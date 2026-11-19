## GameState.gd (autoload "GameState")
##
## Loads data/heroines.json and keeps the save: how far you are with each
## heroine, which memories and cracks you've seen, your settings, and the
## free-to-play state (lives, gems, purchases, daily reward, outfits).
## Saved to user://save.json after every change.
##
## PG-13 Google Play build. Her "layers" are cracks in her cool (expression
## and pose only); outfits are cosmetic and never change stats.
extends Node

const SAVE_PATH := "user://save.json"
const DATA_PATH := "res://data/heroines.json"
const PROG_PATH := "res://data/progression.json"
const F2P_PATH := "res://data/monetization.json"

var data: Dictionary = {}
## data/progression.json: levels, tips, gear, power-ups, cups.
var prog: Dictionary = {}
## data/monetization.json: lives, gems, daily rewards, ads, store products.
var f2p: Dictionary = {}
## Economy (see progression.json). Tips are the money.
var tips := 0
var xp := 0
var level := 1
## gear id -> true
var owned_gear: Dictionary = {}
## gear slot id -> gear id
var equipped: Dictionary = {}
## power-up id -> count owned
var powerups: Dictionary = {}
var pickup_streak := 0
## cup id -> true once won
var trophies: Dictionary = {}
## The cup in progress: {"id", "round", "opponents": [ids]}, or {}.
var cup_run: Dictionary = {}
## Finale rounds cleared (0..4), and whether the championship is won.
var finale_round := 0
var finale_done := false
## heroine id -> number of matches won (0..3)
var progress: Dictionary = {}
## scene id -> true
var scenes_seen: Dictionary = {}
## "<heroine>_<stage>" -> true, cracks reached in a match
var stages_seen: Dictionary = {}
var difficulty := "normal"
var unlock_all := false
var fullscreen := false
## Set by the headless test so it never touches your save.
var no_save := false
var prologue_seen := false
## Your power shot: "smash", or a heroine's signature once you've won her
## over ("bullet", "ricochet", "hook").
var player_shot := "smash"

# ---- free-to-play state
var gems := 0
var lives := 5
## Unix time the next life arrives (0 when full).
var life_next_at := 0
## Unix time unlimited lives end.
var unlimited_until := 0
## Non-consumables and one-time packs bought: product id -> true.
var owned_products: Dictionary = {}
## "YYYY-MM-DD" of the last daily reward claimed, and the streak day (0..6).
var daily_last := ""
var daily_day := 0
## Per-day counters, reset when the date changes: {"date", "ad_lives", "rewarded", "free_powerup"}.
var today: Dictionary = {}
## Matches finished since the last interstitial, and when it was shown.
var matches_since_ad := 0
var matches_total := 0
var last_interstitial := 0
## heroine id -> outfit id chosen, and "<heroine>_<outfit>" -> true owned.
var outfit: Dictionary = {}
var outfits_owned: Dictionary = {}
## Story first-win gems already paid: "<heroine>_<match>" -> true.
var gem_wins: Dictionary = {}
## Ad consent answer from the consent form (stub: "unknown", "personalized", "non_personalized").
var ad_consent := "unknown"


func _ready() -> void:
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	if f:
		var parsed = JSON.parse_string(f.get_as_text())
		if parsed is Dictionary:
			data = parsed
	var f2 := FileAccess.open(PROG_PATH, FileAccess.READ)
	if f2:
		var p2 = JSON.parse_string(f2.get_as_text())
		if p2 is Dictionary:
			prog = p2
	var f3 := FileAccess.open(F2P_PATH, FileAccess.READ)
	if f3:
		var p3 = JSON.parse_string(f3.get_as_text())
		if p3 is Dictionary:
			f2p = p3
	_new_economy()
	load_save()
	tick_lives()


func heroine(id: String) -> Dictionary:
	return data.get("heroines", {}).get(id, {})


func order() -> Array:
	return data.get("order", [])


func wins(id: String) -> int:
	return int(progress.get(id, 0))


func match_count(id: String) -> int:
	return heroine(id).get("matches", []).size()


func story_done(id: String) -> bool:
	return wins(id) >= match_count(id)


func is_unlocked(id: String) -> bool:
	if unlock_all:
		return true
	var h := heroine(id)
	if h.has("unlock_wins") and total_story_wins() < int(h["unlock_wins"]):
		return false
	if h.has("unlock_done"):
		var done := 0
		for other in order():
			if other != id and story_done(other):
				done += 1
		if done < int(h["unlock_done"]):
			return false
	return true


