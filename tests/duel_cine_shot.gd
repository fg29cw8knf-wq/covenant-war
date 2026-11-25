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
##   staged   (25 November) an attack in three shots (DuelScreen.staged_strikes,
##            Gary's yes to it "in every duel"): the close-up as it gathers,
##            the two of them as it crosses (a strip of stills through the
##            leap or the flight), the cut to the blow as it lands; yours and
##            the rival's, a melee blow and a cast one, a blow on Life, one on
##            every Totem across, with both rows full. `oldstrikes` is the
##            attack as it was. (25 November, later: a small hit has no
##            close-up, its two shots are the two of them and the landing;
##            `oldsmall` gives every attack its close-up, as it was.)
## and two flags (5 November):
##   preview  the stage dressed as a Mac or a phone on Full would have it
##            (DuelField3D.preview_level 2: the impact punch shader, which
##            software GL here, Compatibility, would otherwise skip)
##   plain    DuelRules.cinematic off: the field as it is without the touches
##   nolook   (18 November) the arena's look off (DuelField3D.LOOK); nohaze just its haze
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
	var flags := ["flat", "preview", "plain", "nolook", "nohaze", "oldstrikes", "oldsmall", "trace", "moving"]
	parts = parts.filter(func(p): return not String(p).begins_with("only=")) + parts.filter(func(p): return String(p).begins_with("only="))
	flags += parts.filter(func(p): return String(p).begins_with("only="))
	DuelScreen.staged_strikes = not "oldstrikes" in parts
	DuelScreen.small_two_shots = not "oldsmall" in parts   # (`oldsmall`: every staged attack with its close-up, as it was before 25 November's two shots)
	var flat := "flat" in parts
	if not flat and parts.filter(func(p): return not p in flags).is_empty():
		parts += ["attack", "ko", "call", "summon", "finish", "pace", "arena"]   # (flat alone: just the flat field's own)
	if "preview" in parts:
		DuelField3D.preview_level = 2
	if "plain" in parts:
		DuelRules.set_value("cinematic", false)
	# (18 November) the arena's look off (`nolook`), or just its haze (`nohaze`)
	for k in DuelField3D.LOOK:
		if "nolook" in parts or (k == "haze" and "nohaze" in parts):
			DuelField3D.LOOK[k] = false
	get_tree().root.theme = UITheme.make()
	Game.new_game("Sprout", "tidegrove")
	Game.settings["duel_3d"] = not flat
	Game.settings["duel_camera"] = "locked"   # (8 November: these checks are the locked camera's; tests/duel_camera_shot has the moving one)
	if "moving" in parts:
		# (25 November: `staged` under the moving camera, which is the game's
		# default; "came home" then means back on its path, not at one place)
		Game.settings["duel_camera"] = "moving"
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
	if "crossings" in parts:
		await _crossings()
	if "gathers" in parts:
		await _gathers()
	if "staged" in parts:
		await _staged_all()
	if "attack" in parts:
		# (25 November: these three are the attack as it was, the push in and
		# the whip, which Fastest still has and `oldstrikes` everywhere; `staged`
		# has the three shots)
		var staged_was := DuelScreen.staged_strikes
		DuelScreen.staged_strikes = false
		await _attack(false)
		await _attack(true)
		await _attack_all()
		DuelScreen.staged_strikes = staged_was
		if staged_was:
			await _staged_everyone()
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


