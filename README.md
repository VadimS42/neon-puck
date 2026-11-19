# Neon Puck (working title): prototype v0.1

An 18+ arcade air hockey game in Godot 4.3, built the same way as Charm
Combo: one `Main.tscn`, every screen built in code, data in JSON, art found
by path with placeholders until it exists.

**The hook:** strip air hockey. A bar chain bought the Afterglow, a neon
arcade lounge, and sent you as its new night manager. The regulars hate
you (you towed Mila's bike, took Juno's job, and you're the face of the
company Sable sold her lounge to). They play the Last Call League: one
table, first to N, and every layer an opponent loses makes her weaker.
Beat each of them four times to win her over.

## Run it

Open this folder in Godot 4.3 and press F5. Window is 1280x800 and scales.
Set up `export_presets.cfg` the way Charm Combo's is to ship Windows / Android.

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
  Sable: Hook). It's announced when she arms it, it's always the same shot,
  and her card tells you how to stop it. Block it for Heat; let it in and
  your Heat drains.
- **Hostile-to-love story.** Each heroine has 4 matches: Hates you → Rival
  → Grudging respect → Falling for you → Yours, shown on her roster card.
  A prologue sets it up, dialogue plays before and after every match, and
  she taunts or reacts in a speech bubble during play (hostile lines in
  her first two matches, flirty ones after).
- **Progression without grind.** Win a heroine over completely and she
  teaches you her signature shot; pick it as your power shot on the roster.
- **Short matches.** First to 5, 6, 6, then 7 across her four matches.
- **All-ages mode** in Settings for a separate SFW build (uses `*_sfw.png`
  art when present).

## What it fixes from the Tennis Angels research

| Complaint | Here |
| --- | --- |
| Luck-based matches, "slot machine" shots | Deterministic physics; no hidden rolls on your shots |
| AI returns everything | She sees the puck late (`reaction`), has a capped paddle speed and acceleration, and gets weaker per layer |
| 30-minute matches | First to 5-7 |
| Grind gates scenes | No levels or currency. Each win plays her next story beat and unlocks a scene |
| Story hidden in the gallery | Dialogue plays before and after every match, in the main flow |
| Too few scenes, too short | 3 strip stages per match plus a scene per win: 12 scenes and 12 stages across 3 heroines (12 matches), easy to add more in JSON |
| Unappealing protagonist | Faceless player; the camera stays on the heroines |
| Non-consensual framing | They hate you, but everyone signed the league rules; the hostility is comedic and consensual |
| Liked: girls who dislike you at first | Every heroine starts hostile with her own grudge and is won over across 4 matches |
| Liked: each girl plays differently | Speed, banks and curves styles, each with a signature shot and a counter-tip |
| Liked: depth to learn | Learn each girl's signature shot when you win her over |
| Liked: comedy | Rewritten dialogue plus in-match taunts and reactions |
| Liked: separate all-ages build | All-ages mode switch |
| Difficulty | Story / Normal / Hard any time, plus a Story-difficulty rematch button after a loss and an unlock-all gallery |

## Files

| Path | What |
| --- | --- |
| `data/heroines.json` | Heroines, stats, outfit layers and their effects, signature shots, match targets, all dialogue and scene briefs. Edit freely. |
| `scripts/game/PuckSim.gd` | The table as plain math (no nodes): puck, paddles, walls, goals, Heat, power shots |
| `scripts/game/AIBrain.gd` | Her paddle: defend, attack, banks, signature arming |
| `scripts/game/MatchRules.gd` | Score, Composure, stripping and stat drops |
| `scripts/screens/*.gd` | Age gate, menu, how to play, roster, dialogue, match, results, scene viewer, gallery, settings |
| `scripts/ArtAssets.gd` | Every art path the game looks for |
| `scripts/HeroinePortrait.gd` | Her art, or the placeholder figure |
| `docs/ART_LIST.md` | Everything to commission, with paths, sizes and briefs |
| `tools/sim_test.gd` | Headless balance check (bot vs every heroine at every difficulty) |

## Balance check

```
godot --headless --path . -s tools/sim_test.gd -- games=12 bot=weak
```

`bot=weak|normal|strong` sets how good the stand-in player is. It's a bot,
not a person, so treat it as a sanity check; real playtests should set the
final numbers. Tuning knobs: her stats and layer values in
`heroines.json`, the difficulty table at the top of it, `GOAL_W`,
`FRICTION` and `HEAT_MAX` in `PuckSim.gd`.

## Debug launch options

After `--` on the command line: `screen=menu|roster|vn|match|result|scene|gallery|settings|howto`,
`id=mila|juno|sable`, `m=0..2` (match), `stage=0..3`, `autoplay=1` (a bot
plays you), `speed=4` (fast-forward), `shot=out.png delay=2` (screenshot
and quit).

## Not in yet

Music, real SFX, a Live2D or frame-animated scene pipeline (Charm Combo's
`FrameAnimation.gd` / `LiveSprite.gd` could be reused), translations,
Steam achievements, and an all-ages build switch.
