class_name Player
extends CharacterBody2D

@export var speed: float = 145.0

var movement_enabled := true
var facing := Vector2.DOWN
var body_color := Color("#2f4052")
var trim_color := Color("#f6d6a8")
var movement_bounds := Rect2()
var shadow_size := Vector2(20, 4)

var visual_sprite: Sprite2D
var visual_offset := Vector2(0, -34)


func _ready() -> void:
	z_index = 20
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 7.0
	capsule.height = 20.0
	shape.shape = capsule
	shape.position = Vector2(0, 2)
	add_child(shape)


func _physics_process(_delta: float) -> void:
	if not movement_enabled:
		velocity = Vector2.ZERO
		return

	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector.length() > 0.0:
		facing = input_vector.normalized()

	velocity = input_vector.normalized() * speed
	move_and_slide()

	if movement_bounds.size != Vector2.ZERO:
		global_position.x = clampf(global_position.x, movement_bounds.position.x, movement_bounds.end.x)
		global_position.y = clampf(global_position.y, movement_bounds.position.y, movement_bounds.end.y)

	if visual_sprite != null:
		var bob := 0.0
		if velocity.length() > 1.0:
			bob = sin(Time.get_ticks_msec() / 100.0) * 2.0
		visual_sprite.position = visual_offset + Vector2(0, bob)

	queue_redraw()


func set_movement_enabled(value: bool) -> void:
	movement_enabled = value
	if not value:
		velocity = Vector2.ZERO


func set_movement_bounds(rect: Rect2) -> void:
	movement_bounds = rect


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
	draw_rect(Rect2(Vector2(-shadow_size.x * 0.5, 4), shadow_size), Color(0.0, 0.0, 0.0, 0.22))

	if visual_sprite != null:
		return

	var bob := 0.0
	if velocity.length() > 1.0:
		bob = sin(Time.get_ticks_msec() / 90.0) * 1.5

	draw_rect(Rect2(Vector2(-5, -21 + bob), Vector2(10, 8)), Color("#24242b"))
	draw_rect(Rect2(Vector2(-6, -13 + bob), Vector2(12, 13)), body_color)
	draw_rect(Rect2(Vector2(-4, -18 + bob), Vector2(8, 7)), trim_color)
	draw_rect(Rect2(Vector2(-2, -16 + bob), Vector2(2, 2)), Color("#2b1b24"))
	draw_rect(Rect2(Vector2(-8, -10 + bob), Vector2(3, 9)), Color("#24242b"))
	draw_rect(Rect2(Vector2(5, -10 + bob), Vector2(3, 9)), Color("#24242b"))
	draw_rect(Rect2(Vector2(-5, 0), Vector2(4, 9)), Color("#1c2028"))
	draw_rect(Rect2(Vector2(1, 0), Vector2(4, 9)), Color("#1c2028"))
