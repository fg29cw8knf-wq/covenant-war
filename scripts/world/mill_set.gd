class_name MillSet
extends RefCounted
## Tam Hayes's watermill (Master Script v6/v7): "Tam stands by the heavy
## wooden waterwheel", where the stream that's run cold since the Sigilfall in
## the Shardlands turns the millstones. A set of its own, built the first time
## the player goes down the lane to it, well away from the village (out past
## the edge of its land, where nothing stands over it to block the sun):
## the mill house, its big wheel turning in the race, the race between stone
## banks with a low wall to sit on, sacks and a barrel by the door, oaks round
## it, and the lane back up to the green. Tam's afternoon is here (his letter,
## his friendly game), and Corin's evening on the race wall (his button).
## Gary's own watermill takes the drawn one's place the moment it exists
## (assets/models/ashford/watermill.glb, its wheel a node named "Wheel" that
## turns on its x axis, or waterwheel.glb on its own).
##
##   var m := MillSet.build(village)      # once; then m.root, m.tam, m.corin...
##   MillSet.enter(w) / MillSet.leave(w)  # a haze over it while the player's there
##
## It stands out past the edge of the village's land (x 700), so a haze hides
## everything past its own meadow (the land's far edge, 180 m west) while the
## player's there; the shots look east and north, away from the village.

const AT := Vector3(700.0, 0.5, 0.0)
const MILL_MODEL := "res://assets/models/ashford/watermill.glb"
const WHEEL_MODEL := "res://assets/models/ashford/waterwheel.glb"
const WHEEL_R := 1.9
const WHEEL_W := 0.9
const WHEEL_SPEED := 0.55      # radians a second: a slow, heavy turn (the river's gone sour)
## Where people stand, in the set's own frame (it isn't turned, so the world
## spot is AT + this): Tam at the mill's door by the wheel, the player coming
## down the lane, Corin on the race wall in the evening.
const TAM := Vector3(0.55, 0, 3.6)
const ARRIVE := Vector3(-4.6, 0, 18.0)
const CORIN := Vector3(0.62, 0, 7.2)
## The haze while the player's at the mill (the village's own is far thinner).
const HAZE := 0.011


## A spot in the set, in the world (without building it).
static func spot(local: Vector3) -> Vector3:
	return AT + local


## While the player's here: a haze that hides the land's far edge.
static func enter(w: World) -> void:
	var v: AshfordVillage = w.get_meta("village")
	if v == null or v.env == null or v.has_meta("mill_fog"):
		return
	v.set_meta("mill_fog", v.env.fog_density)
	v.env.fog_density = HAZE


static func leave(w: World) -> void:
	var v: AshfordVillage = w.get_meta("village")
	if v == null or v.env == null or not v.has_meta("mill_fog"):
		return
	v.env.fog_density = float(v.get_meta("mill_fog"))
	v.remove_meta("mill_fog")


