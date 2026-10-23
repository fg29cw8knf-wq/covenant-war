class_name DuelScreen
extends Control
## The duel, v1 rules: three Totem slots a side, Life, Essence, Fate dice and
## Wards. Draws the Circle, takes the player's taps and animates everything
## the rules engine (DuelGame) reports.
##
## configure(spec) with:
##   decks: [deck id | Array of card ids] x2     names: [String] x2
##   profiles: [Lore.new_profile(...)] x2        ai: [bool, bool] (who the computer plays)
##   difficulty: 0..1                            seed: int (-1 = random)
##   speed: 1.0, 2.0, 4.0
## Emits finished("won" | "lost" | "draw" | "again" | "quit").

signal finished(result: String)

const DESIGN := Vector2(1920, 1080)
const SLOT_SIZE := Vector2(340, 330)
const FIELD_CX := 1000.0
## Slot centres. The rival's row is further away: closer together and smaller.
const MY_X := [610.0, 1000.0, 1390.0]
const RIVAL_X := [672.0, 1000.0, 1328.0]
const MY_PLAT_Y := 652.0
const RIVAL_PLAT_Y := 300.0
const RIVAL_DEPTH := 0.8
const HAND_Y := 812.0
const HAND_CARD := Vector2(176, 246)
const DETAIL_POS := Vector2(1598, 96)
const DETAIL_SIZE := Vector2(298, 418)
## Where Cancel and notes sit while you pick a target.
const DOCK_POS := Vector2(1560, 536)
const LOG_MAX := 200
## The colour of the drifting light in each arena.
const ARENA_MOTES := {
	"solhaven": Color(1.0, 0.9, 0.6), "emberforge": Color(1.0, 0.55, 0.25), "tidegrove": Color(0.6, 1.0, 0.85),
	"ironstone": Color(1.0, 0.8, 0.45), "veilwild": Color(0.75, 0.55, 1.0),
}

var spec: Dictionary = {}
## Tutorial coaching: spec.coach = [{"at": "start"|"call"|"essence"|"attack", "who": "Bram", "say": "..."}].
## Each line shows once, when the duel reaches that step, and stays until the next.
var _coach_box: PanelContainer
var _coach_label: Label
var _coach_who: Label
var _coached: Dictionary = {}
var _my_turns := 0
## The gated tutorial (spec.tutorial), or null. See DuelTutor. A duel with
## spec.lessons = true (Bram is about) gets one with no script, so the first
## condition, Ward or Ascension can be explained once, the same gated way.
var tutor: DuelTutor = null
var _rolloff: DuelViews.RolloffView = null   # the dice for who goes first, while they're up
var _dice_view: DuelViews.DiceView = null    # a Fate roll, while it's up
var game: DuelGame
var human: DuelHuman
var me := 0
var rival := 1
var speed := 1.0
var sfx: Sfx

var stage: Control
var fx_layer: Control
var overlay: Control
var views := [[], []]          # [side][slot] -> TotemView
var panels := []               # [side] -> PlayerPanel
var hand_views: Array = []
var detail: DetailCard
var actions: VBoxContainer
var hint: DuelViews.HintView
var turn_label: Label
var end_btn: DuelViews.EmblemButton
var gift_btn: DuelViews.GiftButton
var ward_zones := []           # [side] -> WardZone
var phase_band: DuelViews.PhaseBand   # the turn's phases, under the rival's plate (Phase A)
var rival_hand: DuelViews.HandBacks
var _menu_anchor := Vector2(-1, -1)
var _menu_beside := 0            # 0: above the anchor; -1 / 1: to that side of it (3D field)
var _place_queued := false
var _stage_base := Vector2.ZERO
var _shake := 0.0
var _base_k := 1.0
var _zoom := 0.0
var _won_resonance := 0
var _zoom_at := Vector2(1000, 476)
var _started := false
var _arena_name := "solhaven"
var arena_label: Label        # the Circle's rule, under the turn count (Phase D)
var _pinch := false
var field: DuelField3D = null    # the 3D field, when the 3D setting is on
var _herald: PaleHerald = null   # a Pale Herald watching at the Circle's edge (spec.herald_at)
var _herald2d: Sprite2D = null    # the same on the flat (2D) field
## On screens wider than 16:9 the side columns move out to the screen's edges.
var _edge := 0.0
var _left_nodes := []          # [Control, design position]
var _right_nodes := []
var _arena: Arena
var _strike := {}              # the attack in flight: {attacker, melee, to3}
var _last_hit_pos := Vector2.ZERO
var _impact3 := Vector3.ZERO     # where the last hit landed in the 3D field
var log_panel: PanelContainer
var log_text: RichTextLabel
var lab_panel: PanelContainer

var mode := "idle"             # idle, main, pick_slot, respond, busy, over
var sel_card: DuelCard = null
var sel_totem: DuelTotem = null
var sel_move := -1
var sel_tributes: Array = []   # the Totems given up for the call being placed (Phase B)
var sel_veiled := false        # the call being placed goes face down (Phase C)
var pending := ""              # call, ascend, rite, summon, move, shift, gift
var targets: Array = []        # DuelTotem | "life" | int (slot index, on pick_side)
var pick_side := 0
var reveal_rival := false
var _log_lines: Array = []
var _result := ""


func configure(p_spec: Dictionary) -> DuelScreen:
	spec = p_spec
	return self


# ================================================================== build ===

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.make()
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	speed = float(spec.get("speed", Game.settings.get("duel_speed", 1.0)))
	sfx = Sfx.new()
	add_child(sfx)
	sfx.volume_db = linear_to_db(maxf(0.001, float(Game.settings.get("sfx", 0.9)))) - 8.0
	var arena_name: String = spec.get("arena", "")
	if arena_name == "":
		var decks: Array = spec.get("decks", ["emberstorm", "tidegrove"])
		arena_name = DuelArt.arena_for_deck(decks[1] if decks.size() > 1 else "")
	_arena_name = arena_name
	var use3d: bool = spec.get("field3d", Game.settings.get("duel_3d", true))
	if use3d:
		field = DuelField3D.new()
		add_child(field)
		field.setup(arena_name)
		if spec.has("herald_at"):
			# the story's Pale Herald, at the Circle's edge, watching
			_herald = PaleHerald.new()
			field.world.add_child(_herald)
			_herald.position = spec.herald_at
			_herald.scale = Vector3.ONE * float(spec.get("herald_scale", 1.0))
			_herald.snap_dir(Vector3(-_herald.position.x, 0, 0.35 - _herald.position.z))
	var bg := Arena.new()
	_arena = bg
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.overlay_only = use3d
	bg.tex = null if use3d else DuelArt.arena(arena_name)
	bg.mote_col = ARENA_MOTES.get(arena_name, bg.mote_col)
	add_child(bg)
	stage = Control.new()
	stage.size = DESIGN
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)
	bg.stage = stage
	if field != null:
		field.stage = stage
	_build()
	if field == null and spec.has("herald_at"):
		# (the flat field: the Herald as a pale figure at the Circle's far edge)
		var tex := DollArt.texture("herald", "front")
		_herald2d = Sprite2D.new()
		_herald2d.texture = tex
		_herald2d.centered = true
		var k := 250.0 / float(maxi(1, tex.get_height()))
		_herald2d.scale = Vector2(k, k)
		_herald2d.position = Vector2(1770, 330)
		_herald2d.modulate = Color(0.85, 0.88, 0.95, 0.5)
		stage.add_child(_herald2d)
		stage.move_child(_herald2d, 0)
	fx_layer = Control.new()
	fx_layer.size = DESIGN
	fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.z_index = 50          # above the fanned hand (which uses z_index for its order)
	stage.add_child(fx_layer)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 100
	add_child(overlay)
	resized.connect(_fit)
	SafeArea.watch(self, _fit)
	_start.call_deferred()


## The stage (cards, hand, Life, buttons) fits the screen's safe area, clear
## of a phone's Dynamic Island and home bar; on screens wider than 16:9 its
## side columns move out towards the edges. The arena and the 3D field fill
## the whole screen around it.
func _fit() -> void:
	var s := _safe_rect()
	var k := minf(s.size.x / DESIGN.x, s.size.y / DESIGN.y)
	_base_k = k
	stage.scale = Vector2(k, k)
	_stage_base = (s.position + (s.size - DESIGN * k) * 0.5).floor()
	stage.position = _stage_base
	_edge = maxf(0.0, (s.size.x / k - DESIGN.x) * 0.5) * 0.85
	_apply_edges()
	if field != null:
		field.fit_to_stage(_stage_base, k, size)


## The safe area in this screen's own coordinates.
func _safe_rect() -> Rect2:
	var m := SafeArea.insets()
	return Rect2(Vector2(m.x, m.y), size - Vector2(m.x + m.z, m.y + m.w))


## Pins a control to the left (or right) column so it hugs the screen edge.
func _pin(n: Control, pos: Vector2, right: bool) -> void:
	(_right_nodes if right else _left_nodes).append([n, pos])
	n.position = pos + Vector2(_edge if right else -_edge, 0)


func _apply_edges() -> void:
	for e in _left_nodes:
		e[0].position = e[1] - Vector2(_edge, 0)
	for e in _right_nodes:
		e[0].position = e[1] + Vector2(_edge, 0)
	if _arena != null:
		_arena.edge = _edge


func _detail_pos() -> Vector2:
	return DETAIL_POS + Vector2(_edge, 0)


func _process(delta: float) -> void:
	if stage == null:
		return
	if _view_save > 0.0:
		_view_save -= delta
		if _view_save <= 0.0:
			Game.save_settings()
	if field != null:
		_sync_field()
		for side in 2:
			for v in views[side]:
				v.queue_redraw()
	if _shake <= 0.0 and _zoom <= 0.0:
		if stage.position != _stage_base:
			stage.position = _stage_base
			stage.scale = Vector2(_base_k, _base_k)
		return
	_shake = move_toward(_shake, 0.0, delta * 60.0)
	_zoom = move_toward(_zoom, 0.0, delta * 0.1)
	var k := _base_k * (1.0 + _zoom)
	stage.scale = Vector2(k, k)
	var jolt := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake * _base_k
	stage.position = _stage_base - _zoom_at * _base_k * _zoom + jolt


## A quick push of the camera towards a big moment.
func punch(at: Vector2, amount: float = 0.03) -> void:
	if field != null:
		field.cam_punch(amount * 1.6)
		return
	if amount > _zoom:
		_zoom = amount
		_zoom_at = at


## Shakes the whole field (big hits, knockouts).
func shake(amount: float) -> void:
	if field != null:
		field.cam_shake(amount)
		return
	_shake = maxf(_shake, amount)


## Keeps each 2D slot view sitting on its 3D slot, and the 3D slot showing
## what the view knows (the Totem, highlights, nudges, flashes).
func _sync_field() -> void:
	if game == null:
		return
	for side in 2:
		for v in views[side]:
			field.sync(v)
			var foot: Vector2 = field.foot_stage(side, v.slot)
			v.position = foot - Vector2(v.size.x * 0.5, v.size.y * 0.6)
			v.body_rect_3d = Rect2(field.body_stage(side, v.slot) - Vector2(90, 110), Vector2(180, 220)) if v.totem != null else Rect2()


## "Wren's", or "Your" for a duellist called You.
func _whose(player_name: String) -> String:
	return "Your" if player_name == "You" else "%s's" % player_name


## Where a slot's view goes on the stage.
func _slot_pos(side: int, slot: int) -> Vector2:
	if side == me:
		return Vector2(MY_X[slot] - SLOT_SIZE.x * 0.5, MY_PLAT_Y - SLOT_SIZE.y * 0.6)
	return Vector2(RIVAL_X[slot] - SLOT_SIZE.x * 0.5, RIVAL_PLAT_Y - SLOT_SIZE.y * 0.6)


func _build() -> void:
	# the rival's hand, face down along the top
	rival_hand = DuelViews.HandBacks.new()
	rival_hand.position = Vector2(FIELD_CX - 300, 0)
	rival_hand.size = Vector2(600, 90)
	stage.add_child(rival_hand)
	# the Circle's slots
	for side in 2:
		views[side] = []
		for s in DuelRules.SLOTS:
			var v := DuelViews.TotemView.new()
			v.side = side
			v.slot = s
			v.size = SLOT_SIZE
			v.field3d = field != null
			v.tapped.connect(_on_slot_tapped)
			stage.add_child(v)
			views[side].append(v)
	# Ward zones and Life plates down the left
	for side in 2:
		var wz := DuelViews.WardZone.new()
		wz.size = Vector2(418, 140)
		wz.standing_tapped.connect(func(c: DuelCard) -> void:
			sfx.play("ui_select")
			_show_detail(c.id))
		stage.add_child(wz)
		ward_zones.append(wz)
	for side in 2:
		var p := DuelViews.PlayerPanel.new()
		p.size = Vector2(412, 250)
		p.tapped.connect(_on_panel_tapped)
		p.discard_tapped.connect(_on_discard_tapped)
		stage.add_child(p)
		panels.append(p)
	phase_band = DuelViews.PhaseBand.new()
	phase_band.size = Vector2(400, 42)
	stage.add_child(phase_band)
	# aiming arrows while a target is being picked
	var arrows := TargetArrows.new()
	arrows.screen = self
	arrows.size = DESIGN
	stage.add_child(arrows)
	# guidance across the middle, and the turn count on the left
	hint = DuelViews.HintView.new()
	hint.position = Vector2(440, 450)
	hint.size = Vector2(1120, 54)
	stage.add_child(hint)
	turn_label = UITheme.label("", 24, UITheme.TEXT_DIM, "bold", 5)
	_pin(turn_label, Vector2(26, 456), false)
	turn_label.size = Vector2(390, 44)
	stage.add_child(turn_label)
	arena_label = UITheme.label("", 19, UITheme.TEXT_DIM, "body", 4)
	_pin(arena_label, Vector2(26, 500), false)
	arena_label.size = Vector2(390, 120)
	arena_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stage.add_child(arena_label)
	# the card being looked at (shown when something is tapped)
	detail = DetailCard.new()
	detail.position = _detail_pos()
	detail.size = DETAIL_SIZE
	detail.visible = false
	stage.add_child(detail)
	# moves and card actions pop up beside what was tapped
	actions = VBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	actions.position = DOCK_POS
	stage.add_child(actions)
	# patron medallion and End Turn, bottom right
	gift_btn = DuelViews.GiftButton.new()
	_pin(gift_btn, Vector2(1546, 842), true)
	gift_btn.size = Vector2(150, 196)
	gift_btn.pressed.connect(_on_gift)
	stage.add_child(gift_btn)
	end_btn = DuelViews.EmblemButton.new()
	_pin(end_btn, Vector2(1690, 836), true)
	end_btn.size = Vector2(228, 228)
	end_btn.pressed.connect(_on_end_turn)
	stage.add_child(end_btn)
	var menu := DuelViews.IconButton.new()
	_pin(menu, Vector2(1838, 10), true)
	menu.size = Vector2(74, 74)
	menu.pressed.connect(func() -> void:
		sfx.play("ui_menu")
		lab_panel.visible = not lab_panel.visible
		if not lab_panel.visible:
			log_panel.visible = false)
	stage.add_child(menu)
	_build_log()
	_build_lab()


func _small_button(t: String) -> Button:
	var b := UITheme.button(t, false, 170)
	b.custom_minimum_size = Vector2(172, 72)
	b.add_theme_font_size_override("font_size", 26)
	return b


func _build_log() -> void:
	log_panel = PanelContainer.new()
	log_panel.add_theme_stylebox_override("panel", UITheme.sb(Color(0.03, 0.04, 0.07, 0.96), UITheme.GOLD_DIM, 18, 2, 18))
	log_panel.position = Vector2(440, 96)
	log_panel.size = Vector2(860, 700)
	log_panel.visible = false
	stage.add_child(log_panel)
	log_text = RichTextLabel.new()
	log_text.bbcode_enabled = true
	log_text.scroll_following = true
	log_text.add_theme_font_override("normal_font", CardFace.font("body"))
	log_text.add_theme_font_size_override("normal_font_size", 24)
	log_panel.add_child(log_text)


