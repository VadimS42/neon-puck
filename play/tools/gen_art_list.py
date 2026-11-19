"""Regenerates docs/ART_LIST.md (PG-13 Google Play build) from the game data.
   python3 tools/gen_art_list.py
Outfit and crack-stage descriptions live in this file (OUTFIT_BRIEFS,
STAGE_BRIEFS); everything else comes from data/*.json."""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
d = json.load(open(os.path.join(ROOT, "data/heroines.json")))
prog = json.load(open(os.path.join(ROOT, "data/progression.json")))
f2p = json.load(open(os.path.join(ROOT, "data/monetization.json")))
order = d["order"]
H = d["heroines"]

STAGE_BRIEFS = {
    "mila": ["Smug grin, sunglasses pushed up on her head, one hand on her hip, ready to race.",
             "The grin is gone. Jaw set, glaring straight at you.",
             "Her ponytail has come loose; hair everywhere, blowing a strand out of her face.",
             "Comic meltdown: red-faced, fists clenched, mid-shout, cartoon sweat drops."],
    "juno": ["Arms folded, one eyebrow raised, pen tucked behind her ear. Unimpressed.",
             "One eyebrow twitching, a very tight smile.",
             "Holding a snapped pen in two halves, a little ink on her fingers, staring at it.",
             "Bow tie crooked, hair escaping its clip, blushing and pointing at you, mid-rant."],
    "kat":  ["Sunglasses on, chewing gum, thumbs hooked in her belt loops. Too cool.",
             "Shades yanked down her nose, glaring at you over them.",
             "Her guitar pick slipping out of her fingers, mouth open in disbelief.",
             "Leaning in, grin-snarl, a comic anger mark on her forehead. She's having fun now."],
    "sable": ["Perfect poker face, chin raised, hands clasped in front of her.",
              "A tiny smile tugging at her mouth that she's trying very hard to hide.",
              "Her sleek bun has come loose; strands across her face, eyes wide.",
              "Blushing, hand over her mouth, looking away. Flustered for the first time in years."],
}

OUTFIT_BRIEFS = {
    ("mila", "default"): "Pink and black cycling jacket zipped up, fitted athletic top, bike shorts over black leggings, fingerless gloves, messenger bag strap across her chest.",
    ("mila", "date"): "Oversized denim jacket over a pink skater dress with leggings, white sneakers, hair down with a star clip.",
    ("juno", "default"): "White shirt with rolled sleeves, black bartender vest, mint bow tie, black trousers.",
    ("juno", "date"): "Soft mint cardigan over a floral blouse, high-waisted trousers, round glasses.",
    ("kat", "default"): "Black leather jacket, faded band tee, jeans with knee rips, boots, sunglasses.",
    ("kat", "date"): "Red plaid flannel over a band tee, black jeans, bass strap over one shoulder, silver rings.",
    ("sable", "default"): "Purple velvet blazer, silk blouse buttoned to the collar, tailored trousers, heeled boots, sleek low bun.",
    ("sable", "date"): "Floor-length deep purple gown with long sleeves, hair up, pearl earrings.",
}
SHARED_OUTFITS = {
    "league": "Last Call League jersey in her colour with her name and number on the back, track pants, sneakers, sweatband.",
    "neon": "Neon party look in her colour: glowing piping, holographic jacket, LED-trim sneakers, glow bracelets.",
}

def outfit_brief(hid, oid):
    return OUTFIT_BRIEFS.get((hid, oid)) or SHARED_OUTFITS.get(oid, "")

o = []
w = o.append
w("# Neon Puck Rivals: art list (PG-13 Google Play build)\n")
w("Every piece of art this build looks for, with its exact path, size and a short brief")
w("for the artist. Drop a PNG at the path and the game uses it on next launch;")
w("nothing else changes (see `scripts/ArtAssets.gd`). Missing art falls back to the")
w("placeholder, so art can arrive piece by piece.\n")
w("Generated from the game data: `python3 tools/gen_art_list.py`.\n")
w("**Content rules for every image (Google Play, Teen rating):** fully clothed at all times,")
w("no underwear or swimwear shots, no suggestive poses or camera angles, romance stops at a")
w("kiss or a hug. Drinks are soda, milkshakes, tea or mocktails. All characters are adults (%s)" % ", ".join(str(H[i]["age"]) for i in order))
w("and should look it. None of the 18+ art can be reused here.\n")
w("## Priority order\n")
w("1. **Crack stages** (%d images): 4 per heroine in her default outfit. This is what players look at during every match." % (len(order) * 4))
w("2. **Table, puck, paddles** (%d images). Cheap and they lift the whole look." % (len(order) + 3))
w("3. **Store listing art** (icon, feature graphic, screenshots). Needed before you can publish.")
w("4. **Dialogue sprites**: `vn_neutral` per heroine first, then the other 6 expressions.")
w("5. **Memories** (%d story CGs, then 4 cup and finale CGs)." % sum(len(H[i]["matches"]) for i in order))
w("6. **Outfits** (Date, League jersey, Neon Nights). These are what players buy with gems, so they should look worth it.")
w("7. **Store and UI art** (gem packs, pass badges, backgrounds, logo).\n")
w("Minimum set to publish: items 1 to 3 plus `vn_neutral` per heroine (about %d files).\n" % (len(order) * 4 + len(order) + 3 + 8 + len(order)))

