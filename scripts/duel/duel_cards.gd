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

const CARDS := {
	# =================================================================== FIRE
	"cinderpup": {
		"kind": "totem", "name": "Cinderpup", "element": "fire", "tier": 1, "stage": 0, "cost": 1,
		"hp": 50, "affinity": "might", "attuned": {"min": 5, "damage": 10},
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
		"ascends_from": "cinderpup", "cost": 2, "hp": 90, "affinity": "might",
		"attuned": {"min": 5, "damage": 10}, "keywords": ["harvest"],
		"moves": [
			{"name": "Flame Fang", "cost": 0, "damage": 30},
			{"name": "Inferno Rush", "cost": 2, "damage": 50, "effects": [{"op": "status", "status": "burn"}]},
		],
		"art": "a lean wolfhound wreathed in roaring flame, a mane of fire, molten cracks along its body, lunging forward",
	},
	"emberwisp": {
		"kind": "totem", "name": "Emberwisp", "element": "fire", "tier": 1, "stage": 0, "cost": 1,
		"hp": 40, "affinity": "swiftness", "keywords": ["swift"], "attuned": {"min": 5, "damage": 10},
		"moves": [
			{"name": "Spark", "cost": 0, "damage": 10},
			{"name": "Kindle", "cost": 1, "damage": 10, "target": "foe_totem",
				"effects": [{"op": "status", "status": "burn"}]},
		],
		"art": "a tiny floating spark spirit with a candle-flame body, wide curious eyes, trailing glowing cinders",
	},
	"hearth_salamander": {
		"kind": "totem", "name": "Hearth Salamander", "element": "fire", "tier": 1, "stage": 0, "cost": 2,
		"hp": 60, "affinity": "presence", "keywords": ["channel"], "attuned": {"min": 5, "hp": 20},
		"moves": [
			{"name": "Tail Whip", "cost": 0, "damage": 20},
			{"name": "Fire Spit", "cost": 1, "damage": 30},
		],
		"art": "a plump orange salamander curled in a hearth of glowing coals, little flames dancing along its spine, sleepy content smile",
	},
	"ashen_drake": {
		"kind": "totem", "name": "Ashen Drake", "element": "fire", "tier": 3, "stage": 0, "cost": 4,
		"hp": 110, "affinity": "might", "attuned": {"min": 6, "damage": 20},
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
		"hp": 50, "affinity": "swiftness", "attuned": {"min": 6, "damage": 10},
		"moves": [
			{"name": "Zap", "cost": 0, "damage": 10},
			{"name": "Crackle", "cost": 1, "damage": 0, "fate": [
				{"to": 1, "damage": 0, "text": "Miss"},
				{"to": 11, "damage": 20},
				{"to": 19, "damage": 30, "effects": [{"op": "status", "status": "stun"}]},
				{"to": 99, "damage": 50, "effects": [{"op": "status", "status": "stun"}]}]},
		],
		"art": "a small indigo fox kit with crackling yellow lightning along its ears and a bolt-shaped tail",
	},
	"voltlynx": {
		"kind": "totem", "name": "Voltlynx", "element": "storm", "tier": 2, "stage": 1,
		"ascends_from": "sparkkit", "cost": 2, "hp": 90, "affinity": "swiftness", "keywords": ["swift"],
		"moves": [
			{"name": "Thunder Claw", "cost": 0, "damage": 30},
			{"name": "Chain Lightning", "cost": 2, "damage": 30, "target": "foe_totem",
				"effects": [{"op": "splash_random", "amount": 20}]},
		],
		"art": "a lynx with deep indigo fur and ear tufts sparking with electricity, a jagged lightning mane, snarling",
	},
	"thunder_ram": {
		"kind": "totem", "name": "Thunder Ram", "element": "storm", "tier": 2, "stage": 0, "cost": 3,
		"hp": 80, "affinity": "might", "keywords": ["swift"],
		"moves": [
			{"name": "Headbutt", "cost": 0, "damage": 20},
			{"name": "Thunder Charge", "cost": 2, "damage": 60, "effects": [{"op": "self_damage", "amount": 20}]},
		],
		"art": "a charging ram with storm-grey wool crackling with static, curled horns glowing electric blue, sparks under its hooves",
	},
	"stormcaller": {
		"kind": "totem", "name": "Stormcaller Heron", "element": "storm", "tier": 3, "stage": 0, "cost": 4,
		"hp": 100, "affinity": "intellect", "attuned": {"min": 6, "cost": 1},
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
		"hp": 60, "affinity": "resolve", "attuned": {"min": 5, "hp": 20},
		"moves": [
			{"name": "Splash", "cost": 0, "damage": 10},
			{"name": "Undertow", "cost": 1, "damage": 30, "effects": [{"op": "heal", "who": "self", "amount": 10}]},
		],
		"art": "a small river serpent with translucent blue fins and pebble-smooth scales, curled in a splash of clear water",
	},
	"riptide_serpent": {
		"kind": "totem", "name": "Riptide Serpent", "element": "tide", "tier": 2, "stage": 1,
		"ascends_from": "brookfin", "cost": 2, "hp": 110, "affinity": "resolve", "attuned": {"min": 5, "hp": 20},
		"moves": [
			{"name": "Water Lash", "cost": 0, "damage": 30},
			{"name": "Riptide", "cost": 2, "damage": 60, "effects": [{"op": "heal", "who": "self", "amount": 20}]},
		],
		"art": "a long sea serpent coiling through a crashing wave, fins like torn sails, eyes glowing deep blue",
	},
	"deepmaw": {
		"kind": "totem", "name": "Deepmaw Leviathan", "element": "tide", "tier": 3, "stage": 2,
		"ascends_from": "riptide_serpent", "cost": 3, "hp": 170, "affinity": "resolve", "attuned": {"min": 6, "hp": 30},
		"moves": [
			{"name": "Crushing Tide", "cost": 0, "damage": 40},
			{"name": "Maelstrom", "cost": 3, "damage": 90},
		],
		"art": "a colossal sea leviathan rising from a whirlpool, barnacled armour plates, a jaw wide enough to swallow ships",
	},
	"shellguard": {
		"kind": "totem", "name": "Shellguard", "element": "tide", "tier": 1, "stage": 0, "cost": 2,
		"hp": 90, "affinity": "resolve", "keywords": ["guardian"],
		"moves": [
			{"name": "Shell Slam", "cost": 0, "damage": 20},
			{"name": "Withdraw", "cost": 1, "damage": 0, "target": "none",
				"effects": [{"op": "shield", "who": "self", "amount": 40}]},
		],
		"art": "a sturdy turtle with a coral-covered shell and a calm wise face, water droplets beading on its shell",
	},
	# ================================================================ VERDANT
	"mossling": {
		"kind": "totem", "name": "Mossling", "element": "verdant", "tier": 1, "stage": 0, "cost": 1,
		"hp": 60, "affinity": "resolve", "attuned": {"min": 5, "hp": 20},
		"moves": [
			{"name": "Sap", "cost": 0, "damage": 10, "effects": [{"op": "heal", "who": "self", "amount": 10}]},
			{"name": "Vine Snare", "cost": 1, "damage": 0, "target": "foe_totem", "fate": [
				{"to": 10, "damage": 20},
				{"to": 99, "damage": 20, "effects": [{"op": "status", "status": "stun"}]}]},
		],
		"art": "a small round forest creature covered in soft moss, a sprout growing from its head, big gentle eyes",
	},
	"thornwarden": {
		"kind": "totem", "name": "Thornwarden", "element": "verdant", "tier": 2, "stage": 1,
		"ascends_from": "mossling", "cost": 2, "hp": 110, "affinity": "resolve", "keywords": ["thorns"],
		"attuned": {"min": 5, "hp": 20},
		"moves": [
			{"name": "Barbed Lash", "cost": 0, "damage": 20, "effects": [{"op": "status", "status": "poison"}]},
			{"name": "Wild Growth", "cost": 2, "damage": 50, "effects": [{"op": "heal", "who": "self", "amount": 20}]},
		],
		"art": "a bear-like guardian made of woven roots and thorny vines, flowers blooming on its shoulders, protective stance",
	},
	"bloomsprite": {
		"kind": "totem", "name": "Bloomsprite", "element": "verdant", "tier": 1, "stage": 0, "cost": 1,
		"hp": 40, "affinity": "insight", "keywords": ["channel"], "attuned": {"min": 5, "draw": 1},
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
		"hp": 150, "affinity": "resolve", "keywords": ["guardian"], "attuned": {"min": 6, "hp": 30},
		"moves": [
			{"name": "Root Slam", "cost": 0, "damage": 30},
			{"name": "Ancient Grasp", "cost": 3, "damage": 70, "effects": [{"op": "status", "status": "stun"}]},
		],
		"art": "an ancient walking tree with a bark face, moss beard and glowing sap veins, roots dragging like feet",
	},
	# ================================================================== EARTH
	"pebblit": {
		"kind": "totem", "name": "Pebblit", "element": "earth", "tier": 1, "stage": 0, "cost": 1,
		"hp": 60, "affinity": "might", "attuned": {"min": 5, "damage": 10},
		"moves": [
			{"name": "Pebble Toss", "cost": 0, "damage": 10},
			{"name": "Rock Smash", "cost": 1, "damage": 30},
		],
		"art": "a round pebble creature with little stubby arms, a teal crystal growing from its head, cheerful face",
	},
	"boulderox": {
		"kind": "totem", "name": "Boulderox", "element": "earth", "tier": 2, "stage": 1,
		"ascends_from": "pebblit", "cost": 2, "hp": 120, "affinity": "might", "attuned": {"min": 5, "damage": 10},
		"moves": [
			{"name": "Horn Ram", "cost": 0, "damage": 30},
			{"name": "Landslide", "cost": 3, "damage": 80},
		],
		"art": "a massive ox with a body of layered boulders, curved stone horns, moss in the cracks, pawing the ground",
	},
	"burrowmole": {
		"kind": "totem", "name": "Burrowmole", "element": "earth", "tier": 1, "stage": 0, "cost": 2,
		"hp": 60, "affinity": "cunning", "keywords": ["burrow"],
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
		"hp": 160, "affinity": "might", "keywords": ["guardian"], "attuned": {"min": 6, "damage": 20},
		"moves": [
			{"name": "Slam", "cost": 0, "damage": 30},
			{"name": "Rockfall", "cost": 3, "damage": 90},
		],
		"art": "a towering golem of quarried granite blocks held together by glowing amber veins, a pickaxe still lodged in its shoulder",
	},
	# ================================================================== METAL
	"brassback": {
		"kind": "totem", "name": "Brassback", "element": "metal", "tier": 1, "stage": 0, "cost": 1,
		"hp": 60, "affinity": "resolve", "keywords": ["guardian"],
		"moves": [
			{"name": "Clank", "cost": 0, "damage": 10},
			{"name": "Horn Bash", "cost": 1, "damage": 30},
		],
		"art": "a beetle with a polished brass shell engraved with sun patterns, a single curved horn, sturdy legs",
	},
	"ironhide": {
		"kind": "totem", "name": "Ironhide Warbeetle", "element": "metal", "tier": 2, "stage": 1,
		"ascends_from": "brassback", "cost": 2, "hp": 120, "affinity": "resolve", "keywords": ["guardian"],
		"attuned": {"min": 5, "hp": 20},
		"moves": [
			{"name": "Iron Tackle", "cost": 0, "damage": 30},
			{"name": "Steel Wall", "cost": 1, "damage": 20, "effects": [{"op": "shield", "who": "self", "amount": 50}]},
		],
		"art": "a huge armoured war beetle with riveted iron plates and a battering-ram horn, gold trim, sun banners",
	},
	"shieldhound": {
		"kind": "totem", "name": "Shieldhound", "element": "metal", "tier": 1, "stage": 0, "cost": 2,
		"hp": 80, "affinity": "resolve", "attuned": {"min": 5, "damage": 10},
		"moves": [
			{"name": "Guard Bite", "cost": 0, "damage": 20},
			{"name": "Shield Bash", "cost": 1, "damage": 40},
		],
		"art": "a loyal hound wearing a small steel breastplate and helm, a sun crest on its collar, standing guard",
	},
	"gilded_sentinel": {
		"kind": "totem", "name": "Gilded Sentinel", "element": "metal", "tier": 3, "stage": 0, "cost": 4,
		"hp": 130, "affinity": "presence", "keywords": ["guardian"], "attuned": {"min": 6, "damage": 20},
		"moves": [
			{"name": "Gilded Blade", "cost": 0, "damage": 30},
			{"name": "Judgement", "cost": 2, "damage": 70},
		],
		"art": "a tall golden armoured construct with a halo-shaped helm and a sunburst halberd, light spilling from its joints",
	},
	# ================================================================ PSYCHIC
	"dreamfox": {
		"kind": "totem", "name": "Dreamfox", "element": "psychic", "tier": 1, "stage": 0, "cost": 1,
		"hp": 60, "affinity": "insight", "attuned": {"min": 5, "draw": 1},
		"moves": [
			{"name": "Psy Nip", "cost": 0, "damage": 10},
			{"name": "Hypnotic Gaze", "cost": 1, "damage": 0, "target": "foe_totem", "fate": [
				{"to": 5, "damage": 10},
				{"to": 99, "damage": 10, "effects": [{"op": "status", "status": "sleep"}]}]},
		],
		"art": "a slender pink fox with two misty tails and half-closed dreamy eyes, bubbles of illusion floating around it",
	},
	"veilfox": {
		"kind": "totem", "name": "Veilfox", "element": "psychic", "tier": 2, "stage": 1,
		"ascends_from": "dreamfox", "cost": 2, "hp": 100, "affinity": "insight", "attuned": {"min": 5, "damage": 10},
		"moves": [
			{"name": "Mind Lash", "cost": 0, "damage": 30},
			{"name": "Mirage", "cost": 2, "damage": 40, "effects": [{"op": "status", "status": "stun"}]},
		],
		"art": "an elegant fox with four translucent veil-like tails, a glowing third eye, surrounded by shifting mirages",
	},
	"somnowl": {
		"kind": "totem", "name": "Somnowl", "element": "psychic", "tier": 1, "stage": 0, "cost": 2,
		"hp": 70, "affinity": "insight", "keywords": ["channel"],
		"moves": [
			{"name": "Hoot", "cost": 0, "damage": 20},
			{"name": "Night Screech", "cost": 2, "damage": 20, "target": "all_foes"},
		],
		"art": "a round lavender owl with enormous sleepy moon-eyes, feathers trailing wisps of dream-mist, perched on a crescent moon",
	},
	"thought_eater": {
		"kind": "totem", "name": "Thought Eater", "element": "psychic", "tier": 3, "stage": 0, "cost": 4,
		"hp": 110, "affinity": "intellect", "attuned": {"min": 6, "damage": 20}, "keywords": ["harvest"],
		"moves": [
			{"name": "Mind Rend", "cost": 0, "damage": 30},
			{"name": "Devour Thought", "cost": 2, "damage": 60, "effects": [{"op": "discard_random", "count": 1}]},
		],
		"art": "a tapir-like dream beast with a star-speckled violet hide, a long curling trunk inhaling glowing thought-bubbles",
	},
	# ================================================================== VENOM
	"blightrat": {
		"kind": "totem", "name": "Blightrat", "element": "venom", "tier": 1, "stage": 0, "cost": 1,
		"hp": 60, "affinity": "cunning", "attuned": {"min": 5, "damage": 10},
		"moves": [
			{"name": "Gnaw", "cost": 0, "damage": 10},
			{"name": "Plague Bite", "cost": 1, "damage": 20, "effects": [{"op": "status", "status": "poison"}]},
		],
		"art": "a mangy rat with sickly purple fur, dripping green-violet fangs, beady glowing eyes, sneaking",
	},
	"plague_asp": {
		"kind": "totem", "name": "Plague Asp", "element": "venom", "tier": 2, "stage": 1,
		"ascends_from": "blightrat", "cost": 2, "hp": 90, "affinity": "cunning", "attuned": {"min": 5, "damage": 10},
		"moves": [
			{"name": "Fang", "cost": 0, "damage": 30},
			{"name": "Venom Surge", "cost": 2, "damage": 40, "target": "foe_totem",
				"effects": [{"op": "bonus_if_status", "status": "poison", "amount": 40}]},
		],
		"art": "a coiled asp with violet scales and a hood marked like a skull, venom mist rising around it",
	},
	"mirewidow": {
		"kind": "totem", "name": "Mirewidow", "element": "venom", "tier": 1, "stage": 0, "cost": 2,
		"hp": 60, "affinity": "cunning", "keywords": ["thorns"],
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
	# ================================================================ SUMMONS
	"pyraxis": {
		"kind": "summon", "name": "Pyraxis, Heart of the Pyre", "element": "fire", "tier": 6, "cost": 7,
		"affinity": "might",
		"move": {"name": "Sunfall", "damage": 40, "target": "all_foes",
			"effects": [{"op": "status", "status": "burn"}]},
		"art": "a colossal phoenix-dragon demigod of white-hot flame descending from a burning sky, wings spanning the horizon, molten feathers raining down",
	},
	"thalassa": {
		"kind": "summon", "name": "Thalassa, the Deep Mother", "element": "tide", "tier": 6, "cost": 7,
		"affinity": "resolve",
		"move": {"name": "Tidal Embrace", "damage": 50, "target": "all_foes",
			"effects": [{"op": "heal", "who": "allies", "amount": 60}, {"op": "life", "amount": 40}]},
		"art": "a vast serene sea goddess rising from the ocean, hair of rolling waves, a crown of coral and pearls, arms cradling a whirlpool",
	},
	"grondmaw": {
		"kind": "summon", "name": "Grondmaw, the Mountain's Heart", "element": "earth", "tier": 6, "cost": 6,
		"affinity": "might",
		"move": {"name": "Worldbreaker", "damage": 140, "target": "foe_totem", "effects": [{"op": "pierce"}, {"op": "stun_others"}]},
		"art": "a titanic stone giant tearing itself free of a mountain range, glowing magma heart visible through cracked ribs, fists like boulders",
	},
	"somnara": {
		"kind": "summon", "name": "Somnara, the Dreaming Veil", "element": "psychic", "tier": 6, "cost": 6,
		"affinity": "insight",
		"move": {"name": "Endless Dream", "damage": 30, "target": "all_foes",
			"effects": [{"op": "status", "status": "sleep"}]},
		"art": "an ethereal moth-winged demigoddess veiled in drifting starlit silk, her closed eyes glowing, the world below falling into a dream",
	},
	# ================================================================== RITES
	"essence_flask": {
		"kind": "rite", "name": "Essence Flask", "element": "any", "tier": 1, "cost": 0, "target": "none",
		"effects": [{"op": "essence", "amount": 2}],
		"art": "a crystal flask holding swirling motes of many-coloured light",
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
		"damage": 40,
		"art": "a burning brand hurled through the air, trailing a comet-tail of sparks",
	},
	"thunderclap": {
		"kind": "rite", "name": "Thunderclap", "element": "storm", "tier": 2, "cost": 3, "target": "all_foes",
		"damage": 20,
		"art": "a single enormous lightning bolt striking the centre of a duelling circle, a ring of thunder rippling outward",
	},
	"tidal_surge": {
		"kind": "rite", "name": "Tidal Surge", "element": "tide", "tier": 2, "cost": 2, "target": "foe_totem",
		"effects": [{"op": "bounce"}],
		"art": "a towering green-blue wave curling over a stone circle, about to sweep everything away",
	},
	"rejuvenate": {
		"kind": "rite", "name": "Rejuvenate", "element": "verdant", "tier": 1, "cost": 1, "target": "none",
		"effects": [{"op": "life", "amount": 40}],
		"art": "a cupped pair of hands holding a sprouting seedling that glows with soft green light",
	},
	"bulwark": {
		"kind": "rite", "name": "Bulwark", "element": "earth", "tier": 1, "cost": 1, "target": "ally",
		"effects": [{"op": "shield", "who": "target", "amount": 50}],
		"art": "a wall of stone slabs erupting from the ground in a protective half-ring, dust flying",
	},
	"forge_edge": {
		"kind": "rite", "name": "Forge Edge", "element": "metal", "tier": 1, "cost": 1, "target": "ally",
		"effects": [{"op": "buff", "amount": 20}],
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
		"damage": 30, "effects": [{"op": "drain"}],
		"art": "a dark stone rune tile with a glowing violet symbol draining light into itself",
	},
	# ================================================================== WARDS
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
			"essence_flask": 2, "firebrand": 2, "thunderclap": 1, "healing_draught": 1,
			"ambush_snare": 2, "vengeful_spirit": 1, "pyraxis": 1, "travellers_pack": 1},
	},
	"tidegrove": {
		"name": "Tidegrove", "elements": ["tide", "verdant"], "mascot": "brookfin",
		"desc": "Tough Tide and Verdant Totems that heal, guard and outlast. Suits Resolve and Insight.",
		"attributes": {"resolve": 2, "insight": 2},
		"cards": {"brookfin": 3, "riptide_serpent": 2, "deepmaw": 1, "shellguard": 2,
			"mossling": 3, "thornwarden": 2, "bloomsprite": 3, "elderbark": 1,
			"healing_draught": 2, "tidal_surge": 1, "rejuvenate": 2, "seekers_compass": 1, "crystal_vein": 1,
			"riptide_snare": 1, "vengeful_spirit": 1, "thalassa": 1, "travellers_pack": 2, "essence_flask": 1},
	},
	"ironstone": {
		"name": "Ironstone", "elements": ["earth", "metal"], "mascot": "pebblit",
		"desc": "Heavy Earth and Metal Guardians that wall off your Life and grind the enemy down. Suits Might and Resolve.",
		"attributes": {"might": 2, "resolve": 2},
		"cards": {"pebblit": 3, "boulderox": 2, "burrowmole": 3, "quarry_golem": 1,
			"brassback": 3, "ironhide": 2, "shieldhound": 3, "gilded_sentinel": 1,
			"bulwark": 2, "forge_edge": 2, "lure_bell": 1, "healing_draught": 1, "crystal_vein": 1,
			"iron_bastion": 2, "vengeful_spirit": 1, "grondmaw": 1, "essence_flask": 1},
	},
	"veilwild": {
		"name": "Veilwild", "elements": ["psychic", "venom"], "mascot": "dreamfox",
		"desc": "Psychic and Venom tricksters: poison, sleep and face-down Wards. Suits Cunning and Insight.",
		"attributes": {"cunning": 2, "insight": 2},
		"cards": {"dreamfox": 3, "veilfox": 2, "somnowl": 2, "thought_eater": 1,
			"blightrat": 3, "plague_asp": 2, "mirewidow": 3,
			"mind_fog": 2, "toxic_mist": 1, "seekers_compass": 1, "siphon_rune": 1, "travellers_pack": 1,
			"mirror_veil": 2, "counter_rune": 1, "poison_trap": 2, "somnara": 1,
			"essence_flask": 1, "healing_draught": 1},
	},
}

