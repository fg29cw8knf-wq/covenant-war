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
var quality := 2             # 2 full (Mac/PC), 1 phone, 0 phone link (web): Gfx.level()
var burning_house: Node3D
var elapsed := 0.0
## The Great Lantern on the green (Gary's model, scaled up to stand over the
## crowd). The light inside is the candle, lit at midnight.
const GREAT_LANTERN_MODEL := "res://assets/models/ashford/great_lantern.glb"
const GREAT_LANTERN_SCALE := 2.4
const GREAT_LANTERN_CANDLE := 3.4      # the candle flame's height in the model, in metres
var great_lantern_top := Vector3.ZERO
var great_lantern_light: OmniLight3D
var great_lantern_glow: MeshInstance3D
var festival_light: OmniLight3D
## Tam's chore: the cider barrel by the hay cart, and where it goes at Tilly's stall.
var tam_barrel: Node3D
var barrel_spot := Vector3.ZERO
## Tam's hay cart, and how it stands before the Sigilfall knocks it over.
const HAY_CART_YAW := 2.07
const HAY_CART_HALF_WIDTH := 1.25   # centre to the outside of a wheel
var hay_cart: Node3D
var hay_cart_rest := Transform3D.IDENTITY
var hay_cart_tip := 0.0
## The festival stalls on the green: Tilly's red one, and the blue one.
var stalls: Array = []
## The traders' carts lining the green's west side (Gary's merchant_cart_a.glb,
## 26 October: a cart with a striped awning, 3.5 m long with its shafts; his
## second cart, merchant_cart_b.glb, takes the second place when it comes),
## where Corin sells his signed cards in the afternoon; the shockwave throws
## them over at midnight (shatter_carts).
var merchant_carts: Array = []


## Built a piece a frame (build_spread()) rather than all at once in _ready:
## a world made ahead of time under the title screen (World.prepare).
var spread := false


func _ready() -> void:
	if spread:
		return   # build_spread() does it
	_build()


func build_spread() -> void:
	spread = true
	await _build()


## A frame's rest between the pieces of a spread build (none otherwise).
func _breath() -> void:
	if spread and is_inside_tree():
		await get_tree().process_frame


func _build() -> void:
	var t0 := Time.get_ticks_msec()
	quality = Gfx.level()   # phones play the lighter level 1 unless set to Full
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
	await _breath()
	build_terrain()
	await _breath()
	await build_village()
	await _breath()
	build_green()
	await _breath()
	build_walls_and_fences()
	await _breath()
	build_trees()
	await _breath()
	build_grass()
	build_props()
	await _breath()
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

var moon_light: DirectionalLight3D
var tear_light: DirectionalLight3D

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
	moon_light = moon
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
	tear_light = tear
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

## The terrain mesh: a grid TERRAIN_N squares a side over +-TERRAIN_HALF metres,
## fine near the green and coarser further out (ground_y() follows it exactly).
const TERRAIN_N := 230
const TERRAIN_HALF := 520.0
const TERRAIN_SPREAD := 1.9

func build_terrain() -> void:
	var N := TERRAIN_N
	var coords := PackedFloat32Array()
	for i in N + 1:
		coords.append(_terrain_line(i))
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

## Where grid line `i` of the terrain mesh runs (the same on x and z).
func _terrain_line(i: int) -> float:
	var t := float(i) / TERRAIN_N * 2.0 - 1.0
	return sign(t) * pow(abs(t), TERRAIN_SPREAD) * TERRAIN_HALF

## The grid square of the terrain mesh that `x` (or z) falls in.
func _terrain_square(x: float) -> int:
	var t := signf(x) * pow(absf(x) / TERRAIN_HALF, 1.0 / TERRAIN_SPREAD)
	var i := clampi(int(floor((t + 1.0) * 0.5 * TERRAIN_N)), 0, TERRAIN_N - 1)
	# step past any rounding at a grid line
	if x < _terrain_line(i):
		i = maxi(i - 1, 0)
	elif x > _terrain_line(i + 1):
		i = mini(i + 1, TERRAIN_N - 1)
	return i

## The ground as it is drawn: the terrain mesh is flat triangles between its
## grid points, so far out, where the squares are a few metres across, it can
## sit a little above or below height(). Things set down out there use this.
func ground_y(x: float, z: float) -> float:
	var i := _terrain_square(x)
	var j := _terrain_square(z)
	var x0 := _terrain_line(i)
	var x1 := _terrain_line(i + 1)
	var z0 := _terrain_line(j)
	var z1 := _terrain_line(j + 1)
	var u := clampf((x - x0) / (x1 - x0), 0.0, 1.0)
	var w := clampf((z - z0) / (z1 - z0), 0.0, 1.0)
	var ha := height(x0, z0)
	var hb := height(x1, z0)
	var hc := height(x0, z1)
	var hd := height(x1, z1)
	# each square is two triangles, (a b c) and (b d c), as build_terrain makes them
	if u + w <= 1.0:
		return ha + (hb - ha) * u + (hc - ha) * w
	return hd + (hc - hd) * (1.0 - u) + (hb - hd) * (1.0 - w)

## The lowest drawn ground under a round base of `radius` at `at`, so nothing
## set down on a slope is left with an edge in the air.
func ground_under(at: Vector3, radius: float) -> float:
	var lo := ground_y(at.x, at.z)
	for k in 12:
		var a := TAU * k / 12.0
		lo = minf(lo, ground_y(at.x + cos(a) * radius, at.z + sin(a) * radius))
	return lo

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
		# Gary's painted cottages where they exist, the drawn stand-in otherwise
		var mid: String = RING_MODELS[i]
		if mid == "" and ResourceLoader.exists("res://assets/models/ashford/inn.glb"):
			continue   # the inn's model is bigger than the drawn one and fills this plot
		if not model_house(mid, pos, i, i == 4):
			house(pos, p[2], p[3], p[4], p[5], doors[i % 4], i, i == 4)
		if i % 3 == 2:
			await _breath()
	# the Crooked Lantern inn, two storeys, on the west side
	var inn_pos := Vector3(-24.0, 0.0, 6.0)
	if not model_house("inn", inn_pos, 99, false):
		house(inn_pos, 11.0, 6.4, 4.8, 0, "green", 99, false, true)
	await _breath()
	# farmhouses dotted over the hills, lights in their windows
	for f in [Vector3(-70, 0, -40), Vector3(48, 0, 46), Vector3(95, 0, -30), Vector3(-95, 0, 20), Vector3(-30, 0, -95), Vector3(20, 0, -120)]:
		if not model_house("cottage_b", f, 200 + int(f.x), false):
			house(f, 7.0, 5.0, 2.6, 1, "natural", 200 + int(f.x), false)
	await _breath()
	build_mill(MILL_SPOT)


## Which of Gary's cottages stands on each plot round the green (the fifth,
## north-west, is the one whose thatch catches at the Sigilfall; the sixth
## is left to the Crooked Lantern).
const RING_MODELS := ["cottage_c", "cottage_a", "cottage_b", "cottage_c", "cottage_a", "",
	"cottage_c", "cottage_a", "cottage_b", "cottage_c", "cottage_a"]
## Warm light behind the windows: each model has <id>_glow.png, a mask of its
## glass made from its colour atlas, used as the emission texture.
const WINDOW_GLOW := Color(1.0, 0.6, 0.28)
var _model_info := {}   # model id -> its chimney top (measured once)
## The houses' window glow materials ([material, its night energy]) and the
## lights at their doors, which the daylight turns down (set_daylight).
var window_mats: Array = []
var house_lights: Array = []
## The festival night as built, kept so the daylight can blend back into it
## (Master Script v7: P1 is a frosty morning and an afternoon, and the
## lanterns are lit as the sun drops behind the mill).
var _night := {}
var daylight := 0.0
## Every building model placed: {id, root, L, D, top, inn}, for setting them alight.
var houses: Array = []

## Places one of Gary's building models (assets/models/ashford/<id>.glb) facing
## the green, with lit windows, a porch light and chimney smoke. Returns false
## when the model isn't there, so the drawn stand-in is built instead.
func model_house(id: String, pos: Vector3, seed_i: int, burning: bool) -> bool:
	var path := "res://assets/models/ashford/%s.glb" % id
	if not ResourceLoader.exists(path):
		return false
	var scene: PackedScene = load(path)
	var root := Node3D.new()
	pos.y = height(pos.x, pos.z) - 0.08
	root.position = pos
	var to_c := -Vector2(pos.x, pos.z).normalized()
	root.rotation.y = atan2(to_c.x, to_c.y)
	add_child(root)
	var inst: Node3D = scene.instantiate()
	root.add_child(inst)
	var glow_path := "res://assets/models/ashford/%s_glow.png" % id
	var glow: Texture2D = load(glow_path) if ResourceLoader.exists(glow_path) else null
	var box := AABB()
	var first := true
	var measure := not _model_info.has(id)
	var top_v := Vector3(0, -1, 0)    # the highest vertex: the chimney
	for mi: MeshInstance3D in inst.find_children("*", "MeshInstance3D", true, false):
		var xf := root.global_transform.affine_inverse() * mi.global_transform
		var b := xf * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		for s in mi.mesh.get_surface_count():
			if measure:
				var verts: PackedVector3Array = mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
				for v in verts:
					var w := xf * v
					if w.y > top_v.y:
						top_v = w
			var m := mi.get_active_material(s)
			if glow != null and m is StandardMaterial3D:
				var gm: StandardMaterial3D = m.duplicate()
				gm.emission_enabled = true
				gm.emission = WINDOW_GLOW
				gm.emission_energy_multiplier = 2.2 + (seed_i % 5) * 0.25
				gm.emission_texture = glow
				gm.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
				mi.set_surface_override_material(s, gm)
				window_mats.append([gm, gm.emission_energy_multiplier])
	if measure:
		_model_info[id] = top_v
	top_v = _model_info[id]
	var L := box.size.x
	var D := box.size.z
	var top := box.end.y
	var mid := Vector2(box.get_center().x, box.get_center().z).rotated(-root.rotation.y)
	var centre := Vector3(pos.x + mid.x, 0.0, pos.z + mid.y)
	footprints.append([Vector2(centre.x, centre.z), max(L, D) * 0.56])
	solid_box(Vector3(centre.x, 1.5, centre.z), Vector3(L + 0.3, 3.0, D + 0.3), root.rotation.y)
	# a warm light at the door and one behind, so the house reads at night
	for spot in [Vector3(-0.8, 2.2, box.end.z + 0.7), Vector3(0.6, 2.0, box.position.z - 0.8)]:
		var ll := OmniLight3D.new()
		ll.light_color = Color(1.0, 0.62, 0.3)
		ll.light_energy = 1.3 if spot.z > 0 else 0.7
		ll.omni_range = 7.0
		ll.omni_attenuation = 1.4
		ll.position = spot
		root.add_child(ll)
		house_lights.append(ll)
	if top_v.y > 0.0 and not burning:
		chimney_smoke(root, top_v + Vector3(0, 0.15, 0))
	if burning:
		burning_house = root
		# ignite_roof() reads these as length, depth, wall height and roof rise
		set_meta("burning_dims", [L, D, top * 0.5, top * 0.33 - 0.25])
	houses.append({"id": id, "root": root, "L": L, "D": D, "top": top, "inn": id == "inn"})
	return true

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