## What she thinks of you: index into data["attitude"] by matches won.
func attitude(id: String) -> String:
	var a: Array = data.get("attitude", [])
	if a.is_empty():
		return ""
	return String(a[clampi(wins(id), 0, a.size() - 1)])


## Power shots you can pick: your own smash plus every signature you've
## learned by finishing a heroine's story.
func shots() -> Array:
	var out := [{"kind": "smash", "name": "Smash", "from": ""}]
	for id in order():
		if story_done(id) or unlock_all:
			var h := heroine(id)
			out.append({"kind": String(h.get("signature", "")), "name": String(h.get("signature_name", "")), "from": id})
	return out


func record_win(id: String, match_index: int) -> void:
	if wins(id) <= match_index:
		progress[id] = match_index + 1
	save()


func see_scene(scene_id: String) -> void:
	scenes_seen[scene_id] = true
	save()


func see_stage(id: String, stage: int) -> void:
	stages_seen["%s_%d" % [id, stage]] = true
	save()


func scene_unlocked(scene_id: String) -> bool:
	return unlock_all or scenes_seen.has(scene_id)


func stage_unlocked(id: String, stage: int) -> bool:
	return unlock_all or stage == 0 or stages_seen.has("%s_%d" % [id, stage])


func diff() -> Dictionary:
	return data.get("difficulty", {}).get(difficulty, {"speed": 1.0, "reaction": 0.0, "aim": 1.0, "heat": 1.0})


## Sets up her paddle and brain for a match, with `layers_lost` layers
## already off. Called again every time she loses a layer.
func apply_opponent(id: String, match_index: int, layers_lost: int, brain: AIBrain, pad: PuckSim.Paddle) -> void:
	var h := heroine(id)
	var s: Dictionary = h.get("stats", {})
	var d := diff()
	# Later matches in her story are a little sharper.
	var arc: Array = [0.88, 0.93, 0.97, 1.01, 1.05, 1.08]
	var arc_mult: float = arc[clampi(match_index, 0, arc.size() - 1)]
	var speed: float = float(s.get("speed", 2200)) * float(d.get("speed", 1.0)) * arc_mult
	var size: float = float(s.get("size", 40))
	var reaction: float = float(s.get("reaction", 0.14)) + float(d.get("reaction", 0.0))
	var layers: Array = h.get("layers", [])
	for i in mini(layers_lost, layers.size()):
		var L: Dictionary = layers[i]
		match String(L.get("stat", "")):
			"speed":
				speed *= float(L.get("value", 1.0))
			"size":
				size *= float(L.get("value", 1.0))
			"reaction":
				reaction += float(L.get("value", 0.0))
	# Free-to-play difficulty curve: later matches get much sharper.
	var cv := curve(id, match_index)
	speed *= float(cv.get("speed", 1.0))
	reaction += float(cv.get("reaction", 0.0))
	pad.max_speed = speed
	pad.max_accel = float(s.get("accel", 6500)) * float(d.get("speed", 1.0)) * (speed / maxf(1.0, float(s.get("speed", 2200)) * float(d.get("speed", 1.0))))
	pad.radius = size
	pad.power_kind = String(h.get("signature", "bullet"))
	brain.reaction = maxf(0.04, reaction)
	brain.aim_spread = float(s.get("aim", 50)) * float(d.get("aim", 1.0)) * float(cv.get("aim", 1.0))
	brain.bank_pref = float(s.get("bank", 0.25))
	brain.aggression = float(s.get("aggression", 0.5))


func apply_player(pad: PuckSim.Paddle) -> void:
	var p: Dictionary = data.get("player", {})
	var g := gear_stats()
	pad.max_speed = float(p.get("speed", 2600)) * (1.0 + g.speed / 100.0)
	pad.max_accel = float(p.get("accel", 40000))
	pad.radius = float(p.get("size", 38)) * (1.0 + g.size / 100.0)
	pad.power_mult = 1.0 + g.power / 100.0
	pad.smash_mult = 1.0 + g.smash / 100.0
	pad.heat_mult = float(diff().get("heat", 1.0)) * (1.0 + g.heat / 100.0)
	var ok := false
	for sh in shots():
		if sh["kind"] == player_shot:
			ok = true
	pad.power_kind = player_shot if ok else "smash"


