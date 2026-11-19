# Neon Puck (working title): prototype v0.2

An 18+ arcade air hockey game in Godot 4.3, built the same way as Charm
Combo: one `Main.tscn`, every screen built in code, data in JSON, art found
by path with placeholders until it exists.

**The hook:** strip air hockey. A bar chain bought the Afterglow, a neon
arcade lounge, and sent you as its new night manager. The regulars hate
you (you towed Mila's bike, took Juno's job, your league night stole Kat's
crowd at the bar across the street, and you're the face of the company
Sable sold her lounge to). They play the Last Call League: one table,
first to N, and every layer an opponent loses makes her weaker. Beat each
of them six times to win her over, then win the Last Call Championship
to buy the Afterglow back.

**PG-13 Google Play version:** a separate free-to-play project lives in
`play/` (own app id, save and data; see `play/README.md`). Godot skips that
folder when you open this project, and the Android export excludes it.

## Run it

Open this folder in Godot 4.3 and press F5. Window is 1280x800 and scales.
## Android APK

`export_presets.cfg` has an Android preset (landscape, arm64 + armv7,
package `com.neonpuck.prototype`). On a phone the paddle follows your
finger; tap SMASH, or put a second finger on the table, to arm the smash.
The back button works like Esc.

```
godot --headless --path . --export-release "Android" build/android/unsigned.apk
python3 tools/sign_apk.py build/android/unsigned.apk build/android/NeonPuck.apk
```

`tools/sign_apk.py` signs with APK Signature Scheme v2 (Android 7 and up)
using only Python, for machines without the Android SDK. Godot still wants
an SDK path in Editor Settings; any folder with `platform-tools/adb` and
`build-tools/<ver>/apksigner` files passes the check when the preset is
unsigned. With the real SDK installed you can set `package/signed=true`
instead. Keep the same key file between builds or phones refuse the update.

Controls: the paddle follows the mouse or your finger (WASD / arrows / left
stick also work). Click the table, press Space or A, or tap SMASH to arm a
power smash when your Heat is full. Esc pauses.

## How it plays

- **Pure physics, zero dice.** Where and how hard you hit is where the puck
  goes. Her only randomness is which spot of your goal she aims at.
- **Heat → Smash.** Hits, saves and goals fill your Heat (bank goals most).
  Full Heat arms a power smash: your next hit flies at top speed.
- **Composure → layers.** She has 2 Composure per layer. Each goal you score
  knocks off 1; a smash that scores knocks off a whole layer. Her goals win
  back 1 Composure, never a layer.
- **Stripping weakens her.** Every layer carries a stat (paddle speed,
  paddle size or reactions), shown on her card. Landing smashes early makes
  the rest of the match easier, so the reward and the strategy are the same
  thing.
- **Signature shots.** Each heroine has one (Mila: Bullet, Juno: Ricochet,
  Kat: Slingshot, Sable: Hook). It's announced when she arms it, it's always the same shot,
  and her card tells you how to stop it. Block it for Heat; let it in and
  your Heat drains.
- **Hostile-to-love story.** Four heroines, 6 matches each: Hates you →
  Rival → Grudging respect → Friendly → Crushing on you → Falling for you
  → Yours, shown on her roster card. Kat unlocks after 4 story wins and
  Sable after you win over two of the others. Winning over all four opens
  the Last Call Championship: all four back to back, then the epilogue.
  A prologue sets it up, dialogue plays before and after every match, and
  she taunts or reacts in a speech bubble during play (hostile lines in
  her first two matches, flirty ones after).
- **Learn their shots.** Win a heroine over completely and she teaches you
  her signature shot; pick it as your power shot on the roster.
- **Light grind, never in front of a scene.** Matches pay XP and tips.
  Levels gate only the *next story match*; every scene unlocks the moment
  you win its match. Story wins earn most of the XP you need, and the last
  few gates ask for a pickup game or a cup.
- **Pro Shop.** Four gear slots (paddle, glove, sneakers, lucky charm), up
  to 5 tiers each, adding speed, size, hit power, Heat gain and smash speed.
- **Power-ups.** Seven one-match boosts (full Heat start, bigger paddle,
  she strips faster, Heat fills faster, her signature charges slower,
  speed and power, a Heat refill at her match point). 1 to 3 slots by level,
  picked on the loadout screen before each match.
- **Pickup games.** First to 5 against anyone you've unlocked, with a win
  streak bonus.
- **Cups.** Bronze, Silver and Gold: pay the entry, win 3 or 4 rounds in a
  row as opponents sharpen, take the prize and a cup scene.
- **Short matches.** First to 5, 5, 6, 6, 7, 7 across her six matches.
- **All-ages mode** in Settings for a separate SFW build (uses `*_sfw.png`
  art when present).

## What it fixes from the Tennis Angels research

