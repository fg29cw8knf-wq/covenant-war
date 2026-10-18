class_name World
extends Node3D
## The walkable world: builds an area, puts the player and NPCs in it, and
## runs movement, the camera, talking and duels.
##
## Duels are handed to `duel_handler` (a Callable taking the duel spec and
## returning true if the player won). Main sets it; without it (in tests) the
## duel is decided by a quick AI-vs-AI simulation.

signal exit_to_title
## The area's story has moved on to something outside the walkable world.
signal story_next(what: String)

## Loaded when the area is entered: on the web Solhaven's script comes in its own
## pack (Packs.need("solhaven") first).
const AREAS := {
	"solhaven": "res://scripts/world/areas/solhaven.gd",
	"ashford": "res://scripts/world/areas/ashford.gd",
	"thornwood": "res://scripts/world/areas/thornwood.gd",
}

const SPEED := 5.4
const TALK_RANGE := 2.4
const CAM_OFFSET := Vector3(0, 8.2, 11.5)
const CAM_FOV := 32.0
## The camera looks at this point above the ground under the player.
const CAM_LOOK := Vector3(0, 1.1, 0)
## Camera zoom (Game.settings.cam_zoom): 1 is the usual view and higher comes
## closer, along the same line, so the angle never changes. Pinch, the mouse
## wheel, a trackpad, the + and - keys and buttons, and a pad's right stick
## change it; the Options page has a slider and a reset.
const ZOOM_MIN := 0.7      # furthest out
const ZOOM_MAX := 1.8      # closest in
## Holding a zoom key or the stick: the distance changes by e^this a second.
const ZOOM_RATE := 0.9
## How far the camera keeps from walls, roofs and trees (metres).
const CAM_CLEARANCE := 0.45

var duel_handler: Callable
var attract := false       # title-screen mode: no player control, a slow camera drift
var _attract_t := 0.0
var area_id := "solhaven"
var area: GDScript
var hud: WorldHUD
var cam: Camera3D
var player: CharacterBody3D
var player_doll: PaperDoll
var npcs: Array = []       # {def, body, doll}
var busy := false:         # talking, in a menu or a cutscene
	set(v):
		var was := busy
		busy = v
		if was and not v and is_inside_tree():
			_refresh_markers.call_deferred()   # (hidden while busy: back now)
var _move_target = null    # Vector3 or null
var _talk_target = null    # npc dict to talk to on arrival
var _near = null           # npc dict in range
var _focus := Vector3.ZERO
var _stuck_time := 0.0
var cine := false:         # a cutscene is driving the camera
	set(v):
		var was := cine
		cine = v
		if was and not v and is_inside_tree():
			_refresh_markers.call_deferred()
var _shake := 0.0
var music: Array = []      # the area's tracks (set by its build()), resumed after a duel
var _zoom := 1.0           # the zoom the camera is at now (it eases to the setting)
var _cam_clear := 1.0      # how much of the way out the camera can go without entering a wall (eased)
var _zoom_hold := 0.0      # a quick press of a zoom key or the stick zooms for at least this long
var _zoom_dir := 0.0
var _zoom_save := 0.0      # the setting is saved once the zoom has stopped changing for this long


## Brings the area's music back after a duel or a scene took it over; it
## carries on from where it left off (Music remembers), never from the top.
func resume_music() -> void:
	if not music.is_empty():
		Music.play(music, 1.5, true)


func setup(p_area: String, spawn: String) -> World:
	area_id = p_area if AREAS.has(p_area) else "solhaven"
	area = load(AREAS[area_id])
	Game.area = area_id
	Game.spawn = spawn
	return self


