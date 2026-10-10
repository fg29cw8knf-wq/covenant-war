class_name OpeningMovie
extends CanvasLayer
## The opening movie, "The Throne of Ages".
##
## Plays, in order of preference:
##   1. the finished cut: res://assets/movies/opening.ogv
##   2. shot by shot: res://assets/movies/shots/<shot>.ogv for each shot,
##      or the still res://assets/art/movie/<shot>.png (or .jpg) animated in the engine,
##      or, when neither exists yet, an animatic card describing the shot.
## Narration subtitles follow the Master Script v2 timings (2:24, the title at 2:14).
## Voice lines (res://assets/audio/vo/vo_<n>.ogg) and music (res://assets/audio/opening_theme.ogg)
## play when present. Tap to show Skip. The files to make are listed in
## "Opening Movie: Your Step-by-Step".

signal finished

## Script: start time (s), length (s), narration, what we see, camera move, overlay effect.
const SHOTS := [
	{"id": "shot_01", "len": 8.0, "vo": "Before the first king, before the first card, there was the Throne.",
		"see": "Black. A spark rises; a sea of golden clouds; the Throne tiny on a distant floating peak.", "move": "in", "fx": "motes_gold"},
	{"id": "shot_02", "len": 8.0, "vo": "Whoever sits upon it commands every drop of magic in creation.",
		"see": "The empty Throne; rivers of light flow up into it.", "move": "up", "fx": "motes_gold"},
	{"id": "shot_03", "len": 9.0, "vo": "Once, the gods fought over it, and the heavens broke. So the first gods wrote the Covenant.",
		"see": "Giant god silhouettes carve runes into a floating stone ring.", "move": "right", "fx": "sparks"},
	{"id": "shot_04", "len": 11.0, "vo": "One god would rule for one Age: two thousand years. No god may destroy another. And all magic that falls to the world below must obey its law.",
		"see": "The rune ring locks around the Throne; a shockwave rolls across the clouds.", "move": "out", "fx": "motes_gold"},
	{"id": "shot_05", "len": 8.0, "vo": "For two thousand years, the Throne has belonged to Solmaris, the Radiant Sovereign.",
		"see": "Solmaris on the Throne, eyes closed, serene and cold.", "move": "in", "fx": "motes_gold"},
	{"id": "shot_06", "len": 6.0, "vo": "Now her Age is ending.",
		"see": "Her eyes open; the shadow of the sky-sized sundial touches the last rune.", "move": "up", "fx": "flash"},
	{"id": "shot_07a", "len": 2.0, "vo": "And the others are coming for her crown.",
		"see": "Pyrrhane, the Burning Crown, rises from a sea of fire.", "move": "in", "fx": "embers", "god": "pyrrhane"},
	{"id": "shot_07b", "len": 2.0, "vo": "", "see": "Vaelith, the Frost Queen, on still black water.", "move": "in", "fx": "snow", "god": "vaelith"},
	{"id": "shot_07c", "len": 2.0, "vo": "", "see": "Ixara, the Storm Herald, bursts through the storm.", "move": "in", "fx": "flash", "god": "ixara"},
	{"id": "shot_07d", "len": 2.0, "vo": "", "see": "Nocthra, the Veiled Mother, and a thousand moths.", "move": "in", "fx": "moths", "god": "nocthra"},
	{"id": "shot_07e", "len": 2.0, "vo": "", "see": "Oriel, the Dreaming Eye, opens her many eyes.", "move": "in", "fx": "motes", "god": "oriel"},
	{"id": "shot_07f", "len": 2.0, "vo": "", "see": "Aldrith, the Runeweaver, locks his rune circles.", "move": "in", "fx": "motes", "god": "aldrith"},
	{"id": "shot_08", "len": 8.0, "vo": "Gods cannot kill gods. So they will fight through us.",
		"see": "The seven powers collide; the sky shatters like glass.", "move": "in", "fx": "flash"},
	{"id": "shot_09a", "len": 5.0, "vo": "Every blow tears the sky, and their magic falls to the world of Veyl,",
		"see": "Light falls to Veyl.", "move": "down", "fx": "falling"},
	{"id": "shot_09b", "len": 5.0, "vo": "crystallised into Sigils.",
		"see": "One streak cools into a card in a field.", "move": "in", "fx": "sparks"},
	{"id": "shot_10", "len": 9.0, "vo": "Those who can wield a Sigil can summon what sleeps inside it.",
		"see": "A duellist raises a card and Blazehound bursts out onto a rune circle.", "move": "in", "fx": "embers"},
	{"id": "shot_11", "len": 9.0, "vo": "Kingdoms rose on Sigil wealth. Now wars are fought with cards, not swords.",
		"see": "Two armies at dusk; Boulderox and Voltlynx clash above a giant duelling circle.", "move": "up", "fx": "sparks"},
	{"id": "shot_12", "len": 10.0, "vo": "Each kingdom is ruled by a Champion sworn to a god. When an Age ends, anyone may challenge them, and the seven who still stand fight for the Throne.",
		"see": "Seven beams fall on seven kingdoms; seven marks burn onto seven hands.", "move": "out", "fx": "falling"},
	{"id": "shot_12b", "len": 10.0, "vo": "And in Ironvault, a mortal king who owns half the world has begun to wonder why the other half belongs to the gods.",
		"see": "A vault of glowing cards; a gold-ringed hand turns over a card beside a gold case with eight empty slots. The face is never shown.", "move": "left", "fx": "motes_gold"},
	{"id": "shot_13", "len": 8.0, "vo": "But on the last night of the Age, over a village no one had ever heard of...",
		"see": "Ashford at night; the sky tears open.", "move": "in", "fx": "falling"},
	{"id": "shot_15", "len": 18.0, "vo": "...the Covenant did something it had never done before.",
		"see": "The Throne with seven orbiting lights; an eighth, pure white, ignites and joins them.", "move": "out", "fx": "motes_gold",
		"title": true, "title_at": 8.0},
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

	_video = VideoStreamPlayer.new()
	_video.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_video.expand = true
	_video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_video.visible = false
	_root.add_child(_video)

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
	_skip.offset_left = -250
	_skip.offset_right = -40
	_skip.offset_top = 36
	_skip.offset_bottom = 132
	_skip.modulate.a = 0.0
	_skip.pressed.connect(_finish)
	_root.add_child(_skip)

	_music = AudioStreamPlayer.new()
	add_child(_music)
	_voice = AudioStreamPlayer.new()
	add_child(_voice)
	_play.call_deferred()


func _play() -> void:
	if ResourceLoader.exists(MUSIC):
		_music.stream = load(MUSIC)
		_music.play()
	if ResourceLoader.exists(MOVIE):
		await _play_full_cut()
	else:
		await _play_shots()
	_finish()


func _play_full_cut() -> void:
	_stage.visible = false
	_video.stream = load(MOVIE)
	_video.visible = true
	_video.play()
	var t := 0.0
	var i := 0
	var start := 0.0
	while _video.is_playing() and not _done:
		await get_tree().process_frame
		t = _video.stream_position
		while i < SHOTS.size() and t >= start + float(SHOTS[i].len):
			start += float(SHOTS[i].len)
			i += 1
		_set_sub(SHOTS[i].vo if i < SHOTS.size() else "")


func _play_shots() -> void:
	var n := 0
	for shot in SHOTS:
		if _done:
			return
		n += 1
		var id: String = shot.id
		var clip := "res://assets/movies/shots/%s.ogv" % id
		var still := _still_path(id)
		_set_sub(String(shot.vo))
		var vo_path := "res://assets/audio/vo/vo_%s.ogg" % id.trim_prefix("shot_")
		if ResourceLoader.exists(vo_path):
			_voice.stream = load(vo_path)
			_voice.play()
		if ResourceLoader.exists(clip):
			_stage.visible = false
			_video.stream = load(clip)
			_video.visible = true
			_video.play()
		else:
			_video.stop()
			_video.visible = false
			_stage.visible = true
			_stage.show_shot(shot, load(still) if still != "" else null, n)
		await _wait(float(shot.len))


## The shot's painting, as a PNG or a JPG, or "" until it's been made.
static func _still_path(id: String) -> String:
	for ext in ["png", "jpg"]:
		var p := "res://assets/art/movie/%s.%s" % [id, ext]
		if ResourceLoader.exists(p):
			return p
	return ""


func _wait(sec: float) -> void:
	var t := 0.0
	while t < sec and not _done:
		await get_tree().process_frame
		t += get_process_delta_time()


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


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("menu"):
		_finish()
	elif e.is_action_pressed("interact"):
		_show_skip()


func _show_skip() -> void:
	create_tween().tween_property(_skip, "modulate:a", 1.0, 0.2)
	_skip.grab_focus()
	var my_timer := get_tree().create_timer(3.5)
	_skip_timer = my_timer
	await my_timer.timeout
	if _skip_timer == my_timer and not _done:
		create_tween().tween_property(_skip, "modulate:a", 0.0, 0.4)


func _finish() -> void:
	if _done:
		return
	_done = true
	_video.stop()
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 0.0, 0.6)
	tw.parallel().tween_property(_music, "volume_db", -40.0, 0.6)
	await tw.finished
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

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func show_shot(s: Dictionary, tex: Texture2D, n: int) -> void:
		shot = s
		still = tex
		number = n
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
		if still != null:
			_draw_still(r, k)
		else:
			_draw_card(r, title_t < 0.0)
		_draw_fx(r)
		if title_t >= 0.0:
			_draw_title(r, title_t)
		# letterbox bars and vignette give every shot the same frame
		var bar := r.size.y * 0.06
		draw_rect(Rect2(0, 0, r.size.x, bar), Color.BLACK)
		draw_rect(Rect2(0, r.size.y - bar, r.size.x, bar), Color.BLACK)

	func _draw_still(r: Rect2, k: float) -> void:
		var e := k * k * (3.0 - 2.0 * k)
		var zoom := 1.06
		var off := Vector2.ZERO
		match String(shot.get("move", "in")):
			"in":
				zoom = lerpf(1.02, 1.12, e)
			"out":
				zoom = lerpf(1.14, 1.02, e)
			"up":
				zoom = 1.1
				off = Vector2(0, lerpf(0.04, -0.04, e))
			"down":
				zoom = 1.1
				off = Vector2(0, lerpf(-0.04, 0.04, e))
			"left":
				zoom = 1.1
				off = Vector2(lerpf(0.04, -0.04, e), 0)
			"right":
				zoom = 1.1
				off = Vector2(lerpf(-0.04, 0.04, e), 0)
		var sz := r.size * zoom
		var pos := (r.size - sz) * 0.5 + off * r.size
		CardFace.draw_cover(self, Rect2(pos, sz), still, 0.5)

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
		# eight lights circling
		for i in 8:
			var ang := _t * 0.4 + TAU * i / 8.0
			var p := c + Vector2(cos(ang) * r.size.x * 0.3, sin(ang) * r.size.y * 0.12) + Vector2(0, 30)
			var el := "any" if i == 7 else String(Lore.GODS[Lore.GREAT_GODS[i]].element)
			var col := Color.WHITE if i == 7 else Lore.color(el, 0)
			draw_circle(p, 16, Color(col, 0.18 * a))
			draw_circle(p, 6, Color(col, 0.95 * a))
