class_name DuelField3D
extends SubViewportContainer
## The duel field in 3D: the arena painting laid flat as a playmat, each
## Totem's card lying in its slot with the creature standing on it, real
## lights and shadows, a camera that moves with the action, and the light
## effects that happen on the field. The 2D screen keeps the HUD and reads
## positions back through foot_stage() / body_stage().

const MY_Z := 2.0
const RIVAL_Z := -2.6
const MY_X := [-3.3, 0.0, 3.3]
const RIVAL_X := [-3.1, 0.0, 3.1]
const MAT := 16.2
const CARD := Vector2(1.5, 2.1)
const SIDE_LIFE_Z := [6.2, -7.0]      # where a hit on Life lands, per side (set by set_rows)

var stage: Control                    # the 2D stage, for coordinate conversion
var arena_name := "solhaven"
var vp: SubViewport
var world: Node3D
var cam: Camera3D
var sun: DirectionalLight3D
var slots := {}                       # [side][slot] -> Slot
var me := 0
var _t := 0.0

# camera
var cam_pos := Vector3(0, 9.6, 11.4)
var cam_look := Vector3(0, 0.8, 1.3)
var cam_fov := 33.0
var _home_pos := Vector3(0, 9.6, 11.4)
var _home_look := Vector3(0, 0.8, 1.3)
var _shake := 0.0
var _punch := 0.0
var _cam_tw: Tween
var _view_k := 1.0        # how much taller the view is than the stage (fit_to_stage)
## The player's zoom on the field (Game.settings.duel_view, from a pinch or the
## mouse wheel): the lens times this, under 1 is closer. Kept within limits
## that leave every slot clear of the hand and the side columns.
const VIEW_MIN := 0.88
const VIEW_MAX := 1.2
var _view := 1.0          # eases to the setting


class Slot:
	extends Node3D
	var side := 0
	var index := 0
	var mine := true
	var ring: MeshInstance3D
	var ring_mat: StandardMaterial3D
	var mark: MeshInstance3D
	var mark_mat: StandardMaterial3D
	var floor_glow: MeshInstance3D
	var glow_mat: StandardMaterial3D
	var card: MeshInstance3D
	var card_vp: SubViewport
	var card_face: Control
	var sprite: Sprite3D
	var model: Node3D = null        # a real 3D model, when one exists (assets/models/...)
	var anim: AnimationPlayer = null
	var model_h := 1.0              # the model's natural size, for scaling
	var model_floor := 0.0          # the model's lowest point (its feet)
	var lamp: OmniLight3D
	var shadow: MeshInstance3D
	var card_id := ""
	var creature_h := 2.0
	var fly := false
	var spin := 0.0
	var yaw := 0.0                 # the model's current turn
	var yaw_target := 0.0
	var yaw_until := 0.0           # when a temporary turn (facing a target) ends
	var stance := "strike"         # its Totem's stance (Phase A): a held pose when the model has no clip for it
	var pose := Vector3(1, 1, 0)   # the pose it's at: width, height, lean
	var stance_clip := false       # the model plays a guard / rest clip of its own


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch = true
	process_priority = -10        # move the camera before the screen reads positions
	vp = SubViewport.new()
	vp.own_world_3d = true
	vp.handle_input_locally = false
	vp.transparent_bg = false
	vp.msaa_3d = Viewport.MSAA_2X
	Gfx.apply(vp)   # a phone draws it smaller and upscales it
	vp.positional_shadow_atlas_size = 2048
	add_child(vp)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_view = view_setting()
	_build()


## Fills the whole screen, never black bars: a wide phone, a 4:3 iPad and the
## margins kept for a phone's Dynamic Island and home bar all just see more
## arena. The view is centred on the stage's 16:9 rectangle (so it may run a
## little past one edge of the screen) and widened by _view_k, so that
## rectangle shows exactly the field it always did and the 2D cards and
## Totem plates stay on their slots.
func fit_to_stage(stage_pos: Vector2, stage_scale: float, screen: Vector2) -> void:
	var st := Vector2(1920.0, 1080.0) * stage_scale
	var c := stage_pos + st * 0.5
	var half := Vector2(maxf(c.x, screen.x - c.x), maxf(c.y, screen.y - c.y))
	var pos := (c - half).floor()
	var sz := (c + half).ceil() - pos
	_view_k = sz.y / maxf(st.y, 1.0)
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	set_deferred("position", pos)
	set_deferred("size", sz)
	_place_camera()


# ================================================================== build ===

func _build() -> void:
	world = Node3D.new()
	vp.add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.03, 0.06)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.6, 0.78)
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 1.5
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.0
	env.glow_hdr_scale = 2.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.fog_enabled = true
	env.fog_light_color = Color(0.1, 0.09, 0.18)
	env.fog_density = 0.018
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 1.12
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	sun.light_color = Color(0.85, 0.85, 1.0)
	sun.light_energy = 0.8
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 40.0
	world.add_child(sun)
	var hall := OmniLight3D.new()
	_hall = hall
	_env = env
	hall.position = Vector3(0, 6, 0)
	hall.light_color = Color(1.0, 0.85, 0.6)
	hall.light_energy = 0.9
	hall.omni_range = 16.0
	world.add_child(hall)
	# ground beyond the mat
	var ground := MeshInstance3D.new()
	var gp := PlaneMesh.new()
	gp.size = Vector2(120, 120)
	ground.mesh = gp
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.051, 0.051, 0.086)
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ground.material_override = gm
	ground.position.y = -0.03
	world.add_child(ground)
	_mat = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(MAT, MAT)
	_mat.mesh = pm
	_mat_material = StandardMaterial3D.new()
	_mat_material.roughness = 0.8
	_mat_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_mat.material_override = _mat_material
	world.add_child(_mat)
	_back = MeshInstance3D.new()
	var bq := QuadMesh.new()
	bq.size = Vector2(90, 13.5)
	_back.mesh = bq
	_back_material = StandardMaterial3D.new()
	_back_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_back_material.albedo_color = Color(0.8, 0.8, 0.9)
	_back.material_override = _back_material
	_back.position = Vector3(0, 5.6, -16.0)
	world.add_child(_back)
	for side in 2:
		slots[side] = {}
		for i in 3:
			var s := _make_slot(side, i)
			slots[side][i] = s
			world.add_child(s)
	world.add_child(_motes())
	cam = Camera3D.new()
	cam.fov = cam_fov
	cam.near = 0.1
	cam.far = 120.0
	world.add_child(cam)
	cam.current = true
	_place_camera()


var _mat: MeshInstance3D
var _mat_material: StandardMaterial3D
var _back: MeshInstance3D
var _back_material: StandardMaterial3D
var _hall: OmniLight3D
var _env: Environment

## Each arena's light: the motes, and the tint a Terrain Rite gives the hall
## light and the haze while its ground holds (Phase D).
const ARENA_LIGHT := {"emberforge": Color(1.0, 0.6, 0.3), "tidegrove": Color(0.6, 0.95, 0.9), "veilwild": Color(0.7, 0.55, 1.0),
	"ironstone": Color(1.0, 0.8, 0.5), "solhaven": Color(1.0, 0.92, 0.62), "ashford": Color(0.75, 1.0, 0.6)}