func _ready() -> void:
	if area == null:
		setup(Game.area, Game.spawn)
	_build_environment()
	area.build(self)
	_spawn_player(area.SPAWNS.get(Game.spawn, area.SPAWNS.values()[0]))
	for def in area.npcs():
		_spawn_npc(def)
	_build_camera()
	# a story film picking up where it was starts on black, not on the world
	if not attract and area.get_script_constant_map().has("RESUMES") and area.starts_black():
		Cine.overlay(self).black(true)
	if attract:
		var ca := cam.attributes as CameraAttributesPractical
		ca.dof_blur_far_distance = 52.0
		ca.dof_blur_far_transition = 30.0
		ca.dof_blur_near_enabled = false
		player.visible = false
		player.process_mode = Node.PROCESS_MODE_DISABLED
		return
	hud = WorldHUD.new()
	add_child(hud)
	hud.tapped.connect(_on_tap)
	hud.zoom_by.connect(zoom_by)
	hud.talk_pressed.connect(func() -> void:
		if _near != null and not busy:
			_talk(_near))
	hud.menu_action.connect(_on_menu)
	_refresh_markers()
	_arrive.call_deferred()


func _arrive() -> void:
	var key := "arrived_" + area_id
	if not Game.flag(key) and area.get_script_constant_map().has("INTRO"):
		area.intro_frame(self)   # start the camera on the intro's first shot before the fade
	await hud.fade(0.0, 0.6)
	# no place-name card over a story film picking up part-way
	if not (area.get_script_constant_map().has("RESUMES") and area.starts_black()):
		hud.show_area_title(area.NAME, area.SUBTITLE)
	if not Game.flag(key):
		Game.set_flag(key)
		busy = true
		hud.set_controls_visible(false)
		if area.get_script_constant_map().has("INTRO"):
			await area.intro(self)   # the area's own opening shot (Ashford's flight over the festival)
		else:
			await get_tree().create_timer(1.2).timeout
		await run_steps(area.arrival(), null)
		hud.dialogue.close()
		hud.set_controls_visible(true)
		busy = false
	if area.get_script_constant_map().has("RESUMES"):
		await area.resume(self)   # a story film the game was closed in the middle of
		if not is_inside_tree():
			return
	hud.set_objective(_fmt(String(Game.flag("objective", ""))))
	_show_first_steps()


## Bram teaches walking and talking in his own words (Spoken Script, P1). These
## two standing hints are only a fallback: they appear if a new player has done
## nothing for a while after his lesson, and go once each step is done.
func _show_first_steps() -> void:
	if attract or Game.settings.get("first_steps", 0) >= 2:
		return
	var step := int(Game.settings.get("first_steps", 0))
	await get_tree().create_timer(9.0).timeout
	if not is_inside_tree() or int(Game.settings.get("first_steps", 0)) != step:
		return
	if step == 0:
		hud.show_hint("Tap the ground where you want to walk.")
	else:
		hud.show_hint("Walk up to someone and tap the Talk button to speak to them.")


func _first_step_done(step: int) -> void:
	if int(Game.settings.get("first_steps", 0)) != step:
		return
	Game.settings["first_steps"] = step + 1
	Game.save_settings()
	hud.show_hint("")
	if step == 0:
		await get_tree().create_timer(2.5).timeout
		while busy and is_inside_tree():   # mid-conversation: wait for it to end
			await get_tree().create_timer(0.5).timeout
		if is_inside_tree():
			_show_first_steps()


# ============================================================ building ===

func _build_environment() -> void:
	if area.get_script_constant_map().has("CUSTOM_ENV"):
		return
	var e: Dictionary = area.ENV
	var we := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(e.sky_top)
	sm.sky_horizon_color = Color(e.sky_horizon)
	sm.ground_horizon_color = Color(e.ground_horizon)
	sm.ground_bottom_color = Color(e.ground_horizon).darkened(0.4)
	sm.sky_curve = 0.12
	sm.sun_angle_max = 20.0
	sm.sky_energy_multiplier = 1.1
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = float(e.ambient)
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.0
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.06
	env.glow_hdr_threshold = 1.1
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 1.6
	env.fog_enabled = true
	env.fog_light_color = Color(e.fog)
	env.fog_density = float(e.fog_density)
	env.fog_aerial_perspective = 0.35
	env.fog_sky_affect = 0.25
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.18
	env.adjustment_contrast = 1.08
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = e.sun_angle
	sun.light_color = Color(e.sun_color)
	sun.light_energy = float(e.sun_energy)
	sun.shadow_enabled = true
	sun.shadow_blur = 1.5
	sun.light_angular_distance = 0.8
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 55.0
	add_child(sun)


