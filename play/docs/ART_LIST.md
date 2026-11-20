# Neon Puck Rivals: art list (PG-13 Google Play build)

Every piece of art this build looks for, with its exact path, size and a short brief
for the artist. Drop a PNG at the path and the game uses it on next launch;
nothing else changes (see `scripts/ArtAssets.gd`). Missing art falls back to the
placeholder, so art can arrive piece by piece.

Generated from the game data: `python3 tools/gen_art_list.py`.

**Content rules for every image (Google Play, Teen rating):** fully clothed at all times,
no underwear or swimwear shots, no suggestive poses or camera angles, romance stops at a
kiss or a hug. Drinks are soda, milkshakes, tea or mocktails. All characters are adults (24, 27, 28, 31)
and should look it. None of the 18+ art can be reused here.

## Priority order

1. **Crack stages** (16 images): 4 per heroine in her default outfit. This is what players look at during every match.
2. **Table, puck, paddles** (7 images). Cheap and they lift the whole look.
3. **Store listing art** (icon, feature graphic, screenshots). Needed before you can publish.
4. **Dialogue sprites**: `vn_neutral` per heroine first, then the other 6 expressions.
5. **Memories** (24 story CGs, then 4 cup and finale CGs).
6. **Outfits** (Date, League jersey, Neon Nights). These are what players buy with gems, so they should look worth it.
7. **Store and UI art** (gem packs, pass badges, backgrounds, logo).

Minimum set to publish: items 1 to 3 plus `vn_neutral` per heroine (about 35 files).

## Per heroine

Replace `<id>` with `mila`, `juno`, `kat`, `sable`. Same pose and outfit for all four crack stages, so the swap reads as her
cool cracking: only face, hair and body language change. Transparent background.

| File | Size | Shown where | Brief |
| --- | --- | --- | --- |
| `art/heroines/<id>/stage_0.png` | 1024x1440 | Match card, roster, results | Cool and composed (see her row below). |
| `art/heroines/<id>/stage_1.png` | 1024x1440 | After her first crack | First crack (see below). |
| `art/heroines/<id>/stage_2.png` | 1024x1440 | After her second crack | Second crack. |
| `art/heroines/<id>/stage_3.png` | 1024x1440 | After her third crack | Lost her cool completely, played for comedy. |
| `art/heroines/<id>/vn_<expression>.png` | 1024x1440 | Dialogue | neutral, happy, shy, surprised, teasing, sad, angry. Default outfit, waist up is fine. |
| `art/heroines/<id>/card.png` | 700x600 | Roster card, Wardrobe (optional) | Falls back to stage_0. |
| `art/table/paddle_<id>.png` | 256x256 | Her paddle | Round, top-down, in her colour. |
| `art/scenes/<id>_1.png` ... `<id>_6.png` | 1920x1080 | Memory after each story win | See briefs below. |

### Mila Reyes (24), `mila`, colour #FF4F8B

Bike courier. Plays fast, talks faster. You towed her bike. Plays a speed style; signature shot: Bullet.

**Default outfit (Racer gear):** Pink and black cycling jacket zipped up, fitted athletic top, bike shorts over black leggings, fingerless gloves, messenger bag strap across her chest.

Crack stages:

- `stage_0` **Cool**: Smug grin, sunglasses pushed up on her head, one hand on her hip, ready to race.
- `stage_1` **Smirk gone**: The grin is gone. Jaw set, glaring straight at you.
- `stage_2` **Hair tie snaps**: Her ponytail has come loose; hair everywhere, blowing a strand out of her face.
- `stage_3` **Full meltdown**: Comic meltdown: red-faced, fists clenched, mid-shout, cartoon sweat drops.

Memories (she goes from hating you to falling for you across them):

