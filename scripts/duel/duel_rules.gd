class_name DuelRules
extends RefCounted
## Every tunable number in the duel, in one place. These mirror the
## "Duel Rules v1" page. They are static vars (not consts) so the Duel Lab's
## tuning panel and the balance tests can change them while the game runs;
## call reset() to put them back.

# --- the board ---------------------------------------------------------------
const SLOTS := 3                  # Totem slots per side
static var ward_slots := 2        # 3 with Cunning 7+
static var deck_size := 30
static var start_hand := 5
static var second_player_bonus_cards := 1
static var hand_limit := 10

# --- Life ----------------------------------------------------------------------
static var life_base := 150
static var life_per_attribute := 5    # for every attribute point
static var guard_min_hit := 10        # Guard never reduces a hit below this
static var fatigue := 30              # Life lost for drawing from an empty deck

# --- Essence -------------------------------------------------------------------
static var essence_cap := 10
static var shift_cost := 1

# --- damage and conditions -----------------------------------------------------
static var weakness_mult := 1.5
static var burn_damage := 20
static var burn_turns := 2
static var poison_damage := 10
static var wake_roll := 11            # breaking free (Sleep, Frozen, Possessed) needs this or higher
static var thorns_damage := 10
# v2 conditions (see DuelConditions)
static var corroded_bonus := 10       # every hit on a Corroded Totem
static var bleed_damage := 10         # each time a Bleeding Totem attacks or Shifts
static var shock_fail := 8            # a Shocked Totem's attack fails on 1 to this
static var blind_fail := 10           # a Blinded Totem's attack misses on 1 to this
static var confuse_fail := 7          # a Confused Totem hits its own side on 1 to this
static var soaked_bonus := 20         # Storm and Frost hits on a Soaked Totem
static var enraged_bonus := 10       # an Enraged Totem deals this much more...
static var enraged_exposed := 20      # ...and takes this much more from every hit
static var frozen_roll := 14          # a Frozen Totem breaks free on this or higher
static var marked_bonus := 20
static var doom_dawns := 3            # a Doomed Totem falls at its owner's third Dawn
# boons
static var shielded_amount := 30
static var empowered_bonus := 20
static var regen_heal := 10

# --- attribute perks (the "7+" column) ------------------------------------------
static var perk_level := 7
static var might_strike_bonus := 10
static var resolve_hp_bonus := 10
static var intellect_hand_bonus := 1
static var presence_discount := 1

# --- Divine Gifts ----------------------------------------------------------------
static var mercy_heal := 50
static var wrath_bonus := 30
static var tempest_essence := 3

# --- safety ------------------------------------------------------------------------
static var max_turns := 60             # a duel this long is a draw
const MAX_ACTIONS_PER_TURN := 60

## The defaults, for reset() and for showing what the tuning panel changed.
static var _defaults := {}


static func tunables() -> Array:
	return ["life_base", "life_per_attribute", "guard_min_hit", "fatigue", "essence_cap",
		"start_hand", "second_player_bonus_cards", "hand_limit", "weakness_mult",
		"burn_damage", "poison_damage", "shift_cost", "wrath_bonus", "mercy_heal",
		"corroded_bonus", "bleed_damage", "shock_fail", "blind_fail", "confuse_fail", "soaked_bonus", "enraged_bonus", "marked_bonus", "doom_dawns", "enraged_exposed", "frozen_roll", "shielded_amount", "empowered_bonus", "regen_heal", "wake_roll", "burn_turns"]


static func snapshot() -> Dictionary:
	var d := {}
	for k in tunables():
		d[k] = get_value(k)
	return d


static func get_value(key: String):
	match key:
		"life_base": return life_base
		"life_per_attribute": return life_per_attribute
		"guard_min_hit": return guard_min_hit
		"fatigue": return fatigue
		"essence_cap": return essence_cap
		"start_hand": return start_hand
		"second_player_bonus_cards": return second_player_bonus_cards
		"hand_limit": return hand_limit
		"weakness_mult": return weakness_mult
		"burn_damage": return burn_damage
		"poison_damage": return poison_damage
		"shift_cost": return shift_cost
		"wrath_bonus": return wrath_bonus
		"mercy_heal": return mercy_heal
		"corroded_bonus": return corroded_bonus
		"bleed_damage": return bleed_damage
		"shock_fail": return shock_fail
		"blind_fail": return blind_fail
		"confuse_fail": return confuse_fail
		"soaked_bonus": return soaked_bonus
		"enraged_bonus": return enraged_bonus
		"marked_bonus": return marked_bonus
		"doom_dawns": return doom_dawns
		"enraged_exposed": return enraged_exposed
		"frozen_roll": return frozen_roll
		"shielded_amount": return shielded_amount
		"empowered_bonus": return empowered_bonus
		"regen_heal": return regen_heal
		"wake_roll": return wake_roll
		"burn_turns": return burn_turns
	return null


static func set_value(key: String, v) -> void:
	if _defaults.is_empty():
		_defaults = snapshot()
	match key:
		"life_base": life_base = int(v)
		"life_per_attribute": life_per_attribute = int(v)
		"guard_min_hit": guard_min_hit = int(v)
		"fatigue": fatigue = int(v)
		"essence_cap": essence_cap = int(v)
		"start_hand": start_hand = int(v)
		"second_player_bonus_cards": second_player_bonus_cards = int(v)
		"hand_limit": hand_limit = int(v)
		"weakness_mult": weakness_mult = float(v)
		"burn_damage": burn_damage = int(v)
		"poison_damage": poison_damage = int(v)
		"shift_cost": shift_cost = int(v)
		"wrath_bonus": wrath_bonus = int(v)
		"mercy_heal": mercy_heal = int(v)
		"corroded_bonus": corroded_bonus = int(v)
		"bleed_damage": bleed_damage = int(v)
		"shock_fail": shock_fail = int(v)
		"blind_fail": blind_fail = int(v)
		"confuse_fail": confuse_fail = int(v)
		"soaked_bonus": soaked_bonus = int(v)
		"enraged_bonus": enraged_bonus = int(v)
		"marked_bonus": marked_bonus = int(v)
		"doom_dawns": doom_dawns = int(v)
		"enraged_exposed": enraged_exposed = int(v)
		"frozen_roll": frozen_roll = int(v)
		"shielded_amount": shielded_amount = int(v)
		"empowered_bonus": empowered_bonus = int(v)
		"regen_heal": regen_heal = int(v)
		"wake_roll": wake_roll = int(v)
		"burn_turns": burn_turns = int(v)


static func reset() -> void:
	if _defaults.is_empty():
		return
	for k in _defaults:
		set_value(k, _defaults[k])


# --- formulas --------------------------------------------------------------------

## Starting Life for a duellist with these attributes.
static func life_for(attrs: Dictionary) -> int:
	var total := 0
	for a in Lore.ATTRIBUTES:
		total += int(attrs.get(a, 0))
	return life_base + life_per_attribute * total


## Guard: each hit on Life is reduced by this.
static func guard_for(attrs: Dictionary) -> int:
	return int(attrs.get("resolve", 0))


## Fate roll modifier from an attribute: +1 per 3 points.
static func fate_mod(attr_value: int) -> int:
	return attr_value / 3


## True when the attribute unlocks its 7+ perk.
static func has_perk(attrs: Dictionary, attribute: String) -> bool:
	return int(attrs.get(attribute, 0)) >= perk_level