w("## Per heroine\n")
w("Replace `<id>` with %s. Same pose and outfit for all four crack stages, so the swap reads as her" % ", ".join("`%s`" % i for i in order))
w("cool cracking: only face, hair and body language change. Transparent background.\n")
w("| File | Size | Shown where | Brief |")
w("| --- | --- | --- | --- |")
w("| `art/heroines/<id>/stage_0.png` | 1024x1440 | Match card, roster, results | Cool and composed (see her row below). |")
w("| `art/heroines/<id>/stage_1.png` | 1024x1440 | After her first crack | First crack (see below). |")
w("| `art/heroines/<id>/stage_2.png` | 1024x1440 | After her second crack | Second crack. |")
w("| `art/heroines/<id>/stage_3.png` | 1024x1440 | After her third crack | Lost her cool completely, played for comedy. |")
w("| `art/heroines/<id>/vn_<expression>.png` | 1024x1440 | Dialogue | neutral, happy, shy, surprised, teasing, sad, angry. Default outfit, waist up is fine. |")
w("| `art/heroines/<id>/card.png` | 700x600 | Roster card, Wardrobe (optional) | Falls back to stage_0. |")
w("| `art/table/paddle_<id>.png` | 256x256 | Her paddle | Round, top-down, in her colour. |")
w("| `art/scenes/<id>_1.png` ... `<id>_6.png` | 1920x1080 | Memory after each story win | See briefs below. |\n")

for i in order:
    h = H[i]
    w("### %s (%d), `%s`, colour %s\n" % (h["name"], h["age"], i, h["color"]))
    w("%s Plays a %s style; signature shot: %s.\n" % (h["tagline"], h["style"].lower(), h["signature_name"]))
    w("**Default outfit (%s):** %s\n" % (h["outfits"][0]["name"], outfit_brief(i, "default")))
    w("Crack stages:\n")
    names = ["Cool"] + [L["name"] for L in h["layers"]]
    for n, (nm, br) in enumerate(zip(names, STAGE_BRIEFS[i])):
        w("- `stage_%d` **%s**: %s" % (n, nm, br))
    w("")
    w("Memories (she goes from hating you to falling for you across them):\n")
    for n, m in enumerate(h["matches"]):
        s = m["scene"]
        w("%d. **%s** (`art/scenes/%s.png`): %s" % (n + 1, s["title"], s["id"], s["brief"]))
    w("")

w("## Outfits (Wardrobe)\n")
w("Cosmetic only. Each outfit is a folder: `art/heroines/<id>/<outfit>/` holding `stage_0.png` to")
w("`stage_3.png` (same poses and expressions as her default set, new clothes) and optionally `card.png`")
w("and `vn_*.png`. Minimum per outfit is `stage_0.png` (shown for every crack); the full set of 4 is")
w("better. Dialogue keeps her default outfit unless you add `vn_*.png` to the folder.\n")
w("| Heroine | Folder | Outfit | How players get it | Brief |")
w("| --- | --- | --- | --- | --- |")
for i in order:
    for of in H[i]["outfits"][1:]:
        how = {"story": "Finish her story", "gems": "%d gems" % of.get("gems", 0)}.get(of["unlock"], of["unlock"])
        w("| %s | `art/heroines/%s/%s/` | %s | %s | %s |" % (H[i]["name"].split(" ")[0], i, of["id"], of["name"], how, outfit_brief(i, of["id"])))
w("")

