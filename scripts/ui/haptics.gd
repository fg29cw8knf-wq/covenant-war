class_name Haptics
## The phone shaking in the hand (14 November, Gary's yes to "the phone
## shaking in the hand on big blows and the Last Page"): a short buzz from
## the phone's own motor at the moments that should be felt as well as seen.
## Only a phone has one: on a Mac this does nothing. Off with "Vibration" in
## Settings (Game.settings["vibration"]).
##
## So far only the Night of the White Sky asks for it (WhiteSky): a big blow,
## a Totem broken, Bram driven to his knee, the Last Page landing.

## A light tap, a blow, and the heaviest (ms, strength 0..1).
const TAP := [18, 0.45]
const BLOW := [45, 0.75]
const HEAVY := [90, 1.0]
const LONG := [320, 1.0]

## Every buzz asked for, whether or not this machine can make it (the
## tests read it): how many, and the last one's [ms, strength].
static var count := 0
static var last: Array = [0, 0.0]


static func on() -> bool:
	return bool(Game.settings.get("vibration", true))


## Whether this machine has a motor to shake (the iPhone/iPad app, Android;
## `-- --phone` on a computer counts, so the Settings switch can be looked at).
static func can() -> bool:
	return Gfx.is_phone()


static func buzz(ms: int, strength := 1.0) -> void:
	if not on():
		return
	count += 1
	last = [ms, strength]
	if can():
		Input.vibrate_handheld(maxi(1, ms), clampf(strength, 0.05, 1.0))


## One of the kinds above: Haptics.kind(Haptics.BLOW).
static func kind(k: Array) -> void:
	buzz(int(k[0]), float(k[1]))
