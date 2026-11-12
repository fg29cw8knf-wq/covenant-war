# The Covenant War: Throne of Ages

A story-led creature card-battle game. The god-throne of Veyl has come to the end
of its two-thousand-year reign, seven gods are fighting for it, and their power
has crystallised in the mortal world as **Sigils** — cards that let their bearers
summon **Totems** and duel in the gods' name.

Built with **Godot 4.7** for iPhone, iPad, Mac, PC and the web.

## Project layout

| Folder | What's in it |
| --- | --- |
| `scripts/core/` | The rules engine: elements, gods and attributes (`lore.gd`), every card and deck (`sigil_db.gd`), and the duel itself (`battle_game.gd`). No graphics code — it runs headless. |
| `scripts/ai/` | The computer opponent. |
| `tests/` | Headless tests. `sim.gd` plays thousands of AI-vs-AI duels and checks the rules never break. |
| `assets/art/` | The painted art, sized for the game: `cards/` (card paintings, 640 wide), `creatures/` (transparent battlefield cut-outs), `summons/` (Summon cut-outs and their sky scenes), `arenas/`, `gods/`, `card_back.jpg`, `icon.png`. Files are named by card id (see `scripts/duel_ui/duel_art.gd`); anything missing falls back to drawn placeholders. Prompts: `docs/card-prompts.md`. |
| `assets/sfx/` | Sound effects (`cry_<kind>.wav`, `cry_<summon>.wav`: the creatures' stand-in voices, `tools/make_cries.py`; `step_<ground>.wav`: footsteps, `tools/make_steps.py`; `amb_<name>.ogg`: each place's bed of sound, `tools/make_ambience.py`). |
| `docs/` | Art prompts and design notes. The full story and world guide lives in the project's Claude doc. |

## Gary's standing rule (22 October): every update is built to the best look and flow

Every session leaves the game looking and playing as well as Godot can make
it, not just working. **Look**: Forward+ on iPhone and Mac is the target (the
phone link's compatibility renderer is the floor): baked lighting
(`LightmapGI`) for the villages, reflection probes on gold and metal, normal
and roughness maps derived from Gary's colour textures, soft filtered sun
shadows, one colour grade per place, depth of field for the dialogue
close-ups where it helps, animation blending and small idle motion on the
figures, with the phone's frame rate and the first-launch time kept. Ashford
first, as the showcase, then wherever the player goes next. **Flow**: nobody
floats, sinks, pops or waits on nothing; every cut and camera move is
deliberate; the gated steps always say what to do. After each update: the
play-through as every look (`tests/ashford_test.tscn -- <dir> opening
look=<a|b|c|d> keys`, and the rest of the game as each) with its stills looked
at. (2 November, Gary: "don't worry about doing the phone link, just the
Mac version and the one for the phone through Xcode". The web build isn't
built or published any more; the Mac app and the iPhone app's Xcode project
rebuild themselves on every push to `main`, from the `mac` and `iphone`
releases, and are what he plays. `tools/build_web.sh` and
`tools/publish_web.sh` stay for when he wants the link again.) The look
pass started on 5 November (Gary: "Make the game look visually as amazing
as possible"), below; what's left of it is at its end.

### The look pass (5 November)

Gary (5 November): "Make the game look visually as amazing as possible."
The first part of the look pass the standing rule asks for. Each change is
on a switch, and each was seen in stills before and after
(`tests/look_shot.tscn`, below).

- **Normal and roughness maps from Gary's own paint.** His prop and
  building models (the inn, the three cottages, the well, the stall, the
  Great Lantern, the hay cart, the merchant cart, the barrel, the crate, the
  sacks, the two oaks, the stone wall, the fence, the windmill's tower, the
  watermill and its wheel, the shelter's shelves) came with one painted
  colour atlas each and a flat roughness. `tools/derive_maps.py` reads the
  fine shape back out of the paint (the grain of the planks, the mortar
  between stones, the bark's ridges, the weave of the thatch and the
  sacks), with the broad painted shading taken off first so nothing comes
  out as a false slope (paint with very little in it kept a little
  shallower, `SPREAD_FLOOR`: the inn's whitewash has faint stone blocks
  painted in, which come out as whitewashed stone, not lumps), and
  writes `<id>_normal.png` and `<id>_mr.png`
  (how rough in green, how metal in blue) beside the model,
  VRAM-compressed (about 1 MB a 1024 map; the inn's is 2048). The iron of
  the barrel's hoops, the cart's tyres and the crate's corners is metal
  (`--metal`: the dark grey swatches; the cart's rust spots stay rust).
  `LevelKit.dress_models()` puts them on the models' own materials once,
  before a place is built (`World._build_environment`,
  `AshfordVillage._build`), so every copy of a model wherever it's loaded
  has them (the village, the films, the Thornwood, Solhaven's carts and
  sacks). Normal strength `LevelKit.MAP_NORMAL` 0.6: a touch, not plastic.
  On the Compatibility renderer only the normal map goes on: there a
  material with colour, normal, roughness and a glow map (the houses' lit
  windows) put out every sun shadow in the picture (Godot 4.7.2; each map
  alone with the glow is fine), `LevelKit._mr_ok`. Off:
  `LevelKit.maps = false`. A new model: `python3 tools/derive_maps.py
  assets/models/ashford/<id>.glb [--metal]`, then add its id to
  `LevelKit.MAPPED`. Not for characters: their atlases are thousands of
  small islands and would come out with a seam round each; a character's
  normal map comes from the maker's own file (`tools/add_normal_map.py`,
  as Player A's).
- **One colour grade per place and time.** A gentle grade over the
  finished picture (the environment's colour correction: a curve for each
  of red, green and blue, one lookup a pixel, on every renderer):
  Ashford's morning warm gold (the whitewash cream, not blue-white), the
  festival evening amber, midnight blue-white (blue in the shadows, the
  lanterns still warm), the morning after smoky rose, the night Ashford
  burns, the Thornwood green and cold, Solhaven white-gold in its
  highlights (its shadows left alone, so its night and vaults keep their
  blue). `AshfordVillage.GRADES`, blended with the sunset as
  `set_daylight` moves (`set_grade`), set by `set_time`; Solhaven's laid
  on its own set by `World._grade_place`. By day the glow takes only
  what's truly bright (`GLOW_DAY_THRESHOLD` 1.6: the sunlit whitewash had a
  haze round it), at night every lantern blooms (1.0 as built); the sun's
  shadow edges are softer by day on Forward+ (`SUN_ANGLE` 1.2 degrees, the
  moon's 0.6). Off: `AshfordVillage.grading = false` before the place is
  built.
- **Heads turn to whoever's talking.** A figure near someone talking
  (`talking`, set by every line in the world and in the films) turns its
  head to them, and the one talking to whoever's nearest in front of them:
  the neck and head sharing the turn (`LOOK_NECK`), at most 50 degrees
  aside and 16 up or down (Bram looks down at Tilly), eased in and out
  over a third of a second, only within 4.5 m and in front (no owl turns),
  laid over the clip so they still breathe and gesture. Never in a clip a
  scene asked for (act, hold, pose), lying down or sat up in bed
  (`Figure3D._free_to_look`). `Figure3D.HeadTurn`, a skeleton modifier.
  Off: `Figure3D.looking = false`.
- **A reflection probe in the inn's rooms** (`AshfordVillage._room_probe`:
  the taproom of the evening before and of the afternoon after, as
  InnRooms builds them): one box the size of the room, drawn once, so the
  pewter, copper and bottles reflect the room rather than the sky. Off:
  `AshfordVillage.room_probes = false`.

What it costs: the maps two texture reads on those models' pixels (one on
Compatibility), about 30 MB of pictures on disk and less in memory
(compressed); the grade one lookup a pixel; the head turn a few sums a
figure a frame; the probe one small cube of pictures when a room is built.
Frame times here weren't measurable (software rendering on two cores
shared with other jobs ran 1.2 to 6 s a frame whatever was on).

```sh
# stills for the look pass: Ashford by day, at sunset and at midnight (the inn's front, the well, the
# carts, the hay cart, a cottage, the green), the evening's taproom, the Thornwood, Solhaven's gate;
# each as <tag>_<name>.png. nomaps / nograde / noprobes turn each part off, for a before and after;
# only=inn,green picks views; people builds the whole world with its people (more memory).
xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 960x540 --fixed-fps 30 \
    res://tests/look_shot.tscn -- <dir> <tag> [day] [dusk] [night] [taproom] [thornwood] [solhaven] [only=...] [nomaps] [nograde] [noprobes] [people]
```

Checked (5 November): `load_all` 0 failed; `duel_sim -- 200` 0 invariant
errors (rules untouched); `village_shot`, `attic_peek -- 14 2` and
`look_shot` (day, dusk, night, taproom, Thornwood, Solhaven, each with its
part off and on) on Compatibility, the stills looked at; Forward+ seen
through software Vulkan (Ashford by day and at dusk, the taproom with and
without its probe). On Forward+ the maps show most (the plank and barrel
grain, the inn's whitewashed stone); the probe's change is small.

Still to do in the look pass: baked light (`LightmapGI`) for Ashford; the
characters' normal maps (Bram's and the rest, from Gary's original Tripo3D
files, as Player A's: their game atlases can't give one); a reflection probe
on Solhaven's gold (its set is built in `solhaven_set.gd`); SSAO and
SDFGI on the Mac judged on the Mac itself (left as they were: SSAO 1.8 and
SDFGI on at the full level; worth trying SSAO about 1.0 and SDFGI off for
the frame rate if the Mac struggles); the 3D duel field (the 4 to 5 November
drama is there; nothing cheap and clear found missing).

Left for later in the look pass: baked lighting (`LightmapGI`) for the villages;
normal maps for the people (Bram's atlas is thousands of small islands, so it
needs the maker's own normal map, as Player A's had); a reflection probe on
Solhaven's gold (`solhaven_set.gd`); SSAO (1.8 now) and SDFGI judged on the Mac.

## The Duel Lab (duel rules v2)

The card battle is being rebuilt to the v1 rules (three Totem slots a side,
Life, Essence, Fate dice, Wards, Ascension). It lives in its own folders and
can be played from the title screen's **Duel Lab** button, or straight away with:

```sh
godot -- --lab
```

| Folder | What's in it |
| --- | --- |
| `scripts/duel/` | The rules engine: every tunable number (`duel_rules.gd`), the cards and starter decks (`duel_cards.gd`), the duel itself (`duel_game.gd`), the computer duellist (`duel_ai.gd`), the 24 conditions and 6 boons (`duel_conditions.gd`), the Kingdom Laws and Blessings (`duel_laws.gd`), and Resonance, Rank and Attunement (`duel_rewards.gd`). No graphics code. |
| `scripts/duel_ui/` | The Duel Lab set-up screen, the duel screen, card faces and the pieces they're built from. |
| `assets/models/creatures/` | The Totems' 3D models, `<card id>.glb` with `<card id>_atlas.png` beside it (`assets/models/PUT_MODELS_HERE.txt`). A Tripo3D creature (one material, 4K base colour, roughness-metal and normal maps embedded) is readied with `python3 tools/split_creature.py <in.glb> assets/models/creatures/<id>.glb --glow` (since 8 November after `tools/glb_bake_turn.py` and `tools/glb_flatten_rig.py`, see Kaethis below): the atlas out at 2048 (4096 since 2 November), the other maps dropped, and with `--glow` the fire-coloured parts of the atlas as an emission map (`<id>_glow.png`), so a Cinderpup's flames shine through the bloom. Cinderpup is Gary's 26 October Tripo3D model, with its seven clips (idle, spawn, attack, hit, defeat, victory, run); under the duel's warm lights its orange coat reads red. Brookfin is his 27 October one (the blue fish-dragon with the pale belly and fins, an 89-joint rig with eleven clips: idle, walk, run, swim, attack, hit_react, defeat, victory, spawn, tail_swish, rest; `hit_react` is read as its hit, `DuelField3D.CLIP_ALIASES`); `tests/totem_peek.tscn -- <dir> <yours> <theirs>` stands chosen Totems on the field for a look. River Hound is Gary's 28 October model (the lean water hound with the white foam ruff, the same eleven clips as Brookfin), in Tam's friendly game, his Reckoning duel and any deck that has her; until then she was a Shieldhound washed blue. |

```sh
godot --headless --script res://tests/duel_sim.gd -- 2000            # balance: every deck vs every deck
godot --headless --script res://tests/duel_sim.gd -- 2000 --cards    # plus win rate when each card is played
godot --headless --script res://tests/duel_log.gd -- emberstorm veilwild 3   # the full log of one duel
godot --headless res://tests/duel_monkey.tscn -- 6                   # random taps through the duel screen
godot --headless --script res://tests/deck_rate.gd -- veilwild 100   # one deck against the field (+card/-card to swap)
godot --headless --script res://tests/condition_probe.gd -- 80       # how strong each condition and boon card is
godot --headless --script res://tests/law_sim.gd -- 400              # every Kingdom Law against every deck
godot --headless --script res://tests/patron_sim.gd -- 200           # each patron god, and each Blessing under its own Law
godot --headless --script res://tests/rewards_test.gd                # Resonance, Rank, Codex and Attunement
godot --headless --script res://tests/load_all.gd                    # every script loads
godot --headless res://tests/lantern_sim.tscn -- 0.3 0.25 200        # the Lantern Duel as the story plays it (always winnable)
xvfb-run -a godot --rendering-driver opengl3 res://tests/lantern_tutorial_test.tscn -- <dir>   # plays Bram's lesson tap by tap
godot --headless --script res://tests/phase_test.gd                  # the turn's phases, Stances, answers and chains (Phase A)
godot --headless --script res://tests/phase_b_test.gd                # Tributes, Echoes, Loyal, Rekindling, the discard Rites (Phase B)
godot --headless --script res://tests/phase_c_test.gd                # bonds, Relics, veiled calls, the second Ascension stage, Tempering (Phase C)
godot --headless --script res://tests/phase_d_test.gd                # arena rules, Terrain and Continuous Rites, Favour, Oaths (Phase D)
godot --headless --script res://tests/phase_e_test.gd                # the seven ways, their cards, the cards the story hands out (Phase E)
godot --headless --script res://tests/duel_sim.gd -- 980 --ways      # the seven ways' sample decks against each other
xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 res://tests/phase_e_shot.tscn -- <dir>   # Phase E stills: the tinted stand-ins
xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 res://tests/phase_d_shot.tscn -- <dir>   # Phase D stills, both fields
godot --headless --script res://tests/skills_test.gd                 # duel skills, Rallying Light, the Circle's events, the damage preview (27 October)
godot --headless --script res://tests/puzzles_test.gd                # Bram's Riddles: each answer wins, a wrong try doesn't
xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 res://tests/battle_extras_shot.tscn -- <dir>   # their stills
```

### Skills, the comeback card, the Circle joining in, and Bram's Riddles (27 October)

Gary (27 October): "add all the go battles", the seven ideas sent him that
morning, with the phases gone. Each can be switched off in the Lab's tuning
list, and none of them is in a lesson (the Lantern Duel), on a set board (the
Trial, a riddle) or where a spec says no (`no_skills`, `no_comeback`,
`no_arena_events`).

- **Duel skills** (`scripts/duel/duel_skills.gd`, `DuelGame.has_skill` and
  `_use_skill`): one a side, on a ribbon across the top of the plate (gold;
  grey and struck through once used; tap it for its words), each working
  once a duel by itself. Second Wind (at half Life your Totems heal 30),
  Quick Start (+1 Essence on your first turn), Lucky Charm (the first Fate
  roll rolled twice, the better counts), Keen Eye (the rival's first Ward
  set face up), and three learned from their owners by beating them: Loyal
  Hound (Tam's: the first Totem to be knocked out holds on with 10 HP), Old
  Wards (Nell's: the first Ward is free) and Showman (Corin's: the first
  attack +20; learned from the Lantern Duel). The player chooses theirs in
  the menu under Deck (`DuelSkills.chosen`, Game setting `duel_skill`); a
  story duel gives its rival's as `spec.rival_skill`, the Lab picks each
  side's (Random, None or one) and `spec.skills` sets both. When one works,
  its name comes across the Circle (`fx_skill`). Notes after the Lantern
  Duel, Tam's and Nell's games say what was learned.
- **Rallying Light, the comeback card** (`DuelGame._after_life_loss`): the
  first time a duellist's Life falls to a quarter, their god sends them a
  free Rite, once a duel: every Totem heals 30 and is Empowered, and a card
  is drawn (`rallying_light`, "granted": never in a deck, the Codex, a cache
  or the rewards, and not counted among a duellist's own cards). Its
  painting is a stand-in drawn here until Gary's comes. There was a Ward
  called Last Stand already, so it has its own name.
- **The finishing blow** (`DuelScreen._finishing_start`, `_finishing_end`):
  the blow that empties a Life flies at a third of the speed
  (`Engine.time_scale`), the camera leans in to where it lands, the screen's
  edges darken and the one going down says their last line
  (`rival_falls`); time comes back up over half a second after, and is put
  back whatever ends the duel. Not at the tests' 20x autoplay.
- **Opponents speak up** (`DuelBarks`): Tam, Nell and Corin have more lines
  (their big hits, skills, Rallying Light, the Circle, the last blow), and a
  Lab rival, or any duel without its own lines, says one of the generic
  ones. Each event once a duel, as before.
- **Bram's Riddles** (`scripts/duel_ui/duel_puzzles.gd`, `PuzzleMenu`, the
  title screen's button): seven one-turn puzzles on set boards, each
  teaching a trick: an open lane (Shift), spill-over, a Guardian first,
  weakness, baiting a Ward, the order of Essence and power-ups, and
  Rallying Light. Bram's side only watches; a wrong try and he sets it again
  with his hint from the second try (the Trial's reset); solved ones are
  ticked (setting `riddles_solved`). The aiming preview shows only the
  damage there (what wins is the riddle). `tests/puzzles_test.gd` plays each
  answer and a wrong try. The rules engine took four puzzle keys for them:
  `wards` (set face down), `no_gift`, `attack_first` and `out_text`.
- **The Circle joins in** (`DuelGame.ARENA_EVENTS`, `_arena_event`): at turn
  5 and every 6 turns after, the arena does something to both sides
  (Ashford's lanterns flare: every Totem Empowered, Fire Totems heal 20; the
  tide surges; the forge roars; the stone wakes; the mists part; the noon
  bell), counted down in the corner under the turn for the last three turns
  (`fx_arena_event`).
- **The damage preview** (`DuelGame.preview_attack`, `DuelScreen.PreviewChips`):
  while a move is aimed, a chip over each target says what it would take
  (a range for a Fate move), KO (or its chance), and WINS (or its chance)
  if the blow, or its spill-over, would end the duel. Face-down Wards and
  answers aren't counted. **Speed** is one tap away at the top of the duel
  (Normal, Fast, Fastest: 1x, 2x, 4x), and in Options as Battle speed.

`friendly_sim` with the skills, Rallying Light and the lanterns: Tam 86% for
a new player's plain play (82% before), Nell 50% (53%). `duel_sim -- 300`
with a random skill each side: 0 invariant errors, 26.7 turns on average
(25.6 before), first player 49%.

### Longer duels (29 October)

Gary (29 October): "lets up the health points of characters and maybe the
totem cards so that battles last a little longer". Every duellist's Life is
100 more (`DuelRules.life_base` 250, was 150: about 425 for a starting
duellist, was 325); every Totem's HP is 30% more, to the nearest 10, in the
card list itself, so every card face and the Codex show it (40 became 50,
50 70, 60 80, 70 90, 80 100, 90 120, 100 130, 120 160, 130 170, 150 200);
the five Summons' blows 30% more too, so the biggest cards still do what
they're for (Sunfall 60, Tidal Embrace 70, Worldbreaker 180, Endless Dream
40, Dawn's Roar 70), and Flood 40. The friendly games are fought at 60 Life
(was 40); the Lantern Duel stays at 25 (it's the lesson, and plays as before:
Splash and Undertow still finish Corin's pup, now 70). Tried in
`duel_sim -- 600` before choosing (`--life-base=` sets it for a run):

| Life base | Totem HP | Average duel |
| --- | --- | --- |
| 150 | as it was | 21.5 turns |
| 200 | as it was | 22.7 |
| 150 | +25% | 23.5 |
| 250 | +30% (chosen) | 26.3 |
| 300 | +30% | 27.4 |
| 250 | +50% | 28.2 |

With the change, `duel_sim -- 1000`: 26.1 turns on average (21.5 before), 0
invariant errors, first player 51%, Emberstorm 58%, Tidegrove 53%,
Ironstone 40%, Veilwild 50%. `friendly_sim`: Tam 76%, Nell 52%, 8 turns
(was 6). `lantern_sim`: won every time, 6 turns. The riddles and the Trial
of Light are set boards, so their numbers were worked again: The Guardian
First (Ten Life, three Essence), Where It's Weak (a Bloomsprite where the
Mossling was), Steel Finds the Wound and Whose Ground (Twenty Life, two
Essence, Horn Bash after), Old Friends (Flood 40); the Trial's Tidegrove
mirrors 260 Life (was 240) and Veilwild's 110 (was 140); `puzzles_test` and
`trial_puzzle_test` play them.

### Gary's 29 October duel notes

Gary's five notes on the card battle (29 October), and what each became.

- **"animations added to each card or attacks effect"**: every blow and
  every card played has its own look on the 3D field, by its element and the
  kind of move it is. One table says which (`DuelFXStyle`,
  `scripts/duel_ui/duel_fx_style.gd`): each element's colours, how its blow
  travels, how it lands and its gem colour; the kind of move read from its
  name (a Scorch or a Pollen Spit is a breath, a Glint or a Lance a beam, a
  Rockfall or a Thunderhead comes from above, a Riptide a wave, a Howl or a
  Gaze rings out, a Water Lash lashes, the rest are blows); a few moves set
  by hand (`OVERRIDES`, "card id:move": the Ashen Drake's third move is a
  meteor, Stormcaller's first an arc); the Rites by what they do, the Wards
  set and springing, answers, Relics and the cards' own arrivals
  (`RITE_OPS`, `WARD_OPS`, `ANSWER_OPS`, `CARD_MOTIF`). Change a line there
  and the duel follows. The pieces are built in `DuelStrikeFX`
  (`scripts/duel_ui/duel_strike_fx.gd`): a fireball with a flame trail, a
  water jet, a wave, a fissure of stone spikes, an arc of lightning and a
  bolt from above, frost and venom breath, whirling leaves and a vine lash,
  spinning blades and a beam of metal light, a venom glob, psychic rings, a
  rune circle, spirit and dawn beams, shadow wisps and falling stars; each
  lands its own way (a burst of embers, a splash, stone chips, a crackle,
  frost shards, leaves, sparks), with a hit flash and a shake. A Rite is
  cast from a circle of runes on its caster's side; a Ward set is a circle
  of runes sinking into its owner's ground, and one springing flashes violet
  and then does its work where it does it (a shield round the Totem it
  guards, its blow on the attacker, a seal on the Rite it stops); Guard
  throws up a dome of light, Rest a gentle mending; a condition or boon
  rings the Totem in its colour. It's all CPU particles with shared
  materials, glows drawn as quads with their own material (a Sprite3D glow
  next to a particle trail vanished under Compatibility, the web build's
  renderer), at most two lights a blow, and every shader drawn once under
  the floor as the duel opens (`DuelField3D.warm_fx`), so the first blow
  doesn't stutter on a phone. The flat field (Options, "3D duel field" off)
  keeps its old effects.
- **"When a card dies ... turn to dust or diamonds rather then just fall
  over"**: a Totem knocked out stops still, turns to glass from its feet
  up, cracks with light, and bursts into diamonds of its element's gem
  colour that tumble, bounce on the ground and fade into sparkling dust; its
  plaque fades and the slot is empty (`DuelCrystal`,
  `scripts/duel_ui/duel_crystal.gd`; `DuelField3D.crystal_death`, about 1.5
  s at 1x). A 3D model gets a crystal coat over its own materials, a painted
  cut-out a glass shader of its own, and the flat field its card going to
  glass and shattering (`DuelCrystal.shatter_2d`). No blood. A Totem swept
  back to the hand (a bounce, Undertow) doesn't shatter: it shrinks back
  into its card, BACK TO HAND.
- **"if a person clicks on the card preview ... it makes it much bigger
  till you click off it"**: a tap on the card panel on the right (it has a
  magnifier on its corner now) opens the card out in the middle of the
  screen, as tall as the screen allows, with everything behind dimmed and
  its words written out beside it (under it on a screen taller than wide),
  sized to be read on a phone (`DuelScreen.CardZoom`). A tap anywhere, Esc,
  B, E, Space or Enter closes it, and that tap does nothing else: it isn't
  a tap on the board, so whatever the player had picked up stays picked
  up. It won't open while a line of Bram's lesson is waiting to be read,
  and a line coming up closes it.
- **"In the how to duel some of the text goes out of the text box"**: the
  element chart's HURT BY column was set at two thirds of a fixed width,
  and Tide, Verdant and Venom (each hurt by three) ran past the chart's
  right edge. The chart's columns are now as wide as the words in them
  (`ElementChart`), on the How to Duel page and at Bram's campfire.
  `tests/manual_shot.tscn` opens How to Duel with every chapter there is
  (45), takes a still of each screenful and checks that no line, page or
  chart row runs out of its box.
- **"The text in the battles goes by very quickly not enough to read what it
  says needs to be a fraction longer"**: one setting, **Reading time**
  (`DuelReading`, `scripts/duel_ui/duel_reading.gd`; Options and the duel's
  own Menu; setting `duel_reading`). **Normal**, the new default: every
  timed word in a duel stays up 1.6 times as long as it did, and never less
  than 0.9 s and 0.3 s a word (at most 5 s). **Slow**: 2.2 times, 1.3 s and
  0.42 s a word (at most 7.5 s). It covers the banners, a move's name, the
  damage and condition words, the toasts, the rival's barks, a Fate roll, a
  Rite or Ward held up in the middle (the rival's by its words; your own a
  little longer than before), the answers and notes. The pure animation
  waits (a lunge, a card flying) are as they were. A faster battle speed
  still shortens the words, but only by the square root of the speed, so
  they can be read even at 4x; the tests' 20x autoplay keeps the old holds.
  The turn banner counts only its title ("YOUR TURN"), not the line under it.

```sh
# the stills (attacks of every element mid-flight and landing, each kind of move, the rival's blows,
# Rites, Wards, an answer, a Relic, a stance, conditions, the knockout at four moments for a model and
# a cut-out, the card opened out, the reading times):
xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 30 \
    res://tests/duel_notes_shot.tscn -- <dir> [attacks] [cards] [ko] [zoom] [reading]
# a blow frame by frame (a still every twentieth of a second), to time an effect:
#   ... duel_notes_shot.tscn -- <dir> flight=astral_fall,fire_meteor,r_tide_jet
# the card opened out on a phone (each way up):
xvfb-run -a -s "-screen 0 1280x900x24" godot --rendering-driver opengl3 --resolution 390x844 --fixed-fps 30 \
    res://tests/duel_notes_shot.tscn -- <dir> zoom
# How to Duel at a screen size (390x844, 844x390, 1280x720, 1920x1080; ui=1.3 for the Largest text size):
xvfb-run -a -s "-screen 0 2000x1200x24" godot --rendering-driver opengl3 --resolution 844x390 \
    res://tests/manual_shot.tscn -- <dir> [ui=1.3]
```

`--fixed-fps 30` makes every frame a thirtieth of a second of the duel
however slowly it's drawn, and `duel_notes_shot` draws nothing between its
stills, so each is caught at its moment even on a slow software renderer.
Tests with the changes: `load_all` 0 failed; `duel_sim -- 300` 0 invariant
errors, 26.1 turns on average, first player 53%; `duel_monkey -- 4` and
`-- 4 --3d` no script errors; `skills_test` and `synergy_test` pass;
`lantern_sim -- 0.3 0.25 100` won every time, 6 turns; `lantern_tutorial_test`
won, no problems; `manual_shot` ok at 390x844, 844x390, 1280x720 and
1920x1080, and at the Largest text size (`ui=1.3`) at the first three.

### Faster, more cinematic duels (4 November)

Gary (4 November): "Battle needs to go a little faster and can we make it
more cinematic and dramatic." Two things, then: the pure waiting in a turn
trimmed, and the 3D field given a camera and a clock that know a big moment
when they see one. The words' reading times (Reading time, above) are not
touched: nothing is on screen for less than it was.

**Faster.** Every wait below is in the duel's own seconds (at Normal the
duel runs 1.2 times that; Fast and Fastest divide again), each a named
constant at the top of the effects in `DuelScreen` ("the pace, and the
show") or in `DuelHuman.Paced`:

| What | Was | Now |
| --- | --- | --- |
| The turn banner ("YOUR TURN"): its words slide in and out in a fixed moment each (`BANNER_IN`, `BANNER_OUT` 0.14) and are fully up for their whole reading time, and the duel moves on as they slip away (`BANNER_TAIL` 0.06) | words up 1.09 s, 1.52 s a turn at Normal | words up 1.14 s, 1.31 s a turn |
| The rival thinking before a play (`THINK_ACTION`) | 0.5 | 0.25 |
| ...showing the card or target it chose (`AI_PREVIEW`) | 0.35 | 0.2 |
| ...before an answer on your turn (`THINK_RESPONSE`) | 0.6 | 0.35 |
| ...choosing cards, Totems, a slot or a reroll (`THINK_CARDS`, `THINK_SLOT`) | 0.4, 0.3 | 0.2, 0.15 |
| ...ending its turn (`THINK_END`: it chooses first now, and ending needs no thinking) | 0.5 | 0 |
| A called Totem watched arriving (`CALL_WAIT_MIN` to `CALL_WAIT_MAX`: a long spawn clip, Cinderpup's 2 s, plays on under the duel) | 0.5 to the whole clip | 0.4 to 0.6 |
| The beat after a blow lands on a Totem (`HIT_PAUSE`, one wait where there were two) | 0.44 | 0.25 |
| ...on Life (`LIFE_HIT_PAUSE`) | 0.5 | 0.3 |
| The roll-off dice held after they land (`ROLLOFF_PAUSE`) | 1.1 | 0.6 |
| The card drawn (`DRAW_PAUSE`) | 0.3 | 0.15 |
| An attacker gathering itself (`WINDUP_PAUSE`) | 0.26 | 0.15 |
| After a knockout's dust (`KO_TAIL`) | 0.12 | 0.08 |
| The camera going home: after the last blow of an attack (`CAM_HOME_AFTER` 0.4), not after each one, so it stops bouncing home between the blows of a multi-hit; and anyway 3.5 s after an attack that never lands (`CAM_HOME_FALLBACK`) | after every hit | once |

The same duel timed both ways (`tests/duel_film.tscn` headless, seed 3,
Emberstorm against Tidegrove, `--plain` so no freeze or slow motion counts):
15 turns in 236.7 s before, 189.8 s now, 20% shorter, 16.4 s a turn down to
13.1 (the rival's turns gain most: 11.0 s to 7.8, 13.1 to 10.5). What's
left of a turn is mostly words and blows.

**More cinematic and dramatic**, on the 3D field (the flat field keeps its
own look, but the freeze, the slow motion and the bars play there too). One
switch, `DuelRules.cinematic` (on; `DuelRules.set_value("cinematic",
false)` for a phone that struggles), and every number a named constant with
a line saying what it is (`DuelScreen`, and the camera's in `DuelField3D`,
"camera"):

- **The camera moves.** `DuelField3D.cam_shot(pos, look, dur, fov)` puts
  it anywhere, looking anywhere, the lens tweened too (`_cam_to` takes a
  fov now; `set_home` keeps a film's lens as `_home_fov`), the idle drift,
  shake and punch still laid over it. On an attack it pushes in low behind
  the attacker over 0.3 s (`SHOT_IN`; `shot_behind`: 5.4 m back, 2.5 to the
  side the middle of the field is on, 1.7 up, lens 40), looking across at
  the target, then whips to where the blow lands as it lands (`SHOT_WHIP`
  0.26, a lunge's 0.14; `shot_close`: 5.2 m short of it, 1.9 aside, 2.5
  up, lens 37; a blow on Life, which lands beyond the row, from 8.4 m back
  and 3.8 up so the row is in the frame), and goes home 0.4 s after the
  attack's last blow. The move's name keeps to its Totem as the camera
  moves (`MoveLabel.follow`), and a 2D nudge (the windup, the knockback)
  is read through the camera's own axes now (`px_per_unit`,
  `_cam_right`/`_cam_forward`): from behind a Totem a metre to +x used to
  come out as 1 px, and a 28 px step threw the model 28 m off the field.
  While the player chooses an answer the camera comes off the attacker's
  shoulder so the whole board can be read (`begin_respond`). Films (the
  White Sky, `spec.film`) keep their directed cameras: none of this runs in
  one (`_cine()`).
- **Hit-stop.** A blow of 50 or more (`HIT_STOP_DAMAGE`), one on a
  weakness, or a natural 20 (`fx_roll` leaves the roll on the strike) stops
  the clock at 0.08 (`HIT_STOP_SCALE`) for 85 ms of real time
  (`HIT_STOP_MS`), a frame or two after the impact so the sparks are out,
  then runs it back up over 130 ms (`HIT_STOP_RAMP_MS`), the finishing
  blow's own ramp (`_time_ramp`, shared now). Never above Fastest, in a
  film, or while the finishing blow or another freeze has the clock
  (`_may_slow`); the clock is set straight whatever ends the duel or the
  screen (`_time_gen`: a ramp still running leaves it alone from then on).
- **Knockouts.** A close-up (`shot_ko`: 3.4 m in front, short of the row
  across, 1.5 aside, at head height, lens 38) and the crystal's burst in
  slow motion, 0.4 for 400 ms real then back over 250 ms (`KO_SLOW`,
  `KO_SLOW_MS`, `KO_SLOW_RAMP_MS`); KNOCKED OUT sits higher, clear of the
  toasts in the middle.
- **Big calls.** A call of tier 3 and up (`HERO_TIER`) and every Ascension:
  as the card lands the camera cuts to the floor in front of the Totem
  (`shot_hero`: 3.3 m out, 1.3 aside, 0.45 up, lens 44; an Ascension from
  1.7 times as far, back from its pillar of light) and rises to its eye
  line over the wait, the lens punched.
- **Black bars** top and bottom, 8% of the screen each (`LETTERBOX`),
  eased in and out over 0.3 s of real time (`LETTERBOX_SECS`), for a Summon
  (up until the Demigod has landed) and the finishing blow
  (`DuelScreen.Letterbox`, on the overlay). The Life number of the
  finishing blow sits under the top bar.
- **The grade.** The glow spikes on an impact, 0.55 to 0.9 and back over
  0.4 s (`impact_glow`: `GLOW_SPIKE` 1.65 times `GLOW_BASE`,
  `GLOW_SPIKE_SECS`; half a spike on a small blow, more on a knockout, an
  Ascension and a Summon landing; a film's 0.8 is its own base), and the
  colour drains while the clock is slow, saturation 1.12 to 0.72
  (`slow_grade`, `SAT_BASE`, `SAT_SLOW`, in real time).
- **The far blur.** A `CameraAttributesPractical` on the field's camera,
  only at `Gfx.level()` 2 (Forward+ on a Mac, or a phone set to Full; the
  phone's Smooth and the Compatibility renderer never pay for it), with a
  gentle far blur (`DOF_AMOUNT` 0.055) that starts 2.6 m past a shot's
  subject (`DOF_MARGIN`) and comes in over 7 m (`DOF_TRANSITION`);
  `cam_shot` and a `cam_focus` of 0.3 or more turn it on, `cam_home` eases
  it off. A film has none.

```sh
# stills of all of it (the attack shots at four moments for your blow and the rival's, the knockout
# close-up at the crystal, the burst and the dust, the hero shots, a Summon's bars, the finishing
# blow; `flat` the flat field; `pace` prints the waits at Normal, old and new):
xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 30 \
    res://tests/duel_cine_shot.tscn -- <dir> [attack] [ko] [call] [summon] [finish] [pace] [flat]
# the pace of a whole duel, headless (prints when each turn begins; --plain: no freezes or slow motion):
godot --headless --fixed-fps 30 res://tests/duel_film.tscn -- 1280x720 3 8 600 tidegrove 30 --plain
```

`duel_cine_shot` checks for itself that the camera pushed in and came home,
that the clock stopped and was set straight, that the bars came and went and
the knocked-out slot cleared. Tests with the changes: `load_all` 0 failed;
`duel_sim -- 300` 0 invariant errors, first player 53%; `duel_monkey -- 4`
and `-- 4 --3d` no script errors; `duel_cine_shot` (every part, and `flat`)
no problems; `duel_notes_shot -- ko reading` no problems. The Duel Lab's
tuning panel doesn't list `cinematic` yet (its rows are named in
`duel_lab.gd`'s `TUNE_LABELS`); `DuelRules.set_value` reaches it.

### A more dramatic duel (5 November)

Gary (5 November, having played the 4 November build): "Make the battle
look better. At the moment it looks boring. I want it more dramatic." The
camera and the clock were done the day before; this is the spectacle
itself, on the 3D field, with `DuelRules.cinematic` on (nothing of it
without, and nothing of it in a film: `DuelScreen._cine()`,
`tests/duel_film_check.tscn` plays Bram's filmed duel and checks none of
it creeps in). Every number is a named constant with a line saying what it
is: "the stage" at the top of `DuelField3D`, "the drama" in
`DuelStrikeFX`, and the screen's in `DuelScreen` ("the drama").

- **The arena is a stage** (`DuelField3D.dress_stage`, as the field is
  built; `_undress` for a film). The surround is darker and the Circle the
  lit thing in it: the ambient light down (`AMBIENT_ENERGY`), the contrast
  up, the warm key light over the Circle stronger (`HALL_ENERGY`) and the
  scenery painting dimmer (`BACKDROP_DIM`); a cool rim light from the far
  side edges every Totem (`RIM_COL`, `RIM_ENERGY`, `RIM_PITCH`); three
  shafts of light hang over the far half of the field and sway
  (`SHAFTS`, `SHAFT_*`; `DuelStrikeFX._shaft_tex`); embers of the arena's
  colour whirl up through the motes (`EMBERS`); the sigils breathe
  (`RING_BREATHE`) and the floor glow under a Totem pulses with its lamp
  (`GLOW_PULSE`); the screen's edges are shaded over the field, under the
  HUD (`DuelScreen.STAGE_SHADE`). A Totem that acts gets a flare of its
  sigil and a ring running out from its feet (`act_pulse`).
- **An attacker gathers its power** before the blow (`DuelStrikeFX.charge`,
  `DuelScreen.CHARGE_SECS`, under the windup and the Fate roll): motes of
  its element drawn in to its body out of the air, a glow swelling there,
  a ring of its light tightening on the floor under it, its lamp swelling,
  and the Totem itself swelling a little (`CHARGE_SWELL`); the blow ends
  it in a blink (`Charge.end`, `_end_charge`), or it ends by itself if the
  attack comes to nothing (`CHARGE_MAX_SECS`).
- **A heavy blow throws things out** on top of its element's own impact
  (`DuelStrikeFX.heavy`, from `DuelField3D.strike_impact` with `drama`): a
  white-hot core, a shockwave ring standing up at the point of impact,
  splinters of the element's light flung out and falling (`_shard_tex`),
  and the mark the blow leaves on the floor (`floor_mark`: a scorch for
  fire, earth, venom, metal and the dark elements, a pale pool of the
  element's light for the rest, lingering `HEAVY_MARK_SECS`). A small blow
  gets the core and a few splinters.
- **The whole picture takes the blow** (`DuelScreen._blow_lands`): the
  picture is punched from where it landed, a radial smear and a chromatic
  split for a few frames (`DuelField3D.impact_punch`,
  `assets/shaders/duel/impact_punch.gdshader`, the field container's own
  material, only at `Gfx.level()` 2: a Mac, or a phone set to Full), the
  camera kicked back and springing (`cam_kick`, `KICK_BIG`/`KICK_SMALL`,
  `KICK_SPRING`), and the screen's edges flaring in the blow's colour
  (`_vignette` with `k` under 1: `WASH_BIG`, `WASH_SMALL`, `WASH_KO`,
  `WASH_LIFE`; yours on your own Life stays the full red it was). A struck
  Totem flares white-hot (`HIT_FLASH_COL`; the number carries the red),
  squashes and springs back (`HIT_SQUASH`), and is thrown back away from
  whatever struck it, further the harder the blow (`KNOCKBACK_PX`,
  `KNOCKBACK_PER_DAMAGE`, `KNOCKBACK_MAX`).
- **Calls, Ascensions and the Demigod**: a called Totem arrives in a rune
  circle spinning up under it, halos of its light rising up its body and
  tightening, splinters thrown up (`DuelStrikeFX.arrival`; an Ascension's
  is gold, the picture punched and the edges in gold); the Demigod's
  landing stands a shockwave up, rolls dust out low across the floor,
  throws stones, and sends a second wave of its light a beat after the
  first (`DuelStrikeFX.landing`).
- **Low Life beats like a heart** (`DuelViews`: under `LOW_LIFE` of full
  Life the number and the bar pulse red, quicker the lower it falls).
- **By device**: particle counts are scaled by `DuelField3D.fx_scale()`
  (all at level 2, 0.7 on a phone's Smooth, under half on the phone link),
  the rim light and the shafts need level 1, the punch shader level 2;
  `DuelField3D.preview_level` lets a test dress the stage as a Mac would
  (software GL here is Compatibility).

```sh
# the stage at rest (both rows full, the shafts and embers), every part of the drama, dressed as a Mac would have it:
xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 960x540 --fixed-fps 30 \
    res://tests/duel_cine_shot.tscn -- <dir> arena attack ko call summon finish preview    # `plain`: cinematic off
# the film guard: Bram's filmed duel, checked for any of the dressing or the drama having crept in:
xvfb-run -a ... res://tests/duel_film_check.tscn -- <dir> [seconds]
```

Checked (5 November): `load_all` 0 failed; `duel_sim -- 200` 0 invariant
errors, 25.8 turns, first player 52%; `duel_cine_shot` every part with
`preview`, problems none, the stills looked at; `duel_film_check` problems
none; `duel_monkey -- 1 --3d` no script errors. The impact punch and the
Forward+ look weren't seen here (software GL): worth a look on the Mac.

### The moving duel camera (8 November)

Gary (8 November): "During battle can we have the camera pan around the
playing board so we can watch whats happening from all angles and have a
button at the top if players would rather have it locked like it is now."

**Moving (the new default).** On the 3D field the camera's home stops being
one place and becomes a path (`DuelField3D`, "the moving camera"): it
travels slowly round the Circle, a lap in about 80 seconds
(`ROAM_SPEED` 4.5 degrees a second, a little quicker and slower as it goes,
`ROAM_SPEED_SWAY`), looking down from 28 to 40 degrees (`ROAM_PITCH`,
`ROAM_PITCH_SWAY`; never under `ROAM_PITCH_MIN` 20 on the path) and coming
in and out a little (`ROAM_DIST` 13.4 m, `ROAM_DIST_SWAY`), lens 34
(`ROAM_FOV`), looking a little short of the middle towards itself
(`ROAM_NEAR`) so the Circle sits up clear of the hand. Every side of the
board is seen in a lap, the rival's end included. What the duel does still
takes it where things happen: the attack shots, the knockout close-up, the
hero shot of a big call and a Summon's descent are the 4 November shots as
they were; a Totem called (below tier 3, which has the hero shot) is now
watched from round in front of it as it arrives (`roam_view`: as near its
front as `VIEW_ROUND` 70 degrees, never more of a swing than `VIEW_SWING` 60
from where the camera is, 21 degrees above it, about 9 to 10 m off, for
`VIEW_SECS` 2.6); and a lean (`cam_focus`: a Rite on a Totem, an answer
being chosen) leans in from the path rather than from home (`roam_lean`).
When a shot ends the camera flows on from wherever the shot left it
(`_roam_from_here`), not back to home.

**The player's choices are never harder.** Whenever the player has
something to choose on the field (their turn's choosing, a slot to pick,
an answer, a lesson from Bram's memory up: `DuelScreen._choosing()`, set on
the field every frame as `roam_hold`), the path is the true home view, and
once settled it is exactly home (`_at_home`; `roam_home()`), so every slot
and tap target is where the locked camera has it. It comes home in about
two seconds (`ROAM_HOLD_SMOOTH`); a Totem just called is watched at least
`VIEW_HELD` 1.1 s first. It moves on again as soon as the action plays out,
and all through the rival's turn. Fast and Fastest move it quicker
(`pace`).

**How it moves.** Nothing on the path is a tween: its turn round the
middle, its height, its distance, what it looks at and its lens each follow
their goal on a critically damped spring (`_smooth`, `_smooth3`;
`ROAM_SMOOTH` 1.5 s, quicker out of a shot but never quicker than
`ROAM_QUICKEST` 0.3 s, which is gentler than the locked camera's own
cubic way home), so it eases off and in and never jerks. Moving, the lens
is kept clear of every Totem's body and above the mat (`_clearance`:
`CLEAR_R`, `CLEAR_SOFT`, `CLEAR_ABOVE`, `MAT_CLEAR`), eased in as the path
takes over (`FOLLOW_IN`). The Totems' name plates keep the size their slot
looks from where the camera is (`depth_k`; 1 at home and when locked). The
idle drift, the shake, the kick and the punch are laid over it as before.
Cost: a few sums a frame.

**The button.** At the top, left of the Speed button: "Camera: Moving" /
"Camera: Locked" (`DuelScreen.cam_btn`, `_set_camera`), kept in
`Game.settings.duel_camera` ("moving" by default, or "locked") and saved at
once; Options has it too ("Duel camera", Moving / Locked, under Battle
speed). **Locked is exactly the camera as it was** (`roam_on` false: none of
the above runs, the plates keep their row sizes).

**Untouched:** a filmed duel (the White Sky's, `spec.film`) never moves on
its own (`set_roam` is never called for one, so its `set_home`/`cam_home`
work as before); the flat 2D field has no camera and no button; Summon
videos, puzzles and lesson duels play as before (a lesson up holds the
camera home).

```sh
# the moving camera: a lap of the path (stills every `every` s), the player's choosing (exactly home),
# a call on each side, an attack's shots and back onto the path, the button (locked and saved, moving again):
xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 30 \
    res://tests/duel_camera_shot.tscn -- <dir> [path] [choose] [call] [attack] [button] [every=12] [nostills]
```
`tests/duel_cine_shot` now sets the camera to locked, since its checks are
the locked camera's.

### Kaethis, the Hand Before: Bram's god and its cards (5 November)

Gary: "top tier totems that will be under his own god"; he said yes to Kaethis on 6 November (the name, Astral shared with Aster, and the faceless hunter being Kaethis's, kept secret until Interlude A or Part 3). Bram's old god, from the pantheon doc of 4 November: the god of fate and destiny, Astral (shared with Aster, as Pyrrhane and Ysolde share Fire), attribute Resolve, outside every bloc, with no Seat, so no Kingdom Law, no arena and no Blessing (`Lore.GODS.kaethis`; its Divine Gift `foreordained`: draw a card, and the card on top of the rival's deck goes to its bottom, two cards on full Favour; the doc's "look at the top five of both decks and order them" wants a picker, so the Gift's text says what it really does). It isn't in the Duel Lab's patron list or any pool, starter deck or Sigil Cache yet; a 14th god breaks nothing that walks the gods (`GREAT_GODS` stays seven; Standing, the Favour meter, the god seals and the Gift button all go by `Lore.GODS.has` and fall back to the drawn seal while `assets/art/gods/kaethis.jpg` is missing). Its name lives in `Lore.GODS` only: the cards' backstories take `{god}` and `{title}` from there (`DuelLore.backstory`). Eleven cards (`duel_cards.gd`, the KAETHIS section; `DuelSynergy.CARD_GOD` gives ten of them to Kaethis, the Glyph Warden is Aldrith's by its element): the Totems **The Scrivener** (Crystal, 3, 180 HP; Strike the Name pierces Guard), **Loomwarden** (Crystal, 4, 220, Guardian; Tangle Roots), **The Unspent Hour** (Relic tier, 4, 190, Swift; Turn the Glass Staggers), **The Weft Serpent** (Legend, 5, 240; Unravel Marks, Weave Shut +40 on the Marked, `bonus_if_status`) and Aldrith's **Glyph Warden** (Mystic, Relic tier, 3, 180, Guardian and Shelter; Binding Glyph Silences); the Summon **Orlanthe, the Last Page** (Demigod, 7: Final Entry, 140 to one foe through Guard, every other foe Doomed: the new `doom_others` op beside Grondmaw's `stun_others`, in `_summon_strike` and the AI's `_summon_score`); the Rites **Cut Thread** (Dooms a foe) and **Foreordained** (draw, and the new `rival_top_to_bottom` op, scored by the AI's `_rite_score`); the Ward **Already Written** (`foe_rite` → `cancel_rite`, so like the Counter Rune it stops a Summon too); the Relics **Hourglass With No Sand** (a move, The Fixed Hour, 2: 50 and Staggered) and **Knotted Cord** (+30 HP and a card when it falls: `relic_text` now joins a Relic's parts, so one Relic can give two things). Until Gary's paintings and models come each Totem stands as a tinted stand-in (`stand_in` + `stand_in_tint`): the Scrivener a parchment Gilded Sentinel, the Loomwarden a pale Mirewidow, the Unspent Hour a pale-blue Somnowl, the Weft Serpent a parchment Riptide Serpent, the Glyph Warden an indigo Quarry Golem; Orlanthe with no cut-out, scene, model or `summon_orlanthe` stinger falls back as any Summon does (the drawn card in the Summon cinematic, the landing's starlight, the "summon" sound under the duel's music). `DuelGame.demigod_of` now skips a Summon `CARD_GOD` gives to another god, so Aster's sworn aren't offered Orlanthe at full Favour (Aster has no Demigod, as before). Prompts: `docs/card-prompts.md` "Round 9: Kaethis, the Hand Before" (the god's painting, every card, Orlanthe's sky scene, the 3D model lines and the stinger's music prompt). Later, not in this round: the doc's small Kaethis cards (Thread Moth, Spindle Cat, the Written Hound, the Knot-Warden).

The Totem plate's HP figure is fitted to its box since the same day (`DuelViews`: 220 was cut to "22").

**8 November (Gary's files for Round 9):** the Scrivener, Loomwarden, the Unspent Hour and the Weft Serpent are his own now: each has its card painting (`assets/art/cards/<id>.jpg`, at the size he painted it), a battlefield cut-out (`assets/art/creatures/<id>.webp`, cut from the painting with rembg's isnet, 560 px like the others) and his Tripo3D model (`assets/models/creatures/<id>.glb`, readied by `tools/glb_bake_turn.py`, the new `tools/glb_flatten_rig.py` and `tools/split_creature.py`, with its 4096 colour picture beside it, VRAM-compressed), so their `stand_in`s are gone from `duel_cards.gd`; the Glyph Warden is still the indigo Quarry Golem. Tripo's clips came under its own names, so `tools/glb_rename_clips.py` renames them to what `DuelField3D.CLIP_ALIASES` reads before the split: the Loomwarden's `thread_shield`, the Unspent Hour's `time_shield` and the Weft Serpent's `thread_shield` are their `guard`, the Serpent's `attack_strike` its `attack` and its `slither` its `run`; the Scrivener came on the humanoid library (idle, walk, run, punch, sword_swing, fight_stance, hit_react, death, cheer...), so its `sword_swing` is its `attack` (the quill stroke of Strike the Name) and `fight_stance` its `guard`; `death` and `cheer` are read as its ko and victory by the aliases, and it has no spawn clip (the call's light covers it). The Unspent Hour floats (`DuelArt.FLYERS`): a winged hourglass spirit with no feet. **Why the flatten step:** these Tripo exports keep the mesh centred on the origin and lift it onto its feet through the bones, under two quarter-turned nodes (node_0, Armature); Godot draws it where the bones put it but `DuelField3D._merged_aabb` measures the mesh's own bounds through those nodes, so on the field each Totem was lifted half its height into the air (the first render had the Unspent Hour in the sky and the Weft Serpent's head off the top). `glb_bake_turn.py` puts the rest pose into the mesh and `glb_flatten_rig.py` folds the nodes' turns into the root joint (its clip keys turned with it), so measure and picture agree; `tests/creature_peek.tscn -- <dir> creatures/<id> [clips]` renders a model alone (front, three-quarter, back, each clip) and prints its floor and which duel clip each alias finds, and `tests/tree_peek.gd` prints the scene Godot built. Orlanthe's stinger is in (`summon_orlanthe`, his 19.7 s piece as `assets/audio/music/summon_orlanthe.ogg`, the original in `audio/source/`): the duel's music dips under it when the Last Page is called, and in the Night of the White Sky it rings on through the white (`Music.stop` leaves a stinger playing). Kaethis's own painting is `assets/art/gods/kaethis.jpg`, the back view from his set of four Tripo reference pictures (the god is only ever seen from behind; the hooded head sits in the upper third for the seal), so its seal (the medallion `DuelArt.god_medallion` cuts from the hood, on a Totem plate's patron mark and the Favour meter) is cut from the painting now instead of drawn; and his Tripo3D model of the god is rigged as a story character like Warden Hale (`assets/models/characters/kaethis.glb`, `tools/glb_bake_turn.py` then `tools/rig_character.py` with the shared clips, 2.30 m tall, `Figure3D.OWN_GAIT` kaethis), ready for the scenes that will show it; no scene calls it yet. His map of Veyl came too: `assets/art/map/veyl.jpg`, with where each place sits on it noted in `docs/veyl-map-prompt.md` for the "Choose a kingdom" code (not drawn by the game yet). Details and what was checked: `docs/handover/2026-11-08-files.md`. Still to come for Round 9: the Glyph Warden's painting, cut-out and model; Orlanthe's painting, Summon cut-out, sky scene and model; the five small card paintings (Cut Thread, Foreordained, Already Written, Hourglass With No Sand, Knotted Cord).

**12 November (more of Round 9):** the Glyph Warden is his own now: its card painting (`assets/art/cards/glyph_warden.jpg`, 1254 square as painted), its battlefield cut-out (`assets/art/creatures/glyph_warden.webp`, 560 high, framed as the others; rembg's isnet alone read the inlays' glow as see-through and took a door hinge from behind it, so its outline is isnet's and its inside u2net's solid figure, filled) and his Tripo3D model (`assets/models/creatures/glyph_warden.glb` + `_atlas.png` at 4096; its `ward_hold` renamed `guard`, its `dash` is read as run; bake, flatten, split as the others), so its `stand_in` is gone. Orlanthe has its card painting (`cards/orlanthe.jpg`, 1060 × 1484, the 5:7 of a Summon card) and his Tripo3D model (`assets/models/summons/orlanthe.glb` + `_atlas.png`, the same three steps, `ward_hold` as guard): `DuelField3D.summon_descend` brings it down the beam onto the field on its `spawn` clip, as the four Demigods'. Foreordained and Already Written have their paintings (`cards/foreordained.jpg`, `cards/already_written.jpg`). He sent Orlanthe's summon clip too (10 s, 1280 × 720 at 24 fps, with its own choir and sound): the first Summon clip in the game, as `assets/movies/summons/orlanthe_full.ogv` (all of it) and `orlanthe_short.ogv` (4.6 to 7.4 s of it: the book opening, the column of light, the figure in the Circle among the pages; a quarter-second fade at the end), Theora at 24 fps as made (his master and the short cut as .mp4 on the "films" release, for the apps). Since then a Summon whose clip plays doesn't start its stinger under it (`DuelScreen.fx_summon`): the clip's own sound and the stinger were two pieces of music at once; with Summon videos Off, or a Summon with no clip, the stinger plays as before. A filmed duel (`spec.film`, the Night of the White Sky) plays no clips at all (`fx_summon`, `fx_call`): its overlay is hidden, so before this Orlanthe's clip would have played unseen, its sound over the film for ten seconds and the card marked as seen; the memory keeps its own Summon and the stinger ringing into the white. Orlanthe's Summon cut-out and sky scene are still to come (both are needed for the drawn Summon scene, `SummonCine.has_art`, seen only with Summon videos Off; until both come that falls back to the drawn card). Still to come for Round 9: those two, and the paintings of Cut Thread, the Hourglass With No Sand (`hourglass_no_sand`) and the Knotted Cord. Details: `docs/handover/2026-11-12.md`.

**12 November (afternoon), Gary's yeses:** the Glyph Warden "barely moves" (a stone slab), so its purple and gold markings glow: `tools/split_creature.py --glow=rune` makes its emission map (`creatures/glyph_warden_glow.png`, 1024: the saturated violet inlays lifted towards a bright glow of their own hue, and the gold trim; 11% of the atlas) and `DuelField3D.FLARE` (`{"glyph_warden": 2.0}`) breathes it a little at rest and blazes it up over each strike (`_flare` from `play_clip(..., "attack")`, through `Slot.glow_boost` in `_tint_model`). Only its front carries the markings, so it stands in a ring of its own glyphs on the ground (yes from Gary the same afternoon: `assets/art/fx/glyph_ring.png`, drawn by `tools/make_glyph_ring.py`, violet diamonds edged in gold and the arches of its inlays; `DuelField3D._glyph_ring`, `GLYPH_RING` 2.5 m inside the 3.1 m rune circle): it breathes with the markings, turns slowly against the rune circle, blazes up and out a tenth as it strikes, throws up violet sparks (`rise` from `_flare`) and goes out as it turns to glass, so the glow shows from behind too; `tests/totem_peek.tscn -- <dir> <yours> <theirs> [arena] strike|strike_theirs` takes stills through a strike. In the Night of the White Sky the Last Page's camera moved (Gary: "we want to see it"; `WhiteSky.CLIMAX`): Orlanthe came down behind Bram's middle Totem, seen from low behind him; now the camera is behind him and to his right, above his head and back far enough that all 4.8 m of Orlanthe stands in the picture once it lands (from (2.0, 2.4, 12.0), lens 42; the descent ends 0.4 m higher and 0.6 m further back, looking at (0, 2.0, −0.8)), his back low on the left, the Unspent Hour beside him, the hunter's pack to the right. (A nearer camera between his Totems, tried first on the watched duel, cut it off at the waist once the duel was played and the Loomwarden had fallen.)

### Synergy: families, side by side, reactions, bonds, chains and the gods (28 October)

Gary (28 October): "to add synergy to the card game how would i go about
doing that", then of the five ideas sent back "i like all of that lets add it
all just make sure we put the training throughout the game so the player
fully understands the game", and "i also want all cards linked to a god it
doesnt have to be one of the main 7 but that means each will work for or
against depending where your battling and where standings are with
different gods". The data and words are in `scripts/duel/duel_synergy.gd`
(`DuelSynergy`); `DuelGame` applies them (its "synergy (28 October)"
section). `DuelGame.synergy` says which are on in a duel: all, as
`DuelRules.synergy` (the Lab's tuning list has it); none in the Lantern
lesson (`spec.tutorial`) or on a set board unless it names the ones it's
about (`puzzle.synergy`); `spec.synergy` names them for any other duel.

- **Families** (`DuelSynergy.FAMILIES`, `FAMILY_OF`): seven kinds across the
  elements, printed on the card after BASIC TOTEM. With another of its
  family on its side, each has its family's Kinship: Hounds (Pack: 10 more
  for each other Hound), Foxes (Trickery: +3 on Fate rolls), Cats (Prowl:
  Swift), Winged (Flight: Life over the Totem opposite, never past a
  Guardian), Scaled (Shed Skin: heals 10 a Dawn for each other), Shells
  (Hardened: 10 less from every attack) and Stoneborn (Rockslide: the free
  Strike 20 more). Two new Rites: Pack Howl (Hounds 20 more this turn; in
  Dask's deck) and Call of Kin (search a Totem of a family you have out); both
  in the Codex pool, both with stand-in paintings until Gary's.
- **Side by side**: two Totems of one element in neighbouring slots each deal
  10 more; Shelter (Shellguard, Gilded Sentinel: the Totems beside it take 10
  less from attacks), Rally (Emberwisp, Dawnling, Shieldhound: 10 more) and
  Tend (Lantern Moth, Bloomsprite: 10 at Dawn) are keywords
  (`DuelCards.KEYWORDS`). The computer places Totems for it
  (`DuelAI._beside_value`).
- **Reactions** (`DuelSynergy.REACTIONS`): a hit of one element on a Totem
  with a certain condition: Melt (Fire on Frozen: 20 more, Soaked), Shatter
  (Earth or Metal on Frozen: double), Steam (Tide on Burned: 10 more,
  Blinded), Flare (Fire on Poisoned: 20 more, the poison gone), Conduct
  (Storm on Soaked: 20 to each Totem beside it), Freeze (Frost on Soaked:
  Frozen), Overgrow (Verdant on Soaked: Rooted), Firestorm (Storm on Burned:
  20 more, the Totems beside it Burn), Rend (Metal on Bleeding: 20 more),
  Nightmare (Psychic on Asleep: 20 more, and it stays asleep). Attacks and
  damaging Rites both react; the aiming chip names the reaction.
- **Bonds**: four more (Flood, River Hound and Brookfin: 40 to every Totem
  across and Soaked; Lantern Watch, Hallowed Hound and Lantern Moth; Rime
  Runes, Rimecub and Runeowl; Night Sky, Starling and Duskstalker). A Totem
  can be in more than one now (`DuelCards.bonds_of`; Brookfin's other is
  Riverwall with Shellguard).
- **Chains** (`DuelPlayer.cards_played`): every card played on your own turn
  counts; the third costs 1 less (`DuelGame.chain_discount`), and a Combo card
  played third or later does more (a Totem comes in Empowered; a Rite deals
  or gives 20 more): Sparkkit, Mirewidow, Burrowmole, Runeowl, Firebrand,
  Thunderclap, Jagged Shards, Siphon Rune, Rejuvenate, Bulwark, Forge Edge.
  The turn line counts the chain.
- **The gods** (`DuelSynergy.god_of`): every card answers to one, printed at
  its foot: its element's god, or (`CARD_GOD`) Ysolde for the fire that
  unveils and a god for each card of no element. Two lesser gods are new:
  Ellowen, the Lantern Keeper (spirit; Ashford's Lantern Festival is hers)
  and Orrun, the Stone Warden (earth). Each Circle is a god's ground
  (`ARENA_GOD`: Ashford Ellowen's, Solhaven Solmaris's...; a Law's god's
  ground under a Law; `spec.place_god` says otherwise, "-" for nobody's: the
  Thornwood campfire and the road). A card is Graced on its god's ground or
  when its god is Pleased with you (Standing 2 and up), Shunned on its god's
  rival's ground (`RIVALS`) or when it's Displeased (-2 and down); both cancel.
  A Graced Totem hits 10 harder, any other Graced card costs 1 less; Shunned,
  10 less or 1 more. The player's standing comes from `Standing.value`
  (`DuelScreen._player_standing`); a rival's from their patron. A ribbon on a
  hand card and a tag on a plaque say which; the corner says whose ground.

Where it's taught, each the first time it matters (`DuelTutor.lesson`, kept
for How to Duel's new chapters: Working together, Families, Side by side,
Reactions, Chains and Combos, The gods' grace; and its own riddle):

| Where | What | How |
| --- | --- | --- |
| Tam's friendly game | chains, Combo | a memory of Bram as the player's second card goes down (2 November; until then Tam said it in his own words, `spec.teach`, `teach_lines`, gone); a note after a win |
| Nell's friendly game | whose ground, Graced | a memory of Bram at the first turn, four lines: Ashford's Circle is Ellowen's (2 November; until then Nell's own lesson); a note after a win |
| Bram's campfire, Dask on the road | families, side by side, Shelter/Rally/Tend, reactions | Bram, the first time each happens (`lessons`); Dask's pack and his steel (Pack Howl, Rend) bark it |
| Hale at the gate | Shells, Shelter, Solmaris's ground | his Gate Watch stands shoulder to shoulder |
| Wren | chains | "Quick hands" |
| Ser Aldric | the gods | Solmaris keeps her own on the Sunspire |
| Bram's Riddles | one each | The Pack, Side by Side, Steel Finds the Wound, Third Time, Old Friends, Whose Ground |

Checked: `tests/synergy_test.gd` (every family, reaction, the chain and
Combo, the gods' grace by ground and standing, the bonds, every card has a
god), `puzzles_test` (all thirteen riddles), `duel_sim -- 1000`: 0
invariant errors, first player 51%, the decks within a few points of where
they were (Emberstorm 59%, Tidegrove 52-56%, Ironstone 41-44%, Veilwild 45%;
before, 58/56/43/44), duels about four turns shorter; `--synergy=kin,side`
turns only some on. `friendly_sim`: Tam 80% (82% before), Nell 54% (50%).
`fire_sim` now sets the campfire up as the screen does.
`tests/synergy_shot.tscn -- <dir>` takes stills.

### The turn, Stances and answers (Phase A of the deeper duel, 23 October)

**Since 27 October the turn's phases are off** (`DuelRules.phases`, false;
Gary: "I don't like the different stages of the fight, let's go back to how
we used to have it"): the whole turn is one free Main, calls, Rites, Wards,
Stances, Shifts and attacks in any order, the big button says END TURN all
turn, no band is built, and the start-of-turn and end-of-turn work happens
as before. Everything else from Phases A to E stays (Stances, answers and
chains, the Oaths Gary likes, and the rest). The Duel Lab's "Turn phases"
row turns them back on; `tests/phase_test.gd` checks the phase rules with
them on and the rest both ways. What follows describes them on.

Gary (23 October): "I want all of those added to the duels ... more like
Yu-Gi-Oh", built in phases A to E, each merged as it passes. Phase A is the
shape of a turn and answering on the rival's turn.

- **The turn has phases** (`DuelGame.phase`, `PHASES`): Dawn (conditions, the
  Law) · Draw · Main (calls, Ascension, Wards, Summons, Stances, Rites,
  Shifts) · Clash (attacks) · Main II (a Rite or a Shift) · Dusk. A band under
  the rival's plate names the one the turn is in (`DuelViews.PhaseBand`); the
  big button says where the turn goes next (TO CLASH, MAIN II, END TURN) and
  sends `{type: "next"}`, while "end" ends the turn from anywhere; a phase with
  nothing to do in it is skipped (`next_phase`, `clash_worth`, `main2_worth`).
  `phase_problem(kind)` is why an action can't be done now, and the screen
  says so on the card or the move ("Attacks come in the Clash"). The
  computer only offers what its phase allows (`DuelAI._candidates`) and asks
  for "next" when nothing's worth doing. The Lantern Duel's lessons were
  written before the phases: when Bram asks for an attack in the Main, the
  Clash comes by itself (`DuelHuman.choose_action`), and Corin's script moves
  the phase on for a step that needs a later one (`DuelHuman.Scripted`).
- **Stances** (`DuelTotem.stance`, `{type: "stance", totem, stance}`, free,
  in the Main, only for a Totem that could attack this turn): Strike;
  **Guard**, half of every blow turned aside until its owner's next turn and
  no attack; **Rest**, mended `DuelRules.rest_heal` now and `rest_essence`
  Essence held over to the owner's next turn, no attack or Shift, and it
  stays put. A stance is what a ready Totem does with its turn instead of
  striking, so a Totem called this turn (or asleep, stunned, frozen) has none
  to take; Rest's Essence comes at the next turn so a rest can't be turned
  into a call the same turn (with it paid at once the computer rested every
  Totem that couldn't attack and duels ran to the turn limit). The badge is
  on the nameplate, the pose on the model (`DuelField3D.set_stance`: a
  guard or rest clip when the model has one, else a held pose). The computer
  weighs Guard by the biggest blow that could land on the Totem (halved, and
  how likely it is to be the one hit) and Rest by the mending, against the
  Totem's best attack (`DuelAI._candidates`).
- **Answers** (Counter Rites, `"answer": true` with `"answers"` naming the
  events: attack, rite, call, ward, ward_spring): played only on the rival's
  turn, in the **response window** (`DuelGame._window`) that opens after an
  action is declared and before it lands. The rival of whoever acted is
  asked first (`choose_response(game, pi, event, cards)`); an answer can be
  answered by the other side, up to `DuelRules.chain_max` deep, and the chain
  resolves last in, first out: a cancelled answer does nothing, and the
  action stands or falls by what's left (`_resolve_answer`). Eight across the
  elements: Null Sigil (cancel an attack), Ashen Shroud (half its damage),
  Shieldwall Call (a Guardian takes it), Undertow Glyph (a Rite back to its
  hand, undone), Quicksilver Step (the Totem attacked swaps slots and the
  blow lands on what's there now), Root Toll (Essence when they call),
  Whisper of Pages (a card when they set a Ward), Rune Break (a Ward spent
  for nothing as it springs). Two Wards play from the hand too, once each a
  duel (`"from_hand"`, `DuelPlayer.hand_wards_used`): Lightning Reflex and
  Hushed Counter. Wards in their slots still spring by themselves, and a
  spring can be answered. An answer on the chain still counts among its
  owner's cards (`DuelPlayer.answering`, for the sim's card count). Essence
  left over from a turn is lost at the next Dawn anyway, so keeping some back
  for an answer is the real cost of answering. The screen's Respond strip
  (`DuelScreen.begin_respond`, `RespondStrip`): what's coming, the answers in
  hand (greyed when they can't be paid for), a countdown bar
  (`DuelRules.respond_secs`, stopped by the pause menu with the tree) and
  "Let it be"; a tap away from it lets it be. Options: "Ask me to respond:
  Always / Only when I can / Never" (`Game.settings.respond`). An answer is
  a link of light from the answerer's plate to what it answers
  (`fx_answer`); the computer's answers are previewed like its plays. The
  computer answers when the harm prevented (the blow's damage, a knockout,
  a Rite's worth) outweighs the card (`DuelAI.choose_response`).
- One answer card went into each starter deck in its own element (Quicksilver
  Step, Undertow Glyph, Shieldwall Call, Whisper of Pages) and Rune Break into
  Dask's; the ten cards' prompts are in `docs/card-prompts.md` (round 4),
  drawn placeholders until Gary paints them. Bram's one-off lessons the first
  time each matters: `phases`, `stance`, `answer`, `answered` (on the How to
  Duel page). Lab rows: Rest mends, Rest gives Essence, Answers in a chain,
  Seconds to answer. After Phase A `duel_sim 2000` plays 28.1 turns a duel on
  average (27.6 before), 2 draws in 2000, the decks between 47% and 54%, no
  invariant errors.

### Calling the big cards, and the discard (Phase B, 23 October)

- **Tribute calls** (`DuelGame.tributes_needed`, `DuelRules.tribute_tier` 3,
  `tribute_two_tier` 5): a Basic Totem of tier 3 and up costs one of its
  caller's Totems on the field as well as its Essence (tier 5 and up, two).
  The call carries them (`{type: "call", card, slot, tributes}`); they go
  to the discard and the new Totem may take one of their slots. The screen
  offers "Call it with a Tribute", then a picker for who steps down
  (`DuelScreen._begin_tribute`, with Cancel), then the slot; the step-down is
  a rise of light (`fx_tribute`). The computer gives up its least valuable
  Totems when the Legend is worth more (`DuelAI._candidates`). A story rule's
  own call (Wren's theft) pays none. **Hour of Need** calls a Legend free and
  without a Tribute while your Life is lower than your opponent's.
- **The discard as a resource**: **Second Dawn** (a Basic Totem back to the
  hand), **Rekindle** (one of tier 2 or lower back to the field with half its
  HP, `DuelRules.revive_hp`), **Rite of Ashes** (40 to every enemy Totem, only
  with three Totem cards of one element in your discard, `needs_ashes`).
  **Echo** (`"echo"` on the card): once a duel, when another of your Totems
  falls, a Totem card in your discard acts: Cinderpup deals 10 to the Totem
  that felled it, Brookfin heals your most hurt Totem 20, Pebblit gives you
  an Essence at your next turn (a shield, first tried, spoiled the Trial of
  Light's Tidegrove board, whose mirrors are two Pebblits and a Brassback),
  Blightrat poisons the one that felled it
  (`DuelGame._after_fall`). The discard is a pill on each plate; a tap opens
  it to read (`PlayerPanel.discard_rect`, `CardPicker.look_only`).
- **Special calls** (keywords): **Loyal** (Shieldhound calls itself from the
  hand into the empty slot, free, when a Totem of yours falls), **Rekindling**
  (Hearth Salamander climbs back from the discard at its owner's Dawn with
  half its HP, once a duel), **Riposte** (Veilfox: hit and still standing,
  the attacker is Confused), **Galvanise** (Stormcaller: hit and still
  standing, it becomes Empowered) (`_on_hit`, `_dawn_rekindle`).
- **Searches**: **Kindred Seek** (a Totem of an element you have on the
  field, the deck fanning out, `fx_search`), **Memory Thread** (a card from
  the discard on top of the deck); Traveller's Pack still draws two.
- Each starter deck has one Phase B card (Rite of Ashes, Second Dawn,
  Rekindle, Kindred Seek); Hour of Need and Memory Thread are in the pool.
  Prompts: `docs/card-prompts.md`, round 5. Bram's lessons: `tribute`,
  `echo`, `loyal`, `rekindle`, `search`. Lab rows: Tribute from tier, Two
  tributes from tier, Revived with HP share. A knockout resolved inside
  another (a Loyal call, an Echo's blow) is never counted twice
  (`_resolve_knockouts` skips a Totem already off the field).

### What Totems are, and building round them (Phase C, 23 October)

- **Bonds** (`DuelCards.BONDS`, twelve pairs by their Basic, so an Ascended
  form keeps its bond): while both stand on the same side, both gain a bond
  move (a move with "Bond with ..." under it) or a stat (+20 HP or +10
  damage). `DuelGame.refresh_bonds` keeps them current (every
  `state_changed`); a bond move is checked again as it's used. A BOND pill
  on the nameplate, a thread of light when one forms (`fx_bond`), the
  partner and what the bond does in the Codex (`DuelCards.bond_text`).
- **Relics** (a new card kind, `"relic"`): given to a Totem of yours in the
  Main (`{type: "relic", card, target}`, one each), they stay until it falls
  (then to the discard; swept back with it to the hand). Ten: Ember Collar
  (+10 damage), Tide Pearl (+30 HP), Iron Brace (shielded 20 at Dawn), Thorn
  Crown (Thorns), Storm Feather (Galvanise), Veil Charm (Riposte), Sun
  Medallion (heals 20 at Dawn), Hunter's Fang (a Rend move), Stone Heart
  (Guardian), Spirit Lantern (draw two when it falls); Relic Hunt fetches one
  from the discard. The Relic's band under the nameplate; an amber RELIC
  band on the card (`DuelCardFace.spell_look`); a Relics filter in the Codex.
- **Veiled calls** (`{type: "call", ..., veiled: true}`, +1 Essence): face
  down until it attacks, is attacked, or its owner's Dawn
  (`DuelGame._reveal`). The rival sees a card back in the circle (2D and on
  the 3D field, `DuelField3D.sync`, `CardFaceDraw.veiled`) and a VEILED
  plaque; the call flies in as a card back with no clip, the log says only
  that a Totem was called face down, and tapping it gives nothing away. Six
  Totems have a **Reveal**: Dreamfox (the Totem across falls asleep),
  Mirewidow (poisons it), Emberwisp and Burrowmole (20 damage to it),
  Somnowl (draw one), Bloomsprite (your Totems heal 20). The computer veils
  when a Reveal is worth the Essence (`DuelAI._reveal_value`), and weighs a
  blow on a veiled Totem of yours by the blow alone, not knowing what's
  under the card (`DuelAI._hit_value_plain`).
- **The second Ascension stage**: Deepmaw was the only one; seven more
  (Infernal Warg, Tempest Lynx, Briar Colossus, Cragmaul, Ironclad Behemoth,
  Ninefold Fox, Blight Wyrm), each a turn after the first stage. Until
  Gary's paintings and models come they're shown as their line's first
  stage, bigger (`"stand_in"`, `DuelField3D.model_path`,
  `DuelArt.creature_or_stand_in`); the card shows the drawn placeholder.
- **Tempering** (Gary's rule): each spare copy re-absorbed in the Codex
  (`Game.reabsorb`) marks its card for good, three times at most
  (`Game.temper_of`): +20 Life, then the best Fate band on its first Fate
  move starts two lower, then a Tempered move (its strongest, +20 damage, one
  more Essence). The marks ride into the player's duels on a copy of their
  profile (`DuelScreen._start`, `DuelTotem.temper`, by the line's Basic) and
  show as ✦ on the nameplate and in the Codex. Bram's campfire deck tour
  has one more line about it (`PackTour.CAMP_DECK`).
- Each starter deck has a Relic (Ember Collar, Tide Pearl, Iron Brace, Veil
  Charm) and Emberstorm, Ironstone and Veilwild a second stage (Tidegrove has
  Deepmaw). Prompts: `docs/card-prompts.md`, round 6 (the seven second
  stages need a painting, a cut-out and a model each). Bram's lessons:
  `bond`, `relic`, `veiled`, `revealed`.

### The ground, the gods and the stakes (Phase D, 23 October)

- **Arena rules** (`DuelGame.ARENA_RULES`, `arena_now`): every Circle has a
  rule for both duellists, all duel long. Ashford's green: none (the
  beginner's Circle). The tidegrove Soaks a Totem at each Dawn; the
  emberforge Burns the Totem a springing Ward catches; at ironstone both
  Guards are 5 higher (`DuelRules.arena_guard`); the veilwild veils each
  duellist's first call, free; at Solhaven, whoever has fewer Totems at
  their Dawn gains 1 Essence. The screen sets `game.arena` from the duel's
  arena, except in a story duel with its own rule (its rule stands in the
  arena's place) and on the Trial's board. The rule is written under the
  turn count, and a ripple and a line of text show it acting
  (`fx_arena_rule`).
- **Terrain Rites** (op `"terrain"`): Flooded Circle, Forge Ground, Iron
  Ground, Veilwild Mist and Sunlit Court turn the Circle into that arena,
  its rule with it, for three turns (`DuelRules.terrain_turns`, counted at
  each Dusk, `_terrain_tick`); another Terrain Rite takes its place. The
  field's look changes with it (`fx_terrain`): on the 3D field the new
  floor and scenery fade in over the old, a wave of its colour runs across
  the Circle and the hall light and haze take its tint while it holds
  (`DuelField3D.change_arena`); on the flat field the painting cross-fades
  (`Arena.fade_to`).
- **Continuous Rites** (`"continuous": true`, a `"standing"` effect): they
  stand beside the Wards (STANDING, tap one to read it), two a side
  (`DuelRules.continuous_slots`); a third sends the oldest to the discard,
  and **Unbind** sends one of the rival's there. Six: Kindled Banner (Fire
  Totems +10 damage), Tidewell (heals 10 from each Totem at Dawn), Iron
  Tithe (the rival's Wards and Rites cost 1 more), Thorn Hedge (an attacker takes 10),
  Storm Spire (Storm Totems attack the turn they're called), Shadow Veil
  (the first call each turn veiled at no extra cost). A green STANDING RITE
  band on the card, TERRAIN RITE on the five.
- **Favour** (`DuelPlayer.favour2`, in half points, 0 to 10): it fills as
  you play your god's element (calls, Rites, attacks with its Totems) and
  follow its way, by the god's attribute (`DuelGame.WAYS`: presence calls,
  might attacks, resolve stances and Wards, swiftness shifts, cunning Wards
  and Rites, insight Rites and Ascensions, intellect Rites and Relics),
  twice as fast under the god's own Law; the Unsworn fill it from anything
  at half pace. Full, it opens the Gift again, or brings the god's Demigod
  (the Summon of its element: Dawnmane, Pyraxis, Thalassa, Somnyx) down from
  no card, free (`{type: "demigod"}`); either empties it. The Unsworn's
  second Unbound Will draws three and gives an Essence. A ring round each
  god's seal on the plates and round the Gift button; tap the Gift to
  choose.
- **Oaths** (`DuelGame.OATHS`, `{type: "oath", oath}`): sworn on your first
  turn (a Swear an Oath button in the turn's choices) and once more
  mid-duel (the Menu): the Swift End (win by your eighth turn), the
  Faithful (win with a Totem of your god's element on the field; not for
  the Unsworn), the Unbowed (never let your Life fall under half). Sworn,
  Favour fills 3; broken, it costs 30 Life (`DuelRules.oath_life_cost`);
  kept, the win's Resonance is a quarter more (`DuelRewards.OATH_MULT`). A
  ribbon across the foot of the god's seal (UNBOWED, OATH KEPT, BROKEN).
  The computer swears sometimes at the start (not in story duels,
  `game.ai_oaths`). A story rival's line for it can be added to a duel's
  `bark_on` as "my_oath", "my_oath_broken" or "rival_oath_broken" (none is
  written yet: that's the story's).
- The starter decks have Phase D cards (Emberstorm: Forge Ground, Kindled
  Banner; Tidegrove: Flooded Circle, Thorn Hedge; Ironstone: Iron Tithe;
  Veilwild: Veilwild Mist, Shadow Veil). Iron Ground was tried in Ironstone
  and left out: the computer had little use for it, and the deck did 6
  points better with a Healing Draught in its place. The Duel Lab picks the Circle (its rule under the buttons) and has
  rows for the new numbers. Prompts: `docs/card-prompts.md`, round 7.
  Bram's lessons: `arena_rule`, `terrain`, `continuous`, `favour`,
  `favour_rival`, `oath`.

### Decks that play differently (Phase E, 23 October)

- **Seven ways of playing** (`scripts/duel/duel_archetypes.gd`,
  `DuelArchetypes.ARCHETYPES`), one for each pair of elements: Burn and
  Gamble (Fire, Storm: the Emberstorm starter's), Outlast and Heal (Tide,
  Verdant: Tidegrove's), Guard and Counter (Earth, Metal: Ironstone's), Veil
  and Reveal (Psychic, Venom: Veilwild's), and three for elements with no
  deck: Dawn and Blessing (Radiant, Spirit), Frost and Stillness (Frost,
  Mystic), Stars and Shadow (Astral, Umbral). A deck's way is the one its
  Totems' elements lean to (`DuelArchetypes.of_cards`); the deck builder
  shows it.
- **Each way's three cards** (`"archetype"` on the card): they work only
  while a Totem of the way's elements stands on your side (`DuelGame.archetype_problem`;
  the card says so first). Burn and Gamble: Stoke the Coals (each Burned
  enemy takes 20), Loaded Dice (Fate +3 this turn, draw), Wildfire Pact
  (standing: Burn deals 10 more). Outlast and Heal: Deep Roots (heal 20 each,
  shield the unhurt), Tidal Reserve (standing: 5 Life per heal), Still Waters
  (a card per unhurt Totem). Guard and Counter: Counterweight (an answer: the
  blow lands 20 lighter and the attacker takes 20), Stone Patience (damage
  twice your Guard), Bastion Banner (standing: Guarding Totems take 10 less).
  Veil and Reveal: Unmasking (your veiled Totems turn up, each Reveal twice),
  Whispering Shroud (standing: a reveal draws a card), Venom Mask (call a
  small Basic veiled and free). Dawn and Blessing: Sunward Vow (all Blessed,
  heal 10), Lantern Vigil (standing: a fall gives 20 Life and a card), Kindled
  Soul (a tier 3 or lower Totem back from the discard). Frost and Stillness:
  Deep Winter (standing: Frozen enemies take 20 more), Shatter (50 to a Frozen
  enemy), Glacial Ward (Freezes an attacker). Stars and Shadow: Constellation
  (one of your top three to the hand), Eclipse (standing: the rival's Fate 2
  lower), Shadow Step (Blind and draw).
- **Six new Totems** for the three new ways: Dawnling, Hallowed Hound
  (Loyal), Rimecub, Runeowl, Starling, Duskstalker. Until Gary's paintings
  and models come they're drawn as another creature in their own element's
  colour (`"stand_in"`, `"stand_in_tint"`: on the 3D field the stand-in
  keeps its own paint, washed a little towards that colour,
  `DuelField3D._tint_model`, `DuelArt.soft_tint`; the flat field's cut-out
  takes the same wash. Until 27 October its solid surfaces went plain in the
  colour, and Tam's River Hound, a Shieldhound stand-in, stood on the field
  as a glowing blue lump: Gary, "blue for some reason"; since 28 October
  she's Gary's own model).
- **No new starter decks.** The seven ways have sample decks
  (`DuelArchetypes.DECKS`: the four starters with their way's three cards,
  and a deck for each new way) in the Duel Lab's deck list and for the
  balance tests (`duel_sim -- N --ways`). The new cards reach the player as
  the story goes: after a won story duel one card they haven't met comes
  into their Codex, from the pools the chapter has opened
  (`DuelArchetypes.POOLS` by Seals won: every deeper-duel card no starter
  carries first, the Radiant, Spirit, Frost and Mystic cards after the first
  Seal, the Astral and Umbral after the second), and Resonance can then
  build it (`Game.record_win`, "New in your Codex" on the result). Tamsin's
  stall (Still to Make, crowns) can sell from the same pools when it's built.
- **The computer's plan** (`DuelAI._plan_for`, `_apply_plan`): it reads its
  deck's way and plays to it: Burn and Gamble attacks harder and likes Burns
  and Fate moves, Outlast and Heal heals gladly and Guards, Guard and
  Counter Guards and keeps Essence back for an answer it holds, Veil and
  Reveal veils and prizes Poison and Sleep, Dawn and Blessing prizes boons
  and calling the fallen back, Frost and Stillness prizes Freezing and
  Silence and holds its answers, Stars and Shadow leans on Fate and Blinds.
- Prompts: `docs/card-prompts.md`, round 8. Bram's lesson: `way`.

The Lantern Duel is a gated tutorial (`scripts/duel_ui/duel_tutor.gd`, lines in
`LESSON` in `scripts/world/areas/ashford.gd`): each explanation waits for a tap and
each instruction locks everything but the one thing to tap (including the tap on
the die for who goes first, and the card panel on the right). Both decks are dealt
in order, the player goes first, Corin follows a script (`DuelHuman.Scripted`) and
the player's Life and Totem can't drop to zero. It teaches only what's on the table
that night; everything else is taught the first time it matters, in the same gated
way, by Bram, at any duel he's at (Master Script v3: the practice round and Dask's
road duel): the first condition or boon to land on either side (`fx_status`,
which also gives it a Codex entry under *Conditions*), the first Ward set or
sprung, the first hit on a weakness, a Guardian, a Gift, a Summon, and the first
time an Ascension can be played. A duel with `spec.lessons = true` gets a tutor
just for these one-off lessons (`DuelTutor.lesson()`); each is taught once ever
(`Game.learn()`), and every line Bram has given is kept, in order
(`Game.lessons()`). Since 25 October the pause menu's **How to Duel** page is a
manual rather than that list (Gary: "it needs to be a proper easy-to-read
manual of everything you have been shown or learned"): `scripts/ui/duel_manual.gd`
(`DuelManual.sections()`) writes a chapter for each thing in plain words, with
the real numbers from `DuelRules` (the aim, the cards, the hand and the deck,
Essence, the Circle, a turn step by step, attacking, knockouts, stakes, Rites;
then the elements with the chart, Fate, Wards, Stances, Answers, Shift, tiers,
Tributes, veiled calls, Relics, Summons, Ascension, ways, Bonds, Guardians, the
ground, Continuous Rites, Favour, Gifts, Oaths, the discard, searches, the
pack, and the conditions met), the basics from the moment the player has a
deck and the rest as each lesson id is learned. Bram's own lines still go into
`Game.lessons()` as before (the tests and the pack tour read them).

### A Rite's own picture on the field (25 October)

Every Rite plays a picture of what it does on the 3D field, where it lands
(Gary: "when you use the Bulwark card have it actually animate putting a wall
around the Totem, then fades; same for others"): `DuelField3D.rite_motif(card,
at, ahead, col)`, called from `DuelScreen.fx_rite` for the Totem it's aimed
at, for every Totem across the Circle for an `all_foes` Rite, or in front of
the caster's row for a Rite on nobody (`plate_world`); the screen waits for
it. The motif comes from the card's effects and element, so each card fits:
a shield is a half-ring of stone slabs rising round the Totem on its enemy's
side, standing a moment and sinking (`wall_ring`; another element's shield
is the same wall in its light); healing a warm ring and a green column
(`mend`); a buff a ring of light climbing the body (`aura`); a draw or a
search cards rising and fanning (`cards_fan`); Essence motes gathering out
of the air (`essence_motes`); a bounce, a drain or a push a wave sweeping
over (`wave`: a body of translucent water with a rolling white crest); a
condition its own thing (`status_motif`: Frozen a block of ice that closes
round the Totem and shatters, Burned flames, Poisoned and Corroded a low
cloud, Soaked rain, Rooted roots, Petrified a rockfall, Shocked and Stunned a
bolt from above, Blinded a white flash, Bleeding a red burst, the mind and
soul conditions a swirl of light in their colour); and plain damage by
element (`strike_motif`: fire flares, storm strikes down, tide sweeps, frost
and verdant spike up, metal flies, venom rolls low, wind whirls, earth falls,
the gods' elements come down as light). The pieces are `wall_ring`, `spikes`,
`ice_block`, `flames`, `wave`, `rain_sheet`, `cloud`, `swirl`, `rockfall`,
`mend`, `aura`, `cards_fan` and `essence_motes`, on top of the field's older
`pillar`, `floor_wave`, `burst`, `rise`, `flash_light`, `flash_sprite`, `bolt`
and `lightning` (which can now strike straight down: a vertical bolt had no
side against UP and drew nothing). `tests/rite_shot.tscn -- <dir>` takes a
still of each part-way through (Brookfin and Cinderpup across the Circle).

Story duels (Master Script v3) each have a rule of their own that says who the
opponent is, as a real rule in the engine: `spec.story_rules = {rule id: side}`
(`DuelGame.story_rules`, one `_rule_<id>()` each) and `spec.rule = [name, text]`
for its banner, shown after "DUEL!" and held until it's tapped (or E, Space,
Enter, a pad's A; 23 October, Gary: "you don't have long to read it"), as the
Law's banner is; both are on the duel's Menu (☰) for the rest of the duel.
A test driving the screen taps a waiting banner with `ds.tap_banner()` (it
never waits when the computer plays the player's side). Every model a duel
could call (both decks' Totems and Summons) is loaded in the background and
drawn once under the Circle's floor as the duel opens
(`DuelField3D.warm_models`), so no summon reads its model from disk or
compiles its shaders on the spot (Gary: "the battle's a bit glitchy when you
load a Totem"). The Prologue's: Dask's Run to Ground (his
hounds always attack the Totem with the least Life left). Chapter 1's
(`scripts/world/solhaven/duels.gd`): Warden Hale's Hold the Gate (while his
Guardian stands his Totems never go for your Life; the duel is at half Life,
`spec.life_scale`), Wren's Light Fingers (once a duel, from her second turn,
she takes the best card she can play out of your hand and plays it as hers),
Ser Aldric's Sunspire's Mirror (at half Life his Radiant cards cost one less and
Dawnmane, kept off his deck in `spec.kept_back`, comes to his hand and is called
down the moment he can pay; the crowd names it, `spec.crowd_on`; the first time
your Life drops below a third the blank card shows the seal, `spec.blank_eye`)
and the Trial of Light's `mirror_trial` (a set board, `spec.puzzle`: the
mirrors only watch, your Essence is the Summon's cost every turn, and you have
three turns; a mistake is `spec.trial`, Liora's line and the board set again).
Their barks are tied to what happens on the board, once each per duel
(`spec.bark_on`, `DuelScreen.story_bark()`: the rival's first Fate roll, a
Poisoning, a Ward springing, your lethal, a weakness hit, one of theirs or yours
knocked out, their Guardian hit or falling, their Gift, their steal, their
Summon, your Summon, your 60-or-more hit, their Life under a third, you pulling
ahead), said by `spec.bark_who` if it isn't the rival; a duel can name its music
(`spec.music`). Losing a main story
duel (`spec.retry`) plays the opponent's line for winning (`spec.win_line`), then
Morrowen takes the story back with one line, never the same one twice running,
then a page turning back and **Again** / **Change deck first**; after a second
loss only the page (`scripts/duel_ui/story_loss.gd`; her voice is
`assets/audio/vo/morrowen_loss_01.ogg` ... `_04` and the page `assets/sfx/page_turn.wav`,
Gary's recordings since 20 October). From the night of the Sigilfall on, the blank card
sits in its own slot beside the deck in every story duel and flickers when Life
runs low (`scripts/duel_ui/blank_card_slot.gd`).

```sh
godot --headless --script res://tests/story_rules_test.gd          # every story duel's rule, and 120 duels under each
godot --headless --script res://tests/trial_puzzle_test.gd -- 4000 # each Trial board's answer wins; no line without the Summon on turn 1 does
xvfb-run -a godot --rendering-driver opengl3 --resolution 1280x720 res://tests/road_duel_test.tscn -- <dir>   # Dask's duel lost twice, then won
xvfb-run -a godot --rendering-driver opengl3 --resolution 1280x720 res://tests/solhaven_duels_test.tscn -- <dir> [hale|wren|trial|aldric] [2d]
    # Chapter 1's duels: played by the computer under each rule, lost (the Trial reset three times), then won (2d: the flat field)
```

```sh
xvfb-run -a godot --rendering-driver opengl3 --resolution 1280x720 res://tests/creature_shot.tscn -- <dir> blazehound   # a duel with a given Totem on the field
```

The rules are written up in the "Duel Rules v2" Claude doc
(https://claude.ai/artifact/P1gUzZ7eRcTEe175qadyCd: its page title still says
v1; "The deeper duel" section has Phases A to E, and "A turn" the new turn),
and the story in the "Master Script" doc. The Duel Lab's Kingdom Law picker plays any duel under a
god's Law.

**Play it on a phone:** https://fg29cw8knf-wq.github.io/covenant-war/ (turn the phone sideways; in
Safari use Share > Add to Home Screen for a full-screen app icon). Rebuild it with `tools/build_web.sh`
and push `build/web` to the `gh-pages` branch.

**Edge to edge on a phone.** The game fills any screen shape (an iPhone 16 Pro Max
held sideways is 2.17:1): the 1920 x 1080 base stretches sideways (`canvas_items` +
`expand`), the opening movie's paintings and shot clips fill the screen (cropping a
little top and bottom, `OpeningMovie.frame_rect()`; Gary's finished cut is
shown whole, `cut_rect()`), and the duel's 3D field
covers the whole screen on any shape, the iPad's 4:3 included
(`DuelField3D.fit_to_stage()` widens the lens to match). The buttons and words
keep clear of the Dynamic Island, the rounded corners and the home bar through
one helper, `SafeArea` (`scripts/ui/safe_area.gd`): `SafeArea.fit(control)` keeps
a full-screen control inside the safe area, `SafeArea.rect()` / `insets()` give
the margins. It reads `DisplayServer.get_display_safe_area()` in the apps and the
page's CSS `env(safe-area-inset-*)` on the phone link (`tools/build_web.sh` adds
`viewport-fit=cover` to the page so Safari doesn't leave bars beside the island;
the Home Screen app is full screen, `progressive_web_app/display`). The iPhone
app hides the status bar and the home bar and holds back the edge swipes
(`display/window/ios/*` in `project.godot`). Check every screen at a phone's
shape with a pretend safe area:

```sh
xvfb-run -a -s "-screen 0 2900x2200x24" godot --rendering-driver opengl3 --resolution 1434x660 \
    res://tests/screen_fit_test.tscn -- /tmp/fit --safe-area=93,0,93,32 mark   # an iPhone 16 Pro Max at half size
```

`--safe-area=L,T,R,B` (window pixels) works on any run of the game; `mark` draws
the island and home bar on the screenshots, and the test lists any button
outside the safe area. The phone link's page is checked in Chromium dressed as
the iPhone held sideways, with its safe area:

```sh
tools/build_web.sh && python3 tests/web_fit_check.py build/web /tmp/webfit   # viewport-fit, full-screen app, canvas, safe area; screenshots
```

Options also has **Text and buttons size** (Normal, Larger, Largest,
`SafeArea.ui_scale()`), which draws the world's buttons, the conversation box,
the pause menu, a card's detail and the films' words bigger for a small phone
(add `ui=1.3` to the screen-fit test to see it); also the title screen's
buttons (the title above them shrinks a little if they need its room), the
opening notice (as big as fits), the campfire's deck card and objective,
Bram's pack tour box, and in a duel Bram's lesson box, the rival's barks and
the result box. The rest of the duel (its board is one fixed layout) and
the Duel Lab (a test bench) keep their size.

A phone browser runs out of memory if it loads the whole game at once, so the web
build comes in parts (`tools/web_packs.py` says what's in each, and `build_web.sh`
keeps the export presets in step with it): a main pack (title, menus, Ashford,
Thornwood), then `packs/movie.pck` (the opening movie), `packs/duel.pck` (the duel
Totems and Summons; the moth and the hounds the films need stay in the main pack)
and `packs/solhaven.pck` (Solhaven's script and anything in a `solhaven/` folder),
each downloaded the first time it's needed, with a loading bar (the movie's has a
Skip button too (about 78 MB for Gary's finished cut), since nobody should sit through its download to skip it:
`Packs.need("movie", true)` returns false if it's pressed, and New Game goes
straight on to Ashford; if the movie's over before Ashford is ready a
"Lighting the lanterns in Ashford" bar holds the screen, `Packs.hold()`). Code
that needs one awaits it first: `await Packs.need("duel")` (`scripts/game/packs.gd`; it
returns at once in the apps, the editor and the tests, where everything is in one
pack). `docs/`, `tools/`, `tests/`, `lookdev/` and `assets/audio/source/` are
never exported. `python3 tools/pck_list.py build/web/index.pck` shows what's in a pack.

The title screen and the pause menu's Options page show **Early build** followed by
the date and time (UK) the build was made: `tools/build_web.sh` and
`tools/build_ios.sh` write it into `build_info.cfg` for that build only. A game run
from the editor shows the version number instead.

**Play it on a Mac:** download
https://github.com/fg29cw8knf-wq/covenant-war/releases/download/mac/CovenantWar-Mac.zip,
unzip it and open The Covenant War (the first time: System Settings > Privacy &
Security > Open Anyway; `docs/mac.md`). `.github/workflows/mac.yml` rebuilds it with
`tools/build_mac.sh` every time `main` changes. Full quality, one pack, and
Gary's opening film at 4K through the Mac's own player (the native video
player, below).

**Play it on an iPhone as an app:** download
https://github.com/fg29cw8knf-wq/covenant-war/releases/download/iphone/CovenantWar-iOS.zip
on a Mac, open `CovenantWar.xcodeproj` in Xcode, choose your Apple ID as the team
and press Run. `docs/iphone.md` has the steps, including for a free Apple ID.
`.github/workflows/iphone.yml` rebuilds it with `tools/build_ios.sh` every time
`main` changes. The app has everything in one pack at full quality: Forward+ (as on
the Mac; Android keeps the Mobile renderer) and ASTC textures, and Gary's
opening film at 4K 60 fps through the phone's own player (the native video
player, below).

Every story duel is on the v2 duel now; the older rules below (`scripts/core/`, `BattleScreen`) are only what `Main.run_duel` falls back to for a spec without decks. While a duel is on, the place it was started from is hidden and stopped still (`Main.run_duel` sets the world's `process_mode` to disabled and puts it back after): until 27 October Ashford's whole festival kept running under the first duel, every villager's animation and every script, and on the phone it ran slow and kept freezing (Gary). An empty slot's lamp on the Circle is switched off, not just turned down to nothing (each light costs the phone another pass over the floor).

## Story mode

**5 November, Gary's files (`docs/handover/2026-11-05-pm.md`):** Dask's heavy
crossbow (`ashford/crossbow.glb`, 0.65 m, `split_glb.py`) in his hands on the
Thornwood road, held low in both (`Thornwood._crossbow`: the butt by his right hip,
`Figure3D.carry` and `reach` keep both hands on it; the drawn one stands in if the
file is missing). The second merchant cart (`ashford/merchant_cart_b.glb`) in its
place by the first (`AshfordVillage` already looked for it), thrown over at midnight
with it (`shatter_carts`). The Thornwood shelter's stone doorway
(`ashford/shelter_door.glb`, 3.45 x 2.41 m) where the drawn door stood
(`ThornwoodShelter`): its oak-and-iron door is cut out of the model and hung on its
hinge as "Leaf" (`DOORWAY_HINGE`), so Bram pushes it in (`DOOR_OPEN`), the dark of
the way in behind it; the drawn door and roots stand in if it's missing. Krell's
warhorse (`ashford/warhorse.glb`, Tripo's rig and clips: idle, walk, trot, canter,
run, gallop, rear, paw_ground, tail_swish, attack_kick, hit_react, victory, defeat,
summon; made in a unit box, scaled to 1.75 m at the withers): `AshfordNight.Warhorse`,
a Cine extra (`"warhorse"`), canters up the road with her bailiffs, walks onto the
green (`HORSE_WALK_IN`) and halts; Krell sits astride (`Figure3D.ride`: `ASTRIDE_THIGH`,
`ASTRIDE_SHIN`), her body put on the saddle every frame (`Warhorse.saddle`), her
ledger held over the withers (`LEDGER_RIDING`), and her lines shot from beside the
horse's head (`_krell_cam`); with no model she walks in as before. Tobin
(`characters/tobin.glb`, `tools/rig_villager.sh tobin`: Gary's Blender export, 1.30 m,
his own normal map) at the Golden Gate and in the side story (`Figure3D.MODELS`,
walk 1.28 / run 3.24); the sleeping child further back at the gate (`ref_3`) is
`child_b` now, not a second Tobin. Bram's White Sky lines (0002, 0003) and Nell's
"Tam!" (0218) are mastered by `vo_master.py --lines` into
`assets/audio/vo/ashford/bram/b3db9878.ogg`, `cb5440f1.ogg` and
`assets/audio/vo/ashford/nell/fad059d8.ogg` (`VoiceLines` finds them by the words,
in the 3D and in the Reckoning film's step). Nell's crying (5.9 s as recorded) is
`assets/audio/sfx/nell_crying.ogg`: `tools/far_off.sh <rec> <out.wav> nofade` (far
off and down the hill, no fades), then `tools/sfx_loop.py --pad 3 --fade 2` (a pause
between the bouts and the start crossfaded out of the quiet: a 7.2 s loop), looped
by `_nell_crying` under the bell. Tilly's music `tilly_moth` (Gary's 134 s,
scouted in three-time, looping 15.372 to 96.4 s; `Music.LOOP_START`) plays by the
well and when she gives her moth (the hooks were in since 2 November).

**5 November, scripts for Gary's yes (nothing built from them yet):**
`docs/script/v8_interlude_a.md` (Interlude A, The Hunters: between Solhaven and the
first kingdom, Krell's ambush at the Wend Ford, Dask warning you off it or leading
it by `dask_kept_hound` / `dask_sent_home`, duels with Dask and Krell, Wren saying
the name Kaethis), `docs/script/v8_corins_return.md` (Corin as a Notary of the
House at Gildersgate, the button, "Sprout", and the page you sign or don't) and
`docs/script/v8_return_to_ashford.md` (Ashford half a year on: Nell's mill, Tilly's
moth, Tam's stone, the Lantern). Each ends with its Writers' notes, the new things
it needs and numbered questions (Gary reads them as Claude docs, linked from Still
to Make 18); Interlude A's placement changes two small lines
in Pyreholt v1 (listed in its notes). The map of Veyl's painting prompt, with
where each kingdom lies and the label positions for the code, is
`docs/veyl-map-prompt.md`.

**2 November, later (Gary's files; `docs/handover/2026-11-02-pm.md`):**
Warden Hale (`characters/hale.glb`) and the Sun Guard (`sun_guard.glb`, every
guard in Chapter 1 and the gate warden) are Gary's Tripo3D models, rigged by
`tools/rig_villager.sh hale|sun_guard`, their portraits rendered from them;
Ironvault's second enforcer, the woman in grey (`enforcer.glb`, Hale's clips
fitted to her: `HALE=<his master> tools/rig_villager.sh enforcer`), is one
bailiff at the Reckoning (`h2`) and one grey coat in the look back (`g2`)
(`Figure3D.MODELS`). Tripo's Mixamo-rigged exports turn the figure a quarter
round in a node matrix above the armature: `tools/glb_bake_turn.py` bakes it
in first (and `tools/glb_trs.py` reads matrices as TRS). The Shellguard is
Gary's coral turtle, rigged by Tripo but without clips: `tools/creature_clips.py
--kind turtle` makes its eight from its own bones (idle, attack, hit, defeat,
spawn, run, victory, and guard, its stance: head and legs drawn in under the
shell). The Thornwood shelter has his shelves and iron pot
(`ashford/shelter_shelves.glb`, `iron_pot.glb`; `ThornwoodShelter._model`).
`corin_evening` and `solhaven_town` are in, looped (`Music.LOOP_START`);
Solmaris's lines 2 to 9 play in the Sun Court (Gary's files 02 and 08 held
each other's words; his 01 is a copy of 06, so line 1 stays a subtitle).
**Talk music:** Bram (`bram_theme`, the deck hand-over and his evening on the
green), Tam (`tam_mill`), Nell (`nell_waltz`) and Tilly (`tilly_moth`) each
ask for their own track while you talk to them (`{"theme": [...]}` /
`"back"`), and nothing changes until Gary's tracks come. Nell's crying loops
under the bell at the look back; `tools/far_off.sh` makes his close recording
sound far off when it comes. (Size: the Golden Gate's atlas and four props'
were shrunk for the phone link's 1 GB that night, then put back to full size
when Gary dropped the link: the gate at 4096, VRAM-compressed, the props at
2048.)
**4K pictures (2 November, Gary: yes to sharper people and creatures):** the
models Gary made in Tripo3D came with 4096 colour pictures, cut to 2048 by
the rig tools; Player A, Bram, Hale, the enforcer, Cinderpup, Brookfin, the
River Hound and the Shellguard have their 4096 back (`tools/atlas_4k.py
<master.glb> <atlas.png>`: the master's picture, with anything painted on
the game's copy kept, Bram's open eyes), VRAM-compressed at high quality
(ASTC 4x4 on iPhone, BPTC on Mac): in memory that's about what a lossy 2048
was, so the phone holds as many at once. Everyone AssetFurnace made (Corin,
Tam, Tilly, Nell, Hob, Ned, Krell, looks B to D, the crowd, the Sun Guard)
came at 2048 and stays so; remade in Tripo3D they'd come in at 4096.
`rig_character.py` (`--texture-size` 4096) and `split_creature.py` now keep a
Tripo picture's full size and import it that way. The Mac and iPhone builds
keep `.godot/imported` between runs (actions/cache), since the 4096 VRAM
pictures are slow to make.
**Full-size art and scenery (2 November, Gary: "can we make the scenery and
assets 4k?"):** the inn's atlas is back at 4096 (`atlas_4k.py`, its master
`crooked_lantern.glb`); the other buildings and props were made at 2048 (the
small ones 1024) and stay so until they're remade. Gary's painted art went
in at the size he painted it, matched to the game's files by what they show
(`tools/art_full.py <game dir> <his dir>`, his "Covenant Art" folder): 58
card paintings at 1536 (they were 640), the seven gods at 1536x2048 (512x682),
five arenas at 3840x2160 (2560x1440) and the four Summons' scenes at
3840x2160 (1920x1080), all VRAM-compressed at high quality, which on the
phone costs about what the smaller lossy ones did. Twelve more cards came
from his "card game folder" (`cards:<id>.png`, 1254) and Cinderpup's from
`cinderpup_3d_test 4/reference_card.png` (1536): 71 of the 72 at full size.
Left as they were: Rallying Light (a stand-in painting), the Ashford arena
(its original is the game's size) and the Summons' cut-outs (their
transparency was made in the game).

**2 November (Gary's playtest notes; `docs/handover/2026-11-02.md` has the
whole list):** every lesson in every story duel is **a memory of Bram**
(`DuelTutor`: a box headed A MEMORY OF BRAM with his face, faded a little;
Bram's hand-over says "all the years I've been teaching you about duels, you
know how to do them, just remember what I taught you", with no offer to
coach, and the Lantern Duel's gated steps are reworded as what he taught over
the years; Tam's and Nell's own lessons are gone, their games teach as the
rest do (`spec.lessons`, `skills_on` keeps their skills); the first draw from
an empty deck brings a memory on it (`DuelScreen._fatigue_lesson`, the number
tagged EMPTY DECK); the first-time lines are fuller). Getting out of bed: the
blanket hand keeps within the arm's reach (`AshfordP1._hand_can`), the seat
rises as the legs swing round so the feet clear the rail (`SWING_LIFT`), the
lift onto the mattress comes in over the blend, and the stretch is a clip of
its own built from the idle (`Figure3D.stretch`, `STRETCH`), not two IK
targets. The taproom: "You left the shutter unlatched again, Sprout."; the
slate prices in coppers; the settle is on the north wall under the notice
board, not in front of the fire (`InnRooms.EVE_SETTLE_X`); the porridge can
be eaten first (`AshfordP1._eat`, objective `crate_or_eat`, flag `p1_ate`);
the kitchen's and the passage's doorways turn the player back with a word
(`walk_room` "stray_zones", `DOORS_LATER`, `DOORS_FIRST`). The green's life
starts as the player steps out of the inn, not when the crate's down
(`AshfordLife` from `_street`). The lanterns are packed inside the crate's
thick walls (`PACKED_SCALE`, `paper_lantern(size)`). The card box sits on a
flat hand (`Figure3D.palm(..., flat 1.0)`), and the player takes it in both
hands from underneath, palms up, the right hand's mark hanging from the box
(`_first_deck`); `palm()` takes a `fingers` direction, so a hand on the side
of a thing points its fingers forward or up instead of folding at the wrist
(Tam's letter, flat fingers up). A talk that opens with questions shows who's
being talked to over them, not the last line said by whoever was last
(`DialogueBox.plate`, `close` clears). Normal battle speed is 1.2x
(`DuelScreen.NORMAL_RATE`). `tests/bed_probe.tscn` prints the rise's numbers;
`tests/box_hands_peek.gd` and `tests/crate_peek.tscn` take the close-ups;
`tests/pose_try.gd` tries bone turns.

**1 November (Gary's playtest notes; `docs/handover/2026-11-01.md` has the
whole list):** Ashford's people never stand frozen (`AshfordLife`, new: Corin
and the children move about, the adults turn, shift and chat; the old circle
of four walkers is two couples dancing); the taproom's crate waits on a side
table and is lifted with the knees and set down from a crouch
(`AshfordP1._crate_stand`, `_take_crate`, `CROUCH`); the inn has rooms behind
the taproom (`InnRooms._eve_tavern`) and the attic is dressed as his room
(`_attic_dressing`); standing figures carry themselves upright
(`Figure3D` `Posture` modifier, first in the chain); Corin's evening, the
awakening and the Herald are staged as films (`AshfordDay._corin_pond_film`,
`AshfordNight.awakening`, `Ashford._herald_3d`), midnight opens on the taper;
a talk can set its own music (`{"theme": [...]}` in a talk tree, `"back"` to
return; Corin's evening asks for `corin_evening`); a staged walk's turns are
moved off anything solid (`Cine.off_blockers`); friendly games (Tam's, Nell's)
deal no fatigue until both decks are empty and a Totem can't Guard two turns
running (`DuelGame.friendly`, `guard_turn`); the duel's text goes by a little
quicker at each reading speed (`DuelReading.LEVELS`).

**Since 24 October the Prologue follows Gary's Master Script v7**
(`docs/script/v7_prologue.md`, made from his v6 PDF beside it; the Claude doc
"Master Script v7" is the master). Where the code below still describes v3,
v7 wins; the parts it changed:

- **P1, the morning** (`ashford_p1.gd`): the attic on a frosty morning, Walk to
  the washbasin, the fogged mirror wiped clear, the name written in the frost
  (`ask_name`, the only name prompt now), the reflection hub, the mark
  (`SealMark`: ash-grey on the collarbone, on the Neck bone), Bram's taproom
  hub, the crate from the corner, the menu at the door, the crate down at the
  Lantern. The whole day is lit as day (`AshfordVillage.set_daylight(1)`).
  Since 25 October (Gary's notes from playing it): the shots from the glass
  are cuts, not glides through the player's head, and the picture is masked
  to the mirror's oval (`AshfordP1.mirror_mask`, a canvas layer under the
  dialogue box) so it reads as the reflection, not a wide shot up his chin;
  the taproom's bar stands forward of the west wall with a walkway behind
  it and a raised lift-up flap at its south end (`InnRooms.BAR_X`,
  `BAR_BEHIND`, `BAR_FLAP_Z`: Bram had stood inside the counter with his
  back in the shelves, and had no way out); Corin's strapped card boxes hang
  at his hip (`HIP_BOXES`, on the Hips bone) and his clerkship letter is
  tucked into his vest (`COAT_LETTER`: inside its right panel, the top
  corner showing; `tests/corin_props_shot.tscn -- <dir>` takes stills of
  both), where they had sat on his hand bones and stuck out of his arms.
  Since 27 October (Gary: wiping the glass showed "an outline of the body"
  and his face looked deformed) the glass holds a live reflection
  (`MirrorGlass`: a second camera on the far side of the glass, cut to its
  edges, drawn on a sheet over it; only while he's at it), the
  over-the-shoulder shot stands back off his head and to one side (the
  camera's near edge had cut into his hair), and the close-up in the oval is
  taken from about a metre away on the far side of the glass with a long lens
  and turned left for right (`AshfordP1._glass_shot`; the mask's `Flip`). It
  had been a hand's width from his face with a wide lens, his nose cut off.
  `tests/mirror_shot.tscn -- <dir>` takes stills of the shots.
- **The Lantern Duel first** (Gary): Corin comes over the moment the crate's
  down; his hub; "I would, but I don't have a deck."; Bram's hand on the
  shoulder, "You do now.", the box held out with Gary's "I've always told
  you..." line, the player takes it and the deck fans out, then "You've seen
  enough duels..." and his offer to talk you through it (a choice), the duel
  (no experience: spec `practice`), Corin yields, Gary's Bram lines and the
  two objectives. Bram's lesson says "one afternoon's worth. Today, just the
  basics." (it was "tonight"; the duel is in the afternoon) and names the
  stakes before the roll ("This one's a friendly: nothing to win or lose but
  your pride"), and the turn's six steps are taught in four short lines with
  the phase band lit (`DuelScreen.fx_phase`, lesson ids `phases`..`phases_4`,
  focus `band`) in place of one long one (they only play with the turn's
  phases on, which they aren't since 27 October). After the duel Corin sags,
  beaten, head down and shoulders gone (`Figure3D.slump`, held while he
  yields; `tests/slump_peek.gd` takes stills), instead of cheering his own
  loss (`AshfordDay.after_lantern`; 27 October: the flinch and the
  near-standing `defeat` clip that replaced the cheer looked "more scared
  than defeated").
- **The afternoon** (`ashford_day.gd`, `AshfordDay`): Tam at his watermill
  down the lane (`MillSet`, a set of its own at x 700, reached by the lane
  off the green's east side, out between two cottages to a field gate where
  the village ends: `AshfordDay.LANE_MOUTH`, `LANE`, `lane_gate`; since 27
  October, when Gary said the way there "doesn't make sense ... it's right
  next to houses": it was a glowing spot by a cottage wall with the old
  track running in under two roofs; back from the mill the gate won't take
  you again until you've walked off from it, and with nobody new to see down
  there it asks first, `_lane_go_again`, where walking back towards the
  houses had replayed Tam's scene; `tests/lane_shot.tscn -- <dir>` takes
  stills and a plan of it; since the evening of 25 October Gary's own
  mill house and waterwheel, `assets/models/ashford/watermill.glb` and
  `waterwheel.glb`, the house on a stone footing so the axle hole in its
  east wall meets the wheel's axle, its windows lit in the evening;
  `tests/mill_shot.tscn` takes its stills), his hub, the letter on screen,
  the Ledger note; Tilly's moth by the well (it circles her head) and the Standing note;
  Nell's hub; friendly games with Tam (River Hound) and Nell (Wards), no
  experience, repeatable (`ashford.gd FRIENDLY`). When all three are seen,
  talking to Bram makes the sun go down (`AshfordDay.sunset`).
- **The evening**: Tilly's thanks and her card, Tam's bread (since 27 October
  Gary's `festival_loaf.glb` on a bread board on its own little round table
  beside Tam all evening, `AshfordDay.festival_loaf` (the stall's counter is
  full of the stall model's own bowls and jars, and hid it), and his
  `loaf_piece.glb`, steam and all, the piece Tam reaches over and tears off
  it and hands across; `tests/new_cast_shot.tscn -- <dir> [stall]` takes
  stills), Nell's dance
  (tell Tam and he dances with her), Corin on the mill-race wall and his
  button (Items; since 26 October Gary's `assets/models/ashford/corin_button.glb`
  passes from his hand to the player's, the drawn disc if it's missing), Bram
  by the Lantern ("It's nearly midnight." starts it).
- **The merchant carts** (26 October): Gary's `merchant_cart_a.glb` twice,
  west of the blue stall where Corin sells his signed cards in the afternoon
  (`AshfordVillage.merchant_carts`; his `merchant_cart_b.glb` takes the second
  place when it comes), thrown over by the shockwave at midnight
  (`shatter_carts`, from `_midnight_3d`).
- **Midnight**: no mill fire; Find Corin; the cart heaved off him with a QTE
  (`CartHeave`: HEAVE/E/A again and again, PULL/F/X in the gold; it can't be
  failed); the white light, the mark blazing on the collarbone, Bram's coat,
  the collapse.
- **After midnight** (`ashford_night.gd`, `AshfordNight`; `ashford.gd
  FILM_PARTS`): the awakening in the attic before sunrise (how you take it:
  `temper_angry`/`afraid`/`resolved`), the dawn and the v7 Herald (heavy grey
  burial cloth torn at every hem, rusted chains, an empty hood:
  `PaleHerald.form = "shroud"`, its cloth `PaleHerald.CLOTH_SHADER`, its look
  checked with `tests/herald_shot.tscn`; it names you the Unsworn, no name
  prompt), That Day in the cellar (22 Ward marks), the Reckoning at dusk
  (Krell early, Tam's challenge, the cellar, the tunnel walked, Tam's duel to
  the death, the restraint magic; nothing burns, no blood), and the look back
  from the hill (walked; he steps down on his own; Bram's hand; Corin limping
  up with his farewell).
- **The Thornwood** (`thornwood_shelter.gd`, `ThornwoodShelter`): the shelter
  in the hillside, the four class boxes (Mercenary, Scrivener, Ferryman,
  Unsworn), the tour, Bram's lesson (no experience; his two glimpses are the
  duel's lines `rival_ward_springs` and `my_ascends`), the morning, Dask by
  day (Player B, a crossbow; Run to Ground is +10 a round,
  `DuelGame.run_to_ground_bonus`; the first experience) and the ridge.

### Gary's 11 November play-through notes, and the opening rebuilt (12 November)

Gary's thirteen notes from playing the Mac build on 11 November, and the
change to the game's opening he sent the next morning
(`docs/handover/2026-11-12-opening.md`). Every look plays as Player A in the game.

**The opening rebuilt (12 November)**

His list, and what each line became:

- *Keep* the snow walk first; the baby, the hunter, "Not this one", Bram's
  face unseen, the white, "Twenty years later, the debt came due."; the quiet
  day in Ashford; Bram's memories teaching one thing at a time, gated steps,
  a first duel that can't be lost; Tilly's Lantern Moth. All as they were.
- **"Bram's duel becomes played, not watched ... three gated moves as Bram
  (call a Totem, attack, play the Last Page), with no costs or numbers, and
  it can't be lost."** `WhiteSky._duel` plays a duel written out move by move
  (`WhiteSkyDuel.PLAY_TURNS`, `play_board`) on the real rules, cut into
  already joined and going badly (`DuelGame.puzzle.damage`: Totems already
  hurt). The hunter strikes first and the Warg breaks the Scrivener. Then
  the player's three moves, each waited for (`WhiteSky._ask_move`, called by
  Bram's side of the duel, `WhiteSkyDuel.Staged.ask`):
  1. *call*: his hand comes up as paintings alone (`WhiteSky.PlayCard`: no
     names, costs or numbers), the Unspent Hour lifted and glowing.
     "(Tap the glowing card to call a Totem.)"
  2. *attack*: a ring of light on the Blazehound (`MoveRing`).
     "(Tap the hound to strike it.)" The Unspent Hour is Swift, so it
     strikes the turn it's called, and breaks the hound.
  3. *last_page*: after the pack's answer has brought the Loomwarden down,
     the card he has just drawn glows. "(Tap the glowing card: the Last
     Page.)" Orlanthe's blow lands and the screen burns white.
  Each prompt is in brackets and worded for the device (`HOW_MOVE`: tap,
  click or E, A on a controller). A tap anywhere else does nothing
  (`_on_move`, `MOVE_NEAR`). Nothing in it is chance and nothing can lose
  it: both sides are `Staged` players that only make the moves written; no
  Wards are set and nobody holds an answer. Between the moves it's filmed
  by its beats as the watched duel was (`_on_beat`), the bars off while the
  player chooses, the choosing done from high behind Bram (`PLAY_SHOT`).
  `DuelScreen` takes its players from the spec now (`spec.controllers`).
  `tests/white_sky_play_probe.gd` plays the written duel headless and
  checks every step; `tests/white_sky_test.tscn` plays the whole memory,
  taps off the mark first to see nothing happens, and reports when the
  first card is played (60 s in with the test's quick hands; about a minute
  and a half to two minutes for a person).
- **"The opening movie moves to before the title screen on first launch,
  skippable. New Game then goes straight to the snow."** `Main._ready` plays
  it once after the notice, the first time the game is opened on a device
  (`Game.settings.seen_opening`), then the title; `_on_new_game` no longer
  plays it. Watch the Opening on the title is unchanged. `-- --no-opening`
  leaves it out.
- **"The mirror's crater answer should add something new, since the player
  has just lived it."** `AshfordP1.REFLECTION`, the second question: it told
  the crater again. Now: "Twenty years. Bram tells it in one breath: he
  found you in the snow, out in the Shardlands, and carried you home inside
  his coat." / "Ask what he was doing out there, or what else was there
  that night, and he finds a barrel that needs moving." / (v6's last
  sentence, unchanged) "He bought this inn with unexplained gold, gave you a
  bed, and taught you to keep your head down." Gary said yes to the words on
  12 November ("1 yes").
- **"Remove the 68-second watched duel from the opening"**: gone
  (`WhiteSky._duel_film` and the two-computer duel; `WhiteSkyDuel.board()`
  and its seed stay for `tests/white_sky_probe.gd`).
- **"Remove the never-skip rule after the first play-through"**: the Skip
  button is back once the memory has been seen (`WhiteSky._skip_btn`,
  `seen()`); the first time nothing can be skipped, as he asked on 8
  November.
- **"Your film's shots as the payoff after each of the player's three
  moves, with the full film shown later once they know the rules."** Three
  short films, `white_sky_move_1`, `_2`, `_3` (`StoryFilm.FILMS`), play over
  the duel as it plays each move out (`WhiteSky._move_film`) once Gary has
  made them; until then the game's own shots are the payoff. His whole
  film, `white_sky_duel`, plays on the Thornwood road once it exists: after
  Bram's lesson, the player under the blanket and Bram awake by the door
  (`ThornwoodShelter.after_lesson`). The brief is in
  `docs/script/films_plan.md`, section 8.
- **"A test: watch five people who have never seen the game play the first
  ten minutes without help."** Gary's to run; the one-page sheet for it is
  `docs/playtest_first_ten_minutes.md`.

**The thirteen notes (11 November)**

- **1, 4. "Bram's left hand is deformed"; the hunter's right hand**: both
  models' fingers were being bent by clips made for another hand
  (auto-rigged fingers, poor weights). Their fingers stay as modelled now
  (`Figure3D.FROZEN` `"*fingers"` for `bram_coat` and `shard_hunter`,
  `finger_rests`, `keep_fingers`).
- **2. "Whole game running slow, keeps freezing, especially when Bram goes
  to pick up baby"**: the duel was being built behind the picture as the
  pick-up prompt came up. It's built under the opening's black now
  (`WhiteSky.prep_early`, `_open`), and not drawn again until the cut. On
  computers a frame-rate guard draws the 3D a little smaller only while the
  machine can't keep up (`Gfx.Guard`; Options: "Keep the frame rate
  smooth"). Not measurable here: it needs his Mac.
- **3. "Have Bram pick up baby quicker"**: the kneel, reach, lift and rise
  are about 40% shorter (`KNEEL_SECS` 0.8, `REACH_SECS` 0.45, `LIFT_SECS`
  0.8, `RISE_SECS` 0.95); prompt to child in his arms 4.5 s.
- **5. "It makes no sense just watching them fight"**: the played duel,
  above.
- **6, 7, 11, 12. Arms and hands twisting** (the porridge, Bram's box,
  Corin's button, Bram at the marks): a hand asked to face somewhere was
  turned at the wrist alone, however far. `Figure3D._natural_wrist`: the
  forearm takes most of a roll (`FORE_SHARE` 0.7, up to 125 degrees), the
  wrist rolls no more than 50 and bends no more than 72; past that the hand
  stops short instead of wringing. On top of that, each scene's own cause:
  - *Porridge*: the palm was turned out over the bowl, so the forearm
    rolled half a turn every mouthful. The palm stays down-and-in and
    squares up only near the lips (`AshfordP1.SPOON_PALM_BOWL`). Forearm
    roll through the eating: 2 to 50 degrees (`tests/eat_probe`).
  - *The box*: over the lid the fingers pointed straight ahead on a forearm
    coming in across the body, and the elbow stayed up while the hand
    followed the lid up. The fingers lie the way the forearm comes
    (`Ashford.LID_FINGERS`) and the elbow drops as the lid lifts
    (`LID_ELBOW`); no wrist is asked past its range (`Figure3D.wrist_over`,
    printed by `notes_1106_shot deck`).
  - *Corin's button*: the natural wrist; and the button goes to his pocket
    in his hand instead of hanging in the air (`AshfordDay.BUTTON_POCKET`).
    His head eases between speakers and lingers on the last one
    (`Figure3D.LOOK_SMOOTH`, `LOOK_LINGER`).
  - *Bram at the marks*: his palm was laid flat on the timber from a
    shoulder a forearm away, the hand bent back like a hand held up to stop
    someone. His fingers go to each mark now, wrist straight, the arm worked
    out each frame from his shoulder (`AshfordNight._aim_hand`,
    `_marks_glide`; `Figure3D.elbow_to`, `palm_to`), starting from and going
    back to where his hand hangs; the marks he presses are the easy ones
    (`_marks_for`), and he kneels 6 cm further from the cask.
    `after_midnight_shot cellar`: ok (no hand in the timber or the cask).
- **8. "After first battle with Corin we have 2 different music playing at
  same time"**: the 12-second victory stinger played on over the village
  reel. `Music` fades a stinger that isn't ducking the music out when the
  music changes (`_solo_out`), and every fade is its own tween now
  (`_fade`, `_dip`). `tests/music_overlap_test`.
- **9. "I like it turning during battle but don't like it keeps getting
  pulled back all the time"**: while the player chooses, the moving camera
  swings gently on their side of the board instead of going home
  (`DuelField3D.roam_near`, `NEAR_ARC`), slower still while a slot or an
  answer is being picked (`roam_still`); only a lesson holds it home.
- **10. "Hard to know how much health is left or how much damage is being
  done"**: every blow shows a strip under the Totem for 1.7 s
  (`DuelViews.HitStrip`): what the shield took and what's left of it, the
  health bar draining from before to after with the numbers, "BLOCKED" when
  a shield stops a whole blow. The plaques' health bars are deeper, with the
  shield as a pale band and "SHIELD n".
- **13. "After, his body goes through the stairs"** (the Reckoning's cellar
  scenes): Bram stood inside the flight and the player ran into its second
  tread. Everyone stands and walks clear of it (`AshfordNight.RK_*`,
  `STAIRS_FOOT`, `STAIRS_CAM`); the cellar probe checks every spot and the
  ways between against the treads and the walls. Placed by measurement,
  not yet seen rendered: worth a look on the Mac.

**What was checked** (12 November): `load_all` 0 failed;
`white_sky_play_probe` ok; `white_sky_test` headless PASS (the three moves
asked in order, a stray tap ignored, the Last Page called, the memory
finished), and with Skip pressed at four moments in the duel;
`white_sky_world -- <dir> play` (the memory inside the Ashford world, as New
Game plays it): the duel played, the attic reached, rendered and headless;
`first_launch_test` ok both ways (first launch: notice, movie, title, New
Game, the snow; later: notice, title, New Game, the snow); the played duel
rendered and looked at; `eat_probe` ok; `notes_1106_shot deck` ok as Player
A, `wall` ok; `after_midnight_shot cellar` ok (the Reckoning's spots 25 cm
clear of the steps and walls); `music_overlap_test` ok; `hit_strip_shot` ok;
`duel_camera_shot choose attack` no problems; `duel_sim -- 100` 0 invariant
errors; `puzzles_test` PASS. Not checked here: the frame-rate guard and the
slowness on a real Mac. Left as found: as Player D the right hand's skin goes
2.4 cm into the box's underside for half a second as he takes it (the same
with the wrist as it was: not from this change).

### Sounds for the taps, the cards and the creatures; the grass and the wood in patches (12 November, later)

Gary, 12 November, after the opening's build: "adding the sound effect to the
game and cards and creatures is good implement that" (his yes to "a sound on
each tap: the card going down, the hound's cry, a page turning"), "m1 chip"
(his Mac), and, to "I'll lighten it where it's too much": "dont lighten it as
i want the game to be able to run on other peoples computers and they likely
have that". So nothing in the look was lowered and no setting was changed for
his Mac: what follows makes the same picture cheaper to draw, for everyone.
Details: `docs/handover/2026-11-12-sounds.md`.

**Sounds**

- **The three taps in the snow** (`WhiteSky._move_sound`, `_snd`): Bram's
  hand comes up with `card_draw`; the tap on the glowing card is `card_lift`
  (the duel's own `card_fly`, `call_totem` and the Unspent Hour's voice
  follow); the mark closing on the hound is a high `ward_set`, and the tap on
  it is the hound's snarl (its voice, below), with its whine as the blow
  lands and it breaks; the tap on the Last Page is `page_turn`.
- **Creatures have voices** (`Sfx.cry`, `cry_of`; `DuelScreen._cry`): each
  Totem is heard as it's called (`CRY_AFTER_CALL` after its card lands), as it
  attacks, under a blow of `CRY_HURT_DAMAGE` or more that it lives through,
  as it falls, and as it Ascends (the new form's voice). A voice is looked
  for in turn: `assets/sfx/cry_<id>_<when>` (`call`, `attack`, `hurt`, `ko`),
  `cry_<id>`, `cry_<kind>_<when>`, `cry_<kind>`. The kinds are the families'
  (`Sfx.VOICE_OF_FAMILY`: Hounds bark, Foxes yip, Cats snarl, the Winged
  chime, the Scaled hiss, Shells clack, the Stoneborn grind) and those of
  `Sfx.VOICE_OF` for a creature with no family or not like its family (the
  owls hoot, the heron squawks, the drakes roar, the rats squeak, the tree
  folk creak, the ram and the cub grunt, Kaethis's Totems sing like glass).
  **The fourteen `cry_<kind>.wav` files are stand-ins built from nothing by
  `tools/make_cries.py`** (tones through mouth-shaped filters, shaped noise:
  the same sort of sound as the game's other effects), levelled against each
  other and checked by their spectrograms, not by ear: nobody has heard them
  yet. One cry serves every creature of its kind, so it's pitched by the
  creature's Health (`Sfx.SIZE_PITCH`: a Cinderpup high, a Warg low), by a
  per-creature nudge (`VOICE_OF`), and by the moment (`CRY_WHEN`: an attack a
  little higher and quieter, a fall lower). A Hound that's hurt or falls
  whines (`CRY_ALIAS`: Gary's `hound_whine`). Each of the six Summons has a
  cry of its own (below).
  Gary's own recording replaces a stand-in by being saved under the same
  name (`.ogg`, `.wav` or `.mp3`); `cry_<creature id>` gives one creature
  its own voice. The list of what to make is in the Still to Make doc
  ("Creature voices" tab). A duel loads its decks' voices as it starts
  (`Sfx.warm_cries`).
- **A voice for each Summon** (Gary, later the same day: "Do the footsteps
  and and the voice for each summon in the todo list"): `cry_dawnmane` (a
  great lion's roar, the dawn ringing in it), `cry_grondmaw` (a groan from
  under the ground, rock grinding and splitting), `cry_pyraxis` (a
  firebird's scream over a dragon's roar), `cry_somnara` (three voices on
  one soft dark chord, moth wings), `cry_thalassa` (a long rising call, a
  second answering above it, a wave drawing back), `cry_orlanthe` (one deep
  bell, glass singing after it, pages turning). Two to three seconds each,
  made by `tools/make_cries.py` as the kinds' are, and as unheard. Played
  `CRY_AFTER_LANDING` after the landing's boom (`DuelScreen.fx_summon`), in
  Bram's filmed duel too, and in the Codex at a tap on a Summon's picture.
- **Footsteps** (`Figure3D._footfalls`, `Sfx.step`, `World.surface_at`): a
  figure walking, running or sneaking is heard each time a foot comes down.
  The two foot bones are watched (a foot `STEP_LIFT` above where it rests is
  up; back within `STEP_DOWN` of it is a footfall), so the sound lands with
  the picture whatever the model, clip or pace: the player's run is 3.8
  steps a second, a walk 1.8, Bram's trudge in his coat 1.0. The ground is
  the figure's `step_on` when set (Bram in the memory: "snow"; "none" for
  never), else what its world says is there (`World.surface_at`, asked by
  walking up from the figure to the nearest node that has one): the area's
  own answer first (`Ashford.surface_at`: the cellar "stone", the smugglers'
  tunnel "dirt", the mill "wood"; `Thornwood.surface_at`: Bram's shelter
  "dirt"), then boards for anything below `INDOORS_BELOW` (the rooms all sit
  40 m under the ground), dirt on a village's or a wood's paths
  (`AshfordVillage.path_at` over `PATH_FROM`) and grass off them, stone
  anywhere else (Solhaven). A world behind the title screen, or waiting
  under it, is silent. Five grounds, four takes each
  (`assets/sfx/step_<ground>.wav`, `_2`, `_3`, `_4`, made by
  `tools/make_steps.py`: shaped noise, a thump, a knock; unheard, as the
  voices are), a take picked at random, its pitch and loudness moved a
  little every time; played on a player of their own (`Sfx.steps()`, which
  doesn't count as a press's sound, so a button still clicks while you run)
  at `STEP_DB`, a run a touch harder, quieter the further the walker is from
  the camera (full within `STEP_NEAR`, the world camera's own distance from
  the player; unheard past `STEP_FAR_DB`), and anyone but the player (or a
  figure with its own `step_on`) `STEP_OTHERS_DB` under that. The stand-ins
  are levelled by what an ear and a phone's speaker get of them (above
  `HEARD_FROM` 180 Hz: the voices were levelled again the same way).
  `tests/steps_test.tscn` checks the rates, left then right, stillness,
  "none", distance, the grounds, and the player run across the green by a
  tap; `white_sky_test` wants `step_snow` on the walk (29 on the walk to the
  crater) and `cry_orlanthe` at the landing.
- **A quiet bed of sound for each place** (Gary, the same afternoon: "Yes
  re sound effects", to "a quiet background sound for each place under its
  music: the taproom's fire, birds and voices on the green, the Thornwood at
  night" and "a splash at the river's edge, and a different sound for the
  inn's stairs"). `Ambience` (`scripts/ui/ambience.gd`, made by
  `Game._ready`) asks whichever world is showing, every `CHECK` seconds,
  what its place sounds like (`World.ambience()`, which asks the area's
  static `ambience_at(w, at)`, `at` the spot of ground the camera is looking
  at: `World.cam_ground`), and eases to that bed over `FADE`, or to silence.
  Nothing starts or stops one: a duel (the world hidden behind it), the
  title screen, a world still waiting, a black screen (`CineOverlay.is_black`),
  a film (`StoryFilm` counts itself into `Ambience.hush`) and Bram's memory
  (`WhiteSky._hush`: its storm is its own) are all quiet by that. Eleven
  loops of 24 s (`assets/sfx/amb_<name>.ogg`, about 240 KB each, made by
  `tools/make_ambience.py` from layers: a breeze, leaves, birds, crickets,
  an owl, far voices, a hearth, a house on fire, a river, a drip; each made
  to join its own start; as unheard as the rest), played at `Ambience.DB`
  under the sound-effects volume:
  `amb_fire` both taprooms; `amb_cellar` the cellar and the smugglers'
  tunnel; `amb_river` the mill and the Thornwood within `RIVER_HEARD` of its
  river; on Ashford's green `amb_burning` while a house burns, else by the
  hour: `amb_green_day` (`daylight` over 0.6), `amb_dusk`, `amb_festival`
  (the festival night), `amb_night` (the dark night after), silence on the
  dawn after the fires (the attic has had `amb_attic` since the weather,
  below); in the Thornwood by
  `ThornwoodSet.scene_kind`: `amb_camp`, `amb_wood_day` (morning, the
  ridge), `amb_night` (the road), silence in Bram's shelter; `amb_city` all
  through Solhaven. A new place: give its area an `ambience_at`.
  `tests/ambience_test.tscn` checks every one, the easing between two, and
  each kind of silence; `white_sky_world` that no bed plays under the
  memory.
- **A slider for the places, Summon videos' choices, and weather** (Gary,
  16:34: "Yes re the slider. Also a button in the game setting for summons
  play full video or 3 second intro and yes re weather"):
  - Options, **"Background sounds"** (`Game.settings.ambience`,
    `Ambience.SETTING`): how loud the places' beds are, apart from Sound
    effects (which they followed before); all the way down is off.
  - Options and the duel's Menu, **"Summon videos"**: *Full video* (the new
    `always`: a Summon's whole clip every time), *3-second intro* (`short`,
    was "Short"), *Full once* (`full`, was "Full", and still what a save has
    until one is chosen: the whole clip the first time each is summoned, the
    intro after), *Off*; what the choice does in a line under the buttons
    (`SummonVideo.MODE_WORDS`). `tests/summon_video_test.tscn` has the new
    choice; `tests/options_shot.tscn` pictures the page.
  - **Weather** (`scripts/world/weather.gd`, a `Weather` node on the
    village, `Weather.of(w)`): a light shower over Ashford's green for
    about a minute (`LAST`), first after `FIRST` (150 to 300 s) of a day
    spent free on the green and again after `GAP` (6 to 11 minutes): thin
    streaks falling where the camera looks (`DROPS` by `Gfx.level()`, a
    particle box that follows `World.cam_ground`), and the green's bed
    changing to `amb_rain` (`Ashford.ambience_at`, once `raining()`). Only
    by full day, out of doors, with the player free: a staged scene
    (`cine`), a film, the sun going down, a house on fire or going indoors
    sees it off in `EASE_OUT` seconds, and its clock only runs while one
    could fall. The sky, light and ground are untouched (a sun shower), so
    nothing changes when it's dry, and a film that follows it shows no
    seam beyond the rain having stopped. The attic has `amb_attic`, the
    wind under its eaves (it was silent), made quieter than the other beds
    (`QUIETER` in `tools/make_ambience.py`). `tests/ambience_test.tscn`
    runs a day's weather a second at a time (the first shower, its length,
    the gap) and everything that sees one off; `tests/rain_shot.tscn`
    pictures the green dry and in the rain (looked at: thin pale streaks,
    light, the green otherwise as it was).
- **Two more grounds for the footsteps**: `step_stairs` (a tread rings
  higher than the floor and creaks: anywhere indoors more than
  `World.STAIR_RISE` above a room's floor, so the cellar's stairs and the
  attic's) and `step_water` (a splash: where the Thornwood's ground is under
  its river, `Thornwood.surface_at`).
- **The Codex** (`Codex.Detail`): a card opened turns over (`card_flip`); a
  creature of yours is heard as its card opens and again at a tap on its
  picture ("(Tap its picture to hear its voice.)" under Your Collection);
  Add to deck is `card_fly`, Take out `card_lift`; forging, re-absorbing and
  the pool have `essence_gain`, or `gift` when a card is made.
- **Every button clicks** (`Sfx.watch_buttons`, from `Game._ready`): a
  button that plays nothing of its own on a press plays `ui_tap` through one
  shared player (`Sfx.shared()`, which also plays the Codex's sounds and is
  heard while the game is paused). The click comes after the press's own
  handlers and stays silent if anything was played in that moment, so the
  duel's buttons keep their own sounds; a button with the meta `quiet` never
  clicks.
- **No more test beep on four elements**: Astral, Radiant, Spirit and Umbral
  attacks had no `cast_` file and played a placeholder tone; they borrow
  `cast_mystic` (Umbral `cast_psychic`) until they have their own
  (`Sfx.FALLBACK`).
- `tests/sfx_test.tscn` checks all of it (every Totem a voice for every
  moment and the file loads, no stand-in on a Summon, Hounds whine, small
  cries higher than big, the button click and its two exceptions, the Codex);
  `white_sky_test` now fails if any of the three taps' sounds, or the
  Totems' voices, isn't played.

**The M1, without lightening** (measured with `tests/mem_probe.tscn -- full`
and the new `tests/tri_probe.tscn`, both building the place as a Mac does,
`Gfx.force_level`):

- What the village held and drew: 858 MB of textures (1,075 MB with a duel
  over it), and **4.3 million triangles standing, of which 2.0 million were
  grass**: one piece of 42,000 clumps, each 48 triangles written as 144
  separate points, so the graphics card placed, bent in the wind and shaded
  six million points a pass, twice a frame (depth, then colour), wherever
  the camera looked. A piece like that is drawn whole or not at all.
- **The grass in patches** (`AshfordVillage.grass_field`, `in_cells`,
  `GRASS_CELL` 12 m): the same clumps in the same places with the same
  colours, sorted into squares; a square out of sight isn't sent. And a
  clump's shared corners are kept once (`blade_clump` ends `st.index()`: 64
  points, not 144). From the green a frame went from 4.9 to 3.1 million
  triangles. Two stills of the same frame, before and after, differ only
  where the people breathe: the grass is the same to the pixel.
- **The Thornwood's trees in squares** (`multimesh_cells`, `TREE_CELL` 28 m)
  and its grass in patches: the wood was eight pieces a quarter of a mile
  long, every tree drawn every frame and again for each of the sun's shadow
  maps. From over the camp a frame went from 9.0 to 2.7 million triangles;
  the two stills are identical (largest difference 0).
- Solhaven's gate is light (0.3 million triangles) and so is a duel (0.2
  million, 580 draw calls): what a duel costs a Mac is its pixels (the bounce
  light, fog and soft shadows at a Retina screen's size), which is what the
  frame-rate guard of 11 November watches (`Gfx.Guard`: unchanged; Options,
  "Keep the frame rate smooth", off holds the full picture whatever).
- **Not done, offered to Gary:** the models' pictures are held unpacked in
  the graphics memory (a 4096 square is 85 MB). Stored the way graphics
  cards read them they'd take a quarter of that, load without a decode and
  look the same, for about 470 MB more download per app and 11 minutes more
  build. It changes how every texture is stored, so it waits for his yes.
- Still not measured: the frame rate on a real M1 (nothing here has a
  graphics card). Options, "Show frame rate" gives the number, and "3D at
  N%" when the guard has stepped in.

**What was checked:** `load_all` 0 failed; `sfx_test` ok; `white_sky_play_probe`
ok; `white_sky_test` headless PASS, whole and the duel alone (the sounds
heard listed); `first_launch_test` ok; `duel_sim -- 100` 0 invariant errors;
`puzzles_test` PASS; `mem_probe -- full duel` a duel played over the village
with every voice hooked in, no errors; `tri_probe` in Ashford, the Thornwood
and Solhaven. Later the same day, with the footsteps and the Summons'
voices: `steps_test` ok; `sfx_test` ok; `white_sky_test` headless PASS (29
footsteps on the walk, Orlanthe's voice at its landing); `load_all`,
`first_launch_test`, `white_sky_play_probe`, `duel_sim -- 100` as before.
With the beds: `ambience_test` ok; `white_sky_world -- <dir> play` headless
(no bed under the memory, none left hushed after it); the rest again.
Not checked: how any of the sounds sound.

### Gary's 8 November evening notes (the memory, the morning, the green, the evening)

Gary's notes from playing the Mac build on the evening of 8 November, and
what each became (`docs/handover/2026-11-08-eve.md`). The moving duel
camera he asked for the same evening is in the Duel Lab ("The moving duel
camera"); his Weft Serpent file that evening was the same file as the
morning's (the colour picture identical pixel for pixel), so nothing
changed there. Morrowen's opening line is to be recorded again (Still to
Make, before the attic). Every look plays as Player A in the game.

**The Night of the White Sky**

- **"Make it so you can't skip Bram's bit at the beginning"**: a tap skipped
  the filmed duel, and once the memory had been seen
  (`Game.settings.seen_white_sky`) a Skip button at the top right skipped
  the lot. Both are gone (`WhiteSky._ready`, `play`, `_duel`, `_close`):
  nothing in the memory can be skipped now, first time or any time after;
  taps still move the lines on as everywhere else. `WhiteSky.skip()` stays
  for the tests (`white_sky_test ... skip`), with nothing in the game
  calling it.

- **"Think there needs to be more of a pause or action before hooded figure
  shows up"**: both times it appears.
  - *On the walk* (`_glimpse`): it used to fade in the moment he came
    within `GLIMPSE_AT` of the crater, with nothing to say anything was
    there. Now the storm drops first: the wind falls away (`_wind_to`,
    `WIND_HUSH_DB`) and the music dips under it (`Music.duck`), the Sigils
    stop coming down and the snow thins and slows (`_storm_to`, the snow's
    `amount_ratio` and `speed_scale`) over `GLIMPSE_HUSH` 1.6 s; the
    camera's eyes are drawn off to the side of the way ahead
    (`_glimpse_look`, `GLIMPSE_EYES` 0.5 of the way to it, the roaming
    camera still following him) and his head turns with them
    (`Figure3D.eyes_on`); a gust lifts the snow there and it takes form in
    it (`GLIMPSE_FORM` 1.8 s), watching him (`GLIMPSE_HOLD` 3 s); then the
    wind comes back with a gust and it's gone, his eyes and the camera's
    back to the way ahead, the Sigils falling again. The walk stays his the
    whole time (his 5 November note: nothing takes it from him).
  - *On the rim* (`_the_hunter`): a heartbeat after the child was tucked in
    his coat it was simply on the rim. Now the night goes still first: his
    eyes on the child in his coat, the wind falls away to almost nothing,
    the Sigils stop and the snow all but hangs in the air, the crater's
    light sinks (`_crater_k` to 0.32) and the music dips; cut wide and low
    behind him, small in the bottom of the bowl under the empty rim, the
    camera creeping in (`RIM_HUSH` 3.4 s). Then a sound up there in the
    dark, a hound's whine, low and far off (`_far_whine`: Gary's
    `hound_whine` pitched down, the hunter's pack); his head comes up to
    the rim (`RIM_SOUND`). Snow lifts off the lip in a gust and the shape of
    something stands in it, half there (`RIM_FORM_HALF`, faded to 0.4),
    then whole (`RIM_FORM`), and it walks the last `RIM_BACK` 1.6 m to the
    edge on its own walk clip (`Hunter.walk_to`, `RIM_STEP` 1.2 s, the
    clip's pace from `Figure3D.OWN_GAIT` shard_hunter, so its feet don't
    slide) and stops, looking down at him. As it forms a cold light finds
    it (`RIM_LIGHT`: dark on the dark sky it was all but lost), and it's
    seen on a long lens over his shoulder (`RIM_LENS` 26 degrees, the
    camera more nearly behind him than before so no edge of his cheek shows
    past his hair as his head comes up). Coming up over the lip from behind
    it, its feet are hidden by the lip until it walks to the edge. "Not this
    one." The cards rise and the white comes as before. From the tuck to the
    white is about 11 seconds now (was about 5). Every shot is from behind
    him.

- **"Can we make the battle more movie like or give me images and prompt
  and I'll make it a movie"**: both.
  - *More like a film* (`WhiteSky._duel`, `_on_beat`): the camera used to
    cycle through five fixed wide shots every 6.5 s while the duel played
    in the middle distance. Now every beat the duel's presenter is told of
    chooses the shot (`DuelGame.beat`, a new signal sent with each `fx_`
    call, connected deferred so the film's shot comes after the duel
    screen's own camera calls and stands). A Totem called rises in a low
    hero shot (`_beat_call`); an attack is seen from behind the attacker
    across at what it's going for (`_beat_attack`), and a big blow cuts to
    where it lands with the camera shaken by it (`_beat_hit`, `BIG_BLOW`
    60; a small one just shakes the shot that's up); a Totem broken is held
    close (`_beat_ko`); a blow on Bram is seen over his shoulder as he takes
    it, and he flinches (`_beat_life`, his `hit_react`); the hunter's Doom
    on the Scrivener is held close (`_beat_close`); each turn opens on
    whoever's turn it is, over his shoulder or the hunter across the Circle
    on a long lens, creeping in (`_beat_turn`, `_creep`); a Rite or a Ward
    shows who cast it (`_beat_rite`); when nothing's happened for
    `IDLE_WIDE` 3.8 s, one of the wide shots drifts into place (`WIDES`).
    Black bars of a widescreen film over it all (`_film_bars`:
    `FILM_ASPECT` 2.35 where the screen's narrower, each bar 4 to 10% of
    the height, a little deeper for the Last Page). No ordinary cut sooner
    than `MIN_HOLD` 1.3 s after the last. Called down, the Last Page has the
    picture to itself: tight over his shoulder looking up, then out to
    `CLIMAX` as it comes down (`_climax_shot`; since 12 November behind him
    to his right, high and back enough for the whole of it), the camera shaken as its
    blow lands, and held a second on it (`CLIMAX_HOLD` 1.0, was 0.5) before
    the white comes over 1.5 s (was 1.2). The Totems' cards lying on the
    field under them, with their names and numbers, are kept out of the film
    (`_hide_plates`; the rune rings still mark the Circle's places). The
    hunter's hounds lost the white rectangles that stood off them: the smoke
    (`DuelField3D.spectral`) was laid over each model's whole mesh, and the
    Blazehound's flames and the foxes' glows are flat cards with a picture
    cut out of them, so each card showed as a white sheet; a creature of
    smoke has no flames, so those parts are taken out of a spectral model's
    mesh (`DuelField3D._drop_see_through`; only the hunter's side in the
    White Sky is ever spectral). The duel plays a little slower so each beat has its moment
    (`WhiteSkyDuel.FILM_SPEED` 2.2, was 3.0; the same duel, beat for beat:
    the seed decides it, not the speed).
    *Bram's face is never seen*: every shot is checked first
    (`_face_seen`: his head in the picture, with room to spare for the
    duel's widened picture and its drift, with the camera anywhere but
    behind his shoulders; side-on counts), and a shot that fails gives way
    to the next of its kind. That check threw out two of the old five wide
    shots (from out at the sides of the Circle, his face three-quarters on
    in the corner of the picture), so the wides are `WIDES` now. His own
    Totems' hero shots come from low behind them (from in front the picture
    looked back into his face); the hunter's attacks are seen from behind
    what they're going for (from behind the hounds it looked into his face,
    and stood the camera inside the hunter, `_in_the_way`).
    *The duel's own camera in a film*: the duel screen still sends the
    field's camera home, and leans it at what's happening, in a film (only
    its cinematic shots, the bars and the slow motion are off,
    `DuelScreen._filmed`), so each film shot is made the field's home as
    it's taken (`_home_on`: `DuelField3D.set_home` with the camera left
    where it is), and the screen's home and leans keep to it. The film
    relies on `DuelField3D.cam_shot`, `set_home`, `cam_home`, `cam_shake`,
    `shot_hero`, `shot_behind`, `shot_close`, `shot_ko`, `body_world`,
    `foot_world`, `life_world`, `ahead_of` and `cam_moves`, and on no other
    camera motion being added to a field in film mode (the new moving duel
    camera must stay off when `spec.film`).
  - *Gary's own film of it* (`StoryFilm.FILMS["white_sky_duel"]`,
    `WhiteSky._duel_film`): sixteen shots, `wsd_01` to `wsd_16`, 61 s, each
    a beat of the duel in its order (the shot list below), no lines over
    it, Bram's face never in it, no Player A. When his film is there
    (`white_sky_duel_4k.mp4` through the device's own player, from the
    films release as the others; else `assets/movies/white_sky_duel.ogv`;
    else a clip or painting for every shot, `tools/movie_clips.py --film
    white_sky_duel`) it plays in the duel's place: the hunter's white flash
    as before, then his film, then the white again and the close to black
    and Morrowen's last line, as after the 3D duel. So his film should open
    out of white (the hunter's cards) and end on white (the book opening).
    If it can't play after all (`"played": false`), the 3D duel plays.
    Until it comes, nothing changes: the 3D duel, filmed as above.

`tests/white_sky_film_peek.tscn -- <dir> duel|rim|glimpse|refs [every=s]
[nostills]`: `duel` stills a moment into every film shot, named for the beat
that chose it, and counts the frames with Bram's head in the real camera's
picture from in front (fails nothing; prints it); `rim` and `glimpse` a still
every `every` s through the build-ups; `refs` reference pictures (Bram from
behind, the hunter full length, the bundle, the ice field).

**What was checked** (8 November): `load_all` 0 failed; `white_sky_test`
headless PASS (filmed, Orlanthe called, no script errors; the whole memory
121 s of game time, was about 95: the two build-ups and the slower duel);
`white_sky_film_peek duel` headless and rendered: the same duel beat for
beat as at the old speed (its log compared line by line), 68.5 s, 37 cuts
(one every 1.9 s on average; 58 before the cutting was calmed), **Bram's
head in the real camera's picture from in front of his shoulders: 0
frames**; `rim` and `glimpse` stills looked at (the hush, the eyes drawn,
the figure in the gust; the wide in the bowl, the whine, the head coming
up, the figure rising over the lip and walking to the edge on the long
lens); `white_sky_world -- --story-films` (the memory in the world with the
film path forced on, its animatic cards): `story film: white_sky_duel
(shots)`, the white back after it and the close to Morrowen's line.

**Left / worth knowing**
- Orlanthe has no model in the game yet (Gary's Round 9 list), so the Last
  Page shows as its column of light; the climax shot is framed for the
  figure coming down and will show it once it's in. The Glyph Warden is
  still the drawn stand-in (a purple block).
- The film relies on the new moving duel camera staying off in film mode
  (`spec.film` / `DuelScreen._filmed()`), and on `DuelField3D.set_home`,
  `cam_shot`, `cam_home` and `cam_moves` working as they did.
- `tests/white_sky_world.gd`: `_shot` now returns at once when headless
  (it waited for ever on a frame that never comes).

**Gary's film of the duel: the shot list** (`StoryFilm.FILMS["white_sky_duel"]`,
63 s; the moment is when it happens in the game's own filmed duel, seconds
from the cut out of the white; the still
of each, rendered from the game by `tests/white_sky_film_peek.tscn -- <dir> duel`,
is under its shot in Gary's doc "Films for Player A: Your Step-by-Step",
Film 8 (https://claude.ai/artifact/4YMbd8HD1gBzrCDM7437ie), with every shot's
picture and movement prompts)

| Shot | Length | What's seen | Moment in the duel | Still |
|---|---|---|---|---|
| wsd_01 | 4.5 s | Out of the white: the Circle in the Shardlands, a ring of trampled snow among towering crystals of blue ice, the torn sky white overhead, snow driving across it. From high behind him: Bram, the child a bulge in his coat under his left arm, cards in his right hand; across the Circle the hunter, its hood empty; on his side the Scrivener and the Loomwarden, on its side the pack (a Blazehound, the Infernal Warg and a Veilfox) made of pale smoke and Sigil light. | 0 to 2 s | wsd_01.png |
| wsd_02 | 3.5 s | The hunter, close, on a long lens from Bram's side: one long grey hand turns over a card of white light (the Doom Sigil). | 2 to 3.5 s | wsd_02.png |
| wsd_03 | 4.0 s | The Scrivener (a tall faceless scribe in parchment robes, quill of starlight raised): a black sigil of doom closes round it like a noose of ink; it looks up from its writing. | 3.5 to 5.7 s | wsd_03.png (from behind it: the game never looks back towards Bram) |
| wsd_04 | 3.5 s | Bram from behind, his right hand up with a card: the Unspent Hour, a winged hourglass of glass and starlit sand, darts out of the light over his shoulder. | 7.3 s | wsd_04.png |
| wsd_05 | 4.0 s | The Unspent Hour turns its glass on the Infernal Warg and the Warg reels; but a trap springs in the snow under it and green poison mist clings to its glass. | 8 to 11.5 s | wsd_05.png |
| wsd_06 | 4.0 s | The Scrivener writes a line of silver script at the Blazehound; the Loomwarden (a many-armed weaver of grey thread in a loom of bone-white wood) pulls its silver threads taut through it: the hound bursts into smoke. | 12.3 to 14.1 s | wsd_06.png (the hound breaking) |
| wsd_07 | 2.5 s | Where it stood, a River Hound of white smoke comes up out of the snow. | 15.0 s | wsd_07.png |
| wsd_08 | 4.5 s | The pack turns on the Scrivener: the Veilfox's mirage, the Warg's charge of pale fire, the River Hound's bite; steam bursts off it, and it staggers, blinded. | 17.3 to 24.5 s | wsd_08.png |
| wsd_09 | 3.5 s | The hunter's hand lifts to call more of its kin; Bram's face-down Ward flips at his feet and lines of silver script close over the hunter's card. It comes to nothing. | 25 to 31.7 s | wsd_09.png (over his shoulder as it springs) |
| wsd_10 | 4.0 s | The Unspent Hour and the Loomwarden break the Infernal Warg: it bursts into smoke and white sparks. A Shieldhound rises in its place. | 33.3 to 36.2 s | wsd_10.png |
| wsd_11 | 4.0 s | The River Hound's bite takes the Scrivener: it comes apart into pages that blow away, and the blow carries on into Bram; over his shoulder he staggers, his arm going round the child. | 43.8 to 46.3 s | wsd_11.png (the game breaks its Totems into crystal) |
| wsd_12 | 3.0 s | The hounds drag the Unspent Hour down; its glass cracks and its sand pours out. | 47.5 to 49.2 s | wsd_12.png |
| wsd_13 | 4.5 s | The Weft Serpent rises out of the snow into the gap, a vast serpent woven of grey and silver thread, rearing over the pack; the Glyph Warden takes the other gap, runes lighting across it. | 51.5 and 53.5 s | wsd_13.png, wsd_13b.png (the Glyph Warden is still the drawn stand-in) |
| wsd_14 | 3.5 s | Wide, high over Bram's back: the hunter's poison mist rolls over his side of the Circle and his Totems sicken in it. The Circle nearly lost. | 60.3 to 63 s | wsd_14.png |
| wsd_15 | 6.0 s | The Last Page: the stars draw together into a closed book and Orlanthe comes down out of it, a hooded figure the size of a hill in robes of folded parchment, faceless, the book in one hand. Low behind Bram, up past the hunter at it. | 65.0 s | wsd_15.png (only its column of light: no Orlanthe model yet) |
| wsd_16 | 4.0 s | The clasp comes undone; the book opens and white light pours out over the Circle, the pack and the hunter, until there is nothing but white. (End on the white: the game takes it to black.) | 66 to 68.5 s | wsd_16.png |

References (`white_sky_film_peek refs`): Bram in his coat from behind, the
hunter full length and with its white cards raised, the child's bundle, the
crater, the Shardlands' ice under the torn sky; four of them are in the doc.

Things Gary's film must keep, for the brief: Bram's face never seen (always
from behind or beside-behind); no words or numbers on screen; open out of
white, end on white; nobody sees who won. The game's music for it is his own
`white_sky_duel` (the hush, then the climax) and `summon_orlanthe` for the
Last Page, if he wants them in the film.

Files: `scripts/story/white_sky.gd`, `scripts/story/white_sky_duel.gd`
(`FILM_SPEED`), `scripts/story/story_film.gd` (the film and its header),
`scripts/duel/duel_game.gd` (`signal beat`, sent from `_fx`),
`scripts/duel_ui/duel_field3d.gd` (`spectral`, `_drop_see_through`),
`tests/white_sky_film_peek.gd/.tscn` (new), `tests/white_sky_world.gd`.

**The morning**

- **"When eating porridge hand moves in an unnatural way"**: measured on the
  8 November eating (`tests/eat_probe`, which now prints the arm: how far the
  wrist bends off the line of the forearm, past the bend the hand is modelled
  with, how bent the elbow is, and how the hand's speed changes frame to
  frame, while the hand's on the spoon): reaching to the bowl the arm went
  out dead straight (elbow 0 to 1 degrees: the bowl was 22 cm in from the
  counter's edge and he stood 24 cm off it, 52 cm from his shoulder for an
  arm of 45); at the mouth the wrist was folded 134 to 141 degrees, the fist
  under his chin with the spoon standing near upright (`SPOON_UP` 118
  degrees) like a lolly stick; the palm was turned from facing down to
  facing in and up whatever the forearm did; the rise took 0.42 s; and the
  correction for the fist's shortfall was learnt only at the two ends, 60%
  a frame, so the hand lurched at the top of each rise as it caught up (its
  speed changing by up to 2.3 m/s from one frame to the next, 30 frames
  over half a metre a second).
  Now (`AshfordP1._eat`): the bowl's rim is a hand's width in from the
  counter's edge (`BOWL_IN`, its middle 15 cm in) and he stands up to the
  edge (`EAT_STAND`, 16 cm off it); he takes the spoon by its handle's end
  off the bowl's rim (`SPOON_PICK_LIFT`), the handle lying in the curl of
  his fingers (`SPOON_GRIP`: held 1.2 cm over the palm's middle it hung
  under his open hand and read as nothing held), and each mouthful goes as one
  does: the spoon dips into the oats and draws through them towards him
  (`SPOON_SCOOP`), lifts straight up off the bowl and comes up in an arc to
  the mouth (`_bezier`, `SPOON_ARC_UP`, `SPOON_ARC_IN`), carried near level
  and coming in at the lips from in front and to his right
  (`SPOON_DIR_BOWL` to `SPOON_DIR_MOUTH`: the fist out by the side of his
  chin), the elbow lifting out as it rises (`SPOON_ELBOW_BOWL`,
  `SPOON_ELBOW_MOUTH`), the lips take it (in a centimetre, the bowl end
  tipping up 16 degrees, back out: `SPOON_TAKE`), and down the way it came;
  2.7 s a mouthful (`SPOON_SECS`). The hand is always turned square to the
  forearm as drawn round the handle (the hammer grip a hand modelled as a
  loose fist has: a straight wrist, the spoon out past the thumb;
  `SpoonHold.fore`), and the shortfall is corrected every frame against what
  was asked the frame before, a third of it a frame, at most 10 cm, and not
  while the arm's at full stretch (`SPOON_FEEDBACK`, `SPOON_CORR_MOST`). At
  the end the spoon goes back on the bowl's rim where it was, instead of
  jumping there. The spoon's hold (`SpoonHold`) is put after the arm's reach
  and the hand's turn in the skeleton's list (before them it read the arm as
  the clip had it, the hand by his hip).
  After (`eat_probe`, Player A, 10 frames a second): the wrist bent at most
  16 degrees (was 141), the elbow 54 to 115 degrees, never straight (was
  locked at 0 reaching for the bowl), the spoon's bowl 2.6 to 2.7 cm from the
  lips at each of the three mouthfuls (it stops 2 cm in front of them by
  design, `SPOON_AT_MOUTH`), the hand's speed changing by at most 0.9 m/s
  from one frame to the next (was 2.3; 0 frames over the probe's 1.0, was
  30 over 0.5). Stills looked at: the handle through his fingers, the bowl
  down in the oats, the hand by the side of his mouth as it goes in.
  `tests/eat_probe.gd` now measures and fails on a wrist past 70 degrees, a
  locked elbow and a jerk, while the hand's on the spoon, and counts the
  lips' in and out as one mouthful.

**The green**

- **"I like Corin walking over while you put lantern down but then he
  disappears and walks over again"**: the walk itself was right; it was
  undone afterwards, and only on a New Game. There World plays the opening
  through `Ashford.intro()` and then calls `Ashford.resume()`, and resume
  staged the green for the time of day (`AshfordDay.stage`); by then the
  opening had set `ash_started`, so `_to_spot` put Corin straight back on
  his morning spot by the drum, 8.9 m away, the moment the opening ended,
  and his talk (`corin_calls`) walked him all the way over again (his
  first line 17.2 s into the green instead of 13.3). `pose()` there could
  also have sat Bram down onto his stool from wherever he was. The probes
  came in through a saved game, where resume runs before the opening and
  moves nobody, so they never saw it. Now the opening marks the world
  (`p1_opened`) and resume, straight after it, neither poses nor moves
  anyone (`AshfordDay.stage(w, place)`); a game loaded later is staged as
  before. `tests/notes_1106_shot.tscn -- <dir> walk newgame` comes in as a
  New Game does; `restage` puts the old behaviour back for the probe's
  own check. Before (restage): Corin jumped 8.87 m in a frame at the
  opening's end and walked away from the player and back, first line at
  17.2 s. After: 0 jumps, never hidden, one walk, at his mark at 9.9 s, the
  crate down at 10.8 s, his first line at 13.3 s, both ways in (New Game
  and from a save).
- **"Talking with Corin can't have 'enough, let's settle this with a
  duel' as the player knows he doesn't have any cards"**: the player's
  last pick in Corin's hub was "Enough talking. Let's settle the Lantern
  Duel.", straight before "I would, but I don't have a deck." Now the
  player only asks, "You were serious about the Lantern Duel?", and it's
  Corin who throws it down: "Last Lantern Night before I'm off to the
  city, and I'm not going out on a win over Hob and his cabbage-patch
  Sparks. You and me, in front of the whole green. Deck out, Sprout."
  (worded to stand on its own, since the hub ends by itself when the
  questions run out). Then "I would, but I don't have a deck." and Bram's
  "You do now." as before (`Ashford._corin_morning`; the Master Script v7
  doc, `docs/script/v7_prologue.md`, and the voice sheet, `vo_lines.csv`,
  where it's a new line for Corin to record).
- **"Corin's letter has moved from his pocket to his chest"**: since 25
  October the clerkship letter, full size (14 x 9.5 cm), stood inside the
  vest's neck, a big white sheet up by his collar (`COAT_LETTER` on
  Spine2). His vest has two patch pockets on its right side, painted in his
  picture; the upper one stands a little proud of the vest at its top edge.
  The letter is folded small now (`COAT_LETTER_SCALE` 0.45: 6.3 x 4.3 cm)
  and stands on end in that pocket (`COAT_LETTER_BONE` Spine1, nearer the
  pocket than Spine2, so it moves with it), its top two centimetres out of
  the pocket and leant 17 degrees out from him at the top, the rest down
  in the pocket (`COAT_LETTER`, `COAT_LETTER_ROT`). The question about it
  stays "What's that letter tucked into your coat?". After, through his
  idle, walk, talking, cheer, fight stance and the slump: only the
  letter's top shows (its top fifth in every frame, a little more in a
  tenth of the cheer's, the rest never), it stands at most 1.4 cm off his
  vest, and no arm or hand touches it (in the old place the top two
  fifths stood out over his collar, up to 5.3 cm off him, and his arm went
  0.4 cm into it in the fight stance).
  `tests/corin_letter_probe.tscn` (new) finds the two pockets in his
  picture by where they're painted, measures the letter against his skin
  each frame (rays from the letter out through his coat's triangles, and
  his arms' vertices against it), `fit` searches a placement, `stills=`
  takes close-ups; `tests/corin_props_shot.tscn`'s chest still now looks
  at the pocket.

Checked: `load_all` 0 failed; `notes_1106_shot walk newgame` and `walk`
(from a save) ok, 0 jumps, never hidden, first line at 13.3 s both ways;
`walk newgame restage` fails as it should (the 8.87 m jump);
`corin_letter_probe` ok; stills of the pocket (`corin_letter_probe
stills=`, `corin_props_shot`) looked at. The voice sheet was regenerated
for Corin's new line (`tools/vo_sheet.py`); rerun it once everyone's lines
are in, since it reads every script.

- **"Players hand distort really bad when Bram hands you box"**: since 8
  November (Gary: "Left hand still goes through box...") a flat hand asked of
  Player A opened his fingers 70 degrees at their roots and turned his thumb
  60 degrees (`Figure3D.OPEN_FLAT`), and his rig can't take it: Tripo3D put
  his finger joints 3 to 4 cm back in the palm from his knuckles, weighted
  his palm to his thumb's bones and his thumb to his fingers'. Measured on
  the mesh (`tools/hand_weights.py`, which simulates the opening on the bind
  pose): the left hand's skin stretched to 3.7 times its length, 132 of its
  1214 triangles over 1.6 times (the right 2.9, 50), the palm twisted with
  the thumb's turn and the wristband's charm torn. Re-weighting the fingers
  as one block opened about the true knuckle line (tried at 30 to 90
  degrees) still tore them where the curled fingers meet the thumb (2.5
  times at the 99th percentile), since the modelled fist joins them. So his
  hands are kept as he modelled them (`OPEN_FLAT` has no Player A now) and
  the hold suits them: his left hand is a loose claw (fingers standing 10 to
  12 cm up off the palm, the thumb across it), his right near flat (its
  fingers curl 4 cm up at most). The box goes on his right hand
  (`Ashford.BOX_FIT` `carry`, `carry_side`, `other_side`, `_box_mirror`:
  every mark of the hold mirrored), resting on the thumb's mound and the
  curl of his fingers, a cupped hold (`bottom` 3.5 cm, `heel` 3 cm forward);
  only that hand goes in under it as Bram holds it out (`one_hand`), and his
  left, with its curled fingers, comes up round the box's side to the lid's
  edge and lifts it (the path the right hand took, mirrored); after the
  reveal the box stays on his right hand at the waist. Looks B, C and D keep
  the two-handed hold on the left hand as tuned on 8 November.
  `_box_left_at`/`_box_right_at` are `_box_carry_at`/`_box_other_at`;
  `tests/box_hold_probe.gd` follows the carrying hand. The right palm is
  cupped (its middle 2.4 cm up, the thumb's ridge 3.2, the curled fingertips
  3.7), so a box laid flat on the highest of it stood 1 to 3 cm clear of the
  palm and looked to float: it's tipped 6 degrees front up on the hand
  (`Figure3D.attach`'s new `tilt`; `BOX_FIT` `tilt`, `_box_tilt`,
  `_box_lift`), resting along the thumb's ridge and the fingers' curl, the
  fingertips up in front of it; held level in Bram's hand it's clear of the
  thumb (`level`, `_box_level_bottom`) and settles to the tip as it's brought
  in. The left hand lifts the lid with its palm held 13 cm over it and 6 cm
  in from the far edge (`lid_over`, `lid_back`), so the curled fingers come
  down onto the lid, not through it (at the bottom's height they went 2.1 cm
  into the box).
  After: `box_hold_probe a`: no skin of either hand in the box or the lid
  at any stage (taken, centred, on the one hand, lid up). In the game
  (`notes_1106_shot deck look=a`, 92 frames): the right hand clear of box and
  lid every frame; the left at the lid: its curled fingertips over the lid's
  far edge 1.1 cm deep for 6 frames as it swings up, and 0.7 cm into the
  box's far rim for 2 frames as it starts (was 2.1 cm with the palm at the
  bottom's height; raising it and moving it in from the edge didn't shift
  these: they're the fingertips wrapped on the edge doing the lifting, which
  reads right in the stills). No hand stretched or twisted in any still.
  Still open: a box on a cupped palm has a hollow under its middle, seen from
  the little finger's side at the box's own height; looks B, C and D weren't
  re-run (their hold is unchanged).
- Tam's letter (found on the way): the player's hands at its sides were
  opened by `OPEN_FLAT` too (flat 1.0), with the same stretching (the left
  hand twisted and its charm torn in the stills); with it gone his hands are
  as modelled there, curled, no skin in the letter before or after
  (`tests/letter_hold_peek.gd`, new). Left as it was: his palms sit 3 to 4 cm
  out from the letter's edges, not on them (the palm frame is offset from
  Player A's mesh), both before and after.

**The afternoon and the evening**

- **"You can miss talk with Corin by talking to Bram first in the evening. I
  don't want that to be possible: if you talk to Bram first have him say Corin
  was looking for you over by the mill"**: Bram's evening talk
  (`Ashford._bram_evening`) only offers "It's nearly midnight." once Corin's
  evening on the mill-race wall is done (`corin_pond`). Before that, after his
  "Look at them" lines the first time, he says: "Corin came looking for you
  while they were lighting the lanterns. Wouldn't say what for. He's gone off
  down by the mill, sat on the race wall on his own." / "Go and find him,
  Sprout. He's leaving soon enough, and he's too proud to come looking
  twice." (`bram_sent_corin`), and any time after that before Corin: "He's
  still down at the mill race, Sprout. Go on. Midnight'll keep." The evening's
  words put Corin first from the moment the sun's down
  (`AshfordDay.EVENING_CORIN`: "Enjoy the festival. Corin's gone off on his
  own, down by the mill race: find him. (Follow the arrow...) Then, before
  midnight, find Bram..."; `sunset` set the old Bram-only line, and Corin
  only came into it after a reload), and the arrow points down the lane to
  "Corin, at the mill race" until he's seen, then to Bram. Master Script v7
  (`docs/script/v7_prologue.md`) has the new lines and the rule. The rest of
  the evening: Tilly's thanks can't be missed (she runs up the moment the
  player's near her, and the sunset leaves them 2.4 m from her); Tam's bread
  and Nell's dance can, as the script has them (optional; nothing later
  depends on them but Tam dancing at midnight). `tests/evening_order_test.tscn`
  talks to Bram before Corin (twice) and after, and checks the words, the
  arrow and that midnight starts only after Corin.
- **"You can run through the villagers next to Ned"**: the dancers by Ned's
  fiddle, the children round Corin and his mam at the bakery door were
  extras with no body at all (`Cine.spawn` stands them in a bare node), so
  the player ran straight through them; the talking villagers (Ned, Hob,
  Bram, Tam...) had World's own and were solid already. Each has one now,
  `AshfordLife.solid` (an upright cylinder under their feet, 0.28 m across
  the shoulders, a child's 0.21, in the node they stand in, so it goes where
  they go), made with them in `AshfordP1.crowd`. Only the player is stopped by
  it: staged walks set positions and already go round people
  (`Cine.route`), and `Cine.blockers` leaves an extra's body out (it's a
  person, not a thing in the set; `tests/p1_v7_test`'s solids check too).
  So nobody dances or runs into a player who's standing still, the reel
  makes way (`AshfordP1._dance`: when a step in the next `DANCE_LOOK` 0.35 s
  would bring a dancer into the player, the couples' turning eases to a stop,
  `DANCE_EASE`, and they dance on the spot until the player moves on; the two
  couples keep their places opposite each other), a child's run or a
  shuffle, and Corin's step about, never ends where the player stands
  (`AshfordLife._on_player`). `tests/green_bodies_test.tscn` runs at each of
  them from eight sides: before, straight through every one of them; now
  the player stops at their body (0.0 cm in, every one) and is never left
  stuck (0 of 55 runs), stands in the reel's way without a dancer coming into
  them (the reel stops and starts again when they walk off), and Bram's walk
  past the dancers to Ned and the player's staged walk past the children
  aren't held up.
- **(found on the way) the player's hands in the race wall**: sat beside
  Corin on the mill-race wall the player's hanging arms went 9.6 cm into the
  stone (56 frames of the quick wall run), as Corin's had before 6 November.
  The pond film sits them with their hands in their lap (below) and the wall
  solid to their hands (`Figure3D.hands_off`, as Corin's), and the button's
  hand-over takes only the hand it needs and puts it back on the thigh after
  (`AshfordDay.corin_button`): 0 frames in the wall, the two palms still not
  into each other (`tests/notes_1106_shot.tscn wall`, which now watches the
  player's hands too).
- **"Hand goes through bench when you sit down with Nell"**: a sat figure's
  arms are its standing clip's, hanging at its sides, and on the bench that's
  straight down through the seat beside the hips: the player's hands went
  right through the boards (3.5 cm, the seat's whole depth to its middle)
  sitting down, sat and talking (14, 51 and 47 frames), and Nell's free left
  hand the same all the time she sat there (and her pat on the seat beside
  her went 1.5 cm under its top). Now the hands have somewhere to rest
  (`AshfordP1.lap_hands`, `LapMarks`): the player's on their thighs, a little
  over half way to the knee, palm down, fingers on towards the knee (each
  hand's mark rides its own thigh, read off the thigh's bones as they're
  posed each frame, so as they sit down the hands go onto the thighs as the
  thighs come forward, and stay there through the talk; standing up they push
  off the thighs as the legs straighten, then go back to the clip by
  themselves, `LAP_LET_GO`); Nell's free hand over the other on her stick (her
  skirt stands well off her thighs, so a hand "on the thigh" was inside the
  cloth and down on the seat; an old woman's two hands on her stick), back
  there after her pat, which now lays her palm flat on the boards and stops
  at their top (`PAT_REST`, `PAT_LIFT`). `sit_down(..., lap)` asks for it;
  `sit_with_nell` and the mill-race wall use it. Measured on the hands' skin
  (every vertex) against the bench as built (the seat, the backrest, the two
  legs, the lantern post) every frame (`tests/bench_hands_probe.tscn`, `nolap`
  for before): the player's hands 0 frames in it (was through it), Nell's 0
  (was every frame she sat), her pat 0. Left as it was: sat, the hips and
  thighs press up to 3.5 cm into the seat's top (both of them, before and
  after: `Figure3D.SEAT_PAD`), under the thighs where it isn't seen.
  `lap_rest = false` turns it all off.

- **(found on the way) a child running through Nell's bench**: the
  New Game walk-through (`p1_v7_test`) caught the third child running
  through the bench as Corin's talk began. With Corin met nearer the crate
  now, that child's place behind him (`AshfordP1`, "the children gather
  behind him") fell on the bench, and a walk that ends on a thing goes
  straight through it: the places are moved off anything solid now
  (`Cine.off_blockers`). And since a staged walk that starts inside a
  thing's circle is let through it (`Cine._keep_off`; a long thin bench's
  circle reaches well past its seat), the children's own runs and shuffles
  check the straight line against the set's real solids first
  (`AshfordLife._clear_run`: rays at a child's knee and chest, a body's
  width either side; people and the ground don't count) and hop on the spot
  instead when it's blocked.
- **(found on the way) the voice sheet's scenes**: a line after a lambda
  (`func(...)`) was filed under the scene "("; `tools/vo_sheet.py` skips
  those now.

### Gary's 8 November play-through notes (the memory, the morning, the green, the waking, the dawn, the cellar)

Thirteen notes from playing the Mac build, 8 November, and what each became
(`docs/handover/2026-11-08-pm.md`). Every look plays as Player A in the game
(`DollArt.player_look()`), so the game's stills check A.

**The Night of the White Sky**

- **"After Morrowen speaks at the beginning it glitches for a bit"**: the
  moment her line ended, `_sigilfall` made everything the tear and the Sigils
  are drawn with for the first time, spread over the next seconds: each
  colour's card read its painting off disk and compiled its own copy of the
  `CARD` shader (eight compiles of the same code), each colour's pool its own
  `POOL`, every strike its own streak material, the first ribbon, the first
  sparks and the first strike's sparks their particle shaders, and each landed
  as a hitch (the first card frame took up to 0.9 s more than its neighbours,
  the first impact frame up to 0.6 s). The picture itself never jumped. Now
  `WhiteSky._warm_sigils` builds it all under the caption, on black (a pit
  `"Warm"` at `WARM_AT`, in the camera's view behind his back: a ribbon, a
  streak, a strike's sparks, a small light, then one colour a frame — its card,
  its sparks, its pool — the hunter faded and whole, the look-up clip and the
  strike sound; freed two frames later; `warm_sigils = false` turns it off),
  and there is one `Shader` per kind shared by every colour (`_shared_shader`,
  `_streak`, `_pool_mesh`, `_streak_mesh`, `_impact_sparks`, `_trail_mesh`).
  After: no frame after the line stands out from its neighbours. Found on
  the way: if he stood still as the sky opened, the look-up clip held and
  setting off he slid over the snow in it for two seconds before his legs
  began; `_roam_step` releases it the moment he moves.
  `tests/white_sky_hitch.tscn -- <dir> [nowarm|stand|stills]` prints the
  frame times round the end of her line.
- **"Bram's hands twist when he picks up the baby"**: `reach()` fixed each
  hand's place and left its turn to the arm's IK: on the way down both palms
  faced away from the bundle (112 and 129 degrees off it), on it the hands
  were edge-on with the fingers across its ends, and standing with it the
  right palm faced away the whole hold; the marks were under the bundle's
  axis, which with any palm-up turn put the palm on top of it; and the carry
  turned the bundle to one fixed yaw, so coming at the child the way he walks
  it swung half round in his hands and his arms crossed. Now `_lift_child`
  turns each hand as it reaches (`Figure3D.palm`: palm up and in towards the
  bundle's middle, `LIFT_PALM`; fingers on under it, `LIFT_FINGERS`; a little
  cupped, `LIFT_FLAT`), the elbows out to his sides and low (`LIFT_ELBOW`),
  the marks set from where the palms should lie (`PALM_AT`, `MARK_OFF`), the
  cradle's yaw so the end his left hand holds stays on his left, and wrists
  and elbows given back at `_tuck`. After: no frame with a palm turned away
  (was 31 of 102), the palms 4 to 9 cm under the axis, elbows never in past a
  shoulder, hands uncrossed standing. `tests/white_sky_peek.tscn -- <dir>
  lift [side] [nowrists]` measures the wrists and elbows each frame.

**The morning**

- **"Bed scene looks much better, can we now make it slightly faster"**:
  nothing was wrong with it, it was long: from the fade-up to standing still
  after the stretch took 9.5 s (the get-out-of-bed clip 4.8 s at 1.15x, the
  stretch 2.8 s). Each movement is kept and brisker (`AshfordP1`, by
  `SWING_LIFT`): `RISE_STIR` 0.9 s from the fade-up to the hand going to the
  hem (was 1.4), `BLANKET_SECS` 0.6 for the morning's throw (was 0.8; the
  hand finding the hem inside `throw_blanket` is quicker for the midnight
  waking too, which keeps its own 0.7), `RISE_SPEED` 1.6 for the clip (was
  1.15) with the lift onto the mattress on its own `LIFT_IN` 0.28 s (timed off
  the blend at the new speed the hips dipped 4 cm), `STRETCH_SECS` 2.0 (was
  2.8), the step off the bed at 0.8 m/s. After: 6.7 s to standing, 6.9 s to
  the controls (was 9.8) — 29% shorter, the hips never dipping, no jump over
  the blend's 3 cm. `tests/bed_probe.tscn -- from=0 to=16` prints the
  timeline; `tests/attic_peek.tscn -- <dir> seconds=14.5 every=0.5 tap` takes
  the game's stills.
- **"When eating the porridge the spoon doesn't go all the way to the mouth,
  it only gets to about chest level"**: three things. The hand's target was a
  fixed point already under and in front of the lips (on Player A the lips are
  4.5 cm above and 17 cm ahead of the Head bone, measured off the mesh by
  `tests/mouth_find.gd`); the arm's IK puts the end of the hand bone on its
  target and the turn of the hand to hold the spoon swung the palm 7 to 14 cm
  short of even that; and the spoon lay centred along the fingers, entirely
  inside the cupped hand, so no still showed a spoon at all. Now `_eat` reads
  the lips as drawn (`mouth_of`, `MOUTH`), a `SpoonHold` modifier last in the
  skeleton's list holds the spoon by its handle's end in the fist and points
  it (`SPOON_LIFT`), its pitch going from `SPOON_DIP` down into the bowl up
  and over to `SPOON_UP` at the lips, the fist under the chin and the wrist
  turning with it (`SPOON_PALM_BOWL`, `SPOON_PALM`), the drawn fist read back
  each frame and the target corrected by what it fell short
  (`SPOON_FEEDBACK`, `SPOON_CORR_MOST`), the bowl end stopping at
  `SPOON_AT_MOUTH` (a centimetre right of and under the lips, 2 cm in front),
  his eyes on the bowl so the head dips to meet it; the spoon has a flat oval
  bowl, and the camera is over the counter's north end looking back at his
  face. After: the bowl end comes to 2.3, 1.5 and 1.3 cm from the lips on the
  three mouthfuls, pauses, and goes back to the bowl. `tests/eat_probe.tscn --
  <dir>` measures it and takes the stills.
- **"Door passes through player when it opens before leaving inn"**: the leaf
  (1.15 m, hinged on the east jamb, opening into the room to 100 degrees) was
  right; the player stood in its swing, the walk ending anywhere within
  0.85 m of `door_in`, 0.9 m from the hinge, and stepping off 0.4 s into the
  0.7 s swing, with the crate reaching 0.6 m further. `InnRooms.eve` has a
  `door_stand` now, the leaf's width and 0.7 m back from the wall (2 m from
  the hinge, the crate's near corner 1.29 m from it); `_taproom`'s walk ends
  at the stand or at the door as before, the camera glides to `DOOR_CAM` (the
  door's side of the table, player and door in frame) as they take the last
  step, the menu, then the leaf swings (`DOOR_SWING` 0.7) and they step off
  at `DOOR_STEP_OFF` 0.55 s, once it's past square, reaching the doorway with
  it fully open. After: the leaf into the player's capsule 0 cm and into the
  crate 0 cm every frame, through the doorway at 2.0 s with the leaf at 100
  degrees. `tests/door_swing_test.tscn -- <dir>` checks it every frame;
  `tests/taproom_walk_test.tscn` takes the crate itself now (it waited on an
  objective that no longer exists).

**The green**

- **"Corin is back to taking ages to walk over to you instead of as soon as
  you put crates down"**: his walk was one walk and did start, but late and
  out of sight. The player stood at the Lantern holding the crate for four
  seconds while Bram's wide swing round was waited for, Corin was only sent
  as the crouch began, his 10.6 m round the Lantern's foot took 5.3 s at
  `CORIN_WALK` 1.7, and from the crate's low shot (held 3.5 s for
  `bram_to_stool` and `home`) he was behind the player and then the Lantern
  the whole way; his first line came 4.8 s after the crate touched the grass,
  most of it spent looking at the crate. Now `_green` sends him
  (`corin_sets_off`) the moment the player stops at the Lantern, in the wide
  shot where he's seen setting off by the drum, and waits for Bram after;
  `CORIN_WALK` is 2.0 (his own clip at 1.18x, no slide); once the crate's
  down `bram_to_stool` runs un-awaited, the player looks up to Corin and
  `home` glides the camera up behind them at once; if he arrives before his
  talk begins he stands waiting with his eyes on the player
  (`_corin_comes` keeps `life_busy`) instead of the green's life shuffling
  him; `corin_calls` glides straight into the talk's own framing
  (`two_shot_cam`) with no cut, and when he's already there it glides round
  from behind the player. After: sent at 5.0 s, at his mark at 9.8 s, the
  crate down at 10.8 s, his first line at 13.3 s — 2.5 s after the crate
  touched (was 4.8), one walk, no jump, no cut back. `tests/notes_1106_shot.tscn
  -- <dir> walk` times the moments and fails if he's sent more than half a
  second after the crate touches or speaks while still walking.
- **"Left hand still goes through box as you're holding it when you open it
  to reveal cards"**: three things the 6 November bone checks couldn't see,
  found by checking the hands' skin (`tests/hand_skin.gd`). Gary's box model
  isn't `CARD_BOX_SIZE`: `_card_box` sized it by its width alone, and it's
  16 x 6.3 x 12.4 cm, not 16 x 11 x 9.5, so every hand placement had its
  bottom 2.3 cm lower than meant and its back 1.4 cm further over the wrist
  (`Ashford.box_size` reads the model's own size now, and `_box_back`,
  `_box_lift`, `_box_right_at`, the grip marks, the lid edge, the right hand's
  way round and Bram's palm hold all use it). The palms are thicker than a
  skin's width (2 to 3 cm of heel and thumb mound over `palm_frame`), so the
  palms sat 1.3 to 2.3 cm inside the box: `BOX_FIT` now has each look's
  `bottom` from its skin profile (A 2.8, B 3.2, C 2.5, D 2.2, Bram 2.7 cm) and
  the rigged thumbs' `thumb` aside, `sink` is gone (`_box_bottom`), and the
  right palm's mark sits `BOX_RIGHT_UNDER` further under. And Player A's hands
  are modelled as loose fists (`FROZEN`): his fingers stand 10 cm up from the
  knuckles and his thumb 6 to 9 cm, so a 12.4 cm box on a 6.6 cm palm had the
  fingers up through its front half and the thumb through its side whatever
  was done with it — the open-box view Gary saw. `Figure3D.OPEN_FLAT`: when a
  flat hand is asked for (`palm(..., flat)`) a hand modelled closed opens, A's
  fingers turned 70 degrees out of the curl at their roots about the knuckle
  line, the thumb 60 degrees down along the hand's side (`_turn_hands`,
  `_turn_bone_about`). In `_first_deck` the right hand is laid flat over the
  lid with its fingers kept pointing ahead as it turns, and as the lid swings
  open the hand turns with it, palm to the lid's face (`lid_follow`). After:
  in the game (`notes_1106_shot deck look=a`, 92 frames from the hand-over
  through the reveal to the box going down) no hand's skin in the box or the
  lid, no bone either (before: 200 to 223 left-hand vertices in the box, 3 cm
  deep, 63 to 77 in the lid); `box_hold_probe` A, C and D clear, B's skin
  clear with the bone test's extrapolated right-pinky tip 0.9 cm at the box's
  front edge (probe only). `tests/box_hold_probe.gd -- <dir> <look>
  [open=<deg> thumb=<deg>]` measures the skin and prints the palm profiles
  `BOX_FIT` comes from.

**The waking, the dawn and the cellar**

One cause under three of these (8, 9 and 13): a per-frame "palm correction"
that read `Figure3D._palm_point()` between frames, where a bone has only the
clip's pose (white_sky.gd notes the same), so it saw Bram's hand at his knee
and drove the target away to its clamp. The palm and the shoulder joint are
read at `skeleton_updated` now (`Ashford._palm_watch`, `_palm_unwatch`), the
target is capped at `SHOULDER_REACH` (0.96 of the arm) so an out-of-reach
point can't wind it up, and a hand comes to a shoulder from above and outside
and leaves the same way (`SHOULDER_FROM`, `SHOULDER_GLIDE`,
`_shoulder_leave`).

- **"When Bram puts his hand on player shoulder it goes through it when you're
  both sitting on the bed"**: his hand was 11.4 cm into the player in 105 of
  107 reaching frames, the target 7 cm over the Arm joint where Player A's
  shoulder top is 10 cm over it, the elbow in front so the hand came up on
  its edge from the side. Now `_shoulder_point` (`side`, `reacher`, `hand`)
  puts the palm's middle `SHOULDER_TOP` 12 cm over the joint and
  `SHOULDER_OUT` 2 cm outboard, rolled `WAKE_ROLL` 25 degrees in towards the
  neck with the fingers forward over the front, the elbow round behind them
  (`WAKE_ELBOW`), his thumb (modelled folded 7 cm under his palm) opened by
  `Figure3D.OPEN_FLAT["bram"]`; the elbow 57 to 123 degrees, never locked,
  the two bodies never overlapping. Left: the index and little fingertips
  drape 2.6 to 3.4 cm inside the test's 10 cm sphere round the joint (the
  real shoulder is flatter than a sphere there) and a frame or two of
  transients as the hand arrives and leaves.
- **"After it mentions about the Herald, Bram's arm distorts"**: the shoulder
  was picked before either had turned — the far one, 0.90 m from his own
  shoulder against an arm of 0.56 — so the arm locked straight and twisted to
  point at it. Face to face the near shoulders are 12 cm further apart than
  the hips (both idles hold the shoulders back), so the two now stand
  `WIN_APART` 0.46 at the window, and as he turns Bram steps in `WIN_STEP`
  0.12 and turns `WIN_OPEN` 30 degrees past them so his right shoulder swings
  forward (`eyes_on` keeps his eyes on their face), waits for the turn, then
  his right hand goes to their left shoulder (`WIN_ELBOW`, palm down), and
  comes off (`_bram_hand_back`) before the walk to the hatch. After: the
  target 0.48 m, elbow 93 to 137 degrees, never locked, settled frames 0 to
  0.9 cm. Left: as the hand comes in (half a second) the forearm passes 5 to
  9 cm through the player's upper arm on its way up.
- **"Dawn, after Hob's line, it takes a while to load"**: the Herald was built
  after his line, and the frame that first drew it compiled its burial
  cloth's shader, its mist's and the visions' (a 3.6 s frame with 176 nodes
  built). `Ashford._warm_herald` builds the Herald, its mist and a vision with
  every Champion's name while the screen is black at the start of `_dawn`,
  before the caption (checked: the black at alpha 1.0, every warm-up still's
  brightest pixel 0), `_herald_ready` takes it from there, `PaleHerald.shader_for`
  shares one compiled shader per kind, the Champions' pictures are held
  (`_faces`). After: nothing built after Hob's line, the longest frame there
  1.6 times an ordinary one (the close two-shot of the kneel, rendering load).
- **"After the Herald, when it cuts to Bram he is crouched and distorted
  while talking"**: the village knelt in the way down of the sit clip (a
  squat with the back bent), and Bram's arm reached straight out of it to the
  shoulder tracker, which was left alive to the hub's end. `_kneel` is the
  one-knee kneel now (`Figure3D.kneel(..., upright)`, `KNEEL_LEAN`), the
  tracker is freed as soon as his hand is off. Measuring everyone's kneel
  found `Figure3D._kneel_pose` itself wrong: the Hips offset the wrong way
  (hips 12 cm low, the kneeling knee 2 to 5 cm under the grass, the planted
  foot's ankle 6 to 16 cm under and its toes pointing on down), so `upright`
  is the one-knee kneel at its right height, the planted shin from the
  figure's own lengths, feet flat (`KNEEL_TOES`); the default kneel is left as
  it was because the White Sky's lift has his stoop and hands tuned to it.
  After: from the Herald's going to his hub line, 126 frames, crouched while
  walking 0, arm still reaching 0; knee joints 6 to 9 cm up, toes on the
  grass, everyone.
- **"Then in the next scene his body is going through the stairs"**: the
  cellar's `stairs` point is the staircase's middle, and the player packed
  half a metre west of it, stood in its bottom two steps (the left foot 16.6
  cm in for 197 frames). They kneel on both knees now (`Figure3D.kneel` with
  `both`) 1.5 m west of it, palms flat on the satchel's flap (`PACK_AT`,
  `SATCHEL_AT`, `PACK_HANDS`, `PACK_FLAP`, `Figure3D.press`); 0 frames in the
  steps, knees and toes on the floor. And Bram's marks (note 13, found while
  there): he knelt a metre off the marks with the cask between and reached
  for them through it, arm locked straight 64 frames, hand through the cask.
  Now on both knees 0.26 m off the timber (`MARKS_KNEEL`, `MARKS_LEAN`), palm
  tipped 30 degrees off it (`MARKS_TIP`), one point glided mark to mark
  (`_press_mark`, `MARKS_IN`, `_marks_done`), the three nearest then the last
  (`MARKS_PRESSED`), turned 45 degrees not square to the player for the line;
  palm 0.30 to 0.44 m from his shoulder, never locked, feet clear of the
  timber (left: the wrist 1.2 cm in for two frames at the lowest mark).

`tests/after_midnight_shot.tscn -- <dir> bed|dawn|cellar|warmonly [every=N]
[choice=N] [nomesh]` measures all of it: Bram's hand bones and skin against
the player's mesh (skinned on the CPU), the reach against his arm, the elbow,
the frame times through the dawn, everyone's kneel, both figures against the
steps, the timber and the cask.

### Gary's 6 November play-through notes (the memory, the first day, midnight)

Twelve notes from playing the Mac build, 6 November, and what each became
(`docs/handover/2026-11-08.md`). Since Master Script v7 every look plays as
Player A in the game (`DollArt.player_look()`), so the four-look stills
check A in the game and the others only in the plain-stage probes.

**The Night of the White Sky**

- **"Bram still walks very weird at start of game"**: the 5 November posture
  had gone too far: walking, his back leant 7 degrees behind upright and his
  face was turned 14 degrees up at the sky, and the coat model's own walk put
  each foot down on the line of the other, swung the left arm out wide and
  slid his feet a quarter of his pace. He walks on the taproom Bram's own walk
  now (`Figure3D.OWN_CLIPS`, `OWN_GAIT` 1.76), and `POSTURE`'s `bram_coat`
  entry brings his back a little forward over the hips, keeps his face level
  and his arms hanging: 3 degrees forward, arms 16 degrees out, feet a hip's
  width apart and still on the snow. `tests/gait_probe.gd -- <model> [pace]`
  measures it on the pose as drawn; `tests/coat_walk_peek.gd` takes stills.
- **"Can we make the whole scene like the shards of ice and the cards look
  much better"**: the spires were plain cones of near-black glass. They're
  clusters of six-sided ice crystals now, pointed, faceted, their feet sunk in
  the snow (`WhiteSky._crystal_mesh`, `_low_ground`), in the `ICE` shader:
  deep blue ice you see into, thin cracks and drifting specks of light inside
  (`ICE_LAYERS` by Gfx level), the edges and points catching the light, frost
  on top and snow at the foot; the crater's are paler and lit from within, and
  the filmed duel has a ring of them (`_ice_round_duel`). The Sigils are real
  cards (`sigil_card`, the `CARD` shader): rounded corners, the card back one
  side, a painting of their colour (`CARD_FACES`) with a pulsing rune ring the
  other, a line of light round the edge; they flutter down (`_flutter`) with a
  ribbon of light (`TRAIL_LEN`) and on a Mac sparks, flare as they land with a
  round pool of light on the snow (`POOL`), never on the child or at Bram's
  feet (`CARD_CLEAR_CHILD`, `CARD_CLEAR_HIM`). `tests/white_sky_peek.tscn --
  <dir> ice|cards`.
- **"Baby still levitates off ground into Bram's hands"**: on one knee his
  straight arms ended 15 cm over the bundle, so it rose to meet them. He
  kneels square on to it (`_kneel_dir`, `_kneel_spot`) and bends right over it
  from the hips (`Stoop`, `STOOP`); it doesn't move until both hands are on it
  (`lift_gap`, `HANDS_ON`, measured on the pose as drawn), then comes up with
  his back (`LIFT_SECS`). Filmed low on his right; "Hush, now" over his left
  shoulder (`_held_shot`). `tests/white_sky_peek.tscn -- <dir> lift [side]`.
- **"When Bram's battle happens in the beginning it stays on a white screen
  for ages"**: the whole duel was built and drawn for the first time in the
  white. It's built behind the memory while the pick-up prompt waits now
  (`WhiteSky._prepare_duel`, `DuelScreen` `spec.hold` and `go()`), warmed and
  then not drawn until the cut (`DUEL_WARM_SECS`, `DUEL_WARM_MAX`); the white is
  a short flash (`WHITE_HOLD`); the duel is ended before its screen goes
  (`_end_screen`). Nothing of the inn was found showing or playing behind it.

**The first day**

- **"Corin starts walking up when you put down lanterns but then it cuts to
  him back where he was and walks up again"**: his talk started a second walk
  while the first was under way, and the green's life could take him back to
  his old spot. One walk now (`AshfordP1.corin_sets_off` keeps `corin_meet`;
  `corin_calls` lets it finish, walks only the rest if he was stopped short,
  and the camera glides instead of cutting); `AshfordLife` leaves him alone
  while he's `corin_coming`. `tests/notes_1106_shot.tscn -- <dir> walk`.
- **"Bram's card box now goes through player's arm while he's holding it"**:
  Player C's hands have no middle or little finger bones, so they never turned
  palm up (`Figure3D._knuckle_rest` now); Player A's kept thumbs came up
  through the box's side and lid; Player D's box floated 3 cm over the palm
  (`Ashford.BOX_FIT`, `_box_lift`, `_box_aside`). The box sits halfway between
  the hands as it's taken (`BOX_ASIDE`, `Figure3D.attach`'s `aside`), the left
  hand slides under its middle with the box kept still, the right drops away
  below it. `tests/box_hold_probe.gd -- <dir> <look>`; `tests/notes_1106_shot.tscn
  -- <dir> deck look=<a|b|c|d>`.
- **"When you meet Corin in evening his hands look through the wall he is
  sitting on; his legs also go through the wall when he turns to you"**: he
  sits towards the wall's meadow edge so his shins hang clear
  (`AshfordDay.RACE_WALL`, `CORIN_SEAT`), one hand flat on the wall top, the
  other in his lap, the wall solid to his hands (`_corin_rests`; `_corin_up`
  undoes it), and he turns his head alone (`_corin_eyes`, `_corin_beat`,
  `Figure3D.eyes_on`). `tests/notes_1106_shot.tscn -- <dir> pond|wall` checks
  legs and hands against the wall every frame.
- **"When Corin hands you something your hand goes through his"**: the
  player's hand comes in under the edge of his, palm up, beside and a little
  lower (`BUTTON_ACROSS`, `BUTTON_UNDER`); he tips his hand and the button
  slides into their palm; a close shot of the hands.

**Midnight and the waking**

- **"When you're doing the heave pull with the cart the players aren't doing
  anything"**: the player crouches at the cart's tail and takes the tail board
  in both hands (`HEAVE_GRIPS` on the slats, `HEAVE_STAND`); each HEAVE is a
  strain up out of the crouch with the cart coming up in their hands
  (`HEAVE_TIP`); on the PULL they stand with it (`HEAVE_PULL`) and Tilly, by
  Corin's head (`TILLY_AT_HEAD`), drops down (`TILLY_CROUCH`), takes him under
  the arms and drags him clear; the player comes round the tail to him
  (`HEAVE_TO`). `tests/night_close.tscn -- <dir> heave`.
- **"The hay cart that falls on Corin seems really big"**: it was 2.5 m across
  the wheels and 2.46 m to the top of the hay. `AshfordVillage.HAY_CART_SCALE`
  everywhere it's used (Ashford, the mill, Solhaven): 1.9 m across, 2 m high;
  Corin lies at `Ashford.CART_PIN`; `set_cart_tip` turns before it scales so it
  doesn't skew.
- **"When you wake up in bed after the white card you're not under the
  covers, your body is half way through them"**: his own hand throws the
  blanket back before he sits up, after the white light as in the morning
  (`AshfordP1.throw_blanket`); the attic bed is `InnRooms.BED_FOOT` longer at
  the foot and the blanket (`BLANKET_L`, `_blanket_points`) covers him to his
  boots, where they had stuck out through its end.
- **"When Bram sits down on the bed his arm goes through the player and his
  eyes are weird"**: he sits `AshfordNight.WAKE_BESIDE` along from them, his
  near hand palm-down on their shoulder (`WAKE_ELBOW`, `palm`), back to his
  knee as they look at their hands (`_bram_hand_back`); he only glances their
  way (`look_turn`, `WAKE_LOOK_TURN`) and the shots keep his face to the
  camera. His eyes are painted on the texture, so side-on they still look odd:
  a Bram model with modelled open eyes would settle it.

### Gary's 5 November play-through notes (the memory, the opening, the green)

Eleven notes from playing the Mac build, 5 November, and what each became
(the duel's, "Make the battle look better, at the moment it looks boring, I
want it more dramatic", is under "A more dramatic duel (5 November)" in the
Duel Lab section):

- **"Why does Bram pause after Morrowen finishes talking?"** He was being
  stopped: once her line ended the walk was taken off him for four seconds,
  the camera cut to the sky over his shoulder, and he stood looking up as it
  tore, which read as the game hanging. Nothing stops him now
  (`WhiteSky._sigilfall`): the sky tears over him as he walks, the roaming
  camera behind him lifts its eyes to the tear for a couple of seconds and
  comes back down with him still in the foot of the picture (`_sky_look`,
  `SKY_LOOK_UP`/`HOLD`/`DOWN`), he looks up himself only if he happens to be
  standing, and the arrow comes up after `COMPASS_AT`.
- **"Compass should be more of an arrow"**: `WorldHUD.Compass` is one big
  gold arrow now, a broad head on a tapered shaft with a dark edge and a
  soft glow, nudging forward along its own line, on a faint dark disc so it
  reads over snow or sun; the dial's four points and tick marks are gone.
  Still `Compass` by name, with the same calls, so the map can grow from it.
- **"Bram looks hunched over. Have him stand up straight"**: his coat
  model's clips round his back from the hips up and carry his head a hand's
  width ahead of him. `Figure3D.POSTURE` has a `bram_coat` entry now (the
  three spine bones drawn up, the neck up and back, the face kept level, the
  shoulders back); `tests/stance_peek.gd -- <dir> [model] [tag]` shows any
  model standing and walking against a plumb line. The taproom's own Bram
  (`bram`) stands well enough as he is.
- **"Bram picks up the baby weird, it more levitates into his arms rather
  than him picking him up"**: the bundle rose on a path of its own while he
  stood, the hands chasing it. `_lift_child` picks it up the way anyone
  picks up a baby: on his knee he gathers it in to his chest first
  (`GATHER_SECS`), then stands with it held there (`RISE_SECS`), the bundle
  carried relative to his chest bone every frame (`CRADLE`) so it comes up
  with him and the hands stay under it.
- **"When you write player's name on mirror can we make that look better,
  at the moment it looks like they just wave their hand in front"**: the
  hand had slid once across the glass while the whole name faded up at
  once. `AshfordP1._write_in_frost`: the hand is turned so its fingers point
  at the glass, palm in and down, the knuckles on the frost
  (`_finger_to_frost`, `WRITE_FINGER`); each letter comes up in turn under
  the hand as it travels along the line, rising and dipping over each the
  way a hand writing does; a letter is the frost cleared dark with a bright
  rim of pushed frost round it (`WRITE_INK`, `WRITE_RIM`; one Label3D a
  letter, the name's own label taking over once it's written); a faint
  squeak of skin on cold glass with each letter (`Sfx` "frost_write").
  `tests/mirror_shot.tscn -- <dir> a write` takes stills through it. (Player
  A's hand is a loose fist, his fingers kept as he modelled them, so it's
  the knuckle that writes; an extended finger waits on his 4K remake.)
- **"Bram doesn't try and stop you when you approach the second door to the
  right of the fireplace"**: the taproom's two doorway zones shared one
  six-second clock, so going from the kitchen's doorway to the passage's (a
  two-second walk) met silence at the second. Each zone keeps its own clock
  now (`AshfordP1.walk_room`, `STRAY_AGAIN` 3 s), the zones reach a stride
  further into the room, and the passage's turns the player back
  north-west, clear of the trestle bench (`InnRooms.eve`'s `stray_zones`).
- **"Kids around Corin when you first walk out of the inn take a while to
  come to life and they keep stopping and staring at player"**: life on the
  green (`AshfordLife`) began only once the walk out of the inn had ended,
  and nobody acted for up to four seconds after that; between runs the
  children stood for three or four seconds and one time in five turned to
  stare at the player for as long. Now it starts as the inn's door opens
  (`AshfordP1._street`), the green's people may move through the opening's
  own shots, which never have them in (`life_through_cine`, taken off when
  Corin's scene begins), everyone's first move comes within a second
  (`FIRST_MOVE`), and the children are hardly ever still: a run, then a
  hop, a cheer or a shuffle inside two seconds, their eyes on Corin, a
  glance at the player now and then no longer than a glance (`KID_GLANCE`,
  `KID_GLANCE_CHANCE`). Corin's own look at a passing player goes back to
  his audience after a second or so.
- **"Can Corin start walking over as we're putting planters down so we're
  not waiting so long for him to get to player"**: he sets off across the
  green the moment the crate starts down (`AshfordP1.corin_sets_off`,
  `CORIN_MEET`, `CORIN_WALK`), so by the time the camera's home he's there
  or nearly; `corin_calls` finds him where he is (or picks up his walk) and
  gathers the children behind where he'll stand.
- **"Players fingers still go through box when we see player holding box
  when Bram hands it over"**: Player A's fingers are kept as he modelled
  them, in a relaxed curl, so a box centred on his palm had its front half
  under the curl and the fingers came up through it. `Figure3D.attach` takes
  an `ahead` now, and the box sits back on the palms (`Ashford.BOX_BACK`,
  4.5 cm towards the wrists; the grip marks, the right hand's mark under the
  box and the left hand's place under its middle all moved with it): it
  rests from the heel of the hand to the finger roots and the fingers curl
  up in front of it, a cupped hold. `tests/box_hands_peek.gd` and
  `tests/hands_shot.tscn -- <dir> box` show it.
- **"When you go to sit next to old Nell your legs go through the bench"**:
  anyone more than a step off the seat glided standing to the seat's middle,
  straight legs through the boards, and sat there. `AshfordP1.sit_down`
  sits the way anyone sits now: standing where the feet will be once sat
  (`Figure3D.seat_feet_ahead`), the hips go back and down onto the seat as
  the knees bend, the feet staying put, the sit and the shift one move (the
  spot taken for the seat moving with them); `sit_with_nell` and
  `bram_to_stool` walk to that spot. `tests/bench_shot.tscn` checks the legs
  against the bench sitting down as well as getting up.

### Gary's 4 November play-through notes (the opening, the village, the menu)

Sixteen notes from playing the Mac build, 4 November, and what each became
(the Night of the White Sky's six are under Story mode, the duel's under
"Faster, more cinematic duels"):

- **The title screen** ("can we animate it or make it look better"): the
  painting itself moves (`TitleScreen.ArtLayer`'s shader: the rivers of
  gold light run down the mountain, the brightest stars twinkle on their own
  clocks, the sea of cloud roils under a slow warp), a shaft of light stands
  and breathes over the Throne, a shooting star crosses the sky every six to
  thirteen seconds, and on opening the title rises in with a sweep of gold
  across its letters and the buttons come in after it one by one
  (`TitleScreen.Lights`, `Logo.set_sweep`). `tests/title_shot.tscn` still
  takes its three stills.
- **The attic's decorations** ("flowers coming out of ceiling", "broken items
  on the side", "picture on side look like drawn by a 2 year old"): the
  bunch of lavender hung from a collar beam is gone; the shirt and breeches
  draped over the chest with a sleeve and a leg hanging (the broken-looking
  boxes) are two neat folded piles on its lid; the three scribbles pinned
  by the mirror are two of Gary's card paintings (the Lantern Moth and
  Brookfin) in plain oak frames and a proper ink map of the valley on
  parchment (`InnRooms._sketch`, 256 pixels, soft-edged: the river, the
  road, the green's ring of houses with the inn in red, the mill, hills,
  trees, a compass rose); the rag rug is one picture on a flat oval
  (`InnRooms._rug_texture`: braided rings, a plait across each) in place of
  six stacked discs that read as a target.
- **Player A's little finger** ("the baby finger looks deformed"): his
  Tripo3D rig put every finger joint within a centimetre or two of the
  knuckles, jumbled, with nothing of them along the fingers, so the idle's
  curl of the fingers turned the skin about the wrong pivots (the right
  hand's little finger worst, the left with its wristband too). His finger
  bones are kept at rest now (`Figure3D.FROZEN`, in the Posture modifier):
  the hands as he modelled them, moving whole from the wrist.
  `tests/hand_peek.gd -- <dir> [look] [idle|walk|rest]` takes close-ups of
  both hands.
- **Walking to the mirror** ("it cuts player out due to stairs leading up"):
  the camera for that walk was up in the south-west corner by the roof, and
  the collar beams stepping away across the room came between it and him;
  it comes along behind him now, under the beams (`cam_follow` on the attic
  for that walk, at 1.62 m).
- **Eating the porridge** ("his arm goes through himself"): the palm had been
  sent to the mouth itself with the spoon hanging from it, and the elbow's
  usual hint (out and back) folded the arm back past the shoulder so the
  forearm came forward through the chest. Now the hand stops a spoon's
  length short of the mouth, off to his right, the spoon lies in the palm
  with its bowl end towards him (`Figure3D.attach`), and the elbow is kept
  down in front of the ribs: `Figure3D.elbow(side, at)` puts the hint a
  reaching arm's elbow bends towards where it should be (their own frame;
  `Vector3.INF` gives the usual one back); the targets are in his own frame
  (`Figure3D.to_own`) so they go with him.
- **Taking the card box from Bram** ("arms go into body"): with the hands side
  by side under the box in front of the belly, the same elbow hint bent the
  elbows back past the flanks and the forearms ran in through the sides of
  the body. The elbows are held out to the sides and a touch forward at the
  ribs for as long as the box is held (`elbow`, given back in `_drop_box`),
  and the low hold after the reveal is out from the belly (`hold_point(0.52,
  0.78)`, was `(0.36, 0.8)`).
- **The taproom door showing night** ("it shows it as night outside but then
  you walk out into day"): the doorway's view is a picture of the village
  taken once (`InnRooms.view_of`), and under the title screen it was taken
  before the opening turned the day on. `AshfordP1.warm` sets the daylight
  first now (the attic's window view too).
- **Going back to Tam's** ("you go through the floor"): the second time at the
  field gate the game asks whether to go down to the mill, and the question
  didn't take the controls, so a held key or the pad walked the player on
  past the gate, where the lane climbs and the village has no ground to
  stand on. The question stands them still (`AshfordDay._lane_go_again`:
  `busy`, the controls hidden), and a solid wall just past the gate stops
  free walking down the lane at all (the way to the mill is `to_mill`'s own
  walk, which isn't stopped by it).
- **The Deck in the menu** ("give each totem a proper back story, why that
  shard took that form"): every one of the 49 Totems has its story
  (`scripts/duel/duel_lore.gd`, `DuelLore.BACKSTORY`: what the Shard found
  when it fell, and why it kept that shape), shown under the card as "WHY
  THE SHARD TOOK THIS FORM" in the Deck's and the Codex's card view
  (`Codex.Detail`) once the card is owned (a card seen but not owned says
  its story is told once it's yours); the duel's quick card view keeps to
  the short words.

### Gary's 29 October notes on the opening

- **Bram wiping the counter** ("he is waving his hand above it ... he needs a
  cloth in his hand"): a striped linen rag lies on the oak under his palm and
  goes where his hand goes (`AshfordP1._rag`, `_wipe`), long strokes from side
  to side; his palm is held down in the cloth's wad (`Figure3D.press`, after
  everything else: the reach alone left the turned hand a hand's depth over
  it), the fingers half curled round it (`Figure3D.palm(..., flat)`). He
  stands a step nearer the counter (`InnRooms.BAR_BEHIND`).
- **The counter is solid to hands** ("when he is talking to player his hands
  are still going onto the wood of the bar"): `Figure3D.hands_off(boxes)`, a
  modifier after the clip, the reaches and the hand turns: a hand (wrist,
  palm, every knuckle and the fingertips) found inside a box is moved out of
  it the shortest way (up onto the top when the wrist is at its height, else
  out of a side), the arm bending to put it there (`_move_wrist`, two bones).
  `InnRooms.eve()` gives the counter and its raised flap as `hand_solids`.
- **The taproom's walls**: windows at last (Bram's first line is about the
  shutter): one in the west wall behind the bar, two in the north wall west
  of the door, leaded diamond panes of old glass with the frosty morning
  behind them (`assets/shaders/village/pane.gdshader`), frames, deep sills,
  shutters folded back inside, and the one he means swung half open and
  knocking in the draught; cold daylight through each onto the floor
  (`InnRooms._eve_windows`, the walls round them `_wall_with_holes`). Behind
  the bar (`_eve_dressing`): two shelves of stoneware jugs, green and brown
  bottles, pewter plates on edge, crocks, a candle and a paper lantern folded
  for tonight; copper measures on the hooks; the inn's painted board, The
  Crooked Lantern; Bram's round shield from the Shards with a short sword
  behind it; dried hops along the beam. The counter's top and flap are
  polished honey oak (`InnRooms.counter_oak`), not the beams' near-black.
- **Bram's card box, in his hand for real** ("can't you add mechanics so it
  actually fixes it"): `Figure3D.attach(node, "palm"|"between", ...)` puts a
  held thing where the hands are, every frame, after the hands are solved:
  on one palm (its up the palm's way out, its front the way they face), or
  between both palms (`gap`: the arms bend to put each palm on its side). It
  can't hang in the air: it's where the hand is. `Figure3D.grip(node, gap)`
  puts the palms on a thing's two sides without moving it (taking it from
  someone). `palm_frame(side)` is a palm's place and turn as drawn. Bram no
  longer carries it over: it comes out of his apron pocket on "You do now."
  on the flat of his right hand and goes out to the player on it; their
  hands come to its sides and it's theirs, between their palms; then
  ("his hands are in the way when he opens it") it's set on the flat of
  their left hand, the right goes to the front of the lid and lifts it as it
  swings up, and the shot cuts to a close one from beside and above, looking
  into it (`Ashford._into_box_shot`). The deck in Gary's box shows the card
  back on its top card. `tests/hands_shot.tscn -- <dir> box` checks the palms
  are the box's width apart while it's between them.
- **Corin's back** ("still a hole in the back of Corin at the top when he
  turns around"): a pit in the model at his left shoulder blade, 23 cm deep
  through his body (the 23 October fixes only recoloured it).
  `tools/patch_hole.py MODEL --at X,Y --radius R --mirror --bake` lays a patch
  of new triangles over it on the back's own surface (its depth filled in
  smoothly from round it), skinned like the back round it, with its own
  little texture (`corin_patch.png`, `corin_patch_mr.png`): the vest as it is
  at its rim, blending to the other shoulder blade's, mirrored, at its
  middle. `tests/back_peek.tscn -- <out.png> <id> [clips]` takes a character
  from behind, three-quarters and above in clips.
- **Player A's nose** ("face still look weird around the nose area"; then,
  29 October 17:06, "take the original of that model and put the old head
  on it"): his mesh, UVs and colours were Gary's own all along (the same
  points as his "New Player a.glb", 25 October; the atlas is his colour map
  at 2048); what was missing was its **normal map**, the fine shape painted
  into the light (the bridge and nostrils, the eyelids, the folds in his
  shirt), which `rig_character.py` leaves out. Put back on the rigged model
  with StandardMaterial3D it lit him in patches: on the Compatibility
  renderer (the phone link) Godot 4.7's skinning pass decodes a rigged
  mesh's tangents the other way from how it encoded them, so each island of
  the atlas was lit from a different side (the unskinned mesh was fine; the
  same tangents written into the file came out the same). So a model with
  `<model>_normal.png` beside it wears `assets/shaders/character_nm.gdshader`
  (`Figure3D.dress_normal_map`, also in the portraits): his own colour and
  metal-roughness, and the normal map read through a frame worked out per
  pixel from the screen derivatives of the surface and its UVs (signed by
  the UVs' winding, so the same on GL and on Vulkan/Metal), needing no
  tangents. `tests/nm_check.gd` measures it against StandardMaterial3D on the
  unskinned mesh (a mean difference of 5 in 255, the rigged model the same).
  `tools/add_normal_map.py MODEL.glb <maker's.glb|normal.png>` puts a normal
  map beside a model; `player_a_normal.png` is his, at its own 2048. His
  portrait is re-rendered. (`tools/heal_face.py`, painting over the nose
  from the front, was tried that morning and taken back the same afternoon.)
- **Nell's stick** ("goes through the bench before you sit with her"): sat,
  her stick stands on the ground by her right knee, clear of the seat
  (`Figure3D.plant_stick(foot)`: the hand turned so the stick hangs straight
  from it and the arm bent to put its foot there; `STICKS` has where its foot
  is in her hand's frame); standing lets it go. People sit a few cm forward
  on her bench (`AshfordP1.BENCH_SIT_FWD`: her shawl showed through its back).
- **Getting up off the bench** ("your legs go through the bench as you get
  up"): `AshfordP1.stand_up` brings them up onto their feet where their feet
  were, in front of the seat (`Figure3D.seat_feet_ahead`), the body coming
  forward as they rise; it had straightened the legs up through the seat.
  `tests/bench_shot.tscn -- <dir>` stages Nell and the player on it, and
  checks the player's shins and feet and Nell's stick against it every frame.
- **Nell's face in her duel** ("the image for her is different then her
  model"): the friendly duels named their teacher's stand-in look (Nell's
  `elder` is Old Maren's face, Tam's `farmer` the crowd's); now `nell` and
  `tam`, the portraits rendered from their own models (`DuelTutor._show_box`
  takes a rendered portrait first).
- **The way to Tam's mill** ("It's not clear for players how to get to
  Tam's mill"): Bram says where it is after the Lantern Duel ("Take the lane
  by the signpost, off the east side of the green, and on through the field
  gate"); the objective names it until Tam's been seen (`FESTIVAL_TAM`;
  `EVENING_CORIN` for Corin by the race in the evening); an arrow on the
  screen points the way, at the screen's edge when it's off it and over the
  place when it's on it, with how far (`WorldHUD.set_way`, `WayMarker`; to
  the signpost from the green, to the gate once they're in the lane:
  `AshfordDay.show_way`); a soft pillar of light stands over the gate
  (`AshfordDay._beacon`). Above all, the camera now follows them up the lane:
  it stopped at the green's edge (`CAMERA_X_LIMIT`) and they walked off the
  screen behind a cottage. `Ashford.CAMERA_REACH` lets it follow there and
  turns it to look along the lane between the cottages
  (`World._cam_yaw`, eased; the pad and the keys turn with it, so up is
  always into the screen). `tests/way_shot.tscn -- <dir> [phone]` checks the
  way and takes stills from the game's camera with the HUD up.

`tests/p1_v7_test.tscn` plays P1 New Game to midnight as a player would (taps,
answers, the name, both friendly games, the sunset, the evening; `stop=<words>`
stops once the wait those words describe is reached, e.g. `stop="the street"`
for the attic and the taproom only);
`tests/film_test.tscn -- <dir> midnight` plays on from there to the Thornwood.

The Prologue's first part (P1: Ashford, before midnight) followed Gary's "Master
Script v3" Claude doc word for word (`docs/script/v3_prologue_p1.md` is a copy;
the doc is the master); the parts after it still follow the older "Spoken
Script" until they're rebuilt to v3. The words and talk trees are in
`scripts/world/areas/ashford.gd` (above the films), the staging in
`scripts/world/areas/ashford_p1.gd`.

**The Night of the White Sky** (3 November, Gary: "add that to the story and
build it"; "Bram should face a faceless hunter"): New Game's memory, twenty
years before the attic, in place of the dream's five seconds of stars
(`scripts/story/white_sky.gd`, `WhiteSky`, played by `AshfordP1._attic` while
`AshfordP1.MEMORY` is true). Its own 3D set in a SubViewport of its own (the
Shardlands at night: snow drifts and the crater from `WhiteSky.height()`, the
village's sky shader with its tear opening, dark glass spires, white shards
round the crater's lip, driven snow from `DuelField3D.snow_particles`): the
caption "The Shardlands / Twenty years ago.", Morrowen's `morrowen_attic` over
the sky (moved from the attic; recorded afresh 12 November, 13.5 s with its
soft hall, `docs/handover/2026-11-12.md`), the sky tearing and Sigils falling (streaks,
flashes, cards of light settling in the snow), then the player walks as Bram,
from behind, his face never in a shot (hold to walk, gated, the bracketed
instruction by device), the hunter glimpsed off to the side and gone in a gust,
down into the crater, the child (a wool bundle with SealMark's painting glowing
on it; Gary's `baby_bundle.glb` to come) picked up on a tap, "Hush, now. I've
got you.", tucked into his coat, the hunter on the rim ("Not this one.").
Bram wears a drawn travelling coat over his model (`_dress_bram`, on his
Spine2 bone) until Gary's `bram_coat.glb` is used whole in its place; the
hunter is drawn (`WhiteSky.Hunter`: a ragged ash-coloured cloak, a hood with a
void for a face, smoke off it) until `shard_hunter.glb` comes. **Bram's duel**
is the real duel filmed: `DuelScreen` with `spec.film` (no stage, overlay or
arena overlay; no Circle rule, skills, comeback, events, Oaths or ground god)
and `DuelField3D.film_mode()` (snow for the mat, the torn sky, cold light,
driven snow) with `spectral_side` 1, the hunter's Totems drawn as pale Sigil
light over their own shapes (`DuelField3D.spectral`, a `material_overlay`).
Bram plays as the god's man he was for many years (4 November, Gary: "a very
powerful distinguished player", "high tier cards, nothing low tier"; the god
stays hidden, no patron or Gift in it): the film cuts in with the duel already
joined, on a set board (`spec.puzzle`, as the Trial of Light; `WhiteSkyDuel.board()`).
**Since 5 November his deck is his god's**, Kaethis, the Hand Before (Duel Lab,
"Kaethis"): the Scrivener and the Loomwarden standing from the first frame (no
stacks), Last Stand set, the Unspent Hour, Cut Thread, the Hourglass With No Sand
and the Knotted Cord in hand, and a deck of Already Written, Glyph Warden, the
Weft Serpent, Orlanthe, Doom Sigil, Foreordained, Cut Thread, Counter Rune,
Hushed Counter, the Scrivener, Knotted Cord, Glyph Warden, Foreordained, Null
Sigil (nothing under Crystal among his Totems, nothing under Glimmer at all), six
Essence a turn, every attribute at 10, and the story rule `free_call` (a Crystal
costs him no tribute, `DuelGame.tributes_needed`); the hunter's pack of Hounds and
Foxes already standing and Ascended (`HUNTER_BOARD`), the hunter striking first
with Doom Sigil. The Summon is `WhiteSkyDuel.SUMMON` (`orlanthe`, `SUMMON_AT` 3
cards down; the film, its test and the probe watch the log for
`WhiteSkyDuel.summon_name()`). `tests/white_sky_probe.gd` found seed 13: the
hunter Dooms the Scrivener at once; the Unspent Hour and the Loomwarden break the
Blazehound and the Infernal Warg; the Scrivener and the Unspent Hour fall on the
hunter's third turn; Bram calls the Weft Serpent and the Glyph Warden into the
gaps (so all five of his Totems are seen) and calls down Orlanthe on turn 8
(`FILM_SPEED` 3). The probe's `[pos]` argument now goes into the set board's deck.
Both sides are the computer;
Bram and the hunter stand at the ends of the field, Bram with the child in his
left arm, the play-card clip on each of his plays; the camera cuts between
`WhiteSky.SHOTS` (all on Bram's side of him or looking away from him). When
Orlanthe's blow lands the screen burns white; black; Morrowen: "Twenty years
later, the debt came due." (line 0004 on the voice sheet, recorded 4 November);
then the attic caption, and the player wakes with the mark under
his collar glowing and fading (`SealMark.blaze`). The filmed duel always has a
Skip button; once the memory has been seen (`Game.settings.seen_white_sky`)
all of it has. Its music is Gary's `white_sky` and `white_sky_duel`, its
sounds `assets/sfx/storm_wind` and `baby_cry` (all in since 4 November, below). The
gate at dawn and the clerk counting the crowns are the Reckoning film's shot
`rk_02b`. `tests/white_sky_test.tscn -- <dir> [every s] [skip]` plays it as a
player would and takes stills.

**4 November: Gary's White Sky files, and Bram as a god's champion.** Everything
the memory played a stand-in for is now his: the faceless hunter
(`characters/shard_hunter.glb`, a Tripo3D Mixamo rig with the 22 library clips,
baked and cut like Hale's by `tools/rig_villager.sh shard_hunter`, 2.29 m;
`WhiteSky.Hunter` plays its idle, fades it through
`GeometryInstance3D.transparency` and fans the cards by its hood), Bram in his
heavy coat (`characters/bram_coat.glb`, `rig_villager.sh bram_coat`, 1.84 m
with Bram's lift; `Figure3D.make("bram_coat")` plays the whole memory, so the
drawn coat is never put on him), the child (`ashford/baby_bundle.glb`:
Tripo's 1.95-million-triangle, 8192-pixel bundle slimmed to 30,000 and 2048 by
`tools/slim_glb.py` and laid along z face up; the mark is painted on the
blanket over its heart as it was on the drawn one), the storm and the crying
(`assets/sfx/storm_wind.ogg`, 41 s, and `baby_cry.ogg`, both looped without a
join by `tools/sfx_loop.py`, the recordings kept in `assets/audio/source/sfx/`)
and Morrowen's line 0004 (`vo/ashford/morrowen/6ec01c26.ogg`, mastered by
`vo_master.py --lines`). His one piece of music is cut in two (Music loops,
below): `white_sky` for the walk and `white_sky_duel` for the duel, which the
duel's spec names first and which stops dead with the white (`Music.stop(0.12)`
as the white lands; `Music.FROM_START` makes both begin from their start every
time the memory plays). Bram's deck in the duel is the champion's set board
of the same night (the paragraph above: Cragmaul and the Ironclad Behemoth
standing from the first frame, every card Crystal tier or above, no tribute
for his calls; built in Gary's other chat and merged here). Bram's own model
keeps its painted-open eyes (Gary, 4 November: "the one we have at the moment
seems to be alright with the painted eyes"), so no new Bram is waited for.

**4 November, later: Gary's play-through notes on the memory.** Six of his
notes were about it, and it plays differently now. *He walks about freely
from the first moment*, while Morrowen speaks over him (Gary: "have him able
to walk around as Morrowen is talking"): the pad (a drag is a joystick, a
tap on the snow walks there, `WhiteSky._tap_snow` marching the tap's ray
down onto the snow), the keys or a stick, the way the camera looks being up
(`_roam_step`), kept out of the glass spires and within `ROAM_R` of the
crater, the camera easing round behind him as he turns (`_cam_mode` "roam")
and his feet matched to the ground (`Figure3D.pace`: until then the clip
ran at its own 1.62 m/s over a 1.25 m/s walk, and "Bram walks very weird").
Her line ends on its own or a tap; then the sky tears over him as he walks
on (5 November: he used to be stopped for it, and "Why does Bram pause after
Morrowen finishes talking?"; the camera lifts its eyes to the tear and comes
back), and *an arrow comes up in the bottom left corner* pointing the way
to the light ("The light · 27 m"; `WorldHUD.Compass`, one big gold arrow
since 5 November that turns to its `target` as the camera turns, made for
the world to use as the map later, as Gary asked), gone at the crater's lip
(`RIM_AT`). The hunter is glimpsed ahead and to his left on the way
(`GLIMPSE_AT`). *The Shardlands look like a storm*: the spires come in close
about his way now, from shards no taller than a man to spires of 22 m, in a
glass shader of their own (`GLASS`: near black, the sky's cold light along
their edges, a faint light moving inside, frost caught on their upper faces),
with small shards about their feet; sheets of snow blown low along the
ground in the wind (`_build_storm`: streaks aligned with their flight) and
big soft flakes close to the camera over the snowfall; the snow's own shape
in the light (the ground shader works a normal out of its drifts and the
wind's ripples) and the fog thinned (0.034 to 0.026) so the spires are seen
at all. *The Sigils on the ground are cards*, not confetti: a little bigger
than a hand, each stands tilted in the snow where it lands with a pool of
its light under it (`_card_lands`), the oldest going when there are more
than `[18, 30, 44]` by quality. *The child is seen from the rim*: on the lip
the camera holds over his shoulder for two seconds on the bowl, the bundle
at the bottom in a beacon of light with sparks rising off it
(`_child_beacon`), then comes down the slope with him keeping the child in
the middle of the picture (his walk and the camera's drift on the same
frame clock). *He picks the child up*: on the tap he goes down on one knee
over it (`Figure3D.kneel`: the right knee to the ground, the shin along it,
the left foot planted ahead, the back bent over it; a clip built from the
idle as the seated ones are), his hands go under it (`reach`), and it rises
with his hands into his arms as he stands (`rise`, the bundle carried in his
own frame from then on), the beacon gone and the crying fading. The test
drives him with the up key now (`white_sky_test`, `ashford_test`);
`tests/kneel_peek.gd -- <dir> [model]` shows the kneel and the lift on a
plain stage.

Before the memory (and with `AshfordP1.MEMORY` false) New Game opened on black and the caption "Ashford / The last night of the Age."
in the inn's attic, then the dream the player is about to tell Bram about
(`CineOverlay.dream_sky()`, `AshfordP1.DREAM_SECS`, 0 turns it off): the night
sky as it's seen from the bed through the attic window, full of stars with a
thin moon, held about two seconds, then an even fade to white over about 2.5 s
and a beat of pure white (the Sigilfall, before it happens; since 22 October:
the front of white that rose from the bottom read as black going white on a
phone), cut to black on the drum. Since 28 October Morrowen speaks over it
(Gary: "the speech at the beginning of the game happen while we see the sky
and it turning white"; it had been spoken once he was out of bed): the sky
comes up (`CineOverlay.dream_begin`), her recording plays with her words as
a subtitle over the stars (`AshfordP1._dream`, the line `ATTIC`), the white
starts coming over the sky `DREAM_WHITE` seconds before she finishes so it's
full white as her last words end (`CineOverlay.dream_whiten`), a beat of
white (`DREAM_HOLD`), then black; a tap skips her and the white comes at
once, and without her recording the line waits for a tap with the sky held
under it. The player
wakes in the bed (since 22 October an oak frame with
turned posts, a slatted headboard and a footboard, a straw mattress in striped
ticking that sags where a body lies, a plump pillow with a head's dent in it
and a rumpled wool blanket with its hem turned back, `InnRooms._bed()`; the
sleeper lies and sits up in the mattress's dip, `lie_top`, and sits on its edge
at the edge's height, `edge_top`; Gary's own model takes its place from
`assets/models/ashford/bed.glb` or `attic_bed.glb` when it exists), lying on top of the
mattress with his head up on the pillow (`Figure3D.lie_on()`: the body tipped
up a little at the head end, `LIE_HEAD_UP`, the feet lolling, `LIE_FOOT_DROP`),
puts a hand down on the mattress and pushes himself up on it, slowly, the
blanket sliding back, swings his legs over the side and turns to sit on the
edge, sits a moment and stands (`sit_long()`, `sit()` with `shift_seat()`,
`stand()`, and `reach()` for the hand: poses built on the model's own idle,
blended one into the next; `tests/bed_check.tscn` takes stills of it from the
side and the foot of the bed), goes to the cracked mirror and chooses their
look (`scripts/ui/mirror_picker.gd`: since 22 October a tap on a face puts
that look in the glass, the real model in front of the mirror with the camera
looking back at it from the glass, and "That's me." keeps it; left and right
show each look with the keys or a pad and Enter / E / Space / A keeps the one
in the glass; four looks since 20 October, A Gary's first
young man, B his second, C the young woman in green, D the bearded man;
`assets/models/characters/player_<letter>.glb`, `tools/rig_player.sh`, and
the look chosen is the `look` flag, which `Figure3D.model_file("player")`
and `DollArt.portrait("player")` read, so the player and their dialogue
face are that look from then on; a look whose model isn't there yet would
show as coming soon). In the taproom Bram is
stacking paper lanterns into a crate from the pile on the table beside it
(while he talks he wipes the counter, his right hand in front of his right
shoulder on its near edge, `AshfordP1.WIPE_AT` in his own frame; until 28
October it worked half a metre ahead and well to his left, out of the right
arm's reach, so the arm ran across his chest, twisted, and the hand went
through the counter: "his arm twists in a weird way ... and his hand passed
through the bar"), his hand turned flat on the oak (`Figure3D.palm(side,
dir)`: a `HandTurn` modifier after the arms' IK turns the hand so its palm
faces `dir`, the fingers on along the forearm; the IK alone leaves the hand
turned as the clip has it, and his talking clip held it palm up)
(seen from the player's side of the room, so every lantern is seen taken
from the pile: 23 October), the shelves behind the bar bare; he hands
the crate over, the player carries it out of the inn and across to the green
with Bram following (indoors he walks round the table and the stools, as the
player must; the stairs are solid, and anyone carrying the crate back towards
them is stopped, turned back a step and told "Wrong way, Sprout. The green's
out the door, not up the stairs.": `stairs_zone` in `InnRooms.eve()`,
`AshfordP1.walk_room()`), and hangs the last lantern on the Great Lantern's top
hook with its hoist. (The inn's rooms had drifting dust motes until 20 October;
on a phone they read as little lights floating about, so they're gone.)

New Game's Ashford is built before it's needed: the moment the title screen is
up, `Main._prepare_new_game()` builds it underneath, a piece a frame
(`World.prepare()`, `AshfordVillage.build_spread()`), builds the attic and the
taproom and shows the attic's first shot to the camera so their shaders
compile there (`Ashford.warm()`), then hides it and stops it. New Game plays
the movie over it and `World.release()` starts the story the moment the movie
ends or is skipped; Continue or the Duel Lab throw it away and put the game
state back. `tests/start_time_probe.tscn` times the whole thing, title to
attic. The movie's own loading (its pack, on the web) is as it was. Bram teaches
walking, stopping, using and talking in his own words while the Objective line
names the button for the device in hand (`scripts/ui/world_coach.gd`: phone,
tablet, computer or controller, and it changes if a pad or a keyboard is picked
up; an instruction in brackets inside a spoken line, Bram's "(Tap the three
lines at the top right of the screen to open the menu.)" from `{menu}`, is
drawn in the Objective's gold italics so it reads as the game's note, not the
speaker's words: `DialogueBox.mark_instructions`), and every step is gated: the pause square only appears when he mentions
stopping, a thing to use lights up and only it answers (`AshfordP1.use`), and
until the player has talked to Tam nobody but Tam and Bram answers. The attic and
the taproom are built below the village (`attic()` and `eve()` in
`scripts/world/inn_rooms.gd`), with the real village seen through the attic window
and the taproom door. The opening's progress is saved in the flag `p1_stage`, so
a game closed during it picks up at the start of the part it was in; older saves
past the arrival skip it. (The flight over Ashford that New Game used to open
with is gone: v3 cuts from the movie's title to black and the attic, and the
village is seen as the player steps out of the inn.)

On the green: Tam's barrel and the letter from Ironvault he can't read (read on
screen, `scripts/ui/letter_view.gd`; whether the player tells him it says tonight
is kept as `tam_told`), Nell on her bench by the well (the player sits with her),
Tilly running up with her Lantern Moth (it circles the player and settles on the
back of their hand), Ned the fiddler, Hob, dancers and children with paper
lanterns, and Corin, whose mam (extra `corin_mam`) watches from the bakery door.
Corin calls out when the player comes near; Bram gets up off his stool with the
card box and hands over the first deck when Corin says there isn't one. (Bram on
his stool, Nell on her bench and the player beside her sit with
`Figure3D.sit()`, through `AshfordP1.sit_down`.) Every staged camera
on the green is checked for anything solid or anyone standing in the way
(`AshfordP1.clear_cam`). The
Lantern Duel has Corin's own rule, Showboat: his Cinderpup attacks the moment it
can, whatever's in its way (`story_rules` in `DuelGame`, `_rule_showboat`; named
as the duel starts from `spec.rule`), and his barks are tied to its moments
(`spec.bark_on`). It can't be lost: coached by Bram it's gated step by step; if
the player says they've watched enough duels, Corin still plays his script and
Bram keeps quiet (`tutorial = {"quiet": true}`). Then, uncoached, Corin offers a
rematch that can be lost (shuffled, a roll for who goes first, no floor, and the
result stands: `spec.once`; flag `lantern_rematch` = "won" or "lost"), and the
loser carries the drum. Tilly runs over with her moth, which passes into the
player's hands on her words "You keep it", and midnight begins. A dialogue line
can play a scene while it's up: `{"say": ..., "during": "<scene>", "at":
"<words>"}` starts the scene as the line types out as far as those words.

Bram, Corin, Tam, Tilly, Old Nell, Hob and the player are their 3D models
everywhere (`scripts/world/figure_3d.gd`; Tam and Tilly since 16 October,
Nell since 18 October (her new look, the Cast tab's Nell Hayes, since 25
October), Hob since 19 October, and Bram Gary's own AssetFurnace
model, in place of the 11 October stand-in, since 20 October); the crowd's farmer,
merchant and trader are Gary's 22 October models (`farmer.glb`, `merchant.glb`,
`trader.glb`: the Lantern Night crowd and the P1 dancers with those looks are
3D figures); the elder and the two children are his 23 October models
(`elder.glb`, `child_b.glb`, `child_c.glb`: Old Nell's and Old Maren's look,
the children of the green, the Lantern Night and Solhaven's gate; the third
child look, `child`, the blonde cut-out that was Pip's and the third child's on
the green, plays the boy's model too, `Figure3D.MODELS`, until Pip's own comes);
the other villagers (Ned, the refugee, the courtier) stay cut-outs until their
models exist, and a model dropped into `assets/models/characters/<id>.glb` is picked
up by itself. A cut-out always
shows the camera its painted front, turned left or right (its back picture
read as a blank white card in a film), and kneels by crouching onto its feet
rather than sinking into the ground. The models share
one skeleton's bone names, so a clip one lacks is borrowed from another and
fitted to their height (Tilly is a child, Nell small and stooped);
`reach()` puts hands on things: Tam and the player carry the barrel by its
ends, Tilly holds her moth's card out in both hands, Corin leads her up the
lane by the hand and holds it on the riverbank, Tam levels his pitchfork.
`sit(height)` sits someone on a bench that high where they stand (Nell on
hers, the player beside her): hips on the seat, thighs along it, feet on
the ground (Tilly's swing); whatever they do sitting (talking, a wave, a
held pose) stays sitting until `stand()` or they walk off.

The player (look A) is Gary's young man: since 26 October his new look from
the Cast tab (about 20, lean, freckles, a scar through his left eyebrow,
wavy dark brown hair, cream shirt and moss-green waistcoat), a Tripo3D model
(`New_Player_A_Master_22_Animations.glb`) whose own rig couldn't be used (its
skeleton stood turned 90 degrees to the mesh, so every clip mangled him):
`tools/reskin.py` put the new mesh onto the game's skeleton instead, fitted
from his 17 October model's, with fresh bone-distance weights, and
`rig_character.py` then gave him every clip of the model he replaced (the
AssetFurnace 21, the game's and Bram's lift) and a `get_out_of_bed` clip
fitted from Hob's new model (played in the attic since 27 October). Bram was
remade the same way the same day (Gary's `Bram_new_model.glb`, a Tripo3D
model with no skin weights at all), with his 20 October model's clips. The
bone-distance weights deformed them both (Gary, 27 October: the main
character "looks deformed", his face in the mirror and the text box; Bram's
"arm is passing through his body"), so both now carry weights copied from
the models they replaced (`tools/reweight.py CUR.glb REF.glb OUT.glb
--refit-joints`: each vertex takes the weights of the nearest flesh of the
old model's same bone, and the joints are fitted again from them; the old
models are in git, `9ee55f7~1`), Bram's apron is freed from his arms
(`tools/free_arms.py MODEL.glb "0.263,0.15,0.092:0.16"`, the leather's
colour, as `rig_character.py --free-of-arms` does: it had flapped after his
hands), and his eyes, which the model has painted shut, are painted open
(`tools/paint_eyes.py`, drawn front-on and projected into the texture; a
remade Bram with his eyes open is the real fix). Their portraits are
re-rendered. **Player A's head** (28 October, Gary: "Player A's face still
looks deformed, it's not like the model I gave you"): his clips are the ones
made for the AssetFurnace faces, which are sculpted looking down about 12
degrees at rest, so the clips lift the head (`--head-up 10` in
`rig_player.sh`, and the walk tips it back itself); his Tripo3D face is level
at rest, so in every clip his chin was up, his neck stretched long under it
and his face seen from below, in the mirror and the text box most of all.
`tools/head_level.py MODEL DEG` turns every clip's neck and head by DEG
(two fifths and three fifths, as `--head-up`); Player A has -11 (all but
`get_out_of_bed`, which leaves the head at rest). `tests/head_peek.gd -- <dir>
<ids> [clips]` takes the head from the side and the front, at rest and in
clips, for comparing models (`player_a,player_b`). His portrait is
re-rendered. From 17 to 25 October look A was
his AssetFurnace master with 21 motion-captured clips. `tools/rig_character.py` turns a rigged
AssetFurnace model into a game character: the shared skeleton's bone names
(AssetFurnace numbers them), every bone's rest square to the world, a set
height (the player stands 1.76 m), walking clips cut to one step cycle that
stays on the spot (their natural pace goes in `Figure3D.OWN_GAIT`), the
game's other clips fitted to his body from `characters/clips/shared.glb`
(the first player model's clips, which everyone else still borrows) and
Bram's lift, and the textures beside the model. AssetFurnace's normal map
splits the face into a light and a dark half, so it's left out. To rebuild
him from Gary's master file:

```sh
tools/rig_player_a.sh <Player_B_Master_21_Animations.glb>        # an AssetFurnace master with its clips
python3 tools/reskin.py <tripo_model.glb> assets/models/characters/player_a.glb /tmp/pa.glb --height 1.76   # a model whose rig is no good: the mesh onto the game's skeleton
python3 tools/rig_character.py /tmp/pa.glb assets/models/characters/player_a.glb --name "Player A" --height 1.76 \
    --borrow "assets/models/characters/player_a.glb:<every clip of the old model>" --borrow <hob_new.glb>:get_out_of_bed
godot --headless --import
xvfb-run -a -s "-screen 0 1024x1024x24" godot --rendering-driver opengl3 --resolution 1024x1024 res://tools/render_portraits.tscn -- player
godot --headless --script res://tests/clips_check.gd          # everyone can play every clip the story uses, and sit
python3 tools/arm_weights.py assets/models/characters/player_d.glb [--fix]   # cloth skinned to a hand or finger (it rises with the hand); --fix walks it back onto the body
xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 960x540 \
    res://tests/carry_check.tscn -- /tmp/carry [a,b,c,d]        # every look carrying the lantern crate, side and front
xvfb-run -a -s "-screen 0 800x800x24" godot --rendering-driver opengl3 --resolution 640x640 \
    --script res://tests/model_sheet.gd -- /tmp/sheet player_a  # the model by the cast, in every clip, the cast on a bench
```

His own clips besides the game's: sneak, strafe_left, jump, sit,
fight_stance, punch, punch_combo, kick, roundhouse, flying_kick,
sword_swing, kata, hit_react, death, dance, wave and roll (the roll, the
flying kick, the punch combo, the strafe and the death travel as made, so
whoever plays one moves the figure to where it ends). The `sit` clips
(everyone's) sit down on the ground; a bench is `Figure3D.sit()`.

Looks B, C and D are Gary's 20 October masters (`Player_B_New_21_Animations.glb`,
`Player_C_Master_21_Animations.glb`, `Player_D_Master_21_Animations.glb`, the
same 21 clips as look A's, retargeted from a library), built by
`tools/rig_player.sh b|c|d <master.glb>` the way look A is: B stands 1.76 m
(52 joints), C 1.68 m (40 joints, three fingers a hand), D 1.82 m (52 joints).
`Figure3D.OWN_GAIT` has their paces.

Corin, Tam and Tilly are Gary's 18 October AssetFurnace models (Old Nell was
too, until her 25 October one, below),
Hob his 26 October one (`Hob_new_model.glb`, his new look: South Asian,
broad and bald, a red neckerchief; a 34-joint rig with 22 library clips,
`rig_villager.sh hob`), Ned the fiddler his 26 October one too (sent as
`Hob_3d_model.glb`: a 52-joint rig with one clip, his idle; the rest fitted
from the player and the shared clips, `rig_villager.sh ned`; `ned.glb`, where
the cut-out "fiddler" stood), Bram his 26 October Tripo3D one (above) and the crowd's farmer,
merchant and trader his 22 October ones (21 clips each, the farmer and the
trader 52-joint rigs with Player B's clips retargeted, the merchant a 34-joint
rig on Tam's library; farmer 1.78 m, merchant 1.72 m, trader 1.80 m; their
paces in `OWN_GAIT`), and the elder and the children are his 23 October ones
(New Characters 04, 05 and 06, 52-joint rigs with the player's 21 clips; the
masters come 0.9 m tall whatever the figure, so `rig_villager.sh` sets them:
the elder 1.62 m, the boy 1.34 m, the girl 1.30 m, a child of ten or so where
Tilly, at 1.25 m, is seven), built the same way by
`tools/rig_villager.sh <who> <master.glb>` (then the import, their portrait
and the checks above, with their id): Corin stands 1.72 m, Tam 1.88 m, Tilly
1.25 m, Nell 1.50 m, Bram 1.84 m (his own idle, walk, run, strafe, jump, roll,
sit, wave, dance and fighting clips; his lift, which everyone borrows, and his
cheer came over from the stand-in, `git show 3c521d9:assets/models/characters/bram.glb`)
and Hob 1.80 m (his own idle, walk, run, jump, sit, wave,
cheer and death). Corin's own walk, run, sit and wave came on 20 October as
single-clip AssetFurnace files (one clip each, the same rig, no idle among
them): `rig_villager.sh corin <folder>` takes the walk file as his body and
his idle, jump, cheer, dance, punch, death and fighting clips from the 18
October model (`git show 0afe166:assets/models/characters/corin.glb`). Each
keeps its own clips besides the game's: Corin cheer, dance, death,
fight_stance, flying_kick, hit_react, jump, kata, kick, punch and punch_combo;
Tam and Tilly jump,
sit, wave, cheer, dance, kick, punch and death. Their rigs are smaller than
the player's: Tam's hands are a thumb and the fingers as one, Tilly's a thumb
and two groups. **Old Nell** is Gary's 25 October model (`Nell_model.glb`,
her new look from the Cast tab: Nell Hayes, the faded blue headscarf, the
cream knitted shawl, the plum dress, the carved stick in her right hand; it
replaced his 18 October one, `git show 9cd9cdc:assets/models/characters/nell.glb`):
a 21-joint rig with no fingers, 0.9 m tall as made and set to 1.50 m, with 22
clips retargeted from a library (the player's 21 and a `get_out_of_bed`).
Her walking stick is part of her mesh, in her right hand; the library's
clips hang that hand loose at her side, which would point the stick back
through her skirt, so that arm stays as it is in her rest pose (hand on the
stick) in her idle, walk, run, talk, cheer, dance, look_up and duel clips
(`--hold-arm Right:rest:...`); her wave lifts the stick (it reads as her
waving it) and her fall takes it down with her. The stick itself is bound to
her right hand alone (`tools/stick_weights.py`, 23 October: AssetFurnace
ties a stick's top to the fingers and its foot to the toes, and it bent as
she danced), so she pats the bench with her left hand. Tilly's leather satchel hangs by her left hand, so
AssetFurnace bound part of it (and of its strap over her right shoulder) to
her arms, and it stretched after her hand when she held her card out:
`--free-of-arms R,G,B:TOL` gives the big patches of the leather's colour the
body's weights instead (a few shaded spots of skin of about that colour on a
forearm stay with the arm), and leaves out the few triangles that fused her
hand to the bag where it rests on it (a triangle that's all arm at one corner
and no arm at another). AssetFurnace's walk and run tip the head back, so
it's levelled for the four of them. Tam's master file was 47 MB because it
carried every source file's mesh and textures, unused; his game model, like
the others, has only what it uses (about 2.5 MB, with a 2048 colour atlas).

**Corin's mam, Huntmaster Krell and the refugee woman** are Gary's 27 October
models (`Cornis_mam.glb`, `Huntmaster_Krel.glb` and
`Travel_Worn_Woman_Master_21_Animations.glb`: 52-joint rigs with the 21 clips,
the first two with a `get_out_of_bed` too), built by `tools/rig_villager.sh
corin_mam|krell|refugee <master.glb>` like the elder's: Corin's mam 1.66 m (an
older woman, silver hair, the blue dress and green bodice; at the bakery door
on the green and on the riverbank), Krell 1.80 m (Ironvault's huntmaster, black
leather and its key; the Reckoning and the Solhaven film) and the refugee 1.64
m (the travel-worn woman: Solhaven's gate and square; Corin's mam stood in her
look until her own came). Their paces are in `Figure3D.OWN_GAIT`;
`tests/clips_check.gd` checks them; `tests/new_cast_shot.tscn` takes Corin's
mam at her door (`-- <dir> krell`: Krell on the green at dusk, from the
Reckoning's camera), `tests/new_cast_solhaven.tscn -- <dir>` the refugee and
Krell at Solhaven's gate. Their dialogue portraits stay the painted ones from Gary's
sheets (Corin's mam doesn't speak; hers from his sheet shows the red-haired
look the Cast tab first had).

Everything after the Lantern Duel is a film in the game's own 3D, line for line
from Master Script v3 (a copy is in `docs/script/v3_prologue_films.md`): midnight,
the Sigilfall, the run, the cart, the white light, the Pale Herald at dawn (its
lantern shows the Champions it doesn't read out), the taproom, Ashford burning
(Krell's terms, Tam's lie), the cellar and the tunnel (`ashford.gd`, parts saved
in the `pro_part` flag so a closed game picks up where it was), then the
Thornwood (`scripts/world/areas/thornwood.gd` on `scripts/world/thornwood_set.gd`):
the riverbank, the campfire (Bram's four decks on a log, tap a box to see it and
again to choose, `scripts/world/deck_boxes.gd`, then his walk round the deck
screen, `PackTour.CAMP_DECK`, which since 23 October also explains the two bars under a card, Resonance towards a second copy and Attunement towards its Ascension, and what a spare copy is for), Bram's duel by the fire straight after it (23 October, Gary: "he should do a duel with you and teach you more"; the practice round, moved from the second morning and no longer offered: he puts the other three boxes away and keeps out the deck that shows the player's its weakness by the element chart, `Prologue.BRAM_PICKS`, says why, and plays it at `Prologue.BRAM_STRENGTH`; it can be lost and the night goes on either way; closed mid-duel the game comes straight back into it, `practice_on`; the second gated lesson duel, `spec.lessons`, teaching once each the tiers, Rites, Shift and the Fate bands as well as conditions, Wards, Guardians, Gifts, Summons and Ascension; `tests/fire_sim.tscn` plays a learner against him for balance), the second morning (one caption and one line until the walk out of the Thornwood is staged: its words are in `docs/script/v3_prologue_films.md` for Gary to read first), Dask's
road duel and dawn over Solhaven. A staged walk (`Cine.path`, `Cine.walk`) goes round whatever solid and small stands in its straight line (23 October: the player and Bram walked straight through Nell's bench on the way to the Lantern, and Tilly ran through it after the duel): the set's static bodies (every `solid_box` and `solid_round`: the bench, the well, a stool, a barrel, the Lantern's foot, a cart; not houses, walls or fences, and never people) are read as circles on the ground (`Cine.blockers`, cached a second at a time), and a leg that crosses one is replaced by the shortest way through the points round each thing in the way over legs that cross nothing (`Cine.route`; the bench against the well is passed by the bench's far end, not squeezed between). A walk that starts or ends on a thing (sitting down on the bench, standing up from it) ignores it. Since 28 October (Gary: "Bram outside walks through the bench again") a long thing (a bench, a cart) is a row of circles along it rather than one round its whole length, so a walk from a stride off its end is no longer taken as starting on it (that one circle reached a metre past the bench's ends); and what stands along the inn's front, part of Gary's one-mesh inn (the bench under the bay window, the crates and barrels by the door), is solid on its own (`AshfordVillage.INN_FRONT_PROPS`, in the model's own x/z): the inn's own box takes in its whole front and is too big a thing to walk round, so Bram following the player out of the door cut through the bench. Bram following the player on foot slides round them too (`AshfordP1._round_props`). `godot --headless res://tests/route_test.tscn` checks walks across the green (since 28 October also with someone standing in the gap the way round the bench takes, the real `_green` scene with the morning's crowd from five ways onto the green, and Bram following the player along the inn's front both ways). `tests/p1_v7_test` checks every frame that nobody standing walks through anything solid and small (by its real shape; sitting down on it and standing up off it don't count). Since the afternoon of 23 October a walk named for its walker (every `Cine.path`) goes round the people standing about as well (`Cine.people`: the player, the villagers and the extras, a body's width each; a walk still ends on its mark whoever stands beside it; the way to each point is found as that leg starts), Bram leaves for the Lantern a beat after the player and swings wide on his own side (Gary: "Bram walks straight through the player"), and Bram following the player on foot steps back when walked into (`AshfordP1.FOLLOW_SPACE`). **Every line waits for a tap** (Gary, 23 October: "all text you need to have to click"): a subtitle and a narration line stay up until E, Space, Enter, a pad's A or a tap (`CineOverlay.auto` is false; the "TAP ▸" hint after a moment, in words since 25 October: a lone arrow wasn't understood); only a line with a voice recording playing (`Cine.say(..., hold, timed)`: the Herald's, Solmaris's, Morne's, `films.gd _voice`) and a story film's subtitles and cards over its picture keep their timing, and a tap skips those. **A title card** ("Ashford / The last night of the Age.", "Dawn") is the exception since 25 October (Gary: it "stays on till you click but nobody would know they are supposed to click"): it holds its seconds once it's faded in, then goes on by itself, and a tap goes on sooner (`CineOverlay.caption`). Every test that plays through lines taps them (`ov._waiting` then `ov._next.emit()`, as the film tests do). **Getting out of bed** (`AshfordP1._attic`; since 25 October about seven seconds from the fade-up to standing, where it was twelve: Gary, "a little bit faster"): the sleeper's right hand takes the blanket's hem and throws it back across him to the wall, the cloth following the hand (`BlanketThrow`: the blanket keeps its grid of points, the near edge moving first and the far edge last, the corner on the hand), then pushes up on the mattress; he slides to the bed's edge with his legs still out along the mattress and swings them down only once he's over the edge (`Figure3D.shift_seat` then `sit`), so nothing goes through the bed; `tests/bed_check.tscn` takes its stills. Since 27 October (Gary: "weird getting out of bed") he gets up with the real clip instead, Hob's `get_out_of_bed` (lying, sits up, legs over the side, sits, stands), mirrored so it's the open side of the bed, its root motion given to the body that carries him so he ends where it ends (`Figure3D.play_rooted`, `AshfordP1._rise_from_bed`: lifted onto this taller bed while he lies, slid to its edge as his legs come round); the pose-built rise is kept for a model without the clip (`_rise_by_poses`). Player A's copy of the clip had its root motion 7.6 times too big (he lay three metres under the attic): `tools/fix_clip_root.py` takes it from the clip's own source. **Bram's card box** is held in both hands in front of his chest and passed into the player's (`Ashford._hold_box`, `_box_out`, `_card_box`). Since 27 October it's Gary's `assets/models/ashford/card_box.glb` (a worn oak box with brass corners and clasp and the sigil on its lid, made with its lid on a hinge, `Hinged_Oak_Lid`, opening -105 degrees about its X): sized by its width, the lid named "Lid" so `open_box_lid` swings it, and the Spark deck laid inside; `tests/box_peek.gd` takes it shut and open. Since 27 October (Gary: it "still looks not very good when he hands it to you") the built one is a small oak case with brass at its rim and corners, a clasp, the sigil on its lid and the Spark deck inside (`tests/box_peek.gd` takes stills); it comes up out of his apron pocket into his hands, crosses to the player's on a little rise turning as it goes (it slid across and spun round at the end), and its lid opens (`open_box_lid`) before the deck fans out. Since 25 October the hand-over is its own beat (Gary): Bram says "You do now.", his hand comes off the player's shoulder and the box comes out held in both hands (scene `box_out`), he says Gary's line ("I've always told you, when you were ready, I'd let you start using cards..."), the player reaches out and takes it and the Spark deck fans out (scene `first_deck`), and only then "You've seen enough duels to know how it works..." and his offer to coach. A box given to someone already holding one replaces it (`_clear_boxes`; until then the first stayed floating at his chest while he handed over another: "it duplicates"). Since 28 October (Gary: "Bram's card box is just floating, it's not in his hands, and the player's hand is deformed when he reached to take it") it's held where each one's arms reach: `Figure3D.hold_point()`, a little under the shoulders and about half an arm ahead, from the model's own shoulder height and arm length (`_box_hold`; the fixed `BOX_HOLD` at a grown-up's waist was a hand's length beyond Bram's short arms, and held out 0.2 m further it floated a quarter of a metre clear of his hands), held out a little (`BOX_OUT`); Bram stops beside the player, facing Corin as they do (`BRAM_BESIDE`, 0.8 m; he had stood 1.5 m off and turned to them, his arm stretched out at nothing), his near hand on their near shoulder (`_shoulder_point`'s `from`), and they turn to each other for the box; the player steps in to `BOX_GIVE_GAP` (0.64 m) and takes it (`_step_to_take`), within reach. The box is a little bigger (`CARD_BOX_SIZE` 0.16 m wide) so it reads in the hands. `tests/hands_shot.tscn -- <dir> wipe|box [look]` stages Bram wiping the counter and the box hand-over for real, takes stills from the scene's camera and a close one, and checks each reaching hand is at what it holds. **The Sigilfall's falls** ease in over a longer blend (`act("fall", 1.0, 0.4)`, Tam's `death` 0.35), and a camera shake comes in over a few frames rather than in the frame it's asked for (`World.shake`), so a strike's burst, flash and fall no longer land in one frame. **Tilly's gift** crosses on an eased arc with the player's hands coming up to meet it, and the deck reveal has a soft breathing glow behind it instead of turning rays. **Corin's back** had a patch of triangles mapped onto the shirt and the skin of the atlas, seen as a hole from behind: `tools/mend_winding.py` turns a model's inside-out triangles round (every character had some; `rig_character.py` runs it on each new rig) and `tools/mend_corin_back.py` maps that patch onto the vest; a faint mark remains until his model is remade. **A film's look** (23 October, Gary: the cutscenes "don't look very good yet"; the first of the look pass, and the parts that run on every renderer): every shot a film takes (`Cine.shot`, `move`, `drift`) sets a soft warm key light beside the camera on whoever it looks at (`Cine.light_shot`, `FILL_NIGHT` 0.55 in Ashford's nights, `FILL_DAY` 0.25 elsewhere), so faces read in the dark instead of flattening into the moonlight; a close shot (fov 40 or tighter) gets depth of field focused on its subject, on a phone too (the walkable world leaves it off there for its frame rate); the movie bars bring a vignette with them (`CineOverlay.VIGNETTE`); both go when the film ends (`Cine.end_light`). The sky's tear at the Sigilfall opens into a rift as it tears (`tear_open` widens the crack and spills its colours below it, `sky.gdshader`), and the rift lights the village from above as it opens (`tear_light`). The stand-in cut-outs (`PaperDoll`, the children, Ned, the elder, the refugee until their models come) are lit by the scene like the figures beside them (`shaded`) and have lost their white sticker border. What's still to do for these two films is the look pass proper (baked lighting, normal and roughness maps, animation blending) and, above all, Gary's models for the children, Ned, the elder and the refugee woman, who are cartoon stand-ins in a painted scene (the refugee woman's came on 27 October, with Krell's and Corin's mam's). Films are staged with `scripts/world/cine.gd` (shots, walks, spawns, reveals,
and `Cine.ask` for a film's questions that can all be asked, as a
conversation's `{"ask": ...}` step can) and `scripts/world/cine_overlay.gd` (letterbox,
subtitles, choices, the name prompt). The Herald's voice plays from
`assets/audio/vo/herald_NN.ogg` (01, 02, 03, 09, 10, 12, 13, Gary's recordings
since 20 October, and 21 and 22, "The Age is turned..." and "The Covenant
updates...", since 27 October, mastered by `tools/vo_master.py --lines` from
his WAVs named by their sheet numbers, 0152 and 0155, the WAVs kept as FLAC in
`assets/audio/source/vo/`; .wav or .mp3 work too; a story film's voice waits
for the one before it to finish, `StoryFilm._say`, so herald_21, a second
longer than its shot, isn't cut off by herald_03) and the Champions' faces from
`assets/art/champions/<id>.png` or `.jpg` (aldric, vorn, eiran, rook, silk,
maelis, crane; all seven are Gary's paintings: Vorn, Eiran and Rook since
20 October, Silk, Maelis and Crane since that night, Aldric since 22 October)
once they exist; until then the lines are subtitles and each face is its
Seat's sign.

**Voices** (Gary, 23 October: "what if we used actual voices instead of just
text? Then people wouldn't have to click through unless they wanted to
skip"): every line the game speaks can have a recording, found by the line's
id (`VoiceLines`, `scripts/story/voice_lines.gd`: the first eight hex digits
of the sha1 of the words as written in the script, before `{name}` is filled
in) at `assets/audio/vo/<area>/<speaker>/<id>.ogg` (ashford, thornwood or
solhaven; a film's stand-in such as `film_wren` uses the person's folder,
`VoiceLines.PERSON`). A film's subtitle (`Cine.say`), a conversation step
(`World.run_steps`, `DialogueBox.say`), a side story's line
(`SolhavenSide._say`) and a story film's line (`StoryFilm._say`) all look one
up: with a recording the line plays it, holds for its length and a breath
(`VoiceLines.TAIL`) and moves on by itself, a tap skipping it; without one it
waits for a tap as before. The Herald's, Solmaris's and Morne's named
recordings (`"vo": "herald_01"`, `films.gd _voice`) stay as they are.
`tools/vo_sheet.py` writes every line in play order, numbered, with its
speaker and id, to `docs/script/vo_lines.md` (the sheet to read from) and
`.csv` (the tools' key): 483 lines, 29 of them recorded already; `python3
tools/vo_master.py --lines <folder>` takes recordings named by sheet number
or id, levels each and puts it in place; then `godot --headless --import`.
On the web, Ashford's and Thornwood's voices come as a `voices` pack fetched
quietly as the world starts (`Packs.want`, `VoiceLines.warm`; the main pack
is near GitHub's 100 MB) and Solhaven's ride in Solhaven's pack
(`tools/web_packs.py`, which now adds a preset for a pack that has none).
`godot --headless res://tests/voice_lines_test.tscn` checks the ids and the
holds. Nothing is recorded yet: who is voiced (everyone, or the cutscenes
first) is Gary's call.

Chapter 1, The Sun's Court, is Solhaven, line for line from Master Script v3 (a
copy is in `docs/script/v3_chapter1.md`). `scripts/world/areas/solhaven.gd` is
the Sun Square as a hub (who is there as the story goes on, and what they say:
Bram's wagon menu, Tamsin and her once-a-day crier, Pip, Old Maren, the notice
board, Wren, Liora, Aldric, Hale or the gate warden), with the places that start
each film: north past the fountain (Wren), the temple's doors (the Sun Court,
then the Trial of Light) and the Sunspire's door in the west wall; a pillar of
light marks the next one. The films are in `scripts/world/solhaven/films.gd`
(the Golden Gate and Hale's duel, the wagon and Turnip, Wren and the alley duel,
the Sun Court where Solmaris stops time, the Trial in the Hall of Mirrors, Ser
Aldric on the Sunspire, and after the Trial, back at the wagon, Gold in the Dark
and Morne's vault), saved by part in the `sol_film` flag, a duel resumed by its
own flag; Wren's chase is `chase.gd` (tap each glowing ledge to vault or slide);
the place is `solhaven_set.gd`, stand-ins that give way to Gary's Solhaven models
(`assets/models/solhaven/<name>.glb`, the names in "Solhaven: Your
Step-by-Step") (the Golden Gate is his since 22 October: `golden_gate.glb` with its 4096
atlas beside it, VRAM-compressed, at its real 24 m, the way in under its 5.7 m
arch, the doors hung in the arch and the city wall starting where its wings
end; the doors are his since 23 October, `solhaven_gate_door.glb`, one leaf
made to the arch at its real size, 2.8 m wide and 5 m tall at the hinge rising
to 7 m where the two meet, hung hinge edge on the hinge and mirrored for the
other, swinging into the square; `tests/gate_shot.tscn -- <dir>` takes stills
of it from the road, under the arch and from the square, shut and open; Bram's
wagon is his `covered_wagon.glb` of the same day, at its real size, turned
about so its shafts, down on the ground, point the set's way with Turnip
between them, its let-down tailboard the seat Bram takes in the campfire film
(`SolSet.tailboard`), and `tests/wagon_shot.tscn -- <dir>` takes stills of it
in the stable yard by day and with the lamp lit; the atlases of both sit
beside them, VRAM-compressed, split out by `tools/split_glb.py`) and his people (`assets/models/characters/<id>.glb`: hale,
sun_guard, ysa, tobin, refugee_b, refugee_c, horse_trader, turnip, tamsin, pip,
maren, wren, courtier, hierarch, aldric, liora, morne) as each arrives. Ysa came on 12 November
(`characters/ysa.glb`, Gary's Tripo3D model, `tools/glb_bake_turn.py` then
`tools/rig_villager.sh ysa`, 1.64 m, `Figure3D.OWN_GAIT` ysa, her portrait
rendered from it): she sits on a bedroll on the verge at the gate, legs out,
facing where the player stops, with Tobin asleep on his back along it at her
right, his head against her lap and her right hand on his hair
(`Films._ysa_and_tobin`, `YSA_FACES`, `TOBIN_HEAD`, `TOBIN_LIES`; `sit_long`,
`lie_on`, `AshfordP1.lap_hands`; she no longer turns, which would swing her legs
out from under him), and plays her side story; and Tamsin's stall
(`solhaven/card_stall.glb`, made at its real size, so it stands at it: 2.35 m
to the awning, its rack of cards facing the square), SIGIL CACHES painted in
gold on its little hanging tin board (`SolSet._stall_sign`, `STALL_BOARD`).
The gate's guards: the outer two (`Films.GUARDS`) stood at z 26.6, inside
the towers' faces (27.45) of his 4.9 m-deep gate, so they read as a guard with
a leg lifted; they stand in front at 28.0, and when Hale opens the gate all
four step aside (`GUARDS_ASIDE`, `_aside`) rather than back 1.6 m, into the
towers and the doors' swing. `tests/ysa_stall_peek.tscn -- <dir> [gate]`. Voices
play from `assets/audio/vo/` (`herald_14`..`16`, `solmaris_01`..`09`,
`morne_01`..`08`), the square's music is `solhaven_town`. The side stories come
in through `scripts/world/areas/solhaven/solhaven_side.gd` (`setup(world)`).

```sh
godot --headless --fixed-fps 10 res://tests/solhaven_test.tscn -- <dir> [choice=1]    # the whole chapter, every line tapped on, its checks
xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 960x540 --fixed-fps 10 \
    res://tests/solhaven_test.tscn -- <dir> keys [from=court]    # a still on every line (from= starts at a film part)
```

Dialogue portraits for the 3D characters are rendered from their models into
`assets/art/characters/<id>_portrait.png` (the dialogue box, and the Ledger's
People page, use someone's own portrait when there is one, else the face for
their costume). Ned the fiddler's, Krell's and Corin's mam's are head-and-
shoulders crops of Gary's 20 October pictures of them (`lookdev/refs/ned_sheet.jpg`,
`krell_sheet.jpg`, `corin_mam_sheet.jpg`, the sources for their models) on the
frame's dark blue, until their models exist and can be rendered; Warden Hale's
(`hale_portrait.png`) and the Sun Guard's (`gate_warden_portrait.png`, the
gate warden who speaks in his place after the Trial) are the same from his 23
October sheets (`hale_sheet.jpg`, `sun_guard_sheet.jpg`), the studio grey
behind them keyed to the blue:

```sh
xvfb-run -a -s "-screen 0 1024x1024x24" godot --rendering-driver opengl3 --resolution 1024x1024 res://tools/render_portraits.tscn
```

Since 5 November the portraits are 1024 square (`tools/render_portraits.gd`
`SIZE`; run it with `--resolution 1024x1024` in a 1024x1024 screen), twice
what they were: the dialogue box's 220-point frame is 660 pixels on a 3x
phone. The framing is unchanged (same `CLOSER` and `RAISE`; compared side by
side). The tool also knows the costume faces it had rendered before by hand
(`child_b`, `child_c`, `elder`), Tobin (`tobin.glb`, for the Ledger's People
page), and three people whose figures were Gary's models but whose faces
were blank in the box and the Ledger: Wren and Dask (Player C and B, as
`Figure3D.MODELS` dresses them) and Pip (the boy, `child_b`). The refugee's,
Krell's, Corin's mam's and Aldric's stay the painted ones from Gary's sheets
(512). Tamsin has no face yet: the merchant model she stands in is a bearded
man, so she needs a model of her own. Tilly's is now rendered as the tool frames her
(`CLOSER` 0.88: her face the size of everyone else's); the old file was a copy
of `child_c`'s, framed wider. Every place that shows a face (the dialogue box,
the Hero page, Standing, the Ledger's People page, the swear screen, the pack
tour, the duel tutor, the mirror, the old battle screen) draws it with the
mipmapped filter (`TEXTURE_FILTER_LINEAR_WITH_MIPMAPS`; the portraits import
with mipmaps on and no size limit), so a 1024 face stays smooth in a small frame.

To watch a film part by itself, tapping through every line (`corin`, `midnight`,
`dawn`, `taproom`, `burning`, `cellar`, `river`, `camp`, `morning`, `road`, `ridge`;
`choice=1` answers every choice the other way, `flag=tam_told` sets a story flag
first, `box=2` picks another of Bram's decks):

```sh
xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 960x540 --fixed-fps 10 \
    res://tests/film_test.tscn -- /tmp/film midnight 30 keys     # a still every 3 s and one per line
godot --headless --fixed-fps 10 res://tests/film_test.tscn -- /tmp/film river   # just run it
godot --headless --fixed-fps 10 res://tests/film_test.tscn -- /tmp/film corin 0 only read=25 trace   # lines left up as a player reads them, with where Bram is
```

Tam's barrel is carried to the stall and Tilly's Lantern Moth flies (its wings
beat through `scripts/world/wing_flap.gd`, which also flaps the moth in duels);
the Great Lantern (Gary's model) is lit at midnight. The lantern crate the player
carries is Gary's model (`make_crate()` in `ashford_village.gd`) at half size,
its lid left off so the lanterns show.

The village itself (`scripts/world/ashford_village.gd`) is built from the look
test in `lookdev/ashford`, with lighter settings on the phone and web renderers.
Its shaders live in `assets/shaders/village/`.

```sh
# P1 played as a player would (taps, keys, wrong taps to check the gating), a still at every line and step:
xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 8 \
    res://tests/ashford_test.tscn -- /tmp/ash                 # the attic to midnight
#   ... -- /tmp/ash opening          the attic to "Find Tam"
#   ... -- /tmp/ash green alt        Tam, Nell, Tilly, Ned and Hob, giving the other answers
#   ... -- /tmp/ash duel lose        Corin to Tilly's gift, losing the rematch (coach: let Bram coach, no rematch)
#   ... -- /tmp/ash midnight         straight to Corin, then on into the film
godot --headless --fixed-fps 8 res://tests/taproom_walk_test.tscn        # the crate walk: the stairs, "Wrong way", the door (5 s)
godot --headless res://tests/lantern_sim.tscn -- 0.3 0.25 200            # Lantern Duel balance, as the story plays it
godot --headless res://tests/lantern_sim.tscn -- 0.3 x 300 rematch       # the rematch you can lose
```

## Menus, standing, items and adverts

- **Opening notice** (`scripts/ui/notice_screen.gd`): two pages at launch, before the title: who made and owns the game with Gary's note about adverts, then (23 October) "A one-man job": that one person made all of it, and a plea to tell him what doesn't work or look right so he can fix it (`NoticeScreen.PAGES`; the words are his, polished). The title screen carries "Made by Gary Mannion" and the copyright line. Each page stays up until Continue is pressed (or Enter, Space, E, Esc or a pad's A), and Continue isn't there to press for its first 1.2 s, so a thumb still down from the splash, a tap before it can be read or a key held since before can't move it on (22 October; `tests/controls_test.gd` checks both pages).
- **First launch** (`Main.first_launch()`, `scripts/game/launch_log.gd`): the first run of a build on a phone or a Mac compiles every shader the opening draws the first time it's drawn, and on an iPhone that held the screen for a long moment with nothing to say why (Gary, 22 October: "the first time launching the game it sticks"). On that first launch Ashford is built and warmed under the title behind a "Getting the game ready" loading bar (`Packs.hold`), and every launch after finds the shaders in the cache. Each launch marks where it got to (the notice, the title, Ashford building, ready, and the slowest frame on the way) in the settings as it goes, and the pause menu's Options page shows the last launch's marks under the build line, so a phone that stuck can say where. `-- --first-launch` makes any run behave as a first one.
- **Pause menu** (`scripts/ui/pause_menu.gd`, ☰ or Esc in the world): Hero (Sigil Rank, Seals, the seven attributes with their 7+ perks and points to place), Standing, Deck (edit it; only a legal deck is kept), Codex, Items, Controls (phone, tablet, computer, controller; opens on the device in use) and Options (volumes, text speed, camera zoom and its reset, text and buttons size, 3D field, advert previews, save, quit). **The game stops while it's open** (23 October; until then a film, a walk or a voice line carried on behind it): the menu pauses the scene tree (`PauseMenu._set_paused`) and runs on its own (`PROCESS_MODE_ALWAYS`), as do the pack tour over it, the music and the loading screens; the world's own waits are timers that stop with the tree (`create_timer(secs, false)` throughout `scripts/world/`), and a tween made from a world node stops with it. Anything new that must keep going while the menu is up needs `PROCESS_MODE_ALWAYS`.
- **Camera zoom** (`World.zoom_by()`, saved as `cam_zoom` in the settings): in the world on foot, pinch with two fingers, the mouse wheel or a trackpad, the + and - keys, a pad's right stick, or the small + and - buttons at the right edge. The camera glides closer or further along its usual line (`World.ZOOM_MIN` to `ZOOM_MAX`) and stops in front of any wall, roof or tree it would otherwise end up inside (`World._clear_way()`). Films own the camera: no zooming while one runs, and the player's zoom is back when it ends. In a duel, the wheel or a pinch zooms the 3D field a little (`DuelField3D.VIEW_MIN` to `VIEW_MAX`, saved as `duel_view`).
- **New Game starts with no cards.** Deck and Codex aren't in the pack until the story opens them: `Game.give_first_deck(cards)` hands over Bram's 12-card Spark deck (shown on the Deck tab, not editable), `Game.unlock("deck")` / `Game.unlock("codex")` add the tabs (the world toasts "New in your pack: Deck and Codex"), and `await hud.pack_tour()` runs a gated tour of the pack (`scripts/ui/pack_tour.gd`, lines in `PackTour.FIRST_DECK`, styled like the duel's tutor; kept on How to Duel under *Your pack*). Master Script v3 opens the deck screen first at the campfire, where the player chooses a deck, so the Lantern Duel doesn't play the tour or open the tabs: Bram hands over the Spark deck (its twelve cards fanned out on screen) and Deck and Codex stay shut in Ashford. Bram's 30-card deck, chosen at the campfire on the Thornwood road (flag `bram_deck`), is the first one the player can edit; old saves past Ashford have everything open. The deck screen's stall when it first opened at the campfire was its paintings loading on the first draw (seventeen at once; `tests/deck_open_probe.tscn` measures it: the first frame cost over a second here, a normal frame once they're loaded): `CardFace.warm_art` loads them ahead while Bram nods, on another thread in the apps and, since 23 October, one painting a frame on the phone link (web, no threads), where it had done nothing.
- **Codex** (`scripts/ui/codex.gd`): every card the player has found (their own, and cards seen played, greyed out until owned; nothing else is listed), with a detail view: the painting, description, attacks with their Fate bands, how to get it (Resonance), and the Attunement bar towards its Ascended form, with Re-absorb and Pour buttons.
- **Standing** (`scripts/game/standing.gd`): how each god and person sees the player, -10 to +10. Story choices already recorded as flags count through `FLAG_EFFECTS`; a dialogue step `{"standing": {"tilly": 1}, "why": "..."}` nudges it directly, and `{"if": "standing:solmaris>=2"}` branches on it. A toast says "Tilly will remember that."
- **Items** (`scripts/game/items.gd`): story items shown from flags, and equipment in three slots (charm, ring, deck case) that adds to attributes in every duel. A dialogue step `{"item": "<id>"}` gives one.
- **Morrowen's Ledger** (`scripts/ui/ledger.gd`, the Ledger tab after Hero): the quest log in Morrowen's voice, as the Keeper of the Dead's record of the Age (Master Script v3, Side Quests). *Accounts* lists the main story and the side stories, those still open first, then the settled ones, newest first, a sentence or two each in the past tense; *People* has everyone met, by place, with their face (`assets/art/characters/<id>_portrait.png`, or their cut-out's until it exists), one line on what's known of them and, where it's kept, how they stand with you. The words, and the flags that pick between them, are in `scripts/story/ledger_entries.gd`, from the Prologue on.
- **Sworn wagers** (`scripts/ui/swear_screen.gd`): before a one-shot wager duel, the swear screen says who's across the Circle and with what deck, what each side stakes, the opponent's duel rule, and "A sworn wager. Win or lose, it stands.", with **Not yet** and **Swear now** (armed after a moment, so a thumb tapping through talk can't swear by accident). The oath is saved (`wager_<id>`, `wagers_sworn`); the duel has no Try again (`spec.once`), and a game closed in the middle of one goes straight back into it.
- **Shards** (3 November, Gary: shards to collect as well as cards won in
  duels, "spending shards you should be able to do yourself", and "make sure
  cards aren't got too quickly"): a Shard is crystallised Resonance (one
  Shard, one Resonance) that the player keeps in a wallet (`Game.v2.shards`,
  `Game.shards()`; old saves start with none) and spends themselves, any time,
  from a card's detail in the Codex: **Forge with N Shards** pours only what
  the card still needs into its bank (`v2.banked`, the same bank a win's
  Resonance fills), a full bank crystallises a copy, and the rest stays in the
  wallet (`Game.forge()`). Only the cards a win could build towards can be
  forged (`DuelRewards.eligible()`: seen in a duel, answering at the player's
  Rank, a Relic only once a Champion or boss has played one, never a Summon or
  an Ascension), and a card marked `pvp_only` (PvP prizes; none yet) never.
  Forging gives no Rank experience: that comes from duels. Where they come
  from, all of it small (`DuelRewards`):
  - a won story duel spills a tenth of its Resonance as Shards
    (`SHARD_SPILL` 0.1, at least 1; on the result screen, "+8 Shards spill
    over"), and the advert that doubles a win doubles them too;
  - **Sigilfall shards** (`scripts/world/sigil_shards.gd`, `SigilShards`):
    little glowing crystals of Sigil glass (DuelCrystal's cut glass) at six
    spots round Solhaven's square, 2 or 3 each; walking onto one picks it up
    ("+2 Shards"), it's gone for the day and back the next by the device's
    calendar, and a day gives at most `SIGILFALL_DAILY_CAP` (12). None in
    the Prologue (`Ads.in_prologue()`), none before the Codex opens, and they
    hide while a film has the camera. `World._build` places them
    (`SigilShards.place`); another area gets them by adding its spots to
    `SigilShards.SPOTS`;
  - each of Chapter 1's side stories, once, when it's finished
    (`QUEST_SHARDS`: Mercy 20, Fen 15, Pip 15, the Sundial 20, Hale 25; paid
    from `Game.set_flag` when a `side_*` flag reaches an ending, so every
    branch pays; the HUD says "+20 Shards");
  - a spare copy of a Basic Totem with nothing left to manifest and already
    Tempered three times turns into Shards, a tenth of its cost
    (`Game.spare_is_shards`, `DuelRewards.copy_shards`: a Spark's spare is
    3), from the Codex ("Turn a spare into 3 Shards"); such a Totem not yet
    fully Tempered can still be Re-absorbed to Temper it (the button had only
    shown while an Ascension was filling).
  The Hero page's Resonance line says how many Shards are held. The Codex
  detail's buttons wrap onto a second row (an `HFlowContainer`); at 1600x900
  the row had run off the panel and the Close button was off screen.
  `godot --headless --script res://tests/shards_test.gd` checks it all and
  prints the pacing; `godot --headless res://tests/sigilfall_test.tscn` the
  crystals in Solhaven; `menu_test` forges a Cinderpup (`detail_forged`).
- **Adverts** (`scripts/game/ads.gd`, autoload `Ads`): one full-screen advert at most every 3 story duels and 5 minutes (never in the Prologue, never mid-duel), retries always free, and an optional advert after a story win that doubles its Resonance (3 a day; never offered in the Prologue either, `Ads.in_prologue()`). Until the AdMob plugin (poingstudios/godot-admob-plugin) is added to the iOS and Android exports, a labelled placeholder shows where each would play; Options turns previews off.

Ashford's cottages, the Crooked Lantern, the windmill (its sails turn until the thatch catches at midnight) and the oaks round the village are Gary's models (`assets/models/ashford/`; an `oak_b.glb`, `oak_c.glb`... is used alongside `oak_a` as soon as it's there); each has a `<id>_glow.png` window mask made from its colour atlas, so the windows light up at night. Missing models fall back to the drawn stand-ins.

So are the dry-stone walls round the fields, the fence along the inn's yard, the grain sacks and the crates (since 18 October; each model's texture is beside it, `tools/split_glb.py`, 1024 pixels). The walls are Gary's 4.2 m length laid end to end along the field lines (`FIELD_WALLS` in `ashford_village.gd`), each fitted to its stretch, set into the ground and leaning with the slope, some turned round; they're drawn in batches of about 32 m so far ones use simpler versions, and the phones leave out those past 85 m. Gateways are left where the riders and hounds come down the east road (`WALL_GAPS`). The fence is laid from Gary's model split into its bays and one post, so every join has a single post; its gap is where Bram and the player go through to the gardens (`INN_FENCE`). Sacks stand by the mill door, behind Tam's cart and by the blue stall; crates by the inn's door and the blue stall (`build_props()`). `make_crate()` gives the lantern crate on its own for carrying (origin at the middle of its base). The cider barrels (Tam's, the taproom's, the cellar's) are Gary's barrel since 20 October (`barrel.glb`, 0.96 m as made, scaled to the game's 0.8 m in `make_barrel()`, origin at its middle), and his second oak (`oak_b.glb`, the leaning one) is planted in turn with the first.

```sh
xvfb-run -a -s "-screen 0 2560x1600x24" godot --rendering-driver opengl3 res://tests/menu_test.tscn -- /tmp/menu 1600x900   # every menu tab, card detail, notice, advert
xvfb-run -a -s "-screen 0 2560x1600x24" godot --rendering-driver opengl3 res://tests/pack_tour_test.tscn -- /tmp/tour 1600x900   # Bram's pack tour, tap by tap
xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --resolution 1600x900 res://tests/deck_open_probe.tscn   # what opening the Deck tab costs: cold, cached, after warm_art, the web's one-a-frame way
xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 res://tests/village_shot.tscn -- /tmp/village       # Ashford's buildings and the roof fire
xvfb-run -a -s "-screen 0 1280x720x24" godot --resolution 1280x720 res://tests/props_shot.tscn -- /tmp/props [thornwood]   # the windmill (turning, then burning) and the oaks
xvfb-run -a -s "-screen 0 1280x720x24" godot --resolution 1280x720 res://tests/walls_shot.tscn -- /tmp/walls   # the walls, fence, sacks and crates, and what each view draws
godot --headless --fixed-fps 10 res://tests/props_clear_test.tscn -- /tmp/clear burning 0 only   # nobody in the film walks through them (corin, midnight, dawn, burning)
godot --headless res://tests/controls_test.tscn          # every line of the Controls page, pressed for real (keys, pad, mouse, wheel, fingers); also runs under xvfb-run
```

- **Crowns and Tamsin's stall** (5 November). The player has a purse: crowns,
kept in the save beside Shards (`Game.crowns()`, `add_crowns(n, why)`,
`spend_crowns(n)`; `v2.crowns`, an old save starts with none), shown on the
Hero page after the Shards ("Purse: 23 crowns."), with a "+N crowns" toast in
the world when they come from anywhere but a duel (`Game.crowns_gained`,
`WorldHUD._on_crowns`). A won story duel pays crowns by its kind
(`DuelRewards.CROWNS`: a lesson 0, early story 3 to 5, normal 6 to 10, big
moments 15 to 25; the least for a plain win, half the gap more for a Clean win
and half for a Quick one; a spec names its kind as `"rewards": {"crowns": ...}`,
else `CROWN_KIND` goes by the opponent), and the result screen says "+N crowns
(N in your purse)". Nothing in the Prologue (as with Shards), nothing from a
day's Sigilfall, and the advert that doubles a win doesn't double its crowns.
Chapter 1: Hale at the gate is early story, Wren in the alley, the Trial of
Light and the four sworn wagers are normal, Ser Aldric is a big moment; by the
Golden Knight's duel the main story has paid 19 to 25 crowns, beating him
makes it 34 to 50. Pip's two crowns a run are his own money: nothing pays the
player there, but losing his wager ("Two crowns, to Pip") takes two from the
purse. The two forty-crown choices (the Temple healer's price for Tobin, the
Sergeant's fine) are offered only with forty in the purse; otherwise they
read "I'll pay it. (40 crowns — you have 12)" greyed and can't be picked
(`DialogueBox.choose` takes `{"text", "off": true}` for an answer that can't be
given yet; `solhaven_side.gd _pay_option`), and paying takes the forty. The
old flags (`paid_temple`, `paid_fine`) are unchanged.
  **Tamsin's stall** sells sealed caches: talking to her, after her lines (and
"(Tamsin's stall sells sealed caches for crowns.)" once, the first time), "What've
you got?" opens the stall (`scripts/ui/stall_sheet.gd`, `StallSheet.open`):
three caches on the counter a day, each one card face down with a wax seal,
from exactly the cards a won duel's "New in your Codex" draws from
(`DuelArchetypes.in_reach`: the pools the chapter has opened, cards that
answer the Rank; `sealed_caches` puts cards not yet met first), never a Summon,
an Ascension, a PvP prize or the comeback card, and no Relic before the first
Seal (`DuelRewards.cache_ok`). Prices by tier (`CACHE_PRICE`: Spark 8, Glimmer
15, Crystal 30, Relic 60), half as much again after the Trial (Tamsin's
"Everything's dearer today": Spark 12, Glimmer 23, Crystal 45). Buying turns
the card over with the Codex's card face and it's owned, in the collection and
the Codex ("New in your Codex: Root Toll"; `Game.buy_cache`). The counter is
stocked afresh each calendar day (`Game.stall_caches`, by
`Game.calendar_day()`, which the Sigilfall shards use too) and kept in the
save. The crier's advert is now one free cache off the same counter (the
stall opens with "Take it" on each; a counter sold out that day gets one more
first, `Game.stall_one_more`), where it was three random cards.
`tests/crowns_test.gd` checks all of it headless (and prints the numbers);
`menu_test` takes the Hero page and the stall (`menu_stall.png`,
`menu_stall_bought.png`).

## Solhaven's side stories

Chapter 1's five side stories (Master Script v3, Side Quests; the lines are copied
into `docs/script/v3_side_quests.md`) live in `scripts/world/areas/solhaven/`:
`solhaven_side.gd` (the stories, their people, their wagers and their decks) and
`side_places.gd` (their places). Solhaven calls `setup(world)` once its square is
built, and `event(world, name)` when the main story starts one of them
("pips_errands", "sundial_scar", "hales_orders"); the square's spots fit either
Solhaven square (`Places.square()`).

- **The Price of Mercy** (Ysa, after the gate; in the square if she got in, at the gate if not): swear, pay the Temple's forty crowns, leave it to her, or find Brother Anselm under the dyers' bridge, and the Sergeant of the Dawn Watch (rule *Licensed*: his Rites cost nothing while you have more Totems).
- **The Second Unsworn** (Fen on the fountain's rim): his soup line behind the fountain, then the truth, carry on, or a wager (rule *Patter*: his Wards lie face up and he swaps one each turn).
- **Pip's Errands** (once Pip's gone to work on the counting-house steps): follow him, then a wager for one note (rule *Scrapper*: his Totems hit 10 harder while he's behind), or Wren lifts one; the note on screen, and what you do with it; then a place for him.
- **The Sundial's Scar** (after Old Maren's talk): the oldest steps at dawn, Father Corvin, and Maren's forty pages.
- **Hale's Orders** (only if Hale opened the gate to everyone, once you know he's been stripped of his command): the barracks yard at noon; stand with him, or a wager with the Captain of the Sun Guard (rule *Discipline*: her Totems can't be Burned, Poisoned or Frozen). The lashing is seen on faces (Hale's, then yours) and heard, never the lash landing. There's no blood anywhere in the game (Gary, 24 October: "blood off"): a knocked-out Totem bursts into crystal and light, and the Options' old Full violence switch is gone (`Game.settings.violence` stays, at "full", for the lashing's shots).

Each place loads Gary's model by its name in "Solhaven: Your Step-by-Step" the
moment it's there (`assets/models/solhaven/anselm_room.glb`, `shrine_lantern.glb`,
`sundial_steps.glb`, `barracks_yard.glb`; people from `assets/models/characters/`:
`ysa`, `tobin`, `temple_healer`, `anselm`, `sergeant`, `sun_guard`, `fen`, `pell`,
`corvin`, `captain`, `hale`), and is a drawn stand-in until then.

```sh
godot --headless --script res://tests/story_rules_test.gd          # the four wager rules, and 30 duels under each
godot --headless res://tests/side_quests_test.tscn -- /tmp/side    # all five, each branch, wagers won and lost: just the checks
xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 15 \
    res://tests/side_quests_test.tscn -- /tmp/side mercy_won      # with screenshots (scenarios: hub mercy_won mercy_lost
#   mercy_swore fen_won fen_lost resume pip_aldric pip_lost pip_wren scar_told scar_nothing hale_won hale_lost hale_stood noon ledger)
```

## Running the tests

```sh
godot --headless --import                                   # first time only
godot --headless --script res://tests/sim.gd -- 2000        # every deck vs every deck
godot --headless --script res://tests/sim.gd -- 900 emberstorm tidegrove ironstone
godot --headless --script res://tests/duel_sim.gd -- 1000       # the v2 duel: decks, synergy by deck
godot --headless --script res://tests/synergy_test.gd           # families, reactions, chains, the gods
godot --headless --script res://tests/puzzles_test.gd           # every riddle's answer and a wrong try
godot --headless --script res://tests/white_sky_play_probe.gd   # Bram's duel in the snow, every move as written
godot --headless --fixed-fps 10 res://tests/white_sky_test.tscn -- /tmp/ws 4      # the whole snow opening, the three moves made
godot --headless --fixed-fps 10 res://tests/first_launch_test.tscn [-- again]     # notice, movie (first time only), title, New Game, the snow
godot --headless res://tests/sfx_test.tscn [-- list]            # the creatures' voices, the button click, the Codex's sounds
godot --headless --fixed-fps 30 res://tests/steps_test.tscn [-- list]   # footsteps: the rates, the grounds, a run across the green
godot --headless --fixed-fps 30 res://tests/ambience_test.tscn [-- list] # each place's bed of sound, the easing, every kind of silence, the weather
godot --headless res://tests/summon_video_test.tscn             # which Summon clip plays under each choice
# stills (under xvfb, as the others): ... res://tests/rain_shot.tscn -- <dir> [phone]   the green dry and in a shower
#                                     ... res://tests/options_shot.tscn -- <dir>         the Options page
# what a place holds and draws, built as a Mac builds it (under xvfb, as the stills):
#   ... res://tests/mem_probe.tscn -- full [duel] [list]         textures, meshes, triangles and draw calls
#   ... res://tests/tri_probe.tscn -- [ashford green | thornwood river | solhaven gate] [cam=x,y,z,x,y,z] [shot=<file.png>]
python3 tools/make_cries.py [kind or Summon ...]                # the stand-in creature voices (assets/sfx/cry_<kind>.wav, cry_<summon>.wav)
python3 tools/make_steps.py [ground ...]                        # the stand-in footsteps (assets/sfx/step_<ground>.wav and its takes)
python3 tools/make_ambience.py [bed ...]                        # the places' beds of sound (assets/sfx/amb_<name>.ogg; needs ffmpeg)
```

The summary line must report `0 invariant errors`.

### Texture sizes for the store build (5 November)

`tools/texture_sizes.py` sets every texture's import size under assets/ by
what it's for, from one table and a named profile: `full` (no limits, every
texture at the size it was made: the repo's state, as Gary wants his 4K models
in) or `launch` (people and the star creatures 2048, props and scenery 1024;
a still-lossless model texture to VRAM compression; card paintings and the UI
left alone). Dry run by default (a table of what would change, and the
megapixels per class before and after); `--apply` writes the `.import` files.
Before the store build, if it needs to be smaller: `python3
tools/texture_sizes.py --profile launch --apply`, then reimport
(`godot --headless --import`); `--profile full --apply` puts it all back (the
source pictures are never touched). Today `launch` would take the models from
608 to 378 megapixels. ASTC on iPhone: `project.godot` has
`textures/vram_compression/import_etc2_astc=true`, and the iOS preset in
`export_presets.cfg` keeps it (`texture_format/etc2_astc=true`,
`s3tc_bptc=false`); nothing overrides it.

## Rules in brief

- 40-card decks; 4 Prize cards (knocking out a Legend-tier or higher Totem takes 2).
- One Energy per turn. The duellist who goes first can't attack or call an Ally on turn 1.
- Twelve core elements plus four divine ones; hitting a weakness deals ×1.5 damage.
- Seven card tiers, from Spark (common) to Divine (one of a kind).
- Each duellist has seven attributes. A card becomes **Attuned** — and gains its
  bonus — when its duellist's matching attribute is high enough.
- Swearing to a god gives +3 to that god's attribute and a once-per-duel Divine Gift.
  Staying Unsworn gives +1 to every attribute and the gift *Unbound Will*.

## Music loops

Gary's tracks are delivered as whole pieces; the game plays a cut that loops
without a join you can hear. `Music` (`scripts/ui/music.gd`) plays each track's
intro once, then loops from `LOOP_START[name]` back to the file's end, which has
the music leading into the loop point baked over it. The two duel themes take
turns (`Music.duel_theme()`), and a track that was faded out (the village reel
when a duel starts) carries on from where it was when it comes back
(`World.resume_music()`), never from the top.

```sh
python3 tools/music_loop.py assets/audio/source/<name>.mp3 assets/audio/music/<name>.ogg \
    --start 35.03 --end 86.85 --fade 2.15 --check docs/audio-checks/<name>_loop_seam.mp3
godot --headless --script res://tests/loop_probe.gd -- <name>      # where Godot's loop really lands, and the jump at the join
```

`--start` and `--end` are a bar-aligned pair (the tool nudges `--end` onto the
beat and adds the crossfade); put the start in `LOOP_START`. Gary's 4 November
tracks: `bram_theme` (14.698 to 145.090), `tam_mill` (4.946 to 88.921),
`nell_waltz` (5.828 to 159.086, scouted in three-time: `--beats-per-bar 3`),
and the Night of the White Sky's one piece, `white_sky.mp3` (224 s), cut in
two: `white_sky` is its first 122 s (24.613 to 121.974, the walk's loop, rarely
reached since the walk takes 60 to 90 s) and `white_sky_duel` is the piece from
149.5 s (the hush before the storm) with its climax looping (8.870 to 50.759 of
that cut) until the white cuts it dead; the tail after the climax is never
played. A piece in `Music.FROM_START` always begins at its start. The seam-check mp3
is the join as the game plays it, three times, for listening to.

`midnight_choice` (5 November): Gary's 24 s continuation of the Midnight
film's soundtrack (`Midnight_Choice_Menu_Music_24s_Continuation.wav`),
played from its first sample (it carries straight on from part 1) and
looping 5.745 to 20.744 s (16 bars of its 0.9375 s bar; the end refined by
`tools/music_loop.py`'s `refine_end`, a one-bar crossfade baked in by its
`bake`), +4.2 dB so that at the default music volume it sits where Gary's
own preview mix has it under the film, Vorbis q6. Picked from the loop
scout's candidates by measuring each join against the piece's own
moments: its join's onset jump (1.75) and change of sound (0.108) are
below the piece's own typical moments (2.29 and 0.138), so it shouldn't be
heard. Its last 2 s fade out in Gary's file, so the whole 24 s can't loop.
It's in `Music.FROM_START` (always from its beginning). Gary's file is kept
as `assets/audio/source/midnight_choice.wav`; to cut it again,
`python3 tools/music_loop.py assets/audio/source/midnight_choice.wav <out.ogg> --start 5.745 --end 20.745 --fade 0.9375 --bar 0.9375 --search 0.06`
makes the same join (that tool writes q4 with no gain: the shipped file
is the same samples +4.2 dB, written at q6).
`tools/music_scout.py <mp3>` suggests the pair for a new track: the tempo and
bar grid, the first downbeat where the intro has settled, and the latest
bar-aligned end in the body of the piece whose run-in sounds like the run-in to
the start (beats, timbre and harmony); it prints the `music_loop.py` arguments
to use. `music_loop.py` ends with "rhythm through the join", the beats either
side of the join against the track's own flow into the start (1 is perfect;
the loops in the game are 0.5 to 0.96).

On the web (phones), Godot's own audio can only loop a track by stopping at its
end and starting again from the top, so the web build plays the music through
the page instead: `tools/build_web.sh` leaves the music out of the pack, makes
an MP3 of each track in `build/web/music/` (with the real length of each, the
loop's end, in `manifest.json`) and puts `scripts/ui/music_web.js` into
`index.html`; `Music` hands it the tracks, fades and loop points, and the
browser loops them sample-accurately. Check it in a real browser with:

```sh
tools/build_web.sh && python3 tests/web_music_check.py build/web   # records the join, the crossfades, the volume
```

## Opening movie

**When it plays (12 November):** once, before the title screen, the first
time the game is opened on a device (`Main._ready`,
`Game.settings.seen_opening`), skippable; after that from the title's Watch
the Opening. New Game no longer plays it: New Game opens on the snow
(`WhiteSky`). Before 12 November it played on every New Game.

Since 22 October the opening is Gary's one finished film: his animated clips,
Morrowen's narration, the music, the title and the words on screen all in the
picture. His master is 4K (3840x2160 at 60 fps, H.264, 3:14.6, 417 MB; since
23 October the joined cut of his three parts, "updated 4k opening movie"), and
the game carries it two ways:

- **At 4K, through the device's own player**, in the iPhone and Mac apps. The
  master is `opening_4k.mp4` on the repository's **films** release, the app
  workflows put it loose in the app bundle, and `OpeningMovie` plays it
  through the native video player (below) when both are there: AVPlayer over
  the game's view, decoded by the hardware, shown whole, with its own Skip.
- **As Ogg Theora**, `assets/movies/opening.ogv`: the same film at 1280x720
  and 30 fps (76.7 MB, Theora at 3000 kb/s with Vorbis sound, made from the
  master with ffmpeg, 23 October), which the phone link plays and the apps
  fall back to. It must stay under GitHub's 100 MB limit. To remake it:

  ```sh
  ffmpeg -i opening_4k.mp4 -vf "scale=1280:720:flags=lanczos,fps=30" -c:v libtheora -b:v 3000k -c:a libvorbis -q:a 5 assets/movies/opening.ogv
  ```

- **At 4K on the phone link, streamed** (24 October): through the browser's
  own video player (`scripts/ui/film_web.js`, put into the page by
  `tools/build_web.sh`; `WebVideoPlayer` drives it with the native player's
  API). Safari plays the HLS stream itself; other browsers through hls.js
  (`tools/web/hls.light.min.js`, Apache-2.0). The stream is on the site at
  `films/opening/`: `tools/make_hls.sh <master.mp4> <dir>` makes it (the 4K
  copied untouched, 1080p60 and 540p60 cut at the same keyframes, about 600
  MB), and `tools/publish_web.sh "<message>" --film opening <dir>` publishes
  the site with it (later publishes keep `films/` without uploading or
  downloading it, its sizes kept in `films/sizes.txt`; it refuses a site over
  980 MB, GitHub Pages' limit is 1 GB). The web build's
  Theora fallback, for a browser that can't stream, is a 360p copy
  (`build/opening_360.ogv`, made by `build_web.sh`; the apps keep the 720p
  one). With the opening's streams the site is about 950 MB: **there's no
  room on GitHub Pages for another 4K film**, so the story films will need
  somewhere else to stream from on the phone link (the apps carry them from
  the films release as they do the opening). `build/` has a `.gdignore`
  (`build_web.sh` makes it), so nothing put there goes into a pack: until 24
  October the opening's two spare copies there added 133 MB to the main pack.

`OpeningMovie` plays either whole, with nothing of the engine's over it (no
subtitles, voice, music or title), shown whole: as big as fits the screen with
nothing cropped, centred, black either side on a wide phone (`cut_rect()`;
until 23 October it was enlarged to fill the phone's width and a fifth of its
height went off the top: "you can't see it all, some of it is off screen on
phone"). A tap shows Skip; Esc, Tab or a pad's Start skip at once, and E,
Space, Enter or A show Skip and skip on the second press. On the phone link
the Theora copy is the whole `movie` pack (the paintings, voice lines and theme
below stay out of the web build while the cut exists, or the pack would pass
GitHub's 100 MB limit); the apps keep both. Check the Theora copy with
`tests/movie_shot.tscn -- <dir> cut 0:20 1:30 3:04` (stills at those times;
it checks nothing of the engine's goes over it and that it runs to its end).
If it ever stutters on a phone, re-encoding the .ogv again is lossy: convert
from Gary's master instead.

### The native video player (iPhone and Mac)

Godot's own player only does Theora, and a 4K 60 fps Theora would neither fit
in git nor play on a phone, so the apps play Gary's masters through the
device's own player instead: `addons/native_video` is a small GDExtension,
`NativeVideoPlayer` (`src/native_video_player.h`, `.mm`: AVPlayer in a view
laid over the game's view, with a Skip label and a subtitle line of its own,
taps reported to `poll()` once a frame, `set_opacity`/`set_volume` for the
fade), built for macOS (universal) and iOS (arm64) with godot-cpp at API 4.7
by `.github/workflows/native-video.yml` on a Mac runner whenever its source
changes on `main` or a `wip/` branch (or from the Actions tab), and put on
the **native-video** release as `native-video.zip` with its sum. Nothing built
is committed: `tools/fetch_native.sh`, run by `iphone.yml` and `mac.yml`
before they import and export, downloads the libraries into
`addons/native_video/bin/` with the `.gdextension` beside them (copied from
`native_video.gdextension.in`: the file isn't live in the repository, so Godot
never complains of a missing library here or on the web), and every `.mp4` on
the **films** release into `addons/native_video/films/`, where the export
plugin (`films_export.gd`, enabled in `project.godot`) ships them loose in
the bundle: the bundle's root on an iPhone, `Contents/Resources` on a Mac.
Without either release the apps play the Theora copy, and nothing fails.

`OpeningMovie` asks for the player only where it exists
(`ClassDB.class_exists("NativeVideoPlayer")`) and the film is in the bundle
(`find_file("opening_4k.mp4")`), gives it up to 8 s to read the file, and
falls back to the Theora copy if it can't be opened or read (a failure in the
middle of the film ends the movie instead). While it plays the engine's own
Skip button is under the native view, so a tap shows the player's own Skip
and the next tap on it skips; the keys still work, since the Mac view passes
them on. The fade-out takes the native picture and its sound down with the
engine's black, and `stop()` clears the view. The phone's own player pauses
when the app is put away and goes on when it's back. All of this runs
headless against a stand-in player, since the real one exists only in the apps:

```sh
godot --headless --fixed-fps 30 res://tests/native_movie_test.tscn   # prefers it, tap/Skip, keys, fade, its end, the fallbacks
```

**Putting a film on the films release** (midnight and dawn, when Gary makes
them in 4K): on a `wip/` branch, commit it to `incoming/films/` as
`<name>.mp4.part0`, `.part1`... (`split -b 90m <name>.mp4 <name>.mp4.part`)
with `<name>.mp4.sha256` beside them, push, and `.github/workflows/films.yml`
joins the parts, checks the sum and uploads `<name>.mp4` (its tag stays on
`main`); then delete the parts from the branch and keep that commit out of
`main`'s history (GitHub takes no file over 100 MB, and 400 MB of film would
be in every clone for good). The opening went up this way on 23 October.
Not yet seen on a real iPhone or Mac: the first build with it should be
watched from the title to the attic (`docs/iphone.md`). A simulator build
has no library and plays the Theora copy.

Without the file, the engine plays the movie shot by shot
(`tests/movie_shot.tscn` without `cut` checks that path, whether or not the
cut exists): `scripts/story/opening_movie.gd` follows the "Opening movie"
table of the Master Script v3: 21 shots in 2:24, cut in time with
`opening_theme` (the title rises at 2:14.5 to meet its last chord). Morrowen
narrates fifteen lines (`assets/audio/vo/`); shot 10 is music only. Each line
starts `vo_at` seconds after its shot's cut, and its subtitle is the words as
recorded. Some lines are longer than their shots, so they run on past the cut and
the next one follows a breath later, still inside its own shot (09b runs straight
on from 09a, on the cut to the card); none overlaps another, and all end before
the title. Two effects follow her words, timed in seconds into the line: shot
13's white streak sets off on "over a village" and lands on Ashford on "anyway",
just before the cut (`streak`), and the eighth light round the Throne ignites on
"marked" (`white_word`).

The lines are made from Gary's recordings, kept as he sent them in
`assets/audio/source/vo/` with his line sheet and voice notes. `tools/vo_master.py`
trims each to its words, levels it (about -16 LUFS, peaks under -1 dBTP) and
writes the game's Ogg files. After a line is re-recorded, run it again, then the
check, and move the `vo_at`s if it reports a problem:

```sh
python3 tools/vo_master.py assets/audio/source/vo             # -> assets/audio/vo/vo_<n>.ogg
godot --headless --fixed-fps 20 res://tests/movie_shot.tscn   # every line against the shots, and the checks
xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 20 \
    res://tests/movie_shot.tscn -- /tmp/movie 2:05.6 2:07.7   # plus stills: half a second into each line, and at these times
```

Each shot plays its painting with a slow camera move, or a video clip where one
exists. To add clips made with an image-to-video tool, name them after their
shots (`shot_08.mp4`) and run:

```sh
python3 tools/movie_clips.py <folder of clips>     # -> assets/movies/shots/<shot>.ogv, trimmed to each shot
```

### Summon videos (Gary's clips in a duel)

Since 23 October (Gary: "a video that plays when you summon; the first time a
longer one, after that a brief one, or a toggle") a card's own clip plays when
it's summoned or called (`scripts/duel_ui/summon_video.gd`, from
`DuelScreen.fx_summon` and `fx_call`): `assets/movies/summons/<card id>_full.ogv`
(8 to 12 s) and `<card id>_short.ogv` (2 to 3 s), Theora for the phone link and
the editor, made with the ffmpeg line above; the apps also carry his masters
as `<card id>_full.mp4` / `_short.mp4` from the "films" release
(`tools/fetch_native.sh` fetches every .mp4 there, the export plugin ships
them) and play those through the native player. The first time a card is
summoned in a save its full clip plays, every time after the short one
(`Game.v2.summon_seen`); Options and the duel's Menu set "Summon videos:
Full / Short / Off" (`Game.settings.summon_videos`); a tap skips; the music
dips under it (`Music.duck`); the landing effects follow it. A card with no
clip keeps the drawn `SummonCine`. On the web each card's clips are their own
pack (`tools/web_packs.py` makes `summon_<id>` for every card with clips),
fetched the first time that card is summoned, with a loading bar that can be
skipped. `docs/script/summon_clips.md` lists the cards to make, lengths and
what each should show (the four Demigod Summons first, then every starter
Totem). `godot --headless res://tests/summon_video_test.tscn` checks the rule.

The first clip came on 12 November, Orlanthe's (`orlanthe_full.ogv`, 10 s;
`orlanthe_short.ogv`, 2.9 s cut from it); his master and the short cut
from it are on the "films" release as `orlanthe_full.mp4` and
`orlanthe_short.mp4` (through `wip/orlanthe-clip`, as the films go), so the
apps play those natively. A clip with its own sound plays without its stinger (`fx_summon`), and a
filmed duel (`spec.film`) plays no clips.

## Story films: the Prologue's cutscenes as Gary's own films

Since 23 October a stretch of a 3D cutscene can play as one of Gary's own
films instead, as the finished opening replaced its shot-by-shot version
(Gary: "the cut scene after all the lanterns go up: can we make a proper
movie from that like we did for the opening movie?"; 24 October, v7: the
cutscenes as videos built round one hero, Player A). Master Script v7 has
seven, in the Still to Make doc's "Films for Player A" tab:

| film | where | in place of |
|---|---|---|
| `midnight` | the bell to Bram's answer to the player's choice (Gary's film, in parts; part 3, the lanterns to the cart, still to make) | `Ashford._midnight_3d` up to the lanterns (`_midnight_to_answer`); the 3D plays on from the lanterns until part 3 comes |
| `white_light` | after the cart, to black | `Ashford._the_white_light` |
| `herald` | dawn, to Bram stepping between | `Ashford._herald_3d` |
| `reckoning` | Krell's arrival to her stakes | `AshfordNight._krell_arrives` |
| `tams_hand` | Tam's duel, his fall, Nell, Krell's orders | `AshfordNight._tam_falls` and her two lines |
| `no_roof` | the wide shot from the ridge | `AshfordNight._restraint` |
| `ridge` | the Thornwood's last ridge, Solhaven below | `Thornwood._ridge`'s 3D |
| `white_sky_duel` | Bram's duel in the Night of the White Sky (8 November: Gary's choice to film it himself; 16 shots, no Player A) | `WhiteSky._duel`'s filmed 3D duel (`WhiteSky._duel_film`) |

What the player does stays in the game between them (the cart heave, the
tunnel, the look back, the conversations). `scripts/story/story_film.gd`
(`StoryFilm`) holds each film as its steps (`FILMS`): shots with their
length, what's seen (Gary's brief, and the animatic's card), whether Player
A is in it, and the lines said over them at their moments (the 3D scene's
own lines, word for word); between them what a film can't carry on its own
(Bram's midnight question, the music cues). A film plays, best first: Gary's
4K film `<film>_4k.mp4` through the device's own player (the apps: from the
films release, as the opening; the phone link: streamed from `films/<film>/`
if the site has it, `films/sizes.txt` saying so), its lines as the player's
own subtitles and the choice pausing it with the picture stepped aside for
the game's buttons; else the whole cut `assets/movies/<film>.ogv`; else its
shots (`assets/movies/<film>/<shot>.ogv`, or a painting
`assets/art/movie/<film>/<shot>.png`). Each scene asks `StoryFilm.available`
first and plays its 3D when the film isn't there, or when `StoryFilm.play`
says it couldn't play (`"played": false`); after a film the scene sets the
world as its 3D would have left it (`_midnight_film`, `_white_light_film`,
`_herald_film`, `_krell_film`, `_tam_film`), so any mix of films and 3D
plays on. `-- --story-films` forces every film on, as animatic cards.
When a film comes in, its shot lengths in `FILMS` are set to match it, so
its lines land at their moments. On the phone link each film's Theora copy
would be its own pack (`tools/web_packs.py`), built only once it has
something in it; GitHub Pages has no room left for more 4K streams (the
opening's take 632 MB of its 1 GB). Gary's step-by-step, with every film's
shots, where each line falls and which shots show Player A, is
`docs/script/films_plan.md` (made from `FILMS`).

**Films in parts (midnight, 5 November).** Gary made Midnight in pieces cut
at the player's choice, so a film in `FILMS` can be a list of `"parts"`
instead of `"steps"`. Midnight's are: part 1 (`midnight_1`, 34.08 s: the
bell to Bram's "Wonder who'll be sitting up there tomorrow."; shots
mid_01 to mid_06, their lengths his film's own cuts, each line set where
it's spoken); the choice (`"hold": "midnight_choice"`,
`"music": "midnight_choice"`); Bram's answer for the pick
(`"file": {0: "midnight_2a", 1: "midnight_2b"}, "by": "mid_choice"`, 3.42 s,
shot mid_07, `"keep_music": true`); and part 3 (`midnight_3`, mid_08 to
mid_15, `"optional": true`, not made yet). Each part plays by the usual
ladder (`<part>_4k.mp4` through the device's player, then
`assets/movies/<part>.ogv`, then its shots; a later part with none of them
plays its animatic so the story still goes on), on one native player for
the whole film. A part's last frame stays up when it ends: the device's
player pauses on it, the Theora player's picture is copied into a
`TextureRect` (`_freeze_frame`). At the choice the game shows Gary's own
last frame (`assets/art/movie/midnight/midnight_choice.jpg`, his PNG at
1280x720) and only then hides the native player, so nothing changes on
screen; the menu music starts the moment part 1 ends and loops for as long
as the player takes; the game's own choice buttons come up as everywhere
else (`CineOverlay.choose`: tap, keys, pad). On the pick, 2A or 2B opens on
the same player hidden and is shown only once its first picture is there
(Theora: the held frame stays over it until its first frame is drawn), so
it cuts straight in with no black; the music plays on at the same place
(`"keep_music"`), and the parts' own voices are in the film (`"voiced"`:
no recordings are played over them). Part 3 isn't there, so the film stops
before it: `StoryFilm.play` returns `"stopped_at": "midnight_3"` and
`"film"`, the film still up on 2A/2B's last frame; `Ashford._midnight_film`
then runs `_midnight_3d(w, "lanterns", r)`, which stages the green as the
3D has it at Bram's answer (`_at_the_lanterns`: the Lantern lit and
settled, Tam and Nell dancing, the player on their mark), puts the camera
on the lanterns shot, and lets the film go (`StoryFilm.let_go`, a 0.4 s
dissolve from the film's last frame into the 3D as the lanterns start to
rise); from there it is the 3D as before (the wind stops, "Bram. Is it
meant to do that?", the tear, the carts, the run, the cart). The menu
music carries on under the lanterns and stops where the 3D's own music
stops (`Music.stop(3.0)` as they freeze). When part 3 comes it plays after
2A/2B with no code change, and fades the menu music out over its first
second. On the phone link the parts' Theora copies go in the film's pack
(`tools/web_packs.py`: `assets/movies/<film>_*.ogv`), and the held frames
(`assets/art/movie/<film>/<film>_*`) stay in the main pack, since the
streamed film fetches no pack. (`MOVIE_FALLBACK` there now names the
opening's paintings as `assets/art/movie/shot_*`: its old
`assets/art/movie/*` also swept every story film's paintings and held
frames out of the web build once `opening.ogv` existed.)

**The films release** now has `midnight_1_4k.mp4`, `midnight_2a_4k.mp4`
and `midnight_2b_4k.mp4` (Gary's 1280x720 files; the `_4k` is only the
name the native player looks for), each with its `.sha256`, published
through the work branch `wip/midnight-films` and the Films release
workflow (the session can't upload to a release directly; the branch's
second commit took the files off it again). **To add part 3:** put
`midnight_3_4k.mp4` (and its `.sha256`) on the films release the same way,
and its Theora copy at `assets/movies/midnight_3.ogv` (ffmpeg, libtheora
`-q:v 8`, 1280x720, Vorbis `-q:a 6`, 48 kHz); set mid_08 to mid_15's
lengths in `FILMS` to his cuts. Nothing else changes.

A Theora quirk found on the way: with no sound device (the container's
runs) the Theora player never says it has finished and runs on past its
end on its last frame; with one, its clock goes back to 0 the moment it
finishes. `StoryFilm._play_cut` now ends a cut by its own clock as well as
the player's word, and a shot's line clock counts a finished player as the
shot's end (before, a cut ending a moment before its shots' total waited
for ever).

```sh
xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 640x360 \
    --fixed-fps 4 --path . res://tests/midnight_parts_test.tscn -- /tmp/mid 0 every=4 wait=3 after=6
godot --headless --fixed-fps 4 --path . res://tests/midnight_parts_test.tscn -- /tmp/mid 1 every=0   # quick, no stills
```
(`tests/midnight_parts_test`: the Theora way through part 1, the held frame
and buttons with the music, the pick, 2A or 2B, and into the 3D at the
lanterns; measures every frame's brightness at the three joins and fails
on a black frame; stills every `every` frames. About 10 minutes rendered.)

```sh
python3 tools/movie_clips.py <folder of clips> --film midnight    # -> assets/movies/midnight/<shot>.ogv
godot --headless --fixed-fps 10 res://tests/film_test.tscn -- /tmp/film midnight only 0 --story-films   # the films as animatic cards
godot --headless --fixed-fps 30 --path . res://tests/story_film_test.tscn   # the 4K path, with a stand-in player
```
