class_name LedgerEntries
extends RefCounted
## Morrowen's Ledger (Master Script v3, Side Quests: "the quest log is written
## in Morrowen's voice, as the Keeper of the Dead's record of the Age: a
## sentence or two per quest, in the past tense, plus a People page with one
## line on everyone you've met ('Hale. Opened a gate he was told to keep shut,
## and paid for it.'). A player coming back after a week reads where they are
## without anyone in the game repeating the plot.")
##
## Everything here is worked out from the story's flags, so a save made before
## the Ledger existed reads right too. v3 gives the form and that one line;
## the rest is written to match it, and copied in docs/script/v3_side_quests.md.
##
## Conditions ("when", and the first item of each line): flag names; "!flag"
## (not set); "flag=a,b" (the flag holds one of these words; "!flag=a,b" not);
## "standing:who>=n"; " & " joins terms that must all hold, and " | " joins
## alternatives. "" always holds.
##
## An account shows once its "when" holds and is still open while "open"
## holds. Its words are its "parts" one after another, each the last of its
## [condition, text] lines that holds (an empty text says nothing).

## The story and its side stories, in the order they happen.
const ACCOUNTS := [
	# ---------------------------------------------------------------- Ashford
	# (Master Script v7, 24 October: the morning duel, the afternoon's jobs, the
	# evening; the dawn Herald, that day, Krell at dusk and the tunnel.)
	{"id": "p_last_night", "title": "The Last Night of the Age", "place": "Ashford", "kind": "story",
		"when": "arrived_ashford | ash_started", "open": "!ash_lantern_duel & !ash_marked",
		"parts": [[
			["", "Ashford hung its lanterns for the last night of the Age, and Corin wanted his Lantern Duel before anyone had eaten."],
			["ash_won_lantern", "Ashford hung its lanterns for the last night of the Age. You won the Lantern Duel with Bram's old Sparks, so the Great Lantern was yours to light at midnight."],
			["ash_evening", "Ashford hung its lanterns for the last night of the Age, and you won the Lantern Duel. When the sun went down, nobody in Ashford owed anybody anything for one evening. I let them have it."],
		]]},
	{"id": "a_note", "title": "The Note", "place": "Ashford", "kind": "story", "when": "tam_letter_seen | tam_told",
		"open": "!pro_part=burning,cellar,reckoning,tunnel & !pro_tunnel_done & !arrived_thornwood",
		"parts": [[
			["", "Tam Hayes couldn't read, so you read him Ironvault's letter: seventy crowns for seed-barley, grown to four hundred in three winters, due at midnight. You promised not to tell Nell until the festival was over."],
			["pro_part=burning,cellar,reckoning,tunnel | pro_tunnel_done | arrived_thornwood", "Tam Hayes couldn't read, so you read him Ironvault's letter. The next evening he stood between Krell and the inn and challenged the debt, and Krell set the stakes. The note was settled with him. He came to me."],
		]]},
	{"id": "a_nell", "title": "The Night Bram Came", "place": "Ashford", "kind": "side", "when": "ash_nell", "open": "!ash_nell",
		"parts": [[
			["", "Old Nell remembered the night Bram walked out of the Shardlands with you tucked inside his coat, the sky burning white. He paid for the inn in gold that smelled of ash. She has never asked him where he found you."],
		]]},
	{"id": "a_tilly", "title": "Tilly's Moth", "place": "Ashford", "kind": "side", "when": "ash_tilly", "open": "!tilly_thanks",
		"parts": [[
			["", "Tilly's Lantern Moth wouldn't wake for anyone in Ashford, not even Tam. It woke for you, and flew round her head."],
			["tilly_thanks", "Tilly's Lantern Moth wouldn't wake for anyone in Ashford. It woke for you, so that evening she gave it to you, before it could go grey for good. She means to visit it."],
		]]},
	{"id": "a_corin", "title": "Corin's Letter", "place": "Ashford", "kind": "side", "when": "corin_letter | corin_truth", "open": "!corin_pond",
		"parts": [[
			["", "Corin had a clerkship from the Ironvault Notary Guild, and he'd put your name down too."],
			["corin_pond", "Corin had a clerkship from the Ironvault Notary Guild. That evening on the mill-race wall he gave you the best button off his new coat."],
			["corin_truth", "Corin had a clerkship from the Ironvault Notary Guild. On the mill-race wall he told you why: two years clerking, and his mam's note would be written off. She thought he wanted to go. He gave you a button."],
		]]},
	{"id": "p_sigilfall", "title": "The Sigilfall", "place": "Ashford", "kind": "story", "when": "ash_marked", "open": "!ash_marked",
		"parts": [[
			["", "At midnight the sky tore open. You pulled Corin out from under a cart, and then one streak of white came down to you and no one else, and left a blank white card in your hand. The mark on your collarbone burned white."],
		]]},
	{"id": "p_herald", "title": "The Pale Herald", "place": "Ashford", "kind": "story",
		"when": "pro_part=taproom,burning,cellar,that_day,reckoning,tunnel | pro_tunnel_done | arrived_thornwood", "open": "!ash_marked",
		"parts": [[
			["", "At dawn my Herald counted the Champions of the seven Seats. Then the Covenant forged an eighth, for the holder of the Last Seal, and the Herald named you the Unsworn. Ashford stepped back from you, and Bram stepped forward."],
		]]},
	{"id": "p_burning", "title": "The Ashford Reckoning", "place": "Ashford", "kind": "story",
		"when": "pro_part=cellar,reckoning,tunnel | pro_tunnel_done | arrived_thornwood", "open": "!ash_marked",
		"parts": [[
			["", "Krell came at dusk, hours early, holding the notes for twenty-two roofs, and offered to burn them all for one white card. Nobody pointed. Tam challenged the debt to buy you time, and Bram took you out through his tunnel."],
			["pro_tunnel_done | arrived_thornwood", "Krell came at dusk, hours early, and offered to burn every note in Ashford for one white card. Nobody pointed. Tam challenged the debt and died for it, and Bram took you out through his tunnel. From the hill, Ashford was still standing. Corin stayed."],
		]]},
	# ------------------------------------------------------------ the road
	{"id": "p_road", "title": "The Thornwood Road", "place": "The Thornwood", "kind": "story",
		"when": "arrived_thornwood | pro_tunnel_done", "open": "!thornwood_done & !arrived_solhaven",
		"parts": [[
			["", "You left Ashford by Bram's tunnel, with Ironvault's grey coats on the green behind you, and walked the Thornwood all night."],
			["bram_deck", "In a shelter under the Thornwood, Bram set out four old card boxes and let you choose one. Then he taught you what the cellar never had."],
			["beat_hunter", "On the road east, Hunter Dask staked every card he owned against yours, for his mother's note. He lost them."],
			["beat_hunter & dask_kept_hound", "On the road east, Hunter Dask staked every card he owned against yours, for his mother's note, and lost them. You gave him back his hound."],
			["beat_hunter & dask_sent_home", "On the road east, Hunter Dask staked every card he owned against yours, for his mother's note, and lost them. You sent him home."],
			["thornwood_done | arrived_solhaven", "On the road east, Bram gave you one of his old decks, and Hunter Dask lost every card he owned to you. At dawn, Solhaven was white on the plain."],
		]]},
	# ------------------------------------------------------------ Solhaven
	{"id": "c1_sun_court", "title": "The Sun's Court", "place": "Solhaven", "kind": "story", "when": "arrived_solhaven", "open": "!beat_aldric",
		"parts": [[
			["", "You reached Solhaven three days after the fire, with the smoke still in your clothes. Warden Hale would not open his gate for a mark he took for paint."],
			["beat_hale", "Warden Hale tested your mark in the Circle and found it real. Up the hill, the Sun Court would have to enter it before your claim on the Throne was true."],
			["sun_court_done | c4_done", "The Hierarch asked for your card and my Herald forbade it; then Solmaris stopped the light to ask for it herself. Ser Aldric would test you, once the Temple's Trial of Light was passed."],
			["temple_leave | trial_light_passed | c5_done", "You passed the Trial of Light. Ser Aldric was waiting to duel you in front of his whole city."],
			["beat_aldric", "You beat Ser Aldric in front of his own city, and were found worthy to challenge any Seat in Veyl. The Hierarch left without entering your name, so Ser Aldric entered it himself and gave you the Court's writ, to be shown at the Throne. In Ironvault, a man wrote the day's date beside an old debt."],
		]]},
	{"id": "s_mercy", "title": "The Price of Mercy", "place": "Solhaven", "kind": "side",
		"when": "side_mercy | side_duel_on=mercy", "open": "side_duel_on=mercy",
		"parts": [[
			["", "The Temple wanted forty crowns or an oath to heal Ysa's son. Under the dyers' bridge, you swore a wager with the Sun Guard for the man who healed him for a word."],
			["side_mercy=swore", "Ysa asked the Unsworn whether she should kneel to the Sun for her son's healing, and you told her to. She swore, and put her green leaf away in her pocket."],
			["side_mercy=her_choice", "Ysa asked the Unsworn whether she should kneel to the Sun for her son's healing, and you said it was hers to decide. She decided, and put her green leaf away in her pocket."],
			["side_mercy=paid", "The Temple wanted forty crowns or an oath to heal Ysa's son, and you paid the crowns. She kept her green leaf, and said she wouldn't forget it."],
			["side_mercy=anselm_won", "Brother Anselm healed Ysa's son for one word, the name of Ilvane, a god of people on the road at night. You beat the Sun Guard's sergeant for him, and her lantern was a little brighter."],
			["side_mercy=anselm_fine", "Brother Anselm healed Ysa's son for one word, the name of Ilvane, a god of people on the road at night. You paid his fine, and her lantern was a little brighter."],
			["side_mercy=anselm_lost", "Brother Anselm healed Ysa's son for one word, the name of Ilvane, a god of people on the road at night. You lost the wager, and the Sun Guard took him for heresy."],
		]]},
	{"id": "s_fen", "title": "The Second Unsworn", "place": "Solhaven", "kind": "side",
		"when": "side_fen | side_duel_on=fen", "open": "side_fen=pending | side_duel_on=fen",
		"parts": [[
			["", "A Shardlander called Fen was selling the Unsworn's blessing at the fountain, a copper a time, and putting most of it in a soup pot. You told him to stop, and he wanted the Circle to decide."],
			["side_fen=truth", "Fen sold the Unsworn's blessing at the fountain, a copper a time, and put most of it in a soup pot. You told him to give it away instead: owe nobody."],
			["side_fen=carry_on", "Fen sold the Unsworn's blessing at the fountain, a copper a time, and put most of it in a soup pot. You let him carry on."],
			["side_fen=beaten", "Fen sold the Unsworn's blessing at the fountain until you beat him in the Circle and he washed his hand. He said there were always others."],
			["side_fen=won", "Fen sold the Unsworn's blessing at the fountain, and when you swore a wager to stop him, he won it. The whole fountain witnessed it."],
		]]},
	{"id": "s_pip", "title": "Pip's Errands", "place": "Solhaven", "kind": "side",
		"when": "side_pip | side_duel_on=pip", "open": "side_pip=seen,pending | side_duel_on=pip",
		"parts": [
			[
				["", "Pip ran sealed notes for Mr Pell, from the counting house up to a side door of the Sun Court, two crowns a run."],
				["side_pip_place=hale,aldric,tamsin", "Pip ran sealed notes for Mr Pell, two crowns a run, until you found him a place."],
			],
			[
				["", "He never opened them."],
				["side_pip=delivered", "He beat you for one, and it went up the hill unopened."],
				["side_pip=returned", "You read one, Ironvault lending against the Temple roofs for the Bread of Dawn, and gave it back."],
				["side_pip=kept", "You read one, Ironvault lending against the Temple roofs for the Bread of Dawn, and kept it."],
				["side_pip=aldric", "You read one, Ironvault lending against the Temple roofs for the Bread of Dawn, and took it to Ser Aldric."],
			],
		]},
	{"id": "s_scar", "title": "The Sundial's Scar", "place": "Solhaven", "kind": "side",
		"when": "met_maren | side_started_sundial_scar | side_scar", "open": "!side_scar",
		"parts": [[
			["", "Old Maren, thirty years a Temple scribe, said the Great Sundial's shadows were nine days wrong, and that somebody had slowed the sun. She told you to look at the oldest stone, under the steps, at dawn."],
			["side_scar=nothing", "At dawn you found the Great Sundial's lines cut twice, nine days apart, and Father Corvin found you. You told him you'd seen nothing, and Maren said you had sense."],
			["side_scar=told", "At dawn you found the Great Sundial's lines cut twice, nine days apart, and told Father Corvin so to his face. Maren gave you forty pages from her bread tin, and asked you to send for her when it's time."],
		]]},
	{"id": "s_hale", "title": "Hale's Orders", "place": "Solhaven", "kind": "side",
		"when": "side_hale | side_duel_on=hale | side_started_hales_orders | beat_aldric & let_refugees_in & !c6_done",
		"open": "!side_hale",
		"parts": [[
			["", "Warden Hale was stripped of his command for opening the gate to everyone, against the Hierarch's order. He was in the barracks yard, waiting to pay for it."],
			["side_hale=stood", "Hale took ten lashes at noon for opening the Goddess's gate to everyone. You stood at the front, where he could see you."],
			["side_hale=won", "Hale was to take ten lashes for opening the Goddess's gate to everyone. You duelled the Captain for his sentence and won back his rank, and he was furious, and then he thanked you."],
			["side_hale=lost", "Hale was to take ten lashes for opening the Goddess's gate to everyone. You duelled the Captain for his sentence and lost, and he took twenty."],
		]]},
]