func save() -> void:
	if no_save:
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"progress": progress,
		"scenes_seen": scenes_seen,
		"stages_seen": stages_seen,
		"difficulty": difficulty,
		"unlock_all": unlock_all,
		"fullscreen": fullscreen,
		"prologue_seen": prologue_seen,
		"player_shot": player_shot,
		"tips": tips,
		"xp": xp,
		"level": level,
		"owned_gear": owned_gear,
		"equipped": equipped,
		"powerups": powerups,
		"pickup_streak": pickup_streak,
		"trophies": trophies,
		"cup_run": cup_run,
		"finale_round": finale_round,
		"finale_done": finale_done,
		"gems": gems,
		"lives": lives,
		"life_next_at": life_next_at,
		"unlimited_until": unlimited_until,
		"owned_products": owned_products,
		"daily_last": daily_last,
		"daily_day": daily_day,
		"today": today,
		"matches_since_ad": matches_since_ad,
		"matches_total": matches_total,
		"last_interstitial": last_interstitial,
		"outfit": outfit,
		"outfits_owned": outfits_owned,
		"gem_wins": gem_wins,
		"ad_consent": ad_consent,
	}))


func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if not d is Dictionary:
		return
	progress = d.get("progress", {})
	scenes_seen = d.get("scenes_seen", {})
	stages_seen = d.get("stages_seen", {})
	difficulty = String(d.get("difficulty", "normal"))
	unlock_all = bool(d.get("unlock_all", false))
	fullscreen = bool(d.get("fullscreen", false))
	prologue_seen = bool(d.get("prologue_seen", false))
	player_shot = String(d.get("player_shot", "smash"))
	if d.has("tips"):
		tips = int(d.get("tips", 0))
		xp = int(d.get("xp", 0))
		level = int(d.get("level", 1))
		owned_gear = d.get("owned_gear", owned_gear)
		equipped = d.get("equipped", equipped)
		powerups = d.get("powerups", {})
		pickup_streak = int(d.get("pickup_streak", 0))
		trophies = d.get("trophies", {})
		cup_run = d.get("cup_run", {})
		finale_round = int(d.get("finale_round", 0))
		finale_done = bool(d.get("finale_done", false))
	for k in powerups:
		powerups[k] = int(powerups[k])
	gems = int(d.get("gems", gems))
	lives = int(d.get("lives", lives))
	life_next_at = int(d.get("life_next_at", 0))
	unlimited_until = int(d.get("unlimited_until", 0))
	owned_products = d.get("owned_products", {})
	daily_last = String(d.get("daily_last", ""))
	daily_day = int(d.get("daily_day", 0))
	today = d.get("today", {})
	matches_since_ad = int(d.get("matches_since_ad", 0))
	matches_total = int(d.get("matches_total", 0))
	last_interstitial = int(d.get("last_interstitial", 0))
	outfit = d.get("outfit", {})
	outfits_owned = d.get("outfits_owned", {})
	gem_wins = d.get("gem_wins", {})
	ad_consent = String(d.get("ad_consent", "unknown"))


func reset_progress() -> void:
	progress = {}
	scenes_seen = {}
	stages_seen = {}
	prologue_seen = false
	player_shot = "smash"
	# Purchases, gems and outfits survive a story reset: the player paid for them.
	var keep_gems := gems
	_new_economy()
	gems = keep_gems
	gem_wins = {}
	save()


# ------------------------------------------------------------ progression
# Levels, tips, gear, power-ups and cups. The one rule that keeps the grind
# light: a level only ever gates the NEXT story match. Every scene unlocks
# the moment you win the match it belongs to.

func _new_economy() -> void:
	tips = int(prog.get("start_tips", 150))
	xp = 0
	level = 1
	owned_gear = {}
	equipped = {}
	for g in prog.get("gear", []):
		if int(g.get("tier", 1)) == 1:
			owned_gear[String(g["id"])] = true
			equipped[String(g["slot"])] = String(g["id"])
	powerups = {}
	pickup_streak = 0
	trophies = {}
	cup_run = {}
	finale_round = 0
	finale_done = false
	gems = int(f2p.get("start_gems", 25))
	lives = max_lives()
	life_next_at = 0


func finale() -> Dictionary:
	return data.get("finale", {})


