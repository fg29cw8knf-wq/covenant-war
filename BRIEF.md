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
bigger. Do 1 to 10 first, then 11 and 12. Item 13 (the deeper duel) is a
build of several evenings in its own right: Gary has said yes to all of it
(16:27, 23 October), so do it in the phases written there, telling him at
the start of each phase roughly how big it is, and merging each phase to
`main` as it passes so he can play it.

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

## 13. The deeper duel (build it all; Gary said yes to every idea)

> "What ways could we make the card games more in depth and more to it?"
> Then, on the list below: "I want all of those added to the duels, anything
> else I don't mind. Duels being longer or more in depth, just want to keep
> them fun and not so repetitive, more like Yu-Gi-Oh."

So the brief is: every idea below, built; longer duels are fine; the test of
each one is "is there a real choice here, and does the duel feel less like
the last one". Yu-Gi-Oh is the model: a visible turn with phases, chains of
answers, calling the big cards by paying for them, the discard as a second
hand, decks that each play their own way.

What's there now (so nothing is built twice): 3 Totem slots a side, 2 Ward
slots (3 with Cunning 7+), 30-card decks, 5-card hands (limit 10), Life 150,
Essence to a cap of 10, Shift, Rites, Wards (face-down traps), 24 conditions
and 6 boons, Fate dice bands on every move, Guardians, Divine Gifts, Summons
(the five Demigods), Ascension (one stage), Attunement / Resonance / Rank,
Kingdom Laws and Blessings, seven attributes with 7+ perks, equipment on the
duellist. A turn is Dawn (conditions, the Law) → draw → actions → Dusk
(`DuelGame._take_turn`, `_dawn_conditions`, `_dawn_law`, `_dusk`). The pool
is about 93 cards (35 Totems, 41 Rites, 10 Wards, 5 Summons; tiers 1 to 6)
in `scripts/duel/duel_cards.gd`, four starter decks (`DECKS`). The computer
is `scripts/duel/duel_ai.gd` (774 lines): **every new mechanic must be
played well by the computer too, or it's a trick only the player has.**

Where the repetition comes from, and the answer to each: the same four decks
(archetypes with their own support cards, and more cards); every turn the
same shape (phases that matter, Stances, answers on the rival's turn); the
big cards arriving by luck of the draw (Tribute calls, searches, the Favour
meter); nothing to do with a fallen Totem (the discard as a resource).

### How each piece is built

Each mechanic, in this order: the rule in `duel_game.gd` (with its
`action_problem` text, so the screen can say why not); its card data in
`duel_cards.gd`; the computer in `duel_ai.gd` (it must use it, and answer
it); the screen (`duel_screen.gd`: the action, its highlight, the Fate band
and the detail text; the 3D field's effect, `duel_field3d.gd` / `duel_fx.gd`,
to the standard of the rest, never a placeholder); its Codex entry; a gated
one-off lesson the first time it matters, in Bram's words (`DuelTutor.lesson`,
`Game.learn`, onto How to Duel); the Duel Lab's tuning panel; then balance:
`duel_sim 2000` (`0 invariant errors`, no deck over ~60% against the field),
`deck_rate`, `condition_probe` for anything with a number, `duel_monkey`,
`law_sim`, `patron_sim`, `rewards_test`, `story_rules_test` (the story
duels' rules and tutorials must still hold: the Lantern Duel still can't be
lost, `lantern_sim`; the Trial's puzzle still has its one answer,
`trial_puzzle_test`). The deck screen (`PauseMenu` Deck) must build and show
any new card kind. New cards need Gary's paintings: write each new card's
prompt into `docs/card-prompts.md` in the kit's format and tell him which are
needed; the drawn placeholder stands in until then.

### Phase A: the turn, and answers on the rival's turn

