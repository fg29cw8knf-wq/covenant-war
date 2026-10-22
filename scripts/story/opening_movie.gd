class_name OpeningMovie
extends CanvasLayer
## The opening movie, "The Throne of Ages".
##
## Plays, in order of preference:
##   1. the finished cut: res://assets/movies/opening.ogv (Gary's one film since
##      22 October: his clips, Morrowen's narration, the music, the title and the
##      words already in the picture, 3:12 long). Nothing of the engine's plays
##      over it: no subtitles, music, voice or title. Tap to show Skip.
##   2. shot by shot: res://assets/movies/shots/<shot>.ogv for each shot,
##      or the still res://assets/art/movie/<shot>.png (or .jpg) animated in the engine,
##      or, when neither exists yet, an animatic card describing the shot.
##      This is the fallback if the cut's missing, and what the apps keep.
## Shots, lines and pictures follow the "Opening movie" table of Master Script v3
## (2:24 in all, in time with opening_theme; the title rises at 2:14.5 to meet its
## final chord). Morrowen's voice lines (res://assets/audio/vo/vo_<n>.ogg, made from
## Gary's recordings with tools/vo_master.py) and the music
## (res://assets/audio/opening_theme.ogg) play when present. Tap to show Skip. The
## files to make are listed in "Opening Movie: Your Step-by-Step".

signal finished

## Script: length (s), Morrowen's line (the words exactly as recorded, which are
## also the subtitle), when it starts (vo_at: seconds after its shot's cut), what we
## see, camera move, overlay effect. The shots' lengths are v3's timings, so the
## pictures cut with the music. The longer lines run on past their cut, and the
## next line waits for them: vo_at is set from the recordings' lengths so that
## every line starts in its own shot, a breath after the one before (09b runs
## straight on from 09a, on the cut to the card), and the last ends before the
## title. tests/movie_shot.gd prints the timeline and checks it.
const SHOTS := [
	{"id": "shot_01", "len": 8.0, "vo": "I have watched every Age end, and written down what each one cost.", "vo_at": 0.5,
		"see": "Black. A spark rises; a sea of golden clouds; the Throne tiny on a distant floating peak.", "move": "in", "fx": "motes_gold"},
	{"id": "shot_02", "len": 8.0, "vo": "Whoever sits on that Throne rules every other god, and decides where the rain falls.", "vo_at": 0.1,
		"see": "The empty Throne; rivers of light flow up into it.", "move": "up", "fx": "motes_gold"},
	{"id": "shot_03", "len": 9.0, "vo": "To end their wars, the first gods carved the Covenant into the sky. It didn't end them. It scheduled them.", "vo_at": 1.72,
		"see": "Giant god silhouettes carve runes into a floating stone ring.", "move": "right", "fx": "sparks"},
	{"id": "shot_04", "len": 11.0, "vo": "One god rules for one Age: two thousand years. And nobody asked the world below whether it agreed.", "vo_at": 4.15,
		"see": "The rune ring locks around the Throne; a shockwave rolls across the clouds.", "move": "out", "fx": "motes_gold"},
	{"id": "shot_05", "len": 8.0, "vo": "This Age belongs to Solmaris, and the sun has kept perfect time.", "vo_at": 2.48,
		"see": "Solmaris on the Throne, eyes closed, serene and cold.", "move": "in", "fx": "motes_gold"},
	{"id": "shot_06", "len": 6.0, "vo": "Now her Age falls due.", "vo_at": 0.5,
		"see": "Her eyes open; the shadow of the sky-sized sundial touches the last rune.", "move": "up", "fx": "flash"},
	{"id": "shot_07a", "len": 2.0, "vo": "The other six would like her gone.", "vo_at": 0.4,
		"see": "Pyrrhane, the Burning Crown, rises from a sea of fire.", "move": "in", "fx": "embers", "god": "pyrrhane"},
	{"id": "shot_07b", "len": 2.0, "vo": "", "see": "Vaelith, the Frost Queen, on still black water.", "move": "in", "fx": "snow", "god": "vaelith"},
	{"id": "shot_07c", "len": 2.0, "vo": "", "see": "Ixara, the Storm Herald, bursts through the storm.", "move": "in", "fx": "flash", "god": "ixara"},
	{"id": "shot_07d", "len": 2.0, "vo": "", "see": "Nocthra, the Veiled Mother, and a thousand moths.", "move": "in", "fx": "moths", "god": "nocthra"},
	{"id": "shot_07e", "len": 2.0, "vo": "", "see": "Oriel, the Dreaming Eye, opens her many eyes.", "move": "in", "fx": "motes", "god": "oriel"},
	{"id": "shot_07f", "len": 2.0, "vo": "", "see": "Aldrith, the Runeweaver, locks his rune circles.", "move": "in", "fx": "motes", "god": "aldrith"},
	{"id": "shot_08", "len": 8.0, "vo": "Gods can break the sky, but not each other. So they spend the living instead.", "vo_at": 0.4,
		"see": "The seven powers collide; the sky shatters like glass.", "move": "in", "fx": "flash"},
	{"id": "shot_09a", "len": 5.0, "vo": "Their magic has always spilled into the world below,", "vo_at": 0.68,
		"see": "Light falls to Veyl.", "move": "down", "fx": "falling"},
	{"id": "shot_09b", "len": 5.0, "vo": "and cooled into cards.", "vo_at": 0.0,
		"see": "One streak cools into a card in a field.", "move": "in", "fx": "sparks"},
	# music only: Bram explains the first Totem that night, in his own words
	{"id": "shot_10", "len": 9.0, "vo": "",
		"see": "A duellist raises a card and Blazehound bursts out onto a rune circle.", "move": "in", "fx": "embers"},
	{"id": "shot_11", "len": 9.0, "vo": "Kingdoms were built on cards. Now they fight with them, not swords. Fewer die that way. I notice the difference.", "vo_at": 0.1,
		"see": "Two armies at dusk; Boulderox and Voltlynx clash above a giant duelling circle.", "move": "up", "fx": "sparks"},
	{"id": "shot_12", "len": 10.0, "vo": "Each kingdom has a Champion, marked by a god. Anyone may challenge one for the mark. The last one standing crowns their god.", "vo_at": 1.32,
		"see": "Seven beams fall on seven kingdoms; seven marks burn onto seven hands.", "move": "out", "fx": "falling"},
	{"id": "shot_12b", "len": 10.0, "vo": "And in Ironvault, a man who holds half the world in debt has started to ask what the gods are for.", "vo_at": 1.84,
		"see": "A vault of glowing cards; a gold-ringed hand turns a page in a ledger beside a gold case with eight empty slots. The face is never shown.", "move": "left", "fx": "motes_gold"},
	# the white streak sets off on "over a village" and comes down on Ashford on
	# "anyway" (seconds into the line), a moment before the cut
	{"id": "shot_13", "len": 8.0, "vo": "On the last night of the Age, over a village that had hung its lanterns anyway...", "vo_at": 2.25,
		"see": "Ashford at night; the sky tears open, and one white streak falls towards the village.", "move": "in", "fx": "streak",
		"streak": [3.07, 5.28], "streak_from": Vector2(0.455, 0.05), "streak_to": Vector2(0.578, 0.745)},
	# the eighth light ignites on "marked", 0.86 s into the line
	{"id": "shot_15", "len": 18.0, "vo": "...the Covenant marked an eighth Champion, and left the god's name blank.", "vo_at": 0.75,
		"see": "The Throne with seven orbiting lights; an eighth, pure white, ignites on \"marked\" and joins them.", "move": "out", "fx": "orbit",
		"orbit_at": Vector2(0.5, 0.79), "orbit_r": Vector2(0.13, 0.04), "white_word": 0.86,
		"title": true, "title_at": 8.5},
]

