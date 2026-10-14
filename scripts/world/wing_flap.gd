class_name WingFlap
extends Node
## Flaps the wings of a model that has no animations of its own (the Lantern
## Moth). Any MeshInstance3D whose name contains "wing" is hung on a hinge at
## the edge nearest the body and swung back and forth around the body's
## upright axis, so the wingtips beat towards the creature's back. Upper and
## lower wings beat slightly out of step, like a real moth's.
##
##   WingFlap.attach(model_root)   # returns the WingFlap, or null if no wings

var beat_hz := 5.5       # wingbeats per second
var amount := 0.95       # radians the tips swing back at the top of the beat
var rest := 0.12         # radians the wings sit back at the bottom of the beat
var _hinges: Array = []  # [pivot Node3D, side (-1 left / +1 right), phase]
var _t := 0.0


static func attach(root: Node3D) -> WingFlap:
	var wings: Array = []
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if String(mi.name).to_lower().contains("wing"):
			wings.append(mi)
	if wings.is_empty():
		return null
	var f := WingFlap.new()
	f.name = "WingFlap"
	root.add_child(f)
	for mi: MeshInstance3D in wings:
		var parent := mi.get_parent() as Node3D
		if parent == null:
			continue
		# the wing's box in its parent's space; the hinge is its inner edge
		var box: AABB = mi.transform * mi.get_aabb()
		var left := box.get_center().x < 0.0
		var hinge := Vector3(box.end.x if left else box.position.x, box.get_center().y, box.get_center().z)
		var pivot := Node3D.new()
		pivot.name = String(mi.name) + "Hinge"
		pivot.position = hinge
		parent.add_child(pivot)
		var xf := mi.transform
		parent.remove_child(mi)
		pivot.add_child(mi)
		mi.transform = Transform3D(xf.basis, xf.origin - hinge)
		var lower := String(mi.name).to_lower().contains("lower")
		f._hinges.append([pivot, -1.0 if left else 1.0, 0.55 if lower else 0.0])
	return f


func _process(delta: float) -> void:
	_t += delta
	for h in _hinges:
		var pivot: Node3D = h[0]
		if not is_instance_valid(pivot):
			continue
		var s := 0.5 + 0.5 * sin((_t * beat_hz - float(h[2]) * 0.15) * TAU)
		# left wing: negative turn sends its tip backwards (-Z); right: positive
		pivot.rotation.y = float(h[1]) * (rest + s * amount)
