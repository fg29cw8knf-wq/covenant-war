class_name ThornwoodShelter
extends RefCounted
## Prologue P5's night, as Master Script v7 has it (docs/script/v7_prologue.md):
## hours after the escape, deep in the Thornwood, Bram pulls the roots aside
## from a low stone door in a bracken-covered rise. Inside, his old shelter:
## provisions, a pot he warms without a spark, the player's questions and how
## they take his answers, four card boxes out of his coat and one chosen (its
## class: Mercenary, Scrivener, Ferryman or Unsworn), the Deck and the Codex
## walked round, Bram's lesson duel by no fire at all, and the night. The
## morning after, out of the door and on through the trees.
##
## The room is built below the Thornwood (ROOM_AT), as the inn's rooms are
## below Ashford. thornwood.gd's deck picker, lesson duel and tour are used
## with the table standing in for v3's log.

const ROOM_AT := Vector3(0.0, -40.0, 0.0)
## The low stone door in the rise, a few steps off the old fire ring in the
## clearing (ThornwoodSet.SPOTS.camp), and where they stop in front of it.
const DOOR := Vector3(36.4, 0, 30.6)
const DOOR_STAND := Vector3(37.2, 0, 32.2)
## What Bram says of each box as it's looked at (v7: the four classes).
const CLASS_LINES := {
	"emberstorm": "Mercenary. Goes first and goes hardest, and it doesn't much care who's paying. I won a duke's bet with it once. I was sorry by morning.",
	"ironstone": "Scrivener. Takes every blow, writes it down, and hands it back with interest. The one I'd pick, if I'm honest about myself.",
	"tidegrove": "Ferryman. Patient. Carries you through anything, mending as it goes, and drowns whatever won't get out of the way.",
	"veilwild": "Unsworn. Tricks and dreams and nothing anyone can pin down. It's won duels it had no business winning.",
}
const CLASS_NAMES := {"emberstorm": "Mercenary", "ironstone": "Scrivener", "tidegrove": "Ferryman", "veilwild": "Unsworn"}


static func village(w: World) -> ThornwoodSet:
	return w.get_meta("village") as ThornwoodSet


static func _area(w: World):
	return w.area


# ================================================================ the room ===

