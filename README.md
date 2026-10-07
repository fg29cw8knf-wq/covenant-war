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

## The Duel Lab (new duel rules, v1)

The card battle is being rebuilt to the v1 rules (three Totem slots a side,
Life, Essence, Fate dice, Wards, Ascension). It lives in its own folders and
can be played from the title screen's **Duel Lab** button, or straight away with:

```sh
godot -- --lab
```

| Folder | What's in it |
| --- | --- |
| `scripts/duel/` | The v1 rules engine: every tunable number (`duel_rules.gd`), the cards and starter decks (`duel_cards.gd`), the duel itself (`duel_game.gd`) and the computer duellist (`duel_ai.gd`). No graphics code. |
| `scripts/duel_ui/` | The Duel Lab set-up screen, the duel screen, card faces and the pieces they're built from. |

```sh
godot --headless --script res://tests/duel_sim.gd -- 2000            # balance: every deck vs every deck
godot --headless --script res://tests/duel_sim.gd -- 2000 --cards    # plus win rate when each card is played
godot --headless --script res://tests/duel_log.gd -- emberstorm veilwild 3   # the full log of one duel
godot --headless res://tests/duel_monkey.tscn -- 6                   # random taps through the duel screen
```

**Play it on a phone:** https://fg29cw8knf-wq.github.io/covenant-war/ (turn the phone sideways; in
Safari use Share > Add to Home Screen for a full-screen app icon). Rebuild it with `tools/build_web.sh`
and push `build/web` to the `gh-pages` branch.

The story's duels still use the older rules below until the v1 duel is signed off.

## Story mode: Ashford

New Game starts the Prologue in Ashford, the player's village, on the last
night of the Age (`scripts/world/areas/ashford.gd`): Bram's errands, the Lantern
Duel against Corin on the v1 rules, then midnight, the Sigilfall and the
marking, before the rest of the Prologue plays as story scenes and the player
arrives in Solhaven. The village itself (`scripts/world/ashford_village.gd`) is
built from the look test in `lookdev/ashford`, with lighter settings on the
phone and web renderers. Its shaders live in `assets/shaders/village/`.

```sh
xvfb-run -a godot --resolution 1280x720 --fixed-fps 8 res://tests/ashford_test.tscn -- /tmp/ash 24            # play it all, with screenshots
xvfb-run -a godot --resolution 1280x720 --fixed-fps 8 res://tests/ashford_test.tscn -- /tmp/ash 10 midnight   # just the duel and midnight
godot --headless --script res://tests/lantern_sim.gd -- 80 1.0 0.25                                          # Lantern Duel balance
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
