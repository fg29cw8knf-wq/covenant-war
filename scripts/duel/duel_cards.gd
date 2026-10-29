class_name DuelCards
extends RefCounted
## Every card for the new duel rules (see DuelRules and the "Duel Rules v1"
## page), the starter decks, and the words printed on each card.
##
## kind:      totem, rite, ward, summon
## cost:      Essence to call a Totem / cast a Rite / set a Ward / call a Summon.
##            For an Ascended Totem this is the cost to Ascend.
## stage:     0 = Basic, 1 = Ascended, 2 = Exalted (played on `ascends_from`)
## affinity:  the attribute this card draws on (Fate rolls and Attuned bonus)
## attuned:   {min, damage | hp | cost | keyword | draw} bonus once the
##            duellist's affinity attribute is at least `min`
## keywords:  guardian, swift, channel, thorns, harvest, burrow
## moves:     [0] is the free Strike; the rest cost Essence. Each move:
##              damage, cost, target (foe | foe_totem | ally | none | all_foes),
##              effects [...], fate [{to, damage, effects, text}] (a d20 roll)
## art:       the subject for AI art; the file goes in
##            assets/art/cards/<card id>.png (see docs/art-prompts.md)
## answer:    a Rite played only on the rival's turn, in answer to what they
##            do: "answers" names the events (attack, rite, call, ward,
##            ward_spring), the effects are negate, halve, redirect_guardian,
##            bounce_rite, sidestep, essence, essence_next, draw, cancel_ward
##            (Phase A of the deeper duel, 23 October)
## from_hand: a Ward that can also be played from the hand in answer to its
##            trigger, once a duel
## echo:      {when: "ally_falls", op, amount | status}: a Totem card that acts
##            from its owner's discard once a duel when another of their
##            Totems falls (Phase B: damage_attacker, status_attacker,
##            heal_weakest, shield_one, essence_next)
## needs_ashes: a Rite that only works with this many Totem cards of one
##            element in its caster's discard
## bond:      see BONDS: two Totems (by their Basic) that stand together
##            gain a bond move or a stat (Phase C)
## relic:     a card kind (Phase C): given to a Totem of yours (one each),
##            it stays until the Totem falls: "relic": {hp | damage |
##            keyword | dawn_heal | dawn_shield | move | fall_draw}
## reveal:    {op: status_across | damage_across | draw | heal_allies}: what a
##            Totem does when it's turned face up after a veiled call
## stand_in:  a Totem with no model or painting yet is shown as this one
## A Basic Totem of tier 3 and up costs one of its caller's Totems on the
## field as well as its Essence (tier 5 and up, two): a Tribute (Phase B).

