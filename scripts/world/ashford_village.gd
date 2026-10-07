class_name AshfordVillage
extends Node3D
## Ashford on the last night of the Age: the village built for the walkable
## world, from the look test in lookdev/ashford. Festival first; at midnight
## the sky lanterns rise, then the Sigilfall: the sky tears, Sigils fall, a roof
## catches fire and one white light comes down to the player.
##
## Quality follows the renderer: Forward+ (Mac, iPad) gets everything, the
## phone renderer drops volumetric fog and bounce light, and the web build also
## thins the grass.

signal phase_done(what: String)

const SH := "res://assets/shaders/village/"
var rng := RandomNumberGenerator.new()
var n_hills := FastNoiseLite.new()
var n_far := FastNoiseLite.new()
var n_small := FastNoiseLite.new()
var path_img: Image
const PATH_EXTENT := 120.0
var footprints: Array = []   # [Vector2 centre, radius]
var mats := {}
var env: Environment
var streaks: Array = []      # {node, glow, light, dir, len, head, speed, width}
var white_light: Node3D
var flicker_lights: Array = []
var args := {}
var sky_mat: ShaderMaterial
var paper_mm: MultiMeshInstance3D
var leaf_tex: ImageTexture
var quality := 2             # 2 Forward+, 1 phone renderer, 0 web
var burning_house: Node3D
var elapsed := 0.0


func _ready() -> void:
	var t0 := Time.get_ticks_msec()
	match RenderingServer.get_current_rendering_method():
		"forward_plus":
			quality = 2
		"mobile":
			quality = 1
		_:
			quality = 0
	if OS.has_feature("web"):
		quality = 0
	args["grass"] = str([9000, 20000, 42000][quality])
	rng.seed = 1171
	n_hills.seed = 7; n_hills.frequency = 0.008; n_hills.fractal_octaves = 4
	n_far.seed = 11; n_far.frequency = 0.004; n_far.fractal_octaves = 3
	n_small.seed = 3; n_small.frequency = 0.08
	make_materials()
	if quality == 0:
		mats.lantern.set_shader_parameter("energy", 1.3)
		mats.bulb.set_shader_parameter("energy", 3.0)
	build_environment()
	build_paths()
	build_terrain()
	build_village()
	build_green()
	build_walls_and_fences()
	build_trees()
	build_grass()
	build_sky_lanterns()
	build_sigilfall()
	if quality == 2:
		build_mist()
	build_post()
	print("Ashford built in %d ms (quality %d)" % [Time.get_ticks_msec() - t0, quality])


func height(x: float, z: float) -> float:
	var r := sqrt(x * x + z * z)
	var flat := smoothstep(24.0, 55.0, r)
	var hills := (n_hills.get_noise_2d(x, z) * 0.5 + 0.5) * 16.0 * flat
	var village_floor := smoothstep(26.0, 60.0, r)
	var ne := 26.0 * exp(-((x - 62.0) ** 2 + (z + 85.0) ** 2) / (2.0 * 40.0 * 40.0)) * village_floor
	var sw := 9.0 * exp(-((x + 50.0) ** 2 + (z - 58.0) ** 2) / (2.0 * 26.0 * 26.0)) * village_floor
	var far := 85.0 * smoothstep(170.0, 340.0, r) * (0.5 + 0.5 * (n_far.get_noise_2d(x, z) * 0.5 + 0.5))
	var und := 0.22 * n_small.get_noise_2d(x, z) * smoothstep(27.0, 40.0, r)
	return hills + ne + sw + far + und

func shader_mat(name: String, params := {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(SH + name + ".gdshader")
	for k in params:
		m.set_shader_parameter(k, params[k])
	return m

func make_materials() -> void:
	mats.stone = shader_mat("stone")
	mats.stone_ww = shader_mat("stone", {"whitewash": 0.95, "plaster": Color(0.60, 0.58, 0.53)})
	mats.stone_ww2 = shader_mat("stone", {"whitewash": 0.9, "plaster": Color(0.64, 0.55, 0.42)})
	mats.rock = shader_mat("stone", {"stone_a": Color(0.25, 0.245, 0.23), "stone_b": Color(0.15, 0.145, 0.14), "course": 3.0, "block": 4.0})
	mats.thatch = shader_mat("thatch")
	mats.thatch_old = shader_mat("thatch", {"age": 0.8})
	mats.wood = shader_mat("wood")
	mats.wood_h = shader_mat("wood", {"grain_axis": Vector3(1, 0, 0)})
	mats.beam = shader_mat("wood", {"wood_a": Color(0.10, 0.07, 0.05), "wood_b": Color(0.05, 0.035, 0.025), "grain_axis": Vector3(1, 0, 0)})
	mats.beam_v = shader_mat("wood", {"wood_a": Color(0.10, 0.07, 0.05), "wood_b": Color(0.05, 0.035, 0.025)})
	for c in [["green", Color(0.10, 0.22, 0.16)], ["blue", Color(0.10, 0.16, 0.30)], ["red", Color(0.35, 0.08, 0.06)], ["natural", Color(0.22, 0.14, 0.08)]]:
		mats["door_" + c[0]] = shader_mat("wood", {"plank": 0.16, "paint": 0.0 if c[0] == "natural" else 0.9, "paint_col": c[1]})
	mats.window = shader_mat("window")
	mats.metal = shader_mat("metal")
	mats.cloth_red = shader_mat("cloth")
	mats.cloth_blue = shader_mat("cloth", {"col_a": Color(0.08, 0.14, 0.40), "col_b": Color(0.85, 0.80, 0.62)})
	mats.flag = shader_mat("flag")
	mats.bulb = shader_mat("bulb")
	mats.lantern = shader_mat("lantern")
	mats.streak = shader_mat("streak")
	mats.glow = shader_mat("glowball")
	mats.flame = shader_mat("flame")
	mats.smoke = shader_mat("smoke", {"smoke_col": Color(0.035, 0.032, 0.03), "opacity": 0.6})
	mats.chimney_smoke = shader_mat("smoke", {"smoke_col": Color(0.06, 0.065, 0.08), "opacity": 0.3, "glow_tint": Color(0, 0, 0)})
	mats.ember = shader_mat("ember")
	mats.bark = shader_mat("bark")
	mats.hay = shader_mat("thatch", {"straw": Color(0.45, 0.36, 0.18), "age": 0.1})
	leaf_tex = make_leaf_texture()
	mats.leaf = shader_mat("leaf", {"leaves": leaf_tex})
	mats.leaf_dark = shader_mat("leaf", {"leaves": leaf_tex, "tint": Color(0.22, 0.3, 0.16)})
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.02, 0.018, 0.015)
	dark.roughness = 1.0
	mats.dark = dark
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.3, 0.2, 0.1)
	glass.emission_enabled = true
	glass.emission = Color(1.0, 0.62, 0.28)
	glass.emission = Color(1.0, 0.5, 0.18)
	glass.emission_energy_multiplier = 2.6
	mats.lamp_glass = glass

# ------------------------------------------------------------------ environment

func build_environment() -> void:
	env = Environment.new()
	sky_mat = shader_mat("sky")
	var sky := Sky.new()
	sky.sky_material = sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_128
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	if quality == 2:
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_energy = 1.6
	else:
		# no bounce light on the simpler renderers: a moonlit fill instead
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.36, 0.42, 0.62)
		env.ambient_light_energy = [0.75, 0.6][quality]
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.0
	env.glow_enabled = true
	env.glow_normalized = false
	env.glow_intensity = 0.55
	env.glow_strength = 1.0
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.0
	env.glow_hdr_scale = 2.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	var lv := [0.0, 0.6, 1.0, 1.0, 0.8, 0.6, 0.35]
	for i in lv.size():
		env.set_glow_level(i, lv[i])
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 1.8
	env.ssil_enabled = quality == 2
	env.sdfgi_enabled = quality == 2
	env.sdfgi_use_occlusion = true
	env.sdfgi_min_cell_size = 0.15
	env.sdfgi_cascades = 6
	env.sdfgi_energy = 1.2
	env.sdfgi_bounce_feedback = 0.6
	env.volumetric_fog_enabled = quality == 2
	env.volumetric_fog_density = 0.0014
	env.volumetric_fog_albedo = Color(0.75, 0.8, 0.95)
	env.volumetric_fog_anisotropy = 0.55
	env.volumetric_fog_length = 110.0
	env.volumetric_fog_detail_spread = 2.0
	env.volumetric_fog_gi_inject = 0.5
	env.volumetric_fog_ambient_inject = 0.0
	env.volumetric_fog_sky_affect = 0.0
	env.volumetric_fog_temporal_reprojection_enabled = true
	env.fog_enabled = true
	env.fog_light_color = Color(0.04, 0.05, 0.10)
	env.fog_density = 0.0008
	env.fog_sky_affect = 0.0
	env.fog_height = 3.0
	env.fog_height_density = 0.02
	env.fog_aerial_perspective = 0.5
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 1.12
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	# Moonlight and the cold light from the tear in the sky.
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.55, 0.66, 1.0)
	moon.light_energy = [1.0, 0.85, 0.7][quality]
	moon.shadow_enabled = true
	moon.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS if quality == 2 else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	moon.directional_shadow_max_distance = 140.0 if quality == 2 else 60.0
	moon.light_angular_distance = 0.6
	moon.shadow_blur = 1.2
	add_child(moon)
	moon.look_at_from_position(Vector3.ZERO, -Vector3(-0.84, 0.45, 0.30), Vector3.UP)
	var tear := DirectionalLight3D.new()
	tear.light_color = Color(0.75, 0.6, 1.0)
	tear.light_energy = 0.3
	tear.shadow_enabled = false
	add_child(tear)
	tear.look_at_from_position(Vector3.ZERO, -Vector3(0.1, 0.7, -0.7), Vector3.UP)

