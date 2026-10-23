class_name VoiceLines
extends RefCounted
## Gary's voices for the cutscenes and the conversations (23 October: "what
## if we used actual voices instead of just text? Then people wouldn't have
## to click through unless they wanted to skip"). Every line the game says
## (Cine.say, a conversation step) has a stable id: the first eight hex
## digits of the sha1 of its words as written in the script (before the
## player's name is filled in, one space between words). A recording dropped
## in as assets/audio/vo/<area>/<speaker>/<id>.ogg (or .mp3, .wav; the area
## is ashford, thornwood or solhaven, so the web packs can carry Solhaven's
## apart) plays with the line, which holds for its length and moves on by
## itself, a tap skipping it. With no recording the line waits for a tap as
## before. A step can name its recording outright with "vo": "<file>" (the
## Herald's and Solmaris's are named that way already, in the vo folder's
## root). tools/vo_sheet.py writes every line with its id, speaker and area
## to docs/script/vo_lines.md and .csv for recording; tools/vo_master.py
## --lines levels the recordings and puts them in place by id.

const DIR := "res://assets/audio/vo/"
const AREAS := ["ashford", "thornwood", "solhaven"]
const EXTS := ["ogg", "mp3", "wav"]
const TAIL := 0.35   # s the line stays up after the voice ends
## For the tests: ids that count as recorded, with their length (s).
static var stub: Dictionary = {}


## The words as the sheet writes them: trimmed, one space between words.
static func normalise(text: String) -> String:
	var re := RegEx.create_from_string("\\s+")
	return re.sub(text.strip_edges(), " ", true)


static func line_id(text: String) -> String:
	return normalise(text).sha1_text().left(8)


## A film's stand-in for someone (an extra at the gate, on the roof) speaks
## with their voice: its folder is the person's.
const PERSON := {"film_wren": "wren", "hale_gate": "hale", "hale_yard": "hale", "aldric_roof": "aldric",
	"aldric_court": "aldric", "liora_hall": "liora", "gate_ysa": "ysa", "pip_roof": "pip", "player": "narrator"}


## The speaker's folder: a figure's id, "narrator" for narration.
static func speaker_of(who: String) -> String:
	if who == "":
		return "narrator"
	return String(PERSON.get(who, who))


## On the web, Ashford's and Thornwood's voices come as a pack of their own
## (tools/web_packs.py; Solhaven's ride in Solhaven's), fetched quietly as
## the world starts; a line said before it has come plays without its voice.
static func warm() -> void:
	if Packs.in_build("voices"):
		Packs.want("voices")


## The recording for this line, or "".
static func file_for(who: String, text: String, vo := "") -> String:
	var speaker := speaker_of(who)
	var stem := vo if vo != "" else line_id(text)
	for area in AREAS:
		for ext in EXTS:
			var p := "%s%s/%s/%s.%s" % [DIR, area, speaker, stem, ext]
			if ResourceLoader.exists(p):
				return p
	if vo != "":
		for ext in EXTS:
			if ResourceLoader.exists(DIR + vo + "." + ext):
				return DIR + vo + "." + ext
	return ""


## Plays the line's recording from `host` if there is one, and returns how
## long the line should stay up (s): the recording's length and a breath.
## -1 when there's no recording.
static func play(host: Node, who: String, text: String, vo := "") -> float:
	var stem := vo if vo != "" else line_id(text)
	if stub.has(stem):
		return float(stub[stem]) + TAIL
	var path := file_for(who, text, vo)
	if path == "":
		return -1.0
	var stream = load(path)
	if not (stream is AudioStream):
		return -1.0
	stop(host)
	var ap := AudioStreamPlayer.new()
	ap.stream = stream
	if AudioServer.get_bus_index("Voice") >= 0:
		ap.bus = "Voice"
	host.add_child(ap)
	ap.play()
	ap.finished.connect(ap.queue_free)
	host.set_meta("voice_player", ap)
	return float((stream as AudioStream).get_length()) + TAIL


## Stops the line's recording (the line was tapped past).
static func stop(host: Node) -> void:
	if host.has_meta("voice_player"):
		var ap = host.get_meta("voice_player")
		if ap != null and is_instance_valid(ap):
			(ap as AudioStreamPlayer).stop()
			(ap as AudioStreamPlayer).queue_free()
		host.remove_meta("voice_player")
