extends SceneTree
# Builds the practice room and saves it as room.tscn.
func _initialize() -> void:
	var root := Node3D.new(); root.name = "Room"
	var lm := LightmapGI.new(); lm.name = "LightmapGI"; lm.quality = LightmapGI.BAKE_QUALITY_MEDIUM
	root.add_child(lm); lm.owner = root
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.8, 0.8, 0.8)
	var red := StandardMaterial3D.new(); red.albedo_color = Color(0.9, 0.15, 0.1)
	for spec in [[Vector3(0, 0, 0), Vector3(8, 0.2, 8), mat], [Vector3(-4, 2, 0), Vector3(0.2, 4, 8), red], [Vector3(4, 2, 0), Vector3(0.2, 4, 8), mat], [Vector3(0, 2, -4), Vector3(8, 4, 0.2), mat], [Vector3(0, 1, 0), Vector3(1.5, 2, 1.5), mat]]:
		var bm := BoxMesh.new(); bm.size = spec[1]; bm.add_uv2 = true; bm.material = spec[2]
		var mi := MeshInstance3D.new(); mi.mesh = bm; mi.position = spec[0]; mi.gi_mode = GeometryInstance3D.GI_MODE_STATIC
		root.add_child(mi); mi.owner = root
	var l := OmniLight3D.new(); l.position = Vector3(-2.5, 2.2, 1.0); l.omni_range = 10; l.light_energy = 2; l.light_bake_mode = Light3D.BAKE_DYNAMIC; l.shadow_enabled = true
	root.add_child(l); l.owner = root
	var ps := PackedScene.new(); ps.pack(root)
	print(ResourceSaver.save(ps, "res://room.tscn"))
	quit()
