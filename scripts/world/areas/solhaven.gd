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
static func npcs() -> Array:
	return [
		{"id": "hale", "look": "guard", "name": "Warden Hale", "pos": Vector3(3.2, 0, 11.0), "duel_flag": "beat_hale", "talk": _hale()},
		{"id": "bram", "look": "bram", "name": "Bram", "pos": Vector3(10.2, 0, -0.2), "talk": _bram()},
		{"id": "wren", "look": "wren", "name": "Wren", "pos": Vector3(8.8, 0, 7.6), "duel_flag": "beat_wren", "talk": _wren()},
		{"id": "pip", "look": "child", "name": "Pip", "pos": Vector3(-2.6, 0, -1.6), "talk": _pip()},
		{"id": "maren", "look": "elder", "name": "Old Maren", "pos": Vector3(-10.4, 0, 4.4), "talk": _maren()},
		{"id": "tamsin", "look": "merchant", "name": "Tamsin", "pos": Vector3(12.6, 0, 5.2), "talk": _tamsin()},
		{"id": "liora", "look": "acolyte", "name": "Acolyte Liora", "pos": Vector3(3.2, 0, -14.6), "duel_flag": "temple_leave", "talk": _liora()},
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

## Plays the first time the player enters the area.
static func arrival() -> Array:
	return [
		{"say": "Three days after the fire, you reach Solhaven: the Sun's own city, white stone and gold under a cloudless sky.", "who": "narrator"},
		{"say": "Somewhere in this city is Ser Aldric Vane, Champion of Solmaris. Sooner or later, he'll come looking for the Unsworn.", "who": "narrator"},
		{"say": "I'll find us rooms at the Gilded Hearth, east side of the square. Have a look around. And let the guards see your mark before they see it for themselves.", "who": "bram"},
	]

# Steps: {"say", "who"} · {"if": flag, "then", "else"} · {"choice": [...], "then": [[...], ...]}
# {"duel": {...}, "win": [...], "lose": [...]} · {"set": flag} · {"give": card} · {"save": true}
# "{name}" is replaced with the player's name. A flag starting with "!" means "not".

static func _hale() -> Array:
	return [
		{"if": "met_hale", "then": [
			{"say": "Keep your cards close in the market, {name}. Not everyone in Solhaven is as holy as they look.", "who": "hale"},
			{"if": "!beat_hale", "then": [
				{"say": "Still fancy a round against the Watch?", "who": "hale"},
				{"choice": ["Duel Warden Hale", "Maybe later"], "then": [[{"goto_duel": "hale_duel"}], []]},
			]},
		], "else": [
			{"set": "met_hale"},
			{"say": "Halt. Let me see your hand.", "who": "hale"},
			{"say": "...The Covenant's mark. So the rumours are true. The Unsworn walks into Solhaven.", "who": "hale"},
			{"say": "Every Champion in Veyl will want a look at you. Ser Aldric is waiting at the Duelling Circle, west of the fountain.", "who": "hale"},
			{"say": "But no one challenges the Sun's Champion without the Temple's leave. Speak to the acolytes on the temple steps.", "who": "hale"},
			{"say": "And if you want a warm-up, the Watch never turns down a duel.", "who": "hale"},
			{"choice": ["Duel Warden Hale", "Not now"], "then": [[{"goto_duel": "hale_duel"}], []]},
		]},
	]


static func hale_duel() -> Array:
	return [
		{"duel": {"deck": "solhaven_guard", "name": "Warden Hale", "look": "guard", "patron": "solmaris", "attrs": {"resolve": 1}},
			"win": [
				{"set": "beat_hale"},
				{"say": "Ha! Solid. The Watch keeps its word: take this.", "who": "hale"},
				{"give": "lure_bell"},
			],
			"lose": [
				{"say": "Not bad for a first try. Come back when you've sharpened your deck.", "who": "hale"},
			]},
	]


static func _bram() -> Array:
	return [
		{"say": "There you are. I've taken rooms at the Gilded Hearth. Solhaven prices, mind. Robbery with a smile.", "who": "bram"},
		{"choice": ["Any advice?", "Rest and save", "Tell me about the gods"], "then": [
			[
				{"say": "Watch the orb on a Totem's card. That's its element. Hit a weakness and it takes half again as much damage.", "who": "bram"},
				{"say": "And mind your own nature. Every card leans on one of your attributes: Might, Resolve, Swiftness and the rest.", "who": "bram"},
				{"say": "Meet the card's mark and it becomes Attuned. More damage, more life, cheaper attacks. The gold line on the card tells you what.", "who": "bram"},
			],
			[
				{"save": true},
				{"say": "Rest easy. I'll keep your place. (Game saved.)", "who": "bram"},
			],
			[
				{"say": "Seven gods want the Throne of Ages. Swear to one and they'll bless you: a stronger attribute and a Gift you can call once a duel.", "who": "bram"},
				{"say": "Stay Unsworn and you get a little of everything, and nobody's leash round your neck. Your choice. Nobody else's.", "who": "bram"},
			],
		]},
	]


static func _wren() -> Array:
	return [
		{"if": "beat_wren", "then": [
			{"say": "Don't look so pleased. I let you win. Mostly.", "who": "wren"},
			{"say": "Aldric's deck has a Legend in it. A real one. Sunlance Seraph. Don't let it sit on the field for long.", "who": "wren"},
		], "else": [
			{"say": "Well, well. The famous Unsworn. You look less impressive up close.", "who": "wren"},
			{"say": "Tell you what: beat me, and I'll teach you a trick or two. Lose, and I'm having one of your cards.", "who": "wren"},
			{"choice": ["Duel Wren", "Not now"], "then": [[
				{"duel": {"deck": "wren", "name": "Wren", "look": "wren", "patron": "nocthra", "attrs": {"cunning": 2}},
					"win": [
						{"set": "beat_wren"},
						{"say": "...Fine. A deal's a deal. Here. Call me when you need a hand in someone else's pocket.", "who": "wren"},
						{"give": "wren"},
					],
					"lose": [
						{"say": "Too slow! I'll let you keep your cards this time. Consider it a loan.", "who": "wren"},
					]},
			], []]},
		]},
	]


static func _pip() -> Array:
	return [
		{"say": "Are you really a Champion? You don't have a god? Everybody has a god!", "who": "pip"},
		{"say": "Ser Aldric's never lost a Trial duel. Not once. He's got a Seraph made of sunlight!", "who": "pip"},
	]


static func _maren() -> Array:
	return [
		{"say": "Sit a moment, child. My knees are older than the Hierarch's beard.", "who": "maren"},
		{"say": "Two thousand years Solmaris has sat the Throne of Ages. Two thousand years of sun on these stones.", "who": "maren"},
		{"say": "Now the Age is ending and the other gods smell blood. They say she'll do anything to keep her seat.", "who": "maren"},
		{"say": "Anything, mind. Remember that when the priests start smiling at you.", "who": "maren"},
	]


static func _tamsin() -> Array:
	return [
		{"say": "Sigils, charms, rare Rites from the far kingdoms! ...Well, soon. My caravan's stuck at the Hrimmark pass.", "who": "tamsin"},
		{"say": "Come back when the snows clear, love. I'll have something special for a Champion.", "who": "tamsin"},
	]


static func _liora() -> Array:
	return [
		{"if": "temple_leave", "then": [
			{"say": "The Sun go with you, Unsworn. Ser Aldric waits at the Circle.", "who": "liora"},
		], "else": [
			{"say": "You carry the Covenant's mark, but no god's blessing. The Temple does not know what to make of you.", "who": "liora"},
			{"say": "Our law is simple. To challenge the Sun's Champion, pass the Rite of Dawn: a duel against the Temple.", "who": "liora"},
			{"choice": ["Take the Rite of Dawn", "Not yet"], "then": [[
				{"duel": {"deck": "temple_acolyte", "name": "Acolyte Liora", "look": "acolyte", "patron": "solmaris", "attrs": {"insight": 2}},
					"win": [
						{"set": "temple_leave"},
						{"say": "The dawn answers. You have the Temple's leave to face Ser Aldric.", "who": "liora"},
						{"say": "Take this candle. It has carried more than one Totem back from the dark.", "who": "liora"},
						{"give": "revival_candle"},
					],
					"lose": [
						{"say": "The dawn is patient. Return when you are ready.", "who": "liora"},
					]},
			], []]},
		]},
	]


static func _aldric() -> Array:
	return [
		{"if": "beat_aldric", "then": [
			{"say": "I have served the Sun since I could hold a sword. I did not expect to be taught humility by someone with no god at all.", "who": "aldric"},
			{"say": "Go carefully, Unsworn. The Hierarch will not forgive this as easily as I do.", "who": "aldric"},
		], "else": [
			{"if": "!temple_leave", "then": [
				{"say": "So. The eighth mark. The Covenant has a sense of humour.", "who": "aldric"},
				{"say": "I do not duel the unblessed on a whim. Pass the Temple's Rite of Dawn, and I will meet you here.", "who": "aldric"},
			], "else": [
				{"say": "The Temple gave you leave. Then it's time.", "who": "aldric"},
				{"say": "A Trial duel is binding under the Covenant. The loser forfeits a Sigil of the winner's choosing. Three defeats, and the mark fades.", "who": "aldric"},
				{"choice": ["Begin the Trial duel", "Give me a moment"], "then": [[
					{"duel": {"deck": "ser_aldric", "name": "Ser Aldric Vane", "look": "aldric", "patron": "solmaris", "attrs": {"presence": 3, "resolve": 1}, "trial": true},
						"win": [
							{"set": "beat_aldric"},
							{"say": "...It is done. The Covenant saw it. Choose, then. I will not dishonour the Trial.", "who": "aldric"},
							{"give": "gilded_sentinel"},
							{"say": "Solmaris will hear of this before the sun sets.", "who": "aldric"},
							{"end_slice": true},
						],
						"lose": [
							{"say": "Well fought. Keep your Sigil: the first defeat is a lesson, not a debt. Return when you're stronger.", "who": "aldric"},
						]},
				], []]},
			]},
		]},
	]
