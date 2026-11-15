class_name SealMark
extends RefCounted
## The mark on the hero's neck (Master Script v6/v7 had it on the collarbone;
## 15 November, Gary: "the glowing mark is meant to be on his neck not
## chest"): ash-grey, like a broken seal, kept under his collar all his life;
## it blazes white when the Last Seal falls into his hand at midnight and
## again when the Pale Herald turns to him. A small painted disc on the skin
## of the right side of his neck, under the jaw and above the collar, carried
## on the Neck bone so it moves with him; drawn here (a broken ring round a
## sigil, the break a jagged gap) until Gary paints one
## (assets/art/fx/seal_mark.png is used when it exists).
##
##   SealMark.show_on(w, true)     # seen (the mirror, the close-ups)
##   SealMark.blaze(w, 1.0, 0.4)   # white fire (0 back to ash-grey)

const ART := "res://assets/art/fx/seal_mark.png"
## Where it sits from the Neck bone, in the bone's own frame (m, rad; the
## bone's +x is his left): up the neck, out to his right and a little forward
## onto the skin, turned to face out from it there. (His right: asleep in the
## attic he lies on his back with his head to the west, and his right side
## is the one turned to the room; his left is to the wall.) Tuned on Player
## A's model; the other looks' necks have their own (AT_BY:
## tests/mark_neck_look.gd shows each).
## (Until 15 November: (0.055, -0.075, 0.075), turned (-0.35, 0, 0): down on
## the collarbone, under his collar.)
const AT := Vector3(-0.07, 0.077, 0.058)
const ROT := Vector3(0.0, -0.87, 0.0)
## Each look's own place and turn for it, where Player A's doesn't sit on
## that look's neck (the skin found round each one's Neck bone: Player C's
## neck is slimmer, Player D's shorter and thicker under his beard).
const AT_BY := {
	"player_b": [Vector3(-0.068, 0.093, 0.06), Vector3(0.0, -0.85, 0.0)],
	"player_c": [Vector3(-0.03, 0.06, 0.066), Vector3(0.0, -0.43, 0.0)],
	"player_d": [Vector3(-0.044, 0.055, 0.098), Vector3(0.0, -0.44, 0.0)],
}
const SIZE := 0.042
const ASH := Color(0.42, 0.41, 0.4)
const WHITE := Color(1.0, 0.98, 0.92)

static var _tex: Texture2D


static func _mark(w: World) -> MeshInstance3D:
	var pf = w.player_doll
	if not (pf is Figure3D) or (pf as Figure3D).model == null:
		return null
	return mark_on(pf as Figure3D)


## The mark on a figure (made the first time it's asked for, hidden).
static func mark_on(fig: Figure3D) -> MeshInstance3D:
	if fig == null or fig.model == null:
		return null
	var sk := fig.model.find_child("Skeleton3D", true, false) as Skeleton3D
	if sk == null:
		return null
	var got := sk.find_child("SealMark", true, false) as MeshInstance3D
	if got != null:
		return got
	if sk.find_bone("Neck") < 0:
		return null
	var ba := BoneAttachment3D.new()
	ba.name = "SealMarkBone"
	ba.bone_name = "Neck"
	sk.add_child(ba)
	var mi := MeshInstance3D.new()
	mi.name = "SealMark"
	var q := QuadMesh.new()
	q.size = Vector2(SIZE, SIZE)
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_texture = texture()
	m.albedo_color = ASH
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true
	m.emission = Color.BLACK
	m.emission_texture = texture()
	m.roughness = 0.8
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ba.add_child(mi)
	var own: Array = AT_BY.get(fig._model_name, [AT, ROT])
	mi.position = own[0]
	mi.rotation = own[1]
	mi.visible = false
	return mi


static func show_on(w: World, on: bool) -> void:
	var mi := _mark(w)
	if mi != null:
		mi.visible = on


## The mark's fire: 0 is ash-grey, 1 blazing white (over `secs`).
static func blaze(w: World, amount: float, secs := 0.3) -> void:
	var mi := _mark(w)
	if mi == null:
		return
	mi.visible = true
	var m := mi.material_override as StandardMaterial3D
	var from := m.emission.r / 6.0 if m.emission.r > 0.0 else 0.0
	var tw := w.create_tween()
	tw.tween_method(func(k: float) -> void:
		m.albedo_color = ASH.lerp(WHITE, k)
		m.emission = WHITE * (k * 6.0), from, clampf(amount, 0.0, 1.0), maxf(secs, 0.01))


