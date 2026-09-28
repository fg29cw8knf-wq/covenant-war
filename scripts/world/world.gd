class_name World
extends Node3D
## The walkable world: builds an area, puts the player and NPCs in it, and
## runs movement, the camera, talking and duels.
##
## Duels are handed to `duel_handler` (a Callable taking the duel spec and
## returning true if the player won). Main sets it; without it (in tests) the
## duel is decided by a quick AI-vs-AI simulation.

signal exit_to_title

const AREAS := {
	"solhaven": preload("res://scripts/world/areas/solhaven.gd"),
}

const SPEED := 5.4
const TALK_RANGE := 2.4
const CAM_OFFSET := Vector3(0, 8.2, 11.5)
const CAM_FOV := 32.0

var duel_handler: Callable
var area_id := "solhaven"
var area: GDScript
var hud: WorldHUD
var cam: Camera3D
var player: CharacterBody3D
var player_doll: PaperDoll
var npcs: Array = []       # {def, body, doll}
var busy := false          # talking, in a menu or a cutscene
var _move_target = null    # Vector3 or null
var _talk_target = null    # npc dict to talk to on arrival
var _near = null           # npc dict in range
var _focus := Vector3.ZERO
var _stuck_time := 0.0


func setup(p_area: String, spawn: String) -> World:
	area_id = p_area if AREAS.has(p_area) else "solhaven"
	area = AREAS[area_id]
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
	hud = WorldHUD.new()
	add_child(hud)
	hud.tapped.connect(_on_tap)
	hud.talk_pressed.connect(func() -> void:
		if _near != null and not busy:
			_talk(_near))
	hud.menu_action.connect(_on_menu)
	_refresh_markers()
	_arrive.call_deferred()


func _arrive() -> void:
	await hud.fade(0.0, 0.6)
	hud.show_area_title(area.NAME, area.SUBTITLE)
	var key := "arrived_" + area_id
	if not Game.flag(key):
		Game.set_flag(key)
		await get_tree().create_timer(1.2).timeout
		busy = true
		hud.set_controls_visible(false)
		await run_steps(area.arrival(), null)
		hud.dialogue.close()
		hud.set_controls_visible(true)
		busy = false


# ============================================================ building ===

func _build_environment() -> void:
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
	player_doll = PaperDoll.new().setup("player")
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
	var doll := PaperDoll.new().setup(def.look)
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
	cam.attributes = attrs
	add_child(cam)
	_focus = _cam_focus_target()
	_place_camera()
	cam.make_current()


func _cam_focus_target() -> Vector3:
	var p := player.global_position
	var b: Rect2 = area.BOUNDS
	return Vector3(clampf(p.x, -area.CAMERA_X_LIMIT, area.CAMERA_X_LIMIT), 0.0,
		clampf(p.z, b.position.y + 5.0, b.end.y - 4.0))


func _place_camera() -> void:
	cam.global_position = _focus + CAM_OFFSET
	cam.look_at(_focus + Vector3(0, 1.1, 0), Vector3.UP)


# ============================================================ movement ===

func _physics_process(delta: float) -> void:
	var dir := Vector3.ZERO
	if not busy:
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
	player_doll.walking = moving
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
	_focus = _focus.lerp(_cam_focus_target(), minf(1.0, delta * 5.0))
	_place_camera()


func _on_tap(pos: Vector2) -> void:
	if busy:
		return
	var from := cam.project_ray_origin(pos)
	var dir := cam.project_ray_normal(pos)
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * 200.0)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty() and hit.collider is Node and (hit.collider as Node).has_meta("npc"):
		var n = _npc_by_id((hit.collider as Node).get_meta("npc"))
		if n != null:
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


func _refresh_markers() -> void:
	for n in npcs:
		var kind := ""
		if _wants_duel(n.def):
			kind = "duel"
		elif n == _near:
			kind = "talk"
		n.doll.set_marker(kind)


# =============================================================== talking ===

func _talk(n: Dictionary) -> void:
	if busy:
		return
	busy = true
	_move_target = null
	hud.set_controls_visible(false)
	player_doll.walking = false
	n.doll.look_toward(player.global_position, cam)
	player_doll.look_toward(n.body.global_position, cam)
	n.doll.set_marker("")
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
			await hud.dialogue.say(_speaker(who), _portrait(who), _fmt(st.say))
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
	_refresh_markers()


func _check(cond: String) -> bool:
	if cond.begins_with("!"):
		return not bool(Game.flag(cond.substr(1)))
	return bool(Game.flag(cond))


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
		return DollArt.portrait(n.def.look)
	if DollArt.LOOKS.has(who):
		return DollArt.portrait(who)
	return null


func _fmt(s: String) -> String:
	return s.replace("{name}", Game.player_name)


# ================================================================= duels ===

func _duel(spec: Dictionary) -> bool:
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
	var game := BattleGame.new()
	var opp_profile := Game.npc_profile(spec.name, spec.get("patron", ""), spec.get("attrs", {}))
	game.setup([Game.deck, spec.deck], [Game.player_name, spec.name],
		[AIController.new(), AIController.new()], [Game.profile, opp_profile])
	await game.run()
	return game.winner == 0


func _end_of_slice() -> void:
	hud.dialogue.close()
	await hud.fade(0.85, 1.0)
	await hud.dialogue.say("", null, "[center][b]End of the first chapter.[/b][/center]\n[center]You have defeated the Sun's Champion. The Covenant War has begun.[/center]")
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
