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
| `assets/sfx/` | Sound effects. |
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
at, and the web build published so the phone link matches `main`. The look
pass itself hasn't started (22 October): it's the next big job, and Gary should
be asked before it's begun, as `docs/handover/2026-10-18.md` says of anything
big.

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
| `assets/models/creatures/` | The Totems' 3D models, `<card id>.glb` with `<card id>_atlas.png` beside it (`assets/models/PUT_MODELS_HERE.txt`). A Tripo3D creature (one material, 4K base colour, roughness-metal and normal maps embedded) is readied with `python3 tools/split_creature.py <in.glb> assets/models/creatures/<id>.glb --glow`: the atlas out at 2048, the other maps dropped, and with `--glow` the fire-coloured parts of the atlas as an emission map (`<id>_glow.png`), so a Cinderpup's flames shine through the bloom. Cinderpup is Gary's 26 October Tripo3D model, with its seven clips (idle, spawn, attack, hit, defeat, victory, run); under the duel's warm lights its orange coat reads red. Brookfin is his 27 October one (the blue fish-dragon with the pale belly and fins, an 89-joint rig with eleven clips: idle, walk, run, swim, attack, hit_react, defeat, victory, spawn, tail_swish, rest; `hit_react` is read as its hit, `DuelField3D.CLIP_ALIASES`); `tests/totem_peek.tscn -- <dir> <yours> <theirs>` stands chosen Totems on the field for a look. River Hound is Gary's 28 October model (the lean water hound with the white foam ruff, the same eleven clips as Brookfin), in Tam's friendly game, his Reckoning duel and any deck that has her; until then she was a Shieldhound washed blue. |

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
| Tam's friendly game | chains, Combo | Tam says it as the player's second card goes down (`spec.teach`, `teach_lines`: a duel that teaches only some lessons, in its own teacher's words); a note after a win |
| Nell's friendly game | whose ground, Graced | Nell at the first turn: Ashford's Circle is Ellowen's, and the Traveller's Pack is hers; a note after a win |
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

New Game opens on black and the caption "Ashford / The last night of the Age."
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
xvfb-run -a -s "-screen 0 1024x1024x24" godot --rendering-driver opengl3 --resolution 512x512 res://tools/render_portraits.tscn -- player
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
maren, wren, courtier, hierarch, aldric, liora, morne) as each arrives. Voices
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
xvfb-run -a -s "-screen 0 1024x1024x24" godot --rendering-driver opengl3 --resolution 512x512 res://tools/render_portraits.tscn
```

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
```

The summary line must report `0 invariant errors`.

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
beat and adds the crossfade); put the start in `LOOP_START`. The seam-check mp3
is the join as the game plays it, three times, for listening to.
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

## Story films: the Prologue's cutscenes as Gary's own films

Since 23 October a stretch of a 3D cutscene can play as one of Gary's own
films instead, as the finished opening replaced its shot-by-shot version
(Gary: "the cut scene after all the lanterns go up: can we make a proper
movie from that like we did for the opening movie?"; 24 October, v7: the
cutscenes as videos built round one hero, Player A). Master Script v7 has
seven, in the Still to Make doc's "Films for Player A" tab:

| film | where | in place of |
|---|---|---|
| `midnight` | the bell to the cart going over on Corin | `Ashford._midnight_3d` (the run and `_the_cart_falls`) |
| `white_light` | after the cart, to black | `Ashford._the_white_light` |
| `herald` | dawn, to Bram stepping between | `Ashford._herald_3d` |
| `reckoning` | Krell's arrival to her stakes | `AshfordNight._krell_arrives` |
| `tams_hand` | Tam's duel, his fall, Nell, Krell's orders | `AshfordNight._tam_falls` and her two lines |
| `no_roof` | the wide shot from the ridge | `AshfordNight._restraint` |
| `ridge` | the Thornwood's last ridge, Solhaven below | `Thornwood._ridge`'s 3D |

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

```sh
python3 tools/movie_clips.py <folder of clips> --film midnight    # -> assets/movies/midnight/<shot>.ogv
godot --headless --fixed-fps 10 res://tests/film_test.tscn -- /tmp/film midnight only 0 --story-films   # the films as animatic cards
godot --headless --fixed-fps 30 --path . res://tests/story_film_test.tscn   # the 4K path, with a stand-in player
```