const HALL_COL := Color(1.0, 0.85, 0.6)
const FOG_COL := Color(0.1, 0.09, 0.18)


func setup(p_arena: String) -> void:
	arena_name = p_arena
	var mt := DuelArt.mat(arena_name)
	if mt != null:
		_mat_material.albedo_texture = mt
	else:
		_mat_material.albedo_color = Color(0.2, 0.2, 0.28)
	var bk := DuelArt.backdrop(arena_name)
	_back.visible = bk != null
	if bk != null:
		_back_material.albedo_texture = bk
	var light_col: Color = {"emberforge": Color(1.0, 0.6, 0.3), "tidegrove": Color(0.6, 0.95, 0.9), "veilwild": Color(0.7, 0.55, 1.0),
		"ironstone": Color(1.0, 0.8, 0.5)}.get(arena_name, Color(1.0, 0.9, 0.7))
	_mote_col = light_col


## A Terrain Rite turns the ground (Phase D): the new arena's floor and the
## scenery beyond fade in over the old, a wave of its colour runs out across
## the Circle, and while the Rite holds (`held`) the hall light and the haze
## take its tint; when it fades they go back.
func change_arena(p_arena: String, held: bool, dur: float = 1.3) -> void:
	if p_arena == "" or world == null:
		return
	var col: Color = ARENA_LIGHT.get(p_arena, Color(1.0, 0.9, 0.7))
	floor_wave(Vector3(0, 0.05, 0), col, 9.0, dur * 0.8)
	flash_light(Vector3(0, 3.0, 0), col, 5.0, dur * 0.7, 14.0)
	var tw := create_tween().set_parallel(true)
	var temp := []
	if p_arena != arena_name:
		var mt := DuelArt.mat(p_arena)
		if mt != null:
			var top := MeshInstance3D.new()
			top.mesh = _mat.mesh
			var m2 := StandardMaterial3D.new()
			m2.roughness = 0.8
			m2.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			m2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m2.albedo_texture = mt
			m2.albedo_color = Color(1, 1, 1, 0)
			top.material_override = m2
			top.position.y = 0.006
			world.add_child(top)
			tw.tween_property(m2, "albedo_color:a", 1.0, dur)
			temp.append(top)
		var bk := DuelArt.backdrop(p_arena)
		if bk != null and _back.visible:
			var front := MeshInstance3D.new()
			front.mesh = _back.mesh
			var b2 := StandardMaterial3D.new()
			b2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			b2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			b2.albedo_texture = bk
			b2.albedo_color = Color(0.8, 0.8, 0.9, 0)
			front.material_override = b2
			front.position = _back.position + Vector3(0, 0, 0.05)
			world.add_child(front)
			tw.tween_property(b2, "albedo_color:a", 1.0, dur)
			temp.append(front)
	var hall_to: Color = HALL_COL.lerp(col, 0.5) if held else HALL_COL
	var fog_to: Color = FOG_COL.lerp(col * 0.35, 0.6) if held else FOG_COL
	if _hall != null:
		tw.tween_property(_hall, "light_color", hall_to, dur)
	if _env != null:
		tw.tween_property(_env, "fog_light_color", fog_to, dur)
	await get_tree().create_timer(dur + 0.05).timeout
	if not is_instance_valid(self) or world == null:
		return
	setup(p_arena)   # the new ground goes under the faded-in copy, which then goes
	for n in temp:
		(n as Node).queue_free()


## Which side is the player's: their row is the near one.
func set_rows(p_me: int) -> void:
	me = p_me
	for side in 2:
		for i in 3:
			var s: Slot = slots[side][i]
			s.mine = side == me
			var z: float = MY_Z if s.mine else RIVAL_Z
			var x: float = MY_X[i] if s.mine else RIVAL_X[i]
			s.position = Vector3(x, 0, z)
			s.card.rotation_degrees = Vector3(-90, 0 if s.mine else 180, 0)


func _make_slot(side: int, i: int) -> Slot:
	var s := Slot.new()
	s.side = side
	s.index = i
	# rune circle
	s.ring = MeshInstance3D.new()
	var rq := QuadMesh.new()
	rq.size = Vector2(3.1, 3.1)
	s.ring.mesh = rq
	s.ring.rotation_degrees.x = -90
	s.ring.position.y = 0.02
	s.ring_mat = _additive(load("res://assets/art/fx/rune_ring.png"))
	s.ring_mat.albedo_color = Color(0.5, 0.6, 1.0, 0.5)
	s.ring.material_override = s.ring_mat
	s.add_child(s.ring)
	# the target / selection marker: a second brighter ring
	s.mark = MeshInstance3D.new()
	var mq := QuadMesh.new()
	mq.size = Vector2(3.5, 3.5)
	s.mark.mesh = mq
	s.mark.rotation_degrees.x = -90
	s.mark.position.y = 0.03
	s.mark_mat = _additive(load("res://assets/art/fx/ring.png"))
	s.mark_mat.albedo_color = Color(1, 0.85, 0.4, 0.0)
	s.mark.material_override = s.mark_mat
	s.mark.visible = false
	s.add_child(s.mark)
	# soft coloured glow on the floor
	s.floor_glow = MeshInstance3D.new()
	var fq := QuadMesh.new()
	fq.size = Vector2(3.4, 3.4)
	s.floor_glow.mesh = fq
	s.floor_glow.rotation_degrees.x = -90
	s.floor_glow.position.y = 0.015
	s.glow_mat = _additive(load("res://assets/art/fx/glow.png"))
	s.glow_mat.albedo_color = Color(0.5, 0.6, 1.0, 0.0)
	s.floor_glow.material_override = s.glow_mat
	s.add_child(s.floor_glow)
	# the card lying in the slot
	s.card_vp = SubViewport.new()
	s.card_vp.size = Vector2i(400, 560)
	s.card_vp.transparent_bg = true
	s.card_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	s.card_face = CardFaceDraw.new()
	s.card_face.size = Vector2(400, 560)
	s.card_vp.add_child(s.card_face)
	s.add_child(s.card_vp)
	s.card = MeshInstance3D.new()
	var cq := QuadMesh.new()
	cq.size = CARD
	s.card.mesh = cq
	s.card.rotation_degrees = Vector3(-90, 0, 0)
	s.card.position.y = 0.05
	var cm := StandardMaterial3D.new()
	cm.albedo_texture = s.card_vp.get_texture()
	cm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	cm.roughness = 0.45
	cm.metallic = 0.1
	s.card.material_override = cm
	s.card.visible = false
	s.add_child(s.card)
	# contact shadow under the creature
	s.shadow = MeshInstance3D.new()
	var sq := QuadMesh.new()
	sq.size = Vector2(1.6, 0.8)
	s.shadow.mesh = sq
	s.shadow.rotation_degrees.x = -90
	s.shadow.position.y = 0.06
	var sm := StandardMaterial3D.new()
	sm.albedo_texture = load("res://assets/art/fx/glow.png")
	sm.albedo_color = Color(0, 0, 0, 0.6)
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	s.shadow.material_override = sm
	s.shadow.visible = false
	s.add_child(s.shadow)
	# the creature
	s.sprite = Sprite3D.new()
	s.sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.sprite.shaded = false
	s.sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	s.sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	s.sprite.position.y = 0.06
	s.sprite.visible = false
	s.add_child(s.sprite)
	s.lamp = OmniLight3D.new()
	s.lamp.light_energy = 0.0
	s.lamp.omni_range = 3.2
	s.lamp.omni_attenuation = 1.6
	s.lamp.position = Vector3(0, 1.2, 0.6)
	s.add_child(s.lamp)
	return s


