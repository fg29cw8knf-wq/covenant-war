class_name Sfx
extends Node
## Sound effects. Each one is a file in assets/sfx/<name>.ogg (or .wav/.mp3);
## extra takes named <name>_2, <name>_3 are picked at random. Until a file
## exists, the sound falls back to a tiny synthesised placeholder (see
## FALLBACK and _synth), or stays silent. The names are listed in the
## "Sound & Music Plan" doc.
##
## Creatures have voices (12 November, Gary: "adding the sound effect to the
## game and cards and creatures is good implement that"): cry() plays a
## creature's own recording (cry_<its id>), else the stand-in for its kind
## (cry_hound, cry_fox...: VOICE_OF, made by tools/make_cries.py), pitched by
## its size and by the moment. And every button in the game clicks
## (watch_buttons, shared).

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
	"cast_frost": "", "cast_wind": "",
	# (12 November: the elements with no cast of their own borrowed a test beep)
	"cast_astral": "cast_mystic", "cast_radiant": "cast_mystic", "cast_spirit": "cast_mystic", "cast_umbral": "cast_psychic",
	"hit_light": "hit", "hit_heavy": "hit", "hit_weak": "hit", "shield_block": "select", "life_hit": "hit",
	"miss": "", "status_burn": "select", "status_poison": "select", "status_stun": "select",
	"status_sleep": "select", "dice_roll": "", "dice_land": "coin", "dice_crit": "gift", "dice_fumble": "lose",
	"summon_boom": "", "gift": "gift", "heal": "heal", "ko": "ko",
}

const RATE := 22050
static var _cache := {}
static var _files := {}   # sound name -> its file's path ("" for none)

# --- creature voices ----------------------------------------------------------
## The stand-in voice of each family (DuelSynergy.FAMILY_OF) ...
const VOICE_OF_FAMILY := {
	"hound": "hound", "fox": "fox", "cat": "cat", "winged": "sprite",
	"scaled": "serpent", "shell": "shell", "stoneborn": "stone",
}
## ... and of each creature that has no family, or doesn't sound like its
## family: [kind, pitch] (the pitch is on top of its size's: SIZE_PITCH).
## A Summon has no kind: each has a cry of its own (cry_<id>, made by
## tools/make_cries.py as the kinds' are), heard as it lands.
const VOICE_OF := {
	"stormcaller": ["bird", 1.0], "somnowl": ["owl", 1.0], "runeowl": ["owl", 0.92],
	"ashen_drake": ["drake", 1.3], "deepmaw": ["drake", 1.0],
	"blightrat": ["rodent", 1.0], "burrowmole": ["rodent", 0.74],
	"briar_colossus": ["wood", 1.0], "elderbark": ["wood", 0.9], "thornwarden": ["wood", 1.05],
	"mossling": ["sprite", 0.8], "emberwisp": ["sprite", 1.0],
	"mirewidow": ["shell", 1.25], "glyph_warden": ["stone", 1.0],
	"rimecub": ["beast", 1.4], "thunder_ram": ["beast", 1.05], "thought_eater": ["beast", 0.9],
	"scrivener": ["astral", 1.0], "loomwarden": ["astral", 0.88], "unspent_hour": ["astral", 1.12],
	"sunlance_seraph": ["astral", 1.2], "weft_serpent": ["serpent", 1.0],
}
## The moments a creature is heard at, and how each moves a cry that has no
## recording of its own for it (cry_<name>_attack...): the pitch, and the
## loudness in dB. A hurt cry is only asked for on a heavy blow.
const CRY_WHEN := {
	"call": [1.0, 0.0], "attack": [1.1, -4.0], "hurt": [1.18, -5.0], "ko": [0.78, -1.0],
}
## Sounds used for a moment until its own file exists: a Hound that is hurt
## or falls whines (Gary's hound_whine).
const CRY_ALIAS := {"cry_hound_hurt": "hound_whine", "cry_hound_ko": "hound_whine"}
## A stand-in is one cry for every creature of its kind, so its pitch goes by
## the creature's size: its Health (a Cinderpup's 70 high, a Warg's 200 low).
const SIZE_PITCH := [1.42, 280.0, 0.72, 1.24]   # (pitch at no Health, Health per whole step down, least, most)
const CRY_DB := -3.0   # (a voice sits just under the blows and the spells)
const CRY_PITCH := [0.56, 1.9]   # (no cry slower or faster than this, whatever its size and moment)