## The shelter: a cramped stone room, shelves of sealed water, bread in waxed
## cloth, dried meat and a battered cooking pot; old Ward marks cut into the
## walls; a small table, two stools, a folded blanket. No fire, no lantern,
## no window.
static func room(v: ThornwoodSet) -> Dictionary:
	if v.has_meta("shelter"):
		return v.get_meta("shelter")
	var root := Node3D.new()
	root.name = "Shelter"
	root.position = ROOM_AT
	v.add_child(root)
	var W := 4.2
	var D := 3.4
	var H := 2.2
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.36, 0.34, 0.31)
	stone.roughness = 1.0
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.2, 0.19, 0.17)
	dark.roughness = 1.0
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.36, 0.25, 0.15)
	wood.roughness = 0.9
	v.box(root, Vector3(W, 0.2, D), Vector3(0, -0.1, 0), dark)
	v.box(root, Vector3(W, 0.2, D), Vector3(0, H + 0.1, 0), stone)
	for side in [[Vector3(W, H, 0.3), Vector3(0, H * 0.5, -D * 0.5 - 0.15)], [Vector3(0.3, H, D), Vector3(-W * 0.5 - 0.15, H * 0.5, 0)],
			[Vector3(0.3, H, D), Vector3(W * 0.5 + 0.15, H * 0.5, 0)]]:
		v.box(root, side[0], side[1], stone)
	# the south wall, with the low door in it
	v.box(root, Vector3(W * 0.5 - 0.5, H, 0.3), Vector3(-W * 0.25 - 0.25, H * 0.5, D * 0.5 + 0.15), stone)
	v.box(root, Vector3(W * 0.5 - 0.5, H, 0.3), Vector3(W * 0.25 + 0.25, H * 0.5, D * 0.5 + 0.15), stone)
	v.box(root, Vector3(1.0, 0.6, 0.3), Vector3(0, H - 0.3, D * 0.5 + 0.15), stone)
	var door := Node3D.new()
	door.name = "Door"
	root.add_child(door)
	door.position = Vector3(-0.5, 0, D * 0.5 + 0.12)
	v.box(door, Vector3(1.0, 1.6, 0.08), Vector3(0.5, 0.8, 0), wood)
	# shelves on the west wall: water, bread, meat, the pot
	for y in [0.8, 1.35]:
		v.box(root, Vector3(0.35, 0.05, 2.0), Vector3(-W * 0.5 + 0.2, y, -0.3), wood)
	var clay := StandardMaterial3D.new()
	clay.albedo_color = Color(0.5, 0.36, 0.24)
	for k in 4:
		v.cyl(root, 0.07, 0.07, 0.24, Vector3(-W * 0.5 + 0.2, 1.5, -1.0 + k * 0.32), clay, 10)
	var waxed := StandardMaterial3D.new()
	waxed.albedo_color = Color(0.72, 0.66, 0.5)
	for k in 3:
		v.box(root, Vector3(0.22, 0.12, 0.26), Vector3(-W * 0.5 + 0.2, 0.89, -0.9 + k * 0.4), waxed)
	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color(0.18, 0.18, 0.19)
	iron.metallic = 0.6
	iron.roughness = 0.6
	var pot := Node3D.new()
	pot.name = "Pot"
	root.add_child(pot)
	pot.position = Vector3(-W * 0.5 + 0.2, 0.83, 0.55)
	v.cyl(pot, 0.13, 0.11, 0.16, Vector3(0, 0.08, 0), iron, 14)
	# the flat stone on the floor by the table, where the pot goes to warm
	var flat := Vector3(-0.9, 0.0, -0.9)
	v.box(root, Vector3(0.5, 0.12, 0.4), flat + Vector3(0, 0.06, 0), stone)
	# the table, two stools, a folded blanket
	var tc := Vector3(0.35, 0, -0.2)
	v.box(root, Vector3(1.3, 0.06, 0.75), tc + Vector3(0, 0.72, 0), wood)
	for x in [-0.55, 0.55]:
		for z in [-0.3, 0.3]:
			v.box(root, Vector3(0.06, 0.7, 0.06), tc + Vector3(x, 0.35, z), wood)
	for s in [-1.0, 1.0]:
		v.cyl(root, 0.17, 0.15, 0.44, tc + Vector3(0, 0.22, s * 0.75), wood, 12)
	var wool := StandardMaterial3D.new()
	wool.albedo_color = Color(0.42, 0.34, 0.26)
	v.box(root, Vector3(0.7, 0.12, 0.5), Vector3(W * 0.5 - 0.5, 0.06, -1.1), wool)
	# the old Ward marks on the walls, faint
	var marks: Array = []
	var mm := StandardMaterial3D.new()
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mm.albedo_color = Color(0.55, 0.62, 0.9, 0.12)
	mm.albedo_texture = SealMark.texture()
	for i in 10:
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.14, 0.14)
		mi.mesh = q
		mi.material_override = mm.duplicate()
		var on_east := i % 2 == 0
		if on_east:
			mi.position = Vector3(W * 0.5 - 0.01, 0.6 + 0.25 * (i % 4), -1.2 + 0.5 * (i / 2))
			mi.rotation = Vector3(0, -PI * 0.5, 0)
		else:
			mi.position = Vector3(-1.4 + 0.6 * (i / 2), 0.7 + 0.3 * (i % 3), -D * 0.5 + 0.01)
		root.add_child(mi)
		marks.append(mi)
	# no fire, no lantern: what light there is is cold and low (the marks')
	var fill := OmniLight3D.new()
	fill.light_color = Color(0.55, 0.6, 0.85)
	fill.light_energy = 1.1
	fill.omni_range = 7.0
	fill.position = Vector3(0.2, 1.9, 0.0)
	root.add_child(fill)
	var fill2 := OmniLight3D.new()
	fill2.light_color = Color(0.7, 0.7, 0.8)
	fill2.light_energy = 0.5
	fill2.omni_range = 5.0
	fill2.position = Vector3(1.4, 1.2, 1.2)
	root.add_child(fill2)
	var warm := OmniLight3D.new()
	warm.light_color = Color(1.0, 0.6, 0.32)
	warm.light_energy = 0.0
	warm.omni_range = 2.2
	warm.position = flat + Vector3(0, 0.45, 0)
	root.add_child(warm)
	var top := ROOM_AT.y + 0.75
	var out := {
		"root": root, "floor_y": ROOM_AT.y, "pot": pot, "flat": root.to_global(flat + Vector3(0, 0.12, 0)), "warm": warm, "marks": marks,
		"door": door, "door_in": root.to_global(Vector3(0, 0, D * 0.5 - 0.5)),
		"shelf": root.to_global(Vector3(-W * 0.5 + 0.55, 0, -0.3)),
		"bram_seat": root.to_global(tc + Vector3(0, 0, -0.75)), "player_seat": root.to_global(tc + Vector3(0, 0, 0.75)),
		"table": {"mid": root.to_global(tc + Vector3(0, 0.75, 0)), "along": Vector3.RIGHT, "top": top},
		"bed": root.to_global(Vector3(W * 0.5 - 0.5, 0, -1.1)), "watch": root.to_global(Vector3(-0.2, 0, D * 0.5 - 0.6)),
		"walk": Rect2(-W * 0.5 + 0.45, -D * 0.5 + 0.35, W - 0.9, D - 0.7),
		"blocks": [[Vector2(tc.x, tc.z), 0.85], [Vector2(flat.x, flat.z), 0.35]],
	}
	v.set_meta("shelter", out)
	return out


