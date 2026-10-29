extends RefCounted
## Chapter 1's story duels (Master Script v3, Solhaven), each with the rule of
## its own that says who is across the Circle, as a real rule in the duel
## engine (DuelGame.story_rules), its barks tied to the board (spec.bark_on)
## and, for the main story's duels, the story-duel loss (spec.retry: their
## line for winning, Morrowen's, then Again / Change deck first).
##
##   The Gate      Warden Hale · The Gate Watch     Hold the Gate (half Life)
##   The Alley     Wren · Pickpocket                Light Fingers
##   The Trial of Light (Liora's mirrors)           a set board: win in three turns
##   The Trial     Ser Aldric Vane · The Golden Oath   The Sunspire's Mirror
##
## Loaded by path (it travels in the web build's Solhaven pack):
##   const Duels := preload("res://scripts/world/solhaven/duels.gd")

const HOLD_THE_GATE := ["Hold the Gate", "While Hale's Guardian stands, he never attacks your Life; he's there to hold, not to win."]
const LIGHT_FINGERS := ["Light Fingers", "Once per duel, Wren takes a card from your hand and plays it as her own."]
const SUNSPIRE_MIRROR := ["The Sunspire's Mirror", "At half Life, the great mirror swings to Aldric's side and his Radiant cards cost one less for the rest of the duel."]
const TRIAL_OF_LIGHT := ["The Trial of Light", "The mirrors set the board. Win within three turns; a mistake resets it."]


## The deck the player duels with: the one they've built, else their starter.
static func player_deck() -> Array:
	var deck: Array = Game.v2.get("deck", [])
	if deck.is_empty():
		var me: String = Game.starter if DuelCards.DECKS.has(Game.starter) else "emberstorm"
		deck = DuelCards.card_list(me)
	return deck.duplicate()


## DUEL · The Gate. A short duel: both sides start at half Life, because it's
## a test, not a fight. Bram's first-time lines introduce Guardians and Divine
## Gifts (Hale is the Goddess's: Dawn's Mercy).
static func hale_spec() -> Dictionary:
	var hale := Lore.new_profile("Warden Hale", "solmaris", 3)
	Lore.add_attribute(hale, "resolve", 1)
	return {
		"decks": [player_deck(), DuelCards.card_list("gate_watch")],
		"names": [Game.player_name, "Warden Hale"],
		"profiles": [Game.profile, hale],
		"ai": [false, true],
		"difficulty": 0.5,
		"arena": "solhaven",
		"music": [],
		"story": true,
		"retry": true,
		"lessons": true,
		"life_scale": 0.5,
		"story_rules": {"hold_the_gate": 1},
		"rule": HOLD_THE_GATE,
		"bark_on": {
			# 28 October (synergy)
			"rival_kin": "Shoulder to shoulder. That's how a gate holds.",
			"rival_graced": "The Sun keeps her own in Solhaven. You'll feel it.",
			"my_shunned": "Shadow cards in the Sun's own city? They'll not burn bright here.",
			"rival_guardian_hit": "Hold.",
			"rival_gift": "Her mercy. Freely given, to them as kneel.",
			"rival_guardian_ko": "Hm.",
		},
		"win_line": "The gate stands.",
		"rewards": {"opponent": "kingdom"},
		"title": "The Gate · Warden Hale",
	}


## DUEL · The Alley. Light Fingers: once a duel Wren takes a card from your
## hand and plays it as her own. Bram watches from the alley mouth; his
## first-time lines introduce Ascension and hand disruption.
static func wren_spec() -> Dictionary:
	var wren := Lore.new_profile("Wren", "", 3)
	Lore.add_attribute(wren, "cunning", 2)
	Lore.add_attribute(wren, "swiftness", 1)
	return {
		"decks": [player_deck(), DuelCards.card_list("pickpocket")],
		"names": [Game.player_name, "Wren"],
		"profiles": [Game.profile, wren],
		"ai": [false, true],
		"difficulty": 0.6,
		"arena": "solhaven",
		"music": [],
		"story": true,
		"retry": true,
		"lessons": true,
		"story_rules": {"light_fingers": 1},
		"rule": LIGHT_FINGERS,
		"bark_on": {
			# 28 October (synergy)
			"rival_chain": "Quick hands, Unsworn. One, two, three, gone.",
			"my_chain": "Oh, you've got rhythm. I like that.",
			"rival_steals": "Let's see what you're hiding. I'll have that one.",
			"rival_kos_mine": "Nice card. Shame about it.",
			"my_lead": "You're getting better. Stop it.",
		},
		"win_line": "Dinner's on you. Somewhere with tablecloths.",
		"rewards": {"opponent": "rival"},
		"title": "The Alley · Wren",
	}


