#!/usr/bin/env python3
"""Checks the phone link fills an iPhone held sideways edge to edge and keeps
its buttons clear of the Dynamic Island and the home bar, in headless
Chromium dressed as an iPhone 16 Pro Max in landscape: 956 x 440 points, with
touch (at 1.5 pixels a point, half the real phone's, to keep software drawing
quick). Chromium has no notch, so the page is given the iPhone's safe area (62
points at each side, 21 at the bottom) through Chromium's safe-area override
when it has one, or else by telling the game's probe element those margins.

Checks the page asks for viewport-fit=cover and a full-screen Home Screen app,
the canvas covers the whole window, the page behind it is the game's dark blue,
and the game read the safe area; saves screenshots of the notice and the title
(the buttons should sit inside the margins, the painting run to the edges).

    tools/build_web.sh
    python3 tests/web_fit_check.py build/web <out_dir> [chromium executable]

Needs Python 3 with playwright.
"""
import functools
import http.server
import json
import os
import sys
import threading
import time

from playwright.sync_api import sync_playwright

WEB = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else "build/web")
OUT = os.path.abspath(sys.argv[2] if len(sys.argv) > 2 else ".")
CHROMIUM = sys.argv[3] if len(sys.argv) > 3 else os.environ.get("CHROMIUM")
VIEW = {"width": 956, "height": 440}
SCALE = 1.5
INSETS = {"top": 0, "left": 62, "bottom": 21, "right": 62}
failures = []


def check(ok, what):
    print(("  PASS  " if ok else "  FAIL  ") + what)
    if not ok:
        failures.append(what)


class Quiet(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a):
        pass


def wait_for(page, js, timeout, what):
    t = time.time()
    while time.time() - t < timeout:
        if page.evaluate(js):
            return True
        time.sleep(0.5)
    print("  (gave up waiting for %s)" % what)
    return False


def main():
    os.makedirs(OUT, exist_ok=True)
    srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), functools.partial(Quiet, directory=WEB))
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    base = "http://127.0.0.1:%d" % srv.server_address[1]
    page_html = open(os.path.join(WEB, "index.html")).read()
    check('viewport-fit=cover' in page_html, "index.html asks for viewport-fit=cover (no bars beside the island)")
    check('apple-mobile-web-app-status-bar-style' in page_html, "the Home Screen app draws under the status bar")
    manifest = json.load(open(os.path.join(WEB, "index.manifest.json")))
    check(manifest.get("display") == "fullscreen", "the Home Screen app is full screen (manifest display: %s)" % manifest.get("display"))
    args = ["--autoplay-policy=no-user-gesture-required", "--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"]
    with sync_playwright() as p:
        browser = p.chromium.launch(executable_path=CHROMIUM, args=args) if CHROMIUM else p.chromium.launch(args=args)
        ctx = browser.new_context(viewport=VIEW, device_scale_factor=SCALE, is_mobile=True, has_touch=True)
        page = ctx.new_page()
        logs = []
        page.on("console", lambda m: logs.append("%s: %s" % (m.type, m.text)))
        page.on("pageerror", lambda e: logs.append("pageerror: %s" % e))
        how = "Chromium's safe-area override"
        try:
            cdp = ctx.new_cdp_session(page)
            cdp.send("Emulation.setSafeAreaInsetsOverride", {"insets": INSETS})
        except Exception as e:
            how = "the probe element told the margins (this Chromium has no safe-area override: %s)" % str(e).splitlines()[0][:80]
            page.add_init_script("""(() => { const s = document.createElement('style');
				s.textContent = '#cw-safe-probe{padding:%dpx %dpx %dpx %dpx !important}';
				document.addEventListener('DOMContentLoaded', () => document.head.appendChild(s)); })();"""
                % (INSETS["top"], INSETS["right"], INSETS["bottom"], INSETS["left"]))
        print("safe area: " + how)
        page.goto(base + "/index.html")
        started = wait_for(page, "!document.getElementById('status')", 300, "the game to start")
        check(started, "the game starts")
        read = wait_for(page, "!!document.getElementById('cw-safe-probe')", 60, "the game to read the safe area")
        check(read, "the game reads the page's safe area (SafeArea's probe is there)")
        time.sleep(4.0)
        geo = page.evaluate("""(() => { const c = document.getElementById('canvas'); const r = c.getBoundingClientRect();
			const s = getComputedStyle(document.getElementById('cw-safe-probe') || document.body);
			return {x: r.left, y: r.top, w: r.width, h: r.height, cw: c.width, ch: c.height, iw: innerWidth, ih: innerHeight,
				bg: getComputedStyle(document.body).backgroundColor,
				safe: [s.paddingLeft, s.paddingTop, s.paddingRight, s.paddingBottom]}; })()""")
        print("  page:", geo)
        check(geo["x"] == 0 and geo["y"] == 0 and geo["w"] == geo["iw"] and geo["h"] == geo["ih"],
              "the canvas covers the whole window (%gx%g of %dx%d)" % (geo["w"], geo["h"], geo["iw"], geo["ih"]))
        check(abs(geo["cw"] - VIEW["width"] * SCALE) <= 1 and abs(geo["ch"] - VIEW["height"] * SCALE) <= 1,
              "the canvas is drawn at the screen's own pixels (%dx%d)" % (geo["cw"], geo["ch"]))
        check(geo["bg"] == "rgb(7, 8, 15)", "the page behind the game is its dark blue (%s)" % geo["bg"])
        check(geo["safe"] == ["%dpx" % INSETS[k] for k in ("left", "top", "right", "bottom")], "the page reports the safe area %s" % geo["safe"])
        page.screenshot(path=os.path.join(OUT, "web_notice.png"))
        # Continue sits low in the middle of the notice (since 22 October only it moves the notice on)
        page.mouse.click(VIEW["width"] / 2, VIEW["height"] * 0.78)
        time.sleep(5.0)
        page.screenshot(path=os.path.join(OUT, "web_title.png"))
        errors = [l for l in logs if l.startswith("error") or l.startswith("pageerror")]
        for l in errors[:10]:
            print("   ", l)
        browser.close()
    srv.shutdown()
    print("WEB FIT: %s" % ("ok" if not failures else "%d FAILED: %s" % (len(failures), "; ".join(failures))))
    sys.exit(1 if failures else 0)


main()
