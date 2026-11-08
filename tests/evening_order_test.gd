extends Node
## Corin's evening can't be missed (8 November, Gary: "You can miss talk with
## Corin by talking to Bram first in the evening. I don't want that to be
## possible: if you talk to Bram first have him say Corin was looking for you
## over by the mill"). Headless, on the green after the sunset:
##   1. the evening's words put Corin first and the arrow points down the
##      lane to him;
##   2. Bram talked to before Corin: his lines send the player to the mill,
##      "It's nearly midnight." isn't offered and midnight doesn't start;
##      talked to again, the short reminder, and still no midnight;
##   3. once Corin's been seen (corin_pond), Bram's hub offers "It's nearly
##      midnight." and it starts midnight.
## Every line said is printed.
##
##   godot --headless --fixed-fps 30 --path . res://tests/evening_order_test.tscn
## Ends with "EVENING ORDER: ok" or the problems.

var world: World
var problems: Array = []
var said: Array = []
var offered: Array = []
var want := ""       # the answer to pick when it's offered ("" the first)
var _last := ""


func _ready() -> void:
	Game.new_game("Sprout", "")
	Game.set_flag("arrived_ashford")
	for f in ["ash_started", "p1_crate_down", "corin_met", "first_deck", "ash_won_lantern", "ash_tam", "ash_tilly", "ash_nell",
			"tam_letter_seen", "ash_evening", "tilly_thanks", "has_lantern_moth"]:
		Game.set_flag(f)
	Game.settings["first_steps"] = 2
	world = World.new().setup("ashford", "green")
	add_child(world)
	await _frames(30)
	AshfordP1.dress(world)
	AshfordDay.stage(world)
	await _frames(5)
	# 1. the words and the arrow
	var obj := String(Game.flag("objective", ""))
	_expect(obj == AshfordDay.EVENING_CORIN, "the evening's objective isn't Corin first: %s" % obj)
	_expect(obj.begins_with("Enjoy the festival. Corin's gone off"), "the objective doesn't open with Corin")
	AshfordDay.show_way(world)
	var way_label := _way_label()
	print("  objective: ", obj.replace("\n", " / "))
	print("  arrow: ", way_label)
	_expect(way_label.contains("Corin"), "the arrow doesn't point to Corin (%s)" % way_label)
	# 2. Bram first
	var bram = world._npc_by_id("bram")
	world.busy = false
	await _talk(bram)
	_expect(not Game.flag("ash_lantern_duel"), "talking to Bram before Corin started midnight")
	_expect(Game.flag("bram_sent_corin"), "Bram didn't send the player to Corin")
	_expect(not offered.has("It's nearly midnight."), "\"It's nearly midnight.\" was offered before Corin")
	_expect(said.any(func(s: String) -> bool: return s.contains("Corin came looking for you")), "Bram didn't say Corin was looking for them")
	_expect(said.any(func(s: String) -> bool: return s.contains("by the mill")), "Bram didn't say where Corin is")
	_expect(String(Game.flag("objective", "")) == AshfordDay.EVENING_CORIN, "the objective after Bram isn't Corin first")
	said.clear()
	offered.clear()
	await _talk(bram)
	_expect(not Game.flag("ash_lantern_duel"), "talking to Bram again before Corin started midnight")
	_expect(said.any(func(s: String) -> bool: return s.contains("still down at the mill race")), "no reminder from Bram the second time")
	_expect(not said.any(func(s: String) -> bool: return s.contains("Corin came looking for you")), "Bram's first lines again the second time")
	# 3. after Corin
	Game.set_flag("corin_pond")
	AshfordDay.stage(world)
	_expect(String(Game.flag("objective", "")) == AshfordDay.EVENING, "after Corin the objective isn't Bram's")
	AshfordDay.show_way(world)
	print("  after Corin, arrow: ", _way_label())
	said.clear()
	offered.clear()
	want = "It's nearly midnight."
	world.busy = false
	var go := func() -> void: await world._talk(bram)
	go.call()
	var t := 0.0
	while t < 60.0 and not Game.flag("ash_lantern_duel"):
		await get_tree().process_frame
		t += get_process_delta_time()
	_expect(offered.has("It's nearly midnight."), "\"It's nearly midnight.\" not offered after Corin")
	_expect(Game.flag("ash_lantern_duel"), "\"It's nearly midnight.\" didn't start midnight after Corin")
	print("EVENING ORDER: ", "ok" if problems.is_empty() else "%d problems: %s" % [problems.size(), "; ".join(problems)])
	get_tree().quit(0 if problems.is_empty() else 1)


func _way_label() -> String:
	var wy = world.hud.way
	if wy == null or wy.target == Vector3.INF:
		return "(none)"
	return String(wy.label)


func _talk(n) -> void:
	await world._talk(n)
	await _frames(3)


func _process(_d: float) -> void:
	if world == null or world.hud == null:
		return
	var dlg := world.hud.dialogue
	if dlg._choices.visible:
		var opts: Array = []
		for b in dlg._choices.get_children():
			if b is Button:
				opts.append(String((b as Button).text))
		if opts.size() > 0 and opts != offered.slice(offered.size() - opts.size()):
			for o in opts:
				offered.append(o)
			print("    [", " | ".join(opts), "]")
		var k := opts.find(want) if want != "" else -1
		# the wanted answer, else the leave line (the last), so a hub ends
		dlg._chosen.emit(k if k >= 0 else opts.size() - 1)
	elif dlg._waiting:
		if dlg._typing:
			dlg._tap()
		var t := String(dlg._text.text)
		if t != _last:
			_last = t
			said.append(t)
			print("    ", (dlg._name.text + ": ") if dlg._name.text != "" else "", t.left(120))
		dlg._advance.emit()


func _expect(ok: bool, what: String) -> void:
	if not ok:
		problems.append(what)
		print("  PROBLEM: ", what)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
