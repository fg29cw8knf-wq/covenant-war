extends Node
## The attic blanket laid over the sleeper (18 November, Gary's yes to "a
## soft blanket that folds over him": BlanketDrape). The hero is put to bed
## as the attic's first shot has him (AshfordP1.asleep) and the blanket is
## looked at and measured:
## - that it was laid over him (twice the squares, its shade, its points
##   without his left arm), and how long that took;
## - how near his skin the cloth comes anywhere under it, read off his own
##   skin as it's drawn, then and for six seconds of him lying there (his
##   breathing); nothing of him through it;
## - how high it stands, how much of it lies on the mattress;
## - put to bed again: the same cloth, not made again;
## - the blanket thrown back (BlanketThrow) and laid again.
## Drawn, stills from five places: the game's own shot of the whole of him,
## low from the open side, from the foot, from above, and close on the hem.
##
##   godot --headless --path . res://tests/blanket_look.tscn
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --rendering-method gl_compatibility \
##       --resolution 1280x720 --path . res://tests/blanket_look.tscn -- <dir> [plain] [look]
## (`plain`: the stills of the blanket as it was, laid by rule, for comparing.
## `look`: with a light of the test's own over the bed, to see the cloth's
## shape by; the game's own light on it is in tests/mark_wake_test's stills.)

