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
## For the tests: ids that count as recorded, with their length (s), and
## (stub_env) how loud each is, as envelopes.json has it.
static var stub: Dictionary = {}
static var stub_env: Dictionary = {}

## How loud each recording is, sixty times a second (0..100), for the mouths
## (18 November, Gary's yes: "make mouths open in time with the actual voice
## lines, wider on louder words"): written by tools/vo_envelopes.py
## (tools/vo_master.py runs it when it puts recordings in place).
const ENVELOPES := DIR + "envelopes.json"
static var _envs := {}
static var _env_rate := 60.0
static var _envs_read := false
## The line playing now: {"t0": when it began (ms, the clock), "env": its
## loudness, "rate": values a second, "who": its speaker}; {} when none.
static var now: Dictionary = {}


## A recording's loudness (an Array of 0..100), or [] if it's not been read.
static func envelope(path: String) -> Array:
	if not _envs_read:
		_envs_read = true
		if FileAccess.file_exists(ENVELOPES):
			var d = JSON.parse_string(FileAccess.get_file_as_string(ENVELOPES))
			if d is Dictionary:
				_env_rate = float(d.get("rate", 60.0))
				_envs = d.get("lines", {})
	var e = _envs.get(path, [])
	return e if e is Array else []


## How open a mouth should be for a voice now (0..1), or -1 once the
## recording is over (or there's none to go by). The sound reaches the ear
## the output's latency after it's played; lips move a breath before the
## sound they make: both counted.
const LIPS_LEAD := 0.05
static func level_of(v: Dictionary) -> float:
	var e: Array = v.get("env", [])
	if e.is_empty():
		return -1.0
	var t := (Time.get_ticks_msec() - int(v.get("t0", 0))) / 1000.0 - AudioServer.get_output_latency() + LIPS_LEAD
	var f := t * float(v.get("rate", 60.0))
	if f < 0.0:
		return 0.0
	var i := int(f)
	if i >= e.size() - 1:
		return -1.0 if i >= e.size() else float(e[i]) / 100.0
	return lerpf(float(e[i]), float(e[i + 1]), f - i) / 100.0


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
	now = {}
	if stub.has(stem):
		now = {"t0": Time.get_ticks_msec(), "env": stub_env.get(stem, []), "rate": 60.0, "who": who}
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
	now = {"t0": Time.get_ticks_msec(), "env": envelope(path), "rate": _env_rate, "who": who}
	return float((stream as AudioStream).get_length()) + TAIL


## Stops the line's recording (the line was tapped past).
static func stop(host: Node) -> void:
	now = {}
	if host.has_meta("voice_player"):
		var ap = host.get_meta("voice_player")
		if ap != null and is_instance_valid(ap):
			(ap as AudioStreamPlayer).stop()
			(ap as AudioStreamPlayer).queue_free()
		host.remove_meta("voice_player")