func finale_open() -> bool:
	if finale().is_empty():
		return false
	if unlock_all:
		return true
	for id in order():
		if not story_done(id):
			return false
	return true


func max_level() -> int:
	return int(prog.get("level_xp", {}).get("max_level", 15))


## XP needed to go from level `lv` to `lv + 1`.
func xp_to_next(lv: int = -1) -> int:
	if lv < 0:
		lv = level
	var lx: Dictionary = prog.get("level_xp", {})
	return int(lx.get("base", 150)) + int(lx.get("step", 100)) * (lv - 1)


## Level a story match needs (heroines.json, "level" on each match).
func match_level(id: String, mi: int) -> int:
	var ms: Array = heroine(id).get("matches", [])
	if mi < 0 or mi >= ms.size():
		return 1
	return int(ms[mi].get("level", 1))


func can_play_story(id: String, mi: int) -> bool:
	return unlock_all or level >= match_level(id, mi)


func powerup(pid: String) -> Dictionary:
	for p in prog.get("powerups", []):
		if String(p["id"]) == pid:
			return p
	return {}


func gear_item(gid: String) -> Dictionary:
	for g in prog.get("gear", []):
		if String(g["id"]) == gid:
			return g
	return {}


func powerup_slots(lv: int = -1) -> int:
	if lv < 0:
		lv = level
	var n := 0
	for s in prog.get("powerup_slots", []):
		if lv >= int(s["level"]):
			n = maxi(n, int(s["slots"]))
	return n


## Sum of equipped gear stats, in percent.
func gear_stats() -> Dictionary:
	var out := {"speed": 0.0, "size": 0.0, "power": 0.0, "heat": 0.0, "smash": 0.0}
	for slot in equipped:
		var g := gear_item(String(equipped[slot]))
		var st: Dictionary = g.get("stats", {})
		for k in st:
			out[k] = float(out.get(k, 0.0)) + float(st[k])
	return out


func buy_gear(gid: String) -> bool:
	var g := gear_item(gid)
	if g.is_empty() or owned_gear.has(gid) or level < int(g.get("level", 1)) or tips < int(g.get("price", 0)):
		return false
	tips -= int(g.get("price", 0))
	owned_gear[gid] = true
	equipped[String(g["slot"])] = gid
	save()
	return true


func equip(gid: String) -> void:
	if owned_gear.has(gid):
		equipped[String(gear_item(gid)["slot"])] = gid
		save()


func buy_powerup(pid: String) -> bool:
	var p := powerup(pid)
	if p.is_empty() or level < int(p.get("level", 1)) or tips < int(p.get("price", 0)):
		return false
	tips -= int(p.get("price", 0))
	powerups[pid] = int(powerups.get(pid, 0)) + 1
	save()
	return true


## Takes the chosen power-ups out of your bag for one match.
func use_powerups(ids: Array) -> Array:
	var used := []
	for pid in ids:
		if int(powerups.get(pid, 0)) > 0:
			powerups[pid] = int(powerups[pid]) - 1
			used.append(pid)
	save()
	return used


func cup(cid: String) -> Dictionary:
	for c in prog.get("tournaments", []):
		if String(c["id"]) == cid:
			return c
	return {}


func total_story_wins() -> int:
	var n := 0
	for id in order():
		n += wins(id)
	return n


## "" if you can enter, otherwise why not.
func cup_block(cid: String) -> String:
	var c := cup(cid)
	if level < int(c.get("level", 1)):
		return "Reach level %d" % int(c.get("level", 1))
	if total_story_wins() < int(c.get("requires_wins", 0)):
		return "Win %d story matches" % int(c.get("requires_wins", 0))
	if tips < int(c.get("entry", 0)):
		return "Entry costs %d tips" % int(c.get("entry", 0))
	return ""


func unlocked_heroines() -> Array:
	var out := []
	for id in order():
		if is_unlocked(id):
			out.append(id)
	return out


## Pays the entry and draws the bracket: unlocked heroines, the toughest
## (furthest down the roster) saved for the final.
func start_cup(cid: String) -> bool:
	if cup_block(cid) != "":
		return false
	var c := cup(cid)
	tips -= int(c.get("entry", 0))
	var pool := unlocked_heroines()
	var rounds := int(c.get("rounds", 3))
	var opp := []
	for r in rounds:
		opp.append(pool[mini(r * pool.size() / rounds, pool.size() - 1)] if r < rounds - 1 else pool[pool.size() - 1])
	cup_run = {"id": cid, "round": 0, "opponents": opp}
	save()
	return true