## The rise, the roots hanging over the low stone door (outside, in the trees).
static func _door_outside(v: ThornwoodSet) -> Node3D:
	if v.has_meta("shelter_door"):
		return v.get_meta("shelter_door")
	var n := Node3D.new()
	n.name = "ShelterDoor"
	v.add_child(n)
	var at := DOOR
	at.y = v.height(at.x, at.z)
	n.global_position = at
	n.rotation.y = 0.7
	var bracken := StandardMaterial3D.new()
	bracken.albedo_color = Color(0.2, 0.26, 0.12)
	bracken.roughness = 1.0
	var mound := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 2.4
	sm.height = 2.6
	mound.mesh = sm
	mound.material_override = bracken
	mound.position = Vector3(0, 0.2, -1.6)
	n.add_child(mound)
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.36, 0.34, 0.31)
	v.box(n, Vector3(1.3, 1.5, 0.3), Vector3(0, 0.75, 0.4), stone)
	var doorm := StandardMaterial3D.new()
	doorm.albedo_color = Color(0.1, 0.08, 0.06)
	v.box(n, Vector3(0.9, 1.25, 0.05), Vector3(0, 0.62, 0.57), doorm)
	var roots := StandardMaterial3D.new()
	roots.albedo_color = Color(0.18, 0.13, 0.08)
	var hang := Node3D.new()
	hang.name = "Roots"
	n.add_child(hang)
	for i in 9:
		v.box(hang, Vector3(0.04, 1.1, 0.04), Vector3(-0.45 + i * 0.11, 1.05, 0.64), roots, Vector3(0.1 * sin(i * 1.7), 0, 0.12 * cos(i)))
	v.set_meta("shelter_door", n)
	return n


# =============================================================== the night ===

