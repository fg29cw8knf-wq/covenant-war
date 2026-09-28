class_name Lore
extends RefCounted
## Shared world data: elements and their matchups, player attributes, the
## seven contending gods and their Divine Gifts. Everything here comes from
## the Story & World Guide - change it here and the whole game follows.

const CORE_ELEMENTS := ["fire", "frost", "tide", "storm", "earth", "wind",
	"verdant", "metal", "venom", "psychic", "mystic", "spirit"]
const DIVINE_ELEMENTS := ["radiant", "umbral", "astral", "void"]

## strong = deals extra damage to; weak = takes extra damage from.
## colors = [light, main, dark]
const ELEMENTS := {
	"fire": {"name": "Fire", "strong": ["frost", "verdant"], "weak": ["tide", "earth"],
		"colors": ["ffb36b", "e9552d", "7c1f10"]},
	"frost": {"name": "Frost", "strong": ["wind", "tide"], "weak": ["fire", "metal"],
		"colors": ["dff6ff", "7cc8f0", "24577a"]},
	"tide": {"name": "Tide", "strong": ["fire", "earth"], "weak": ["frost", "storm", "venom"],
		"colors": ["9ad7ff", "2f86dd", "153f7a"]},
	"storm": {"name": "Storm", "strong": ["tide", "metal"], "weak": ["earth", "wind"],
		"colors": ["fff29e", "f0bd24", "8a650c"]},
	"earth": {"name": "Earth", "strong": ["storm", "fire"], "weak": ["tide", "verdant"],
		"colors": ["e6c393", "b07843", "553515"]},
	"wind": {"name": "Wind", "strong": ["storm", "venom"], "weak": ["frost", "verdant"],
		"colors": ["dcf7e8", "72c9a0", "2a6650"]},
	"verdant": {"name": "Verdant", "strong": ["earth", "wind"], "weak": ["fire", "metal", "venom"],
		"colors": ["b6e68f", "3aa647", "1a5424"]},
	"metal": {"name": "Metal", "strong": ["frost", "verdant"], "weak": ["storm", "mystic"],
		"colors": ["eef1f5", "9aa4b3", "3f4654"]},
	"venom": {"name": "Venom", "strong": ["verdant", "tide"], "weak": ["wind", "psychic", "spirit"],
		"colors": ["e2c0ee", "9a5bb3", "47245a"]},
	"psychic": {"name": "Psychic", "strong": ["mystic", "venom"], "weak": ["spirit"],
		"colors": ["ffc6e2", "e0569b", "7a1f4f"]},
	"mystic": {"name": "Mystic", "strong": ["spirit", "metal"], "weak": ["psychic"],
		"colors": ["c9ccff", "5d63d9", "262a6e"]},
	"spirit": {"name": "Spirit", "strong": ["psychic", "venom"], "weak": ["mystic"],
		"colors": ["cff7ef", "5fc4b2", "245a52"]},
	"radiant": {"name": "Radiant", "strong": ["umbral"], "weak": ["umbral"],
		"colors": ["fff7d6", "f2cf5b", "8a6a12"]},
	"umbral": {"name": "Umbral", "strong": ["radiant"], "weak": ["radiant"],
		"colors": ["c4b1dd", "4b3570", "1b1030"]},
	"astral": {"name": "Astral", "strong": ["void"], "weak": ["void"],
		"colors": ["b3c9ff", "3f5fd6", "0f1f5c"]},
	"void": {"name": "Void", "strong": ["astral"], "weak": ["astral"],
		"colors": ["d2d2da", "4a4a57", "0d0d12"]},
	"any": {"name": "Any", "strong": [], "weak": [],
		"colors": ["f4f4f7", "b4b4c3", "4d4d60"]},
}

const WEAKNESS_MULT := 1.5
const DIVINE_SHIELD := 20      # divine Totems take this much less from core elements
const RESISTANCE := 20

const ATTRIBUTES := ["might", "resolve", "swiftness", "cunning", "insight", "intellect", "presence"]
const ATTRIBUTE_NAMES := {
	"might": "Might", "resolve": "Resolve", "swiftness": "Swiftness", "cunning": "Cunning",
	"insight": "Insight", "intellect": "Intellect", "presence": "Presence",
}

