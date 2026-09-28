class_name PlayerState
extends RefCounted
## Everything one duellist owns during a duel.

var index: int
var player_name: String
var deck_id: String
var profile: Dictionary = {}   # see Lore.new_profile(): attributes, patron, fortune
var deck: Array = []           # Card; top of deck = last element
var hand: Array = []
var discard: Array = []
var prizes: Array = []
var limbo: Array = []          # a card while it is being played
var active: Creature = null
var bench: Array = []
var controller = null

# per-turn flags
var energy_attached := 0
var energy_limit := 1
var supporter_played := false
var retreated := false
var free_retreat := false
var wrath := false

# per-duel flags
var gift_used := false
var foresight := false
var mulligans := 0


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


func in_play() -> Array:
	var out := []
	if active != null:
		out.append(active)
	out.append_array(bench)
	return out


func has_creatures_in_play() -> bool:
	return active != null or not bench.is_empty()


func total_card_count() -> int:
	var n := deck.size() + hand.size() + discard.size() + prizes.size() + limbo.size()
	for c in in_play():
		n += c.all_cards().size()
	return n


func hand_basics() -> Array:
	var out := []
	for c in hand:
		if c.is_basic_creature():
			out.append(c)
	return out
