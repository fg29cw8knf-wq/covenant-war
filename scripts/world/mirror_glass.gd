class_name MirrorGlass
extends Node3D
## A live reflection in a flat mirror's glass: the room drawn again from the
## camera's place turned through the glass (a second camera behind it, its
## view cut to the glass's edges), shown on a sheet laid over the glass and
## trimmed to its oval. Only while it's wanted: the attic mirror while the
## player is at it (27 October, Gary: wiping the frost off showed "an outline
## of the body", and nothing of him in the glass).
##   var g := MirrorGlass.start(w, oval_node, Vector3(-0.036, 0, 0), 0.27, 0.27 * 1.32)
##   ... g.stop()

const PX := 420.0          # the reflection's height in pixels (its width by the glass's shape)

var centre := Vector3.ZERO
var normal := Vector3.FORWARD   # out of the glass, into the room
var up := Vector3.UP
var half_w := 0.27
var half_h := 0.36
var vp: SubViewport
var cam: Camera3D
var sheet: MeshInstance3D
var _mat: ShaderMaterial

const SHADER := """
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque;
uniform sampler2D refl : source_color, filter_linear, repeat_disable;
uniform vec3 tint : source_color = vec3(0.86, 0.9, 0.94);
uniform float fade = 1.0;
void fragment() {
	vec2 c = (UV - 0.5) * 2.0;
	float r = length(c);
	if (r > 1.0) discard;
	// a mirror shows the room the other way round
	vec3 col = texture(refl, vec2(1.0 - UV.x, UV.y)).rgb;
	// old silvering: a touch cold, a little dim towards the rim
	float rim = smoothstep(0.55, 1.0, r);
	col *= tint * (1.0 - rim * 0.35);
	col = mix(vec3(0.33, 0.36, 0.4), col, fade);
	ALBEDO = col;
}
"""


## A reflection on the glass of `oval`: its face at `local_centre` in the
## oval's own space, facing the oval's -X (the attic mirror's way), the
## glass `hw` by `hh` metres from its middle to its side and to its top.
static func start(parent: Node, oval: Node3D, local_centre: Vector3, hw: float, hh: float) -> MirrorGlass:
	var g := MirrorGlass.new()
	g.name = "MirrorGlass"
	parent.add_child(g)
	g.centre = oval.to_global(local_centre)
	g.normal = -(oval.global_transform.basis.x).normalized()
	g.half_w = hw
	g.half_h = hh
	g._build()
	return g


func _build() -> void:
	vp = SubViewport.new()
	vp.size = Vector2i(roundi(PX * half_w / half_h), roundi(PX))
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_DISABLED
	# (the room's lamps cast their shadows in the glass too)
	add_child(vp)
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_FRUSTUM
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	vp.add_child(cam)
	cam.current = true
	sheet = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(half_w * 2.0, half_h * 2.0)
	sheet.mesh = q
	sheet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var sh := Shader.new()
	sh.code = SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	_mat.set_shader_parameter("refl", vp.get_texture())
	sheet.material_override = _mat
	add_child(sheet)
	# square to the glass, a hair in front of it (behind the frost)
	var right := up.cross(normal).normalized()
	sheet.global_transform = Transform3D(Basis(right, up, normal), centre + normal * 0.0015)
	_follow()


func _process(_delta: float) -> void:
	_follow()


## The second camera: where the one in use would be if the glass were a
## window, looking out through it, its view cut to the glass's edges.
func _follow() -> void:
	var view := get_viewport().get_camera_3d() if is_inside_tree() else null
	if view == null or cam == null:
		return
	var c := view.global_position
	var d := (c - centre).dot(normal)
	sheet.visible = d > 0.02
	if d <= 0.02:
		return   # (looking at it from behind, or edge on: nothing to show)
	var at := c - 2.0 * d * normal
	var b := Basis.looking_at(normal, up)
	cam.global_transform = Transform3D(b, at)
	# the near plane just past the glass (the frost and the frame stay out
	# of it), so everything scales from there
	var near := d + 0.012
	var k := near / d
	var rel := centre - at
	cam.set_frustum(half_h * 2.0 * k, Vector2(rel.dot(b.x), rel.dot(b.y)) * k, near, 40.0)


## Frost back on it: 1 the room shows clear, 0 a flat grey.
func set_clear(u: float) -> void:
	if _mat != null:
		_mat.set_shader_parameter("fade", clampf(u, 0.0, 1.0))


func stop() -> void:
	if vp != null:
		vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	queue_free()
