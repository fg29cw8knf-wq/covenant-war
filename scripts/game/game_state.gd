extends Node
## Autoload "Game": the player's profile, deck, collection, story flags and
## where they are in the world. Saved to user://save.json.

signal changed

const SAVE_PATH := "user://save.json"
const SETTINGS_PATH := "user://settings.json"
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
var settings := {"music": 0.8, "sfx": 0.9, "text_speed": 1.0, "violence": "full"}
## v2 progress (see DuelRewards and "Duel Rules v2"): the player's v2 card
## collection, Sigil Rank, Seals, Codex, Resonance and Attunement.
var v2 := {}


func _ready() -> void:
	_setup_input()
	load_settings_only()


func _process(delta: float) -> void:
	play_seconds += delta


# ------------------------------------------------------------ new game ---

## keep_progress: keep the v2 Rank, Codex and Resonance already earned (the
## Prologue calls this again once the player picks Bram's deck).
func new_game(p_name: String, starter_deck: String, keep_progress := false) -> void:
	var kept := v2.duplicate(true) if keep_progress else {}
	player_name = p_name.strip_edges() if p_name.strip_edges() != "" else "Ash"
	starter = starter_deck
	profile = Lore.new_profile(player_name, "")
	var bonus: Dictionary = DuelCards.DECKS.get(starter_deck, SigilDB.DECKS.get(starter_deck, {})).get("attributes", {})
	for k in bonus:
		Lore.add_attribute(profile, k, int(bonus[k]))
	# The old-rules deck, still used by the Solhaven prototype's duels until
	# Chapter 1 moves to the v2 rules. Veilwild has no old version, so it
	# borrows the old Psychic deck.
	deck = SigilDB.card_list(starter_deck if SigilDB.DECKS.has(starter_deck) else "wren")
	collection = {}
	for id in deck:
		collection[id] = int(collection.get(id, 0)) + 1
	flags = {}
	area = "solhaven"
	spawn = "gate"
	play_seconds = 0.0
	v2 = new_v2(starter_deck)
	if not kept.is_empty():
		for k in ["rank", "xp", "points", "banked", "target", "pool"]:
			if kept.has(k):
				v2[k] = kept[k]
		for id in kept.get("codex", {}):
			if not v2.codex.has(id) or String(kept.codex[id]) == "champion":
				v2.codex[id] = kept.codex[id]
	changed.emit()


# ------------------------------------------------------------- v2 progress ---

## Fresh v2 progress: Bram's starter deck, Bonded (so every card answers at
## any Rank), Rank 1.
static func new_v2(starter_deck: String) -> Dictionary:
	var v := {"rank": 1, "xp": 0, "points": 0, "seals": [], "convocation": false,
		"collection": {}, "bonded": {}, "codex": {}, "target": "", "target_chosen": false, "banked": {},
		"attune": {}, "stage": {}, "pool": 0, "deck": []}
	if DuelCards.DECKS.has(starter_deck):
		v.deck = DuelCards.card_list(starter_deck)
		for id in v.deck:
			v.collection[id] = int(v.collection.get(id, 0)) + 1
			v.bonded[id] = true
			v.codex[id] = "seen"
	return v


func _v2() -> Dictionary:
	if v2.is_empty():
		v2 = new_v2(starter)
	return v2


func rank() -> int:
	return int(_v2().rank)


func rank_cap() -> int:
	return DuelRewards.rank_cap(_v2().seals.size(), bool(_v2().convocation))


## Does this card answer the player at their Rank?
func card_answers(id: String) -> bool:
	var v := _v2()
	if v.bonded.has(id):
		return true
	var tier := int(DuelCards.CARDS.get(id, {}).get("tier", 1))
	return tier <= DuelRewards.tier_cap(int(v.rank))


## Every card the player could pour Resonance into right now: the ones they
## own fewest of first, then the cheapest.
func resonance_choices() -> Array:
	var v := _v2()
	var out := []
	for id in v.codex:
		if DuelRewards.eligible(id, int(v.rank), v.codex):
			out.append(id)
	out.sort_custom(func(a, b):
		var na := int(v.collection.get(a, 0))
		var nb := int(v.collection.get(b, 0))
		if na != nb:
			return na < nb
		if DuelRewards.card_cost(a) != DuelRewards.card_cost(b):
			return DuelRewards.card_cost(a) < DuelRewards.card_cost(b)
		return a < b)
	return out


## The player picks which card their Resonance builds towards.
func set_resonance_target(id: String) -> void:
	_v2().target = id
	_v2().target_chosen = true
	changed.emit()


