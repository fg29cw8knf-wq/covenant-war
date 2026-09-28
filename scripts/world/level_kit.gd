class_name LevelKit
extends RefCounted
## Building blocks for greybox-to-final 3D levels: materials with procedural
## textures, and helpers that add boxes, roofs, columns, trees, lamps and so
## on with collision. Levels are described in code (see scripts/world/areas/),
## so they can later be swapped piece by piece for modelled assets.

static var _mats := {}


# ============================================================= materials ===

static func mat(name: String) -> StandardMaterial3D:
	if _mats.has(name):
		return _mats[name]
	var m := StandardMaterial3D.new()
	match name:
		"cobble":
			m.albedo_texture = _cells(Color("7d6c58"), Color("b89e7c"), Color("4d4133"), 11, 0.07)
			m.normal_enabled = true
			m.normal_texture = _cells_normal(11, 0.07)
			m.normal_scale = 0.9
			m.roughness = 0.92
			_world_uv(m, 0.22)
		"flagstone":
			m.albedo_texture = _cells(Color("9d8c70"), Color("d6c6a4"), Color("6d604c"), 23, 0.05)
			m.normal_enabled = true
			m.normal_texture = _cells_normal(23, 0.05)
			m.roughness = 0.8
			_world_uv(m, 0.12)
		"marble":
			m.albedo_texture = _noise(Color("d6ccb6"), Color("ece4d2"), 0.02)
			m.roughness = 0.55
			_world_uv(m, 0.08)
		"sandstone":
			m.albedo_texture = _noise(Color("c9a878"), Color("e0c69a"), 0.03)
			m.roughness = 0.85
			_world_uv(m, 0.1)
		"plaster":
			m.albedo_texture = _noise(Color("dccdb0"), Color("ece0c8"), 0.05)
			m.roughness = 0.9
			_world_uv(m, 0.1)
		"roof_teal":
			m.albedo_color = Color("2f7f8f")
			m.albedo_texture = _stripes(Color("2c7584"), Color("3b8c9c"), 18)
			m.roughness = 0.6
			_world_uv(m, 0.35)
		"roof_terracotta":
			m.albedo_texture = _stripes(Color("b3563a"), Color("c96a48"), 18)
			m.roughness = 0.75
			_world_uv(m, 0.35)
		"gold":
			m.albedo_color = Color("e6b84f")
			m.metallic = 0.85
			m.roughness = 0.28
		"bronze":
			m.albedo_color = Color("b0783f")
			m.metallic = 0.8
			m.roughness = 0.35
		"wood":
			m.albedo_texture = _stripes(Color("6e4a2e"), Color("85603c"), 9)
			m.roughness = 0.85
			_world_uv(m, 0.8)
		"dark_wood":
			m.albedo_color = Color("4a3322")
			m.roughness = 0.8
		"grass":
			m.albedo_texture = _noise(Color("4f7a2c"), Color("7fa648"), 0.05)
			m.roughness = 1.0
			_world_uv(m, 0.15)
		"leaves":
			m.albedo_texture = _noise(Color("3e6b2c"), Color("6c9a3c"), 0.2)
			m.roughness = 0.95
			_world_uv(m, 0.6)
		"cypress":
			m.albedo_texture = _noise(Color("24472a"), Color("3f6b3a"), 0.25)
			m.roughness = 1.0
			_world_uv(m, 0.8)
		"water":
			m.albedo_color = Color(0.2, 0.55, 0.75, 0.82)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.metallic = 0.3
			m.roughness = 0.05
			m.emission_enabled = true
			m.emission = Color("2f7fa8")
			m.emission_energy_multiplier = 0.35
			m.normal_enabled = true
			m.normal_texture = _noise_normal(0.04)
			_world_uv(m, 0.3)
		"cloth_blue":
			m.albedo_color = Color("2d4f9a")
			m.roughness = 0.9
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"cloth_white":
			m.albedo_color = Color("f3eee2")
			m.roughness = 0.9
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"awning_red":
			m.albedo_texture = _stripes(Color("c0392b"), Color("f3e6cf"), 4, true)
			m.roughness = 0.9
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"awning_blue":
			m.albedo_texture = _stripes(Color("2c5d9e"), Color("f3e6cf"), 4, true)
			m.roughness = 0.9
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"lamp_glow":
			m.albedo_color = Color("fff2c4")
			m.emission_enabled = true
			m.emission = Color("ffd27a")
			m.emission_energy_multiplier = 4.0
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		"sun_glow":
			m.albedo_color = Color("fff0b0")
			m.emission_enabled = true
			m.emission = Color("ffcf5a")
			m.emission_energy_multiplier = 2.5
			m.metallic = 0.6
			m.roughness = 0.2
		"ring_glow":
			m.albedo_color = Color("ffe8a0")
			m.emission_enabled = true
			m.emission = Color("ffc04a")
			m.emission_energy_multiplier = 3.0
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		"rock":
			m.albedo_texture = _noise(Color("8d8272"), Color("b3a792"), 0.08)
			m.roughness = 0.95
			_world_uv(m, 0.2)
		"hill":
			m.albedo_texture = _noise(Color("9fae5c"), Color("c8c77a"), 0.02)
			m.roughness = 1.0
			_world_uv(m, 0.05)
		_:
			m.albedo_color = Color.MAGENTA
	_mats[name] = m
	return m