1. **Sore Loser** (`art/scenes/mila_1.png`): Mila sits on the edge of the table, hair a mess, arms crossed, glaring at you and refusing to admit she's blushing.
2. **Borrowed Jacket** (`art/scenes/mila_2.png`): Outside under the neon sign, Mila wears your oversized work jacket over her racer gear, leaning on her bike, still pretending to be annoyed.
3. **Courier Crowd** (`art/scenes/mila_3.png`): Mila in her racer gear stands on the table rail, pointing at you in mock outrage while her courier friends cheer offscreen. She's fighting a grin.
4. **Rain Check** (`art/scenes/mila_4.png`): Mila sits on the bar in an oversized Afterglow hoodie with a towel round her shoulders, hair dripping, watching you patch her bike tyre on the floor.
5. **Fries at 4 AM** (`art/scenes/mila_5.png`): Mila in her racer gear and your jacket, sharing fries with you on the lounge's back steps at dawn, leaning on your shoulder.
6. **The Long Way Home** (`art/scenes/mila_6.png`): You and Mila walk her bike down an empty neon street at dawn, her hand in yours. She has just kissed you and is pretending it didn't happen, grinning.

### Juno Hart (27), `juno`, colour #4FE3B0

Bartender. Never hits the puck straight. You took her job. Plays a banks style; signature shot: Ricochet.

**Default outfit (Bartender):** White shirt with rolled sleeves, black bartender vest, mint bow tie, black trousers.

Crack stages:

- `stage_0` **Cool**: Arms folded, one eyebrow raised, pen tucked behind her ear. Unimpressed.
- `stage_1` **Eyebrow twitch**: One eyebrow twitching, a very tight smile.
- `stage_2` **Pen snapped**: Holding a snapped pen in two halves, a little ink on her fingers, staring at it.
- `stage_3` **Lost her cool**: Bow tie crooked, hair escaping its clip, blushing and pointing at you, mid-rant.

Memories (she goes from hating you to falling for you across them):

1. **Behind the Bar** (`art/scenes/juno_1.png`): Juno, behind the bar in her vest and bow tie, slams a soda down in front of you, furious, and refuses to admit she lost.
2. **The Memo** (`art/scenes/juno_2.png`): Juno, sleeves rolled up, sits on the office desk reading your unsent memo by lamplight, looking up at you differently for the first time.
3. **Stockroom** (`art/scenes/juno_3.png`): Juno in her shirt and vest, sleeves rolled up, sits on a stack of soda crates in the stockroom with a clipboard and a pen between her teeth, eating cherries from the jar.
4. **Credit Where Due** (`art/scenes/juno_4.png`): Juno in her work clothes and your blazer lounges on the office couch, popping a bottle of sparkling cider, laughing as the cork hits the ceiling.
5. **Off the Menu** (`art/scenes/juno_5.png`): Juno sits on the bar in her bartender vest and your tie, sliding you a glowing neon milkshake with two straws and a small smile.
6. **Perfect Angle** (`art/scenes/juno_6.png`): Juno leans across the bar to kiss you, eyes closed, smiling into it. The framed napkin reading 'don't fall for the new guy' hangs on the wall behind her.

### Kat Vance (28), `kat`, colour #FF9F43

Owns the Static, the dive bar across the street. Your league night stole her crowd. Plays a tricks style; signature shot: Slingshot.

**Default outfit (Rocker):** Black leather jacket, faded band tee, jeans with knee rips, boots, sunglasses.

Crack stages:

- `stage_0` **Cool**: Sunglasses on, chewing gum, thumbs hooked in her belt loops. Too cool.
- `stage_1` **Shades off**: Shades yanked down her nose, glaring at you over them.
- `stage_2` **Pick dropped**: Her guitar pick slipping out of her fingers, mouth open in disbelief.
- `stage_3` **Rage mode**: Leaning in, grin-snarl, a comic anger mark on her forehead. She's having fun now.

Memories (she goes from hating you to falling for you across them):

1. **Wrong Bar** (`art/scenes/kat_1.png`): Kat stands at the table in her band tee and jeans, leather jacket slung over one shoulder, jabbing a finger at you, furious and flushed.
2. **Dead Spot** (`art/scenes/kat_2.png`): Kat in her band tee and ripped jeans sits on the bar of the empty Static across the street, its old table behind her, arms folded, studying you suspiciously.
3. **Monday Night** (`art/scenes/kat_3.png`): Kat behind the bar of the packed Static in her band tee and jeans, pulling two pints at once and laughing, the crowd a neon blur behind her.
4. **Soundcheck** (`art/scenes/kat_4.png`): Kat on the Static's tiny stage in her band tee and jeans, bass guitar slung low, grinning at you over the mic stand under red stage lights.
5. **Across the Street** (`art/scenes/kat_5.png`): Kat in her band tee and your work jacket stands in the middle of the empty street between the two bars at 4 AM, both neon signs glowing behind her, reaching for your hand.
6. **Last Song** (`art/scenes/kat_6.png`): Kat and you slow-dancing alone on the Static's stage after close, her forehead against yours, her bass leaning on the amp, red stage lights turned low.

