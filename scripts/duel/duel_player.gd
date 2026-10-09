class_name DuelPlayer
extends RefCounted
## Everything one duellist owns during a duel.

var index: int
var player_name: String
var deck_id := "custom"
var profile: Dictionary = {}   # see Lore.new_profile(): attributes, patron, fortune
var controller = null

var deck: Array = []           # DuelCard; top of deck = last element
var hand: Array = []
var discard: Array = []
var spent: Array = []          # Summons that have returned to the heavens
var slots: Array = [null, null, null]   # DuelTotem or null
var wards: Array = []          # DuelCard, face down

var life := 0
var max_life := 0
var essence := 0
var essence_max := 0

# per turn
var shifts := 0
var totems_called := 0
var wrath := false
var free_shift := false

# per duel
var gift_used := false
var fortune_left := 0
var foresight := false
var pending_essence := 0      # Essence drained from the opponent, gained next turn
var guard_bonus := 0          # Hethrin's Blessing
var guard_double := false     # Forged Guard, until this duellist's next Dawn
var extra_ward_slots := 0     # Nocthra's Law
var fate_bonus := 0           # Star Chart, for the rest of this turn
var rite_recalled := false    # Aldrith's Blessing, once a duel
var fallen: Array = []        # the stage of each of this duellist's Totems knocked out (for Resonance)
var survived := false

# statistics for the balance tests
var played := {}              # card id -> times played this duel
var stats := {"life_damage_dealt": 0, "kos": 0, "totems_called": 0, "rites": 0, "wards_sprung": 0,
	"fate_rolls": 0, "essence_spent": 0, "summons": 0, "ascensions": 0}


func _init(p_index: int, p_name: String) -> void:
	index = p_index
	player_name = p_name


func attributes() -> Dictionary:
	return profile.get("attributes", {})


func attribute(a: String) -> int:
	return int(attributes().get(a, 0))


func patron() -> String:
	return profile.get("patron", "")


func gift() -> String:
	var p := patron()
	if p == "":
		return Lore.UNSWORN_GIFT
	return Lore.GODS[p].gift


func guard() -> int:
	var g := DuelRules.guard_for(attributes()) + guard_bonus
	return g * 2 if guard_double else g


func ward_slots() -> int:
	return DuelRules.ward_slots + extra_ward_slots + (1 if DuelRules.has_perk(attributes(), "cunning") else 0)


func totems() -> Array:
	var out := []
	for t in slots:
		if t != null:
			out.append(t)
	return out


func empty_slots() -> Array:
	var out := []
	for i in slots.size():
		if slots[i] == null:
			out.append(i)
	return out


func has_guardian() -> bool:
	for t in totems():
		if t.has_keyword("guardian"):
			return true
	return false


func total_card_count() -> int:
	var n := deck.size() + hand.size() + discard.size() + spent.size() + wards.size()
	for t in totems():
		n += t.stack.size()
	return n


func hand_basics() -> Array:
	var out := []
	for c in hand:
		if c.is_basic_totem():
			out.append(c)
	return out


func note_played(id: String) -> void:
	played[id] = int(played.get(id, 0)) + 1
