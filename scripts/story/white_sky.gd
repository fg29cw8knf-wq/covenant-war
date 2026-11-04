class_name WhiteSky
extends CanvasLayer
## The Night of the White Sky (3 November 2026, Gary: "add that to the story
## and build it"; "Bram should face a faceless hunter"): the memory that opens
## a New Game, twenty years before the attic. It takes the place of the five
## seconds of stars that were the dream.
##
##   1. Black, the caption "The Shardlands / Twenty years ago."; the night sky
##      over the snow, Morrowen's line ("Every soul in my book starts with a
##      debt...") over it.
##   2. The sky tears white over the Shardlands and cards rain down as Sigils.
##   3. The player walks as Bram, seen from behind and never his face, through
##      the storm towards the light of a crater (gated: hold to walk). Something
##      stands in the snow off to the side, and is gone.
##   4. In the crater, a crying baby with an ash-grey mark. The player picks the
##      child up (gated), Bram tucks it into his coat ("Hush, now. I've got
##      you."), and turns: the faceless hunter on the crater's rim.
##      "Not this one."
##   5. Bram's duel, filmed: the real duel engine (DuelScreen, spec.film) with
##      no HUD and the camera directed, out in the snow; Bram's old Ironstone
##      against the hunter's pale hounds of Sigil light. Bram plays one-handed,
##      the child in his coat; he is losing; he calls down Grondmaw, the
##      Mountain's Heart, and the screen burns white. Nobody sees who won.
##   6. Black. Morrowen: "Twenty years later, the debt came due." Then the attic
##      (AshfordP1._attic): the player wakes, the mark under his collar fading.
##
## A tap skips the filmed duel; once the memory has been seen (Game.settings
## seen_white_sky, kept across saves) a Skip button skips all of it. The gate
## at dawn and the clerk counting the crowns are kept back for the Reckoning
## (the reckoning film's shot rk_02b), so the opening doesn't say where Bram's
## gold came from.
##
##   var m := WhiteSky.new(); m.w = world; add_child(m); await m.play()
##
## tests/white_sky_test.tscn plays it on its own and takes stills;
## tests/white_sky_probe.gd finds the duel's seed (SEED).

signal finished

# ----------------------------------------------------------------- lines ---
const OPEN := {"who": "morrowen", "say": "Every soul in my book starts with a debt. Most spend a lifetime paying interest on a life they never asked for, trying to balance an account that was written before they were born.", "vo": "morrowen_attic"}
const HUSH := {"who": "bram", "say": "Hush, now. I've got you."}
const NOT_THIS := {"who": "bram", "say": "Not this one."}
const DEBT_DUE := {"who": "morrowen", "say": "Twenty years later, the debt came due."}
const CAPTION := ["The Shardlands", "Twenty years ago."]
## The falling Sigils' colours (the village's, Ashford.SIGIL_COLS).
const SIGIL_COLS := [Color(1.0, 0.25, 0.12), Color(1.0, 0.55, 0.12), Color(1.0, 0.85, 0.35), Color(0.35, 0.7, 1.0),
	Color(0.65, 0.3, 1.0), Color(0.2, 1.0, 0.8), Color(0.45, 1.0, 0.3), Color(1.0, 0.35, 0.7)]

## The bracketed instructions (never in a character's voice), by device.
const HOW_WALK := {"phone": "(Touch and hold anywhere to walk.)", "tablet": "(Touch and hold anywhere to walk.)",
	"computer": "(Hold W or the up arrow to walk.)", "controller": "(Push the left stick up to walk.)"}
const HOW_TAKE := {"phone": "(Tap the screen to pick up the child.)", "tablet": "(Tap the screen to pick up the child.)",
	"computer": "(Press E, or click, to pick up the child.)", "controller": "(Press A to pick up the child.)"}

# ------------------------------------------------------------------ duel ---
## The duel itself (decks, seed, skill) is WhiteSkyDuel's, so its probe can
## run without the game's autoloads.
## Where Bram and the hunter stand on the duel's field (its own coordinates:
## Bram's row at z 2, the hunter's at -2.6).
const BRAM_AT := Vector3(-0.6, 0.0, 6.4)
const HUNTER_AT := Vector3(0.0, 0.0, -7.4)
## The film's shots: [camera, looking at, lens]. Every one is on Bram's side
## of him or looking away from him, so his face is never seen.
const SHOTS := [
	[Vector3(1.9, 3.4, 12.4), Vector3(0.0, 1.0, -1.6), 42.0],
	[Vector3(-3.6, 1.5, 9.6), Vector3(0.4, 1.4, -3.0), 36.0],
	[Vector3(9.4, 2.4, 2.8), Vector3(-1.0, 0.9, -1.2), 40.0],
	[Vector3(0.6, 1.0, 10.2), Vector3(0.0, 2.4, -7.4), 32.0],
	[Vector3(-9.0, 2.8, 0.6), Vector3(1.2, 0.8, -1.0), 40.0],
]
const SHOT_SECS := 6.5
## When Grondmaw is called: low behind Bram, up past the hunter.
const CLIMAX := [Vector3(1.2, 0.9, 10.6), Vector3(0.0, 3.6, -6.0), 46.0]
## The longest the duel may run before the white comes anyway (s).
const FILM_MAX := 140.0

# ------------------------------------------------------------------- set ---
## The crater the child lies in (the set's own coordinates; Bram walks from
## WALK_FROM towards it, -z).
const CRATER := Vector3(0.0, 0.0, -30.0)
const CRATER_R := 7.0
const CRATER_DEPTH := 2.4
const WALK_FROM := Vector3(0.0, 0.0, -2.0)
const WALK_TO := Vector3(0.0, 0.0, -21.6)
const WALK_SPEED := 1.25
## Where the hunter is glimpsed during the walk (shown when Bram passes
## GLIMPSE_AT of the way), and where it stands on the rim.
const GLIMPSE := Vector3(-13.0, 0.0, -16.0)
const GLIMPSE_AT := 0.55
const RIM_STAND := Vector3(0.0, 0.0, -38.6)
## Gary's models, used when they exist (stand-ins are drawn till then).
const BABY_MODEL := "res://assets/models/ashford/baby_bundle.glb"

var w: World = null            # the world it plays in (null in its test)
var quality := 2
var _root: Control
var _vpc: SubViewportContainer
var _vp: SubViewport
var _set: Node3D
var _cam: Camera3D
var _env: Environment
var _sky: ShaderMaterial
var _moon: DirectionalLight3D
var _tear_light: DirectionalLight3D
var _crater_light: OmniLight3D
var _ground_mat: ShaderMaterial
var _snow: GPUParticles3D
var _bram: Node3D
var _baby: Node3D
var _hunter: Hunter
var _ov: CineOverlay
var _black: ColorRect
var _white: ColorRect
var _hint: Label
var _skip: Button
var _screen: DuelScreen
var _wind: AudioStreamPlayer
var _cry: AudioStreamPlayer
var _t := 0.0
var _cam_pos := Vector3.ZERO
var _cam_look := Vector3.ZERO
var _cam_ease := 0.0          # 0: cut; otherwise how fast the camera follows
var _held := false            # a finger or the mouse held down
var _tapped := false
var _last_input := ""
var _skipping := false
var _done := false
var _falling: Array = []      # [node, velocity, spin]
var _rng := RandomNumberGenerator.new()


static func seen() -> bool:
	return bool(Game.settings.get("seen_white_sky", false))