func _build_lab() -> void:
	lab_panel = PanelContainer.new()
	lab_panel.add_theme_stylebox_override("panel", UITheme.sb(Color(0.03, 0.04, 0.07, 0.97), UITheme.GOLD_DIM, 18, 2, 24))
	_pin(lab_panel, Vector2(1330, 96), true)
	lab_panel.size = Vector2(570, 640)
	lab_panel.visible = false
	stage.add_child(lab_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	lab_panel.add_child(box)
	box.add_child(UITheme.label("Menu", 34, UITheme.GOLD, "display_bold"))
	# the duel's own rule, and the Law it's under, to read again any time
	var rule: Array = spec.get("rule", [])
	if rule.size() >= 2:
		var rl := UITheme.label("%s: %s" % [String(rule[0]), String(rule[1])], 24, UITheme.TEXT)
		rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rl.custom_minimum_size = Vector2(500, 0)
		box.add_child(rl)
	var law := String(spec.get("law", ""))
	if law != "":
		var ll := UITheme.label("%s: %s" % [DuelLaws.law_name(law), DuelLaws.describe(law)], 24, UITheme.TEXT)
		ll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ll.custom_minimum_size = Vector2(500, 0)
		box.add_child(ll)
	var lg := UITheme.button("Duel log", false, 500)
	lg.pressed.connect(func() -> void: log_panel.visible = not log_panel.visible)
	box.add_child(lg)
	var oath_b := UITheme.button("Swear an Oath", false, 500)
	oath_b.pressed.connect(func() -> void:
		lab_panel.visible = false
		log_panel.visible = false
		if mode != "main":
			_toast("Oaths are sworn on your turn.")
		elif not _oath_available():
			_toast("No Oath can be sworn now." if _oaths_open() else "Not in this duel.")
		else:
			_offer_oaths())
	box.add_child(oath_b)
	box.add_child(UITheme.label("Animation speed", 24, UITheme.TEXT_DIM))
	var sp := HBoxContainer.new()
	sp.add_theme_constant_override("separation", 10)
	box.add_child(sp)
	for v in [1.0, 2.0, 4.0]:
		var b := _small_button("%dx" % int(v))
		b.custom_minimum_size = Vector2(160, 72)
		b.pressed.connect(func() -> void:
			speed = v
			Game.settings["duel_speed"] = v
			Game.save_settings())
		sp.add_child(b)
	# Gary's Summon clips: the long one first, then the short; or short
	# always, or none (SummonVideo)
	box.add_child(UITheme.label("Summon videos", 24, UITheme.TEXT_DIM))
	var svb := HBoxContainer.new()
	svb.add_theme_constant_override("separation", 10)
	box.add_child(svb)
	var sv_btns := []
	for m in SummonVideo.MODES:
		var sb := _small_button(String(SummonVideo.MODE_NAMES[m]))
		sb.toggle_mode = true
		sb.button_pressed = SummonVideo.mode() == m
		sb.custom_minimum_size = Vector2(160, 72)
		sb.pressed.connect(func() -> void:
			SummonVideo.set_mode(String(m))
			for o in sv_btns:
				o.button_pressed = o == sb)
		sv_btns.append(sb)
		svb.add_child(sb)
	var d3 := CheckButton.new()
	d3.text = "3D field (restart the duel to apply)"
	d3.button_pressed = Game.settings.get("duel_3d", true)
	d3.add_theme_font_size_override("font_size", 24)
	d3.toggled.connect(func(on: bool) -> void:
		Game.settings["duel_3d"] = on
		Game.save_settings())
	box.add_child(d3)
	var vio := CheckButton.new()
	vio.text = "Full violence (blood when Totems fall)"
	vio.button_pressed = String(Game.settings.get("violence", "full")) == "full"
	vio.add_theme_font_size_override("font_size", 24)
	vio.toggled.connect(func(on: bool) -> void:
		Game.settings["violence"] = "full" if on else "reduced"
		Game.save_settings())
	box.add_child(vio)
	var rv := CheckButton.new()
	rv.text = "Show the rival's hand and Wards"
	rv.add_theme_font_size_override("font_size", 24)
	rv.toggled.connect(func(on: bool) -> void:
		reveal_rival = on
		panels[rival].reveal_wards = on
		ward_zones[rival].reveal = on
		_refresh())
	box.add_child(rv)
	var again := UITheme.button("Restart this duel", false, 500)
	again.pressed.connect(func() -> void: _leave("again"))
	box.add_child(again)
	var quit := UITheme.button("Leave the duel", false, 500)
	quit.pressed.connect(func() -> void: _leave("quit"))
	box.add_child(quit)


func _leave(result: String) -> void:
	if mode == "over":
		return
	mode = "over"
	if game != null and not game.over:
		game._finish(2, "The duel was abandoned.")
	finished.emit(result)


# ================================================================== start ===

func _start() -> void:
	if Game.settings.get("debug_autoplay", false) and spec.get("story", false):
		spec["ai"] = [true, true]   # automated tests: the computer plays the player's side too
		spec["speed"] = 20.0
		speed = 20.0
	var ai_flags: Array = spec.get("ai", [false, true])
	me = 0
	rival = 1
	human = DuelHuman.new()
	human.screen = self
	var controllers := []
	var lesson: Dictionary = spec.get("tutorial", {})
	for i in 2:
		if ai_flags[i]:
			var a: DuelHuman.Paced
			if i == 1 and not lesson.is_empty() and spec.has("rival_script"):
				a = DuelHuman.Scripted.new(spec.rival_script, float(spec.get("difficulty", 1.0)))
			else:
				a = DuelHuman.Paced.new(float(spec.get("difficulty", 1.0)))
			a.screen = self
			controllers.append(a)
		else:
			controllers.append(human)
	game = DuelGame.new()
	game.stacked = spec.get("stacked", [false, false])
	game.setup(spec.get("decks", ["emberstorm", "tidegrove"]), spec.get("names", ["You", "Rival"]),
		controllers, spec.get("profiles", []), int(spec.get("seed", -1)))
	if not ai_flags[me]:
		# the player's Tempering marks (Phase C), on a copy of their duel profile
		var prof: Dictionary = game.players[me].profile.duplicate()
		prof["temper"] = Game.temper_marks()
		game.players[me].profile = prof
	game.start_life = int(spec.get("life", 0))
	game.start_lives = spec.get("lives", [])
	game.first_forced = int(spec.get("first", -1))
	game.life_floor = spec.get("life_floor", [0, 0])
	game.totem_floor = spec.get("totem_floor", [0, 0])
	if (not lesson.is_empty() or spec.get("lessons", false)) and not ai_flags[me]:
		tutor = DuelTutor.new().setup(self, lesson, String(spec.get("lesson_group", "The Lantern Duel")))
	game.law = String(spec.get("law", ""))
	game.story_rules = spec.get("story_rules", {})
	# the Circle's own rule (Phase D); a story duel's own rule stands in its place
	game.arena = "" if (spec.has("rule") or not game.story_rules.is_empty()) else _arena_name
	game.ai_oaths = not bool(spec.get("story", false))   # (story rivals don't swear)
	game.life_scale = float(spec.get("life_scale", 1.0))
	game.kept_back = (spec.get("kept_back", [[], []]) as Array).duplicate(true)
	game.puzzle = spec.get("puzzle", {})
	game.presenter = self
	if field != null:
		# every model this duel could call, loaded and drawn once now, so
		# no summon has to wait for it (DuelField3D.warm_models)
		var ids := {}
		for p in game.players:
			for c in p.deck:
				ids[c.id] = true
		for side in game.kept_back:
			for kid in side:
				ids[String(kid)] = true
		field.warm_models(ids.keys())
	sfx.play("shuffle")
	# a story duel can name its own music (spec.music: tracks to try first)
	Music.play((spec.get("music", ["arena_" + _arena_name]) as Array) + Music.duel_theme())
	game.logged.connect(_on_log)
	game.state_changed.connect(_refresh)
	for side in 2:
		for v in views[side]:
			v.mine = side == me
			v.depth = 1.0 if side == me else RIVAL_DEPTH
			v.position = _slot_pos(side, v.slot)
	if field != null:
		field.set_rows(me)
	_pin(panels[rival], Vector2(6, 6), false)
	_pin(panels[me], Vector2(6, 822), false)
	_pin(phase_band, Vector2(20, 258), false)
	_pin(ward_zones[rival], Vector2(20, 306), false)
	_pin(ward_zones[me], Vector2(20, 690), false)
	for side in 2:
		panels[side].player = game.players[side]
		panels[side].mine = side == me
		panels[side].sub = _plate_line(side)
		ward_zones[side].player = game.players[side]
		ward_zones[side].mine = side == me
		ward_zones[side].face_up = game.face_up   # Wards that lie face up (Fen's Patter, the Unveiling)
	BlankCardSlot.attach(self)   # the blank card, from the night of the Sigilfall on
	_refresh()
	await game.run()
	if mode == "over":
		return
	mode = "over"
	_refresh()
	var r := "draw"
	if game.winner == me:
		r = "won"
	elif game.winner == rival:
		r = "lost"
	var choice: String = await _show_result(r)
	finished.emit(choice if choice != "" else r)


func pause(sec: float) -> void:
	await get_tree().create_timer(maxf(0.01, sec / speed)).timeout


# ================================================================ refresh ===

func _refresh() -> void:
	if game == null:
		return
	for side in 2:
		var p: DuelPlayer = game.players[side]
		for v in views[side]:
			v.set_totem(p.slots[v.slot])
		panels[side].active = game.current == side and not game.over
	_layout_hand()
	_update_highlights()
	rival_hand.count = game.players[rival].hand.size()
	rival_hand.queue_redraw()
	if not _pinch and not game.over and game.turn > 0:
		for pl in game.players:
			if pl.life > 0 and pl.life <= pl.max_life * 0.3 and Music.has("duel_pinch"):
				_pinch = true
				Music.play(["duel_pinch"], 0.6)
				break
	var cur: DuelPlayer = game.players[game.current]
	var whose := "Your turn" if game.current == me and not _watching() else "%s turn" % _whose(cur.player_name)
	if game.turn > 0:
		turn_label.text = "TURN %d  ·  %s" % [game.turn, whose]
	arena_label.text = _arena_line()
	var my_turn := mode == "main"
	if game.over:
		end_btn.state = "off"
	elif my_turn:
		end_btn.state = "glow" if not game.can_do_anything_but_end(me) and pending == "" else "on"
		end_btn.label = _end_label()
	else:
		end_btn.state = "wait"
	end_btn.wait_label = "WATCHING" if _watching() else ("%s TURN" % _whose(cur.player_name)).to_upper()
	if game.current == me and not _watching():
		end_btn.wait_label = "PLEASE WAIT"
	var mp: DuelPlayer = game.players[me]
	gift_btn.god = mp.patron()
	gift_btn.gift_name = Lore.GIFTS[mp.gift()].name
	gift_btn.used = mp.gift_used and not mp.favour_ready
	gift_btn.enabled = my_turn and (game.gift_problem(me) == "" or game.demigod_problem(me) == "")
	gift_btn.favour = clampf(mp.favour() / maxf(1.0, DuelRules.favour_max), 0.0, 1.0)
	gift_btn.favour_ready = mp.favour_ready
	gift_btn.favour_col = DuelFX.light(Lore.GODS[mp.patron()].element) if mp.patron() != "" and Lore.GODS.has(mp.patron()) else UITheme.GOLD


func _watching() -> bool:
	var ai_flags: Array = spec.get("ai", [false, true])
	return ai_flags[me]


## What the big button does now: on to the Clash, on to the second Main, or
## end the turn (Phase A). A tutorial step that says "end" ends it.
func _end_label() -> String:
	if _tutor_wants_end():
		return "END TURN"
	match game.next_phase(me):
		"clash":
			return "TO CLASH"
		"main2":
			return "MAIN II"
	return "END TURN"


func _tutor_wants_end() -> bool:
	if tutor == null or not tutor.gating():
		return false
	var step: Dictionary = tutor._current_do()
	return not step.is_empty() and String(step.get("do", "")) == "end"


## The line under a duellist's name on their plate: spec.plates (or the
## profile's "plate") when the story gives one (Corin is "Ashford"), else
## "Sworn to <god>", else "Unsworn" for the player only. "The Unsworn" is
## the player's name in the story, so a rival with no god (Bram, Dask) shows
## nothing there.
func _plate_line(side: int) -> String:
	var plates: Array = spec.get("plates", [])
	if side < plates.size():
		return String(plates[side])
	var p: DuelPlayer = game.players[side]
	if p.profile.has("plate"):
		return String(p.profile.plate)
	if p.patron() != "":
		return "Sworn to %s" % Lore.GODS[p.patron()].name
	var ai_flags: Array = spec.get("ai", [false, true])
	return "Unsworn" if side < ai_flags.size() and not ai_flags[side] else ""


func _layout_hand() -> void:
	var p: DuelPlayer = game.players[me]
	var keep := {}
	for hv in hand_views:
		keep[hv.card] = hv
	var fresh := []
	for c in p.hand:
		var hv: DuelViews.HandCard = keep.get(c)
		if hv == null:
			hv = DuelViews.HandCard.new(c)
			hv.size = HAND_CARD
			hv.pivot_offset = Vector2(HAND_CARD.x * 0.5, HAND_CARD.y)
			hv.tapped.connect(_on_hand_tapped)
			stage.add_child(hv)
			hv.position = Vector2(1500, 1120)
			hv.rotation = 0.5
		keep.erase(c)
		fresh.append(hv)
	for c in keep:
		keep[c].queue_free()
	hand_views = fresh
	# fan the cards in an arc
	var n := hand_views.size()
	var step := minf(HAND_CARD.x * 0.86, 820.0 / maxf(1.0, n - 1))
	var tilt := minf(3.2, 26.0 / maxf(1.0, n - 1))
	for i in n:
		var hv: DuelViews.HandCard = hand_views[i]
		var off := i - (n - 1) * 0.5
		var target := Vector2(FIELD_CX + off * step - HAND_CARD.x * 0.5, HAND_Y + off * off * 2.4)
		var rot := deg_to_rad(off * tilt)
		var sc := 1.0
		hv.z_index = i
		if hv.card == sel_card:
			target.y -= 74
			rot = 0.0
			sc = 1.1
			hv.z_index = 40
		if hv.position.distance_to(target) > 2 or absf(hv.rotation - rot) > 0.01 or absf(hv.scale.x - sc) > 0.01:
			var tw := hv.create_tween().set_parallel(true)
			tw.tween_property(hv, "position", target, 0.24 / speed).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			tw.tween_property(hv, "rotation", rot, 0.24 / speed).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			tw.tween_property(hv, "scale", Vector2(sc, sc), 0.24 / speed).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		hv.attrs = p.attributes()
		hv.cost_shown = _card_cost(hv.card)
		hv.state = _hand_state(hv.card)
		if _watching():
			hv.state = "normal"


## The top centre of a hand card once it has risen out of the fan.
func _hand_anchor(hv) -> Vector2:
	var i := hand_views.find(hv)
	var n := hand_views.size()
	var step := minf(HAND_CARD.x * 0.86, 820.0 / maxf(1.0, n - 1))
	var off := i - (n - 1) * 0.5
	return Vector2(FIELD_CX + off * step, HAND_Y - 74 - 32)


## Where something the tutorial points at sits on the stage (design pixels).
## f: hand, card:<id>, slot:<n>, totem:<id>, foe:<id>, target:<id|life>,
## life, essence, end, move:<n>, detail (the card panel), die (the dice up
## now); anything else gives an empty rect.
func tutor_rect(f: String) -> Rect2:
	var kind := f.get_slice(":", 0)
	var arg := f.get_slice(":", 1) if f.contains(":") else ""
	match kind:
		"detail":
			if detail.visible:
				return Rect2(detail.position, detail.size)
		"die":
			if _rolloff != null:
				return Rect2(_rolloff.position, _rolloff.size)
			if _dice_view != null:
				var dc := _dice_view.position + _dice_view.die_center()
				return Rect2(dc - Vector2(150, 150), Vector2(300, 300))
		"hand":
			var r := Rect2()
			for hv in hand_views:
				var hr := Rect2(hv.position, hv.size * hv.scale)
				r = hr if r.size == Vector2.ZERO else r.merge(hr)
			return r
		"card":
			for hv in hand_views:
				if hv.card.id == arg:
					return Rect2(hv.position, hv.size * hv.scale)
		"slot":
			var v: DuelViews.TotemView = views[me][clampi(int(arg), 0, DuelRules.SLOTS - 1)]
			var foot := _foot(v)
			return Rect2(foot - Vector2(130, 150), Vector2(260, 200))
		"totem", "foe", "target":
			if kind == "target" and arg == "life":
				return tutor_rect("life")
			var sides := [me] if kind == "totem" else ([rival] if kind == "foe" else [rival, me])
			for side in sides:
				for v in views[side]:
					if v.totem != null and v.totem.id() == arg:
						if field != null and v.body_rect_3d.size != Vector2.ZERO:
							return v.body_rect_3d.grow(14)
						return Rect2(v.position, v.size)
		"life":
			var p: DuelViews.PlayerPanel = panels[rival]
			return Rect2(p.position + p.life_rect().position, p.life_rect().size).grow(8)
		"essence":
			var p2: DuelViews.PlayerPanel = panels[me]
			return Rect2(p2.position, p2.size)
		"ward":
			var wz: DuelViews.WardZone = ward_zones[rival if arg == "rival" else me]
			var n := maxi(1, game.players[rival if arg == "rival" else me].wards.size())
			return Rect2(wz.position + wz.card_rect(0).position, Vector2(94 * n, 109)).grow(6)
		"end":
			return Rect2(end_btn.position, end_btn.size)
		"move":
			for b in actions.get_children():
				if b is ActionButton and String(b.get_meta("key", "")) == "move:" + arg:
					return Rect2(actions.position + b.position, b.size)
			if arg == "any":
				var r2 := Rect2()
				for b in actions.get_children():
					if b is ActionButton and String(b.get_meta("key", "")).begins_with("move:"):
						var br := Rect2(actions.position + b.position, b.size)
						r2 = br if r2.size == Vector2.ZERO else r2.merge(br)
				return r2
	return Rect2()


func _card_cost(c: DuelCard) -> int:
	if c.is_basic_totem():
		return game.call_cost(me, c)
	if c.is_summon():
		return game.summon_cost(me, c)
	return c.cost()


func _hand_state(c: DuelCard) -> String:
	if c == sel_card:
		return "selected"
	var p: DuelPlayer = game.players[me]
	if _card_cost(c) > p.essence:
		return "unaffordable"
	if mode != "main":
		return "normal"
	if game.phase_problem(_play_kind(c)) != "":
		return "normal"   # not in this phase of the turn
	var ok := false
	match c.kind():
		"totem":
			ok = game.call_problem(me, c) == "" if c.is_basic_totem() else game.ascend_problem(me, c) == ""
		"rite":
			ok = game.rite_problem(me, c) == ""
		"ward":
			ok = game.ward_problem(me, c) == ""
		"summon":
			ok = game.summon_problem(me, c) == ""
		"relic":
			ok = game.relic_problem(me, c) == ""
	return "playable" if ok else "normal"


## The kind of action playing this card is, for the phase rules.
func _play_kind(c: DuelCard) -> String:
	if c.kind() == "totem":
		return "call" if c.is_basic_totem() else "ascend"
	return c.kind()


func _update_highlights() -> void:
	for side in 2:
		for v in views[side]:
			var h := ""
			if pending != "" or mode == "pick_slot":
				if v.totem != null and targets.has(v.totem):
					h = "target"
				elif v.totem == null and side == pick_side and targets.has(v.slot) and (pending == "call" or pending == "shift" or mode == "pick_slot"):
					h = "target"
				elif pending == "shift" and side == me and targets.has(v.slot) and v.totem != sel_totem:
					h = "target"
				elif pending == "call" and side == me and v.totem != null and sel_tributes.has(v.totem):
					h = "target"   # (a tribute's slot is free for the Totem it's given up for)
			if v.totem != null and v.totem == sel_totem:
				h = "selected"
			if h == "" and mode == "main" and side == me and v.totem != null and _has_usable_move(v.totem) and game.phase_problem("attack") == "":
				h = "ready"
			v.highlight = h
	panels[rival].targetable = targets.has(DuelGame.LIFE)
	panels[me].targetable = false


func _has_usable_move(t: DuelTotem) -> bool:
	for i in t.moves().size():
		if game.move_problem(me, t, i) == "":
			return true
	return false


# ============================================================== main mode ===

func begin_main() -> void:
	mode = "main"
	_clear_selection()
	_hide_detail()
	_refresh()
	_show_actions_default()
	_my_turns += 1
	if _my_turns == 1:
		_coach("call")
	elif _my_turns == 2:
		_coach("attack")
	_bark_if_lethal()


func _clear_selection() -> void:
	sel_card = null
	sel_totem = null
	sel_move = -1
	sel_tributes = []
	sel_veiled = false
	pending = ""
	targets = []


func _respond(value) -> void:
	mode = "busy"
	_clear_selection()
	_set_hint("")
	_clear_actions()
	_hide_detail()
	_refresh()
	human.responded.emit(value)


func _set_hint(t: String) -> void:
	hint.text = t


## Keyboard and mouse on a computer: Esc or right-click cancels what's
## selected (or opens the duel menu), Space ends the turn.
func _unhandled_input(e: InputEvent) -> void:
	if mode == "over" or not is_visible_in_tree():
		return
	if banner_waiting:
		# the Law or the rule is up to be read: the interact key moves it on
		if e.is_action_pressed("interact") and not e.is_echo():
			tap_banner()
			get_viewport().set_input_as_handled()
		return
	if tutor != null and tutor.blocking:
		# an explanation is up: E, Space, Enter or a pad's A carries on, like a tap
		if e.is_action_pressed("interact"):
			tutor.tap()
			get_viewport().set_input_as_handled()
		return
	var cancel: bool = e.is_action_pressed("menu") or (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT)
	if cancel and tutor != null and tutor.gating() and mode == "main":
		tutor.nudge()   # no backing out of a lesson step
		get_viewport().set_input_as_handled()
		return
	if cancel:
		if mode == "main" and (pending != "" or sel_card != null or sel_totem != null):
			_back_out()
		elif e.is_action_pressed("menu"):
			lab_panel.visible = not lab_panel.visible
			if not lab_panel.visible:
				log_panel.visible = false
		get_viewport().set_input_as_handled()
	elif e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_SPACE:
		if mode == "main" and pending == "" and sel_card == null and sel_totem == null:
			_on_end_turn()
			get_viewport().set_input_as_handled()


## A right-click cancels wherever the pointer is. The cards and Totems keep
## clicks for themselves, so it's caught here, before they see it. So is the
## zoom (the cards and Totems would keep the wheel too).
func _input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT:
		_unhandled_input(e)
	_zoom_input(e)


var _touches := {}       # finger index -> where it is
var _spread := 0.0       # how far apart two fingers were (0: not pinching)
var _view_save := 0.0    # the zoom is saved once it has stopped changing for this long


## A little zoom on the 3D field (DuelField3D.zoom_by): the mouse wheel, a
## trackpad, or two fingers pinching. Not over the duel log or menu (they
## scroll), nor while a question or a card picker is up.
func _zoom_input(e: InputEvent) -> void:
	if field == null or not is_visible_in_tree():
		return
	if e is InputEventScreenTouch:
		if e.pressed:
			_touches[e.index] = e.position
		else:
			_touches.erase(e.index)
		_spread = _touch_spread()
		return
	if e is InputEventScreenDrag:
		if _touches.has(e.index):
			_touches[e.index] = e.position
		var d := _touch_spread()
		if _spread > 0.0 and d > 8.0 and not _over_panel(e.position):
			_zoom_field(_spread / d)   # fingers apart: closer
		_spread = d
		return
	var factor := 0.0
	if e is InputEventMouseButton and e.pressed and (e.button_index == MOUSE_BUTTON_WHEEL_UP or e.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		var notches: float = e.factor if e.factor > 0.0 else 1.0
		factor = pow(0.95, notches if e.button_index == MOUSE_BUTTON_WHEEL_UP else -notches)
	elif e is InputEventMagnifyGesture and e.factor > 0.0:
		factor = 1.0 / e.factor
	elif e is InputEventPanGesture:
		factor = exp(clampf(e.delta.y, -4.0, 4.0) * 0.04)
	if factor <= 0.0 or _over_panel(e.position):
		return
	_zoom_field(factor)
	get_viewport().set_input_as_handled()


func _touch_spread() -> float:
	var ps: Array = _touches.values()
	return (ps[0] as Vector2).distance_to(ps[1]) if ps.size() >= 2 else 0.0


func _over_panel(p: Vector2) -> bool:
	if mode == "over":
		return true
	for panel in [log_panel, lab_panel]:
		if panel != null and panel.is_visible_in_tree() and panel.get_global_rect().has_point(p):
			return true
	for c in overlay.get_children():
		if c is DuelViews.CardPicker or c is DuelViews.Dialog:
			return true
	return false


func _zoom_field(factor: float) -> void:
	field.zoom_by(factor)
	_view_save = 0.8


## A tap on the bare board changes your mind, like Cancel. Only a tap well
## clear of every slot, creature and the card panel counts, so a tap that
## just misses a target doesn't throw the choice away.
func _gui_input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
		return
	accept_event()
	if mode != "main" or (pending == "" and sel_card == null and sel_totem == null):
		return
	var p: Vector2 = stage.get_global_transform_with_canvas().affine_inverse() * (get_global_transform_with_canvas() * e.position)
	if detail.visible and Rect2(detail.position, detail.size).has_point(p):
		return
	for side in 2:
		for v in views[side]:
			if Rect2(v.position, v.size).grow(40).has_point(p) or v.body_rect_3d.grow(40).has_point(p):
				return
	if tutor != null and tutor.gating():
		tutor.nudge()   # no backing out of a lesson step
		return
	_back_out()


## One step back: from a target to the Totem's moves, or drop what's picked.
func _back_out() -> void:
	if pending != "":
		_cancel_pending()
	else:
		_clear_selection()
		_hide_detail()
		_clear_actions()
		_show_actions_default()
		_refresh()


func _on_end_turn() -> void:
	if mode == "main":
		if tutor != null and not tutor.allows("end"):
			# the lesson wants something else; moving on to the Clash for an
			# attack it asks for is fine (its steps were written before the phases)
			var kind := DuelHuman.tutor_step_kind(game, me, tutor._current_do())
			if not (kind != "" and game.phase_problem(kind) != "" and game.next_phase(me) != "end"):
				tutor.nudge()
				return
			sfx.play("end_turn")
			_respond({"type": "next"})
			return
		var ends := game.next_phase(me) == "end" or _tutor_wants_end()
		if tutor != null:
			tutor.did("end")
		sfx.play("end_turn")
		_respond({"type": "end"} if ends else {"type": "next"})


func _on_gift() -> void:
	if mode != "main":
		return
	if tutor != null and tutor.gating():
		tutor.nudge()
		return
	var mp: DuelPlayer = game.players[me]
	if mp.favour_ready:
		# full Favour (Phase D): the Gift again, or the god's Demigod, free
		_clear_selection()
		_clear_actions()
		_hide_detail()
		_menu_anchor = Vector2(-1, -1)
		_menu_beside = 0
		_add_note("Your Favour is full: %s. Either one empties it." % game.favour_offer_text(me))
		var g0: String = mp.gift()
		var gp := game.gift_problem(me)
		var gsub := DuelCards.gift_text(g0)
		if g0 == "unbound" and mp.gift_used:
			gsub = "Draw 3 cards and gain 1 Essence."
		_add_action(("%s again" if mp.gift_used else "%s") % Lore.GIFTS[g0].name, gsub if gp == "" else gp, 0, gp == "", _begin_gift, "gift")
		var dg := game.demigod_of(me)
		if dg != "":
			var dp := game.demigod_problem(me)
			_add_action("%s, free" % DuelCards.CARDS[dg].name, DuelCards.card_text(dg).trim_prefix("Descends, then returns to the heavens. ") if dp == "" else dp, 0, dp == "", _begin_demigod, "demigod")
		_show_cancel()
		_set_hint("Full Favour: choose what it brings.")
		_refresh()
		return
	_begin_gift()


func _begin_gift() -> void:
	var prob := game.gift_problem(me)
	if prob != "":
		_toast(prob)
		return
	var ts := game.gift_targets(me)
	var g: String = game.players[me].gift()
	_clear_selection()
	_clear_actions()
	_hide_detail()
	_menu_anchor = Vector2(-1, -1)
	_menu_beside = 0
	_add_note("%s: %s Once per duel." % [Lore.GIFTS[g].name, DuelCards.gift_text(g)])
	if ts.is_empty():
		_add_action("Use %s" % Lore.GIFTS[g].name, DuelCards.gift_text(g), 0, true,
			func() -> void: _respond({"type": "gift"}))
		_show_cancel()
		_set_hint(DuelCards.gift_text(g))
		_refresh()
		return
	pending = "gift"
	targets = ts
	_set_hint("%s: choose one of your Totems." % Lore.GIFTS[g].name)
	_show_cancel()
	_refresh()


## Full Favour spent on the god's Demigod (Phase D).
func _begin_demigod() -> void:
	var prob := game.demigod_problem(me)
	if prob != "":
		_toast(prob)
		return
	var dc := DuelCard.new(-1, game.demigod_of(me), me)
	_clear_actions()
	if not game.summon_needs_target(dc):
		_respond({"type": "demigod"})
		return
	pending = "demigod"
	targets = game.targetable(game.players[rival].totems())
	_set_hint("%s: choose the enemy Totem it strikes." % dc.card_name())
	_show_cancel()
	_refresh()


## Oaths (Phase D): open at the start of the duel and once mid-duel, not in a
## lesson or on the mirrors' board.
func _oaths_open() -> bool:
	return game != null and tutor == null and game.puzzle.is_empty() and not bool(spec.get("no_oaths", false))


func _oath_available() -> bool:
	if not _oaths_open() or game.phase_problem("oath") != "":
		return false
	for id in DuelGame.OATHS:
		if game.oath_problem(me, id) == "":
			return true
	return false


## The three Oaths, as choices.
func _offer_oaths() -> void:
	if mode != "main" or not _oaths_open():
		return
	_clear_selection()
	_clear_actions()
	_hide_detail()
	_menu_anchor = Vector2(-1, -1)
	_menu_beside = 0
	_add_note("Swear an Oath. Keep it and your win is worth more Resonance; it fills %d Favour now. Break it and it costs %d Life." % [DuelRules.oath_favour, DuelRules.oath_life_cost])
	for id in DuelGame.OATHS:
		var prob := game.oath_problem(me, id)
		var oid: String = id
		_add_action(String(DuelGame.OATHS[id].name), game.oath_text(id, me) if prob == "" else prob, 0, prob == "",
			func() -> void: _respond({"type": "oath", "oath": oid}), "oath:" + id)
	_show_cancel()
	_set_hint("Choose an Oath, or cancel.")
	_refresh()


func _on_panel_tapped(panel) -> void:
	if mode == "main" and pending != "" and targets.has(DuelGame.LIFE) and panel == panels[rival]:
		if tutor != null and not tutor.allows("target", DuelGame.LIFE):
			tutor.nudge()
			return
		if tutor != null:
			tutor.did("target", DuelGame.LIFE)
		_resolve(DuelGame.LIFE)
	elif tutor != null and tutor.gating() and mode == "main":
		tutor.nudge()


func _on_hand_tapped(hv) -> void:
	var c: DuelCard = hv.card
	if tutor != null and tutor.gating() and mode == "main" and (sel_card == c or not tutor.allows("card", c)):
		tutor.nudge()
		return
	_show_detail(c.id, {"attrs": game.players[me].attributes(), "cost": _card_cost(c)})
	if mode != "main":
		return
	if tutor != null:
		tutor.did("card", c)
	sfx.play("card_lift")
	if sel_card == c:
		_clear_selection()
		_hide_detail()
		_clear_actions()
		_show_actions_default()
		_refresh()
		return
	_clear_selection()
	sel_card = c
	var p: DuelPlayer = game.players[me]
	_clear_actions()
	_menu_anchor = _hand_anchor(hv)
	_menu_beside = 0
	var ph := game.phase_problem(_play_kind(c))
	if ph != "":
		_add_note(ph)
		_refresh()
		return
	match c.kind():
		"totem":
			if c.is_basic_totem():
				var prob := game.call_problem(me, c)
				var need := game.tributes_needed(c)
				if prob != "":
					_add_note(prob)
				elif need > 0:
					_add_action("Call it with a Tribute", "Give up %s of your Totems on the field for it, as well as its Essence." % ("one" if need == 1 else "two"),
						game.call_cost(me, c), true, func() -> void: _begin_tribute(c, need), "tribute")
					if tutor != null:
						tutor.lesson("tribute", "That %s is a Legend. The big ones don't come for Essence alone: one of your Totems has to step down for it, into the discard, and its light goes into the new one. Choose who you can spare." % c.card_name(), "Tributes", "card:" + c.id)
				else:
					pending = "call"
					pick_side = me
					targets = p.empty_slots()
					_set_hint("Tap an empty slot to call %s." % c.card_name())
					_show_cancel()
					# veiled (Phase C): face down, for one more Essence
					if game.call_cost(me, c) + 1 <= p.essence:
						var reveal := c.def.has("reveal")
						_add_action("Call it veiled", ("Face down, +1 Essence. Its Reveal springs when it's turned up." if reveal else "Face down, +1 Essence: your rival won't know what it is until it fights."),
							game.call_cost(me, c) + 1, true, func() -> void:
								sel_veiled = not sel_veiled
								_set_hint(("Veiled: tap an empty slot to call %s face down." if sel_veiled else "Tap an empty slot to call %s.") % c.card_name())
								if tutor != null:
									tutor.lesson("veiled", "Face down. Your rival sees a card back and nothing else, until it fights, it's struck, or your next Dawn comes. Some have a trick for the moment they're turned up.", "Veiled calls", ""), "veil")
			else:
				var prob := game.ascend_problem(me, c)
				if prob != "":
					_add_note(prob)
				else:
					pending = "ascend"
					targets = game.ascend_targets(me, c)
					_set_hint("Tap %s to Ascend it." % DuelCards.CARDS[c.def.ascends_from].name)
					_show_cancel()
		"rite":
			var prob := game.rite_problem(me, c)
			if prob != "":
				_add_note(prob)
			elif game.rite_needs_target(c):
				pending = "rite"
				targets = game.rite_targets(me, c).filter(func(t): return game.rite_problem(me, c, t) == "")
				_set_hint("Choose a target for %s." % c.card_name())
				_show_cancel()
			else:
				_add_action("Cast %s" % c.card_name(), DuelCards.card_text(c.id), c.cost(), true,
					func() -> void: _respond({"type": "rite", "card": c}))
		"ward":
			var prob := game.ward_problem(me, c)
			if prob != "":
				_add_note(prob)
			else:
				_add_action("Set face down", DuelCards.TRIGGER_TEXT.get(c.def.trigger, "") + ".", c.cost(), true,
					func() -> void: _respond({"type": "ward", "card": c}))
		"relic":
			var prob := game.relic_problem(me, c)
			if prob != "":
				_add_note(prob)
			else:
				pending = "relic"
				targets = game.relic_targets(me)
				_set_hint("Tap the Totem to carry the %s." % c.card_name())
				_show_cancel()
				if tutor != null:
					tutor.lesson("relic", "A Relic. Hang it on one of yours and it stays, as long as the Totem does. Give it to one that'll last: when it falls, the Relic goes down with it.", "Relics", "card:" + c.id)
		"summon":
			var prob := game.summon_problem(me, c)
			if prob != "":
				_add_note(prob)
			elif game.summon_needs_target(c):
				pending = "summon"
				targets = game.players[rival].totems()
				_set_hint("Choose the enemy Totem %s will strike." % c.card_name())
				_show_cancel()
			else:
				_add_action("Call down %s" % c.def.name.get_slice(",", 0), DuelCards.card_text(c.id), game.summon_cost(me, c), true,
					func() -> void: _respond({"type": "summon", "card": c}))
	_refresh()


func _on_slot_tapped(v) -> void:
	if tutor != null and tutor.gating() and mode == "main":
		var ok := false
		if pending == "call" and v.side == me and v.totem == null and targets.has(v.slot):
			ok = tutor.allows("slot", v.slot)
			if ok:
				tutor.did("slot", v.slot)
		elif pending != "" and pending != "call" and pending != "shift" and v.totem != null and targets.has(v.totem):
			ok = tutor.allows("target", v.totem)
			if ok:
				tutor.did("target", v.totem)
		elif pending == "" and v.totem != null and v.side == me:
			ok = tutor.allows("totem", v.totem)
			if ok:
				tutor.did("totem", v.totem)
		if not ok:
			tutor.nudge()
			return
	if v.totem != null and not (pending != "" and targets.has(v.totem)):
		if v.totem.face_down and v.side != me:
			_toast("A veiled Totem: you'll know it when it fights")
		else:
			var opts := {"hp_left": v.totem.hp_left(), "attrs": v.totem.attrs}
			_show_detail(v.totem.id(), opts)
	if mode == "pick_slot":
		if v.side == pick_side and v.totem == null and targets.has(v.slot):
			var s: int = v.slot
			mode = "busy"
			targets = []
			_set_hint("")
			_refresh()
			human.responded.emit(s)
		return
	if mode != "main":
		return
	if pending != "":
		match pending:
			"call":
				if v.side == me and targets.has(v.slot) and (v.totem == null or sel_tributes.has(v.totem)):
					var act := {"type": "call", "card": sel_card, "slot": v.slot}
					if not sel_tributes.is_empty():
						act["tributes"] = sel_tributes.duplicate()
					if sel_veiled:
						act["veiled"] = true
					_respond(act)
					return
			"shift":
				if v.side == me and v.slot != sel_totem.slot:
					_respond({"type": "shift", "totem": sel_totem, "slot": v.slot})
					return
			_:
				if v.totem != null and targets.has(v.totem):
					_resolve(v.totem)
					return
	if v.totem != null and v.side == me:
		_select_totem(v.totem)
	elif pending != "":
		_cancel_pending()


## Choosing the Totems given up for a Tribute call (Phase B), then the slot.
func _begin_tribute(c: DuelCard, need: int) -> void:
	var p: DuelPlayer = game.players[me]
	mode = "busy"
	_clear_actions()
	var picker := DuelViews.CardPicker.new().setup("Give up %s for %s" % ["one Totem" if need == 1 else "two Totems", c.card_name()], p.totems(), need, need)
	picker.cancellable = true
	overlay.add_child(picker)
	var chosen: Array = await picker.done
	picker.queue_free()
	mode = "main"
	if chosen.size() != need:
		_clear_selection()
		_show_actions_default()
		_refresh()
		return
	sel_card = c
	sel_tributes = chosen
	pending = "call"
	pick_side = me
	targets = p.empty_slots()
	for t in chosen:
		targets.append((t as DuelTotem).slot)
	_set_hint("Tap the slot for %s: an empty one, or one you're giving up." % c.card_name())
	_show_cancel()
	_refresh()


## The discard pile, read (Phase B): every card in it, nothing to pick.
func _on_discard_tapped(panel) -> void:
	var p: DuelPlayer = panel.player
	if p == null or p.discard.is_empty() or mode == "busy" or mode == "respond" or mode == "pick_slot":
		return
	sfx.play("ui_select")
	var was := mode
	mode = "busy"
	var picker := DuelViews.CardPicker.new().setup("%s discard (%d)" % [_whose(p.player_name), p.discard.size()], p.discard.duplicate(), 0, 0)
	picker.look_only = true
	overlay.add_child(picker)
	await picker.done
	picker.queue_free()
	mode = was
	_refresh()


func _resolve(target) -> void:
	match pending:
		"ascend":
			_respond({"type": "ascend", "card": sel_card, "target": target})
		"rite":
			_respond({"type": "rite", "card": sel_card, "target": target})
		"summon":
			_respond({"type": "summon", "card": sel_card, "target": target})
		"move":
			_respond({"type": "attack", "attacker": sel_totem, "move": sel_move, "target": target})
		"gift":
			_respond({"type": "gift", "target": target})
		"demigod":
			_respond({"type": "demigod", "target": target})
		"relic":
			_respond({"type": "relic", "card": sel_card, "target": target})


func _cancel_pending() -> void:
	if tutor != null and tutor.gating():
		tutor.nudge()
		return
	sfx.play("ui_back")
	var t := sel_totem
	_clear_selection()
	if t != null:
		_select_totem(t)
		return
	_hide_detail()
	_clear_actions()
	_show_actions_default()
	_refresh()


func _select_totem(t: DuelTotem) -> void:
	sfx.play("ui_select")
	_clear_selection()
	sel_totem = t
	_show_detail(t.id(), {"hp_left": t.hp_left(), "attrs": t.attrs})
	_clear_actions()
	var tv: DuelViews.TotemView = views[me][t.slot]
	if field != null:
		_menu_anchor = _center(tv)
		_menu_beside = -1 if t.slot == 2 else 1
	else:
		_menu_anchor = _center(tv) - Vector2(0, 118)
	var ready := game.ready_problem(me, t)
	var ph := game.phase_problem("attack")
	if ready != "":
		_add_note(ready)
	elif ph != "":
		_add_note(ph)
	for i in t.moves().size():
		var mv := t.move(i)
		var prob := game.move_problem(me, t, i)
		if prob == "" and ph != "":
			prob = ph
		var sub := DuelCardFace.move_detail(mv)
		var dmg := int(mv.get("damage", 0))
		var title: String = mv.name
		if not mv.has("fate") and dmg > 0:
			title += "  —  %d" % (dmg + t.damage_bonus(i) + (DuelRules.wrath_bonus if game.players[me].wrath else 0))
		elif mv.has("fate"):
			title += "  —  d20"
		if mv.has("bond"):
			var pn: String = DuelCards.CARDS[mv.bond].name if DuelCards.CARDS.has(mv.bond) else String(mv.bond)
			sub = "Bond with %s. %s" % [pn, sub]
		elif mv.has("relic"):
			sub = "From the %s. %s" % [DuelCards.CARDS[mv.relic].name, sub]
		elif mv.get("tempered", false):
			sub = "Tempered. %s" % sub
		if ready == "" and prob != "":
			sub = prob
		var idx := i
		_add_action(title, sub, t.move_cost(i), prob == "", func() -> void: _choose_move(t, idx), "move:%d" % i)
	# its stance (Phase A): what a ready Totem does with its turn instead of striking
	if game.phase_problem("stance") == "":
		var offered := false
		for st in ["guard", "rest", "strike"]:
			if st == t.stance or game.stance_problem(me, t, st) != "":
				continue
			var stance := String(st)
			var title := ""
			var sub := ""
			match stance:
				"guard":
					title = "Guard"
					sub = "Turns half of every blow aside until your next turn. It makes no attack."
				"rest":
					title = "Rest"
					sub = "Mends %d now, and gives you %d Essence at your next turn. No attack or Shift this turn." % [DuelRules.rest_heal, DuelRules.rest_essence]
				_:
					continue   # (a stance holds for the turn: there's no going back to Strike)
			_add_action(title, sub, 0, true, func() -> void: _respond({"type": "stance", "totem": t, "stance": stance}), "stance:" + stance)
			offered = true
		if offered and tutor != null:
			tutor.lesson("stance", "Set it to Strike, Guard or Rest. Guard turns half of every blow aside and makes no attack; Rest mends it and pays you an Essence next turn. A choice is only a choice when it costs you something, and here it costs the attack.", "Stances", "")
	if game.phase_problem("shift") == "" and game.shift_problem(me, t, (t.slot + 1) % DuelRules.SLOTS) == "":
		var sc := game.shift_cost(me)
		_add_action("Shift", "Move to another slot (swaps if taken).", sc, true, func() -> void:
			_clear_selection()
			sel_totem = t
			pending = "shift"
			pick_side = me
			targets = range(DuelRules.SLOTS).filter(func(s): return s != t.slot)
			_set_hint("Tap the slot to shift %s to." % t.card_name())
			_clear_actions()
			_menu_anchor = Vector2(-1, -1)
			_menu_beside = 0
			_show_cancel()
			_refresh())
	_set_hint("%s: choose a move." % t.card_name())
	_refresh()


func _choose_move(t: DuelTotem, i: int) -> void:
	if tutor != null and tutor.gating():
		if not tutor.allows("move", i):
			tutor.nudge()
			return
		tutor.did("move", i)
	var ts := game.attack_targets(me, t, i)
	if ts.size() == 1 and ts[0] is String and ts[0] == DuelGame.NONE:
		_respond({"type": "attack", "attacker": t, "move": i, "target": DuelGame.NONE})
		return
	sfx.play("ui_tap")
	sel_totem = t
	sel_move = i
	pending = "move"
	targets = ts
	var life := ts.has(DuelGame.LIFE)
	var tk := t.move_target(i)
	if tk == "ally":
		_set_hint("Choose one of your Totems.")
	elif life:
		_set_hint("Choose a target, or tap %s's Life." % game.players[rival].player_name)
	else:
		_set_hint("Choose an enemy Totem.")
	_clear_actions()
	_menu_anchor = Vector2(-1, -1)
	_menu_beside = 0
	_show_cancel()
	_refresh()


# ============================================================ action list ===

func _clear_actions() -> void:
	for c in actions.get_children():
		actions.remove_child(c)
		c.queue_free()
	actions.size = Vector2.ZERO


func _show_actions_default() -> void:
	_clear_actions()
	_menu_anchor = Vector2(-1, -1)
	_menu_beside = 0
	var p: DuelPlayer = game.players[me]
	var any := false
	for t in p.totems():
		if _has_usable_move(t):
			any = true
	match game.phase:
		"clash":
			_set_hint("The Clash: tap a glowing Totem to attack." if any else "Nothing can attack: move on.")
		"main2":
			_set_hint("A last breath: a Rite or a Shift, or end your turn." if game.can_do_anything_but_end(me) else "Nothing left to do: end your turn.")
		_:
			if game.can_do_anything_but_end(me):
				_set_hint("Tap a glowing card to play it, or a Totem to set its stance." if any else "Tap a glowing card in your hand to play it.")
			elif any:
				_set_hint("Set your stances, or on to the Clash.")
			else:
				_set_hint("Nothing left to do: end your turn.")
			# the Oath at the start of the duel (Phase D): offered on the first turn
			if game.own_turns(me) <= 1 and _oath_available():
				_add_action("Swear an Oath", "Now, and once more mid-duel.", 0, true, _offer_oaths, "oath")


func _show_cancel() -> void:
	_menu_anchor = Vector2(-1, -1)
	_menu_beside = 0
	var b := UITheme.button("Cancel", false, 300)
	b.custom_minimum_size = Vector2(340, 76)
	b.pressed.connect(_cancel_pending)
	actions.add_child(b)
	_queue_place()


func _add_note(t: String) -> void:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UITheme.sb(Color(0.03, 0.035, 0.07, 0.94), UITheme.GOLD_DIM, 14, 2, 14))
	var l := UITheme.label(t, 23, UITheme.TEXT)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(340, 0)
	pc.add_child(l)
	actions.add_child(pc)
	_queue_place()


func _add_action(title: String, sub: String, cost: int, enabled: bool, cb: Callable, key: String = "") -> void:
	var b := ActionButton.new()
	b.title = title
	b.sub = sub
	b.cost = cost
	b.enabled = enabled
	b.set_meta("key", key)
	b.custom_minimum_size = Vector2(384, 96)
	b.pressed.connect(func() -> void:
		if tutor != null and tutor.gating() and not tutor.allows("button", key):
			tutor.nudge()
			return
		if b.enabled:
			sfx.play("ui_tap")
			cb.call()
		else:
			sfx.play("ui_error"))
	actions.add_child(b)
	_queue_place()


func _queue_place() -> void:
	if not _place_queued:
		_place_queued = true
		_place_actions.call_deferred()


## Puts the command buttons above what was tapped (or docks them on the right
## while a target is being picked) and pops them in.
func _place_actions() -> void:
	_place_queued = false
	if actions.get_child_count() == 0:
		return
	actions.size = Vector2.ZERO
	var sz := actions.get_combined_minimum_size()
	actions.size = sz
	if _menu_anchor.x < 0.0:
		# (kept inside the screen's right edge, however wide the buttons are)
		# (and a tall stack rises so it ends above the Gift and the turn button)
		actions.position = Vector2(minf(DOCK_POS.x, DESIGN.x - sz.x - 12.0) + _edge, clampf(820.0 - sz.y, 92.0, DOCK_POS.y))
		actions.pivot_offset = Vector2(sz.x * 0.5, 0)
	elif _menu_beside != 0:
		var x := _menu_anchor.x + 150.0 if _menu_beside > 0 else _menu_anchor.x - 150.0 - sz.x
		x = clampf(x, 432.0, 1572.0 - sz.x)
		var y := clampf(_menu_anchor.y - sz.y * 0.5, 92.0, 770.0 - sz.y)
		actions.position = Vector2(x, y)
		actions.pivot_offset = Vector2(0.0 if _menu_beside > 0 else sz.x, sz.y * 0.5)
	else:
		var x := clampf(_menu_anchor.x - sz.x * 0.5, 432.0, 1572.0 - sz.x)
		var y := maxf(92.0, _menu_anchor.y - sz.y)
		actions.position = Vector2(x, y)
		actions.pivot_offset = Vector2(sz.x * 0.5, sz.y)
	actions.scale = Vector2(0.86, 0.86)
	actions.modulate.a = 0.0
	var tw := actions.create_tween().set_parallel(true)
	tw.tween_property(actions, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(actions, "modulate:a", 1.0, 0.12)


func _show_detail(id: String, opts: Dictionary = {}) -> void:
	var was := detail.visible
	detail.show_card(id, opts)
	detail.visible = true
	if not was:
		detail.position = _detail_pos() + Vector2(60, 0)
		detail.modulate.a = 0.0
		var tw := detail.create_tween().set_parallel(true)
		tw.tween_property(detail, "position", _detail_pos(), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(detail, "modulate:a", 1.0, 0.15)


func _hide_detail() -> void:
	detail.visible = false
	detail.card_id = ""


# =========================================================== human pickers ===

## The response window (Phase A): the rival's action is declared and hasn't
## landed; the answers in hand are offered, with a countdown and "Let it be".
## Options says when to ask: always (any answer held), only when one can be
## paid for, or never.
func begin_respond(event: Dictionary, cards: Array) -> void:
	var affordable := cards.filter(func(c): return game.answer_problem(me, c, event) == "")
	mode = "respond"
	_clear_selection()
	_clear_actions()
	_hide_detail()
	if tutor != null:
		await tutor.lesson("answer", "They've made their move, and it hasn't landed yet. That's your moment: an answer from your hand, or let it be. Six breaths, then it lands.", "Answers", "")
	var strip := RespondStrip.new()
	strip.screen = self
	strip.setup(event, cards, affordable)
	overlay.add_child(strip)
	sfx.play("ui_select")
	var pick = await strip.done
	strip.queue_free()
	_respond(pick)


## Whether to ask the player at all (Options: always when an answer is held,
## only when one can be paid for, or never). Asked before the strip, so a
## "no" never has to be signalled to a controller that isn't listening yet.
func wants_respond(event: Dictionary, cards: Array) -> bool:
	if _watching():
		return false
	var setting := String(Game.settings.get("respond", "can"))
	if setting == "never":
		return false
	if setting == "can":
		return cards.any(func(c): return game.answer_problem(me, c, event) == "")
	return not cards.is_empty()


## "Corin's Cinderpup attacks your Brookfin": what's being answered.
func event_text(ev: Dictionary) -> String:
	var kind := String(ev.get("type", ""))
	var by := int(ev.get("by", rival))
	if kind == "attack" and ev.get("attacker") is DuelTotem:
		by = (ev.attacker as DuelTotem).owner
	var who: String = "You" if by == me else game.players[by].player_name
	var whose_: String = "your" if by == me else "%s's" % game.players[by].player_name
	match kind:
		"attack":
			var tg = ev.get("target")
			var at := "your Life" if by != me else "%s Life" % _whose(game.players[rival].player_name).to_lower()
			if tg is DuelTotem:
				at = ("your %s" if tg.owner == me else "%s %s" % [_whose(game.players[tg.owner].player_name).to_lower(), "%s"]) % tg.card_name() if tg.owner == me else "%s %s" % [_whose(game.players[tg.owner].player_name), tg.card_name()]
			return "%s %s attacks %s" % [whose_.capitalize() if by != me else "Your", (ev.attacker as DuelTotem).card_name(), at]
		"rite":
			var c: DuelCard = ev.get("card")
			if ev.get("answer", false):
				return "%s answer%s with %s" % [who, "" if by == me else "s", c.card_name()]
			return "%s call%s down %s" % [who, "" if by == me else "s", c.card_name()] if ev.get("summon", false) else "%s cast%s %s" % [who, "" if by == me else "s", c.card_name()]
		"call":
			return "%s call%s %s" % [who, "" if by == me else "s", (ev.called as DuelTotem).card_name()]
		"ward":
			return "%s set%s a Ward face down" % [who, "" if by == me else "s"]
		"ward_spring":
			return "%s Ward springs: %s" % [whose_.capitalize() if by != me else "Your", (ev.card as DuelCard).card_name()]
	return ""


func begin_pick_cards(prompt: String, items: Array, min_n: int, max_n: int, context: Dictionary) -> void:
	mode = "busy"
	var picker := DuelViews.CardPicker.new().setup(prompt, items, min_n, max_n, context.get("wards", []))
	overlay.add_child(picker)
	var chosen: Array = await picker.done
	picker.queue_free()
	human.responded.emit(chosen)


func begin_pick_slot(prompt: String, slots: Array, context: Dictionary) -> void:
	mode = "pick_slot"
	pick_side = rival if context.get("reason", "") == "move_foe" else me
	targets = slots
	_set_hint(prompt)
	_refresh()


func begin_reroll(info: Dictionary) -> void:
	mode = "busy"
	var b: Dictionary = info.bands[info.index]
	var res := DuelCards.outcome_text(int(b.get("damage", 0)), b.get("effects", []), "foe", b.get("text", "Miss"))
	var p: DuelPlayer = game.players[me]
	var d := DuelViews.Dialog.new().setup("You rolled %d: %s.\nSpend Fortune to re-roll? (%d left)" % [int(info.total), res, p.fortune_left],
		"Re-roll", "Keep it")
	overlay.add_child(d)
	var yes: bool = await d.answered
	d.queue_free()
	human.responded.emit(yes)


func begin_scry(card: DuelCard) -> void:
	mode = "busy"
	var d := DuelViews.Dialog.new().setup("Insight shows the top card of your deck.", "Keep it on top", "Send it to the bottom", card.id)
	overlay.add_child(d)
	var yes: bool = await d.answered
	d.queue_free()
	human.responded.emit(yes)


## Shows what the computer is about to do, so its turn can be followed.
func preview_ai_action(pi: int, a: Dictionary) -> void:
	match a.get("type", ""):
		"attack":
			var t: DuelTotem = a.attacker
			var v: DuelViews.TotemView = views[pi][t.slot]
			v.highlight = "selected"
			var tg = a.get("target")
			if tg is DuelTotem:
				views[tg.owner][tg.slot].highlight = "target"
			elif tg is String and tg == DuelGame.LIFE:
				panels[1 - pi].targetable = true
			await pause(0.35)
			panels[1 - pi].targetable = false
		"call", "rite", "summon", "ascend", "answer", "relic":
			if bool(a.get("veiled", false)):
				await pause(0.35)   # (a veiled call shows nothing)
				return
			var c: DuelCard = a.card
			_show_detail(c.id, {"cost": c.cost()})
			await pause(0.35)


# ================================================================ effects ===

func _view(t: DuelTotem) -> DuelViews.TotemView:
	return views[t.owner][t.slot]


func _center(v: Control) -> Vector2:
	if v is DuelViews.TotemView:
		if field != null:
			return field.body_stage(v.side, v.slot)
		return v.position + v.body_point()
	return v.position + v.size * Vector2(0.5, 0.36)


func _foot(v: DuelViews.TotemView) -> Vector2:
	if field != null:
		return field.foot_stage(v.side, v.slot)
	return v.position + v.foot_point()


## 3D positions for the field's effects (zero when the field is 2D).
func _body3(t: DuelTotem) -> Vector3:
	return field.body_world(t.owner, t.slot)


func _foot3(t: DuelTotem) -> Vector3:
	return field.foot_world(t.owner, t.slot)


## Plays a model clip on a Totem's slot (nothing happens for cut-outs).
func _clip(t: DuelTotem, want: String, speed_scale: float = 1.0) -> float:
	if field == null or t == null:
		return 0.0
	return field.play_clip(t.owner, t.slot, want, speed_scale)


## Where Life damage numbers pop: just right of the Life plate.
func _life_number_pos(pi: int) -> Vector2:
	var p: DuelViews.PlayerPanel = panels[pi]
	return p.position + Vector2(p.size.x + 120, 96)


func _life_center(pi: int) -> Vector2:
	var p: DuelViews.PlayerPanel = panels[pi]
	return p.position + p.life_rect().get_center()


func fx_start() -> void:
	if not _started and not game.puzzle.is_empty():
		# a set board (the Trial of Light) has no roll for the first turn
		_started = true
		await _opening_banners()
	await pause(0.1)


## "DUEL!", then the Law it's fought under and the story duel's own rule
## (spec.rule = [name, what it does]: Corin's Showboat in the Lantern Duel,
## Chapter 1's four). The Law and the rule are read at the player's own
## pace: each stays up until it's tapped (or E, Space, Enter, a pad's A),
## since a rule is a thing to know for the whole duel (Gary, 23 October:
## "when the battle starts and it shows Showboat you don't have long to read
## it"). Both are on the duel's Menu for the rest of the duel too.
func _opening_banners() -> void:
	sfx.play("duel_start")
	await _banner("DUEL!", UITheme.GOLD, 0.9, 130, "", "Empty your rival's Life to win.")
	if game.law != "":
		var god: String = game.law if Lore.GODS.has(game.law) else ""
		await _banner(DuelLaws.law_name(game.law).to_upper(), UITheme.GOLD, 1.6, 72, god, DuelLaws.describe(game.law), true)
	var rule: Array = spec.get("rule", [])
	if rule.size() >= 2:
		await _banner(String(rule[0]).to_upper(), UITheme.GOLD, 2.2, 72, "", "Duel rule: " + String(rule[1]), true)


## A banner is up waiting for a tap (the Law or the duel's rule).
var banner_waiting := false
signal _banner_tapped


## Moves a waiting banner on (a tap on the screen, the interact key, or a
## test driving the duel).
func tap_banner() -> void:
	if banner_waiting:
		_banner_tapped.emit()


## Both duellists roll for the first turn, big in the middle of the Circle.
## In the Lantern Duel Bram's intro ends with "tap the die", and the roll
## waits for that tap.
func fx_rolloff(r0: int, r1: int) -> void:
	var names: Array = spec.get("names", ["You", "Rival"])
	var rv := DuelViews.RolloffView.new()
	rv.names = [names[me] if _watching() else "You", names[rival]]
	rv.position = Vector2(FIELD_CX - 560, 300)
	rv.size = Vector2(1120, 400)
	rv.die_tapped.connect(_on_die_tapped)
	fx_layer.add_child(rv)
	_rolloff = rv
	if not _started:
		_started = true
		# (a story duel's rule is read on its own, the dice out of the way)
		rv.visible = not spec.has("rule")
		await _opening_banners()
		rv.visible = true
		if tutor != null:
			rv.waiting = true
			await tutor.event("intro")   # ends with the player tapping their die
			rv.waiting = false
	var rattle := Sfx.has_file("dice_roll")
	if rattle:
		sfx.play("dice_roll")
	var steps := int(16 / maxf(1.0, speed * 0.7))
	for k in steps:
		rv.faces = [randi_range(1, 20), randi_range(1, 20)]
		rv.spin += 0.5
		if not rattle:
			sfx.play("click", 1.3 + randf() * 0.3)
		await pause(0.05)
	rv.faces = [r0 if me == 0 else r1, r1 if me == 0 else r0]
	rv.landed = true
	sfx.play("dice_land")
	for i in 2:
		var c := rv.position + rv.die_center(i)
		DuelFX.flash(fx_layer, c, Color(0.7, 0.6, 1.0), 200.0, 0.5 / speed)
		DuelFX.burst(fx_layer, c, Color(0.7, 0.6, 1.0), 14, 420.0, 12.0, 0.6, Vector2.ZERO, 180.0, Vector2.UP, speed)
	await pause(1.1)
	_rolloff = null
	var tw := rv.create_tween()
	tw.tween_property(rv, "modulate:a", 0.0, 0.2 / speed)
	tw.tween_callback(rv.queue_free)
	if r0 == r1:
		await _banner("A TIE", UITheme.TEXT, 0.7, 72, "", "Both rolled %d. Roll again!" % r0)
		return
	var first: String = names[0] if r0 > r1 else names[1]
	var head := "YOU GO FIRST" if first == "You" else "%s GOES FIRST" % first.to_upper()
	await _banner(head, UITheme.GOLD, 1.0, 72, "", "Fate roll:  %s %d   ·   %s %d" % [names[0], r0, names[1], r1])


## The player tapped the roll-off dice (`on_die`: on their own die).
func _on_die_tapped(on_die: bool) -> void:
	if tutor == null or not tutor.gating():
		return
	if on_die and tutor.allows("die"):
		sfx.play("ui_select")
		tutor.did("die")
	else:
		tutor.nudge()


## Lessons for things on the table for the first time, before the player
## acts: an Ascension card they could play now.
func lessons_at_main() -> void:
	if tutor == null or game == null or game.over:
		return
	# the tiers, the first time a card above Spark is in the hand
	for c in game.players[me].hand:
		var card: DuelCard = c
		if card.tier() >= 2 and card.tier() < Lore.TIER_NAMES.size() and not Game.learned("tier"):
			await tutor.lesson("tier", "That %s is a %s: the %s of seven tiers, Spark to Divine. Each tier up costs more to call and hits harder, and a deck carries fewer of them: four Sparks of a kind, one Relic. The high ones aren't better. They're later." % [
				card.card_name(), Lore.TIER_NAMES[card.tier()], ["", "first", "second", "third", "fourth", "fifth", "sixth", "seventh"][card.tier()]], "Tiers", "card:" + card.id)
			break
	for c in game.players[me].hand:
		var card: DuelCard = c
		if card.is_summon():
			await tutor.lesson("summon", "That %s is a Summon. Not a Totem: a piece of something far bigger. It costs %d Essence, does one great thing, and goes back where it came from. Save it for when it counts." % [
				card.card_name(), game.summon_cost(me, card)], "Summons", "card:" + card.id)
			return
		if card.kind() == "totem" and not card.is_basic_totem() and game.ascend_problem(me, card) == "":
			var from_name: String = DuelCards.CARDS[card.def.ascends_from].name
			await tutor.lesson("ascend", "That %s is an Ascension: %s, grown up. Play it on your %s and it steps into the same slot, bigger, with everything it had. It costs Essence, so think about when." % [
				card.card_name(), from_name, from_name], "Ascension", "card:" + card.id)
			return


func fx_turn(pi: int) -> void:
	_hide_detail()
	_strike = {}
	if field != null:
		field.cam_home(0.8 / speed)
	_refresh()
	sfx.play("turn_mine" if pi == me else "turn_rival")
	var t := "YOUR TURN" if pi == me and not _watching() else ("%s turn" % _whose(game.players[pi].player_name)).to_upper()
	await _banner(t, UITheme.MINE if pi == me else UITheme.THEIRS, 0.6, 96, "", "TURN %d" % game.turn)
	if pi == me:
		sfx.play("essence_gain")
		if tutor != null:
			tutor.begin_turn()
		if _my_turns == 0:
			_coach("start")


## The turn moves into a phase (Phase A): the band, and a word for the player's own Clash.
func fx_phase(pi: int, p_phase: String) -> void:
	if phase_band != null:
		phase_band.set_phase(p_phase, pi == me)
	_refresh()
	if pi == me and not _watching():
		if p_phase == "clash" or p_phase == "main2":
			sfx.play("ui_select")
			_toast("THE CLASH" if p_phase == "clash" else "MAIN II")
		if p_phase == "main" and tutor != null and game.turn > 1:
			await tutor.lesson("phases", "A turn has its parts, and the band under my plate keeps count: Dawn, the draw, then the Main for calling, setting and casting; the Clash for the blows; a last breath for a Rite or a Shift; then Dusk. Nothing happens out of its turn.", "The turn", "")


## A Totem takes a stance (Phase A): its badge, its pose on the field.
func fx_stance(t: DuelTotem) -> void:
	_refresh()
	var v := _view(t)
	v.flash = 0.5
	v.flash_color = Color("c7d2ff") if t.stance == "guard" else (Color("9fe8c0") if t.stance == "rest" else Color(1, 1, 1))
	if field != null:
		field.set_stance(t.owner, t.slot, t.stance)
	sfx.play("shift")
	await pause(0.25)


## An answer is played (Phase A): the card shown, a link of light from the
## answerer's plate to what it answers.
func fx_answer(pi: int, card: DuelCard, event: Dictionary, _depth: int) -> void:
	sfx.play("ward_spring")
	_refresh()
	_show_detail(card.id, {"cost": card.cost()})
	var who := "You answer" if pi == me else "%s answers" % game.players[pi].player_name
	_toast("%s with %s" % [who, card.card_name()])
	var from := _life_center(pi)
	var to := _event_point(event)
	DuelFX.lightning(fx_layer, from, to, DuelFX.light(card.element()), 0.55, 7.0)
	if pi != me and tutor != null:
		await tutor.lesson("answered", "Answered. A card played against yours in the moment between the saying and the doing. You can do the same, when you hold one.", "Answers", "")
	await pause(0.7)


## A Relic hung on a Totem (Phase C).
func fx_relic(t: DuelTotem, card: DuelCard) -> void:
	var v := _view(t)
	sfx.play("ascend")
	DuelFX.flash(fx_layer, _center(v), DuelCardFace.RELIC_COL, 120.0, 0.4)
	DuelFX.rise(fx_layer, _foot(v), DuelCardFace.RELIC_COL, 120.0, 22)
	_toast("%s carries the %s" % [t.card_name(), card.card_name()])
	_refresh()
	await pause(0.5)


## A veiled Totem turns face up (Phase C).
func fx_reveal(t: DuelTotem) -> void:
	_refresh()
	var v := _view(t)
	sfx.play("call_totem")
	DuelFX.shockwave(fx_layer, _foot(v), DuelFX.light(t.element()), 150.0, 0.45)
	_toast("Revealed: %s" % t.card_name())
	if tutor != null and t.owner != me:
		await tutor.lesson("revealed", "There. That's what was under the card. Something called face down shows itself when it fights, when it's struck, or at its owner's Dawn, and a few have a trick for that moment.", "Veiled calls", "")
	await pause(0.5)


## Two bonded Totems (Phase C): a thread of light between them.
func fx_bond(t: DuelTotem, partner: DuelTotem) -> void:
	var a := _center(_view(t))
	var b := _center(_view(partner))
	DuelFX.lightning(fx_layer, a, b, UITheme.GOLD, 0.5, 6.0)
	_toast("Bonded: %s" % String(t.bond.get("name", "")))
	if tutor != null and t.owner == me:
		tutor.lesson("bond", "Those two know each other. Some Totems fight better side by side: while both stand, they share a move, or something more. Keep the pair together.", "Bonds", "")


## A Totem given up for a Tribute call: its light rises and goes.
## The ground's name and rule, under the turn count (Phase D).
func _arena_line() -> String:
	if game == null:
		return ""
	var a := game.arena_now()
	if a == "":
		return ""
	var nm := a.to_upper()
	if not game.terrain.is_empty():
		var left := int(game.terrain.left)
		nm += "  ·  %d TURN%s LEFT" % [left, "" if left == 1 else "S"]
	return "%s\n%s" % [nm, game.arena_rule_text()]


## The ground turns (Phase D): a Terrain Rite takes the Circle, or one fades.
func fx_terrain(a: String, why: String) -> void:
	var look := a if a != "" else _arena_name
	var col: Color = ARENA_MOTES.get(look, UITheme.GOLD)
	sfx.play("ascend")
	if field != null:
		field.change_arena(look, why != "fade")
	elif _arena != null:
		_arena.fade_to(DuelArt.arena(look))
	if _arena != null:
		_arena.mote_col = col
	DuelFX.shockwave(fx_layer, Vector2(FIELD_CX, 476), col, 520.0, 0.8)
	if why == "fade":
		_toast("The ground fades: %s again" % look.capitalize())
	else:
		_toast("The ground turns: %s" % look.capitalize())
	_refresh()
	await pause(1.0)
	if tutor != null and why != "fade":
		await tutor.lesson("terrain", "The ground's changed under us. A Terrain Rite turns the Circle into another place for three turns, and that place's rule with it. Read the corner: it says what the ground does now.", "The Circle", "")


## The Circle's own rule acts (Phase D).
func fx_arena_rule(pi: int, rule: String, text: String) -> void:
	var col: Color = ARENA_MOTES.get(rule, UITheme.GOLD)
	if field != null:
		field.floor_wave(Vector3(0, 0.05, 0), col, 6.0, 0.6)
	DuelViews.float_text(fx_layer, Vector2(FIELD_CX, 420), "%s: %s" % [rule.capitalize(), text], col, 28, 1.4)
	if tutor != null:
		await tutor.lesson("arena_rule", "Every Circle has a rule of its own, all duel long, for both of you. It's written in the corner under the turn. Ashford's green has none: that's why we learn there.", "The Circle", "")
	await pause(0.45)


## A Continuous Rite takes its place on its side, or leaves it (Phase D).
func fx_continuous(pi: int, card: DuelCard, gone: bool) -> void:
	_refresh()
	var wz: DuelViews.WardZone = ward_zones[pi]
	var j := maxi(0, game.players[pi].continuous.find(card))
	var at: Vector2 = wz.position + (wz.standing_rect(j).get_center() if not gone else wz.card_rect(0).get_center())
	var col := DuelViews.WardZone.CONT_COL
	sfx.play("ward_set" if not gone else "ward_spring")
	DuelFX.flash(fx_layer, at, col, 90.0, 0.35)
	if not gone:
		DuelFX.rise(fx_layer, at, col, 70.0, 16)
		_toast("%s stands" % card.card_name())
	else:
		_toast("%s is gone" % card.card_name())
	await pause(0.5)
	if tutor != null and not gone:
		await tutor.lesson("continuous", "That one doesn't go to the discard. A Continuous Rite stands beside the Wards and keeps working, two a side, till it's unbound or a third pushes the oldest out. Tap it to read it.", "Continuous Rites", "")


## Favour fills to the brim (Phase D).
func fx_favour(pi: int, full: bool) -> void:
	_refresh()
	if not full:
		return
	var p: DuelPlayer = game.players[pi]
	var pan: DuelViews.PlayerPanel = panels[pi]
	var at := pan.position + pan.portrait_center()
	var col: Color = DuelFX.light(Lore.GODS[p.patron()].element) if p.patron() != "" and Lore.GODS.has(p.patron()) else UITheme.GOLD
	sfx.play("gift")
	DuelFX.flash(fx_layer, at, col, 140.0, 0.45)
	DuelFX.shockwave(fx_layer, at, col, 170.0, 0.5)
	DuelFX.rise(fx_layer, at, col, 90.0, 20)
	_toast("%s Favour is full" % ("Your" if pi == me else _whose(p.player_name)))
	await pause(0.6)
	if tutor != null and pi == me:
		await tutor.lesson("favour", "Feel that? Your god's noticed you. Favour fills as you play your god's element and follow its way; full, it opens your Gift again, or brings your god's Demigod down for nothing. Tap the Gift.", "Favour", "")
	elif tutor != null:
		await tutor.lesson("favour_rival", "Their god's noticed them: the ring round their seal is full. That's a second Gift coming, or worse. Be ready.", "Favour", "")


## An Oath is sworn, kept or broken (Phase D).
func fx_oath(pi: int, oath: String, state: String) -> void:
	_refresh()
	var p: DuelPlayer = game.players[pi]
	var pan: DuelViews.PlayerPanel = panels[pi]
	var at := pan.position + pan.portrait_center() + Vector2(0, 60)
	match state:
		"sworn":
			sfx.play("ascend")
			DuelFX.flash(fx_layer, at, UITheme.GOLD, 110.0, 0.4)
			_toast("%s swears the %s" % ["You" if pi == me else p.player_name, DuelGame.OATHS[oath].name])
			if pi == me:
				story_bark("my_oath")   # (a story rival's line for it, if the story gives one)
			await pause(0.7)
			if tutor != null:
				await tutor.lesson("oath", "An Oath. Words said in the Circle bind you: keep it and the win's worth more; break it and it takes Life from you.", "Oaths", "")
		"broken":
			sfx.play("life_hit")
			DuelFX.flash(fx_layer, at, Color("ff5050"), 110.0, 0.4)
			_toast("%s Oath is broken" % ("Your" if pi == me else _whose(p.player_name)))
			if pi == me:
				story_bark("my_oath_broken")
			elif pi == rival:
				story_bark("rival_oath_broken")
			await pause(0.6)


func fx_tribute(t: DuelTotem, card: DuelCard) -> void:
	var v := _view(t)
	var at := _center(v)
	sfx.play("ascend")
	DuelFX.rise(fx_layer, at, DuelFX.light(t.element()), 140.0, 34)
	DuelFX.flash(fx_layer, at, DuelFX.light(card.element()), 150.0, 0.4)
	_toast("%s steps down for %s" % [t.card_name(), card.card_name()])
	await pause(0.6)
	_refresh()


## An Echo answers from the discard.
func fx_echo(pi: int, card: DuelCard) -> void:
	sfx.play("ward_spring")
	_show_detail(card.id, {})
	var at: Vector2 = panels[pi].position + panels[pi].discard_rect.get_center()
	DuelFX.rise(fx_layer, at, DuelFX.light(card.element()), 90.0, 22)
	_toast("Echo: %s" % card.card_name())
	if tutor != null:
		await tutor.lesson("echo", "An Echo. A fallen Totem doesn't always go quiet: some answer once from the discard, when another of yours falls. Read what lies in the discard. Tap it on the plate.", "Echoes", "")
	await pause(0.6)


## A search: the deck fans out, and the card is found.
func fx_search(pi: int, cards: Array) -> void:
	sfx.play("shuffle")
	var base: Vector2 = panels[pi].position + Vector2(220, 160)
	var n := mini(7, maxi(3, cards.size() + 2))
	var fan: Array = []
	for i in n:
		var back := Panel.new()
		back.add_theme_stylebox_override("panel", UITheme.sb(Color("1c2140"), UITheme.GOLD_DIM, 8, 2, 0))
		back.size = Vector2(70, 98)
		back.pivot_offset = Vector2(35, 98)
		back.position = base - back.pivot_offset
		back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fx_layer.add_child(back)
		fan.append(back)
		var tw := back.create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(back, "rotation", lerpf(-0.6, 0.6, float(i) / maxf(1.0, n - 1.0)), 0.35 / speed)
		tw.tween_property(back, "position:y", back.position.y - 30.0, 0.35 / speed)
	await pause(0.7)
	for b in fan:
		var tw := (b as Panel).create_tween()
		tw.tween_property(b, "modulate:a", 0.0, 0.25 / speed)
		tw.tween_callback((b as Panel).queue_free)
	if tutor != null and pi == me:
		await tutor.lesson("search", "A search. A deck that can find its own pieces plays less by luck. Keep a few of those in, and the right card comes when you need it.", "Searches", "")


## A Totem card back from the discard (to the hand, or rising to the field).
func fx_revive(pi: int, card: DuelCard) -> void:
	sfx.play("call_totem")
	var at: Vector2 = panels[pi].position + panels[pi].discard_rect.get_center()
	DuelFX.rise(fx_layer, at, DuelFX.light(card.element()), 110.0, 26)
	_toast("%s returns" % card.card_name())
	if tutor != null and (card.def.get("keywords", []) as Array).has("rekindle"):
		await tutor.lesson("rekindle", "That one rekindles. Once a duel, at its owner's Dawn, it climbs out of the discard with half its strength. Put it down twice and it stays down.", "Echoes", "")
	await pause(0.4)


func fx_chain_done(_chain: Array, _res: Dictionary) -> void:
	_hide_detail()
	_refresh()


## Where on the screen an event is: the attacker, the caster's plate, a Ward zone.
func _event_point(ev: Dictionary) -> Vector2:
	match String(ev.get("type", "")):
		"attack":
			if ev.get("attacker") is DuelTotem:
				return _center(_view(ev.attacker))
		"call":
			if ev.get("called") is DuelTotem:
				return _center(_view(ev.called))
		"ward_spring":
			var by := int(ev.get("by", rival))
			var wz: DuelViews.WardZone = ward_zones[by]
			return wz.position + wz.size * 0.5
	return _life_center(int(ev.get("by", rival)))


func fx_draw(pi: int, cards: Array) -> void:
	_refresh()
	if pi == me:
		sfx.play("card_draw")
		for hv in hand_views:
			if cards.has(hv.card):
				hv.position = Vector2(1560 + _edge, 1100)
				hv.rotation = 0.6
		_layout_hand()
		await pause(0.3)


func fx_call(t: DuelTotem) -> void:
	_hide_detail()
	if tutor != null and t.has_keyword("loyal") and game.current != t.owner:
		tutor.lesson("loyal", "Loyal. When one of its own falls, it comes out of the hand by itself, free, and takes the empty place. Hounds are like that.", "Echoes", "")
	if t.owner == me:
		_coach("essence")
	var hidden: bool = t.face_down and t.owner != me   # a veiled call keeps its secret (Phase C)
	if not hidden and SummonVideo.pick(t.id()) != "":
		await SummonVideo.play(overlay, t.id())
	var v := _view(t)
	v.set_totem(t)
	v.fade = 0.0
	v.pop = 0.3
	var foot := _foot(v)
	var col := DuelFX.light(t.element())
	sfx.play("card_fly")
	_layout_hand()
	var from := Vector2(FIELD_CX, HAND_Y + 80) if t.owner == me else Vector2(FIELD_CX, 30)
	if field != null:
		field.cam_focus(_foot3(t), 0.3, 0.4 / speed)
	await _fly_card("" if hidden else t.id(), from, foot - Vector2(0, 30), 0.3 / speed)
	sfx.play("call_totem")
	if field != null:
		field.pillar(_foot3(t), col, 5.5, 1.8, 0.9 / speed)
		field.floor_wave(_foot3(t), col, 3.6, 0.6 / speed)
		field.burst(_foot3(t) + Vector3(0, 0.3, 0), col, 40, 7.0, 0.8)
		DuelFX.flash(fx_layer, foot, col, 200.0, 0.4 / speed)
	else:
		DuelFX.flash(fx_layer, foot, col, 260.0 * v.depth, 0.5 / speed)
		DuelFX.shockwave(fx_layer, foot, col, 240.0 * v.depth, 0.55 / speed, 0.3, 9.0)
		DuelFX.pillar(fx_layer, foot, col, 190.0 * v.depth, 560.0 * v.depth, 0.8 / speed)
		DuelFX.burst(fx_layer, foot - Vector2(0, 30), col, 40, 520.0, 15.0, 0.8, Vector2(0, 320), 70.0, Vector2.UP, speed)
	v.flash = 1.0
	v.flash_color = Color(1, 1, 0.9)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(v, "pop", 1.0, 0.45 / speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(v, "fade", 1.0, 0.18 / speed)
	tw.tween_property(v, "flash", 0.0, 0.7 / speed)
	if t.tier() >= 3 and not hidden:
		shake(9.0)
	var clip_len := _clip(t, "summon", speed)
	await pause(maxf(0.5, clip_len * 0.8))
	if field != null:
		field.cam_home(0.5 / speed)
	if tutor != null and t.owner == rival and not hidden:
		await tutor.event("rival_call")
		if t.has_keyword("guardian"):
			await tutor.lesson("guardian", "That's a Guardian. Everything goes through it first. Break it, or go nowhere.", "Guardians", "foe:" + t.id())


func fx_ascend(t: DuelTotem) -> void:
	_hide_detail()
	var v := _view(t)
	v.set_totem(t)
	var foot := _foot(v)
	var c := _center(v)
	sfx.play("ascend")
	_layout_hand()
	if field != null:
		field.cam_focus(_foot3(t), 0.45, 0.5 / speed)
		field.pillar(_foot3(t), UITheme.GOLD, 8.0, 2.4, 1.2 / speed)
		field.rise(_foot3(t), UITheme.GOLD, 70, 1.4, 1.6)
	else:
		DuelFX.pillar(fx_layer, foot, UITheme.GOLD, 240.0 * v.depth, 760.0 * v.depth, 1.0 / speed)
		DuelFX.rise(fx_layer, foot - Vector2(0, 20), UITheme.GOLD, 220.0 * v.depth, 60, 1.2, speed)
	await pause(0.25)
	DuelFX.flash(fx_layer, c, Color(1, 0.95, 0.8), 330.0 * v.depth, 0.6 / speed)
	if field != null:
		field.floor_wave(_foot3(t), UITheme.GOLD, 5.0, 0.7 / speed)
		field.burst(_body3(t), UITheme.GOLD, 60, 9.0, 1.0, 0.14, 0.0)
		field.flash_light(_body3(t), Color(1, 0.95, 0.8), 10.0, 0.6 / speed)
	else:
		DuelFX.shockwave(fx_layer, foot, UITheme.GOLD, 300.0 * v.depth, 0.6 / speed, 0.32, 12.0)
		DuelFX.burst(fx_layer, c, UITheme.GOLD, 50, 700.0, 18.0, 0.9, Vector2(0, 200), 180.0, Vector2.UP, speed)
	shake(10.0)
	punch(c, 0.04)
	v.flash = 1.0
	v.flash_color = UITheme.GOLD
	DuelFX.number(fx_layer, c + Vector2(0, -150 * v.depth), "ASCENDED!", UITheme.GOLD, 64, 1.3 / speed)
	_clip(t, "summon", speed)
	v.pop = 1.25
	var tw := create_tween().set_parallel(true)
	tw.tween_property(v, "pop", 1.0, 0.55 / speed).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(v, "flash", 0.0, 0.8 / speed)
	await pause(0.7)
	if field != null:
		field.cam_home(0.6 / speed)


func fx_rite(pi: int, card: DuelCard, target) -> void:
	_hide_detail()
	sfx.play("card_fly")
	_layout_hand()
	var from := Vector2(FIELD_CX, HAND_Y + 80) if pi == me else Vector2(FIELD_CX, 30)
	var c := await _show_card_big(card.id, "RITE", DuelCardFace.RITE_COL, 0.75 if pi != me else 0.45, from)
	sfx.play("rite_cast")
	var col := DuelFX.light(card.element())
	if target is DuelTotem:
		var to := _center(_view(target))
		var b := DuelFX.projectile(fx_layer, c, to, col, 0.3 / speed, 30.0, 60.0)
		await b.arrived
		DuelFX.flash(fx_layer, to, col, 180.0, 0.4 / speed)
		if field != null:
			field.burst(_body3(target), col, 30, 5.0, 0.6, 0.1, 0.0)
			field.flash_light(_body3(target), col, 6.0, 0.4 / speed)
		else:
			DuelFX.burst(fx_layer, to, col, 22, 420.0, 14.0, 0.6, Vector2(0, 200), 180.0, Vector2.UP, speed)
	else:
		DuelFX.flash(fx_layer, c, col, 260.0, 0.45 / speed)
		DuelFX.burst(fx_layer, c, col, 30, 520.0, 14.0, 0.7, Vector2(0, 200), 180.0, Vector2.UP, speed)
	await pause(0.1)
	if tutor != null:
		await tutor.lesson("rite", ("That was a Rite of mine." if pi == rival and _bram_rival() else ("That was a Rite." if pi == rival else "A Rite.")) + " Cast once and gone, and it answers at once. The Essence it costs is Essence you're not calling a Totem with: spend it when the board asks for it, not because it's in your hand.", "Rites")
	if tutor != null and pi == rival:
		await tutor.event("rival_rite")


func fx_ward_set(pi: int, _card: DuelCard) -> void:
	_coach("ward")
	sfx.play("card_fly")
	get_tree().create_timer(0.3 / speed).timeout.connect(func() -> void: sfx.play("ward_set"))
	_layout_hand()
	var wz: DuelViews.WardZone = ward_zones[pi]
	var wr: Rect2 = wz.card_rect(maxi(0, game.players[pi].wards.size() - 1))
	var to: Vector2 = wz.position + wr.get_center()
	var from := Vector2(FIELD_CX, HAND_Y + 80) if pi == me else Vector2(FIELD_CX, 30)
	await _fly_card("", from, to, 0.3 / speed, Vector2(0.44, 0.44))
	DuelFX.flash(fx_layer, to, DuelCardFace.WARD_COL, 140.0, 0.5 / speed)
	DuelFX.burst(fx_layer, to, Color("d9a6f0"), 16, 260.0, 10.0, 0.5, Vector2.ZERO, 180.0, Vector2.UP, speed)
	await pause(0.15)
	if tutor != null:
		if pi == rival:
			var ws := ("That's my Ward, face down, so you can't read it." if _bram_rival() else "A Ward. Face down, so you can't read it.") + " It springs by itself when the right thing happens: a Totem called, a Rite cast, a hit coming in. Mind what you give it."
			await tutor.lesson("ward_set", ws, "Wards", "ward:rival")
		else:
			await tutor.lesson("ward_mine", "Yours is down. It'll spring on its own when its moment comes. Set them early, while they're cheap.", "Wards", "ward:mine")


func fx_ward_spring(pi: int, card: DuelCard, _ctx: Dictionary) -> void:
	sfx.play("ward_spring")
	var wz: DuelViews.WardZone = ward_zones[pi]
	var from: Vector2 = wz.position + wz.card_rect(0).get_center()
	var c := await _show_card_big(card.id, "WARD!", DuelCardFace.WARD_COL, 0.9, from)
	DuelFX.shockwave(fx_layer, c, Color("d9a6f0"), 380.0, 0.6 / speed, 1.0, 10.0)
	shake(6.0)
	if pi == rival:
		story_bark("rival_ward_springs")
	if tutor != null and pi == rival:
		await tutor.lesson("ward_spring", "There it goes. It's spent now. Next time, think what it's waiting for, and don't give it that.", "Wards")


func fx_shift(_pi: int) -> void:
	sfx.play("shift")
	if tutor != null:
		await tutor.lesson("shift", "A Shift: two of your Totems change places, for an Essence. It's the only way to move one once it's called, so a slot you've put the wrong Totem in isn't a slot you're stuck with.", "Shift")
	for side in 2:
		for v in views[side]:
			v.set_totem(game.players[side].slots[v.slot])
			if v.totem != null:
				if field != null:
					field.floor_wave(field.foot_world(side, v.slot), DuelFX.light(v.totem.element()), 2.6, 0.45 / speed)
				else:
					DuelFX.shockwave(fx_layer, _foot(v), DuelFX.light(v.totem.element()), 160.0 * v.depth, 0.4 / speed, 0.3, 6.0)
	await pause(0.25)


## Melee moves charge in and strike; everything else is thrown, breathed or cast.
func _is_melee(move_name: String) -> bool:
	var n := move_name.to_lower()
	for w in ["nip", "bite", "fang", "rush", "whip", "claw", "headbutt", "charge", "lash", "slam", "ram", "smash",
			"bash", "tackle", "gnaw", "strike", "grasp", "blade", "ambush"]:
		if n.contains(w):
			return true
	return false


func _target_point(t: DuelTotem, target) -> Vector2:
	if target is DuelTotem:
		return _center(_view(target))
	if target is String and target == DuelGame.LIFE:
		return _life_center(1 - t.owner)
	return _center(_view(t)) + Vector2(0, -120 if t.owner == me else 120)


func fx_attack(t: DuelTotem, i: int, target) -> void:
	_hide_detail()
	if t.owner == me and _coached.has("attack"):
		_coach_hide(4.0)
	elif t.owner != me:
		_bark()
	var v := _view(t)
	var mv := t.move(i)
	var col := DuelFX.light(t.element())
	var src := _center(v)
	var dest := _target_point(t, target)
	_strike = {"attacker": t, "melee": _is_melee(String(mv.name))}
	sfx.play("attack_charge")
	_strike["clip_len"] = _clip(t, "attack", speed)
	if field != null:
		var aim: Vector3 = _body3(target) if target is DuelTotem else (field.life_world(1 - t.owner) if (target is String and target == DuelGame.LIFE) else _body3(t))
		if target is DuelTotem or (target is String and target == DuelGame.LIFE):
			field.face_at(t.owner, t.slot, aim, 1.8 / speed)
			if target is DuelTotem and target.owner != t.owner:
				field.face_at(target.owner, target.slot, _body3(t), 1.8 / speed)
		field.cam_focus((_body3(t) + aim) * 0.5, 0.3, 0.45 / speed)
		field.flash_light(_body3(t), col, 4.0, 0.5 / speed, 5.0)
	_move_label(src + Vector2(0, -150 * v.depth), String(mv.name), col)
	# gather power: a glow, sparks drawn in, and a step back
	v.flash = 0.7
	v.flash_color = col
	create_tween().tween_property(v, "flash", 0.0, 0.45 / speed)
	DuelFX.flash(fx_layer, src, col, 170.0 * v.depth, 0.45 / speed)
	var back := -(dest - src).normalized() * 28.0
	var tw := create_tween()
	tw.tween_property(v, "offset", back, 0.14 / speed).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	if not _strike.melee:
		tw.tween_property(v, "offset", Vector2.ZERO, 0.16 / speed).set_ease(Tween.EASE_IN_OUT)
	await pause(0.26)
	if (target is String and target == DuelGame.NONE) or (target is DuelTotem and target.owner == t.owner):
		# a self or ally move: no strike to deliver
		_strike = {}
		tw = create_tween()
		tw.tween_property(v, "offset", Vector2.ZERO, 0.15 / speed)
		if field != null:
			field.cam_home(0.6 / speed)


## Sends the attack across the field once its damage is known.
func _deliver(att: DuelTotem, to: Vector2) -> void:
	var v := _view(att)
	var from := _center(v) - v.offset
	var col := DuelFX.light(att.element())
	if field != null:
		await _deliver3(att, to)
		return
	if _strike.get("melee", false):
		sfx.play("melee_whoosh")
		var tw := create_tween()
		tw.tween_property(v, "offset", (to - from) * 0.8, 0.12 / speed).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		await tw.finished
		sfx.play("slash")
		var ang := randf_range(-0.9, -0.4)
		if to.x < from.x:
			ang = PI - ang
		DuelFX.slash(fx_layer, to, col, 150.0, ang, 0.26 / speed)
		DuelFX.slash(fx_layer, to + Vector2(10, 14), Color.WHITE, 120.0, ang + 0.25, 0.22 / speed)
		var back := create_tween()
		back.tween_property(v, "offset", Vector2.ZERO, 0.32 / speed).set_delay(0.08 / speed).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		return
	var el := att.element()
	sfx.play("cast_mystic" if el == "spirit" or el == "mystic" else "cast_" + el)
	match el:
		"storm":
			DuelFX.flash(fx_layer, from, col, 140.0, 0.3 / speed)
			DuelFX.lightning(fx_layer, from, to, col, 0.36 / speed, 10.0)
			DuelFX.lightning(fx_layer, from, to, Color.WHITE, 0.22 / speed, 4.0)
			await pause(0.1)
		"psychic", "mystic", "spirit":
			var b := DuelFX.projectile(fx_layer, from, to, col, 0.34 / speed, 30.0, 40.0)
			for k in 2:
				DuelFX.shockwave(fx_layer, from, col, 120.0 + k * 60.0, 0.4 / speed, 1.0, 5.0)
			await b.arrived
			for k in 3:
				DuelFX.shockwave(fx_layer, to, col, 90.0 + k * 70.0, (0.3 + k * 0.1) / speed, 1.0, 6.0)
		_:
			var b := DuelFX.projectile(fx_layer, from, to, col, 0.3 / speed, 34.0, 110.0)
			await b.arrived


## The attack crossing the 3D field. `to` is where it lands on the stage;
## `_strike_to3` says where that is in the world.
func _deliver3(att: DuelTotem, to: Vector2) -> void:
	var v := _view(att)
	var col := DuelFX.light(att.element())
	var a3 := _body3(att)
	var b3: Vector3 = _strike.get("to3", a3)
	if _strike.get("melee", false):
		sfx.play("melee_whoosh")
		var tw := create_tween()
		tw.tween_property(v, "offset", (to - _center(v)) * 0.8, 0.12 / speed).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		await tw.finished
		sfx.play("slash")
		var ang := randf_range(-0.9, -0.4)
		if to.x < _center(v).x:
			ang = PI - ang
		DuelFX.slash(fx_layer, to, col, 150.0, ang, 0.26 / speed)
		DuelFX.slash(fx_layer, to + Vector2(10, 14), Color.WHITE, 120.0, ang + 0.25, 0.22 / speed)
		var back := create_tween()
		back.tween_property(v, "offset", Vector2.ZERO, 0.32 / speed).set_delay(0.08 / speed).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		return
	var el := att.element()
	sfx.play("cast_mystic" if el == "spirit" or el == "mystic" else "cast_" + el)
	match el:
		"storm":
			field.lightning(a3 + Vector3(0, 0.6, 0), b3, col, 0.36 / speed, 0.18)
			field.lightning(a3 + Vector3(0, 0.6, 0), b3, Color.WHITE, 0.22 / speed, 0.07)
			await pause(0.1)
		"psychic", "mystic", "spirit":
			var b := field.bolt(a3, b3, col, 0.34 / speed, 0.9, 0.6)
			field.floor_wave(_foot3(att), col, 2.4, 0.4 / speed)
			await b.arrived
			for k in 3:
				field.floor_wave(b3 * Vector3(1, 0, 1), col, 2.0 + k * 1.2, (0.3 + k * 0.1) / speed)
		_:
			var b := field.bolt(a3, b3, col, 0.3 / speed, 1.0, 1.4)
			await b.arrived


## The flash, sparks and shake where a hit lands.
func _impact(pos: Vector2, col: Color, amount: int) -> void:
	var big := amount >= 50
	DuelFX.flash(fx_layer, pos, col, 230.0 if big else 170.0, 0.4 / speed)
	DuelFX.flash(fx_layer, pos, Color.WHITE, 90.0 if big else 70.0, 0.2 / speed)
	if field != null and _impact3 != Vector3.ZERO:
		field.burst(_impact3, col, 46 if big else 30, 8.0 if big else 6.0, 0.7, 0.13, 0.0)
		field.flash_light(_impact3, col, 9.0 if big else 6.0, 0.4 / speed)
		field.floor_wave(_impact3 * Vector3(1, 0, 1), col, 3.2 if big else 2.4, 0.45 / speed)
	else:
		DuelFX.burst(fx_layer, pos, col, 34 if big else 22, 620.0 if big else 480.0, 16.0, 0.65, Vector2(0, 420), 180.0, Vector2.UP, speed)
		DuelFX.shockwave(fx_layer, pos + Vector2(0, 50), col, 200.0 if big else 150.0, 0.45 / speed, 0.4, 9.0)
	shake(5.0 + minf(float(amount), 100.0) * 0.12)


func fx_roll(_pi: int, info: Dictionary) -> void:
	_coach("fate")
	var dv := DuelViews.DiceView.new()
	dv.info = info
	dv.position = Vector2(FIELD_CX - 590, 276)
	dv.size = Vector2(1180, 400)
	fx_layer.add_child(dv)
	_dice_view = dv
	var steps := int(14 / maxf(1.0, speed * 0.7))
	var rattle := Sfx.has_file("dice_roll")
	if rattle:
		sfx.play("dice_roll")
	if _pi == rival:
		story_bark("rival_first_fate")   # (a plea as it rolls: "Six. Give me a six.")
	for k in steps:
		dv.face = randi_range(1, 20)
		dv.spin += 0.5
		if not rattle:
			sfx.play("click", 1.4 + randf() * 0.3)
		await pause(0.05)
	dv.face = int(info.roll)
	dv.spin = 0.0
	dv.landed = true
	if int(info.roll) == 20:
		sfx.play("dice_crit")
	elif int(info.roll) == 1:
		sfx.play("dice_fumble")
	else:
		sfx.play("dice_land")
	var bands: Array = info.get("bands", [])
	var bi := int(info.get("index", -1))
	if bi >= 0 and bi < bands.size() and int(bands[bi].get("damage", 0)) == 0 and String(bands[bi].get("text", "")) == "Miss":
		sfx.play("miss")
	var c := dv.position + dv.die_center()
	var col := UITheme.GOLD if int(info.roll) == 20 else (Color("ff6a5a") if int(info.roll) == 1 else Color(0.7, 0.6, 1.0))
	DuelFX.flash(fx_layer, c, col, 220.0, 0.5 / speed)
	DuelFX.burst(fx_layer, c, col, 26 if int(info.roll) == 20 else 14, 420.0, 12.0, 0.6, Vector2.ZERO, 180.0, Vector2.UP, speed)
	await pause(1.2)
	if tutor != null:
		# the die stays up while Bram explains it (the Lantern Duel's scripted
		# line, or the one-off lesson in a later duel)
		await tutor.event("fate" if _pi == me else "rival_fate")
		await tutor.lesson("fate", "That's a Fate roll. High, and it hits hard; low, nothing. The die doesn't care who you are.", "Fate", "die")
		await tutor.lesson("fate_bands", "The bands under a move say what the die has to make: the low band does the small thing, the top band the big one. A move with a wide top band is a gamble. A narrow one is steady money.", "Fate", "detail")
	_dice_view = null
	var tw := dv.create_tween()
	tw.tween_property(dv, "modulate:a", 0.0, 0.15 / speed)
	tw.tween_callback(dv.queue_free)


func fx_totem_hit(t: DuelTotem, amount: int, info: Dictionary) -> void:
	var v := _view(t)
	if v.totem != t:
		v.set_totem(t)
	var c := _center(v)
	var att = info.get("attacker")
	var src: String = info.get("source", "")
	_impact3 = _body3(t) if field != null else Vector3.ZERO
	if att != null and src == "" and not _strike.is_empty() and _strike.get("attacker") == att:
		_strike["to3"] = _impact3
		await _deliver(att, c)
	elif src == "thorns" or src == "recoil":
		DuelFX.burst(fx_layer, c, Color("9be15d") if src == "thorns" else Color(1, 0.6, 0.4), 14, 300.0, 10.0, 0.5, Vector2.ZERO, 180.0, Vector2.UP, speed)
	var absorbed := int(info.get("absorbed", 0))
	if absorbed > 0:
		sfx.play("shield_block")
		DuelFX.shockwave(fx_layer, c, Color("9fe8ff"), 150.0 * v.depth, 0.4 / speed, 1.0, 8.0)
		DuelFX.number(fx_layer, c + Vector2(110, -40), "◈ -%d" % absorbed, Color("9fe8ff"), 46, 0.9 / speed)
	_last_hit_pos = c
	if amount <= 0:
		await pause(0.2)
		if tutor != null and absorbed > 0 and t.owner == me:
			await tutor.event("absorbed")
		return
	sfx.play("hit_weak" if att != null and t.weak_to(att.element()) else ("hit_heavy" if amount >= 40 else "hit_light"))
	_clip(t, "hit", speed)
	var col := Color(1.0, 0.45, 0.35)
	if att != null:
		col = DuelFX.light(att.element())
	elif src == "burn":
		col = Color(1.0, 0.55, 0.2)
	elif src == "poison":
		col = Color(0.65, 1.0, 0.3)
	_impact(c, col, amount)
	if amount >= 40:
		punch(c, 0.025 + minf(float(amount), 120.0) * 0.0002)
	v.flash = 1.0
	v.flash_color = Color(1, 0.3, 0.25)
	var weak: bool = att != null and t.weak_to(att.element())
	if weak and att != null and att.owner == me and t.owner != me:
		_coach("weakness")
		story_bark("weakness_on_rival")
	if att != null and att.owner == me and t.owner == rival:
		if t.has_keyword("guardian"):
			story_bark("rival_guardian_hit")
		if amount >= 60:
			story_bark("my_big_hit")
	DuelFX.number(fx_layer, c + Vector2(0, -10), "-%d" % amount, Color("ffb347") if weak else Color("ff5a4a"), 96 if amount >= 50 else 80, 1.1 / speed, "WEAK!  ×1.5" if weak else "")
	# knocked back, then settles
	var push := Vector2(0, -16) if t.owner == me else Vector2(0, 12)
	if att != null and _strike.get("melee", false):
		push = (c - _center(_view(att))).normalized() * 22.0
	var tw := create_tween()
	tw.tween_property(v, "offset", push, 0.05 / speed)
	for k in 3:
		tw.tween_property(v, "offset", push * 0.5 + Vector2(randf_range(-10, 10), randf_range(-4, 4)), 0.04 / speed)
	tw.tween_property(v, "offset", Vector2.ZERO, 0.12 / speed)
	create_tween().tween_property(v, "flash", 0.0, 0.45 / speed)
	await pause(0.08)
	await pause(0.36)
	if field != null and att != null:
		field.cam_home(0.7 / speed)
	if tutor != null:
		if weak and att != null and att.owner == me and t.owner != me:
			await tutor.event("weakness")
			await tutor.lesson("weakness", "See that? Every element hurts something and fears something. Twelve of them. You'll learn the rest the way I did: by getting hit.", "The elements", "foe:" + t.id())
		elif t.owner == me:
			await tutor.event("hit_mine")


func fx_life_hit(pi: int, amount: int, info: Dictionary) -> void:
	var p: DuelViews.PlayerPanel = panels[pi]
	var to := _life_center(pi)
	var att = info.get("attacker")
	var land3: Vector3 = field.life_world(pi) if field != null else Vector3.ZERO
	if info.get("spill", false):
		if field != null and _impact3 != Vector3.ZERO:
			var b3 := field.bolt(_impact3, land3, Color(1, 0.35, 0.4), 0.28 / speed, 0.7, 1.0)
			await b3.arrived
		else:
			var b := DuelFX.projectile(fx_layer, _last_hit_pos, to, Color(1, 0.35, 0.4), 0.28 / speed, 26.0, 80.0)
			await b.arrived
	elif att != null and not _strike.is_empty() and _strike.get("attacker") == att:
		_strike["to3"] = land3
		if field != null:
			await _deliver(att, field.world_to_stage(land3))
		else:
			await _deliver(att, to)
	if field != null:
		_impact3 = land3
		field.burst(land3, Color(1, 0.35, 0.4), 40, 7.0, 0.7, 0.13, 0.0)
		field.flash_light(land3, Color(1, 0.3, 0.4), 9.0, 0.5 / speed)
		field.floor_wave(land3 * Vector3(1, 0, 1), Color(1, 0.35, 0.4), 4.0, 0.5 / speed)
	sfx.play("life_hit")
	p.flash = 1.0
	p.shake = 10.0
	var col := Color(1, 0.3, 0.4)
	DuelFX.flash(fx_layer, to, col, 220.0, 0.45 / speed)
	DuelFX.burst(fx_layer, to, col, 26, 520.0, 14.0, 0.6, Vector2(0, 300), 180.0, Vector2.UP, speed)
	shake(8.0 + minf(float(amount), 100.0) * 0.1)
	punch(Vector2(FIELD_CX, 476), 0.02)
	DuelFX.number(fx_layer, _life_number_pos(pi), "-%d" % amount, Color("ff4d6a"), 88 if not info.get("spill", false) else 70, 1.2 / speed, "SPILL-OVER" if info.get("spill", false) else "")
	var tw := create_tween().set_parallel(true)
	tw.tween_property(p, "flash", 0.0, 0.5 / speed)
	tw.tween_property(p, "shake", 0.0, 0.45 / speed)
	if pi == me:
		_vignette(Color(1, 0.05, 0.1))
	if pi == rival:
		if att != null and att.owner == me and amount >= 60:
			story_bark("my_big_hit")
		_rival_life_barks()
	await pause(0.5)
	if field != null:
		field.cam_home(0.7 / speed)
	if pi == me:
		await _blank_eye_check()


## Story barks tied to the rival's Life: below a third ("rival_life_third"),
## and the player pulling ahead ("my_lead": less of their Life left than of
## yours, once they've lost a fifth of it).
func _rival_life_barks() -> void:
	var q: DuelPlayer = game.players[rival]
	var p: DuelPlayer = game.players[me]
	if q.life > 0 and q.life * 3 <= q.max_life:
		story_bark("rival_life_third")
	if q.max_life > 0 and p.max_life > 0 and q.life * 5 <= q.max_life * 4 \
			and float(q.life) / q.max_life < float(p.life) / p.max_life:
		story_bark("my_lead")


## Aldric's duel (spec.blank_eye): the first time your Life drops below a
## third, the duel freezes for a beat; the blank card in its slot flickers and
## a faint image shows on it, a white eye inside a ring of runes, then fades.
func _blank_eye_check() -> void:
	if not spec.get("blank_eye", false) or _barked.has("_blank_eye") or game.over:
		return
	var p: DuelPlayer = game.players[me]
	if p.life <= 0 or p.life * 3 > p.max_life:
		return
	_barked["_blank_eye"] = true
	var slot := stage.get_node_or_null("BlankCardSlot")
	if slot == null:
		return
	if field != null:
		field.cam_home(0.3)
	await pause(0.5)
	await slot.show_eye(2.4 / speed)
	if _herald != null and field != null:
		# Aldric doesn't see it. The Pale Herald's hood turns, very slightly.
		_herald.turn_hood(field.life_world(me))
		field.cam_focus(_herald.hood_pos(), 0.12, 0.8 / speed)
		await pause(1.6)
		field.cam_home(0.6)
	elif _herald2d != null:
		var tw := _herald2d.create_tween().set_parallel(true)
		tw.tween_property(_herald2d, "skew", -0.12, 0.9 / speed).set_trans(Tween.TRANS_SINE)
		tw.tween_property(_herald2d, "scale:x", _herald2d.scale.x * 0.9, 0.9 / speed).set_trans(Tween.TRANS_SINE)
		await pause(1.6)
	await pause(0.4)


func fx_heal(t: DuelTotem, amount: int) -> void:
	var v := _view(t)
	sfx.play("heal")
	var col := Color(0.45, 1.0, 0.55)
	v.flash = 0.8
	v.flash_color = col
	_clip(t, "victory", speed)
	create_tween().tween_property(v, "flash", 0.0, 0.6 / speed)
	if field != null:
		field.rise(_foot3(t), col, 40, 1.2, 1.4)
		field.floor_wave(_foot3(t), col, 2.8, 0.5 / speed)
		field.flash_light(_body3(t), col, 5.0, 0.6 / speed)
	else:
		DuelFX.rise(fx_layer, _foot(v) - Vector2(0, 10), col, 200.0 * v.depth, 34, 1.1, speed)
		DuelFX.shockwave(fx_layer, _foot(v), col, 180.0 * v.depth, 0.5 / speed, 0.3, 7.0)
	DuelFX.number(fx_layer, _center(v), "+%d" % amount, Color("7ee08a"), 76, 1.0 / speed)
	await pause(0.35)


func fx_life_gain(pi: int, amount: int) -> void:
	sfx.play("heal")
	var to := _life_center(pi)
	DuelFX.rise(fx_layer, to + Vector2(0, 40), Color(0.45, 1.0, 0.55), 260.0, 30, 1.0, speed)
	if amount > 0:
		DuelFX.number(fx_layer, _life_number_pos(pi), "+%d" % amount, Color("7ee08a"), 76, 1.0 / speed)
	else:
		DuelFX.number(fx_layer, _life_number_pos(pi), "SURVIVED!", UITheme.GOLD, 56, 1.3 / speed)
	await pause(0.35)


func fx_status(t: DuelTotem, status: String) -> void:
	if status == "":
		return   # a condition was cleared; the nameplate redraws by itself
	if status == "poison":
		_coach("poison")
		if t.owner == me:
			story_bark("rival_poisons")
	var v := _view(t)
	var col: Color = DuelConditions.color(status)
	var c := _center(v)
	if field != null:
		match status:
			"burn":
				field.rise(_foot3(t), Color(1.0, 0.5, 0.15), 36, 0.9, 1.2)
			"poison":
				field.rise(_foot3(t), Color(0.6, 1.0, 0.3), 28, 1.1, 1.2)
			"stun":
				field.burst(_body3(t) + Vector3(0, 0.8, 0), Color(1.0, 0.9, 0.3), 20, 3.0, 0.6, 0.1, 0.0)
			_:
				field.rise(_body3(t), Color(0.7, 0.6, 1.0), 16, 1.3, 0.8)
		field.flash_light(_body3(t), col, 4.0, 0.4 / speed)
	else:
		match status:
			"burn":
				DuelFX.rise(fx_layer, _foot(v) - Vector2(0, 20), Color(1.0, 0.5, 0.15), 160.0 * v.depth, 30, 0.9, speed)
			"poison":
				DuelFX.rise(fx_layer, _foot(v) - Vector2(0, 20), Color(0.6, 1.0, 0.3), 160.0 * v.depth, 24, 1.1, speed)
			"stun":
				DuelFX.burst(fx_layer, c + Vector2(0, -60), Color(1.0, 0.9, 0.3), 18, 300.0, 12.0, 0.6, Vector2.ZERO, 180.0, Vector2.UP, speed)
			_:
				DuelFX.rise(fx_layer, c, Color(0.7, 0.6, 1.0), 120.0 * v.depth, 16, 1.2, speed)
	DuelFX.flash(fx_layer, c, col, 150.0 * v.depth, 0.4 / speed)
	DuelFX.number(fx_layer, c + Vector2(0, 60), DuelConditions.display_name(status).to_upper() + "!", col, 44, 0.9 / speed)
	var snd := status
	if not status in ["burn", "poison", "stun", "sleep"]:
		snd = {"body": "poison", "mind": "stun", "soul": "sleep"}.get(DuelConditions.kind_of(status), "stun")
	sfx.play("status_" + snd)
	await pause(0.3)
	# the first time a condition (or boon) lands on either side, Bram says
	# what it does and how long it lasts, and it gets its Codex entry
	if tutor != null and (DuelConditions.is_condition(status) or DuelConditions.is_boon(status)):
		Game.meet_condition(status)
		await tutor.lesson("status:" + status, _status_lesson(t, status),
			"Conditions" if DuelConditions.is_condition(status) else "Boons",
			("totem:" if t.owner == me else "foe:") + t.id())


## Bram's one line on a condition: what it does, and how long it lasts.
func _status_lesson(t: DuelTotem, status: String) -> String:
	var who := "Your %s" % t.card_name() if t.owner == me else ("My %s" if _bram_rival() else "His %s") % t.card_name()
	var nm := DuelConditions.display_name(status)
	var what := DuelConditions.describe(status)
	var turns := DuelConditions.turns(status)
	var lasts := ""
	if DuelConditions.breaks_free(status):
		lasts = "It stays until it breaks free, or it's cured."
	elif turns == 0:
		lasts = "It stays until it's cured." if DuelConditions.is_condition(status) else "It stays until it's used up."
	elif turns == 1:
		lasts = "One turn, then it's gone."
	else:
		lasts = "%s turns, then it's gone." % ["Two", "Three", "Four", "Five"][clampi(turns - 2, 0, 3)]
	return "%s's %s now. %s %s" % [who, nm, what, lasts]


func fx_ko(t: DuelTotem) -> void:
	var v: DuelViews.TotemView = views[t.owner][t.slot]
	v.set_totem(t)
	var c := _center(v)
	var foot := _foot(v)
	var col := DuelFX.light(t.element())
	v.flash = 1.0
	v.flash_color = Color(1, 1, 1)
	sfx.play("ko")
	shake(12.0)
	punch(c, 0.045)
	var ko_len := _clip(t, "ko", speed)
	if t.owner == rival:
		story_bark("rival_ko_own")
		if t.has_keyword("guardian"):
			story_bark("rival_guardian_ko")
	else:
		story_bark("rival_kos_mine")
	DuelFX.flash(fx_layer, c, Color(1, 0.95, 0.9), 280.0 * v.depth, 0.5 / speed)
	# Violence setting: Full spills blood as it falls; Reduced bursts into crystal and light.
	var gore: bool = String(Game.settings.get("violence", "full")) == "full"
	if field != null:
		field.cam_focus(_foot3(t), 0.4, 0.3 / speed)
		field.burst(_body3(t), col, 70, 9.0, 1.0, 0.15, 0.0)
		if gore:
			field.burst(_body3(t), Color(0.55, 0.02, 0.03), 46, 5.0, 0.9, 0.3, 0.0)
			field.rise(_foot3(t), Color(0.35, 0.0, 0.02), 20, 0.4, 0.8)
		field.rise(_foot3(t), col, 60, 1.5, 1.6)
		field.floor_wave(_foot3(t), col, 4.5, 0.7 / speed)
		field.flash_light(_body3(t), Color(1, 0.95, 0.9), 12.0, 0.6 / speed)
	else:
		DuelFX.burst(fx_layer, c, col, 46, 720.0, 18.0, 0.9, Vector2(0, 300), 180.0, Vector2.UP, speed)
		if gore:
			DuelFX.burst(fx_layer, c, Color(0.6, 0.02, 0.04), 34, 520.0, 14.0, 0.8, Vector2(0, 900), 120.0, Vector2.UP, speed)
		DuelFX.rise(fx_layer, foot - Vector2(0, 50), col, 190.0 * v.depth, 50, 1.3, speed)
		DuelFX.shockwave(fx_layer, foot, col, 260.0 * v.depth, 0.6 / speed, 0.3, 10.0)
	DuelFX.number(fx_layer, c + Vector2(0, -70), "KNOCKED OUT", Color("ff4d6a"), 54, 1.2 / speed)
	var tw := create_tween()
	tw.tween_property(v, "pop", 1.12, 0.08 / speed)
	tw.set_parallel(true)
	var ko_hold: float = maxf(0.42, ko_len * 0.9)
	tw.tween_property(v, "pop", 0.35 if ko_len <= 0.0 else 1.0, ko_hold).set_ease(Tween.EASE_IN).set_delay(0.08 / speed)
	tw.tween_property(v, "fade", 0.0, ko_hold).set_ease(Tween.EASE_IN).set_delay(0.08 / speed)
	await pause(ko_hold + 0.13)
	v.pop = 1.0
	v.fade = 1.0
	v.flash = 0.0
	v.set_totem(game.players[t.owner].slots[t.slot])
	if field != null:
		field.cam_home(0.7 / speed)
	if tutor != null and t.owner == rival:
		await tutor.event("ko_rival")


func fx_summon(pi: int, card: DuelCard) -> void:
	_hide_detail()
	_layout_hand()
	if pi == rival and spec.get("crowd_on", {}).has("rival_summons"):
		# the crowd knows it from his banners before he can name it
		await _crowd(String(spec.crowd_on.rival_summons))
		story_bark("rival_summons")
		await pause(2.4)
	elif pi == me:
		if spec.get("mirrors_show", false) and not _barked.has("my_summons"):
			# the Trial of Light: every mirror in the hall shows the Demigod at once
			_mirrors_show(card)
			await pause(0.5)
		story_bark("my_summons")
	if not Music.stinger("summon_" + card.id):
		sfx.play("summon")
	if SummonVideo.pick(card.id) != "":
		# Gary's clip for it (the long one the first time, then the short)
		await SummonVideo.play(overlay, card.id)
	else:
		var cine := SummonCine.new()
		cine.card_id = card.id
		cine.mine = pi == me
		cine.scene = DuelArt.summon_scene(card.id)
		cine.figure = DuelArt.summon(card.id)
		cine.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay.add_child(cine)
		var tw := create_tween()
		cine.tween = tw
		tw.tween_property(cine, "t", 1.0, (3.2 if cine.has_art() else 1.9) / minf(speed, 2.0))
		await tw.finished
		cine.queue_free()
	var col := DuelFX.light(card.element())
	var landing := func() -> void:
		DuelFX.flash(fx_layer, Vector2(FIELD_CX, 470), col, 700.0, 0.6 / speed)
		sfx.play("summon_boom")
		if field != null:
			field.pillar(Vector3(0, 0, -0.8), col, 12.0, 5.0, 1.2 / speed)
			field.floor_wave(Vector3(0, 0, -0.8), col, 9.0, 0.9 / speed)
			field.burst(Vector3(0, 1.5, -0.8), col, 90, 12.0, 1.2, 0.18, 0.0)
			field.flash_light(Vector3(0, 2, -0.8), col, 16.0, 1.0 / speed, 14.0)
		shake(14.0)
		punch(Vector2(FIELD_CX, 476), 0.05)
	if field != null and DuelField3D.has_summon_model(card.id):
		# the Demigod itself comes down onto the field
		var hint_was := hint.visible
		hint.visible = false
		await field.summon_descend(card.id, col, minf(speed, 2.0), landing)
		hint.visible = hint_was
	else:
		landing.call()
	if tutor != null and pi == rival:
		await tutor.lesson("summon", ("That was my Summon." if _bram_rival() else "That was a Summon.") + " One great blow, then it's gone, and it cost a fortune in Essence. Nobody can do that often.", "Summons")


## Is Bram the one across the Circle (the practice round at the campfire)?
## Then his one-off lines are about his own cards.
func _bram_rival() -> bool:
	var names: Array = spec.get("names", [])
	return names.size() > rival and String(names[rival]) == "Bram"


func fx_gift(pi: int, g: String) -> void:
	sfx.play("gift")
	var p: DuelPlayer = game.players[pi]
	# (a rival with no god isn't "the Unsworn": that's the player's name)
	var from: String = "A Divine Gift from %s" % Lore.GODS[p.patron()].name if p.patron() != "" \
		else ("A Divine Gift from the Unsworn" if pi == me else "Bound to no god")
	var at: Vector2 = panels[pi].position + panels[pi].portrait_center()
	DuelFX.flash(fx_layer, at, UITheme.GOLD, 260.0, 0.6 / speed)
	DuelFX.rise(fx_layer, at + Vector2(0, 40), UITheme.GOLD, 160.0, 40, 1.2, speed)
	await _banner(Lore.GIFTS[g].name.to_upper(), UITheme.GOLD, 1.2, 84, p.patron(), from)
	if pi == rival:
		story_bark("rival_gift")
	_refresh()
	if tutor != null:
		await tutor.lesson("gift", "A Gift. A god's favour, bought with kneeling. Nobody gets many.", "Gifts")


## Light Fingers (Wren): she's had a card out of your hand, and plays it as
## her own straight after.
func fx_light_fingers(pi: int, card: DuelCard) -> void:
	_hide_detail()
	_layout_hand()
	if pi == rival:
		story_bark("rival_steals")
	sfx.play("card_fly")
	var from := Vector2(FIELD_CX, HAND_Y + 60) if pi == rival else Vector2(FIELD_CX, 30)
	await _show_card_big(card.id, "LIGHT FINGERS", UITheme.GOLD, 1.1, from)
	if tutor != null and pi == rival:
		await tutor.lesson("steal", "She's had a card off you. Don't sit on what you can play now.", "Your hand", "hand")


## The Sunspire's Mirror (Aldric): at half Life the great mirror swings on its
## chains to put the sun on his side of the Circle.
func fx_mirror(pi: int) -> void:
	spec["_mirror_swung"] = true   # the story shows the mirror swung, afterwards
	_hide_detail()
	sfx.play("ascend")
	var col := Color(1.0, 0.92, 0.62)
	_screen_flash(Color(1.0, 0.96, 0.82, 0.55))
	if field != null:
		var at := Vector3(0, 0, -1.6) if pi == rival else Vector3(0, 0, 1.6)
		field.pillar(at, col, 14.0, 6.0, 1.6 / speed)
		field.floor_wave(at, col, 10.0, 1.0 / speed)
		field.flash_light(at + Vector3(0, 4, 0), col, 18.0, 1.4 / speed, 22.0)
	var sub := String(spec.get("mirror_text", "The great mirror swings to %s side of the Circle. Radiant cards cost one less there, for the rest of the duel." % _whose(String(game.players[pi].player_name)).to_lower()))
	await _banner("THE SUNSPIRE'S MIRROR", UITheme.GOLD, 2.0, 72, "", sub)
	_refresh()


## The Hall of Mirrors (spec.mirrors_show): a ring of tall mirrors round the
## Circle, every one of them showing the Demigod at once; they hold, then
## fade back to glass.
func _mirrors_show(card: DuelCard) -> void:
	var tex: Texture2D = DuelArt.summon(card.id)
	if tex == null:
		tex = DuelArt.summon_scene(card.id)
	var col := DuelFX.light(card.element())
	sfx.play("ascend")
	var panes: Array = []
	# round the hall: an ellipse about the Circle, its near side (the hand)
	# left open; behind the plates and the cards, as the walls are
	for side in [-1.0, 1.0]:
		for deg in [-62.0, -34.0, -6.0, 22.0, 50.0]:
			var a := deg_to_rad(deg)
			var c := Vector2(FIELD_CX + side * 830.0 * cos(a), 470.0 + 400.0 * sin(a))
			var m := MirrorPane.new()
			m.tex = tex
			m.col = col
			m.size = Vector2(140, 270) * lerpf(0.72, 1.0, (sin(a) + 1.0) * 0.5)
			m.position = c - m.size * 0.5
			m.pivot_offset = m.size * 0.5
			m.modulate.a = 0.0
			m.mouse_filter = Control.MOUSE_FILTER_IGNORE
			stage.add_child(m)
			stage.move_child(m, 0)
			panes.append(m)
	for m in panes:
		var tw := (m as Control).create_tween()
		tw.tween_property(m, "modulate:a", 1.0, 0.22 / speed)
		tw.parallel().tween_property(m, "lit", 1.0, 0.22 / speed)
		tw.tween_interval(2.0 / speed)
		tw.tween_property(m, "lit", 0.0, 0.7 / speed)
		tw.parallel().tween_property(m, "modulate:a", 0.0, 0.9 / speed)
		tw.tween_callback((m as Control).queue_free)
	_screen_flash(Color(col.r, col.g, col.b, 0.28))


## A shout from the crowd round the Circle, big across the top of the field.
func _crowd(text: String) -> void:
	sfx.play("duel_start")
	var l := UITheme.label(text, 120, UITheme.GOLD, "display_bold", 18)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(FIELD_CX - 900, 120)
	l.size = Vector2(1800, 170)
	l.pivot_offset = l.size * 0.5
	l.scale = Vector2(0.6, 0.6)
	l.modulate.a = 0.0
	fx_layer.add_child(l)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "modulate:a", 1.0, 0.18 / speed)
	tw.tween_property(l, "scale", Vector2(1, 1), 0.3 / speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(1.4 / speed)
	tw.chain().tween_property(l, "modulate:a", 0.0, 0.5 / speed)
	tw.chain().tween_callback(l.queue_free)
	shake(6.0)
	await pause(1.3)


func fx_message(text: String) -> void:
	_toast(text)
	await pause(0.8)


func fx_game_over(winner: int, _reason: String) -> void:
	if tutor != null:
		tutor.finish()
	Music.stop(0.4)
	var won := winner == me or (_watching() and winner in [0, 1])
	if not Music.stinger("victory" if won else "defeat", false):
		sfx.play("win" if won else "lose")
	await pause(0.6)


# --------------------------------------------------------- effect helpers ---

func _banner(text: String, col: Color, hold: float, size_px: int = 72, god: String = "", sub: String = "", wait := false) -> void:
	var b := Banner.new()
	b.text = text
	b.sub = sub
	b.col = col
	b.size_px = size_px
	b.god = god
	# the band runs to the screen's edges, past the safe area kept for the stage
	b.edge = maxf(_edge, maxf(_stage_base.x / _base_k, (size.x - _stage_base.x) / _base_k - DESIGN.x))
	b.position = Vector2(0, 476)
	b.size = Vector2(DESIGN.x, 1)
	fx_layer.add_child(b)
	var total := (hold + 0.55) / speed
	if not wait or _watching():   # (nobody to tap when the computer plays both sides)
		var tw := b.create_tween()
		tw.tween_property(b, "t", 1.0, total)
		tw.tween_callback(b.queue_free)
		await pause(hold + 0.45)
		return
	# in, then held at full until it's tapped; the band takes every tap, and
	# the interact key comes through _unhandled_input (tap_banner)
	b.footer = "TAP TO CONTINUE  ▸"
	var catcher := Control.new()
	catcher.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	catcher.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) \
				or (e is InputEventScreenTouch and e.pressed):
			tap_banner())
	add_child(catcher)
	var tin := b.create_tween()
	tin.tween_property(b, "t", 0.5, total * 0.5)
	await pause(hold * 0.5 + 0.2)   # (the words are in and still before a tap counts)
	banner_waiting = true
	await _banner_tapped
	banner_waiting = false
	catcher.queue_free()
	sfx.play("ui_tap")
	if is_instance_valid(b):
		var tout := b.create_tween()
		tout.tween_property(b, "t", 1.0, total * 0.5)
		tout.tween_callback(b.queue_free)
	await pause(0.25)


func _move_label(pos: Vector2, text: String, col: Color) -> void:
	var m := MoveLabel.new()
	m.text = text
	m.col = col
	m.position = pos
	fx_layer.add_child(m)
	var tw := m.create_tween()
	tw.tween_property(m, "t", 1.0, 1.0 / speed)
	tw.tween_callback(m.queue_free)


func _toast(text: String) -> void:
	DuelViews.float_text(fx_layer, Vector2(FIELD_CX, 470), text, UITheme.TEXT, 34, 1.6)


## Shows the tutorial line for this step (once), in a box at the top of the Circle.
func _coach(at: String) -> void:
	if _coached.has(at):
		return
	for line in spec.get("coach", []):
		if String(line.get("at", "")) != at:
			continue
		_coached[at] = true
		if _coach_box == null:
			_coach_box = PanelContainer.new()
			_coach_box.add_theme_stylebox_override("panel", UITheme.sb(Color(0.03, 0.04, 0.08, 0.9), UITheme.GOLD_DIM, 18, 2, 22))
			_coach_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var v := VBoxContainer.new()
			v.add_theme_constant_override("separation", 4)
			_coach_box.add_child(v)
			_coach_who = UITheme.label("", 22, UITheme.GOLD, "bold")
			v.add_child(_coach_who)
			_coach_label = UITheme.label("", 27, UITheme.TEXT)
			_coach_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_coach_label.custom_minimum_size = Vector2(560, 0)
			v.add_child(_coach_label)
			overlay.add_child(_coach_box)
		_coach_who.text = String(line.get("who", "")).to_upper()
		_coach_label.text = String(line.get("say", ""))
		_coach_box.modulate.a = 0.0
		_coach_box.visible = true
		await get_tree().process_frame
		# top right, clear of the rival's Totems and the turn banner
		var sr := _safe_rect()
		_coach_box.position = Vector2(sr.end.x - _coach_box.size.x - 24, sr.position.y + 72)
		var tw := _coach_box.create_tween()
		tw.tween_property(_coach_box, "modulate:a", 1.0, 0.35)
		sfx.play("ui_select")
		return


func _coach_hide(delay: float = 0.0) -> void:
	if _coach_box == null or not _coach_box.visible:
		return
	var tw := _coach_box.create_tween()
	tw.tween_property(_coach_box, "modulate:a", 0.0, 0.5).set_delay(delay)
	tw.tween_callback(func() -> void: _coach_box.visible = false)


## The rival's barks (spec.barks: a list of short lines), one at a time in a
## small box on their side of the Circle, roughly every other attack.
var _bark_box: PanelContainer
var _bark_label: Label
var _bark_i := 0
var _bark_skip := false


func _bark() -> void:
	var lines: Array = spec.get("barks", [])
	if lines.is_empty() or spec.has("bark_on"):
		return   # a story duel's barks are tied to what happens (story_bark)
	_bark_skip = not _bark_skip
	if _bark_skip and _bark_i > 0:
		return
	_show_bark(String(lines[_bark_i % lines.size()]))
	_bark_i += 1


## A story duel's barks (Master Script v3): each is tied to something that
## happens on the board and is said once per duel. spec.bark_on maps the
## event to the line: "rival_first_fate" (the rival's first Fate roll),
## "rival_poisons" (one of yours is Poisoned), "rival_ward_springs" (their
## Ward goes off), "my_lethal" (you have enough on the board to finish them),
## "weakness_on_rival" (you hit one of theirs on its weakness), "rival_ko_own"
## (one of theirs is knocked out), "my_oath" (you swear an Oath, Phase D),
## "my_oath_broken" and "rival_oath_broken" (an Oath breaks). Their line for
## winning is spec.win_line (StoryLoss).
var _barked := {}


func story_bark(event: String) -> void:
	var lines: Dictionary = spec.get("bark_on", {})
	if not lines.has(event) or _barked.has(event):
		return
	_barked[event] = true
	_show_bark(String(lines[event]))


## A story duel's own rule just made a difference on the board (DuelGame's
## fx_rule: a free Rite under licence, Fen's Patter, Pip scrapping, the
## Captain's discipline): the rival's line for it, once ("rule" in bark_on).
func fx_rule(pi: int, _rule_id: String) -> void:
	if pi == rival:
		story_bark("rule")


## "my_lethal": checked each time the player is about to act.
func _bark_if_lethal() -> void:
	if not spec.get("bark_on", {}).has("my_lethal") or _barked.has("my_lethal") or game == null or game.over:
		return
	if DuelAI.new()._lethal_available(game, me):
		story_bark("my_lethal")


func _show_bark(line: String) -> void:
	if _bark_box == null:
		_bark_box = PanelContainer.new()
		_bark_box.add_theme_stylebox_override("panel", UITheme.sb(Color(0.03, 0.04, 0.08, 0.88), UITheme.GOLD_DIM, 18, 2, 20))
		_bark_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 2)
		_bark_box.add_child(v)
		var who := UITheme.label(String(spec.get("bark_who", spec.get("names", ["", "Rival"])[1])).to_upper(), 20, UITheme.TEXT_DIM, "bold")
		v.add_child(who)
		_bark_label = UITheme.label("", 26, UITheme.TEXT)
		_bark_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_bark_label.custom_minimum_size = Vector2(460, 0)
		v.add_child(_bark_label)
		overlay.add_child(_bark_box)
	if _bark_tw != null and _bark_tw.is_valid():
		_bark_tw.kill()   # a new line takes over from one still showing
	_bark_label.text = line
	_bark_box.modulate.a = 0.0
	_bark_box.visible = true
	_bark_at = Time.get_ticks_msec()
	await get_tree().process_frame
	# just right of the rival's plate, below their hand, at the field's scale,
	# and kept inside the screen's safe area
	var sr := _safe_rect()
	var plate: Control = panels[rival]
	_bark_box.scale = Vector2(_base_k, _base_k) * 1.15 * SafeArea.ui_scale()   # (the player's text size)
	var at := plate.global_position + Vector2(plate.size.x + 12.0, 70.0) * _base_k
	var bs := _bark_box.size * _bark_box.scale
	at.x = clampf(at.x, sr.position.x + 8.0, maxf(sr.position.x + 8.0, sr.end.x - bs.x - 8.0))
	at.y = clampf(at.y, sr.position.y + 8.0, maxf(sr.position.y + 8.0, sr.end.y - bs.y - 8.0))
	_bark_box.position = at
	var tw := _bark_box.create_tween()
	_bark_tw = tw
	tw.tween_property(_bark_box, "modulate:a", 1.0, 0.3)
	tw.tween_interval(2.6)
	tw.tween_property(_bark_box, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func() -> void: _bark_box.visible = false)


var _bark_tw: Tween


var _bark_at := 0


## Bram waits for a line of the rival's to be read before he speaks (they
## sat in the same corner, his box over theirs): it stays up two seconds,
## then fades out at once.
func _bark_gone() -> void:
	if _bark_box == null or not _bark_box.visible or not is_inside_tree():
		return
	var left := 2.0 - float(Time.get_ticks_msec() - _bark_at) / 1000.0
	if left > 0.0:
		await get_tree().create_timer(left).timeout
	if _bark_box == null or not _bark_box.visible:
		return
	if _bark_tw != null and _bark_tw.is_valid():
		_bark_tw.kill()
	var tw := _bark_box.create_tween()
	_bark_tw = tw
	tw.tween_property(_bark_box, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func() -> void: _bark_box.visible = false)
	await tw.finished


## Flips a card up in the middle of the Circle, flying in from `from`.
## Returns the card's centre.
func _show_card_big(id: String, tag: String, col: Color, hold: float, from := Vector2(-1, -1)) -> Vector2:
	var cv := BigCard.new()
	cv.card_id = id
	cv.tag = tag
	cv.tag_col = col
	cv.size = Vector2(300, 420)
	var home := Vector2(FIELD_CX - 150, 170)
	cv.pivot_offset = cv.size * 0.5
	fx_layer.add_child(cv)
	if from.x >= 0.0:
		cv.position = from - cv.size * 0.5
		cv.scale = Vector2(0.35, 0.35)
		cv.rotation = 0.3
		var tw0 := create_tween().set_parallel(true)
		tw0.tween_property(cv, "position", home, 0.24 / speed).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw0.tween_property(cv, "scale", Vector2(1, 1), 0.24 / speed).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw0.tween_property(cv, "rotation", 0.0, 0.24 / speed)
	else:
		cv.position = home
		cv.scale = Vector2(0.05, 1.0)
		var tw := create_tween()
		tw.tween_property(cv, "scale", Vector2(1, 1), 0.18 / speed).set_ease(Tween.EASE_OUT)
	var c := home + cv.size * 0.5
	await pause(0.22)
	sfx.play("card_flip")
	DuelFX.flash(fx_layer, c, col.lightened(0.3), 300.0, 0.5 / speed)
	DuelFX.burst(fx_layer, c, col.lightened(0.4), 24, 520.0, 12.0, 0.7, Vector2.ZERO, 180.0, Vector2.UP, speed)
	await pause(hold)
	var tw2 := create_tween().set_parallel(true)
	tw2.tween_property(cv, "modulate:a", 0.0, 0.2 / speed)
	tw2.tween_property(cv, "scale", Vector2(1.15, 1.15), 0.2 / speed)
	tw2.chain().tween_callback(cv.queue_free)
	await pause(0.1)
	return c


## A card flying across the field, shrinking as it goes (to a slot or a Ward zone).
## An empty id flies a face-down card.
func _fly_card(id: String, from: Vector2, to: Vector2, dur: float, end_scale := Vector2(0.5, 0.2)) -> void:
	var fc := FlyCard.new()
	fc.card_id = id
	fc.size = HAND_CARD
	fc.pivot_offset = HAND_CARD * 0.5
	fc.position = from - HAND_CARD * 0.5
	fx_layer.add_child(fc)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(fc, "position", to - HAND_CARD * 0.5, dur).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(fc, "scale", end_scale, dur).set_ease(Tween.EASE_IN)
	tw.tween_property(fc, "rotation", randf_range(-0.15, 0.15), dur)
	await tw.finished
	fc.queue_free()


func _vignette(col: Color) -> void:
	var r := Vignette.new()
	r.col = col
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(r)
	var tw := r.create_tween()
	tw.tween_property(r, "modulate:a", 0.0, 0.6)
	tw.tween_callback(r.queue_free)


func _screen_flash(col: Color) -> void:
	var r := ColorRect.new()
	r.color = col
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(r)
	var tw := r.create_tween()
	tw.tween_property(r, "modulate:a", 0.0, 0.35)
	tw.tween_callback(r.queue_free)


# ===================================================================== log ===

func _on_log(text: String, who: int) -> void:
	var col := "#ece7da"
	if who == me:
		col = "#8fd0ff"
	elif who == rival:
		col = "#ffb09a"
	elif who == -2:
		col = "#f2c96b"
	_log_lines.append("[color=%s]%s[/color]" % [col, text.replace("[", "(").replace("]", ")")])
	if _log_lines.size() > LOG_MAX:
		_log_lines.pop_front()
	if log_text != null:
		log_text.text = "\n".join(_log_lines)


# ================================================================== result ===

func _show_result(r: String) -> String:
	if r != "won" and spec.get("retry", false) and not _watching():
		# a main story duel: the story is taken back, and played again
		return await StoryLoss.new().play(self)
	if r != "won" and spec.get("trial", false) and not _watching():
		# the Trial of Light: a mistake, and the mirrors simply begin again
		return await _trial_reset()
	var title: String = {"won": "VICTORY", "lost": "DEFEAT", "draw": "DRAW"}[r]
	if _watching():
		var wn := String(game.players[game.winner].player_name) if game.winner in [0, 1] else ""
		title = "DRAW" if wn == "" else ("YOU WIN" if wn == "You" else "%s WINS" % wn.to_upper())
	var col := UITheme.GOLD if r == "won" or _watching() else (Color("c7cbe0") if r == "draw" else Color("e06070"))
	var burst := ResultBurst.new()
	burst.col = col
	burst.title = title
	burst.won = r == "won" or _watching()
	burst.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(burst)
	var bt := burst.create_tween()
	bt.tween_property(burst, "t", 1.0, 0.7)
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UITheme.sb(Color(0.03, 0.04, 0.08, 0.92), UITheme.GOLD_DIM, 26, 2, 36))
	overlay.add_child(box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	box.add_child(v)
	var why := UITheme.label(game.win_reason, 30, UITheme.TEXT)
	why.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(why)
	var p: DuelPlayer = game.players[me]
	var q: DuelPlayer = game.players[rival]
	var st := UITheme.label("%d turns  ·  your Life %d  ·  their Life %d  ·  knockouts %d – %d" % [game.turn, maxi(0, p.life), maxi(0, q.life), p.stats.kos, q.stats.kos], 26, UITheme.TEXT_DIM)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(st)
	if r == "won" and (not _watching() or Game.settings.get("debug_autoplay", false)):
		# the rewards scroll if there are many, so the buttons always stay on screen
		var sc := ScrollContainer.new()
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		sc.custom_minimum_size = Vector2(1100, 0)
		var lines := _reward_lines()
		var rv := VBoxContainer.new()
		rv.add_theme_constant_override("separation", 10)
		rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.add_child(rv)
		for line in lines:
			var rl := UITheme.label(line, 28, UITheme.GOLD)
			rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			rv.add_child(rl)
		v.add_child(sc)
		await get_tree().process_frame
		sc.custom_minimum_size.y = minf(rv.size.y + 8, overlay.size.y * 0.32)
		# an advert the player can choose to watch, to double this win
		if _won_resonance > 0 and spec.get("story", false) and Ads.can_offer_rewarded():
			var dbl := UITheme.button("Watch an advert: double this win's Resonance (%d left today)" % Ads.rewarded_left_today(), false, 0)
			dbl.custom_minimum_size = Vector2(0, 84)
			dbl.add_theme_font_size_override("font_size", 26)
			dbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			dbl.pressed.connect(func() -> void:
				dbl.disabled = true
				if await Ads.rewarded("double_resonance"):
					var extra := Game.add_resonance(_won_resonance)
					var t := "Doubled! +%d more Resonance." % _won_resonance
					if not extra.made.is_empty():
						t += "  %s crystallises in your hand!" % DuelCards.CARDS[extra.made[0]].name
					elif String(extra.get("target", "")) != "":
						t += "  %s: %d / %d" % [DuelCards.CARDS[extra.target].name, int(extra.banked_after), DuelRewards.card_cost(extra.target)]
					dbl.text = t
					Game.save_game()
				else:
					dbl.text = "No reward: the advert was stopped early."
				)
			v.add_child(dbl)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 24)
	v.add_child(hb)
	var story: bool = spec.get("story", false)
	var again := UITheme.button("Try again" if story else "Duel again", not story or r != "won", 340)
	var back := UITheme.button("Continue" if story else "Back to the Lab", story and r == "won", 340)
	# spec.once: the result stands, win or lose (the Lantern Duel's rematch)
	again.visible = not (story and r == "won") and not spec.get("once", false)
	hb.add_child(again)
	hb.add_child(back)
	var picked := [""]
	again.pressed.connect(func() -> void: picked[0] = "again")
	back.pressed.connect(func() -> void: picked[0] = r if r != "draw" else "draw")
	box.modulate.a = 0.0
	await get_tree().process_frame
	await get_tree().process_frame
	# centred a little below the middle, and never off the bottom of the
	# screen; drawn at the player's text size, as big as fits
	var sr := _safe_rect()
	var k := minf(SafeArea.ui_scale(), minf((sr.size.x - 40.0) / maxf(1.0, box.size.x), (sr.size.y - 80.0) / maxf(1.0, box.size.y)))
	k = maxf(k, 0.5)
	box.scale = Vector2(k, k)
	var bsz := box.size * k
	var y := clampf(sr.position.y + sr.size.y * 0.56 - bsz.y * 0.5, sr.position.y + 40.0, sr.end.y - bsz.y - 40.0)
	# below the big title (ResultBurst) where there's room: a win's box, with
	# its rewards, is taller, and its top lay over the title's words
	var tk := minf(overlay.size.x / 1920.0, overlay.size.y / 1080.0)
	var under_title := overlay.size.y * 0.4 + 150.0 * tk * 0.55 + 16.0
	if y < under_title:
		y = maxf(y, minf(under_title, sr.end.y - bsz.y - 24.0))
	box.position = Vector2(sr.position.x + (sr.size.x - bsz.x) * 0.5, y)
	var tw := box.create_tween()
	tw.tween_property(box, "modulate:a", 1.0, 0.3).set_delay(0.5)
	while picked[0] == "":
		await get_tree().process_frame
	return picked[0]


