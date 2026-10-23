# Brief, 23 October 2026 (afternoon): Gary's phone play-through, round two

Gary owns the game and is non-technical: write to him in plain, short English.
Read `README.md`, then `docs/handover/2026-10-23.md` and `2026-10-18.md`
(one session at a time; ask before anything big; one or two agents at most).
Keep his to-do doc current ("Still to Make: The Covenant War",
https://claude.ai/artifact/TK64sPmjjvjfqSU4tjyfSv): add the items below to it
in game order and tick them as they land.

This brief was written in a chat session that only read the code; nothing
below is built yet. Work on this branch (`wip/feedback-23oct`), merge to
`main` when it's checked (delete this file on the merge, as the 22 October
brief was), publish the phone link to `gh-pages`, and write
`docs/handover/2026-10-23-pm.md`.

Gary's standing rules apply to all of it: every change built to the best look
and flow Godot can give; afterwards the play-through as all four looks
(`tools/play_all_looks.sh <dir>`, `PARTS=opening` then `PARTS=solhaven`) with
the stills looked at, the headless tests, and the web build published so the
phone link matches `main`. Items 1 to 10 are bugs and feel; 11 to 14 are
bigger. Do 1 to 10 first, then 11, and ask Gary before 12 to 14 if any of
them looks like more than an evening.

Gary's words are quoted as he sent them from his phone.

---

## 1. Getting out of bed (P1, the attic)

> "Getting out of bed - still not great, bed sheets move on their own and part
> of character goes through the bed. Can we improve this at all?"

Where: `AshfordP1.opening()` (`scripts/world/areas/ashford_p1.gd` ~1184-1222):
`reach()` for the hand, `sit_long()`, the blanket tweened as one rigid mesh to
`blanket_off`, `sit()` + `let_go()` + `shift_seat()`, `stand()`, then the body
tweened to `bed_side`. The poses are built on the idle (`Figure3D._sit_as`,
`lie_on`, `LIE_HEAD_UP`), not a clip, which is why the legs pass through the
mattress as he turns and the blanket slides off by itself.

Do:
- The blanket must move because he moves it. Hang its near corner on his
  hand (a `reach()` target on the blanket's edge, the mesh following that
  corner: skin the `_blanket_mesh` to two or three bones (head end, hand
  corner, foot end) and drive them from the figure, or at the least tween the
  corner with the hand and let the rest trail) so it is thrown back by the
  hand that pushes up, not on a timer.
- Nothing through the bed: during `shift_seat` the hips swing through the
  frame. Keep the body above `lie_top` / `edge_top` every frame (a clamp in
  `shift_seat`, or lift the hips on the turn and come down on the edge), and
  check it with `tests/bed_check.tscn` from the side and the foot, every look.
- The real fix is a clip. Ask Gary for one more single-clip AssetFurnace file,
  "lying on his back, sits up, swings his legs over the side, sits, stands"
  (about 5 s, the shared skeleton), as he made Corin's walk; `rig_character.py`
  fits it to every look like the others. Until it comes, the procedural one
  above, as good as it can be made. Note the ask on the Still to Make doc.

## 2. Bram walks through the player at the Lantern (P1, the green)

> "When walking up to the pole with the crate Bram walks straight through the
> player."

Where: `AshfordP1._green()` (~1607): `Cine.path(player → spot, 1.4)` and
`Cine.path(bram → bram_to, 1.6)` start at the same moment; Bram comes from
behind, faster, to a mark beside the player's, and his straight line crosses
the player. `Cine.route` goes round `Cine.blockers` (props), "never people".
Also `AshfordP1._follow_step` walks straight at the player and never gives
way if the player turns and walks into him.

Do:
- `Cine.route` / `Cine.path`: take moving people as blockers too (the player
  and any figure standing on the set, radius ~0.45 m), re-routed each leg; a
  walk ends at its mark whatever. Bram's walk here should also leave after the
  player's (a beat) and arc wide on his side (`side`), so the two never share
  a line.
