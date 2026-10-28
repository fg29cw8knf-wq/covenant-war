class_name DuelSynergy
extends RefCounted
## The ways cards work together (28 October, Gary: "to add synergy to the
## card game... lets add it all", and "i also want all cards linked to a
## god"). The data and the words live here; DuelGame applies them.
##
##   Families    Totems of a kind (Hounds, Foxes, Cats, Winged, Scaled,
##               Shells, Stoneborn), whatever their element: with another of
##               its family on its side, each has its family's Kinship.
##   Side by Side two Totems of the same element in neighbouring slots each
##               deal 10 more; Shelter, Rally and Tend Totems help whoever
##               stands beside them (DuelCards.KEYWORDS).
##   Reactions   a hit of one element on a Totem with a certain condition
##               (Fire on Frozen melts it, Storm on Soaked runs through it).
##   Bonds       named pairs (DuelCards.BONDS), more of them now.
##   Chains      the cards a duellist plays in a turn: the third costs 1 less,
##               and a Combo card does more as the third card or later.
##   The gods    every card answers to a god. Where that god rules, or when
##               it's Pleased with you, the card is Graced (a Totem hits 10
##               harder, any other card costs 1 less); where its rival
##               rules, or when it's Displeased with you, Shunned (10 less,
##               or 1 more).
##
## Each is taught the first time it matters (DuelScreen, DuelTutor.lesson) and
## has a page under How to Duel (DuelManual) and a riddle (DuelPuzzles).

# ================================================================ families ===

const FAMILIES := {
	"hound": {"name": "Hound", "plural": "Hounds", "trait": "Pack",
		"text": "deals 10 more for each other Hound on your side"},
	"fox": {"name": "Fox", "plural": "Foxes", "trait": "Trickery",
		"text": "+3 on its Fate rolls"},
	"cat": {"name": "Cat", "plural": "Cats", "trait": "Prowl",
		"text": "Swift: it can attack the turn it's called"},
	"winged": {"name": "Winged", "plural": "Winged Totems", "trait": "Flight",
		"text": "it can strike your rival's Life over the Totem across from it (never past a Guardian)"},
	"scaled": {"name": "Scaled", "plural": "Scaled Totems", "trait": "Shed Skin",
		"text": "at your Dawn it heals 10 for each other Scaled Totem on your side"},
	"shell": {"name": "Shell", "plural": "Shells", "trait": "Hardened",
		"text": "takes 10 less from every attack"},
	"stoneborn": {"name": "Stoneborn", "plural": "Stoneborn", "trait": "Rockslide",
		"text": "its free Strike deals 20 more"},
}

## Every card's family, by card (an Ascension can change it: Sparkkit is a
## fox kit, Voltlynx a cat).
const FAMILY_OF := {
	"cinderpup": "hound", "blazehound": "hound", "infernal_warg": "hound",
	"shieldhound": "hound", "river_hound": "hound", "hallowed_hound": "hound",
	"sparkkit": "fox", "dreamfox": "fox", "veilfox": "fox", "ninefold_fox": "fox", "starling": "fox",
	"voltlynx": "cat", "tempest_lynx": "cat", "sunmane_lion": "cat", "duskstalker": "cat",
	"stormcaller": "winged", "somnowl": "winged", "runeowl": "winged", "lantern_moth": "winged",
	"dawnling": "winged", "bloomsprite": "winged",
	"brookfin": "scaled", "riptide_serpent": "scaled", "deepmaw": "scaled", "plague_asp": "scaled",
	"blight_wyrm": "scaled", "ashen_drake": "scaled", "hearth_salamander": "scaled",
	"shellguard": "shell", "brassback": "shell", "ironhide": "shell", "ironclad_behemoth": "shell",
	"pebblit": "stoneborn", "boulderox": "stoneborn", "cragmaul": "stoneborn",
	"quarry_golem": "stoneborn", "gilded_sentinel": "stoneborn",
}

const PACK_BONUS := 10          # Hounds: for each other Hound
const TRICKERY_FATE := 3        # Foxes
const SHED_HEAL := 10           # Scaled: for each other Scaled Totem, at Dawn
const HARDENED := 10            # Shells
const ROCKSLIDE := 20           # Stoneborn: on the free Strike


