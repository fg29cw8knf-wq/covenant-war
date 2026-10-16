# Gary's audio of 16 October 2026, not yet installed

Install these the way the earlier ones were (see the header comments of
scripts/ui/music.gd, scripts/ui/sfx.gd, tools/music_loop.py, tools/web_music.py,
assets/audio/source/README.txt and assets/sfx/PUT_SOUNDS_HERE.txt), then delete
this folder.

music/
- arena_emberforge, arena_solhaven, arena_tidegrove: looping duel music, one per
  arena (duel_screen.gd plays "arena_<name>" in place of the duel theme when it
  exists). Seamless bar-aligned loops (LOOP_START in music.gd, tests/loop_probe.gd),
  levelled to duel_main/duel_alt.
- summon_grondmaw: the Summon stinger for Grondmaw. Trim, fade and level it like
  summon_pyraxis / summon_somnara / summon_thalassa (about 8.5 s).

sfx/
- dice_roll, dice_land, dice_crit, dice_fumble (the Fate dice, duel_screen.gd),
  summon_boom, gift, and the film's bell_toll (plays six times as the bell counts
  twelve), sigil_strike and cart_crash, which replace the synthesised stand-ins
  already in assets/sfx. Trim leading silence, level them with their neighbours.