w("## Cup and championship memories\n")
w("| File | Title | Brief |")
w("| --- | --- | --- |")
for c in prog.get("tournaments", []):
    s = c["scene"]
    w("| `art/scenes/%s.png` | %s | %s |" % (s["id"], s["title"], s["brief"]))
fs = d["finale"]["scene"]
w("| `art/scenes/%s.png` | %s | %s |\n" % (fs["id"], fs["title"], fs["brief"]))

w("## Table and backgrounds\n")
w("| File | Size | Brief |")
w("| --- | --- | --- |")
w("| `art/table/table.png` | 1920x1080 | Top-down playfield, exactly 16:9. Goals on the left and right short edges, centred, 43% of the height wide. Centre line and circle. Neon arcade style. |")
w("| `art/table/puck.png` | 128x128 | Light grey or white; the game tints it gold for your smash and her colour for her signature. |")
w("| `art/table/paddle_player.png` | 256x256 | Your paddle, cyan. |")
w("| `art/bg/lounge.png` | 1920x1080 | The Afterglow after hours: arcade cabinets, neon signs, the air hockey table, a juice and soda bar. Shown dimmed behind most screens. |")
w("| `art/bg/menu.png` | 1920x1080 | Title screen. Keep the left 40% calm: the menu buttons sit there. |")
w("| `art/ui/logo.png` | 1200x450 | \"Neon Puck Rivals\" logo, transparent. |\n")

w("## Store and free-to-play UI\n")
w("All transparent PNGs. Until they exist the game uses the flat icons drawn by `tools/make_f2p_icons.py`.\n")
w("| File | Size | Brief |")
w("| --- | --- | --- |")
w("| `art/ui/icons/gem.png` | 128x128 | The premium currency: a cut cyan gem with a neon glow. |")
w("| `art/ui/icons/life.png` | 128x128 | A life: an air hockey puck with a pink heart on it. |")
w("| `art/ui/icons/ad.png` | 128x128 | \"Watch an ad\" marker: a small gold screen with a play button. |")
for p in f2p["products"]:
    if p["type"] == "consumable":
        w("| `art/ui/store/%s.png` | 256x192 | %s: a pile of %d gems (bigger pile for bigger packs). |" % (p["id"], p["name"], p["gems"]))
w("| `art/ui/store/starter_pack.png` | 256x192 | Starter Pack: a gift box with gems, tip coins and a paddle peeking out. |")
w("| `art/ui/store/remove_ads.png` | 256x192 | Remove Ads: a TV screen with a neon \"no\" sign over it, playful not angry. |")
w("| `art/ui/store/lounge_pass.png` | 256x192 | VIP Lounge Pass: a gold VIP lanyard and card with the Afterglow logo. |\n")

w("## Google Play listing (needed to publish)\n")
w("| File (anywhere, uploaded in Play Console) | Size | Brief |")
w("| --- | --- | --- |")
w("| App icon | 512x512, 32-bit PNG | A glowing puck and paddle, or one heroine's face with a paddle. Readable at tiny sizes, no text. |")
w("| Adaptive launcher icon | 432x432 foreground + 432x432 background | Same design split into layers; set in the export preset (`launcher_icons/*`). |")
w("| Feature graphic | 1024x500, no transparency | All four rivals behind the glowing table, logo on one side. Nothing important near the edges. |")
w("| Phone screenshots | 1920x1080 (at least 2, up to 8) | A match mid-smash, the roster, a memory, the Wardrobe, a dialogue scene. Real gameplay, all Teen-safe. |")
w("| Promo video (optional) | YouTube link | 30 seconds of matches and story. |\n")

w("## Counts\n")
n = len(order)
w("| Group | Files |")
w("| --- | --- |")
w("| Crack stages (default outfit) | %d |" % (n * 4))
w("| Dialogue expressions | %d to %d |" % (n, n * 7))
w("| Story memories | %d |" % sum(len(H[i]["matches"]) for i in order))
w("| Cup and championship memories | %d |" % (len(prog.get("tournaments", [])) + 1))
w("| Outfits (3 per heroine, 1 to 4 images each) | %d to %d |" % (n * 3, n * 3 * 4))
w("| Table, puck, paddles | %d |" % (n + 3))
w("| Backgrounds and logo | 3 |")
w("| Store and F2P UI | %d |" % (3 + len(f2p["products"])))
w("| Play listing | 5 to 11 |")

open(os.path.join(ROOT, "docs/ART_LIST.md"), "w").write("\n".join(o) + "\n")
print("wrote docs/ART_LIST.md")