- `_follow_step`: a personal-space radius. If the player is within 0.6 m of
  Bram, Bram steps aside / back rather than being walked through.
- Check: `tests/route_test.tscn` (add a case with a standing figure in the
  way), and `ashford_test opening keys` as all four looks, the stills of the
  walk to the Lantern.

## 3. Every line waits for a tap (everywhere)

> "The text before the cutscene carries on before you click, so not enough
> time for everyone to read it."
> "All text you need to have to click, otherwise it's going too fast."

Where: `CineOverlay.say()` (`scripts/world/cine_overlay.gd` 360-393): `auto :=
true` moves a subtitle on after `READ_BASE + READ_PER_CHAR` seconds. `caption()`
(441) hides a title card after `secs` (2.6). `Cine.say` / `Cine.caption` are
the callers throughout `ashford.gd`, `thornwood.gd`, `solhaven/films.gd`,
`solhaven.gd`. The conversation box (`DialogueBox`) already waits for a tap.

Do:
- `auto = false` is the rule: a subtitle, a caption and a narration line stay
  up until tapped (E / Space / Enter / a pad's A), with the "TAP TO CONTINUE"
  hint after a moment, exactly as the duel's rule banner does since last
  night. The one exception: a line with a voice recording playing (item 12,
  and the Herald / Solmaris / Morne lines already voiced, `films.gd _voice`)
  moves on when the voice ends; a tap during it skips to the next.
- Lines with `"during": <scene>, "at": <words>` still start their scene as
  the words type; the wait comes after.
- A whole-cut story film (`StoryFilm` over an `.ogv`) keeps its timed
  subtitles; those are over video and can't wait.
- Options: a "Lines wait for a tap" switch is NOT wanted; Gary wants the tap
  always. Keep "Text speed" as the typing speed only.
- Tests drive `_next` (the film tests' `read=`, `screen_fit_test` sets
  `ov.auto = false` already): every test that plays through lines must tap
  them, as `ds.tap_banner()` does for the duel. `film_test` for every part,
  `ashford_test`, `solhaven_test`, `side_quests_test`, `controls_test` must
  pass after.

## 4. The fall looks blocky (the Sigilfall, the run)

> "Cut scene when the characters fall over looks very blocky."

Where: `Ashford._the_run()` (`scripts/world/areas/ashford.gd` ~1483-1530):
`(pf as Figure3D).act("fall")` straight out of a run with `blend` 0.2; Corin
under the cart `pose("fall", CORIN_DOWN)` / `resume(CORIN_UP)` (~1589-1651);
Tam's fall backwards (~2625-2660, his `death` clip). The `fall` clip is a
shared one (`characters/clips/shared.glb`) fitted to each body by
`tools/rig_character.py`.

Do, in this order, and look at it with stills every 2 frames
(`film_test midnight 2 keys` round the strike):
- The clip itself: its key count and interpolation after `rig_character.py`
  (AssetFurnace exports 30 fps; if the fit resampled it low, or Godot imports
  it with linear keys at a low `animation/fps`, it steps). Make sure every
  clip comes through at full rate with smooth interpolation.
- The join: run → fall with a longer blend (0.35-0.45 s), the run's pace
  easing to 0 over the same time, so the body doesn't snap; the figure's root
  settling on the ground (`Cine.ground`), never under it; the camera's
  `Cine.follow` lag not jumping as the figure stops.
- On a phone the strike's shake + burst + flash + the figure change in one
  frame reads as a hitch: spread the shake and the burst over two or three
  frames and drop the particle count on `phone` quality.
- Same treatment for Tam's and Corin's falls.

## 5. Things coming to the player look blocky

> "When item comes to the player looks very blocky."

Candidates (check each in stills, fix all that are rough):
- Tilly's Lantern Moth crossing to the player's hands on "You keep it"
  (`Ashford._tilly_hands_over`, ~1036): a card quad on a tween; give it a
  proper eased arc (ease in-out, a slow spin, scale from her hands to the
  player's, 60 fps on the apps), and the player's hands coming up to meet it
  (`reach()`), not a straight slide.
- The card / deck reveal (`DeckReveal._draw`, `scripts/ui/deck_reveal.gd`):
  the card art is drawn scaled up from the 640-wide paintings and the fan
  snaps in. Draw with the biggest source (`assets/art/cards/` full size if a
  larger one exists; filter on), ease the fan in card by card, and a soft
  glow, not stepped rays.
- The crate into the player's arms in the taproom (`AshfordP1._crate_in_arms`)
  and any `{"item": ...}` toast: same look.

## 6. Corin has a hole in his back

> "Corin has a hole in the back of him."

Where: `assets/models/characters/corin.glb` (20 October, body from his
single-clip walk file, clips from the 18 October model; one mesh, 19,997
triangles, one material, single-sided like everyone's).

Do: render him from behind (`tests/model_sheet.gd -- <dir> corin`, and a
still from behind on the green). Either triangles are missing or a patch has
its winding flipped (culled from behind). Fix: if the 18 October body
(`git show 0afe166:assets/models/characters/corin.glb`) has no hole, rebuild
from that body with his own clips (`rig_villager.sh corin`); else flip the
bad patch's winding in `tools/rig_character.py` (detect triangles whose
normal points inwards) or, last resort, `cull_mode = CULL_DISABLED` on his
material. Check every other model from behind while at it.

## 7. Bram's arm goes through his card box (P1, the green)

> "When Bram holds his box of cards his arm goes through it."

Where: `Ashford._card_box()` (770) is a 7.5 x 10 x 4 cm box put on his
lantern-hand point by `_hold()` (796): `hand_light(node)`, offset
(0, 0.06, 0.04). His hand keeps the lantern-carrying pose, so the fingers
pass through it.

Do: hold it in two hands, like Tilly holds the moth's card (`reach()` with
two targets on the box's sides), the box a little bigger and in front of his
chest; when he holds it out to the player (407, 926-945) the hands go with
it. Ask Gary for a card-box model (a worn wooden deck box, brass corners) for
`assets/models/ashford/card_box.glb`; `_card_box()` picks it up when it exists.

## 8. Bram duels you after he gives you your deck (the campfire)

> "When Bram gives you the deck of cards he should do a duel with you and
> teach you more of the game mechanics. When he shows you how to use your
> deck he should also explain about upgrading cards and about the different
> tiers. After you pick your deck from Bram he should pick one to battle you
> with."

Where now: the deck is chosen at the campfire (`Thornwood._camp`, flag
`bram_deck`), the pack tour follows (`PackTour.CAMP_DECK`), and the practice
round is the next morning, optional ("Practice round before we walk?",
`Thornwood._morning` ~538-620, `Prologue.practice_duel_spec`: Bram always
plays `ironstone`).

Do:
- Move the practice round to the campfire, straight after the deck choice and
  the pack tour: Bram puts the other three boxes back, keeps one out — one
  he picks against the player's choice (a deck that shows the player's deck's
  weakness, so the lesson lands; a table in `practice_duel_spec`) — and says
  so. It's the second gated lesson duel (`spec.lessons`, `DuelTutor`), it can
  be lost (the story goes on; his line either way), and it's not optional
  (Gary: "he should do a duel with you").
- In it, taught once each the first time it matters, in Bram's words (Master
  Script v3 voice; adult, in-depth, never cheesy): the seven tiers (Spark to
  Divine) and what a tier means in a duel; upgrading cards: Attunement and
  the Attunement bar, Ascension, and what duplicates do (Re-absorb and Pour on
  the Codex; the story's rule is that a duplicate is re-absorbed to make an
  upgrade card for that creature); Rites and when to spend Essence on one;
  Wards (set and sprung); Shift; the Fate bands on a card. The lines go in
  `LESSON` / the tutor's one-off lessons (`README` "The Lantern Duel is a
  gated tutorial"), and every lesson onto How to Duel.