func _ready() -> void:
	layer = 13               # under the subtitles (CineOverlay is 14)
	_rng.seed = 2006
	quality = Gfx.level()
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UITheme.make()
	add_child(_root)
	_vpc = SubViewportContainer.new()
	_vpc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vpc.stretch = true
	_vpc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_vpc)
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.msaa_3d = Viewport.MSAA_2X if quality >= 2 else Viewport.MSAA_DISABLED
	if quality >= 1:
		_vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	_vpc.add_child(_vp)
	Gfx.apply(_vp)
	_build_set()
	_black = _rect(Color.BLACK, 1.0)
	_white = _rect(Color(1.0, 0.99, 0.96), 0.0)
	_hint = Label.new()
	_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.offset_top = -170
	_hint.offset_bottom = -110
	_hint.offset_left = -700
	_hint.offset_right = 700
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", int(30 * SafeArea.ui_scale()))
	_hint.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_hint.add_theme_constant_override("outline_size", 8)
	_hint.modulate.a = 0.0
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_hint)
	_skip = Button.new()
	_skip.text = "Skip  ▸▸"
	_skip.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_skip.offset_left = -230
	_skip.offset_right = -36
	_skip.offset_top = 36
	_skip.offset_bottom = 36 + UITheme.TOUCH
	_skip.visible = false
	_skip.focus_mode = Control.FOCUS_NONE
	_skip.pressed.connect(skip)
	_root.add_child(_skip)
	_wind = _sound("storm_wind", -14.0, true)
	_cry = _sound("baby_cry", -6.0, true)


func _rect(col: Color, a: float) -> ColorRect:
	var r := ColorRect.new()
	r.color = col
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.modulate.a = a
	_root.add_child(r)
	return r


## A sound from assets/sfx (Gary's: storm_wind, a loop, and baby_cry), or
## nothing until it's there.
func _sound(nm: String, db: float, loop: bool) -> AudioStreamPlayer:
	for ext in ["ogg", "wav", "mp3"]:
		var p := "res://assets/sfx/%s.%s" % [nm, ext]
		if ResourceLoader.exists(p):
			var s: AudioStream = load(p)
			if loop and s is AudioStreamOggVorbis:
				(s as AudioStreamOggVorbis).loop = true
			var a := AudioStreamPlayer.new()
			a.stream = s
			a.volume_db = db
			add_child(a)
			return a
	return null


# ================================================================== play ===

## Plays the whole memory; returns once it has ended on black.
func play() -> void:
	_ov = Cine.overlay(w) if w != null else _own_overlay()
	_skip.visible = seen()
	if w != null:
		_ov.black(false)
	Music.play(["white_sky", "sigilfall"], 2.0)
	if _wind != null:
		_wind.play()
	await _open()
	if not _skipping:
		await _sigilfall()
	if not _skipping:
		await _walk()
	if not _skipping:
		await _crater()
	if not _skipping:
		await _the_hunter()
	if not _skipping:
		await _duel()
	await _close()


func _own_overlay() -> CineOverlay:
	var ov := CineOverlay.new()
	add_child(ov)
	return ov


## Skips the rest: the white, then the last line and the attic.
func skip() -> void:
	_skipping = true
	_skip.visible = false
	if _ov != null and _ov._waiting:
		_ov._next.emit()
	_tapped = true


# --- 1. the sky ---------------------------------------------------------
func _open() -> void:
	_shot(Vector3(0.6, 1.5, 3.0), Vector3(2.0, 9.0, -30.0), 52.0)
	_bram.position = Vector3(WALK_FROM.x, height(WALK_FROM.x, WALK_FROM.z), WALK_FROM.z)
	await _ov.caption(CAPTION[0], CAPTION[1], 2.6)
	if _skipping:
		return
	_fade(_black, 0.0, 2.2)
	_drift(Vector3(0.6, 1.5, 3.0), Vector3(0.4, 1.6, 2.2), Vector3(2.0, 9.0, -30.0), Vector3(1.2, 10.0, -30.0), 14.0)
	await _wait(1.0)
	await _say(OPEN)


# --- 2. the sky tears ---------------------------------------------------------
func _sigilfall() -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_method(func(k: float) -> void: _sky.set_shader_parameter("tear_open", k), 0.0, 1.25, 3.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_tear_light, "light_energy", 0.55, 3.0)
	tw.tween_property(_env, "fog_light_color", Color(0.22, 0.2, 0.34), 3.0)
	# the white of the tear washes over the screen once, as it opens
	var fl := create_tween()
	fl.tween_interval(1.0)
	fl.tween_property(_white, "modulate:a", 0.55, 0.35)
	fl.tween_property(_white, "modulate:a", 0.0, 1.6)
	_strike_burst(6, 0.4)
	await _wait(1.8)
	# down to Bram, from behind, looking up at it
	_shot(WALK_FROM + Vector3(0.7, 1.75, 2.6), WALK_FROM + Vector3(0.0, 4.5, -12.0), 50.0)
	_face(_bram, Vector3.FORWARD)
	_act(_bram, "look_up")
	_rain_cards(true)
	await _wait(3.4)


# --- 3. the walk ------------------------------------------------------------------
func _walk() -> void:
	_show_hint(HOW_WALK)
	var pos := WALK_FROM
	var glimpsed := false
	var total := WALK_FROM.distance_to(WALK_TO)
	var flat := WALK_FROM   # where he is on the plan (y 0); pos.y is the snow's
	_follow(pos)
	while flat.distance_to(WALK_TO) > 0.05 and not _skipping:
		var dt := get_process_delta_time()
		var go := _walk_held()
		_set_walking(_bram, go)
		if go:
			_hide_hint()
			flat = flat.move_toward(WALK_TO, WALK_SPEED * dt)
			pos = Vector3(flat.x, height(flat.x, flat.z), flat.z)
			_bram.position = pos
			_face(_bram, Vector3.FORWARD)
		_follow(pos)
		var k := 1.0 - flat.distance_to(WALK_TO) / total
		if not glimpsed and k >= GLIMPSE_AT:
			glimpsed = true
			_glimpse()
		await get_tree().process_frame
	_set_walking(_bram, false)
	_hide_hint()


func _walk_held() -> bool:
	if _held:
		return true
	return Input.is_action_pressed("move_up") or Input.is_action_pressed("interact")


## The hunter, off to the side in the snow, for a few seconds: then a gust and
## it's gone.
func _glimpse() -> void:
	_hunter.position = Vector3(GLIMPSE.x, height(GLIMPSE.x, GLIMPSE.z), GLIMPSE.z)
	_hunter.look_at_dir(_bram.position - _hunter.position)
	_hunter.visible = true
	_hunter.fade_to(1.0, 1.2)
	await _wait(3.4)
	if is_instance_valid(_hunter):
		_gust(_hunter.position)
		await _hunter.fade_to(0.0, 0.9)
		_hunter.visible = false


# --- 4. the crater --------------------------------------------------------------
func _crater() -> void:
	# over the rim: down to where the light is, from behind and above him
	var bottom := CRATER + Vector3(0.0, 0.0, 1.05)
	bottom.y = height(bottom.x, bottom.z)
	_shot(WALK_TO + Vector3(1.6, 3.6, 3.4), CRATER + Vector3(0, -1.5, 0), 44.0)
	if _cry != null:
		_cry.play()
	_set_walking(_bram, true)
	var from := _bram.position
	var steps := 70
	for i in steps + 1:
		if _skipping:
			return
		var p := from.lerp(bottom, float(i) / steps)
		p.y = height(p.x, p.z)
		_bram.position = p
		await _wait(5.0 / steps)
	_set_walking(_bram, false)
	_face(_bram, Vector3.FORWARD)
	# close, over his shoulder, down at the child
	_shot(bottom + Vector3(0.75, 1.9, 1.15), CRATER + Vector3(0, 0.15, 0), 34.0)
	await _wait(1.2)
	_show_hint(HOW_TAKE)
	_tapped = false
	while not _tapped and not _skipping:
		if Input.is_action_just_pressed("interact"):
			break
		await get_tree().process_frame
	_hide_hint()
	if _skipping:
		return
	# he bends and lifts the child; the crying stops in his arms
	var lift := _act(_bram, "lift")
	await _wait(0.6 if lift else 0.1)
	_pick_up()
	if _cry != null:
		var ct := create_tween()
		ct.tween_property(_cry, "volume_db", -40.0, 1.6)
		ct.tween_callback(_cry.stop)
	await _wait(1.0)
	# over his shoulder, down at the child in his arms
	_shot(bottom + Vector3(0.85, 2.45, 1.7), bottom + Vector3(0.0, 1.05, -0.35), 36.0)
	await _say(HUSH)
	# into his coat, held in his left arm from here on
	_tuck()
	await _wait(0.8)