## (25 November) The crossing's shot for every pair of slots, both rows
## full and then thinner boards, the striker held in the middle of its leap:
## what DuelField3D.crossing_shot picks, and its mark, printed with each.
func _crossings() -> void:
	var boards := [
		["full", ["brookfin", "cinderpup", "pebblit"], ["ironhide", "mossling", "elderbark"]],
		["big", ["ashen_drake", "elderbark", "ironhide"], ["ashen_drake", "elderbark", "ironhide"]],
		["two", ["cinderpup", null, "brookfin"], [null, "mossling", "pebblit"]],
	]
	var f := ds.field
	for bd in boards:
		var made: Array = await _board(bd[1], bd[2])
		ds.mode = "busy"
		ds._set_hint("")
		for i in 3:
			for j in [0, 1, 2, -1]:
				if made[0][i] == null or (j >= 0 and made[1][j] == null):
					continue
				var a3: Vector3 = f.body_world(0, i)
				var b3: Vector3 = f.body_world(1, j) if j >= 0 else ds._lunge_end(made[0][i], f.life_world(1))
				var c: Array = f.crossing_shot(a3, b3, 44.0, DuelScreen.STAGE_DROP)
				var sl = f.slots[0][i]
				sl.lunge = (b3 - a3) * Vector3(1, 0, 1) * 0.45 + Vector3(0, 0.45, 0)
				f.cam_shot(c[0], c[1], 0.0, float(c[2]), true)
				await _wait(0.1)
				await _shot("cross_%s_%d_to_%s" % [bd[0], i, ("life" if j < 0 else str(j))])
				print("CINE SHOT: crossing %s %d to %d: %s" % [bd[0], i, j, f.cross_pick])
				sl.lunge = Vector3.ZERO
		# and the rival's on your Life
		for j in 3:
			if made[1][j] == null:
				continue
			var a3: Vector3 = f.body_world(1, j)
			var b3: Vector3 = ds._lunge_end(made[1][j], f.life_world(0))
			var c: Array = f.crossing_shot(b3, a3, 44.0, DuelScreen.STAGE_DROP)
			var sl = f.slots[1][j]
			sl.lunge = (b3 - a3) * Vector3(1, 0, 1) * 0.45 + Vector3(0, 0.45, 0)
			f.cam_shot(c[0], c[1], 0.0, float(c[2]), true)
			await _wait(0.1)
			await _shot("cross_%s_rival_%d_to_life" % [bd[0], j])
			print("CINE SHOT: crossing %s rival %d to your Life: %s" % [bd[0], j, f.cross_pick])
			sl.lunge = Vector3.ZERO
	f.cam_home(0.1)
	await _wait(0.3)


## (25 November) Shot one, the close-up as it gathers, for every slot of a
## full board of big Totems and of small ones.
func _gathers() -> void:
	var two := DuelScreen.small_two_shots
	DuelScreen.small_two_shots = false   # (a still of every slot's close-up, small hit or not)
	for bd in [["small", ["brookfin", "cinderpup", "pebblit"], ["ironhide", "mossling", "cinderpup"]],
			["big", ["ashen_drake", "elderbark", "ironhide"], ["ashen_drake", "elderbark", "ironhide"]]]:
		var made: Array = await _board(bd[1], bd[2])
		ds.mode = "busy"
		ds._set_hint("")
		for side in 2:
			for i in 3:
				var att: DuelTotem = made[side][i]
				ds.fx_attack(att, 0, made[1 - side][1])
				await _wait(0.35)
				await _shot("gather_%s_%s_%d" % [bd[0], "mine" if side == 0 else "rival", i])
				await _wait(0.5)
				ds._end_charge()
				ds._strike = {}
				ds.field.cam_home(0.05)
				await _wait(0.3)
	DuelScreen.small_two_shots = two


## (25 November) An attack in three shots, on boards a duel really has.
func _staged_all() -> void:
	# yours, a melee blow that matters (60 on a weakness), the rows full
	# (the last argument, 25 November: 1 if it must have the close-up, 0 if it
	# must be a small hit's two shots; it follows the cards, so a change to a
	# Totem's move or a weakness can move it)
	await _staged("mine_melee", ["brookfin", "cinderpup", "pebblit"], ["ironhide", "mossling", "elderbark"], 0, 1, 1, 60, true, 1)
	# yours on the long slant, a small one, the rows full
	await _staged("mine_slant", ["cinderpup", "brookfin", "pebblit"], ["ironhide", "elderbark", "mossling"], 0, 0, 2, 20)
	# the rival's, a small one, on a slant
	await _staged("rival_melee", ["brookfin", "mossling", "pebblit"], ["cinderpup", "ironhide", "elderbark"], 1, 0, 2, 20, true, 0)
	# a cast blow, yours, from the end of your row to the far end of theirs
	await _staged("mine_cast", ["ashen_drake", "cinderpup", null], ["mossling", null, "pebblit"], 0, 0, 2, 30, false)
	# and the rival's, big ones both rows
	await _staged("rival_cast", ["elderbark", "ironhide", "brookfin"], ["elderbark", "ashen_drake", "ironhide"], 1, 1, 1, 60, false)
	# on Life, nothing of theirs in the way
	await _staged("mine_life", [null, "cinderpup", null], ["mossling", null, null], 0, 1, -1, 30, true, 0)
	# and the rival's on yours, past your row
	await _staged("rival_life", ["brookfin", null, "pebblit"], [null, "cinderpup", null], 1, 1, -1, 30, true, 0)
	await _staged_ko()
	await _staged_flurry()
	await _staged_noshots()