class CardFaceDraw:
	extends Control
	var card_id := ""
	var opts := {}
	var veiled := false   # a veiled Totem's card, face down (Phase C)

	func _draw() -> void:
		if veiled:
			DuelCardFace.draw_back(self, Rect2(Vector2.ZERO, size))
			return
		if card_id == "":
			return
		var o := opts.duplicate()
		o["compact"] = false
		DuelCardFace.draw_card(self, Rect2(Vector2.ZERO, size), card_id, o)


static func _additive(tex: Texture2D) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


var _mote_col := Color(1.0, 0.9, 0.7)
var _motes_node: CPUParticles3D


func _motes() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 80
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(9, 0.3, 8)
	p.direction = Vector3.UP
	p.spread = 25
	p.initial_velocity_min = 0.12
	p.initial_velocity_max = 0.4
	p.gravity = Vector3.ZERO
	var q := QuadMesh.new()
	q.size = Vector2(0.08, 0.08)
	var qm := _additive(DuelFX.dot_tex())
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	qm.albedo_color = Color(1.0, 0.9, 0.7, 0.9)
	q.material = qm
	p.mesh = q
	_motes_node = p
	return p


# =============================================================== each frame ===

func _process(delta: float) -> void:
	_t += delta
	if _motes_node != null and _motes_node.mesh != null:
		(_motes_node.mesh as QuadMesh).material.albedo_color = Color(_mote_col, 0.9)
	# the camera: its target, a slow idle drift, shake and punch
	_shake = move_toward(_shake, 0.0, delta * 1.2)
	_punch = move_toward(_punch, 0.0, delta * 0.12)
	_view = lerpf(_view, view_setting(), minf(1.0, delta * 8.0))
	_place_camera()


func _place_camera() -> void:
	if cam == null:
		return
	var drift := Vector3(sin(_t * 0.23) * 0.08, sin(_t * 0.31) * 0.05, cos(_t * 0.19) * 0.06)
	var jolt := Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _shake
	cam.position = cam_pos + drift + jolt
	cam.look_at(cam_look + jolt * 0.3, Vector3.UP)
	# This container is centred on the stage's rectangle and _view_k times its
	# height (see fit_to_stage): the lens is widened to match, so the stage
	# sees the same field on any screen shape and the rest is extra arena.
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	var half := deg_to_rad(cam_fov * (1.0 - _punch)) * 0.5
	cam.fov = rad_to_deg(2.0 * atan(tan(half) * _view_k * _view))


## The zoom the player has chosen for the field (1 is the usual view).
static func view_setting() -> float:
	return clampf(float(Game.settings.get("duel_view", 1.0)), VIEW_MIN, VIEW_MAX)


## Zooms the field by `factor` (under 1 comes closer), within the limits.
func zoom_by(factor: float) -> void:
	Game.settings["duel_view"] = clampf(view_setting() * factor, VIEW_MIN, VIEW_MAX)


# ============================================================ coordinates ===

func foot_world(side: int, slot: int) -> Vector3:
	var s: Slot = slots[side][slot]
	return s.global_position + s.sprite.position * Vector3(1, 0, 1)


func body_world(side: int, slot: int) -> Vector3:
	var s: Slot = slots[side][slot]
	var h: float = s.creature_h if s.card_id != "" else 1.2
	return foot_world(side, slot) + Vector3(0, h * 0.5, 0)


## Where a hit on a duellist's Life lands: beyond their row of slots.
func life_world(side: int) -> Vector3:
	return Vector3(0, 0.9, 5.4 if side == me else -6.2)


func _to_stage(world_pos: Vector3) -> Vector2:
	var px := cam.unproject_position(world_pos) + position
	if stage == null:
		return px
	return (px - stage.position) / stage.scale.x


func foot_stage(side: int, slot: int) -> Vector2:
	return _to_stage(foot_world(side, slot))


func body_stage(side: int, slot: int) -> Vector2:
	return _to_stage(body_world(side, slot))


func world_to_stage(p: Vector3) -> Vector2:
	return _to_stage(p)


## Stage pixels per world unit at a slot (for converting 2D nudges).
func px_per_unit(side: int, slot: int) -> float:
	var f := foot_world(side, slot)
	return maxf(1.0, _to_stage(f + Vector3(1, 0, 0)).x - _to_stage(f).x)


# ================================================================= sync ===

