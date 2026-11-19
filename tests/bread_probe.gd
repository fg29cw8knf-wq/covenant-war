extends Node
## Tam's bread handed over and held (18 November, the body sweep: "player's
## right wrist is 3.7 cm inside Bread" for 17 s: it was put on the hand
## bone's joint, round his wrist like a bracelet; Gary's yes to putting it in
## his palm). Tam tears it off the loaf and holds it out, the hero takes it,
## and stands holding it for six seconds while the body check looks at every
## frame. Where the bread's middle is from his palm, and stills when drawn.
##   godot --headless --fixed-fps 30 --path . res://tests/bread_probe.tscn
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --rendering-method gl_compatibility \
##       --resolution 1280x720 --fixed-fps 30 --path . res://tests/bread_probe.tscn -- <dir>

const BodyCheck = preload("res://tests/body_check.gd")
var out := ""
var world: World


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0 and not String(args[0]).contains("="):
		out = String(args[0])
		DirAccess.make_dir_recursive_absolute(out)
	Game.new_game("Sprout", "")
	Game.set_flag("arrived_ashford")
	for f in ["ash_started", "p1_crate_down", "corin_met", "first_deck", "ash_won_lantern", "ash_tam", "tam_letter_seen"]:
		Game.set_flag(f)
	Game.set_flag("p1_stage", "done")
	Game.settings["first_steps"] = 2
	world = World.new().setup("ashford", "green")
	add_child(world)
	for k in 30:
		await get_tree().process_frame
	AshfordP1.dress(world)
	AshfordDay.stage(world)
	for k in 10:
		await get_tree().process_frame
	if world.hud != null:
		world.hud.visible = false
	var tb := Cine.body(world, "tam")
	var problems: Array = []
	if tb == null:
		print("BREAD PROBE: no Tam")
		get_tree().quit(1)
		return
	AshfordDay.festival_loaf(world)
	var tp := tb.global_position
	var away := Vector3(-tp.x, 0.0, -tp.z).normalized()
	AshfordP1.put(world, "player", tp + away * 1.0, tp)
	Cine.look(world, "tam", world.player.global_position)
	for k in 10:
		await get_tree().process_frame
	world.busy = true
	var bc: Node = BodyCheck.watch(world, out + "/body" if out != "" else "")
	await AshfordDay.tam_bread(world)
	var pf := world.player_doll as Figure3D
	var bread: Node3D = null
	for n in world.find_children("Bread", "Node3D", true, false):
		bread = n
	if bread == null:
		problems.append("no bread in his hand")
	else:
		var bb := AABB()
		var first := true
		for mi: MeshInstance3D in bread.find_children("*", "MeshInstance3D", true, false):
			var b := bread.global_transform.affine_inverse() * mi.global_transform * mi.get_aabb()
			bb = b if first else bb.merge(b)
			first = false
		print("BREAD PROBE: the bread's size in its own frame %s cm (from its middle %s)" % [str((bb.size * 100.0).snappedf(0.1)), str((bb.position * 100.0).snappedf(0.1))])
	# six seconds holding it: where its middle is from his palm, as drawn
	var off := [Vector3.ZERO, 0]
	var cb := func() -> void:
		if bread != null and is_instance_valid(bread):
			var f := pf.palm_frame("right")
			off[0] += f.basis.inverse() * (bread.global_position - f.origin)
			off[1] += 1
	pf._skel.skeleton_updated.connect(cb)
	if out != "":
		await _still("1_held", pf, false)
		await _still("2_held_close", pf, true)
	var t := 0.0
	while t < 6.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	pf._skel.skeleton_updated.disconnect(cb)
	# and put away in his pocket when Tam's done
	await AshfordDay.tam_bread_away(world)
	for k in 20:
		await get_tree().process_frame
	var gone := bread == null or not is_instance_valid(bread) or not bread.is_inside_tree()
	print("BREAD PROBE: put away in his pocket: %s" % str(gone))
	if not gone:
		problems.append("the bread was never put away")
	if out != "":
		await _still("3_put_away", pf, false)
	var mean: Vector3 = off[0] / maxf(float(off[1]), 1.0)
	print("BREAD PROBE: the bread's middle from his palm (across, out of it, along the fingers): %s cm" % str((mean * 100.0).snappedf(0.1)))
	var found := 0
	for r: Dictionary in bc.reported:
		if String(r.get("text", "")).contains("Bread") or String(r.get("what", "")).contains("Bread"):
			found += 1
			print("BREAD PROBE: ", r.get("text", r))
	if found > 0:
		problems.append("the body check found him in the bread %d times" % found)
	if absf(mean.z) > 0.09 or mean.y < -0.01:
		problems.append("the bread isn't in his palm (%s cm off its middle)" % str((mean * 100.0).snappedf(0.1)))
	if problems.is_empty():
		print("BREAD PROBE: ok")
	else:
		print("BREAD PROBE: %d problems: %s" % [problems.size(), "; ".join(problems)])
	get_tree().quit(0 if problems.is_empty() else 1)


func _still(name: String, pf: Figure3D, close: bool) -> void:
	# (the palm as it's drawn: read in its bones' own pass, the reach in it)
	await get_tree().create_timer(0.6).timeout
	var got := [Vector3.INF]
	pf._skel.skeleton_updated.connect(func() -> void: got[0] = pf.palm_frame("right").origin, CONNECT_ONE_SHOT)
	for k in 3:
		await get_tree().process_frame
	var hand: Vector3 = got[0] if got[0] != Vector3.INF else pf.bone_pos("RightHand")
	var face := pf.facing()
	var side := Vector3.UP.cross(face).normalized()
	if close:
		# (from in front of him, at the hand's height: between his hand and
		# his leg, where the bread is)
		Cine.shot(world, hand + face * 0.45 - side * 0.2 + Vector3(0, 0.2, 0), hand, 38.0)
	else:
		Cine.shot(world, pf.global_position + face * 2.2 - side * 0.9 + Vector3(0, 1.5, 0), pf.global_position + Vector3(0, 1.0, 0), 40.0)
	for k in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