# --- the hunter on the rim ----------------------------------------------------
func _the_hunter() -> void:
	_gust(RIM_STAND)
	_hunter.position = Vector3(RIM_STAND.x, height(RIM_STAND.x, RIM_STAND.z), RIM_STAND.z)
	_hunter.look_at_dir(_bram.position - _hunter.position)
	_hunter.visible = true
	_hunter.fade_to(1.0, 0.8)
	var b := _bram.position
	# low behind his right shoulder, up at the rim
	_shot(b + Vector3(0.9, 1.0, 2.6), _hunter.position + Vector3(0, 2.2, 0), 38.0)
	await _wait(1.6)
	_drift(b + Vector3(0.9, 1.0, 2.6), b + Vector3(0.6, 1.2, 2.0), _hunter.position + Vector3(0, 2.2, 0), _hunter.position + Vector3(0, 2.0, 0), 6.0)
	await _say(NOT_THIS)
	if _skipping:
		return
	# it lifts a hand: cards rise from the snow about it, white
	_hunter.raise_cards()
	await _wait(1.6)
	var fl := create_tween()
	fl.tween_property(_white, "modulate:a", 1.0, 0.5)
	await fl.finished


# --- 5. the duel, filmed ----------------------------------------------------------
func _duel() -> void:
	_skip.visible = true          # a filmed duel can always be skipped
	var spec := duel_spec()
	_screen = DuelScreen.new().configure(spec)
	_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_screen)
	_root.move_child(_screen, _vpc.get_index() + 1)
	while _screen.game == null:
		await get_tree().process_frame
	_vpc.visible = false
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var f := _screen.field
	if f != null:
		_bram.reparent(f.world, false)
		_bram.position = BRAM_AT
		_face(_bram, Vector3.FORWARD)
		_hunter.reparent(f.world, false)
		_hunter.position = HUNTER_AT
		_hunter.scale = Vector3.ONE * 1.15
		_hunter.look_at_dir(Vector3.BACK)
		_hunter.lower_cards()
		_hunter.visible = true
		_hunter._set_fade(1.0)
	var st := {"called": -1.0, "struck": -1.0, "over": false}
	_screen.game.logged.connect(func(t: String, who: int) -> void:
		if who == 0 and is_instance_valid(_bram) and (t.contains(" plays ") or t.contains(" calls ") or t.contains(" sets ")):
			_act(_bram, "play_card")
		if who == 0 and t.contains("calls down") and t.contains("Grondmaw") and st.called < 0.0:
			st.called = _t
		# the Mountain's Heart's blow landing on the hunter's side
		if st.called >= 0.0 and st.struck < 0.0 and who == 1 and t.contains(" takes "):
			st.struck = _t)
	_screen.finished.connect(func(_r) -> void: st.over = true)
	var fade := create_tween()
	fade.tween_property(_white, "modulate:a", 0.0, 1.2)
	var start := _t
	var shot_i := 0
	var next_shot := 0.0
	var climax := false
	while not _skipping and not st.over and _t - start < FILM_MAX:
		if f != null and st.called >= 0.0 and not climax:
			# the Mountain's Heart: low behind him, looking up past the
			# hunter at what's coming down
			climax = true
			var c: Array = CLIMAX
			f.cam_fov = float(c[2])
			f.set_home(c[0], c[1])
			f.cam_home(1.4)
		if f != null and _t >= next_shot and st.called < 0.0:
			var s: Array = SHOTS[shot_i % SHOTS.size()]
			f.cam_fov = float(s[2])
			f.set_home(s[0], s[1])
			f.cam_home(2.4)
			shot_i += 1
			next_shot = _t + SHOT_SECS
		if st.called >= 0.0 and ((st.struck >= 0.0 and _t - st.struck > 0.5) or _t - st.called > 9.0):
			break
		if _tapped and not _skip.visible:
			break
		await get_tree().process_frame
	# the white: the Mountain's Heart's blow, or the end of the film
	var wt := create_tween()
	wt.tween_property(_white, "modulate:a", 1.0, 1.2 if not _skipping else 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await wt.finished


## The filmed duel's spec for DuelScreen (tests read it too).
static func duel_spec() -> Dictionary:
	var D := WhiteSkyDuel
	return {"decks": [D.bram_deck(D.SEED, D.GRONDMAW_AT), D.hunter_deck(D.SEED)], "stacked": [true, true],
		"puzzle": D.board(), "story_rules": D.story_rules(),
		"names": ["Bram", "The hunter"], "profiles": [D.bram_profile(), D.hunter_profile()],
		"ai": [true, true], "difficulty": D.SKILL, "seed": D.SEED, "speed": D.FILM_SPEED,
		"film": true, "arena": "ironstone", "spectral_side": 1, "life_floor": D.LIFE_FLOOR.duplicate(),
		"music": ["white_sky", "sigilfall"], "film_home": SHOTS[0], "field3d": true}


# --- 6. the end ---------------------------------------------------------------------
func _close() -> void:
	_skip.visible = false
	_hide_hint()
	if _white.modulate.a < 0.99:
		var wt := create_tween()
		wt.tween_property(_white, "modulate:a", 1.0, 0.5)
		await wt.finished
	await _wait(0.6)
	if is_instance_valid(_screen):
		_screen.queue_free()
	_black.modulate.a = 0.0
	_root.move_child(_black, _root.get_child_count() - 1)
	var bt := create_tween()
	bt.tween_property(_black, "modulate:a", 1.0, 1.4)
	if _wind != null:
		create_tween().tween_property(_wind, "volume_db", -60.0, 2.0)
	Music.stop(2.0)
	await bt.finished
	_skipping = false
	await _say(DEBT_DUE, true)
	Game.settings["seen_white_sky"] = true
	Game.save_settings()
	_done = true
	finished.emit()


# ================================================================== the set ===

## The snow's height at (x, z): gentle drifts, and the crater (a bowl
## CRATER_DEPTH deep with a raised lip round it).
static func height(x: float, z: float) -> float:
	var d := Vector2(x - CRATER.x, z - CRATER.z).length()
	var h := 0.22 * sin(x * 0.21 + 1.3) * cos(z * 0.17 - 0.4) + 0.12 * sin(x * 0.53 + z * 0.41)
	var r := d / CRATER_R
	if r < 1.0:
		h -= CRATER_DEPTH * (1.0 - r * r) * (1.0 - r * r * 0.15)
	h += 0.75 * exp(-pow((d - CRATER_R) / 1.7, 2.0))
	# the drifts flatten into the bowl
	return h


func _build_set() -> void:
	_set = Node3D.new()
	_vp.add_child(_set)
	_env = Environment.new()
	var sky := Sky.new()
	_sky = ShaderMaterial.new()
	_sky.shader = load("res://assets/shaders/village/sky.gdshader")
	_sky.set_shader_parameter("zenith", Color(0.008, 0.012, 0.03))
	_sky.set_shader_parameter("horizon", Color(0.07, 0.08, 0.13))
	_sky.set_shader_parameter("tear_open", 0.0)
	_sky.set_shader_parameter("sky_dim", 0.8)
	_sky.set_shader_parameter("tear_a", Vector3(-0.55, 0.62, -0.56))
	_sky.set_shader_parameter("tear_b", Vector3(0.6, 0.35, -0.72))
	sky.sky_material = _sky
	_env.background_mode = Environment.BG_SKY
	_env.sky = sky
	# a cold night: little light but the moon's, the crater's and the Sigils'
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color(0.3, 0.38, 0.58)
	_env.ambient_light_energy = 0.42
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_env.tonemap_white = 1.6
	_env.glow_enabled = true
	_env.glow_intensity = 0.75
	_env.glow_hdr_threshold = 1.0
	_env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	_env.fog_enabled = true
	_env.fog_light_color = Color(0.13, 0.15, 0.22)
	_env.fog_density = 0.034
	_env.fog_sky_affect = 0.25
	if quality >= 2:
		_env.volumetric_fog_enabled = true
		_env.volumetric_fog_density = 0.018
		_env.volumetric_fog_albedo = Color(0.75, 0.8, 0.95)
		_env.volumetric_fog_length = 48.0
		_env.ssao_enabled = true
	_env.adjustment_enabled = true
	_env.adjustment_contrast = 1.12
	_env.adjustment_saturation = 0.85
	var we := WorldEnvironment.new()
	we.environment = _env
	_set.add_child(we)
	_moon = DirectionalLight3D.new()
	_moon.rotation_degrees = Vector3(-32, 140, 0)
	_moon.light_color = Color(0.66, 0.74, 1.0)
	_moon.light_energy = 0.62
	_moon.shadow_enabled = true
	_moon.directional_shadow_max_distance = 60.0
	_set.add_child(_moon)
	_tear_light = DirectionalLight3D.new()
	_tear_light.rotation_degrees = Vector3(-60, 10, 0)
	_tear_light.light_color = Color(0.7, 0.62, 1.0)
	_tear_light.light_energy = 0.0
	_set.add_child(_tear_light)
	_crater_light = OmniLight3D.new()
	_crater_light.position = CRATER + Vector3(0, -0.6, 0)
	_crater_light.light_color = Color(0.92, 0.95, 1.0)
	_crater_light.light_energy = 2.6
	_crater_light.omni_range = 15.0
	_crater_light.shadow_enabled = quality >= 2
	_set.add_child(_crater_light)
	_build_ground()
	_build_spires()
	_build_crater_shards()
	_snow = DuelField3D.snow_particles([1400, 3000, 5200][clampi(quality, 0, 2)], Vector3(16, 9, 16), Vector3(-5.5, -2.8, 1.6), 0.075)
	_set.add_child(_snow)
	_cam = Camera3D.new()
	_cam.near = 0.05
	_cam.far = 400.0
	_set.add_child(_cam)
	_cam.current = true
	var who := "bram_coat" if Figure3D.has_model("bram_coat") else "bram"
	_bram = Figure3D.make(who, who)
	_set.add_child(_bram)
	_bram.position = WALK_FROM
	_face(_bram, Vector3.FORWARD)   # his back to us, from the first frame
	_dress_bram.call_deferred()
	_baby = _make_baby()
	_set.add_child(_baby)
	var bp := CRATER + Vector3(0.0, 0.0, 0.0)
	bp.y = height(bp.x, bp.z) + 0.1
	_baby.position = bp
	_baby.rotation.y = 0.6
	_hunter = Hunter.new()
	_hunter.visible = false
	_set.add_child(_hunter)


func _build_ground() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 150 if quality >= 1 else 96
	var size := 150.0
	var c0 := Vector3(0, 0, -25)
	for iz in n + 1:
		for ix in n + 1:
			var x: float = c0.x - size * 0.5 + float(ix) / n * size
			var z: float = c0.z - size * 0.5 + float(iz) / n * size
			st.set_uv(Vector2(x, z) * 0.1)
			st.add_vertex(Vector3(x, height(x, z), z))
	for iz in n:
		for ix in n:
			var a := iz * (n + 1) + ix
			var b := a + 1
			var c := a + n + 1
			var d := c + 1
			for k in [a, b, d, a, d, c]:
				st.add_index(k)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	_ground_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = SNOW
	_ground_mat.shader = sh
	_ground_mat.set_shader_parameter("crater", CRATER)
	_ground_mat.set_shader_parameter("crater_r", CRATER_R)
	mi.material_override = _ground_mat
	_set.add_child(mi)


## The Shardlands: dark glass spires standing out of the snow, leaning, some
## lit faintly from inside.
func _build_spires() -> void:
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.03, 0.035, 0.05)
	glass.metallic = 0.4
	glass.roughness = 0.08
	glass.emission_enabled = true
	glass.emission = Color(0.3, 0.4, 0.75)
	glass.emission_energy_multiplier = 0.06
	var r := RandomNumberGenerator.new()
	r.seed = 77
	for i in 46:
		var ang := r.randf() * TAU
		var dist := r.randf_range(26.0, 85.0)
		var p := CRATER + Vector3(cos(ang), 0, sin(ang)) * dist
		if absf(p.x) < 6.0 and p.z > -26.0:
			continue   # never across his path
		var cm := CylinderMesh.new()
		cm.radial_segments = 5
		cm.rings = 1
		var hgt := r.randf_range(4.0, 16.0)
		cm.height = hgt
		cm.bottom_radius = hgt * r.randf_range(0.05, 0.09)
		cm.top_radius = 0.0
		var mi := MeshInstance3D.new()
		mi.mesh = cm
		mi.material_override = glass
		mi.position = p + Vector3(0, height(p.x, p.z) + hgt * 0.42, 0)
		mi.rotation = Vector3(r.randf_range(-0.35, 0.35), r.randf() * TAU, r.randf_range(-0.35, 0.35))
		_set.add_child(mi)