## The windmill on the hill north-east of the green: Gary's whitewashed tower
## (mill_tower.glb, 8.15 m to the tip of its thatch, origin at the middle of
## its base, door and sail hub facing +Z) with his sails (mill_sails.glb,
## 9.76 m across, origin at their hub) on its windshaft, or the drawn stand-in.
## The sails turn steadily, anticlockwise seen from the front as English mills
## do, until the Sigil sets the thatch alight at midnight; then they slow to a
## stop, and stay stopped for the rest of the Prologue (dawn, the night Ashford
## burns, the Thornwood).
const MILL_TOWER_MODEL := "res://assets/models/ashford/mill_tower.glb"
const MILL_SAILS_MODEL := "res://assets/models/ashford/mill_sails.glb"
## The mill faces west-south-west: into the west wind that carries the smoke
## east, and turned enough towards the village that its sails show from the green.
const MILL_YAW := -0.87
## The flat top of the hill north-east of the green, at the end of the lane
## (the ground under the tower's foot is level to within about 10 cm there).
const MILL_SPOT := Vector3(66.0, 0.0, -79.0)
const MILL_BASE_RADIUS := 1.75      # the tower's foot, for standing it on the slope
const MILL_HUB := Vector3(0.0, 6.91, 2.045)   # the sails' hub on the tower's windshaft (Gary's notes)
const MILL_THATCH := Vector3(0.0, 7.0, 0.0)   # the middle of the thatched cap, where the fire takes
## A turn every ten seconds (6 rpm): a working mill in an evening breeze.
const MILL_TURN := TAU / 10.0
const MILL_STOPPING := 14.0         # seconds the sails take to run down once the cap is alight
var mill_root: Node3D
var mill_sails: Node3D              # turns about its own Z (the windshaft)
var mill_spin := MILL_TURN          # radians a second now
var mill_spin_to := MILL_TURN       # what it is easing towards (0 once the mill has burned)
var mill_thatch := Vector3(0, 10.2, 0)   # the cap's middle, in mill_root's space (the drawn mill's here)
var mill_fire_box := Vector3(1.6, 0.6, 1.6)   # how far round that the flames start: about to the eaves

func build_mill(pos: Vector3) -> void:
	var root := Node3D.new()
	root.name = "Mill"
	mill_root = root
	if ResourceLoader.exists(MILL_TOWER_MODEL):
		# stood on the lowest ground under its foot, a few centimetres down, so
		# no edge of the base floats where the hill falls away
		pos.y = ground_under(pos, MILL_BASE_RADIUS) - 0.06
		root.position = pos
		root.rotation.y = MILL_YAW
		add_child(root)
		var tower: Node3D = load(MILL_TOWER_MODEL).instantiate()
		root.add_child(tower)
		for mi: MeshInstance3D in tower.find_children("*", "MeshInstance3D", true, false):
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		mill_thatch = MILL_THATCH
		mill_fire_box = Vector3(1.1, 0.45, 1.1)
		if ResourceLoader.exists(MILL_SAILS_MODEL):
			var hub := Node3D.new()
			hub.name = "Sails"
			hub.position = MILL_HUB
			hub.rotation.z = 0.35
			root.add_child(hub)
			var sails: Node3D = load(MILL_SAILS_MODEL).instantiate()
			hub.add_child(sails)
			for mi: MeshInstance3D in sails.find_children("*", "MeshInstance3D", true, false):
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			mill_sails = hub
		solid_round(pos, MILL_BASE_RADIUS)
		return
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
	mill_sails = hub

## The middle of the mill's thatched cap, in the world: where the Sigil
## strikes, the fire burns and the film looks.
func mill_fire_point() -> Vector3:
	return mill_root.to_global(mill_thatch)

## Stops the sails where they are (the mill has burned).
func stop_mill() -> void:
	mill_spin = 0.0
	mill_spin_to = 0.0

func _turn_mill(delta: float) -> void:
	if mill_sails == null:
		return
	if mill_spin != mill_spin_to:
		mill_spin = move_toward(mill_spin, mill_spin_to, MILL_TURN / MILL_STOPPING * delta)
	if mill_spin > 0.0:
		mill_sails.rotation.z = fposmod(mill_sails.rotation.z + mill_spin * delta, TAU)

# ------------------------------------------------------------------ the green

func build_green() -> void:
	var g := Node3D.new()
	add_child(g)
	# the Great Lantern: Gary's model where it exists, the drawn pole otherwise.
	# It stays dark until midnight, when the Lantern Duel's winner lights it.
	var lp := Vector3(0.0, height(0, 0), 0.0)
	var top := lp + Vector3(0, 10.35, 0)
	var anchor := top + Vector3(0, -1.1, 0)   # where the bunting strings meet
	var pole_h := 9.0
	if ResourceLoader.exists(GREAT_LANTERN_MODEL):
		var gr := Node3D.new()
		gr.name = "GreatLantern"
		gr.position = lp - Vector3(0, 0.05, 0)
		gr.scale = Vector3.ONE * GREAT_LANTERN_SCALE
		g.add_child(gr)
		var inst: Node3D = load(GREAT_LANTERN_MODEL).instantiate()
		gr.add_child(inst)
		for mi: MeshInstance3D in inst.find_children("*", "MeshInstance3D", true, false):
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		solid_round(lp, 0.62 * GREAT_LANTERN_SCALE)
		footprints.append([Vector2(lp.x, lp.z), 0.75 * GREAT_LANTERN_SCALE])
		top = lp + Vector3(0, GREAT_LANTERN_CANDLE * GREAT_LANTERN_SCALE, 0)
		anchor = lp + Vector3(0, 2.66 * GREAT_LANTERN_SCALE, 0)
		pole_h = anchor.y + 0.5
	else:
		solid_round(lp, 0.45)
		cyl(g, 0.12, 0.18, 10.0, lp + Vector3(0, 5.0, 0), mats.beam_v, 10)
		box(g, Vector3(1.8, 0.12, 0.12), lp + Vector3(0, 9.2, 0), mats.beam)
		box(g, Vector3(0.12, 0.12, 1.8), lp + Vector3(0, 9.2, 0), mats.beam)
		box(g, Vector3(0.62, 0.8, 0.62), top, mats.lamp_glass)
		for sx in [-1, 1]:
			for sz in [-1, 1]:
				box(g, Vector3(0.07, 0.9, 0.07), top + Vector3(0.33 * sx, 0, 0.33 * sz), mats.metal)
		cyl(g, 0.05, 0.62, 0.45, top + Vector3(0, 0.62, 0), mats.metal, 4, Vector3(0, PI / 4, 0))
	great_lantern_top = top
	var gl := OmniLight3D.new()
	gl.light_color = Color(1.0, 0.6, 0.28)
	gl.light_energy = 0.0
	gl.light_volumetric_fog_energy = 0.6
	gl.omni_range = 26.0
	gl.omni_attenuation = 1.3
	gl.shadow_enabled = true
	gl.light_size = 0.3
	gl.position = top
	gl.visible = false
	g.add_child(gl)
	great_lantern_light = gl
	great_lantern_glow = glow_sprite(g, top, Color(1.0, 0.5, 0.2), 1.6, 0.5)
	great_lantern_glow.visible = false
	# until midnight the green is lit by its festival lights: a softer, lower glow
	var fest := OmniLight3D.new()
	fest.light_color = Color(1.0, 0.66, 0.36)
	fest.light_energy = 2.6
	fest.omni_range = 20.0
	fest.omni_attenuation = 1.5
	fest.position = lp + Vector3(0, 5.5, 0)
	g.add_child(fest)
	festival_light = fest
	# bunting and fairy lights from the lantern to poles round the green
	var poles: Array = []
	for i in 7:
		var a := TAU * i / 7.0 + 0.3
		var pp := Vector3(cos(a) * 11.5, 0, sin(a) * 11.5)
		pp.y = height(pp.x, pp.z)
		cyl(g, 0.08, 0.1, pole_h, pp + Vector3(0, pole_h * 0.5, 0), mats.beam_v, 8)
		poles.append(pp + Vector3(0, pole_h - 0.1, 0))
		solid_round(pp, 0.25)
	var flag_xf: Array = []
	var flag_col: Array = []
	var bulb_xf: Array = []
	var bulb_col: Array = []
	var lan_xf: Array = []
	var lan_col: Array = []
	var palette := [Color(0.7, 0.08, 0.06), Color(0.85, 0.65, 0.12), Color(0.08, 0.2, 0.6), Color(0.85, 0.82, 0.7), Color(0.1, 0.4, 0.15)]
	for i in poles.size():
		var a: Vector3 = anchor
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
	# the well (Gary's model, or the drawn one): Corin waits here and Nell sits here
	var wp := Vector3(-6.0, height(-6, 4), 4.0)
	if prop_model("well", g, wp, 0.0) == null:
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
	# festival stalls (the red one is Tilly's, where Tam's cider goes)
	var red := stall(g, Vector3(7.5, 0, 6.0), deg_to_rad(-30), mats.cloth_red)
	stalls = [red, stall(g, Vector3(-4.0, 0, -8.5), deg_to_rad(160), mats.cloth_blue)]
	# the merchant carts, west of the blue stall, their shafts towards the
	# ring road, a step inside it
	merchant_carts = []
	for k in [[Vector3(-9.6, 0, -8.2), 1.35, "merchant_cart_a"], [Vector3(-12.3, 0, -2.6), 1.95, "merchant_cart_b"]]:
		var cid: String = k[2]
		if not ResourceLoader.exists("res://assets/models/ashford/%s.glb" % cid):
			cid = "merchant_cart_a"
		var mc := prop_model(cid, g, k[0], k[1])
		if mc != null:
			mc.set_meta("rest", mc.transform)
			merchant_carts.append(mc)
	# the barrel goes down just past the stall's left-hand post
	var beside := Vector3(-2.35 if red.has_meta("model") else -2.1, 0.0, 0.05)
	barrel_spot = red.to_global(beside) if red.is_inside_tree() else red.transform * beside
	barrel_spot.y = height(barrel_spot.x, barrel_spot.z)
	# the last cider barrel, waiting by Tam for a second pair of hands
	var bp := Vector3(7.3, 0.0, -3.5)
	bp.y = height(bp.x, bp.z)
	tam_barrel = make_barrel()
	tam_barrel.position = bp + Vector3(0, BARREL_HALF, 0)
	tam_barrel.rotation.y = 0.4
	g.add_child(tam_barrel)
	# Tam's hay cart (Gary's model), its shafts down on the grass pointing up
	# the lane to the mill: the cart that goes over on Corin at the Sigilfall
	var cp := Vector3(9.0, height(9, -5), -5.0)
	hay_cart = prop_model("hay_cart", g, cp, HAY_CART_YAW)
	if hay_cart == null:
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
		hay_cart = cart
	hay_cart_rest = hay_cart.transform