## How strong a heroine plays outside her story: her current arc stage for
## pickup games, a fixed stage per cup.
func side_match_index(id: String, ctx: Dictionary) -> int:
	if String(ctx.get("mode", "")) == "cup":
		return [1, 3, 5][clampi(["bronze", "silver", "gold"].find(String(ctx.get("cup", ""))), 0, 2)]
	if String(ctx.get("mode", "")) == "finale":
		return match_count(id) - 1
	return clampi(wins(id), 0, match_count(id) - 1)


## Hands out XP and tips for a finished match and returns what happened,
## for the result screen: {xp, tips, lines, level_from, level_to, unlocks}.
func award(ctx: Dictionary, rules: MatchRules) -> Dictionary:
	var rw: Dictionary = prog.get("rewards", {})
	var won := rules.player_won
	var mode := String(ctx.get("mode", "story"))
	var base: Dictionary = rw.get("win" if won else "loss", {})
	var gx := float(base.get("xp", 0))
	var gt := float(base.get("tips", 0))
	var lines := []
	lines.append(["Win" if won else "Good try", int(gx), int(gt)])
	var pl: Dictionary = rw.get("per_layer", {})
	if rules.layers_lost > 0:
		lines.append(["Cracks x%d" % rules.layers_lost, int(pl.get("xp", 0)) * rules.layers_lost, int(pl.get("tips", 0)) * rules.layers_lost])
	var ps: Dictionary = rw.get("per_smash_goal", {})
	if rules.smash_goals > 0:
		lines.append(["Power goals x%d" % rules.smash_goals, int(ps.get("xp", 0)) * rules.smash_goals, int(ps.get("tips", 0)) * rules.smash_goals])
	if won and rules.sim.paddle(1).score == 0:
		var so: Dictionary = rw.get("shutout", {})
		lines.append(["Shutout", int(so.get("xp", 0)), int(so.get("tips", 0))])
	gx = 0.0
	gt = 0.0
	for l in lines:
		gx += l[1]
		gt += l[2]
	var mult := 1.0
	var why := ""
	match mode:
		"story", "finale":
			if won:
				mult = float(rw.get("story_mult", 1.5))
				why = "Story win"
		"replay":
			mult = float(rw.get("replay_mult", 0.6))
			why = "Replay"
		"pickup":
			if won:
				pickup_streak += 1
				var k := mini(pickup_streak - 1, int(rw.get("pickup_streak_max", 5)))
				mult = 1.0 + float(rw.get("pickup_streak_bonus", 0.15)) * k
				if k > 0:
					why = "Win streak %d" % pickup_streak
			else:
				pickup_streak = 0
		"cup":
			if won:
				var c := cup(String(ctx.get("cup", "")))
				var rr: Dictionary = c.get("round_reward", {})
				lines.append(["Cup round %d" % (int(ctx.get("round", 0)) + 1), int(rr.get("xp", 0)), int(rr.get("tips", 0))])
				gx += float(rr.get("xp", 0))
				gt += float(rr.get("tips", 0))
				if int(ctx.get("round", 0)) >= int(c.get("rounds", 3)) - 1:
					var pz: Dictionary = c.get("prize", {})
					lines.append(["%s prize!" % String(c.get("name", "")), int(pz.get("xp", 0)), int(pz.get("tips", 0))])
					gx += float(pz.get("xp", 0))
					gt += float(pz.get("tips", 0))
	if mult != 1.0:
		lines.append([("%s x%.2f" % [why, mult]) if why != "" else "x%.2f" % mult, int(gx * (mult - 1.0)), int(gt * (mult - 1.0))])
		gx *= mult
		gt *= mult
	if owns("lounge_pass") and gt > 0:
		lines.append(["VIP Lounge Pass +20%", 0, int(gt * 0.2)])
		gt *= 1.2
	var lv_from := level
	add_xp(int(gx))
	tips += int(gt)
	var g := _award_gems(ctx, rules)
	gems += int(g[0])
	note_match_finished()
	save()
	return {"xp": int(gx), "tips": int(gt), "gems": int(g[0]), "gem_lines": g[1], "lines": lines, "level_from": lv_from, "level_to": level, "unlocks": unlocks_between(lv_from, level)}


