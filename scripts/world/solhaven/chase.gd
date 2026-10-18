extends Node
## The chase in C3 (Master Script v3, Thief in the Market): Wren runs with the
## blank card, out of the market and down the lane, and the player runs after
## her. Objective: "Catch the thief. (Tap the glowing ledges to vault and
## slide.)" As the player comes up to each thing in the way, its ledge glows:
## a tap on it (or E, Space, Enter, a pad's A) vaults over it or slides under
## it without breaking stride. Miss it and the player pulls up short in front
## of it until the tap comes; there's no failing, only falling behind. Wren
## calls back over her shoulder, once each: "Keep up!", "Mind the washing!",
## "Oh, come on!". It ends in the dead-end alley, where she turns.
##
##   var ch := Chase.new(); await ch.play(world)

const SolSet := preload("res://scripts/world/solhaven/solhaven_set.gd")
const OBJECTIVE := "Catch the thief. (Tap the glowing ledges to vault and slide.)"
const RUN := 4.3          # the player, m/s
const WREN_RUN := 4.7
## How far before an obstacle its ledge lights up (m).
const LIGHT_AT := 7.0
## A tap counts for the lit ledge within this share of the screen's width of it.
const TAP_REACH := 0.3
## Where the lane turns into the alley.
const CORNER := Vector3(60.0, 0, 13.6)

var w: World
var _lit := -1               # the obstacle whose ledge is lit
var _tapped := false
var _layer: CanvasLayer
var _prompt: Label
var _bark_who: Label
var _bark: Label
var _ring: Control
var _cam_dir := Vector3(1, 0, 0)
var _running := false
var taps := 0                # for the tests: how many ledges were tapped
var stops := 0               # and how many times the player pulled up short


func play(world: World) -> void:
	w = world
	name = "Chase"
	w.add_child(self)
	_build_ui()
	var v: Node3D = w.get_meta("solhaven_set")
	var obstacles: Array = v.obstacles
	var start := w.player.global_position
	var lane := SolSet.SPOTS.lane_start as Vector3
	var dead := SolSet.SPOTS.dead_end as Vector3
	w.hud.set_objective(OBJECTIVE)
	Game.set_flag("objective", OBJECTIVE)
	# Wren, off ahead with the card
	var wren := _wren(Vector3(8.0, 0, -3.0))
	# her way: out of the market, down the lane over everything in it, round
	# the corner into the alley, under the arch, to the end
	# round the fountain's east side, between the lamps, past the market stalls
	var round := Vector3(5.6, 0, -6.6)
	var market := Vector3(9.5, 0, 12.6)
	var wren_route: Array = [round, market, lane]
	for o in SolSet.CHASE:
		if String(o.what) == "arch":
			wren_route.append(CORNER)
		wren_route.append(o.at)
	wren_route.append(dead + Vector3(0, 0, -1.6))
	_run_wren(wren_route)
	_running = true
	_bark_line("Keep up!")
	# after her: round the fountain, through the market, into the lane
	if start.x < round.x - 0.5 or start.z > round.z + 3.0:
		await Cine.walk(w, "player", round, RUN, "run")
	await Cine.walk(w, "player", market, RUN, "run")
	await Cine.walk(w, "player", lane, RUN, "run")
	var at := lane
	for i in SolSet.CHASE.size():
		var o: Dictionary = SolSet.CHASE[i]
		var ob: Vector3 = o.at
		var dir := (ob - at)
		dir.y = 0.0
		dir = dir.normalized()
		var before := ob - dir * 1.7
		var after := ob + dir * 1.7
		var glow: MeshInstance3D = (obstacles[i] as Node3D).get_meta("glow")
		# run up to it; the ledge lights when it's close
		var light_from := before - dir * LIGHT_AT
		if (light_from - w.player.global_position).dot(dir) > 0.0:
			await Cine.walk(w, "player", light_from, RUN, "run")
		_light(i, glow, true)
		if String(o.what) == "washing":
			_bark_line("Mind the washing!")
		if String(o.what) == "ledge":
			_bark_line("Oh, come on!")
		await _run_until_tap(before)
		if not _tapped:
			stops += 1
			var pf = Cine.fig(w, "player")
			if pf is Figure3D:
				(pf as Figure3D).walking = false
			while not _tapped and is_inside_tree():
				await get_tree().process_frame
		taps += 1
		_light(i, glow, false)
		if String(o.kind) == "vault":
			await _vault(before, after)
		else:
			await _slide(before, after)
		at = after
		if String(o.what) == "ledge":
			# the turn into the alley
			await Cine.walk(w, "player", CORNER, RUN, "run")
			at = CORNER
	# the dead end: she's there, and nowhere left to go
	await Cine.walk(w, "player", dead + Vector3(-0.3, 0, 3.2), RUN, "run")
	_running = false
	var pf2 = Cine.fig(w, "player")
	if pf2 is Figure3D:
		(pf2 as Figure3D).gait = "walk"
	Cine.look(w, "player", dead)
	_layer.queue_free()
	if is_instance_valid(wren):
		var ex: Dictionary = w.get_meta("extras", {})
		ex.erase("chase_wren")
		wren.visible = false
		w.get_tree().create_timer(40.0).timeout.connect(wren.queue_free)
	queue_free()


