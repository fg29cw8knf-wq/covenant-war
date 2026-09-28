extends Node
## Autoload "Game": the player's profile, deck, collection, story flags and
## where they are in the world. Saved to user://save.json.

signal changed

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1

var player_name := "Ash"
var profile: Dictionary = {}
var starter := ""
var deck: Array = []            # card ids in the player's current deck
var collection: Dictionary = {} # card id -> count owned (including the deck)
var flags: Dictionary = {}
var area := "solhaven"
var spawn := "gate"
var play_seconds := 0.0
var settings := {"music": 0.8, "sfx": 0.9, "text_speed": 1.0}


func _ready() -> void:
	_setup_input()
	load_settings_only()


func _process(delta: float) -> void:
	play_seconds += delta


# ------------------------------------------------------------ new game ---

func new_game(p_name: String, starter_deck: String) -> void:
	player_name = p_name.strip_edges() if p_name.strip_edges() != "" else "Ash"
	starter = starter_deck
	profile = Lore.new_profile(player_name, "")
	var bonus: Dictionary = SigilDB.DECKS[starter_deck].get("attributes", {})
	for k in bonus:
		Lore.add_attribute(profile, k, int(bonus[k]))
	deck = SigilDB.card_list(starter_deck)
	collection = {}
	for id in deck:
		collection[id] = int(collection.get(id, 0)) + 1
	flags = {}
	area = "solhaven"
	spawn = "gate"
	play_seconds = 0.0
	changed.emit()


func flag(key: String, default = false):
	return flags.get(key, default)


func set_flag(key: String, value = true) -> void:
	flags[key] = value
	changed.emit()


func add_card(id: String, n: int = 1) -> void:
	collection[id] = int(collection.get(id, 0)) + n
	changed.emit()


## A duellist profile for an NPC: attributes and patron for their AI.
static func npc_profile(npc_name: String, patron: String, bumps: Dictionary = {}) -> Dictionary:
	var p := Lore.new_profile(npc_name, patron)
	for k in bumps:
		Lore.add_attribute(p, k, int(bumps[k]))
	return p


# ---------------------------------------------------------------- save ---

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	var data := {
		"version": SAVE_VERSION,
		"player_name": player_name,
		"profile": profile,
		"starter": starter,
		"deck": deck,
		"collection": collection,
		"flags": flags,
		"area": area,
		"spawn": spawn,
		"play_seconds": play_seconds,
		"settings": settings,
		"saved_at": Time.get_datetime_string_from_system(),
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Couldn't write the save file: %s" % error_string(FileAccess.get_open_error()))
		return false
	f.store_string(JSON.stringify(data, "\t"))
	return true


func load_game() -> bool:
	var data := _read_save()
	if data.is_empty():
		return false
	player_name = data.get("player_name", "Ash")
	profile = data.get("profile", Lore.new_profile(player_name))
	# JSON turns ints into floats; tidy the attributes back into ints.
	for key in ["base", "attributes"]:
		var d: Dictionary = profile.get(key, {})
		for a in d:
			d[a] = int(d[a])
	starter = data.get("starter", "")
	deck = data.get("deck", [])
	collection = {}
	var c: Dictionary = data.get("collection", {})
	for k in c:
		collection[k] = int(c[k])
	flags = data.get("flags", {})
	area = data.get("area", "solhaven")
	spawn = data.get("spawn", "gate")
	play_seconds = float(data.get("play_seconds", 0.0))
	settings.merge(data.get("settings", {}), true)
	changed.emit()
	return true


func load_settings_only() -> void:
	var data := _read_save()
	if not data.is_empty():
		settings.merge(data.get("settings", {}), true)


func save_summary() -> String:
	var data := _read_save()
	if data.is_empty():
		return ""
	var mins := int(float(data.get("play_seconds", 0)) / 60.0)
	return "%s  ·  %s  ·  %dh %02dm" % [data.get("player_name", "?"), String(data.get("area", "")).capitalize(), mins / 60, mins % 60]


func _read_save() -> Dictionary:
	if not has_save():
		return {}
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		return parsed
	return {}


# --------------------------------------------------------------- input ---

func _setup_input() -> void:
	var keys := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"interact": [KEY_E, KEY_SPACE, KEY_ENTER],
		"menu": [KEY_ESCAPE, KEY_TAB],
	}
	for action in keys:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action, 0.2)
		for k in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
	var pads := {
		"interact": JOY_BUTTON_A,
		"menu": JOY_BUTTON_START,
	}
	for action in pads:
		var ev := InputEventJoypadButton.new()
		ev.button_index = pads[action]
		InputMap.action_add_event(action, ev)
	var axes := {"move_left": [JOY_AXIS_LEFT_X, -1.0], "move_right": [JOY_AXIS_LEFT_X, 1.0],
		"move_up": [JOY_AXIS_LEFT_Y, -1.0], "move_down": [JOY_AXIS_LEFT_Y, 1.0]}
	for action in axes:
		var ev := InputEventJoypadMotion.new()
		ev.axis = axes[action][0]
		ev.axis_value = axes[action][1]
		InputMap.action_add_event(action, ev)
