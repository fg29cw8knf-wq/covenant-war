class_name PaleHerald
extends Node3D
## A Pale Herald, Morrowen's own: a grey horse that leaves no prints, and a
## rider whose hood is empty, carrying a staff topped with a pale lantern.
## Built from mist rather than flesh, so it reads as something not quite
## there: pale, see-through at the middle, bright at the edges, trailing fog
## from its hooves.
##
##   var h := PaleHerald.new(); add_child(h)
##   h.walking = true          # the slow, gliding walk
##   h.look_dir(Vector3.LEFT)  # turns (the whole of it)
##   h.turn_hood(target)       # just the empty hood turns to look
##   h.lantern_pos()           # where its lantern hangs (the visions come out of it)
##   h.lantern_flare(1.0)      # the lantern brightens (0 back to its glow)

const SHADER := """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_disabled;
uniform vec3 tint : source_color = vec3(0.80, 0.82, 0.88);
uniform float body = 0.42;
uniform float rim = 1.6;
uniform float fade = 1.0;
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
float h(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }
float n3(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	float a = mix(mix(h(i), h(i + vec3(1,0,0)), f.x), mix(h(i + vec3(0,1,0)), h(i + vec3(1,1,0)), f.x), f.y);
	float b = mix(mix(h(i + vec3(0,0,1)), h(i + vec3(1,0,1)), f.x), mix(h(i + vec3(0,1,1)), h(i + vec3(1,1,1)), f.x), f.y);
	return mix(a, b, f.z);
}
void fragment() {
	float fr = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.2);
	float swirl = n3(wpos * 2.6 + vec3(0.0, TIME * 0.35, TIME * 0.2)) * 0.6 + n3(wpos * 7.0 - vec3(TIME * 0.5)) * 0.4;
	ALBEDO = tint * (0.75 + 0.35 * swirl);
	EMISSION = tint * (0.10 + fr * rim * 0.6);
	ALPHA = clamp((body * (0.6 + 0.6 * swirl) + fr * rim * 0.55) * fade, 0.0, 1.0);
	ROUGHNESS = 1.0;
}
"""

## v7's shroud: grey burial cloth, opaque and heavy, in vertical folds with
## the wrappings showing, grimed, its hem torn ragged (each piece's bottom
## edge eaten away by noise: `half_h` is the piece's half-height), shifting
## slowly; it fades by dithering away, so it stays solid until it goes.
const CLOTH_SHADER := """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_disabled;
uniform vec3 tint : source_color = vec3(0.4, 0.41, 0.42);
uniform float fade = 1.0;
instance uniform float half_h = 1.0;
instance uniform float cut = 0.0;   // the hood: its face opened (an empty dark)
instance uniform float fray = 0.16;
instance uniform float folds = 0.06;
varying vec3 wpos;
varying float ang;
varying float low;
varying vec3 lp;
float h(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }
float n3(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	float a = mix(mix(h(i), h(i + vec3(1,0,0)), f.x), mix(h(i + vec3(0,1,0)), h(i + vec3(1,1,0)), f.x), f.y);
	float b = mix(mix(h(i + vec3(0,0,1)), h(i + vec3(1,0,1)), f.x), mix(h(i + vec3(0,1,1)), h(i + vec3(1,1,1)), f.x), f.y);
	return mix(a, b, f.z);
}
void vertex() {
	lp = VERTEX;
	ang = atan(VERTEX.z, VERTEX.x);
	low = clamp((half_h - VERTEX.y) / (2.0 * half_h), 0.0, 1.0);
	vec3 radial = vec3(VERTEX.x, 0.0, VERTEX.z);
	radial = length(radial) > 0.001 ? normalize(radial) : vec3(0.0, 0.0, 1.0);
	float f = sin(ang * 9.0 + n3(vec3(ang * 2.0, VERTEX.y * 1.5, 0.0)) * 3.0) * 0.5 + 0.5;
	float sway = sin(TIME * 0.9 + VERTEX.y * 2.2 + ang * 2.0);
	VERTEX += radial * f * folds * (0.4 + low);
	VERTEX.x += sway * 0.035 * low;
	VERTEX.z += cos(TIME * 0.7 + VERTEX.y * 1.7) * 0.035 * low;
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	// the torn hem
	float rag = n3(vec3(wpos.x * 5.0, 0.3, wpos.z * 5.0)) * 0.65 + n3(vec3(wpos.x * 17.0, 1.7, wpos.z * 17.0)) * 0.35;
	if (low > 1.0 - fray * rag) discard;
	if (cut > 0.5) {
		vec2 q = vec2(lp.x / 0.21, (lp.y + 0.06) / 0.27);
		if (lp.z > 0.0 && dot(q, q) < 1.0) discard;
	}
	// going: dithered away (it stays solid till then)
	if (h(vec3(floor(FRAGCOORD.xy), 3.1)) > fade) discard;
	float fold = sin(ang * 9.0) * 0.5 + 0.5;
	float band = fract(wpos.y * 1.7 + ang * 0.27);
	float wrap = smoothstep(0.38, 0.48, band) * (1.0 - smoothstep(0.52, 0.62, band));
	float grime = n3(wpos * 4.0) * 0.6 + n3(wpos * 13.0) * 0.4;
	vec3 c = tint * (0.62 + 0.38 * fold) * (0.72 + 0.42 * grime) * (1.0 - 0.28 * wrap);
	c *= mix(1.0, 0.72, low);   // dirtier down where it drags
	if (!FRONT_FACING) { c *= 0.28; }
	float fr = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.5);
	ALBEDO = c;
	EMISSION = vec3(0.5, 0.55, 0.65) * fr * 0.22;
	ROUGHNESS = 1.0;
}
"""

