## GalleryScreen.gd: every strip stage and scene you've unlocked, per
## heroine. Settings → "Unlock all gallery" opens everything.
class_name GalleryScreen
extends Control

var main


func _init(m) -> void:
	main = m


func _ready() -> void:
	add_child(UI.background())
	var t := UI.label("Gallery", 38, UI.PINK)
	t.position = Vector2(40, 22)
	add_child(t)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(40, 80)
	scroll.size = Vector2(1200, 640)
	add_child(scroll)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	scroll.add_child(v)
	var first: Button
	for id in GameState.order():
		var h := GameState.heroine(id)
		v.add_child(UI.label(String(h.get("name", id)), 24, UI.hcolor(id)))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		v.add_child(row)
		for st in 4:
			var ok := GameState.stage_unlocked(id, st)
			var stage := st
			var b := UI.button(("Stage %d" % st) if ok else "Locked", func(): main.open_stage(id, stage), 16, UI.hcolor(id) if ok else UI.LINE)
			b.custom_minimum_size = Vector2(88, 90)
			b.disabled = not ok
			row.add_child(b)
			if first == null and ok:
				first = b
		for m in h.get("matches", []):
			var sc: Dictionary = m.get("scene", {})
			var ok2 := GameState.scene_unlocked(String(sc.get("id", "")))
			var b2 := UI.button(String(sc.get("title", "")) if ok2 else "Locked", func(): main.open_scene(id, sc), 16, UI.PINK if ok2 else UI.LINE)
			b2.custom_minimum_size = Vector2(124, 90)
			b2.clip_text = true
			b2.disabled = not ok2
			row.add_child(b2)
	v.add_child(UI.label("Cup nights and the championship", 24, UI.GOLD))
	var crow := HBoxContainer.new()
	crow.add_theme_constant_override("separation", 10)
	v.add_child(crow)
	for c in GameState.prog.get("tournaments", []):
		var cs: Dictionary = c.get("scene", {})
		var ok3 := GameState.scene_unlocked(String(cs.get("id", "")))
		var b3 := UI.button(String(cs.get("title", "")) if ok3 else "Win the %s" % String(c.get("name", "")), func(): main.open_scene(GameState.order().back(), cs), 16, UI.GOLD if ok3 else UI.LINE)
		b3.custom_minimum_size = Vector2(220, 90)
		b3.disabled = not ok3
		crow.add_child(b3)
	var fs: Dictionary = GameState.finale().get("scene", {})
	if not fs.is_empty():
		var okf := GameState.scene_unlocked(String(fs.get("id", "")))
		var bf := UI.button(String(fs.get("title", "")) if okf else "Win the championship", func(): main.open_scene("sable", fs), 16, UI.PINK if okf else UI.LINE)
		bf.custom_minimum_size = Vector2(220, 90)
		bf.disabled = not okf
		crow.add_child(bf)
	var back := UI.button("Back", main.show_menu, 20, UI.LINE)
	back.position = Vector2(40, 735)
	add_child(back)
	(first if first else back).call_deferred("grab_focus")


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		main.show_menu()
