class_name DuelTutor
extends RefCounted
## A gated, step-by-step tutorial on the Duel screen (the Lantern Duel). Each
## lesson waits for the player: a line of explanation stays up until they tap,
## and an instruction ("Tap Brookfin") lights up the one thing to tap while
## everything else on the screen is locked. Nothing moves on until it's done.
##
## spec.tutorial = {
##   "events": {"intro": [step...], "weakness": [step...], ...},   shown once, when the duel reaches them
##   "turns":  [[step...], [step...], ...]                          the player's turns, in order
## }
## A step is {"say": "...", "who": "Bram", "focus": "...", "do": "...", "learn": "..."}.
## Without "do" it's an explanation (tap to go on); with "do" it's an
## instruction, and only that action is allowed:
##   card:<id>  tap that card in your hand     slot:<n>   tap that empty slot
##   totem:<id> tap your Totem                 move:<n>   pick that move (move:any = either)
##   target:<id> | target:life                 end        End Turn
##   die        tap your die (the roll for who goes first)
## focus (optional) spotlights something: hand, card:<id>, slot:<n>, totem:<id>,
## foe:<id>, life, essence, end, move:<n>, detail (the card panel), die. A "do"
## step spotlights its own target. Once the scripted turns run out the duel
## plays freely. "learn" names a lesson the line teaches (so it isn't taught
## again later by lesson()).
##
## Every line is kept, in order, on the pause menu's How to Duel page
## (Game.lessons()). Later duels where Bram is about (spec.lessons = true)
## get a tutor with no script, just for lesson(): the first condition, Ward
## or Ascension is explained the same gated way, once ever, in the words of
## Master Script v3 (FIRST_TIME). spec.tutorial = {"quiet": true} gives a
## duel with no lessons at all: the Lantern Duel when the player told Bram
## they'd watched enough duels ("Then I'll keep quiet. Mostly.").

signal _did_step

var screen   # DuelScreen
var data: Dictionary = {}
var queue: Array = []          # what's left of this turn's lesson
var my_turn := 0
var blocking := false          # an explanation is up: everything waits for a tap
var focus := ""
var group := "The Lantern Duel"   # the How to Duel heading the scripted lines go under
var event_step: Dictionary = {}   # an instruction inside an event (tap the die), waiting to be done
var _shown := {}
var _shown_at := 0
var _said := 0
var root: Control
var catcher: Control
var spot: Spotlight
var design: Control
var box: PanelContainer
var who_label: Label
var text_label: Label
var foot_label: Label
var portrait: TextureRect


func setup(p_screen, p_data: Dictionary, p_group: String = "The Lantern Duel") -> DuelTutor:
	screen = p_screen
	data = p_data
	group = p_group
	root = Control.new()
	root.name = "Tutorial"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.z_index = 120
	screen.add_child(root)
	spot = Spotlight.new()
	spot.tutor = self
	spot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(spot)
	catcher = Control.new()
	catcher.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	catcher.mouse_filter = Control.MOUSE_FILTER_IGNORE
	catcher.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			tap())
	root.add_child(catcher)
	# the speech box lives in the duel's 1920 x 1080 design space
	design = Control.new()
	design.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design.size = Vector2(1920, 1080)
	root.add_child(design)
	box = PanelContainer.new()
	box.add_theme_stylebox_override("panel", UITheme.sb(Color(0.035, 0.04, 0.08, 0.96), UITheme.GOLD, 20, 3, 24))
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.visible = false
	design.add_child(box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)
	portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(124, 124)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(portrait)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)
	who_label = UITheme.label("", 24, UITheme.GOLD, "bold")
	col.add_child(who_label)
	text_label = UITheme.label("", 31, UITheme.TEXT)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size = Vector2(720, 0)
	col.add_child(text_label)
	foot_label = UITheme.label("", 22, UITheme.GOLD, "bold")
	foot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	col.add_child(foot_label)
	return self


## The player's turn has begun: load its lesson.
func begin_turn() -> void:
	my_turn += 1
	var turns: Array = data.get("turns", [])
	queue = (turns[my_turn - 1] as Array).duplicate() if my_turn <= turns.size() else []


## Called before the player may act: explanations first, then the instruction.
func at_main() -> void:
	await _continue()


## A moment in the duel (the rival calls, a weakness lands, a knockout...).
## Its lines show once, and the duel waits while they're up; a "do" step in
## it (tap the die) waits until it's done.
func event(name: String) -> void:
	if _shown.has(name):
		return
	var lines: Array = data.get("events", {}).get(name, [])
	if lines.is_empty():
		return
	_shown[name] = true
	await _rival_done()
	for step in lines:
		if (step as Dictionary).has("do"):
			await _instruct(step)
		else:
			await _explain(step)
	_show_head()