const MOVIE := "res://assets/movies/opening.ogv"
const MUSIC := "res://assets/audio/opening_theme.ogg"

var _root: Control
var _stage: ShotView
var _sub: Label
var _skip: Button
var _video: VideoStreamPlayer
var _music: AudioStreamPlayer
var _voice: AudioStreamPlayer
var _done := false
var _skip_timer: SceneTreeTimer
var _skip_up := false        # Skip is showing: the next E, Space, Enter or A skips
var _focus_before: Control   # the button underneath that had the keyboard focus
var _duck_tween: Tween
var _ducked := false
var _clock := 0.0
## Play shot by shot even when the finished cut exists (the tests of that path).
var shots_only := false
var _cut := false            # the finished cut is what's playing
var _lines: Array = []       # schedule(): when each line starts and ends
var _next_line := 0          # the next line to start
var _line_end := -1.0        # when the line speaking now ends (-1: none)
## How far the music drops while Morrowen speaks.
const DUCK_DB := -8.0
## A subtitle stays up this long after its line ends, unless the next line takes over.
const SUB_HOLD := 0.6
## The music comes back up between lines only when the next one is further off than this.
const UNDUCK_GAP := 1.5


func _ready() -> void:
	layer = 30
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.theme = UITheme.make()
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.gui_input.connect(_on_input)
	add_child(_root)
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(black)

	# clips keep their 16:9 shape and fill the screen, framed like the paintings (frame_rect)
	_video = VideoStreamPlayer.new()
	_video.expand = true
	_video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_video.visible = false
	_root.add_child(_video)
	_root.resized.connect(_fit_video)
	_fit_video()

	_stage = ShotView.new()
	_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_stage)

	_sub = UITheme.label("", 40, Color(1, 1, 1, 0.95), "body", 10)
	_sub.anchor_left = 0.08
	_sub.anchor_right = 0.92
	_sub.anchor_top = 1.0
	_sub.anchor_bottom = 1.0
	_sub.offset_top = -190
	_sub.offset_bottom = -60
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sub.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_root.add_child(_sub)

	_skip = UITheme.button("Skip", false, 200)
	_skip.anchor_left = 1.0
	_skip.anchor_right = 1.0
	_skip.modulate.a = 0.0
	# the words and Skip keep clear of a phone's Dynamic Island and home bar
	SafeArea.watch(_skip, func() -> void:
		var m := SafeArea.insets()
		_sub.offset_top = -190 - m.w
		_sub.offset_bottom = -60 - m.w
		_skip.offset_left = -250 - m.z
		_skip.offset_right = -40 - m.z
		_skip.offset_top = 36 + m.y
		_skip.offset_bottom = 132 + m.y)
	_skip.focus_mode = Control.FOCUS_NONE   # keys are handled in _unhandled_input
	_skip.pressed.connect(_finish)
	_root.add_child(_skip)
	# the title's button underneath keeps the keyboard focus, and would take
	# Space and Enter for itself (starting the movie again); it gets it back after
	_focus_before = get_viewport().gui_get_focus_owner()
	get_viewport().gui_release_focus()

	_music = AudioStreamPlayer.new()
	add_child(_music)
	_voice = AudioStreamPlayer.new()
	add_child(_voice)
	_play.call_deferred()