## Footsteps (12 November, Gary: "Do the footsteps"): step(), one sound for
## each kind of ground (step_snow, step_grass, step_dirt, step_wood,
## step_stone, each with a few takes), a little different every time, and
## quieter the further the walker is from the camera.
const STEP_DB := -7.0       # (a step sits well under everything else: there are a lot of them)
const STEP_RUN_DB := 1.5    # ...a running one a touch harder
const STEP_NEAR := 14.0     # the world's camera stands this far (m) from the player: full loudness from here in
const STEP_FAR_DB := 18.0   # a walker so far off that their step would be this much quieter isn't heard
const STEP_ELSE := "dirt"   # the ground used for one that has no sound of its own

## One player for sounds that belong to no screen (a button's click, a card
## turned over in the Codex): shared(). And one for footsteps (steps()), so
## a run across the green never takes a button's click.
static var _shared: Sfx
static var _steps: Sfx
static var _last_msec := -1000
static var clicks := 0   # (how many button clicks have been played: for the tests)
static var listen := false   # (the tests: every sound played is noted in `heard`, [frame, name, pitch])
static var heard: Array = []

var volume_db := -8.0
var _players: Array = []
## Whether a sound from this player counts as a press's own sound (a button
## that has one doesn't click as well: _click). Footsteps don't.
var marks_press := true


func _init() -> void:
	# (a menu's sounds are heard while the game is paused behind it)
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	if not _players.is_empty():
		return
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.volume_db = volume_db
		add_child(p)
		_players.append(p)


func play(sound: String, pitch: float = 1.0, gain_db: float = 0.0) -> void:
	var stream := get_stream(_take(sound))
	if stream == null:
		return
	if marks_press:
		_last_msec = Time.get_ticks_msec()
	if listen:
		heard.append([Engine.get_process_frames(), sound, pitch])
	var level := linear_to_db(maxf(0.001, float(Game.settings.get("sfx", 0.9)) / 0.9))
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = pitch
			p.volume_db = volume_db + level + gain_db
			p.play()
			return


## A creature's voice at a moment: "call" (it arrives), "attack", "hurt" (a
## heavy blow lands on it) or "ko" (it falls). Silent if it has none.
func cry(id: String, when: String = "call") -> void:
	var c := cry_of(id, when)
	if String(c[0]) != "":
		play(String(c[0]), float(c[1]), float(c[2]))


## [sound, pitch, dB] of a creature's voice at a moment, the sound "" when it
## has none. Looked for in turn: its own recording for the moment
## (cry_<id>_<when>), its own cry, its kind's for the moment, its kind's cry.
static func cry_of(id: String, when: String = "call") -> Array:
	var how: Array = CRY_WHEN.get(when, CRY_WHEN["call"])
	for own: String in ["cry_%s_%s" % [id, when], "cry_" + id]:
		if has_file(own):
			# (its own voice: as recorded, only moved for a moment it has no take of)
			var made_for: bool = own == "cry_%s_%s" % [id, when]
			return [own, 1.0 if made_for else float(how[0]), CRY_DB + (0.0 if made_for else float(how[1]))]
	var kind := voice_kind(id)
	if kind == "":
		return ["", 1.0, 0.0]
	var size := size_pitch(id) * float((VOICE_OF.get(id, ["", 1.0]) as Array)[1])
	# (never quite the same twice: a few hundredths either way)
	size *= randf_range(0.97, 1.03)
	var lo := float(CRY_PITCH[0])
	var hi := float(CRY_PITCH[1])
	var at := "cry_%s_%s" % [kind, when]
	if has_file(at):
		return [at, clampf(size, lo, hi), CRY_DB]
	if CRY_ALIAS.has(at) and has_file(String(CRY_ALIAS[at])):
		return [String(CRY_ALIAS[at]), clampf(size, lo, hi), CRY_DB + float(how[1])]
	if has_file("cry_" + kind):
		return ["cry_" + kind, clampf(size * float(how[0]), lo, hi), CRY_DB + float(how[1])]
	return ["", 1.0, 0.0]


## Which kind of voice a creature has ("" for none: a Summon, a Rite).
static func voice_kind(id: String) -> String:
	if VOICE_OF.has(id):
		return String((VOICE_OF[id] as Array)[0])
	return String(VOICE_OF_FAMILY.get(DuelSynergy.family_of(id), ""))


