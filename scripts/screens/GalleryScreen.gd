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
			b.custom_minimum_size = Vector2(76, 90)
			b.disabled = not ok
			row.add_child(b)
			if first == null and ok:
				first = b
		for m in h.get("matches", []):
			var sc: Dictionary = m.get("scene", {})
			var ok2 := GameState.scene_unlocked(String(sc.get("id", "")))
			var b2 := UI.button(String(sc.get("title", "")) if ok2 else "Locked", func(): main.open_scene(id, sc), 16, UI.PINK if ok2 else UI.LINE)
			b2.custom_minimum_size = Vector2(104, 90)
			b2.clip_text = true
			b2.disabled = not ok2
			row.add_child(b2)
			var alt: Dictionary = m.get("alt_scene", {})
			if not alt.is_empty():
				var ok4 := GameState.scene_unlocked(String(alt.get("id", "")))
				var b4 := UI.button(String(alt.get("title", "")) if ok4 else "Secret", func(): main.open_scene(id, alt), 16, UI.GOLD if ok4 else UI.LINE)
				b4.custom_minimum_size = Vector2(104, 90)
				b4.clip_text = true
				b4.disabled = not ok4
				b4.tooltip_text = "" if ok4 else String(alt.get("hint", "An alternate scene your choices can earn."))
				row.add_child(b4)
		# Memories: replay any conversation from a match you've won.
		var trow := HBoxContainer.new()
		trow.add_theme_constant_override("separation", 6)
		trow.add_child(UI.label("Talks", 15, UI.INK_SOFT))
		for mi in h.get("matches", []).size():
			var okt: bool = GameState.wins(id) > mi or GameState.unlock_all
			var mm: int = mi
			var bt := UI.button("%d" % (mi + 1), func(): main.replay_talk(id, mm), 14, UI.hcolor(id) if okt else UI.LINE)
			bt.disabled = not okt
			trow.add_child(bt)
		v.add_child(trow)
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
	var xs := Extras.crossovers()
	var eps := Extras.epilogues()
	if not xs.is_empty() or not eps.is_empty():
		v.add_child(UI.label("Crossovers and dates", 24, UI.PINK))
		var xrow := HFlowContainer.new()
		xrow.custom_minimum_size = Vector2(1180, 0)
		xrow.add_theme_constant_override("h_separation", 10)
		xrow.add_theme_constant_override("v_separation", 10)
		v.add_child(xrow)
		for c in xs:
			var cc: Dictionary = c
			var okx := Extras.seen.has("crossover_" + String(c["id"])) or GameState.unlock_all
			var bx := UI.button(String(c.get("title", "")) if okx else "Locked", func(): main.play_crossover(cc, main.show_gallery), 16, UI.PINK if okx else UI.LINE)
			bx.custom_minimum_size = Vector2(220, 70)
			bx.disabled = not okx
			xrow.add_child(bx)
		for eid in eps:
			var hid: String = eid
			var oke := Extras.seen.has("epilogue_" + hid) or GameState.unlock_all
			var be := UI.button(String(eps[eid].get("title", "")) if oke else "Locked", func(): main.play_epilogue(hid, main.show_gallery), 16, UI.hcolor(hid) if oke else UI.LINE)
			be.custom_minimum_size = Vector2(220, 70)
			be.disabled = not oke
			xrow.add_child(be)
	var back := UI.button("Back", main.show_menu, 20, UI.LINE)
	back.position = Vector2(40, 735)
	add_child(back)
	(first if first else back).call_deferred("grab_focus")


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		main.show_menu()