## Is the camera back where it rests: at home (locked), or on its path
## round the Circle and up above it again (moving)?
func _came_home(home: Vector3) -> bool:
	var f := ds.field
	if f.roam_on:
		return f._following and f.cam_pos.y > 4.0
	return f.cam_pos.distance_to(home) <= 0.5


## `only=<tag>` on the command line runs just that staged case.
func _only(tag: String) -> bool:
	for p in parts:
		if String(p).begins_with("only="):
			return String(p).substr(5) == tag
	return true


## A staged blow that breaks its Totem: the leap, the blow, then the crystal's
## close-up, the striker out of its way.
func _staged_ko() -> void:
	if not _only("ko"):
		return
	var made: Array = await _board(["brookfin", "cinderpup", "pebblit"], ["ironhide", "mossling", "elderbark"])
	var att: DuelTotem = made[0][1]
	var tg: DuelTotem = made[1][1]
	var f := ds.field
	var home := f.cam_pos
	ds.mode = "busy"
	ds._set_hint("")
	await ds.fx_attack(att, 0, tg)
	tg.damage = tg.max_hp()
	ds.game.players[1].slots[1] = null
	await ds.fx_totem_hit(tg, 110, {"attacker": att, "element": att.element()})
	await _shot("staged_ko_1_landed")
	ds.fx_ko(tg)
	for k in 6:
		await _wait(0.2)
		await _shot("staged_ko_2_crystal_%d" % k)
		print("CINE SHOT: staged ko: the striker %.2f m from its place" % f.lunge_of(0, 1).length())
	await _wait(2.2)
	await _shot("staged_ko_3_home")
	if not _came_home(home):
		problems.append("staged ko: the camera didn't come home (%.1f m off)" % f.cam_pos.distance_to(home))
	if absf(Engine.time_scale - 1.0) > 0.001:
		problems.append("staged ko: the clock was left at %.2f" % Engine.time_scale)
	ds._strike = {}
	await _wait(0.4)