## The Trial of Light not passed: the mirrors flare white, the keeper of the
## Trial says her line (spec.reset_lines: [on a reset, on the third reset]),
## and the board is set again. Returns "again".
func _trial_reset() -> String:
	var n := int(spec.get("_resets", 0)) + 1
	spec["_resets"] = n
	var lines: Array = spec.get("reset_lines", ["Again."])
	var line := String(lines[1]) if n == 3 and lines.size() > 1 else String(lines[0])
	if hint != null:
		hint.visible = false
	var root := Control.new()
	root.name = "TrialReset"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(root)
	var glare := ColorRect.new()
	glare.color = Color(1.0, 0.98, 0.9, 0.0)
	glare.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glare.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(glare)
	var tw := root.create_tween()
	tw.tween_property(glare, "color:a", 0.85, 0.5)
	tw.tween_property(glare, "color", Color(0.02, 0.02, 0.05, 0.8), 0.9)
	sfx.play("ward_spring")
	await tw.finished
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	root.add_child(box)
	var who := UITheme.label(String(spec.get("bark_who", "")).to_upper(), 34, UITheme.GOLD_DIM, "display_bold")
	who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(who)
	var say := UITheme.label(line, 44, UITheme.TEXT, "body")
	say.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	say.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	say.custom_minimum_size = Vector2(minf(1300.0, size.x * 0.8), 0)
	box.add_child(say)
	await get_tree().process_frame
	box.position = (root.size - box.size) * 0.5
	box.modulate.a = 0.0
	root.create_tween().tween_property(box, "modulate:a", 1.0, 0.4)
	var tapped := [false]
	root.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			tapped[0] = true)
	var t := 0.0
	var hold := 1.6 + line.length() * 0.06
	while t < hold and not (tapped[0] and t > 0.6):
		await get_tree().process_frame
		t += get_process_delta_time()
	return "again"


