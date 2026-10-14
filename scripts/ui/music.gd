extends Node
## Background music (autoload "Music"). Crossfades between looping tracks and
## plays short stingers over them. Tracks are optional: put them in
## assets/audio/music/<name>.ogg (or .mp3 / .wav); anything missing is skipped.
##
##   Music.play(["arena_veilwild", "duel_main"])  first track that exists
##   Music.stinger("victory")                      one-shot, ducks the loop
##   Music.stop()

const DIR := "res://assets/audio/music/"
## Tracks with an intro that shouldn't repeat: after the first pass the loop
## jumps back to this many seconds in (the file's tail is baked to blend there).
## Each loop is cut with tools/music_loop.py and checked with tests/loop_probe.gd.
const LOOP_START := {"ashford_festival": 35.029, "menu_theme": 59.0, "duel_pinch": 29.78, "duel_alt": 11.376}
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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = -60.0
		add_child(p)
		_players.append(p)
	_sting = AudioStreamPlayer.new()
	add_child(_sting)


## The loudness music plays at, from the player's settings.
func level_db() -> float:
	return linear_to_db(maxf(0.001, float(Game.settings.get("music", 0.8)))) - 8.0


## Applies a changed music volume to what's playing now.
func apply_volume() -> void:
	var p := _players[_active]
	if p.playing:
		p.volume_db = level_db()


static func path_for(track: String) -> String:
	for ext in ["ogg", "mp3", "wav"]:
		var p := "%s%s.%s" % [DIR, track, ext]
		if ResourceLoader.exists(p):
			return p
	return ""


static func has(track: String) -> bool:
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


func stop(fade: float = 0.8) -> void:
	current = ""
	for i in _players.size():
		var p := _players[i]
		if p.playing:
			_remember(i)
			var tw := create_tween()
			tw.tween_property(p, "volume_db", -60.0, fade)
			tw.tween_callback(p.stop)


## Notes where a player's track has got to, for when it comes back.
func _remember(i: int) -> void:
	var p := _players[i]
	if _names[i] != "" and p.playing:
		_resume[_names[i]] = p.get_playback_position()


## A short piece over the music (Summons, victory, defeat). Returns false when
## the file doesn't exist yet.
func stinger(track: String, duck: bool = true) -> bool:
	if not has(track):
		return false
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
