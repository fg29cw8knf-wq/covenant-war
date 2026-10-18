class_name StoryLoss
extends RefCounted
## Losing a main story duel (Master Script v3, "Losing a story duel"): the
## opponent's line for winning plays, then Morrowen takes the story back with
## one line, never the same one twice running, and only once per duel; after
## a second loss there is only the sound of a page turning back. Then two
## buttons: Again, and Change deck first (the Deck page, then the duel again
## with the deck as it's left).
##
## The duel screen hands over to this when spec.retry is set and the player
## didn't win: `return await StoryLoss.new().play(screen)`. It returns
## "again"; the spec is the same dictionary each time round (Main.run_duel
## plays it again), so the losses are counted in it.
##
##   spec.win_line = "Mam. Mam, it's —"     what the opponent says on winning
##
## Morrowen's lines are voiced once Gary records them:
## assets/audio/vo/morrowen_loss_01.ogg ... _04 (one per line of LINES, in
## order); the page turning back is assets/sfx/page_turn.ogg.

## Morrowen, Keeper of the Dead, taking the story back.
const LINES := [
	"No. That isn't how it went.",
	"No. I have it written differently.",
	"Not like that. Again.",
	"That isn't what's in my ledger.",
]
const VO := "res://assets/audio/vo/morrowen_loss_%02d.ogg"

var screen: Control      # the DuelScreen
var root: Control
var _go := ""
var _tapped := false


## Plays the loss and waits for a button; returns "again".
func play(p_screen: Control) -> String:
	screen = p_screen
	var spec: Dictionary = screen.spec
	var losses := int(spec.get("_losses", 0)) + 1
	spec["_losses"] = losses
	root = Control.new()
	root.name = "StoryLoss"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.theme = UITheme.make()
	root.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			_tapped = true)
	screen.overlay.add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.02, 0.0)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	var dt := root.create_tween()
	dt.tween_property(dim, "color:a", 0.82, 0.8)
	if screen.hint != null:
		screen.hint.visible = false   # nothing left to do on the board
	await screen.get_tree().create_timer(0.9).timeout
	if losses == 1:
		# their line for winning
		var win_line := String(spec.get("win_line", ""))
		if win_line != "":
			var names: Array = spec.get("names", ["", ""])
			await _line(String(names[1]).to_upper(), win_line, UITheme.TEXT_DIM, UITheme.TEXT, "body", 40, -1.0)
		# and Morrowen takes the story back
		var i := pick_line()
		var hold := -1.0
		var vo := VO % (i + 1)
		if ResourceLoader.exists(vo):
			var ap := AudioStreamPlayer.new()
			ap.stream = load(vo)
			root.add_child(ap)
			ap.play()
			hold = ap.stream.get_length() + 0.6
		await _line("MORROWEN", LINES[i], UITheme.GOLD_DIM, Color(0.93, 0.9, 0.82), "display", 50, hold)
	await _page_turn()
	var choice := await _buttons()
	if choice == "deck":
		await _change_deck(spec)
	root.queue_free()
	return "again"


## One of Morrowen's lines, never the one she said last (kept with the save).
static func pick_line() -> int:
	var last := int(Game.flag("morrowen_last", -1))
	var pool: Array = []
	for i in LINES.size():
		if i != last:
			pool.append(i)
	var i: int = pool[randi() % pool.size()]
	Game.set_flag("morrowen_last", i)
	return i


## A line in the middle of the screen, under who says it; it stays until it's
## been read (or `hold` seconds), or a tap.
func _line(who: String, text: String, who_col: Color, col: Color, font: String, size_px: int, hold: float) -> void:
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.offset_left = -820
	box.offset_right = 820
	box.offset_top = -140
	box.offset_bottom = 140
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(box)
	var w := UITheme.label(who, 26, who_col, "display_bold", 6)
	w.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(w)
	var l := UITheme.label(text, size_px, col, font, 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(1500, 0)
	box.add_child(l)
	box.modulate.a = 0.0
	var tw := root.create_tween()
	tw.tween_property(box, "modulate:a", 1.0, 0.5)
	var speed := maxf(0.4, float(Game.settings.get("text_speed", 1.0)))
	var secs := hold if hold > 0.0 else (CineOverlay.READ_BASE + text.length() * CineOverlay.READ_PER_CHAR) / speed + 0.6
	_tapped = false
	var t := 0.0
	while t < secs and not (_tapped and t > 0.4):
		await screen.get_tree().process_frame
		t += screen.get_process_delta_time()
	var out := root.create_tween()
	out.tween_property(box, "modulate:a", 0.0, 0.4)
	await out.finished
	box.queue_free()


## The page turning back: a pale leaf sweeping across, and its sound.
func _page_turn() -> void:
	var snd := Sfx.new()
	root.add_child(snd)
	if Sfx.has_file("page_turn"):
		snd.play("page_turn")
	else:
		snd.play("card_flip", 0.55)   # until page_turn exists
	var leaf := PageLeaf.new()
	leaf.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	leaf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(leaf)
	var tw := root.create_tween()
	tw.tween_property(leaf, "t", 1.0, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	leaf.queue_free()


## Again, and Change deck first. Returns "again" or "deck".
func _buttons() -> String:
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	row.offset_left = -560
	row.offset_right = 560
	row.offset_top = -60
	row.offset_bottom = 60
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 32)
	root.add_child(row)
	var again := UITheme.button("Again", true, 380)
	var deck := UITheme.button("Change deck first", false, 380)
	deck.visible = Game.unlocked("deck")
	row.add_child(again)
	row.add_child(deck)
	_go = ""
	again.pressed.connect(func() -> void: _go = "again")
	deck.pressed.connect(func() -> void: _go = "deck")
	row.modulate.a = 0.0
	root.create_tween().tween_property(row, "modulate:a", 1.0, 0.4)
	again.grab_focus.call_deferred()
	while _go == "":
		await screen.get_tree().process_frame
	row.queue_free()
	return _go


## The Deck page over the duel; the duel is played again with the deck as
## it's left (an unfinished deck isn't kept, PauseMenu sees to that).
func _change_deck(spec: Dictionary) -> void:
	var pm := PauseMenu.new()
	root.add_child(pm)
	pm.open("deck")
	while is_instance_valid(pm) and pm.visible:
		await screen.get_tree().process_frame
	if is_instance_valid(pm):
		pm.queue_free()
	var deck: Array = Game.v2.get("deck", [])
	if not deck.is_empty():
		var decks: Array = spec.get("decks", [])
		if not decks.is_empty():
			decks[0] = deck.duplicate()


## A pale page sweeping right to left across the screen (t 0..1).
class PageLeaf:
	extends Control
	var t := 0.0:
		set(v):
			t = v
			queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		# the turning edge travels from the right edge to the left; the leaf
		# narrows towards the end, as a page does when it lies down
		var edge := lerpf(w * 1.05, -w * 0.15, t)
		var width := w * 0.42 * sin(t * PI)
		var lean := h * 0.18 * sin(t * PI)
		var pts := PackedVector2Array([Vector2(edge, 0), Vector2(edge + width, 0), Vector2(edge + width - lean, h), Vector2(edge - lean, h)])
		var a := 0.5 * sin(t * PI)
		draw_colored_polygon(pts, Color(0.92, 0.88, 0.78, a))
		# a soft shadow along its turning edge
		draw_line(Vector2(edge, 0), Vector2(edge - lean, h), Color(0, 0, 0, a * 0.8), 18.0)