## Mirrors a 2D TotemView's state (totem, pop, fade, flash, offset, highlight)
## onto its slot in the field, once a frame.
func sync(v) -> void:
	var s: Slot = slots[v.side][v.slot]
	var t = v.totem
	var id: String = "" if t == null else t.id()
	if t != null and t.face_down and not s.mine:
		# a veiled Totem of the rival's (Phase C): its card lies face down, nothing stands on it
		if s.card_id != "__veiled__":
			s.card_id = "__veiled__"
			if s.model != null:
				s.model.queue_free()
				s.model = null
				s.anim = null
			s.card.visible = true
			s.card_face.card_id = ""
			s.card_face.veiled = true
			s.card_face.queue_redraw()
			s.card_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
			s.sprite.visible = false
			s.shadow.visible = false
			s.lamp.light_energy = 0.0
		_ring_state(s, v.highlight, Color(0.7, 0.6, 1.0), 0.35 * v.fade)
		return
	if id != s.card_id:
		s.card_id = id
		if s.model != null:
			s.model.queue_free()
			s.model = null
			s.anim = null
		if id == "":
			s.card.visible = false
			s.sprite.visible = false
			s.shadow.visible = false
			s.lamp.light_energy = 0.0
		else:
			s.card_face.veiled = false
			s.card_face.card_id = id
			s.card_face.queue_redraw()
			s.card_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
			s.card.visible = true
			var tex := DuelArt.creature_or_stand_in(id)
			s.sprite.texture = tex
			s.sprite.modulate = DuelArt.stand_in_tint(id)
			s.sprite.visible = tex != null
			s.shadow.visible = tex != null
			var tier := int(DuelCards.CARDS[id].tier)
			var stg := int(DuelCards.CARDS[id].get("stage", 0))
			s.creature_h = 2.6 if (tier >= 3 or stg >= 2) else (2.25 if (tier == 2 or stg == 1) else 1.9)
			if tex != null:
				s.sprite.pixel_size = s.creature_h / float(tex.get_height())
				s.sprite.offset = Vector2(0, tex.get_height() * 0.5)
			s.fly = DuelArt.FLYERS.has(id)
			s.lamp.light_color = DuelFX.light(t.element())
			_load_model(s, id)
	if t == null:
		_ring_state(s, v.highlight, Color(0.55, 0.65, 1.0), 0.35 * v.fade)
		return
	var el: String = t.element()
	var col := DuelFX.light(el)
	# the creature: breathing, flipped for the rival, nudged by the 2D offset
	var breathe := sin(_t * 2.1 + v.slot * 1.7)
	var sx := 1.0 - 0.006 * breathe
	var sy := 1.0 + 0.014 * breathe
	if t.asleep:
		sy = 1.0 + 0.02 * sin(_t * 1.1)
	s.sprite.scale = Vector3(sx * v.pop, sy * v.pop, 1.0)
	s.sprite.flip_h = not s.mine
	var pxu := px_per_unit(v.side, v.slot)
	var off := Vector3(v.offset.x / pxu, 0, v.offset.y / pxu)
	var hover := 0.0
	if s.fly:
		hover = 0.35 + sin(_t * 1.8 + v.slot) * 0.08
	s.sprite.position = Vector3(off.x, 0.06 + hover, off.z)
	s.shadow.position = Vector3(off.x, 0.06, off.z)
	s.shadow.scale = Vector3(s.creature_h * 0.55, s.creature_h * 0.55, 1.0) * v.pop
	var m := Color(1, 1, 1, v.fade)
	if v.highlight == "dim":
		m = Color(0.55, 0.55, 0.6, v.fade)
	if v.flash > 0.0:
		var fc: Color = v.flash_color
		m = m.lerp(Color(fc.r * 2.5, fc.g * 2.5, fc.b * 2.5, v.fade), clampf(v.flash * 0.75, 0.0, 1.0))
	s.sprite.modulate = m
	if s.model != null:
		var k: float = s.creature_h * 1.05 / maxf(0.01, s.model_h) * v.pop
		# the stance pose: braced lower and leaning for Guard, settled down for Rest
		var want := Vector3(1, 1, 0)
		if not s.stance_clip:
			match s.stance:
				"guard":
					want = Vector3(1.06, 0.88, 0.14 * (1.0 if s.mine else -1.0))
				"rest":
					want = Vector3(1.04, 0.74, 0.0)
		s.pose = s.pose.lerp(want, clampf(get_process_delta_time() * 6.0, 0.0, 1.0))
		s.model.scale = Vector3(k * s.pose.x, k * s.pose.y, k * s.pose.x)
		s.model.rotation.z = s.pose.z
		# models face +Z: at rest they stand three-quarters to the camera so their
		# faces show; during a strike they turn to face their target (face_at)
		if s.yaw_until > 0.0 and _t > s.yaw_until:
			s.yaw_until = 0.0
			s.yaw_target = home_yaw(s)
		s.yaw = lerp_angle(s.yaw, s.yaw_target, 1.0 - pow(0.001, get_process_delta_time()))
		s.model.rotation.y = s.yaw
		s.model.position = Vector3(off.x, 0.06 + hover - s.model_floor * k, off.z)
		s.model.visible = v.fade > 0.02
		_tint_model(s, m)
		_drive_anim(s, v)
	s.lamp.light_energy = (0.55 + 0.1 * sin(_t * 3.0 + v.slot)) * v.fade + v.flash * 3.0
	s.lamp.light_color = col if v.flash <= 0.0 else col.lerp(v.flash_color, v.flash)
	s.glow_mat.albedo_color = Color(col, 0.16 * v.fade)
	_ring_state(s, v.highlight, col, 0.85 * v.fade)


## Models face +Z (the camera) as exported. The rival's face the player, the
## player's are turned to face across the board at the rival, each with a
## little angle so they aren't dead square to the camera.
static func home_yaw(s: Slot) -> float:
	return PI * 0.76 if s.mine else -PI * 0.27


## Turns a slot's model to face a point on the field for `hold` seconds
## (then it settles back to its resting pose).
func face_at(side: int, slot: int, target: Vector3, hold: float = 1.5) -> void:
	var s: Slot = slots[side][slot]
	var d := target - s.position
	if d.length_squared() < 0.01:
		return
	s.yaw_target = atan2(d.x, d.z)
	s.yaw_until = _t + hold


## The model file for a card, if there is one (assets/models/creatures/ or summons/).
static func model_path(id: String) -> String:
	for sub in ["creatures", "summons"]:
		var p := "res://assets/models/%s/%s.glb" % [sub, id]
		if ResourceLoader.exists(p):
			return p
	# a card with no model yet stands in as its stand-in (Phase C: the
	# second-stage Ascensions, shown bigger as the line's first stage)
	if DuelCards.CARDS.has(id) and DuelCards.CARDS[id].has("stand_in"):
		return model_path(String(DuelCards.CARDS[id].stand_in))
	return ""


var _warming := {}   # model path -> true while its background load is on
var _warmed := {}    # model path -> true once it has been drawn here


## Loads the models a duel may call (both decks' Totems and Summons) ahead
## of their summons, in the background, and draws each one once under the
## floor of the Circle so its shaders are compiled before it's wanted. Until
## 23 October a creature's model was read from disk, built and its shaders
## compiled at the moment it was called, and the duel hitched as it came
## (Gary: "the battle's a bit glitchy when you load a Totem"). A few models
## are built a frame, so the opening banners don't stutter either.
func warm_models(ids: Array) -> void:
	var paths: Array = []
	for id in ids:
		var p := model_path(String(id))
		if p != "" and not _warmed.has(p) and not _warming.has(p) and not paths.has(p):
			paths.append(p)
	if paths.is_empty():
		return
	var pit := Node3D.new()
	pit.name = "Warm"
	pit.position = Vector3(0, -3.0, 0)   # under the mat, in the camera's view, unseen
	world.add_child(pit)
	var left: Array = paths.duplicate()
	var to_ask: Array = paths.duplicate()
	while not left.is_empty() and is_inside_tree():
		await get_tree().process_frame
		if not to_ask.is_empty():
			# one request a frame: on the phone link (no threads) a request
			# loads there and then, so they're spread rather than one stall
			var p0: String = to_ask.pop_front()
			_warming[p0] = true
			ResourceLoader.load_threaded_request(p0)
		var batch := 0
		for p in left.duplicate():
			if _warmed.has(p):
				left.erase(p)   # (a summon took it first: already drawn in its slot)
				continue
			if not _warming.has(p):
				continue   # (not asked for yet)
			if ResourceLoader.load_threaded_get_status(p) != ResourceLoader.THREAD_LOAD_LOADED:
				if ResourceLoader.load_threaded_get_status(p) == ResourceLoader.THREAD_LOAD_FAILED:
					left.erase(p)
					_warming.erase(p)
				continue
			var scene := ResourceLoader.load_threaded_get(p) as PackedScene
			left.erase(p)
			_warming.erase(p)
			_warmed[p] = true
			if scene == null:
				continue
			var inst := scene.instantiate()
			if inst is Node3D:
				_dress_model(inst)
				# small, so a big one (Pyraxis) doesn't stand up through the
				# mat while it's warmed: the shaders and skinning are the same
				(inst as Node3D).scale = Vector3.ONE * 0.05
				pit.add_child(inst)
				var anim := _find_anim(inst)
				if anim != null and anim.has_animation(_clip_in(anim, "idle")):
					anim.play(_clip_in(anim, "idle"))   # (the skinning runs once too)
			else:
				inst.queue_free()
			batch += 1
			if batch >= 2:
				break   # (the rest next frame)
	# two drawn frames for the last of them, then they go
	for i in 2:
		await get_tree().process_frame
	if is_instance_valid(pit):
		pit.queue_free()