const CARDS := {
	# =================================================================== FIRE
	"cinderpup": {
		"kind": "totem", "name": "Cinderpup", "element": "fire", "tier": 1, "stage": 0, "cost": 1,
		"keywords": ["echo"], "echo": {"when": "ally_falls", "op": "damage_attacker", "amount": 10},
		"hp": 70, "affinity": "might", "attuned": {"min": 5, "damage": 10},
		"moves": [
			{"name": "Nip", "cost": 0, "damage": 10},
			{"name": "Reckless Bite", "cost": 1, "damage": 0, "fate": [
				{"to": 1, "damage": 0, "text": "Miss"},
				{"to": 9, "damage": 20},
				{"to": 19, "damage": 40},
				{"to": 99, "damage": 70, "effects": [{"op": "status", "status": "burn"}]}]},
		],
		"art": "a small fox-like pup made of glowing embers, a flickering flame for a tail, bright amber eyes, playful crouch",
	},
	"blazehound": {
		"kind": "totem", "name": "Blazehound", "element": "fire", "tier": 2, "stage": 1,
		"ascends_from": "cinderpup", "cost": 2, "hp": 120, "affinity": "might",
		"attuned": {"min": 5, "damage": 10}, "keywords": ["harvest"],
		"moves": [
			{"name": "Flame Fang", "cost": 0, "damage": 30},
			{"name": "Inferno Rush", "cost": 2, "damage": 50, "effects": [{"op": "status", "status": "burn"}]},
		],
		"art": "a lean wolfhound wreathed in roaring flame, a mane of fire, molten cracks along its body, lunging forward",
	},
	"emberwisp": {
		"kind": "totem", "name": "Emberwisp", "element": "fire", "tier": 1, "stage": 0, "cost": 1,
		"reveal": {"op": "damage_across", "amount": 20},
		"hp": 50, "affinity": "swiftness", "keywords": ["reveal", "swift", "rally"], "attuned": {"min": 5, "damage": 10},
		"moves": [
			{"name": "Spark", "cost": 0, "damage": 10},
			{"name": "Kindle", "cost": 1, "damage": 10, "target": "foe_totem",
				"effects": [{"op": "status", "status": "burn"}]},
		],
		"art": "a tiny floating spark spirit with a candle-flame body, wide curious eyes, trailing glowing cinders",
	},
	"hearth_salamander": {
		"kind": "totem", "name": "Hearth Salamander", "element": "fire", "tier": 1, "stage": 0, "cost": 2,
		"hp": 80, "affinity": "presence", "keywords": ["channel", "rekindle"], "attuned": {"min": 5, "hp": 20},
		"moves": [
			{"name": "Tail Whip", "cost": 0, "damage": 20},
			{"name": "Fire Spit", "cost": 1, "damage": 30},
		],
		"art": "a plump orange salamander curled in a hearth of glowing coals, little flames dancing along its spine, sleepy content smile",
	},
	"ashen_drake": {
		"kind": "totem", "name": "Ashen Drake", "element": "fire", "tier": 3, "stage": 0, "cost": 4,
		"hp": 140, "affinity": "might", "attuned": {"min": 6, "damage": 20},
		"moves": [
			{"name": "Scorch", "cost": 0, "damage": 30},
			{"name": "Scorch Breath", "cost": 2, "damage": 70},
			{"name": "Cinder Storm", "cost": 4, "damage": 40, "target": "all_foes"},
		],
		"art": "a young dragon with charcoal-grey scales and glowing orange cracks, smoke pouring from its jaws, wings half spread",
	},
	# ================================================================== STORM
	"sparkkit": {
		"kind": "totem", "name": "Sparkkit", "element": "storm", "tier": 1, "stage": 0, "cost": 1,
		"hp": 70, "affinity": "swiftness", "keywords": ["combo"], "attuned": {"min": 6, "damage": 10},
		"moves": [
			{"name": "Zap", "cost": 0, "damage": 10},
			{"name": "Crackle", "cost": 1, "damage": 0, "fate": [
				{"to": 1, "damage": 0, "text": "Miss"},
				{"to": 11, "damage": 20},
				{"to": 19, "damage": 30, "effects": [{"op": "status", "status": "shocked"}]},
				{"to": 99, "damage": 50, "effects": [{"op": "status", "status": "stun"}]}]},
		],
		"art": "a small indigo fox kit with crackling yellow lightning along its ears and a bolt-shaped tail",
	},
	"voltlynx": {
		"kind": "totem", "name": "Voltlynx", "element": "storm", "tier": 2, "stage": 1,
		"ascends_from": "sparkkit", "cost": 2, "hp": 120, "affinity": "swiftness", "keywords": ["swift"],
		"moves": [
			{"name": "Thunder Claw", "cost": 0, "damage": 30},
			{"name": "Chain Lightning", "cost": 2, "damage": 30, "target": "foe_totem",
				"effects": [{"op": "splash_random", "amount": 20}]},
		],
		"art": "a lynx with deep indigo fur and ear tufts sparking with electricity, a jagged lightning mane, snarling",
	},
	"thunder_ram": {
		"kind": "totem", "name": "Thunder Ram", "element": "storm", "tier": 2, "stage": 0, "cost": 3,
		"hp": 100, "affinity": "might", "keywords": ["swift"],
		"moves": [
			{"name": "Headbutt", "cost": 0, "damage": 20},
			{"name": "Thunder Charge", "cost": 2, "damage": 60, "effects": [{"op": "self_damage", "amount": 20}]},
		],
		"art": "a charging ram with storm-grey wool crackling with static, curled horns glowing electric blue, sparks under its hooves",
	},
	"stormcaller": {
		"kind": "totem", "name": "Stormcaller Heron", "element": "storm", "tier": 3, "stage": 0, "cost": 4,
		"keywords": ["galvanise"],
		"hp": 130, "affinity": "intellect", "attuned": {"min": 6, "cost": 1},
		"moves": [
			{"name": "Gale Bolt", "cost": 0, "damage": 20},
			{"name": "Thunderhead", "cost": 2, "damage": 0, "fate": [
				{"to": 1, "damage": 0, "text": "Miss"},
				{"to": 9, "damage": 40},
				{"to": 19, "damage": 70},
				{"to": 99, "damage": 100, "effects": [{"op": "status", "status": "stun"}]}]},
		],
		"art": "a tall heron standing in dark water, storm clouds swirling around its crest, lightning dancing between its wings",
	},
	# =================================================================== TIDE
	"brookfin": {
		"kind": "totem", "name": "Brookfin", "element": "tide", "tier": 1, "stage": 0, "cost": 1,
		"keywords": ["echo"], "echo": {"when": "ally_falls", "op": "heal_weakest", "amount": 20},
		"hp": 90, "affinity": "resolve", "attuned": {"min": 5, "hp": 20},
		"moves": [
			{"name": "Splash", "cost": 0, "damage": 10},
			{"name": "Undertow", "cost": 1, "damage": 30, "effects": [{"op": "heal", "who": "self", "amount": 10}]},
		],
		"art": "a small river serpent with translucent blue fins and pebble-smooth scales, curled in a splash of clear water",
	},
	"riptide_serpent": {
		"kind": "totem", "name": "Riptide Serpent", "element": "tide", "tier": 2, "stage": 1,
		"ascends_from": "brookfin", "cost": 2, "hp": 140, "affinity": "resolve", "attuned": {"min": 5, "hp": 20},
		"moves": [
			{"name": "Water Lash", "cost": 0, "damage": 30},
			{"name": "Riptide", "cost": 2, "damage": 60, "effects": [{"op": "heal", "who": "self", "amount": 20}]},
		],
		"art": "a long sea serpent coiling through a crashing wave, fins like torn sails, eyes glowing deep blue",
	},
	"deepmaw": {
		"kind": "totem", "name": "Deepmaw Leviathan", "element": "tide", "tier": 3, "stage": 2,
		"ascends_from": "riptide_serpent", "cost": 3, "hp": 220, "affinity": "resolve", "attuned": {"min": 6, "hp": 30},
		"moves": [
			{"name": "Crushing Tide", "cost": 0, "damage": 40},
			{"name": "Maelstrom", "cost": 3, "damage": 90},
		],
		"art": "a colossal sea leviathan rising from a whirlpool, barnacled armour plates, a jaw wide enough to swallow ships",
	},
	"shellguard": {
		"kind": "totem", "name": "Shellguard", "element": "tide", "tier": 1, "stage": 0, "cost": 2,
		"hp": 120, "affinity": "resolve", "keywords": ["guardian", "shelter"],
		"moves": [
			{"name": "Shell Slam", "cost": 0, "damage": 20},
			{"name": "Withdraw", "cost": 1, "damage": 0, "target": "none",
				"effects": [{"op": "shield", "who": "self", "amount": 40}]},
		],
		"art": "a sturdy turtle with a coral-covered shell and a calm wise face, water droplets beading on its shell",
	},
	# ================================================================= SPIRIT
	"lantern_moth": {
		"kind": "totem", "name": "Lantern Moth", "element": "spirit", "tier": 1, "stage": 0, "cost": 1,
		"hp": 50, "affinity": "insight", "keywords": ["channel", "tend"], "attuned": {"min": 5, "hp": 10},
		"moves": [
			{"name": "Glimmer", "cost": 0, "damage": 10},
			{"name": "Dazzle", "cost": 1, "damage": 0, "target": "foe_totem", "fate": [
				{"to": 10, "damage": 20},
				{"to": 99, "damage": 20, "effects": [{"op": "status", "status": "sleep"}]}]},
		],
		"art": "a plump spirit moth whose round furry body glows warm amber like a paper festival lantern, translucent teal and silver wings patterned like lantern ribs",
	},
	# ================================================================ VERDANT
	"mossling": {
		"kind": "totem", "name": "Mossling", "element": "verdant", "tier": 1, "stage": 0, "cost": 1,
		"hp": 90, "affinity": "resolve", "attuned": {"min": 5, "hp": 20},
		"moves": [
			{"name": "Sap", "cost": 0, "damage": 10, "effects": [{"op": "heal", "who": "self", "amount": 10}]},
			{"name": "Vine Snare", "cost": 1, "damage": 0, "target": "foe_totem", "fate": [
				{"to": 10, "damage": 20},
				{"to": 99, "damage": 20, "effects": [{"op": "status", "status": "rooted"}]}]},
		],
		"art": "a small round forest creature covered in soft moss, a sprout growing from its head, big gentle eyes",
	},
	"thornwarden": {
		"kind": "totem", "name": "Thornwarden", "element": "verdant", "tier": 2, "stage": 1,
		"ascends_from": "mossling", "cost": 2, "hp": 140, "affinity": "resolve", "keywords": ["thorns"],
		"attuned": {"min": 5, "hp": 20},
		"moves": [
			{"name": "Barbed Lash", "cost": 0, "damage": 20, "effects": [{"op": "status", "status": "poison"}]},
			{"name": "Wild Growth", "cost": 2, "damage": 50, "effects": [{"op": "heal", "who": "self", "amount": 20}]},
		],
		"art": "a bear-like guardian made of woven roots and thorny vines, flowers blooming on its shoulders, protective stance",
	},
	"bloomsprite": {
		"kind": "totem", "name": "Bloomsprite", "element": "verdant", "tier": 1, "stage": 0, "cost": 1,
		"reveal": {"op": "heal_allies", "amount": 20},
		"hp": 70, "affinity": "insight", "keywords": ["reveal", "channel", "tend"], "attuned": {"min": 5, "draw": 1},
		"moves": [
			{"name": "Petal Mend", "cost": 0, "damage": 0, "target": "ally",
				"effects": [{"op": "heal", "who": "target", "amount": 30}]},
			{"name": "Pollen Burst", "cost": 1, "damage": 0, "target": "foe_totem", "fate": [
				{"to": 10, "damage": 20},
				{"to": 99, "damage": 20, "effects": [{"op": "status", "status": "sleep"}]}]},
		],
		"art": "a tiny fairy-like sprite with petal wings and a flower-bud head, scattering glowing pollen",
	},
	"elderbark": {
		"kind": "totem", "name": "Elderbark", "element": "verdant", "tier": 3, "stage": 0, "cost": 5,
		"hp": 200, "affinity": "resolve", "keywords": ["guardian"], "attuned": {"min": 6, "hp": 30},
		"moves": [
			{"name": "Root Slam", "cost": 0, "damage": 30},
			{"name": "Ancient Grasp", "cost": 3, "damage": 70, "effects": [{"op": "status", "status": "stun"}]},
		],
		"art": "an ancient walking tree with a bark face, moss beard and glowing sap veins, roots dragging like feet",
	},
	# ================================================================== EARTH
	"pebblit": {
		"kind": "totem", "name": "Pebblit", "element": "earth", "tier": 1, "stage": 0, "cost": 1,
		"keywords": ["echo"], "echo": {"when": "ally_falls", "op": "essence_next", "amount": 1},
		"hp": 80, "affinity": "might", "attuned": {"min": 5, "damage": 10},
		"moves": [
			{"name": "Pebble Toss", "cost": 0, "damage": 10},
			{"name": "Rock Smash", "cost": 1, "damage": 30},
		],
		"art": "a round pebble creature with little stubby arms, a teal crystal growing from its head, cheerful face",
	},
	"boulderox": {
		"kind": "totem", "name": "Boulderox", "element": "earth", "tier": 2, "stage": 1,
		"ascends_from": "pebblit", "cost": 2, "hp": 160, "affinity": "might", "attuned": {"min": 5, "damage": 10},
		"moves": [
			{"name": "Horn Ram", "cost": 0, "damage": 30},
			{"name": "Landslide", "cost": 3, "damage": 80},
		],
		"art": "a massive ox with a body of layered boulders, curved stone horns, moss in the cracks, pawing the ground",
	},
	"burrowmole": {
		"kind": "totem", "name": "Burrowmole", "element": "earth", "tier": 1, "stage": 0, "cost": 2,
		"reveal": {"op": "damage_across", "amount": 20},
		"hp": 80, "affinity": "cunning", "keywords": ["reveal", "burrow", "combo"],
		"moves": [
			{"name": "Dig Strike", "cost": 0, "damage": 20},
			{"name": "Tunnel Ambush", "cost": 1, "damage": 0, "fate": [
				{"to": 1, "damage": 0, "text": "Miss"},
				{"to": 10, "damage": 20},
				{"to": 19, "damage": 40},
				{"to": 99, "damage": 60, "effects": [{"op": "status", "status": "stun"}]}]},
		],
		"art": "a mole in a battered miner's helmet with a glowing lamp, huge digging claws, clods of earth flying",
	},
	"quarry_golem": {
		"kind": "totem", "name": "Quarry Golem", "element": "earth", "tier": 3, "stage": 0, "cost": 5,
		"hp": 210, "affinity": "might", "keywords": ["guardian"], "attuned": {"min": 6, "damage": 20},
		"moves": [
			{"name": "Slam", "cost": 0, "damage": 30},
			{"name": "Rockfall", "cost": 3, "damage": 90},
		],
		"art": "a towering golem of quarried granite blocks held together by glowing amber veins, a pickaxe still lodged in its shoulder",
	},
	# ================================================================== METAL
	"brassback": {
		"kind": "totem", "name": "Brassback", "element": "metal", "tier": 1, "stage": 0, "cost": 1,
		"hp": 80, "affinity": "resolve", "keywords": ["guardian"],
		"moves": [
			{"name": "Clank", "cost": 0, "damage": 10},
			{"name": "Horn Bash", "cost": 1, "damage": 30},
		],
		"art": "a beetle with a polished brass shell engraved with sun patterns, a single curved horn, sturdy legs",
	},
	"ironhide": {
		"kind": "totem", "name": "Ironhide Warbeetle", "element": "metal", "tier": 2, "stage": 1,
		"ascends_from": "brassback", "cost": 2, "hp": 160, "affinity": "resolve", "keywords": ["guardian"],
		"attuned": {"min": 5, "hp": 20},
		"moves": [
			{"name": "Iron Tackle", "cost": 0, "damage": 30},
			{"name": "Steel Wall", "cost": 1, "damage": 20, "effects": [{"op": "shield", "who": "self", "amount": 50}]},
		],
		"art": "a huge armoured war beetle with riveted iron plates and a battering-ram horn, gold trim, sun banners",
	},
	"shieldhound": {
		"kind": "totem", "name": "Shieldhound", "element": "metal", "tier": 1, "stage": 0, "cost": 2,
		"keywords": ["loyal", "rally"],
		"hp": 100, "affinity": "resolve", "attuned": {"min": 5, "damage": 10},
		"moves": [
			{"name": "Guard Bite", "cost": 0, "damage": 20},
			{"name": "Shield Bash", "cost": 1, "damage": 30, "effects": [{"op": "status", "status": "bleed"}]},
		],
		"art": "a loyal hound wearing a small steel breastplate and helm, a sun crest on its collar, standing guard",
	},
	"gilded_sentinel": {
		"kind": "totem", "name": "Gilded Sentinel", "element": "metal", "tier": 3, "stage": 0, "cost": 4,
		"hp": 170, "affinity": "presence", "keywords": ["guardian", "shelter"], "attuned": {"min": 6, "damage": 20},
		"moves": [
			{"name": "Gilded Blade", "cost": 0, "damage": 30},
			{"name": "Judgement", "cost": 2, "damage": 70},
		],
		"art": "a tall golden armoured construct with a halo-shaped helm and a sunburst halberd, light spilling from its joints",
	},
	# ================================================================ PSYCHIC
	"dreamfox": {
		"kind": "totem", "name": "Dreamfox", "element": "psychic", "tier": 1, "stage": 0, "cost": 1,
		"keywords": ["reveal"], "reveal": {"op": "status_across", "status": "sleep"},
		"hp": 90, "affinity": "insight", "attuned": {"min": 5, "draw": 1},
		"moves": [
			{"name": "Psy Nip", "cost": 0, "damage": 10},
			{"name": "Hypnotic Gaze", "cost": 1, "damage": 0, "target": "foe_totem", "fate": [
				{"to": 5, "damage": 10},
				{"to": 12, "damage": 10, "effects": [{"op": "status", "status": "confused"}]},
				{"to": 99, "damage": 10, "effects": [{"op": "status", "status": "sleep"}]}]},
		],
		"art": "a slender pink fox with two misty tails and half-closed dreamy eyes, bubbles of illusion floating around it",
	},
	"veilfox": {
		"kind": "totem", "name": "Veilfox", "element": "psychic", "tier": 2, "stage": 1,
		"keywords": ["riposte"],
		"ascends_from": "dreamfox", "cost": 2, "hp": 140, "affinity": "insight", "attuned": {"min": 5, "damage": 10},
		"moves": [
			{"name": "Mind Lash", "cost": 0, "damage": 30},
			{"name": "Mirage", "cost": 2, "damage": 40, "effects": [{"op": "status", "status": "confused"}]},
		],
		"art": "an elegant fox with four translucent veil-like tails, a glowing third eye, surrounded by shifting mirages",
	},
	"somnowl": {
		"kind": "totem", "name": "Somnowl", "element": "psychic", "tier": 1, "stage": 0, "cost": 2,
		"reveal": {"op": "draw", "count": 1},
		"hp": 100, "affinity": "insight", "keywords": ["reveal", "channel"],
		"moves": [
			{"name": "Hoot", "cost": 0, "damage": 20},
			{"name": "Night Screech", "cost": 2, "damage": 20, "target": "all_foes"},
		],
		"art": "a round lavender owl with enormous sleepy moon-eyes, feathers trailing wisps of dream-mist, perched on a crescent moon",
	},
	"thought_eater": {
		"kind": "totem", "name": "Thought Eater", "element": "psychic", "tier": 3, "stage": 0, "cost": 4,
		"hp": 160, "affinity": "intellect", "attuned": {"min": 6, "damage": 20}, "keywords": ["harvest"],
		"moves": [
			{"name": "Mind Rend", "cost": 0, "damage": 30},
			{"name": "Devour Thought", "cost": 2, "damage": 60, "effects": [{"op": "discard_random", "count": 1}]},
		],
		"art": "a tapir-like dream beast with a star-speckled violet hide, a long curling trunk inhaling glowing thought-bubbles",
	},
	# ================================================================== VENOM
	"blightrat": {
		"kind": "totem", "name": "Blightrat", "element": "venom", "tier": 1, "stage": 0, "cost": 1,
		"keywords": ["echo"], "echo": {"when": "ally_falls", "op": "status_attacker", "status": "poison"},
		"hp": 90, "affinity": "cunning", "attuned": {"min": 5, "damage": 10},
		"moves": [
			{"name": "Gnaw", "cost": 0, "damage": 10},
			{"name": "Plague Bite", "cost": 1, "damage": 20, "effects": [{"op": "status", "status": "poison"}]},
		],
		"art": "a mangy rat with sickly purple fur, dripping green-violet fangs, beady glowing eyes, sneaking",
	},
	"plague_asp": {
		"kind": "totem", "name": "Plague Asp", "element": "venom", "tier": 2, "stage": 1,
		"ascends_from": "blightrat", "cost": 2, "hp": 130, "affinity": "cunning", "attuned": {"min": 5, "damage": 10},
		"moves": [
			{"name": "Fang", "cost": 0, "damage": 30},
			{"name": "Venom Surge", "cost": 2, "damage": 40, "target": "foe_totem",
				"effects": [{"op": "bonus_if_status", "status": "poison", "amount": 40}]},
		],
		"art": "a coiled asp with violet scales and a hood marked like a skull, venom mist rising around it",
	},
	"mirewidow": {
		"kind": "totem", "name": "Mirewidow", "element": "venom", "tier": 1, "stage": 0, "cost": 2,
		"reveal": {"op": "status_across", "status": "poison"},
		"hp": 90, "affinity": "cunning", "keywords": ["reveal", "thorns", "combo"],
		"moves": [
			{"name": "Venom Bite", "cost": 0, "damage": 10, "target": "foe_totem",
				"effects": [{"op": "status", "status": "poison"}]},
			{"name": "Web Snare", "cost": 1, "damage": 0, "target": "foe_totem", "fate": [
				{"to": 7, "damage": 10},
				{"to": 16, "damage": 20, "effects": [{"op": "status", "status": "stun"}]},
				{"to": 99, "damage": 30, "effects": [{"op": "status", "status": "stun"}, {"op": "status", "status": "poison"}]}]},
		],
		"art": "a swamp spider with an iridescent violet abdomen, legs dripping luminous venom, sitting in a dewy web over a bog",
	},
	# ================================================================ RADIANT
	# Solhaven's own light (Master Script v3, Chapter 1: Ser Aldric's duel on
	# the Sunspire). Paintings to come: cards/<id>.png, creatures/<id>.png.
	"sunlance_seraph": {
		"kind": "totem", "name": "Sunlance Seraph", "element": "radiant", "tier": 5, "stage": 0, "cost": 5,
		"hp": 200, "affinity": "presence", "keywords": ["swift"], "attuned": {"min": 6, "damage": 20},
		"moves": [
			{"name": "Sunlance", "cost": 0, "damage": 30},
			{"name": "Dawnbreak Lance", "cost": 3, "damage": 80, "effects": [{"op": "pierce"}]},
		],
		"art": "a six-winged seraph of white gold and living sunlight, a long lance of light levelled, a face hidden behind a sunburst helm, an heirloom of a knightly house",
	},
	"sunmane_lion": {
		"kind": "totem", "name": "Sunmane Lion", "element": "radiant", "tier": 4, "stage": 0, "cost": 3,
		"hp": 130, "affinity": "presence", "keywords": ["swift"], "attuned": {"min": 5, "damage": 10},
		"moves": [
			{"name": "Pounce", "cost": 0, "damage": 30},
			{"name": "Mane of Dawn", "cost": 2, "damage": 50, "effects": [{"op": "boon", "who": "self", "boon": "blessed"}]},
		],
		"art": "a young lion made of cooling sunlight, its mane a ring of soft gold flame, Dawnmane made small, crouched to pounce",
	},
	# ================================================================ SUMMONS
	"dawnmane": {
		"kind": "summon", "name": "Dawnmane, the Sun Lion", "element": "radiant", "tier": 6, "cost": 7,
		"affinity": "presence",
		"move": {"name": "Dawn's Roar", "damage": 70, "target": "all_foes",
			"effects": [{"op": "boon", "who": "allies", "boon": "blessed"}]},
		"art": "a colossal lion of blazing dawn light leaping down from the sun, its mane a corona, roaring over a white city of gold domes",
	},
	"pyraxis": {
		"kind": "summon", "name": "Pyraxis, Heart of the Pyre", "element": "fire", "tier": 6, "cost": 7,
		"affinity": "might",
		"move": {"name": "Sunfall", "damage": 60, "target": "all_foes",
			"effects": [{"op": "status", "status": "burn"}]},
		"art": "a colossal phoenix-dragon demigod of white-hot flame descending from a burning sky, wings spanning the horizon, molten feathers raining down",
	},
	"thalassa": {
		"kind": "summon", "name": "Thalassa, the Deep Mother", "element": "tide", "tier": 6, "cost": 7,
		"affinity": "resolve",
		"move": {"name": "Tidal Embrace", "damage": 70, "target": "all_foes",
			"effects": [{"op": "heal", "who": "allies", "amount": 60}, {"op": "life", "amount": 40}]},
		"art": "a vast serene sea goddess rising from the ocean, hair of rolling waves, a crown of coral and pearls, arms cradling a whirlpool",
	},
	"grondmaw": {
		"kind": "summon", "name": "Grondmaw, the Mountain's Heart", "element": "earth", "tier": 6, "cost": 6,
		"affinity": "might",
		"move": {"name": "Worldbreaker", "damage": 180, "target": "foe_totem", "effects": [{"op": "pierce"}, {"op": "stun_others"}]},
		"art": "a titanic stone giant tearing itself free of a mountain range, glowing magma heart visible through cracked ribs, fists like boulders",
	},
	"somnara": {
		"kind": "summon", "name": "Somnyx, the Dreaming Veil", "element": "psychic", "tier": 6, "cost": 6,
		"affinity": "insight",
		"move": {"name": "Endless Dream", "damage": 40, "target": "all_foes",
			"effects": [{"op": "status", "status": "sleep"}]},
		"art": "an ethereal moth-winged demigoddess veiled in drifting starlit silk, her closed eyes glowing, the world below falling into a dream",
	},
	# ====================================== SECOND-STAGE ASCENSIONS (Phase C)
	"infernal_warg": {
		"kind": "totem", "name": "Infernal Warg", "element": "fire", "tier": 3, "stage": 2,
		"ascends_from": "blazehound", "cost": 3, "hp": 200, "affinity": "might", "stand_in": "blazehound",
		"attuned": {"min": 6, "damage": 20}, "keywords": ["harvest"],
		"moves": [
			{"name": "Searing Maw", "cost": 0, "damage": 40},
			{"name": "Hellfire Charge", "cost": 3, "damage": 80, "effects": [{"op": "status", "status": "burn"}]},
		],
		"art": "a towering warg of black stone and living fire, a mane of white-hot flame, eyes like forge mouths, molten drool hissing on the ground",
	},
	"tempest_lynx": {
		"kind": "totem", "name": "Tempest Lynx", "element": "storm", "tier": 3, "stage": 2,
		"ascends_from": "voltlynx", "cost": 3, "hp": 170, "affinity": "swiftness", "stand_in": "voltlynx", "keywords": ["swift"],
		"moves": [
			{"name": "Arc Claw", "cost": 0, "damage": 40},
			{"name": "Storm Front", "cost": 3, "damage": 30, "target": "all_foes", "effects": [{"op": "status", "status": "shocked"}]},
		],
		"art": "a great lynx made of storm cloud and lightning, ear tufts crackling, each pawstep a thunderclap of light",
	},
	"briar_colossus": {
		"kind": "totem", "name": "Briar Colossus", "element": "verdant", "tier": 3, "stage": 2,
		"ascends_from": "thornwarden", "cost": 3, "hp": 220, "affinity": "resolve", "stand_in": "thornwarden", "keywords": ["thorns"],
		"moves": [
			{"name": "Bramble Slam", "cost": 0, "damage": 30, "effects": [{"op": "status", "status": "poison"}]},
			{"name": "Overgrowth", "cost": 3, "damage": 60, "effects": [{"op": "heal", "who": "self", "amount": 30}]},
		],
		"art": "a walking giant of knotted briar and old oak, thorns as long as swords, flowers blooming in the hollows of its chest",
	},
	"cragmaul": {
		"kind": "totem", "name": "Cragmaul", "element": "earth", "tier": 3, "stage": 2,
		"ascends_from": "boulderox", "cost": 3, "hp": 230, "affinity": "might", "stand_in": "boulderox",
		"attuned": {"min": 6, "damage": 20},
		"moves": [
			{"name": "Rockfall", "cost": 0, "damage": 40},
			{"name": "Earthbreaker", "cost": 4, "damage": 100},
		],
		"art": "a mountain of an ox, a whole cliff for a back, horns of raw granite, the ground cracking around its hooves",
	},
	"ironclad_behemoth": {
		"kind": "totem", "name": "Ironclad Behemoth", "element": "metal", "tier": 3, "stage": 2,
		"ascends_from": "ironhide", "cost": 3, "hp": 250, "affinity": "resolve", "stand_in": "ironhide", "keywords": ["guardian"],
		"moves": [
			{"name": "Shell Ram", "cost": 0, "damage": 30},
			{"name": "Forged Bulwark", "cost": 2, "damage": 40, "effects": [{"op": "shield", "who": "self", "amount": 60}]},
		],
		"art": "a colossal beetle in riveted iron plate, steam venting from its joints, a shell like a fortress gate",
	},
	"ninefold_fox": {
		"kind": "totem", "name": "Ninefold Fox", "element": "psychic", "tier": 3, "stage": 2,
		"ascends_from": "veilfox", "cost": 3, "hp": 170, "affinity": "insight", "stand_in": "veilfox", "keywords": ["riposte"],
		"moves": [
			{"name": "Mirage Bite", "cost": 0, "damage": 40},
			{"name": "Ninefold Illusion", "cost": 3, "damage": 30, "target": "all_foes", "effects": [{"op": "status", "status": "confused"}]},
		],
		"art": "a silver fox with nine translucent tails, each one a shimmering copy of the fox itself, eyes like twin moons",
	},
	"blight_wyrm": {
		"kind": "totem", "name": "Blight Wyrm", "element": "venom", "tier": 3, "stage": 2,
		"ascends_from": "plague_asp", "cost": 3, "hp": 200, "affinity": "cunning", "stand_in": "plague_asp",
		"moves": [
			{"name": "Venom Coil", "cost": 0, "damage": 30, "effects": [{"op": "status", "status": "poison"}]},
			{"name": "Plague Breath", "cost": 3, "damage": 40, "target": "all_foes", "effects": [{"op": "status", "status": "poison"}]},
		],
		"art": "a long-bodied wyrm with sickly green scales, a hood of bone spines, breathing a cloud of glowing violet spores",
	},
	# ================================================================== RITES
	"essence_flask": {
		"kind": "rite", "name": "Essence Flask", "element": "any", "tier": 1, "cost": 0, "target": "none",
		"effects": [{"op": "essence", "amount": 2}],
		"art": "a crystal flask holding swirling motes of many-coloured light",
	},
	# (27 October) Never in a deck: a duellist's god sends it, once a duel, when
	# their Life first falls to a quarter (DuelGame._after_life_loss: Gary's "comeback card"). "granted"
	# keeps it out of the Codex, the caches and the rewards.
	"rallying_light": {
		"kind": "rite", "name": "Rallying Light", "element": "any", "tier": 1, "cost": 0, "target": "none",
		"granted": true,
		"effects": [{"op": "heal", "who": "allies", "amount": 30}, {"op": "boon", "who": "allies", "boon": "empowered"},
			{"op": "draw", "count": 1}],
		"art": "a single card blazing with golden light in a darkened duelling circle, embers rising round a duellist's raised hand",
	},
	"crystal_vein": {
		"kind": "rite", "name": "Crystal Vein", "element": "any", "tier": 2, "cost": 2, "target": "none",
		"effects": [{"op": "essence_max", "amount": 1}],
		"art": "a seam of raw glowing sigil-crystal running through dark rock, light pulsing along it like a heartbeat",
	},
	"healing_draught": {
		"kind": "rite", "name": "Healing Draught", "element": "any", "tier": 1, "cost": 1, "target": "ally",
		"effects": [{"op": "heal", "who": "target", "amount": 50}, {"op": "cure", "who": "target"}],
		"art": "a glass flask of glowing rose-red liquid with a cork stopper, tiny bubbles rising",
	},
	"travellers_pack": {
		"kind": "rite", "name": "Traveller's Pack", "element": "any", "tier": 1, "cost": 2, "target": "none",
		"effects": [{"op": "draw", "count": 2}],
		"art": "a worn leather travelling pack spilling out a bedroll, a lantern and a bundle of cards tied with string",
	},
	"seekers_compass": {
		"kind": "rite", "name": "Seeker's Compass", "element": "any", "tier": 1, "cost": 1, "target": "none",
		"effects": [{"op": "search_totem"}],
		"art": "an ornate brass compass whose needle is a tiny flame, pointing towards a hidden card",
	},
	"lure_bell": {
		"kind": "rite", "name": "Lure Bell", "element": "any", "tier": 2, "cost": 1, "target": "foe_totem",
		"effects": [{"op": "move_foe"}],
		"art": "a small golden bell with a sun engraving, sound waves of light rippling from it",
	},
	"firebrand": {
		"kind": "rite", "name": "Firebrand", "element": "fire", "tier": 1, "cost": 2, "target": "foe_totem",
		"damage": 40, "keywords": ["combo"],
		"art": "a burning brand hurled through the air, trailing a comet-tail of sparks",
	},
	"thunderclap": {
		"kind": "rite", "name": "Thunderclap", "element": "storm", "tier": 2, "cost": 3, "target": "all_foes",
		"damage": 20, "keywords": ["combo"], "effects": [{"op": "status", "status": "shocked"}],
		"art": "a single enormous lightning bolt striking the centre of a duelling circle, a ring of thunder rippling outward",
	},
	"tidal_surge": {
		"kind": "rite", "name": "Tidal Surge", "element": "tide", "tier": 2, "cost": 2, "target": "foe_totem",
		"effects": [{"op": "bounce"}],
		"art": "a towering green-blue wave curling over a stone circle, about to sweep everything away",
	},
	"rejuvenate": {
		"kind": "rite", "name": "Rejuvenate", "element": "verdant", "tier": 1, "cost": 1, "target": "none",
		"effects": [{"op": "life", "amount": 40}], "keywords": ["combo"],
		"art": "a cupped pair of hands holding a sprouting seedling that glows with soft green light",
	},
	"bulwark": {
		"kind": "rite", "name": "Bulwark", "element": "earth", "tier": 1, "cost": 1, "target": "ally",
		"effects": [{"op": "shield", "who": "target", "amount": 50}], "keywords": ["combo"],
		"art": "a wall of stone slabs erupting from the ground in a protective half-ring, dust flying",
	},
	"forge_edge": {
		"kind": "rite", "name": "Forge Edge", "element": "metal", "tier": 1, "cost": 1, "target": "ally",
		"effects": [{"op": "buff", "amount": 20}], "keywords": ["combo"],
		"art": "a glowing blade fresh from the anvil, sparks flying as a hammer strikes it",
	},
	"mind_fog": {
		"kind": "rite", "name": "Mind Fog", "element": "psychic", "tier": 1, "cost": 2, "target": "foe_totem",
		"effects": [{"op": "status", "status": "sleep"}],
		"art": "a swirl of pink-violet fog shaped like a sleeping face drifting over a battlefield",
	},
	"toxic_mist": {
		"kind": "rite", "name": "Toxic Mist", "element": "venom", "tier": 2, "cost": 2, "target": "all_foes",
		"effects": [{"op": "status", "status": "poison"}],
		"art": "a creeping cloud of glowing green-violet poison rolling low over the ground",
	},
	"siphon_rune": {
		"kind": "rite", "name": "Siphon Rune", "element": "venom", "tier": 2, "cost": 2, "target": "foe_totem",
		"damage": 30, "keywords": ["combo"], "effects": [{"op": "drain"}],
		"art": "a dark stone rune tile with a glowing violet symbol draining light into itself",
	},
	# ------------------------------------------ v2 condition and boon Rites ---
	"frostbind": {
		"kind": "rite", "name": "Frostbind", "element": "frost", "tier": 2, "cost": 2, "target": "foe_totem",
		"damage": 10, "effects": [{"op": "status", "status": "frozen"}],
		"art": "a creature caught mid-leap inside a block of blue glacial ice, frost runes spiralling across the surface",
	},
	"gust_shove": {
		"kind": "rite", "name": "Gust Shove", "element": "wind", "tier": 1, "cost": 1, "target": "foe_totem",
		"damage": 20, "effects": [{"op": "status", "status": "staggered"}],
		"art": "a fist of swirling pale-green wind slamming into a creature's flank, leaves and dust whipping past",
	},
	"corrosive_spit": {
		"kind": "rite", "name": "Corrosive Spit", "element": "venom", "tier": 1, "cost": 1, "target": "foe_totem",
		"damage": 10, "effects": [{"op": "status", "status": "corroded"}],
		"art": "a gob of glowing yellow-green acid hissing as it eats through a metal plate, smoke curling up",
	},
	"jagged_shards": {
		"kind": "rite", "name": "Jagged Shards", "element": "metal", "tier": 1, "cost": 1, "target": "foe_totem",
		"damage": 20, "keywords": ["combo"], "effects": [{"op": "status", "status": "bleed"}],
		"art": "a burst of razor-edged steel shards flying through the air, glinting red in firelight",
	},
	"drowning_rain": {
		"kind": "rite", "name": "Drowning Rain", "element": "tide", "tier": 1, "cost": 1, "target": "all_foes",
		"damage": 10, "effects": [{"op": "status", "status": "soaked"}],
		"art": "a heavy sheet of blue-green rain pouring onto a duelling circle, water pooling between the runes",
	},
	"strangling_roots": {
		"kind": "rite", "name": "Strangling Roots", "element": "verdant", "tier": 1, "cost": 1, "target": "foe_totem",
		"damage": 10, "effects": [{"op": "status", "status": "rooted"}],
		"art": "thick green roots bursting from the earth and coiling around a creature's legs, pinning it in place",
	},
	"stone_gaze": {
		"kind": "rite", "name": "Stone Gaze", "element": "earth", "tier": 2, "cost": 2, "target": "foe_totem",
		"effects": [{"op": "status", "status": "petrified"}],
		"art": "an ancient carved stone eye glowing amber, a creature before it slowly turning to grey stone from the feet up",
	},
	"blinding_flare": {
		"kind": "rite", "name": "Blinding Flare", "element": "fire", "tier": 1, "cost": 1, "target": "foe_totem",
		"effects": [{"op": "status", "status": "blinded"}],
		"art": "a white-gold flash of fire exploding in a creature's face, it reels back with eyes shut tight",
	},
	"goading_ember": {
		"kind": "rite", "name": "Goading Ember", "element": "fire", "tier": 1, "cost": 1, "target": "foe_totem",
		"damage": 20, "effects": [{"op": "status", "status": "enraged"}],
		"art": "a single taunting ember flicked at a beast, the beast snarling with red rage lines around it",
	},
	"confounding_chime": {
		"kind": "rite", "name": "Confounding Chime", "element": "psychic", "tier": 1, "cost": 1, "target": "foe_totem",
		"damage": 10, "effects": [{"op": "status", "status": "confused"}],
		"art": "a crystal chime ringing out rippling pink-violet sound rings, a creature spinning dizzily in them",
	},
	"heart_lure": {
		"kind": "rite", "name": "Heart Lure", "element": "psychic", "tier": 2, "cost": 2, "target": "foe_totem",
		"effects": [{"op": "status", "status": "charmed"}],
		"art": "a floating rose-pink heart of light on a silver thread, drawing a fierce beast forward in a daze",
	},
	"dread_howl": {
		"kind": "rite", "name": "Dread Howl", "element": "spirit", "tier": 2, "cost": 2, "target": "all_foes",
		"effects": [{"op": "status", "status": "terrified"}],
		"art": "a spectral teal wolf throwing back its head in a howl, shadowy creatures cowering before the sound",
	},
	"silence_rune": {
		"kind": "rite", "name": "Silence Rune", "element": "mystic", "tier": 1, "cost": 1, "target": "foe_totem",
		"effects": [{"op": "status", "status": "silenced"}],
		"art": "an indigo rune seal pressed over a creature's mouth like a glowing gag, its power muffled",
	},
	"puppet_rune": {
		"kind": "rite", "name": "Puppet Rune", "element": "mystic", "tier": 3, "cost": 3, "target": "foe_totem",
		"effects": [{"op": "status", "status": "possessed"}],
		"art": "glowing violet threads of rune-light hooked into a creature's limbs, a ghostly hand above working them like a puppet",
	},
	"hex_mark": {
		"kind": "rite", "name": "Hex Mark", "element": "mystic", "tier": 1, "cost": 1, "target": "foe_totem",
		"effects": [{"op": "status", "status": "hexed"}],
		"art": "a crooked violet sigil burning onto a creature's hide, chains of tiny runes trailing from it",
	},
	"grave_curse": {
		"kind": "rite", "name": "Grave Curse", "element": "spirit", "tier": 1, "cost": 1, "target": "foe_totem",
		"effects": [{"op": "status", "status": "cursed"}],
		"art": "a cold grey-green hand of mist rising from a grave, its finger touching a creature's brow",
	},
	"hunters_mark": {
		"kind": "rite", "name": "Hunter's Mark", "element": "any", "tier": 1, "cost": 1, "target": "foe_totem",
		"effects": [{"op": "status", "status": "marked"}],
		"art": "a glowing red target sigil painted on a creature's shoulder, a hunter's arrow fletching in the foreground",
	},
	"soul_siphon": {
		"kind": "rite", "name": "Soul Siphon", "element": "spirit", "tier": 2, "cost": 2, "target": "foe_totem",
		"damage": 20, "effects": [{"op": "status", "status": "drained"}],
		"art": "a ribbon of pale teal soul-light being drawn out of a creature into an open hand",
	},
	"doom_sigil": {
		"kind": "rite", "name": "Doom Sigil", "element": "mystic", "tier": 4, "cost": 4, "target": "foe_totem",
		"effects": [{"op": "status", "status": "doomed"}],
		"art": "a black sigil like a slowly closing eye hanging over a creature, three candles beneath it, one already out",
	},
	"clarity_tonic": {
		"kind": "rite", "name": "Clarity Tonic", "element": "any", "tier": 1, "cost": 1, "target": "ally",
		"effects": [{"op": "heal", "who": "target", "amount": 20}, {"op": "cure", "who": "target", "kind": "mind"}],
		"art": "a slim blue glass vial of clear sparkling water, a soft halo of light around it",
	},
	"cleansing_bell": {
		"kind": "rite", "name": "Cleansing Bell", "element": "any", "tier": 1, "cost": 1, "target": "ally",
		"effects": [{"op": "heal", "who": "target", "amount": 20}, {"op": "cure", "who": "target", "kind": "soul"}],
		"art": "a silver temple bell ringing, rings of white light washing away dark smoke",
	},
	"war_paint": {
		"kind": "rite", "name": "War Paint", "element": "any", "tier": 1, "cost": 1, "target": "ally",
		"effects": [{"op": "boon", "who": "target", "boon": "empowered"}],
		"art": "a clay pot of glowing red-ochre war paint, three fingers of paint smeared across a beast's brow",
	},
	"verdant_balm": {
		"kind": "rite", "name": "Verdant Balm", "element": "verdant", "tier": 1, "cost": 1, "target": "ally",
		"effects": [{"op": "boon", "who": "target", "boon": "regenerating"}],
		"art": "a wooden bowl of green moss balm glowing softly, tiny leaves sprouting from it",
	},
	"shadow_cloak": {
		"kind": "rite", "name": "Shadow Cloak", "element": "psychic", "tier": 1, "cost": 1, "target": "ally",
		"effects": [{"op": "boon", "who": "target", "boon": "veiled"}],
		"art": "a cloak of shimmering violet mist settling over a creature until only its eyes show",
	},
	"sanctify": {
		"kind": "rite", "name": "Sanctify", "element": "any", "tier": 2, "cost": 1, "target": "ally",
		"effects": [{"op": "boon", "who": "target", "boon": "blessed"}],
		"art": "a ring of golden sunlight descending onto a creature, motes of light settling on it like snow",
	},
	"quicken": {
		"kind": "rite", "name": "Quicken", "element": "storm", "tier": 1, "cost": 1, "target": "ally",
		"effects": [{"op": "boon", "who": "target", "boon": "hastened"}],
		"art": "crackling yellow lightning streaks wrapping a creature's legs, after-images trailing behind it",
	},
	# ===================================================== THE DISCARD (Phase B)
	"hour_of_need": {
		"kind": "rite", "name": "Hour of Need", "element": "any", "tier": 3, "cost": 1, "target": "none",
		"effects": [{"op": "call_legend_free"}],
		"art": "a lone duellist on one knee in a ruined circle, a great beast of light rising behind them out of the cracked stone",
	},
	"second_dawn": {
		"kind": "rite", "name": "Second Dawn", "element": "radiant", "tier": 1, "cost": 1, "target": "none",
		"effects": [{"op": "revive_hand"}],
		"art": "first light breaking over a field of fallen cards, one card lifting from the grass towards the sun",
	},
	"rekindle": {
		"kind": "rite", "name": "Rekindle", "element": "fire", "tier": 2, "cost": 3, "target": "none",
		"effects": [{"op": "revive_field", "max_tier": 2}],
		"art": "a pile of grey ash on a stone circle, one ember glowing at its heart and a small creature's shape rising out of the smoke",
	},
	"rite_of_ashes": {
		"kind": "rite", "name": "Rite of Ashes", "element": "any", "tier": 3, "cost": 2, "target": "all_foes",
		"damage": 40, "needs_ashes": 3,
		"art": "three urns of ash on an altar, their smoke twisting together into a single burning shape that sweeps across a duelling circle",
	},
	"kindred_seek": {
		"kind": "rite", "name": "Kindred Seek", "element": "any", "tier": 1, "cost": 1, "target": "none",
		"effects": [{"op": "seek_kindred"}],
		"art": "a fan of face-down cards spreading in the air, one glowing with the same colour as a creature standing below it",
	},
	# 28 October (synergy): the families' own Rites
	"pack_howl": {
		"kind": "rite", "name": "Pack Howl", "element": "any", "tier": 1, "cost": 1, "target": "none",
		"effects": [{"op": "buff_family", "family": "hound", "amount": 20}],
		"art": "three hounds of fire, steel and river water howling together at a lantern-lit sky, their breath mingling",
	},
	"call_of_kin": {
		"kind": "rite", "name": "Call of Kin", "element": "any", "tier": 1, "cost": 1, "target": "none",
		"effects": [{"op": "seek_family"}],
		"art": "a lantern held up in a dark wood, and in its light the eyes of a whole family of creatures shining back",
	},
	"memory_thread": {
		"kind": "rite", "name": "Memory Thread", "element": "psychic", "tier": 1, "cost": 0, "target": "none",
		"effects": [{"op": "discard_to_top"}],
		"art": "a violet thread of light pulling a single card up out of a pile of discarded ones and laying it on top of a deck",
	},
	# ================================================================= RELICS (Phase C)
	"ember_collar": {"kind": "relic", "name": "Ember Collar", "element": "fire", "tier": 1, "cost": 1, "relic": {"damage": 10},
		"art": "a collar of blackened iron links with a coal glowing in each, resting on charred velvet"},
	"tide_pearl": {"kind": "relic", "name": "Tide Pearl", "element": "tide", "tier": 1, "cost": 1, "relic": {"hp": 30},
		"art": "a sea-green pearl the size of a fist in an open shell, the sound of the sea drawn as rings of light"},
	"iron_brace": {"kind": "relic", "name": "Iron Brace", "element": "metal", "tier": 2, "cost": 2, "relic": {"dawn_shield": 20},
		"art": "a riveted iron bracer etched with a sunrise, a faint dome of light rising from it"},
	"thorn_crown": {"kind": "relic", "name": "Thorn Crown", "element": "verdant", "tier": 1, "cost": 1, "relic": {"keyword": "thorns"},
		"art": "a circlet of living briar with small white flowers between the thorns, on a mossy stone"},
	"storm_feather": {"kind": "relic", "name": "Storm Feather", "element": "storm", "tier": 2, "cost": 1, "relic": {"keyword": "galvanise"},
		"art": "a single long feather crackling with blue lightning, hanging in the air above a storm-grey cushion"},
	"veil_charm": {"kind": "relic", "name": "Veil Charm", "element": "psychic", "tier": 2, "cost": 1, "relic": {"keyword": "riposte"},
		"art": "a violet glass charm on a silver thread, a second faint copy of it floating just beside it"},
	"sun_medallion": {"kind": "relic", "name": "Sun Medallion", "element": "radiant", "tier": 2, "cost": 2, "relic": {"dawn_heal": 20},
		"art": "a gold medallion stamped with the sun, warm light pooling from it like honey"},
	"hunters_fang": {"kind": "relic", "name": "Hunter's Fang", "element": "venom", "tier": 2, "cost": 2,
		"relic": {"move": {"name": "Rend", "cost": 1, "damage": 30, "effects": [{"op": "status", "status": "bleed"}]}},
		"art": "a long curved fang bound with leather on a cord, a drop of green venom at its point"},
	"stone_heart": {"kind": "relic", "name": "Stone Heart", "element": "earth", "tier": 3, "cost": 2, "relic": {"keyword": "guardian"},
		"art": "a heart carved from grey granite, a slow amber light beating inside it"},
	"spirit_lantern": {"kind": "relic", "name": "Spirit Lantern", "element": "spirit", "tier": 1, "cost": 1, "relic": {"fall_draw": 2},
		"art": "a small paper lantern with a pale teal flame, a ribbon of light trailing from it into the dark"},
	"relic_hunt": {
		"kind": "rite", "name": "Relic Hunt", "element": "any", "tier": 1, "cost": 1, "target": "none",
		"effects": [{"op": "relic_hunt"}],
		"art": "a hand brushing dust from a half-buried relic in a ruin, lantern light on old gold",
	},
	# ================================================ THE NEW WAYS' TOTEMS (Phase E)
	# (shown as a tinted stand-in until their paintings and models come)
	"dawnling": {
		"kind": "totem", "name": "Dawnling", "element": "radiant", "tier": 1, "stage": 0, "cost": 1,
		"hp": 90, "affinity": "presence", "keywords": ["rally"], "attuned": {"min": 5, "hp": 20}, "stand_in": "emberwisp", "stand_in_tint": "f2cf5b",
		"moves": [
			{"name": "Glint", "cost": 0, "damage": 10},
			{"name": "Morning Ray", "cost": 1, "damage": 20, "effects": [{"op": "heal", "who": "allies", "amount": 10}]},
		],
		"art": "a small round sprite of warm sunlight with stubby wings and a halo of soft gold rays, cheerful and bright",
	},
	"river_hound": {
		# Tam Hayes's Totem (Master Script v6/v7): he calls her down every
		# morning; the player meets her in his friendly game, and sees her
		# torn apart by Krell's shadow hound that night
		"kind": "totem", "name": "River Hound", "element": "tide", "tier": 1, "stage": 0, "cost": 1,
		"hp": 100, "affinity": "resolve", "attuned": {"min": 5, "hp": 20}, "stand_in": "shieldhound", "stand_in_tint": "4a9fd8",
		"keywords": ["loyal"],
		"moves": [
			{"name": "Snap", "cost": 0, "damage": 10},
			{"name": "Mill-Race Bite", "cost": 1, "damage": 0, "fate": [
				{"to": 3, "damage": 0, "text": "Slips on the stones"},
				{"to": 12, "damage": 20},
				{"to": 99, "damage": 40}]},
		],
		"art": "a lean grey-blue hound made of running river water, a mill-race foam ruff at its neck, droplets flying as it lopes through reeds",
	},
	"hallowed_hound": {
		"kind": "totem", "name": "Hallowed Hound", "element": "spirit", "tier": 2, "stage": 0, "cost": 2,
		"hp": 130, "affinity": "resolve", "attuned": {"min": 5, "hp": 20}, "stand_in": "shieldhound", "stand_in_tint": "5fc4b2",
		"keywords": ["loyal"],
		"moves": [
			{"name": "Spirit Bite", "cost": 0, "damage": 20},
			{"name": "Grave Howl", "cost": 2, "damage": 40, "effects": [{"op": "status", "status": "terrified"}]},
		],
		"art": "a pale spectral hound with a glowing teal mane like candle smoke, a small lantern hanging from its collar",
	},
	"rimecub": {
		"kind": "totem", "name": "Rimecub", "element": "frost", "tier": 1, "stage": 0, "cost": 1,
		"hp": 90, "affinity": "resolve", "attuned": {"min": 5, "hp": 20}, "stand_in": "cinderpup", "stand_in_tint": "7cc8f0",
		"moves": [
			{"name": "Frost Nip", "cost": 0, "damage": 10},
			{"name": "Chill Breath", "cost": 1, "damage": 0, "fate": [
				{"to": 10, "damage": 20},
				{"to": 99, "damage": 20, "effects": [{"op": "status", "status": "frozen"}]}]},
		],
		"art": "a round white bear cub with frost-blue paws and icicle tufts on its ears, breathing a little cloud of snow",
	},
	"runeowl": {
		"kind": "totem", "name": "Runeowl", "element": "mystic", "tier": 2, "stage": 0, "cost": 2,
		"hp": 120, "affinity": "intellect", "keywords": ["combo"], "attuned": {"min": 5, "hp": 20}, "stand_in": "somnowl", "stand_in_tint": "5d63d9",
		"moves": [
			{"name": "Rune Talon", "cost": 0, "damage": 20},
			{"name": "Seal Sigil", "cost": 2, "damage": 30, "effects": [{"op": "status", "status": "silenced"}]},
		],
		"art": "an indigo owl with glowing rune marks on its wings, a ring of floating sigils turning round its head",
	},
	"starling": {
		"kind": "totem", "name": "Starling", "element": "astral", "tier": 1, "stage": 0, "cost": 1,
		"hp": 90, "affinity": "insight", "attuned": {"min": 5, "hp": 20}, "stand_in": "sparkkit", "stand_in_tint": "3f5fd6",
		"moves": [
			{"name": "Twinkle", "cost": 0, "damage": 10},
			{"name": "Falling Star", "cost": 1, "damage": 0, "fate": [
				{"to": 6, "damage": 10},
				{"to": 14, "damage": 30},
				{"to": 99, "damage": 50}]},
		],
		"art": "a small dark-blue fox kit whose fur is full of tiny glittering stars, its tail trailing light like a comet",
	},
	"duskstalker": {
		"kind": "totem", "name": "Duskstalker", "element": "umbral", "tier": 2, "stage": 0, "cost": 2,
		"hp": 130, "affinity": "cunning", "attuned": {"min": 5, "hp": 20}, "stand_in": "veilfox", "stand_in_tint": "6a4c9c",
		"moves": [
			{"name": "Shade Claw", "cost": 0, "damage": 20},
			{"name": "Night Pounce", "cost": 2, "damage": 50, "effects": [{"op": "pierce"}]},
		],
		"art": "a lean shadow panther with violet eyes, its edges dissolving into wisps of dusk",
	},
	# ==================================================== EACH WAY'S CARDS (Phase E)
	# (they work only while a Totem of the way's elements stands on your side)
	"stoke_the_coals": {
		"kind": "rite", "name": "Stoke the Coals", "element": "fire", "tier": 2, "cost": 1, "target": "none", "archetype": "burn_gamble",
		"effects": [{"op": "burned_damage", "amount": 20}],
		"art": "a pair of bellows blowing a bed of coals white-hot, flames leaping up off three burning shapes",
	},
	"loaded_dice": {
		"kind": "rite", "name": "Loaded Dice", "element": "storm", "tier": 1, "cost": 0, "target": "none", "archetype": "burn_gamble",
		"effects": [{"op": "fate_bonus", "amount": 3}, {"op": "draw", "count": 1}],
		"art": "a gold twenty-sided die crackling with lightning as it lands, its top face glowing",
	},
	"wildfire_pact": {
		"kind": "rite", "name": "Wildfire Pact", "element": "fire", "tier": 2, "cost": 2, "target": "none", "continuous": true, "archetype": "burn_gamble",
		"standing": {"burn_bonus": 10},
		"art": "two hands clasped over a burning contract, the fire spreading along its edges in a ring",
	},
	"deep_roots": {
		"kind": "rite", "name": "Deep Roots", "element": "verdant", "tier": 2, "cost": 3, "target": "none", "archetype": "outlast_heal",
		"effects": [{"op": "heal", "who": "allies", "amount": 20}, {"op": "shield_unhurt", "amount": 10}],
		"art": "great roots rising out of the ground and wrapping gently round three creatures, green light pulsing along them",
	},
	"tidal_reserve": {
		"kind": "rite", "name": "Tidal Reserve", "element": "tide", "tier": 2, "cost": 2, "target": "none", "continuous": true, "archetype": "outlast_heal",
		"standing": {"heal_life": 5},
		"art": "a still blue rock pool fed by a thin waterfall, its water glowing brighter as it fills",
	},
	"still_waters": {
		"kind": "rite", "name": "Still Waters", "element": "tide", "tier": 1, "cost": 2, "target": "none", "archetype": "outlast_heal",
		"effects": [{"op": "draw_full", "max": 2}],
		"art": "a perfectly calm lake at dawn reflecting two cards floating above it",
	},
	"counterweight": {
		"kind": "rite", "name": "Counterweight", "element": "metal", "tier": 2, "cost": 1, "target": "none", "archetype": "guard_counter",
		"answer": true, "answers": ["attack"], "effects": [{"op": "blunt", "amount": 20}],
		"art": "a heavy iron weight on a chain swinging into a charging beast, sparks flying where they meet",
	},
	"stone_patience": {
		"kind": "rite", "name": "Stone Patience", "element": "earth", "tier": 2, "cost": 1, "target": "foe_totem", "archetype": "guard_counter",
		"effects": [{"op": "guard_strike", "mult": 2}],
		"art": "a stone guardian that has stood still for an age finally swinging one great fist",
	},
	"bastion_banner": {
		"kind": "rite", "name": "Bastion Banner", "element": "earth", "tier": 2, "cost": 2, "target": "none", "continuous": true, "archetype": "guard_counter",
		"standing": {"guard_less": 10},
		"art": "a heavy grey banner on an iron pole driven into rock, a shield sigil glowing on it",
	},
	"unmasking": {
		"kind": "rite", "name": "Unmasking", "element": "psychic", "tier": 1, "cost": 1, "target": "none", "archetype": "veil_reveal",
		"effects": [{"op": "reveal_twice"}],
		"art": "a porcelain mask lifting away from a face of violet light, a second mask beneath it already cracking",
	},
	"whispering_shroud": {
		"kind": "rite", "name": "Whispering Shroud", "element": "psychic", "tier": 2, "cost": 1, "target": "none", "continuous": true, "archetype": "veil_reveal",
		"standing": {"reveal_draw": 1},
		"art": "a hooded cloak of violet mist standing empty, faint whispers drawn as curls of light around it",
	},
	"venom_mask": {
		"kind": "rite", "name": "Venom Mask", "element": "venom", "tier": 2, "cost": 1, "target": "none", "archetype": "veil_reveal",
		"effects": [{"op": "veil_call_free", "max_tier": 2}],
		"art": "a green lacquered mask dripping with venom, a creature's shape forming behind it in shadow",
	},
	"sunward_vow": {
		"kind": "rite", "name": "Sunward Vow", "element": "radiant", "tier": 2, "cost": 2, "target": "none", "archetype": "dawn_blessing",
		"effects": [{"op": "boon", "who": "allies", "boon": "blessed"}, {"op": "heal", "who": "allies", "amount": 10}],
		"art": "three creatures kneeling in a beam of morning light, a golden sigil of the sun above them",
	},
	"lantern_vigil": {
		"kind": "rite", "name": "Lantern Vigil", "element": "spirit", "tier": 2, "cost": 2, "target": "none", "continuous": true, "archetype": "dawn_blessing",
		"standing": {"fall_life": 20},
		"art": "a row of paper lanterns glowing teal along a dark path, one floating up into the night",
	},
	"kindled_soul": {
		"kind": "rite", "name": "Kindled Soul", "element": "spirit", "tier": 2, "cost": 2, "target": "none", "archetype": "dawn_blessing",
		"effects": [{"op": "revive_field", "max_tier": 3}],
		"art": "a ghostly creature rising from a lantern's flame back into solid form, teal light streaming off it",
	},
	"deep_winter": {
		"kind": "rite", "name": "Deep Winter", "element": "frost", "tier": 2, "cost": 2, "target": "none", "continuous": true, "archetype": "frost_stillness",
		"standing": {"frozen_extra": 20},
		"art": "a snowstorm swirling over a frozen duelling circle, a creature trapped in ice at its centre",
	},
	"shatter": {
		"kind": "rite", "name": "Shatter", "element": "frost", "tier": 2, "cost": 2, "target": "foe_totem", "archetype": "frost_stillness",
		"damage": 50, "needs_status": "frozen",
		"art": "a block of ice with a creature inside cracking apart in a burst of blue shards",
	},
	"glacial_ward": {
		"kind": "ward", "name": "Glacial Ward", "element": "frost", "tier": 2, "cost": 1, "trigger": "foe_attack", "archetype": "frost_stillness",
		"effects": [{"op": "status_attacker", "status": "frozen"}],
		"art": "a wall of blue ice rising in front of a small creature, a lunging beast freezing solid against it",
	},
	"constellation": {
		"kind": "rite", "name": "Constellation", "element": "astral", "tier": 1, "cost": 1, "target": "none", "archetype": "stars_shadow",
		"effects": [{"op": "pick_top", "count": 3}],
		"art": "three cards hanging in a night sky, joined by lines of starlight into a constellation",
	},
	"eclipse": {
		"kind": "rite", "name": "Eclipse", "element": "umbral", "tier": 2, "cost": 1, "target": "none", "continuous": true, "archetype": "stars_shadow",
		"standing": {"foe_fate_minus": 2},
		"art": "a black moon sliding across the sun over a duelling circle, a ring of violet fire around it",
	},
	"shadow_step": {
		"kind": "rite", "name": "Shadow Step", "element": "umbral", "tier": 1, "cost": 1, "target": "foe_totem", "archetype": "stars_shadow",
		"effects": [{"op": "status", "status": "blinded"}, {"op": "draw", "count": 1}],
		"art": "a figure stepping out of one shadow and into another behind a startled creature, violet smoke trailing",
	},
	# ======================================================= TERRAIN RITES (Phase D)
	# (each turns the Circle's ground to an element's arena for three turns)
	"flooded_circle": {
		"kind": "rite", "name": "Flooded Circle", "element": "tide", "tier": 2, "cost": 1, "target": "none",
		"effects": [{"op": "terrain", "arena": "tidegrove"}],
		"art": "sea water pouring over the rim of a stone duelling circle, reeds and lily pads rising as its floor becomes a tidal pool",
	},
	"forge_ground": {
		"kind": "rite", "name": "Forge Ground", "element": "fire", "tier": 2, "cost": 1, "target": "none",
		"effects": [{"op": "terrain", "arena": "emberforge"}],
		"art": "a stone duelling circle cracking open to glowing forge-fire beneath, anvils and chains rising round its edge",
	},
	"iron_ground": {
		"kind": "rite", "name": "Iron Ground", "element": "metal", "tier": 2, "cost": 1, "target": "none",
		"effects": [{"op": "terrain", "arena": "ironstone"}],
		"art": "riveted iron plates sliding over a duelling circle's floor like scales, great iron pillars rising at its edge",
	},
	"veilwild_mist": {
		"kind": "rite", "name": "Veilwild Mist", "element": "psychic", "tier": 2, "cost": 1, "target": "none",
		"effects": [{"op": "terrain", "arena": "veilwild"}],
		"art": "violet mist rolling over a duelling circle, twisted trees and watching eyes appearing in it",
	},
	"sunlit_court": {
		"kind": "rite", "name": "Sunlit Court", "element": "radiant", "tier": 2, "cost": 1, "target": "none",
		"effects": [{"op": "terrain", "arena": "solhaven"}],
		"art": "sunlight breaking through cloud onto a duelling circle, white marble steps and gold banners rising round it",
	},
	# ==================================================== CONTINUOUS RITES (Phase D)
	# (they stay on their side of the Circle, two a side, until unbound or replaced)
	"kindled_banner": {
		"kind": "rite", "name": "Kindled Banner", "element": "fire", "tier": 2, "cost": 2, "target": "none", "continuous": true,
		"standing": {"element_damage": true, "element": "fire", "amount": 10},
		"art": "a tall war banner of red cloth burning without being consumed, planted at the edge of a duelling circle",
	},
	"tidewell": {
		"kind": "rite", "name": "Tidewell", "element": "tide", "tier": 2, "cost": 2, "target": "none", "continuous": true,
		"standing": {"dawn_heal": 10},
		"art": "a small stone well brimming with glowing sea-green water, a mist of droplets drifting from it over a circle",
	},
	"iron_tithe": {
		"kind": "rite", "name": "Iron Tithe", "element": "metal", "tier": 2, "cost": 2, "target": "none", "continuous": true,
		"standing": {"foe_tax": 1},
		"art": "an iron collection box chained to a post, a rune-marked coin hovering over its slot",
	},
	"thorn_hedge": {
		"kind": "rite", "name": "Thorn Hedge", "element": "verdant", "tier": 2, "cost": 2, "target": "none", "continuous": true,
		"standing": {"thorn_all": true, "amount": 10},
		"art": "a low hedge of dark briars with white flowers ringing one side of a duelling circle, its thorns long as knives",
	},
	"storm_spire": {
		"kind": "rite", "name": "Storm Spire", "element": "storm", "tier": 2, "cost": 1, "target": "none", "continuous": true,
		"standing": {"storm_swift": true},
		"art": "a thin spire of black stone with lightning curling round its tip, the air around it bright with sparks",
	},
	"shadow_veil": {
		"kind": "rite", "name": "Shadow Veil", "element": "psychic", "tier": 2, "cost": 1, "target": "none", "continuous": true,
		"standing": {"free_veil": true},
		"art": "a curtain of violet shadow hanging in the air over a duelling circle, a creature's eyes glinting behind it",
	},
	"unbind": {
		"kind": "rite", "name": "Unbind", "element": "any", "tier": 2, "cost": 1, "target": "none",
		"effects": [{"op": "unbind"}],
		"art": "two hands pulling apart a knot of glowing cord, its light unravelling into the air",
	},
	# ========================================================== COUNTER RITES
	# (answers, played on the rival's turn: Phase A)
	"null_sigil": {
		"kind": "rite", "name": "Null Sigil", "element": "mystic", "tier": 3, "cost": 3, "target": "none",
		"answer": true, "answers": ["attack"], "effects": [{"op": "negate"}],
		"art": "an indigo sigil drawn in the air with one finger, a charging beast stopped dead against it as if against glass",
	},
	"ashen_shroud": {
		"kind": "rite", "name": "Ashen Shroud", "element": "fire", "tier": 2, "cost": 2, "target": "none",
		"answer": true, "answers": ["attack"], "effects": [{"op": "halve"}],
		"art": "a swirl of grey ash and dying embers wrapping round a creature like a cloak, a blow glancing off it",
	},
	"shieldwall_call": {
		"kind": "rite", "name": "Shieldwall Call", "element": "metal", "tier": 2, "cost": 1, "target": "none",
		"answer": true, "answers": ["attack"], "effects": [{"op": "redirect_guardian"}],
		"art": "an iron-shelled guardian beast stepping in front of a smaller creature, a war-horn's note drawn as rings of bronze light",
	},
	"undertow_glyph": {
		"kind": "rite", "name": "Undertow Glyph", "element": "tide", "tier": 2, "cost": 2, "target": "none",
		"answer": true, "answers": ["rite"], "effects": [{"op": "bounce_rite"}],
		"art": "a glowing green-blue glyph on wet stone, a spell's light being dragged back into it like water down a drain",
	},
	"quicksilver_step": {
		"kind": "rite", "name": "Quicksilver Step", "element": "storm", "tier": 1, "cost": 1, "target": "none",
		"answer": true, "answers": ["attack"], "effects": [{"op": "sidestep"}],
		"art": "a creature blurring sideways in a crackle of yellow lightning, a claw swiping through the after-image where it stood",
	},
	"root_toll": {
		"kind": "rite", "name": "Root Toll", "element": "verdant", "tier": 1, "cost": 0, "target": "none",
		"answer": true, "answers": ["call"], "effects": [{"op": "essence", "amount": 1}, {"op": "essence_next", "amount": 1}],
		"art": "pale roots rising from the earth round a newly summoned creature's feet, drinking motes of light from it into the soil",
	},
	"whisper_of_pages": {
		"kind": "rite", "name": "Whisper of Pages", "element": "psychic", "tier": 1, "cost": 0, "target": "none",
		"answer": true, "answers": ["ward"], "effects": [{"op": "draw", "count": 1}],
		"art": "a face-down card on a stone table, a violet whisper of light curling off it and turning the page of an open book nearby",
	},
	"rune_break": {
		"kind": "rite", "name": "Rune Break", "element": "earth", "tier": 2, "cost": 1, "target": "none",
		"answer": true, "answers": ["ward_spring"], "effects": [{"op": "cancel_ward"}],
		"art": "a stone fist cracking a glowing rune circle in two as it flares, its light going out along the fracture",
	},
	# ================================================================== WARDS
	"lightning_reflex": {
		"kind": "ward", "name": "Lightning Reflex", "element": "storm", "tier": 2, "cost": 1, "trigger": "foe_attack", "from_hand": true,
		"effects": [{"op": "status_attacker", "status": "shocked"}, {"op": "shield_target", "amount": 20}],
		"art": "a hand snapping up from a card fan with lightning between the fingers, a lunging beast jolted in mid-air",
	},
	"hushed_counter": {
		"kind": "ward", "name": "Hushed Counter", "element": "mystic", "tier": 3, "cost": 2, "trigger": "foe_rite", "from_hand": true,
		"effects": [{"op": "cancel_rite"}],
		"art": "a finger laid across lips wreathed in indigo light, a spell's glow going quiet mid-cast like a snuffed candle",
	},
	"ambush_snare": {
		"kind": "ward", "name": "Ambush Snare", "element": "any", "tier": 1, "cost": 1, "trigger": "foe_call",
		"effects": [{"op": "damage_called", "amount": 30}],
		"art": "a hidden snare of glowing rope springing up from the grass, runes flaring along its knots",
	},
	"vengeful_spirit": {
		"kind": "ward", "name": "Vengeful Spirit", "element": "spirit", "tier": 1, "cost": 1, "trigger": "ally_ko",
		"effects": [{"op": "damage_attacker", "amount": 40}],
		"art": "a pale teal ghost-hound rising from a fallen creature's body, eyes blazing with vengeance",
	},
	"riptide_snare": {
		"kind": "ward", "name": "Riptide Snare", "element": "tide", "tier": 2, "cost": 2, "trigger": "foe_call",
		"effects": [{"op": "bounce_called"}],
		"art": "a whirlpool opening under a creature's feet, dragging it back into a swirling portal of water",
	},
	"iron_bastion": {
		"kind": "ward", "name": "Iron Bastion", "element": "metal", "tier": 1, "cost": 1, "trigger": "foe_attack",
		"effects": [{"op": "shield_target", "amount": 60}],
		"art": "a massive iron tower shield slamming down in front of a duellist, sparks scattering off its face",
	},
	"mirror_veil": {
		"kind": "ward", "name": "Mirror Veil", "element": "psychic", "tier": 2, "cost": 2, "trigger": "foe_attack",
		"effects": [{"op": "negate"}, {"op": "damage_attacker", "amount": 20}],
		"art": "a shimmering veil of mirrored glass shards hanging in the air, reflecting an attacking beast back at itself",
	},
	"counter_rune": {
		"kind": "ward", "name": "Counter Rune", "element": "mystic", "tier": 2, "cost": 2, "trigger": "foe_rite",
		"effects": [{"op": "cancel_rite"}],
		"art": "a floating indigo rune circle snapping shut around a spell, unravelling it into harmless sparks",
	},
	"poison_trap": {
		"kind": "ward", "name": "Poison Trap", "element": "venom", "tier": 1, "cost": 1, "trigger": "foe_attack",
		"effects": [{"op": "status_attacker", "status": "poison"}],
		"art": "a patch of innocent flowers hiding needle-thorns that drip glowing violet poison",
	},
	"static_field": {
		"kind": "ward", "name": "Static Field", "element": "storm", "tier": 1, "cost": 1, "trigger": "foe_attack",
		"effects": [{"op": "status_attacker", "status": "shocked"}],
		"art": "a dome of crackling static over a duelling circle, a lunging beast jolted rigid by sparks",
	},
	"frost_snare": {
		"kind": "ward", "name": "Frost Snare", "element": "frost", "tier": 2, "cost": 2, "trigger": "foe_call",
		"effects": [{"op": "status_called", "status": "frozen"}],
		"art": "frost runes flashing up from the ground and freezing a newly summoned creature's feet to the stone",
	},
	"last_stand": {
		"kind": "ward", "name": "Last Stand", "element": "any", "tier": 4, "cost": 2, "trigger": "lethal",
		"effects": [{"op": "survive", "life": 20}],
		"art": "a battered duellist standing alone in a ring of golden light, cards raised, refusing to fall",
	},
}


