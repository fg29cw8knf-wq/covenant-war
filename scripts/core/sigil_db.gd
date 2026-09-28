class_name SigilDB
extends RefCounted
## Every Sigil (card) in the game, and the decks the story uses.
##
## kind:     totem (a creature), summon (Demigod/Divine), rite (item),
##           ally (supporter, 1 per turn), energy
## element:  see Lore.ELEMENTS.   tier: 1-7 (see Lore.TIER_NAMES)
## stage:    0 = base, 1-2 = Awakenings (played on the card named in awakens_from)
## affinity: the player attribute this card draws on
## attuned:  bonus while the player's affinity attribute >= min:
##           damage (+ to attacks), hp (+ max HP), retreat (- cost),
##           cost (- that many "any" from attack costs), immune (no conditions),
##           draw (draw cards when it enters play)
## art:      the subject description for AI art (combine with the style prompt
##           in docs/art-prompts.md)

const CARDS := {
	# ================================================================== FIRE
	"cinderpup": {
		"kind": "totem", "name": "Cinderpup", "element": "fire", "tier": 1, "stage": 0,
		"hp": 60, "retreat": 1, "affinity": "might", "attuned": {"min": 5, "damage": 10},
		"attacks": [
			{"name": "Nip", "cost": ["any"], "damage": 10},
			{"name": "Ember Bite", "cost": ["fire", "any"], "damage": 30,
				"text": "Discard a Fire Energy from this Totem.",
				"effects": [{"op": "discard_energy_self", "type": "fire", "count": 1}]},
		],
		"art": "a small fox-like pup made of glowing embers, a flickering flame for a tail, bright amber eyes, playful crouch",
	},
	"blazehound": {
		"kind": "totem", "name": "Blazehound", "element": "fire", "tier": 2, "stage": 1,
		"awakens_from": "cinderpup", "hp": 90, "retreat": 1, "affinity": "might",
		"attuned": {"min": 5, "damage": 10},
		"attacks": [
			{"name": "Flame Fang", "cost": ["fire", "any"], "damage": 40,
				"text": "Flip a coin. If heads, the Defending Totem is now Burned.",
				"effects": [{"op": "flip_status", "status": "burned"}]},
			{"name": "Inferno Rush", "cost": ["fire", "fire", "any"], "damage": 80,
				"text": "Discard a Fire Energy from this Totem.",
				"effects": [{"op": "discard_energy_self", "type": "fire", "count": 1}]},
		],
		"art": "a lean wolfhound wreathed in roaring flame, a mane of fire, molten cracks along its body, lunging forward",
	},
	"emberwisp": {
		"kind": "totem", "name": "Emberwisp", "element": "fire", "tier": 1, "stage": 0,
		"hp": 40, "retreat": 0, "affinity": "swiftness", "attuned": {"min": 5, "damage": 10},
		"attacks": [
			{"name": "Kindle", "cost": ["fire"], "damage": 10,
				"text": "The Defending Totem is now Burned.",
				"effects": [{"op": "status", "status": "burned"}]},
			{"name": "Scatter Sparks", "cost": ["fire", "any"], "damage": 0,
				"text": "Does 10 damage to each of your opponent's Benched Totems.",
				"effects": [{"op": "bench_all_opp", "amount": 10}]},
		],
		"art": "a tiny floating spark spirit with a candle-flame body, wide curious eyes, trailing glowing cinders",
	},
	"ashen_drake": {
		"kind": "totem", "name": "Ashen Drake", "element": "fire", "tier": 3, "stage": 0,
		"hp": 100, "retreat": 2, "affinity": "might", "attuned": {"min": 6, "damage": 20},
		"attacks": [
			{"name": "Scorch Breath", "cost": ["fire", "fire", "any"], "damage": 50},
			{"name": "Cinder Storm", "cost": ["fire", "fire", "any", "any"], "damage": 100,
				"text": "Discard 2 Energy from this Totem.",
				"effects": [{"op": "discard_energy_self", "type": "any", "count": 2}]},
		],
		"art": "a young dragon with charcoal-grey scales and glowing orange cracks, smoke pouring from its jaws, wings half spread",
	},
	# ================================================================== WIND
	"gustling": {
		"kind": "totem", "name": "Gustling", "element": "wind", "tier": 1, "stage": 0,
		"hp": 50, "retreat": 1, "affinity": "swiftness", "attuned": {"min": 5, "retreat": 1},
		"attacks": [
			{"name": "Buffet", "cost": ["any"], "damage": 10},
			{"name": "Updraft", "cost": ["wind", "any"], "damage": 20,
				"text": "You may switch this Totem with one of your Benched Totems.",
				"effects": [{"op": "self_switch"}]},
		],
		"art": "a round fluffy bird made of swirling air currents, tufted crest, tiny wings, riding a little whirlwind",
	},
	"galeheart": {
		"kind": "totem", "name": "Galeheart", "element": "wind", "tier": 2, "stage": 1,
		"awakens_from": "gustling", "hp": 80, "retreat": 1, "affinity": "swiftness",
		"attuned": {"min": 5, "retreat": 1},
		"attacks": [
			{"name": "Razor Wind", "cost": ["wind", "any"], "damage": 40},
			{"name": "Cyclone Dive", "cost": ["wind", "wind", "any"], "damage": 60,
				"text": "Your opponent switches their Active Totem with one of their Benched Totems.",
				"effects": [{"op": "opp_switch"}]},
		],
		"art": "a sleek falcon with feathers that dissolve into streaks of wind, sharp eyes, diving through a spiral of air",
	},
	"skylark_scout": {
		"kind": "totem", "name": "Skylark Scout", "element": "wind", "tier": 1, "stage": 0,
		"hp": 40, "retreat": 0, "affinity": "insight", "attuned": {"min": 5, "draw": 1},
		"attacks": [
			{"name": "Scout Ahead", "cost": ["any"], "damage": 0, "text": "Draw 2 cards.",
				"effects": [{"op": "draw", "count": 2}]},
			{"name": "Peck", "cost": ["wind"], "damage": 20},
		],
		"art": "a small skylark wearing a tiny scout's satchel, feathers edged with glowing wind lines, perched alert",
	},
	"tempest_roc": {
		"kind": "totem", "name": "Tempest Roc", "element": "wind", "tier": 3, "stage": 0,
		"hp": 90, "retreat": 1, "affinity": "swiftness", "attuned": {"min": 6, "damage": 20},
		"attacks": [
			{"name": "Gale Talons", "cost": ["wind", "any", "any"], "damage": 50,
				"text": "Also does 20 damage to one of your opponent's Benched Totems.",
				"effects": [{"op": "snipe_opp_bench", "amount": 20}]},
		],
		"art": "a huge storm-grey roc with a wingspan of whirling cloud, talons like silver hooks, screaming mid-flight",
	},
	# ================================================================== TIDE
	"brookfin": {
		"kind": "totem", "name": "Brookfin", "element": "tide", "tier": 1, "stage": 0,
		"hp": 60, "retreat": 1, "affinity": "resolve", "attuned": {"min": 5, "hp": 20},
		"attacks": [
			{"name": "Splash", "cost": ["tide"], "damage": 20},
			{"name": "Undertow", "cost": ["tide", "any"], "damage": 30},
		],
		"art": "a small river serpent with translucent blue fins and pebble-smooth scales, curled in a splash of clear water",
	},
	"riptide_serpent": {
		"kind": "totem", "name": "Riptide Serpent", "element": "tide", "tier": 2, "stage": 1,
		"awakens_from": "brookfin", "hp": 100, "retreat": 2, "affinity": "resolve",
		"attuned": {"min": 5, "hp": 20},
		"attacks": [
			{"name": "Water Lash", "cost": ["tide", "any"], "damage": 40},
			{"name": "Riptide", "cost": ["tide", "tide", "any"], "damage": 60, "damage_suffix": "+",
				"text": "Does 10 more damage for each Tide Energy on this Totem not used to pay for this attack (max +20).",
				"effects": [{"op": "plus_per_extra_energy", "type": "tide", "per": 10, "max": 20}]},
		],
		"art": "a long sea serpent coiling through a crashing wave, fins like torn sails, eyes glowing deep blue",
	},
	"deepmaw": {
		"kind": "totem", "name": "Deepmaw Leviathan", "element": "tide", "tier": 3, "stage": 2,
		"awakens_from": "riptide_serpent", "hp": 150, "retreat": 3, "affinity": "resolve",
		"attuned": {"min": 6, "hp": 30},
		"attacks": [
			{"name": "Crushing Tide", "cost": ["tide", "tide", "any"], "damage": 80},
			{"name": "Maelstrom", "cost": ["tide", "tide", "tide", "any"], "damage": 130,
				"text": "Discard 2 Energy from this Totem.",
				"effects": [{"op": "discard_energy_self", "type": "any", "count": 2}]},
		],
		"art": "a colossal sea leviathan rising from a whirlpool, barnacled armour plates, a jaw wide enough to swallow ships",
	},
	"shellguard": {
		"kind": "totem", "name": "Shellguard", "element": "tide", "tier": 1, "stage": 0,
		"hp": 80, "retreat": 2, "affinity": "resolve", "attuned": {"min": 5, "immune": true},
		"attacks": [
			{"name": "Withdraw", "cost": ["tide"], "damage": 0,
				"text": "Flip a coin. If heads, prevent all damage done to this Totem during your opponent's next turn.",
				"effects": [{"op": "flip_protect"}]},
			{"name": "Shell Slam", "cost": ["tide", "any", "any"], "damage": 50},
		],
		"art": "a sturdy turtle with a coral-covered shell and a calm wise face, water droplets beading on its shell",
	},
	# =============================================================== VERDANT
	"mossling": {
		"kind": "totem", "name": "Mossling", "element": "verdant", "tier": 1, "stage": 0,
		"hp": 60, "retreat": 1, "affinity": "resolve", "attuned": {"min": 5, "hp": 20},
		"attacks": [
			{"name": "Sap", "cost": ["verdant"], "damage": 10, "text": "Heal 10 damage from this Totem.",
				"effects": [{"op": "heal_self", "amount": 10}]},
			{"name": "Vine Snare", "cost": ["verdant", "any"], "damage": 20,
				"text": "Flip a coin. If heads, the Defending Totem is now Paralyzed.",
				"effects": [{"op": "flip_status", "status": "paralyzed"}]},
		],
		"art": "a small round forest creature covered in soft moss, a sprout growing from its head, big gentle eyes",
	},
	"thornwarden": {
		"kind": "totem", "name": "Thornwarden", "element": "verdant", "tier": 2, "stage": 1,
		"awakens_from": "mossling", "hp": 100, "retreat": 2, "affinity": "resolve",
		"attuned": {"min": 5, "hp": 20},
		"attacks": [
			{"name": "Barbed Lash", "cost": ["verdant", "any"], "damage": 30,
				"text": "The Defending Totem is now Poisoned.",
				"effects": [{"op": "status", "status": "poisoned"}]},
			{"name": "Wild Growth", "cost": ["verdant", "verdant", "any"], "damage": 60,
				"text": "Heal 20 damage from this Totem.",
				"effects": [{"op": "heal_self", "amount": 20}]},
		],
		"art": "a bear-like guardian made of woven roots and thorny vines, flowers blooming on its shoulders, protective stance",
	},
	"bloomsprite": {
		"kind": "totem", "name": "Bloomsprite", "element": "verdant", "tier": 1, "stage": 0,
		"hp": 40, "retreat": 0, "affinity": "insight", "attuned": {"min": 5, "draw": 1},
		"attacks": [
			{"name": "Petal Mend", "cost": ["verdant"], "damage": 0,
				"text": "Heal 30 damage from one of your Totems.",
				"effects": [{"op": "heal_own", "amount": 30}]},
			{"name": "Pollen Burst", "cost": ["verdant", "any"], "damage": 20,
				"text": "Flip a coin. If heads, the Defending Totem is now Asleep.",
				"effects": [{"op": "flip_status", "status": "asleep"}]},
		],
		"art": "a tiny fairy-like sprite with petal wings and a flower-bud head, scattering glowing pollen",
	},
	"elderbark": {
		"kind": "totem", "name": "Elderbark", "element": "verdant", "tier": 3, "stage": 0,
		"hp": 130, "retreat": 3, "affinity": "resolve", "attuned": {"min": 6, "hp": 30},
		"attacks": [
			{"name": "Root Slam", "cost": ["verdant", "verdant", "any"], "damage": 50},
			{"name": "Ancient Grasp", "cost": ["verdant", "verdant", "any", "any"], "damage": 80,
				"text": "Flip a coin. If heads, the Defending Totem is now Paralyzed.",
				"effects": [{"op": "flip_status", "status": "paralyzed"}]},
		],
		"art": "an ancient walking tree with a bark face, moss beard and glowing sap veins, roots dragging like feet",
	},
	# ================================================================= STORM
	"sparkkit": {
		"kind": "totem", "name": "Sparkkit", "element": "storm", "tier": 1, "stage": 0,
		"hp": 50, "retreat": 1, "affinity": "intellect", "attuned": {"min": 5, "damage": 10},
		"attacks": [
			{"name": "Static", "cost": ["storm"], "damage": 10,
				"text": "Flip a coin. If heads, the Defending Totem is now Paralyzed.",
				"effects": [{"op": "flip_status", "status": "paralyzed"}]},
			{"name": "Spark Pounce", "cost": ["storm", "any"], "damage": 30},
		],
		"art": "a small indigo fox kit with crackling yellow lightning along its ears and a bolt-shaped tail",
	},
	"voltlynx": {
		"kind": "totem", "name": "Voltlynx", "element": "storm", "tier": 2, "stage": 1,
		"awakens_from": "sparkkit", "hp": 90, "retreat": 1, "affinity": "intellect",
		"attuned": {"min": 5, "damage": 10},
		"attacks": [
			{"name": "Thunder Claw", "cost": ["storm", "any"], "damage": 40},
			{"name": "Overcharge", "cost": ["storm", "storm", "any"], "damage": 90,
				"text": "Flip a coin. If tails, this Totem also does 30 damage to itself.",
				"effects": [{"op": "flip_self_damage_tails", "amount": 30}]},
		],
		"art": "a lynx with deep indigo fur and ear tufts sparking with electricity, a jagged lightning mane, snarling",
	},
	"stormcaller": {
		"kind": "totem", "name": "Stormcaller Heron", "element": "storm", "tier": 3, "stage": 0,
		"hp": 90, "retreat": 1, "affinity": "intellect", "attuned": {"min": 6, "draw": 2},
		"attacks": [
			{"name": "Chain Lightning", "cost": ["storm", "storm", "any"], "damage": 40,
				"text": "Also does 10 damage to each of your opponent's Benched Totems.",
				"effects": [{"op": "bench_all_opp", "amount": 10}]},
		],
		"art": "a tall heron standing in dark water, storm clouds swirling around its crest, lightning dancing between its wings",
	},
	# ================================================================= EARTH
	"pebblit": {
		"kind": "totem", "name": "Pebblit", "element": "earth", "tier": 1, "stage": 0,
		"hp": 70, "retreat": 2, "affinity": "might", "attuned": {"min": 5, "damage": 10},
		"attacks": [
			{"name": "Rock Toss", "cost": ["earth"], "damage": 20},
			{"name": "Rollout", "cost": ["earth", "any"], "damage": 30},
		],
		"art": "a round pebble creature with little stubby arms, a teal crystal growing from its head, cheerful face",
	},
	"boulderox": {
		"kind": "totem", "name": "Boulderox", "element": "earth", "tier": 2, "stage": 1,
		"awakens_from": "pebblit", "hp": 120, "retreat": 3, "affinity": "might",
		"attuned": {"min": 5, "damage": 10},
		"attacks": [
			{"name": "Rock Slam", "cost": ["earth", "any", "any"], "damage": 50},
			{"name": "Landslide", "cost": ["earth", "earth", "any", "any"], "damage": 80,
				"text": "Does 10 damage to each of your opponent's Benched Totems.",
				"effects": [{"op": "bench_all_opp", "amount": 10}]},
		],
		"art": "a massive ox with a body of layered boulders, curved stone horns, moss in the cracks, pawing the ground",
	},
	"burrowmole": {
		"kind": "totem", "name": "Burrowmole", "element": "earth", "tier": 1, "stage": 0,
		"hp": 60, "retreat": 1, "affinity": "intellect", "attuned": {"min": 5, "draw": 1},
		"attacks": [
			{"name": "Mud Slap", "cost": ["earth"], "damage": 20},
			{"name": "Undermine", "cost": ["earth", "any"], "damage": 0,
				"text": "Choose one of your opponent's Totems. This attack does 30 damage to it. (Weakness and Resistance don't apply.)",
				"effects": [{"op": "snipe_any", "amount": 30}]},
		],
		"art": "a mole in a battered miner's helmet with a glowing lamp, huge digging claws, clods of earth flying",
	},
	# ================================================================= METAL
	"brassback": {
		"kind": "totem", "name": "Brassback", "element": "metal", "tier": 1, "stage": 0,
		"hp": 70, "retreat": 2, "affinity": "resolve", "attuned": {"min": 5, "hp": 20},
		"attacks": [
			{"name": "Horn Jab", "cost": ["metal"], "damage": 20},
			{"name": "Brass Charge", "cost": ["metal", "any"], "damage": 30},
		],
		"art": "a beetle with a polished brass shell engraved with sun patterns, a single curved horn, sturdy legs",
	},
	"ironhide": {
		"kind": "totem", "name": "Ironhide Warbeetle", "element": "metal", "tier": 2, "stage": 1,
		"awakens_from": "brassback", "hp": 120, "retreat": 3, "affinity": "resolve",
		"attuned": {"min": 5, "hp": 20},
		"attacks": [
			{"name": "Fortress Shell", "cost": ["metal"], "damage": 20,
				"text": "During your opponent's next turn, this Totem takes 30 less damage.",
				"effects": [{"op": "brace", "amount": 30}]},
			{"name": "Iron Horn", "cost": ["metal", "any", "any"], "damage": 70},
		],
		"art": "a huge armoured war beetle with riveted iron plates and a battering-ram horn, gold trim, sun banners",
	},
	"shieldhound": {
		"kind": "totem", "name": "Shieldhound", "element": "metal", "tier": 1, "stage": 0,
		"hp": 60, "retreat": 1, "affinity": "presence", "attuned": {"min": 5, "damage": 10},
		"attacks": [
			{"name": "Guard Bite", "cost": ["metal"], "damage": 20},
			{"name": "Steel Pounce", "cost": ["metal", "any"], "damage": 30},
		],
		"art": "a loyal hound wearing a small steel breastplate and helm, a sun crest on its collar, standing guard",
	},
	"gilded_sentinel": {
		"kind": "totem", "name": "Gilded Sentinel", "element": "metal", "tier": 3, "stage": 0,
		"hp": 110, "retreat": 3, "affinity": "presence", "attuned": {"min": 6, "cost": 1},
		"attacks": [
			{"name": "Sunlit Halberd", "cost": ["metal", "metal", "any"], "damage": 60},
			{"name": "Judgement Strike", "cost": ["metal", "metal", "any", "any"], "damage": 100},
		],
		"art": "a tall golden armoured construct with a halo-shaped helm and a sunburst halberd, light spilling from its joints",
	},
	# ================================================================ SPIRIT
	"candlewisp": {
		"kind": "totem", "name": "Candlewisp", "element": "spirit", "tier": 1, "stage": 0,
		"hp": 50, "retreat": 0, "affinity": "insight", "attuned": {"min": 5, "damage": 10},
		"attacks": [
			{"name": "Flicker", "cost": ["spirit"], "damage": 10,
				"text": "Flip a coin. If heads, the Defending Totem is now Confused.",
				"effects": [{"op": "flip_status", "status": "confused"}]},
			{"name": "Soul Touch", "cost": ["spirit", "any"], "damage": 30},
		],
		"art": "a small ghost shaped like a melting candle, a pale teal flame for a head, gentle sad eyes",
	},
	"lantern_wraith": {
		"kind": "totem", "name": "Lantern Wraith", "element": "spirit", "tier": 2, "stage": 1,
		"awakens_from": "candlewisp", "hp": 80, "retreat": 1, "affinity": "insight",
		"attuned": {"min": 5, "draw": 1},
		"attacks": [
			{"name": "Soul Burn", "cost": ["spirit", "any"], "damage": 30,
				"text": "The Defending Totem is now Burned.",
				"effects": [{"op": "status", "status": "burned"}]},
			{"name": "Hollow Gaze", "cost": ["spirit", "spirit", "any"], "damage": 50, "damage_suffix": "+",
				"text": "If the Defending Totem has a Special Condition, this attack does 30 more damage.",
				"effects": [{"op": "plus_if_defender_condition", "amount": 30}]},
		],
		"art": "a hooded wraith carrying a lantern of trapped teal soul-fire, tattered robes drifting like smoke",
	},
	# ================================================================ MYSTIC
	"runemoth": {
		"kind": "totem", "name": "Runemoth", "element": "mystic", "tier": 1, "stage": 0,
		"hp": 50, "retreat": 1, "affinity": "intellect", "attuned": {"min": 5, "damage": 10},
		"attacks": [
			{"name": "Glyph Dust", "cost": ["mystic"], "damage": 10,
				"text": "The Defending Totem is now Asleep.",
				"effects": [{"op": "status", "status": "asleep"}]},
			{"name": "Arcane Flutter", "cost": ["mystic", "any"], "damage": 30},
		],
		"art": "a moth with indigo wings covered in glowing golden runes, feathery antennae, dust sparkling as it flies",
	},
	"glyph_owl": {
		"kind": "totem", "name": "Glyph Owl", "element": "mystic", "tier": 2, "stage": 1,
		"awakens_from": "runemoth", "hp": 80, "retreat": 1, "affinity": "intellect",
		"attuned": {"min": 5, "draw": 1},
		"attacks": [
			{"name": "Rune Bolt", "cost": ["mystic", "any"], "damage": 40},
			{"name": "Seal Sight", "cost": ["mystic", "mystic", "any"], "damage": 50,
				"text": "Discard an Energy from the Defending Totem.",
				"effects": [{"op": "discard_opp_energy", "count": 1}]},
		],
		"art": "a wise owl with feathers inscribed with glowing runes, spectacles of floating light, a floating open book beside it",
	},
	# ================================================================= VENOM
	"blightrat": {
		"kind": "totem", "name": "Blightrat", "element": "venom", "tier": 1, "stage": 0,
		"hp": 50, "retreat": 0, "affinity": "cunning", "attuned": {"min": 5, "damage": 10},
		"attacks": [
			{"name": "Gnaw", "cost": ["any"], "damage": 10},
			{"name": "Plague Bite", "cost": ["venom"], "damage": 10,
				"text": "The Defending Totem is now Poisoned.",
				"effects": [{"op": "status", "status": "poisoned"}]},
		],
		"art": "a mangy rat with sickly purple fur, dripping green-violet fangs, beady glowing eyes, sneaking",
	},
	"plague_asp": {
		"kind": "totem", "name": "Plague Asp", "element": "venom", "tier": 2, "stage": 1,
		"awakens_from": "blightrat", "hp": 80, "retreat": 1, "affinity": "cunning",
		"attuned": {"min": 5, "damage": 10},
		"attacks": [
			{"name": "Venom Fang", "cost": ["venom", "any"], "damage": 30,
				"text": "The Defending Totem is now Poisoned.",
				"effects": [{"op": "status", "status": "poisoned"}]},
			{"name": "Wither", "cost": ["venom", "venom", "any"], "damage": 50, "damage_suffix": "+",
				"text": "If the Defending Totem is Poisoned, this attack does 30 more damage.",
				"effects": [{"op": "plus_if_defender_status", "status": "poisoned", "amount": 30}]},
		],
		"art": "a coiled asp with violet scales and a hood marked like a skull, venom mist rising around it",
	},
	# =============================================================== PSYCHIC
	"dreamfox": {
		"kind": "totem", "name": "Dreamfox", "element": "psychic", "tier": 1, "stage": 0,
		"hp": 50, "retreat": 1, "affinity": "cunning", "attuned": {"min": 5, "damage": 10},
		"attacks": [
			{"name": "Mind Trick", "cost": ["psychic"], "damage": 0,
				"text": "Your opponent discards a random card from their hand.",
				"effects": [{"op": "discard_random_opp_hand", "count": 1}]},
			{"name": "Daze", "cost": ["psychic", "any"], "damage": 20,
				"text": "The Defending Totem is now Confused.",
				"effects": [{"op": "status", "status": "confused"}]},
		],
		"art": "a slender pink fox with two misty tails and half-closed dreamy eyes, bubbles of illusion floating around it",
	},
	"veilfox": {
		"kind": "totem", "name": "Veilfox", "element": "psychic", "tier": 2, "stage": 1,
		"awakens_from": "dreamfox", "hp": 80, "retreat": 1, "affinity": "cunning",
		"attuned": {"min": 5, "damage": 10},
		"attacks": [
			{"name": "Mirage Claw", "cost": ["psychic", "any"], "damage": 40},
			{"name": "Nightmare Veil", "cost": ["psychic", "psychic", "any"], "damage": 40, "damage_suffix": "+",
				"text": "If the Defending Totem is Asleep, this attack does 50 more damage. Then the Defending Totem is now Asleep.",
				"effects": [{"op": "plus_if_defender_status", "status": "asleep", "amount": 50},
					{"op": "status", "status": "asleep"}]},
		],
		"art": "an elegant fox with four translucent veil-like tails, a glowing third eye, surrounded by shifting mirages",
	},
	# ================================================================ LEGEND
	"sunlance_seraph": {
		"kind": "totem", "name": "Sunlance Seraph", "element": "radiant", "tier": 5, "stage": 0,
		"hp": 130, "retreat": 2, "affinity": "presence", "attuned": {"min": 6, "cost": 1},
		"attacks": [
			{"name": "Dawnblade", "cost": ["any", "any", "any"], "damage": 70},
			{"name": "Solar Verdict", "cost": ["any", "any", "any", "any"], "damage": 120,
				"text": "Discard 2 Energy from this Totem.",
				"effects": [{"op": "discard_energy_self", "type": "any", "count": 2}]},
		],
		"art": "a radiant winged warrior spirit in white-gold armour, six wings of light, a lance of pure sunlight, halo blazing",
	},
	# ================================================================ SUMMON
	"dawnmane": {
		"kind": "summon", "name": "Dawnmane, the Sun Lion", "element": "radiant", "tier": 6,
		"affinity": "presence", "attuned": {"min": 6, "cost": 1},
		"cost": ["any", "any", "any", "any"],
		"text": "Summon instead of attacking. Deals 80 damage to your opponent's Active Totem and 20 to each of their Benched Totems.",
		"effects": [{"op": "summon_strike", "amount": 80}, {"op": "bench_all_opp", "amount": 20}],
		"art": "a colossal lion of living sunlight descending from the sky, a mane of solar flares, roaring as dawn breaks behind it",
	},
	# ================================================================= RITES
	"healing_draught": {
		"kind": "rite", "name": "Healing Draught", "tier": 1, "op": "heal", "amount": 30,
		"target": "own_damaged", "text": "Heal 30 damage from one of your Totems.",
		"art": "a glass flask of glowing rose-red liquid with a cork stopper, tiny bubbles rising",
	},
	"cleansing_salts": {
		"kind": "rite", "name": "Cleansing Salts", "tier": 1, "op": "cure_active", "amount": 10,
		"text": "Remove all Special Conditions from your Active Totem and heal 10 damage from it.",
		"art": "a small pouch spilling shimmering white salt crystals that glow softly",
	},
	"swap_talisman": {
		"kind": "rite", "name": "Swap Talisman", "tier": 1, "op": "switch_own", "target": "own_bench",
		"text": "Switch your Active Totem with one of your Benched Totems.",
		"art": "a bronze talisman of two interlocking arrows on a leather cord, faintly glowing",
	},
	"seekers_compass": {
		"kind": "rite", "name": "Seeker's Compass", "tier": 1, "op": "search_basic",
		"text": "Search your deck for a base Totem and put it into your hand. Then shuffle your deck.",
		"art": "an ornate brass compass whose needle is a tiny flame, pointing towards a hidden card",
	},
	"awakening_stone": {
		"kind": "rite", "name": "Awakening Stone", "tier": 1, "op": "search_evolution",
		"text": "Search your deck for an Awakening card and put it into your hand. Then shuffle your deck.",
		"art": "a smooth river stone cracked open with a golden light pouring out of it",
	},
	"essence_flask": {
		"kind": "rite", "name": "Essence Flask", "tier": 1, "op": "recycle_energy", "count": 2,
		"text": "Put up to 2 Energy cards from your discard pile into your hand.",
		"art": "a crystal flask holding swirling motes of many-coloured light",
	},
	"lure_bell": {
		"kind": "rite", "name": "Lure Bell", "tier": 2, "op": "gust", "target": "opp_bench",
		"text": "Switch one of your opponent's Benched Totems with their Active Totem.",
		"art": "a small golden bell with a sun engraving, sound waves of light rippling from it",
	},
	"siphon_rune": {
		"kind": "rite", "name": "Siphon Rune", "tier": 2, "op": "remove_opp_energy",
		"text": "Discard an Energy attached to your opponent's Active Totem.",
		"art": "a dark stone rune tile with a glowing violet symbol draining light into itself",
	},
	"revival_candle": {
		"kind": "rite", "name": "Revival Candle", "tier": 2, "op": "revive_basic",
		"text": "Put a base Totem from your discard pile onto your Bench with half its HP.",
		"art": "a tall white candle with a teal spirit flame, wax dripping into the shape of a small creature",
	},
	# ================================================================ ALLIES
	"bram": {
		"kind": "ally", "name": "Bram, Old Duellist", "tier": 1, "op": "draw", "count": 3,
		"text": "Draw 3 cards.",
		"art": "a weathered old innkeeper with a grey beard, an eyepatch and a warm grin, shuffling a worn deck of cards",
	},
	"archive_scribe": {
		"kind": "ally", "name": "Archive Scribe", "tier": 1, "op": "discard_draw", "count": 7,
		"text": "Discard your hand and draw 7 cards.",
		"art": "a young scribe in indigo robes surrounded by floating scrolls, ink-stained fingers, spectacles",
	},
	"wren": {
		"kind": "ally", "name": "Wren, Card Thief", "tier": 2, "op": "whisper",
		"text": "Look at your opponent's hand and discard one card from it.",
		"art": "a quick-eyed young thief in a hooded green cloak, flicking a stolen card between her fingers, sly smile",
	},
	# ================================================================ ENERGY
	"e_fire": {"kind": "energy", "name": "Fire Energy", "element": "fire", "tier": 1, "provides": ["fire"]},
	"e_frost": {"kind": "energy", "name": "Frost Energy", "element": "frost", "tier": 1, "provides": ["frost"]},
	"e_tide": {"kind": "energy", "name": "Tide Energy", "element": "tide", "tier": 1, "provides": ["tide"]},
	"e_storm": {"kind": "energy", "name": "Storm Energy", "element": "storm", "tier": 1, "provides": ["storm"]},
	"e_earth": {"kind": "energy", "name": "Earth Energy", "element": "earth", "tier": 1, "provides": ["earth"]},
	"e_wind": {"kind": "energy", "name": "Wind Energy", "element": "wind", "tier": 1, "provides": ["wind"]},
	"e_verdant": {"kind": "energy", "name": "Verdant Energy", "element": "verdant", "tier": 1, "provides": ["verdant"]},
	"e_metal": {"kind": "energy", "name": "Metal Energy", "element": "metal", "tier": 1, "provides": ["metal"]},
	"e_venom": {"kind": "energy", "name": "Venom Energy", "element": "venom", "tier": 1, "provides": ["venom"]},
	"e_psychic": {"kind": "energy", "name": "Psychic Energy", "element": "psychic", "tier": 1, "provides": ["psychic"]},
	"e_mystic": {"kind": "energy", "name": "Mystic Energy", "element": "mystic", "tier": 1, "provides": ["mystic"]},
	"e_spirit": {"kind": "energy", "name": "Spirit Energy", "element": "spirit", "tier": 1, "provides": ["spirit"]},
}

