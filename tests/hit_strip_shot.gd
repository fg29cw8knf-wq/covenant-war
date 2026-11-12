extends Node
## What a blow did, in numbers (11 November, Gary: "With things like Bulwark
## it's hard to know how much health is left or how much damage is being done
## during the attacks"). On the 3D field, with the moving camera and an
## attack's close shot: a blow of 70 on a Totem behind a Bulwark's 50 (the
## shield takes 50, 20 goes through), a blow the shield stops whole, a plain
## blow, and one that breaks a Totem; a still of each as it lands and as its
## Health drains, and of the name plate with a shield on it at rest. Checks
## the strip is up, inside the screen, says the right numbers, and goes.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 30 \
##       res://tests/hit_strip_shot.tscn -- <out_dir> [locked]

var out := "user://"
var ds: DuelScreen
var problems: Array = []


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://"
	DirAccess.make_dir_recursive_absolute(out)
	get_tree().root.theme = UITheme.make()
	Game.new_game("Sprout", "tidegrove")
	Game.settings["duel_3d"] = true
	Game.settings["duel_camera"] = "locked" if "locked" in args else "moving"
	SummonVideo.set_mode("off")
	RenderingServer.render_loop_enabled = false
	ds = DuelScreen.new().configure({"decks": ["emberstorm", "tidegrove"], "names": ["You", "Rival"],
		"profiles": [Lore.new_profile("You", "", 4), Lore.new_profile("Rival", "", 4)], "arena": "ashford",
		"ai": [false, false], "seed": 7, "speed": 1.0, "first": 0, "no_arena_events": true, "field3d": true})
	add_child(ds)
	var t := 0.0
	while (ds.game == null or ds.game.turn < 1 or ds.mode != "main") and t < 40.0:
		await _wait(0.2)
		t += 0.2
		if ds.banner_waiting:
			ds.tap_banner()
	var g := ds.game
	var made := [[], []]
	var uid := 9500
	var ids := [["cinderpup", "ashen_drake", "brookfin"], ["mossling", "elderbark", "pebblit"]]
	for side in 2:
		g.players[side].slots = [null, null, null]
		for i in 3:
			var tt := g._new_totem(DuelCard.new(uid, String(ids[side][i]), side), side, i, 0)
			uid += 1
			g.players[side].slots[i] = tt
			made[side].append(tt)
	g._changed()
	ds._refresh()
	ds.mode = "busy"
	if ds.hint != null:
		ds.hint.visible = false
	await _wait(1.5)
	var att: DuelTotem = made[0][1]
	var tg: DuelTotem = made[1][1]
	# a Bulwark on it: the plate at rest
	tg.shield = 50
	ds._refresh()
	await _wait(0.6)
	await _shot("1_shield_on_the_plate")
	# 70 at it: the shield takes 50, 20 goes through
	await ds.fx_attack(att, 0, tg)
	tg.shield = 0
	tg.damage += 20
	ds.fx_totem_hit(tg, 20, {"attacker": att, "element": att.element(), "absorbed": 50})
	await _wait(0.45)
	await _shot("2_shield_breaks_20_through")
	_check(tg, 50, "the shield's blow")
	await _wait(0.6)
	await _shot("3_draining")
	ds._strike = {}
	await _wait(2.6)
	if is_instance_valid(ds._strips.get(tg)):
		problems.append("the strip was still up 3.6 s after the blow")
	# a shield that stops the whole blow
	tg.shield = 30
	ds._refresh()
	await ds.fx_attack(att, 0, tg)
	tg.shield = 10
	ds.fx_totem_hit(tg, 0, {"attacker": att, "element": att.element(), "absorbed": 20})
	await _wait(0.45)
	await _shot("4_blocked_whole")
	_check(tg, 20, "the blocked blow")
	ds._strike = {}
	await _wait(2.6)
	# the rival's blow on yours, plain
	var mine: DuelTotem = made[0][0]
	var foe: DuelTotem = made[1][0]
	await ds.fx_attack(foe, 0, mine)
	mine.damage += 40
	ds.fx_totem_hit(mine, 40, {"attacker": foe, "element": foe.element()})
	await _wait(0.45)
	await _shot("5_yours_hit_40")
	_check(mine, 0, "the blow on yours")
	ds._strike = {}
	await _wait(2.6)
	# and one that breaks it
	await ds.fx_attack(foe, 0, mine)
	var rest := mine.hp_left()
	mine.damage += rest
	ds.fx_totem_hit(mine, rest, {"attacker": foe, "element": foe.element()})
	await _wait(0.45)
	await _shot("6_broken")
	_check(mine, 0, "the breaking blow")
	RenderingServer.render_loop_enabled = true
	print("HIT STRIP: problems: ", problems if not problems.is_empty() else "none")
	print("HIT STRIP: ", "ok" if problems.is_empty() else "FAILED")
	get_tree().quit()


func _check(t: DuelTotem, absorbed: int, what: String) -> void:
	var hs = ds._strips.get(t)
	if hs == null or not is_instance_valid(hs):
		problems.append("%s: no Health strip by the Totem" % what)
		return
	var s := hs as DuelViews.HitStrip
	print("HIT STRIP: %s: %d -> %d of %d, shield took %d (%d left), at %s" % [what, s.before, s.after, s.max_hp, s.absorbed, s.shield_left, s.position])
	if s.after != t.hp_left() or s.max_hp != t.max_hp() or s.absorbed != absorbed or s.shield_left != t.shield:
		problems.append("%s: the strip's numbers are wrong" % what)
	var r := Rect2(s.position, s.size)
	if r.position.x < 0.0 or r.end.x > DuelScreen.DESIGN.x or r.position.y < 0.0 or r.end.y > DuelScreen.DESIGN.y:
		problems.append("%s: the strip is off the screen (%s)" % [what, r])


func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, false).timeout


func _shot(nm: String) -> void:
	RenderingServer.render_loop_enabled = true
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join("strip_%s.png" % nm))
	RenderingServer.render_loop_enabled = false
