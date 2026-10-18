class_name InnRooms
extends RefCounted
## The inside of the Crooked Lantern, for the Prologue's cutscenes: the
## taproom (the afternoon after the Sigilfall, shutters closed, Bram and the
## blank card) and the cellar (the night Ashford burns, Bram's chest of old
## decks and the smugglers' trapdoor).
##
## Both are built out of the village's own materials, well below the ground
## (nothing outside can be seen from in here), and only once they're needed.
## Each returns a Dictionary of the marks the cutscene stages around.

const TAPROOM_AT := Vector3(0.0, -40.0, 0.0)
const CELLAR_AT := Vector3(30.0, -40.0, 0.0)
## Prologue P1, the evening before: the attic the player wakes in, and the
## taproom with Bram stacking paper lanterns into a crate (attic(), eve()).
const ATTIC_AT := Vector3(0.0, -40.0, 30.0)
const EVE_AT := Vector3(30.0, -40.0, 30.0)


## The taproom: plaster and black beams, a long bar, the hearth, a table with a
## lamp, and the shutters closed against the village with the day leaking in.
static func taproom(v: AshfordVillage) -> Dictionary:
	if v.has_meta("taproom"):
		return v.get_meta("taproom")
	var o := TAPROOM_AT
	var root := Node3D.new()
	root.name = "Taproom"
	root.position = o
	v.add_child(root)
	var W := 9.0
	var D := 7.0
	var H := 3.1
	# floor, ceiling and walls
	v.box(root, Vector3(W, 0.2, D), Vector3(0, -0.1, 0), v.mats.wood_h)
	v.box(root, Vector3(W, 0.2, D), Vector3(0, H + 0.1, 0), v.mats.beam)
	for side in [[Vector3(W, H, 0.3), Vector3(0, H * 0.5, -D * 0.5 - 0.15)], [Vector3(W, H, 0.3), Vector3(0, H * 0.5, D * 0.5 + 0.15)],
			[Vector3(0.3, H, D), Vector3(-W * 0.5 - 0.15, H * 0.5, 0)], [Vector3(0.3, H, D), Vector3(W * 0.5 + 0.15, H * 0.5, 0)]]:
		v.box(root, side[0], side[1], v.mats.stone_ww2)
	# beams: posts round the walls, and across the ceiling
	for x in [-4.3, -2.2, 0.0, 2.2, 4.3]:
		v.box(root, Vector3(0.22, H, 0.22), Vector3(x, H * 0.5, -D * 0.5 + 0.05), v.mats.beam_v)
		v.box(root, Vector3(0.22, H, 0.22), Vector3(x, H * 0.5, D * 0.5 - 0.05), v.mats.beam_v)
	for z in [-2.6, -1.3, 0.0, 1.3, 2.6]:
		v.box(root, Vector3(W, 0.24, 0.2), Vector3(0, H - 0.12, z), v.mats.beam)
	v.box(root, Vector3(W, 0.2, 0.2), Vector3(0, 1.0, -D * 0.5 + 0.06), v.mats.beam)
	v.box(root, Vector3(W, 0.2, 0.2), Vector3(0, 1.0, D * 0.5 - 0.06), v.mats.beam)
	# the bar along the back wall, with the barrels and bottles behind it
	v.box(root, Vector3(4.6, 1.05, 0.7), Vector3(-1.4, 0.525, -2.3), v.mats.wood)
	v.box(root, Vector3(4.8, 0.08, 0.85), Vector3(-1.4, 1.09, -2.3), v.mats.beam)
	for y in [1.55, 2.15]:
		v.box(root, Vector3(4.2, 0.05, 0.3), Vector3(-1.4, y, -D * 0.5 + 0.18), v.mats.wood_h)
	var glass_cols := [Color(0.18, 0.32, 0.12), Color(0.35, 0.16, 0.08), Color(0.12, 0.16, 0.3), Color(0.4, 0.3, 0.1)]
	for i in 22:
		var b := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.03
		cm.bottom_radius = 0.045
		cm.height = 0.28
		cm.radial_segments = 8
		b.mesh = cm
		var gm := StandardMaterial3D.new()
		gm.albedo_color = glass_cols[i % glass_cols.size()]
		gm.roughness = 0.15
		gm.metallic = 0.2
		b.material_override = gm
		b.position = Vector3(-3.3 + (i % 11) * 0.38 + v.rng.randf_range(-0.05, 0.05), 1.72 if i < 11 else 2.32, -D * 0.5 + 0.2)
		root.add_child(b)
	for k in 3:
		var bar := v.make_barrel()
		bar.position = Vector3(1.4 + k * 0.7, AshfordVillage.BARREL_HALF, -3.0)
		root.add_child(bar)
	var top := v.make_barrel()
	top.position = Vector3(2.1, AshfordVillage.BARREL_HALF * 3.0, -3.0)
	top.rotation.z = PI * 0.5
	root.add_child(top)
	# the hearth on the east wall, low and red
	v.box(root, Vector3(0.7, H, 2.2), Vector3(W * 0.5 - 0.35, H * 0.5, 0.6), v.mats.stone)
	v.box(root, Vector3(0.3, 0.9, 1.1), Vector3(W * 0.5 - 0.62, 0.45, 0.6), v.mats.dark)
	_hearth(v, root, Vector3(W * 0.5 - 0.75, 0.12, 0.6))
	# shutters closed on the south wall, the day leaking through the cracks
	for x in [-2.6, 1.6]:
		v.box(root, Vector3(1.3, 1.3, 0.12), Vector3(x, 1.7, D * 0.5 - 0.06), v.mats.door_natural)
		for k in 3:
			var slit := MeshInstance3D.new()
			var q := QuadMesh.new()
			q.size = Vector2(1.2, 0.025)
			slit.mesh = q
			var sm := StandardMaterial3D.new()
			sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			sm.albedo_color = Color(1.0, 0.86, 0.62) * 3.0
			slit.material_override = sm
			slit.position = Vector3(x, 1.35 + k * 0.33, D * 0.5 - 0.13)
			slit.rotation.y = PI
			root.add_child(slit)
		var shaft := SpotLight3D.new()
		shaft.light_color = Color(1.0, 0.82, 0.6)
		shaft.light_energy = 3.0
		shaft.spot_range = 7.0
		shaft.spot_angle = 22.0
		shaft.light_volumetric_fog_energy = 2.0
		shaft.shadow_enabled = v.quality > 0
		root.add_child(shaft)
		shaft.position = Vector3(x, 1.8, D * 0.5 - 0.3)
		shaft.look_at(root.to_global(Vector3(x * 0.6, 0.0, 0.4)), Vector3.UP)
	# the table, two stools, the lamp and the card
	var t := Vector3(0.2, 0.0, 0.5)
	v.cyl(root, 0.8, 0.8, 0.07, t + Vector3(0, 0.78, 0), v.mats.wood_h, 24)
	v.cyl(root, 0.1, 0.16, 0.76, t + Vector3(0, 0.38, 0), v.mats.beam_v, 10)
	v.cyl(root, 0.32, 0.32, 0.05, t + Vector3(0, 0.02, 0), v.mats.beam_v, 16)
	for dz in [-1.05, 1.05]:
		v.cyl(root, 0.24, 0.22, 0.48, t + Vector3(0.0, 0.24, dz), v.mats.wood, 14)
	var lamp := v.box(root, Vector3(0.16, 0.24, 0.16), t + Vector3(0.38, 0.95, -0.2), v.mats.lamp_glass)
	lamp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var ll := OmniLight3D.new()
	ll.light_color = Color(1.0, 0.64, 0.32)
	ll.light_energy = 2.6
	ll.omni_range = 7.5
	ll.shadow_enabled = true
	ll.position = t + Vector3(0.38, 1.1, -0.2)
	root.add_child(ll)
	v.flicker_lights.append([ll, 2.6])
	var fill := OmniLight3D.new()
	fill.light_color = Color(0.9, 0.7, 0.55)
	fill.light_energy = 0.8
	fill.omni_range = 10.0
	fill.position = Vector3(-1.5, 2.6, 1.5)
	root.add_child(fill)
	var card := blank_card(v)
	card.position = t + Vector3(-0.15, 0.816, 0.1)
	card.rotation = Vector3(-PI * 0.5, 0.3, 0)
	root.add_child(card)
	_motes(v, root, Vector3(0, 1.6, 1.0), Vector3(3.5, 1.2, 2.0))
	var out := {"root": root, "table": root.to_global(t), "card": card,
		"bram": root.to_global(t + Vector3(0.0, 0.0, -1.05)), "player": root.to_global(t + Vector3(0.0, 0.0, 1.05)),
		"bar": root.to_global(Vector3(-1.6, 0.0, -1.6))}
	v.set_meta("taproom", out)
	return out


