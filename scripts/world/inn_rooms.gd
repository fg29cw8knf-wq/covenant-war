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
## The P1 taproom's bar (in the room's own x/z): its middle line, stood
## forward of the west wall (at -4.5) so a man stands behind it clear of the
## counter and the shelves; where it runs from and to (north to south);
## where the counter stops for the lift-up flap at its south end; and where
## Bram stands behind it.
const BAR_X := -3.25
const BAR_Z0 := -2.4
const BAR_Z1 := 1.8
const BAR_FLAP_Z := 1.05
## (29 October: a step nearer the counter than it was, -3.92, so he can
## reach well onto it with the rag without his arm stretched straight)
const BAR_BEHIND := Vector3(-3.84, 0.0, -0.1)


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
	# the shutter, swung half to on the inside, with the frost on the glass
	# beside it (v7: "a frost-cracked shutter")
	v.box(root, Vector3(0.05, wh + 0.04, ww * 0.52), Vector3(gx + 0.16, win_c.y, -ww * 0.27), v.mats.door_natural, Vector3(0, 0.35, 0))
	var rime := StandardMaterial3D.new()
	rime.albedo_color = Color(0.9, 0.95, 1.0, 0.32)
	rime.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rime.roughness = 0.9
	rime.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	v.box(root, Vector3(0.005, wh - 0.06, ww * 0.46), Vector3(gx + 0.05, win_c.y, ww * 0.24), rime)
	# pale morning light through the frost-cracked shutter (Master Script v7:
	# the Prologue opens on a frosty morning), onto the floorboards and the bed
	var moon := SpotLight3D.new()
	moon.light_color = Color(0.86, 0.9, 1.0)
	moon.light_energy = 3.2
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
	cl.light_energy = 0.55   # (a guttered stub: it's morning)
	cl.omni_range = 5.5
	cl.shadow_enabled = true
	cl.position = Vector3(-2.1, 0.75, -1.85)
	root.add_child(cl)
	v.flicker_lights.append([cl, 0.55])
	# the morning's cold light off the floorboards and the bed linen, up
	# into the room (1 November: the attic read nearly black)
	var bounce := OmniLight3D.new()
	bounce.light_color = Color(0.82, 0.84, 0.9)
	bounce.light_energy = 0.7
	bounce.omni_range = 4.5
	bounce.position = Vector3(-0.6, 0.9, -0.6)
	root.add_child(bounce)
	var fill := OmniLight3D.new()
	fill.light_color = Color(0.8, 0.84, 0.92)
	fill.light_energy = 1.9    # (the web's renderer draws it darker than a desktop does; 1 November: lifted so the room's things read)
	fill.omni_range = 7.0
	fill.position = Vector3(1.2, 2.2, 0.8)
	root.add_child(fill)
	# a chest at the bed's foot, a coat on a peg
	v.box(root, Vector3(0.75, 0.46, 0.46), Vector3(0.75, 0.23, -2.05), v.mats.wood)
	v.box(root, Vector3(0.12, 0.05, 0.05), Vector3(-1.4, 0.85, D * 0.5 - 0.03), v.mats.beam)
	v.box(root, Vector3(0.42, 0.62, 0.08), Vector3(-1.4, 0.55, D * 0.5 - 0.08), v.mats.cloth_blue)
	# the washbasin on its stand against the east gable, an oval mirror over
	# it veiled in cold grey condensation that clears where a palm wipes it
	# (Master Script v7: the mirror he writes his name in)
	var mz := 0.55
	var my := 1.42
	var mx := W * 0.5 - 0.02
	var stand_x := mx - 0.26
	for lx in [-0.18, 0.18]:
		for lz in [-0.22, 0.22]:
			v.box(root, Vector3(0.05, 0.78, 0.05), Vector3(stand_x + lx, 0.39, mz + lz), v.mats.beam_v)
	v.box(root, Vector3(0.46, 0.05, 0.56), Vector3(stand_x, 0.8, mz), v.mats.wood_h)
	var china := StandardMaterial3D.new()
	china.albedo_color = Color(0.86, 0.84, 0.78)
	china.roughness = 0.35
	v.cyl(root, 0.19, 0.12, 0.1, Vector3(stand_x, 0.875, mz), china, 18)
	var water := StandardMaterial3D.new()
	water.albedo_color = Color(0.32, 0.38, 0.42, 0.85)
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.roughness = 0.05
	water.metallic = 0.3
	v.cyl(root, 0.165, 0.165, 0.004, Vector3(stand_x, 0.9, mz), water, 18)
	v.cyl(root, 0.05, 0.075, 0.22, Vector3(stand_x + 0.06, 0.94, mz + 0.2), china, 12)
	# the oval: a dark wooden ring, the glass, and the fog in front of it
	var oval := Node3D.new()
	oval.name = "Mirror"
	root.add_child(oval)
	oval.position = Vector3(mx - 0.05, my, mz)
	oval.scale = Vector3(1.0, 1.32, 1.0)
	v.cyl(oval, 0.31, 0.31, 0.05, Vector3.ZERO, v.mats.beam, 28, Vector3(0, 0, PI * 0.5))
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.5, 0.55, 0.6)
	glass.metallic = 0.85
	glass.roughness = 0.12
	glass.emission_enabled = true
	glass.emission = Color(0.12, 0.13, 0.16)
	v.cyl(oval, 0.27, 0.27, 0.01, Vector3(-0.03, 0, 0), glass, 28, Vector3(0, 0, PI * 0.5))
	var fog_mat := StandardMaterial3D.new()
	fog_mat.albedo_color = Color(0.78, 0.8, 0.84, 0.78)
	fog_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fog_mat.roughness = 1.0
	fog_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var fog := v.cyl(oval, 0.265, 0.265, 0.004, Vector3(-0.042, 0, 0), fog_mat, 28, Vector3(0, 0, PI * 0.5))
	fog.name = "Fog"
	# the name written in the frost (filled in at the glass: AshfordP1)
	var writing := Label3D.new()
	writing.name = "Writing"
	writing.text = ""
	writing.font_size = 64
	writing.pixel_size = 0.0016
	writing.modulate = Color(0.95, 0.97, 1.0, 0.0)
	writing.outline_size = 0
	writing.double_sided = false
	writing.shaded = false
	oval.add_child(writing)
	writing.position = Vector3(-0.05, 0.02, 0)
	writing.rotation = Vector3(0, -PI * 0.5, 0)
	writing.scale = Vector3(1.0, 1.0 / 1.32, 1.0)
	# (1 November, Gary: "decorate the player's room so it actually looks like
	# he lives there")
	_attic_dressing(v, root, W, D, K)
	# the hatch down to the stairs, by the south-east corner
	var hatch := Vector3(2.0, 0.0, 1.35)
	v.box(root, Vector3(0.85, 0.015, 0.85), hatch + Vector3(0, 0.008, 0), v.mats.dark)
	for s in [-1.0, 1.0]:
		v.box(root, Vector3(0.06, 0.95, 0.06), hatch + Vector3(s * 0.32, 0.47, 0.38), v.mats.beam_v)
	var out := {"root": root, "bed": root.to_global(bed + Vector3(0, BED_TOP, 0)), "bed_head": root.to_global(bed + Vector3(-0.8, BED_TOP, 0)),
		"bed_side": root.to_global(bed + Vector3(0.1, 0, 0.95)), "mirror": root.to_global(Vector3(mx - 0.09, my, mz)),
		# where they lie (hips over it, head to the west), sit on the edge (hips
		# over it, feet down the south side), and the mattress's height
		"lie_at": root.to_global(bed + Vector3(-0.16, 0, 0)), "edge_at": root.to_global(bed + Vector3(0.12, 0, 0.36)),
		# (the mattress's edge; the dip a body lies in; the edge under someone sat on it)
		"bed_top": BED_TOP, "lie_top": BED_TOP - BED_SAG, "edge_top": BED_TOP - EDGE_SINK,
		"blanket": bed_parts.blanket, "blanket_off": bed_parts.blanket_off,
		"mirror_stand": root.to_global(Vector3(mx - 0.82, 0, mz)), "window": root.to_global(win_c), "hatch": root.to_global(hatch),
		"floor_y": ATTIC_AT.y, "view_quad": null,
		"mirror_node": oval, "fog": fog, "fog_mat": fog_mat, "writing": writing,
		# for walking it (AshfordP1.walk_room): the floor clear of the eaves,
		# round the bed, the candle crate, the chest, the washstand and the hatch
		"walk": Rect2(-2.55, -1.3, 5.05, 2.95),
		"blocks": [[Vector2(-1.25, -1.9), 0.62], [Vector2(-0.25, -1.9), 0.62], [Vector2(-2.1, -1.95), 0.4],
			[Vector2(0.75, -2.05), 0.5], [Vector2(stand_x, mz), 0.34], [Vector2(hatch.x, hatch.z), 0.62],
			# (1 November) his desk under the window and its stool, his boots
			[Vector2(-2.78, 0.95), 0.5], [Vector2(-2.3, 1.05), 0.26], [Vector2(2.3, -2.15), 0.3]]}
	# the green through the window: the village itself, from the inn's upper floor
	var front := inn_front(v)
	var eye: Vector3 = front.root.to_global(Vector3(2.2, 6.6, front.front_z + 0.4))
	var q := view_of(v, root, eye, Vector3(0.0, 3.6, 0.0), Transform3D(Basis(Vector3.UP, PI * 0.5), win_c + Vector3(-0.85, 0.05, 0)), Vector2(2.2, 1.5))
	out["view_quad"] = q
	# the morning's light, the candle and the fill (the awakening, before
	# sunrise, turns them down: AshfordWake)
	out["lights"] = {"window": moon, "candle": cl, "fill": fill, "bounce": bounce}
	v.set_meta("attic", out)
	return out


