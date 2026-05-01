extends Node2D

signal exit_shop_requested
signal order_served(price: int)
signal customer_missed
signal day_finished(stats: Dictionary)

const VIEW_SIZE := Vector2(1152, 648)
const SHOP_INTERIOR_PATH := "res://assets/generated/sprites/ramen_shop_interior.png"
const PLAYER_COOK_PATH := "res://assets/generated/sprites/player_cook.png"
const ORDER_ICON_PATH := "res://assets/generated/sprites/order_icons.png"
const COIN_ICON_PATH := "res://assets/generated/sprites/coin_icons.png"
const DEFAULT_CUSTOMER_PATHS := [
	"res://assets/generated/sprites/customer_green.png",
	"res://assets/generated/sprites/customer_kimono.png",
	"res://assets/generated/sprites/customer_blue.png"
]

var menu_items: Array = []
var customer_types: Array = []
var day_config := {}
var night := 1
var street_info := {}
var special_request := {}
var player: Player
var customers: Array[Dictionary] = []
var spawn_timer := 0.0
var day_timer := 0.0
var served_count := 0
var missed_count := 0
var revenue := 0
var correct_count := 0
var wrong_count := 0
var target_revenue := 90
var spawn_interval := 9.0
var day_length := 150.0
var selected_menu_index := 0
var held_order := {}
var cooking_order := {}
var cooking_left := 0.0
var special_completed := false
var shop_closed := false
var feedback_text := ""
var feedback_timer := 0.0

var broth_zone := Rect2(150, 470, 210, 82)
var topping_zone := Rect2(414, 470, 220, 82)
var serve_zone := Rect2(690, 470, 310, 82)
var exit_zone := Rect2(36, 502, 94, 82)
var seats: Array[Vector2] = [Vector2(176, 530), Vector2(422, 530), Vector2(674, 530), Vector2(924, 530)]
var bowl_sprites: Array[Sprite2D] = []


func configure(night_value: int, info: Dictionary) -> void:
	night = night_value
	street_info = info
	special_request = info.get("special_request", {})


func _ready() -> void:
	_load_data()
	_create_background_sprite()
	_create_counter_assets()
	_create_player()
	_create_camera()
	_spawn_customer()


func _process(delta: float) -> void:
	if shop_closed:
		return

	day_timer += delta
	spawn_timer += delta
	if feedback_timer > 0.0:
		feedback_timer -= delta
		if feedback_timer <= 0.0:
			feedback_text = ""

	if cooking_left > 0.0:
		cooking_left -= delta
		if cooking_left <= 0.0:
			held_order = cooking_order.duplicate()
			cooking_order = {}
			cooking_left = 0.0

	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_spawn_customer()

	for customer in customers.duplicate():
		customer["wait_left"] -= delta
		var npc: PixelNpc = customer["npc"]
		npc.patience_ratio = clamp(customer["wait_left"] / customer["patience"], 0.0, 1.0)
		npc.label_text = str(customer["order"].get("name", "拉面"))
		if customer["wait_left"] <= 0.0:
			_miss_customer(customer)

	if day_timer >= day_length:
		_finish_day()

	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return

	if exit_zone.has_point(player.global_position):
		exit_shop_requested.emit()
	elif broth_zone.has_point(player.global_position):
		_cycle_selected_menu()
	elif topping_zone.has_point(player.global_position):
		_start_cooking()
	elif serve_zone.has_point(player.global_position):
		_serve_matching_customer()


func get_prompt() -> String:
	if exit_zone.has_point(player.global_position):
		return "按 E 回到温泉街"
	if broth_zone.has_point(player.global_position):
		return "按 E 切换菜单：" + _selected_menu_name()
	if topping_zone.has_point(player.global_position):
		if not held_order.is_empty():
			return "手上已有 " + str(held_order.get("name", "拉面")) + "，先去出餐"
		if cooking_left > 0.0:
			return "制作中：" + str(cooking_order.get("name", "拉面")) + " %.1f 秒" % cooking_left
		return "按 E 制作：" + _selected_menu_name()
	if serve_zone.has_point(player.global_position):
		if held_order.is_empty():
			return "先去料理台做一碗拉面"
		return "按 E 出餐：" + str(held_order.get("name", "拉面")) + " 给匹配顾客"
	return "汤底台选菜单，料理台制作，出餐口交给顾客"


func get_status() -> Dictionary:
	return {
		"time_left": max(0, int(day_length - day_timer)),
		"served": served_count,
		"missed": missed_count,
		"waiting": customers.size(),
		"revenue": revenue,
		"held": str(held_order.get("name", "无")) if not held_order.is_empty() else ("制作中" if cooking_left > 0.0 else "无"),
		"selected": _selected_menu_name(),
		"objective": _objective_text()
	}