### Sable Marchetti (31), `sable`, colour #B98CFF

Founded the Afterglow, sold it to your chain. Undefeated for six years. Plays a curves style; signature shot: Hook.

**Default outfit (Velvet):** Purple velvet blazer, silk blouse buttoned to the collar, tailored trousers, heeled boots, sleek low bun.

Crack stages:

- `stage_0` **Cool**: Perfect poker face, chin raised, hands clasped in front of her.
- `stage_1` **Poker face cracks**: A tiny smile tugging at her mouth that she's trying very hard to hide.
- `stage_2` **Hair falls loose**: Her sleek bun has come loose; strands across her face, eyes wide.
- `stage_3` **Flustered**: Blushing, hand over her mouth, looking away. Flustered for the first time in years.

Memories (she goes from hating you to falling for you across them):

1. **First Sweat** (`art/scenes/sable_1.png`): Sable leans back on the table, blazer over one shoulder and a strand of hair out of place, eyes narrowed, studying you like a problem she plans to destroy.
2. **The Office** (`art/scenes/sable_2.png`): Sable in her old office in her velvet blazer, lit pink by the neon sign through the window, pouring two cups of tea.
3. **Opening Night** (`art/scenes/sable_3.png`): Sable, blazer off and sleeves rolled up, sits on her office floor surrounded by old photos of the Afterglow's opening night, laughing at one of them, eyes a little wet.
4. **Rooftop** (`art/scenes/sable_4.png`): Sable wrapped in your coat sits on the roof ledge beside the buzzing neon sign, city lights behind her, twirling a lollipop like a cigar.
5. **Partners** (`art/scenes/sable_5.png`): Sable in her velvet blazer sits on the edge of her desk signing a napkin contract, pulling you closer by your tie with a sly smile.
6. **Champion's Privilege** (`art/scenes/sable_6.png`): Sable kisses you under the Afterglow's neon sign beside the championship table, her blazer around your shoulders, your name freshly painted at the top of the wall behind her.

## Outfits (Wardrobe)

Cosmetic only. Each outfit is a folder: `art/heroines/<id>/<outfit>/` holding `stage_0.png` to
`stage_3.png` (same poses and expressions as her default set, new clothes) and optionally `card.png`
and `vn_*.png`. Minimum per outfit is `stage_0.png` (shown for every crack); the full set of 4 is
better. Dialogue keeps her default outfit unless you add `vn_*.png` to the folder.