## How far a 16:9 picture may be enlarged past fitting whole to fill the
## screen: a wide phone (2.17:1 needs 1.22) is filled edge to edge, cropping
## a little top and bottom; an iPad (4:3 would need 1.33) keeps thin bands.
const MAX_FILL := 1.25


## Where a picture of this shape goes on a screen of size `s`: as big as
## fills the screen, up to MAX_FILL times its whole-picture size, centred.
static func frame_rect(s: Vector2, aspect: float = 16.0 / 9.0) -> Rect2:
	var fit_h := minf(s.x / aspect, s.y)
	var h := minf(maxf(s.x / aspect, s.y), fit_h * MAX_FILL)
	var sz := Vector2(h * aspect, h)
	return Rect2((s - sz) * 0.5, sz)


## How much of the finished cut's height may go off the bottom of a wide
## screen: Gary's words along its foot end 3.5% up, so the crop comes off the
## top (sky; the title sits mid-frame) and the words stay whole.
const CUT_FOOT := 0.01


func _fit_video() -> void:
	var fr := frame_rect(_root.size)
	if ResourceLoader.exists(MOVIE) and not shots_only and fr.size.y > _root.size.y:
		fr.position.y = _root.size.y - fr.size.y * (1.0 - CUT_FOOT)
	_video.position = fr.position
	_video.size = fr.size


func _play() -> void:
	_lines = schedule()
	if ResourceLoader.exists(MOVIE) and not shots_only:
		await _play_full_cut()
	if not _cut and not _done:
		# the engine's own movie: the theme, and Morrowen's lines over the shots
		if ResourceLoader.exists(MUSIC):
			_music.stream = load(MUSIC)
			_music.play()
		await _play_shots()
	_finish()


## The finished cut has everything in it (the narration, the music, the words
## on screen and the title), so nothing of the engine's goes over it: only the
## clock follows it, for the log. Returns false if the file can't play, and the
## shots take over.
func _play_full_cut() -> bool:
	var stream := load(MOVIE) as VideoStream
	if stream == null:
		push_warning("OpeningMovie: %s won't load; playing the shots instead" % MOVIE)
		return false
	_stage.visible = false
	_video.stream = stream
	_video.visible = true
	_video.play()
	await get_tree().process_frame
	if not _video.is_playing():
		push_warning("OpeningMovie: %s won't play; playing the shots instead" % MOVIE)
		_video.stop()
		_video.visible = false
		_stage.visible = true
		return false
	_cut = true
	while _video.is_playing() and not _done:
		await get_tree().process_frame
		_clock = maxf(_clock, _video.stream_position)   # (0 again once it's over)
	return true


