extends Node
## The map of Veyl (the last beat of Chapter 1: "The map of Veyl opens on six
## kingdoms, a Champion's banner flying over each." / "Choose a kingdom. (Tap
## a banner on the map.)"), at every text size on the screen it's run at:
## the six banners and the four names wholly on the screen and clear of each
## other, of the objective and of the way back; a banner that can't be
## pressed before it's offered; the banner Bram names first under the keys;
## every banner opening its own kingdom's card, the card wholly on the
## screen, and "Back to the map" closing it; Esc closing a card, then the
## map; the names matching the game's own (the Kingdom Laws' places, the
## Convocation's Champions). Run with a real renderer, once for each shape:
##   xvfb-run -a -s "-screen 0 2560x1600x24" godot --rendering-driver opengl3 \
##       res://tests/veyl_map_test.tscn -- <out_dir> [WxH] [--phone --safe-area=L,T,R,B]
## Ends with "VEYL MAP TEST: ok" when every step worked.

var out_dir := "user://"
var size := Vector2i(1600, 900)
var problems := []
var chosen: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	if args.size() > 1 and args[1].contains("x"):
		var p: PackedStringArray = args[1].split("x")
		size = Vector2i(int(p[0]), int(p[1]))
	get_window().size = size
	Game.new_game("Ash", "emberstorm")
	_names_match()
	for ui in [1.0, 1.15, 1.3]:
		Game.settings["ui_scale"] = ui
		SafeArea.refresh()
		await _one(ui)
	Game.settings.erase("ui_scale")
	print("VEYL MAP TEST: %s" % ("ok" if problems.is_empty() else "PROBLEMS"))
	for p in problems:
		print("  - ", p)
	get_tree().quit()


## The map's names are the game's own.
func _names_match() -> void:
	var champs: Array = load("res://scripts/world/areas/ashford.gd").CHAMPIONS
	if VeylMap.KINGDOMS.size() != 6:
		problems.append("%d kingdoms on the map, not six" % VeylMap.KINGDOMS.size())
	for k in VeylMap.KINGDOMS:
		var god := String(k.god)
		if String(DuelLaws.LAWS.get(god, {}).get("place", "")) != String(k.name):
			problems.append("%s: the Kingdom Laws call %s's kingdom \"%s\"" % [k.name, god, DuelLaws.LAWS.get(god, {}).get("place", "")])
		var found := false
		for c in champs:
			if String(c[0]) == String(k.champion):
				found = true
				if String(c[1]) != god or String(c[2]) != String(k.holder):
					problems.append("%s: the Convocation has %s for %s, the map %s for %s" % [k.name, c[2], c[1], k.holder, god])
		if not found:
			problems.append("%s: no Champion \"%s\" at the Convocation" % [k.name, k.champion])
		if VeylMap.portrait(k) == null:
			problems.append("%s: no portrait of %s" % [k.name, k.holder])
		if not Glyphs.SHAPES.has(VeylMap.sign_of(k)):
			problems.append("%s: no sign \"%s\" to put on its banner" % [k.name, VeylMap.sign_of(k)])
	if String(VeylMap.kingdom("pyreholt").get("sign", "")) != "flame_crown":
		problems.append("Pyreholt's banner isn't the crown of flame")


