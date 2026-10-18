extends RefCounted
## Solhaven — the Sun Square. The first kingdom of the vertical slice.
##
## Layout (metres): the camera looks north (towards -z). The player enters
## through the south gate, the Temple of Solmaris fills the north side, the
## Duelling Circle sits to the west and the market and inn to the east.

const NAME := "Solhaven"
const SUBTITLE := "The Sun Square"

const BOUNDS := Rect2(-15.5, -18.0, 31.0, 32.0)  # x, z, width, depth the player can walk
const CAMERA_X_LIMIT := 7.0

const SPAWNS := {
	"gate": Vector3(0, 0, 12.5),
	"inn": Vector3(10.5, 0, 1.5),
	"circle": Vector3(-8.5, 0, -6.0),
	"temple": Vector3(0, 0, -14.0),
}

const ENV := {
	"sky_top": "3f7fcf",
	"sky_horizon": "f4d9a8",
	"ground_horizon": "d9c49a",
	"sun_color": "ffe2b0",
	"sun_energy": 1.1,
	"sun_angle": Vector3(-38, -32, 0),
	"ambient": 0.4,
	"fog": "f1dcb6",
	"fog_density": 0.004,
}


## NPCs: look (DollArt id), display name, position, and what happens on talk.
## Chapter 1 as a hub: the gate (Hale), the wagon (Bram), the market (Wren,
## Tamsin), the square (Pip, Maren), the temple steps (the Hierarch, the Herald,
## Liora) and the Duelling Circle (Aldric). The Sun Court, the Trial of Light
## and the Sunspire play here until their own scenes are built.
static func npcs() -> Array:
	return [
		{"id": "hale", "look": "guard", "name": "Warden Hale", "pos": Vector3(3.2, 0, 11.0), "duel_flag": "beat_hale", "talk": _hale()},
		{"id": "bram", "look": "bram", "name": "Bram", "pos": Vector3(10.2, 0, -0.2), "talk": _bram()},
		{"id": "wren", "look": "wren", "name": "Wren", "pos": Vector3(8.8, 0, 7.6), "duel_flag": "beat_wren", "talk": _wren()},
		{"id": "pip", "look": "child", "name": "Pip", "pos": Vector3(-2.6, 0, -1.6), "talk": _pip()},
		{"id": "maren", "look": "elder", "name": "Old Maren", "pos": Vector3(-10.4, 0, 4.4), "talk": _maren()},
		{"id": "tamsin", "look": "merchant", "name": "Tamsin", "pos": Vector3(12.6, 0, 5.2), "talk": _tamsin()},
		{"id": "hierarch", "look": "hierarch", "name": "Hierarch Aurel", "pos": Vector3(-3.6, 0, -14.6), "talk": _hierarch()},
		{"id": "herald", "look": "herald", "name": "The Pale Herald", "pos": Vector3(-7.2, 0, -16.0), "talk": _herald()},
		{"id": "liora", "look": "acolyte", "name": "Acolyte Liora", "pos": Vector3(3.2, 0, -14.6), "duel_flag": "temple_leave", "duel_needs": "sun_court_done", "talk": _liora()},
		{"id": "aldric", "look": "aldric", "name": "Ser Aldric Vane", "pos": Vector3(-9.0, 0, -9.6), "duel_flag": "beat_aldric", "duel_needs": "temple_leave", "talk": _aldric()},
	]


# ================================================================ scenery ===