static func _world_uv(m: StandardMaterial3D, scale: float) -> void:
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(scale, scale, scale)
	m.uv1_triplanar_sharpness = 4.0


static func _ramp(a: Color, b: Color) -> Gradient:
	var g := Gradient.new()
	g.set_color(0, a)
	g.set_color(1, b)
	return g


static func _noise(a: Color, b: Color, freq: float) -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = freq
	n.fractal_octaves = 4
	var t := NoiseTexture2D.new()
	t.width = 256
	t.height = 256
	t.seamless = true
	t.noise = n
	t.color_ramp = _ramp(a, b)
	t.generate_mipmaps = true
	return t


static func _noise_normal(freq: float) -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.frequency = freq
	var t := NoiseTexture2D.new()
	t.width = 256
	t.height = 256
	t.seamless = true
	t.as_normal_map = true
	t.bump_strength = 4.0
	t.noise = n
	return t


## Cobblestones: cellular noise, dark grout between lighter stones.
static func _cells(grout: Color, light: Color, dark: Color, seed_v: int, freq: float) -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_CELLULAR
	n.seed = seed_v
	n.frequency = freq
	n.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	n.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	n.fractal_type = FastNoiseLite.FRACTAL_NONE
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.08, 0.22, 1.0])
	g.colors = PackedColorArray([dark, grout, light, light.lightened(0.08)])
	var t := NoiseTexture2D.new()
	t.width = 512
	t.height = 512
	t.seamless = true
	t.noise = n
	t.color_ramp = g
	t.generate_mipmaps = true
	return t


static func _cells_normal(seed_v: int, freq: float) -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_CELLULAR
	n.seed = seed_v
	n.frequency = freq
	n.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	n.fractal_type = FastNoiseLite.FRACTAL_NONE
	var t := NoiseTexture2D.new()
	t.width = 512
	t.height = 512
	t.seamless = true
	t.as_normal_map = true
	t.bump_strength = 6.0
	t.noise = n
	return t


