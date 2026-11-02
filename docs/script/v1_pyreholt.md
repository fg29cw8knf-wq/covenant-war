# Chapter 2 · Pyreholt: The Ember Moot (draft v1, for Gary's yes)

_Written 2 November 2026 by Claude for Gary to read before anything is built. Nothing here is in the game yet, and nothing in the Prologue (v7) or Chapter 1 has been changed to make room for it._

**The kingdom's question:** Is bread worth a war?

**Where it sits.** After Chapter 1. Chapter 1 ends on the map of Veyl, six banners and Bram's "Pyreholt's nearest.", with "Choose a kingdom." Pyreholt is one of the six the player can choose; this script assumes it's the first, and the few lines that would change if it isn't are marked _(if Pyreholt isn't the first kingdom)_. Umbravel is always last. If Pyreholt is the **second** kingdom, Interlude A (The Hunters) begins on the road out, after PY18.

**How long it plays.** About 3 hours on the main path; 4 to 5 hours with the four side stories. Four days in the city. Seven main duels (the first Tag Duel, the first boss duel, and a climax with two different last duels), four side-story wagers, and one duel the player watches.

**How to read it.** As in Chapter 1 (`v3_chapter1.md`): **Speaker:** is a line; a note in brackets after a name says when it plays and is never shown; _italics_ are what we see and what the player does; **The player's choice:** lists what the player can say, and in a menu the questions not yet asked come back after each answer; **Objective:** lines appear on screen; (V) marks a voiced line; **[GAME]** is what the game does that isn't a line, and anything it tells the player is shown in brackets on screen, never in a character's voice. **Thought:** is the player's own thought, shown in brackets and italics. `{name}` is the name the player wrote in the frost. A dialogue box holds two sentences at most, and **every line waits for a tap.**

**Duels.** Every story duel has one rule of its own that says something about the person across the Circle, and every bark is tied to something on the board, once a duel. Anything the player hasn't met before is taught the first time it comes up as **A MEMORY OF BRAM** (his face, his words, what he taught over the years, never a comment on the board), and only if it hasn't been learned already. Losing a main story duel is a retry: the rival's winning line, then Morrowen's line ("No. That isn't how it went." and the others), then Again / Change deck first. Side-story wagers are sworn and played once: "Win or lose, it stands." Winning shakes Resonance loose and it crystallises into a card by its energy; nobody ever takes the loser's card. Damage runs in tens; Life starts at 250 plus 5 for every attribute point.

**What it leans on from before.** The Sun Court's writ (C6: every Seat must take the player's challenge, but the one challenged sets the stakes); the price posted on the player (C3) and Morne moving it (C7), which Pyreholt only hints at so Interlude A can tell it; Corin's button; Bram's four deck boxes (the player chose one; Bram still has the other three, Emberstorm among them unless the player chose it); Old Maren's nine days, if the player heard them; Pyreholt's Law, Forge Heat, and Vexa's, Plague Air, both already in `duel_laws.gd`.

---

## The shape of it

Pyreholt is a forge-fortress in a dead volcano that grows nothing and eats very well. For twelve years Warlord Vorn has fed it by selling its steel to every war in Veyl, and for eleven the Ember Moot, the clans' old tournament, has ended the same way: his champion (for the last seven, his foster son Doran Garr) wins the Brand, the right to challenge the Warlord, and lays it on Vorn's forge. Kaela Ashborn, daughter of the Warlord Vorn beat, comes down off the rim to win it back. The player enters the Moot for the Seal and finds it rigged in a way the duels give away: the Crucible's Circle has been secretly re-cut to Vexa, the Plague Saint, and Vorn has been hers for eleven years. Pyrrhane is too cold even to stop time; his people climb the Bread Stair, not his hill. The player relights his Pyre by taking his Trial, learns that Kaela's father threw his duel so Pyreholt could eat, wins the Moot and holds the Brand. Then the choice: carry it into Vorn's Circle and give the Seat back to Kaela and her god, knowing Pyreholt will go hungry; or lay it on Vorn's forge and stand for him against Kaela, knowing Pyreholt's steel will go on killing people in other kingdoms and Pyrrhane will lose his only Dominion. Either way the Herald unmasks Vorn in front of his city, and either way Kaela, who asked only to be looked in the eye, becomes the truest ally the player will have.

**Scenes, in play order**

| | Scene | What happens |
|---|---|---|
| **Day one** | PY1 · The Ash Road | Across the badlands; the first sight of Pyreholt; the cold Pyre |
| | PY2 · The Cold Waystone | Kaela and the Ashborn exiles. **Duel 1: Kaela** (Open Hand) |
| | PY3 · The Cinder Gate | The city opens: the forges, the Bread Stair, the Slag, Tamsin |
| | PY4 · The Moot Roll | Sarn the Tallyman; why the Moot and not the writ |
| | PY5 · The Warlord's Table | Vorn feeds the city and the player; the war-buyers; his collar and his terms |
| | PY6 · The wagon, night one | Bram on bread; Wren: "Your price is gone." |
| **Day two** | PY7 · The Ember Draw | The black sand. **Duel 2: Dagny Flint** (The Long Purse) |
| | PY8 · Noon | The city between rounds; the side stories open |
| | PY9 · The Semi-Finals | **Duel 3: Ulfar Brenn** (Paid in Full). Kaela loses to Garr on turned ground (watched) |
| | PY10 · The Cold Pyre | Keeper Odra; Pyrrhane in the coals; his quest |
| | PY11 · The Crucible by Night | Under the sand. **Duel 4: the Crucible Watch** (Tag Duel with Kaela). Vexa |
| | PY12 · The Trial by Fire | The coal-walk. **Duel 5: Pyrrhane's Aspect** (boss). The Pyre relit; the Seal, Pyraxis, the Ashborn Drake; Hadric's secret |
| **Day three** | PY13 · The Sand Burns | The marks show through at dawn; Vorn doesn't deny them |
| | PY14 · The Final | **Duel 6: Doran Garr** (Never Behind). The Brand |
| | PY15 · Two Fires | Vorn at his forge, Kaela at the Waystone, Bram and Wren: each makes their case |
| | PY16 · The Brand | The choice: his forge, or his Circle |
| | PY17A · For Kaela | **Duel 7A: Vorn** at the Anvil, under Vexa's Law. Kaela takes the Seat for Pyrrhane |
| | PY17B · For Vorn | **Duel 7B: Kaela** at the Anvil, the player standing for Vorn. Pyreholt becomes Vexa's |
| **Day four** | PY18 · The Road Out | Two departures; Morrowen's account; the map |

