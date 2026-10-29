extends Node
## How to Duel (the pause menu's manual, DuelManual) with every chapter it
## can have: every lesson learned, every condition and boon met, the whole
## pack tour heard. Scrolls down the page a screen at a time and takes a
## still of each, and checks that no words run out of their box: no line
## wider than the page, no page wider than the panel (it would scroll
## sideways), and the element chart's columns inside the chart (29 October,
## Gary: "In the how to duel some of the text goes out of the text box").
##   xvfb-run -a -s "-screen 0 2000x1200x24" godot --rendering-driver opengl3 --resolution 390x844 \
##       res://tests/manual_shot.tscn -- <out_dir> [ui=1.3]
## Run it at 390x844, 844x390, 1280x720 and 1920x1080 (a phone each way up,
## a laptop, a big screen). Ends with "MANUAL SHOT: ok" or the problems.

## Every lesson DuelManual opens a chapter for.
const LESSONS := ["aim", "weakness", "fate", "fate_bands", "ward_set", "ward_mine", "ward_spring", "stance",
	"answer", "answered", "shift", "tier", "tribute", "veiled", "revealed", "relic", "summon", "ascend", "way",
	"bond", "family", "side", "beside", "reaction", "chain", "combo", "graced", "shunned", "ground", "skills",
	"comeback", "arena_event", "guardian", "arena_rule", "terrain", "continuous", "favour", "favour_rival",
	"gift", "oath", "echo", "rekindle", "loyal", "search", "steal"]

var out_dir := "user://"
var tag := ""
var problems := []
var _settings_file = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # the menu pauses the tree
	if FileAccess.file_exists(Game.SETTINGS_PATH):
		_settings_file = FileAccess.get_file_as_string(Game.SETTINGS_PATH)
	Game.settings["ui_scale"] = 1.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("ui="):
			Game.settings["ui_scale"] = float(a.trim_prefix("ui="))
		elif not a.begins_with("--"):
			out_dir = a
	var win := get_window().size
	tag = "%dx%d" % [win.x, win.y]
	if SafeArea.ui_scale() > 1.0:
		tag += "_ui%d" % roundi(SafeArea.ui_scale() * 100)
	get_tree().root.theme = UITheme.make()
	_learn_everything()
	var titles := []
	for s in DuelManual.sections():
		titles.append(String(s.title))
	print("MANUAL SHOT: %d chapters: %s" % [titles.size(), ", ".join(titles)])
	await _manual()
	await _story_chart()
	print("MANUAL SHOT: %s" % ("ok" if problems.is_empty() else "%d PROBLEMS\n  %s" % [problems.size(), "\n  ".join(problems)]))
	if _settings_file is String:
		var f := FileAccess.open(Game.SETTINGS_PATH, FileAccess.WRITE)
		if f != null:
			f.store_string(_settings_file)
			f.close()
	get_tree().quit(0 if problems.is_empty() else 1)


func _learn_everything() -> void:
	Game.flags["first_deck"] = true
	Game.flags["told_skills"] = true
	for id in LESSONS:
		Game.learn(id, "Everything", "Bram", "")
	# the pack tour, as far as Resonance (the deepest pack lines)
	Game.learn("pack_open", "Your pack", "Bram", "That's your pack.")
	Game.learn("pack_resonance", "Your pack", "Bram", "Resonance fills every time you duel with it.")
	for id in DuelConditions.DEFS.keys():
		Game.meet_condition(String(id))


## The page, a screen at a time.
func _manual() -> void:
	var menu := PauseMenu.new()
	add_child(menu)
	await _frames(3)
	menu.open("howto")
	await _secs(0.6)
	var sc := _find_scroll(menu)
	if sc == null:
		problems.append("no How to Duel page")
		return
	_check_page(sc, menu)
	var page := sc.get_child(0) as Control
	var step := maxf(200.0, sc.size.y - 90.0)
	var y := 0.0
	var n := 0
	while true:
		sc.scroll_vertical = int(y)
		await _frames(3)
		await _shot("manual_%02d" % n)
		n += 1
		if y + sc.size.y >= page.size.y - 1.0 or n > 60:
			break
		y += step
	print("MANUAL SHOT: %d stills of a page %d tall in a %s box" % [n, int(page.size.y), sc.size.round()])
	menu.queue_free()
	await _frames(2)