## Bram lets the rival's line be read before he speaks (both at once, his box
## lay over theirs).
func _rival_done() -> void:
	if screen != null and screen.has_method("_bark_gone"):
		await screen._bark_gone()


## A one-off lesson for something seen for the first time (a condition, a
## Ward, Ascension): one gated line from Bram, kept on the How to Duel page,
## never taught twice. `focus` spotlights what it's about.
func lesson(id: String, text: String, p_group: String, p_focus: String = "", who: String = "Bram") -> void:
	if Game.learned(id) or bool(data.get("quiet", false)):
		return
	# a duel that teaches only some things (28 October: Tam's chains, Nell's
	# gods), in its own teacher's words; the rest wait for Bram
	var only: Array = data.get("only", [])
	if not only.is_empty() and not only.has(id):
		return
	if data.has("who"):
		who = String(data.who)
	text = first_time_line(id, text)
	if (data.get("lines", {}) as Dictionary).has(id):
		text = String(data.lines[id])
	Game.learn(id, p_group, who, text)
	await _rival_done()
	await _explain({"say": text, "who": who, "look": String(data.get("look", "")), "focus": p_focus, "keep": false})
	_show_head()


## Bram's first-time lines in Master Script v3's words ("Bram, the first time
## each thing appears"), by lesson id. The Duel screen asks for each lesson
## with its own (older) wording and the cards it's about filled in; where v3
## rewrote the line, this gives v3's, with the same cards. "(mine)" is the
## version for when Bram is the one across the Circle.
const FIRST_TIME := {
	"fate": "That's a Fate roll. High, and it hits hard; low, nothing. The die doesn't care who you are.",
	"ward_set": "A Ward. Face down, so you can't read it. It springs by itself when the right thing happens: a Totem called, a Rite cast, a hit coming in. Mind what you give it.",
	"ward_set (mine)": "That's my Ward, face down, so you can't read it. It springs by itself when the right thing happens: a Totem called, a Rite cast, a hit coming in. Mind what you give it.",
	"ward_mine": "Yours is down. It'll spring on its own when its moment comes. Set them early, while they're cheap.",
	"ward_spring": "There it goes. It's spent now. Next time, think what it's waiting for, and don't give it that.",
	"summon (theirs)": "That was a Summon. One great blow, then it's gone, and it cost a fortune in Essence. Nobody can do that often.",
	"summon (mine)": "That was my Summon. One great blow, then it's gone, and it cost a fortune in Essence. Nobody can do that often.",
	"ascend": "That %s is an Ascension: %s, grown up. Play it on your %s and it steps into the same slot, bigger, with everything it had. It costs Essence, so think about when.",
}


static func first_time_line(id: String, text: String) -> String:
	var mine := text.begins_with("That's my") or text.begins_with("That was my")
	match id:
		"fate", "ward_mine", "ward_spring":
			return FIRST_TIME[id]
		"ward_set":
			return FIRST_TIME["ward_set (mine)" if mine else "ward_set"]
		"summon":
			if text.begins_with("That was"):
				return FIRST_TIME["summon (mine)" if mine else "summon (theirs)"]
		"ascend":
			var m := RegEx.create_from_string("^That (.+) is an Ascension: (.+), grown up\\.").search(text)
			if m != null:
				return FIRST_TIME.ascend % [m.get_string(1), m.get_string(2), m.get_string(2)]
	return text


## True while an instruction is waiting to be carried out.
func gating() -> bool:
	return blocking or not event_step.is_empty() or (not queue.is_empty() and (queue[0] as Dictionary).has("do"))


## The instruction the player must carry out now, or {}.
func _current_do() -> Dictionary:
	if not event_step.is_empty():
		return event_step
	if not queue.is_empty() and (queue[0] as Dictionary).has("do"):
		return queue[0]
	return {}


## May the player do this right now? kind: card, slot, totem, move, target, end, die, button, other.
func allows(kind: String, what = null) -> bool:
	if blocking:
		return false
	var step := _current_do()
	if step.is_empty():
		return true
	var d := String(step.do)
	var want := d.get_slice(":", 0)
	var arg := d.get_slice(":", 1) if d.contains(":") else ""
	match kind:
		"card":
			return want == "card" and what is DuelCard and (what as DuelCard).id == arg
		"slot":
			return want == "slot" and (arg == "" or int(arg) == int(what))
		"totem":
			return want == "totem" and what is DuelTotem and (what as DuelTotem).id() == arg
		"move":
			return want == "move" and (arg == "any" or int(arg) == int(what))
		"button":
			return want == "move" and String(what).begins_with("move:") and (arg == "any" or String(what) == "move:" + arg)
		"target":
			if want != "target":
				return false
			if arg == "life":
				return what is String and what == DuelGame.LIFE
			return what is DuelTotem and (what as DuelTotem).id() == arg
		"end":
			return want == "end"
		"die":
			return want == "die"
	return false