## What the win earned (v2 Resonance and Rank). In a story duel the
## player's progress is updated; in the Lab it only says what it's worth.
func _reward_lines() -> Array:
	var rw: Dictionary = spec.get("rewards", {})
	var kind: String = rw.get("opponent", "kingdom")
	if rw.is_empty() or not spec.get("story", false):
		var res := DuelRewards.resonance(game, me, kind, bool(rw.get("thick", false)), false)
		return ["This win makes %d Resonance (%s)." % [res.total, _resonance_why(res)]]
	var out := Game.record_win(game, me, kind, bool(rw.get("thick", false)), false)
	_won_resonance = int(out.resonance.total)
	var lines := ["+%d Resonance  (%s)" % [out.resonance.total, _resonance_why(out.resonance)]]
	var target: String = out.get("target", "")
	if not out.made.is_empty():
		lines.append("%s crystallises in your hand!" % DuelCards.CARDS[out.made[0]].name)
	elif target != "":
		lines.append("Building towards %s: %d / %d Resonance" % [DuelCards.CARDS[target].name, out.banked_after, DuelRewards.card_cost(target)])
	if int(out.overflow) > 0:
		lines.append("+%d to your Attunement pool" % out.overflow)
	if int(out.ranks_gained) > 0:
		lines.append("Sigil Rank %d!  +%d attribute points to place" % [out.rank_after, int(out.ranks_gained) * DuelRewards.POINTS_PER_RANK])
	elif out.capped:
		lines.append("Sigil Rank %d: earn a Seal to rise higher" % out.rank_after)
	else:
		lines.append("Sigil Rank %d  ·  %d / %d to Rank %d" % [out.rank_after, out.xp_after, out.xp_next, out.rank_after + 1])
	return lines


