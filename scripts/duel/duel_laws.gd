class_name DuelLaws
extends RefCounted
## Dominion Laws ("Duel Rules v2"): every duel fought in a god's kingdom
## follows that god's Law, and duellists sworn to that god also get its
## Blessing. A game's `law` is the god's id, "ironvault", or "" for none
## (the Shardlands, the Convocation, and ordinary PvP).

const LAWS := {
	"solmaris": {"name": "Dawnlight", "place": "Solhaven",
		"law": "At each Dawn, your most damaged Totem heals %d.",
		"blessing": "It heals %d instead."},
	"pyrrhane": {"name": "Forge Heat", "place": "Pyreholt",
		"law": "Fire cards cost 1 less Essence, and every Totem takes %d damage at its owner's Dusk.",
		"blessing": "Your Fire Totems ignore the heat."},
	"vexa": {"name": "Plague Air", "place": "Pyreholt",
		"law": "Poison deals %d at each Dawn instead of %d.",
		"blessing": "Your Totems can't be Poisoned."},
	"vaelith": {"name": "Long Winter", "place": "Hrimmark",
		"law": "A sleeping Totem wakes only on %d or more, and Shifting costs 1 more.",
		"blessing": "Your Totems wake on %d or more, as usual."},
	"verdanthe": {"name": "Green Spring", "place": "Hrimmark",
		"law": "Verdant cards cost 1 less, and healing Rites heal %d more.",
		"blessing": "Your Totems enter with +%d HP."},
	"ixara": {"name": "Open Sky", "place": "Stormreach",
		"law": "Shifting is free for everyone.",
		"blessing": "You can Shift one more time each turn."},
	"maerith": {"name": "High Tide", "place": "Stormreach",
		"law": "At Dawn, a duellist with fewer Totems than their opponent draws an extra card.",
		"blessing": "You draw it even when the Totems are level."},
	"oriel": {"name": "Prophecy", "place": "Somnara",
		"law": "At Dawn, each duellist sees their top card and may send it to the bottom.",
		"blessing": "You see your opponent's top card too."},
	"aster": {"name": "Starfall", "place": "Somnara",
		"law": "Every Fate roll gets +1.",
		"blessing": "Your natural 19 counts as a 20."},
	"aldrith": {"name": "Runebound", "place": "Glyphmere",
		"law": "Rites cost 1 less.",
		"blessing": "Once a duel, at your Dawn, return a Rite from your discard pile to your hand."},
	"hethrin": {"name": "Ironworks", "place": "Glyphmere",
		"law": "Metal cards cost 1 less, and Wards cost 1 more.",
		"blessing": "Your Guard is +%d."},
	"nocthra": {"name": "Veiled Circle", "place": "Umbravel",
		"law": "Every duellist gets a third Ward slot.",
		"blessing": "Gifts can't reveal or destroy your Wards."},
	"ysolde": {"name": "Unveiling", "place": "Umbravel",
		"law": "Every Ward is set face up.",
		"blessing": "Your own Wards stay face down."},
	"ironvault": {"name": "Ledger Law", "place": "Ironvault",
		"law": "No Divine Gift can be used.",
		"blessing": ""},
}

# --- the numbers -------------------------------------------------------------
static var dawnlight_heal := 10
static var dawnlight_blessed_heal := 15
static var forge_heat := 5
static var plague_poison := 15
static var winter_wake := 15
static var spring_heal_bonus := 10
static var spring_hp_bonus := 5
static var ironworks_guard := 3


static func ids() -> Array:
	return LAWS.keys()


static func law_name(id: String) -> String:
	return LAWS.get(id, {}).get("name", "No Law")


static func describe(id: String) -> String:
	if not LAWS.has(id):
		return ""
	var t: String = LAWS[id].law
	match id:
		"solmaris": t = t % dawnlight_heal
		"pyrrhane": t = t % forge_heat
		"vexa": t = t % [plague_poison, DuelRules.poison_damage]
		"vaelith": t = t % winter_wake
		"verdanthe": t = t % spring_heal_bonus
	return t


static func describe_blessing(id: String) -> String:
	if not LAWS.has(id):
		return ""
	var t: String = LAWS[id].blessing
	match id:
		"solmaris": t = t % dawnlight_blessed_heal
		"vaelith": t = t % DuelRules.wake_roll
		"verdanthe": t = t % spring_hp_bonus
		"hethrin": t = t % ironworks_guard
	return t
