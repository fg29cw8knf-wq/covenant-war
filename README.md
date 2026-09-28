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
| `assets/art/` | Card illustrations, characters and scenery (see `docs/art-prompts.md`). |
| `assets/sfx/` | Sound effects. |
| `docs/` | Art prompts and design notes. The full story and world guide lives in the project's Claude doc. |

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
