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
##      the storm towards the light of a crater: free to walk about (the pad,
##      the keys, a tap on the snow) from the first moment, while Morrowen
##      speaks; once she stops the sky tears over him as he walks (nothing
##      stops him), and an arrow comes up in the bottom left corner pointing
##      the way to the light (4 November, Gary: "have him able to walk around
##      as Morrowen is talking - once she stops talking ... a compass in the
##      bottom left with an arrow pointing direction you need to go, this can
##      become the map later"; 5 November: "Compass should be more of an
##      arrow"). Something stands in the snow off to the side, and is gone.
##   4. In the crater, a crying baby with an ash-grey mark, seen from the rim
##      by the light it lies in. The player goes down to it and picks the
##      child up (gated): Bram kneels to it, lifts it and stands with it;
##      he tucks it into his coat ("Hush, now. I've got you."), and turns:
##      the faceless hunter on the crater's rim. "Not this one."
##   5. Bram's duel, played (12 November, Gary: "Bram's duel becomes played,
##      not watched ... three gated moves as Bram (call a Totem, attack, play
##      the Last Page), with no costs or numbers, and it can't be lost"): the
##      real duel engine (DuelScreen, spec.film) with no HUD, out in the snow,
##      cut into already joined and going badly, every move of it written out
##      (WhiteSkyDuel.PLAY_TURNS). The hunter's pack breaks one of his Totems;
##      then the player, as Bram, makes three moves, each waited for (_ask_move:
##      his hand as paintings, no names, costs or numbers, the card to play
##      glowing, the instruction in brackets): he calls the Unspent Hour; it
##      strikes a hound and breaks it; the pack answers and another of his
##      falls; he plays the Last Page, and when Orlanthe's book opens the
##      screen burns white. Nobody sees who won. Each move's payoff is filmed
##      by its beats as the watched duel was (8 November: _on_beat), and by
##      Gary's own shot of it once he's made one (StoryFilm "white_sky_move_1"
##      to "_3": _move_film). Bram's cards are his god's (Kaethis, the Hand
##      Before, never named here). The duel watched whole, 68 seconds of it,
##      is gone from here: Gary's film of it, "white_sky_duel", plays later,
##      on the Thornwood road, once the player knows the rules.
##   6. Black. Morrowen: "Twenty years later, the debt came due." Then the attic
##      (AshfordP1._attic): the player wakes, the mark under his collar fading.
##
## The first time, none of it can be skipped (8 November, Gary: "Make it so
## you can't skip Bram's bit at the beginning"). Once it has been seen
## (Game.settings seen_white_sky) a Skip button skips the lot (12 November:
## "Remove: the never-skip rule after the first play-through"). Taps move the
## lines on as everywhere else. The gate
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
const HOW_WALK := {"phone": "(Drag anywhere, or tap the snow, to walk.)", "tablet": "(Drag anywhere, or tap the snow, to walk.)",
	"computer": "(W A S D or the arrow keys to walk, or click the snow.)", "controller": "(Left stick to walk.)"}
## The compass's name for where the light is.
const COMPASS_LABEL := "The light"
const HOW_TAKE := {"phone": "(Tap the screen to pick up the child.)", "tablet": "(Tap the screen to pick up the child.)",
	"computer": "(Press E, or click, to pick up the child.)", "controller": "(Press A to pick up the child.)"}

## The player's three moves in Bram's duel (WhiteSkyDuel.PLAY_GATES).
const HOW_MOVE := {
	"call": {"phone": "(Tap the glowing card to call a Totem.)", "tablet": "(Tap the glowing card to call a Totem.)",
		"computer": "(Click the glowing card, or press E, to call a Totem.)", "controller": "(Press A to call a Totem.)"},
	"attack": {"phone": "(Tap the hound to strike it.)", "tablet": "(Tap the hound to strike it.)",
		"computer": "(Click the hound, or press E, to strike it.)", "controller": "(Press A to strike the hound.)"},
	"last_page": {"phone": "(Tap the glowing card: the Last Page.)", "tablet": "(Tap the glowing card: the Last Page.)",
		"computer": "(Click the glowing card, or press E: the Last Page.)", "controller": "(Press A to play the Last Page.)"},
}

# ------------------------------------------------------------------ duel ---
## The duel itself (the board and every move of it) is WhiteSkyDuel's, so its
## probe can run without the game's autoloads.
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
## The filmed duel's wide shots, for when nothing has happened for a while
## (8 November: SHOTS' two from out at the sides of the Circle had him
## three-quarters on, his face in the corner of a widened picture, so the
## director keeps to these, each checked by _face_seen): behind him high,
## behind and low on his left, low behind him up at the hunter, a crane
## high over his back, the pack's two flanks from between the rows (looking
## away from him), and behind him on his right.
const WIDES := [
	[Vector3(1.9, 3.4, 12.4), Vector3(0.0, 1.0, -1.6), 42.0],
	[Vector3(6.2, 2.0, 0.4), Vector3(-1.2, 1.0, -4.8), 40.0],
	[Vector3(-3.6, 1.5, 9.6), Vector3(0.4, 1.4, -3.0), 36.0],
	[Vector3(0.0, 8.0, 14.5), Vector3(0.0, 0.2, -2.5), 38.0],
	[Vector3(-6.4, 2.4, -0.2), Vector3(1.4, 1.0, -4.6), 40.0],
	[Vector3(0.6, 1.0, 10.2), Vector3(0.0, 2.4, -7.4), 32.0],
	[Vector3(4.8, 1.2, 8.6), Vector3(-0.8, 1.2, -2.0), 34.0],
]
## When his Summon is called: from behind Bram and to his right, higher
## than his head and back far enough for all of Orlanthe, 4.8 m of it, to
## stand in the picture once it has landed (the descent ends at this plus
## (0, 0.4, 0.6), looking at (0, 2.0, -0.8)): Bram's head and shoulders low
## on the left, clear of it, the hunter behind it (12 November, Gary: "we
## want to see it". It came down behind his Loomwarden from low behind him,
## at (1.2, 0.9, 10.6), in the watched duel; in the played one the Loomwarden
## has fallen by then, and a nearer camera between his Totems cut it off at
## the waist).
const CLIMAX := [Vector3(2.0, 2.4, 12.0), Vector3(0.0, 2.4, -0.8), 42.0]
## The longest the duel may run before the white comes anyway (s).
const FILM_MAX := 140.0

# ------------------------------------------------------------------- set ---
## The crater the child lies in (the set's own coordinates; Bram walks from
## WALK_FROM towards it, -z).
const CRATER := Vector3(0.0, 0.0, -30.0)
const CRATER_R := 7.0
const CRATER_DEPTH := 2.4
const WALK_FROM := Vector3(0.0, 0.0, -2.0)
const WALK_SPEED := 1.3
## How far from the crater's middle the walk ends (just outside its lip) and
## the hunter is glimpsed; how far he can wander from the crater at all.
const RIM_AT := 8.6
const GLIMPSE_AT := 19.0
const ROAM_R := 60.0
## How far short of the child he stops to kneel to it (m: it lies across in
## front of his knees, clear of the forward foot).
const CHILD_STOP := 0.42
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
var _skip_btn: Button
var _done := false
var _tap_at := Vector2.INF       # where the last tap or click was (Vector2.INF: a key or a button)
var _falling: Array = []      # [node, velocity, spin, colour]
var _rng := RandomNumberGenerator.new()
## Walking about (the pad, the keys, a tap on the snow): on through the walk.
var _roam := false
var _pad: WorldHUD.TouchPad
var _compass: WorldHUD.Compass
var _flat := Vector3.ZERO        # where he is on the plan (y 0)
var _move_target := Vector3.INF  # a tap on the snow to walk to
var _cam_yaw := PI               # the camera's heading behind him (eased)
var _spires: Array = []          # [x, z, radius]: the glass he walks round
var _landed: Array = []          # the Sigils standing in the snow (the oldest go)
var _line_over := false
var _sky_look := 0.0             # 0..1: the roaming camera's eyes lifted to the tear


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
	# the touch pad (drag: a joystick; a tap: walk there), under everything
	# else drawn over the picture
	_pad = WorldHUD.TouchPad.new()
	_pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pad.tapped.connect(_tap_snow)
	_root.add_child(_pad)
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
	_compass = WorldHUD.Compass.new()
	_compass.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_compass.cam = _cam
	_compass.label = COMPASS_LABEL
	_root.add_child(_compass)
	SafeArea.fit(_compass)
	# Skip, once the memory has been seen (12 November; play() shows it)
	_skip_btn = UITheme.button("Skip", false, 200)
	_skip_btn.anchor_left = 1.0
	_skip_btn.anchor_right = 1.0
	# (clear of a phone's Dynamic Island, as the opening movie's is)
	SafeArea.watch(_skip_btn, func() -> void:
		var mg := SafeArea.insets()
		_skip_btn.offset_left = -250 - mg.z
		_skip_btn.offset_right = -40 - mg.z
		_skip_btn.offset_top = 36 + mg.y
		_skip_btn.offset_bottom = 132 + mg.y)
	_skip_btn.visible = false
	_skip_btn.focus_mode = Control.FOCUS_NONE
	_skip_btn.pressed.connect(skip)
	_root.add_child(_skip_btn)
	_wind = _sound("storm_wind", WIND_DB, true)
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

## Keeps the place's bed of sound (Ambience) out of the memory while it
## plays, and lets it back after; however the memory ends, or is taken away.
var _hushed := false

func _hush(on: bool) -> void:
	if on == _hushed:
		return
	_hushed = on
	Ambience.hush = maxi(0, Ambience.hush + (1 if on else -1))


func _exit_tree() -> void:
	_hush(false)


## Plays the whole memory; returns once it has ended on black.
func play() -> void:
	_hush(true)   # (the storm is this memory's own sound: no bed from the world it's played over)
	_ov = Cine.overlay(w) if w != null else _own_overlay()
	if w != null:
		_ov.black(false)
	Music.play(["white_sky", "sigilfall"], 2.0)
	if _wind != null:
		_wind.play()
	_skip_btn.visible = seen()
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


## Skips the rest: the white, then the last line and the attic (the Skip
## button, there once the memory has been seen; and the tests).
func skip() -> void:
	_skipping = true
	if _skip_btn != null:
		_skip_btn.visible = false
	if _ov != null and _ov._waiting:
		_ov._next.emit()
	_tapped = true


# --- 1. the sky ---------------------------------------------------------
## The caption on black; then Bram from behind under the night sky, his to
## walk about from the first moment, while Morrowen speaks over him. Her
## line ends on its own (voiced) or on a tap; the walk goes on through it.
func _open() -> void:
	_flat = WALK_FROM
	_bram.position = Vector3(WALK_FROM.x, height(WALK_FROM.x, WALK_FROM.z), WALK_FROM.z)
	_face(_bram, Vector3.FORWARD)
	_cam_yaw = PI
	_cam_mode = "roam"
	_cam_pos = Vector3.ZERO   # (snaps to its place behind him on the first frame)
	_cam.fov = 50.0
	if warm_sigils:
		_warm_sigils()   # (under the caption's black, a few frames; not waited for)
	# the duel built now too, under the caption's black, and the black held
	# until it is (11 November, Gary: "Whole game running slow keeps freezing
	# especially when Bram goes to pick up baby": see _prepare_duel)
	var early := prep_early
	if early:
		_prepare_duel()
	await _ov.caption(CAPTION[0], CAPTION[1], 2.6)
	if _skipping:
		return
	var held := 0.0
	while early and not _prep_done and held < DUEL_WARM_MAX and not _skipping:
		await get_tree().process_frame
		held += get_process_delta_time()
	_fade(_black, 0.0, 2.2)
	_roam = true
	_show_hint(HOW_WALK)
	await _wait(0.8)
	_line_over = false
	_say_over(OPEN)
	while not _line_over and not _skipping:
		await get_tree().process_frame


## A line spoken over whatever's happening (the walk goes on under it);
## _line_over goes true when it's done.
func _say_over(line: Dictionary) -> void:
	await _say(line)
	_line_over = true


## What the tear first brings, drawn once under the caption's black and
## freed (8 November, Gary: "After Morrowen speaks at the beginning it
## glitches for a bit": the moment her line ended the Sigils began, and
## everything they're made of was made then, for the first time, in the
## seconds after it: a card of each new colour read its painting off the
## disk (eight paintings of 1536 pixels) and compiled its own copy of the
## card shader, each colour's pool its own copy of the pool's, the first
## ribbon the streak shader, the first sparks and the first strike's sparks
## their particle shaders. Each came as a hitch, spread over the first
## seconds of the tear). Now, while the caption is still on black, a pit
## stands small in front of the camera for a few frames with a card of every
## colour, each with its sparks and its pool, a ribbon, a streak and a
## strike's sparks (one colour a frame, so no frame does it all), the hunter
## is drawn once faded and once whole (its first showing is the glimpse on
## the way), and his look-up clip is made sure of (his own model has it; a
## stand-in would borrow it from another file here, not as the sky opens);
## then the pit goes. Nothing of it is seen: the screen is black, and the
## pit is a twentieth of its size. `warm_sigils` false leaves it out (the
## hitch test's before).
var warm_sigils := true
## Where the pit stands, from him (m): in front of his chest, in the
## camera's view but behind his back from where it stands over his right
## shoulder, so even with the caption tapped through early nothing of it
## shows.
const WARM_AT := Vector3(-0.3, 1.0, -1.2)

func _warm_sigils() -> void:
	if not is_inside_tree() or _set == null:
		return
	var pit := Node3D.new()
	pit.name = "Warm"
	pit.position = _bram.position + WARM_AT
	pit.scale = Vector3.ONE * 0.05
	_set.add_child(pit)
	# the ribbon, a streak and a strike's sparks (one of each: their shaders
	# are shared by every colour)
	var col0: Color = SIGIL_COLS[0]
	var trail := _trail_mesh(col0)
	trail.transform = Transform3D(Basis(Vector3(1.3, 0, 0), Vector3(0, -0.8, 0), Vector3(0, 0, 1)), Vector3(0.3, 0.4, 0))
	pit.add_child(trail)
	var streak := _streak_mesh(col0)
	streak.transform = Transform3D(Basis(Vector3(0.9, 0, 0), Vector3(0, 2.0, 0), Vector3(0, 0, 1)), Vector3(-0.3, 1.0, 0))
	pit.add_child(streak)
	var burst := _impact_sparks(col0)
	burst.one_shot = false
	pit.add_child(burst)
	burst.emitting = true
	# a strike's light on it all (the Compatibility renderer makes another
	# variant of a shader for things an omni light falls on, the first time)
	var glow := OmniLight3D.new()
	glow.light_color = col0.lerp(Color.WHITE, 0.4)
	glow.light_energy = 1.0
	glow.omni_range = 0.5   # (the pit only: not the snow a metre under it)
	glow.position = pit.position + Vector3(0, 0.1, 0)
	_set.add_child(glow)
	pit.tree_exiting.connect(glow.queue_free)
	# the hunter: drawn faded (the glimpse fades it in) and then whole, small
	# in the pit's place, and put back as it was (hidden, its size)
	var hunter_was := [_hunter.visible, _hunter.scale, _hunter.position, _hunter._fade]
	_hunter.position = pit.position + Vector3(0.1, -0.1, 0)
	_hunter.scale = Vector3.ONE * 0.05
	_hunter.visible = true
	_hunter._set_fade(0.5)
	# his look up at the tear (borrowed from another model's file if his
	# hasn't it: fetched now, not as the sky opens), and the strikes' sound
	if _bram is Figure3D:
		(_bram as Figure3D)._ensure("look_up")
	if ResourceLoader.exists(STRIKE_SFX):
		load(STRIKE_SFX)
	await get_tree().process_frame
	# a card of each colour with its sparks and its pool, one colour a frame
	for i in SIGIL_COLS.size():
		if not is_instance_valid(pit) or not pit.is_inside_tree() or _done:
			break
		var col: Color = SIGIL_COLS[i]
		var card := sigil_card(col)
		card.position = Vector3(-0.7 + 0.2 * i, 0.4, 0.0)
		card.rotation = Vector3(-0.3, 0.4 * i, 0.1)
		pit.add_child(card)
		if quality >= 1:
			var sparks := _card_sparks(col)
			card.add_child(sparks)
			sparks.emitting = true
		var pool := _pool_mesh(col)
		pool.position = Vector3(-0.7 + 0.2 * i, -0.2, 0.0)
		pool.rotation = Vector3(-PI * 0.5, 0, 0)
		pit.add_child(pool)
		if i == SIGIL_COLS.size() / 2 and is_instance_valid(_hunter):
			_hunter._set_fade(1.0)
		await get_tree().process_frame
	# two more drawn frames for the last of them, then it all goes
	for k in 2:
		await get_tree().process_frame
	if is_instance_valid(_hunter):
		_hunter._set_fade(float(hunter_was[3]))
		_hunter.visible = bool(hunter_was[0])
		_hunter.scale = hunter_was[1]
		_hunter.position = hunter_was[2]
	if is_instance_valid(pit):
		pit.queue_free()


# --- 2. the sky tears ---------------------------------------------------------
## The sky opens over him as he walks (5 November, Gary: "Why does Bram pause
## after Morrowen finishes talking?": he was stopped here for four seconds,
## stood still with the camera on the sky, and it read as the game hanging.
## Nothing takes the walk from him now): the camera behind him lifts its eyes
## to the tear (SKY_LOOK_UP, held SKY_LOOK_HOLD, down again over
## SKY_LOOK_DOWN, the picture still following him), the Sigils begin to
## fall, and if he happens to be standing he looks up himself; then the arrow
## comes up in the corner pointing to the light.
const SKY_LOOK_UP := 1.0
const SKY_LOOK_HOLD := 1.9
const SKY_LOOK_DOWN := 1.3
## How long after the tear begins the arrow comes up (s).
const COMPASS_AT := 2.6

func _sigilfall() -> void:
	# the camera's eyes up to the sky and back, the walk going on under it
	var look := create_tween()
	look.tween_property(self, "_sky_look", 1.0, SKY_LOOK_UP).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	look.tween_interval(SKY_LOOK_HOLD)
	look.tween_property(self, "_sky_look", 0.0, SKY_LOOK_DOWN).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _wait(0.5)
	if _skipping:
		return
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
	if _bram is Figure3D and not (_bram as Figure3D).walking:
		_act(_bram, "look_up")
	_rain_cards(true)
	await _wait(COMPASS_AT)
	if _skipping:
		return
	# the arrow: the way to the light
	_compass.target = CRATER
	_compass.show_compass(true)