# ------------------------------------------------------------------ paths

func build_paths() -> void:
	var S := 512
	path_img = Image.create(S, S, false, Image.FORMAT_R8)
	path_img.fill(Color(0, 0, 0))
	var segs: Array = []
	# ring road around the green
	var ring := 15.5
	for i in 48:
		var a0 := TAU * i / 48.0
		var a1 := TAU * (i + 1) / 48.0
		segs.append([Vector2(cos(a0), sin(a0)) * ring, Vector2(cos(a1), sin(a1)) * ring, 1.9])
	# the main road east-west, south of the green
	var pts := [Vector2(-125, 30), Vector2(-70, 24), Vector2(-35, 17), Vector2(-14, 14.5), Vector2(14, 14.5), Vector2(40, 12), Vector2(80, 2), Vector2(125, -10)]
	for i in pts.size() - 1:
		segs.append([pts[i], pts[i + 1], 2.2])
	# track north up to the mill
	var mill := [Vector2(6, -15), Vector2(18, -35), Vector2(38, -58), Vector2(55, -78)]
	for i in mill.size() - 1:
		segs.append([mill[i], mill[i + 1], 1.4])
	# the green's own worn paths to the lantern and the well
	segs.append([Vector2(0, 15), Vector2(0, 1.0), 1.0])
	segs.append([Vector2(-15, 0), Vector2(-1, 0), 0.9])
	segs.append([Vector2(-6, 4), Vector2(-1, 1), 0.8])
	for s in segs:
		paint_segment(s[0], s[1], s[2], S)
	set_meta("segs", segs)

func paint_segment(a: Vector2, b: Vector2, w: float, S: int) -> void:
	var to_px := func(p: Vector2) -> Vector2: return (p / (PATH_EXTENT * 2.0) + Vector2(0.5, 0.5)) * S
	var pa: Vector2 = to_px.call(a)
	var pb: Vector2 = to_px.call(b)
	var wpx := w / (PATH_EXTENT * 2.0) * S
	var x0 := int(clamp(min(pa.x, pb.x) - wpx * 2 - 2, 0, S - 1))
	var x1 := int(clamp(max(pa.x, pb.x) + wpx * 2 + 2, 0, S - 1))
	var y0 := int(clamp(min(pa.y, pb.y) - wpx * 2 - 2, 0, S - 1))
	var y1 := int(clamp(max(pa.y, pb.y) + wpx * 2 + 2, 0, S - 1))
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var p := Vector2(x + 0.5, y + 0.5)
			var d := Geometry2D.get_closest_point_to_segment(p, pa, pb).distance_to(p)
			var v := clampf(1.0 - (d - wpx * 0.5) / (wpx * 0.8 + 0.5), 0.0, 1.0)
			if v > path_img.get_pixel(x, y).r:
				path_img.set_pixel(x, y, Color(v, v, v))

func path_at(x: float, z: float) -> float:
	var S := path_img.get_width()
	var px := int((x / (PATH_EXTENT * 2.0) + 0.5) * S)
	var py := int((z / (PATH_EXTENT * 2.0) + 0.5) * S)
	if px < 0 or py < 0 or px >= S or py >= S:
		return 0.0
	return path_img.get_pixel(px, py).r

# ------------------------------------------------------------------ terrain

func build_terrain() -> void:
	var N := 230
	var half := 520.0
	var coords := PackedFloat32Array()
	for i in N + 1:
		var t := float(i) / N * 2.0 - 1.0
		coords.append(sign(t) * pow(abs(t), 1.9) * half)
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var idx := PackedInt32Array()
	for j in N + 1:
		for i in N + 1:
			var x := coords[i]
			var z := coords[j]
			verts.append(Vector3(x, height(x, z), z))
			var e := 0.5
			var nx := height(x - e, z) - height(x + e, z)
			var nz := height(x, z - e) - height(x, z + e)
			norms.append(Vector3(nx, 2.0 * e, nz).normalized())
	for j in N:
		for i in N:
			var a := j * (N + 1) + i
			var b := a + 1
			var c := a + N + 1
			var d := c + 1
			idx.append_array([a, b, c, b, d, c])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var tex := ImageTexture.create_from_image(path_img)
	var m := shader_mat("terrain", {"path_mask": tex, "path_extent": PATH_EXTENT})
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	add_child(mi)
	# check winding: flip if the top face points down
	var ab := verts[1] - verts[0]
	var ac := verts[N + 1] - verts[0]
	if ab.cross(ac).y > 0.0:
		for k in range(0, idx.size(), 3):
			var tmp := idx[k + 1]; idx[k + 1] = idx[k + 2]; idx[k + 2] = tmp
		arr[Mesh.ARRAY_INDEX] = idx
		mesh.clear_surfaces()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)

# ------------------------------------------------------------------ mesh helpers

