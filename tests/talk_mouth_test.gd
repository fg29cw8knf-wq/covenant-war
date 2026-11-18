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
	print("TALK MOUTH: %s" % ("ok" if _fails == 0 else "%d FAILED" % _fails))
	get_tree().quit(1 if _fails > 0 else 0)