## The cellar: stone and barrels, stairs up to a door with smoke curling under
## it, the iron-bound chest with Bram's four decks, and the rug over the
## smugglers' trapdoor.
static func cellar(v: AshfordVillage) -> Dictionary:
	if v.has_meta("cellar"):
		return v.get_meta("cellar")
	var o := CELLAR_AT
	var root := Node3D.new()
	root.name = "Cellar"
	root.position = o
	v.add_child(root)
	var W := 6.5
	var D := 5.5
	var H := 2.5
	v.box(root, Vector3(W, 0.2, D), Vector3(0, -0.1, 0), v.mats.rock)
	v.box(root, Vector3(W, 0.2, D), Vector3(0, H + 0.1, 0), v.mats.beam)
	for side in [[Vector3(W, H, 0.4), Vector3(0, H * 0.5, -D * 0.5 - 0.2)], [Vector3(W, H, 0.4), Vector3(0, H * 0.5, D * 0.5 + 0.2)],
			[Vector3(0.4, H, D), Vector3(-W * 0.5 - 0.2, H * 0.5, 0)], [Vector3(0.4, H, D), Vector3(W * 0.5 + 0.2, H * 0.5, 0)]]:
		v.box(root, side[0], side[1], v.mats.stone)
	for z in [-1.8, -0.6, 0.6, 1.8]:
		v.box(root, Vector3(W, 0.22, 0.22), Vector3(0, H - 0.11, z), v.mats.beam)
	# barrels on their sides along the west wall, more stood in the corner
	for k in 4:
		var b := v.make_barrel()
		b.position = Vector3(-W * 0.5 + 0.45, 0.32, -1.8 + k * 0.72)
		b.rotation.x = PI * 0.5
		root.add_child(b)
		var b2 := v.make_barrel()
		b2.position = Vector3(-W * 0.5 + 0.45, 0.95, -1.45 + k * 0.72)
		b2.rotation.x = PI * 0.5
		if k < 3:
			root.add_child(b2)
		else:
			b2.free()
	for p in [Vector3(2.4, 0, -2.0), Vector3(2.4, 0, -1.3)]:
		var b3 := v.make_barrel()
		b3.position = p + Vector3(0, AshfordVillage.BARREL_HALF, 0)
		root.add_child(b3)
	# the stairs up the east side to the door, and smoke under it
	for k in 8:
		v.box(root, Vector3(1.1, 0.3, 0.32), Vector3(W * 0.5 - 0.6, 0.15 + k * 0.3, 1.9 - k * 0.32), v.mats.wood_h)
	var door_at := Vector3(W * 0.5 - 0.6, 2.25, -0.75)
	v.box(root, Vector3(1.0, 1.6, 0.1), door_at + Vector3(0, 0.6, -0.3), v.mats.door_natural)
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.42, 0.12)
	glow.light_energy = 2.2
	glow.omni_range = 6.0
	glow.position = door_at + Vector3(0, -0.1, 0.2)
	root.add_child(glow)
	v.flicker_lights.append([glow, 2.2])
	_smoke_seep(v, root, door_at + Vector3(0, -0.2, -0.2))
	# the chest
	var cpos := Vector3(0.4, 0.0, -1.7)
	var chest := Node3D.new()
	chest.position = cpos
	root.add_child(chest)
	v.box(chest, Vector3(1.2, 0.6, 0.66), Vector3(0, 0.3, 0), v.mats.wood)
	for x in [-0.45, 0.45]:
		v.box(chest, Vector3(0.07, 0.62, 0.68), Vector3(x, 0.3, 0), v.mats.metal)
	var hinge := Node3D.new()
	hinge.position = Vector3(0, 0.6, -0.33)
	chest.add_child(hinge)
	v.box(hinge, Vector3(1.22, 0.16, 0.68), Vector3(0, 0.08, 0.34), v.mats.wood)
	for x in [-0.45, 0.45]:
		v.box(hinge, Vector3(0.07, 0.18, 0.7), Vector3(x, 0.08, 0.34), v.mats.metal)
	v.box(hinge, Vector3(0.12, 0.14, 0.05), Vector3(0, 0.02, 0.7), v.mats.metal)
	# four card boxes inside, worn soft at the corners, one per deck
	var boxes: Array = []
	var cols := {"emberstorm": Color(0.55, 0.16, 0.08), "tidegrove": Color(0.1, 0.25, 0.45), "ironstone": Color(0.35, 0.33, 0.3), "veilwild": Color(0.32, 0.16, 0.42)}
	var ids: Array = DuelCards.DECKS.keys()
	for i in ids.size():
		var bm := StandardMaterial3D.new()
		bm.albedo_color = cols.get(ids[i], Color(0.4, 0.3, 0.2))
		bm.roughness = 0.85
		var cb := v.box(chest, Vector3(0.2, 0.09, 0.28), Vector3(-0.36 + i * 0.24, 0.62, 0.0), bm)
		cb.rotation.y = v.rng.randf_range(-0.12, 0.12)
		boxes.append(cb)
	var cl := OmniLight3D.new()
	cl.light_color = Color(1.0, 0.86, 0.6)
	cl.light_energy = 0.0
	cl.omni_range = 2.5
	cl.position = Vector3(0, 0.9, 0.1)
	chest.add_child(cl)
	# the rug, and the trapdoor under it
	var rug := Node3D.new()
	rug.position = Vector3(-0.9, 0.0, 0.7)
	root.add_child(rug)
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color(0.42, 0.1, 0.08)
	rm.roughness = 1.0
	v.box(rug, Vector3(1.6, 0.03, 1.1), Vector3(0, 0.015, 0), rm)
	var rb := StandardMaterial3D.new()
	rb.albedo_color = Color(0.75, 0.6, 0.3)
	v.box(rug, Vector3(1.4, 0.035, 0.9), Vector3(0, 0.016, 0), rb).transparency = 0.6
	var trap := Node3D.new()
	trap.position = Vector3(-0.9, 0.0, 0.7) + Vector3(0, 0.0, -0.45)
	root.add_child(trap)
	v.box(trap, Vector3(0.9, 0.06, 0.9), Vector3(0, 0.03, 0.45), v.mats.wood_h)
	v.box(trap, Vector3(0.1, 0.07, 0.1), Vector3(0, 0.06, 0.8), v.mats.metal)
	var hole := v.box(root, Vector3(0.88, 0.02, 0.88), Vector3(-0.9, 0.005, 0.7), v.mats.dark)
	hole.visible = false
	# Bram's lantern hangs from a beam
	var lamp := v.box(root, Vector3(0.18, 0.26, 0.18), Vector3(-0.2, 1.95, -0.4), v.mats.lamp_glass)
	lamp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var ll := OmniLight3D.new()
	ll.light_color = Color(1.0, 0.62, 0.3)
	ll.light_energy = 2.4
	ll.omni_range = 7.0
	ll.shadow_enabled = true
	ll.position = Vector3(-0.2, 1.75, -0.4)
	root.add_child(ll)
	v.flicker_lights.append([ll, 2.4])
	_motes(v, root, Vector3(0, 1.4, 0), Vector3(2.5, 0.9, 2.0))
	var out := {"root": root, "lid": hinge, "boxes": boxes, "box_light": cl, "rug": rug, "trapdoor": trap, "hole": hole,
		"chest": root.to_global(cpos), "bram": root.to_global(cpos + Vector3(0.2, 0, 0.85)),
		"player": root.to_global(cpos + Vector3(-0.9, 0, 1.3)), "stairs": root.to_global(Vector3(W * 0.5 - 0.6, 0, 1.4)),
		"trap": root.to_global(Vector3(-0.9, 0, 0.7))}
	v.set_meta("cellar", out)
	return out


