#!/usr/bin/env python3
"""Checks the web build's music in a real browser (headless Chromium), by
recording exactly what the page's music player sends to the speakers and
comparing it, sample by sample, with the decoded track:
  - the title's menu_theme and Ashford's reel loop at the loop point with no
    gap and no jump back to the intro (the player is moved to 3 s before the
    loop's end, then 6 s are recorded across the join);
  - a crossfade to a duel theme and back carries on where the reel was;
  - the music volume and a stinger's dip apply;
  - and in a second browser, at 44.1 kHz (as some iPhones run), with an MP3
    whose decoder padding isn't removed (as a decoder that ignores the gapless
    header leaves it) the loop is still exact, and a track that won't load is
    just silent.

    tools/build_web.sh        (or any build/web made by it)
    python3 tests/web_music_check.py build/web [chromium executable]

Needs Python 3 with numpy and playwright, and ffmpeg.
"""
import base64
import functools
import http.server
import json
import os
import subprocess
import sys
import tempfile
import threading
import time

import numpy as np
from playwright.sync_api import sync_playwright

WEB = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else "build/web")
CHROMIUM = sys.argv[2] if len(sys.argv) > 2 else os.environ.get("CHROMIUM")
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
failures = []


def check(ok, what):
    print(("  PASS  " if ok else "  FAIL  ") + what)
    if not ok:
        failures.append(what)


class Quiet(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a):
        pass


def serve():
    srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), functools.partial(Quiet, directory=WEB))
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    return srv


# In the page: a recorder on the music player's output (an AudioWorklet, so it
# runs on the audio thread and never drops a sample), and helpers.
HELPERS = r"""
window.__t = {
	chunks: [], node: null,
	async setup() {
		const ctx = CWMusic.debug.ctx;
		const code = `class Rec extends AudioWorkletProcessor {
			constructor() { super(); this.on = false; this.port.onmessage = (e) => { this.on = e.data; }; }
			process(ins) {
				const i = ins[0];
				if (this.on && i.length) this.port.postMessage([currentFrame, i[0].slice(), (i[1] || i[0]).slice()]);
				return true;
			}
		}
		registerProcessor('rec', Rec);`;
		await ctx.audioWorklet.addModule(URL.createObjectURL(new Blob([code], { type: 'application/javascript' })));
		const node = new AudioWorkletNode(ctx, 'rec', { numberOfInputs: 1, numberOfOutputs: 1, outputChannelCount: [2] });
		node.port.onmessage = (e) => this.chunks.push(e.data);
		const mute = ctx.createGain();
		mute.gain.value = 0;
		CWMusic.debug.out.connect(node);
		node.connect(mute);
		mute.connect(ctx.destination);
		this.node = node;
		return ctx.sampleRate;
	},
	start() { this.chunks = []; this.node.port.postMessage(true); },
	stop() {
		this.node.port.postMessage(false);
		const n = this.chunks.reduce((a, c) => a + c[1].length, 0);
		const l = new Float32Array(n), r = new Float32Array(n);
		let at = 0;
		for (const c of this.chunks) { l.set(c[1], at); r.set(c[2], at); at += c[1].length; }
		return { frame0: this.chunks.length ? this.chunks[0][0] : -1, l: this.b64(l), r: this.b64(r) };
	},
	b64(f32) {
		const u8 = new Uint8Array(f32.buffer, f32.byteOffset, f32.byteLength);
		let s = '';
		for (let i = 0; i < u8.length; i += 0x8000) s += String.fromCharCode.apply(null, u8.subarray(i, i + 0x8000));
		return btoa(s);
	},
	// the active (newest) voice of a track
	voice(name) {
		const s = CWMusic.debug.slots.filter((v) => v && v.name === name && v.state !== 'stopped');
		return s.length ? s[s.length - 1] : null;
	},
	slotOf(name) { return CWMusic.debug.slots.indexOf(this.voice(name)); },
	info(name) {
		const v = this.voice(name);
		if (!v || !v.src) return v ? { state: v.state } : null;
		return { state: v.state, slot: this.slotOf(name), loop: v.src.loop, loopStart: v.src.loopStart, loopEnd: v.src.loopEnd,
			lead: v.trim.lead, decoded: v.trim.decoded, offset: v.offset, t0: v.t0, from: v.from, gain: v.gain.gain.value, db: v.db,
			bufLen: v.src.buffer.length, bufRate: v.src.buffer.sampleRate, bufDur: v.src.buffer.duration,
			position: CWMusic.position(this.slotOf(name)), now: CWMusic.debug.ctx.currentTime };
	},
	// a stretch of a voice's decoded audio, channel 0 and 1 (or just 0)
	pcm(name, from, to, left) {
		const b = this.voice(name).src.buffer;
		from = Math.max(0, Math.floor(from)); to = Math.min(b.length, Math.floor(to));
		return { from: from, l: this.b64(b.getChannelData(0).slice(from, to)),
			r: left ? '' : this.b64(b.getChannelData(b.numberOfChannels > 1 ? 1 : 0).slice(from, to)) };
	},
};
"""