## A loaded model, from its background load when one was asked for, else
## from disk now.
func _model_scene(path: String) -> PackedScene:
	if _warming.has(path):
		var sc := ResourceLoader.load_threaded_get(path) as PackedScene   # (waits for it)
		_warming.erase(path)
		_warmed[path] = true
		return sc
	return load(path) as PackedScene


## Mesh shadows, and push emissive parts (fire, eyes) so they glow through
## the bloom: the same dressing for a Totem in its slot and for a model
## drawn once to warm its shaders, so the shaders are the same ones.
static func _dress_model(inst: Node3D) -> void:
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		var mesh := mi as MeshInstance3D
		if mesh.mesh == null:
			continue
		for i in mesh.mesh.get_surface_count():
			var mat := mesh.get_active_material(i)
			if mat is BaseMaterial3D:
				var m2: BaseMaterial3D = (mat as BaseMaterial3D).duplicate()
				_dress_material(m2)
				mesh.mesh.surface_set_material(i, m2)   # becomes the model's own material
				mesh.set_meta("_base_%d" % i, m2)


## Loads assets/models/creatures/<id>.glb (or summons/) when it exists and
## hides the cut-out behind it.
func _load_model(s: Slot, id: String) -> void:
	var path := model_path(id)
	if path == "":
		return
	var scene: PackedScene = _model_scene(path)
	if scene == null:
		return
	var inst := scene.instantiate()
	if not inst is Node3D:
		inst.queue_free()
		return
	s.model = inst
	s.add_child(inst)
	s.yaw = home_yaw(s)
	s.yaw_target = s.yaw
	s.yaw_until = 0.0
	# measure its height so it can be scaled to the slot
	var aabb := _merged_aabb(inst)
	# Models are scaled so their body (the bigger of height and length) fills
	# the slot; a raised tail shouldn't shrink the creature, but a wide
	# wingspan (a moth) counts, or it would dwarf its neighbours.
	s.model_h = maxf(0.01, maxf(aabb.size.y, maxf(aabb.size.z, aabb.size.x) * 0.8))
	s.model_floor = aabb.position.y
	s.anim = _find_anim(inst)
	if s.anim != null:
		s.anim.playback_default_blend_time = 0.15
		for nm in ["idle", "run", "victory"]:
			var real := _clip_name(s, nm)
			if real != "":
				s.anim.get_animation(real).loop_mode = Animation.LOOP_LINEAR
		# when a one-shot clip ends, settle back into idle
		s.anim.animation_finished.connect(func(_done: StringName) -> void:
			var idle := _clip_name(s, "idle")
			if idle != "" and s.anim.current_animation != idle:
				s.anim.play(idle, 0.25))
		play_clip(s.side, s.index, "idle")
	else:
		WingFlap.attach(inst)   # a model without clips still beats its wings (the Lantern Moth)
	_dress_model(inst)
	# a new Totem with no model of its own yet (Phase E) wears its stand-in's
	# shape in its own colour, plain, so it reads as a placeholder
	var d: Dictionary = DuelCards.CARDS.get(id, {})
	if d.has("stand_in_tint") and not path.ends_with("/%s.glb" % id):
		inst.set_meta("stand_in_tint", Color(String(d.stand_in_tint)))
	s.sprite.visible = false
	s.shadow.visible = true


## The model packs name their magic surfaces: fire, flame, mist, veil, water,
## fin and glow. Fire and mist are light, not paint, so they're drawn
## additively and unlit (the Blazehound's flame ribbons, say, which are
## alpha-blended, double-sided and emissive in the file); everything else
## keeps the artist's materials with a gentle emission.
static func _dress_material(m: BaseMaterial3D) -> void:
	var nm := m.resource_name.to_lower()
	var blended := m.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA
	if (nm.contains("fire") or nm.contains("flame") or nm.contains("ember")) and blended:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.emission_energy_multiplier = 0.9
		m.albedo_color = Color(0.9, 0.9, 0.9)
	elif (nm.contains("mist") or nm.contains("veil")) and blended:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.emission_energy_multiplier = 0.6
		m.albedo_color = Color(0.7, 0.7, 0.7)
	elif m.emission_enabled:
		m.emission_energy_multiplier = maxf(m.emission_energy_multiplier, 1.0) * 0.8


static func _merged_aabb(n: Node3D) -> AABB:
	var out := AABB()
	var first := true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = (mi as MeshInstance3D).get_aabb()
		b = (mi as Node3D).transform * b
		var p := mi.get_parent()
		while p != null and p != n and p is Node3D:
			b = (p as Node3D).transform * b
			p = p.get_parent()
		if first:
			out = b
			first = false
		else:
			out = out.merge(b)
	return out


static func _find_anim(n: Node) -> AnimationPlayer:
	var found := n.find_children("*", "AnimationPlayer", true, false)
	return found[0] if not found.is_empty() else null


func _tint_model(s: Slot, m: Color) -> void:
	# Only flashes and dimming change the model's look: a white flash lifts
	# the emission, dimming darkens the albedo. Otherwise the model's own
	# materials are left alone.
	var flash := maxf(0.0, maxf(m.r, maxf(m.g, m.b)) - 1.0)
	var dim := minf(1.0, minf(m.r, minf(m.g, m.b)))
	var tinted: bool = s.model.has_meta("stand_in_tint")
	var tint: Color = s.model.get_meta("stand_in_tint", Color.WHITE)
	for mi in s.model.find_children("*", "MeshInstance3D", true, false):
		var mesh := mi as MeshInstance3D
		for i in mesh.mesh.get_surface_count() if mesh.mesh != null else 0:
			var src := mesh.get_active_material(i)
			if not src is BaseMaterial3D:
				continue
			var key := "_base_%d" % i
			if not mesh.has_meta(key):
				mesh.set_meta(key, src)
			var base: BaseMaterial3D = mesh.get_meta(key)
			if flash <= 0.001 and dim >= 0.999 and not tinted:
				if mesh.get_surface_override_material(i) != null:
					mesh.set_surface_override_material(i, null)
				continue
			var ov: BaseMaterial3D = mesh.get_surface_override_material(i)
			# (a tinted stand-in's solid surfaces go plain in its colour; its light
			# surfaces, fire and mist, keep their texture and take the colour)
			var solid := tinted and base.blend_mode == BaseMaterial3D.BLEND_MODE_MIX and base.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED
			if ov == null or ov == base:
				ov = base.duplicate()
				if solid:
					ov.albedo_texture = null
				mesh.set_surface_override_material(i, ov)
			var col := base.albedo_color
			if solid:
				col = Color(tint, base.albedo_color.a)
			elif tinted:
				col = base.albedo_color * tint
			ov.albedo_color = col * Color(dim, dim, dim, 1.0)
			ov.emission_enabled = true
			ov.emission = Color(m.r, m.g, m.b).lerp(base.emission if base.emission_enabled else Color.BLACK, 0.0) * 0.5 if flash > 0.001 else (base.emission if base.emission_enabled else Color.BLACK)
			ov.emission_energy_multiplier = (base.emission_energy_multiplier if base.emission_enabled else 0.0) + flash * 2.0


