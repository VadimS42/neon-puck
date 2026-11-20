## HeroinePortrait.gd
##
## Shows a heroine's art if it exists (ArtAssets), otherwise a flat
## placeholder figure, fully dressed in her outfit colours, whose face and
## pose get more rattled at each crack stage (sweat, blush, messy hair), so
## the Cool meter reads during play long before real art is in.
class_name HeroinePortrait
extends Control

var heroine_id := ""
var stage := 0
var expression := "neutral"
## "stage" for the match portrait, "vn" for dialogue sprites.
var mode := "stage"
## Outfit to show ("" = the one picked in the Wardrobe).
var outfit := ""
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
	var tex: Texture2D = ArtAssets.vn(heroine_id, expression) if mode == "vn" else ArtAssets.stage(heroine_id, stage, outfit)
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
	# Outfit: one colour per outfit, always fully dressed.
	var oid := outfit if outfit != "" else GameState.current_outfit(heroine_id)
	var tints := {"default": col, "date": col.lerp(Color("#FFFFFF"), 0.35), "league": Color("#3FD7FF"), "neon": col.lerp(Color("#FFC94F"), 0.5)}
	var oc: Color = tints.get(oid, Color(String(GameState.outfit_def(heroine_id, oid).get("tint", col.to_html()))))
	draw_rect(Rect2(torso.position.x - 2, torso.position.y, torso.size.x + 4, torso.size.y + 6), oc.lightened(0.15))
	draw_rect(Rect2(hips.position.x - 4, hips.position.y - 4, hips.size.x + 8, h * 0.30), oc.lerp(Color.BLACK, 0.3))
	draw_rect(Rect2(torso.position.x - w * 0.08, torso.position.y - 4, w * 0.075, h * 0.30), oc)
	draw_rect(Rect2(torso.end.x + w * 0.005, torso.position.y - 4, w * 0.075, h * 0.30), oc)
	# Cracks in her cool: sweat, blush, a stray strand of hair.
	if mode == "stage" and stage >= 1:
		draw_circle(head + Vector2(head_r * 0.95, -head_r * 0.2), head_r * 0.13, Color("#9FE6FF"))
	if mode == "stage" and stage >= 2:
		draw_line(head + Vector2(-head_r * 0.6, -head_r * 1.1), head + Vector2(-head_r * 0.1, head_r * 0.3), hair, maxf(2.0, head_r * 0.12))
		draw_line(head + Vector2(head_r * 0.7, -head_r * 1.0), head + Vector2(head_r * 0.3, head_r * 0.2), hair, maxf(2.0, head_r * 0.12))
	if (mode == "stage" and stage >= 3) or expression == "shy":
		draw_circle(head + Vector2(-head_r * 0.55, head_r * 0.35), head_r * 0.2, Color(1, 0.3, 0.4, 0.5))
		draw_circle(head + Vector2(head_r * 0.55, head_r * 0.35), head_r * 0.2, Color(1, 0.3, 0.4, 0.5))
	var ex := expression
	if mode == "stage":
		ex = ["neutral", "surprised", "angry", "shy"][clampi(stage, 0, 3)]
	# Face hint: the expression as text.
	var font := UI.BODY_FONT
	var face := {"neutral": "-  -", "happy": "^  ^", "shy": "> <", "surprised": "o  o", "teasing": "-  ^", "sad": "T  T", "angry": "\\  /"}
	draw_string(font, head + Vector2(-head_r * 0.7, 4), String(face.get(ex, "-  -")), HORIZONTAL_ALIGNMENT_CENTER, head_r * 1.4, int(maxf(10.0, head_r * 0.55)), Color("#3A2141"))
	var tag := "PLACEHOLDER  ·  %s  ·  %s  ·  crack %d/3" % [UI.first_name(heroine_id), String(GameState.outfit_def(heroine_id, oid).get("name", oid)), stage] if mode == "stage" else "PLACEHOLDER  ·  %s  ·  %s" % [UI.first_name(heroine_id), ex]
	draw_string(font, Vector2(8, h - 10), tag, HORIZONTAL_ALIGNMENT_LEFT, w - 16, 13, Color(1, 1, 1, 0.55))
	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, flash * 0.6))