## The attic as a room someone has lived in for twenty years (1 November,
## Gary: "decorate the player's room so it actually looks like he lives
## there"): a braided rag rug by the bed; on the north knee wall a shelf of
## his things (books, a carved horse Bram whittled him, a jar of feathers, a
## tin box, river stones, a candle stub), his wooden practice sword leant
## beside it and his boots under it; his writing desk under the west window
## with a stool, an open book, an inkpot and quill, papers and a mug; drawings
## and a hand-drawn map of the valley pinned to the east gable by the mirror,
## a towel over the washstand's rail; a half-made paper lantern of his own for
## tonight hanging from a collar beam, a bunch of lavender drying on another;
## a shirt and a pair of breeches over the chest at the bed's foot, a scarf on
## the peg by the coat, and a satchel hung on the hatch rail.
static func _attic_dressing(v: AshfordVillage, root: Node3D, W: float, D: float, _K: float) -> void:
	var mk := func(col: Color, rough := 0.85, metal := 0.0) -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_color = col
		m.roughness = rough
		m.metallic = metal
		return m
	var oak: Material = v.mats.wood_h
	var dark_oak: Material = v.mats.wood
	var beam: Material = v.mats.beam_v
	var paper: StandardMaterial3D = mk.call(Color(0.86, 0.8, 0.66), 0.95)
	var ink: StandardMaterial3D = mk.call(Color(0.08, 0.07, 0.06), 0.4)
	var leather: StandardMaterial3D = mk.call(Color(0.36, 0.22, 0.12), 0.7)
	var leather_dk: StandardMaterial3D = mk.call(Color(0.2, 0.12, 0.07), 0.75)
	var linen: StandardMaterial3D = mk.call(Color(0.82, 0.78, 0.68), 0.95)
	var wool_g: StandardMaterial3D = mk.call(Color(0.28, 0.36, 0.22), 1.0)
	var wool_r: StandardMaterial3D = mk.call(Color(0.5, 0.16, 0.1), 1.0)
	var brown_cloth: StandardMaterial3D = mk.call(Color(0.33, 0.25, 0.17), 1.0)
	var clay: StandardMaterial3D = mk.call(Color(0.62, 0.38, 0.24), 0.7)
	var tin: StandardMaterial3D = mk.call(Color(0.55, 0.55, 0.52), 0.4, 0.8)
	var wax: StandardMaterial3D = mk.call(Color(0.93, 0.88, 0.74), 0.7)
	var nk := -D * 0.5 + 0.06    # the north knee wall's inner face (z)
	# --- the rag rug by the bed: braided rings of old cloth, an oval
	var rug := Node3D.new()
	rug.name = "RagRug"
	root.add_child(rug)
	rug.position = Vector3(-0.55, 0.0, -0.95)
	rug.scale = Vector3(1.0, 1.0, 0.55)
	# (old cloth, faded: muted browns and a dull green, close in tone, so it
	# reads as a rug, not a target)
	var ring_cols := [Color(0.3, 0.2, 0.15), Color(0.38, 0.31, 0.23), Color(0.27, 0.27, 0.23), Color(0.36, 0.25, 0.18), Color(0.3, 0.3, 0.24), Color(0.4, 0.33, 0.25)]
	for i in ring_cols.size():
		var r := 0.68 - i * 0.11
		v.cyl(rug, r, r, 0.012, Vector3(0, 0.006 + i * 0.0012, 0), mk.call(ring_cols[i], 1.0), 28)
	# --- the shelf on the north knee wall, east of the bed's foot
	var sx0 := 1.25
	var sx1 := 2.75
	var sy := 0.78
	v.box(root, Vector3(sx1 - sx0, 0.035, 0.24), Vector3((sx0 + sx1) * 0.5, sy, nk + 0.12), oak)
	for bx in [sx0 + 0.12, sx1 - 0.12]:
		v.box(root, Vector3(0.04, 0.12, 0.2), Vector3(bx, sy - 0.07, nk + 0.1), beam)
	var top := sy + 0.0175
	# books: four stood up, the last leaning, and three lying in a stack
	var spine_cols := [Color(0.42, 0.14, 0.1), Color(0.18, 0.26, 0.2), Color(0.5, 0.36, 0.18), Color(0.2, 0.2, 0.32)]
	for i in 4:
		var bh := 0.2 - 0.02 * (i % 2)
		v.box(root, Vector3(0.04, bh, 0.15), Vector3(sx0 + 0.2 + i * 0.045, top + bh * 0.5, nk + 0.11), mk.call(spine_cols[i], 0.8), Vector3(0, 0, -0.08 if i == 3 else 0.0))
	for i in 3:
		v.box(root, Vector3(0.17 - i * 0.01, 0.035, 0.13 - i * 0.01), Vector3(sx0 + 0.52, top + 0.0175 + i * 0.035, nk + 0.11), mk.call(spine_cols[(i + 2) % 4], 0.8), Vector3(0, 0.15 * i, 0))
	# the carved horse Bram whittled him: body, neck, head and four legs
	var horse := Node3D.new()
	root.add_child(horse)
	horse.position = Vector3(sx0 + 0.82, top, nk + 0.11)
	horse.rotation.y = -0.5
	v.box(horse, Vector3(0.11, 0.045, 0.04), Vector3(0, 0.07, 0), oak)
	v.box(horse, Vector3(0.03, 0.06, 0.03), Vector3(0.055, 0.105, 0), oak, Vector3(0, 0, -0.5))
	v.box(horse, Vector3(0.05, 0.025, 0.028), Vector3(0.08, 0.13, 0), oak, Vector3(0, 0, 0.3))
	for lx in [-0.04, 0.04]:
		for lz in [-0.012, 0.012]:
			v.box(horse, Vector3(0.012, 0.05, 0.012), Vector3(lx, 0.025, lz), oak)
	# a clay jar of feathers
	v.cyl(root, 0.035, 0.045, 0.11, Vector3(sx0 + 1.02, top + 0.055, nk + 0.12), clay, 12)
	var feather_cols := [Color(0.9, 0.88, 0.82), Color(0.45, 0.32, 0.22), Color(0.2, 0.3, 0.42)]
	for k in 3:
		v.box(root, Vector3(0.008, 0.2, 0.025), Vector3(sx0 + 1.02 + (k - 1) * 0.015, top + 0.19, nk + 0.12), mk.call(feather_cols[k], 0.9), Vector3(0, k * 0.6, (k - 1) * 0.25))
	# a tin box, river stones, a candle stub
	v.box(root, Vector3(0.12, 0.05, 0.08), Vector3(sx0 + 1.2, top + 0.025, nk + 0.11), tin, Vector3(0, 0.3, 0))
	for k in 4:
		var st := SphereMesh.new()
		st.radius = 0.02 + 0.005 * (k % 2)
		st.height = st.radius * 1.2
		v.add_mesh(root, st, mk.call(Color(0.5 + 0.08 * k, 0.5 + 0.05 * k, 0.48), 0.6), Transform3D(Basis.IDENTITY, Vector3(sx0 + 1.32 + k * 0.035, top + 0.012, nk + 0.1 + 0.02 * (k % 2))))
	v.cyl(root, 0.035, 0.04, 0.012, Vector3(sx1 - 0.1, top + 0.006, nk + 0.12), tin, 10)
	v.cyl(root, 0.014, 0.014, 0.06, Vector3(sx1 - 0.1, top + 0.04, nk + 0.12), wax, 8)
	# his wooden practice sword leant against the wall past the shelf's end
	var sword := Node3D.new()
	root.add_child(sword)
	sword.position = Vector3(2.85, 0.0, nk + 0.12)
	sword.rotation = Vector3(-0.12, 0.0, 0.2)
	v.box(sword, Vector3(0.045, 0.62, 0.016), Vector3(0, 0.46, 0), oak)
	v.box(sword, Vector3(0.16, 0.025, 0.03), Vector3(0, 0.14, 0), dark_oak)
	v.box(sword, Vector3(0.03, 0.13, 0.03), Vector3(0, 0.065, 0), leather_dk)
	# his boots under the shelf, one stood, one fallen over
	for b in [[Vector3(2.15, 0, -2.2), 0.1, false], [Vector3(2.36, 0, -2.12), -0.6, true]]:
		var boot := Node3D.new()
		root.add_child(boot)
		boot.position = b[0]
		boot.rotation = Vector3(0, b[1], PI * 0.5 if b[2] else 0.0)
		if b[2]:
			boot.position.y = 0.05
		v.box(boot, Vector3(0.1, 0.24, 0.09), Vector3(0, 0.12, 0), leather)
		v.box(boot, Vector3(0.24, 0.06, 0.09), Vector3(0.06, 0.03, 0), leather)
		v.box(boot, Vector3(0.11, 0.03, 0.1), Vector3(0, 0.23, 0), leather_dk)
	# --- his desk under the west window, and its stool
	var desk := Vector3(-2.78, 0.0, 0.95)
	var dh := 0.74
	v.box(root, Vector3(0.44, 0.04, 0.82), desk + Vector3(0, dh, 0), oak)
	for lx in [-0.18, 0.18]:
		for lz in [-0.37, 0.37]:
			v.box(root, Vector3(0.045, dh, 0.045), desk + Vector3(lx, dh * 0.5, lz), beam)
	v.box(root, Vector3(0.36, 0.1, 0.74), desk + Vector3(0, dh - 0.06, 0), dark_oak)
	var dt := dh + 0.02
	# an open book, a sheet half written, the inkpot and quill, a mug, a candle
	v.box(root, Vector3(0.21, 0.02, 0.29), desk + Vector3(0.02, dt + 0.002, -0.12), mk.call(Color(0.35, 0.16, 0.1), 0.8), Vector3(0, 0.1, 0))
	for sd in [-1.0, 1.0]:
		v.box(root, Vector3(0.19, 0.012, 0.135), desk + Vector3(0.02, dt + 0.016, -0.12 + sd * 0.07), paper, Vector3(sd * 0.05, 0.1, 0))
	v.box(root, Vector3(0.18, 0.004, 0.24), desk + Vector3(0.05, dt + 0.002, 0.2), paper, Vector3(0, -0.25, 0))
	for k in 5:
		v.box(root, Vector3(0.004, 0.002, 0.1 - 0.012 * (k % 3)), desk + Vector3(0.01 + k * 0.018, dt + 0.005, 0.18 + 0.01 * k), ink, Vector3(0, -0.25, 0))
	v.cyl(root, 0.025, 0.03, 0.045, desk + Vector3(-0.1, dt + 0.022, 0.33), ink, 10)
	v.box(root, Vector3(0.006, 0.006, 0.24), desk + Vector3(-0.1, dt + 0.1, 0.3), linen, Vector3(0.9, 0, 0.2))
	v.cyl(root, 0.04, 0.036, 0.09, desk + Vector3(0.1, dt + 0.045, 0.34), clay, 12)
	v.cyl(root, 0.03, 0.035, 0.015, desk + Vector3(-0.12, dt + 0.008, -0.33), tin, 10)
	v.cyl(root, 0.015, 0.015, 0.09, desk + Vector3(-0.12, dt + 0.06, -0.33), wax, 8)
	var stool := Vector3(-2.3, 0.0, 1.05)
	v.cyl(root, 0.17, 0.17, 0.04, stool + Vector3(0, 0.46, 0), oak, 14)
	for k in 3:
		var a := TAU * k / 3.0
		v.box(root, Vector3(0.04, 0.46, 0.04), stool + Vector3(cos(a) * 0.11, 0.23, sin(a) * 0.11), beam, Vector3(sin(a) * 0.12, 0, -cos(a) * 0.12))
	# --- drawings and a map pinned to the east gable, north of the mirror
	var ex := W * 0.5 - 0.01
	var pins: StandardMaterial3D = mk.call(Color(0.7, 0.5, 0.2), 0.4, 0.7)
	var sheets := [[Vector3(ex, 1.55, -0.55), Vector2(0.42, 0.32), 0.04, "map"], [Vector3(ex, 1.08, -0.42), Vector2(0.22, 0.28), -0.08, "moth"],
		[Vector3(ex, 1.2, -0.95), Vector2(0.24, 0.2), 0.1, "hound"], [Vector3(ex, 1.72, -1.15), Vector2(0.26, 0.34), -0.05, "notice"]]
	for i in sheets.size():
		var sh: Array = sheets[i]
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = sh[1]
		q.mesh = qm
		var pm := StandardMaterial3D.new()
		pm.albedo_texture = _sketch(String(sh[3]), i)
		pm.roughness = 0.95
		pm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		q.material_override = pm
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# facing west, into the room, off the east gable
		q.transform = Transform3D(Basis(Vector3.UP, -PI * 0.5) * Basis(Vector3.BACK, float(sh[2])), sh[0])
		root.add_child(q)
		var pin_at: Vector3 = sh[0] + Vector3(-0.004, (sh[1] as Vector2).y * 0.5 - 0.025, 0)
		v.cyl(root, 0.008, 0.008, 0.01, pin_at, pins, 6, Vector3(0, 0, PI * 0.5))
	# --- a towel over the washstand's rail (the stand is at z 0.55, x W/2 - 0.28)
	v.box(root, Vector3(0.012, 0.28, 0.2), Vector3(W * 0.5 - 0.56, 0.66, 0.72), linen)
	v.box(root, Vector3(0.05, 0.012, 0.2), Vector3(W * 0.5 - 0.535, 0.8, 0.72), linen)
	# --- his own paper lantern for tonight, half made, hung from a collar beam,
	# and a bunch of lavender drying upside down on the next
	var lan := Node3D.new()
	root.add_child(lan)
	# (on his desk, half made: hung from a beam it filled a corner of every
	# shot of the room)
	lan.position = desk + Vector3(0.0, dt + 0.12, 0.18)
	var ball := SphereMesh.new()
	ball.radius = 0.13
	ball.height = 0.24
	ball.radial_segments = 12
	ball.rings = 6
	var lp := StandardMaterial3D.new()
	lp.albedo_color = Color(0.95, 0.66, 0.3)
	lp.roughness = 0.9
	lp.emission_enabled = true
	lp.emission = Color(0.4, 0.18, 0.05)
	lp.emission_energy_multiplier = 0.25
	v.add_mesh(lan, ball, lp, Transform3D.IDENTITY)
	for k in 3:
		var rr := 0.132 - 0.02 * absf(k - 1)
		v.cyl(lan, rr, rr, 0.006, Vector3(0, -0.06 + k * 0.06, 0), leather_dk, 14)
	var lav := Node3D.new()
	root.add_child(lav)
	lav.position = Vector3(0.0, 1.86, -0.85)
	v.box(lav, Vector3(0.01, 0.12, 0.01), Vector3(0, 0.08, 0), wool_g)
	# (a loose, uneven bunch of thin stems fanning out from a twine tie, the
	# flower spikes greyed with drying: nine stiff spokes and fat purple blocks
	# read as a potted plant hanging in the air)
	var stem: StandardMaterial3D = mk.call(Color(0.36, 0.42, 0.3), 1.0)
	var bloom: StandardMaterial3D = mk.call(Color(0.44, 0.4, 0.54), 1.0)
	var twine: StandardMaterial3D = mk.call(Color(0.62, 0.52, 0.36), 1.0)
	v.cyl(lav, 0.016, 0.018, 0.035, Vector3(0, 0.0, 0), twine, 10)
	for k in 15:
		var a := TAU * k / 15.0 + 0.37 * sin(k * 2.3)
		var tilt := 0.1 + 0.16 * absf(sin(k * 1.7))
		var ln := 0.2 + 0.07 * absf(cos(k * 2.9))
		var out := Vector3(cos(a), 0, sin(a)) * sin(tilt)
		var down := Vector3(0, -cos(tilt), 0)
		var dir := (out + down).normalized()
		var axis := Vector3.UP.cross(-dir).normalized()
		var bas := Basis(axis, Vector3.UP.angle_to(-dir)) if axis.length() > 0.01 else Basis()
		var mid := dir * ln * 0.5
		v.add_mesh(lav, _thin_box(0.005, ln, 0.005), stem, Transform3D(bas, mid))
		v.add_mesh(lav, _thin_box(0.011, 0.075, 0.011), bloom, Transform3D(bas, dir * (ln + 0.03)))
	# --- a shirt and breeches over the chest at the bed's foot (the chest's
	# top at 0.46, at x 0.75, z -2.05), a sleeve and a leg hanging down
	v.box(root, Vector3(0.5, 0.025, 0.36), Vector3(0.72, 0.475, -2.05), linen, Vector3(0, 0.18, 0.04))
	v.box(root, Vector3(0.1, 0.24, 0.025), Vector3(0.42, 0.36, -1.84), linen, Vector3(0.1, 0, 0.25))
	v.box(root, Vector3(0.38, 0.03, 0.3), Vector3(0.82, 0.5, -2.08), brown_cloth, Vector3(0, -0.3, 0))
	v.box(root, Vector3(0.14, 0.3, 0.03), Vector3(1.0, 0.34, -1.83), brown_cloth, Vector3(-0.05, 0, -0.12))
	# --- a scarf on a second peg by the coat on the south knee wall
	v.box(root, Vector3(0.1, 0.04, 0.04), Vector3(-0.85, 0.88, D * 0.5 - 0.03), beam)
	v.box(root, Vector3(0.12, 0.55, 0.03), Vector3(-0.85, 0.6, D * 0.5 - 0.07), wool_r)
	v.box(root, Vector3(0.12, 0.42, 0.03), Vector3(-0.78, 0.66, D * 0.5 - 0.09), wool_r, Vector3(0, 0, 0.08))
	# --- his satchel hung on the hatch rail's east post
	var sat := Node3D.new()
	root.add_child(sat)
	sat.position = Vector3(2.0 + 0.32, 0.0, 1.35 + 0.38)
	v.box(sat, Vector3(0.3, 0.24, 0.09), Vector3(0.0, 0.55, 0.06), leather)
	v.box(sat, Vector3(0.3, 0.12, 0.095), Vector3(0.0, 0.62, 0.065), leather_dk)
	v.box(sat, Vector3(0.025, 0.36, 0.01), Vector3(-0.12, 0.8, 0.02), leather_dk, Vector3(0, 0, -0.35))
	v.box(sat, Vector3(0.025, 0.36, 0.01), Vector3(0.12, 0.8, 0.02), leather_dk, Vector3(0, 0, 0.35))