## DUEL · The Trial. The Sunspire's Mirror: at half Life the great mirror
## swings to Aldric's side and his Radiant cards cost one less; Dawnmane,
## kept back for when he's losing, comes out (the crowd names it). The first
## time your Life drops below a third the blank card shows the seal.
static func aldric_spec() -> Dictionary:
	var aldric := Lore.new_profile("Ser Aldric Vane", "solmaris", 4)
	Lore.add_attribute(aldric, "presence", 2)
	Lore.add_attribute(aldric, "resolve", 1)
	return {
		"decks": [player_deck(), DuelCards.card_list("golden_oath")],
		"names": [Game.player_name, "Ser Aldric Vane"],
		"profiles": [Game.profile, aldric],
		"ai": [false, true],
		"difficulty": 0.8,
		"arena": "solhaven",
		"music": ["arena_solhaven"],
		"story": true,
		"retry": true,
		"story_rules": {"sunspire_mirror": 1},
		"kept_back": [[], ["dawnmane"]],
		"rule": SUNSPIRE_MIRROR,
		"mirror_text": "The great mirror swings on its chains and puts the sun on Aldric's side of the Circle. His Radiant cards cost one less for the rest of the duel.",
		"bark_on": {
			# 28 October (synergy)
			"rival_graced": "Solmaris keeps her own, up here on the Sunspire.",
			"my_shunned": "The Veiled Mother's cards, on the Sunspire? Bold.",
			"rival_kin": "The Sun's hounds run together. They always have.",
			"rival_guardian_hit": "Hold, Sentinel.",
			"my_big_hit": "A good strike. Here's mine.",
			"rival_summons": "I've never once had to wake you.",
			"rival_life_third": "Goddess, guide my hand.",
		},
		"crowd_on": {"rival_summons": "DAWNMANE!"},
		"blank_eye": true,
		# the Pale Herald at the Circle's edge (its hood turns at the blank card)
		"herald_at": Vector3(6.3, 0, -2.9),
		"herald_scale": 0.85,
		"win_line": "Well fought. Solhaven keeps its knight.",
		"rewards": {"opponent": "champion"},
		"title": "The Trial · Ser Aldric Vane",
	}


# ===================================================== the Trial of Light ===
# The mirrors set the board, and the player has three turns to win; a mistake
# resets it. Each of Bram's four decks gets its own board, built round its
# Summon, which the mirrors put in the player's hand: it costs everything they
# have, and their Essence doesn't grow in the Hall of Mirrors. Called down on
# the first turn (when nothing can attack anyway) it opens the way and leaves
# both later turns for the Totems' paid moves; held back, it eats one of them
# and the board can't be won. The mirrors only watch.
# tests/trial_puzzle_test.gd plays each board's answer, and thousands of other
# lines, to keep it so.

## The board for each deck. "board": the player's Totems (slots 0, 1, 2) and
## the mirrors'; "decoy": a cheap Ward that looks like a sensible first play;
## "life": the mirrors' Life.
const TRIALS := {
	"emberstorm": {
		"summon": "pyraxis", "decoy": "ambush_snare", "life": 150,
		"mine": ["hearth_salamander", null, "thunder_ram"],
		"mirrors": ["brassback", "brassback", "brassback"],
	},
	"tidegrove": {
		"summon": "thalassa", "decoy": "vengeful_spirit", "life": 260,
		"mine": [["brookfin", "riptide_serpent"], null, ["mossling", "thornwarden"]],
		"mirrors": ["pebblit", "brassback", "pebblit"],
	},
	"ironstone": {
		"summon": "grondmaw", "decoy": "iron_bastion", "life": 300,
		"mine": [["pebblit", "boulderox"], null, "quarry_golem"],
		"mirrors": [null, "gilded_sentinel", null],
	},
	"veilwild": {
		"summon": "somnara", "decoy": "poison_trap", "life": 110,
		"mine": [["dreamfox", "veilfox"], null, "thought_eater"],
		"mirrors": ["brassback", "blightrat", "brassback"],
	},
}
const TRIAL_TURNS := 3


## Which board: the deck the player chose from Bram's four (its Summon).
static func trial_deck() -> String:
	var d := str(Game.flag("bram_deck", ""))
	if not TRIALS.has(d):
		d = Game.starter
	return d if TRIALS.has(d) else "emberstorm"


## The set board itself, as DuelGame.puzzle takes it.
static func trial_puzzle(deck_id: String) -> Dictionary:
	var t: Dictionary = TRIALS.get(deck_id, TRIALS.emberstorm)
	var summon_cost := int(DuelCards.CARDS[t.summon].cost)
	return {
		"first": 0,
		"turns": TRIAL_TURNS,
		"life": [100, int(t.life)],
		# Essence is exactly the Summon's cost, every turn
		"essence_max": [summon_cost, 0],
		"essence_fixed": [true, false],
		"board": [t.mine, t.mirrors],
		"hand": [[t.summon, t.decoy], []],
		"deck": [["healing_draught", "healing_draught", "healing_draught"], ["essence_flask", "essence_flask", "essence_flask"]],
		"log": "The mirrors set the board.",
	}


## The duel spec for the Trial of Light. The player's side is played with a
## plain profile (the mirrors set everything), and the Trial can't be lost:
## a mistake and the mirrors begin again, with Liora's line.
static func trial_spec(deck_id: String = "") -> Dictionary:
	if deck_id == "":
		deck_id = trial_deck()
	var t: Dictionary = TRIALS.get(deck_id, TRIALS.emberstorm)
	var me := Lore.new_profile(Game.player_name, "", 3)
	var mirrors := Lore.new_profile("The Mirrors", "solmaris", 0)
	return {
		"decks": [[t.summon, t.decoy], ["essence_flask"]],
		"names": [Game.player_name, "The Mirrors"],
		"profiles": [me, mirrors],
		"ai": [false, true],
		"difficulty": 1.0,
		"arena": "solhaven",
		"music": [],
		"story": true,
		"trial": true,
		"puzzle": trial_puzzle(deck_id),
		"story_rules": {"mirror_trial": 1},
		"rule": TRIAL_OF_LIGHT,
		"bark_who": "Liora",
		# when you Summon, every mirror shows the Demigod at once
		"mirrors_show": true,
		"bark_on": {
			"my_summons": "Oh.",
		},
		"reset_lines": [
			"Again. The mirrors don't mind.",
			"Some pilgrims start with the biggest thing they have. Some never do.",
		],
		"blank_card": false,
		"rewards": {"opponent": "village", "thick": true},
		"title": "The Trial of Light",
	}
