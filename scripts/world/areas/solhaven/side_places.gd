extends RefCounted
## The places Solhaven's side stories go to (Master Script v3, Side Quests):
## Ysa's camp outside the walls, Brother Anselm's room under the dyers'
## bridge, the Great Sundial's oldest steps at dawn and the barracks yard;
## and what marks them in the Sun Square itself (a Great Sundial in the
## temple square, the barracks gateway, the counting-house steps).
##
## Each place loads Gary's model by the name in "Solhaven: Your Step-by-Step"
## (assets/models/solhaven/<name>.glb: anselm_room, shrine_lantern,
## sundial_steps, barracks_yard; the camp uses wagon and Ashford's sacks) the
## moment it exists, fitted to the place's size, and is a drawn stand-in
## until then. The places are built far off the square, each on its own
## ground, the first time a story needs one: build(world, place) returns it,
## spot(place, mark) gives a spot in it.

const MODELS := "res://assets/models/solhaven/%s.glb"
const SACKS := "res://assets/models/ashford/sacks.glb"

## Where each place is built (far from the square and from each other).
const ORIGIN := {
	"camp": Vector3(320, 0, 0),
	"anselm": Vector3(0, 0, 320),
	"sundial": Vector3(-320, 0, 0),
	"barracks": Vector3(0, 0, -320),
}

## Spots in each place, from its origin. The camera looks in from +z.
const MARKS := {
	"camp": {
		"ysa": Vector3(0.2, 0, -0.2), "tobin": Vector3(-1.2, 0, 0.3), "healer": Vector3(1.0, 0, -1.4),
		"player": Vector3(1.9, 0, 0.5), "healer_off": Vector3(9.0, 0, 6.0),
		"ref_a": Vector3(-4.4, 0, -1.4), "ref_b": Vector3(4.6, 0, -2.6), "ref_c": Vector3(-2.6, 0, -5.2),
	},
	"anselm": {
		"anselm": Vector3(-0.5, 0, -2.3), "docker": Vector3(-1.6, 0, -1.7), "player": Vector3(1.2, 0, -0.4),
		"ysa": Vector3(2.0, 0, -2.9), "tobin": Vector3(0.9, 0.26, -3.9), "shrine": Vector3(3.0, 0, -4.7),
		"lantern": Vector3(3.0, 1.62, -4.75), "stair_top": Vector3(-3.2, 2.8, -4.9),
		"sergeant": Vector3(-2.2, 0, -1.2), "guard_a": Vector3(-3.0, 0, -2.4), "guard_b": Vector3(-3.2, 0.7, -3.2),
	},
	"sundial": {
		"player": Vector3(-0.7, 0, 8.6), "lines": Vector3(0, 0.3, 7.25), "corvin_top": Vector3(0.8, 0.95, 4.4),
		"corvin": Vector3(0.9, 0, 8.5),
	},
	"barracks": {
		"hale": Vector3(0.2, 0, -0.6), "post": Vector3(0, 0, -1.5), "captain": Vector3(-2.6, 0, 0.6),
		"player": Vector3(1.8, 0, 3.2), "guard_a": Vector3(-5.6, 0, -3.8), "guard_b": Vector3(-4.3, 0, -4.1),
		"guard_c": Vector3(4.3, 0, -4.1), "guard_d": Vector3(5.6, 0, -3.8), "watch_a": Vector3(-0.8, 0, 3.0),
		"watch_b": Vector3(3.2, 0, 2.7), "crowd_a": Vector3(-0.9, 0, -8.2), "crowd_b": Vector3(0.6, 0, -8.6),
		"crowd_c": Vector3(1.8, 0, -8.1),
	},
}

## In the Sun Square: the Great Sundial (temple square), the barracks
## gateway (west) and the counting-house steps (east), and where to stand
## to use each.
const HUB := {
	"sundial": Vector3(9.2, 0, -13.6), "sundial_talk": Vector3(9.2, 0, -11.5),
	"barracks": Vector3(-16.1, 0, 3.0), "barracks_talk": Vector3(-14.9, 0, 3.0),
	"counting_house": Vector3(15.0, 0, -12.4),
}

## Chapter 1's square (the SolhavenSet: the world has meta "solhaven_set")
## runs further south, with the notice board where the barracks gateway was
## and a solid gate: these spots replace HUB's and SQUARE's there.
const HUB_SET := {
	"barracks": Vector3(-16.1, 0, 14.2), "barracks_talk": Vector3(-14.9, 0, 14.2),   # between the houses, south of the board
}
const SQUARE_SET := {
	"ysa_gate": Vector3(-1.2, 0, 23.4),   # the shut gate, from inside: the way out to her camp
}