const DECKS := {
	"emberstorm": {
		"name": "Emberstorm", "elements": ["fire", "storm"], "mascot": "cinderpup",
		"desc": "Fast Fire and Storm Totems that hit early, burn and gamble on Fate. Suits Might and Swiftness.",
		"attributes": {"might": 2, "swiftness": 2},
		"cards": {"cinderpup": 3, "blazehound": 2, "emberwisp": 3, "hearth_salamander": 2, "ashen_drake": 1,
			"sparkkit": 3, "voltlynx": 2, "thunder_ram": 2, "stormcaller": 1,
			"ember_collar": 1, "firebrand": 1, "thunderclap": 1, "rite_of_ashes": 1, "quicksilver_step": 1,
			"forge_ground": 1, "kindled_banner": 1, "ambush_snare": 1, "infernal_warg": 1, "pyraxis": 1, "travellers_pack": 1},
	},
	"tidegrove": {
		"name": "Tidegrove", "elements": ["tide", "verdant"], "mascot": "brookfin",
		"desc": "Tough Tide and Verdant Totems that heal, guard and outlast. Suits Resolve and Insight.",
		"attributes": {"resolve": 2, "insight": 2},
		"cards": {"brookfin": 3, "riptide_serpent": 2, "deepmaw": 1, "shellguard": 2,
			"mossling": 3, "thornwarden": 2, "bloomsprite": 3, "elderbark": 1,
			"healing_draught": 1, "tidal_surge": 1, "rejuvenate": 1, "seekers_compass": 1, "second_dawn": 1,
			"flooded_circle": 1, "thorn_hedge": 1,
			"riptide_snare": 1, "vengeful_spirit": 1, "thalassa": 1, "travellers_pack": 1, "tide_pearl": 1, "undertow_glyph": 1},
	},
	"ironstone": {
		"name": "Ironstone", "elements": ["earth", "metal"], "mascot": "pebblit",
		"desc": "Heavy Earth and Metal Guardians that wall off your Life and grind the enemy down. Suits Might and Resolve.",
		"attributes": {"might": 2, "resolve": 2},
		"cards": {"pebblit": 3, "boulderox": 2, "burrowmole": 3, "quarry_golem": 1,
			"brassback": 3, "ironhide": 2, "shieldhound": 3, "gilded_sentinel": 1,
			"bulwark": 1, "forge_edge": 1, "rekindle": 1, "healing_draught": 1, "crystal_vein": 1, "shieldwall_call": 1, "iron_tithe": 1,
			"iron_bastion": 2, "ironclad_behemoth": 1, "grondmaw": 1, "iron_brace": 1},
	},
	"veilwild": {
		"name": "Veilwild", "elements": ["psychic", "venom"], "mascot": "dreamfox",
		"desc": "Psychic and Venom tricksters: poison, sleep and face-down Wards. Suits Cunning and Insight.",
		"attributes": {"cunning": 2, "insight": 2},
		"cards": {"dreamfox": 3, "veilfox": 2, "somnowl": 2, "thought_eater": 1,
			"blightrat": 3, "plague_asp": 2, "mirewidow": 3,
			"mind_fog": 1, "toxic_mist": 1, "kindred_seek": 1, "siphon_rune": 1, "puppet_rune": 1, "shadow_veil": 1, "veilwild_mist": 1,
			"mirror_veil": 2, "ninefold_fox": 1, "poison_trap": 1, "somnara": 1,
			"whisper_of_pages": 1, "veil_charm": 1},
	},
}

