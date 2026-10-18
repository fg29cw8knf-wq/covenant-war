extends Node
## Plays Solhaven's five side stories start to finish (Master Script v3, Side
## Quests), each down its branches: every sworn wager on the real duel screen,
## won in one branch and lost in another, the swear screen (Not yet, then
## Swear now), Mr Pell's note, the lashing at full and reduced violence, a
## wager duel the game was closed in the middle of (straight back into it),
## and Morrowen's Ledger afterwards. Checks the story's flags; saves
## screenshots (every line of a story's first branch, the key moments of the
## rest).
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
##       res://tests/side_quests_test.tscn -- <out_dir> [scenario ...]
##   godot --headless res://tests/side_quests_test.tscn -- <out_dir>     # just the checks
## Scenarios: hub mercy_won mercy_lost mercy_swore fen_won fen_lost resume pip_aldric
## pip_lost pip_wren scar_told scar_nothing hale_won hale_lost hale_stood ledger (default: all).

const SIDE := "res://scripts/world/areas/solhaven/solhaven_side.gd"
const ALL := ["hub", "mercy_won", "mercy_lost", "mercy_swore", "fen_won", "fen_lost", "resume", "pip_aldric",
	"pip_lost", "pip_wren", "scar_told", "scar_nothing", "hale_won", "hale_lost", "hale_stood", "ledger"]

