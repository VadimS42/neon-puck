# Neon Puck: art list

Every piece of art the game looks for, with its exact path, size and a brief
for the artist. Drop a PNG at the path and the game uses it on next launch;
nothing else needs to change (see `scripts/ArtAssets.gd`). Anything missing
falls back to the placeholder you see now, so art can arrive piece by piece.

This file is generated from the game data: `python3 tools/gen_art_list.py`.

All characters are adults (24, 27, 28, 31). Sizes are recommended export
sizes; keep the aspect ratio. Use transparent backgrounds for characters,
paddles and the puck.

## Priority order

1. **Strip stages** for each heroine (16 images). The match is where players
   spend their time, and the portrait changing is the core reward.
2. **Story scenes** (24 CGs). One per story match win, 6 per heroine.
3. **Table, puck and paddles** (7 images). Cheap, and they lift the whole look.
4. **Dialogue expressions** (up to 28). Start with `vn_neutral` per heroine;
   every missing expression falls back to it.
5. **Cup and championship scenes** (4 CGs). Rewards for side content and the ending.
6. **Backgrounds and logo** (3 images).

Minimum set for a good-looking demo: items 1, 3, the first two scenes per
heroine, and `vn_neutral` for each heroine (35 files).

## Per heroine

Replace `<id>` with `mila`, `juno`, `kat`, `sable`.

| File | Size | Shown where | Notes |
| --- | --- | --- | --- |
| `art/heroines/<id>/stage_0.png` | 1024x1440 | Match card, roster, results | Fully dressed, standing, facing the player. Same pose for all four stages so swaps read as clothes coming off. |
| `art/heroines/<id>/stage_1.png` | 1024x1440 | Match card after the first layer | Outer layer off (see her layer list). Flustered expression. |
| `art/heroines/<id>/stage_2.png` | 1024x1440 | After the second layer | Second layer off. |
| `art/heroines/<id>/stage_3.png` | 1024x1440 | After the third layer | Last layer off. In the placeholder she is down to underwear; how far the final stage goes is your call. |
| `art/heroines/<id>/vn_<expression>.png` | 1024x1440 | Dialogue | Expressions: neutral, happy, shy, surprised, teasing, sad, angry. Dressed (stage 0 outfit). |
| `art/heroines/<id>/card.png` | 700x600 | Roster card (optional) | Falls back to stage_0. |
| `art/table/paddle_<id>.png` | 256x256 | Her paddle | Round, top-down, in her colour. |
| `art/scenes/<id>_1.png` ... `<id>_6.png` | 1920x1080 | Reward after each story match | See scene briefs below. The last one is her romance scene: a good candidate for animation later. |

### Mila Reyes (24), `mila`, colour #FF4F8B

Bike courier. Plays fast, talks faster. You towed her bike. She starts out hating you: you towed her bike on your first morning. Plays a speed style; her signature shot is the Bullet.

Layers, in the order they come off: **Racer jacket**, **Crop top**, **Bike shorts**.

Scenes (her mood goes from hostile to in love across them):

1. **Sore Loser** (`art/scenes/mila_1.png`): Mila sits on the edge of the table in whatever she has left, arms crossed, glaring at you and refusing to admit she's blushing.
2. **Borrowed Jacket** (`art/scenes/mila_2.png`): Outside under the neon sign, Mila wears your work jacket and nothing much under it, leaning on her bike, still pretending to be annoyed.
3. **Courier Crowd** (`art/scenes/mila_3.png`): Mila in her crop top and bike shorts stands on the table rail, pointing at you in mock outrage while her courier friends cheer offscreen. She's fighting a grin.
4. **Rain Check** (`art/scenes/mila_4.png`): Mila sits on the bar wrapped in a lounge towel, hair dripping, watching you patch her bike tyre on the floor. Her wet clothes hang off a bar stool.
5. **Fries at 4 AM** (`art/scenes/mila_5.png`): Mila in her sports bra and your jacket, sharing fries with you on the lounge's back steps at dawn, leaning on your shoulder.
6. **After Hours** (`art/scenes/mila_6.png`): Mila's romance scene in the closed lounge. Adult scene: write to your content plan.