var out := ""
var plain := false
var look := false
var world: World


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if String(a) == "plain":
			plain = true
		elif String(a) == "look":
			look = true
		elif out == "":
			out = String(a)
	if out != "":
		DirAccess.make_dir_recursive_absolute(out)
	var fails: Array = []
	BlanketDrape.measure = true
	# (the attic as the game has it under the title screen: built, the frosty
	# morning on, the hero asleep, the first shot on the camera; held there,
	# the opening never begun)
	var made0 := BlanketDrape.made
	Game.new_game("Sprout", "")
	Game.settings["first_steps"] = 0
	world = World.new().setup("ashford", "green")
	add_child(world)
	await world.prepare()
	world.visible = true
	world.process_mode = Node.PROCESS_MODE_INHERIT
	Cine.overlay(world)._black.modulate.a = 0.0
	var v: AshfordVillage = AshfordP1.village(world)
	var a := InnRooms.attic(v)
	var bl := a.blanket as MeshInstance3D
	var plain_rows: Array = InnRooms._blanket_points(InnRooms.BLANKET_L, float(bl.get_meta("width", 0.96)))
	if look:
		# (a light of the test's own over the bed's open side, to see the
		# cloth's shape by: not the game's light)
		var l := OmniLight3D.new()
		l.light_energy = 2.2
		l.omni_range = 5.0
		l.shadow_enabled = true
		(a.root as Node3D).add_child(l)
		l.global_position = (a.bed as Vector3) + (a.root as Node3D).global_transform.basis * Vector3(-0.6, 1.3, 1.1)
	if plain:
		for i in 20:
			await get_tree().process_frame
		bl.mesh = InnRooms._blanket_mesh_of(plain_rows)
		await _stills(a, "plain")
		print("BLANKET LOOK: plain stills in ", out)
		get_tree().quit()
		return
	var waited := 0
	while BlanketDrape.made == made0 and waited < 80:
		await get_tree().process_frame
		waited += 1
	var rows: Array = bl.get_meta("rows")
	var st: Dictionary = BlanketDrape.last
	print("BLANKET LOOK: laid over him after %d frames, in %.0f ms: %d by %d points (it was %d by %d); %d points of his skin read, %d under it" % [
		waited, BlanketDrape.last_ms, rows.size(), (rows[0] as Array).size(), plain_rows.size(), (plain_rows[0] as Array).size(), int(st.get("skin", 0)), int(st.get("under", 0))])
	if BlanketDrape.made == made0:
		fails.append("the blanket was never laid over him")
	if rows.size() != BlanketDrape.NX + 1 or (rows[0] as Array).size() != BlanketDrape.NZ + 1:
		fails.append("the laid blanket has %d by %d points" % [rows.size(), (rows[0] as Array).size()])
	if not bl.has_meta("rows_free") or not bl.has_meta("shade") or bl.mesh != bl.get_meta("mesh_on"):
		fails.append("the blanket isn't wearing what was laid")
	print("BLANKET LOOK: as laid: the cloth %.1f cm from his skin at nearest, %d points of him through it; it stands %.1f cm over the mattress's edge at most" % [
		float(st.get("least", 0.0)) * 100.0, int(st.get("through", -1)), float(st.get("top", 0.0)) * 100.0])
	if int(st.get("through", 1)) > 0 or float(st.get("least", 0.0)) < 0.004:
		fails.append("his skin comes within %.1f cm of the cloth as laid (%d points through it)" % [float(st.get("least", 0.0)) * 100.0, int(st.get("through", -1))])
	# how it lies: on the mattress, over him, the folds
	var on_bed := 0
	var over_him := 0
	var n := 0
	var free: Array = bl.get_meta("rows_free", rows)
	var arm_most := 0.0
	for i in rows.size():
		for j in (rows[i] as Array).size():
			var p: Vector3 = rows[i][j]
			n += 1
			if p.y - BlanketDrape.mattress_y(p.x, p.z) < 0.03:
				on_bed += 1
			elif p.y > 0.08:
				over_him += 1
			arm_most = maxf(arm_most, p.y - (free[i][j] as Vector3).y)
	print("BLANKET LOOK: %d%% of it lies on the mattress, %d%% stands 8 cm or more over its edge; without his left arm under it, it lies up to %.1f cm lower" % [
		roundi(100.0 * on_bed / n), roundi(100.0 * over_him / n), arm_most * 100.0])
	if on_bed < n / 10 or over_him < n / 10:
		fails.append("the cloth doesn't lie both on the mattress and over him (%d and %d of %d points)" % [on_bed, over_him, n])
	if arm_most < 0.02:
		fails.append("the cloth without his left arm under it is the same as with it")
	if out != "":
		await _stills(a, "laid")
	if look:
		print("BLANKET LOOK: stills in ", out)
		get_tree().quit()
		return
	# six seconds of him lying there: his skin against the cloth as it's drawn
	var least := INF
	var through_most := 0
	var fig := world.player_doll as Figure3D
	var looks := 12 if out == "" else 3   # (drawn, a look takes seconds)
	for k in looks:
		for i in 5:
			await get_tree().process_frame
		var got := await _skin_under(bl, fig)
		least = minf(least, float(got[0]))
		through_most = maxi(through_most, int(got[1]))
	print("BLANKET LOOK: lying there (%d looks): the cloth %.1f cm from his skin at nearest, at most %d points of him through it" % [looks, least * 100.0, through_most])
	if through_most > 0:
		fails.append("%d points of him came through the cloth as he lay there (nearest %.1f cm)" % [through_most, least * 100.0])
	# put to bed again: the same cloth, not made again
	var made1 := BlanketDrape.made
	var mesh1 := bl.mesh
	AshfordP1.asleep(world)
	for i in 40:
		await get_tree().process_frame
	print("BLANKET LOOK: put to bed again: made again %s, the same cloth %s" % [str(BlanketDrape.made != made1), str(bl.mesh == mesh1)])
	if BlanketDrape.made != made1 or bl.mesh != mesh1:
		fails.append("the cloth was made again for the same way of lying")
	# thrown back by his own hand, and how long a frame of that takes here
	# (against a frame of him lying there)
	var tb := Time.get_ticks_usec()
	for i in 60:
		await get_tree().process_frame
	var usual := (Time.get_ticks_usec() - tb) / 1000.0 / 60.0
	var hand := Node3D.new()
	world.add_child(hand)
	var t0 := Time.get_ticks_usec()
	var f0 := Engine.get_process_frames()
	var done := [false]
	var run := func() -> void:
		await AshfordP1.throw_blanket(world, fig, a, hand, 0.8)
		done[0] = true
	run.call()
	var shot := false
	var guard := 0
	while not done[0] and guard < 600:
		await get_tree().process_frame
		guard += 1
		var th := _throw_of(bl)
		if out != "" and not shot and th != null and th.t > 0.4:
			shot = true
			await _one(a, "thrown_half", Vector3(2.45, 1.6, 1.3), Vector3(0.2, 0.15, 0.0), 46.0)
	var frames := Engine.get_process_frames() - f0
	var ms := (Time.get_ticks_usec() - t0) / 1000.0 / maxf(frames, 1.0)
	await get_tree().create_timer(1.2).timeout
	print("BLANKET LOOK: thrown back: %d frames, %.1f ms a frame here (%.1f lying there); in its heap %s" % [frames, ms, usual, str(bl.mesh != bl.get_meta("mesh_on"))])
	if _throw_of(bl) != null or bl.mesh == bl.get_meta("mesh_on"):
		fails.append("the blanket wasn't thrown back")
	if out != "":
		await _one(a, "thrown", Vector3(2.45, 1.6, 1.3), Vector3(0.2, 0.15, 0.0), 46.0)
	hand.queue_free()
	fig.let_go(0.1)
	AshfordP1.asleep(world)
	for i in 30:
		await get_tree().process_frame
	if bl.mesh != bl.get_meta("mesh_on") or bl.mesh != mesh1:
		fails.append("put to bed after the throw, the blanket isn't laid over him again")
	if fails.is_empty():
		print("BLANKET LOOK: ok")
	else:
		print("BLANKET LOOK: %d problems: %s" % [fails.size(), "; ".join(fails)])
	get_tree().quit(0 if fails.is_empty() else 1)