static func family_of(id: String) -> String:
	return String(FAMILY_OF.get(id, ""))


static func family_name(f: String) -> String:
	return String(FAMILIES.get(f, {}).get("name", ""))


static func family_plural(f: String) -> String:
	return String(FAMILIES.get(f, {}).get("plural", ""))


## "Kinship (Pack): with another Hound on your side, it deals 10 more for
## each other Hound on your side."
static func kinship_text(id: String) -> String:
	var f := family_of(id)
	if f == "":
		return ""
	var d: Dictionary = FAMILIES[f]
	var other := "another %s" % (String(d.name) if f != "winged" and f != "scaled" else "%s Totem" % d.name)
	return "%s (Kinship): with %s on your side, %s." % [d.trait, other, d.text]


## Every Totem card in a family, for the manual and the Codex.
static func members(f: String) -> Array:
	var out := []
	for id in FAMILY_OF:
		if FAMILY_OF[id] == f and DuelCards.CARDS.has(id):
			out.append(id)
	return out


# ============================================================ side by side ===

const SIDE_BONUS := 10          # each neighbour of the same element
const RALLY := 10               # a Rally Totem's neighbours deal this much more
const SHELTER := 10             # a Shelter Totem's neighbours take this much less
const TEND := 10                # a Tend Totem's neighbours heal this much at Dawn


## The slots beside `slot` (0 and 2 have one neighbour, 1 has two).
static func beside(slot: int) -> Array:
	var out := []
	for s in [slot - 1, slot + 1]:
		if s >= 0 and s < DuelRules.SLOTS:
			out.append(s)
	return out


# =============================================================== reactions ===

## A hit of `element` on a Totem with `status`: the first that matches is the
## one that happens. bonus: more damage; mult: the damage times this; then:
## the condition it's left with (the old one goes); clear: the condition is
## used up; splash: damage to each Totem beside it.
const REACTIONS := [
	{"id": "melt", "name": "Melt", "elements": ["fire"], "status": "frozen", "bonus": 20, "then": "soaked",
		"text": "Fire on a Frozen Totem: 20 more, and the ice melts. It's Soaked instead.", "color": "ff9a4a"},
	{"id": "shatter", "name": "Shatter", "elements": ["earth", "metal"], "status": "frozen", "mult": 2, "clear": true,
		"text": "Earth or Metal on a Frozen Totem: double damage, and the ice breaks.", "color": "bfe9ff"},
	{"id": "steam", "name": "Steam", "elements": ["tide"], "status": "burn", "bonus": 10, "then": "blinded",
		"text": "Tide on a Burned Totem: 10 more, the fire goes out in a cloud of steam, and it's Blinded.", "color": "e8f2f7"},
	{"id": "flare", "name": "Flare", "elements": ["fire"], "status": "poison", "bonus": 20, "clear": true,
		"text": "Fire on a Poisoned Totem: the poison catches. 20 more, and the poison burns away.", "color": "c6ff5a"},
	{"id": "conduct", "name": "Conduct", "elements": ["storm"], "status": "soaked", "splash": 20, "clear": true,
		"text": "Storm on a Soaked Totem: the lightning runs through the water, 20 to each Totem beside it.", "color": "ffe066"},
	{"id": "freeze", "name": "Freeze", "elements": ["frost"], "status": "soaked", "then": "frozen",
		"text": "Frost on a Soaked Totem: the water freezes, and so does the Totem.", "color": "9fe3ff"},
	{"id": "overgrow", "name": "Overgrow", "elements": ["verdant"], "status": "soaked", "then": "rooted",
		"text": "Verdant on a Soaked Totem: roots drink the water and hold it fast. It's Rooted.", "color": "7fc25a"},
	{"id": "firestorm", "name": "Firestorm", "elements": ["storm"], "status": "burn", "bonus": 20, "spread": "burn",
		"text": "Storm on a Burned Totem: the wind fans the fire. 20 more, and the Totems beside it catch.", "color": "ff7a2a"},
	{"id": "rend", "name": "Rend", "elements": ["metal"], "status": "bleed", "bonus": 20,
		"text": "Metal on a Bleeding Totem: steel finds the wound. 20 more.", "color": "e0454a"},
	{"id": "nightmare", "name": "Nightmare", "elements": ["psychic"], "status": "sleep", "bonus": 20, "then": "sleep",
		"text": "Psychic on an Asleep Totem: the blow comes as a bad dream. 20 more, and it doesn't wake.", "color": "b9a4ff"},
]


