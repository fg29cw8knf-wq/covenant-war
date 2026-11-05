class_name StallSheet
extends Control
## Tamsin's stall (5 November: "Crowns for caches. Win duels, earn crowns,
## come back."): three sealed caches on the counter a day, each one card face
## down, with its price by tier (DuelRewards.CACHE_PRICE; half as much again
## after the Trial). Buying one takes the crowns from the purse, turns the
## card over with the Codex's card face, and puts it in the collection and the
## Codex, owned (Game.buy_cache). The counter is stocked afresh each calendar
## day (Game.stall_caches). The crier's cache is one of them, free: the sheet
## opens with `free` caches to take before the prices count.
##
##   await StallSheet.open(world)          # "What've you got?"
##   await StallSheet.open(world, 1)       # the crier heard out: one free

signal closed

## The card's size on the counter (the Codex's proportions).
const CARD := Vector2(250, 350)

## Caches still to take for nothing (the crier's).
var free := 0
var _slots: Array = []        # {card (CacheCard), tag (Label), btn (Button)}
var _purse: Label
var _sub: Label
var _toast: Label
var _done: Button
var _panel: Control
var _sfx: Sfx
var _t := 0.0


## Shows the stall over `parent` (the world) until the player is done.
static func open(parent: Node, free_picks := 0) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 18
	parent.add_child(layer)
	if free_picks > 0:
		Game.stall_one_more()   # (a counter sold out today gets one more cache for the crier)
	var s := StallSheet.new()
	s.name = "StallSheet"
	s.free = free_picks
	layer.add_child(s)
	await s.closed
	Game.save_game()
	layer.queue_free()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.make()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)
	_sfx = Sfx.new()
	add_child(_sfx)
	_panel = Control.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	SafeArea.fit(_panel, Vector2(40, 24), true)   # clear of the island and the home bar
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(centre)
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(1180, 0)
	col.add_theme_constant_override("separation", 12)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.add_child(col)
	var kicker := UITheme.label("TAMSIN'S STALL", 28, UITheme.GOLD_DIM, "display_bold", 6)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(kicker)
	var title := UITheme.label("SEALED CACHES", 60, UITheme.GOLD, "display_bold", 10)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	_sub = UITheme.label("", 28, UITheme.TEXT_DIM, "body", 4)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_sub)
	# the counter
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 70)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(row)
	var caches := Game.stall_caches()
	for i in caches.size():
		var slot := VBoxContainer.new()
		slot.add_theme_constant_override("separation", 10)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(slot)
		var card := CacheCard.new()
		card.id = String(caches[i].id)
		card.open = bool(caches[i].sold)
		card.turn = 1.0 if card.open else 0.0
		card.custom_minimum_size = CARD + Vector2(40, 40)
		slot.add_child(card)
		var tag := UITheme.label("", 26, UITheme.TEXT_DIM, "display_bold", 4)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.custom_minimum_size = Vector2(CARD.x + 40, 0)
		slot.add_child(tag)
		var btn := UITheme.button("", true, 0)
		btn.custom_minimum_size = Vector2(CARD.x + 20, UITheme.TOUCH)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var at := i
		btn.pressed.connect(func() -> void: _buy(at))
		slot.add_child(btn)
		_slots.append({"card": card, "tag": tag, "btn": btn})
	if caches.is_empty():
		var none := UITheme.label("Nothing on the counter yet. Come back when you've seen more of the world.", 30, UITheme.TEXT, "body")
		none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(none)
	_purse = UITheme.label("", 34, UITheme.GOLD, "display_bold", 6)
	_purse.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_purse)
	_toast = UITheme.label("", 30, UITheme.TEXT, "display_bold", 6)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.custom_minimum_size = Vector2(0, 40)
	col.add_child(_toast)
	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(foot)
	_done = UITheme.button("Done", false, 360)
	_done.pressed.connect(_close)
	foot.add_child(_done)
	_refresh()
	_first_focus.call_deferred()