func _wren(at: Vector3) -> Node3D:
	var b := Node3D.new()
	b.name = "Extra_chase_wren"
	w.add_child(b)
	b.global_position = at
	var d := Figure3D.make("wren", "wren")
	b.add_child(d)
	var ex: Dictionary = w.get_meta("extras", {}) if w.has_meta("extras") else {}
	ex["chase_wren"] = {"body": b, "doll": d}
	w.set_meta("extras", ex)
	return b


## Wren runs the route, hopping what's in the way, and waits for nobody.
func _run_wren(route: Array) -> void:
	for p in route:
		if not is_inside_tree():
			return
		await Cine.walk(w, "chase_wren", p, WREN_RUN, "run")
		for o in SolSet.CHASE:
			if (o.at as Vector3).distance_to(p) < 0.1:
				var f = Cine.fig(w, "chase_wren")
				if f is Figure3D:
					(f as Figure3D).act("jump", 1.4)
				else:
					Cine.hop(w, "chase_wren", 0.5)
	Cine.look(w, "chase_wren", w.player.global_position)


## Runs to `to`, stopping early if the tap has come (it carries on over).
func _run_until_tap(to: Vector3) -> void:
	var b: Node3D = w.player
	var f = Cine.fig(w, "player")
	var from := b.global_position
	var d := to - from
	d.y = 0.0
	var dist := d.length()
	if dist < 0.05:
		return
	if f is Figure3D:
		(f as Figure3D).gait = "run"
		(f as Figure3D).pace = RUN
	f.walking = true
	f.face(d, w.cam)
	var t := 0.0
	var secs := dist / RUN
	while t < secs and is_inside_tree():
		await get_tree().process_frame
		t += get_process_delta_time()
		b.global_position = from.lerp(to, minf(1.0, t / secs))
		if _tapped and t / secs > 0.6:
			break
	b.global_position = from.lerp(to, minf(1.0, t / secs)) if t < secs else to


## Over it: a jump, the body carried up and across in an arc.
func _vault(a: Vector3, b: Vector3) -> void:
	var f = Cine.fig(w, "player")
	if f is Figure3D:
		(f as Figure3D).act("jump", 1.5)
	var body: Node3D = w.player
	var from := body.global_position
	var secs := 0.75
	var t := 0.0
	while t < secs and is_inside_tree():
		await get_tree().process_frame
		t += get_process_delta_time()
		var u := minf(1.0, t / secs)
		var p := from.lerp(b, u)
		p.y = sin(u * PI) * 1.35
		body.global_position = p
	body.global_position = b


## Under it: down low and through.
func _slide(a: Vector3, b: Vector3) -> void:
	var f = Cine.fig(w, "player")
	if f is Figure3D:
		(f as Figure3D).pose("sit", 0.22, 0.12)
	var body: Node3D = w.player
	var from := body.global_position
	var secs := 0.6
	var t := 0.0
	while t < secs and is_inside_tree():
		await get_tree().process_frame
		t += get_process_delta_time()
		body.global_position = from.lerp(b, minf(1.0, t / secs))
	body.global_position = b
	if f is Figure3D:
		(f as Figure3D).release(0.15)


func _light(i: int, glow: MeshInstance3D, on: bool) -> void:
	glow.visible = on
	_lit = i if on else -1
	_tapped = false
	_ring.visible = on
	_ring.set_meta("glow", glow)


