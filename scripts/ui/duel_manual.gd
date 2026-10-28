class_name DuelManual
extends RefCounted
## The pause menu's How to Duel page as a manual (25 October, Gary: it
## "just shows the chats; it needs to be a proper, easy-to-read manual of
## everything you have been shown or learned"). Each chapter is written in
## plain words and appears once the game has taught what it covers: the
## basics once the player has a deck in their hands (the Lantern Duel shows
## them whether or not Bram talks it through), and the rest as each thing is
## met for the first time (Game.learned, the ids DuelTutor keeps). Nothing
## here is a line of dialogue; Bram's words go into the lessons as he says
## them, and this is what they add up to.
##
##   for s in DuelManual.sections(): s.title, s.body (paragraphs and
##   {"bullets": [...]} items), s.chart (the element chart goes here)


## True once the player has a deck: the basics can be read from then on.
static func basics() -> bool:
	return bool(Game.flag("first_deck")) or bool(Game.flag("ash_won_lantern")) or Game.learned("aim")


static func known(id: String) -> bool:
	return Game.learned(id) or Game.learned("seen:" + id)   # (seen in a duel without a teacher, 28 October)


static func any_known(ids: Array) -> bool:
	for id in ids:
		if Game.learned(String(id)):
			return true
	return false


## The chapters that can be read now, in the order they're taught.
static func sections() -> Array:
	var out: Array = []
	if not basics():
		return out
	var cap := DuelRules.essence_cap
	out.append({"title": "The aim", "body": [
		"A duel is fought between two card-holders inside a Circle. Each of you starts with a store of Life. Bring your rival's Life down to nothing and you've won.",
		"Your Totems do the fighting. You do the thinking: what to call, what to spend, when to strike and where.",
	]})
	out.append({"title": "Your cards", "body": [
		"Every card is a Sigil: a drop of the gods' magic, set hard. Each has a kind, written on it.",
		{"bullets": [
			"A TOTEM is a creature. You call it into the Circle, and it fights for you. It has Life of its own, an element, and one or two moves.",
			"A RITE is magic you cast once. It does its work the moment it's cast, then it's gone to the discard.",
		]},
		"Tap any card, yours or your rival's, to see it up close: what it costs, what it is and what its moves do.",
	]})
	out.append({"title": "Your hand and your deck", "body": [
		{"bullets": [
			"You start with %d cards in hand and draw one more at the start of every turn. Whoever goes second draws one extra to begin with." % DuelRules.start_hand,
			"You can hold %d cards at most." % DuelRules.hand_limit,
			"If your deck runs dry, drawing from it costs you %d Life." % DuelRules.fatigue,
		]},
	]})
	out.append({"title": "Essence", "body": [
		"Essence is what you spend. Calling a Totem costs its Essence; so does casting a Rite.",
		{"bullets": [
			"At the start of your turn your Essence is filled up again, and your store grows by one, up to %d." % cap,
			"Whatever you haven't spent by the end of your turn is gone. Spend it.",
		]},
	]})
	out.append({"title": "The Circle", "body": [
		{"bullets": [
			"Each side has %d slots. A Totem is called into one of your empty slots, for its Essence cost." % DuelRules.SLOTS,
			"A Totem fights the Totem standing across from it. If the slot across from it is empty, it can strike at your rival's Life instead.",
			"Nobody attacks on the first turn of the duel, and a Totem that's just been called can't attack until your next turn: it needs a moment to find its feet.",
		]},
	]})
	if DuelRules.phases:
		out.append({"title": "A turn, step by step", "body": [
			"The little band under your rival's plate shows the steps of a turn, left to right, and lights the one you're in.",
			{"bullets": [
				"DAWN: anything that wakes at the start of a turn, wakes.",
				"DRAW: you draw a card.",
				"MAIN: your time. Call Totems, set Wards, cast Rites, in any order you like.",
				"THE CLASH: your Totems attack, one at a time, each once.",
				"MAIN II: a last chance for a Rite or a Shift, if you've Essence left.",
				"DUSK: the turn ends and anything that fades, fades. Then it's your rival's turn.",
			]},
			"When a button goes dark it isn't broken: it's just not the step of the turn for it. End Turn is there whenever you've nothing more to do.",
		]})
	else:
		# (27 October, Gary: no stages to the turn, as it was before)
		out.append({"title": "Your turn", "body": [
			{"bullets": [
				"Your turn starts with a card drawn and your Essence filled. Anything that wakes at the start of a turn, wakes.",
				"Then it's all yours, in any order you like: call Totems, set Wards, cast Rites, set a Totem's stance, and attack.",
				"Each of your Totems attacks once a turn. Tap END TURN when you've nothing more to do.",
			]},
		]})
	out.append({"title": "Attacking", "body": [
		{"bullets": [
			"Tap one of your Totems, pick one of its moves, then pick what to hit.",
			"Some moves are free; some cost Essence. A dearer move usually hits harder, or does something more.",
			"Each Totem attacks once a turn.",
		]},
	]})
	out.append({"title": "Knockouts", "body": [
		"When a Totem's Life reaches nothing it's knocked out: back into its card and off to the discard, and its slot is empty again. Nobody bleeds inside a Circle unless the stakes say so.",
	]})
	out.append({"title": "Stakes", "body": [
		"Every duel has its stakes, named as it starts. A friendly game is played for nothing but pride. Others are played for cards, for coin, or for a good deal worse. Know what you're playing for before you sit down.",
	]})
	if known("weakness"):
		out.append({"title": "The elements", "chart": true, "body": [
			"Every Totem has an element, and every element hurts one other and fears one. A hit on a Totem's weakness does half as much again. The sign on each card says what it fears. Twelve elements in all: the chart shows which beats which.",
		]})
	if any_known(["fate", "fate_bands"]):
		out.append({"title": "Fate", "body": [
			"Some moves roll a die with twenty faces. High, and they hit hard; low, and nothing happens.",
			"The bands under such a move say what the die has to make: the low band does the small thing, the top band the big one. A move with a wide top band is a gamble. A narrow one is steady.",
		]})
	# (Rites are on the table in the Lantern Duel: Bulwark)
	out.append({"title": "Rites", "body": [
		"A Rite is cast once, from your hand, and answers at once. The Essence it costs is Essence you're not calling a Totem with, so cast it when the board asks for it, not because it's in your hand.",
		"Bulwark, for one, throws a wall of stone round one of your Totems: the next hit it takes, the stone takes first, up to fifty of it.",
	]})
	if any_known(["ward_set", "ward_mine", "ward_spring"]):
		out.append({"title": "Wards", "body": [
			"A Ward is set face down beside the Circle, so your rival can't read it. It springs by itself when the right thing happens: a Totem called, a Rite cast, a hit coming in.",
			{"bullets": [
				"Each side can have %d Wards down at once." % DuelRules.ward_slots,
				"Set them early, while they're cheap.",
				"Once a Ward has sprung it's spent. Think what your rival's Ward is waiting for, and don't give it that.",
			]},
		]})
	if known("stance"):
		out.append({"title": "Stances", "body": [
			"Each of your Totems can take a stance for the turn:",
			{"bullets": [
				"STRIKE: it fights as normal.",
				"GUARD: it makes no attack, and turns half of every blow aside.",
				"REST: it makes no attack, mends %d Life, and pays you an Essence next turn." % DuelRules.rest_heal,
			]},
		]})
	if any_known(["answer", "answered"]):
		out.append({"title": "Answers", "body": [
			"When your rival makes a move, it hasn't landed yet. That's your moment: you have %d seconds to play a card from your hand against it, or let it be. They can do the same to you. A chain of answers runs to %d at most." % [int(DuelRules.respond_secs), DuelRules.chain_max],
		]})
	if known("shift"):
		out.append({"title": "Shift", "body": [
			"Two of your Totems change places, for %d Essence. It's the only way to move a Totem once it's called, so a slot you've put the wrong Totem in isn't a slot you're stuck with." % DuelRules.shift_cost,
		]})
	if known("tier"):
		out.append({"title": "Tiers", "body": [
			"Every card has a tier, Spark to Divine, seven in all. Each tier up costs more to call and hits harder, and a deck carries fewer of them: four Sparks of a kind, one Relic. The high ones aren't better. They're later.",
		]})
	if known("tribute"):
		out.append({"title": "Tributes", "body": [
			"The biggest Totems don't come for Essence alone. One of your Totems has to step down for a Legend, into the discard, and its light goes into the new one; the greatest ask for two. Choose who you can spare.",
		]})
	if any_known(["veiled", "revealed"]):
		out.append({"title": "Veiled calls", "body": [
			"A Totem can be called face down. Your rival sees a card back and nothing else until it fights, it's struck, or your next turn comes. Some have a trick for the moment they're turned up.",
		]})
	if known("relic"):
		out.append({"title": "Relics", "body": [
			"A Relic is hung on one of your Totems and stays as long as the Totem does. Give it to one that'll last: when the Totem falls, the Relic goes down with it.",
		]})
	if known("summon"):
		out.append({"title": "Summons", "body": [
			"A Summon isn't a Totem: it's a piece of something far bigger. It costs a great deal of Essence, does one great thing, and goes back where it came from. Save it for when it counts.",
		]})
	if known("ascend"):
		out.append({"title": "Ascension", "body": [
			"An Ascension is a Totem grown up. Play it on the Totem it grows from and it steps into the same slot, bigger, with everything it had. It costs Essence, so think about when.",
		]})
	if known("way"):
		out.append({"title": "Ways of playing", "body": [
			"Some cards belong to a way of playing, and only work while a Totem of that way stands on your field. Every deck leans to a way; play to it and its cards play for you.",
		]})
	if known("bond"):
		var pairs := []
		for b in DuelCards.BONDS:
			if DuelCards.CARDS.has(b.a) and DuelCards.CARDS.has(b.b):
				pairs.append("%s and %s: %s." % [DuelCards.CARDS[b.a].name, DuelCards.CARDS[b.b].name, b.name])
		out.append({"title": "Bonds", "body": [
			"Some Totems know each other. While both stand on your side, they share a move, or something more: the BOND tag shows on their plaques. Keep the pair together.",
			{"bullets": pairs},
		]})
	# 28 October (Gary: "add synergy to the card game... lets add it all")
	if any_known(["family", "side", "beside"]):
		out.append({"title": "Working together", "body": [
			"A deck isn't a pile of strong cards: it's cards that make each other stronger. The Totems on a side help each other in three ways: by family, by standing side by side, and by bond. The tags on a Totem's plaque say what it has from the others right now.",
		]})
	if known("family"):
		var fams := []
		for fid in DuelSynergy.FAMILIES:
			var fd: Dictionary = DuelSynergy.FAMILIES[fid]
			var names := DuelSynergy.members(fid).map(func(m): return String(DuelCards.CARDS[m].name))
			fams.append("%s (%s): with another of its family on your side, %s. %s." % [String(fd.plural).to_upper(), fd.trait, String(fd.text), ", ".join(names)])
		out.append({"title": "Families", "body": [
			"Every creature belongs to a kind, whatever its element: a Hound is a Hound, made of fire or of river water. With another of its family on your side, each has its family's Kinship. The family is printed on the card, after BASIC TOTEM.",
			{"bullets": fams},
			"Pack Howl and Call of Kin are Rites for families: one makes your Hounds hit harder for a turn, the other finds a Totem of a family you already have out.",
		]})
	if any_known(["side", "beside"]):
		out.append({"title": "Side by side", "body": [
			"Your three slots are a line, and neighbours matter. Two Totems of the same element in slots next to each other each deal %d more. The middle slot has two neighbours; the ends have one." % DuelSynergy.SIDE_BONUS,
			{"bullets": [
				"SHELTER: the Totems beside it take %d less from every attack (Shellguard, Gilded Sentinel)." % DuelSynergy.SHELTER,
				"RALLY: the Totems beside it deal %d more (Emberwisp, Dawnling, Shieldhound)." % DuelSynergy.RALLY,
				"TEND: at your Dawn, the Totems beside it heal %d (Lantern Moth, Bloomsprite)." % DuelSynergy.TEND,
			]},
			"Shifting a Totem costs Essence, but putting the right two together can be worth it.",
		]})
	if known("reaction"):
		var rx := []
		for r in DuelSynergy.REACTIONS:
			rx.append("%s: %s" % [String(r.name).to_upper(), r.text])
		out.append({"title": "Reactions", "body": [
			"A condition isn't only harm. Hit a Totem that carries one with the right element and the two react: more damage, and something new left behind. Set one up with one Totem, and set it off with the next.",
			{"bullets": rx},
			"While you aim, the chip over a target names the reaction your blow would set off.",
		]})
	if any_known(["chain", "combo"]):
		out.append({"title": "Chains and Combos", "body": [
			"Every card you play in a turn adds to your chain: a Totem called, a Rite cast, a Ward set, an Ascension, a Summon, a Relic. The turn line at the top counts it.",
			{"bullets": [
				"The third card you play in a turn costs %d less Essence. Play the cheap ones first and the dear one third." % DuelSynergy.CHAIN_DISCOUNT,
				"A COMBO card does more when it's the third card of the turn or later: a Combo Totem comes in Empowered, a Combo Rite deals or gives %d more." % DuelSynergy.COMBO_BONUS,
			]},
			"Answers played on your rival's turn don't count: a chain is your own turn's work.",
		]})
	if any_known(["graced", "shunned", "ground"]):
		var grounds := []
		for a in DuelSynergy.ARENA_GOD:
			grounds.append("%s: %s's ground." % [String(a).capitalize(), DuelSynergy.god_name(DuelSynergy.ARENA_GOD[a])])
		var rivals := []
		var seen := {}
		for g in DuelSynergy.RIVALS:
			if seen.has(g):
				continue
			seen[g] = true
			seen[DuelSynergy.RIVALS[g]] = true
			rivals.append("%s and %s." % [DuelSynergy.god_name(g), DuelSynergy.god_name(DuelSynergy.RIVALS[g])])
		out.append({"title": "The gods' grace", "body": [
			"Every card answers to a god: its name is printed at the foot of the card. Most follow their element's god; a few belong to gods you won't find in a temple, like Ellowen the Lantern Keeper, whose festival Ashford keeps, and Orrun the Stone Warden.",
			{"bullets": [
				"GRACED: on its god's ground, or when its god is Pleased with you. A Graced Totem hits %d harder; any other Graced card costs %d less." % [DuelSynergy.GRACE_DAMAGE, DuelSynergy.GRACE_COST],
				"SHUNNED: on the ground of its god's rival, or when its god is Displeased with you. A Shunned Totem hits %d less; any other Shunned card costs %d more." % [DuelSynergy.GRACE_DAMAGE, DuelSynergy.GRACE_COST],
				"Both at once cancel out. The ribbon on a card in your hand, and the tag on a Totem's plaque, show which it is.",
			]},
			"Whose ground a duel is on is written in the corner under the turn. A duel under a god's Law is on that god's ground.",
			{"bullets": grounds},
			"How each god feels about you comes from what you've done: the menu's Standing page shows it. Swear to a god and it's Pleased with you from then on. The rivals:",
			{"bullets": rivals},
		]})
	# the 27 October additions (Gary: "add all the go battles")
	if bool(Game.flag("told_skills")) or known("skills"):
		out.append({"title": "Duel skills", "body": [
			"Every duellist has one skill, shown on a ribbon across the top of their plate. It works once a duel, by itself: there's nothing to press. Tap the ribbon to read it; it greys out once it's used.",
			"You start knowing a few, and learn others by beating people at cards. Choose yours in the menu, under Deck.",
		]})
	if known("comeback"):
		out.append({"title": "Rallying Light", "body": [
			"When your Life first falls to a quarter, your god sends you one card, once a duel: Rallying Light. It costs nothing. It heals every Totem you have, Empowers them, and draws you a card. Play it before you attack.",
			"Your rival's god does the same for them.",
		]})
	if known("arena_event"):
		out.append({"title": "The Circle joins in", "body": [
			"Every few turns the Circle itself does something, to both sides alike: Ashford's lanterns flare, the tide surges, the forge roars. The corner under the turn counts it down.",
		]})
	out.append({"title": "Aiming", "body": [
		"While you pick what a move will hit, each target shows what it would take: the damage (a range, for a move that rolls Fate), KO if it would fall, and WINS if the blow would end the duel. A face-down Ward or an answer can still change it.",
		"The Speed button at the top of the duel plays it faster: 1x, 2x or 4x. Options has it too.",
	]})
	if known("guardian"):
		out.append({"title": "Guardians", "body": [
			"A Guardian stands in front of everything: every blow goes through it first, and nothing on its side can be hit at the Life while it stands. Break it, or go nowhere.",
		]})
	if any_known(["arena_rule", "terrain"]):
		out.append({"title": "The ground", "body": [
			"Every Circle has a rule of its own, all duel long, for both sides. It's written in the corner under the turn. Ashford's green has none.",
			"A Terrain Rite turns the Circle into another place for %d turns, and that place's rule comes with it. Read the corner: it says what the ground does now." % DuelRules.terrain_turns,
		]})
	if known("continuous"):
		out.append({"title": "Continuous Rites", "body": [
			"A Continuous Rite doesn't go to the discard. It stands beside the Wards and keeps working, %d a side, until it's unbound or a third pushes the oldest out. Tap it to read it." % DuelRules.continuous_slots,
		]})
	if any_known(["favour", "favour_rival"]):
		out.append({"title": "Favour", "body": [
			"Favour fills as you play your god's element and follow its way: the ring round your seal. Full, it opens your Gift again, or brings your god's Demigod down for nothing. Watch your rival's ring too: full, it means a second Gift coming, or worse.",
		]})
	if known("gift"):
		out.append({"title": "Gifts", "body": [
			"A Gift is a god's favour, bought with kneeling: one great thing, once. Nobody gets many.",
		]})
	if known("oath"):
		out.append({"title": "Oaths", "body": [
			"An Oath is sworn in the Circle, and words said there bind you. Keep it and the win's worth more; break it and it costs you %d Life." % DuelRules.oath_life_cost,
		]})
	if any_known(["echo", "rekindle", "loyal"]):
		var b := []
		if known("echo"):
			b.append("An ECHO: a fallen Totem that answers once from the discard, when another of yours falls. Read what lies in your discard; tap it on your plate.")
		if known("rekindle"):
			b.append("One that REKINDLES climbs out of the discard once a duel, at the start of your turn, with half its strength. Put it down twice and it stays down.")
		if known("loyal"):
			b.append("A LOYAL Totem comes out of your hand by itself, free, when one of its own falls, and takes the empty place.")
		out.append({"title": "The discard", "body": [{"bullets": b}]})
	if known("search"):
		out.append({"title": "Searches", "body": [
			"A card that searches your deck for another means playing less by luck. Keep a few in, and the right card comes when you need it.",
		]})
	if known("steal"):
		out.append({"title": "Your hand, stolen from", "body": [
			"Some rivals can take a card from your hand. Don't sit on what you can play now.",
		]})
	# the pack, once Bram has walked the player round it (PackTour)
	var pack_lines: Array = Game.lessons().filter(func(l): return String(l.get("group", "")) == "Your pack")
	if not pack_lines.is_empty():
		var b := [
			"Your pack holds everything you carry: open it from the corner of the screen, or from the menu.",
			"DECK: the cards you duel with, shuffled before every duel. A beginner's deck is twelve cards; a proper one is thirty, built by you from what you find, and changed whenever you like.",
			"Tap any card to read it: what it costs, its element, what every move does. Read before you play.",
			"CODEX: every card you own, and every card anybody has played against you.",
		]
		var deep := false
		for l in pack_lines:
			if "Resonance" in String(l.get("say", "")):
				deep = true
		if deep:
			b.append("The two bars under a card: RESONANCE fills every time you duel with the card, towards a second copy. ATTUNEMENT fills towards the card it grows into, its Ascension.")
			b.append("A spare copy isn't dead weight: re-absorb it in the Codex and it feeds the Attunement of its own kind, or pour in from the pool you win in duels, at half the worth.")
			b.append("Every copy you re-absorb tempers the card for good: more Life the first time, a kinder roll the second, a new move the third.")
		out.append({"title": "Your pack", "body": [{"bullets": b}]})
	# conditions and boons the player has met, each in a line
	var met: Dictionary = Game.conditions_met()
	if not met.is_empty():
		var lines := []
		for id in DuelConditions.DEFS.keys():
			if met.has(id):
				lines.append("%s: %s %s" % [DuelConditions.display_name(String(id)).to_upper(), DuelConditions.describe(String(id)), _lasts(String(id))])
		if not lines.is_empty():
			out.append({"title": "Conditions and boons", "body": [
				"A condition is something done to a Totem that stays on it for a while; a boon is the same, but good. The ones you've met so far:",
				{"bullets": lines},
			]})
	return out


static func _lasts(id: String) -> String:
	var turns := DuelConditions.turns(id)
	if DuelConditions.breaks_free(id):
		return "Stays until it breaks free, or it's cured."
	if turns == 0:
		return "Stays until it's cured." if DuelConditions.is_condition(id) else "Stays until it's used up."
	if turns == 1:
		return "One turn."
	return "%s turns." % ["Two", "Three", "Four", "Five"][clampi(turns - 2, 0, 3)]
