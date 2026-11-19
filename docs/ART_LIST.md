# Neon Puck: art list

Every piece of art the game looks for, with its exact path, size and a brief
for the artist. Drop a PNG at the path and the game uses it on next launch;
nothing else needs to change (see `scripts/ArtAssets.gd`). Anything missing
falls back to the placeholder you see now, so art can arrive piece by piece.

All characters are adults (24, 27 and 31). Sizes are recommended export
sizes; keep the aspect ratio. Use transparent backgrounds for characters,
paddles and the puck.

## Priority order

1. **Strip stages** for each heroine (12 images). The match is where players
   spend their time, and the portrait changing is the core reward.
2. **Reward scenes** (12 CGs). One per match win, 4 per heroine.
3. **Table, puck and paddles** (6 images). Cheap, and they lift the whole look.
4. **Dialogue expressions** (up to 21). Start with `vn_neutral` per heroine;
   every missing expression falls back to it.
5. **Backgrounds and logo** (3 images).

Minimum set for a good-looking demo: items 1, 2 and 3, plus `vn_neutral`
for each heroine (33 files).

## Per heroine

Replace `<id>` with `mila`, `juno` or `sable`.

| File | Size | Shown where | Notes |
| --- | --- | --- | --- |
| `art/heroines/<id>/stage_0.png` | 1024x1440 | Match card, roster, results | Fully dressed, standing, facing the player. Same pose for all four stages so swaps read as clothes coming off. |
| `art/heroines/<id>/stage_1.png` | 1024x1440 | Match card after the first layer | Outer layer off (see her layer list). Flustered expression. |
| `art/heroines/<id>/stage_2.png` | 1024x1440 | After the second layer | Second layer off. |
| `art/heroines/<id>/stage_3.png` | 1024x1440 | After the third layer | Last layer off. In the placeholder she is down to underwear; how far the final stage goes is your call. |
| `art/heroines/<id>/vn_<expression>.png` | 1024x1440 | Dialogue | Expressions: neutral, happy, shy, surprised, teasing, sad, angry. Dressed (stage 0 outfit). |
| `art/heroines/<id>/card.png` | 700x600 | Roster card (optional) | Falls back to stage_0. |
| `art/table/paddle_<id>.png` | 256x256 | Her paddle | Round, top-down, in her colour. |
| `art/scenes/<id>_1.png` | 1920x1080 | Reward after match 1 | See scene briefs below. |
| `art/scenes/<id>_2.png` | 1920x1080 | Reward after match 2 | |
| `art/scenes/<id>_3.png` | 1920x1080 | Reward after match 3 | |
| `art/scenes/<id>_4.png` | 1920x1080 | Reward after match 4 | Her romance scene. Good candidate for animation later (the research showed animated scenes got the most praise). |

### Mila Reyes (24), `mila`, colour #FF4F8B

Bike courier. Plays fast, talks faster. You towed her bike. She starts out hating you: you towed her bike on your first morning. Plays a speed style; her signature shot is the Bullet.

Layers, in the order they come off: **Racer jacket**, **Crop top**, **Bike shorts**.

Scenes (her mood goes from hostile to in love across them):

1. **Sore Loser**: Mila sits on the edge of the table in whatever she has left, arms crossed, glaring at you and refusing to admit she's blushing.
2. **Borrowed Jacket**: Outside under the neon sign, Mila wears your work jacket and nothing much under it, leaning on her bike, still pretending to be annoyed.
3. **Fries at 4 AM**: Mila in her sports bra and your jacket, sharing fries with you on the lounge's back steps at dawn, leaning on your shoulder.
4. **After Hours**: Mila's romance scene in the closed lounge. Adult scene: write to your content plan.

### Juno Hart (27), `juno`, colour #4FE3B0

Bartender. Never hits the puck straight. You took her job. She starts out hating you: you got the manager job she'd been doing for free. Plays a banks style; her signature shot is the Ricochet.

Layers, in the order they come off: **Bar vest**, **Silk shirt**, **Pencil skirt**.

Scenes (her mood goes from hostile to in love across them):

1. **Behind the Bar**: Juno, half out of her uniform, slams a drink down in front of you, furious, and refuses to admit she lost.
2. **The Memo**: Juno in her slip on the office desk, reading your unsent memo by lamplight, looking up at you differently for the first time.
3. **Off the Menu**: Juno sits on the bar in her underwear and your tie, sliding you a glowing cocktail with a small smile.
4. **Perfect Angle**: Juno's romance scene behind the bar. Adult scene: write to your content plan.

### Sable Marchetti (31), `sable`, colour #B98CFF

Founded the Afterglow, sold it to your chain. Undefeated for six years. She starts out hating you: you're the face of the company that bought her lounge. Plays a curves style; her signature shot is the Hook.

Layers, in the order they come off: **Velvet blazer**, **Corset top**, **Stockings**.

Scenes (her mood goes from hostile to in love across them):

1. **Under the Blazer**: Sable leans back on the table, blazer gone, eyes narrowed, studying you like a problem she plans to destroy.
2. **The Office**: Sable in her old office in stockings and little else, lit pink by the neon sign through the window, pouring two drinks.
3. **Partners**: Sable in lingerie sits on the edge of her desk signing a napkin contract, pulling you in by your tie.
4. **Champion's Privilege**: Sable's romance scene on the lounge's championship table. Adult scene: write to your content plan.

## Shared

| File | Size | Notes |
| --- | --- | --- |
| `art/table/table.png` | 1920x1080 | Top-down playfield, exactly 16:9. Goals are on the left and right short edges, centred, 43% of the height wide. Centre line and circle. Neon arcade style. |
| `art/table/puck.png` | 128x128 | Light grey or white: the game tints it gold for your smash and her colour for her signature. |
| `art/table/paddle_player.png` | 256x256 | Your paddle, cyan. |
| `art/bg/lounge.png` | 1920x1080 | The after-hours arcade lounge. Used behind most screens (dimmed). |
| `art/bg/menu.png` | 1920x1080 | Title screen. Keep the left 40% calm: the menu buttons sit there. |
| `art/ui/logo.png` | 1200x450 | "Neon Puck" logo (working title), transparent. |

## All-ages versions (optional)

Settings has an All-ages mode, for the separate SFW build the research
recommends. With it on, every lookup tries `<name>_sfw.png` first (for
example `art/heroines/mila/stage_3_sfw.png`, `art/scenes/mila_4_sfw.png`)
and falls back to the normal file. Commission SFW variants only for the
images that need them: usually stage_2, stage_3 and the scenes.

## Sound (optional, same drop-in rule)

`audio/sfx/<name>.ogg` for: hit, wall, goal, goal_against, smash, strip, warn,
click, win, lose. Missing files play a synthesized blip.

## Counts

| Group | Files |
| --- | --- |
| Strip stages | 12 |
| Reward scenes | 12 |
| Dialogue expressions | 3 to 21 |
| Paddles, puck, table | 6 |
| Backgrounds and logo | 3 |
| **Total** | **36 to 54** |