## Decks used by the story. Starter decks are chosen in the prologue.
const DECKS := {
	# The three starters form a triangle: Emberstorm beats Tidegrove,
	# Tidegrove beats Ironstone, Ironstone beats Emberstorm.
	"emberstorm": {
		"name": "Emberstorm", "elements": ["fire", "storm"], "starter": true, "mascot": "cinderpup",
		"desc": "Fast, fierce Fire and Storm Totems that hit hard and early. Suits Might and Intellect.",
		"attributes": {"might": 2, "intellect": 2},
		"cards": {"cinderpup": 4, "blazehound": 2, "emberwisp": 2, "ashen_drake": 1,
			"sparkkit": 4, "voltlynx": 2, "stormcaller": 1,
			"healing_draught": 2, "swap_talisman": 1, "seekers_compass": 2, "awakening_stone": 2, "bram": 2,
			"e_fire": 8, "e_storm": 7},
	},
	"tidegrove": {
		"name": "Tidegrove", "elements": ["tide", "verdant"], "starter": true, "mascot": "brookfin",
		"desc": "Tough Tide and Verdant Totems that heal and outlast. Suits Resolve and Insight.",
		"attributes": {"resolve": 2, "insight": 2},
		"cards": {"brookfin": 3, "riptide_serpent": 2, "deepmaw": 1, "shellguard": 2,
			"mossling": 3, "thornwarden": 2, "bloomsprite": 2, "elderbark": 1,
			"healing_draught": 2, "cleansing_salts": 1, "seekers_compass": 2, "awakening_stone": 2, "bram": 2,
			"e_tide": 8, "e_verdant": 7},
	},
	"ironstone": {
		"name": "Ironstone", "elements": ["earth", "metal"], "starter": true, "mascot": "pebblit",
		"desc": "Heavy Earth and Metal walls that grind the enemy down. Suits Might and Resolve.",
		"attributes": {"might": 2, "resolve": 2},
		"cards": {"pebblit": 4, "boulderox": 2, "burrowmole": 2, "brassback": 3, "ironhide": 2,
			"shieldhound": 2, "gilded_sentinel": 1,
			"healing_draught": 2, "swap_talisman": 1, "seekers_compass": 2, "awakening_stone": 2, "bram": 2,
			"e_earth": 8, "e_metal": 7},
	},
	"ironvault_hunter": {
		"name": "Ironvault Hunter", "elements": ["venom", "metal"],
		"cards": {"blightrat": 4, "plague_asp": 2, "brassback": 3, "shieldhound": 3,
			"healing_draught": 2, "siphon_rune": 2, "seekers_compass": 2, "awakening_stone": 2,
			"e_venom": 10, "e_metal": 10},
	},
	"wren": {
		"name": "Wren's Deck", "elements": ["psychic", "venom"],
		"cards": {"dreamfox": 4, "veilfox": 2, "blightrat": 3, "plague_asp": 2,
			"wren": 2, "siphon_rune": 1, "swap_talisman": 2, "healing_draught": 2, "seekers_compass": 2, "awakening_stone": 2,
			"e_psychic": 9, "e_venom": 9},
	},
	"solhaven_guard": {
		"name": "Solhaven Guard", "elements": ["metal", "wind"],
		"cards": {"brassback": 4, "ironhide": 2, "shieldhound": 3, "gustling": 3, "galeheart": 2, "gilded_sentinel": 1,
			"healing_draught": 2, "swap_talisman": 1, "seekers_compass": 2, "awakening_stone": 2, "bram": 2, "lure_bell": 1,
			"e_metal": 8, "e_wind": 7},
	},
	"temple_acolyte": {
		"name": "Temple Acolyte", "elements": ["spirit", "mystic"],
		"cards": {"candlewisp": 4, "lantern_wraith": 2, "runemoth": 4, "glyph_owl": 2,
			"healing_draught": 2, "cleansing_salts": 2, "seekers_compass": 2, "awakening_stone": 2, "archive_scribe": 1, "bram": 2,
			"e_spirit": 9, "e_mystic": 8},
	},
	"ser_aldric": {
		"name": "Ser Aldric's Deck", "elements": ["metal", "fire", "radiant"],
		"cards": {"brassback": 3, "ironhide": 2, "gilded_sentinel": 2, "cinderpup": 3, "blazehound": 2,
			"shieldhound": 2, "sunlance_seraph": 1, "dawnmane": 1,
			"healing_draught": 2, "swap_talisman": 1, "seekers_compass": 2, "awakening_stone": 2, "bram": 1, "lure_bell": 1,
			"e_metal": 8, "e_fire": 7},
	},
}


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
	if cards.size() != 40:
		problems.append("A deck needs exactly 40 cards (this one has %d)." % cards.size())
	var counts := {}
	for id in cards:
		counts[id] = int(counts.get(id, 0)) + 1
	var demigods := 0
	var divines := 0
	var has_base := false
	for id in counts:
		var d: Dictionary = CARDS[id]
		if d.kind == "energy":
			continue
		var tier := int(d.get("tier", 1))
		if tier == 6:
			demigods += counts[id]
		if tier == 7:
			divines += counts[id]
		if d.kind == "totem" and int(d.get("stage", 0)) == 0:
			has_base = true
		var limit: int = Lore.TIER_MAX_COPIES[tier]
		if counts[id] > limit:
			problems.append("Only %d copies of a Tier %s card are allowed (%s)." % [limit, Lore.TIER_NAMES[tier], d.name])
	if demigods > 1:
		problems.append("Only one Demigod card per deck.")
	if divines > 1:
		problems.append("Only one Divine card per deck.")
	if not has_base:
		problems.append("A deck needs at least one base Totem.")
	return problems