const VOID_SHADER := """
shader_type spatial;
render_mode unshaded, cull_front;
uniform float fade = 1.0;
void fragment() { ALBEDO = vec3(0.0); ALPHA = 0.96 * fade; }
"""

var walking := false
## "rider": the v3 Herald, a grey horse and an empty-hooded rider with a
## lantern on a staff. "shroud" (Master Script v7): "a towering, shifting mass
## of grey burial cloth and rusted iron chains", hovering inches above the
## grass, an empty hood at the top. Set before it's added to the tree.
var form := "rider"
var _t := 0.0
var _chains: Array = []     # [link node, phase]
var _legs: Array = []      # [hip node, phase]
var _body: Node3D
var _rider: Node3D
var _hood: Node3D
var _mat: ShaderMaterial
var _void: ShaderMaterial
var _mist: GPUParticles3D
var _lantern: Node3D
var _lantern_light: OmniLight3D
var _lantern_glow: MeshInstance3D
var _lantern_flame: MeshInstance3D
var _flare := 0.0
var _flare_to := 0.0
var _yaw := 0.0
var _want_yaw := 0.0
var _hood_yaw := 0.0
var _hood_want := 0.0
var fade := 1.0:
	set(v):
		fade = v
		if _mat != null:
			_mat.set_shader_parameter("fade", v)
			_void.set_shader_parameter("fade", v)
		if _mist != null:
			_mist.amount_ratio = clampf(v, 0.0, 1.0)


