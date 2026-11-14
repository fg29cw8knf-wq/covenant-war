extends Node
## "Best picture" (Gfx.Best; 14 November, Gary's yes to "a Best picture
## switch on the Mac: sharper edges and finer shadows, at some cost in
## smoothness"). Checked on a computer: off, a 3D view is left exactly as
## it was made; on, it's drawn with four samples a pixel where it had two,
## its lamps' shadow map doubled, 16x filtering, full-detail models and
## debanding, the game's own window too, and the frame-rate guard stands
## down; a view made with no multisampling keeps none; off again, every view
## is back exactly as it was made and the guard is back. A view made while
## it's on is dressed as it's made (a duel's field, the Night of the White
## Sky). With `-- --phone` (a phone has its own two settings): never on.
##   godot --headless --path . res://tests/best_picture_test.tscn [-- --phone]
## Ends "BEST PICTURE: ok" or the problems.

var problems: Array = []


func _view(msaa: int, lamps: int) -> SubViewport:
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.set("msaa_3d", msaa)
	vp.positional_shadow_atlas_size = lamps
	add_child(vp)
	return vp


func _is(what: String, got: Variant, want: Variant) -> void:
	if got != want:
		problems.append("%s: %s, wanted %s" % [what, str(got), str(want)])


func _ready() -> void:
	var root := get_tree().root
	var root_was := [root.msaa_3d, root.positional_shadow_atlas_size, root.anisotropic_filtering_level, root.mesh_lod_threshold, root.use_debanding]
	Game.settings["smooth_auto"] = true
	Game.settings["best_picture"] = false
	Gfx.setup(get_tree())
	if Gfx.is_phone():
		# a phone: the setting does nothing, whatever it says
		Game.settings["best_picture"] = true
		Gfx.setup(get_tree())
		_is("on a phone, Best.on()", Gfx.Best.on(), false)
		var pv := _view(Viewport.MSAA_2X, 2048)
		Gfx.apply(pv)
		_is("on a phone, a view's lamps' shadow map", pv.positional_shadow_atlas_size, 2048)
		_is("on a phone, a view's models' detail", pv.mesh_lod_threshold, 1.0)
		_end("(phone)")
		return
	# off: a view is left as it was made
	var a := _view(Viewport.MSAA_2X, 2048)
	var a_was := [a.msaa_3d, a.positional_shadow_atlas_size, a.anisotropic_filtering_level, a.mesh_lod_threshold, a.use_debanding]
	Gfx.apply(a)
	_is("off, a view's edges", a.msaa_3d, Viewport.MSAA_2X)
	_is("off, a view's lamps' shadow map", a.positional_shadow_atlas_size, 2048)
	_is("off, the guard", Gfx.Guard.on(), true)
	var plain := _view(Viewport.MSAA_DISABLED, 4096)
	Gfx.apply(plain)
	# on
	Game.settings["best_picture"] = true
	Gfx.setup(get_tree())
	_is("on, Best.on()", Gfx.Best.on(), true)
	_is("on, a view's edges", a.msaa_3d, Viewport.MSAA_4X)
	_is("on, a view's lamps' shadow map", a.positional_shadow_atlas_size, 4096)
	_is("on, a view's filtering", a.anisotropic_filtering_level, Viewport.ANISOTROPY_16X)
	_is("on, a view's models' detail", a.mesh_lod_threshold, 0.0)
	_is("on, a view's debanding", a.use_debanding, true)
	_is("on, the window's edges", root.msaa_3d, Viewport.MSAA_4X if int(root_was[0]) != Viewport.MSAA_DISABLED else Viewport.MSAA_DISABLED)
	_is("on, the window's filtering", root.anisotropic_filtering_level, Viewport.ANISOTROPY_16X)
	_is("on, a view made with no multisampling", plain.msaa_3d, Viewport.MSAA_DISABLED)
	_is("on, that view's lamps' shadow map (never over the most)", plain.positional_shadow_atlas_size, Gfx.Best.LAMP_MAP_MOST)
	_is("on, the guard stands down", Gfx.Guard.on(), false)
	# a view made while it's on (as a duel's field is: its own settings, then Gfx.apply)
	var b := _view(Viewport.MSAA_2X, 2048)
	Gfx.apply(b)
	_is("on, a view made now: its edges", b.msaa_3d, Viewport.MSAA_4X)
	_is("on, a view made now: its lamps' shadow map", b.positional_shadow_atlas_size, 4096)
	# the real ones
	var f := DuelField3D.new()
	_is("on, a duel's field's edges", f.vp.msaa_3d, Viewport.MSAA_4X)
	_is("on, a duel's field's lamps' shadow map", f.vp.positional_shadow_atlas_size, 4096)
	f.free()
	# off again: everything as it was made
	Game.settings["best_picture"] = false
	Gfx.setup(get_tree())
	_is("off again, a view", [a.msaa_3d, a.positional_shadow_atlas_size, a.anisotropic_filtering_level, a.mesh_lod_threshold, a.use_debanding], a_was)
	_is("off again, the view made while it was on", [b.msaa_3d, b.positional_shadow_atlas_size], [Viewport.MSAA_2X, 2048])
	_is("off again, the window", [root.msaa_3d, root.positional_shadow_atlas_size, root.anisotropic_filtering_level, root.mesh_lod_threshold, root.use_debanding], root_was)
	_is("off again, the guard", Gfx.Guard.on(), true)
	_end("")


func _end(tag: String) -> void:
	Game.settings["best_picture"] = false
	if problems.is_empty():
		print("BEST PICTURE%s: ok" % (" " + tag if tag != "" else ""))
	else:
		for p in problems:
			print("BEST PICTURE: FAIL: ", p)
	get_tree().quit(0 if problems.is_empty() else 1)
