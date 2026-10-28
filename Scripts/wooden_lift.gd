extends Sprite2D

signal descent_finished

@export_range(1.0, 420.0) var descent_distance := 300.0
@export_range(1.0, 12.0) var travel_time := 4.0

var descending := false
var ascending := false
var arrived := false
var _elapsed := 0.0
var _offset := 0.0
var _start_y := 0.0
var _frame_texture: ImageTexture
var _deck_texture: ImageTexture
var _foreground_texture: ImageTexture
var _activation_requested := false
var _interaction_prompt: Label

@onready var platform: AnimatableBody2D = $StaticBody2D


func _ready() -> void:
	# Keep the native sprite bounds for editor selection and dragging.
	# In play, the separated layers below replace the baked-in static deck.
	region_enabled = true
	region_rect = Rect2()
	_build_art_layers()
	if Engine.is_editor_hint():
		return
	process_physics_priority = -1
	_start_y = platform.position.y
	# Movement is applied on physics ticks before the character moves.
	platform.sync_to_physics = false
	_interaction_prompt = Label.new()
	_interaction_prompt.text = "[F] Descend"
	_interaction_prompt.position = Vector2(-150, -35)
	_interaction_prompt.size = Vector2(300, 40)
	_interaction_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_interaction_prompt.add_theme_font_size_override("font_size", 28)
	_interaction_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_interaction_prompt.add_theme_constant_override("outline_size", 6)
	_interaction_prompt.z_index = 100
	_interaction_prompt.visible = false
	platform.add_child(_interaction_prompt)
	queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or event.is_echo() or descending or ascending:
		return
	if event.is_action_pressed("lift_descend"):
		_activation_requested = true


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not descending and not ascending:
		var requested := _activation_requested or Input.is_action_just_pressed("lift_descend") or (
			not arrived and Input.is_action_just_pressed("ui_down") and not Input.is_action_pressed("run")
		)
		_activation_requested = false
		var focus := get_viewport().gui_get_focus_owner()
		_interaction_prompt.visible = false
		_interaction_prompt.text = "[F] Ascend" if arrived else "[F] Descend"
		if not (focus is LineEdit or focus is TextEdit):
			for body in get_tree().get_nodes_in_group("Player"):
				if body is CharacterBody2D and body.get("local_player") != false:
					if _is_on_platform(body):
						_interaction_prompt.visible = true
						if requested:
							if arrived:
								start_ascent()
							else:
								start_descent()
						break
		return
	_elapsed = minf(_elapsed + delta, travel_time)
	var progress := _elapsed / travel_time
	var eased := 0.5 - 0.5 * cos(PI * progress)
	_offset = descent_distance * (1.0 - eased if ascending else eased)
	platform.position.y = _start_y + _offset
	queue_redraw()
	if _elapsed >= travel_time:
		arrived = descending
		descending = false
		ascending = false
		if arrived:
			descent_finished.emit()


func start_descent() -> void:
	if descending or ascending or arrived:
		return
	descending = true
	_elapsed = 0.0
	_interaction_prompt.visible = false
	_activation_requested = false


func start_ascent() -> void:
	if descending or ascending or not arrived:
		return
	ascending = true
	_elapsed = 0.0
	_interaction_prompt.visible = false
	_activation_requested = false


func _is_on_platform(body: CharacterBody2D) -> bool:
	if not body.is_on_floor() or body.get("dead") == true:
		return false
	var query := PhysicsRayQueryParameters2D.create(
		body.global_position, body.global_position + Vector2(0.0, 48.0), body.collision_mask
	)
	query.exclude = [body.get_rid()]
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.collider == platform


