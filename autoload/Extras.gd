## Extras.gd (autoload "Extras")
##
## Everything added on top of the core loop, kept out of GameState so both
## games share one file (the same script lives in play/autoload/). What a
## game offers depends on what its data/extras.json has:
##   - achievements (+ Steam / Play Games hooks)
##   - dialogue choices and the flags they set, conditional lines
##   - crossover scenes, rival barks, the finale variant by who you won first
##   - daily missions (Rivals)
##   - comeback help after repeated losses (Rivals)
##   - shot trainer results, the Endless Ladder, epilogue dates (Neon Puck)
##   - weekly event cup and season pass (Rivals)
## Saved to user://extras.json, next to GameState's save.
extends Node

signal achievement_unlocked(a: Dictionary)

const SAVE_PATH := "user://extras.json"
const DATA_PATH := "res://data/extras.json"

var data: Dictionary = {}

## Dialogue choices: "<heroine>_<match>" -> picked tag ("tease", ...).
var flags: Dictionary = {}
## Lifetime counters (see STAT_KEYS).
var stats: Dictionary = {}
## Achievement id -> unix time unlocked.
var unlocked: Dictionary = {}
## Heroines in the order you won them over.
var won_order: Array = []
## "crossover_<id>", "epilogue_<id>" -> true once played.
var seen: Dictionary = {}
## Today's missions: {"date", "ids": [], "base": {stat: value at start}, "claimed": [], "bonus": bool}.
var missions: Dictionary = {}
## Story losses in a row per match: "<id>_<mi>" -> n.
var loss_streak: Dictionary = {}
## Endless Ladder: the run in progress {"round", "seed"} or {}, and the best rung reached.
var ladder_run: Dictionary = {}
var ladder_best := 0
## Weekly event cup: {"week", "round", "won", "runs"}.
var event_state: Dictionary = {}
## Season pass: {"id", "xp", "free": {tier: true}, "premium": {tier: true}}.
var season: Dictionary = {}
## Dialogue auto-advance.
var auto_advance := false
## Local notifications (Rivals).
var notify_on := true
## Mods a dialogue choice set for the match that follows (Sable's terms).
var pending_mods: Array = []


const STAT_KEYS := ["matches", "wins", "story_wins", "bank_goals", "smash_goals", "saves", "strips", "blocks", "shutouts", "special_wins", "rush_wins", "trainer_passes", "cups", "ladder_rungs", "crossovers", "epilogues", "choices", "missions", "events", "comebacks"]


func _ready() -> void:
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	if f:
		var parsed = JSON.parse_string(f.get_as_text())
		if parsed is Dictionary:
			data = parsed
	load_save()


func _gs() -> Node:
	return get_node("/root/GameState")


# ------------------------------------------------------------------ save

func save() -> void:
	if _gs().no_save:
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(to_dict()))


func to_dict() -> Dictionary:
	return {
		"flags": flags, "stats": stats, "unlocked": unlocked, "won_order": won_order,
		"seen": seen, "missions": missions, "loss_streak": loss_streak,
		"ladder_run": ladder_run, "ladder_best": ladder_best, "event_state": event_state,
		"season": season, "auto_advance": auto_advance, "notify_on": notify_on,
	}


func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		from_dict(d)


func from_dict(d: Dictionary) -> void:
	flags = d.get("flags", {})
	stats = d.get("stats", {})
	unlocked = d.get("unlocked", {})
	won_order = d.get("won_order", [])
	seen = d.get("seen", {})
	missions = d.get("missions", {})
	loss_streak = d.get("loss_streak", {})
	ladder_run = d.get("ladder_run", {})
	ladder_best = int(d.get("ladder_best", 0))
	event_state = d.get("event_state", {})
	season = d.get("season", {})
	auto_advance = bool(d.get("auto_advance", false))
	notify_on = bool(d.get("notify_on", true))


func reset() -> void:
	from_dict({})
	save()


## Story reset: forget choices and story order, keep achievements, stats,
## missions, events and the season pass.
func reset_story() -> void:
	flags = {}
	won_order = []
	seen = {}
	loss_streak = {}
	ladder_run = {}
	save()


func stat(key: String) -> int:
	return int(stats.get(key, 0))