static func night(w: World) -> void:
	var v := village(w)
	var A = _area(w)
	A.call("_only", w, ["bram"])
	await Cine.begin(w)
	Cine.overlay(w).black(true)
	# deep in the Thornwood, keeping off the road: no fire in the clearing
	v.set_scene("camp")
	if v.campfire_flames != null:
		v.campfire_flames.emitting = false
	v.campfire_level(0.0)
	var dn := _door_outside(v)
	var stand := DOOR_STAND
	stand.y = v.height(stand.x, stand.z)
	var to_door := (dn.global_position - stand)
	to_door.y = 0.0
	to_door = to_door.normalized()
	var start := stand - to_door * 7.0 + to_door.cross(Vector3.UP) * 1.5
	start.y = v.height(start.x, start.z)
	Cine.place(w, "bram", start, stand)
	Cine.place(w, "player", start - to_door * 1.4, stand)
	Music.play(["thornwood", "menu_theme"], 2.0, true)
	await Cine.caption(w, "The Thornwood", "hours after the escape")
	Cine.shot(w, stand + to_door.cross(Vector3.UP) * 4.0 + Vector3(0, 1.8, 0) - to_door * 2.0, (start + stand) * 0.5 + Vector3(0, 1.2, 0), 42.0)
	Cine.fade(w, 0.0, 1.4)
	Cine.walk(w, "player", stand - to_door * 1.0 - to_door.cross(Vector3.UP) * 0.8, 1.2)
	await Cine.walk(w, "bram", stand, 1.2)
	Cine.look(w, "bram", dn.global_position)
	# he pulls aside the roots hanging over a low stone door
	var bf = Cine.fig(w, "bram")
	if bf is Figure3D:
		(bf as Figure3D).act("lift", 1.0)
	var roots: Node3D = dn.get_node("Roots")
	var rt := w.create_tween()
	rt.tween_property(roots, "rotation:z", 0.9, 0.8).set_trans(Tween.TRANS_SINE)
	Cine.shot(w, stand + to_door.cross(Vector3.UP) * 2.4 + Vector3(0, 1.5, 0), dn.global_position + Vector3(0, 0.8, 0), 38.0)
	await Cine.wait(w, 1.0)
	Cine.look(w, "bram", w.player.global_position)
	Cine.look(w, "player", Cine.body(w, "bram").global_position)
	Cine.over_shoulder(w, "player", "bram", 1.0, 32.0)
	await Cine.say(w, "player", "What is this place? I thought we were going to keep moving.")
	await Cine.say(w, "bram", "An old shelter. Built into the hillside; you'd never find it from the path. I made sure of that.")
	await Cine.say(w, "bram", "We should be safe here for tonight. We won't stay long, just enough time to eat, sleep and get our strength back. Then we're on our way again. There are provisions inside.")
	# "Enter Bram's hidden shelter and inspect the provisions."
	await Cine.overlay(w).bars(false, 0.3)
	var mark := Node3D.new()
	v.add_child(mark)
	mark.global_position = dn.global_position + Vector3(0, 0.8, 0) + to_door * -0.55
	await _use(w, mark, "Enter Bram's hidden shelter and inspect the provisions.")
	mark.queue_free()
	await Cine.fade(w, 1.0, 0.6)
	# ---- inside
	var r := room(v)
	var root: Node3D = r.root
	Cine.place(w, "bram", r.door_in + Vector3(0.4, 0, -0.4), r.table.mid)
	Cine.place(w, "player", r.door_in, r.shelf)
	Cine.shot(w, root.to_global(Vector3(1.6, 1.7, 1.2)), root.to_global(Vector3(-1.0, 0.9, -0.4)), 50.0)
	await Cine.fade(w, 0.0, 0.8)
	await Cine.say(w, "", "[i]Bram shuts the door behind them and tests the latch. There is no fire, no lantern, and no window for an enemy to watch.[/i]")
	# the provisions: walk to the shelves and lay out the food
	var shelf_mark := Node3D.new()
	root.add_child(shelf_mark)
	shelf_mark.global_position = r.shelf + Vector3(-0.25, 0.95, 0)
	await _use(w, shelf_mark, "Inspect the provisions.")
	shelf_mark.queue_free()
	await Cine.path(w, "player", [r.shelf], 1.1)
	Cine.look(w, "player", r.shelf + Vector3(-1.0, 0, 0))
	var pf = w.player_doll
	if pf is Figure3D:
		(pf as Figure3D).act("lift", 1.0)
	await Cine.wait(w, 1.2)
	# Bram rests the pot on the flat stone and passes his fingers over it: a
	# low warmth, no spark; a faint pattern moves across his knuckles and is gone
	var pot: Node3D = r.pot
	await Cine.path(w, "bram", [(r.flat as Vector3) + Vector3(0.55, 0, 0.3)], 1.1)
	Cine.look(w, "bram", r.flat)
	pot.global_position = r.flat
	if bf is Figure3D:
		(bf as Figure3D).pose("lift", 0.42, 0.4)
	Cine.shot(w, (r.flat as Vector3) + Vector3(1.0, 0.7, 0.9), (r.flat as Vector3) + Vector3(0, 0.15, 0), 34.0)
	await Cine.wait(w, 0.8)
	var warm: OmniLight3D = r.warm
	var hand: Vector3 = (bf as Figure3D).bone_pos("RightHand") if bf is Figure3D else (r.flat as Vector3) + Vector3(0, 0.5, 0)
	var glint := v.glow_sprite(v, hand, Color(0.7, 0.78, 1.0), 0.25, 1.6)
	var wt := w.create_tween().set_parallel(true)
	wt.tween_property(warm, "light_energy", 0.8, 1.4)
	wt.tween_property(glint, "scale", Vector3.ONE * 0.01, 0.9).set_delay(0.4)
	await Cine.wait(w, 1.6)
	if is_instance_valid(glint):
		glint.queue_free()
	if bf is Figure3D:
		(bf as Figure3D).release(0.4)
	Cine.look(w, "player", Cine.body(w, "bram").global_position)
	Cine.two_shot(w, "player", "bram", 2.6, 1.3, 1.0, 36.0)
	await Cine.say(w, "player", "You can do that? You never used magic at the inn.")
	await Cine.say(w, "bram", "A little heat, kept where it belongs. No flame, no smoke, no glow for a tracker to follow.")
	await Cine.say(w, "bram", "And at the inn I had good reason not to draw attention. Eat before it goes cold.")
	# the table: opposite sides, and the silence only lasts a moment
	await Cine.fade(w, 1.0, 0.4)
	AshfordP1.sit_down(w, "bram", r.bram_seat, Vector3.BACK, 0.44, 0.0)
	AshfordP1.sit_down(w, "player", r.player_seat, Vector3.FORWARD, 0.44, 0.0)
	pot.global_position = (r.table.mid as Vector3) + Vector3(-0.35, 0.0, 0.0)
	var tm: Vector3 = r.table.mid
	Cine.shot(w, tm + Vector3(1.9, 0.75, 0.4), tm + Vector3(0, 0.2, 0), 40.0)
	await Cine.fade(w, 0.0, 0.5)
	await Cine.wait(w, 0.8)
	Cine.shot(w, tm + Vector3(0.5, 0.65, -1.4), (r.player_seat as Vector3) + Vector3(0, 1.05, 0), 36.0)
	await Cine.say(w, "player", "Bram... what happened to Tam? Did you know Krell was coming? Why did you have a tunnel, and this place, ready?")
	await Cine.say(w, "player", "What are you hiding from me? What am I? And that white card... what has it done to me?")
	# he lowers his food and lets the questions hang in the dark
	Cine.shot(w, tm + Vector3(-0.4, 0.65, 1.4), (r.bram_seat as Vector3) + Vector3(0, 1.05, 0), 36.0)
	await Cine.wait(w, 1.4)
	await Cine.say(w, "bram", "I don't know what happened to Tam after we went below. I won't pretend otherwise.")
	await Cine.say(w, "bram", "And yes, I prepared a way out. I hoped it would never be needed.")
	await Cine.say(w, "bram", "As for the rest... you deserve answers, Sprout. You do. But answers won't stop Krell's hounds when they find our trail.")
	# what the player says (v7: their own feeling, remembered)
	var feel := await Cine.choose(w, ["You could have stopped her.", "I keep seeing him fall.", "Then teach me how to beat her."])
	match feel:
		0:
			Game.set_flag("temper_angry")
			await Cine.say(w, "bram", "Maybe. And then she'd have known exactly what I am, and you'd be in a cage tonight instead of a cellar.")
			await Cine.wait(w, 0.7)
			await Cine.say(w, "bram", "I chose. Hate me for it if you need to. Just eat while you do.")
		1:
			Game.set_flag("temper_afraid")
			await Cine.say(w, "bram", "You will. For a long while.")
			await Cine.wait(w, 0.7)
			await Cine.say(w, "bram", "It gets quieter. It never goes.")
		_:
			Game.set_flag("temper_resolved")
			await Cine.say(w, "bram", "That I can do. That's the one thing I'm sure I can do.")
	Cine.shot(w, tm + Vector3(0.5, 0.65, -1.4), (r.player_seat as Vector3) + Vector3(0, 1.05, 0), 36.0)
	await Cine.say(w, "player", "Then tell me what I need to know. Just that much.")
	Cine.shot(w, tm + Vector3(-0.4, 0.65, 1.4), (r.bram_seat as Vector3) + Vector3(0, 1.05, 0), 36.0)
	await Cine.say(w, "bram", "The Herald named you before the whole valley. That makes you a target, and the white card is the reason Ironvault came.")
	await Cine.say(w, "bram", "It's part of the Last Seal, not an ordinary duelling card. Keep it hidden. Don't try to play it, don't show it to anyone, and don't let anyone take it.")
	await Cine.say(w, "bram", "The rest of what I know has waited twenty years. It can wait one more night.")
	# four worn deck-boxes out of his coat, onto the table
	var ids: Array = DuelCards.DECKS.keys()
	var boxes := await _boxes_on_table(w, r, ids)
	await Cine.say(w, "bram", "I wasn't always an innkeeper. There was a time I travelled this kingdom and survived by my deck. I'm not proud of everything I did.")
	await Cine.say(w, "bram", "The one I lent you for the Lantern Duel was only a start. Now you need a hand you can trust when I'm not there to tell you what to do.")
	await Cine.say(w, "bram", "Choose one. I'll teach you what matters.")
	w.hud.set_objective("Choose your starting class deck: Scrivener, Mercenary, Ferryman or Unsworn.")
	var deck := await _choose(w, boxes, ids, r.table)
	w.hud.set_objective("")
	A.call("_take_deck", deck)
	Game.set_flag("starter_class", String(CLASS_NAMES.get(deck, "")))
	await A.call("_deck_tour", w)
	# he sees the player glance at the white card inside their coat
	Cine.shot(w, tm + Vector3(-0.4, 0.65, 1.4), (r.bram_seat as Vector3) + Vector3(0, 1.05, 0), 36.0)
	await Cine.wait(w, 0.6)
	await Cine.say(w, "bram", "Not that one. These walls carry old Wards, enough to keep a practice hand from signalling beyond the hill.")
	await Cine.say(w, "bram", "My warning on the green still stands: don't reveal your power to anyone hunting us. We practise with ordinary cards tonight.")
	w.hud.set_objective("Begin Bram's sheltered practice duel.")
	await Cine.say(w, "bram", "Corin taught you to swing. Tonight you learn to wait. Draw, and watch your Essence: it comes back with every turn, and what you spend carelessly isn't there when you need to defend yourself.")
	w.hud.set_objective("")
	await lesson(w, r, boxes)
	await after_lesson(w, r)