static func build(root: Node3D) -> void:
	var K := LevelKit
	# ground: the square, grass beyond, hills in the distance
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(120, 120)
	ground.mesh = pm
	ground.material_override = K.mat("grass")
	root.add_child(ground)
	var gbody := StaticBody3D.new()
	var gcs := CollisionShape3D.new()
	gcs.shape = WorldBoundaryShape3D.new()
	gbody.add_child(gcs)
	root.add_child(gbody)
	K.box(root, Vector3(0, -0.2, -2), Vector3(38, 0.24, 42), "cobble", false)
	K.box(root, Vector3(0, -0.19, 14), Vector3(8, 0.24, 30), "flagstone", false)  # south road
	K.box(root, Vector3(0, -0.18, -4), Vector3(10, 0.24, 20), "flagstone", false)  # processional way

	_temple(root)
	_fountain(root, Vector3(0, 0, -3.5))
	_duel_circle(root, Vector3(-9.0, 0, -8.2))
	_gate(root)

	# west side: houses and the old quarter
	K.house(root, Vector3(-20, 0, -12), Vector3(7, 7.5, 8), "plaster", "roof_teal", 90)
	K.house(root, Vector3(-20, 0, -2), Vector3(7, 6.0, 8), "sandstone", "roof_terracotta", 90)
	K.house(root, Vector3(-20, 0, 8), Vector3(8, 6.5, 8), "plaster", "roof_teal", 90)
	K.house(root, Vector3(-27, 0, 0), Vector3(8, 9.0, 12), "plaster", "roof_terracotta", 90)
	# east side: the inn (the Gilded Hearth), shops
	K.house(root, Vector3(19.5, 0, -1), Vector3(9, 7.0, 8), "sandstone", "roof_terracotta", -90)
	K.box(root, Vector3(14.9, 2.8, -1), Vector3(0.1, 1.0, 2.6), "dark_wood", false)  # inn sign
	K.house(root, Vector3(19.5, 0, -12), Vector3(7, 8.0, 8), "plaster", "roof_teal", -90)
	K.house(root, Vector3(19.5, 0, 9), Vector3(7, 6.0, 7), "plaster", "roof_teal", -90)
	K.house(root, Vector3(27, 0, -4), Vector3(8, 10.0, 14), "sandstone", "roof_teal", -90)

	# the stable yard: Bram's wagon, the Crooked Lantern's lantern on its hook, and Turnip
	_wagon(root, Vector3(12.6, 0, -4.2))

	# market
	K.stall(root, Vector3(12.8, 0, 3.2), -90, "awning_red")
	K.stall(root, Vector3(12.8, 0, 7.4), -90, "awning_blue")
	K.crate(root, Vector3(14.2, 0, 9.4), 0.8, 12)
	K.crate(root, Vector3(14.6, 0, 10.3), 0.6, -20)
	K.barrel(root, Vector3(13.6, 0, 0.6))
	K.barrel(root, Vector3(14.4, 0, 1.2))

	# greenery, lamps, banners, benches
	for z in [-15.0, -7.0, 1.0, 9.0]:
		K.cypress(root, Vector3(-14.4, 0, z), 5.5)
		K.cypress(root, Vector3(14.9, 0, z - 3.5), 5.0)
	K.tree(root, Vector3(-12.2, 0, 9.5), 1.1)
	K.tree(root, Vector3(-6.5, 0, 12.5), 0.9)
	K.lamp(root, Vector3(-4.6, 0, 3.6), true)
	K.lamp(root, Vector3(4.6, 0, 3.6))
	K.lamp(root, Vector3(-4.6, 0, -10.5))
	K.lamp(root, Vector3(4.6, 0, -10.5), true)
	K.bench(root, Vector3(-10.4, 0, 3.0))
	K.bench(root, Vector3(-3.8, 0, -7.6), 90)
	for x in [-5.8, 5.8]:
		K.banner(root, Vector3(x, 7.6, -18.9), 0)
	K.banner(root, Vector3(-15.4, 5.5, -2), 90, "radiant")
	K.banner(root, Vector3(15.45, 5.2, -12), -90, "radiant")

	# far backdrop: city wall and distant hills beyond the temple
	K.box(root, Vector3(0, 0, -44), Vector3(90, 7, 2), "sandstone", false)
	for i in 9:
		var x := -40.0 + i * 10.0
		K.cylinder(root, Vector3(x, 0, -44), 1.8, 10.5, "sandstone", false, 1.8, 12)
		K.cylinder(root, Vector3(x, 10.5, -44), 2.0, 2.2, "roof_teal", false, 0.0, 12)
	for h in [[-38, -70, 22], [-5, -80, 28], [30, -72, 24], [55, -60, 18], [-60, -58, 20]]:
		var hill := K.sphere(root, Vector3(h[0], -h[2] * 0.55, h[1]), h[2], "hill", 0.6)
		hill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# keep the player in the square
	var b := BOUNDS
	K.wall(root, Vector3(b.position.x, 0, b.position.y), Vector3(b.end.x, 0, b.position.y))
	K.wall(root, Vector3(b.position.x, 0, b.position.y), Vector3(b.position.x, 0, b.end.y))
	K.wall(root, Vector3(b.end.x, 0, b.position.y), Vector3(b.end.x, 0, b.end.y))
	K.wall(root, Vector3(b.position.x, 0, b.end.y), Vector3(b.end.x, 0, b.end.y))
	# Chapter 1's side stories, from their own file (solhaven/solhaven_side.gd); nothing happens without it
	var side = load("res://scripts/world/areas/solhaven/solhaven_side.gd") if ResourceLoader.exists("res://scripts/world/areas/solhaven/solhaven_side.gd") else null
	if side != null:
		side.setup(root)


## A battered wagon with a lantern on a hook, and a grey mule with one ear
## that won't stand up.
static func _wagon(root: Node3D, c: Vector3) -> void:
	var K := LevelKit
	K.box(root, c + Vector3(0, 0.75, 0), Vector3(2.0, 0.2, 3.6), "dark_wood", true)       # bed
	K.box(root, c + Vector3(-0.95, 1.2, 0), Vector3(0.1, 0.7, 3.6), "wood", false)         # sides
	K.box(root, c + Vector3(0.95, 1.2, 0), Vector3(0.1, 0.7, 3.6), "wood", false)
	K.box(root, c + Vector3(0, 1.2, -1.75), Vector3(2.0, 0.7, 0.1), "wood", false)
	K.box(root, c + Vector3(0, 1.2, 1.75), Vector3(2.0, 0.5, 0.1), "wood", false)          # tailboard
	K.box(root, c + Vector3(0, 2.3, -0.4), Vector3(2.3, 0.12, 2.6), "cloth_white", false)  # canvas hoop
	for s in [-1, 1]:
		for z in [-1.1, 1.1]:
			var wh := K.cylinder(root, c + Vector3(s * 1.1, 0, z), 0.55, 0.16, "dark_wood", false, -1.0, 16)
			wh.position = c + Vector3(s * 1.1, 0.55, z)
			wh.rotation.z = PI * 0.5
	K.box(root, c + Vector3(0, 0.5, 2.9), Vector3(0.14, 0.14, 2.4), "wood", false)         # shaft
	K.cylinder(root, c + Vector3(0.9, 1.6, 1.9), 0.03, 0.9, "bronze", false, -1.0, 8)      # lantern hook
	var lamp := K.sphere(root, c + Vector3(0.9, 2.3, 1.9), 0.18, "lamp_glow")
	lamp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var l := OmniLight3D.new()
	l.position = c + Vector3(0.9, 2.3, 1.9)
	l.light_color = Color("ffc67a")
	l.light_energy = 1.0
	l.omni_range = 5.0
	root.add_child(l)
	# Turnip
	var m := c + Vector3(0.4, 0, 4.9)
	K.box(root, m + Vector3(0, 0.95, 0), Vector3(0.7, 0.7, 1.5), "rock", true)             # body
	K.box(root, m + Vector3(0, 1.45, -0.95), Vector3(0.4, 0.5, 0.5), "rock", false)        # neck
	K.box(root, m + Vector3(0, 1.7, -1.35), Vector3(0.36, 0.34, 0.6), "rock", false)       # head
	K.box(root, m + Vector3(-0.14, 2.0, -1.2), Vector3(0.08, 0.34, 0.1), "rock", false)    # the ear that stands
	var ear := K.box(root, m + Vector3(0.16, 1.9, -1.2), Vector3(0.08, 0.34, 0.1), "rock", false)
	ear.rotation.z = -1.1                                                                   # the ear that won't
	for s in [-1, 1]:
		for z in [-0.5, 0.5]:
			K.box(root, m + Vector3(s * 0.22, 0.3, z), Vector3(0.14, 0.6, 0.14), "rock", false)


