extends Node
## Autoload `Packs`. The web version is too big for a phone browser to hold all
## at once, so it comes as a main pack plus packs fetched the first time they're
## needed (tools/web_packs.py says what's in each):
##
##     await Packs.need("movie")      # before the opening movie
##     await Packs.need("duel")       # before a duel (Totem and Summon models)
##     await Packs.need("solhaven")   # before stepping into Solhaven
##     await Packs.need("looks")      # before the player is any look but A (B, C and D's models)
##
## Everywhere else (the iPhone and Mac apps, the editor, the tests) everything is
## in one pack and need() returns at once. On the web a loading screen shows the
## download; if it fails the player can try again.
##
## The build also says when it was made: BUILD_INFO is written by
## tools/build_web.sh and tools/build_ios.sh, and build_label() is the
## "Early build" shown on the title screen and the pause menu.

const BUILD_INFO := "res://build_info.cfg"
## Where downloaded packs are kept on the web (memory only, gone when the page closes).
const WEB_DIR := "/tmp/packs/"
const TITLES := {"movie": "the opening movie", "duel": "the Totems and Summons", "solhaven": "Solhaven", "looks": "your look",
	"midnight": "the Lantern Night", "dawn": "the morning after"}

signal _loaded(pack: String)

var _info := ConfigFile.new()
var _have := {}
var _busy := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if FileAccess.file_exists(BUILD_INFO):
		_info.load(BUILD_INFO)


## "15 Oct 2026, 16:42 BST" for a published build; the version number otherwise.
func build_label() -> String:
	return str(_info.get_value("build", "published", ProjectSettings.get_setting("application/config/version", "")))


## What tells one build from the next (the build's id from tools/build_info.sh;
## the version number for a run from the editor).
func build_id() -> String:
	return str(_info.get_value("build", "id", ProjectSettings.get_setting("application/config/version", "")))


## Whether a pack is ready (always true outside the split web build).
func has(pack: String) -> bool:
	return not _sizes().has(pack) or _have.has(pack)


## Whether this build has a pack of that name to fetch (the split web build),
## loaded or not: what's in it exists, even before ResourceLoader can see it.
func in_build(pack: String) -> bool:
	return _sizes().has(pack)


## Makes sure a pack is loaded, downloading it on the web the first time.
## Returns true once it's there. With `skippable`, the loading screen has a
## Skip button (the opening movie: nobody should sit through its download to
## skip it): pressed, the download is dropped and need() returns false.
func need(pack: String, skippable := false) -> bool:
	if has(pack):
		return true
	if _busy.has(pack):
		while not _have.has(pack) and _busy.has(pack):
			await _loaded
		return _have.has(pack)
	_busy[pack] = true
	var screen := _Screen.new()
	screen.what = TITLES.get(pack, "a Summon's clip" if pack.begins_with("summon_") else pack)
	screen.skippable = skippable
	add_child(screen)
	var got := false
	while true:
		got = await _fetch(pack, screen)
		if got or screen.skipped:
			break
		await screen.retry()
	screen.queue_free()
	if got:
		_have[pack] = true
	_busy.erase(pack)
	_loaded.emit(pack)
	return got


## Fetches a pack quietly, with no loading screen, for what can wait for it
## (the voices: a line said before its pack has come plays without one).
func want(pack: String) -> void:
	if has(pack) or _busy.has(pack):
		return
	_busy[pack] = true
	var got := await _fetch(pack, null)
	if got:
		_have[pack] = true
	_busy.erase(pack)
	_loaded.emit(pack)


## A holding screen for a wait that isn't a download (New Game's Ashford still
## being built after the movie's skipped): `what` is finished by the caller
## with `free_hold()`. The bar creeps along meanwhile so it's seen to be alive.
func hold(what: String) -> CanvasLayer:
	var screen := _Screen.new()
	screen.what = what
	add_child(screen)
	screen.creep(7.0)
	return screen


func _sizes() -> Dictionary:
	if not OS.has_feature("web"):
		return {}
	return _info.get_value("packs", "sizes", {})


## Downloads a pack with the browser's own fetch, straight into one buffer the
## size of the pack, then hands it to the engine's file system. (Godot's
## HTTPRequest can't save a download to a file on the web, and the game's own
## memory never shrinks once grown, so the pack mustn't pass through it.)
const FETCH_JS := """(function () {
	var all = window.__packs = window.__packs || {};
	var ctrl = (typeof AbortController !== 'undefined') ? new AbortController() : null;
	var s = all[NAME] = {done: 0, state: 'loading', ctrl: ctrl};
	fetch(URL, ctrl ? {signal: ctrl.signal} : {}).then(function (r) {
		if (!r.ok) throw new Error('HTTP ' + r.status);
		var buf = new Uint8Array(SIZE), reader = r.body.getReader();
		var pump = function () {
			return reader.read().then(function (res) {
				if (res.done) return;
				if (s.done + res.value.length > SIZE) throw new Error('bigger than expected');
				buf.set(res.value, s.done);
				s.done += res.value.length;
				return pump();
			});
		};
		return pump().then(function () {
			if (s.done !== SIZE) throw new Error('only ' + s.done + ' bytes');
			engine.copyToFS(PATH, buf.buffer);
			s.state = 'ok';
		});
	}).catch(function (e) { s.state = String(e); });
})();"""


