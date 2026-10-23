# The Lantern Night and the morning after, as films: your step-by-step

Two of the Prologue's scenes can now play as films of your own clips, the
way the opening movie does, in place of the game's 3D staging of them: the
Lantern Night (midnight: the Great Lantern lit, the lanterns stopping in
the air, the Sigilfall, the cart, the white light) and the morning after
(dawn: the Pale Herald). The game keeps playing its 3D version of each
until the film's clips are all there, so nothing changes until you want it to.

The lines (Master Script v3, `docs/script/v3_prologue_films.md`) stay the
game's own subtitles over the picture, so the two choices in these scenes
still work, and the Herald still speaks the player's name. Your clips carry
the picture and the sound of the world; the Herald's words are your
recordings (`assets/audio/vo/herald_*.ogg`), played by the game at the right
moment, so leave them out of the clips. You can record Morrowen's one line
at midnight ("Midnight. The chapel bell counts twelve...") as
`assets/audio/vo/mid_01.ogg` and the game will play it too.

## What to make

One clip per shot, named after the shot (`mid_01.mp4`, `dawn_07.mov`...),
at least as long as the shot (a longer clip is cut; a shorter one holds on
its last frame), 16:9. Put them in a folder and run:

    python3 tools/movie_clips.py <the folder> --film midnight
    python3 tools/movie_clips.py <the folder> --film dawn

That cuts each to length, drops its sound and saves it where the game looks
(`assets/movies/midnight/`, `assets/movies/dawn/`). A painting instead of a
clip works too: `assets/art/movie/midnight/mid_01.png` and the game moves
over it the way it does the opening's paintings.

**The player is in some shots** (marked *player* below). The player's look
is chosen in the mirror, so either keep the player faceless in those shots
(from behind, hands only, a silhouette against the Lantern) or make one
clip per look, named `mid_02_a.mp4`, `mid_02_b.mp4`, `_c`, `_d`, and the
game plays the one for the look chosen.

If you'd rather cut the whole scene as one film, as you did the opening,
save it as `assets/movies/midnight.ogv` (or `dawn.ogv`): the game plays it
whole, puts the lines over it at their moments and pauses it for the choice
and the name. Keep the shots in this order and at these lengths, so the
lines land where they should.

## The Lantern Night (midnight), 2:33 and the choice

| Shot | Length | What we see | Said over it |
| --- | --- | --- | --- |
| mid_01 | 8 s | The green at night, packed, every face turned up to the unlit Great Lantern; the chapel tower; the bell swinging. | Morrowen: "Midnight. The chapel bell counts twelve, and all of Ashford counts with it." |
| mid_02 *player* | 7 s | From behind: the player climbs the Lantern's steps with a lit taper and touches it to the wick. The Great Lantern catches with a roar, and the whole village roars back. | |
| mid_03 | 6 s | Tam dancing with Nell, badly, in the Lantern's gold light; Ned's fiddle; paper lanterns bobbing in the crowd. | |
| mid_04 | 7 s | Corin beside the player, both watching the crowd; he says it without looking over. | Corin: "It's a good village, this. Don't tell anyone I said so." |
| mid_05 | 10 s | Bram, looking up at the first paper lanterns being readied, their candles lit one by one. | Bram: "Folk think we send them up for the gods. We don't. A lantern's for whoever's out in the dark, so they know which way is home." |
| mid_06 | 6 s | Bram's face, the Lantern behind him, his eyes going up to the stars. | Bram: "Two thousand years. Wonder who'll be sitting up there tomorrow." |
| *the choice* | | The picture holds while the player picks: "Does it matter to us?" / "Whoever it is owes us a better year." | |
| mid_07 | 5 s | Bram, close, the ghost of a laugh. | Bram: "It shouldn't. It always seems to." or "Write and tell them. See who writes back." |
| mid_08 | 11 s | Hundreds of paper lanterns rise over Ashford. Then they stop, every one, hanging in the air as if the night has taken hold of them. The fiddle trails off. One by one, faces turn up. | |
| mid_09 | 5 s | Corin, looking up, then at Bram. | Corin: "Bram. Is it meant to do that?" |
| mid_10 | 8 s | The sky splits from one horizon to the other. Light pours down in every colour. For a breath the children cheer. | |
| mid_11 | 5 s | A strike hits the mill and the thatch goes up. | Nell: "The mill! The mill's on fire!" |
| mid_12 | 5 s | Bram, shouting over the noise, pointing the player at the inn. | Bram: "Inside! Everyone inside! Sprout, the inn. Now!" |
| mid_13 *player* | 9 s | Everyone runs for their doors. Corin grabs Tilly and runs her up the lane past Tam's hay cart. The player runs for the inn (from behind); strikes land all round, and one knocks them flat. | |
| mid_14 | 5 s | A blast on the far side of the hay cart throws it over, onto Corin. Tilly screams. | Tilly: "Corin! CORIN!" |
| mid_15 *player* | 7 s | The player gets up off the ground, sees him, and runs back. Bram is already running too. Corin under the cart's edge, his leg pinned. | Corin: "My leg. It's stuck, I can't, I can't get it —" |
| mid_16 *player* | 8 s | Bram arrives at the cart. He and the player take its top edge, one either side of Corin, and heave; Corin drags himself clear and the cart crashes back down. | Bram: "Other side. On three. One, two —" |
| mid_17 | 6 s | Corin on his feet, limping, trying to make light of it. He isn't all right: his hands are shaking. | Corin: "I'm all right. I'm all right." |
| mid_18 *player* | 10 s | One light falls differently. White. Slow. Silent. It passes Bram. It passes Corin. It stops at the player. | |
| mid_19 *player* | 9 s | The player's hand held out, and the light settles on it: a card with nothing on it. Every other light in the sky goes out at once. Then a white mark burns itself into the back of the hand. | |
| mid_20 | 7 s | Corin, staring at the card, then down at his own empty hand. | Corin: "It came to you." ... "It just came to you." |
| mid_21 *player* | 9 s | Bram crosses to the player and closes their fingers over the card. Its glow dies between them. His hand is shaking too. He looks the player in the eye. | Bram: "Put that away. Don't show anyone. Not anyone." |