## Bram reaches into his coat and sets the four worn boxes on the table, one
## after another, along it.
static func _boxes_on_table(w: World, r: Dictionary, ids: Array) -> Array:
	var v := village(w)
	var tb: Dictionary = r.table
	var mid: Vector3 = tb.mid
	var along: Vector3 = tb.along
	# the pot's eaten from and put back on its stone by the table, out of
	# the way of the boxes (it stood in front of the first)
	if r.has("pot") and is_instance_valid(r.pot):
		(r.pot as Node3D).global_position = r.flat
	Cine.shot(w, mid + Vector3(0, 0.9, 1.2), mid + Vector3(0, 0.05, 0), 40.0)
	var bf = Cine.fig(w, "bram")
	var boxes: Array = []
	var cols: Dictionary = (w.area as Script).get_script_constant_map().get("BOX_COLS", {})
	for i in ids.size():
		if bf is Figure3D:
			(bf as Figure3D).act("play_card", 1.4)
		await Cine.wait(w, 0.35)
		var m := StandardMaterial3D.new()
		m.albedo_color = cols.get(ids[i], Color(0.4, 0.3, 0.2))
		m.roughness = 0.85
		var b := Node3D.new()
		v.add_child(b)
		v.box(b, Vector3(0.2, 0.09, 0.28), Vector3(0, 0.045, 0), m)
		var to := mid + along * (-0.48 + i * 0.32)
		to.y = float(tb.top)
		b.global_position = to + Vector3(0, 0.0, -0.18)
		b.rotation.y = randf_range(-0.08, 0.08)
		b.set_meta("deck", ids[i])
		boxes.append(b)
		_area(w).call("_sfx", w, "card_lift", 0.9)
	await Cine.wait(w, 0.5)
	return boxes


