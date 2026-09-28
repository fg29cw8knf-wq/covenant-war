class_name Creature
extends RefCounted
## A Totem in play (Active or on the Bench): its Awakening stack, attached
## Energy, damage and Special Conditions, plus its owner's attributes so it
## knows whether its Attuned bonus is active.

static var _next_uid := 1

var uid: int
var owner: int
var attrs: Dictionary = {}  # the owner's attributes (might, resolve, ...)
var stack: Array = []      # Card; [0] is the base Totem, last is the current top card
var energy: Array = []
var damage := 0
var special := ""          # "", asleep, paralyzed, confused, frozen (one at a time)
var special_turn := 0
var poisoned := false
var burned := false
var turn_played := 0
var turn_evolved := -1
var protected_turn := -1   # all damage prevented during this game turn
var brace_turn := -1       # damage reduced during this game turn
var brace_amount := 0


func _init(base: Card, p_owner: int, turn: int, p_attrs: Dictionary = {}) -> void:
	uid = _next_uid
	_next_uid += 1
	owner = p_owner
	attrs = p_attrs
	stack = [base]
	turn_played = turn


func top() -> Card:
	return stack[stack.size() - 1]


func card_def() -> Dictionary:
	return top().def


func card_name() -> String:
	return top().def.name


func type() -> String:
	return top().def.element


func element() -> String:
	return top().def.element


func stage() -> int:
	return int(top().def.get("stage", 0))


func tier() -> int:
	return int(top().def.get("tier", 1))


func affinity() -> String:
	return top().def.get("affinity", "")


## True while the owner's attribute meets this card's Attuned threshold.
func attuned() -> bool:
	var a: Dictionary = top().def.get("attuned", {})
	if a.is_empty():
		return false
	return int(attrs.get(affinity(), 0)) >= int(a.get("min", 99))


func attuned_value(key: String) -> int:
	if not attuned():
		return 0
	var v = top().def.attuned.get(key, 0)
	if v is bool:
		return 1 if v else 0
	return int(v)


func max_hp() -> int:
	return int(top().def.hp) + attuned_value("hp")


func hp_left() -> int:
	return maxi(0, max_hp() - damage)


func is_knocked_out() -> bool:
	return damage >= max_hp()


func attacks() -> Array:
	return top().def.get("attacks", [])


## The cost after the Attuned discount (removes "any" symbols).
func attack_cost(atk: Dictionary) -> Array:
	var cost: Array = atk.cost.duplicate()
	var cut := attuned_value("cost")
	while cut > 0 and cost.has("any"):
		cost.erase("any")
		cut -= 1
	return cost


func retreat_cost() -> int:
	return maxi(0, int(top().def.get("retreat", 0)) - attuned_value("retreat"))


func damage_bonus() -> int:
	return attuned_value("damage")


func status_immune() -> bool:
	return attuned_value("immune") > 0


func weaknesses() -> Array:
	return Lore.weak_to(element())


func weakness() -> String:
	var w := weaknesses()
	return w[0] if not w.is_empty() else ""


func resistance() -> String:
	return top().def.get("resistance", "")


func energy_provided() -> Array:
	var out := []
	for e in energy:
		out.append_array(e.provides())
	return out


func energy_unit_count() -> int:
	return energy_provided().size()


func has_condition() -> bool:
	return special != "" or poisoned or burned


func conditions() -> Array:
	var out := []
	if special != "":
		out.append(special)
	if poisoned:
		out.append("poisoned")
	if burned:
		out.append("burned")
	return out


func clear_conditions() -> void:
	special = ""
	poisoned = false
	burned = false


func all_cards() -> Array:
	return stack + energy


func can_pay(cost: Array) -> bool:
	return Creature.cost_payable(energy_provided(), cost)


func can_use(atk: Dictionary) -> bool:
	return can_pay(attack_cost(atk))


static func cost_payable(provided: Array, cost: Array) -> bool:
	return missing_for_cost(provided, cost) == 0


## How many more Energy are needed to pay `cost` ("any" is paid by anything).
static func missing_for_cost(provided: Array, cost: Array) -> int:
	var pool := {}
	for t in provided:
		pool[t] = int(pool.get(t, 0)) + 1
	var missing := 0
	var any_needed := 0
	for c in cost:
		if c == "any":
			any_needed += 1
		elif int(pool.get(c, 0)) > 0:
			pool[c] = int(pool[c]) - 1
		else:
			missing += 1
	var remaining := 0
	for k in pool:
		remaining += int(pool[k])
	missing += maxi(0, any_needed - remaining)
	return missing


## Energy of `energy_type` attached beyond what the cost uses.
static func extra_of_type(provided: Array, cost: Array, energy_type: String) -> int:
	var have := 0
	var others := 0
	for t in provided:
		if t == energy_type:
			have += 1
		else:
			others += 1
	var typed_needed := 0
	var any_needed := 0
	for c in cost:
		if c == energy_type:
			typed_needed += 1
		elif c == "any":
			any_needed += 1
		else:
			others -= 1
	var spare := have - typed_needed
	var any_from_type := maxi(0, any_needed - maxi(0, others))
	return maxi(0, spare - any_from_type)