## One of Gary's props (assets/models/ashford/<id>.glb, +Y up, front +Z) set
## down at `pos` turned by `yaw`, with shadows, a footprint and a solid body.
## Returns its node, or null when the model isn't there yet.
func prop_model(id: String, parent: Node3D, pos: Vector3, yaw: float) -> Node3D:
	var path := "res://assets/models/ashford/%s.glb" % id
	if not ResourceLoader.exists(path):
		return null
	var root := Node3D.new()
	root.name = id.capitalize()
	pos.y = height(pos.x, pos.z) - 0.03
	root.position = pos
	root.rotation.y = yaw
	root.set_meta("model", true)
	parent.add_child(root)
	var inst: Node3D = load(path).instantiate()
	root.add_child(inst)
	var box_ := AABB()
	var first := true
	for mi: MeshInstance3D in inst.find_children("*", "MeshInstance3D", true, false):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		var b := (root.global_transform.affine_inverse() * mi.global_transform) * mi.get_aabb()
		box_ = b if first else box_.merge(b)
		first = false
	var c := box_.get_center()
	var flat := Vector2(c.x, c.z).rotated(-yaw)
	var centre := Vector3(pos.x + flat.x, 0.0, pos.z + flat.y)
	footprints.append([Vector2(centre.x, centre.z), maxf(box_.size.x, box_.size.z) * 0.55])
	solid_box(Vector3(centre.x, 1.5, centre.z), Vector3(box_.size.x + 0.2, 3.0, box_.size.z + 0.2), yaw)
	return root


func stall(parent: Node3D, pos: Vector3, yaw: float, cloth: Material) -> Node3D:
	var m := prop_model("stall", parent, pos, yaw)
	if m != null:
		# the lantern on its front right post is unlit in the model: light it
		var ml := OmniLight3D.new()
		ml.light_color = Color(1.0, 0.6, 0.3); ml.light_energy = 1.3; ml.omni_range = 6.0
		ml.position = Vector3(1.55, 1.9, 1.1)
		m.add_child(ml)
		return m
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
	return s

## A cider barrel: Gary's barrel (barrel.glb, 0.96 m tall as made, its origin
## at the middle of its base) scaled to the game's 0.8 m, or until it's
## there, bulged oak staves and iron hoops drawn here. Its origin is its
## middle (0.4 m up when it stands), so it turns about its centre when carried.
const BARREL_HALF := 0.4
const BARREL_MODEL := "res://assets/models/ashford/barrel.glb"
const BARREL_MODEL_HEIGHT := 0.96
func make_barrel() -> Node3D:
	var b := Node3D.new()
	b.name = "CiderBarrel"
	var body := Node3D.new()
	body.name = "Body"
	body.position = Vector3(0, -BARREL_HALF, 0)
	b.add_child(body)
	if ResourceLoader.exists(BARREL_MODEL):
		var inst: Node3D = load(BARREL_MODEL).instantiate()
		inst.scale = Vector3.ONE * (BARREL_HALF * 2.0 / BARREL_MODEL_HEIGHT)
		body.add_child(inst)
		for mi: MeshInstance3D in inst.find_children("*", "MeshInstance3D", true, false):
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		return b
	# fresh oak, a shade lighter than the old barrels so it reads at night
	var oak := StandardMaterial3D.new()
	oak.albedo_color = Color(0.62, 0.42, 0.24)
	oak.roughness = 0.75
	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color(0.32, 0.3, 0.3)
	iron.metallic = 0.6
	iron.roughness = 0.45
	var bar := CylinderMesh.new()
	bar.top_radius = 0.27; bar.bottom_radius = 0.3; bar.height = 0.42; bar.radial_segments = 18
	add_mesh(body, bar, oak, Transform3D(Basis(), Vector3(0, 0.21, 0)))
	var bar2 := CylinderMesh.new()
	bar2.top_radius = 0.3; bar2.bottom_radius = 0.27; bar2.height = 0.42; bar2.radial_segments = 18
	add_mesh(body, bar2, oak, Transform3D(Basis(), Vector3(0, 0.59, 0)))
	for y in [0.1, 0.32, 0.48, 0.7]:
		var hoop := CylinderMesh.new()
		var r := 0.285 if y < 0.2 or y > 0.6 else 0.305
		hoop.top_radius = r; hoop.bottom_radius = r; hoop.height = 0.045; hoop.radial_segments = 18
		add_mesh(body, hoop, iron, Transform3D(Basis(), Vector3(0, y, 0)))
	return b

## Gary's lantern crate (crate.glb, front +Z): width, height and depth in metres.
const CRATE_MODEL := "res://assets/models/ashford/crate.glb"
const CRATE_SIZE := Vector3(1.11, 0.85, 0.93)
## The lantern crate on its own, for carrying: its origin is the middle of its
## base, and it has no footprint or solid body (whoever uses it places it).
## A plain wooden box of the same size when the model isn't there.
func make_crate() -> Node3D:
	var c := Node3D.new()
	c.name = "Crate"
	if ResourceLoader.exists(CRATE_MODEL):
		var inst: Node3D = load(CRATE_MODEL).instantiate()
		c.add_child(inst)
		for mi: MeshInstance3D in inst.find_children("*", "MeshInstance3D", true, false):
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	else:
		box(c, CRATE_SIZE, Vector3(0, CRATE_SIZE.y * 0.5, 0), mats.wood_h)
	return c

## Puffs of dust where something heavy lands.
func dust_puff(at: Vector3) -> void:
	var p := GPUParticles3D.new()
	p.amount = 10
	p.lifetime = 1.1
	p.one_shot = true
	p.explosiveness = 0.95
	p.position = at + Vector3(0, 0.08, 0)
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 0.3, 0)
	pm.spread = 90.0
	pm.initial_velocity_min = 0.6
	pm.initial_velocity_max = 1.2
	pm.gravity = Vector3(0, 0.15, 0)
	pm.damping_min = 1.5
	pm.damping_max = 2.5
	pm.scale_min = 0.3
	pm.scale_max = 0.55
	var sc := Curve.new(); sc.add_point(Vector2(0, 0.5)); sc.add_point(Vector2(1, 1.6))
	var sct := CurveTexture.new(); sct.curve = sc
	pm.scale_curve = sct
	p.process_material = pm
	var q := QuadMesh.new(); q.size = Vector2(0.7, 0.7)
	p.draw_pass_1 = q
	p.material_override = mats.chimney_smoke
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)
	p.emitting = true
	get_tree().create_timer(2.0, false).timeout.connect(p.queue_free)

