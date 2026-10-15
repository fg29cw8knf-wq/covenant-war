class_name ThornwoodSet
extends AshfordVillage
## The country east of Ashford, for the end of the Prologue's film. It is
## built from the village's own materials and trees, round four places:
##
##   the river      below the hill, the night Ashford burns: the smugglers'
##                  tunnel comes out on the near bank, the village huddles on
##                  the far one, and the Crooked Lantern burns on the crest
##   the camp       a clearing in the Thornwood, the first night: Bram's fire
##   the road       the second night: the road narrows between thorn trees,
##                  fireflies, and Hunter Dask steps out
##   the ridge      dawn: the plains, and Solhaven's white towers far off
##
## The marks for each are in SPOTS; set_scene() sets the sky and light.

const RIVER_Z := 0.0
const WATER_Y := -0.85
## The burning village on the crest above the river.
const CREST := Vector3(0.0, 0.0, -46.0)
const SPOTS := {
	"tunnel": Vector3(-3.0, 0, -3.6),        # where the tunnel comes out, on the near bank
	"near_bank": Vector3(-1.6, 0, -2.4),
	"far_bank": Vector3(1.0, 0, 6.6),        # the villagers, across the water
	"camp": Vector3(40.0, 0, 34.0),          # the fire in the clearing
	"road": Vector3(-42.0, 0, 36.0),         # the narrow place between the thorns
	"ridge": Vector3(0.0, 0, 74.0),          # looking south over the plains
}
## Solhaven on the far side of the plains, south of the ridge.
const SOLHAVEN := Vector3(-30.0, 0.0, 430.0)

var water_mat: StandardMaterial3D
var crest_fires: Array = []
var inn_root: Node3D
var fireflies: GPUParticles3D
var campfire_light: OmniLight3D


func _ready() -> void:
	match RenderingServer.get_current_rendering_method():
		"forward_plus":
			quality = 2
		"mobile":
			quality = 1
		_:
			quality = 0
	if OS.has_feature("web"):
		quality = 0
	args["grass"] = str([7000, 14000, 26000][quality])
	rng.seed = 4242
	n_hills.seed = 19; n_hills.frequency = 0.012; n_hills.fractal_octaves = 4
	n_far.seed = 23; n_far.frequency = 0.004; n_far.fractal_octaves = 3
	n_small.seed = 5; n_small.frequency = 0.09
	make_materials()
	build_environment()
	build_paths()
	build_terrain()
	build_river()
	build_crest()
	build_camp()
	build_road_place()
	build_solhaven()
	build_forest()
	build_grass_here()
	if quality == 2:
		build_mist()
	build_post()
	set_scene("river")


## The land: a river along x at the foot of a hill rising north to the crest,
## a wooded rise to the south, and past the ridge the plains to Solhaven.
func height(x: float, z: float) -> float:
	var zc := RIVER_Z + 3.0 * sin(x / 25.0)
	var dz := z - zc
	# the hill north of the river, up to the crest
	var hill := smoothstep(3.0, 46.0, -dz) * 17.0 * (1.0 - smoothstep(60.0, 130.0, absf(x))) + smoothstep(3.0, 70.0, -dz) * 6.0
	# the wooded country south, rolling, up to the ridge
	var south := smoothstep(3.0, 30.0, dz) * (1.2 + (n_hills.get_noise_2d(x, z) * 0.5 + 0.5) * 3.5)
	var ridge := smoothstep(40.0, 74.0, z) * 4.5 - smoothstep(76.0, 120.0, z) * 9.5
	var far := 60.0 * smoothstep(220.0, 480.0, absf(x)) + 40.0 * smoothstep(-160.0, -420.0, z)
	var und := 0.18 * n_small.get_noise_2d(x, z)
	var h := hill + south + ridge + far + und
	# the river's channel, cut into whatever is there
	var ch := smoothstep(5.2, 2.2, absf(dz))
	h = lerpf(h, WATER_Y - 0.9, ch)
	# the camp clearing and the ridge top are flattened a little
	for c in [Vector2(SPOTS.camp.x, SPOTS.camp.z), Vector2(SPOTS.ridge.x, SPOTS.ridge.z)]:
		var d := Vector2(x, z).distance_to(c)
		var k := smoothstep(14.0, 5.0, d)
		if k > 0.0:
			var cx: float = c.x
			var cz: float = c.y
			h = lerpf(h, _base_at(cx, cz), k * 0.75)
	return h