static func _is_set(w) -> bool:
	return w != null and is_instance_valid(w) and (w as Node).has_meta("solhaven_set")


## The square's spots for this world's square.
static func square(w) -> Dictionary:
	return SQUARE.merged(SQUARE_SET, true) if _is_set(w) else SQUARE


## The hub's marks for this world's square.
static func hubs(w) -> Dictionary:
	return HUB.merged(HUB_SET, true) if _is_set(w) else HUB


## A spot in a place, in the world.
static func spot(place: String, mark: String) -> Vector3:
	return ORIGIN[place] + MARKS[place][mark]


## Has Gary's model for this place (or prop) arrived?
static func has_model(file: String) -> bool:
	return ResourceLoader.exists(MODELS % file)


## The place, built the first time it's asked for.
static func build(w: World, place: String) -> Node3D:
	var key := "side_place_" + place
	if w.has_meta(key) and is_instance_valid(w.get_meta(key)):
		return w.get_meta(key)
	var root := Node3D.new()
	root.name = "SidePlace_" + place
	w.add_child(root)
	root.global_position = ORIGIN[place]
	w.set_meta(key, root)
	match place:
		"camp":
			_camp(root)
		"anselm":
			_anselm_room(root)
		"sundial":
			_sundial(root)
		"barracks":
			_barracks(root)
	return root


# ============================================================ the square ===

## The side stories' marks in the Sun Square, built with the square.
static func hub(w: World) -> void:
	if w.has_meta("side_hub"):
		return
	var root := Node3D.new()
	root.name = "SideHub"
	w.add_child(root)
	w.set_meta("side_hub", root)
	var at := hubs(w)
	_hub_sundial(root, at.sundial)
	_hub_barracks(root, at.barracks)
	_hub_counting_house(root, at.counting_house)


## The Great Sundial in the temple square: stepped rings of golden stone and a
## bronze pointer leaning north.
static func _hub_sundial(root: Node3D, c: Vector3) -> void:
	var K := LevelKit
	K.cylinder(root, c, 2.5, 0.16, "sandstone", true, 2.5, 40)
	K.cylinder(root, c, 2.05, 0.32, "sandstone", false, 2.05, 40)
	K.cylinder(root, c, 1.65, 0.46, "marble", false, 1.65, 40)
	_gnomon(root, c + Vector3(0, 0.46, 0.35), 3.4, 0.16)
	for i in 12:
		var a := TAU * i / 12.0
		var tick := K.box(root, c + Vector3(sin(a) * 1.4, 0.46, cos(a) * 1.4), Vector3(0.05, 0.02, 0.3), "bronze", false)
		tick.rotation.y = a


## A bronze pointer: a fin of bronze rising from `base`, its upright edge to the
## south and its long edge sloping down to the north.
static func _gnomon(root: Node3D, base: Vector3, length: float, thick: float) -> void:
	var g := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(length * 0.6, length, thick)
	pm.left_to_right = 0.0
	g.mesh = pm
	g.material_override = LevelKit.mat("bronze")
	root.add_child(g)
	g.rotation.y = PI * 0.5
	g.position = base + Vector3(0, length * 0.5, 0)


## The barracks gateway on the west side: a white wall with a gateway, a gold
## sun painted over it, and the dark of the yard beyond.
static func _hub_barracks(root: Node3D, c: Vector3) -> void:
	var K := LevelKit
	K.box(root, c + Vector3(0, 0, -2.05), Vector3(0.7, 3.8, 2.3), "plaster")
	K.box(root, c + Vector3(0, 0, 2.05), Vector3(0.7, 3.8, 2.3), "plaster")
	K.box(root, c + Vector3(0, 3.0, 0), Vector3(0.7, 0.8, 1.8), "plaster", false)
	var dark := K.box(root, c + Vector3(-0.55, 0, 0), Vector3(0.3, 3.0, 1.8), "dark_wood", false)
	dark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var sun := K.cylinder(root, c + Vector3(0.37, 3.55, 0), 0.34, 0.04, "gold", false, 0.34, 24)
	sun.rotation.z = PI * 0.5
	sun.position = c + Vector3(0.37, 3.55, 0)
	for i in 8:
		var a := TAU * i / 8.0
		var ray := K.box(root, c + Vector3(0.38, 3.55 + cos(a) * 0.5 - 0.06, sin(a) * 0.5), Vector3(0.03, 0.12, 0.22), "gold", false)
		ray.rotation.x = -a


