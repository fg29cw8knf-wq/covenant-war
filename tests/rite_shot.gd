extends Node
## Stills of the Rites' own pictures on the 3D field (DuelField3D.rite_motif,
## 25 October): Brookfin and Cinderpup across the Circle, then each motif
## played on its Totem and caught part-way: Bulwark's wall, Healing Draught,
## Firebrand, Frostbind's ice, Strangling Roots, Drowning Rain, Toxic Mist,
## Thunderclap, Tidal Surge, Stone Gaze, Forge Edge, Traveller's Pack and
## Essence Flask.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
##       res://tests/rite_shot.tscn -- <out_dir>

var out := "user://"

## [card, on whose Totem (0 mine, 1 the rival's, -1 my plate), seconds in]
const SHOTS := [
	["bulwark", 0, 0.55], ["bulwark", 0, 1.0], ["healing_draught", 0, 0.3], ["forge_edge", 0, 0.35],
	["firebrand", 1, 0.3], ["frostbind", 1, 0.5], ["frostbind", 1, 1.05], ["strangling_roots", 1, 0.4],
	["drowning_rain", 1, 0.5], ["toxic_mist", 1, 0.4], ["thunderclap", 1, 0.1], ["tidal_surge", 1, 0.3],
	["stone_gaze", 1, 0.45], ["mind_fog", 1, 0.5], ["travellers_pack", -1, 0.4], ["essence_flask", -1, 0.7],
	["jagged_shards", 1, 0.1], ["gust_shove", 1, 0.35],
]


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://"
	get_tree().root.theme = UITheme.make()
	var ds := DuelScreen.new().configure({"decks": ["emberstorm", "veilwild"], "names": ["You", "Rival"],
		"ai": [false, false], "seed": 43, "speed": 50.0, "field3d": true})
	add_child(ds)
	var t := 0.0
	while (ds.game == null or ds.game.turn < 1) and t < 30.0:
		await get_tree().create_timer(0.2).timeout
		t += 0.2
		if ds.banner_waiting:
			ds.tap_banner()
	var g := ds.game
	for pl in g.players:
		pl.slots = [null, null, null]
	g.players[0].slots[1] = g._new_totem(DuelCard.new(9200, "brookfin", 0), 0, 1, 1)
	g.players[1].slots[1] = g._new_totem(DuelCard.new(9202, "cinderpup", 1), 1, 1, 1)
	ds._refresh()
	await get_tree().create_timer(2.5).timeout   # (the models load)
	var field = ds.field
	if field == null:
		print("RITE SHOT: no 3D field")
		get_tree().quit(1)
		return
	for sh in SHOTS:
		var id := String(sh[0])
		var who := int(sh[1])
		var secs := float(sh[2])
		var card := DuelCard.new(9300, id, 0)
		var col: Color = DuelFX.light(card.element())
		var at: Vector3
		var ahead: Vector3
		if who < 0:
			at = field.plate_world(0)
			ahead = field.ahead_of(0)
		else:
			at = field.body_world(who, 1)
			ahead = field.ahead_of(who)
		field.rite_motif(card, at, ahead, col)
		await get_tree().create_timer(secs).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/rite_%s_%02d.png" % [out, id, int(secs * 100)])
		print("RITE SHOT: %s at %.2f s" % [id, secs])
		await get_tree().create_timer(2.5).timeout   # (it plays out and is gone)
	print("RITE SHOT: done")
	get_tree().quit()
