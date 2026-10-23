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

## Conditions, one per kind (DuelConditions.KINDS): kind -> {id, left,
## applied (the game turn it was put on), src_uid, src_owner, dawns}.
var conds := {}
## Boons: id -> {left, applied}. Shielded is the `shield` number above.
var boons := {}
var is_boss := false           # bosses shrug off some conditions

## Read-only shortcuts kept for the duel screen and older code.
var asleep: bool:
	get: return has_status("sleep")
var stunned: bool:
	get: return has_status("stun")
var poisoned: bool:
	get: return has_status("poison")
var burn_turns: int:
	get: return int(conds.get("body", {}).get("left", 0)) if has_status("burn") else 0

var called_turn := 0
var ascended_turn := -1
var attacked := false          # this turn
## Its stance (Phase A): strike, guard (takes half damage, can't attack) or
## rest (mended when set, an Essence at its owner's next turn; can't attack or Shift). Set in
## its owner's Main phase, back to Strike at their next turn.
var stance := "strike"
var stance_turn := -1          # the game turn its stance was set on (one stance a turn)
## Phase C: what a Totem is beyond its card.
var bond: Dictionary = {}      # the bond it's in while its partner stands beside it (DuelCards.BONDS), else {}
var relic: DuelCard = null     # the Relic it carries (one each); lost when it falls
var face_down := false         # called veiled: its rival sees only a card back until it's revealed
var temper := {}               # its owner's Tempering marks, card id -> 1 to 3 (Codex re-absorbs)
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
	var rk := String(relic_def().get("keyword", ""))
	if rk != "" and not out.has(rk):
		out.append(rk)
	if hasted and not out.has("swift"):
		out.append("swift")
	if attuned():
		var k: String = def().attuned.get("keyword", "")
		if k != "" and not out.has(k):
			out.append(k)
	return out


func has_keyword(k: String) -> bool:
	return keywords().has(k)


## The Relic's effect ({} when it carries none).
func relic_def() -> Dictionary:
	return relic.def.get("relic", {}) if relic != null else {}


## Its line's Tempering marks (by the Basic at the bottom, so they stay
## through Ascension).
func temper_level() -> int:
	return int(temper.get(String(stack[0].id), 0))


func max_hp() -> int:
	var hp := int(def().hp) + attuned_value("hp") + bonus_hp + int(relic_def().get("hp", 0)) + int(bond.get("hp", 0))
	if temper_level() >= 1:
		hp += 20   # Tempered once: +20 Life
	return hp


func hp_left() -> int:
	return maxi(0, max_hp() - damage)


func is_knocked_out() -> bool:
	return damage >= max_hp()


## Its moves: the card's own, then a bond move while its partner stands
## beside it, a Relic's move, and a Tempered move (three marks).
func moves() -> Array:
	var base: Array = def().get("moves", [])
	var lvl := temper_level()
	if bond.is_empty() and relic_def().get("move", {}).is_empty() and lvl < 2:
		return base
	var out: Array = base.duplicate()
	if lvl >= 2:
		# Tempered twice: the best Fate band on its first Fate move starts two lower
		for i in out.size():
			if (out[i] as Dictionary).has("fate"):
				var m: Dictionary = (out[i] as Dictionary).duplicate(true)
				var bands: Array = m.fate
				if bands.size() >= 2:
					bands[-2]["to"] = maxi(int(bands[-3].get("to", 0)) + 1 if bands.size() >= 3 else 1, int(bands[-2].to) - 2)
				out[i] = m
				break
	if lvl >= 3:
		var strongest: Dictionary = {}
		for m in base:
			if strongest.is_empty() or int(m.get("damage", 0)) > int(strongest.get("damage", 0)):
				strongest = m
		var tm := {"name": "Tempered %s" % String(strongest.get("name", "Strike")), "cost": maxi(1, int(strongest.get("cost", 0)) + 1),
			"damage": maxi(int(strongest.get("damage", 0)), 30) + 20, "tempered": true}
		out.append(tm)
	if not bond.is_empty() and bond.has("move"):
		var bm: Dictionary = (bond.move as Dictionary).duplicate(true)
		bm["bond"] = String(bond.get("partner", ""))
		out.append(bm)
	var rm: Dictionary = relic_def().get("move", {})
	if not rm.is_empty():
		var r2 := rm.duplicate(true)
		r2["relic"] = relic.id
		out.append(r2)
	return out