## Everyone met, one line each. "look" is the cut-out whose face stands in
## until their portrait exists (assets/art/characters/<id>_portrait.png).
const PEOPLE := [
	# ---------------------------------------------------------------- Ashford
	{"id": "bram", "look": "bram", "place": "Ashford", "met": "met_bram | arrived_ashford | ash_started", "lines": [
		["", "Bram. Kept the Crooked Lantern twenty years, and you in it."],
		["ash_nell", "Bram. Came down the Shardlands road with you in his coat, and paid for an inn in gold. He has never said where the gold came from."],
		["pro_part=that_day,reckoning,tunnel | pro_tunnel_done | arrived_thornwood", "Bram. Not who you thought he was. Twenty years of lies, and every one of them kept you alive."],
	]},
	{"id": "tam", "look": "farmer", "place": "Ashford", "met": "met_tam | ash_tam", "lines": [
		["", "Tam Hayes. Ashford's miller. Couldn't read, and didn't want his wife to know."],
		["pro_part=cellar,tunnel | pro_tunnel_done | arrived_thornwood", "Tam Hayes. Miller of Ashford. Challenged the debt for you. A terrible card player, Krell said. She was wrong."],
	]},
	{"id": "nell", "look": "elder", "place": "Ashford", "met": "met_nell | ash_nell", "lines": [
		["", "Old Nell. Tam's wife, and the first through the Crooked Lantern's door."],
		["pro_part=cellar,tunnel | pro_tunnel_done | arrived_thornwood", "Old Nell. I heard her from the hill, under the bell."],
	]},
	{"id": "tilly", "look": "child", "place": "Ashford", "met": "met_tilly | ash_tilly_seen | ash_tilly | has_lantern_moth", "lines": [
		["", "Tilly. Seven. Her Lantern Moth wouldn't wake for her."],
		["ash_tilly", "Tilly. Seven. Her Lantern Moth woke for you, and flew round her head."],
		["has_lantern_moth", "Tilly. Seven. Gave you her Lantern Moth so it wouldn't go grey. She means to visit it."],
	]},
	{"id": "corin", "look": "corin", "place": "Ashford", "met": "met_corin | corin_met | ash_lantern_duel", "lines": [
		["", "Corin. Ashford's best duellist, by his own account."],
		["corin_letter", "Corin. Ashford's best duellist, by his own account, and an Ironvault clerk from the spring."],
		["corin_truth", "Corin. Taking Ironvault's clerkship to write off his mam's note. She thinks he wants to go."],
		["pro_tunnel_done | arrived_thornwood", "Corin. Found your rabbit-hole when you were ten, and never told. Stayed behind with his mam, Nell and Tilly, on a crushed knee."],
	]},
	{"id": "hob", "look": "hob", "place": "Ashford", "met": "met_hob | hob_gift", "lines": [
		["", "Hob. Grew his cabbages early this year, and Sparks came up with them."],
		["hob_gift", "Hob. Skimmed nine Sparks across the river to you, because Tam said you'd need them more than him."],
	]},
	{"id": "ned", "look": "fiddler", "place": "Ashford", "met": "met_ned | met_seamus", "lines": [
		["", "Ned. Plays a reel as old as the Age, and wonders how the last night of the last one went."],
	]},
	{"id": "herald", "look": "herald", "place": "Ashford", "met": "pro_part=taproom,burning,cellar,that_day,reckoning,tunnel | pro_tunnel_done | arrived_thornwood", "lines": [
		["", "My Herald. It says what the Covenant gives it to say, and nothing else."],
	]},
	{"id": "krell", "look": "krell", "place": "Ashford", "met": "pro_part=cellar,reckoning,tunnel | pro_tunnel_done | arrived_thornwood", "lines": [
		["", "Sabine Krell. Ironvault's Huntmaster. Never raises her voice. Wanted the white card, not a heap of ashes."],
	]},
	{"id": "dask", "look": "hunter", "place": "The Thornwood", "met": "beat_hunter", "lines": [
		["", "Dask. Staked every card he owned to pay off his mother's note, and lost them to you."],
		["dask_kept_hound", "Dask. Staked every card he owned on his mother's note and lost them to you. You gave him back his hound."],
		["dask_sent_home", "Dask. Staked every card he owned on his mother's note and lost them to you. You sent him home."],
	]},
	# ------------------------------------------------------------ Solhaven
	{"id": "hale", "look": "guard", "place": "Solhaven", "met": "met_hale | beat_hale | c1_done", "lines": [
		["", "Warden Hale. Keeps Solhaven's south gate, and tests a mark before he trusts it."],
		["beat_aldric & !let_refugees_in & !let_children_in & !gate=all,children | c6_done & !gate=all,children & !let_refugees_in", "Warden Hale. Kept his gate shut, as ordered, and asked you to remember the people outside it."],
		["let_children_in | gate=children", "Warden Hale. Let the children in, one grown-up with each, and had his pay docked for every one."],
		["let_refugees_in | gate=all", "Warden Hale. Opened a gate he was told to keep shut."],
		["side_hale=stood,lost", "Hale. Opened a gate he was told to keep shut, and paid for it."],
		["side_hale=won", "Hale. Opened a gate he was told to keep shut, and you wouldn't let him pay for it."],
	]},
	{"id": "wren", "look": "wren", "place": "Solhaven", "met": "met_wren | beat_wren | c3_done", "lines": [
		["", "Wren. A thief. Took the blank card out of your pocket, and found out that it bites."],
		["beat_wren", "Wren. A thief who keeps her deals. Told you the price on your hand: ten thousand crowns, Ironvault's."],
	]},
	{"id": "pip", "look": "child", "place": "Solhaven", "met": "met_pip | side_started_pips_errands", "lines": [
		["", "Pip. Eleven. Means to carry Ser Aldric's shield one day; Ser Aldric doesn't know yet."],
		["met_pip_before | side_started_pips_errands", "Pip. Eleven. Runs Mr Pell's notes for two crowns a run, and means to carry Ser Aldric's shield one day."],
		["side_pip_place=hale,aldric,tamsin", "Pip. Eleven. Has a place now, and asked straight away whether Ser Aldric goes past it."],
	]},
	{"id": "maren", "look": "elder", "place": "Solhaven", "met": "met_maren | side_started_sundial_scar", "lines": [
		["", "Old Maren. Thirty years a Temple scribe, until she asked which Champion the sun was slowed for."],
		["side_scar=told", "Old Maren. Kept forty pages in a bread tin for thirty years, and gave them to you."],
	]},
	{"id": "tamsin", "look": "merchant", "place": "Solhaven", "met": "met_tamsin", "lines": [
		["", "Tamsin. Sells Sigil caches out of the Shardlands, sealed, if not quite certified."],
	]},
	{"id": "liora", "look": "acolyte", "place": "Solhaven", "met": "met_liora | trial_light_passed | c5_done", "lines": [
		["", "Acolyte Liora. Keeps the Trial of Light, and the mirrors that set it."],
		["temple_leave | trial_light_passed | c5_done", "Acolyte Liora. Keeps the Trial of Light. The mirrors showed her you twice, and she hasn't told anyone."],
	]},
	{"id": "hierarch", "look": "hierarch", "place": "Solhaven", "met": "met_hierarch | sun_court_done | c4_done", "lines": [
		["", "Hierarch Cassius Aurel. Asked for your card, and called it an offer when he was refused."],
	]},
	{"id": "aldric", "look": "aldric", "place": "Solhaven", "met": "met_aldric | sun_court_done | c4_done", "lines": [
		["", "Ser Aldric Vane. The Sun's Champion, and the only one in his city who said he was sorry about Ashford."],
		["sun_court_done | c4_done", "Ser Aldric Vane. The Sun's Champion, and the only one in his city who said he was sorry about Ashford. His goddess hasn't spoken to him in a month."],
		["beat_aldric", "Ser Aldric Vane. Lost his first Trial to you, in front of his city, and gave you his Lion's light."],
	]},
	{"id": "ysa", "look": "side_ysa", "place": "Solhaven", "met": "side_mercy | side_duel_on=mercy", "lines": [
		["", "Ysa. Prays to the Rootmother. Her son had a burn fever from the night the sky fell."],
		["side_mercy=swore,her_choice", "Ysa. Prayed to the Rootmother, and swore to the Sun for her son. She wears a sun disc now."],
		["side_mercy=paid", "Ysa. Kept her green leaf. Can't pay you back, and won't forget it."],
		["side_mercy=anselm_won,anselm_lost,anselm_fine", "Ysa. Said a forgotten god's name once, and hung her green leaf on the lantern, so she'd know who was asking."],
	]},
	{"id": "tobin", "look": "child_b", "place": "Solhaven", "met": "side_mercy", "lines": [
		["", "Tobin. Six. Had a burn fever from the night the sky fell, and lived."],
	]},
	{"id": "anselm", "look": "side_anselm", "place": "Solhaven", "met": "side_mercy=anselm_won,anselm_lost,anselm_fine | side_duel_on=mercy", "lines": [
		["", "Brother Anselm. Keeps Ilvane, the god of people on the road at night, alive one word at a time."],
		["side_mercy=anselm_lost", "Brother Anselm. Kept Ilvane alive one word at a time, until the Sun Guard took him for healing a boy."],
	]},
	{"id": "sergeant", "look": "side_sergeant", "place": "Solhaven", "met": "side_mercy=anselm_won,anselm_lost,anselm_fine | side_duel_on=mercy", "lines": [
		["", "The Sergeant of the Dawn Watch. Calls healing heresy when the Temple hasn't licensed it."],
		["side_mercy=anselm_won", "The Sergeant of the Dawn Watch. Came for a heretic, lost the Circle to you, and saw no shrine and no boy."],
		["side_mercy=anselm_fine", "The Sergeant of the Dawn Watch. Took forty crowns for a heretic, and said that's what it costs, then."],
		["side_mercy=anselm_lost", "The Sergeant of the Dawn Watch. Took Brother Anselm by the arm, by the Covenant, and let the boy stay."],
	]},
	{"id": "fen", "look": "side_fen", "place": "Solhaven", "met": "side_fen", "lines": [
		["", "Fen. A Shardlander with a quick tongue. Sold your blessing for a copper, and put most of it in the soup."],
		["side_fen=truth", "Fen. Gives your blessing away now, and calls it a worse business and a better sermon."],
		["side_fen=carry_on", "Fen. Sells your blessing at a copper a time. It comes naturally."],
		["side_fen=beaten", "Fen. Washed the white off his hand in the fountain, and promised there'd be others."],
		["side_fen=won", "Fen. Beat you in the Circle and kept the name. The Unsworn's own blessing, witnessed."],
	]},
	{"id": "pell", "look": "side_pell", "place": "Solhaven", "met": "side_pip", "lines": [
		["", "Mr Pell. Ironvault's counting house. Pays on time, according to Pip."],
	]},
	{"id": "corvin", "look": "side_corvin", "place": "Solhaven", "met": "side_scar", "lines": [
		["", "Father Corvin. A priest of the Sun Temple. Smiles the whole time he's warning you."],
	]},
	{"id": "captain", "look": "side_captain", "place": "Solhaven", "met": "side_hale | side_duel_on=hale", "lines": [
		["", "The Captain of the Sun Guard. Plays by the book, because the book is all she has."],
	]},
]