## The inn's attic, where the Prologue opens (P1): low beams under a pitched
## roof, a straw bed against the north wall with a candle by it, a cracked
## mirror on the east gable and a little window in the west one, through
## which the green can be seen filling up with lanterns (the real village,
## seen from the inn's upper floor: view_of). The hatch to the stairs is in
## the floor by the south-east corner.
static func attic(v: AshfordVillage) -> Dictionary:
	if v.has_meta("attic"):
		return v.get_meta("attic")
	var root := Node3D.new()
	root.name = "Attic"
	root.position = ATTIC_AT
	v.add_child(root)
	var W := 6.0       # gable to gable (x)
	var D := 5.0       # eaves to eaves (z)
	var K := 1.2       # the knee walls under the eaves
	var R := 2.95      # the ridge
	var boards: Material = v.mats.door_natural   # rough planks, walls and gables
	v.box(root, Vector3(W + 0.5, 0.2, D + 0.5), Vector3(0, -0.1, 0), v.mats.wood_h)
	for s in [-1.0, 1.0]:
		v.box(root, Vector3(W, K, 0.25), Vector3(0, K * 0.5, s * (D * 0.5 + 0.125)), boards)
	# the roof's boards on their rafters, sloping up to the ridge
	var run := D * 0.5
	var rise := R - K
	var ang := atan2(rise, run)
	var slope := sqrt(run * run + rise * rise) + 0.35
	for s in [-1.0, 1.0]:
		var c := Vector3(0, K + rise * 0.5 + 0.1, s * run * 0.5)
		v.box(root, Vector3(W + 0.6, 0.12, slope), c, v.mats.wood_h, Vector3(s * ang, 0, 0))
		var inward := Vector3(0, -cos(ang), -s * sin(ang))
		for x in [-2.4, -1.2, 0.0, 1.2, 2.4]:
			v.box(root, Vector3(0.13, 0.15, slope - 0.2), c + inward * 0.13 + Vector3(x, 0, 0), v.mats.beam, Vector3(s * ang, 0, 0))
	v.box(root, Vector3(W + 0.3, 0.22, 0.22), Vector3(0, R - 0.08, 0), v.mats.beam)
	# low collar beams across, at head height: mind your head
	var tie_y := 2.02
	var tie_half := run * (R - tie_y) / rise + 0.15
	for x in [-1.9, 0.0, 1.9]:
		v.box(root, Vector3(0.16, 0.18, tie_half * 2.0), Vector3(x, tie_y, 0), v.mats.beam)
	# the east gable, plain, with the mirror on it
	v.box(root, Vector3(0.25, R + 0.1, D + 0.4), Vector3(W * 0.5 + 0.125, (R + 0.1) * 0.5, 0), boards)
	# the west gable, round its little window
	var win_c := Vector3(-W * 0.5 - 0.125, 1.55, 0.0)
	var ww := 0.72
	var wh := 0.62
	var gx := -W * 0.5 - 0.125
	v.box(root, Vector3(0.25, win_c.y - wh * 0.5, D + 0.4), Vector3(gx, (win_c.y - wh * 0.5) * 0.5, 0), boards)
	var top_h := R + 0.1 - (win_c.y + wh * 0.5)
	v.box(root, Vector3(0.25, top_h, D + 0.4), Vector3(gx, win_c.y + wh * 0.5 + top_h * 0.5, 0), boards)
	var side_w := (D + 0.4) * 0.5 - ww * 0.5
	for s in [-1.0, 1.0]:
		v.box(root, Vector3(0.25, wh, side_w), Vector3(gx, win_c.y, s * (ww * 0.5 + side_w * 0.5)), boards)
	for s in [-1.0, 1.0]:
		v.box(root, Vector3(0.3, 0.07, ww + 0.14), Vector3(gx + 0.02, win_c.y + s * (wh * 0.5 + 0.035), 0), v.mats.beam)
		v.box(root, Vector3(0.3, wh, 0.07), Vector3(gx + 0.02, win_c.y, s * (ww * 0.5 + 0.035)), v.mats.beam)
	v.box(root, Vector3(0.06, wh, 0.04), Vector3(gx, win_c.y, 0), v.mats.beam)
	v.box(root, Vector3(0.06, 0.04, ww), Vector3(gx, win_c.y, 0), v.mats.beam)
	# the moon through it, onto the floorboards and the bed
	var moon := SpotLight3D.new()
	moon.light_color = Color(0.62, 0.72, 1.0)
	moon.light_energy = 2.2
	moon.spot_range = 7.0
	moon.spot_angle = 24.0
	moon.shadow_enabled = v.quality > 0
	root.add_child(moon)
	moon.position = Vector3(gx - 0.6, 2.2, 0.1)
	moon.look_at(root.to_global(Vector3(-0.6, 0.0, -0.9)), Vector3.UP)
	# the bed along the north wall: its head to the west
	var bed := Vector3(-0.7, 0.0, -1.9)
	var bed_parts := _bed(v, root, bed)
	# a crate by its head with the candle on it
	v.box(root, Vector3(0.42, 0.42, 0.42), Vector3(-2.1, 0.21, -1.95), v.mats.wood_h, Vector3(0, 0.2, 0))
	v.cyl(root, 0.03, 0.035, 0.12, Vector3(-2.1, 0.48, -1.95), v.mats.stone_ww, 10)
	v.glow_sprite(root, Vector3(-2.1, 0.58, -1.95), Color(1.0, 0.7, 0.35), 0.16, 0.9)
	var cl := OmniLight3D.new()
	cl.light_color = Color(1.0, 0.66, 0.34)
	cl.light_energy = 1.3
	cl.omni_range = 5.5
	cl.shadow_enabled = true
	cl.position = Vector3(-2.1, 0.75, -1.85)
	root.add_child(cl)
	v.flicker_lights.append([cl, 1.3])
	var fill := OmniLight3D.new()
	fill.light_color = Color(0.85, 0.72, 0.6)
	fill.light_energy = 0.5
	fill.omni_range = 7.0
	fill.position = Vector3(1.2, 2.2, 0.8)
	root.add_child(fill)
	# a chest at the bed's foot, a coat on a peg
	v.box(root, Vector3(0.75, 0.46, 0.46), Vector3(0.75, 0.23, -2.05), v.mats.wood)
	v.box(root, Vector3(0.12, 0.05, 0.05), Vector3(-1.4, 0.85, D * 0.5 - 0.03), v.mats.beam)
	v.box(root, Vector3(0.42, 0.62, 0.08), Vector3(-1.4, 0.55, D * 0.5 - 0.08), v.mats.cloth_blue)
	# the cracked mirror on the east gable, in a dark wooden frame
	var mz := 0.55
	var my := 1.48
	var mx := W * 0.5 - 0.02
	v.box(root, Vector3(0.06, 0.98, 0.7), Vector3(mx - 0.03, my, mz), v.mats.beam)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.5, 0.55, 0.6)
	glass.metallic = 0.85
	glass.roughness = 0.12
	glass.emission_enabled = true
	glass.emission = Color(0.12, 0.13, 0.16)
	v.box(root, Vector3(0.02, 0.84, 0.56), Vector3(mx - 0.07, my, mz), glass)
	var crack := StandardMaterial3D.new()
	crack.albedo_color = Color(0.85, 0.9, 1.0)
	crack.emission_enabled = true
	crack.emission = Color(0.5, 0.55, 0.6)
	for c2 in [[Vector3(0, 0.1, 0.05), 0.6, 0.5], [Vector3(0, -0.1, -0.06), 0.45, -0.7], [Vector3(0, 0.22, -0.1), 0.28, 1.4]]:
		v.box(root, Vector3(0.005, 0.008, c2[1]), Vector3(mx - 0.085, my, mz) + c2[0], crack, Vector3(c2[2], 0, 0))
	# the hatch down to the stairs, by the south-east corner
	var hatch := Vector3(2.0, 0.0, 1.35)
	v.box(root, Vector3(0.85, 0.015, 0.85), hatch + Vector3(0, 0.008, 0), v.mats.dark)
	for s in [-1.0, 1.0]:
		v.box(root, Vector3(0.06, 0.95, 0.06), hatch + Vector3(s * 0.32, 0.47, 0.38), v.mats.beam_v)
	_motes(v, root, Vector3(-0.8, 1.3, -0.4), Vector3(2.2, 0.8, 1.6))
	var out := {"root": root, "bed": root.to_global(bed + Vector3(0, BED_TOP, 0)), "bed_head": root.to_global(bed + Vector3(-0.8, BED_TOP, 0)),
		"bed_side": root.to_global(bed + Vector3(0.1, 0, 0.95)), "mirror": root.to_global(Vector3(mx - 0.09, my, mz)),
		# where they lie (hips over it, head to the west), sit on the edge (hips
		# over it, feet down the south side), and the mattress's height
		"lie_at": root.to_global(bed + Vector3(-0.02, 0, 0)), "edge_at": root.to_global(bed + Vector3(0.12, 0, 0.33)),
		"bed_top": BED_TOP, "blanket": bed_parts.blanket, "blanket_off": bed_parts.blanket_off,
		"mirror_stand": root.to_global(Vector3(mx - 0.72, 0, mz)), "window": root.to_global(win_c), "hatch": root.to_global(hatch),
		"floor_y": ATTIC_AT.y, "view_quad": null}
	# the green through the window: the village itself, from the inn's upper floor
	var front := inn_front(v)
	var eye: Vector3 = front.root.to_global(Vector3(2.2, 6.6, front.front_z + 0.4))
	var q := view_of(v, root, eye, Vector3(0.0, 3.6, 0.0), Transform3D(Basis(Vector3.UP, PI * 0.5), win_c + Vector3(-0.85, 0.05, 0)), Vector2(2.2, 1.5))
	out["view_quad"] = q
	v.set_meta("attic", out)
	return out


