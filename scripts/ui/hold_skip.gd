class_name HoldSkip
extends Node
## Press and hold to skip, for any Skip button (12 November, Gary's yes to
## "hold to skip on the other story films too, so every film skips the same
## way" as the opening movie, OpeningMovie): the button reads "Hold to skip"
## and fills with gold while it's held; a second's hold (OpeningMovie.HOLD_SECS)
## emits `done`. A tap does nothing. Held keys count too when `keys` is on (E,
## A, a click: the "interact" action), and the device's own player's label
## while it covers the view (`native`: NativeVideoPlayer's is_skip_held and
## set_skip_progress; one built before those skips on a tap, NV_SKIP_PRESSED,
## which the film handles). `on` false lets go of it (under a choice).
##
##   var hs := HoldSkip.attach(button)
##   hs.done.connect(skip)

signal done

const TEXT := "Hold to skip"
const FILL := Color(0.93, 0.8, 0.47, 0.4)

var btn: Button
var keys := true
var on := true
var native = null
var _down := false
var _t := 0.0
var _fill: ColorRect


## Makes `b` a hold-to-skip button: its text, the fill, the hold.
static func attach(b: Button, with_keys := true) -> HoldSkip:
	var h := HoldSkip.new()
	h.name = "HoldSkip"
	h.btn = b
	h.keys = with_keys
	b.text = TEXT
	b.button_down.connect(func() -> void: h._down = true)
	b.button_up.connect(func() -> void: h._down = false)
	h._fill = ColorRect.new()
	h._fill.color = FILL
	h._fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h._fill.size = Vector2.ZERO
	b.add_child(h._fill)
	b.add_child(h)
	return h


## How far the hold has got (0 to 1).
func progress() -> float:
	return clampf(_t / OpeningMovie.HOLD_SECS, 0.0, 1.0)


func _native_holds() -> bool:
	return native != null and native.has_method("is_skip_held")


func _process(delta: float) -> void:
	var held := false
	if on:
		if btn != null and btn.is_visible_in_tree():
			held = _down
		if keys:
			held = held or Input.is_action_pressed("interact")
		if _native_holds():
			held = held or bool(native.is_skip_held())
	if held:
		_t += delta
	else:
		_t = 0.0
		_down = _down and on
	var k := progress()
	if _fill != null and btn != null:
		_fill.size = Vector2(btn.size.x * k, btn.size.y)
	if _native_holds():
		native.set_skip_progress(k)
	if _t >= OpeningMovie.HOLD_SECS:
		_t = 0.0
		_down = false
		done.emit()