static func _resonance_why(res: Dictionary) -> String:
	var parts := []
	for l in res.lines:
		if l.has("add"):
			parts.append("%s %+d" % [l.text, l.add])
		else:
			parts.append("%s ×%s" % [l.text, str(l.mult)])
	return ", ".join(parts)


# ============================================================ inner views ===

## The backdrop: the painted arena (dimmed so the cards stay readable) or,
## without art, a dark hall with a drawn duelling Circle.
class Arena:
	extends Control
	var stage: Control
	var edge := 0.0
	var overlay_only := false       # 3D field underneath: only draw the HUD shading and motes
	var tex: Texture2D = null
	var mote_col := Color(1.0, 0.8, 0.45)
	var _t := 0.0
	var _old_tex: Texture2D = null   # the ground a Terrain Rite is fading out (Phase D)
	var _fade := 1.0

	## A new painting fades in over the old one.
	func fade_to(t: Texture2D, dur: float = 1.2) -> void:
		if t == null or t == tex:
			return
		_old_tex = tex
		tex = t
		_fade = 0.0
		var tw := create_tween()
		tw.tween_property(self, "_fade", 1.0, dur)
		tw.tween_callback(func() -> void: _old_tex = null)

	## Where the painted Circle sits: this point of the picture (0-1)...
	const ART_ANCHOR := Vector2(0.5, 0.55)
	## ...lands on this point of the stage, with the picture at least this wide.
	const STAGE_ANCHOR := Vector2(1000, 486)
	const MIN_WIDTH := 1.22

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		if overlay_only and stage != null:
			_draw_overlay()
			return
		if tex != null and stage != null:
			_draw_art()
			return
		CardFace.vgrad_rect(self, Rect2(Vector2.ZERO, size), Color("141a33"), Color("06070d"))
		if stage == null:
			return
		var k := stage.scale.x
		var o := stage.position
		var c := o + Vector2(1000, 476) * k
		var rx := 640.0 * k
		var ry := 380.0 * k
		for i in 6:
			_ellipse(c, Vector2(rx, ry) * (1.0 - i * 0.05), Color(0.95, 0.8, 0.45, 0.018))
		_ring(c, Vector2(rx, ry), Color(UITheme.GOLD, 0.28 + 0.06 * sin(_t * 0.8)), 3.0 * k)
		_ring(c, Vector2(rx, ry) * 0.93, Color(UITheme.GOLD, 0.12), 2.0 * k)
		for i in 28:
			var a := TAU * i / 28.0 + _t * 0.03
			var p := c + Vector2(cos(a) * rx * 0.965, sin(a) * ry * 0.965)
			draw_circle(p, 3.5 * k, Color(UITheme.GOLD, 0.35))
		# the line between the two sides
		draw_line(o + Vector2(430, 476) * k, o + Vector2(1570, 476) * k, Color(UITheme.GOLD, 0.18), 2.0 * k)

	func _draw_art() -> void:
		var k := stage.scale.x
		var o := stage.position
		# the screen in stage units, so the picture covers it on any shape of screen
		var tl := -o / k
		var br := (size - o) / k
		var ax := STAGE_ANCHOR
		var w := MIN_WIDTH * 1920.0
		var aspect := float(tex.get_height()) / float(tex.get_width())
		w = maxf(w, (ax.x - tl.x) / ART_ANCHOR.x)
		w = maxf(w, (br.x - ax.x) / (1.0 - ART_ANCHOR.x))
		w = maxf(w, (ax.y - tl.y) / (ART_ANCHOR.y * aspect))
		w = maxf(w, (br.y - ax.y) / ((1.0 - ART_ANCHOR.y) * aspect))
		var sz := Vector2(w, w * aspect)
		var r := Rect2(o + (ax - sz * ART_ANCHOR) * k, sz * k)
		if _old_tex != null and _fade < 1.0:
			draw_texture_rect(_old_tex, r, false)
			draw_texture_rect(tex, r, false, Color(1, 1, 1, _fade))
		else:
			draw_texture_rect(tex, r, false)
		# dim it so the cards and numbers stay the brightest things on screen
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.03, 0.07, 0.38))
		# darker under the hand, behind the side columns and at the very top
		var hand_top := o.y + 740.0 * k
		CardFace.vgrad_rect(self, Rect2(Vector2(0, hand_top), Vector2(size.x, size.y - hand_top)), Color(0.01, 0.01, 0.03, 0.0), Color(0.01, 0.01, 0.03, 0.82))
		CardFace.vgrad_rect(self, Rect2(Vector2.ZERO, Vector2(size.x, o.y + 120.0 * k)), Color(0.01, 0.01, 0.03, 0.55), Color(0.01, 0.01, 0.03, 0.0))
		_hgrad(Rect2(Vector2.ZERO, Vector2(o.x + (440.0 - edge) * k, size.y)), Color(0.01, 0.01, 0.03, 0.66), Color(0.01, 0.01, 0.03, 0.0))
		var rx := o.x + (1560.0 + edge) * k
		_hgrad(Rect2(Vector2(rx, 0), Vector2(size.x - rx, size.y)), Color(0.01, 0.01, 0.03, 0.0), Color(0.01, 0.01, 0.03, 0.7))
		# drifting motes of light
		for i in 34:
			var sd := float(i) * 12.9898
			var fx := absf(fmod(sin(sd) * 43758.5453, 1.0))
			var rise := 14.0 + 22.0 * absf(fmod(sin(sd * 1.7) * 9631.2, 1.0))
			var y := fmod(_t * rise + float(i) * 97.0, 1080.0)
			var p := o + Vector2(440.0 + fx * 1120.0 + sin(_t * 0.7 + i) * 18.0, 1000.0 - y) * k
			var life := sin(y / 1080.0 * PI)
			draw_circle(p, (2.0 + float(i % 3)) * k, Color(mote_col, 0.35 * life))

	## Over the 3D field: shade the HUD columns and the hand so they read.
	func _draw_overlay() -> void:
		var k := stage.scale.x
		var o := stage.position
		# (the field fills the whole screen on any shape: DuelField3D.fit_to_stage)
		var hand_top := o.y + 760.0 * k
		CardFace.vgrad_rect(self, Rect2(Vector2(0, hand_top), Vector2(size.x, size.y - hand_top)), Color(0.01, 0.01, 0.03, 0.0), Color(0.01, 0.01, 0.03, 0.75))
		CardFace.vgrad_rect(self, Rect2(Vector2.ZERO, Vector2(size.x, o.y + 110.0 * k)), Color(0.01, 0.01, 0.03, 0.5), Color(0.01, 0.01, 0.03, 0.0))
		_hgrad(Rect2(Vector2.ZERO, Vector2(o.x + (440.0 - edge) * k, size.y)), Color(0.01, 0.01, 0.03, 0.6), Color(0.01, 0.01, 0.03, 0.0))
		var rx := o.x + (1560.0 + edge) * k
		_hgrad(Rect2(Vector2(rx, 0), Vector2(size.x - rx, size.y)), Color(0.01, 0.01, 0.03, 0.0), Color(0.01, 0.01, 0.03, 0.65))

	func _hgrad(r: Rect2, a: Color, b: Color) -> void:
		var pts := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
		draw_polygon(pts, PackedColorArray([a, b, b, a]))

	func _ellipse(c: Vector2, r: Vector2, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in 64:
			var a := TAU * i / 64.0
			pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
		draw_colored_polygon(pts, col)

	func _ring(c: Vector2, r: Vector2, col: Color, w: float) -> void:
		var pts := PackedVector2Array()
		for i in 97:
			var a := TAU * i / 96.0
			pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
		draw_polyline(pts, col, w, true)


## The band that sweeps across the field for turns, the duel's start and Gifts.
class Banner:
	extends Control
	var text := ""
	var sub := ""
	var footer := ""      # "TAP TO CONTINUE": the banner waits for a tap
	var col := Color.WHITE
	var size_px := 72
	var god := ""
	var edge := 0.0
	var _pulse := 0.0
	var t := 0.0:
		set(v):
			t = v
			queue_redraw()

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		if footer != "":
			_pulse += delta
			queue_redraw()

	func _draw() -> void:
		var tin := clampf(t / 0.16, 0.0, 1.0)
		var tout := clampf((t - 0.84) / 0.16, 0.0, 1.0)
		var e_in := 1.0 - pow(1.0 - tin, 3.0)
		var h := ((200.0 if sub != "" else 180.0) + (60.0 if footer != "" else 0.0)) * e_in * (1.0 - tout)
		if h < 1.0:
			return
		var x0 := -edge - 40.0
		var x1 := 1920.0 + edge + 40.0
		var top := -h * 0.5
		var mid := Color(0.01, 0.01, 0.03, 0.84)
		var clear := Color(0.01, 0.01, 0.03, 0.0)
		CardFace.vgrad_rect(self, Rect2(Vector2(x0, top), Vector2(x1 - x0, h * 0.25)), clear, mid)
		draw_rect(Rect2(Vector2(x0, top + h * 0.25), Vector2(x1 - x0, h * 0.5)), mid)
		CardFace.vgrad_rect(self, Rect2(Vector2(x0, top + h * 0.75), Vector2(x1 - x0, h * 0.25)), mid, clear)
		DuelFX.draw_glow(self, Vector2(960, 0), Vector2(900, h * 0.6), Color(col, 0.2))
		var lw := 980.0 * e_in
		var la := 0.85 * (1.0 - tout)
		draw_line(Vector2(960 - lw, top + 16), Vector2(960 + lw, top + 16), Color(col, la), 2.5)
		draw_line(Vector2(960 - lw, -top - 16), Vector2(960 + lw, -top - 16), Color(col, la), 2.5)
		draw_line(Vector2(960 - lw * 0.7, top + 22), Vector2(960 + lw * 0.7, top + 22), Color(col, la * 0.4), 1.0)
		draw_line(Vector2(960 - lw * 0.7, -top - 22), Vector2(960 + lw * 0.7, -top - 22), Color(col, la * 0.4), 1.0)
		# a streak of light sweeping across
		var sx := lerpf(x0, x1, clampf((t - 0.04) / 0.5, 0.0, 1.0))
		DuelFX.draw_glow(self, Vector2(sx, 0), Vector2(300, h * 0.45), Color(1, 1, 1, 0.3 * (1.0 - tout)))
		# the words slide in, settle, then slip away
		var slide := (1.0 - e_in) * 240.0 - tout * 180.0
		var a := clampf(t / 0.1, 0.0, 1.0) * (1.0 - tout)
		var fnt := CardFace.font("display_bold")
		var fs := CardFace.fit_size(fnt, text, size_px, 1400)
		var k := 1.0 + 0.22 * (1.0 - e_in)
		var y := fs * 0.34 - (16.0 if sub != "" else 0.0)
		draw_set_transform(Vector2(960 + slide, 0), 0.0, Vector2(k, k))
		CardFace.text(self, fnt, Vector2(-900, y), text, fs, Color(col.lightened(0.3), a), HORIZONTAL_ALIGNMENT_CENTER, 1800, maxi(6, fs / 9), Color(0, 0, 0, 0.85 * a))
		if sub != "":
			CardFace.text(self, CardFace.font("bold"), Vector2(-900, y + 48), sub, 30 if footer != "" else 28, Color(1, 1, 1, 0.85 * a), HORIZONTAL_ALIGNMENT_CENTER, 1800, 4)
		if footer != "" and tout <= 0.0:
			# "TAP TO CONTINUE", breathing, once the words are in
			var fa := clampf((t - 0.3) / 0.15, 0.0, 1.0) * (0.55 + 0.3 * sin(_pulse * 3.2))
			CardFace.text(self, CardFace.font("bold"), Vector2(-900, y + 96), footer, 22, Color(UITheme.GOLD, fa), HORIZONTAL_ALIGNMENT_CENTER, 1800, 3)
		draw_set_transform(Vector2.ZERO)
		if god != "" and DuelArt.god(god) != null and a > 0.05:
			var tw_px := fnt.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var gc := Vector2(960 + slide - tw_px * 0.5 - 120, 0)
			draw_circle(gc, 86, Color(0, 0, 0, 0.6 * a))
			DuelFX.draw_glow(self, gc, Vector2(150, 150), Color(UITheme.GOLD, 0.35 * a))
			DuelArt.god_medallion(self, gc, 76.0 * e_in * (1.0 - tout * 0.5), god, UITheme.GOLD)


## A move's name, flashed above the creature using it.
class MoveLabel:
	extends Node2D
	var text := ""
	var col := Color.WHITE
	var t := 0.0:
		set(v):
			t = v
			queue_redraw()

	func _draw() -> void:
		var fnt := CardFace.font("display_bold")
		var fs := 34
		var w := fnt.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 64
		var k := 1.0 + 0.35 * (1.0 - clampf(t / 0.12, 0.0, 1.0))
		var a := clampf((1.0 - t) / 0.25, 0.0, 1.0)
		draw_set_transform(Vector2(0, -t * 30.0), 0.0, Vector2(k, k))
		var r := Rect2(Vector2(-w * 0.5, -28), Vector2(w, 56))
		CardFace.box(self, Rect2(r.position + Vector2(0, 4), r.size), 28, Color(0, 0, 0, 0.45 * a))
		CardFace.vgrad(self, r, 28, Color(0.12, 0.12, 0.2, 0.95 * a), Color(0.02, 0.02, 0.05, 0.95 * a))
		CardFace.box(self, r, 28, Color(0, 0, 0, 0), Color(col, a), 3.0)
		CardFace.text_in(self, fnt, r, text, fs, Color(1, 1, 1, a), HORIZONTAL_ALIGNMENT_CENTER, 4)
		draw_set_transform(Vector2.ZERO)


## A card in flight (from hand to slot, or into a Ward zone).
class FlyCard:
	extends Control
	var card_id := ""

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		DuelFX.draw_glow(self, size * 0.5, size * 0.9, Color(1, 0.95, 0.8, 0.45))
		if card_id == "":
			CardFace.draw_back(self, r)
		else:
			DuelCardFace.draw_card(self, r, card_id, {"compact": true})


## A wash of colour around the screen's edges (you've been hit).
class Vignette:
	extends Control
	var col := Color.RED

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := size.x * 0.22
		var h := size.y * 0.3
		var c0 := Color(col, 0.55)
		var c1 := Color(col, 0.0)
		_quad(Rect2(Vector2.ZERO, Vector2(w, size.y)), c0, c1, true)
		_quad(Rect2(Vector2(size.x - w, 0), Vector2(w, size.y)), c1, c0, true)
		_quad(Rect2(Vector2.ZERO, Vector2(size.x, h)), c0, c1, false)
		_quad(Rect2(Vector2(0, size.y - h), Vector2(size.x, h)), c1, c0, false)

	func _quad(r: Rect2, a: Color, b: Color, horizontal: bool) -> void:
		var pts := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
		if horizontal:
			draw_polygon(pts, PackedColorArray([a, b, b, a]))
		else:
			draw_polygon(pts, PackedColorArray([a, a, b, b]))


## Curved, flowing arrows from the attacking Totem to everything it can hit.
## The Respond strip (Phase A): what's coming, the answers in hand (greyed
## when they can't be paid for), a countdown bar and "Let it be".
class RespondStrip:
	extends Control
	signal done(card)
	var screen = null   # DuelScreen
	var event: Dictionary = {}
	var cards: Array = []
	var affordable: Array = []
	var left := 0.0
	var total := 6.0
	var _panel: PanelContainer
	var _finished := false

	func _init() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP   # a tap elsewhere lets it be, below

	func setup(p_event: Dictionary, p_cards: Array, p_affordable: Array) -> void:
		event = p_event
		cards = p_cards
		affordable = p_affordable
		total = maxf(1.0, DuelRules.respond_secs)
		left = total
		_panel = PanelContainer.new()
		_panel.add_theme_stylebox_override("panel", UITheme.sb(Color(0.03, 0.035, 0.07, 0.96), UITheme.GOLD, 18, 3, 22))
		add_child(_panel)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 10)
		_panel.add_child(col)
		var head := UITheme.label("RESPOND?", 30, UITheme.GOLD, "display_bold")
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(head)
		var what := UITheme.label(screen.event_text(event) + ". It hasn't landed yet.", 24, UITheme.TEXT)
		what.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		what.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		what.custom_minimum_size = Vector2(1000, 0)
		col.add_child(what)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_child(row)
		for c in cards:
			var card: DuelCard = c
			var b := ActionButton.new()
			b.title = card.card_name()
			var prob: String = screen.game.answer_problem(screen.me, card, event)
			b.sub = DuelCards.card_text(card.id) if prob == "" else prob
			b.cost = card.cost()
			b.enabled = prob == ""
			b.custom_minimum_size = Vector2(384, 96)
			b.pressed.connect(func() -> void:
				if b.enabled:
					screen.sfx.play("ui_tap")
					_finish(card)
				else:
					screen.sfx.play("ui_error")
					screen._show_detail(card.id, {"cost": card.cost()}))
			row.add_child(b)
		var foot := HBoxContainer.new()
		foot.add_theme_constant_override("separation", 20)
		foot.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_child(foot)
		var let := UITheme.button("Let it be", false, 300)
		let.custom_minimum_size = Vector2(300, 70)
		let.pressed.connect(func() -> void:
			screen.sfx.play("ui_back")
			_finish(null))
		foot.add_child(let)
		call_deferred("_place")

	func _place() -> void:
		var sz := _panel.get_combined_minimum_size()
		_panel.size = sz
		_panel.position = Vector2((size.x - sz.x) * 0.5, 540.0 - sz.y * 0.5)

	func _process(delta: float) -> void:
		left -= delta
		queue_redraw()
		if left <= 0.0:
			_finish(null)

	func _finish(card) -> void:
		if _finished:
			return
		_finished = true
		done.emit(card)

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			if not _panel.get_global_rect().has_point(e.global_position):
				_finish(null)   # tapped away: let it be
			accept_event()

	func _unhandled_input(e: InputEvent) -> void:
		if e.is_action_pressed("ui_cancel"):
			_finish(null)
			get_viewport().set_input_as_handled()

	func _draw() -> void:
		if _panel == null or _panel.size == Vector2.ZERO:
			return
		# the countdown: a bar along the panel's top edge, draining
		var r := Rect2(_panel.position + Vector2(24, -10), Vector2(_panel.size.x - 48, 8))
		CardFace.box(self, r, 4, Color(0, 0, 0, 0.6))
		var k := clampf(left / total, 0.0, 1.0)
		var col := UITheme.GOLD if k > 0.35 else Color("ff8a5a")
		if k > 0.0:
			CardFace.box(self, Rect2(r.position, Vector2(r.size.x * k, r.size.y)), 4, col)


