class_name Items
extends RefCounted
## Things the player carries: story items (handed over by the story and shown
## from its flags) and equipment (charms worn in three slots, each lifting an
## attribute, which counts in every duel).
##
## No equipment is placed in the story yet: when the script decides where a
## charm is found (a god's quest reward is the natural place), the story gives
## it with {"item": "<id>"} and it appears here, ready to wear.

const SLOTS := ["charm", "ring", "case"]
const SLOT_NAMES := {"charm": "Charm", "ring": "Ring", "case": "Deck case"}
const SLOT_HINTS := {
	"charm": "Worn at the throat. Lifts one attribute.",
	"ring": "Worn on the marked hand. Lifts one attribute.",
	"case": "Holds your deck. Lifts one attribute.",
}
## The most an attribute can reach with equipment on.
const ATTRIBUTE_CAP := 10

const ITEMS := {
	# ---- story items: shown while their flag is set -------------------------------
	"blank_sigil": {"kind": "story", "name": "The Blank Sigil", "flag": "ash_marked",
		"text": "A card with nothing on it, warm as a heartbeat. It fell to you at midnight in Ashford and burned its mark into your hand. Bram has never seen one like it. Plenty of people want it."},
	"bram_deck": {"kind": "story", "name": "Bram's old deck", "flag": "bram_deck",
		"text": "One of the four decks Bram duelled with for thirty years, carried up from the cellar of the Crooked Lantern the night Ashford burned."},
	"dask_deck": {"kind": "story", "name": "Hunter Dask's deck", "flag": "beat_hunter",
		"text": "Thirty cards of hounds, traps and poison, won from Hunter Dask by sworn wager on the road to Solhaven."},
	"ironvault_seal": {"kind": "story", "name": "Ironvault wax seal", "flag": "beat_wren",
		"text": "A coin crossed with a key. Wren's proof of the ten-thousand-crown price on a blank Sigil and the hand that holds it."},
	# Solhaven's side stories (scripts/world/areas/solhaven/solhaven_side.gd)
	"maren_pages": {"kind": "story", "name": "Maren's forty pages", "flag": "maren_pages",
		"text": "The Great Sundial's old readings, copied in a neat Temple hand the week before the Temple threw Old Maren out. Thirty years in her bread tin. She asked you to send for her when it's time."},
	"pell_note": {"kind": "story", "name": "Mr Pell's note", "flag": "pell_note",
		"text": "To His Grace the Hierarch: Ironvault acknowledges a further three thousand crowns drawn against the Temple roofs, for the Bread of Dawn. Interest as before. Pip never got his two crowns for it."},
	# ---- equipment (not yet given anywhere in the story) ---------------------------
	"hearth_charm": {"kind": "gear", "slot": "charm", "name": "Hearthstone Charm", "bonus": {"resolve": 1},
		"text": "A smooth stone from a village hearth, still faintly warm."},
	"gale_ring": {"kind": "gear", "slot": "ring", "name": "Gale-Tooth Ring", "bonus": {"swiftness": 1},
		"text": "A ring cut from a storm-hawk's tooth. Your hand moves before you've decided to."},
	"vault_case": {"kind": "gear", "slot": "case", "name": "Ironvault Deck Case", "bonus": {"cunning": 1},
		"text": "Brass-bound, with a false bottom nobody has ever found."},
}


static func is_gear(id: String) -> bool:
	return String(ITEMS.get(id, {}).get("kind", "")) == "gear"


## Story items the player holds right now.
static func story_items() -> Array:
	var out := []
	for id in ITEMS:
		var d: Dictionary = ITEMS[id]
		if d.kind == "story" and Game.flag(d.flag):
			out.append(id)
	return out


## Equipment the player owns, worn or not.
static func gear_owned() -> Array:
	var out := []
	for id in Game.items:
		if is_gear(id) and int(Game.items[id]) > 0:
			out.append(id)
	return out


## What everything worn adds, attribute by attribute.
static func gear_bonus(equipped: Dictionary) -> Dictionary:
	var out := {}
	for slot in equipped:
		var d: Dictionary = ITEMS.get(String(equipped[slot]), {})
		for a in d.get("bonus", {}):
			out[a] = int(out.get(a, 0)) + int(d.bonus[a])
	return out


static func bonus_text(id: String) -> String:
	var parts := []
	var b: Dictionary = ITEMS.get(id, {}).get("bonus", {})
	for a in b:
		parts.append("%+d %s" % [int(b[a]), Lore.ATTRIBUTE_NAMES.get(a, a)])
	return ", ".join(parts)