## Records a won v2 duel: adds the cards seen to the Codex, pours the
## Resonance into the target card (crystallising it when full, overflow to
## the Attunement pool) and adds Rank XP. Returns what happened, for the
## result screen.
func record_win(game: DuelGame, me: int, opponent_kind: String, thick := false, ad := false) -> Dictionary:
	var v := _v2()
	var seen_as := "champion" if opponent_kind in ["champion", "boss"] else "seen"
	for p in game.players:
		for id in p.played:
			if String(v.codex.get(id, "")) != "champion":
				v.codex[id] = seen_as
	var res := DuelRewards.resonance(game, me, opponent_kind, thick, ad)
	var out := {"resonance": res, "made": [], "overflow": 0, "rank_before": int(v.rank), "xp_before": int(v.xp)}
	var amount: int = res.total
	if v.target == "" or not DuelRewards.eligible(String(v.target), int(v.rank), v.codex):
		var ch := resonance_choices()
		v.target = ch[0] if not ch.is_empty() else ""
		v.target_chosen = false
	out["target"] = v.target
	out["banked_before"] = int(v.banked.get(v.target, 0))
	if v.target == "":
		v.pool = int(v.pool) + amount
		out.overflow = amount
	else:
		var have := int(v.banked.get(v.target, 0)) + amount
		var cost := DuelRewards.card_cost(v.target)
		if have >= cost:
			v.collection[v.target] = int(v.collection.get(v.target, 0)) + 1
			out.made.append(v.target)
			v.banked.erase(v.target)
			v.pool = int(v.pool) + (have - cost)
			out.overflow = have - cost
			if not bool(v.get("target_chosen", false)):
				v.target = ""   # an automatic target moves on to the next card
		else:
			v.banked[v.target] = have
	out["banked_after"] = int(v.banked.get(v.target, 0))
	# Rank
	var cap := rank_cap()
	v.xp = int(v.xp) + amount
	var ups := 0
	while int(v.rank) < cap and int(v.xp) >= DuelRewards.xp_to_next(int(v.rank)):
		v.xp = int(v.xp) - DuelRewards.xp_to_next(int(v.rank))
		v.rank = int(v.rank) + 1
		v.points = int(v.points) + DuelRewards.POINTS_PER_RANK
		ups += 1
	out["rank_after"] = int(v.rank)
	out["xp_after"] = int(v.xp)
	out["xp_next"] = DuelRewards.xp_to_next(int(v.rank))
	out["capped"] = int(v.rank) >= cap
	out["ranks_gained"] = ups
	changed.emit()
	return out


## Spends an attribute point on one attribute.
func spend_point(attribute: String) -> bool:
	var v := _v2()
	if int(v.points) <= 0 or int(profile.get("base", {}).get(attribute, 10)) >= 10:
		return false
	v.points = int(v.points) - 1
	Lore.add_attribute(profile, attribute, 1)
	changed.emit()
	return true


## Spare copies of a Totem: owned beyond the copies in the deck, never the last one.
func spare_copies(id: String) -> int:
	var v := _v2()
	var owned := int(v.collection.get(id, 0))
	var in_deck := 0
	for c in v.get("deck", []):
		if c == id:
			in_deck += 1
	return maxi(0, owned - maxi(1, in_deck))


## Re-absorbs spare copies of a Basic Totem into its Attunement store.
## Returns the Ascension card manifested, if the store filled.
func reabsorb(id: String, copies: int) -> String:
	var v := _v2()
	copies = mini(copies, spare_copies(id))
	if copies <= 0 or not DuelCards.is_basic_totem(id):
		return ""
	v.collection[id] = int(v.collection[id]) - copies
	v.attune[id] = int(v.attune.get(id, 0)) + copies * DuelRewards.copy_points(id)
	return _try_manifest(id)


## Pours Attunement pool points (at half value) into a Totem's store.
func pour_pool(id: String, points: int) -> String:
	var v := _v2()
	points = mini(points, int(v.pool))
	if points <= 0:
		return ""
	v.pool = int(v.pool) - points
	v.attune[id] = int(v.attune.get(id, 0)) + int(points * DuelRewards.POOL_RATE)
	return _try_manifest(id)


func _try_manifest(id: String) -> String:
	var v := _v2()
	var done := int(v.stage.get(id, 0))
	var next := DuelRewards.next_ascension(id, done)
	if next == "":
		return ""
	var need := DuelRewards.store_needed(done)
	if int(v.attune.get(id, 0)) < need:
		changed.emit()
		return ""
	v.attune[id] = int(v.attune[id]) - need
	v.stage[id] = done + 1
	v.collection[next] = int(v.collection.get(next, 0)) + 1
	changed.emit()
	return next


## Earns a kingdom's Seal (raises the Rank cap).
func add_seal(kingdom: String) -> void:
	var v := _v2()
	if not v.seals.has(kingdom):
		v.seals.append(kingdom)
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
		"v2": v2,
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
	v2 = _ints(data.get("v2", {}))
	changed.emit()
	return true


## JSON turns every number into a float; turn whole numbers back into ints.
static func _ints(x):
	if x is Dictionary:
		var d := {}
		for k in x:
			d[k] = _ints(x[k])
		return d
	if x is Array:
		return x.map(func(e): return _ints(e))
	if x is float and x == floor(x):
		return int(x)
	return x


func load_settings_only() -> void:
	var data := _read_save()
	if not data.is_empty():
		settings.merge(data.get("settings", {}), true)
	if FileAccess.file_exists(SETTINGS_PATH):
		var f := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		var parsed = JSON.parse_string(f.get_as_text()) if f != null else null
		if parsed is Dictionary:
			settings.merge(parsed, true)


## Settings are also kept on their own, so they survive without a save game.
func save_settings() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(settings, "\t"))


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