## The height at a spot without the flattening (for the flattened places).
func _base_at(x: float, z: float) -> float:
	var zc := RIVER_Z + 3.0 * sin(x / 25.0)
	var dz := z - zc
	var south := smoothstep(3.0, 30.0, dz) * (1.2 + (n_hills.get_noise_2d(x, z) * 0.5 + 0.5) * 3.5)
	var ridge := smoothstep(40.0, 74.0, z) * 4.5 - smoothstep(76.0, 120.0, z) * 9.5
	return south + ridge


## The Thornwood road: from the river east and south through the trees, and
## the narrow road between the thorns.
func build_paths() -> void:
	var S := 512
	path_img = Image.create(S, S, false, Image.FORMAT_R8)
	path_img.fill(Color(0, 0, 0))
	var segs: Array = []
	var pts := [Vector2(-8, 8), Vector2(10, 14), Vector2(26, 24), Vector2(36, 30), Vector2(48, 44), Vector2(30, 60), Vector2(6, 70), Vector2(0, 90)]
	for i in pts.size() - 1:
		segs.append([pts[i], pts[i + 1], 1.8])
	var thorn := [Vector2(-42, 10), Vector2(-43, 24), Vector2(-42, 36), Vector2(-40, 50), Vector2(-34, 64)]
	for i in thorn.size() - 1:
		segs.append([thorn[i], thorn[i + 1], 1.2])
	for s in segs:
		paint_segment(s[0], s[1], s[2], S)
	set_meta("segs", segs)


func build_river() -> void:
	var q := PlaneMesh.new()
	q.size = Vector2(420.0, 14.0)
	q.subdivide_width = 60
	water_mat = StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.015, 0.025, 0.035)
	water_mat.roughness = 0.06
	water_mat.metallic = 0.2
	water_mat.metallic_specular = 0.7
	var nt := NoiseTexture2D.new()
	nt.width = 256
	nt.height = 256
	nt.seamless = true
	nt.as_normal_map = true
	nt.bump_strength = 3.0
	var fn := FastNoiseLite.new()
	fn.frequency = 0.05
	nt.noise = fn
	water_mat.normal_enabled = true
	water_mat.normal_texture = nt
	water_mat.normal_scale = 0.35
	water_mat.uv1_scale = Vector3(60.0, 2.0, 1.0)
	# the river bends with the channel: lay it in short straight pieces
	for i in 28:
		var x0 := -210.0 + i * 15.0
		var x1 := x0 + 15.0
		var z0 := RIVER_Z + 3.0 * sin(x0 / 25.0)
		var z1 := RIVER_Z + 3.0 * sin(x1 / 25.0)
		var mid := Vector3((x0 + x1) * 0.5, WATER_Y, (z0 + z1) * 0.5)
		var pm := PlaneMesh.new()
		pm.size = Vector2(Vector2(x1 - x0, z1 - z0).length() + 0.6, 8.0)
		var mi := add_mesh(self, pm, water_mat, Transform3D(Basis(Vector3.UP, -atan2(z1 - z0, x1 - x0)), mid), false)
		mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	# stones in the shallows, and the tunnel mouth in the near bank
	for i in 14:
		var x := rng.randf_range(-24.0, 24.0)
		var zc := RIVER_Z + 3.0 * sin(x / 25.0) + rng.randf_range(-3.6, 3.6)
		var r := add_mesh(self, rock_mesh(300 + i), mats.rock, Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * rng.randf_range(0.4, 1.0)), Vector3(x, WATER_Y + 0.05, zc)))
		r.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	var t: Vector3 = SPOTS.tunnel
	var arch := Node3D.new()
	arch.position = Vector3(t.x, height(t.x, t.z), t.z) + Vector3(0, 0, -1.6)
	add_child(arch)
	cyl(arch, 1.25, 1.25, 2.4, Vector3(0, 0.6, -0.6), mats.stone, 18, Vector3(PI / 2, 0, 0))
	cyl(arch, 0.95, 0.95, 2.6, Vector3(0, 0.6, -0.6), mats.dark, 18, Vector3(PI / 2, 0, 0))
	box(arch, Vector3(3.4, 2.2, 1.6), Vector3(0, 1.6, -1.8), mats.rock)
	box(arch, Vector3(1.9, 1.2, 0.2), Vector3(0, 0.0, 0.62), mats.dark)