def f32(b64):
    return np.frombuffer(base64.b64decode(b64), np.float32)


def wait_for(page, js, timeout=60.0, what=""):
    t = time.time()
    while time.time() - t < timeout:
        if page.evaluate(js):
            return True
        time.sleep(0.1)
    raise RuntimeError("timed out waiting for " + (what or js))


def record(page, seconds):
    page.evaluate("__t.start()")
    time.sleep(seconds)
    rec = page.evaluate("__t.stop()")
    return rec["frame0"], np.stack([f32(rec["l"]), f32(rec["r"])], axis=1)


def pcm(page, name, a, b):
    d = page.evaluate("([n, a, b]) => __t.pcm(n, a, b)", [name, a, b])
    return d["from"], np.stack([f32(d["l"]), f32(d["r"])], axis=1)


class Expected:
    """What a looping voice should play, by the Web Audio rules for an
    AudioBufferSourceNode: from buffer position p (frames; between frames the
    two neighbouring samples are blended, the second one taken from the loop's
    start when it would be past the buffer) straight on to the loop's end, then
    on from the loop's start (one wrap)."""

    def __init__(self, page, name, info, start_pos, n):
        rate = info["bufRate"]
        self.a, self.b, self.n, self.len = info["loopStart"] * rate, min(info["loopEnd"] * rate, info["bufLen"]), n, info["bufLen"]
        lo = int(np.floor(start_pos)) - 4
        self.segs = [pcm(page, name, lo, min(int(np.ceil(start_pos + n)) + 4, self.len)),
                     pcm(page, name, int(self.a) - 4, int(self.a) + n + 4)]

    def get(self, idx):
        out = np.full((len(idx), 2), np.nan, np.float64)
        for p0, data in self.segs:
            sel = (idx >= p0) & (idx < p0 + len(data))
            out[sel] = data[idx[sel] - p0]
        assert not np.isnan(out).any()
        return out

    def at(self, start_pos):
        pos = start_pos + np.arange(self.n, dtype=np.float64)
        wrapped = pos >= self.b
        pos[wrapped] -= self.b - self.a
        i = np.floor(pos).astype(np.int64)
        f = (pos - i)[:, None]
        i2 = i + 1
        past = i2 >= self.len
        i2[past] = np.floor(pos[past] + 1 - (self.b - self.a)).astype(np.int64)
        out = (1 - f) * self.get(i) + f * self.get(i2)
        return out.astype(np.float32), wrapped


