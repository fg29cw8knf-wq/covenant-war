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
	s.lamp.visible = false
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
			s.lamp.visible = false
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
			s.lamp.visible = false
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
	# (an empty slot's lamp off altogether: every light on the Circle costs
	# the phone another pass over the floor, lit or not; 27 October)
	s.lamp.visible = s.lamp.light_energy > 0.01
	s.lamp.light_color = col if v.flash <= 0.0 else col.lerp(v.flash_color, v.flash)
	s.glow_mat.albedo_color = Color(col, 0.16 * v.fade)
	_ring_state(s, v.highlight, col, 0.85 * v.fade)


## Models face +Z (the camera) as exported. The rival's face the player, the
## player's are turned to face across the board at the rival, each with a
## little angle so they aren't dead square to the camera.
static func home_yaw(s: Slot) -> float:
	return PI * 0.95 if s.mine else -PI * 0.05


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
			# (a stand-in keeps its own painted look, washed a little towards
			# its Totem's colour: until 27 October its solid surfaces went
			# plain in that colour, and Tam's River Hound, a Shieldhound in
			# blue, stood on the field as a glowing blue lump; Gary: "blue
			# for some reason")
			if ov == null or ov == base:
				ov = base.duplicate()
				mesh.set_surface_override_material(i, ov)
			var col := base.albedo_color
			if tinted:
				col = base.albedo_color * DuelArt.soft_tint(tint)
			ov.albedo_color = col * Color(dim, dim, dim, 1.0)
			ov.emission_enabled = true
			ov.emission = Color(m.r, m.g, m.b).lerp(base.emission if base.emission_enabled else Color.BLACK, 0.0) * 0.5 if flash > 0.001 else (base.emission if base.emission_enabled else Color.BLACK)
			ov.emission_energy_multiplier = (base.emission_energy_multiplier if base.emission_enabled else 0.0) + flash * 2.0