func _ready() -> void:
	_mat = ShaderMaterial.new()
	_mat.shader = Shader.new()
	_mat.shader.code = CLOTH_SHADER if form == "shroud" else SHADER
	_void = ShaderMaterial.new()
	_void.shader = Shader.new()
	_void.shader.code = VOID_SHADER
	_body = Node3D.new()
	add_child(_body)
	if form == "shroud":
		_build_shroud()
		_add_mist()
		return
	# the horse, facing +z: barrel, chest, neck, head, tail and four legs
	_cap(_body, 0.40, 1.9, Vector3(0, 1.42, -0.05), Vector3(PI / 2, 0, 0))
	_cap(_body, 0.37, 0.9, Vector3(0, 1.48, 0.72), Vector3(PI / 2 - 0.35, 0, 0))
	_cap(_body, 0.20, 1.05, Vector3(0, 1.95, 1.05), Vector3(0.62, 0, 0))
	_cap(_body, 0.15, 0.78, Vector3(0, 2.28, 1.42), Vector3(PI / 2 + 0.55, 0, 0))
	for sx in [-1, 1]:
		var ear := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = 0.045
		cm.height = 0.16
		ear.mesh = cm
		ear.material_override = _mat
		ear.position = Vector3(0.06 * sx, 2.55, 1.2)
		ear.rotation = Vector3(-0.3, 0, 0.2 * sx)
		_body.add_child(ear)
	_cap(_body, 0.11, 0.9, Vector3(0, 1.25, -1.15), Vector3(-0.5, 0, 0))
	for corner in [Vector2(-0.2, 0.62), Vector2(0.2, 0.62), Vector2(-0.2, -0.68), Vector2(0.2, -0.68)]:
		var hip := Node3D.new()
		hip.position = Vector3(corner.x, 1.28, corner.y)
		_body.add_child(hip)
		_cap(hip, 0.085, 1.28, Vector3(0, -0.62, 0), Vector3.ZERO)
		var phase := 0.0 if (corner.x < 0) == (corner.y > 0) else PI
		_legs.append([hip, phase])
	# the rider: a hooded robe, and nothing inside the hood
	_rider = Node3D.new()
	_rider.position = Vector3(0, 1.82, -0.15)
	_body.add_child(_rider)
	var robe := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = 0.2
	rm.bottom_radius = 0.5
	rm.height = 1.15
	rm.radial_segments = 20
	robe.mesh = rm
	robe.material_override = _mat
	robe.position = Vector3(0, 0.45, 0)
	_rider.add_child(robe)
	# the cloak falls over the horse's flanks
	var cloak := MeshInstance3D.new()
	var clm := CylinderMesh.new()
	clm.top_radius = 0.45
	clm.bottom_radius = 0.75
	clm.height = 0.7
	clm.radial_segments = 20
	cloak.mesh = clm
	cloak.material_override = _mat
	cloak.position = Vector3(0, -0.12, -0.05)
	_rider.add_child(cloak)
	_hood = Node3D.new()
	_hood.position = Vector3(0, 1.12, 0)
	_rider.add_child(_hood)
	var hood := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.24
	hm.height = 0.56
	hood.mesh = hm
	hood.material_override = _mat
	hood.scale = Vector3(1.0, 1.1, 1.05)
	_hood.add_child(hood)
	# the opening of the hood: black, and nothing behind it
	var hole := MeshInstance3D.new()
	var hh := SphereMesh.new()
	hh.radius = 0.15
	hh.height = 0.34
	hole.mesh = hh
	hole.material_override = _void
	hole.position = Vector3(0, -0.02, 0.14)
	hole.scale = Vector3(1.0, 1.2, 0.6)
	_hood.add_child(hole)
	var hole2 := MeshInstance3D.new()
	var hq := QuadMesh.new()
	hq.size = Vector2(0.24, 0.34)
	hole2.mesh = hq
	var vm := StandardMaterial3D.new()
	vm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	vm.albedo_color = Color(0, 0, 0)
	hole2.material_override = vm
	hole2.position = Vector3(0, -0.02, 0.215)
	_hood.add_child(hole2)
	# the staff in its right hand, upright, and the pale lantern at the top
	var staff := Node3D.new()
	staff.position = Vector3(-0.42, 0.35, 0.28)
	staff.rotation = Vector3(0.12, 0, 0.05)
	_rider.add_child(staff)
	var pole := MeshInstance3D.new()
	var pm0 := CylinderMesh.new()
	pm0.top_radius = 0.022
	pm0.bottom_radius = 0.03
	pm0.height = 2.6
	pm0.radial_segments = 8
	pole.mesh = pm0
	pole.material_override = _mat
	pole.position = Vector3(0, 0.5, 0)
	staff.add_child(pole)
	var hook := MeshInstance3D.new()
	var hm0 := TorusMesh.new()
	hm0.inner_radius = 0.07
	hm0.outer_radius = 0.1
	hook.mesh = hm0
	hook.material_override = _mat
	hook.position = Vector3(0, 1.84, 0.06)
	hook.rotation = Vector3(0, 0, PI / 2)
	staff.add_child(hook)
	_lantern = Node3D.new()
	_lantern.position = Vector3(0, 1.62, 0.14)
	staff.add_child(_lantern)
	var cage := MeshInstance3D.new()
	var cm0 := CylinderMesh.new()
	cm0.top_radius = 0.07
	cm0.bottom_radius = 0.1
	cm0.height = 0.24
	cm0.radial_segments = 6
	cage.mesh = cm0
	cage.material_override = _mat
	_lantern.add_child(cage)
	var glass := StandardMaterial3D.new()
	glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glass.albedo_color = Color(0.9, 0.95, 1.0)
	glass.emission_enabled = true
	glass.emission = Color(0.82, 0.9, 1.0)
	glass.emission_energy_multiplier = 2.5
	var flame := MeshInstance3D.new()
	var fm0 := SphereMesh.new()
	fm0.radius = 0.055
	fm0.height = 0.13
	flame.mesh = fm0
	flame.material_override = glass
	_lantern.add_child(flame)
	_lantern_flame = flame
	_lantern_glow = MeshInstance3D.new()
	var gq := QuadMesh.new()
	gq.size = Vector2(0.9, 0.9)
	_lantern_glow.mesh = gq
	var gm := StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	gm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var gg := Gradient.new(); gg.set_color(0, Color(1, 1, 1, 1)); gg.set_color(1, Color(1, 1, 1, 0))
	var ggt := GradientTexture2D.new(); ggt.gradient = gg; ggt.fill = GradientTexture2D.FILL_RADIAL
	ggt.fill_from = Vector2(0.5, 0.5); ggt.fill_to = Vector2(0.5, 0.0)
	gm.albedo_texture = ggt
	gm.albedo_color = Color(0.75, 0.85, 1.0, 0.55)
	_lantern_glow.material_override = gm
	_lantern_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_lantern.add_child(_lantern_glow)
	_lantern_light = OmniLight3D.new()
	_lantern_light.light_color = Color(0.78, 0.86, 1.0)
	_lantern_light.light_energy = 0.8
	_lantern_light.omni_range = 5.0
	_lantern.add_child(_lantern_light)
	_add_mist()