func _spawn_player(pos: Vector3) -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.6
	cs.shape = cap
	cs.position.y = 0.8
	player.add_child(cs)
	player.position = pos
	add_child(player)
	player_doll = Figure3D.make("player")
	player.add_child(player_doll)
	player_doll.facing_back = true


func _spawn_npc(def: Dictionary) -> void:
	var body := StaticBody3D.new()
	body.name = "NPC_" + def.id
	body.set_meta("npc", def.id)
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.45
	cyl.height = 1.9
	cs.shape = cyl
	cs.position.y = 0.95
	body.add_child(cs)
	body.position = def.pos
	add_child(body)
	var doll := Figure3D.make(def.look, String(def.get("id", "")))
	body.add_child(doll)
	npcs.append({"def": def, "body": body, "doll": doll})


func _build_camera() -> void:
	cam = Camera3D.new()
	cam.fov = CAM_FOV
	cam.near = 0.3
	cam.far = 220.0
	var attrs := CameraAttributesPractical.new()
	attrs.dof_blur_far_enabled = true
	attrs.dof_blur_far_distance = CAM_OFFSET.length() + 9.0
	attrs.dof_blur_far_transition = 16.0
	attrs.dof_blur_near_enabled = true
	attrs.dof_blur_near_distance = CAM_OFFSET.length() - 8.0
	attrs.dof_blur_near_transition = 5.0
	attrs.dof_blur_amount = 0.06
	if Gfx.level() < 2:
		# depth-of-field blur is one of the dearest effects on a phone
		attrs.dof_blur_far_enabled = false
		attrs.dof_blur_near_enabled = false
	cam.attributes = attrs
	add_child(cam)
	_focus = _cam_focus_target()
	_zoom = zoom_setting()
	_place_camera()
	cam.make_current()


func _cam_focus_target() -> Vector3:
	var p := player.global_position
	var b: Rect2 = area.BOUNDS
	return Vector3(clampf(p.x, -area.CAMERA_X_LIMIT, area.CAMERA_X_LIMIT), 0.0,
		clampf(p.z, b.position.y + 5.0, b.end.y - 4.0))


## The camera's place behind the player at the zoom the player chose, before
## anything in the way is allowed for.
func _cam_offset(z: float = -1.0) -> Vector3:
	return CAM_LOOK + (CAM_OFFSET - CAM_LOOK) / (z if z > 0.0 else zoom_setting())


## Puts the camera behind the player, at the zoom eased so far, and in front of
## any wall, roof or tree it would otherwise end up inside. `delta` < 0 snaps.
func _place_camera(delta: float = -1.0) -> void:
	var look := _focus + CAM_LOOK
	var want := _focus + _cam_offset(_zoom)
	var clear := _clear_way(look, want)
	if delta < 0.0 or clear < _cam_clear:
		_cam_clear = clear   # in front of a wall at once...
	else:
		_cam_clear = lerpf(_cam_clear, clear, minf(1.0, delta * 2.5))   # ...and out again gently
	cam.global_position = look.lerp(want, _cam_clear)
	cam.look_at(look, Vector3.UP)
	var ca := cam.attributes as CameraAttributesPractical
	if ca != null and ca.dof_blur_far_enabled:
		var d := cam.global_position.distance_to(look)
		ca.dof_blur_far_distance = d + 9.0
		ca.dof_blur_near_distance = maxf(0.5, d - 8.0)