## A pinned sheet's picture, drawn in ink on old paper: the valley's map (the
## river, the road, the green's ring of houses), a Lantern Moth and a river
## hound as a boy draws them, or the festival's notice.
static func _sketch(kind: String, seed: int) -> ImageTexture:
	var n := 96
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7000 + seed
	for y in n:
		for x in n:
			var g := 0.02 * sin(x * 0.7 + y * 0.3) + rng.randf_range(-0.02, 0.02)
			var edge := minf(minf(x, n - 1 - x), minf(y, n - 1 - y)) / 6.0
			var age := 0.08 * (1.0 - clampf(edge, 0.0, 1.0))
			img.set_pixel(x, y, Color(0.88 + g - age, 0.82 + g - age * 1.2, 0.68 + g - age * 1.5))
	var dot := func(x: float, y: float, r: float, c: Color) -> void:
		for yy in range(int(y - r), int(y + r) + 1):
			for xx in range(int(x - r), int(x + r) + 1):
				if xx >= 0 and yy >= 0 and xx < n and yy < n and Vector2(xx - x, yy - y).length() <= r:
					img.set_pixel(xx, yy, c)
	var line := func(a: Vector2, b: Vector2, c: Color, r := 0.8) -> void:
		var steps := int(a.distance_to(b) * 1.5) + 1
		for i in steps + 1:
			var p := a.lerp(b, float(i) / steps)
			dot.call(p.x, p.y, r, c)
	var ink := Color(0.16, 0.12, 0.1)
	var blue := Color(0.22, 0.32, 0.5)
	var red := Color(0.55, 0.2, 0.14)
	match kind:
		"map":
			var prev := Vector2(4, 30)
			for i in 12:
				var nx := Vector2(4 + (i + 1) * 7.6, 30 + 14 * sin((i + 1) * 0.6))
				line.call(prev, nx, blue, 1.2)
				prev = nx
			line.call(Vector2(10, 88), Vector2(88, 60), ink, 0.7)
			for k in 8:
				var a := TAU * k / 8.0
				dot.call(52 + cos(a) * 13, 64 + sin(a) * 9, 1.6, ink)
			dot.call(52, 64, 2.5, red)
			line.call(Vector2(64, 50), Vector2(80, 32), ink, 0.6)
			dot.call(82, 30, 3.0, ink)
		"moth":
			dot.call(48, 54, 7, Color(0.85, 0.55, 0.2))
			for s in [-1.0, 1.0]:
				for k in 14:
					var a := k / 14.0 * PI
					line.call(Vector2(48, 50), Vector2(48 + s * (10 + 22 * sin(a)), 50 - 26 * cos(a) * 0.9), ink, 0.6)
			line.call(Vector2(46, 46), Vector2(40, 30), ink, 0.6)
			line.call(Vector2(50, 46), Vector2(56, 30), ink, 0.6)
		"hound":
			line.call(Vector2(20, 60), Vector2(70, 58), blue, 2.0)
			line.call(Vector2(70, 58), Vector2(82, 40), blue, 1.8)
			dot.call(84, 38, 5, blue)
			for lx in [26, 36, 58, 66]:
				line.call(Vector2(lx, 60), Vector2(lx + rng.randf_range(-3, 3), 80), blue, 1.2)
			line.call(Vector2(20, 60), Vector2(10, 50), blue, 1.0)
		"notice":
			for k in 8:
				var wl := 70 - (k % 3) * 12
				line.call(Vector2(13, 18 + k * 9), Vector2(13 + wl, 18 + k * 9), ink, 0.6 if k > 0 else 1.4)
			dot.call(48, 86, 4, red)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## The height of the attic bed's mattress (the straw and the sacking over it)
## off the attic floor, at its edges.
const BED_TOP := 0.52
## How far the middle of the mattress sags: a body lies that much lower than
## the edges, in the dip (`lie_top`), and sits on the edge a touch lower than
## the edge itself (`edge_top`).
const BED_SAG := 0.06
const EDGE_SINK := 0.02
## Gary's own bed model takes the built one's place the moment it exists, by
## either name (2.05 m long, 1 m wide, its origin at the middle of its base,
## the head at -x), as the crate and the Great Lantern are picked up.
const BED_MODELS := ["res://assets/models/ashford/bed.glb", "res://assets/models/ashford/attic_bed.glb"]


