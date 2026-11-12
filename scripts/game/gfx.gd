class_name Gfx
extends RefCounted
## How hard the game pushes the graphics on this device.
##
## A Mac or PC gets everything (Forward+, light that bounces, volumetric fog,
## 42,000 grass clumps). A phone can't draw all that at its own screen size:
## an iPhone 16 Pro Max is 2868 x 1320 pixels and wants 120 frames a second,
## and with the Mac's settings it couldn't keep up, so everything ran slow and
## uneven. Phones (the iPhone/iPad app and Android) therefore play "Smooth" by
## default:
##   - the 3D is drawn at two-thirds size and sharpened back up to the full
##     screen by the phone's own upscaler (MetalFX on Apple, FSR 2 elsewhere),
##     which also smooths the edges, so 3D anti-aliasing (MSAA) is off;
##   - the village uses its phone detail level (Gfx.level() == 1): no
##     bounce light or volumetric fog, half the grass, simpler shadows;
##   - the frame rate is held at a steady 60 instead of chasing 120.
## The Options page can switch a phone to "Full" (the Mac's settings) to
## compare, and can show the frame rate. The phone link in a browser stays on
## its own lightest settings (level 0), whatever is chosen here.
##
## Run with `-- --phone` on a computer to see the Smooth profile.

## A test can set the detail level whatever it's drawn with (tests/mem_probe
## counts what a Mac holds and draws on a machine with no graphics card).
static var force_level := -1

## How big the 3D is drawn on a phone in Smooth, before upscaling.
const PHONE_SCALE := 0.67
const PHONE_FPS := 60


## True on the iPhone/iPad app and Android (not the phone link in a browser).
static func is_phone() -> bool:
	if OS.has_feature("web"):
		return false
	return OS.has_feature("mobile") or "--phone" in OS.get_cmdline_user_args()


## True when this device draws the Mac's full settings.
static func full() -> bool:
	if OS.has_feature("web"):
		return false
	if not is_phone():
		return true
	return String(Game.settings.get("graphics", "smooth")) == "full"


## The detail level the world is built at: 2 everything (Forward+ on a
## computer, or a phone set to Full), 1 phone, 0 the phone link.
static func level() -> int:
	if force_level >= 0:
		return force_level
	if OS.has_feature("web"):
		return 0
	match RenderingServer.get_current_rendering_method():
		"forward_plus":
			return 2 if full() else 1
		"mobile":
			return 1
	return 0


## Sets a viewport's 3D drawing size for this device: the game's own window,
## and the duel's 3D field (which has a viewport of its own). On a computer
## the viewport is also put on the frame-rate guard's list (Guard), which
## draws the 3D a little smaller only while the machine can't keep up.
static func apply(vp: Viewport) -> void:
	if vp == null:
		return
	if not is_phone():
		Guard.watch(vp)
		return
	if full():
		vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
		vp.scaling_3d_scale = 1.0
		return
	if RenderingServer.get_current_rendering_method() == "forward_plus":
		# MetalFX Temporal on Apple; Godot falls back to MetalFX Spatial or
		# FSR 2 by itself where it isn't available
		vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_METALFX_TEMPORAL
		vp.msaa_3d = Viewport.MSAA_DISABLED
	else:
		vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_METALFX_SPATIAL if OS.has_feature("ios") else Viewport.SCALING_3D_MODE_FSR
	vp.scaling_3d_scale = PHONE_SCALE


## Called once at start-up (by Game) and again when the Options change.
static func setup(tree: SceneTree) -> void:
	if is_phone():
		Engine.max_fps = 0 if full() else PHONE_FPS
		apply(tree.root)
	else:
		Guard.start(tree)
	FpsMeter.show_on(tree, bool(Game.settings.get("show_fps", false)))