## Clip names the game asks for, and what a model may call them instead.
const CLIP_ALIASES := {
	"idle": ["idle", "breathe", "breathing"],
	"attack": ["attack", "bite", "pounce", "strike", "lunge"],
	"hit": ["hit", "hurt", "damage", "recoil", "stagger"],
	"ko": ["ko", "defeat", "death", "die", "collapse", "faint"],
	"summon": ["summon", "spawn", "appear", "rise", "enter"],
	"victory": ["victory", "win", "cheer", "celebrate"],
	"run": ["run", "charge", "walk", "dash"],
	"guard": ["guard", "block", "defend", "brace"],
	"rest": ["rest", "sleep", "sit", "lie", "crouch"],
}


static func _clip_name(s: Slot, want: String) -> String:
	return _clip_in(s.anim, want)


static func _clip_in(anim: AnimationPlayer, want: String) -> String:
	if anim == null:
		return ""
	for nm in CLIP_ALIASES.get(want, [want]):
		if anim.has_animation(nm):
			return nm
		for existing in anim.get_animation_list():
			if String(existing).to_lower() == nm:
				return String(existing)
	return ""


## Whether a Summon has a 3D model to descend with.
static func has_summon_model(id: String) -> bool:
	return ResourceLoader.exists("res://assets/models/summons/%s.glb" % id)


## The Demigod comes down onto the middle of the field, lands with a shock,
## roars its attack, then lifts away. Awaitable; `on_land` is called at the
## moment it touches down so the screen can fire its own effects.
func summon_descend(id: String, col: Color, speed: float = 1.0, on_land: Callable = Callable()) -> void:
	var scene: PackedScene = _model_scene("res://assets/models/summons/%s.glb" % id)
	if scene == null:
		return
	var god := scene.instantiate() as Node3D
	if god == null:
		return
	var holder := Node3D.new()
	var at := Vector3(0, 0, -0.8)
	holder.position = at
	_fx_parent().add_child(holder)
	holder.add_child(god)
	var aabb := _merged_aabb(god)
	var h := maxf(0.01, aabb.size.y)
	var want_h := 4.8
	var k := want_h / h
	if aabb.size.x * k > 9.0:
		k = 9.0 / aabb.size.x
	god.scale = Vector3(k, k, k)
	god.rotation.y = 0.12
	god.position = Vector3(0, -aabb.position.y * k, 0)
	var anim := _find_anim(god)
	for mi in god.find_children("*", "MeshInstance3D", true, false):
		var mesh := mi as MeshInstance3D
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if mesh.mesh == null:
			continue
		for i in mesh.mesh.get_surface_count():
			var mat := mesh.get_active_material(i)
			if mat is BaseMaterial3D:
				var m2: BaseMaterial3D = (mat as BaseMaterial3D).duplicate()
				_dress_material(m2)
				mesh.mesh.surface_set_material(i, m2)
	# a light of its element at its heart
	var lamp := OmniLight3D.new()
	lamp.light_color = col
	lamp.light_energy = 0.0
	lamp.omni_range = 11.0
	lamp.position = Vector3(0, want_h * 0.45, 0.5)
	holder.add_child(lamp)
	# down the beam
	var drop := 1.1 / speed
	holder.position.y = 9.0
	pillar(at, col, 14.0, 3.2, drop + 0.4)
	rise(at, col, 60, drop + 0.6, 4.0)
	if anim != null:
		var sp := _clip_in(anim, "summon")
		if sp != "":
			anim.play(sp)
			anim.speed_scale = maxf(0.6, anim.get_animation(sp).length / drop)
	# the camera lifts its gaze to take the Demigod in
	_cam_to(_home_pos + Vector3(0, 0.4, 0.6), Vector3(at.x, want_h * 0.42, at.z), drop)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(holder, "position:y", 0.0, drop).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(lamp, "light_energy", 2.6, drop)
	await tw.finished
	if on_land.is_valid():
		on_land.call()
	cam_shake(16.0)
	cam_punch(0.06)
	# the roar
	var hold := 1.4 / speed
	if anim != null:
		var atk := _clip_in(anim, "attack")
		if atk != "":
			anim.speed_scale = 1.0 * speed
			anim.play(atk, 0.1)
			hold = anim.get_animation(atk).length / speed + 0.3 / speed
	await get_tree().create_timer(hold).timeout
	# and away, back up the beam
	var lift := 0.9 / speed
	pillar(at, col, 14.0, 2.4, lift + 0.3)
	flash_light(at + Vector3(0, 3, 0), col, 10.0, lift, 14.0)
	cam_home(lift)
	var tw2 := create_tween().set_parallel(true)
	tw2.tween_property(holder, "position:y", 11.0, lift).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw2.tween_property(god, "scale", Vector3(k * 0.4, k * 0.4, k * 0.4), lift).set_ease(Tween.EASE_IN)
	tw2.tween_property(lamp, "light_energy", 0.0, lift)
	await tw2.finished
	holder.queue_free()


## Plays a clip on a slot's model (no-op without a model). Returns the clip's
## length in seconds, or 0.
func play_clip(side: int, slot: int, want: String, speed_scale: float = 1.0) -> float:
	var s: Slot = slots[side][slot]
	if s.anim == null:
		return 0.0
	var nm := _clip_name(s, want)
	if nm == "":
		return 0.0
	s.anim.speed_scale = speed_scale
	s.anim.play(nm, 0.12 if want != "idle" else 0.25)
	return s.anim.get_animation(nm).length / maxf(0.01, speed_scale)


func _drive_anim(_s: Slot, _v) -> void:
	pass   # clips are driven explicitly by the screen's effects (play_clip)


## A Totem's stance on its model (Phase A): a guard or rest clip when the
## model has one; otherwise a held pose (sync: braced lower and leaning for
## Guard, settled down for Rest, back up for Strike).
func set_stance(side: int, slot: int, stance: String) -> void:
	var s: Slot = slots[side][slot]
	s.stance = stance
	s.stance_clip = false
	if s.model == null:
		return
	if stance == "strike":
		play_clip(side, slot, "idle")
	elif play_clip(side, slot, stance) > 0.0:
		s.stance_clip = true


