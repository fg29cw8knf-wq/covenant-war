class_name Card
extends RefCounted
## One physical Sigil card in a duel.

var uid: int
var id: String
var def: Dictionary
var owner: int


func _init(p_uid: int, p_id: String, p_owner: int) -> void:
	uid = p_uid
	id = p_id
	def = SigilDB.CARDS[p_id]
	owner = p_owner


func card_name() -> String:
	return def.name


func kind() -> String:
	return def.kind


func tier() -> int:
	return int(def.get("tier", 1))


func is_creature() -> bool:
	return def.kind == "totem"


func is_energy() -> bool:
	return def.kind == "energy"


func is_trainer() -> bool:
	return def.kind == "rite" or def.kind == "ally"


func is_summon() -> bool:
	return def.kind == "summon"


func is_basic_creature() -> bool:
	return is_creature() and int(def.get("stage", 0)) == 0


func is_evolution() -> bool:
	return is_creature() and int(def.get("stage", 0)) > 0


func is_basic_energy() -> bool:
	return is_energy()


func is_supporter() -> bool:
	return def.kind == "ally"


func provides() -> Array:
	return def.get("provides", [])


func energy_units() -> int:
	return provides().size()