## Decks the story's duellists play (not offered as starters or in the Lab).
const NPC_DECKS := {
	"dask_hounds": {
		"name": "Ironvault Hounds", "elements": ["metal", "earth", "venom"], "mascot": "shieldhound",
		"desc": "Hunter Dask's pack: metal hounds, burrowers, poison and traps.",
		"attributes": {"cunning": 1},
		"cards": {"shieldhound": 3, "brassback": 3, "ironhide": 2, "burrowmole": 2, "pebblit": 3, "boulderox": 1,
			"blightrat": 3, "plague_asp": 1,
			"jagged_shards": 2, "hunters_mark": 1, "pack_howl": 1, "healing_draught": 1, "essence_flask": 1, "rune_break": 1,
			"poison_trap": 2, "ambush_snare": 2, "iron_bastion": 1},
	},
	# Chapter 1, Solhaven (Master Script v3)
	"gate_watch": {
		"name": "The Gate Watch", "elements": ["metal", "earth"], "mascot": "brassback",
		"desc": "Warden Hale's Guardians: shells and shields that hold a gate, not take a field.",
		"attributes": {"resolve": 2, "presence": 1},
		"cards": {"brassback": 3, "ironhide": 2, "shieldhound": 3, "gilded_sentinel": 1, "shellguard": 2,
			"pebblit": 3, "boulderox": 1, "quarry_golem": 1,
			"bulwark": 2, "healing_draught": 2, "essence_flask": 2, "forge_edge": 1, "sanctify": 1, "lure_bell": 1,
			"clarity_tonic": 1, "travellers_pack": 1, "crystal_vein": 1,
			"iron_bastion": 2},
	},
	"pickpocket": {
		"name": "Pickpocket", "elements": ["psychic", "venom", "storm"], "mascot": "dreamfox",
		"desc": "Wren's deck: quick hands, tricks, poison and things that aren't where you left them.",
		"attributes": {"cunning": 2, "swiftness": 2},
		"cards": {"dreamfox": 3, "veilfox": 2, "blightrat": 3, "plague_asp": 1, "mirewidow": 2,
			"sparkkit": 3, "voltlynx": 1, "emberwisp": 2, "somnowl": 1,
			"mind_fog": 1, "shadow_cloak": 2, "quicken": 1, "corrosive_spit": 1, "confounding_chime": 1,
			"essence_flask": 2, "hex_mark": 1,
			"mirror_veil": 1, "poison_trap": 1, "ambush_snare": 1},
	},
	"golden_oath": {
		"name": "The Golden Oath", "elements": ["radiant", "metal", "fire"], "mascot": "gilded_sentinel",
		"desc": "Ser Aldric Vane's deck: the Gilded Sentinel that lets nothing past, his house's Sunlance Seraph, and the sun at his back.",
		"attributes": {"presence": 3, "resolve": 2},
		"cards": {"gilded_sentinel": 1, "sunlance_seraph": 1, "brassback": 3, "ironhide": 2, "shieldhound": 3,
			"pebblit": 2, "boulderox": 1, "hearth_salamander": 2, "cinderpup": 2, "blazehound": 1,
			"sanctify": 2, "healing_draught": 2, "forge_edge": 1, "essence_flask": 2, "crystal_vein": 1,
			"blinding_flare": 1,
			"iron_bastion": 2, "last_stand": 1},
	},
}