| Heroine | Folder | Outfit | How players get it | Brief |
| --- | --- | --- | --- | --- |
| Mila | `art/heroines/mila/date/` | Date night | Finish her story | Oversized denim jacket over a pink skater dress with leggings, white sneakers, hair down with a star clip. |
| Mila | `art/heroines/mila/league/` | League jersey | 120 gems | Last Call League jersey in her colour with her name and number on the back, track pants, sneakers, sweatband. |
| Mila | `art/heroines/mila/neon/` | Neon Nights | 250 gems | Neon party look in her colour: glowing piping, holographic jacket, LED-trim sneakers, glow bracelets. |
| Mila | `art/heroines/mila/rush_hour/` | Rush Hour Racer | Win the Rush Hour weekly event | Orange-and-black courier racing suit with reflective stripes, fingerless gloves, a stopwatch on a lanyard. |
| Mila | `art/heroines/mila/pass_s1/` | Neon Nights Courier | Season 1: Neon Nights premium track | Purple light-up rain jacket over a crop hoodie and cargo pants, glowing bike-light clips on her bag strap. |
| Juno | `art/heroines/juno/date/` | Sunday best | Finish her story | Soft mint cardigan over a floral blouse, high-waisted trousers, round glasses. |
| Juno | `art/heroines/juno/league/` | League jersey | 120 gems | Last Call League jersey in her colour with her name and number on the back, track pants, sneakers, sweatband. |
| Juno | `art/heroines/juno/neon/` | Neon Nights | 250 gems | Neon party look in her colour: glowing piping, holographic jacket, LED-trim sneakers, glow bracelets. |
| Juno | `art/heroines/juno/bank_holiday/` | Bank Holiday Bartender | Win the Bank Holiday weekly event | Mint waistcoat and bow tie over a white shirt, sleeves rolled, a protractor tucked in her breast pocket. |
| Juno | `art/heroines/juno/pass_s1/` | Neon Nights Mixologist | Season 1: Neon Nights premium track | Sleek black jumpsuit with cyan neon piping, hair up with a glowing cocktail-stick pin. |
| Kat | `art/heroines/kat/date/` | Gig night | Finish her story | Red plaid flannel over a band tee, black jeans, bass strap over one shoulder, silver rings. |
| Kat | `art/heroines/kat/league/` | League jersey | 120 gems | Last Call League jersey in her colour with her name and number on the back, track pants, sneakers, sweatband. |
| Kat | `art/heroines/kat/neon/` | Neon Nights | 250 gems | Neon party look in her colour: glowing piping, holographic jacket, LED-trim sneakers, glow bracelets. |
| Kat | `art/heroines/kat/static_night/` | Static Night Stagewear | Win the Static Night weekly event | Red leather jacket with a lightning-bolt patch, ripped black tee, studded belt, red stage lights on her. |
| Kat | `art/heroines/kat/pass_s1/` | Neon Nights Headliner | Season 1: Neon Nights premium track | Holographic bomber jacket, mesh-sleeve band tee, platform boots, glow-stick bracelets. |
| Sable | `art/heroines/sable/date/` | Gala | Finish her story | Floor-length deep purple gown with long sleeves, hair up, pearl earrings. |
| Sable | `art/heroines/sable/league/` | League jersey | 120 gems | Last Call League jersey in her colour with her name and number on the back, track pants, sneakers, sweatband. |
| Sable | `art/heroines/sable/neon/` | Neon Nights | 250 gems | Neon party look in her colour: glowing piping, holographic jacket, LED-trim sneakers, glow bracelets. |
| Sable | `art/heroines/sable/grand_opening/` | Grand Opening Gown | Win the Grand Opening weekly event | Gold sequinned evening dress with long sleeves and a high neck, hair in a sleek wave, the original Afterglow sign pin. |
| Sable | `art/heroines/sable/pass_s1/` | Neon Nights Proprietor | Season 1: Neon Nights premium track | Tailored violet suit with a neon-thread lapel, silk shirt buttoned to the collar, gold cufflinks. |

## Cup and championship memories

| File | Title | Brief |
| --- | --- | --- |
| `art/scenes/cup_bronze.png` | Bronze Cup Night | The three regulars, mid-celebration in their league jerseys, crowd around you and the bronze trophy at the bar, Mila on your shoulders. |
| `art/scenes/cup_silver.png` | Silver Cup Afterparty | Afterparty in the lounge: the heroines in party hats under a falling pile of silver confetti, everyone laughing, Juno spraying a can of whipped cream. |
| `art/scenes/cup_gold.png` | Gold Cup Champions | The four heroines hoist you onto the championship table with the gold cup, streamers everywhere, Kat's band playing in the corner. |
| `art/scenes/finale.png` | Afterglow | Dawn after the championship: you and all four heroines crowd around the championship table under the neon sign for a group photo. Mila on the rail, Juno holding a napkin, Kat with her bass, Sable holding the deed, the 'SOLD' banner torn in half on the floor. |

## Crossover memories

Two heroines in one image, unlocked from After Hours once you're far enough with both.

| File | Title | Who | Brief |
| --- | --- | --- | --- |
| `art/scenes/x_mila_juno.png` | Fries and Napkins | Mila and Juno | Mila and Juno sit on either side of you on the bar in league jerseys, one holding out a fry and the other a napkin diagram, glaring at each other over your head. |
| `art/scenes/x_juno_kat.png` | Sister Bars | Juno and Kat | Juno and Kat sit back to back on the Static's bumper table sharing one cocktail with two straws while you hold the spirit level, both trying not to laugh. |
| `art/scenes/x_kat_sable.png` | For Ray | Kat and Sable | Sable in her blazer and Kat in her band tee lean side by side on the Static's old table under a framed photo of Uncle Ray, toasting with two glasses, both pretending they aren't teary. |
| `art/scenes/x_mila_sable.png` | Speed Lesson | Mila and Sable | Sable stands behind Mila at the table guiding her wrist on the paddle, Mila still in her helmet and grinning at you over her shoulder. |