func add_mesh(parent: Node, mesh: Mesh, mat: Material, xf := Transform3D.IDENTITY, shadows := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = xf
	if not shadows:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi

func box(parent: Node, size: Vector3, pos: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	var xf := Transform3D(Basis.from_euler(rot), pos)
	return add_mesh(parent, b, mat, xf)

func cyl(parent: Node, r_top: float, r_bot: float, h: float, pos: Vector3, mat: Material, segs := 16, rot := Vector3.ZERO) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = r_top
	c.bottom_radius = r_bot
	c.height = h
	c.radial_segments = segs
	c.rings = 1
	return add_mesh(parent, c, mat, Transform3D(Basis.from_euler(rot), pos))

func tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3, ua: Vector2, ub: Vector2, uc: Vector2) -> void:
	# Godot treats clockwise triangles as front-facing.
	if (b - a).cross(c - a).dot(n) > 0.0:
		var t := b; b = c; c = t
		var tu := ub; ub = uc; uc = tu
	for v in [[a, ua], [b, ub], [c, uc]]:
		st.set_normal(n)
		st.set_uv(v[1])
		st.add_vertex(v[0])

## Extrude a (z, y) profile, counter-clockwise, along x from x0 to x1.
func extrude(profile: PackedVector2Array, x0: float, x1: float, caps := true) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := profile.size()
	var per := 0.0
	for i in n:
		var a := profile[i]
		var b := profile[(i + 1) % n]
		var e := b - a
		var nz := e.y
		var ny := -e.x
		var nrm := Vector3(0, ny, nz).normalized()
		var len := e.length()
		var A0 := Vector3(x0, a.y, a.x); var A1 := Vector3(x1, a.y, a.x)
		var B0 := Vector3(x0, b.y, b.x); var B1 := Vector3(x1, b.y, b.x)
		tri(st, A0, B0, B1, nrm, Vector2(x0, per), Vector2(x0, per + len), Vector2(x1, per + len))
		tri(st, A0, B1, A1, nrm, Vector2(x0, per), Vector2(x1, per + len), Vector2(x1, per))
		per += len
	if caps:
		var ids := Geometry2D.triangulate_polygon(profile)
		for k in range(0, ids.size(), 3):
			var p := [profile[ids[k]], profile[ids[k + 1]], profile[ids[k + 2]]]
			for side in [[x1, Vector3(1, 0, 0)], [x0, Vector3(-1, 0, 0)]]:
				var xx: float = side[0]
				tri(st, Vector3(xx, p[0].y, p[0].x), Vector3(xx, p[1].y, p[1].x), Vector3(xx, p[2].y, p[2].x), side[1],
					Vector2(p[0].x, -p[0].y), Vector2(p[1].x, -p[1].y), Vector2(p[2].x, -p[2].y))
	st.generate_tangents()
	return st.commit()

func ccw(p: PackedVector2Array) -> PackedVector2Array:
	var area := 0.0
	for i in p.size():
		var a := p[i]; var b := p[(i + 1) % p.size()]
		area += a.x * b.y - b.x * a.y
	if area < 0.0:
		p.reverse()
	return p

# ------------------------------------------------------------------ buildings

func build_village() -> void:
	# [angle (deg, 0 = +x, counter-clockwise seen from above), radius, length, depth, wall height, style]
	var plan := [
		[18, 22.0, 7.5, 5.0, 2.6, 0], [48, 23.0, 6.5, 4.8, 2.5, 1], [76, 22.5, 8.0, 5.2, 2.7, 2],
		[104, 23.5, 6.8, 4.8, 2.5, 0], [132, 22.0, 7.2, 5.0, 2.6, 1], [205, 23.0, 7.0, 5.0, 2.6, 2],
		[232, 22.5, 6.5, 4.6, 2.4, 0], [258, 23.0, 7.8, 5.2, 2.7, 1], [286, 24.0, 6.6, 4.8, 2.5, 2],
		[314, 23.0, 7.4, 5.0, 2.6, 0], [340, 22.0, 6.4, 4.6, 2.5, 1],
	]
	var doors := ["green", "blue", "red", "natural"]
	for i in plan.size():
		var p: Array = plan[i]
		var ang := deg_to_rad(p[0])
		# angles measured toward -z so "north" is up the screen in the main shots
		var pos := Vector3(cos(ang) * p[1], 0.0, -sin(ang) * p[1])
		house(pos, p[2], p[3], p[4], p[5], doors[i % 4], i, i == 4)
	# the Crooked Lantern inn, two storeys, on the west side
	var inn_pos := Vector3(-24.0, 0.0, 6.0)
	house(inn_pos, 11.0, 6.4, 4.8, 0, "green", 99, false, true)
	# farmhouses dotted over the hills, lights in their windows
	for f in [Vector3(-70, 0, -40), Vector3(48, 0, 46), Vector3(95, 0, -30), Vector3(-95, 0, 20), Vector3(-30, 0, -95), Vector3(20, 0, -120)]:
		house(f, 7.0, 5.0, 2.6, 1, "natural", 200 + int(f.x), false)
	build_mill(Vector3(62.0, 0.0, -88.0))

func house(pos: Vector3, L: float, D: float, H: float, style: int, door: String, seed_i: int, burning: bool, inn := false) -> void:
	var root := Node3D.new()
	pos.y = height(pos.x, pos.z) - 0.2
	root.position = pos
	# face the green
	var to_c := -Vector2(pos.x, pos.z).normalized()
	root.rotation.y = atan2(to_c.x, to_c.y)
	add_child(root)
	footprints.append([Vector2(pos.x, pos.z), max(L, D) * 0.62])
	var R := D * 0.55 + (0.6 if inn else 0.4)
	var wall_mat: Material = [mats.stone, mats.stone_ww, mats.stone_ww2][style]
	# body: pentagon profile in (z, y), extruded along x
	var body := ccw(PackedVector2Array([Vector2(-D / 2, -0.4), Vector2(D / 2, -0.4), Vector2(D / 2, H), Vector2(0, H + R), Vector2(-D / 2, H)]))
	add_mesh(root, extrude(body, -L / 2, L / 2), wall_mat)
	# plinth
	box(root, Vector3(L + 0.25, 0.45, D + 0.25), Vector3(0, 0.0, 0), mats.stone)
	# thatched roof with thickness, rounded eaves and a ridge cap
	var k := R / (D / 2)
	var o := 0.55
	var T := 0.42
	var zE := D / 2 + o
	var yb := func(z: float) -> float: return H + R - abs(z) * k
	var prof := PackedVector2Array()
	prof.append(Vector2(zE, yb.call(zE)))
	for s in 5:
		var a := PI * 0.5 * (s + 1) / 6.0
		prof.append(Vector2(zE + sin(a) * 0.12, yb.call(zE) + (1.0 - cos(a)) * T * 0.9))
	prof.append(Vector2(zE - 0.05, yb.call(zE) + T))
	prof.append(Vector2(0.35, yb.call(0.35) + T + 0.05))
	prof.append(Vector2(0.0, yb.call(0.0) + T + 0.18))
	prof.append(Vector2(-0.35, yb.call(-0.35) + T + 0.05))
	prof.append(Vector2(-zE + 0.05, yb.call(-zE) + T))
	for s in 5:
		var a := PI * 0.5 * (5 - s) / 6.0
		prof.append(Vector2(-zE - sin(a) * 0.12, yb.call(-zE) + (1.0 - cos(a)) * T * 0.9))
	prof.append(Vector2(-zE, yb.call(-zE)))
	prof.append(Vector2(0.0, yb.call(0.0) - 0.02))
	var roof_mat: Material = mats.thatch_old if seed_i % 3 == 1 else mats.thatch
	add_mesh(root, extrude(ccw(prof), -L / 2 - 0.45, L / 2 + 0.45), roof_mat)
	# chimney on one gable
	var cx := L / 2 - 0.55 if seed_i % 2 == 0 else -L / 2 + 0.55
	box(root, Vector3(0.7, H + R + 1.3, 0.8), Vector3(cx, (H + R + 1.3) / 2 - 0.3, -0.15), mats.stone)
	box(root, Vector3(0.85, 0.12, 0.95), Vector3(cx, H + R + 1.05, -0.15), mats.stone)
	if not burning:
		chimney_smoke(root, Vector3(cx, H + R + 1.2, -0.15))
	# front: door, windows, lantern
	var fz := D / 2
	var door_x := 0.0 if L < 7.2 else -0.6
	box(root, Vector3(1.05, 2.0, 0.12), Vector3(door_x, 0.95, fz + 0.02), mats["door_" + door])
	box(root, Vector3(1.3, 0.16, 0.25), Vector3(door_x, 2.02, fz + 0.06), mats.beam)
	box(root, Vector3(0.14, 2.1, 0.22), Vector3(door_x - 0.6, 0.95, fz + 0.05), mats.beam_v)
	box(root, Vector3(0.14, 2.1, 0.22), Vector3(door_x + 0.6, 0.95, fz + 0.05), mats.beam_v)
	var wins: Array = []
	if L >= 7.0:
		wins = [door_x - 2.2, door_x + 2.0]
	else:
		wins = [-L * 0.3, L * 0.3]
	var rows := [1.35]
	if inn:
		wins = [-4.0, -2.0, 2.0, 4.0]
		rows = [1.35, 3.4]
	for row in rows:
		for wx in wins:
			window(root, Vector3(wx, row, fz), seed_i * 10 + int(wx * 3) + int(row), true)
	# a window at the back and one in the gable, so the house glows from every side
	window(root, Vector3(0.0, 1.35, -fz), seed_i * 7 + 3, false, PI)
	var gx := -L / 2 if seed_i % 2 == 0 else L / 2
	window(root, Vector3(gx, H + R * 0.28, 0.0), seed_i * 5 + 1, false, -PI / 2 if seed_i % 2 == 0 else PI / 2)
	# door lantern
	var lan := Vector3(door_x + 0.95, 2.05, fz + 0.28)
	box(root, Vector3(0.05, 0.05, 0.3), lan + Vector3(0, 0.25, -0.15), mats.metal)
	box(root, Vector3(0.2, 0.28, 0.2), lan, mats.lamp_glass)
	cyl(root, 0.0, 0.17, 0.12, lan + Vector3(0, 0.2, 0), mats.metal, 4)
	var ll := OmniLight3D.new()
	ll.light_color = Color(1.0, 0.62, 0.3)
	ll.light_energy = 1.4
	ll.omni_range = 7.0
	ll.omni_attenuation = 1.4
	ll.position = lan + Vector3(0, -0.1, 0.2)
	ll.light_size = 0.1
	root.add_child(ll)
	if inn:
		# hanging sign of the Crooked Lantern
		box(root, Vector3(0.08, 0.08, 1.4), Vector3(L / 2 - 1.0, 3.0, fz + 0.65), mats.metal)
		box(root, Vector3(0.08, 0.75, 1.0), Vector3(L / 2 - 1.0, 2.5, fz + 0.9), mats.door_red)
		box(root, Vector3(0.22, 0.3, 0.22), Vector3(L / 2 - 1.0, 2.0, fz + 1.4), mats.lamp_glass)
	if burning:
		burning_house = root
		set_meta("burning_dims", [L, D, H, R])
	solid_box(Vector3(pos.x, 1.5, pos.z), Vector3(L + 0.6, 3.0, D + 0.6), root.rotation.y)

func window(root: Node3D, at: Vector3, seed_i: int, shutters: bool, yaw := 0.0) -> void:
	var w := Node3D.new()
	w.position = at
	w.rotation.y = yaw
	root.add_child(w)
	var q := QuadMesh.new()
	q.size = Vector2(0.75, 0.95)
	var gm: ShaderMaterial = mats.window.duplicate()
	gm.set_shader_parameter("seed", float(seed_i % 97))
	gm.set_shader_parameter("energy", 2.6 + (seed_i % 5) * 0.35)
	add_mesh(w, q, gm, Transform3D(Basis(), Vector3(0, 0, 0.015)), false)
	box(w, Vector3(0.95, 0.1, 0.14), Vector3(0, 0.52, 0.05), mats.beam)
	box(w, Vector3(1.0, 0.09, 0.24), Vector3(0, -0.52, 0.08), mats.stone)
	box(w, Vector3(0.09, 1.05, 0.14), Vector3(-0.43, 0, 0.05), mats.beam_v)
	box(w, Vector3(0.09, 1.05, 0.14), Vector3(0.43, 0, 0.05), mats.beam_v)
	if shutters:
		var sm: Material = [mats.door_green, mats.door_blue, mats.door_natural][seed_i % 3]
		box(w, Vector3(0.42, 0.95, 0.05), Vector3(-0.72, 0, 0.12), sm, Vector3(0, 0.35, 0))
		box(w, Vector3(0.42, 0.95, 0.05), Vector3(0.72, 0, 0.12), sm, Vector3(0, -0.35, 0))
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.58, 0.26)
	l.light_energy = 1.1
	l.omni_range = 5.5
	l.omni_attenuation = 1.6
	l.position = Vector3(0, -0.1, 0.55)
	w.add_child(l)

