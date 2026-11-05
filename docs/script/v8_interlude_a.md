# The Covenant War · Interlude A · The Hunters (draft v1, for Gary's yes)

_5 November 2026. Written by Claude for Gary to read before anything is built.
Nothing here is in the game yet, and nothing in the Prologue (v7) or Chapter 1
(v3) has been changed to make room for it. Two small lines in Chapter 2
(Pyreholt, v1, also waiting for your yes) would change; they're listed in the
notes._

**How to read it.** As in v7 and Pyreholt: **Name:** is a line; _(italics in
brackets)_ are what we see and what the player does; **[GAME]** is what the
game does that isn't a line, and anything it tells the player is in brackets
on screen, never in a character's voice; **Thought:** is the player's own
thought, shown in brackets and italics. `{name}` is the name written in the
frost. **Every line waits for a tap.** In a menu of questions, the ones not
yet asked come back after each answer, and one choice moves on. A dialogue box
holds two sentences at most. A line that depends on an earlier choice is
marked _(if ...)_ with the flag the game already keeps.

**Where it sits.** Between Chapter 1 and the first kingdom. Chapter 1 ends on
the map and "Choose a kingdom."; the wagon sets out, and this plays on the
plains road two days out of Solhaven, before the player gets where they chose
to go. It's written for Pyreholt as the first kingdom ("Pyreholt's nearest.");
the one line that changes if it isn't is marked. (v1 Pyreholt had Interlude A
after the second kingdom: Question 1.)

**What it leans on.** C7: Morne takes the price off the Unsworn ("Let them
win.") and puts it on Holloway, alive. The Prologue's last choice on the
Thornwood road, which the game keeps as `dask_kept_hound` or `dask_sent_home`.
Wren's deal in C3 ("You need someone who knows where hunters drink. I need
someone they're more interested in than me.") and her fence, who "doesn't pay
for failures. He collects on them." The Reckoning: Krell, her warhorse, her
hound of shadow, Tam.

**The two ways.** **W (warned)** is `dask_kept_hound`: Dask finds the wagon and
warns you off. **L (led)** is `dask_sent_home`: Dask leads Krell's hunters to
you. Both come to the same ford and the same Huntmaster, from opposite banks.

**How long it plays.** About 35 minutes. Four scenes. One duel if Dask warned
you, two if he led them.

| | Scene | What happens |
|---|---|---|
| Dusk | IA1 · The Two Roads | A crossroads inn where hunters drink. The board: your bill gone, Bram's in its place, Wren's tag beside it. (W) Dask comes out of the dark |
| Night or morning | IA2 · Two ways to the water | (W) Garrow's Ferry by night, down the far bank at dawn. (L) The plains road at first light |
| Morning | IA3 · The Wend Ford | Krell's ambush, met from behind (W) or walked into (L). **Duel: Dask** (L only). **Duel: Krell.** Who goes free |
| Night | IA4 · The far bank | Out of the Sun's country. Wren says a name. Bram doesn't answer |

---

## The script

**Caption:** Interlude · The Hunters

**Morrowen (V):** I have written down a great many hunters. Every one of them
was paying something off.

### IA1 · The Two Roads

_(Dusk, the second day out of Solhaven. Flat country, the long grass gone the
colour of rope, a sky with all the warmth gone out of it. The plains road runs
east, the drovers' road crosses it north to south, and where they cross stands
a long, low coaching inn with a yard full of wagons and horse lines. Over the
door: THE TWO ROADS. At the crossing itself, a signpost of black oak carved at
the top into a head with two faces, one looking down each road.)_

_(The wagon comes into the yard: Turnip in front, Bram at the reins, the player
beside him, Wren on the roof with her hood up. (If Wren was told no in
Solhaven, she's on the roof anyway: she has been since the first night, and
nobody has said anything about it.))_

**Wren:** _(Looking at the signpost.)_ Weylin's. Leave him a copper and he won't
warn you about a thing.

**Bram:** Then why leave him a copper?

**Wren:** So he won't warn anyone about you. _(She drops off the roof.)_ Wait
here. This is where hunters drink.

**Bram:** And you'd know.

**Wren:** That was the deal.

**The player's choice:** I'm coming with you. / Be quick.

**Wren (with you):** Then keep your hand out of that pocket.

**Wren (be quick):** I'm always quick. _(She's back before Bram has the brake
on.)_ You'd better see this.

_(The taproom: low beams, a long fire, drovers at the tables. Along the back
wall, eight or nine men and women who aren't drovers: good boots, card cases at
the belt, a crossbow on a peg. Behind the bar, a big woman with grey hair
scraped back and a black feather stuck through it: Ma Corbie. By the bar, a
notice board with a carved rook on top, thick with bills.)_

**Ma Corbie:** Board's a copper to read and a crown to post. The back table's
hunters, and they don't share it.

_(Near the top of the board, a nail with the corner of a bill on it, the rest
torn away. Under it, fresh, a good drawing of Bram, eyepatch and all:
HOLLOWAY, B. ALIVE. TEN THOUSAND CROWNS. The wax seal is a coin crossed with a
key.)_