- The next morning then has no duel: see item 9.
- Keep saves working (`practice_on`), `lantern_sim`-style balance for the new
  pairing (winnable at 0.35, not a gift), `film_test camp`, `solhaven_test`.

## 9. More build-up between Bram's duel and Dask's

> "Think we need more of a build-up after battling Bram before the person
> runs into us and straight into another duel."

Where now: `Thornwood._morning` (the second day) then `_road` (Dask).

Do: the second morning becomes the build-up, written as story, not filler
(Gary's rule: every scene has a point). The shape to write: the walk out of
the Thornwood as a staged film with the player on foot — Bram on what the
refugees on the road are fleeing and what the Sun's Court is; signs of Dask's
riders (tracks, a burnt waystone or a dead hound, the baying far off); a
short choice that matters (hide the blank card or carry it openly, feeding
Standing); a breath on the ridge with Solhaven in sight; then Dask's riders
come up the road behind them, and the road duel. Write the lines first, in
Master Script v3's voice, into `docs/script/v3_prologue_films.md` and the
Master Script doc, and **show Gary the words in chat before staging any of
it**. Then stage it (`Cine`), with the cameras checked (`clear_cam`), the
music cue (`thornwood` under it, `duel_pinch` as the riders come), and the
`pro_part` flag so a closed game picks up.

## 10. Smaller things seen on the way

- Bram's hand clips: check every `hand_light` prop (lanterns, the box, the
  lamp) in all four looks' stills.
