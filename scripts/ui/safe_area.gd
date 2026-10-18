class_name SafeArea
extends RefCounted
## Keeps the buttons and words clear of a phone's Dynamic Island (or notch),
## its rounded corners and the home bar, while backgrounds, paintings and the
## 3D still go right to the edges of the screen. Every screen uses this one
## helper:
##
##   SafeArea.fit(control, margin)    a full-screen control shrunk to the safe
##                                    area (and at least `margin` in from each
##                                    edge), kept that way as the screen changes
##                                    (and, with `scaled`, drawn at the player's
##                                    "Text and buttons size", ui_scale())
##   SafeArea.rect()                  the safe area, in the UI's own units (the
##                                    1920 x 1080 base stretched to the screen)
##   SafeArea.insets()                how far in it is from each edge, in those
##                                    units: x left, y top, z right, w bottom
##   SafeArea.watch(node, callable)   calls back now and whenever it changes
##                                    (or the text size does: refresh())
##
## Where the numbers come from:
##   - the iPhone/iPad (and Android) app: DisplayServer.get_display_safe_area();
##   - the phone link: the page's CSS env(safe-area-inset-*), read through
##     JavaScriptBridge (index.html asks for viewport-fit=cover, see
##     tools/build_web.sh; without it Safari leaves bars there by itself);
##   - a computer: nothing to keep clear of;
##   - a test: `-- --safe-area=L,T,R,B` (window pixels), or SafeArea.simulate().
## An iPhone 16 Pro Max held sideways keeps 62 points clear at either side and
## 21 at the bottom: 186 and 63 of its 2868 x 1320 pixels, or about 152 and 52
## of the game's units. At half size that's
##   godot --resolution 1434x660 ... -- --safe-area=93,0,93,32

## The page's safe-area insets in canvas pixels, "left,top,right,bottom".
const WEB_JS := """(function () {
	var d = document.getElementById('cw-safe-probe');
	if (!d) {
		d = document.createElement('div');
		d.id = 'cw-safe-probe';
		d.style.cssText = 'position:fixed;left:0;top:0;width:0;height:0;visibility:hidden;pointer-events:none;' +
			'padding-top:env(safe-area-inset-top,0px);padding-right:env(safe-area-inset-right,0px);' +
			'padding-bottom:env(safe-area-inset-bottom,0px);padding-left:env(safe-area-inset-left,0px)';
		document.body.appendChild(d);
	}
	var s = getComputedStyle(d);
	var c = document.getElementById('canvas');
	var k = (c && c.clientWidth) ? c.width / c.clientWidth : (window.devicePixelRatio || 1);
	return [s.paddingLeft, s.paddingTop, s.paddingRight, s.paddingBottom]
		.map(function (v) { return (parseFloat(v) || 0) * k; }).join(',');
}())"""

static var _sim = null          # simulated insets (window pixels), or null
static var _args_read := false
static var _px := Vector4.ZERO  # the last insets read (window pixels)
static var _px_at := -100000
static var _px_win := Vector2i.ZERO


## Pretends the screen has these insets (window pixels: x left, y top, z right,
## w bottom) and lays every screen out again; null goes back to the real ones.
static func simulate(px) -> void:
	_args_read = true
	_sim = px
	_px_at = -100000
	refresh()


## The insets in window pixels: x left, y top, z right, w bottom.
static func pixels() -> Vector4:
	if not _args_read:
		_args_read = true
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--safe-area="):
				var p := a.trim_prefix("--safe-area=").split(",")
				if p.size() == 4:
					_sim = Vector4(float(p[0]), float(p[1]), float(p[2]), float(p[3]))
	if _sim != null:
		return _sim
	var win := DisplayServer.window_get_size()
	var now := Time.get_ticks_msec()
	if now - _px_at < 250 and win == _px_win:
		return _px
	_px_at = now
	_px_win = win
	_px = _read(win)
	return _px


