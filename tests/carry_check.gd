extends Node
## Each look carrying the lantern crate (the P1 carry: the crate held in
## front, both hands on its handles through the hand IK), from the side and
## the front, with each arm bone's scale and length checked: for a stretched
## arm, cloth that comes up with a hand (tools/arm_weights.py mends that) or a
## crate in the wrong place (Gary, 22 October: "Player D, when he's holding
## the lanterns, his image becomes distorted").
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 960x540 \
##       res://tests/carry_check.tscn -- <out_dir> [a,b,c,d]

var out := "/tmp/carry"
var looks: Array = ["a", "b", "c", "d"]
var problems := 0


func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	if a.size() > 1:
		looks = Array(String(a[1]).split(","))
	DirAccess.make_dir_recursive_absolute(out)
	Game.new_game("Sprout", "")
	Game.set_flag("arrived_ashford")   # (no opening: the player stands on the green)
	var world := World.new().setup("ashford", "green")
	add_child(world)
	await _frames(30)
	if world.hud != null:
		world.hud.visible = false
	var v: AshfordVillage = AshfordP1.village(world)
	world.busy = true
	var at := world.player.global_position
	for look in looks:
		Game.set_flag("look", look)
		world.swap_player_look()
		await _frames(2)
		var fig = world.player_doll
		if not (fig is Figure3D):
			print("look %s has no model" % look)
			continue
		var f := fig as Figure3D
		f.snap_face(Vector3.BACK)
		var c := AshfordP1.crate(v)
		f.carry(c, AshfordP1.CRATE_HOLD)
		f.reach(c.get_node("L"), c.get_node("R"), 0.0)
		await _frames(20)
		var sk: Skeleton3D = f._skel
		var report := []
		for side in [["Left", "L"], ["Right", "R"]]:
			var hand := sk.find_bone(String(side[0]) + "Hand")
			var hp: Vector3 = sk.global_transform * sk.get_bone_global_pose(hand).origin
			var tp: Vector3 = (c.get_node(String(side[1])) as Node3D).global_position
			var d := hp.distance_to(tp)
			# (the bone pose read here is the clip's, before the hand IK: the
			# distance is for the eye, the stills are the check)
			report.append("%s hand %.2f m from its handle before the IK" % [side[0], d])
			for b in [String(side[0]) + "Arm", String(side[0]) + "ForeArm", String(side[0]) + "Hand"]:
				var i := sk.find_bone(b)
				var sc := sk.get_bone_global_pose(i).basis.get_scale()
				var len := sk.get_bone_global_pose(i).origin.distance_to(sk.get_bone_global_pose(sk.get_bone_parent(i)).origin)
				var rest := sk.get_bone_rest(i).origin.length()
				if absf(sc.x - 1.0) > 0.05 or absf(sc.y - 1.0) > 0.05 or absf(sc.z - 1.0) > 0.05 or (rest > 0.01 and absf(len / rest - 1.0) > 0.15):
					problems += 1
					print("PROBLEM: look %s: %s scale %s, %.3f m long (rest %.3f)" % [look, b, sc, len, rest])
		print("look %s: %s" % [look, ", ".join(PackedStringArray(report))])
		var side_cam := at + Vector3(2.6, 1.2, 0.3)
		await world.cine_to(side_cam, at + Vector3(0, 1.0, 0), 0.05)
		await _frames(5)
		await _shot("carry_%s_side" % look)
		await world.cine_to(at + Vector3(0.4, 1.3, 2.8), at + Vector3(0, 1.0, 0), 0.05)
		await _frames(5)
		await _shot("carry_%s_front" % look)
		f.let_go(0.0)
		c.queue_free()
		await _frames(3)
		# the pick-up off the taproom's crate stand, half way and done
		var stand := AshfordP1._crate_stand(v, world, at + Vector3(0, 0, 0.62), 0.0)
		var c2 := AshfordP1.crate(v)
		world.add_child(c2)
		c2.global_position = at + Vector3(0, AshfordP1.CRATE_STAND_H, 0.62)
		c2.rotation.y = 0.3
		await world.cine_to(at + Vector3(2.4, 1.1, 0.9), at + Vector3(0, 0.8, 0.3), 0.05)
		AshfordP1._take_crate(world, c2)
		for t in [[0.75, 1], [0.45, 2], [0.35, 3], [1.0, 4]]:
			await get_tree().create_timer(float(t[0])).timeout
			if int(t[1]) < 4:
				await _shot("pickup_%s_%d" % [look, int(t[1])])
		await _frames(4)
		await _shot("pickup_%s_4" % look)
		# and down on the ground in front of them from a crouch (as at the Lantern)
		var down_at := at + Vector3(0, 0, AshfordP1.CRATE_DOWN)
		f.pose("sit", AshfordP1.CROUCH, 0.55)
		await get_tree().create_timer(0.2).timeout
		c2.reparent(world)
		var tw := create_tween()
		tw.tween_property(c2, "global_position", down_at + Vector3(0, 0.14, 0), 0.5)
		await get_tree().create_timer(0.3).timeout
		await _shot("putdown_%s_1" % look)
		if tw.is_running():
			await tw.finished
		await _shot("putdown_%s_2" % look)
		f.let_go(0.2)
		c2.global_position = down_at
		await get_tree().create_timer(0.3).timeout
		await _shot("putdown_%s_3" % look)
		f.release(0.0)
		world.busy = true
		f.let_go(0.0)
		c2.queue_free()
		stand.queue_free()
		await _frames(3)
	print("CARRY CHECK: %s (%d problems)" % ["PASS" if problems == 0 else "FAIL", problems])
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