const TIER_MAX_COPIES := [0, 3, 3, 2, 1, 1, 1, 1]

const KEYWORDS := {
	"guardian": {"name": "Guardian", "text": "While it stands, enemies can't attack your Life directly."},
	"swift": {"name": "Swift", "text": "Can attack on the turn it's called."},
	"channel": {"name": "Channel", "text": "+1 Essence on the turn it's called."},
	"thorns": {"name": "Thorns", "text": "A Totem that attacks it takes 10 damage."},
	"harvest": {"name": "Harvest", "text": "+1 Essence when it knocks out a Totem."},
	"burrow": {"name": "Burrow", "text": "Can attack Life even when the slot opposite is filled."},
}

const STATUS_NAMES := {"burn": "Burned", "poison": "Poisoned", "stun": "Stunned", "sleep": "Asleep"}

## Divine Gift wording for the v1 duel (numbers come from DuelRules).
static func gift_text(g: String) -> String:
	match g:
		"dawns_mercy": return "Heal %d damage from one of your Totems and clear its conditions." % DuelRules.mercy_heal
		"wrath": return "Your Totems deal %d more damage this turn." % DuelRules.wrath_bonus
		"stillness": return "Stun up to two enemy Totems."
		"tempest": return "Gain %d Essence this turn. Totems you call this turn are Swift, and Shifting is free." % DuelRules.tempest_essence
		"whisper": return "See your opponent's hand and Wards, then discard two cards from their hand."
		"foresight": return "Draw 3 cards. Your next Fate roll counts as a natural 20."
		"recall": return "Return up to 2 cards from your discard pile to your hand."
		"unbound": return "Draw 3 cards."
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
	var d: Dictionary = DECKS[deck_id]
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
	match d.kind:
		"rite":
			return _rite_text(d)
		"ward":
			return "%s: %s." % [TRIGGER_TEXT.get(d.trigger, d.trigger), _ward_text(d)]
		"summon":
			var m: Dictionary = d.move
			return "Descends, then returns to the heavens. %s: %s." % [m.name, _cap(outcome_text(int(m.damage), m.get("effects", []), m.get("target", "foe_totem")))]
	return ""