func bump(key: String, n: int = 1) -> void:
	if n != 0:
		stats[key] = stat(key) + n


# ------------------------------------------------------------ match hook

## Called by Main for every finished match, before rewards. Updates the
## counters, missions, the season pass, loss streaks and achievements.
func on_match(ctx: Dictionary, rules: MatchRules) -> void:
	var mode := String(ctx.get("mode", "story"))
	var won := rules.player_won
	if mode == "trainer":
		if won:
			bump("trainer_passes")
		check_achievements()
		save()
		return
	bump("matches")
	bump("bank_goals", rules.bank_goals)
	bump("smash_goals", rules.smash_goals)
	bump("saves", rules.saves)
	bump("strips", rules.layers_lost)
	bump("blocks", rules.sig_blocks)
	if won:
		bump("wins")
		if rules.sim.paddle(1).score == 0:
			bump("shutouts")
		if not rules.mods.is_empty():
			bump("special_wins")
		if rules.mods.has("rush"):
			bump("rush_wins")
		if rules.revives == 0 and rules.max_deficit >= 3:
			bump("comebacks")
	var key := "%s_%d" % [rules.heroine_id, rules.match_index]
	if mode == "story":
		if won:
			bump("story_wins")
			loss_streak.erase(key)
		else:
			loss_streak[key] = int(loss_streak.get(key, 0)) + 1
	if mode == "ladder" and won:
		bump("ladder_rungs")
	add_season_xp(int(data.get("season", {}).get("xp_win" if won else "xp_loss", 0)))
	check_achievements()
	save()


## A heroine's story is finished: remember the order (finale variant).
func note_won_over(id: String) -> void:
	if not won_order.has(id):
		won_order.append(id)
		save()


# ---------------------------------------------------------- achievements

func achievements() -> Array:
	return data.get("achievements", [])


## Current value toward an achievement.
func progress_of(a: Dictionary) -> int:
	var gs := _gs()
	var k := String(a.get("stat", ""))
	match k:
		"won_over":
			var n := 0
			for id in gs.order():
				if gs.story_done(id):
					n += 1
			return n
		"finale":
			return 1 if gs.finale_done else 0
		"scenes":
			return gs.scenes_seen.size()
		"trophies":
			return gs.trophies.size()
		"level":
			return gs.level
		"ladder_best":
			return ladder_best
		"won":
			return 1 if gs.story_done(String(a.get("id_of", ""))) else 0
		"alt_scenes":
			var n2 := 0
			for id in gs.order():
				for m in gs.heroine(id).get("matches", []):
					var alt: Dictionary = m.get("alt_scene", {})
					if not alt.is_empty() and gs.scenes_seen.has(String(alt.get("id", ""))):
						n2 += 1
			return n2
	return stat(k)


## Unlocks anything newly earned; returns the new ones.
func check_achievements() -> Array:
	var out := []
	for a in achievements():
		var id := String(a.get("id", ""))
		if id == "" or unlocked.has(id):
			continue
		if progress_of(a) >= int(a.get("n", 1)):
			unlocked[id] = int(Time.get_unix_time_from_system())
			out.append(a)
			_push_platform(a)
			achievement_unlocked.emit(a)
	if not out.is_empty():
		save()
	return out


## Mirrors an unlock to Steam (GodotSteam) or Google Play Games when the
## build includes them. Untested without the real SDKs: check the call
## names against the plugin versions you install (see README).
func _push_platform(a: Dictionary) -> void:
	var id := String(a.get("id", ""))
	if Engine.has_singleton("Steam"):
		var st := Engine.get_singleton("Steam")
		st.call("setAchievement", String(a.get("steam_id", id)).to_upper())
		st.call("storeStats")
	var pid := String(a.get("play_id", ""))
	if pid != "":
		for sname in ["GodotAndroidPlayGamesServices", "GodotPlayGameServices"]:
			if Engine.has_singleton(sname):
				Engine.get_singleton(sname).call("unlockAchievement", pid)
				break


# ------------------------------------------------- choices and conditions

func set_flag(key: String, tag: String) -> void:
	if not flags.has(key):
		bump("choices")
	flags[key] = tag
	save()