## A cold light about it, and mist off its hooves (or the hem of its shroud).
func _add_mist() -> void:
	var l := OmniLight3D.new()
	l.light_color = Color(0.75, 0.8, 0.95)
	l.light_energy = 1.2
	l.omni_range = 6.0
	l.position = Vector3(0, 1.6, 0.4)
	add_child(l)
	_mist = GPUParticles3D.new()
	_mist.amount = 40
	_mist.lifetime = 3.2
	_mist.local_coords = false
	_mist.position = Vector3(0, 0.15, 0)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(0.6, 0.1, 1.0)
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 60.0
	pm.initial_velocity_min = 0.1
	pm.initial_velocity_max = 0.35
	pm.gravity = Vector3(0, 0.05, 0)
	pm.scale_min = 1.6
	pm.scale_max = 2.8
	var sc := Curve.new(); sc.add_point(Vector2(0, 0.3)); sc.add_point(Vector2(0.4, 1.0)); sc.add_point(Vector2(1, 1.4))
	var sct := CurveTexture.new(); sct.curve = sc
	pm.scale_curve = sct
	var ac := Gradient.new()
	ac.set_color(0, Color(1, 1, 1, 0))
	ac.add_point(0.3, Color(1, 1, 1, 0.5))
	ac.set_color(1, Color(1, 1, 1, 0))
	var act := GradientTexture1D.new(); act.gradient = ac
	pm.color_ramp = act
	_mist.process_material = pm
	var q := QuadMesh.new(); q.size = Vector2(1, 1)
	_mist.draw_pass_1 = q
	var mm := StandardMaterial3D.new()
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mm.vertex_color_use_as_albedo = true
	mm.albedo_color = Color(0.85, 0.87, 0.92, 0.55)
	var g := Gradient.new(); g.set_color(0, Color(1, 1, 1, 1)); g.set_color(1, Color(1, 1, 1, 0))
	var gt := GradientTexture2D.new(); gt.gradient = g; gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5); gt.fill_to = Vector2(0.5, 0.0)
	mm.albedo_texture = gt
	_mist.material_override = mm
	_mist.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mist.visibility_aabb = AABB(Vector3(-6, -1, -6), Vector3(12, 6, 12))
	add_child(_mist)