## Lights the Great Lantern at midnight: the flame catches, flares, and settles.
func light_great_lantern() -> void:
	if great_lantern_light == null:
		return
	var gl := great_lantern_light
	gl.visible = true
	gl.light_energy = 0.0
	great_lantern_glow.visible = true
	great_lantern_glow.scale = Vector3.ONE * 0.2
	var tw := create_tween().set_parallel(true)
	tw.tween_property(gl, "light_energy", 14.0, 0.25)
	tw.tween_property(great_lantern_glow, "scale", Vector3.ONE * 3.2, 0.25)
	tw.chain().set_parallel(true)
	tw.tween_property(gl, "light_energy", 6.0, 1.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(great_lantern_glow, "scale", Vector3.ONE * 1.6, 1.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(festival_light, "light_energy", 1.2, 1.4)
	tw.chain().tween_callback(func() -> void: flicker_lights.append([gl, 7.0]))
	# a burst of sparks out of the lantern
	var p := GPUParticles3D.new()
	p.amount = 40
	p.lifetime = 1.6
	p.one_shot = true
	p.explosiveness = 0.9
	p.position = great_lantern_top
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 70.0
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 5.0
	pm.gravity = Vector3(0, -2.5, 0)
	pm.scale_min = 0.5
	pm.scale_max = 1.0
	p.process_material = pm
	var q := QuadMesh.new(); q.size = Vector2(0.09, 0.09)
	p.draw_pass_1 = q
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	sm.albedo_color = Color(1.0, 0.7, 0.3)
	p.material_override = sm
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)
	p.emitting = true
	get_tree().create_timer(2.5, false).timeout.connect(p.queue_free)

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

## The dry-stone walls round the fields: lines of points (x, z) along both
## sides of the road in and out of the village, and over the hills.
const FIELD_WALLS := [
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
## Gateways left open in them, [centre, half its width]: where the lane up to
## the mill goes through, and the night Ashford burns, where Krell's riders
## come down the east road (ashford.gd, _burning): one starts in the field
## south of it and crosses the wall at a slant, one starts close by, and a
## hound runs past the end of the north wall.
const WALL_GAPS := [[Vector2(24.0, -41.9), 1.6], [Vector2(55.4, 12.5), 3.6], [Vector2(42.0, 8.0), 3.6]]
## Past this far from the green the phone renderers leave the walls out.
const WALL_NEAR := 85.0
## Gary's dry-stone wall (stone_wall.glb): a straight length 4.2 m long, 1.05
## high and 0.57 thick, its origin at the middle of its foot, along X.
const STONE_WALL_MODEL := "res://assets/models/ashford/stone_wall.glb"
const WALL_LENGTH := 4.2
const WALL_HALF_DEPTH := 0.28
const WALL_STEP := 4.05       # how far apart the lengths are laid, about
const WALL_OVERLAP := 0.08    # each runs this far past the joins either side
const WALL_CORNER := 0.2      # and a line this far past its corners, to close the angle
const WALL_SINK := 0.08       # its foot this far into the lowest ground under it
const WALL_CHUNK := 32.0      # drawn in squares this size, so the far ones use the model's simpler versions
## The fence along the Crooked Lantern's yard, beside the road: two runs
## [from, to], with the gap between them where Bram and the player go through
## from the woodpile to the back gardens, and the west run stopping short of
## where they come back to the back door (ashford.gd, _burning and _gardens).
const INN_FENCE := [[Vector2(-29.2, 13.5), Vector2(-23.0, 13.5)], [Vector2(-20.3, 13.5), Vector2(-17.2, 13.5)]]
## Gary's post-and-rail fence (fence.glb): three posts in a row along X,
## 1.56 m apart, with two courses of rails, the middle post's foot at its origin.
const FENCE_MODEL := "res://assets/models/ashford/fence.glb"
const FENCE_SPAN := 3.12      # end post to end post
const FENCE_POST := 0.11      # a post's half-width
const FENCE_SINK := 0.1       # the posts this far into the ground

func build_walls_and_fences() -> void:
	if ResourceLoader.exists(STONE_WALL_MODEL):
		lay_walls()
		_roll_rock_dice()
	else:
		rock_walls()
	if ResourceLoader.exists(FENCE_MODEL):
		lay_fences(INN_FENCE)
	else:
		box_fences(INN_FENCE)

## The meshes in one of Gary's models, each with where it sits in the model:
## [Mesh, Transform3D], for drawing many copies with MultiMeshes.
var _model_parts := {}
func model_parts(path: String) -> Array:
	if not _model_parts.has(path):
		var out: Array = []
		var inst: Node3D = load(path).instantiate()
		for mi: MeshInstance3D in inst.find_children("*", "MeshInstance3D", true, false):
			out.append([mi.mesh, _local_to(mi, inst)])
		inst.free()
		_model_parts[path] = out
	return _model_parts[path]

func _local_to(n: Node3D, root: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	while n != root:
		xf = n.transform * xf
		n = n.get_parent() as Node3D
	return xf

## Gary's dry-stone wall laid length after length along FIELD_WALLS (where,
## wall_sections()), drawn with one MultiMesh for each WALL_CHUNK square of
## the map, so the far ones drop to the model's simpler versions and the ones
## off screen aren't drawn; the phone renderers leave out those past
## WALL_NEAR and draw no shadows from them, as they did for the drawn walls.
func lay_walls() -> void:
	var root := Node3D.new()
	root.name = "FieldWalls"
	add_child(root)
	var chunks := {}
	for s in wall_sections():
		if quality < 2 and bool(s[1]):
			continue
		var xf: Transform3D = s[0]
		var key := Vector2i(floori(xf.origin.x / WALL_CHUNK), floori(xf.origin.z / WALL_CHUNK))
		if not chunks.has(key):
			chunks[key] = []
		(chunks[key] as Array).append(xf)
	for key: Vector2i in chunks:
		for part in model_parts(STONE_WALL_MODEL):
			var xfs: Array = []
			for xf: Transform3D in chunks[key]:
				xfs.append(xf * (part[1] as Transform3D))
			var mi := multimesh(root, part[0], null, xfs, [], quality == 2)
			mi.name = "Walls_%d_%d" % [key.x, key.y]
			mi.lod_bias = 0.5 if quality == 0 else 1.0

## Where every length of wall goes: [its transform, whether it's past
## WALL_NEAR], for all of FIELD_WALLS. Each line is laid a stretch at a time,
## corner to corner and round the gateways, the lengths in a stretch
## stretched or squeezed a few per cent to fit it exactly (_wall_stretch).
func wall_sections() -> Array:
	var r := RandomNumberGenerator.new()
	r.seed = 1173
	var out: Array = []
	for line in FIELD_WALLS:
		for i in line.size() - 1:
			var a: Vector2 = line[i]
			var b: Vector2 = line[i + 1]
			var dir := (b - a).normalized()
			for span in _open_spans(a - dir * WALL_CORNER, b + dir * WALL_CORNER):
				out.append_array(_wall_stretch(span[0], span[1], r))
	return out

## The parts of the line from `a` to `b` that stay walled, round WALL_GAPS:
## [[from, to], ...], none shorter than half a length.
func _open_spans(a: Vector2, b: Vector2) -> Array:
	var L := a.distance_to(b)
	var dir := (b - a) / L
	var cuts: Array = []
	for g in WALL_GAPS:
		var c: Vector2 = g[0]
		var half: float = g[1]
		var off := absf((c - a).cross(dir))
		if off < half:
			var t := (c - a).dot(dir)
			var h := sqrt(half * half - off * off)
			cuts.append([t - h, t + h])
	cuts.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) < float(y[0]))
	var out: Array = []
	var t0 := 0.0
	for c in cuts:
		var t1 := minf(float(c[0]), L)
		if t1 - t0 > WALL_LENGTH * 0.5:
			out.append([a + dir * t0, a + dir * t1])
		t0 = maxf(t0, float(c[1]))
	if L - t0 > WALL_LENGTH * 0.5:
		out.append([a + dir * t0, b])
	return out

## One straight stretch of wall from `a` to `b`, in lengths. Each length is
## set into the lowest ground at both ends and leans with the slope, its
## stones still upright (its transform shears rather than tilts); where the
## ground dips between two joins the joins go down with it, so no length is
## left with its foot in the air. About half are turned end for end, and each
## is a touch taller or lower, thicker or thinner and off the line than the
## next, so the copies don't repeat.
func _wall_stretch(a: Vector2, b: Vector2, r: RandomNumberGenerator) -> Array:
	var L := a.distance_to(b)
	var n := maxi(1, roundi(L / WALL_STEP))
	var dir := (b - a) / L
	var face := Vector2(-dir.y, dir.x) * WALL_HALF_DEPTH
	var pts: Array = []
	var ys: Array = []
	for k in n + 1:
		var p := a.lerp(b, float(k) / n)
		pts.append(p)
		ys.append(minf(ground_y(p.x + face.x, p.y + face.y), ground_y(p.x - face.x, p.y - face.y)) - WALL_SINK)
	var drop: Array = []
	drop.resize(n + 1)
	drop.fill(0.0)
	for i in n:
		var need := 0.0
		for t in [0.25, 0.5, 0.75]:
			var q: Vector2 = (pts[i] as Vector2).lerp(pts[i + 1], t)
			var y := lerpf(ys[i], ys[i + 1], t)
			for s in [-1.0, 0.0, 1.0]:
				need = maxf(need, y - ground_y(q.x + face.x * s, q.y + face.y * s) + WALL_SINK * 0.5)
		drop[i] = maxf(drop[i], need)
		drop[i + 1] = maxf(drop[i + 1], need)
	var reach := (L / n + 2.0 * WALL_OVERLAP) / (L / n)
	var out: Array = []
	for i in n:
		var pa: Vector2 = pts[i]
		var pb: Vector2 = pts[i + 1]
		var p := Vector3(pa.x, ys[i] - drop[i], pa.y)
		var q := Vector3(pb.x, ys[i + 1] - drop[i + 1], pb.y)
		if r.randf() < 0.5:
			var t := p
			p = q
			q = t
		var along := ((q - p) * reach / WALL_LENGTH).rotated(Vector3.UP, r.randf_range(-0.015, 0.015))
		var across := Vector3(along.x, 0.0, along.z).normalized().cross(Vector3.UP)
		var basis := Basis(along, Vector3.UP * r.randf_range(0.94, 1.06), across * r.randf_range(0.92, 1.08))
		var mid := (p + q) * 0.5 + across * r.randf_range(-0.03, 0.03)
		out.append([Transform3D(basis, mid), Vector2(mid.x, mid.z).length() > WALL_NEAR])
	return out

## The drawn walls rolled the village's dice for every stone they built (five
## randf()s and a randi() each, three stones every 0.36 m); Gary's walls have
## dice of their own, so the same rolls are made here and the trees, grass,
## sky lanterns and Sigils after them come out where they always have.
func _roll_rock_dice() -> void:
	for line in FIELD_WALLS:
		for i in line.size() - 1:
			var a: Vector2 = line[i]
			var b: Vector2 = line[i + 1]
			var n := int(a.distance_to(b) / 0.36)
			for s in n:
				if quality < 2 and a.lerp(b, (s + 0.5) / n).length() > WALL_NEAR:
					continue
				for stone in 3:
					for k in 5:
						rng.randf()
					rng.randi()

## The drawn stand-in for Gary's walls: rough stones in three courses.
func rock_walls() -> void:
	var meshes := [rock_mesh(1), rock_mesh(2), rock_mesh(3)]
	var xfs := [[], [], []]
	for line in FIELD_WALLS:
		for i in line.size() - 1:
			var a: Vector2 = line[i]
			var b: Vector2 = line[i + 1]
			var L := a.distance_to(b)
			var n := int(L / 0.36)
			var dir := (b - a).normalized()
			for s in n:
				var p := a.lerp(b, (s + 0.5) / n)
				if quality < 2 and p.length() > WALL_NEAR:
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

## Gary's fence along each run [from, to]: a post at both ends and at every
## join, the bays between following the ground (the rails slope with it, the
## posts stay upright), each bay and each post turned about at random and the
## posts leaning a touch, so no two lengths look alike. One MultiMesh for the
## bays and one for the posts, and a solid body along each run.
func lay_fences(runs: Array) -> void:
	var root := Node3D.new()
	root.name = "Fences"
	add_child(root)
	var parts := fence_parts()
	var whole := parts.is_empty()
	if whole:
		parts = [model_parts(FENCE_MODEL)[0][0], null]
	var r := RandomNumberGenerator.new()
	r.seed = 1175
	var bays: Array = []
	var posts: Array = []
	for run in runs:
		var a: Vector2 = run[0]
		var b: Vector2 = run[1]
		var L := a.distance_to(b)
		var n := maxi(1, roundi(L / FENCE_SPAN))
		var dir := (b - a) / L
		var line := Vector3(dir.x, 0.0, dir.y)
		var joins: Array = []
		for k in n + 1:
			var p := a.lerp(b, float(k) / n)
			joins.append(Vector3(p.x, ground_under(Vector3(p.x, 0.0, p.y), FENCE_POST) - FENCE_SINK, p.y))
		for i in n:
			var p: Vector3 = joins[i]
			var q: Vector3 = joins[i + 1]
			# its middle post goes into the ground too, where the ground dips
			var m := (p + q) * 0.5
			var dip := maxf(0.0, m.y - (ground_under(m, FENCE_POST) - FENCE_SINK))
			p.y -= dip
			q.y -= dip
			if r.randf() < 0.5:
				var t := p
				p = q
				q = t
			var along := (q - p) / FENCE_SPAN
			bays.append(Transform3D(Basis(along, Vector3.UP, Vector3(along.x, 0.0, along.z).normalized().cross(Vector3.UP)), (p + q) * 0.5))
		if not whole:
			for k in n + 1:
				var yaw := atan2(-dir.y, dir.x) + (PI if r.randf() < 0.5 else 0.0) + r.randf_range(-0.08, 0.08)
				var basis := Basis(line, r.randf_range(-0.035, 0.035)) * Basis(Vector3.UP, yaw).scaled(Vector3(1.0, r.randf_range(0.96, 1.05), 1.0))
				posts.append(Transform3D(basis, joins[k]))
		var mid := (a + b) * 0.5
		solid_box(Vector3(mid.x, 1.5, mid.y), Vector3(L + FENCE_POST * 2.0, 3.0, 0.3), atan2(-dir.y, dir.x))
	multimesh(root, parts[0], null, bays, [])
	if not posts.is_empty():
		multimesh(root, parts[1], null, posts, [])

## Gary's fence in the two pieces a run is laid from: the bays (both spans
## of rails and the middle post) and a post (its +X end post and the pegs in
## it, moved to stand on the origin). The -X end post is left out, as the
## next post along stands there. Empty when the model isn't three posts in a
## row along X; then whole fences are laid end to end.
var _fence_parts: Array = []
func fence_parts() -> Array:
	if not _fence_parts.is_empty():
		return _fence_parts
	var parts := model_parts(FENCE_MODEL)
	if parts.size() != 1 or (parts[0][0] as Mesh).get_surface_count() != 1:
		return []
	var mesh: Mesh = parts[0][0]
	var xf: Transform3D = parts[0][1]
	var arr := mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	for i in v.size():
		v[i] = xf * v[i]
	# the separate pieces of timber: vertices joined by their triangles, and
	# across the texture's seams by being in the same place
	var up: Array = range(v.size())
	var find := func(i: int) -> int:
		while up[i] != i:
			up[i] = up[up[i]]
			i = up[i]
		return i
	var at := {}
	for i in v.size():
		var k := v[i].snapped(Vector3.ONE * 0.0001)
		if at.has(k):
			up[find.call(i)] = find.call(at[k])
		else:
			at[k] = i
	for t in range(0, idx.size(), 3):
		var ra: int = find.call(idx[t])
		up[find.call(idx[t + 1])] = ra
		up[find.call(idx[t + 2])] = ra
	var boxes := {}
	for i in v.size():
		var c: int = find.call(i)
		if boxes.has(c):
			boxes[c] = (boxes[c] as AABB).expand(v[i])
		else:
			boxes[c] = AABB(v[i], Vector3.ZERO)
	# a piece centred further out than this belongs to an end post
	var end := FENCE_SPAN * 0.5 - 0.3
	var post := AABB()
	var found := 0
	for c in boxes:
		var b: AABB = boxes[c]
		if b.get_center().x > end and b.size.y > 0.6:
			post = b
			found += 1
	if found != 1:
		return []
	var in_bays := PackedByteArray()
	in_bays.resize(v.size())
	var in_post := PackedByteArray()
	in_post.resize(v.size())
	for i in v.size():
		var cx := (boxes[find.call(i)] as AABB).get_center().x
		if cx > end:
			in_post[i] = 1
		elif cx > -end:
			in_bays[i] = 1
	var foot := Vector3(post.get_center().x, 0.0, post.get_center().z)
	_fence_parts = [_sub_mesh(mesh, arr, v, xf.basis, in_bays, Vector3.ZERO), _sub_mesh(mesh, arr, v, xf.basis, in_post, -foot)]
	return _fence_parts

## The triangles of a one-surface mesh whose corners are all marked in
## `keep`, as a mesh of their own (with the same material), moved by `offset`.
func _sub_mesh(src: Mesh, arr: Array, v: PackedVector3Array, turn: Basis, keep: PackedByteArray, offset: Vector3) -> ArrayMesh:
	var nrm = arr[Mesh.ARRAY_NORMAL]
	var tan = arr[Mesh.ARRAY_TANGENT]
	var uv = arr[Mesh.ARRAY_TEX_UV]
	var uv2 = arr[Mesh.ARRAY_TEX_UV2]
	var col = arr[Mesh.ARRAY_COLOR]
	var to := PackedInt32Array()
	to.resize(v.size())
	var out := []
	out.resize(Mesh.ARRAY_MAX)
	var ov := PackedVector3Array()
	var on := PackedVector3Array()
	var ot := PackedFloat32Array()
	var ou := PackedVector2Array()
	var ou2 := PackedVector2Array()
	var oc := PackedColorArray()
	for i in v.size():
		to[i] = -1
		if keep[i] == 0:
			continue
		to[i] = ov.size()
		ov.append(v[i] + offset)
		if nrm != null:
			on.append((turn * (nrm[i] as Vector3)).normalized())
		if tan != null:
			var tv := (turn * Vector3(tan[i * 4], tan[i * 4 + 1], tan[i * 4 + 2])).normalized()
			ot.append_array([tv.x, tv.y, tv.z, tan[i * 4 + 3]])
		if uv != null:
			ou.append(uv[i])
		if uv2 != null:
			ou2.append(uv2[i])
		if col != null:
			oc.append(col[i])
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var oi := PackedInt32Array()
	for t in range(0, idx.size(), 3):
		var a := to[idx[t]]
		var b := to[idx[t + 1]]
		var c := to[idx[t + 2]]
		if a >= 0 and b >= 0 and c >= 0:
			oi.append_array([a, b, c])
	out[Mesh.ARRAY_VERTEX] = ov
	out[Mesh.ARRAY_INDEX] = oi
	if nrm != null:
		out[Mesh.ARRAY_NORMAL] = on
	if tan != null:
		out[Mesh.ARRAY_TANGENT] = ot
	if uv != null:
		out[Mesh.ARRAY_TEX_UV] = ou
	if uv2 != null:
		out[Mesh.ARRAY_TEX_UV2] = ou2
	if col != null:
		out[Mesh.ARRAY_COLOR] = oc
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out)
	m.surface_set_material(0, src.surface_get_material(0))
	return m

