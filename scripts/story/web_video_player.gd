class_name WebVideoPlayer
extends RefCounted
## Gary's 4K films on the phone link, through the browser's own video player.
##
## The same methods as the apps' NativeVideoPlayer (addons/native_video), so
## OpeningMovie (and the story films) drive either the same way: find_file,
## open, play, poll once a frame, show_skip, set_opacity/set_volume to fade,
## stop. Underneath it's window.CWFilm in the page (scripts/ui/film_web.js,
## put into index.html by tools/build_web.sh): a <video> over the game's
## canvas, streaming the film as HLS from films/<name>/master.m3u8 beside the
## page (tools/make_hls.sh made it from the 4K master: the 4K picture
## untouched, with 1080p and 540p copies for slower connections), so it
## starts in a second or two and shows 4K as soon as the connection allows.
## Safari (and so every iPhone browser) plays HLS itself; elsewhere hls.js
## does it through Media Source.
##
## Only on the web, and only where the page has CWFilm and the browser can
## stream: available() says so. Anywhere else the game plays its Theora copy.

const TAPPED := 1
const SKIP_PRESSED := 2
const FINISHED := 4
const FAILED := 8

## Where the streams sit, beside index.html on the phone link.
const FILMS_DIR := "films"

var _open := false
var _state := {}
var _state_frame := -1
var _volume := 1.0
var _skip_shown := false


## The browser can stream a film here (the phone link with the page's film
## player, in a browser that plays HLS or has Media Source).
static func available() -> bool:
	if not OS.has_feature("web"):
		return false
	var ok = JavaScriptBridge.eval("!!(window.CWFilm && window.CWFilm.supported())", true)
	return ok == true


## The stream for a film the apps carry as `<name>_4k.mp4` (or `<name>.mp4`):
## films/<name>/master.m3u8 beside the page, or "" when the site's list of
## films (films/sizes.txt, read by the page as it loads) says it isn't there.
## Without the list, whether it's really there is found out when it's opened
## (a missing one fails within a moment, and the game plays the Theora copy).
func find_file(file_name: String) -> String:
	if not available():
		return ""
	var stem := file_name.get_basename()
	if stem.ends_with("_4k"):
		stem = stem.trim_suffix("_4k")
	var known = JavaScriptBridge.eval("window.CWFilm.has ? window.CWFilm.has(%s) : -1" % JSON.stringify(stem), true)
	if typeof(known) in [TYPE_INT, TYPE_FLOAT] and int(known) == 0:
		return ""
	return "%s/%s/master.m3u8" % [FILMS_DIR, stem]


func is_supported() -> bool:
	return available()


func open(path: String) -> bool:
	if path == "":
		return false
	_open = JavaScriptBridge.eval("window.CWFilm.open(%s)" % JSON.stringify(path), true) == true
	_state = {}
	_skip_shown = false
	return _open


func play() -> void:
	if _open:
		JavaScriptBridge.eval("window.CWFilm.play()", true)


func pause() -> void:
	if _open:
		JavaScriptBridge.eval("window.CWFilm.pause()", true)


func stop() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.CWFilm && window.CWFilm.stop()", true)
	_open = false


## The page's state, read at most once a frame (events gather in between).
var _pending_events := 0


func _read() -> Dictionary:
	var f := Engine.get_process_frames()
	if f == _state_frame and not _state.is_empty():
		return _state
	_state_frame = f
	var raw = JavaScriptBridge.eval("window.CWFilm ? window.CWFilm.state() : ''", true)
	if typeof(raw) == TYPE_STRING and raw != "":
		var d = JSON.parse_string(raw)
		if d is Dictionary:
			_state = d
			_pending_events |= int(d.get("ev", 0))
	return _state


func is_open() -> bool:
	return _open


func is_ready() -> bool:
	return bool(_read().get("ready", false))


func is_playing() -> bool:
	return bool(_read().get("playing", false))


func has_finished() -> bool:
	return bool(_read().get("finished", false))


func has_failed() -> bool:
	return bool(_read().get("failed", false))


func get_error() -> String:
	return String(_read().get("error", ""))


func get_position() -> float:
	return float(_read().get("pos", 0.0))


func get_length() -> float:
	return float(_read().get("len", 0.0))


func seek(seconds: float) -> void:
	if _open:
		JavaScriptBridge.eval("window.CWFilm.seek(%f)" % seconds, true)


func get_video_size() -> Vector2:
	var s := _read()
	return Vector2(float(s.get("w", 0)), float(s.get("h", 0)))


## Which copy hls.js is playing (-1: Safari's own player, which doesn't say).
func get_level() -> int:
	return int(_read().get("level", -1))


func set_volume(v: float) -> void:
	_volume = v
	if _open:
		JavaScriptBridge.eval("window.CWFilm.set_volume(%f)" % v, true)


func get_volume() -> float:
	return _volume


func set_opacity(k: float) -> void:
	if _open:
		JavaScriptBridge.eval("window.CWFilm.set_opacity(%f)" % k, true)


func set_visible(on: bool) -> void:
	if _open:
		JavaScriptBridge.eval("window.CWFilm.set_visible(%s)" % ("true" if on else "false"), true)


func is_visible() -> bool:
	return _open


func set_subtitle(text: String) -> void:
	if _open:
		JavaScriptBridge.eval("window.CWFilm.set_subtitle(%s)" % JSON.stringify(text), true)


func show_skip(on: bool, text: String) -> void:
	_skip_shown = on
	if _open:
		JavaScriptBridge.eval("window.CWFilm.show_skip(%s, %s)" % ["true" if on else "false", JSON.stringify(text)], true)


## Events since the last call (TAPPED, SKIP_PRESSED, FINISHED, FAILED bits).
func poll() -> int:
	_state_frame = -1
	_read()
	var ev := _pending_events
	_pending_events = 0
	return ev
