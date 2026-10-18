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
```

The Lantern Duel is a gated tutorial (`scripts/duel_ui/duel_tutor.gd`, lines in
`LESSON` in `scripts/world/areas/ashford.gd`): each explanation waits for a tap and
each instruction locks everything but the one thing to tap (including the tap on
the die for who goes first, and the card panel on the right). Both decks are dealt
in order, the player goes first, Corin follows a script (`DuelHuman.Scripted`) and
the player's Life and Totem can't drop to zero. It teaches only what's on the table
that night; everything else is taught the first time it matters, in the same gated
way, by Bram: the first condition or boon to land on either side (`fx_status`,
which also gives it a Codex entry under *Conditions*), Wards and the element chart
at the campfire before Dask's road duel (`prologue.gd`, with `ElementChart`), the
first Ward set or sprung, and the first time an Ascension can be played. A duel
with `spec.lessons = true` gets a tutor just for these one-off lessons
(`DuelTutor.lesson()`); each is taught once ever (`Game.learn()`), and every line
Bram has given is kept, in order, on the pause menu's **How to Duel** page.

```sh
xvfb-run -a godot --rendering-driver opengl3 --resolution 1280x720 res://tests/creature_shot.tscn -- <dir> blazehound   # a duel with a given Totem on the field
```

The rules are written up in the "Duel Rules v2" Claude doc, and the story in the
"Master Script" doc. The Duel Lab's Kingdom Law picker plays any duel under a
god's Law.

**Play it on a phone:** https://fg29cw8knf-wq.github.io/covenant-war/ (turn the phone sideways; in
Safari use Share > Add to Home Screen for a full-screen app icon). Rebuild it with `tools/build_web.sh`
and push `build/web` to the `gh-pages` branch.

A phone browser runs out of memory if it loads the whole game at once, so the web
build comes in parts (`tools/web_packs.py` says what's in each, and `build_web.sh`
keeps the export presets in step with it): a main pack (title, menus, Ashford,
Thornwood), then `packs/movie.pck` (the opening movie), `packs/duel.pck` (the duel
Totems and Summons; the moth and the hounds the films need stay in the main pack)
and `packs/solhaven.pck` (Solhaven's script and anything in a `solhaven/` folder),
each downloaded the first time it's needed, with a loading bar. Code that needs
one awaits it first: `await Packs.need("duel")` (`scripts/game/packs.gd`; it
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
`tools/build_mac.sh` every time `main` changes. Full quality, one pack.

**Play it on an iPhone as an app:** download
https://github.com/fg29cw8knf-wq/covenant-war/releases/download/iphone/CovenantWar-iOS.zip
on a Mac, open `CovenantWar.xcodeproj` in Xcode, choose your Apple ID as the team
and press Run. `docs/iphone.md` has the steps, including for a free Apple ID.
`.github/workflows/iphone.yml` rebuilds it with `tools/build_ios.sh` every time
`main` changes. The app has everything in one pack at full quality: Forward+ (as on
the Mac; Android keeps the Mobile renderer) and ASTC textures.

The story's duels still use the older rules below until the v1 duel is signed off.

## Story mode

The Prologue's first part (P1: Ashford, before midnight) follows Gary's "Master
Script v3" Claude doc word for word (`docs/script/v3_prologue_p1.md` is a copy;
the doc is the master); the parts after it still follow the older "Spoken
Script" until they're rebuilt to v3. The words and talk trees are in
`scripts/world/areas/ashford.gd` (above the films), the staging in
`scripts/world/areas/ashford_p1.gd`.

New Game opens on black and the caption "Ashford / The last night of the Age."
in the inn's attic: the player wakes on the straw bed, goes to the cracked mirror
and chooses their look (`scripts/ui/mirror_picker.gd`: only look A exists, so B,
C and D show as coming soon). In the taproom Bram is stacking paper lanterns into
a crate, the shelves behind the bar bare; he hands the crate over, the player
carries it out of the inn and across to the green with Bram following, and hangs
the last lantern on the Great Lantern's top hook with its hoist. Bram teaches
walking, stopping, using and talking in his own words while the Objective line
names the button for the device in hand (`scripts/ui/world_coach.gd`: phone,
tablet, computer or controller, and it changes if a pad or a keyboard is picked
up), and every step is gated: the pause square only appears when he mentions
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
card box and hands over the first deck when Corin says there isn't one. The
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

Bram, Corin, Tam, Tilly and the player are their 3D models everywhere
(`scripts/world/figure_3d.gd`; Tam and Tilly since 16 October); the other
villagers stay cut-outs until their models exist, and a model dropped into
`assets/models/characters/<id>.glb` is picked up by itself. The models share
one skeleton, so a clip one lacks is borrowed from another and fitted to
their height (Tilly is a child), and `reach()` puts hands on things: Tam and
the player carry the barrel by its ends, Tilly holds her moth's card out in
both hands, Corin leads her up the lane by the hand and holds it on the
riverbank, Tam levels his pitchfork.

The player (look A) is Gary's young man since 17 October, from AssetFurnace
with 21 motion-captured clips. `tools/rig_character.py` turns a rigged
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
tools/rig_player_a.sh <Player_B_Master_21_Animations.glb>
godot --headless --import
xvfb-run -a -s "-screen 0 1024x1024x24" godot --rendering-driver opengl3 --resolution 512x512 res://tools/render_portraits.tscn -- player
godot --headless --script res://tests/clips_check.gd          # everyone can play every clip the story uses
xvfb-run -a -s "-screen 0 800x800x24" godot --rendering-driver opengl3 --resolution 640x640 \
    --script res://tests/model_sheet.gd -- /tmp/sheet player_a  # the model by the cast, and in every clip
```