## Shards of white glass thrown out of the crater, pointing away from it.
func _build_crater_shards() -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.45, 0.5, 0.62)
	m.metallic = 0.5
	m.roughness = 0.04
	m.emission_enabled = true
	m.emission = Color(0.6, 0.72, 1.0)
	m.emission_energy_multiplier = 0.35
	var r := RandomNumberGenerator.new()
	r.seed = 5
	for i in 26:
		var ang := r.randf() * TAU
		var d := r.randf_range(1.2, CRATER_R + 1.2)
		var p := CRATER + Vector3(cos(ang), 0, sin(ang)) * d
		var cm := CylinderMesh.new()
		cm.radial_segments = 4
		cm.rings = 1
		var hgt := r.randf_range(0.2, 0.75)
		cm.height = hgt
		cm.bottom_radius = hgt * 0.14
		cm.top_radius = 0.0
		var mi := MeshInstance3D.new()
		mi.mesh = cm
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = p + Vector3(0, height(p.x, p.z) + hgt * 0.3, 0)
		var out := Vector3(cos(ang), 0, sin(ang))
		# leaning out of the bowl, away from where it struck
		var up := (Vector3.UP * 0.75 + out * 0.65).normalized()
		var side := out.cross(Vector3.UP).normalized()
		mi.basis = Basis(side, up, side.cross(up))
		_set.add_child(mi)