## The height of the attic bed's mattress (the straw and the sacking over it)
## off the attic floor.
const BED_TOP := 0.52


## The attic bed at `at` (the middle of its base), its head to the west: a
## low oak cot with a slatted headboard and a footboard, a straw mattress in
## a sacking cover, a bolster pillow and a wool blanket. The blanket is
## returned with the transform it's thrown back to when the sleeper gets up
## (`blanket_off`). Gary's own model takes its place the moment it exists
## (assets/models/ashford/attic_bed.glb, 2.05 m long, 1 m wide, its origin
## at the middle of its base, the head at -x).
static func _bed(v: AshfordVillage, root: Node3D, at: Vector3) -> Dictionary:
	var sack := v.shader_mat("cloth", {"col_a": Color(0.56, 0.5, 0.38), "col_b": Color(0.5, 0.45, 0.34), "stripes": 24.0})
	var linen := v.shader_mat("cloth", {"col_a": Color(0.78, 0.74, 0.64), "col_b": Color(0.74, 0.7, 0.6), "stripes": 30.0})
	var wool := v.shader_mat("cloth", {"col_a": Color(0.3, 0.1, 0.07), "col_b": Color(0.16, 0.15, 0.11), "stripes": 3.0})
	var oak: Material = v.mats.wood_h
	var post: Material = v.mats.beam_v
	var L := 2.05
	var W := 1.0
	var rail_y := 0.3      # the side rails' middle
	var model_path := "res://assets/models/ashford/attic_bed.glb"
	if ResourceLoader.exists(model_path):
		var inst: Node3D = load(model_path).instantiate()
		inst.name = "AtticBed"
		root.add_child(inst)
		inst.position = at
		for mi: MeshInstance3D in inst.find_children("*", "MeshInstance3D", true, false):
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	else:
		# four posts, the head pair tall for the headboard
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var h := 0.98 if sx < 0.0 else 0.6
				v.box(root, Vector3(0.09, h, 0.09), at + Vector3(sx * (L * 0.5 - 0.045), h * 0.5, sz * (W * 0.5 - 0.045)), post)
		# side and end rails, and the slats across them
		for sz in [-1.0, 1.0]:
			v.box(root, Vector3(L - 0.18, 0.12, 0.05), at + Vector3(0, rail_y, sz * (W * 0.5 - 0.07)), oak)
		for sx in [-1.0, 1.0]:
			v.box(root, Vector3(0.05, 0.12, W - 0.18), at + Vector3(sx * (L * 0.5 - 0.07), rail_y, 0), v.mats.wood)
		for i in 7:
			v.box(root, Vector3(0.1, 0.03, W - 0.14), at + Vector3(-L * 0.5 + 0.2 + i * (L - 0.4) / 6.0, rail_y + 0.075, 0), oak)
		# the headboard: two rails and five uprights between the tall posts
		for y in [0.58, 0.88]:
			v.box(root, Vector3(0.06, 0.07, W - 0.18), at + Vector3(-L * 0.5 + 0.045, y, 0), v.mats.wood)
		for i in 5:
			v.box(root, Vector3(0.04, 0.26, 0.05), at + Vector3(-L * 0.5 + 0.045, 0.73, -W * 0.5 + 0.17 + i * (W - 0.34) / 4.0), v.mats.wood)
		# the footboard: one rail
		v.box(root, Vector3(0.06, 0.07, W - 0.18), at + Vector3(L * 0.5 - 0.045, 0.52, 0), v.mats.wood)
		# the straw, poking out under the sacking, and the mattress in its cover
		v.box(root, Vector3(L - 0.12, 0.07, W - 0.1), at + Vector3(0, rail_y + 0.12, 0), v.mats.hay)
		v.box(root, Vector3(L - 0.2, 0.12, W - 0.16), at + Vector3(0, BED_TOP - 0.06, 0), sack)
		# the bolster at the head
		var bolster := CapsuleMesh.new()
		bolster.radius = 0.11
		bolster.height = W - 0.3
		v.add_mesh(root, bolster, linen, Transform3D(Basis.from_euler(Vector3(PI * 0.5, 0, 0)), at + Vector3(-L * 0.5 + 0.28, BED_TOP + 0.08, 0)))
	# the blanket: draped over the sleeper from the chest down, high over
	# the chest, lower over the legs, falling to the mattress at the sides
	var blanket := v.add_mesh(root, _blanket_mesh(1.3, W - 0.04), wool, Transform3D(Basis.IDENTITY, at + Vector3(0.3, BED_TOP, 0)))
	blanket.name = "Blanket"
	# thrown back against the wall, in a heap, when they get up
	var off := Transform3D(Basis.from_euler(Vector3(0.0, 0.0, 0.0)) * Basis.from_scale(Vector3(0.85, 1.3, 0.42)), at + Vector3(0.4, BED_TOP, -0.27))
	return {"blanket": blanket, "blanket_off": off}