static func build(v: AshfordVillage) -> Dictionary:
	if v.has_meta("mill_set"):
		return v.get_meta("mill_set")
	var root := Node3D.new()
	root.name = "MillSet"
	root.position = AT
	v.add_child(root)
	# the ground: a meadow, a little rough, the grass up to the banks
	var ground := PlaneMesh.new()
	ground.size = Vector2(700, 700)
	ground.subdivide_width = 16
	ground.subdivide_depth = 16
	var gm := StandardMaterial3D.new()
	var noise := FastNoiseLite.new()
	noise.frequency = 0.04
	var nt := NoiseTexture2D.new()
	nt.noise = noise
	nt.width = 512
	nt.height = 512
	nt.seamless = true
	var grad := Gradient.new()
	grad.set_color(0, Color(0.20, 0.27, 0.10))
	grad.set_color(1, Color(0.36, 0.42, 0.18))
	nt.color_ramp = grad
	gm.albedo_texture = nt
	gm.uv1_scale = Vector3(90, 90, 1)
	gm.roughness = 0.95
	v.add_mesh(root, ground, gm, Transform3D.IDENTITY, false)
	# the race: north to south past the mill's east wall, between low stone
	# banks built up out of the meadow (a leat: the water runs above the grass)
	var race_x := 2.6
	var race_w := 2.3
	var stream := PlaneMesh.new()
	stream.size = Vector2(race_w, 70)
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color(0.16, 0.22, 0.24, 0.92)
	wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wm.roughness = 0.08
	wm.metallic = 0.25
	var wn := FastNoiseLite.new()
	wn.frequency = 0.08
	var wt := NoiseTexture2D.new()
	wt.noise = wn
	wt.seamless = true
	wt.as_normal_map = true
	wt.bump_strength = 6.0
	wm.normal_enabled = true
	wm.normal_texture = wt
	wm.uv1_scale = Vector3(1.5, 30, 1)
	var water := v.add_mesh(root, stream, wm, Transform3D(Basis.IDENTITY, Vector3(race_x, 0.28, 0)), false)
	water.name = "Race"
	# its dark bed just under the water, and the banks either side
	var bed := StandardMaterial3D.new()
	bed.albedo_color = Color(0.1, 0.12, 0.1)
	v.box(root, Vector3(race_w + 0.2, 0.05, 70), Vector3(race_x, 0.04, 0), bed)
	for s in [-1.0, 1.0]:
		v.box(root, Vector3(0.45, 0.5, 70), Vector3(race_x + s * (race_w * 0.5 + 0.22), 0.25, 0), v.mats.stone)
	# the low wall along the west bank, south of the mill: a seat by the water
	v.box(root, Vector3(0.5, 0.5, 6.0), Vector3(race_x - race_w * 0.5 - 0.45, 0.25, 7.5), v.mats.stone)
	var wall_seat := root.to_global(Vector3(race_x - race_w * 0.5 - 0.45, 0.5, 7.0))
	# the mill house: Gary's watermill, or a stone house with a thatched roof
	var house := Node3D.new()
	house.name = "MillHouse"
	root.add_child(house)
	var wheel: Node3D = null
	# where the house stands: its east wall on the race's west bank, so the
	# wheel turns against it (Gary's model, its origin at the middle of its
	# base and its long side north to south, stands in the same place)
	var L := 7.0
	var D := 5.5
	var H := 3.4
	house.position = Vector3(race_x - race_w * 0.5 - 0.5 - D * 0.5, 0, -1.0)
	if ResourceLoader.exists(MILL_MODEL):
		var m: Node3D = load(MILL_MODEL).instantiate()
		house.add_child(m)
		wheel = m.find_child("Wheel", true, false) as Node3D
	else:
		v.box(house, Vector3(D, H, L), Vector3(0, H * 0.5, 0), v.mats.stone)
		# a timbered upper storey and a steep thatch
		v.box(house, Vector3(D + 0.1, 0.25, L + 0.1), Vector3(0, H, 0), v.mats.beam)
		var roof := ArrayMesh.new()
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var rh := 2.8
		var hw := D * 0.5 + 0.5
		var hl := L * 0.5 + 0.4
		var pts := [Vector3(-hw, H, -hl), Vector3(hw, H, -hl), Vector3(hw, H, hl), Vector3(-hw, H, hl), Vector3(0, H + rh, -hl), Vector3(0, H + rh, hl)]
		for tri in [[0, 4, 5], [0, 5, 3], [1, 2, 5], [1, 5, 4], [0, 1, 4], [3, 5, 2]]:
			for k in tri:
				st.add_vertex(pts[k])
		st.generate_normals()
		roof = st.commit()
		v.add_mesh(house, roof, v.mats.get("thatch_old", v.mats.wood), Transform3D.IDENTITY)
		# the door on the south gable, a window either side
		v.box(house, Vector3(1.1, 2.0, 0.08), Vector3(0, 1.0, L * 0.5 + 0.03), v.mats.door_natural)
		v.window(house, Vector3(-1.6, 1.7, L * 0.5 + 0.05), 11, true)
		v.window(house, Vector3(1.6, 1.7, L * 0.5 + 0.05), 12, true)
	# the wheel, in the race against the east wall
	if wheel == null:
		wheel = Node3D.new()
		wheel.name = "Wheel"
		root.add_child(wheel)
		wheel.position = Vector3(race_x - 0.15, WHEEL_R - 0.55, -1.2)
		if ResourceLoader.exists(WHEEL_MODEL):
			wheel.add_child((load(WHEEL_MODEL) as PackedScene).instantiate())
		else:
			_drawn_wheel(v, wheel)
		# the axle into the wall
		v.cyl(root, 0.14, 0.14, 1.4, wheel.position + Vector3(-0.9, 0, 0), v.mats.beam_v, 10, Vector3(0, 0, PI * 0.5))
	# sacks, a barrel and a cart by the door; oaks round the meadow
	var props := [["sacks", Vector3(-1.4, 0, 3.6), 0.4], ["crate", Vector3(-4.8, 0, 3.0), 1.1], ["hay_cart", Vector3(-8.5, 0, 6.5), 2.4]]
	for p in props:
		var path := "res://assets/models/ashford/%s.glb" % p[0]
		if ResourceLoader.exists(path):
			var n: Node3D = load(path).instantiate()
			root.add_child(n)
			n.position = p[1]
			n.rotation.y = p[2]
			if p[0] == "crate":
				n.scale = Vector3.ONE * 0.55
	var b := v.make_barrel()
	root.add_child(b)
	b.position = Vector3(-2.9, AshfordVillage.BARREL_HALF, 3.3)
	var oaks := v.oak_scenes()
	if not oaks.is_empty():
		# round the meadow, and a looser ring further out that closes the view
		var spots := [Vector3(-14, 0, -10), Vector3(9, 0, -14), Vector3(12, 0, 6), Vector3(-12, 0, 12), Vector3(-20, 0, 0), Vector3(16, 0, -4), Vector3(4, 0, 18), Vector3(-6, 0, -20)]
		for k in 22:
			var a := TAU * k / 22.0 + 0.13
			var r := 34.0 + 10.0 * sin(k * 2.3)
			spots.append(Vector3(cos(a) * r, 0, sin(a) * r))
		for i in spots.size():
			var o: Node3D = (oaks[i % oaks.size()] as PackedScene).instantiate()
			root.add_child(o)
			o.position = spots[i]
			o.rotation.y = i * 1.7
			o.scale = Vector3.ONE * (0.9 + 0.1 * (i % 3))
	# the lane up to the green, a darker strip of trodden earth
	var lane := StandardMaterial3D.new()
	lane.albedo_color = Color(0.3, 0.25, 0.18)
	lane.roughness = 1.0
	v.box(root, Vector3(2.2, 0.02, 18.0), Vector3(-3.2, 0.01, 12.0), lane, Vector3(0, 0.25, 0))
	# a sun for the set (the village's moon light is the sun by day; this
	# fills the set's own shadows a little) and two lanterns on the race wall,
	# lit for the evening
	var lamps: Array = []
	for z in [5.2, 9.6]:
		var l := AshfordP1.paper_lantern(v, 1.4)
		root.add_child(l)
		l.position = Vector3(race_x - race_w * 0.5 - 0.45, 0.62, z)
		var ol := OmniLight3D.new()
		ol.light_color = Color(1.0, 0.62, 0.3)
		ol.light_energy = 0.0
		ol.omni_range = 5.0
		ol.position = l.position + Vector3(0, 0.3, 0)
		root.add_child(ol)
		lamps.append([l, ol])
	var out := {"root": root, "wheel": wheel, "water_mat": wm, "lamps": lamps,
		"floor_y": AT.y,
		# where people stand: Tam by the wheel, the player arriving down the lane
		"tam": root.to_global(TAM),
		"wheel_at": root.to_global(Vector3(race_x - 0.15, WHEEL_R - 0.55, -1.2)),
		"arrive": root.to_global(ARRIVE),
		"lane_end": root.to_global(Vector3(-4.2, 0, 21.0)),
		"wall_seat": wall_seat,
		"corin": root.to_global(CORIN),
		# walking it (AshfordP1.walk_room): the meadow by the mill, round the house, the race and the props
		"walk": Rect2(-9.0, -4.0, 10.6, 26.0),
		"blocks": [[Vector2(house.position.x, house.position.z - 1.8), 3.2], [Vector2(house.position.x, house.position.z + 1.8), 3.2],
			[Vector2(-1.4, 3.6), 0.8], [Vector2(-4.8, 3.0), 0.7], [Vector2(-8.5, 6.5), 1.8], [Vector2(-2.9, 3.3), 0.5],
			[Vector2(race_x - race_w * 0.5 - 0.45, 7.5), 0.45]],
		"keep_out": [Rect2(race_x - race_w * 0.5 - 0.5, -40, race_w + 2.0, 80)]}
	v.set_meta("mill_set", out)
	var spin := MillTurn.new()
	spin.wheel = wheel
	spin.water = wm
	root.add_child(spin)
	return out


