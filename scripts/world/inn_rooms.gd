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
		v.env.ambient_light_color, v.env.ambient_light_energy, v.env.fog_density])
	v.moon_light.visible = false
	v.tear_light.visible = false
	v.env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	v.env.ambient_light_color = Color(0.45, 0.36, 0.3)
	v.env.ambient_light_energy = 0.35
	v.env.fog_density = 0.0


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
	v.remove_meta("outside_env")