His own clips besides the game's: sneak, strafe_left, jump, sit,
fight_stance, punch, punch_combo, kick, roundhouse, flying_kick,
sword_swing, kata, hit_react, death, dance, wave and roll (the roll, the
flying kick, the punch combo, the strafe and the death travel as made, so
whoever plays one moves the figure to where it ends).

Everything after the Lantern Duel is a film in the game's own 3D: midnight,
the Sigilfall, the run, the cart, the white light, the Pale Herald at dawn, the taproom,
Ashford burning, the cellar and Bram's decks (`ashford.gd`, parts saved in the
`pro_part` flag so a closed game picks up where it was), then the Thornwood
(`scripts/world/areas/thornwood.gd` on `scripts/world/thornwood_set.gd`): the
riverbank, the campfire and its practice duel, Dask's road duel and dawn over
Solhaven. Films are staged with `scripts/world/cine.gd` (shots, walks,
spawns, reveals) and `scripts/world/cine_overlay.gd` (letterbox, subtitles,
choices, the name prompt, the deck choice). Solhaven
(`scripts/world/areas/solhaven.gd`) is Chapter 1 as a hub: the gate
and its refugees, Bram's wagon and Turnip, Wren, the Sun Court on the temple
steps (Solmaris stops time), the Trial of Light as a duel against Liora, Ser
Aldric at the Circle and Morne's vault to close the chapter. Still to build
from the script: Wren's chase, the mirror puzzle and the Sunspire.

Dialogue portraits for the 3D characters are rendered from their models into
`assets/art/characters/<id>_portrait.png` (the dialogue box uses someone's own
portrait when there is one, else the face for their costume):

```sh
xvfb-run -a -s "-screen 0 1024x1024x24" godot --rendering-driver opengl3 --resolution 512x512 res://tools/render_portraits.tscn
```

To watch a film part by itself, tapping through every line (`corin`, `midnight`,
`dawn`, `taproom`, `burning`, `cellar`, `river`, `camp`, `road`, `ridge`):

```sh
xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 960x540 --fixed-fps 10 \
    res://tests/film_test.tscn -- /tmp/film midnight 30 keys     # a still every 3 s and one per line
godot --headless --fixed-fps 10 res://tests/film_test.tscn -- /tmp/film river   # just run it
godot --headless --fixed-fps 10 res://tests/film_test.tscn -- /tmp/film corin 0 only read=25 trace   # lines left up as a player reads them, with where Bram is
```