## The four boxes on the table: tap one to look at it (Bram's word on its
## class), tap it again to choose. (thornwood.gd's picker, the table for the log.)
static func _choose(w: World, boxes: Array, ids: Array, tb: Dictionary) -> String:
	var mid: Vector3 = tb.mid
	var row_cam := mid + Vector3(0, 0.95, 1.15)
	Cine.shot(w, row_cam, mid + Vector3(0, 0.05, -0.1), 42.0)
	var picker := DeckBoxes.new()
	w.add_child(picker)
	picker.setup(w.cam, boxes, ids)
	w.set_meta("deck_boxes", picker)
	var chosen := ""
	while chosen == "":
		picker.listen()
		var res: Dictionary = await picker.tapped
		var i := int(res.index)
		var b: Node3D = boxes[i]
		if bool(res.again):
			chosen = String(ids[i])
			break
		for k in boxes.size():
			var bk: Node3D = boxes[k]
			var lift := w.create_tween()
			lift.tween_property(bk, "position:y", float(tb.top) + (0.06 if k == i else 0.0), 0.25)
		Cine.move(w, b.global_position + Vector3(0, 0.6, 0.7), b.global_position + Vector3(0, 0.05, 0), 0.6, 36.0)
		picker.show_deck(i)
		await Cine.say(w, "bram", String(CLASS_LINES.get(ids[i], "")))
		if String(ids[i]) == "veilwild":
			await Cine.wait(w, 0.6)
			await Cine.say(w, "bram", "And yes. I know what that thing on the green called you. I named this deck forty years before it did.")
		Cine.move(w, row_cam, mid + Vector3(0, 0.05, -0.1), 0.5, 42.0)
	picker.hide_deck()
	picker.chosen = true
	CardFace.warm_art(DuelCards.card_list(chosen))
	await Cine.say(w, "bram", "That one.")
	var bf = Cine.fig(w, "bram")
	if bf is Figure3D:
		(bf as Figure3D).act("talk", 0.6)   # he nods slowly
	await Cine.wait(w, 0.7)
	await Cine.say(w, "bram", "Yes. That suits you.")
	picker.finish()
	w.remove_meta("deck_boxes")
	return chosen


