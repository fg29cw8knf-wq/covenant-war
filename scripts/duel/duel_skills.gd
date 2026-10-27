class_name DuelSkills
extends RefCounted
## Duel skills (27 October, Gary: "add all the go battles"): one each side,
## shown on the duellist's plate, each working once a duel by itself (no
## button to press). A story rival with no rule of their own has one (Tam's
## Loyal Hound, Nell's Old Wards); the player chooses theirs in the menu,
## under Deck, from the ones they know. Beating Tam and Nell teaches theirs,
## and the Lantern Duel teaches Corin's. The rules engine plays them
## (DuelGame.has_skill / _use_skill); the screen shows them (fx_skill).

const SKILLS := {
	"second_wind": {"name": "Second Wind",
		"text": "The first time your Life falls to half or less, each of your Totems heals 30."},
	"quick_start": {"name": "Quick Start",
		"text": "Your first turn starts with 1 more Essence."},
	"lucky_charm": {"name": "Lucky Charm",
		"text": "Your first Fate roll is rolled twice, and the better roll counts."},
	"keen_eye": {"name": "Keen Eye",
		"text": "Your rival's first Ward is set face up, where you can read it."},
	"loyal_hound": {"name": "Loyal Hound", "from": "Tam",
		"text": "The first time one of your Totems would be knocked out, it holds on with 10 HP."},
	"old_wards": {"name": "Old Wards", "from": "Old Nell",
		"text": "Your first Ward costs no Essence."},
	"showman": {"name": "Showman", "from": "Corin",
		"text": "Your first attack deals 20 more."},
}
## Every duellist knows these from the start.
const STARTERS := ["second_wind", "quick_start", "lucky_charm", "keen_eye"]
## ...and these are learned by beating their owner (the story flag that says so).
const LEARNED_BY := {"showman": "ash_won_lantern", "loyal_hound": "beat_tam", "old_wards": "beat_nell"}
const DEFAULT := "second_wind"
## How much a skill gives, where it's a number.
const SECOND_WIND_HEAL := 30
const LOYAL_HOLD := 10
const SHOWMAN_BONUS := 20


static func skill_name(id: String) -> String:
	return String(SKILLS.get(id, {}).get("name", ""))


static func text(id: String) -> String:
	return String(SKILLS.get(id, {}).get("text", ""))


## The game's state (the Game autoload), looked up when it's wanted: the
## rules engine is compiled before the autoloads exist in a headless test.
static func _state() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null("Game") if tree != null else null


## The skills the player can choose from now (the starters, then any learned).
static func known() -> Array:
	var out: Array = STARTERS.duplicate()
	var g := _state()
	for id in LEARNED_BY:
		if g != null and g.flag(String(LEARNED_BY[id]), false):
			out.append(id)
	return out


## The player's chosen skill (a known one; Second Wind until they choose).
static func chosen() -> String:
	var g := _state()
	var id := String(g.settings.get("duel_skill", DEFAULT)) if g != null else DEFAULT
	return id if known().has(id) else DEFAULT


static func choose(id: String) -> void:
	var g := _state()
	if SKILLS.has(id) and g != null:
		g.settings["duel_skill"] = id
		g.save_settings()


## Any skill but `not_this`, picked at random (a Lab rival's).
static func random(rng: RandomNumberGenerator, not_this := "") -> String:
	var ids: Array = SKILLS.keys().filter(func(k): return k != not_this)
	return String(ids[rng.randi_range(0, ids.size() - 1)])