## The frame-rate guard, on a Mac or PC (11 November, Gary: "Whole Game
## running slow keeps freezing"). A computer draws everything at the
## screen's own size: on a MacBook's Retina screen that is five to eight
## million pixels of bounce light, fog and soft shadows a frame, and a Mac
## that can't draw that 40 times a second ran the whole game slow, with
## nothing in the game noticing. The guard watches the frame rate (a
## second and a half at a time, loading catches left out) and, when it has
## been under LOW for a few seconds, draws the 3D one step smaller and lets
## the Mac's own upscaler (MetalFX; FSR elsewhere) sharpen it back up to the
## full screen: the words, cards and buttons are never touched, only the 3D.
## When it has run at the screen's own rate for a while it tries a step back
## up, and waits longer each time a step up doesn't hold, so it doesn't
## swing. If the smallest step still isn't enough it turns the bounce light
## (SDFGI) and its screen-space partner (SSIL) off in whatever place is
## showing, as the phone plays without them; that stays for the session.
## A Mac that keeps up never sees any of it: the picture stays at full size.
## Options: "Keep the frame rate smooth" (Game.settings.smooth_auto, on by
## default); off holds the full picture whatever the frame rate.
class Guard extends Node:
	## The 3D's size at each step (1 is the screen's own).
	const STEPS := [1.0, 0.87, 0.77, 0.67, 0.58, 0.5]
	const WINDOW := 1.5        # seconds measured at a time
	const LOW := 41.0          # under this for DOWN_AFTER windows running: a step down
	const DOWN_AFTER := 3
	const UP_AFTER := 10       # at the screen's own rate for this many windows: try a step up
	const UP_SHARE := 0.93     # ...this share of the screen's rate (or of 60) counts as its own
	const HITCH := 0.2         # a frame longer than this is a load, not a slow picture: left out
	const LEAN_UNDER := 31.0   # at the smallest step and still under this: the bounce light goes
	const RETRY_MOST := 300.0  # the longest it waits before trying a step up again (s)

	static var _me: Guard = null
	static var _views: Array = []     # WeakRefs of the viewports it sizes
	static var step := 0
	static var lean := false

	var _t := 0.0
	var _frames := 0
	var _low := 0
	var _high := 0
	var _retry := 15.0     # how long a step up must wait after one that didn't hold
	var _wait := 0.0
	var _stepped_up := INF # seconds since the last step up (INF: none to judge)

	static func start(tree: SceneTree) -> void:
		if OS.has_feature("web") or DisplayServer.get_name() == "headless":
			return
		# (not in a test: those run on a software renderer at a set frame
		# rate, where every frame is "slow"; `-- --guard` turns it on for
		# the guard's own test)
		var soft := RenderingServer.get_video_adapter_name().to_lower()
		if not "--guard" in OS.get_cmdline_user_args() and ("--fixed-fps" in OS.get_cmdline_args() or soft.contains("llvmpipe") or soft.contains("lavapipe") or soft.contains("swiftshader")):
			return
		if _me == null or not is_instance_valid(_me):
			_me = Guard.new()
			_me.name = "GfxGuard"
			_me.process_mode = Node.PROCESS_MODE_ALWAYS
			tree.root.add_child.call_deferred(_me)
			watch(tree.root)
		if not on():
			step = 0
			_apply_all()

	static func on() -> bool:
		return bool(Game.settings.get("smooth_auto", true))

	## Puts a viewport that draws 3D on the list, at the size the guard is at.
	static func watch(vp: Viewport) -> void:
		for r in _views:
			if (r as WeakRef).get_ref() == vp:
				return
		_views.append(weakref(vp))
		_size(vp)

	## The 3D's size now, as a share of the screen's (1: full).
	static func scale_now() -> float:
		return float(STEPS[clampi(step, 0, STEPS.size() - 1)])

	static func _size(vp: Viewport) -> void:
		var k := scale_now()
		if k >= 0.999:
			vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
			vp.scaling_3d_scale = 1.0
			return
		# the Mac's own sharpening upscaler; FSR 1 on a PC (and on the
		# Compatibility renderer plain filtering, which is all it has)
		if RenderingServer.get_current_rendering_method() == "gl_compatibility":
			vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
		elif OS.has_feature("macos"):
			vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_METALFX_SPATIAL
		else:
			vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
		vp.scaling_3d_scale = k

	static func _apply_all() -> void:
		var live: Array = []
		for r in _views:
			var vp = (r as WeakRef).get_ref()
			if vp != null and is_instance_valid(vp):
				live.append(r)
				_size(vp)
		_views = live

	## The screen's own rate, as far as it's known (60 when it isn't).
	func _target() -> float:
		var hz := DisplayServer.screen_get_refresh_rate()
		if hz <= 1.0:
			hz = 60.0
		if Engine.max_fps > 0:
			hz = minf(hz, float(Engine.max_fps))
		return minf(hz, 60.0)   # (holding 60 is keeping up, on a 120 Hz screen too)

	var _last_usec := 0

	func _process(_delta: float) -> void:
		# (by the clock, not the game's own time: slow motion in a duel and a
		# test's set frame rate aren't the machine being slow)
		var now := Time.get_ticks_usec()
		var real := (now - _last_usec) / 1000000.0 if _last_usec > 0 else 0.0
		_last_usec = now
		if not Guard.on() or real <= 0.0:
			return
		# (not while the window's in the background, where macOS slows it
		# on purpose, nor through a load's long frame)
		if not DisplayServer.window_is_focused() or real > HITCH:
			return
		_t += real
		_frames += 1
		if _t < WINDOW:
			return
		var fps := _frames / _t
		_t = 0.0
		_frames = 0
		_wait = maxf(0.0, _wait - WINDOW)
		if _stepped_up < INF:
			_stepped_up += WINDOW
		if Guard.lean:
			_lean_now()
		if fps < LOW:
			_high = 0
			_low += 1
			if _low >= DOWN_AFTER:
				_low = 0
				if Guard.step < STEPS.size() - 1:
					if _stepped_up < 20.0:
						# the step up didn't hold: longer before the next try
						_retry = minf(RETRY_MOST, _retry * 2.0)
					_stepped_up = INF
					_wait = _retry
					Guard.step += 1
					Guard._apply_all()
				elif fps < LEAN_UNDER and not Guard.lean:
					Guard.lean = true
					_lean_now()
			return
		_low = 0
		if fps >= _target() * UP_SHARE and Guard.step > 0 and not Guard.lean:
			_high += 1
			if _high >= UP_AFTER and _wait <= 0.0:
				_high = 0
				_stepped_up = 0.0
				Guard.step -= 1
				Guard._apply_all()
		else:
			_high = 0

	## The bounce light and its partner off, in whatever place is showing
	## (looked for each window: a place built later has them on again).
	func _lean_now() -> void:
		for r in Guard._views:
			var vp = (r as WeakRef).get_ref()
			if vp == null or not is_instance_valid(vp):
				continue
			var w3: World3D = (vp as Viewport).find_world_3d()
			var env: Environment = w3.environment if w3 != null else null
			if env == null:
				var cam := (vp as Viewport).get_camera_3d()
				env = cam.environment if cam != null else null
			if env != null and (env.sdfgi_enabled or env.ssil_enabled):
				env.sdfgi_enabled = false
				env.ssil_enabled = false