**Side stories** (each written in full after the main script): **Untested Steel** (Marda Kell, a smith proving war-Sigils for the siege her own son is defending against), **The Grain Road** (Kaela's cousin Bren means to burn Vorn's steel at the Cinder Steps, and the grain will go with it), **The Ember Urn** (the draw is sold, and the old man selling it feeds the Ashborn's forgotten people with the money), **The Hammer's Doubt** (Garr asks the player for one honest duel, to find out whether any of his seven Moots were his).

---

## The script

### PY1 · The Ash Road

_The map of Veyl. The player taps the red banner with a crown of flame. The wagon moves off the edge of the plains and up into the badlands._

_Film. Black rock in long folds, grey ash lying in the hollows like old snow, threads of steam rising from cracks in the road. Nothing grows: not a weed. Here and there in the ash a half-formed Sigil glints, the way frost starts on a window. The wagon creaks along the Ash Road, Turnip in front with his ear down against the grit, Bram at the reins, the player beside him, Wren on the roof with her hood up._

**Morrowen (V):** Pyreholt has kept its god's fire since before the Covenant was written. For the last twelve years it has fed other fires instead, and they have fed Pyreholt, and nobody asks what they burn.

**Wren:** _(She looks round, properly.)_ What do they eat?

**Bram:** Nothing's grown here since the Age before last. What they can buy.

**Wren:** With what?

**Bram:** _(A nod at the road ahead.)_ With that.

_A string of iron-wheeled wagons comes the other way, climbing out towards the far rim under oilcloth. Each crate is stamped with an anvil, and under the anvil a buyer's seal: a white wolf, a white wolf, a ship, a white wolf. The drivers don't look at the wagon._

**Wren (reading the seals as they pass):** Hrimmark. Hrimmark. Stormreach. _(beat)_ Two wars, one road.

**Bram (if Pyreholt isn't the first kingdom):** Should've come here first. It was nearest.

_The road crests the lip of a vast dead crater, and Bram stops the wagon without being asked._

_Below, built down the inside of the caldera in terraces of black stone, is Pyreholt: a forge-fortress of chimneys and chain-bridges, a hundred furnace-mouths glowing orange through the smoke, the sound of hammers coming up off it like rain on a roof. On the highest crag above it all stands a stone brazier the size of a house. It holds only a dull red glow._

**Narration:** Pyreholt. Every chimney in it is lit except one.

**Bram:** That's the Pyre, up top. Pyrrhane's fire. On a clear night you used to be able to see it from Solhaven.

**Thought:** _(You've never seen it. From Ashford you never saw anything lit at night but the Great Lantern.)_

**The player's choice (a menu: each thing asked comes off the list and the rest come back; "Go on." moves on):** You've been here before. / What do they make? / Why's the big one out? / Go on.

**Bram (been here):** A long time ago. _(He clicks his tongue at Turnip, who ignores him.)_ It was louder.

**Bram (what do they make):** Everything that cuts. Blades, war-Sigils, siege engines, the chains on Ironvault's doors.

**Bram:** Every war in Veyl has a Pyreholt maker's mark on it somewhere, if you turn it over.

**Bram (why's it out):** A god's fire burns on what his people give it. Prayers, mostly.

**Wren:** So nobody's giving.

**Bram:** Somebody's giving something. _(He looks at the hundred lit chimneys.)_ Just not to him.

**Bram (go on):** Down we go. Hand in your pocket and mouth shut till we know who's who.

**Narration:** On the rim, beside the road, there's a camp.

---

### PY2 · The Cold Waystone

_An old standing stone on the crater's lip, taller than two men, carved with flames worn almost smooth: the Cold Waystone. At its foot a duelling Circle has been cut into the bare rock, clean and sharp. Round it, tents of scorched red canvas, a dozen cookfires, children, old people, thin people in good boots. Over the largest tent a banner flies upside down: an open hand in flame, pointing at the ground._

_A woman sits on the Waystone's foot turning a card over and over in her fingers. Mid-twenties; cropped dark-red hair, uneven, as if cut with a knife; an old burn scar along her jaw; a scorched red cloak. Beside her, big as a pony, lies a Warg made of black stone and banked fire, asleep with one eye open._

**Kaela:** You're the Unsworn.

**Kaela:** _(She doesn't get up.)_ The Sun's knight went down on his own roof, they're saying, in front of his whole city. I'd like to see how.

**Bram:** We're passing through.

**Kaela:** Nobody passes through Pyreholt, old man. There's nothing on the other side of it.

**The player's choice (a menu; "So what do you want?" moves on):** Who are you? / Why's your banner upside down? / That's a Warg. / So what do you want?

**Kaela (who):** Kaela. Ashborn. _(She waits, to see if it means anything to you. It doesn't.)_ It used to mean something down there.

**Kaela (banner):** That's how exiles fly it. Hand down, fire down.

**Kaela:** We'll turn it the right way up when we're home.

**Kaela (Warg):** _(The open eye moves to you.)_ Old Smoke. I've had him since I was five.

**Kaela:** A man on the road gave him to me the night my town burned. Gave a five-year-old a Warg. I've never known whether to thank him or hit him.

_Behind you, Bram has gone very still._

**Kaela (what do you want):** The Ember Moot opens at dawn tomorrow. I'm in it.

**Kaela:** If you're after the Seal here, you'll be in it too. So before I find myself across the sand from you, I want to know what you are.

_She stands. The Warg stands with her._

**Kaela:** Here. Now. On honest ground.

**The player's choice:** All right. / What's in it for me?

**Kaela (all right):** Good.

**Kaela (what's in it):** Win, and I'll tell you what the Moot really is, which nobody down there will. Lose, and you'll know not to enter it.

_She steps into the Circle at the Waystone's foot._

**Thought:** _(A crown of flame cut round the rim. Pyrrhane's ground.)_

**DUEL · The Cold Waystone** · Kaela Ashborn · Ashborn Fire. _A test, not a fight: nothing is sworn._

- _Her deck: Fire, Burn and Gamble: Old Smoke (her own Infernal Warg, Tempered three times ✦✦✦) and the Cinderpup and Blazehound before him, Hearth Salamander, Ashen Drake, Emberwisp, Kindled Banner, Wildfire Pact, War Paint, Rite of Ashes._
- _Ground and Law: the Waystone is Pyrrhane's ground (Fire cards Graced). Pyreholt's Law, Forge Heat: Fire cards cost 1 less, every Totem takes 5 at the end of its owner's turn, and Kaela, sworn to Pyrrhane, has his Blessing: her Fire Totems ignore the heat. The stone has no rule of its own._
- _Duel rule: **Open Hand.** Nothing hidden. Neither side can set a Ward or call anything Veiled, and Kaela plays with her hand face up where you can see it. She has never once hidden a card._
- _Her Oath: on her first turn she swears the Unbowed (never fall under half Life)._
- _A MEMORY OF BRAM (the first time the Law acts, if not yet learned):_ "Every kingdom's some god's Dominion, and that god lays a Law over every Circle in it. Learn the Law before you learn the duellist." / "Anyone sworn to that god gets a Blessing on top. Watch whose Totems don't flinch when the Law bites, and you'll know who they kneel to."
- _A MEMORY OF BRAM (when Kaela swears, if not yet learned):_ "A rival can swear an Oath, same as you can. Half of them do it to frighten you." / "So break it for them. A broken Oath costs them thirty Life, and it costs them their nerve, which is worth more."
- _Crystallises (your win): a Fire card by its energy, usually a Tier II (Blazehound); with an Oath of yours kept, often a Tier III (Ashen Drake)._

**Kaela (she swears the Unbowed):** The Unbowed. My father swore it every time he stepped into a Circle.

**Kaela (her Fire Totem shrugs off the heat at the end of her turn):** He's still with me in that much.

**Kaela (the first time you open her hand to read it):** Look all you like. Knowing what's coming never saved anyone.

**Kaela (her Oath breaks, if it does):** _(A long breath out.)_ All right. Now I know what you are.

**Kaela (if she wins):** Go home, Unsworn. Wherever that is.

**Kaela (when you win):** _(She looks at the stone, not at you.)_ That'll do.

_Old Smoke lies down again. Kaela sits back on the Waystone's foot and pats the rock beside her._

**Kaela:** The Moot, then.

**Kaela:** Every year the clans send their best down into the Crucible. Whoever's standing at the end gets the Brand.

**Kaela:** The Brand's the right to walk into the Warlord's Circle and fight him for the Seat, on the clans' terms, not his. It's older than the forges.

**Kaela:** For eleven years the one standing at the end has been his man. The last seven, Doran Garr, the Hammer: Vorn raised him from a boy.

**Kaela:** Garr wins, Garr lays the Brand on Vorn's forge, and the Moot's a fair with drums.

**The player's choice (a menu; "And this year?" moves on):** What did Vorn do to you? / It's the Turning. Why not just challenge him? / And this year?

**Kaela (what did Vorn do):** He beat my father for the Seat, twelve years ago, the winter everyone went hungry. Then he threw the Ashborn out of the city.

**Kaela:** My father died in a tent on this rock two winters after. _(She looks down at the hundred chimneys.)_ Vorn sells Pyrrhane's fire to anyone with a war. Pyreholt eats very well on it. You'll see.

**Kaela (why not challenge):** I could. The Herald would let me. And Vorn would set the stakes, because the one who's challenged always does, and I'd fight on his terms in his hall.

**Kaela:** And if I won, the clans wouldn't follow me to the end of the street. They'll follow the Brand. They've never followed anything else.

**Kaela (this year):** This year there's a Turning, and in a Turning the Moot can't turn anyone away. Not even an Ashborn. Not even you.

**Kaela:** Nobody's carried the Brand into his Circle in eleven years. This year somebody will.

**Kaela:** The Seal comes from the Pyre's Trial. Vorn shut the Pyre the year he took the Seat. _(beat)_ There's an old way up, at night, for an Ashborn and whoever an Ashborn brings. Remember I said so.

**Kaela:** And Unsworn. He'll feed you tonight; he feeds everyone. Eat it. Then come and tell me how it tasted.

_As you walk back to the wagon, Turnip bites Kaela's sleeve. Not hard. She looks at him until he lets go._

_The wagon rolls on down the Ash Road. Bram looks back once, at the Warg. He doesn't say anything for a long time._

**The player's choice:** You knew that Warg. / (Say nothing.)

**Bram (you knew it):** Lots of Cinderpups in the world, Sprout.

**Thought:** _(Nobody said Cinderpup. She called it a Warg.)_

---

### PY3 · The Cinder Gate

_The gate in the crater's rim: two iron doors forty feet high, standing open. A toll-house, a queue of buyers' wagons, guards in blackened scale with an anvil on the breast. The guard at the front sees the mark on the player's hand and waves the wagon past the queue._

**Gate guard:** Unsworn, is it? The Warlord said you'd come. You'll eat at his Table tonight. _(He says it the way you'd say the sun will rise.)_ Everyone does, once.

**Objective:** Put your name on the Moot Roll, at the Crucible. (Then the Warlord's Table, at dusk.)

[GAME] Pyreholt opens: the Lower Forges and their chain-bridges, the Bread Stair, the Slag, the Crucible, the Anvil Hall, and the path to the Pyre (chained). People speak once each as the player passes, and again after each day's events.

**A forge-hand on a chain-bridge:** Hammers stop for the Moot. Three days a year you can hear yourself think. I hate it.

**A woman on the Bread Stair, an iron token in her fist:** Four loaves a token, a token a day. Twelve years he's never once been late.

**An old man on the Bread Stair:** I remember the Hungry Winter. My grandson doesn't. _(He taps the token on the stair rail.)_ That's the Warlord, that is. That's all he is.

**A girl with soot on her hands:** _(She has a white mark painted on one palm. When she sees your real one, she puts her hand behind her back.)_

**A purser in a sea-captain's coat, by a buyer's wagon:** Two hundred anchors and a war-Sigil a sailor. Admiral Vessa doesn't haggle. She just waits till you do.

**The Bread Board** _(a slate at the foot of the Stair):_ BREAD. Four loaves a token. Tokens at the top of the Stair, by the Warlord's grace.

**The Pyre path** _(a chain across it and a painted board):_ THE PYRE IS CLOSED. BY ORDER OF THE WARLORD.

**Thought:** _(A god's own temple, with a chain across the door.)_

**Tamsin** _(her stall, under the Crucible's wall, the same striped awning as in Solhaven):_ You again. _(She doesn't sound sorry.)_ I follow the money, love, and three days a year the money comes to the Moot.

**Tamsin:** Pyreholt war-Sigils, at Pyreholt prices. I sell them to people who sell them to people who use them, and I sleep fine. _(beat)_ Mostly.

[GAME] Tamsin sells caches as in Solhaven, from the pools the story has opened, with Pyreholt's Metal and Fire weighted heavier.

**Wren:** I'm going to the Slag. _(The player looks at her.)_ The black market. They keep it in the slag heaps, which is honest of them.

**Wren:** I'll find you at the wagon tonight. If there's anything posted about us, it'll be posted there.

---

### PY4 · The Moot Roll

_The Crucible's gate: an arch cut through rock, hot air breathing out of it. Under an awning, an old man at a table with a ledger as thick as a doorstep, a long grey moustache, spectacles pushed up on his forehead: Sarn, the Tallyman. Beside him on an iron stand, an iron pot of coals: the Ember Urn. By the gate stands the Clanstone, a slab of black rock with every clan's name cut into it. One name has a deep mark cut through it, a flame turned on its side: ASHBORN._

_A broad woman with a bent nail in her hair is ahead of you in the queue._

**Dagny:** Flint. Dagny. Hethrin's, for my sins. Seventh year.

**Sarn:** _(Writing.)_ Seventh year.

**Dagny:** Somebody's got to feed the Hammer. _(She goes in without looking back.)_

**Sarn:** Name. Clan. God.

**Sarn:** _(He sees your hand, and puts the pen down.)_ No clan. No god. _(He picks it up again and writes.)_ First time for both in this book.

**Sarn:** You'll have the Sun Court's writ, then.

_You show it. He reads it slowly, the gold seal on white silk, and hands it back._

**Sarn:** Then you know you don't need me. You could walk into the Anvil Hall tonight and challenge the Warlord straight. Every Seat has to take you now.

**Bram:** And the one who's challenged sets the stakes.

**Sarn:** _(Looking at Bram for the first time.)_ He does. And he'd set them at whatever you've got in that pocket you keep not touching. He's not a fool.

**Thought:** _(The white card. You don't touch the pocket. You want to.)_

**Sarn:** The Moot sets its own stakes, and they've not changed in four hundred years. Win it, and the Brand walks you into his Circle for the Seat, against your fire in Pyreholt.

**Sarn:** Lose that, and you never stand in a Circle in this city again. That's all. Nobody dies of it.

**The player's choice (a menu; "Put me down." moves on):** What's the Urn for? / Who's favourite? / Put me down.

**Sarn (the Urn):** The Draw. Eight tokens in the coals, eight names, and I draw them out two by two at dawn with my bare hand. _(He holds it up: the palm is one old smooth burn.)_ Forty years. You stop feeling it.

**Sarn (favourite):** The Hammer. He's been favourite seven years. _(beat)_ And he's won seven years. Some people find that restful.

**Sarn (put me down):** You're down. Draw's at dawn. Bring a deck you trust.

**Objective:** The Warlord's Table, in the Anvil Hall, at dusk.

---

### PY5 · The Warlord's Table

_Dusk. The Anvil Hall: a forge-hall the length of a street, its roof lost in smoke, a fire-trench running down the middle. On both sides, long tables, and at them a thousand people: forge-hands, widows, children, clan-folk, old men, all eating the same stew from the same iron bowls. At the far end, at the same tables, on the same bench, sits a big grey man in a leather apron over good red wool, eating. Behind him, set into the stone floor, a duelling Circle of black iron: the Anvil._

**Narration:** Once a week, anyone in Pyreholt can eat at the Warlord's Table. Most weeks, most of Pyreholt does.

_A steward walks the player up the hall. Vorn doesn't stand. He moves along the bench to make room._

**Vorn:** Sit. Eat. Then talk. That's the order things go in, in here.

**Vorn:** _(To Bram, without looking up.)_ You too. And the girl off the roof of your wagon, if she'll come down off it.

**Wren:** _(Already at the next table, a bowl in front of her, half gone.)_ I came down.

_Vorn makes a sound that might be a laugh._

_A bowl of stew in front of the player, a heel of dark bread beside it._

**The player's choice:** Eat. / Don't.

_(Eat.) The player eats, spoon to mouth, and it's good: black beans, smoked mutton, more pepper than Bram ever used._

**Vorn (you eat):** Good.

**Vorn (you don't):** Suit yourself. Somebody will. _(He slides your bowl down the bench, and a boy of about six takes it in both hands.)_

_At the far end of the head table, apart, three people aren't eating: a huge man in white wolf-fur, a narrow woman in a sea-captain's coat, and a thin man in Ironvault grey with a ledger open beside his bowl, writing._

**The player's choice (a menu; "What do you want from me?" moves on):** Who are they? / Kaela says you sell Pyrrhane's fire. / Why feed everyone? / Why is the Pyre chained? / What do you want from me?

**Vorn (who are they):** Customers. _(He points with his spoon.)_ Duke Halvard's quartermaster, from Hrimmark. Admiral Vessa's purser, from Stormreach. And Ironvault, who lends them both the money to buy from me.

**Vorn:** The Duke's besieging his nephew. The Admiral's blockading a pirate. Neither of those is my business; their orders are.

**Ulfar** _(the man in the wolf-fur, overhearing, lifting his cup):_ Spring by midsummer, Warlord. The Duke just needs a few engines to knock on a boy's door first.

**Vorn:** _(Not lifting his.)_ He'll have them.

**Vorn (sell Pyrrhane's fire):** I sell what my forges make to whoever pays for it. The fire doesn't mind. It's fire.

**Vorn:** Her father didn't sell. That winter four hundred people in this city starved. _(He goes on eating.)_ I counted. Somebody had to.

**Vorn (why feed everyone):** Because I remember that winter. _(He looks down the hall.)_ Half the people at these tables were children then. They don't remember it. That's what I'm for.

**Vorn (the Pyre):** The priests up there said a forge that sells to other men's wars is a forge that's lost its god. They said it every morning from the top of the Bread Stair, to the people queuing for my bread.

**Vorn:** I chained the path. They stopped saying it. _(beat)_ The fire went out on its own.

**Vorn (what do you want from me):** Ah. There it is.

**Vorn:** You want my Seal. Every Seal in Veyl, I'm told, and you can't have mine without the Pyre's Trial, and the Pyre's chain is mine.

**Vorn:** So here's my price.

_He puts a heavy black iron collar on the table between the bowls, stamped with an anvil._

**Vorn:** Fight the Moot with that on one of your Totems. The buyers watch the Moot to see what my steel can do. Let them watch it do it in the Unsworn's hand.

**Vorn:** Win, lay the Brand on my forge the way Garr does every year, and I'll walk you up to the Pyre myself and take the chain off. You'll have your Seal by breakfast.

**The player's choice ("And Kaela?" comes off the list once asked; the other two move on):** And Kaela? / I'll think about it. / No.

**Vorn (and Kaela):** Kaela will do what Ashborn do: something brave, in the wrong order.

**Vorn:** I don't hate her. I'd feed her, if she'd sit down. She won't sit down.

**Vorn (think):** Do. Keep the collar while you think. _(He pushes it across.)_ It's a good collar. I made it.

**Vorn (no):** _(A nod, not offended. He pushes the collar across anyway.)_ Keep it. Iron doesn't take sides.

[GAME] NEW SIGIL: Anvil-Forged Collar (a Relic). (Give it to a Totem in a Moot duel and the Buyers' Gallery will notice. The Warlord will remember each time you do.)

**Vorn:** One more thing, since you're eating my stew. Tomorrow at noon the grain comes up the Cinder Steps from the plains, and my steel goes down to pay for it.

**Vorn:** The Ashborn pups have been throwing fire at my wagons. If you're near the Steps, I'd count it a kindness.

_(This starts The Grain Road.)_

_As the player gets up, a young man in smith's leathers comes up the hall with two bowls and sits down on Vorn's other side without being asked: tall, broad, a soft open face, soot to the elbows. Vorn puts a hand on the back of his neck for a moment, the way you would with a son, and goes on eating._

**Vorn:** Garr. The Unsworn.

**Garr:** _(Standing, out of manners.)_ I've heard. _(He sits again.)_ Good luck tomorrow. I mean it.

**Vorn:** _(To Bram, as you go.)_ You've a duellist's hands, old man.

**Bram:** I've an innkeeper's back.

_Vorn looks at Bram a moment longer than he needs to._

**Vorn:** Mm.

_Outside, in the smoke, Wren falls into step._

**Wren:** The man in grey wrote down everything you said. And how long you took to say it.

---

### PY6 · The wagon, night one

_The wagon in a yard under the Cinder Gate. The forges don't stop for the night; the light through the canvas is orange till morning. Turnip asleep standing up. Bram on the tailboard, the iron collar on the boards beside him._

**Bram:** What do you need?

**The player's choice (a menu, as at the wagon in Solhaven; "That's all." leaves):** Rest and save / Change my deck / Is Vorn right? / About the Pyre... / That's all.

**Bram (rest and save):** Get some sleep. I'll keep the lamp lit. _(Game saved.)_

**Bram (change my deck):** Tailboard's yours. _(The deck screen opens.)_

**Bram (is Vorn right):** I fed people for twenty years, Sprout. Never once asked where the barley came from.

**Bram:** _(beat)_ Doesn't mean I shouldn't have.

**Bram (the Pyre):** You'll want his Trial for the Seal. Vorn's offering one door up that hill, and the girl on the rim's offering another.

**Bram:** Two doors to the same fire. Mind which one you're seen walking through.

_(If Pyreholt is the first kingdom.) Wren drops off the wagon roof with a paper bag of roast chestnuts she certainly didn't pay for, and sits on the tailboard's other end._

**Wren:** Went to the Slag.

**Wren:** Your price is gone.

**The player's choice:** Gone? / Good.

**Wren (gone):** Off the board. Ten thousand crowns, on every board from here to the Shards the day we left Solhaven. Tonight, nothing.

**Wren (good):** Not good. Nobody drops ten thousand crowns.

**Wren:** They move it. Somebody at Ironvault's moved it.

_Bram has stopped turning the lamp._

**Wren:** Moved it where, nobody in the Slag knew. Or nobody would say.

**Bram:** Get some sleep. Both of you.

**Wren:** _(Watching him.)_ Yes, Bram.

_(If Pyreholt isn't the first kingdom, Wren only says: "Still nothing on the boards. Whatever they moved it onto, it isn't you.")_

---

**Caption:** The first day of the Moot

### PY7 · The Ember Draw

_Dawn. The Crucible: a small crater inside the city, its walls cut into stands, packed and roaring. Vents in the rock breathe heat. The floor is a Circle under a hand's depth of black sand, raked smooth, so that no mark of its rim can be seen. High on one side, behind glass, the Buyers' Gallery: the wolf-fur, the sea-coat, the grey. Drums._

_Sarn draws the tokens out of the Urn's coals bare-handed, two by two. The crowd answers every pair. Garr and a Flint lad: a roar. Kaela Ashborn and a forge-captain's son: silence from most of the stands, a stamp of boots from the clan seats. Ulfar Brenn and a smith from the Lower Forges: polite applause from the Gallery._

**Sarn:** The Unsworn. And Dagny Flint.

_A laugh goes round the stands. Dagny, on the far side of the sand, doesn't laugh._

**Dagny:** Seven years I've drawn. Six of them, the Hammer, first round. _(She looks up at the Gallery.)_ This year, you. Somebody's come up in the world.

**Bram:** _(At the rope, quietly.)_ Never seen a Circle covered. A Circle's marks are the first thing you look at.

**Wren:** I asked. It's ash from the forges, raked fresh every Moot. "Tradition." _(beat)_ Eleven years old, the tradition.

[GAME] The corner, in every duel in the Crucible: "The Crucible · ground hidden under the sand" (no god). Underneath, the duel's ground is Vexa's (`spec.place_god` "vexa"): Venom cards are Graced, Verdant cards Shunned, and Fire cards nothing at all, though the Law is Pyrrhane's.

**DUEL · Round One** · Dagny Flint · The Ember Purse. _The Moot's first round._

- _Her deck: Earth and Metal, slag and stone, and one old Cinderpup for luck: Pebblit, Burrowmole, Boulderox, Brassback, Shieldhound, Cinderpup, Bulwark, Forge Edge, Iron Bastion._
- _Ground and Law: the Crucible (hidden; truly Vexa's). Forge Heat. The emberforge's own rule: a Ward that springs Burns the Totem it catches. At turn 5 and every 6 after, the Forge Roars: every Totem but a Fire one takes 10, and Fire Totems are Empowered._
- _Duel rule: **The Long Purse.** The Moot pays a first-round loser by how long they last. Whenever Dagny is behind on Life, her Totems that could attack take Guard instead. She's here for the purse, not the Brand, and she knows it._
- _Stakes: Moot law. The winner goes on; the loser goes home with the ember purse._
- _A MEMORY OF BRAM (the first time a sprung Ward Burns, if not yet learned):_ "A Circle has a rule of its own, as well as its god's Law over it. Water in one, stone in another, fire in a forge." / "Read the rim before you read the rival. And count the turns: every so often the Circle itself joins in, and it doesn't take anybody's side."
- _Crystallises: by its energy, usually a Tier II Earth or Metal card (Boulderox)._

**Dagny (her Totems Guard while she's behind):** Not today, love. Today I'm getting paid.

**Dagny (her Cinderpup comes in, and the sand gives it nothing):** _(She frowns at it.)_ Hm. Never does, down here.

**Dagny (the Forge Roars):** There's the old girl.

**Dagny (if she wins):** Well. Somebody tell the Hammer.

**Dagny (when you win):** _(A boy brings her a cloth bundle across the sand. She weighs it.)_ Three loaves and an onion. Same as always.

_Bram is waiting at the rope._

**Bram:** Her Cinderpup should have been Graced. Pyrrhane's city, Pyrrhane's card. It wasn't.

**Wren:** Or it isn't Pyrrhane's ground.

_Bram doesn't answer that._

_Kaela's round is next. She beats the forge-captain's son in five turns, plainly, without a word. Old Smoke takes the field, and at the end of every turn the heat bites everyone's Totems but his._

**Wren:** Her Warg hits softer down here than on the rock.

**Bram:** I saw.

_As the player leaves the rope, Dagny is waiting at the Crucible's gate with her bundle._

**Dagny:** Six Hammers out of eight names, six years running. I'm a smith, not a priest, but I can count. Come and find me before the semis.

_(This starts The Ember Urn.)_

---

### PY8 · Noon

**Caption:** Noon

[GAME] The Moot stops till the third bell. The city's open, and marked: the Cinder Steps (The Grain Road, at noon), Marda's forge in the Lower Forges (Untested Steel), Dagny at the Crucible's gate (The Ember Urn), Tamsin's stall, the wagon. **Objective:** The semi-finals, at the third bell.

**The forge-hand on the chain-bridge:** You beat Dagny. _(He shrugs.)_ Everyone beats Dagny. She's got six kids.

**The woman on the Bread Stair:** The Ashborn girl won her round. My mam says her father let the whole city starve for his god. _(She looks up at the dark Pyre.)_ Fat lot of good it did him.

**Tamsin:** Two hundred crowns went through the Gallery on your first round, love. None of it was mine.

---

### PY9 · The Semi-Finals

_The third bell. The stands fuller than at dawn; people on the walls above them. In the Gallery, the Notary in grey turns a page. The bracket put the Unsworn against Ulfar Brenn, and Kaela against Garr._

_Ulfar comes across the sand in his wolf-fur, enormous, cheerful, a green rootwork brooch at his throat: the Rootmother's sign._

**Ulfar:** No offence, Unsworn. The Duke's paid good money for forty siege-Sigils, and I'd like to see them hit something famous before I sign for them.

**The player's choice (both can be asked):** Paid who? / What are they for?

**Ulfar (paid who):** Pyreholt. Ironvault. _(He shrugs.)_ Same money, different hands.

**Ulfar (what for):** A gate, in Hrimmark. There's a boy behind it who thinks starving's a kind of pride.

**Ulfar:** The Duke will have the north fed by midsummer, once that gate's open. _(He means it.)_

**DUEL · The Semi-Final** · Ulfar Brenn · Bought Steel. _The Moot's second round._

- _His deck: Metal and Verdant: Pyreholt steel on Hrimmark money. Brassback, Shieldhound, Ironhide Warbeetle, Siegebreaker Ram (his new purchase), Mossling, Thornwarden, Deep Roots, Forge Edge, Iron Brace._
- _Ground and Law: the Crucible (hidden; truly Vexa's). His Verdant cards come in Shunned (their blows 10 lighter, everything else 1 dearer), because the Rootmother and the Plague Saint are each other's oldest rival, and he notices. Forge Heat; a sprung Ward Burns; the Forge Roars._
- _Duel rule: **Paid in Full.** Every Metal Totem Ulfar calls arrives with an Iron Brace already given (shielded 20 at the start of each of his turns). He's bought the best, and he's paid for it._
- _Stakes: Moot law. The winner goes to the final._
- _A MEMORY OF BRAM (the first Brace, if Relics aren't yet learned):_ "A Relic's a thing you give a Totem, and it stays given till the Totem falls. Collars, braces, charms: whatever the smith made." / "So don't spend anything on the Relic. Knock out the Totem wearing it and the Relic goes with it. Nobody learns that till it's cost them a duel."
- _Crystallises: by its energy, usually Siegebreaker Ram (a new Tier III Metal Totem)._

**Ulfar (Paid in Full, the first time):** Bought and paid for.

**Ulfar (a Verdant card of his comes in Shunned, the first time):** _(He stares at the sand under his boots.)_ Your ground doesn't like my Rootmother.

**Ulfar (his Siegebreaker Ram is knocked out):** Forty of those. _(He makes a mark in a little book.)_ Thirty-nine.

**Ulfar (if you gave a Totem Vorn's collar, when it first strikes):** _(To the Gallery.)_ There's his steel, look. In the Unsworn's hand.

**Ulfar (if he wins):** Good steel. I'll tell the Duke.

**Ulfar (when you win):** _(He looks up at the Gallery, where the Notary is writing.)_ Put that down as a test.

_At the rope, Wren is chewing a chestnut, slowly._

**Wren:** The Rootmother's cards came in sour. Which god can't stand the Rootmother?

**Bram:** _(Slowly.)_ One. Since the first spring. Rot against growth.

**Wren:** Vexa.

**Bram:** The Plague Saint.

_Bram looks at the black sand for a long time._

_The drums change. The stands come to their feet for Garr. For Kaela, the clan seats stand, and nobody else._

_(Kaela against Garr is shown, not played: a film cut from the duel's own cameras, about two minutes, with the plates and ribbons readable.)_

_Kaela swears the Unbowed on her first turn, as she did on the Waystone. Old Smoke takes the field, and at the end of every turn the heat bites everyone but him._

_Garr plays Metal and Venom, the Warlord's steel: an Ironhide Warbeetle, a Plague Asp. Each time the Asp strikes, a small ribbon flickers over it: GRACED._

**Wren:** Look at his Asp.

**Bram:** I'm looking.

_Kaela fights well. It doesn't matter. Her fire falls a little short every time; his poison lands a little long. On the eighth turn her Life falls under half and her Oath breaks and takes thirty Life with it, and she takes it without a flicker._

_At the end she stands with nothing on the field, and Garr's Asp across the sand from her._

**Kaela:** _(To Garr, clearly.)_ Finish it.

_He does._

_Silence in the clan seats. Everywhere else, the Crucible roars. Up in the Gallery, the Notary turns a page._

_Garr doesn't lift his hands to the crowd. He's looking down at the sand under his own feet._

_Kaela walks out of the Crucible without looking at anyone. As she passes the player at the rope:_

**Kaela:** Don't. Ashborn don't blame the ground.

**Wren:** _(When she's gone.)_ The ground's to blame, though.

**Objective:** Find Kaela. (She was seen going up the Pyre path.)

_(The Hammer's Doubt can start now: after dark, Garr is sitting alone at the Cold Waystone.)_

---

### PY10 · The Cold Pyre

_Dusk. The Pyre path. The chain across it has been unhooked and left hanging. Up on the crag, a roofless temple of black stone round the great brazier; the coals in it are the size of cartwheels and banked to a red that barely lights the walls. A path of coals is laid flat in the stone floor, from the door to the brazier's foot: the coal-walk. An old woman in a scorched leather apron is working a bellows as long as she is, slowly, alone. Kaela kneels at the brazier's foot with her head down._

**Odra:** _(Not stopping the bellows.)_ Twelve years I've worked these. Some nights it's like breathing for someone in their sleep.

**Odra:** You'll be the Unsworn. She said you'd come up. _(A nod at Kaela.)_ She's praying. Let her.

**The player's choice (a menu; "Kaela." moves on):** What is this place? / Why are you still here? / Does he answer? / Kaela.

**Odra (this place):** The Pyre. His own fire, lit before the Covenant was signed, they say, and I've no cause to say different.

**Odra:** An Ashborn used to walk those coals every year and ask him for a fire. That's the Trial. Nine hundred years of it, and then a chain.

**Odra (still here):** Somebody has to work the bellows. If it goes out all the way, it doesn't come back.

**Odra (does he answer):** He used to. _(The bellows sigh.)_ He can't hear much now. A god needs people for that, and they've all gone down the Stair for bread.

**Kaela:** _(Not turning round.)_ I lost.

**The player's choice:** The ground was turned. / You fought well. / (Kneel beside her and say nothing.)

**Kaela (turned):** I know what the ground was. I felt it the first turn. _(beat)_ I'd still have had to win on it.

**Kaela (fought well):** "Fought well" is what you say to people at funerals.

**Kaela (say nothing):** _(A long while.)_ Thank you.

**Kaela:** Twelve years I've come up here and talked to him. Not a word back.

**Kaela:** My father walked those coals nine times. The Keeper says the god won't take an Ashborn's Trial while the Ashborn are exiled. So I wait.

_Odra, at the bellows, looks away._

_The player looks into the coals, and something in the coals looks back._

_Slowly, the embers brighten in a shape: a face as big as the brazier, a heavy brow, a beard of slow coals, and a crown that has burned down to a dull red ring. It doesn't stop time; it hasn't the strength. Kaela goes on praying beside you and Odra goes on working the bellows, and neither of them sees it._

**Narration:** Nobody else can see him. At first, you're not sure you can.

**Pyrrhane:** _(The voice is a long way down, like a furnace heard through a wall.)_ There you are. The cold one.

**Pyrrhane:** Everything near me is warm. Everything but that card in your coat.

**The player's choice (a menu; "What do you want?" moves on):** Are you Pyrrhane? / Why don't you answer her? / What happened to your fire? / Maren says the sun was slowed nine days. _(only if the player heard Old Maren in Solhaven)_ / What do you want?

**Pyrrhane (are you):** What's left of him. _(The embers dim, and come back.)_ Enough to talk. Not enough to stand up.

**Pyrrhane (why don't you answer her):** Because every night she asks me to take the Ashborn back, and she doesn't know what she's asking me to forgive.

**Pyrrhane:** She prays for the wrong thing. I don't answer the wrong thing.

**Pyrrhane (my fire):** A city full of my own people, and not one of them climbs the hill. They climb the Stair.

**Pyrrhane:** And worse. Somebody has cut me out of my own Circle, down in that crater of theirs.

**Pyrrhane:** Something's lying in it like a cuckoo in a nest. I can feel it from up here, and I can't see it.

**Pyrrhane:** Go and look under the sand.

**Pyrrhane (nine days):** _(The coals go very still.)_ I lost the last Turning by nine days.

**Pyrrhane:** I've spent two thousand years wondering where the sun went for them. Tell your old woman I believe her.

**Pyrrhane (what do you want):** Not that card. _(The coals flare.)_ I don't ask for things. I'd fight you for it, the day you have the stomach to stake it.

**Pyrrhane:** Find what's in my Circle. Then come back up here, walk my coals, and fight me for my fire. That's the Trial. It's the only one I've ever had.

**Pyrrhane:** Win it, and you'll have the Seal, and one of my two hearts to carry. And I'll answer the question she's too proud to ask.

_The face sinks back into the coals._

_Kaela gets up off her knees, and looks at the player looking at the brazier._

**Kaela:** _(She sees your face.)_ What is it? What's in there?

**The player's choice:** He spoke to me. / Come to the Crucible with me tonight.

**Kaela (he spoke):** _(She looks at the brazier, then at you, for a long time.)_ What did he say?

_(You tell her: look under the sand.)_

**Kaela:** _(Very quietly.)_ Twelve years. And he tells you.

**Kaela (come with me):** To do what?

_(You tell her: look under the sand.)_

**Kaela (either way):** _(She's already moving.)_ Tonight, then. Bring the thief.

**Objective:** Look under the Crucible's sand, tonight. (Then come back to the Pyre for the Trial.)

---

### PY11 · The Crucible by Night

_Night. The Crucible empty, the stands black, the vents breathing slow. A locked iron grille across the tunnel to the floor. Wren kneels at the lock. Bram stays at the tunnel mouth with the lamp turned down._

**Bram:** I'll watch. I'm too old for sand.

_The lock opens almost before Wren touches it._

**Kaela:** You've done that before.

**Wren:** I've done most things before.

**Objective:** Clear the sand from the rim. (Hold to sweep it back.)

_The player and Kaela sweep the black sand back from the Circle's rim with their hands. Under it, the old rim: Pyrrhane's crown of flame, cut deep, as it is at the Waystone. And over it, newer, cut across Pyrrhane's flames so that every one of them is broken: a serpent coiled round a censer. The cuts are clean and patient. Somebody careful did this, over a great many nights._

**Kaela:** _(Very quietly.)_ That's not ours.

**Wren:** It's Vexa's. The Plague Saint. I've seen it painted on doors in the Shards, the years the cough came through.

**Kaela:** In Pyrrhane's own Circle. Under the sand, where nobody would ever—

_She stops. She's looking at the place on the rim where she stood this afternoon._

**Kaela:** He put me on it. He put me on her ground and called it the Moot.

[GAME] The corner, in a duel in the Crucible from now until dawn: "The Crucible · Vexa's ground".

_A lantern at the far tunnel. Two of the Crucible Watch, in blackened scale with the anvil on the breast, cards already out: one stout, one thin._

**Ashwarden Teague:** Floor's closed, by order. _(He sees Kaela.)_ Ashborn. On the Warlord's sand.

**Ashwarden Pike:** _(He sees what's been uncovered, and then makes himself stop seeing it.)_ Rake it back and go, and we never saw you.

**Kaela:** _(Drawing.)_ No.

**Teague:** Then we saw you.

**DUEL · The Crucible by Night** · Ashwardens Teague and Pike · The Crucible Watch. _A Tag Duel: the player and Kaela against the two of them._

- _Their decks: Metal and Venom, the Watch's issue: Shieldhound, Brassback, Ironhide Warbeetle, Blightrat, Mirewidow, Poison Trap, Iron Bastion._
- _Ground and Law: the Crucible, Vexa's ground and showing it now (Venom Graced; Kaela's Fire nothing). Forge Heat, and Kaela keeps Pyrrhane's Blessing (her Fire Totems ignore the heat). A sprung Ward Burns; the Forge Roars._
- _Tag Duel (new; the rules proposed under New things): the player and Kaela share one side of the Circle, its three Totem slots and two Ward slots, and one Life; each has their own deck, hand and Essence. Turns go the player, Teague, Kaela, Pike. Kaela is played by the computer, and the player can see her hand._
- _Duel rule: **The Bell.** Somebody's ringing for the rest of the Watch. From the Watch's fourth turn, their Totems are Empowered at the start of each of their turns._
- _Stakes: none sworn. Get out with what you've seen._
- _A MEMORY OF BRAM (the first Tag Duel):_ "Two against two, you and a friend on one side of the Circle. You share the ground and you share the Life, so every blow they take is yours as well." / "Don't play your own game beside them; play theirs, and leave them room. The best card you'll ever play in a pair is the one you held back so they could play theirs."
- _Crystallises: by its energy, usually a Tier I or II Venom or Metal card (Mirewidow)._

**Kaela (she calls Old Smoke):** Her sand or not. Up you get, old lad.

**Teague (the first Poison lands on your side):** Breathe it in, Ashborn. It's the Warlord's air.

**Pike (The Bell, the first time):** Hear that? That's six more of us.

**Kaela (the first time one of the Watch's Totems falls to you):** Good. Again.

**Teague (if they win):** Rake it back. And go.

**Pike (when you win):** _(Backing off down the tunnel, to Teague.)_ We didn't see it. _(He means the marks.)_ We never saw it.

_The Watch is gone. The vents sigh. Then the heat goes out of the air, all at once, as if someone has opened a window in winter._

_High in the stands, where nobody sits in the day, someone is sitting: a tall figure in layered grey-green veils like a mourner's, the face hidden but for a calm mouth. A bronze censer on a long chain swings slowly from one pale hand, and the smoke off it is green and thin. Kaela and Wren see her too. At the tunnel mouth, Bram lowers the lamp._

**Vexa:** Go on, look at it. It's good work. It took him a winter of nights.

**Vexa:** You've found my little room in his house. He'd have found it himself, if anyone had prayed to him hard enough to give him eyes.

**The player's choice (a menu; "What do you want?" moves on):** Who are you? / Is Vorn yours? / Why here? / What do you want?

**Vexa (who):** The Plague Saint. People say it as if it were an insult.

**Vexa:** A saint is only someone who stays at the bedside. I always stay.

**Vexa (Vorn):** For eleven years. He came to my shrine in the Mire with four hundred names in his head and asked me who would let him feed the rest.

**Vexa:** Pyrrhane said no. I said yes. _(The censer swings.)_ Which of us would you have knelt to?

**Vexa (why here):** Every war needs a forge, and every forge in this city needed a war. I didn't make that sum. I only stopped pretending it was ugly.

**Vexa:** Wars are long, in my keeping, and long wars are sickly ones, and the sick pray. _(You can hear the smile.)_ I'm a very well-prayed-to god, Unsworn.

**Vexa (what do you want):** Nothing from you. Nothing I'd need to ask for.

**Vexa:** Let the man go on feeding them. That's all. You'll never have to kneel to me, and Pyreholt will never go hungry again.

**Vexa:** And take this, whatever you decide. I like people who look under things.

_She sets something on the stone bench beside her. Then, to Wren, as if they'd met before:_

**Vexa:** Give your mother my love, child.

**Wren:** My mother's dead.

**Vexa:** _(Pleasantly.)_ Is she.

_And she's gone, and the heat comes back into the air. On the bench lies a card: a bronze censer on a chain, its green smoke coiled in the shape of a serpent._

**The player's choice:** Take it. / Leave it.

[GAME] (Take it: NEW SIGIL: Plague Saint's Censer, a Relic. Vexa's Court will remember. Leave it: it's gone by morning, and Vexa's Court will remember that too.)

**Kaela:** _(Looking at the marks, not at the bench.)_ My father lost his Seat to a man sworn to my god. And that man went and swore to hers.

**Kaela:** Up. The Pyre. I want to watch you walk those coals.

_(Later, at the wagon or on the road, the player can ask Wren: "Your mother?" **Wren:** "Gods say things to get a look on your face. Mine's dead. Leave it.")_

---

### PY12 · The Trial by Fire

_The Pyre, near midnight. Odra has the bellows going hard. Word has gone round the way it does: twenty or thirty people have come up the path in the dark, clan-folk, a few forge-hands, Dagny Flint. At the back, apart, a tall young man in smith's leathers: Garr._

**Odra:** You've seen what's in his Circle, then. _(She looks at your face.)_ Aye.

**Odra:** The coals will carry you if you don't stop. Don't stop. At the end he'll be waiting, as much of him as there is.

**Kaela:** _(Beside you, low.)_ My father said the trick's to think about something cold.

**Thought:** _(Snow on the millpond. Corin going through the ice, and you going in after him in your boots.)_

**Objective:** Walk the coals. (Keep moving. If you stop, the heat turns you back to the door.)

_The coals give under the player's boots like crusted snow. The heat comes up through the soles, and then, strangely, it doesn't. At the end of the walk the brazier's dull red lifts and stands up out of the Pyre: a giant of dark iron and living embers, broad as a forge door, a crown on his head that is a dull ring of flame. The Burning Crown, poured into a Totem: a sliver of a god as big as a house._

**Pyrrhane:** _(Nearer now, louder.)_ Look at that. Somebody walked my coals.

**Pyrrhane:** I'm not much tonight. Make me sorry I got up.

**DUEL · The Trial by Fire** · Pyrrhane, the Burning Crown · His Aspect. _A boss duel, and the Pyre's Trial._

- _Ground and Law: the Pyre, Pyrrhane's own ground (Fire Graced). Forge Heat. The Pyre has no rule of its own; the Forge Roars at turn 5 and every 6._
- _A boss: one great Life (about three times the player's), up to three moves a turn, and no Mind condition takes hold._
- _Boss Rule: **The Strongest Rule.** He always strikes the player's strongest Totem (the one with the most HP left) first, and the Totem of the player's that hit him hardest last turn hits him 20 harder this one: he respects it. While the Pyre is cold his fire is banked, and his blows land 20 lighter._
- _At half Life: **The Pyre Wakes.** The banking's gone and his crown flares white. At the start of each of his turns every Totem on both sides is Empowered and Burned. He is enjoying himself._
- _Stakes: the Trial. Win, and the Seal of Pyreholt, his Summon, and the card his Aspect sheds. Lose, and Again._
- _A MEMORY OF BRAM (the first boss):_ "Some things across a Circle aren't duellists at all. A god poured into a Totem, a beast loose from a Sigilfall: one great Life, and more than one blow a turn." / "Don't trade with it, because you'll lose every trade. Read its rule, find the one thing it can't abide, and do that thing every turn until it falls."
- _Crystallises: a card no duel can make (see below)._

**Pyrrhane (the first blow on him of 60 or more):** There. That's a blow.

**Pyrrhane (The Strongest Rule, the first time):** Your best. Always your best. Bring it to me.

**Pyrrhane (The Pyre Wakes):** _(The crown goes white.)_ Oh, I'd forgotten this.

**Pyrrhane (if he wins):** Again. I'll not get up for anyone else tonight.

_When you win: the Aspect kneels all at once, like a wall coming down, and its embers pour up into the brazier. The brazier takes them, and the Pyre catches._

_It goes up white, then gold, then the deep orange of a forge at full heat: a column of fire forty feet high that lights the crag, the city and the badlands out to the rim. Down in Pyreholt, a thousand faces turn up to look. Odra lets go of the bellows. They hang, and the fire doesn't need them._

**Narration:** For the first time in twelve years, they can see the Pyre from the plains.

_In the fire now, whole, stands Pyrrhane: vast and dark and burning, and everyone on the crag can see him. Several of them kneel. Kaela doesn't. Garr, at the back, does._

**Pyrrhane:** _(Like a man who's eaten for the first time in a week.)_ That's the Trial. The Seal's yours.

[GAME] (The Seal of Pyreholt is in your Items.)

**Pyrrhane:** And one of my hearts. I only have two.

[GAME] NEW SIGIL: Pyraxis, Heart of the Pyre (a Summon, Tier VI).

**Pyrrhane (if the player's deck is Emberstorm):** You carry the other one already. Holloway walked my coals forty years ago and went home with it, and never once came back to say thank you.

**Pyrrhane (if not):** The other's in a box in your wagon. Holloway walked my coals forty years ago and went home with it, and never once came back to say thank you.

**Pyrrhane:** Tell him the Burning Crown remembers.

_At the edge of the crowd, Bram has come up the path with the lamp. He hears his name. He doesn't come any closer._

_Something is lying on the coals where the Aspect knelt: a card, glowing, warm. A great drake of soot-black scales with seams of banked fire, and branded on its breast an open hand in flame._

**Kaela:** _(A sound out of her like being hit.)_ That's ours. That's my father's Drake.

**Pyrrhane:** Hadric Ashborn laid it on my coals twelve years ago. It's been cold since.

**Pyrrhane:** It's warm now. _(To the player.)_ It came out of your fight, not hers. It's yours.

[GAME] NEW SIGIL: The Ashborn Drake (a Legend, Tier V). (It won't answer you yet: your Sigil Rank is too low. One day it will.)

**Pyrrhane:** I said I'd answer the question she's too proud to ask.

**The player's choice:** Tell her. / Tell me. Just me.

**Pyrrhane (tell her):** _(To Kaela, in front of all of them.)_ Your father threw his duel, Ashborn.

**Pyrrhane:** He laid that Drake on my coals the night before, and walked onto the Anvil without it. Then he played every card he had left as if he meant to win.

**Pyrrhane:** The Herald saw an honest duel, because every move in it was honest. I saw a man leave his best card at home.

**Pyrrhane:** He wouldn't sell my fire to other men's wars, and he couldn't watch you all starve for it. So he gave the Seat to a man who would.

**Pyrrhane:** I turned my face from his house for it. I'd do it again.

_Nobody on the crag moves. Odra shuts her eyes. At the back, Garr doesn't get up off his knees._

**Kaela:** _(Nothing. Then:)_ No.

**Pyrrhane:** Ask the Keeper who cut the mark through your name on the Clanstone. Ask the Warlord why he let you all believe it was him.

_Kaela turns and looks at Odra. Odra doesn't look away. That's the answer._

**Kaela:** _(Very quietly.)_ He let me hate the wrong man for twelve years.

_She walks back down the coals, out through the crowd, and into the dark._

**Pyrrhane (just me):** _(The fire leans down to the player. Everyone else hears only the Pyre roaring.)_ Her father threw his duel. He laid that Drake on my coals the night before, and fought Vorn for his Seat without it.

**Pyrrhane:** He wouldn't sell my fire, and he couldn't watch them starve. So he gave the Seat to a man who would, and I turned my face from his house.

**Pyrrhane:** Tell her or don't. That's no business of a god's.

[GAME] (If "just me": Kaela doesn't know yet. She looks at the player, at the fire, and back, and asks nothing.)

_The fire stands up straight again. Pyrrhane looks out over his city for a long moment, the way a man looks at a house he's come home to and found the furniture moved._

**Pyrrhane:** Tomorrow they'll see what's in my Circle. All of them.

_On the path down, Bram walks beside the player with the lamp, though there's no need of it now._

**The player's choice:** You took his Trial. / You never said.

**Bram (took his Trial):** I was young. I wanted a big card. _(beat)_ I got one.

**Bram (never said):** Nobody asks an innkeeper where he's been. _(beat)_ Don't start tonight.

---

**Caption:** The last day of the Moot

### PY13 · The Sand Burns

_Dawn. The Pyre burns over the city, and on the path up to it there's a line of people, the first in twelve years. Down in the Crucible someone has raked the sand back over the rim in the night, smooth as ever. It makes no difference. The vents under the floor run hot with the Pyre's fire, and the black sand over the Circle glows from underneath. Through it, bright as writing on a window, the marks show: Pyrrhane's crown of flame, and across it, the serpent and the censer._

_The stands filled before it was light. Nobody is sitting down. The Buyers' Gallery is full, and very quiet._

**Crowd (voices, one after another):** That's Vexa's. / Under the Warlord's own sand. / Eleven years we've watched the Moot on that. / My boy lost on that.

_Sarn stands at the rim with the Ember Urn, the Brand heating in its coals for the final, and looks at the marks for a long time._

_(If Sarn is to confess: see The Ember Urn.) Sarn puts the Urn down on the sand and turns to the stands._

**Sarn (if he confesses):** I've sold the Draw for eleven years. To the buyers, and to the Warlord's steward.

**Sarn (if he confesses):** Kaela Ashborn's semi was bought. So was the Unsworn's first round. So were most of yours. _(The stands go silent.)_ That's all. Somebody else can carry the Brand today.

_Vorn comes down the steps into the Crucible alone, in his apron, as if he'd walked straight from the forge. He goes to the rim and looks at the marks for a long time._

**Vorn:** _(To the whole Crucible. Not loud; it carries.)_ Fetch a mason. Cut it back to Pyrrhane's. Today.

**Vorn:** The final's at noon, and it'll be fought on true ground.

_He turns to go, and passes the player at the rope._

**The player's choice (both can be said):** You did this. / Why not deny it?

**Vorn (you did this):** I did. Eleven years ago, with my own chisel, at night, the first year the buyers came to watch. _(He doesn't lower his voice.)_

**Vorn (deny it):** To who? _(He glances up at the Pyre.)_ Him? The Herald?

**Vorn:** You can't lie to either of those. And I've never wasted breath lying to the rest.

**Vorn:** Come and see me after the final. Whichever way it goes.

_Up in the Gallery, the Notary in grey closes his ledger._

[GAME] (The Hammer's Doubt can still be played until the final. The Ember Urn has closed.)

**The woman on the Bread Stair** _(if the player passes):_ Vexa. In the Crucible. _(She turns the token over in her fingers.)_ He's still never once been late.

---

### PY14 · The Final

_Noon. A mason has cut the serpent and censer back to bare stone; Pyrrhane's crown of flame stands clear and whole on the rim. There's no sand. For the first time in the Moot, the corner reads "The Crucible · Pyrrhane's ground"._

_Garr walks out on his own. There are no drums. He looks up at the Pyre burning over the rim, and then across at the player._

**Garr (if he won at the Waystone):** I know what I am now. Honest ground, honest win. Let's see if it holds in here.

**Garr (if you beat him at the Waystone):** You beat me on honest ground last night. _(He rolls his shoulders.)_ Let's find out if it was the ground.

**Garr (if you never fought him there):** Seven Moots. _(He looks at the bare stone where the marks were.)_ I don't know how many of them were mine.

**Garr:** This one will be.

**Garr (if Pyrrhane told Kaela in front of everyone):** Hadric gave his Seat away so the city would eat. My mother was dead by then. _(beat)_ Nobody tells you which bread was paid for with what.

**The player's choice:** Then fight me properly. / You were good, Garr, on any ground.

**Garr (properly):** I don't know any other way. That's the joke.

**Garr (any ground):** _(He looks at you as if you've handed him something he doesn't know where to put.)_ We'll find out.

**DUEL · The Final** · Doran Garr, the Hammer · The Warlord's Steel. _The Moot's final._

- _His deck: Metal and Venom, the deck Vorn gave him and the buyers come to see: Ironhide Warbeetle and the Ironclad Behemoth it Ascends to, Plague Asp and its Blight Wyrm, Shieldhound, Blightrat, Anvilback Tortoise, Iron Ground (a Terrain Rite), Iron Tithe (a standing Rite), Counterweight, Toxic Mist._
- _Ground and Law: the Crucible, Pyrrhane's ground at last (Fire Graced; his Venom nothing now). Forge Heat. A sprung Ward Burns; the Forge Roars._
- _Duel rule: **Never Behind.** Garr has never once been behind in a Moot. While he's ahead on Life his Totems hit 20 harder; while he's behind, 10 lighter. He doesn't know how to fight from behind, because he's never had to._
- _His Oath: the Swift End, sworn on his first turn (win by his eighth turn). If the player is still standing after it, it breaks._
- _Stakes: the Brand of the Moot._
- _A MEMORY OF BRAM (Iron Ground, if Terrain Rites aren't yet learned):_ "Some Rites don't touch a Totem at all. They change the Circle under you for three turns, rule and all." / "So fight the ground they've made, not the one you started on. And count the three turns: they always forget the third."
- _A MEMORY OF BRAM (Iron Tithe, if standing Rites aren't yet learned):_ "A standing Rite stays out beside the Wards and works every turn, until something takes it away." / "If you can break it, break it first. If you can't, outlast it, and make every card you play while it's there worth what it costs."
- _Crystallises: by its energy, usually Anvilback Tortoise (a new Tier III Metal Totem)._

**Garr (he swears the Swift End):** Eight turns. It's never once taken more.

**Garr (Iron Ground):** Iron. Like home.

**Garr (Never Behind: the first time he falls behind):** _(He looks at his Life as if it belonged to somebody else.)_ Oh.

**Garr (his Oath breaks):** Nine. _(He almost laughs.)_ So that's what nine feels like.

**Garr (if he wins):** _(Not cheering.)_ Mine. That one was mine.

**Garr (when you win):** _(He sits down on the stone, there in the Circle, and looks at his hands.)_

_Sarn, or a Flint lad holding the Urn if Sarn has confessed, carries the Brand across the stone: an iron rod as long as a forearm, its head an open hand in flame, kept hot in the Urn's coals. Moot law says the winner takes it bare-handed. It doesn't burn the player. Up in the stands, people notice that._

**Sarn (or the Flint lad):** The Moot's done. The Brand's the Unsworn's.

[GAME] (The Brand of the Moot is in your Items. With it you can challenge the Warlord in his own Circle, on the Moot's stakes: the Seat, against your fire in Pyreholt.)

_Up in the Gallery, the Stormreach purser is already leaving. Ulfar Brenn stays, his cup untouched, watching the player._

**Garr:** _(Still sitting on the stone.)_ He'll ask you to lay that on his forge. He asked me seven times, and I said yes seven times.

**Garr:** I thought it was the same thing as winning.

---

### PY15 · Two Fires

**Objective:** Talk to the Warlord at his forge, and to Kaela at the Cold Waystone. (The Anvil Hall at dusk, with the Brand.)

[GAME] Both are marked; either order. The wagon is on the way. When the player has spoken to both, the objective becomes: Take the Brand to the Anvil Hall.

#### Vorn, at his forge

_The back of the Anvil Hall: a working forge. Vorn at the anvil in his apron, sleeves rolled, beating out a bar of iron for nothing in particular. He doesn't stop when the player comes in._

**Vorn (if the player wore his collar):** You won, and with my collar on. Good. I'd have hated you to lose in it.

**Vorn (if not):** You won. Not with my collar. _(He turns the bar.)_ I noticed.

**Vorn:** Sit, if you like. I can talk and hit at the same time.

**The player's choice (a menu; "What do you want?" moves on):** You turned the Crucible. / You're Vexa's. / Hadric threw his duel. _(only if the player knows)_ / What happens if I challenge you? / What do you want?

**Vorn (the Crucible):** A challenge in my Circle means the Herald in my Circle. And the Herald says what's true, out loud, in front of everyone.

**Vorn:** Nobody challenges a man who sets his own stakes, so that left the Brand.

**Vorn:** So the Brand came to my forge every year, the buyers watched my steel win, and the Herald stayed away. Eleven years.

**Vorn (Vexa's):** Since the winter after the Hungry one. Pyrrhane wouldn't let me sell. She would.

**Vorn:** I didn't swear to her for love. I swore to her for flour.

**Vorn (Hadric threw):** _(The hammer stops, for the first time.)_ Who told you that?

_(You tell him.)_

**Vorn:** _(He starts again.)_ Then it's true. He'd know.

**Vorn:** I went into that Circle to lose with my head up. By the third turn I knew he'd left his Drake at home, and he knew I knew.

**Vorn:** I let the Ashborn think I'd thrown them out. Better they hate me than know that about him.

**Vorn (if I challenge you):** Then the Herald comes, and says what I am in front of my city, and you fight me in my Circle under her Law, not his.

**Vorn:** And if you win, you'll give my Seat to Kaela, and Kaela will shut my order books. And every one of those faces at my Table will be hungry this winter, so that she can stand up straight.

**Vorn (what do you want):** You know what I want. Lay the Brand on my forge, like Garr did.

**Vorn:** She'll come at me anyway, by the Herald's law, tonight. I'd put money on it. When she does, I'll set the stakes, and I'll name you to stand for me.

**Vorn:** Beat her, and Pyreholt eats. That's all I've ever asked anybody for.

#### Kaela, at the Cold Waystone

_Sunset on the rim. The Ashborn camp is half packed, as if it can't decide. Kaela sits on the Waystone's foot where the player first saw her, Old Smoke's head across her boots._

**Kaela (if Pyrrhane told her in front of everyone):** He threw it. _(She says it as if it were a word in another language.)_ My father. The most honest man I ever knew.

**Kaela (if Pyrrhane told her in front of everyone):** I've spent twelve years being him. Turns out he wasn't.

**Kaela (if she doesn't know):** You won. I watched from the top of the stands. _(beat)_ You fight like someone who was never let.

**The player's choice (a menu; "What do you want?" moves on):** What will you do with the Seat? / They'll go hungry. / There's something about your father. _(only if she doesn't know)_ / Why do you still want him back? _(only once she knows)_ / Your father's Drake. _(only if the player still has it)_ / What do you want?

**Kaela (the Seat):** Take the chain off the Pyre. Shut his order books. Send the buyers home with nothing in their wagons but their own money.

**Kaela:** Then walk my father's coals, if the god will have me.

**Kaela (hungry):** Yes. _(She doesn't look away.)_ We'll be hungry, and we'll be ours.

**Kaela:** The Flints have goats in the north valleys, and there's fish in the crater lakes if you know where. There's harvest work on the plains for strong backs.

**Kaela:** It'll be a bad winter. I'll not let it be the Hungry one.

**Kaela:** And when it's bad, my cousins will want to go down the Cinder Steps and take the plains' grain off the carts, because Pyrrhane says the strong take. _(beat)_ I'll have to stop them. I don't know yet if I can.

**Kaela (if Bren burned the Steps, in The Grain Road):** Bren burned the Steps yesterday. I'd have done it too, at his age. I'd have been wrong too.

**Kaela (something about your father):** _(The player tells her what Pyrrhane said in the fire. She listens to all of it without moving.)_

**Kaela:** _(When it's done.)_ Thank you for not letting me hear that from Vorn.

[GAME] (Kaela knows now.)

**Kaela (why still want him back):** Because he was right. A people that sells its strength to everyone else's wars hasn't any left of its own.

**Kaela:** And because my father wasn't wrong either. _(beat)_ I'm the one who has to live with both.

**Kaela (the Drake):** _(She doesn't ask for it. She looks at the card in your hand and away.)_

**The player's choice:** Give it to her. / Keep it.

**Kaela (given):** _(She takes it in both hands and says nothing for a long time. Old Smoke lifts his head and looks at the card.)_ He's warm. _(beat)_ I never thought I'd hold him again.

[GAME] (The Ashborn Drake leaves your Codex. Kaela will remember.)

**Kaela (kept):** _(A nod.)_ He came out of your fight. That's the law. _(beat)_ Look after him.

**Kaela (what do you want):** Take that Brand into his Circle. Put me where my father stood.

**Kaela:** I won't ask you to lose a fight for me. I'd sooner you threw the Brand in the fire than did that.

**Kaela:** And whatever you do with it, look me in the eye when you've done it.

_She takes a card from her cloak: a raised fist wrapped in burning cloth, the fingers straight._

**Kaela:** Here. Whatever you do. It was my father's.

**Kaela (if she knows):** It's the one thing of his I know he kept.

[GAME] NEW SIGIL: Unbowed (a Rite).

#### Bram and Wren, at the wagon

**Bram:** Your choice, when it comes. Don't let anyone hurry it. Least of all me.

**Bram:** I'll say one thing and then I'll shut up. I've eaten bread paid for with worse than a war, Sprout, and I've buried people who starved with their heads up.

**Bram:** I don't know which I'd choose. I know which one I still dream about. _(He doesn't say which.)_

**Wren:** Bread's bread. I've stolen both kinds.

**Wren:** The kind someone died for tastes exactly the same. That's the trouble with it.

---

### PY16 · The Brand

_Dusk. The Anvil Hall. The long tables have been cleared to the walls, and most of Pyreholt is in the hall standing: forge-hands along the sides, clan-folk by the doors, the buyers in a knot at the back, Garr against a pillar, Dagny with her six children, Odra, who never comes down. At the head of the hall Vorn stands by his forge with the fire up. In front of him, set into the stone, the black iron Circle of the Anvil. Kaela is by the doors with the Ashborn, Old Smoke at her knee._

**Vorn:** Well, Unsworn.

**Narration:** The Brand is warm in your hand. The forge is ten steps to your left. The Anvil is ten steps ahead.

**Thought:** _(Four hundred names in Vorn's head. Forty siege-Sigils on the road to a gate in Hrimmark. A boy at the Table holding your bowl in both hands.)_

**The player's choice:** Lay the Brand on his forge. / Carry it into his Circle.

[GAME] (The game asks once more: "This can't be undone." Yes / Not yet. "Not yet" leaves the player free in the hall: Bram, Wren, Garr and Dagny each have a line, and the choice waits at the Anvil.)

**Garr (not yet):** Seven times I walked to the left. _(beat)_ It's not far.

**Dagny (not yet):** Six kids. _(She doesn't say anything else. She doesn't need to.)_

---

### PY17A · For Kaela: the Anvil

_The player walks ten steps forward and steps onto the iron. The hall breathes in. Vorn looks at the player, then at the forge, then puts his hammer down on the anvil, gently._

**Vorn:** _(Not angry. Tired.)_ All right.

_The temperature drops. There's no sound of arrival. The Pale Herald is simply there beside the Anvil: a towering mass of grey burial cloth and rusted chains, and a hood with nothing in it._

**The Pale Herald (V):** The Seat of Pyreholt is challenged, in the Turning, by the Covenant, under the Brand of the Moot.

**The Pale Herald (V):** The challenger is the Unsworn. The defender is Vorn.

**The Pale Herald (V):** Vorn holds the Seat of Pyreholt for Pyrrhane. Vorn is sworn to Vexa.

_Nobody in the hall makes a sound. Then a forge-hand by the wall spits on the floor, and the woman next to him hits him, and then everybody is talking at once. The Herald waits until they stop._

**The Pale Herald (V):** The Circle is the defender's. The Law is the defender's god's: Plague Air.

**The Pale Herald (V):** The stakes are the Moot's: the Seat, against the challenger's fire in Pyreholt. Begin.

**Vorn:** _(Taking a deck from his apron pocket.)_ Twelve years since I've done this in front of anyone. _(beat)_ Mind the air.

**DUEL · The Anvil** · Warlord Vorn · Every War's Forge. _The Seat contest, witnessed by the Herald._

- _His deck: Metal and Venom, everything Pyreholt sells: The Brazen Hydra (his Legend), the Ironclad Behemoth line, the Blight Wyrm line, Shieldhound, Mirewidow, Venom Mask, Toxic Mist, Siphon Rune, Iron Tithe, Poison Trap, Counterweight._
- _Ground and Law: the Anvil, under Vexa's Law and so on Vexa's ground (Venom Graced, Verdant Shunned). **Plague Air:** Poison deals 15 a turn instead of 10, and Vorn, sworn to Vexa, has her Blessing: his Totems can't be Poisoned. The Anvil has no rule of its own._
- _Duel rule: **Both Sides of the Ledger.** Whenever a Totem is knocked out, on either side, Vorn gains 10 Life. He has made his living from every loss in every war._
- _At half Life he calls the Brazen Hydra with two Tributes (he holds it back till then, and keeps two Totems on the field to pay for it), and the forge behind him breathes green._
- _He swears no Oath._
- _Stakes: the Moot's. (A main story duel: lose, and Again.)_
- _A MEMORY OF BRAM (Venom Mask, if Veiled calls aren't yet learned):_ "A Totem called face down costs a little more and tells your rival nothing. They find out what it is when it bites, or when you let them." / "Hit a veiled Totem and you could be hitting a mouse or a mountain. Sometimes it's worth paying to find out early."
- _Crystallises: a Champion's card, Tier IV: the Brazen Drake (new), lesser kin of his Hydra._

**Vorn (Both Sides of the Ledger, the first time):** Every loss is somebody's living.

**Vorn (when the player swears an Oath):** Oaths are for people who can afford to break them.

**Vorn (the first Poison on the player's side):** Mind the air, I said.

**Vorn (the Brazen Hydra):** _(The forge behind him breathes green.)_ Twelve years of orders went into that. Look at it.

**Vorn (if he wins):** _(Quietly.)_ Go home, Unsworn. Pyreholt's fed.

**Vorn (when you win):** _(He lays his cards face down on the iron, the way a man puts his tools down at the end of a shift.)_

**The Pale Herald (V):** The Seat of Pyreholt passes to the Unsworn. The Unsworn holds no god. Name the holder.

**{name}:** Kaela Ashborn.

_Kaela walks up the hall. The Ashborn follow her. People step out of her way the way they'd step out of the way of a cart._

**The Pale Herald (V):** Kaela Ashborn holds the Seat of Pyreholt, for Pyrrhane. Witnessed.

_The mark burns onto the back of her hand: a crown of flame. She looks at it the way the player once looked at their own. When she looks up, the Herald has gone._

[GAME] (Pyrrhane's Court will remember this. So will Vexa's.)

**Kaela:** _(To the player.)_ You've given me my father's Seat. Ask me for something. Ashborn pay what they owe.

**The player's choice:** Don't shut his books till spring. / Let Vorn stay. / Nothing.

**Kaela (books till spring):** No. _(At once, and without heat.)_ Ask me for something I can give.

_(The choice comes back, without the books.)_

**Kaela (let Vorn stay):** _(She looks at Vorn a long time.)_ He can work a forge. Like anyone.

**Kaela (nothing):** Then I owe you. _(beat)_ I don't like owing.

_Vorn takes off his apron and folds it over his arm._

**Vorn:** The order books are in the strongroom. The grain contract's with the Hesk woman on the plains; she's straight. The Table's on the seventh day.

**Vorn:** Don't stop the Table.

**Kaela:** _(After a moment.)_ I won't stop the Table.

**Kaela (if she knows):** You let me hate you twelve years for something my father did.

**Vorn (if she knows):** It was the one thing I could give him.

**Vorn (if she doesn't know):** _(He looks at Kaela for a long moment, and says nothing.)_

**Vorn (if the player asked her to let him stay):** _(After a moment, he ties the apron back on, and goes and stands by the forge with the other smiths.)_

**Vorn (otherwise):** South road. I'll not come back.

_(Otherwise.) He walks the length of his hall, past a thousand people he has fed, and nobody says anything to him at all. Two or three of them touch his sleeve as he passes. Garr leaves the pillar and walks out after him._

#### That night (A)

_The Pyre, midnight. The chain is gone from the path. Kaela stands at the foot of the coal-walk, the new mark on her hand, and half of Pyreholt on the crag behind her._

**Pyrrhane:** _(From the fire.)_ Ashborn.

**Kaela:** _(Walking the coals, not stopping.)_ I'm not here to ask you for anything.

**Pyrrhane:** _(A sound like a furnace door, which might be a laugh.)_ Good.

_She reaches the brazier, and the fire leans down to her, and doesn't burn her._

_Below, in the Anvil Hall's forge, the order books go into the fire one by one. At the back of the hall the Notary in grey watches them burn, and writes something very short._

**Ulfar Brenn:** _(Watching the books burn, to nobody.)_ The Duke won't like that. _(beat)_ The boy will.

---

### PY17B · For Vorn: the forge

_The player walks ten steps to the left and lays the Brand on the coals of Vorn's forge. The open hand in flame goes white, and softens, and runs. By the doors someone makes a sound like they've been hit. It isn't Kaela. Kaela doesn't make any sound at all._

**Vorn:** _(Quietly, only to the player.)_ Thank you.

**Vorn:** I offered you the Pyre for that, once. You lit it yourself.

**Vorn:** So name something else.

**The player's choice:** Let the Ashborn come home. / Take the chain off the Pyre for good. / Nothing.

**Vorn (Ashborn home):** Done. Whatever happens tonight, their name goes back on the stone.

**Vorn (the Pyre):** Done. It's not mine to chain, now he's lit. I'll not touch that path again.

**Vorn (nothing):** _(He looks at the player properly, for the first time.)_ Nothing. _(beat)_ I've not had that from anyone in twelve years.

_Kaela walks the length of the hall, not fast. She stops at the edge of the Anvil._

**Kaela:** Vorn. I challenge you for the Seat of Pyreholt, in the Turning, by the Covenant.

**Vorn:** I take it.

_The temperature drops. The Pale Herald is simply there beside the Anvil._

**The Pale Herald (V):** The Seat of Pyreholt is challenged, in the Turning, by the Covenant.

**The Pale Herald (V):** The challenger is Kaela Ashborn, sworn to Pyrrhane. The defender is Vorn.

**The Pale Herald (V):** Vorn holds the Seat of Pyreholt for Pyrrhane. Vorn is sworn to Vexa.

_Nobody in the hall makes a sound. Then a forge-hand by the wall spits on the floor, and the woman next to him hits him, and then everybody is talking at once. The Herald waits until they stop._

**The Pale Herald (V):** The Circle is the defender's. The Law is the defender's god's: Plague Air.

**Vorn:** The stakes are mine. If she loses, she leaves Pyreholt and never stands in a Circle here again.

**Vorn (if the player asked for the Ashborn):** Her clan stays, and their name goes back on the stone.

**Vorn:** And I name the Unsworn to stand for me.

**The Pale Herald (V):** The defender names the Unsworn to stand for him. The stakes are set. Begin.

_Kaela steps onto the iron opposite the player._

**Kaela:** Look at me.

_The player does._

**Kaela:** Good. _(She draws.)_ Don't you dare go easy. The Herald would know, and so would I.

**DUEL · The Anvil** · Kaela Ashborn · Ashborn Fire. _The Seat contest, witnessed by the Herald. The player stands for Vorn._

- _Her deck: as on the Waystone, and with The Ashborn Drake in it if the player gave it to her (a harder duel)._
- _Ground and Law: the Anvil, Vexa's ground under Vexa's Law (Kaela's Fire nothing; Venom Graced). **Plague Air:** Poison deals 15 a turn instead of 10. Kaela isn't Vexa's, and the player isn't anybody's: no Blessing on either side._
- _Duel rule: **Open Hand**, as on the Waystone, and this time both ways: nothing hidden on either side. No Wards, no Answers, nothing Veiled, and both hands face up._
- _Her Oaths: the Unbowed on her first turn; if it breaks, the Faithful mid-duel (win with a Fire Totem standing)._
- _Her Favour fills as she attacks; full, Pyrrhane answers her: Pyraxis comes down for her from no card at all, in Vexa's own Circle._
- _Stakes: Vorn's, as he set them._
- _A MEMORY OF BRAM (her Favour fills, if not yet learned):_ "When a sworn duellist's Favour fills, their god can answer: the Gift again, or the god's own Demigod down out of the sky with no card at all." / "Watch the ring round their god's seal on the plate. When it's nearly full, finish it, or be ready for the sky to fall in."
- _Crystallises: by its energy, usually a Tier III Fire card (Ashen Drake)._

**Kaela (she swears the Unbowed):** Same Oath as on the rock. I'll keep it this time.

**Kaela (she swears the Faithful):** With a fire standing, or not at all.

**Kaela (she calls the Ashborn Drake, if she has it):** Up. Up for him.

**Kaela (her Favour fills, and Pyraxis comes down):** _(Looking up, past the roof.)_ There you are.

**Kaela (her Oath breaks, if it does):** _(Through her teeth.)_ Always this Oath.

**Kaela (if she wins):** You stood for him. Remember you lost doing it.

**Kaela (when you win):** _(She stands with nothing on the field, as she stood against Garr.)_ Finish it.

**The Pale Herald (V):** The defender's Seat stands. Vorn holds the Seat of Pyreholt.

**The Pale Herald (V):** Vorn is sworn to Vexa. The Seat is held for its holder's god. Pyreholt is Vexa's Dominion, until the Closing seals it.

_Somewhere above the hall, very high, a long low sound like a furnace door closing. Then the Herald is gone._

[GAME] (Vexa's Court will remember this. So will Pyrrhane's.)

_Kaela gathers up her cards. Old Smoke presses against her leg. She walks over to the player, close, and looks them in the eye, as she said she would._

**Kaela:** You did it in front of me. _(beat)_ In this city that's rarer than rain.

**The player's choice:** I'm sorry. / They'll eat. / (Say nothing.)

**Kaela (sorry):** Don't be sorry. Be right. You've all winter to find out if you were.

**Kaela (they'll eat):** They will. Every one of them. _(She looks down the hall at the faces.)_ And somewhere up north a gate comes down.

**Kaela (nothing):** _(A nod.)_

**Kaela:** I'm leaving Pyreholt tonight. That was the stake.

**Kaela:** Pyrrhane's got no kingdom now. He's got a fire on a hill. _(beat)_ And me.

**Kaela:** You're going round every Seat in Veyl, I'm told. Every one of them's somebody's bread and somebody else's war.

**Kaela:** I'd like to see how you choose the next one. _(She looks at the wagon-yard through the doors.)_ Does your mule bite?

**Bram:** Not hard.

[GAME] Kaela joins the wagon. (Her companion card, Kaela, the Unbowed, is in your Codex. She'll stand beside you in Tag Duels.)

**Vorn:** _(As Kaela goes, quietly.)_ Ashborn.

_She stops, but doesn't turn round._

**Vorn (if she knows):** Your father was a better man than either of us. He just couldn't do sums.

**Vorn (if she doesn't know):** _(He looks at her back for a long moment, and lets her go.)_

#### That night (B)

_The forges, which stopped for the Moot, start again before midnight, every one of them. In the Anvil Hall, Notary Strand lays the order books open on the long table, and the buyers sign them in turn: the white wolf, the ship. Ulfar Brenn signs last: forty more siege-Sigils, sixty chain and an engine, for the spring._

_The smoke over Pyreholt is the same colour it always was, except where the light catches it, where it's very faintly green._

_On the crag, the Pyre._

_(If Vorn kept the path open.) It burns low, the colour of a coal you could still cook on. A few people climb to it. At the bellows, where Odra stood, Garr._

_(If not.) The chain goes back across the path. The Pyre sinks through the night, orange to red to the dull glow it had when the wagon came over the rim. Garr sits at the foot of the chained path with his back against the post._

---

**Caption:** The morning after

### PY18 · The Road Out

#### If Kaela holds the Seat (A)

_Dawn at the Cinder Gate. The Pyre burns over the city and the path to it is full. Buyers' wagons roll out through the gate with nothing under their oilcloth but their own pay-chests. The Bread Board at the foot of the Stair has been wiped and chalked again: BREAD. Two loaves a token. Kaela's hand._

**Bram:** _(Reading it as the wagon passes.)_ Two loaves. It was four.

**Wren:** Forty siege-Sigils short at a gate in Hrimmark. Somebody's gate stays up a bit longer.

**The woman on the Bread Stair:** _(Her token in her fist, her face turned up to the Pyre.)_ Two loaves. _(beat)_ I'd forgotten you could see it from down here.

**Tamsin:** Pyreholt steel's gone dear overnight, love. I'm rich, and nobody's buying.

**Garr (if Vorn left):** _(At a forge by the gate, hammer in hand.)_ I walked him to the edge of the badlands. He told me to come back and make something. _(beat)_ A forge that doesn't sell still has to make something.

**Vorn (if he stayed):** _(At a forge by the gate, in his apron, beating out a ploughshare. He nods at the wagon once, and goes on hitting.)_

_Kaela is at the gate with the new mark on her hand and the Ashborn banner over her, the right way up._

**Kaela:** I'll be hungry this winter. Come back in the spring and see if I'm still standing up straight.

**Kaela:** And when you need a fire, call. I'll come. _(She gives the player a card.)_ Pyreholt can mind itself for an afternoon.

[GAME] NEW SIGIL: Kaela, the Unbowed (a companion card: she'll stand beside you in Tag Duels when you call her).

**Kaela:** _(To Turnip, who is eyeing her sleeve.)_ Don't.

_Turnip doesn't._

**Morrowen (V):** Pyreholt went hungry that winter, with its head up and its fire lit. I wrote down every name that came to me from it: fewer than Vorn would have guessed, and more than Kaela could bear.

#### If Vorn holds the Seat (B)

_Dawn at the Cinder Gate. Every forge in the city roaring. Buyers' wagons roll out under full oilcloth, the white wolf on most of them. The Bread Board has been chalked again in the old hand, with a line added at the bottom: BREAD. Four loaves a token. By the Warlord's grace, and the Saint's._

**Bram:** _(Reading it as the wagon passes.)_ Four loaves.

**Wren:** Ulfar got his engines. _(beat)_ Somebody's gate comes down a bit sooner.

**The woman on the Bread Stair:** _(Her token in her fist.)_ He's never once been late. _(She doesn't look up the hill.)_

**Tamsin:** Business as usual, love. Business as usual is the best kind.

**Vorn:** _(At the gate, in his apron, as the wagon reaches it.)_ Come and eat at my Table, any time you're passing. _(beat)_ Bring her, if she'll sit down.

_Kaela, on the wagon's tailboard with Old Smoke's head in her lap, doesn't look at him. She looks back once, at the Pyre on its crag, for as long as it's in sight._

**Morrowen (V):** Pyreholt ate that winter, every soul of it, and its steel went north and east and did what steel does. I wrote down every name that came to me from those wars. Not one of them was from Pyreholt.

---

**Caption:** End of Chapter Two: The Ember Moot.

_The map of Veyl. Pyreholt's banner is changed: (A) the crown of flame over an open hand, the right way up; (B) a serpent round a censer, on grey-green._

**Objective:** Choose a kingdom. (Tap a banner on the map.)

_(If Pyreholt was the second kingdom, the map waits: Interlude A, The Hunters, begins on the road.)_

---

## Pyreholt's side stories

Each one is a small story about what someone owes, and changes something the player sees again. Each has a sworn wager, played once ("Win or lose, it stands."), with Swear now / Not yet on the swear screen as in Solhaven.

### Untested Steel

_Who: Marda Kell, a blade-smith of the Lower Forges, fifties, iron-grey hair cropped short, a stub of chalk behind her ear. When: from the first afternoon until the final. Where: her forge under a chain-bridge, its doors open on the street._

**What it's about:** the bread a city eats and the war it arms are the same order, and somebody has a son on the other end of it.

_Twenty cards laid out in rows on an anvil and a bench, their crystal still cloudy from the forge: war-Sigils. A clerk's crate beside them, stamped with an anvil and a white wolf. Marda is checking each card against the light, one at a time, and writing on the bench in chalk._

**Marda:** Don't touch them. They're not proved.

**Marda:** _(She looks at the player's hand, then at the button the player is turning over in it: Corin's.)_ That button's one of ours. Ironvault buys our buttons by the barrel, for their clerks' coats.

**Thought:** _(Corin on the green in his new coat, twirling a card. It feels like years ago.)_

**Marda:** You're the Unsworn. I need a duellist nobody in this city can buy.

**Marda:** A war-Sigil's not sold till it's been proved in a Circle. These go north on the third day, behind the Duke's first forty, and the Warlord's prover is the Hammer, and the Hammer's busy winning.

**Marda:** Prove them for me. One duel: my batch against your deck. If they hold, they ship, and my lot eat till spring. If they break, I'd sooner know now than hear it from a duke.

**The player's choice (a menu; "All right." or "Not now." moves on):** Who are they for? / What do I get? / All right. / Not now.

**Marda (who for):** Duke Halvard's siege, in Hrimmark. Him with the white wolf. _(She taps the crate with her chalk.)_

**Marda:** My son's in Hrimmark. Arlo. He went north two winters back to duel in the boy-king's guard. The pay's better than the forge.

**The player's choice (sub):** You're arming the side against your son. / (Say nothing.)

**Marda (arming the other side):** _(She doesn't stop checking cards.)_ I'm feeding his sisters. He'd tell me to. He did tell me to, in his last letter.

**Marda:** _(She chalks a mark on the bench.)_ I don't read his letters twice.

**Marda (what do I get):** Whatever the duel gives you. And my thanks, which is worth more in the Lower Forges than you'd think.

**DUEL · The Proving** · Marda Kell · The Hrimmark Order. _A sworn wager, played once. If her batch holds (you lose), it ships as it is. If it breaks (you win), Marda has a choice to make._

- _Her deck: the order itself, Metal war-Sigils: Brassback, Shieldhound, Ironhide Warbeetle, Siegebreaker Ram, Forge Edge, Jagged Shards._
- _Ground and Law: the proving-Circle cut in her forge floor, Hethrin's ground (the Forgefather, who forges for every side; Metal Graced). Forge Heat._
- _Duel rule: **Proof.** The first blow each of Marda's Totems strikes is rolled on Fate: on a 1 to 5 a flaw shows, and the Totem cracks (it loses half its HP)._
- _Crystallises: by its energy, usually a Tier II Metal card._

**Marda (a flaw shows):** _(She chalks a mark on the bench.)_ There's one.

**Marda (a Totem's first blow holds):** Good steel. _(She doesn't sound glad.)_

**Marda (if she wins, and the batch held):** It holds. _(She packs the cards into the crate, one by one.)_ They'll ship, and my girls eat.

**Marda (if she wins):** Go on, then. You've done me a kindness. It'll not feel like one, to either of us.

**Marda (when you win, and the batch broke):** Three flaws in twenty. _(She looks at the crate a long time.)_ The Duke's clerk tests one in ten. He'd never find them.

**The player's choice:** Reforge them. / Ship them flawed. / That's your choice, not mine.

**Marda (reforge):** Then they're late, and the Warlord docks my tokens a month. _(beat)_ We'll be hungry, and they'll be sound. Arlo would laugh at me.

**Marda (flawed):** _(Quietly.)_ Flawed steel at a gate my son's standing behind. _(She puts the lid on the crate.)_ Nobody'll know but us and the gate.

**Marda (your choice):** It always is, isn't it. _(She makes it. The player doesn't see which.)_

**Where it comes back:** in Hrimmark, on the boy-king's walls, a young duellist with his mother's square jaw: Arlo Kell. Shipped sound, Halvard's engines carry Marda's maker's mark against his gate and he knows it: "Mam's work. Best in Pyreholt." Shipped flawed, three of the Duke's war-Sigils crack on the gate in the first assault, and Arlo turns one of the broken cards over in his hands and laughs until he can't. Reforged, the batch is a month late and the siege starts without it. Left to her, which it was is only found out there. In branch A none of it ships at all: the books are burned, and Marda, at her forge, says: "Twenty proved Sigils and a Warlord who won't sell them. Well. Arlo's safe from my steel, anyway."

### The Grain Road

_Who: Bren Ashborn, seventeen, Kaela's cousin, with her jaw and none of her patience; Mother Hesk, a sunburnt grain-factor from the plains; Notary Strand of Ironvault. When: the second day, at noon. Vorn asks the player at his Table; the first evening, Bren can be heard at the Ashborn camp telling the other young ones what he means to do. Where: the Cinder Steps, the switchback road down the crater's outer cliff to the plains, and the exchange yard cut into the cliff halfway down._

**What it's about:** doing the right thing on other people's behalf before they've agreed to pay for it.

_The exchange yard: a ledge in the cliff, wind coming up off the plains. Wagons up from the plains, piled with grain sacks; wagons down from Pyreholt, under oilcloth. A woman in a broad straw hat with a whip at her belt and a ledger under her arm is arguing with a thin man in Ironvault grey. On the rocks above the yard, five young Ashborn with Firebrand Rites lit in their palms, and in front of them, a lanky boy in a scorched red cloak too big for him._

**Bren:** That's far enough, Unsworn. That steel's going to a war, and we're going to stop it going.

**Mother Hesk:** _(Not looking up from her ledger.)_ And then I turn my wagons round, boy. My contract says steel for grain, and there'll be no steel.

**Bren:** You'd let them starve?

**Mother Hesk:** I'd let them pay. I've a farm to keep too.

**Notary Strand:** _(Writing.)_ Ironvault holds both ends of this contract. A delay is noted. A loss is charged.

**The player's choice (a menu; the three answers at the bottom move on):** Does Kaela know? / If you burn it, the grain turns back. / Where's the steel going? / Stand down, Bren. / Let it burn. / Ask Wren.

**Bren (Kaela):** She'd do it herself if she wasn't in the Moot. _(beat)_ She'll do it when she's Warlord. I'm only doing it first.

**Bren (grain turns back):** Then we eat less. We ate less for twelve years up on the rock.

**Bren:** _(Looking at the grain wagons. Quieter.)_ The rock wasn't so bad.

**Bren (where's it going):** _(He throws the player a manifest he lifted off a wagon.)_ Read it.

_The manifest, on screen: To Duke Halvard's quartermaster, for the gate at Hrimmark: forty siege-Sigils, sixty chain, one engine. Paid by note of Ironvault._

**Bren (stand down):** _(He jumps down into the yard's turning-circle.)_ Then stand me down.

**DUEL · The Cinder Steps** · Bren Ashborn · Young Ash. _A sworn wager, played once. If you win, the Ashborn stand down and the wagons go through. If Bren wins, the steel burns._

- _His deck: Fire, all of it hurrying: Cinderpup, Emberwisp, Blazehound, Firebrand, Goading Ember, Kindled Banner._
- _Ground and Law: the yard's turning-circle, cut with Pyrrhane's marks for the carters' luck: Pyrrhane's ground (Fire Graced). Forge Heat, and Bren, sworn to Pyrrhane like all the Ashborn, has the Blessing._
- _Duel rule: **Hothead.** Bren's Totems never Guard or Rest. Every one that can attack, attacks._
- _Crystallises: by its energy, usually a Tier I or II Fire card._

**Bren (his first attack):** Waiting's what got us exiled.

**Bren (a Totem of his falls):** That's nothing. Kaela would've—

**Bren (if he wins):** Burn it!

**Bren (when you win):** _(He looks at the grain wagons, and then at his own hands.)_ Fine. Fine. Tell her I tried.

**Let it burn:** _(The young Ashborn bring the oilcloth down in flames, and the steel wagons burn on the ledge. Mother Hesk watches for a while, then cracks her whip, and her grain wagons start back down the Steps the way they came.)_

**Mother Hesk (it burned):** Next month, if there's steel.

**Bren (it burned):** _(Watching the grain go down the cliff. He'd thought it would feel different.)_

**Ask Wren:** _(Wren reads the manifest over the player's shoulder.)_

**Wren:** Steel's going to a war either way. I can't stop that. I can change which one.

**Wren:** Give me a minute with the Notary's seal and his back turned. Hesk gets her steel, the grain comes up, nobody burns anything. You just pick where the forty Sigils end up.

**The player's choice:** Send it to Stormreach. / Leave it for Hrimmark.

_(Leave it for Hrimmark.) Wren shrugs and steps back, and the menu comes back without her._

_(Stormreach.) A minute later the Notary turns back to his manifest and finds his own seal on it, in his own wax, over a new name. He frowns at it a long time, and initials it._

**Bren (Stormreach):** _(The fire in his palm goes out.)_ Is that better?

**Wren:** Ask Stormreach.

**Where it comes back:** the Bread Board. If the steel burned, it reads "Two loaves a token, this week only", the Bread Stair knows the Ashborn did it, Kaela's welcome in the Anvil Hall in branch A is colder, and her first winter starts a week hungrier. Kaela's line at the Waystone (PY15). In Hrimmark, forty siege-Sigils fewer at the boy-king's gate if the steel burned or went to Stormreach. In Stormreach, forty Pyreholt war-Sigils more on Admiral Vessa's decks if Wren sent them, every crate stamped "Hrimmark" and crossed out.

### The Ember Urn

_Who: Dagny Flint, forties, a forge-hand of the Flint clan with six children; Sarn the Tallyman, sixties. When: after Round One, until the dawn of the third day. Where: the Crucible's gate, then Ember Lane, a crooked street of forge-cottages under the Crucible's outer wall._

**What it's about:** a rig is kept going by people who need it to eat.

_Dagny is waiting at the Crucible's gate with her purse in a cloth: three loaves and an onion._

**Dagny:** I'll show you something.

_She takes the player to the Ember Urn, cooling on its stand, and holds her palm flat over the coals without touching them._

**Dagny:** The tokens sit in the coals all night. Iron holds heat, and the ones that went in late are cooler. An old man who's handled iron all his life can tell which is which with his eyes shut.

**The player's choice (a menu; "Where does he live?" moves on):** Who puts them in? / Why tell me? / Where does he live?

**Dagny (who):** Sarn. Tallyman forty years. He was Hadric Ashborn's second, once, in the Anvil.

**Dagny (why tell me):** Because you're the one person in the Crucible nobody's paid. That I know of.

**Dagny (where):** Ember Lane. Follow the smell of stew. _(beat)_ You'll see.

_Ember Lane. A cottage door standing open, and inside, an old man ladling stew out of a pot big enough to bath a child in, into bowl after bowl held up by children and old women. Forty of them, at least, in the lane and the doorway._

**Sarn:** _(He sees the player's face, and Dagny's behind it, and puts the ladle down.)_ Ah.

**Sarn:** Sit down. You'll want to have this out properly.

**The player's choice (a menu; "So what now?" moves on):** You fixed the Draw. / Who paid you? / Why? / So what now?

**Sarn (fixed):** I've made every Draw for eleven years. I sell them. _(He doesn't lower his voice; the children don't look up.)_

**Sarn (who paid):** The buyers, mostly. A duke's man wants his steel tried on someone famous in the semi, so he pays for them to get there.

**Sarn:** This year the Duke's man bought you, and Dagny for your first round. The Warlord's steward bought Kaela for the Hammer. The rest went cheap.

**Sarn (why):** _(A nod at the pot.)_ Forty in this lane. The Warlord's tokens feed whoever works a forge. These don't.

**Sarn:** They were Hadric's people. The Ashborn's old and widowed and too small to climb the rock with them when they went. Nobody's tokens cover them but mine.

**Thought:** _(He feeds Hadric's people by selling Hadric's daughter to the Hammer.)_

**Sarn (so what now):** That's yours to say.

**The player's choice:** Tell the Moot, at dawn. / I'll keep it to myself. / Duel me for it.

**Sarn (tell the Moot):** _(A long breath.)_ Then I'll say it myself, at dawn, on the sand. I'd sooner it came out of my mouth than yours.

**Sarn (tell the Moot):** And nobody buys a Draw off me again, and this pot's empty by the new moon. _(beat)_ You'd better be right about what you're doing.

**Sarn (keep it):** _(He picks the ladle up again.)_ Thank you. _(He doesn't look glad.)_

**Sarn (duel me):** An old man and a young one. _(He takes a deck down off the shelf, old and brass-cornered, in Ashborn red.)_ If you win, I stand on the sand at dawn and say it myself. If I win, you forget the Urn.

**DUEL · Ember Lane** · Sarn · The Old Tally. _A sworn wager, played once._

- _His deck: Fire and Earth, an old Moot champion's deck, heavy on Wards: Hearth Salamander, Ashen Drake, Pebblit, Quarry Golem, Ambush Snare, Iron Bastion, Rite of Ashes._
- _Ground and Law: a Circle chalked on the lane's cobbles with Pyrrhane's marks: his ground (Fire Graced). Forge Heat._
- _Duel rule: **Warm Hands.** At the start of each of his turns Sarn sees the top card of your deck. He's felt for warm iron for forty years._
- _Crystallises: by its energy, usually a Tier II or III Fire card._

**Sarn (Warm Hands, the first time):** _(A nod at your deck.)_ That one's warm.

**Sarn (his Ward springs):** I won the Moot three times with that one. Honestly, in those days.

**Sarn (if he wins):** Forget the Urn. _(He goes back to the pot.)_

**Sarn (when you win):** _(He looks at the pot, then at the children.)_ Dawn, then.

**Where it comes back:** at dawn on the third day (PY13). If Sarn confesses, the city learns the Moot was sold as well as turned, and the hall is angrier that night. In branch A, Kaela keeps him on as Tallyman ("Nobody'll buy a Draw off him now, so he's the only honest one we've got"), but her tokens are thin, and the pot in Ember Lane is empty by midwinter: Hadric's forgotten people go hungry under the first Ashborn Warlord in twelve years. In branch B, Vorn turns him off the tally and puts all forty on the Warlord's tokens the same week: he has never let anybody starve that he could count. If the player kept the secret, on any later visit Sarn is still selling the Draw.

### The Hammer's Doubt

_Who: Doran Garr, twenty-four, the Hammer, Vorn's foster son. When: the second evening, after the semi-finals, until the final. Where: the Cold Waystone after dark, the Ashborn camp asleep round it._

**What it's about:** what a win is worth when you don't know whose it was.

_A big young man in smith's leathers sits alone on the Waystone's foot with his Moot deck in his lap. He stands when he sees the player: not to fight, out of manners._

**Garr:** You're the Unsworn. I watched your semi. _(beat)_ You watched mine.

**Garr:** My Asp was Graced down there. In Pyrrhane's Crucible. Venom. _(He turns the deck over in his hands.)_ Seven years I've never once looked at the ribbons. I didn't want to know why they were always on my side.

**The player's choice (a menu; "What do you want?" moves on):** Why did you never look? / Why come to me? / You beat Kaela. / What do you want?

**Garr (never look):** Because he raised me. My mother died the Hungry Winter, in Hadric's last year.

**Garr:** Vorn found me in the queue on the Bread Stair, twelve years old, and sat me at his Table, and I've been there ever since. If he's put his thumb on my scales, it's because he thinks I'd fall off without it. I'd rather not find out he's right.

**Garr (why come to me):** Because you're nobody's. Nobody's paid you to lose, and nobody's turned a Circle for you.

**Garr:** And this stone's Pyrrhane's, and nobody's touched it.

**Garr (beat Kaela):** I don't know if I did. That's the whole of it.

**Garr (what do you want):** One bout. Honest ground. And not with the Warlord's steel: with mine.

_He holds up a second deck, small and battered and red._

**Garr:** The deck I had when I was eleven. Before the Table.

**The player's choice:** All right. / Not tonight.

**DUEL · The Waystone, by night** · Doran Garr · The Boy's Deck. _A sworn wager with nothing on it but the truth: win or lose, it stands._

- _His deck: Fire, a child's collection grown up: Cinderpup, Blazehound, Hearth Salamander, Emberwisp, Rekindle, Firebrand._
- _Ground and Law: the Waystone, Pyrrhane's ground (Fire Graced). Forge Heat. Garr is sworn to Pyrrhane, so his Fire Totems ignore the heat: the first the player sees of which god he kneels to._
- _Duel rule: **No rule.** Garr asks for nothing: no tally, no sand, no Moot law, just the Circle. It's the only duel in the chapter without a rule of its own, and that's the point._
- _Crystallises: by its energy, usually a Tier II Fire card._

**Garr (his first Fire Totem shrugs off the heat):** _(Quietly.)_ Still mine, then.

**Garr (if he wins):** _(He sits down hard on the stone.)_ I'm good. _(He sounds almost disappointed.)_ I'm actually good.

**Garr (when you win):** _(He laughs once, not unhappily.)_ There it is.

**Garr (when you win):** Thank you. _(beat)_ Nobody's beaten me since I was a boy. I'd started to think nobody could.

**The player's choice:** Your Asp was Graced because the ground's Vexa's. / Ask Vorn. / Go home, Garr.

**Garr (Vexa's):** _(He doesn't say anything for a long time.)_ I pray at the Pyre every night. I've never once asked for anything.

**Garr:** I thought that was why he never answered.

**Garr (ask Vorn):** He'd tell me. _(beat)_ That's what frightens me.

**Garr (go home):** Home's his Table. _(He gets up.)_ I'll go anyway.

**Where it comes back:** Garr's lines before the final (PY14) change with what happened here. Whatever the player did, in branch A he walks Vorn to the edge of the badlands and comes back to work Kaela's forges (or, if Vorn stays, works beside him), and in branch B he won't hold the Hammer in a Vexa forge: he climbs to the Pyre, takes the bellows from Odra, and keeps whatever fire Vorn's promise has left him. If the player beat him here, he says so to Odra the first night: "Somebody beat me. On honest ground. You'd have liked it." In Part 2 he is in the stands at the Convocation, either way, watching Kaela (A) or Vorn (B).

---

## Morrowen's Ledger

Each account is a sentence or two in Morrowen's voice, in the past tense, and changes as the story does (examples; the rest follow the same shape).

- **The Ember Moot** (A): You won the clans' Brand on ground you'd made honest, carried it into the Warlord's own Circle, and gave his Seat to Kaela Ashborn for her god. Pyreholt went hungry that winter, and lit.
- **The Ember Moot** (B): You won the clans' Brand and laid it on Vorn's forge, then stood for him against Kaela Ashborn under the Plague Saint's Law. Pyreholt ate, and became Vexa's.
- **The Burning Crown:** A god too cold to stop time asked you to look under the sand and then to fight him. You did both, and his Pyre could be seen from the plains again.
- **Untested Steel** (flawed): Marda Kell found three flaws in twenty war-Sigils and sent them north anyway, to a gate her son stands behind.
- **The Grain Road** (Stormreach): A thief changed one word on a manifest, and forty siege-Sigils went to a different war. Nobody in Pyreholt went without bread.
- **The Ember Urn** (confessed): Sarn sold the Moot's Draw for eleven years to feed forty people nobody else would. He said so on the sand, and the pot in Ember Lane emptied.
- **The Hammer's Doubt** (you won): Doran Garr had never lost. You beat him on honest ground, and he thanked you for it.

**People** (one line each):

- Kaela Ashborn. Lost the Moot on stolen ground and asked only to be looked in the eye.
- Warlord Vorn. Fed a city for twelve years, and hid only what it cost.
- Doran Garr. Seven Moots won, and not sure of one.
- Keeper Odra. Worked a dying god's bellows alone for twelve years, and cut a mark she wished she hadn't.
- Sarn. Tallyman. Fed forty people with a crooked Draw.
- Dagny Flint. Six children, seven Moots, and she can count.
- Ulfar Brenn. Bought forty siege-Sigils for a gate in Hrimmark and paid for them honestly.
- Marda Kell. Forges the order that goes north to her son's war.
- Bren Ashborn. Wanted to be his cousin a year early.
- Pyrrhane. The Burning Crown. He doesn't ask for things.
- Vexa. The Plague Saint. Always stays at the bedside.

---

## New things this chapter needs

### People (looks for a 3D model prompt)

All in the game's painted, slightly stylised realism, full body, A-pose, arms a little away from the body, eyes open.

| Who | Look |
|---|---|
| **Kaela Ashborn**, 26 | A lean, strong woman in her mid-twenties with a duellist's build; cropped dark-red hair, uneven as if cut with a knife; grey-green eyes; a pale, long-healed burn scar along the left side of her jaw; a small iron ring in one ear. A scorched red wool cloak over a fitted black leather jerkin with brass buckles, thin leather bracers on bare forearms, a wide belt with a card case, dark trousers, tall worn boots. Proud, still stance. |
| **Warlord Vorn**, about 58 | A big, heavy-shouldered man; shaved head, short iron-grey beard, deep-set tired eyes; old smooth healed burn marks on both forearms. A scarred leather smith's apron over a good dark-red wool shirt with the sleeves rolled to the elbow, black trousers, heavy boots, a thick iron ring on one thumb. Solid, patient stance. |
| **Doran Garr**, 24 | A tall, broad young man with a soft, open, boyish face; short black curly hair; clean-shaven. Sleeveless leather smith's jerkin, leather trousers, heavy gloves tucked in his belt, an iron hammer pendant on a cord, soot on his forearms. |
| **Keeper Odra**, 70s | A small, wiry old woman; white hair in one long braid; a face lined like bark. A long leather apron scorched at the hem over a plain grey dress, thick leather gauntlets, sandals. |
| **Sarn the Tallyman**, 60s | Lean and a little stooped; a long grey moustache, bald on top with grey hair at the sides, spectacles pushed up on his forehead. A faded red waistcoat over a collarless shirt, sleeve garters; one palm a smooth old burn. |
| **Dagny Flint**, 40s | A broad woman with ruddy cheeks and short brown hair pinned back with a bent nail. A soot-streaked canvas forge-smock, leather apron, rolled sleeves, heavy boots, a cloth bundle at her belt. |
| **Ulfar Brenn**, 40s | A huge northern man; long fair hair and beard in braids. A heavy white wolf-fur mantle over grey mail and a quilted coat, a green rootwork brooch at his throat, fur boots. Cheerful face. |
| **Marda Kell**, 50s | Strong and square; iron-grey hair cropped short; burn-freckled forearms; a stub of chalk behind one ear. Leather blacksmith's apron over a brown work shirt, heavy gloves. |
| **Bren Ashborn**, 17 | A lanky boy with long, untidy dark-red hair like his cousin's and a patchy first beard. A scorched red cloak too big for him, a leather jerkin, a card held ready in one hand. |
| **Mother Hesk**, 50s | A sunburnt plains farmer: broad straw hat, linen smock and waistcoat, a coiled whip at her belt, a ledger under one arm. |
| **Notary Strand**, 40s | A thin man in the immaculate grey coat of Ironvault, high collar, silver buttons; neat colourless hair; a ledger and pen. |
| **The Crucible Watch** (Teague and Pike) | Two guards in blackened scale armour with an anvil badge on the breast, hooded smoke-masks pushed down round their necks; one stout, one thin. |
| **Pyreholt crowd** (four or five variants) | Forge-folk: soot, leather aprons and red and black wool; clan-folk in scorched red; an old man; a mother with an iron token; a child with a white-painted palm. |
| **Pyrrhane** | Gary's own painting and video of him (male). In PY10 only his face and shoulders forming in the coals, dim; from PY12 on, whole and burning in the Pyre. |
| **The Burning Crown** (Pyrrhane's Aspect; a boss model and a painting) | A giant made of dark iron plates and living embers, broad as a forge door; a heavy brow and a beard of slow-burning coals; eyes like forge-mouths; molten seams across the chest; a crown that is a ring of flame, dull red at first and white-hot from half Life. Clips: rising out of the brazier, idle, three blows, kneeling (the fall). |
| **Vexa, the Plague Saint** | A tall, slender figure in layered grey-green veils like a mourner's, the face hidden except a calm, kind mouth; long pale hands; a bronze censer on a long chain in one hand, thin green smoke coiling out of it; bare feet stained the dark green of marsh water; a faint halo of thin smoke rings behind her head. Gentle, unhurried. |

Old Smoke, Kaela's Warg, is an Infernal Warg: its own model (still a stand-in in the game) does for him, with three small ✦ marks.

### Places and props

- **The Ash Road and the badlands:** black rock in long folds, grey ash in the hollows, threads of steam from cracks, half-formed Sigils glinting in the ash.
- **Pyreholt from the rim:** the caldera city in terraces of black stone, chimneys and chain-bridges, a hundred furnace-mouths, the Pyre on its crag (cold, then lit).
- **The Cold Waystone and the Ashborn camp:** a standing stone carved with worn flames, a clean Circle cut at its foot with Pyrrhane's crown of flame round the rim; red tents and cookfires; the Ashborn banner (an open hand in flame) upside down, and in branch A the right way up.
- **The Cinder Gate:** two forty-foot iron doors, a toll-house, buyers' wagons with crate seals (an anvil over a white wolf; over a ship).
- **The city:** the Lower Forges and chain-bridges; the Bread Stair up to the granary, with its queue; the Bread Board (a slate, four versions of its chalk); the Slag; Tamsin's stall; the Pyre path with its chain and painted sign; Ember Lane and Sarn's cottage with the great pot; Marda's forge with a proving-Circle cut in the floor (Hethrin's marks).
- **The Crucible:** a small crater arena, stands cut into its walls, heat vents, the Buyers' Gallery behind glass; the Circle in four states: under raked black sand; swept back to show Pyrrhane's flames with Vexa's serpent-and-censer cut across them; glowing up through the sand at dawn; cut clean back to Pyrrhane's. The Clanstone by the gate, ASHBORN with a flame cut through it sideways. The Ember Urn (an iron pot of coals on a stand, eight stamped iron tokens).
- **The Anvil Hall:** a forge-hall the length of a street, a fire-trench down the middle, long tables and iron bowls, Vorn's working forge at the head, and the Anvil, a duelling Circle of black iron set into the floor.
- **The Pyre:** a roofless temple of black stone round a house-sized brazier; the coal-walk; Odra's bellows; cold and banked, then a forty-foot column of fire.
- **The Cinder Steps:** a switchback road down the outer cliff and an exchange yard on a ledge, grain wagons and steel wagons, a turning-circle with Pyrrhane's marks.
- **Props:** the Brand of the Moot (an iron rod with a head shaped as an open hand in flame, glowing); bread tokens (iron, stamped with an anvil); the Anvil-Forged Collar on a table; the Halvard manifest; the order books; Garr's two decks (the steel one, and a small battered red one).

### Items

- **The Seal of Pyreholt:** a disc of black volcanic glass with a flame held inside it that never goes out. Given by Pyrrhane at his Trial.
- **The Brand of the Moot:** in Items from the final until the choice; gone either way after it.

### New cards

| Card | Element · tier · kind | What it does | Painting subject |
|---|---|---|---|
| **The Ashborn Drake** | Fire · V Legend · Totem | Two Tributes. 260 HP. Strike: Ash Wing, 50. Brand of the Clan (4 Essence): 90 and Burned. **Unbowed:** while its duellist keeps an Oath, it takes 20 less from every blow. One of three in the world; this one was Hadric Ashborn's. | A great drake of soot-black scales with seams of banked fire, wings like scorched banners, an open hand in flame branded on its breast, crouched on a cooling pyre, smoke rising. |
| **The Brazen Hydra** | Metal · V Legend · Totem (Vorn's; not won) | Two Tributes. 280 HP. Strike: Three Mouths, 30 to up to three enemy Totems. Siege Breath (4 Essence): 60 and Poisoned. **Every War:** whenever any Totem falls, it heals 20. | A hydra of riveted bronze plate and forge-pipes, three heads with furnace mouths, green smoke seeping from its seams, standing over stacked crates stamped with different kingdoms' seals. |
| **Brazen Drake** | Metal · IV Relic · Totem (beating Vorn, branch A) | One Tribute. 190 HP. Strike: Furnace Bite, 40. Brazen Breath (3 Essence): 60. **Profit:** when an enemy Totem falls, gain 1 Essence at your next turn. Lesser kin of the Hydra. | A one-headed drake of bronze plate, a furnace glowing behind the grille of its ribs, rivets hot, a forge's chain still round one leg. |
| **Siegebreaker Ram** | Metal · III Crystal · Totem (from Ulfar) | One Tribute. 170 HP. Strike: Breach, 40, and **Breach**: its Strike ignores Guard. Battering Charge (3 Essence): 70. | An iron ram-beast with a riveted battering-ram head, chains trailing, Pyreholt maker's marks stamped on its plates, snow on its back. |
| **Anvilback Tortoise** | Metal · III Crystal · Totem (from Garr) | One Tribute. 220 HP. Guardian; Shells family (Hardened). **Hammer Down:** a Totem that strikes it takes 10. Strike: Shell Slam, 30. | A great tortoise whose shell is a black iron anvil scarred with hammer-marks, sparks rising off it, glowing eyes under a brow of slag. |
| **Unbowed** | Fire · II Glimmer · Rite (Kaela's gift) | If no Oath binds you and your Life is at half or more, swear the Unbowed now; it doesn't use up either of the duel's two Oaths. While you keep it, your Fire Totems deal 10 more. | A raised fist wrapped in burning cloth, the fingers straight and unbent, against a sky full of cinders. |
| **Anvil-Forged Collar** | Metal · III Crystal · Relic (Vorn's gift) | +20 damage. When the Totem wearing it falls, gain 1 Essence at your next turn. | A heavy collar of black iron stamped with an anvil, its rivets glowing faintly, lying on a forge-anvil. |
| **Plague Saint's Censer** | Venom · III Crystal · Relic (Vexa's offer) | Its Totem's Strike Poisons. Its Totem can't be Poisoned. | A bronze censer swinging on a chain over grey-green silk, its green smoke coiling into the shape of a serpent. |
| **Kaela, the Unbowed** | Fire · IV · Companion card | Kaela stands beside you in a Tag Duel. In an ordinary duel, once: call Old Smoke, her Infernal Warg, into an empty slot for free; he strikes once, then goes home. Leaves with her if she ever leaves. | Kaela mid-stride in her scorched red cloak, a card burning in her raised hand, Old Smoke at her side, the Pyre behind them. |

Pyraxis, Heart of the Pyre (VI) is already in the game: Pyrrhane gives the second of the two in the world. If the player's deck is Emberstorm, they now hold both.

**For the build** (rules this chapter uses that the duel doesn't have yet): the Crucible's hidden ground (the corner reads "ground hidden under the sand" while `spec.place_god` is Vexa's, then "Vexa's ground" once swept, then Pyrrhane's); a Seat contest fought under the defender's sworn god's Law rather than the kingdom's; the **Tag Duel** (proposed: one side shared between two, its three Totem slots, two Ward slots and one Life; each partner has their own deck, hand and Essence; turns go you, rival one, partner, rival two; the partner is the computer and you see their hand; Life is the higher of the two partners' plus 100); and the **boss duel** as the synopsis has it (one great Life, up to three moves a turn, no Mind conditions, a Boss Rule and a second at half Life). Two more: a story duel keeping its Circle's own rule beside its story rule (today a story rule takes the arena rule's place, but every Crucible duel here keeps the emberforge's sprung-Ward Burn and the Forge Roars); and a defender naming someone to stand for him in a Seat contest (PY17B; new to the Law of Challenge). The story rules: Open Hand (twice, the second time both ways), The Long Purse, Paid in Full, The Bell, The Strongest Rule and The Pyre Wakes, Never Behind, Both Sides of the Ledger, and for the side stories Proof, Hothead, Warm Hands and No rule. Barks for rivals' Oaths (Kaela, Garr) and for the player swearing (Vorn) use the `my_oath`, `my_oath_broken` and `rival_oath_broken` hooks. The Law and card texts in `duel_laws.gd` and `duel_cards.gd` still say "Dawn" and "Dusk" for the start and end of a turn, left over from the phases; this script says "the start of a turn" and "the end of a turn", and the game's own words want the same change.

### Music (for AI Music Lab; paste each as it is)

The Crucible's ordinary duels can use the existing `arena_emberforge` loop, and Pyraxis has `summon_pyraxis`. Ten new tracks:

1. **pyreholt_road** (the Ash Road, the first sight of the city): Cinematic dark fantasy ambient. Low bowed cello drone, distant war drums, slow low brass swells, far-off anvil strikes and hissing steam woven into the rhythm, a lone duduk melody over the top. 70 BPM, D minor. Mood: vast, desolate, awe at a city of fire seen across a dead land. No vocals. Seamless loop. Length 2:30.
2. **pyreholt_town** (the city between scenes): Industrial folk-orchestral fantasy town theme. Hammer-on-anvil percussion on the beat, frame drum and bodhrán, low string ostinato, a hurdy-gurdy melody answered by bass clarinet. 96 BPM, A minor with a Dorian lift in the second half. Mood: hard-working, proud, smoky, a city that never stops. No vocals. Seamless loop. Length 2:45.
3. **ashborn_camp** (Kaela's theme; the Waystone): Intimate fantasy theme for solo cello and fiddle. Low solo cello carrying a proud, wounded melody, a fiddle answering it, a soft frame-drum heartbeat, crackling campfire underneath, one French horn near the end. 76 BPM, E minor. Mood: exile, pride, quiet anger, warmth underneath. No vocals. Seamless loop. Length 2:30.
4. **vorn_table** (the Anvil Hall; Vorn's theme): Warm, heavy medieval hall music. Low strings and bassoon, plucked lute, slow bodhrán, a tuba-like low brass melody, the murmur of a crowded hall as a quiet bed. 84 BPM, F major leaning into F minor in the middle. Mood: generous, solid and tired, a man who feeds a city, with something uneasy underneath. No vocals. Seamless loop. Length 2:30.
5. **ember_moot** (the Moot's duels: Dagny, Ulfar, the final): Epic tribal-orchestral duel theme. Huge war drums and a crowd-stomp rhythm, anvil hits on the off-beats, low brass stabs, driving strings, a fierce zurna lead, wordless synth-choir pads. 128 BPM, C minor. Mood: an arena of fire, heat and ferocity, a crowd on its feet. No vocals. Seamless loop. Length 3:00.
6. **the_cold_pyre** (Pyrrhane's temple, his face in the coals): Sacred dark ambient. A deep organ pedal note, slow breathing swells like a great bellows, wordless low choir pads, crackling embers, a sparse low piano motif. 60 BPM, B-flat minor. Mood: a god's temple gone cold, grief, something huge asleep in the coals. No vocals. Seamless loop. Length 2:30.
7. **the_plague_saint** (Vexa in the stands): Eerie, gentle ambient. Glass harmonica and bowed vibraphone, a soft detuned music box, a slow swinging pulse like a censer, breathy alto flute, a low drone. 66 BPM, G-sharp minor. Mood: kind, calm and quietly sickening, a nurse at a bedside who is enjoying herself. No vocals. Seamless loop. Length 2:00.
8. **trial_by_fire** (the boss duel with Pyrrhane's Aspect): Epic boss-battle hybrid of orchestra and metal. Pounding timpani and taiko, distorted low guitars under full brass, anvil percussion, racing strings, roaring fire sound design; a heroic horn theme that rises halfway through and lifts the whole piece brighter and faster. 140 BPM, D minor. Mood: facing a god of fire, overwhelming heat, joy in strength. No vocals. Seamless loop. Length 3:15.
9. **the_anvil** (the Seat contest, both branches): Dark, solemn orchestral duel theme. A low string ostinato, iron anvil strikes on beats one and three, a low brass chorale, hammered dulcimer, a slowly building war drum, and a sickly woodwind counter-melody (oboe and bass clarinet) for the green smoke. 112 BPM, F minor. Mood: a reckoning in a great hall, a whole city watching, no clean side. No vocals. Seamless loop. Length 3:00.
10. **pyreholt_farewell** (the road out, both branches): Bittersweet folk-orchestral farewell built on Kaela's theme. Solo cello and fiddle duet, harp, soft strings, a far-off anvil, a last French horn. 72 BPM, E minor resolving to G major. Mood: leaving a city that has been changed, hope and cost together. No vocals. Seamless loop. Length 2:30.

### Voice lines (the Herald and Morrowen)

Of the voices recorded so far, only the Pale Herald and Morrowen speak in Pyreholt; Solmaris and Morne don't appear. Who voices the rest of the cast is still to settle (the synopsis lists it as open); until then everyone else's lines go on the recording sheet the usual way (`tools/vo_sheet.py`) once the chapter is in the game.

| Id | Who | Line | Where |
|---|---|---|---|
| morrowen_pyre_01 | Morrowen | Pyreholt has kept its god's fire since before the Covenant was written. For the last twelve years it has fed other fires instead, and they have fed Pyreholt, and nobody asks what they burn. | PY1 |
| morrowen_pyre_02 | Morrowen | Pyreholt went hungry that winter, with its head up and its fire lit. I wrote down every name that came to me from it: fewer than Vorn would have guessed, and more than Kaela could bear. | PY18, A |
| morrowen_pyre_03 | Morrowen | Pyreholt ate that winter, every soul of it, and its steel went north and east and did what steel does. I wrote down every name that came to me from those wars. Not one of them was from Pyreholt. | PY18, B |
| herald_pyre_01 | Pale Herald | The Seat of Pyreholt is challenged, in the Turning, by the Covenant, under the Brand of the Moot. | PY17A |
| herald_pyre_02 | Pale Herald | The challenger is the Unsworn. The defender is Vorn. | PY17A |
| herald_pyre_03 | Pale Herald | Vorn holds the Seat of Pyreholt for Pyrrhane. Vorn is sworn to Vexa. | PY17A, PY17B |
| herald_pyre_04 | Pale Herald | The Circle is the defender's. The Law is the defender's god's: Plague Air. | PY17A, PY17B |
| herald_pyre_05 | Pale Herald | The stakes are the Moot's: the Seat, against the challenger's fire in Pyreholt. Begin. | PY17A |
| herald_pyre_06 | Pale Herald | The Seat of Pyreholt passes to the Unsworn. The Unsworn holds no god. Name the holder. | PY17A |
| herald_pyre_07 | Pale Herald | Kaela Ashborn holds the Seat of Pyreholt, for Pyrrhane. Witnessed. | PY17A |
| herald_pyre_08 | Pale Herald | The Seat of Pyreholt is challenged, in the Turning, by the Covenant. | PY17B |
| herald_pyre_09 | Pale Herald | The challenger is Kaela Ashborn, sworn to Pyrrhane. The defender is Vorn. | PY17B |
| herald_pyre_10 | Pale Herald | The defender names the Unsworn to stand for him. The stakes are set. Begin. | PY17B |
| herald_pyre_11 | Pale Herald | The defender's Seat stands. Vorn holds the Seat of Pyreholt. | PY17B |
| herald_pyre_12 | Pale Herald | Vorn is sworn to Vexa. The Seat is held for its holder's god. Pyreholt is Vexa's Dominion, until the Closing seals it. | PY17B |

### Where it comes back later

Kaela: a Champion of the Convocation in branch A (and so a possible draw against the player in Part 2), a companion on the wagon in branch B; her personal quest later can be her father's Drake, and the man who gave a five-year-old a Warg. Vorn: Pyreholt's Champion for Vexa in branch B. Pyrrhane: with no Dominion in branch B, the Faded's first new member if the story wants him. Hrimmark: the forty siege-Sigils (The Grain Road), Marda's batch and her son Arlo (Untested Steel), Ulfar at Halvard's side. Stormreach: Wren's re-sealed crates. Wren: Vexa's "Give your mother my love." Bram: Pyrrhane's "Holloway walked my coals forty years ago."

---

## Questions for Gary

1. **Branch B gives Pyreholt to Vexa.** Because a Seat is held for its holder's god, standing for Vorn makes Pyreholt Vexa's Dominion: Plague Air becomes its Law for the rest of the game and Pyrrhane loses his only kingdom. It's the biggest consequence in Part 1 so far. Keep it?
2. **Hadric threw his duel.** Kaela's father let Vorn win so the city would eat, and it was Pyrrhane, not Vorn, who exiled the Ashborn for it. The synopsis says the Covenant forbids a thrown duel and the Herald always knows, so as written he did it inside the letter of the law: he laid his Legend on the Pyre the night before and fought Vorn honestly without it. Is that the secret you want under Kaela?
3. **Bram in Pyreholt.** Two small threads: he took Pyrrhane's Trial forty years ago (which is why his Emberstorm box holds Pyraxis), and Kaela's Warg is the Cinderpup he says he raised and gave "a girl in a town that was burning" in the Prologue. Keep both, one, or neither? If the Warg stays, Kaela was the Warlord's daughter then, so "the night my town burned" needs a place and a cause (an Ashborn clan town outside the crater, perhaps), decided before her personal quest is written.
4. **Kaela in branch A.** As written she stays to rule Pyreholt through the hungry winter and comes when the player calls her card. Would you rather she rode with the wagon in both branches?
5. **Tag Duels.** The proposed rules: you and your partner share one side, three slots and one Life, each with your own deck and hand, turns going you, rival, partner, rival. Is that the Tag Duel you want?

---

## Editor's pass (2 November)

- **No phase words.** Every "at Dawn" and "at Dusk" in the duel specs and directions (Forge Heat, Plague Air, Iron Brace, The Bell, The Pyre Wakes, Warm Hands, the Kaela–Garr film) now says the start or end of a turn. The build note records that `duel_laws.gd` and `duel_cards.gd` still use the words.
- **Oaths as the engine plays them.** A broken Oath costs 30 Life and nothing else, so Bram's memory and the semi-final film no longer take Favour. Only one Oath can bind at a time, so Kaela's Faithful in PY17B comes only if her Unbowed breaks. The Unbowed Rite's text now fits those rules.
- **Hadric's thrown duel made lawful.** The synopsis says the Covenant forbids a thrown duel and the Herald always knows. So Hadric laid his Drake on the Pyre the night before and fought Vorn honestly without it. Pyrrhane's reveal, Vorn's account and the Drake's history now agree.
- **The rig holds together.** Kaela no longer says the Herald comes only in a Turning, which broke Vorn's reason for keeping the Herald out for eleven years. She now says why she can enter this year, and Vorn says why nobody challenged him directly (he sets the stakes). The sand is raked back over the rim overnight before PY13. On day three Sarn carries the Brand, because a final has no draw.
- **Boss duel shaped as the synopsis has it:** one Boss Rule (The Strongest Rule, which now includes the banked fire) and one rule at half Life (The Pyre Wakes).
- **PY17B's duel rule** was called "Trial by Fire", the same name as PY12's Trial. It is now Kaela's own Open Hand from the Waystone, played both ways this time.
- **Nobody takes a card.** Pyrrhane's "Holloway took it off me" is now "walked my coals and went home with it", here and in the later list.
- **Teaching only through Bram's memories.** Cut the Thought that taught Graced ground again (the Prologue already taught it). The rim Thought in PY2 is now only what the player sees.
- **Contradictions fixed:** Kaela's "not for a god" bark (she kneels at the Pyre in PY10). Garr's age at the Hungry Winter (12, not 8). The Blessing being the "first the player has seen" (they saw it at the Waystone). Bram's "You never asked" (the player can ask in PY1). Vorn's promise of "one thing" that he never made. Morrowen's "nine thousand years" against Odra's "before the Covenant". The Ledger's "never once lied" for Vorn. Sarn's Thought, which kept Kaela out of a Moot she is in.
- **Flat or cheesy lines rewritten:** Wren's cemetery and "anything blue" quips, "Somebody's busy", "A deal's a deal" (Wren's line from Chapter 1), "as if they owed you money" in Kaela's grief, "Lucky me", Vexa's "You were doing so well", Bren's "Make me", Garr's "what I was missing", Sarn's "son" (the player can be any of four looks). Marda's "Doesn't mean I sleep" is changed and kept for Bram's Chapter 15 line.
- **Side-story holes:** in The Grain Road, "Leave it for Hrimmark" left Bren hanging; it now brings the menu back. Corin's button is in the player's hand, not sewn on their coat. Cut PY10's sub-choice, which had two options and one answer. "Bring the thief" now follows either answer.
- **Menus** now say which questions can all be asked (Sarn's Urn, Ulfar, Vorn at the Crucible, Vorn's collar offer).
- **Repetition trimmed:** Dagny's "six Hammers in seven years" was said three times, the Draw narration repeated Sarn, plus "The shape of it" and two "Where it comes back" paragraphs.
- **New-things list:** added two rules the build doesn't have: a Circle's own rule kept beside a story rule, and a defender naming someone to stand for him. The voice section no longer says "the voiced four", because who voices the rest is still open.
- **Questions 2 and 3 updated:** the thrown-duel loophole, and Kaela's burning town needs a place and a cause.
