// The phone link's film player (window.CWFilm): Gary's 4K films through the
// browser's own video player, streamed, driven by scripts/story/web_video_player.gd
// the way the iPhone and Mac apps drive their NativeVideoPlayer.
//
// Godot's web player only plays Theora, at a size the phone can hold, and the
// whole file has to come down first. The browser's own <video> plays H.264 in
// 4K with the phone's hardware, and streams it: each film is published as HLS
// (tools/make_hls.sh: Gary's 4K picture untouched, a 1080p copy and a 540p
// copy, cut into the same 4-second pieces) under films/<name>/master.m3u8 next
// to index.html, so it starts in a second or two and steps up to 4K as fast as
// the connection allows. Safari (every browser on an iPhone) plays HLS itself;
// elsewhere hls.js (hls.light.min.js next to index.html, loaded the first time
// it's needed) feeds the same <video> through Media Source.
//
// tools/build_web.sh puts this script in index.html. The page's video sits
// over the game's canvas, black, the picture shown whole. A tap on it is
// reported as TAPPED; Skip (show_skip) as SKIP_PRESSED; Esc skips, Enter,
// Space and E show Skip and then skip; its end FINISHED; a failure FAILED.
//
// iOS lets a video play with sound only from inside a touch. The first touch,
// click or key anywhere on the page (the notice's Continue, usually) "primes"
// the video element by calling play() on it there, empty, which lifts that
// rule for the element for good; if a browser still refuses later, a Play
// button over the picture asks for the touch.
(function () {
	'use strict';
	const TAPPED = 1, SKIP_PRESSED = 2, FINISHED = 4, FAILED = 8;
	const HLS_JS = 'hls.light.min.js';
	let video = null, root = null, skip = null, sub = null, playBtn = null;
	let hls = null;
	let events = 0;
	let ready = false, failed = false, finished = false, error = '';
	let wantPlaying = false, skipShown = false, open = false;
	// Which films are on the site: films/sizes.txt, a line a film ("<name>
	// <bytes>", kept by tools/publish_web.sh), read once as the page loads.
	// null: not known (still coming, or the list isn't there), when a film is
	// simply tried and a missing one fails within a moment.
	let published = null;
	try {
		fetch('films/sizes.txt', { cache: 'no-cache' }).then((r) => (r.ok ? r.text() : null)).then((t) => {
			if (t !== null) {
				published = new Set(t.split('\n').map((l) => l.trim().split(/\s+/)[0]).filter((n) => n));
			}
		}).catch(() => {});
	} catch (e) { /* no fetch: films are tried as they come */ }

	function make() {
		if (video) {
			return;
		}
		root = document.createElement('div');
		root.id = 'cw-film';
		root.style.cssText = 'position:fixed;left:0;top:0;right:0;bottom:0;z-index:2147483000;background:#000;' +
			'display:none;touch-action:none;-webkit-user-select:none;user-select:none;-webkit-tap-highlight-color:transparent;';
		video = document.createElement('video');
		video.setAttribute('playsinline', '');
		video.setAttribute('webkit-playsinline', '');
		video.setAttribute('preload', 'none');
		video.disablePictureInPicture = true;
		video.controls = false;
		video.style.cssText = 'position:absolute;left:0;top:0;width:100%;height:100%;object-fit:contain;background:#000;pointer-events:none;';
		root.appendChild(video);
		sub = document.createElement('div');
		sub.style.cssText = 'position:absolute;left:8%;right:8%;bottom:calc(6% + env(safe-area-inset-bottom));text-align:center;' +
			'color:#fff;font:500 clamp(16px,2.6vw,30px)/1.3 Georgia,serif;text-shadow:0 0 6px #000,0 2px 4px #000;pointer-events:none;';
		root.appendChild(sub);
		skip = document.createElement('button');
		skip.type = 'button';
		skip.textContent = 'Skip';
		skip.style.cssText = 'position:absolute;top:calc(24px + env(safe-area-inset-top));right:calc(24px + env(safe-area-inset-right));' +
			'padding:12px 30px;border-radius:28px;border:1px solid rgba(232,196,120,0.75);background:rgba(10,10,18,0.72);' +
			'color:#f3dca2;font:600 20px Georgia,serif;letter-spacing:0.04em;opacity:0;transition:opacity .25s;pointer-events:none;';
		root.appendChild(skip);
		playBtn = document.createElement('button');
		playBtn.type = 'button';
		playBtn.textContent = '▶  Play the film';
		playBtn.style.cssText = 'position:absolute;left:50%;top:50%;transform:translate(-50%,-50%);padding:18px 40px;border-radius:34px;' +
			'border:1px solid rgba(232,196,120,0.8);background:rgba(10,10,18,0.8);color:#f3dca2;font:600 24px Georgia,serif;display:none;';
		root.appendChild(playBtn);
		document.body.appendChild(root);

		const tap = (e) => {
			e.preventDefault();
			e.stopPropagation();
			if (e.target === playBtn) {
				startPlaying();
				return;
			}
			if (e.target === skip && skipShown) {
				events |= SKIP_PRESSED;
				return;
			}
			events |= TAPPED;
		};
		root.addEventListener('pointerup', tap);
		root.addEventListener('pointerdown', (e) => { e.preventDefault(); e.stopPropagation(); });
		root.addEventListener('touchstart', (e) => { e.stopPropagation(); }, { passive: true });
		root.addEventListener('contextmenu', (e) => e.preventDefault());
		window.addEventListener('keydown', (e) => {
			if (!open) {
				return;
			}
			if (e.key === 'Escape' || e.key === 'Tab') {
				events |= SKIP_PRESSED;
			} else if (e.key === 'Enter' || e.key === ' ' || e.key === 'e' || e.key === 'E') {
				events |= skipShown ? SKIP_PRESSED : TAPPED;
			} else {
				return;
			}
			e.preventDefault();
			e.stopPropagation();
		}, true);
		video.addEventListener('canplay', () => { ready = true; });
		video.addEventListener('loadeddata', () => { ready = true; });
		video.addEventListener('ended', () => { finished = true; events |= FINISHED; });
		video.addEventListener('error', () => {
			const err = video.error;
			fail('video error' + (err ? ' ' + err.code + (err.message ? ': ' + err.message : '') : ''));
		});
		document.addEventListener('visibilitychange', () => {
			if (!open) {
				return;
			}
			if (document.hidden) {
				video.pause();
			} else if (wantPlaying && !finished) {
				startPlaying();
			}
		});
	}

	function fail(why) {
		if (failed) {
			return;
		}
		failed = true;
		error = why;
		events |= FAILED;
		console.warn('CWFilm: ' + why);
	}

	// The first touch, click or key anywhere: play() on the empty element inside
	// it, so iOS lets it play with sound later without another touch.
	const GESTURES = ['touchend', 'pointerup', 'mousedown', 'keydown', 'click'];
	let primed = false;
	function prime() {
		if (primed) {
			return;
		}
		primed = true;
		GESTURES.forEach((g) => window.removeEventListener(g, prime, true));
		make();
		if (!open) {
			try {
				const p = video.play();
				if (p && p.catch) {
					p.catch(() => {});
				}
			} catch (e) { /* an empty element can't play: priming is all it was for */ }
		}
	}
	GESTURES.forEach((g) => window.addEventListener(g, prime, true));

	function loadScript(src) {
		return new Promise((resolve, reject) => {
			const s = document.createElement('script');
			s.src = src;
			s.onload = resolve;
			s.onerror = () => reject(new Error('could not load ' + src));
			document.head.appendChild(s);
		});
	}

	function nativeHls() {
		const v = video || document.createElement('video');
		return !!v.canPlayType && v.canPlayType('application/vnd.apple.mpegurl') !== '';
	}
	function mse() {
		return !!(window.MediaSource || window.ManagedMediaSource || window.WebKitMediaSource);
	}

	function startPlaying() {
		if (!video || finished || failed) {
			return;
		}
		wantPlaying = true;
		let p;
		try {
			p = video.play();
		} catch (e) {
			p = Promise.reject(e);
		}
		if (p && p.then) {
			p.then(() => { playBtn.style.display = 'none'; }).catch((e) => {
				if (e && e.name === 'NotAllowedError') {
					playBtn.style.display = 'block';   // the browser wants a touch first
				} else if (e && e.name !== 'AbortError') {
					fail('play: ' + e);
				}
			});
		}
	}

	window.CWFilm = {
		// Whether this browser can stream a film at all (Safari's own HLS, or
		// Media Source for hls.js). Without it the game plays the Theora copy.
		supported: function () {
			return nativeHls() || mse();
		},
		open: function (url) {
			make();
			this.stop();
			ready = failed = finished = false;
			events = 0;
			error = '';
			open = true;
			root.style.display = 'block';
			root.style.opacity = '1';
			video.muted = false;
			video.volume = 1;
			if (nativeHls()) {
				video.src = url;
				video.load();
				return true;
			}
			if (!mse()) {
				fail('no HLS and no Media Source here');
				return false;
			}
			const attach = () => {
				if (!open || failed) {
					return;
				}
				const Hls = window.Hls;
				if (!Hls || !Hls.isSupported()) {
					fail('hls.js not supported here');
					return;
				}
				hls = new Hls({ capLevelToPlayerSize: false, startLevel: -1, maxBufferLength: 20, backBufferLength: 10 });
				hls.on(Hls.Events.ERROR, (ev, data) => {
					if (!data.fatal) {
						return;
					}
					if (data.type === Hls.ErrorTypes.MEDIA_ERROR && !hls._recovered) {
						hls._recovered = true;
						hls.recoverMediaError();
						return;
					}
					fail('hls ' + data.type + ': ' + data.details);
				});
				hls.loadSource(url);
				hls.attachMedia(video);
				if (wantPlaying) {
					startPlaying();
				}
			};
			if (window.Hls) {
				attach();
			} else {
				loadScript(HLS_JS).then(attach).catch((e) => fail(String(e)));
			}
			return true;
		},
		// Whether the site has the film called `name`: 1 yes, 0 no, -1 not known.
		has: function (name) {
			return published === null ? -1 : (published.has(name) ? 1 : 0);
		},
		play: function () { startPlaying(); },
		pause: function () { wantPlaying = false; if (video) { video.pause(); } },
		stop: function () {
			open = false;
			wantPlaying = false;
			skipShown = false;
			if (hls) {
				try { hls.destroy(); } catch (e) { /* gone already */ }
				hls = null;
			}
			if (video) {
				video.pause();
				video.removeAttribute('src');
				try { video.load(); } catch (e) { /* nothing to unload */ }
			}
			if (root) {
				root.style.display = 'none';
				skip.style.opacity = '0';
				skip.style.pointerEvents = 'none';
				playBtn.style.display = 'none';
				sub.textContent = '';
			}
		},
		// Everything the game asks once a frame, as one JSON string.
		state: function () {
			const v = video;
			const out = {
				ev: events,
				ready: ready,
				failed: failed,
				finished: finished,
				playing: !!v && !v.paused && !v.ended,
				pos: v ? (v.currentTime || 0) : 0,
				len: v && isFinite(v.duration) ? v.duration : 0,
				w: v ? v.videoWidth : 0,
				h: v ? v.videoHeight : 0,
				level: hls ? hls.currentLevel : -1,
				error: error,
			};
			events = 0;
			return JSON.stringify(out);
		},
		set_volume: function (k) { if (video) { video.volume = Math.max(0, Math.min(1, k)); } },
		set_opacity: function (k) { if (root) { root.style.opacity = String(Math.max(0, Math.min(1, k))); } },
		// Hidden (a story film paused for a choice): out of the way altogether,
		// so taps reach the game's own buttons under it.
		set_visible: function (on) { if (root) { root.style.display = on && open ? 'block' : 'none'; } },
		set_subtitle: function (text) { if (sub) { sub.textContent = text || ''; } },
		show_skip: function (on, text) {
			make();
			skipShown = !!on;
			skip.textContent = text || 'Skip';
			skip.style.opacity = on ? '1' : '0';
			skip.style.pointerEvents = on ? 'auto' : 'none';
		},
		seek: function (t) { if (video) { video.currentTime = t; } },
	};
})();