func chimney_smoke(root: Node3D, at: Vector3) -> void:
	var p := GPUParticles3D.new()
	p.amount = 14
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.position = at
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0.3, 1, 0.1)
	pm.spread = 12.0
	pm.initial_velocity_min = 0.5
	pm.initial_velocity_max = 0.9
	pm.gravity = Vector3(0.25, 0.08, 0.05)
	pm.scale_min = 0.6
	pm.scale_max = 1.0
	var sc := Curve.new(); sc.add_point(Vector2(0, 0.4)); sc.add_point(Vector2(1, 2.4))
	var sct := CurveTexture.new(); sct.curve = sc
	pm.scale_curve = sct
	pm.angle_min = -180; pm.angle_max = 180
	p.process_material = pm
	var q := QuadMesh.new(); q.size = Vector2(1.4, 1.4)
	p.draw_pass_1 = q
	p.material_override = mats.chimney_smoke
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-4, -1, -4), Vector3(14, 14, 10))
	root.add_child(p)

func build_mill(pos: Vector3) -> void:
	var root := Node3D.new()
	pos.y = height(pos.x, pos.z) - 0.3
	root.position = pos
	root.rotation.y = deg_to_rad(205)
	add_child(root)
	cyl(root, 2.0, 3.0, 9.0, Vector3(0, 4.5, 0), mats.stone_ww, 20)
	cyl(root, 0.0, 2.6, 2.6, Vector3(0, 10.2, 0), mats.thatch_old, 20)
	window(root, Vector3(0, 6.0, 2.42), 5, false)
	window(root, Vector3(0, 2.4, 2.92), 6, false)
	var hub := Node3D.new()
	hub.position = Vector3(0, 8.6, 2.6)
	hub.rotation.z = deg_to_rad(18)
	root.add_child(hub)
	for i in 4:
		var arm := Node3D.new()
		arm.rotation.z = TAU * i / 4.0
		hub.add_child(arm)
		box(arm, Vector3(0.22, 7.5, 0.16), Vector3(0, 3.75, 0), mats.beam_v)
		box(arm, Vector3(1.4, 5.8, 0.05), Vector3(0.8, 4.3, 0.05), mats.cloth_blue)
	cyl(hub, 0.35, 0.35, 0.6, Vector3(0, 0, -0.2), mats.metal, 10, Vector3(PI / 2, 0, 0))

# ------------------------------------------------------------------ the green

func build_green() -> void:
	var g := Node3D.new()
	add_child(g)
	# the Great Lantern
	var lp := Vector3(0.0, height(0, 0), 0.0)
	solid_round(lp, 0.45)
	cyl(g, 0.12, 0.18, 10.0, lp + Vector3(0, 5.0, 0), mats.beam_v, 10)
	box(g, Vector3(1.8, 0.12, 0.12), lp + Vector3(0, 9.2, 0), mats.beam)
	box(g, Vector3(0.12, 0.12, 1.8), lp + Vector3(0, 9.2, 0), mats.beam)
	var top := lp + Vector3(0, 10.35, 0)
	box(g, Vector3(0.62, 0.8, 0.62), top, mats.lamp_glass)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			box(g, Vector3(0.07, 0.9, 0.07), top + Vector3(0.33 * sx, 0, 0.33 * sz), mats.metal)
	cyl(g, 0.05, 0.62, 0.45, top + Vector3(0, 0.62, 0), mats.metal, 4, Vector3(0, PI / 4, 0))
	var gl := OmniLight3D.new()
	gl.light_color = Color(1.0, 0.6, 0.28)
	gl.light_energy = 6.0
	gl.light_volumetric_fog_energy = 0.6
	gl.omni_range = 26.0
	gl.omni_attenuation = 1.3
	gl.shadow_enabled = true
	gl.light_size = 0.3
	gl.position = top
	g.add_child(gl)
	flicker_lights.append([gl, 7.0])
	glow_sprite(g, top, Color(1.0, 0.5, 0.2), 1.6, 0.5)
	# bunting and fairy lights from the lantern to poles round the green
	var poles: Array = []
	for i in 7:
		var a := TAU * i / 7.0 + 0.3
		var pp := Vector3(cos(a) * 11.5, 0, sin(a) * 11.5)
		pp.y = height(pp.x, pp.z)
		cyl(g, 0.08, 0.1, 9.0, pp + Vector3(0, 4.5, 0), mats.beam_v, 8)
		poles.append(pp + Vector3(0, 8.9, 0))
		solid_round(pp, 0.25)
	var flag_xf: Array = []
	var flag_col: Array = []
	var bulb_xf: Array = []
	var bulb_col: Array = []
	var lan_xf: Array = []
	var lan_col: Array = []
	var palette := [Color(0.7, 0.08, 0.06), Color(0.85, 0.65, 0.12), Color(0.08, 0.2, 0.6), Color(0.85, 0.82, 0.7), Color(0.1, 0.4, 0.15)]
	for i in poles.size():
		var a: Vector3 = top + Vector3(0, -1.1, 0)
		var b: Vector3 = poles[i]
		var nb := poles[(i + 1) % poles.size()] as Vector3
		for pass_i in 2:
			var p0 := a if pass_i == 0 else b
			var p1 := b if pass_i == 0 else nb
			var sag := 0.9 if pass_i == 0 else 1.2
			var L := p0.distance_to(p1)
			var steps := int(L / 0.42)
			for s in steps:
				var t := (s + 0.5) / steps
				var p := p0.lerp(p1, t) - Vector3(0, sag * 4.0 * t * (1.0 - t), 0)
				var dir := (p1 - p0).normalized()
				var yaw := atan2(-dir.z, dir.x)
				flag_xf.append(Transform3D(Basis(Vector3.UP, yaw), p))
				flag_col.append(palette[(s + i) % palette.size()])
				var pb := p + Vector3(0, -0.05, 0.0)
				bulb_xf.append(Transform3D(Basis().scaled(Vector3.ONE * 0.5), pb + Vector3(0, 0.02, 0)))
				bulb_col.append(Color(1.0, 0.75, 0.45))
				if s % 6 == 3:
					lan_xf.append(Transform3D(Basis().scaled(Vector3.ONE * 0.65), p - Vector3(0, 0.45, 0)))
					lan_col.append(Color(1.0, 0.45 + 0.2 * rng.randf(), 0.15, rng.randf()))
	multimesh(g, flag_mesh(), mats.flag, flag_xf, flag_col, false)
	var bm := SphereMesh.new(); bm.radius = 0.035; bm.height = 0.07; bm.radial_segments = 6; bm.rings = 3
	multimesh(g, bm, mats.bulb, bulb_xf, bulb_col, false)
	multimesh(g, lantern_mesh(), mats.lantern, lan_xf, lan_col, false)
	# the well
	var wp := Vector3(-6.0, height(-6, 4), 4.0)
	var ring := CylinderMesh.new(); ring.top_radius = 0.95; ring.bottom_radius = 1.0; ring.height = 0.85; ring.radial_segments = 20
	add_mesh(g, ring, mats.stone, Transform3D(Basis(), wp + Vector3(0, 0.42, 0)))
	cyl(g, 0.72, 0.72, 0.05, wp + Vector3(0, 0.86, 0), mats.dark, 20)
	for sx in [-1, 1]:
		box(g, Vector3(0.14, 2.0, 0.14), wp + Vector3(0.85 * sx, 1.4, 0), mats.beam_v)
	box(g, Vector3(2.2, 0.08, 1.3), wp + Vector3(0, 2.5, 0.3), mats.wood_h, Vector3(0.45, 0, 0))
	box(g, Vector3(2.2, 0.08, 1.3), wp + Vector3(0, 2.5, -0.3), mats.wood_h, Vector3(-0.45, 0, 0))
	cyl(g, 0.1, 0.1, 1.6, wp + Vector3(0, 1.9, 0), mats.wood, 8, Vector3(0, 0, PI / 2))
	footprints.append([Vector2(wp.x, wp.z), 1.2])
	solid_round(wp, 1.15)
	# festival stalls
	stall(g, Vector3(7.5, 0, 6.0), deg_to_rad(-30), mats.cloth_red)
	stall(g, Vector3(-4.0, 0, -8.5), deg_to_rad(160), mats.cloth_blue)
	# hay cart
	var cp := Vector3(9.0, height(9, -5), -5.0)
	var cart := Node3D.new(); cart.position = cp; cart.rotation.y = 0.6; g.add_child(cart)
	box(cart, Vector3(2.6, 0.5, 1.5), Vector3(0, 0.9, 0), mats.wood_h)
	for sx in [-1, 1]:
		cyl(cart, 0.55, 0.55, 0.1, Vector3(0, 0.55, 0.8 * sx), mats.wood, 16, Vector3(PI / 2, 0, 0))
	var hay := SphereMesh.new(); hay.radius = 1.0; hay.height = 1.2
	add_mesh(cart, hay, mats.hay, Transform3D(Basis().scaled(Vector3(1.3, 0.8, 0.75)), Vector3(0, 1.35, 0)))
	box(cart, Vector3(2.2, 0.08, 0.08), Vector3(2.0, 0.65, 0.4), mats.wood_h, Vector3(0, 0, -0.25))
	box(cart, Vector3(2.2, 0.08, 0.08), Vector3(2.0, 0.65, -0.4), mats.wood_h, Vector3(0, 0, -0.25))
	footprints.append([Vector2(cp.x, cp.z), 1.8])
	solid_round(cp, 1.7)

