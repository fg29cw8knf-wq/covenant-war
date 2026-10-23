class_name DuelArchetypes
extends RefCounted
## Decks that play differently (Phase E of the deeper duel): each pair of
## elements has a named way of playing, with support cards that only work
## while a Totem of one of its elements stands on your side of the field
## (a card's "archetype"). The four starter decks are four of the ways; three
## more are for elements that have no deck of their own. The computer reads a
## deck's way and plays to it (DuelAI's plan). New cards reach the player as
## the story goes: after a won story duel one card they haven't met yet comes
## into their Codex (`glimpse`), the pool widening with each Seal.

const ARCHETYPES := {
	"burn_gamble": {"name": "Burn and Gamble", "elements": ["fire", "storm"], "deck": "emberstorm",
		"desc": "Set the rival's Totems burning and trust the dice: Burns that bite harder, Fate rolls that land higher.",
		"plan": {"aggro": 1.2, "fate": 1.3, "status": {"burn": 1.6, "shocked": 1.3}}},
	"outlast_heal": {"name": "Outlast and Heal", "elements": ["tide", "verdant"], "deck": "tidegrove",
		"desc": "Never quite fall: heal, shield, and let the rival tire first.",
		"plan": {"aggro": 0.85, "heal": 1.5, "guard": 1.3}},
	"guard_counter": {"name": "Guard and Counter", "elements": ["earth", "metal"], "deck": "ironstone",
		"desc": "A wall that hits back: Guard, answer the blow, and make every attack cost them.",
		"plan": {"aggro": 0.9, "guard": 1.6, "hold": true}},
	"veil_reveal": {"name": "Veil and Reveal", "elements": ["psychic", "venom"], "deck": "veilwild",
		"desc": "Nothing is what it looks like: call face down and spring the Reveal when it hurts most.",
		"plan": {"aggro": 1.0, "veil": 1.6, "status": {"poison": 1.3, "sleep": 1.3}, "hold": true}},
	"dawn_blessing": {"name": "Dawn and Blessing", "elements": ["radiant", "spirit"], "deck": "",
		"desc": "The light keeps its own: Blessed Totems, fallen ones called back, Life for every loss.",
		"plan": {"aggro": 0.95, "boon": 1.5, "revive": 1.4, "heal": 1.2}},
	"frost_stillness": {"name": "Frost and Stillness", "elements": ["frost", "mystic"], "deck": "",
		"desc": "Freeze it, silence it, then break it while it can't move.",
		"plan": {"aggro": 0.9, "status": {"frozen": 1.6, "silenced": 1.4, "stun": 1.3}, "hold": true}},
	"stars_shadow": {"name": "Stars and Shadow", "elements": ["astral", "umbral"], "deck": "",
		"desc": "Read the stars, darken the rival's: your Fate rises while theirs falls.",
		"plan": {"aggro": 1.1, "fate": 1.3, "status": {"blinded": 1.4}}},
}