func flag(key: String) -> String:
	return String(flags.get(key, ""))


## How many of her matches you answered with `tag`.
func choice_count(id: String, tag: String) -> int:
	var n := 0
	for k in flags:
		if String(k).begins_with(id + "_") and String(flags[k]) == tag:
			n += 1
	return n


## Conditions on dialogue lines ("if"): "mila_2=tease", "!mila_2=tease",
## "first=juno" (the first heroine you won over), "won=kat",
## "count:mila:flirt>=3", "wins:juno>=3" (story wins with her). Several joined with "&" must all hold.
func cond(c: String) -> bool:
	if c == "":
		return true
	for part in c.split("&"):
		if not _cond1(part.strip_edges()):
			return false
	return true


func _cond1(c: String) -> bool:
	if c.begins_with("!"):
		return not _cond1(c.substr(1))
	if c.begins_with("wins:"):
		var wb := c.substr(5).split(">=")
		return _gs().wins(wb[0]) >= int(wb[1])
	if c.begins_with("count:"):
		var bits := c.substr(6).split(">=")
		var who := bits[0].split(":")
		return choice_count(who[0], who[1]) >= int(bits[1])
	var kv := c.split("=")
	if kv.size() != 2:
		return false
	match kv[0]:
		"first":
			return not won_order.is_empty() and String(won_order[0]) == kv[1]
		"won":
			return _gs().story_done(kv[1])
	return flag(kv[0]) == kv[1]


## Drops lines whose "if" fails.
func filter_lines(lines: Array) -> Array:
	var out := []
	for L in lines:
		if L is Dictionary and not cond(String(L.get("if", ""))):
			continue
		out.append(L)
	return out


## The scene a story win unlocks: her alternate one if your choices earned it.
func pick_scene(id: String, m: Dictionary) -> Dictionary:
	var alt: Dictionary = m.get("alt_scene", {})
	if not alt.is_empty() and choice_count(id, String(alt.get("tag", ""))) >= int(alt.get("min", 3)):
		return alt
	return m.get("scene", {})


# ------------------------------------------------------------ crossovers

func crossovers() -> Array:
	return data.get("crossovers", [])


func crossover_ready(c: Dictionary) -> bool:
	var gs := _gs()
	if gs.unlock_all:
		return true
	var need := int(c.get("need", 3))
	return gs.wins(String(c["a"])) >= need and gs.wins(String(c["b"])) >= need


## Crossovers you can play now and haven't seen yet.
func crossovers_waiting() -> Array:
	var out := []
	for c in crossovers():
		if crossover_ready(c) and not seen.has("crossover_" + String(c["id"])):
			out.append(c)
	return out


func see(key: String, stat_key: String = "") -> void:
	if not seen.has(key) and stat_key != "":
		bump(stat_key)
	seen[key] = true
	check_achievements()
	save()


## A jealous or curious line about another heroine you're getting close to,
## said at the start of a match. "" if there's nothing to say.
func rival_bark(id: String) -> String:
	var gs := _gs()
	var lines: Dictionary = data.get("rival_barks", {}).get(id, {})
	var best := ""
	var best_w := 2
	for other in gs.order():
		if other == id or not lines.has(other):
			continue
		if gs.wins(other) > best_w:
			best_w = gs.wins(other)
			best = String(lines[other])
	return best


## Extra finale lines for whoever you won over first.
func finale_extra() -> Array:
	if won_order.is_empty():
		return []
	return data.get("finale_by_first", {}).get(String(won_order[0]), [])


# -------------------------------------------------------------- missions

func mission_cfg() -> Dictionary:
	return data.get("missions", {})


func missions_enabled() -> bool:
	return not mission_cfg().get("pool", []).is_empty()


