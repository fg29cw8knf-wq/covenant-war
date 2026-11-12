class_name Ambience
extends Node
## A quiet bed of sound for the place on screen, under its music (12
## November, Gary: "Yes re sound effects", to "a quiet background sound for
## each place: the taproom's fire, birds and voices on the green, the
## Thornwood at night"). Each bed is a loop in assets/sfx (amb_<name>.ogg,
## made by tools/make_ambience.py; a recording saved under the same name is
## used instead).
##
## Nothing has to start or stop one. A few times a second the player asks
## whichever world is showing what its place sounds like (World.ambience(),
## which asks its area: Ashford.ambience_at and the others, by where the
## camera is looking, the time of day and what's burning) and eases to that
## bed, or to silence: so a duel (the world hidden behind it), the title
## screen, a world still being got ready, and a film (StoryFilm counts
## itself into `hush`) are all quiet without being told.

const DB := -6.0        # how loud a bed plays (it is recorded quiet as well: see the tool's LOUD)
const FADE := 1.8       # seconds a bed takes to come in, or to go
const CHECK := 0.35     # seconds between asking what the place sounds like
const GROUP := "worlds"

static var _me: Ambience
## Things with a soundtrack of their own count themselves in here while
## they play (StoryFilm): no bed while it's above 0.
static var hush := 0

var _slots: Array = []   # [{p: AudioStreamPlayer, name, gain, want}]
var _bed := ""
var _t := 0.0


## Made once, as the game starts (Game._ready), under the root.
static func start(tree: SceneTree) -> void:
	if is_instance_valid(_me):
		return
	_me = Ambience.new()
	_me.name = "Ambience"
	_me.process_mode = Node.PROCESS_MODE_ALWAYS   # (the place is still heard behind the pause menu)
	tree.root.add_child.call_deferred(_me)


## The bed playing, or coming in, now ("" for none).
static func bed() -> String:
	return _me._bed if is_instance_valid(_me) else ""


## How loud the bed named is right now, 0 to 1 (the tests).
static func gain_of(nm: String) -> float:
	if is_instance_valid(_me):
		for s: Dictionary in _me._slots:
			if String(s.name) == nm:
				return float(s.gain)
	return 0.0


func _ready() -> void:
	for i in 3:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_slots.append({"p": p, "name": "", "gain": 0.0, "want": 0.0})


func _process(delta: float) -> void:
	_t -= delta
	if _t <= 0.0:
		_t = CHECK
		var want := wanted()
		if want != _bed:
			_switch(want)
	var level := DB + linear_to_db(maxf(0.001, float(Game.settings.get("sfx", 0.9)) / 0.9))
	for s: Dictionary in _slots:
		var p: AudioStreamPlayer = s.p
		s.gain = move_toward(float(s.gain), float(s.want), delta / FADE)
		if float(s.gain) <= 0.0:
			if p.playing:
				p.stop()
			continue
		p.volume_db = level + linear_to_db(maxf(0.001, float(s.gain)))


## What the place on screen sounds like now: the bed's name, "" for silence.
func wanted() -> String:
	if hush > 0:
		return ""
	var best := ""
	for w in get_tree().get_nodes_in_group(GROUP):
		if w is World:
			var b := (w as World).ambience()
			if b != "":
				best = b
	return best if best == "" or Sfx.has_file(best) else ""


func _switch(nm: String) -> void:
	_bed = nm
	for s: Dictionary in _slots:
		s.want = 0.0
	if nm == "":
		return
	# the slot that still has it (going out: it turns round), else the quietest
	var slot: Dictionary = {}
	for s: Dictionary in _slots:
		if String(s.name) == nm and float(s.gain) > 0.0:
			slot = s
	if slot.is_empty():
		for s: Dictionary in _slots:
			if slot.is_empty() or float(s.gain) < float(slot.gain):
				slot = s
		var stream := loop_of(nm)
		if stream == null:
			return
		var p: AudioStreamPlayer = slot.p
		p.stop()
		p.stream = stream
		p.volume_db = -80.0
		slot.name = nm
		slot.gain = 0.0
		# (not always from its first second: a place come back to isn't the same bird again)
		p.play(randf() * maxf(0.0, stream.get_length() - 1.0))
	slot.want = 1.0


## A bed's sound, set to go round.
static func loop_of(nm: String) -> AudioStream:
	var path := Sfx._file(nm)
	if path == "":
		return null
	var s: AudioStream = load(path)
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = true
	elif s is AudioStreamMP3:
		(s as AudioStreamMP3).loop = true
	elif s is AudioStreamWAV:
		var wv := s as AudioStreamWAV
		wv.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wv.loop_begin = 0
		wv.loop_end = int(wv.get_length() * wv.mix_rate)
	return s
