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

## Whether the bounce light (SDFGI) is worked out at half the picture's size
## and spread. Off, as the engine has it: the speed test times both
## (SpeedTest, "Bounce light worked out at half size"), and it's to be turned
## on only with a number from a real Mac and a look at the two pictures.
static var gi_half := false

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
		Best.dress(vp)
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
		Best.apply_all(tree)
	FpsMeter.show_on(tree, bool(Game.settings.get("show_fps", false)))


## The frame-rate guard, on a Mac or PC (11 November, Gary: "Whole Game
## running slow keeps freezing"). A computer draws everything at the
## screen's own size: on a MacBook's Retina screen that is five to eight
## million pixels of bounce light, fog and soft shadows a frame, and a Mac
## that can't draw that 40 times a second ran the whole game slow, with
## nothing in the game noticing. The guard watches the frame rate (a
## second and a half at a time, loading catches left out) and, when it has
## been under LOW for a few seconds, draws the 3D one step smaller and lets
## the Mac's own upscaler (MetalFX; FSR elsewhere) bring it back up to the
## full screen (rebuilt from the frames before it, since 18 November:
## `_size`): the words, cards and buttons are never touched, only the 3D.
## When it has run at the screen's own rate for a while it tries a step back
## up, and waits longer each time a step up doesn't hold, so it doesn't
## swing. If the smallest step still isn't enough it turns the bounce light
## (SDFGI) and its screen-space partner (SSIL) off in whatever place is
## showing, as the phone plays without them; that stays for the session.
## A Mac that keeps up never sees any of it: the picture stays at full size.
## Options: "Keep the frame rate smooth" (Game.settings.smooth_auto, on by
## default); off holds the full picture whatever the frame rate. It works
## under "Best picture" as well (Best, below), where it leaves the light be.
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
	## (18 November, Gary: "Game not running smoothly frame rate is between
	## 15-19fps". The guard came down one step every four and a half seconds,
	## so a Mac that needed the smallest size spent the first half minute of
	## every session at the frame rate it started with, and began again from
	## the full size the next time the game was opened.)
	## Well under (FAR_LOW) for FAR_AFTER windows running: two steps at once,
	## without waiting for DOWN_AFTER. And the step it has come to is kept
	## with the Options (Game.settings.gfx_step), so the next session starts
	## from it and tries a step up from there, as it does anyway.
	const FAR_LOW := 26.0
	const FAR_AFTER := 2
	const STEP_KEY := "gfx_step"
	## With the guard switched off the full picture is held whatever the
	## frame rate, and nothing says so: under BEST_LOW for BEST_AFTER windows
	## running, a line says it once a session (Told), with where to turn the
	## guard back on.
	const BEST_LOW := 24.0
	const BEST_AFTER := 4

	static var _me: Guard = null
	static var _views: Array = []     # WeakRefs of the viewports it sizes
	static var step := 0
	static var lean := false

	var _t := 0.0
	var _frames := 0
	var _low := 0
	var _far := 0
	var _best_low := 0
	var _high := 0
	static var told_best := false
	## The last window's frame rate (the speed test reads it: the game as it
	## was being played, before the test stopped it).
	static var last_fps := 0.0
	static var play_fps := 0.0   # (the last one with the game not paused)
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
		elif step == 0 and int(Game.settings.get(STEP_KEY, 0)) > 0:
			# (where the last session came to: tried up from there, not found again)
			step = clampi(int(Game.settings.get(STEP_KEY, 0)), 0, STEPS.size() - 1)
			_apply_all()

	## (18 November, Gary, asked for a "Smooth" picture that left things out:
	## "no i want it to run smoothly while looking the best". Until then
	## "Best picture" stood the guard down, so an M1 drew every pixel of a
	## Retina screen with the finest shadows at 15 to 19 frames a second.
	## The two are separate now: "Best picture" is how fine the light, the
	## shadows and the edges are, and the guard keeps the frame rate under
	## either, by drawing fewer pixels and rebuilding the rest (`_size`).
	## Off holds every pixel whatever the frame rate, as before.)
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
		# On a Mac the picture is rebuilt at the screen's size from the
		# frames before it (MetalFX Temporal, as the iPhone's has been since
		# October), not just sharpened (MetalFX Spatial, until 18 November):
		# a rebuilt picture keeps the fine detail a sharpened one has lost,
		# and smooths the edges itself, so the engine leaves multisampling
		# out under it. Where the Mac can't (an Intel one, an old macOS) the
		# engine falls back to sharpening by itself; a size under what the
		# rebuilder takes (`rebuild_least`) is sharpened too. FSR 1 on a PC,
		# and on the Compatibility renderer plain filtering, which is all it
		# has.
		if RenderingServer.get_current_rendering_method() == "gl_compatibility":
			vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
		elif OS.has_feature("macos") or force_rebuild:
			vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_METALFX_TEMPORAL if k >= rebuild_least() - 0.001 else Viewport.SCALING_3D_MODE_METALFX_SPATIAL
		else:
			vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
		vp.scaling_3d_scale = k

	## A test can ask for the Mac's way of bringing a smaller picture back up
	## on a machine that isn't one (the engine then uses FSR 2 for MetalFX).
	static var force_rebuild := false

	## The smallest size the Mac's rebuilder takes (it says: half, on the
	## Macs there are now), 0 where there isn't one.
	static func rebuild_least() -> float:
		var rd := RenderingServer.get_rendering_device()
		# (asked only where there is one: any other driver answers the
		# question with a number that means nothing, 1,073 on Vulkan)
		if rd == null or not rd.has_feature(RenderingDevice.SUPPORTS_METALFX_TEMPORAL):
			return 0.0
		return clampf(float(rd.limit_get(RenderingDevice.LIMIT_METALFX_TEMPORAL_SCALER_MIN_SCALE)) / 1000000.0, 0.0, 1.0)

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
		if real <= 0.0:
			return
		if SpeedTest.running:
			# (the speed test is timing the picture with things changed: not
			# the guard's to judge, or to change under it)
			_t = 0.0
			_frames = 0
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
		judge(fps)

	## One window's frame rate judged (the tests call it with made-up ones).
	func judge(fps: float) -> void:
		Guard.last_fps = fps
		if is_inside_tree() and not get_tree().paused:
			Guard.play_fps = fps
		if not Guard.on():
			# (the guard switched off: every pixel held, and said so once if
			# the computer can't draw them at a rate worth playing at)
			if fps < BEST_LOW:
				_best_low += 1
				if _best_low >= BEST_AFTER and not Guard.told_best:
					Guard.told_best = true
					Told.say(get_tree(), "(This computer is drawing the full picture at %d frames a second. For a smoother game: Options, Keep the frame rate smooth.)" % roundi(fps))
			else:
				_best_low = 0
			return
		_wait = maxf(0.0, _wait - WINDOW)
		if _stepped_up < INF:
			_stepped_up += WINDOW
		if Guard.lean and not Best.on():
			_lean_now()
		if fps < LOW:
			_high = 0
			_low += 1
			_far = _far + 1 if fps < FAR_LOW else 0
			var far := _far >= FAR_AFTER
			if _low >= DOWN_AFTER or far:
				_low = 0
				_far = 0
				if Guard.step < STEPS.size() - 1:
					if _stepped_up < 20.0:
						# the step up didn't hold: longer before the next try
						_retry = minf(RETRY_MOST, _retry * 2.0)
					_stepped_up = INF
					_wait = _retry
					Guard.step = mini(Guard.step + (2 if far else 1), STEPS.size() - 1)
					Guard._apply_all()
					Guard._keep()
				elif fps < LEAN_UNDER and not Guard.lean and not Best.on():
					# (never under "Best picture": that's a promise of all the light)
					Guard.lean = true
					_lean_now()
			return
		_low = 0
		_far = 0
		if fps >= _target() * UP_SHARE and Guard.step > 0 and not Guard.lean:
			_high += 1
			if _high >= UP_AFTER and _wait <= 0.0:
				_high = 0
				_stepped_up = 0.0
				Guard.step -= 1
				Guard._apply_all()
				Guard._keep()
		else:
			_high = 0

	## The step it's at kept with the Options, for the next session.
	static func _keep() -> void:
		if int(Game.settings.get(STEP_KEY, 0)) != step:
			Game.settings[STEP_KEY] = step
			Game.save_settings()

	## The bounce light and its partner off, in whatever place is showing
	## (looked for each window: a place built later has them on again), and
	## the haze (18 November: the duel's arena has one now too).
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
			if env != null and (env.sdfgi_enabled or env.ssil_enabled or env.volumetric_fog_enabled):
				env.sdfgi_enabled = false
				env.ssil_enabled = false
				env.volumetric_fog_enabled = false