## How high a creature's kind's cry is pitched for its size.
static func size_pitch(id: String) -> float:
	var hp := float(DuelCards.CARDS.get(id, {}).get("hp", 120))
	return clampf(float(SIZE_PITCH[0]) - hp / float(SIZE_PITCH[1]), float(SIZE_PITCH[2]), float(SIZE_PITCH[3]))


## Loads the voices of these creatures now, so the first one called in a duel
## doesn't wait on the disk.
static func warm_cries(ids: Array) -> void:
	for id in ids:
		for when in CRY_WHEN:
			var c := cry_of(String(id), when)
			if String(c[0]) != "":
				get_stream(String(c[0]))


## The player for sounds that belong to no screen. Made when first asked for,
## under the root, and kept.
static func shared() -> Sfx:
	if not is_instance_valid(_shared):
		_shared = Sfx.new()
		_shared.name = "SharedSfx"
		# (added a moment later: the root may be in the middle of its own
		# children; watch_buttons asks for it as the game starts, so it is
		# long there by the first sound)
		(Engine.get_main_loop() as SceneTree).root.add_child.call_deferred(_shared)
	return _shared


## The player for footsteps, made and kept as shared() is.
static func steps() -> Sfx:
	if not is_instance_valid(_steps):
		_steps = Sfx.new()
		_steps.name = "StepSfx"
		_steps.marks_press = false
		(Engine.get_main_loop() as SceneTree).root.add_child.call_deferred(_steps)
	return _steps


## One footfall on `surface` ("snow", "grass", "dirt", "wood", "stone") by
## the walker `at` (a Figure3D: how far they are from the camera sets how
## loud it is; null plays it at full), `gain_db` on top (the villagers'
## steps sit under the player's). True if it was played.
static func step(surface: String, at: Node3D = null, running: bool = false, gain_db: float = 0.0) -> bool:
	var sound := "step_" + surface
	if not has_file(sound):
		sound = "step_" + STEP_ELSE
		if not has_file(sound):
			return false
	var gain := STEP_DB + (STEP_RUN_DB if running else 0.0) + gain_db
	if at != null and at.is_inside_tree():
		var cam := at.get_viewport().get_camera_3d()
		if cam != null:
			var far := cam.global_position.distance_to(at.global_position)
			var off := 20.0 * log(maxf(far, STEP_NEAR) / STEP_NEAR) / log(10.0)
			if off > STEP_FAR_DB:
				return false
			gain -= off
	steps().play(sound, randf_range(0.93, 1.07), gain + randf_range(-1.5, 0.5))
	return true


## Every button in the game clicks (12 November). A screen that plays its own
## sound for a press (the duel's buttons, a card lifted) keeps it: the click
## comes after the press's own handlers, and stays silent if anything was
## played in that moment. A button with the meta "quiet" never clicks.
static func watch_buttons(tree: SceneTree) -> void:
	shared()
	steps()
	if not tree.node_added.is_connected(_on_node):
		tree.node_added.connect(_on_node)


static func _on_node(n: Node) -> void:
	# (a button taken out of the tree and put back is met twice)
	if n is BaseButton and not n.has_meta("quiet") and not (n as BaseButton).pressed.is_connected(_click):
		(n as BaseButton).pressed.connect(_click, CONNECT_DEFERRED)


static func _click() -> void:
	if Time.get_ticks_msec() - _last_msec < 90:
		return
	clicks += 1
	shared().play("ui_tap")


## True when a real recording exists for this sound.
static func has_file(sound: String) -> bool:
	return _file(sound) != ""