func stall(parent: Node3D, pos: Vector3, yaw: float, cloth: Material) -> void:
	var s := Node3D.new()
	pos.y = height(pos.x, pos.z)
	s.position = pos
	s.rotation.y = yaw
	parent.add_child(s)
	box(s, Vector3(2.4, 0.08, 1.0), Vector3(0, 0.9, 0), mats.wood_h)
	box(s, Vector3(2.3, 0.85, 0.06), Vector3(0, 0.45, 0.45), mats.door_natural)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			box(s, Vector3(0.08, 2.3, 0.08), Vector3(1.15 * sx, 1.15, 0.5 * sz), mats.beam_v)
	var aw := PlaneMesh.new(); aw.size = Vector2(2.7, 1.6); aw.subdivide_depth = 4
	add_mesh(s, aw, cloth, Transform3D(Basis(Vector3.RIGHT, -0.32), Vector3(0, 2.35, 0.1)))
	# goods: apples, jars, bundles
	for i in 26:
		var sp := SphereMesh.new(); sp.radius = 0.055; sp.height = 0.11; sp.radial_segments = 8; sp.rings = 4
		var c := StandardMaterial3D.new()
		c.albedo_color = [Color(0.5, 0.06, 0.04), Color(0.45, 0.4, 0.08), Color(0.25, 0.35, 0.08)][i % 3]
		c.roughness = 0.5
		add_mesh(s, sp, c, Transform3D(Basis(), Vector3(rng.randf_range(-1.0, 1.0), 1.0, rng.randf_range(-0.35, 0.35))), false)
	for i in 3:
		var bar := CylinderMesh.new(); bar.top_radius = 0.28; bar.bottom_radius = 0.28; bar.height = 0.8; bar.radial_segments = 14
		add_mesh(s, bar, mats.wood, Transform3D(Basis(), Vector3(-1.6 + i * 0.1, 0.4, -0.3 + i * 0.6)))
	box(s, Vector3(0.6, 0.45, 0.45), Vector3(1.6, 0.22, -0.2), mats.wood_h, Vector3(0, 0.3, 0))
	box(s, Vector3(0.22, 0.3, 0.22), Vector3(1.05, 2.0, 0.55), mats.lamp_glass)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.6, 0.3); l.light_energy = 1.3; l.omni_range = 6.0
	l.position = Vector3(1.05, 1.8, 0.75)
	s.add_child(l)
	footprints.append([Vector2(pos.x, pos.z), 1.8])
	solid_box(Vector3(pos.x, 1.5, pos.z), Vector3(2.7, 3.0, 1.5), yaw)

func flag_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a := Vector3(-0.12, 0, 0); var b := Vector3(0.12, 0, 0); var c := Vector3(0, -0.3, 0)
	st.set_normal(Vector3(0, 0, 1)); st.set_uv(Vector2(0, 0)); st.add_vertex(a)
	st.set_normal(Vector3(0, 0, 1)); st.set_uv(Vector2(1, 0)); st.add_vertex(b)
	st.set_normal(Vector3(0, 0, 1)); st.set_uv(Vector2(0.5, 1)); st.add_vertex(c)
	return st.commit()

func lantern_mesh() -> Mesh:
	var c := CylinderMesh.new()
	c.top_radius = 0.2
	c.bottom_radius = 0.15
	c.height = 0.48
	c.radial_segments = 10
	c.rings = 2
	return c

func multimesh(parent: Node, mesh: Mesh, mat: Material, xfs: Array, cols: Array, shadows := true) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = cols.size() > 0
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
		if cols.size() > 0:
			mm.set_instance_color(i, cols[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = mat
	if not shadows:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi

func glow_sprite(parent: Node, pos: Vector3, col: Color, size: float, intensity: float) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	var mi := add_mesh(parent, q, mats.glow, Transform3D(Basis().scaled(Vector3.ONE * size), pos), false)
	mi.set_instance_shader_parameter("col", col)
	mi.set_instance_shader_parameter("intensity", intensity)
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	return mi

# ------------------------------------------------------------------ walls, fences, rocks

func rock_mesh(seed_i: int) -> ArrayMesh:
	var sm := SphereMesh.new()
	sm.radius = 0.5; sm.height = 1.0
	sm.radial_segments = 10 if quality == 2 else 7
	sm.rings = 6 if quality == 2 else 4
	var arr := sm.get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var nz := FastNoiseLite.new(); nz.seed = seed_i; nz.frequency = 1.6
	for i in v.size():
		var p := v[i]
		v[i] = p * (1.0 + 0.22 * nz.get_noise_3dv(p * 2.0)) * Vector3(1.25, 0.5, 0.8)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = null
	arr[Mesh.ARRAY_TANGENT] = null
	var st := SurfaceTool.new()
	st.create_from_arrays(arr)
	st.generate_normals()
	return st.commit()

func build_walls_and_fences() -> void:
	var lines := [
		[Vector2(-125, 34), Vector2(-70, 28), Vector2(-36, 21)],
		[Vector2(-125, 26), Vector2(-70, 20), Vector2(-36, 12.5)],
		[Vector2(42, 16), Vector2(80, 6), Vector2(125, -6)],
		[Vector2(42, 8), Vector2(80, -2), Vector2(125, -14)],
		[Vector2(-40, -30), Vector2(-60, -70), Vector2(-50, -130)],
		[Vector2(30, -30), Vector2(10, -70), Vector2(-10, -140)],
		[Vector2(-36, 21), Vector2(-50, 60), Vector2(-40, 110)],
		[Vector2(70, 10), Vector2(90, 60), Vector2(70, 120)],
		[Vector2(-60, -70), Vector2(10, -70)],
	]
	var meshes := [rock_mesh(1), rock_mesh(2), rock_mesh(3)]
	var xfs := [[], [], []]
	for line in lines:
		for i in line.size() - 1:
			var a: Vector2 = line[i]
			var b: Vector2 = line[i + 1]
			var L := a.distance_to(b)
			var n := int(L / 0.36)
			var dir := (b - a).normalized()
			for s in n:
				var p := a.lerp(b, (s + 0.5) / n)
				if quality < 2 and p.length() > 85.0:
					continue
				for layer in 3:
					var jitter := Vector2(-dir.y, dir.x) * rng.randf_range(-0.12, 0.12)
					var q := p + jitter + dir * (0.2 if layer == 1 else 0.0)
					var y := height(q.x, q.y) + 0.1 + layer * 0.24
					var sc := rng.randf_range(0.32, 0.44) * (1.0 - layer * 0.1)
					var basis := Basis.from_euler(Vector3(rng.randf() * 0.5, atan2(-dir.y, dir.x) + rng.randf() * 0.6, rng.randf() * 0.4)).scaled(Vector3(sc * 1.3, sc, sc))
					xfs[rng.randi() % 3].append(Transform3D(basis, Vector3(q.x, y, q.y)))
	for k in 3:
		multimesh(self, meshes[k], mats.rock, xfs[k], [], quality == 2)
	# a fence along the inn's garden
	for i in 10:
		var p := Vector3(-31.0 + i * 1.6, 0, 13.5)
		p.y = height(p.x, p.z)
		box(self, Vector3(0.12, 1.1, 0.12), p + Vector3(0, 0.5, 0), mats.beam_v)
		if i < 9:
			box(self, Vector3(1.6, 0.08, 0.06), p + Vector3(0.8, 0.75, 0), mats.wood_h)
			box(self, Vector3(1.6, 0.08, 0.06), p + Vector3(0.8, 0.35, 0), mats.wood_h)

# ------------------------------------------------------------------ trees

func make_leaf_texture() -> ImageTexture:
	var S := 256
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.2, 0.3, 0.1, 0.0))
	var r := RandomNumberGenerator.new(); r.seed = 5
	for i in 420:
		var ang := r.randf() * TAU
		var dist := pow(r.randf(), 0.7) * S * 0.44
		var c := Vector2(S / 2.0, S / 2.0) + Vector2(cos(ang), sin(ang)) * dist
		var la := r.randf() * TAU
		var lw := r.randf_range(4.0, 7.0)
		var ll := r.randf_range(9.0, 15.0)
		var col := Color(r.randf_range(0.45, 0.75), r.randf_range(0.7, 1.0), r.randf_range(0.3, 0.5)) * r.randf_range(0.55, 1.0)
		var ax := Vector2(cos(la), sin(la))
		var ay := Vector2(-ax.y, ax.x)
		for y in range(int(c.y - ll), int(c.y + ll) + 1):
			for x in range(int(c.x - ll), int(c.x + ll) + 1):
				if x < 0 or y < 0 or x >= S or y >= S:
					continue
				var d := Vector2(x, y) - c
				var u := d.dot(ax) / ll
				var v := d.dot(ay) / lw
				if u * u + v * v <= 1.0:
					var shade := 0.8 + 0.2 * (1.0 - absf(v))
					img.set_pixel(x, y, Color(col.r * shade, col.g * shade, col.b * shade, 1.0))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