### Juno Hart (27), `juno`, colour #4FE3B0

Bartender. Never hits the puck straight. You took her job. She starts out hating you: you got the manager job she'd been doing for free. Plays a banks style; her signature shot is the Ricochet.

Layers, in the order they come off: **Bar vest**, **Silk shirt**, **Pencil skirt**.

Scenes (her mood goes from hostile to in love across them):

1. **Behind the Bar** (`art/scenes/juno_1.png`): Juno, half out of her uniform, slams a drink down in front of you, furious, and refuses to admit she lost.
2. **The Memo** (`art/scenes/juno_2.png`): Juno in her slip on the office desk, reading your unsent memo by lamplight, looking up at you differently for the first time.
3. **Stockroom** (`art/scenes/juno_3.png`): Juno in her silk shirt, half buttoned with the sleeves rolled up, sits on a stack of beer crates in the stockroom with a clipboard and a pen between her teeth, eating cherries from the jar.
4. **Credit Where Due** (`art/scenes/juno_4.png`): Juno in her slip and your blazer lounges on the office couch, popping a stolen bottle of champagne, laughing as the cork hits the ceiling.
5. **Off the Menu** (`art/scenes/juno_5.png`): Juno sits on the bar in her underwear and your tie, sliding you a glowing cocktail with a small smile.
6. **Perfect Angle** (`art/scenes/juno_6.png`): Juno's romance scene behind the bar. Adult scene: write to your content plan.

### Kat Vance (28), `kat`, colour #FF9F43

Owns the Static, the dive bar across the street. Your league night stole her crowd. She starts out hating you: your chain's league night flyers stole her Thursday crowd, and one ended up taped to her door. Plays a tricks style; her signature shot is the Slingshot.

Layers, in the order they come off: **Leather jacket**, **Band tee**, **Ripped jeans**.

Scenes (her mood goes from hostile to in love across them):

1. **Wrong Bar** (`art/scenes/kat_1.png`): Kat stands at the table in her band tee and jeans, leather jacket thrown on the floor, jabbing a finger at you, furious and flushed.
2. **Dead Spot** (`art/scenes/kat_2.png`): Kat in her band tee and ripped jeans sits on the bar of the empty Static across the street, its old table behind her, arms folded, studying you suspiciously.
3. **Monday Night** (`art/scenes/kat_3.png`): Kat behind the bar of the packed Static in her band tee and jeans, pulling two pints at once and laughing, the crowd a neon blur behind her.
4. **Soundcheck** (`art/scenes/kat_4.png`): Kat on the Static's tiny stage in a cropped band tee and jeans, bass guitar slung low, grinning at you over the mic stand under red stage lights.
5. **Across the Street** (`art/scenes/kat_5.png`): Kat in her band tee and your work jacket stands in the middle of the empty street between the two bars at 4 AM, both neon signs glowing behind her, reaching for your hand.
6. **Upstairs at the Static** (`art/scenes/kat_6.png`): Kat's romance scene in her apartment above the Static. Adult scene: write to your content plan.

### Sable Marchetti (31), `sable`, colour #B98CFF

Founded the Afterglow, sold it to your chain. Undefeated for six years. She starts out hating you: you're the face of the company that bought her lounge. Plays a curves style; her signature shot is the Hook.

Layers, in the order they come off: **Velvet blazer**, **Corset top**, **Stockings**.

Scenes (her mood goes from hostile to in love across them):

