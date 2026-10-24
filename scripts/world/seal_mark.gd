class_name SealMark
extends RefCounted
## The mark on the hero's collarbone (Master Script v6/v7): ash-grey, like a
## broken seal, hidden under his collar all his life; it blazes white when the
## Last Seal falls into his hand at midnight and again when the Pale Herald
## turns to him. A small painted disc on the skin over the left collarbone,
## carried on the Neck bone so it moves with him; drawn here (a broken ring
## round a sigil, the break a jagged gap) until Gary paints one
## (assets/art/fx/seal_mark.png is used when it exists).
##
##   SealMark.show_on(w, true)     # seen (the mirror, the close-ups)
##   SealMark.blaze(w, 1.0, 0.4)   # white fire (0 back to ash-grey)

const ART := "res://assets/art/fx/seal_mark.png"
## Where it sits from the Neck bone, in the bone's own frame (m, rad): down
## to the collarbone, forward onto the skin, a little to his left. Tuned on
## Player A's model.
const AT := Vector3(0.055, -0.075, 0.075)
const ROT := Vector3(-0.35, 0.0, 0.0)
const SIZE := 0.05
const ASH := Color(0.42, 0.41, 0.4)
const WHITE := Color(1.0, 0.98, 0.92)

static var _tex: Texture2D


static func _mark(w: World) -> MeshInstance3D:
	var pf = w.player_doll
	if not (pf is Figure3D) or (pf as Figure3D).model == null:
		return null
	var sk := (pf as Figure3D).model.find_child("Skeleton3D", true, false) as Skeleton3D
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
	mi.position = AT
	mi.rotation = ROT
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