func _ring_state(s: Slot, h: String, base: Color, a: float) -> void:
	var col := base
	var spin_speed := 0.25
	match h:
		"target":
			col = Color(1.0, 0.85, 0.4)
			a = 1.0
			spin_speed = 0.9
		"selected":
			col = Color(0.65, 0.9, 1.0)
			a = 1.0
			spin_speed = 0.6
		"ready":
			col = base.lerp(Color(0.6, 0.85, 1.0), 0.4)
			a = 0.75 + 0.25 * sin(_t * 2.6)
	s.ring_mat.albedo_color = Color(col, a * 0.8)
	s.spin += spin_speed * (1.0 if s.side == 0 else -1.0) * get_process_delta_time()
	s.ring.rotation_degrees = Vector3(-90, 0, rad_to_deg(s.spin))
	var show := h == "target" or h == "selected"
	s.mark.visible = show
	if show:
		var pulse := 0.5 + 0.5 * sin(_t * 6.0)
		s.mark_mat.albedo_color = Color(col, 0.4 + 0.35 * pulse)
		s.mark.scale = Vector3.ONE * (1.0 + 0.08 * pulse)
		s.mark.rotation_degrees = Vector3(-90, 0, -rad_to_deg(s.spin) * 1.5)


# =============================================================== camera ===

func set_home(pos: Vector3, look: Vector3) -> void:
	_home_pos = pos
	_home_look = look
	cam_pos = pos
	cam_look = look


func cam_home(dur: float = 0.6) -> void:
	_cam_to(_home_pos, _home_look, dur)


## Leans towards a point on the field: a touch closer and lower, so both
## rows stay on screen under the HUD.
func cam_focus(target: Vector3, amount: float = 0.35, dur: float = 0.35) -> void:
	var lean := Vector3(target.x * 0.25, -1.2, (target.z - _home_look.z) * 0.25 - 0.9) * amount
	var to_pos := _home_pos + lean
	var to_look := _home_look + Vector3(target.x * 0.3, 0.0, (target.z - _home_look.z) * 0.3) * amount
	_cam_to(to_pos, to_look, dur)


func _cam_to(pos: Vector3, look: Vector3, dur: float) -> void:
	if _cam_tw != null and _cam_tw.is_valid():
		_cam_tw.kill()
	_cam_tw = create_tween().set_parallel(true)
	_cam_tw.tween_property(self, "cam_pos", pos, dur).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	_cam_tw.tween_property(self, "cam_look", look, dur).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)


func cam_shake(amount: float) -> void:
	_shake = maxf(_shake, amount * 0.012)


func cam_punch(amount: float) -> void:
	_punch = maxf(_punch, amount)


# ================================================================ effects ===

func _fx_parent() -> Node3D:
	return world


## A pillar of light rising from the floor.
func pillar(at: Vector3, col: Color, height: float = 5.0, width: float = 1.6, dur: float = 0.8) -> void:
	for k in 2:
		var m := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(width, height)
		q.center_offset = Vector3(0, height * 0.5, 0)
		m.mesh = q
		var mat := _additive(load("res://assets/art/fx/pillar.png"))
		mat.albedo_color = Color(col.r * 1.6, col.g * 1.6, col.b * 1.6, 0.9)
		m.material_override = mat
		m.position = at
		m.rotation_degrees.y = 90.0 * k
		m.scale = Vector3(0.3, 0.05, 1)
		_fx_parent().add_child(m)
		var tw := m.create_tween()
		tw.tween_property(m, "scale", Vector3(1, 1, 1), dur * 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(mat, "albedo_color:a", 0.0, dur * 0.75)
		tw.tween_callback(m.queue_free)
	flash_light(at + Vector3(0, 1, 0), col, 6.0, dur)


## A ring of light spreading across the floor.
func floor_wave(at: Vector3, col: Color, radius: float = 3.5, dur: float = 0.5) -> void:
	var m := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(2, 2)
	m.mesh = q
	m.rotation_degrees.x = -90
	var mat := _additive(load("res://assets/art/fx/ring.png"))
	mat.albedo_color = Color(col.r * 1.8, col.g * 1.8, col.b * 1.8, 1.0)
	m.material_override = mat
	m.position = at + Vector3(0, 0.04, 0)
	m.scale = Vector3(0.2, 0.2, 0.2)
	_fx_parent().add_child(m)
	var tw := m.create_tween().set_parallel(true)
	tw.tween_property(m, "scale", Vector3(radius, radius, radius), dur).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(mat, "albedo_color:a", 0.0, dur).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(m.queue_free)


## A quick flash of real light.
func flash_light(at: Vector3, col: Color, energy: float = 6.0, dur: float = 0.4, range_m: float = 7.0) -> void:
	var l := OmniLight3D.new()
	l.position = at
	l.light_color = col
	l.light_energy = energy
	l.omni_range = range_m
	l.shadow_enabled = false
	_fx_parent().add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "light_energy", 0.0, dur).set_ease(Tween.EASE_OUT)
	tw.tween_callback(l.queue_free)


## A glowing billboard that blooms and fades (impact flash).
func flash_sprite(at: Vector3, col: Color, size: float = 2.5, dur: float = 0.35) -> void:
	var sp := Sprite3D.new()
	sp.texture = DuelFX.glow_tex()
	sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sp.shaded = false
	sp.transparent = true
	sp.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	sp.modulate = Color(col.r * 2.0, col.g * 2.0, col.b * 2.0, 1.0)
	sp.pixel_size = size / 128.0
	sp.position = at
	sp.scale = Vector3.ONE * 0.4
	sp.no_depth_test = true
	_fx_parent().add_child(sp)
	var tw := sp.create_tween().set_parallel(true)
	tw.tween_property(sp, "scale", Vector3.ONE, dur * 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(sp, "modulate:a", 0.0, dur).set_delay(dur * 0.2)
	tw.chain().tween_callback(sp.queue_free)


## Sparks flying out of a point.
func burst(at: Vector3, col: Color, amount: int = 40, speed: float = 7.0, life: float = 0.7, size: float = 0.12, up_bias: float = 1.0) -> void:
	var p := CPUParticles3D.new()
	p.position = at
	p.one_shot = true
	p.explosiveness = 0.92
	p.amount = amount
	p.lifetime = life
	p.direction = Vector3.UP
	p.spread = 180.0 if up_bias <= 0.0 else 70.0
	p.initial_velocity_min = speed * 0.35
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -9.0, 0)
	p.damping_min = 2.0
	p.damping_max = 5.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	var sc := Curve.new()
	sc.add_point(Vector2(0, 1))
	sc.add_point(Vector2(1, 0))
	p.scale_amount_curve = sc
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	g.colors = PackedColorArray([Color(col.lightened(0.5), 1), Color(col, 0.9), Color(col, 0)])
	p.color_ramp = g
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var qm := _additive(DuelFX.dot_tex())
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	qm.vertex_color_use_as_albedo = true
	q.material = qm
	p.mesh = q
	p.emitting = true
	_fx_parent().add_child(p)
	get_tree().create_timer(life + 0.4).timeout.connect(p.queue_free)


