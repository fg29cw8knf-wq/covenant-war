class_name PaleHerald
extends Node3D
## A Pale Herald, Morrowen's own: a grey horse that leaves no prints, and a
## rider whose hood is empty. Built from mist rather than flesh, so it reads
## as something not quite there: pale, see-through at the middle, bright at
## the edges, trailing fog from its hooves.
##
##   var h := PaleHerald.new(); add_child(h)
##   h.walking = true          # the slow, gliding walk
##   h.look_dir(Vector3.LEFT)  # turns (the whole of it)
##   h.turn_hood(target)       # just the empty hood turns to look

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

const VOID_SHADER := """
shader_type spatial;
render_mode unshaded, cull_front;
uniform float fade = 1.0;
void fragment() { ALBEDO = vec3(0.0); ALPHA = 0.96 * fade; }
"""

var walking := false
var _t := 0.0
var _legs: Array = []      # [hip node, phase]
var _body: Node3D
var _rider: Node3D
var _hood: Node3D
var _mat: ShaderMaterial
var _void: ShaderMaterial
var _mist: GPUParticles3D
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
	_mat.shader.code = SHADER
	_void = ShaderMaterial.new()
	_void.shader = Shader.new()
	_void.shader.code = VOID_SHADER
	_body = Node3D.new()
	add_child(_body)
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
	# a cold light about it, and mist off its hooves
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
	_body.position.y = (absf(sin(_t * 3.4)) * 0.05 * k) + sin(_t * 0.9) * 0.03
	_rider.rotation.z = sin(_t * 1.7) * 0.02
