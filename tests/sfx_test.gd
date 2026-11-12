extends Node
## The game's sounds (12 November): every Totem has a voice for each moment
## (its own recording, or its kind's stand-in) and the file loads; each
## Summon has a voice of its own; a Hound that falls whines; a small one
## cries higher than a big one of its kind; and every button clicks, unless
## its own press already played a sound, or it's marked "quiet"; and a card
## opened in the Codex turns over with a sound, a creature of yours heard.
## Run: godot --headless --path . res://tests/sfx_test.tscn [-- list]
## Ends "SFX: ok" or the problems.


func _ready() -> void:
	var show := "list" in OS.get_cmdline_user_args()
	var bad := []
	var kinds := {}
	for id: String in DuelCards.CARDS:
		var c: Dictionary = DuelCards.CARDS[id]
		var kind := String(c.get("kind", ""))
		if kind != "totem" and kind != "summon":
			continue
		var line := "%-18s" % id
		for when: String in Sfx.CRY_WHEN:
			var r := Sfx.cry_of(id, when)
			var snd := String(r[0])
			if kind == "totem":
				if snd == "":
					bad.append("%s has no voice for '%s'" % [id, when])
				elif Sfx.get_stream(snd) == null:
					bad.append("%s: %s doesn't load" % [id, snd])
				elif float(r[1]) < 0.4 or float(r[1]) > 2.2:
					bad.append("%s: pitch %.2f for '%s'" % [id, float(r[1]), when])
			elif when == "call" and snd != "cry_" + id:
				bad.append("the Summon %s isn't heard as it lands by its own voice (cry_%s): '%s'" % [id, id, snd])
			elif snd != "" and Sfx.get_stream(snd) == null:
				bad.append("%s: %s doesn't load" % [id, snd])
			line += "  %s %s x%.2f %+.0f dB" % [when, snd, float(r[1]), float(r[2])]
		kinds[Sfx.voice_kind(id)] = int(kinds.get(Sfx.voice_kind(id), 0)) + 1
		if show:
			print(line)
	if show:
		print("kinds: ", kinds)
	for k: String in kinds:
		if k != "" and not Sfx.has_file("cry_" + k):
			bad.append("no file for the kind '%s' (assets/sfx/cry_%s.wav: tools/make_cries.py)" % [k, k])
	if String(Sfx.cry_of("blazehound", "ko")[0]) != "hound_whine":
		bad.append("a Hound that falls doesn't whine: %s" % [Sfx.cry_of("blazehound", "ko")])
	if Sfx.size_pitch("cinderpup") <= Sfx.size_pitch("infernal_warg"):
		bad.append("a Cinderpup doesn't cry higher than a Warg")

	# --- the buttons
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(Sfx._shared) or not Sfx._shared.is_inside_tree():
		bad.append("the shared player isn't in the tree")
	var plain := Button.new()
	add_child(plain)
	var own := Button.new()
	add_child(own)
	var mine := Sfx.new()
	add_child(mine)
	own.pressed.connect(func() -> void: mine.play("ui_select"))
	var quiet := Button.new()
	quiet.set_meta("quiet", true)
	add_child(quiet)
	await get_tree().create_timer(0.2).timeout
	var was := Sfx.clicks
	plain.pressed.emit()
	await get_tree().create_timer(0.2).timeout
	if Sfx.clicks != was + 1:
		bad.append("a plain button didn't click (%d)" % (Sfx.clicks - was))
	own.pressed.emit()
	await get_tree().create_timer(0.2).timeout
	if Sfx.clicks != was + 1:
		bad.append("a button with its own sound clicked as well")
	quiet.pressed.emit()
	await get_tree().create_timer(0.2).timeout
	if Sfx.clicks != was + 1:
		bad.append("a quiet button clicked")
	# (taken out of the tree and put back: one click still, not two)
	remove_child(plain)
	add_child(plain)
	plain.pressed.emit()
	await get_tree().create_timer(0.2).timeout
	if Sfx.clicks != was + 2:
		bad.append("a button put back in the tree clicked %d times" % (Sfx.clicks - was - 1))
	# --- a card opened in the Codex: the card turns, and a creature that's
	# yours is heard, again at a tap on its picture
	Game.new_game("Sprout", "emberstorm")
	var mine_id := ""
	for cid: String in DuelCards.CARDS:
		if Codex.owned(cid) > 0 and String(Sfx.cry_of(cid, "call")[0]) != "":
			mine_id = cid
			break
	if mine_id == "":
		bad.append("no creature owned to open in the Codex")
	else:
		Sfx.listen = true
		Sfx.heard.clear()
		var d := Codex.Detail.new()
		d.id = mine_id
		add_child(d)
		await get_tree().create_timer(0.6).timeout
		var names: Array = Sfx.heard.map(func(h): return String(h[1]))
		if not names.has("card_flip"):
			bad.append("opening a card in the Codex made no sound")
		var voice := String(Sfx.cry_of(mine_id, "call")[0])
		if not names.has(voice):
			bad.append("%s wasn't heard as its card opened (%s)" % [mine_id, names])
		Sfx.heard.clear()
		var tap := InputEventMouseButton.new()
		tap.button_index = MOUSE_BUTTON_LEFT
		tap.pressed = true
		d._art.gui_input.emit(tap)
		await get_tree().create_timer(0.2).timeout
		if not Sfx.heard.map(func(h): return String(h[1])).has(voice):
			bad.append("a tap on %s's picture didn't play its voice" % mine_id)
		if show:
			print("codex: opened %s, heard %s" % [mine_id, names])
		d.queue_free()
	for b in bad:
		print("  problem: ", b)
	print("SFX: ok" if bad.is_empty() else "SFX: %d problem(s)" % bad.size())
	get_tree().quit(0 if bad.is_empty() else 1)
