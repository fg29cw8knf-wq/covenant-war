extends Node
## Stills of the 4 November duel changes (Gary: "Battle needs to go a little
## faster and can we make it more cinematic and dramatic") on the 3D field:
##   attack   your Totem's blow and the rival's: the camera pushed in behind
##            the attacker, the whip to the blow, the freeze as it lands, and
##            the camera home afterwards (Engine.time_scale printed with each)
##   ko       a knockout's close-up, at the crystal, the burst (slow motion)
##            and the dust
##   call     a tier-3 call's low hero shot, and an Ascension's
##   summon   a Summon with the black bars up
##   finish   the finishing blow: bars, slow motion, the colour drained
##   pace     how long a banner, a hit and a call take at Normal, printed
##   flat     the same on the flat (2D) field, where only the freeze, the slow
##            motion and the bars apply (stills named flat_...)
##   arena    (5 November) the field at rest, dressed as a stage: both rows
##            full, the shafts of light, the embers, the rim light
## and two flags (5 November):
##   preview  the stage dressed as a Mac or a phone on Full would have it
##            (DuelField3D.preview_level 2: the impact punch shader, which
##            software GL here, Compatibility, would otherwise skip)
##   plain    DuelRules.cinematic off: the field as it is without the touches
## Run all, or name the parts:
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 30 \
##       res://tests/duel_cine_shot.tscn -- <out_dir> [attack] [ko] [call] [summon] [finish] [pace] [arena] [flat] [preview] [plain]
## Nothing is drawn between the stills (as duel_notes_shot), so each is caught
## at its moment on a slow software renderer. The waits are in real seconds.

var out := "user://"
var ds: DuelScreen
var parts: Array = []
var problems: Array = []


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://"
	parts = args.slice(1)
	var flags := ["flat", "preview", "plain"]
	var flat := "flat" in parts
	if not flat and parts.filter(func(p): return not p in flags).is_empty():
		parts += ["attack", "ko", "call", "summon", "finish", "pace", "arena"]   # (flat alone: just the flat field's own)
	if "preview" in parts:
		DuelField3D.preview_level = 2
	if "plain" in parts:
		DuelRules.set_value("cinematic", false)
	get_tree().root.theme = UITheme.make()
	Game.new_game("Sprout", "tidegrove")
	Game.settings["duel_3d"] = not flat
	SummonVideo.set_mode("off")   # (the drawn Summon scene, not Gary's clip: the bars are what's looked at)
	RenderingServer.render_loop_enabled = false
	ds = DuelScreen.new().configure({"decks": ["emberstorm", "tidegrove"], "names": ["You", "Rival"],
		"profiles": [Lore.new_profile("You", "", 4), Lore.new_profile("Rival", "", 4)], "arena": "ashford",
		"ai": [false, false], "seed": 7, "speed": 1.0, "first": 0, "no_arena_events": true, "field3d": not flat})
	add_child(ds)
	var t := 0.0
	while (ds.game == null or ds.game.turn < 1 or ds.mode != "main") and t < 40.0:
		await _wait(0.2)
		t += 0.2
		if ds.banner_waiting:
			ds.tap_banner()
	if flat:
		await _flat()
	if "pace" in parts:
		_pace()
	if "arena" in parts and not flat:
		await _arena()
	if "attack" in parts:
		await _attack(false)
		await _attack(true)
		await _attack_all()
	if "ko" in parts:
		await _ko()
	if "call" in parts:
		await _call()
	if "summon" in parts:
		await _summon()
	if "finish" in parts:
		await _finish()
	if absf(Engine.time_scale - 1.0) > 0.001:
		problems.append("the clock was left at %.2f" % Engine.time_scale)
	RenderingServer.render_loop_enabled = true
	print("CINE SHOT: problems: ", problems if not problems.is_empty() else "none")
	print("CINE SHOT: done")
	get_tree().quit()


var _watch_clock := false
var _slowest := 1.0
var _punch_peak := 0.0   # the hardest the impact punch got while watched (5 November)