## Gems a match pays: the first win of each story match, finishing a story,
## and a cup final. Returns [total, [[label, gems], ...]].
func _award_gems(ctx: Dictionary, rules: MatchRules) -> Array:
	var out := []
	var total := 0
	if not rules.player_won:
		return [0, out]
	var mode := String(ctx.get("mode", "story"))
	if mode == "story":
		var key := "%s_%d" % [rules.heroine_id, rules.match_index]
		if not gem_wins.has(key):
			gem_wins[key] = true
			var n := int(f2p.get("first_win_gems", 5))
			out.append(["First win", n])
			total += n
			if rules.match_index >= match_count(rules.heroine_id) - 1:
				var n2 := int(f2p.get("story_complete_gems", 30))
				out.append(["%s won over" % String(heroine(rules.heroine_id).get("name", "")).split(" ")[0], n2])
				total += n2
	elif mode == "cup":
		var c := cup(String(ctx.get("cup", "")))
		if int(ctx.get("round", 0)) >= int(c.get("rounds", 3)) - 1:
			var gl: Array = f2p.get("cup_win_gems", [10, 20, 40])
			var ci := clampi(["bronze", "silver", "gold"].find(String(c.get("id", ""))), 0, gl.size() - 1)
			out.append(["%s won" % String(c.get("name", "")), int(gl[ci])])
			total += int(gl[ci])
	return [total, out]


func add_xp(n: int) -> void:
	xp += n
	while level < max_level() and xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
	if level >= max_level():
		xp = mini(xp, xp_to_next())


## Everything that opens up between two levels, as text lines.
func unlocks_between(a: int, b: int) -> Array:
	var out := []
	if b <= a:
		return out
	if powerup_slots(b) > powerup_slots(a):
		out.append("%d power-up slots" % powerup_slots(b))
	for id in order():
		for mi in match_count(id):
			var lv := match_level(id, mi)
			if lv > a and lv <= b:
				out.append("%s match %d" % [String(heroine(id).get("name", id)).split(" ")[0], mi + 1])
	var fl := int(finale().get("level", 99))
	if fl > a and fl <= b:
		out.append(String(finale().get("title", "Finale")))
	for c in prog.get("tournaments", []):
		if int(c["level"]) > a and int(c["level"]) <= b:
			out.append(String(c["name"]))
	for p in prog.get("powerups", []):
		if int(p["level"]) > a and int(p["level"]) <= b:
			out.append("Power-up: " + String(p["name"]))
	for g in prog.get("gear", []):
		if int(g["level"]) > a and int(g["level"]) <= b:
			out.append("Gear: " + String(g["name"]))
	return out


# ------------------------------------------------------------ free to play
# Lives, gems, daily rewards, ad pacing, store products and outfits. All the
# numbers live in data/monetization.json.

func now() -> int:
	return int(Time.get_unix_time_from_system())


func date_str() -> String:
	return Time.get_date_string_from_system()


func lives_cfg() -> Dictionary:
	return f2p.get("lives", {})


func max_lives() -> int:
	return 8 if owns("lounge_pass") else int(lives_cfg().get("max", 5))


func refill_seconds() -> int:
	var s := int(lives_cfg().get("refill_minutes", 20)) * 60
	return s / 2 if owns("lounge_pass") else s


func has_unlimited() -> bool:
	return now() < unlimited_until


## Adds the lives the clock has earned since the last check.
func tick_lives() -> void:
	var changed := false
	if lives >= max_lives():
		if life_next_at != 0:
			life_next_at = 0
			changed = true
	else:
		var t := now()
		if life_next_at == 0:
			life_next_at = t + refill_seconds()
			changed = true
		while lives < max_lives() and t >= life_next_at:
			lives += 1
			life_next_at += refill_seconds()
			changed = true
		if lives >= max_lives():
			life_next_at = 0
	if changed:
		save()


func seconds_to_next_life() -> int:
	if lives >= max_lives() or life_next_at == 0:
		return 0
	return maxi(0, life_next_at - now())


## Story, pickup, cup (first round only) and championship matches cost a
## life; replays of won matches are free (lives.free_modes).
func match_costs_life(ctx: Dictionary) -> bool:
	var mode := String(ctx.get("mode", "story"))
	if mode in lives_cfg().get("free_modes", ["replay"]):
		return false
	if mode == "cup" and int(ctx.get("round", 0)) > 0:
		return false
	return true