## Sparkles drifting upward (healing, a KO's spirit, status effects).
func rise(at: Vector3, col: Color, amount: int = 30, life: float = 1.2, width: float = 1.2) -> void:
	var p := CPUParticles3D.new()
	p.position = at
	p.one_shot = true
	p.explosiveness = 0.5
	p.amount = amount
	p.lifetime = life
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(width * 0.5, 0.1, width * 0.3)
	p.direction = Vector3.UP
	p.spread = 15.0
	p.initial_velocity_min = 1.2
	p.initial_velocity_max = 2.6
	p.gravity = Vector3.ZERO
	var sc := Curve.new()
	sc.add_point(Vector2(0, 1))
	sc.add_point(Vector2(1, 0))
	p.scale_amount_curve = sc
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(col.lightened(0.3), 1), Color(col, 0)])
	p.color_ramp = g
	var q := QuadMesh.new()
	q.size = Vector2(0.11, 0.11)
	var qm := _additive(DuelFX.dot_tex())
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	qm.vertex_color_use_as_albedo = true
	q.material = qm
	p.mesh = q
	p.emitting = true
	_fx_parent().add_child(p)
	get_tree().create_timer(life + 0.4).timeout.connect(p.queue_free)


## A glowing orb that flies from a to b along an arc, trailing sparks.
## Await its `arrived`.
func bolt(a: Vector3, b: Vector3, col: Color, dur: float = 0.35, size: float = 0.9, arc: float = 1.4) -> Bolt3D:
	var n := Bolt3D.new()
	n.a = a
	n.b = b
	n.arc = arc
	n.col = col
	n.size = size
	_fx_parent().add_child(n)
	var tw := n.create_tween()
	tw.tween_property(n, "t", 1.0, dur).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(n._arrive)
	return n


class Bolt3D:
	extends Node3D
	signal arrived
	var a := Vector3.ZERO
	var b := Vector3.ZERO
	var arc := 1.4
	var col := Color.WHITE
	var size := 0.9
	var sp: Sprite3D
	var core: Sprite3D
	var trail: CPUParticles3D
	var lamp: OmniLight3D
	var t := 0.0:
		set(v):
			t = v
			var mid := (a + b) * 0.5 + Vector3(0, arc, 0)
			position = a.lerp(mid, t).lerp(mid.lerp(b, t), t)

	func _ready() -> void:
		sp = Sprite3D.new()
		sp.texture = DuelFX.glow_tex()
		sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sp.shaded = false
		sp.transparent = true
		sp.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
		sp.no_depth_test = true
		sp.modulate = Color(col.r * 1.6, col.g * 1.6, col.b * 1.6, 0.8)
		sp.pixel_size = size / 128.0
		add_child(sp)
		core = Sprite3D.new()
		core.texture = DuelFX.glow_tex()
		core.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		core.shaded = false
		core.transparent = true
		core.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
		core.no_depth_test = true
		core.modulate = Color(3, 3, 3, 1)
		core.pixel_size = size * 0.4 / 128.0
		add_child(core)
		lamp = OmniLight3D.new()
		lamp.light_color = col
		lamp.light_energy = 3.0
		lamp.omni_range = 4.0
		add_child(lamp)
		trail = CPUParticles3D.new()
		trail.amount = 50
		trail.lifetime = 0.4
		trail.local_coords = false
		trail.direction = Vector3.UP
		trail.spread = 180
		trail.initial_velocity_min = 0.2
		trail.initial_velocity_max = 1.0
		trail.gravity = Vector3.ZERO
		var sc := Curve.new()
		sc.add_point(Vector2(0, 1))
		sc.add_point(Vector2(1, 0))
		trail.scale_amount_curve = sc
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 1.0])
		g.colors = PackedColorArray([Color(col, 1), Color(col, 0)])
		trail.color_ramp = g
		var q := QuadMesh.new()
		q.size = Vector2(size * 0.3, size * 0.3)
		var qm := DuelField3D._additive(DuelFX.dot_tex())
		qm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		qm.vertex_color_use_as_albedo = true
		q.material = qm
		trail.mesh = q
		add_child(trail)
		t = 0.0

	func _arrive() -> void:
		arrived.emit()
		trail.emitting = false
		sp.visible = false
		core.visible = false
		var tw := create_tween()
		tw.tween_property(lamp, "light_energy", 0.0, 0.2)
		tw.tween_interval(0.5)
		tw.tween_callback(queue_free)


## A crackling bolt of lightning between two points.
func lightning(a: Vector3, b: Vector3, col: Color, dur: float = 0.32, width: float = 0.16) -> void:
	var n := Lightning3D.new()
	n.a = a
	n.b = b
	n.col = col
	n.width = width
	n.cam = cam
	_fx_parent().add_child(n)
	var tw := n.create_tween()
	tw.tween_property(n, "t", 1.0, dur)
	tw.tween_callback(n.queue_free)
	flash_light(b, col, 8.0, dur)
	flash_light(a, col, 3.0, dur * 0.5)


class Lightning3D:
	extends MeshInstance3D
	var a := Vector3.ZERO
	var b := Vector3.ZERO
	var col := Color.WHITE
	var width := 0.16
	var cam: Camera3D
	var _k := -1.0
	var _pts: Array = []
	var t := 0.0:
		set(v):
			t = v
			if v - _k > 0.1:
				_k = v
				_pts = _jag()
			_rebuild()

	func _ready() -> void:
		mesh = ImmediateMesh.new()
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.vertex_color_use_as_albedo = true
		m.no_depth_test = true
		material_override = m

	func _jag() -> Array:
		var pts := [a]
		var d := b - a
		var n := 12
		var up := Vector3.UP
		var side := d.cross(up).normalized()
		for i in range(1, n):
			var k := float(i) / n
			var amp := 0.45 * sin(k * PI)
			pts.append(a + d * k + side * randf_range(-amp, amp) + up * randf_range(-amp, amp))
		pts.append(b)
		return pts

	func _rebuild() -> void:
		var im := mesh as ImmediateMesh
		im.clear_surfaces()
		if _pts.size() < 2 or cam == null:
			return
		var al := 1.0 - t * t
		for layer in [[width * 3.0, Color(col, 0.35 * al)], [width, Color(col, 0.9 * al)], [width * 0.35, Color(1, 1, 1, al)]]:
			var w: float = layer[0]
			var c: Color = layer[1]
			im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
			for i in _pts.size():
				var p: Vector3 = _pts[i]
				var dir: Vector3 = (_pts[mini(i + 1, _pts.size() - 1)] - _pts[maxi(i - 1, 0)]).normalized()
				var to_cam := (cam.global_position - p).normalized()
				var side := dir.cross(to_cam).normalized() * w * 0.5
				im.surface_set_color(c)
				im.surface_add_vertex(p + side)
				im.surface_set_color(c)
				im.surface_add_vertex(p - side)
			im.surface_end()
