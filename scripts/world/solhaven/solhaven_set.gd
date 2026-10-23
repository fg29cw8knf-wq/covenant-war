extends Node3D
## Solhaven, for Chapter 1 (Master Script v3): the city and the places its
## story goes, built as stand-ins from LevelKit's blocks until Gary's models
## arrive. Each piece is picked up by its file name the moment it exists in
## assets/models/solhaven/ (the names in the "Solhaven: Your Step-by-Step"
## doc), fitted to the stand-in's size, and the stand-in isn't built:
##
##   golden_gate, gate_door (one leaf, mirrored for the other), wagon,
##   card_stall, fountain, house_a / house_b / house_c, notice_board, temple,
##   sun_court, hierarch_throne, solmaris_statue, hall_of_mirrors,
##   temple_mirror, sunspire, sunspire_roof, sun_mirror, morne_vault,
##   morne_desk; and Turnip, characters/turnip.glb.
##
## Layout (metres; the walking camera looks north, towards -z):
##   the Sun Square     the hub: the temple on the north side, the fountain in
##                      the middle, the stable yard and Bram's wagon east, the
##                      market south-east, the notice board west, the
##                      Sunspire's door in the west wall
##   the Golden Gate    the south end of the square (z = 25), and the road
##                      outside it, crowded with refugees
##   the lane           east of the market, where Wren runs (the chase)
##   the Sunspire       a tower west of the square; its roof (y = 42) is the
##                      great duelling circle under the colossal mirror
##   the field          beside the road outside the walls: the wagon at night
##   inside             far off to the east, out of sight of the city: the Sun
##                      Court, the Hall of Mirrors and Ironvault (Morne's vault)
##
## set_scene() sets the sky and the light for each.

const DIR := "res://assets/models/solhaven/"

## Marks the story stages its scenes on.
const SPOTS := {
	"gate": Vector3(0, 0, 25.0),              # the middle of the gateway
	"road": Vector3(0, 0, 34.0),              # outside, where Bram and the player stop
	"wagon": Vector3(12.6, 0, -4.2),          # the stable yard
	"fountain": Vector3(0, 0, -3.5),
	"stall": Vector3(12.8, 0, 6.0),           # Tamsin's card stall
	"board": Vector3(-13.2, 0, 2.0),          # the notice board
	"temple_door": Vector3(0, 0, -18.0),      # the foot of the temple steps
	"spire_door": Vector3(-15.0, 0, -9.0),    # the Sunspire's door in the west wall
	"lane_start": Vector3(14.0, 0, 13.6),
	"dead_end": Vector3(60.0, 0, -7.0),
	"spire": Vector3(-36.0, 0, -26.0),        # the Sunspire's foot
	"field": Vector3(17.0, 0, 64.0),          # the wagon at night
	"court": Vector3(600.0, 0, 0.0),          # the Sun Court's doors (the hall runs north)
	"mirrors": Vector3(600.0, 0, 200.0),      # the middle of the Hall of Mirrors
	"vault": Vector3(600.0, 0, 400.0),        # Morne's desk
}
const ROOF_Y := 42.0
## The chase: Wren's way through the lane, and the obstacles on it (each
## a glowing ledge to tap: "vault" over it or "slide" under it).
const CHASE := [
	{"at": Vector3(22.0, 0, 13.6), "kind": "vault", "what": "crates"},
	{"at": Vector3(30.0, 0, 13.6), "kind": "slide", "what": "washing"},
	{"at": Vector3(39.0, 0, 13.6), "kind": "vault", "what": "cart"},
	{"at": Vector3(48.0, 0, 13.6), "kind": "vault", "what": "ledge"},
	{"at": Vector3(60.0, 0, 6.0), "kind": "slide", "what": "arch"},
]

var quality := 2
var env: Environment
var sun: DirectionalLight3D
var sky_mat: ProceduralSkyMaterial
var gate_doors: Array = []        # the two leaves' hinges
var wagon: Node3D                 # the wagon, its lamp and Turnip together
var wagon_lamp: OmniLight3D
var wagon_glow: MeshInstance3D
var turnip: Node3D
var turnip_anim: AnimationPlayer
var sun_mirror: Node3D            # the great mirror's pivot, on the Sunspire
var shaft: MeshInstance3D         # the column of gold light in the Sun Court
var court_window: MeshInstance3D
var solmaris: Node3D              # Solmaris leaning down out of the glare
var statue: Node3D
var mirror_frames: Array = []     # the Hall of Mirrors' mirrors (their glass)
var candles: Array = []
var vault_cards: MultiMeshInstance3D
var ledger_label: Label3D
var obstacles: Array = []         # the chase's obstacles, in CHASE's order
var marker: Node3D                # the light over where the story goes next
var lights_day: Array = []        # lights that only belong to one scene
var lights_court: Array = []
var lights_mirrors: Array = []
var lights_night: Array = []
var lights_vault: Array = []
var roof_crowd_spots: Array = []  # where the Sunspire's crowd sits [pos, facing]
var cheap_seat_spots: Array = []  # the very top: the refugees, if the gate was opened
var board_label: Label3D


func _ready() -> void:
	quality = Gfx.level()
	_build_environment()
	_build_ground()
	_build_square()
	_build_temple()
	_build_gate()
	_build_road()
	_build_houses()
	_build_market()
	_build_wagon(SPOTS.wagon)
	_build_board()
	_build_spire()
	_build_lane()
	_build_court()
	_build_mirrors()
	_build_vault()
	_build_backdrop()
	_build_marker()
	set_scene("day")


# ================================================================= models ===

## Pieces whose file Gary named otherwise than "Solhaven: Your Step-by-Step"
## does (23 October: the gate's doors came as solhaven_gate_door.glb, Bram's
## wagon as covered_wagon.glb): each name is tried in turn, his first.
const MODEL_FILES := {"gate_door": ["solhaven_gate_door", "gate_door"], "wagon": ["covered_wagon", "wagon"]}


## The file of Gary's model for a piece, or "" until it's in.
static func model_path(id: String) -> String:
	for name in MODEL_FILES.get(id, [id]):
		var path: String = DIR + name + ".glb"
		if ResourceLoader.exists(path):
			return path
	return ""


## One of Gary's Solhaven models, fitted to `size` (the stand-in's width,
## height and depth; 0 keeps that axis in proportion, by height), its base on
## `pos`, turned by `yaw` degrees. null when the file isn't there yet.
func model(id: String, parent: Node3D, pos: Vector3, yaw: float, size: Vector3, collide := true) -> Node3D:
	var path := model_path(id)
	if path == "":
		return null
	var root := Node3D.new()
	root.name = id.capitalize().replace(" ", "")
	root.position = pos
	root.rotation.y = deg_to_rad(yaw)
	parent.add_child(root)
	var inst: Node3D = (load(path) as PackedScene).instantiate()
	root.add_child(inst)
	var box := AABB()
	var first := true
	for mi: MeshInstance3D in inst.find_children("*", "MeshInstance3D", true, false):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		var b := (root.global_transform.affine_inverse() * mi.global_transform) * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	if first:
		return root
	var k := 1.0
	if size.y > 0.0 and box.size.y > 0.001:
		k = size.y / box.size.y
	elif size.x > 0.0 and box.size.x > 0.001:
		k = size.x / box.size.x
	inst.scale = Vector3.ONE * k
	# its base on the ground, its middle on the mark
	var c := box.get_center() * k
	inst.position = Vector3(-c.x, -box.position.y * k, -c.z)
	if collide:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(box.size.x * k, minf(box.size.y * k, 4.0), box.size.z * k)
		cs.shape = sh
		cs.position = Vector3(0, sh.size.y * 0.5, 0)
		body.add_child(cs)
		root.add_child(body)
	return root


## Is Gary's model for this piece in yet?
static func has_model(id: String) -> bool:
	return model_path(id) != ""