## Clip names the game asks for, and what a model may call them instead.
const CLIP_ALIASES := {
	"idle": ["idle", "breathe", "breathing"],
	"attack": ["attack", "bite", "pounce", "strike", "lunge"],
	"hit": ["hit", "hit_react", "hurt", "damage", "recoil", "stagger"],
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
		# the two ways the bolt can wander, both across its line (a bolt
		# straight down from the sky has no "side" against UP: 25 October)
		var side := d.cross(Vector3.UP)
		if side.length() < 0.01:
			side = d.cross(Vector3.RIGHT)
		side = side.normalized()
		var up := side.cross(d).normalized()
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


# ========================================================== Rite motifs ===
## Every Rite has an effect of its own on the field (25 October, Gary: "when
## you use the Bulwark card have it actually animate putting a wall around
## the Totem, then fades; same for others"). The motif is picked from what
## the card does (its effects' ops and its damage) and its element, so each
## card gets a picture that fits what it is: a stone wall for a shield, a
## block of ice for Frostbind, roots for Strangling Roots, rain for Drowning
## Rain, cards fanning up for a draw, and so on. `at` is where it lands (a
## Totem's body, or the duellist's plate for a Rite on nobody); `ahead` is
## the way towards that Totem's enemy (a wall stands on that side). Returns
## how long it plays (s), for the screen to wait.
func rite_motif(card: DuelCard, at: Vector3, ahead: Vector3, col: Color) -> float:
	var d: Dictionary = card.def
	var el := String(d.get("element", "any"))
	var effects: Array = d.get("effects", [])
	var dmg := int(d.get("damage", 0))
	var ops := []
	for e in effects:
		ops.append(String((e as Dictionary).get("op", "")))
	var foot := Vector3(at.x, 0.0, at.z)
	var status := ""
	for e in effects:
		if String((e as Dictionary).get("op", "")) == "status":
			status = String((e as Dictionary).get("status", ""))
	if "shield" in ops:
		return wall_ring(foot, ahead, el)
	if "heal" in ops or "cure" in ops or "regen" in ops or "life" in ops:
		return mend(foot, col)
	if "buff" in ops or "empower" in ops:
		return aura(foot, col)
	if "draw" in ops or "search_totem" in ops or "search" in ops or "search_rite" in ops:
		return cards_fan(foot, col)
	if "essence" in ops or "essence_max" in ops:
		return essence_motes(foot, col)
	if "bounce" in ops or "move_foe" in ops or "drain" in ops:
		return wave(foot, ahead, col)
	if status != "":
		return status_motif(foot, status, el, col)
	if dmg > 0 or String(d.get("target", "none")) in ["foe_totem", "all_foes"]:
		return strike_motif(foot, el, col, ahead)
	# a Rite on nobody in particular: the god's light at the plate
	pillar(foot, col, 4.0, 1.4, 0.8)
	rise(foot, col, 18, 0.9, 1.0)
	return 0.6


## Where a Rite on nobody in particular plays: on the ground in front of
## that side's row, in view (the plates themselves sit past the camera's
## edge, under the hand).
func plate_world(side: int) -> Vector3:
	return Vector3(0, 0, MY_Z + 0.6) if side == me else Vector3(0, 0, RIVAL_Z - 0.8)


## The way from a slot towards the row across from it.
func ahead_of(side: int) -> Vector3:
	return Vector3(0, 0, -1) if side == me else Vector3(0, 0, 1)


## A blow by element: fire flares, storm strikes down, tide sweeps over (in
## from the caster's side, so against `ahead`), frost spikes up, metal
## flies, venom rolls low, verdant grasps, wind whirls, earth falls, and the
## gods' elements come down as light.
func strike_motif(foot: Vector3, el: String, col: Color, ahead: Vector3) -> float:
	match el:
		"fire":
			return flames(foot, col)
		"storm":
			lightning(foot + Vector3(0.3, 4.6, 0), foot + Vector3(0, 0.8, 0), col, 0.4, 0.3)
			get_tree().create_timer(0.12).timeout.connect(func() -> void:
				lightning(foot + Vector3(-0.5, 4.6, 0.3), foot + Vector3(0.1, 0.9, 0), col, 0.3, 0.2))
			flash_sprite(foot + Vector3(0, 1.0, 0), Color(1, 1, 1), 2.6, 0.3)
			flash_light(foot + Vector3(0, 1.5, 0), col, 9.0, 0.4)
			burst(foot + Vector3(0, 0.6, 0), col, 30, 5.5, 0.5, 0.12, 1.0)
			return 0.55
		"tide":
			return wave(foot, -ahead, col)
		"frost":
			return spikes(foot, Color(0.78, 0.92, 1.0), 9, 1.4, 0.5, 0.12)
		"metal":
			burst(foot + Vector3(0, 1.0, 0), col.lightened(0.3), 34, 7.5, 0.5, 0.14, 0.4)
			flash_sprite(foot + Vector3(0, 1.0, 0), Color(1, 1, 1), 1.8, 0.25)
			return 0.45
		"venom":
			return cloud(foot, col, 1.1)
		"verdant":
			return spikes(foot, Color(0.3, 0.55, 0.22), 8, 1.3, 0.6, 0.1)
		"wind":
			return swirl(foot, col, 0.9, 2.2)
		"earth":
			return rockfall(foot, col)
		_:
			pillar(foot, col, 4.5, 1.6, 0.7)
			swirl(foot, col, 0.7, 1.2)
			return 0.6


## A condition settling on a Totem, each in its own way.
func status_motif(foot: Vector3, status: String, el: String, col: Color) -> float:
	var sc := Color(String(DuelConditions.DEFS.get(status, {}).get("color", "ffffff")))
	match status:
		"frozen":
			return ice_block(foot, sc)
		"burn":
			return flames(foot, Color(1.0, 0.55, 0.2))
		"poison", "corroded":
			return cloud(foot, sc, 1.1)
		"soaked":
			return rain_sheet(foot, sc, 0.8)
		"rooted":
			return spikes(foot, Color(0.3, 0.55, 0.22), 8, 1.2, 0.7, 0.1)
		"petrified":
			rockfall(foot, Color(0.72, 0.66, 0.54))
			return 0.9
		"shocked", "stun":
			lightning(foot + Vector3(-0.3, 4.2, 0), foot + Vector3(0, 0.9, 0), sc, 0.35, 0.26)
			flash_sprite(foot + Vector3(0, 1.0, 0), Color(1, 1, 0.9), 2.2, 0.3)
			flash_light(foot + Vector3(0, 1.5, 0), sc, 7.0, 0.3)
			return 0.45
		"blinded":
			flash_sprite(foot + Vector3(0, 1.1, 0), Color(1, 1, 0.9), 3.6, 0.45)
			flash_light(foot + Vector3(0, 1.2, 0), Color(1, 1, 0.85), 9.0, 0.4)
			return 0.45
		"bleed":
			burst(foot + Vector3(0, 1.0, 0), sc, 24, 4.0, 0.5, 0.12, 0.2)
			return 0.4
		"staggered":
			return swirl(foot, sc, 0.7, 2.0)
		"sleep":
			return swirl(foot, sc, 1.1, 0.6)
		_:
			# the mind and the soul: a slow ring of light climbing the body
			return swirl(foot, sc, 0.9, 1.0)


# ---------------------------------------------------------------- pieces ---

func _solid(col: Color, rough: float = 0.9, emit: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = emit
	return m


## A half-ring of stone slabs rising out of the ground round the Totem, on
## the side its enemies are, dust at their feet; they stand a moment, then
## sink and fade (Bulwark). Another element's shield is the same wall in its
## own light.
func wall_ring(foot: Vector3, ahead: Vector3, el: String) -> float:
	var stone := Color(0.46, 0.42, 0.36)
	var glow := 0.0
	if el != "earth" and el != "any":
		stone = DuelFX.light(el).darkened(0.35)
		glow = 0.6
	var n := 7
	var r := 1.45
	var h := 1.55
	var base := atan2(ahead.x, ahead.z)
	var slabs: Array = []
	for i in n:
		var a := base + (float(i) / (n - 1) - 0.5) * PI * 1.05
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.62, h, 0.24)
		m.mesh = bm
		m.material_override = _solid(stone.lightened(randf_range(-0.08, 0.08)), 0.95, glow)
		m.position = foot + Vector3(sin(a) * r, -h * 0.5 - 0.05, cos(a) * r)
		m.rotation.y = a
		m.rotation.z = randf_range(-0.06, 0.06)
		_fx_parent().add_child(m)
		slabs.append(m)
		var delay := 0.05 * absf(float(i) - (n - 1) * 0.5)
		var tw := m.create_tween()
		tw.tween_interval(delay)
		tw.tween_property(m, "position:y", foot.y + h * 0.5 - 0.02, 0.28).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_interval(1.0 - delay)
		tw.tween_property(m, "position:y", foot.y - h * 0.5 - 0.05, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.parallel().tween_property(m.material_override, "albedo_color:a", 0.0, 0.5)
		tw.tween_callback(m.queue_free)
		get_tree().create_timer(delay + 0.05).timeout.connect(func() -> void:
			if is_instance_valid(m):
				burst(Vector3(m.position.x, foot.y + 0.05, m.position.z), Color(0.6, 0.52, 0.4), 10, 2.2, 0.5, 0.1, 1.0))
	cam_shake(0.12)
	flash_light(foot + Vector3(0, 1.2, 0), DuelFX.light(el) if el != "any" else Color(0.9, 0.8, 0.6), 3.0, 0.6)
	return 1.4


## Thin spikes thrusting up out of the ground round the feet and sinking
## again: roots (green), ice (pale blue), shards of stone.
func spikes(foot: Vector3, col: Color, count: int, h: float, hold: float, width: float) -> float:
	for i in count:
		var a := randf() * TAU
		var r := randf_range(0.35, 1.0)
		var m := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = width
		cm.height = h * randf_range(0.7, 1.1)
		cm.radial_segments = 6
		m.mesh = cm
		m.material_override = _solid(col.lightened(randf_range(-0.1, 0.1)), 0.7, 0.25)
		var p := foot + Vector3(sin(a) * r, 0, cos(a) * r)
		m.position = p + Vector3(0, -cm.height * 0.5, 0)
		m.rotation = Vector3(randf_range(-0.25, 0.25), 0, randf_range(-0.25, 0.25))
		_fx_parent().add_child(m)
		var tw := m.create_tween()
		tw.tween_interval(randf_range(0.0, 0.12))
		tw.tween_property(m, "position:y", p.y + cm.height * 0.5 - 0.05, 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_interval(hold)
		tw.tween_property(m, "position:y", p.y - cm.height * 0.5, 0.35).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(m.material_override, "albedo_color:a", 0.0, 0.35)
		tw.tween_callback(m.queue_free)
	burst(foot + Vector3(0, 0.2, 0), col, 14, 2.5, 0.5, 0.1, 1.0)
	return 0.35 + hold + 0.2


## A block of ice closing round the Totem, held a breath, then shattered.
func ice_block(foot: Vector3, col: Color) -> float:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.7, 2.1, 1.5)
	m.mesh = bm
	var mat := _solid(Color(col.r, col.g, col.b, 0.55), 0.1, 0.35)
	mat.metallic = 0.3
	m.material_override = mat
	m.position = foot + Vector3(0, 1.05, 0)
	m.scale = Vector3(0.05, 0.05, 0.05)
	_fx_parent().add_child(m)
	var tw := m.create_tween()
	tw.tween_property(m, "scale", Vector3.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(0.7)
	tw.tween_callback(func() -> void:
		burst(foot + Vector3(0, 1.0, 0), col.lightened(0.3), 40, 6.0, 0.7, 0.16, 0.5)
		flash_sprite(foot + Vector3(0, 1.0, 0), col, 2.6, 0.3))
	tw.tween_property(m, "scale", Vector3(0.02, 0.02, 0.02), 0.12)
	tw.tween_callback(m.queue_free)
	flash_light(foot + Vector3(0, 1.4, 0), col, 4.0, 0.6)
	return 1.25


## Flames licking up round the Totem: a flickering column, sparks, light.
func flames(foot: Vector3, col: Color) -> float:
	pillar(foot, col, 3.2, 1.9, 0.7)
	get_tree().create_timer(0.18).timeout.connect(func() -> void:
		pillar(foot + Vector3(0.3, 0, 0.2), col.lightened(0.2), 2.4, 1.3, 0.6))
	burst(foot + Vector3(0, 0.5, 0), col, 36, 4.5, 0.8, 0.13, 1.0)
	rise(foot, Color(1.0, 0.7, 0.3), 20, 0.9, 1.4)
	flash_light(foot + Vector3(0, 1.2, 0), col, 7.0, 0.7)
	return 0.8


## A wave sweeping over the Totem and on past it: a body of translucent
## water with a rolling white crest (solid geometry, which reads on the
## bright floor where a glow would not), then spray as it passes.
func wave(foot: Vector3, dir: Vector3, col: Color) -> float:
	var holder := Node3D.new()
	var flat := Vector3(dir.x, 0, dir.z).normalized()
	var from := foot - flat * 2.0
	var to := foot + flat * 2.0
	holder.position = from
	_fx_parent().add_child(holder)
	holder.look_at(from + flat, Vector3.UP)
	var water := Color(col.r * 0.8, col.g * 0.9, col.b * 1.05, 0.62)
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(3.2, 1.4, 0.7)
	body.mesh = bm
	var wm := _solid(water, 0.08, 0.55)
	wm.metallic = 0.2
	body.material_override = wm
	body.position = Vector3(0, 0.7, 0)
	body.rotation.x = 0.3
	holder.add_child(body)
	var crest := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.34
	cm.bottom_radius = 0.34
	cm.height = 3.0
	cm.radial_segments = 14
	crest.mesh = cm
	var crm := _solid(Color(0.9, 0.97, 1.0, 0.85), 0.2, 0.9)
	crest.material_override = crm
	crest.position = Vector3(0, 1.45, 0.2)
	crest.rotation.z = PI * 0.5
	holder.add_child(crest)
	var tw := holder.create_tween()
	tw.tween_property(holder, "position", to, 0.6).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(crest, "rotation:x", -TAU * 1.5, 0.6)
	tw.parallel().tween_property(wm, "albedo_color:a", 0.0, 0.25).set_delay(0.4)
	tw.parallel().tween_property(crm, "albedo_color:a", 0.0, 0.25).set_delay(0.4)
	tw.tween_callback(holder.queue_free)
	floor_wave(foot, col, 3.0, 0.5)
	# spray thrown up as it passes
	get_tree().create_timer(0.22).timeout.connect(func() -> void:
		burst(foot + Vector3(0, 0.9, 0), Color(0.85, 0.95, 1.0), 44, 4.5, 0.7, 0.14, 1.0))
	flash_light(foot + Vector3(0, 1.0, 0), col, 4.0, 0.6)
	return 0.7


## Rain pouring down on the Totem.
func rain_sheet(foot: Vector3, col: Color, secs: float) -> float:
	var p := CPUParticles3D.new()
	p.position = foot + Vector3(0, 3.4, 0)
	p.amount = 90
	p.lifetime = 0.45
	p.one_shot = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(1.1, 0.1, 0.9)
	p.direction = Vector3.DOWN
	p.spread = 3.0
	p.initial_velocity_min = 7.0
	p.initial_velocity_max = 8.5
	p.gravity = Vector3.ZERO
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(col.lightened(0.4), 0.9), Color(col, 0.5)])
	p.color_ramp = g
	var q := QuadMesh.new()
	q.size = Vector2(0.035, 0.4)
	var qm := _additive(DuelFX.dot_tex())
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	qm.vertex_color_use_as_albedo = true
	q.material = qm
	p.mesh = q
	p.emitting = true
	_fx_parent().add_child(p)
	get_tree().create_timer(secs).timeout.connect(func() -> void:
		if is_instance_valid(p):
			p.emitting = false)
	get_tree().create_timer(secs + 0.6).timeout.connect(p.queue_free)
	floor_wave(foot, col, 2.4, secs)
	return secs + 0.2


## A low cloud rolling round the feet (venom, poison).
func cloud(foot: Vector3, col: Color, secs: float) -> float:
	var p := CPUParticles3D.new()
	p.position = foot + Vector3(0, 0.25, 0)
	p.amount = 64
	p.lifetime = secs
	p.one_shot = true
	p.explosiveness = 0.8
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.6
	p.direction = Vector3(1, 0.1, 0)
	p.spread = 180.0
	p.initial_velocity_min = 0.6
	p.initial_velocity_max = 1.6
	p.gravity = Vector3(0, 0.15, 0)
	p.damping_min = 1.0
	p.damping_max = 2.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	var sc := Curve.new()
	sc.add_point(Vector2(0, 0.4))
	sc.add_point(Vector2(0.3, 1))
	sc.add_point(Vector2(1, 0))
	p.scale_amount_curve = sc
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	var bright := Color(col.r * 2.4, col.g * 2.4, col.b * 2.4)
	g.colors = PackedColorArray([Color(bright, 0.0), Color(bright, 1.0), Color(bright, 0)])
	p.color_ramp = g
	var q := QuadMesh.new()
	q.size = Vector2(0.7, 0.7)
	var qm := _additive(DuelFX.glow_tex())
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	qm.vertex_color_use_as_albedo = true
	q.material = qm
	p.mesh = q
	p.emitting = true
	_fx_parent().add_child(p)
	get_tree().create_timer(secs + 0.4).timeout.connect(p.queue_free)
	floor_wave(foot, col, 2.6, secs * 0.8)
	flash_light(foot + Vector3(0, 0.6, 0), col, 4.0, secs)
	return secs * 0.7


## Lights whirling round the body and climbing it.
func swirl(foot: Vector3, col: Color, secs: float, speed: float) -> float:
	var p := CPUParticles3D.new()
	p.position = foot + Vector3(0, 0.3, 0)
	p.amount = 48
	p.lifetime = secs
	p.one_shot = true
	p.explosiveness = 0.7
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_radius = 0.9
	p.emission_ring_inner_radius = 0.8
	p.emission_ring_height = 0.2
	p.emission_ring_axis = Vector3.UP
	p.direction = Vector3.UP
	p.spread = 5.0
	p.initial_velocity_min = 1.2
	p.initial_velocity_max = 1.8
	p.gravity = Vector3.ZERO
	p.tangential_accel_min = 4.0 * speed
	p.tangential_accel_max = 6.0 * speed
	p.radial_accel_min = -1.5
	p.radial_accel_max = -0.5
	var sc := Curve.new()
	sc.add_point(Vector2(0, 0.6))
	sc.add_point(Vector2(0.5, 1))
	sc.add_point(Vector2(1, 0))
	p.scale_amount_curve = sc
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.7, 1.0])
	g.colors = PackedColorArray([Color(col.lightened(0.4), 1), Color(col, 0.9), Color(col, 0)])
	p.color_ramp = g
	var q := QuadMesh.new()
	q.size = Vector2(0.14, 0.14)
	var qm := _additive(DuelFX.dot_tex())
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	qm.vertex_color_use_as_albedo = true
	q.material = qm
	p.mesh = q
	p.emitting = true
	_fx_parent().add_child(p)
	get_tree().create_timer(secs + 0.4).timeout.connect(p.queue_free)
	flash_light(foot + Vector3(0, 1.2, 0), col, 3.5, secs)
	return secs * 0.8