## The child: a bundle of grey wool, a small face, and over the heart the
## ash-grey mark, glowing faintly (SealMark's painting).
func _make_baby() -> Node3D:
	var root := Node3D.new()
	root.name = "Child"
	if ResourceLoader.exists(BABY_MODEL):
		# Gary's model, laid along z like the drawn one, about 0.5 m long
		var m := (load(BABY_MODEL) as PackedScene).instantiate() as Node3D
		root.add_child(m)
		var aabb := DuelField3D._merged_aabb(m)
		var k := 0.5 / maxf(0.01, maxf(aabb.size.z, maxf(aabb.size.x, aabb.size.y)))
		m.scale = Vector3.ONE * k
		m.position = -aabb.get_center() * k
		var glow := OmniLight3D.new()
		glow.light_color = Color(0.85, 0.85, 0.9)
		glow.light_energy = 0.5
		glow.omni_range = 0.9
		glow.position = Vector3(0, 0.2, -0.1)
		glow.name = "MarkGlow"
		root.add_child(glow)
		return root
	var wool := StandardMaterial3D.new()
	var nt := NoiseTexture2D.new()
	nt.width = 128
	nt.height = 128
	nt.seamless = true
	var fn := FastNoiseLite.new()
	fn.frequency = 0.09
	nt.noise = fn
	var g := Gradient.new()
	g.set_color(0, Color(0.5, 0.47, 0.42))
	g.set_color(1, Color(0.74, 0.7, 0.62))
	nt.color_ramp = g
	wool.albedo_texture = nt
	wool.roughness = 1.0
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.11
	cap.height = 0.5
	body.mesh = cap
	body.material_override = wool
	body.rotation_degrees = Vector3(90, 0, 0)
	root.add_child(body)
	var hood := MeshInstance3D.new()
	var hs := SphereMesh.new()
	hs.radius = 0.1
	hs.height = 0.2
	hood.mesh = hs
	hood.material_override = wool
	hood.position = Vector3(0, 0.02, -0.2)
	hood.scale = Vector3(1.05, 1.0, 0.9)
	root.add_child(hood)
	var face := MeshInstance3D.new()
	var fs := SphereMesh.new()
	fs.radius = 0.06
	fs.height = 0.12
	face.mesh = fs
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.86, 0.68, 0.6)
	skin.roughness = 0.7
	if quality >= 2:
		skin.subsurf_scatter_enabled = true
		skin.subsurf_scatter_strength = 0.4
	face.material_override = skin
	face.position = Vector3(0, 0.06, -0.19)
	root.add_child(face)
	var mark := MeshInstance3D.new()
	var mq := QuadMesh.new()
	mq.size = Vector2(0.06, 0.06)
	mark.mesh = mq
	var mm := StandardMaterial3D.new()
	mm.albedo_texture = SealMark.texture()
	mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mm.albedo_color = SealMark.ASH
	mm.emission_enabled = true
	mm.emission = Color(0.75, 0.75, 0.8)
	mm.emission_energy_multiplier = 0.8
	mm.emission_texture = SealMark.texture()
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mark.material_override = mm
	mark.rotation_degrees = Vector3(-90, 0, 0)
	mark.position = Vector3(0.0, 0.112, -0.09)
	root.add_child(mark)
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.85, 0.85, 0.9)
	glow.light_energy = 0.5
	glow.omni_range = 0.9
	glow.position = Vector3(0, 0.2, -0.1)
	glow.name = "MarkGlow"
	root.add_child(glow)
	return root


## Twenty years ago he wasn't an innkeeper: a heavy travelling coat of dark
## wool over him, collar up, to the knee, open at the front (the child goes
## inside it). Worn on his upper back so it moves with him. Drawn here until
## Gary's Bram-in-his-coat model (assets/models/characters/bram_coat.glb,
## used whole in place of bram.glb when it exists) comes.
func _dress_bram() -> void:
	if not (_bram is Figure3D):
		return
	var fig := _bram as Figure3D
	if fig.model == null or String(fig._model_name) == "bram_coat":
		return
	var sk := fig.model.find_child("Skeleton3D", true, false) as Skeleton3D
	if sk == null:
		return
	var bone := ""
	for b in ["Spine2", "Spine1", "Spine"]:
		if sk.find_bone(b) >= 0:
			bone = b
			break
	if bone == "":
		return
	var at := BoneAttachment3D.new()
	at.bone_name = bone
	sk.add_child(at)
	var origin := sk.get_bone_global_rest(sk.find_bone(bone)).origin
	var top := fig._shoulder + 0.13
	var bottom := maxf(0.4, fig._hips * 0.42)
	var mi := MeshInstance3D.new()
	mi.mesh = _coat_mesh(top - origin.y, bottom - origin.y, origin)
	var sm := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = COAT
	sm.shader = sh
	mi.material_override = sm
	mi.name = "Coat"
	at.add_child(mi)


## The coat: a ring open at the front, wider at the hem, flatter front to
## back, with a turned-up collar; in the model's own frame (it faces +z) less
## the bone's rest position.
func _coat_mesh(y_top: float, y_bot: float, origin: Vector3) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cols := 28
	var rows := 12
	var gap := deg_to_rad(30.0)            # the opening at the front, each side
	for r in rows + 1:
		var v := float(r) / rows
		var y := lerpf(y_top, y_bot, v)
		# over the shoulders and the tops of the arms (a mantle), then
		# falling straight to the knee and spreading a little at the hem
		var rad := lerpf(0.17, 0.31, smoothstep(0.0, 0.1, v)) + 0.15 * pow(v, 1.4)
		var wide := lerpf(1.38, 1.08, smoothstep(0.0, 0.35, v))
		for c in cols + 1:
			var u := float(c) / cols
			var a := lerpf(-PI + gap, PI - gap, u)   # 0 is his back
			var p := Vector3(sin(a) * rad * wide, y, -cos(a) * rad * 0.8)
			st.set_uv(Vector2(u, v))
			st.add_vertex(p - Vector3(origin.x, 0, origin.z))
	# the collar, turned up round the back of his neck
	var base := (rows + 1) * (cols + 1)
	for r in 2:
		var y := y_top + 0.085 * r
		for c in cols + 1:
			var u := float(c) / cols
			var a := lerpf(-PI * 0.6, PI * 0.6, u)
			var rad := 0.15 + 0.025 * r
			st.set_uv(Vector2(u, -0.1 * r))
			st.add_vertex(Vector3(sin(a) * rad, y, -cos(a) * rad * 0.85) - Vector3(origin.x, 0, origin.z))
	for r in rows:
		for c in cols:
			var a := r * (cols + 1) + c
			var b := a + 1
			var d := a + cols + 1
			var e := d + 1
			for k in [a, d, b, b, d, e]:
				st.add_index(k)
	for c in cols:
		var a := base + c
		var b := a + 1
		var d := a + cols + 1
		var e := d + 1
		for k in [a, b, d, b, e, d]:
			st.add_index(k)
	st.generate_normals()
	return st.commit()


const COAT := """
shader_type spatial;
render_mode cull_disabled;
float h2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h2(i), h2(i + vec2(1, 0)), f.x), mix(h2(i + vec2(0, 1)), h2(i + vec2(1, 1)), f.x), f.y);
}
void vertex() {
	// the hem swings in the wind; the shoulders don't
	float k = clamp(UV.y, 0.0, 1.0);
	float wv = sin(TIME * 2.1 + UV.x * 9.0) * 0.6 + sin(TIME * 3.3 + UV.x * 4.0) * 0.4;
	VERTEX.x += k * k * (0.05 + wv * 0.025);
	VERTEX.z -= k * k * abs(wv) * 0.03;
}
void fragment() {
	float n = n2(UV * vec2(60.0, 40.0)) * 0.5 + n2(UV * vec2(9.0, 5.0)) * 0.5;
	vec3 wool = mix(vec3(0.17, 0.14, 0.11), vec3(0.32, 0.27, 0.21), n);
	// snow caught on the shoulders
	float snow = smoothstep(0.08, 0.0, UV.y) * step(0.0, UV.y) * smoothstep(0.35, 0.7, n2(UV * vec2(40.0, 30.0)));
	ALBEDO = mix(wool, vec3(0.8, 0.84, 0.92), snow * 0.8);
	ROUGHNESS = 0.95;
	SPECULAR = 0.2;
}
"""


func _pick_up() -> void:
	if _bram is Figure3D:
		var fig := _bram as Figure3D
		fig.carry(_baby, fig.hold_point(0.38, 0.5))
		_baby.rotation = Vector3(0, PI * 0.5, 0)
		var l := Node3D.new()
		var r := Node3D.new()
		_baby.add_child(l)
		_baby.add_child(r)
		l.position = Vector3(0.0, -0.05, 0.16)
		r.position = Vector3(0.0, -0.06, -0.12)
		fig.reach(l, r, 0.35)
	else:
		_baby.reparent(_bram, false)
		_baby.position = Vector3(0, 1.1, 0.25)