static func _read(win: Vector2i) -> Vector4:
	if OS.has_feature("web"):
		var s = JavaScriptBridge.eval(WEB_JS, true)
		var p := str(s).split(",")
		if p.size() == 4:
			return Vector4(float(p[0]), float(p[1]), float(p[2]), float(p[3])).max(Vector4.ZERO)
		return Vector4.ZERO
	if OS.has_feature("mobile"):
		var safe := DisplayServer.get_display_safe_area()
		var at := DisplayServer.window_get_position()
		if safe.size.x <= 0 or safe.size.y <= 0:
			return Vector4.ZERO
		return Vector4(safe.position.x - at.x, safe.position.y - at.y,
			at.x + win.x - safe.end.x, at.y + win.y - safe.end.y).max(Vector4.ZERO)
	return Vector4.ZERO


## UI units per window pixel (the game draws its 1920 x 1080 base stretched).
static func _units() -> float:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root.size.y <= 0:
		return 1.0
	return tree.root.get_visible_rect().size.y / float(tree.root.size.y)


## How far the safe area is in from each edge, in UI units: x left, y top,
## z right, w bottom.
static func insets() -> Vector4:
	return (pixels() * _units()).round()


## The whole screen in UI units.
static func screen() -> Rect2:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_visible_rect() if tree != null else Rect2(0, 0, 1920, 1080)


## The safe area in UI units: the screen less the insets.
static func rect() -> Rect2:
	var s := screen()
	var m := insets()
	return Rect2(s.position + Vector2(m.x, m.y), s.size - Vector2(m.x + m.z, m.y + m.w))


## Keeps a full-screen control inside the safe area, and at least `margin`
## (x at the sides, y top and bottom) in from the screen's edges. `scaled`:
## it's also drawn at the player's "Text and buttons size" (ui_scale()), laid
## out in a smaller area that the scale brings back up to the safe area.
static func fit(c: Control, margin := Vector2.ZERO, scaled := false) -> void:
	c.set_anchors_preset(Control.PRESET_TOP_LEFT if scaled else Control.PRESET_FULL_RECT)
	watch(c, func() -> void:
		var m := insets()
		var tl := Vector2(maxf(m.x, margin.x), maxf(m.y, margin.y))
		var br := Vector2(maxf(m.z, margin.x), maxf(m.w, margin.y))
		if not scaled:
			c.offset_left = tl.x
			c.offset_top = tl.y
			c.offset_right = -br.x
			c.offset_bottom = -br.y
			return
		var k := ui_scale()
		c.scale = Vector2(k, k)
		c.position = tl
		c.size = (screen().size - tl - br) / k)


## The player's "Text and buttons size" (Options; Game.settings.ui_scale): how
## much bigger the things to read and tap in the world, its menus and its
## films are drawn, for a small phone. 1 is the usual size.
const UI_SCALES := {"Normal": 1.0, "Larger": 1.15, "Largest": 1.3}


static func ui_scale() -> float:
	return clampf(float(Game.settings.get("ui_scale", 1.0)), 1.0, 1.3)


## Lays every screen out again (after the text size changes).
static func refresh() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.root.size_changed.emit()


## Calls `f` now (or as soon as `n` is in the tree) and again whenever the
## screen's size or safe area changes, for as long as `n` lives.
static func watch(n: Node, f: Callable) -> void:
	var w := _Watcher.new()
	w.name = "SafeAreaWatch"
	w.f = f
	n.add_child(w, false, Node.INTERNAL_MODE_BACK)   # internal: lists of the node's children never see it


## Lives under the node it lays out, so it goes when that does.
class _Watcher:
	extends Node
	var f: Callable
	var _last := Vector4(-1, -1, -1, -1)
	var _last_size := Vector2.ZERO
	var _t := 0.0

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		get_viewport().size_changed.connect(_check.bind(true))
		_check(true)

	func _process(delta: float) -> void:
		# the iPhone only reports its safe area once the view is on screen, and
		# Safari's bars come and go: look again now and then
		_t += delta
		if _t >= 0.5:
			_t = 0.0
			_check(false)

	func _check(force: bool) -> void:
		var m := SafeArea.insets()
		var s := get_viewport().get_visible_rect().size
		if not force and m == _last and s == _last_size:
			return
		_last = m
		_last_size = s
		if f.is_valid():
			f.call()