## The attic bed at `at` (the middle of its base), its head to the west: an
## oak frame with turned posts, a slatted headboard and a footboard, a straw
## mattress in a striped ticking cover that sags in the middle, a plump
## linen pillow with the dent of a head in it, and a rumpled wool blanket.
## The blanket is returned with the transform it's thrown back to when the
## sleeper gets up (`blanket_off`). Gary's own model takes its place the
## moment it exists (BED_MODELS). (In-engine since 22 October, until his
## model comes.)
static func _bed(v: AshfordVillage, root: Node3D, at: Vector3) -> Dictionary:
	var ticking := v.shader_mat("cloth", {"col_a": Color(0.8, 0.76, 0.66), "col_b": Color(0.42, 0.46, 0.56), "stripes": 44.0})
	var linen := v.shader_mat("cloth", {"col_a": Color(0.8, 0.77, 0.68), "col_b": Color(0.76, 0.73, 0.64), "stripes": 30.0})
	var wool := v.shader_mat("cloth", {"col_a": Color(0.3, 0.1, 0.07), "col_b": Color(0.16, 0.15, 0.11), "stripes": 3.0})
	var oak: Material = v.mats.wood_h
	var post: Material = v.mats.beam_v
	var L := 2.05
	var W := 1.0
	var rail_y := 0.3      # the side rails' middle
	var model_path := ""
	for p in BED_MODELS:
		if ResourceLoader.exists(p):
			model_path = p
			break
	if model_path != "":
		var inst: Node3D = load(model_path).instantiate()
		inst.name = "AtticBed"
		root.add_child(inst)
		inst.position = at
		for mi: MeshInstance3D in inst.find_children("*", "MeshInstance3D", true, false):
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	else:
		# four posts, the head pair tall for the headboard, each with a
		# turned knob on top
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var h := 1.0 if sx < 0.0 else 0.66
				var px := at + Vector3(sx * (L * 0.5 - 0.045), 0, sz * (W * 0.5 - 0.045))
				v.box(root, Vector3(0.09, h, 0.09), px + Vector3(0, h * 0.5, 0), post)
				v.cyl(root, 0.03, 0.055, 0.05, px + Vector3(0, h + 0.025, 0), oak, 12)
				var knob := SphereMesh.new()
				knob.radius = 0.055
				knob.height = 0.11
				v.add_mesh(root, knob, oak, Transform3D(Basis.IDENTITY, px + Vector3(0, h + 0.09, 0)))
		# side and end rails, and the slats across them
		for sz in [-1.0, 1.0]:
			v.box(root, Vector3(L - 0.18, 0.12, 0.05), at + Vector3(0, rail_y, sz * (W * 0.5 - 0.07)), oak)
		for sx in [-1.0, 1.0]:
			v.box(root, Vector3(0.05, 0.12, W - 0.18), at + Vector3(sx * (L * 0.5 - 0.07), rail_y, 0), v.mats.wood)
		for i in 7:
			v.box(root, Vector3(0.1, 0.03, W - 0.14), at + Vector3(-L * 0.5 + 0.2 + i * (L - 0.4) / 6.0, rail_y + 0.075, 0), oak)
		# the headboard: a top rail with a rounded cap, a lower rail, and
		# five uprights between the tall posts
		v.box(root, Vector3(0.06, 0.07, W - 0.18), at + Vector3(-L * 0.5 + 0.045, 0.58, 0), v.mats.wood)
		v.box(root, Vector3(0.07, 0.09, W - 0.18), at + Vector3(-L * 0.5 + 0.045, 0.9, 0), v.mats.wood)
		v.cyl(root, 0.045, 0.045, W - 0.18, at + Vector3(-L * 0.5 + 0.045, 0.945, 0), oak, 12, Vector3(PI * 0.5, 0, 0))
		for i in 5:
			v.box(root, Vector3(0.04, 0.26, 0.05), at + Vector3(-L * 0.5 + 0.045, 0.73, -W * 0.5 + 0.17 + i * (W - 0.34) / 4.0), v.mats.wood)
		# the footboard: a top rail and three uprights down to the end rail
		v.box(root, Vector3(0.06, 0.08, W - 0.18), at + Vector3(L * 0.5 - 0.045, 0.58, 0), v.mats.wood)
		for i in 3:
			v.box(root, Vector3(0.04, 0.2, 0.05), at + Vector3(L * 0.5 - 0.045, 0.46, -W * 0.5 + 0.25 + i * (W - 0.5) / 2.0), v.mats.wood)
		# the straw, poking out under the ticking, and the mattress: a
		# stuffed slab, rolled at the edges, that sags where a body lies
		v.box(root, Vector3(L - 0.12, 0.07, W - 0.1), at + Vector3(0, rail_y + 0.12, 0), v.mats.hay)
		var mat_h := BED_TOP - 0.4
		v.add_mesh(root, _mattress_mesh(L - 0.2, W - 0.16, mat_h), ticking, Transform3D(Basis.IDENTITY, at + Vector3(0, 0.4, 0)))
		# the pillow at the head: plump linen with the dent of a head in it,
		# sat on the mattress where it stands at the head end
		var px := -L * 0.5 + 0.34
		var py := BED_TOP - _sag(px, 0.0, L - 0.2, W - 0.16) - 0.015
		v.add_mesh(root, _pillow_mesh(0.46, 0.64, 0.15), linen, Transform3D(Basis.IDENTITY, at + Vector3(px, py, 0)))
	# the blanket: draped over the sleeper from the chest down, high over
	# the chest, lower over the legs, falling to the mattress at the sides,
	# rumpled, and the hem turned back over the chest
	var rows := _blanket_points(1.3, W - 0.04)
	var blanket := v.add_mesh(root, _blanket_mesh_of(rows), wool, Transform3D(Basis.IDENTITY, at + Vector3(0.3, BED_TOP, 0)))
	blanket.name = "Blanket"
	# (its points and its mesh as laid, for BlanketThrow and for putting it
	# back over the sleeper)
	blanket.set_meta("rows", rows)
	blanket.set_meta("mesh_on", blanket.mesh)
	# thrown back against the wall, in a heap, when they get up
	var off := Transform3D(Basis.from_euler(Vector3(0.0, 0.0, 0.0)) * Basis.from_scale(Vector3(0.85, 1.3, 0.42)), at + Vector3(0.4, BED_TOP, -0.27))
	return {"blanket": blanket, "blanket_off": off}


## How far the mattress's top dips at (x, z) from its middle (metres), on a
## mattress `L` by `W`: a long bowl, deepest a little towards the head,
## where the hips and back lie, nothing at the rolled edges.
static func _sag(x: float, z: float, L: float, W: float) -> float:
	var u := absf(x + 0.25) / (L * 0.5)
	var w := absf(z) / (W * 0.5)
	return BED_SAG * smoothstep(1.0, 0.3, u) * smoothstep(1.0, 0.25, w)


