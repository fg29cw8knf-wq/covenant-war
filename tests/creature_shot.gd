extends Node
## Screenshots of a duel built so a given Totem ends up on the field, for
## checking a new creature model in the real duel (its clips, its flames):
## the computer plays both sides from stacked decks.
##   xvfb-run -a godot --rendering-driver opengl3 --resolution 1280x720 res://tests/creature_shot.tscn -- <out_dir> <card id> [seconds]
## A Basic Totem is called straight away; an Ascended one is reached by
## calling what it grows from first.

var out_dir := "user://"
var n := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else "user://"
	var id: String = args[1] if args.size() > 1 else "blazehound"
	var secs: float = float(args[2]) if args.size() > 2 else 30.0
	Game.new_game("Sprout", "emberstorm")
	var d: Dictionary = DuelCards.CARDS[id]
	var mine: Array = []
	if d.has("ascends_from"):
		mine = [String(d.ascends_from), id, id]
	else:
		mine = [id, id]
	mine += ["essence_flask", "essence_flask", "healing_draught", "essence_flask", "essence_flask", "healing_draught", "essence_flask", "essence_flask"]
	var spec := {
		"decks": [mine, ["brookfin", "bulwark", "essence_flask", "healing_draught", "essence_flask", "healing_draught", "bulwark", "essence_flask", "healing_draught", "essence_flask"]],
		"names": ["Sprout", "Corin"], "ai": [true, true], "stacked": [true, true], "first": 0,
		"arena": "ashford", "life": 60, "speed": 2.0,
	}
	var layer := CanvasLayer.new()
	add_child(layer)
	var ds := DuelScreen.new().configure(spec)
	layer.add_child(ds)
	var t := 0.0
	while t < secs:
		await get_tree().create_timer(2.0).timeout
		t += 2.0
		var on_field := false
		if ds.game != null:
			for p in ds.game.players:
				for tt in p.totems():
					if tt.id() == id:
						on_field = true
		await _shot("duel" + ("_" + id if on_field else ""))
		if ds.game != null and ds.game.over:
			break
	get_tree().quit()


func _shot(tag: String) -> void:
	await RenderingServer.frame_post_draw
	n += 1
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("%02d_%s.png" % [n, tag]))