static func _temple(root: Node3D) -> void:
	var K := LevelKit
	var z0 := -19.0
	# stepped platform
	for i in 4:
		K.box(root, Vector3(0, i * 0.3, z0 - 1.0 - i * 0.7), Vector3(22 - i * 0.8, 0.3, 4.0 + i * 1.4), "marble", i == 0)
	K.box(root, Vector3(0, 1.2, -26), Vector3(20, 0.2, 12), "marble", false)
	# portico columns
	for i in 7:
		var x := -8.1 + i * 2.7
		K.column(root, Vector3(x, 1.2, z0 - 3.0), 7.0, 0.45)
	K.box(root, Vector3(0, 8.2, z0 - 3.4), Vector3(19.6, 0.9, 2.2), "marble", false)
	K.gable(root, Vector3(0, 9.1, z0 - 3.4), 20.4, 2.4, 2.4, "marble")
	K.box(root, Vector3(0, 9.1, z0 - 2.25), Vector3(1.6, 1.6, 0.1), "gold", false)
	# cella and dome
	K.box(root, Vector3(0, 1.2, -27), Vector3(16, 8.5, 10), "marble")
	K.box(root, Vector3(0, 1.2, z0 - 4.95), Vector3(3.2, 5.2, 0.2), "gold", false)  # great door
	K.cylinder(root, Vector3(0, 9.7, -27), 5.2, 2.2, "marble", false, 5.2, 32)
	K.dome(root, Vector3(0, 11.9, -27), 5.0, "gold")
	K.sphere(root, Vector3(0, 17.4, -27), 0.7, "sun_glow")
	# flanking towers
	for x in [-11.0, 11.0]:
		K.cylinder(root, Vector3(x, 1.2, -25), 1.6, 11.0, "marble", true, 1.5, 20)
		K.cylinder(root, Vector3(x, 12.2, -25), 1.8, 3.4, "gold", false, 0.0, 20)


static func _fountain(root: Node3D, c: Vector3) -> void:
	var K := LevelKit
	K.cylinder(root, c, 3.2, 0.25, "marble", true, 3.2, 40)
	var rim := K.torus(root, c + Vector3(0, 0.42, 0), 2.85, 3.3, "marble")
	rim.scale.y = 1.6
	var w := K.cylinder(root, c + Vector3(0, 0.25, 0), 2.95, 0.22, "water", false, 2.95, 40)
	w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	K.cylinder(root, c, 0.45, 2.6, "marble", false, 0.3, 16)
	K.cylinder(root, c + Vector3(0, 2.3, 0), 1.1, 0.25, "marble", false, 1.3, 24)
	var sun := K.sphere(root, c + Vector3(0, 3.2, 0), 0.55, "sun_glow")
	sun.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in 8:
		var a := TAU * i / 8.0
		var ray := K.box(root, c + Vector3(cos(a) * 0.85, 3.08, sin(a) * 0.85), Vector3(0.5, 0.08, 0.12), "gold", false)
		ray.rotation.y = -a
	var l := OmniLight3D.new()
	l.position = c + Vector3(0, 3.3, 0)
	l.light_color = Color("ffd88a")
	l.light_energy = 1.2
	l.omni_range = 7.0
	root.add_child(l)


