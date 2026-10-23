extends Node
## Every screen at one screen shape, with a phone's safe area if asked, to
## check the game fills the screen edge to edge and keeps its buttons and words
## clear of the Dynamic Island and the home bar (SafeArea). The notice, the
## title, the opening movie, the world and its HUD (and the camera zoomed in
## and out), the dialogue box, a film's bars, subtitles, choices, name and
## deck choice, every pause menu tab and a card's detail, a new card, a story
## scene, the loading bar, a duel (and a card looked at), and the Duel Lab.
##   xvfb-run -a -s "-screen 0 2900x2200x24" godot --rendering-driver opengl3 --resolution 1434x660 \
##       res://tests/screen_fit_test.tscn -- <out_dir> [--safe-area=93,0,93,32] [only=world,duel,...] [ui=1.3] [mark]
## 1434x660 with --safe-area=93,0,93,32 is an iPhone 16 Pro Max held sideways,
## at half size. `mark` draws the phone's Dynamic Island and home bar over the
## screenshots (on the left; iOS keeps the same margin on both sides). `ui=`
## sets Options > Text and buttons size (1.15 Larger, 1.3 Largest). Any button
## found outside the safe area is listed; ends with "SCREEN FIT: ok".

var out_dir := "user://"
var tag := ""
var only: PackedStringArray = []
var problems := []
var _n := 0
var _settings_file = null   # the settings file as it was (zooming saves it), put back at the end


func _ready() -> void:
	if FileAccess.file_exists(Game.SETTINGS_PATH):
		_settings_file = FileAccess.get_file_as_string(Game.SETTINGS_PATH)
	Game.settings["ui_scale"] = 1.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("only="):
			only = a.trim_prefix("only=").split(",")
		elif a.begins_with("ui="):
			Game.settings["ui_scale"] = float(a.trim_prefix("ui="))   # Options > Text and buttons size
		elif not a.begins_with("--") and a != "mark":
			out_dir = a
	var win := get_window().size
	tag = "%dx%d" % [win.x, win.y]
	if SafeArea.pixels() != Vector4.ZERO:
		tag += "_safe"
	if SafeArea.ui_scale() > 1.0:
		tag += "_ui%d" % roundi(SafeArea.ui_scale() * 100)
	get_viewport().scaling_3d_scale = 0.5   # the 3D at half resolution (software GL is slow); the UI stays sharp
	get_tree().root.theme = UITheme.make()
	Game.settings["seen_notice"] = true
	Game.settings["first_steps"] = 2
	Game.settings["cam_zoom"] = 1.0
	if "mark" in OS.get_cmdline_user_args():
		add_child(PhoneMarks.new())
	print("screen %s, safe area %s (UI units %s)" % [win, SafeArea.pixels(), SafeArea.insets()])
	if _want("notice"):
		await _notice()
	if _want("title"):
		await _title()
	if _want("movie"):
		await _movie()
	if _want("world"):
		await _world()
	if _want("story"):
		await _story()
	if _want("loading"):
		await _loading()
	if _want("duel"):
		await _duel()
	if _want("lab"):
		await _lab()
	print("SCREEN FIT: %s" % ("ok (%d screenshots)" % _n if problems.is_empty() else "%d PROBLEMS\n  %s" % [problems.size(), "\n  ".join(problems)]))
	# put the player's settings back as they were (the zoom saved them)
	await secs(1.0)
	if _settings_file is String:
		var f := FileAccess.open(Game.SETTINGS_PATH, FileAccess.WRITE)
		if f != null:
			f.store_string(_settings_file)
			f.close()
	elif FileAccess.file_exists(Game.SETTINGS_PATH):
		DirAccess.remove_absolute(Game.SETTINGS_PATH)
	get_tree().quit(0 if problems.is_empty() else 1)


func _want(what: String) -> bool:
	return only.is_empty() or only.has(what)


# =============================================================== screens ===

func _notice() -> void:
	var n := NoticeScreen.new()
	add_child(n)
	await secs(2.0)
	await shot("notice", n)
	# the second page (one man's work, the plea for reports)
	n._finish()
	await secs(1.0)
	await shot("notice_2", n)
	n.queue_free()
	await frames(2)