func tube(st: SurfaceTool, a: Vector3, b: Vector3, ra: float, rb: float, segs := 7) -> void:
	var ax := (b - a).normalized()
	var ref := Vector3.UP if abs(ax.y) < 0.9 else Vector3.RIGHT
	var u := ax.cross(ref).normalized()
	var v := ax.cross(u).normalized()
	var L := a.distance_to(b)
	for i in segs:
		var t0 := TAU * i / segs
		var t1 := TAU * (i + 1) / segs
		var d0 := u * cos(t0) + v * sin(t0)
		var d1 := u * cos(t1) + v * sin(t1)
		var p00 := a + d0 * ra; var p01 := a + d1 * ra
		var p10 := b + d0 * rb; var p11 := b + d1 * rb
		var uv00 := Vector2(float(i) / segs, 0); var uv01 := Vector2(float(i + 1) / segs, 0)
		var uv10 := Vector2(float(i) / segs, L); var uv11 := Vector2(float(i + 1) / segs, L)
		tri(st, p00, p10, p11, (d0 + d1).normalized(), uv00, uv10, uv11)
		tri(st, p00, p11, p01, (d0 + d1).normalized(), uv00, uv11, uv01)

func make_tree(seed_i: int) -> Array:
	var r := RandomNumberGenerator.new(); r.seed = seed_i
	var bark := SurfaceTool.new(); bark.begin(Mesh.PRIMITIVE_TRIANGLES)
	var leaves := SurfaceTool.new(); leaves.begin(Mesh.PRIMITIVE_TRIANGLES)
	var trunk_h := r.randf_range(3.2, 4.8)
	var base := Vector3.ZERO
	var top := Vector3(r.randf_range(-0.4, 0.4), trunk_h, r.randf_range(-0.4, 0.4))
	tube(bark, base - Vector3(0, 0.3, 0), top, 0.32, 0.2, 9)
	var clusters: Array = [top + Vector3(0, 1.6, 0)]
	var nb := r.randi_range(4, 6)
	for i in nb:
		var ang := TAU * i / nb + r.randf() * 0.6
		var start := base.lerp(top, r.randf_range(0.55, 0.95))
		var dir := Vector3(cos(ang), r.randf_range(0.5, 1.1), sin(ang)).normalized()
		var end := start + dir * r.randf_range(2.0, 3.4)
		tube(bark, start, end, 0.14, 0.06, 6)
		clusters.append(end + Vector3(0, 0.4, 0))
		var mid := start.lerp(end, 0.6)
		var sub := mid + (dir + Vector3(r.randf_range(-0.6, 0.6), 0.6, r.randf_range(-0.6, 0.6))).normalized() * 1.4
		tube(bark, mid, sub, 0.06, 0.03, 5)
		clusters.append(sub)
	for c in clusters:
		var rad := r.randf_range(1.3, 1.9)
		for k in 22:
			var d := Vector3(r.randf_range(-1, 1), r.randf_range(-0.7, 1), r.randf_range(-1, 1)).normalized()
			var p: Vector3 = c + d * rad * r.randf_range(0.2, 0.95)
			var nrm := (p - (c as Vector3) + Vector3(0, 0.3, 0)).normalized()
			var basis := Basis.from_euler(Vector3(r.randf() * TAU, r.randf() * TAU, r.randf() * TAU))
			var s := r.randf_range(1.3, 2.0)
			var ex := basis.x * s * 0.5; var ey := basis.y * s * 0.5
			var col := Color(1, 1, 1).darkened(r.randf() * 0.35)
			for tri_v in [[p - ex - ey, Vector2(0, 1)], [p + ex - ey, Vector2(1, 1)], [p + ex + ey, Vector2(1, 0)], [p - ex - ey, Vector2(0, 1)], [p + ex + ey, Vector2(1, 0)], [p - ex + ey, Vector2(0, 0)]]:
				leaves.set_color(col)
				leaves.set_normal(nrm)
				leaves.set_uv(tri_v[1])
				leaves.add_vertex(tri_v[0])
	bark.generate_tangents()
	return [bark.commit(), leaves.commit()]

func build_trees() -> void:
	var variants := [make_tree(11), make_tree(23), make_tree(37)]
	var bark_x := [[], [], []]
	var leaf_x := [[], [], []]
	var spots: Array = []
	# trees round the edge of the village
	for i in 26:
		var a := rng.randf() * TAU
		var rr := rng.randf_range(29.0, 44.0)
		spots.append(Vector2(cos(a) * rr, sin(a) * rr))
	# copses and hedgerow trees on the hills
	for c in [Vector2(-60, -55), Vector2(35, -50), Vector2(-85, 45), Vector2(85, 30), Vector2(10, -105), Vector2(-40, -110), Vector2(110, -60), Vector2(-120, -20)]:
		for i in 14:
			spots.append(c + Vector2(rng.randf_range(-14, 14), rng.randf_range(-14, 14)))
	for i in 40:
		var a := rng.randf() * TAU
		var rr := rng.randf_range(60.0, 150.0)
		spots.append(Vector2(cos(a) * rr, sin(a) * rr))
	for s in spots:
		var blocked := false
		for f in footprints:
			if (s as Vector2).distance_to(f[0]) < f[1] + 3.5:
				blocked = true
		for cpos in [Vector2(-50, 50), Vector2(-30, 44), Vector2(14, 22)]:
			if Geometry2D.get_closest_point_to_segment(s, cpos, Vector2.ZERO).distance_to(s) < 9.0:
				blocked = true
		if blocked or path_at(s.x, s.y) > 0.2 or s.length() < 27.0:
			continue
		var k := rng.randi() % 3
		var sc := rng.randf_range(0.85, 1.35)
		var xf := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * sc), Vector3(s.x, height(s.x, s.y) - 0.1, s.y))
		bark_x[k].append(xf)
		leaf_x[k].append(xf)
	for k in 3:
		multimesh(self, variants[k][0], mats.bark, bark_x[k], [])
		multimesh(self, variants[k][1], mats.leaf, leaf_x[k], [])

# ------------------------------------------------------------------ grass

func blade_clump() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r := RandomNumberGenerator.new(); r.seed = 9
	for b in 8:
		var ang := r.randf() * TAU
		var off := Vector3(r.randf_range(-0.12, 0.12), 0, r.randf_range(-0.12, 0.12))
		var h := r.randf_range(0.2, 0.45)
		var w := r.randf_range(0.012, 0.02)
		var lean := Vector3(cos(ang), 0, sin(ang)) * r.randf_range(0.05, 0.18)
		var side := Vector3(-sin(ang), 0, cos(ang))
		var nrm := Vector3(cos(ang), 0.4, sin(ang)).normalized()
		var segs := 3
		var prev_l: Vector3; var prev_r: Vector3; var prev_t := 0.0
		for s in segs + 1:
			var t := float(s) / segs
			var c := off + Vector3(0, h * t, 0) + lean * t * t
			var ww := w * (1.0 - t * 0.85)
			var l := c - side * ww
			var rr := c + side * ww
			if s > 0:
				for v in [[prev_l, prev_t, 0.0], [l, t, 0.0], [rr, t, 1.0], [prev_l, prev_t, 0.0], [rr, t, 1.0], [prev_r, prev_t, 1.0]]:
					st.set_normal(nrm)
					st.set_uv(Vector2(v[2], v[1]))
					st.add_vertex(v[0])
			prev_l = l; prev_r = rr; prev_t = t
	return st.commit()

func build_grass() -> void:
	var xfs: Array = []
	var cols: Array = []
	var target := int(args.get("grass", "42000"))
	var tries := 0
	while xfs.size() < target and tries < target * 4:
		tries += 1
		var rr := sqrt(rng.randf()) * 62.0
		var a := rng.randf() * TAU
		var x := cos(a) * rr
		var z := sin(a) * rr
		# denser on the green, thinner further out
		var keep := 1.0 if rr < 13.5 else lerpf(0.75, 0.3, clampf((rr - 13.5) / 50.0, 0, 1))
		if rng.randf() > keep:
			continue
		var pth := path_at(x, z)
		if pth > 0.35 or (pth > 0.15 and rng.randf() < 0.7):
			continue
		var blocked := false
		for f in footprints:
			if Vector2(x, z).distance_to(f[0]) < f[1]:
				blocked = true
				break
		if blocked:
			continue
		var sc := rng.randf_range(0.7, 1.35) * (0.8 if rr < 13.5 else 1.0)
		xfs.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(sc, sc * rng.randf_range(0.8, 1.3), sc)), Vector3(x, height(x, z) - 0.02, z)))
		var v := rng.randf_range(0.75, 1.15)
		cols.append(Color(v * rng.randf_range(0.9, 1.1), v, v * rng.randf_range(0.8, 1.0)))
	var mi := multimesh(self, blade_clump(), shader_mat("grass"), xfs, cols, false)
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	print("grass clumps: ", xfs.size())

# ------------------------------------------------------------------ sky lanterns

var lantern_from: Array = []
var lantern_to: Array = []
var lantern_delay: Array = []
var lantern_t := -1.0          # seconds since release; -1 before midnight
var lantern_lights: Array = []