## (25 November, Gary's yes to a switch for it) "Attack shots" off: the
## camera stays where it is through an attack, yours and the rival's, and the
## striker still leaps across. Then the duel's own Menu, where the switch is.
func _staged_noshots() -> void:
	if not _only("noshots"):
		return
	var was := DuelScreen.attack_shots()
	Game.settings["duel_attack_shots"] = "off"
	if DuelScreen.attack_shots():
		problems.append("noshots: the setting didn't turn the shots off")
	for side in 2:
		# (a melee striker in the middle of its row, whichever side's)
		var rows := [["brookfin", "cinderpup", "pebblit"], ["ironhide", "mossling", "elderbark"]]
		var made: Array = await _board(rows[side], rows[1 - side])
		var att: DuelTotem = made[side][1]
		var tg: DuelTotem = made[1 - side][1]
		var f := ds.field
		var home := f.cam_pos
		ds.mode = "busy"
		ds._set_hint("")
		var crossed := ds.staged_crossings
		ds.fx_attack(att, 0, tg)
		var off := 0.0
		for k in 4:
			await _wait(0.1)
			off = maxf(off, f.cam_pos.distance_to(home))
		ds.fx_totem_hit(tg, 60, {"attacker": att, "element": att.element()})
		var furthest := 0.0
		for k in 12:
			await _wait(0.07)
			off = maxf(off, f.cam_pos.distance_to(home))
			furthest = maxf(furthest, f.lunge_of(side, 1).length())
			if k == 5:
				await _shot("staged_noshots_%s_leap" % ("mine" if side == 0 else "rival"))
		var waited := 0.0
		while (Engine.time_scale < 0.999 or f.lunge_of(side, 1).length() > 0.05) and waited < 8.0:
			await _wait(0.1)
			waited += 0.1
		print("CINE SHOT: staged noshots (%s): the camera moved %.2f m, the striker went %.1f m" % ["mine" if side == 0 else "rival", off, furthest])
		if off > 0.6:
			problems.append("noshots: the camera moved %.1f m with the attack shots off" % off)
		if furthest < 1.5:
			problems.append("noshots: the striker never crossed (%.1f m)" % furthest)
		if ds.staged_crossings != crossed:
			problems.append("noshots: a crossing shot was taken")
		if absf(Engine.time_scale - 1.0) > 0.001:
			problems.append("noshots: the clock was left at %.2f" % Engine.time_scale)
		ds._strike = {}
		await _wait(0.4)
	# the duel's Menu, with the switch in it, opened as its button opens it
	ds.lab_panel.visible = true
	ds._fit_lab()
	await _wait(0.2)
	await _shot("staged_noshots_menu")
	var found := false
	for c in ds.lab_panel.find_children("*", "CheckButton", true, false):
		if String((c as CheckButton).text).begins_with("Attack shots"):
			found = true
			if (c as CheckButton).button_pressed:
				problems.append("noshots: the Menu's switch shows on with the setting off")
			(c as CheckButton).button_pressed = true
			if not DuelScreen.attack_shots():
				problems.append("noshots: the Menu's switch didn't turn the shots back on")
	if not found:
		problems.append("noshots: no Attack shots switch in the duel's Menu")
	var screen_h: float = ds.stage.size.y
	var bottom: float = ds.lab_panel.position.y + ds.lab_panel.size.y
	var content: float = ds._lab_box.get_combined_minimum_size().y + DuelScreen.LAB_PAD
	print("CINE SHOT: the duel's Menu: %d px of things in it, its bottom at %d of %d" % [int(content), int(bottom), int(screen_h)])
	if bottom > screen_h + 1.0:
		problems.append("noshots: the duel's Menu runs off the bottom of the stage (%d of %d)" % [int(bottom), int(screen_h)])
	var last: Control = null
	for c in ds.lab_panel.find_children("*", "Button", true, false):
		if String((c as Button).text) == "Leave duel":
			last = c
	if last == null:
		problems.append("noshots: no Leave duel button in the Menu")
	elif last.get_global_rect().end.y > ds.stage.get_global_rect().end.y + 1.0:
		problems.append("noshots: Leave duel is below the bottom of the screen (an ordinary duel's Menu should fit without scrolling)")
	if ds.lab_panel.get_index() != ds.stage.get_child_count() - 1:
		problems.append("noshots: the Menu isn't in front of the hand")
	ds.lab_panel.visible = false
	Game.settings["duel_attack_shots"] = "on" if was else "off"
	await _wait(0.3)


## Two of the rival's attacks one after the other, as its turn has them: the
## second's close-up cut to from the first's blow, the camera not gone home
## between.
func _staged_flurry() -> void:
	if not _only("flurry"):
		return
	var made: Array = await _board(["brookfin", "mossling", "pebblit"], ["cinderpup", "ashen_drake", null])
	var f := ds.field
	var home := f.cam_pos
	ds.mode = "busy"
	ds._set_hint("")
	var k := 0
	for pair in [[made[1][0], made[0][0]], [made[1][1], made[0][1]]]:
		var att: DuelTotem = pair[0]
		var tg: DuelTotem = pair[1]
		await ds.fx_attack(att, 0, tg)
		await _shot("staged_flurry_%d_1_gathered" % k)
		await ds.fx_totem_hit(tg, 30, {"attacker": att, "element": att.element()})
		await _shot("staged_flurry_%d_2_landed" % k)
		ds._strike = {}
		await _wait(0.15)   # (the rival thinks DuelHuman.Paced.THINK_ACTION between its plays)
		if k == 0 and f.cam_pos.distance_to(home) < 1.0:
			problems.append("staged flurry: the camera went home between the two attacks")
		k += 1
	await _wait(1.8)
	await _shot("staged_flurry_3_home")
	if not _came_home(home):
		problems.append("staged flurry: the camera didn't come home (%.1f m off)" % f.cam_pos.distance_to(home))
	await _wait(0.4)