## Rocks tumbling down on the Totem, dust where they land, gone again.
func rockfall(foot: Vector3, col: Color) -> float:
	var stone := Color(0.5, 0.45, 0.38)
	for i in 5:
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		var sz := randf_range(0.28, 0.5)
		bm.size = Vector3(sz, sz * 0.8, sz * 0.9)
		m.mesh = bm
		m.material_override = _solid(stone.lightened(randf_range(-0.1, 0.1)), 0.95, 0.0)
		var land := foot + Vector3(randf_range(-0.8, 0.8), sz * 0.4, randf_range(-0.7, 0.7))
		m.position = land + Vector3(0, 3.8, 0)
		m.rotation = Vector3(randf() * TAU, randf() * TAU, 0)
		_fx_parent().add_child(m)
		var tw := m.create_tween()
		tw.tween_interval(0.08 * i)
		tw.tween_property(m, "position", land, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.tween_callback(func() -> void:
			burst(Vector3(land.x, foot.y + 0.05, land.z), Color(0.6, 0.52, 0.4), 10, 2.2, 0.45, 0.1, 1.0)
			cam_punch(0.06))
		tw.tween_interval(0.6)
		tw.tween_property(m.material_override, "albedo_color:a", 0.0, 0.4)
		tw.parallel().tween_property(m, "position:y", foot.y - sz, 0.4).set_ease(Tween.EASE_IN)
		tw.tween_callback(m.queue_free)
	flash_light(foot + Vector3(0, 1.2, 0), col, 2.5, 0.6)
	return 1.1


## Mending: a warm ring on the ground and motes climbing the body.
func mend(foot: Vector3, col: Color) -> float:
	floor_wave(foot, col, 2.8, 0.6)
	pillar(foot, col, 2.6, 1.5, 1.0)
	rise(foot, col, 44, 1.3, 1.4)
	flash_sprite(foot + Vector3(0, 1.0, 0), col, 2.4, 0.6)
	flash_light(foot + Vector3(0, 1.2, 0), col, 4.0, 0.9)
	return 0.8


## A buff: a ring of the element's light climbing the body and tightening on it.
func aura(foot: Vector3, col: Color) -> float:
	var m := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 1.05
	tm.outer_radius = 1.2
	tm.rings = 24
	tm.ring_segments = 8
	m.mesh = tm
	var mat := _additive(DuelFX.glow_tex())
	mat.albedo_color = Color(col.r * 1.6, col.g * 1.6, col.b * 1.6, 0.9)
	m.material_override = mat
	m.position = foot + Vector3(0, 0.1, 0)
	_fx_parent().add_child(m)
	var tw := m.create_tween()
	tw.tween_property(m, "position:y", foot.y + 1.9, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(m, "scale", Vector3(0.45, 1, 0.45), 0.6).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.6).set_delay(0.25)
	tw.tween_callback(m.queue_free)
	burst(foot + Vector3(0, 0.3, 0), col, 20, 3.0, 0.6, 0.1, 1.0)
	flash_light(foot + Vector3(0, 1.2, 0), col, 4.0, 0.6)
	return 0.7


## Cards rising from the duellist's plate and fanning out as they fade (a draw, a search).
func cards_fan(at: Vector3, col: Color) -> float:
	for i in 3:
		var m := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.34, 0.48)
		m.mesh = q
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.92, 0.88, 0.78, 1.0)
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 0.6
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.material_override = mat
		m.position = at + Vector3(0, 0.6, 0)
		m.rotation = Vector3(-0.3, (i - 1) * 0.35, 0)
		_fx_parent().add_child(m)
		var tw := m.create_tween()
		tw.tween_interval(0.07 * i)
		tw.tween_property(m, "position", at + Vector3((i - 1) * 0.55, 2.2, 0), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.parallel().tween_property(m, "rotation:z", (i - 1) * 0.3, 0.5)
		tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.5).set_delay(0.25)
		tw.tween_callback(m.queue_free)
	rise(at + Vector3(0, 0.5, 0), col, 16, 0.9, 0.9)
	flash_light(at + Vector3(0, 1.4, 0), col, 3.0, 0.6)
	return 0.7