func build_sky_lanterns() -> void:
	var cols: Array = []
	for i in 170:
		var y := 12.0 + pow(rng.randf(), 1.3) * 90.0
		var spread := 6.0 + y * 0.75
		var a := rng.randf() * TAU
		var rr := sqrt(rng.randf()) * spread
		var p := Vector3(cos(a) * rr + y * 0.35, y, sin(a) * rr - y * 0.25)
		var sc := rng.randf_range(0.9, 1.25)
		var basis := Basis(Vector3.UP, rng.randf() * TAU).rotated(Vector3.RIGHT, rng.randf_range(-0.1, 0.1)).scaled(Vector3.ONE * sc)
		lantern_to.append(Transform3D(basis, p))
		var ga := rng.randf() * TAU
		var gr := sqrt(rng.randf()) * 10.0
		lantern_from.append(Transform3D(basis, Vector3(cos(ga) * gr, 1.4, sin(ga) * gr)))
		lantern_delay.append(rng.randf() * 3.0)
		cols.append(Color(1.0, rng.randf_range(0.4, 0.62), rng.randf_range(0.1, 0.22), rng.randf()))
	paper_mm = multimesh(self, lantern_mesh(), mats.lantern, lantern_from, cols, false)
	paper_mm.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	paper_mm.visible = false
	# light from the lowest few, following them up
	var order := range(lantern_to.size())
	order.sort_custom(func(a, b): return lantern_to[a].origin.y < lantern_to[b].origin.y)
	for k in 6:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.55, 0.22)
		l.light_energy = 0.9
		l.omni_range = 7.0
		l.visible = false
		add_child(l)
		lantern_lights.append([l, order[k]])

# ------------------------------------------------------------------ the Sigilfall

func build_sigilfall() -> void:
	var palette := [Color(1.0, 0.25, 0.12), Color(1.0, 0.55, 0.12), Color(1.0, 0.85, 0.35), Color(0.35, 0.7, 1.0),
		Color(0.65, 0.3, 1.0), Color(0.2, 1.0, 0.8), Color(0.45, 1.0, 0.3), Color(1.0, 0.35, 0.7)]
	var fall := Vector3(0.28, -1.0, 0.16).normalized()
	var n: int = [16, 30, 46][quality]
	for i in n:
		var col: Color = palette[i % palette.size()]
		var head := Vector3(rng.randf_range(-150, 170), rng.randf_range(25, 190), rng.randf_range(-260, 30))
		if i < 6:
			head = Vector3(rng.randf_range(-70, 70), rng.randf_range(8, 30), rng.randf_range(-90, -35))
		add_streak(head, fall, rng.randf_range(18, 55), col, i < [4, 8, 12][quality])
	# the white light: slow, silent, heading for the player
	white_light = Node3D.new()
	white_light.visible = false
	add_child(white_light)
	var core := SphereMesh.new(); core.radius = 0.12; core.height = 0.24
	var wm := StandardMaterial3D.new()
	wm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wm.albedo_color = Color(1, 1, 1)
	add_mesh(white_light, core, wm, Transform3D.IDENTITY, false)
	glow_sprite(white_light, Vector3.ZERO, Color(0.9, 0.95, 1.0), 2.6, 1.6)
	glow_sprite(white_light, Vector3.ZERO, Color(0.7, 0.8, 1.0), 8.0, 0.22)
	var wl := OmniLight3D.new()
	wl.light_color = Color(0.85, 0.9, 1.0)
	wl.light_energy = 1.6
	wl.omni_range = 16.0
	wl.light_volumetric_fog_energy = 0.6
	white_light.add_child(wl)
	var trail := MeshInstance3D.new()
	trail.mesh = QuadMesh.new()
	trail.material_override = mats.streak
	trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	trail.transform = Transform3D(Basis(Vector3(0.6, 0, 0), Vector3(0, 9, 0), Vector3(0, 0, 1)), Vector3(0, 4.5, 0))
	trail.set_instance_shader_parameter("col", Color(0.8, 0.9, 1.0))
	trail.set_instance_shader_parameter("intensity", 2.0)
	white_light.add_child(trail)

func add_streak(head: Vector3, fall: Vector3, length: float, col: Color, with_light: bool) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = QuadMesh.new()
	mi.material_override = mats.streak
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	var width := clampf(length / 40.0, 0.6, 1.4) * (2.0 if head.y > 80 else 1.0)
	mi.transform = Transform3D(Basis(Vector3(width, 0, 0), -fall * length, Vector3(0, 0, 1)), head - fall * length * 0.5)
	mi.set_instance_shader_parameter("col", col)
	mi.set_instance_shader_parameter("intensity", 7.0)
	mi.visible = false
	add_child(mi)
	var gs := glow_sprite(self, head, col, 1.6 + width * 1.2, 1.1)
	gs.visible = false
	var l: OmniLight3D = null
	if with_light:
		l = OmniLight3D.new()
		l.light_color = col
		l.light_energy = 6.0 if head.y < 40 else 3.0
		l.omni_range = 45.0
		l.omni_attenuation = 1.2
		l.position = head
		l.visible = false
		add_child(l)
	streaks.append({"node": mi, "glow": gs, "light": l, "dir": fall, "len": length, "head": head,
		"speed": rng.randf_range(40.0, 70.0), "width": width})

func impact(at: Vector3, col: Color) -> void:
	glow_sprite(self, at + Vector3(0, 0.6, 0), Color(1.0, 0.5, 0.2), 2.2, 0.5)
	var l := OmniLight3D.new()
	l.light_color = col.lerp(Color(1, 0.9, 0.7), 0.4)
	l.light_energy = 3.0
	l.omni_range = 26.0
	l.light_volumetric_fog_energy = 0.15
	l.shadow_enabled = true
	l.position = at + Vector3(0, 1.5, 0)
	add_child(l)
	flicker_lights.append([l, 12.0])
	var sp := GPUParticles3D.new()
	sp.amount = 160
	sp.lifetime = 1.6
	sp.preprocess = 0.0
	sp.position = at + Vector3(0, 0.3, 0)
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 70.0
	pm.initial_velocity_min = 4.0
	pm.initial_velocity_max = 13.0
	pm.gravity = Vector3(0, -9.0, 0)
	pm.scale_min = 0.06
	pm.scale_max = 0.16
	sp.process_material = pm
	var q := QuadMesh.new(); q.size = Vector2(1, 1)
	sp.draw_pass_1 = q
	var em: ShaderMaterial = mats.ember.duplicate()
	em.set_shader_parameter("ember_col", col.lerp(Color(1, 0.9, 0.6), 0.5))
	em.set_shader_parameter("intensity", 25.0)
	sp.material_override = em
	sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sp.visibility_aabb = AABB(Vector3(-20, -2, -20), Vector3(40, 20, 40))
	add_child(sp)
	# scorched ground
	var dm := QuadMesh.new(); dm.size = Vector2(4.5, 4.5); dm.orientation = PlaneMesh.FACE_Y
	var scorch := StandardMaterial3D.new()
	scorch.albedo_color = Color(0.01, 0.008, 0.006)
	scorch.emission_enabled = true
	scorch.emission = Color(0.9, 0.18, 0.02)
	scorch.emission_energy_multiplier = 0.35
	scorch.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var g := Gradient.new(); g.set_color(0, Color(1, 1, 1, 1)); g.set_color(1, Color(1, 1, 1, 0))
	var gt := GradientTexture2D.new(); gt.gradient = g; gt.fill = GradientTexture2D.FILL_RADIAL; gt.fill_from = Vector2(0.5, 0.5); gt.fill_to = Vector2(0.5, 0.0)
	scorch.albedo_texture = gt
	scorch.emission_texture = gt
	add_mesh(self, dm, scorch, Transform3D(Basis(), at + Vector3(0, 0.08, 0)), false)
	fire_at(at + Vector3(0, 0.1, 0), Vector3(1.4, 0.3, 1.4), 28, 0.8)

# ------------------------------------------------------------------ fire