# ================================================================ zoom ===

## The zoom the player has chosen (1 is the usual view, higher is closer).
static func zoom_setting() -> float:
	return clampf(float(Game.settings.get("cam_zoom", 1.0)), ZOOM_MIN, ZOOM_MAX)


## Moves the camera's distance by `factor` (under 1 comes closer), within the
## limits. Not while a film has the camera, or the player isn't free to walk.
func zoom_by(factor: float) -> void:
	if attract or cine or busy or factor <= 0.0 or (hud != null and hud.menu_open()):
		return
	var z := clampf(zoom_setting() / factor, ZOOM_MIN, ZOOM_MAX)
	if absf(z - zoom_setting()) < 0.0001:
		return
	Game.settings["cam_zoom"] = z
	_zoom_save = 0.8


## The + / - keys and the right stick: a press zooms a little, holding keeps going.
func _zoom_input(delta: float) -> void:
	if _zoom_save > 0.0:
		_zoom_save -= delta
		if _zoom_save <= 0.0:
			Game.save_settings()
	if cine or busy or hud.menu_open():
		_zoom_hold = 0.0
		return
	var v := Input.get_axis("zoom_in", "zoom_out")
	if absf(v) < 0.2 and _zoom_hold > 0.0:
		v = _zoom_dir
	_zoom_hold = maxf(0.0, _zoom_hold - delta)
	if absf(v) >= 0.2:
		zoom_by(exp(v * ZOOM_RATE * delta))


## How far along the line from `look` out to `want` (0 to 1) the camera can
## sit without being inside a building, a roof or a tree, judged by the boxes
## round their meshes. Only the camera's own spot has to be clear: the view
## past a roof to the player is as it always was.
func _clear_way(look: Vector3, want: Vector3) -> float:
	var seg := want - look
	var length := seg.length()
	if length < 0.01:
		return 1.0
	var boxes := []   # [inverse transform, grown local box]
	for id in RenderingServer.instances_cull_ray(look, want, get_world_3d().scenario):
		var mi := instance_from_id(id) as MeshInstance3D
		if mi == null or not _blocks_camera(mi):
			continue
		var inv := mi.global_transform.affine_inverse()
		var sc := mi.global_transform.basis.get_scale()
		var g := Vector3(CAM_CLEARANCE / maxf(sc.x, 0.001), CAM_CLEARANCE / maxf(sc.y, 0.001), CAM_CLEARANCE / maxf(sc.z, 0.001))
		var box := mi.get_aabb()
		box = AABB(box.position - g, box.size + g * 2.0)
		if box.has_point(inv * look):
			continue   # standing under its eaves or its branches: it can't be helped
		boxes.append([inv, box])
	var k := 1.0
	for i in 4:   # move in front of the box the camera is in, then check again
		var p := look + seg * k
		var moved := false
		for b in boxes:
			var inv: Transform3D = b[0]
			var box: AABB = b[1]
			if not box.has_point(inv * p):
				continue
			var hit = box.intersects_segment(inv * look, inv * p)
			var t := 0.0
			if hit is Vector3:
				t = (inv.affine_inverse() * (hit as Vector3)).distance_to(look) / length
			k = minf(k, maxf(0.0, t - 0.02))
			moved = true
		if not moved:
			break
	return k


## Something the camera mustn't end up inside: a big, solid, shadow-casting
## mesh that isn't a person.
func _blocks_camera(mi: MeshInstance3D) -> bool:
	if not mi.is_visible_in_tree() or mi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
		return false
	var ab := mi.global_transform * mi.get_aabb()
	if ab.size.y < 1.0 or ab.end.y < 1.5 or ab.size.x > 80.0 or ab.size.z > 80.0:
		return false   # the ground, paths, low props, the sky
	var n: Node = mi.get_parent()
	for i in 10:
		if n == null or n == self:
			break
		if n is PaperDoll or n is CharacterBody3D:
			return false   # the player, the villagers and anyone a film brings on
		n = n.get_parent()
	return true