## A sample deck for each way, for the Duel Lab and the balance tests (never
## offered as a starter: the story gives Bram four boxes).
const DECKS := {
	"way_burn_gamble": {"name": "Emberstorm, its way", "archetype": "burn_gamble", "elements": ["fire", "storm"], "mascot": "cinderpup",
		"desc": "The Emberstorm starter with its way's three cards.",
		"attributes": {"might": 2, "swiftness": 2},
		"cards": {"cinderpup": 3, "blazehound": 2, "emberwisp": 3, "hearth_salamander": 2, "ashen_drake": 1,
			"sparkkit": 3, "voltlynx": 2, "thunder_ram": 2, "stormcaller": 1,
			"ember_collar": 1, "firebrand": 1, "rite_of_ashes": 1, "stoke_the_coals": 1, "loaded_dice": 1, "wildfire_pact": 1,
			"forge_ground": 1, "kindled_banner": 1, "ambush_snare": 1, "infernal_warg": 1, "pyraxis": 1}},
	"way_outlast_heal": {"name": "Tidegrove, its way", "archetype": "outlast_heal", "elements": ["tide", "verdant"], "mascot": "brookfin",
		"desc": "The Tidegrove starter with its way's three cards.",
		"attributes": {"resolve": 2, "insight": 2},
		"cards": {"brookfin": 3, "riptide_serpent": 2, "deepmaw": 1, "shellguard": 2,
			"mossling": 3, "thornwarden": 2, "bloomsprite": 3, "elderbark": 1,
			"healing_draught": 1, "rejuvenate": 1, "second_dawn": 1, "deep_roots": 1, "tidal_reserve": 1, "still_waters": 1,
			"flooded_circle": 1, "thorn_hedge": 1,
			"riptide_snare": 1, "vengeful_spirit": 1, "thalassa": 1, "tide_pearl": 1, "undertow_glyph": 1}},
	"way_guard_counter": {"name": "Ironstone, its way", "archetype": "guard_counter", "elements": ["earth", "metal"], "mascot": "pebblit",
		"desc": "The Ironstone starter with its way's three cards.",
		"attributes": {"might": 2, "resolve": 2},
		"cards": {"pebblit": 3, "boulderox": 2, "burrowmole": 3, "quarry_golem": 1,
			"brassback": 3, "ironhide": 2, "shieldhound": 3, "gilded_sentinel": 1,
			"bulwark": 1, "healing_draught": 1, "counterweight": 1, "stone_patience": 1, "bastion_banner": 1, "shieldwall_call": 1, "iron_tithe": 1,
			"iron_bastion": 2, "ironclad_behemoth": 1, "grondmaw": 1, "iron_brace": 1}},
	"way_veil_reveal": {"name": "Veilwild, its way", "archetype": "veil_reveal", "elements": ["psychic", "venom"], "mascot": "dreamfox",
		"desc": "The Veilwild starter with its way's three cards.",
		"attributes": {"cunning": 2, "insight": 2},
		"cards": {"dreamfox": 3, "veilfox": 2, "somnowl": 2, "thought_eater": 1,
			"blightrat": 3, "plague_asp": 2, "mirewidow": 3,
			"mind_fog": 1, "kindred_seek": 1, "unmasking": 1, "whispering_shroud": 1, "venom_mask": 1, "shadow_veil": 1, "veilwild_mist": 1,
			"mirror_veil": 2, "ninefold_fox": 1, "poison_trap": 1, "somnara": 1,
			"whisper_of_pages": 1, "veil_charm": 1}},
	"way_dawn_blessing": {"name": "Dawn and Blessing", "archetype": "dawn_blessing", "elements": ["radiant", "spirit"], "mascot": "dawnling",
		"desc": "Radiant and Spirit: Blessings, Totems called back from the fallen, Life for every loss. Suits Presence and Resolve.",
		"attributes": {"presence": 2, "resolve": 2},
		"cards": {"dawnling": 3, "hallowed_hound": 3, "lantern_moth": 3, "sunmane_lion": 1, "sunlance_seraph": 1,
			"second_dawn": 2, "sunward_vow": 2, "lantern_vigil": 1, "kindled_soul": 1, "sun_medallion": 1, "spirit_lantern": 1,
			"healing_draught": 2, "sanctify": 2, "grave_curse": 2, "vengeful_spirit": 2, "essence_flask": 2, "sunlit_court": 1}},
	"way_frost_stillness": {"name": "Frost and Stillness", "archetype": "frost_stillness", "elements": ["frost", "mystic"], "mascot": "rimecub",
		"desc": "Frost and Mystic: freeze, silence, then break what can't move. Suits Resolve and Intellect.",
		"attributes": {"resolve": 2, "intellect": 2},
		"cards": {"rimecub": 3, "runeowl": 3, "brookfin": 3, "riptide_serpent": 2, "pebblit": 3, "boulderox": 1, "quarry_golem": 1,
			"deep_winter": 1, "shatter": 2, "glacial_ward": 2, "frostbind": 2, "frost_snare": 2, "silence_rune": 1,
			"null_sigil": 1, "healing_draught": 1, "essence_flask": 1, "ambush_snare": 1}},
	"way_stars_shadow": {"name": "Stars and Shadow", "archetype": "stars_shadow", "elements": ["astral", "umbral"], "mascot": "starling",
		"desc": "Astral and Umbral: lucky stars for you, a darker sky for them. Suits Insight and Cunning.",
		"attributes": {"insight": 2, "cunning": 2},
		"cards": {"starling": 3, "duskstalker": 3, "sparkkit": 3, "voltlynx": 2, "dreamfox": 3, "thought_eater": 1,
			"constellation": 2, "eclipse": 1, "shadow_step": 2, "hunters_mark": 2, "seekers_compass": 1,
			"essence_flask": 2, "mind_fog": 2, "ambush_snare": 2, "kindred_seek": 1}},
}

