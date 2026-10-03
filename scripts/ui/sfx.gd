class_name Sfx
extends Node
## Sound effects. Each one is a file in assets/sfx/<name>.ogg (or .wav/.mp3);
## extra takes named <name>_2, <name>_3 are picked at random. Until a file
## exists, the sound falls back to a tiny synthesised placeholder (see
## FALLBACK and _synth), or stays silent. The names are listed in the
## "Sound & Music Plan" doc.

## Placeholder used for each named sound until its file arrives ("" = silent).
const FALLBACK := {
	"ui_tap": "click", "ui_select": "select", "ui_back": "click", "ui_error": "", "ui_menu": "click",
	"end_turn": "click", "duel_start": "turn", "turn_mine": "turn", "turn_rival": "turn",
	"card_draw": "card", "card_lift": "select", "card_fly": "card", "card_flip": "card", "shuffle": "",
	"ward_set": "card", "ward_spring": "gift", "rite_cast": "",
	"call_totem": "energy", "ascend": "evolve", "shift": "select", "essence_gain": "",
	"attack_charge": "select", "melee_whoosh": "", "slash": "",
	"cast_fire": "", "cast_storm": "", "cast_tide": "", "cast_verdant": "", "cast_earth": "",
	"cast_metal": "", "cast_psychic": "", "cast_venom": "", "cast_mystic": "",
	"hit_light": "hit", "hit_heavy": "hit", "hit_weak": "hit", "shield_block": "select", "life_hit": "hit",
	"miss": "", "status_burn": "select", "status_poison": "select", "status_stun": "select",
	"status_sleep": "select", "dice_roll": "", "dice_land": "coin", "dice_crit": "gift", "dice_fumble": "lose",
	"summon_boom": "", "gift": "gift", "heal": "heal", "ko": "ko",
}

const RATE := 22050
static var _cache := {}

var volume_db := -8.0
var _players: Array = []


func _ready() -> void:
	for i in 6:
		var p := AudioStreamPlayer.new()
		p.volume_db = volume_db
		add_child(p)
		_players.append(p)


func play(sound: String, pitch: float = 1.0) -> void:
	var stream := get_stream(_take(sound))
	if stream == null:
		return
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = pitch
			p.play()
			return


## True when a real recording exists for this sound.
static func has_file(sound: String) -> bool:
	return _file(sound) != ""


static func _file(sound: String) -> String:
	for ext in ["ogg", "wav", "mp3"]:
		var path := "res://assets/sfx/%s.%s" % [sound, ext]
		if ResourceLoader.exists(path):
			return path
	return ""


## Picks one of the recorded takes (name, name_2, name_3...) at random.
static func _take(sound: String) -> String:
	if not has_file(sound + "_2"):
		return sound
	var takes := [sound]
	var i := 2
	while has_file("%s_%d" % [sound, i]):
		takes.append("%s_%d" % [sound, i])
		i += 1
	return takes[randi() % takes.size()]


static func get_stream(sound: String) -> AudioStream:
	if _cache.has(sound):
		return _cache[sound]
	var s: AudioStream = null
	var path := _file(sound)
	if path != "":
		s = load(path)
	elif FALLBACK.has(sound):
		var fb: String = FALLBACK[sound]
		s = null if fb == "" else get_stream(fb)
	else:
		s = _synth(sound)
	_cache[sound] = s
	return s


static func _synth(sound: String) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	match sound:
		"card":
			samples = _noise(0.09, 0.35, 4000.0)
		"click":
			samples = _tone([[1400.0, 0.03]], 0.25, "sine")
		"hit":
			samples = _mix(_sweep(220.0, 55.0, 0.22, 0.8, "sine"), _noise(0.12, 0.45, 1500.0))
		"coin":
			samples = _tone([[1318.5, 0.07], [1760.0, 0.22]], 0.35, "sine")
		"ko":
			samples = _sweep(520.0, 90.0, 0.45, 0.35, "square")
		"heal":
			samples = _tone([[523.3, 0.07], [659.3, 0.07], [784.0, 0.16]], 0.3, "sine")
		"energy":
			samples = _sweep(400.0, 900.0, 0.12, 0.3, "sine")
		"turn":
			samples = _tone([[784.0, 0.1], [1046.5, 0.25]], 0.25, "tri")
		"win":
			samples = _tone([[523.3, 0.12], [659.3, 0.12], [784.0, 0.12], [1046.5, 0.45]], 0.35, "tri")
		"lose":
			samples = _tone([[392.0, 0.18], [311.1, 0.18], [261.6, 0.5]], 0.35, "tri")
		"evolve":
			samples = _sweep(300.0, 1200.0, 0.4, 0.3, "tri")
		"summon":
			samples = _mix(_sweep(110.0, 880.0, 0.9, 0.35, "tri"), _noise(0.9, 0.25, 900.0))
		"gift":
			samples = _tone([[659.3, 0.1], [987.8, 0.1], [1318.5, 0.1], [1975.5, 0.5]], 0.28, "sine")
		"select":
			samples = _tone([[1046.5, 0.04]], 0.18, "sine")
		_:
			samples = _tone([[880.0, 0.05]], 0.2, "sine")
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w


static func _osc(kind: String, phase: float) -> float:
	match kind:
		"square":
			return 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
		"tri":
			return 4.0 * absf(fmod(phase, 1.0) - 0.5) - 1.0
	return sin(phase * TAU)


static func _env(t: float, dur: float) -> float:
	var attack := minf(0.005, dur * 0.2)
	if t < attack:
		return t / attack
	return pow(1.0 - (t - attack) / maxf(0.0001, dur - attack), 2.0)


static func _tone(notes: Array, vol: float, kind: String) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for n in notes:
		var f: float = n[0]
		var dur: float = n[1]
		var count := int(dur * RATE)
		var phase := 0.0
		for i in count:
			var t := float(i) / RATE
			phase += f / RATE
			out.append(_osc(kind, phase) * _env(t, dur) * vol)
	return out


static func _sweep(f0: float, f1: float, dur: float, vol: float, kind: String) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var count := int(dur * RATE)
	var phase := 0.0
	for i in count:
		var t := float(i) / RATE
		var f := lerpf(f0, f1, t / dur)
		phase += f / RATE
		out.append(_osc(kind, phase) * _env(t, dur) * vol)
	return out


static func _noise(dur: float, vol: float, cutoff: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var count := int(dur * RATE)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var a := clampf(cutoff / RATE * TAU, 0.0, 1.0)
	var y := 0.0
	for i in count:
		y += a * (rng.randf_range(-1.0, 1.0) - y)
		out.append(y * _env(float(i) / RATE, dur) * vol * 2.5)
	return out


static func _mix(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for i in maxi(a.size(), b.size()):
		var v := 0.0
		if i < a.size():
			v += a[i]
		if i < b.size():
			v += b[i]
		out.append(v)
	return out