func can_start(ctx: Dictionary) -> bool:
	tick_lives()
	return not match_costs_life(ctx) or has_unlimited() or lives > 0


## Takes the life for a match. Returns true if one was taken (so a win can
## give it back).
func spend_life(ctx: Dictionary) -> bool:
	if not match_costs_life(ctx) or has_unlimited():
		return false
	tick_lives()
	if lives <= 0:
		return false
	lives -= 1
	if life_next_at == 0:
		life_next_at = now() + refill_seconds()
	save()
	return true


func add_lives(n: int) -> void:
	lives = mini(max_lives(), lives + n)
	if lives >= max_lives():
		life_next_at = 0
	save()


func refill_lives() -> void:
	lives = max_lives()
	life_next_at = 0
	save()


func buy_life_refill() -> bool:
	var cost := int(lives_cfg().get("refill_gems", 30))
	if gems < cost or lives >= max_lives():
		return false
	gems -= cost
	refill_lives()
	return true


func buy_unlimited() -> bool:
	var cost := int(lives_cfg().get("unlimited_gems", 60))
	if gems < cost:
		return false
	gems -= cost
	unlimited_until = maxi(now(), unlimited_until) + int(lives_cfg().get("unlimited_minutes", 120)) * 60
	save()
	return true


## Today's counters, reset at the first look each new day.
func _today() -> Dictionary:
	if String(today.get("date", "")) != date_str():
		today = {"date": date_str(), "ad_lives": 0, "rewarded": 0, "free_powerup": 0}
	return today


func ad_lives_left() -> int:
	return maxi(0, int(lives_cfg().get("ad_lives_per_day", 5)) - int(_today().get("ad_lives", 0)))


func rewarded_left() -> int:
	return maxi(0, int(f2p.get("ads", {}).get("rewarded_per_day", 15)) - int(_today().get("rewarded", 0)))


func free_powerups_left() -> int:
	return maxi(0, int(f2p.get("ads", {}).get("free_powerup_per_day", 1)) - int(_today().get("free_powerup", 0)))


## Counts a rewarded ad watched (kind: "life", "free_powerup" or "other").
func note_rewarded(kind: String) -> void:
	var t := _today()
	t["rewarded"] = int(t.get("rewarded", 0)) + 1
	if kind == "life":
		t["ad_lives"] = int(t.get("ad_lives", 0)) + 1
	elif kind == "free_powerup":
		t["free_powerup"] = int(t.get("free_powerup", 0)) + 1
	save()


func daily_available() -> bool:
	return daily_last != date_str()


## The reward waiting today, and which day of the 7-day streak it is.
func daily_preview() -> Array:
	var days: Array = f2p.get("daily", [])
	if days.is_empty():
		return [0, {}]
	var d := 0
	if daily_last != "":
		var y := Time.get_date_string_from_unix_time(now() - 86400)
		d = (daily_day + 1) % days.size() if daily_last == y else 0
	return [d, days[d]]


func claim_daily() -> Dictionary:
	if not daily_available():
		return {}
	var pv := daily_preview()
	daily_day = int(pv[0])
	daily_last = date_str()
	grant(pv[1])
	return pv[1]


## Gives a bundle: {"tips", "gems", "lives", "powerup" + "count", "powerups": {id: n}, "gear"}.
func grant(r: Dictionary) -> void:
	tips += int(r.get("tips", 0))
	gems += int(r.get("gems", 0))
	if r.has("lives"):
		lives = mini(max_lives(), lives + int(r["lives"]))
	if r.has("powerup"):
		var pid := String(r["powerup"])
		powerups[pid] = int(powerups.get(pid, 0)) + int(r.get("count", 1))
	for pid in r.get("powerups", {}):
		powerups[pid] = int(powerups.get(pid, 0)) + int(r["powerups"][pid])
	if r.has("gear"):
		var gid := String(r["gear"])
		if not gear_item(gid).is_empty():
			owned_gear[gid] = true
			equipped[String(gear_item(gid)["slot"])] = gid
	save()