class TargetArrows:
	extends Control
	var screen: DuelScreen
	var _t := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		material = DuelFX.additive()

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		if screen == null or screen.mode != "main" or screen.sel_totem == null:
			return
		if screen.pending != "move" and screen.pending != "gift":
			return
		var from := screen._center(screen._view(screen.sel_totem))
		for tg in screen.targets:
			var to: Vector2
			if tg is DuelTotem:
				if tg == screen.sel_totem:
					continue
				to = screen._center(screen._view(tg))
			elif tg is String and tg == DuelGame.LIFE:
				to = screen._life_center(screen.rival)
			else:
				continue
			_arrow(from, to, UITheme.GOLD if not (tg is DuelTotem and tg.owner == screen.me) else Color(0.5, 1.0, 0.6))

	func _arrow(a: Vector2, b: Vector2, col: Color) -> void:
		var mid := (a + b) * 0.5 + Vector2(0, -minf(220.0, a.distance_to(b) * 0.35))
		var pts := PackedVector2Array()
		var n := 40
		for i in n + 1:
			var k := float(i) / n
			pts.append(a.lerp(mid, k).lerp(mid.lerp(b, k), k))
		# trim the ends so the arrow sits between the two
		var start := 6
		var stop := n - 5
		var body := pts.slice(start, stop + 1)
		draw_polyline(body, Color(col, 0.2), 24.0, true)
		draw_polyline(body, Color(col, 0.45), 8.0, true)
		# pulses flowing along it
		for j in 4:
			var f := fmod(_t * 0.9 + j * 0.25, 1.0)
			var idx := int(lerpf(start, stop, f))
			DuelFX.draw_glow(self, pts[idx], Vector2(22, 22), Color(col, 0.9 * sin(f * PI)))
		# the head
		var tip := pts[stop]
		var dir := (pts[stop] - pts[stop - 2]).normalized()
		var nn := Vector2(-dir.y, dir.x)
		var head := PackedVector2Array([tip + dir * 26, tip - dir * 10 + nn * 20, tip - dir * 10 - nn * 20])
		draw_colored_polygon(head, Color(col, 0.85))
		DuelFX.draw_glow(self, tip, Vector2(40, 40), Color(col, 0.6))


