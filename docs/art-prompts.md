# Art guide — The Covenant War

Everything the game needs from image AIs, and how to make it look like one game
rather than fifty different ones.

## The golden rule: one look

Pick **one** tool for each kind of art and stick with it, and reuse the same
style reference every time:

- **Midjourney:** make your first card you love, then pass its image URL as a
  style reference on every later card: `--sref <url>`. Keep the same `--stylize`
  value. For characters, use `--cref <url>` (character reference) so the same
  person looks the same in every pose.
- **ChatGPT / other chat image tools:** upload the first card you love and say
  "match the style of this image exactly" each time.

Don't worry about text, frames, borders, names or numbers — the game draws all
of those itself. Ask for **no text** every time.

## 1. Sigil cards (Totems, Summons, Rites, Allies)

**Size:** square, 1024 × 1024 or larger. Keep the subject in the middle with some
space around it — the card frame shows a wide window from the centre, and the
full square appears when a card is inspected or summoned.

**Style prompt** (paste after the subject):

> painted fantasy trading-card illustration, rich painterly brushwork, dramatic
> rim lighting, glowing magical particles, atmospheric background tinted with
> {element colour}, subject centred, full body visible, high detail, no text,
> no border, no frame, no watermark

**Element colours** to drop into `{element colour}`:

| Element | Colour words |
| --- | --- |
| Fire | ember orange and crimson |
| Frost | pale ice blue and white |
| Tide | deep ocean blue and teal |
| Storm | electric indigo and yellow |
| Earth | warm ochre and stone brown |
| Wind | pale mint and sky blue |
| Verdant | fresh leaf green and gold |
| Metal | polished steel and brass |
| Venom | sickly violet and acid green |
| Psychic | soft pink and lavender |
| Mystic | deep indigo and gold runes |
| Spirit | ghostly teal and silver |
| Radiant (divine) | blazing white-gold |
| Umbral (divine) | ink black and violet |
| Astral (divine) | starfield blue and silver |
| Void (divine) | black with a crimson rim |

**Rarity feel** — say this too, it keeps higher tiers looking grander:

- Tier 1–2 (Spark, Glimmer): "small, charming, everyday wild creature"
- Tier 3–4 (Crystal, Relic): "powerful, imposing, ancient"
- Tier 5 (Legend): "legendary, awe-inspiring, cinematic scale"
- Tier 6–7 (Demigod, Divine): "godlike, colossal, heavenly light, epic"

**Save as:** `assets/art/cards/<card id>.png` — the card ids are in the table
below (for example `cinderpup.png`).

## 2. Characters for the walkable world

The world is 3D with painted characters standing in it like paper cut-outs
(think *Octopath Traveler* meets *Paper Mario*). So each character needs a few
flat images of the **same person**:

| Image | Size | Notes |
| --- | --- | --- |
| `<name>_front.png` | 1024 × 1536 (portrait) | full body, facing three-quarters towards the viewer, standing relaxed, arms slightly away from the body |
| `<name>_back.png` | 1024 × 1536 | same person from behind, three-quarters |
| `<name>_portrait.png` | 1024 × 1024 | head and shoulders for dialogue boxes, a clear expression |

**Style prompt:**

> full body character art for a fantasy RPG, painterly anime-inspired style,
> clean silhouette, soft cel shading, plain flat light grey background, no
> shadow on the ground, no text

The flat grey background matters — the game cuts it away automatically. Only one
character per image.

**Save as:** `assets/art/characters/`.

## 3. Places

The ground, buildings and props are built in 3D in the engine. What helps from
image AI:

- **Concept paintings** of each place (wide 16:9), which set the colours and mood
  I build towards. Save to `assets/art/concepts/`.
- **Sky and distant backdrops** (very wide, 3:1, no foreground). Save to
  `assets/art/backdrops/`.
- **Seamless textures** — ask for "seamless tileable texture, top-down, even
  lighting" (cobblestone, grass, sandstone, roof tiles). Square, 1024 × 1024.
  Save to `assets/art/textures/`.

## 4. Story scenes

The prologue is told over full-screen paintings. Wide 16:9 (for example
1920 × 1080), no text. Until a painting exists the game draws a simple
stand-in.

| File (assets/art/story/) | Scene |
| --- | --- |
| `sigilfall.png` | Night over a small farming village; streaks of many-coloured light fall from a torn sky like meteors |
| `card.png` | Close-up: a blank, glowing card lying in the grass at night, light pouring from it |
| `heralds.png` | Dawn; eight tall banners on a hill, seven in the colours of the gods and one plain white |
| `fire.png` | The village burning at night; hooded hunters' silhouettes against the flames |
| `road.png` | A lonely road through hills at dusk; an old innkeeper and a young traveller walking east |