1. **Under the Blazer** (`art/scenes/sable_1.png`): Sable leans back on the table, blazer gone, eyes narrowed, studying you like a problem she plans to destroy.
2. **The Office** (`art/scenes/sable_2.png`): Sable in her old office in stockings and little else, lit pink by the neon sign through the window, pouring two drinks.
3. **Opening Night** (`art/scenes/sable_3.png`): Sable in her corset top sits on her office floor surrounded by old photos of the Afterglow's opening night, laughing at one of them, eyes a little wet.
4. **Rooftop** (`art/scenes/sable_4.png`): Sable in stockings and your dress shirt sits on the roof ledge beside the buzzing neon sign, city lights behind her, holding a candy cigarette like a real one.
5. **Partners** (`art/scenes/sable_5.png`): Sable in lingerie sits on the edge of her desk signing a napkin contract, pulling you in by your tie.
6. **Champion's Privilege** (`art/scenes/sable_6.png`): Sable's romance scene on the lounge's championship table. Adult scene: write to your content plan.

## Cup and championship scenes

| File | Title | Brief |
| --- | --- | --- |
| `art/scenes/cup_bronze.png` | Bronze Cup Night | The three regulars, mid-celebration in their league jerseys and not much else, crowd around you and the bronze trophy at the bar. |
| `art/scenes/cup_silver.png` | Silver Cup Afterparty | Afterparty in the lounge: the heroines in lingerie and party hats, a pile of silver confetti, everyone a little tipsy. |
| `art/scenes/cup_gold.png` | Gold Cup Champions | Group romance scene on the championship table after the Gold Cup. Adult scene: write to your content plan. |
| `art/scenes/finale.png` | Afterglow | Dawn after the championship. You and all four heroines on the championship table under the neon sign, the 'SOLD' banner torn in half on the floor. Adult group scene: write to your content plan. |

## Shared

| File | Size | Notes |
| --- | --- | --- |
| `art/table/table.png` | 1920x1080 | Top-down playfield, exactly 16:9. Goals are on the left and right short edges, centred, 43% of the height wide. Centre line and circle. Neon arcade style. |
| `art/table/puck.png` | 128x128 | Light grey or white: the game tints it gold for your smash and her colour for her signature. |
| `art/table/paddle_player.png` | 256x256 | Your paddle, cyan. |
| `art/bg/lounge.png` | 1920x1080 | The after-hours arcade lounge. Used behind most screens (dimmed). |
| `art/bg/menu.png` | 1920x1080 | Title screen. Keep the left 40% calm: the menu buttons sit there. |
| `art/ui/logo.png` | 1200x450 | "Neon Puck" logo (working title), transparent. |

## Shop icons (optional, later)

The Pro Shop and loadout screens use text only for now. If you want icons,
these are the items (256x256 each, transparent): gear Felt-rim paddle, Carbon paddle, Tournament paddle, Neon Crown, Cotton glove, Leather glove, Pro glove, Midnight glove, Canvas sneakers, Court sneakers, Air sneakers, Bottle-cap pin, Neon keychain, Gold token, Champion's ring; power-ups Energy Drink, Grip Tape, Spotlight, Hype Track, Distracting Wink, Sugar Rush, Second Wind. Tell
me when they exist and I'll wire them in.

## All-ages versions (optional)

Settings has an All-ages mode, for the separate SFW build the research
recommends. With it on, every lookup tries `<name>_sfw.png` first (for
example `art/heroines/mila/stage_3_sfw.png`, `art/scenes/mila_6_sfw.png`)
and falls back to the normal file. Commission SFW variants only for the
images that need them: usually stage_2, stage_3 and the scenes.

## Sound (optional, same drop-in rule)

`audio/sfx/<name>.ogg` for: hit, wall, goal, goal_against, smash, strip, warn,
click, win, lose. Missing files play a synthesized blip.

## Counts

| Group | Files |
| --- | --- |
| Strip stages | 16 |
| Story scenes | 24 |
| Cup and championship scenes | 4 |
| Dialogue expressions | 4 to 28 |
| Paddles, puck, table | 7 |
| Backgrounds and logo | 3 |
| **Total** | **58 to 82** |
