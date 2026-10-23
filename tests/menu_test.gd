extends Node
## Screenshots of the pause menu (every tab), a card's detail, a deck edit,
## the opening notice and an advert placeholder; first, a new game in Ashford
## (no Deck or Codex yet), Bram's Spark deck and a Codex of just the cards
## found. Run with a real renderer:
##   xvfb-run -a -s "-screen 0 2560x1600x24" godot --rendering-driver opengl3 \
##       res://tests/menu_test.tscn -- <out_dir> [WxH]
## Ends with "MENU TEST: ok" when every step worked.

const SPARK := ["brookfin", "bulwark", "essence_flask", "healing_draught", "essence_flask", "healing_draught",
	"bulwark", "essence_flask", "healing_draught", "essence_flask", "bulwark", "travellers_pack"]

var out_dir := "user://"
var size := Vector2i(1600, 900)
var problems := []


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	if args.size() > 1:
		var p: PackedStringArray = args[1].split("x")
		size = Vector2i(int(p[0]), int(p[1]))
	get_window().size = size
	get_viewport().scaling_3d_scale = 0.5   # the world behind the menu at half resolution (software GL is slow)
	Game.new_game("Ash", "")
	Game.flags["arrived_solhaven"] = true   # no arrival scene behind the menu
	var world := World.new().setup("solhaven", "gate")
	add_child(world)
	await _frames(40)
	var menu: PauseMenu = world.hud._menu
	await _new_player(world, menu)
	# a player just past the Prologue: Bram's deck, Dask's cards, a few choices made
	Game.new_game("Ash", "emberstorm")
	for f in ["ash_marked", "ash_tam", "ash_tilly", "ash_nell", "ash_won_lantern", "bram_deck", "beat_hunter",
			"met_bram", "met_corin", "met_tam", "met_tilly", "met_nell", "arrived_solhaven", "beat_wren"]:
		Game.flags[f] = true
	Game.flags["solmaris_favour"] = "defiant"
	for id in DuelCards.card_list("dask_hounds"):
		Game.v2.collection[id] = int(Game.v2.collection.get(id, 0)) + 1
		Game.v2.codex[id] = "seen"
	Game.v2.codex["brookfin"] = "seen"   # seen in the Lantern Duel, not owned
	Game.v2.rank = 3
	Game.v2.points = 2
	Game.v2.xp = 25
	Game.v2.pool = 9
	Game.v2.attune["cinderpup"] = 4
	Game.give_item("hearth_charm")
	Game.equip("charm", "hearth_charm")
	# Bram's lessons so far (the How to Duel page) and two conditions met (the Codex)
	Game.learn("The Lantern Duel:1", "The Lantern Duel", "Bram", "Right. Those cards are Sigils. The gods' magic is always leaking into the world, a drop at a time, and where it lands it sets hard. Like frost on a window.")
	Game.learn("The Lantern Duel:2", "The Lantern Duel", "Bram", "A duel's how sensible folk settle things. Your Totems do the fighting. Bring his Life down to nothing and you've won.")
	Game.learn("fate", "Fate", "Bram", "That's Fate. Some moves roll the die: roll high, hit hard; roll low, nothing.")
	Game.learn("wards:2", "Wards", "Bram", "Some of those cards are Wards. You set one face down for next to nothing, and it waits.")
	Game.learn("elements:1", "The elements", "Bram", "Second: the elements. Twelve of them, and every one hurts something and fears something. Here's the lot.")
	Game.learn("status:burn", "Conditions", "Bram", "His Cinderpup is Burned now. Takes 10 damage at its owner's Dawn. Two turns, then it's gone.")
	Game.meet_condition("burn")
	Game.meet_condition("poison")
	Game.meet_condition("shielded")
	world.hud.open_menu("hero")
	for k in PauseMenu.LOCKED_TABS:
		if not menu._tab_btns[k].visible:
			problems.append("%s tab hidden with Bram's deck" % k)
	for t in PauseMenu.TABS:
		menu.show_tab(t[0])
		await _frames(12)
		await _shot(t[0])
	# Morrowen's Ledger: its People page too
	Ledger.section = "people"
	menu.show_tab("ledger")
	await _frames(12)
	await _shot("ledger_people")
	Ledger.section = "accounts"
	# the Codex's Conditions page
	menu.show_tab("codex")
	await _frames(6)
	var cgrid: Codex.Grid = menu._content.get_child(0)
	cgrid.filter = "conditions"
	cgrid.rebuild()
	await _frames(12)
	await _shot("codex_conditions")
	# a card's detail, with its Ascension progress
	menu.show_tab("codex")
	await _frames(6)
	menu._open_card("cinderpup")
	await _frames(10)
	await _shot("detail_cinderpup")
	menu._overlay.closed.emit()
	await _frames(4)
	menu._open_card("brookfin")
	await _frames(10)
	await _shot("detail_unowned")
	menu._overlay.closed.emit()
	await _frames(4)
	# take a card out: the deck isn't ready, and Resume asks first
	menu._deck_work.erase("cinderpup")
	menu.show_tab("deck")
	await _frames(10)
	await _shot("deck_short")
	menu.request_close()
	await _frames(10)
	await _shot("deck_confirm")
	if menu._overlay == null:
		problems.append("no confirm box for an unfinished deck")
	else:
		menu._overlay.queue_free()
		menu._overlay = null
	# put it back: Resume closes and the deck is unchanged
	menu._deck_work.append("cinderpup")
	menu.request_close()
	await _frames(4)
	if menu.visible:
		problems.append("menu stayed open with a legal deck")
	# the standing toast
	Game.shift_standing("corin", 2, "Test nudge.")
	await get_tree().create_timer(0.6).timeout
	await _shot("standing_toast")
	if Standing.value("tilly") != 2 or Standing.value("solmaris") != -2 or Standing.value("corin") != 3:
		problems.append("standing values wrong: tilly %d solmaris %d corin %d" % [Standing.value("tilly"), Standing.value("solmaris"), Standing.value("corin")])
	if int(Game.profile.attributes.resolve) != int(Game.profile.base.resolve) + 2:
		problems.append("the charm's +1 Resolve isn't counted")
	# the opening notice and an advert placeholder
	var notice := NoticeScreen.new()
	add_child(notice)
	await _frames(90)
	await _shot("notice")
	if is_instance_valid(notice):
		notice._finish()   # the second page
		await _frames(45)
		await _shot("notice_2")
	if is_instance_valid(notice):   # it may have closed itself already on a slow machine
		notice.queue_free()
	Ads._show("interstitial")
	await get_tree().create_timer(1.0).timeout
	await _shot("advert")
	print("MENU TEST: %s" % ("ok" if problems.is_empty() else "PROBLEMS " + str(problems)))
	get_tree().quit()