def seam_test(page, name, label):
    """Moves the track to 3 s before its loop's end, records 6 s and compares."""
    info = page.evaluate("(n) => __t.info(n)", name)
    rate = info["bufRate"]
    end_content = info["loopEnd"]
    page.evaluate("([s, p]) => CWMusic.debug.seek(s, p)", [info["slot"], end_content - 3.0])
    info = page.evaluate("(n) => __t.info(n)", name)
    frame0, rec = record(page, 6.5)
    n = len(rec)
    # where the recording starts in the buffer, from the audio clock; then the
    # best sub-sample shift (the browser may round the start offset to a frame)
    start_pos = info["offset"] * rate + (frame0 - info["t0"] * rate)
    ex = Expected(page, name, info, start_pos, n)
    best = None
    for d in np.arange(-1.0, 1.0001, 0.05):
        exp, wrapped = ex.at(start_pos + d)
        e = float(np.sum((rec - exp * (np.dot(rec[:, 0], exp[:, 0]) / max(np.dot(exp[:, 0], exp[:, 0]), 1e-12))) ** 2))
        if best is None or e < best[0]:
            best = (e, d)
    exp, wrapped = ex.at(start_pos + best[1])
    seam = int(np.argmax(wrapped)) if wrapped.any() else -1
    g = float(np.dot(rec[:, 0], exp[:, 0]) / max(np.dot(exp[:, 0], exp[:, 0]), 1e-12))
    resid = rec - g * exp
    print("  (recording aligned by the audio clock to within %+.2f samples)" % best[1])
    sig = float(np.sqrt(np.mean(rec ** 2)))
    err = float(np.sqrt(np.mean(resid ** 2)))
    w50 = int(0.05 * rate)
    near = resid[max(0, seam - w50):seam + w50] if seam >= 0 else resid
    away = np.concatenate([resid[:max(0, seam - w50)], resid[seam + w50:]]) if seam >= 0 else resid
    # the other possibility: a restart from the top (what Godot's web player did)
    if seam >= 0:
        top = pcm(page, name, 0, n - seam + 10)[1][:n - seam]
        after = rec[seam:seam + len(top)]
        corr_loop = float(np.corrcoef(after[:, 0], exp[seam:seam + len(top), 0])[0, 1])
        corr_top = float(np.corrcoef(after[:, 0], top[:, 0])[0, 1])
    # no silence: 10 ms windows across the recording, against the same windows
    # of the track itself (some tracks have a moment of silence of their own)
    w = int(0.01 * rate)
    rms = np.sqrt(np.mean(rec[:n // w * w].reshape(-1, w, 2) ** 2, axis=(1, 2)))
    rms_exp = g * np.sqrt(np.mean(exp[:n // w * w].reshape(-1, w, 2) ** 2, axis=(1, 2)))
    dropouts = int(np.sum((rms < 0.5 * rms_exp) & (rms_exp > 1e-3)))
    print("%s: %s at %d Hz, loop [%.6f, %.6f) s in a %.6f s buffer (decoded %.6f s, %.6f s of padding cut from the start), recorded %.2f s, join at %.3f s into it"
          % (label, name, rate, info["loopStart"], info["loopEnd"], info["bufDur"], info["decoded"], info["lead"], n / rate, seam / rate))
    print("  gain %.4f; output vs expected (intro tail -> loop start): rms error %.2e on a %.3f rms signal (%.1f dB below), "
          "largest error within 50 ms of the join %.2e (elsewhere %.2e); quietest 10 ms window %.4f (median %.4f), %d window(s) quieter than the track"
          % (g, err, sig, 20 * np.log10(sig / max(err, 1e-12)), float(np.abs(near).max()), float(np.abs(away).max()),
             float(rms.min()), float(np.median(rms)), dropouts))
    check(info["loop"] is True, "%s: source.loop is on" % label)
    check(seam > 0 and seam < n - rate, "%s: the recording crosses the loop's end" % label)
    check(err < sig * 0.001, "%s: output matches the expected samples through the join (error %.1f dB down)" % (label, 20 * np.log10(sig / max(err, 1e-12))))
    check(float(np.abs(near).max()) < 0.001, "%s: no click at the join (largest error there %.1e)" % (label, float(np.abs(near).max())))
    check(dropouts == 0, "%s: no silence or dropout anywhere in the recording" % label)
    if seam >= 0 and info["loopStart"] > 1.0:
        print("  after the join: correlation with the loop start %.4f, with the track's own start (a restart) %.4f" % (corr_loop, corr_top))
        check(corr_loop > 0.99 and corr_top < 0.5, "%s: after the join it continues from the loop start, not from the top" % label)
    elif seam >= 0:
        print("  after the join: correlation with the track's start (its loop start) %.4f" % corr_loop)
        check(corr_loop > 0.99, "%s: after the join it continues from the start, its loop point" % label)
    return info


def locate(page, name, rec, info, rate):
    """Finds where in the track (content seconds) a recording comes from, by
    searching the whole decoded track (coarsely, then exactly)."""
    buf = f32(page.evaluate("(n) => __t.pcm(n, 0, 1e9, true)", name)["l"]).astype(np.float64)
    probe = rec[:, 0][: int(1.0 * rate)].astype(np.float64)
    # normalised cross-correlation at every lag, by FFT
    size = 1 << int(np.ceil(np.log2(len(buf) + len(probe))))
    num = np.fft.irfft(np.fft.rfft(buf, size) * np.conj(np.fft.rfft(probe, size)), size)[:len(buf) - len(probe) + 1]
    energy = np.concatenate([[0.0], np.cumsum(buf ** 2)])
    seg = np.sqrt(energy[len(probe):] - energy[:-len(probe)])[:len(num)]
    c = num / (seg * np.linalg.norm(probe) + 1e-9)
    best = int(np.argmax(c))
    return best / rate, float(c[best])


def boot(p, rate=None, routes=None):
    args = ["--autoplay-policy=no-user-gesture-required", "--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"]
    browser = p.chromium.launch(executable_path=CHROMIUM, args=args) if CHROMIUM else p.chromium.launch(args=args)
    page = browser.new_page(viewport={"width": 960, "height": 540})
    if rate:
        # the page's own AudioContext asks for no rate: give it this one (Godot's asks for its own)
        page.add_init_script("""(() => { const A = window.AudioContext;
			window.AudioContext = function (o) { o = o || {}; if (!o.sampleRate) o.sampleRate = %d; return new A(o); };
			window.AudioContext.prototype = A.prototype; })();""" % rate)
    for pattern, handler in (routes or {}).items():
        page.route(pattern, handler)
    logs = []
    page.on("console", lambda m: logs.append("%s: %s" % (m.type, m.text)))
    page.on("pageerror", lambda e: logs.append("pageerror: %s" % e))
    requests = []
    page.on("request", lambda r: requests.append(r.url))
    page.goto("%s/index.html?musictest" % BASE)
    wait_for(page, "!!window.CWMusicTest", 240, "the game to start")
    page.evaluate(HELPERS)
    rate = page.evaluate("__t.setup()")
    frames = page.evaluate("""new Promise((done) => { const ts = [];
        const f = (t) => { ts.push(t); if (ts.length < 8) requestAnimationFrame(f); else done(ts); }; requestAnimationFrame(f); })""")
    print("(the game is drawing a frame every %.0f ms in this software-rendered browser)" % float(np.median(np.diff(frames))))
    return browser, page, logs, requests, rate


def run():
    with sync_playwright() as p:
        # ------------------------------------------------ 48 kHz, as shipped
        browser, page, logs, requests, rate = boot(p, rate=48000)
        print("page up; music player at %d Hz, %d tracks" % (rate, len(json.loads(page.evaluate("CWMusic.tracks()")))))
        check(page.evaluate("Object.keys(JSON.parse(CWMusic.tracks())).includes('ashford_festival')"), "Music.has() on the web comes from the manifest")
        # the real flow: dismiss the notice (a tap), the title starts menu_theme
        t = time.time()
        while not page.evaluate("!!__t.voice('menu_theme') && __t.voice('menu_theme').state === 'playing'"):
            if time.time() - t > 90:
                raise RuntimeError("menu_theme never started at the title")
            time.sleep(1.5)
            page.mouse.click(480, 270)
        time.sleep(2.0)
        info = seam_test(page, "menu_theme", "title (menu_theme)")
        check(abs(info["loopStart"] - 59.0) < 1e-6 and abs(info["loopEnd"] - 126.5) < 1e-6,
              "menu_theme: loopStart 59.0 (Music.LOOP_START) and loopEnd 126.5 (the manifest, not buffer.duration)")

        # Ashford's reel, as World starts it (2 s crossfade from the title)
        page.evaluate("CWMusicTest('play', 'ashford_festival', 2.0)")
        wait_for(page, "!!__t.voice('ashford_festival') && __t.voice('ashford_festival').state === 'playing'", 30, "ashford_festival")
        time.sleep(2.5)
        check(page.evaluate("!__t.voice('menu_theme')"), "menu_theme faded out and stopped after the crossfade")
        info = seam_test(page, "ashford_festival", "Ashford (ashford_festival)")
        check(abs(info["loopStart"] - 35.029) < 1e-6 and abs(info["loopEnd"] - 86.848020833) < 1e-6,
              "ashford_festival: loopStart 35.029 and loopEnd 86.848020833 (the source's 4168705 samples)")
        seam_test(page, "ashford_festival", "Ashford, second time")

        # -------------------------- crossfade to a duel and back: it resumes
        # (the position is read in the same JS task as the switch: in this
        # software-rendered browser each game frame holds the page for a while)
        # returns where `other` was just before and just after the switch (it
        # plays on while the new track loads): Music remembers a point between
        switch = """([name, fade, other]) => { const s = __t.slotOf(other); const p0 = CWMusic.position(s);
            CWMusicTest('play', name, fade); return [p0, CWMusic.position(s)]; }"""
        before = page.evaluate(switch, ["duel_main", 1.2, "ashford_festival"])
        wait_for(page, "!!__t.voice('duel_main') && __t.voice('duel_main').state === 'playing' && !__t.voice('ashford_festival')", 60, "duel_main")
        time.sleep(1.0)
        d_before = page.evaluate(switch, ["ashford_festival", 1.5, "duel_main"])
        check(d_before[0] > 1.0, "duel_main took over (it got to %.2f s) and the reel faded out and stopped" % d_before[0])
        wait_for(page, "!!__t.voice('ashford_festival') && __t.voice('ashford_festival').state === 'playing' && !__t.voice('duel_main')", 60, "ashford back")
        b = page.evaluate("__t.info('ashford_festival')")
        print("crossfade: the reel was at %.4f-%.4f s as the duel began; it came back from %.4f s" % (before[0], before[1], b["from"]))
        check(before[0] - 1e-6 <= b["from"] <= before[1] + 1e-6, "the reel resumes from where it was (%.4f s, in %.4f-%.4f s), not from 0" % (b["from"], before[0], before[1]))
        frame0, rec = record(page, 1.5)
        heard, c = locate(page, "ashford_festival", rec, b, rate)
        want = b["offset"] + (frame0 / rate - b["t0"])
        print("  a recording made after the return is from %.4f s into the reel (expected %.4f s; match %.4f), found by searching the whole track"
              % (heard, want, c))
        check(abs(heard - want) < 0.002 and c > 0.99, "what plays after the return is the reel carrying on from there")
        d2 = page.evaluate(switch, ["duel_main", 0.5, "ashford_festival"])   # and the duel's own place is remembered too
        wait_for(page, "!!__t.voice('duel_main') && __t.voice('duel_main').state === 'playing'", 60, "duel_main again")
        d2 = page.evaluate("__t.info('duel_main')")
        check(d_before[0] - 1e-6 <= d2["from"] <= d_before[1] + 1e-6, "duel_main came back from where it was too (%.4f s, in %.4f-%.4f s)" % (d2["from"], d_before[0], d_before[1]))
        page.evaluate("CWMusicTest('play', 'ashford_festival', 0.5)")
        wait_for(page, "!!__t.voice('ashford_festival') && __t.voice('ashford_festival').state === 'playing' && !__t.voice('duel_main')", 60, "ashford again")
        time.sleep(0.5)

        # ----------------------------------------------------------- volume
        frame0, rec = record(page, 0.6)
        g0 = page.evaluate("__t.info('ashford_festival').gain")
        page.evaluate("CWMusicTest('volume', 0.3)")
        time.sleep(0.4)
        g1 = page.evaluate("__t.info('ashford_festival').gain")
        frame1, rec1 = record(page, 0.6)
        lvl = lambda m: 10 ** ((20 * np.log10(m) - 8.0) / 20)
        print("volume: music 0.8 -> gain %.4f (want %.4f), rms %.4f; music 0.3 -> gain %.4f (want %.4f), rms %.4f"
              % (g0, lvl(0.8), float(np.sqrt(np.mean(rec ** 2))), g1, lvl(0.3), float(np.sqrt(np.mean(rec1 ** 2)))))
        check(abs(g0 - lvl(0.8)) < 1e-3 and abs(g1 - lvl(0.3)) < 1e-3, "the music volume setting applies (Music.apply_volume)")
        page.evaluate("CWMusicTest('volume', 0.8)")
        time.sleep(0.3)

        # ------------------------------------------------- stinger and duck
        page.evaluate("CWMusicTest('stinger', 'victory', true)")
        wait_for(page, "!!CWMusic.debug.sting() && CWMusic.debug.sting().state === 'playing'", 30, "the victory stinger")
        t_sting = page.evaluate("CWMusic.debug.sting().t0")
        wait_for(page, "CWMusic.debug.ctx.currentTime > %f" % (t_sting + 1.0), 30)
        gd = page.evaluate("__t.info('ashford_festival').gain")
        print("stinger: music gain 1 s into the victory piece %.4f (want %.4f, 14 dB down)" % (gd, lvl(0.8) * 10 ** (-14 / 20)))
        check(abs(gd - lvl(0.8) * 10 ** (-14 / 20)) < 2e-3, "a stinger ducks the looping music by 14 dB")
        wait_for(page, "CWMusic.debug.ctx.currentTime > %f" % (t_sting + 12.373 - 0.6 + 0.2 + 0.8 + 0.3), 60)
        gu = page.evaluate("__t.info('ashford_festival').gain")
        check(abs(gu - lvl(0.8)) < 2e-3, "and the music comes back up after it (gain %.4f)" % gu)

        # ------------------------------------------------ the other loops
        loop_start = {"duel_pinch": 29.78, "duel_alt": 11.376, "duel_main": 0.0, "sigilfall": 0.0}
        lengths = json.loads(page.evaluate("CWMusic.tracks()"))
        for name, ls in loop_start.items():
            page.evaluate("(n) => CWMusicTest('play', n, 0.3)", name)
            wait_for(page, "!!__t.voice('%s') && __t.voice('%s').state === 'playing' && CWMusic.debug.slots.filter((v) => v && v.state !== 'stopped').length === 1" % (name, name), 60, name)
            info = seam_test(page, name, name)
            check(abs(info["loopStart"] - ls) < 1e-6 and abs(info["loopEnd"] - lengths[name]) < 1e-6,
                  "%s: loopStart %.3f, loopEnd %.6f" % (name, ls, lengths[name]))

        # ------------------------------------------------------------ stop
        page.evaluate("CWMusicTest('stop', 0.5)")
        time.sleep(1.2)
        check(page.evaluate("!__t.voice('ashford_festival')"), "Music.stop() fades out and stops")
        errors = [l for l in logs if l.startswith("pageerror") or ("error" in l.lower() and "music" in l.lower())]
        check(not errors, "no errors in the page (%s)" % "; ".join(errors[:3]))
        browser.close()

        # ------- 44.1 kHz, a decoder that leaves the MP3's padding in, a failed load
        untagged = os.path.join(tempfile.mkdtemp(), "ashford_untagged.mp3")
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", os.path.join(ROOT, "assets/audio/music/ashford_festival.ogg"),
                        "-c:a", "libmp3lame", "-b:a", "192k", "-write_xing", "0", untagged], check=True)
        body = open(untagged, "rb").read()
        routes = {
            "**/music/ashford_festival.mp3*": lambda route: route.fulfill(status=200, body=body, headers={"Content-Type": "audio/mpeg"}),
            "**/music/duel_alt.mp3*": lambda route: route.abort(),
        }
        browser, page, logs, requests, rate = boot(p, rate=44100, routes=routes)
        print("second browser: music player at %d Hz; ashford_festival.mp3 without its gapless header; duel_alt.mp3 unreachable" % rate)
        page.evaluate("CWMusicTest('play', 'ashford_festival', 0.3)")
        wait_for(page, "!!__t.voice('ashford_festival') && __t.voice('ashford_festival').state === 'playing'", 30, "ashford_festival")
        time.sleep(1.0)
        info = page.evaluate("__t.info('ashford_festival')")
        pad = info["decoded"] - 86.848020833
        print("  decoded %.6f s for 86.848021 s of music (%.1f ms of padding); %.6f s cut from the start (%d samples at 48 kHz; LAME's is 1105), leaving %.6f s"
              % (info["decoded"], pad * 1000, info["lead"], round(info["lead"] * 48000), info["bufDur"]))
        check(abs(info["lead"] * 48000 - 1105) < 3 and abs(info["bufDur"] - 86.848020833) < 1.5 / rate, "the start padding is found and the buffer cut to exactly the music")
        for i in range(3):   # three times: each lands on the loop at a different moment of the audio clock
            seam_test(page, "ashford_festival", "44.1 kHz, padded MP3, pass %d" % (i + 1))
        n0 = sum("duel_alt.mp3" in u for u in requests)
        page.evaluate("CWMusicTest('play', 'duel_alt', 0.5)")
        wait_for(page, "!CWMusic.playing(0) && !CWMusic.playing(1)", 60, "silence after the failed load")
        time.sleep(5.0)
        n1 = sum("duel_alt.mp3" in u for u in requests)
        st = page.evaluate("[CWMusic.playing(0), CWMusic.playing(1)]")
        print("  duel_alt that can't load: %d request(s) in the next 5 s+, slots playing %s; console: %s" % (n1 - n0, st, [l for l in logs if "duel_alt" in l][:2]))
        check(n1 - n0 == 1 and not any(st), "a track that can't load is fetched once, then silence (the old music fades out), no error loop")
        page.evaluate("CWMusicTest('play', 'ashford_festival', 0.3)")
        wait_for(page, "!!__t.voice('ashford_festival') && __t.voice('ashford_festival').state === 'playing'", 30, "ashford after a failure")
        check(True, "music still plays after a failed load")
        check(not [l for l in logs if l.startswith("pageerror")], "no page errors")
        browser.close()


srv = serve()
BASE = "http://127.0.0.1:%d" % srv.server_address[1]
try:
    run()
finally:
    srv.shutdown()
print("\n%s: %d failed" % ("FAILED" if failures else "ALL PASSED", len(failures)))
sys.exit(1 if failures else 0)