## The crest above the river: the Crooked Lantern and two cottages, burning,
## and the mill beyond.
func build_crest() -> void:
	var c := CREST
	c.y = height(c.x, c.z)
	inn_root = _place("inn", c + Vector3(0, 0, 0), PI)
	for k in [[-13.0, -1.5, "cottage_a"], [12.5, 1.0, "cottage_c"], [-24.0, 3.0, "cottage_b"]]:
		var p := c + Vector3(float(k[0]), 0, float(k[1]))
		p.y = height(p.x, p.z)
		var root := _place(String(k[2]), p, PI + rng.randf_range(-0.3, 0.3))
		if root != null:
			crest_fires.append([root, p])
	build_mill(c + Vector3(30.0, 0, -6.0))
	# the glow of it all on the hillside and the clouds
	for i in 3:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.45, 0.14)
		l.light_energy = 0.0
		l.omni_range = 60.0
		l.omni_attenuation = 0.8
		l.position = c + Vector3(-12.0 + i * 12.0, 8.0, 6.0)
		add_child(l)
		set_meta("crest_glow_%d" % i, l)


func _place(id: String, pos: Vector3, yaw: float) -> Node3D:
	var path := "res://assets/models/ashford/%s.glb" % id
	if not ResourceLoader.exists(path):
		return null
	var root := Node3D.new()
	root.position = pos - Vector3(0, 0.1, 0)
	root.rotation.y = yaw
	add_child(root)
	var inst: Node3D = (load(path) as PackedScene).instantiate()
	root.add_child(inst)
	for mi: MeshInstance3D in inst.find_children("*", "MeshInstance3D", true, false):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return root


## Sets the crest alight (the night of the river scene).
func burn_crest() -> void:
	if inn_root != null:
		fire_at(inn_root.global_position + Vector3(0, 5.2, 0), Vector3(4.0, 0.8, 2.6), [30, 44, 60][quality], 1.5)
	for f in crest_fires:
		fire_at((f[1] as Vector3) + Vector3(0, 3.0, 0), Vector3(2.6, 0.5, 1.8), [16, 24, 36][quality], 1.1)
	if mill_root != null:
		fire_at(mill_root.to_global(Vector3(0, 10.2, 0)), Vector3(1.6, 0.5, 1.6), [14, 20, 30][quality], 1.1)
	for i in 3:
		var l: OmniLight3D = get_meta("crest_glow_%d" % i)
		l.light_energy = 6.0
		flicker_lights.append([l, 6.0])