## A blanket lying over someone on their back: `L` long (x, the head at -x)
## and `W` wide (z), its origin at the mattress under its head end's middle.
## Highest over the chest, lower down the legs, flat over the body's width
## and falling to the mattress either side of it.
static func _blanket_mesh(L: float, W: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nx := 16
	var nz := 12
	var pts: Array = []
	for i in nx + 1:
		var u := float(i) / nx
		# the body under it: chest, hips, knees, feet
		var h := 0.25 - 0.14 * u + 0.03 * sin(u * PI)
		var row: Array = []
		for j in nz + 1:
			var vv := float(j) / nz * 2.0 - 1.0
			var over := smoothstep(1.0, 0.4, absf(vv))
			row.append(Vector3(-L * 0.5 + u * L, h * over + 0.015, vv * W * 0.5))
		pts.append(row)
	for i in nx:
		for j in nz:
			var a: Vector3 = pts[i][j]
			var b: Vector3 = pts[i + 1][j]
			var c: Vector3 = pts[i + 1][j + 1]
			var d: Vector3 = pts[i][j + 1]
			var ua := Vector2(float(i) / nx, float(j) / nz)
			var uc := Vector2(float(i + 1) / nx, float(j + 1) / nz)
			for tri in [[a, ua, c, uc, b, Vector2(uc.x, ua.y)], [a, ua, d, Vector2(ua.x, uc.y), c, uc]]:
				st.set_uv(tri[1]); st.add_vertex(tri[0])
				st.set_uv(tri[3]); st.add_vertex(tri[2])
				st.set_uv(tri[5]); st.add_vertex(tri[4])
	st.generate_normals()
	return st.commit()


## The taproom on the evening of the festival (P1), not the film's shuttered
## afternoon after it: the good tankards already out on the green and the
## shelves behind the bar bare, the hearth in, a lamp over the table where
## Bram is packing paper lanterns into a crate, the stairs down from the
## attic along the south wall, and the front door in the north wall, shut
## until the player gets to it (`door` swings it open), the street beyond.
## (The crate and the lanterns are the scene's own: AshfordP1.)
static func eve(v: AshfordVillage) -> Dictionary:
	if v.has_meta("eve"):
		return v.get_meta("eve")
	var root := Node3D.new()
	root.name = "TaproomEve"
	root.position = EVE_AT
	v.add_child(root)
	var W := 9.0
	var D := 7.0
	var H := 3.1
	var dx := 2.2       # the front door's middle, along the north wall
	var dw := 1.15
	var dh := 2.15
	var wall := plaster()
	v.box(root, Vector3(W, 0.2, D), Vector3(0, -0.1, 0), v.mats.wood_h)
	v.box(root, Vector3(W, 0.2, D), Vector3(0, H + 0.1, 0), v.mats.beam)
	v.box(root, Vector3(W, H, 0.3), Vector3(0, H * 0.5, D * 0.5 + 0.15), wall)
	for s in [-1.0, 1.0]:
		v.box(root, Vector3(0.3, H, D), Vector3(s * (W * 0.5 + 0.15), H * 0.5, 0), wall)
	# the north wall, round the doorway
	var left_w := W * 0.5 + dx - dw * 0.5
	v.box(root, Vector3(left_w, H, 0.3), Vector3(-W * 0.5 + left_w * 0.5, H * 0.5, -D * 0.5 - 0.15), wall)
	var right_w := W * 0.5 - dx - dw * 0.5
	v.box(root, Vector3(right_w, H, 0.3), Vector3(W * 0.5 - right_w * 0.5, H * 0.5, -D * 0.5 - 0.15), wall)
	v.box(root, Vector3(dw, H - dh, 0.3), Vector3(dx, dh + (H - dh) * 0.5, -D * 0.5 - 0.15), wall)
	for s in [-1.0, 1.0]:
		v.box(root, Vector3(0.16, dh, 0.36), Vector3(dx + s * (dw * 0.5 + 0.08), dh * 0.5, -D * 0.5 - 0.15), v.mats.beam_v)
	v.box(root, Vector3(dw + 0.32, 0.18, 0.36), Vector3(dx, dh + 0.09, -D * 0.5 - 0.15), v.mats.beam)
	# the door itself, hinged on its east side, opening in
	var hinge := Node3D.new()
	hinge.position = Vector3(dx + dw * 0.5, 0, -D * 0.5 + 0.02)
	root.add_child(hinge)
	v.box(hinge, Vector3(dw, dh - 0.02, 0.07), Vector3(-dw * 0.5, dh * 0.5, 0.0), v.mats.door_natural)
	v.box(hinge, Vector3(0.05, 0.05, 0.08), Vector3(-dw + 0.12, 1.05, 0.06), v.mats.metal)
	# beams round the walls and across
	for x in [-4.3, -2.2, 0.0, 4.3]:
		v.box(root, Vector3(0.22, H, 0.22), Vector3(x, H * 0.5, D * 0.5 - 0.05), v.mats.beam_v)
	for z in [-2.6, -1.3, 0.0, 1.3, 2.6]:
		v.box(root, Vector3(W, 0.24, 0.2), Vector3(0, H - 0.12, z), v.mats.beam)
	# the bar along the west wall; the shelves behind it bare, hooks empty
	v.box(root, Vector3(0.7, 1.05, 4.2), Vector3(-3.75, 0.525, -0.3), v.mats.wood)
	v.box(root, Vector3(0.85, 0.08, 4.4), Vector3(-3.75, 1.09, -0.3), v.mats.beam)
	for y in [1.5, 2.1]:
		v.box(root, Vector3(0.3, 0.05, 3.9), Vector3(-W * 0.5 + 0.18, y, -0.3), v.mats.wood_h)
	for k in 8:
		v.box(root, Vector3(0.04, 0.09, 0.03), Vector3(-W * 0.5 + 0.12, 2.0, -2.0 + k * 0.48), v.mats.metal)
	for p in [Vector3(-4.0, 0, -3.0), Vector3(-3.3, 0, -3.05)]:
		var b := v.make_barrel()
		b.position = p + Vector3(0, AshfordVillage.BARREL_HALF, 0)
		root.add_child(b)
	# the hearth in the east wall
	v.box(root, Vector3(0.7, H, 2.2), Vector3(W * 0.5 - 0.35, H * 0.5, 0.9), v.mats.stone)
	v.box(root, Vector3(0.3, 0.9, 1.1), Vector3(W * 0.5 - 0.62, 0.45, 0.9), v.mats.dark)
	_hearth(v, root, Vector3(W * 0.5 - 0.75, 0.12, 0.9))
	# the stairs down from the attic, along the south wall, rising to the west
	for i in 10:
		var top := 0.29 * (i + 1)
		v.box(root, Vector3(0.38, top, 1.0), Vector3(-0.2 - i * 0.38, top * 0.5, D * 0.5 - 0.5), v.mats.wood_h)
	v.box(root, Vector3(0.08, 1.0, 0.08), Vector3(0.05, 0.5, D * 0.5 - 1.02), v.mats.beam_v)
	v.box(root, Vector3(3.9, 0.07, 0.07), Vector3(-1.85, 2.05, D * 0.5 - 1.02), v.mats.beam_v, Vector3(0, 0, 0.65))
	# the table, two stools, and the lamp hung over it
	var t := Vector3(0.6, 0.0, 0.3)
	v.cyl(root, 0.8, 0.8, 0.07, t + Vector3(0, 0.78, 0), v.mats.wood_h, 24)
	v.cyl(root, 0.1, 0.16, 0.76, t + Vector3(0, 0.38, 0), v.mats.beam_v, 10)
	v.cyl(root, 0.32, 0.32, 0.05, t + Vector3(0, 0.02, 0), v.mats.beam_v, 16)
	for p in [Vector3(-1.2, 0, 0.2), Vector3(1.15, 0, 0.55)]:
		v.cyl(root, 0.22, 0.2, 0.46, t + p + Vector3(0, 0.23, 0), v.mats.wood, 14)
	var lamp := v.box(root, Vector3(0.18, 0.26, 0.18), t + Vector3(0.1, 2.2, -0.1), v.mats.lamp_glass)
	lamp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	v.box(root, Vector3(0.02, 0.6, 0.02), t + Vector3(0.1, 2.62, -0.1), v.mats.metal)
	var ll := OmniLight3D.new()
	ll.light_color = Color(1.0, 0.64, 0.32)
	ll.light_energy = 1.9
	ll.omni_range = 8.0
	ll.shadow_enabled = true
	ll.position = t + Vector3(0.1, 2.0, -0.1)
	root.add_child(ll)
	v.flicker_lights.append([ll, 1.9])
	var fill := OmniLight3D.new()
	fill.light_color = Color(0.9, 0.72, 0.56)
	fill.light_energy = 0.7
	fill.omni_range = 10.0
	fill.position = Vector3(-1.5, 2.6, -1.0)
	root.add_child(fill)
	_motes(v, root, Vector3(0, 1.6, 0.0), Vector3(3.5, 1.2, 2.5))
	var out := {"root": root, "door": hinge, "table": root.to_global(t), "table_top": root.to_global(t + Vector3(0, 0.815, 0)),
		"bram": root.to_global(t + Vector3(0.0, 0, -1.05)), "player": root.to_global(t + Vector3(-0.15, 0, 1.15)),
		"stairs_foot": root.to_global(Vector3(0.35, 0, D * 0.5 - 0.6)), "stairs_top": root.to_global(Vector3(-3.4, 2.9, D * 0.5 - 0.5)),
		"door_in": root.to_global(Vector3(dx, 0, -D * 0.5 + 0.75)), "door_out": root.to_global(Vector3(dx, 0, -D * 0.5 - 0.7)),
		"bar": root.to_global(Vector3(-3.1, 0, -0.3)), "hearth": root.to_global(Vector3(W * 0.5 - 0.8, 0, 0.9)),
		# where the player may walk (in the room's own x/z), and what's in the way:
		# round things (the table and the stools) and square ones (the stairs,
		# their rail included), and the foot of the stairs, where Bram stops
		# anyone heading back up them
		"walk": Rect2(-3.15, -D * 0.5 + 0.35, 6.75, D - 1.35), "blocks": [[Vector2(t.x, t.z), 1.05], [Vector2(t.x - 1.2, t.z + 0.2), 0.42],
			[Vector2(t.x + 1.15, t.z + 0.55), 0.42]],
		"keep_out": [Rect2(-3.95, D * 0.5 - 1.38, 4.3, 1.6)],
		"stairs_zone": Rect2(-1.3, D * 0.5 - 1.95, 2.0, 1.2),
		"floor_y": EVE_AT.y}
	# the street through the doorway: the village itself, from the inn's door
	var front := inn_front(v)
	var eye: Vector3 = front.door + front.out * 0.6 + Vector3(0, 1.6, 0)
	view_of(v, root, eye, eye + front.out * 10.0 + Vector3(0, -0.4, 0), Transform3D(Basis(), Vector3(dx, 1.25, -D * 0.5 - 1.6)), Vector2(3.4, 2.6))
	v.set_meta("eve", out)
	return out


## Lime plaster for the inside walls: warm off-white, faintly mottled.
static func plaster() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.7, 0.64, 0.54)
	m.roughness = 0.95
	var nt := NoiseTexture2D.new()
	var n := FastNoiseLite.new()
	n.frequency = 0.03
	nt.noise = n
	nt.width = 256
	nt.height = 256
	nt.seamless = true
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.84, 0.82, 0.8))
	ramp.set_color(1, Color(1.0, 1.0, 1.0))
	nt.color_ramp = ramp
	m.albedo_texture = nt
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(0.6, 0.6, 0.6)
	m.albedo_texture_force_srgb = true
	return m


