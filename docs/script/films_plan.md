# The Prologue's films for Player A (Master Script v7): your step-by-step

Seven of the Prologue's cutscenes can play as your own films, built round
one hero, Player A, the way the opening movie does, in place of the game's
3D staging of them. The game keeps playing its 3D version of each until the
film is there, so nothing changes until you want it to. (The old plan for
v3's midnight and dawn films is in git's history; v7 changed both.)

What the player does stays in the game between the films: the cart heave
(after the midnight film), the cellar and the tunnel (after the reckoning
film), the look back, every conversation and choice. One choice falls
inside a film (Bram's question at midnight): the film is made in parts
around it, and the game asks it between them (below).

## What to make

**Best: one finished film for each, like the opening.** 4K, 60 fps, H.264,
in DaVinci Resolve, named after the film: `midnight_4k.mp4`,
`white_light_4k.mp4`, `herald_4k.mp4`, `reckoning_4k.mp4`,
`tams_hand_4k.mp4`, `no_roof_4k.mp4`, `ridge_4k.mp4`. Put the picture and
the world's sound in it (music too, if you like), but **no subtitles and
no voices burned in**: the game puts each line over the picture at its
moment (below), as its own subtitles, so the words can change without
remaking a film, and plays the voice recordings it has (the Herald's,
`assets/audio/vo/herald_21`, `herald_03`, `herald_09`, `herald_22`).
Attach it to a session as you did the opening: the iPhone and Mac apps
play it through the phone's own player, like the opening.

The shot lengths below are where the lines fall. Make the shots whatever
length works; when a film comes in, Claude sets the lengths in the game
(`scripts/story/story_film.gd`) to match it, so the lines land on their
moments.

**Or clips, one per shot,** named after the shot (`mid_01.mp4`,
`wl_03.mov`...), and `python3 tools/movie_clips.py <folder> --film
midnight` cuts each to its length and saves it where the game looks. A
painting in place of a clip works too (`assets/art/movie/midnight/mid_01.png`).

**The phone link:** the opening's 4K stream fills most of what GitHub Pages
holds (632 MB of its 1 GB), so a second 4K film needs somewhere else to
stream from on the phone link (the apps aren't affected). Claude will set
that up with you when the first film is ready.

## 1. Midnight (`midnight`), in three parts

You made this one in pieces, cut at Bram's question (5 November), and the
game plays them in turn:

- **Part 1** (`midnight_1_4k.mp4`, 34 s, made): from the bell to Bram's
  "Wonder who'll be sitting up there tomorrow." Its last frame stays on
  screen under the game's two buttons, and your music carries straight on
  from the film (`Midnight_Choice_Menu_Music_24s_Continuation.wav`),
  looping for as long as the player takes to choose.
- **2A or 2B** (`midnight_2a_4k.mp4`, `midnight_2b_4k.mp4`, 3.4 s each,
  made): Bram's answer to the pick, the music still playing under it.
- **Part 3** (`midnight_3_4k.mp4`, still to make): from the lanterns going
  up to Corin under the wheel. Until it's there, the game's 3D takes over
  at the lanterns going up, and its own music stops as the lanterns stop.
  When you make it, start its music where the loop would be by then, or
  bring it in gently: the game fades the loop out over its first second.

The times below are where each shot and line falls in its own part.

**Part 1** (the times are your film's own cuts)

| Shot | Starts | Length | Player A | What's in it | Said over it |
|---|---|---|---|---|---|
| mid_01 | 0:00.0 | 4.5 s |  | Midnight on the packed green, every face turned up to the unlit Great Lantern; the chapel tower, its bell swinging. | 0:00.6 "Midnight. The chapel bell counts twelve, and all of Ashford counts with it." |
| mid_02 | 0:04.5 | 5.5 s | yes | From behind: he climbs the Lantern's steps with a lit taper and touches it to the wick. The Great Lantern burns with a rich, golden flame, and the whole green roars. |  |
| mid_03 | 0:10.0 | 3.5 s |  | Little Tilly steps back from the Lantern, her face glowing gold. Behind her, Tam dances with Nell, badly; Ned's fiddle. |  |
| mid_04 | 0:13.5 | 4.6 s | yes | Corin beside him, both of them watching the crowd; he says it without looking over. | 0:14.0 Corin: "It's a good village, this. Don't tell anyone I said so." |
| mid_05 | 0:18.1 | 7.5 s |  | Bram, looking up at the paper lanterns being readied, their candles lit one by one. | 0:18.6 Bram: "Folk think we send them up for the gods. We don't. A lantern's for whoever's out in the dark, so they know which way is home." |
| mid_06 | 0:25.6 | 8.5 s |  | Bram's face, the Lantern behind him, his eyes going up to the stars. | 0:27.5 Bram: "Two thousand years. Wonder who'll be sitting up there tomorrow." |
| | 0:34.1 | | | **The game asks Bram's question here**, over the held last frame: "Does it matter to us?" / "Whoever it is owes us a better year." | |

**2A or 2B**

| Shot | Starts | Length | Player A | What's in it | Said over it |
|---|---|---|---|---|---|
| mid_07 | 0:00.0 | 3.4 s |  | Bram, close, the ghost of a laugh. | 2A, 0:00.6 Bram: "It shouldn't. It always seems to." (after "Does it matter to us?")<br>2B, 0:00.9 Bram: "Write and tell them. See who writes back." (after "Whoever it is owes us a better year.") |

**Part 3** (still to make; about 51 s)

| Shot | Starts | Length | Player A | What's in it | Said over it |
|---|---|---|---|---|---|
| mid_08 | 0:00.0 | 10 s | yes | Hundreds of paper lanterns rise over Ashford. Then the wind simply stops. Every lantern freezes mid-air; the fiddle trails off; the village goes dead silent, every face turned up, his among them. |  |
| mid_09 | 0:10.0 | 5 s |  | Corin, looking up, then at Bram. | 0:10.4 Corin: "Bram. Is it meant to do that?" |
| mid_10 | 0:15.0 | 8 s |  | With a deafening, glass-shattering crack the sky tears open. A blinding white light bleeds down from the Empyrean, and the midnight green goes as stark and pale as bone. For a breath the children cheer. |  |
| mid_11 | 0:23.0 | 6 s |  | The first strike lands in the top field. The earth bucks; the shockwave shatters the merchant carts lining the green. | 0:26.4 "Screams finally break the silence." |
| mid_12 | 0:29.0 | 4 s |  | Bram, shouting over the noise, pointing him at the inn. | 0:29.3 Bram: "Inside! Everyone inside! Sprout, the inn. Now!" |
| mid_13 | 0:33.0 | 8 s | yes | Everyone runs for their doors. Corin grabs Tilly's hand and runs her up the lane past Tam's cart. He runs for the inn (from behind); strikes land all round him, and one knocks him flat. |  |
| mid_14 | 0:41.0 | 6 s |  | A blast on the far side of the cart throws it over onto Corin; an iron-banded wheel pins him in the mud. Tilly screams. | 0:43.4 Tilly: "Corin! CORIN!" |
| mid_15 | 0:47.0 | 4 s | yes | He gets up in the dust and falling debris, sees Corin under the wheel, and turns back. (The game takes over: Find Corin, and the cart.) |  |

## 2. The White Light (`white_light`), about 38 s

| Shot | Starts | Length | Player A | What's in it | Said over it |
|---|---|---|---|---|---|
| wl_01 | 0:00.0 | 9 s |  | By the cart, one light falls differently: white, slow, silent. Time slows. It passes Bram across the green. It passes Corin. |  |
| wl_02 | 0:09.0 | 6 s | yes | His open palm, and the white streak settling into it: a card with nothing on it. Every other light in the sky goes out at once. |  |
| wl_03 | 0:15.0 | 4 s | yes | Close: under his collarbone the ash-grey broken seal he has hidden all his life blazes with white fire. He doubles over. |  |
| wl_04 | 0:19.0 | 7 s |  | Corin, staring at the card, then down at his own empty hand. | 0:19.4 Corin: "It came to you."<br>0:22.6 Corin: "It just came to you." |
| wl_05 | 0:26.0 | 7 s | yes | Bram shoves through the screaming crowd, his face pale with terror, throws his heavy wool coat over him and closes his fingers over the card. | 0:29.4 Bram: "Close your fist. Don't look at it. Hide it. Now." |
| wl_06 | 0:33.0 | 5 s | yes | The card's glow dies between their hands. His vision swims, and he goes down into the mud. Black. |  |

## 3. The Pale Herald (`herald`), about 101 s

| Shot | Starts | Length | Player A | What's in it | Said over it |
|---|---|---|---|---|---|
| her_01 | 0:00.0 | 8 s |  | Dawn over Ashford: frost on the green, burnt-out paper lanterns lying everywhere like dead moths, the merchant carts in pieces. |  |
| her_02 | 0:08.0 | 6 s |  | Tilly and a small boy picking fallen Sparks out of the furrows, squabbling over them like conkers. |  |
| her_03 | 0:14.0 | 7 s |  | Hob with a fan of glowing cards in his big hands, showing Bram. | 0:14.5 Hob: "Lost half the barley. Found nine cards in the cabbages. Can't tell if that's a good trade." |
| her_04 | 0:21.0 | 6 s |  | The temperature drops. No sound of arrival: it is simply there, hovering inches above the crushed grass, a towering, shifting mass of grey burial cloth and rusted iron chains. The village draws back into a wide, terrified ring. |  |
| her_05 | 0:27.0 | 6 s | yes | Bram's hand comes down on his shoulder (from behind the pair). | 0:28.4 Bram: "A Pale Herald. Morrowen's own. Head down. Hand in your pocket." |
| her_06 | 0:33.0 | 16 s |  | The Herald's empty hood; the pale light in its mist on Ashford's frightened faces. | 0:33.3 Herald: "The Age is turned. The Turning year begins. I am the witness. I record the current holders of the seven Dominion Seats, subject to open challenge. Let the blood of the contenders be counted." |
| her_07 | 0:49.0 | 6 s |  | In its mist, a knight kneeling in a sun chapel (Ser Aldric Vane). | 0:49.3 Herald: "Solhaven, for Solmaris: Ser Aldric Vane." |
| her_08 | 0:55.0 | 6 s | yes | A grey scholar's face in the mist (Magister Tobias Crane); at the name, Bram's hand tightens on his shoulder. | 0:55.3 Herald: "Glyphmere, for Aldrith: Magister Tobias Crane." |
| her_09 | 1:01.0 | 5 s |  | Five more faces in the mist, too quick to hold: a scarred warlord, a young king on an ice throne, a grinning captain, a silk mask in the dark, a blindfolded priestess. The camera stays on Ashford's faces. |  |
| her_10 | 1:06.0 | 6 s | yes | A suffocating heat in his chest: the mark on his collarbone blazes bright white through his shirt. Every head turns. The Herald stops mid-word, and its hood snaps down onto him. |  |
| her_11 | 1:12.0 | 17 s |  | The hood, facing him; its grinding voice stutters, as if the old laws are rewriting themselves. | 1:12.3 Herald: "The Covenant updates. An eighth Seat is forged. The holder of the Last Seal claims this position. Unmarked by any god, until challenged and broken... they are witnessed. I name the Unsworn." |
| her_12 | 1:29.0 | 5 s |  | It dissolves into a thick grey mist, and the mist goes. |  |
| her_13 | 1:34.0 | 7 s | yes | The silence on the green. Tam looks at the ground. Nell quietly pulls Tilly away; the villagers step back from him. Bram steps firmly into the empty space between him and the village. (The game takes over: the Hero note, and Bram.) |  |

## 4. The Reckoning (`reckoning`), about 73 s

| Shot | Starts | Length | Player A | What's in it | Said over it |
|---|---|---|---|---|---|
| rk_01 | 0:00.0 | 8 s |  | Dusk on the green. Hoofbeats: Huntmaster Krell rides in on a heavy warhorse, her bailiffs behind her with torches, a hound of shadow at her stirrup. |  |
| rk_02 | 0:08.0 | 17 s |  | Krell in the saddle, a ledger open in her hand, reading the terms to the gathered village. | 0:08.4 Krell: "Good evening. I hold the foreclosure notes for twenty-two properties in this valley."<br>0:13.0 Krell: "By the authority of Caldus Morne and the House of Ironvault, the terms are as follows. Every roof but the inn's is forfeit tonight."<br>0:19.0 Krell: "Alternatively, you may surrender one card, the white one, and the notes are burned. I will wait five minutes." |
| rk_02b | 0:25.0 | 8 s |  | (new, 3 November) A flash of white, then twenty years ago: Ashford's gate at dawn, snow on the ground. Bram, never his face, snow on his heavy coat and a baby asleep inside it, sets a heavy purse on a trestle. Aurex Morne's clerk counts out four thousand gold crowns, stacks them, and seals a single page. A flash of white, back to Krell. | 0:29.6 Clerk: "Four thousand crowns. Paid in full, and sealed." |
| rk_03 | 0:33.0 | 4 s |  | Nobody speaks. The silence stretches across the frightened faces, Nell's among them. |  |
| rk_04 | 0:37.0 | 12 s |  | Tam steps forward, between her horse and the path up to the inn, and slaps his note down on a rain barrel. | 0:39.0 Tam: "The note says midnight. Take the mill, Huntmaster. It's yours. But you leave the people out of this."<br>0:44.4 Tam: "The one you're looking for, the Unsworn, they fled over the northern ridge hours ago." |
| rk_05 | 0:49.0 | 15 s |  | Krell looks down at the note, then at Tam, and leans from the saddle with a cold, almost sympathetic smile, her eyes on where he's planted his boots. | 0:50.6 Krell: "A brave lie, Miller. But you're a terrible card player."<br>0:54.4 Krell: "You put your body between my hounds and the inn before you even opened your mouth."<br>0:58.6 Krell: "Guards, search every building. Collect every note. If they don't have the coin, take the property." |
| rk_06 | 1:04.0 | 6 s |  | Tam reaches into his coat: not for another note. A worn deck. The crowd gasps. | 1:05.2 Tam: "I challenge the debt, Huntmaster! Under the Covenant, you cannot refuse a drawn hand." |
| rk_07 | 1:10.0 | 11 s |  | Krell, unhurried, closing her ledger. (The game takes over: the cellar.) | 1:10.3 Krell: "Fair enough, Miller. The law states I cannot refuse a duel. But if you wish to go ahead with this, I have the right to set the stakes."<br>1:16.0 Krell: "And to deter anyone else from trying it... we fight to the death. Draw your Essence." |

## 5. Tam's Hand (`tams_hand`), about 33 s

| Shot | Starts | Length | Player A | What's in it | Said over it |
|---|---|---|---|---|---|
| th_01 | 0:00.0 | 6 s |  | The duelling Circle glows gold on the green between them. Tam calls his River Hound out of its card, blue and shining, as she was in your friendly game; Krell's hound of shadow waits. |  |
| th_02 | 0:06.0 | 4 s |  | The shadow hound tears through the River Hound, and she bursts into blue light. |  |
| th_03 | 0:10.0 | 5 s |  | The feedback shatters Tam's Ward. He clutches his chest and goes down, his life drawn out of him by the duel. No blood. |  |
| th_04 | 0:15.0 | 5 s |  | Nell screams, and drops to her knees. | 0:15.6 Nell: "Tam!" |
| th_05 | 0:20.0 | 13 s |  | Krell, giving her orders without looking at him. | 0:20.4 Krell: "The debt is settled. Search every building. Start with the inn. Keep the houses intact; they're worth more standing."<br>0:27.0 Krell: "If anyone interferes, subdue them. I want the white card, not a heap of ashes." |

## 6. No Roof Burns (`no_roof`), about 12 s

| Shot | Starts | Length | Player A | What's in it | Said over it |
|---|---|---|---|---|---|
| nr_01 | 0:00.0 | 12 s |  | From a distant ridge, the moonlit green: two enforcers draw cards. One summons a controlled line of fire that stops the villagers passing and touches no house; the other binds a resisting villager in glowing strands and forces them to their knees. Behind them, soldiers search the houses. |  |

## 7. Solhaven (`ridge`), about 22 s

| Shot | Starts | Length | Player A | What's in it | Said over it |
|---|---|---|---|---|---|
| sol_01 | 0:00.0 | 7 s | yes | From behind him and Bram: they crest the Thornwood's last ridge at dawn; the plains below, and far off Solhaven's white towers, catching the first sun in Solmaris's light. |  |
| sol_02 | 0:07.0 | 6 s |  | Bram, turning to him. | 0:07.3 Bram: "Go through Dask's cards when we stop. Swap in what's nastier than what you've got. That's most of duelling." |
| sol_03 | 0:13.0 | 5 s |  | Solhaven, as close as the eye can get it. | 0:13.4 Bram: "There she is. Solhaven." |
| sol_04 | 0:18.0 | 4 s |  | Bram's face. He doesn't sound pleased. |  |


## 8. Bram's duel in the snow (12 November: it's played now)

The duel in the Night of the White Sky is played by the player in three moves,
so your film of it has two new jobs.

**Three short films, one for each move.** Each plays over the game's own
picture of that move, the moment the player makes it. Until one exists the
game's own shots play, so nothing breaks while you make them.

| Film | Name it | What's in it |
|---|---|---|
| The call | `white_sky_move_1_4k.mp4` | Bram from behind, the child in his coat, his right hand up with a card: the Unspent Hour darts out of the light over his shoulder into the gap where the Scrivener stood. About 3.5 s. |
| The strike, and the pack's answer | `white_sky_move_2_4k.mp4` | The Unspent Hour turns its glass on the Blazehound: the hound bursts into white sparks (4 s). Then the Veilfox's mirage and the Warg's charge bring the Loomwarden down; over Bram's shoulder he staggers, his arm going round the child (4.5 s). |
| The Last Page | `white_sky_move_3_4k.mp4` | Orlanthe comes down out of the stars, the book in one hand, seen low from behind Bram (6 s). The clasp comes undone, the book opens, white light pours out until there is nothing but white (4 s). End on the white. |

No voices, no subtitles, Bram's face never seen. These are the same shots as
`wsd_04`, `wsd_05`/`wsd_06`, `wsd_08`/`wsd_11` and `wsd_15`/`wsd_16` in the
whole film's list (`scripts/story/story_film.gd`), so if the whole film is
already cut, these are three pieces of it.

**The whole film, `white_sky_duel_4k.mp4`,** is no longer shown in the opening.
It plays later, on the Thornwood road: after Bram's lesson, when the player is
under the blanket and Bram is awake by the door, watching the dark. By then the
player knows the rules and can read the duel. Until the film exists that night
goes straight to the morning.

