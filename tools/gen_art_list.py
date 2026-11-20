"""Regenerates docs/ART_LIST.md from data/heroines.json and data/progression.json.
   python3 tools/gen_art_list.py
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
d = json.load(open(os.path.join(ROOT, "data/heroines.json")))
prog = json.load(open(os.path.join(ROOT, "data/progression.json")))
extras = json.load(open(os.path.join(ROOT, "data/extras.json")))
order = d["order"]
H = d["heroines"]
n = len(order)
mpg = max(len(H[i]["matches"]) for i in order)
ages = ", ".join(str(H[i]["age"]) for i in order)
cups = prog.get("tournaments", [])
fin = d.get("finale", {})
n_scenes = sum(len(H[i]["matches"]) for i in order)
extra = len(cups) + (1 if fin else 0)
xovers = extras.get("crossovers", [])
alts = [(i, m["alt_scene"]) for i in order for m in H[i]["matches"] if m.get("alt_scene")]
eps = extras.get("epilogues", {})
n_more = len(xovers) + len(alts) + len(eps)

o = []
w = o.append
w("# Neon Puck: art list\n")
w("Every piece of art the game looks for, with its exact path, size and a brief")
w("for the artist. Drop a PNG at the path and the game uses it on next launch;")
w("nothing else needs to change (see `scripts/ArtAssets.gd`). Anything missing")
w("falls back to the placeholder you see now, so art can arrive piece by piece.\n")
w("This file is generated from the game data: `python3 tools/gen_art_list.py`.\n")
w("All characters are adults (%s). Sizes are recommended export" % ages)
w("sizes; keep the aspect ratio. Use transparent backgrounds for characters,")
w("paddles and the puck.\n")
w("## Priority order\n")
w("1. **Strip stages** for each heroine (%d images). The match is where players" % (n * 4))
w("   spend their time, and the portrait changing is the core reward.")
w("2. **Story scenes** (%d CGs). One per story match win, %d per heroine." % (n_scenes, mpg))
w("3. **Table, puck and paddles** (%d images). Cheap, and they lift the whole look." % (n + 3))
w("4. **Dialogue expressions** (up to %d). Start with `vn_neutral` per heroine;" % (n * 7))
w("   every missing expression falls back to it.")
w("5. **Cup and championship scenes** (%d CGs). Rewards for side content and the ending." % extra)
w("6. **Crossover, alternate and date scenes** (%d CGs). After Hours and choice rewards; placeholders show the brief until they exist." % n_more)
w("7. **Backgrounds and logo** (3 images).\n")
w("Minimum set for a good-looking demo: items 1, 3, the first two scenes per")
w("heroine, and `vn_neutral` for each heroine (%d files).\n" % (n * 4 + n + 3 + n * 2 + n))
w("## Per heroine\n")
w("Replace `<id>` with %s.\n" % ", ".join("`%s`" % i for i in order))
w("| File | Size | Shown where | Notes |")
w("| --- | --- | --- | --- |")
w("| `art/heroines/<id>/stage_0.png` | 1024x1440 | Match card, roster, results | Fully dressed, standing, facing the player. Same pose for all four stages so swaps read as clothes coming off. |")
w("| `art/heroines/<id>/stage_1.png` | 1024x1440 | Match card after the first layer | Outer layer off (see her layer list). Flustered expression. |")
w("| `art/heroines/<id>/stage_2.png` | 1024x1440 | After the second layer | Second layer off. |")
w("| `art/heroines/<id>/stage_3.png` | 1024x1440 | After the third layer | Last layer off. In the placeholder she is down to underwear; how far the final stage goes is your call. |")
w("| `art/heroines/<id>/vn_<expression>.png` | 1024x1440 | Dialogue | Expressions: neutral, happy, shy, surprised, teasing, sad, angry. Dressed (stage 0 outfit). |")
w("| `art/heroines/<id>/card.png` | 700x600 | Roster card (optional) | Falls back to stage_0. |")
w("| `art/table/paddle_<id>.png` | 256x256 | Her paddle | Round, top-down, in her colour. |")
w("| `art/scenes/<id>_1.png` ... `<id>_%d.png` | 1920x1080 | Reward after each story match | See scene briefs below. The last one is her romance scene: a good candidate for animation later. |\n" % mpg)

for i in order:
    h = H[i]
    w("### %s (%d), `%s`, colour %s\n" % (h["name"], h["age"], i, h["color"]))
    w("%s %s Plays a %s style; her signature shot is the %s.\n" % (h["tagline"], "She starts out hating you: " + h["grudge"][0].lower() + h["grudge"][1:], h["style"].lower(), h["signature_name"]))
    w("Layers, in the order they come off: %s.\n" % ", ".join("**%s**" % L["name"] for L in h["layers"]))
    w("Scenes (her mood goes from hostile to in love across them):\n")
    for k, m in enumerate(h["matches"]):
        sc = m["scene"]
        w("%d. **%s** (`art/scenes/%s.png`): %s" % (k + 1, sc["title"], sc["id"], sc["brief"]))
    w("")

w("## Cup and championship scenes\n")
w("| File | Title | Brief |")
w("| --- | --- | --- |")
for c in cups:
    sc = c["scene"]
    w("| `art/scenes/%s.png` | %s | %s |" % (sc["id"], sc["title"], sc["brief"]))
if fin:
    sc = fin["scene"]
    w("| `art/scenes/%s.png` | %s | %s |" % (sc["id"], sc["title"], sc["brief"]))
w("")
w("## Crossover scenes\n")
w("Two heroines in one image, unlocked once you're far enough with both (After Hours).\n")
w("| File | Title | Who | Brief |")
w("| --- | --- | --- | --- |")
for c in xovers:
    sc = c["scene"]
    w("| `art/scenes/%s.png` | %s | %s and %s | %s |" % (sc["id"], sc["title"], H[c["a"]]["name"].split(" ")[0], H[c["b"]]["name"].split(" ")[0], sc["brief"]))
w("")
w("## Alternate scenes (earned with dialogue choices)\n")
w("| File | Title | How | Brief |")
w("| --- | --- | --- | --- |")
for i, a in alts:
    w("| `art/scenes/%s.png` | %s | %s | %s |" % (a["id"], a["title"], a.get("hint", ""), a["brief"]))
w("")
w("## Date nights (after the championship)\n")
w("| File | Title | Brief |")
w("| --- | --- | --- |")
for i in order:
    if i in eps:
        sc = eps[i]["scene"]
        w("| `art/scenes/%s.png` | %s | %s |" % (sc["id"], sc["title"], sc["brief"]))
w("")
w("## Shared\n")
w("| File | Size | Notes |")
w("| --- | --- | --- |")
w("| `art/table/table.png` | 1920x1080 | Top-down playfield, exactly 16:9. Goals are on the left and right short edges, centred, 43% of the height wide. Centre line and circle. Neon arcade style. |")
w("| `art/table/puck.png` | 128x128 | Light grey or white: the game tints it gold for your smash and her colour for her signature. |")
w("| `art/table/paddle_player.png` | 256x256 | Your paddle, cyan. |")
w("| `art/bg/lounge.png` | 1920x1080 | The after-hours arcade lounge. Used behind most screens (dimmed). |")
w("| `art/bg/menu.png` | 1920x1080 | Title screen. Keep the left 40% calm: the menu buttons sit there. |")
w("| `art/ui/logo.png` | 1200x450 | \"Neon Puck\" logo (working title), transparent. |\n")
w("## Shop icons (optional, later)\n")
w("The Pro Shop and loadout screens use text only for now. If you want icons,")
w("these are the items (256x256 each, transparent): gear %s; power-ups %s. Tell" % (
    ", ".join(g["name"] for g in prog["gear"] if g["tier"] > 1),
    ", ".join(p["name"] for p in prog["powerups"])))
w("me when they exist and I'll wire them in.\n")
w("## All-ages versions (optional)\n")
w("Settings has an All-ages mode, for the separate SFW build the research")
w("recommends. With it on, every lookup tries `<name>_sfw.png` first (for")
w("example `art/heroines/mila/stage_3_sfw.png`, `art/scenes/mila_6_sfw.png`)")
w("and falls back to the normal file. Commission SFW variants only for the")
w("images that need them: usually stage_2, stage_3 and the scenes.\n")
w("## Sound (optional, same drop-in rule)\n")
w("`audio/sfx/<name>.ogg` for: hit, wall, goal, goal_against, smash, strip, warn,")
w("click, win, lose. Missing files play a synthesized blip.\n")
w("## Counts\n")
w("| Group | Files |")
w("| --- | --- |")
w("| Strip stages | %d |" % (n * 4))
w("| Story scenes | %d |" % n_scenes)
w("| Cup and championship scenes | %d |" % extra)
w("| Crossover, alternate and date scenes | %d |" % n_more)
w("| Dialogue expressions | %d to %d |" % (n, n * 7))
w("| Paddles, puck, table | %d |" % (n + 3))
w("| Backgrounds and logo | 3 |")
lo = n * 4 + n_scenes + extra + n_more + n + n + 3 + 3
hi = lo - n + n * 7
w("| **Total** | **%d to %d** |" % (lo, hi))
open(os.path.join(ROOT, "docs/ART_LIST.md"), "w").write("\n".join(o) + "\n")
print("wrote docs/ART_LIST.md", lo, hi)