func _throw_of(bl: Node) -> BlanketThrow:
	for c in bl.get_children():
		if c is BlanketThrow and not c.is_queued_for_deletion():
			return c
	return null


## His skin against the cloth as both are drawn now: [the least the cloth
## stands over a point of his skin under it (m), how many points are
## through it]. Read in his bones' own pass.
func _skin_under(bl: MeshInstance3D, fig: Figure3D) -> Array:
	var res := [INF, 0]
	var done := [false]
	var cb := func() -> void:
		if done[0]:
			return
		done[0] = true
		var d := BlanketDrape.new()
		d.blanket = bl
		d.fig = fig
		var sk: Array = d._skin()
		d.free()
		var pts: PackedVector3Array = sk[0]
		var rows: Array = bl.get_meta("rows")
		var npx := rows.size()
		var npz := (rows[0] as Array).size()
		# the cloth's triangles, by the square of the grid they're in
		for p in pts:
			var best := INF
			# (the squares round where it would be on a plain grid)
			var fi := (p.x + InnRooms.BLANKET_L * 0.5) / (InnRooms.BLANKET_L / (npx - 1))
			var fj := (p.z + float(bl.get_meta("width", 0.96)) * 0.5) / (float(bl.get_meta("width", 0.96)) / (npz - 1))
			for i in range(maxi(int(fi) - 2, 0), mini(int(fi) + 2, npx - 1)):
				for j in range(maxi(int(fj) - 2, 0), mini(int(fj) + 2, npz - 1)):
					var a: Vector3 = rows[i][j]
					var b: Vector3 = rows[i + 1][j]
					var c: Vector3 = rows[i + 1][j + 1]
					var e: Vector3 = rows[i][j + 1]
					for tri in [[a, c, b], [a, e, c]]:
						var y = _over(p, tri[0], tri[1], tri[2])
						if y != null:
							best = minf(best, float(y) - p.y)
			if best == INF:
				continue
			res[0] = minf(float(res[0]), best)
			if best < 0.0:
				res[1] = int(res[1]) + 1
	fig._skel.skeleton_updated.connect(cb, CONNECT_ONE_SHOT)
	var guard := 0
	while not done[0] and guard < 20:
		await get_tree().process_frame
		guard += 1
	if not done[0]:
		if fig._skel.skeleton_updated.is_connected(cb):
			fig._skel.skeleton_updated.disconnect(cb)
		cb.call()
	return res


## The height of the triangle a-b-c over the point p (seen from above), or
## null if p isn't under it.
func _over(p: Vector3, a: Vector3, b: Vector3, c: Vector3):
	var v0 := Vector2(b.x - a.x, b.z - a.z)
	var v1 := Vector2(c.x - a.x, c.z - a.z)
	var v2 := Vector2(p.x - a.x, p.z - a.z)
	var den := v0.x * v1.y - v1.x * v0.y
	if absf(den) < 1e-10:
		return null
	var u := (v2.x * v1.y - v1.x * v2.y) / den
	var w := (v0.x * v2.y - v2.x * v0.y) / den
	if u < -0.001 or w < -0.001 or u + w > 1.002:
		return null
	return a.y + (b.y - a.y) * u + (c.y - a.y) * w


func _stills(a: Dictionary, tag: String) -> void:
	# the game's own shot of the whole of him; low from the open side; from
	# the foot; from above; close on the hem
	await _one(a, tag + "_1_whole", Vector3(2.45, 1.6, 1.3), Vector3(0.2, 0.15, 0.0), 46.0)
	await _one(a, tag + "_2_side", Vector3(0.25, 0.95, 1.9), Vector3(0.2, 0.05, 0.0), 44.0)
	await _one(a, tag + "_3_foot", Vector3(2.3, 1.15, 0.25), Vector3(0.0, 0.1, 0.0), 40.0)
	await _one(a, tag + "_4_above", Vector3(0.35, 1.25, 0.75), Vector3(0.35, 0.0, -0.05), 62.0)
	await _one(a, tag + "_5_hem", Vector3(-0.1, 1.05, 1.0), Vector3(-0.35, 0.15, 0.0), 36.0)


## A still from `at` looking at `to`, both from the bed's middle at the
## mattress's height (x down the bed, z out into the room).
func _one(a: Dictionary, name: String, at: Vector3, to: Vector3, fov: float) -> void:
	if out == "":
		return
	var bed: Vector3 = a.bed
	var root := a.root as Node3D
	var rb := root.global_transform.basis
	if name.ends_with("_1_whole") or name.begins_with("thrown"):
		Cine.shot(world, root.to_global(at), bed + to, fov)
	else:
		Cine.shot(world, bed + rb * at, bed + rb * to, fov)
	for i in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