- The crate: `carry_check.tscn` as all four looks after item 2.

---

## 11. Summon videos (the duel)

> "Can we create a video that plays when you summon - first time you summon
> that character it plays a longer video, after that just a brief one - or
> have a toggle at the top: show full summon videos / short summon videos /
> none."

Where: `DuelScreen.fx_summon()` (`scripts/duel_ui/duel_screen.gd` 2343): the
2D `SummonCine` (the sky scene + cut-out, 3.2 s) then
`DuelField3D.summon_descend` (the model comes down). Calling a Totem has its
own fx (`fx_call`); Ascension its own.

Do (the engine side; Gary makes the clips):
- A clip plays when it exists, for any card: `assets/movies/summons/<card
  id>_full.ogv` and `<card id>_short.ogv` (Theora 1280x720, from his masters
  with the `ffmpeg` line in README; the apps can also carry his masters as
  `.mp4` on the `films` release through the native player, `NativeVideoPlayer`,
  as the opening does — do that for the apps, Theora for the phone link). A
  card with no clip keeps today's SummonCine.
- The rule: the first time a card is summoned or called in this save plays
  `_full` (flag per card, `Game.learn`-style, `summon_seen`); every time
  after, `_short`. A tap skips either.
- Options: "Summon videos: Full / Short / Off" (saved), and the same three on
  the duel's Menu (☰) so it can be changed mid-duel. Off plays SummonCine.
- The video sits over the field between the sky's flash and the landing, the
  music ducked, the landing effects after it.