## Bonds (Phase C): two Totems, by their Basic, that stand together on the
## same side gain a bond move (both of them) or a stat (both of them).
const BONDS := [
	{"a": "cinderpup", "b": "sparkkit", "name": "Wildfire Dash",
		"move": {"name": "Wildfire Dash", "cost": 2, "damage": 40, "effects": [{"op": "status", "status": "burn"}]}},
	{"a": "emberwisp", "b": "hearth_salamander", "name": "Hearthlight", "hp": 20},
	{"a": "thunder_ram", "b": "ashen_drake", "name": "Storm of Cinders",
		"move": {"name": "Storm of Cinders", "cost": 3, "damage": 30, "target": "all_foes"}},
	{"a": "brookfin", "b": "shellguard", "name": "Riverwall", "hp": 20},
	{"a": "mossling", "b": "bloomsprite", "name": "Spring Rain",
		"move": {"name": "Spring Rain", "cost": 1, "damage": 20, "effects": [{"op": "heal", "who": "allies", "amount": 20}]}},
	{"a": "elderbark", "b": "stormcaller", "name": "Lightning Tree",
		"move": {"name": "Lightning Tree", "cost": 3, "damage": 70, "effects": [{"op": "status", "status": "shocked"}]}},
	{"a": "pebblit", "b": "brassback", "name": "Scrap and Stone",
		"move": {"name": "Scrap and Stone", "cost": 1, "damage": 30, "effects": [{"op": "shield", "who": "self", "amount": 20}]}},
	{"a": "burrowmole", "b": "shieldhound", "name": "Tunnel Ambush",
		"move": {"name": "Tunnel Ambush", "cost": 2, "damage": 40, "effects": [{"op": "pierce"}]}},
	{"a": "quarry_golem", "b": "gilded_sentinel", "name": "Twin Bastions", "damage": 10},
	{"a": "dreamfox", "b": "blightrat", "name": "Fever Dream",
		"move": {"name": "Fever Dream", "cost": 2, "damage": 20, "effects": [{"op": "status", "status": "sleep"}]}},
	{"a": "somnowl", "b": "mirewidow", "name": "Night Weavers", "damage": 10},
	{"a": "sunlance_seraph", "b": "sunmane_lion", "name": "Dawn Pride", "damage": 10},
	# 28 October (synergy): Tam's River Hound and the Brookfin, and the newer Totems
	{"a": "river_hound", "b": "brookfin", "name": "Flood",
		"move": {"name": "Flood", "cost": 3, "damage": 40, "target": "all_foes", "effects": [{"op": "status", "status": "soaked"}]}},
	{"a": "hallowed_hound", "b": "lantern_moth", "name": "Lantern Watch", "hp": 20},
	{"a": "rimecub", "b": "runeowl", "name": "Rime Runes",
		"move": {"name": "Rime Runes", "cost": 2, "damage": 30, "effects": [{"op": "status", "status": "frozen"}]}},
	{"a": "starling", "b": "duskstalker", "name": "Night Sky",
		"move": {"name": "Night Sky", "cost": 2, "damage": 40, "effects": [{"op": "status", "status": "blinded"}]}},
]