## The front of the Crooked Lantern as it stands on its plot: its root node,
## how far out its front face is (the model's +z), the middle of its door on
## the ground, and the way out of the door. (Measured from Gary's model:
## the door is half a metre left of the middle of the front.)
static func inn_front(v: AshfordVillage) -> Dictionary:
	for h in v.houses:
		if not h.get("inn", false):
			continue
		var r: Node3D = h.root
		var box := AABB()
		var first := true
		for mi: MeshInstance3D in r.find_children("*", "MeshInstance3D", true, false):
			var b := (r.global_transform.affine_inverse() * mi.global_transform) * mi.get_aabb()
			box = b if first else box.merge(b)
			first = false
		var out := r.global_transform.basis.z
		out.y = 0.0
		var door := r.to_global(Vector3(-0.53, 0.0, box.end.z))
		door.y = v.height(door.x, door.z)
		return {"root": r, "front_z": box.end.z, "door": door, "out": out.normalized()}
	# the drawn stand-in: its door faces the green
	var pos := Vector3(-24.0, 0.0, 6.0)
	var o := -Vector3(pos.x, 0, pos.z).normalized()
	return {"root": v, "front_z": 3.4, "door": pos + o * 3.4, "out": o}


## A window onto the village from inside a room built below it: a camera at
## `eye` looking at `look` renders the village once into a picture, shown on
## a quad (`xf` in `root`'s space, facing +z) behind the window or doorway.
## It's taken as the room is built, before the room's own lighting goes in.
static func view_of(v: AshfordVillage, root: Node3D, eye: Vector3, look: Vector3, xf: Transform3D, size_m: Vector2) -> MeshInstance3D:
	var vp := SubViewport.new()
	vp.size = Vector2i(640, int(640.0 * size_m.y / size_m.x))
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	vp.msaa_3d = Viewport.MSAA_DISABLED
	root.add_child(vp)
	var cam := Camera3D.new()
	cam.fov = 48.0
	cam.near = 0.3
	cam.far = 200.0
	vp.add_child(cam)
	cam.global_position = eye
	cam.look_at(look, Vector3.UP)
	cam.current = true
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = size_m
	q.mesh = qm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_texture = vp.get_texture()
	q.material_override = m
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	q.transform = xf
	root.add_child(q)
	return q