var out := "user://"
var world: World
var scenario := ""
var answers: Array = []        # the choices to make, by how their text starts
var swears: Array = []         # "swear" or "not_yet", in turn
var results: Array = []        # the wager duels: true to win, false to lose
var every_line := false
var demo_patter := false
var _driving := false
var fails := 0
var n := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://"
	var which: Array = Array(args.slice(1)) if args.size() > 1 else ALL
	Game.settings["first_steps"] = 2
	Game.settings["duel_3d"] = false
	for s in which:
		scenario = String(s)
		print("SIDE QUESTS: --- %s" % scenario)
		await call("_" + scenario)
		_driving = false
		await _frames(4)
	print("SIDE QUESTS: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	get_tree().quit(0 if fails == 0 else 1)


# ============================================================== the setup ===

## A player in Solhaven just past the gate, with the Prologue behind them.
func _fresh(extra: Dictionary = {}) -> void:
	if world != null and is_instance_valid(world):
		world.queue_free()
		await _frames(3)
	Game.new_game("Rowan", "emberstorm")
	Game.settings["first_steps"] = 2
	for f in ["ash_started", "arrived_ashford", "ash_tam", "tam_told", "ash_nell", "ash_tilly", "has_lantern_moth", "ash_lantern_duel",
			"ash_marked", "first_deck", "corin_letter", "pro_tunnel_done", "arrived_thornwood", "hob_gift", "bram_deck",
			"beat_hunter", "dask_kept_hound", "thornwood_done", "arrived_solhaven", "beat_hale", "met_hale", "met_bram",
			"met_tam", "met_nell", "met_tilly", "met_corin"]:
		Game.flags[f] = true
	for k in extra:
		Game.flags[k] = extra[k]
	Game.area = "solhaven"
	world = World.new().setup("solhaven", "gate")
	world.duel_handler = _duel
	add_child(world)
	await _wait(2.5)
	answers = []
	swears = []
	results = []
	every_line = false
	demo_patter = false
	if not _driving:
		_driving = true
		_drive()


## Walks up to someone in the square and talks to them.
func _talk(id: String) -> void:
	var nn = world._npc_by_id(id)
	_check(nn != null, "%s is in the square" % id)
	if nn == null:
		return
	world.player.global_position = nn.body.global_position * Vector3(1, 0, 1) + Vector3(0.3, 0, 1.6)
	world._focus = world._cam_focus_target()
	await _frames(6)
	await _shot("near_" + id)
	await world._talk(nn)
	await _wait(0.6)
	await _shot("after_" + id)


func _want(flag: String, value) -> void:
	var got = Game.flag(flag, null)
	_check(str(got) == str(value), "%s: %s is %s (got %s)" % [scenario, flag, value, got])


# ============================================================ the stories ===

func _hub() -> void:
	await _fresh({"let_refugees_in": true, "gate_choice": "all", "met_maren": true, "met_pip": true, "met_pip_before": true, "beat_aldric": true, "c6_done": true})
	# Hale's Orders: in a square with a gate warden, only once he's said where Hale is
	var side = load(SIDE)
	if world._npc_by_id("gate_warden") != null:
		_check(world._npc_by_id("barracks") == null, "hub: the barracks wait for the gate warden's word")
		Game.set_flag("side_started_hales_orders")
		await side.event(world, "hales_orders")
	var sq: Dictionary = side.SQ
	var hub: Dictionary = side.HUB
	for look in [[sq.ysa_in + Vector3(5.9, 3.2, 6.6), sq.ysa_in + Vector3(-0.1, 0.8, 0.2), "ysa_inside"],
			[sq.fen_cam, sq.fen_look, "fen_fountain"],
			[hub.sundial + Vector3(-3.6, 3.4, 7.6), hub.sundial + Vector3(0, 0.8, 0), "great_sundial"],
			[hub.barracks + Vector3(7.1, 3.2, 4.0), hub.barracks + Vector3(0.1, 1.6, 0), "barracks_gate"],
			[hub.counting_house + Vector3(-6.0, 3.0, 5.4), hub.counting_house + Vector3(-0.6, 1.0, 0.2), "counting_house"]]:
		world.cine = true
		world.cam.global_position = look[0]
		world.cam.look_at(look[1], Vector3.UP)
		await _frames(8)
		await _shot(look[2])
	world.cine = false
	for id in ["ysa", "fen", "sundial", "barracks", "pip"]:
		_check(world._npc_by_id(id) != null, "hub: %s is there to talk to" % id)
	# the gate shut: Ysa waits at it
	await _fresh({"met_maren": true})
	var gate: Vector3 = side.SQ.ysa_gate
	world.cine = true
	world.cam.global_position = gate + Vector3(4.2, 3.0, -7.0)
	world.cam.look_at(gate + Vector3(0, 1.0, 0), Vector3.UP)
	await _frames(8)
	await _shot("ysa_at_the_gate")
	world.cine = false
	var ysa = world._npc_by_id("ysa")
	_check(ysa != null and (ysa.body as Node3D).global_position.distance_to(gate) < 0.5, "hub: the gate shut, Ysa waits at it")


func _mercy_won() -> void:
	await _fresh({"let_refugees_in": true, "gate_choice": "all"})
	every_line = true
	answers = ["Don't.", "That's buying faith.", "Will you heal a boy?", "Then we settle it"]
	swears = ["swear"]
	results = [true]
	await _talk("ysa")
	_want("side_mercy", "anselm_won")
	_want("ilvane", "full")
	_want("ysa_leaf", "lantern")
	_want("wager_mercy", "won")
	_check(world._npc_by_id("ysa") == null, "mercy: Ysa's story is over and she's gone from the square")


func _mercy_lost() -> void:
	await _fresh()
	answers = ["Don't.", "Will you heal a boy?", "Then we settle it", "Then we settle it"]
	swears = ["not_yet", "swear"]
	results = [false]
	await _talk("ysa")
	_want("side_mercy", "anselm_lost")
	_want("ilvane", "half")
	_want("wager_mercy", "lost")


func _mercy_swore() -> void:
	await _fresh({"let_refugees_in": true, "gate_choice": "all"})
	answers = ["Swear."]
	await _talk("ysa")
	_want("side_mercy", "swore")
	_want("ilvane", "none")


func _fen_won() -> void:
	await _fresh()
	Game.settings["duel_3d"] = true
	every_line = true
	demo_patter = true
	answers = ["Tell them the truth.", "Stop, or I'll stop you."]
	swears = ["swear"]
	results = [true]
	await _talk("fen")
	Game.settings["duel_3d"] = false
	_want("side_fen", "beaten")
	_check(world._npc_by_id("fen") == null, "fen: gone from the fountain once it's settled")


func _fen_lost() -> void:
	await _fresh()
	answers = ["Talk to him first.", "Stop, or I'll stop you."]
	swears = ["not_yet"]
	await _talk("fen")
	_want("side_fen", "pending")
	_check(world._npc_by_id("fen") != null, "fen: after Not yet he waits on the rim")
	await _wait(0.5)
	await _shot("fen_waits_with_a_mark")
	swears = ["swear"]
	results = [false]
	await _talk("fen")
	_want("side_fen", "won")
	_want("wager_fen", "lost")


## The game closed in the middle of Fen's wager: straight back into the duel.
func _resume() -> void:
	await _fresh({"side_fen": "pending", "side_fen_pending": true, "side_duel_on": "fen", "wager_fen": "sworn"})
	results = [true]
	var t := 0.0
	while String(Game.flag("side_fen", "")) == "pending" and t < 90.0:
		await _wait(0.5)
		t += 0.5
	await _wait(1.0)
	_want("side_fen", "beaten")
	_check(not Game.flag("side_duel_on"), "resume: the duel is no longer on")


func _pip_aldric() -> void:
	await _fresh({"met_pip": true, "met_pip_before": true, "beat_wren": true, "met_wren": true, "met_aldric": true})
	every_line = true
	answers = ["Who's the man in grey?", "Duel me for one note.", "Take it to Aldric."]
	swears = ["swear"]
	results = [true]
	await _talk("pip")
	_want("side_pip", "aldric")
	_want("pip_note_read", true)
	# and a place for him, back at the fountain
	answers = ["Aldric's stable needs a boy."]
	await _talk("pip")
	_want("side_pip_place", "aldric")


func _pip_lost() -> void:
	await _fresh({"met_pip": true, "met_pip_before": true})
	answers = ["Duel me for one note."]
	swears = ["swear"]
	results = [false]
	await _talk("pip")
	_want("side_pip", "delivered")
	_want("paid_pip", true)


func _pip_wren() -> void:
	await _fresh({"met_pip": true, "met_pip_before": true, "beat_wren": true, "met_wren": true})
	answers = ["Ask Wren to lift one.", "Keep it."]
	await _talk("pip")
	_want("side_pip", "kept")
	_want("pell_note", true)
	_check(Items.story_items().has("pell_note"), "pip: Mr Pell's note is carried")


func _scar_told() -> void:
	await _fresh({"met_maren": true})
	every_line = true
	answers = ["Somebody recut these lines."]
	await _talk("sundial")
	_want("side_scar", "told")
	_check(Items.story_items().has("maren_pages"), "scar: Maren's forty pages are carried")


func _scar_nothing() -> void:
	await _fresh({"met_maren": true})
	answers = ["I saw nothing.", "Let him."]
	await _talk("sundial")
	_want("side_scar", "nothing")
	_want("corvin_blessed", true)


func _hale_won() -> void:
	await _fresh({"let_refugees_in": true, "gate_choice": "all", "beat_aldric": true, "c6_done": true, "side_started_hales_orders": true})
	every_line = true
	answers = ["I'll duel for his sentence.", "Yes."]
	swears = ["swear"]
	results = [true]
	await _talk("barracks")
	_want("side_hale", "won")


func _hale_lost() -> void:
	await _fresh({"let_refugees_in": true, "gate_choice": "all", "beat_aldric": true, "c6_done": true, "side_started_hales_orders": true})
	Game.settings["violence"] = "full"
	answers = ["I'll duel for his sentence.", "Yes.", "Yes."]
	swears = ["not_yet", "swear"]
	results = [false]
	await _talk("barracks")
	_want("side_hale", "lost")


func _hale_stood() -> void:
	await _fresh({"let_refugees_in": true, "gate_choice": "all", "beat_aldric": true, "c6_done": true, "side_started_hales_orders": true})
	Game.settings["violence"] = "reduced"
	answers = ["Then I'll stand with you."]
	await _talk("barracks")
	Game.settings["violence"] = "full"
	_want("side_hale", "stood")


## Morrowen's Ledger, with the stories settled various ways.
func _ledger() -> void:
	await _fresh({"let_refugees_in": true, "gate_choice": "all", "beat_aldric": true, "c6_done": true, "side_started_hales_orders": true, "sun_court_done": true, "temple_leave": true, "met_aldric": true,
		"met_wren": true, "beat_wren": true, "met_pip": true, "met_pip_before": true, "met_maren": true, "met_hierarch": true,
		"side_mercy": "anselm_won", "ilvane": "full", "side_fen": "truth", "side_pip": "returned", "side_pip_place": "hale",
		"side_scar": "told", "maren_pages": true, "side_hale": "stood", "met_tamsin": true, "met_liora": true})
	Game.shift_standing("ysa", 1, "You found Tobin a healer who asked one word.")
	Game.shift_standing("hale", 2, "You stood where he could see you while he took ten lashes.")
	var texts := ""
	for a in LedgerEntries.accounts():
		texts += String(a.text) + "\n"
	for want in ["came to me", "her lantern was a little brighter", "owe nobody", "gave it back", "forty pages", "where he could see you"]:
		_check(texts.contains(want), "ledger: the accounts say \"%s\"" % want)
	var people := ""
	for p in LedgerEntries.people():
		people += String(p.text) + "\n"
	_check(people.contains("Hale. Opened a gate he was told to keep shut, and paid for it."), "ledger: Hale's line is v3's own")
	for k in ["accounts", "people"]:
		Ledger.section = k
		world.hud.open_menu("ledger")
		await _frames(14)
		await _shot("ledger_" + k)
		var sc := world.hud._menu.find_children("*", "ScrollContainer", true, false)
		if not sc.is_empty():
			(sc[0] as ScrollContainer).scroll_vertical = 100000
			await _frames(6)
			await _shot("ledger_%s_end" % k)
		world.hud.close_menu()
		await _frames(4)
	# at the largest text and buttons size: the Ledger, and the swear screen (Not yet)
	Game.settings["ui_scale"] = 1.3
	Ledger.section = "accounts"
	world.hud.open_menu("ledger")
	await _frames(14)
	await _shot("ledger_accounts_largest")
	world.hud.close_menu()
	await _frames(4)
	swears = ["not_yet"]
	var sworn: bool = await load(SIDE)._swear(world, "mercy")
	_check(not sworn and Game.flag("wager_mercy", "") == "", "swear screen: Not yet backs out, and nothing is sworn")
	Game.settings["ui_scale"] = 1.0
	# early on, in Ashford
	Game.flags = {"arrived_ashford": true, "ash_started": true, "ash_tam": true, "met_bram": true, "met_tam": true}
	Ledger.section = "accounts"
	world.hud.open_menu("ledger")
	await _frames(14)
	await _shot("ledger_ashford_early")
	world.hud.close_menu()


# ============================================================ the driver ===

## Answers the conversation as it goes: lines tapped through once they've
## typed out, choices picked by `answers`, the swear screen by `swears`,
## Mr Pell's note put down.
func _drive() -> void:
	while _driving:
		await get_tree().process_frame
		if world == null or not is_instance_valid(world) or world.hud == null:
			continue
		var sw := world.find_child("SwearScreen", true, false) as SwearScreen
		if sw != null and not sw._done:
			await _wait(1.7)
			_check(sw._armed, "%s: Swear now is armed after a moment" % scenario)
			await _shot("swear_screen")
			var what: String = swears.pop_front() if not swears.is_empty() else "swear"
			if what == "swear":
				sw._swear.pressed.emit()
			else:
				sw._not_yet.pressed.emit()
			await _wait(1.4)
			continue
		var note := world.find_child("NoteView", true, false)
		if note != null and not bool(note.get("_done")):
			await _wait(1.6)
			await _shot("the_note")
			note.call("_close")
			await _wait(0.6)
			continue
		var dlg := world.hud.dialogue
		if dlg.visible and dlg._choices.visible and dlg._choices.get_child_count() > 0:
			await _wait(0.45)
			await _shot("choice")
			dlg._chosen.emit(_pick(dlg))
			await _frames(3)
			continue
		if dlg.visible and dlg._waiting:
			await _wait(0.5)
			if dlg._waiting and not dlg._choices.visible:
				if every_line:
					await _shot("line")
				dlg._advance.emit()
			await _frames(2)


func _pick(dlg: DialogueBox) -> int:
	var want: String = answers.pop_front() if not answers.is_empty() else ""
	var have := []
	for i in dlg._choices.get_child_count():
		var b := dlg._choices.get_child(i) as Button
		have.append(b.text)
		if want != "" and b.text.begins_with(want):
			return i
	_check(want == "", "%s: no answer \"%s\" among %s" % [scenario, want, have])
	return 0


## A wager's duel on the real duel screen, the way Main plays it: up to the
## player's turn, then won or lost on purpose.
func _duel(spec: Dictionary) -> bool:
	var win: bool = results.pop_front() if not results.is_empty() else true
	_check(bool(spec.get("once", false)), "%s: the wager is played once" % scenario)
	_check(not spec.get("story_rules", {}).is_empty() and spec.get("rule", []).size() == 2, "%s: the duel has its rule" % scenario)
	world.visible = false
	world.hud.visible = false
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var ds := DuelScreen.new().configure(spec)
	layer.add_child(ds)
	await _wait(2.6)
	await _shot("duel_rule_banner")
	var t := 0.0
	while t < 90.0 and ds.mode != "main":
		await _wait(0.25)
		t += 0.25
	_check(ds.mode == "main", "%s: the duel reached the player's turn" % scenario)
	_check(ds.game.story_rules.size() == 1, "%s: the engine has the rule" % scenario)
	await _wait(0.4)
	await _shot("duel")
	if demo_patter:
		await _patter(ds)
	ds.game._finish(0 if win else 1, "The duel is decided." if win else "Your Life is empty.")
	ds.human.responded.emit({"type": "end"})
	var got := [""]
	ds.finished.connect(func(r: String) -> void: got[0] = r)
	t = 0.0
	var pressed := false
	while got[0] == "" and t < 40.0:
		await _wait(0.25)
		t += 0.25
		if pressed:
			continue
		var cont: Button = null
		var again := false
		for b in ds.find_children("*", "Button", true, false):
			var bt := b as Button
			if bt.is_visible_in_tree() and bt.text == "Continue":
				cont = bt
			if bt.is_visible_in_tree() and bt.text in ["Try again", "Again"]:
				again = true
		if cont != null:
			await _wait(0.6)
			await _shot("duel_result")
			_check(not again, "%s: no Try again after a sworn wager" % scenario)
			cont.pressed.emit()
			pressed = true
	_check(got[0] == ("won" if win else "lost"), "%s: the duel ended %s (got %s)" % [scenario, "won" if win else "lost", got[0]])
	ds.queue_free()
	layer.queue_free()
	world.visible = true
	world.hud.visible = true
	return got[0] == "won"


## Fen's Patter, shown: two of his Wards go down face up, then he swaps one.
func _patter(ds: DuelScreen) -> void:
	var g := ds.game
	var fen: DuelPlayer = g.players[1]
	var wards := []
	for c in fen.deck + fen.hand:
		if c.is_ward() and wards.size() < 3 and (wards.is_empty() or wards.all(func(x): return x.id != c.id)):
			wards.append(c)
	for c in wards:
		fen.deck.erase(c)
		if not fen.hand.has(c):
			fen.hand.append(c)
	fen.essence = 9
	for c in wards.slice(0, 2):
		await g._act_ward(1, c)
	ds._refresh()
	await _wait(0.8)
	await _shot("patter_face_up")
	await g._rule_patter(fen)
	ds._refresh()
	await _wait(1.2)
	await _shot("patter_swap_bark")
	_check(g.face_up.size() >= 2, "patter: Fen's Wards lie face up")


# ============================================================== helpers ===

func _check(ok: bool, what: String) -> void:
	print("SIDE QUESTS %s: %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		fails += 1


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _frames(k: int) -> void:
	for i in k:
		await get_tree().process_frame


func _shot(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	n += 1
	get_viewport().get_texture().get_image().save_png(out.path_join("%03d_%s_%s.png" % [n, scenario, label]))
