extends Node
## Stills of the duel's look pass (18 November, DuelField3D.LOOK): each arena
## with both rows full (a brass Totem, a furred one and a stone one on your
## side; a bark one, a gilded one and a small one across), seen from home
## and close on the brass, the fur and the gold (from in front), with the
## checks that each part is on where it should be and off where it shouldn't.
##   before         every part of the look off: the arena as it was
##   only=a,b       just those parts on (ao bounce haze floor skin lit probe grade)
##   phone          as an iPhone on Smooth builds it (level 1: no bounce, no haze)
##   arenas=a,b     just those arenas (default all six)
##   views=a,b      just those views (home brass fur gold)
## Forward+ through software Vulkan (lavapipe), which the look is for:
##   VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json xvfb-run -a -s "-screen 0 1280x720x24" \
##       godot --rendering-driver vulkan --resolution 960x540 --fixed-fps 30 \
##       res://tests/duel_look_shot.tscn -- <out_dir> [before] [only=...] [phone] [arenas=...] [views=...]
## Stills are <arena>_<view>.png. Several frames are drawn before each, so the
## haze and the bounced light (worked out over frames) have settled.

const ARENAS := ["emberforge", "tidegrove", "veilwild", "ironstone", "solhaven", "ashford"]
const MINE := ["ironhide", "blazehound", "quarry_golem"]
const THEIRS := ["elderbark", "gilded_sentinel", "pebblit"]

var out := "user://"
var ds: DuelScreen
var problems: Array = []
var views := ["home", "brass", "fur", "gold"]


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://"
	var arenas: Array = ARENAS.duplicate()
	DuelField3D.preview_level = 1 if "phone" in args else 2
	for a in args.slice(1):
		if a == "before":
			for k in DuelField3D.LOOK:
				DuelField3D.LOOK[k] = false
		elif a.begins_with("only="):
			var on: PackedStringArray = a.substr(5).split(",")
			for k in DuelField3D.LOOK:
				DuelField3D.LOOK[k] = k in on
		elif a.begins_with("arenas="):
			arenas = Array(a.substr(7).split(","))
		elif a.begins_with("views="):
			views = Array(a.substr(6).split(","))
	print("LOOK SHOT: level %d, look %s" % [DuelField3D.look_level(), DuelField3D.LOOK])
	get_tree().root.theme = UITheme.make()
	Game.new_game("Sprout", "tidegrove")
	Game.settings["duel_3d"] = true
	Game.settings["duel_camera"] = "locked"
	RenderingServer.render_loop_enabled = false
	ds = DuelScreen.new().configure({"decks": ["emberstorm", "tidegrove"], "names": ["You", "Rival"],
		"profiles": [Lore.new_profile("You", "", 4), Lore.new_profile("Rival", "", 4)], "arena": String(arenas[0]),
		"ai": [false, false], "seed": 7, "speed": 1.0, "first": 0, "no_arena_events": true, "field3d": true})
	add_child(ds)
	var t := 0.0
	while (ds.game == null or ds.game.turn < 1 or ds.mode != "main") and t < 40.0:
		await _wait(0.2)
		t += 0.2
		if ds.banner_waiting:
			ds.tap_banner()
	await _board(MINE, THEIRS)
	ds.mode = "main"
	ds._set_hint("")
	_check()
	for arena in arenas:
		var f := ds.field
		if f.arena_name != arena:
			f.setup(arena)
			await _wait(0.3)
		_check_arena(arena)
		if "home" in views:
			f.cam_home(0.01)
			await _shot("%s_home" % arena)
		# close on one Totem, from in front of it (the hero shot's place)
		for v in [["brass", 0, 0], ["fur", 0, 1], ["gold", 1, 1]]:
			if String(v[0]) in views:
				var sh: Array = f.shot_hero(int(v[1]), int(v[2]), 0.75)
				f.cam_shot(sh[0], sh[1], 0.01, DuelField3D.SHOT_FOV_HERO, true)
				await _shot("%s_%s" % [arena, v[0]])
		f.cam_home(0.01)
	print("LOOK SHOT: problems %s" % ("none" if problems.is_empty() else str(problems)))
	get_tree().quit(1 if not problems.is_empty() else 0)