## The player did what was asked (call after allows() said yes). Any
## explanations queued behind it show now, before the next instruction;
## except after a step the duel then plays out (an attack or a Rite on its
## target, a Totem called into its slot): those wait until the duel comes
## back to the player (at_main()), so a line the play itself brings (Bram's
## "See that?" as the hit lands on a weakness, "Out it goes" at a knockout)
## comes first, in the script's order, not behind the next one.
func did(kind: String, what = null) -> void:
	if _current_do().is_empty() or not allows(kind, what):
		return
	if not event_step.is_empty():
		event_step = {}
		_hide()
		_did_step.emit()
		return
	queue.pop_front()
	if kind in ["target", "slot"]:
		if not _line_up:
			_hide()
		return
	_continue()


## Shows the explanations at the front of the queue, then the next instruction.
## One run at a time: asked again while it's running (the duel coming back
## to the main phase while a line is still up), it waits for that run to
## finish instead of starting a second over the same lines, which would
## take two lines away with one tap.
func _continue() -> void:
	if _continuing:
		await _continued
		return
	_continuing = true
	while not queue.is_empty() and not (queue[0] as Dictionary).has("do"):
		var step: Dictionary = queue[0]
		await _explain(step)
		if not queue.is_empty() and is_same(queue[0], step):
			queue.pop_front()
	_continuing = false
	_show_head()
	_continued.emit()


signal _continued
var _continuing := false


## Something else was tapped: shake the instruction so the eye finds it.
func nudge() -> void:
	if screen.sfx != null:
		screen.sfx.play("ui_error")
	if box.visible:
		var x := box.position.x
		var tw := box.create_tween()
		for k in 4:
			tw.tween_property(box, "position:x", x + (14.0 if k % 2 == 0 else -14.0), 0.05)
		tw.tween_property(box, "position:x", x, 0.05)
	spot.pulse = 1.0


## The duel is over: everything goes.
func finish() -> void:
	queue.clear()
	event_step = {}
	_line_up = false
	_waiting.clear()
	_continuing = false
	blocking = false
	catcher.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hide()


func tap() -> void:
	if blocking and Time.get_ticks_msec() - _shown_at > 350:
		_tapped.emit()


# ------------------------------------------------------------------ drawing ---

## An explanation, up until the player taps. Lines take turns: one that
## comes while another is up (Bram's "See that?" as the hit lands, while the
## line queued behind the attack is showing) waits until that one has been
## tapped, so a single tap never carries two lines away.
func _explain(step: Dictionary) -> void:
	if _line_up:
		var turn := Turn.new()
		_waiting.append(turn)
		await turn.go   # (handed the box by the line before, still marked up)
	_line_up = true
	_put_up(step)
	await _tapped
	if screen.sfx != null:
		screen.sfx.play("ui_tap")
	blocking = false
	catcher.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _waiting.is_empty():
		_line_up = false
	else:
		# (next frame: not from inside this tap, which it mustn't also take)
		var nxt: Turn = _waiting.pop_front()
		nxt.go.emit.call_deferred()


signal _tapped
var _line_up := false
## Lines waiting for the box, first come first shown.
var _waiting: Array = []


class Turn:
	extends RefCounted
	signal go


func _put_up(step: Dictionary) -> void:
	blocking = true
	catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	_show_box(step, "TAP TO CONTINUE  ▸")
	focus = String(step.get("focus", ""))
	spot.dim = 0.42 if focus == "" else 0.55
	_shown_at = Time.get_ticks_msec()


## An instruction inside an event: up until the player does it.
func _instruct(step: Dictionary) -> void:
	event_step = step
	_show_box(step, "YOUR MOVE  ▸")
	focus = String(step.get("focus", step.do))
	spot.dim = 0.5
	await _did_step


func _show_head() -> void:
	if _line_up:
		return   # a line is still up (or waiting): the head shows when it's done
	if queue.is_empty() or not (queue[0] as Dictionary).has("do"):
		_hide()
		return
	var step: Dictionary = queue[0]
	_show_box(step, "YOUR MOVE  ▸")
	focus = String(step.get("focus", step.do))
	spot.dim = 0.5


