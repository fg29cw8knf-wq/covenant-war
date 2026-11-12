extends SceneTree
## Bram's duel as it's played (12 November: WhiteSkyDuel.PLAY_TURNS), run
## headless with nobody at the gates, and checked: every step made as
## written and none skipped; the Scrivener broken by the hunter's first
## blow; the Unspent Hour called and the Blazehound broken on Bram's first
## turn; one of his Totems lost to the pack's answer; the Last Page called
## down on his second turn and its blow landing; Bram never beaten, and the
## duel not over before the Last Page.
## Run: godot --headless --path . --script res://tests/white_sky_play_probe.gd [-- log]
## Ends "WHITE SKY PLAY: ok" or the problems.


func _initialize() -> void:
	var show := "log" in OS.get_cmdline_user_args()
	var D := WhiteSkyDuel
	var game := DuelGame.new()
	game.stacked = [true, true]
	game.puzzle = D.play_board()
	game.story_rules = D.story_rules()
	var cs: Array = D.play_controllers()
	game.setup([D.PLAY_BRAM_DECK.duplicate(), D.PLAY_HUNTER_DECK.duplicate()], ["Bram", "The hunter"], cs,
		[D.bram_profile(), D.hunter_profile()], D.SEED)
	game.life_floor = D.LIFE_FLOOR.duplicate()
	# as DuelScreen sets a filmed duel (spec.film)
	game.arena = ""
	game.skills = ["", ""]
	game.comeback = false
	game.arena_events = false
	game.ai_oaths = false
	game.place_god = ""
	var st := {"called": -1, "struck": false, "lines": [], "ko": []}
	var summon := D.summon_name()
	game.logged.connect(func(t: String, who: int) -> void:
		(st.lines as Array).append([game.turn, who, t])
		if show:
			print("  t%d %s%s" % [game.turn, "    " if who == 1 else "", t])
		if who == 0 and "calls down" in t and summon in t:
			st.called = game.turn
		if int(st.called) >= 0 and who == 1 and " takes " in t:
			st.struck = true
		if game.turn > 6:
			game.over = true)
	var beats: Array = []
	game.beat.connect(func(m: String, a: Array) -> void:
		if m == "fx_ko" and a[0] is DuelTotem:
			beats.append([game.turn, (a[0] as DuelTotem).owner, (a[0] as DuelTotem).id()])
		if m == "fx_totem_hit" and int(st.called) >= 0 and a[0] is DuelTotem and (a[0] as DuelTotem).owner == 1:
			st.struck = true
			game.over = true)
	await game.run()
	var problems: Array = []
	for i in 2:
		for sk in (cs[i] as WhiteSkyDuel.Staged).skipped:
			problems.append("%s's step skipped: %s" % ["Bram" if i == 0 else "the hunter", sk])
	var gates: Array = (cs[0] as WhiteSkyDuel.Staged).made
	if gates != D.PLAY_GATES:
		problems.append("the player's moves were %s, not %s" % [gates, D.PLAY_GATES])
	var want := [[1, 0, "scrivener"], [2, 1, "blazehound"], [3, 0, "loomwarden"]]
	for wk in want:
		if not beats.has(wk):
			problems.append("%s's %s wasn't broken on turn %d" % ["Bram" if wk[1] == 0 else "the hunter", wk[2], wk[0]])
	for b in beats:
		if not want.has(b):
			problems.append("%s's %s was broken on turn %d (not written)" % ["Bram" if b[1] == 0 else "the hunter", b[2], b[0]])
	if int(st.called) != 4:
		problems.append("the Last Page was called down on turn %d, not 4" % int(st.called))
	if not bool(st.struck):
		problems.append("the Last Page's blow never landed")
	if game.players[0].life <= 0 or game.winner == 1:
		problems.append("Bram was beaten")
	print("  Totems broken (turn, side, which): ", beats)
	print("  Bram's Life %d, the hunter's %d; his hand at the end: %s" % [game.players[0].life, game.players[1].life,
		game.players[0].hand.map(func(c): return c.id)])
	print("WHITE SKY PLAY: ", "ok" if problems.is_empty() else "%d problems: %s" % [problems.size(), "; ".join(problems)])
	quit(0 if problems.is_empty() else 1)