func _one(ui: float) -> void:
	var tag := "%dx%d ui %.2f" % [size.x, size.y, ui]
	var map := VeylMap.open_on(self)
	chosen = []
	map.closed.connect(func(id: String) -> void: chosen.append(id))
	await _wait(0.7)
	# nothing can be pressed while Bram's line is up
	map.banner_button("pyreholt").pressed.emit()
	await _frames(3)
	if map.card_open():
		problems.append("%s: a banner opened its card before the map was offered" % tag)
	map.stir("pyreholt")
	await _frames(2)
	if ui == 1.0:
		await _shot("map_%dx%d_%d_stir" % [size.x, size.y, int(ui * 100)])
	map.offer("pyreholt")
	await _wait(0.6)
	await _shot("map_%dx%d_%d" % [size.x, size.y, int(ui * 100)])
	var f := get_viewport().gui_get_focus_owner()
	if f != map.banner_button("pyreholt"):
		problems.append("%s: the keys don't start on Pyreholt's banner (%s)" % [tag, f])
	# everything on the screen, and nothing over anything else
	var safe := SafeArea.rect().grow(1.0)
	var rects: Dictionary = map.rects()
	var painting: Rect2 = rects["painting"]
	rects.erase("painting")
	if not Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size).grow(1.0).encloses(painting):
		problems.append("%s: the painting %s isn't wholly on the screen" % [tag, painting])
	var names: Array = rects.keys()
	for i in names.size():
		var a: Rect2 = rects[names[i]]
		if not safe.encloses(a):
			problems.append("%s: \"%s\" %s runs out of the safe area %s" % [tag, names[i], a, safe])
		for j in range(i + 1, names.size()):
			if String(names[j]) == String(names[i]) + "'s banner":
				continue   # (a banner's own pole stands on its own names)
			if a.grow(-2.0).intersects(rects[names[j]]):
				problems.append("%s: \"%s\" is over \"%s\"" % [tag, names[i], names[j]])
	for k in VeylMap.KINGDOMS:
		# (what can be pressed is its names and its pole and cloth together)
		var press: Rect2 = (rects[String(k.name)] as Rect2).merge(rects[String(k.name) + "'s banner"])
		if press.size.x < UITheme.TOUCH or press.size.y < UITheme.TOUCH:
			problems.append("%s: %s's banner is too small to tap (%s)" % [tag, k.name, press.size])
	# every banner opens its own card, and the card goes back to the map
	var n := 0
	for k in VeylMap.KINGDOMS:
		map.banner_button(String(k.id)).pressed.emit()
		await _wait(0.3)
		if map.card_kingdom() != String(k.id):
			problems.append("%s: %s's banner opened \"%s\"" % [tag, k.name, map.card_kingdom()])
			continue
		var panel := map._card.find_children("*", "PanelContainer", true, false)[0] as Control
		if not safe.encloses(panel.get_global_rect()):
			problems.append("%s: %s's card %s runs out of the safe area %s" % [tag, k.name, panel.get_global_rect(), safe])
		for c in _controls(map._card):
			if not panel.get_global_rect().grow(1.0).encloses((c as Control).get_global_rect()):
				problems.append("%s: \"%s\" runs out of %s's card" % [tag, (c as Button).text, k.name])
		var words := _texts(map._card)
		for want in [String(k.name).to_upper(), String(k.holder), DuelLaws.law_name(String(k.god)).to_upper(), "Back to the map"]:
			if not words.contains(want):
				problems.append("%s: %s's card doesn't say \"%s\"" % [tag, k.name, want])
		if (ui == 1.0 and n in [0, 3]) or (ui > 1.2 and n in [2, 5]):
			await _shot("card_%dx%d_%d_%s" % [size.x, size.y, int(ui * 100), k.id])
		n += 1
		if n % 2 == 0:
			_key(KEY_ESCAPE)   # (Esc with a card up closes the card, not the map)
		else:
			map.card_back_button().pressed.emit()
		await _wait(0.25)
		if map.card_open():
			problems.append("%s: %s's card didn't close" % [tag, k.name])
		if not chosen.is_empty():
			problems.append("%s: closing %s's card closed the map" % [tag, k.name])
			break
		if get_viewport().gui_get_focus_owner() != map.banner_button(String(k.id)):
			problems.append("%s: the keys aren't back on %s's banner after its card" % [tag, k.name])
	# the way back: Esc on the map itself
	_key(KEY_ESCAPE)
	await _frames(3)
	if chosen != [""]:
		problems.append("%s: Esc on the map chose %s, not the way back" % [tag, chosen])
	await map.shut(0.0)
	await _frames(4)
	if has_node("VeylMapLayer") and not get_node("VeylMapLayer").is_queued_for_deletion():
		problems.append("%s: the map was left up" % tag)
	await _frames(2)


func _key(code: Key) -> void:
	for down in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.physical_keycode = code
		e.pressed = down
		Input.parse_input_event(e)


func _controls(n: Node, out: Array = []) -> Array:
	for c in n.get_children():
		if c is BaseButton and (c as Control).is_visible_in_tree():
			out.append(c)
		_controls(c, out)
	return out


func _texts(n: Node) -> String:
	var s := ""
	if n is Label:
		s += (n as Label).text + "\n"
	elif n is Button:
		s += (n as Button).text + "\n"
	for c in n.get_children():
		s += _texts(c)
	return s


## `secs` of the game's time (a fade, a card coming up), and a frame or two
## more for whatever was put off to the end of one.
func _wait(secs: float) -> void:
	await get_tree().create_timer(secs).timeout
	await _frames(2)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out_dir, name])
