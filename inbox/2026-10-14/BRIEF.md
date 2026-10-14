# Work brief, 14 October 2026

Gary Mannion's game, **The Covenant War: Throne of Ages** (Godot 4.7). Read the repo's
`README.md` first: it covers the layout, the tests and how to publish. Gary plays every
build on his phone at https://fg29cw8knf-wq.github.io/covenant-war/, so each change has to
be built with `tools/build_web.sh` and pushed to `gh-pages` as well as `main`.

How Gary works: he makes all the art, music, sound and 3D models himself; Claude writes
the code and builds the game. He wants plain-English reports, short, with no jargon.
He wants the dialogue as good as the best of the genre. Tutorials are gated (each
instruction waits until the player has done it, and nothing else can be touched), and the
first duel must be winnable.

His docs (Claude Docs, edited with the Claude Docs connector):
[Still to Make](https://claude.ai/artifact/TK64sPmjjvjfqSU4tjyfSv) ·
[Sound & Music Plan](https://claude.ai/artifact/6a3RJWCRDz4enA5XLZj1XM) ·
[The Spoken Script](https://claude.ai/artifact/2ki6rTJKfqHP3A29RmLXe6) ·
[Master Script](https://claude.ai/artifact/F6HjcnUsP2pTYaJ9n6fq67) ·
[Opening Movie: Your Step-by-Step](https://claude.ai/artifact/7jfX7vfS9gRM71ZozhXJL7) ·
[Ashford: Your Step-by-Step](https://claude.ai/artifact/WqPGLkwPsT58fGLzenDpZU)

This `inbox/` folder has a `.gdignore`, so Godot never imports it. Move each file to its
proper place, then delete `inbox/2026-10-14/` in the same commit.

## 1. Put Gary's new files in the game

All of these have already been checked: they are the right size and nothing is cut off.

| File here | What it is | Notes |
| --- | --- | --- |
| `jagged_shards.png` | Card painting for the Rite `jagged_shards` | 1254 x 1254. Size it like the other cards in `assets/art/cards/`. |
| `shot_09b.png`, `shot_10.png` | Full-size opening-movie shots 9b and 10 (2560 x 1440) | Replace the smaller copies, the same way 7e to 13 went in. These two were cut off last time; these are fine. |
| `defeat.mp3` | The loss sting | It is 48.5 s, but `victory` is a 12.4 s sting. Cut it at a natural phrase ending, about 10 to 15 s, with a short musical fade, at the same loudness as `victory`. Keep the original in `assets/audio/source/`. Tell Gary where you cut it. |
| `duel_alt.mp3` | Second duel theme (2:09.6), so duels alternate with `duel_main` | Loop it seamlessly like `duel_pinch` (`LOOP_START` in `scripts/ui/music.gd` plus a baked tail). Make duels actually alternate between the two. `ashford.gd` lists `duel_alt` as Ashford's fallback music: check that is still what's wanted. |
| `sfx/*.wav` (11) | `card_draw`, `card_flip`, `card_fly`, `card_lift`, `rite_cast`, `shuffle`, `ward_set`, `ward_spring`, `duel_start`, `turn_mine`, `turn_rival` | Into `assets/sfx/`. Check each plays at the right moment and sits level with the six UI sounds already in. (The `fantasy_game_sfx` folder Gary also picked is identical to those six, so nothing to do there.) |
| `blazehound/` | New animated Blazehound: rigged, with 7 clips (`idle`, `run`, `attack`, `hit`, `defeat`, `victory`, `spawn`), one 4096 texture, 11 MB | Replaces `assets/models/creatures/blazehound.glb`. Shrink the texture to match the other creatures and keep the web build small. Play the clips wherever the duel animates creatures. The flame ribbons are alpha-blended, so check they draw properly in the web build. The README has the details. |
| `props/market_stall.glb` | Ashford prop `stall` (Tilly's festival stall), 3.56 x 2.05 x 2.89 m, +Y up, front +Z | Replace the stand-in. Tam's barrel scene must still set the barrel down at this stall. Placement is in the Ashford Step-by-Step. |
| `props/village_well.glb` | Ashford prop `well`, 2.67 x 2.13 x 3.19 m, +Y up, front +Z, crank on the right | Replace the stand-in. Corin waits here and Nell sits here, so make sure they still fit. |

## 2. Ashford's music must play continuously

Gary: the Ashford music "abruptly just restarts when it finishes". At the moment
`ashford_festival.ogg` is cut to 104.1 s and loops back to 35.062 s (`LOOP_START`). Find
out why it still sounds like a restart. It could be a seam that isn't on the beat,
`loop_offset` not working in the web build, or the track starting again from 0 when the
player comes back to Ashford after a duel or a scene. Fix it so it never audibly restarts
on the phone build. The original 140.8 s track is `assets/audio/source/ashford_festival.mp3`.
Send Gary a short "loop seam check" mp3 of the join, as was done for `duel_pinch`.

## 3. Lore change: Sigils form all the time

Gary's decision: the gods' magic is constantly leaking into the world and setting hard as
Sigils. It is not just something that happens every 2,000 years. The Sigilfall at the
end of an Age is a flood; the rest of the time it's a trickle.

Replace Bram's first two `intro` lines in `LESSON` (`scripts/world/areas/ashford.gd`,
the "fell out of the sky two thousand years ago" line and the "frost on a window" line)
with these three. If Gary's message asking for this work gives different wording, his
wording wins:

1. "Right. Those cards are Sigils. The gods' magic is always leaking into the world, a drop at a time, and where it lands it sets hard. Like frost on a window."
2. "These are Sparks, the smallest kind. Ploughs turn them up all the time. Ashford's kept this lot in a box at the inn since before my grandad."
3. "That's the gods on a quiet day, mind. When they fight, it doesn't drip. It pours."

Then search every line in the game (story scripts, Codex text, card text, README) and the
Master Script and Spoken Script docs for anything saying Sigils only arrive every 2,000
years, and make it fit. Already checked and fine: `prologue.gd` line 12, Nell's "one light
… hole in the top field", and the movie narration, which doesn't need re-recording. Put
Bram's new lines in the Spoken Script.

## 4. The first duel (the Lantern Duel tutorial)

a. **The dice.** Bram says "You both roll the die to see who starts", but Gary sees no
roll. Make the roll-off visible and hands-on. Bram says something like "Tap the die to
roll for who goes first. Highest starts." The player taps, both dice roll big on screen,
not behind the dialogue box, and the player still wins (15 against 6, as now). Also make
sure Corin's Fate roll (`CORIN_SCRIPT` turn 2, roll 12) is seen rolling on screen before
Bram's "That's Fate" line.

b. **Card details.** Tapping a card brings up its details, but nobody tells the player.
After the player first taps Brookfin, add a step that spotlights the detail panel (add a
`detail` focus target to `DuelTutor` / `tutor_rect` if there isn't one), with Bram saying:
"That panel on the right is the card up close: its cost, its element and what its moves
do. Tap any card, yours or Corin's, whenever you want a closer look."

c. **What waits until later.** The first duel teaches only what's on the table: Totems,
Rites, Essence, Life, attacking, one weakness (water beats fire), Fate and card details.
Everything else is taught the first time it matters, by Bram, in the same gated style:

- The first time a status effect lands on either side: a short Bram line saying what it
  does and how long it lasts, and the condition gets its Codex entry.
- Wards and the full element chart: at the campfire, when Bram hands over his decks,
  before Dask's road duel. Build this now if Dask's duel already runs on the new duel
  screen; if not, add it to Still to Make for when it does.
- Ascension: the first time the player can ascend.
- A **How to Duel** page in the pause menu that keeps every lesson Bram has given, in
  order, so the player can reread them.

d. The duel must stay unlosable and gated. Re-run `lantern_sim` and
`lantern_tutorial_test`, and play the lesson through tap by tap to check that a wrong tap
never moves it on.

## 5. Test, publish, report

- Run the README's tests (at least `load_all`, `lantern_sim`, `lantern_tutorial_test`,
  `duel_monkey`, `prologue_test`, `ashford_test`, `movie_test`). Take screenshots of
  Ashford with the well and stall in, the new Blazehound in a duel, and the tutorial's dice
  and detail steps, and look at them.
- Build the web version, boot it in a headless browser, then push `main` and `gh-pages`
  and confirm the live link is serving the new build.
- Update the docs: tick everything that went in on Still to Make, the Sound & Music Plan,
  the Opening Movie Step-by-Step (9b and 10 now full size) and Ashford's Step-by-Step; add
  Bram's new lines and any new tutorial lines to the Spoken Script.
- Tell Gary what changed in a few short lines, plus anything he needs to redo.