## The roof of the Crooked Lantern falls in: a gout of sparks and flame, and
## then it burns lower.
func inn_roof_falls() -> void:
	if inn_root == null:
		return
	var at := inn_root.global_position + Vector3(0, 5.0, 0)
	var sp := GPUParticles3D.new()
	sp.amount = [120, 200, 320][quality]
	sp.lifetime = 3.2
	sp.one_shot = true
	sp.explosiveness = 0.8
	sp.position = at
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(4.0, 0.5, 2.5)
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 25.0
	pm.initial_velocity_min = 8.0
	pm.initial_velocity_max = 18.0
	pm.gravity = Vector3(0.5, -3.0, 0)
	pm.scale_min = 0.12
	pm.scale_max = 0.3
	sp.process_material = pm
	var q := QuadMesh.new(); q.size = Vector2(1, 1)
	sp.draw_pass_1 = q
	var em: ShaderMaterial = mats.ember.duplicate()
	em.set_shader_parameter("intensity", 30.0)
	sp.material_override = em
	sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sp.visibility_aabb = AABB(Vector3(-30, -5, -30), Vector3(60, 80, 60))
	add_child(sp)
	sp.emitting = true
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.6, 0.25)
	l.light_energy = 30.0
	l.omni_range = 70.0
	l.position = at + Vector3(0, 4, 4)
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "light_energy", 0.0, 2.5)
	tw.tween_callback(l.queue_free)
	var sink := create_tween()
	sink.tween_property(inn_root, "position:y", inn_root.position.y - 2.2, 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


## Bram's camp: a ring of stones, the fire, a log to sit on, a rabbit on a spit.
func build_camp() -> void:
	var c: Vector3 = SPOTS.camp
	c.y = height(c.x, c.z)
	var root := Node3D.new()
	root.position = c
	add_child(root)
	for i in 9:
		var a := TAU * i / 9.0
		var r := add_mesh(root, rock_mesh(500 + i), mats.rock, Transform3D(Basis(Vector3.UP, a).scaled(Vector3.ONE * 0.32), Vector3(cos(a) * 0.62, 0.06, sin(a) * 0.62)))
		r.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	for k in 4:
		var lg := cyl(root, 0.06, 0.06, 0.9, Vector3(0, 0.08, 0), mats.bark, 7, Vector3(PI / 2, TAU * k / 4.0 + 0.3, 0))
		lg.rotation = Vector3(PI / 2 - 0.25, TAU * k / 4.0 + 0.3, 0)
	var f := GPUParticles3D.new()
	f.amount = [14, 20, 28][quality]
	f.lifetime = 0.9
	f.preprocess = 1.0
	f.position = Vector3(0, 0.1, 0)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.22
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 10.0
	pm.initial_velocity_min = 0.6
	pm.initial_velocity_max = 1.1
	pm.gravity = Vector3(0, 0.8, 0)
	pm.scale_min = 0.35
	pm.scale_max = 0.6
	f.process_material = pm
	var q := QuadMesh.new(); q.size = Vector2(0.9, 1.4)
	f.draw_pass_1 = q
	f.material_override = mats.flame
	f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(f)
	var e := GPUParticles3D.new()
	e.amount = 30
	e.lifetime = 2.6
	e.preprocess = 2.6
	e.position = Vector3(0, 0.4, 0)
	var em := ParticleProcessMaterial.new()
	em.direction = Vector3(0, 1, 0)
	em.spread = 18.0
	em.initial_velocity_min = 1.0
	em.initial_velocity_max = 2.2
	em.gravity = Vector3(0, 0.2, 0)
	em.turbulence_enabled = true
	em.turbulence_noise_strength = 1.6
	em.scale_min = 0.03
	em.scale_max = 0.06
	e.process_material = em
	var eq := QuadMesh.new(); eq.size = Vector2(1, 1)
	e.draw_pass_1 = eq
	e.material_override = mats.ember
	e.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	e.visibility_aabb = AABB(Vector3(-4, -1, -4), Vector3(8, 10, 8))
	root.add_child(e)
	campfire_light = OmniLight3D.new()
	campfire_light.light_color = Color(1.0, 0.52, 0.2)
	campfire_light.light_energy = 3.2
	campfire_light.omni_range = 11.0
	campfire_light.shadow_enabled = true
	campfire_light.position = Vector3(0, 0.8, 0)
	root.add_child(campfire_light)
	flicker_lights.append([campfire_light, 3.2])
	# the spit and its rabbit, the log, Bram's pack
	for sx in [-1, 1]:
		cyl(root, 0.02, 0.025, 0.95, Vector3(0.55 * sx, 0.45, 0), mats.beam_v, 6, Vector3(0, 0, -0.25 * sx))
	cyl(root, 0.015, 0.015, 1.3, Vector3(0, 0.82, 0), mats.beam_v, 6, Vector3(0, 0, PI / 2))
	var rab := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.08
	cap.height = 0.38
	rab.mesh = cap
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color(0.35, 0.18, 0.08)
	rm.roughness = 0.6
	rab.material_override = rm
	rab.position = Vector3(0, 0.79, 0)
	rab.rotation = Vector3(0, 0, PI / 2)
	root.add_child(rab)
	cyl(root, 0.22, 0.24, 2.2, Vector3(-0.2, 0.2, 1.7), mats.bark, 10, Vector3(0, 0.3, PI / 2))
	var pack := box(root, Vector3(0.5, 0.45, 0.32), Vector3(1.6, 0.22, -1.2), mats.door_natural)
	pack.rotation.y = 0.5


## The narrow road between the thorn trees, and its fireflies.
func build_road_place() -> void:
	var c: Vector3 = SPOTS.road
	c.y = height(c.x, c.z)
	fireflies = GPUParticles3D.new()
	fireflies.amount = [50, 80, 120][quality]
	fireflies.lifetime = 6.0
	fireflies.preprocess = 6.0
	fireflies.position = c + Vector3(0, 1.4, 0)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(6.0, 1.0, 14.0)
	pm.direction = Vector3(0, 0.2, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = 0.05
	pm.initial_velocity_max = 0.25
	pm.gravity = Vector3.ZERO
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.6
	pm.turbulence_noise_speed_random = 0.5
	var ac := Gradient.new()
	ac.set_color(0, Color(1, 1, 1, 0))
	ac.add_point(0.2, Color(1, 1, 1, 1))
	ac.add_point(0.5, Color(1, 1, 1, 0.2))
	ac.add_point(0.7, Color(1, 1, 1, 1))
	ac.set_color(1, Color(1, 1, 1, 0))
	var act := GradientTexture1D.new(); act.gradient = ac
	pm.color_ramp = act
	fireflies.process_material = pm
	var q := QuadMesh.new(); q.size = Vector2(0.06, 0.06)
	fireflies.draw_pass_1 = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_color = Color(0.85, 1.0, 0.45) * 2.2
	fireflies.material_override = m
	fireflies.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fireflies.visibility_aabb = AABB(Vector3(-10, -3, -18), Vector3(20, 8, 36))
	add_child(fireflies)


## Solhaven on the far side of the plains: a wall, white towers with gold
## caps, and the Sunspire in the middle, catching the sun first.
func build_solhaven() -> void:
	var c := SOLHAVEN
	c.y = height(c.x, c.z)
	var root := Node3D.new()
	root.name = "SolhavenFar"
	root.position = c
	add_child(root)
	var white := StandardMaterial3D.new()
	white.albedo_color = Color(0.92, 0.9, 0.85)
	white.roughness = 0.7
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(0.95, 0.72, 0.28)
	gold.metallic = 0.9
	gold.roughness = 0.25
	gold.emission_enabled = true
	gold.emission = Color(1.0, 0.7, 0.3)
	gold.emission_energy_multiplier = 0.6
	# the wall
	for i in 40:
		var a := TAU * i / 40.0
		var p := Vector3(cos(a) * 70.0, 6.0, sin(a) * 50.0)
		var seg := box(root, Vector3(12.5, 12.0, 3.0), p, white)
		seg.rotation.y = -a + PI / 2
	# towers
	for i in 16:
		var a := TAU * i / 16.0 + 0.2
		var r := rng.randf_range(18.0, 60.0)
		var hgt := rng.randf_range(24.0, 48.0)
		var p := Vector3(cos(a) * r, hgt * 0.5, sin(a) * r * 0.7)
		cyl(root, 3.2, 3.8, hgt, p, white, 14)
		cyl(root, 0.0, 4.2, 9.0, p + Vector3(0, hgt * 0.5 + 4.5, 0), gold, 14)
	# the Sunspire
	cyl(root, 4.0, 7.0, 120.0, Vector3(0, 60.0, 0), white, 18)
	cyl(root, 0.0, 6.0, 26.0, Vector3(0, 133.0, 0), gold, 18)
	var spark := glow_sprite(root, Vector3(0, 146.0, 0), Color(1.0, 0.85, 0.5), 18.0, 1.2)
	spark.name = "Sunspark"
	root.visible = false
	set_meta("solhaven", root)


## Trees all round: oaks in the wood, thorn trees close along the narrow road,
## kept off the river, the paths, the clearings and the view from the ridge.
func build_forest() -> void:
	var variants := [make_tree(11), make_tree(23), make_tree(37), make_tree(51)]
	var bark_x := [[], [], [], []]
	var leaf_x := [[], [], [], []]
	var thorn_bark: Array = []
	var thorn_leaf: Array = []
	var n: int = [520, 800, 1100][quality]
	var tries := 0
	var placed := 0
	while placed < n and tries < n * 6:
		tries += 1
		var x := rng.randf_range(-150.0, 150.0)
		var z := rng.randf_range(-70.0, 130.0)
		var zc := RIVER_Z + 3.0 * sin(x / 25.0)
		if absf(z - zc) < 8.5:
			continue
		if path_at(x, z) > 0.1:
			continue
		var p := Vector2(x, z)
		if p.distance_to(Vector2(SPOTS.camp.x, SPOTS.camp.z)) < 9.0:
			continue
		# keep the crest and the hillside under it open, and the view south off the ridge
		if absf(x - CREST.x) < 40.0 and z < -8.0 and z > -60.0 and rng.randf() < 0.85:
			continue
		if z > 66.0 and absf(x - SPOTS.ridge.x) < 60.0:
			continue
		if p.distance_to(Vector2(SPOTS.far_bank.x, SPOTS.far_bank.z)) < 10.0:
			continue
		var near_road := absf(x - SPOTS.road.x) < 9.0 and z > 14.0 and z < 60.0
		var sc := rng.randf_range(0.85, 1.4)
		var xf := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * sc), Vector3(x, height(x, z) - 0.1, z))
		if near_road:
			thorn_bark.append(xf.scaled_local(Vector3(0.75, 0.7, 0.75)))
			thorn_leaf.append(xf.scaled_local(Vector3(0.75, 0.7, 0.75)))
		else:
			var k := rng.randi() % 4
			bark_x[k].append(xf)
			leaf_x[k].append(xf)
		placed += 1
	# a wall of thorn trees each side of the narrow road
	for side in [-1, 1]:
		for i in 22:
			var z := 16.0 + i * 2.0 + rng.randf_range(-0.6, 0.6)
			var x: float = SPOTS.road.x + side * rng.randf_range(2.6, 4.2)
			var xf := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * rng.randf_range(0.55, 0.85)), Vector3(x, height(x, z) - 0.1, z))
			thorn_bark.append(xf)
			thorn_leaf.append(xf)
	for k in 4:
		multimesh(self, variants[k][0], mats.bark, bark_x[k], [])
		multimesh(self, variants[k][1], mats.leaf, leaf_x[k], [])
	multimesh(self, variants[2][0], mats.bark, thorn_bark, [])
	multimesh(self, variants[2][1], mats.leaf_dark, thorn_leaf, [])


