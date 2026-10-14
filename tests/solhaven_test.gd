extends Node
## Plays Chapter 1 in Solhaven automatically (Spoken Script C1 to C7): the gate
## duel on arrival, then everyone in story order, with duels simulated and the
## first answer taken at every choice. Checks the story flags at the end and
## saves screenshots.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
##       res://tests/solhaven_test.tscn -- <out_dir>

var out_dir := "user://"
var world: World
var _shots := 0
var _wait := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	Game.new_game("Rowan", "emberstorm")
	world = World.new().setup("solhaven", "gate")
	add_child(world)
	await _frames(20)
	await _shot("arrival")
	# the arrival (with Hale's gate duel) plays by itself
	var t := 0
	while not world.hud.pad.visible and t < 6000:
		await _frames(1)
		t += 1
	await _shot("after_arrival")
	var order := ["bram", "wren", "wren", "pip", "maren", "tamsin", "liora", "aldric", "hierarch",
		"liora", "liora", "aldric", "hale", "bram", "pip", "maren", "wren", "tamsin", "aldric", "hale"]
	for id in order:
		var n = world._npc_by_id(id)
		_teleport(n.body.global_position + Vector3(0.0, 0, 1.6))
		await _frames(4)
		await world._talk(n)
		await _frames(4)
		await _shot("talked_" + id)
		# a lost duel just means trying again
		var tries := 0
		while id in ["wren", "liora", "aldric"] and world._wants_duel(n.def) and tries < 8:
			await world._talk(n)
			tries += 1
	var want := ["beat_hale", "met_hale", "beat_wren", "sun_court_done", "temple_leave", "beat_aldric", "bram_after_trial"]
	var missing := []
	for f in want:
		if not Game.flag(f):
			missing.append(f)
	var lion := int(Game.collection.get("sunmane_lion", 0))
	print("SOLHAVEN TEST: favour=%s objective='%s' lion=%d missing=%s" % [Game.flag("solmaris_favour", ""), Game.flag("objective", ""), lion, missing])
	print("SOLHAVEN TEST: %s" % ("PASS" if missing.is_empty() and lion == 1 else "FAIL"))
	get_tree().quit(0 if missing.is_empty() else 1)


func _process(_d: float) -> void:
	if world == null or world.hud == null:
		return
	if world.hud.dialogue._waiting:
		_wait += 1
		if _wait > 3:
			_wait = 0
			world.hud.dialogue._advance.emit()
	if world.hud.dialogue._choices.visible:
		world.hud.dialogue._chosen.emit(0)
	for c in world.hud.get_children(true):
		_close_reveals(c)


func _close_reveals(n: Node) -> void:
	if n.has_signal("closed") and n.get("card_id") != null and n.is_visible_in_tree():
		n.emit_signal("closed")
	for c in n.get_children():
		_close_reveals(c)


func _teleport(p: Vector3) -> void:
	world.player.global_position = p
	world._focus = world._cam_focus_target()


func _shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	_shots += 1
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("%02d_%s.png" % [_shots, label]))


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