static func _duel_circle(root: Node3D, c: Vector3) -> void:
	var K := LevelKit
	K.cylinder(root, c, 4.2, 0.18, "marble", false, 4.2, 48)
	var ring := K.torus(root, c + Vector3(0, 0.2, 0), 3.55, 3.75, "ring_glow")
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var inner := K.torus(root, c + Vector3(0, 0.2, 0), 1.3, 1.42, "ring_glow")
	inner.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in 6:
		var a := TAU * i / 6.0 + 0.5
		var p := c + Vector3(cos(a), 0, sin(a)) * 4.8
		K.cylinder(root, p, 0.28, 1.6, "marble", true, 0.22, 12)
		var s := K.sphere(root, p + Vector3(0, 1.8, 0), 0.22, "lamp_glow")
		s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func _gate(root: Node3D) -> void:
	# The south gate stands behind the camera's view line, so it frames the
	# bottom of the screen without hiding the player.
	var K := LevelKit
	var z := 21.0
	for x in [-6.0, 6.0]:
		K.box(root, Vector3(x, 0, z), Vector3(3.0, 5.0, 3.0), "sandstone")
		K.gable(root, Vector3(x, 5.0, z), 3.6, 3.6, 1.4, "roof_teal")
		K.banner(root, Vector3(x, 4.4, z - 1.56), 0, "radiant")
	for sx in [-1, 1]:
		K.box(root, Vector3(sx * 13.5, 0, z), Vector3(12, 2.2, 1.0), "sandstone")


# =============================================================== dialogue ===
# Steps: {"say", "who"} · {"if": flag, "then", "else"} · {"choice": [...], "then": [[...], ...]}
# {"duel": {...}, "win": [...], "lose": [...]} · {"set": flag} · {"give": card} · {"save": true}
# {"objective": text} · {"scene": name}. "{name}" is replaced with the player's name.
# A flag starting with "!" means "not".

## C1 · The Golden Gate, then C2 · the stable yard. Plays the first time the
## player enters: Hale bars the gate until the Unsworn is tested.
static func arrival() -> Array:
	return [
		{"say": "[center][i]Three days after the fire, you reach Solhaven with the smoke still in your clothes. So does everyone else on the road.[/i][/center]"},
		{"say": "Three days we've waited. They let the pilgrims in. Not us.", "who": "refugee"},
		{"say": "Gate's closed. By order of the Hierarch, only sun-marked pilgrims enter Solhaven during the Turning.", "who": "hale"},
		{"say": "We're not pilgrims. Show him, Sprout.", "who": "bram"},
		{"say": "[i]You raise your hand. The white mark glows.[/i]"},
		{"say": "...White. I had a crown on it being a forgery. They sell those by the dozen in the Shardlands.", "who": "hale"},
		{"say": "You'd bar the Unsworn from the Sun Court? The Herald sent for them.", "who": "bram"},
		{"say": "The Herald sends for a lot of people. I'd test one.", "who": "hale"},
		{"set": "met_hale"},
		{"choice": ["Then test me.", "I don't have time for this."], "then": [
			[{"say": "Gladly.", "who": "hale"}],
			[{"say": "Then you'd best duel quickly.", "who": "hale"}],
		]},
		{"goto_duel": "hale_duel"},
		# the stable yard
		{"say": "[i]The stable yard. Bram counts his last coins into a horse-trader's palm. In return: a battered wagon with a lantern on a hook, and a grey mule with one ear that won't stand up.[/i]"},
		{"say": "Mule's called Turnip. Bites. Not hard.", "who": "trader"},
		{"say": "The Crooked Lantern rides again.", "who": "bram"},
		{"say": "This is home now, Sprout. Sleep here, sort your deck here. Turnip says you're welcome.", "who": "bram"},
		{"say": "[i]Turnip bites your sleeve. Not hard.[/i]"},
		{"objective": "Present your mark at the Sun Court: the Hierarch, on the temple steps."},
	]


static func _hale() -> Array:
	return [
		{"if": "beat_aldric", "then": [
			{"say": "I watched from the wall. The whole Watch did. Half of them owe me money now.", "who": "hale"},
			{"if": "let_refugees_in", "then": [
				{"say": "The ones you let in have told the whole lower town what you did. I've had three offers of marriage on your behalf. I said you'd think about it.", "who": "hale"},
			], "else": [
				{"say": "{name}. The people outside the walls. If you ever have the ear of someone who matters, remember them. I can't.", "who": "hale"},
			]},
		], "else": [
			{"if": "beat_hale", "then": [
				{"say": "Keep your cards close in the market, {name}. Not everyone in Solhaven is as holy as the paintwork.", "who": "hale"},
			], "else": [
				{"say": "The gate's still shut to the untested, {name}. The offer stands.", "who": "hale"},
				{"choice": ["Then test me.", "Not now"], "then": [[{"goto_duel": "hale_duel"}], []]},
			]},
		]},
	]


## The Gate Duel (v1 rules). Tips introduce Guardians and Divine Gifts.
static func hale_duel() -> Array:
	return [
		{"duel": {"deck": "solhaven_guard", "name": "Warden Hale", "look": "guard", "patron": "solmaris", "attrs": {"resolve": 1}},
			"win": [
				{"set": "beat_hale"},
				{"say": "That mark's real. Heaven help the rest of us. The gate's open to you.", "who": "hale"},
				{"choice": ["Let these people in too.", "Thank you, Warden."], "then": [
					[
						{"say": "The Hierarch's orders are...", "who": "hale"},
						{"say": "[i]You hold his eye. He let a stranger in for a mark on their hand. These people's homes burned.[/i]"},
						{"say": "...Open it wide. All of them. If anyone asks, you threatened me.", "who": "hale"},
						{"say": "[i]The refugees pour through. A woman grips your hand as she passes.[/i]"},
						{"say": "We won't forget this.", "who": "refugee"},
						{"set": "let_refugees_in"},
					],
					[
						{"say": "Don't thank me. Thank whatever chose you. I'm sorry for them. I have my orders.", "who": "hale"},
					],
				]},
			],
			"lose": [
				{"say": "Solhaven's gate still stands. Don't take it hard. Sharpen that deck and come back. I'm not going anywhere.", "who": "hale"},
			]},
	]