## Today's three missions, rolled from the date so everyone gets the same set.
func todays_missions() -> Array:
	if not missions_enabled():
		return []
	var today := Time.get_date_string_from_system()
	if String(missions.get("date", "")) != today:
		var pool: Array = mission_cfg().get("pool", [])
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(today)
		var idx := range(pool.size())
		var ids := []
		for i in mini(int(mission_cfg().get("per_day", 3)), pool.size()):
			var j := rng.randi_range(i, idx.size() - 1)
			var t = idx[i]
			idx[i] = idx[j]
			idx[j] = t
			ids.append(String(pool[idx[i]]["id"]))
		var base := {}
		for k in STAT_KEYS:
			base[k] = stat(k)
		missions = {"date": today, "ids": ids, "base": base, "claimed": [], "bonus": false}
		save()
	var out := []
	for mid in missions.get("ids", []):
		for m in mission_cfg().get("pool", []):
			if String(m["id"]) == String(mid):
				out.append(m)
	return out


func mission_progress(m: Dictionary) -> int:
	var k := String(m.get("stat", ""))
	return mini(int(m.get("n", 1)), stat(k) - int(missions.get("base", {}).get(k, stat(k))))


func mission_done(m: Dictionary) -> bool:
	return mission_progress(m) >= int(m.get("n", 1))


func mission_claimed(m: Dictionary) -> bool:
	return missions.get("claimed", []).has(String(m["id"]))


## Missions finished but not yet collected (for the menu badge).
func missions_to_claim() -> int:
	var n := 0
	for m in todays_missions():
		if mission_done(m) and not mission_claimed(m):
			n += 1
	if all_missions_claimed() and not bool(missions.get("bonus", false)):
		n += 1
	return n


func all_missions_claimed() -> bool:
	var ms := todays_missions()
	if ms.is_empty():
		return false
	for m in ms:
		if not mission_claimed(m):
			return false
	return true


func claim_mission(m: Dictionary) -> bool:
	if not mission_done(m) or mission_claimed(m):
		return false
	missions["claimed"].append(String(m["id"]))
	_gs().grant(m.get("reward", {}))
	bump("missions")
	add_season_xp(int(data.get("season", {}).get("xp_mission", 0)))
	check_achievements()
	save()
	return true


func claim_mission_bonus() -> bool:
	if not all_missions_claimed() or bool(missions.get("bonus", false)):
		return false
	missions["bonus"] = true
	_gs().grant(mission_cfg().get("bonus", {}))
	save()
	return true


# ---------------------------------------------------------- comeback help

func comeback_cfg() -> Dictionary:
	return data.get("comeback", {})


## True when you've lost this story match enough times in a row to be
## offered help.
func needs_help(id: String, mi: int) -> bool:
	if comeback_cfg().is_empty():
		return false
	return int(loss_streak.get("%s_%d" % [id, mi], 0)) >= int(comeback_cfg().get("after_losses", 3))


# ---------------------------------------------------------------- ladder

func ladder_cfg() -> Dictionary:
	return data.get("ladder", {})


func ladder_open() -> bool:
	if ladder_cfg().is_empty():
		return false
	return _gs().finale_done or _gs().unlock_all


func start_ladder() -> void:
	ladder_run = {"round": 0, "seed": randi()}
	save()


## Who you face on a rung, her rules and how much sharper she plays.
func ladder_rung(r: int) -> Dictionary:
	var gs := _gs()
	var cfg := ladder_cfg()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(ladder_run.get("seed", 1)) + r * 7919
	var pool: Array = gs.order()
	var id := String(pool[rng.randi_range(0, pool.size() - 1)])
	var all_mods: Array = MatchMods.DEFS.keys()
	all_mods.erase("handicap")
	var mods := []
	var n := 0 if r == 0 else (1 if r < 4 else 2)
	for i in n:
		var m = all_mods[rng.randi_range(0, all_mods.size() - 1)]
		if not mods.has(m) and not (m == "big_goals" and mods.has("mini_goals")) and not (m == "mini_goals" and mods.has("big_goals")):
			mods.append(m)
	return {
		"id": id,
		"mods": mods,
		"target": int(cfg.get("target", 5)),
		"boost": minf(float(cfg.get("boost_step", 0.03)) * r, float(cfg.get("boost_max", 0.45))),
	}


func ladder_won(r: int) -> void:
	ladder_best = maxi(ladder_best, r + 1)
	ladder_run["round"] = r + 1
	check_achievements()
	save()


func ladder_lost() -> void:
	ladder_run = {}
	save()


# ------------------------------------------------------------- epilogues

func epilogues() -> Dictionary:
	return data.get("epilogues", {})