## Gary's painting of the mark if there is one, else one drawn here: a ring
## broken at the top right, a cross-bar and a dot inside, soft-edged.
static func texture() -> Texture2D:
	if _tex != null:
		return _tex
	if ResourceLoader.exists(ART):
		_tex = load(ART)
		return _tex
	var n := 128
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := Vector2(n, n) * 0.5
	for y in n:
		for x in n:
			var p := Vector2(x + 0.5, y + 0.5) - c
			var r := p.length() / (n * 0.5)
			var ang := atan2(-p.y, p.x)
			var a := 0.0
			# the ring, broken by a jagged gap at about two o'clock
			var ring := 1.0 - clampf(absf(r - 0.78) / 0.09, 0.0, 1.0)
			var gap := absf(wrapf(ang - 0.62, -PI, PI))
			if gap < 0.32 + 0.06 * sin(r * 40.0):
				ring = 0.0
			a = maxf(a, ring)
			# an inner bar, and a dot under it, like the impression of a seal
			var bar := (1.0 - clampf(absf(p.y + n * 0.04) / (n * 0.035), 0.0, 1.0)) * (1.0 - clampf((absf(p.x) - n * 0.2) / (n * 0.03), 0.0, 1.0))
			a = maxf(a, bar)
			var dot := 1.0 - clampf((p - Vector2(0, n * 0.14)).length() / (n * 0.07), 0.0, 1.0)
			a = maxf(a, dot)
			a = clampf(a * 1.4, 0.0, 1.0) * 0.92
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_tex = ImageTexture.create_from_image(img)
	return _tex


# ------------------------------------------------- the mark held on black ---
## (15 November, Gary's yes to "the mark links the two times": the last
## picture of the Night of the White Sky is the child's mark glowing, and the
## first picture of the attic is the same mark on the grown hero, in the same
## place on screen.) The mark alone on black between the two: a picture of it
## drawn over everything (its own layer, above the subtitles and captions),
## at `at` (its middle, as a share of the screen) and `size` (its height, as
## a share of the screen's). WhiteSky puts it up over the child's own as the
## memory goes dark (hold), it stays through Morrowen's last line, the title
## and the attic's caption, and the attic's first shot is framed (frame) so
## the hero's own mark lies under it as it lets go.
##
##   var h := SealMark.hold(host, Vector2(0.5, 0.33), 0.15)   # up, dark
##   h.glow_to(1.0, 1.2)                                      # and lit
##   SealMark.held(tree)                                      # the one that's up, or null
const HOLD_GROUP := "seal_mark_held"

class Held:
	extends CanvasLayer
	var at := Vector2(0.5, 0.33)
	var size := 0.15
	## How brightly it's lit, 0..1 (glow_to).
	var k := 0.0
	## Seconds until it goes by itself (0: it stays until it's let go).
	var life := 0.0
	var _box: Control
	var _t := 0.0

	func _init() -> void:
		layer = 15   # (over the subtitles and captions, CineOverlay's 14)
		add_to_group(SealMark.HOLD_GROUP)

	func _ready() -> void:
		_box = Control.new()
		_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_box.draw.connect(_draw_mark)
		var cm := CanvasItemMaterial.new()
		cm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_box.material = cm
		add_child(_box)

	func _process(delta: float) -> void:
		_t += delta
		_box.queue_redraw()
		if life > 0.0:
			life -= delta
			if life <= 0.0 and is_in_group(SealMark.HOLD_GROUP):
				let_go(1.0)

	## Its light to `to` (0: gone) over `secs`.
	func glow_to(to: float, secs: float) -> Tween:
		var tw := create_tween()
		tw.tween_property(self, "k", to, maxf(secs, 0.01)).set_trans(Tween.TRANS_SINE)
		return tw

	## Fades and is gone.
	func let_go(secs: float) -> void:
		remove_from_group(SealMark.HOLD_GROUP)
		var tw := glow_to(0.0, secs)
		tw.tween_callback(queue_free)

	## Where its middle is on the screen, and its height (px).
	func middle() -> Vector2:
		return _box.size * at

	func height_px() -> float:
		return _box.size.y * size

	func _draw_mark() -> void:
		if k <= 0.001:
			return
		var c := middle()
		var h := height_px()
		# (a slow breath of light, as the child's has and the hero's as he wakes)
		var beat := 0.88 + 0.12 * sin(_t * 1.7)
		var soft := SealMark._soft()
		# the light round it, then the mark itself, twice for its heart
		var g := h * 3.4
		_box.draw_texture_rect(soft, Rect2(c - Vector2(g, g) * 0.5, Vector2(g, g)), false, Color(0.5, 0.56, 0.9, 0.34 * k * beat))
		var g2 := h * 1.7
		_box.draw_texture_rect(soft, Rect2(c - Vector2(g2, g2) * 0.5, Vector2(g2, g2)), false, Color(0.7, 0.76, 1.0, 0.3 * k * beat))
		var tex := SealMark.texture()
		_box.draw_texture_rect(tex, Rect2(c - Vector2(h, h) * 0.5, Vector2(h, h)), false, Color(0.86, 0.88, 0.96, k))
		_box.draw_texture_rect(tex, Rect2(c - Vector2(h, h) * 0.5, Vector2(h, h)), false, Color(0.5, 0.52, 0.6, 0.6 * k * beat))


