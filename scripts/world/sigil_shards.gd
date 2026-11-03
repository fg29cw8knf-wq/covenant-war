class_name SigilShards
extends Node3D
## Sigilfall shards (Gary, 3 November: shards to collect as well as cards won
## in duels): small glowing crystals left lying about the walkable world where
## the leaking magic has settled. Walking over one picks it up (Game.collect_sigilfall:
## "+3 Shards"), and it comes back the next day by the device's calendar, up
## to DuelRewards.SIGILFALL_DAILY_CAP a day across them all. Never in the
## Prologue (Ads.in_prologue(): it teaches the game), never before the Codex
## is open (where Shards are spent), and hidden while a film has the camera.
##
## World._build() calls place(world) once the area is built.

## Each area's spots: [key, where (on the ground), Shards]. Clear ground the
## player walks anyway: Solhaven's square, its corners and lanes.
const SPOTS := {
	"solhaven": [
		["ysa_corner", Vector3(-7.6, 0.0, 8.6), 2],
		["fountain_steps", Vector3(4.0, 0.0, -7.2), 2],
		["east_lane", Vector3(11.2, 0.0, -9.4), 3],
		["inn_yard", Vector3(9.6, 0.0, 3.0), 2],
		["temple_steps", Vector3(2.0, 0.0, -14.6), 3],
		["circle_edge", Vector3(-12.0, 0.0, -7.6), 2],
	],
}
## How near (m, on the ground) the player has to come to pick one up.
const PICK_RANGE := 1.0
## The crystal's pale Sigil light (the colour cards fall as).
const TINT := Color(0.78, 0.9, 1.0)
const GEM := Color(0.55, 0.75, 1.0)

var world: World
var _items: Array = []   # {key, amount, node}
var _check_t := 0.0
var _sfx: Sfx


## Puts the area's Sigilfall shards into the world (nothing if it has none).
static func place(w: World) -> SigilShards:
	if w.attract or not SPOTS.has(w.area_id):
		return null
	var s := SigilShards.new()
	s.name = "SigilShards"
	s.world = w
	w.add_child(s)
	return s


## Are Sigilfall shards in the game yet (after the Prologue, with the Codex)?
static func active() -> bool:
	return Game.unlocked("codex") and not Ads.in_prologue()


func _ready() -> void:
	_sfx = Sfx.new()
	add_child(_sfx)
	for spot in SPOTS[world.area_id]:
		var node := _crystal()
		node.position = spot[1] + Vector3(0, 0.55, 0)
		add_child(node)
		_items.append({"key": "%s:%s" % [world.area_id, spot[0]], "amount": int(spot[2]), "node": node, "taken": false})
	_refresh()


func _refresh() -> void:
	var on := active()
	for it in _items:
		var n: Node3D = it.node
		n.visible = on and not it.taken and Game.sigilfall_here(String(it.key)) and not world.cine


func _process(delta: float) -> void:
	_check_t -= delta
	if _check_t <= 0.0:
		_check_t = 1.0
		_refresh()
	var t := Time.get_ticks_msec() / 1000.0
	for it in _items:
		var n: Node3D = it.node
		if not n.visible or it.taken:
			continue
		n.rotation.y = t * 0.9
		n.position.y = 0.55 + sin(t * 2.0 + n.position.x) * 0.07
		if world.busy or world.cine or world.player == null:
			continue
		var d := world.player.global_position - n.global_position
		d.y = 0.0
		if d.length() <= PICK_RANGE:
			_take(it)


func _take(it: Dictionary) -> void:
	var got := Game.collect_sigilfall(String(it.key), int(it.amount))
	it.taken = true
	if got <= 0:
		(it.node as Node3D).visible = false
		return
	_sfx.play("gift")
	var n: Node3D = it.node
	var tw := n.create_tween()
	tw.tween_property(n, "position:y", n.position.y + 0.9, 0.45).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(n, "scale", Vector3.ONE * 0.05, 0.45).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		n.visible = false
		n.scale = Vector3.ONE)
	Game.save_game()


## A little cluster of Sigil crystals, glowing (DuelCrystal's cut glass).
static func _crystal() -> Node3D:
	var root := Node3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = 4
	mm.mesh = DuelCrystal.diamond()
	var shapes := [
		[Vector3(0, 0.0, 0), 0.34, Vector3(0, 0, 0)],
		[Vector3(0.11, -0.08, 0.05), 0.2, Vector3(0.3, 0.6, 0.25)],
		[Vector3(-0.1, -0.1, -0.04), 0.17, Vector3(-0.35, 1.9, -0.2)],
		[Vector3(0.02, -0.1, -0.12), 0.14, Vector3(0.2, 3.4, 0.4)],
	]
	for i in shapes.size():
		var sh: Array = shapes[i]
		var b := Basis.from_euler(sh[2]).scaled(Vector3(0.7, 1.6, 0.7) * float(sh[1]))
		mm.set_instance_transform(i, Transform3D(b, sh[0]))
		mm.set_instance_color(i, GEM if i % 2 == 1 else TINT)
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := ShaderMaterial.new()
	mat.shader = DuelCrystal.shard_shader()
	mat.set_shader_parameter("glow", 2.2)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	return root
