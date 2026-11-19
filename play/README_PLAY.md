# Shipping Neon Puck Rivals on Google Play

A checklist from this build to a published app. Nothing here has been done
yet; each step needs you (your Play Console account, your keys, your money).

## 1. Accounts and app

1. Google Play Console developer account ($25 one-time). New personal
   accounts must run a **closed test with at least 12 testers for 14 days**
   before they can publish to production. Start that early.
2. Create the app: name "Neon Puck Rivals", game, free, package
   `com.neonpuck.rivals` (set in `export_presets.cfg`; it can never change
   after the first upload).
3. Fill in App content: privacy policy URL, ads = yes, target audience
   (13+ or 16+, **not** under 13), content rating questionnaire, data safety
   form. Answers are drafted in `docs/STORE_LISTING.md`.

## 2. Build setup (one time)

1. Install Godot 4.3 export templates and the Android build template
   (Project > Install Android Build Template). The "Google Play AAB" preset
   uses a Gradle build, which plugins need.
2. Android SDK with build tools and platform 35; JDK 17. Point Godot's
   Editor Settings at them.
3. Make an upload keystore and keep it safe (losing it means you can't
   update the app; Play App Signing holds the real signing key):
   `keytool -genkey -v -keystore upload.keystore -alias upload -keyalg RSA -keysize 2048 -validity 10000`
   Set it in the preset's release keystore fields (not committed to git).
4. Target API: Play requires a recent target SDK (the preset sets 35;
   check Play's current requirement before each release and raise it).

## 3. Real billing

1. Add the Godot Google Play Billing plugin for Godot 4
   (github.com/godot-sdk-integrations/godot-google-play-billing) to
   `addons/` and enable it in the "Google Play AAB" preset's plugin list.
2. `autoload/Store.gd` detects the `GodotGooglePlayBilling` singleton and
   switches from the test store. It was written against the plugin's
   documented API; check signal names against the plugin version you
   install, because they have changed between versions.
3. Create the 7 in-app products in Play Console with the ids in
   `data/monetization.json` (table in `docs/STORE_LISTING.md`).
4. Add your Google account as a license tester and buy each product from an
   internal-test build. Check: gems arrive once, packs can't be bought
   twice, Restore purchases brings back Remove Ads and the pass after a
   reinstall, a cancelled purchase grants nothing.
5. Recommended before a big launch: verify purchase tokens on a small
   server (Google Play Developer API) so modified APKs can't fake purchases.

## 4. Real ads

1. Create an AdMob account and app, link it to the Play app, and create a
   rewarded unit and an interstitial unit.
2. Add an AdMob plugin for Godot 4 (for example Poing Studios'
   godot-admob-plugin) and its Android dependencies.
3. In `autoload/Ads.gd` set `backend` to the real one and fill in
   `_real_init` (initialize, load ads), `_real_rewarded` (show, call
   `cb.call(true)` from the reward callback and `GameState.note_rewarded`)
   and `_real_interstitial` (show, call `cb` when dismissed). Pacing rules
   stay in GameState, so nothing else changes.
4. Set the max ad content rating to **T** (Teen) in AdMob, and turn on
   Google's UMP consent form for the EU/UK; call it from
   `Ads.request_consent`.
5. Use Google's test ad unit ids until the app is approved. Never tap your
   own live ads.

## 5. Store listing and art

- Text: `docs/STORE_LISTING.md`.
- Art: the "Google Play listing" section of `docs/ART_LIST.md` (icon,
  feature graphic, screenshots), plus the in-game art in priority order.
- Replace `PRIVACY_URL` in `scripts/screens/SettingsScreen.gd` with the
  hosted policy.
- Credits: fill in names in `data/credits.txt`. The lounge track's title
  contains the word "Sexy"; it's instrumental and CC BY, but you may want to
  replace it with a track whose credit line reads better in a Teen game.

## 6. Release

1. Export "Google Play AAB", upload to Internal testing, test billing and
   ads on 2 or 3 real phones.
2. Closed testing (12+ testers, 14 days if your account needs it).
3. Production, staged rollout (10%, then 50%, then 100%).
4. Bump `version/code` in the preset for every upload.