## v7's Herald: a towering mass of grey burial cloth, a heavy robe under a
## mantle and a wrap, torn strips hanging off it all round, rising to a hood
## with nothing in it; rusted iron chains hang in loops about it and sway;
## it hovers just off the grass. Its "lantern" is a pale light inside the
## cloth at the chest (the faces come out of it).
func _build_shroud() -> void:
	# [top radius, bottom radius, height, bottom y, turn, fray, folds]
	var pieces := [[0.3, 0.98, 2.95, 0.0, 0.0, 0.1, 0.07], [0.38, 0.9, 1.35, 1.68, 0.6, 0.3, 0.06],
		[0.78, 1.12, 0.95, 0.32, 1.9, 0.45, 0.08]]
	for P in pieces:
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = P[0]
		cm.bottom_radius = P[1]
		cm.height = P[2]
		cm.radial_segments = 48
		cm.rings = 24
		cm.cap_top = false
		cm.cap_bottom = false
		mi.mesh = cm
		mi.material_override = _mat
		mi.position = Vector3(0.0, float(P[3]) + float(P[2]) * 0.5, 0.0)
		mi.rotation.y = P[4]
		mi.set_instance_shader_parameter("half_h", float(P[2]) * 0.5)
		mi.set_instance_shader_parameter("fray", P[5])
		mi.set_instance_shader_parameter("folds", P[6])
		_body.add_child(mi)
	# torn strips of cloth hanging off it all round, longer low down
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for k in 18:
		var a := TAU * k / 18.0 + rng.randf_range(-0.12, 0.12)
		var y := rng.randf_range(0.5, 2.3)
		var rad := lerpf(1.02, 0.5, (y - 0.5) / 1.8) + 0.04
		var len := rng.randf_range(0.8, 1.5) * (1.2 - (y - 0.5) / 3.6)
		var strip := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(rng.randf_range(0.12, 0.24), len)
		pm.subdivide_depth = 8
		pm.orientation = PlaneMesh.FACE_Z
		strip.mesh = pm
		strip.material_override = _mat
		strip.position = Vector3(cos(a) * rad, y - len * 0.5 + 0.1, sin(a) * rad)
		strip.rotation = Vector3(0.0, -a + PI * 0.5, 0.0)
		strip.rotate_object_local(Vector3.RIGHT, -0.08)
		strip.set_instance_shader_parameter("half_h", len * 0.5)
		strip.set_instance_shader_parameter("fray", 0.35)
		strip.set_instance_shader_parameter("folds", 0.0)
		_body.add_child(strip)
	_rider = Node3D.new()
	_rider.position = Vector3(0, 2.95, 0)
	_body.add_child(_rider)
	_hood = Node3D.new()
	_hood.position = Vector3(0, 0.26, 0.05)
	_rider.add_child(_hood)
	var hood := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.42
	hm.height = 0.92
	hm.radial_segments = 32
	hm.rings = 16
	hood.mesh = hm
	hood.material_override = _mat
	hood.scale = Vector3(1.0, 1.12, 1.1)
	hood.set_instance_shader_parameter("half_h", 0.46)
	hood.set_instance_shader_parameter("fray", 0.12)
	hood.set_instance_shader_parameter("folds", 0.03)
	hood.set_instance_shader_parameter("cut", 1.0)
	_hood.add_child(hood)
	var hole := MeshInstance3D.new()
	var hh := SphereMesh.new()
	hh.radius = 0.22
	hh.height = 0.5
	hole.mesh = hh
	hole.material_override = _void
	hole.position = Vector3(0, -0.04, 0.22)
	hole.scale = Vector3(1.0, 1.2, 0.6)
	_hood.add_child(hole)
	var hole2 := MeshInstance3D.new()
	var hq := QuadMesh.new()
	hq.size = Vector2(0.3, 0.44)
	hole2.mesh = hq
	var vm := StandardMaterial3D.new()
	vm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	vm.albedo_color = Color(0, 0, 0)
	hole2.material_override = vm
	hole2.position = Vector3(0, -0.04, 0.33)
	_hood.add_child(hole2)
	# rusted iron chains: loops of links about the cloth, swaying
	var rust := StandardMaterial3D.new()
	rust.albedo_color = Color(0.21, 0.13, 0.09)
	rust.metallic = 0.6
	rust.roughness = 0.85
	var loops := [[1.05, 0.86, 0.0], [1.6, 0.72, 1.2], [2.2, 0.56, 2.3], [0.62, 1.02, 3.6], [2.6, 0.46, 4.7]]
	for L in loops:
		var chain := Node3D.new()
		chain.position = Vector3(0, float(L[0]), 0)
		chain.rotation = Vector3(0.22, float(L[2]), 0.08)
		_body.add_child(chain)
		var r: float = L[1] + 0.06
		var links := 26
		for j in links:
			var a := PI * 1.15 * j / float(links - 1) - PI * 0.575
			var link := MeshInstance3D.new()
			var tm := TorusMesh.new()
			tm.inner_radius = 0.03
			tm.outer_radius = 0.058
			tm.rings = 10
			tm.ring_segments = 5
			link.mesh = tm
			link.material_override = rust
			# a sagging arc round the front of the cloth
			link.position = Vector3(sin(a) * r, -0.32 * cos(a * 0.87) + 0.32, cos(a) * r)
			link.rotation = Vector3(0.0, a, PI * 0.5 * (j % 2))
			chain.add_child(link)
		_chains.append([chain, float(L[2])])
	# the light the faces come out of, low in the cloth at the chest
	_lantern = Node3D.new()
	_lantern.position = Vector3(0, 2.2, 0.55)
	_body.add_child(_lantern)
	var glass := StandardMaterial3D.new()
	glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glass.albedo_color = Color(0.9, 0.95, 1.0)
	var flame := MeshInstance3D.new()
	var fm0 := SphereMesh.new()
	fm0.radius = 0.02
	fm0.height = 0.04
	flame.mesh = fm0
	flame.material_override = glass
	_lantern.add_child(flame)
	_lantern_flame = flame
	_lantern_glow = MeshInstance3D.new()
	var gq := QuadMesh.new()
	gq.size = Vector2(1.2, 1.2)
	_lantern_glow.mesh = gq
	var gm := StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	gm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var gg := Gradient.new(); gg.set_color(0, Color(1, 1, 1, 1)); gg.set_color(1, Color(1, 1, 1, 0))
	var ggt := GradientTexture2D.new(); ggt.gradient = gg; ggt.fill = GradientTexture2D.FILL_RADIAL
	ggt.fill_from = Vector2(0.5, 0.5); ggt.fill_to = Vector2(0.5, 0.0)
	gm.albedo_texture = ggt
	gm.albedo_color = Color(0.75, 0.85, 1.0, 0.35)
	_lantern_glow.material_override = gm
	_lantern_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_lantern.add_child(_lantern_glow)
	_lantern_light = OmniLight3D.new()
	_lantern_light.light_color = Color(0.78, 0.86, 1.0)
	_lantern_light.light_energy = 0.6
	_lantern_light.omni_range = 5.0
	_lantern.add_child(_lantern_light)


