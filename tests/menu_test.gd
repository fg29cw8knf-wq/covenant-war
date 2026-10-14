extends Node
## Screenshots of the pause menu (every tab), a card's detail, a deck edit,
## the opening notice and an advert placeholder. Run with a real renderer:
##   xvfb-run -a -s "-screen 0 2560x1600x24" godot --rendering-driver opengl3 \
##       res://tests/menu_test.tscn -- <out_dir> [WxH]
## Ends with "MENU TEST: ok" when every step worked.

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
	# a player just past the Prologue: Bram's deck, Dask's cards, a few choices made
	Game.new_game("Ash", "emberstorm")
	for f in ["ash_marked", "ash_tam", "ash_tilly", "ash_nell", "ash_won_lantern", "bram_deck", "beat_hunter",
			"met_bram", "met_corin", "met_tam", "met_tilly", "met_nell", "arrived_solhaven", "beat_wren"]:
		Game.flags[f] = true
	Game.flags["solmaris_favour"] = "defiant"
	for id in DuelCards.card_list("dask_hounds"):
		Game.v2.collection[id] = int(Game.v2.collection.get(id, 0)) + 1
		Game.v2.codex[id] = "seen"
	Game.v2.rank = 3
	Game.v2.points = 2
	Game.v2.xp = 25
	Game.v2.pool = 9
	Game.v2.attune["cinderpup"] = 4
	Game.give_item("hearth_charm")
	Game.equip("charm", "hearth_charm")
	var world := World.new().setup("solhaven", "gate")
	add_child(world)
	await _frames(40)
	var menu: PauseMenu = world.hud._menu
	world.hud.open_menu("hero")
	for t in PauseMenu.TABS:
		menu.show_tab(t[0])
		await _frames(12)
		await _shot(t[0])
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
	notice.queue_free()
	Ads._show("interstitial")
	await get_tree().create_timer(1.0).timeout
	await _shot("advert")
	print("MENU TEST: %s" % ("ok" if problems.is_empty() else "PROBLEMS " + str(problems)))
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/menu_%s.png" % [out_dir, name])