## The morning after (dawn), 2:00 and the name

| Shot | Length | What we see | Said over it |
| --- | --- | --- | --- |
| *caption* | | "Dawn" | |
| dawn_01 | 9 s | Dawn over Ashford. Smoke lies over the hills. The mill is a black shell. Children pick fallen Sparks out of the furrows and squabble over them like conkers. | |
| dawn_02 | 8 s | Hob on the green with a fan of glowing cards in his big hands, showing Bram. | Hob: "Lost half the barley and the mill roof. Found nine cards in the cabbages. Can't tell if that's a good trade." |
| dawn_03 | 10 s | A mist comes down the road against the wind. In it walks a grey horse that leaves no prints. Its rider's hood is empty, and it carries a staff topped with a pale lantern. | |
| dawn_04 *player* | 7 s | The villagers kneel without being told. Bram's hand on the player's shoulder brings them down with the rest (from behind the pair). | Bram: "A Pale Herald. Morrowen's own. Head down. Hand in your pocket." |
| dawn_05 | 4 s | The Herald stops at the edge of the green. The empty hood. | The Herald (your recording, 3.4 s): "Hear the Covenant." |
| dawn_06 | 16.5 s | The pale lantern on the staff brightens as it speaks; Ashford's faces, kneeling, lit by it. | The Herald (15.7 s): "The Age of Solmaris is ending. By the Covenant, the Turning begins. For one year, any Seat in Veyl may be challenged by anyone." |
| dawn_07 | 8.5 s | The lantern's light shows a knight kneeling in a sun chapel (Ser Aldric Vane, your painting). | The Herald (8.0 s): "Solhaven, for Solmaris: Ser Aldric Vane." |
| dawn_08 | 8 s | Five more faces in the lantern's light, a name written under each, too quick to hold: a scarred warlord, a boy on an ice throne, a grinning captain, a mask in the dark, a blindfolded priestess. The camera stays mostly on Ashford's faces. | |
| dawn_09 *player* | 6.5 s | The sixth face. At the name, Bram's hand tightens on the player's shoulder. | The Herald (5.8 s): "Glyphmere, for Aldrith: Magister Tobias Crane." |
| dawn_10 | 12 s | The empty hood, and the lantern's light turning towards the kneeling crowd. | The Herald (11.2 s): "And one more. Bound to no god. Holding no Seat. Marked by the Covenant itself." |
| dawn_11 *player* | 7 s | The mark on the player's hand blazes straight through their pocket. Every head in Ashford turns. Last of all, slowly, the empty hood. | |
| *the name* | | The picture holds while the player gives their name. | |
| dawn_12 | 5 s | The empty hood, facing the player. | The Herald: "{name}." then (your recording, 2.2 s) "The Unsworn." |
| dawn_13 | 10 s | The Herald, the staff raised a little, the lantern's light on the player. | The Herald (9.4 s): "Present your mark at the Sun Court of Solhaven before the new moon, or forfeit it." |
| dawn_14 | 9 s | The Herald rides back into the mist, and the mist goes with it. Nobody speaks. Tilly, uncertain, waves at the place where it was. | |

The shots' lengths and what's said over them are in `scripts/story/story_film.gd`
(`StoryFilm.FILMS`): change a length there and `tools/movie_clips.py` cuts to
the new one. The game's own music keeps playing under the shots (the dawn's
`dawn_after`); a whole-film cut brings its own.