func _load_data() -> void:
	var text := FileAccess.get_file_as_string("res://data/ramen_shop.json")
	var parsed = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		menu_items = parsed.get("menu_items", [])
		customer_types = parsed.get("customer_types", [])
		day_config = parsed.get("day_config", {})
		for config in parsed.get("night_configs", []):
			if int(config.get("night", 0)) == night:
				day_config = config
				break

	if menu_items.is_empty():
		menu_items = [{"name": "酱油拉面", "price": 12}]
	if customer_types.is_empty():
		customer_types = [{"name": "旅人", "patience": 28, "sprite": DEFAULT_CUSTOMER_PATHS[0]}]
	day_length = float(day_config.get("day_length_seconds", 150.0))
	spawn_interval = float(day_config.get("customer_spawn_interval", 9.0))
	target_revenue = int(day_config.get("target_revenue", 90))


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


func _create_counter_assets() -> void:
	for i in menu_items.size():
		var path := str(menu_items[i].get("sprite", ""))
		var texture := _load_texture(path)
		if texture == null:
			continue

		var bowl := Sprite2D.new()
		bowl.texture = texture
		bowl.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bowl.centered = true
		bowl.scale = Vector2(0.36, 0.36)
		bowl.position = Vector2(220 + i * 86, 452)
		bowl.z_index = 5
		bowl_sprites.append(bowl)
		add_child(bowl)

	_update_bowl_highlight()
	_add_small_prop(ORDER_ICON_PATH, Vector2(720, 422), Vector2(0.34, 0.34), 4)
	_add_small_prop(COIN_ICON_PATH, Vector2(1010, 28), Vector2(0.26, 0.26), 30)


func _add_small_prop(path: String, pos: Vector2, scale_amount: Vector2, z: int) -> void:
	var texture := _load_texture(path)
	if texture == null:
		return

	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.position = pos
	sprite.scale = scale_amount
	sprite.z_index = z
	add_child(sprite)


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
	var type_data: Dictionary = _pick_customer_type()
	var order: Dictionary = _pick_order_for_customer(type_data)
	var npc := PixelNpc.new()
	npc.display_name = str(type_data.get("name", "客人"))
	npc.position = free_seat
	npc.set_visual_from_path(str(type_data.get("sprite", DEFAULT_CUSTOMER_PATHS[0])), Vector2(0.40, 0.40), Vector2(0, -38))
	npc.set_shadow(Vector2(18, 4))
	add_child(npc)
	customers.append({
		"npc": npc,
		"type": type_data,
		"order": order,
		"patience": float(type_data.get("patience", 30.0)),
		"wait_left": float(type_data.get("patience", 30.0))
	})


func _pick_customer_type() -> Dictionary:
	if customer_types.is_empty():
		return {"id": "traveler", "name": "旅人", "patience": 30.0, "sprite": DEFAULT_CUSTOMER_PATHS[0]}

	var focus := str(street_info.get("crowd_focus", ""))
	if not special_completed and not special_request.is_empty() and randf() < 0.28:
		var special_type := _find_customer_type(str(special_request.get("customer_id", "")))
		if not special_type.is_empty():
			return special_type

	if focus != "" and randf() < 0.62:
		var focused_type := _find_customer_type(focus)
		if not focused_type.is_empty():
			return focused_type

	return customer_types.pick_random()


func _find_customer_type(id: String) -> Dictionary:
	for item in customer_types:
		if str(item.get("id", "")) == id:
			return item
	return {}


func _pick_order_for_customer(type_data: Dictionary) -> Dictionary:
	if not special_completed and not special_request.is_empty() and str(type_data.get("id", "")) == str(special_request.get("customer_id", "")):
		var special := _find_menu_item(str(special_request.get("dish_id", "")))
		if not special.is_empty():
			return special

	if randf() < 0.65:
		var favorite := _find_menu_item(str(type_data.get("favorite", "")))
		if not favorite.is_empty():
			return favorite

	return menu_items.pick_random()


func _find_menu_item(id: String) -> Dictionary:
	for item in menu_items:
		if str(item.get("id", "")) == id:
			return item
	return {}


func _cycle_selected_menu() -> void:
	if menu_items.is_empty() or cooking_left > 0.0:
		return
	selected_menu_index = (selected_menu_index + 1) % menu_items.size()
	_update_bowl_highlight()


func _start_cooking() -> void:
	if menu_items.is_empty() or cooking_left > 0.0 or not held_order.is_empty():
		return
	cooking_order = menu_items[selected_menu_index].duplicate()
	cooking_left = float(cooking_order.get("make_seconds", 2.0))