static func _bram() -> Array:
	return [
		{"if": "beat_aldric", "then": [
			{"if": "!bram_after_trial", "then": [
				{"set": "bram_after_trial"},
				{"say": "You beat Solhaven's Champion, Sprout. By nightfall half of Veyl will know your name. I liked it better when nobody did.", "who": "bram"},
			]},
		]},
		{"say": "There you are. What do you need?", "who": "bram"},
		{"choice": ["Any advice?", "Rest and save", "Tell me about the gods", "About Morne..."], "then": [
			[
				{"say": "Read the orb on a Totem's card before you read anything else. That's its element. Hit a weakness and it takes half again as much damage.", "who": "bram"},
				{"say": "Then read yourself. Every card leans on one of your attributes: Might, Resolve, Swiftness and the rest.", "who": "bram"},
				{"say": "Meet the card's mark and it wakes for you. Attuned. More damage, more life, cheaper attacks. The gold line on the card tells you what.", "who": "bram"},
			],
			[
				{"save": true},
				{"say": "Go on, get some sleep. I'll keep the lamp lit. (Game saved.)", "who": "bram"},
			],
			[
				{"say": "Hundreds of gods up there, Sprout, and seven with a real claim on the Throne of Ages. Every one of them wants you wearing their colours.", "who": "bram"},
				{"say": "Swear to one and they'll bless you for it: a stronger attribute, and a Gift you can call once a duel.", "who": "bram"},
				{"say": "Stay Unsworn and you get a little of everything, and nobody's leash round your neck. Your choice, when the time comes. Don't let anyone hurry it. Least of all a god.", "who": "bram"},
			],
			[
				{"say": "He's a banker. Owns Ironvault, and the note on half of everything that isn't. Men like that don't want a thing, Sprout. They collect it.", "who": "bram"},
				{"say": "How do I know? ...Eat something. We'll go home when there's a home to go to. I swore that on the Lantern.", "who": "bram"},
			],
		]},
		{"if": "!sun_court_done", "then": [
			{"say": "Sun Court's up the hill. Can't miss it. It's the bit that's gold.", "who": "bram"},
		]},
	]


## C3 · Wren, as a market duel until the chase is built.
static func _wren() -> Array:
	return [
		{"if": "beat_wren", "then": [
			{"say": "Don't look so pleased. I let you win. Mostly.", "who": "wren"},
			{"say": "Everyone watches the lantern. Nobody watches the moth. So: you watch the lantern. I'll watch the hands.", "who": "wren"},
			{"if": "beat_aldric", "then": [
				{"say": "You beat the golden knight in front of his whole city. I'd have charged for that. Tell me you at least charged.", "who": "wren"},
			], "else": [
				{"say": "One for free, and I don't do free. Aldric's deck has a Legend in it. A real one. Sunlance Seraph, his house's heirloom. Don't let it settle on the field.", "who": "wren"},
			]},
		], "else": [
			{"say": "Well, well. The famous Unsworn. I pictured someone taller. Possibly glowing.", "who": "wren"},
			{"say": "I had my hand in your pocket back there, you know. That blank card of yours bit me. That's not a card. That's a curse with corners.", "who": "wren"},
			{"choice": ["That's mine.", "Who sent you?"], "then": [
				[{"say": "Clearly. It's very loyal. Like a dog. A dog that bites.", "who": "wren"}],
				[{"say": "Nobody sends me. I go where the money is, and that thing is the most money I've ever seen.", "who": "wren"}],
			]},
			{"say": "Tell you what. Beat me, and I'll tell you what you're worth, and who's paying. Lose, and you buy me dinner. I'm not greedy.", "who": "wren"},
			{"choice": ["Duel Wren", "Not now"], "then": [[
				{"duel": {"deck": "wren", "name": "Wren", "look": "wren", "patron": "", "attrs": {"cunning": 2}},
					"win": [
						{"set": "beat_wren"},
						{"say": "...All right. All right. A deal's a deal.", "who": "wren"},
						{"say": "Ten thousand crowns. That's the price on a blank Sigil and the hand that holds it, in every black market in Veyl. Sealed with this.", "who": "wren"},
						{"say": "[i]She flicks you a wax seal: a coin crossed with a key.[/i]"},
						{"say": "Ironvault. You've met their hunters. Now everyone who can count to ten thousand is a hunter. You'll want someone who knows where they drink.", "who": "wren"},
						{"choice": ["Are you offering to help?", "Why should we trust a thief?"], "then": [
							[{"say": "I'm offering to be nearby when the money happens. Call it help if you like.", "who": "wren"}],
							[{"say": "You shouldn't. That's why I'm useful. I know exactly how people like me think.", "who": "wren"}],
						]},
						{"say": "Anyway. I'm coming. It isn't up to you, or the old man.", "who": "wren"},
						{"say": "[i]She pulls on a pair of fingerless gloves. As the glove goes on, a small moth tattoo shows on her wrist, and is gone.[/i]"},
						{"say": "I'm Wren. Call me when you need a hand in someone else's pocket.", "who": "wren"},
						{"give": "wren"},
					],
					"lose": [
						{"say": "Too slow! Dinner's on you. Somewhere with tablecloths. Then we'll go again.", "who": "wren"},
					]},
			], []]},
		]},
	]