func _cap(parent: Node3D, r: float, h: float, pos: Vector3, rot: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = r
	cm.height = maxf(h, r * 2.0)
	cm.radial_segments = 16
	cm.rings = 6
	mi.mesh = cm
	mi.material_override = _mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


## Turns the horse to face along `dir`.
func look_dir(dir: Vector3) -> void:
	dir.y = 0.0
	if dir.length() > 0.01:
		_want_yaw = atan2(dir.x, dir.z)


func snap_dir(dir: Vector3) -> void:
	look_dir(dir)
	_yaw = _want_yaw
	rotation.y = _yaw


## Turns the empty hood (only) towards a point.
func turn_hood(point: Vector3) -> void:
	var local := to_local(point)
	_hood_want = clampf(atan2(local.x, local.z), -1.3, 1.3)


## Where the hood is, for aiming a camera at it.
func hood_pos() -> Vector3:
	return _hood.global_position


## Where the lantern on its staff hangs.
func lantern_pos() -> Vector3:
	return _lantern.global_position


## The lantern brightens (1) as it shows something, or settles back (0).
func lantern_flare(to: float) -> void:
	_flare_to = to


func _process(delta: float) -> void:
	_t += delta
	_yaw += wrapf(_want_yaw - _yaw, -PI, PI) * minf(1.0, delta * 2.5)
	rotation.y = _yaw
	_hood_yaw += (_hood_want - _hood_yaw) * minf(1.0, delta * 1.6)
	_hood.rotation.y = _hood_yaw
	var k := 1.0 if walking else 0.0
	for leg in _legs:
		var hip: Node3D = leg[0]
		hip.rotation.x = sin(_t * 3.4 + float(leg[1])) * 0.32 * k
	if form == "shroud":
		# hovering just off the grass, the cloth shifting, the chains swaying
		_body.position.y = 0.12 + sin(_t * 0.8) * 0.05
		_body.rotation.y = sin(_t * 0.37) * 0.05
		for c in _chains:
			(c[0] as Node3D).rotation.z = 0.08 + sin(_t * 1.1 + float(c[1]) * 2.0) * 0.06
	else:
		_body.position.y = (absf(sin(_t * 3.4)) * 0.05 * k) + sin(_t * 0.9) * 0.03
	_rider.rotation.z = sin(_t * 1.7) * 0.02
	_flare = move_toward(_flare, _flare_to, delta * 2.5)
	if _lantern_light != null:
		_lantern_light.light_energy = (0.8 + _flare * 3.2 + sin(_t * 2.3) * 0.08) * fade
		_lantern_glow.scale = Vector3.ONE * (1.0 + _flare * 1.6) * maxf(0.01, fade)
		_lantern_flame.visible = fade > 0.25
