# Neon Puck Rivals: PG-13 free-to-play build for Google Play

A separate Godot 4.3 project, forked from the 18+ Neon Puck in the parent
folder. It has its own app id (`com.neonpuck.rivals`), its own save folder
and its own data, and shares no files with the 18+ game at runtime. Godot
skips this folder when you open the parent project (it contains its own
`project.godot`), so neither game can pull in the other's content.

Open **this folder** (`play/`) in Godot 4.3 and press F5.

## What changed from the 18+ game

| 18+ game | This build |
| --- | --- |
| Strip layers that weaken her | **Her Cool**: each goal knocks off a Cool pip, a power smash cracks her at once. Each crack is a change of expression and pose (smirk gone, hair tie snaps, full meltdown), never clothing, and lowers the same stat the layer did. Gameplay is identical. |
| Adult scenes | **Memories**: every scene rewritten as a Teen-safe moment. Each romance ends with a kiss. |
| Age gate, all-ages switch | Removed. The whole build is PG-13. |
| Gallery unlock-all in Settings | Removed (the Album fills as you play). |
| Alcohol-forward lines | Sodas, milkshakes, sparkling cider and mocktails. The lounge still has a bar in the background. |
| Scene music track ("Sexy Scene Vol. 3 [With Ultra Sexy Voice]") | Removed; scenes use the lounge theme. |
| One outfit per heroine | **Wardrobe**: 4 cosmetic outfits each (default, Date from finishing her story, League jersey and Neon Nights for gems). |

The full rewritten dialogue is in `docs/SCRIPT.md` (246 lines), the art to
commission in `docs/ART_LIST.md`, and the Play Store text in
`docs/STORE_LISTING.md`.

## Free-to-play systems

All numbers are in `data/monetization.json`.

- **Lives**: 5 max, one refills every 20 minutes. A match takes a life
  when it starts and gives it back on a win, so only losses and quits cost
  one. Replays of won matches and cup rounds after the first are free. Out
  of lives: wait, watch an ad (+1, 5 a day), refill for 30 gems, or 2 hours
  unlimited for 60 gems.
- **Gems** (premium): 25 to start, 5 per first story win, 30 for finishing a
  rival's story, 10/20/40 for cups, 5 and 20 from the daily streak. Spent
  on lives, tips and outfits.
- **Tips** (soft currency): unchanged. Earned from matches, spent in the
  Pro Shop. Gems can be swapped for tips in the Store.
- **Daily reward**: 7-day streak shown on the menu, resets if you miss a day.
- **Store** (real money): four gem packs ($0.99 to $19.99), a one-time
  Starter Pack ($1.99), Remove Ads ($2.99) and the VIP Lounge Pass ($7.99:
  8 lives, double refill speed, +20% tips, no ads). No loot boxes and no
  random paid rewards.
- **Ads**: rewarded ads only when the player taps them (extra life, double
  tips on the result screen, a free power-up once a day). Interstitials only
  between matches, never in the first 4 matches, at most every 3 matches and
  3 minutes, never before a story memory, and never for anyone who has paid
  for anything. No banners.

## Difficulty curve and revives

Later matches get much sharper on top of the chosen difficulty
(`difficulty_curve` in `data/monetization.json`), keyed by the level a
match needs:

| Tier | Match levels | Her speed | Reactions | Aim | Extra Cool per crack |
| --- | --- | --- | --- | --- | --- |
| Warm-up | 1-3 | x1.00 | normal | normal | 0 |
| League | 4-6 | x1.08 | -0.015 s | x0.90 | 0 |
| Pro | 7-9 | x1.20 | -0.035 s | x0.75 | +1 |
| Legend | 10-11 | x1.28 | -0.045 s | x0.65 | +1 |
| Last Call | 12 (Sable's last match, the championship) | x1.32 | -0.05 s | x0.60 | +1 |

Lose a match and a revive card appears: watch an ad (once per match) or pay
gems (20, then 40, then 80) to keep playing with her score pulled back to 3
short of winning and your Heat full. `tools/curve_test.gd` measures win
rates for a bot with best gear, with and without 3 power-ups and a revive.

## Test backends (what's real and what's stubbed)

| Piece | Status |
| --- | --- |
| Lives, gems, daily reward, outfits, ad pacing, store grants | Real and tested (`tools/f2p_test.gd`, 31 checks). |
| Google Play Billing | Code written in `autoload/Store.gd` against the Godot Google Play Billing plugin. It switches on automatically when the plugin is in the Android build. **Not tested on a device yet.** Without the plugin every purchase succeeds for free and says TEST. |
| AdMob ads | **Stubbed.** `autoload/Ads.gd` shows a full-screen "TEST AD" card with a countdown in place of a real ad. Three small functions (`_real_rewarded`, `_real_interstitial`, `_real_init`) are where the AdMob plugin calls go. |
| Ad consent (GDPR / UMP) | Stubbed in `Ads.request_consent`. Needs the UMP form from the AdMob plugin before release in the EU/UK. |

`README_PLAY.md` has the steps to swap the stubs for the real SDKs and
publish.

## Run, test, debug

```
godot --headless --path . -s tools/f2p_test.gd          # free-to-play rules
godot --headless --path . -s tools/playthrough_test.gd -- bot=normal side=1
godot --headless --path . -s tools/sim_test.gd -- games=12 bot=weak
python3 tools/gen_art_list.py                           # docs/ART_LIST.md
python3 tools/gen_script.py                             # docs/SCRIPT.md
```

Debug screens: `-- screen=menu|roster|store|wardrobe|shop|prematch|result|match|gallery|settings|howto|nolives|daily all=1`.

## Files that differ from the 18+ project

| Path | What |
| --- | --- |
| `data/heroines.json` | PG-13 dialogue, cracks instead of layers, outfits, memory briefs |
| `data/progression.json` | Cup memory briefs, Spotlight power-up text |
| `data/monetization.json` | Lives, gems, daily rewards, ads, products (new) |
| `autoload/GameState.gd` | Free-to-play state and rules; no age gate or all-ages switch |
| `autoload/Store.gd`, `autoload/Ads.gd` | Billing and ads (new) |
| `scripts/screens/StoreScreen.gd`, `WardrobeScreen.gd` | New screens |
| `scripts/ArtAssets.gd` | Outfit-aware art lookups |
| `scripts/HeroinePortrait.gd` | Dressed placeholder that reacts to cracks |
| `scripts/Main.gd`, `UI.gd`, other screens | Lives checks, ad hooks, popups, Store/Wardrobe buttons, new wording |
| `export_presets.cfg` | "Android test APK" and "Google Play AAB" presets, `com.neonpuck.rivals` |
| `tools/f2p_test.gd`, `gen_script.py`, `make_f2p_icons.py` | New tools |

Bug fixes to the shared game code (physics, AI, matches) need making in both
projects; they're plain copies today.