static func _file(sound: String) -> String:
	# (looked up once: a voice asks after several names every time it's heard)
	if _files.has(sound):
		return _files[sound]
	var found := ""
	for ext in ["ogg", "wav", "mp3"]:
		var path := "res://assets/sfx/%s.%s" % [sound, ext]
		if ResourceLoader.exists(path):
			found = path
			break
	_files[sound] = found
	return found


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
	elif FALLBACK.has(sound) and FALLBACK[sound] != sound:
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
		"frost_write":
			# a fingertip squeaking over cold glass (the name in the frost)
			samples = _mix(_sweep(1700.0, 2300.0, 0.16, 0.05, "sine"), _noise(0.16, 0.07, 5000.0))
		# (14 November, Gary's yes to "ice that rings in the wind and cracks when
		# lightning hits": stand-ins made here until his recordings are saved as
		# assets/sfx/ice_ring.ogg (and _2, _3), ice_crack.ogg (and _2) and
		# ice_shatter.ogg; made once, WhiteSky asks for them under its opening
		# black)
		"ice_ring":
			# a shard singing in the wind: a few high glassy notes that swell
			# and die away, not quite in tune with each other
			samples = _ring([[1864.7, 1.0, 0.0], [2793.8, 0.6, 0.12], [3729.3, 0.34, 0.3], [4978.0, 0.2, 0.05], [2217.5, 0.4, 0.55]], 2.4, 0.11)
		"ice_crack":
			# the crack of ice split by a bolt: a hard snap, the split running
			# on through it, a few last ticks
			samples = _mix(_mix(_noise(0.05, 0.75, 9000.0), _sweep(2900.0, 700.0, 0.32, 0.3, "tri")), _pings(9, 0.75, 1800.0, 5200.0, 0.2, 0.05, 11))
		"ice_shatter":
			# a shard bursting: the break, then its splinters ringing down
			samples = _mix(_mix(_noise(0.45, 0.6, 7500.0), _sweep(1500.0, 260.0, 0.4, 0.3, "sine")), _pings(46, 1.7, 2100.0, 7400.0, 0.2, 0.16, 23))
		# (14 November, night: the two new moments before the opening's duel;
		# stand-ins until Gary's are saved as assets/sfx/mark_wake.ogg and
		# circle_draw.ogg)
		"mark_wake":
			# the mark over the child's heart answering the hunter's hand: a
			# low warm note swelling up, a high one waking over it
			samples = _ring([[196.0, 1.0, 0.0], [293.7, 0.7, 0.15], [392.0, 0.5, 0.4], [1174.7, 0.16, 0.7], [1568.0, 0.1, 0.95]], 2.8, 0.13)
		"circle_draw":
			# a Circle of light drawing itself in the snow: a line running
			# round, rising, and a soft ring as it closes
			samples = _mix(_mix(_sweep(420.0, 1250.0, 1.5, 0.07, "sine"), _noise(1.5, 0.03, 6000.0)), _ring([[1568.0, 0.8, 1.4], [2349.3, 0.45, 1.45], [3136.0, 0.25, 1.5]], 3.0, 0.11))
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


## Notes that swell and die away together (glass, ice): each of `parts` is
## [Hz, loudness, seconds late], `dur` long.
static func _ring(parts: Array, dur: float, vol: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var count := int(dur * RATE)
	out.resize(count)
	for part in parts:
		var f: float = part[0]
		var a: float = part[1]
		var late: float = part[2]
		var from := int(late * RATE)
		var step := f / RATE * TAU
		var beat := (0.7 + f * 0.0004) / RATE * TAU   # (a slow shimmer, each note's own)
		for i in range(from, count):
			var t := float(i - from) / RATE
			var left := (dur - late - t) / maxf(0.001, dur - late)
			var e := (1.0 - exp(-t / 0.22)) * exp(-t / (dur * 0.38)) * minf(1.0, left * 6.0)
			out[i] += sin(step * (i - from)) * (0.8 + 0.2 * sin(beat * i)) * e * a * vol
	return out


## `n` short high pings scattered over `dur` (splinters, ticks), thinning
## out towards its end: between `f_lo` and `f_hi` Hz, each up to `len` s.
static func _pings(n: int, dur: float, f_lo: float, f_hi: float, vol: float, length: float, seed_v: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var count := int(dur * RATE)
	out.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for k in n:
		var at := pow(rng.randf(), 1.7) * (dur - length)
		var f := rng.randf_range(f_lo, f_hi)
		var len_s := length * rng.randf_range(0.35, 1.0)
		var a := vol * rng.randf_range(0.35, 1.0) * (1.0 - 0.6 * at / dur)
		var from := int(at * RATE)
		var m := mini(int(len_s * RATE), count - from)
		var step := f / RATE * TAU
		for i in m:
			var t := float(i) / RATE
			out[from + i] += sin(step * i) * exp(-t / (len_s * 0.28)) * minf(1.0, t / 0.001) * a
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
