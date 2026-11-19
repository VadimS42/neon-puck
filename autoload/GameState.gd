## GameState.gd (autoload "GameState")
##
## Loads data/heroines.json and keeps the save: how far you are with each
## heroine, which scenes and strip stages you've seen, and your settings.
## Saved to user://save.json after every change.
extends Node

const SAVE_PATH := "user://save.json"
const DATA_PATH := "res://data/heroines.json"
const PROG_PATH := "res://data/progression.json"

var data: Dictionary = {}
## data/progression.json: levels, tips, gear, power-ups, cups.
var prog: Dictionary = {}
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
## "<heroine>_<stage>" -> true, strip stages reached in a match
var stages_seen: Dictionary = {}
var difficulty := "normal"
var unlock_all := false
var age_ok := false
var fullscreen := false
## Set by the headless test so it never touches your save.
var no_save := false
var prologue_seen := false
## Your power shot: "smash", or a heroine's signature once you've won her
## over ("bullet", "ricochet", "hook").
var player_shot := "smash"
## All-ages mode: art lookups prefer *_sfw.png files (the separate SFW build
## the research recommends). Placeholders keep everyone covered.
var sfw := false


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
	_new_economy()
	load_save()


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
	pad.max_speed = speed
	pad.max_accel = float(s.get("accel", 6500)) * float(d.get("speed", 1.0)) * (speed / maxf(1.0, float(s.get("speed", 2200)) * float(d.get("speed", 1.0))))
	pad.radius = size
	pad.power_kind = String(h.get("signature", "bullet"))
	brain.reaction = maxf(0.04, reaction)
	brain.aim_spread = float(s.get("aim", 50)) * float(d.get("aim", 1.0))
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
		"age_ok": age_ok,
		"fullscreen": fullscreen,
		"prologue_seen": prologue_seen,
		"player_shot": player_shot,
		"sfw": sfw,
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
	age_ok = bool(d.get("age_ok", false))
	fullscreen = bool(d.get("fullscreen", false))
	prologue_seen = bool(d.get("prologue_seen", false))
	player_shot = String(d.get("player_shot", "smash"))
	sfw = bool(d.get("sfw", false))
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


func reset_progress() -> void:
	progress = {}
	scenes_seen = {}
	stages_seen = {}
	prologue_seen = false
	player_shot = "smash"
	_new_economy()
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
		lines.append(["Layers x%d" % rules.layers_lost, int(pl.get("xp", 0)) * rules.layers_lost, int(pl.get("tips", 0)) * rules.layers_lost])
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
	var lv_from := level
	add_xp(int(gx))
	tips += int(gt)
	save()
	return {"xp": int(gx), "tips": int(gt), "lines": lines, "level_from": lv_from, "level_to": level, "unlocks": unlocks_between(lv_from, level)}


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