## The bond a Basic Totem is in, as it applies to that Totem: {partner, name,
## move | hp | damage}; {} for none. (Its first: since 28 October a Totem can
## be in more than one, bonds_of.)
static func bond_of(root_id: String) -> Dictionary:
	var all := bonds_of(root_id)
	return all[0] if not all.is_empty() else {}


## Every bond a Basic Totem is in, as bond_of gives one.
static func bonds_of(root_id: String) -> Array:
	var out := []
	for b in BONDS:
		if b.a == root_id or b.b == root_id:
			var one: Dictionary = b.duplicate(true)
			one["partner"] = b.b if b.a == root_id else b.a
			one.erase("a")
			one.erase("b")
			out.append(one)
	return out


## Every bond's words, one line each.
static func bonds_text(root_id: String) -> String:
	var lines := []
	for b in bonds_of(root_id):
		lines.append(_one_bond_text(root_id, b))
	return "\n".join(lines)


## "+20 HP for both" / "a bond move: Wildfire Dash (2 Essence, 40 damage, Burned)".
static func bond_text(root_id: String) -> String:
	return bonds_text(root_id)


static func _one_bond_text(root_id: String, b: Dictionary) -> String:
	if b.is_empty():
		return ""
	var with_name: String = CARDS[b.partner].name if CARDS.has(b.partner) else String(b.partner)
	if b.has("move"):
		var m: Dictionary = b.move
		var t := "%s and %s together: a bond move for both, %s (%s, %s)" % [CARDS[root_id].name, with_name, m.name,
			"free" if int(m.get("cost", 0)) == 0 else "%d Essence" % int(m.cost),
			outcome_text(int(m.get("damage", 0)), m.get("effects", []), m.get("target", "foe"))]
		return t + "."
	if b.has("hp"):
		return "%s and %s together: +%d HP for both (%s)." % [CARDS[root_id].name, with_name, int(b.hp), b.name]
	return "%s and %s together: +%d damage on every move for both (%s)." % [CARDS[root_id].name, with_name, int(b.damage), b.name]