## Essence drawn in: motes gathering to the plate out of the air.
func essence_motes(at: Vector3, col: Color) -> float:
	var p := CPUParticles3D.new()
	p.position = at + Vector3(0, 1.4, 0)
	p.amount = 48
	p.lifetime = 0.7
	p.one_shot = true
	p.explosiveness = 0.9
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 1.8
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 0.0
	p.initial_velocity_max = 0.3
	p.gravity = Vector3.ZERO
	p.radial_accel_min = -12.0
	p.radial_accel_max = -9.0
	var sc := Curve.new()
	sc.add_point(Vector2(0, 0.5))
	sc.add_point(Vector2(1, 1))
	p.scale_amount_curve = sc
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(col, 0.2), Color(col.lightened(0.5), 1)])
	p.color_ramp = g
	var q := QuadMesh.new()
	q.size = Vector2(0.18, 0.18)
	var qm := _additive(DuelFX.dot_tex())
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	qm.vertex_color_use_as_albedo = true
	q.material = qm
	p.mesh = q
	p.emitting = true
	_fx_parent().add_child(p)
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)
	get_tree().create_timer(0.65).timeout.connect(func() -> void:
		flash_sprite(at + Vector3(0, 1.4, 0), col, 2.4, 0.4)
		flash_light(at + Vector3(0, 1.4, 0), col, 6.0, 0.4))
	return 0.9
