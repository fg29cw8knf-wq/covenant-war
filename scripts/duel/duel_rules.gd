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
static var wake_roll := 11            # a sleeping Totem wakes on this or higher
static var thorns_damage := 10

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
		"burn_damage", "poison_damage", "shift_cost", "wrath_bonus", "mercy_heal"]


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
