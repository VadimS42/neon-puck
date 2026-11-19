## MenuScreen.gd: title and main buttons.
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
	v.position = Vector2(90, 70)
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
	v.add_child(UI.label("After hours, one table, no luck.", 22, UI.INK_SOFT))
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 20)
	v.add_child(sp)
	var play := UI.button("Play", main.show_roster, 28)
	v.add_child(play)
	v.add_child(UI.button("How to play", main.show_how_to_play, 22, UI.CYAN))
	v.add_child(UI.button("Gallery", main.show_gallery, 22, UI.CYAN))
	v.add_child(UI.button("Settings", func(): main.show_settings(), 22, UI.CYAN))
	v.add_child(UI.button("Quit", func(): get_tree().quit(), 22, UI.LINE))
	play.call_deferred("grab_focus")
	var ver := UI.label("Prototype v%s · placeholder art · difficulty: %s" % [ProjectSettings.get_setting("application/config/version"), String(GameState.diff().get("label", "Normal"))], 16, UI.INK_SOFT)
	ver.position = Vector2(760, 768)
	add_child(ver)


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
