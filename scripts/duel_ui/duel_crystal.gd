class_name DuelCrystal
extends RefCounted
## A Totem knocked out turns to crystal and shatters (29 October, Gary: "When
## a card dies can we have the creature turn to dust or diamonds rather then
## just fall over"). It fits the lore: the cards are the gods' magic set hard
## into Sigils, and a Totem knocked out goes back into its card. The
## creature stops still; a glassy sheen climbs it from its feet to its head;
## it cracks, light showing through; it bursts into glittering diamonds that
## tumble, bounce and fade into drifting sparkling dust; its card goes to
## light, and the slot is clear. Nothing gory (Gary's rule: "blood off").
##
## DuelField3D.crystal_death() plays it on the 3D field, for a Totem's model
## (a sheen drawn over its own materials, crystal_overlay) and for a painted
## cut-out (its picture drawn as glass, crystal_sprite); shatter_2d() is the
## flat field's. The same shaders draw Wards' and answers' shields
## (shield_shader). Everything here is warmed as a duel opens
## (DuelField3D.warm_fx), so the first knockout doesn't stop to compile.

static var _overlay: Shader
static var _sprite: Shader
static var _shard: Shader
static var _shield: Shader
static var _diamond: ArrayMesh
static var _diamond2d: Texture2D

## A 3D Voronoi's cell edges: the cracks.
const CRACKS := """
vec3 cw_hash3(vec3 p) {
	p = vec3(dot(p, vec3(127.1, 311.7, 74.7)), dot(p, vec3(269.5, 183.3, 246.1)), dot(p, vec3(113.5, 271.9, 124.6)));
	return fract(sin(p) * 43758.5453);
}
float cw_cracks(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	for (int z = -1; z <= 1; z++) {
		for (int y = -1; y <= 1; y++) {
			for (int x = -1; x <= 1; x++) {
				vec3 g = vec3(float(x), float(y), float(z));
				float d = length(g + cw_hash3(i + g) - f);
				if (d < d1) {
					d2 = d1;
					d1 = d;
				} else if (d < d2) {
					d2 = d;
				}
			}
		}
	}
	return 1.0 - smoothstep(0.0, 0.08, d2 - d1);
}
float cw_spark(vec3 w, float t) {
	float r = fract(sin(dot(floor(w * 16.0), vec3(12.9898, 78.233, 37.719))) * 43758.5453);
	return step(0.93, r) * (0.5 + 0.5 * sin(t * 11.0 + r * 60.0));
}
"""

## The sheen over a model, drawn as a second pass of its own materials:
## below the climbing line it's glass (a cold rim, glints), at the line a
## bright band, and later the cracks.
const OVERLAY := """
shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_back, fog_disabled;
uniform float progress = 0.0;
uniform float crack = 0.0;
uniform float y0 = 0.0;
uniform float y1 = 2.0;
uniform vec3 tint : source_color = vec3(0.78, 0.93, 1.0);
uniform float strength = 1.0;
%s
void fragment() {
	vec3 w = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = (w.y - y0) / max(0.001, y1 - y0);
	float line = progress * 1.25 - 0.1;
	float covered = 1.0 - smoothstep(line - 0.04, line + 0.04, h);
	float edge = (1.0 - smoothstep(0.0, 0.08, abs(h - line))) * (1.0 - smoothstep(0.92, 1.0, progress));
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	float c = 0.0;
	if (crack > 0.001) {
		c = cw_cracks(w * 4.5) * crack;
	}
	vec3 col = tint * (covered * (0.16 + 1.0 * fres) + edge * 1.8);
	col += vec3(1.0) * covered * (cw_spark(w, TIME) * 0.8 + c * 1.1);
	ALBEDO = col * strength;
}
"""