## The mark put up on black (dark until glow_to): under `host` (the world,
## so it outlives the memory that put it up; or whatever plays the memory on
## its own).
static func hold(host: Node, at: Vector2, size: float) -> Held:
	var was := held(host.get_tree()) if host.is_inside_tree() else null
	if was != null:
		was.remove_from_group(HOLD_GROUP)
		was.queue_free()
	var h := Held.new()
	h.at = at
	h.size = size
	host.add_child(h)
	return h


## The mark that's up, if one is.
static func held(tree: SceneTree) -> Held:
	if tree == null:
		return null
	var n := tree.get_first_node_in_group(HOLD_GROUP)
	return n as Held if n != null and is_instance_valid(n) and not n.is_queued_for_deletion() else null


## Where a camera of `fov` degrees (up and down) stands to see a mark lying
## at `mark` (its middle; its face along +z, its top along +y), `size_m`
## across, at `at` on the screen and `size` of the screen's height tall:
## square on to it, its top up the picture.
static func frame(mark: Transform3D, size_m: float, fov: float, at: Vector2, size: float, aspect := 16.0 / 9.0) -> Transform3D:
	var n := mark.basis.z.normalized()
	var up := mark.basis.y.normalized()
	var side := up.cross(n).normalized()
	up = n.cross(side).normalized()
	var tall := size_m / maxf(size, 0.001)             # the picture's height at the mark (m)
	var d := tall / (2.0 * tan(deg_to_rad(fov) * 0.5))
	var pos := mark.origin + n * d - up * (0.5 - at.y) * tall + side * (0.5 - at.x) * tall * aspect
	return Transform3D(Basis(side, up, n), pos)


## The hero's mark seen through whatever lies over it (on), as light is seen
## through cloth: lying in bed his collar and the blanket may cover it, and
## the attic's first picture is of it glowing. Off: as it was again.
static func through(w: World, on: bool) -> void:
	var mi := _mark(w)
	if mi == null:
		return
	var m := mi.material_override as StandardMaterial3D
	m.no_depth_test = on
	m.render_priority = 2 if on else 0


## Its light going out over `secs` where it's seen through his shirt
## (through): fainter and gone, then hidden again and put away.
## (Faded to ash-grey as blaze does it, it was left lying on the cloth, and
## on the blanket as the camera drew back, like a grey stamp.)
static func go_out(w: World, secs: float) -> void:
	var mi := _mark(w)
	if mi == null:
		return
	var m := mi.material_override as StandardMaterial3D
	var from := maxf(m.emission.r / 6.0, 0.01)
	var tw := w.create_tween()
	tw.tween_method(func(k: float) -> void:
		var c := ASH.lerp(WHITE, k)
		m.albedo_color = Color(c.r, c.g, c.b, clampf(k / from, 0.0, 1.0))
		m.emission = WHITE * (k * 6.0), from, 0.0, maxf(secs, 0.01)).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void:
		if not is_instance_valid(mi):
			return
		mi.visible = false
		m.albedo_color = ASH
		m.emission = Color.BLACK
		m.no_depth_test = false
		m.render_priority = 0)


## The hero's own mark, where it lies now (null if he has no model).
static func on_hero(w: World) -> MeshInstance3D:
	return _mark(w)


## Where the hero's mark is (its middle, in the world), or `or_else` if he
## has no model to carry it.
static func where(w: World, or_else: Vector3) -> Vector3:
	var mi := _mark(w)
	return mi.global_position if mi != null else or_else


## A close shot of the hero's mark: [camera, looking at], the camera `dist`
## off it, out along its face and towards `fwd` (the way he faces) by
## `toward`, so it's seen on his neck rather than square on (15 November: the
## mark moved up onto his neck; the close shots of it looked under the Neck
## bone, at the collarbone, where it had been). Null without his model.
static func close_shot(w: World, dist: float, fwd: Vector3, toward := 0.45):
	var mi := _mark(w)
	if mi == null:
		return null
	var at := mi.global_position
	var n := mi.global_transform.basis.z.normalized()
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length() > 0.01 else n
	var out := n.lerp(fwd, toward).normalized()
	return [at + out * dist + Vector3(0, 0.03, 0), at]


static var _soft_tex: Texture2D

## A round soft light (for the light round the held mark).
static func _soft() -> Texture2D:
	if _soft_tex != null:
		return _soft_tex
	var n := 96
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var r := (Vector2(x + 0.5, y + 0.5) - Vector2(n, n) * 0.5).length() / (n * 0.5)
			var a := pow(clampf(1.0 - r, 0.0, 1.0), 2.2)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_soft_tex = ImageTexture.create_from_image(img)
	return _soft_tex
