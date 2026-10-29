class_name DuelFXStyle
extends RefCounted
## What every attack and every card looks like on the 3D field (29 October,
## Gary: "In the card battle I want animations added to each card or attacks
## effect"). It's data, not code, so a card nobody has thought about still
## gets a picture that fits it:
##
##   ELEMENTS    each element's colours, how its blows cross the Circle
##               ("travel"), how they land ("impact"), what falls from the
##               sky for it ("fall") and the gem its Totems shatter into
##   MOVE_WORDS  a move's name says what kind of move it is: a bite or a
##               charge (melee), a breath, a beam, something falling from
##               above, a wave, a howl or a gaze, a lash or a snare
##   OVERRIDES   one card, or one move of a card ("ashen_drake:2"), pinned
##               to a look of its own
##   RITE_OPS / ANSWER_OPS / WARD_OPS   a card's picture from what it does
##
## DuelField3D draws the pieces (strike_travel, strike_impact, card_motif,
## ward_motif, answer_motif); DuelScreen picks them with attack_style() and
## card_style(). The 2D field keeps its own drawn effects.

## travel: fireball, water_jet, fissure, arc, gust, ice_volley, leaf_flurry,
## blades, venom_glob, mind_rings, runes, radiant_beam, shadow_wisps,
## star_fall, orb. impact: flare, splash, rock_burst, arc_burst, gust_burst,
## ice_burst, thorn_burst, metal_sparks, venom_splat, mind_burst, rune_burst,
## radiant_burst, shadow_burst, star_burst, plain. fall: meteor, rockfall,
## bolt_down, star_fall, whirlpool, ice_fall, leaf_fall.
const ELEMENTS := {
	"fire": {"col": "ff8a33", "hot": "ffe0a0", "travel": "fireball", "impact": "flare", "fall": "meteor", "gem": "ffc46b"},
	"tide": {"col": "4fb2ff", "hot": "e2f6ff", "travel": "water_jet", "impact": "splash", "fall": "whirlpool", "gem": "8fe3ff"},
	"earth": {"col": "d09a5c", "hot": "f6dcaa", "travel": "fissure", "impact": "rock_burst", "fall": "rockfall", "gem": "ecc890"},
	"storm": {"col": "ffe14d", "hot": "ffffff", "travel": "arc", "impact": "arc_burst", "fall": "bolt_down", "gem": "fff08a"},
	"wind": {"col": "cfeee6", "hot": "ffffff", "travel": "gust", "impact": "gust_burst", "fall": "bolt_down", "gem": "e6fff8"},
	"frost": {"col": "9fe3ff", "hot": "ffffff", "travel": "ice_volley", "impact": "ice_burst", "fall": "ice_fall", "gem": "dcf7ff"},
	"verdant": {"col": "7fd65a", "hot": "e0ffb0", "travel": "leaf_flurry", "impact": "thorn_burst", "fall": "leaf_fall", "gem": "a6f59a"},
	"metal": {"col": "cfdcf0", "hot": "ffffff", "travel": "blades", "impact": "metal_sparks", "fall": "meteor", "gem": "eef3fb"},
	"venom": {"col": "a6e83a", "hot": "eaffa0", "travel": "venom_glob", "impact": "venom_splat", "fall": "meteor", "gem": "cdf57a"},
	"psychic": {"col": "ff7ad9", "hot": "ffd6f4", "travel": "mind_rings", "impact": "mind_burst", "fall": "star_fall", "gem": "ffb8ee"},
	"mystic": {"col": "a98bff", "hot": "e6dcff", "travel": "runes", "impact": "rune_burst", "fall": "star_fall", "gem": "cdb8ff"},
	"spirit": {"col": "7ff5e6", "hot": "ecfffc", "travel": "radiant_beam", "impact": "radiant_burst", "fall": "star_fall", "gem": "b0fff4"},
	"radiant": {"col": "ffe39a", "hot": "fffbe8", "travel": "radiant_beam", "impact": "radiant_burst", "fall": "star_fall", "gem": "fff2b8"},
	"umbral": {"col": "8a5cf0", "hot": "d2b8ff", "travel": "shadow_wisps", "impact": "shadow_burst", "fall": "star_fall", "gem": "bba2ff"},
	"astral": {"col": "9fb6ff", "hot": "ffffff", "travel": "star_fall", "impact": "star_burst", "fall": "star_fall", "gem": "c8d6ff"},
	"void": {"col": "8a7fb0", "hot": "e0dcf0", "travel": "shadow_wisps", "impact": "shadow_burst", "fall": "star_fall", "gem": "cfc8e8"},
	"any": {"col": "ffd98a", "hot": "fff6dc", "travel": "orb", "impact": "plain", "fall": "meteor", "gem": "ffffff"},
}