static func _pip() -> Array:
	return [
		{"if": "beat_aldric", "then": [
			{"say": "You beat him. You actually beat him! ...He's still the best. But you're second-best. In the whole world!", "who": "pip"},
		], "else": [
			{"say": "Hah! Hyah! ...You're the Unsworn! Everyone says! Is it true you haven't got a god? Everybody's got a god. Even my nan's got a god, and she doesn't like anybody.", "who": "pip"},
			{"say": "Ser Aldric's never lost a Trial. His Gilded Sentinel never lets anyone through. You'd have to go round it. You can't go round it.", "who": "pip"},
			{"say": "I'm going to be his squire. He doesn't know yet.", "who": "pip"},
		]},
	]


static func _maren() -> Array:
	return [
		{"if": "beat_aldric", "then": [
			{"say": "The Sun's own knight, beaten in the Sun's own city. Oh, the priests will be smiling at you now. Count their teeth.", "who": "maren"},
		], "else": [
			{"say": "Sit, sit. You've the look of someone who's walked a long way to be lied to.", "who": "maren"},
			{"say": "Two thousand years Solmaris has sat the Throne of Ages. Two thousand years of sun on these stones. Lovely weather.", "who": "maren"},
			{"say": "There's an old story the Temple doesn't tell. The last Age was the Burning Crown's to win, plain as day. Then the Great Sundial ran slow.", "who": "maren"},
			{"say": "Nine days slow. Funny, that. Don't tell the priests I said so.", "who": "maren"},
			{"choice": ["What happened then?", "Why tell me?"], "then": [
				[{"say": "The Sun's Champion caught up, and here we all are. And mind yourself when the priests start smiling at you.", "who": "maren"}],
				[{"say": "Because you're the first in two thousand years the priests can't tell to hush. And mind yourself when they start smiling at you.", "who": "maren"}],
			]},
		]},
	]


static func _tamsin() -> Array:
	return [
		{"if": "beat_aldric", "then": [
			{"say": "The Unsworn, at my stall! Everything's a crown dearer today, love. Fame has a price, and I've just set it.", "who": "tamsin"},
		], "else": [
			{"say": "Sigil caches! Fresh from the Shardlands, sealed and certified, never opened by a dishonest hand! Mine are honest. Nearly all of them.", "who": "tamsin"},
			{"say": "Crowns for caches. Win duels, earn crowns, come back. Simple.", "who": "tamsin"},
			{"say": "The Hrimmark caravan's a week late. Snow, at harvest. They say the boy-king's goddess has stopped minding the calendar.", "who": "tamsin"},
		]},
	]


static func _herald() -> Array:
	return [
		{"say": "[i]The Pale Herald says nothing. The empty hood turns, very slightly, to follow you.[/i]"},
	]


## C4 · The Sun Court, played on the temple steps until the hall is built.
static func _hierarch() -> Array:
	return [
		{"if": "sun_court_done", "then": [
			{"if": "beat_aldric", "then": [
				{"say": "Enjoy your afternoon, Unsworn. The Goddess has a long memory, and so do I.", "who": "hierarch"},
			], "else": [
				{"say": "You have the Court's leave to be tested. Do not mistake it for welcome.", "who": "hierarch"},
			]},
		], "else": [
			{"say": "[i]Courtiers whisper on the steps as you climb.[/i]"},
			{"say": "That's the Unsworn? It's so... small.", "who": "courtier"},
			{"say": "From a farming village. Can you imagine.", "who": "courtier"},
			{"say": "So. The Covenant's little accident. You'll present your mark, as the law requires.", "who": "hierarch"},
			{"say": "[i]You raise your hand; the mark glows.[/i]"},
			{"say": "Yes, yes. Very pretty. And you'll surrender that card to the Goddess's vault, for safekeeping. A blank Sigil in a farmhand's pocket is a danger to us all.", "who": "hierarch"},
			{"say": "The Covenant forbids it.", "who": "herald"},
			{"say": "[i]The steps go silent.[/i]"},
			{"say": "Of course. I only meant to offer.", "who": "hierarch"},
			{"say": "Then let the Unsworn be tested, honestly. No challenger enters the Turning without the Sun Court's Trial, so I'll give it myself, before the whole city. Your Grace?", "who": "aldric"},
			{"say": "...Very well. But first the Unsworn passes the Trial of Light in the Sun Temple, as every pilgrim does. If they can.", "who": "hierarch"},
			{"scene": "solmaris"},
			{"say": "[i]Aldric catches up with you at the foot of the steps, away from the courtiers.[/i]"},
			{"say": "The Goddess spoke to you. I saw your eyes change.", "who": "aldric"},
			{"say": "She hasn't spoken to me in a month.", "who": "aldric"},
			{"say": "[i]He walks away before you can answer.[/i]"},
			{"set": "sun_court_done"},
			{"objective": "Pass the Trial of Light: Acolyte Liora, on the temple steps."},
		]},
	]


