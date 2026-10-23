class_name SummonVideo
extends Control
## Gary's clips for a Summon or a Totem called (23 October: "a video that
## plays when you summon: the first time you summon that character it plays
## a longer video, after that just a brief one, or a toggle"). A card has a
## clip when assets/movies/summons/<card id>_full.ogv or _short.ogv exists
## (Theora, for the phone link and the editor; made from his masters with
## the ffmpeg line in the README), or when the apps carry his masters as
## <card id>_full.mp4 / _short.mp4 on the "films" release, played by the
## native player (NativeVideoPlayer) as the opening film is. The first time
## a card is called or summoned in a save its full clip plays; every time
## after, the short one (whichever of the two exists). Options and the
## duel's Menu set "Summon videos: Full / Short / Off"
## (Game.settings.summon_videos): Short always plays the short one, Off plays
## none (the SummonCine as before). A tap skips. On the web each card's
## clips are their own pack (tools/web_packs.py: summon_<id>), fetched the
## first time that card is summoned, with a loading bar that can be skipped.
## A card with no clip keeps the SummonCine.

const DIR := "res://assets/movies/summons/"
const SETTING := "summon_videos"
const MODES := ["full", "short", "off"]
const MODE_NAMES := {"full": "Full", "short": "Short", "off": "Off"}
## NativeVideoPlayer.poll()'s events, as native_video_player.h numbers them
const NV_TAPPED := 1
const NV_SKIP_PRESSED := 2
const NV_FINISHED := 4
const NV_FAILED := 8
const READY_SECS := 4.0
## For the tests: card ids that count as having both clips (nothing plays).
static var stub_clips: Array = []

var _done := false


static func mode() -> String:
	var m := String(Game.settings.get(SETTING, "full"))
	return m if m in MODES else "full"


static func set_mode(m: String) -> void:
	Game.settings[SETTING] = m if m in MODES else "full"
	Game.save_settings()


## The native player (the apps), or null.
static func _native():
	if ClassDB.class_exists("NativeVideoPlayer"):
		return ClassDB.instantiate("NativeVideoPlayer")
	return null


## Whether a card has this clip anywhere it could play from: Theora in the
## project, a web pack not fetched yet, or a master in the apps' films.
static func has_clip(card_id: String, kind: String) -> bool:
	if stub_clips.has(card_id):
		return true
	var name := "%s_%s" % [card_id, kind]
	if ResourceLoader.exists(DIR + name + ".ogv"):
		return true
	if Packs.in_build("summon_" + card_id):
		return true
	var p = _native()
	if p == null:
		return false
	var found: bool = p.find_file(name + ".mp4") != ""
	if p is Node:
		(p as Node).queue_free()
	return found


## Has this card's clip been seen in this save?
static func seen(card_id: String) -> bool:
	return bool((Game.v2.get("summon_seen", {}) as Dictionary).get(card_id, false))


static func mark_seen(card_id: String) -> void:
	if not Game.v2.has("summon_seen"):
		Game.v2["summon_seen"] = {}
	Game.v2["summon_seen"][card_id] = true


## Which clip plays for this card now: "full", "short", or "" for none.
static func pick(card_id: String) -> String:
	var m := mode()
	if m == "off":
		return ""
	var want := "short" if (m == "short" or seen(card_id)) else "full"
	var other := "short" if want == "full" else "full"
	for kind in [want, other]:
		if has_clip(card_id, kind):
			return kind
	return ""


## Plays the card's clip over `parent` (the duel's overlay), the music
## dipped under it, and returns when it ends or is tapped. The card is
## marked seen whether it was watched out or skipped.
static func play(parent: Control, card_id: String) -> void:
	var kind := pick(card_id)
	if kind == "":
		return
	mark_seen(card_id)
	if stub_clips.has(card_id):
		return
	var pack := "summon_" + card_id
	if Packs.in_build(pack) and not Packs.has(pack):
		if not await Packs.need(pack, true):
			return
		# now the pack's own clips can be seen, they decide
		if not ResourceLoader.exists(DIR + "%s_%s.ogv" % [card_id, kind]):
			kind = "short" if kind == "full" else "full"
			if not ResourceLoader.exists(DIR + "%s_%s.ogv" % [card_id, kind]):
				return
	var sv := SummonVideo.new()
	sv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sv.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(sv)
	await sv._run("%s_%s" % [card_id, kind])
	sv.queue_free()


func _gui_input(e: InputEvent) -> void:
	if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
		_done = true
		accept_event()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("interact") or e.is_action_pressed("ui_accept") or e.is_action_pressed("ui_cancel"):
		_done = true
		get_viewport().set_input_as_handled()


## The clip itself: the native player when it has the master, else the
## Theora copy in a VideoStreamPlayer over black.
func _run(name: String) -> void:
	var p = _native()
	var path: String = p.find_file(name + ".mp4") if p != null else ""
	if path != "" and p.open(path):
		p.set_volume(1.0)
		p.play()
		var waited := 0.0
		while not p.is_ready() and not p.has_failed() and waited < READY_SECS and not _done:
			await get_tree().process_frame
			waited += get_process_delta_time()
		Music.duck(maxf(float(p.get_length()), 2.0))
		while not _done and not p.has_failed():
			var ev: int = p.poll()
			if ev & (NV_FINISHED | NV_FAILED | NV_TAPPED | NV_SKIP_PRESSED):
				break
			await get_tree().process_frame
		p.stop()
		if p is Node:
			(p as Node).queue_free()
		return
	if p is Node:
		(p as Node).queue_free()
	var file := DIR + name + ".ogv"
	if not ResourceLoader.exists(file):
		return
	var stream = load(file)
	if not (stream is VideoStream):
		return
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(black)
	var vp := VideoStreamPlayer.new()
	vp.stream = stream
	vp.expand = true
	vp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vp)
	vp.play()
	Music.duck(maxf(vp.get_stream_length(), 2.0))
	# (a frame for it to start, so is_playing() is true)
	await get_tree().process_frame
	while not _done and vp.is_playing():
		await get_tree().process_frame
	vp.stop()