## A move's kind from the words in its name; the first row that matches wins.
## Anything else is thrown, spat or cast across the Circle ("travel").
const MOVE_WORDS := [
	["breath", ["breath", "spit", "scorch", "pollen"]],
	["beam", ["lance", "ray", "beam", "judgement", "dawnbreak", "glint", "glimmer", "sunlance", "dazzle"]],
	["fall", ["storm", "rockfall", "landslide", "earthbreaker", "falling star", "thunderhead", "maelstrom"]],
	["wave", ["tide", "riptide", "undertow", "surge", "crushing"]],
	["howl", ["howl", "screech", "hoot", "gaze", "mirage", "illusion", "devour"]],
	["lash", ["lash", "whip", "grasp", "snare", "vine", "web", "coil", "overgrowth", "bramble", "growth"]],
	["melee", ["nip", "bite", "fang", "rush", "claw", "headbutt", "charge", "slam", "ram", "smash", "bash", "tackle",
		"gnaw", "strike", "blade", "ambush", "pounce", "maw", "talon", "snap"]],
]

## The elements whose lashes come up out of the ground.
const LASH_ELEMENTS := ["verdant", "venom", "earth", "tide"]

## One card ("cinderpup") or one of its moves ("ashen_drake:2") with a look of
## its own; any key of a style can be set (travel, impact, kind, col).
const OVERRIDES := {
	"ashen_drake:1": {"kind": "breath"},
	"ashen_drake:2": {"kind": "fall", "fall": "meteor"},
	"stormcaller:0": {"kind": "travel", "travel": "arc"},
	"voltlynx:1": {"kind": "travel", "travel": "arc"},
	"tempest_lynx:1": {"kind": "fall", "fall": "bolt_down"},
	"somnowl:1": {"kind": "howl"},
	"thought_eater:1": {"kind": "howl"},
	"quarry_golem:1": {"kind": "fall", "fall": "rockfall"},
	"cragmaul:0": {"kind": "fall", "fall": "rockfall"},
	"veilfox:0": {"kind": "travel"},
	"ninefold_fox:0": {"kind": "melee"},
	"duskstalker:0": {"kind": "travel", "travel": "shadow_wisps"},
	"lantern_moth:0": {"kind": "beam"},
	"mossling:1": {"kind": "lash"},
	"mirewidow:1": {"kind": "lash"},
	"plague_asp:1": {"kind": "travel", "travel": "venom_glob"},
	"blight_wyrm:1": {"kind": "breath"},
	"rimecub:1": {"kind": "breath"},
	"starling:1": {"kind": "fall", "fall": "star_fall"},
	"runeowl:1": {"kind": "travel", "travel": "runes"},
	"dawnling:1": {"kind": "beam"},
	"hallowed_hound:1": {"kind": "howl"},
}

## What a Rite looks like, from the first of its effects found here (in this
## order); a Rite with none of them falls back on its damage and element.
## Each is a motif DuelField3D.card_motif() draws.
const RITE_OPS := [
	["shield", "wall"], ["shield_unhurt", "wall"],
	["heal", "mend"], ["cure", "mend"], ["life", "mend"], ["regen", "mend"],
	["buff", "aura"], ["buff_family", "howl_aura"],
	["revive_field", "revival"], ["revive_hand", "revival"], ["call_legend_free", "revival"],
	["draw", "cards"], ["draw_full", "cards"], ["search_totem", "cards"], ["seek_kindred", "cards"],
	["seek_family", "cards"], ["relic_hunt", "cards"], ["discard_to_top", "cards"], ["pick_top", "cards"],
	["fate_bonus", "cards"],
	["essence", "essence"], ["essence_max", "essence"],
	["bounce", "wave"], ["move_foe", "wave"], ["drain", "drain"],
	["terrain", "terrain"], ["unbind", "unbind"], ["veil_call_free", "veil"], ["reveal_twice", "reveal"],
	["burned_damage", "stoke"],
]

## A boon a Rite gives has its own look (war paint, a blessing, a veil...).
const BOON_MOTIF := {"empowered": "aura", "regenerating": "mend", "veiled": "veil", "blessed": "blessing",
	"hastened": "haste", "shielded": "wall"}

## Answers (Phase A) by what they do.
const ANSWER_OPS := [
	["negate", "shield"], ["cancel_rite", "rune_seal"], ["cancel_ward", "rune_seal"], ["halve", "ash_veil"],
	["blunt", "wall"], ["redirect_guardian", "wall"], ["bounce_rite", "wave"], ["sidestep", "haste"],
	["essence", "essence"], ["essence_next", "essence"], ["draw", "cards"],
]