# ============================================================ movement ===

## Moves the player once a frame, in step with the camera. (It used to run at
## the physics rate, 60 a second, while the camera ran every frame: on a phone
## drawing 120 frames a second, or dropping frames, the player hopped while the
## camera glided, which looked like the game straining to catch up.)
func _move(delta: float) -> void:
	var dir := Vector3.ZERO
	if not busy and not hud.menu_open():
		var v := hud.pad.vector
		var k := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if k.length() > v.length():
			v = k
		if v.length() > 0.15:
			_move_target = null
			_talk_target = null
			dir = Vector3(v.x, 0, v.y)
			if dir.length() > 1.0:
				dir = dir.normalized()
		elif _move_target != null:
			var to: Vector3 = _move_target - player.global_position
			to.y = 0
			var stop := 1.6 if _talk_target != null else 0.12
			if to.length() <= stop:
				_move_target = null
				if _talk_target != null:
					var t = _talk_target
					_talk_target = null
					_talk(t)
			else:
				dir = to.normalized()
	var target_vel := dir * SPEED
	player.velocity.x = lerpf(player.velocity.x, target_vel.x, minf(1.0, delta * 14.0))
	player.velocity.z = lerpf(player.velocity.z, target_vel.z, minf(1.0, delta * 14.0))
	player.velocity.y = 0.0
	player.move_and_slide()
	var moving := Vector2(player.velocity.x, player.velocity.z).length() > 0.4
	if not cine:   # a cutscene walks the player itself
		player_doll.walking = moving
		if player_doll is Figure3D:
			# the player covers ground at a jog: match the feet to it
			(player_doll as Figure3D).gait = "run"
			(player_doll as Figure3D).pace = Vector2(player.velocity.x, player.velocity.z).length()
	if dir.length() > 0.1:
		player_doll.face(dir, cam)
	# give up on a tap target we can't reach
	if _move_target != null and not moving:
		_stuck_time += delta
		if _stuck_time > 0.6:
			_move_target = null
			_talk_target = null
	else:
		_stuck_time = 0.0
	_update_near()


func _process(delta: float) -> void:
	if cam == null:
		return
	if attract:
		_attract_t += delta
		var a := -0.35 + sin(_attract_t * 0.06) * 0.5
		var target := Vector3(0, 3.0, -12.0)
		cam.global_position = target + Vector3(sin(a) * 30.0, 9.0 + sin(_attract_t * 0.11) * 1.5, cos(a) * 30.0)
		cam.look_at(target + Vector3(0, 2.5, 0), Vector3.UP)
		return
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta)
		cam.h_offset = randf_range(-1, 1) * _shake * 0.25
		cam.v_offset = randf_range(-1, 1) * _shake * 0.25
	_move(delta)   # (the title screen's drifting camera returned above)
	_zoom_input(delta)
	if cine:
		return   # a film has the camera; the player's zoom waits for it to end
	_focus = _focus.lerp(_cam_focus_target(), minf(1.0, delta * 5.0))
	_zoom = lerpf(_zoom, zoom_setting(), minf(1.0, delta * 8.0))
	_place_camera(delta)


func _on_tap(pos: Vector2) -> void:
	if busy:
		return
	var from := cam.project_ray_origin(pos)
	var dir := cam.project_ray_normal(pos)
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * 200.0)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty() and hit.collider is Node and (hit.collider as Node).has_meta("npc"):
		var n = _npc_by_id((hit.collider as Node).get_meta("npc"))
		if n != null and not n.def.get("muted", false):
			if player.global_position.distance_to(n.body.global_position) <= TALK_RANGE:
				_talk(n)
			else:
				_move_target = n.body.global_position
				_talk_target = n
			return
	# otherwise walk to where the ray meets the ground
	if absf(dir.y) > 0.001:
		var t := -from.y / dir.y
		if t > 0:
			var p := from + dir * t
			var b: Rect2 = area.BOUNDS
			p.x = clampf(p.x, b.position.x + 0.4, b.end.x - 0.4)
			p.z = clampf(p.z, b.position.y + 0.4, b.end.y - 0.4)
			_move_target = p
			_talk_target = null
			_spawn_tap_ring(p)
			_first_step_done(0)