func move(i: int) -> Dictionary:
	return moves()[i]


func move_cost(i: int) -> int:
	var c := int(move(i).get("cost", 0))
	if c > 0:
		c = maxi(1, c - attuned_value("cost"))
		if has_boon("hastened"):
			c = maxi(1, c - 1)
		if has_status("hexed"):
			c += 1
	return c


## A move that costs nothing is a Strike (the Might 7+ perk boosts these).
func is_strike(i: int) -> bool:
	return int(move(i).get("cost", 0)) == 0


func move_target(i: int) -> String:
	return move(i).get("target", "foe")


## Extra damage this Totem adds to its damaging moves.
func damage_bonus(i: int) -> int:
	var b := attuned_value("damage") + buff + int(relic_def().get("damage", 0)) + int(bond.get("damage", 0))
	if is_strike(i) and DuelRules.has_perk(attrs, "might"):
		b += DuelRules.might_strike_bonus
	if has_status("enraged"):
		b += DuelRules.enraged_bonus
	if has_boon("empowered"):
		b += DuelRules.empowered_bonus
	return b


func weak_to(attack_element: String) -> bool:
	return Lore.weak_to(element()).has(attack_element)


## The ids of the conditions it carries (Body, then Mind, then Soul).
func conditions() -> Array:
	var out := []
	for k in DuelConditions.KINDS:
		if conds.has(k):
			out.append(conds[k].id)
	return out


func has_condition() -> bool:
	return not conds.is_empty()


func has_status(id: String) -> bool:
	var k := DuelConditions.kind_of(id)
	return k != "" and conds.has(k) and conds[k].id == id


## The condition of one kind ({} if none).
func cond(kind: String) -> Dictionary:
	return conds.get(kind, {})


func condition_of(id: String) -> Dictionary:
	if not has_status(id):
		return {}
	return conds[DuelConditions.kind_of(id)]


## Puts a condition on, replacing any other of the same kind.
func set_status(id: String, game_turn: int, src_uid: int = -1, src_owner: int = -1) -> void:
	var k := DuelConditions.kind_of(id)
	if k == "":
		return
	conds[k] = {"id": id, "left": DuelConditions.turns(id), "applied": game_turn,
		"src_uid": src_uid, "src_owner": src_owner, "dawns": 0}


func remove_status(id: String) -> void:
	if has_status(id):
		conds.erase(DuelConditions.kind_of(id))


## Clears every condition, or just one kind ("body", "mind" or "soul").
func clear_conditions(kind: String = "") -> void:
	if kind == "" or kind == "all":
		conds.clear()
	else:
		conds.erase(kind)


func has_boon(id: String) -> bool:
	if id == "shielded":
		return shield > 0
	return boons.has(id)


func add_boon(id: String, game_turn: int) -> void:
	if id == "shielded":
		shield += DuelRules.shielded_amount
		return
	boons[id] = {"left": DuelConditions.turns(id), "applied": game_turn}


func remove_boon(id: String) -> void:
	if id == "shielded":
		shield = 0
	boons.erase(id)


## Boons it carries, for the nameplate.
func boon_list() -> Array:
	var out := []
	if shield > 0:
		out.append("shielded")
	for b in boons:
		out.append(b)
	return out


func all_cards() -> Array:
	var out := stack.duplicate()
	if relic != null:
		out.append(relic)
	return out


func _to_string() -> String:
	return "%s(%d/%d)" % [card_name(), hp_left(), max_hp()]
