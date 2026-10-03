extends Node
## Background music (autoload "Music"). Crossfades between looping tracks and
## plays short stingers over them. Tracks are optional: put them in
## assets/audio/music/<name>.ogg (or .mp3 / .wav); anything missing is skipped.
##
##   Music.play(["arena_veilwild", "duel_main"])  first track that exists
##   Music.stinger("victory")                      one-shot, ducks the loop
##   Music.stop()

const DIR := "res://assets/audio/music/"

var current := ""
var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _sting: AudioStreamPlayer


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


func _switch(track: String, fade: float) -> void:
	if track == current and _players[_active].playing:
		return
	current = track
	var s: AudioStream = load(path_for(track))
	_set_loop(s, true)
	var old := _players[_active]
	_active = 1 - _active
	var p := _players[_active]
	p.stream = s
	p.volume_db = -40.0
	p.play()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(p, "volume_db", level_db(), fade)
	if old.playing:
		tw.tween_property(old, "volume_db", -60.0, fade)
		tw.chain().tween_callback(old.stop)


func stop(fade: float = 0.8) -> void:
	current = ""
	for p in _players:
		if p.playing:
			var tw := create_tween()
			tw.tween_property(p, "volume_db", -60.0, fade)
			tw.tween_callback(p.stop)


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
