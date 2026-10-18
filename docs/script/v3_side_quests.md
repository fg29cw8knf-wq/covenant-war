# Master Script v3: Solhaven's five side stories, and Morrowen's Ledger

A plain copy of the lines Chapter 1's side stories are built from, taken from the
"Side Quests" tab of the **Master Script v3** Claude doc (approved and locked by Gary
on 18 October 2026), with the places in the "Chapter 1" tab where each one starts. The
doc is the master: if they ever differ, the doc wins.

Where it is in the game: `scripts/world/areas/solhaven/solhaven_side.gd` (the five
stories, their people and their wagers) and `side_places.gd` (their places: Ysa's camp,
Anselm's room under the dyers' bridge, the Great Sundial's oldest steps, the barracks
yard, and their marks in the Sun Square); the four wagers' rules in
`scripts/duel/duel_game.gd` (Licensed, Patter, Scrapper, Discipline); the swear screen,
`scripts/ui/swear_screen.gd`; Morrowen's Ledger, `scripts/ui/ledger.gd` with its words in
`scripts/story/ledger_entries.gd`.

## How to read the script

**Speaker:** is a line of dialogue; a note in brackets after a name says when it plays and is never shown. _Italics_ are what we see and what the player does. **The player's choice:** lists what the player can say. `{name}` is the name the player gives. A dialogue box holds two sentences at most.

**Sworn wagers in side stories** are played once, and the story follows the result. The swear screen shows the opponent's duel rule and says "A sworn wager. Win or lose, it stands." with Swear now and Not yet. Closing the app mid-duel always resumes the duel; it never counts as a loss.

## The rule for side quests

**Every side quest is a small story about what someone owes, and it changes something you'll see again.** No fetching, no counting, no "bring me three". A side quest earns its place only if it does at least three of these five things:

**It has a turn.** What you're asked to do is not what the quest is about. The barrel is really about a letter; the con man is really about faith.

**It asks a question with no clean answer.** Both choices cost something, and the better reward never decides the right thing to do.

**It shows the main conflict from the ground.** Gods rationing mercy, Ironvault's paper, a Seat's politics, seen through one person.

**It comes back.** A consequence shows up hours later, without a caption telling you why.

**It gives you someone.** A named person you'll recognise, with a voice of their own.

**How quests reach the player:** through situations, not exclamation marks. You overhear an argument, see a boy follow a man in grey, notice a crowd round a con man. A mark appears over someone's head only once they've spoken to you.

**How duels carry them:** where a quest has a duel, the stakes are sworn, the opponent's deck says who they are, and the wager is played once. Lose, and the story goes the losing way; there's no retry.

**Morrowen's Ledger:** the quest log is written in Morrowen's voice, as the Keeper of the Dead's record of the Age: a sentence or two per quest, in the past tense, plus a People page with one line on everyone you've met ("Hale. Opened a gate he was told to keep shut, and paid for it."). A player coming back after a week reads where they are without anyone in the game repeating the plot.

## Where they start (Chapter 1 tab)

### C1 · The Golden Gate

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

### C6 · Warden Hale, afterwards

