class_name WorldCoach
extends Control
## The first steps in Ashford (Prologue P1), as the HUD shows them: Bram
## teaches walking, stopping, using and talking in his own words, and the
## Objective line at the top left names the control for the device in hand
## (phone, tablet, computer or controller; it changes if the player picks up
## a pad or a keyboard half-way). It can also put a gold ring, and an arrow,
## round the HUD control a step is about: the pause square ("menu") or the
## round Talk button ("talk"). It never takes a tap: the world behind works.
##
##   var coach := WorldCoach.of(hud)
##   coach.objective("crate")        # "Carry the lantern crate to the green. (Tap the ground to walk.)"
##   coach.light("menu", 2.5)        # the pause square glows for 2.5 s ("glows once")
##   coach.light("talk")             # until coach.light("")

## Each step's Objective (Master Script v3, P1), and the button in brackets
## for each kind of device. The phone's is the script's own.
const OBJECTIVES := {
	"look": ["Choose your look.", {"phone": "(Tap a face to see it in the glass. Tap That's me to keep it.)",
		"tablet": "(Tap a face to see it in the glass. Tap That's me to keep it.)",
		"computer": "(Click a face to see it in the glass. Click That's me to keep it.)",
		"controller": "(Left and right to see each look. Press A to keep it.)"}],
	"crate": ["Carry the lantern crate to the green.", {"phone": "(Tap the ground to walk.)",
		"tablet": "(Tap the ground, or drag, to walk.)", "computer": "(W A S D or the arrow keys to walk, or click the ground.)",
		"controller": "(Left stick to walk.)"}],
	"hook": ["Hang the last lantern on the Great Lantern's pole.", {"phone": "(Walk up to the glowing hook and tap it.)",
		"tablet": "(Walk up to the glowing hook and tap it.)", "computer": "(Walk up to the glowing hook and click it, or press E.)",
		"controller": "(Walk up to the glowing hook and press A.)"}],
	"tam": ["Find Tam at the hay cart.", {"phone": "(Walk up to him and tap Talk.)", "tablet": "(Walk up to him and tap Talk.)",
		"computer": "(Walk up to him and press E, or click Talk.)", "controller": "(Walk up to him and press A.)"}],
	"barrel": ["Carry the barrel to the stall with Tam.", {"phone": "(Tap the stall.)", "tablet": "(Tap the stall.)",
		"computer": "(Click the stall, or press E.)", "controller": "(Press A.)"}],
	"letter": ["Read Tam's letter.", {"phone": "(Tap it.)", "tablet": "(Tap it.)",
		"computer": "(Click it, or press E.)", "controller": "(Press A.)"}],
	"after_tam": ["Duel Corin on the green. Nell's on the bench by the well, if you've time.", {}],
	"bench": ["Sit with Nell.", {"phone": "(Tap the bench.)", "tablet": "(Tap the bench.)",
		"computer": "(Click the bench, or press E.)", "controller": "(Press A.)"}],
	"moth": ["Wake the Lantern Moth.", {"phone": "(Tap the card.)", "tablet": "(Tap the card.)",
		"computer": "(Click the card, or press E.)", "controller": "(Press A.)"}],
}

## How to open the pause menu, in brackets, for Bram's line at the door
## ("{menu}" in a dialogue line, World._fmt): the three lines at the top
## right on a phone or tablet, the key or button elsewhere (Gary, 20
## October: tell the player without breaking the fourth wall).
const MENU_HOW := {
	"phone": "(Tap the three lines at the top right of the screen to open the menu.)",
	"tablet": "(Tap the three lines at the top right of the screen to open the menu.)",
	"computer": "(Press Esc to open the menu.)",
	"controller": "(Press Start to open the menu.)",
}

var hud: WorldHUD
var _key := ""             # the objective showing ("" for none of ours)
var _last_input := ""      # "pad", "keys" or "" (taps and the mouse)
var _what := ""            # the control lit up
var _until := 0.0
var _t := 0.0


