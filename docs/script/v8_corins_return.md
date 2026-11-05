# The Covenant War · Corin's return, under Ironvault (draft v1, for Gary's yes)

_5 November 2026. Written by Claude for Gary to read before anything is built.
Nothing here is in the game yet. The return to Ashford that follows it is its
own file (`v8_return_to_ashford.md`)._

**How to read it.** As in v7, Pyreholt and Interlude A: **Name:** is a line;
_(italics in brackets)_ are what we see and what the player does; **[GAME]** is
what the game does that isn't a line, and anything it tells the player is in
brackets on screen; **Thought:** is the player's own thought. `{name}` is the
name written in the frost. **Every line waits for a tap.** In a menu, the
questions not yet asked come back after each answer, and one choice moves on.
A line that depends on an earlier choice is marked _(if ...)_.

**Where it sits.** Part 1, after the third kingdom: high summer of the Turning
year. Corin's clerkship began in the spring, so he has been the House's for a
season. A stop on the road at **Gildersgate**, a market town built on a long
stone bridge where three kingdoms' roads meet, with the House's biggest
counting-house outside Ironvault itself. The return to Ashford follows
straight after.

**Under Ironvault: both.** In their colours: a Notary of the House, sworn, in
the grey coat with every iron button in its place. In their debt: a Notary's
bond, twenty years' service or four thousand crowns, which bought his mam's
bakery back clear and paid the Temple's forty crowns for his knee. (The other
way, for Gary: in their debt only, a clerk with no oath and his mind his own.
Question 1.)

**What it leans on.** v7: Corin's clerkship was for his mam's note
(`corin_truth`); the button off his festival coat; the millpond; on the hill,
"maybe I can use it to find out how to make the House answer for this ... I'll
see you in the city", and "Keep that. Sell it, I said. Don't you dare sell
it."; the lore rule (he comes back bound to Ironvault, his mind altered, after
the white card, laying traps); the writers' note (reaching for the card he
calls you Sprout and stops himself; the button can be what does it; the
choice: stop him to protect the Last Seal, or risk everything to bring him
back). Chapter 1: the Temple's forty crowns for anyone who won't kneel; Wren's
"You check that pocket every time someone passes." Pyreholt: Marda's "That
button's one of ours. Ironvault buys our buttons by the barrel, for their
clerks' coats." Interlude A: Krell's "Someone you'll find harder to say no to."

