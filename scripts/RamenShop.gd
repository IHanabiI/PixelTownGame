extends Node2D

signal exit_shop_requested
signal order_served(price: int)
signal customer_missed
signal day_finished(stats: Dictionary)

const VIEW_SIZE := Vector2(1152, 648)
const SHOP_INTERIOR_PATH := "res://assets/generated/sprites/ramen_shop_interior.png"
const PLAYER_COOK_PATH := "res://assets/generated/sprites/player_cook.png"
const DEFAULT_CUSTOMER_PATHS := [
	"res://assets/generated/sprites/customer_green.png",
	"res://assets/generated/sprites/customer_kimono.png",
	"res://assets/generated/sprites/customer_blue.png"
]

var menu_items: Array = []
var customer_types: Array = []
var day_config := {}
var player: Player
var customers: Array[Dictionary] = []
var spawn_timer := 0.0
var day_timer := 0.0
var served_count := 0
var missed_count := 0
var revenue := 0
var shop_closed := false

var counter_zone := Rect2(150, 470, 850, 82)
var exit_zone := Rect2(36, 502, 94, 82)
var seats: Array[Vector2] = [Vector2(176, 530), Vector2(422, 530), Vector2(674, 530), Vector2(924, 530)]


func _ready() -> void:
	_load_data()
	_create_background_sprite()
	_create_player()
	_create_camera()
	_spawn_customer()


func _process(delta: float) -> void:
	if shop_closed:
		return

	day_timer += delta
	spawn_timer += delta
	if spawn_timer >= float(day_config.get("customer_spawn_interval", 8.0)):
		spawn_timer = 0.0
		_spawn_customer()

	for customer in customers.duplicate():
		customer["wait_left"] -= delta
		var npc: PixelNpc = customer["npc"]
		npc.patience_ratio = clamp(customer["wait_left"] / customer["patience"], 0.0, 1.0)
		npc.label_text = str(customer["order"].get("name", "拉面"))
		if customer["wait_left"] <= 0.0:
			_miss_customer(customer)

	if day_timer >= float(day_config.get("day_length_seconds", 150.0)):
		_finish_day()

	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return

	if exit_zone.has_point(player.global_position):
		exit_shop_requested.emit()
	elif counter_zone.has_point(player.global_position):
		_serve_oldest_customer()


func get_prompt() -> String:
	if exit_zone.has_point(player.global_position):
		return "按 E 回到温泉街"
	if counter_zone.has_point(player.global_position) and not customers.is_empty():
		return "按 E 出餐：" + str(customers[0]["order"].get("name", "拉面"))
	if counter_zone.has_point(player.global_position):
		return "料理台已准备好，等待下一位客人"
	return "走到料理台前给客人出餐"


func get_status() -> Dictionary:
	return {
		"time_left": max(0, int(float(day_config.get("day_length_seconds", 150.0)) - day_timer)),
		"served": served_count,
		"missed": missed_count,
		"waiting": customers.size(),
		"revenue": revenue,
	}


func _load_data() -> void:
	var text := FileAccess.get_file_as_string("res://data/ramen_shop.json")
	var parsed = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		menu_items = parsed.get("menu_items", [])
		customer_types = parsed.get("customer_types", [])
		day_config = parsed.get("day_config", {})

	if menu_items.is_empty():
		menu_items = [{"name": "酱油拉面", "price": 12}]
	if customer_types.is_empty():
		customer_types = [{"name": "旅人", "patience": 28, "sprite": DEFAULT_CUSTOMER_PATHS[0]}]


func _create_background_sprite() -> void:
	var texture := _load_texture(SHOP_INTERIOR_PATH)
	if texture == null:
		return

	var booth := Sprite2D.new()
	booth.texture = texture
	booth.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	booth.centered = false
	booth.scale = Vector2(1.6, 1.6)
	booth.position = Vector2(64, 0)
	booth.z_index = -5
	add_child(booth)


func _create_player() -> void:
	player = Player.new()
	player.position = Vector2(572, 572)
	player.speed = 118.0
	player.set_visual_from_path(PLAYER_COOK_PATH, Vector2(0.44, 0.44), Vector2(0, -40))
	player.set_shadow(Vector2(22, 4))
	player.set_movement_bounds(Rect2(94, 514, 964, 74))
	add_child(player)


func _create_camera() -> void:
	var camera := Camera2D.new()
	camera.position = VIEW_SIZE * 0.5
	camera.enabled = true
	add_child(camera)
	camera.make_current()


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


func _spawn_customer() -> void:
	if customers.size() >= seats.size():
		return

	var free_seat: Vector2 = seats[customers.size()]
	var type_data: Dictionary = customer_types.pick_random()
	var order: Dictionary = menu_items.pick_random()
	var npc := PixelNpc.new()
	npc.display_name = str(type_data.get("name", "客人"))
	npc.position = free_seat
	npc.set_visual_from_path(str(type_data.get("sprite", DEFAULT_CUSTOMER_PATHS[0])), Vector2(0.40, 0.40), Vector2(0, -38))
	npc.set_shadow(Vector2(18, 4))
	add_child(npc)
	customers.append({
		"npc": npc,
		"order": order,
		"patience": float(type_data.get("patience", 30.0)),
		"wait_left": float(type_data.get("patience", 30.0))
	})


func _serve_oldest_customer() -> void:
	if customers.is_empty():
		return

	var customer: Dictionary = customers.pop_front()
	var price := int(customer["order"].get("price", 10))
	revenue += price
	served_count += 1
	order_served.emit(price)
	var npc: PixelNpc = customer["npc"]
	npc.queue_free()
	_reseat_customers()


func _miss_customer(customer: Dictionary) -> void:
	customers.erase(customer)
	missed_count += 1
	customer_missed.emit()
	var npc: PixelNpc = customer["npc"]
	npc.queue_free()
	_reseat_customers()


func _reseat_customers() -> void:
	for i in customers.size():
		var npc: PixelNpc = customers[i]["npc"]
		npc.position = seats[i]


func _finish_day() -> void:
	shop_closed = true
	for customer in customers:
		var npc: PixelNpc = customer["npc"]
		npc.queue_free()
	customers.clear()
	day_finished.emit({
		"revenue": revenue,
		"served": served_count,
		"missed": missed_count,
		"target": int(day_config.get("target_revenue", 90))
	})


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color("#2a1f23"))
	draw_rect(Rect2(0, 0, VIEW_SIZE.x, 470), Color(0.0, 0.0, 0.0, 0.10))
	draw_rect(Rect2(0, 470, VIEW_SIZE.x, 178), Color("#8a6852"))
	draw_rect(Rect2(0, 502, VIEW_SIZE.x, 146), Color("#9c775d", 0.65))
	for x in range(0, int(VIEW_SIZE.x), 52):
		draw_line(Vector2(x, 510), Vector2(x + 18, 648), Color("#715643", 0.4), 1)
	for y in range(522, int(VIEW_SIZE.y), 34):
		draw_line(Vector2(0, y), Vector2(VIEW_SIZE.x, y), Color("#7b5e49", 0.45), 1)

	draw_rect(counter_zone, Color(1.0, 0.90, 0.60, 0.10))
	draw_rect(exit_zone, Color("#d8c09c", 0.14))
	draw_string(ThemeDB.fallback_font, Vector2(42, 538), "出口", HORIZONTAL_ALIGNMENT_LEFT, 64, 16, Color("#fff7df"))
