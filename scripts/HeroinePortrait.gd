## HeroinePortrait.gd
##
## Shows a heroine's art if it exists (ArtAssets), otherwise a flat
## placeholder figure whose clothing blocks disappear stage by stage, so the
## strip progression reads during play long before real art is in.
class_name HeroinePortrait
extends Control

var heroine_id := ""
var stage := 0
var expression := "neutral"
## "stage" for the match portrait, "vn" for dialogue sprites.
var mode := "stage"
var flash := 0.0
var _tex_rect: TextureRect


func _init(id: String = "", st: int = 0, m: String = "stage") -> void:
	heroine_id = id
	stage = st
	mode = m
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_tex_rect = TextureRect.new()
	_tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tex_rect)
	refresh()


func set_stage(n: int) -> void:
	stage = n
	refresh()


func set_expression(e: String) -> void:
	expression = e if e != "" else "neutral"
	refresh()


func refresh() -> void:
	if _tex_rect == null:
		return
	var tex: Texture2D = ArtAssets.vn(heroine_id, expression) if mode == "vn" else ArtAssets.stage(heroine_id, stage)
	_tex_rect.texture = tex
	queue_redraw()


func _process(delta: float) -> void:
	if flash > 0.0:
		flash = maxf(0.0, flash - delta)
		queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if _tex_rect and _tex_rect.texture:
		if flash > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, flash * 0.5))
		return
	var col := UI.hcolor(heroine_id)
	draw_rect(Rect2(Vector2.ZERO, size), col.darkened(0.82))
	# Soft spotlight.
	draw_circle(Vector2(w * 0.5, h * 0.42), minf(w, h) * 0.46, Color(col, 0.10))
	var skin := Color("#F2C7A8")
	var cx := w * 0.5
	var head_r := minf(w * 0.12, h * 0.085)
	var head := Vector2(cx, h * 0.17)
	var hair := col.darkened(0.35)
	# Hair behind the head.
	draw_circle(head + Vector2(0, head_r * 0.25), head_r * 1.35, hair)
	draw_rect(Rect2(cx - head_r * 1.35, head.y, head_r * 2.7, head_r * 2.2), hair)
	# Neck, body, arms, legs.
	draw_rect(Rect2(cx - head_r * 0.35, head.y + head_r * 0.8, head_r * 0.7, head_r * 0.9), skin)
	var torso := Rect2(cx - w * 0.17, h * 0.27, w * 0.34, h * 0.30)
	draw_rect(torso, skin)
	draw_rect(Rect2(torso.position.x - w * 0.07, torso.position.y + 4, w * 0.065, h * 0.34), skin)
	draw_rect(Rect2(torso.end.x + w * 0.005, torso.position.y + 4, w * 0.065, h * 0.34), skin)
	var hips := Rect2(cx - w * 0.18, h * 0.55, w * 0.36, h * 0.10)
	draw_rect(hips, skin)
	draw_rect(Rect2(cx - w * 0.16, h * 0.64, w * 0.14, h * 0.36), skin)
	draw_rect(Rect2(cx + w * 0.02, h * 0.64, w * 0.14, h * 0.36), skin)
	draw_circle(head, head_r, skin)
	# Base underwear (always on in placeholders).
	var under := Color("#2A2233")
	if GameState.sfw:
		# All-ages placeholder: a tank top and shorts stay on.
		draw_rect(Rect2(torso.position.x + 2, torso.position.y + 4, torso.size.x - 4, torso.size.y - 4), under)
		draw_rect(Rect2(hips.position.x + 2, hips.position.y, hips.size.x - 4, h * 0.14), under)
	else:
		draw_rect(Rect2(torso.position.x + 6, torso.position.y + h * 0.05, torso.size.x - 12, h * 0.07), under)
		draw_rect(Rect2(hips.position.x + 8, hips.position.y + 2, hips.size.x - 16, hips.size.y * 0.8), under)
	# Layers, outermost first: 0 = jacket, 1 = top, 2 = bottoms.
	if stage < 3:
		draw_rect(Rect2(hips.position.x - 4, hips.position.y - 4, hips.size.x + 8, h * 0.22), col.lerp(Color.BLACK, 0.25))
	if stage < 2:
		draw_rect(Rect2(torso.position.x - 2, torso.position.y, torso.size.x + 4, torso.size.y + 6), col.lightened(0.25))
	if stage < 1:
		draw_rect(Rect2(torso.position.x - w * 0.08, torso.position.y - 4, w * 0.1, h * 0.36), col)
		draw_rect(Rect2(torso.end.x - w * 0.02, torso.position.y - 4, w * 0.1, h * 0.36), col)
		draw_rect(Rect2(torso.position.x - w * 0.02, torso.position.y - 4, w * 0.08, torso.size.y + 10), col)
		draw_rect(Rect2(torso.end.x - w * 0.06, torso.position.y - 4, w * 0.08, torso.size.y + 10), col)
	# Face hint: the expression as text.
	var font := UI.BODY_FONT
	var face := {"neutral": "-  -", "happy": "^  ^", "shy": "> <", "surprised": "o  o", "teasing": "-  ^", "sad": "T  T", "angry": "\\  /"}
	draw_string(font, head + Vector2(-head_r * 0.7, 4), String(face.get(expression, "-  -")), HORIZONTAL_ALIGNMENT_CENTER, head_r * 1.4, int(maxf(10.0, head_r * 0.55)), Color("#3A2141"))
	var tag := "PLACEHOLDER  ·  %s  ·  stage %d/3" % [UI.first_name(heroine_id), stage] if mode == "stage" else "PLACEHOLDER  ·  %s  ·  %s" % [UI.first_name(heroine_id), expression]
	draw_string(font, Vector2(8, h - 10), tag, HORIZONTAL_ALIGNMENT_LEFT, w - 16, 13, Color(1, 1, 1, 0.55))
	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, flash * 0.6))