# --- 3. the walk ------------------------------------------------------------------
## His to walk (the pad, the keys, a tap on the snow: _process moves him)
## until he reaches the crater's lip; the hunter is glimpsed on the way.
func _walk() -> void:
	var glimpsed := false
	while _crater_dist() > RIM_AT and not _skipping:
		if not glimpsed and _crater_dist() < GLIMPSE_AT:
			glimpsed = true
			_glimpse()
		await get_tree().process_frame
	_roam = false
	_set_walking(_bram, false)
	_move_target = Vector3.INF
	_hide_hint()
	_compass.show_compass(false, 0.8)


## How far he is from the crater's middle, on the plan.
func _crater_dist() -> float:
	return Vector2(_flat.x - CRATER.x, _flat.z - CRATER.z).length()


## The way he's facing, flat.
func _heading() -> Vector3:
	if _bram is PaperDoll:
		var f: Vector3 = (_bram as PaperDoll).facing()
		f.y = 0.0
		if f.length() > 0.01:
			return f.normalized()
	return Vector3.FORWARD


## A tap on the snow: walk there (the ray from the camera through the tap,
## marched down onto the snow).
func _tap_snow(pos: Vector2) -> void:
	if not _roam or _cam == null:
		return
	var vpp := Vector2(pos.x / maxf(1.0, _root.size.x) * float(_vp.size.x), pos.y / maxf(1.0, _root.size.y) * float(_vp.size.y))
	var from := _cam.project_ray_origin(vpp)
	var dir := _cam.project_ray_normal(vpp)
	var t := 0.5
	var last := from
	while t < 90.0:
		var p := from + dir * t
		if p.y <= height(p.x, p.z):
			# between last and p: halve in
			var a := last
			var b := p
			for k in 6:
				var m := (a + b) * 0.5
				if m.y <= height(m.x, m.z):
					b = m
				else:
					a = m
			_move_target = Vector3(b.x, 0.0, b.z)
			return
		last = p
		t += 0.5


## The hunter, off to the side in the snow ahead, for a few seconds: then a
## gust and it's gone. (8 November, Gary: "Think there needs to be more of a
## pause or action before hooded figure shows up": it faded in the moment he
## came within GLIMPSE_AT, with nothing to say anything was there.) Now the
## storm drops first: the wind falls away and the music dips under it, the
## Sigils stop coming down and the snow thins (GLIMPSE_HUSH); the camera's
## eyes are drawn off to the side of the way ahead (GLIMPSE_EYES of the way
## to it, the picture still following him) and his head turns with them; a
## gust lifts the snow there, and as it thins the figure is standing in it,
## watching him (GLIMPSE_FORM), held (GLIMPSE_HOLD); then the wind comes
## back with a gust, and it's gone. The walk stays his the whole time
## (5 November, Gary: nothing should take it from him).
const GLIMPSE_HUSH := 1.6
const GLIMPSE_EYES := 0.5
const GLIMPSE_FORM := 1.8
const GLIMPSE_HOLD := 3.0
## How loud the wind is at its height, and in a hush (dB).
const WIND_DB := -14.0
const WIND_HUSH_DB := -32.0
var _glimpse_at := Vector3.INF   # where the roaming camera's eyes are drawn
var _glimpse_look := 0.0         # 0..1: how far they're drawn there

