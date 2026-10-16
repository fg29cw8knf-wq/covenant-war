extends Node
## Background music (autoload "Music"). Crossfades between looping tracks and
## plays short stingers over them. Tracks are optional: put them in
## assets/audio/music/<name>.ogg (or .mp3 / .wav); anything missing is skipped.
##
##   Music.play(["arena_veilwild", "duel_main"])  first track that exists
##   Music.stinger("victory")                      one-shot, ducks the loop
##   Music.stop()
##
## On the web the music plays through the page's own player instead
## (scripts/ui/music_web.js, which tools/build_web.sh puts in the page with an
## MP3 of every track): Godot's web audio can only loop a track by stopping at
## its end and starting again from the top. Everything else here is the same.

const DIR := "res://assets/audio/music/"
## Tracks with an intro that shouldn't repeat: after the first pass the loop
## jumps back to this many seconds in (the file's tail is baked to blend there).
## Each loop is cut with tools/music_loop.py and checked with tests/loop_probe.gd.
const LOOP_START := {"ashford_festival": 35.029, "menu_theme": 59.0, "duel_pinch": 29.78, "duel_alt": 11.376,
		"arena_emberforge": 7.997, "arena_solhaven": 12.245, "arena_tidegrove": 12.245}
## The two duel themes take turns, duel by duel.
const DUEL_THEMES := ["duel_main", "duel_alt"]

var current := ""
var _players: Array[AudioStreamPlayer] = []
var _names := ["", ""]          # which track each player holds
var _active := 0
var _sting: AudioStreamPlayer
var _duel_i := 0
## Where each track was when it faded out, so coming back to it (the village
## after a duel, say) carries on from there instead of starting again.
var _resume := {}
## The page's player (window.CWMusic) when the music plays through it, on the web.
static var _web = null
## Its tracks: name -> length in seconds.
static var _web_tracks := {}
var _web_test = null            # keeps the ?musictest hook's callback alive


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = -60.0
		add_child(p)
		_players.append(p)
	_sting = AudioStreamPlayer.new()
	add_child(_sting)
	if OS.has_feature("web"):
		_web_start()


## On the web, hands the music to the page's player when the page has one
## (a build without it keeps Godot's players and whatever music the pack has).
func _web_start() -> void:
	if not JavaScriptBridge.eval("!!window.CWMusic", true):
		return
	var tracks = JSON.parse_string(str(JavaScriptBridge.eval("CWMusic.tracks()", true)))
	if not tracks is Dictionary:
		return
	_web = JavaScriptBridge.get_interface("CWMusic")
	_web_tracks = tracks
	# a hook for tests/web_music_check.py, only with ?musictest in the address
	if str(JavaScriptBridge.eval("location.search", true)).contains("musictest"):
		_web_test = JavaScriptBridge.create_callback(_on_web_test)
		JavaScriptBridge.get_interface("window").CWMusicTest = _web_test


## The test hook: CWMusicTest("play", "a,b", fade), ("stop", fade),
## ("stinger", name, duck), ("volume", 0..1).
func _on_web_test(args: Array) -> void:
	match str(args[0]):
		"play":
			play(Array(str(args[1]).split(",")), float(args[2]))
		"stop":
			stop(float(args[1]))
		"stinger":
			stinger(str(args[1]), bool(args[2]))
		"volume":
			Game.settings["music"] = float(args[1])
			apply_volume()


func _web_playing(i: int) -> bool:
	return bool(_web.playing(i))


## The loudness music plays at, from the player's settings.
func level_db() -> float:
	return linear_to_db(maxf(0.001, float(Game.settings.get("music", 0.8)))) - 8.0


## Applies a changed music volume to what's playing now.
func apply_volume() -> void:
	if _web != null:
		if _web_playing(_active):
			_web.level(_active, level_db())
		return
	var p := _players[_active]
	if p.playing:
		p.volume_db = level_db()


## The track's file in the game's pack ("" if it isn't there; the web build
## leaves the music out of the pack and plays its own copies, see has()).
static func path_for(track: String) -> String:
	for ext in ["ogg", "mp3", "wav"]:
		var p := "%s%s.%s" % [DIR, track, ext]
		if ResourceLoader.exists(p):
			return p
	return ""


