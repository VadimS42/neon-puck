## Notify.gd (autoload "Notify")
##
## Local reminders, scheduled when the game goes to the background and
## cleared when it comes back:
##   - "Your lives are full" at the moment the last life refills.
##   - "Your daily reward is ready" the next day at 10:00, if today's was
##     claimed (and new missions are waiting).
## Off switch in Settings (Extras.notify_on). Never more than these two.
##
## Backends:
##  - "plugin": a local-notification plugin for Godot 4 on Android, used
##    when its singleton is present (names tried: "LocalNotification",
##    "NotificationScheduler"). Android 13+ also needs the
##    POST_NOTIFICATIONS permission, which the plugin requests. Written
##    against those plugins' usual calls and NOT tested on a device.
##  - "test": prints what it would schedule and keeps the list in
##    `scheduled`, so the timing can be checked on desktop.
extends Node

const ID_LIVES := 1
const ID_DAILY := 2

var backend := "test"
var scheduled: Array = []
var _plugin: Object


func _ready() -> void:
	for sname in ["LocalNotification", "NotificationScheduler"]:
		if Engine.has_singleton(sname):
			_plugin = Engine.get_singleton(sname)
			backend = "plugin"
			break


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		schedule_all()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		cancel_all()


## What would be scheduled right now: [[id, seconds from now, title, text], ...].
func plan() -> Array:
	var out := []
	if not Extras.notify_on:
		return out
	GameState.tick_lives()
	if GameState.lives < GameState.max_lives() and not GameState.has_unlimited():
		var missing := GameState.max_lives() - GameState.lives
		var secs := GameState.seconds_to_next_life() + (missing - 1) * GameState.refill_seconds()
		if secs > 60:
			out.append([ID_LIVES, secs, "Lives full", "Your lives are full. The table's waiting."])
	if not GameState.daily_available():
		var tm := Time.get_time_dict_from_system()
		var secs2 := 86400 - (int(tm.hour) * 3600 + int(tm.minute) * 60 + int(tm.second)) + 10 * 3600
		out.append([ID_DAILY, secs2, "Daily reward", "Your daily reward and new missions are ready."])
	return out


func schedule_all() -> void:
	cancel_all()
	scheduled = plan()
	for n in scheduled:
		if backend == "plugin":
			if _plugin.has_method("show"):
				_plugin.call("show", String(n[3]), String(n[2]), int(n[1]), int(n[0]))
			elif _plugin.has_method("schedule"):
				_plugin.call("schedule", int(n[0]), String(n[2]), String(n[3]), int(n[1]))
		else:
			print("[Notify test] in %ds: %s - %s" % [int(n[1]), n[2], n[3]])


func cancel_all() -> void:
	if backend == "plugin":
		for id in [ID_LIVES, ID_DAILY]:
			if _plugin.has_method("cancel"):
				_plugin.call("cancel", id)
	scheduled = []