## The cards the story hands out, by the chapter they open in (a chapter is
## one more than the Seals won): the deeper duel's cards that no starter deck
## carries, each way's support cards, and the new ways' Totems.
const POOLS := {
	1: ["null_sigil", "ashen_shroud", "shieldwall_call", "undertow_glyph", "quicksilver_step", "root_toll", "whisper_of_pages", "rune_break",
		"lightning_reflex", "hushed_counter", "hour_of_need", "second_dawn", "rekindle", "rite_of_ashes", "kindred_seek", "memory_thread",
		"ember_collar", "tide_pearl", "iron_brace", "thorn_crown", "storm_feather", "veil_charm", "sun_medallion", "hunters_fang",
		"stone_heart", "spirit_lantern", "relic_hunt",
		"flooded_circle", "forge_ground", "iron_ground", "veilwild_mist", "sunlit_court",
		"kindled_banner", "tidewell", "iron_tithe", "thorn_hedge", "storm_spire", "shadow_veil", "unbind",
		"stoke_the_coals", "loaded_dice", "wildfire_pact", "deep_roots", "tidal_reserve", "still_waters",
		"counterweight", "stone_patience", "bastion_banner", "unmasking", "whispering_shroud", "venom_mask"],
	2: ["dawnling", "hallowed_hound", "sunward_vow", "lantern_vigil", "kindled_soul",
		"rimecub", "runeowl", "deep_winter", "shatter", "glacial_ward"],
	3: ["starling", "duskstalker", "constellation", "eclipse", "shadow_step"],
}


static func ids() -> Array:
	return ARCHETYPES.keys()


static func arch_name(id: String) -> String:
	return String(ARCHETYPES.get(id, {}).get("name", ""))


## "a Fire or Storm Totem": what a way's support card needs on the field.
static func need_text(id: String) -> String:
	var els: Array = ARCHETYPES.get(id, {}).get("elements", [])
	var names := []
	for e in els:
		names.append(String(e).capitalize())
	return "a %s Totem" % " or ".join(names)


## Whether `pi` has a Totem of the way's elements standing on their side.
static func has_need(game: DuelGame, pi: int, id: String) -> bool:
	var els: Array = ARCHETYPES.get(id, {}).get("elements", [])
	for t in game.players[pi].totems():
		if els.has((t as DuelTotem).element()):
			return true
	return false


## The way a list of card ids leans to: the one whose two elements its Totems
## have most of ("" if it has no Totems).
static func of_cards(card_ids: Array) -> String:
	var tally := {}
	for id in card_ids:
		var d: Dictionary = DuelCards.CARDS.get(String(id), {})
		if d.get("kind", "") != "totem":
			continue
		var el := String(d.get("element", ""))
		tally[el] = int(tally.get(el, 0)) + 1
	var best := ""
	var best_n := 0
	for a in ARCHETYPES:
		var n := 0
		for e in ARCHETYPES[a].elements:
			n += int(tally.get(e, 0))
		if n > best_n:
			best_n = n
			best = a
	return best


## The way of a duellist's cards in this duel (all of them, wherever they are).
static func of_player(p: DuelPlayer) -> String:
	var all := []
	for c in p.deck + p.hand + p.discard:
		all.append((c as DuelCard).id)
	for t in p.totems():
		for c in (t as DuelTotem).stack:
			all.append((c as DuelCard).id)
	return of_cards(all)


static func plan(id: String) -> Dictionary:
	return ARCHETYPES.get(id, {}).get("plan", {})


static func chapter_of(id: String) -> int:
	for ch in POOLS:
		if (POOLS[ch] as Array).has(id):
			return int(ch)
	return 0


## After a won story duel: one card from the pools (this chapter's and the
## ones before) that the player hasn't met, for their Codex, if one answers
## their Rank; "" when there's none. `rng` picks among them.
static func glimpse(codex: Dictionary, chapter: int, rank: int, rng: RandomNumberGenerator) -> String:
	var opts := []
	for ch in POOLS:
		if int(ch) > chapter:
			continue
		for id in POOLS[ch]:
			if codex.has(id) or not DuelCards.CARDS.has(id):
				continue
			if int(DuelCards.CARDS[id].get("tier", 1)) > DuelRewards.tier_cap(rank):
				continue
			opts.append(id)
	if opts.is_empty():
		return ""
	return String(opts[rng.randi_range(0, opts.size() - 1)])
