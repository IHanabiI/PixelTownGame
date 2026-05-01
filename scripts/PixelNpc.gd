class_name PixelNpc
extends Node2D

@export var display_name := "客人"
@export var body_color := Color("#7a4d91")
@export var accent_color := Color("#ffd166")

var label_text := ""
var patience_ratio := 1.0
var shadow_size := Vector2(20, 4)

var visual_sprite: Sprite2D
var visual_offset := Vector2(0, -34)
var idle_phase := 0.0


func _ready() -> void:
	z_index = 18
	idle_phase = randf_range(0.0, TAU)


func _process(_delta: float) -> void:
	if visual_sprite != null:
		visual_sprite.position = visual_offset + Vector2(0, sin(Time.get_ticks_msec() / 340.0 + idle_phase) * 1.2)
	queue_redraw()


func set_shadow(size: Vector2) -> void:
	shadow_size = size


func set_visual_from_path(path: String, scale_amount: Vector2, offset := Vector2(0, -34)) -> void:
	var texture := _load_texture(path)
	if texture == null:
		return

	if visual_sprite == null:
		visual_sprite = Sprite2D.new()
		visual_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(visual_sprite)

	visual_sprite.texture = texture
	visual_sprite.centered = true
	visual_sprite.scale = scale_amount
	visual_offset = offset
	visual_sprite.position = visual_offset


func _load_texture(path: String) -> Texture2D:
	if FileAccess.file_exists(path + ".import"):
		var imported = ResourceLoader.load(path)
		if imported is Texture2D:
			return imported

	var image := Image.new()
	var err := image.load(path)
	if err != OK:
		push_warning("Could not load texture at " + path)
		return null
	return ImageTexture.create_from_image(image)


func _draw() -> void:
	draw_rect(Rect2(Vector2(-shadow_size.x * 0.5, 4), shadow_size), Color(0.0, 0.0, 0.0, 0.2))

	if visual_sprite == null:
		draw_rect(Rect2(Vector2(-5, -20), Vector2(10, 7)), Color("#2b2731"))
		draw_rect(Rect2(Vector2(-6, -13), Vector2(12, 13)), body_color)
		draw_rect(Rect2(Vector2(-4, -18), Vector2(8, 7)), Color("#f1c7a0"))
		draw_rect(Rect2(Vector2(-8, -8), Vector2(3, 8)), accent_color)
		draw_rect(Rect2(Vector2(5, -8), Vector2(3, 8)), accent_color)
		draw_rect(Rect2(Vector2(-5, 0), Vector2(4, 8)), Color("#262331"))
		draw_rect(Rect2(Vector2(1, 0), Vector2(4, 8)), Color("#262331"))

	if label_text != "":
		draw_rect(Rect2(Vector2(-42, -54), Vector2(84, 18)), Color(0.06, 0.05, 0.08, 0.78))
		draw_string(ThemeDB.fallback_font, Vector2(-36, -41), label_text, HORIZONTAL_ALIGNMENT_LEFT, 72, 11, Color.WHITE)
		draw_rect(Rect2(Vector2(-36, -34), Vector2(72 * patience_ratio, 3)), Color("#62d6a0"))