## The drawn stand-in for Gary's fence: posts and two rails along each run.
func box_fences(runs: Array) -> void:
	for run in runs:
		var a: Vector2 = run[0]
		var b: Vector2 = run[1]
		var n := maxi(1, roundi(a.distance_to(b) / 1.6))
		var turn := Vector3(0.0, atan2(-(b - a).y, (b - a).x), 0.0)
		for i in n + 1:
			var p2 := a.lerp(b, float(i) / n)
			box(self, Vector3(0.12, 1.1, 0.12), Vector3(p2.x, height(p2.x, p2.y) + 0.5, p2.y), mats.beam_v, turn)
			if i < n:
				var m2 := a.lerp(b, (i + 0.5) / n)
				for y in [0.75, 0.35]:
					box(self, Vector3(a.distance_to(b) / n, 0.08, 0.06), Vector3(m2.x, height(m2.x, m2.y) + y, m2.y), mats.wood_h, turn)
		solid_box(Vector3((a.x + b.x) * 0.5, 1.5, (a.y + b.y) * 0.5), Vector3(a.distance_to(b) + 0.2, 3.0, 0.3), turn.y)

# ------------------------------------------------------------------ sacks and crates

## Gary's three grain sacks (sacks.glb, 1.15 m across, front +Z).
const SACKS_MODEL := "res://assets/models/ashford/sacks.glb"
## Every pile of sacks and stack of crates set down: [centre (x, z), radius],
## for the tests that check nobody in the story walks through one.
var props_placed: Array = []

