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
way, by Bram, at any duel he's at (Master Script v3: the practice round and Dask's
road duel): the first condition or boon to land on either side (`fx_status`,
which also gives it a Codex entry under *Conditions*), the first Ward set or
sprung, the first hit on a weakness, a Guardian, a Gift, a Summon, and the first
time an Ascension can be played. A duel with `spec.lessons = true` gets a tutor
just for these one-off lessons (`DuelTutor.lesson()`); each is taught once ever
(`Game.learn()`), and every line Bram has given is kept, in order, on the pause
menu's **How to Duel** page.

Story duels (Master Script v3) each have a rule of their own that says who the
opponent is, as a real rule in the engine: `spec.story_rules = {rule id: side}`
(`DuelGame.story_rules`, one `_rule_<id>()` each) and `spec.rule = [name, text]`
for its banner, shown after "DUEL!". The Prologue's: Dask's Run to Ground (his
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

The rules are written up in the "Duel Rules v2" Claude doc, and the story in the
"Master Script" doc. The Duel Lab's Kingdom Law picker plays any duel under a
god's Law.

**Play it on a phone:** https://fg29cw8knf-wq.github.io/covenant-war/ (turn the phone sideways; in
Safari use Share > Add to Home Screen for a full-screen app icon). Rebuild it with `tools/build_web.sh`
and push `build/web` to the `gh-pages` branch.

**Edge to edge on a phone.** The game fills any screen shape (an iPhone 16 Pro Max
held sideways is 2.17:1): the 1920 x 1080 base stretches sideways (`canvas_items` +
`expand`), the opening movie's paintings and clips fill the screen (cropping a
little top and bottom, `OpeningMovie.frame_rect()`), and the duel's 3D field
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
Skip button too, since nobody should sit through its download to skip it:
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
`tools/build_mac.sh` every time `main` changes. Full quality, one pack.

**Play it on an iPhone as an app:** download
https://github.com/fg29cw8knf-wq/covenant-war/releases/download/iphone/CovenantWar-iOS.zip
on a Mac, open `CovenantWar.xcodeproj` in Xcode, choose your Apple ID as the team
and press Run. `docs/iphone.md` has the steps, including for a free Apple ID.
`.github/workflows/iphone.yml` rebuilds it with `tools/build_ios.sh` every time
`main` changes. The app has everything in one pack at full quality: Forward+ (as on
the Mac; Android keeps the Mobile renderer) and ASTC textures.

Every story duel is on the v2 duel now; the older rules below (`scripts/core/`, `BattleScreen`) are only what `Main.run_duel` falls back to for a spec without decks.

## Story mode

The Prologue's first part (P1: Ashford, before midnight) follows Gary's "Master
Script v3" Claude doc word for word (`docs/script/v3_prologue_p1.md` is a copy;
the doc is the master); the parts after it still follow the older "Spoken
Script" until they're rebuilt to v3. The words and talk trees are in
`scripts/world/areas/ashford.gd` (above the films), the staging in
`scripts/world/areas/ashford_p1.gd`.

New Game opens on black and the caption "Ashford / The last night of the Age."
in the inn's attic, then the dream the player is about to tell Bram about
(`CineOverlay.dream_sky()`, `AshfordP1.DREAM_SECS`, 0 turns it off): the night
sky as it's seen from the bed, full of stars, until a white light climbs from
the bottom of it and puts them out one by one, and there's nothing left but
white (the Sigilfall, before it happens), cut to black on the drum. The player
wakes in the bed (an oak cot with a straw mattress, a pillow and a wool
blanket, `InnRooms._bed()`; Gary's own model takes its place from
`assets/models/ashford/attic_bed.glb` when it exists), lying on top of the
mattress with his head up on the pillow (`Figure3D.lie_on()`: the body tipped
up a little at the head end, `LIE_HEAD_UP`, the feet lolling, `LIE_FOOT_DROP`),
puts a hand down on the mattress and pushes himself up on it, slowly, the
blanket sliding back, swings his legs over the side and turns to sit on the
edge, sits a moment and stands (`sit_long()`, `sit()` with `shift_seat()`,
`stand()`, and `reach()` for the hand: poses built on the model's own idle,
blended one into the next; `tests/bed_check.tscn` takes stills of it from the
side and the foot of the bed), goes to the cracked mirror and chooses their
look (`scripts/ui/mirror_picker.gd`: four since 20 October, A Gary's first
young man, B his second, C the young woman in green, D the bearded man;
`assets/models/characters/player_<letter>.glb`, `tools/rig_player.sh`, and
the look chosen is the `look` flag, which `Figure3D.model_file("player")`
and `DollArt.portrait("player")` read, so the player and their dialogue
face are that look from then on; a look whose model isn't there yet would
show as coming soon). In the taproom Bram is
stacking paper lanterns into a crate, the shelves behind the bar bare; he hands
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
Nell since 18 October, Hob since 19 October, and Bram Gary's own AssetFurnace
model, in place of the 11 October stand-in, since 20 October); the other villagers (Ned, the
crowd) stay cut-outs until their models exist, and a model dropped into
`assets/models/characters/<id>.glb` is picked up by itself. A cut-out always
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
godot --headless --script res://tests/clips_check.gd          # everyone can play every clip the story uses, and sit
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