## "Best picture", on a Mac or PC (14 November, Gary's yes to "a Best picture
## switch on the Mac: sharper edges and finer shadows, at some cost in
## smoothness"). Options: "Best picture" (Game.settings.best_picture, off by
## default). On, everything the game draws in 3D is drawn the sharpest it
## can be:
##   - edges: four samples a pixel where a view had two (4x MSAA: the world,
##     a duel's field, the Night of the White Sky), so a roof's edge, a
##     crystal's and a card's are smooth where they stepped;
##   - shadows: the sun's, the moon's and the tear's shadow map twice as
##     fine each way (8192 for 4096) and each lamp's the same, with the
##     softer of the renderer's filters (Soft High for Soft Low), so a
##     shadow's edge is clean close to and doesn't crawl as the camera moves;
##   - the small shadows where things meet (SSAO) worked out more finely;
##   - snow, grass and stone seen at a slant stay sharp into the distance
##     (16x anisotropic filtering for 4x);
##   - models keep their full shape however far off they are (no swapping
##     to their simpler copies);
##   - skies and haze shade without bands (debanding).
## It costs frame rate, most of it the edges and the shadow maps, and it
## can't be measured here (no graphics card), so it's a switch and it's off
## until asked for. Until 18 November the frame-rate guard stood down while
## it was on; now the guard keeps the frame rate under it too (Guard.on),
## by drawing fewer pixels and rebuilding the picture from them, and never
## takes the bounce light or the haze away while it's on (Guard.judge).
## Off puts every view back exactly as it was made (each one's own settings
## are kept on it: "gfx_was").
## A phone has its own two settings (Smooth and Full, above) and none of
## this.
class Best:
	const SHADOW_MAP := 8192
	const LAMP_MAP_MOST := 8192

	static func on() -> bool:
		if OS.has_feature("web") or Gfx.is_phone():
			return false
		return bool(Game.settings.get("best_picture", false))

	## One 3D view dressed for it, or put back as it was made.
	static func dress(vp: Viewport) -> void:
		if vp == null or not is_instance_valid(vp):
			return
		if not vp.has_meta("gfx_was"):
			vp.set_meta("gfx_was", [vp.msaa_3d, vp.positional_shadow_atlas_size, vp.anisotropic_filtering_level, vp.mesh_lod_threshold, vp.use_debanding])
		var was: Array = vp.get_meta("gfx_was")
		if on():
			# (a view made with no multisampling keeps none: it has its reasons)
			if int(was[0]) != Viewport.MSAA_DISABLED:
				vp.set("msaa_3d", maxi(int(was[0]), Viewport.MSAA_4X))
			vp.positional_shadow_atlas_size = clampi(int(was[1]) * 2, int(was[1]), maxi(int(was[1]), LAMP_MAP_MOST))
			vp.set("anisotropic_filtering_level", Viewport.ANISOTROPY_16X)
			vp.mesh_lod_threshold = 0.0
			vp.use_debanding = true
		else:
			vp.set("msaa_3d", int(was[0]))
			vp.positional_shadow_atlas_size = int(was[1])
			vp.set("anisotropic_filtering_level", int(was[2]))
			vp.mesh_lod_threshold = float(was[3])
			vp.use_debanding = bool(was[4])

	## What a view was made with, before any of this (the tests read it).
	static func was(vp: Viewport) -> Array:
		return vp.get_meta("gfx_was", [])

	## The renderer's own settings (the shadow maps and their filter, the
	## small shadows), and every 3D view there is now.
	static func apply_all(tree: SceneTree) -> void:
		var best := on()
		var ps := func(nm: String, fallback: Variant) -> Variant:
			var v: Variant = ProjectSettings.get_setting(nm)
			return v if v != null else fallback
		RenderingServer.directional_shadow_atlas_set_size(SHADOW_MAP if best else int(ps.call("rendering/lights_and_shadows/directional_shadow/size", 4096)), bool(ps.call("rendering/lights_and_shadows/directional_shadow/16_bits", true)))
		RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH if best else int(ps.call("rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality", 2)))
		RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH if best else int(ps.call("rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality", 2)))
		RenderingServer.environment_set_ssao_quality(
			RenderingServer.ENV_SSAO_QUALITY_HIGH if best else int(ps.call("rendering/environment/ssao/quality", 2)),
			bool(ps.call("rendering/environment/ssao/half_size", true)),
			float(ps.call("rendering/environment/ssao/adaptive_target", 0.5)),
			int(ps.call("rendering/environment/ssao/blur_passes", 2)),
			float(ps.call("rendering/environment/ssao/fadeout_from", 50.0)),
			float(ps.call("rendering/environment/ssao/fadeout_to", 300.0)))
		if tree != null:
			dress(tree.root)
		for r in Guard._views:
			var vp = (r as WeakRef).get_ref()
			if vp != null and is_instance_valid(vp) and (tree == null or vp != tree.root):
				dress(vp as Viewport)