## The wheel drawn until Gary's comes: two iron-banded oak rims, sixteen
## spokes and twenty-four paddles, on its axle (x).
static func _drawn_wheel(v: AshfordVillage, wheel: Node3D) -> void:
	var iron: Material = v.mats.metal
	for s in [-1.0, 1.0]:
		var rim := TorusMesh.new()
		rim.inner_radius = WHEEL_R - 0.12
		rim.outer_radius = WHEEL_R
		rim.rings = 40
		rim.ring_segments = 8
		v.add_mesh(wheel, rim, v.mats.beam, Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(s * WHEEL_W * 0.5, 0, 0)))
		var band := TorusMesh.new()
		band.inner_radius = WHEEL_R - 0.02
		band.outer_radius = WHEEL_R + 0.02
		band.rings = 40
		band.ring_segments = 6
		v.add_mesh(wheel, band, iron, Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(s * WHEEL_W * 0.5, 0, 0)))
		for k in 8:
			var a := TAU * k / 8.0
			v.box(wheel, Vector3(0.08, WHEEL_R * 2.0 - 0.2, 0.1), Vector3(s * WHEEL_W * 0.5, 0, 0), v.mats.beam_v, Vector3(a, 0, 0))
	for k in 24:
		var a := TAU * k / 24.0
		var p := Vector3(0, sin(a), cos(a)) * (WHEEL_R - 0.25)
		v.box(wheel, Vector3(WHEEL_W, 0.42, 0.05), p, v.mats.wood_h, Vector3(-a, 0, 0))
	v.cyl(wheel, 0.22, 0.22, WHEEL_W + 0.3, Vector3.ZERO, iron, 12, Vector3(0, 0, PI * 0.5))


## Light the race wall's lanterns (the evening) or put them out.
static func lamps(v: AshfordVillage, on: bool) -> void:
	var m: Dictionary = build(v)
	for pair in m.lamps:
		(pair[1] as OmniLight3D).light_energy = 1.4 if on else 0.0
		var mm := (pair[0] as Node3D).get_node_or_null("Paper") as MultiMeshInstance3D
		if mm != null and mm.material_override is ShaderMaterial:
			(mm.material_override as ShaderMaterial).set_shader_parameter("energy", 2.4 if on else 0.15)


## Turns the wheel and runs the water, frame by frame.
class MillTurn:
	extends Node
	var wheel: Node3D
	var water: StandardMaterial3D
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if is_instance_valid(wheel):
			wheel.rotation.x = fposmod(wheel.rotation.x - WHEEL_SPEED * delta, TAU)
		if water != null:
			water.uv1_offset = Vector3(0.0, -_t * 0.35, 0.0)