## The reaction a hit of `element` on `t` sets off ({} for none).
static func reaction_for(t: DuelTotem, element: String) -> Dictionary:
	if t == null or element == "" or element == "any":
		return {}
	for r in REACTIONS:
		if (r.elements as Array).has(element) and t.has_status(String(r.status)):
			return r
	return {}


## The damage after a reaction (before the defender's own shields).
static func react_amount(amount: int, r: Dictionary) -> int:
	if r.is_empty() or amount <= 0:
		return amount
	var a := amount
	if r.has("mult"):
		a *= int(r.mult)
	return a + int(r.get("bonus", 0))


static func reaction(id: String) -> Dictionary:
	for r in REACTIONS:
		if r.id == id:
			return r
	return {}


# ================================================================== chains ===

## The third card a duellist plays in a turn costs this much less.
const CHAIN_AT := 3
const CHAIN_DISCOUNT := 1
## A Combo Rite's extra damage or healing, played as the third card or later.
const COMBO_BONUS := 20


## What a card's Combo does, in words ("" if it has none).
static func combo_text(d: Dictionary) -> String:
	if not (d.get("keywords", []) as Array).has("combo"):
		return ""
	if d.get("kind", "") == "totem":
		return "Combo: called as the third card or later you've played this turn, it comes in Empowered."
	if int(d.get("damage", 0)) > 0:
		return "Combo: played as the third card or later this turn, it deals %d more." % COMBO_BONUS
	return "Combo: played as the third card or later this turn, it gives %d more." % COMBO_BONUS


# ================================================================ the gods ===

## Gods below the fourteen of the Turning, whose cards are in the game too:
## old, local, worshipped in a valley or a trade rather than a kingdom.
## (Not offered to swear to; Standing still keeps how they feel.)
const LESSER_GODS := {
	"ellowen": {"name": "Ellowen", "title": "the Lantern Keeper", "element": "spirit",
		"about": "Keeper of lanterns, roads home and the dead who walk them. Ashford's Lantern Festival is hers."},
	"orrun": {"name": "Orrun", "title": "the Stone Warden", "element": "earth",
		"about": "The old god of quarries, cairns and boundary stones. Miners leave him the first stone they cut."},
}

## The god each element answers to, unless the card says otherwise.
const ELEMENT_GOD := {
	"radiant": "solmaris", "fire": "pyrrhane", "frost": "vaelith", "storm": "ixara",
	"umbral": "nocthra", "psychic": "oriel", "mystic": "aldrith", "venom": "vexa",
	"verdant": "verdanthe", "tide": "maerith", "astral": "aster", "metal": "hethrin",
	"earth": "orrun", "spirit": "ellowen", "wind": "ixara",
}

## Cards whose god isn't their element's: the Unveiling Flame's own, and the
## element-less cards, each given to the god it belongs with.
const CARD_GOD := {
	# Ysolde, the Unveiling Flame: fire that shows what's hidden
	"emberwisp": "ysolde", "blinding_flare": "ysolde", "ashen_shroud": "ysolde", "goading_ember": "ysolde",
	# the cards of no element
	"essence_flask": "aldrith", "crystal_vein": "orrun", "healing_draught": "verdanthe",
	"travellers_pack": "ellowen", "seekers_compass": "aster", "lure_bell": "solmaris",
	"hunters_mark": "nocthra", "clarity_tonic": "oriel", "cleansing_bell": "solmaris",
	"war_paint": "pyrrhane", "sanctify": "solmaris", "hour_of_need": "ellowen",
	"rite_of_ashes": "pyrrhane", "kindred_seek": "ellowen", "unbind": "aldrith",
	"ambush_snare": "nocthra", "last_stand": "hethrin",
	"relic_hunt": "orrun", "pack_howl": "ellowen", "call_of_kin": "ellowen",
}