## A new game in Ashford: no Deck or Codex; then Bram's Spark deck (shown,
## not editable) and a Codex of only the cards found.
func _new_player(world: World, menu: PauseMenu) -> void:
	Game.area = "ashford"
	if not Game.v2.deck.is_empty() or not Game.v2.collection.is_empty() or not Game.v2.codex.is_empty():
		problems.append("a new game has cards")
	world.hud.open_menu("hero")
	await _frames(12)
	await _shot("locked_hero")
	for k in PauseMenu.LOCKED_TABS:
		if menu._tab_btns[k].visible:
			problems.append("%s tab shows before it's unlocked" % k)
	menu.show_tab("codex")
	if menu.tab != "hero":
		problems.append("a locked tab opened")
	menu.show_tab("howto")
	await _frames(8)
	await _shot("locked_howto")
	menu.request_close()
	# Bram hands over the Spark deck
	Game.give_first_deck(SPARK)
	Game.unlock("deck")
	Game.unlock("codex")
	await get_tree().create_timer(0.8).timeout
	await _shot("unlock_toast")
	world.hud.open_menu("deck")
	await _frames(12)
	await _shot("spark_deck")
	var words := _texts(menu._content)
	if menu.tab != "deck" or not words.contains("12 CARDS"):
		problems.append("no Spark deck page (%s)" % words.left(80))
	if words.contains("Not ready"):
		problems.append("the Spark deck says it isn't ready")
	menu._open_card("brookfin")
	await _frames(10)
	await _shot("spark_detail")
	if _texts(menu._overlay).contains("Add to deck"):
		problems.append("the Spark deck can be edited")
	menu.close_card()
	await _frames(4)
	menu.show_tab("codex")
	await _frames(12)
	await _shot("spark_codex")
	var grid: Codex.Grid = menu._page_grid()
	if grid._grid.get_child_count() != 5 or not _texts(grid).contains("Cards found: 5"):
		problems.append("the Codex shows %d cards, not the 5 found" % grid._grid.get_child_count())
	for f in ["ward", "summon", "conditions"]:
		if grid._filter_btns[f].visible:
			problems.append("the empty %s filter shows" % f)
	# after the Lantern Duel: Corin's cards seen, not owned
	Game.v2.codex["cinderpup"] = "seen"
	Game.v2.codex["firebrand"] = "seen"
	menu.show_tab("codex")
	await _frames(12)
	await _shot("found_codex")
	grid = menu._page_grid()
	if grid._grid.get_child_count() != 7 or not _texts(grid).contains("Cards found: 7 (5 yours)"):
		problems.append("the Codex should show 7 found, 5 yours: %s" % _texts(grid).left(120))
	menu.request_close()
	await _frames(4)
	Game.area = "solhaven"


## Every bit of text under a node, for checking what a page says.
func _texts(n: Node) -> String:
	var out := ""
	if n is Label or n is Button:
		out += n.text + "\n"
	elif n is RichTextLabel:
		out += n.get_parsed_text() + "\n"
	for c in n.get_children():
		if not c.is_queued_for_deletion():
			out += _texts(c)
	return out


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/menu_%s.png" % [out_dir, name])