func _title() -> void:
	var t := TitleScreen.new()
	add_child(t)
	await secs(2.0)
	await shot("title", t)
	t.queue_free()
	await frames(2)


func _movie() -> void:
	var m := OpeningMovie.new()
	m.shots_only = true   # the paintings and the title (the finished cut fills the same frame)
	add_child(m)
	await secs(2.5)
	m._show_skip()
	await secs(0.4)
	await shot("movie_painting", m)
	# a clip plays in the same frame as the paintings, filling a wide screen
	var fr := OpeningMovie.frame_rect(m._root.size)
	if m._video.size.distance_to(fr.size) > 1.0:
		problems.append("movie: a clip would be %s, not %s" % [m._video.size, fr.size])
	var screen: Vector2 = m._root.size
	if screen.x / screen.y > 16.0 / 9.0 + 0.01 and screen.x / screen.y < 2.22 and (fr.size.x < screen.x - 1.0 or fr.size.y < screen.y - 1.0):
		problems.append("movie: a clip doesn't fill a %s screen (%s)" % [screen, fr])
	# the last shot: the eight lights and the title
	var last: Dictionary = OpeningMovie.SHOTS[-1]
	var still := OpeningMovie._still_path(String(last.id))
	m._stage.show_shot(last, load(still) if still != "" else null, OpeningMovie.SHOTS.size())
	m._stage._t = float(last.get("title_at", 8.0)) + 3.0
	m._stage.modulate.a = 1.0
	await secs(0.5)
	await shot("movie_title", m)
	m.queue_free()
	await frames(2)


func _world() -> void:
	Game.new_game("Sprout", "emberstorm")
	Game.set_flag("arrived_ashford")
	Game.give_first_deck(["brookfin", "bulwark", "essence_flask", "healing_draught", "essence_flask", "healing_draught",
		"bulwark", "essence_flask", "healing_draught", "essence_flask", "bulwark", "travellers_pack"])
	Game.unlock("deck")
	Game.unlock("codex")
	Game.learn("fate", "Fate", "Bram", "That's Fate. Some moves roll the die: roll high, hit hard; roll low, nothing.")
	var w := World.new().setup("ashford", "green")
	add_child(w)
	await until(func() -> bool: return w.hud != null and w.hud._fade.modulate.a < 0.05 and not w.busy, 20.0)
	await secs(1.0)
	var hud := w.hud
	hud.set_objective("Find Bram by the Great Lantern.")
	hud.show_hint("Tap the ground where you want to walk.")
	hud.set_talk_target("Bram", false)
	hud.toast("New in your pack: Deck and Codex")
	await secs(0.8)
	await shot("world", hud)
	# zoom: all the way in, all the way out, then back
	var d0 := w.cam.global_position.distance_to(w._focus + World.CAM_LOOK)
	for i in 8:
		hud._zoom_in.pressed.emit()
	await secs(1.5)
	var d_in := w.cam.global_position.distance_to(w._focus + World.CAM_LOOK)
	await shot("world_zoom_in", hud)
	for i in 12:
		hud._zoom_out.pressed.emit()
	await secs(1.5)
	var d_out := w.cam.global_position.distance_to(w._focus + World.CAM_LOOK)
	await shot("world_zoom_out", hud)
	print("camera distance: usual %.1f m, in %.1f m, out %.1f m" % [d0, d_in, d_out])
	if not (d_in < d0 - 2.0 and d_out > d0 + 2.0):
		problems.append("world: zoom didn't move the camera (usual %.1f, in %.1f, out %.1f)" % [d0, d_in, d_out])
	Game.settings["cam_zoom"] = 1.0
	await secs(1.0)
	hud.set_talk_target("", false)
	hud.show_hint("")
	# the dialogue box, and answers
	w.busy = true
	hud.set_controls_visible(false)
	hud.dialogue.say("Bram", DollArt.portrait("bram"), "Right. Those cards are Sigils. The gods' magic is always leaking into the world, a drop at a time, and where it lands it sets hard. Like frost on a window.")
	await secs(3.5)
	await shot("dialogue", hud)
	hud.dialogue.choose(["Tell me about the Throne.", "Who is Corin?", "Never mind."])
	await secs(0.6)
	await shot("dialogue_answers", hud)
	hud.dialogue._chosen.emit(2)
	hud.dialogue.close()
	await frames(2)
	# a film: the bars, a subtitle, answers, the name, the deck chest
	var ov := Cine.overlay(w)
	ov.auto = false
	await ov.bars(true, 0.2)
	ov.say("Bram", "Inside! All of you, inside! And keep away from the windows!")
	await secs(1.4)
	await shot("cine_line", ov)
	ov._next.emit()
	await frames(2)
	ov.choose(["Come with us!", "We'll come back for you!"])
	await secs(0.8)
	await shot("cine_answers", ov)
	ov._chosen.emit(0)
	await frames(2)
	await ov.bars(false, 0.2)
	ov.say("", "The bells of Ashford rang until morning.")
	await secs(1.4)
	await shot("cine_line_nobars", ov)
	ov._next.emit()
	await frames(2)
	ov.ask_name("What's your name?", "Sprout")
	await secs(0.8)
	await shot("cine_name", ov)
	_press(ov._root, "That's me")
	await frames(3)
	ov.choose_deck("Bram's chest: choose a deck")
	await secs(0.8)
	await shot("cine_decks", ov)
	_press(ov._root, "Choose ")
	await frames(3)
	w.busy = false
	hud.set_controls_visible(true)
	# every tab of the pause menu, and a card's detail
	var menu: PauseMenu = hud._menu
	hud.open_menu("hero")
	for t in PauseMenu.TABS:
		menu.show_tab(t[0])
		await frames(10)
		await shot("menu_" + String(t[0]), hud)
	menu.show_tab("codex")
	await frames(6)
	menu._open_card("brookfin")
	await frames(10)
	await shot("menu_card", hud)
	menu.close_card()
	menu.request_close()
	await frames(4)
	# a new card
	w.busy = true
	hud.show_card_reward("cinderpup")
	await secs(1.0)
	await shot("new_card", hud)
	w.queue_free()
	await frames(4)


