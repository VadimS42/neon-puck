## GameState.gd (autoload "GameState")
##
## Loads data/heroines.json and keeps the save: how far you are with each
## heroine, which scenes and strip stages you've seen, and your settings.
## Saved to user://save.json after every change.
extends Node

const SAVE_PATH := "user://save.json"
const DATA_PATH := "res://data/heroines.json"

var data: Dictionary = {}
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
	if not h.has("unlock"):
		return true
	for other in order():
		if other != id and story_done(other):
			return true
	return false


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
	var arc_mult: float = [0.9, 0.97, 1.03, 1.08][clampi(match_index, 0, 3)]
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
	pad.max_speed = float(p.get("speed", 3200))
	pad.max_accel = float(p.get("accel", 40000))
	pad.radius = float(p.get("size", 38))
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


func reset_progress() -> void:
	progress = {}
	scenes_seen = {}
	stages_seen = {}
	prologue_seen = false
	player_shot = "smash"
	save()