## The coach on this HUD (made the first time it's wanted).
static func of(p_hud: WorldHUD) -> WorldCoach:
	for c in p_hud._root.get_children():
		if c is WorldCoach:
			return c
	var wc := WorldCoach.new()
	wc.hud = p_hud
	p_hud._root.add_child(wc)
	return wc


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## What the player is holding: "phone", "tablet", "computer" or "controller".
## A controller counts once it's been used; a keyboard on a tablet makes it
## a computer for the brackets.
func device() -> String:
	if _last_input == "pad":
		return "controller"
	var d := PauseMenu.device_kind()
	if _last_input == "keys" and d != "computer":
		return "computer"
	return d


## The Objective line for a step, with the button for this device.
static func text_for(key: String, dev: String) -> String:
	var o: Array = OBJECTIVES.get(key, [key, {}])
	var how: Dictionary = o[1]
	var b := String(how.get(dev, how.get("phone", "")))
	return String(o[0]) + ((" " + b) if b != "" else "")


## The bracketed way to open the menu on the device in hand.
func menu_hint() -> String:
	return String(MENU_HOW.get(device(), MENU_HOW.phone))


## Shows a step's Objective (kept in the save like any other, so a game
## closed part-way shows it again); "" clears it.
func objective(key: String) -> void:
	_key = key
	var t := text_for(key, device()) if key != "" else ""
	Game.set_flag("objective", t)
	Game.set_flag("objective_key", key)
	hud.set_objective(t)


## Lights up a HUD control ("menu", "talk"; "" for none) for `secs` seconds
## (0 = until told otherwise).
func light(what: String, secs := 0.0) -> void:
	_what = what
	_until = (_t + secs) if secs > 0.0 else 0.0


func _input(e: InputEvent) -> void:
	var was := device()
	if e is InputEventJoypadButton or (e is InputEventJoypadMotion and absf((e as InputEventJoypadMotion).axis_value) > 0.5):
		_last_input = "pad"
	elif e is InputEventKey:
		_last_input = "keys"
	elif e is InputEventScreenTouch or (e is InputEventMouseButton and (e as InputEventMouseButton).pressed):
		_last_input = ""
	else:
		return
	if device() != was and _key != "" and String(Game.flag("objective_key", "")) == _key:
		objective(_key)


func _rect() -> Rect2:
	var c: Control = null
	match _what:
		"menu":
			c = hud._menu_btn
		"talk":
			c = hud._talk
	if c == null or not c.is_visible_in_tree():
		return Rect2()
	return get_global_transform().affine_inverse() * c.get_global_rect()


func _process(delta: float) -> void:
	_t += delta
	if _until > 0.0 and _t > _until:
		_what = ""
		_until = 0.0
	queue_redraw()


## A gold ring round the control, breathing, and a bouncing arrow pointing at it.
func _draw() -> void:
	if _what == "":
		return
	var r := _rect()
	if not r.has_area():
		return
	var glow := 0.55 + 0.45 * sin(_t * 5.0)
	var c := r.get_center()
	var rad := maxf(r.size.x, r.size.y) * 0.5 + 10.0
	draw_arc(c, rad, 0, TAU, 64, Color(UITheme.GOLD, 0.6 + 0.4 * glow), 7.0, true)
	draw_arc(c, rad + 12.0, 0, TAU, 64, Color(UITheme.GOLD, 0.22 * glow), 8.0, true)
	var bob := sin(_t * 6.0) * 12.0
	var w := 30.0
	var h := 36.0
	if c.y > size.y * 0.5:
		var tip := Vector2(c.x, c.y - rad - 18.0 - bob)
		draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-w, -h), tip + Vector2(w, -h)]), UITheme.GOLD)
	else:
		var tip2 := Vector2(c.x, c.y + rad + 18.0 + bob)
		draw_colored_polygon(PackedVector2Array([tip2, tip2 + Vector2(-w, h), tip2 + Vector2(w, h)]), UITheme.GOLD)