func _story() -> void:
	var s := StoryScreen.new()
	add_child(s)
	s.scene("card", [{"text": "The light settles into a card, warm as a hearthstone.", "who": "bram", "name": "Bram"}])
	await secs(3.0)
	await shot("story", s)
	s.queue_free()
	await frames(2)


func _loading() -> void:
	var S = load("res://scripts/game/packs.gd")
	var l = S._Screen.new()
	l.what = "the Totems and Summons"
	add_child(l)
	await frames(2)
	l.progress(31 << 20, 74 << 20)
	await frames(2)
	await shot("loading", l)
	l.queue_free()
	await frames(2)


func _duel() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var ds := DuelScreen.new().configure({"decks": ["emberstorm", "veilwild"], "names": ["You", "Wren"],
		"profiles": [Lore.new_profile("You", "pyrrhane", 4), Lore.new_profile("Wren", "oriel", 4)],
		"ai": [false, true], "seed": 11, "speed": 4.0})
	layer.add_child(ds)
	await until(func() -> bool: return ds.mode == "main", 60.0)
	await secs(0.6)
	await shot("duel", ds)
	if not ds.hand_views.is_empty():
		ds._on_hand_tapped(ds.hand_views[0])
		await secs(0.6)
		await shot("duel_card", ds)
		ds._back_out()
	# Totems in every slot, then the field zoomed as far in and out as a pinch or the wheel goes
	var ids := [["cinderpup", "sparkkit", "voltlynx"], ["dreamfox", "brookfin", "pebblit"]]
	for side in 2:
		var pl: DuelPlayer = ds.game.players[side]
		for slot in 3:
			var t := DuelTotem.new(DuelCard.new(900 + side * 3 + slot, ids[side][slot], side), side, slot, 1, pl.attributes())
			pl.slots[slot] = t
			ds.views[side][slot].set_totem(t)
	await secs(1.5)
	await shot("duel_full", ds)
	for z in [["duel_zoom_in", DuelField3D.VIEW_MIN], ["duel_zoom_out", DuelField3D.VIEW_MAX]]:
		Game.settings["duel_view"] = z[1]
		await secs(1.0)
		await shot(z[0], ds)
	Game.settings["duel_view"] = 1.0
	layer.queue_free()
	await frames(4)