## C5 · The Trial of Light, as a duel against Liora until the mirror puzzle is built.
static func _liora() -> Array:
	return [
		{"if": "temple_leave", "then": [
			{"say": "The Sun go with you, Unsworn. The Circle won't turn you away now. I haven't told anyone about the mirrors. I shan't.", "who": "liora"},
		], "else": [
			{"if": "!sun_court_done", "then": [
				{"say": "Oh! You're the... yes. The Hierarch hasn't sent for you yet. Present your mark to him first. He's the gold one. On the steps. Sorry.", "who": "liora"},
			], "else": [
				{"say": "Oh! You're early. I mean, you're on time. I'm early. I mean... welcome, pilgrim. Challenger. Unsworn. Sorry. Nobody's ever been all three.", "who": "liora"},
				{"say": "The Trial of Light. A duel, before the mirrors of the Sun Temple. They watch every Rite. They're very old. And very fussy.", "who": "liora"},
				{"say": "If you fall, the mirrors simply begin again. They're patient. More patient than me.", "who": "liora"},
				{"choice": ["Take the Trial of Light", "Not yet"], "then": [[
					{"duel": {"deck": "temple_acolyte", "name": "Acolyte Liora", "look": "acolyte", "patron": "solmaris", "attrs": {"insight": 2}},
						"win": [
							{"set": "temple_leave"},
							{"say": "You've passed. You may challenge the Sun's Champion.", "who": "liora"},
							{"say": "Take this candle. Every pilgrim who passes gets one. Not many do. It has carried more than one Totem back from the dark.", "who": "liora"},
							{"give": "revival_candle"},
							{"say": "Can I tell you something? The mirrors showed you twice. Once as you are. And once all in white.", "who": "liora"},
							{"say": "They've never done that. Not for anyone.", "who": "liora"},
							{"choice": ["What does it mean?", "Don't tell anyone."], "then": [
								[{"say": "I don't know. And I don't want to.", "who": "liora"}],
								[{"say": "I wasn't going to. Nobody listens to an acolyte. Tonight I'm glad of it.", "who": "liora"}],
							]},
							{"objective": "Face Ser Aldric at the Duelling Circle, west of the fountain."},
						],
						"lose": [
							{"say": "The mirrors would like you to try again. Politely.", "who": "liora"},
						]},
				], []]},
			]},
		]},
	]


## C6 · The Golden Knight, at the square's Duelling Circle until the Sunspire is built.
static func _aldric() -> Array:
	return [
		{"if": "beat_aldric", "then": [
			{"say": "I have served the Sun since I could hold a sword. I did not expect to be taught humility by someone with no god at all.", "who": "aldric"},
			{"say": "Go carefully, Unsworn. The Hierarch will not forgive this as easily as I do.", "who": "aldric"},
		], "else": [
			{"if": "!temple_leave", "then": [
				{"say": "So. The eighth mark. I did not know the Covenant had a sense of humour.", "who": "aldric"},
				{"say": "They say the sky fell on your village, and men with torches came after it. I am sorry. Nobody in this city will say that to you, so I will.", "who": "aldric"},
				{"if": "sun_court_done", "then": [
					{"say": "But I do not duel the untested. Pass the Temple's Trial of Light, and I will meet you here.", "who": "aldric"},
				], "else": [
					{"say": "But I do not duel the unblessed on a whim. Present your mark to the Hierarch, pass the Temple's Trial of Light, and I will meet you here.", "who": "aldric"},
				]},
			], "else": [
				{"say": "[i]The stands around the Circle are packed with the people of Solhaven. Pip is on someone's shoulders, waving his wooden sword.[/i]"},
				{"say": "ALDRIC! ALDRIC! ALDRIC!", "who": "pip"},
				{"say": "Whatever you are, I will fight you fairly. It is the only promise anyone can make in this Trial.", "who": "aldric"},
				{"choice": ["Same to you.", "May the best duellist win."], "then": [
					[{"say": "Then the Goddess will judge us both.", "who": "aldric"}],
					[{"say": "They usually do.", "who": "aldric"}],
				]},
				{"say": "The Sun Court's Trial, by the Covenant. If the Unsworn wins, they may challenge any Champion in Veyl until the Turning closes. Begin.", "who": "herald"},
				{"choice": ["Begin the Trial", "Give me a moment"], "then": [[
					{"duel": {"deck": "ser_aldric", "name": "Ser Aldric Vane", "look": "aldric", "patron": "solmaris", "attrs": {"presence": 3, "resolve": 1}, "trial": true},
						"win": [
							{"set": "beat_aldric"},
							{"say": "[i]Aldric's last Totem falls, and the magic it sheds pours into your hand. Silence across the stands.[/i]"},
							{"say": "The Unsworn is tested and found worthy. Challenge whom you will.", "who": "herald"},
							{"say": "[i]The light his fallen Totems shed gathers in your open hand, and cools into a card: a lion of your own.[/i]"},
							{"give": "sunmane_lion"},
							{"say": "My Lion's light, made yours. Treat it well.", "who": "aldric"},
							{"say": "[i]Silence. Then one small voice from the stands.[/i]"},
							{"say": "...That was AMAZING!", "who": "pip"},
							{"say": "[i]Pip cheers, then the person beside him, then the whole square. Aldric watches you through the noise.[/i]"},
							{"say": "You fight like someone with nothing to lose.", "who": "aldric"},
							{"choice": ["I've already lost my home.", "Maybe I don't."], "then": [
								[{"say": "Then I'm sorry. Truly.", "who": "aldric"}],
								[{"say": "Everyone has something. You'll find yours. That's when it gets hard.", "who": "aldric"}],
							]},
							{"say": "Solmaris will know of this before the sun sets. Not from me. I'd have to hear from her first.", "who": "aldric"},
							{"objective": ""},
							{"scene": "vault"},
						],
						"lose": [
							{"say": "Well fought. There's no shame in it. A defeat is a lesson, not a debt. Come back when you've learned it.", "who": "aldric"},
						]},
				], []]},
			]},
		]},
	]