**Style prompt:** "cinematic fantasy painting, painterly, dramatic lighting, rich
colour, wide establishing shot, no text, no watermark".

## 5. The card list

Each card's subject is below. Build a prompt as:
**subject** + **rarity feel** + **style prompt** (with the element colour).

| File name (add .png) | Card | Kind | Element | Tier | Subject |
| --- | --- | --- | --- | --- | --- |
| `cinderpup` | Cinderpup | Totem | Fire | 1 Spark | a small fox-like pup made of glowing embers, a flickering flame for a tail, bright amber eyes, playful crouch |
| `blazehound` | Blazehound | Totem | Fire | 2 Glimmer | a lean wolfhound wreathed in roaring flame, a mane of fire, molten cracks along its body, lunging forward |
| `emberwisp` | Emberwisp | Totem | Fire | 1 Spark | a tiny floating spark spirit with a candle-flame body, wide curious eyes, trailing glowing cinders |
| `ashen_drake` | Ashen Drake | Totem | Fire | 3 Crystal | a young dragon with charcoal-grey scales and glowing orange cracks, smoke pouring from its jaws, wings half spread |
| `gustling` | Gustling | Totem | Wind | 1 Spark | a round fluffy bird made of swirling air currents, tufted crest, tiny wings, riding a little whirlwind |
| `galeheart` | Galeheart | Totem | Wind | 2 Glimmer | a sleek falcon with feathers that dissolve into streaks of wind, sharp eyes, diving through a spiral of air |
| `skylark_scout` | Skylark Scout | Totem | Wind | 1 Spark | a small skylark wearing a tiny scout's satchel, feathers edged with glowing wind lines, perched alert |
| `tempest_roc` | Tempest Roc | Totem | Wind | 3 Crystal | a huge storm-grey roc with a wingspan of whirling cloud, talons like silver hooks, screaming mid-flight |
| `brookfin` | Brookfin | Totem | Tide | 1 Spark | a small river serpent with translucent blue fins and pebble-smooth scales, curled in a splash of clear water |
| `riptide_serpent` | Riptide Serpent | Totem | Tide | 2 Glimmer | a long sea serpent coiling through a crashing wave, fins like torn sails, eyes glowing deep blue |
| `deepmaw` | Deepmaw Leviathan | Totem | Tide | 3 Crystal | a colossal sea leviathan rising from a whirlpool, barnacled armour plates, a jaw wide enough to swallow ships |
| `shellguard` | Shellguard | Totem | Tide | 1 Spark | a sturdy turtle with a coral-covered shell and a calm wise face, water droplets beading on its shell |
| `mossling` | Mossling | Totem | Verdant | 1 Spark | a small round forest creature covered in soft moss, a sprout growing from its head, big gentle eyes |
| `thornwarden` | Thornwarden | Totem | Verdant | 2 Glimmer | a bear-like guardian made of woven roots and thorny vines, flowers blooming on its shoulders, protective stance |
| `bloomsprite` | Bloomsprite | Totem | Verdant | 1 Spark | a tiny fairy-like sprite with petal wings and a flower-bud head, scattering glowing pollen |
| `elderbark` | Elderbark | Totem | Verdant | 3 Crystal | an ancient walking tree with a bark face, moss beard and glowing sap veins, roots dragging like feet |
| `sparkkit` | Sparkkit | Totem | Storm | 1 Spark | a small indigo fox kit with crackling yellow lightning along its ears and a bolt-shaped tail |
| `voltlynx` | Voltlynx | Totem | Storm | 2 Glimmer | a lynx with deep indigo fur and ear tufts sparking with electricity, a jagged lightning mane, snarling |
| `stormcaller` | Stormcaller Heron | Totem | Storm | 3 Crystal | a tall heron standing in dark water, storm clouds swirling around its crest, lightning dancing between its wings |
| `pebblit` | Pebblit | Totem | Earth | 1 Spark | a round pebble creature with little stubby arms, a teal crystal growing from its head, cheerful face |
| `boulderox` | Boulderox | Totem | Earth | 2 Glimmer | a massive ox with a body of layered boulders, curved stone horns, moss in the cracks, pawing the ground |
| `burrowmole` | Burrowmole | Totem | Earth | 1 Spark | a mole in a battered miner's helmet with a glowing lamp, huge digging claws, clods of earth flying |
| `brassback` | Brassback | Totem | Metal | 1 Spark | a beetle with a polished brass shell engraved with sun patterns, a single curved horn, sturdy legs |
| `ironhide` | Ironhide Warbeetle | Totem | Metal | 2 Glimmer | a huge armoured war beetle with riveted iron plates and a battering-ram horn, gold trim, sun banners |
| `shieldhound` | Shieldhound | Totem | Metal | 1 Spark | a loyal hound wearing a small steel breastplate and helm, a sun crest on its collar, standing guard |
| `gilded_sentinel` | Gilded Sentinel | Totem | Metal | 3 Crystal | a tall golden armoured construct with a halo-shaped helm and a sunburst halberd, light spilling from its joints |
| `candlewisp` | Candlewisp | Totem | Spirit | 1 Spark | a small ghost shaped like a melting candle, a pale teal flame for a head, gentle sad eyes |
| `lantern_wraith` | Lantern Wraith | Totem | Spirit | 2 Glimmer | a hooded wraith carrying a lantern of trapped teal soul-fire, tattered robes drifting like smoke |
| `runemoth` | Runemoth | Totem | Mystic | 1 Spark | a moth with indigo wings covered in glowing golden runes, feathery antennae, dust sparkling as it flies |
| `glyph_owl` | Glyph Owl | Totem | Mystic | 2 Glimmer | a wise owl with feathers inscribed with glowing runes, spectacles of floating light, a floating open book beside it |
| `blightrat` | Blightrat | Totem | Venom | 1 Spark | a mangy rat with sickly purple fur, dripping green-violet fangs, beady glowing eyes, sneaking |
| `plague_asp` | Plague Asp | Totem | Venom | 2 Glimmer | a coiled asp with violet scales and a hood marked like a skull, venom mist rising around it |
| `dreamfox` | Dreamfox | Totem | Psychic | 1 Spark | a slender pink fox with two misty tails and half-closed dreamy eyes, bubbles of illusion floating around it |
| `veilfox` | Veilfox | Totem | Psychic | 2 Glimmer | an elegant fox with four translucent veil-like tails, a glowing third eye, surrounded by shifting mirages |
| `sunlance_seraph` | Sunlance Seraph | Totem | Radiant | 5 Legend | a radiant winged warrior spirit in white-gold armour, six wings of light, a lance of pure sunlight, halo blazing |
| `dawnmane` | Dawnmane, the Sun Lion | Summon | Radiant | 6 Demigod | a colossal lion of living sunlight descending from the sky, a mane of solar flares, roaring as dawn breaks behind it |
| `healing_draught` | Healing Draught | Rite | — | 1 Spark | a glass flask of glowing rose-red liquid with a cork stopper, tiny bubbles rising |
| `cleansing_salts` | Cleansing Salts | Rite | — | 1 Spark | a small pouch spilling shimmering white salt crystals that glow softly |
| `swap_talisman` | Swap Talisman | Rite | — | 1 Spark | a bronze talisman of two interlocking arrows on a leather cord, faintly glowing |
| `seekers_compass` | Seeker's Compass | Rite | — | 1 Spark | an ornate brass compass whose needle is a tiny flame, pointing towards a hidden card |
| `awakening_stone` | Awakening Stone | Rite | — | 1 Spark | a smooth river stone cracked open with a golden light pouring out of it |
| `essence_flask` | Essence Flask | Rite | — | 1 Spark | a crystal flask holding swirling motes of many-coloured light |
| `lure_bell` | Lure Bell | Rite | — | 2 Glimmer | a small golden bell with a sun engraving, sound waves of light rippling from it |
| `siphon_rune` | Siphon Rune | Rite | — | 2 Glimmer | a dark stone rune tile with a glowing violet symbol draining light into itself |
| `revival_candle` | Revival Candle | Rite | — | 2 Glimmer | a tall white candle with a teal spirit flame, wax dripping into the shape of a small creature |
| `bram` | Bram, Old Duellist | Ally | — | 1 Spark | a weathered old innkeeper with a grey beard, an eyepatch and a warm grin, shuffling a worn deck of cards |
| `archive_scribe` | Archive Scribe | Ally | — | 1 Spark | a young scribe in indigo robes surrounded by floating scrolls, ink-stained fingers, spectacles |
| `wren` | Wren, Card Thief | Ally | — | 2 Glimmer | a quick-eyed young thief in a hooded green cloak, flicking a stolen card between her fingers, sly smile |

Energy cards need no illustration — they're drawn by the game.