## A stuffed mattress `L` long (x) by `W` wide (z) by `T` thick, its origin at
## the middle of its base: the top rolled over at the edges (a piped seam's
## roundness) and sagging in the middle (_sag), straight sides, a flat base.
static func _mattress_mesh(L: float, W: float, T: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var R := 0.045        # the roll at the edge
	var nx := 28
	var nz := 14
	var top := func(u: float, w: float) -> Vector3:
		# u, w in -1..1 across the top; the roll takes the outer R metres
		var x := u * L * 0.5
		var z := w * W * 0.5
		var e := minf(L * 0.5 - absf(x), W * 0.5 - absf(z))
		var y := T - _sag(x, z, L, W)
		if e < R:
			var d := R - e
			y = T - R + sqrt(maxf(R * R - d * d, 0.0)) - _sag(x, z, L, W) * (e / R)
		return Vector3(x, y, z)
	_grid(st, nx, nz, top, false)
	# the sides, from under the roll down to the base, and the base
	var rim := T - R
	var corners := [Vector3(-L * 0.5, 0, -W * 0.5), Vector3(L * 0.5, 0, -W * 0.5), Vector3(L * 0.5, 0, W * 0.5), Vector3(-L * 0.5, 0, W * 0.5)]
	for i in 4:
		var a: Vector3 = corners[i]
		var b: Vector3 = corners[(i + 1) % 4]
		_quad(st, a + Vector3(0, rim, 0), b + Vector3(0, rim, 0), b, a)
	_quad(st, corners[0], corners[1], corners[2], corners[3])
	st.generate_normals()
	return st.commit()


## A plump pillow `X` along the bed (x) by `Z` across it (z), `T` thick at its
## fullest, its origin at the middle of its base: rounded all over, flat
## underneath, with the dent of a head pressed into its middle.
static func _pillow_mesh(X: float, Z: float, T: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top := func(u: float, w: float) -> Vector3:
		var pu := sqrt(maxf(1.0 - pow(absf(u), 3.2), 0.0))
		var pw := sqrt(maxf(1.0 - pow(absf(w), 3.2), 0.0))
		var r := sqrt(u * u * 1.6 + w * w)
		var dent := 0.035 * smoothstep(0.75, 0.1, r)
		var y := T * pu * pw - dent + 0.03 * (1.0 - absf(u)) * (1.0 - absf(w)) * 0.0
		return Vector3(u * X * 0.5, maxf(y, 0.0), w * Z * 0.5)
	_grid(st, 18, 22, top, false)
	_quad(st, Vector3(-X * 0.5, 0, -Z * 0.5), Vector3(X * 0.5, 0, -Z * 0.5), Vector3(X * 0.5, 0, Z * 0.5), Vector3(-X * 0.5, 0, Z * 0.5))
	st.generate_normals()
	return st.commit()


## A grid of nx by nz quads over u, w in -1..1, each corner at `at(u, w)`,
## wound to face up (y+); `flip` winds it the other way.
static func _grid(st: SurfaceTool, nx: int, nz: int, at: Callable, flip: bool) -> void:
	for i in nx:
		for j in nz:
			var u0 := float(i) / nx * 2.0 - 1.0
			var u1 := float(i + 1) / nx * 2.0 - 1.0
			var w0 := float(j) / nz * 2.0 - 1.0
			var w1 := float(j + 1) / nz * 2.0 - 1.0
			var a: Vector3 = at.call(u0, w0)
			var b: Vector3 = at.call(u1, w0)
			var c: Vector3 = at.call(u1, w1)
			var d: Vector3 = at.call(u0, w1)
			var ua := Vector2(float(i) / nx, float(j) / nz)
			var uc := Vector2(float(i + 1) / nx, float(j + 1) / nz)
			if flip:
				_tri(st, a, ua, b, Vector2(uc.x, ua.y), c, uc)
				_tri(st, a, ua, c, uc, d, Vector2(ua.x, uc.y))
			else:
				_tri(st, a, ua, c, uc, b, Vector2(uc.x, ua.y))
				_tri(st, a, ua, d, Vector2(ua.x, uc.y), c, uc)


static func _tri(st: SurfaceTool, a: Vector3, ua: Vector2, b: Vector3, ub: Vector2, c: Vector3, uc: Vector2) -> void:
	st.set_uv(ua); st.add_vertex(a)
	st.set_uv(ub); st.add_vertex(b)
	st.set_uv(uc); st.add_vertex(c)


## A quad a-b-c-d (wound so a-b-c faces the way a, b, c turn).
static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_tri(st, a, Vector2(0, 0), b, Vector2(1, 0), c, Vector2(1, 1))
	_tri(st, a, Vector2(0, 0), c, Vector2(1, 1), d, Vector2(0, 1))


## A blanket lying over someone on their back: `L` long (x, the head at -x)
## and `W` wide (z), its origin at the mattress's edge height under its head
## end's middle. Highest over the chest, lower down the legs, flat over the
## body's width and falling to the mattress either side of it (into the
## mattress's dip where the body lies), rumpled in loose folds, its hem
## turned back in a roll over the chest.
static func _blanket_points(L: float, W: float) -> Array:
	var nx := 26
	var nz := 16
	var pts: Array = []
	for i in nx + 1:
		var u := float(i) / nx
		# the body under it: chest, hips, knees, feet (the boots lift it a
		# little again at the end)
		var h := 0.25 - 0.14 * u + 0.03 * sin(u * PI) + 0.09 * smoothstep(0.65, 1.0, u)
		var row: Array = []
		for j in nz + 1:
			var vv := float(j) / nz * 2.0 - 1.0
			var over := smoothstep(1.0, 0.4, absf(vv))
			# the body lies in the mattress's dip, so the blanket does too
			var dip := BED_SAG * smoothstep(1.0, 0.25, absf(vv)) * smoothstep(1.0, 0.3, absf(u * L - 0.4) / 0.95)
			# loose folds across and along it, and the roll of the turned hem
			var fold := 0.012 * sin(u * 19.0 + vv * 2.5) * cos(vv * 7.0 + u * 3.0) + 0.008 * sin(vv * 11.0 + u * 5.0)
			var hem := 0.035 * smoothstep(0.1, 0.0, u) * smoothstep(1.0, 0.7, absf(vv))
			row.append(Vector3(-L * 0.5 + u * L, h * over + 0.015 - dip + fold * (0.4 + 0.6 * over) + hem, vv * W * 0.5))
		pts.append(row)
	return pts


## The blanket's mesh from its grid of points (as laid, or wherever
## BlanketThrow has them this frame).
static func _blanket_mesh_of(pts: Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nx := pts.size() - 1
	var nz := (pts[0] as Array).size() - 1
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
	# the east wall, with the doorways to the kitchen and the back passage
	# (1 November, _eve_tavern)
	_eve_east_wall(v, root, wall, W, D, H)
	# the west wall behind the bar, round its window, and the north wall
	# west of the door round its two (29 October, Gary: "need some windows
	# on the room as you say about the shutters but there are no windows":
	# Bram's first line is "Left the shutter unlatched again"); the west
	# window's frame and shutters, and the rest, are _eve_windows
	_wall_with_holes(v, root, wall, Vector3(-W * 0.5 - 0.15, 0, 0), Vector3(0, 0, 1), D, H, [[EVE_WEST_WINDOW.x, EVE_WEST_WINDOW.y, EVE_WEST_WINDOW.z]])
	var left_w := W * 0.5 + dx - dw * 0.5
	var holes := []
	for c in EVE_NORTH_WINDOWS:
		holes.append([(c as Vector3).x - (-W * 0.5 + left_w * 0.5), (c as Vector3).y, (c as Vector3).z])
	_wall_with_holes(v, root, wall, Vector3(-W * 0.5 + left_w * 0.5, 0, -D * 0.5 - 0.15), Vector3(1, 0, 0), left_w, H, holes)
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
	# the bar along the west wall, stood forward of it so there's a walkway
	# behind (BAR_X; 25 October, Gary: Bram stood half inside the counter
	# with his back in the shelves); the shelves behind it bare, hooks
	# empty; at its south end the counter stops short and its lift-up flap
	# stands raised on its hinge, so there's plainly a way in and out
	var bar_len := BAR_FLAP_Z - BAR_Z0
	var bar_mid := (BAR_Z0 + BAR_FLAP_Z) * 0.5
	v.box(root, Vector3(0.7, 1.05, bar_len), Vector3(BAR_X, 0.525, bar_mid), v.mats.wood)
	# its top in oak polished by forty years of elbows (29 October: it was
	# the near-black of the beams, and read as a hole in the picture more
	# than a counter)
	v.box(root, Vector3(0.85, 0.08, bar_len + 0.1), Vector3(BAR_X, 1.09, bar_mid - 0.05), counter_oak(v))
	# the flap: the counter top's last 0.7 m, hinged at the counter's end and
	# raised upright (and a brass hook on the wall post it rests against)
	v.box(root, Vector3(0.85, 0.7, 0.08), Vector3(BAR_X, 1.09 + 0.35, BAR_FLAP_Z + 0.04), counter_oak(v))
	v.box(root, Vector3(0.1, 0.03, 0.03), Vector3(BAR_X, 1.09 + 0.72, BAR_FLAP_Z + 0.08), v.mats.metal)
	# the gap's far post, where the counter would have ended
	v.box(root, Vector3(0.12, 1.05, 0.12), Vector3(BAR_X - 0.29, 0.525, BAR_Z1), v.mats.beam_v)
	_eve_dressing(v, root, W, D, H)
	_eve_windows(v, root, W, D)
	_eve_tavern(v, root, W, D, H, wall)
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
	var out := {"root": root, "door": hinge, "table": root.to_global(t), "table_top": root.to_global(t + Vector3(0, 0.815, 0)),
		"bram": root.to_global(t + Vector3(0.0, 0, -1.05)), "player": root.to_global(t + Vector3(-0.15, 0, 1.15)),
		"stairs_foot": root.to_global(Vector3(0.35, 0, D * 0.5 - 0.6)), "stairs_top": root.to_global(Vector3(-3.4, 2.9, D * 0.5 - 0.5)),
		"door_in": root.to_global(Vector3(dx, 0, -D * 0.5 + 0.75)), "door_out": root.to_global(Vector3(dx, 0, -D * 0.5 - 0.7)),
		"bar": root.to_global(Vector3(BAR_X + 0.75, 0, -0.3)), "bar_behind": root.to_global(BAR_BEHIND),
		"hearth": root.to_global(Vector3(W * 0.5 - 0.8, 0, 0.9)),
		# where the player may walk (in the room's own x/z: east of the bar's
		# front), and what's in the way: round things (the table and the
		# stools) and square ones (the stairs, their rail included), and the
		# foot of the stairs, where Bram stops anyone heading back up them
		"walk": Rect2(BAR_X + 0.75, -D * 0.5 + 0.35, 3.6 - (BAR_X + 0.75), D - 1.35), "blocks": [[Vector2(t.x, t.z), 1.05], [Vector2(t.x - 1.2, t.z + 0.2), 0.42],
			[Vector2(t.x + 1.15, t.z + 0.55), 0.42],
			# (1 November, _eve_tavern) the settle at the fire, the trestle
			# table and its bench, the little table under the north window
			[Vector2(2.85, 0.45), 0.42], [Vector2(2.85, 1.35), 0.42], [Vector2(1.75, 2.6), 0.55], [Vector2(2.95, 2.6), 0.55],
			[Vector2(-0.7, -2.75), 0.5], [Vector2(-1.32, -2.63), 0.24], [Vector2(-0.08, -2.63), 0.24]],
		"keep_out": [Rect2(-3.95, D * 0.5 - 1.38, 4.3, 1.6)],
		# the counter as a solid for hands (Figure3D.hands_off; 29 October,
		# Gary: Bram's hands went "onto the wood of the bar"): its body and
		# top, from the floor to the top's upper face (1.13), the raised flap
		# standing on its end
		"hand_solids": [AABB(root.to_global(Vector3(BAR_X - 0.425, 0.0, BAR_Z0 - 0.1)), Vector3(0.85, 1.13, bar_len + 0.1)),
			AABB(root.to_global(Vector3(BAR_X - 0.425, 1.13, BAR_FLAP_Z)), Vector3(0.85, 0.7, 0.08))],
		"bar_top": root.to_global(Vector3(BAR_X, 1.13, bar_mid)),
		"stairs_zone": Rect2(-1.3, D * 0.5 - 1.95, 2.0, 1.2),
		"floor_y": EVE_AT.y}
	# the street through the doorway: the village itself, from the inn's door
	var front := inn_front(v)
	var eye: Vector3 = front.door + front.out * 0.6 + Vector3(0, 1.6, 0)
	view_of(v, root, eye, eye + front.out * 10.0 + Vector3(0, -0.4, 0), Transform3D(Basis(), Vector3(dx, 1.25, -D * 0.5 - 1.6)), Vector2(3.4, 2.6))
	v.set_meta("eve", out)
	return out


## The Crooked Lantern as a working inn, not a hall with a door and a stair
## (1 November, Gary: "it's meant to be a tavern but there is only the front
## door and stairs going up, no other rooms"). The east wall has two
## doorways: the kitchen's, north of the hearth (EVE_KITCHEN_Z), its own big
## cooking hearth straight ahead through it with the pot on its crane, a
## work table of bread and onions, pans on the beam and crocks on the
## dresser; and the back passage's, south of the hearth (EVE_PASSAGE_Z),
## running east to the yard door with the day round its edges, a lamp and
## a coat on a peg, and the door to the back stairs. Behind the bar the
## cellar's trapdoor with its ring. In the taproom: a high-backed settle at
## the fire, a trestle table with its bench along the south wall under an
## iron candle wheel, a little table and two stools under the north window,
## tankards and candles on the tables, cloaks on the pegs by the door, the
## notice board with Ironvault's red-sealed notice on it, and a slate of
## what's on chalked up by the barrels.
const EVE_KITCHEN_Z := -1.6
const EVE_PASSAGE_Z := 2.75
const EVE_DOOR_W := 1.0
const EVE_DOOR_H := 2.1


## The east wall with its two doorways (W, D, H: the room's size).
static func _eve_east_wall(v: AshfordVillage, root: Node3D, mat: Material, W: float, D: float, H: float) -> void:
	var x := W * 0.5 + 0.15
	var cuts := [[EVE_KITCHEN_Z - EVE_DOOR_W * 0.5, EVE_KITCHEN_Z + EVE_DOOR_W * 0.5], [EVE_PASSAGE_Z - 0.45, EVE_PASSAGE_Z + 0.45]]
	var at := -D * 0.5
	for c in cuts:
		if float(c[0]) > at:
			v.box(root, Vector3(0.3, H, float(c[0]) - at), Vector3(x, H * 0.5, (at + float(c[0])) * 0.5), mat)
		v.box(root, Vector3(0.3, H - EVE_DOOR_H, float(c[1]) - float(c[0])), Vector3(x, EVE_DOOR_H + (H - EVE_DOOR_H) * 0.5, (float(c[0]) + float(c[1])) * 0.5), mat)
		# the doorway's oak frame: posts and a lintel
		for z in [c[0], c[1]]:
			v.box(root, Vector3(0.36, EVE_DOOR_H, 0.12), Vector3(x, EVE_DOOR_H * 0.5, float(z)), v.mats.beam_v)
		v.box(root, Vector3(0.36, 0.16, float(c[1]) - float(c[0]) + 0.24), Vector3(x, EVE_DOOR_H + 0.08, (float(c[0]) + float(c[1])) * 0.5), v.mats.beam)
		at = float(c[1])
	if D * 0.5 > at:
		v.box(root, Vector3(0.3, H, D * 0.5 - at), Vector3(x, H * 0.5, (at + D * 0.5) * 0.5), mat)


static func _eve_tavern(v: AshfordVillage, root: Node3D, W: float, D: float, H: float, wall: Material) -> void:
	var mk := func(col: Color, rough := 0.85, metal := 0.0) -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_color = col
		m.roughness = rough
		m.metallic = metal
		return m
	var oak: Material = v.mats.wood_h
	var dark: Material = v.mats.wood
	var beam: Material = v.mats.beam
	var post: Material = v.mats.beam_v
	var iron: Material = v.mats.metal
	var pewter: StandardMaterial3D = mk.call(Color(0.6, 0.6, 0.58), 0.38, 0.85)
	var stoneware: StandardMaterial3D = mk.call(Color(0.72, 0.64, 0.5), 0.6)
	var stone_dk: StandardMaterial3D = mk.call(Color(0.42, 0.3, 0.2), 0.5)
	var wax: StandardMaterial3D = mk.call(Color(0.93, 0.88, 0.74), 0.7)
	var bread: StandardMaterial3D = mk.call(Color(0.68, 0.44, 0.2), 0.8)
	var onion: StandardMaterial3D = mk.call(Color(0.72, 0.5, 0.3), 0.6)
	var cabbage: StandardMaterial3D = mk.call(Color(0.4, 0.55, 0.3), 0.8)
	var sack: StandardMaterial3D = mk.call(Color(0.62, 0.54, 0.4), 1.0)
	var flag_stone: Material = v.mats.stone_ww
	var copper: StandardMaterial3D = mk.call(Color(0.78, 0.42, 0.24), 0.32, 0.9)
	var ex := W * 0.5 + 0.3   # the far side of the east wall
	# ---------------------------------------------------------- the kitchen
	var kx0 := ex
	var kx1 := ex + 3.9
	var kz0 := -D * 0.5
	var kz1 := 0.5
	var kc := Vector3((kx0 + kx1) * 0.5, 0, (kz0 + kz1) * 0.5)
	v.box(root, Vector3(kx1 - kx0, 0.2, kz1 - kz0), kc + Vector3(0, -0.1, 0), flag_stone)
	v.box(root, Vector3(kx1 - kx0, 0.2, kz1 - kz0), kc + Vector3(0, H + 0.1, 0), beam)
	v.box(root, Vector3(kx1 - kx0, H, 0.3), Vector3(kc.x, H * 0.5, kz0 - 0.15), wall)
	v.box(root, Vector3(kx1 - kx0, H, 0.3), Vector3(kc.x, H * 0.5, kz1 + 0.15), wall)
	for z in [kz0 + 0.8, kc.z, kz1 - 0.8]:
		v.box(root, Vector3(kx1 - kx0, 0.22, 0.2), Vector3(kc.x, H - 0.11, z), beam)
	# its cooking hearth in the far wall, straight ahead through the doorway
	var hz := EVE_KITCHEN_Z
	v.box(root, Vector3(0.6, H, 3.9), Vector3(kx1 + 0.3, H * 0.5, kc.z), v.mats.stone)
	v.box(root, Vector3(0.75, 1.3, 1.8), Vector3(kx1 - 0.1, 0.65, hz), v.mats.stone)
	v.box(root, Vector3(0.5, 1.0, 1.4), Vector3(kx1 - 0.2, 0.5, hz), v.mats.dark)
	v.box(root, Vector3(0.95, 0.22, 2.1), Vector3(kx1 - 0.2, 1.38, hz), v.mats.stone)
	v.box(root, Vector3(0.12, 0.12, 2.0), Vector3(kx1 - 0.55, 1.38, hz), beam)
	_hearth(v, root, Vector3(kx1 - 0.25, 0.1, hz))
	# the pot on its crane over the fire, a kettle on the hob
	v.box(root, Vector3(0.04, 0.9, 0.04), Vector3(kx1 - 0.55, 0.85, hz - 0.62), iron)
	v.box(root, Vector3(0.5, 0.04, 0.04), Vector3(kx1 - 0.35, 1.25, hz - 0.62), iron, Vector3(0, 0.9, 0))
	v.box(root, Vector3(0.012, 0.42, 0.012), Vector3(kx1 - 0.3, 1.02, hz - 0.3), iron)
	var pot := SphereMesh.new()
	pot.radius = 0.2
	pot.height = 0.32
	v.add_mesh(root, pot, mk.call(Color(0.12, 0.11, 0.1), 0.55, 0.6), Transform3D(Basis.IDENTITY, Vector3(kx1 - 0.3, 0.68, hz - 0.3)))
	v.cyl(root, 0.08, 0.11, 0.16, Vector3(kx1 - 0.25, 0.55, hz + 0.45), copper, 12)
	var kl := OmniLight3D.new()
	kl.light_color = Color(1.0, 0.58, 0.26)
	kl.light_energy = 2.4
	kl.omni_range = 6.5
	kl.position = Vector3(kx1 - 0.8, 0.9, hz)
	root.add_child(kl)
	v.flicker_lights.append([kl, 2.4])
	var kf := OmniLight3D.new()
	kf.light_color = Color(0.95, 0.8, 0.62)
	kf.light_energy = 0.7
	kf.omni_range = 5.0
	kf.position = Vector3(kc.x, 2.4, kc.z)
	root.add_child(kf)
	# the work table, scrubbed pale, with the day's bread and the onions
	var wt := Vector3(kc.x - 0.3, 0.0, kc.z + 0.4)
	v.box(root, Vector3(1.6, 0.07, 0.75), wt + Vector3(0, 0.84, 0), mk.call(Color(0.62, 0.5, 0.36), 0.9))
	for lx in [-0.7, 0.7]:
		for lz in [-0.3, 0.3]:
			v.box(root, Vector3(0.08, 0.84, 0.08), wt + Vector3(lx, 0.42, lz), post)
	for k in 3:
		var loaf := SphereMesh.new()
		loaf.radius = 0.11
		loaf.height = 0.12
		v.add_mesh(root, loaf, bread, Transform3D(Basis.from_scale(Vector3(1.3, 1, 1)), wt + Vector3(-0.5 + k * 0.24, 0.92, -0.15)))
	for k in 6:
		var o := SphereMesh.new()
		o.radius = 0.04
		o.height = 0.07
		v.add_mesh(root, o, onion, Transform3D(Basis.IDENTITY, wt + Vector3(0.25 + (k % 3) * 0.08, 0.91, 0.12 + (k / 3) * 0.08)))
	var cb := SphereMesh.new()
	cb.radius = 0.12
	cb.height = 0.22
	v.add_mesh(root, cb, cabbage, Transform3D(Basis.IDENTITY, wt + Vector3(0.6, 0.98, -0.12)))
	v.box(root, Vector3(0.36, 0.03, 0.24), wt + Vector3(-0.1, 0.89, 0.15), oak)
	v.box(root, Vector3(0.16, 0.01, 0.06), wt + Vector3(-0.1, 0.91, 0.15), iron, Vector3(0, 0.4, 0))
	# pans and ladles hung on the beam over it
	for k in 5:
		var px := wt.x - 0.6 + k * 0.3
		v.box(root, Vector3(0.012, 0.3, 0.012), Vector3(px, H - 0.38, kc.z), iron)
		if k % 2 == 0:
			v.cyl(root, 0.13, 0.11, 0.05, Vector3(px, H - 0.62, kc.z), copper, 14, Vector3(PI * 0.5, 0, 0))
		else:
			v.cyl(root, 0.05, 0.05, 0.04, Vector3(px, H - 0.6, kc.z), iron, 10)
	# the dresser on the north wall: crocks, plates and jugs
	var dz := kz0 + 0.25
	v.box(root, Vector3(1.6, 0.9, 0.45), Vector3(kc.x - 0.2, 0.45, dz + 0.02), dark)
	v.box(root, Vector3(1.6, 1.1, 0.05), Vector3(kc.x - 0.2, 1.45, kz0 + 0.03), dark)
	for y in [1.25, 1.65]:
		v.box(root, Vector3(1.55, 0.04, 0.22), Vector3(kc.x - 0.2, y, kz0 + 0.14), oak)
		for k in 6:
			var px := kc.x - 0.85 + k * 0.26
			if (k + int(y * 10)) % 2 == 0:
				v.cyl(root, 0.1, 0.1, 0.012, Vector3(px, y + 0.11, kz0 + 0.1), pewter, 16, Vector3(PI * 0.5 - 0.2, 0, 0))
			else:
				v.cyl(root, 0.045, 0.06, 0.15, Vector3(px, y + 0.095, kz0 + 0.14), stoneware if k % 3 else stone_dk, 12)
	# flour sacks and the water butt in the corner by the door
	for k in 2:
		v.cyl(root, 0.2, 0.24, 0.6, Vector3(kx0 + 0.45 + k * 0.42, 0.3, kz0 + 0.45), sack, 12)
	var butt := v.make_barrel()
	butt.position = Vector3(kx0 + 0.5, AshfordVillage.BARREL_HALF, kz1 - 0.45)
	root.add_child(butt)
	# --------------------------------------------------- the back passage
	var pz0 := EVE_PASSAGE_Z - 0.55
	var pz1 := EVE_PASSAGE_Z + 0.55
	var px1 := ex + 3.6
	var pc := Vector3((ex + px1) * 0.5, 0, (pz0 + pz1) * 0.5)
	v.box(root, Vector3(px1 - ex, 0.2, pz1 - pz0), pc + Vector3(0, -0.1, 0), oak)
	v.box(root, Vector3(px1 - ex, 0.2, pz1 - pz0), pc + Vector3(0, 2.5, 0), beam)
	v.box(root, Vector3(px1 - ex, 2.6, 0.3), Vector3(pc.x, 1.3, pz0 - 0.15), wall)
	v.box(root, Vector3(px1 - ex, 2.6, 0.3), Vector3(pc.x, 1.3, pz1 + 0.15), wall)
	# the yard door at its end, the day round its edges
	v.box(root, Vector3(0.3, 2.6, pz1 - pz0 + 0.6), Vector3(px1 + 0.15, 1.3, pc.z), wall)
	v.box(root, Vector3(0.06, 1.95, 0.9), Vector3(px1 - 0.02, 0.975, pc.z), v.mats.door_natural)
	v.box(root, Vector3(0.05, 0.05, 0.08), Vector3(px1 - 0.06, 1.0, pc.z - 0.32), iron)
	var chink := StandardMaterial3D.new()
	chink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	chink.albedo_color = Color(1.0, 0.95, 0.85) * 2.2
	v.box(root, Vector3(0.02, 0.02, 0.92), Vector3(px1 - 0.05, 1.96, pc.z), chink)
	v.box(root, Vector3(0.02, 1.9, 0.015), Vector3(px1 - 0.05, 0.97, pc.z + 0.46), chink)
	var yard := OmniLight3D.new()
	yard.light_color = Color(0.85, 0.9, 1.0)
	yard.light_energy = 0.8
	yard.omni_range = 3.0
	yard.position = Vector3(px1 - 0.4, 1.2, pc.z)
	root.add_child(yard)
	# the door to the back stairs, a lamp on its hook, a coat on a peg
	v.box(root, Vector3(0.8, 1.95, 0.06), Vector3(ex + 1.6, 0.975, pz1 - 0.02), v.mats.door_natural)
	v.box(root, Vector3(0.05, 0.05, 0.06), Vector3(ex + 1.9, 1.0, pz1 - 0.07), iron)
	v.box(root, Vector3(0.14, 0.2, 0.14), Vector3(ex + 2.6, 1.9, pz0 + 0.12), v.mats.lamp_glass).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pl := OmniLight3D.new()
	pl.light_color = Color(1.0, 0.66, 0.34)
	pl.light_energy = 1.2
	pl.omni_range = 3.5
	pl.position = Vector3(ex + 2.6, 1.8, pz0 + 0.3)
	root.add_child(pl)
	v.flicker_lights.append([pl, 1.2])
	v.box(root, Vector3(0.1, 0.04, 0.04), Vector3(ex + 0.9, 1.65, pz0 + 0.03), post)
	v.box(root, Vector3(0.45, 0.85, 0.08), Vector3(ex + 0.9, 1.2, pz0 + 0.08), mk.call(Color(0.24, 0.27, 0.22), 1.0))
	# ---------------------------------------------- the taproom's furniture
	# a high-backed settle at the fire, facing it
	var st := Vector3(2.85, 0, 0.9)
	v.box(root, Vector3(0.42, 0.06, 1.5), st + Vector3(0, 0.45, 0), oak)
	v.box(root, Vector3(0.06, 1.25, 1.5), st + Vector3(-0.2, 0.62, 0), dark)
	for sz in [-0.72, 0.72]:
		v.box(root, Vector3(0.46, 0.75, 0.05), st + Vector3(0, 0.375, sz), dark)
		v.box(root, Vector3(0.46, 0.05, 0.06), st + Vector3(0.0, 0.72, sz), oak)
	# the trestle table along the south wall, its bench, the candle wheel over it
	var tt := Vector3(2.35, 0, 2.85)
	v.box(root, Vector3(1.9, 0.07, 0.7), tt + Vector3(0, 0.76, 0), oak)
	for sx in [-0.75, 0.75]:
		v.box(root, Vector3(0.08, 0.74, 0.5), tt + Vector3(sx, 0.37, 0), post)
		v.box(root, Vector3(0.08, 0.06, 0.62), tt + Vector3(sx, 0.05, 0), post)
	v.box(root, Vector3(1.4, 0.08, 0.06), tt + Vector3(0, 0.3, 0), post)
	v.box(root, Vector3(1.7, 0.06, 0.3), tt + Vector3(0, 0.45, -0.58), oak)
	for sx in [-0.65, 0.65]:
		v.box(root, Vector3(0.06, 0.44, 0.24), tt + Vector3(sx, 0.22, -0.58), post)
	var wheel := Vector3(tt.x, 2.25, tt.z - 0.1)
	v.cyl(root, 0.4, 0.4, 0.035, wheel, iron, 20)
	v.cyl(root, 0.36, 0.36, 0.04, wheel, v.mats.dark, 20)
	for k in 6:
		var a := TAU * k / 6.0
		v.cyl(root, 0.018, 0.018, 0.12, wheel + Vector3(cos(a) * 0.38, 0.08, sin(a) * 0.38), wax, 8)
		if k % 2 == 0:
			v.box(root, Vector3(0.008, 0.85, 0.008), wheel + Vector3(cos(a) * 0.2, 0.44, sin(a) * 0.2), iron, Vector3(sin(a) * 0.22, 0, -cos(a) * 0.22))
	# a little table and two stools under the north window
	var nt := Vector3(-0.7, 0, -2.75)
	v.cyl(root, 0.42, 0.42, 0.05, nt + Vector3(0, 0.74, 0), oak, 20)
	v.cyl(root, 0.06, 0.1, 0.72, nt + Vector3(0, 0.36, 0), post, 10)
	v.cyl(root, 0.22, 0.22, 0.04, nt + Vector3(0, 0.02, 0), post, 14)
	for sx in [-0.62, 0.62]:
		v.cyl(root, 0.18, 0.16, 0.44, nt + Vector3(sx, 0.22, 0.12), dark, 12)
	# tankards and candles in bottles on the tables (the middle one's at 0.6, 0.3)
	var tops := [[Vector3(0.6, 0.815, 0.3), 0.5], [tt + Vector3(0, 0.795, 0), 0.7], [nt + Vector3(0, 0.765, 0), 0.25]]
	for i in tops.size():
		var tp: Vector3 = tops[i][0]
		var spread: float = tops[i][1]
		v.cyl(root, 0.045, 0.05, 0.13, tp + Vector3(-spread * 0.4, 0.065, 0.08), pewter, 12)
		v.box(root, Vector3(0.015, 0.08, 0.04), tp + Vector3(-spread * 0.4 + 0.06, 0.07, 0.08), pewter)
		if i != 2:
			v.cyl(root, 0.045, 0.05, 0.13, tp + Vector3(spread * 0.3, 0.065, -0.1), stoneware, 12)
		v.cyl(root, 0.035, 0.035, 0.16, tp + Vector3(spread * 0.05, 0.08, -0.15), mk.call(Color(0.16, 0.3, 0.14), 0.15), 10)
		v.cyl(root, 0.016, 0.016, 0.08, tp + Vector3(spread * 0.05, 0.2, -0.15), wax, 8)
	# cloaks on the pegs east of the front door, a hat on one
	for k in 3:
		var cx := 3.2 + k * 0.45
		v.box(root, Vector3(0.04, 0.04, 0.12), Vector3(cx, 1.7, -D * 0.5 + 0.06), post)
		if k != 1:
			v.box(root, Vector3(0.38, 0.95, 0.08), Vector3(cx, 1.2, -D * 0.5 + 0.1), mk.call([Color(0.3, 0.22, 0.16), Color(0.22, 0.25, 0.3), Color(0.35, 0.18, 0.12)][k], 1.0), Vector3(0.05, 0, 0.03 * (k - 1)))
		else:
			v.cyl(root, 0.17, 0.17, 0.02, Vector3(cx, 1.62, -D * 0.5 + 0.18), mk.call(Color(0.2, 0.16, 0.12), 0.9), 14, Vector3(PI * 0.5, 0, 0))
			v.cyl(root, 0.1, 0.11, 0.12, Vector3(cx, 1.62, -D * 0.5 + 0.22), mk.call(Color(0.2, 0.16, 0.12), 0.9), 14, Vector3(PI * 0.5, 0, 0))
	# the notice board west of the door, Ironvault's notice on it with its seal
	var nb := Vector3(0.62, 1.5, -D * 0.5 + 0.04)
	v.box(root, Vector3(0.8, 0.6, 0.04), nb, dark)
	var sheets := [[Vector3(-0.2, 0.05, 0), Vector2(0.26, 0.34), "notice", 0.05], [Vector3(0.15, -0.06, 0), Vector2(0.24, 0.3), "notice", -0.07], [Vector3(0.22, 0.17, 0), Vector2(0.18, 0.14), "moth", 0.0]]
	for i in sheets.size():
		var sh: Array = sheets[i]
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = sh[1]
		q.mesh = qm
		var pm := StandardMaterial3D.new()
		pm.albedo_texture = _sketch(String(sh[2]), 20 + i)
		pm.roughness = 0.95
		q.material_override = pm
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		q.transform = Transform3D(Basis(Vector3.BACK, float(sh[3])), nb + sh[0] + Vector3(0, 0, 0.025))
		root.add_child(q)
	# Ironvault's red wax seal on the first
	v.cyl(root, 0.03, 0.03, 0.01, nb + Vector3(-0.2, -0.08, 0.03), mk.call(Color(0.6, 0.08, 0.06), 0.4), 12, Vector3(PI * 0.5, 0, 0))
	# the slate of what's on, chalked, on the north wall over the barrels
	var sl := Vector3(-4.0, 1.75, -D * 0.5 + 0.03)
	v.box(root, Vector3(0.62, 0.48, 0.03), sl, mk.call(Color(0.12, 0.13, 0.14), 0.8))
	v.box(root, Vector3(0.68, 0.54, 0.02), sl + Vector3(0, 0, -0.01), oak)
	var chalk := Label3D.new()
	chalk.text = "LANTERN NIGHT\nFestival pie . 3d\nAle . 1d\nCider . 1d"
	chalk.font_size = 40
	chalk.pixel_size = 0.0018
	chalk.modulate = Color(0.88, 0.88, 0.84)
	chalk.outline_size = 0
	chalk.shaded = true
	chalk.double_sided = false
	chalk.line_spacing = -6.0
	chalk.position = sl + Vector3(0, 0.0, 0.02)
	root.add_child(chalk)
	# the cellar's trapdoor in the walkway behind the bar, with its iron ring
	var td := Vector3(-4.05, 0.0, -2.35)
	v.box(root, Vector3(0.72, 0.025, 0.72), td + Vector3(0, 0.012, 0), dark)
	for k in 4:
		v.box(root, Vector3(0.72, 0.028, 0.012), td + Vector3(0, 0.013, -0.27 + k * 0.18), post)
	for sz in [-0.22, 0.22]:
		v.box(root, Vector3(0.28, 0.03, 0.05), td + Vector3(-0.2, 0.016, sz), iron)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.035
	ring.outer_radius = 0.05
	v.add_mesh(root, ring, iron, Transform3D(Basis.IDENTITY, td + Vector3(0.22, 0.03, 0)))


## The taproom's windows (29 October): one in the west wall behind the bar,
## to the north of the shelves (x unused, its middle along the wall z, its
## sill y... as [along, sill, width] it's x = middle along the wall, y =
## sill height, z = width), and two in the north wall west of the door
## (their middles along x, sills, widths). All 1.0 m of glass tall.
const EVE_WEST_WINDOW := Vector3(-1.75, 1.15, 0.8)
const EVE_NORTH_WINDOWS := [Vector3(-3.0, 1.05, 0.9), Vector3(-0.7, 1.05, 0.9)]
const EVE_WINDOW_H := 1.0


## A wall `length` long along `along` (a unit x or z), `h` tall, its middle
## on the floor at `mid`, 0.3 thick, with window holes: each [middle along
## the wall from its own middle, sill height, width], EVE_WINDOW_H tall.
static func _wall_with_holes(v: AshfordVillage, root: Node3D, mat: Material, mid: Vector3, along: Vector3, length: float, h: float, holes: Array) -> void:
	var size_of := func(a: float, y: float) -> Vector3:
		return Vector3(a, y, 0.3) if along.x != 0.0 else Vector3(0.3, y, a)
	var cuts := holes.duplicate()
	cuts.sort_custom(func(p, q): return float(p[0]) < float(q[0]))
	var at := -length * 0.5
	for c in cuts:
		var c0 := float(c[0]) - float(c[2]) * 0.5
		var c1 := float(c[0]) + float(c[2]) * 0.5
		var sill := float(c[1])
		var top := sill + EVE_WINDOW_H
		if c0 > at:
			v.box(root, size_of.call(c0 - at, h), mid + along * (at + c0) * 0.5 + Vector3(0, h * 0.5, 0), mat)
		v.box(root, size_of.call(c1 - c0, sill), mid + along * (c0 + c1) * 0.5 + Vector3(0, sill * 0.5, 0), mat)
		v.box(root, size_of.call(c1 - c0, h - top), mid + along * (c0 + c1) * 0.5 + Vector3(0, (top + h) * 0.5, 0), mat)
		at = c1
	if length * 0.5 > at:
		v.box(root, size_of.call(length * 0.5 - at, h), mid + along * (at + length * 0.5) * 0.5 + Vector3(0, h * 0.5, 0), mat)


## The windows' glass, frames, sills and shutters, and the cold morning light
## through them. The shutters are inside, two leaves to a window, folded back
## against the wall, but for the one Bram means ("Left the shutter unlatched
## again"): the north window over the barrels, its west leaf swung out into
## the room and knocking a little in the draught.
static func _eve_windows(v: AshfordVillage, root: Node3D, W: float, D: float) -> void:
	# [the glass's middle, which way into the room, width, unlatched]
	var wins := [[Vector3(-W * 0.5 - 0.15, EVE_WEST_WINDOW.y + EVE_WINDOW_H * 0.5, EVE_WEST_WINDOW.x), Vector3(1, 0, 0), EVE_WEST_WINDOW.z, false]]
	var first := true
	for c in EVE_NORTH_WINDOWS:
		wins.append([Vector3((c as Vector3).x, (c as Vector3).y + EVE_WINDOW_H * 0.5, -D * 0.5 - 0.15), Vector3(0, 0, 1), (c as Vector3).z, first])
		first = false
	var n := 0
	for wdef in wins:
		var c: Vector3 = wdef[0]
		var inw: Vector3 = wdef[1]
		var ww: float = wdef[2]
		var unl: bool = wdef[3]
		var hh := EVE_WINDOW_H
		var across := Vector3.UP.cross(inw)   # along the wall
		var yaw := atan2(inw.x, inw.z)
		var face := c + inw * 0.15   # the wall's inner face
		# the glass, set back in the wall
		var pane := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(ww, hh)
		pane.mesh = q
		var pm := ShaderMaterial.new()
		pm.shader = load("res://assets/shaders/village/pane.gdshader")
		pm.set_shader_parameter("seed", float(n) * 3.7)
		pm.set_shader_parameter("panes", Vector2(ww / 0.3, hh / 0.3))
		pane.material_override = pm
		pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pane.transform = Transform3D(Basis(Vector3.UP, yaw), c - inw * 0.04)
		root.add_child(pane)
		# the frame round it on the inside, the mullion, the deep sill
		var rot := Vector3(0, yaw, 0)
		for sd in [-1.0, 1.0]:
			v.box(root, Vector3(0.09, hh + 0.18, 0.08), face + across * sd * (ww * 0.5 + 0.045) + inw * 0.02, v.mats.beam_v, rot)
		v.box(root, Vector3(ww + 0.36, 0.14, 0.1), face + Vector3(0, hh * 0.5 + 0.07, 0) + inw * 0.03, v.mats.beam, rot)
		v.box(root, Vector3(ww + 0.3, 0.05, 0.36), face + Vector3(0, -hh * 0.5 - 0.025, 0) - inw * 0.1, v.mats.wood_h, rot)
		v.box(root, Vector3(0.05, hh, 0.05), c - inw * 0.02, v.mats.beam, rot)
		# the shutters: a leaf each side, hinged at the frame, iron strap
		# hinges and a latch bar
		for sd in [-1.0, 1.0]:
			var hinge := Node3D.new()
			hinge.position = face + across * sd * (ww * 0.5 + 0.1) + inw * 0.04
			hinge.rotation.y = yaw
			root.add_child(hinge)
			var leaf := Node3D.new()
			hinge.add_child(leaf)
			v.box(leaf, Vector3(ww * 0.5, hh + 0.06, 0.035), Vector3(-sd * ww * 0.25, 0, 0), v.mats.door_natural)
			for y in [-0.32, 0.32]:
				v.box(leaf, Vector3(ww * 0.36, 0.04, 0.012), Vector3(-sd * ww * 0.17, y, 0.022), v.mats.metal)
			# folded back flat against the wall, or swung out on its hinge
			var open := deg_to_rad(168.0)
			if unl and sd < 0.0:
				open = deg_to_rad(64.0)
				var sway := func() -> void:
					var tw := leaf.create_tween().set_loops()
					tw.tween_property(leaf, "rotation:y", sd * deg_to_rad(5.0), 2.3).set_trans(Tween.TRANS_SINE)
					tw.tween_property(leaf, "rotation:y", sd * deg_to_rad(-1.5), 1.9).set_trans(Tween.TRANS_SINE)
					tw.tween_interval(1.2)
				if leaf.is_inside_tree():
					sway.call()
				else:
					leaf.tree_entered.connect(sway, CONNECT_ONE_SHOT)
			hinge.rotation.y = yaw + sd * open
		# the day coming in: cold, from high outside, onto the floor
		var sun := SpotLight3D.new()
		sun.light_color = Color(0.84, 0.9, 1.0)
		sun.light_energy = 2.2 if unl else 1.6
		sun.spot_range = 7.5
		sun.spot_angle = 26.0
		sun.spot_attenuation = 0.8
		sun.shadow_enabled = v.quality > 0
		root.add_child(sun)
		sun.position = c - inw * 1.2 + Vector3(0, 1.0, 0)
		sun.look_at(root.to_global(c + inw * 2.6 + Vector3(0, -c.y, 0)), Vector3.UP)
		n += 1


## Polished oak for the counter's top: honey-brown, the grain along it.
static func counter_oak(v: AshfordVillage) -> Material:
	return v.shader_mat("wood", {"wood_a": Color(0.42, 0.26, 0.13), "wood_b": Color(0.27, 0.16, 0.08), "grain_axis": Vector3(0, 0, 1)})


## The wall behind the bar, dressed (29 October, Gary: "behind him can we
## add some ornaments on the wall so it doesn't look so plain"): two shelves
## from the counter's flap end to the window, the good tankards out on the
## green but the rest of a working inn on them (stoneware jugs, bottles,
## pewter plates stood on edge, a crock, a candle, a folded paper lantern
## for tonight), copper measures on the hooks under the top shelf, and over
## them the inn's painted board, The Crooked Lantern, Bram's old round
## shield with a short sword behind it from his years in the Shards, and a
## string of dried hops along the beam.
static func _eve_dressing(v: AshfordVillage, root: Node3D, W: float, _D: float, _H: float) -> void:
	var wx := -W * 0.5   # the west wall's inner face
	var z0 := -1.12      # the shelves' north end (the window's south side)
	var z1 := 1.65
	var zl := z1 - z0
	for y in [1.5, 2.1]:
		v.box(root, Vector3(0.3, 0.05, zl), Vector3(wx + 0.18, y, (z0 + z1) * 0.5), v.mats.wood_h)
		for zz in [z0 + 0.12, (z0 + z1) * 0.5, z1 - 0.12]:
			v.box(root, Vector3(0.05, 0.14, 0.04), Vector3(wx + 0.06, y - 0.09, zz), v.mats.beam_v, Vector3(0, 0, 0.6))
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.74, 0.66, 0.52)
	stone.roughness = 0.6
	var stone_dk := StandardMaterial3D.new()
	stone_dk.albedo_color = Color(0.42, 0.3, 0.2)
	stone_dk.roughness = 0.5
	var pewter := StandardMaterial3D.new()
	pewter.albedo_color = Color(0.62, 0.62, 0.6)
	pewter.metallic = 0.85
	pewter.roughness = 0.38
	var copper := StandardMaterial3D.new()
	copper.albedo_color = Color(0.78, 0.42, 0.24)
	copper.metallic = 0.9
	copper.roughness = 0.32
	var green_glass := StandardMaterial3D.new()
	green_glass.albedo_color = Color(0.16, 0.3, 0.14, 0.82)
	green_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	green_glass.roughness = 0.12
	green_glass.metallic_specular = 0.8
	var brown_glass := green_glass.duplicate() as StandardMaterial3D
	brown_glass.albedo_color = Color(0.36, 0.18, 0.07, 0.85)
	var wax := StandardMaterial3D.new()
	wax.albedo_color = Color(0.93, 0.88, 0.74)
	wax.roughness = 0.7
	var x := wx + 0.2
	# the lower shelf (its top at 1.525)
	var y1 := 1.525
	var row1 := [["jug", 0.12], ["bottle_g", 0.16], ["bottle_b", 0.08], ["plate", 0.15], ["crock", 0.12], ["jug_s", 0.12],
		["candle", 0.18], ["bottle_g", 0.1], ["bottle_g", 0.07], ["bottle_b", 0.1], ["plate", 0.14], ["jug", 0.15], ["crock", 0.14], ["bottle_b", 0.12]]
	var row2 := [["plate", 0.1], ["plate", 0.07], ["jug_s", 0.16], ["lantern", 0.2], ["bottle_g", 0.2], ["jug", 0.16],
		["plate", 0.14], ["plate", 0.07], ["crock", 0.16], ["bottle_b", 0.12], ["jug_s", 0.12]]
	for r in [[row1, y1], [row2, 2.125]]:
		var z := z1 - 0.1
		for it in r[0]:
			var kind: String = it[0]
			z -= float(it[1])
			if z < z0 + 0.08:
				break
			var p := Vector3(x, float(r[1]), z)
			match kind:
				"jug":
					v.cyl(root, 0.045, 0.07, 0.17, p + Vector3(0, 0.085, 0), stone, 12)
					v.cyl(root, 0.035, 0.045, 0.05, p + Vector3(0, 0.195, 0), stone, 12)
					v.box(root, Vector3(0.015, 0.1, 0.02), p + Vector3(0.06, 0.12, 0), stone_dk)
				"jug_s":
					v.cyl(root, 0.035, 0.05, 0.12, p + Vector3(0, 0.06, 0), stone_dk, 12)
					v.cyl(root, 0.025, 0.035, 0.04, p + Vector3(0, 0.14, 0), stone_dk, 12)
				"bottle_g", "bottle_b":
					var gm: Material = green_glass if kind == "bottle_g" else brown_glass
					v.cyl(root, 0.035, 0.035, 0.18, p + Vector3(0, 0.09, 0), gm, 10)
					v.cyl(root, 0.012, 0.03, 0.06, p + Vector3(0, 0.21, 0), gm, 8)
					v.cyl(root, 0.014, 0.014, 0.025, p + Vector3(0, 0.25, 0), stone_dk, 6)
				"plate":
					# stood on edge, leant back against the wall
					v.cyl(root, 0.11, 0.11, 0.012, p + Vector3(-0.08, 0.11, 0), pewter, 18, Vector3(0, 0, PI * 0.5 - 0.2))
				"crock":
					v.cyl(root, 0.06, 0.065, 0.13, p + Vector3(0, 0.065, 0), stone, 12)
					v.cyl(root, 0.064, 0.064, 0.02, p + Vector3(0, 0.135, 0), stone_dk, 12)
				"candle":
					v.cyl(root, 0.045, 0.05, 0.015, p + Vector3(0, 0.008, 0), pewter, 12)
					v.cyl(root, 0.016, 0.016, 0.11, p + Vector3(0, 0.07, 0), wax, 8)
				"lantern":
					# a paper lantern folded flat for tonight, its ribs showing
					var paper := StandardMaterial3D.new()
					paper.albedo_color = Color(0.93, 0.62, 0.3)
					paper.roughness = 0.9
					v.cyl(root, 0.08, 0.08, 0.07, p + Vector3(0, 0.035, 0), paper, 14)
					for k in 3:
						v.cyl(root, 0.082, 0.082, 0.006, p + Vector3(0, 0.012 + k * 0.024, 0), stone_dk, 14)
	# copper measures on the hooks under the top shelf
	for k in 6:
		var hz := z0 + 0.25 + k * 0.45
		v.box(root, Vector3(0.04, 0.09, 0.03), Vector3(wx + 0.12, 2.0, hz), v.mats.metal)
		if k % 3 != 2:
			var s := 0.75 + 0.12 * (k % 2)
			v.cyl(root, 0.045 * s, 0.055 * s, 0.11 * s, Vector3(wx + 0.16, 1.88, hz), copper, 12)
			v.box(root, Vector3(0.012, 0.07 * s, 0.02), Vector3(wx + 0.1, 1.9, hz), copper)
	# over the shelves: the inn's board
	var board_at := Vector3(wx + 0.05, 2.55, 0.25)
	v.box(root, Vector3(0.05, 0.42, 1.25), board_at, v.mats.wood)
	v.box(root, Vector3(0.06, 0.48, 0.05), board_at + Vector3(0.005, 0, 0.645), v.mats.beam)
	v.box(root, Vector3(0.06, 0.48, 0.05), board_at + Vector3(0.005, 0, -0.645), v.mats.beam)
	var name_lbl := Label3D.new()
	name_lbl.text = "The Crooked Lantern"
	name_lbl.font = load("res://assets/fonts/Cinzel-Bold.woff2")
	name_lbl.font_size = 64
	name_lbl.pixel_size = 0.0016
	name_lbl.modulate = Color(0.88, 0.7, 0.36)
	name_lbl.outline_size = 0
	name_lbl.shaded = true
	name_lbl.double_sided = false
	name_lbl.position = board_at + Vector3(0.03, 0.04, 0)
	name_lbl.rotation.y = PI * 0.5
	root.add_child(name_lbl)
	var est := Label3D.new()
	est.text = "ASHFORD"
	est.font = name_lbl.font
	est.font_size = 40
	est.pixel_size = 0.0016
	est.modulate = Color(0.72, 0.56, 0.3)
	est.shaded = true
	est.double_sided = false
	est.position = board_at + Vector3(0.03, -0.12, 0)
	est.rotation.y = PI * 0.5
	root.add_child(est)
	# Bram's round shield from the Shards, a short sword behind it
	var shield_at := Vector3(wx + 0.06, 2.5, 1.35)
	var leather := StandardMaterial3D.new()
	leather.albedo_color = Color(0.34, 0.2, 0.11)
	leather.roughness = 0.75
	v.box(root, Vector3(0.025, 0.05, 0.62), shield_at + Vector3(-0.02, 0.02, 0.0), v.mats.metal, Vector3(0.75, 0, 0))
	v.box(root, Vector3(0.02, 0.09, 0.03), shield_at + Vector3(-0.02, -0.22, 0.22), v.mats.beam, Vector3(0.75, 0, 0))
	v.cyl(root, 0.24, 0.24, 0.04, shield_at + Vector3(0.02, 0, 0), leather, 24, Vector3(0, 0, PI * 0.5))
	v.cyl(root, 0.245, 0.245, 0.03, shield_at + Vector3(0.025, 0, 0), copper, 24, Vector3(0, 0, PI * 0.5))
	v.cyl(root, 0.22, 0.22, 0.045, shield_at + Vector3(0.026, 0, 0), leather, 24, Vector3(0, 0, PI * 0.5))
	v.cyl(root, 0.06, 0.07, 0.05, shield_at + Vector3(0.06, 0, 0), pewter, 14, Vector3(0, 0, PI * 0.5))
	# dried hops along the beam over it all, swagged between nails
	var hop := StandardMaterial3D.new()
	hop.albedo_color = Color(0.62, 0.6, 0.34)
	hop.roughness = 0.9
	var leafm := StandardMaterial3D.new()
	leafm.albedo_color = Color(0.36, 0.38, 0.2)
	leafm.roughness = 0.9
	var hz0 := z0 - 0.1
	var hz1 := z1 + 0.05
	var cones := 26
	for k in cones:
		var u := float(k) / (cones - 1)
		var zz := lerpf(hz0, hz1, u)
		var sag := 0.13 * sin(fmod(u * 3.0, 1.0) * PI)
		var py := 2.88 - sag
		var sz := 0.035 + 0.01 * sin(float(k) * 1.7)
		v.cyl(root, sz * 0.4, sz, sz * 1.8, Vector3(wx + 0.09, py - 0.03, zz), hop, 7, Vector3(0.0, 0, PI))
		if k % 2 == 0:
			v.box(root, Vector3(0.012, 0.05, 0.07), Vector3(wx + 0.1, py + 0.01, zz + 0.03), leafm, Vector3(0.5, 0, 0.3))


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


static func _thin_box(x: float, y: float, z: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(x, y, z)
	return b