## Each god's rival: where one rules, the other's cards are Shunned.
const RIVALS := {
	"solmaris": "nocthra", "nocthra": "solmaris",
	"pyrrhane": "vaelith", "vaelith": "pyrrhane",
	"ixara": "orrun", "orrun": "ixara",
	"oriel": "aldrith", "aldrith": "oriel",
	"vexa": "verdanthe", "verdanthe": "vexa",
	"maerith": "ysolde", "ysolde": "maerith",
	"aster": "hethrin", "hethrin": "aster",
}

## Whose ground each Circle is (a duel under a god's Law is on that god's).
const ARENA_GOD := {
	"ashford": "ellowen", "solhaven": "solmaris", "tidegrove": "maerith",
	"emberforge": "pyrrhane", "ironstone": "hethrin", "veilwild": "nocthra",
}

## How far a god's feeling must go (Standing, -10 to 10) before its cards
## notice: "Pleased" (2 and up) graces them, "Displeased" (-2 and down)
## shuns them.
const PLEASED := 2
const DISPLEASED := -2
const GRACE_DAMAGE := 10        # a Graced Totem's attacks
const GRACE_COST := 1           # any other Graced card costs this much less


## The god a card answers to ("" for a card sent mid-duel, like Rallying Light).
static func god_of(id: String) -> String:
	if CARD_GOD.has(id):
		return String(CARD_GOD[id])
	var d: Dictionary = DuelCards.CARDS.get(id, {})
	if d.is_empty() or d.get("granted", false):
		return ""
	return String(ELEMENT_GOD.get(String(d.get("element", "")), ""))


static func is_god(g: String) -> bool:
	return Lore.GODS.has(g) or LESSER_GODS.has(g)


static func god_name(g: String) -> String:
	if Lore.GODS.has(g):
		return String(Lore.GODS[g].name)
	return String(LESSER_GODS.get(g, {}).get("name", g.capitalize()))


static func god_title(g: String) -> String:
	if Lore.GODS.has(g):
		return String(Lore.GODS[g].title)
	return String(LESSER_GODS.get(g, {}).get("title", ""))


static func rival_of(g: String) -> String:
	return String(RIVALS.get(g, ""))


## The god whose ground a duel is on: its Law's god, else its Circle's.
static func place_god(law: String, arena: String) -> String:
	if law != "" and is_god(law):
		return law
	return String(ARENA_GOD.get(arena, ""))


## +1 Graced, -1 Shunned, 0 neither: the place (its god's card +1, its
## god's rival's -1) and the duellist's standing with the card's god
## (Pleased +1, Displeased -1), held to one step either way.
static func grace(god: String, place: String, standing: Dictionary) -> int:
	if god == "":
		return 0
	var g := 0
	if place != "":
		if god == place:
			g += 1
		elif god == rival_of(place):
			g -= 1
	var s := int(standing.get(god, 0))
	if s >= PLEASED:
		g += 1
	elif s <= DISPLEASED:
		g -= 1
	return clampi(g, -1, 1)


## Why a card is Graced or Shunned, in a few words ("Ellowen's ground",
## "Solmaris is Pleased with you").
static func grace_why(god: String, place: String, standing: Dictionary, who := "you") -> String:
	var parts := []
	if place != "" and god == place:
		parts.append("%s's ground" % god_name(god))
	elif place != "" and god == rival_of(place):
		parts.append("%s's ground, %s's rival" % [god_name(place), god_name(god)])
	var s := int(standing.get(god, 0))
	if s >= PLEASED:
		parts.append("%s is Pleased with %s" % [god_name(god), who])
	elif s <= DISPLEASED:
		parts.append("%s is Displeased with %s" % [god_name(god), who])
	return ", and ".join(parts)


## A duellist's standing with the gods: what their profile carries (the duel
## screen fills the player's from Standing: story choices and their patron),
## else their patron's, Pleased. (Not Standing itself: the rules engine
## mustn't name the Game autoload, or a headless test won't compile.)
const PATRON_STANDING := 4

static func standing_for(profile: Dictionary) -> Dictionary:
	if profile.has("standing") and profile.standing is Dictionary:
		return (profile.standing as Dictionary).duplicate()
	var out := {}
	var patron := String(profile.get("patron", ""))
	if patron != "":
		out[patron] = PATRON_STANDING
	return out