## Grain sacks by the mill's door, behind Tam's hay cart and beside the blue
## stall; a crate by the Crooked Lantern's door, and two stacked by the blue
## stall.
## All of it stands clear of where the story goes: Tam's barrel walk, the
## crowd and the Lantern Duel round the Great Lantern, the run and the cart
## at midnight, the dawn, the riders and the escape through the gardens
## (ashford.gd), and out of the films' cameras. Built after the grass, so the
## grass and everything after it come out as before (a few blades come up
## round their feet).
func build_props() -> void:
	var root := Node3D.new()
	root.name = "Props"
	add_child(root)
	var sacks: Array = []
	var crates: Array = []
	if mill_root != null and ResourceLoader.exists(MILL_TOWER_MODEL):
		# either side of the door (the tower's +Z), under the sails' sweep
		for k in [[Vector3(2.1, 0, 1.6), 0.5], [Vector3(-2.25, 0, 1.35), -0.4]]:
			var p := to_local(mill_root.to_global(k[0]))
			sacks.append([Vector2(p.x, p.z), mill_root.rotation.y + float(k[1]), 1])
	if hay_cart != null:
		# behind its tail, out of the way of Tam and the barrel
		sacks.append([Vector2(5.9, -5.0), 0.9, 1])
	if stalls.size() > 1:
		# on the blue stall's west side, away from the crowd at the Lantern Duel
		var blue: Node3D = stalls[1]
		for k in [[Vector3(2.5, 0, -1.0), 0.3, 1, sacks], [Vector3(2.6, 0, 0.55), -0.15, 2, crates]]:
			var p := to_local(blue.to_global(k[0]))
			(k[3] as Array).append([Vector2(p.x, p.z), blue.rotation.y + float(k[1]), k[2]])
	var inn := inn_index()
	if inn >= 0:
		var r: Node3D = houses[inn].root
		# against the wall just south of the door (its middle is at x -0.6),
		# end on, between it and the model's barrels (x -3.6 and -4.6), clear
		# of the way out and of where the player comes out (SPAWNS.inn). One
		# high: a second crate on top covered the corner of the window above
		for k in [[Vector3(-2.35, 0, 3.3), PI * 0.5 + 0.04, 1]]:
			var p := to_local(r.to_global(k[0]))
			crates.append([Vector2(p.x, p.z), r.rotation.y + float(k[1]), k[2]])
	place_props(root, SACKS_MODEL, sacks)
	place_props(root, CRATE_MODEL, crates)

## Copies of one of Gary's props, drawn together by one MultiMesh (one for
## each mesh in the model). Each spot is [where (x, z), yaw, how many high]:
## a stack, each one a little turned on the one below. The bottom one stands
## on the lowest ground under it and gets a footprint and a solid body, as
## prop_model()'s do.
func place_props(parent: Node3D, path: String, spots: Array) -> void:
	if not ResourceLoader.exists(path) or spots.is_empty():
		return
	var parts := model_parts(path)
	var box_ := AABB()
	for i in parts.size():
		var b: AABB = (parts[i][1] as Transform3D) * (parts[i][0] as Mesh).get_aabb()
		box_ = b if i == 0 else box_.merge(b)
	var r := RandomNumberGenerator.new()
	r.seed = 1176 + spots.size()
	var xfs: Array = []
	for s in spots:
		var at: Vector2 = s[0]
		var yaw: float = s[1]
		var c := Vector2(box_.get_center().x, box_.get_center().z).rotated(-yaw)
		var centre := Vector3(at.x + c.x, 0.0, at.y + c.y)
		var foot := maxf(box_.size.x, box_.size.z) * 0.55
		var p := Vector3(at.x, ground_under(centre, foot * 0.8) - 0.02, at.y)
		for k in int(s[2]):
			var turn := yaw + (r.randf_range(-0.14, 0.14) if k > 0 else 0.0)
			xfs.append(Transform3D(Basis(Vector3.UP, turn), p + Vector3(0, box_.size.y * k, 0)))
		footprints.append([Vector2(centre.x, centre.z), foot])
		props_placed.append([Vector2(centre.x, centre.z), foot])
		solid_box(Vector3(centre.x, 1.5, centre.z), Vector3(box_.size.x + 0.2, 3.0, box_.size.z + 0.2), yaw)
	for part in parts:
		var pxfs: Array = []
		for xf: Transform3D in xfs:
			pxfs.append(xf * (part[1] as Transform3D))
		multimesh(parent, part[0], null, pxfs, [])

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

## A garden hedge: leaf cards packed into a long low block, `length` along
## its local X. Used where someone needs to hide (the back gardens).
func hedge(at: Vector3, yaw: float, length := 4.0, h := 1.6) -> MeshInstance3D:
	var r := RandomNumberGenerator.new()
	r.seed = int(absf(at.x) * 131.0 + absf(at.z) * 17.0)
	var leaves := SurfaceTool.new()
	leaves.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := int(length * 34.0)
	for k in n:
		var p := Vector3(r.randf_range(-length * 0.5, length * 0.5), r.randf_range(0.15, h), r.randf_range(-0.45, 0.45))
		var nrm := Vector3(0, 0.4, sign(p.z) if absf(p.z) > 0.05 else 1.0).normalized()
		var basis := Basis.from_euler(Vector3(r.randf() * TAU, r.randf() * TAU, r.randf() * TAU))
		var sz := r.randf_range(0.55, 0.9)
		var ex := basis.x * sz * 0.5
		var ey := basis.y * sz * 0.5
		var col := Color(1, 1, 1).darkened(r.randf() * 0.4)
		for tri_v in [[p - ex - ey, Vector2(0, 1)], [p + ex - ey, Vector2(1, 1)], [p + ex + ey, Vector2(1, 0)], [p - ex - ey, Vector2(0, 1)], [p + ex + ey, Vector2(1, 0)], [p - ex + ey, Vector2(0, 0)]]:
			leaves.set_color(col)
			leaves.set_normal(nrm)
			leaves.set_uv(tri_v[1])
			leaves.add_vertex(tri_v[0])
	var mi := MeshInstance3D.new()
	mi.mesh = leaves.commit()
	mi.material_override = mats.leaf_dark
	add_child(mi)
	mi.global_position = Vector3(at.x, height(at.x, at.z), at.z)
	mi.rotation.y = yaw
	return mi


## Gary's oaks (assets/models/ashford/oak_a.glb, and oak_b, oak_c... as they
## come: every one that's there is used, in turn) stand round the edge of the
## village, where the films and the flight over the rooftops pass close; the
## copses and hedgerow trees out on the hills stay the light drawn trees. Each
## oak is about 20,000 triangles up close, so there are at most OAK_MAX of
## them, each its own node so the engine draws its simpler versions (LODs) when
## it's further off; each is turned, sized and stretched a little differently.
const OAK_MODELS := ["oak_a", "oak_b", "oak_c", "oak_d"]
const OAK_MAX := 16
const OAK_CROWN := 6.4        # the model's crown, centre to edge, in metres
const OAK_TRUNK := 0.75       # its trunk at the foot (the roots spread further, low)
## Trees keep this far from the mill's foot, clear of its turning sails.
const MILL_CLEAR := 9.5
## Where the film watches the Sigil strike the mill from, on the green
## (ashford.gd, "and one on the mill"), and the top of the lane, as far up it
## as the player can walk: no tree stands in the way of the mill from either.
const MILL_VIEW_FROM := Vector3(4.0, 2.0, 8.0)
const MILL_LANE_VIEW := Vector3(12.0, 1.8, -23.5)
var oaks: Array = []          # every oak planted: its root node

func oak_scenes() -> Array:
	var out: Array = []
	for id in OAK_MODELS:
		var path := "res://assets/models/ashford/%s.glb" % id
		if ResourceLoader.exists(path):
			out.append(load(path))
	return out

func build_trees() -> void:
	var variants := [make_tree(11), make_tree(23), make_tree(37)]
	var bark_x := [[], [], []]
	var leaf_x := [[], [], []]
	var oak_kinds := oak_scenes()
	# the oaks' own dice, so the village's other random things (grass, sky
	# lanterns, Sigils) come out as they always have
	var orng := RandomNumberGenerator.new()
	orng.seed = 1172
	var oak_at: Array = []    # [Vector2 trunk, crown radius]
	var spots: Array = []
	# trees round the edge of the village
	for i in 26:
		var a := rng.randf() * TAU
		var rr := rng.randf_range(29.0, 44.0)
		spots.append(Vector2(cos(a) * rr, sin(a) * rr))
	var edge := spots.size()
	# copses and hedgerow trees on the hills
	for c in [Vector2(-60, -55), Vector2(35, -50), Vector2(-85, 45), Vector2(85, 30), Vector2(10, -105), Vector2(-40, -110), Vector2(110, -60), Vector2(-120, -20)]:
		for i in 14:
			spots.append(c + Vector2(rng.randf_range(-14, 14), rng.randf_range(-14, 14)))
	for i in 40:
		var a := rng.randf() * TAU
		var rr := rng.randf_range(60.0, 150.0)
		spots.append(Vector2(cos(a) * rr, sin(a) * rr))
	var mill_at := Vector2(mill_root.position.x, mill_root.position.z) if mill_root != null else Vector2(INF, INF)
	for n in spots.size():
		var s: Vector2 = spots[n]
		var blocked := false
		var room := INF    # how far the nearest building is past its own footprint
		for f in footprints:
			var d := s.distance_to(f[0]) - float(f[1])
			room = minf(room, d)
			if d < 3.5:
				blocked = true
		for cpos in [Vector2(-50, 50), Vector2(-30, 44), Vector2(14, 22)]:
			if Geometry2D.get_closest_point_to_segment(s, cpos, Vector2.ZERO).distance_to(s) < 9.0:
				blocked = true
		if blocked or path_at(s.x, s.y) > 0.2 or s.length() < 27.0:
			continue
		var k := rng.randi() % 3
		var sc := rng.randf_range(0.85, 1.35)
		var yaw := rng.randf() * TAU
		if s.distance_to(mill_at) < MILL_CLEAR or _blocks_mill_view(s, 3.6 * sc, 8.6 * sc):
			continue
		if n < edge and not oak_kinds.is_empty():
			var osc := orng.randf_range(0.82, 1.12)
			var crown := OAK_CROWN * osc
			# an oak needs more room than a drawn tree: its crown mustn't reach
			# into a roof, or into the next oak's crown more than a little
			var fits := oaks.size() < OAK_MAX and room > crown * 0.7 and not _blocks_mill_view(s, crown, 9.6 * osc)
			for o in oak_at:
				if s.distance_to(o[0]) < (crown + float(o[1])) * 0.72:
					fits = false
			if fits:
				var kind: PackedScene = oak_kinds[oaks.size() % oak_kinds.size()]
				plant_oak(kind, s, yaw, Vector3(osc, osc * orng.randf_range(0.9, 1.1), osc))
				oak_at.append([s, crown])
				continue
		var xf := Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * sc), Vector3(s.x, height(s.x, s.y) - 0.1, s.y))
		bark_x[k].append(xf)
		leaf_x[k].append(xf)
	for k in 3:
		multimesh(self, variants[k][0], mats.bark, bark_x[k], [])
		multimesh(self, variants[k][1], mats.leaf, leaf_x[k], [])

