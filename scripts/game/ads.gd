extends Node
## Autoload "Ads": every advert in the game goes through here, so the rules
## for when they appear live in one place.
##
## Where adverts appear, and nowhere else:
##   * Before a duel: one full-screen advert, at most once every
##     DUELS_BETWEEN duels and never within MIN_GAP seconds of the last one.
##     None during the Prologue (it's the tutorial), none before the first
##     duel after the game opens, and none before a duel marked "no_ads"
##     (a boss's first attempt, say).
##   * Retrying a lost duel counts as a duel, so a retry can bring one round,
##     but retrying itself is always free.
##   * After a story win, an advert the player chooses to watch doubles that
##     win's Resonance, up to REWARDED_PER_DAY times a day.
## No banners, and nothing in the middle of a duel, a conversation or a menu.
##
## Until the AdMob plugin goes into the phone builds (see "Adverts" in the
## README), a clearly labelled placeholder shows where each advert would go,
## so the timing can be judged in play. Turn previews off in Options.

signal ad_finished(kind: String, completed: bool)

const DUELS_BETWEEN := 3
const MIN_GAP := 300.0          # seconds between full-screen adverts
const REWARDED_PER_DAY := 3
const PLACEHOLDER_SECONDS := 4.0
const REWARDED_SECONDS := 6.0

var _duels_since := 0
var _last_ad_time := -1.0e9
var _first_duel_done := false


## Call before every duel (and before a retry). Shows an advert if one is due.
func before_duel(spec: Dictionary, is_retry := false) -> void:
	var due := _duel_ad_due(spec, is_retry)
	if not due:
		return
	_duels_since = 0
	_last_ad_time = _now()
	await _show("interstitial")


func _duel_ad_due(spec: Dictionary, _is_retry: bool) -> bool:
	if not spec.get("story", false) or spec.get("no_ads", false):
		return false
	if not Game.flag("beat_hunter"):
		return false      # the Prologue teaches the game: no adverts in it
	if not _first_duel_done:
		_first_duel_done = true
		return false
	_duels_since += 1
	if _duels_since < DUELS_BETWEEN:
		return false
	return _now() - _last_ad_time >= MIN_GAP


## True when the "watch an advert to double this win" offer can be made.
func can_offer_rewarded() -> bool:
	if _real_network() == null and not bool(Game.settings.get("ad_previews", true)):
		return false
	var st := _state()
	if String(st.get("day", "")) != _today():
		return true
	return int(st.get("used", 0)) < REWARDED_PER_DAY


func rewarded_left_today() -> int:
	var st := _state()
	if String(st.get("day", "")) != _today():
		return REWARDED_PER_DAY
	return maxi(0, REWARDED_PER_DAY - int(st.get("used", 0)))


## Plays an advert the player chose to watch; true if it was watched to the
## end (only then is the reward given).
func rewarded(_reason: String) -> bool:
	if not can_offer_rewarded():
		return false
	var done: bool = await _show("rewarded")
	if done:
		var st := _state()
		if String(st.get("day", "")) != _today():
			st = {"day": _today(), "used": 0}
		st["used"] = int(st.get("used", 0)) + 1
		Game.settings["ads_rewarded"] = st
		Game.save_settings()
	return done


func _state() -> Dictionary:
	var st = Game.settings.get("ads_rewarded", {})
	return st if st is Dictionary else {}


func _today() -> String:
	return Time.get_date_string_from_system()


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


## Shows one advert: the real network's when the plugin is in, otherwise the
## placeholder (or nothing, with previews off). Returns true when completed.
func _show(kind: String) -> bool:
	var real := _real_network()
	if real != null:
		# The AdMob plugin's interstitial / rewarded calls go here once it is
		# added to the iOS and Android builds.
		pass
	if not bool(Game.settings.get("ad_previews", true)):
		ad_finished.emit(kind, true)
		return true
	var layer := CanvasLayer.new()
	layer.layer = 60
	add_child(layer)
	var card := AdPlaceholder.new()
	card.kind = kind
	card.seconds = REWARDED_SECONDS if kind == "rewarded" else PLACEHOLDER_SECONDS
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.theme = UITheme.make()
	layer.add_child(card)
	var completed: bool = await card.closed
	layer.queue_free()
	ad_finished.emit(kind, completed)
	return completed


## The ad network, when its plugin is installed in this build; null otherwise.
func _real_network() -> Object:
	return null


## Stands in for an advert: says what kind would play here and counts down.
class AdPlaceholder:
	extends Control
	signal closed(completed: bool)
	var kind := "interstitial"
	var seconds := 4.0
	var _t := 0.0
	var _btn: Button
	var _count: Label

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		var bg := ColorRect.new()
		bg.color = Color(0.02, 0.02, 0.04, 0.97)
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(bg)
		var box := VBoxContainer.new()
		box.set_anchors_preset(Control.PRESET_CENTER)
		box.offset_left = -560
		box.offset_right = 560
		box.offset_top = -260
		box.offset_bottom = 260
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_theme_constant_override("separation", 22)
		add_child(box)
		var tag := UITheme.label("ADVERT", 30, UITheme.TEXT_DIM, "bold")
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(tag)
		var head := UITheme.label("A real advert plays here" if kind == "interstitial" else "A rewarded advert plays here", 52, UITheme.GOLD, "display_bold")
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(head)
		var why := UITheme.label("Placeholder for this early build. Adverts help keep The Covenant War free." if kind == "interstitial"
			else "Watched to the end, it doubles the Resonance from this win.", 30, UITheme.TEXT)
		why.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		why.custom_minimum_size = Vector2(1000, 0)
		box.add_child(why)
		_count = UITheme.label("", 30, UITheme.TEXT_DIM)
		_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(_count)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 24)
		box.add_child(row)
		if kind == "rewarded":
			var stop := UITheme.button("Stop watching", false, 320)
			stop.pressed.connect(func() -> void: closed.emit(false))
			row.add_child(stop)
		_btn = UITheme.button("Close" if kind == "interstitial" else "Claim reward", true, 320)
		_btn.disabled = true
		_btn.pressed.connect(func() -> void: closed.emit(true))
		row.add_child(_btn)

	func _process(delta: float) -> void:
		_t += minf(delta, 0.1)   # a stalled frame doesn't eat the countdown
		var left := ceili(seconds - _t)
		if left > 0:
			_count.text = "You can close this in %d" % left if kind == "interstitial" else "Reward in %d" % left
		else:
			_count.text = ""
			if _btn.disabled:
				_btn.disabled = false
				_btn.grab_focus()