## The words for a Relic.
static func relic_text(d: Dictionary) -> String:
	var r: Dictionary = d.get("relic", {})
	var what := ""
	if r.has("damage"): what = "its moves deal %d more damage" % int(r.damage)
	elif r.has("hp"): what = "+%d HP" % int(r.hp)
	elif r.has("keyword"): what = "it has %s (%s)" % [KEYWORDS[r.keyword].name, String(KEYWORDS[r.keyword].text).trim_suffix(".").to_lower()]
	elif r.has("dawn_heal"): what = "at your Dawn it heals %d" % int(r.dawn_heal)
	elif r.has("dawn_shield"): what = "at your Dawn it's shielded for %d" % int(r.dawn_shield)
	elif r.has("fall_draw"): what = "when it falls, you draw %d" % int(r.fall_draw)
	elif r.has("move"):
		var m: Dictionary = r.move
		what = "a new move, %s (%d Essence: %s)" % [m.name, int(m.get("cost", 0)), outcome_text(int(m.get("damage", 0)), m.get("effects", []), m.get("target", "foe"))]
	return "Give it to one of your Totems (one Relic each): %s. It stays until the Totem falls, then goes to your discard." % what


const TIER_MAX_COPIES := [0, 3, 3, 2, 1, 1, 1, 1]

const KEYWORDS := {
	"guardian": {"name": "Guardian", "text": "While it stands, enemies can't attack your Life directly."},
	"swift": {"name": "Swift", "text": "Can attack on the turn it's called."},
	"channel": {"name": "Channel", "text": "+1 Essence on the turn it's called."},
	"thorns": {"name": "Thorns", "text": "A Totem that attacks it takes 10 damage."},
	"harvest": {"name": "Harvest", "text": "+1 Essence when it knocks out a Totem."},
	"burrow": {"name": "Burrow", "text": "Can attack Life even when the slot opposite is filled."},
	"echo": {"name": "Echo", "text": "Acts once from your discard when another of your Totems falls."},
	"loyal": {"name": "Loyal", "text": "When a Totem of yours falls, it calls itself from your hand into the empty slot, free."},
	"rekindle": {"name": "Rekindling", "text": "Once a duel, at your Dawn, it comes back from your discard to an empty slot with half its HP."},
	"riposte": {"name": "Riposte", "text": "When it's hit and still standing, the attacker is Confused."},
	"galvanise": {"name": "Galvanise", "text": "When it's hit and still standing, it becomes Empowered."},
	"reveal": {"name": "Reveal", "text": "Called veiled, it does something when it's turned face up."},
	# (28 October: what a Totem does for the Totems beside it, and the chain)
	"shelter": {"name": "Shelter", "text": "The Totems beside it take 10 less from every attack."},
	"rally": {"name": "Rally", "text": "The Totems beside it deal 10 more damage."},
	"tend": {"name": "Tend", "text": "At your Dawn, the Totems beside it heal 10."},
	"combo": {"name": "Combo", "text": "Does more as the third card or later you play in a turn."},
}


## What a keyword does on this card (an Echo's own words).
static func keyword_text(k: String, d: Dictionary) -> String:
	if k == "combo":
		return DuelSynergy.combo_text(d)
	if k == "echo" and d.has("echo"):
		return "Once a duel, when another of your Totems falls, from your discard: %s" % echo_text(d)
	if k == "reveal" and d.has("reveal"):
		var rv: Dictionary = d.reveal
		var what := ""
		match String(rv.get("op", "")):
			"status_across": what = "the Totem across from it is %s" % STATUS_NAMES.get(rv.status, rv.status)
			"damage_across": what = "it deals %d damage to the Totem across from it" % int(rv.amount)
			"draw": what = "you draw %d" % int(rv.get("count", 1))
			"heal_allies": what = "your Totems heal %d" % int(rv.amount)
		return "Called veiled (face down, +1 Essence), when it's turned face up: %s." % what
	return String(KEYWORDS.get(k, {}).get("text", ""))


static func echo_text(d: Dictionary) -> String:
	var e: Dictionary = d.get("echo", {})
	match String(e.get("op", "")):
		"damage_attacker": return "deal %d damage to the Totem that felled it." % int(e.amount)
		"status_attacker": return "the Totem that felled it is %s." % STATUS_NAMES.get(e.status, e.status)
		"heal_weakest": return "heal %d damage from your most hurt Totem." % int(e.amount)
		"shield_one": return "shield your weakest Totem for %d." % int(e.amount)
		"essence_next": return "gain %d Essence at your next turn." % int(e.amount)
	return ""

const STATUS_NAMES := DuelConditions.NAMES

## Divine Gift wording for the v1 duel (numbers come from DuelRules).
static func gift_text(g: String) -> String:
	match g:
		"dawns_mercy": return "Heal %d damage from one of your Totems and clear its conditions." % DuelRules.mercy_heal
		"wrath": return "Your Totems deal %d more damage this turn." % DuelRules.wrath_bonus
		"stillness": return "Stun up to two enemy Totems."
		"tempest": return "Gain %d Essence this turn. Totems you call this turn are Swift, and Shifting is free." % DuelRules.tempest_essence
		"whisper": return "See your opponent's hand and Wards, then discard two cards from their hand."
		"foresight": return "Draw 2 cards. Your next Fate roll counts as a natural 20."
		"recall": return "Return up to 2 cards from your discard pile to your hand."
		"unbound": return "Draw 2 cards."
		"contagion": return "Every enemy Totem takes 10 damage and is Poisoned."
		"regrowth": return "Heal 40 damage from every one of your Totems and clear their Body conditions."
		"undertow": return "Sweep every enemy Totem back to its owner's hand; any Ascension cards on them are discarded."
		"star_chart": return "Draw any two of your top 5 cards. +2 on your Fate rolls this turn."
		"forged_guard": return "Shield each of your Totems for 30, and double your Guard until your next Dawn."
		"unveil": return "Turn every enemy Ward face up, then destroy one."
	return ""


const TRIGGER_TEXT := {
	"foe_attack": "When an enemy Totem attacks",
	"foe_direct": "When an enemy Totem attacks your Life",
	"foe_call": "When your opponent calls a Totem",
	"foe_rite": "When your opponent casts a Rite or calls down a Summon",
	"ally_ko": "When one of your Totems is knocked out",
	"lethal": "When your Life would drop to 0",
}


# ------------------------------------------------------------------ decks ---

static func card_list(deck_id: String) -> Array:
	var out := []
	var d: Dictionary = DECKS[deck_id] if DECKS.has(deck_id) else (NPC_DECKS[deck_id] if NPC_DECKS.has(deck_id) else DuelArchetypes.DECKS[deck_id])
	for id in d.cards:
		for i in int(d.cards[id]):
			out.append(id)
	return out