func _play_shots() -> void:
	var n := 0
	var cut := 0.0
	for shot in SHOTS:
		if _done:
			return
		n += 1
		var id: String = shot.id
		var clip := "res://assets/movies/shots/%s.ogv" % id
		var still := _still_path(id)
		var line_at := _line_start(id) - cut
		if ResourceLoader.exists(clip):
			# the clip plays; the stage stays up only to draw the title over it
			_video.stream = load(clip)
			_video.visible = true
			_video.play()
			_stage.visible = shot.get("title", false) or String(shot.get("fx", "")) == "orbit"
			_stage.overlay_only = true
			_stage.show_shot(shot, null, n, line_at)
		else:
			_video.stop()
			_video.visible = false
			_stage.visible = true
			_stage.overlay_only = false
			_stage.show_shot(shot, load(still) if still != "" else null, n, line_at)
		# each cut lands on the movie clock, so the pictures never drift from the music
		cut += float(shot.len)
		await _wait_until(cut)


## When each of Morrowen's lines starts and ends, on the movie clock: at its
## shot's cut plus vo_at, or, if a re-recorded line before it has grown too long
## to finish by then, a moment after that one ends, so lines never overlap or get
## cut off. A line whose recording isn't there yet gets a reading-time estimate.
static func schedule() -> Array:
	var out := []
	var cut := 0.0
	var free_at := 0.0
	for shot in SHOTS:
		var text := String(shot.vo)
		if text != "":
			var id: String = shot.id
			var path := "res://assets/audio/vo/vo_%s.ogg" % id.trim_prefix("shot_")
			var length := 1.0 + text.length() * 0.07
			if ResourceLoader.exists(path):
				length = (load(path) as AudioStream).get_length()
			else:
				path = ""
			var start := maxf(cut + float(shot.get("vo_at", 0.0)), free_at)
			out.append({"shot": id, "text": text, "path": path, "start": start, "end": start + length})
			free_at = start + length + 0.05
		cut += float(shot.len)
	return out


## Where the line for this shot starts on the movie clock (-1: the shot has none).
func _line_start(shot_id: String) -> float:
	for l in _lines:
		if l.shot == shot_id:
			return l.start
	return -1.0


## Starts each line on time, takes its subtitle down after it, and ducks the
## music under the voice. Timing runs on the movie clock, not the audio driver,
## so the subtitles stay right even when the sound can't play.
func _tick_lines(speak := true) -> void:
	if _next_line < _lines.size() and _clock >= float(_lines[_next_line].start):
		var line: Dictionary = _lines[_next_line]
		_next_line += 1
		_line_end = float(line.end)
		_set_sub(String(line.text))
		if speak and line.path != "":
			_voice.stream = load(line.path)
			_voice.play()
			_duck(true)
		if OS.is_debug_build():
			print("movie: %s at %d:%06.3f" % [String(line.shot).replace("shot", "vo"), int(_clock) / 60, fmod(_clock, 60.0)])
	if _line_end >= 0.0 and _clock >= _line_end:
		var next_at: float = _lines[_next_line].start if _next_line < _lines.size() else INF
		if speak and next_at - _line_end > UNDUCK_GAP:
			_duck(false)
		if _clock >= _line_end + SUB_HOLD:
			_line_end = -1.0
			_set_sub("")


func _duck(down: bool) -> void:
	if down == _ducked:
		return
	_ducked = down
	if _duck_tween:
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_property(_music, "volume_db", DUCK_DB if down else 0.0, 0.3 if down else 0.8)


## The shot's painting, as a PNG or a JPG, or "" until it's been made.
static func _still_path(id: String) -> String:
	for ext in ["png", "jpg"]:
		var p := "res://assets/art/movie/%s.%s" % [id, ext]
		if ResourceLoader.exists(p):
			return p
	return ""


## Runs the movie clock (and the lines on it) until it reaches `t`.
func _wait_until(t: float) -> void:
	while _clock < t and not _done:
		await get_tree().process_frame
		_clock += get_process_delta_time()
		_tick_lines()


func _set_sub(text: String) -> void:
	if _sub.text == text:
		return
	_sub.text = text
	_sub.modulate.a = 0.0
	if text != "":
		create_tween().tween_property(_sub, "modulate:a", 1.0, 0.5)


func _on_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		_show_skip()


## Esc, Tab or Start skips at once; E, Space, Enter or A shows Skip, and a
## second press while it shows skips.
func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("menu"):
		_finish()
		get_viewport().set_input_as_handled()
	elif e.is_action_pressed("interact"):
		if _skip_up:
			_finish()
		else:
			_show_skip()
		get_viewport().set_input_as_handled()


func _show_skip() -> void:
	_skip_up = true
	create_tween().tween_property(_skip, "modulate:a", 1.0, 0.2)
	var my_timer := get_tree().create_timer(3.5)
	_skip_timer = my_timer
	await my_timer.timeout
	if _skip_timer == my_timer and not _done:
		_skip_up = false
		create_tween().tween_property(_skip, "modulate:a", 0.0, 0.4)


