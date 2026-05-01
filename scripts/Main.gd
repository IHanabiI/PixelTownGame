extends Node2D

const STREET_SCENE := preload("res://scenes/Street.tscn")
const SHOP_SCENE := preload("res://scenes/RamenShop.tscn")

var current_scene: Node
var mode := "street"
var money := 0
var served := 0
var missed := 0
var paused := false

var hud_layer: CanvasLayer
var hud_panel: PanelContainer
var hud_label: Label
var prompt_label: Label
var order_label: Label
var prompt_panel: PanelContainer
var pause_panel: PanelContainer
var summary_panel: PanelContainer
var summary_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_input_actions()
	_build_ui()
	_switch_to_street()


func _process(_delta: float) -> void:
	_update_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and mode != "day_summary":
		_set_paused(not paused)
	if mode == "day_summary" and event.is_action_pressed("interact"):
		_restart_day()


func _ensure_input_actions() -> void:
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_action("interact", [KEY_E, KEY_ENTER])
	_add_key_action("pause", [KEY_ESCAPE])


func _add_key_action(action: String, keys: Array[int]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var exists := false
		for event in InputMap.action_get_events(action):
			if event is InputEventKey and event.physical_keycode == key:
				exists = true
		if not exists:
			var input := InputEventKey.new()
			input.physical_keycode = key as Key
			InputMap.action_add_event(action, input)


func _build_ui() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(hud_layer)

	hud_panel = PanelContainer.new()
	hud_panel.position = Vector2(16, 16)
	hud_panel.size = Vector2(290, 74)
	hud_panel.add_theme_stylebox_override("panel", _make_overlay_style(Color(0.07, 0.06, 0.09, 0.74)))
	hud_layer.add_child(hud_panel)

	var hud_margin := MarginContainer.new()
	hud_margin.add_theme_constant_override("margin_left", 14)
	hud_margin.add_theme_constant_override("margin_right", 14)
	hud_margin.add_theme_constant_override("margin_top", 12)
	hud_margin.add_theme_constant_override("margin_bottom", 10)
	hud_panel.add_child(hud_margin)

	hud_label = Label.new()
	hud_label.add_theme_color_override("font_color", Color.WHITE)
	hud_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	hud_label.add_theme_constant_override("shadow_offset_x", 2)
	hud_label.add_theme_constant_override("shadow_offset_y", 2)
	hud_margin.add_child(hud_label)

	order_label = Label.new()
	order_label.position = Vector2(0, 24)
	order_label.add_theme_color_override("font_color", Color("#ffe08a"))
	order_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	order_label.add_theme_constant_override("shadow_offset_x", 2)
	order_label.add_theme_constant_override("shadow_offset_y", 2)
	hud_margin.add_child(order_label)

	prompt_panel = PanelContainer.new()
	prompt_panel.position = Vector2(250, 586)
	prompt_panel.size = Vector2(652, 40)
	prompt_panel.add_theme_stylebox_override("panel", _make_overlay_style(Color(0.07, 0.06, 0.09, 0.78)))
	hud_layer.add_child(prompt_panel)

	prompt_label = Label.new()
	prompt_label.position = Vector2(12, 8)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.size = Vector2(628, 24)
	prompt_label.add_theme_color_override("font_color", Color.WHITE)
	prompt_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	prompt_label.add_theme_constant_override("shadow_offset_x", 2)
	prompt_label.add_theme_constant_override("shadow_offset_y", 2)
	prompt_panel.add_child(prompt_label)

	pause_panel = _make_center_panel("暂停\nEsc 继续")
	pause_panel.visible = false
	hud_layer.add_child(pause_panel)

	summary_panel = _make_center_panel("")
	summary_panel.visible = false
	summary_label = summary_panel.get_node("Margin/Label")
	hud_layer.add_child(summary_panel)


func _make_center_panel(text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = Vector2(370, 205)
	panel.size = Vector2(430, 210)
	panel.add_theme_stylebox_override("panel", _make_overlay_style(Color(0.10, 0.08, 0.12, 0.92)))
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)
	var label := Label.new()
	label.name = "Label"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color.WHITE)
	margin.add_child(label)
	return panel


func _make_overlay_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_color = Color(1.0, 1.0, 1.0, 0.08)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	return style


func _switch_to_street() -> void:
	_clear_current_scene()
	mode = "street"
	current_scene = STREET_SCENE.instantiate()
	add_child(current_scene)
	move_child(hud_layer, get_child_count() - 1)
	current_scene.enter_shop_requested.connect(_switch_to_shop)


func _switch_to_shop() -> void:
	_clear_current_scene()
	mode = "shop_open"
	current_scene = SHOP_SCENE.instantiate()
	add_child(current_scene)
	move_child(hud_layer, get_child_count() - 1)
	current_scene.exit_shop_requested.connect(_switch_to_street)
	current_scene.order_served.connect(_on_order_served)
	current_scene.customer_missed.connect(_on_customer_missed)
	current_scene.day_finished.connect(_on_day_finished)


func _clear_current_scene() -> void:
	if current_scene != null:
		current_scene.queue_free()
		current_scene = null


func _on_order_served(price: int) -> void:
	money += price
	served += 1


func _on_customer_missed() -> void:
	missed += 1


func _on_day_finished(stats: Dictionary) -> void:
	mode = "day_summary"
	_set_paused(false)
	summary_label.text = "今日收工\n收入：%d / 目标：%d\n接待：%d  错过：%d\n\n按 E 再开一天" % [
		stats.revenue,
		stats.target,
		stats.served,
		stats.missed
	]
	summary_panel.visible = true


func _restart_day() -> void:
	money = 0
	served = 0
	missed = 0
	summary_panel.visible = false
	_switch_to_street()


func _set_paused(value: bool) -> void:
	paused = value
	get_tree().paused = value
	pause_panel.visible = value


func _update_ui() -> void:
	var shop_status := {}
	if current_scene != null and current_scene.has_method("get_status"):
		shop_status = current_scene.get_status()

	var time_text := ""
	if shop_status.has("time_left"):
		time_text = "  剩余 %02d:%02d" % [floori(int(shop_status.time_left) / 60.0), int(shop_status.time_left) % 60]

	hud_label.text = "金币 %d  接待 %d  错过 %d%s" % [money, served, missed, time_text]

	if mode == "shop_open" and shop_status.has("waiting"):
		order_label.text = "等待客人：%d" % shop_status.waiting
	else:
		order_label.text = "温泉街：找到夜樱拉面馆开始营业"

	if current_scene != null and current_scene.has_method("get_prompt") and not paused and mode != "day_summary":
		prompt_label.text = current_scene.get_prompt()
	else:
		prompt_label.text = ""

	prompt_panel.visible = prompt_label.text != ""
