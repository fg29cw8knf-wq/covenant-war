extends Node
## The pack's menu at every text size, and its Options page most of all (the
## Deck and the Codex too, which ran off the right at Larger and Largest).
## The Options page at every screen shape and text size: in two columns
## where there's room, with nothing off the bottom or the side (25 November,
## Gary's yes to "Put the Options page in two columns so nothing needs
## scrolling."), one column that scrolls where there isn't, every row there
## either way. Run with a real renderer, once for each shape:
##   xvfb-run -a -s "-screen 0 2560x1600x24" godot --rendering-driver opengl3 \
##       res://tests/options_page_test.tscn -- <out_dir> [WxH] [phone]
## Ends with "OPTIONS PAGE TEST: ok" when every step worked.

## Words every Options page must have, however it's laid out.
const ROWS := ["Music", "Sound effects", "Background sounds", "Text speed", "Camera zoom", "Battle speed",
	"Duel camera", "Attack shots", "Reading time", "Ask me to respond", "Summon videos", "3D duel field",
	"Show frame rate", "Save game", "Save and quit to title"]

var out_dir := "user://"
var size := Vector2i(1600, 900)
var problems := []
var shots := 0
var once := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	if args.size() > 1:
		var p: PackedStringArray = args[1].split("x")
		size = Vector2i(int(p[0]), int(p[1]))
	get_window().size = size
	get_viewport().scaling_3d_scale = 0.5
	Game.new_game("Ash", "emberstorm")
	Game.flags["arrived_solhaven"] = true
	Game.flags["bram_deck"] = true   # (every tab open)
	for id in DuelCards.card_list("dask_hounds"):   # (a Codex with more in it than the deck)
		Game.v2.collection[id] = int(Game.v2.collection.get(id, 0)) + 1
		Game.v2.codex[id] = "seen"
	var world := World.new().setup("solhaven", "gate")
	add_child(world)
	await _frames(40)
	var menu: PauseMenu = world.hud._menu
	world.hud.open_menu("options")
	await _frames(12)
	for nm in ["Normal", "Larger", "Largest", "Normal"]:
		# picked with the page's own button, as a player picks it: the page
		# must lay itself out again where the number of columns changes
		var picked := false
		for b in _controls(menu._content):
			if b is Button and (b as Button).text == nm and _name_of(b).begins_with("Text"):
				(b as Button).pressed.emit()
				picked = true
				break
		if not picked:
			problems.append("no \"%s\" text size button" % nm)
		await _frames(12)
		var want_two := menu._options_room() >= PauseMenu.OPT_TWO_ROOM
		if menu._opt_two != want_two:
			problems.append("%s: the page stayed in %s after the text size changed" % [nm, "two columns" if menu._opt_two else "one column"])
		var tag := "%dx%d %s" % [size.x, size.y, nm]
		# every other page first, its panel wholly on the screen too; then back
		# to the Options, which must not be left as wide as the widest of them
		for t in PauseMenu.TABS:
			if String(t[0]) == "options" or not PauseMenu.tab_open(String(t[0])):
				continue
			menu.show_tab(String(t[0]))
			await _frames(6)
			var pr: Rect2 = menu._panel.get_global_rect()
			if not SafeArea.rect().grow(1.0).encloses(pr):
				problems.append("%s: the %s page's panel is %d wide of the screen's safe area" % [tag, t[1], int(pr.end.x - SafeArea.rect().end.x)])
			# the Deck and the Codex were the two that ran off at Larger and
			# Largest (25 November): a still of each, and every card on the page
			if String(t[0]) in ["deck", "codex"]:
				var g := menu._page_grid()
				if g == null:
					problems.append("%s: no card grid on the %s page" % [tag, t[1]])
				else:
					var view: Rect2 = g._scroll.get_global_rect().grow(1.0)
					for cell in g._grid.get_children():
						var cr: Rect2 = (cell as Control).get_global_rect()
						if cr.position.x < view.position.x or cr.end.x > view.end.x:
							problems.append("%s: a card on the %s page runs off its side (%d to %d in %d to %d)" % [tag, t[1], int(cr.position.x), int(cr.end.x), int(view.position.x), int(view.end.x)])
							break
				if once.get(nm, true):
					await _shot("%s_%dx%d_%s" % [t[0], size.x, size.y, String(nm).to_lower()])
		menu.show_tab("options")
		await _frames(8)
		var sc := menu._content.get_child(0) as ScrollContainer
		if sc == null:
			problems.append("%s: the page isn't in a scroller" % tag)
			continue
		var inner := sc.get_child(0) as Control
		for c in sc.get_children():
			if not (c is ScrollBar):
				inner = c
		var over := inner.get_combined_minimum_size() - sc.size
		var words := _texts(menu._content)
		for r in ROWS:
			if not words.contains(r):
				problems.append("%s: no \"%s\" row" % [tag, r])
		print("OPTIONS %s: %s, room %d, page %dx%d in %dx%d" % [tag, "two columns" if menu._opt_two else "one column",
			int(menu._options_room()), int(inner.get_combined_minimum_size().x), int(inner.get_combined_minimum_size().y), int(sc.size.x), int(sc.size.y)])
		if menu._opt_two:
			if over.y > 0.5:
				problems.append("%s: two columns, and %d too tall for the panel" % [tag, int(over.y)])
			if over.x > 0.5:
				problems.append("%s: two columns, and %d too wide for the panel" % [tag, int(over.x)])
			# every button and slider wholly inside the scroller, and none over another
			var box := sc.get_global_rect().grow(1.0)
			var seen: Array = []
			for b in _controls(inner):
				var r: Rect2 = b.get_global_rect()
				if not box.encloses(r):
					problems.append("%s: \"%s\" runs out of the page" % [tag, _name_of(b)])
				for o in seen:
					if (o[1] as Rect2).grow(-1.0).intersects(r):
						problems.append("%s: \"%s\" is over \"%s\"" % [tag, _name_of(b), o[0]])
				seen.append([_name_of(b), r])
		elif over.x > 0.5:
			problems.append("%s: one column, and %d too wide for the panel" % [tag, int(over.x)])
		# the menu's panel wholly on the screen, clear of a phone's notch and
		# home bar, at every text size (25 November: at Larger and Largest it
		# ran off the right)
		var panel: Rect2 = menu._panel.get_global_rect()
		if not SafeArea.rect().grow(1.0).encloses(panel):
			problems.append("%s: the menu's panel %s runs off the screen's safe area %s" % [tag, panel, SafeArea.rect()])
		once[nm] = false
		shots += 1
		await _shot("options_%dx%d_%d_%s" % [size.x, size.y, shots, String(nm).to_lower()])
	Game.settings["ui_scale"] = 1.0
	print("OPTIONS PAGE TEST: %s" % ("ok" if problems.is_empty() else "PROBLEMS"))
	for p in problems:
		print("  - ", p)
	get_tree().quit()


func _controls(n: Node, out: Array = []) -> Array:
	for c in n.get_children():
		if (c is BaseButton or c is Slider) and (c as Control).is_visible_in_tree():
			out.append(c)
		_controls(c, out)
	return out


## A slider's or a choice's row name; a plain button's own words.
func _name_of(c: Control) -> String:
	var p := c.get_parent()
	if c is Button and (c as Button).text != "" and not (p.get_child(0) is Label):
		return (c as Button).text
	for s in p.get_children():
		if s is Label:
			return (s as Label).text
	return String(c.name)


func _texts(n: Node) -> String:
	var s := ""
	if n is Label:
		s += (n as Label).text + "\n"
	elif n is Button:
		s += (n as Button).text + "\n"
	for c in n.get_children():
		s += _texts(c)
	return s


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out_dir, name])
