# Work brief, 22 October 2026 — branch `wip/assets-22oct`

For a claude.ai/code session on this repo. Gary owns the game and is
non-technical: write to him in plain, short English. Read `README.md` first,
then `docs/handover/2026-10-20-late.md` and `2026-10-18.md` (one session at a
time, ask before anything big). Keep the one to-do list, Gary's Claude doc
"Still to Make: The Covenant War", current: tick what lands, add what's new in
the section where the player meets it.

Everything Gary sent tonight is in `incoming/assets-22oct/` (a `.gdignore` keeps
Godot out of it). Move each thing into its proper place as you do it, and
delete `incoming/` at the end. Work in play order below; commit as you go; when
it's all in, merge to `main`, build and publish the web build (gh-pages) so the
phone link and the iPhone zip pick it up, and write `docs/handover/2026-10-22.md`.

## 1. The finished opening movie (`incoming/assets-22oct/opening_movie/opening.ogv`)

Gary has cut the whole opening as one film: his animated clips, Morrowen's
narration, the music and the **subtitles already burnt in**, 3:12 long (longer
than the engine's 2:24 shot table — his clips run longer). It was converted
from his 4K 60 fps HEVC master to Ogg Theora 1600x900, 30 fps, q5, with Vorbis
stereo. His 4K master stays on his Mac (`The_Covenant_War_4K_60fps_Smaller_HEVC.mp4`)
if a different size is ever needed.

`OpeningMovie` (`scripts/story/opening_movie.gd`) already prefers a finished
cut at `res://assets/movies/opening.ogv` (`_play_full_cut`), but it was written
for a cut *without* words on screen, so before moving the file into place:

- No engine subtitles over it (`_tick_lines` must not draw lines while the
  cut plays — his are in the picture).
- No engine music or voice over it (`_music.play()` runs before the cut is
  chosen; the cut has its own music and narration).
- The title, `white_word` and `streak` effects are shot-table effects: his cut
  has the title in it at ~3:04, so none of those fire over the cut.
- Skip (tap to show Skip) still works; on the cut's end: the v3 cut to black
  and the attic as now. The web pack `movie` (`tools/web_packs.py`) must carry
  the .ogv and nothing it no longer needs (the 21 still paintings can stay
  as the fallback if the file is missing, as the comment in the script says).
- Check it plays on the phone link (Safari) and in the iOS build: Theora
  decode at 1600x900 is the known-good path from `tools/movie_clips.py`.
  If it stutters on iPhone, re-encode smaller from the .ogv is lossy — ask Gary
  for the master instead.
- `tests/movie_shot.tscn` must still pass (it checks the shot-by-shot path).

## 2. First launch sticks (iPhone, and the last build too)

Gary: "the first time launching the game it sticks, I have to close and reopen
it; it did that with the last version as well." Second launch is fine. That
pattern fits first-run shader/pipeline compilation (Metal) plus the Ashford
build that now runs under the title screen (`Main`, 20 Oct handover: "first-time
shader hitches on iPhone" is an open item). Find the actual freeze: reproduce
on a cold install (delete the app, reinstall from the zip, or clear the
shader cache), log where the main thread stops. Then fix it so a first launch
never looks hung: pre-warm the shaders behind a visible loading state
(Godot 4.7: `rendering/shader_compiler/shader_cache`, pipeline precompilation
/ ubershader settings), and make sure nothing waits on the Ashford background
build before the notice and title can draw and take input.

## 3. The opening notice still goes by itself

Gary: "the opening message cuts without me clicking Continue; it should stay on
screen until Continue is pressed." The 20 Oct fix (`scripts/ui/notice_screen.gd`:
no timer, no tap-anywhere) may simply not have been in the build he played —
check the iOS zip's build date against commit 4995ab6. But also make sure
nothing else dismisses it: a touch held over from the splash arriving as a
press, the Ashford build finishing and moving `Main` on, or a pad/key event
on a phone. Test on the web link on a phone and in the iOS build.

## 4. Mirror: see each look, then confirm

Gary: "When you look in the mirror you should be able to select and see the
look of each player, then confirm the one you want." Now (`scripts/ui/
mirror_picker.gd`) a tap on a face chooses it at once. Change it to:

- Tap a face: that look appears **in the glass** — the actual model
  (`player_<look>.glb`), head and shoulders or full figure, lit as the attic
  is, idle clip playing (a SubViewport in the mirror, or swap the real figure
  in front of the mirror and let the glass show it). Tapping another face
  shows that one instead. The face row shows which is up.
- A Confirm button/line in the game's dialogue style ("That's me." or the
  like, in brackets if it's an instruction: Gary's rule is on-screen
  instructions go in brackets so the fourth wall isn't broken) locks it in;
  then as now: `Game.set_flag("look", ...)`, `Packs.need("looks")` on the
  phone link, `World.swap_player_look()` behind the fade.
- Still gated: nothing else moves on until a look is confirmed. Keys/pad: left
  and right move the preview, Enter/E/Space/A confirms.
- `tests/ashford_test.gd` (`opening look=<letter>`) must still play through.

## 5. A better bed in the attic

Gary: "if we haven't added already, need to put a better bed in the opening."
The attic bed is still the geometry rebuilt on 20 Oct (`ashford_p1.gd` `_attic`
/ `AshfordVillage`), and "the attic bed model and a wake-up clip" is an open
item for Gary in the to-do doc. Until his model comes, make the in-engine bed
properly good: a wooden frame with head- and footboard, a mattress with a
visible sag, a rumpled blanket and a pillow, with the wood and cloth materials
the village already has (`LevelKit` / `AshfordVillage.mats`), and the lie-down,
sit-up and stand-up poses fitted to its real height so nobody sinks through it.
Pick up `assets/models/ashford/bed.glb` automatically if it ever appears, as
the crate and the Great Lantern are picked up. Tell Gary it's in-engine for now.

## 6. The dream: a fade to white, not a jump

Gary: "when he dreams about the sky turning white it's not clear that's what's
happening — the screen just goes white; a fade to white would work better."
This is `CineOverlay.dream_sky()` (`scripts/world/cine_overlay.gd`, called from
`ashford_p1.gd` `opening`, `DREAM_SECS`). On a phone the stars read as near
black, so it looks like black → white. Make it read: the night sky clearly
seen first (brighter, bigger stars, a thin moon or the attic window's frame
round it so it's plainly the sky from the bed) for about two seconds, then a
smooth, even fade to white over about 2.5 s (not a front rising from the
bottom), a beat of pure white, then the cut to black on the drum as now.
Keep Bram's "I dreamt about the sky again" line making sense of it.

## 7. Bram floats to the Lantern instead of walking

Gary: "when going over to do the lanterns, Bram doesn't walk, he floats."
`ashford_p1.gd` `_green()`: `Cine.path(w, "bram", round_lantern(...), 1.6)`
after `(bf as Figure3D).release(0.0)` off his stool. `Cine.path` sets
`walking = true`, `gait` and `pace`, so find why his walk clip isn't playing
(the release from the sit pose, a held pose, his own clips' names, the
AnimationPlayer left stopped) and fix it wherever `Cine.path` moves a
`Figure3D`, not just here. Also the known "Bram glides 0.5 m onto his stool"
(`bram_to_stool`). Feet should match the ground speed.

## 8. The crate goes down into the floor, and the player stands on it

Gary: "when the player puts down the lanterns he is standing on top of them,
like they are part of the floor." Same scene, `_green()`: the crate is tweened
to `crate_at = p + to_c * 0.62` with `crate_at.y = v.height(...)`. Check the
crate node's origin (if it's the model's centre, half the crate sinks into the
grass and only the lanterns' tops show, which is what Gary describes) and the
distance: 0.62 m from the player's centre puts the crate's edge at his feet.
Set it down a full stride in front, base on the ground, lanterns standing up
in it, and the camera for the moment showing the crate on the grass with the
player's feet clear of it. Same check for the crate wherever else it's put
down (the taproom stack, `_stack`).

## 9. Dialogue: several questions in a conversation

Done on 20 Oct (`World._ask`: `{"ask": [...], "then": [...], "leave": ...}`;
the "choice" step stays for a plain answer with two ways). Gary has asked
for it again, so either it wasn't in his build or some conversations are
still single-pick that shouldn't be. Walk every talk tree in `ashford.gd`,
`ashford_p1.gd`, `solhaven.gd`, `solhaven_side.gd`, `thornwood.gd`: anything
where the player is choosing *what to ask* becomes an `ask` list (the
unasked ones come back after each answer, a leave line last); only a real
"someone asks you a question, pick one of two answers" stays a `choice`.
Story forks (`Cine.choose`, the side stories' decisions) stay as they are.

## 10. The breather line names the menu

Done on 20 Oct (`{menu}` in Bram's line at the door → "(Tap the three lines at
the top right of the screen to open the menu.)" on a phone). Gary has asked
again, so verify it shows in the phone build and reads as a bracketed
instruction, not Bram's voice; the same `{menu}` treatment anywhere else the
player is told how to do something.

## 11. Aldric's face (`incoming/assets-22oct/aldric/aldric_source.png`)

Gary's painting of Ser Aldric, Solmaris's champion: blond, bearded, golden
sun-armour, hands clasped in prayer in a sun-lit chapel. Make
`assets/art/champions/aldric.jpg` (768 px, same crop and import settings as
`crane.jpg`, `maelis.jpg`, `silk.jpg`) so the Champions of the Turning no
longer show the Seat's sign for him; and a dialogue portrait if his lines in
Solhaven use one (`assets/art/characters/aldric_portrait.png`, head and
shoulders on the frame's dark blue, like `ned_portrait.png`). Keep the source
in `lookdev/refs/aldric_sheet.jpg`.

## 12. Three villager models: farmer, merchant, trader

`incoming/assets-22oct/{farmer_model,merchant_model,trader_model}/`: AssetFurnace
masters with 21 clips each (idle original; walk, run, sneak, strafe_left,
jump, sit, fight_stance, punch, punch_combo, kick, roundhouse, flying_kick,
sword_swing, kata, hit_react, death, cheer, dance, wave, roll). Read each
folder's `Integration_Notes.txt` and `Animation_Manifest.csv`:

- farmer = New_Character_01, 52-joint rig, clips retargeted from Player B;
- merchant = New_Character_02, **34-joint rig** (Tam's hierarchy; 10 clips from
  Tam's library, 10 cross-rig from Player B with fingers dropped) — red
  waistcoat, gold trim, beard (`incoming/.../merchant_images/` are his sheets);
- trader = New_Character_03, 52-joint rig, from Player B — brown waistcoat,
  beard (`trader_images/`).

These are the four crowd looks the game draws as cut-out dolls
(`scripts/world/doll_art.gd` LOOKS: farmer, merchant, trader, refugee), used
by the Lantern Night crowd (`ashford.gd` CROWD v1–v10), the P1 dancers
(`ashford_p1.gd` DANCERS) and Tam's `"look": "farmer"`. Rig them with
`tools/rig_villager.sh` / `tools/rig_character.py` as Hob and Corin were →
`assets/models/characters/farmer.glb`, `merchant.glb`, `trader.glb`, heights
to match the cast (`Figure3D.OWN_GAIT` paces from their own walk/run), and
make the crowd and dancers use a 3D figure wherever a look has a model, the
doll only where it hasn't (refugee, courtier, the children). Tam keeps his
own model. Run `tests/clips_check.gd` and `tests/model_sheet.gd` on each;
look at the sit, dance and wave clips especially on the merchant's 34-joint
rig. Portraits only if any of them ever speak.

## 13. The refugee woman (`incoming/assets-22oct/refugee_images/`)

Front, side and back turnaround sheets of the travel-worn woman in the grey
dress and shawl — the `refugee` look, and the refugee woman with the sleeping
boy at Solhaven's Golden Gate (`refugee_b` / `refugee_c` in the Solhaven
cast). No model yet: Gary generates the model from sheets like these, so
expect `refugee.glb` next. For now: a dialogue portrait for the refugee woman
who speaks at the gate from the front sheet (`assets/art/characters/
refugee_portrait.png`), the sheets into `lookdev/refs/refugee_sheet.jpg`, and
leave the `refugee` doll look as the stand-in.

## 14. The Golden Gate of Solhaven (`incoming/assets-22oct/solhaven_golden_gate/`)

`golden_gate_solhaven.glb` (11 MB, 31k triangles, one 4096 colour atlas, two
materials: limestone and gilding; `README.md` and `mesh_validation.json`
alongside, plus front/rear/detail/preview renders). Real size 24.0 m wide ×
4.9 m deep × 16.2 m high; arch 5.7 m wide, 7.1 m to the crown; no doors, no
ground plane; Y up, faces +Z, pivot at ground level centred on the gateway.

`SolhavenSet` picks up `assets/models/solhaven/golden_gate.glb` and fits it to
`size = Vector3(16.0, 0, 0)` (`_build_gate`, `model()`), i.e. scales it to
16 m wide — decide whether the square's south wall (z = 25, the 8 m way in,
the city wall either side, `gate_doors`) takes it at its real 24 m or needs
the fit, and move the walls/road to match so the arch lines up with the way
in. The gate's own collision is "its towers: keep the way through open" —
rebuild that for this mesh (arch 5.7 m clear). The two door leaves
(`gate_door.glb` is still a stand-in) hinge in the arch: keep `open_gate()`
working at the arch's real width. The web pack for Solhaven must carry it;
the 4096 atlas may want the import's VRAM compression. Play the Golden Gate
film (`tests/solhaven_test.tscn -- <dir> keys`) and look at the stills from
the road (`SPOTS.road`) and from inside the square.

## Then

- `docs/handover/2026-10-22.md`: what landed, what's open, in the usual form.
- The to-do doc: tick the opening movie as one film, Aldric's face, the three
  villager models and the Golden Gate; add the refugee model (Gary) and the
  bed model (Gary) if they're not there.
- Delete `incoming/` and this `BRIEF.md` on the merge to `main`.