static func has(track: String) -> bool:
	if _web != null:
		return _web_tracks.has(track)
	return path_for(track) != ""


## Plays the first track in `tracks` that exists. With none, the music fades out
## (unless `keep_if_none`).
func play(tracks: Array, fade: float = 1.2, keep_if_none: bool = false) -> void:
	for t in tracks:
		if has(t):
			_switch(t, fade)
			return
	if not keep_if_none:
		stop(fade)


## The next duel's theme, then the other one as its fallback: duels alternate
## between duel_main and duel_alt.
func duel_theme() -> Array:
	var i := _duel_i
	_duel_i = (_duel_i + 1) % DUEL_THEMES.size()
	return [DUEL_THEMES[i], DUEL_THEMES[(i + 1) % DUEL_THEMES.size()]]


func _switch(track: String, fade: float) -> void:
	if _web != null:
		_web_switch(track, fade)
		return
	if track == current and _players[_active].playing:
		return
	current = track
	var s: AudioStream = load(path_for(track))
	_set_loop(s, true)
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop_offset = float(LOOP_START.get(track, 0.0))
	var old := _players[_active]
	_remember(_active)
	_active = 1 - _active
	var p := _players[_active]
	_names[_active] = track
	p.stream = s
	p.volume_db = -40.0
	var from := float(_resume.get(track, 0.0))
	if from >= s.get_length() - 1.0:
		from = 0.0
	p.play(from)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(p, "volume_db", level_db(), fade)
	if old.playing:
		tw.tween_property(old, "volume_db", -60.0, fade)
		tw.chain().tween_callback(old.stop)


## _switch on the web: the same, in the page's player. The new track fades in
## once it has loaded, and only then does the old one fade out.
func _web_switch(track: String, fade: float) -> void:
	if track == current and _web_playing(_active):
		return
	current = track
	var old := _active
	_remember(old)
	_active = 1 - _active
	_names[_active] = track
	var from := float(_resume.get(track, 0.0))
	if from >= float(_web_tracks[track]) - 1.0:
		from = 0.0
	_web.play(_active, track, from, float(LOOP_START.get(track, 0.0)), fade, level_db(), old)


func stop(fade: float = 0.8) -> void:
	current = ""
	if _web != null:
		for i in 2:
			if _web_playing(i):
				_remember(i)
				_web.fadeOut(i, fade)
		return
	for i in _players.size():
		var p := _players[i]
		if p.playing:
			_remember(i)
			var tw := create_tween()
			tw.tween_property(p, "volume_db", -60.0, fade)
			tw.tween_callback(p.stop)


## Notes where a player's track has got to, for when it comes back.
func _remember(i: int) -> void:
	if _web != null:
		if _names[i] != "" and _web_playing(i):
			_resume[_names[i]] = float(_web.position(i))
		return
	var p := _players[i]
	if _names[i] != "" and p.playing:
		_resume[_names[i]] = p.get_playback_position()


## A short piece over the music (Summons, victory, defeat). Returns false when
## the file doesn't exist yet.
func stinger(track: String, duck: bool = true) -> bool:
	if not has(track):
		return false
	if _web != null:
		# the same dip as below, done by the page's player once the piece starts
		var ducked := _active if duck and _web_playing(_active) else -1
		var hold := maxf(0.5, float(_web_tracks[track]) - 0.6)
		_web.sting(track, level_db() + 2.0, ducked, level_db() - 14.0, 0.2, hold, level_db(), 0.8)
		return true
	var s: AudioStream = load(path_for(track))
	_set_loop(s, false)
	_sting.stream = s
	_sting.volume_db = level_db() + 2.0
	_sting.play()
	if duck and _players[_active].playing:
		var p := _players[_active]
		var tw := create_tween()
		tw.tween_property(p, "volume_db", level_db() - 14.0, 0.2)
		tw.tween_interval(maxf(0.5, s.get_length() - 0.6))
		tw.tween_property(p, "volume_db", level_db(), 0.8)
	return true


static func _set_loop(s: AudioStream, on: bool) -> void:
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = on
	elif s is AudioStreamMP3:
		(s as AudioStreamMP3).loop = on
	elif s is AudioStreamWAV:
		var w := s as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD if on else AudioStreamWAV.LOOP_DISABLED
		if on:
			w.loop_end = int(w.get_length() * w.mix_rate)