func _show_box(step: Dictionary, footer: String) -> void:
	var who := String(step.get("who", "Bram"))
	who_label.text = who.to_upper()
	text_label.text = String(step.get("say", ""))
	foot_label.text = footer
	var look := String(step.get("look", "")) if String(step.get("look", "")) != "" else who.to_lower()
	# 29 October (Gary: Nell's "image ... is different then her model"): a
	# teacher with a portrait rendered from their own model shows that, not
	# the stand-in look (Nell's "elder" is Old Maren's face, Tam's "farmer"
	# the crowd's farmer)
	portrait.texture = DollArt.portrait(look) if (DollArt.has_portrait(look) or DollArt.LOOKS.has(look)) else null
	portrait.visible = portrait.texture != null
	var was := box.visible
	box.visible = true
	box.reset_size()
	if not was:
		box.modulate.a = 0.0
		box.create_tween().tween_property(box, "modulate:a", 1.0, 0.2)
	else:
		box.modulate.a = 0.4
		box.create_tween().tween_property(box, "modulate:a", 1.0, 0.18)
	_place_box()
	_keep(step, who)


## Every scripted line goes on the How to Duel page, in the order it was said.
func _keep(step: Dictionary, who: String) -> void:
	if not bool(step.get("keep", true)):
		return
	_said += 1
	Game.learn("%s:%d" % [group, _said], group, who, String(step.get("say", "")))
	if step.has("learn"):
		Game.learn(String(step.learn), group, who, String(step.get("say", "")))


func _hide() -> void:
	box.visible = false
	focus = ""
	spot.dim = 0.0


## Top centre, unless that would cover what's being pointed at.
func _place_box() -> void:
	# drawn at the player's text size (Options: Text and buttons size)
	var k := SafeArea.ui_scale()
	box.scale = Vector2(k, k)
	box.size = box.get_combined_minimum_size()
	var sz := box.size * k
	var x := (1920.0 - sz.x) * 0.5
	var f: Rect2 = screen.tutor_rect(focus) if focus != "" else Rect2()
	var spots := [Vector2(x, 92), Vector2(x, 470 - sz.y * 0.5), Vector2(x, 600)]
	var best: Vector2 = spots[0]
	for p in spots:
		if not Rect2(p, sz).grow(16).intersects(f):
			best = p
			break
	box.position = best


## Dims the screen around what to tap, rings it in gold and points at it.
class Spotlight:
	extends Control
	var tutor: DuelTutor
	var dim := 0.0
	var _dim_now := 0.0
	var pulse := 0.0
	var _t := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_t += delta
		_dim_now = move_toward(_dim_now, dim, delta * 2.5)
		pulse = move_toward(pulse, 0.0, delta * 2.0)
		var s = tutor.screen
		tutor.design.position = s._stage_base
		tutor.design.scale = Vector2(s._base_k, s._base_k)
		if tutor.box.visible and tutor.focus != "":
			tutor._place_box()
		queue_redraw()

	func _draw() -> void:
		if _dim_now <= 0.005:
			return
		var s = tutor.screen
		var full := Rect2(Vector2.ZERO, size)
		var f: Rect2 = s.tutor_rect(tutor.focus) if tutor.focus != "" else Rect2()
		var shade := Color(0, 0, 0, _dim_now)
		if f.size == Vector2.ZERO:
			draw_rect(full, shade)
			return
		var k: float = s._base_k
		var r := Rect2(s._stage_base + f.position * k, f.size * k).grow(10.0 * k)
		# four bands round the hole
		draw_rect(Rect2(0, 0, size.x, r.position.y), shade)
		draw_rect(Rect2(0, r.end.y, size.x, size.y - r.end.y), shade)
		draw_rect(Rect2(0, r.position.y, r.position.x, r.size.y), shade)
		draw_rect(Rect2(r.end.x, r.position.y, size.x - r.end.x, r.size.y), shade)
		var glow := 0.55 + 0.45 * sin(_t * 5.0)
		var gold := Color(UITheme.GOLD, 0.6 + 0.4 * glow)
		draw_rect(r, gold, false, (4.0 + 4.0 * pulse) * k + 2.0)
		draw_rect(r.grow(8.0 * k), Color(UITheme.GOLD, 0.18 * glow), false, 6.0 * k)
		if tutor.blocking:
			return
		# a bouncing arrow above (or below, near the top of the screen)
		var bob := sin(_t * 6.0) * 12.0 * k
		var c := Vector2(r.get_center().x, 0)
		var w := 34.0 * k
		var h := 40.0 * k
		if r.position.y > 120.0 * k:
			var tip := Vector2(c.x, r.position.y - 14.0 * k - bob)
			draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-w, -h), tip + Vector2(w, -h)]), UITheme.GOLD)
		else:
			var tip2 := Vector2(c.x, r.end.y + 14.0 * k + bob)
			draw_colored_polygon(PackedVector2Array([tip2, tip2 + Vector2(-w, h), tip2 + Vector2(w, h)]), UITheme.GOLD)