const GODS := {
	"solmaris": {"name": "Solmaris", "title": "the Radiant Sovereign", "element": "radiant",
		"attribute": "presence", "gift": "dawns_mercy"},
	"pyrrhane": {"name": "Pyrrhane", "title": "the Burning Crown", "element": "fire",
		"attribute": "might", "gift": "wrath"},
	"vaelith": {"name": "Vaelith", "title": "the Frost Queen", "element": "frost",
		"attribute": "resolve", "gift": "stillness"},
	"ixara": {"name": "Ixara", "title": "the Storm Herald", "element": "storm",
		"attribute": "swiftness", "gift": "tempest"},
	"nocthra": {"name": "Nocthra", "title": "the Veiled Mother", "element": "umbral",
		"attribute": "cunning", "gift": "whisper"},
	"oriel": {"name": "Oriel", "title": "the Dreaming Eye", "element": "psychic",
		"attribute": "insight", "gift": "foresight"},
	"aldrith": {"name": "Aldrith", "title": "the Runeweaver", "element": "mystic",
		"attribute": "intellect", "gift": "recall"},
}

## Extra damage from Pyrrhane's Wrath.
const WRATH_BONUS := 30
## The gift of a duellist sworn to no god.
const UNSWORN_GIFT := "unbound"

const GIFTS := {
	"dawns_mercy": {"name": "Dawn's Mercy", "text": "Heal 80 damage from one of your Totems and clear its conditions."},
	"wrath": {"name": "Wrath", "text": "Your Active Totem deals 30 more damage this turn."},
	"stillness": {"name": "Stillness", "text": "Your opponent's Active Totem is Frozen: it can't attack or retreat next turn."},
	"tempest": {"name": "Tempest", "text": "Retreat for free and attach one extra Energy this turn."},
	"whisper": {"name": "Whisper", "text": "Look at your opponent's hand and discard one card from it."},
	"foresight": {"name": "Foresight", "text": "Draw 2 cards. Your next coin flip this duel lands on heads."},
	"recall": {"name": "Rune of Recall", "text": "Put up to 2 cards from your discard pile into your hand."},
	"unbound": {"name": "Unbound Will", "text": "Draw 3 cards. (The gift of the Unsworn, who kneel to no god.)"},
}

const TIER_NAMES := ["", "Spark", "Glimmer", "Crystal", "Relic", "Legend", "Demigod", "Divine"]
const TIER_MAX_COPIES := [0, 4, 4, 2, 1, 1, 1, 1]


static func element_name(e: String) -> String:
	return ELEMENTS.get(e, ELEMENTS.any).name


static func color(e: String, i: int = 1) -> Color:
	return Color(ELEMENTS.get(e, ELEMENTS.any).colors[i])


static func is_divine(e: String) -> bool:
	return e in DIVINE_ELEMENTS


static func weak_to(e: String) -> Array:
	return ELEMENTS.get(e, ELEMENTS.any).weak


static func strong_against(e: String) -> Array:
	return ELEMENTS.get(e, ELEMENTS.any).strong


## A fresh duellist profile. Attributes run 1-10. "base" holds the earned
## values; "attributes" is base plus the patron's blessing (see set_patron).
static func new_profile(player_name: String = "You", patron: String = "", base: int = 3) -> Dictionary:
	var attrs := {}
	for a in ATTRIBUTES:
		attrs[a] = base
	var p := {"name": player_name, "base": attrs, "attributes": {}, "patron": "", "fortune": 0}
	set_patron(p, patron)
	return p


## Raise (or lower) an earned attribute, then refresh the blessed values.
static func add_attribute(profile: Dictionary, attribute: String, amount: int) -> void:
	var base: Dictionary = profile.base
	base[attribute] = clampi(int(base.get(attribute, 0)) + amount, 1, 10)
	set_patron(profile, profile.get("patron", ""))


## Swear to a god (+3 to their attribute), or "" to stay Unsworn (+1 to all).
static func set_patron(profile: Dictionary, patron: String) -> void:
	profile.patron = patron
	var attrs := {}
	for a in ATTRIBUTES:
		attrs[a] = int(profile.base.get(a, 3))
	if patron == "":
		for a in ATTRIBUTES:
			attrs[a] = mini(10, int(attrs[a]) + 1)
	else:
		var na: String = GODS[patron].attribute
		attrs[na] = mini(10, int(attrs[na]) + 3)
	profile.attributes = attrs