func _draw() -> void:
	if texture == null:
		return
	var center := texture.get_size() * 0.5
	if _frame_texture == null or _deck_texture == null:
		draw_texture(texture, -center)
		return
	# The deck extends behind both posts instead of ending at rectangular cuts.
	draw_texture(_frame_texture, -center)
	for chain_x in [400.0, 776.0]:
		draw_texture_rect_region(texture,
			Rect2(Vector2(chain_x, 750) - center, Vector2(25, 175)),
			Rect2(chain_x, 950, 25, 175))
	draw_texture_rect_region(texture,
		Rect2(Vector2(592, 750) - center, Vector2(18, _offset + 30)),
		Rect2(592, 340, 18, 64))
	draw_texture(_deck_texture, -center + Vector2(0, _offset))
	# Keep the original bolts over the replacement chain and rope sections.
	for bolt_x in [382.0, 766.0]:
		draw_texture_rect_region(texture,
			Rect2(Vector2(bolt_x, 750 + _offset) - center, Vector2(56, 56)),
			Rect2(bolt_x, 750, 56, 56))
	draw_texture(_foreground_texture, -center)


func _build_art_layers() -> void:
	if texture == null:
		return
	# Reconstruct only the wood hidden by the baked-in deck. No source asset is changed.
	var source := texture.get_image()
	source.convert(Image.FORMAT_RGBA8)
	var frame := source.duplicate() as Image
	var deck := Image.create(source.get_width(), source.get_height(), false, Image.FORMAT_RGBA8)
	for y in range(750, 925):
		var left_vine := _vine_span(source, y, 250, 390)
		var right_vine := _vine_span(source, y, 810, 950)
		for x in range(250, 951):
			var vine := (x >= left_vine.x and x <= left_vine.y) or (x >= right_vine.x and x <= right_vine.y)
			if vine:
				continue
			if x >= 354 and x < 845:
				frame.set_pixel(x, y, Color.TRANSPARENT)
			elif y >= 775:
				frame.set_pixel(x, y, _post_pixel(source, x, y))
		if y < 775:
			continue
		var left := 280 + maxi(790 - y, 0)
		var right := 920 - maxi(790 - y, 0)
		if y >= 890:
			left = 350 if y < 900 else 370
			right = 850 if y < 900 else 830
		for x in range(left, right):
			var sample_x := x
			if x < 354:
				sample_x = 450 + (x % 40)
			elif x >= 845:
				sample_x = 700 + (x % 40)
			var color := source.get_pixel(sample_x, y)
			if y < 890 and (x < left + 5 or x >= right - 5):
				color = source.get_pixel(450, 777)
			deck.set_pixel(x, y, color)
	_frame_texture = ImageTexture.create_from_image(frame)
	_deck_texture = ImageTexture.create_from_image(deck)
	var foreground := frame.duplicate() as Image
	for y in range(source.get_height()):
		var left_vine := _vine_span(source, y, 250, 390)
		var right_vine := _vine_span(source, y, 810, 950)
		for x in range(354, 845):
			if (x >= left_vine.x and x <= left_vine.y) or (x >= right_vine.x and x <= right_vine.y):
				continue
			foreground.set_pixel(x, y, Color.TRANSPARENT)
	_foreground_texture = ImageTexture.create_from_image(foreground)
	queue_redraw()


func _vine_span(source: Image, y: int, left: int, right: int) -> Vector2i:
	var first := right + 10
	var last := left - 10
	for x in range(left, right):
		if _is_vine(source.get_pixel(x, y)):
			first = mini(first, x - 5)
			last = maxi(last, x + 5)
	return Vector2i(first, last)


func _is_vine(color: Color) -> bool:
	return color.a > 0.4 and color.g > color.r * 1.1 and color.g > color.b * 1.08


func _post_pixel(source: Image, x: int, y: int) -> Color:
	for reference_y in [740, 700, 660, 620, 580, 540, 500, 460, 420, 380]:
		var sample_y: int = reference_y - (y % 12)
		var clear_wood := true
		for near_x in range(maxi(0, x - 8), mini(source.get_width(), x + 9)):
			if _is_vine(source.get_pixel(near_x, sample_y)):
				clear_wood = false
				break
		if clear_wood:
			return source.get_pixel(x, sample_y)
	return source.get_pixel(x, 740)
