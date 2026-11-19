extends Node
## Mouths moving when someone talks (18 November, Gary's yes). On the green:
## a line in Corin's name moves Corin's mouth while its words come up and
## shuts it when they're up or the line is moved on; a line in brackets
## moves nobody's; the player's own line moves the player's; two farmers
## from one model don't share a mouth; and the hand-opened mouth (the
## porridge) still opens.
##   godot --headless --fixed-fps 30 --path . res://tests/talk_mouth_test.tscn

var _fails := 0


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_fails += 1
		print("talk_mouth_test: FAIL ", what)


func _ready() -> void:
	Game.new_game("Sprout", "")
	Game.set_flag("arrived_ashford")
	var world := World.new().setup("ashford", "green")
	add_child(world)
	for k in 40:
		await get_tree().process_frame
	var who := ""
	var fig: Figure3D = null
	for n in world.npcs:
		if n.doll is Figure3D and (n.doll as Figure3D).has_mouth():
			who = String(n.def.get("name", ""))
			fig = n.doll as Figure3D
			break
	_expect(fig != null, "nobody on the green has a mouth to move")
	if fig == null:
		get_tree().quit(1)
		return
	var most := [0.0]
	var watch := func() -> void:
		most[0] = maxf(most[0], fig.jaw_now())
	# 1. their line
	var done := [false]
	var say := func(nm: String, text: String) -> void:
		await world.hud.dialogue.say(nm, null, text)
		done[0] = true
	say.call(who + " (quietly)", "It was the wind. Everyone saw the wind. I'd have had it, any other year.")
	var t := 0.0
	while t < 1.2:
		await get_tree().process_frame
		t += 1.0 / 30.0
		watch.call()
	_expect(most[0] > 0.2, "%s's mouth didn't move as their line came up (most %.2f open)" % [who, most[0]])
	_expect(world.spoke_last == who, "the world moved \"%s\"'s mouth for %s's line" % [world.spoke_last, who])
	_expect((world.player_doll as Figure3D).jaw_now() <= 0.001, "the player's mouth moved for %s's line" % who)
	print("talk_mouth_test: %s's mouth opened to %.2f while the line came up" % [who, most[0]])
	world.hud.dialogue._advance.emit()
	world.hud.dialogue._advance.emit()
	for k in 30:
		await get_tree().process_frame
	_expect(done[0], "the line wasn't moved on")
	_expect(fig.jaw_now() <= 0.01, "their mouth is still open (%.2f) a second after the line was moved on" % fig.jaw_now())
	# 2. a line in brackets: nobody's
	most[0] = 0.0
	done[0] = false
	say.call(who, "(He gives you a knowing smile.)")
	for k in 20:
		await get_tree().process_frame
		watch.call()
	_expect(most[0] <= 0.01, "a line in brackets moved a mouth (%.2f)" % most[0])
	world.hud.dialogue._advance.emit()
	world.hud.dialogue._advance.emit()
	for k in 10:
		await get_tree().process_frame
	# 3. the player's own
	var me := world.player_doll as Figure3D
	var mine := 0.0
	say.call(Game.player_name, "I saw the wind too. It wasn't the wind.")
	for k in 30:
		await get_tree().process_frame
		mine = maxf(mine, me.jaw_now())
	_expect(mine > 0.2, "the player's mouth didn't move for their own line (%.2f)" % mine)
	world.hud.dialogue._advance.emit()
	world.hud.dialogue._advance.emit()
	for k in 30:
		await get_tree().process_frame
	_expect(me.jaw_now() <= 0.01, "the player's mouth is still open")
	# 4. two from one model: one mouth each
	var a: Figure3D = Figure3D.new().setup("farmer") as Figure3D
	var b: Figure3D = Figure3D.new().setup("farmer") as Figure3D
	world.add_child(a)
	world.add_child(b)
	a.global_position = world.player.global_position + Vector3(2, 0, 2)
	b.global_position = world.player.global_position + Vector3(3, 0, 2)
	for k in 5:
		await get_tree().process_frame
	a.jaw(0.8)
	b.jaw(0.0)
	for k in 5:
		await get_tree().process_frame
	var am := (a._jaw_mats[0][1] as ShaderMaterial) if not a._jaw_mats.is_empty() else null
	var bm := (b._jaw_mats[0][1] as ShaderMaterial) if not b._jaw_mats.is_empty() else null
	_expect(am != null and bm != null and am != bm, "two farmers share one material")
	if am != null and bm != null:
		_expect(float(am.get_shader_parameter("jaw_open")) > 0.7 and float(bm.get_shader_parameter("jaw_open")) < 0.01, "one farmer's open mouth opened the other's")
	# 5. a smile is the shader's too
	fig.smile(1.0)
	for k in 4:
		await get_tree().process_frame
	_expect(fig.smile_now() > 0.99 and float((fig._jaw_mats[0][1] as ShaderMaterial).get_shader_parameter("smile")) > 0.99, "a smile didn't reach the shader")
	fig.smile(0.0)
	# 6. (18 November, Gary's yes: mouths in time with the voices) a line with
	# its recording: the jaw follows how loud it is, open on the words, shut
	# between them, shut at its end. A made-up recording: a second, two
	# words with a gap. Waited on by the clock, as the sound plays.
	var text := "Two words."
	var stem := VoiceLines.line_id(text)
	var env: Array = []
	for i in 60:
		env.append(90 if (i >= 6 and i < 20) or (i >= 34 and i < 48) else 0)
	VoiceLines.stub[stem] = 1.0
	VoiceLines.stub_env[stem] = env
	var fid := ""
	for n in world.npcs:
		if n.doll == fig:
			fid = String(n.def.get("id", ""))
	var said := [false]
	var go := func() -> void:
		await Cine.say(world, fid, text)
		said[0] = true
	go.call()
	var seen := []
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 1300:
		await get_tree().process_frame
		OS.delay_msec(12)
		seen.append([(Time.get_ticks_msec() - t0) / 1000.0, fig.jaw_now()])
	var in_word := 0.0
	var in_gap := 1.0
	var after := 1.0
	for sv: Array in seen:
		var tt: float = sv[0]
		if tt > 0.17 and tt < 0.3:
			in_word = maxf(in_word, float(sv[1]))
		if tt > 0.47 and tt < 0.53:
			in_gap = minf(in_gap, float(sv[1]))
		if tt > 1.15:
			after = minf(after, float(sv[1]))
	print("talk_mouth_test: a voiced line: open %.2f on its first word, %.2f in the gap, %.2f after it" % [in_word, in_gap, after])
	_expect(fid != "", "no id for the speaker")
	_expect(in_word > 0.5, "the mouth didn't open on the recording's word (%.2f)" % in_word)
	_expect(in_gap < 0.3, "the mouth didn't close between the recording's words (%.2f)" % in_gap)
	_expect(after < 0.05, "the mouth is still open after the recording (%.2f)" % after)
	Cine.overlay(world)._next.emit()
	VoiceLines.stub.erase(stem)
	VoiceLines.stub_env.erase(stem)
	# 7. Bram in the snow: his coat's wind shader moves his jaw too (his
	# mouth isn't given the people's shader over it, which would lose the
	# wind and the snow)
	var ws := WhiteSky.new()
	ws.warm_sigils = false
	add_child(ws)
	for k in 8:
		await get_tree().process_frame
	var bf := ws._bram as Figure3D
	_expect(bf != null and bf.has_mouth(), "Bram in the snow has no mouth to move")
	if bf != null and bf.has_mouth():
		bf.talk_mouth(true, 2.0)
		var wm := 0.0
		for k in 30:
			await get_tree().process_frame
			wm = maxf(wm, bf.jaw_now())
		var mat: ShaderMaterial = (bf._jaw_mats[0][1] as ShaderMaterial) if not bf._jaw_mats.is_empty() else null
		_expect(mat != null and mat == ws._weather, "Bram's moving mouth isn't on his coat's wind shader")
		_expect(wm > 0.2, "Bram's mouth didn't move in the snow (%.2f)" % wm)
		print("talk_mouth_test: Bram in the snow: his mouth to %.2f, on the wind shader %s" % [wm, str(mat == ws._weather)])
	ws.queue_free()
	print("TALK MOUTH: %s" % ("ok" if _fails == 0 else "%d FAILED" % _fails))
	get_tree().quit(1 if _fails > 0 else 0)