## Table and backgrounds

| File | Size | Brief |
| --- | --- | --- |
| `art/table/table.png` | 1920x1080 | Top-down playfield, exactly 16:9. Goals on the left and right short edges, centred, 43% of the height wide. Centre line and circle. Neon arcade style. |
| `art/table/puck.png` | 128x128 | Light grey or white; the game tints it gold for your smash and her colour for her signature. |
| `art/table/paddle_player.png` | 256x256 | Your paddle, cyan. |
| `art/bg/lounge.png` | 1920x1080 | The Afterglow after hours: arcade cabinets, neon signs, the air hockey table, a juice and soda bar. Shown dimmed behind most screens. |
| `art/bg/menu.png` | 1920x1080 | Title screen. Keep the left 40% calm: the menu buttons sit there. |
| `art/ui/logo.png` | 1200x450 | "Neon Puck Rivals" logo, transparent. |

## Store and free-to-play UI

All transparent PNGs. Until they exist the game uses the flat icons drawn by `tools/make_f2p_icons.py`.

| File | Size | Brief |
| --- | --- | --- |
| `art/ui/icons/gem.png` | 128x128 | The premium currency: a cut cyan gem with a neon glow. |
| `art/ui/icons/life.png` | 128x128 | A life: an air hockey puck with a pink heart on it. |
| `art/ui/icons/ad.png` | 128x128 | "Watch an ad" marker: a small gold screen with a play button. |
| `art/ui/store/gems_80.png` | 256x192 | Pocket of Gems: a pile of 80 gems (bigger pile for bigger packs). |
| `art/ui/store/gems_450.png` | 256x192 | Bag of Gems: a pile of 450 gems (bigger pile for bigger packs). |
| `art/ui/store/gems_1000.png` | 256x192 | Box of Gems: a pile of 1000 gems (bigger pile for bigger packs). |
| `art/ui/store/gems_2200.png` | 256x192 | Crate of Gems: a pile of 2200 gems (bigger pile for bigger packs). |
| `art/ui/store/starter_pack.png` | 256x192 | Starter Pack: a gift box with gems, tip coins and a paddle peeking out. |
| `art/ui/store/remove_ads.png` | 256x192 | Remove Ads: a TV screen with a neon "no" sign over it, playful not angry. |
| `art/ui/store/lounge_pass.png` | 256x192 | VIP Lounge Pass: a gold VIP lanyard and card with the Afterglow logo. |

## Google Play listing (needed to publish)

| File (anywhere, uploaded in Play Console) | Size | Brief |
| --- | --- | --- |
| App icon | 512x512, 32-bit PNG | A glowing puck and paddle, or one heroine's face with a paddle. Readable at tiny sizes, no text. |
| Adaptive launcher icon | 432x432 foreground + 432x432 background | Same design split into layers; set in the export preset (`launcher_icons/*`). |
| Feature graphic | 1024x500, no transparency | All four rivals behind the glowing table, logo on one side. Nothing important near the edges. |
| Phone screenshots | 1920x1080 (at least 2, up to 8) | A match mid-smash, the roster, a memory, the Wardrobe, a dialogue scene. Real gameplay, all Teen-safe. |
| Promo video (optional) | YouTube link | 30 seconds of matches and story. |

## Counts

| Group | Files |
| --- | --- |
| Crack stages (default outfit) | 16 |
| Dialogue expressions | 4 to 28 |
| Story memories | 24 |
| Cup and championship memories | 4 |
| Crossover memories | 4 |
| Outfits (20 extra in all, 1 to 4 images each) | 20 to 80 |
| Table, puck, paddles | 7 |
| Backgrounds and logo | 3 |
| Store and F2P UI | 11 |
| Play listing | 5 to 11 |
