## Ads.gd (autoload "Ads")
##
## Every ad in the game goes through here, so the rules live in one place:
##  - Rewarded ads are always the player's choice, and the button says what
##    they get (a life, double tips, a free power-up).
##  - Interstitials only between matches, never on launch, never before a
##    story memory, and never for anyone who bought Remove Ads, the VIP
##    pass or any gem pack (GameState.interstitial_due).
##  - No banners.
##
## Backend right now: TEST only. A full-screen "TEST AD" card stands in for
## the real ad (5 seconds for rewarded, 3 for interstitials), so pacing and
## rewards can be tuned before an ad SDK goes in. To ship real ads, add an
## AdMob plugin for Godot 4 (for example Poing Studios' godot-admob-plugin)
## and fill in the three _real_* functions below; nothing else changes.
## Ad unit ids go in data/monetization.json ("ad_units"). See README_PLAY.md.
extends Node

var backend := "test"
var _layer: CanvasLayer


func is_test() -> bool:
	return backend == "test"


## Asks the user for ad consent where the law needs it (EU/UK: Google's
## UMP consent form). Test backend: remembers a default answer.
func request_consent(cb: Callable = Callable()) -> void:
	if GameState.ad_consent == "unknown":
		GameState.ad_consent = "non_personalized"
		GameState.save()
	if cb.is_valid():
		cb.call()


## Shows a rewarded ad; cb(true) only if the player watched it to the end.
func show_rewarded(kind: String, cb: Callable) -> void:
	if GameState.rewarded_left() <= 0:
		cb.call(false)
		return
	if backend != "test":
		_real_rewarded(kind, cb)
		return
	_test_card("Rewarded ad", 5.0, true, func(ok: bool):
		if ok:
			GameState.note_rewarded(kind)
		cb.call(ok))


## Shows an interstitial if one is due, then calls cb either way.
func maybe_interstitial(cb: Callable) -> void:
	if not GameState.interstitial_due():
		cb.call()
		return
	GameState.note_interstitial()
	if backend != "test":
		_real_interstitial(cb)
		return
	_test_card("Ad break", 3.0, false, func(_ok: bool): cb.call())


func _real_rewarded(_kind: String, cb: Callable) -> void:
	cb.call(false)


func _real_interstitial(cb: Callable) -> void:
	cb.call()


func _real_init() -> void:
	pass


## The stand-in ad: a full-screen card with a countdown. Rewarded ads can
## be closed early, which forfeits the reward (same as a real one).
func _test_card(title: String, secs: float, rewarded: bool, done: Callable) -> void:
	if DisplayServer.get_name() == "headless":
		done.call(true)
		return
	_layer = CanvasLayer.new()
	_layer.layer = 100
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.01, 0.05, 0.96)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(bg)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(c)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	c.add_child(v)
	v.add_child(UI.label("TEST AD", 64, UI.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UI.label(title + ": a real ad plays here once the ad SDK is in.", 22, UI.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	var count := UI.label("", 30, UI.INK, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(count)
	var finished := [false]
	var close := UI.button("Close (no reward)" if rewarded else "Close", func():
		if finished[0]:
			return
		finished[0] = true
		_layer.queue_free()
		done.call(false), 20, UI.LINE)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.visible = rewarded
	v.add_child(close)
	var t := secs
	while t > 0.0 and not finished[0]:
		count.text = "%d" % ceili(t)
		await get_tree().create_timer(0.25, true, false, true).timeout
		t -= 0.25
	if finished[0]:
		return
	finished[0] = true
	_layer.queue_free()
	done.call(true)