## The end of the duel: rays, a burst of light and the big word.
class ResultBurst:
	extends Control
	var col := Color.WHITE
	var title := ""
	var won := true
	var _time := 0.0
	var t := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var e := 1.0 - pow(1.0 - clampf(t, 0.0, 1.0), 3.0)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.7 * e))
		var k := minf(size.x / 1920.0, size.y / 1080.0)
		var c := Vector2(size.x * 0.5, size.y * 0.4)
		if won:
			for i in 24:
				var a := TAU * i / 24.0 + _time * 0.15
				var d := Vector2(cos(a), sin(a))
				var nn := Vector2(-d.y, d.x)
				var L := size.length() * e
				draw_colored_polygon(PackedVector2Array([c + nn * 4, c + d * L + nn * L * 0.09, c + d * L - nn * L * 0.09, c - nn * 4]), Color(col, 0.06 + 0.03 * sin(_time * 2.0 + i)))
		DuelFX.draw_glow(self, c, Vector2(700, 300) * k * e, Color(col, 0.35))
		var fnt := CardFace.font("display_bold")
		var fs := int(150 * k * (0.7 + 0.3 * e))
		fs = CardFace.fit_size(fnt, title, fs, size.x - 100)
		var lw := 700.0 * k * e
		draw_line(c + Vector2(-lw, fs * 0.55), c + Vector2(lw, fs * 0.55), Color(col, 0.8), 3.0)
		draw_line(c + Vector2(-lw, -fs * 0.85), c + Vector2(lw, -fs * 0.85), Color(col, 0.8), 3.0)
		CardFace.text(self, fnt, Vector2(0, c.y + fs * 0.32), title, fs, Color(col.lightened(0.25), e), HORIZONTAL_ALIGNMENT_CENTER, size.x, maxi(8, fs / 10), Color(0, 0, 0, 0.85 * e))


