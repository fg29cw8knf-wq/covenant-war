extends SceneTree
## Prints how Godot has built a model's scene (nodes, transforms, each
## mesh's own bounds, the skeleton's root rest): for seeing why a model is
## measured somewhere other than where it's drawn (8 November: Tripo3D's
## node_0 / Armature turns above the skeleton, folded in by
## tools/glb_flatten_rig.py).
##   godot --headless --script res://tests/tree_peek.gd -- creatures/scrivener characters/kaethis
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	for which in args:
		var scene := load("res://assets/models/%s.glb" % which) as PackedScene
		var inst := scene.instantiate() as Node3D
		print("== ", which)
		_walk(inst, 0)
		inst.free()
	quit()
func _walk(n: Node, d: int) -> void:
	var s := "  ".repeat(d) + n.name + " (" + n.get_class() + ")"
	if n is Node3D:
		var t: Transform3D = (n as Node3D).transform
		if not t.is_equal_approx(Transform3D.IDENTITY):
			s += " T=" + str(t).replace("\n", " ")
	if n is MeshInstance3D:
		s += " aabb=" + str((n as MeshInstance3D).get_aabb()) + " skin=" + str((n as MeshInstance3D).skin != null) + " skel=" + str((n as MeshInstance3D).skeleton)
	if n is Skeleton3D:
		var sk := n as Skeleton3D
		s += " bones=%d root_rest=%s" % [sk.get_bone_count(), str(sk.get_bone_global_rest(0))]
	print(s)
	for c in n.get_children():
		_walk(c, d + 1)
