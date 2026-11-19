## SceneViewer.gd: a reward scene (CG) or a strip stage, full screen.
## Without art it shows the scene's brief, which doubles as the artist's
## commission note.
class_name SceneViewer
extends Control

var main
var heroine_id := ""
var scene: Dictionary
var done: Callable


func _init(m, id: String, sc: Dictionary, on_done: Callable) -> void:
	main = m
	heroine_id = id
	scene = sc
	done = on_done


func _ready() -> void:
	add_child(UI.background())
	var tex: Texture2D = null
	if scene.has("stage"):
		var por := HeroinePortrait.new(heroine_id, int(scene["stage"]), "stage")
		por.position = Vector2(390, 30)
		por.size = Vector2(500, 680)
		add_child(por)
	else:
		tex = ArtAssets.scene(String(scene.get("id", "")))
		if tex:
			var tr := TextureRect.new()
			tr.texture = tex
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			add_child(UI.fill(tr))
		else:
			var col := UI.hcolor(heroine_id)
			var p := UI.panel(col.darkened(0.8), 20, col)
			p.position = Vector2(140, 80)
			p.size = Vector2(1000, 600)
			add_child(p)
			var v := VBoxContainer.new()
			v.alignment = BoxContainer.ALIGNMENT_CENTER
			v.add_theme_constant_override("separation", 18)
			p.add_child(v)
			v.add_child(UI.label("SCENE PLACEHOLDER", 20, UI.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))
			v.add_child(UI.label(String(scene.get("title", "")), 46, col, HORIZONTAL_ALIGNMENT_CENTER))
			var b := UI.wrap_label(String(scene.get("brief", "")), 24)
			b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			b.custom_minimum_size = Vector2(900, 0)
			v.add_child(b)
			v.add_child(UI.label("Art goes in res://art/scenes/%s.png (1920x1080)" % String(scene.get("id", "")), 16, UI.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	var title := UI.label(String(scene.get("title", "")), 24, UI.INK)
	title.position = Vector2(30, 740)
	if tex == null and not scene.has("stage"):
		title.visible = false
	add_child(title)
	var btn := UI.button("Continue", done, 22)
	btn.position = Vector2(1100, 730)
	add_child(btn)
	btn.call_deferred("grab_focus")


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		done.call()