## The blank card: plain white, faintly glowing, nothing on it.
static func blank_card(_v: AshfordVillage) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.063, 0.088, 0.003)
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.96, 0.94, 0.88)
	m.emission_enabled = true
	m.emission = Color(0.85, 0.9, 1.0)
	m.emission_energy_multiplier = 0.6
	m.roughness = 0.6
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## A low fire in a hearth: flames and sparks and a red light, no smoke.
static func _hearth(v: AshfordVillage, root: Node3D, at: Vector3) -> void:
	var f := GPUParticles3D.new()
	f.amount = 14
	f.lifetime = 0.9
	f.preprocess = 1.0
	f.position = at
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(0.12, 0.05, 0.35)
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 8.0
	pm.initial_velocity_min = 0.4
	pm.initial_velocity_max = 0.8
	pm.gravity = Vector3(0, 0.6, 0)
	pm.scale_min = 0.25
	pm.scale_max = 0.45
	f.process_material = pm
	var q := QuadMesh.new(); q.size = Vector2(0.9, 1.4)
	f.draw_pass_1 = q
	f.material_override = v.mats.flame
	f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(f)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.45, 0.15)
	l.light_energy = 2.0
	l.omni_range = 6.0
	l.position = at + Vector3(-0.4, 0.5, 0)
	root.add_child(l)
	v.flicker_lights.append([l, 2.0])