func _process(_delta: float) -> void:
	if _watch_clock:
		_slowest = minf(_slowest, Engine.time_scale)
		if ds != null and ds.field != null and ds.field._punch_mat != null:
			_punch_peak = maxf(_punch_peak, float(ds.field._punch_mat.get_shader_parameter("strength")))


## (5 November) The field at rest, dressed as a stage: both rows full, from
## home, twice a moment apart (the embers and the shafts move).
func _arena() -> void:
	await _board(["cinderpup", "ashen_drake", "brookfin"], ["mossling", "elderbark", "pebblit"])
	ds.mode = "main"
	ds._set_hint("")
	await _wait(0.5)
	await _shot("arena_1_stage")
	await _wait(1.5)
	await _shot("arena_2_stage_later")
	var f := ds.field
	if DuelRules.cinematic:
		if not f._dressed:
			problems.append("arena: the stage wasn't dressed")
		if DuelField3D.drama_level() >= 1 and (f._rim == null or f._shafts.size() != DuelField3D.SHAFTS):
			problems.append("arena: no rim light or shafts at level %d" % DuelField3D.drama_level())
		if DuelField3D.drama_level() >= 2 and f._punch_mat == null:
			problems.append("arena: no impact punch material at level 2")
		if DuelField3D.drama_level() < 2 and f._punch_mat != null:
			problems.append("arena: the impact punch material is on below level 2")
	elif f._dressed or f._rim != null or f.material != null:
		problems.append("arena: the stage was dressed with cinematic off")
	print("CINE SHOT: arena: level %d, fx_scale %.2f, dressed %s, rim %s, shafts %d, punch %s" % [DuelField3D.drama_level(),
		DuelField3D.fx_scale(), f._dressed, f._rim != null, f._shafts.size(), f._punch_mat != null])


func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func _shot(name: String) -> void:
	RenderingServer.render_loop_enabled = true
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/cine_%s.png" % [out, name])
	RenderingServer.render_loop_enabled = false
	if ds.field != null:
		print("CINE SHOT: saved %s  (time_scale %.2f, cam %s fov %.0f)" % [name, Engine.time_scale, ds.field.cam_pos, ds.field.cam_fov])
	else:
		print("CINE SHOT: saved %s  (time_scale %.2f)" % [name, Engine.time_scale])


## Stands Totems on the field: [mine x3], [theirs x3] (null for empty).
func _board(mine: Array, theirs: Array) -> Array:
	var g := ds.game
	var made := [[], []]
	var uid := 9500 + randi() % 300 * 3
	for side in 2:
		var ids: Array = mine if side == 0 else theirs
		g.players[side].slots = [null, null, null]
		for i in 3:
			if i < ids.size() and ids[i] != null:
				var tt := g._new_totem(DuelCard.new(uid, String(ids[i]), side), side, i, 0)
				uid += 1
				g.players[side].slots[i] = tt
				made[side].append(tt)
			else:
				made[side].append(null)
	g._changed()
	ds._refresh()
	if ds.field != null:
		ds.field.cam_home(0.1)
	await _wait(1.2)   # (the models load and settle)
	return made