## A line said once at the top of the screen and gone (the guard's, about
## "Best picture"): in brackets, as every word to the player that isn't a
## character's is.
class Told extends CanvasLayer:
	const SECS := 9.0
	static var last := ""   # (the tests read it)

	static func say(tree: SceneTree, text: String) -> void:
		last = text
		if tree == null or DisplayServer.get_name() == "headless":
			return
		var t := Told.new()
		t.layer = 127
		t.process_mode = Node.PROCESS_MODE_ALWAYS
		var l := Label.new()
		l.text = text
		l.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		l.offset_top = 64.0
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", 26)
		l.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		l.add_theme_constant_override("outline_size", 8)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.modulate.a = 0.0
		t.add_child(l)
		tree.root.add_child.call_deferred(t)
		var come := func() -> void:
			var tw := t.create_tween()
			tw.tween_property(l, "modulate:a", 1.0, 0.5)
			tw.tween_interval(SECS)
			tw.tween_property(l, "modulate:a", 0.0, 0.8)
			tw.tween_callback(t.queue_free)
		t.ready.connect(come, CONNECT_ONE_SHOT)


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
			if not Gfx.is_phone() and Guard.on() and (Guard.step > 0 or Guard.lean):
				_label.text += "  ·  3D at %d%%%s" % [roundi(Guard.scale_now() * 100.0), ", no bounce light" if Guard.lean else ""]
			# (and what it's being asked to draw, so a number sent in says which)
			if Best.on():
				_label.text += "  ·  Best picture on"
			if not Gfx.is_phone() and not Guard.on():
				_label.text += "  ·  smoothing off"
			_t = 0.0
			_frames = 0
			_worst = 0.0