## Dust hanging in the air, catching the light.
static func _motes(v: AshfordVillage, root: Node3D, at: Vector3, ext: Vector3) -> void:
	var p := GPUParticles3D.new()
	p.amount = [40, 70, 110][v.quality]
	p.lifetime = 8.0
	p.preprocess = 8.0
	p.position = at
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = ext
	pm.direction = Vector3(0.2, 1, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = 0.01
	pm.initial_velocity_max = 0.05
	pm.gravity = Vector3(0, -0.005, 0)
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.2
	pm.scale_min = 0.5
	pm.scale_max = 1.0
	p.process_material = pm
	var q := QuadMesh.new(); q.size = Vector2(0.012, 0.012)
	p.draw_pass_1 = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_color = Color(1.0, 0.85, 0.6, 0.6)
	p.material_override = m
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(-ext - Vector3.ONE, ext * 2.0 + Vector3.ONE * 2.0)
	root.add_child(p)


## Smoke curling in under a door.
static func _smoke_seep(v: AshfordVillage, root: Node3D, at: Vector3) -> void:
	var s := GPUParticles3D.new()
	s.amount = 18
	s.lifetime = 4.0
	s.preprocess = 4.0
	s.position = at
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(0.45, 0.02, 0.05)
	pm.direction = Vector3(0, -0.2, 1)
	pm.spread = 25.0
	pm.initial_velocity_min = 0.15
	pm.initial_velocity_max = 0.35
	pm.gravity = Vector3(0, 0.12, 0.05)
	pm.scale_min = 0.5
	pm.scale_max = 0.9
	var sc := Curve.new(); sc.add_point(Vector2(0, 0.4)); sc.add_point(Vector2(1, 1.8))
	var sct := CurveTexture.new(); sct.curve = sc
	pm.scale_curve = sct
	s.process_material = pm
	var q := QuadMesh.new(); q.size = Vector2(1, 1)
	s.draw_pass_1 = q
	s.material_override = v.mats.chimney_smoke
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	s.visibility_aabb = AABB(Vector3(-3, -2, -3), Vector3(6, 5, 6))
	root.add_child(s)


## Inside: the moon and the sky's light are shut out, so only the lamps light
## the room. Call outside() to put them back.
static func inside(v: AshfordVillage) -> void:
	v.set_meta("outside_env", [v.moon_light.visible, v.tear_light.visible, v.env.ambient_light_source,
		v.env.ambient_light_color, v.env.ambient_light_energy, v.env.fog_density, v.env.fog_enabled,
		v.env.volumetric_fog_enabled])
	v.moon_light.visible = false
	v.tear_light.visible = false
	v.env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	v.env.ambient_light_color = Color(0.45, 0.36, 0.3)
	v.env.ambient_light_energy = 0.35
	v.env.fog_density = 0.0
	# the rooms sit below the village, where its height fog is thickest
	v.env.fog_enabled = false
	v.env.volumetric_fog_enabled = false


static func outside(v: AshfordVillage) -> void:
	if not v.has_meta("outside_env"):
		return
	var s: Array = v.get_meta("outside_env")
	v.moon_light.visible = s[0]
	v.tear_light.visible = s[1]
	v.env.ambient_light_source = s[2]
	v.env.ambient_light_color = s[3]
	v.env.ambient_light_energy = s[4]
	v.env.fog_density = s[5]
	if s.size() > 7:
		v.env.fog_enabled = s[6]
		v.env.volumetric_fog_enabled = s[7]
	v.remove_meta("outside_env")