## The flat field: a big blow (the freeze), a knockout (slow motion) and the
## finishing blow (the bars), and nothing of the 3D camera to go wrong.
func _flat() -> void:
	var made: Array = await _board([null, "cinderpup", null], [null, "mossling", null])
	var att: DuelTotem = made[0][1]
	var tg: DuelTotem = made[1][1]
	ds.mode = "busy"
	ds._set_hint("")
	await ds.fx_attack(att, 0, tg)
	_slowest = 1.0
	_watch_clock = true
	ds.fx_totem_hit(tg, 60, {"attacker": att, "element": att.element()})
	await _wait(0.4)
	await _shot("flat_1_hit")
	await _wait(0.8)
	_watch_clock = false
	if _slowest > 0.5:
		problems.append("flat: time didn't stop on a 60 blow on a weakness (slowest %.2f)" % _slowest)
	ds._strike = {}
	tg.damage = tg.max_hp()
	ds.game.players[1].slots[1] = null
	ds.fx_ko(tg)
	await _wait(0.9)
	await _shot("flat_2_ko")
	await _wait(1.8)
	ds.game.players[1].life = 0
	await ds.fx_attack(att, 0, DuelGame.LIFE)
	ds.fx_life_hit(1, 40, {"attacker": att})
	await _wait(0.6)
	await _shot("flat_3_finish")
	if ds._letterbox == null or ds._letterbox.amount < 0.5:
		problems.append("flat finish: the bars didn't come up")
	await _wait(3.0)
	if absf(Engine.time_scale - 1.0) > 0.001:
		problems.append("flat: the clock was left at %.2f" % Engine.time_scale)
	ds.game.players[1].life = 100


## The pace at Normal, in real seconds, for the README's numbers.
func _pace() -> void:
	var sp: float = ds.speed
	var hold: float = ds._read(0.6, "YOUR TURN")
	print("CINE SHOT: pace at Normal (x%.1f): turn banner %.2f s (words fully up %.2f s; was %.2f s), hit beat %.2f s (was %.2f), Life hit beat %.2f s (was %.2f), roll-off %.2f s (was %.2f), draw %.2f s (was %.2f), windup %.2f s (was %.2f), call wait at most %.2f s (was uncapped), rival thinks %.2f s a play (was %.2f) + preview %.2f s (was %.2f), 0 s to end its turn (was %.2f)" % [
		sp, (hold + DuelScreen.BANNER_IN + DuelScreen.BANNER_TAIL) / sp, hold / sp, (hold + 0.45) / sp,
		DuelScreen.HIT_PAUSE / sp, 0.44 / sp, DuelScreen.LIFE_HIT_PAUSE / sp, 0.5 / sp,
		DuelScreen.ROLLOFF_PAUSE / sp, 1.1 / sp, DuelScreen.DRAW_PAUSE / sp, 0.3 / sp,
		DuelScreen.WINDUP_PAUSE / sp, 0.26 / sp, DuelScreen.CALL_WAIT_MAX / sp,
		DuelHuman.Paced.THINK_ACTION / sp, 0.5 / sp, DuelScreen.AI_PREVIEW / sp, 0.35 / sp, 0.5 / sp])


