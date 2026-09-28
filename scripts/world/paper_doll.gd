class_name PaperDoll
extends Node3D
## A character drawn as a painted cut-out standing in the 3D world: always
## upright and facing the camera, with a soft shadow, a little bounce when
## walking, and a front/back picture depending on which way they're heading.

var char_id := "player"
var walking := false
var facing_back := false
var facing_left := false

var _sprite: Sprite3D
var _shadow: MeshInstance3D
var _marker: Sprite3D
var _t := 0.0
var _marker_kind := ""

static var _shadow_mat: StandardMaterial3D


func setup(id: String) -> PaperDoll:
	char_id = id
	return self


func _ready() -> void:
	_sprite = Sprite3D.new()
	_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_sprite.shaded = false
	_sprite.double_sided = true
	_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_sprite)
	_apply_texture()

	_shadow = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1.15, 0.6)
	_shadow.mesh = q
	_shadow.rotation_degrees.x = -90
	_shadow.position.y = 0.03
	_shadow.material_override = _get_shadow_mat()
	_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_shadow)

	_marker = Sprite3D.new()
	_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_marker.shaded = false
	_marker.no_depth_test = true
	_marker.render_priority = 10
	_marker.pixel_size = 0.0045
	_marker.position.y = DollArt.WORLD_HEIGHT * 0.98
	_marker.visible = false
	add_child(_marker)


func _apply_texture() -> void:
	var tex := DollArt.texture(char_id, "back" if facing_back else "front")
	_sprite.texture = tex
	_sprite.pixel_size = DollArt.WORLD_HEIGHT / float(tex.get_height())
	_sprite.offset = Vector2(0, tex.get_height() * 0.5)
	_sprite.flip_h = facing_left


## Face along a world-space direction, relative to the camera.
func face(dir: Vector3, cam: Camera3D) -> void:
	if dir.length() < 0.01 or cam == null:
		return
	var right := cam.global_transform.basis.x
	var fwd := -cam.global_transform.basis.z
	fwd.y = 0
	fwd = fwd.normalized()
	var x := dir.dot(right)
	var z := dir.dot(fwd)
	var back := z > 0.35
	var left := x < -0.15 if absf(x) > 0.15 else facing_left
	if back != facing_back or left != facing_left:
		facing_back = back
		facing_left = left
		_apply_texture()


## Turn to face a point (e.g. the player when talking).
func look_toward(point: Vector3, cam: Camera3D) -> void:
	var d := point - global_position
	d.y = 0
	if d.length() > 0.01:
		face(d.normalized(), cam)
		if facing_back:
			facing_back = false
			_apply_texture()


## "" hides it; "talk" or "duel" shows an icon over the character's head.
func set_marker(kind: String) -> void:
	if kind == _marker_kind:
		return
	_marker_kind = kind
	if kind == "":
		_marker.visible = false
		return
	_marker.texture = _badge(kind)
	_marker.pixel_size = 0.55 / _marker.texture.get_width()
	_marker.visible = true


func _process(delta: float) -> void:
	_t += delta
	if walking:
		var b := sin(_t * 12.0)
		_sprite.position.y = absf(b) * 0.07
		_sprite.scale = Vector3(1.0 + b * 0.025, 1.0 - absf(b) * 0.03, 1.0)
	else:
		# gentle breathing
		var br := sin(_t * 2.2)
		_sprite.position.y = lerpf(_sprite.position.y, 0.0, minf(1.0, delta * 10.0))
		_sprite.scale = Vector3(1.0 - br * 0.006, 1.0 + br * 0.012, 1.0)
	if _marker.visible:
		_marker.position.y = DollArt.WORLD_HEIGHT * 0.98 + sin(_t * 3.0) * 0.06


static var _badges := {}


## A round badge with an icon: gold for a duel, pale for a chat.
static func _badge(kind: String) -> Texture2D:
	if _badges.has(kind):
		return _badges[kind]
	var bg := "#f2c96b" if kind == "duel" else "#f4efe4"
	var icon: String = String(Glyphs.SHAPES.get(kind, "")).replace("#fff", "#1c1a26").replace("#000", "#f2c96b")
	var svg := "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 120 132'>" + \
		"<path d='M60 128 L48 104 H72 Z' fill='#1c1a26'/>" + \
		"<circle cx='60' cy='56' r='52' fill='#1c1a26'/><circle cx='60' cy='56' r='46' fill='%s'/>" % bg + \
		"<g transform='translate(29 25) scale(0.62)'>%s</g></svg>" % icon
	var img := Image.new()
	if img.load_svg_from_string(svg, 1.5) != OK:
		img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_badges[kind] = t
	return t


static func _get_shadow_mat() -> StandardMaterial3D:
	if _shadow_mat != null:
		return _shadow_mat
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0.5))
	g.set_color(1, Color(0, 0, 0, 0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 128
	gt.height = 128
	var m := StandardMaterial3D.new()
	m.albedo_texture = gt
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	_shadow_mat = m
	return m