## Whether a tree at `s` (its crown `crown` round, its top `top` above the
## ground) would stand in the view of the mill from the green or the lane.
func _blocks_mill_view(s: Vector2, crown: float, top: float) -> bool:
	if mill_root == null:
		return false
	var to := mill_fire_point()
	var b := Vector2(to.x, to.z)
	for from: Vector3 in [MILL_VIEW_FROM, MILL_LANE_VIEW]:
		var a := Vector2(from.x, from.z)
		var near := Geometry2D.get_closest_point_to_segment(s, a, b)
		var u := a.distance_to(near) / maxf(a.distance_to(b), 0.01)
		var sight_y := lerpf(from.y, to.y, u)
		# wider towards the mill, for its sails (5 m out) and the tower under the cap
		if near.distance_to(s) < crown + 1.5 + 4.0 * u and ground_y(s.x, s.y) + top > sight_y - 6.0 * u:
			return true
	return false

## One of Gary's oaks at `at` (on the ground), turned by `yaw` and sized by
## `sc`, with its trunk solid so no one walks through it.
func plant_oak(kind: PackedScene, at: Vector2, yaw: float, sc: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "Oak%d" % oaks.size()
	var p := Vector3(at.x, 0.0, at.y)
	# set into the lowest ground round the trunk, so it doesn't stand proud on a slope
	p.y = ground_under(p, OAK_TRUNK * sc.x) - 0.05
	root.position = p
	root.rotation.y = yaw
	root.scale = sc
	add_child(root)
	var inst: Node3D = kind.instantiate()
	root.add_child(inst)
	for mi: MeshInstance3D in inst.find_children("*", "MeshInstance3D", true, false):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		# a phone's sharp screen would keep the full 20,000 triangles further
		# out than it needs: on the web the simpler versions come in sooner
		mi.lod_bias = 0.5 if quality == 0 else 1.0
	solid_round(p, OAK_TRUNK * sc.x)
	oaks.append(root)
	return root

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
	var ls: Array = []
	# two lights per fire on the big renderer; one, without shadows, on phones
	for k in (2 if quality == 2 else 1):
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.45, 0.12)
		l.light_energy = 5.0 * scale_k * (1.0 if quality == 2 else 1.5)
		l.omni_range = 18.0
		l.shadow_enabled = k == 0 and quality > 0
		l.light_volumetric_fog_energy = 0.2
		l.position = at + Vector3(rng.randf_range(-1, 1), 1.5 + k, rng.randf_range(-1, 1))
		add_child(l)
		flicker_lights.append([l, l.light_energy])
		ls.append(l)
	fires.append({"flame": f, "ember": e, "smoke": s, "lights": ls})

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
	for i in range(flicker_lights.size() - 1, -1, -1):
		var fl: Array = flicker_lights[i]
		if not is_instance_valid(fl[0]):
			flicker_lights.remove_at(i)   # it went with whatever carried it
			continue
		var l: OmniLight3D = fl[0]
		l.light_energy = fl[1] * (0.82 + 0.18 * sin(elapsed * 13.0 + fl[1]) * sin(elapsed * 7.3 + fl[1] * 2.0))
	_turn_mill(delta)
	if lantern_t >= 0.0:
		_rise_lanterns(delta)
	if absf(tear - tear_target) > 0.001:
		tear = move_toward(tear, tear_target, delta * 0.45)
		var open := tear * tear * (3.0 - 2.0 * tear)
		sky_mat.set_shader_parameter("tear_open", open)
		if sigil_on and tear_light != null:
			# the rift lights the village from above as it opens (and dims to
			# its scar's glow after)
			tear_light.visible = true
			tear_light.light_energy = 0.3 + 1.1 * open
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

# ------------------------------------------------------------------ the Prologue's cutscenes

## Tips Tam's hay cart over on its side, about its left-hand wheel (the side
## facing the green): 0 standing, 1 flat over. Corin ends up under it.
func set_cart_tip(amount: float) -> void:
	hay_cart_tip = amount
	if hay_cart == null:
		return
	var edge := Vector3(-HAY_CART_HALF_WIDTH, 0.0, 0.0)
	# a little past flat so the hay rests on the grass rather than the wheel rim
	var r := Basis(Vector3(0, 0, 1), amount * deg_to_rad(88.0))
	hay_cart.transform = hay_cart_rest * Transform3D(Basis(), edge) * Transform3D(r, Vector3.ZERO) * Transform3D(Basis(), -edge)


func tip_cart(to: float, secs: float, trans := Tween.TRANS_QUAD, ease := Tween.EASE_IN) -> void:
	var tw := create_tween()
	tw.tween_method(set_cart_tip, hay_cart_tip, to, secs).set_trans(trans).set_ease(ease)
	await tw.finished


## Which way the cart falls (flat on the ground, world space).
func cart_fall_dir() -> Vector3:
	var x := hay_cart_rest.basis.x
	x.y = 0.0
	return -x.normalized()