## Each part of the look where it should be, at the level it's built for.
func _check() -> void:
	var f := ds.field
	var lvl := DuelField3D.look_level()
	var env: Environment = f._env
	var want := {
		"ao": DuelField3D.LOOK.ao and lvl >= 1,
		"bounce": DuelField3D.LOOK.bounce and lvl >= 2,
		"haze": DuelField3D.LOOK.haze and lvl >= 2,
		"grade": DuelField3D.LOOK.grade,
	}
	var have := {
		"ao": env.ssao_enabled,
		"bounce": env.ssil_enabled,
		"haze": env.volumetric_fog_enabled,
		"grade": env.adjustment_color_correction != null,
	}
	for k in want:
		if bool(want[k]) != bool(have[k]):
			problems.append("%s is %s, wanted %s" % [k, have[k], want[k]])
	if want.haze and f.sun.light_volumetric_fog_energy > 0.0:
		problems.append("the sun lights the haze")
	# the skin: every Totem's model with its normal map, where it has one
	var skinned := 0
	var models := 0
	for side in 2:
		for i in 3:
			var s: DuelField3D.Slot = f.slots[side][i]
			if s.model == null:
				problems.append("no model in slot %d,%d" % [side, i])
				continue
			models += 1
			var any := false
			for mi in s.model.find_children("*", "MeshInstance3D", true, false):
				var mesh := mi as MeshInstance3D
				for k in mesh.mesh.get_surface_count():
					var m := mesh.get_active_material(k) as BaseMaterial3D
					if m != null and m.normal_enabled:
						any = true
						if m.resource_name.to_lower().contains("eye"):
							problems.append("%s: an eye has the normal map (%s)" % [s.card_id, m.resource_name])
			if any:
				skinned += 1
	var want_lit: bool = DuelField3D.LOOK.lit and lvl >= 1
	for mi in f.slots[0][0].model.find_children("*", "MeshInstance3D", true, false):
		var mesh := mi as MeshInstance3D
		for k in mesh.mesh.get_surface_count():
			var m := mesh.get_active_material(k) as BaseMaterial3D
			if m != null and m.resource_name.to_lower() == "coat_emission":
				var lit: bool = m.emission_energy_multiplier <= DuelField3D.LIT_GLOW + 0.001
				if lit != want_lit:
					problems.append("the Ironhide's coat glows at %.2f (lit wanted %s)" % [m.emission_energy_multiplier, want_lit])
	var want_skin: bool = DuelField3D.LOOK.skin and lvl >= 1
	if want_skin and skinned < models:
		problems.append("only %d of %d Totems have their skin" % [skinned, models])
	if not want_skin and skinned > 0:
		problems.append("%d Totems have their skin with it off" % skinned)
	print("LOOK SHOT: ao %s bounce %s haze %s grade %s skin %d/%d" % [have.ao, have.bounce, have.haze, have.grade, skinned, models])


func _check_arena(arena: String) -> void:
	var f := ds.field
	var lvl := DuelField3D.look_level()
	var floor_on: bool = DuelField3D.LOOK.floor and lvl >= 1
	if f._mat_material.normal_enabled != floor_on:
		problems.append("%s: the floor's maps are %s, wanted %s" % [arena, f._mat_material.normal_enabled, floor_on])
	var probe_on: bool = DuelField3D.LOOK.probe and lvl >= 1
	if (f._probe != null) != probe_on:
		problems.append("%s: the reflection is %s, wanted %s" % [arena, f._probe != null, probe_on])
	if DuelField3D.LOOK.grade and f._grade_now != DuelField3D.ARENA_GRADES.get(arena, []):
		problems.append("%s: the grade isn't the arena's" % arena)


## Stands Totems on the field: [mine x3], [theirs x3].
func _board(mine: Array, theirs: Array) -> void:
	var g := ds.game
	var uid := 9500
	for side in 2:
		var ids: Array = mine if side == 0 else theirs
		g.players[side].slots = [null, null, null]
		for i in 3:
			var tt := g._new_totem(DuelCard.new(uid, String(ids[i]), side), side, i, 0)
			uid += 1
			g.players[side].slots[i] = tt
	g._changed()
	ds._refresh()
	ds.field.cam_home(0.1)
	await _wait(1.5)   # (the models load and settle)


func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


## A still, after a few frames drawn (the haze and the bounce settle over
## frames; the reflection is drawn on the first).
func _shot(name: String) -> void:
	RenderingServer.render_loop_enabled = true
	for i in 6:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
	RenderingServer.render_loop_enabled = false
	print("LOOK SHOT: saved %s" % name)
