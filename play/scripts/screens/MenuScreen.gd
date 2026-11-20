## MenuScreen.gd: title, main buttons, your lives and gems, and the daily
## reward card (once a day, 7-day streak).
class_name MenuScreen
extends Control

var main


func _init(m) -> void:
	main = m


func _ready() -> void:
	var bg := ArtAssets.background("menu")
	add_child(UI.background())
	if bg:
		var tr := TextureRect.new()
		tr.texture = bg
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		add_child(UI.fill(tr))
	else:
		add_child(_NeonDeco.new())
	var v := VBoxContainer.new()
	v.position = Vector2(90, 50)
	v.custom_minimum_size = Vector2(420, 0)
	v.add_theme_constant_override("separation", 14)
	add_child(v)
	var logo := ArtAssets.ui("logo")
	if logo:
		var lt := TextureRect.new()
		lt.texture = logo
		lt.custom_minimum_size = Vector2(420, 160)
		lt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lt.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		v.add_child(lt)
	else:
		var t1 := UI.label("NEON", 80, UI.PINK)
		var t2 := UI.label("PUCK", 80, UI.CYAN)
		t1.add_theme_constant_override("line_spacing", -20)
		v.add_child(t1)
		v.add_child(t2)
		t2.custom_minimum_size = Vector2(0, 80)
		t1.custom_minimum_size = Vector2(0, 80)
	v.add_child(UI.label("One table. Four rivals. Zero luck.", 22, UI.INK_SOFT))
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 4)
	v.add_child(sp)
	var play := UI.button("Play", main.show_roster, 28, UI.PINK, "right")
	v.add_child(play)
	v.add_child(UI.button("How to play", main.show_how_to_play, 22, UI.CYAN, "question"))
	v.add_child(UI.button("Store", func(): main.show_store(main.show_menu), 22, UI.GOLD, "gem"))
	v.add_child(UI.button("Wardrobe", func(): main.show_wardrobe(main.show_menu), 22, UI.CYAN, "star"))
	v.add_child(UI.button("Album", main.show_gallery, 22, UI.CYAN, "star"))
	v.add_child(UI.button("Settings", func(): main.show_settings(), 22, UI.CYAN, "gear"))
	play.call_deferred("grab_focus")
	add_child(UI.pin_top_right(UI.status_bar(Vector2.ZERO), 20, 14))
	var ver := UI.label("v%s, placeholder art, difficulty: %s%s" % [ProjectSettings.get_setting("application/config/version"), String(GameState.diff().get("label", "Normal")), ", test store and ads" if Store.is_test() or Ads.is_test() else ""], 16, UI.INK_SOFT)
	ver.position = Vector2(600, 768)
	add_child(ver)
	# Live features: daily missions, this week's event, the season pass.
	var live := HBoxContainer.new()
	live.position = Vector2(600, 640)
	live.add_theme_constant_override("separation", 10)
	add_child(live)
	if Extras.missions_enabled():
		var n := Extras.missions_to_claim()
		live.add_child(UI.button("Missions" + (" (%d)" % n if n > 0 else ""), func(): main.show_missions(), 20, UI.GOLD if n > 0 else UI.CYAN, "star"))
	if not Extras.current_event().is_empty():
		live.add_child(UI.button("Event: " + String(Extras.current_event().get("name", "")), func(): main.show_event(main.show_menu), 20, UI.PINK, "trophy"))
	if Extras.season_enabled():
		var u := Extras.season_unclaimed()
		live.add_child(UI.button("Pass" + (" (%d)" % u if u > 0 else ""), func(): main.show_season(main.show_menu), 20, UI.GOLD, "gem"))
	if not CloudSave.pending.is_empty() and not GameState.no_save:
		_cloud_offer.call_deferred()
	elif GameState.daily_available() and not GameState.no_save:
		_daily.call_deferred()


## The cloud has a save that's further along than this phone's.
func _cloud_offer() -> void:
	var blob := CloudSave.pending
	var when := Time.get_datetime_string_from_unix_time(int(blob.get("time", 0)), true)
	UI.popup(self, "Cloud save found", "Your Google account has progress from %s that's further along than this device. Load it?" % when, [
		["Load cloud save", func():
			CloudSave.apply(blob)
			main.show_menu(), UI.GOLD],
		["Keep this device's", func():
			CloudSave.pending = {}
			CloudSave.upload()
			main.show_menu(), UI.LINE],
	], UI.CYAN)


func _daily() -> void:
	var pv := GameState.daily_preview()
	var days: Array = GameState.f2p.get("daily", [])
	var lines := []
	for i in days.size():
		lines.append("%s Day %d: %s" % ["▶" if i == int(pv[0]) else ("✓" if i < int(pv[0]) else "  "), i + 1, GameState.describe(days[i])])
	UI.popup(self, "Daily reward, day %d" % (int(pv[0]) + 1), "Come back every day: miss one and the streak starts over.\n\n" + "\n".join(lines), [
		["Claim " + GameState.describe(pv[1]), func():
			GameState.claim_daily()
			main.show_menu(), UI.GOLD, "coin"],
	], UI.GOLD)


## Placeholder title art: a glowing table and puck.
class _NeonDeco extends Control:
	var t := 0.0
	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(d: float) -> void:
		t += d
		queue_redraw()
	func _draw() -> void:
		var r := Rect2(600, 170, 600, 440)
		draw_rect(r, Color("#160F2A"))
		draw_rect(r, UI.CYAN, false, 4)
		draw_line(Vector2(r.position.x + r.size.x / 2, r.position.y), Vector2(r.position.x + r.size.x / 2, r.end.y), Color(UI.PINK, 0.6), 3)
		draw_arc(r.get_center(), 70, 0, TAU, 48, Color(UI.PINK, 0.6), 3)
		var p := r.get_center() + Vector2(cos(t * 1.3) * 220, sin(t * 2.1) * 160)
		draw_circle(p, 22, Color(UI.GOLD, 0.25))
		draw_circle(p, 16, UI.GOLD)
		draw_circle(Vector2(r.position.x + 60, r.get_center().y + sin(t * 2.1) * 120), 34, Color(UI.CYAN, 0.9))
		draw_circle(Vector2(r.end.x - 60, r.get_center().y + sin(t * 2.1 + 0.6) * 120), 34, Color(UI.PINK, 0.9))