static func _rite_text(d: Dictionary) -> String:
	var dmg := int(d.get("damage", 0))
	var parts := []
	if dmg > 0:
		if d.target == "all_foes":
			parts.append("Deal %d damage to each enemy Totem" % dmg)
		else:
			parts.append("Deal %d damage to an enemy Totem" % dmg)
	for e in d.get("effects", []):
		match e.op:
			"essence": parts.append("Gain %d Essence this turn" % e.amount)
			"essence_max": parts.append("Your Essence limit rises by %d for the rest of the duel" % e.amount)
			"heal": parts.append("Heal %d damage from one of your Totems" % e.amount)
			"cure": parts.append("clear its conditions")
			"draw": parts.append("Draw %d cards" % e.count)
			"search_totem": parts.append("Search your deck for a Basic Totem and put it in your hand")
			"move_foe": parts.append("Move an enemy Totem to an empty slot on their side")
			"bounce": parts.append("Return an enemy Totem to its owner's hand")
			"life": parts.append("Gain %d Life" % e.amount)
			"shield": parts.append("Shield one of your Totems: prevent the next %d damage to it" % e.amount)
			"buff": parts.append("One of your Totems deals %d more damage this turn" % e.amount)
			"status":
				if d.target == "all_foes":
					parts.append("Every enemy Totem is %s" % STATUS_NAMES[e.status])
				else:
					parts.append("An enemy Totem is %s" % STATUS_NAMES[e.status])
			"drain": parts.append("gain Life equal to the damage dealt")
	return ", and ".join(parts).replace(", and clear", " and clear") + "."


static func _ward_text(d: Dictionary) -> String:
	var parts := []
	for e in d.effects:
		match e.op:
			"damage_called": parts.append("deal %d damage to that Totem" % e.amount)
			"bounce_called": parts.append("return that Totem to their hand")
			"damage_attacker": parts.append("deal %d damage to the attacker" % e.amount)
			"status_attacker": parts.append("the attacker is %s" % STATUS_NAMES[e.status])
			"negate": parts.append("cancel the attack")
			"block_life": parts.append("prevent all damage to your Life from it")
			"shield_target": parts.append("the attack deals %d less damage" % e.amount)
			"cancel_rite": parts.append("cancel it")
			"survive": parts.append("you survive with %d Life" % e.life)
	return " and ".join(parts)


static func _cap(s: String) -> String:
	if s.is_empty():
		return s
	return s.substr(0, 1).to_upper() + s.substr(1)