func _lab() -> void:
	var lab := DuelLab.new()
	add_child(lab)
	await secs(1.0)
	await shot("lab", lab)
	lab.queue_free()
	await frames(2)


# ================================================================ checks ===

## Presses the first visible button under `n` whose words start with `text`.
func _press(n: Node, text: String) -> void:
	for b in n.find_children("*", "Button", true, false):
		if (b as Button).text.begins_with(text) and (b as Button).is_visible_in_tree():
			(b as Button).pressed.emit()
			return


## Every button showing under `n` must be inside the safe area.
func _check_buttons(what: String, n: Node) -> void:
	var safe := SafeArea.rect().grow(3.0)
	for c in n.find_children("*", "Control", true, false):
		var ctl := c as Control
		if not ctl.is_visible_in_tree() or ctl.modulate.a < 0.05:
			continue
		var tappable := ctl is BaseButton or ctl is WorldHUD.IconButton or ctl is WorldHUD.TalkButton \
			or ctl is DuelViews.EmblemButton or ctl is DuelViews.GiftButton or ctl is DuelViews.IconButton \
			or ctl is DuelViews.HandCard
		if not tappable:
			continue
		var clip := _clipped_by(ctl)
		# where it's really drawn (the hand's cards are turned in a fan)
		var xf := ctl.get_global_transform_with_canvas()
		var r := Rect2(xf * Vector2.ZERO, Vector2.ZERO)
		for corner in [Vector2(ctl.size.x, 0), ctl.size, Vector2(0, ctl.size.y)]:
			r = r.expand(xf * corner)
		if clip.has_area():
			r = r.intersection(clip)
			if not r.has_area():
				continue
		# the hand's fan dips its outer cards a little past the bottom of the duel's stage, by design
		var room := safe.grow_side(SIDE_BOTTOM, 30.0) if ctl is DuelViews.HandCard else safe
		if not room.encloses(r):
			problems.append("%s: %s %s is outside the safe area %s" % [what, ctl.get_class() if ctl.get_script() == null else ctl.name, r, safe])


## The rect of the nearest scroll box above `c`, if any (what's scrolled out of it doesn't show).
func _clipped_by(c: Control) -> Rect2:
	var p := c.get_parent()
	while p != null:
		if p is ScrollContainer:
			return (p as Control).get_global_rect()
		p = p.get_parent()
	return Rect2()


func shot(what: String, n: Node) -> void:
	_check_buttons(what, n)
	await RenderingServer.frame_post_draw
	var path := "%s/%s_%s.png" % [out_dir, tag, what]
	get_viewport().get_texture().get_image().save_png(path)
	_n += 1
	print("saved ", path)


# =============================================================== waiting ===

func frames(k: int) -> void:
	for i in k:
		await get_tree().process_frame


func secs(t: float) -> void:
	await get_tree().create_timer(t).timeout


func until(cond: Callable, timeout: float = 4.0) -> bool:
	var t := 0.0
	while not cond.call():
		if t > timeout:
			return false
		await get_tree().process_frame
		t += get_process_delta_time()
	return true


## The phone drawn over the screenshots: the Dynamic Island at the left, the
## home bar at the bottom, and the safe area's edge as a thin line.
class PhoneMarks:
	extends CanvasLayer

	func _ready() -> void:
		layer = 127
		var c := Marks.new()
		c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(c)

	class Marks:
		extends Control

		func _process(_d: float) -> void:
			queue_redraw()

		func _draw() -> void:
			var m := SafeArea.insets()
			var s := size
			if m.x > 0.0:
				# the island: about 37 x 126 points, 11 points in from the edge
				var k := m.x / 62.0
				draw_rect(Rect2(Vector2(11.0 * k, s.y * 0.5 - 63.0 * k), Vector2(37.0, 126.0) * k), Color.BLACK)
			if m.w > 0.0:
				var k2 := m.w / 21.0
				draw_rect(Rect2(Vector2(s.x * 0.5 - 70.0 * k2, s.y - 9.0 * k2), Vector2(140.0, 5.0) * k2), Color(1, 1, 1, 0.85))
			draw_rect(SafeArea.rect(), Color(1, 0.2, 0.6, 0.55), false, 2.0)