## A blow of 60 on a weakness (fire on Mossling): the push in, the whip, the freeze, home.
func _attack(back: bool) -> void:
	var tag := "rival" if back else "mine"
	var made: Array = await _board([null, "mossling" if back else "cinderpup", null], [null, "cinderpup" if back else "mossling", null])
	var att: DuelTotem = made[1 if back else 0][1]
	var tg: DuelTotem = made[0 if back else 1][1]
	ds.mode = "busy"
	ds._set_hint("")
	var home := ds.field.cam_pos
	await ds.fx_attack(att, 0, tg)
	await _wait(0.1)
	await _shot("attack_%s_1_pushin" % tag)
	if DuelRules.cinematic and ds.field.cam_pos.distance_to(home) < 2.0:
		problems.append("attack %s: the camera didn't push in (moved %.1f m)" % [tag, ds.field.cam_pos.distance_to(home)])
	# (5 November) the attacker gathers its power under the push-in
	var charging: bool = ds._strike.get("charge") is DuelStrikeFX.Charge and is_instance_valid(ds._strike.get("charge"))
	if DuelRules.cinematic and not charging:
		problems.append("attack %s: no charge on the attacker" % tag)
	elif not DuelRules.cinematic and charging:
		problems.append("attack %s: a charge with cinematic off" % tag)
	_slowest = 1.0
	_punch_peak = 0.0
	_watch_clock = true
	ds.fx_totem_hit(tg, 60, {"attacker": att, "element": att.element()})
	await _wait(0.16)
	await _shot("attack_%s_2_whip" % tag)
	await _wait(0.14)
	await _shot("attack_%s_3_land" % tag)
	await _wait(0.1)
	await _shot("attack_%s_4_hitstop" % tag)
	await _wait(0.5)
	_watch_clock = false
	if _slowest > 0.5 and DuelRules.cinematic:
		problems.append("attack %s: time didn't stop on a 60 blow on a weakness (slowest %.2f)" % [tag, _slowest])
	elif _slowest > 0.5:
		print("CINE SHOT: attack %s: the clock ran on (cinematic off)" % tag)
	else:
		print("CINE SHOT: attack %s: the clock stopped at %.2f" % [tag, _slowest])
	if ds.field._punch_mat != null:
		if _punch_peak < 0.5:
			problems.append("attack %s: the picture wasn't punched on a 60 blow (peak %.2f)" % [tag, _punch_peak])
		else:
			print("CINE SHOT: attack %s: the picture was punched to %.2f" % [tag, _punch_peak])
		if float(ds.field._punch_mat.get_shader_parameter("strength")) > 0.01:
			problems.append("attack %s: the punch was left on (%.2f)" % [tag, float(ds.field._punch_mat.get_shader_parameter("strength"))])
	if charging and is_instance_valid(ds._strike.get("charge")) and not (ds._strike.get("charge") as DuelStrikeFX.Charge)._ended:
		problems.append("attack %s: the charge didn't end with the blow" % tag)
	await _shot("attack_%s_5_after" % tag)
	await _wait(0.9)
	await _shot("attack_%s_6_home" % tag)
	if ds.field.cam_pos.distance_to(home) > 0.5:
		problems.append("attack %s: the camera didn't come home (%.1f m off)" % [tag, ds.field.cam_pos.distance_to(home)])
	if absf(Engine.time_scale - 1.0) > 0.001:
		problems.append("attack %s: the clock was left at %.2f" % [tag, Engine.time_scale])
	ds._strike = {}
	await _wait(0.5)


## A blow on every Totem across (the Ashen Drake's Cinder Storm): the push
## in looks across the field, the whip goes to each as it lands.
func _attack_all() -> void:
	var made: Array = await _board([null, "ashen_drake", null], ["mossling", "brookfin", "pebblit"])
	var att: DuelTotem = made[0][1]
	var mi := -1
	for i in 3:
		if String(att.move(i).get("target", "")) == "all_foes":
			mi = i
	if mi < 0:
		problems.append("attack all: the Ashen Drake has no blow on every foe")
		return
	ds.mode = "busy"
	ds._set_hint("")
	await ds.fx_attack(att, mi, DuelGame.NONE)
	await _wait(0.1)
	await _shot("attack_all_1_pushin")
	for k in 3:
		var tg: DuelTotem = made[1][k]
		await ds.fx_totem_hit(tg, 40, {"attacker": att, "element": att.element(), "spill": true})
		await _shot("attack_all_2_hit_%d" % k)
	await _wait(1.2)
	await _shot("attack_all_3_home")
	if ds.field.cam_pos.distance_to(Vector3(0, 9.6, 11.4)) > 0.5:
		problems.append("attack all: the camera didn't come home (%.1f m off)" % ds.field.cam_pos.distance_to(Vector3(0, 9.6, 11.4)))
	ds._strike = {}
	await _wait(0.5)