func fire_at(at: Vector3, extents: Vector3, amount: int, scale_k: float, grow := false) -> void:
	var f := GPUParticles3D.new()
	f.amount = amount
	f.lifetime = 1.1
	f.preprocess = 0.0 if grow else 1.1
	f.position = at
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = extents
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 10.0
	pm.initial_velocity_min = 1.0
	pm.initial_velocity_max = 2.4
	pm.gravity = Vector3(0, 2.0, 0)
	pm.scale_min = 1.1 * scale_k
	pm.scale_max = 2.0 * scale_k
	pm.angle_min = -180; pm.angle_max = 180
	f.process_material = pm
	var q := QuadMesh.new(); q.size = Vector2(0.9, 1.4)
	f.draw_pass_1 = q
	f.draw_order = GPUParticles3D.DRAW_ORDER_VIEW_DEPTH
	f.material_override = mats.flame
	f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	f.visibility_aabb = AABB(Vector3(-15, -2, -15), Vector3(30, 20, 30))
	add_child(f)
	var e := GPUParticles3D.new()
	e.amount = int(amount * 2.5)
	e.lifetime = 3.5
	e.preprocess = 0.0 if grow else 3.5
	e.position = at + Vector3(0, 1.0, 0)
	var em := ParticleProcessMaterial.new()
	em.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	em.emission_box_extents = extents
	em.direction = Vector3(0.3, 1, 0.1)
	em.spread = 25.0
	em.initial_velocity_min = 2.0
	em.initial_velocity_max = 5.0
	em.gravity = Vector3(0.6, 0.6, 0.2)
	em.turbulence_enabled = true
	em.turbulence_noise_strength = 3.0
	em.turbulence_noise_scale = 3.0
	em.scale_min = 0.04
	em.scale_max = 0.1
	e.process_material = em
	var eq := QuadMesh.new(); eq.size = Vector2(1, 1)
	e.draw_pass_1 = eq
	e.material_override = mats.ember
	e.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	e.visibility_aabb = AABB(Vector3(-20, -2, -20), Vector3(40, 30, 40))
	add_child(e)
	var s := GPUParticles3D.new()
	s.amount = int(amount * 0.6)
	s.lifetime = 7.0
	s.preprocess = 0.0 if grow else 7.0
	s.position = at + Vector3(0, 1.8, 0)
	var smm := ParticleProcessMaterial.new()
	smm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	smm.emission_box_extents = extents
	smm.direction = Vector3(0.25, 1, 0.1)
	smm.spread = 15.0
	smm.initial_velocity_min = 1.5
	smm.initial_velocity_max = 2.8
	smm.gravity = Vector3(0.5, 0.3, 0.15)
	smm.scale_min = 2.5 * scale_k
	smm.scale_max = 4.0 * scale_k
	var sc := Curve.new(); sc.add_point(Vector2(0, 0.5)); sc.add_point(Vector2(1, 2.2))
	var sct := CurveTexture.new(); sct.curve = sc
	smm.scale_curve = sct
	smm.angle_min = -180; smm.angle_max = 180
	s.process_material = smm
	var sq := QuadMesh.new(); sq.size = Vector2(1, 1)
	s.draw_pass_1 = sq
	s.material_override = mats.smoke
	s.draw_order = GPUParticles3D.DRAW_ORDER_VIEW_DEPTH
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	s.visibility_aabb = AABB(Vector3(-30, -2, -30), Vector3(60, 50, 60))
	add_child(s)
	for k in 2:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.45, 0.12)
		l.light_energy = 5.0 * scale_k
		l.omni_range = 18.0
		l.shadow_enabled = k == 0
		l.light_volumetric_fog_energy = 0.2
		l.position = at + Vector3(rng.randf_range(-1, 1), 1.5 + k, rng.randf_range(-1, 1))
		add_child(l)
		flicker_lights.append([l, 5.0 * scale_k])

# ------------------------------------------------------------------ mist and post

func build_mist() -> void:
	var fv := FogVolume.new()
	fv.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
	fv.size = Vector3(260, 10, 260)
	fv.position = Vector3(0, 3.0, -30)
	fv.material = shader_mat("mist", {"density": 0.014, "top": 4.0})
	add_child(fv)

func build_post() -> void:
	var cl := CanvasLayer.new()
	cl.layer = -1
	var cr := ColorRect.new()
	cr.set_anchors_preset(Control.PRESET_FULL_RECT)
	cr.material = shader_mat("post", {"grain": 0.012, "aberration": 0.0002, "vignette": 0.24})
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(cr)
	add_child(cl)

# ------------------------------------------------------------------ collisions

func solid_box(center: Vector3, size: Vector3, yaw := 0.0) -> void:
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	b.add_child(cs)
	b.transform = Transform3D(Basis(Vector3.UP, yaw), center)
	add_child(b)

func solid_round(center: Vector3, radius: float) -> void:
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var c := CylinderShape3D.new()
	c.radius = radius
	c.height = 3.0
	cs.shape = c
	b.add_child(cs)
	b.position = Vector3(center.x, 1.5, center.z)
	add_child(b)

# ------------------------------------------------------------------ midnight

## Sends the sky lanterns up from the green; phase_done("lanterns") when they hang still.
func release_lanterns() -> void:
	paper_mm.visible = true
	for ll in lantern_lights:
		ll[0].visible = true
	lantern_t = 0.0

## The sky tears and the Sigils start to fall.
var sigil_on := false
var sigil_t := 0.0
var tear := 0.0
var tear_target := 0.0
func start_sigilfall() -> void:
	sigil_on = true
	sigil_t = 0.0
	tear_target = 1.0
	for st in streaks:
		st.node.visible = true
		st.glow.visible = true
		if st.light:
			st.light.visible = true

## A Sigil lands in the field beyond the north-west houses.
func first_impact() -> void:
	var at := Vector3(-33, height(-33, -32), -32)
	add_streak(at + Vector3(0, 1.5, 0), Vector3(0.28, -1.0, 0.16).normalized(), 40, Color(1.0, 0.45, 0.15), true)
	var st: Dictionary = streaks[-1]
	st.node.visible = true
	st.glow.visible = true
	st.speed = 0.0
	if st.light:
		st.light.visible = true
	impact(at, Color(1.0, 0.45, 0.15))

## The thatch of the north-west cottage catches.
func ignite_roof() -> void:
	if burning_house == null:
		return
	var d: Array = get_meta("burning_dims")
	var at := burning_house.to_global(Vector3(d[0] * 0.18, d[2] + d[3] + 0.25, 0.0))
	fire_at(at, Vector3(d[0] * 0.3, 0.3, d[1] * 0.3), [30, 45, 60][quality], 1.1, true)

## Every other light in the sky goes out; the tear stays as a scar.
var sky_dim := 1.0
var sky_dim_target := 1.0
func lights_out() -> void:
	sky_dim_target = 0.0
	tear_target = 0.35

var white_from := Vector3.ZERO
var white_to := Vector3.ZERO
var white_dur := 1.0
var white_t := -1.0
## The white light drifts down to `to` over `seconds`; phase_done("white") when it arrives.
func send_white_light(to: Vector3, seconds: float) -> void:
	white_to = to
	white_from = to + Vector3(-3.0, 20.0, -6.0)
	white_dur = seconds
	white_t = 0.0
	white_light.position = white_from
	white_light.visible = true

func hide_white_light() -> void:
	white_light.visible = false

# ------------------------------------------------------------------ per frame

var player_light: OmniLight3D
func _process(delta: float) -> void:
	elapsed += delta
	var w := get_parent()
	if w is World and w.player != null:
		if player_light == null:
			player_light = OmniLight3D.new()
			player_light.light_color = Color(1.0, 0.78, 0.55)
			player_light.light_energy = 0.9
			player_light.omni_range = 7.0
			player_light.shadow_enabled = false
			add_child(player_light)
		player_light.global_position = w.player.global_position + Vector3(0, 2.4, 0.8)
	for fl in flicker_lights:
		var l: OmniLight3D = fl[0]
		l.light_energy = fl[1] * (0.82 + 0.18 * sin(elapsed * 13.0 + fl[1]) * sin(elapsed * 7.3 + fl[1] * 2.0))
	if lantern_t >= 0.0:
		_rise_lanterns(delta)
	if absf(tear - tear_target) > 0.001:
		tear = move_toward(tear, tear_target, delta * 0.45)
		sky_mat.set_shader_parameter("tear_open", tear * tear * (3.0 - 2.0 * tear))
	if absf(sky_dim - sky_dim_target) > 0.001:
		sky_dim = move_toward(sky_dim, sky_dim_target, delta * 0.8)
		mats.lantern.set_shader_parameter("energy", (1.3 if quality == 0 else 2.2) * sky_dim)
		for st in streaks:
			st.node.set_instance_shader_parameter("intensity", 7.0 * sky_dim)
			st.glow.set_instance_shader_parameter("intensity", 1.1 * sky_dim)
			if st.light:
				st.light.light_energy = (6.0 if st.head.y < 40 else 3.0) * sky_dim
		for ll in lantern_lights:
			ll[0].light_energy = 0.9 * sky_dim
	if sigil_on:
		sigil_t += delta
		for st in streaks:
			var head: Vector3 = st.head + st.dir * st.speed * 0.35 * sigil_t
			var guard := 0
			while head.y < height(head.x, head.z) and guard < 4:
				head -= st.dir * 200.0
				guard += 1
			st.node.global_position = head - st.dir * st.len * 0.5
			st.glow.global_position = head
			if st.light:
				st.light.global_position = head
	if white_t >= 0.0:
		white_t += delta
		var u := clampf(white_t / white_dur, 0.0, 1.0)
		var e := 1.0 - pow(1.0 - u, 2.2)
		white_light.position = white_from.lerp(white_to, e) + Vector3(sin(elapsed * 1.3) * 0.25, 0, cos(elapsed * 1.1) * 0.25) * (1.0 - e)
		if u >= 1.0:
			white_t = -1.0
			phase_done.emit("white")

func _rise_lanterns(delta: float) -> void:
	lantern_t += delta
	var done := true
	for i in lantern_from.size():
		var u := clampf((lantern_t - float(lantern_delay[i])) / 9.0, 0.0, 1.0)
		if u < 1.0:
			done = false
		var e := 1.0 - pow(1.0 - u, 2.4)
		var a: Transform3D = lantern_from[i]
		var b: Transform3D = lantern_to[i]
		var p := a.origin.lerp(b.origin, e) + Vector3(sin(elapsed + i) * 0.15, 0, cos(elapsed * 0.8 + i) * 0.15) * u
		paper_mm.multimesh.set_instance_transform(i, Transform3D(b.basis, p))
	for ll in lantern_lights:
		var k: int = ll[1]
		var u2 := clampf((lantern_t - float(lantern_delay[k])) / 9.0, 0.0, 1.0)
		ll[0].position = (lantern_from[k] as Transform3D).origin.lerp((lantern_to[k] as Transform3D).origin, 1.0 - pow(1.0 - u2, 2.4))
	if done:
		lantern_t = -1.0
		phase_done.emit("lanterns")