func _spawn_tap_ring(p: Vector3) -> void:
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.28
	tm.outer_radius = 0.36
	ring.mesh = tm
	ring.material_override = LevelKit.mat("ring_glow")
	ring.position = p + Vector3(0, 0.05, 0)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)
	var tw := create_tween()
	tw.tween_property(ring, "scale", Vector3(1.8, 1.0, 1.8), 0.45)
	tw.parallel().tween_property(ring, "transparency", 1.0, 0.45)
	tw.tween_callback(ring.queue_free)


func _update_near() -> void:
	var best = null
	var best_d := TALK_RANGE
	if not busy:
		for n in npcs:
			if n.def.get("muted", false):
				continue   # held back while a lesson step waits (Ashford's first steps)
			var d := player.global_position.distance_to(n.body.global_position)
			if d < best_d:
				best_d = d
				best = n
	if best != _near:
		_near = best
		if _near != null:
			hud.set_talk_target(_near.def.name, _wants_duel(_near.def))
		else:
			hud.set_talk_target("", false)
		_refresh_markers()


func _npc_by_id(id: String):
	for n in npcs:
		if n.def.id == id:
			return n
	return null


func _wants_duel(def: Dictionary) -> bool:
	var f: String = def.get("duel_flag", "")
	if f == "" or Game.flag(f):
		return false
	var need: String = def.get("duel_needs", "")
	return need == "" or bool(Game.flag(need))


## The badges over people's heads (a duel, someone to talk to). None while
## the world is busy (a conversation, a scene, a film): a nested part of a
## talk ending, or the player moved by a scene, used to put them back up in
## the middle of it (Corin's duel badge over him as he talked).
func _refresh_markers() -> void:
	var hide := busy or cine
	for n in npcs:
		var kind := ""
		if hide:
			pass
		elif _wants_duel(n.def):
			kind = "duel"
		elif n == _near:
			kind = "talk"
		n.doll.set_marker(kind)


# ========================================================== keys and pads ===

## E, Space, Enter or a pad's A talks to whoever the round button is showing,
## like tapping it. Only a fresh press counts (holding a key doesn't repeat),
## and the press that closes the last line of a talk never gets here: the
## dialogue box takes it first. Nothing happens while busy, in a cutscene or
## with the pause menu open.
func _unhandled_input(event: InputEvent) -> void:
	if attract or hud == null or busy or cine or hud.menu_open():
		return
	if event.is_action_pressed("interact") and _near != null and hud.talk_showing():
		get_viewport().set_input_as_handled()
		_talk(_near)
	for a in ["zoom_in", "zoom_out"]:
		if event.is_action_pressed(a):
			_zoom_hold = 0.2
			_zoom_dir = -1.0 if a == "zoom_in" else 1.0
			get_viewport().set_input_as_handled()


# =============================================================== talking ===

func _talk(n: Dictionary) -> void:
	if busy:
		return
	busy = true
	_first_step_done(1)
	_move_target = null
	hud.set_controls_visible(false)
	player_doll.walking = false
	n.doll.look_toward(player.global_position, cam)
	player_doll.look_toward(n.body.global_position, cam)
	n.doll.set_marker("")
	if String(n.def.get("id", "")) != "":
		Game.flags["met_" + String(n.def.id)] = true
	await run_steps(n.def.talk, n)
	hud.dialogue.close()
	hud.set_controls_visible(true)
	busy = false
	_near = null
	_update_near()
	_refresh_markers()