## A painted cut-out (a Sprite3D) drawn as glass: its own picture below the
## line turns to tinted crystal, the band, glints and cracks the same. It
## faces the camera as the sprite does (upright, turning about its height).
const SPRITE := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque, fog_disabled;
uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform float progress = 0.0;
uniform float crack = 0.0;
uniform float y0 = 0.0;
uniform float y1 = 2.0;
uniform vec3 tint : source_color = vec3(0.78, 0.93, 1.0);
uniform float strength = 1.0;
%s
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0), MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}
void fragment() {
	vec4 t = texture(tex, UV);
	if (t.a < 0.5) {
		discard;
	}
	vec3 base = t.rgb * COLOR.rgb;
	vec3 w = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = (w.y - y0) / max(0.001, y1 - y0);
	float line = progress * 1.25 - 0.1;
	float covered = 1.0 - smoothstep(line - 0.04, line + 0.04, h);
	float edge = (1.0 - smoothstep(0.0, 0.08, abs(h - line))) * (1.0 - smoothstep(0.92, 1.0, progress));
	float lum = dot(base, vec3(0.3, 0.55, 0.15));
	float facet = fract(sin(dot(floor(w * 7.0), vec3(12.9898, 78.233, 37.719))) * 43758.5453);
	vec3 glass = tint * (0.3 + 0.6 * lum) * (0.85 + 0.3 * facet) + vec3(0.04);
	float c = 0.0;
	if (crack > 0.001) {
		c = cw_cracks(w * 4.5) * crack;
	}
	vec3 col = mix(base, glass, covered * 0.8) + tint * edge * 1.4;
	col += vec3(1.0) * covered * (cw_spark(w, TIME) * 0.8 + c * 0.9);
	ALBEDO = col * strength;
}
"""

## The diamonds: cut glass, mostly clear, some in the Totem's gem colour,
## each catching the light now and then.
const SHARD := """
shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, specular_schlick_ggx;
uniform float glow = 1.4;
varying vec4 col;
varying float twinkle;
void vertex() {
	col = COLOR;
	twinkle = pow(max(0.0, sin(TIME * 13.0 + float(INSTANCE_ID) * 2.39)), 12.0);
}
void fragment() {
	float fres = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.5);
	ALBEDO = col.rgb * 0.3;
	ROUGHNESS = 0.05;
	METALLIC = 0.25;
	SPECULAR = 1.0;
	EMISSION = col.rgb * (0.35 + fres * glow) + vec3(twinkle * 2.0 + fres * fres);
	ALPHA = col.a;
}
"""

## A shield of light: a rim that glows where it's seen edge-on, and a faint
## lattice across it.
const SHIELD := """
shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_disabled, fog_disabled;
uniform vec3 tint : source_color = vec3(0.7, 0.9, 1.0);
uniform float power = 1.0;
void fragment() {
	float fres = pow(1.0 - abs(dot(NORMAL, VIEW)), 2.0);
	vec3 w = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 p = vec2(w.x + w.z * 0.5, w.y * 1.15 + w.z * 0.6) * 4.0;
	vec2 g = abs(fract(p) - 0.5);
	float lattice = 1.0 - smoothstep(0.0, 0.06, min(g.x, g.y));
	ALBEDO = tint * power * (0.1 + fres * 1.5 + lattice * 0.35 * (0.3 + fres));
}
"""


static func overlay_shader() -> Shader:
	if _overlay == null:
		_overlay = Shader.new()
		_overlay.code = OVERLAY % CRACKS
	return _overlay


static func sprite_shader() -> Shader:
	if _sprite == null:
		_sprite = Shader.new()
		_sprite.code = SPRITE % CRACKS
	return _sprite


static func shard_shader() -> Shader:
	if _shard == null:
		_shard = Shader.new()
		_shard.code = SHARD
	return _shard


static func shield_shader() -> Shader:
	if _shield == null:
		_shield = Shader.new()
		_shield.code = SHIELD
	return _shield


## The sheen for a model's surfaces (one per dying Totem: its uniforms are its own).
static func overlay_material(tint: Color, y0: float, y1: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = overlay_shader()
	m.set_shader_parameter("tint", Color(tint.r, tint.g, tint.b))
	m.set_shader_parameter("y0", y0)
	m.set_shader_parameter("y1", y1)
	return m


## A cut-out's glass picture (its own texture).
static func sprite_material(tex: Texture2D, tint: Color, y0: float, y1: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = sprite_shader()
	m.set_shader_parameter("tex", tex)
	m.set_shader_parameter("tint", Color(tint.r, tint.g, tint.b))
	m.set_shader_parameter("y0", y0)
	m.set_shader_parameter("y1", y1)
	return m


## A cut stone: a six-sided table, a crown down to the girdle and a long
## pavilion to the point, every face flat so each catches the light.
static func diamond() -> ArrayMesh:
	if _diamond != null:
		return _diamond
	var table := []
	var girdle := []
	for i in 6:
		var a := TAU * i / 6.0
		table.append(Vector3(cos(a + PI / 6.0) * 0.24, 0.3, sin(a + PI / 6.0) * 0.24))
		girdle.append(Vector3(cos(a) * 0.45, 0.08, sin(a) * 0.45))
	var top := Vector3(0, 0.3, 0)
	var point := Vector3(0, -0.62, 0)
	var tris := []
	for i in 6:
		var j := (i + 1) % 6
		tris.append([top, table[i], table[j]])
		tris.append([table[i], girdle[i], girdle[j]])
		tris.append([table[i], girdle[j], table[j]])
		tris.append([girdle[i], point, girdle[j]])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for t in tris:
		var a: Vector3 = t[0]
		var b: Vector3 = t[1]
		var c: Vector3 = t[2]
		var n := (b - a).cross(c - a).normalized()
		var centre := (a + b + c) / 3.0
		if n.dot(centre - Vector3(0, -0.1, 0)) < 0.0:
			n = -n
			var tmp := b
			b = c
			c = tmp
		# (clockwise seen from outside: Godot's front faces)
		for v in [a, c, b]:
			st.set_normal(n)
			st.add_vertex(v)
	_diamond = st.commit()
	return _diamond


## A cut stone for the flat field's particles: a rhombus with lit and shaded facets.
static func diamond_tex_2d() -> Texture2D:
	if _diamond2d != null:
		return _diamond2d
	var n := 48
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var u := (x + 0.5) / n * 2.0 - 1.0
			var v := (y + 0.5) / n * 2.0 - 1.0
			var d := absf(u) / 0.62 + absf(v)
			if d > 1.0:
				img.set_pixel(x, y, Color(1, 1, 1, 0))
				continue
			var shade := 0.72
			if v < -0.25:
				shade = 1.0 if u < 0.0 else 0.88
			elif u < 0.0:
				shade = 0.8 if v < 0.3 else 0.62
			else:
				shade = 0.92 if v < 0.3 else 0.7
			var a := clampf((1.0 - d) * 10.0, 0.0, 1.0)
			img.set_pixel(x, y, Color(shade, shade, shade, a))
	img.generate_mipmaps()
	_diamond2d = ImageTexture.create_from_image(img)
	return _diamond2d


# ================================================================ shards ===

## The diamonds a Totem bursts into: one MultiMesh (one draw for them all),
## each stone thrown out, tumbling, bouncing once or twice on the floor,
## then shrinking away; as they go, `on_dust` is handed where they are, for
## the sparkling dust.
class Shards3D:
	extends Node3D
	var mm: MultiMesh
	var pos := PackedVector3Array()
	var vel := PackedVector3Array()
	var axis := PackedVector3Array()
	var spin := PackedFloat32Array()
	var size := PackedFloat32Array()
	var cols := PackedColorArray()
	var rot: Array = []
	var t := 0.0
	var life := 1.4
	var fade_at := 0.62
	var floor_y := 0.0
	var gravity := 10.0
	var on_dust := Callable()
	var _dusted := false

	func setup(n: int, centre: Vector3, half: Vector3, tint: Color, gem: Color, power: float) -> void:
		mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.instance_count = n
		mm.mesh = DuelCrystal.diamond()
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		var mat := ShaderMaterial.new()
		mat.shader = DuelCrystal.shard_shader()
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		for i in n:
			var p := centre + Vector3(randf_range(-half.x, half.x), randf_range(-half.y, half.y), randf_range(-half.z, half.z))
			pos.append(p)
			var out := (p - centre + Vector3(0, half.y * 0.6, 0)).normalized()
			if out.length() < 0.01:
				out = Vector3.UP
			vel.append((out + Vector3(randf_range(-0.3, 0.3), randf_range(0.2, 0.9), randf_range(-0.3, 0.3))).normalized() * randf_range(2.2, 5.0) * power)
			axis.append(Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized())
			spin.append(randf_range(6.0, 16.0))
			size.append(randf_range(0.13, 0.3))
			var c := Color(0.92, 0.97, 1.0).lerp(tint, 0.35)
			if i % 3 == 0:
				c = gem
			elif i % 3 == 1:
				c = c.lerp(gem, 0.4)
			cols.append(c)
			rot.append(Basis(axis[i], randf() * TAU))
		_place()

	func _process(dt: float) -> void:
		t += dt
		for i in pos.size():
			var v: Vector3 = vel[i]
			v.y -= gravity * dt
			v *= 1.0 - minf(0.9, 0.5 * dt)
			var p: Vector3 = pos[i] + v * dt
			var r := size[i] * 0.45
			if p.y < floor_y + r:
				p.y = floor_y + r
				if v.y < 0.0:
					v.y = -v.y * 0.32
					v.x *= 0.55
					v.z *= 0.55
					spin[i] *= 0.55
			pos[i] = p
			vel[i] = v
			rot[i] = (rot[i] as Basis).rotated(axis[i], spin[i] * dt)
		var k := clampf((t / life - fade_at) / (1.0 - fade_at), 0.0, 1.0)
		if not _dusted and k > 0.02:
			_dusted = true
			if on_dust.is_valid():
				on_dust.call(pos.duplicate())
		_place(k)
		if t >= life:
			queue_free()

	func _place(k: float = 0.0) -> void:
		for i in pos.size():
			var sc := size[i] * (1.0 - k * k)
			mm.set_instance_transform(i, Transform3D((rot[i] as Basis).scaled(Vector3.ONE * maxf(0.001, sc)), pos[i]))
			mm.set_instance_color(i, Color(cols[i], 1.0 - k * 0.4))


## The burst: diamonds out of the body, a flash, and, as they fade, the
## sparkling dust drifting up out of where they lie.
static func shatter(f: DuelField3D, centre: Vector3, half: Vector3, tint: Color, gem: Color, spd: float = 1.0) -> Shards3D:
	var sh := Shards3D.new()
	sh.life = 1.45 / maxf(0.5, minf(spd, 3.0))
	sh.setup(26, centre, half, tint, gem, 1.0)
	sh.on_dust = func(points: PackedVector3Array) -> void:
		if not is_instance_valid(f):
			return
		# the dust: a sparkle where each stone was, drifting up and away
		DuelStrikeFX.emit(f, Vector3.ZERO, {"shape": "points", "points": points, "amount": 60, "life": 1.3, "explode": 0.6,
			"speed": [0.2, 0.7], "dir": Vector3.UP, "spread": 50.0, "gravity": Vector3(0, 0.45, 0), "damp": [0.2, 0.5],
			"tex": "star", "size": 0.16, "grow": "swell", "cols": [Color.WHITE, tint, gem]})
		DuelStrikeFX.emit(f, Vector3.ZERO, {"shape": "points", "points": points, "amount": 40, "life": 1.5, "explode": 0.4,
			"speed": [0.1, 0.4], "dir": Vector3.UP, "spread": 70.0, "gravity": Vector3(0, 0.25, 0), "size": 0.07,
			"grow": "flat", "cols": [Color(tint, 0.9), Color(gem, 0.6)]})
	f._fx_parent().add_child(sh)
	return sh


## The flat field's knockout: the cut-out is already pale glass (its flash);
## it bursts into diamond chips that fall and glitter, and dust rises.
static func shatter_2d(parent: Control, pos: Vector2, tint: Color, gem: Color, depth: float, spd: float) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = 26
	p.lifetime = 1.1
	p.speed_scale = spd
	p.texture = diamond_tex_2d()
	p.direction = Vector2.UP
	p.spread = 180.0
	p.initial_velocity_min = 220.0 * depth
	p.initial_velocity_max = 620.0 * depth
	p.gravity = Vector2(0, 1100.0 * depth)
	p.angular_velocity_min = -540.0
	p.angular_velocity_max = 540.0
	p.angle_min = 0.0
	p.angle_max = 360.0
	p.scale_amount_min = 0.35 * depth
	p.scale_amount_max = 0.9 * depth
	var sc := Curve.new()
	sc.add_point(Vector2(0, 1))
	sc.add_point(Vector2(0.65, 0.85))
	sc.add_point(Vector2(1, 0))
	p.scale_amount_curve = sc
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), tint.lerp(gem, 0.4), Color(gem, 0.0)])
	p.color_ramp = g
	p.emitting = true
	parent.add_child(p)
	parent.get_tree().create_timer(1.6 / maxf(0.1, spd)).timeout.connect(p.queue_free)
	DuelFX.rise(parent, pos + Vector2(0, 30), tint, 160.0 * depth, 40, 1.4, spd)
	DuelFX.flash(parent, pos, Color(0.9, 0.97, 1.0), 260.0 * depth, 0.4 / spd)