func _input(e: InputEvent) -> void:
	if _lit < 0 or _tapped:
		return
	var pos := Vector2(-1, -1)
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		pos = e.position
	elif e is InputEventScreenTouch and e.pressed:
		pos = e.position
	elif e.is_action_pressed("interact"):
		_tapped = true
		get_viewport().set_input_as_handled()
		return
	if pos.x < 0.0:
		return
	var glow: MeshInstance3D = _ring.get_meta("glow")
	var at := w.cam.unproject_position(glow.global_position)
	var reach := get_viewport().get_visible_rect().size.x * TAP_REACH
	if pos.distance_to(at) <= reach:
		_tapped = true
		get_viewport().set_input_as_handled()


## For the tests: tap the lit ledge.
func tap() -> void:
	if _lit >= 0:
		_tapped = true


func _process(delta: float) -> void:
	if not _running or w == null:
		return
	# the camera runs behind and a little above, turning with the way ahead
	var p := w.player.global_position
	var to: Vector3
	var wb := Cine.body(w, "chase_wren")
	if wb != null:
		to = wb.global_position - p
		to.y = 0.0
		if to.length() > 0.5:
			_cam_dir = _cam_dir.lerp(to.normalized(), minf(1.0, delta * 2.0)).normalized()
	var want := p - _cam_dir * 5.2 + Vector3(0, 2.6, 0) + _cam_dir.cross(Vector3.UP) * 1.2
	w.cine = true
	w.cam.fov = lerpf(w.cam.fov, 52.0, minf(1.0, delta * 3.0))
	w.cam.global_position = w.cam.global_position.lerp(want, minf(1.0, delta * 4.0))
	w.cam.look_at(p + _cam_dir * 4.0 + Vector3(0, 1.2, 0), Vector3.UP)
	if _ring.visible:
		var glow: MeshInstance3D = _ring.get_meta("glow")
		var at := w.cam.unproject_position(glow.global_position)
		_ring.position = at - _ring.size * 0.5
		_ring.queue_redraw()


func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 15
	add_child(_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UITheme.make()
	_layer.add_child(root)
	var m := SafeArea.insets()
	_prompt = UITheme.label(OBJECTIVE, 32, UITheme.GOLD, "display_bold", 8)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_prompt.offset_top = m.y + 120.0
	_prompt.offset_bottom = m.y + 170.0
	root.add_child(_prompt)
	_bark_who = UITheme.label("WREN", 26, UITheme.GOLD, "display_bold", 8)
	_bark_who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bark_who.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_bark_who.offset_left = -600
	_bark_who.offset_right = 600
	_bark_who.offset_top = -m.w - 250.0
	_bark_who.offset_bottom = -m.w - 214.0
	_bark_who.modulate.a = 0.0
	root.add_child(_bark_who)
	_bark = UITheme.label("", 38, UITheme.TEXT, "body", 10)
	_bark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bark.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_bark.offset_left = -700
	_bark.offset_right = 700
	_bark.offset_top = -m.w - 212.0
	_bark.offset_bottom = -m.w - 160.0
	_bark.modulate.a = 0.0
	root.add_child(_bark)
	_ring = Ring.new()
	_ring.size = Vector2(180, 180)
	_ring.visible = false
	root.add_child(_ring)


## Wren, over her shoulder: on screen a moment, then gone.
func _bark_line(text: String) -> void:
	_bark.text = text
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_bark, "modulate:a", 1.0, 0.2)
	tw.tween_property(_bark_who, "modulate:a", 1.0, 0.2)
	tw.chain().tween_interval(1.6)
	tw.chain().set_parallel(true)
	tw.tween_property(_bark, "modulate:a", 0.0, 0.4)
	tw.tween_property(_bark_who, "modulate:a", 0.0, 0.4)


## The pulsing ring round the lit ledge, with "TAP".
class Ring:
	extends Control
	var _t := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_t += delta

	func _draw() -> void:
		var c := size * 0.5
		var k := 0.85 + 0.15 * sin(_t * 7.0)
		draw_arc(c, 62.0 * k, 0.0, TAU, 48, Color(1.0, 0.85, 0.4, 0.9), 6.0, true)
		draw_arc(c, 74.0 * k, 0.0, TAU, 48, Color(1.0, 0.85, 0.4, 0.35), 3.0, true)
		var f := CardFace.font("display_bold")
		draw_string_outline(f, c + Vector2(-60, 12), "TAP", HORIZONTAL_ALIGNMENT_CENTER, 120, 34, 8, Color(0, 0, 0, 0.8))
		draw_string(f, c + Vector2(-60, 12), "TAP", HORIZONTAL_ALIGNMENT_CENTER, 120, 34, Color(1.0, 0.9, 0.55))