## A small frame-rate readout in the top corner (Options > Show frame rate),
## so a slow patch can be described with a number.
class FpsMeter extends CanvasLayer:
	var _label: Label
	var _t := 0.0
	var _frames := 0
	var _worst := 0.0

	static func show_on(tree: SceneTree, on: bool) -> void:
		var old := tree.root.get_node_or_null("FpsMeter")
		if old != null:
			old.queue_free()
		if on:
			var m := FpsMeter.new()
			m.name = "FpsMeter"
			tree.root.add_child.call_deferred(m)

	func _ready() -> void:
		layer = 128
		process_mode = Node.PROCESS_MODE_ALWAYS
		_label = Label.new()
		_label.position = Vector2(24, 18)
		_label.add_theme_font_size_override("font_size", 26)
		_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
		_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		_label.add_theme_constant_override("outline_size", 6)
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_label)

	func _process(delta: float) -> void:
		_t += delta
		_frames += 1
		_worst = maxf(_worst, delta)
		if _t >= 0.5:
			_label.text = "%d fps  (slowest frame %d ms)" % [roundi(_frames / _t), roundi(_worst * 1000.0)]
			# (on a computer: the size the frame-rate guard has the 3D at)
			if not Gfx.is_phone() and (Guard.step > 0 or Guard.lean):
				_label.text += "  ·  3D at %d%%%s" % [roundi(Guard.scale_now() * 100.0), ", no bounce light" if Guard.lean else ""]
			_t = 0.0
			_frames = 0
			_worst = 0.0