Corin, Tam, Tilly and Old Nell are Gary's 18 October AssetFurnace models,
Hob his 19 October one and Bram his 20 October one, built the same way by
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
sit, wave, cheer, dance, kick, punch and death; Nell jump, sit, wave, cheer,
dance, punch and death. Their rigs are smaller than the player's: Tam's and
Nell's hands are a thumb and the fingers as one, Tilly's a thumb and two
groups, and Nell has 29 bones in all. Nell's walking stick is part of her
mesh, in her right hand, so that arm stays as in her idle when she talks,
cheers, walks or runs. Tilly's leather satchel hangs by her left hand, so
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

Everything after the Lantern Duel is a film in the game's own 3D, line for line
from Master Script v3 (a copy is in `docs/script/v3_prologue_films.md`): midnight,
the Sigilfall, the run, the cart, the white light, the Pale Herald at dawn (its
lantern shows the Champions it doesn't read out), the taproom, Ashford burning
(Krell's terms, Tam's lie), the cellar and the tunnel (`ashford.gd`, parts saved
in the `pro_part` flag so a closed game picks up where it was), then the
Thornwood (`scripts/world/areas/thornwood.gd` on `scripts/world/thornwood_set.gd`):
the riverbank, the campfire (Bram's four decks on a log, tap a box to see it and
again to choose, `scripts/world/deck_boxes.gd`, then his walk round the deck
screen, `PackTour.CAMP_DECK`), the practice round on the second morning, Dask's
road duel and dawn over Solhaven. Films are staged with `scripts/world/cine.gd`
(shots, walks, spawns, reveals) and `scripts/world/cine_overlay.gd` (letterbox,
subtitles, choices, the name prompt). The Herald's voice plays from
`assets/audio/vo/herald_NN.ogg` (01, 02, 03, 09, 10, 12, 13, Gary's recordings
since 20 October; .wav or .mp3 work too) and the Champions' faces from
`assets/art/champions/<id>.png` or `.jpg` (aldric, vorn, eiran, rook, silk,
maelis, crane; Vorn, Eiran and Rook are Gary's paintings since 20 October) once
they exist; until then the lines are subtitles and each face is its Seat's sign.

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
Step-by-Step") and his people (`assets/models/characters/<id>.glb`: hale,
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
frame's dark blue, until their models exist and can be rendered:

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
godot --headless res://tests/lantern_sim.tscn -- 0.3 0.25 200            # Lantern Duel balance, as the story plays it
godot --headless res://tests/lantern_sim.tscn -- 0.3 x 300 rematch       # the rematch you can lose
```

## Menus, standing, items and adverts

- **Opening notice** (`scripts/ui/notice_screen.gd`): who made and owns the game and Gary's note about adverts, shown at launch before the title. The title screen carries "Made by Gary Mannion" and the copyright line.
- **Pause menu** (`scripts/ui/pause_menu.gd`, ☰ or Esc in the world): Hero (Sigil Rank, Seals, the seven attributes with their 7+ perks and points to place), Standing, Deck (edit it; only a legal deck is kept), Codex, Items, Controls (phone, tablet, computer, controller; opens on the device in use) and Options (volumes, text speed, camera zoom and its reset, text and buttons size, violence, 3D field, advert previews, save, quit).
- **Camera zoom** (`World.zoom_by()`, saved as `cam_zoom` in the settings): in the world on foot, pinch with two fingers, the mouse wheel or a trackpad, the + and - keys, a pad's right stick, or the small + and - buttons at the right edge. The camera glides closer or further along its usual line (`World.ZOOM_MIN` to `ZOOM_MAX`) and stops in front of any wall, roof or tree it would otherwise end up inside (`World._clear_way()`). Films own the camera: no zooming while one runs, and the player's zoom is back when it ends. In a duel, the wheel or a pinch zooms the 3D field a little (`DuelField3D.VIEW_MIN` to `VIEW_MAX`, saved as `duel_view`).
- **New Game starts with no cards.** Deck and Codex aren't in the pack until the story opens them: `Game.give_first_deck(cards)` hands over Bram's 12-card Spark deck (shown on the Deck tab, not editable), `Game.unlock("deck")` / `Game.unlock("codex")` add the tabs (the world toasts "New in your pack: Deck and Codex"), and `await hud.pack_tour()` runs a gated tour of the pack (`scripts/ui/pack_tour.gd`, lines in `PackTour.FIRST_DECK`, styled like the duel's tutor; kept on How to Duel under *Your pack*). Master Script v3 opens the deck screen first at the campfire, where the player chooses a deck, so the Lantern Duel doesn't play the tour or open the tabs: Bram hands over the Spark deck (its twelve cards fanned out on screen) and Deck and Codex stay shut in Ashford. Bram's 30-card deck, chosen at the campfire on the Thornwood road (flag `bram_deck`), is the first one the player can edit; old saves past Ashford have everything open.
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
- **Hale's Orders** (only if Hale opened the gate to everyone, once you know he's been stripped of his command): the barracks yard at noon; stand with him, or a wager with the Captain of the Sun Guard (rule *Discipline*: her Totems can't be Burned, Poisoned or Frozen). The lashing follows the violence setting.

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

The opening movie (`scripts/story/opening_movie.gd`) follows the "Opening movie"
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