## Fills in the words, the prices and which buttons can be pressed.
func _refresh() -> void:
	var caches := Game.stall_caches()
	var left := 0
	for c in caches:
		if not bool(c.sold):
			left += 1
	if free > 0 and left > 0:
		_sub.text = "The crier's cache: take one, and it's yours for nothing."
	elif left == 0 and not caches.is_empty():
		_sub.text = "Sold out today. Fresh caches tomorrow."
	elif Game.stall_dearer():
		_sub.text = "Everything's dearer today: half as much again, since the Trial."
	else:
		_sub.text = "Fresh out of the Shardlands, three a day. One card in each, sealed."
	var cr := Game.crowns()
	_purse.text = "Your purse: %d crown%s" % [cr, "" if cr == 1 else "s"]
	for i in _slots.size():
		if i >= caches.size():
			continue
		var s: Dictionary = _slots[i]
		var id := String(caches[i].id)
		var tier := int(DuelCards.CARDS.get(id, {}).get("tier", 1))
		var btn: Button = s.btn
		var tag: Label = s.tag
		if bool(caches[i].sold):
			tag.text = String(DuelCards.CARDS.get(id, {}).get("name", id))
			tag.add_theme_color_override("font_color", UITheme.GOLD)
			btn.text = "Yours"
			btn.disabled = true
			continue
		var price := Game.cache_price(i)
		tag.text = "A %s, sealed" % Lore.TIER_NAMES[tier]
		tag.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		if free > 0:
			btn.text = "Take it"
			btn.disabled = false
		else:
			btn.text = "%d crowns" % price
			btn.disabled = cr < price


func _first_focus() -> void:
	for s in _slots:
		var b: Button = s.btn
		if not b.disabled:
			b.grab_focus()
			return
	_done.grab_focus()


func _buy(i: int) -> void:
	var was_new := Codex.owned(String(Game.stall_caches()[i].id)) == 0
	var id := Game.buy_cache(i, free > 0)
	if id == "":
		return
	if free > 0:
		free -= 1
	var card: CacheCard = _slots[i].card
	card.reveal()
	_sfx.play("gift")
	var name_ := String(DuelCards.CARDS[id].name)
	_toast.text = ("New in your Codex: %s" if was_new else "Another %s for your collection") % name_
	_toast.modulate.a = 0.0
	create_tween().tween_property(_toast, "modulate:a", 1.0, 0.3)
	_refresh()
	_first_focus()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("menu") or e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	if _done.disabled:
		return
	_done.disabled = true
	var out := create_tween()
	out.tween_property(self, "modulate:a", 0.0, 0.25)
	await out.finished
	closed.emit()


func _draw() -> void:
	var s := size
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.01, 0.01, 0.025, 0.86))
	# the stall's lamp: a warm pool of light behind the counter
	var c := Vector2(s.x * 0.5, s.y * 0.5)
	for i in 8:
		draw_circle(c, minf(s.x, s.y) * (0.62 - i * 0.06), Color(1.0, 0.78, 0.42, 0.018 + 0.004 * sin(_t * 1.3)))


## One cache on the counter: the card face down, turned over when bought.
class CacheCard:
	extends Control
	var id := ""
	var open := false
	## 0 face down .. 1 face up (the turn's half-way, edge on, swaps the sides)
	var turn := 0.0
	var _glow := 0.0
	var _t := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	## Turns the card over, with a flash of Sigil light.
	func reveal() -> void:
		open = true
		var tw := create_tween()
		tw.tween_property(self, "turn", 1.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.parallel().tween_property(self, "_glow", 1.0, 0.3)
		tw.tween_property(self, "_glow", 0.0, 0.8)

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		if id == "" or not DuelCards.CARDS.has(id):
			return
		var full := Rect2((size - StallSheet.CARD) * 0.5, StallSheet.CARD)
		var c := full.get_center()
		var tier := int(DuelCards.CARDS[id].get("tier", 1))
		# a soft halo in the tier's metal, brighter as it turns
		var halo: Color = Color(CardFace.TIER_METAL[clampi(tier, 0, CardFace.TIER_METAL.size() - 1)][0])
		for i in 6:
			draw_circle(c, full.size.y * (0.6 - i * 0.07), Color(halo, 0.025 + 0.05 * _glow))
		var k := absf(cos(turn * PI))   # its width as it turns edge on
		if k * full.size.x < 2.0:
			return
		# drawn at full size, squeezed about its middle while it turns
		if k < 0.999:
			draw_set_transform(Vector2(c.x * (1.0 - k), 0.0), 0.0, Vector2(k, 1.0))
		if turn < 0.5:
			DuelCardFace.draw_back(self, full)
			# the seal across it: a band of wax-red ribbon and its wax
			if not open or turn > 0.0:
				draw_rect(Rect2(full.position.x, c.y - 14, full.size.x, 28), Color(0.55, 0.12, 0.1, 0.85))
				draw_circle(c, 26.0, Color(0.62, 0.14, 0.11))
				draw_arc(c, 26.0, 0, TAU, 40, Color(0.88, 0.38, 0.27, 0.9), 2.5, true)
				draw_arc(c, 17.0, 0, TAU, 32, Color(0.4, 0.07, 0.06, 0.8), 2.0, true)
		else:
			DuelCardFace.draw_card(self, full, id, {"attrs": Game.profile.get("attributes", {}), "compact": false})
		if _glow > 0.0:
			CardFace.box(self, full, 12, Color(1.0, 0.97, 0.85, 0.5 * _glow))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
