class_name DuelPuzzles
extends RefCounted
## Bram's Riddles (27 October, Gary: "add all the go battles": win-in-one-
## turn puzzles, each teaching a trick). Each is a set board (DuelGame's
## puzzle): your Totems, your hand and your Essence as Bram lays them out,
## theirs too, and one turn to empty their Life. A wrong try and Bram sets
## the board again (the Trial of Light's reset); from the second try his
## hint shows. Played from the title screen (PuzzleMenu); a solved riddle
## is ticked (Game.settings "riddles_solved").
##
## Each: id, title, riddle (said as it starts), hint, lesson (said when
## it's solved), life [yours, theirs], essence (yours, every turn), board
## [yours, theirs] (three slots, an id or null; theirs' slot 0 stands across
## from your slot 0), hand (yours), wards (theirs, face down), deck (yours,
## for a card that draws). tests/puzzles_test.gd plays each one's answer,
## and a wrong try, through the rules engine.

const PUZZLES := [
	{
		"id": "open_lane", "title": "An Open Lane",
		"riddle": "Fifty Life to take, and their Cinderpup stands across from your Blazehound. A Totem can strike Life only when nothing stands across from it.",
		"hint": "Shift your Blazehound to the empty slot for 1 Essence. It can still attack after.",
		"lesson": "A Totem hits Life only through an empty lane. Shifting costs 1 Essence, and the Totem can still attack after it moves.",
		"life": [100, 50], "essence": 3,
		"board": [["blazehound", null, null], ["cinderpup", "cinderpup", null]],
		"hand": [],
	},
	{
		"id": "spill_over", "title": "Spill Over",
		"riddle": "Three Totems wall off their Life, and you have one attack. Twenty Life to take.",
		"hint": "Hit a Totem harder than it can take, and the rest spills onto its owner's Life.",
		"lesson": "Damage past what a Totem can take spills onto its owner's Life. A big hit on a small Totem reaches Life even with every lane blocked.",
		"life": [100, 20], "essence": 3,
		"board": [["boulderox", null, null], ["cinderpup", "cinderpup", "cinderpup"]],
		"hand": [],
	},
	{
		"id": "guardian_first", "title": "The Guardian First",
		"riddle": "Twenty Life, and a Brassback standing guard. While a Guardian stands, nothing of yours can touch their Life.",
		"hint": "Bring the Brassback down with two of yours, cheaply. Then the third has a clear lane.",
		"lesson": "A Guardian keeps every attack off its owner's Life until it falls. Knock it out first, then go for Life.",
		"life": [100, 20], "essence": 2,
		"board": [["pebblit", "blazehound", "dawnling"], [null, "brassback", null]],
		"hand": [],
	},
	{
		"id": "where_its_weak", "title": "Where It's Weak",
		"riddle": "Thirty Life behind three Totems, and two of yours to get through. Some blows land harder than others.",
		"hint": "Fire burns Verdant, and Tide puts Fire out: a blow on a Totem weak to it lands half as hard again.",
		"lesson": "Every element is weak to others. Hit a Totem with what it's weak to and the blow is half as big again. The chart is under How to Duel.",
		"life": [100, 30], "essence": 3,
		"board": [["blazehound", "brookfin", null], ["cinderpup", "mossling", "pebblit"]],
		"hand": [],
	},
	{
		"id": "bait_the_ward", "title": "Bait the Ward",
		"riddle": "Thirty Life, nothing on their side, and one Ward face down. A Ward springs at the first attack that sets it off.",
		"hint": "Let it spring on the attack you can spare.",
		"lesson": "A face-down Ward springs at the first thing that sets it off. Spend it on a small attack, and send the big one after.",
		"life": [100, 30], "essence": 0,
		"board": [["pebblit", "blazehound", null], [null, null, null]],
		"hand": [], "wards": ["mirror_veil"],
	},
	{
		"id": "every_last_drop", "title": "Every Last Drop",
		"riddle": "Seventy Life, one Pebblit, one Essence. Everything you need is in your hand.",
		"hint": "The Flask costs nothing and pays for the rest. Power your Pebblit up before it strikes.",
		"lesson": "Order matters. Make your Essence first, power your Totem up, and only then attack.",
		"life": [100, 70], "essence": 1,
		"board": [["pebblit", null, null], [null, null, null]],
		"hand": ["essence_flask", "forge_edge", "war_paint"],
	},
	{
		"id": "last_light", "title": "Last Light",
		"riddle": "Your Life is low and theirs is fifty. When your Life first falls to a quarter, your god sends you a card: Rallying Light.",
		"hint": "Rallying Light costs nothing and Empowers every Totem you have. Play it before you attack.",
		"lesson": "Rallying Light comes once a duel, when your Life first falls to a quarter. It heals and Empowers all your Totems: play it, then attack with everything.",
		"life": [30, 50], "essence": 0,
		"board": [["pebblit", "dawnling", null], [null, null, null]],
		"hand": ["rallying_light"], "deck": ["healing_draught"],
	},
	# 28 October (Gary: "add synergy... lets add it all", and teach it
	# throughout): one riddle for each way cards work together. "synergy"
	# names the ways that are on (the others are off, so the numbers are
	# exact); "place" is whose ground the board is on.
	{
		"id": "the_pack", "title": "The Pack",
		"riddle": "Sixty Life to take, an open lane, and a Blazehound. Inferno Rush hits for fifty. Hounds hunt better together.",
		"hint": "Call a Hound beside it first. With another Hound on your side, a Hound deals 10 more.",
		"lesson": "Totems of a family look out for their own. A Hound deals 10 more for every other Hound on your side, whatever its element.",
		"life": [100, 60], "essence": 3, "synergy": ["kin"],
		"board": [["blazehound", null, null], [null, null, null]],
		"hand": ["river_hound", "shieldhound"],
	},
	{
		"id": "side_by_side", "title": "Side by Side",
		"riddle": "Sixty Life, two Fire Totems a slot apart, and one Essence. Neighbours matter.",
		"hint": "Shift one of them into the middle. Two of an element side by side each deal 10 more, and the Emberwisp Rallies whoever stands beside it.",
		"lesson": "Two Totems of one element in neighbouring slots each deal 10 more. Rally, Shelter and Tend Totems help whoever stands beside them. Where they stand is worth an Essence.",
		"life": [100, 60], "essence": 1, "synergy": ["side"],
		"board": [["emberwisp", null, "hearth_salamander"], [null, null, null]],
		"hand": [],
	},
	{
		"id": "steel_finds_the_wound", "title": "Steel Finds the Wound",
		"riddle": "Ten Life, behind an Emberwisp with forty to it. One Jagged Shards, and your Brassback's Clank.",
		"hint": "Wound it first. Metal on a Bleeding Totem is a reaction: Rend, 20 more.",
		"lesson": "Set a condition with one card and set it off with the next. Metal on a Bleeding Totem Rends; Fire on Frozen Melts; Storm on Soaked Conducts. How to Duel has them all.",
		"life": [100, 10], "essence": 1, "synergy": ["react"],
		"board": [["brassback", null, null], ["emberwisp", null, null]],
		"hand": ["jagged_shards"],
	},
	{
		"id": "third_time", "title": "Third Time",
		"riddle": "A hundred Life, one Essence, a Blazehound, and three cards. Which order?",
		"hint": "The third card you play in a turn costs 1 less, and Forge Edge is a Combo card: played third, it gives 20 more. Then Inferno Rush.",
		"lesson": "Every card you play in a turn adds to your chain. The third costs 1 less, and a Combo card played third or later does more. Cheap ones first, the best one third.",
		"life": [100, 100], "essence": 1, "synergy": ["chain"],
		"board": [["blazehound", null, null], [null, null, null]],
		"hand": ["essence_flask", "war_paint", "forge_edge"],
	},
	{
		"id": "old_friends", "title": "Old Friends",
		"riddle": "Thirty Life behind three Emberwisps, your River Hound, a Brookfin in hand, and four Essence.",
		"hint": "River Hound and Brookfin are bonded: together they share Flood, a blow on every Totem across. Fire is weak to Tide, and what's left over spills.",
		"lesson": "Bonded Totems share a move, or something more, while both stand on your side. Call the partner and the bond is there that turn.",
		"life": [100, 30], "essence": 4,
		"board": [["river_hound", null, null], ["emberwisp", "emberwisp", "emberwisp"]],
		"hand": ["brookfin"],
	},
	{
		"id": "whose_ground", "title": "Whose Ground",
		"riddle": "Pyrrhane's ground. Ten Life behind an Emberwisp, one Essence, and a Firebrand that costs two.",
		"hint": "Firebrand is Pyrrhane's card, and this is Pyrrhane's ground: it's Graced, and costs 1 less. Clear the lane with it.",
		"lesson": "Every card answers to a god. On its god's ground, or when its god is Pleased with you, it's Graced: a Totem hits 10 harder, any other card costs 1 less. On its god's rival's, Shunned.",
		"life": [100, 10], "essence": 1, "synergy": ["grace"], "place": "pyrrhane",
		"board": [["brassback", null, null], ["emberwisp", null, null]],
		"hand": ["firebrand"],
	},
]