## Bram's night lesson (v7): a real duel against the deck that shows the
## player's its weakness. It can be lost, gives no experience, and the night
## goes on either way. Its moments are taught as they come (spec.lessons); his
## two glimpses of his past are the duel's own lines (Prologue.practice_duel_spec).
static func lesson(w: World, r: Dictionary, boxes: Array) -> void:
	var A = _area(w)
	var mine := String(Game.starter)
	var pick := Prologue.bram_pick(mine)
	# the other boxes back in his coat, and his pick kept out
	await Cine.fade(w, 1.0, 0.3)
	for b in boxes:
		var bn: Node3D = b
		if is_instance_valid(bn) and String(bn.get_meta("deck", "")) != pick:
			bn.queue_free()
	await Cine.fade(w, 0.0, 0.3)
	await Cine.say(w, "bram", String(Prologue.BRAM_PICK_LINES.get(mine, "This one, against yours.")))
	Game.set_flag("practice_on")
	Game.save_game()
	await Cine.fade(w, 1.0, 0.5)
	var won: bool = await w._duel(Prologue.practice_duel_spec(mine))
	Game.set_flag("practice_on", false)
	Game.save_game()
	for b in boxes:
		if is_instance_valid(b):
			(b as Node).queue_free()
	var tm: Vector3 = r.table.mid
	Cine.shot(w, tm + Vector3(-0.4, 0.65, 1.4), (r.bram_seat as Vector3) + Vector3(0, 1.05, 0), 36.0)
	await Cine.fade(w, 0.0, 0.6)
	if won:
		await Cine.say(w, "bram", "Hm.", 1.4)
		await Cine.wait(w, 1.4)   # he studies the cards a while
		await Cine.say(w, "bram", "Not bad.")
	else:
		await Cine.say(w, "bram", "I said I'd teach you. I never said I'd be soft about it.")
	await Cine.say(w, "bram", "Better. Remember what each card is for. Essence keeps you moving. Totems hold the field. Rites change a moment. Wards punish an opening.")
	await Cine.say(w, "bram", "And power means very little if you don't know when to hold it back.")