## One attack: `side`'s Totem in `slot` on the other side's in `at` (-1:
## their Life) for `amount`, stills through all three shots. `melee` false
## looks for a move of its that isn't a melee blow.
func _staged(tag: String, mine: Array, theirs: Array, side: int, slot: int, at: int, amount: int, melee := true, want_close := -1) -> void:
	if not _only(tag):
		return
	var made: Array = await _board(mine, theirs)
	var att: DuelTotem = made[side][slot]
	var tg = made[1 - side][at] if at >= 0 else DuelGame.LIFE
	var mi := 0
	for i in 3:
		if att.move(i).is_empty():
			continue
		var st := DuelFXStyle.attack_style(att.id(), att.element(), att.move(i), i)
		if (String(st.kind) == "melee") == melee and String(att.move(i).get("target", "")) != "all_foes":
			mi = i
			break
	ds.mode = "busy"
	ds._set_hint("")
	var f := ds.field
	var home := f.cam_pos
	var was := ds.staged_attacks
	var crossed0 := ds.staged_crossings
	var closeups := ds.staged_closeups
	ds.fx_attack(att, mi, tg)
	await _wait(0.3)
	# (25 November: a small hit has no close-up; its first shot is the two of them)
	var close: bool = ds.staged_closeups == closeups + 1
	await _shot("staged_%s_1_%s" % [tag, "gather" if close else "two_shot"])
	print("CINE SHOT: staged %s: %s" % [tag, "three shots (the close-up first)" if close else "two shots (no close-up)"])
	if DuelScreen.staged_strikes and want_close >= 0 and close != (want_close == 1):
		problems.append("staged %s: %s, and it should have been %s" % [tag, "the close-up" if close else "no close-up", "the close-up" if want_close == 1 else "two shots"])
	if DuelScreen.staged_strikes and not close and ds.staged_crossings != crossed0 + 1:
		problems.append("staged %s: a small hit, and the two of them weren't cut to as it began" % tag)
	var gsl = f.slots[side][slot]
	var gv = ds.views[side][slot]
	print("CINE SHOT: staged %s: gather: flash %.2f %s, glow_boost %.2f, fx_tint %s %.2f, rim %s %s, highlight %s" % [tag, gv.flash, gv.flash_color,
		gsl.glow_boost, gsl.fx_tint, gsl.fx_tint_k, DuelField3D.has_rim(gsl.card_id), DuelField3D.rim_col(gsl.card_id), gv.highlight])
	print("CINE SHOT: staged %s: %s (%s), gather shot %.1f m from home, move %d %s" % [tag, att.card_name(),
		"melee" if ds._strike.get("melee", false) else "cast", f.cam_pos.distance_to(home), mi, String(att.move(mi).get("name", ""))])
	if DuelScreen.staged_strikes and ds.staged_attacks != was + 1:
		problems.append("staged %s: the attack wasn't staged" % tag)
	await _wait(0.45 if close else 0.03)   # (a small hit's gather is 0.3 s: its blow goes about now)
	var crossed := ds.staged_crossings
	_slowest = 1.0
	_watch_clock = true
	if tg is DuelTotem:
		ds.fx_totem_hit(tg, amount, {"attacker": att, "element": att.element()})
	else:
		ds.fx_life_hit(1 - side, amount, {"attacker": att})
	var furthest := 0.0
	for k in 9:
		await _wait(0.085)
		furthest = maxf(furthest, f.lunge_of(side, slot).length())
		await _shot("staged_%s_2_cross_%d" % [tag, k])
	await _wait(0.5)
	_watch_clock = false
	await _shot("staged_%s_3_after" % tag)
	print("CINE SHOT: staged %s: the striker went %.1f m from its place; the clock's slowest %.2f; crossing %s" % [tag, furthest, _slowest, f.cross_pick])
	if DuelScreen.staged_strikes:
		if ds.staged_crossings != crossed0 + 1:
			problems.append("staged %s: %d crossing shots, not one" % [tag, ds.staged_crossings - crossed0])
		if not close and ds.staged_crossings != crossed:
			problems.append("staged %s: a small hit's two-shot was cut to again as the blow went" % tag)
		if ds._strike.get("melee", false) and furthest < 1.5:
			problems.append("staged %s: the striker never crossed (%.1f m)" % [tag, furthest])
	await _wait(1.6)
	await _shot("staged_%s_4_home" % tag)
	if not _came_home(home):
		problems.append("staged %s: the camera didn't come home (%.1f m off)" % [tag, f.cam_pos.distance_to(home)])
	if f.lunge_of(side, slot).length() > 0.05:
		problems.append("staged %s: the striker didn't come back to its place (%.2f m off)" % [tag, f.lunge_of(side, slot).length()])
	if absf(Engine.time_scale - 1.0) > 0.001:
		problems.append("staged %s: the clock was left at %.2f" % [tag, Engine.time_scale])
	ds._strike = {}
	await _wait(0.4)


