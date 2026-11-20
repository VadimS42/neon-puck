"""Regenerates docs/SCRIPT.md: every line of dialogue in the PG-13 build,
in play order (prologue, each heroine's 6 matches, in-match lines, the
championship). Edit data/heroines.json, then run:
   python3 tools/gen_script.py"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
d = json.load(open(os.path.join(ROOT, "data/heroines.json")))
prog = json.load(open(os.path.join(ROOT, "data/progression.json")))
H = d["heroines"]
count = [0]


def who(l):
    w = l["who"]
    if w == "you":
        return "**You**"
    if w == "narrator":
        return "*Narrator*"
    return "**%s**%s" % (H[w]["name"].split(" ")[0], (" (%s)" % l["e"]) if l.get("e") else "")


def lines(ls, out, ind=""):
    for l in ls:
        if "choice" in l:
            out.append(ind + "- *Choice:*")
            for c in l["choice"]:
                extra = (" (rules: %s)" % ", ".join(c["mods"])) if c.get("mods") else ""
                out.append(ind + "  - \"%s\"%s" % (c["text"], extra))
                lines(c.get("reply", []), out, ind + "    ")
            continue
        count[0] += 1
        cond = (" *(only if %s)*" % l["if"]) if l.get("if") else ""
        out.append(ind + "- %s: %s%s" % (who(l), l["text"], cond))


o = []
w = o.append
w("# Neon Puck Rivals: full script (PG-13)\n")
w("Every line in the Google Play build, in the order players see it. Generated from")
w("`data/heroines.json` by `python3 tools/gen_script.py`; edit the JSON, not this file.")
w("Expressions in brackets pick her dialogue sprite.\n")
w("## Prologue\n")
lines(d["prologue"], o)
w("")
for hid in d["order"]:
    h = H[hid]
    w("## %s (%d)\n" % (h["name"], h["age"]))
    w("*%s* Starts out hating you: %s %s" % (h["tagline"], h["grudge"][0].lower() + h["grudge"][1:], ("Unlocks: " + h["unlock"] + ".") if h.get("unlock") else ""))
    w("")
    w("What she thinks of you after each win: " + " → ".join(d["attitude"]) + "\n")
    for n, m in enumerate(h["matches"]):
        s = m["scene"]
        w("### Match %d (level %d, first to %d)\n" % (n + 1, m["level"], m["target"]))
        if m.get("mods"):
            w("Special rules: %s\n" % ", ".join(m["mods"]))
        if m.get("attitude"):
            w("After this win she's: %s\n" % m["attitude"])
        w("Before:\n")
        lines(m["before"], o)
        w("\nAfter a win:\n")
        lines(m["after"], o)
        for k, leg in enumerate(m.get("legs", [])):
            w("\nGame %d (rules: %s):\n" % (k + 2, ", ".join(leg.get("mods", [])) or "none"))
            lines(leg.get("before", []), o)
        w("\nMemory unlocked: **%s**. %s\n" % (s["title"], s["brief"]))
    w("### In-match lines\n")
    w("Hostile for her first two matches, warm after.\n")
    labels = {"her_goal": "She scores", "your_goal": "You score", "crack1": "First crack", "crack2": "Second crack", "crack3": "Third crack", "signature": "Arms her %s" % h["signature_name"]}
    for mood in ("hostile", "warm"):
        w("**%s**\n" % mood.capitalize())
        for k, lab in labels.items():
            v = h["barks"][mood][k]
            vs = v if isinstance(v, list) else [v]
            count[0] += len(vs)
            w("- %s: %s" % (lab, " / ".join('"%s"' % x for x in vs)))
        w("")
    names = ", ".join("%s (%s)" % (L["name"], L["effect"]) for L in h["layers"])
    w("Her cracks, in order: %s.\n" % names)
f = d["finale"]
w("## %s (level %d, first to %d, all four back to back)\n" % (f["title"], f["level"], f["target"]))
w("Before:\n")
lines(f["before"], o)
for r in f["rounds"]:
    w("\nRound vs %s:\n" % H[r["id"]]["name"].split(" ")[0])
    lines(r["before"], o)
w("\nAfter the final win:\n")
lines(f["after"], o)
w("\nMemory unlocked: **%s**. %s\n" % (f["scene"]["title"], f["scene"]["brief"]))
w("## Cup memories\n")
for c in prog.get("tournaments", []):
    w("- **%s** (%s): %s" % (c["scene"]["title"], c["name"], c["scene"]["brief"]))
w("\n---\n%d lines in total." % count[0])
open(os.path.join(ROOT, "docs/SCRIPT.md"), "w").write("\n".join(o) + "\n")
print("wrote docs/SCRIPT.md,", count[0], "lines")