func _fetch(pack: String, screen: _Screen) -> bool:
	var path := WEB_DIR + pack + ".pck"
	var total := int(_sizes()[pack])
	JavaScriptBridge.eval(FETCH_JS.replace("NAME", JSON.stringify(pack)).replace("SIZE", str(total))
		.replace("PATH", JSON.stringify(path))
		.replace("URL", JSON.stringify("packs/%s.pck?v=%s" % [pack, _info.get_value("build", "id", "0")])), true)
	var state := "loading"
	while state == "loading":
		await get_tree().process_frame
		if screen != null and screen.skipped:
			# dropped: the browser's fetch is told to stop, and the pack is
			# fetched afresh if it's ever wanted
			JavaScriptBridge.eval("(window.__packs[%s] || {}).ctrl && window.__packs[%s].ctrl.abort()" % [JSON.stringify(pack), JSON.stringify(pack)], true)
			return false
		var s = JSON.parse_string(str(JavaScriptBridge.eval("JSON.stringify(window.__packs[%s])" % JSON.stringify(pack), true)))
		state = s.state if s is Dictionary else "lost track of the download"
		if screen != null:
			screen.progress(int(s.done) if s is Dictionary else 0, total)
	if state == "ok" and not ProjectSettings.load_resource_pack(path):
		state = "not a pack"
	if state != "ok":
		push_warning("Packs: couldn't load %s: %s" % [pack, state])
	return state == "ok"


## The loading screen: what's loading, a bar, and a retry button if it fails.
class _Screen:
	extends CanvasLayer
	signal _again
	var what := ""
	## Shows a Skip button; `skipped` goes true when it's pressed.
	var skippable := false
	var skipped := false
	var _label: Label
	var _bar: Panel
	var _fill: Panel
	var _retry: Button
	var _skip: Button
	var _focus_before: Control   # the button underneath that had the keyboard focus

	func _ready() -> void:
		layer = 120
		# nothing under it answers a key or a pad meanwhile (the title's New
		# Game would take Enter through the bar); it gets the focus back after
		_focus_before = get_viewport().gui_get_focus_owner()
		get_viewport().gui_release_focus()
		var bg := ColorRect.new()
		bg.color = Color(0.027, 0.031, 0.059, 0.92)
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.theme = UITheme.make()
		add_child(bg)
		var center := CenterContainer.new()
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.add_child(center)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 28)
		center.add_child(box)
		_label = UITheme.label("Loading %s…" % what, 36, UITheme.TEXT, "body", 6)
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.custom_minimum_size = Vector2(900, 0)
		box.add_child(_label)
		_bar = Panel.new()
		_bar.custom_minimum_size = Vector2(760, 14)
		_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_bar.add_theme_stylebox_override("panel", UITheme.sb(Color(1, 1, 1, 0.08), UITheme.GOLD_DIM, 7, 1, 0))
		box.add_child(_bar)
		_fill = Panel.new()
		_fill.add_theme_stylebox_override("panel", UITheme.sb(UITheme.GOLD, Color(0, 0, 0, 0), 7, 0, 0))
		_fill.size = Vector2(0, 14)
		_bar.add_child(_fill)
		_retry = UITheme.button("Try again", true, 400)
		_retry.visible = false
		_retry.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_retry.pressed.connect(func() -> void: _again.emit())
		box.add_child(_retry)
		if skippable:
			_skip = UITheme.button("Skip", false, 300)
			_skip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			_skip.pressed.connect(func() -> void:
				skipped = true
				_skip.disabled = true
				_label.text = "Skipping %s…" % what)
			box.add_child(_skip)

	## The bar creeping most of the way along over `secs`, for a wait with no
	## count to show.
	func creep(secs: float) -> void:
		_label.text = "%s…" % what
		var tw := create_tween()
		tw.tween_method(func(k: float) -> void:
			if is_instance_valid(_fill):
				_fill.size.x = 760.0 * (1.0 - pow(1.0 - k, 2.0)) * 0.92, 0.0, 1.0, secs)

	func progress(done: int, total: int) -> void:
		_fill.size.x = 760.0 * clampf(float(done) / maxf(total, 1), 0.0, 1.0)
		_label.text = "Loading %s…  %d of %d MB" % [what, done >> 20, maxi(total >> 20, 1)]

	func retry() -> void:
		_label.text = "Couldn't load %s. Check the connection and try again." % what
		_retry.visible = true
		_retry.grab_focus()
		await _again
		_retry.visible = false
		_fill.size.x = 0.0

	func _exit_tree() -> void:
		if is_instance_valid(_focus_before) and _focus_before.is_visible_in_tree():
			_focus_before.grab_focus()