# ================================================================ scenes ===

static func scene(name: String, w: World) -> void:
	match name:
		"solmaris":
			await _solmaris(w)
		"vault":
			await _vault(w)


## The sun-window blazes white and sound stops: Solmaris leans down out of the glare.
static func _solmaris(w: World) -> void:
	var hud := w.hud
	hud.dialogue.close()
	Music.stinger("the_marking")
	await w.flash(Color(1.0, 0.98, 0.9), 0.5, 0.8)
	await hud.dialogue.say("", null, "[i]The light blazes white and sound stops. The courtiers, the Hierarch and Aldric turn to statues of light mid-gesture. Only you can move.[/i]")
	await hud.dialogue.say("", null, "[i]Above the temple, something vast leans down out of the glare: Solmaris, white and gold, her face lost in light.[/i]")
	await hud.dialogue.say("Solmaris", null, "Little mark. You were not meant to be.")
	await hud.dialogue.say("Solmaris", null, "Kneel, and I will carry the weight of that card for you. No hunter will touch you in my city. No harm will find you in my Age.")
	var pick := await hud.dialogue.choose(["I'll think about it.", "I kneel to no one.", "What is this card?"])
	match pick:
		0:
			Game.set_flag("solmaris_favour", "unsure")
			await hud.dialogue.say("Solmaris", null, "Think quickly. Ages are long, but Trials are short.")
		1:
			Game.set_flag("solmaris_favour", "defiant")
			await hud.dialogue.say("Solmaris", null, "Everyone kneels, little mark. Some simply take longer.")
		_:
			Game.set_flag("solmaris_favour", "curious")
			await hud.dialogue.say("Solmaris", null, "Something that should have stayed buried.")
	await hud.dialogue.say("", null, "[i]The light folds away and time returns. Nobody else saw a thing.[/i]")
	hud.dialogue.close()
	await w.flash(Color(1.0, 0.98, 0.9), 0.15, 0.9)


## C7 · Gold in the Dark, then the end of the chapter.
static func _vault(w: World) -> void:
	var hud := w.hud
	hud.dialogue.close()
	await hud.fade(1.0, 1.2)
	await hud.dialogue.say("", null, "[i]Night. The wagon in a field outside Solhaven's walls, Turnip asleep. Bram sits on the tailboard, turning the blank card under the lamp.[/i]")
	await hud.dialogue.say("", null, "[i]A faint image shows on it: a white eye inside a ring of runes. Then it fades.[/i]")
	await hud.dialogue.say("Bram", DollArt.portrait("bram"), "A seal. ...Oh, Sprout. It's the seal.")
	await hud.dialogue.say("", null, "[i]He hides the card in his coat and stares into the dark for a long time. In the shadow of the wagon wheel, Wren is awake. She heard. She says nothing.[/i]")
	await hud.dialogue.say("", null, "[i]Ironvault. A vault of iron racks and glowing cards climbing into darkness, a ledger desk, a gold case with eight empty slots.[/i]")
	await hud.dialogue.say("", null, "[i]For the first time, a face: Caldus Morne, silver-gold hair, black velvet, rings on every finger, a calm and pleasant smile. Huntmaster Krell kneels before the desk.[/i]")
	await hud.dialogue.say("Huntmaster Krell", DollArt.portrait("krell"), "The Unsworn beat the Sun's knight.")
	await hud.dialogue.say("Caldus Morne", DollArt.portrait("morne"), "Good. Let them all grow strong.")
	await hud.dialogue.say("", null, "[i]He closes a ledger with eight names on its cover.[/i]")
	await hud.dialogue.say("Caldus Morne", DollArt.portrait("morne"), "A harvest should be ripe before it's cut.")
	await hud.dialogue.say("Huntmaster Krell", DollArt.portrait("krell"), "There's an old man travelling with them. Big. An innkeeper. Calls himself Bram.")
	await hud.dialogue.say("", null, "[i]Morne's hand stops on the ledger.[/i]")
	await hud.dialogue.say("Caldus Morne", DollArt.portrait("morne"), "Holloway. My father paid him once, in advance. He never delivered.")
	await hud.dialogue.say("Caldus Morne", DollArt.portrait("morne"), "Old debts, Krell. I always collect.")
	await hud.dialogue.say("", null, "[i]He sets a single gold coin on the eighth name. Yours.[/i]")
	await hud.dialogue.say("", null, "[center][b]End of Chapter One: The Sun's Court.[/b][/center]\n[center]The Unsworn is tested and found worthy. Six kingdoms wait, and the Turning has a year to run.[/center]")
	await hud.dialogue.say("", null, "[center]Thank you for playing this early slice of The Covenant War.\nYou can keep exploring Solhaven and duelling.[/center]")
	hud.dialogue.close()
	Game.save_game()
	await hud.fade(0.0, 1.2)