func run_steps(steps: Array, npc) -> void:
	for st in steps:
		if not is_inside_tree():
			return
		if st.has("say"):
			var who: String = st.get("who", "narrator")
			var talker = _figure_of(who)
			if talker is Figure3D:
				(talker as Figure3D).talking = true
			var line := _fmt(st.say)
			if st.has("during"):
				_during(String(st.during), DialogueBox.reach_secs(line, String(st.get("at", ""))))
			await hud.dialogue.say(_speaker(who), _portrait(who), line)
			if talker is Figure3D:
				(talker as Figure3D).talking = false
		elif st.has("if"):
			var ok := _check(st["if"])
			await run_steps(st.get("then", []) if ok else st.get("else", []), npc)
		elif st.has("choice"):
			var i := await hud.dialogue.choose(st.choice)
			var branches: Array = st.get("then", [])
			if i < branches.size():
				await run_steps(branches[i], npc)
		elif st.has("set"):
			Game.set_flag(st.set)
		elif st.has("standing"):
			# {"standing": {"tilly": 1, "solmaris": -1}, "why": "..."}
			for who in st.standing:
				Game.shift_standing(String(who), int(st.standing[who]), String(st.get("why", "")))
		elif st.has("item"):
			Game.give_item(String(st.item))
			hud.toast("Got: %s" % Items.ITEMS.get(String(st.item), {}).get("name", st.item))
		elif st.has("objective"):
			Game.set_flag("objective", String(st.objective))
			hud.set_objective(_fmt(String(st.objective)))
		elif st.has("give"):
			hud.dialogue.close()
			Game.add_card(st.give)
			await hud.show_card_reward(st.give)
		elif st.has("save"):
			Game.save_game()
		elif st.has("goto_duel"):
			await run_steps(area.call(st.goto_duel), npc)
		elif st.has("duel"):
			hud.dialogue.close()
			var won := await _duel(st.duel)
			await run_steps(st.get("win", []) if won else st.get("lose", []), npc)
		elif st.has("end_slice"):
			await _end_of_slice()
		elif st.has("scene"):
			hud.dialogue.close()
			await area.scene(st.scene, self)
	_refresh_markers()


## A scene that plays while a line is up, not waited for: {"say": ...,
## "during": "<scene>", "at": "<words>"} starts it as the line types out as
## far as those words (Bram setting off while Corin talks, Tilly's card
## passing over on "You keep it").
func _during(scene_name: String, delay: float) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	if is_inside_tree():
		await area.scene(scene_name, self)


func _check(cond: String) -> bool:
	if cond.begins_with("standing:"):
		return Standing.check(cond)
	if cond.begins_with("!"):
		return not bool(Game.flag(cond.substr(1)))
	return bool(Game.flag(cond))


## The figure of whoever is speaking, if they're standing in the world.
func _figure_of(who: String):
	if who == "player":
		return player_doll
	var n = _npc_by_id(who)
	return n.doll if n != null else null


func _speaker(who: String) -> String:
	match who:
		"narrator":
			return ""
		"player":
			return Game.player_name
	var n = _npc_by_id(who)
	if n != null:
		return n.def.name
	return who.capitalize()


func _portrait(who: String) -> Texture2D:
	match who:
		"narrator":
			return null
		"player":
			return DollArt.portrait("player")
	var n = _npc_by_id(who)
	if n != null:
		# their own face when it's been rendered from their 3D model (Tam,
		# Tilly), else the face that goes with their costume
		var id := String(n.def.get("id", ""))
		if id != "" and DollArt.has_portrait(id):
			return DollArt.portrait(id)
		return DollArt.portrait(n.def.look)
	if DollArt.LOOKS.has(who):
		return DollArt.portrait(who)
	return null


