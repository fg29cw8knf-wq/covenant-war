class_name SpeedTest
extends CanvasLayer
## What the picture costs this computer, measured on the computer itself
## (18 November, Gary: "Game not running smoothly frame rate is between
## 15-19fps", on his M1 Mac, and, asked for a lighter picture: "no i want it
## to run smoothly while looking the best"). Nothing the game is built on has
## a graphics card, so three rounds of work on its frame rate were done
## without one number from a real Mac. This is that number, taken where the
## player stands: Options, "Test this computer's speed".
##
## With the game stopped and its menu out of the way it times the picture as
## it is, then again with one thing changed at a time (CASES): the 3D at half
## size, each kind of light and shadow off, the grass, the people, and the
## ways a smaller picture can be brought back up to the screen's size. Each
## is given SETTLE to come to rest and timed for MEASURE, with the screen's
## own frame limit off, so about a minute in all. Then everything is put back
## exactly as it was, and what it found is shown, copied (the Copy button),
## and kept in user://speed_test.txt. Each line's "saves" is how much shorter
## a frame was without that thing: where the time goes on this machine.
##
## It changes nothing for good and decides nothing: it's for whoever is
## making the game faster to read (tests/speed_test_test.tscn runs it).

## Seconds a change is left to settle, and timed for (a test shortens both).
static var settle := 0.7
static var measure := 1.6
## The last report, and whether one is being made now (Gfx.Guard waits).
static var last := ""
static var running := false

const FILE := "user://speed_test.txt"

signal done(text: String)

var _menu: Control = null
var _place := ""
var _views: Array = []
var _status: Label
var _was_paused := false
var _rows: Array = []     # [label, fps, ms, gpu ms, note]


## Starts one over everything. `menu`: the pause menu, hidden while it runs
## and shown again after; `place`: where the player is, for the report.
static func run(tree: SceneTree, menu: Control = null, place := "") -> SpeedTest:
	var st := SpeedTest.new()
	st._menu = menu
	st._place = place
	st.layer = 126
	st.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.root.add_child(st)
	return st


func _ready() -> void:
	var stop := Control.new()
	stop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(stop)
	_status = Label.new()
	_status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_status.offset_top = -96.0
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 28)
	_status.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	_status.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_status.add_theme_constant_override("outline_size", 8)
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_status)
	_go()


func _input(e: InputEvent) -> void:
	# (nothing reaches the game or its menu while it's being timed)
	if SpeedTest.running and not (e is InputEventMouseMotion):
		get_viewport().set_input_as_handled()


# ------------------------------------------------------------- the run ----

func _go() -> void:
	SpeedTest.running = true
	var tree := get_tree()
	_was_paused = tree.paused
	if _menu != null:
		_menu.visible = false
	tree.paused = true
	for r in Gfx.Guard._views:
		var vp = (r as WeakRef).get_ref()
		if vp != null and is_instance_valid(vp):
			_views.append(vp)
	if not _views.has(tree.root):
		_views.append(tree.root)
	var vsync := DisplayServer.window_get_vsync_mode()
	var cap := Engine.max_fps
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	for vp: Viewport in _views:
		RenderingServer.viewport_set_measure_render_time(vp.get_viewport_rid(), true)
	var cases := _cases()
	var n := cases.size() + 1
	_say(1, n)
	var base: Dictionary = await _time()
	var counts := _counts()
	_rows.append(["As it is now", base.fps, base.ms, base.gpu, ""])
	var k := 1
	for c: Array in cases:
		k += 1
		_say(k, n)
		var undo: Variant = (c[1] as Callable).call()
		if undo == null:
			_rows.append([String(c[0]), -1.0, 0.0, 0.0, "not on here"])
			continue
		var got: Dictionary = await _time()
		(undo as Callable).call()
		_rows.append([String(c[0]), got.fps, got.ms, got.gpu, _saves(float(base.ms) - float(got.ms))])
	# (and once more as it was: how far two readings of the same thing differ)
	_say(n, n)
	var again: Dictionary = await _time()
	_rows.append(["As it is now, again", again.fps, again.ms, again.gpu, ""])
	for vp: Viewport in _views:
		if is_instance_valid(vp):
			RenderingServer.viewport_set_measure_render_time(vp.get_viewport_rid(), false)
	DisplayServer.window_set_vsync_mode(vsync)
	Engine.max_fps = cap
	var text := _report(counts)
	SpeedTest.last = text
	var f := FileAccess.open(FILE, FileAccess.WRITE)
	if f != null:
		f.store_string(text)
		f.close()
	SpeedTest.running = false
	_status.visible = false
	_show(text)
	done.emit(text)