## Into his coat, against his chest, held in his left arm alone (his right
## is for the cards).
func _tuck() -> void:
	if _bram is Figure3D:
		var fig := _bram as Figure3D
		var tw := create_tween()
		tw.tween_property(_baby, "position", fig.hold_point(0.2, 0.42) + Vector3(0.03, 0, 0), 0.9).set_trans(Tween.TRANS_SINE)
		await tw.finished
		var l := Node3D.new()
		_baby.add_child(l)
		l.position = Vector3(0.0, -0.08, 0.05)
		fig.reach(l, null, 0.4)
	var glow := _baby.get_node_or_null("MarkGlow") as OmniLight3D
	if glow != null:
		create_tween().tween_property(glow, "light_energy", 0.15, 1.5)


# ================================================================ effects ===

## Sigils falling out of the tear: a streak from the sky, a flash, sparks and
## a scorch in the snow, `n` of them over `secs`.
func _strike_burst(n: int, secs: float) -> void:
	for i in n:
		get_tree().create_timer(secs * i + _rng.randf() * 0.3, false).timeout.connect(_strike_random)


func _strike_random() -> void:
	if _done or not is_instance_valid(_set):
		return
	var base := _bram.position if is_instance_valid(_bram) and _bram.get_parent() == _set else WALK_FROM
	var ang := _rng.randf_range(-2.6, -0.5)
	var dist := _rng.randf_range(14.0, 60.0)
	var at := base + Vector3(cos(ang), 0, sin(ang)) * dist
	at.y = height(at.x, at.z)
	_strike(at, SIGIL_COLS[_rng.randi() % SIGIL_COLS.size()])


func _strike(at: Vector3, col: Color) -> void:
	var fall := Vector3(0.22, -1.0, 0.3).normalized()
	var start := at - fall * 80.0
	var mi := MeshInstance3D.new()
	mi.mesh = QuadMesh.new()
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/village/streak.gdshader")
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_instance_shader_parameter("col", col)
	mi.set_instance_shader_parameter("intensity", 7.0)
	_set.add_child(mi)
	var length := 14.0
	var secs := _rng.randf_range(0.45, 0.7)
	var tw := create_tween()
	tw.tween_method(func(u: float) -> void:
		var head := start.lerp(at, u)
		mi.transform = Transform3D(Basis(Vector3(0.9, 0, 0), -fall * length, Vector3(0, 0, 1)), head - fall * length * 0.5), 0.0, 1.0, secs)
	tw.tween_callback(func() -> void:
		mi.queue_free()
		_impact(at, col))


func _impact(at: Vector3, col: Color) -> void:
	var l := OmniLight3D.new()
	l.light_color = col.lerp(Color.WHITE, 0.4)
	l.light_energy = 7.0
	l.omni_range = 16.0
	l.position = at + Vector3(0, 1.4, 0)
	_set.add_child(l)
	var lt := create_tween()
	lt.tween_property(l, "light_energy", 0.0, 1.1)
	lt.tween_callback(l.queue_free)
	var sp := GPUParticles3D.new()
	sp.amount = [20, 40, 70][clampi(quality, 0, 2)]
	sp.lifetime = 1.1
	sp.one_shot = true
	sp.explosiveness = 0.95
	sp.position = at + Vector3(0, 0.2, 0)
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.spread = 70.0
	pm.initial_velocity_min = 3.0
	pm.initial_velocity_max = 8.0
	pm.gravity = Vector3(0, -9.0, 0)
	pm.scale_min = 0.08
	pm.scale_max = 0.2
	pm.color = col.lerp(Color.WHITE, 0.35)
	sp.process_material = pm
	var q := QuadMesh.new()
	var qm := StandardMaterial3D.new()
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	qm.albedo_texture = _soft_dot()
	qm.vertex_color_use_as_albedo = true
	q.material = qm
	q.size = Vector2(0.6, 0.6)
	sp.draw_pass_1 = q
	_set.add_child(sp)
	sp.emitting = true
	get_tree().create_timer(2.0, false).timeout.connect(sp.queue_free)
	var card := _card_mesh(col)
	card.position = at + Vector3(0, 0.05, 0)
	card.rotation = Vector3(-PI * 0.5 + _rng.randf_range(-0.2, 0.2), _rng.randf() * TAU, 0)
	_set.add_child(card)
	_play_strike()


func _play_strike() -> void:
	var p := "res://assets/sfx/sigil_strike.ogg"
	if not ResourceLoader.exists(p):
		return
	var a := AudioStreamPlayer.new()
	a.stream = load(p)
	a.volume_db = -14.0 + _rng.randf_range(-4.0, 0.0)
	a.pitch_scale = _rng.randf_range(0.85, 1.1)
	add_child(a)
	a.play()
	a.finished.connect(a.queue_free)


static var _dot: GradientTexture2D


## A soft round spark.
static func _soft_dot() -> Texture2D:
	if _dot == null:
		var g := Gradient.new()
		# black at the edge as well as clear: the sparks are added, not blended
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(0, 0, 0, 0))
		_dot = GradientTexture2D.new()
		_dot.gradient = g
		_dot.width = 64
		_dot.height = 64
		_dot.fill = GradientTexture2D.FILL_RADIAL
		_dot.fill_from = Vector2(0.5, 0.5)
		_dot.fill_to = Vector2(0.5, 0.0)
	return _dot


