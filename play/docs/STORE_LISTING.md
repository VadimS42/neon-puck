# Neon Puck Rivals: Google Play listing lines

Copy-paste text for Play Console. Character limits are Google's.

## App name (30 max)

Neon Puck Rivals

Alternatives: "Neon Puck: Last Call League", "Neon Puck: Rival Hearts".

## Short description (80 max)

Neon air hockey: beat four rivals, win them over, and claim the Last Call crown.

## Full description (4000 max)

The new manager of a neon arcade lounge walks in. The regulars hate you on sight.

Mila, the bike courier whose bike you towed. Juno, the bartender whose job you got. Kat, who owns the bar across the street. And Sable, the legend who founded the Afterglow and hasn't lost a match in six years. There's only one way to win them over: beat them on the air hockey table.

PURE SKILL, ZERO LUCK
Every shot is real physics. Where and how hard you hit is where the puck goes. Bank shots, power smashes, saves at the buzzer: no dice, no hidden rolls.

MAKE THEM LOSE THEIR COOL
Every goal cracks your rival's cool. Score a power smash and she cracks all at once: slower, smaller, rattled. The more she loses it, the easier she is to beat.

FOUR RIVALS, FOUR STYLES
Mila plays fast. Juno never hits the puck straight. Kat saves her best for last. Sable bends the puck around you. Each has a signature shot to learn to block, and once you win her over, she teaches it to you.

FROM "HATES YOU" TO "TOGETHER"
Six story matches per rival, with dialogue before and after every one. Win, and watch her go from glaring at you to sharing fries at 4 AM. Every win unlocks a memory for your album.

GEAR UP AND DRESS UP
Spend your tips in the Pro Shop on paddles, gloves, sneakers and lucky charms. Pick power-ups before a match. Unlock new outfits for every rival in the Wardrobe.

CUPS AND THE CHAMPIONSHIP
Fight through the Bronze, Silver and Gold Cups, then take on all four rivals back to back in the Last Call Championship to save the Afterglow.

FEATURES
- Fast, one-finger air hockey built for phones
- 24 story matches plus pickup games, three cups and a final championship
- Four rivals with their own play styles and signature shots
- Story, Normal and Hard difficulty, switch any time
- Daily rewards, outfits, gear and power-ups
- Plays offline

Neon Puck Rivals is free to play. It shows ads and offers optional in-app purchases, including items bought with real money. You can turn off in-app purchases in your Google Play settings.

## Category and tags

- Category: Games > Sports (alternative: Arcade)
- Tags: Air hockey, Arcade, Sports, Casual, Story

## Content rating questionnaire (IARC): expected answers

- Violence: none.
- Sexuality: suggestive themes only (flirting, romance, kissing). No nudity.
- Language: mild at most ("shut up", "creep"-level teasing is gone).
- Controlled substances: references to alcohol (the setting is a lounge with a bar; nobody drinks on screen). Answer yes to "references".
- Gambling: none. No loot boxes, no random paid rewards.
- User interaction: none (no chat, no user content).
- In-app purchases: yes. Ads: yes.
- Expected result: Teen / PEGI 12 / USK 12.

## Target audience (Play Console > App content > Target audience)

Pick **16-17 and 18+** (or 13-15 and up at most). Do not include under-13 age groups: that puts the app under the Families policy, which restricts the ad SDK and romance content.

## Data safety form (with AdMob and Play Billing)

- Data collected: Device or other IDs (advertising ID), App interactions, Diagnostics (crash logs), Purchase history.
- Shared: Device or other IDs and App interactions with Google AdMob for advertising.
- Encrypted in transit: yes. Data deletion: the game keeps no account; progress lives on the device and is removed by uninstalling. Say so.
- Privacy policy URL: required. Set the same URL in `scripts/screens/SettingsScreen.gd` (PRIVACY_URL).

## In-app products to create (Play Console > Monetize > Products > In-app products)

| Product id | Type | Price (US) | Grants |
| --- | --- | --- | --- |
| gems_80 | Consumable | $0.99 | 80 gems |
| gems_450 | Consumable | $4.99 | 450 gems |
| gems_1000 | Consumable | $9.99 | 1,000 gems |
| gems_2200 | Consumable | $19.99 | 2,200 gems |
| starter_pack | Non-consumable (one time) | $1.99 | 200 gems, 1,500 tips, Felt-rim paddle, 3 Energy Drinks, 3 Grip Tapes |
| remove_ads | Non-consumable | $2.99 | No interstitial ads |
| lounge_pass | Non-consumable | $7.99 | 8 max lives, 2x refill speed, +20% tips, no interstitials |

The ids must match `data/monetization.json`. Prices there are placeholders; the game shows Google's localized prices once billing is connected.

## What's new (first release)

First release: four rivals, 24 story matches, three cups and the Last Call Championship.
