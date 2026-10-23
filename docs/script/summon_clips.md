# Summon clips: what to make, by card

For Gary (23 October): the game plays a clip of yours when a card is summoned or a Totem is called, the first time the long one, every time after the short one (or always short, or none: Options, and the duel's Menu). The engine side is in (`scripts/duel_ui/summon_video.gd`); the clips are yours to make, in the order below. A card with no clip keeps the drawn summon scene it has now.

## How to name and deliver them

- Two clips a card: `<card id>_full` (8 to 12 seconds) and `<card id>_short` (2 to 3 seconds). The card id is the file name of its painting in `assets/art/cards/` (the list below gives each).
- Make them as you make the films: 16:9, your master as `.mp4`. Put the masters on the repository's **films** release (the apps carry them and play them at full size through the phone's own player, as the opening does). For the phone link, a Theora copy of each goes in the game folder as `assets/movies/summons/<card id>_full.ogv` and `_short.ogv`, made with the line in the README:
  `ffmpeg -i <card id>_full.mp4 -vf "scale=1280:720:flags=lanczos,fps=30" -c:v libtheora -b:v 3000k -c:a libvorbis -q:a 5 assets/movies/summons/<card id>_full.ogv`
- Sound on the clip is fine: the music dips while it plays. A tap skips it, so the first second should already be the creature, not a title.
- The short one is the long one's best two seconds: the arrival, not the build-up.

## What each should show

The long clip: where it comes from (the sky scene its card already has for the four Summons), the creature arriving, one beat of it looking at the duel, and its first blow or its stance. The short clip: it arrives and strikes.

### The four Demigod Summons (first)

- `pyraxis` · **Pyraxis, Heart of the Pyre** (fire, Demigod): the sky scene from its card, the god's piece coming down into the arena, one great blow.
- `thalassa` · **Thalassa, the Deep Mother** (tide, Demigod): the sky scene from its card, the god's piece coming down into the arena, one great blow.
- `grondmaw` · **Grondmaw, the Mountain's Heart** (earth, Demigod): the sky scene from its card, the god's piece coming down into the arena, one great blow.
- `somnara` · **Somnyx, the Dreaming Veil** (psychic, Demigod): the sky scene from its card, the god's piece coming down into the arena, one great blow.

### Every starter Totem, by deck

The Spark and Glimmer Totems a new player calls in the Lantern Duel, Bram's duel by the fire and Dask's road: these play on every call, so keep them to the lengths above and let the short one be very short.

**Emberstorm**

- `cinderpup` · **Cinderpup** (fire, Spark)
- `blazehound` · **Blazehound** (fire, Glimmer)
- `emberwisp` · **Emberwisp** (fire, Spark)
- `hearth_salamander` · **Hearth Salamander** (fire, Spark)
- `ashen_drake` · **Ashen Drake** (fire, Crystal)
- `sparkkit` · **Sparkkit** (storm, Spark)
- `voltlynx` · **Voltlynx** (storm, Glimmer)
- `thunder_ram` · **Thunder Ram** (storm, Glimmer)
- `stormcaller` · **Stormcaller Heron** (storm, Crystal)

**Tidegrove**

- `brookfin` · **Brookfin** (tide, Spark)
- `riptide_serpent` · **Riptide Serpent** (tide, Glimmer)
- `deepmaw` · **Deepmaw Leviathan** (tide, Crystal)
- `shellguard` · **Shellguard** (tide, Spark)
- `mossling` · **Mossling** (verdant, Spark)
- `thornwarden` · **Thornwarden** (verdant, Glimmer)
- `bloomsprite` · **Bloomsprite** (verdant, Spark)
- `elderbark` · **Elderbark** (verdant, Crystal)

**Ironstone**

- `pebblit` · **Pebblit** (earth, Spark)
- `boulderox` · **Boulderox** (earth, Glimmer)
- `burrowmole` · **Burrowmole** (earth, Spark)
- `quarry_golem` · **Quarry Golem** (earth, Crystal)
- `brassback` · **Brassback** (metal, Spark)
- `ironhide` · **Ironhide Warbeetle** (metal, Glimmer)
- `shieldhound` · **Shieldhound** (metal, Spark)
- `gilded_sentinel` · **Gilded Sentinel** (metal, Crystal)

**Veilwild**

- `dreamfox` · **Dreamfox** (psychic, Spark)
- `veilfox` · **Veilfox** (psychic, Glimmer)
- `somnowl` · **Somnowl** (psychic, Spark)
- `thought_eater` · **Thought Eater** (psychic, Crystal)
- `blightrat` · **Blightrat** (venom, Spark)
- `plague_asp` · **Plague Asp** (venom, Glimmer)
- `mirewidow` · **Mirewidow** (venom, Spark)

## Later

Every other Totem, by the order the player meets them: Dask's Ironvault Hounds, then Chapter 1's. Ascended forms (Blazehound and up) can share the long clip of their first stage with a different ending, if that saves work.