func _ko() -> void:
	for who in [["cinderpup", 1, "theirs"], ["brookfin", 0, "mine"]]:
		var made: Array = await _board([null, "brookfin" if who[1] == 1 else String(who[0]), null],
			[null, String(who[0]) if who[1] == 1 else "ironhide", null])
		var t: DuelTotem = made[int(who[1])][1]
		t.damage = t.max_hp()
		ds.game.players[int(who[1])].slots[1] = null
		var home := ds.field.cam_pos
		ds.mode = "busy"
		ds._set_hint("")
		ds.fx_ko(t)
		await _wait(0.45)
		await _shot("ko_%s_1_crystal" % who[2])
		if DuelRules.cinematic and ds.field.cam_pos.distance_to(home) < 2.0:
			problems.append("ko %s: no close-up (the camera moved %.1f m)" % [who[2], ds.field.cam_pos.distance_to(home)])
		await _wait(0.3)
		await _shot("ko_%s_2_cracked" % who[2])
		_slowest = 1.0
		_watch_clock = true
		var slowed := false
		for k in 20:
			await _wait(0.03)
			if Engine.time_scale < 0.6:
				slowed = true
				break
		await _shot("ko_%s_3_burst" % who[2])
		await _wait(0.9)
		await _shot("ko_%s_4_dust" % who[2])
		_watch_clock = false
		if not slowed and _slowest > 0.6 and DuelRules.cinematic:
			problems.append("ko %s: no slow motion at the burst (slowest %.2f)" % [who[2], _slowest])
		else:
			print("CINE SHOT: ko %s: the clock slowed to %.2f" % [who[2], _slowest])
		await _wait(1.6)
		await _shot("ko_%s_5_home" % who[2])
		var s = ds.field.slots[int(who[1])][1]
		if s.card_id != "" or s.dying:
			problems.append("ko %s: the slot didn't clear" % who[2])
		if absf(Engine.time_scale - 1.0) > 0.001:
			problems.append("ko %s: the clock was left at %.2f" % [who[2], Engine.time_scale])


func _call() -> void:
	# a tier-3 call on each side (the hero shot), then an Ascension
	for who in [["ashen_drake", 0, "mine"], ["elderbark", 1, "theirs"]]:
		var made: Array = await _board([null, String(who[0]) if who[1] == 0 else "brookfin", null],
			[null, String(who[0]) if who[1] == 1 else "cinderpup", null])
		var t: DuelTotem = made[int(who[1])][1]
		ds.fx_call(t)
		await _wait(0.42)
		await _shot("call_%s_1_lands" % who[2])
		await _wait(0.35)
		await _shot("call_%s_2_rising" % who[2])
		await _wait(1.2)
		await _shot("call_%s_3_home" % who[2])
	var made2: Array = await _board([null, "blazehound", null], [null, "mossling", null])
	ds.fx_ascend(made2[0][1])
	await _wait(0.4)
	await _shot("ascend_1_rising")
	await _wait(0.6)
	await _shot("ascend_2_top")
	await _wait(1.4)


func _summon() -> void:
	await _board([null, "cinderpup", null], [null, "brookfin", null])
	ds.fx_summon(0, DuelCard.new(9980, "pyraxis", 0))
	await _wait(0.5)
	await _shot("summon_1_bars")
	if DuelRules.cinematic and (ds._letterbox == null or ds._letterbox.amount < 0.9):
		problems.append("summon: the bars didn't come up")
	await _wait(3.2)
	await _shot("summon_2_descends")
	await _wait(5.0)
	await _shot("summon_3_after")
	if ds._letterbox != null and ds._letterbox.amount > 0.05:
		problems.append("summon: the bars stayed up")


func _finish() -> void:
	var made: Array = await _board([null, "cinderpup", null], [null, "brookfin", null])
	var att: DuelTotem = made[0][1]
	ds.game.players[1].life = 0
	ds.mode = "busy"
	await ds.fx_attack(att, 0, DuelGame.LIFE)
	ds.fx_life_hit(1, 40, {"attacker": att})
	await _wait(0.6)
	await _shot("finish_1_slow")
	if Engine.time_scale > 0.9:
		problems.append("finish: no slow motion")
	if DuelRules.cinematic and (ds._letterbox == null or ds._letterbox.amount < 0.5):
		problems.append("finish: the bars didn't come up")
	await _wait(1.2)
	await _shot("finish_2_lands")
	await _wait(2.0)
	await _shot("finish_3_after")
	if absf(Engine.time_scale - 1.0) > 0.001:
		problems.append("finish: the clock was left at %.2f" % Engine.time_scale)
	ds.game.players[1].life = 100