**About "Sprout".** In v7 as built, Corin says it all through the Prologue
("They calculate the interest on the world, Sprout", "You win this year,
Sprout", "Sprout! My leg—", "I'm staying, Sprout"). So the slip isn't the first
time he's used it. It matters because here he calls the player `{name}` and
"Unsworn" and nothing else, the House's way, until the old word comes out of
him with no memory attached, and he has to ask who taught it to him.

| | Scene | What happens |
|---|---|---|
| Evening | CR1 · The letter | A Notary's letter in a perfect clerk's hand, signed by Corin |
| Next day | CR2 · The counting-house | Corin at his desk. What the House did. The page with a space for your name |
| | CR3 · The strongroom | Under the counting-house: one game, Lantern rules. The button. "Sprout." The choice |
| Night | CR4 · The bridge | Afterwards, and the road home to Ashford |

---

## The script

### CR1 · The letter

_(The wagon on the road out of the third kingdom, evening. A rider in the
House's grey overtakes it at a trot, touches his hat, hands Bram a letter
without stopping, and is gone.)_

_(Heavy paper. Grey wax, a coin crossed with a key. The hand is beautiful: a
clerk's copperplate, every letter the same height as the one before.)_

[GAME] The letter, on screen, to read (tap it to close): _To the Unsworn,
travelling with Mr B. Holloway. The House's Notary at Gildersgate asks the
favour of your attendance at the counting-house, at your convenience, on a
matter of business. Safe conduct is given to you and to your party, under this
seal, for the day of your attendance and the day after. Corin of Ashford,
Notary of the House._

**Thought:** _(Corin's letters used to slope downhill and run out of room at the
edge of the page.)_

**Bram:** _(He reads it twice, then turns the seal to the lamp.)_ Safe conduct.
They'll keep it. They keep the letter of everything.

**Wren:** And the spirit of nothing.

**The player's choice:** We're going. / It's a trap.

**Bram (going):** Aye. I thought you'd say that.

**Bram (a trap):** Course it is. It's got his name on it. _(beat)_ We're going
anyway, aren't we.

**Objective:** The counting-house at Gildersgate. (Over the bridge.)

### CR2 · The counting-house

_(Gildersgate: a town that grew on and around a long stone bridge, houses and
shops leaning over the water on both sides of it. At the far end, bigger than
the town hall, the counting-house: grey stone, tall windows, a brass plate by
the door with the coin and the key. Inside, a long hall like a chapel: forty
clerks at forty desks, pens going, nobody looking up. A brass rail across the
far end. Behind it, at a desk of his own, in the grey coat of a Notary of the
House, high collar, every iron button in its place: Corin.)_

_(He stands when he sees them and comes round the desk. He walks without a
limp. His hair is cut short and neat. There's ink on the second finger of his
right hand, where a pen rests.)_

**Corin:** Unsworn. Thank you for coming. _(A nod to Bram, exactly as deep as
it should be.)_ Mr Holloway.

**Bram:** Corin.

**Corin:** _(A nod past them.)_ Miss Wren.

**Wren:** _(Under her breath.)_ Never told him my name.

**Corin:** Sit, please. There's tea. The House pays for the tea.

### Interactive dialogue hub: Corin, Notary of the House

[GAME] (The questions you haven't asked come back. "What's the business,
Corin?" moves on.)

- "Your knee." → **Corin:** Healed. The Temple of Dawn, in Solhaven: forty
  crowns for anyone who won't kneel. → **Corin:** The House paid. It's on my
  account.
- "Your mam." → **Corin:** She has the bakery, deeded, nothing owed. One of
  two roofs in Ashford with nothing owed on them. _(beat)_ You'll know the
  other. → **Corin:** I write on the first of the month. She writes back. I
  keep her letters filed. → **Corin (if corin_truth):** She knows why I went,
  now. I told her. It seemed more accurate.
  - ↳ "How did you pay for it?" → **Corin:** A Notary's bond. Twenty years'
    service, or four thousand crowns, whichever the House calls first. →
    **Bram:** _(Very quietly.)_ Four thousand. → **Corin:** The House set the
    sum. I didn't ask why.
- "Remember the millpond?" → **Corin:** We were eight. I went through the ice
  and you came in after me in your boots, and Bram tanned you for the boots.
  _(beat)_ It's noted.
  - ↳ "Noted?" → **Corin:** I went through every account I had, the week I was
    sworn. _(beat)_ Ours was clear, {name}.
- "What did they do to you?" → **Corin:** Gave me a desk. _(beat)_ And I
  swore, the way every Notary does: in a room with no windows, to a clerk who
  kept very good books. I don't remember her face. → **Corin:** It was quiet.
  Afterwards, everything I owed outside the House was written off. _(beat)_ It's
  called keeping clean books. _(Behind you, Bram's hand closes on the back of a
  chair.)_
- "You said you'd make the House answer for Ashford." → _(He looks at you the
  way he used to look at a card he'd never seen before.)_ **Corin:** Did I.
  _(beat)_ I haven't got that written down.
- "Do you still wish it had come to you?" → **Corin:** I did, under the cart. I
  remember thinking, of course. Of course it's you. → **Corin:** I've done the
  sums since. It's a very bad account.
- "What's the business, Corin?" (moves on)

**Corin:** The House would like to release me from my bond.

_(He lays a page on the desk between the tea things, square to the edge, and
turns it round to face you.)_

**Corin:** If someone else will take it on. Four thousand crowns, on an account
in their name, payable at the Closing.

**Corin:** I'm the offer, {name}. They sent me because you'd come.

[GAME] The page, on screen, to read (tap it to close): _The House of
Ironvault, by its Notary at Gildersgate. The undersigned takes on the bond of
Corin of Ashford, Notary, in full: four thousand crowns, payable at the Closing
of the Turning. On signature the Notary is released. Secured against all that
the undersigned holds. Signed: ______________._

**Bram:** Read the last line, Sprout.

**Thought:** _(Secured against all that the undersigned holds.)_

_(The player's hand goes to the inside pocket before they can stop it.)_

**Wren:** There it goes. The pocket.

**Corin:** That's the card, yes. And everything else. It's a standard clause.

**Corin:** You've never owed anybody anything. The House finds that very hard to
account for.

**The player's choice (a menu; "Still got your Cinderpup?" moves on):**

- "And if I don't sign?" → **Corin:** Then I'm the House's for twenty years, and
  you owe nobody anything. Both entirely in order.
- "You'd let me do this?" → **Corin:** It's a fair page. I wrote it. _(beat)_ I
  don't see what letting has to do with it.
- "Still got your Cinderpup?" → **Corin:** _(A hand on the grey deck box at his
  hip.)_ It's in the deck. It doesn't wake.

**The player's choice:** One game, Corin. Lantern rules.

**Corin:** A friendly settles nothing.

**The player's choice:** Humour me. / It used to.

**Corin (humour me):** _(He looks at you for a long moment.)_ One.

**Corin (it used to):** _(He looks at you for a long moment, as though you've
quoted a clause he can't place.)_ One.

_(He picks up the page and a pen.)_

**Corin:** Downstairs. Notaries settle in the Circle when a page isn't
honoured. There's one under the floor.

### CR3 · The strongroom

_(Stone stairs down, below the street, below the river: you can hear it through
the wall. The strongroom under the counting-house: iron racks from the floor to
the vault of the roof, and on every rack rolled notes tied with grey tape, each
with its tag. Thousands of them; each one a roof, a field, a boat, a mill. A
Notary's desk under a lamp. In the floor, a duelling Circle cut into the
flagstones, a coin crossed with a key cut round its rim.)_

_(On the rack nearest the Circle, a tag in Corin's new, perfect hand: ASHFORD ·
20.)_

_(Bram and Wren stay at the foot of the stairs.)_

**Corin:** Lantern rules. Nothing staked, nothing written.

**DUEL · The Strongroom** · Corin, Notary of the House · The Notary's Hand. _A
friendly: nothing staked, no experience, no card. It can be lost, and the
scene goes on either way._

- _His deck: what the House gave him, Metal and traps: Gilded Sentinel,
  Ironhide Warbeetle, Brassback, Shieldhound, Iron Bastion, Ambush Snare,
  Poison Trap, Hushed Counter, Counterweight, Iron Tithe. And one card the
  House didn't give him: his Cinderpup from the Lantern Duel, grey._
- _Ground and Law: the House's Circle, under the counting-house: Metal Graced,
  and Ironvault's Law, Ledger Law: no Divine Gift can be used (the Unsworn's
  Unbound Will among them)._
- _Duel rule: **The Small Print.** Corin begins with two Wards already set, and
  whenever one springs he sets the next Ward from his deck for nothing. At the
  Lantern he showed the whole green everything he had. Now nothing he does is
  where you can see it._
- _His Cinderpup: the first time he draws it, he calls it at once, by habit. It
  comes in grey, its fire out. At its first chance it attacks whatever's in
  front of it, the way it did at the Lantern, whatever the odds._

**Corin (his first Ward springs):** Page four. Nobody reads page four.

**Corin (he draws the grey Cinderpup and calls it):** _(He looks at the card in
his hand as if it's turned up in the wrong ledger.)_

**Corin (his Cinderpup attacks into a fight it can't win):** _(Very quietly.)_
That's not how I play.

**Corin (his Cinderpup is knocked out):** _(He doesn't look at it.)_

**Corin (you have enough on the board to finish him):** Go on. It's settled either
way.

**Corin (if he wins):** There. Settled. _(He closes his deck box.)_ You'd have
won at the Lantern. I was showing off.

**Corin (when you win):** _(He closes his deck box.)_ Settled. _(beat)_ You
didn't look surprised. You never do.

_(The light goes out of the Circle. Corin doesn't go to the stairs. He stands
at the rim with the page in one hand, and when he speaks again it's lower,
almost the old voice.)_

**Corin:** Or give it to me.

**Corin:** The card. You'd be rid of it: the hunters, the gods, all of it. Give
it to me and I'll carry it. _(He holds out his hand.)_

_(The player's hand goes into their coat. It comes out with what's always in
it, the thing they turn over when they're thinking: the iron button off his
festival coat. They put it in his palm.)_

_(He looks down at it. One of the House's buttons, the same as every one down
his front.)_

**Corin:** Sprout, that's not the—

_(He stops.)_

**Corin:** _(Frowning at it, the way he used to frown at Bram's sums.)_
...Sprout.

**Corin:** Who taught me that?

**The player's choice:** Bram did. Then you did, every day since. / You don't
remember? / (Say nothing.)

**Corin (Bram did):** _(He looks past you, to the foot of the stairs, at Bram.
For a moment he's eight years old and wet through.)_ It was so cold.

**Corin (don't remember):** I remember everything. It's all written down.
_(beat)_ That isn't.

**Corin (nothing):** _(His hand closes on the button.)_ It isn't in anything.
I'd know.

[GAME] The answer is kept: `corin_sprout_bram`, `corin_sprout_ask` or
`corin_sprout_none`.

_(He breathes out. When he looks up he's the Notary again, and the page is
square in his other hand. He holds out the pen.)_

**Corin:** The page, {name}.

_(At the foot of the stairs, Bram doesn't say a word.)_

### The choice

**The player's choice:** (Sign it.) / (Don't sign.)

#### Sign it

_(The pen. Your name, in your own hand, the way you write it in the frost:
{name}.)_

[GAME] (Your name is on the House's page. Ironvault holds a note in your name:
four thousand crowns, payable at the Closing, secured against all you hold.
The House's page is in your Items.)

_(Corin blots it, reads it through once, and signs under your name: the
release. Nothing happens. Then he puts a hand out to the rack beside him, as
if the floor has moved.)_

**Corin:** Oh.

**Corin:** _(Very quietly.)_ Oh, there's... there's a lot of it.

_(He sits down on the rim of the Circle with the button in his fist, and
doesn't say anything for a long time. Then he holds it out to you. His hand is
shaking.)_

**Corin:** Keep that. Sell it, I said. _(beat)_ Don't you dare sell it.

[GAME] (Corin's button is back in your Items.)

_(He stands up and unbuttons the grey coat, every iron button, slowly, and
leaves it folded on the Notary's desk.)_

[GAME] Sets `corin_bond_taken` and `unsworn_owes_house`.

#### Don't sign

_(You put the pen down on the desk.)_

**Corin:** Entirely in order. _(He folds the page into his coat.)_

_(He holds the button out to give it back.)_

**The player's choice:** Keep it. / (Take it back.)

**Corin (keep it):** It's one of ours. It'll have no entry against it. _(beat)_
...I'll keep it.

_(He puts it in his inside pocket, where a card would go.)_

[GAME] (You gave Corin his button.) Sets `button_with_corin`.

_(Take it back.) You take it. His hand stays open a moment after it's empty._

[GAME] Sets `button_kept`.

**Corin:** The safe conduct runs till tomorrow night. Mr Holloway will want to
be off the bridge before then.

**Corin:** Goodbye, Unsworn.

[GAME] Sets `corin_left`.

### CR4 · The bridge

#### If you signed

_(Night on the bridge. Corin walks between the player and Bram in his
shirtsleeves, carrying nothing. Halfway across he stops at the parapet and
looks down at the river for a long time.)_

**Corin:** I wrote to Mam on the first of every month. Every one of those
letters was correct.

**Corin:** Take me home. I don't think I can do the road on my own.

**Bram:** We'll take you home.

**Wren:** _(Later, at the wagon.)_ Four thousand. _(beat)_ I'll start stealing.

**Bram:** _(Later still, not looking up from the lamp.)_ Four thousand crowns,
against everything you hold.

**Bram:** I'd have signed it too. That's what frightens me.

#### If you didn't

_(Night on the bridge. The counting-house windows still lit behind them: forty
desks, forty pens.)_

**Bram:** You did right.

**The player's choice:** Did I? / (Say nothing.)

**Bram (did I):** No. _(beat)_ You did the one that keeps you alive. They're
not always the same thing.

**Bram (if ia_stake_bram):** Krell said they'd send someone harder to say no
to.

**Bram:** We'll go by Ashford. Somebody should see his mam who isn't a letter.

#### Both

**Objective:** Home. (The valley road to Ashford.)

---

## Morrowen's Ledger

- **Corin's Letter** (the Prologue's account, continued; signed): Corin came
  back to you in the House's grey, with clean books and a page with a space for
  your name. You signed it: four thousand crowns, secured against everything
  you hold. He took his coat off.
- **Corin's Letter** (not signed): Corin came back to you in the House's grey,
  with clean books and a page with a space for your name. You didn't sign. He
  called you Sprout once, and asked who had taught him.

**People** (Corin's line replaces his Prologue line):

- Corin (signed). A Notary of the House for one summer. Coming back to himself
  a debt at a time.
- Corin (not signed). Notary of the House. His account with you is clear, he
  says. He checked.

---

## Writers' notes (for Gary and Claude only, never shown in the game)

**Why here.** After the third kingdom, Corin has been the House's for a
season: long enough for it to have taken. The player has had time to miss him
and to have heard nothing. Gildersgate is new and small (a bridge, a street, a
counting-house), so it costs one set, and the counting-house and strongroom
serve again for every kingdom's House and for Interlude B.

**What the House did to him (proposed).** Every Notary swears an oath when
he's taken on, in the strongroom, before a clerk who keeps very good books:
the god the Mornes never name, Sephira the Tally, in the pantheon doc. The
oath is "clean books": every debt the clerk owes outside the House is written
off. Not his memories; their weight. He remembers the millpond the way you'd
remember a figure in a column. That's why he can't be bought by love or
friendship, and why the House trusts its Notaries with everything. Nicknames
and buttons aren't on any ledger, which is how "Sprout" and the button get
through. Sephira isn't named in the scene; Bram's hand on the chair is the
only sign that he knows who keeps those books. The full reveal stays a future
one, as v7's lore rule wants.

**The trap.** Morne doesn't want the card taken. He wants it owed. The Unsworn
is the one person in Veyl who owes nobody anything (v7: "Ironvault has no
receipt for your birth ... a threat to Aurex Morne's bank"), and the pantheon
gives Sephira one want: a god on the Throne who owes her. Corin is the bait
for a signature, and the last line of the page makes the Last Seal security
for it. If the note isn't paid at the Closing, the House has a lawful claim to
the card, witnessed by the Covenant: the one way to take it without a duel or
a death, given freely, in advance. Corin knows exactly what the page does. He
wrote it. "Or give it to me" is the House's first route, which he tries last,
in the old voice; when it fails he goes back to the page. The trap is the
player's love for him.

**Four thousand crowns.** Morne set Corin's bond at the sum Bram paid at the
gate twenty years ago, and which Morne's ledger still shows outstanding. Bram
hears it. Why Morne chose it is Interlude B's to say.

**The duel.** A friendly, Lantern rules, because it's the player who asks for
it and because it's the same two people across a Circle again. The House's
deck, the House's Law, a rule of hidden paper where the Lantern had Showboat.
The grey Cinderpup is the old Corin's rule surfacing once and being put down.

**The choice, and what it sets.**
- **Sign it** (`corin_bond_taken`, `unsworn_owes_house`). Corin is released;
  the debts he'd written off come back all at once. He leaves the coat and
  comes home. The button comes back to the player with the line from the hill.
  The Unsworn owes the House four thousand crowns, payable at the Closing,
  secured against all they hold. Pays off: the return to Ashford (Corin home,
  and the first time he understands what it cost; his Cinderpup wakes for a
  heartbeat); Interlude B (Morne has the Unsworn's signature on his desk: "Yes.
  I know."); Part 2 (Corin, himself again, knows the House's books from inside
  and means to break the note or pay it; the player can pay it from crowns won
  at the Convocation, or not); Part 3 (if it's unpaid at the Closing, the House
  calls it at the Throne and the Pale Herald witnesses its claim on the Last
  Seal). Standing: Corin (high, later), Bram (afraid for you), the House ("has
  your name").
- **Don't sign** (`corin_left`, and `button_with_corin` or `button_kept`). The
  card and the Unsworn's clean name are safe. Corin stays the House's, altered.
  Pays off: the return to Ashford (his mam, and his letters, on time); Part 2
  (Corin is Ironvault's Notary at the Convocation, reading out the stakes the
  referee rules on, across the table from you, precise); Part 3 (with the
  button, he finds it in his pocket one day with no entry against it, and it
  brings him back on his own at the moment it counts: he won't read out a
  claim, or he tears a note; with the button kept, the player can give it to
  him then). Standing: Bram (you did the one that keeps you alive), Corin
  ("Our account's clear").
- **Who taught him "Sprout"**: the answer is kept (`corin_sprout_bram`,
  `corin_sprout_ask`, `corin_sprout_none`) for the first thing he says when
  he's himself again, in either branch.

**Tied to the return to Ashford, only where it helps.** It's why the player
goes home: to take Corin to his mam, or to see her before a letter does. The
ASHFORD · 20 tag in the strongroom is what the player carries into the valley.

### New things it needs

**People**
- **Corin, Notary of the House**: Corin as he is, in a long grey Notary's coat
  with a high collar and a full row of iron buttons, his hair cut short and
  neat, ink on the second finger of his right hand, a single grey deck box at
  his hip, standing straight with no limp.
- **Clerks of the House** (crowd variant): young men and women in grey coats
  at desks, sleeve-guards, pens.
- The House's rider: the bailiff in grey (exists) on a horse.

**Places**
- **Gildersgate**: a market town built along a long stone bridge, tall houses
  and shops leaning over a river on both sides, a grey stone counting-house at
  the far end.
- **The counting-house**: a long stone hall like a chapel, tall windows, forty
  clerks' desks in rows, a brass rail, and a Notary's desk behind it.
- **The strongroom**: a vaulted stone room under the counting-house, iron racks
  floor to roof full of rolled notes tied with grey tape and tagged, a desk
  under a lamp, and a duelling Circle cut into the flagstones with a coin
  crossed with a key round its rim.

**Props**
- The Notary's letter: heavy paper, grey wax with the coin and key, perfect
  copperplate.
- The House's page, with its blank line for a name (and the signed copy in
  Items).
- The tag on the rack: ASHFORD · 20, in the same perfect hand.
- Corin's grey coat, folded on the desk (if signed).
- Corin's button (exists: Gary's corin_button.glb).

**Cards**: none new. Corin's Cinderpup is the game's Cinderpup with its
painting greyed and its fire out (a look, not a card).

**Music** (for AI Music Lab)
1. **the_notary** (the counting-house; Corin's theme, changed): Corin's evening
   melody from the mill-race wall, played slow and exact on a harpsichord over
   a ticking pizzicato, a muted string bed, a clock's tick under it. 72 BPM, G
   minor. Mood: a friend you know, gone neat and cold. No vocals. Seamless
   loop. Length 2:00.
2. **the_strongroom** (the duel): Quiet, tense chamber duel theme. Low cello
   ostinato, plucked harp, a ticking clock, metallic percussion like keys in a
   lock, a solo violin that keeps almost finding Corin's old tune and losing
   it. 108 BPM, D minor. Mood: a game between friends played in a vault. No
   vocals. Seamless loop. Length 2:45.

**For the build:** a friendly story duel (no experience, no card, can be
lost, the scene goes on); a rival who starts with Wards already set and resets
them for free (The Small Print); a scripted call of one card when it's drawn,
with its first attack forced (the grey Cinderpup); a greyed card look; a note
in the player's name, kept with its terms in Items.

---

## Questions for Gary

1. **Under Ironvault: both, or debt only?** As written he's sworn (in their
   colours, the oath that alters him) and bonded (in their debt). The other
   way: no oath, only the debt, his mind his own, and the trap is only the
   page.
2. **The god behind the oath.** It's proposed as Sephira, the Tally, never
   named in the scene. Keep?
3. **The four thousand.** Corin's bond is Bram's sum, set by Morne on purpose.
   Keep that rhyme, or a different sum?
4. **Where.** Gildersgate (new, small, after the third kingdom), or the House's
   counting-house in one of the kingdom cities (Pyreholt already has Notary
   Strand's)?
5. **The choice.** Sign (Corin comes back; the Unsworn owes the House, with
   the Last Seal as security) or don't (the card stays safe; Corin stays the
   House's). Is that the choice you want it to build to? It gives Part 3 a big
   lever: the note at the Throne.
6. **"Sprout".** v7 has Corin saying it all through the Prologue, so the slip
   works here because he's called you `{name}` and "Unsworn" all scene, and
   then has to ask who taught it to him. Happy with that? (The Still to Make
   note said he'd never used it.)
