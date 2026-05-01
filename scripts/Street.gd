extends Node2D

signal enter_shop_requested

const VIEW_SIZE := Vector2(1152, 648)
const STREET_BG_PATH := "res://assets/generated/street_background_v2.png"
const PLAYER_STREET_PATH := "res://assets/generated/sprites/customer_blue.png"
const NPC_PATHS := [
	"res://assets/generated/sprites/customer_green.png",
	"res://assets/generated/sprites/customer_kimono.png",
	"res://assets/generated/sprites/customer_blue.png"
]

var player: Player
var door_zone := Rect2(92, 390, 88, 118)
var petals: Array[Dictionary] = []
var time := 0.0
var street_npcs: Array[PixelNpc] = []
var npc_lines := [
	"今晚开张的话，第一碗记得给常客留着。",
	"樱花季的时候，拉面香味会飘满整条街。",
	"去店里吧，已经有人在等夜宵了。"
]


func _ready() -> void:
	z_index = 0
	_create_background_sprite()
	_create_player()
	_create_camera()
	_create_town_npcs()
	_seed_petals()


func _process(delta: float) -> void:
	time += delta
	for petal in petals:
		petal.pos += petal.vel * delta
		petal.pos.x += sin(time * petal.sway + petal.phase) * 10.0 * delta
		if petal.pos.y > 612 or petal.pos.x > 1180:
			petal.pos = Vector2(randf_range(-100, 1100), randf_range(-100, 20))
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and door_zone.has_point(player.global_position):
		enter_shop_requested.emit()


func get_prompt() -> String:
	if door_zone.has_point(player.global_position):
		return "按 E 进入夜樱拉面"

	for i in street_npcs.size():
		if player.global_position.distance_to(street_npcs[i].global_position) < 70.0:
			return npc_lines[i]

	return "沿着街道走到左侧的拉面馆门口开门营业"


func _create_background_sprite() -> void:
	var texture := _load_texture(STREET_BG_PATH)
	if texture == null:
		return

	var bg := Sprite2D.new()
	bg.texture = texture
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.centered = false
	bg.position = Vector2.ZERO
	bg.z_index = -20
	add_child(bg)


func _create_player() -> void:
	player = Player.new()
	player.position = Vector2(620, 526)
	player.speed = 110.0
	player.set_visual_from_path(PLAYER_STREET_PATH, Vector2(0.44, 0.44), Vector2(0, -38))
	player.set_shadow(Vector2(18, 4))
	player.set_movement_bounds(Rect2(58, 474, 1028, 86))
	add_child(player)


func _create_camera() -> void:
	var camera := Camera2D.new()
	camera.position = VIEW_SIZE * 0.5
	camera.enabled = true
	add_child(camera)
	camera.make_current()


func _create_town_npcs() -> void:
	var names := ["真琴", "千夏", "凉"]
	var points := [Vector2(282, 522), Vector2(756, 520), Vector2(930, 520)]
	for i in points.size():
		var npc := PixelNpc.new()
		npc.display_name = names[i]
		npc.position = points[i]
		npc.set_visual_from_path(NPC_PATHS[i], Vector2(0.42, 0.42), Vector2(0, -38))
		npc.set_shadow(Vector2(18, 4))
		street_npcs.append(npc)
		add_child(npc)


func _seed_petals() -> void:
	for i in 90:
		petals.append({
			"pos": Vector2(randf_range(-50, 1120), randf_range(20, 620)),
			"vel": Vector2(randf_range(10, 24), randf_range(16, 38)),
			"sway": randf_range(1.2, 3.5),
			"phase": randf_range(0, TAU),
			"size": randf_range(2.0, 4.0)
		})


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
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color(0.0, 0.0, 0.0, 0.10))
	draw_rect(Rect2(0, 0, VIEW_SIZE.x, 74), Color(0.05, 0.04, 0.08, 0.26))
	draw_rect(Rect2(0, 588, VIEW_SIZE.x, 60), Color(0.05, 0.04, 0.08, 0.18))
	draw_rect(door_zone, Color(1.0, 0.88, 0.53, 0.12))
	draw_rect(Rect2(door_zone.position + Vector2(4, 4), door_zone.size - Vector2(8, 8)), Color(1.0, 0.75, 0.36, 0.08))

	for petal in petals:
		draw_rect(Rect2(petal.pos, Vector2(petal.size, petal.size * 0.65)), Color("#ffc0d3", 0.95))
