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
		"arena_emberforge": 7.997, "arena_solhaven": 12.245, "arena_tidegrove": 6.409, "arena_ironstone": 10.008,
		"arena_veilwild": 8.406, "ashford_burns": 19.714, "dask": 9.822, "dawn_after": 10.333,
		"river_farewell": 8.104, "solhaven_dawn": 8.243, "thornwood": 10.890,
		# Gary's 2 November tracks: Corin's evening by the mill race, and Solhaven's square
		"corin_evening": 4.226, "solhaven_town": 8.940,
		# Gary's 4 November tracks: the talk music (Bram's, Tam's at the mill,
		# Nell's waltz) and the Night of the White Sky, cut in two from his one
		# piece (tools/music_loop.py on assets/audio/source/white_sky.mp3): the
		# walk (its first 122 s, looping from 24.6 s) and the duel (from 149.5 s,
		# the hush before the storm, then its climax looping from 8.9 s until the
		# white cuts it dead)
		"bram_theme": 14.698, "tam_mill": 4.946, "nell_waltz": 5.828,
		"white_sky": 24.613, "white_sky_duel": 8.870,
		# Gary's 5 November track: Tilly's talk music, by the well and when she
		# gives her moth (scouted in three-time; loops 15.4 to 96.4 s)
		"tilly_moth": 15.372,
		# and the Midnight film's choice-menu music: his soundtrack's own 24 s
		# continuation from the end of part 1, looping 16 bars from 5.745 s
		# while the player decides (StoryFilm, the choice's "music")
		"midnight_choice": 5.745}
## Pieces that always start from their beginning (a memory's music: coming
## back to it carries on from where it left off for everything else; the
## Midnight choice's carries straight on from the film before it).
const FROM_START := ["white_sky", "white_sky_duel", "midnight_choice"]
## The two duel themes take turns, duel by duel.
const DUEL_THEMES := ["duel_main", "duel_alt"]

var current := ""
var _players: Array[AudioStreamPlayer] = []
var _names := ["", ""]          # which track each player holds
var _active := 0
var _sting: AudioStreamPlayer
var _duel_i := 0
## One fade a player (11 November, Gary: "After first battle with Corin we
## have 2 different music playing at same time"): every fade, dip and stop of
## a player goes through _fade, which ends the one before it, so an old
## fade's last step can never bring a track back up, or stop one that has
## since been started on the same player.
var _fades: Array = [null, null]
## A piece played on its own with the music stopped under it (the victory
## and defeat pieces, the Marking): true while it's the one playing.
var _sting_solo := false
var _sting_tw: Tween
## How quickly a piece played on its own makes way when the next music
## starts under it (s): the victory piece is 12 s long, and the village's
## reel came back under it the moment the duel closed.
const SOLO_OUT := 1.2
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
	var was := _active
	_remember(was)
	_active = 1 - _active
	var p := _players[_active]
	_names[_active] = track
	p.stream = s
	p.volume_db = -40.0
	var from := 0.0 if track in FROM_START else float(_resume.get(track, 0.0))
	if from >= s.get_length() - 1.0:
		from = 0.0
	p.play(from)
	_fade(_active, level_db(), fade, false)
	if _players[was].playing:
		_fade(was, -60.0, fade, true)
	# a piece still playing on its own (the victory piece as the duel closes)
	# makes way for it: never two pieces of music at once
	_solo_out(minf(fade, SOLO_OUT))


## Fades player `i` to `db` over `secs` and, with `then_stop`, stops it
## there. Whatever fade, dip or stop that player had before ends here.
func _fade(i: int, db: float, secs: float, then_stop: bool) -> void:
	var was = _fades[i]
	if was is Tween and (was as Tween).is_valid():
		(was as Tween).kill()
	var p := _players[i]
	var tw := create_tween()
	tw.tween_property(p, "volume_db", db, maxf(0.01, secs))
	if then_stop:
		tw.tween_callback(p.stop)
	_fades[i] = tw


## A dip of player `i` for `secs`, then back (a Summon's piece, a hush).
func _dip(i: int, by: float, secs: float) -> void:
	var was = _fades[i]
	if was is Tween and (was as Tween).is_valid():
		(was as Tween).kill()
	var p := _players[i]
	var tw := create_tween()
	tw.tween_property(p, "volume_db", level_db() - by, 0.2)
	tw.tween_interval(maxf(0.5, secs - 0.6))
	tw.tween_property(p, "volume_db", level_db(), 0.8)
	_fades[i] = tw


## A piece playing on its own fades out and stops (the next music is
## starting under it).
func _solo_out(secs: float) -> void:
	if not _sting_solo or _sting == null or not _sting.playing:
		return
	_sting_solo = false
	if _sting_tw != null and _sting_tw.is_valid():
		_sting_tw.kill()
	_sting_tw = create_tween()
	_sting_tw.tween_property(_sting, "volume_db", -60.0, maxf(0.05, secs))
	_sting_tw.tween_callback(_sting.stop)


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
	var from := 0.0 if track in FROM_START else float(_resume.get(track, 0.0))
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
			_fade(i, -60.0, fade, true)


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
	if _sting_tw != null and _sting_tw.is_valid():
		_sting_tw.kill()   # (a piece on its way out: this one takes the player)
	_sting.stream = s
	_sting.volume_db = level_db() + 2.0
	_sting.play()
	# on its own (nothing under it: the victory piece, the Marking) or over
	# the music (a Summon's)
	_sting_solo = not duck
	if duck and _players[_active].playing:
		_dip(_active, 14.0, s.get_length())
	return true


## Dips the music for `secs` (a Summon's clip playing over it), then brings
## it back.
func duck(secs: float, by := 14.0) -> void:
	if _web != null:
		if _web_playing(_active):
			_web.level(_active, level_db() - by)
			get_tree().create_timer(secs).timeout.connect(func() -> void: _web.level(_active, level_db()))
		return
	if not _players[_active].playing:
		return
	_dip(_active, by, secs)


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