## A Sigil: a card of light, the size of a hand.
func _card_mesh(col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.2, 0.28, 0.005)
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	var back := DuelArt.card_back()
	m.albedo_texture = back
	m.albedo_color = Color(0.9, 0.9, 0.9)
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = 1.0
	if back != null:
		m.emission_texture = back
	m.roughness = 0.3
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Cards drifting down through the snow round him as Sigils (on: keep them
## coming through the walk).
func _rain_cards(on: bool) -> void:
	_raining = on


var _raining := false
var _rain_next := 0.0
var _strike_next := 0.0


## A gust: a sheet of snow blown through `at`, to hide or reveal the hunter.
func _gust(at: Vector3) -> void:
	var p := DuelField3D.snow_particles([150, 300, 500][clampi(quality, 0, 2)], Vector3(3, 2.5, 3), Vector3(-7.0, -0.6, 1.5))
	p.one_shot = true
	p.explosiveness = 0.6
	p.lifetime = 2.2
	p.preprocess = 0.0
	(p.draw_pass_1 as QuadMesh).size = Vector2(0.09, 0.09)
	p.position = at + Vector3(2.0, 2.0, 0)
	_set.add_child(p)
	p.emitting = true
	get_tree().create_timer(3.0, false).timeout.connect(p.queue_free)


# ================================================================ camera ===

func _shot(pos: Vector3, look: Vector3, fov: float) -> void:
	_cam_mode = "fixed"
	_cam_pos = pos
	_cam_look = look
	_cam.fov = fov
	_cam_ease = 0.0
	_apply_cam()


func _drift(a: Vector3, b: Vector3, la: Vector3, lb: Vector3, secs: float) -> void:
	_cam_mode = "drift"
	var tw := create_tween().set_parallel(true)
	tw.tween_method(func(u: float) -> void:
		if _cam_mode != "drift":
			return
		_cam_pos = a.lerp(b, u)
		_cam_look = la.lerp(lb, u)
		_apply_cam(), 0.0, 1.0, secs).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Over his right shoulder as he walks, a little behind and above.
func _follow(p: Vector3) -> void:
	_cam_mode = "follow"
	_cam_want = p + Vector3(0.75, 1.85, 2.9)
	_look_want = p + Vector3(0.1, 1.35, -7.0)
	_cam.fov = 50.0


var _cam_mode := "fixed"
var _cam_want := Vector3.ZERO
var _look_want := Vector3.ZERO


func _apply_cam() -> void:
	if _cam == null:
		return
	var sway := Vector3(sin(_t * 0.7) * 0.02, sin(_t * 0.9) * 0.015, 0)
	_cam.position = _cam_pos + sway
	if _cam_pos.distance_to(_cam_look) > 0.01:
		_cam.look_at(_cam_look, Vector3.UP)
	if is_instance_valid(_snow) and _snow.get_parent() == _set:
		_snow.position = _cam_pos + Vector3(-2.0, 4.0, -6.0)


func _process(delta: float) -> void:
	_t += delta
	if _cam_mode == "follow":
		var k := 1.0 - exp(-delta * 3.0)
		if _cam_pos == Vector3.ZERO:
			k = 1.0
		_cam_pos = _cam_pos.lerp(_cam_want, k)
		_cam_look = _cam_look.lerp(_look_want, k)
	if _cam_mode != "drift":
		_apply_cam()
	# the Sigils keep falling while the sky is open
	if _raining and _vpc.visible:
		if _t >= _strike_next:
			_strike_random()
			_strike_next = _t + _rng.randf_range(0.7, 1.8)
		if _t >= _rain_next:
			_drop_card()
			_rain_next = _t + _rng.randf_range(0.25, 0.6)
	for i in range(_falling.size() - 1, -1, -1):
		var f: Array = _falling[i]
		var n: Node3D = f[0]
		if not is_instance_valid(n):
			_falling.remove_at(i)
			continue
		n.position += (f[1] as Vector3) * delta
		n.rotate_object_local(Vector3(1, 0.4, 0.2).normalized(), float(f[2]) * delta)
		if n.position.y <= height(n.position.x, n.position.z) + 0.03:
			n.position.y = height(n.position.x, n.position.z) + 0.03
			_falling.remove_at(i)
	# the crater breathes its light
	if _crater_light != null:
		_crater_light.light_energy = 2.4 + sin(_t * 1.7) * 0.35 + sin(_t * 4.1) * 0.12
	if _ground_mat != null:
		_ground_mat.set_shader_parameter("glow", 0.6 + sin(_t * 1.7) * 0.1)


## One card of light drifting down near him, tumbling.
func _drop_card() -> void:
	if not is_instance_valid(_bram) or _bram.get_parent() != _set:
		return
	var c := _card_mesh(SIGIL_COLS[_rng.randi() % SIGIL_COLS.size()])
	var around := _bram.position + Vector3(_rng.randf_range(-7, 7), 0, _rng.randf_range(-12, 3))
	c.position = around + Vector3(0, _rng.randf_range(7, 11), 0)
	_set.add_child(c)
	_falling.append([c, Vector3(_rng.randf_range(-1.2, -0.4), -_rng.randf_range(1.1, 1.8), _rng.randf_range(-0.2, 0.4)), _rng.randf_range(1.5, 4.0)])
	# (they lie where they land, and go with the set)


# ================================================================== input ===

func _input(e: InputEvent) -> void:
	if _done:
		return
	if e is InputEventScreenTouch:
		_held = (e as InputEventScreenTouch).pressed
		if _held:
			_tapped = true
		_last_input = ""
	elif e is InputEventMouseButton and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_held = (e as InputEventMouseButton).pressed
		if _held:
			_tapped = true
		_last_input = ""
	elif e is InputEventJoypadButton or e is InputEventJoypadMotion:
		if (e is InputEventJoypadMotion and absf((e as InputEventJoypadMotion).axis_value) > 0.4) or e is InputEventJoypadButton:
			_last_input = "pad"
	elif e is InputEventKey and (e as InputEventKey).pressed:
		_last_input = "keys"
	if e.is_action_pressed("interact"):
		_tapped = true


func _device() -> String:
	if _last_input == "pad":
		return "controller"
	var d := PauseMenu.device_kind()
	if _last_input == "keys" and d != "computer":
		return "computer"
	return d


func _show_hint(how: Dictionary) -> void:
	_hint.text = String(how.get(_device(), how.phone))
	create_tween().tween_property(_hint, "modulate:a", 1.0, 0.5)


func _hide_hint() -> void:
	if _hint.modulate.a > 0.0:
		create_tween().tween_property(_hint, "modulate:a", 0.0, 0.4)


# ================================================================= helpers ===

func _say(line: Dictionary, always := false) -> void:
	if _skipping and not always:
		return
	var who := String(line.who)
	var host: Node = w if w != null else self
	var secs := VoiceLines.play(host, who, String(line.say), String(line.get("vo", "")))
	var nm: String = w._speaker(who) if w != null else who.capitalize()
	var text: String = w._fmt(String(line.say)) if w != null else String(line.say)
	await _ov.say(nm, text, secs, secs > 0.0)
	if secs > 0.0:
		VoiceLines.stop(host)


func _wait(secs: float) -> void:
	if _skipping:
		return
	await get_tree().create_timer(secs, false).timeout


func _fade(r: ColorRect, to: float, secs: float) -> void:
	create_tween().tween_property(r, "modulate:a", to, secs)


static func _face(f: Node3D, dir: Vector3) -> void:
	if f is PaperDoll:
		(f as PaperDoll).snap_face(dir)


static func _set_walking(f: Node3D, on: bool) -> void:
	if f is PaperDoll:
		(f as PaperDoll).walking = on


## Plays one of his clips if his model has it (borrowed if need be); false if not.
static func _act(f: Node3D, clip: String) -> bool:
	if f is Figure3D:
		var fig := f as Figure3D
		if fig.anim != null and fig._ensure(clip):
			fig.act(clip)
			return true
	return false


# ================================================================ shaders ===

const SNOW := """
shader_type spatial;
render_mode diffuse_lambert_wrap, specular_schlick_ggx;
uniform vec3 crater = vec3(0.0, 0.0, -30.0);
uniform float crater_r = 7.0;
uniform float glow = 0.6;
varying vec3 wp;
float h2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h2(i), h2(i + vec2(1, 0)), f.x), mix(h2(i + vec2(0, 1)), h2(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) { float a = 0.5; float s = 0.0; for (int i = 0; i < 4; i++) { s += a * n2(p); p *= 2.03; a *= 0.5; } return s; }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float n = fbm(wp.xz * 0.3);
	float fine = fbm(wp.xz * 3.1);
	vec3 snow = mix(vec3(0.5, 0.55, 0.68), vec3(0.82, 0.86, 0.94), n * 0.7 + fine * 0.3);
	float d = length(wp.xz - crater.xz);
	// the bowl: black glass, fused by the fall, snow only at its edges
	float inner = smoothstep(crater_r * 0.98, crater_r * 0.55, d + (fine - 0.5) * 1.6);
	vec3 glass = mix(vec3(0.03, 0.035, 0.05), vec3(0.14, 0.16, 0.22), fine);
	ALBEDO = mix(snow, glass, inner);
	ROUGHNESS = mix(0.82, 0.08, inner);
	SPECULAR = mix(0.35, 0.8, inner);
	// glints in the snow
	vec2 cell = floor(wp.xz * 34.0);
	float sp = step(0.988, h2(cell)) * (1.0 - inner);
	vec3 e = vec3(0.65, 0.75, 1.0) * sp * 0.5;
	// the light at the bottom of the bowl
	e += vec3(0.85, 0.9, 1.0) * glow * inner * exp(-d * 0.5) * 2.4;
	EMISSION = e;
}
"""


# ================================================================= hunter ===

## The faceless hunter: taller than a man, a ragged cloak the colour of old
## ash, a hood with nothing in it, long arms, cards of white light in one hand,
## and the storm trailing off it like smoke. Drawn here until Gary's model
## (assets/models/characters/shard_hunter.glb) takes its place.
class Hunter:
	extends Node3D

	const MODEL := "res://assets/models/characters/shard_hunter.glb"
	var _cloth: ShaderMaterial
	var _cards: Array = []
	var _yaw := 0.0
	var _t := 0.0
	var _hand: Node3D
	var _fade := 0.0

	func _ready() -> void:
		var body := Node3D.new()
		add_child(body)
		if ResourceLoader.exists(MODEL):
			var m := (load(MODEL) as PackedScene).instantiate() as Node3D
			body.add_child(m)
			var ap := m.find_child("AnimationPlayer", true, false) as AnimationPlayer
			if ap != null and ap.has_animation("idle"):
				ap.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
				ap.play("idle")
			_hand = Node3D.new()
			_hand.position = Vector3(0.45, 1.3, 0.35)
			add_child(_hand)
			_add_smoke()
			return
		_cloth = ShaderMaterial.new()
		var sh := Shader.new()
		sh.code = CLOTH
		_cloth.shader = sh
		# the cloak: wide at the hem, ragged, moving in the wind
		var cloak := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.24
		cm.bottom_radius = 0.78
		cm.height = 2.05
		cm.radial_segments = 22
		cm.rings = 10
		cloak.mesh = cm
		cloak.material_override = _cloth
		cloak.position.y = 1.02
		body.add_child(cloak)
		var shoulders := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.5
		sm.height = 0.62
		shoulders.mesh = sm
		shoulders.material_override = _cloth
		shoulders.position.y = 2.02
		shoulders.scale = Vector3(1.0, 0.42, 0.62)
		body.add_child(shoulders)
		# the hood: deep, peaked, its opening a hollow of darkness
		var hood := MeshInstance3D.new()
		var hm := CylinderMesh.new()
		hm.top_radius = 0.02
		hm.bottom_radius = 0.3
		hm.height = 0.72
		hm.radial_segments = 16
		hood.mesh = hm
		hood.material_override = _cloth
		hood.position = Vector3(0, 2.4, -0.05)
		hood.rotation_degrees = Vector3(-14, 0, 0)
		body.add_child(hood)
		var void_mi := MeshInstance3D.new()
		var vm := SphereMesh.new()
		vm.radius = 0.2
		vm.height = 0.4
		void_mi.mesh = vm
		var vmat := StandardMaterial3D.new()
		vmat.albedo_color = Color.BLACK
		vmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		void_mi.material_override = vmat
		void_mi.position = Vector3(0, 2.3, 0.1)
		void_mi.scale = Vector3(0.8, 1.05, 0.55)
		body.add_child(void_mi)
		for side in [-1.0, 1.0]:
			var arm := MeshInstance3D.new()
			var am := CapsuleMesh.new()
			am.radius = 0.075
			am.height = 1.25
			arm.mesh = am
			arm.material_override = _cloth
			arm.position = Vector3(0.5 * side, 1.5, 0.05)
			arm.rotation = Vector3(0.12, 0, 0.12 * side)
			body.add_child(arm)
		_hand = Node3D.new()
		_hand.position = Vector3(0.6, 0.95, 0.2)
		add_child(_hand)
		_add_smoke()
		_set_fade(_fade)

	func _add_smoke() -> void:
		var p := GPUParticles3D.new()
		p.amount = 60
		p.lifetime = 3.0
		p.preprocess = 3.0
		var pm := ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = Vector3(0.5, 1.1, 0.4)
		pm.direction = Vector3(-1, 0.15, 0.3)
		pm.spread = 20.0
		pm.initial_velocity_min = 0.6
		pm.initial_velocity_max = 1.6
		pm.gravity = Vector3.ZERO
		pm.scale_min = 0.6
		pm.scale_max = 1.6
		var cr := Curve.new()
		cr.add_point(Vector2(0, 0.0))
		cr.add_point(Vector2(0.25, 1.0))
		cr.add_point(Vector2(1, 0.0))
		var ct := CurveTexture.new()
		ct.curve = cr
		pm.alpha_curve = ct
		p.process_material = pm
		var q := QuadMesh.new()
		q.size = Vector2(0.7, 0.7)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_texture = DuelFX.dot_tex()
		m.albedo_color = Color(0.8, 0.84, 0.95, 0.22)
		m.vertex_color_use_as_albedo = true
		q.material = m
		p.draw_pass_1 = q
		p.position.y = 1.1
		p.name = "Smoke"
		add_child(p)

	func look_at_dir(dir: Vector3) -> void:
		dir.y = 0.0
		if dir.length() > 0.001:
			rotation.y = atan2(dir.x, dir.z)

	func fade_to(to: float, secs: float) -> void:
		var tw := create_tween()
		tw.tween_method(_set_fade, _fade, to, secs)
		await tw.finished

	func _set_fade(k: float) -> void:
		_fade = k
		if _cloth != null:
			_cloth.set_shader_parameter("fade", k)
		var sm := get_node_or_null("Smoke") as GPUParticles3D
		if sm != null:
			sm.emitting = k > 0.05

	## Cards of white light rise out of the snow and fan above its hand.
	func raise_cards() -> void:
		for i in 5:
			var c := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.3, 0.42, 0.008)
			c.mesh = bm
			var m := StandardMaterial3D.new()
			m.albedo_color = Color(0.95, 0.96, 1.0)
			m.emission_enabled = true
			m.emission = Color(0.9, 0.93, 1.0)
			m.emission_energy_multiplier = 1.3
			c.material_override = m
			add_child(c)
			var a := (float(i) - 2.0) * 0.32
			c.position = Vector3(sin(a) * 1.4, 0.05, 0.6 + cos(a) * 0.5)
			var tw := create_tween()
			tw.tween_interval(i * 0.12)
			tw.tween_property(c, "position", Vector3(sin(a) * 0.9, 2.6 + absf(a) * -0.3, 0.7), 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(c, "rotation", Vector3(0, a, -a * 0.6), 1.1)
			_cards.append(c)

	func lower_cards() -> void:
		for c in _cards:
			if is_instance_valid(c):
				(c as Node).queue_free()
		_cards.clear()

	func _process(delta: float) -> void:
		_t += delta
		if _cloth != null:
			_cloth.set_shader_parameter("t", _t)
		for i in _cards.size():
			var c: Node3D = _cards[i]
			if is_instance_valid(c):
				c.position.y += sin(_t * 1.8 + i) * 0.0015

	const CLOTH := """
shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;
uniform float t = 0.0;
uniform float fade = 1.0;
float h2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h2(i), h2(i + vec2(1, 0)), f.x), mix(h2(i + vec2(0, 1)), h2(i + vec2(1, 1)), f.x), f.y);
}
varying float hem;
void vertex() {
	// the lower it is, the more the wind takes it
	hem = clamp(1.0 - (VERTEX.y + 1.0) / 2.0, 0.0, 1.0);
	float wv = sin(t * 2.3 + VERTEX.y * 3.0 + VERTEX.x * 2.0) * 0.5 + sin(t * 3.7 + VERTEX.z * 4.0) * 0.3;
	VERTEX.x -= hem * hem * (0.18 + wv * 0.08);
	VERTEX.z += hem * hem * wv * 0.05;
}
void fragment() {
	float n = n2(UV * vec2(18.0, 7.0) + vec2(0.0, t * 0.05));
	// ragged at the hem
	if (hem > 0.78 && n2(vec2(UV.x * 42.0, 3.0)) * 0.22 + 0.8 < hem) { discard; }
	vec3 c = mix(vec3(0.035, 0.035, 0.04), vec3(0.11, 0.11, 0.12), n);
	ALBEDO = c;
	ROUGHNESS = 0.95;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = vec3(0.5, 0.58, 0.85) * rim * 0.35;
	ALPHA = fade;
}
"""