## Does a condition hold? (See the top of this file.)
static func check(cond: String) -> bool:
	cond = cond.strip_edges()
	if cond == "":
		return true
	for alt in cond.split(" | "):
		var all := true
		for term in alt.split(" & "):
			if not _term(term.strip_edges()):
				all = false
				break
		if all:
			return true
	return false


static func _term(t: String) -> bool:
	if t == "":
		return true
	if t.begins_with("standing:"):
		return Standing.check(t)
	var neg := t.begins_with("!")
	if neg:
		t = t.substr(1)
	var ok := false
	var eq := t.find("=")
	if eq > 0:
		var v = Game.flag(t.substr(0, eq), null)
		ok = v != null and not (v is bool) and String(v) in t.substr(eq + 1).split(",")
	else:
		var v = Game.flag(t, false)
		ok = v != null and not (v is bool and not v) and not (v is String and v == "")
	return ok != neg


## The words for an entry with "parts" (or a person's "lines"), as they
## stand now.
static func words(parts: Array) -> String:
	var out := []
	for part in parts:
		var said := ""
		for line in part:
			if check(String(line[0])):
				said = String(line[1])
		if said != "":
			out.append(said)
	return " ".join(out)


## The accounts written so far, newest first: [{id, title, place, kind, open, text}].
static func accounts() -> Array:
	var out := []
	for a in ACCOUNTS:
		if not check(String(a.when)):
			continue
		out.push_front({"id": a.id, "title": a.title, "place": a.place, "kind": a.kind,
			"open": check(String(a.get("open", "!" + String(a.when)))) and String(a.get("open", "")) != "",
			"text": words(a.parts)})
	return out


## Everyone met, in the order they were met in the story: [{id, look, place, text}].
static func people() -> Array:
	var out := []
	for p in PEOPLE:
		if check(String(p.met)):
			out.append({"id": p.id, "look": p.look, "place": p.place, "text": words([p.lines])})
	return out