**Wren:** _(Touching the torn corner.)_ That was you, last week. _(She taps
Bram's.)_ Same sum. They didn't even change the number.

**Thought:** _(ALIVE is written bigger than the rest.)_

_(Lower down, small, a tin tag hangs from a nail by its cord, a name stamped in
it: WREN. Under it, in chalk: 40. COLLECT.)_

**Wren:** _(Quite still.)_ Forty.

**Wren:** I've lifted more than that off a bishop before breakfast.

**The player's choice (a menu; "We should go." moves on):**

- "What's the tag?" → **Wren:** My fence's. He posts you when you've cost him
  something. _(beat)_ I told you what you were worth, in that alley. That cost
  him.
- "Who's at the back table?" → **Ma Corbie:** _(Not looking up.)_ Krell's.
  Hired yesterday, a week's pay in advance. → **Wren:** They looked at you and
  went back to their beer. _(beat)_ They're watching the yard.
- "We should go."

**Ma Corbie:** Anyone can take a tag down. Forty, and it's off the board.

**The player's choice:** Pay it. (40 crowns) / It's Wren's.

_(Pay it.) Ma Corbie counts the crowns twice, unhooks the tag and holds it out.
Wren doesn't take it straight away._

**Wren (paid):** Now I owe you forty crowns.

**Wren (paid):** _(She takes the tag.)_ I've never owed anybody anything I
couldn't steal back.

[GAME] Sets `ia_wren_tag_paid`. (Wren will remember. What people think of you
is kept in the menu, under Standing.)

_(It's Wren's.) Wren reaches past Ma Corbie, unhooks her own tag and drops it
into her jacket._

**Ma Corbie (Wren's):** That's not how it works, love.

**Wren (Wren's):** _(She puts a copper on the bar.)_ For the nail.

[GAME] Sets `ia_wren_tag_hers`.

_(The yard. Bram's on the tailboard. Wren hands him the bill. She took it off
the board on the way out; there were others.)_

**Bram:** _(Reading it.)_ Alive. _(He folds it in four.)_ That's generous of him.

**The player's choice (a menu; "So what do we do?" moves on):**

- "Why you?" → **Bram:** I knew his father. _(beat)_ Sons keep their fathers'
  books.
- "They took it off me." → **Bram:** So you can win for him. Every Champion
  you beat is one Morne needn't. → **Bram:** Men like that don't want a thing,
  Sprout. You know the rest.
- "So what do we do?" → **Bram:** We cross the Wend at first light, before
  that table's finished its breakfast. _(He looks east.)_ The far bank's out
  of the Sun's country. I'll breathe easier over it.

#### (W) Dask, at the yard gate _(if dask_kept_hound)_

_(Full dark. Only the inn's windows lit. Turnip's ears come up. At the yard
gate, low down, a hound's eyes: a Shieldhound, its little helm dull with road
dust. Behind it, Dask, keeping out of the lamplight.)_

**Dask:** Don't. Don't call anyone. I've two minutes before they miss me.

**Dask:** Krell's at the Wend Ford. Twelve of hers in the reeds on both banks,
and nets in the water. She's had me on your wheel-ruts since Solhaven.

**Dask:** It isn't you she wants. _(He looks at Bram.)_ It's him. Alive, she
said. She said it twice.

**The player's choice (a menu; "Why tell us?" moves on):**

- "How long have you been following us?" → **Dask:** Since Solhaven. You
  drive slow. The mule bites.
- "What does it pay?" → **Dask:** Mam's note, cleared. If he's in her wagon by
  tomorrow night. _(beat)_ Same as last time.
- "Why tell us?" → **Dask:** _(The hound leans against his leg.)_ You gave her
  back. → **Dask:** Nobody gives anything back. So now we're square, and I
  don't owe you.

**The player's choice:** Come with us. / What happens to you now?

**Dask (come with us):** And leave Mam on her own when the bailiffs knock?
_(He's already backing off.)_ Go round by Garrow's Ferry, upriver. Nobody
watches a ferry nobody uses.

**Dask (what happens):** She'll know. She can count. _(beat)_ Go round by
Garrow's Ferry, upriver. Nobody watches a ferry nobody uses.

_(He's gone. The Shieldhound goes after him without being called.)_

**Bram:** He'll pay for that.

**Wren:** He knows.

**Bram:** Hitch him up, Sprout. We're going now.

#### (L) The yard, after dark _(if dask_sent_home)_

_(Full dark. Bram asleep on the tailboard with his boots on. Wren on the roof.
Out past the yard gate, too far for the lamplight to reach, someone stands in
the long grass watching the wagon: a young man with a crossbow on his back and,
beside him, a grey Brassback with the House's mark on its collar. He watches a
long while. Then he turns and goes east, at a run.)_

_(In the yard, Turnip's ears come up, and go down again.)_

### IA2 · Two ways to the water

#### (W) Garrow's Ferry, by night

_(The drovers' track north along the river, in the dark, no lamp. Bram leads
Turnip by the bridle. At Garrow's, a mill with no roof, and below it the
ferry: a flat timber raft on an iron chain strung across the Wend, the chain
padlocked to a post on the near bank.)_

**Wren:** _(Already kneeling at the lock.)_ Somebody thought about this. _(It
opens.)_ Not very hard.

_(Turnip stands on the raft with all four feet planted and his eyes shut.)_

[GAME] **Objective:** Haul the ferry across. (Hold to haul the chain. Let go
and the raft drifts back a little. It can't be failed.)

_(Halfway over, the river loud and black under the boards. On the far bank,
Turnip bites the player's sleeve. Not hard.)_

_(The east bank, before dawn. They come down it through the willows with the
wheels wrapped in sacking, and through the mist ahead, the glow of a shaded
lamp in a hollow.)_

#### (L) The plains road, at first light

_(Grey morning, mist lying on the grass. The road runs down a long slope to the
Wend: wide and shallow here, the colour of pewter, willows and reeds thick on
both banks. Halfway across, a flat shelf of stone breaks the surface with a
Circle cut into it, worn almost smooth by a hundred years of drovers settling
their quarrels.)_

**Bram:** Out of the Sun's country by breakfast. _(He clicks his tongue at
Turnip.)_ Go on, then.

_(The wagon goes down into the water.)_

### IA3 · The Wend Ford

_(Gary's film, two ways: see the notes.)_

#### (L) From the front

_(The water up to Turnip's knees. The wheels go up onto the stone shelf. Then
Turnip stops dead, and won't be moved.)_

_(The reeds on both banks stand up. They're people: a dozen, in grey coats and
hunters' leathers, cards already in their hands. All round the wagon, lines of
white light rise out of the river and close like the fingers of a hand: a
net. It takes Bram off the box before he's got a card out of his coat and holds
him on his knees in the shallows, bound in strands of light. Wren is off the
roof and onto the stone before it closes.)_

_(Out of the willows on the far bank, at a walk, comes a heavy warhorse. In the
saddle, immaculate, Huntmaster Sabine Krell. At her stirrup, a hound the size
of a pony, armoured, made of shadow: the thing that tore Tam's River Hound
apart. At her other stirrup, on foot, the House's Brassback at his heel and
the end of the net's light in his hand: Dask.)_

**Wren:** _(Low.)_ That's the boy off your road. Isn't it.

**Krell:** Good morning, Mr Holloway.

_(The player's hand is already on their deck box.)_

**Krell:** _(To the player.)_ And good morning to you. You can put your hand
down. Nobody here will touch you, or your card.

#### (W) From behind

_(Dawn. The hollow under the willows on the east bank: grey canvas, horse
lines, a field desk with a ledger on it and a lamp turned low. The camp is
nearly empty. Its people are down in the reeds at the water's edge, every one
of them watching the other bank, the road, the way a wagon would come.)_

_(At the desk, writing, sits Huntmaster Sabine Krell. Her warhorse stands
saddled behind her. At her feet lies the hound of shadow that tore Tam's River
Hound apart. And on the ground beside the desk, on his knees in a ring of white
light, his Shieldhound pressed against him: Dask.)_

**Krell:** _(Without looking up.)_ Good morning, Mr Holloway. You came by
Garrow's Ferry. _(She finishes the line she's writing.)_ Mr Dask was late back
last night. I can count.

_(Behind the player, Bram has a card in each hand. The air round the wagon
tightens, the way it does before a storm: Wards, a dozen of them, laid while
nobody was looking.)_

**Krell:** _(She looks up at last, at the player, whose hand is on their deck
box.)_ And good morning to you. You can put your hand down. Nobody here will
touch you, or your card.

#### The terms (both ways)

**Krell:** Mr Morne has taken the price off you. It's on Mr Holloway now, and
it's for him alive.

**Krell:** You're to be let win, Unsworn. Every Champion you beat is one Mr
Morne needn't.

**Krell:** I'm not permitted to take your card. _(beat)_ I'd like you to know
that I mind.

**The player's choice (a menu; the last one moves on):**

- "What does Morne want with him?" → **Krell:** Mr Holloway has an account
  with the House. Mr Morne would like it closed. → **Bram:** I closed it. At
  Ashford's gate, on a trestle, twenty years ago. → **Krell:** Then you'll
  have the page. _(Bram says nothing.)_
- "Ashford." → **Krell:** Quiet. The House has the farms and the houses,
  under the terms. Mrs Hayes has her mill back, with the note marked paid. Mr
  Morne thought it looked better. → **Krell:** Your inn, Mr Holloway, I
  burned. It was never the House's, so it was worth nothing to us standing.
  _(beat)_ And something to you.
- "Tam Hayes." → **Krell:** He lied to me, to my face, for you. _(beat)_ I've
  thought about him more often than I'd like.
- _(L)_ "Dask." → **Krell:** Mr Dask tracked you from Solhaven on a deck the
  House lent him. If Mr Holloway's in my wagon tonight, his mother's note is
  cleared. → **Dask:** _(Not looking at you.)_ You sent me home. I went. The
  note was still on the door.
- _(W)_ "Let Dask go." → **Krell:** Mr Dask took the House's money and spent
  the night working for you. His mother's note is called on the first of the
  month. _(beat)_ I'm sorry. It was due.
- _(L)_ "Let him out of that net." (moves on)
- _(W)_ "Go home, Huntmaster." (moves on)

#### (L) The shallows

_(The player goes down off the stone towards Bram. Dask steps into the water
between them, the Brassback planting its feet in the current.)_

**Dask:** No. She said keep you busy.

**The player's choice:** Out of my way, Dask. / Don't do this.

**Dask (out of my way):** Make me. You're good at it.

**Dask (don't):** You did it first.

_(The player draws. Dask's hand is steadier than it was in the Thornwood.)_

**Dask:** I set the stakes, then. If I win, you stand in this water and watch
them take him. If you win... _(He looks at Krell.)_ You can try her.

**DUEL · The Shallows** · Dask · Borrowed Hounds. _A main-story duel: lost, it
is Dask's winning line, then Morrowen takes the story back._

- _His deck: the House's, lent on his account: Brassback, Shieldhound, Ironhide
  Warbeetle, Blightrat, Burrowmole, Pebblit, Hunter's Mark, Poison Trap,
  Jagged Shards. Metal, Earth and Venom. None of it his._
- _Ground and Law: the shallows at the ford's edge, nobody's ground. The Wend
  is the edge of the Sun's Dominion and its Law stops at the water: no Law._
- _Duel rule: **Nothing Left.** Dask starts at half Life, never Guards, and his
  Totems hit 20 harder. He lost everything once already; he isn't keeping
  anything back._
- _Crystallises (your win): by its energy, usually a Tier I or II Metal card._

**Dask (his first turn):** Same road. Different hound.

**Dask (his first Ward springs):** Didn't see the trap? Nobody does.

**Dask (one of his Totems is knocked out):** That one's the House's. Put it on
my account.

**Dask (you have enough on the board to finish him):** Go on. You're good at it.

**Dask (if he wins):** Stand there. Watch.

**Dask (when you win):** _(He doesn't look at you.)_ Go on, then. She's waiting.

_(He steps out of the Circle into the shallows. The net's light is still in his
hand.)_

#### (L) The stone

**The player:** Huntmaster. I challenge you.

**Krell:** Of course. Then I set the stakes.

**Krell:** If you win, Mr Holloway walks out of my net and I ride home. If I
win, he comes with me, and you'll not follow us over that bank.

**Krell:** _(Pleasantly, to Dask.)_ And if he walks, Mr Dask, I'll owe you
nothing. That was the agreement.

_(Dask's hand tightens on the light.)_

#### (W) The camp

**Krell:** Mr Holloway has his Wards up, and my people are in the reeds facing
the wrong bank. I could take him. I'd lose six of mine doing it, and I'd
rather not.

_(She stands, and draws.)_

**Krell:** I'm told a Seat can't refuse a drawn hand, and you hold one now. I
challenge you, Unsworn. You set the stakes.

**Bram:** Sprout—

**Krell:** I'd like to see what I was sent to fetch at Ashford. That's all.

**Krell:** The Covenant weighs stakes one for one. If I win, I'll have Mr
Holloway. If you win, name the one thing I give up.

**The player's choice:**
- You give up the hunt. You never come for him again.
- You let Dask go, and his mother's note stands as it was.

**Krell (the hunt):** For myself. _(beat)_ Agreed.

**Krell (Dask):** Agreed.

_(Dask looks at the player. Krell doesn't look at Dask at all.)_

[GAME] The stakes are sworn: `ia_stake_bram` or `ia_stake_dask`. (A sworn
stake stands, win or lose; lose, and Morrowen takes the story back.)

_(Down to the water. The hunters in the reeds turn round. Krell rides into the
ford and steps down off her horse onto the stone shelf.)_

#### The duel (both ways)

**DUEL · The Wend Ford** · Huntmaster Sabine Krell · The House's Hounds. _A
main-story duel: lost, it is Krell's winning line, then Morrowen takes the
story back._

- _Her deck: hounds and traps, Umbral, Metal and Verdant, every card
  answering to Ruadh of the Hunt: Dun (her hound of shadow, Ascended; new),
  Duskstalker, Shieldhound, Brassback, Ironhide Warbeetle, Pack Howl, Hunter's
  Mark, Strangling Roots, Ambush Snare, Iron Bastion, the Huntmaster's Net
  (new)._
- _Ground and Law: the drovers' old Circle on the stone shelf, nobody's ground;
  no Law (the Sun's stops at the water)._
- _Duel rule: **Five Minutes.** ("I will wait five minutes," she said on
  Ashford's green.) For her first five turns Krell's Totems strike only your
  Totems, never your Life. From her sixth turn the note is due: every card you
  play costs 1 more Essence for the rest of the duel._
- _A MEMORY OF BRAM (the first time a rival's own rule turns in the middle of
  a duel, if not yet learned):_ "Some duellists give you time. Don't ever take
  it for a kindness." / "They're counting. Spend it as if you'll be asked for
  it back, with interest."
- _Crystallises (your win): by its energy, usually a Tier II Umbral card;
  often Dunling, a lesser kin of her hound (new)._

**Krell (her first turn):** I'll wait.

**Krell (Dun knocks out one of yours, the first time):** Dun. Heel.

**Krell (her sixth turn: Five Minutes ends):** Five minutes.

**Krell (Dun is knocked out):** _(She looks at the empty place in front of her a
moment longer than she needs to.)_

**Krell (you have enough on the board to finish her):** Go on. Mr Morne will be
delighted.

**Krell (if she wins):** Thank you. Mr Holloway, if you'd come.

**Krell (when you win):** _(She lowers her cards, and the light goes out of the
Circle.)_ Well. _(beat)_ That's settled.

#### After (L)

_(Krell looks at Dask. He opens his hand, and the net round Bram goes out like
a lamp. Bram gets up out of the water slowly, the way old men do, and doesn't
let anyone see what it costs him.)_

**Krell:** _(Back in the saddle.)_ Mr Dask, you tracked well. I'll say so in my
report.

**Krell:** I owe you nothing else.

**Krell:** _(Turning her horse, to the player.)_ Every Champion you beat is one
Mr Morne needn't. Do beat them.

_(She rides up the east bank into the willows, Dun at her stirrup. Her people
come out of the reeds wet to the waist and go after her without a word. Dask
stays where he is, up to his shins in the river, the House's Brassback
shivering beside him.)_

**Dask:** _(To the water.)_ Eleven years. I was a day off it.

_(The thirty cards from his wager in the Thornwood are still in the player's
collection.)_

**The player's choice:** (Give him back his deck.) / (Leave him.)

_(Give him back his deck.) The player takes his cards out of the box, every one
that came off his wager on the road, and holds them out._

[GAME] (Dask's thirty cards leave your collection.)

**Dask (given):** _(He looks at them a long time.)_ ...Why?

_(He takes them.)_

**Dask (given):** There's a bill on that board for a horse thief in Hrimmark.
Two hundred crowns. _(beat)_ That's a start.

[GAME] Sets `ia_dask_deck_back`. (Dask will remember.)

_(Leave him.) Dask stands in the river a while longer. Then he wades out on the
near bank and walks back up the road towards Solhaven, the House's Brassback
at his heel._

**Dask (left):** _(Not turning round.)_ Home.

[GAME] Sets `ia_dask_left`.

**Bram:** _(Wringing out his coat.)_ You came into the water after me.
_(beat)_ In your boots.

#### After (W)

_(If the stake was the hunt.)_

**Krell:** Agreed is agreed. I'll not come for you again, Mr Holloway. I'll tell
Mr Morne I couldn't, and why.

**Krell:** He'll send someone else. Someone you'll find harder to say no to.

**Krell:** _(To the reeds.)_ Bring Mr Dask.

_(Two of them lift Dask out of his ring of light and put him up behind a
saddle. One catches the Shieldhound's collar.)_

**Krell:** No. The hound's his. Let it follow.

**Dask:** _(As they lead him off, to the player.)_ Don't look like that. I knew
what it cost.

**Krell:** _(Turning her horse.)_ Every Champion you beat is one Mr Morne
needn't. Do beat them.

_(She rides up the bank, Dun at her stirrup, and her people go after her.)_

**Bram:** _(When she's gone. He doesn't look at you.)_ You chose me over a boy
who'd done right by you.

**Bram:** Don't do that again.

_(If the stake was Dask.)_

**Krell:** Agreed is agreed. _(She lifts a hand, and the ring of light round
Dask goes out.)_ Your mother's note stands as it was, Mr Dask. It falls due
when it was always going to.

**Krell:** _(To Bram.)_ And I'll see you on the road, Mr Holloway. Not today.

**Krell:** _(Turning her horse.)_ Every Champion you beat is one Mr Morne
needn't. Do beat them.

_(She rides up the bank, Dun at her stirrup, and her people come up out of the
reeds and go after her.)_

**Dask:** _(Getting up, the Shieldhound all over him.)_ Now I owe you again.

**Dask:** I'll pay it. Don't know how.

_(He goes south through the willows, towards home.)_

**Bram:** Good. _(beat)_ She'll be back.

#### Both ways

**Wren:** She keeps her word. That's what frightens me about her.

**Objective:** East, out of the Sun's country.

### IA4 · The far bank

_(Night on the plains road, the Wend a day behind. No fire: Bram warms the pot
with his hand, the way he did in the shelter. Turnip asleep standing up. Wren
on the wagon roof with her hood down for once. Bram on the tailboard, watching
the road behind them.)_

#### Bram, on the tailboard

_(When the player sits beside him, before anything's asked:)_

**Bram (if temper_angry):** You've been angry with me since the attic. You
walked into a river for me anyway.

**Bram (if temper_afraid):** You were frightened in the attic. You weren't
frightened in that river.

**Bram (if temper_resolved):** You told me in the attic to stop protecting you.
I didn't know you meant you'd start on me.

**The player's choice (a menu; "Goodnight, Bram." moves on):**

- "You'd have gone with her." → **Bram:** In a heartbeat. _(beat)_ She doesn't
  want you. That's the best news I've had in twenty years.
- "Your account with the House." → **Bram:** Paid. _(He turns the lamp a little
  lower.)_
- "Goodnight, Bram." → **Bram:** Go to sleep, Sprout. I've the watch.

#### Wren, on the roof

**The player's choice (a menu; "Goodnight, Wren." moves on):**

- "You know the Shards." → **Wren:** Long enough to leave them. _(beat)_ The
  crews comb the craters after a fall, for cards. I was small enough to get
  into the cracks.
- _(if ia_wren_tag_paid)_ "Forty crowns." → **Wren:** _(A stub of pencil and a
  scrap of paper: FORTY, and your name.)_ I've written it down. Don't get
  excited. I'm keeping the accounts, remember.
- _(if ia_wren_tag_hers)_ "Your tag." → **Wren:** _(Turning it over in her
  fingers.)_ There'll be another on the next board. He's got a drawer full of
  me.
- "Goodnight, Wren."

_(The player lies down under the canvas. The lamp is low. Wren hasn't moved.
When she speaks it's to Bram's back, quietly, as though she's been deciding
whether to since a night in Solhaven when she lay awake under a wagon wheel and
heard him whisper to a card.)_

**Wren:** The old crews in the Shards won't go out in a white storm. They say
that's when Kaethis sends someone down for what fell.

_(Bram doesn't answer. He doesn't turn round. After a while he reaches up and
turns the lamp out.)_

**The player's choice:** Bram. Who's Kaethis? / (Say nothing.)

_(Ask.) Bram doesn't answer. Out on the plain, something calls a long way off,
and stops._

[GAME] Sets `ia_asked_bram`.

_(Say nothing.)_ [GAME] Sets `ia_let_bram_be`.

**Caption:** Morning

_(The plain runs on east, and at the edge of it, low and black, the first folds
of the badlands, and one thread of smoke going straight up into the still
air.)_

_(If the player said nothing in the night.) Bram climbs up onto the box, sits,
and holds the reins out to the player._

**Bram (let him be):** You drive. He bites me more.

_(Turnip bites the player's sleeve as they take the reins. Not hard.)_

_(If the player asked.) Bram climbs up onto the box and takes the reins
himself. He says nothing until the badlands._

**Wren:** _(From the roof.)_ Is that smoke?

**Bram:** That's Pyreholt.

_(If the first kingdom isn't Pyreholt, there's no smoke, and Bram's line is
the kingdom's name.)_

**Objective:** Follow the road to Pyreholt.

---

## Morrowen's Ledger

Each account is a sentence or two in Morrowen's voice, in the past tense.

- **The Hunters** (W, the hunt): Dask came out of the dark to tell you that
  Krell was waiting at the Wend, and that it was Bram she wanted, alive. You
  came at her from behind and beat her on the stone, and asked for Bram. She
  took Dask instead.
- **The Hunters** (W, Dask): Dask came out of the dark to tell you that Krell
  was waiting at the Wend. You came at her from behind, beat her on the stone,
  and asked for Dask. She let him go, and told Bram she'd see him on the road.
- **The Hunters** (L, the deck): Dask led Krell's hunters to the Wend, and her
  net took Bram out of the wagon. You beat Dask in the shallows and Krell on
  the stone, and Bram walked. Krell owed Dask nothing after that. You gave him
  back his deck.
- **The Hunters** (L, left): Dask led Krell's hunters to the Wend, and her net
  took Bram out of the wagon. You beat them both, and Bram walked. You left
  Dask standing in the river.
- **Forty Crowns** (paid): Wren's fence posted her at the Two Roads for forty
  crowns, for telling you the truth. You paid it, and she wrote it down.
- **Forty Crowns** (hers): Wren's fence posted her at the Two Roads for forty
  crowns, for telling you the truth. She took her own tag off the nail and left
  a copper for it.

**People** (one line each; Krell's and Dask's replace their Prologue lines):

- Sabine Krell. Ironvault's Huntmaster. Keeps her word to the letter, and minds
  that she may not take your card.
- Dask (W, the hunt). Warned you, and went back with Krell for it. His
  mother's note is called.
- Dask (W, Dask). Warned you, and you staked a duel on him. Says he owes you
  again.
- Dask (L, the deck). Led the hunters to you. You gave him back his deck in
  the river.
- Dask (L, left). Led the hunters to you, and went home with nothing, again.
- Ma Corbie. Keeps the board at the Two Roads. A copper to read, a crown to
  post.

---

## Writers' notes (for Gary and Claude only, never shown in the game)

**Why here, and not after the second kingdom.** Dask's choice is the last
thing the player does in the Prologue; paying it off on the next road, while
they still remember his face, is worth more than paying it off eight hours
later. And Krell acting on Morne's order the week he gives it is what Krell
would do. The cost is two lines in Pyreholt (below).

**What Krell knows and doesn't.** She knows what Morne's ledger says (an
account, open), not why; Interlude B is where that's for. "Then you'll have the
page" is the only threat she makes, and it's the one that matters: Bram's
proof that he paid. The return to Ashford picks it up (he goes down to the
cellar for something with a seal on it, and it's gone).

**The inn.** v7 keeps every house standing ("worth more standing", and from
the hill the inn is still there, a light moving through it). C7 has Krell say
"The inn we burned." Both are true if she burned it after the search, because
it was the one roof that wasn't the House's: worth nothing to them standing,
and something to Bram. Krell says so here.

**Krell's character.** Courteous, precise, never cruel for its own sake. She
keeps every agreement to the letter, including the ones that hurt the people
who served her (L: "I owe you nothing else"). She is Ruadh's (the pantheon's
god of the hunt: fair, fierce, without malice), which is why she lets the
hound follow Dask. "Five Minutes" is her rule because it's what she said on
the green.

**The two ways, side by side.** In W the player was merciful, so they come at
the ambush from behind, Krell has to challenge them, and they set the stakes.
In L the player was cruel, so they're caught in the water, have to fight the
boy they humiliated, and Krell sets the stakes. Mercy buys you the right to
choose; humiliation puts you on someone else's terms. Either way Dask pays: in
W for warning you, in L because your winning means Krell owes him nothing.

**The choices that matter later.**
- W: `ia_stake_bram` (Krell is off Bram's hunt for good; Morne sends someone
  harder to say no to, which is Corin, in Corin's return, though he comes for
  the player's signature, not for Bram; Dask is taken back, his mother's roof
  lost; in Part 2 he's a hunter in the House's grey who won't look at you) or
  `ia_stake_dask` (Krell is still on Bram's trail and is the one who comes for
  him before Interlude B; Dask owes you, and pays it in Part 2: his
  Shieldhound beside you in a Tag Duel, or a warning when it counts).
- L: `ia_dask_deck_back` (in Part 2 Dask has paid his mother's note himself,
  bill by bill: "Paid it. Myself. Not Krell. Not you."; costs the player
  thirty cards now) or `ia_dask_left` (his mother's roof goes to the House;
  he's working a Shardlands crew when you next see him).
- Wren: `ia_wren_tag_paid` (she pays it back at a moment that matters, in
  Stormreach or Part 2: "That's forty. We're square.") or `ia_wren_tag_hers`
  (her fence turns up in person later, which is Wren's own story).
- `ia_asked_bram` or `ia_let_bram_be`: kept for Part 3, when Bram finally
  talks about Kaethis. If the player never pushed, he tells them himself; if
  they asked, they hear it first from a god. Nothing in Part 1 changes.
- Standing: Dask, Wren, Bram, Krell. (Krell with W "Dask" or either L ending:
  she lost cleanly and remembers it; with W "the hunt": she gave her word.)

**Kaethis (Gary's to keep or cut).** The pantheon doc suggests Interlude A as
where the name is first said aloud, by Wren, who's heard it in the Shards. It's
one line; Bram doesn't answer it, and nothing else in the game says it yet.
It ties the faceless hunter in the White Sky to Kaethis as Shardlands rumour,
nothing more. If you'd rather keep the name for Part 3, Wren's line becomes:
"The old crews in the Shards won't go out in a white storm. They say something
walks in it, looking for what fell."

**Wren on the road.** She's there because of her deal in C3 (she knows where
hunters drink; she wants to be near someone they want more than her) and
because her fence posted her for telling the player the truth. With Bram's
price up, the deal still holds: the hunters want him more than her. Her tag is
the side thread: what owing does to someone who's only ever taken. She'd
rather owe a fence than a friend.

**Dun.** Krell's hound of shadow, the one that killed Tam's River Hound. To
dun someone is to press them for a debt; dun is also a grey-brown. Name to
keep or change.

**Teaching.** Only one new memory of Bram (a rival's rule that turns mid-duel).
Nothing else in either duel is new.

**What changes in Pyreholt (v1) if it sits here.**
- PY6: Wren's "Your price is gone" beat has been told already. Proposed in its
  place: **Wren:** "Went to the Slag. Bram's bill's on every board in it."
  **Bram:** "Get some sleep. Both of you." **Wren:** _(Watching him.)_ "Yes,
  Bram."
- The note under "Where it sits" (and the line after the End of Chapter Two
  caption) about Interlude A coming after the second kingdom: cut.

### New things it needs

**People**
- **Ma Corbie**, 60s: a big, broad innkeeper, grey hair scraped back with a
  black feather through it, sleeves rolled, a leather apron, a pencil behind
  one ear, arms like a drover's.
- **Krell's hunters** (three looks, besides the House's bailiffs who exist
  already): a hired card-hunter in patched leathers with a crossbow; an older
  woman in a waxed coat with a card case at each hip; a young man in a grey
  House coat too big for him.
- **Drovers** for the taproom (crowd variants): smocks, oilskins, sheepdogs.
- Dask, Krell, Bram, Wren: as they are (Dask with Gary's crossbow from 5
  November).

**Creatures**
- **Dun**, Krell's hound of shadow: a hound the size of a pony, armoured in
  dark plates, its body black smoke that holds its shape, eyes like coals
  under ash. (In the Reckoning it's a tinted Shieldhound standing in.)
- **Krell's warhorse**: a heavy warhorse fit for her (Gary's Warhorse.glb of
  5 November, if that's who it's for).
- **Dunling**: a lean, half-grown hound of shadow, smoke at its edges.

**Places**
- **The Two Roads**: a long, low coaching inn of grey stone at a crossroads on
  flat plains, a yard of wagons and horse lines, and at the crossing a black
  oak signpost carved into a head with two faces.
- **The Two Roads' taproom**: low beams, a long fire, drovers' tables, and a
  notice board thick with bills under a carved rook.
- **Garrow's Ferry**: a roofless old mill on a river at night, and below it a
  flat timber raft on an iron chain across the water.
- **The Wend Ford**: a wide, shallow, pewter-coloured river on the plains,
  willows and tall reeds on both banks, morning mist, and mid-ford a flat stone
  shelf with an old duelling Circle cut into it, worn almost smooth.
- **Krell's camp**: a hollow under willows, grey canvas tents, horse lines, and
  a field desk with a ledger and a shaded lamp.
- The far bank at night: the wagon on open plain (the wagon set as it is).

**Props**
- Bram's bill: a good ink drawing of Bram, eyepatch and all, "HOLLOWAY, B.
  ALIVE. TEN THOUSAND CROWNS.", and the coin-and-key seal; the torn corner of
  the player's old bill on the nail above.
- Wren's tin tag on a nail, "40. COLLECT." chalked under it.
- The hunters' net: lines of white light rising out of water and closing like
  fingers (an effect, the restraint magic from the Reckoning).
- Wren's scrap of paper: FORTY, and the player's name.

**Cards**

| Card | Element · tier · kind | What it does | Painting subject |
|---|---|---|---|
| **Dun** (Krell's; not won) | Umbral · IV Relic · Totem (Hounds) | One Tribute. 200 HP. Strike: Dun's Bite, 40. Collect (3 Essence): 70. **Arrears:** deals 20 more to a Totem that's already been hit. | A pony-sized hound of black smoke in dark armour plates, eyes like coals under ash, standing over a torn foreclosure note in the mud. |
| **Dunling** (crystallises from Krell's duel) | Umbral · II Glimmer · Totem (Hounds) | 120 HP. Strike: Nip, 20. **Arrears:** 10 more to a Totem that's already been hit. Lesser kin of Dun. | A lean, half-grown hound of shadow, smoke trailing off its legs, crouched in tall reeds by a river at dawn. |
| **The Huntmaster's Net** (Krell's) | Umbral · II Glimmer · Ward | Springs when an enemy Totem attacks: that Totem is Rooted, and can't Shift on its next turn. | Lines of white light rising out of dark water and closing round a running stag like the fingers of a hand. |

**Films (for Player A)**
- **The Wend Ford, (L)**: the wagon in mid-river in the mist; the reeds stand
  up and are people; the net rises out of the water and takes Bram off the
  box; Krell rides out of the willows with Dun and Dask.
- **The Wend Ford, (W)**: the wagon coming down the east bank through the
  willows at dawn with its wheels in sacking; the hunters in the reeds all
  facing away; Krell at her desk, writing, Dask on his knees in light beside
  her.
- **Krell rides away**: up the east bank into the willows, Dun at her
  stirrup, her people wet to the waist behind her (both ways).

**Music** (for AI Music Lab)
1. **the_two_roads** (the inn): Warm but wary folk tavern piece. Low fiddle and
   hurdy-gurdy, a slow bodhrán, the murmur of a crowded room, a lone whistle
   melody that never quite settles. 84 BPM, D Dorian. Mood: a fire, beer, and
   people watching the door. No vocals. Seamless loop. Length 2:15.
2. **the_wend** (the ford, before the duel): Tense, misty ambient. Low string
   drone, slow harp harmonics, a heartbeat on a muffled frame drum, water
   sounds, a distant hunting horn once. 66 BPM, B minor. Mood: something
   waiting in the reeds. No vocals. Seamless loop. Length 2:00.
3. **huntmaster** (Krell's duel): Cold, precise orchestral duel theme.
   Staccato low strings like a clock, a hunting-horn motif in low brass, snare
   rolls, a harpsichord counter-line, building at the halfway point when the
   horns come in full. 120 BPM, C minor. Mood: courteous, patient,
   merciless. No vocals. Seamless loop. Length 3:00.

**Voice**

| Id | Who | Line | Where |
|---|---|---|---|
| morrowen_ia_01 | Morrowen | I have written down a great many hunters. Every one of them was paying something off. | The opening caption |

**For the build** (things the duel doesn't do yet): a story rule that changes
on a set turn (Five Minutes); a rival who starts at half Life and never Guards
(Nothing Left); stakes the player chooses from two (W), shown on the swear
screen as the duel's stakes; a choice that removes thirty named cards from the
collection (L, the deck back), and the deck screen coping if some were in the
player's deck; Krell challenging the player (the first time the player is the
one challenged in a main-story duel).

---

## Questions for Gary

1. **Where it sits.** Here, between Solhaven and the first kingdom, so Dask's
   choice pays off on the next road? Or after the second kingdom, as v1
   Pyreholt's note had it? (Here means PY6's "Your price is gone" changes to
   the lines above.)
2. **The price on Bram, and the inn.** Krell says it out loud: the price is on
   Bram, alive, and the Unsworn is to be let win. And she says she burned the
   inn after the search, because it wasn't the House's. That squares C7 ("The
   inn we burned") with v7 (every house kept standing). Happy with both?
3. **Kaethis.** Keep Wren's line with the name, or keep the name back for Part
   3 and use the other wording in the notes?
4. **The stakes in W.** Krell off Bram's hunt for good, or Dask freed with his
   mother's roof saved: is that the right weight on each side?
5. **Dask's deck in L.** Giving it back costs the player thirty cards. Too
   steep, or right?
6. **Dun.** The name for Krell's hound: keep it?