**Gate warden (if you opened the gate):** Hale? Stripped of his command this morning, Hierarch's orders. He's in the barracks yard, if you want him. _(This starts Hale's Orders.)_

**Hale (if you let the children in):** Half a day's pay docked for every child. Cheapest thing I've bought in years.

**Hale (if you left the gate shut):** {name}. The people outside the walls. If you ever have the ear of somebody who matters, remember them. I can't.

## Solhaven's five side stories (Side Quests tab)

### The Price of Mercy

_Who: Ysa, the woman from the gate, and her son Tobin, six. When: after the gate, inside the walls if you let her in, in the camp outside if not._

**What it's about:** the Temple of Dawn heals Solmaris's faithful for a copper and everyone else for forty crowns, or an oath. Mercy, rationed by faith.

_Tobin lies on a blanket with a burn fever from the night the sky fell. A Temple healer in white is packing up her bag._

**Temple healer:** Forty crowns, or swear to the Goddess and it's a copper. I don't set the price.

_She leaves. Ysa looks at you._

**Ysa:** You're the Unsworn. You don't kneel to anyone. So tell me. Should I?

**The player's choice:** Swear. Your son comes first. / I'll pay it. (40 crowns) / Don't. I'll find another way. / That's yours to decide, not mine.

**Ysa (swear):** _(She nods slowly.)_ Yes. Course. _(She takes off the little green leaf she wears on a string, and holds it a long time before she puts it in her pocket.)_

**Ysa (yours to decide):** That's what I thought you'd say. _(She looks at Tobin.)_ Then I've decided.

_(Swear, or yours to decide.) Next day Tobin is well and Ysa wears a sun disc. She thanks you, and doesn't look you in the eye._

**Ysa (you pay):** _(She stares at the purse.)_ I can't pay you back.

**Ysa (you pay):** _(beat)_ I'll not forget it.

_(You pay.) The healer comes back, counts the crowns twice, and heals the boy. Ysa keeps her leaf._

**Ysa (another way):** There isn't one. _(beat)_ Is there?

_In the lower town, a woman selling candles tells you there's a man under the dyers' bridge who heals for nothing, and the Sun Guard are looking for him._

_Under the bridge, in a room that smells of lamp oil: Brother Anselm, grey and thin, binding a docker's hand. A shrine in the corner holds one small lantern, and it is barely lit._

**Anselm:** If you're the Guard, I'm nearly done. If you're not, sit down, you're in my light.

**Anselm:** I keep Ilvane. You won't have heard of her. She was the god of people on the road at night. Carters, travellers, the lost. Four hundred years ago she had a shrine in every town.

**Anselm:** Now she has me, and about three hundred people who still say her name. When nobody says it, she's gone.

**Anselm:** So I heal for free, and all I ask is that they say her name once. It keeps her alive another day.

**The player's choice:** That's buying faith. / Will you heal a boy?

**Anselm (buying faith):** Everyone in this city is buying faith. The Temple charges forty crowns for it. I charge one word.

**Anselm (heal a boy):** Bring him. Quickly; the Guard come at dusk.

_Back at the camp, Ysa listens to what Anselm wants, and is quiet for a long moment._

**Ysa:** One name. _(beat)_ The Rootmother won't mind. She's not here.

_At Anselm's, Ysa says the name once, quietly. Then she unties her green leaf and loops it on the handle of the shrine lantern._

**Ysa:** So she knows who's asking.

_As Tobin's fever breaks, a Sun Guard sergeant and two guards come down the steps._

**Sergeant:** Unlicensed healing during the Turning. In the Goddess's own city. You know what that is, Brother.

**Anselm:** A boy who'll live.

**Sergeant:** It's heresy. _(He sees you, and your hand.)_ And you'll be the Unsworn. Step aside.

**The player's choice:** Then we settle it in the Circle. / Pay his fine. (40 crowns)

**DUEL · Under the Bridge** · The Sergeant · The Dawn Watch. _A sworn wager: if you win, he walks away; if you lose, Anselm goes with him. Duel rule: Licensed. The Sergeant's Rites cost nothing while you have more Totems than he does; the Temple's rules favour the Temple._

**Sergeant (if you win):** _(He looks at Anselm, at the boy, at the lamp.)_ I didn't see a shrine. I didn't see a boy. _(He goes back up the steps.)_

**Sergeant (if you lose):** That's the Covenant, Unsworn. _(He takes Anselm by the arm.)_ The boy can stay.

**Sergeant (if you pay):** Forty crowns. _(He weighs the purse.)_ That's what it costs, then. _(He goes.)_

**Anselm (if he's still here):** She's a little brighter. Can you see? _(The lantern on the shrine is, very slightly.)_ You don't owe her anything for it. That's rather the point of her.

**Where it comes back:** in Chapter 14, on the darkest stretch of the Stair of Ages, a small grey god with a travelling lantern is waiting: Ilvane, alive because of one healer in Solhaven. A green leaf on a string hangs from her lantern. She says nothing. She lights your way through the dark and asks nothing for it. If Anselm was taken after the healing, she is there, but her light only reaches halfway, and you duel through the rest. If Ysa swore, or you paid the Temple, nobody said the name; Ilvane isn't there at all, and you duel through the dark.

### The Second Unsworn

_Who: Fen, a Shardlander with a quick tongue and a hand painted white. When: the market square, any time._

**What it's about:** faith is power in Veyl, and people are starting to put theirs in you.

_A crowd round a fountain. A young man stands on the rim with a painted white mark on the back of his hand, touching people's foreheads for a copper each._

**Fen:** Owe nothing! Kneel to nobody! The Unsworn's blessing, a copper a time, and nobody's hand on your collar after!

_He sees your hand. The real mark. The crowd sees it too._

**Fen:** Ah.

**Fen:** _(Brightly, to the crowd.)_ My apprentice!

**The player's choice:** Tell them the truth. / Talk to him first.

**Fen (tell them):** _(As the crowd turns.)_ All right, all right. _(To you, low.)_ Before you finish me off, come and see where the coppers go.

**Fen (talk first):** Thank you. Come and see where the coppers go.

_Behind the fountain, he tips most of the day's takings into the pot of a woman running a soup line for the refugees._

**Fen:** _(He shrugs.)_ Soup's dear.

**Debtor (a man in the soup line):** When he touched my forehead, I felt like nobody owned me. Just for a minute. _(beat)_ I'd pay a copper for that again.

**The player's choice:** Stop, or I'll stop you. / Tell them the truth: owe nobody. Don't sell it. / Carry on.

**Fen (stop):** In the Circle, then. If you win, I wash my hand. If I win, I keep the name.

**DUEL · The Fountain** · Fen · The Painted Hand. _A sworn wager, played once. Duel rule: Patter. Fen's Wards are face up, but once a turn he can swap one for a card in his hand: he talks too much to keep a secret._

**Fen (if you win):** _(He washes the paint off in the fountain.)_ There. Just a hand. _(beat)_ You'll find there are others. There's always others.

**Fen (if he wins):** _(He holds up his white hand to the crowd.)_ The Unsworn's own blessing! Witnessed!

**Fen (tell the truth):** Owe nobody. _(He tries it out.)_ Owe nobody. No copper. _(beat)_ It's a worse business. It's a better sermon.

**Fen (carry on):** Bless you. _(He grins.)_ See? It comes naturally.

**Where it comes back:** by the Closing, people in four kingdoms pray to the Unsworn, whatever you chose. What you chose decides what they pray for. Tell the truth, and in Part 2 debtors tear up Ironvault notes in your name, and Ironvault sends Notaries to enforce them. Let him carry on, or lose to him, and Unsworn blessings are sold in every market in Veyl, and Morne buys the trade. Beat him, and the faith goes underground and turns strange: in Somnara, a cult that believes the Unsworn will end the world. In Part 3 the Faded tell you what it adds up to: worship is power, and you have been collecting it.

### Pip's Errands

_Who: Pip, eleven, and a man in a grey coat. When: after meeting Pip at the fountain._

**What it's about:** a holy city mortgaged to a bank, and a child carrying the paperwork.

_Pip takes a sealed note from a man in grey by the counting-house steps, and runs it up the hill to a side door of the Sun Court. He comes back with another._

**Pip (if you follow him):** You following me? _(He squares up.)_ Two crowns a run. Most I've ever earned. You're not spoiling it.

**Pip:** And I don't open them. Open one and you don't get paid. Everyone knows that.

**The player's choice:** Duel me for one note. / Who's the man in grey?

**Pip (who's the man):** Mr Pell. From the counting house. He's all right. Pays on time.

**Pip (duel):** You're on. _(He pulls a battered deck from his shirt.)_ Bet you didn't think I had one.

**DUEL · The Fountain Steps** · Pip · Street Sparks. _A sworn wager, played once: the note against two crowns. Duel rule: Scrapper. Pip's Totems hit 10 harder while he's behind._

**Pip (if he wins):** Two crowns. _(He holds his hand out.)_ Told you.

_(If you win, or if Wren is with you and you ask her, she lifts one in the crowd.)_ The note, on screen: To His Grace the Hierarch. Ironvault acknowledges a further three thousand crowns drawn against the Temple roofs, for the Bread of Dawn. Interest as before. With respect, Ironvault.

**Wren (if she's with you):** The Bread of Dawn. That's the loaf they give out at dawn prayers.

**Pip:** _(Reading over your arm, slowly.)_ What's that mean?

**The player's choice:** Give it back to Pip. / Keep it. / Take it to Aldric.

**Pip (give it back):** _(He snatches it, checks the seal, and runs.)_ Thanks. Don't follow me again.

**Pip (keep it, or take it to Aldric):** That's two crowns! And Mr Pell'll know! _(He runs, not up the hill but away.)_

**Aldric (take it to Aldric):** _(He reads it twice.)_ The Bread of Dawn feeds three thousand people a morning. His Grace would never put the Temple in that man's debt. _(He folds it and keeps it.)_ I'll ask him.

**And Pip:** whatever you did with the note, you can ask someone to take Pip on. Hale (if he still has a post) needs a runner; Aldric's stable needs a boy; Tamsin needs someone who can count.

**Pip (if you find him a place):** _(Suspicious.)_ What's the pay? _(beat)_ ...Does Ser Aldric go past the stables?

**Where it comes back:** if you took the note (by winning the duel or through Wren) and didn't find Pip a place, Mr Pell's men find him: you meet him in Part 2 with a broken wrist, and he won't take your help. If Pip won and the note went up the hill unopened, Pell leaves him be; in Part 2 he's still running notes ("Three crowns a run now. Told you."), and you can still find him a place then. If you found him a place, he carries Aldric's shield in the epilogue. The note itself: given to Aldric, he remembers it in Chapter 10 and the Hierarch can't pretend he didn't know; kept, you can lay it on Morne's desk at Interlude B ("Yes. I know. His Grace is a very good customer."); given back, it's simply delivered.

### The Sundial's Scar

_Who: Old Maren, and Father Corvin of the Temple. When: after Maren's talk on the steps; at dawn._

**What it's about:** the first proof that the sun goddess cheated, and what it costs the person who kept it.

_Dawn at the Great Sundial. Under the oldest steps, where the stone is worn smooth, the hour lines have been cut twice: the old lines filled with lead and painted gold, new lines cut nine days' shadow along._

**Narration:** Somebody filled in the old lines very carefully, a very long time ago. In this light, you can still see where.

_A priest in white comes down the steps, smiling._

**Father Corvin:** Up early for a pilgrim. The Sundial's beautiful at dawn, isn't it? People come from all over.

**Father Corvin:** Old Maren sent you, I expect. She's had a hard life. It would be such a shame to make it harder.

**The player's choice:** I saw nothing. / Somebody recut these lines.

**Father Corvin (nothing):** Good. _(He blesses you, and you let him, or you don't.)_

**Father Corvin (recut):** Two thousand years of pilgrims' feet. Stone wears. _(He keeps smiling.)_ Go and tell Maren that.

_Back on the temple steps._

**Maren (if you told Corvin you saw nothing):** He came, didn't he. Smiling. _(beat)_ Well. You've got sense. More than I had.

**Maren (if you told Corvin what you saw):** He came, didn't he. And you said it to his face. _(She looks at you a long while.)_ Wait there.

_She goes inside and comes back with a bread tin. Inside, wrapped in oilcloth, are forty pages in a neat Temple hand._

**Maren:** The old readings. I copied them the week before they threw me out. Thirty years they've been in my bread tin.

**Maren:** I'm too old to be brave on my own. Take them, and send for me when it's time.

**Where it comes back:** in Chapter 10, when the Hierarch calls the Ledger of Shadows Glyphmere's forgery, Maren stands up in the Sun Court with her forty pages, in his own Temple's hand: "Nine days, Your Grace. I've waited thirty years to say it in this room." Without her pages the Hierarch makes the charge stick, and Aldric needs a second duel to be persuaded. Either way, Father Corvin's people find out what she kept; she is turned out of her room, and Tamsin takes her in.

### Hale's Orders

_Who: Warden Hale and the Captain of the Sun Guard. When: only if you made Hale open the gate for everyone._

**What it's about:** someone paying for your good deed, and whether you let them.

_The barracks yard. Hale stands without his white and gold, in a plain shirt, by the whipping post. The Captain reads from a paper._

**Captain:** Ten lashes, for opening the Goddess's gate against the Hierarch's order. At noon.

**Hale:** _(Seeing you.)_ Don't.

**Hale:** I opened it. Nobody made me. It's mine to pay.

**The player's choice:** Then I'll stand with you. / I'll duel for his sentence.

**Hale (stand with me):** _(A breath.)_ Suit yourself.

_Noon. You stand at the front of the watching guards. Hale looks at you once, before. Full: the lash, ten times; the camera stays on Hale's face, then yours. Reduced: the camera stays on the guards' faces, and you hear it._

**Hale (afterwards, as they cut him down):** You stood there. _(beat)_ Most don't.

**Captain (I'll duel):** A sworn duel over a Sun Guard sentence? _(She looks at Hale, then at the crowd gathering at the gate.)_ If you win, it's his rank and no lash. If you lose, he takes twenty. Still want it?

**The player's choice:** Yes. / No. _(If no, you stand with him, as above.)_

**DUEL · The Barracks Yard** · The Captain · The Sun Guard. _A sworn wager, played once. Duel rule: Discipline. The Captain's Totems can't be Burned, Poisoned or Frozen. She plays by the book because the book is all she has._

**Hale (if you win):** _(Pulling his shirt back on, furious.)_ You don't let a man pay his own way, do you.

**Hale:** _(beat)_ Thank you.

**Hale (if you lose):** _(Before they take him to the post.)_ Twenty, then. _(beat)_ Stand where I can see you.

**Where it comes back:** in Part 2, when Solmaris's Sun Guard close Solhaven's gate against your allies' banners, Hale opens it again, against orders, with one line that depends on what you did here. Stood with him: "Ten lashes. I've had worse for less." Won his sentence: "This time I'm paying for it myself, and you can watch." Lost: "Twenty. Still think it was worth it. Don't make me wrong."

## Not in v3: what the game adds, for Gary to read

v3 writes every spoken line of the five stories, and the form of Morrowen's Ledger with
one example line. These are the game's own words around them, kept short and in the
same voices. Change any of them and the game follows.

### Choices the game adds

- **Pip's Errands:** after "Who's the man in grey?", the choice comes back with **Not now** (so you can walk away without duelling). With Wren beside you, a third answer: **Ask Wren to lift one.**
- **The Sundial's Scar:** "_He blesses you, and you let him, or you don't._" is a choice: **Let him.** / **Don't.**
- **Pip's place** (after the note, whatever you did with it), told to Pip: **Hale needs a runner.** (only if Hale still has a post) / **Aldric's stable needs a boy.** / **Tamsin needs someone who can count.** / **Not now**. Pip answers with v3's line.
- **Not yet** on the swear screen: for the Sergeant and the Captain the scene waits and asks again ("And you'll be the Unsworn. Step aside." / "Still want it?"); for Fen and Pip you can walk away, and they wait for you (Fen opens with "In the Circle, then...", Pip with "And I don't open them...").

### The wagers, on the swear screen

| Duel | If you win | If you lose |
| --- | --- | --- |
| Under the Bridge · The Sergeant · The Dawn Watch | He walks away. | Anselm goes with him. |
| The Fountain · Fen · The Painted Hand | He washes his hand. | He keeps the name. |
| The Fountain Steps · Pip · Street Sparks | One of his notes. | Two crowns, to Pip. |
| The Barracks Yard · The Captain · The Sun Guard | His rank, and no lash. | He takes twenty. |

### Duel barks (v3 has none for these duels)

Each is said once a duel, when its moment comes ("the rule" is the first time the duel's rule makes a difference on the board).

| Who | When | Line |
| --- | --- | --- |
| The Sergeant | Licensed lets him cast a Rite for nothing | Licensed. Costs me nothing. |
| The Sergeant | You have enough on the board to finish him | Careful, Unsworn. |
| Fen | Patter: he swaps a face-up Ward | Did I say that one? I meant this one. |
| Fen | His Ward springs | Told you it was there. Nobody listens. |
| Pip | Scrapper: he hits harder while he's behind | I'm not done! |
| Pip | One of his Totems is knocked out | That one was rubbish anyway. |
| The Captain | Discipline: one of hers shrugs off a condition | By the book. |
| The Captain | One of her Totems is knocked out | Next. |

### Morrowen's Ledger

Accounts, newest first, under **Still open** and **Settled**; each is a sentence or two in the past tense, and changes as the story does (the full set, with when each shows, is in `scripts/story/ledger_entries.gd`). For example:

- **The Note** (after Ashford burns, if you told Tam the truth): Tam Hayes couldn't read, so you read him Ironvault's letter, and he knew the note fell due that night. When Krell offered him the mill for a word, he lied for you, and came to me.
- **The Price of Mercy** (Anselm kept free): Brother Anselm healed Ysa's son for one word, the name of Ilvane, a god of people on the road at night. You beat the Sun Guard's sergeant for him, and her lantern was a little brighter.
- **Hale's Orders** (you stood with him): Hale took ten lashes at noon for opening the Goddess's gate to everyone. You stood at the front, where he could see you.

People, one line each, with their face and how they stand with you. v3's own line is Hale's ("Hale. Opened a gate he was told to keep shut, and paid for it."); the rest follow it, for example:

- Tam Hayes. Miller of Ashford. Told one lie in his life, to Krell, for you.
- Old Nell. Said Tam's name once, the way she'd call him in for supper.
- My Herald. It says what the Covenant gives it to say, and nothing else.
- Fen. Gives your blessing away now, and calls it a worse business and a better sermon.
- Father Corvin. A priest of the Sun Temple. Smiles the whole time he's warning you.

### Items

- **Maren's forty pages:** The Great Sundial's old readings, copied in a neat Temple hand the week before the Temple threw Old Maren out. Thirty years in her bread tin. She asked you to send for her when it's time.
- **Mr Pell's note** (if you keep it): To His Grace the Hierarch: Ironvault acknowledges a further three thousand crowns drawn against the Temple roofs, for the Bread of Dawn. Interest as before. Pip never got his two crowns for it.
