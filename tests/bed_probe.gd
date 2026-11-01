extends Node
## Numbers for the attic rise (AshfordP1._attic): every tenth of a second
## from the fade-up, where the sleeper's hips, hands and feet are against the
## bed (x along it, head to the west; z across it, the open side at +0.5;
## y off the attic floor), what the figure is playing, and whether a hand is
## reaching. For tuning the rise without stills.
##   godot --headless res://tests/bed_probe.tscn -- [from=5.5] [to=11.0]

var from := 5.5
var to := 11.0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for a in args:
		var s := String(a)
		if s.begins_with("from="):
			from = float(s.substr(5))
		elif s.begins_with("to="):
			to = float(s.substr(3))
	Game.new_game("Sprout", "")
	Game.settings["first_steps"] = 0
	var world := World.new().setup("ashford", "green")
	add_child(world)
	var v: AshfordVillage = AshfordP1.village(world)
	var ov := Cine.overlay(world)
	var t := 0.0
	var a := InnRooms.attic(v)
	var bed: Vector3 = a.bed - Vector3(0, InnRooms.BED_TOP, 0)   # the bed's base, its middle
	print("BED PROBE: bed base at %s, mattress top %.2f, lie_top %.2f, edge_top %.2f, edge_at %s, bed_side %s" % [
		bed, float(a.bed_top), float(a.lie_top), float(a.edge_top), (a.edge_at as Vector3) - bed, (a.bed_side as Vector3) - bed])
	while t < to:
		await get_tree().create_timer(0.1).timeout
		t += 0.1
		if ov._waiting:
			ov._next.emit()
		if t < from:
			continue
		var pf = world.player_doll
		if not (pf is Figure3D):
			continue
		var f := pf as Figure3D
		var hips := f.bone_pos("Hips") - bed
		var lf := f.bone_pos("LeftFoot") - bed
		var rf := f.bone_pos("RightFoot") - bed
		var lh := f.bone_pos("LeftHand") - bed
		var rh := f.bone_pos("RightHand") - bed
		var head := f.bone_pos("Head") - bed
		var body := world.player.global_position - bed
		print("t %4.1f %-22s body(%5.2f %5.2f %5.2f) hips(%5.2f %5.2f %5.2f) head(%5.2f %5.2f %5.2f) lfoot(%5.2f %5.2f %5.2f) rfoot(%5.2f %5.2f %5.2f) lhand(%5.2f %5.2f %5.2f) rhand(%5.2f %5.2f %5.2f) reach %s%s" % [
			t, f._clip, body.x, body.y, body.z, hips.x, hips.y, hips.z, head.x, head.y, head.z, lf.x, lf.y, lf.z, rf.x, rf.y, rf.z,
			lh.x, lh.y, lh.z, rh.x, rh.y, rh.z, "L" if f.reaching("left") else "-", "R" if f.reaching("right") else "-"])
	print("BED PROBE: done")
	get_tree().quit()