## Human-readable bundle, for popups.
func describe(r: Dictionary) -> String:
	var parts := []
	if int(r.get("gems", 0)) > 0:
		parts.append("%d gems" % int(r["gems"]))
	if int(r.get("tips", 0)) > 0:
		parts.append("%d tips" % int(r["tips"]))
	if r.has("powerup"):
		parts.append("%d x %s" % [int(r.get("count", 1)), String(powerup(String(r["powerup"])).get("name", r["powerup"]))])
	for pid in r.get("powerups", {}):
		parts.append("%d x %s" % [int(r["powerups"][pid]), String(powerup(String(pid)).get("name", pid))])
	if r.has("gear"):
		parts.append(String(gear_item(String(r["gear"])).get("name", r["gear"])))
	return ", ".join(parts)


func product(pid: String) -> Dictionary:
	for p in f2p.get("products", []):
		if String(p["id"]) == pid:
			return p
	return {}


func owns(pid: String) -> bool:
	return owned_products.has(pid)


## No interstitials for anyone who removed ads, has the pass, or has paid
## for anything at all.
func ads_removed() -> bool:
	return owns("remove_ads") or owns("lounge_pass") or owns("payer")


## Called by Store when Google Play confirms a purchase.
func grant_product(pid: String) -> void:
	var p := product(pid)
	if p.is_empty():
		return
	owned_products["payer"] = true
	if String(p.get("type", "")) != "consumable":
		owned_products[pid] = true
	grant(p)
	if pid == "lounge_pass":
		refill_lives()
	save()


func gem_offer(oid: String) -> Dictionary:
	for o in f2p.get("gem_shop", []):
		if String(o["id"]) == oid:
			return o
	return {}


func buy_gem_offer(oid: String) -> bool:
	var o := gem_offer(oid)
	if o.is_empty() or gems < int(o.get("gems", 0)):
		return false
	gems -= int(o.get("gems", 0))
	tips += int(o.get("tips", 0))
	save()
	return true


func note_match_finished() -> void:
	matches_total += 1
	matches_since_ad += 1


func interstitial_due() -> bool:
	if ads_removed():
		return false
	var a: Dictionary = f2p.get("ads", {})
	return matches_total >= int(a.get("interstitial_after_matches", 4)) \
		and matches_since_ad >= int(a.get("interstitial_every", 3)) \
		and now() - last_interstitial >= int(a.get("interstitial_min_seconds", 180))


func note_interstitial() -> void:
	matches_since_ad = 0
	last_interstitial = now()
	save()


func outfits_of(id: String) -> Array:
	var o: Array = heroine(id).get("outfits", [])
	return o if not o.is_empty() else [{"id": "default", "name": "Default", "unlock": "default"}]


func outfit_def(id: String, oid: String) -> Dictionary:
	for o in outfits_of(id):
		if String(o["id"]) == oid:
			return o
	return {}


func outfit_owned(id: String, oid: String) -> bool:
	var o := outfit_def(id, oid)
	match String(o.get("unlock", "default")):
		"default":
			return true
		"story":
			return story_done(id) or unlock_all or outfits_owned.has("%s_%s" % [id, oid])
		_:
			return outfits_owned.has("%s_%s" % [id, oid])


func current_outfit(id: String) -> String:
	var oid := String(outfit.get(id, "default"))
	return oid if outfit_owned(id, oid) else "default"


func set_outfit(id: String, oid: String) -> void:
	if outfit_owned(id, oid):
		outfit[id] = oid
		save()


func buy_outfit(id: String, oid: String) -> bool:
	var o := outfit_def(id, oid)
	if o.is_empty() or outfit_owned(id, oid) or String(o.get("unlock", "")) != "gems":
		return false
	var cost := int(o.get("gems", 0))
	if gems < cost:
		return false
	gems -= cost
	outfits_owned["%s_%s" % [id, oid]] = true
	outfit[id] = oid
	save()
	return true


## The difficulty-curve tier for a match, by the level it needs
## (monetization.json "difficulty_curve").
func curve(id: String, mi: int) -> Dictionary:
	var lv := match_level(id, mi)
	var out: Dictionary = {}
	for t in f2p.get("difficulty_curve", {}).get("tiers", []):
		if lv >= int(t.get("from_level", 1)):
			out = t
	return out


func revive_cfg() -> Dictionary:
	return f2p.get("revive", {})


## Gem cost of the next revive in this match (after `used_gem` gem revives),
## or -1 when none are left.
func revive_gem_cost(used_gem: int) -> int:
	var costs: Array = revive_cfg().get("gem_costs", [20, 40, 80])
	return int(costs[used_gem]) if used_gem < costs.size() else -1