func _say(k: int, n: int) -> void:
	_status.text = "(Testing this computer's speed: %d of %d. Hands off for a minute.)" % [k, n]


## One timing: SETTLE left alone, then MEASURE's frames counted by the clock.
func _time() -> Dictionary:
	var tree := get_tree()
	var t0 := Time.get_ticks_usec()
	while Time.get_ticks_usec() - t0 < int(SpeedTest.settle * 1000000.0):
		await tree.process_frame
	var frames := 0
	var gpu := 0.0
	t0 = Time.get_ticks_usec()
	while frames == 0 or Time.get_ticks_usec() - t0 < int(SpeedTest.measure * 1000000.0):
		await tree.process_frame
		frames += 1
		for vp: Viewport in _views:
			if is_instance_valid(vp):
				gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp.get_viewport_rid())
	var secs := maxf(0.000001, (Time.get_ticks_usec() - t0) / 1000000.0)
	return {"fps": frames / secs, "ms": secs * 1000.0 / frames, "gpu": gpu / frames}


static func _saves(ms: float) -> String:
	if absf(ms) < 0.05:
		return "saves nothing"
	return ("saves %.1f ms" % ms) if ms > 0.0 else ("costs %.1f ms more" % -ms)


## What a frame is made of now (taken with the first timing).
func _counts() -> Dictionary:
	return {
		"objects": int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)),
		"tris": int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)),
		"calls": int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)),
		"video": int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED)),
		"textures": int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED)),
	}


# ----------------------------------------------------------- the cases ----
# Each: [what it's called, a Callable that makes the change and gives back
# the Callable that undoes it, or null when there's nothing here to change].

func _cases() -> Array:
	var plain: Array = [
		["3D at half size", _scaled.bind(Viewport.SCALING_3D_MODE_BILINEAR, 0.5)],
		["No edge smoothing (MSAA)", _no_msaa],
		["No bounce light (SDFGI)", _env_off.bind("sdfgi_enabled")],
		["No bounce light's partner (SSIL)", _env_off.bind("ssil_enabled")],
		["No contact shadows (SSAO)", _env_off.bind("ssao_enabled")],
		["No haze (volumetric fog)", _env_off.bind("volumetric_fog_enabled")],
		["No glow", _env_off.bind("glow_enabled")],
		["No reflections (SSR)", _env_off.bind("ssr_enabled")],
		["No sun or moon shadows", _lights.bind(true, false)],
		["No lamp shadows", _lights.bind(false, false)],
		["No lamps at all", _lights.bind(false, true)],
		["No grass, leaves or crowds of one thing", _hide.bind("MultiMeshInstance3D")],
		["No people or creatures", _hide.bind("Figure3D")],
		["No sparks, snow or smoke", _hide.bind("GPUParticles3D")],
	]
	var all: Array = plain.duplicate()
	all.append(["All of the above at once", _together.bind(plain)])
	all.append_array([
		["Shadow maps half as fine", _shadow_maps_half],
		["Bounce light worked out at half size", _gi_half],
		["Rebuilt from 77% (MetalFX Temporal)", _scaled.bind(Viewport.SCALING_3D_MODE_METALFX_TEMPORAL, 0.77)],
		["Rebuilt from 67% (MetalFX Temporal)", _scaled.bind(Viewport.SCALING_3D_MODE_METALFX_TEMPORAL, 0.67)],
		["Rebuilt from 50% (MetalFX Temporal)", _scaled.bind(Viewport.SCALING_3D_MODE_METALFX_TEMPORAL, 0.5)],
		["Sharpened from 67% (MetalFX Spatial)", _scaled.bind(Viewport.SCALING_3D_MODE_METALFX_SPATIAL, 0.67)],
		["Full size, edges by MetalFX not MSAA", _scaled.bind(Viewport.SCALING_3D_MODE_METALFX_TEMPORAL, 1.0)],
	])
	return all


