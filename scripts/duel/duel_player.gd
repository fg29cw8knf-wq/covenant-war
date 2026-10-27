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
var hand_wards_used: Array = []   # Wards played from the hand in answer this duel (once each, by card id)
var answering: Array = []      # DuelCard: answers on the chain, between being played and resolving
var once_used: Array = []      # once-a-duel things already spent: "echo:<uid>", "rekindle:<uid>" (Phase B)
var continuous: Array = []     # DuelCard: Continuous Rites standing on this side, two at most (Phase D)
var arena_guard := 0           # Guard the arena adds (Ironstone's, Phase D)
var favour2 := 0               # Favour, in half points (the Unsworn fill at half pace; Phase D)
var favour_ready := false      # full: a second Gift, or the god's Demigod, free
var oath := ""                 # the Oath sworn (DuelGame.OATHS), "" for none
var oath_state := ""           # "sworn", "kept" or "broken"
var oath_start_used := false   # the Oath at the start of the duel (on your first turn)
var oath_mid_used := false     # ...and the one mid-duel

# statistics for the balance tests
var played := {}              # card id -> times played this duel
var stats := {"life_damage_dealt": 0, "kos": 0, "totems_called": 0, "rites": 0, "wards_sprung": 0,
	"fate_rolls": 0, "essence_spent": 0, "summons": 0, "ascensions": 0, "answers": 0, "stances": 0,
	"tributes": 0, "echoes": 0, "revivals": 0, "relics": 0, "veiled": 0, "bond_moves": 0,
	"terrains": 0, "continuous": 0, "favour_fills": 0, "demigods": 0, "oaths": 0, "oaths_kept": 0, "oaths_broken": 0}


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
	var g := DuelRules.guard_for(attributes()) + guard_bonus + arena_guard
	return g * 2 if guard_double else g


## Favour, 0 to DuelRules.favour_max (Phase D).
func favour() -> float:
	return favour2 / 2.0


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


## The duellist's own cards, wherever they are (not counting one a god sent
## them mid-duel: Rallying Light, 27 October).
func total_card_count() -> int:
	var n := 0
	for pile in [deck, hand, discard, spent, wards, answering, continuous]:
		for c in pile:
			if not (c as DuelCard).def.get("granted", false):
				n += 1
	for t in totems():
		n += t.stack.size() + (1 if t.relic != null else 0)
	return n


func hand_basics() -> Array:
	var out := []
	for c in hand:
		if c.is_basic_totem():
			out.append(c)
	return out


func note_played(id: String) -> void:
	played[id] = int(played.get(id, 0)) + 1
