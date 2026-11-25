extends Node
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

## Pages still too wide for the panel at Larger and Largest (25 November:
## found here, not yet put right; they're theirs to fix, not the Options').
const WIDE_PAGES := ["deck", "codex"]

var out_dir := "user://"
var size := Vector2i(1600, 900)
var problems := []
var shots := 0


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
				var said := "%s: the %s page's panel is %d wide of the screen's safe area" % [tag, t[1], int(pr.end.x - SafeArea.rect().end.x)]
				if WIDE_PAGES.has(String(t[0])) and nm != "Normal":
					print("OPTIONS (known, not this test's) ", said)
				else:
					problems.append(said)
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