func _scaled(mode: int, k: float) -> Variant:
	var was: Array = []
	for vp: Viewport in _views:
		was.append([vp, vp.scaling_3d_mode, vp.scaling_3d_scale])
		vp.scaling_3d_mode = mode as Viewport.Scaling3DMode
		vp.scaling_3d_scale = k
	return func() -> void:
		for w: Array in was:
			if is_instance_valid(w[0]):
				(w[0] as Viewport).scaling_3d_mode = w[1]
				(w[0] as Viewport).scaling_3d_scale = w[2]


func _no_msaa() -> Variant:
	var was: Array = []
	for vp: Viewport in _views:
		if vp.msaa_3d != Viewport.MSAA_DISABLED:
			was.append([vp, vp.msaa_3d])
			vp.msaa_3d = Viewport.MSAA_DISABLED
	if was.is_empty():
		return null
	return func() -> void:
		for w: Array in was:
			if is_instance_valid(w[0]):
				(w[0] as Viewport).msaa_3d = w[1]


## Every 3D view's own environment (the world's, or its camera's).
func _envs() -> Array:
	var out: Array = []
	for vp: Viewport in _views:
		var w3: World3D = vp.find_world_3d()
		var env: Environment = w3.environment if w3 != null else null
		if env == null:
			var cam := vp.get_camera_3d()
			env = cam.environment if cam != null else null
		if env != null and not out.has(env):
			out.append(env)
	return out


func _env_off(prop: String) -> Variant:
	var was: Array = []
	for env: Environment in _envs():
		if bool(env.get(prop)):
			was.append(env)
			env.set(prop, false)
	if was.is_empty():
		return null
	return func() -> void:
		for env: Environment in was:
			env.set(prop, true)


## The sun and moon's shadows (`sun`), or the lamps' (or, `whole`, the lamps
## themselves).
func _lights(sun: bool, whole: bool) -> Variant:
	var was: Array = []
	for l: Light3D in get_tree().root.find_children("*", "Light3D", true, false):
		if not l.is_visible_in_tree() or (l is DirectionalLight3D) != sun:
			continue
		if whole:
			was.append(l)
			l.visible = false
		elif l.shadow_enabled:
			was.append(l)
			l.shadow_enabled = false
	if was.is_empty():
		return null
	return func() -> void:
		for l: Light3D in was:
			if is_instance_valid(l):
				if whole:
					l.visible = true
				else:
					l.shadow_enabled = true


func _hide(kind: String) -> Variant:
	var was: Array = []
	var todo: Array = [get_tree().root]
	while not todo.is_empty():
		var n: Node = todo.pop_back()
		todo.append_array(n.get_children())
		var hit := false
		match kind:
			"Figure3D":
				hit = n is Figure3D
			"GPUParticles3D":
				hit = n is GPUParticles3D or n is CPUParticles3D
			_:
				hit = n.is_class(kind)
		if hit and (n as Node3D).visible and (n as Node3D).is_visible_in_tree():
			was.append(n)
			(n as Node3D).visible = false
	if was.is_empty():
		return null
	return func() -> void:
		for n: Node3D in was:
			if is_instance_valid(n):
				n.visible = true


func _together(cases: Array) -> Variant:
	var undo: Array = []
	for c: Array in cases:
		var u: Variant = (c[1] as Callable).call()
		if u != null:
			undo.append(u)
	return func() -> void:
		undo.reverse()
		for u: Callable in undo:
			u.call()


func _shadow_maps_half() -> Variant:
	var now := Gfx.Best.SHADOW_MAP if Gfx.Best.on() else int(ProjectSettings.get_setting("rendering/lights_and_shadows/directional_shadow/size", 4096))
	RenderingServer.directional_shadow_atlas_set_size(now / 2, true)
	var was: Array = []
	for vp: Viewport in _views:
		was.append([vp, vp.positional_shadow_atlas_size])
		vp.positional_shadow_atlas_size = maxi(256, vp.positional_shadow_atlas_size / 2)
	return func() -> void:
		for w: Array in was:
			if is_instance_valid(w[0]):
				(w[0] as Viewport).positional_shadow_atlas_size = w[1]
		Gfx.Best.apply_all(get_tree())