## (25 November) A blow on every Totem across, staged: the close-up as it
## gathers, then one shot from behind it with all of them in it, each blow
## going out to its own, the camera not cut to them one by one.
func _staged_everyone() -> void:
	var made: Array = await _board([null, "ashen_drake", null], ["mossling", "brookfin", "pebblit"])
	var att: DuelTotem = made[0][1]
	var mi := -1
	for i in 3:
		if String(att.move(i).get("target", "")) == "all_foes":
			mi = i
	if mi < 0:
		return
	ds.mode = "busy"
	ds._set_hint("")
	var f := ds.field
	var home := f.cam_pos
	await ds.fx_attack(att, mi, DuelGame.NONE)
	await _shot("staged_all_1_gathered")
	var shot_at := Vector3.ZERO
	for k in 3:
		var tg: DuelTotem = made[1][k]
		# (one after the other with nothing between, as the duel sends them)
		await ds.fx_totem_hit(tg, 40, {"attacker": att, "element": att.element(), "spill": true})
		await _shot("staged_all_2_blow_%d_landed" % k)
		if k == 0:
			shot_at = f.cam_pos
		elif f.cam_pos.distance_to(shot_at) > 1.5:
			problems.append("staged all: the camera left its shot between the blows (%.1f m by blow %d)" % [f.cam_pos.distance_to(shot_at), k])
		if f.cam_pos.distance_to(home) < 2.0:
			problems.append("staged all: the camera was home at blow %d" % k)
	await _wait(1.6)
	await _shot("staged_all_3_home")
	if not _came_home(home):
		problems.append("staged all: the camera didn't come home (%.1f m off)" % f.cam_pos.distance_to(home))
	if absf(Engine.time_scale - 1.0) > 0.001:
		problems.append("staged all: the clock was left at %.2f" % Engine.time_scale)
	ds._strike = {}
	await _wait(0.4)


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
	# (25 November: how long the clock is held slow before it starts back up,
	# in the duel's own frames: the striker's leap is staged now, and the slow
	# clock makes it a long one. The way back up is timed by the watch, which
	# this test's frames outrun, so it's waited for and not measured.)
	var held := 1.8
	while Engine.time_scale < DuelScreen.FINISH_SLOW + 0.005 and held < 12.0:
		await _wait(0.1)
		held += 0.1
		if "trace" in parts:
			print("  finish trace %.1f s: clock %.2f, striker %.2f m out" % [held, Engine.time_scale, ds.field.lunge_of(0, 1).length() if ds.field != null else 0.0])
	print("CINE SHOT: finish: the clock was held slow for %.1f s" % held)
	if held > 4.5:
		problems.append("finish: the clock was held slow for %.1f s" % held)
	var back := 0.0
	while Engine.time_scale < 0.999 and back < 20.0:
		await _wait(0.1)
		back += 0.1
	await _wait(0.6)
	await _shot("finish_3_after")
	if absf(Engine.time_scale - 1.0) > 0.001:
		problems.append("finish: the clock was left at %.2f" % Engine.time_scale)
	ds.game.players[1].life = 100