Tam's barrel is carried to the stall and Tilly's Lantern Moth flies (its wings
beat through `scripts/world/wing_flap.gd`, which also flaps the moth in duels);
the Great Lantern (Gary's model) is lit at midnight. The lantern crate is Gary's
model (`assets/models/ashford/crate.glb`, its lid left off so the lanterns show)
once it's there, and a drawn crate until then.

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
godot --headless res://tests/lantern_sim.tscn -- 0.3 0.25 200            # Lantern Duel balance, as the story plays it
godot --headless res://tests/lantern_sim.tscn -- 0.3 x 300 rematch       # the rematch you can lose
```

## Menus, standing, items and adverts

- **Opening notice** (`scripts/ui/notice_screen.gd`): who made and owns the game and Gary's note about adverts, shown at launch before the title. The title screen carries "Made by Gary Mannion" and the copyright line.
- **Pause menu** (`scripts/ui/pause_menu.gd`, ☰ or Esc in the world): Hero (Sigil Rank, Seals, the seven attributes with their 7+ perks and points to place), Standing, Deck (edit it; only a legal deck is kept), Codex, Items, Controls (phone, tablet, computer, controller; opens on the device in use) and Options (volumes, text speed, violence, 3D field, advert previews, save, quit).
- **New Game starts with no cards.** Deck and Codex aren't in the pack until the story opens them: `Game.give_first_deck(cards)` hands over Bram's 12-card Spark deck (shown on the Deck tab, not editable), `Game.unlock("deck")` / `Game.unlock("codex")` add the tabs (the world toasts "New in your pack: Deck and Codex"), and `await hud.pack_tour()` runs a gated tour of the pack (`scripts/ui/pack_tour.gd`, lines in `PackTour.FIRST_DECK`, styled like the duel's tutor; kept on How to Duel under *Your pack*). Master Script v3 has no lines for that tour and opens the deck screen first at the campfire, where the player chooses a deck, so the Lantern Duel no longer plays the tour or opens the tabs: Bram hands over the Spark deck (its twelve cards fanned out on screen) and Deck and Codex stay shut in Ashford. Bram's 30-card deck from the cellar (flag `bram_deck`) is the first one the player can edit; old saves past Ashford have everything open.
- **Codex** (`scripts/ui/codex.gd`): every card the player has found (their own, and cards seen played, greyed out until owned; nothing else is listed), with a detail view: the painting, description, attacks with their Fate bands, how to get it (Resonance), and the Attunement bar towards its Ascended form, with Re-absorb and Pour buttons.
- **Standing** (`scripts/game/standing.gd`): how each god and person sees the player, -10 to +10. Story choices already recorded as flags count through `FLAG_EFFECTS`; a dialogue step `{"standing": {"tilly": 1}, "why": "..."}` nudges it directly, and `{"if": "standing:solmaris>=2"}` branches on it. A toast says "Tilly will remember that."
- **Items** (`scripts/game/items.gd`): story items shown from flags, and equipment in three slots (charm, ring, deck case) that adds to attributes in every duel. A dialogue step `{"item": "<id>"}` gives one.
- **Adverts** (`scripts/game/ads.gd`, autoload `Ads`): one full-screen advert at most every 3 story duels and 5 minutes (never in the Prologue, never mid-duel), retries always free, and an optional advert after a story win that doubles its Resonance (3 a day). Until the AdMob plugin (poingstudios/godot-admob-plugin) is added to the iOS and Android exports, a labelled placeholder shows where each would play; Options turns previews off.

Ashford's cottages, the Crooked Lantern, the windmill (its sails turn until the thatch catches at midnight) and the oaks round the village are Gary's models (`assets/models/ashford/`; an `oak_b.glb`, `oak_c.glb`... is used alongside `oak_a` as soon as it's there); each has a `<id>_glow.png` window mask made from its colour atlas, so the windows light up at night. Missing models fall back to the drawn stand-ins.

```sh
xvfb-run -a -s "-screen 0 2560x1600x24" godot --rendering-driver opengl3 res://tests/menu_test.tscn -- /tmp/menu 1600x900   # every menu tab, card detail, notice, advert
xvfb-run -a -s "-screen 0 2560x1600x24" godot --rendering-driver opengl3 res://tests/pack_tour_test.tscn -- /tmp/tour 1600x900   # Bram's pack tour, tap by tap
xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 res://tests/village_shot.tscn -- /tmp/village       # Ashford's buildings and the roof fire
xvfb-run -a -s "-screen 0 1280x720x24" godot --resolution 1280x720 res://tests/props_shot.tscn -- /tmp/props [thornwood]   # the windmill (turning, then burning) and the oaks
godot --headless res://tests/controls_test.tscn          # every line of the Controls page, pressed for real (keys, pad, mouse); also runs under xvfb-run
```

## Running the tests

```sh
godot --headless --import                                   # first time only
godot --headless --script res://tests/sim.gd -- 2000        # every deck vs every deck
godot --headless --script res://tests/sim.gd -- 900 emberstorm tidegrove ironstone
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

## Opening movie clips

The opening movie plays each shot's painting with a slow camera move, or a video
clip where one exists. To add clips made with an image-to-video tool, name them
after their shots (`shot_08.mp4`) and run:

```sh
python3 tools/movie_clips.py <folder of clips>     # -> assets/movies/shots/<shot>.ogv, trimmed to each shot
```