const RIVAL := "Bram's Riddle"


static func count() -> int:
	return PUZZLES.size()


static func get_puzzle(i: int) -> Dictionary:
	return PUZZLES[clampi(i, 0, PUZZLES.size() - 1)]


## The duel spec for riddle `i`, as DuelScreen takes it.
static func spec(i: int, player_name := "You") -> Dictionary:
	var pz := get_puzzle(i)
	var me := Lore.new_profile(player_name, "", 3)
	# Bram's side: no god, and no Guard (every number on the board is the number that lands)
	var them := Lore.new_profile(RIVAL, "", 0)
	them.attributes["resolve"] = 0
	var board: Array = pz.board
	return {
		"decks": [["essence_flask"], ["essence_flask"]],
		"names": [player_name, RIVAL],
		"profiles": [me, them],
		"plates": ["", "Ashford"],
		"ai": [false, true],
		"difficulty": 1.0,
		"arena": "ashford",
		"puzzle": {
			"first": 0,
			"turns": 1,
			"life": pz.life,
			"essence_max": [int(pz.essence), 0],
			"essence_fixed": [true, false],
			"board": board,
			"hand": [pz.get("hand", []), []],
			"deck": [pz.get("deck", []), []],
			"wards": [[], pz.get("wards", [])],
			"no_gift": true,
			"attack_first": true,   # (a riddle's one turn is the duel's first)
			"synergy": pz.get("synergy", []),   # (28 October: the ways a riddle is about)
			"place_god": String(pz.get("place", "-")),
			"log": "Bram sets the board.",
			"out_text": "Not this time. Bram sets the board again.",
		},
		# the other side only watches; one turn to win (DuelGame "mirror_trial")
		"story_rules": {"mirror_trial": 1},
		"rule": [String(pz.title), String(pz.riddle)],
		"rule_word": "Win this turn.  ",
		"trial": true,
		"bark_who": "Bram",
		"reset_lines": ["Not quite. Again.", String(pz.hint)],
		"hint_after": 2,
		"hint_stays": true,
		"practice": true,
		"practice_line": "Solved!  " + String(pz.lesson),
		"back_label": "Back to the riddles",
		"no_ads": true,
		"no_barks": true,
		# the aiming preview shows the damage, not whether it wins: that's the riddle
		"preview_plain": true,
		"riddle": String(pz.id),
	}


static func _state() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null("Game") if tree != null else null


static func solved() -> Array:
	var g := _state()
	var s = g.settings.get("riddles_solved", []) if g != null else []
	return s if s is Array else []


static func mark_solved(id: String) -> void:
	var g := _state()
	if g == null:
		return
	var s: Array = solved().duplicate()
	if not s.has(id):
		s.append(id)
	g.settings["riddles_solved"] = s
	g.save_settings()