- Web: each clip is its own pack (`tools/web_packs.py`: `summon_<id>`),
  fetched the first time that card is summoned, with a loading bar that can
  be skipped (as the movie's); the apps carry them all.
- Write `docs/script/summon_clips.md`: which cards, lengths (full 8-12 s,
  short 2-3 s), what each should show, named by card id, for Gary to make.
  Start the list with the four Demigod Summons and every starter Totem.

## 12. Voices in the cutscenes (everywhere)

> "With cut scenes, what if we used actual voices instead of just text? Then
> people wouldn't have to click through unless they wanted to skip."

Where: `Solhaven films.gd _voice()` already plays a recording with a line and
holds the subtitle for its length; the Herald, Solmaris, Morne and Morrowen
have files in `assets/audio/vo/`. Everything else is text.

Do (the engine side; the voices come from Gary):
- One general way: `Cine.say(w, who, text)` looks for a recording by a stable
  line id (speaker + a hash of the words, or an explicit `"vo": "<id>"` on the
  step) under `assets/audio/vo/<who>/<id>.ogg`; found, it plays it, holds the
  line for its length and a tap skips; not found, the line waits for a tap
  (item 3). The conversation box (`DialogueBox.say`) gets the same lookup.
- `tools/vo_sheet.py`: writes every spoken line in the game, in game order,
  with its id, speaker and the words, to `docs/script/vo_lines.md` (and a CSV),
  so Gary (or a voice tool he chooses) can record them and drop the files in
  by name; `tools/vo_master.py` extended to level and place them by id.
- Nothing recorded by the session: Gary decides who voices whom (he has
  recorded Morrowen and the Herald himself; his earlier decision was that
  only the narrator, the Herald, Solmaris and Caldus Morne were voiced, and
  this is him changing that; ask him whether all characters now, or the
  cutscenes first).
- Web: voice files go in the pack of the part they belong to (`web_packs.py`);
  watch the main pack's 100 MB.

## 13. Making the card game deeper (design; nothing built until Gary picks)

> "What ways could we make the card games more in depth and more to it?"

What's there already: 3 Totem slots a side, 2 Ward slots, 30-card decks, Life
150, Essence (cap 10), Shift, Rites, Wards, 24 conditions and 6 boons, Fate
dice bands, Guardians, Divine Gifts, Summons (Demigods), Ascension,
Attunement/Resonance/Rank, Kingdom Laws and Blessings, seven attributes with
7+ perks, equipment in three slots on the duellist.

Ideas, each a real decision every turn or a reason to build a deck a certain
way (not more numbers):
1. **Bonds**: two named Totems on the field together unlock a bond move or
   boon (Cinderpup + Blazehound). Decks built round pairs.
2. **Arena rules and Terrain Rites**: each arena has a standing rule (the
   tidegrove soaks every Totem at Dawn; the emberfield burns a Ward that
   springs), and a Rite can change the ground mid-duel to your element's.
3. **Relics on Totems**: a card that attaches to a Totem (a blade, a charm)
   and stays — one per Totem, lost with it.
4. **Stances**: each turn a Totem is set to Strike, Guard (half damage, no
   attack) or Rest (regains Life and 1 Essence); a choice every turn, free.
5. **Counter Rites**: a Rite marked "in answer" can be played on the rival's
   turn when they attack or play a Rite — a "Respond?" window, the duel's
   first interrupt (Wards stay the traps).
6. **Favour**: a meter that fills as you play your sworn god's element and
   way; full, it opens a second Gift or a Divine Summon window. Unsworn fill
   it from any element, slower.
7. **Veiled calls**: a Totem can be called face down, revealed when it
   attacks or is hit — hidden information for the rival's reads.
8. **Tempering** (Gary's own rule): a duplicate re-absorbed gives that card a
   permanent mark (+Life, then +a Fate band, then +a move), three at most;
   shown on the card. Teach it in Bram's duel (item 8).
9. **Two-stage Ascension** for the Legend tier and up (Spark → Ember →
   Blaze), each stage its own art.
10. **Oaths mid-duel**: swear to win by turn 8 or with a Totem of your god's
    element for a reward; fail and pay.

For Gary: pick the ones he wants; each goes through `duel_sim` balance
(2000 duels, `0 invariant errors`), `duel_monkey`, its Codex entry, its
tutor lesson the first time it matters, and the Duel Lab.

## 14. After everything

- Still to Make doc updated (items 1-13, the asks for Gary: the get-up clip,
  the card-box model, the summon clips list, the voice line sheet).
- `docs/handover/2026-10-23-pm.md`.
- The four-look play-through, the headless tests, `web_fit_check`, the phone
  link published, the apps rebuilt from `main`.