## Grass near the places the camera goes (not everywhere: it's a big wood).
func build_grass_here() -> void:
	var xfs: Array = []
	var cols: Array = []
	var target := int(args.get("grass", "14000"))
	var centres := [Vector2(0, 4), Vector2(SPOTS.camp.x, SPOTS.camp.z), Vector2(SPOTS.road.x, SPOTS.road.z), Vector2(SPOTS.ridge.x, SPOTS.ridge.z)]
	var tries := 0
	while xfs.size() < target and tries < target * 4:
		tries += 1
		var c: Vector2 = centres[tries % centres.size()]
		var rr := sqrt(rng.randf()) * 24.0
		var a := rng.randf() * TAU
		var x := c.x + cos(a) * rr
		var z := c.y + sin(a) * rr
		var zc := RIVER_Z + 3.0 * sin(x / 25.0)
		if absf(z - zc) < 3.4 or path_at(x, z) > 0.25:
			continue
		if Vector2(x, z).distance_to(Vector2(SPOTS.camp.x, SPOTS.camp.z)) < 1.3:
			continue
		var sc := rng.randf_range(0.7, 1.35)
		xfs.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(sc, sc * rng.randf_range(0.8, 1.3), sc)), Vector3(x, height(x, z) - 0.02, z)))
		var v := rng.randf_range(0.75, 1.15)
		cols.append(Color(v * rng.randf_range(0.9, 1.1), v, v * rng.randf_range(0.8, 1.0)))
	var mi := multimesh(self, blade_clump(), shader_mat("grass"), xfs, cols, false)
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED


