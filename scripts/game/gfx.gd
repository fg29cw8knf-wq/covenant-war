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
	if OS.has_feature("web"):
		return 0
	match RenderingServer.get_current_rendering_method():
		"forward_plus":
			return 2 if full() else 1
		"mobile":
			return 1
	return 0


## Sets a viewport's 3D drawing size for this device: the game's own window,
## and the duel's 3D field (which has a viewport of its own).
static func apply(vp: Viewport) -> void:
	if vp == null or not is_phone():
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
	FpsMeter.show_on(tree, bool(Game.settings.get("show_fps", false)))


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
			_t = 0.0
			_frames = 0
			_worst = 0.0