## The counting-house steps on the east side: three stone steps up to a dark
## door with a brass plate, a coin crossed with a key.
static func _hub_counting_house(root: Node3D, c: Vector3) -> void:
	var K := LevelKit
	for i in 3:
		K.box(root, c + Vector3(-0.2 - i * 0.32, 0, 0), Vector3(1.0 - i * 0.1, 0.18 * (3 - i), 2.4), "sandstone", i == 0)
	K.box(root, c + Vector3(0.42, 0.54, 0), Vector3(0.12, 2.5, 1.5), "dark_wood", false)
	var plate := K.cylinder(root, c + Vector3(0.34, 2.2, 0), 0.2, 0.04, "gold", false, 0.2, 20)
	plate.rotation.z = PI * 0.5
	plate.position = c + Vector3(0.34, 2.2, 0)
	var key := K.box(root, c + Vector3(0.31, 2.2, 0), Vector3(0.02, 0.05, 0.34), "dark_wood", false)
	key.rotation.x = 0.7


# ================================================================ helpers ===

## Gary's model for a place when it exists: set into `parent` with its base on
## the ground, centred on `at`, turned by `yaw` and scaled so its widest side
## is `width` metres (the 3D tool's units are anyone's guess). Null if not.
static func model(parent: Node3D, file: String, width: float, at := Vector3.ZERO, yaw := 0.0) -> Node3D:
	var path := MODELS % file
	if not ResourceLoader.exists(path):
		return null
	var holder := Node3D.new()
	holder.name = file.capitalize()
	parent.add_child(holder)
	var inst: Node3D = (load(path) as PackedScene).instantiate()
	holder.add_child(inst)
	var box := AABB()
	var first := true
	for mi: MeshInstance3D in inst.find_children("*", "MeshInstance3D", true, false):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		var b := (inst.global_transform.affine_inverse() * mi.global_transform) * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	var k := width / maxf(0.01, maxf(box.size.x, box.size.z))
	inst.scale = Vector3.ONE * k
	inst.position = -Vector3(box.get_center().x, box.position.y, box.get_center().z) * k
	holder.position = at
	holder.rotation.y = yaw
	return holder