## The middle of the cart where it stands, on the ground.
## The shockwave at midnight throws the merchant carts over: each rolls onto
## its side away from the Lantern, lifting as it goes, and settles.
func shatter_carts() -> void:
	for mc in merchant_carts:
		if not is_instance_valid(mc):
			continue
		var c := mc as Node3D
		var rest: Transform3D = c.get_meta("rest", c.transform)
		var away := Vector3(rest.origin.x, 0, rest.origin.z).normalized()
		var side := signf(away.dot(rest.basis.x))
		if side == 0.0:
			side = 1.0
		var tw := create_tween()
		tw.set_parallel(true)
		# over onto its side: roll about its long axis, and a shove outward
		var end := rest.rotated_local(Vector3(0, 0, 1), -side * 1.45)
		end.origin = rest.origin + away * 1.3 + Vector3(0, 0.45, 0)
		tw.tween_property(c, "transform", end, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		var down := end
		down.origin.y = rest.origin.y + 0.05
		tw.chain().tween_property(c, "transform", down, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


## The carts back on their wheels (a new game, the morning).
func carts_upright() -> void:
	for mc in merchant_carts:
		if is_instance_valid(mc) and (mc as Node3D).has_meta("rest"):
			(mc as Node3D).transform = (mc as Node3D).get_meta("rest")


func cart_centre() -> Vector3:
	var c := hay_cart_rest.origin
	if hay_cart != null and hay_cart.get_parent() != null:
		c = (hay_cart.get_parent() as Node3D).global_transform * c
	return Vector3(c.x, height(c.x, c.z), c.z)


## The cart's long axis (towards its shafts), flat.
func cart_along() -> Vector3:
	var z := hay_cart_rest.basis.z
	z.y = 0.0
	return z.normalized()


## A Sigil strike: a streak of light drops out of the sky onto `at` and lands
## (light, sparks, scorch and a little fire). Waits until it lands.
func strike(at: Vector3, col: Color, secs := 0.4, big := false) -> void:
	at.y = height(at.x, at.z)
	var fall := Vector3(0.28, -1.0, 0.16).normalized()
	var start := at - fall * 70.0
	var mi := MeshInstance3D.new()
	mi.mesh = QuadMesh.new()
	mi.material_override = mats.streak
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_instance_shader_parameter("col", col)
	mi.set_instance_shader_parameter("intensity", 8.0)
	add_child(mi)
	var gs := glow_sprite(self, start, col, 2.4, 1.3)
	var length := 16.0
	var tw := create_tween()
	tw.tween_method(func(u: float) -> void:
		var head := start.lerp(at, u)
		mi.transform = Transform3D(Basis(Vector3(0.9, 0, 0), -fall * length, Vector3(0, 0, 1)), head - fall * length * 0.5)
		gs.global_position = head, 0.0, 1.0, secs)
	await tw.finished
	mi.queue_free()
	gs.queue_free()
	if big:
		impact(at, col)
	else:
		small_impact(at, col)


## A lighter landing than impact(): a flash, sparks and a scorch, and a small
## fire that dies down (cheap enough to have several in a shot on a phone).
func small_impact(at: Vector3, col: Color) -> void:
	var l := OmniLight3D.new()
	l.light_color = col.lerp(Color(1, 0.9, 0.7), 0.4)
	l.light_energy = 9.0
	l.omni_range = 14.0
	l.position = at + Vector3(0, 1.2, 0)
	add_child(l)
	var lt := create_tween()
	lt.tween_property(l, "light_energy", 1.2, 0.8)
	lt.tween_callback(func() -> void: flicker_lights.append([l, 1.2]))
	var sp := GPUParticles3D.new()
	sp.amount = [30, 80, 110][quality]
	sp.lifetime = 1.2
	sp.one_shot = true
	sp.explosiveness = 0.95
	sp.position = at + Vector3(0, 0.2, 0)
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 75.0
	pm.initial_velocity_min = 3.0
	pm.initial_velocity_max = 9.0
	pm.gravity = Vector3(0, -9.0, 0)
	pm.scale_min = 0.06
	pm.scale_max = 0.14
	sp.process_material = pm
	var q := QuadMesh.new(); q.size = Vector2(1, 1)
	sp.draw_pass_1 = q
	var em: ShaderMaterial = mats.ember.duplicate()
	em.set_shader_parameter("ember_col", col.lerp(Color(1, 0.9, 0.6), 0.5))
	em.set_shader_parameter("intensity", 25.0)
	sp.material_override = em
	sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sp.visibility_aabb = AABB(Vector3(-12, -2, -12), Vector3(24, 14, 24))
	add_child(sp)
	sp.emitting = true
	get_tree().create_timer(2.5, false).timeout.connect(sp.queue_free)
	scorch(at, 3.2)
	dust_puff(at)


## A burnt patch on the ground where a Sigil came down.
func scorch(at: Vector3, size: float) -> void:
	var dm := QuadMesh.new(); dm.size = Vector2(size, size); dm.orientation = PlaneMesh.FACE_Y
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.01, 0.008, 0.006)
	m.emission_enabled = true
	m.emission = Color(0.9, 0.18, 0.02)
	m.emission_energy_multiplier = 0.3
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var g := Gradient.new(); g.set_color(0, Color(1, 1, 1, 1)); g.set_color(1, Color(1, 1, 1, 0))
	var gt := GradientTexture2D.new(); gt.gradient = g; gt.fill = GradientTexture2D.FILL_RADIAL; gt.fill_from = Vector2(0.5, 0.5); gt.fill_to = Vector2(0.5, 0.0)
	m.albedo_texture = gt
	m.emission_texture = gt
	var mi := add_mesh(self, dm, m, Transform3D(Basis(Vector3.UP, rng.randf() * TAU), at + Vector3(0, 0.06, 0)), false)
	scorches.append(mi)

var scorches: Array = []
## Fires lit by fire_at(): {flame, ember, smoke, lights}, so dawn can put them out.
var fires: Array = []


## The mill's thatch catches, up on its hill, and its sails run down to a stop.
func fire_mill() -> void:
	if mill_root == null:
		return
	fire_at(mill_fire_point(), mill_fire_box, [24, 36, 50][quality], 1.3, true)
	mill_spin_to = 0.0


## Sets building `i` (an index into houses) alight; "inn" for the Crooked Lantern.
func burn_house(i: int, grow := true) -> void:
	if i < 0 or i >= houses.size():
		return
	var h: Dictionary = houses[i]
	if h.get("burning", false):
		return
	h["burning"] = true
	var root: Node3D = h.root
	var at := root.to_global(Vector3(0.0, float(h.top) * 0.62, 0.0))
	fire_at(at, Vector3(float(h.L) * 0.32, 0.4, float(h.D) * 0.3), [20, 32, 46][quality], 1.15 if h.inn else 1.0, grow)


func inn_index() -> int:
	for i in houses.size():
		if houses[i].inn:
			return i
	return -1


## The ring of cottages nearest a point, nearest first.
func houses_near(p: Vector3) -> Array:
	var idx := range(houses.size())
	idx.sort_custom(func(a, b): return (houses[a].root as Node3D).global_position.distance_to(p) < (houses[b].root as Node3D).global_position.distance_to(p))
	return idx


## The light and sky for each part of the Prologue:
##   "festival"  the last night of the Age (as built)
##   "dawn"      the morning after: a low sun through smoke, the fires out
##   "burning"   the next night: no festival lights, the village dark
## The time of day the set is dressed for ("festival", "dawn", "burning"...; Cine's key light reads it).
var time_kind := "festival"

## Master Script v7's P1 by day (k = 1) or on the festival night (k = 0),
## or anywhere between as the sun goes down: the sky, the sun (the moon's
## light, turned warm and high), the fill and the fog, the lanterns, the
## bunting's bulbs, the windows and the door lights.
func set_daylight(k: float) -> void:
	if _night.is_empty():
		_night = {"moon_col": moon_light.light_color, "moon_e": moon_light.light_energy, "moon_xf": moon_light.global_transform,
			"amb_src": env.ambient_light_source, "amb_col": env.ambient_light_color, "amb_e": env.ambient_light_energy,
			"fog_col": env.fog_light_color, "fog_d": env.fog_density, "exposure": env.tonemap_exposure,
			"fest": festival_light.light_energy, "tear": tear_light.visible,
			"lantern": _param(mats.lantern, "energy", 1.0), "bulb": _param(mats.bulb, "energy", 1.0),
			"tear_open": _param(sky_mat, "tear_open", 0.0),
			"ll_vis": lantern_lights.map(func(ll) -> bool: return (ll[0] as Node3D).visible)}
	k = clampf(k, 0.0, 1.0)
	daylight = k
	var n := _night
	# the sun: high in the south-east by day, low in the west at sunset
	var sun_day := Vector3(0.45, 0.78, 0.43).normalized()
	var sun_set := Vector3(-0.9, 0.08, 0.42).normalized()
	var dusk := clampf((0.75 - k) / 0.55, 0.0, 1.0) * clampf(k / 0.12, 0.0, 1.0)   # 0 by day and by night, up at sunset
	var sun := sun_day.slerp(sun_set, clampf(1.0 - k, 0.0, 1.0)).normalized()
	sky_mat.set_shader_parameter("day", smoothstep(0.08, 0.6, k))
	sky_mat.set_shader_parameter("dawn", dusk * 0.85)
	sky_mat.set_shader_parameter("sun_dir", sun)
	sky_mat.set_shader_parameter("tear_open", lerpf(float(n.tear_open), 0.0, k))
	tear_light.visible = bool(n.tear) and k < 0.5
	if k > 0.0:
		moon_light.look_at_from_position(Vector3.ZERO, -sun, Vector3.UP)
	else:
		moon_light.global_transform = n.moon_xf
	var day_sun := Color(1.0, 0.95, 0.86).lerp(Color(1.0, 0.62, 0.38), dusk)
	moon_light.light_color = (n.moon_col as Color).lerp(day_sun, smoothstep(0.0, 0.35, k))
	moon_light.light_energy = lerpf(float(n.moon_e), [3.0, 2.6, 2.4][quality], smoothstep(0.0, 0.5, k))
	if k > 0.0:
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR if quality < 2 else Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_color = (n.amb_col as Color).lerp(Color(0.66, 0.7, 0.78), k)
		env.ambient_light_energy = lerpf(float(n.amb_e), 1.0, k)
	else:
		env.ambient_light_source = n.amb_src
		env.ambient_light_color = n.amb_col
		env.ambient_light_energy = n.amb_e
	env.fog_light_color = (n.fog_col as Color).lerp(Color(0.72, 0.78, 0.86).lerp(Color(0.95, 0.62, 0.45), dusk), k)
	env.fog_density = lerpf(float(n.fog_d), 0.0018, k)
	# the lanterns and the bunting's bulbs come on as the light goes
	var lamps := 1.0 - smoothstep(0.15, 0.55, k)
	mats.lantern.set_shader_parameter("energy", float(n.lantern) * lamps)
	mats.bulb.set_shader_parameter("energy", float(n.bulb) * lamps)
	festival_light.light_energy = float(n.fest) * lamps
	for wm in window_mats:
		(wm[0] as StandardMaterial3D).emission_energy_multiplier = float(wm[1]) * lamps
	for hl in house_lights:
		(hl as OmniLight3D).visible = lamps > 0.05
	var vis: Array = n.ll_vis
	for i in lantern_lights.size():
		var was: bool = vis[i] if i < vis.size() else true
		(lantern_lights[i][0] as Node3D).visible = was and lamps > 0.05


## A shader's uniform as it stands, or `default` if nothing has set it yet
## (get_shader_parameter() gives null until it's set, not the shader's default).
static func _param(m: ShaderMaterial, name: String, default: float) -> float:
	var x = m.get_shader_parameter(name) if m != null else null
	return float(x) if x != null else default


func set_time(kind: String) -> void:
	time_kind = kind
	if kind == "day":
		set_daylight(1.0)
		return
	var dawn := kind == "dawn"
	sky_mat.set_shader_parameter("dawn", 1.0 if dawn else 0.0)
	if kind != "festival":
		# the festival is over: bunting lights, sky lanterns and Sigils gone
		sigil_on = false
		for st in streaks:
			st.node.visible = false
			st.glow.visible = false
			if st.light:
				st.light.visible = false
		paper_mm.visible = false
		for ll in lantern_lights:
			ll[0].visible = false
		lantern_t = -1.0
		if white_light != null:
			white_light.visible = false
		stop_mill()   # its cap burned at midnight
		mats.bulb.set_shader_parameter("energy", 0.0)
		mats.lantern.set_shader_parameter("energy", 0.0)
		festival_light.light_energy = 0.0
		tear = 0.3
		tear_target = 0.3
		sky_mat.set_shader_parameter("tear_open", 0.25)
		sky_dim = 1.0
		sky_dim_target = 1.0
		sky_mat.set_shader_parameter("sky_dim", 1.0)
	if dawn:
		moon_light.light_color = Color(1.0, 0.74, 0.52)
		moon_light.light_energy = [2.2, 2.0, 1.9][quality]
		var sun := Vector3(0.86, 0.16, -0.50).normalized()
		moon_light.look_at_from_position(Vector3.ZERO, -sun, Vector3.UP)
		tear_light.visible = false
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.62, 0.62, 0.72)
		env.ambient_light_energy = 0.85
		env.fog_light_color = Color(0.62, 0.52, 0.5)
		env.fog_density = 0.0035
		env.volumetric_fog_albedo = Color(0.9, 0.8, 0.75)
		env.tonemap_exposure = 1.0
		great_lantern_light.light_energy = 1.5
		_douse_fires()
		if player_light != null:
			player_light.light_energy = 0.0
	elif kind == "burning":
		moon_light.light_color = Color(0.55, 0.66, 1.0)
		moon_light.light_energy = [0.9, 0.75, 0.6][quality]
		moon_light.look_at_from_position(Vector3.ZERO, -Vector3(-0.84, 0.45, 0.30), Vector3.UP)
		tear_light.visible = true
		tear_light.light_energy = 0.15
		if quality == 2:
			env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
			env.ambient_light_energy = 1.2
		else:
			env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			env.ambient_light_color = Color(0.32, 0.36, 0.55)
			env.ambient_light_energy = [0.65, 0.5][quality]
		env.fog_light_color = Color(0.04, 0.05, 0.10)
		env.fog_density = 0.0012
		great_lantern_light.visible = false
		great_lantern_glow.visible = false
		_douse_fires()
		if player_light != null:
			player_light.light_energy = 0.6


## The fires go out; their smoke keeps rising, thinner and grey.
func _douse_fires() -> void:
	for f in fires:
		(f.flame as GPUParticles3D).emitting = false
		(f.ember as GPUParticles3D).emitting = false
		(f.smoke as GPUParticles3D).amount_ratio = 0.5
		for l in f.lights:
			(l as OmniLight3D).visible = false
			for fl in flicker_lights:
				if fl[0] == l:
					flicker_lights.erase(fl)
					break
	fires.clear()