func epilogue_ready(id: String) -> bool:
	var gs := _gs()
	if not epilogues().has(id):
		return false
	return gs.unlock_all or (gs.finale_done and gs.story_done(id))


# ---------------------------------------------------------- weekly event

func events() -> Array:
	return data.get("events", [])


## Weeks since a fixed Monday, so the event changes every Monday 00:00 UTC.
func week_index() -> int:
	var monday := 1704067200 # 2024-01-01, a Monday
	return int((int(Time.get_unix_time_from_system()) - monday) / 604800)


func current_event() -> Dictionary:
	var ev := events()
	if ev.is_empty():
		return {}
	return ev[week_index() % ev.size()]


func event_now() -> Dictionary:
	if int(event_state.get("week", -1)) != week_index():
		event_state = {"week": week_index(), "round": 0, "won": false, "runs": 0}
	return event_state


func seconds_left_in_event() -> int:
	var monday := 1704067200
	return monday + (week_index() + 1) * 604800 - int(Time.get_unix_time_from_system())


func event_opponents() -> Array:
	var e := current_event()
	if e.has("opponents"):
		return e["opponents"]
	return _gs().unlocked_heroines()


func event_round_won(r: int) -> bool:
	var st := event_now()
	var last := r >= int(current_event().get("rounds", 3)) - 1
	if last:
		var first_time := not bool(st.get("won", false))
		st["won"] = true
		st["round"] = 0
		st["runs"] = int(st.get("runs", 0)) + 1
		if first_time:
			bump("events")
			_gs().grant(current_event().get("reward", {}))
			grant_outfit(String(current_event().get("outfit", "")))
		check_achievements()
		save()
		return first_time
	st["round"] = r + 1
	save()
	return false


func event_lost() -> void:
	event_now()["round"] = 0
	save()


## "mila:event_rush" -> owns that outfit.
func grant_outfit(ref: String) -> void:
	if ref == "" or not ref.contains(":"):
		return
	var gs := _gs()
	var bits := ref.split(":")
	if gs.get("outfits_owned") != null:
		gs.outfits_owned["%s_%s" % [bits[0], bits[1]]] = true
		gs.save()


# ----------------------------------------------------------- season pass

func season_cfg() -> Dictionary:
	return data.get("season", {})


func season_enabled() -> bool:
	return not season_cfg().get("tiers", []).is_empty()


func season_now() -> Dictionary:
	var sid := String(season_cfg().get("id", ""))
	if String(season.get("id", "")) != sid:
		season = {"id": sid, "xp": 0, "free": {}, "premium": {}}
	return season


func add_season_xp(n: int) -> void:
	if n <= 0 or not season_enabled():
		return
	var s := season_now()
	s["xp"] = int(s.get("xp", 0)) + n


func season_tier() -> int:
	var per := maxi(1, int(season_cfg().get("xp_per_tier", 100)))
	return mini(int(season_now().get("xp", 0)) / per, season_cfg().get("tiers", []).size())


func season_premium() -> bool:
	return _gs().has_method("owns") and _gs().owns(String(season_cfg().get("product", "")))


## Claims one tier's reward on one track ("free" or "premium").
func claim_season(tier: int, track: String) -> bool:
	var s := season_now()
	var tiers: Array = season_cfg().get("tiers", [])
	if tier < 0 or tier >= tiers.size() or tier >= season_tier():
		return false
	if track == "premium" and not season_premium():
		return false
	var got: Dictionary = s.get(track, {})
	if got.has(str(tier)):
		return false
	got[str(tier)] = true
	s[track] = got
	var r: Dictionary = tiers[tier].get(track, {})
	_gs().grant(r)
	grant_outfit(String(r.get("outfit", "")))
	save()
	return true


func season_unclaimed() -> int:
	if not season_enabled():
		return 0
	var n := 0
	var s := season_now()
	var tiers: Array = season_cfg().get("tiers", [])
	for t in season_tier():
		if not tiers[t].get("free", {}).is_empty() and not s.get("free", {}).has(str(t)):
			n += 1
		if season_premium() and not tiers[t].get("premium", {}).is_empty() and not s.get("premium", {}).has(str(t)):
			n += 1
	return n