static func _mat(col: Color, rough := 0.9, emit := Color(0, 0, 0, 0), energy := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	if emit.a > 0.0:
		m.emission_enabled = true
		m.emission = emit
		m.emission_energy_multiplier = energy
	return m


static func _mesh(parent: Node3D, mesh: Mesh, pos: Vector3, m: Material, shadow := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


static func _box(parent: Node3D, pos: Vector3, size: Vector3, m: Material, shadow := true) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	return _mesh(parent, bm, pos + Vector3(0, size.y * 0.5, 0), m, shadow)


static func _light(parent: Node3D, pos: Vector3, col: Color, energy: float, rng: float, shadow := false) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng
	l.shadow_enabled = shadow
	l.position = pos
	parent.add_child(l)
	return l


static func _ground(root: Node3D, material: String, size := 140.0) -> void:
	var g := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(size, size)
	g.mesh = pm
	g.material_override = LevelKit.mat(material)
	root.add_child(g)


## A child lying under a blanket (Tobin, with his fever): a grey mound with a
## small head at one end. Turned by `yaw` (the head towards +x unturned).
static func lying_child(parent: Node3D, pos: Vector3, yaw := 0.0) -> Node3D:
	var n := Node3D.new()
	n.name = "LyingChild"
	parent.add_child(n)
	n.position = pos
	n.rotation.y = yaw
	var blanket := _mat(Color("8a8478"))
	var mound := SphereMesh.new()
	mound.radius = 0.5
	mound.height = 0.42
	var body := _mesh(n, mound, Vector3(-0.1, 0.1, 0), blanket)
	body.scale = Vector3(1.0, 0.9, 0.5)
	var head := SphereMesh.new()
	head.radius = 0.11
	head.height = 0.22
	_mesh(n, head, Vector3(0.5, 0.12, 0), _mat(Color("e2b48e")))
	var hair := SphereMesh.new()
	hair.radius = 0.115
	hair.height = 0.14
	_mesh(n, hair, Vector3(0.55, 0.16, 0), _mat(Color("4a2e1e")))
	return n


## The shrine lantern's light (Anselm's room), to brighten when the name is said.
static func shrine_light(w: World) -> OmniLight3D:
	var root := build(w, "anselm")
	return root.get_node_or_null("ShrineLight") as OmniLight3D


## Ysa's green leaf, looped on the shrine lantern's handle.
static func hang_leaf(w: World) -> void:
	var root := build(w, "anselm")
	if root.has_node("Leaf"):
		return
	var leaf := MeshInstance3D.new()
	leaf.name = "Leaf"
	var sm := SphereMesh.new()
	sm.radius = 0.05
	sm.height = 0.1
	leaf.mesh = sm
	leaf.scale = Vector3(0.45, 1.0, 0.18)
	leaf.material_override = _mat(Color("4f8a3a"), 0.7)
	root.add_child(leaf)
	leaf.position = MARKS.anselm.lantern + Vector3(0.1, 0.06, 0.13)
	leaf.rotation.z = 0.5


# =============================================================== the camp ===

## Outside Solhaven's walls: the wagon field, where the people the gate
## turned away have camped among sacks and bedrolls, with the city's white
## wall behind them.
static func _camp(root: Node3D) -> void:
	var K := LevelKit
	_ground(root, "grass")
	# the city wall and a tower, behind the camp
	K.box(root, Vector3(0, 0, -30), Vector3(110, 9, 2.4), "sandstone", false)
	for x in [-26.0, 4.0, 34.0]:
		K.cylinder(root, Vector3(x, 0, -29), 2.4, 13.0, "sandstone", false, 2.4, 16)
		K.cylinder(root, Vector3(x, 13.0, -29), 2.6, 2.6, "roof_teal", false, 0.0, 16)
	for i in 7:
		var hill := K.sphere(root, Vector3(-60 + i * 21, -10, -60 - (i % 3) * 8), 22, "hill", 0.6)
		hill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Tobin's blanket, and bedrolls round about
	_box(root, MARKS.camp.tobin + Vector3(0.1, 0, 0), Vector3(1.5, 0.03, 0.9), _mat(Color("6d5f4a")), false)
	var rolls := [[-3.4, 0.6, 0.3], [3.0, 1.0, -0.6], [-1.8, -3.0, 1.2], [5.2, -0.6, 0.2], [-5.6, -3.4, -0.4]]
	for r in rolls:
		var b := _box(root, Vector3(r[0], 0, r[1]), Vector3(1.8, 0.14, 0.7), _mat(Color("7a7064") if int(r[0]) % 2 == 0 else Color("5f6a74")), false)
		b.rotation.y = r[2]
	# lean-tos of sacking on poles
	for t in [[-6.0, -1.0, 0.4], [6.4, -4.0, -0.5], [-1.0, -7.0, 0.1]]:
		var tent := Node3D.new()
		root.add_child(tent)
		tent.position = Vector3(t[0], 0, t[1])
		tent.rotation.y = t[2]
		var cloth := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(2.4, 1.6, 2.2)
		cloth.mesh = pm
		cloth.material_override = _mat(Color("b0a07e"))
		cloth.position = Vector3(0, 0.8, 0)
		tent.add_child(cloth)
	# sacks: Gary's from Ashford, or drawn ones
	for s in [[-2.6, 1.4, 0.3], [3.4, 0.8, -1.0], [-4.8, -2.0, 2.0], [2.2, -3.6, 0.6]]:
		if ResourceLoader.exists(SACKS):
			var sk: Node3D = (load(SACKS) as PackedScene).instantiate()
			root.add_child(sk)
			sk.position = Vector3(s[0], 0, s[1])
			sk.rotation.y = s[2]
		else:
			for j in 3:
				var sack := SphereMesh.new()
				sack.radius = 0.32
				sack.height = 0.7
				_mesh(root, sack, Vector3(s[0] + j * 0.45 - 0.45, 0.33, s[1] + (j % 2) * 0.2), _mat(Color("c2ad84")))
	# a cart, or Bram's wagon when Gary's model exists
	if model(root, "wagon", 4.2, Vector3(-7.5, 0, -4.5), 0.5) == null:
		K.box(root, Vector3(-7.5, 0.7, -4.5), Vector3(1.8, 0.18, 3.2), "dark_wood", false, rad_to_deg(0.5))
		for sx in [-1, 1]:
			var wh := K.cylinder(root, Vector3(-7.5, 0, -4.5), 0.5, 0.14, "dark_wood", false, -1.0, 14)
			wh.rotation = Vector3(0, 0.5, PI * 0.5)
			wh.position = Vector3(-7.5 + cos(0.5) * sx * 1.0, 0.5, -4.5 - sin(0.5) * sx * 1.0)
	# a small fire
	for i in 5:
		var stick := K.box(root, Vector3(3.0, 0.05, 1.8), Vector3(0.8, 0.1, 0.12), "dark_wood", false)
		stick.rotation.y = TAU * i / 5.0
	var ember := K.sphere(root, Vector3(3.0, 0.12, 1.8), 0.22, "lamp_glow", 0.5)
	ember.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_light(root, Vector3(3.0, 0.8, 1.8), Color("ff9a4a"), 1.4, 6.0)


# ===================================================== Anselm's room ===

## A low room built into the arch under an old stone bridge, its walls streaked
## with old blue and red dye: steps down at one side, a straw pallet, a table of
## bandages, bowls and clay lamps, and in the corner a small shrine whose one
## lantern is barely lit. Open at the front, for the camera.
static func _anselm_room(root: Node3D) -> void:
	_ground(root, "cobble", 60.0)
	var stone := _mat(Color("8a8377"), 0.95)
	var lantern_at: Vector3 = MARKS.anselm.lantern
	if model(root, "anselm_room", 8.0, Vector3(0, 0, -2.6)) == null:
		_box(root, Vector3(0, 0, -2.6), Vector3(7.8, 0.04, 6.0), LevelKit.mat("flagstone"), false)
		_box(root, Vector3(0, 0, -5.75), Vector3(8.2, 4.2, 0.4), stone)
		for sx in [-1, 1]:
			_box(root, Vector3(sx * 4.05, 0, -2.6), Vector3(0.4, 4.2, 6.6), stone)
		# the bridge's vault: an open half-barrel of stone over the room
		var vault := CylinderMesh.new()
		vault.top_radius = 4.4
		vault.bottom_radius = 4.4
		vault.height = 6.6
		vault.cap_top = false
		vault.cap_bottom = false
		vault.radial_segments = 40
		var vm := _mat(Color("7a746a"), 0.95)
		vm.cull_mode = BaseMaterial3D.CULL_DISABLED
		var v := _mesh(root, vault, Vector3(0, -0.9, -2.55), vm)
		v.rotation.x = PI * 0.5
		# old dye, run down the stone
		var dyes := [[-2.6, Color("3b5d9a")], [-1.7, Color("9a3b3b")], [0.8, Color("3b5d9a")], [1.9, Color("8a3a4a")], [-0.3, Color("4a5f8a")]]
		for d in dyes:
			_box(root, Vector3(d[0], 0.4, -5.53), Vector3(0.22 + absf(d[0]) * 0.04, 2.6, 0.02), _mat(Color(d[1], 0.9)), false)
		for sx in [-1, 1]:
			_box(root, Vector3(sx * 3.84, 0.3, -1.6 - sx * 0.9), Vector3(0.02, 2.2, 0.5), _mat(Color("6a5a8a")), false)
		# the steps coming down at the left, from a dark doorway
		for i in 8:
			_box(root, Vector3(-3.25, 0, -1.7 - i * 0.45), Vector3(1.1, 0.35 * (i + 1), 0.45), stone)
		_box(root, Vector3(-3.25, 2.8, -5.5), Vector3(1.2, 1.9, 0.12), _mat(Color("15120e")), false)
		# straw pallet and grey blanket
		_box(root, Vector3(0.9, 0, -3.9), Vector3(2.0, 0.22, 0.95), _mat(Color("b59a5a")))
		_box(root, Vector3(0.7, 0.22, -3.9), Vector3(1.4, 0.04, 0.9), _mat(Color("7c7a74")), false)
		# the table: bandages, bowls, clay lamps
		var wood := LevelKit.mat("wood")
		_box(root, Vector3(-1.1, 0.78, -2.9), Vector3(1.7, 0.08, 0.85), wood)
		for lx in [-0.75, 0.75]:
			for lz in [-0.35, 0.35]:
				_box(root, Vector3(-1.1 + lx, 0, -2.9 + lz), Vector3(0.08, 0.78, 0.08), wood)
		for b in [[-1.6, -2.75], [-1.35, -3.05], [-1.1, -2.7]]:
			var roll := CylinderMesh.new()
			roll.top_radius = 0.06
			roll.bottom_radius = 0.06
			roll.height = 0.14
			_mesh(root, roll, Vector3(b[0], 0.93, b[1]), _mat(Color("efe9dc")), false).rotation.z = PI * 0.5
		for b in [[-0.6, -3.0], [-0.35, -2.7]]:
			var bowl := CylinderMesh.new()
			bowl.top_radius = 0.11
			bowl.bottom_radius = 0.07
			bowl.height = 0.07
			_mesh(root, bowl, Vector3(b[0], 0.9, b[1]), _mat(Color("8a5a3a")), false)
		var clay := SphereMesh.new()
		clay.radius = 0.06
		clay.height = 0.08
		_mesh(root, clay, Vector3(-0.8, 0.88, -3.15), _mat(Color("ffd27a"), 0.5, Color("ffb050"), 3.0), false)
		# the shrine in the corner, its shelf empty but for the lantern
		_box(root, Vector3(3.0, 0, -4.85), Vector3(1.0, 1.5, 0.6), wood)
		_box(root, Vector3(3.0, 1.5, -4.85), Vector3(1.1, 0.06, 0.66), LevelKit.mat("dark_wood"), false)
		_box(root, Vector3(3.0, 2.25, -5.05), Vector3(1.0, 0.06, 0.3), LevelKit.mat("dark_wood"), false)
	# Ilvane's lantern: Gary's own little model, or a dented tin one
	if model(root, "shrine_lantern", 0.2, lantern_at - Vector3(0, 0.1, 0)) == null:
		var tin := _mat(Color("8d8f8c"), 0.5)
		tin.metallic = 0.6
		_box(root, lantern_at - Vector3(0, 0.1, 0), Vector3(0.16, 0.22, 0.16), tin)
		_box(root, lantern_at - Vector3(0, 0.05, 0), Vector3(0.12, 0.13, 0.17), _mat(Color("ffe2a0", 0.9), 0.3, Color("ffb050"), 0.6), false)
		var ring := TorusMesh.new()
		ring.inner_radius = 0.03
		ring.outer_radius = 0.045
		var r := _mesh(root, ring, lantern_at + Vector3(0, 0.16, 0), tin, false)
		r.rotation.x = PI * 0.5
	var sl := _light(root, lantern_at + Vector3(0, 0.02, 0.1), Color("ffcc80"), 0.12, 1.6)
	sl.name = "ShrineLight"
	# lamplight on the table, a little daylight from the doorway, and the open front
	_light(root, Vector3(-0.9, 1.3, -3.0), Color("ffb066"), 1.6, 5.0)
	_light(root, Vector3(-3.0, 3.2, -4.6), Color("c8d4ff"), 0.6, 4.0)
	_light(root, Vector3(0.6, 2.4, 0.6), Color("ffd9a8"), 0.7, 8.0)


# ===================================================== the Great Sundial ===

## The base of the Great Sundial in the temple square: rings of pale golden
## steps up to a broad dial floor and a huge bronze pointer. On the lowest,
## oldest step the stone is worn smooth and the hour lines are cut twice: old
## ones filled with lead and painted gold, and new ones a short way along.
static func _sundial(root: Node3D) -> void:
	var K := LevelKit
	_ground(root, "flagstone")
	if model(root, "sundial_steps", 15.6) == null:
		K.cylinder(root, Vector3.ZERO, 7.6, 0.3, "sandstone", false, 7.6, 72)
		K.cylinder(root, Vector3.ZERO, 6.8, 0.6, "sandstone", false, 6.8, 72)
		K.cylinder(root, Vector3.ZERO, 6.0, 0.9, "sandstone", false, 6.0, 72)
		K.cylinder(root, Vector3(0, 0.9, 0), 5.6, 0.05, "marble", false, 5.6, 72)
		_gnomon(root, Vector3(0, 0.95, 1.6), 9.0, 0.4)
		# the oldest step's hour lines, cut twice
		var lead_gold := _mat(Color("e6c25a"), 0.3, Color("8a6a1a"), 0.4)
		lead_gold.metallic = 0.7
		var groove := _mat(Color("4a3a24"), 1.0)
		for i in 9:
			var a := deg_to_rad(-40.0 + i * 10.0)
			for k in 2:
				var off := 0.0 if k == 0 else deg_to_rad(2.2)   # nine days' shadow along
				var line := MeshInstance3D.new()
				var bm := BoxMesh.new()
				bm.size = Vector3(0.035, 0.012, 0.72)
				line.mesh = bm
				line.material_override = lead_gold if k == 0 else groove
				line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				root.add_child(line)
				var r := 7.22
				line.position = Vector3(sin(a + off) * r, 0.302, cos(a + off) * r)
				line.rotation.y = a + off
	# the temple behind it: a run of columns along the square's far side
	for i in 9:
		K.column(root, Vector3(-16.0 + i * 4.0, 0, -15.0), 8.0, 0.55)
	K.box(root, Vector3(0, 8.0, -15.0), Vector3(36.0, 1.0, 2.0), "marble", false)
	K.box(root, Vector3(0, 0, -19.0), Vector3(40.0, 11.0, 4.0), "marble", false)


## Dawn over the Sundial: a low warm sun from the east and a pale pink sky.
## dawn(w, false) puts the square's own light back.
static func dawn(w: World, on: bool) -> void:
	# the square's own sun and sky: Chapter 1's set's, or the world's
	var sun: DirectionalLight3D = null
	var env: Environment = null
	if _is_set(w):
		var v: Node = w.get_meta("solhaven_set")
		sun = v.get("sun") as DirectionalLight3D
		env = v.get("env") as Environment
	else:
		for c in w.get_children():
			if c is DirectionalLight3D and sun == null:
				sun = c
			elif c is WorldEnvironment and env == null:
				env = (c as WorldEnvironment).environment
	if sun == null or env == null:
		return
	_dawn(w, on, sun, env)


static func _dawn(w: World, on: bool, sun: DirectionalLight3D, env: Environment) -> void:
	var sky: ProceduralSkyMaterial = null
	if env.sky != null:
		sky = env.sky.sky_material as ProceduralSkyMaterial
	if on:
		if not w.has_meta("side_day"):
			var keep := {"rot": sun.rotation_degrees, "col": sun.light_color, "energy": sun.light_energy,
				"ambient": env.ambient_light_energy, "fog": env.fog_light_color}
			if sky != null:
				keep.merge({"top": sky.sky_top_color, "hor": sky.sky_horizon_color, "ground": sky.ground_horizon_color})
			w.set_meta("side_day", keep)
		sun.rotation_degrees = Vector3(-11, 96, 0)
		sun.light_color = Color("ffb27e")
		sun.light_energy = 1.05
		env.ambient_light_energy = 0.32
		env.fog_light_color = Color("e9b796")
		if sky != null:
			sky.sky_top_color = Color("4d64a0")
			sky.sky_horizon_color = Color("f3b08c")
			sky.ground_horizon_color = Color("c89f84")
	elif w.has_meta("side_day"):
		var k: Dictionary = w.get_meta("side_day")
		sun.rotation_degrees = k.rot
		sun.light_color = k.col
		sun.light_energy = k.energy
		env.ambient_light_energy = k.ambient
		env.fog_light_color = k.fog
		if sky != null and k.has("top"):
			sky.sky_top_color = k.top
			sky.sky_horizon_color = k.hor
			sky.ground_horizon_color = k.ground
		w.remove_meta("side_day")


# ===================================================== the barracks yard ===

## A small walled barracks yard: sandy ground inside white plaster walls with a
## gold sun over the arched gateway, a whipping post with iron rings in the
## middle, spears and round shields on a rack, a stone trough, and a covered
## walkway on wooden posts down one side. Open at the front, for the camera.
static func _barracks(root: Node3D) -> void:
	var K := LevelKit
	_ground(root, "cobble")
	if model(root, "barracks_yard", 18.0, Vector3(0, 0, -1.0)) == null:
		_box(root, Vector3(0, 0, -1.0), Vector3(17.6, 0.03, 16.0), _mat(Color("cdb88e"), 1.0), false)
		# the back wall, its arched gateway and the sun over it
		K.box(root, Vector3(-5.5, 0, -9.0), Vector3(7.0, 3.8, 0.6), "plaster")
		K.box(root, Vector3(5.5, 0, -9.0), Vector3(7.0, 3.8, 0.6), "plaster")
		K.box(root, Vector3(0, 3.0, -9.0), Vector3(4.0, 0.8, 0.6), "plaster", false)
		var sun := K.cylinder(root, Vector3.ZERO, 0.5, 0.05, "gold", false, 0.5, 24)
		sun.rotation.x = PI * 0.5
		sun.position = Vector3(0, 3.55, -8.68)
		for i in 10:
			var a := TAU * i / 10.0
			var ray := K.box(root, Vector3(sin(a) * 0.72, 3.55 + cos(a) * 0.72 - 0.08, -8.68), Vector3(0.1, 0.16, 0.03), "gold", false)
			ray.rotation.z = -a
		# the side walls
		for sx in [-1, 1]:
			K.box(root, Vector3(sx * 8.8, 0, -2.0), Vector3(0.6, 3.8, 14.6), "plaster")
		# the whipping post and its iron rings
		K.box(root, Vector3(0, 0, -1.5), Vector3(0.3, 2.5, 0.3), "dark_wood")
		var iron := _mat(Color("3a3836"), 0.6)
		iron.metallic = 0.7
		for ry in [1.95, 1.6]:
			var ring := TorusMesh.new()
			ring.inner_radius = 0.05
			ring.outer_radius = 0.09
			var r := _mesh(root, ring, Vector3(0, ry, -1.32), iron, false)
			r.rotation.x = PI * 0.5
		# spears and round shields along the left wall
		K.box(root, Vector3(-8.2, 1.0, -4.0), Vector3(0.2, 0.12, 4.0), "wood", false)
		for i in 7:
			var spear := K.cylinder(root, Vector3(-8.25, 0, -5.6 + i * 0.5), 0.025, 2.8, "wood", false, 0.025, 6)
			spear.rotation.z = 0.08
		for i in 3:
			var shield := K.cylinder(root, Vector3.ZERO, 0.42, 0.06, "cloth_white", false, 0.42, 20)
			shield.rotation.z = PI * 0.5
			shield.position = Vector3(-8.4, 1.1, -1.4 + i * 1.0)
			var boss := K.sphere(root, Vector3(-8.33, 1.1, -1.4 + i * 1.0), 0.09, "gold")
			boss.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# the trough, and the covered walk on posts down the right
		K.box(root, Vector3(7.6, 0, -6.4), Vector3(0.9, 0.7, 2.2), "rock")
		for i in 5:
			K.box(root, Vector3(6.2, 0, -7.5 + i * 3.0), Vector3(0.22, 3.0, 0.22), "wood", false)
		K.box(root, Vector3(7.4, 3.0, -1.5), Vector3(2.8, 0.2, 13.0), "roof_terracotta", false)


# ========================================================= the people ===

## Where the people of the side stories stand in the square, and the
## child lying by Ysa (inside the walls, among the families Hale let in).
const SQUARE := {
	# Ysa's corner, between the trees (seen from the south, clear of them)
	"ysa_in": Vector3(-9.4, 0, 7.4), "tobin_in": Vector3(-10.5, 0, 7.9), "healer_in": Vector3(-8.3, 0, 6.6),
	"player_ysa": Vector3(-7.6, 0, 8.1), "ysa_cam": Vector3(-8.9, 1.7, 12.95),
	"ysa_gate": Vector3(-2.4, 0, 13.3),
	"fen": Vector3(1.7, 0.74, -0.9), "fen_player": Vector3(2.4, 0, 2.2), "fen_wash": Vector3(2.05, 0, -0.4),
	"fen_cam": Vector3(-1.6, 3.4, 7.6), "fen_look": Vector3(1.4, 1.2, -0.4),   # over the crowd, clear of the lamps
	"crowd": [Vector3(-0.5, 0, 1.3), Vector3(3.3, 0, 0.9), Vector3(4.6, 0, 0.3), Vector3(4.4, 0, -1.7), Vector3(-1.7, 0, 0.1)],
	"behind_fen": Vector3(-0.4, 0, -7.6), "behind_player": Vector3(-1.4, 0, -8.6),
	"soup": Vector3(1.1, 0, -8.0), "debtor": Vector3(2.4, 0, -8.6), "line_a": Vector3(3.5, 0, -9.0), "line_b": Vector3(4.6, 0, -9.2),
	"soup_cam": Vector3(4.2, 2.0, -13.0), "soup_look": Vector3(1.4, 1.0, -8.4),   # from up the hill, the fountain behind
	"pip_steps": Vector3(13.5, 0, -12.7), "pell": Vector3(14.1, 0, -11.6), "side_door": Vector3(10.6, 0, -17.6),
	# from the fountain steps up to the side door, clear of the lamp and the Sundial
	"pip_way": [Vector3(3.4, 0, -11.2), Vector3(6.2, 0, -15.2)],
	# the fountain steps (v3: "The Fountain Steps"), where Pip comes back down to
	"pip_meet": Vector3(2.6, 0, -6.0), "player_meet": Vector3(4.0, 0, -7.2), "player_follow": Vector3(11.2, 0, -9.4),
	"meet_cam": Vector3(6.2, 1.9, -3.3),   # side on to the two of you
	"market": [Vector3(-0.8, 0, -6.8), Vector3(4.4, 0, -10.4), Vector3(1.0, 0, -9.8)],
	"wren_lift": Vector3(5.0, 0, -6.5),
}