## Returns a list of problems with a deck (empty when the deck is legal).
static func deck_problems(cards: Array) -> Array:
	var problems := []
	if cards.size() != DuelRules.deck_size:
		problems.append("A deck needs exactly %d cards (this one has %d)." % [DuelRules.deck_size, cards.size()])
	var counts := {}
	for id in cards:
		if not CARDS.has(id):
			problems.append("Unknown card: %s" % id)
			continue
		counts[id] = int(counts.get(id, 0)) + 1
	var big := 0
	var basics := 0
	for id in counts:
		var d: Dictionary = CARDS[id]
		var tier := int(d.get("tier", 1))
		if tier >= 6:
			big += counts[id]
		if d.kind == "totem" and int(d.get("stage", 0)) == 0:
			basics += counts[id]
		var limit: int = TIER_MAX_COPIES[tier]
		if counts[id] > limit:
			problems.append("Only %d copies of a Tier %s card are allowed (%s)." % [limit, Lore.TIER_NAMES[tier], d.name])
		if d.kind == "totem" and int(d.get("stage", 0)) > 0 and not counts.has(d.ascends_from):
			problems.append("%s needs %s in the deck." % [d.name, CARDS[d.ascends_from].name])
	if big > 1:
		problems.append("Only one Demigod or Divine card per deck.")
	if basics < 6:
		problems.append("A deck needs at least 6 Basic Totems.")
	return problems


# ---------------------------------------------------------------- queries ---

static func is_basic_totem(id: String) -> bool:
	var d: Dictionary = CARDS[id]
	return d.kind == "totem" and int(d.get("stage", 0)) == 0


static func is_ascension(id: String) -> bool:
	var d: Dictionary = CARDS[id]
	return d.kind == "totem" and int(d.get("stage", 0)) > 0


static func stage_name(stage: int) -> String:
	return ["Basic", "Ascended", "Exalted"][clampi(stage, 0, 2)]


# ---------------------------------------------------------------- wording ---

## Words for a Fate band's range, e.g. "2-9" or "20+".
static func band_range(bands: Array, i: int) -> String:
	var lo := 1 if i == 0 else int(bands[i - 1].to) + 1
	var hi := int(bands[i].to)
	if i == bands.size() - 1:
		return "%d+" % lo
	if lo == hi:
		return str(lo)
	return "%d-%d" % [lo, hi]


## One line describing what a band (or a move without Fate) does.
static func outcome_text(damage: int, effects: Array, target: String = "foe", fallback: String = "") -> String:
	var parts := []
	if damage > 0:
		if target == "all_foes":
			parts.append("%d to each foe" % damage)
		else:
			parts.append(str(damage))
	for e in effects:
		var t := effect_text(e)
		if t != "":
			parts.append(t)
	if parts.is_empty():
		return fallback if fallback != "" else "No effect"
	var s := ", ".join(parts)
	return s


static func effect_text(e: Dictionary) -> String:
	match e.op:
		"status":
			return STATUS_NAMES.get(e.status, e.status)
		"boon":
			return STATUS_NAMES.get(e.boon, e.boon)
		"cure":
			return "clear %s conditions" % _kind_word(e.get("kind", "all"))
		"heal":
			match e.get("who", "self"):
				"self": return "heal itself %d" % e.amount
				"target": return "heal %d" % e.amount
				"allies": return "heal your Totems %d" % e.amount
		"splash_random":
			return "%d to another foe" % e.amount
		"self_damage":
			return "%d to itself" % e.amount
		"shield":
			return "shield %d" % e.amount
		"discard_random":
			return "they discard a card"
		"bonus_if_status":
			return "+%d if %s" % [e.amount, STATUS_NAMES.get(e.status, e.status)]
		"draw":
			return "draw %d" % e.count
		"essence":
			return "+%d Essence this turn" % e.amount
		"essence_max":
			return "+%d Essence every turn" % e.amount
		"life":
			return "+%d Life" % e.amount
		"pierce":
			return "spill-over ignores Guard"
		"stun_others":
			return "Stun every other foe"
		"drain":
			return "gain Life equal to the damage"
	return ""


## Rules text for a Rite, Ward or Summon.
static func card_text(id: String) -> String:
	var d: Dictionary = CARDS[id]
	var combo := DuelSynergy.combo_text(d) if d.kind != "totem" else ""
	var tail := (" " + combo) if combo != "" else ""   # (28 October: Combo)
	if d.has("archetype"):
		# (Phase E: a way's card works only with its Totems on the field)
		return "%s, with %s of yours on the field. %s%s" % [DuelArchetypes.arch_name(d.archetype),
			DuelArchetypes.need_text(d.archetype), _plain_text(id), tail]
	return _plain_text(id) + tail


static func _plain_text(id: String) -> String:
	var d: Dictionary = CARDS[id]
	match d.kind:
		"rite":
			if d.get("answer", false):
				return "Answer, when %s: %s" % [_answers_text(d), _rite_text(d)]
			return _rite_text(d)
		"ward":
			var w := "%s: %s." % [TRIGGER_TEXT.get(d.trigger, d.trigger), _ward_text(d)]
			if d.get("from_hand", false):
				w += " Can be played from your hand in answer, once a duel."
			return w
		"summon":
			var m: Dictionary = d.move
			return "Descends, then returns to the heavens. %s: %s." % [m.name, _cap(outcome_text(int(m.damage), m.get("effects", []), m.get("target", "foe_totem")))]
		"relic":
			return relic_text(d)
	return ""


## What a Continuous Rite's standing effect does (Phase D).
static func standing_text(st: Dictionary) -> String:
	if st.has("element_damage"):
		return "Your %s Totems deal %d more damage" % [String(st.element).capitalize(), int(st.amount)]
	if st.has("dawn_heal"):
		return "At your Dawn, heal %d damage from each of your Totems" % int(st.dawn_heal)
	if st.has("foe_tax"):
		return "Your rival's Wards and Rites cost %d more Essence" % int(st.foe_tax)
	if st.has("thorn_all"):
		return "A Totem that attacks one of yours takes %d damage" % int(st.amount)
	if st.has("storm_swift"):
		return "Your Storm Totems can attack the turn they're called"
	if st.has("free_veil"):
		return "Your first Totem each turn can be called veiled at no extra cost"
	if st.has("burn_bonus"):
		return "Burn deals %d more to your rival's Totems" % int(st.burn_bonus)
	if st.has("heal_life"):
		return "Whenever one of your Totems is healed, gain %d Life" % int(st.heal_life)
	if st.has("guard_less"):
		return "Your Totems in Guard take %d less from every blow" % int(st.guard_less)
	if st.has("reveal_draw"):
		return "When one of your Totems is revealed, draw a card"
	if st.has("fall_life"):
		return "When one of your Totems falls, gain %d Life and draw a card" % int(st.fall_life)
	if st.has("frozen_extra"):
		return "Frozen enemy Totems take %d more damage from your attacks" % int(st.frozen_extra)
	if st.has("foe_fate_minus"):
		return "Your rival's Fate rolls are %d lower" % int(st.foe_fate_minus)
	return ""


static func _rite_text(d: Dictionary) -> String:
	if d.has("needs_status") and int(d.get("damage", 0)) > 0:
		return "Deal %d damage to a %s enemy Totem." % [int(d.damage), String(STATUS_NAMES.get(d.needs_status, d.needs_status))]
	if bool(d.get("continuous", false)):
		return "Stands on your side of the Circle (two at most) until it's unbound or replaced: %s." % standing_text(d.get("standing", {}))
	var dmg := int(d.get("damage", 0))
	var parts := []
	if int(d.get("needs_ashes", 0)) > 0:
		parts.append("Needs %d Totems of one element in your discard" % int(d.needs_ashes))
	if dmg > 0:
		if d.target == "all_foes":
			parts.append("Deal %d damage to each enemy Totem" % dmg)
		else:
			parts.append("Deal %d damage to an enemy Totem" % dmg)
	for e in d.get("effects", []):
		match e.op:
			"essence": parts.append(("Gain %d Essence now" if d.get("answer", false) else "Gain %d Essence this turn") % e.amount)
			"essence_max": parts.append("Your Essence limit rises by %d for the rest of the duel" % e.amount)
			"heal": parts.append(("Heal %d damage from each of your Totems" if e.get("who", "target") == "allies" else "Heal %d damage from one of your Totems") % e.amount)
			"cure":
				var kw := _kind_word(e.get("kind", "all"))
				parts.append("clear its conditions" if kw == "all" else "clear its %s conditions" % kw)
			"boon":
				if e.get("who", "target") == "allies":
					parts.append("Your Totems become %s" % STATUS_NAMES[e.boon])
				else:
					parts.append("One of your Totems becomes %s (%s)" % [STATUS_NAMES[e.boon], DuelConditions.describe(e.boon).trim_suffix(".").to_lower()])
			"draw": parts.append("Draw a card" if int(e.count) == 1 else "Draw %d cards" % e.count)
			"search_totem": parts.append("Search your deck for a Basic Totem and put it in your hand")
			"move_foe": parts.append("Move an enemy Totem to an empty slot on their side")
			"bounce": parts.append("Return an enemy Totem to its owner's hand")
			"life": parts.append("Gain %d Life" % e.amount)
			"shield": parts.append("Shield one of your Totems: prevent the next %d damage to it" % e.amount)
			"buff": parts.append("One of your Totems deals %d more damage this turn" % e.amount)
			"status":
				if d.target == "all_foes":
					parts.append(("they are all %s" if dmg > 0 else "Every enemy Totem is %s") % STATUS_NAMES[e.status])
				elif dmg > 0:
					parts.append("it is %s" % STATUS_NAMES[e.status])
				else:
					parts.append("An enemy Totem is %s" % STATUS_NAMES[e.status])
			"drain": parts.append("gain Life equal to the damage dealt")
			"negate": parts.append("cancel it")
			"halve": parts.append("it deals half its damage")
			"redirect_guardian": parts.append("one of your Guardians takes the blow instead")
			"bounce_rite": parts.append("it returns to their hand, undone (the Essence stays spent)")
			"sidestep": parts.append("the Totem attacked swaps slots with another of yours, and the blow lands on whatever stands there now")
			"essence_next": parts.append("%d more at your next turn" % e.amount)
			"cancel_ward": parts.append("the Ward is spent for nothing")
			"revive_hand": parts.append("Return a Basic Totem from your discard to your hand")
			"revive_field": parts.append("Call a Basic Totem of tier %d or lower from your discard into an empty slot, with half its HP" % int(e.get("max_tier", 2)))
			"call_legend_free": parts.append("While your Life is lower than your opponent's, call a Legend Totem from your hand into an empty slot, free and without a Tribute")
			"seek_kindred": parts.append("Search your deck for a Totem that shares an element with one of yours on the field")
			"seek_family": parts.append("Search your deck for a Totem of a family you have on the field")
			"buff_family": parts.append("Your %s deal %d more damage this turn" % [DuelSynergy.family_plural(String(e.family)), int(e.amount)])
			"discard_to_top": parts.append("Put a card from your discard on top of your deck")
			"relic_hunt": parts.append("Return a Relic from your discard to your hand")
			"terrain": parts.append("The Circle becomes %s for %d turns (%s)" % [String(e.arena).capitalize(), DuelRules.terrain_turns,
				String(DuelGame.ARENA_RULES.get(e.arena, "")).trim_suffix(".").to_lower()])
			"unbind": parts.append("Send one of your rival's standing Rites to their discard")
			"burned_damage": parts.append("Each Burned enemy Totem takes %d damage" % int(e.amount))
			"fate_bonus": parts.append("Your Fate rolls are %d higher this turn" % int(e.amount))
			"shield_unhurt": parts.append("each of your Totems left unhurt is shielded from the next %d damage" % int(e.amount))
			"draw_full": parts.append("Draw a card for each of your Totems that is unhurt (%d at most)" % int(e.get("max", 2)))
			"blunt": parts.append("it deals %d less, and the attacker takes %d" % [int(e.amount), int(e.amount)])
			"guard_strike": parts.append("Deal damage to an enemy Totem equal to %s your Guard" % ("twice" if int(e.get("mult", 1)) == 2 else "%d times" % int(e.get("mult", 1))))
			"reveal_twice": parts.append("Turn your veiled Totems face up now, each Reveal happening twice")
			"veil_call_free": parts.append("Call a Basic Totem of tier %d or lower from your hand into an empty slot, veiled and free" % int(e.get("max_tier", 2)))
			"pick_top": parts.append("Look at your top %d cards and put one in your hand" % int(e.get("count", 3)))
	return ", and ".join(parts).replace(", and clear", " and clear") + "."


static func _answers_text(d: Dictionary) -> String:
	var parts := []
	for k in d.get("answers", []):
		parts.append(String(DuelGame.EVENT_TEXT.get(k, k)))
	return " or ".join(parts)


static func _ward_text(d: Dictionary) -> String:
	var parts := []
	for e in d.effects:
		match e.op:
			"damage_called": parts.append("deal %d damage to that Totem" % e.amount)
			"bounce_called": parts.append("return that Totem to their hand")
			"damage_attacker": parts.append("deal %d damage to the attacker" % e.amount)
			"status_attacker": parts.append("the attacker is %s" % STATUS_NAMES[e.status])
			"status_called": parts.append("that Totem is %s" % STATUS_NAMES[e.status])
			"negate": parts.append("cancel the attack")
			"block_life": parts.append("prevent all damage to your Life from it")
			"shield_target": parts.append("the attack deals %d less damage" % e.amount)
			"cancel_rite": parts.append("cancel it")
			"survive": parts.append("you survive with %d Life" % e.life)
	return " and ".join(parts)


static func _kind_word(kind: String) -> String:
	if kind == "" or kind == "all":
		return "all"
	return DuelConditions.KIND_NAMES.get(kind, kind)


static func _cap(s: String) -> String:
	if s.is_empty():
		return s
	return s.substr(0, 1).to_upper() + s.substr(1)