## He closes the boxes; "And the other things?"; "Not tonight."; the player
## under the blanket, Bram awake by the door, watching the dark between the
## Ward marks.
static func after_lesson(w: World, r: Dictionary) -> void:
	var tm: Vector3 = r.table.mid
	Cine.shot(w, tm + Vector3(0.5, 0.65, -1.4), (r.player_seat as Vector3) + Vector3(0, 1.05, 0), 36.0)
	await Cine.say(w, "player", "And the other things? Who you really are... and where I came from?")
	Cine.shot(w, tm + Vector3(-0.4, 0.65, 1.4), (r.bram_seat as Vector3) + Vector3(0, 1.05, 0), 36.0)
	await Cine.say(w, "bram", "We'll get to your questions. I promise. But not tonight.")
	await Cine.say(w, "bram", "You've eaten, and now you've learned enough to make it through a fight without me. That's enough for one day. Get some sleep. At first light, we move.")
	await Cine.fade(w, 1.0, 1.0)
	var pf = w.player_doll
	var bf = Cine.fig(w, "bram")
	if pf is Figure3D:
		(pf as Figure3D).stand(0.0)
	if bf is Figure3D:
		(bf as Figure3D).stand(0.0)
	Cine.place(w, "player", r.bed, (r.bed as Vector3) + Vector3.LEFT)
	if pf is Figure3D:
		(pf as Figure3D).lie_down(0.01, true)
	Cine.place(w, "bram", r.watch, (r.watch as Vector3) + Vector3.BACK)
	if bf is Figure3D:
		(bf as Figure3D).pose("sit", 0.3, 0.0)
	var root: Node3D = r.root
	Cine.shot(w, root.to_global(Vector3(-1.4, 1.8, -1.2)), (r.watch as Vector3) + Vector3(0.6, 0.6, -0.6), 44.0)
	await Cine.fade(w, 0.0, 1.2)
	for m in r.marks:
		var mat := (m as MeshInstance3D).material_override as StandardMaterial3D
		var tw := w.create_tween()
		tw.tween_property(mat, "albedo_color:a", 0.35, 1.2)
		tw.tween_property(mat, "albedo_color:a", 0.12, 1.8)
	await Cine.wait(w, 3.2)
	await Cine.fade(w, 1.0, 1.6)
	if pf is Figure3D:
		(pf as Figure3D).get_up(0.01)
	if bf is Figure3D:
		(bf as Figure3D).release(0.0)


# ============================================================= the morning ===

## The next morning: no fire lit, the shelter left as they found it; Bram
## unhooks the door. "Stay close. The city is our best chance..."
static func morning(w: World) -> void:
	var v := village(w)
	var r := room(v)
	var A = _area(w)
	A.call("_only", w, ["bram"])
	await Cine.begin(w)
	Cine.overlay(w).black(true)
	Cine.place(w, "bram", r.door_in + Vector3(0.3, 0, -0.2), r.door_in + Vector3(0, 0, 2))
	Cine.place(w, "player", r.door_in + Vector3(-0.4, 0, -0.9), r.door_in)
	Music.play(["thornwood", "menu_theme"], 2.0, true)
	await Cine.caption(w, "Morning")
	var root: Node3D = r.root
	Cine.shot(w, root.to_global(Vector3(-1.2, 1.6, -1.0)), (r.door_in as Vector3) + Vector3(0, 1.0, 0), 44.0)
	Cine.fade(w, 0.0, 1.2)
	await Cine.wait(w, 0.8)
	var door: Node3D = r.door
	var dt := w.create_tween()
	dt.tween_property(door, "rotation:y", -1.6, 0.9).set_trans(Tween.TRANS_SINE)
	await Cine.wait(w, 0.6)
	Cine.look(w, "bram", w.player.global_position)
	Cine.over_shoulder(w, "player", "bram", 1.0, 32.0)
	await Cine.say(w, "bram", "Stay close. The city is our best chance of finding someone who understands the old Covenant, and of getting lost in a crowd before Ironvault catches up.")
	w.hud.set_objective("Leave the shelter and follow Bram through the Thornwood.")
	await Cine.wait(w, 0.8)
	await Cine.fade(w, 1.0, 1.2)
	door.rotation.y = 0.0
	w.hud.set_objective("")


## Waits for the player to tap (or press E at) a thing, the objective naming
## it (thornwood's films have no WorldCoach keys of their own).
static func _use(w: World, target: Node3D, objective: String) -> void:
	# (use() clears the Objective line as it starts: ours goes up just after)
	w.get_tree().create_timer(0.05, false).timeout.connect(func() -> void:
		if is_instance_valid(w) and w.hud != null:
			w.hud.set_objective(objective))
	await AshfordP1.use(w, target, "", 0.0, Vector3.INF, 0.45)
	w.hud.set_objective("")