- **Phases shown**: Dawn · Draw · Main · Clash · Dusk, named on the screen as
  the turn moves (a small band under the rival's panel), with the rules
  that only work in one phase saying so. Clash is where attacks happen;
  Main before it is for calls, Rites, Wards, Stances; a second short Main
  after Clash for a Rite or a Shift (as Yu-Gi-Oh's Main Phase 2).
- **Stances** (idea 4): every Totem of yours is set each turn to Strike,
  Guard (takes half damage, can't attack) or Rest (regains 20 Life and gives
  you 1 Essence; can't attack or be Shifted). Free; the stance shows on the
  Totem's card and its model (a guard pose, a rest pose: new clips or holds
  on the creature models, `Figure3D`-style). The computer picks stances.
- **Counter Rites** (idea 5): a Rite marked `"answer": true` can be played
  on the rival's turn when they declare an attack, play a Rite, call a Totem
  or set a Ward. The engine gets a **response window**: after the action is
  declared and before it resolves, each side in turn (the rival first) is
  asked `choose_response(game, pi, event, cards)`; an answer can be answered
  (a chain, resolved last-in first-out, capped at 4 deep, each step shown on
  the field as a link of light). The screen: a "Respond?" strip with the
  answers you hold, a countdown bar (6 s, pause-able), and a "Let it be"
  button; Options has "Ask me to respond: Always / Only when I can / Never
  (auto-pass)". Wards stay the traps (they spring by themselves). Eight
  Counter Rites across the elements to start (negate an attack, halve it,
  redirect it to a Guardian, bounce a Rite, a free Shift, +1 Essence when
  they call, draw a card when they Ward, cancel a Ward as it springs).
- **Hand Wards**: two Wards in the pool that can be played from the hand in
  answer (once each a duel) — the hand-trap moment.

### Phase B: calling the big cards, and the discard

- **Tribute calls**: a Totem of tier 3 and up (Legend and above) costs its
  Essence *and* one Totem of yours sent to the discard (tier 5 and 6, two).
  The call becomes an event (the sacrificed Totem's light goes into the new
  one on the field). Rites that call a tier-3 for free with a condition are
  the exception that makes it exciting.
- **The discard as a resource**: Rites that return a fallen Totem to the hand
  or straight to the field (a Revival at a cost); Totems with an **Echo**
  that works from the discard (once, when a condition is met, e.g. "when a
  Totem of yours falls, Cinderpup's Echo deals 10 to the attacker"); a Rite
  needing three fallen Totems of one element to work (a Rite of Ashes). The
  discard pile shown on the screen as a tappable stack (it isn't now).
- **Special calls**: `"on": {"ally_falls": ...}`-style card triggers: a Totem
  that calls itself from the hand free when one of yours falls; one that
  flips its effect when it's hit; one that comes back at Dawn once. Data
  on the card, resolved by the engine, shown by the screen.
- **Searches and draws**: Rites that search the deck for a Totem of an
  element (shown as the deck fanning), that draw two, that put a card from
  the discard on top of the deck. Decks that can find their pieces play
  less by luck and feel designed.

### Phase C: what Totems are, and build round

- **Bonds** (idea 1): a `"bond"` field on a Totem naming another; both on
  the field together unlocks a bond move (shown as a fourth move with both
  names) or a boon on both. Twelve pairs to start, one or two per element
  pair; the Codex shows a card's bond partner.
- **Relics** (idea 3): a new card kind, `"relic"`: attaches to a Totem of
  yours (one each), stays, gives a move, a boon or a stat, lost when the
  Totem falls (into the discard with it; a Rite can fetch it back). Ten to
  start. The Totem's card shows the relic's band; the model carries it
  where it can (a collar, a glow).
- **Veiled calls** (idea 7): a Totem can be called face down for +1 Essence
  (the rival sees a Veiled card on the slot, its back); it is revealed when
  it attacks, is attacked or at your next Dawn; some Totems have a **Reveal**
  effect (flip effects). The computer veils when it has a Reveal.
- **Two-stage Ascension** (idea 9): tiers 3 and up can Ascend twice (Spark →
  Ember → Blaze: three card ids, three paintings per line), the second
  stage needing the first on the field for a turn. Eight lines to start.
- **Tempering** (idea 8, Gary's rule): a duplicate re-absorbed on the Codex
  marks that card for good: first +20 Life, second one Fate band wider on
  its first move, third a new move; three at most, shown as marks on the
  card's frame; the story's "upgrade card manifests from a duplicate".
  Bram teaches it in the campfire duel (item 8).

### Phase D: the ground, the gods, and the stakes

- **Arena rules and Terrain Rites** (idea 2): each arena (`assets/art/arenas/`:
  ashford, emberforge, ironstone, solhaven, tidegrove, veilwild) a standing
  rule at Dawn (the tidegrove Soaks a random Totem, the emberforge Burns a
  Ward as it springs, ironstone's Guard is +5, the veilwild veils the first
  call free, solhaven gives whoever has fewer Totems 1 Essence, Ashford's
  green nothing: the beginner's Circle); five **Terrain Rites** that change
  the ground to an element's arena for three turns (the field's look changes
  with it: the Circle's floor shader, the sky, the lights, to the standard of
  the rest).
- **Continuous Rites**: a Rite that stays on the field in a slot of its own
  (two a side) with a standing effect (all Fire Totems +10, every Ward costs
  1 more), removed by a Counter Rite or when it's replaced. Six to start.
- **Favour** (idea 6): a meter (0 to 10) that fills as you play your sworn
  god's element and way (the Law's own actions count double); full, it
  opens a window for a second Gift or a free Summon of your god's Demigod,
  then empties. Unsworn fill it from any element, at half pace, for Unbound
  Will's stronger form. Shown as a ring round your god's seal on the panel.
- **Oaths** (idea 10): at the start of a duel (and once mid-duel, from the
  Menu), swear an Oath — win by turn 8; win with a Totem of your god's
  element; never let your Life under half — for a reward in Resonance and a
  Favour head start; break it and pay Life. Shown on the panel; the rival's
  barks notice it. The computer swears sometimes.

### Phase E: decks that play differently

- **Archetypes**: each god's element pair gets a named way of playing with
  support cards that only work in it (Emberstorm's burn-and-gamble, Tidegrove's
  outlast-and-heal, Ironstone's guard-and-counter, Veilwild's veil-and-reveal,
  and three more for the elements without a deck), so every deck is its own
  puzzle. About 40 new cards across the phases above (Counter Rites, Hand
  Wards, Relics, Terrain and Continuous Rites, Echo and Reveal Totems, bond
  pairs, Ascension lines): their prompts for Gary in `docs/card-prompts.md`.
- **No new starter decks** (the story gives Bram four boxes); the new cards
  come to the player as the story goes, through Resonance rewards, duel
  rewards and Tamsin's stall (Still to Make, 13: crowns), so each chapter
  changes what a deck can be.
- The computer: a deck's archetype tells `duel_ai.gd` how to play it (a
  plan per archetype: what it's trying to do, what it holds back for an
  answer), so the rival feels like a different duellist each time.

### Keep

- A duel still ends: `max_turns` 60 stays, fatigue stays; watch the average
  duel length in `duel_sim` (aim 12-20 turns, not 40).
- The phone's frame rate and the duel's load time.
- The Duel Lab plays all of it; the rules doc ("Duel Rules v2" Claude doc,
  `docs/`) updated as each phase lands, and the tutor's lessons in order.

## 14. After everything

- Still to Make doc updated (items 1-13, the asks for Gary: the get-up clip,
  the card-box model, the summon clips list, the voice line sheet).
- `docs/handover/2026-10-23-pm.md`.
- The four-look play-through, the headless tests, `web_fit_check`, the phone
  link published, the apps rebuilt from `main`.