func _glimpse() -> void:
	var f := _heading()
	var at := _bram.position + f * 9.0 - f.cross(Vector3.UP) * 7.5
	at.y = height(at.x, at.z)
	_glimpse_at = at + Vector3(0, 1.3, 0)
	# the hush: the wind falls away, the music dips, the Sigils stop and the
	# snow thins
	_wind_to(WIND_HUSH_DB, GLIMPSE_HUSH)
	Music.duck(GLIMPSE_HUSH + GLIMPSE_FORM + GLIMPSE_HOLD + 0.6, 9.0)
	_raining = false
	_storm_to(0.35, 0.45, GLIMPSE_HUSH)
	await _wait(GLIMPSE_HUSH * 0.55)
	# the eyes drawn off to it, his head turning with them
	create_tween().tween_property(self, "_glimpse_look", 1.0, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if _bram is Figure3D:
		(_bram as Figure3D).eyes_on(_glimpse_at + Vector3(0, 0.6, 0))
	await _wait(GLIMPSE_HUSH * 0.45)
	# a gust lifts the snow there, and it's standing in it
	_gust(at)
	_hunter.position = at
	_hunter.look_at_dir(_bram.position - _hunter.position)
	_hunter.visible = true
	_hunter.fade_to(1.0, GLIMPSE_FORM)
	await _wait(GLIMPSE_FORM + GLIMPSE_HOLD)
	# the storm back with a gust over it, and it's gone
	if is_instance_valid(_hunter):
		_wind_to(WIND_DB, 0.7)
		_storm_to(1.0, 1.0, 0.7)
		_gust(_hunter.position)
		if _bram is Figure3D:
			(_bram as Figure3D).eyes_on(null)
		create_tween().tween_property(self, "_glimpse_look", 0.0, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await _hunter.fade_to(0.0, 0.9)
		_hunter.visible = false
	_raining = true


## The wind's loudness to `db` over `secs`.
func _wind_to(db: float, secs: float) -> void:
	if _wind != null:
		create_tween().tween_property(_wind, "volume_db", db, secs).set_trans(Tween.TRANS_SINE)


## The storm's snow to `blown` of its driven sheets and `fall` of its flakes
## (0..1 of how many there are, and how fast they go: at the hunter's coming
## the snow all but hangs in the air), over `secs`.
func _storm_to(blown: float, fall: float, secs: float) -> void:
	var tw := create_tween().set_parallel(true)
	for pair in [[_blown, blown], [_snow, fall], [_near_snow, fall]]:
		var p := pair[0] as GPUParticles3D
		if p == null or not is_instance_valid(p):
			continue
		var k := float(pair[1])
		tw.tween_property(p, "amount_ratio", clampf(0.25 + 0.75 * k, 0.0, 1.0), secs)
		tw.tween_property(p, "speed_scale", clampf(k, 0.08, 1.0), secs)


# --- 4. the crater --------------------------------------------------------------
## On the lip: the bowl below him and the child in its light at the bottom,
## seen and held (4 November, Gary: "you should be able to see there is
## something there, not just there one second"); then down to it, the
## camera coming down with him and the child kept in the picture; the
## pick-up (gated), the child in his arms.
var _ad := Vector3.FORWARD    # the way he came down into the crater, flat
var _bottom := Vector3.ZERO   # where he stands by the child

func _crater() -> void:
	_ad = CRATER - _bram.position
	_ad.y = 0.0
	_ad = _ad.normalized()
	var rt := _ad.cross(Vector3.UP)
	_face(_bram, _ad)
	var b := _bram.position
	# where he kneels: square on to the bundle's side, so it lies across in
	# front of his knees and a hand goes under each end of it (6 November;
	# he used to come at it end on, and one hand couldn't reach the far end),
	# on the side of it he came down from
	var kd := _kneel_dir(_ad)
	_bottom = _kneel_spot(kd)
	_bottom.y = height(_bottom.x, _bottom.z)
	# over his shoulder from the rim, high, down into the bowl: him on the
	# lip, the light and the child at the bottom
	var reveal := b - _ad * 2.6 + rt * 1.3 + Vector3(0, 3.4, 0)
	_shot(reveal, _baby.position + Vector3(0, 0.3, 0), 44.0)
	_child_beacon(true)
	if _cry != null:
		_cry.play()
	await _wait(REVEAL_SECS)
	if _skipping:
		return
	# down the slope to it, the camera coming down behind him and keeping
	# the child in the middle of the picture
	var krt := kd.cross(Vector3.UP)
	var close := _bottom - kd * 2.4 + krt * 1.1 + Vector3(0, 2.3, 0)
	var secs := DOWN_SECS
	var way := _bottom - b
	way.y = 0.0
	if _bram is PaperDoll and way.length() > 0.05:
		(_bram as PaperDoll).face(way.normalized(), _cam)
	_drift(reveal, close, _baby.position + Vector3(0, 0.3, 0), _baby.position + Vector3(0, 0.1, 0), secs)
	_set_walking(_bram, true)
	if _bram is Figure3D:
		(_bram as Figure3D).pace = b.distance_to(_bottom) / secs
	var from := b
	# (by the frames' own clock, as the camera's drift is, so the two keep
	# step however slowly the frames come)
	var el := 0.0
	while el < secs:
		if _skipping:
			return
		await get_tree().process_frame
		el = minf(secs, el + get_process_delta_time())
		var p := from.lerp(_bottom, el / secs)
		p.y = height(p.x, p.z)
		_bram.position = p
	_set_walking(_bram, false)
	if _bram is Figure3D:
		(_bram as Figure3D).pace = 0.0
	# square on to it (turned as a man turns, not snapped)
	_ad = kd
	rt = _ad.cross(Vector3.UP)
	if _bram is PaperDoll:
		(_bram as PaperDoll).face(_ad, _cam)
	_cam_yaw = atan2(_ad.x, _ad.z)
	await _wait(PROMPT_BEAT)
	_show_hint(HOW_TAKE)
	# (the duel is built already, under the opening's black: _open. Until 11
	# November it was built here, behind the picture, while the prompt waited,
	# and a tap straight away had him kneel and lift the child through it.)
	if not prep_early:
		_prepare_duel()
	_tapped = false
	while not _tapped and not _skipping:
		if Input.is_action_just_pressed("interact"):
			break
		await get_tree().process_frame
	_hide_hint()
	if _skipping:
		return
	# he kneels to it and lifts it, and stands with it; the crying stops in
	# his arms (closer, low over his right shoulder, the child in the middle)
	# (6 November: further round to his right and lower, so the child, lying
	# in front of his right knee, is seen clear of his back as his hands go
	# under it and it comes up in them)
	_shot(_bottom - _ad * 1.9 + rt * 1.45 + Vector3(0, 1.15, 0), _baby.position + Vector3(0, 0.2, 0), 40.0)
	_child_beacon(false)
	await _lift_child()
	if _skipping:
		return
	# high over his shoulder, steeply down at the child in his arms (his face
	# stays out of it: the camera is behind and above him)
	var held: Array = _held_shot()
	_shot(held[0], held[1], 36.0)
	await _say(HUSH)
	# into his coat, held in his left arm from here on
	_tuck()
	await _wait(0.8)


## High over his left shoulder, steeply down at the child held in his left
## arm against his chest: [camera, looking at]. (6 November: it was over his
## right shoulder and a metre back, and his head hid the child.) His face
## stays out of it: the camera is behind and above him.
func _held_shot() -> Array:
	var rt := _ad.cross(Vector3.UP)
	return [_bottom - _ad * 0.45 - rt * 0.5 + Vector3(0, 2.6, 0), _bottom + _ad * 0.3 - rt * 0.05 + Vector3(0, 1.0, 0)]


## The way he faces kneeling to the child: square on to the bundle's side,
## on the side of it nearer `approach` (the way he came).
func _kneel_dir(approach: Vector3) -> Vector3:
	var along := Basis(Vector3.UP, _baby.rotation.y) * Vector3.BACK
	var kd := along.cross(Vector3.UP).normalized()
	return -kd if kd.dot(approach) < 0.0 else kd


## Where he kneels facing `kd`: CHILD_STOP short of the child and a hand's
## width to its left, so it lies in front of his right knee (the one that
## goes down), clear of the forward foot, and under his shoulders.
const CHILD_SIDE := 0.12

func _kneel_spot(kd: Vector3) -> Vector3:
	var p := CRATER - kd * CHILD_STOP - kd.cross(Vector3.UP) * CHILD_SIDE
	p.y = height(p.x, p.z)
	return p


# --- the hunter on the rim ----------------------------------------------------
## (8 November, Gary: "Think there needs to be more of a pause or action
## before hooded figure shows up": a heartbeat after the child was tucked into
## his coat it was simply there on the rim.) Now the night goes still first.
## The child is quiet in his coat; the wind falls away, the Sigils stop
## coming down and the snow all but hangs in the air (_storm_to), the
## crater's light sinks (_crater_k) and the music dips; cut wide and low
## behind him, small at the bottom of the bowl with the empty rim above him,
## the camera creeping in (RIM_HUSH). Then a sound up there in the dark: a
## hound's whine, far off and low (RIM_SOUND). His head comes up from the
## child to the rim. Snow lifts off the lip in a gust and the shape of
## something stands in it, half there (RIM_FORM_HALF), then whole
## (RIM_FORM), and walks to the edge on its long legs (RIM_STEP) and stops,
## looking down at him. "Not this one." The cards rise. His face is never
## seen: every shot here is from behind him.
const RIM_HUSH := 3.4
const RIM_SOUND := 1.3
const RIM_FORM_HALF := 1.6
const RIM_FORM := 1.3
const RIM_STEP := 1.2
## How far back from the lip it takes form, and how far it walks to it (m).
const RIM_BACK := 1.6
## The lens on it as it forms and walks to the edge (degrees), and the cold
## light that finds it.
const RIM_LENS := 26.0
const RIM_LIGHT := 1.1
var _hunter_light: OmniLight3D
var _crater_k := 1.0   # the crater's light, 0..1 of its own

func _the_hunter() -> void:
	var rim := CRATER + _ad * RIM_AT
	var rt := _ad.cross(Vector3.UP)
	var b := _bram.position
	# the stillness: the child quiet in the high shot a moment longer, as the
	# storm falls away round them
	_wind_to(WIND_HUSH_DB - 4.0, RIM_HUSH)
	_raining = false
	_storm_to(0.15, 0.12, RIM_HUSH)
	create_tween().tween_property(self, "_crater_k", 0.32, RIM_HUSH).set_trans(Tween.TRANS_SINE)
	Music.duck(RIM_HUSH + RIM_SOUND + RIM_FORM_HALF + RIM_FORM + RIM_STEP + 1.5, 12.0)
	# his eyes on the child in his coat (so his head coming up reads)
	if _bram is Figure3D and is_instance_valid(_baby):
		(_bram as Figure3D).eyes_on(_baby.global_position)
	await _wait(1.2)
	if _skipping:
		return
	# wide and low behind him: small in the bottom of the bowl, the empty
	# rim up the slope ahead, the snow hanging; creeping in
	var w0 := b - _ad * 6.2 + rt * 2.2 + Vector3(0, 0.9, 0)
	var w1 := b - _ad * 4.9 + rt * 1.7 + Vector3(0, 1.05, 0)
	var rim_look := Vector3(rim.x, height(rim.x, rim.z) + 1.1, rim.z)
	_shot(w0, rim_look.lerp(b + Vector3(0, 1.2, 0), 0.35), 34.0)
	_drift(w0, w1, rim_look.lerp(b + Vector3(0, 1.2, 0), 0.35), rim_look.lerp(b + Vector3(0, 1.2, 0), 0.25), RIM_HUSH + RIM_SOUND + 1.0)
	await _wait(RIM_HUSH - 1.2)
	if _skipping:
		return
	# a sound up there in the dark; his head comes up to the rim
	_far_whine()
	await _wait(0.5)
	if _bram is Figure3D:
		(_bram as Figure3D).eyes_on(rim_look + Vector3(0, 0.9, 0))
	await _wait(RIM_SOUND - 0.5)
	if _skipping:
		return
	# the snow lifts off the lip, and the shape of it stands in the gust,
	# a little back from the edge
	var form := rim + _ad * RIM_BACK
	form.y = height(form.x, form.z)
	_gust(form)
	_hunter.position = form
	_hunter.look_at_dir(_bram.position - _hunter.position)
	_hunter.visible = true
	_hunter.fade_to(0.4, RIM_FORM_HALF)
	# a cold light finds it as it forms (dark on the dark sky, it was all
	# but lost at that distance)
	_hunter_light = OmniLight3D.new()
	_hunter_light.light_color = Color(0.72, 0.8, 1.0)
	_hunter_light.light_energy = 0.0
	_hunter_light.omni_range = 4.5
	_hunter_light.position = Vector3(0.0, 2.0, 1.6)
	_hunter.add_child(_hunter_light)
	create_tween().tween_property(_hunter_light, "light_energy", RIM_LIGHT, RIM_FORM_HALF + RIM_FORM)
	# low behind his right shoulder, up at the rim on a long lens (he's a
	# shoulder in the corner of it)
	# (more nearly behind him than the old 0.9 m aside: on the long lens, with
	# his head up, the edge of his cheek showed past his hair)
	var c0 := b - _ad * 2.6 + rt * 0.6 + Vector3(0, 1.0, 0)
	var c1 := b - _ad * 2.0 + rt * 0.45 + Vector3(0, 1.2, 0)
	_shot(c0, form + Vector3(0, 1.8, 0), RIM_LENS)
	await _wait(RIM_FORM_HALF)
	if _skipping:
		return
	await _hunter.fade_to(1.0, RIM_FORM)
	# it walks to the edge, slowly, and stops, looking down at him
	rim.y = height(rim.x, rim.z)
	_hunter.walk_to(rim, RIM_STEP)
	_drift(c0, c1, form + Vector3(0, 1.8, 0), rim + Vector3(0, 1.9, 0), RIM_STEP + 4.0)
	await _wait(RIM_STEP + 0.6)
	_hunter.look_at_dir(_bram.position - _hunter.position)
	await _say(NOT_THIS)
	if _skipping:
		return
	if _bram is Figure3D:
		(_bram as Figure3D).eyes_on(null)
	# it lifts a hand: cards rise from the snow about it, white
	_hunter.raise_cards()
	await _wait(1.6)
	var fl := create_tween()
	fl.tween_property(_white, "modulate:a", 1.0, 0.5)
	await fl.finished


## A hound's whine far off in the dark: the hunter's pack, before anything
## is seen (quiet, low and slow, as heard from down in the bowl).
func _far_whine() -> void:
	var path := "res://assets/sfx/hound_whine.wav"
	if not ResourceLoader.exists(path):
		return
	# (a plain player: the memory's picture is drawn in its own viewport,
	# which has no listener of its own for a sound placed in it)
	var a := AudioStreamPlayer.new()
	a.stream = load(path)
	a.volume_db = -17.0
	a.pitch_scale = 0.72
	add_child(a)
	a.play()
	a.finished.connect(a.queue_free)


# --- 5. the duel, filmed ----------------------------------------------------------
## The duel's screen, built behind the memory while Bram is down in the
## crater (6 November, Gary: "When Bram's battle happens in the beginning it
## stays on a white screen for ages": the whole duel, its 3D field out in
## the snow, every model either deck could call and every effect's shader,
## was built and drawn for the first time in the white, so the white held
## while all that loaded, and on the Mac the first frames of a new field
## crawled while their shaders were made). Now it's built (spec.hold: the
## duel waits for go()) as the pick-up prompt comes up, under the memory's
## own picture (drawn, so its models and shaders are warmed, then not
## drawn again till the cut: DUEL_WARM_SECS), and the white is a short,
## deliberate flash of the book's light (WHITE_HOLD) before it opens on the
## duel.
## (11 November, Gary: "Whole game running slow keeps freezing especially
## when Bram goes to pick up baby": building it as the pick-up prompt came up
## meant a tap on the prompt had him kneel, lift the child and stand while
## the duel's models were still being read, put on the field and drawn for
## the first time behind the picture, two 3D pictures drawn at once, for up
## to DUEL_WARM_MAX seconds: the worst catch in the game, on the one moment
## that's a close-up. Now it's built at the very start, under the caption's
## black (_open; `prep_early`), which holds until it's done; from then on
## its picture isn't drawn at all until the cut, so the walk, the crater and
## the lift have the machine to themselves.)
const DUEL_WARM_SECS := 1.5
const DUEL_WARM_MAX := 10.0
const WHITE_HOLD := 0.25
## False builds it as the pick-up prompt comes up, as before (the tests'
## before).
var prep_early := true
var _prep_done := false


func _prepare_duel() -> void:
	if _prep != null or _screen != null or _skipping:
		return
	var spec := duel_spec()
	spec["hold"] = true
	_players = spec.get("controllers", [])
	var sc: DuelScreen = DuelScreen.new().configure(spec)
	_prep = sc
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(sc)
	_root.move_child(sc, 0)   # under the memory's own picture
	if sc.field != null:
		_ice_round_duel(sc.field)
	# drawn until every model and effect has been warmed (DuelField3D's
	# "Warm" and "WarmFX" pits gone), DUEL_WARM_SECS at the least and
	# DUEL_WARM_MAX at the most; then not drawn again until the cut
	var el := 0.0
	while el < DUEL_WARM_MAX and is_instance_valid(sc) and not _screen_live:
		await get_tree().process_frame
		el += get_process_delta_time()
		if el >= DUEL_WARM_SECS and sc.field != null and sc.field.world != null \
				and sc.field.world.get_node_or_null("Warm") == null and sc.field.world.get_node_or_null("WarmFX") == null:
			break
	if is_instance_valid(sc) and sc.field != null and sc.field.vp != null and not _screen_live:
		sc.field.vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_prep_done = true


## A duel screen let go: its duel ended first and cut off from the screen
## (6 November: freed with its duel still going, the duel's next step found
## no screen to wait on, so every step after it came at once, for ever, in
## one frame, and the game hung on the white as the memory ended).
static func _end_screen(sc: DuelScreen) -> void:
	if not is_instance_valid(sc):
		return
	if sc.game != null:
		sc.game.presenter = null
		sc.game._finish(2, "")
	sc.queue_free()


## The duel built and waiting (_prepare_duel), until _duel makes it _screen;
## and its two sides' players (WhiteSkyDuel.Staged: Bram's waits for the
## player at each of his three moves).
var _prep: DuelScreen
var _screen_live := false
var _players: Array = []


## The Shardlands' ice round the duel too (6 November: the filmed duel stood
## on open snow): crystal clusters in a ring well outside the Circle and its
## cameras, big ones far off in the haze, a few smaller near.
func _ice_round_duel(f: DuelField3D) -> void:
	var ice := ice_material(quality, false)
	var r := RandomNumberGenerator.new()
	r.seed = 31
	var n: int = [14, 20, 28][clampi(quality, 0, 2)]
	for i in n:
		var big: bool = i % 3 == 0
		var ang := r.randf() * TAU
		var dist := r.randf_range(26.0, 50.0) if big else r.randf_range(13.0, 30.0)
		var p := Vector3(cos(ang) * dist, 0.0, sin(ang) * dist)
		var hgt := r.randf_range(8.0, 18.0) if big else r.randf_range(1.5, 5.0)
		var rad := hgt * r.randf_range(0.07, 0.1)
		var mi := MeshInstance3D.new()
		mi.mesh = _crystal_mesh(r, hgt, rad, r.randi_range(1, 4))
		mi.material_override = ice
		mi.set_instance_shader_parameter("seed", r.randf() * 10.0)
		mi.set_instance_shader_parameter("glow", r.randf_range(0.7, 1.1))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = p - Vector3(0, 0.05, 0)
		mi.rotation = Vector3(r.randf_range(-0.2, 0.2), r.randf() * TAU, r.randf_range(-0.2, 0.2))
		f.world.add_child(mi)

## Bram's duel, played (12 November; the note at the top, 5). The duel was
## built under the opening's black (_prepare_duel) and waits; here it's cut
## to and begun. Its two sides are WhiteSkyDuel.Staged players: the hunter's
## plays its turns as written; Bram's waits at each of the player's three
## moves (_ask_move) and makes it when they do. Between the moves it's a
## film, as the watched duel was (8 November, Gary: "Can we make the battle
## more movie like"): every beat the duel's presenter is told of
## (DuelGame.beat) chooses its shot (_on_beat). A Totem called rises in a
## low hero shot; an attack is seen from behind the attacker, and a big blow
## cuts to where it lands, the camera shaken by it; a Totem broken is held
## close; a blow on Bram is seen over his shoulder as he takes it; the black
## bars of a widescreen film over it all (_film_bars), off while the player
## chooses. Every shot is checked against Bram's face (_face_seen): a shot
## that would show it is passed over for the next of its kind, so it's never
## seen. Called down, the Last Page has the picture to itself: over his
## shoulder, low, rising to CLIMAX as it comes down. (The duel's own
## cinematic shots stay off in a film, DuelScreen._filmed: the camera here
## is the film's alone, through DuelField3D.cam_shot, set_home and cam_home.)
const FILM := "white_sky_duel"
## Where the choosing is done from: high over his back, looking down the
## Circle, his row and the pack's one above the other and the hunter beyond
## ([camera, looking at, lens]). From SHOTS[0], lower, his Loomwarden hid the
## Warg behind it and the ring on the hound lay across the Unspent Hour's
## wing.
const PLAY_SHOT := [Vector3(1.2, 8.4, 14.2), Vector3(0.0, 0.4, 0.4), 40.0]
## The move of his being waited for ("": none), and how long the duel has
## stood waiting for the player in all (not counted against FILM_MAX).
var _asking := ""
var _asked_secs := 0.0
var _move_go := false
var _hand: Control = null
var _ring: MoveRing = null
var _ring_of: DuelTotem = null
var _clip_on := false

func _duel() -> void:
	if _prep == null:
		_prepare_duel()
	_screen = _prep
	_prep = null
	_screen_live = true
	if is_instance_valid(_hunter_light):
		_hunter_light.queue_free()
	_root.move_child(_screen, _vpc.get_index() + 1)
	if _screen.field != null and _screen.field.vp != null:
		_screen.field.vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
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
		_hunter.scale = Vector3.ONE * HUNTER_SCALE
		_hunter.look_at_dir(Vector3.BACK)
		_hunter.lower_cards()
		_hunter.visible = true
		_hunter._set_fade(1.0)
	_dir_f = f
	_film_bars(true)
	var st := {"called": -1.0, "struck": -1.0, "over": false}
	_screen.game.logged.connect(func(t: String, who: int) -> void:
		if who == 0 and is_instance_valid(_bram) and (t.contains(" plays ") or t.contains(" calls ") or t.contains(" sets ") or t.contains(" casts ")):
			_act(_bram, "play_card")
		if who == 0 and t.contains("calls down") and t.contains(WhiteSkyDuel.summon_name()) and st.called < 0.0:
			st.called = _t
		# the Last Page's blow landing on the hunter's side
		if st.called >= 0.0 and st.struck < 0.0 and who == 1 and t.contains(" takes "):
			st.struck = _t
			if _dir_f != null and is_instance_valid(_dir_f):
				_dir_f.cam_shake(14.0))
	# (deferred: after the screen's own camera calls for the same beat, its
	# home and its lean, so the film's shot is the one that stands)
	_screen.game.beat.connect(_on_beat, CONNECT_DEFERRED)
	_screen.finished.connect(func(_r) -> void: st.over = true)
	# Bram's side waits for the player at each of his three moves
	if not _players.is_empty() and _players[0] != null and "ask" in _players[0]:
		_players[0].ask = _ask_move
	_screen.go()
	_wind_to(WIND_DB, 1.2)   # (the storm's back round the Circle after the hush on the rim)
	var fade := create_tween()
	fade.tween_interval(WHITE_HOLD)
	fade.tween_property(_white, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var start := _t
	_asked_secs = 0.0
	_cut_at = _t
	_free_at = _t + 1.6
	_wide_i = 0
	while not _skipping and not st.over and _t - start - _asked_secs < FILM_MAX:
		if f != null:
			_hide_plates(f)
		if f != null and st.called >= 0.0 and not _climax:
			_climax = true
			_climax_shot()
		if f != null and not _climax and _asking == "" and _t - _cut_at > IDLE_WIDE:
			_wide_shot()
		if st.called >= 0.0 and ((st.struck >= 0.0 and _t - st.struck > CLIMAX_HOLD) or _t - st.called > 10.0):
			break
		await get_tree().process_frame
	# (Gary's shot of the last move, to its end: it ends on the white too)
	while _clip_on and not _skipping:
		await get_tree().process_frame
	_asking = ""
	_drop_hand(0.2)
	_drop_ring()
	_hide_hint()
	# the white: the book opening on the Last Page's blow; the music (Gary's
	# white_sky_duel, its climax looping under the duel) stops dead with it
	var wt := create_tween()
	wt.tween_property(_white, "modulate:a", 1.0, 1.5 if not _skipping else 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await wt.finished
	_dir_f = null
	_film_bars(false, 0.0)
	Music.stop(0.12)


# --- the player's three moves (12 November) -----------------------------------
## One of the player's three moves, waited for: called by Bram's side of the
## duel (WhiteSkyDuel.Staged.ask) with the move's name and the action it's
## about to make, and awaited; the action is made when this returns. The
## last blow's shot has its moment first (and Gary's shot of the last move
## its end). Then the picture goes back behind Bram (PLAY_SHOT), the film's
## bars come off, and what's to be done is shown: for a card (the Totem to
## call, the Last Page) his hand comes up along the bottom of the picture as
## paintings alone, no names, costs or numbers, the card to play lifted and
## glowing and the rest dimmed; for the attack a ring of light closes on the
## hound to strike. The instruction is in brackets, by device (HOW_MOVE).
## Nothing else moves the duel on: a tap on the glowing card or the ringed
## hound (or near it: MOVE_NEAR), E or Enter, or A on a controller. Then the
## card flies from his hand, the bars come back and the move plays out,
## filmed (_on_beat), and Gary's shot of it over that when there is one
## (_move_film).
const MOVE_NEAR := 34.0
const MOVE_SETTLE := 0.75
const MOVE_SHOWN := 0.45

## The move waited for now ("": none), and making it without a tap (a key,
## a controller's button; the tests).
func asking() -> String:
	return _asking


func play_move() -> void:
	if _asking != "":
		_move_go = true


func _ask_move(gate: String, action: Dictionary) -> void:
	if _skipping or _dir_f == null or not is_instance_valid(_dir_f) or not is_instance_valid(_screen):
		return
	while (_t < _free_at or _clip_on) and not _skipping:
		await get_tree().process_frame
	if _skipping or _dir_f == null or not is_instance_valid(_dir_f):
		return
	_asking = gate
	_take(PLAY_SHOT, 0.9, 3600.0)
	_film_bars(false, 0.5)
	# (the picture back behind him first: his hand came up over the last
	# blow's close shot while the camera was still on its way)
	await _wait(MOVE_SETTLE)
	if _skipping or _dir_f == null or not is_instance_valid(_dir_f) or not is_instance_valid(_screen):
		_asking = ""
		return
	var card: Control = null
	if gate == "attack":
		_show_ring(action.get("target"))
		_snd("ward_set", 1.25, -5.0)   # (the mark closing on the hound)
	elif action.get("card") is DuelCard:
		card = _show_hand(String((action.card as DuelCard).id))
		_snd("card_draw")   # (his hand coming up)
	await _wait(MOVE_SHOWN)
	# (just over his hand when it's up; where the walk's and the pick-up's
	# were otherwise)
	if card != null:
		_hint.offset_bottom = -(card.size.y * 0.96 + 14.0)
		_hint.offset_top = _hint.offset_bottom - 60.0
	_show_hint(HOW_MOVE.get(gate, HOW_MOVE["call"]))
	_tapped = false
	_move_go = false
	while not _skipping:
		await get_tree().process_frame
		_asked_secs += get_process_delta_time()
		if _move_go:
			break
		if _tapped:
			_tapped = false
			if card != null and not is_instance_valid(card):
				card = null
			if _tap_at == Vector2.INF or _on_move(_tap_at, card):
				break
	_move_go = false
	_hide_hint()
	_asking = ""
	_free_at = _t   # (the move's own shot may cut in at once)
	_cut_at = _t
	# (skipped while it waited: the close has taken his hand away already)
	if card != null and not is_instance_valid(card):
		card = null
	if _skipping:
		_drop_hand(0.0)
		_drop_ring()
		_hint_home()
		return
	_film_bars(true, 0.4)
	_move_sound(gate, action)
	_play_hand(card)
	_drop_ring()
	_move_film(gate)
	_hint_home()
	# (and back at once: the move is made the moment this returns)


## A sound the moment each move is made (12 November, Gary said yes to "a
## sound on each tap: the card going down, the hound's cry, a page
## turning"): the card off his hand, the hound's snarl as it is marked, the
## Last Page turning. What the move does then has the duel's own sounds (the
## call, the Totems' voices, the blows: DuelScreen).
func _move_sound(gate: String, action: Dictionary) -> void:
	match gate:
		"attack":
			var t = action.get("target")
			if t is DuelTotem:
				var c := Sfx.cry_of((t as DuelTotem).id(), "call")
				if String(c[0]) != "":
					_snd(String(c[0]), float(c[1]), float(c[2]))
		"last_page":
			_snd("page_turn", 1.0, 2.0)
		_:
			_snd("card_lift")


## A sound over the memory, at the duel's own loudness when its screen is up.
func _snd(sound: String, pitch: float = 1.0, gain_db: float = 0.0) -> void:
	var s: Sfx = _screen.sfx if is_instance_valid(_screen) and is_instance_valid(_screen.sfx) else Sfx.shared()
	s.play(sound, pitch, gain_db)


## The hint back where the walk's and the pick-up's were, once it has faded
## (it sits over his hand for a card).
func _hint_home() -> void:
	await get_tree().create_timer(0.45, false).timeout
	if _asking == "" and is_instance_valid(_hint):
		_hint.offset_top = -170
		_hint.offset_bottom = -110


## Is a tap at `pos` on what's to be tapped: the glowing card, or the ring on
## the hound (MOVE_NEAR px round either counts)?
func _on_move(pos: Vector2, card: Control) -> bool:
	if card != null and is_instance_valid(card):
		return card.get_global_rect().grow(MOVE_NEAR * SafeArea.ui_scale()).has_point(pos)
	if _ring != null and is_instance_valid(_ring):
		return pos.distance_to(_ring.centre) <= _ring.radius + MOVE_NEAR * SafeArea.ui_scale()
	return true


## Bram's hand along the bottom of the picture, as paintings (PlayCard: no
## names, costs or numbers), the card to play (`glow_id`) lifted and glowing
## and the rest dimmed. Returns the glowing card (null if it isn't there).
func _show_hand(glow_id: String) -> Control:
	_drop_hand(0.0)
	if not is_instance_valid(_screen) or _screen.game == null:
		return null
	var ids: Array = []
	for c in _screen.game.players[0].hand:
		ids.append(String((c as DuelCard).id))
	if ids.is_empty():
		return null
	_hand = Control.new()
	_hand.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_hand)
	_root.move_child(_hand, _white.get_index())   # over the duel and its bars, under the white and the black
	var sz := _root.size
	var hgt := clampf(sz.y * 0.32, 190.0, 420.0)
	var wid := hgt * 5.0 / 7.0
	var step := wid * 0.86
	var n := ids.size()
	var picked: PlayCard = null
	for i in n:
		var pc := PlayCard.new()
		pc.id = ids[i]
		pc.element = String(DuelCards.CARDS.get(ids[i], {}).get("element", ""))
		pc.size = Vector2(wid, hgt)
		var off := float(i) - float(n - 1) * 0.5
		var lit: bool = ids[i] == glow_id and picked == null
		pc.position = Vector2(sz.x * 0.5 + off * step - wid * 0.5, sz.y - hgt * (0.96 if lit else 0.78) + absf(off) * hgt * 0.03)
		pc.pivot_offset = Vector2(wid * 0.5, hgt)
		pc.rotation = deg_to_rad(off * 4.5)
		pc.lit = lit
		if not lit:
			pc.modulate = Color(0.5, 0.52, 0.62)
		_hand.add_child(pc)
		if lit:
			picked = pc
	if picked != null:
		_hand.move_child(picked, -1)
	_hand.position.y = hgt
	create_tween().tween_property(_hand, "position:y", 0.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return picked


## The card played: up out of his hand and gone, the rest of the hand down.
func _play_hand(card: Control) -> void:
	if card != null and is_instance_valid(card):
		var tw := create_tween().set_parallel(true)
		tw.tween_property(card, "position:y", card.position.y - card.size.y * 0.7, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(card, "modulate:a", 0.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_drop_hand(0.4)


func _drop_hand(secs: float) -> void:
	var h := _hand
	_hand = null
	if h == null or not is_instance_valid(h):
		return
	if secs <= 0.0:
		h.queue_free()
		return
	var tw := create_tween()
	tw.tween_property(h, "position:y", clampf(_root.size.y * 0.32, 190.0, 420.0) * 1.1, secs).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(h.queue_free)


## The ring of light on the hound to strike (it follows the hound as the
## picture settles: _place_ring, each frame).
func _show_ring(target) -> void:
	_drop_ring()
	if not (target is DuelTotem):
		return
	_ring_of = target
	_ring = MoveRing.new()
	_ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring.modulate.a = 0.0
	_root.add_child(_ring)
	_root.move_child(_ring, _white.get_index())
	_place_ring()
	create_tween().tween_property(_ring, "modulate:a", 1.0, 0.4)


func _drop_ring() -> void:
	var r := _ring
	_ring = null
	_ring_of = null
	if r != null and is_instance_valid(r):
		var tw := create_tween()
		tw.tween_property(r, "modulate:a", 0.0, 0.2)
		tw.tween_callback(r.queue_free)


func _place_ring() -> void:
	var f := _dir_f
	if _ring == null or not is_instance_valid(_ring) or _ring_of == null or f == null or not is_instance_valid(f) or f.cam == null:
		return
	var foot := f.foot_world(_ring_of.owner, _ring_of.slot)
	var a := _field_px(f, foot)
	var b := _field_px(f, foot + Vector3(0, _height(_ring_of), 0))
	_ring.centre = (a + b) * 0.5
	_ring.radius = clampf(a.distance_to(b) * 0.66, 64.0 * SafeArea.ui_scale(), 260.0 * SafeArea.ui_scale())


## A point on the duel's field, where it's drawn on the screen (this layer's
## own pixels).
func _field_px(f: DuelField3D, p: Vector3) -> Vector2:
	var px := f.cam.unproject_position(p)
	if f.vp != null and f.vp.size.x > 0 and f.vp.size.y > 0:
		px *= f.size / Vector2(f.vp.size)
	return f.get_global_transform() * px


## Gary's own shot of one of the three moves, over the duel as it plays the
## move out underneath (StoryFilm "white_sky_move_1", "_2", "_3": the brief's
## in docs/script/films_plan.md), when he's made it; nothing until then. The
## next move isn't asked for, and the white doesn't come, until it has ended
## (_clip_on).
func _move_film(gate: String) -> void:
	var nm := "white_sky_move_%d" % (WhiteSkyDuel.PLAY_GATES.find(gate) + 1)
	if w == null or not StoryFilm.available(nm):
		return
	_clip_on = true
	var was := layer
	layer = 11   # (under the film: StoryFilm is 12, the subtitles 14)
	await StoryFilm.play(w, nm)
	layer = was
	if _ov != null:
		_ov.black(false)
	if gate != WhiteSkyDuel.PLAY_GATES[-1] and not _skipping:
		Music.play(["white_sky_duel", "white_sky", "sigilfall"], 0.3)
	_clip_on = false


# --- the filmed duel's camera (8 November) --------------------------------------
## How the film cuts: no new cut sooner than this after the last, unless a
## blow lands (s of the memory's clock); a turn's opening and a Rite held
## this long; with nothing happening for IDLE_WIDE, a wide shot drifting.
const MIN_HOLD := 1.3
const TURN_HOLD := 1.8
const CALL_HOLD := 2.2
const HIT_HOLD := 1.1
const KO_HOLD := 1.6
const IDLE_WIDE := 3.8
## The hero shot's rise up a Totem just called (s), and a turn's creep in.
const HERO_RISE_SECS := 1.7
const CREEP_SECS := 4.0
## How big the hunter stands on the duel's field (its scale).
const HUNTER_SCALE := 1.15
## A blow this big shakes the camera harder.
const BIG_BLOW := 60
## The black bars of a widescreen film: the picture kept to FILM_ASPECT
## where the screen is narrower, each bar between BAR_MIN and BAR_MAX of
## the height (a phone's wide screen needs little, a Mac's more); a little
## more for the Last Page.
const FILM_ASPECT := 2.35
const BAR_MIN := 0.04
const BAR_MAX := 0.1
const BAR_CLIMAX := 0.025
## How long the Last Page's blow is held before the white comes (s; 0.5
## until 8 November, when the Last Page was barely seen before the white).
const CLIMAX_HOLD := 1.0

var _dir_f: DuelField3D = null
var _cut_at := 0.0        # when the last cut came
var _free_at := 0.0       # no ordinary cut before this
var _wide_i := 0
var _climax := false
var _attacker: DuelTotem = null
var _bars: Array = []     # [top, bottom]


func _on_beat(method: String, args: Array) -> void:
	if _dir_f == null or not is_instance_valid(_dir_f) or _climax or _skipping:
		return
	match method:
		"fx_turn":
			_beat_turn(int(args[0]))
		"fx_call", "fx_ascend", "fx_revive":
			var t = args[0] if not args.is_empty() else null
			if t is DuelTotem:
				_beat_call(t)
		"fx_attack":
			if args[0] is DuelTotem:
				_beat_attack(args[0], args[2] if args.size() > 2 else null)
		"fx_totem_hit":
			if args[0] is DuelTotem:
				_beat_hit(args[0], int(args[1]))
		"fx_life_hit":
			_beat_life(int(args[0]), int(args[1]))
		"fx_ko":
			if args[0] is DuelTotem:
				_beat_ko(args[0])
		"fx_rite":
			_beat_rite(int(args[0]), args[2] if args.size() > 2 else null)
		"fx_status":
			# (only a Doom: the rest come thick and fast and would chop the film up)
			if args[0] is DuelTotem and String(args[1]) == "doomed":
				_beat_close(args[0], MIN_HOLD + 0.6)
		"fx_ward_spring":
			_beat_rite(int(args[0]), null)


## A shot: [camera, looking at, lens]; cut to it (glide 0) or glide over
## `glide` s, held `hold` s before an ordinary cut may follow; then, if
## `creep`, a slow creep in over CREEP_SECS unless something else has
## moved the camera meanwhile.
func _take(c: Array, glide: float, hold: float, creep := false) -> void:
	var f := _dir_f
	if c.is_empty() or f == null:
		return
	_home_on(c)
	f.cam_shot(c[0], c[1], glide, float(c[2]), glide <= 0.0)
	_cut_at = _t
	_free_at = _t + maxf(hold, MIN_HOLD)
	if creep:
		_creep(c, maxf(glide, 0.05))


## The field's home made this shot (the duel screen still sends the camera
## home, and leans it a little towards what's happening, in a film too: so
## it goes home to the shot it's in, not back to the wide), without moving
## the camera.
func _home_on(c: Array) -> void:
	var f := _dir_f
	var p := f.cam_pos
	var l := f.cam_look
	var was := f.cam_fov
	f.cam_fov = float(c[2])
	f.set_home(c[0], c[1])
	f.cam_pos = p
	f.cam_look = l
	f.cam_fov = was


func _creep(c: Array, after: float) -> void:
	var f := _dir_f
	var moves := f.cam_moves
	await get_tree().create_timer(after, false).timeout
	if _dir_f != f or f == null or not is_instance_valid(f) or f.cam_moves != moves or _climax:
		return
	var p: Vector3 = (c[0] as Vector3).lerp(c[1] as Vector3, 0.14)
	if _face_seen(p, c[1], float(c[2]) - 3.0):
		return
	_home_on([p, c[1], float(c[2]) - 3.0])
	f.cam_shot(p, c[1], CREEP_SECS, float(c[2]) - 3.0)


## The first of `cands` that keeps Bram's face out of the picture and the
## camera out of the hunter (empty if none does: the camera stays put).
func _pick(cands: Array) -> Array:
	for c in cands:
		if c.is_empty():
			continue
		if not _face_seen(c[0], c[1], float(c[2])) and not _in_the_way(c[0]):
			return c
	return []


## Would Bram's face be in this shot? His head in the picture (with room to
## spare: the duel's picture is widened past the lens on wide screens, and
## the drift and shake move it) with the camera anywhere but behind his
## shoulders. (Side-on counts: a profile is a face.)
func _face_seen(pos: Vector3, look: Vector3, fov: float) -> bool:
	var head := BRAM_AT + Vector3(0, 1.68, 0)
	var fwd := Vector3.FORWARD
	if is_instance_valid(_bram) and _bram is PaperDoll:
		fwd = (_bram as PaperDoll).facing()
		fwd.y = 0.0
		fwd = fwd.normalized() if fwd.length() > 0.01 else Vector3.FORWARD
	var to_cam := pos - head
	if to_cam.length() < 0.01:
		return true
	if to_cam.normalized().dot(fwd) < -0.3:
		return false   # behind him: the back of his head
	var z := (look - pos).normalized()
	if z.length() < 0.5:
		return true
	var x := z.cross(Vector3.UP).normalized()
	var y := x.cross(z)
	var h := head - pos
	var depth := h.dot(z)
	if depth <= 0.05:
		return false   # behind the camera
	var tv := tan(deg_to_rad(fov) * 0.5) * 1.45 + 0.08
	var th := tv * 2.25 + 0.08
	return absf(h.dot(x) / depth) < th and absf(h.dot(y) / depth) < tv


## A camera standing in the hunter (or under the snow) is no shot.
func _in_the_way(pos: Vector3) -> bool:
	if pos.y < 0.25:
		return true
	return Vector2(pos.x - HUNTER_AT.x, pos.z - HUNTER_AT.z).length() < 1.3 and pos.y < 3.2


## Over Bram's right shoulder, past him at `at`: [camera, look, lens].
func _over_bram(at: Vector3, fov := 36.0, back := 2.4, side := 0.9, up := 0.5) -> Array:
	var head := BRAM_AT + Vector3(0, 1.68, 0)
	var d := Vector3(at.x - head.x, 0, at.z - head.z)
	d = d.normalized() if d.length() > 0.01 else Vector3.FORWARD
	var r := d.cross(Vector3.UP)
	return [head - d * back + r * side + Vector3(0, up, 0), at, fov]


## The hunter across the Circle from Bram's side, on a long lens.
func _on_hunter(fov := 19.0, near := 0.0) -> Array:
	var h := HUNTER_AT + Vector3(0, 1.75 * HUNTER_SCALE, 0)
	# (high enough to look over its pack: from lower the hounds' flames and
	# cards stood between)
	var off := Vector3(1.5, 1.2, 7.6).lerp(Vector3(1.1, 0.9, 4.6), near)
	return [h + off, h + Vector3(0, 0.15, 0), fov]


func _body(t: DuelTotem) -> Vector3:
	return _dir_f.body_world(t.owner, t.slot)


func _foot(t: DuelTotem) -> Vector3:
	return _dir_f.foot_world(t.owner, t.slot)


func _height(t: DuelTotem) -> float:
	var s = _dir_f.slots[t.owner][t.slot]
	return float(s.creature_h) if s != null and String(s.card_id) != "" else 2.0


## From low behind a Totem and out to its side, over its shoulder at what
## it faces across the Circle (Bram's own Totems from his side of them: from
## in front the picture would look back into his face).
func _behind_low(t: DuelTotem, k := 1.0, fov := 40.0) -> Array:
	var foot := _foot(t)
	var hgt := _height(t)
	var d := _dir_f.ahead_of(t.owner)
	var out := Vector3(signf(foot.x) if absf(foot.x) > 0.5 else 1.0, 0, 0)
	var pos := foot - d * 3.4 + out * 2.0 + Vector3(0, lerpf(0.6, hgt * 0.8, k), 0)
	return [pos, foot + d * 3.0 + Vector3(0, hgt * 0.5, 0), fov]


## From out to the side of the Circle, low, across at a Totem (a long lens).
func _side_on(t: DuelTotem, k := 1.0, fov := 28.0) -> Array:
	var foot := _foot(t)
	var hgt := _height(t)
	var out := Vector3(signf(foot.x) if absf(foot.x) > 0.5 else 1.0, 0, 0)
	var pos := foot + out * 5.2 + _dir_f.ahead_of(t.owner) * 1.0 + Vector3(0, lerpf(0.6, hgt * 0.8, k), 0)
	return [pos, foot + Vector3(0, hgt * 0.55, 0), fov]


func _beat_turn(pi: int) -> void:
	if _t < _free_at:
		return
	var c: Array
	if pi == 0:
		c = _pick([_over_bram(Vector3(0, 1.0, -1.5), 40.0, 3.0, 1.2, 0.8), SHOTS[0]])
	else:
		c = _pick([_on_hunter(19.0), SHOTS[3]])
	_take(c, 0.0, TURN_HOLD, true)


## A Totem called (or ascended, or back from the dead): the low hero shot,
## rising up it as it comes.
func _beat_call(t: DuelTotem) -> void:
	var f := _dir_f
	var lo: Array = f.shot_hero(t.owner, t.slot, 0.0)
	var hi: Array = f.shot_hero(t.owner, t.slot, 1.0)
	var cands_lo: Array = [[lo[0], lo[1], DuelField3D.SHOT_FOV_HERO], _side_on(t, 0.0), _behind_low(t, 0.0)]
	var cands_hi: Array = [[hi[0], hi[1], DuelField3D.SHOT_FOV_HERO - 4.0], _side_on(t, 1.0, 25.0), _behind_low(t, 1.0, 36.0)]
	for i in cands_lo.size():
		var a: Array = cands_lo[i]
		var b: Array = cands_hi[i]
		if not _face_seen(a[0], a[1], float(a[2])) and not _face_seen(b[0], b[1], float(b[2])) and not _in_the_way(a[0]) and not _in_the_way(b[0]):
			_take(a, 0.0, CALL_HOLD)
			_home_on(b)
			f.cam_shot(b[0], b[1], HERO_RISE_SECS, float(b[2]))
			return


## An attack: from behind the attacker, across at what it's going for; the
## hunter's seen coming from behind what they're going for (from behind
## his hounds the picture would look back into Bram's face).
func _beat_attack(t: DuelTotem, target) -> void:
	_attacker = t
	_struck = false
	if _t < _free_at:
		return   # (a flurry: seen in the shot already up)
	var f := _dir_f
	var aim: Vector3
	if target is DuelTotem:
		aim = _body(target)
	elif target is String and target == DuelGame.LIFE:
		aim = f.life_world(1 - t.owner)
	else:
		aim = _body(t) + f.ahead_of(t.owner) * 4.6
	var me := _body(t)
	var b: Array = f.shot_behind(me, aim, t.owner)
	var cands: Array = [[b[0], b[1], DuelField3D.SHOT_FOV_BEHIND]]
	if target is DuelTotem:
		var r: Array = f.shot_behind(aim, me, (target as DuelTotem).owner)
		cands.append([r[0], r[1], DuelField3D.SHOT_FOV_BEHIND])
	elif t.owner == 1:
		cands.append(_over_bram(me, 34.0, 2.2, 1.0, 0.55))
	cands.append(_side_on(t, 0.8, 32.0))
	if t.owner == 0:
		# (his own, going across the Circle on a slant: over his shoulder,
		# watching it go)
		cands.append(_over_bram(aim, 38.0, 2.6, 1.0, 0.6))
	_take(_pick(cands), 0.3, MIN_HOLD)


## A blow landing on a Totem: a big one cut to and the camera shaken by it;
## a small one only shakes the shot that's up (8 November: a cut to every
## blow had the film cutting every second).
var _struck := false

func _beat_hit(t: DuelTotem, amount: int) -> void:
	var f := _dir_f
	if amount < BIG_BLOW or _struck:
		f.cam_shake(4.5)
		return
	_struck = true
	var land := _body(t)
	var from := _body(_attacker) if _attacker != null and is_instance_valid(_attacker) and _attacker.owner != t.owner else land - f.ahead_of(t.owner) * 5.0
	var cl: Array = f.shot_close(land, from, 1 - t.owner)
	var cands: Array = [[cl[0], cl[1], DuelField3D.SHOT_FOV_CLOSE]]
	if t.owner == 0:
		# Bram's own, struck: from behind it, the blow coming at it
		var d := f.ahead_of(0)
		var out := Vector3(signf(land.x) if absf(land.x) > 0.5 else 1.0, 0, 0)
		cands.append([land - d * 3.4 + out * 1.5 + Vector3(0, 1.1, 0), land + d * 0.8, 36.0])
	cands.append(_side_on(t, 0.7, 30.0))
	_take(_pick(cands), 0.0, HIT_HOLD)
	f.cam_shake(9.0 if amount >= BIG_BLOW else 4.5)


## A blow on a duellist: on Bram, over his shoulder as he takes it (he
## flinches); on the hunter, the hunter close.
func _beat_life(pi: int, amount: int) -> void:
	var f := _dir_f
	var c: Array
	if pi == 0:
		var from := _body(_attacker) if _attacker != null and is_instance_valid(_attacker) else HUNTER_AT
		c = _pick([_over_bram(from, 32.0, 1.7, 0.75, 0.4), SHOTS[3]])
		_act(_bram, "hit_react")
	else:
		c = _pick([_on_hunter(28.0, 0.6), _on_hunter(24.0)])
	_take(c, 0.0, HIT_HOLD)
	f.cam_shake(10.0 if amount >= BIG_BLOW else 5.0)


## A Totem broken: held close as it goes.
func _beat_ko(t: DuelTotem) -> void:
	var f := _dir_f
	var k: Array = f.shot_ko(t.owner, t.slot)
	_take(_pick([[k[0], k[1], DuelField3D.SHOT_FOV_KO], _behind_low(t, 0.8, 36.0), _side_on(t, 0.6, 28.0)]), 0.0, KO_HOLD)
	f.cam_shake(6.0)


## Close on a Totem something has happened to (a Doom, a curse).
func _beat_close(t: DuelTotem, hold: float) -> void:
	var f := _dir_f
	var k: Array = f.shot_ko(t.owner, t.slot)
	_take(_pick([[k[0], k[1], DuelField3D.SHOT_FOV_KO + 4.0], _side_on(t, 0.7, 30.0), _behind_low(t, 0.9, 38.0)]), 0.35, hold)


## A Rite cast: whoever casts it (Bram over his shoulder, his hand up with
## the card; the hunter across the Circle).
func _beat_rite(pi: int, target) -> void:
	if _t < _free_at:
		return
	var at := Vector3(0, 1.0, -1.0)
	if target is DuelTotem:
		at = _body(target)
	var c: Array = _pick([_over_bram(at, 36.0, 2.2, 0.9, 0.5), SHOTS[0]]) if pi == 0 else _pick([_on_hunter(21.0, 0.3), SHOTS[3]])
	_take(c, 0.25, MIN_HOLD + 0.4)


## Nothing for a while: one of the wide shots, drifting into place.
func _wide_shot() -> void:
	for k in WIDES.size():
		var s: Array = WIDES[_wide_i % WIDES.size()]
		_wide_i += 1
		if not _face_seen(s[0], s[1], float(s[2])):
			_take([s[0], s[1], s[2]], 2.4, MIN_HOLD, true)
			return
	_cut_at = _t


## The Last Page called down: low over his shoulder, then back and up to
## CLIMAX, the whole of what comes down in the picture; the bars a little
## deeper.
func _climax_shot() -> void:
	var f := _dir_f
	var c: Array = CLIMAX
	var start := _over_bram(Vector3(0.0, 3.0, -6.0), 40.0, 1.6, 0.7, 0.15)
	if not _face_seen(start[0], start[1], float(start[2])):
		f.cam_shot(start[0], start[1], 0.0, float(start[2]), true)
	_home_on(c)
	f.cam_shot(c[0], c[1], 2.6, float(c[2]))
	_film_bars(true, 0.8, BAR_CLIMAX)


## The Totems' cards lying under them on the field, with their names and
## numbers, kept out of the film (8 November: a film, not a game; the rune
## rings still mark the Circle's places).
func _hide_plates(f: DuelField3D) -> void:
	for side in f.slots:
		for i in f.slots[side]:
			var s = f.slots[side][i]
			if s != null and s.card != null and s.card.visible:
				s.card.visible = false


## The film's black bars over the duel (on), or gone.
func _film_bars(on: bool, secs := 0.6, extra := 0.0) -> void:
	if _bars.is_empty():
		if not on:
			return
		for i in 2:
			var r := ColorRect.new()
			r.color = Color.BLACK
			r.mouse_filter = Control.MOUSE_FILTER_IGNORE
			r.anchor_right = 1.0
			if i == 1:
				r.anchor_top = 1.0
				r.anchor_bottom = 1.0
			_root.add_child(r)
			_bars.append(r)
	var sz := _root.size
	var k := 0.0
	if on and sz.y > 1.0:
		k = clampf((1.0 - (sz.x / sz.y) / FILM_ASPECT) * 0.5, BAR_MIN, BAR_MAX) + extra
	var hgt := sz.y * k
	for i in 2:
		var r: ColorRect = _bars[i]
		# over the duel, under the white and the black
		var at := _white.get_index()
		if r.get_index() > at:
			_root.move_child(r, at)
		var tw := create_tween().set_parallel(true)
		if i == 0:
			tw.tween_property(r, "offset_bottom", hgt, maxf(secs, 0.01)).set_trans(Tween.TRANS_SINE)
		else:
			tw.tween_property(r, "offset_top", -hgt, maxf(secs, 0.01)).set_trans(Tween.TRANS_SINE)


## The duel's spec for DuelScreen (tests read it too): the played duel's set
## board and its two sides' players (WhiteSkyDuel.play_board,
## play_controllers), with no HUD (film).
static func duel_spec() -> Dictionary:
	var D := WhiteSkyDuel
	return {"decks": [D.PLAY_BRAM_DECK.duplicate(), D.PLAY_HUNTER_DECK.duplicate()], "stacked": [true, true],
		"puzzle": D.play_board(), "story_rules": D.story_rules(),
		"names": ["Bram", "The hunter"], "profiles": [D.bram_profile(), D.hunter_profile()],
		"ai": [true, true], "controllers": D.play_controllers(), "difficulty": D.SKILL, "seed": D.SEED, "speed": D.FILM_SPEED,
		"film": true, "arena": "ironstone", "spectral_side": 1, "life_floor": D.LIFE_FLOOR.duplicate(),
		"music": ["white_sky_duel", "white_sky", "sigilfall"], "film_home": SHOTS[0], "field3d": true}


# --- 6. the end ---------------------------------------------------------------------
func _close() -> void:
	_hide_hint()
	_roam = false
	_dir_f = null
	_asking = ""
	_drop_hand(0.0)
	_drop_ring()
	if _skip_btn != null:
		_skip_btn.visible = false
	if _compass != null:
		_compass.show_compass(false, 0.3)
	if _white.modulate.a < 0.99:
		var wt := create_tween()
		wt.tween_property(_white, "modulate:a", 1.0, 0.5)
		await wt.finished
	await _wait(0.6)
	_end_screen(_screen)
	_end_screen(_prep)   # (skipped before the duel: never shown)
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
	_hush(false)
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
	# (0.034 until 4 November: the spires, 26 m and more from the crater,
	# were all but lost in it, and the storm read as an empty white field)
	_env.fog_density = 0.026
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
	_moon.light_energy = 0.78
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
	_build_storm()
	_cam = Camera3D.new()
	_cam.near = 0.05
	_cam.far = 400.0
	_set.add_child(_cam)
	_cam.current = true
	var who := "bram_coat" if Figure3D.has_model("bram_coat") else "bram"
	_bram = Figure3D.make(who, who)
	if _bram is Figure3D:
		(_bram as Figure3D).step_on = "snow"   # (12 November: his boots in the snow, the first sound the player makes)
	_set.add_child(_bram)
	if _bram is Figure3D:
		# (the same evening: his breath in the cold)
		var cold := Breath.new()
		cold.who = [_bram]
		cold.wind = Vector3(-1.1, 0.0, 0.3)   # (the way the snow is blown)
		_set.add_child(cold)
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


## The Shardlands: dark glass spires standing out of the snow, leaning, lit
## faintly from inside and rimmed with the sky's light, from great ones far
## off to shards no taller than a man about his way (4 November, Gary: "make
## the snow storm place look better": the 46 spires were all 26 m or more
## from the crater, in fog that hid them, so he walked an empty field). He
## walks round them (_spires).
##
## 6 November (Gary: "Can we make the whole scene like the shards of ice and
## the cards look much better"): the spires were plain four- and five-sided
## cones of near-black glass. Each is a cluster of ice crystals now
## (_crystal_mesh: a six-sided prism with a cut point, flat facets, a few
## smaller ones leaning out from its foot), in the ICE shader: deep blue ice
## you see into, cracks and veins of light inside it at depth (a few layers
## looked into along the refracted view, ICE_LAYERS by Gfx.level()), the
## facets' edges catching the light, a bright fresnel rim, the sky's light
## caught in the points, frost and drifted snow at the foot.
func _build_spires() -> void:
	var ice := ice_material(quality, false)
	var r := RandomNumberGenerator.new()
	r.seed = 77
	var n: int = [40, 64, 90][clampi(quality, 0, 2)]
	for i in n:
		var ang := r.randf() * TAU
		var big: bool = i % 3 == 0
		var dist := r.randf_range(24.0, 70.0) if big else r.randf_range(6.0, 40.0)
		var p := CRATER + Vector3(cos(ang), 0, sin(ang)) * dist
		if p.distance_to(WALK_FROM) < 4.0 or (absf(p.x) < 3.0 and p.z > -27.0 and p.z < 1.0):
			continue   # not on top of him at the start, nor straight across his way
		var hgt := r.randf_range(9.0, 22.0) if big else r.randf_range(1.4, 6.0)
		var rad := hgt * r.randf_range(0.07, 0.11)
		var mi := MeshInstance3D.new()
		mi.mesh = _crystal_mesh(r, hgt, rad, r.randi_range(2, 4) if big else r.randi_range(1, 3))
		mi.material_override = ice
		mi.set_instance_shader_parameter("seed", r.randf() * 10.0)
		mi.set_instance_shader_parameter("glow", r.randf_range(0.7, 1.15))
		# its foot a little into the snow, leaning as the fall left it
		mi.position = p + Vector3(0, _low_ground(p, rad * 2.5) - 0.05, 0)
		mi.rotation = Vector3(r.randf_range(-0.22, 0.22), r.randf() * TAU, r.randf_range(-0.22, 0.22))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if big else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_set.add_child(mi)
		_spires.append([p.x, p.z, rad * 1.5 + 0.45])
		# a few small shards about its foot
		if not big and r.randf() < 0.5:
			for k in 3:
				var sp := p + Vector3(r.randf_range(-1.6, 1.6), 0, r.randf_range(-1.6, 1.6))
				var sh2 := r.randf_range(0.3, 0.95)
				var si := MeshInstance3D.new()
				si.mesh = _crystal_mesh(r, sh2, sh2 * 0.13, r.randi_range(0, 1))
				si.material_override = ice
				si.set_instance_shader_parameter("seed", r.randf() * 10.0)
				si.set_instance_shader_parameter("glow", 0.9)
				si.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				si.position = sp + Vector3(0, _low_ground(sp, sh2 * 0.4) - 0.03, 0)
				si.rotation = Vector3(r.randf_range(-0.5, 0.5), r.randf() * TAU, r.randf_range(-0.5, 0.5))
				_set.add_child(si)


## The lowest the snow lies within `r` of `p` (a crystal's foot is set to
## it, so on a slope or a drift no side of it stands clear of the snow).
static func _low_ground(p: Vector3, r: float) -> float:
	var lo := height(p.x, p.z)
	for k in 8:
		var a := TAU * k / 8.0
		lo = minf(lo, height(p.x + cos(a) * r, p.z + sin(a) * r))
	return lo


## How many layers deep the ice is looked into, by Gfx.level() (the phone
## link, a phone, a Mac).
const ICE_LAYERS := [1, 2, 3]
static var _ice_mats := {}

## The ice's material: `fresh` for the shards thrown out of the crater (paler,
## lit from within by the fall); shared by every crystal of its kind.
static func ice_material(q: int, fresh: bool) -> ShaderMaterial:
	var key := "%d:%s" % [q, fresh]
	if _ice_mats.has(key):
		return _ice_mats[key]
	var sh := Shader.new()
	sh.code = ICE.replace("ICE_LAYERS", str(ICE_LAYERS[clampi(q, 0, 2)]))
	var m := ShaderMaterial.new()
	m.shader = sh
	if fresh:
		m.set_shader_parameter("deep", Color(0.05, 0.1, 0.18))
		m.set_shader_parameter("ice", Color(0.5, 0.72, 1.0))
		m.set_shader_parameter("inner_k", 1.6)
		m.set_shader_parameter("frost_k", 0.0)
	_ice_mats[key] = m
	return m


## A cluster of ice crystals, its foot at the origin, `hgt` tall: a prism of
## five or six faces, a little uneven, narrowing a touch and cut to a point;
## and `extra` smaller ones growing out of its foot, leaning away. Flat
## facets (a normal a face). UV: x across a face (0..1), y up the crystal (0
## at its foot, 1 at the point); UV2.y how wide the face is there (1 on the
## prism, narrowing to 0 at the point: the shader's distance to a facet's
## edge), UV2.x the crystal's own random.
static func _crystal_mesh(r: RandomNumberGenerator, hgt: float, rad: float, extra: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_crystal(st, r, Transform3D.IDENTITY, hgt, rad)
	for k in extra:
		var a := r.randf() * TAU
		var d := Vector3(cos(a), 0.0, sin(a))
		var lean := r.randf_range(0.35, 0.85)
		var b := Basis(Vector3.UP.cross(d).normalized(), lean)
		var h2 := hgt * r.randf_range(0.28, 0.6)
		var o := d * rad * r.randf_range(0.5, 0.95) - Vector3(0, h2 * 0.15, 0)
		_crystal(st, r, Transform3D(b, o), h2, rad * r.randf_range(0.4, 0.7))
	return st.commit()


static func _crystal(st: SurfaceTool, r: RandomNumberGenerator, xf: Transform3D, hgt: float, rad: float) -> void:
	var n := 6 if r.randf() < 0.7 else 5
	var body := hgt * r.randf_range(0.62, 0.8)
	var rnd := r.randf()
	var bot: Array = []
	var top: Array = []
	var a0 := r.randf() * TAU
	for i in n:
		var a := a0 + TAU * float(i) / n + r.randf_range(-0.12, 0.12)
		var rr := rad * r.randf_range(0.82, 1.15)
		# (its foot runs on below the snow, so a lean never lifts it clear)
		bot.append(Vector3(cos(a) * rr, -hgt * 0.3, sin(a) * rr))
		var rt := rr * r.randf_range(0.8, 0.95)
		top.append(Vector3(cos(a) * rt, body, sin(a) * rt))
	var apex := Vector3(r.randf_range(-0.2, 0.2) * rad, hgt, r.randf_range(-0.2, 0.2) * rad)
	var vt := body / hgt
	for i in n:
		var j := (i + 1) % n
		var mid := ((bot[i] as Vector3) + (bot[j] as Vector3)) * 0.5
		var out := Vector3(mid.x, 0.0, mid.z)
		_tri(st, xf, out, [bot[i], top[i], top[j]], [Vector2(0, 0), Vector2(0, vt), Vector2(1, vt)], [1.0, 1.0, 1.0], rnd)
		_tri(st, xf, out, [bot[i], top[j], bot[j]], [Vector2(0, 0), Vector2(1, vt), Vector2(1, 0)], [1.0, 1.0, 1.0], rnd)
		var tm := ((top[i] as Vector3) + (top[j] as Vector3)) * 0.5
		var out2 := Vector3(tm.x, (hgt - body) * 0.3, tm.z)
		_tri(st, xf, out2, [top[i], apex, top[j]], [Vector2(0, vt), Vector2(0.5, 1), Vector2(1, vt)], [1.0, 0.0, 1.0], rnd)


## One flat-shaded triangle, wound so its face points along `out` (Godot's
## front faces are clockwise).
static func _tri(st: SurfaceTool, xf: Transform3D, out: Vector3, p: Array, uv: Array, w: Array, rnd: float) -> void:
	var a: Vector3 = xf * (p[0] as Vector3)
	var b: Vector3 = xf * (p[1] as Vector3)
	var c: Vector3 = xf * (p[2] as Vector3)
	var nrm := (b - a).cross(c - a)
	var o := xf.basis * out
	# (counter-clockwise from outside makes this point out: turn it round)
	var order := [0, 2, 1] if nrm.dot(o) > 0.0 else [0, 1, 2]
	nrm = nrm.normalized() if nrm.dot(o) > 0.0 else -nrm.normalized()
	var pts := [a, b, c]
	for k in order:
		st.set_normal(nrm)
		st.set_uv(uv[k])
		st.set_uv2(Vector2(rnd, float(w[k])))
		st.add_vertex(pts[k])


## The storm itself, over the snowfall: sheets of snow blown low along the
## ground in the wind (streaks, their long side along the way they go),
## and big flakes close to the camera.
var _blown: GPUParticles3D
var _near_snow: GPUParticles3D

func _build_storm() -> void:
	_blown = GPUParticles3D.new()
	_blown.amount = [160, 320, 520][clampi(quality, 0, 2)]
	_blown.lifetime = 3.2
	_blown.preprocess = 3.2
	_blown.visibility_aabb = AABB(Vector3(-60, -10, -60), Vector3(120, 30, 120))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(22, 1.2, 22)
	pm.direction = Vector3(-5.5, -0.15, 1.6).normalized()
	pm.spread = 8.0
	pm.initial_velocity_min = 6.0
	pm.initial_velocity_max = 10.0
	pm.gravity = Vector3(0, -0.2, 0)
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 2.2
	pm.turbulence_noise_scale = 1.6
	pm.scale_min = 0.6
	pm.scale_max = 1.6
	pm.particle_flag_align_y = true
	var cr := Curve.new()
	cr.add_point(Vector2(0, 0.0))
	cr.add_point(Vector2(0.3, 1.0))
	cr.add_point(Vector2(1, 0.0))
	var ct := CurveTexture.new()
	ct.curve = cr
	pm.alpha_curve = ct
	_blown.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.14, 1.6)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.billboard_keep_scale = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = DuelFX.dot_tex()
	m.albedo_color = Color(0.88, 0.92, 1.0, 0.16)
	m.vertex_color_use_as_albedo = true
	q.material = m
	_blown.draw_pass_1 = q
	_blown.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_set.add_child(_blown)
	# big flakes close to the camera, soft
	_near_snow = DuelField3D.snow_particles([60, 110, 160][clampi(quality, 0, 2)], Vector3(4, 3, 4), Vector3(-4.5, -2.4, 1.3), 0.2)
	((_near_snow.draw_pass_1 as QuadMesh).material as StandardMaterial3D).albedo_color = Color(0.92, 0.95, 1.0, 0.45)
	_set.add_child(_near_snow)


## Light rising off the child in the crater, so it's seen from the rim: a
## soft beacon of light over it and a slow rise of sparks (on until he
## kneels to it).
var _beacon: Node3D

func _child_beacon(on: bool) -> void:
	if not on:
		if _beacon != null and is_instance_valid(_beacon):
			var tw := create_tween()
			tw.tween_property(_beacon, "scale", Vector3(0.01, 1.0, 0.01), 0.8)
			tw.tween_callback(_beacon.queue_free)
			_beacon = null
		return
	if _beacon != null:
		return
	_beacon = Node3D.new()
	_beacon.position = _baby.position
	_set.add_child(_beacon)
	# the shaft: a tall soft quad, drawn as light, turned to the camera
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.8, 3.6)
	mi.mesh = qm
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	bm.disable_fog = true   # (fog added over an added quad lights its whole square)
	bm.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	bm.albedo_texture = _beam_tex()
	bm.albedo_color = Color(0.22, 0.26, 0.4, 1.0)
	mi.material_override = bm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position.y = 1.7
	_beacon.add_child(mi)
	var sp := GPUParticles3D.new()
	sp.amount = [20, 36, 56][clampi(quality, 0, 2)]
	sp.lifetime = 3.0
	sp.preprocess = 3.0
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.35
	pm.direction = Vector3.UP
	pm.spread = 12.0
	pm.initial_velocity_min = 0.5
	pm.initial_velocity_max = 1.1
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.05
	pm.scale_max = 0.14
	pm.color = Color(0.85, 0.9, 1.0)
	var cr := Curve.new()
	cr.add_point(Vector2(0, 0.0))
	cr.add_point(Vector2(0.2, 1.0))
	cr.add_point(Vector2(1, 0.0))
	var ct := CurveTexture.new()
	ct.curve = cr
	pm.alpha_curve = ct
	sp.process_material = pm
	var q := QuadMesh.new()
	var qm2 := StandardMaterial3D.new()
	qm2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm2.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm2.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	qm2.disable_fog = true   # (fog added over an added quad lights its whole square)
	qm2.albedo_texture = _soft_dot()
	qm2.vertex_color_use_as_albedo = true
	q.material = qm2
	q.size = Vector2(0.5, 0.5)
	sp.draw_pass_1 = q
	sp.position.y = 0.1
	_beacon.add_child(sp)
	sp.emitting = true
	# a brighter glow on it than its mark gives by itself
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.8, 0.86, 1.0)
	glow.light_energy = 0.9
	glow.omni_range = 2.6
	glow.position.y = 0.6
	_beacon.add_child(glow)


static var _beam: GradientTexture2D

## A soft shaft of light: bright along the middle, fading out to its sides
## and off at its top.
static func _beam_tex() -> Texture2D:
	if _beam == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(0, 0, 0, 0))
		_beam = GradientTexture2D.new()
		_beam.gradient = g
		_beam.width = 64
		_beam.height = 128
		_beam.fill = GradientTexture2D.FILL_RADIAL
		_beam.fill_from = Vector2(0.5, 0.95)
		_beam.fill_to = Vector2(0.5, 0.1)
	return _beam


## Shards of white glass thrown out of the crater, pointing away from it.
## (6 November: crystals of the fresh ice, ice_material(fresh), lit from
## within by the fall, the nearer the middle the brighter; a few bigger ones
## round the lip. Kept clear of the child and of where Bram kneels.)
func _build_crater_shards() -> void:
	var m := ice_material(quality, true)
	var r := RandomNumberGenerator.new()
	r.seed = 5
	var n: int = [22, 30, 36][clampi(quality, 0, 2)]
	for i in n:
		var ang := r.randf() * TAU
		var d := r.randf_range(1.6, CRATER_R + 1.4)
		var p := CRATER + Vector3(cos(ang), 0, sin(ang)) * d
		var hgt := r.randf_range(0.25, 0.8) if d < CRATER_R - 1.0 else r.randf_range(0.5, 1.5)
		var mi := MeshInstance3D.new()
		mi.mesh = _crystal_mesh(r, hgt, hgt * r.randf_range(0.1, 0.15), r.randi_range(0, 2))
		mi.material_override = m
		mi.set_instance_shader_parameter("seed", r.randf() * 10.0)
		mi.set_instance_shader_parameter("glow", lerpf(1.6, 0.8, d / (CRATER_R + 1.4)))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = p + Vector3(0, _low_ground(p, hgt * 0.4) - 0.04, 0)
		var out := Vector3(cos(ang), 0, sin(ang))
		# leaning out of the bowl, away from where it struck
		var up := (Vector3.UP * 0.75 + out * 0.65).normalized()
		var side := out.cross(Vector3.UP).normalized()
		mi.basis = Basis(side, up, side.cross(up)) * Basis(Vector3.UP, r.randf() * TAU)
		_set.add_child(mi)


## The child: a bundle of grey wool, a small face, and over the heart the
## ash-grey mark, glowing faintly (SealMark's painting).
func _make_baby() -> Node3D:
	var root := Node3D.new()
	root.name = "Child"
	if ResourceLoader.exists(BABY_MODEL):
		# Gary's model (4 November, Tripo3D, slimmed and laid along z by
		# tools/slim_glb.py: head to -z, face up), about 0.5 m long, with the
		# mark painted on the blanket over the heart as on the drawn one
		var m := (load(BABY_MODEL) as PackedScene).instantiate() as Node3D
		root.add_child(m)
		var aabb := DuelField3D._merged_aabb(m)
		var k := 0.5 / maxf(0.01, maxf(aabb.size.z, maxf(aabb.size.x, aabb.size.y)))
		m.scale = Vector3.ONE * k
		m.position = -aabb.get_center() * k
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
		# on the top of the bundle, a little towards the head
		mark.position = Vector3(0.0, aabb.size.y * k * 0.5 + 0.004, -0.09)
		root.add_child(mark)
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


## He kneels to the child, his hands go under it where it lies, and he
## picks it up the way anyone picks up a baby (4 November, Gary: "he doesn't
## pick up the baby, it's just in his hands"; 5 November: "Bram picks up the
## baby weird, it more levitates into his arms rather than him picking him
## up"; 6 November: "Baby still levitates off ground into Bram's hands").
## Until 6 November his kneel bent his back only so far: on one knee his
## shoulders stayed 0.74 m up, his straight arms ended 15 cm over the
## bundle, and it rose off the snow to meet his hands. Now he kneels square
## on to it, the bundle lying across in front of his right knee
## (_kneel_dir, _kneel_spot), and bends right over it from the hips (Stoop,
## STOOP, laid over the kneel's own bend, LIFT_LEAN): his shoulders come
## down to 0.58 m and a hand goes to each end of it (on the snow, the palms
## on it: tests/white_sky_peek.gd "lift" prints the gap). The bundle stays
## where it lies until both hands are there (lift_gap, HANDS_ON, measured on
## the pose as drawn); then it comes up in his hands as his back comes up
## (carried by his chest bone, its turn as well as its place, so it swings
## up with him), drawn in to his chest as it comes (CRADLE), and he stands
## with it held there. The hands' marks hang from the bundle, so wherever
## it is the arms are bent to it.
## How far over it he bends to reach it on his knee, and how far once it's
## held; how long the kneel, the reach, the lift and the rise take (s).
const LIFT_LEAN := 0.8
const HOLD_LEAN := 0.3
## (11 November, Gary: "Have Bram pick up baby quicker": from the tap to
## stood with the child was 4.9 s, each part unhurried; every movement is
## the same and brisker, about 3.3 s: a man who's found a child crying in the
## snow doesn't take his time. The walk down to it is quicker too, DOWN_SECS.)
const KNEEL_SECS := 0.8
const REACH_SECS := 0.45
const LIFT_SECS := 0.8
const RISE_SECS := 0.95
## The look down into the crater before he goes down (s; was 2.2), the walk
## down the slope (was 5.4: 8 m at a stroll; now he hurries to it) and the
## beat before the prompt (was 0.6).
const REVEAL_SECS := 1.5
const DOWN_SECS := 4.0
const PROMPT_BEAT := 0.3
## Where it's held against the chest once gathered: in his own frame, off
## the chest bone (a little below and ahead of it, to his left side, where
## the left arm will cradle it).
const CRADLE := Vector3(0.07, -0.16, 0.2)
## Hands this near their marks (m, the hand bone to the mark: the palm is a
## few centimetres on) are on it.
const HANDS_ON := 0.13
## The wrists (8 November, Gary: "Bram's hands twist when he picks up the
## baby": the reach put each hand's place and left its turn to the arm's own
## solution, so the hands came down edge-on to the bundle's ends, the palms
## facing sideways and the fingers down its ends, and standing with it his
## right palm faced away from it). Now each hand is turned as it comes down
## (Figure3D.palm, HandTurn): the palm up and in towards the bundle's middle,
## at 45 degrees, under its end (LIFT_PALM), the fingers on under it towards
## the middle (LIFT_FINGERS), the hand a little cupped (LIFT_FLAT); held so
## through the lift and the rise, and given back to the clip at _tuck. The
## left hand's, in his own frame (x to his left, y up, z ahead); the right's
## is its mirror.
const LIFT_PALM := Vector3(-0.7, 0.7, 0.0)
const LIFT_FINGERS := Vector3(-0.75, -0.5, 0.2)
const LIFT_FLAT := 0.2
## Where the hands take it (the bundle's own frame: z along it, y up, the
## origin its middle): the middle of each palm on the lower, inner part of
## its end, 7 cm under the axis and 15 cm out from the middle (PALM_AT). The
## reach aims the forearm's line 7.5 cm past the wrist (Figure3D._reach),
## not the palm: with the hand turned, the palm's middle sits a hand's
## half-length on from the wrist along the fingers, so the mark each arm
## reaches for is set off from the palm's place by MARK_OFF (his way ahead,
## down, out along the bundle), where the forearm's line ends once the palm
## is on it.
const PALM_AT := Vector3(0.0, -0.07, 0.15)
const MARK_OFF := Vector3(0.04, -0.03, 0.03)
## (false leaves the wrists and elbows to the reach alone, and the marks
## where they were, 2 cm under the axis at the ends: the peek's before)
var turn_wrists := true
## Where the elbows bend towards while he reaches down and lifts (his own
## frame, scaled to his size): out to his sides and a little forward, low,
## as arms do reaching down in front of the knees (the usual hint, up and
## behind the shoulders, bent them back and swung the forearms in). The
## left's; the right's is its mirror.
const LIFT_ELBOW := Vector3(0.6, 0.5, 0.1)

func _lift_child() -> void:
	if not (_bram is Figure3D):
		_baby.reparent(_bram, false)
		_baby.position = Vector3(0, 1.1, 0.25)
		await _wait(0.8)
		return
	var fig := _bram as Figure3D
	# his hands' places on the bundle: under its head end and its feet
	var l := Node3D.new()
	var r := Node3D.new()
	_baby.add_child(l)
	_baby.add_child(r)
	# (one under each end, each hand to the end on its own side of him; the
	# marks where the forearms' lines end with the palms on it, PALM_AT and
	# MARK_OFF: until 8 November they were 2 cm under the axis at the ends,
	# which with the hands turned put the palms on top of the bundle)
	var end_a := Vector3(0.0, -0.02, 0.19)
	var end_b := Vector3(0.0, -0.02, -0.18)
	if turn_wrists:
		var inv := _baby.global_basis.orthonormalized().inverse()
		var fwd := inv * fig.facing()   # (his way ahead, in the bundle's frame)
		fwd.y = 0.0
		fwd = fwd.normalized()
		end_a = Vector3(0.0, PALM_AT.y + MARK_OFF.y, PALM_AT.z + MARK_OFF.z) + fwd * MARK_OFF.x
		end_b = Vector3(0.0, PALM_AT.y + MARK_OFF.y, -(PALM_AT.z + MARK_OFF.z)) + fwd * MARK_OFF.x
	var left_way := fig.to_world(Vector3(1, 0, 0)) - fig.to_world(Vector3.ZERO)
	if (_baby.global_basis * end_a).dot(left_way) < 0.0:
		var sw := end_a
		end_a = end_b
		end_b = sw
	l.position = end_a
	r.position = end_b
	# down on one knee and right over it, bent from the hips, the hands going
	# down to it
	var stoop := _stoop(fig)
	fig.kneel(KNEEL_SECS, LIFT_LEAN)
	if stoop != null:
		create_tween().tween_property(stoop, "amount", 1.0, KNEEL_SECS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _wait(KNEEL_SECS * 0.45)
	var mirror := Vector3(-1, 1, 1)
	var s := fig.stature()
	if turn_wrists:
		fig.elbow("left", LIFT_ELBOW * s, REACH_SECS)
		fig.elbow("right", LIFT_ELBOW * mirror * s, REACH_SECS)
	fig.reach(l, r, REACH_SECS)
	if turn_wrists:
		fig.palm("left", LIFT_PALM, REACH_SECS, LIFT_FLAT, true, LIFT_FINGERS)
		fig.palm("right", LIFT_PALM * mirror, REACH_SECS, LIFT_FLAT, true, LIFT_FINGERS * mirror)
	# the bundle doesn't move till both hands are under it (their places as
	# the skeleton finishes each frame, the reach included)
	# (and the chest bone's, which the bundle is carried by: read between
	# frames a bone has only the clip's pose, without the stoop)
	var sk := fig._skel
	var chest_bone := "Spine2" if sk != null and sk.find_bone("Spine2") >= 0 else "Spine1"
	var ci := sk.find_bone(chest_bone) if sk != null else -1
	var hands := [Vector3.INF, Vector3.INF]
	var chest_now := [null]
	var watch := func() -> void:
		if is_instance_valid(fig) and fig._skel != null:
			var sk0 := fig._skel
			hands[0] = sk0.global_transform * sk0.get_bone_global_pose(sk0.find_bone("LeftHand")).origin
			hands[1] = sk0.global_transform * sk0.get_bone_global_pose(sk0.find_bone("RightHand")).origin
			chest_now[0] = sk0.global_transform * sk0.get_bone_global_pose(ci)
	if sk != null:
		sk.skeleton_updated.connect(watch)
	var el := 0.0
	while el < KNEEL_SECS + REACH_SECS + 1.0 and not _skipping:
		await get_tree().process_frame
		el += get_process_delta_time()
		lift_gaps = [(hands[0] as Vector3).distance_to(l.global_position), (hands[1] as Vector3).distance_to(r.global_position)]
		lift_gap = maxf(lift_gaps[0], lift_gaps[1])
		if el > KNEEL_SECS * 0.55 + REACH_SECS and lift_gap < HANDS_ON:
			break
	await _wait(0.1)   # (a breath, his hands under it)
	if _skipping:
		if sk != null and sk.skeleton_updated.is_connected(watch):
			sk.skeleton_updated.disconnect(watch)
		return
	if _cry != null:
		var ct := create_tween()
		ct.tween_property(_cry, "volume_db", -40.0, 2.0)
		ct.tween_callback(_cry.stop)
	# the camera rises from its low place behind his shoulder to high over it
	# as he lifts the child and stands, so the bundle coming in to his chest
	# is seen over his shoulder instead of lost behind his back
	var cam_to: Array = _held_shot()
	_drift(_cam_pos, cam_to[0], _cam_look, cam_to[1], LIFT_SECS + RISE_SECS + 0.3)
	var chest_xf := func() -> Transform3D:
		if chest_now[0] != null:
			return chest_now[0]
		return sk.global_transform * sk.get_bone_global_pose(ci)
	# where the bundle is in his hands, off his chest bone as it is now
	var in_hands: Transform3D = (chest_xf.call() as Transform3D).affine_inverse() * _baby.global_transform
	# across his chest, the end his left hand holds to his left (8 November:
	# it was always turned the one way, so coming at the child from the way
	# he walks the carry swung it half round in his hands, his arms crossed
	# as he rose and he stood with his right elbow across his chest)
	var b1 := Basis(Vector3.UP, PI * 0.5 if l.position.z > 0.0 else -PI * 0.5)
	# the held place against his chest, in the world (his own frame turned)
	var cradle_xf := func() -> Transform3D:
		var at := fig.to_world(fig.to_own((chest_xf.call() as Transform3D).origin) + CRADLE)
		return Transform3D(fig.global_basis * Basis(Vector3.UP, fig._yaw) * b1, at)
	var gather := [0.0]   # (how far it's drawn in, 0..1; an array so the lambda shares it)
	var carry := func() -> void:
		if not is_instance_valid(_baby) or not is_instance_valid(fig):
			return
		var held: Transform3D = (chest_xf.call() as Transform3D) * in_hands
		var k := smoothstep(0.0, 1.0, float(gather[0]))
		_baby.global_transform = held.interpolate_with(cradle_xf.call(), k)
	# up in his hands as his back comes up, drawn in to his chest as it comes
	fig.kneel(LIFT_SECS, HOLD_LEAN)
	if stoop != null:
		create_tween().tween_property(stoop, "amount", 0.0, LIFT_SECS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	el = 0.0
	while el < LIFT_SECS + 0.15 and not _skipping:
		await get_tree().process_frame
		el += get_process_delta_time()
		gather[0] = clampf((el / LIFT_SECS - 0.15) / 0.85, 0.0, 1.0)
		carry.call()
	if _skipping:
		if sk != null and sk.skeleton_updated.is_connected(watch):
			sk.skeleton_updated.disconnect(watch)
		return
	# and up off his knee with it held there
	gather[0] = 1.0
	fig.rise(RISE_SECS)
	el = 0.0
	while el < RISE_SECS + 0.2 and not _skipping:
		await get_tree().process_frame
		el += get_process_delta_time()
		carry.call()
	# carried in his own frame from here (where _tuck starts from), so it
	# turns with him
	_baby.reparent(fig._pivot, true)
	_baby.position = fig.to_own((chest_xf.call() as Transform3D).origin) + CRADLE
	_baby.basis = b1
	if sk != null and sk.skeleton_updated.is_connected(watch):
		sk.skeleton_updated.disconnect(watch)


## The bend from the hips over the child (Stoop), degrees about each bone
## at its full: the small of the back over, a little more above it, the
## neck back so he looks at the child rather than into his chest.
const STOOP := {"Spine": Vector3(55, 0, 0), "Spine1": Vector3(10, 0, 0), "Neck": Vector3(-20, 0, 0)}

func _stoop(fig: Figure3D) -> Stoop:
	var sk := fig._skel
	if sk == null:
		return null
	if sk.has_node("Stoop"):
		return sk.get_node("Stoop") as Stoop
	var st := Stoop.new()
	st.name = "Stoop"
	for bone: String in STOOP:
		var i := sk.find_bone(bone)
		if i >= 0:
			var e: Vector3 = STOOP[bone]
			st.turns.append([i, Quaternion.from_euler(Vector3(deg_to_rad(e.x), deg_to_rad(e.y), deg_to_rad(e.z)))])
	sk.add_child(st)
	# after the posture, before the hands reach
	var at := 1 if sk.has_node("Posture") else 0
	for c in sk.get_children():
		if c is TwoBoneIK3D or c.name == "HandTurn" or c.name == "HandsOff":
			at = mini(at, c.get_index())
	sk.move_child(st, at)
	return st


## How far the farther hand was from its mark on the bundle when it was
## lifted (m; tests read it).
var lift_gap := INF
var lift_gaps := [INF, INF]


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
		# the wrists and the elbows' hints back to the clip's (the lift's turn
		# of them, LIFT_PALM, LIFT_ELBOW, ends here)
		fig.palm("left", Vector3.ZERO, 0.4)
		fig.palm("right", Vector3.ZERO, 0.4)
		fig.elbow("left", Vector3.INF, 0.4)
		fig.elbow("right", Vector3.INF, 0.4)
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
	var mi := _streak_mesh(col)
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
	var sp := _impact_sparks(col)
	sp.position = at + Vector3(0, 0.2, 0)
	_set.add_child(sp)
	sp.emitting = true
	get_tree().create_timer(2.0, false).timeout.connect(sp.queue_free)
	var card := _card_mesh(col)
	card.position = at
	_set.add_child(card)
	_card_lands(card, col)
	_play_strike()


## The streak of a Sigil falling out of the tear: a camera-facing ribbon in
## the streak shader (one material for all of them: the colour and the
## brightness are instance uniforms; until 8 November each strike made its
## own).
static var _streak: ShaderMaterial

static func _streak_mesh(col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = QuadMesh.new()
	if _streak == null:
		_streak = ShaderMaterial.new()
		_streak.shader = load("res://assets/shaders/village/streak.gdshader")
	mi.material_override = _streak
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_instance_shader_parameter("col", col)
	mi.set_instance_shader_parameter("intensity", 7.0)
	return mi


## The sparks thrown up where a Sigil strikes the snow (not yet emitting).
func _impact_sparks(col: Color) -> GPUParticles3D:
	var sp := GPUParticles3D.new()
	sp.amount = [20, 40, 70][clampi(quality, 0, 2)]
	sp.lifetime = 1.1
	sp.one_shot = true
	sp.explosiveness = 0.95
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
	qm.disable_fog = true   # (fog added over an added quad lights its whole square)
	qm.albedo_texture = _soft_dot()
	qm.vertex_color_use_as_albedo = true
	q.material = qm
	q.size = Vector2(0.6, 0.6)
	sp.draw_pass_1 = q
	return sp


const STRIKE_SFX := "res://assets/sfx/sigil_strike.ogg"

func _play_strike() -> void:
	var p := STRIKE_SFX
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


## A Sigil: a card of light, a little bigger than a hand, with its back's
## painting on it and its colour burning through (4 November, Gary: the
## bits on the ground "look like confetti": they were a hand's size, lying
## flat, with no light of their own on the snow; now each stands tilted in
## the snow where it lands, glowing, with a pool of its light under it).
##
## 6 November (Gary: "...and the cards look much better"): each is a real card
## now (sigil_card): rounded corners and a thickness, the game's own card
## back on one face and on the other a painting from the cards of its
## colour in a frame, a rune ring burning over it in the Sigil's colour,
## pulsing; a line of that light round the edge of both faces and along the
## card's thin edge, so it blooms in the night. As it falls it flutters down
## like a leaf (_process), a ribbon of its light streaming behind it
## (TRAIL) and, on a Mac, a few sparks shed off it.
func _card_mesh(col: Color) -> MeshInstance3D:
	return sigil_card(col)


## Card paintings by Sigil colour (SIGIL_COLS' order), for the card's face.
const CARD_FACES := ["blazehound", "cinderpup", "gilded_sentinel", "riptide_serpent", "somnowl", "crystal_vein", "elderbark", "lantern_moth"]
const CARD_SIZE := Vector2(0.3, 0.42)
static var _card_shape: ArrayMesh
static var _card_mats := {}
## One Shader each for the cards and their pools, shared by every colour's
## material (8 November: each colour made its own copy of the same code, so
## the renderer compiled the card shader eight times over and the pool's
## eight more, one each time a new colour first fell, in the seconds after
## Morrowen's line).
static var _card_shader: Shader
static var _pool_shader: Shader


static func _shared_shader(which: String) -> Shader:
	if which == "card":
		if _card_shader == null:
			_card_shader = Shader.new()
			_card_shader.code = CARD
		return _card_shader
	if _pool_shader == null:
		_pool_shader = Shader.new()
		_pool_shader.code = POOL
	return _pool_shader


## A Sigil card of light in `col` (shared mesh; one material per colour).
static func sigil_card(col: Color, face := "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _card_shape_mesh()
	var key := col.to_html() + face
	if not _card_mats.has(key):
		var m := ShaderMaterial.new()
		m.shader = _shared_shader("card")
		m.set_shader_parameter("col", col)
		m.set_shader_parameter("back_tex", DuelArt.card_back())
		var i := SIGIL_COLS.find(col)
		var fid: String = face if face != "" else (CARD_FACES[i] if i >= 0 else "")
		var fp := "res://assets/art/cards/%s.jpg" % fid
		if fid != "" and ResourceLoader.exists(fp):
			m.set_shader_parameter("face_tex", load(fp))
			m.set_shader_parameter("has_face", 1.0)
		var rp := "res://assets/art/fx/rune_ring.png"
		if ResourceLoader.exists(rp):
			m.set_shader_parameter("rune_tex", load(rp))
		_card_mats[key] = m
	mi.material_override = _card_mats[key]
	mi.set_instance_shader_parameter("phase", randf() * 10.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## The card's shape: a rounded rectangle CARD_SIZE, 6 mm thick. COLOR.r says
## which part: 1 the face, 0 the back, 0.5 the edge; UV across each face.
static func _card_shape_mesh() -> ArrayMesh:
	if _card_shape != null:
		return _card_shape
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var w := CARD_SIZE.x * 0.5
	var h := CARD_SIZE.y * 0.5
	var rc := 0.022
	var th := 0.003
	# the outline, round the corners
	var ring: Array = []
	var corners := [Vector2(w - rc, h - rc), Vector2(-w + rc, h - rc), Vector2(-w + rc, -h + rc), Vector2(w - rc, -h + rc)]
	for ci in 4:
		for k in 5:
			var a := PI * 0.5 * ci + PI * 0.5 * float(k) / 4.0
			ring.append((corners[ci] as Vector2) + Vector2(cos(a), sin(a)) * rc)
	var uv_of := func(p: Vector2, flip: bool) -> Vector2:
		var u := (p.x + w) / (2.0 * w)
		return Vector2(1.0 - u if flip else u, 1.0 - (p.y + h) / (2.0 * h))
	for side in [1.0, -1.0]:
		var z: float = th * side
		var nrm := Vector3(0, 0, side)
		var face_col := Color(1.0 if side > 0.0 else 0.0, 0, 0)
		for i in ring.size():
			var p0: Vector2 = ring[i]
			var p1: Vector2 = ring[(i + 1) % ring.size()]
			# a fan from the middle; wound clockwise as seen from its side
			var tri := [Vector2.ZERO, p1, p0] if side > 0.0 else [Vector2.ZERO, p0, p1]
			for p: Vector2 in tri:
				st.set_color(face_col)
				st.set_normal(nrm)
				st.set_uv(uv_of.call(p, side < 0.0))
				st.add_vertex(Vector3(p.x, p.y, z))
	for i in ring.size():
		var p0: Vector2 = ring[i]
		var p1: Vector2 = ring[(i + 1) % ring.size()]
		var mid := (p0 + p1) * 0.5
		var nrm := Vector3(mid.x, mid.y, 0).normalized()
		var q := [Vector3(p0.x, p0.y, th), Vector3(p0.x, p0.y, -th), Vector3(p1.x, p1.y, -th),
			Vector3(p0.x, p0.y, th), Vector3(p1.x, p1.y, -th), Vector3(p1.x, p1.y, th)]
		# (wound to face out; checked against the normal)
		var flip := ((q[1] as Vector3) - (q[0] as Vector3)).cross((q[2] as Vector3) - (q[0] as Vector3)).dot(nrm) > 0.0
		for t in 2:
			var tri: Array = [q[t * 3], q[t * 3 + 2], q[t * 3 + 1]] if flip else [q[t * 3], q[t * 3 + 1], q[t * 3 + 2]]
			for p: Vector3 in tri:
				st.set_color(Color(0.5, 0, 0))
				st.set_normal(nrm)
				st.set_uv(Vector2(0.5, 0.5))
				st.add_vertex(p)
	_card_shape = st.commit()
	return _card_shape


## A card stood in the snow where it fell: leaning, a little way in, with a
## pool of its light on the snow about it. The oldest go when there are too
## many.
func _card_lands(c: MeshInstance3D, col: Color) -> void:
	var at := c.position
	at.y = height(at.x, at.z)
	c.position = at + Vector3(0, 0.14, 0)
	c.rotation = Vector3(_rng.randf_range(-0.5, -0.2), _rng.randf() * TAU, _rng.randf_range(-0.25, 0.25))
	# it glows down a little once it's still (and flares as it lands)
	var heat := create_tween()
	heat.tween_method(func(k: float) -> void:
		if is_instance_valid(c):
			c.set_instance_shader_parameter("heat", k), 1.6, 0.8, 0.9).set_trans(Tween.TRANS_SINE)
	var pool := _pool_mesh(col)
	# laid on the slope of the snow, a little over it (flat, its far side
	# went under a drift and cut it off along a line)
	var e := 0.3
	var nrm := Vector3(height(at.x - e, at.z) - height(at.x + e, at.z), 2.0 * e, height(at.x, at.z - e) - height(at.x, at.z + e)).normalized()
	var side := nrm.cross(Vector3.BACK).normalized()
	pool.basis = Basis(side, nrm.cross(side), nrm)
	pool.position = at + nrm * 0.07
	pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_set.add_child(pool)
	_landed.append([c, pool])
	var most: int = [18, 30, 44][clampi(quality, 0, 2)]
	while _landed.size() > most:
		var old: Array = _landed.pop_front()
		for n in old:
			if is_instance_valid(n):
				(n as Node).queue_free()


## A pool of a card's light for the snow: a quad in the POOL shader, one
## material a colour (6 November: drawn round in its own shader: the
## soft-dot texture left the whole square faintly lit on the Compatibility
## renderer).
static func _pool_mesh(col: Color) -> MeshInstance3D:
	var pool := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(1.3, 1.3)
	pool.mesh = qm
	var key := "pool" + col.to_html()
	if not _card_mats.has(key):
		var pmat := ShaderMaterial.new()
		pmat.shader = _shared_shader("pool")
		pmat.set_shader_parameter("col", col * 0.45)
		_card_mats[key] = pmat
	pool.material_override = _card_mats[key]
	pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return pool


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
	if _ring != null:
		_place_ring()
	if _roam:
		_roam_step(delta)
	if _cam_mode == "roam":
		# behind him, over his right shoulder, the camera's heading easing
		# round to his as he turns; with _sky_look up, its eyes lifted to the
		# tear over him (a touch lower and further back, the lens wider), him
		# still in the foot of the picture
		var p := _bram.position
		var h := _heading()
		var want_yaw := atan2(h.x, h.z)
		_cam_yaw = lerp_angle(_cam_yaw, want_yaw, minf(1.0, delta * 2.6))
		var f := Vector3(sin(_cam_yaw), 0, cos(_cam_yaw))
		var r := f.cross(Vector3.UP)
		var up := smoothstep(0.0, 1.0, _sky_look)
		_cam_want = p - f * (2.9 + 0.7 * up) + r * 0.75 + Vector3(0, 1.85 - 0.45 * up, 0)
		# (the tear stands 20 to 40 degrees up the sky: tilted 25 degrees the
		# wider lens holds the tear and him both)
		_look_want = (p + f * 7.0 + Vector3(0, 1.35, 0)).lerp(p + f * 9.0 + Vector3(0, 5.5, 0), up)
		# drawn off towards what's glimpsed in the snow (_glimpse), him kept
		# in the picture
		if _glimpse_look > 0.001 and _glimpse_at != Vector3.INF:
			_look_want = _look_want.lerp(_glimpse_at, smoothstep(0.0, 1.0, _glimpse_look) * GLIMPSE_EYES)
		_cam.fov = 50.0 + 10.0 * up
	if _cam_mode == "follow" or _cam_mode == "roam":
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
			_rain_next = _t + _rng.randf_range(0.5, 1.1)
	for i in range(_falling.size() - 1, -1, -1):
		var f: Array = _falling[i]
		var n: Node3D = f[0]
		if not is_instance_valid(n):
			_falling.remove_at(i)
			continue
		_flutter(f, delta)
		if n.position.y <= height(n.position.x, n.position.z) + 0.1:
			_falling.remove_at(i)
			_end_trail(f)
			_card_lands(n as MeshInstance3D, f[3])
	# the crater breathes its light
	if _crater_light != null:
		_crater_light.light_energy = (2.4 + sin(_t * 1.7) * 0.35 + sin(_t * 4.1) * 0.12) * _crater_k
	if _ground_mat != null:
		_ground_mat.set_shader_parameter("glow", (0.6 + sin(_t * 1.7) * 0.1) * lerpf(0.4, 1.0, _crater_k))


## His walking, a frame of it: the pad or the keys (the way the camera
## looks is up), or on towards where the snow was tapped; kept out of the
## glass and within ROAM_R of the crater; his feet matched to the ground.
func _roam_step(delta: float) -> void:
	var v := Vector2.ZERO
	if _pad != null:
		v = _pad.vector
	var k := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if k.length() > v.length():
		v = k
	var dir := Vector3.ZERO
	if v.length() > 0.15:
		_move_target = Vector3.INF
		var f := Vector3(sin(_cam_yaw), 0, cos(_cam_yaw))
		var r := f.cross(Vector3.UP)
		dir = r * v.x - f * v.y
		if dir.length() > 1.0:
			dir = dir.normalized()
	elif _move_target != Vector3.INF:
		var to := _move_target - _flat
		to.y = 0.0
		if to.length() < 0.15:
			_move_target = Vector3.INF
		else:
			dir = to.normalized()
	var speed := dir.length() * WALK_SPEED
	if speed > 0.05:
		_hide_hint()
		var nf := _flat + dir.normalized() * speed * delta
		# round the glass
		for sp in _spires:
			var d := Vector2(nf.x - float(sp[0]), nf.z - float(sp[1]))
			var rr := float(sp[2])
			if d.length() < rr and d.length() > 0.001:
				var out := d.normalized() * rr
				nf.x = float(sp[0]) + out.x
				nf.z = float(sp[1]) + out.y
		# and not away over the Shardlands
		var from_c := Vector2(nf.x - CRATER.x, nf.z - CRATER.z)
		if from_c.length() > ROAM_R:
			from_c = from_c.normalized() * ROAM_R
			nf.x = CRATER.x + from_c.x
			nf.z = CRATER.z + from_c.y
		if Vector2(nf.x - _flat.x, nf.z - _flat.z).length() < 0.0005:
			speed = 0.0
			_move_target = Vector3.INF
		_flat = Vector3(nf.x, 0.0, nf.z)
		_bram.position = Vector3(_flat.x, height(_flat.x, _flat.z), _flat.z)
		if _bram is PaperDoll:
			(_bram as PaperDoll).face(dir, _cam)
	_set_walking(_bram, speed > 0.05)
	# his look up at the tear (standing as the sky opened) gives way to the
	# walk the moment he sets off (8 November: a clip played with act() holds
	# until it ends, so he slid over the snow in the look-up pose for its
	# length before his legs began)
	if speed > 0.05 and _bram is Figure3D and (_bram as Figure3D)._action == "look_up":
		(_bram as Figure3D).release(0.3)
	if _bram is Figure3D:
		(_bram as Figure3D).pace = speed


## One card of light drifting down near him, tumbling.
func _drop_card() -> void:
	if not is_instance_valid(_bram) or _bram.get_parent() != _set:
		return
	var col: Color = SIGIL_COLS[_rng.randi() % SIGIL_COLS.size()]
	var f := _heading()
	# where it starts and how it falls; never to land on the child or at his
	# feet (6 November: one stood up against the bundle as he knelt to it)
	var start := Vector3.INF
	var vel := Vector3.ZERO
	for k in 6:
		var around := _bram.position + f * _rng.randf_range(-3, 12) + f.cross(Vector3.UP) * _rng.randf_range(-7, 7)
		var p := around + Vector3(0, _rng.randf_range(7, 11), 0)
		var v := Vector3(_rng.randf_range(-1.2, -0.4), -_rng.randf_range(1.1, 1.8), _rng.randf_range(-0.2, 0.4))
		var land := p
		for it in 2:   # (the snow's height where it comes down, not where it starts)
			land = p + v * ((p.y - height(land.x, land.z)) / -v.y)
		if Vector2(land.x - CRATER.x, land.z - CRATER.z).length() > CARD_CLEAR_CHILD \
				and Vector2(land.x - _bram.position.x, land.z - _bram.position.z).length() > CARD_CLEAR_HIM:
			start = p
			vel = v
			break
	if start == Vector3.INF:
		return
	var c := _card_mesh(col)
	c.position = start
	_set.add_child(c)
	# its ribbon of light behind it, and on a Mac a few sparks shed off it
	var trail := _trail_mesh(col)
	trail.visible = false
	_set.add_child(trail)
	var sparks: GPUParticles3D = null
	if quality >= 1:
		sparks = _card_sparks(col)
		c.add_child(sparks)
	# [card, velocity, spin, colour, trail, phase, sparks, heading, last position]
	_falling.append([c, vel, _rng.randf_range(-1.0, 1.0), col, trail, _rng.randf() * TAU, sparks, _rng.randf() * TAU, c.position])
	# (they stand where they land, and go with the set)


## How far from the child, and from him, a falling card may come down (m).
const CARD_CLEAR_CHILD := 3.0
const CARD_CLEAR_HIM := 1.4

## How a card falls (6 November): like a leaf, not a tumbling brick: lying
## mostly flat to the air, rocking from side to side and gliding a little
## each way as it rocks, turning slowly; its ribbon of light streams back
## along the way it has really come.
const TRAIL_LEN := 0.55      # seconds of its path the ribbon covers
const TRAIL_GLOW := 2.2

func _flutter(f: Array, delta: float) -> void:
	var n: Node3D = f[0]
	var t := _t + float(f[5])
	var spin := float(f[2])
	var yaw := float(f[7]) + t * spin * 0.35
	var rock := sin(t * 2.3)
	var side := Vector3(cos(yaw), 0.0, -sin(yaw))
	var last: Vector3 = f[8]
	n.position += (f[1] as Vector3) * delta + side * cos(t * 2.3) * 0.75 * delta
	n.basis = Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, -1.25 + 0.2 * sin(t * 1.3)) * Basis(Vector3.BACK, rock * 0.55)
	var moved := n.position - last
	f[8] = n.position
	var trail := f[4] as MeshInstance3D
	if is_instance_valid(trail) and delta > 0.0 and moved.length() > 0.0001:
		var v := moved / delta
		var dir := v.normalized()
		var length := clampf(v.length() * TRAIL_LEN, 0.3, 1.2)
		trail.transform = Transform3D(Basis(Vector3(1.3, 0, 0), -dir * length, Vector3(0, 0, 1)), n.position - dir * length * 0.5)
		trail.visible = true


## A card has landed: its ribbon goes out, its sparks stop and go.
func _end_trail(f: Array) -> void:
	var trail := f[4] as MeshInstance3D
	if is_instance_valid(trail):
		var tw := create_tween()
		tw.tween_method(func(k: float) -> void:
			if is_instance_valid(trail):
				trail.set_instance_shader_parameter("intensity", k), TRAIL_GLOW, 0.0, 0.25)
		tw.tween_callback(trail.queue_free)
	var sp = f[6]
	if sp != null and is_instance_valid(sp):
		(sp as GPUParticles3D).emitting = false
		get_tree().create_timer(1.2, false).timeout.connect((sp as Node).queue_free)


static var _trail: ShaderMaterial

static func _trail_mat() -> ShaderMaterial:
	if _trail == null:
		_trail = ShaderMaterial.new()
		_trail.shader = load("res://assets/shaders/village/streak.gdshader")
		_trail.set_shader_parameter("width", 0.07)
	return _trail


## A falling card's ribbon of light, in `col` (laid along its path by _flutter).
static func _trail_mesh(col: Color) -> MeshInstance3D:
	var trail := MeshInstance3D.new()
	trail.mesh = QuadMesh.new()
	trail.material_override = _trail_mat()
	trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	trail.set_instance_shader_parameter("col", col)
	trail.set_instance_shader_parameter("intensity", TRAIL_GLOW)
	return trail


## A few sparks of its colour shed off a falling card, left behind in the air.
func _card_sparks(col: Color) -> GPUParticles3D:
	var key := "sparks" + col.to_html()
	if not _card_mats.has(key):
		var pm := ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = Vector3(0.15, 0.2, 0.01)
		pm.direction = Vector3.UP
		pm.spread = 180.0
		pm.initial_velocity_min = 0.05
		pm.initial_velocity_max = 0.3
		pm.gravity = Vector3(0, -0.25, 0)
		pm.scale_min = 0.5
		pm.scale_max = 1.0
		pm.color = col.lerp(Color.WHITE, 0.3)
		var cr := Curve.new()
		cr.add_point(Vector2(0, 1.0))
		cr.add_point(Vector2(1, 0.0))
		var ct := CurveTexture.new()
		ct.curve = cr
		pm.scale_curve = ct
		var q := QuadMesh.new()
		q.size = Vector2(0.07, 0.07)
		var qm := StandardMaterial3D.new()
		qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		qm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		qm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		qm.disable_fog = true   # (fog added over an added quad lights its whole square)
		qm.albedo_texture = _soft_dot()
		qm.vertex_color_use_as_albedo = true
		qm.albedo_color = Color(2.0, 2.0, 2.0)
		q.material = qm
		_card_mats[key] = [pm, q]
	var pair: Array = _card_mats[key]
	var p := GPUParticles3D.new()
	p.amount = 10 if quality < 2 else 16
	p.lifetime = 1.0
	p.local_coords = false
	p.process_material = pair[0]
	p.draw_pass_1 = pair[1]
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-4, -4, -4), Vector3(8, 8, 8))
	return p


# ================================================================== input ===

func _input(e: InputEvent) -> void:
	if _done:
		return
	if e is InputEventScreenTouch:
		_held = (e as InputEventScreenTouch).pressed
		if _held:
			_tapped = true
			_tap_at = (e as InputEventScreenTouch).position
		_last_input = ""
	elif e is InputEventMouseButton and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_held = (e as InputEventMouseButton).pressed
		if _held:
			_tapped = true
			_tap_at = (e as InputEventMouseButton).position
		_last_input = ""
	elif e is InputEventJoypadButton or e is InputEventJoypadMotion:
		if (e is InputEventJoypadMotion and absf((e as InputEventJoypadMotion).axis_value) > 0.4) or e is InputEventJoypadButton:
			_last_input = "pad"
	elif e is InputEventKey and (e as InputEventKey).pressed:
		_last_input = "keys"
	if e.is_action_pressed("interact"):
		_tapped = true
		if not (e is InputEventScreenTouch or e is InputEventMouseButton):
			_tap_at = Vector2.INF   # (a key or a button: no place)


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
// the wind's ripples: noise stretched along the way it blows
float ripple(vec2 p) {
	vec2 w = vec2(p.x * 0.35 - p.y * 0.12, p.x * 0.12 + p.y * 0.35);
	return fbm(vec2(w.x * 0.9, w.y * 6.0));
}
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float n = fbm(wp.xz * 0.3);
	float fine = fbm(wp.xz * 3.1);
	float rp = ripple(wp.xz);
	vec3 snow = mix(vec3(0.5, 0.55, 0.68), vec3(0.82, 0.86, 0.94), n * 0.6 + fine * 0.25 + rp * 0.15);
	float d = length(wp.xz - crater.xz);
	// the drifts' and ripples' own shape in the light: a normal from the
	// slope of the noise, in place of the flat mesh's
	float eps = 0.35;
	float hx = (fbm((wp.xz + vec2(eps, 0.0)) * 0.3) - fbm((wp.xz - vec2(eps, 0.0)) * 0.3)) * 1.2
		+ (ripple(wp.xz + vec2(eps, 0.0)) - ripple(wp.xz - vec2(eps, 0.0))) * 0.5;
	float hz = (fbm((wp.xz + vec2(0.0, eps)) * 0.3) - fbm((wp.xz - vec2(0.0, eps)) * 0.3)) * 1.2
		+ (ripple(wp.xz + vec2(0.0, eps)) - ripple(wp.xz - vec2(0.0, eps))) * 0.5;
	vec3 wn = normalize(vec3(-hx, 1.0, -hz));
	NORMAL = normalize(mix(NORMAL, (VIEW_MATRIX * vec4(wn, 0.0)).xyz, 0.7));
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


## A pool of a card's light on the snow: round, soft, nothing at its edge.
const POOL := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, fog_disabled, shadows_disabled, cull_disabled;
uniform vec4 col : source_color = vec4(0.4, 0.3, 0.1, 1.0);
void fragment() {
	float d = clamp(length(UV - 0.5) * 2.0, 0.0, 1.0);
	float k = (1.0 - d) * (1.0 - d);
	ALBEDO = col.rgb * k;
}
"""


## A Sigil card (sigil_card): the face (COLOR.r 1) a painting in a frame of
## gold gone over to its colour, the rune ring burning over it and pulsing;
## the back (0) the game's card back, its gold lit in the colour; the thin
## edge (0.5) all light; a line of light round both faces. `heat` 1 as it
## falls, less once it stands in the snow.
const CARD := """
shader_type spatial;
render_mode cull_back, specular_schlick_ggx;
uniform vec4 col : source_color = vec4(1.0, 0.6, 0.2, 1.0);
uniform sampler2D back_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D face_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D rune_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform float has_face = 0.0;
instance uniform float phase = 0.0;
instance uniform float heat = 1.0;
void fragment() {
	float part = COLOR.r;
	vec2 uv = UV;
	vec2 m = min(uv, 1.0 - uv) * vec2(0.3, 0.42);
	float edge = min(m.x, m.y);                       // to the card's edge (m)
	float line = 1.0 - smoothstep(0.0, 0.01, edge);
	float pulse = 0.72 + 0.28 * sin(TIME * 2.4 + phase);
	vec3 c = col.rgb;
	vec3 alb;
	vec3 em;
	if (part > 0.75) {
		vec2 auv = (uv - vec2(0.075, 0.06)) / vec2(0.85, 0.88);
		float win = step(0.0, auv.x) * step(auv.x, 1.0) * step(0.0, auv.y) * step(auv.y, 1.0);
		vec3 art = texture(face_tex, clamp(auv, 0.0, 1.0)).rgb;
		vec3 field = mix(vec3(0.04, 0.035, 0.07), art * 0.8, has_face);
		vec3 frame = mix(vec3(0.62, 0.46, 0.18), c, 0.4);
		alb = mix(frame, field, win);
		vec2 ruv = vec2((uv.x - 0.5) * 0.3, (uv.y - 0.56) * 0.42) / 0.25 + 0.5;
		vec4 rt = texture(rune_tex, clamp(ruv, 0.0, 1.0));
		float rune = rt.a * max(rt.r, max(rt.g, rt.b)) * step(abs(ruv.x - 0.5), 0.5) * step(abs(ruv.y - 0.5), 0.5);
		em = c * rune * 2.4 * pulse + field * win * 0.35 + frame * (1.0 - win) * 0.6 * c;
	} else if (part > 0.25) {
		alb = c;
		em = c * 2.4;
	} else {
		vec3 b = texture(back_tex, uv).rgb;
		alb = b * 0.6;
		em = b * mix(vec3(1.0), c * 1.4, 0.6) * (0.45 + 0.2 * pulse);
	}
	em += c * line * 2.6;
	ALBEDO = alb;
	ROUGHNESS = 0.32;
	SPECULAR = 0.6;
	EMISSION = em * heat;
}
"""


## The Shardlands' ice (6 November; until then near-black glass cones):
## deep blue ice that's looked into. Under the polished facets (the moon's
## and the tear's glints in them) the view goes on into it, bent as ice bends
## it, and ICE_LAYERS layers of it are seen at depth, each fainter: the ice's
## own blue, and thin bright cracks and veins of white light drifting slowly
## inside. The facets' edges catch the light; a fresnel rim of the sky's
## blue at the silhouette; the points brighter, the light gathering in them;
## frost on upward faces and snow drifted up the foot. Opaque, so it costs
## the same on every renderer (the Compatibility one included) and sorts.
const ICE := """
shader_type spatial;
render_mode specular_schlick_ggx, cull_back;
instance uniform float seed = 0.0;
instance uniform float glow = 1.0;
uniform vec3 deep : source_color = vec3(0.025, 0.065, 0.12);
uniform vec3 ice : source_color = vec3(0.22, 0.5, 0.85);
uniform vec3 vein : source_color = vec3(0.75, 0.9, 1.0);
uniform vec3 rim_col : source_color = vec3(0.45, 0.7, 1.0);
uniform float inner_k = 1.0;
uniform float frost_k = 1.0;
varying vec3 wp;
varying vec3 lp;
float h3(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float n3(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h3(i), h3(i + vec3(1, 0, 0)), f.x), mix(h3(i + vec3(0, 1, 0)), h3(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(h3(i + vec3(0, 0, 1)), h3(i + vec3(1, 0, 1)), f.x), mix(h3(i + vec3(0, 1, 1)), h3(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; lp = VERTEX; }
void fragment() {
	vec3 nw = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 vw = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
	float ndv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fres = pow(1.0 - ndv, 3.0);
	// into the ice, bent at the face, and in the crystal's own frame so the
	// veins stay put as the camera moves
	vec3 rd = refract(-vw, nw, 0.77);
	vec3 inside = vec3(0.0);
	float s = seed + UV2.x * 7.0;
	// two planes of fracture, turned by the crystal's own random
	vec3 n1 = normalize(vec3(0.9, 0.35 + 0.3 * sin(s), 0.25 + 0.3 * cos(s * 1.7)));
	vec3 n2 = normalize(vec3(-0.3 + 0.4 * cos(s * 2.3), 0.85, 0.4 * sin(s * 3.1)));
	for (int i = 0; i < ICE_LAYERS; i++) {
		float d = 0.1 + 0.28 * float(i);
		vec3 p = lp * 1.2 + rd * d + vec3(s, s * 0.7, -s);
		float cloud = n3(p * 2.2 - vec3(0.0, TIME * 0.04, 0.0));
		// thin bright sheets where the ice has cracked, here and there
		float fr = pow(1.0 - abs(sin(dot(p, n1) * 2.7 + n3(p * 1.7) * 0.9)), 40.0) * smoothstep(0.45, 0.75, n3(p * 0.9 + 9.0));
		fr += pow(1.0 - abs(sin(dot(p, n2) * 1.7 + n3(p * 1.3 + 4.0) * 0.9)), 40.0) * smoothstep(0.5, 0.8, n3(p * 0.7 + 21.0));
		// motes of light caught in it (round, one in a few cells)
		vec3 cell = floor(p * 11.0);
		float mote = step(0.985, h3(cell)) * smoothstep(0.22, 0.05, length(fract(p * 11.0) - 0.5))
			* (0.6 + 0.4 * sin(TIME * 2.0 + h3(cell + 3.0) * 30.0));
		inside += (ice * (0.3 + 0.55 * cloud) + vein * (fr * 1.3 + mote * 1.6)) * exp(-d * 1.4);
	}
	// the points gather the light
	float tip = smoothstep(0.55, 1.0, UV.y);
	// how near a facet's edge: across the face, and the ring where the point begins
	float half_w = 0.5 * max(UV2.y, 0.001);
	float edge = min(half_w - abs(UV.x - 0.5), 0.5) / max(UV2.y, 0.05);
	float e = 1.0 - smoothstep(0.0, 0.06, edge);
	// frost on the upward faces and snow up the foot
	float upf = clamp(nw.y, 0.0, 1.0);
	float frost = frost_k * smoothstep(0.45, 0.85, upf) * smoothstep(0.4, 0.8, n3(wp * 5.0));
	float foot = frost_k * (1.0 - smoothstep(0.0, 0.18 + 0.2 * n3(wp * 2.5), lp.y));
	frost = max(frost, foot);
	ALBEDO = mix(deep, vec3(0.8, 0.85, 0.93), frost);
	ROUGHNESS = mix(0.04, 0.75, frost);
	METALLIC = 0.0;
	SPECULAR = mix(0.9, 0.3, frost);
	vec3 em = inside * inner_k * glow * (0.55 + 0.45 * ndv);
	em += rim_col * fres * 0.9;
	em += vein * e * (0.35 + 0.65 * tip) * 0.9;
	em += vein * tip * tip * 0.35 * glow;
	EMISSION = em * (1.0 - frost * 0.85);
}
"""


# ================================================================== stoop ===

## One of Bram's cards as the player sees it in the snow: its painting in a
## plain frame, no name, cost or numbers (a card with no painting yet: its
## element's colours and sign, CardFace.draw_art). `lit`: the one to play,
## a light round it that breathes.
class PlayCard:
	extends Control
	var id := ""
	var element := ""
	var lit := false
	var _t := 0.0
	const RADIUS := 0.055   # the frame's corners, of the card's width

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rad := int(size.x * RADIUS)
		var mask := Panel.new()
		mask.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color.WHITE
		sb.set_corner_radius_all(rad)
		mask.add_theme_stylebox_override("panel", sb)
		add_child(mask)
		var art := Painting.new()
		art.id = id
		art.element = element
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mask.add_child(art)
		var frame := Panel.new()
		frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var fb := StyleBoxFlat.new()
		fb.draw_center = false
		fb.set_corner_radius_all(rad)
		fb.set_border_width_all(maxi(2, int(size.x * 0.018)))
		fb.border_color = Color(0.93, 0.9, 0.78) if lit else Color(0.62, 0.6, 0.55)
		frame.add_theme_stylebox_override("panel", fb)
		add_child(frame)
		set_process(lit)

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		if not lit:
			return
		# the light round it, breathing
		var k := 0.5 + 0.5 * sin(_t * 3.6)
		var rad := int(size.x * RADIUS)
		for i in 6:
			var g := (4.0 + i * 6.0) * (0.8 + 0.4 * k) * size.x / 240.0
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.8, 0.92, 1.0, (0.2 - i * 0.03) * (0.55 + 0.45 * k))
			sb.set_corner_radius_all(rad + int(g))
			draw_style_box(sb, Rect2(Vector2.ZERO, size).grow(g))

	class Painting:
		extends Control
		var id := ""
		var element := ""

		func _draw() -> void:
			var r := Rect2(Vector2.ZERO, size)
			draw_rect(r, Color(0.05, 0.06, 0.09))
			CardFace.draw_art(self, r, id, element, 0.4)


## The ring of light on the hound to strike: two arcs turning about it and a
## soft round of light, breathing.
class MoveRing:
	extends Control
	var centre := Vector2.ZERO
	var radius := 100.0
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var k := 0.5 + 0.5 * sin(_t * 3.6)
		var col := Color(0.8, 0.92, 1.0)
		var r := radius * (1.0 + 0.04 * k)
		for i in 5:
			draw_arc(centre, r + i * 3.0, 0.0, TAU, 72, Color(col, (0.16 - i * 0.03) * (0.5 + 0.5 * k)), 6.0, true)
		var wd := maxf(3.0, radius * 0.035)
		for i in 4:
			var a := _t * 0.9 + i * TAU / 4.0
			draw_arc(centre, r, a, a + TAU / 4.0 - 0.5, 20, Color(col, 0.95), wd, true)


## A bend at the small of the back laid over whatever the clip has (and
## before the hands' reach, so the arms reach from where it puts the
## shoulders): `amount` 0..1 of STOOP. Kneeling on one knee, Figure3D's kneel
## curls the back over (the shoulders stay a forearm's length over the
## snow); this tips the back over from the hips, flat, as a man bends to
## take something off the ground, so his hands get down to it.
class Stoop:
	extends SkeletonModifier3D
	var turns: Array = []   # [bone index, Quaternion at full]
	var amount := 0.0

	func _process_modification_with_delta(_delta: float) -> void:
		var sk := get_skeleton()
		if sk == null or amount <= 0.001:
			return
		for t in turns:
			var b: int = t[0]
			sk.set_bone_pose_rotation(b, Quaternion.IDENTITY.slerp(t[1] as Quaternion, amount) * sk.get_bone_pose_rotation(b))


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
	## Gary's model's meshes, for the fade; empty with the drawn hunter.
	var _geometry: Array = []
	## Gary's model's clips (null with the drawn hunter).
	var _ap: AnimationPlayer
	## How high the cards fan: by the hood of the drawn hunter (2.76 m) or
	## of Gary's (2.29 m, tools/rig_villager.sh shard_hunter).
	var _card_top := 2.6

	func _ready() -> void:
		var body := Node3D.new()
		add_child(body)
		if ResourceLoader.exists(MODEL):
			# Gary's faceless hunter (4 November, Tripo3D, rigged and cut like
			# Hale: 2.29 m, facing +z), playing its own idle
			var m := (load(MODEL) as PackedScene).instantiate() as Node3D
			body.add_child(m)
			var ap := m.find_child("AnimationPlayer", true, false) as AnimationPlayer
			_ap = ap
			if ap != null and ap.has_animation("idle"):
				ap.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
				ap.play("idle")
			if ap != null and ap.has_animation("walk"):
				ap.get_animation("walk").loop_mode = Animation.LOOP_LINEAR
			# (11 November, Gary: the hunter "before brams battle has deformed
			# right hand": his clips curl his long fingers and the skin
			# doesn't follow, Figure3D.FROZEN; kept as modelled)
			Figure3D.keep_fingers(m.find_child("Skeleton3D", true, false) as Skeleton3D)
			for g in m.find_children("*", "GeometryInstance3D", true, false):
				_geometry.append(g)
			_card_top = 2.2
			_hand = Node3D.new()
			_hand.position = Vector3(0.45, 1.3, 0.35)
			add_child(_hand)
			_add_smoke()
			_set_fade(_fade)
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

	## Walks to `to` (on the snow) over `secs` on its own walk clip, its feet
	## kept to the ground (the clip's pace, Figure3D.OWN_GAIT shard_hunter,
	## by how far it goes and how fast), then stands; the drawn hunter glides.
	func walk_to(to: Vector3, secs: float) -> void:
		var from := position
		var dist := Vector3(to.x - from.x, 0, to.z - from.z).length()
		if dist < 0.01:
			return
		look_at_dir(to - from)
		var pace: float = Figure3D.OWN_GAIT.get("shard_hunter", {}).get("walk", 2.41) * scale.x
		if _ap != null and _ap.has_animation("walk"):
			_ap.play("walk", 0.35, clampf(dist / maxf(0.1, secs) / pace, 0.3, 1.2))
		var tw := create_tween()
		tw.tween_property(self, "position", to, secs)
		await tw.finished
		if _ap != null and _ap.has_animation("idle"):
			_ap.play("idle", 0.45)

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
		# Gary's model: faded as a whole (Forward+ and Mobile; the drawn one
		# fades in its own shader)
		for g in _geometry:
			if is_instance_valid(g):
				(g as GeometryInstance3D).transparency = clampf(1.0 - k, 0.0, 1.0)
		var sm := get_node_or_null("Smoke") as GPUParticles3D
		if sm != null:
			sm.emitting = k > 0.05

	## Cards of white light rise out of the snow and fan above its hand.
	func raise_cards() -> void:
		for i in 5:
			# (6 November: Sigil cards as the falling ones are, in white light)
			var c := WhiteSky.sigil_card(Color(0.86, 0.9, 1.0))
			add_child(c)
			var a := (float(i) - 2.0) * 0.32
			c.position = Vector3(sin(a) * 1.4, 0.05, 0.6 + cos(a) * 0.5)
			var tw := create_tween()
			tw.tween_interval(i * 0.12)
			tw.tween_property(c, "position", Vector3(sin(a) * 0.9, _card_top + absf(a) * -0.3, 0.7), 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
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