## Wards springing, by what they do: where it plays (the attacker, the Totem
## it guards, the Totem just called, or its owner's side) and its picture.
const WARD_OPS := [
	["negate", "target", "shield"], ["shield_target", "target", "shield"], ["block_life", "life", "shield"],
	["status_attacker", "attacker", "status"], ["damage_attacker", "attacker", "strike"],
	["status_called", "called", "status"], ["damage_called", "called", "strike"], ["bounce_called", "called", "wave"],
	["cancel_rite", "side", "rune_seal"], ["survive", "life", "blessing"],
]

## The few cards whose picture isn't the one their effects would give.
const CARD_MOTIF := {
	"stoke_the_coals": "stoke", "rite_of_ashes": "ash_storm", "loaded_dice": "dice", "hour_of_need": "revival",
	"second_dawn": "revival", "shadow_step": "veil", "memory_thread": "cards", "deep_roots": "mend",
	"stone_patience": "strike", "shatter": "strike", "rallying_light": "blessing", "sunward_vow": "blessing",
	"pack_howl": "howl_aura", "kindled_soul": "revival", "rekindle": "revival",
}


static func element(el: String) -> Dictionary:
	return ELEMENTS.get(el, ELEMENTS.any)


static func col(el: String) -> Color:
	return Color(String(element(el).col))


static func hot(el: String) -> Color:
	return Color(String(element(el).hot))


static func gem(el: String) -> Color:
	return Color(String(element(el).gem))


## The kind of move a name says it is: melee, breath, beam, fall, wave, howl,
## lash, or travel (thrown or cast across).
static func move_kind(move_name: String) -> String:
	# (a word counts where a word starts: "Splash" isn't a lash)
	var n := " " + move_name.to_lower().replace("-", " ") + " "
	for row in MOVE_WORDS:
		for w in row[1]:
			if n.contains(" " + String(w)):
				return String(row[0])
	return "travel"


## Everything about how an attack looks: {kind, travel, impact, fall, col,
## hot, el}. `id` is the attacking Totem's card, `i` the move's index.
static func attack_style(id: String, el: String, move: Dictionary, i: int) -> Dictionary:
	var e := element(el)
	var out := {"el": el, "kind": move_kind(String(move.get("name", ""))), "travel": String(e.travel),
		"impact": String(e.impact), "fall": String(e.fall), "col": Color(String(e.col)), "hot": Color(String(e.hot))}
	if String(move.get("target", "foe")) == "all_foes" and out.kind in ["travel", "melee", "beam", "lash"]:
		out.kind = "fall"   # (a blow on every Totem across comes down on each of them)
	# (a lash is vines, a web or a water-whip out of the ground; for any
	# other element it's the old lunge and strike)
	if out.kind == "lash" and not el in LASH_ELEMENTS:
		out.kind = "melee"
	for key in [id, "%s:%d" % [id, i]]:
		if OVERRIDES.has(key):
			for k in OVERRIDES[key]:
				var v = OVERRIDES[key][k]
				out[k] = Color(String(v)) if k in ["col", "hot"] else v
	return out


## The motif a Rite (or Relic, or Ward set) plays: one of card_motif()'s.
static func rite_motif(d: Dictionary, id: String = "") -> String:
	if CARD_MOTIF.has(id):
		return String(CARD_MOTIF[id])
	if String(d.get("kind", "")) == "relic":
		return "relic"
	var effects: Array = d.get("effects", [])
	var ops := {}
	for e in effects:
		ops[String((e as Dictionary).get("op", ""))] = e
	for row in RITE_OPS:
		if ops.has(row[0]):
			return String(row[1])
	if ops.has("boon"):
		return String(BOON_MOTIF.get(String(ops.boon.get("boon", "")), "aura"))
	if ops.has("status"):
		return "status"
	if int(d.get("damage", 0)) > 0 or String(d.get("target", "none")) in ["foe_totem", "all_foes"]:
		return "strike"
	if bool(d.get("continuous", false)) or d.has("standing"):
		return "banner"
	return "sigil"


## An answer's picture, from what it does.
static func answer_motif(d: Dictionary) -> String:
	var ops := {}
	for e in d.get("effects", []):
		ops[String((e as Dictionary).get("op", ""))] = true
	for row in ANSWER_OPS:
		if ops.has(row[0]):
			return String(row[1])
	return "sigil"


## A springing Ward's place and picture: [where, motif].
static func ward_motif(d: Dictionary) -> Array:
	for e in d.get("effects", []):
		var op := String((e as Dictionary).get("op", ""))
		for row in WARD_OPS:
			if row[0] == op:
				return [String(row[1]), String(row[2])]
	return ["side", "shield"]