func _fmt(s: String) -> String:
	return s.replace("{name}", Game.player_name)


# ================================================================= duels ===

func _duel(spec: Dictionary) -> bool:
	if spec.get("v1", false) and area.get_script_constant_map().has("PLAYER_DECK"):
		spec = area.duel_spec(spec)
	await hud.fade(1.0, 0.5)
	var won := false
	if duel_handler.is_valid():
		won = await duel_handler.call(spec)
	else:
		won = await _simulate_duel(spec)
	Game.save_game()
	await hud.fade(0.0, 0.5)
	return won


func _simulate_duel(spec: Dictionary) -> bool:
	if spec.has("decks"):
		var g := DuelGame.new()
		g.setup(spec.decks, spec.names, [DuelAI.new(), DuelAI.new()], spec.get("profiles", []))
		g.start_life = int(spec.get("life", 0))
		await g.run()
		return g.winner == 0
	var game := BattleGame.new()
	var opp_profile := Game.npc_profile(spec.name, spec.get("patron", ""), spec.get("attrs", {}))
	game.setup([Game.deck, spec.deck], [Game.player_name, spec.name],
		[AIController.new(), AIController.new()], [Game.profile, opp_profile])
	await game.run()
	return game.winner == 0


func _end_of_slice() -> void:
	hud.dialogue.close()
	await hud.fade(0.85, 1.0)
	await hud.dialogue.say("", null, "[center][b]End of Chapter One: The Sun's Court.[/b][/center]\n[center]The Unsworn is tested and found worthy. Six kingdoms wait, and the Turning has a year to run.[/center]")
	await hud.dialogue.say("", null, "[center]Thank you for playing this early slice of The Covenant War.\nYou can keep exploring Solhaven and duelling.[/center]")
	hud.dialogue.close()
	await hud.fade(0.0, 1.0)


func _on_menu(action: String) -> void:
	match action:
		"save":
			if Game.save_game():
				hud.toast("Game saved")
			hud.close_menu()
		"title":
			hud.close_menu()
			Game.save_game()
			exit_to_title.emit()


# ============================================================== cutscenes ===

## Glides the camera to `pos`, looking at `look`, over `secs` seconds.
func cine_to(pos: Vector3, look: Vector3, secs: float) -> void:
	cine = true
	var token := Cine.take_camera(self)   # (a film's glide still running stops)
	var from_pos := cam.global_position
	var from_look := from_pos + (-cam.global_transform.basis.z) * 10.0
	var tw := create_tween()
	tw.tween_method(func(u: float) -> void:
		if not Cine.has_camera(self, token):
			return
		var e := u * u * (3.0 - 2.0 * u)
		cam.global_position = from_pos.lerp(pos, e)
		cam.look_at(from_look.lerp(look, e), Vector3.UP), 0.0, 1.0, maxf(secs, 0.01))
	await tw.finished


## Hands the camera back to the player.
func end_cine() -> void:
	Cine.take_camera(self)   # (no glide left over from the film fights the player's camera)
	cine = false


## Glides the camera back behind the player, at the zoom they chose, then
## hands it back.
func cine_home(secs: float = 1.0) -> void:
	var f := _cam_focus_target()
	var look := f + CAM_LOOK
	_zoom = zoom_setting()
	var want := f + _cam_offset(_zoom)
	_cam_clear = _clear_way(look, want)
	await cine_to(look.lerp(want, _cam_clear), look, secs)
	_focus = f
	cine = false


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


## A full-screen flash of `col`: in over `t_in`, out over `t_out`.
func flash(col: Color, t_in: float, t_out: float) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 15
	var r := ColorRect.new()
	r.color = Color(col, 0.0)
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(r)
	add_child(layer)
	var tw := create_tween()
	tw.tween_property(r, "color:a", 0.95, t_in)
	tw.tween_property(r, "color:a", 0.0, t_out)
	await tw.finished
	layer.queue_free()