func _mat(col: Color, rough := 0.8, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	return m


func _glow_mat(col: Color, energy: float, alpha := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(col, alpha)
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = energy
	return m


func _omni(parent: Node3D, pos: Vector3, col: Color, energy: float, rng: float, group: Array, shadows := false) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng
	l.shadow_enabled = shadows and quality >= 2
	parent.add_child(l)
	group.append(l)
	return l


# ============================================================ environment ===

func _build_environment() -> void:
	var we := WorldEnvironment.new()
	env = Environment.new()
	var sky := Sky.new()
	sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_curve = 0.12
	sky_mat.sun_angle_max = 20.0
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.glow_enabled = quality >= 1
	env.glow_intensity = 0.7
	env.glow_bloom = 0.06
	env.glow_hdr_threshold = 1.1
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.ssao_enabled = quality >= 2
	env.ssao_radius = 1.2
	env.ssao_intensity = 1.4
	env.fog_enabled = true
	env.fog_aerial_perspective = 0.35
	env.fog_sky_affect = 0.25
	env.adjustment_enabled = true
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.shadow_blur = 1.5
	sun.light_angular_distance = 0.8
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 60.0
	add_child(sun)


## The sky and the light: "day" (the city, the gate, the Sunspire), "court",
## "mirrors", "night" (the field) or "vault".
func set_scene(kind: String) -> void:
	for g in [lights_court, lights_mirrors, lights_night, lights_vault]:
		for l in g:
			(l as Light3D).visible = false
	var group: Array = {"court": lights_court, "mirrors": lights_mirrors, "night": lights_night, "vault": lights_vault}.get(kind, [])
	for l in group:
		(l as Light3D).visible = true
	match kind:
		"court", "mirrors", "vault":
			env.background_mode = Environment.BG_COLOR
			env.background_color = Color(0.01, 0.01, 0.015)
			env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			env.ambient_light_color = {"court": Color(0.9, 0.82, 0.62), "mirrors": Color(0.8, 0.7, 0.55), "vault": Color(0.55, 0.6, 0.7)}[kind]
			env.ambient_light_energy = {"court": 0.32, "mirrors": 0.22, "vault": 0.12}[kind]
			env.fog_enabled = kind != "court"
			env.fog_light_color = Color(0.05, 0.04, 0.03) if kind == "mirrors" else Color(0.02, 0.025, 0.035)
			env.fog_density = 0.02
			env.adjustment_saturation = 1.05
			env.adjustment_contrast = 1.1
			sun.visible = false
		"night":
			env.background_mode = Environment.BG_SKY
			env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
			sky_mat.sky_top_color = Color(0.02, 0.03, 0.08)
			sky_mat.sky_horizon_color = Color(0.08, 0.1, 0.18)
			sky_mat.ground_horizon_color = Color(0.05, 0.05, 0.08)
			sky_mat.ground_bottom_color = Color(0.01, 0.01, 0.02)
			sky_mat.sky_energy_multiplier = 0.6
			env.ambient_light_energy = 0.25
			env.fog_enabled = true
			env.fog_light_color = Color(0.05, 0.06, 0.1)
			env.fog_density = 0.006
			env.adjustment_saturation = 0.9
			env.adjustment_contrast = 1.05
			sun.visible = true
			sun.rotation_degrees = Vector3(-40, 140, 0)
			sun.light_color = Color(0.55, 0.65, 0.95)
			sun.light_energy = 0.22
		_:
			env.background_mode = Environment.BG_SKY
			env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
			sky_mat.sky_top_color = Color("3f7fcf")
			sky_mat.sky_horizon_color = Color("f4d9a8")
			sky_mat.ground_horizon_color = Color("d9c49a")
			sky_mat.ground_bottom_color = Color("d9c49a").darkened(0.4)
			sky_mat.sky_energy_multiplier = 1.1
			env.ambient_light_energy = 0.4
			env.fog_enabled = true
			env.fog_light_color = Color("f1dcb6")
			env.fog_density = 0.0035
			env.adjustment_saturation = 1.18
			env.adjustment_contrast = 1.08
			sun.visible = true
			sun.rotation_degrees = Vector3(-38, -32, 0)
			sun.light_color = Color("ffe2b0")
			sun.light_energy = 1.15
	if wagon_lamp != null:
		wagon_lamp.light_energy = 2.2 if kind == "night" else 1.0


# ================================================================ the city ===

func _build_ground() -> void:
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(260, 260)
	ground.mesh = pm
	ground.material_override = LevelKit.mat("grass")
	ground.position = Vector3(0, 0, 10)
	add_child(ground)
	var gbody := StaticBody3D.new()
	var gcs := CollisionShape3D.new()
	gcs.shape = WorldBoundaryShape3D.new()
	gbody.add_child(gcs)
	add_child(gbody)


func _build_square() -> void:
	LevelKit.box(self, Vector3(0, -0.2, -1), Vector3(40, 0.24, 52), "cobble", false)
	LevelKit.box(self, Vector3(0, -0.18, 12), Vector3(8, 0.24, 26), "flagstone", false)    # the way in from the gate
	LevelKit.box(self, Vector3(0, -0.18, -11), Vector3(9, 0.24, 18), "flagstone", false)   # the processional way
	# the fountain: Gary's, or a sun on a basin
	var f := SPOTS.fountain as Vector3
	if model("fountain", self, f, 0, Vector3(0, 3.6, 0)) == null:
		LevelKit.cylinder(self, f, 3.2, 0.25, "marble", true, 3.2, 40)
		var rim := LevelKit.torus(self, f + Vector3(0, 0.42, 0), 2.85, 3.3, "marble")
		rim.scale.y = 1.6
		var w := LevelKit.cylinder(self, f + Vector3(0, 0.25, 0), 2.95, 0.22, "water", false, 2.95, 40)
		w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		LevelKit.cylinder(self, f, 0.45, 2.6, "marble", false, 0.3, 16)
		LevelKit.cylinder(self, f + Vector3(0, 2.3, 0), 1.1, 0.25, "marble", false, 1.3, 24)
		var s := LevelKit.sphere(self, f + Vector3(0, 3.2, 0), 0.55, "sun_glow")
		s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for i in 8:
			var a := TAU * i / 8.0
			var ray := LevelKit.box(self, f + Vector3(cos(a) * 0.85, 3.08, sin(a) * 0.85), Vector3(0.5, 0.08, 0.12), "gold", false)
			ray.rotation.y = -a
	_omni(self, f + Vector3(0, 3.3, 0), Color("ffd88a"), 1.1, 7.0, lights_day)
	# lamps, benches, greenery
	for p in [Vector3(-4.6, 0, 4.0), Vector3(4.6, 0, 4.0), Vector3(-4.6, 0, -10.5), Vector3(4.6, 0, -10.5), Vector3(-3.4, 0, 18.0), Vector3(3.4, 0, 18.0)]:
		LevelKit.lamp(self, p, false)
	LevelKit.bench(self, Vector3(-9.6, 0, -2.0), 90)
	LevelKit.bench(self, Vector3(-4.2, 0, -7.6), 90)
	for z in [-15.0, -7.0, 1.0, 9.0, 17.0]:
		LevelKit.cypress(self, Vector3(-15.0, 0, z), 5.5)
	for z in [-15.0, 15.0, 20.0]:
		LevelKit.cypress(self, Vector3(15.4, 0, z), 5.0)
	LevelKit.tree(self, Vector3(-12.0, 0, 12.0), 1.1)
	LevelKit.tree(self, Vector3(-7.0, 0, 15.0), 0.9)
	LevelKit.banner(self, Vector3(-15.4, 5.5, -2), 90, "radiant")
	LevelKit.banner(self, Vector3(15.45, 5.2, -12), -90, "radiant")


func _build_temple() -> void:
	var z0 := -19.0
	# the steps up to it stay as they are; Gary's temple stands on them
	for i in 4:
		LevelKit.box(self, Vector3(0, i * 0.3, z0 - 1.0 - i * 0.7), Vector3(22 - i * 0.8, 0.3, 4.0 + i * 1.4), "marble", i == 0)
	if model("temple", self, Vector3(0, 1.2, -28.0), 0, Vector3(0, 17.0, 0)) == null:
		LevelKit.box(self, Vector3(0, 1.2, -26), Vector3(20, 0.2, 12), "marble", false)
		for i in 7:
			var x := -8.1 + i * 2.7
			LevelKit.column(self, Vector3(x, 1.2, z0 - 3.0), 7.0, 0.45)
		LevelKit.box(self, Vector3(0, 8.2, z0 - 3.4), Vector3(19.6, 0.9, 2.2), "marble", false)
		LevelKit.gable(self, Vector3(0, 9.1, z0 - 3.4), 20.4, 2.4, 2.4, "marble")
		LevelKit.box(self, Vector3(0, 9.1, z0 - 2.25), Vector3(1.6, 1.6, 0.1), "gold", false)
		LevelKit.box(self, Vector3(0, 1.2, -27), Vector3(16, 8.5, 10), "marble")
		LevelKit.box(self, Vector3(0, 1.2, z0 - 4.95), Vector3(3.2, 5.2, 0.2), "gold", false)  # the great door
		LevelKit.cylinder(self, Vector3(0, 9.7, -27), 5.2, 2.2, "marble", false, 5.2, 32)
		LevelKit.dome(self, Vector3(0, 11.9, -27), 5.0, "gold")
		LevelKit.sphere(self, Vector3(0, 17.4, -27), 0.7, "sun_glow")
		for x in [-11.0, 11.0]:
			LevelKit.cylinder(self, Vector3(x, 1.2, -25), 1.6, 11.0, "marble", true, 1.5, 20)
			LevelKit.cylinder(self, Vector3(x, 12.2, -25), 1.8, 3.4, "gold", false, 0.0, 20)
	for x in [-5.8, 5.8]:
		LevelKit.banner(self, Vector3(x, 7.6, -18.9), 0)


## The Golden Gate's measurements: Gary's model (22 October, assets/models/
## solhaven/golden_gate.glb) at its real size, 24.0 m wide (its towers and
## short wing walls), 4.9 m deep and 16.2 m high, its arch 5.7 m clear and
## 7.1 m to the crown, pivot at ground level in the middle of the gateway,
## facing +z (the road). The square's 8 m way in runs under the arch, the
## city wall either side starts where the gate's wings end, and the doors
## hang in the arch, a leaf each side.
const GATE_WIDTH := 24.0
const GATE_DEPTH := 4.9
const ARCH_WIDTH := 5.7
const ARCH_CROWN := 7.1
const DOOR_HEIGHT := 5.6   # (a leaf's top corners sit inside the stone above the arch's spring, 4.25 m)


## The Golden Gate in the south wall, its doors able to swing (open_gate()),
## and the walls either side.
func _build_gate() -> void:
	var g := SPOTS.gate as Vector3
	var real := model("golden_gate", self, g, 0, Vector3.ZERO, false)   # (as made: 24 m wide)
	var half_arch := ARCH_WIDTH * 0.5 if real != null else 4.45
	var leaf_w := half_arch - 0.03
	var leaf_h := DOOR_HEIGHT if real != null else 6.0
	var wing := GATE_WIDTH * 0.5 if real != null else 8.0   # where the city wall takes over
	if real == null:
		for x in [-6.2, 6.2]:
			LevelKit.box(self, g + Vector3(x, 0, 0), Vector3(3.4, 9.0, 3.6), "sandstone")
			LevelKit.box(self, g + Vector3(x, 9.0, 0), Vector3(3.8, 0.4, 4.0), "sandstone", false)
			LevelKit.cylinder(self, g + Vector3(x, 9.4, 0), 1.5, 1.6, "gold", false, 0.2, 16)
			LevelKit.banner(self, g + Vector3(x, 7.8, 1.85), 0, "radiant")
		# the arch over the doors
		LevelKit.box(self, g + Vector3(0, 7.0, 0), Vector3(9.0, 2.0, 3.0), "sandstone", false)
		LevelKit.box(self, g + Vector3(0, 6.7, 1.52), Vector3(5.6, 0.3, 0.1), "gold", false)
		var sunb := LevelKit.sphere(self, g + Vector3(0, 8.0, 1.6), 0.55, "sun_glow")
		sunb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	else:
		# the gate's own collision: everything of it either side of the arch,
		# its whole depth, so the way through stays open at the arch's 5.7 m
		var solid := GATE_WIDTH * 0.5 - half_arch
		for side in [-1.0, 1.0]:
			var body := StaticBody3D.new()
			var cs := CollisionShape3D.new()
			var sh := BoxShape3D.new()
			sh.size = Vector3(solid, 4.0, GATE_DEPTH)
			cs.shape = sh
			body.position = g + Vector3(side * (half_arch + solid * 0.5), 2.0, 0)
			body.add_child(cs)
			add_child(body)
	# the doors: two leaves, hinged at the arch's sides, closed across the way.
	# Gary's leaf (23 October, solhaven_gate_door.glb) is made to the arch at
	# its real size: 2.8 m wide, 5.0 m tall at its hinge edge rising to 7.07 m
	# where the two meet under the crown, its hinge straps at x = 0 and its
	# studded face +z (the road). It hangs as made, hinge edge on the hinge,
	# and the other leaf is its mirror.
	for side in [-1, 1]:
		var hinge := Node3D.new()
		hinge.position = g + Vector3(side * half_arch, 0, 0.2)
		add_child(hinge)
		var leaf := model("gate_door", hinge, Vector3.ZERO, 0.0, Vector3.ZERO if real != null else Vector3(0, leaf_h, 0), false)
		if leaf == null:
			var l := Node3D.new()
			hinge.add_child(l)
			LevelKit.box(l, Vector3(-side * leaf_w * 0.5, 0, 0), Vector3(leaf_w - 0.04, leaf_h, 0.35), "gold", false)
			for y in [1.2, 3.0, 4.8]:
				LevelKit.box(l, Vector3(-side * leaf_w * 0.5, y, 0.2), Vector3(leaf_w - 0.24, 0.18, 0.08), "bronze", false)
			var boss := LevelKit.sphere(l, Vector3(-side * leaf_w * 0.5, 3.0, 0.25), 0.22, "sun_glow")
			boss.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		else:
			# model() put the leaf's middle on the hinge: over by half its
			# width, so its hinge edge (the model's x = 0) is on the hinge
			var middle: float = -(leaf.get_child(0) as Node3D).position.x
			leaf.position.x = -side * middle
			if side > 0:
				leaf.scale.x = -1.0   # Gary's one leaf, mirrored for the other
		# a door that's shut is solid
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(leaf_w, leaf_h, 0.5)
		cs.shape = sh
		cs.position = Vector3(-side * leaf_w * 0.5, leaf_h * 0.5, 0)
		body.add_child(cs)
		hinge.add_child(body)
		gate_doors.append(hinge)
	# the city wall either side of the gate, from where its wings end
	for side in [-1, 1]:
		LevelKit.box(self, g + Vector3(side * (wing + 22.0), 0, 0), Vector3(44.0, 7.0, 2.0), "sandstone")
		for i in 4:
			var tx: float = side * (wing + 4.0 + i * 11.0)
			LevelKit.cylinder(self, g + Vector3(tx, 0, 0), 1.7, 9.5, "sandstone", false, 1.7, 14)
			LevelKit.cylinder(self, g + Vector3(tx, 9.5, 0), 1.9, 2.0, "roof_teal", false, 0.0, 14)


## Swings the Golden Gate's doors open (or shut) over `secs`.
func open_gate(open := true, secs := 2.5) -> void:
	var tw := create_tween().set_parallel(true)
	for i in gate_doors.size():
		var side := -1.0 if i == 0 else 1.0
		tw.tween_property(gate_doors[i], "rotation:y", (side * -1.75) if open else 0.0, secs).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for h in gate_doors:
		for b in (h as Node3D).get_children():
			if b is StaticBody3D:
				(b as StaticBody3D).process_mode = Node.PROCESS_MODE_DISABLED if open else Node.PROCESS_MODE_INHERIT
	await tw.finished


func gate_is_open() -> bool:
	return gate_doors.size() > 0 and absf((gate_doors[0] as Node3D).rotation.y) > 0.5


## The road outside the gate: refugees' carts, bundles, sacks, children asleep
## on them (Ashford's props), and the field where the wagon stands at night.
func _build_road() -> void:
	LevelKit.box(self, Vector3(0, -0.19, 58), Vector3(8, 0.24, 64), "flagstone", false)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1171
	var dressing := [
		["hay_cart", Vector3(-7.5, 0, 33.0), 70.0], ["sacks", Vector3(-5.6, 0, 30.2), 10.0],
		["crate", Vector3(-6.4, 0, 36.8), -20.0], ["sacks", Vector3(5.8, 0, 31.4), 160.0],
		["hay_cart", Vector3(8.0, 0, 41.0), -100.0], ["crate", Vector3(5.6, 0, 38.0), 30.0],
		["sacks", Vector3(-6.0, 0, 44.0), 80.0], ["crate", Vector3(6.2, 0, 47.0), 12.0],
		["sacks", Vector3(-5.2, 0, 52.0), -40.0], ["hay_cart", Vector3(-8.2, 0, 56.0), 95.0],
	]
	for d in dressing:
		_ashford_prop(String(d[0]), d[1], float(d[2]))
	# bundles and bedrolls along the verge
	for i in 18:
		var side := -1.0 if i % 2 == 0 else 1.0
		var p := Vector3(side * rng.randf_range(4.6, 7.6), 0, 28.5 + i * 1.6 + rng.randf_range(-0.4, 0.4))
		var b := LevelKit.box(self, p, Vector3(rng.randf_range(0.5, 0.9), rng.randf_range(0.25, 0.45), rng.randf_range(0.4, 0.7)), "cloth_white" if i % 3 == 0 else "wood", false, rng.randf_range(0, 180))
		b.material_override = _mat(Color.from_hsv(rng.randf_range(0.05, 0.12), rng.randf_range(0.2, 0.45), rng.randf_range(0.35, 0.65)), 0.95)
	# the Circle on the road, where the Watch tests whoever comes ("Circle's there")
	var circ := (SPOTS.road as Vector3) + Vector3(0, 0, -2.6)
	LevelKit.cylinder(self, circ, 3.3, 0.08, "marble", false, 3.3, 40)
	var rr := LevelKit.torus(self, circ + Vector3(0, 0.1, 0), 2.85, 3.0, "ring_glow")
	rr.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# a few cold campfires
	for p in [Vector3(-6.6, 0, 40.0), Vector3(6.8, 0, 50.0), Vector3(-6.8, 0, 60.0)]:
		for i in 7:
			var a := TAU * i / 7.0
			LevelKit.sphere(self, p + Vector3(cos(a) * 0.45, 0.08, sin(a) * 0.45), 0.13, "rock", 0.7)
		var ash := LevelKit.cylinder(self, p, 0.32, 0.04, "dark_wood", false, 0.32, 10)
		ash.material_override = _mat(Color(0.12, 0.1, 0.09), 1.0)
	# the field beside the road, where the wagon stands at night: a fire for Bram
	var f := SPOTS.field as Vector3
	_omni(self, f + Vector3(-2.6, 0.6, 2.4), Color(1.0, 0.55, 0.25), 0.0, 7.0, lights_night)


## Ashford's carts, sacks and crates, as they are (from assets/models/ashford).
func _ashford_prop(id: String, pos: Vector3, yaw: float, parent: Node3D = null) -> void:
	var into: Node3D = parent if parent != null else self
	var path := "res://assets/models/ashford/%s.glb" % id
	if ResourceLoader.exists(path):
		var root := Node3D.new()
		root.position = pos
		root.rotation.y = deg_to_rad(yaw)
		into.add_child(root)
		var inst: Node3D = (load(path) as PackedScene).instantiate()
		root.add_child(inst)
		for mi: MeshInstance3D in inst.find_children("*", "MeshInstance3D", true, false):
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		return
	match id:
		"crate":
			LevelKit.crate(into, pos, 0.8, yaw)
		"sacks":
			LevelKit.sphere(into, pos + Vector3(0, 0.35, 0), 0.42, "cloth_white", 0.9)
		_:
			LevelKit.box(into, pos + Vector3(0, 0.5, 0), Vector3(1.8, 0.6, 3.2), "wood", true, yaw)


## The town houses round the square, down the lane and in the old quarter:
## Gary's house_a, house_b and house_c by turns, or the drawn ones.
func _build_houses() -> void:
	var houses := [
		# west side of the square
		[Vector3(-20, 0, -12), Vector3(7, 7.5, 8), 90.0, "a"], [Vector3(-20, 0, -2), Vector3(7, 6.0, 8), 90.0, "b"],
		[Vector3(-20, 0, 9), Vector3(8, 6.5, 8), 90.0, "c"], [Vector3(-27, 0, 0), Vector3(8, 9.0, 12), 90.0, "a"],
		[Vector3(-20, 0, 19), Vector3(7, 6.0, 7), 90.0, "b"],
		# east side: the inn (the Gilded Hearth) and the houses behind the stable yard
		[Vector3(19.5, 0, -1), Vector3(9, 7.0, 8), -90.0, "a"], [Vector3(19.5, 0, -12), Vector3(7, 8.0, 8), -90.0, "c"],
		[Vector3(19.5, 0, 8.5), Vector3(7, 6.0, 7), -90.0, "b"], [Vector3(27, 0, -4), Vector3(8, 10.0, 14), -90.0, "a"],
		[Vector3(19.5, 0, 20.5), Vector3(7, 6.5, 6), -90.0, "c"],
	]
	for h in houses:
		_house(h[0], h[1], float(h[2]), String(h[3]))
	LevelKit.box(self, Vector3(14.9, 2.8, -1), Vector3(0.1, 1.0, 2.6), "dark_wood", false)   # the inn's sign


func _house(pos: Vector3, size: Vector3, yaw: float, which: String) -> void:
	if model("house_" + which, self, pos, yaw, Vector3(0, size.y * 1.35, 0)) == null:
		var roofs := {"a": "roof_terracotta", "b": "roof_teal", "c": "roof_terracotta"}
		LevelKit.house(self, pos, size, "sandstone" if which == "a" else "plaster", roofs[which], yaw)


func _build_market() -> void:
	var s := SPOTS.stall as Vector3
	if model("card_stall", self, s, -90, Vector3(0, 2.9, 0)) == null:
		LevelKit.stall(self, s, -90, "awning_blue")
		# Tamsin's caches: little sealed boxes on the counter
		for i in 5:
			var c := LevelKit.box(self, s + Vector3(0.1, 1.0, -1.0 + i * 0.5), Vector3(0.3, 0.22, 0.3), "dark_wood", false, 8.0 * i)
			c.material_override = _mat(Color.from_hsv(0.08 + i * 0.12, 0.5, 0.55), 0.6)
		LevelKit.box(self, s + Vector3(-0.2, 2.55, 0), Vector3(0.08, 0.5, 2.4), "dark_wood", false)
		var sign := Label3D.new()
		sign.text = "SIGIL CACHES"
		sign.font_size = 64
		sign.pixel_size = 0.004
		sign.modulate = Color("f2c96b")
		sign.outline_size = 10
		sign.position = s + Vector3(-0.26, 2.8, 0)
		sign.rotation.y = deg_to_rad(-90)
		add_child(sign)
	LevelKit.stall(self, s + Vector3(0, 0, 5.0), -90, "awning_red")
	LevelKit.crate(self, s + Vector3(1.6, 0, 7.6), 0.8, 12)
	LevelKit.crate(self, s + Vector3(1.9, 0, 8.4), 0.6, -20)
	LevelKit.barrel(self, s + Vector3(0.8, 0, -4.8))
	LevelKit.barrel(self, s + Vector3(1.6, 0, -4.2))


## Bram's wagon in the stable yard: a battered wagon with a lamp hook, the
## Crooked Lantern's lamp (unlit until Bram hangs and lights it), and Turnip,
## a grey mule with one ear that won't stand up. All one node, so the whole
## household can be moved to the field at night.
func _build_wagon(at: Vector3) -> void:
	wagon = Node3D.new()
	wagon.name = "Wagon"
	wagon.position = at
	add_child(wagon)
	# Gary's wagon (23 October, covered_wagon.glb) at its real size: 2.6 m
	# wide, 2.8 m to the top of the canvas, the bed 4 m long with a tailboard
	# and a seat, and its shafts down on the ground 2 m beyond the front. It
	# faces +z as made; the set's wagon has its shafts and Turnip at -z and
	# its tail at +z, so it stands turned about. model() centres the whole of
	# it, shafts and all, on the mark; the mark should be the middle of the
	# bed (the model's own origin), where the stand-in's was, so it's moved
	# back by what model() moved it.
	var real := model("wagon", wagon, Vector3.ZERO, 180.0, Vector3.ZERO, false)
	if real != null:
		var inst := real.get_child(0) as Node3D
		var back: Vector3 = -(real.transform.basis * inst.position)
		real.position = Vector3(back.x, 0, back.z)
		# solid where the bed and the wheels are (not out along the shafts,
		# where Turnip stands)
		var solid := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(2.7, 2.5, 4.1)
		cs.shape = sh
		cs.position = Vector3(0, 1.25, 0)
		solid.add_child(cs)
		wagon.add_child(solid)
	else:
		LevelKit.box(wagon, Vector3(0, 0.75, 0), Vector3(2.0, 0.2, 3.6), "dark_wood", true)       # bed
		LevelKit.box(wagon, Vector3(-0.95, 1.2, 0), Vector3(0.1, 0.7, 3.6), "wood", false)         # sides
		LevelKit.box(wagon, Vector3(0.95, 1.2, 0), Vector3(0.1, 0.7, 3.6), "wood", false)
		LevelKit.box(wagon, Vector3(0, 1.2, -1.75), Vector3(2.0, 0.7, 0.1), "wood", false)
		LevelKit.box(wagon, Vector3(0, 1.0, 1.75), Vector3(2.0, 0.35, 0.1), "wood", false)          # the tailboard
		var hoop := LevelKit.box(wagon, Vector3(0, 2.3, -0.4), Vector3(2.3, 0.12, 2.6), "cloth_white", false)
		hoop.material_override = _mat(Color("d9cfb8"), 0.95)
		for s in [-1, 1]:
			for z in [-1.1, 1.1]:
				var wh := LevelKit.cylinder(wagon, Vector3.ZERO, 0.55, 0.16, "dark_wood", false, -1.0, 16)
				wh.position = Vector3(s * 1.1, 0.55, z)
				wh.rotation.z = PI * 0.5
		LevelKit.box(wagon, Vector3(0, 0.5, -2.9), Vector3(0.14, 0.14, 2.4), "wood", false)         # the shafts, forward
	# the lamp hook at the back corner (on the tailboard's rail, on Gary's
	# wagon), and the lamp (dark until it's lit)
	var hook := Vector3(0.85, 1.14, 2.15) if real != null else Vector3(0.9, 1.6, 1.9)
	LevelKit.cylinder(wagon, hook, 0.03, 0.9, "bronze", false, -1.0, 8)
	LevelKit.box(wagon, hook + Vector3(0, 0.85, -0.15), Vector3(0.04, 0.04, 0.32), "bronze", false)
	wagon_glow = LevelKit.sphere(wagon, hook + Vector3(0, 0.6, -0.3), 0.16, "lamp_glow")
	wagon_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	wagon_glow.visible = false
	wagon_lamp = OmniLight3D.new()
	wagon_lamp.position = hook + Vector3(0, 0.6, -0.3)
	wagon_lamp.light_color = Color("ffc67a")
	wagon_lamp.light_energy = 1.0
	wagon_lamp.omni_range = 6.0
	wagon_lamp.visible = false
	wagon.add_child(wagon_lamp)
	# Turnip, in the shafts (which lie on the ground either side of him)
	turnip = Node3D.new()
	turnip.name = "Turnip"
	turnip.position = Vector3(0.0, 0, -3.6 if real != null else -4.4)
	turnip.rotation.y = PI
	wagon.add_child(turnip)
	var mule_path := "res://assets/models/characters/turnip.glb"
	if ResourceLoader.exists(mule_path):
		var inst: Node3D = (load(mule_path) as PackedScene).instantiate()
		turnip.add_child(inst)
		var box := AABB()
		var first := true
		for mi: MeshInstance3D in inst.find_children("*", "MeshInstance3D", true, false):
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			var b := mi.get_aabb()
			box = b if first else box.merge(b)
			first = false
		if not first and box.size.y > 0.001:
			inst.scale = Vector3.ONE * (1.45 / box.size.y)   # a mule, about 1.45 m to the ears
		turnip_anim = inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if turnip_anim != null and turnip_anim.has_animation("idle"):
			turnip_anim.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
			turnip_anim.play("idle")
	else:
		var grey := _mat(Color(0.52, 0.5, 0.48), 0.95)
		var body := LevelKit.box(turnip, Vector3(0, 0.7, 0), Vector3(0.62, 0.62, 1.4), "rock", false)
		body.material_override = grey
		for p in [[Vector3(0, 1.1, 0.78), Vector3(0.34, 0.46, 0.44)], [Vector3(0, 1.38, 1.12), Vector3(0.32, 0.3, 0.56)]]:
			var b := LevelKit.box(turnip, p[0], p[1], "rock", false)
			b.material_override = grey
		var ear_up := LevelKit.box(turnip, Vector3(-0.1, 1.66, 1.0), Vector3(0.07, 0.34, 0.09), "rock", false)
		ear_up.material_override = grey
		var ear := LevelKit.box(turnip, Vector3(0.14, 1.62, 1.0), Vector3(0.07, 0.34, 0.09), "rock", false)
		ear.material_override = grey
		ear.rotation.z = -1.15                       # the ear that won't stand up
		for s in [-1, 1]:
			for z in [-0.45, 0.45]:
				var leg := LevelKit.box(turnip, Vector3(s * 0.2, 0.0, z), Vector3(0.13, 0.5, 0.13), "rock", false)
				leg.material_override = grey
		var tail := LevelKit.box(turnip, Vector3(0, 0.75, -0.78), Vector3(0.06, 0.45, 0.06), "dark_wood", false)
		tail.rotation.x = 0.4


## Bram hangs the lamp on its hook and lights it.
func light_wagon_lamp(on := true) -> void:
	wagon_glow.visible = on
	wagon_lamp.visible = on


## Where Bram sits on the wagon's tailboard (the campfire film), wagon-local:
## x and z the spot, y the height of the board. Gary's wagon has a let-down
## tailboard at the back of its bed; the stand-in's was a tailgate.
func tailboard() -> Vector3:
	return Vector3(0, 1.12, 2.2) if has_model("wagon") else Vector3(0, 0.95, 2.65)


## Moves the wagon (and Turnip) to the field outside the walls, or back.
func wagon_to(spot: String) -> void:
	wagon.position = SPOTS[spot]
	wagon.rotation.y = deg_to_rad(-35.0) if spot == "field" else 0.0


## Turnip's head-dip: the bite. Not hard.
func turnip_bite() -> void:
	if turnip_anim != null:
		for c in ["bite", "head_dip", "eat", "attack"]:
			if turnip_anim.has_animation(c):
				turnip_anim.play(c, 0.15)
				await get_tree().create_timer(turnip_anim.get_animation(c).length, false).timeout
				if turnip_anim.has_animation("idle"):
					turnip_anim.play("idle", 0.2)
				return
	var tw := create_tween()
	tw.tween_property(turnip, "rotation:x", 0.35, 0.18)
	tw.tween_property(turnip, "rotation:x", 0.0, 0.3)
	await tw.finished


## The notice board: the Seat roll in gold leaf, and underneath, in fresh black
## ink, the player's name (the game writes the names; the parchment is blank).
func _build_board() -> void:
	var b := SPOTS.board as Vector3
	if model("notice_board", self, b, 90, Vector3(0, 2.6, 0)) == null:
		for z in [-1.1, 1.1]:
			LevelKit.cylinder(self, b + Vector3(0, 0, z), 0.08, 2.6, "dark_wood", true, -1.0, 8)
		LevelKit.box(self, b + Vector3(0, 0.9, 0), Vector3(0.12, 1.5, 2.4), "dark_wood", false)
		LevelKit.gable(self, b + Vector3(0, 2.6, 0), 0.6, 2.7, 0.35, "roof_teal", 90)
		var paper := LevelKit.box(self, b + Vector3(0.07, 1.0, 0), Vector3(0.02, 1.3, 2.1), "cloth_white", false)
		paper.material_override = _mat(Color("efe2c2"), 0.95)
	board_label = Label3D.new()
	board_label.font_size = 40
	board_label.pixel_size = 0.0028
	board_label.modulate = Color(0.75, 0.55, 0.18)
	board_label.outline_size = 0
	board_label.position = b + Vector3(0.1, 1.68, 0)
	board_label.rotation.y = deg_to_rad(90)
	board_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	board_label.width = 700
	board_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(board_label)
	write_board()


## The roll: seven kingdoms and the Champion who holds each, and the player
## added at the bottom once Chapter 1 has begun.
func write_board() -> void:
	var lines := ["THE SEAT ROLL", ""]
	var seats := [["Solhaven", "Ser Aldric Vane"], ["Pyreholt", "Warlord Vorn"], ["Hrimmark", "King Eiran"],
		["Stormreach", "Captain Rook"], ["Somnara", "Sister Maelis"], ["Glyphmere", "Magister Tobias Crane"], ["Umbravel", "Silk"]]
	for s in seats:
		lines.append("%s · %s" % s)
	board_label.text = "\n".join(lines)
	board_label.text += "\n\n%s, the Unsworn, challenger" % Game.player_name


# ================================================================ the Sunspire ===

## A tower crowned with a great mirror that throws the sun across the city;
## its roof is the great duelling circle. The mirror hangs from its frame on
## chains, so it can swing to Aldric's side at half Life.
func _build_spire() -> void:
	var s := SPOTS.spire as Vector3
	var top := s + Vector3(0, ROOF_Y, 0)
	if model("sunspire", self, s, 0, Vector3(0, ROOF_Y, 0)) == null:
		LevelKit.cylinder(self, s, 6.5, 6.0, "marble", true, 6.0, 32)
		LevelKit.cylinder(self, s + Vector3(0, 6.0, 0), 5.6, ROOF_Y - 8.0, "marble", true, 4.6, 32)
		for i in 5:
			var y := 9.0 + i * 6.5
			LevelKit.torus(self, s + Vector3(0, y, 0), 5.0 - i * 0.18, 5.4 - i * 0.18, "gold")
		# windows climbing the spiral stair
		for i in 12:
			var a := TAU * i / 5.0
			var y := 7.0 + i * 2.7
			var r := 5.5 - y * 0.022
			var w := LevelKit.box(self, s + Vector3(cos(a) * r, y, sin(a) * r), Vector3(0.5, 1.2, 0.5), "dark_wood", false)
			w.rotation.y = -a
		# the crown flares out to carry the roof
		LevelKit.cylinder(self, s + Vector3(0, ROOF_Y - 2.0, 0), 4.6, 2.0, "marble", false, 14.0, 40)
	if model("sunspire_roof", self, top, 0, Vector3(30.0, 0, 0), false) == null:
		LevelKit.cylinder(self, top, 14.0, 0.5, "marble", true, 14.0, 48)
		var ring := LevelKit.torus(self, top + Vector3(0, 0.55, 0), 4.3, 4.55, "ring_glow")
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		LevelKit.cylinder(self, top + Vector3(0, 0.5, 0), 4.8, 0.06, "sandstone", false, 4.8, 40)
		# the stands: three tiers of stone benches round the circle, each higher
		# than the last; a gap east for the way up from the stair, and the
		# Hierarch's box on the north side
		for tier in 3:
			var r := 7.0 + tier * 2.0
			var h := 0.45 + tier * 0.9
			for i in 28:
				var a := TAU * i / 28.0
				if a < PI * 0.22 or a > PI * 1.78:
					continue   # the way in from the stair
				if a > PI * 1.36 and a < PI * 1.64:
					continue   # the Hierarch's box
				var seat := LevelKit.box(self, top + Vector3(cos(a) * r, 0.5, sin(a) * r), Vector3(2.1, h, 1.4), "sandstone", false)
				seat.rotation.y = -a + PI * 0.5
				if i % 2 == 0:
					var spot := top + Vector3(cos(a) * r, 0.5 + h, sin(a) * r)
					if tier == 2:
						cheap_seat_spots.append(spot)
					else:
						roof_crowd_spots.append(spot)
		# the Hierarch's shaded box, with an awning
		var bx := top + Vector3(0, 0.5, -10.4)
		LevelKit.box(self, bx, Vector3(4.4, 1.2, 2.4), "marble", false)
		LevelKit.box(self, bx + Vector3(0, 3.6, 0), Vector3(4.8, 0.15, 2.8), "cloth_white", false)
		for x in [-2.1, 2.1]:
			LevelKit.cylinder(self, bx + Vector3(x, 1.2, 1.1), 0.08, 2.4, "gold", false, -1.0, 8)
		# a parapet round the edge
		LevelKit.torus(self, top + Vector3(0, 1.0, 0), 13.6, 14.1, "marble")
	# the great mirror: its frame over the circle, and the glass hung on chains
	var frame_h := 16.0
	for x in [-8.0, 8.0]:
		LevelKit.cylinder(self, top + Vector3(x, 0.5, 9.0), 0.4, frame_h, "gold", false, 0.3, 12)
	LevelKit.box(self, top + Vector3(0, frame_h + 0.3, 9.0), Vector3(17.0, 0.6, 0.6), "gold", false)
	sun_mirror = Node3D.new()
	sun_mirror.name = "SunMirror"
	sun_mirror.position = top + Vector3(0, frame_h + 0.3, 9.0)
	add_child(sun_mirror)
	if model("sun_mirror", sun_mirror, Vector3(0, -12.5, 0), 180, Vector3(0, 11.0, 0), false) == null:
		for x in [-4.6, 4.6]:
			var ch := LevelKit.cylinder(sun_mirror, Vector3(x, -3.0, 0), 0.06, 3.0, "bronze", false, -1.0, 6)
			ch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var disc := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 5.4
		cm.bottom_radius = 5.4
		cm.height = 0.3
		cm.radial_segments = 48
		disc.mesh = cm
		disc.material_override = _mat(Color(0.95, 0.92, 0.85), 0.04, 1.0)
		disc.rotation.x = PI * 0.5
		disc.position = Vector3(0, -8.6, 0)
		sun_mirror.add_child(disc)
		var rim := LevelKit.torus(sun_mirror, Vector3(0, -8.6, 0), 5.3, 5.8, "gold")
		rim.rotation.x = PI * 0.5
		var shine := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 1.4
		sm.height = 2.8
		shine.mesh = sm
		shine.material_override = _glow_mat(Color(1.0, 0.95, 0.75), 3.0, 0.5)
		shine.position = Vector3(0, -8.6, -0.3)
		shine.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sun_mirror.add_child(shine)
	# the Sunspire's door, in the west wall of the square
	var d := SPOTS.spire_door as Vector3
	LevelKit.box(self, d + Vector3(-1.0, 0, -2.2), Vector3(1.4, 5.2, 1.0), "marble")
	LevelKit.box(self, d + Vector3(-1.0, 0, 2.2), Vector3(1.4, 5.2, 1.0), "marble")
	LevelKit.box(self, d + Vector3(-1.0, 5.2, 0), Vector3(1.6, 1.0, 5.4), "marble", false)
	LevelKit.box(self, d + Vector3(-1.45, 0, 0), Vector3(0.2, 4.4, 3.4), "gold", false)
	LevelKit.banner(self, d + Vector3(-0.35, 4.9, 0), 90, "radiant")


## The great mirror swings on its chains: 0 hangs it over the middle, 1 puts
## the sun on Aldric's side of the circle.
func swing_mirror(to: float, secs := 2.0) -> void:
	var tw := create_tween()
	tw.tween_property(sun_mirror, "rotation:x", -0.32 * to, secs).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(sun_mirror, "rotation:y", 0.25 * to, secs).set_trans(Tween.TRANS_SINE)
	await tw.finished


# ================================================================ the lane ===

## East of the market: a lane between tall houses, washing strung across it,
## crates and a cart in the way, and at the end a turn into a dead-end alley.
## Each obstacle has a glowing ledge the chase asks for a tap on.
func _build_lane() -> void:
	var z := 13.6
	# houses both sides of the lane, and down the alley
	var i := 0
	for x in range(22, 58, 7):
		_house(Vector3(x, 0, z - 5.6), Vector3(6, 7.0 + (i % 3), 6), 0.0, ["a", "b", "c"][i % 3])
		_house(Vector3(x + 3, 0, z + 5.8), Vector3(6, 6.0 + (i % 2), 6), 180.0, ["c", "a", "b"][i % 3])
		i += 1
	for zz in [8.0, 0.0, -7.0]:
		_house(Vector3(65.5, 0, zz), Vector3(6, 7.5, 7), -90.0, "c")
	_house(Vector3(54.5, 0, -2.0), Vector3(6, 7.0, 12), 90.0, "b")
	LevelKit.box(self, Vector3(60, 0, -11.5), Vector3(10.0, 6.0, 1.0), "sandstone")    # the dead end
	LevelKit.box(self, Vector3(40, -0.19, z), Vector3(46, 0.24, 4.4), "cobble", false)
	LevelKit.box(self, Vector3(60, -0.18, 2.0), Vector3(5.0, 0.24, 26.0), "cobble", false)
	for o in CHASE:
		var n := Node3D.new()
		n.position = o.at
		add_child(n)
		match String(o.what):
			"crates":
				LevelKit.crate(n, Vector3(-0.3, 0, -0.9), 1.0, 10)
				LevelKit.crate(n, Vector3(0.2, 0, 0.2), 1.1, -8)
				LevelKit.crate(n, Vector3(0.1, 0, 1.2), 0.9, 20)
			"washing":
				for zz in [-2.3, 2.3]:
					LevelKit.cylinder(n, Vector3(0, 0, zz), 0.06, 3.4, "dark_wood", false, -1.0, 6)
				LevelKit.box(n, Vector3(0, 1.5, 0), Vector3(0.03, 0.03, 4.6), "dark_wood", false)
				for k in 5:
					var sheet := LevelKit.box(n, Vector3(0, 0.75, -1.8 + k * 0.9), Vector3(0.02, 0.85, 0.75), "cloth_white", false)
					sheet.material_override = _mat(Color.from_hsv(0.08 * k, 0.25, 0.9), 0.9)
			"cart":
				_ashford_prop("hay_cart", Vector3.ZERO, 90.0, n)
			"ledge":
				LevelKit.box(n, Vector3(0, 0, 0), Vector3(1.2, 1.1, 4.2), "sandstone")
			"arch":
				LevelKit.box(n, Vector3(0, 1.2, 0), Vector3(4.6, 0.6, 1.0), "sandstone", false)
				for xx in [-2.0, 2.0]:
					LevelKit.box(n, Vector3(xx, 0, 0), Vector3(0.6, 1.2, 1.0), "sandstone", false)
		# the glowing ledge
		var glow := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.5, 0.06, 3.6) if o.kind == "vault" else Vector3(3.6, 0.06, 0.5)
		glow.mesh = bm
		glow.material_override = _glow_mat(Color(1.0, 0.85, 0.4), 3.0, 0.85)
		glow.position = Vector3(0, 1.25 if o.kind == "vault" else 0.05, 0)
		if String(o.what) == "arch":
			glow.mesh = bm
			glow.position = Vector3(0, 1.15, 0)
			glow.rotation.y = PI * 0.5
		glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		glow.visible = false
		n.add_child(glow)
		n.set_meta("glow", glow)
		obstacles.append(n)


# ============================================================== the Sun Court ===

## A vast white hall under a sun-window. Light falls in a single gold column
## onto a lower throne beneath a towering statue of Solmaris. The doors are at
## SPOTS.court; the hall runs north from them to the throne.
func _build_court() -> void:
	var c := SPOTS.court as Vector3
	var root := Node3D.new()
	root.name = "SunCourt"
	root.position = c
	add_child(root)
	var throne_z := -30.0
	if model("sun_court", root, Vector3(0, 0, -16.0), 0, Vector3(0, 16.0, 0), false) == null:
		LevelKit.box(root, Vector3(0, -0.2, -16), Vector3(20, 0.24, 36), "marble", false)
		var aisle := LevelKit.box(root, Vector3(0, -0.17, -14), Vector3(3.4, 0.24, 30), "gold", false)
		aisle.material_override = _mat(Color(0.75, 0.2, 0.15), 0.9)           # a red runner up the aisle
		for side in [-1, 1]:
			LevelKit.box(root, Vector3(side * 10.0, 0, -16), Vector3(0.8, 16.0, 36), "marble", false)
			for i in 7:
				LevelKit.column(root, Vector3(side * 5.6, 0, -2.0 - i * 4.4), 12.0, 0.6)
				# tall windows high in the walls, glowing
				var w := LevelKit.box(root, Vector3(side * 9.55, 8.0, -3.0 - i * 4.4), Vector3(0.1, 4.0, 1.6), "lamp_glow", false)
				w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		LevelKit.box(root, Vector3(0, 0, 2.2), Vector3(20, 16.0, 0.8), "marble", false)        # the door wall
		LevelKit.box(root, Vector3(0, 0, -34.4), Vector3(20, 16.0, 0.8), "marble", false)      # the back wall
		LevelKit.box(root, Vector3(0, 16.0, -16), Vector3(20.8, 0.6, 37.6), "marble", false)   # the ceiling
		LevelKit.box(root, Vector3(0, 0, 1.75), Vector3(4.0, 6.5, 0.1), "gold", false)          # the doors, inside
		# the dais
		for i in 3:
			LevelKit.box(root, Vector3(0, i * 0.3, throne_z + 2.0 - i * 0.8), Vector3(9.0 - i * 1.6, 0.3, 5.0 - i * 1.4), "marble", false)
	if model("hierarch_throne", root, Vector3(0, 0.9, throne_z), 0, Vector3(0, 3.2, 0), false) == null:
		LevelKit.box(root, Vector3(0, 0.9, throne_z), Vector3(1.6, 0.6, 1.3), "gold", false)
		LevelKit.box(root, Vector3(0, 1.5, throne_z - 0.55), Vector3(1.6, 2.4, 0.25), "gold", false)
		var sb := LevelKit.cylinder(root, Vector3(0, 3.9, throne_z - 0.6), 0.9, 0.12, "gold", false, 0.9, 24)
		sb.rotation.x = PI * 0.5
	statue = model("solmaris_statue", root, Vector3(0, 0.9, throne_z - 3.2), 0, Vector3(0, 14.5, 0), false)
	if statue == null:
		statue = Node3D.new()
		statue.position = Vector3(0, 0.9, throne_z - 3.2)
		root.add_child(statue)
		# a robed figure in white stone, arms opening, a sun behind her head
		LevelKit.cylinder(statue, Vector3(0, 0, 0), 2.6, 8.5, "marble", false, 1.3, 20)
		LevelKit.cylinder(statue, Vector3(0, 8.5, 0), 1.3, 2.4, "marble", false, 1.5, 20)
		LevelKit.sphere(statue, Vector3(0, 11.4, 0.1), 0.95, "marble", 1.15)
		for s in [-1, 1]:
			var arm := LevelKit.cylinder(statue, Vector3(0, 0, 0), 0.38, 4.2, "marble", false, 0.3, 12)
			arm.position = Vector3(s * 2.2, 8.6, 0.6)
			arm.rotation = Vector3(0.5, 0, s * 0.95)
		var halo := LevelKit.torus(statue, Vector3(0, 11.6, -0.6), 1.9, 2.2, "gold")
		halo.rotation.x = PI * 0.5
	# the sun-window over the throne, and the column of gold light it lets fall
	court_window = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 2.6
	disc.bottom_radius = 2.6
	disc.height = 0.1
	disc.radial_segments = 40
	court_window.mesh = disc
	court_window.material_override = _glow_mat(Color(1.0, 0.92, 0.7), 4.0)
	court_window.position = Vector3(0, 15.65, throne_z + 1.0)
	court_window.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(court_window)
	shaft = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 2.5
	cm.bottom_radius = 3.2
	cm.height = 15.0
	cm.radial_segments = 32
	cm.cap_top = false
	cm.cap_bottom = false
	shaft.mesh = cm
	shaft.material_override = _glow_mat(Color(1.0, 0.82, 0.45), 0.6, 0.16)
	shaft.position = Vector3(0, 8.1, throne_z + 1.0)
	shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(shaft)
	var spot := SpotLight3D.new()
	spot.position = Vector3(0, 15.4, throne_z + 1.0)
	spot.rotation.x = -PI * 0.5
	spot.spot_angle = 16.0
	spot.spot_range = 20.0
	spot.light_color = Color(1.0, 0.86, 0.55)
	spot.light_energy = 9.0
	spot.shadow_enabled = quality >= 2
	root.add_child(spot)
	lights_court.append(spot)
	for z in [-4.0, -14.0, -24.0]:
		_omni(root, Vector3(0, 9.0, z), Color(1.0, 0.9, 0.72), 1.6, 16.0, lights_court)
	# Solmaris, leaning down out of the glare (only while time is stopped): a
	# tall figure of light before the statue, bent toward whoever stands below
	solmaris = Node3D.new()
	solmaris.name = "Solmaris"
	solmaris.position = Vector3(0, 0.9, throne_z - 1.0)
	solmaris.visible = false
	root.add_child(solmaris)
	var lean := Node3D.new()
	lean.rotation.x = 0.3
	solmaris.add_child(lean)
	var robe := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = 0.9
	rm.bottom_radius = 2.4
	rm.height = 7.6
	rm.radial_segments = 28
	robe.mesh = rm
	robe.position = Vector3(0, 3.8, 0)
	robe.material_override = _glow_mat(Color(1.0, 0.94, 0.8), 1.4, 0.3)
	robe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lean.add_child(robe)
	for side in [-1.0, 1.0]:
		# arms opening, palms down, toward you
		var arm := MeshInstance3D.new()
		var am := CapsuleMesh.new()
		am.radius = 0.32
		am.height = 4.2
		arm.mesh = am
		arm.position = Vector3(side * 1.6, 6.0, 0.9)
		arm.rotation = Vector3(0.9, 0, side * 0.75)
		arm.material_override = _glow_mat(Color(1.0, 0.94, 0.82), 1.6, 0.35)
		arm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		lean.add_child(arm)
	var head := MeshInstance3D.new()
	var hsm := SphereMesh.new()
	hsm.radius = 0.75
	hsm.height = 1.8
	head.mesh = hsm
	head.position = Vector3(0, 8.4, 0.3)
	head.material_override = _glow_mat(Color(1.0, 0.97, 0.88), 4.0, 0.8)
	head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lean.add_child(head)
	var corona := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 1.25
	tm.outer_radius = 1.7
	corona.mesh = tm
	corona.material_override = _glow_mat(Color(1.0, 0.8, 0.4), 3.0, 0.5)
	corona.position = Vector3(0, 8.5, -0.25)
	corona.rotation.x = PI * 0.5
	corona.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lean.add_child(corona)
	var sl := OmniLight3D.new()
	sl.light_color = Color(1.0, 0.95, 0.85)
	sl.light_energy = 0.0
	sl.omni_range = 30.0
	sl.position = Vector3(0, 6, 3)
	solmaris.add_child(sl)
	solmaris.set_meta("light", sl)
	solmaris.set_meta("head", head)


## Where Solmaris's face is, while she leans down out of the glare.
func solmaris_face() -> Vector3:
	return (solmaris.get_meta("head") as Node3D).global_position


## The court in white: the sun-window blazes and Solmaris leans down out of
## the glare (1), or the light folds away (0).
func court_blaze(k: float, secs := 0.8) -> void:
	var sl: OmniLight3D = solmaris.get_meta("light")
	if k > 0.0:
		solmaris.visible = true
		solmaris.scale = Vector3.ONE * 0.85
	var tw := create_tween().set_parallel(true)
	tw.tween_property(sl, "light_energy", 6.0 * k, secs)
	tw.tween_property(solmaris, "scale", Vector3.ONE * (1.0 if k > 0.0 else 0.85), secs)
	# (the column of light thins as she takes its place, so she can be seen)
	tw.tween_property(shaft.material_override, "albedo_color:a", lerpf(0.16, 0.03, k), secs)
	tw.tween_property(court_window.material_override, "emission_energy_multiplier", 4.0 + 12.0 * k, secs)
	await tw.finished
	if k <= 0.0:
		solmaris.visible = false


# ========================================================= the Hall of Mirrors ===

## A round hall lined with tall mirrors round a duelling circle, candles
## everywhere. Each mirror is Gary's temple_mirror when it's in.
func _build_mirrors() -> void:
	var c := SPOTS.mirrors as Vector3
	var root := Node3D.new()
	root.name = "HallOfMirrors"
	root.position = c
	add_child(root)
	var r := 11.0
	if model("hall_of_mirrors", root, Vector3.ZERO, 0, Vector3(0, 13.0, 0), false) == null:
		LevelKit.cylinder(root, Vector3(0, -0.2, 0), 13.0, 0.24, "marble", false, 13.0, 48)
		LevelKit.cylinder(root, Vector3(0, 0, 0), 4.2, 0.12, "marble", false, 4.2, 48)
		var ring := LevelKit.torus(root, Vector3(0, 0.14, 0), 3.7, 3.85, "ring_glow")
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# the wall, in ten bays, and a low dome
		for i in 10:
			var a := TAU * i / 10.0
			var p := Vector3(cos(a), 0, sin(a)) * (r + 1.6)
			var wall := LevelKit.box(root, p, Vector3(7.4, 12.0, 0.8), "marble", false)
			wall.rotation.y = -a + PI * 0.5
			var col := Vector3(cos(a + TAU / 20.0), 0, sin(a + TAU / 20.0)) * (r + 0.6)
			LevelKit.column(root, col, 12.0, 0.45)
		var dome := LevelKit.dome(root, Vector3(0, 12.0, 0), 13.4, "marble")
		dome.scale.y = 0.45
		var oc := LevelKit.cylinder(root, Vector3(0, 17.6, 0), 1.6, 0.2, "lamp_glow", false, 1.6, 24)
		oc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# the mirrors, one in each bay but the door's
	for i in 10:
		if i == 2:
			continue   # the door, facing south
		var a := TAU * i / 10.0
		var p := Vector3(cos(a), 0, sin(a)) * r
		var m := Node3D.new()
		m.position = p
		m.rotation.y = -a - PI * 0.5
		root.add_child(m)
		var glass: MeshInstance3D
		if model("temple_mirror", m, Vector3.ZERO, 0, Vector3(0, 6.4, 0), false) == null:
			LevelKit.box(m, Vector3(0, 0, -0.1), Vector3(3.0, 6.6, 0.25), "gold", false)
			glass = MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(2.5, 5.9)
			glass.mesh = qm
			glass.position = Vector3(0, 3.35, 0.06)
			glass.material_override = _mat(Color(0.82, 0.86, 0.9), 0.03, 1.0)
			glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			m.add_child(glass)
		# what the mirror shows (a reflection, or the Demigod), drawn on a pale veil
		var show := MeshInstance3D.new()
		var sq := QuadMesh.new()
		sq.size = Vector2(2.4, 5.8)
		show.mesh = sq
		show.position = Vector3(0, 3.35, 0.09)
		show.material_override = _glow_mat(Color(1.0, 0.95, 0.8), 2.0, 0.0)
		show.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.add_child(show)
		m.set_meta("show", show)
		mirror_frames.append(m)
	# candles: on stands round the circle and in clusters at the mirrors' feet
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 46:
		var a := rng.randf() * TAU
		var d := rng.randf_range(5.0, r - 0.8)
		var p := Vector3(cos(a) * d, 0, sin(a) * d)
		if absf(a - TAU * 2.0 / 10.0) < 0.3 and d > 6.0:
			continue
		var h := rng.randf_range(0.2, 1.1)
		var cnd := LevelKit.cylinder(root, p, 0.05, h, "cloth_white", false, 0.05, 6)
		cnd.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var fl := LevelKit.sphere(root, p + Vector3(0, h + 0.06, 0), 0.04, "lamp_glow", 1.6)
		fl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		candles.append(fl)
	for i in 6:
		var a := TAU * i / 6.0 + 0.2
		_omni(root, Vector3(cos(a) * 6.5, 1.2, sin(a) * 6.5), Color(1.0, 0.7, 0.4), 1.1, 8.0, lights_mirrors)
	_omni(root, Vector3(0, 9.0, 0), Color(1.0, 0.85, 0.6), 0.8, 18.0, lights_mirrors)


## The mirrors light up: k from 0 (plain glass) to 1 (all showing the same
## bright thing, the Demigod or the player in white).
func mirrors_show(k: float, col := Color(1.0, 0.95, 0.8), secs := 0.6) -> void:
	var tw := create_tween().set_parallel(true)
	for m in mirror_frames:
		var show: MeshInstance3D = (m as Node3D).get_meta("show")
		(show.material_override as StandardMaterial3D).emission = col
		tw.tween_property(show.material_override, "albedo_color", Color(col, 0.65 * k), secs)
	await tw.finished


# ================================================================ Ironvault ===

## Morne's vault (the opening movie's shot 12b, seen whole): iron racks of
## glowing cards climbing into the dark, a ledger desk, a gold case with
## eight empty slots. Morne's desk is at SPOTS.vault; the racks go back north.
func _build_vault() -> void:
	var c := SPOTS.vault as Vector3
	var root := Node3D.new()
	root.name = "Ironvault"
	root.position = c
	add_child(root)
	if model("morne_vault", root, Vector3(0, 0, -6.0), 0, Vector3(0, 22.0, 0), false) == null:
		var fl := LevelKit.box(root, Vector3(0, -0.2, -6), Vector3(26, 0.24, 30), "flagstone", false)
		fl.material_override = _mat(Color(0.16, 0.15, 0.15), 0.4, 0.2)
		var iron := _mat(Color(0.12, 0.12, 0.14), 0.45, 0.85)
		for side in [-1, 1]:
			for i in 4:
				var rack := LevelKit.box(root, Vector3(side * (5.0 + i * 1.6), 0, -8.0 - i * 3.0), Vector3(0.4, 22.0, 9.0), "dark_wood", false)
				rack.material_override = iron
				for y in range(1, 22, 2):
					var shelf := LevelKit.box(root, Vector3(side * (5.0 + i * 1.6) - side * 0.4, y, -8.0 - i * 3.0), Vector3(0.8, 0.08, 9.0), "dark_wood", false)
					shelf.material_override = iron
		var back := LevelKit.box(root, Vector3(0, 0, -21), Vector3(26, 24, 0.6), "dark_wood", false)
		back.material_override = _mat(Color(0.06, 0.06, 0.07), 0.6, 0.5)
	# the glowing cards on the racks: one MultiMesh, cheap on a phone
	vault_cards = MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var q := QuadMesh.new()
	q.size = Vector2(0.24, 0.34)
	mm.mesh = q
	var n := 900 if quality >= 1 else 400
	mm.instance_count = n
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	for k in n:
		var side := -1.0 if k % 2 == 0 else 1.0
		var i := rng.randi_range(0, 3)
		var x := side * (5.0 + i * 1.6) - side * 0.55
		var p := Vector3(x, float(rng.randi_range(1, 10)) * 2.0 + 0.2, -8.0 - i * 3.0 + rng.randf_range(-4.2, 4.2))
		var t := Transform3D(Basis(Vector3.UP, side * PI * 0.5 - PI * 0.5 * side * 2.0 + rng.randf_range(-0.15, 0.15)), p)
		mm.set_instance_transform(k, t)
		mm.set_instance_color(k, Color.from_hsv(rng.randf_range(0.0, 1.0), 0.45, 1.0))
	vault_cards.multimesh = mm
	var cm := StandardMaterial3D.new()
	cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cm.vertex_color_use_as_albedo = true
	cm.cull_mode = BaseMaterial3D.CULL_DISABLED
	cm.albedo_color = Color(1.4, 1.4, 1.4)
	vault_cards.material_override = cm
	vault_cards.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(vault_cards)
	# the ledger desk, and the gold case with eight empty slots
	if model("morne_desk", root, Vector3(0, 0, 0), 180, Vector3(0, 1.0, 0)) == null:
		var wood := _mat(Color(0.18, 0.1, 0.06), 0.35)
		var top := LevelKit.box(root, Vector3(0, 0.95, 0), Vector3(2.8, 0.1, 1.3), "dark_wood")
		top.material_override = wood
		for x in [-1.2, 1.2]:
			var leg := LevelKit.box(root, Vector3(x, 0, 0), Vector3(0.3, 0.95, 1.1), "dark_wood", false)
			leg.material_override = wood
	var case_ := LevelKit.box(root, Vector3(-0.85, 1.05, -0.1), Vector3(0.9, 0.08, 0.6), "gold", false)
	case_.rotation.y = 0.15
	for s in 8:
		var slot := LevelKit.box(case_, Vector3(-0.33 + (s % 4) * 0.22, 0.05, -0.12 + int(s / 4.0) * 0.26), Vector3(0.16, 0.02, 0.22), "dark_wood", false)
		slot.position.y = 0.05
		slot.material_override = _mat(Color(0.05, 0.04, 0.03), 0.5)
	# the ledgers: today's, open; the old one comes down from the shelf
	for k in 2:
		var book := LevelKit.box(root, Vector3(0.35 + k * 0.6, 1.0, 0.1), Vector3(0.55, 0.05, 0.42), "cloth_white", false)
		book.material_override = _mat(Color(0.92, 0.88, 0.78), 0.9)
		book.visible = k == 0
		book.set_meta("ledger", k)
		root.set_meta("ledger_%d" % k, book)
	ledger_label = Label3D.new()
	ledger_label.text = ""
	ledger_label.font_size = 28
	ledger_label.pixel_size = 0.0016
	ledger_label.modulate = Color(0.12, 0.08, 0.05)
	ledger_label.outline_size = 0
	ledger_label.position = Vector3(0.95, 1.06, 0.1)
	ledger_label.rotation = Vector3(-PI * 0.5, PI, 0)
	ledger_label.width = 340
	ledger_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(ledger_label)
	_omni(root, Vector3(0.3, 2.2, 0.8), Color(1.0, 0.75, 0.45), 2.4, 6.0, lights_vault, true)
	_omni(root, Vector3(0, 8.0, -10.0), Color(0.6, 0.7, 1.0), 0.8, 22.0, lights_vault)


func old_ledger(on: bool) -> void:
	var root := get_node("Ironvault")
	(root.get_meta("ledger_1") as Node3D).visible = on


# =============================================================== backdrop ===

func _build_backdrop() -> void:
	# the city wall north beyond the temple, the old quarter's roofs, hills
	LevelKit.box(self, Vector3(0, 0, -48), Vector3(100, 7, 2), "sandstone", false)
	for i in 9:
		var x := -40.0 + i * 10.0
		LevelKit.cylinder(self, Vector3(x, 0, -48), 1.8, 10.5, "sandstone", false, 1.8, 12)
		LevelKit.cylinder(self, Vector3(x, 10.5, -48), 2.0, 2.2, "roof_teal", false, 0.0, 12)
	for x in [-30.0, 28.0, 40.0]:
		LevelKit.dome(self, Vector3(x, 8.0, -40.0), 4.0, "gold")
		LevelKit.cylinder(self, Vector3(x, 0, -40.0), 4.0, 8.0, "marble", false, 4.0, 24)
	for h in [[-38, -80, 22], [-5, -90, 28], [30, -82, 24], [55, -70, 18], [-60, -68, 20], [-90, 10, 26], [90, 20, 26]]:
		var hill := LevelKit.sphere(self, Vector3(h[0], -h[2] * 0.55, h[1]), h[2], "hill", 0.6)
		hill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# ================================================================ the marker ===

## A soft pillar of light over where the story goes next (the temple's doors,
## the Sunspire's), so it can be found from anywhere in the square.
func _build_marker() -> void:
	marker = Node3D.new()
	marker.name = "Marker"
	marker.visible = false
	add_child(marker)
	var p := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.5
	cm.bottom_radius = 0.9
	cm.height = 9.0
	cm.cap_top = false
	cm.cap_bottom = false
	p.mesh = cm
	p.material_override = _glow_mat(Color(1.0, 0.85, 0.45), 1.2, 0.18)
	p.position.y = 4.5
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	marker.add_child(p)
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 1.0
	tm.outer_radius = 1.2
	ring.mesh = tm
	ring.material_override = _glow_mat(Color(1.0, 0.85, 0.45), 3.0, 0.8)
	ring.position.y = 0.06
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	marker.add_child(ring)


func mark(spot: String) -> void:
	if spot == "" or not SPOTS.has(spot):
		marker.visible = false
		return
	marker.position = SPOTS[spot]
	marker.visible = true


func _process(delta: float) -> void:
	if marker != null and marker.visible:
		marker.rotation.y += delta * 0.6
		var k := 0.85 + 0.15 * sin(Time.get_ticks_msec() * 0.003)
		marker.scale = Vector3(k, 1.0, k)
