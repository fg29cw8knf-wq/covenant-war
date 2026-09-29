class_name DuelCard
extends RefCounted
## One physical card in a duel.

var uid: int
var id: String
var def: Dictionary
var owner: int


func _init(p_uid: int, p_id: String, p_owner: int) -> void:
	uid = p_uid
	id = p_id
	def = DuelCards.CARDS[p_id]
	owner = p_owner


func card_name() -> String:
	return def.name


func kind() -> String:
	return def.kind


func cost() -> int:
	return int(def.get("cost", 0))


func tier() -> int:
	return int(def.get("tier", 1))


func element() -> String:
	return def.get("element", "any")


func is_totem() -> bool:
	return def.kind == "totem"


func is_basic_totem() -> bool:
	return def.kind == "totem" and int(def.get("stage", 0)) == 0


func is_ascension() -> bool:
	return def.kind == "totem" and int(def.get("stage", 0)) > 0


func is_rite() -> bool:
	return def.kind == "rite"


func is_ward() -> bool:
	return def.kind == "ward"


func is_summon() -> bool:
	return def.kind == "summon"


func _to_string() -> String:
	return "%s#%d" % [id, uid]
