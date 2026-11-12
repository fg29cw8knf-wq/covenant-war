extends SceneTree
## Writes the picture of the cracks under a hurt Totem (DuelCracks.PICTURE)
## from DuelCracks.make_image(), so the game loads it rather than drawing it
## pixel by pixel the first time a Totem is hurt. Run again after changing
## how the cracks are drawn:
##   godot --headless --path . --script res://tools/make_base_cracks.gd


func _init() -> void:
	var t0 := Time.get_ticks_msec()
	var img: Image = DuelCracks.make_image()
	var path := ProjectSettings.globalize_path(DuelCracks.PICTURE)
	img.save_png(path)
	print("base cracks: %s (%d ms)" % [path, Time.get_ticks_msec() - t0])
	quit()