## A patron's face in a gold ring.
class GodFace:
	extends Control
	var god := ""

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size * 0.5
		var rad := minf(size.x, size.y) * 0.5 - 6
		draw_circle(c, rad + 10, Color(UITheme.GOLD, 0.15))
		DuelArt.god_medallion(self, c, rad, god, UITheme.GOLD)


## The big card in the right column.
class DetailCard:
	extends Control
	var card_id := ""
	var opts := {}

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func show_card(id: String, p_opts: Dictionary = {}) -> void:
		card_id = id
		opts = p_opts
		queue_redraw()

	func _draw() -> void:
		if card_id == "":
			CardFace.box(self, Rect2(Vector2.ZERO, size), 16, Color(1, 1, 1, 0.03), Color(1, 1, 1, 0.08), 2.0)
			CardFace.text(self, CardFace.font("body"), Vector2(0, size.y * 0.5), "Tap any card to read it", 24, UITheme.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER, size.x)
			return
		var o := opts.duplicate()
		o["compact"] = false
		DuelFX.draw_glow(self, size * 0.5, size * 0.75, Color(0.55, 0.75, 1.0, 0.25))
		CardFace.box(self, Rect2(Vector2(8, 14), size), 16, Color(0, 0, 0, 0.55))
		DuelCardFace.draw_card(self, Rect2(Vector2.ZERO, size), card_id, o)


## A card flipped up in the middle of the Circle (a Rite being cast, a Ward springing).
class BigCard:
	extends Control
	var card_id := ""
	var tag := ""
	var tag_col := Color.WHITE

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		var tt := Time.get_ticks_msec() / 1000.0
		for i in 16:
			var a := TAU * i / 16.0 + tt * 0.35
			var d := Vector2(cos(a), sin(a))
			var nn := Vector2(-d.y, d.x)
			draw_colored_polygon(PackedVector2Array([c + nn * 6, c + d * 520 + nn * 60, c + d * 520 - nn * 60, c - nn * 6]), Color(tag_col.lightened(0.3), 0.07))
		DuelFX.draw_glow(self, c, size * 0.95, Color(tag_col.lightened(0.3), 0.5))
		CardFace.box(self, Rect2(Vector2(-10, -10), size + Vector2(20, 20)), 22, Color(0, 0, 0, 0.5))
		DuelCardFace.draw_card(self, Rect2(Vector2.ZERO, size), card_id, {"compact": false})
		var r := Rect2(Vector2(size.x * 0.5 - 90, -34), Vector2(180, 52))
		CardFace.box(self, r, 26, tag_col, Color.WHITE, 2.0)
		CardFace.text_in(self, CardFace.font("display_bold"), r, tag, 30, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 4)


## A column of light where a Totem is called.
class Beam:
	extends Control
	var col := Color.WHITE

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := size.x
		for i in 5:
			var inset := w * 0.1 * i
			CardFace.vgrad_rect(self, Rect2(Vector2(inset, 0), Vector2(w - inset * 2, size.y)), Color(col, 0.0), Color(col, 0.12 + i * 0.05))


## One tall mirror of the Hall of Mirrors: arched, gilt-framed glass that
## shows the Demigod (its art, or a burning shape of its light with none) as
## `show` goes to 1, and is only glass again at 0.
class MirrorPane:
	extends Control
	var tex: Texture2D = null
	var col := Color.WHITE
	var lit := 0.0:
		set(v):
			lit = v
			queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var arch := size.x * 0.5
		var glass := PackedVector2Array()
		# the glass: a rectangle under a round arch
		for i in 17:
			var a := PI + PI * float(i) / 16.0
			glass.append(Vector2(arch + cos(a) * (arch - 8.0), arch + sin(a) * (arch - 8.0)))
		glass.append(Vector2(size.x - 8.0, size.y - 8.0))
		glass.append(Vector2(8.0, size.y - 8.0))
		draw_colored_polygon(glass, Color(0.62, 0.66, 0.74, 0.55))
		if lit > 0.01:
			var inner := Rect2(Vector2(10, 10), size - Vector2(20, 20))
			if tex != null:
				DuelArt.cover(self, inner, tex, Vector2(0.5, 0.3), Color(1, 1, 1, lit))
			else:
				for i in 6:
					var rr := (size.x * 0.42) * (1.0 - i * 0.14)
					draw_circle(Vector2(arch, size.y * 0.48), rr, Color(col.r, col.g, col.b, 0.12 * lit))
			# the glass's own sheen over it
			draw_colored_polygon(glass, Color(1, 1, 1, 0.08 * lit))
		# the gilt frame
		var rim := glass.duplicate()
		rim.append(glass[0])
		draw_polyline(rim, Color(0.86, 0.7, 0.36, 0.95), 5.0, true)
		draw_polyline(rim, Color(col.r, col.g, col.b, 0.6 * lit), 2.0, true)
		draw_rect(Rect2(r.position + Vector2(-4, size.y - 10), Vector2(size.x + 8, 10)), Color(0.66, 0.52, 0.26, 0.95))


## The Summon cinematic: the heavens open and the Demigod descends.
class SummonCine:
	extends Control
	var card_id := ""
	var mine := true
	var tween: Tween = null
	var scene: Texture2D = null
	var figure: Texture2D = null
	var t := 0.0:
		set(v):
			t = v
			queue_redraw()

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	## A tap hurries the cinematic along.
	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and tween != null and tween.is_valid():
			tween.set_speed_scale(4.0)
			accept_event()

	func has_art() -> bool:
		return scene != null and figure != null

	func _draw() -> void:
		if has_art():
			_draw_painted()
		else:
			_draw_plain()

	func _draw_painted() -> void:
		var d: Dictionary = DuelCards.CARDS[card_id]
		var col := Lore.color(d.element, 0)
		var a := clampf(t * 7.0, 0.0, 1.0) * clampf((1.0 - t) * 7.0, 0.0, 1.0)
		var k := minf(size.x / 1920.0, size.y / 1080.0)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.9 * a))
		# the opened heavens, drifting slowly closer
		var zoom := 1.1 - 0.1 * t
		var sr := Rect2(size * 0.5 - size * zoom * 0.5, size * zoom)
		DuelArt.cover(self, sr, scene, Vector2(0.5, 0.5), Color(1, 1, 1, a))
		# the Demigod comes down the beam and lands in the Circle
		var land := clampf((t - 0.08) / 0.42, 0.0, 1.0)
		var eo := 1.0 - pow(1.0 - land, 3.0)
		var fa := clampf((t - 0.06) * 6.0, 0.0, 1.0) * clampf((1.0 - t) * 7.0, 0.0, 1.0)
		var fh := size.y * 0.74 * (0.82 + 0.18 * eo)
		var fs := Vector2(fh * figure.get_width() / float(figure.get_height()), fh)
		var foot := Vector2(size.x * 0.5, size.y * 0.86 + (1.0 - eo) * -size.y * 0.95)
		if land >= 1.0:
			foot.y += sin(t * 9.0) * 6.0 * k
		var halo := foot - Vector2(0, fs.y * 0.5)
		for i in 7:
			draw_circle(halo, fs.y * (0.62 - i * 0.07), Color(col.lightened(0.3), 0.05 * fa))
		draw_texture_rect(figure, Rect2(foot - Vector2(fs.x * 0.5, fs.y), fs), false, Color(1, 1, 1, fa))
		# the flash as it lands
		var flash := clampf(1.0 - absf(t - 0.5) * 9.0, 0.0, 1.0)
		if flash > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(col.lightened(0.6), 0.55 * flash))
		# the name
		var ta := clampf((t - 0.48) * 6.0, 0.0, 1.0) * clampf((1.0 - t) * 7.0, 0.0, 1.0)
		if ta > 0.0:
			CardFace.vgrad_rect(self, Rect2(Vector2(0, size.y * 0.72), Vector2(size.x, size.y * 0.28)), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.8 * ta))
			var fnt := CardFace.font("display_bold")
			var nm := String(d.name).to_upper()
			var fsz := CardFace.fit_size(fnt, nm, int(84 * k), size.x - 80)
			CardFace.text(self, CardFace.font("bold"), Vector2(0, size.y - 150 * k), "SUMMON", int(34 * k), Color(col.lightened(0.4), ta), HORIZONTAL_ALIGNMENT_CENTER, size.x, int(6 * k))
			CardFace.text(self, fnt, Vector2(0, size.y - 60 * k), nm, fsz, Color(UITheme.GOLD, ta), HORIZONTAL_ALIGNMENT_CENTER, size.x, int(12 * k))

	func _draw_plain() -> void:
		var a := clampf(t * 4.0, 0.0, 1.0) * clampf((1.0 - t) * 5.0, 0.0, 1.0)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.85 * a))
		var d: Dictionary = DuelCards.CARDS[card_id]
		var col := Lore.color(d.element, 0)
		var c := size * 0.5
		for i in 16:
			var ang := TAU * i / 16.0 + t * 0.6
			var p1 := c + Vector2(cos(ang), sin(ang)) * 60.0
			var p2 := c + Vector2(cos(ang), sin(ang)) * size.length()
			draw_line(p1, p2, Color(col, 0.08 * a), 40.0)
		var k := minf(size.x / 1920.0, size.y / 1080.0)
		var cs := Vector2(420, 588) * k * (0.8 + 0.2 * clampf(t * 2.0, 0.0, 1.0))
		var drop := (1.0 - clampf(t * 2.5, 0.0, 1.0)) * -size.y * 0.5
		var r := Rect2(c - cs * 0.5 + Vector2(0, drop), cs)
		if a > 0.01:
			draw_set_transform(Vector2.ZERO)
			modulate.a = a
			DuelCardFace.draw_card(self, r, card_id, {"compact": false})
			var fnt := CardFace.font("display_bold")
			var fs := int(64 * k)
			CardFace.text(self, fnt, Vector2(0, r.end.y + 80 * k), String(d.name).to_upper(), CardFace.fit_size(fnt, String(d.name).to_upper(), fs, size.x - 80), UITheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER, size.x, int(10 * k))
			CardFace.text(self, CardFace.font("bold"), Vector2(0, r.position.y - 30 * k), "SUMMON", int(36 * k), Color(col, 0.9), HORIZONTAL_ALIGNMENT_CENTER, size.x, int(6 * k))


## A move or card action in the right column: name, cost and small print.
class ActionButton:
	extends Control
	signal pressed
	var title := ""
	var sub := ""
	var cost := 0
	var enabled := true
	var _hover := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_entered.connect(func() -> void:
			_hover = true
			queue_redraw())
		mouse_exited.connect(func() -> void:
			_hover = false
			queue_redraw())

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			pressed.emit()
			accept_event()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		CardFace.box(self, Rect2(r.position + Vector2(0, 5), r.size), 16, Color(0, 0, 0, 0.5))
		var top := Color("27325a") if enabled else Color("1a1d2a")
		var bot := Color("0d1226") if enabled else Color("0e1018")
		if _hover and enabled:
			top = Color("33427a")
		CardFace.vgrad(self, r, 16, top, bot)
		CardFace.vgrad(self, Rect2(r.position + Vector2(4, 3), Vector2(r.size.x - 8, r.size.y * 0.45)), 13, Color(1, 1, 1, 0.1 if enabled else 0.03), Color(1, 1, 1, 0.0))
		CardFace.box(self, r, 16, Color(0, 0, 0, 0), UITheme.GOLD if enabled else Color("3a3e54"), 2.5)
		CardFace.box(self, r.grow(-5), 12, Color(0, 0, 0, 0), Color(UITheme.GOLD, 0.18 if enabled else 0.05), 1.0)
		var x := 20.0
		if cost > 0:
			DuelCardFace.essence_gem(self, Vector2(42, size.y * 0.5), 24, cost, not enabled)
			x = 76.0
		var fnt := CardFace.font("display_bold")
		var col := Color.WHITE if enabled else Color("6a6d82")
		var ty := 44.0 if sub != "" else size.y * 0.5 + 11.0
		CardFace.text(self, fnt, Vector2(x, ty), title, CardFace.fit_size(fnt, title, 29, size.x - x - 16), col, HORIZONTAL_ALIGNMENT_LEFT, -1, 4)
		if sub != "":
			var body := CardFace.font("body")
			CardFace.text(self, body, Vector2(x, 78), sub, CardFace.fit_size(body, sub, 20, size.x - x - 16, 12), Color("b9c2e0") if enabled else Color("5a5d72"))
