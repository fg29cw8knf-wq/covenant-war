# Master Script v3: Chapter 1, The Sun's Court (the main story)

A plain copy of the lines the game's Chapter 1 is built from, taken from the
"Chapter 1" tab of the **Master Script v3** Claude doc (approved and locked by
Gary on 18 October 2026). The doc is the master: if they ever differ, the doc
wins. The five side stories are on the doc's "Side Quests" tab and aren't
copied here. How to read it, as in the Prologue (`v3_prologue_films.md`):
**Speaker:** is a line; a note in brackets after a name says when it plays and
is never shown; _italics_ are what we see and what the player does;
**Objective:** lines appear on screen; (V) marks a voiced line. A dialogue box
holds two sentences at most, so a longer line is shown as two boxes, broken
where a (beat) or the sense breaks it.

Seven scenes and about 60 minutes in Solhaven, plus five side stories. The
player gets a home, a second companion, a god's offer and the first Trial win;
the chapter ends on Morne. Four duels plus the Trial of Light puzzle. Every
story duel has one rule of its own that says something about the person
across the Circle, and every bark is tied to something on the board, once per
duel.

Where it is in the game: `scripts/world/areas/solhaven.gd` (the square: who is
there and what they say, the doors that start each film),
`scripts/world/solhaven/films.gd` (C1 to C7), `chase.gd` (Wren's chase),
`duels.gd` (the four duels and the Trial's boards), `solhaven_set.gd` (the
place); the duel rules are in `scripts/duel/duel_game.gd` (story rules), and
Morne's, Solmaris's and the Herald's voices play from `assets/audio/vo/`
(`morne_01`..`08`, `solmaris_01`..`09`, `herald_14`..`16`) once recorded.

Two things the doc leaves open and the game decides: the Hall of Mirrors'
board is a set puzzle for each of Bram's four decks (`duels.gd`, TRIALS); and
after the Trial the player has the afternoon in the square (everyone's "after
the Trial" lines) until they go back to Bram at the wagon: his line "once,
after the Trial" ends the day, and Gold in the Dark follows.

### C1 · The Golden Gate

_Solhaven revealed: white walls, gold domes, and the Sunspire, a tower crowned with a great mirror that throws the sun across the city. The road to the gate is crowded with refugees from villages the Sigilfall hit: carts, bundles, children asleep on sacks._

**Narration:** Three days after the fire, you reach Solhaven with the smoke still in your clothes. So does everyone else on the road.

**Refugee (a woman with a sleeping boy across her lap):** Three days we've waited. They let the pilgrims through. Not us.

**Refugee:** We pray to the Rootmother where we're from. Seems that's the wrong god this year.

_The gate is shut. In front of it stands Warden Hale in white and gold, with a line of guards._

**Hale:** Gate's closed. During the Turning, by the Hierarch's order, Solhaven admits sun-marked pilgrims and nobody else.

**Bram:** We're not pilgrims. Show him, Sprout.

**Narration:** You raise your hand. The white mark glows.

**Hale:** _(He looks closer.)_ They sell those in the Shardlands. Paint and a pinch of Spark-dust. Crown a dozen.

**Bram:** A Pale Herald called this one by name. In front of a whole village.

**Hale:** Then it won't mind being tested.

**The player's choice:** Test me, then. / Why the pilgrims and not them?

**Hale (test me):** Circle's there.

**Hale (why):** Because a god's as strong as the people praying to her, and this is the year she needs every one. _(beat)_ That's the Hierarch's arithmetic. Not mine. Circle's there.

**DUEL · The Gate** · Warden Hale · The Gate Watch. _A short duel: both sides start at half Life, because it's a test, not a fight. Duel rule: Hold the Gate. While Hale's Guardian stands, he never attacks your Life; he's there to hold, not to win. Bram's first-time lines introduce Guardians and Divine Gifts._

**Hale (his Guardian takes its first hit):** Hold.

**Hale (when he uses Dawn's Mercy):** Her mercy. Freely given, to them as kneel.

**Hale (his Guardian falls):** Hm.

**Hale (if he wins):** The gate stands.

**Hale (when you win):** _(He lowers his cards.)_ Not paint.

**Hale:** The gate's open to you, and whoever's with you.

**The player's choice:** Open it for all of them. / Let the children in, at least. / Thank you, Warden.

**Hale (all of them):** The Hierarch's orders are —

**Narration (all of them):** You hold his eye. He's just opened his gate for a mark on your hand. Behind you are people whose homes burned the same night yours did.

**Hale (all of them):** _(A long breath. Then, to his guards:)_ Open it. All the way.

**Hale (all of them):** _(To you, quietly.)_ Get them off the road before His Grace is up.

_The line pours through. The woman with the sleeping boy stops in front of you._

**Refugee (all of them):** What's your name?

_You tell her._

**Refugee (all of them):** I'll teach it to the boy.

**Hale (the children):** _(He looks along the line, at the children asleep on the sacks.)_ Children, and one grown-up with each. That's my limit, and it's past the Hierarch's.

_A third of the line goes through, the woman and her boy among them. The rest watch them go._

**Refugee (the children; left outside):** That's my sister's girl. Go on, love. Go on.

**Hale (thank you):** Don't thank me. Thank whatever chose you. _(He glances at the line.)_ I've my orders.


### C2 · The wagon

_The stable yard. Bram counts his last coins into a horse-trader's palm. In return: a battered wagon with a lamp hook, and a grey mule with one ear that won't stand up._

**Horse-trader:** Wagon, lamp hook, one mule. Mule's called Turnip. He bites.

**Bram:** Hard?

**Horse-trader:** Not hard.

_Bram hangs a lamp on the hook and lights it._

**Bram:** The Crooked Lantern.

**Bram:** That's the last of my money. We sleep here, we eat here, and you sort your cards on the tailboard.

**Narration:** Turnip bites your sleeve. Not hard.

**Objective:** Present your mark at the Sun Court. (The gold building up the hill.)


### C2 · Bram at the wagon

**Bram:** What do you need?

**The player's choice:** Any advice? / Rest and save / Change my deck / Tell me about the gods / About Morne...

**Bram (any advice):** Read the sign on a Totem's card before anything else. That's its element, and what it fears.

**Bram:** Then read yourself. Some cards want a strong arm, some a cool head. Give a card what it wants and it'll wake for you properly.

**Bram (rest and save):** Get some sleep. I'll keep the lamp lit. _(Game saved.)_

**Bram (change my deck):** Tailboard's yours. Turnip's been told. _(The deck screen opens.)_

**Bram (the gods):** Hundreds of them up there, and seven with a real claim on the Throne. Every one of them will want you in their colours before the year's out.

**Bram:** Swear to one and you get a blessing for it, and a leash. Stay Unsworn and you get a bit of everything and nobody's hand on your collar.

**Bram:** Your choice, when it comes. Don't let anyone hurry it. Least of all a god.

**Bram (about Morne):** Caldus Morne. Owns Ironvault, and the note on half of everything that isn't Ironvault.

**Bram:** Men like that don't want a thing. They want it owed to them.

**The player's choice (about Morne):** How do you know him? / Leave it.

**Bram (how do you know him):** I don't. _(He turns the lamp down.)_ I knew his father. Get some sleep.

**Bram (leave it):** I will.

**Bram (if you come back before the Sun Court):** Sun Court's up the hill. It's the gold one.

**Bram (once, after the Trial):** You beat their champion in front of the whole city. By nightfall half of Veyl will know your name. _(beat)_ I liked it better when nobody did.


### C2 · Tamsin's card stall

**Tamsin:** Sigil caches! Fresh out of the Shardlands, sealed and certified! _(Lower.)_ Sealed, anyway.

**Tamsin:** Crowns for caches. Win duels, earn crowns, come back. That's the whole of it.

**Tamsin:** Hrimmark caravan's a week late. Snow, at harvest. They say the boy-king's goddess has stopped minding the calendar.

**Tamsin (once a day):** There's a crier pays me to let him talk at my customers. Stand and hear him out, and there's a cache in it for you.

**Tamsin (after the Trial):** The Unsworn, at my stall. Everything's dearer today, love. Fame has a price, and I've just set it.


### C2 · Pip at the fountain

_A boy of about eleven is fighting the fountain with a stick._

**Pip:** _(He stops.)_ You're the Unsworn. Everyone says. _(He looks at your hand.)_ Doesn't look like much.

**Pip:** Ser Aldric's never lost a Trial. His Sentinel won't let anything past. You'd have to go round it. _(beat)_ You can't go round it.

**Pip:** I'm going to carry his shield one day. He doesn't know yet.

_A man in a grey coat crosses the far side of the square. Pip watches him go._

**Pip:** Got to go. Work.

_(This starts Pip's Errands.)_

**Pip (after the Trial):** You beat him. _(He doesn't know what to do with his face.)_ He's still the best. You just beat him, that's all.


### C2 · Old Maren, on the temple steps

**Maren:** Sit, sit. You've the look of someone who's walked a long way to be lied to.

**Maren:** Two thousand years of sun on these stones. Not one bad harvest in Solhaven. Lovely weather.

**Maren:** I was a scribe in that Temple thirty years. I copied the Great Sundial's reading every noon. Every single noon.

**Maren:** Then I found the old books. The readings from the last Turning. The shadows are nine days wrong.

**The player's choice:** Wrong how? / Why tell me?

**Maren (wrong how):** Somebody slowed the sun, child. Nine days of it. Long enough for the right Champion to catch up. _(She smiles without any humour.)_ They threw me out for asking which one.

**Maren (why tell me):** Because you're the first person in two thousand years the priests can't tell to hush. They'll try, mind.

**Maren:** Go and look at the Sundial at dawn. The oldest stone, under the steps. Then come and tell me I'm mad.

_(This starts The Sundial's Scar.)_

**Maren (after the Trial):** The Sun's own knight, beaten in the Sun's own city. The priests will be smiling at you now. Count their teeth.


### C2 · The notice board

**Narration:** The Seat roll, in gold leaf: seven kingdoms, and the Champion who holds each.

**Narration:** Underneath, in fresh black ink: {name}, the Unsworn, challenger. Someone has scratched a small coin beside it, crossed with a key.


### C3 · Thief in the Market

_On the way to the Sun Court the crowd thickens. A girl in a patched leather jacket bumps into you._

**Wren:** Sorry. Busy day.

**Narration:** She's gone. A beat. Your pocket is empty.

**Bram:** Your pocket! Go! I'll come round!

**Objective:** Catch the thief. (Tap the glowing ledges to vault and slide.)

**Wren (over her shoulder, once each):** Keep up! / Mind the washing! / Oh, come on!

_A dead-end alley. Wren turns, grinning, and holds up the blank card._

**Wren:** Right. Let's see what all the fuss is —

**Narration:** The card flares white. Wren yelps and drops it, and it flies back through the air into your hand.

**Wren:** _(Shaking her hand. There's a red welt across the palm.)_ Nobody said it bites.

**The player's choice:** That's mine. / Who sent you?

**Wren (that's mine):** So I see.

**Wren (who sent you):** Nobody sends me. I go where the money is, and you're carrying more of it than I've ever seen.

**Wren:** Here's a deal. Beat me, and I'll tell you what you're worth, and how many people know it. Lose, and you buy me dinner.

_Bram comes round the end of the alley, out of breath, and stops where he can see your cards._

**DUEL · The Alley** · Wren · Pickpocket. _Duel rule: Light Fingers. Once per duel, Wren takes a card from your hand and plays it as her own. Bram's first-time lines from the alley mouth introduce Ascension and hand disruption._

**Wren (she uses Light Fingers):** Let's see what you're hiding. _(She studies your hand.)_ I'll have that one.

**Wren (she knocks out one of yours):** Nice card. Shame about it.

**Wren (you take the lead):** You're getting better. Stop it.

**Wren (if she wins):** Dinner's on you. Somewhere with tablecloths.

**Wren (when you win):** All right. All right. A deal's a deal.

**Wren:** Ten thousand crowns. Posted this morning in every black market from here to the Shards, for a blank Sigil and the hand that holds it. Sealed with this.

**Narration:** She flicks you a wax seal: a coin crossed with a key. The same seal as the notes on Ashford's chapel door.

**Bram:** Ironvault.

**Wren:** Ironvault. And now everyone who can count to ten thousand is a hunter.

**Wren:** I've just told you, which my fence won't love. He doesn't pay for failures. He collects on them.

_She tugs back her sleeve. On a cord round her wrist hangs a black-market marker: a tin tag with her name stamped in it._

**Wren:** So. You need someone who knows where hunters drink. I need someone they're more interested in than me.

**The player's choice:** Prove it's real. / Why should we trust a thief?

_(Prove it's real.) She tosses you the tag. Real tin, a real stamp, a Shardlands fence's mark._

**Wren (prove it):** Keep it if you like. I've another.

**Wren (trust a thief):** You shouldn't. That's what makes me useful. I know exactly how people like me think.

_She pulls on a pair of fingerless gloves._

**Wren:** I'm Wren.

**Bram:** I don't like it. _(beat)_ Your call, Sprout.

**The player's choice:** She comes with us. / She doesn't.

**Wren (comes):** Good. Board, and a tenth of whatever you win. I'll keep the accounts.

**Wren (doesn't):** Fair. _(She walks off up the alley without looking back.)_

_(If she doesn't.) That night, she's asleep under the wagon. Turnip hasn't bitten her._


### C3 · Wren at the wagon, afterwards

**Wren:** You check that pocket every time someone passes. Stop it. It tells people where to look.

**Wren (before the Trial):** One for free, and I don't do free. Aldric's deck has a Legend in it: Sunlance Seraph. And he keeps something bigger back for when he's losing. Everyone in Solhaven knows its name. Nobody's seen it, because nobody's ever had him losing.

**Wren (after the Trial):** Half the city's seen your face now. Mind your pocket.


### C4 · The Sun Court

_A vast white hall under a sun-window. Light falls in a single gold column onto a lower throne beneath a towering statue of Solmaris. On the throne sits Hierarch Cassius Aurel: gaunt, gold vestments, a sunburst mitre. Ser Aldric Vane stands at his side in golden plate. By a pillar waits the Pale Herald. Bram and Wren wait by the doors._

**Courtier (as you walk the aisle):** That's the Unsworn? From one of the Shardland villages, I heard.

**Courtier:** They pray to whatever falls on them, out there.

**Hierarch:** The Goddess welcomes every pilgrim, child. Even the ones she didn't send for. You'll present your mark, as the law requires.

**Narration:** You raise your hand; the mark glows.

**Hierarch:** Thank you. And you'll give that card into the Goddess's keeping, as any loyal subject of the Throne would. A blank Sigil in a farmhand's pocket is a danger to us all.

**The Pale Herald (V):** The Covenant forbids it.

**Narration:** The hall goes silent.

**Hierarch:** _(Without a pause.)_ Of course. I only meant to offer.

**Aldric:** _(Stepping forward.)_ Then let the Unsworn be tested, honestly. No challenger enters the Turning without the Sun Court's Trial. I'll give it myself, before the whole city. Your Grace?

**Hierarch:** _(A moment.)_ As you wish, Ser Aldric. After the Trial of Light, as every pilgrim must. If they pass it.

_The sun-window blazes white and sound stops. Courtiers, Hierarch and Aldric turn to statues of light mid-gesture. Only you can move. Above the throne, something vast leans down out of the glare: Solmaris, white and gold, her face lost in light. When she speaks, it's quiet, the way you'd speak at a sickbed._

**Solmaris (V):** Don't be frightened. Nobody else can hear us.

**Solmaris (V):** I watched your village burn. Nobody there was praying to me, and I can't answer a prayer nobody says.

**Solmaris (V):** And what I want from you, I can't take. The Covenant lets me ask. Nothing more.

**Solmaris (V):** So I will offer. Give me that card, freely, and Ashford will stand again by the next new moon. Every roof. Every note paid. The mill turning.

**Solmaris (V):** I can't give you back the miller. Morrowen keeps what she keeps. Everything else, I can.

**The player's choice:** No. Ashford didn't burn so I could sell it. / Not yet. / Tell me what it is first.

**Solmaris (no) (V):** _(Not angry. Tired.)_ Nobody says yes the first time.

**Solmaris (not yet) (V):** Then keep my offer. It doesn't spoil.

**Solmaris (what it is) (V):** Something I have spent two thousand years making sure nobody found. _(beat)_ And then it found you.

**Solmaris (V):** I'll ask again, when you've seen what that card costs the people around you.

**Narration:** The light folds away and time comes back. Nobody else seems to have seen a thing.

_(Your answer sets Solmaris's opinion of you, and "Not yet" is remembered for her last offer in Chapter 10. No oath can be sworn until the Closing.)_

**Objective:** Pass the Trial of Light in the Sun Temple.

_The steps outside. Aldric catches you up, away from the courtiers._

**Aldric:** The Goddess spoke to you. I saw your eyes change.

**Aldric:** She hasn't spoken to me in a month.

**Narration:** He walks away before you can answer.


### C5 · The Trial of Light

_The Sun Temple's Hall of Mirrors: a round hall lined with tall mirrors around a duelling circle, candles everywhere. A young acolyte in white, with a gold circlet, is lighting the last of them. She keeps looking at the mirrors instead of at you._

**Liora:** You're the Unsworn. I'm Liora. I keep the Trial.

**Liora:** I've kept it two years and never been nervous. I don't know why I am now.

**Liora:** The mirrors set the board, and you must win within three turns. If you get it wrong, they begin again. They're patient.

**Liora:** Your deck carries a Summon: a Demigod asleep in one card. The mirrors have put it in your hand. It costs everything you have.

**Objective:** Win within three turns. (A fixed board and hand, built around your deck's Summon. A mistake resets the board.)

**Liora (on a reset):** Again. The mirrors don't mind.

**Liora (on the third reset):** Some pilgrims start with the biggest thing they have. Some never do.

**Liora (when you Summon, and every mirror shows the Demigod at once):** _(Barely a whisper.)_ Oh.

**Liora (when you pass):** You've passed. You may challenge the Sun's Champion.

**Liora (she gives you the Revival Candle):** Every pilgrim who passes is given one. It has carried more than one Totem back from the dark.

**Liora:** Can I tell you something? I'm not meant to. The mirrors showed you twice. Once as you are. And once all in white.

**Liora:** They've never done that. Not in any book I've read, and I've read all of them.

**The player's choice:** What does it mean? / Don't tell anyone.

**Liora (what does it mean):** I don't know. _(beat)_ I don't want to.

**Liora (don't tell anyone):** Nobody listens to acolytes. Tonight I'm glad of it.

**Objective:** Climb the Sunspire and face Ser Aldric.

**Liora (afterwards, on the temple steps):** I haven't told anyone about the mirrors. I've been praying about it. _(beat)_ She doesn't answer me either.


### C6 · The Golden Knight

_The climb up the Sunspire's spiral stair, crowd noise growing. The roof: a great duelling circle under the colossal mirror, the stands packed with the people of Solhaven. The Hierarch in a shaded box. The Pale Herald at the circle's edge. Pip on someone's shoulders. (If you opened the gate, the cheap seats at the very top are full of refugees in travel-stained clothes.)_

**Crowd:** ALDRIC! ALDRIC! ALDRIC!

_Ser Aldric walks into the circle and salutes the crowd, then you._

**Aldric:** They say the sky fell on your village, and men with torches came after it. I'm sorry. Nobody in this city will say so to you, so I will.

**Aldric:** Whatever you are, I'll fight you fairly. It's the only promise anyone can make in this circle.

**The player's choice:** And I'll fight you the same. / Your goddess made me an offer.

**Aldric (the same):** Then she'll judge us both.

**Aldric (an offer):** _(Very still.)_ Then she's speaking to someone. _(beat)_ I'm glad.

**The Pale Herald (V):** The Sun Court's Trial, by the Covenant. If the Unsworn wins, they may challenge for any Seat in Veyl until the Turning closes. Begin.

**DUEL · The Trial** · Ser Aldric Vane · The Golden Oath. _Duel rule: The Sunspire's Mirror. At half Life, the great mirror swings to Aldric's side and his Radiant cards cost one less for the rest of the duel._

**Aldric (his Sentinel blocks for the first time):** Hold, Sentinel.

**Aldric (the first time one of your hits does 60 or more):** A good strike. Here's mine.

_At half Life, the great mirror swings on its chains to put the sun on Aldric's side of the circle. Aldric lays a card on the stone without a word. The crowd knows it from his banners before he can name it._

**Crowd:** DAWNMANE!

**Aldric:** _(To the card, quietly.)_ I've never once had to wake you.

**Aldric (his Life drops below a third):** Goddess, guide my hand.

_The first time your Life drops below a third, the duel freezes for a beat. The blank card in its slot beside your deck flickers, and a faint image shows on it, a white eye inside a ring of runes, then fades. Aldric doesn't see it. The Pale Herald's hood turns, very slightly._

**Aldric (if he wins):** Well fought. Solhaven keeps its knight.

_When you win: Aldric's last Totem falls, and the light it sheds pours into your hand. Silence across the stands. Nobody moves._

**The Pale Herald (V):** The Unsworn is tested and found worthy. Challenge whom you will.

**Narration (the game gives you Sunmane Lion, a new Tier IV card, lesser kin of Dawnmane):** The light his fallen Totems shed gathers in your open hand and cools into a card: a lion of your own.

**Aldric:** _(Watching it form.)_ My Lion's light, made yours. Treat it well.

_Still silence. The Hierarch rises and leaves his box without a word._

_(If you opened the gate.) From the cheap seats at the very top, one voice, then a dozen: the refugees, on their feet, shouting your name. Nobody else joins them. Nobody stops them._

_(If you let the children in.) From high in the stands, children's voices, a handful, shouting your name until somebody hushes them._

_(If you left the gate shut.) A single coin spins down from the stands and rings on the stone at your feet. A crown, for a forgery._

_Pip, on someone's shoulders, is crying, and furious about it._

**Aldric:** Who taught you?

**The player's choice:** An innkeeper. / Nobody, till last week.

**Aldric (innkeeper):** Then I'd like to meet him.

**Aldric (nobody):** _(He looks at his hands.)_ Twenty years, I've trained.

**Aldric:** _(He looks up at the mirror.)_ She'll know of this before the sun sets. Not from me. She'd have to ask.

**Aldric (afterwards, in the square):** Go carefully. The Hierarch won't forgive this as easily as I do.


### C6 · Warden Hale, afterwards

**Gate warden (if you opened the gate):** Hale? Stripped of his command this morning, Hierarch's orders. He's in the barracks yard, if you want him. _(This starts Hale's Orders.)_

**Hale (if you let the children in):** Half a day's pay docked for every child. Cheapest thing I've bought in years.

**Hale (if you left the gate shut):** {name}. The people outside the walls. If you ever have the ear of somebody who matters, remember them. I can't.


### C7 · Gold in the Dark

_Night. The wagon in a field outside Solhaven's walls; Turnip asleep. Bram sits on the tailboard turning the blank card under the lamp. The faint image comes back: a white eye inside a ring of runes._

**Bram:** _(Whispering, to the card.)_ I burned every word about you. Every word.

**Narration:** He puts the card in his coat and stares into the dark for a long time. In the shadow of the wagon wheel, Wren is awake. She heard. She says nothing.

_Ironvault. The vault from the opening movie: iron racks of glowing cards climbing into the dark, a ledger desk, a gold case with eight empty slots. For the first time we see the face: Caldus Morne, silver-gold hair, black velvet, rings on every finger, reading glasses he takes off when he listens. Huntmaster Krell stands before the desk._

**Krell:** The Unsworn beat the Sun's knight. On the Sunspire, in front of the whole city.

**Morne (V):** Good.

**Krell:** Sir?

**Morne (V):** Every Champion they beat is one we needn't. Let them do the work. _(He turns a page.)_ What else?

**Krell:** Ashford's closed. Nobody pointed. We took the mill and the farms under the terms. The inn we burned.

**Morne (V):** And the miller?

**Krell:** He lied to me.

**Morne (V):** _(He makes a note.)_ Give his widow back the mill, with the note marked paid. Profit from a death looks like exactly what it is.

**Krell:** There's an old man travelling with the Unsworn. Sixty or more. Calls himself Bram. His was the only roof in Ashford we never held paper on. He paid for it in gold, twenty years back.

_Morne's pen stops._

**Morne (V):** Holloway.

**Krell:** You know him, sir?

**Morne (V):** He has an account with us.

_He crosses to a shelf of old ledgers, takes one down, thirty years of dust on it, and opens it on the desk beside today's. On the open page, one line has never been closed:_ HOLLOWAY, B. · 4,000 cr. · outstanding.

**Morne (V):** Take the price off the Unsworn. Let them win.

_He dips the pen._

**Morne (V):** Put it on Holloway. Alive.

_He writes today's date beside the old line._

**Caption:** End of Chapter One: The Sun's Court.

_Next time the game opens: dawn. The wagon rolls out of Solhaven, Turnip in front, Bram at the reins, you beside him, Wren on the roof. The map of Veyl opens on six kingdoms, a Champion's banner flying over each._

**Bram:** Pyreholt's nearest.

**Objective:** Choose a kingdom. (Tap a banner on the map.)