## The sky and light for each part:
##   "river"  night, the tear's scar in the sky, Ashford burning on the crest
##   "camp"   night in the wood
##   "road"   a dark blue night, the last of the dusk in the west
##   "ridge"  dawn over the plains, Solhaven catching the sun
func set_scene(kind: String) -> void:
	var sol: Node3D = get_meta("solhaven") if has_meta("solhaven") else null
	if sol != null:
		sol.visible = kind == "ridge"
	sky_mat.set_shader_parameter("tear_open", 0.25 if kind != "ridge" else 0.12)
	match kind:
		"ridge":
			sky_mat.set_shader_parameter("dawn", 1.0)
			sky_mat.set_shader_parameter("sun_dir", Vector3(0.55, 0.12, 0.83))
			moon_light.light_color = Color(1.0, 0.78, 0.56)
			moon_light.light_energy = [2.2, 2.0, 1.9][quality]
			moon_light.look_at_from_position(Vector3.ZERO, -Vector3(0.55, 0.16, 0.83).normalized(), Vector3.UP)
			tear_light.visible = false
			env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			env.ambient_light_color = Color(0.66, 0.64, 0.74)
			env.ambient_light_energy = 0.9
			env.fog_light_color = Color(0.85, 0.66, 0.55)
			env.fog_density = 0.0016
		"road":
			sky_mat.set_shader_parameter("dawn", 0.28)
			sky_mat.set_shader_parameter("sun_dir", Vector3(-0.9, -0.06, 0.4))
			moon_light.light_color = Color(0.5, 0.6, 1.0)
			moon_light.light_energy = [0.7, 0.6, 0.5][quality]
			moon_light.look_at_from_position(Vector3.ZERO, -Vector3(-0.84, 0.45, 0.30), Vector3.UP)
			tear_light.visible = true
			_night_ambient(0.55)
			env.fog_light_color = Color(0.05, 0.06, 0.12)
			env.fog_density = 0.004
		_:
			sky_mat.set_shader_parameter("dawn", 0.0)
			moon_light.light_color = Color(0.55, 0.66, 1.0)
			moon_light.light_energy = [0.8, 0.7, 0.6][quality]
			moon_light.look_at_from_position(Vector3.ZERO, -Vector3(-0.84, 0.45, 0.30), Vector3.UP)
			tear_light.visible = true
			_night_ambient(0.6)
			env.fog_light_color = Color(0.04, 0.05, 0.10)
			env.fog_density = 0.0025 if kind == "camp" else 0.0012


func _night_ambient(e: float) -> void:
	if quality == 2:
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_energy = 1.2
	else:
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.32, 0.36, 0.55)
		env.ambient_light_energy = e


func _process(delta: float) -> void:
	super(delta)
	if water_mat != null:
		water_mat.uv1_offset.x += delta * 0.02