func _gi_half() -> Variant:
	var on := false
	for env: Environment in _envs():
		on = on or env.sdfgi_enabled
	if not on:
		return null
	RenderingServer.gi_set_use_half_resolution(not Gfx.gi_half)
	return func() -> void:
		RenderingServer.gi_set_use_half_resolution(Gfx.gi_half)


# ---------------------------------------------------------- the report ----

func _report(counts: Dictionary) -> String:
	var root := get_tree().root
	var out := PackedStringArray()
	out.append("The Covenant War speed test · build %s · Godot %s" % [Packs.build_label(), Engine.get_version_info().string])
	var mem: Dictionary = OS.get_memory_info()
	out.append("%s · %s · %s %s · %.0f GB · %s, %s" % [OS.get_processor_name(), RenderingServer.get_video_adapter_name(), OS.get_name(), OS.get_version(),
		float(mem.get("physical", 0)) / 1073741824.0, RenderingServer.get_current_rendering_driver_name(), RenderingServer.get_current_rendering_method()])
	var screen := DisplayServer.screen_get_size()
	var win := root.size
	var hz := DisplayServer.screen_get_refresh_rate()
	out.append("Screen %d x %d at %s · window %d x %d · 3D at %d%% · Best picture %s · smoothing %s%s" % [screen.x, screen.y, ("%d Hz" % roundi(hz)) if hz > 1.0 and hz < 1000.0 else "a rate not known",
		win.x, win.y, roundi(root.scaling_3d_scale * 100.0), "on" if Gfx.Best.on() else "off", "on" if Gfx.Guard.on() else "off",
		", no bounce light" if Gfx.Guard.lean else ""])
	out.append("%s · %s triangles, %d draw calls, %d objects a frame · %d MB of video memory (%d MB pictures)" % [_place if _place != "" else "Place not named",
		_thousands(int(counts.tris)), int(counts.calls), int(counts.objects), int(counts.video) / 1048576, int(counts.textures) / 1048576])
	out.append("Being played, just before: %s" % (("%d frames a second" % roundi(Gfx.Guard.play_fps)) if Gfx.Guard.play_fps > 0.0 else "not known"))
	out.append("")
	for r: Array in _rows:
		if float(r[1]) < 0.0:
			out.append("%-42s %s" % [r[0], r[4]])
		else:
			out.append("%-42s %5.1f fps  %6.1f ms%s%s" % [r[0], float(r[1]), float(r[2]), ("  (graphics card %.1f)" % float(r[3])) if float(r[3]) > 0.0 else "", ("  " + String(r[4])) if String(r[4]) != "" else ""])
	return "\n".join(out)


static func _thousands(n: int) -> String:
	if n >= 1000000:
		return "%.1f million" % (n / 1000000.0)
	return "%d thousand" % (n / 1000)


## What it found, over everything, with Copy and Close.
func _show(text: String) -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.025, 0.045, 0.94)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 48.0
	v.offset_right = -48.0
	v.offset_top = 28.0
	v.offset_bottom = -28.0
	v.add_theme_constant_override("separation", 10)
	add_child(v)
	var head := UITheme.label("This computer's speed", 34, UITheme.GOLD)
	v.add_child(head)
	var body := Label.new()
	body.text = text
	body.autowrap_mode = TextServer.AUTOWRAP_OFF
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("font_size", 19)
	body.add_theme_color_override("font_color", UITheme.TEXT)
	var mono := SystemFont.new()
	mono.font_names = PackedStringArray(["Menlo", "SF Mono", "Consolas", "DejaVu Sans Mono", "monospace"])
	body.add_theme_font_override("font", mono)
	body.clip_text = true
	v.add_child(body)
	var note := UITheme.label("(A photo of this screen, or Copy and paste, shows what this computer needs. Send it to %s)" % NoticeScreen.CONTACT, 22, UITheme.TEXT_DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(note)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	v.add_child(row)
	var copy := UITheme.button("Copy", true, 260)
	copy.pressed.connect(func() -> void:
		DisplayServer.clipboard_set(text)
		copy.text = "Copied")
	row.add_child(copy)
	var close := UITheme.button("Close", false, 260)
	close.pressed.connect(_close)
	row.add_child(close)


func _close() -> void:
	if _menu != null and is_instance_valid(_menu):
		_menu.visible = true
	else:
		get_tree().paused = _was_paused
	queue_free()