## No words out of their box: every line inside the page, the page inside the
## panel, the chart's columns inside the chart.
func _check_page(sc: ScrollContainer, menu: PauseMenu) -> void:
	var page := sc.get_child(0) as Control
	var room := sc.size.x
	if page.size.x > room + 1.0:
		problems.append("%s: the page is %d wide in a box %d wide (it scrolls sideways)" % [tag, int(page.size.x), int(room)])
	var right := sc.global_position.x + sc.size.x * sc.get_global_transform().get_scale().x
	for l in page.find_children("*", "Label", true, false):
		var lab := l as Label
		if lab.text.strip_edges() == "":
			continue
		var r := lab.get_global_rect()
		var k := lab.get_global_transform().get_scale().x
		if lab.global_position.x + lab.size.x * k > right + 1.0:
			problems.append("%s: \"%s\" runs out of the page" % [tag, lab.text.left(40)])
		if lab.autowrap_mode == TextServer.AUTOWRAP_OFF:
			var f := lab.get_theme_font("font")
			var fs := lab.get_theme_font_size("font_size")
			if f.get_string_size(lab.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > lab.size.x + 1.0:
				problems.append("%s: \"%s\" is wider than its label" % [tag, lab.text.left(40)])
		elif lab.get_line_count() > 0 and lab.get_visible_line_count() < lab.get_line_count():
			problems.append("%s: \"%s\" shows %d of its %d lines" % [tag, lab.text.left(40), lab.get_visible_line_count(), lab.get_line_count()])
		if r.size.y < 1.0:
			problems.append("%s: \"%s\" has no height" % [tag, lab.text.left(40)])
	for c in page.find_children("*", "ElementChart", true, false):
		_check_chart(c as ElementChart, "page")
		var ch := c as Control
		if ch.global_position.x + ch.size.x * ch.get_global_transform().get_scale().x > right + 1.0:
			problems.append("%s: the element chart runs out of the page" % tag)
	var panel_r := menu._panel.get_global_rect()
	var scr := SafeArea.screen()
	if panel_r.end.x > scr.end.x + 1.0 or panel_r.end.y > scr.end.y + 1.0:
		problems.append("%s: the menu is bigger than the screen (%s on %s)" % [tag, panel_r, scr])


func _check_chart(ch: ElementChart, where: String) -> void:
	for row in ch.overflows():
		problems.append("%s: %s's element chart: %s" % [tag, where, row])


## Bram's chart at the campfire (StoryScreen.show_chart's layout), the same
## chart over the whole screen.
func _story_chart() -> void:
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(holder)
	await _frames(2)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.01, 0.03, 1.0)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(dim)
	var chart := ElementChart.new()
	chart.size = chart.custom_minimum_size
	chart.position = (holder.size - chart.size) * 0.5 - Vector2(0, 20)
	holder.add_child(chart)
	await _frames(3)
	_check_chart(chart, "campfire")
	if chart.position.x < 0.0 or chart.position.x + chart.size.x > holder.size.x:
		problems.append("%s: the campfire chart is wider than the screen" % tag)
	await _shot("chart")
	holder.queue_free()
	await _frames(2)


func _find_scroll(n: Node) -> ScrollContainer:
	for c in n.find_children("*", "ScrollContainer", true, false):
		if (c as ScrollContainer).is_visible_in_tree():
			return c
	return null


func _shot(what: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "%s/%s_%s.png" % [out_dir, tag, what]
	get_viewport().get_texture().get_image().save_png(path)
	print("saved ", path)


func _frames(k: int) -> void:
	for i in k:
		await get_tree().process_frame


func _secs(t: float) -> void:
	await get_tree().create_timer(t, true).timeout