## Horizontal (or vertical) stripes, for roof tiles, planks and awnings.
static func _stripes(a: Color, b: Color, count: int, vertical: bool = false) -> ImageTexture:
	var img := Image.create(64, 64, true, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var v := x if vertical else y
			var band := int(floor(v * count / 64.0)) % 2
			var c := a if band == 0 else b
			# a soft shadow line at the top of each band
			var local := fmod(v * count / 64.0, 1.0)
			if local < 0.12:
				c = c.darkened(0.18)
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


# ============================================================= geometry ===

static func mesh(parent: Node3D, m: Mesh, pos: Vector3, material: Material, rot_y: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = material
	mi.position = pos
	mi.rotation.y = deg_to_rad(rot_y)
	parent.add_child(mi)
	return mi


## A solid box resting on the ground at `pos` (bottom centre).
static func box(parent: Node3D, pos: Vector3, size: Vector3, material: String, collide: bool = true, rot_y: float = 0.0) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	var mi := mesh(parent, bm, pos + Vector3(0, size.y * 0.5, 0), mat(material), rot_y)
	if collide:
		_collider(mi, BoxShape3D.new(), size)
	return mi


static func _collider(mi: MeshInstance3D, shape: Shape3D, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	if shape is BoxShape3D:
		(shape as BoxShape3D).size = size
	cs.shape = shape
	body.add_child(cs)
	mi.add_child(body)


static func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, material: String,
		collide: bool = true, top_radius: float = -1.0, sides: int = 24) -> MeshInstance3D:
	var cm := CylinderMesh.new()
	cm.bottom_radius = radius
	cm.top_radius = radius if top_radius < 0 else top_radius
	cm.height = height
	cm.radial_segments = sides
	var mi := mesh(parent, cm, pos + Vector3(0, height * 0.5, 0), mat(material))
	if collide:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = maxf(radius, cm.top_radius)
		sh.height = height
		cs.shape = sh
		body.add_child(cs)
		mi.add_child(body)
	return mi


## A gabled roof: a triangular prism sitting on top of a building.
static func gable(parent: Node3D, pos: Vector3, width: float, depth: float, height: float, material: String, rot_y: float = 0.0) -> MeshInstance3D:
	var pm := PrismMesh.new()
	pm.size = Vector3(width, height, depth)
	return mesh(parent, pm, pos + Vector3(0, height * 0.5, 0), mat(material), rot_y)


static func dome(parent: Node3D, pos: Vector3, radius: float, material: String) -> MeshInstance3D:
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius
	sm.is_hemisphere = true
	sm.radial_segments = 32
	sm.rings = 12
	return mesh(parent, sm, pos, mat(material))


static func sphere(parent: Node3D, pos: Vector3, radius: float, material: String, stretch: float = 1.0) -> MeshInstance3D:
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0 * stretch
	sm.radial_segments = 16
	sm.rings = 8
	return mesh(parent, sm, pos, mat(material))


static func torus(parent: Node3D, pos: Vector3, inner: float, outer: float, material: String) -> MeshInstance3D:
	var tm := TorusMesh.new()
	tm.inner_radius = inner
	tm.outer_radius = outer
	tm.rings = 48
	tm.ring_segments = 8
	return mesh(parent, tm, pos, mat(material))


# ============================================================ set pieces ===

## A town house: walls, a band of trim, a gabled roof and a door/windows.
static func house(parent: Node3D, pos: Vector3, size: Vector3, wall: String = "plaster",
		roof: String = "roof_teal", rot_y: float = 0.0) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	n.rotation.y = deg_to_rad(rot_y)
	parent.add_child(n)
	box(n, Vector3.ZERO, size, wall)
	box(n, Vector3(0, size.y - 0.35, 0), Vector3(size.x + 0.2, 0.35, size.z + 0.2), "sandstone", false)
	gable(n, Vector3(0, size.y, 0), size.x + 0.8, size.z + 0.8, size.y * 0.45, roof)
	# door and windows on the +z face
	var fz := size.z * 0.5 + 0.03
	box(n, Vector3(0, 0, fz), Vector3(1.3, 2.2, 0.08), "dark_wood", false)
	box(n, Vector3(0, 2.2, fz), Vector3(1.7, 0.25, 0.12), "sandstone", false)
	for x in [-size.x * 0.3, size.x * 0.3]:
		if size.x > 4.0:
			box(n, Vector3(x, 1.4, fz), Vector3(0.9, 1.1, 0.08), "dark_wood", false)
			box(n, Vector3(x, 1.3, fz + 0.05), Vector3(1.1, 0.12, 0.22), "sandstone", false)
	if size.y > 5.0:
		for x in [-size.x * 0.3, 0.0, size.x * 0.3]:
			box(n, Vector3(x, size.y * 0.62, fz), Vector3(0.8, 1.0, 0.08), "dark_wood", false)
	return n


static func column(parent: Node3D, pos: Vector3, height: float, radius: float = 0.4, material: String = "marble") -> void:
	box(parent, pos, Vector3(radius * 2.6, 0.35, radius * 2.6), material, false)
	cylinder(parent, pos + Vector3(0, 0.35, 0), radius, height - 0.7, material, true, radius * 0.88, 16)
	box(parent, pos + Vector3(0, height - 0.35, 0), Vector3(radius * 2.6, 0.35, radius * 2.6), material, false)


static func tree(parent: Node3D, pos: Vector3, size: float = 1.0) -> void:
	cylinder(parent, pos, 0.18 * size, 1.6 * size, "wood", true, 0.12 * size, 8)
	sphere(parent, pos + Vector3(0, 2.4 * size, 0), 1.25 * size, "leaves", 0.9)
	sphere(parent, pos + Vector3(0.6 * size, 2.0 * size, 0.3 * size), 0.85 * size, "leaves", 0.9)
	sphere(parent, pos + Vector3(-0.55 * size, 2.1 * size, -0.25 * size), 0.8 * size, "leaves", 0.9)


static func cypress(parent: Node3D, pos: Vector3, height: float = 5.0) -> void:
	cylinder(parent, pos, 0.14, 0.8, "wood", true, 0.1, 8)
	sphere(parent, pos + Vector3(0, 0.6 + height * 0.5, 0), height * 0.14, "cypress", 3.4)


## A street lamp. `light` adds a real light (keep these few on phones).
static func lamp(parent: Node3D, pos: Vector3, light: bool = false) -> void:
	cylinder(parent, pos, 0.09, 3.0, "bronze", true, 0.07, 8)
	box(parent, pos + Vector3(0, 3.0, 0), Vector3(0.5, 0.06, 0.5), "bronze", false)
	var g := sphere(parent, pos + Vector3(0, 3.28, 0), 0.2, "lamp_glow")
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	gable(parent, pos + Vector3(0, 3.5, 0), 0.55, 0.55, 0.3, "bronze")
	if light:
		var l := OmniLight3D.new()
		l.position = pos + Vector3(0, 3.2, 0)
		l.light_color = Color("ffcf80")
		l.light_energy = 1.4
		l.omni_range = 6.0
		l.shadow_enabled = false
		parent.add_child(l)


## A hanging banner with a god's sigil on it.
static func banner(parent: Node3D, pos: Vector3, rot_y: float, sigil: String = "radiant",
		cloth: Color = Color("2d4f9a"), mark: Color = Color("f2c96b"), height: float = 3.2) -> void:
	var qm := QuadMesh.new()
	qm.size = Vector2(1.3, height)
	var m := StandardMaterial3D.new()
	m.albedo_texture = _banner_tex(sigil, cloth, mark)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.9
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	var mi := mesh(parent, qm, pos + Vector3(0, -height * 0.5, 0), m, rot_y)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	cylinder(parent, pos + Vector3(0, 0.02, 0), 0.05, 0.08, "gold", false)
	var rod := CylinderMesh.new()
	rod.top_radius = 0.05
	rod.bottom_radius = 0.05
	rod.height = 1.5
	var r := mesh(parent, rod, pos + Vector3(0, 0.05, 0), mat("gold"), rot_y)
	r.rotation.z = PI * 0.5


static func _banner_tex(sigil: String, cloth: Color, mark: Color) -> Texture2D:
	var svg := "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 246'>" + \
		"<path d='M0 0 H100 V214 L50 246 L0 214 Z' fill='#%s'/>" % cloth.to_html(false) + \
		"<path d='M6 6 H94 V210 L50 238 L6 210 Z' fill='none' stroke='#%s' stroke-width='3'/>" % mark.to_html(false) + \
		"<g transform='translate(18 70) scale(0.64)'>%s</g></svg>" % String(Glyphs.SHAPES.get(sigil, "")).replace("#fff", "#" + mark.to_html(false))
	var img := Image.new()
	if img.load_svg_from_string(svg, 2.0) != OK:
		img = Image.create(8, 8, false, Image.FORMAT_RGBA8)
		img.fill(cloth)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## A market stall: counter, posts and a striped awning.
static func stall(parent: Node3D, pos: Vector3, rot_y: float = 0.0, awning: String = "awning_red") -> void:
	var n := Node3D.new()
	n.position = pos
	n.rotation.y = deg_to_rad(rot_y)
	parent.add_child(n)
	box(n, Vector3(0, 0, 0), Vector3(2.8, 1.0, 1.1), "wood")
	for x in [-1.3, 1.3]:
		for z in [-0.5, 0.5]:
			cylinder(n, Vector3(x, 0, z), 0.06, 2.5, "dark_wood", false, -1, 6)
	var qm := QuadMesh.new()
	qm.size = Vector2(3.2, 1.7)
	var a := mesh(n, qm, Vector3(0, 2.55, 0.1), mat(awning))
	a.rotation.x = deg_to_rad(-70)
	# wares
	for i in 4:
		var c := Color.from_hsv(fmod(0.08 + i * 0.23, 1.0), 0.55, 0.9)
		var sm := SphereMesh.new()
		sm.radius = 0.16
		sm.height = 0.3
		var wm := StandardMaterial3D.new()
		wm.albedo_color = c
		mesh(n, sm, Vector3(-0.9 + i * 0.6, 1.14, 0.1), wm)


static func crate(parent: Node3D, pos: Vector3, s: float = 0.8, rot_y: float = 0.0) -> void:
	box(parent, pos, Vector3(s, s, s), "wood", true, rot_y)


static func barrel(parent: Node3D, pos: Vector3) -> void:
	cylinder(parent, pos, 0.42, 1.0, "wood", true, 0.42, 14)
	cylinder(parent, pos + Vector3(0, 0.18, 0), 0.44, 0.07, "dark_wood", false, 0.44, 14)
	cylinder(parent, pos + Vector3(0, 0.78, 0), 0.44, 0.07, "dark_wood", false, 0.44, 14)


static func bench(parent: Node3D, pos: Vector3, rot_y: float = 0.0) -> void:
	var n := Node3D.new()
	n.position = pos
	n.rotation.y = deg_to_rad(rot_y)
	parent.add_child(n)
	box(n, Vector3(0, 0.42, 0), Vector3(2.0, 0.1, 0.5), "wood")
	box(n, Vector3(-0.8, 0, 0), Vector3(0.12, 0.42, 0.45), "marble", false)
	box(n, Vector3(0.8, 0, 0), Vector3(0.12, 0.42, 0.45), "marble", false)


## An invisible wall that keeps the player inside the playable area.
static func wall(parent: Node3D, a: Vector3, b: Vector3, height: float = 3.0) -> void:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	var d := b - a
	sh.size = Vector3(d.length(), height, 0.4)
	cs.shape = sh
	body.add_child(cs)
	body.position = (a + b) * 0.5 + Vector3(0, height * 0.5, 0)
	body.rotation.y = -atan2(d.z, d.x)
	parent.add_child(body)
