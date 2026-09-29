class_name DuelTotem
extends RefCounted
## A Totem standing in one of the Circle's slots: its card stack (Basic at
## the bottom, the current Ascension on top), damage taken and conditions.

var uid: int
var owner: int
var slot := 0
var attrs: Dictionary = {}     # the owner's attributes
var stack: Array = []          # DuelCard; [0] is the Basic, last is the top
var damage := 0
var shield := 0                # prevents this much damage, then breaks
var bonus_hp := 0              # from the Resolve 7+ perk

var burn_turns := 0
var poisoned := false
var asleep := false
var stunned := false
var stun_turn := 0             # the game turn the stun was applied

var called_turn := 0
var ascended_turn := -1
var attacked := false          # this turn
var buff := 0                  # extra damage this turn (Forge Edge)
var hasted := false            # Swift for the turn it was called (Swiftness 7+)
var last_hit_by = null         # the DuelTotem that last damaged it (for Harvest and Wards)


func _init(card: DuelCard, p_owner: int, p_slot: int, turn: int, p_attrs: Dictionary) -> void:
	uid = card.uid
	owner = p_owner
	slot = p_slot
	stack = [card]
	called_turn = turn
	attrs = p_attrs
	if DuelRules.has_perk(attrs, "resolve"):
		bonus_hp = DuelRules.resolve_hp_bonus


func top() -> DuelCard:
	return stack[-1]


func def() -> Dictionary:
	return top().def


func id() -> String:
	return top().id


func card_name() -> String:
	return top().card_name()


func element() -> String:
	return def().element


func stage() -> int:
	return int(def().get("stage", 0))


func tier() -> int:
	return int(def().get("tier", 1))


func affinity() -> String:
	return def().get("affinity", "")


## True while the owner's affinity attribute meets the card's Attuned level.
func attuned() -> bool:
	var at: Dictionary = def().get("attuned", {})
	if at.is_empty():
		return false
	return int(attrs.get(affinity(), 0)) >= int(at.get("min", 99))


func attuned_value(key: String) -> int:
	if not attuned():
		return 0
	return int(def().attuned.get(key, 0))


func keywords() -> Array:
	var out: Array = def().get("keywords", []).duplicate()
	if hasted and not out.has("swift"):
		out.append("swift")
	if attuned():
		var k: String = def().attuned.get("keyword", "")
		if k != "" and not out.has(k):
			out.append(k)
	return out


func has_keyword(k: String) -> bool:
	return keywords().has(k)


func max_hp() -> int:
	return int(def().hp) + attuned_value("hp") + bonus_hp


func hp_left() -> int:
	return maxi(0, max_hp() - damage)


func is_knocked_out() -> bool:
	return damage >= max_hp()


func moves() -> Array:
	return def().get("moves", [])


func move(i: int) -> Dictionary:
	return moves()[i]


func move_cost(i: int) -> int:
	var c := int(move(i).get("cost", 0))
	if c > 0:
		c = maxi(1, c - attuned_value("cost"))
	return c


## A move that costs nothing is a Strike (the Might 7+ perk boosts these).
func is_strike(i: int) -> bool:
	return int(move(i).get("cost", 0)) == 0


func move_target(i: int) -> String:
	return move(i).get("target", "foe")


## Extra damage this Totem adds to its damaging moves.
func damage_bonus(i: int) -> int:
	var b := attuned_value("damage") + buff
	if is_strike(i) and DuelRules.has_perk(attrs, "might"):
		b += DuelRules.might_strike_bonus
	return b


func weak_to(attack_element: String) -> bool:
	return Lore.weak_to(element()).has(attack_element)


func conditions() -> Array:
	var out := []
	if burn_turns > 0:
		out.append("burn")
	if poisoned:
		out.append("poison")
	if stunned:
		out.append("stun")
	if asleep:
		out.append("sleep")
	return out


func has_condition() -> bool:
	return not conditions().is_empty()


func clear_conditions() -> void:
	burn_turns = 0
	poisoned = false
	asleep = false
	stunned = false


func all_cards() -> Array:
	return stack.duplicate()


func _to_string() -> String:
	return "%s(%d/%d)" % [card_name(), hp_left(), max_hp()]