| Complaint | Here |
| --- | --- |
| Luck-based matches, "slot machine" shots | Deterministic physics; no hidden rolls on your shots |
| AI returns everything | She sees the puck late (`reaction`), has a capped paddle speed and acceleration, and gets weaker per layer |
| 30-minute matches | First to 5-7 |
| Grind gates scenes | Levels gate only the next story match, never a scene; each win unlocks its scene at once |
| Finished too fast / not enough to do | About 2.5 to 3 hours of story alone (28 story matches), plus a shop, power-ups, cups and pickup games |
| Story hidden in the gallery | Dialogue plays before and after every match, in the main flow |
| Too few scenes, too short | 3 strip stages per match plus a scene per win: 28 scenes (24 story, 3 cups, 1 finale) and 16 strip stages across 4 heroines, easy to add more in JSON |
| Unappealing protagonist | Faceless player; the camera stays on the heroines |
| Non-consensual framing | They hate you, but everyone signed the league rules; the hostility is comedic and consensual |
| Liked: girls who dislike you at first | Every heroine starts hostile with her own grudge and is won over across 4 matches |
| Liked: each girl plays differently | Speed, banks and curves styles, each with a signature shot and a counter-tip |
| Liked: depth to learn | Learn each girl's signature shot when you win her over |
| Liked: shop, gear, tournaments | Pro Shop with 4 gear slots and 5 tiers, power-ups, three cups |
| Liked: comedy | Rewritten dialogue plus in-match taunts and reactions |
| Liked: separate all-ages build | All-ages mode switch |
| Difficulty | Story / Normal / Hard any time, plus a Story-difficulty rematch button after a loss and an unlock-all gallery |

## Files

| Path | What |
| --- | --- |
| `data/heroines.json` | Heroines, stats, outfit layers and their effects, signature shots, match targets and levels, all dialogue, scene briefs and the finale. Edit freely. |
| `data/progression.json` | XP curve, rewards, gear, power-ups, cups. Edit freely. |
| `scripts/game/PuckSim.gd` | The table as plain math (no nodes): puck, paddles, walls, goals, Heat, power shots |
| `scripts/game/AIBrain.gd` | Her paddle: defend, attack, banks, signature arming |
| `scripts/game/MatchRules.gd` | Score, Composure, stripping and stat drops |
| `scripts/screens/*.gd` | Age gate, menu, how to play, roster, loadout, Pro Shop, cups, dialogue, match, results, scene viewer, gallery, settings |
| `scripts/ArtAssets.gd` | Every art path the game looks for |
| `scripts/HeroinePortrait.gd` | Her art, or the placeholder figure |
| `docs/ART_LIST.md` | Everything to commission, with paths, sizes and briefs (regenerate with `python3 tools/gen_art_list.py`) |
| `tools/sim_test.gd` | Headless balance check (bot vs every heroine at every difficulty) |
| `tools/playthrough_test.gd` | Headless playthrough: a bot plays the whole game and it prints the time |

## Balance check

```
godot --headless --path . -s tools/sim_test.gd -- games=12 bot=weak
```

`bot=weak|normal|strong` sets how good the stand-in player is.

```
godot --headless --path . -s tools/playthrough_test.gd -- bot=normal side=0
```

plays the whole story (`side=0`: story only, ignoring level gates; `side=1`:
respects gates, buys gear, plays cups and pickup games) and prints the time
with 4.5 s per dialogue line and 25 s per scene. It's a bot,
not a person, so treat it as a sanity check; real playtests should set the
final numbers. Tuning knobs: her stats and layer values in
`heroines.json`, the difficulty table at the top of it, `GOAL_W`,
`FRICTION` and `HEAT_MAX` in `PuckSim.gd`.

## Debug launch options

After `--` on the command line: `screen=menu|roster|vn|match|result|scene|gallery|settings|howto`,
`screen=shop|cups|prematch` too, `id=mila|juno|kat|sable`, `m=0..5` (match), `all=1 lv=12` (unlock everything, no save), `stage=0..3`, `autoplay=1` (a bot
plays you), `speed=4` (fast-forward), `shot=out.png delay=2` (screenshot
and quit).

## Assets from Charm Combo

Brought over with their licences checked (credits on the in-game Credits
screen, from `data/credits.txt`):

| Path | What | Licence |
| --- | --- | --- |
| `art/ui/icons/` white icons (trophy, shoppingBasket, gear, question, information, star, home, exit, right, return, fastForward) | Game Icons by Kenney | CC0 (`LICENSE_kenney.txt`) |
| `art/ui/icons/` coin, heart_full, heart_empty and the power-up icons | Drawn for Neon Puck by `tools/make_icons.py` (flat neon, no licence to track) | Ours |
| `audio/music/lounge.ogg`, `scene.ogg` | Sascha Ende, "Sexy Scene Instrumentals Vol. 4" and "Sexy Scene Vol. 3" | CC BY 4.0, credit required |
| `audio/music/match.ogg` | Alex McCulloch, "Binary Underwater Village" | CC0 |

Left behind on purpose: Charm Combo's menu theme and ending track (no licence
recorded), the forest and underwater themes (wrong mood), the fantasy-style icons
and gems, the voice lines and character art (they belong to that game's cast).
Replace any track by dropping a file with the same name into `audio/music/`.

## Not in yet

Real SFX, original music, a Live2D or frame-animated scene pipeline (Charm Combo's
`FrameAnimation.gd` / `LiveSprite.gd` could be reused), translations,
Steam achievements, and an all-ages build switch.