func _finish() -> void:
	if _done:
		return
	_done = true
	if _duck_tween:
		_duck_tween.kill()
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 0.0, 0.6)
	tw.parallel().tween_property(_music, "volume_db", -40.0, 0.6)
	if _cut:
		# the cut's own sound goes down with the picture (a Skip in the middle
		# of a line, or of the music)
		tw.parallel().tween_property(_video, "volume_db", -40.0, 0.6)
	else:
		_video.stop()
	await tw.finished
	_video.stop()
	if is_instance_valid(_focus_before) and _focus_before.is_visible_in_tree():
		_focus_before.grab_focus()   # back on the title, the keys work again
	finished.emit()
	queue_free()


## Draws one shot: an AI still with a slow camera move and particles, or,
## until the still exists, an animatic card describing the shot.
class ShotView:
	extends Control
	var shot: Dictionary = {}
	var still: Texture2D = null
	var number := 0
	var _t := 0.0
	var _rng := RandomNumberGenerator.new()
	var _parts: Array = []
	var _still_rect := Rect2()
	## True while a video clip plays underneath: only the title is drawn.
	var overlay_only := false
	## Seconds into the shot when its line starts: effects timed to Morrowen's
	## words (the eighth light, the white streak) count from here.
	var line_at := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	## at: when the shot's line starts, in seconds after the cut (below 0: its vo_at).
	func show_shot(s: Dictionary, tex: Texture2D, n: int, at := -1.0) -> void:
		shot = s
		still = tex
		number = n
		line_at = at if at >= 0.0 else float(s.get("vo_at", 0.0))
		_t = 0.0
		_rng.seed = hash(String(s.id))
		_parts.clear()
		for i in 90:
			_parts.append(Vector4(_rng.randf(), _rng.randf(), _rng.randf(), _rng.randf()))
		modulate.a = 0.0
		create_tween().tween_property(self, "modulate:a", 1.0, 0.35)

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		if shot.is_empty():
			return
		var r := Rect2(Vector2.ZERO, size)
		var k := clampf(_t / float(shot.len), 0.0, 1.0)
		var title_t := _t - float(shot.get("title_at", 0.0)) if shot.get("title", false) else -1.0
		if overlay_only:
			# a clip plays underneath: the 16:9 frame it fills, then the lights and title over it
			_still_rect = OpeningMovie.frame_rect(r.size)
			if String(shot.get("fx", "")) == "orbit":
				_draw_orbit(r)
			if title_t >= 0.0:
				_draw_title(r, title_t)
			return
		if still != null:
			_draw_still(r, k)
		else:
			_draw_card(r, title_t < 0.0)
		_draw_fx(r)
		if title_t >= 0.0:
			_draw_title(r, title_t)
		# letterbox bars frame the placeholder cards; a painting is shown whole
		if still == null:
			var bar := r.size.y * 0.06
			draw_rect(Rect2(0, 0, r.size.x, bar), Color.BLACK)
			draw_rect(Rect2(0, r.size.y - bar, r.size.x, bar), Color.BLACK)

	## The painting fills the screen (OpeningMovie.frame_rect: a wide phone
	## loses a little top and bottom, never the sides) and the camera moves
	## are gentle, never showing past its edges.
	func _draw_still(r: Rect2, k: float) -> void:
		var e := k * k * (3.0 - 2.0 * k)
		var zoom := 1.0
		var off := Vector2.ZERO
		match String(shot.get("move", "in")):
			"in":
				zoom = lerpf(1.0, 1.05, e)
			"out":
				zoom = lerpf(1.05, 1.0, e)
			"up":
				zoom = 1.03
				off = Vector2(0, lerpf(0.015, -0.015, e))
			"down":
				zoom = 1.03
				off = Vector2(0, lerpf(-0.015, 0.015, e))
			"left":
				zoom = 1.03
				off = Vector2(lerpf(0.015, -0.015, e), 0)
			"right":
				zoom = 1.03
				off = Vector2(lerpf(-0.015, 0.015, e), 0)
		var ts := Vector2(still.get_width(), still.get_height())
		var sz := OpeningMovie.frame_rect(r.size, ts.x / ts.y).size * zoom
		var pos := (r.size - sz) * 0.5 + off * r.size
		if shot.has("orbit_at"):
			# crop round the lights (low in the picture), so they stay where the
			# whole painting would have them, above the words
			pos.y = (r.size.y - sz.y) * (shot.orbit_at as Vector2).y + off.y * r.size.y
		for i in 2:   # where it covers the screen, the moves never show past its edge
			if sz[i] >= r.size[i]:
				pos[i] = clampf(pos[i], r.size[i] - sz[i], 0.0)
		_still_rect = Rect2(pos, sz)
		draw_texture_rect(still, _still_rect, false)

	## with_words: false once the title is up, so the card's description doesn't sit under it.
	func _draw_card(r: Rect2, with_words := true) -> void:
		var god: String = shot.get("god", "")
		var tint := Lore.color(Lore.GODS[god].element, 2) if god != "" else Color("141a33")
		CardFace.vgrad_rect(self, r, tint.darkened(0.55), Color("030307"))
		var c := r.get_center()
		for i in 8:
			draw_circle(c, r.size.y * (0.7 - i * 0.07), Color(tint.lightened(0.3), 0.025))
		if not with_words:
			return
		var f := CardFace.font("display")
		CardFace.text(self, CardFace.font("bold"), Vector2(0, r.size.y * 0.3), "SHOT " + String(shot.id).trim_prefix("shot_").lstrip("0").to_upper(),
			24, Color(UITheme.GOLD, 0.7), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		var lines := _wrap(String(shot.see), f, 44, r.size.x * 0.7)
		var y := r.size.y * 0.42
		for ln in lines:
			CardFace.text(self, f, Vector2(0, y), ln, 44, Color(1, 1, 1, 0.85), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
			y += 60
		CardFace.text(self, CardFace.font("body"), Vector2(0, r.size.y * 0.72), "Animatic: this shot's picture hasn't been made yet", 22,
			Color(1, 1, 1, 0.3), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)

	func _wrap(s: String, f: Font, fs: int, width: float) -> Array:
		var out := []
		var line := ""
		for w in s.split(" "):
			var test := (line + " " + w).strip_edges()
			if f.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > width and line != "":
				out.append(line)
				line = w
			else:
				line = test
		if line != "":
			out.append(line)
		return out

	func _draw_fx(r: Rect2) -> void:
		var fx: String = shot.get("fx", "")
		match fx:
			"motes_gold", "motes":
				var col := UITheme.GOLD if fx == "motes_gold" else Color(0.85, 0.9, 1.0)
				for p in _parts:
					var pos := Vector2(fmod(p.x + _t * 0.01 * (p.z - 0.5), 1.0), fmod(p.y + 1.0 - _t * 0.02 * (0.3 + p.w), 1.0)) * r.size
					draw_circle(pos, 1.5 + p.z * 3.0, Color(col, 0.15 + 0.35 * p.w * (0.6 + 0.4 * sin(_t * 2.0 + p.x * 20.0))))
			"embers":
				for p in _parts:
					var pos := Vector2(fmod(p.x + sin(_t + p.y * 9.0) * 0.01, 1.0), fmod(p.y + 1.0 - _t * 0.08 * (0.4 + p.w), 1.0)) * r.size
					draw_circle(pos, 1.5 + p.z * 2.5, Color(1.0, 0.45 + p.w * 0.35, 0.15, 0.7))
			"snow":
				for p in _parts:
					var pos := Vector2(fmod(p.x + sin(_t * 0.5 + p.y * 7.0) * 0.02, 1.0), fmod(p.y + _t * 0.03 * (0.4 + p.w), 1.0)) * r.size
					draw_circle(pos, 1.5 + p.z * 3.0, Color(1, 1, 1, 0.6))
			"moths":
				for p in _parts:
					var pos := Vector2(fmod(p.x + _t * 0.05 * (p.z - 0.3), 1.0), fmod(p.y - _t * 0.04 * p.w + 1.0, 1.0)) * r.size
					var flap: float = absf(sin(_t * 14.0 + p.x * 30.0)) * (4.0 + p.z * 4.0)
					draw_line(pos - Vector2(flap, 0), pos + Vector2(flap, 0), Color(0.9, 0.85, 1.0, 0.55), 2.0)
			"sparks":
				for p in _parts:
					var ph := fmod(_t * (0.4 + p.w) + p.z, 1.0)
					var pos := Vector2(p.x, p.y * 0.6 + ph * 0.4) * r.size
					draw_circle(pos, 1.0 + p.z * 2.0, Color(1.0, 0.85, 0.5, 0.8 * (1.0 - ph)))
			"falling":
				for i in 12:
					var p: Vector4 = _parts[i]
					var ph := fmod(_t * (0.25 + p.w * 0.2) + p.z, 1.0)
					var dir := Vector2(0.35, 1.0).normalized()
					var head := Vector2(p.x * r.size.x * 1.2 - r.size.x * 0.1, -100) + dir * ph * r.size.y * 1.3
					var col := Lore.color(Lore.CORE_ELEMENTS[i % Lore.CORE_ELEMENTS.size()], 0)
					for s in 10:
						var a := head - dir * (200.0 * s / 10.0)
						var b := head - dir * (200.0 * (s + 1) / 10.0)
						draw_line(a, b, Color(col, 0.9 * (1.0 - s / 10.0)), 4.0 - s * 0.3, true)
					draw_circle(head, 5, Color(1, 1, 1, 0.9))
			"flash":
				var f := clampf(1.0 - absf(_t - 0.7) * 3.0, 0.0, 1.0)
				if f > 0.0:
					draw_rect(r, Color(1, 1, 1, 0.5 * f))
			"orbit":
				_draw_orbit(r)
			"streak":
				_draw_streak(r)

	## Shot 13: one white streak breaks out of the torn sky as Morrowen says "over
	## a village" and comes down on Ashford as she says "anyway" (the shot's
	## "streak" times, seconds into its line), half a second before the cut to the
	## Throne: long enough to see it strike, and its light is still on the village
	## as the picture changes.
	func _draw_streak(r: Rect2) -> void:
		var times: Array = shot.get("streak", [3.0, 5.3])
		var t0 := line_at + float(times[0])
		var t1 := line_at + float(times[1])
		if _t < t0:
			return
		var sr := _still_rect if still != null else r
		var k := sr.size.y / 1080.0
		var from := sr.position + Vector2(shot.get("streak_from", Vector2(0.46, 0.05))) * sr.size
		var to := sr.position + Vector2(shot.get("streak_to", Vector2(0.58, 0.75))) * sr.size
		var u := clampf((_t - t0) / maxf(t1 - t0, 0.1), 0.0, 1.0)
		var head := from.lerp(to, pow(u, 1.6))   # it gathers speed as it falls
		var since := _t - t1                       # after it lands
		# the beam it leaves, from the tear to its head, fading away once it has landed
		var beam := clampf(1.0 - since / 0.7, 0.0, 1.0) if since > 0.0 else 1.0
		var n := 32
		for s in n:
			var a := head.lerp(from, float(s) / n)
			var b := head.lerp(from, float(s + 1) / n)
			var f := pow(1.0 - float(s) / n, 1.5) * beam
			draw_line(a, b, Color(0.75, 0.88, 1.0, 0.18 * f), 34.0 * k, true)
			draw_line(a, b, Color(0.9, 0.96, 1.0, 0.45 * f), 14.0 * k, true)
			draw_line(a, b, Color(1, 1, 1, f), 5.0 * k, true)
		if since < 0.0:
			_glow(head, 70.0 * k, Color(0.9, 0.95, 1.0), 0.7)
			draw_circle(head, 9.0 * k, Color.WHITE)
			return
		# it strikes: a flash, a burst of light on the village, a ring running out
		var flash := clampf(1.0 - since / 0.4, 0.0, 1.0)
		if flash > 0.0:
			draw_rect(r, Color(1, 1, 1, 0.45 * flash * flash))
		_glow(to, (150.0 + 90.0 * minf(since, 1.0)) * k, Color(0.92, 0.96, 1.0), 0.8 + 0.5 * flash)
		var ring := minf(since / 1.0, 1.0)
		draw_arc(to, (30.0 + 300.0 * ring) * k, 0.0, TAU, 64, Color(1, 1, 1, 0.8 * (1.0 - ring)), 6.0 * k * (1.0 - ring) + 1.0, true)
		draw_circle(to, 14.0 * k, Color.WHITE)

	## A soft round glow: circles stacked so it's brightest in the middle.
	func _glow(at: Vector2, radius: float, col: Color, strength: float) -> void:
		for i in 18:
			var f := 1.0 - i / 18.0
			draw_circle(at, radius * f * f, Color(col, strength / 10.0))

	## Shot 15: the seven gods' lights circle the Throne; then an eighth, pure
	## white, ignites out of nothing and joins them.
	func _draw_orbit(r: Rect2) -> void:
		for p in _parts.slice(0, 40):
			var pos := Vector2(fmod(p.x + _t * 0.004 * (p.z - 0.5), 1.0), fmod(p.y + 1.0 - _t * 0.01 * (0.3 + p.w), 1.0)) * r.size
			draw_circle(pos, 1.0 + p.z * 2.0, Color(UITheme.GOLD, 0.12 + 0.25 * p.w))
		var sr := _still_rect if still != null else r
		var at: Vector2 = shot.get("orbit_at", Vector2(0.5, 0.85))
		var rad: Vector2 = shot.get("orbit_r", Vector2(0.15, 0.05))
		var c := sr.position + at * sr.size
		var R := rad * sr.size
		var k := sr.size.y / 1080.0
		# the faint path they trace
		var path := PackedVector2Array()
		for i in 65:
			var t := TAU * i / 64.0
			path.append(c + Vector2(cos(t) * R.x, sin(t) * R.y))
		draw_polyline(path, Color(UITheme.GOLD, 0.12), 2.0 * k, true)
		# it ignites as Morrowen says "marked"
		var white_at := line_at + float(shot.get("white_word", 0.0))
		var lights := []
		for i in 8:
			var ang := _t * 0.5 + TAU * i / 8.0
			var depth := sin(ang)          # +1 in front of the Throne, -1 behind it
			var a := 1.0
			if i == 7:
				a = clampf((_t - white_at) / 0.3, 0.0, 1.0)
				if a <= 0.0:
					continue
			var el := "any" if i == 7 else String(Lore.GODS[Lore.GREAT_GODS[i]].element)
			var col := Color.WHITE if i == 7 else Lore.color(el, 0)
			lights.append([depth, Vector2(c.x + cos(ang) * R.x, c.y + depth * R.y), col, a])
		lights.sort_custom(func(x, y): return x[0] < y[0])
		for l in lights:
			var depth: float = l[0]
			var pos: Vector2 = l[1]
			var col: Color = l[2]
			var a: float = l[3] * (0.55 + 0.45 * (depth * 0.5 + 0.5))
			var sz := (13.0 + 5.0 * depth) * k
			for g in 5:
				draw_circle(pos, sz * (6.0 - g), Color(col, 0.06 * a))
			draw_circle(pos, sz * 1.4, Color(col, 0.6 * a))
			draw_circle(pos, sz * 0.8, Color(col.lightened(0.7), 0.98 * a))
		# the eighth light's ignition: a flare of white that blooms and fades, and a ring
		var since := _t - white_at
		if since >= 0.0 and since < 1.6:
			var ang7 := _t * 0.5 + TAU * 7.0 / 8.0
			var p7 := Vector2(c.x + cos(ang7) * R.x, c.y + sin(ang7) * R.y)
			var u := since / 1.6
			var flare := clampf(1.0 - since / 0.6, 0.0, 1.0)
			if flare > 0.0:
				_glow(p7, 110.0 * k, Color.WHITE, 0.6 * flare)
				var ray := (40.0 + 200.0 * flare) * k
				draw_line(p7 - Vector2(ray, 0), p7 + Vector2(ray, 0), Color(1, 1, 1, 0.8 * flare), 2.5 * k, true)
				draw_line(p7 - Vector2(0, ray * 0.6), p7 + Vector2(0, ray * 0.6), Color(1, 1, 1, 0.6 * flare), 2.0 * k, true)
			draw_arc(p7, (20.0 + 160.0 * u) * k, 0.0, TAU, 48, Color(1, 1, 1, 0.7 * (1.0 - u)), 3.0 * k, true)
			draw_circle(p7, (40.0 * (1.0 - u)) * k, Color(1, 1, 1, 0.5 * (1.0 - u)))

	## t: seconds since the title was due; it fades up over 2.5 s.
	func _draw_title(r: Rect2, t: float) -> void:
		var a := clampf(t / 2.5, 0.0, 1.0)
		var c := Vector2(r.size.x * 0.5, r.size.y * 0.36)
		for i in 10:
			draw_circle(c, (r.size.x * 0.32) * (1.0 - i * 0.08), Color(UITheme.GOLD, 0.02 * a))
		var f := CardFace.font("display_bold")
		CardFace.text(self, CardFace.font("display"), Vector2(0, c.y - 110), "THE", 48, Color(UITheme.GOLD, a), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 8)
		CardFace.text(self, f, Vector2(0, c.y + 20), "COVENANT WAR", 132, Color(UITheme.GOLD, a), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 16, Color(0.05, 0.03, 0.01, 0.9 * a))
		CardFace.text(self, CardFace.font("display"), Vector2(0, c.y + 100), "THRONE  OF  AGES", 46, Color(1, 1, 1, 0.9 * a), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 8)
		# eight lights circling (shot 15 already has them round the Throne)
		for i in (0 if String(shot.get("fx", "")) == "orbit" else 8):
			var ang := _t * 0.4 + TAU * i / 8.0
			var p := c + Vector2(cos(ang) * r.size.x * 0.3, sin(ang) * r.size.y * 0.12) + Vector2(0, 30)
			var el := "any" if i == 7 else String(Lore.GODS[Lore.GREAT_GODS[i]].element)
			var col := Color.WHITE if i == 7 else Lore.color(el, 0)
			draw_circle(p, 16, Color(col, 0.18 * a))
			draw_circle(p, 6, Color(col, 0.95 * a))
