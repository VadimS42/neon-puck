## CloudSave.gd (autoload "CloudSave")
##
## Keeps a copy of the save in the player's Google account, so a new phone
## or a reinstall doesn't wipe progress (and purchases tied to it).
##
## The cloud copy is one JSON blob: GameState's save, the Extras save, the
## time it was made and a "progress score" used to pick the better copy when
## the phone and the cloud disagree.
##
## Backends:
##  - "play": Google Play Games Services saved games (snapshots), used when
##    the Android build includes a Play Games plugin for Godot 4 (for
##    example godot-play-game-services, singleton
##    "GodotAndroidPlayGamesServices"). Written against that plugin's
##    documented snapshot calls and NOT tested on a device: check the
##    method and signal names against the version you install, and turn on
##    Saved Games in Play Console (README_PLAY.md).
##  - "test": everywhere else. Writes user://cloud_test.json, so the whole
##    flow (upload, conflict prompt, restore) can be tried on desktop.
extends Node

signal loaded(ok: bool, message: String)

const TEST_PATH := "user://cloud_test.json"
const SNAPSHOT := "neon_puck_rivals_save"
## Seconds between automatic uploads after matches.
const AUTO_EVERY := 90

var backend := "test"
var signed_in := false
var last_upload := 0
var _pgs: Object
## The cloud copy found at startup when it beats the phone's.
var pending: Dictionary = {}


func _ready() -> void:
	for sname in ["GodotAndroidPlayGamesServices", "GodotPlayGameServices"]:
		if Engine.has_singleton(sname):
			_pgs = Engine.get_singleton(sname)
			backend = "play"
			break
	if backend == "play":
		_connect_play()
	else:
		signed_in = true
	call_deferred("check_cloud")


func is_test() -> bool:
	return backend == "test"


## Bigger is further along: story wins, scenes, level, purchases.
func score_of(save: Dictionary) -> int:
	var s := 0
	for k in save.get("progress", {}):
		s += int(save["progress"][k]) * 100
	s += save.get("scenes_seen", {}).size() * 10
	s += int(save.get("level", 1)) * 20
	s += save.get("owned_products", {}).size() * 1000
	return s


func _local_save() -> Dictionary:
	var f := FileAccess.open(GameState.SAVE_PATH, FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}


func make_blob() -> Dictionary:
	var gs := _local_save()
	return {"v": 1, "time": int(Time.get_unix_time_from_system()), "score": score_of(gs), "game": gs, "extras": Extras.to_dict()}


## Uploads now (Settings button, app going to the background).
func upload() -> void:
	if GameState.no_save or not signed_in:
		return
	var blob := make_blob()
	last_upload = int(Time.get_unix_time_from_system())
	if backend == "play":
		_pgs.call("saveGame", SNAPSHOT, "Neon Puck Rivals progress", JSON.stringify(blob))
		return
	var f := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(blob))


## After a match: upload if the last one was a while ago.
func maybe_upload() -> void:
	if int(Time.get_unix_time_from_system()) - last_upload >= AUTO_EVERY:
		upload()


## Startup: fetch the cloud copy; if it's further along than the phone's,
## keep it in `pending` so the menu can ask before replacing anything.
func check_cloud() -> void:
	if GameState.no_save:
		return
	if backend == "play":
		_pgs.call("loadGame", SNAPSHOT, false)
		return
	_on_cloud_blob(_read_test())


func _read_test() -> Dictionary:
	var f := FileAccess.open(TEST_PATH, FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}


func _on_cloud_blob(blob: Dictionary) -> void:
	if blob.is_empty():
		return
	if int(blob.get("score", 0)) > score_of(_local_save()):
		pending = blob


## Settings "Load from cloud": fetch and apply whatever is there.
func download() -> void:
	if backend == "play":
		pending = {"_apply": true}
		_pgs.call("loadGame", SNAPSHOT, false)
		return
	var blob := _read_test()
	if blob.is_empty():
		loaded.emit(false, "No cloud save yet.")
		return
	apply(blob)


## Replaces the phone's save with a cloud copy and reloads everything.
func apply(blob: Dictionary) -> void:
	var gs: Dictionary = blob.get("game", {})
	if gs.is_empty():
		loaded.emit(false, "The cloud save was empty.")
		return
	var f := FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
	if f == null:
		loaded.emit(false, "Couldn't write the save file.")
		return
	f.store_string(JSON.stringify(gs))
	f.close()
	GameState.load_save()
	Extras.from_dict(blob.get("extras", {}))
	Extras.save()
	pending = {}
	loaded.emit(true, "Progress restored from the cloud.")


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		upload()


# ---------------------------------------------------- Play Games backend

func _connect_play() -> void:
	if _pgs.has_signal("userAuthenticated"):
		_pgs.connect("userAuthenticated", func(ok: bool):
			signed_in = ok
			if ok:
				check_cloud())
	if _pgs.has_signal("gameLoaded"):
		_pgs.connect("gameLoaded", func(data):
			var d = JSON.parse_string(String(data)) if data is String else null
			var blob: Dictionary = d if d is Dictionary else {}
			if bool(pending.get("_apply", false)):
				pending = {}
				if blob.is_empty():
					loaded.emit(false, "No cloud save yet.")
				else:
					apply(blob)
			else:
				_on_cloud_blob(blob))
	if _pgs.has_method("isAuthenticated"):
		_pgs.call("isAuthenticated")
