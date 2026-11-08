extends Node
## The crate walk in the taproom, quickly and headless: the game picked up at
## the taproom, Bram's lines run through, then what a player does with the
## crate: a tap at the foot of the stairs (Bram: "Wrong way, Sprout"), and a
## tap on the door, which must get them there with Bram following (23 October:
## Bram's standing body, a step behind at the table, pushed the player back a
## step every frame through move_and_slide, and the door was never reached).
##   godot --headless --fixed-fps 8 res://tests/taproom_walk_test.tscn
## Ends with "TAPROOM WALK: ok" or the problems.

var world: World
var phase := 0
var t := 0.0
var _wait := 0
var e: Dictionary
var problems: Array = []


func _ready() -> void:
	Game.new_game("Sprout", "")
	Game.set_flag("p1_stage", "taproom")
	Game.set_flag("p1_ate")   # (the porridge's eaten: the crate is the one thing to do)
	world = World.new().setup("ashford", "green")
	add_child(world)


## The crate is the player's to take since 2 November (AshfordP1.use on it,
## from a stride away): a tap on the floor by its corner, then on the crate.
var _crate_tapped := 0.0


func _process(d: float) -> void:
	if world == null or world.hud == null:
		return
	if world.hud.dialogue._waiting:
		_wait += 1
		if _wait > 8:
			_wait = 0
			world.hud.dialogue._advance.emit()
	if world.hud.dialogue._choices.visible:
		world.hud.dialogue._chosen.emit(0)
	t += d
	match phase:
		0:
			# (the crate in arms: the objective is green_crate since 2 November)
			if world.has_meta("p1_crate") and world.player.global_position.y < -20.0 and String(Game.flag("objective_key", "")) == "green_crate":
				e = world.get_meta("village").get_meta("eve")
				phase = 1
				t = 0.0
			elif String(Game.flag("objective_key", "")) == "take_crate" and world.get_meta("village", null) != null and (world.get_meta("village") as Node).has_meta("eve"):
				var ev: Dictionary = world.get_meta("village").get_meta("eve")
				var cr: Node3D = ev.crate
				var corner: Vector3 = (ev.root as Node3D).to_global(Vector3(3.55, 0, -2.85))
				var dist := Vector2(world.player.global_position.x - corner.x, world.player.global_position.z - corner.z).length()
				if t - _crate_tapped > 0.6:
					_crate_tapped = t
					if dist < 1.15 and not world.has_meta("p1_crate"):
						world.hud.tapped.emit(world.cam.unproject_position(cr.global_position))
					elif dist >= 1.15:
						world.hud.tapped.emit(world.cam.unproject_position(corner + Vector3(-0.6, 0, 0.4)))
			if t > 120.0:
				_fail("the crate never came (%.0f s)" % t)
		1:
			if t > 1.0:
				world.hud.tapped.emit(world.cam.unproject_position(e.stairs_foot))
				phase = 2
				t = 0.0
		2:
			if world.hud.dialogue.visible and "Wrong way" in world.hud.dialogue._text.text:
				phase = 3
				t = 0.0
			elif t > 30.0:
				_fail("no \"Wrong way\" from Bram at the stairs")
		3:
			if t > 3.4:
				# (as a player would, and as tests/ashford_test.gd does)
				world.hud.tapped.emit(world.cam.unproject_position(e.door_in))
				phase = 4
				t = 0.0
		4:
			# (8 November: the walk ends as they come in front of the door and
			# they're walked back to e.door_stand, out of the leaf's swing;
			# the menu line at the door is the proof they got there)
			var at := _local(world.player.global_position)
			var door := _local(e.door_in)
			var stand := _local(e.get("door_stand", e.door_in))
			if Vector2(at.x - stand.x, at.z - stand.z).length() < 0.3 or (world.hud.dialogue.visible and "stops the game" in world.hud.dialogue._text.text):
				print("the player reached the door in %.1f s (at %s, the stand at %s)" % [t, at.snapped(Vector3(0.01, 0.01, 0.01)), stand.snapped(Vector3(0.01, 0.01, 0.01))])
				_finish()
			elif t > 14.0:
				_fail("the player never reached the door: at %s, the door at %s, the stand at %s (Bram at %s)" % [at, door, stand, _local(Cine.body(world, "bram").global_position)])


func _local(p: Vector3) -> Vector3:
	return (e.root as Node3D).to_local(p)


func _fail(what: String) -> void:
	problems.append(what)
	print("PROBLEM: ", what)
	_finish()


func _finish() -> void:
	print("TAPROOM WALK: %s" % ("ok" if problems.is_empty() else "%d problems" % problems.size()))
	get_tree().quit(1 if problems.size() > 0 else 0)