func _serve_matching_customer() -> void:
	if customers.is_empty() or held_order.is_empty():
		return

	var target_index := -1
	for i in customers.size():
		if str(customers[i]["order"].get("id", "")) == str(held_order.get("id", "")):
			target_index = i
			break

	var correct := target_index >= 0
	if target_index < 0:
		target_index = 0

	var customer: Dictionary = customers[target_index]
	customers.remove_at(target_index)
	var price := int(customer["order"].get("price", 10))
	if not correct:
		price = maxi(4, int(price / 2))
		wrong_count += 1
		_set_feedback("错餐，只收回 %d 金币" % price)
	else:
		correct_count += 1
		if _matches_special(customer, held_order):
			price += int(special_request.get("bonus", 0))
			special_completed = true
			_set_feedback("特别请求完成！+%d 金币" % int(special_request.get("bonus", 0)))
		else:
			_set_feedback("出餐正确 +%d 金币" % price)

	revenue += price
	served_count += 1
	order_served.emit(price)
	held_order = {}
	var npc: PixelNpc = customer["npc"]
	npc.queue_free()
	_reseat_customers()


func _matches_special(customer: Dictionary, order: Dictionary) -> bool:
	if special_request.is_empty() or special_completed:
		return false
	var type_data: Dictionary = customer.get("type", {})
	return str(type_data.get("id", "")) == str(special_request.get("customer_id", "")) and str(order.get("id", "")) == str(special_request.get("dish_id", ""))


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
		"target": target_revenue,
		"correct": correct_count,
		"wrong": wrong_count,
		"special_completed": special_completed
	})


func _selected_menu_name() -> String:
	if menu_items.is_empty():
		return "拉面"
	return str(menu_items[selected_menu_index].get("name", "拉面"))


func _update_bowl_highlight() -> void:
	for i in bowl_sprites.size():
		bowl_sprites[i].modulate = Color.WHITE if i == selected_menu_index else Color(0.72, 0.72, 0.72, 0.82)


func _set_feedback(text: String) -> void:
	feedback_text = text
	feedback_timer = 2.2


func _objective_text() -> String:
	var text := "目标 %d 金币" % target_revenue
	if street_info.has("hint"):
		text += "  |  " + str(street_info.hint)
	if not special_request.is_empty():
		text += "  |  请求：" + str(special_request.get("text", ""))
		if special_completed:
			text += " 完成"
	return text


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color("#2a1f23"))
	draw_rect(Rect2(0, 0, VIEW_SIZE.x, 470), Color(0.0, 0.0, 0.0, 0.10))
	draw_rect(Rect2(0, 470, VIEW_SIZE.x, 178), Color("#8a6852"))
	draw_rect(Rect2(0, 502, VIEW_SIZE.x, 146), Color("#9c775d", 0.65))
	for x in range(0, int(VIEW_SIZE.x), 52):
		draw_line(Vector2(x, 510), Vector2(x + 18, 648), Color("#715643", 0.4), 1)
	for y in range(522, int(VIEW_SIZE.y), 34):
		draw_line(Vector2(0, y), Vector2(VIEW_SIZE.x, y), Color("#7b5e49", 0.45), 1)

	draw_rect(broth_zone, Color("#8ecae6", 0.12))
	draw_rect(topping_zone, Color("#ffd166", 0.12))
	draw_rect(serve_zone, Color("#62d6a0", 0.12))
	draw_rect(exit_zone, Color("#d8c09c", 0.14))
	draw_string(ThemeDB.fallback_font, Vector2(178, 538), "汤底台", HORIZONTAL_ALIGNMENT_LEFT, 120, 16, Color("#fff7df"))
	draw_string(ThemeDB.fallback_font, Vector2(454, 538), "料理台", HORIZONTAL_ALIGNMENT_LEFT, 120, 16, Color("#fff7df"))
	draw_string(ThemeDB.fallback_font, Vector2(770, 538), "出餐口", HORIZONTAL_ALIGNMENT_LEFT, 120, 16, Color("#fff7df"))
	draw_string(ThemeDB.fallback_font, Vector2(42, 538), "出口", HORIZONTAL_ALIGNMENT_LEFT, 64, 16, Color("#fff7df"))
	draw_string(ThemeDB.fallback_font, Vector2(150, 432), "当前：" + _selected_menu_name(), HORIZONTAL_ALIGNMENT_LEFT, 230, 15, Color("#ffe08a"))
	if not held_order.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(692, 432), "手上：" + str(held_order.get("name", "拉面")), HORIZONTAL_ALIGNMENT_LEFT, 260, 15, Color("#ffffff"))
	elif cooking_left > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(414, 432), "制作中 %.1f" % cooking_left, HORIZONTAL_ALIGNMENT_LEFT, 180, 15, Color("#ffffff"))
	if feedback_text != "":
		draw_rect(Rect2(428, 384, 302, 28), Color(0.06, 0.05, 0.08, 0.76))
		draw_string(ThemeDB.fallback_font, Vector2(446, 403), feedback_text, HORIZONTAL_ALIGNMENT_LEFT, 268, 16, Color("#ffe08a"))
