extends Node
## A hand's mark freed while the arm is still coming off it (18 November,
## the body sweep: "corin's left shoulder twisted 165 deg" for a frame after
## his shout: his hands' marks at his mouth were freed in the same breath as
## let_go(), whose 0.3 s hadn't run). Both hands to marks by the mouth, let
## go and the marks freed at once: how far each hand moves in any one frame
## as the arms come down, with the marks kept (Figure3D.keep_gone, as now)
## and without (as before).
##   godot --headless --fixed-fps 12 --path . res://tests/reach_gone_test.tscn

var _fails := 0


func _ready() -> void:
	Game.new_game("Sprout", "")
	Game.set_flag("arrived_ashford")
	var world := World.new().setup("ashford", "green")
	add_child(world)
	for k in 30:
		await get_tree().process_frame
	var me := world.player_doll as Figure3D
	var got := {}
	for keep in [false, true]:
		Figure3D.keep_gone = keep
		Figure3D.reach_ghosts = 0
		var head := me.bone_pos("Head")
		var ahead := me.to_world(Vector3(0, 0, 1)) - me.global_position
		var across := ahead.cross(Vector3.UP).normalized()
		var marks: Array = []
		for sd in [-1.0, 1.0]:
			var hn := Node3D.new()
			world.add_child(hn)
			hn.global_position = head + ahead * 0.13 + across * sd * 0.07 + Vector3(0, -0.1, 0)
			marks.append(hn)
		me.reach(marks[0], marks[1], 0.3)
		await get_tree().create_timer(0.6, false).timeout
		var last := [Vector3.INF, Vector3.INF]
		var jump := [0.0]
		var twist := [0.0]
		var cb := func() -> void:
			var k := 0
			for b in ["LeftHand", "RightHand"]:
				var p: Vector3 = me.to_own(me.bone_pos(b))
				if last[k] != Vector3.INF:
					jump[0] = maxf(jump[0], p.distance_to(last[k]))
				last[k] = p
				k += 1
		me._skel.skeleton_updated.connect(cb)
		await get_tree().process_frame
		me.let_go(0.3)
		for hn: Node in marks:
			hn.queue_free()
		for k in 10:
			await get_tree().process_frame
		me._skel.skeleton_updated.disconnect(cb)
		got[keep] = jump[0]
		print("reach_gone_test: marks %s: a hand moved at most %.0f cm in one frame as the arms came down (%d kept)" % ["kept where they were" if keep else "gone, as before", jump[0] * 100.0, Figure3D.reach_ghosts])
		await get_tree().create_timer(0.5, false).timeout
	# (0.3 s at 12 frames a second: three or four frames to bring a hand down
	# 60 cm; half of it in one frame is a jump)
	if float(got[true]) > 0.3:
		_fails += 1
		print("reach_gone_test: FAIL a hand still jumps %.0f cm in a frame" % (float(got[true]) * 100.0))
	print("REACH GONE: %s" % ("ok" if _fails == 0 else "FAILED"))
	get_tree().quit(1 if _fails > 0 else 0)
