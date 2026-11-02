@tool
extends Sprite2D

signal descent_finished

@export_range(1.0, 420.0) var descent_distance := 300.0
@export_range(1.0, 12.0) var travel_time := 4.0
@export_file("*.tscn") var bottom_scene := ""
@export_file("*.tscn") var top_scene := ""
@export var top_lift_path: NodePath
@export var parked_at_bottom := false
@export var cable_anchor_y := 275.0

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
	# Keep native selection bounds while the child parts render the artwork.
	self_modulate = Color(1, 1, 1, 0)
	region_enabled = false
	_build_art_layers()
	_connect_art_parts()
	_start_y = platform.position.y - (descent_distance if parked_at_bottom else 0.0)
	_offset = descent_distance if parked_at_bottom else 0.0
	arrived = parked_at_bottom
	_refresh_art_parts()
	if Engine.is_editor_hint():
		return
	process_physics_priority = -1
	platform.sync_to_physics = false
	platform.position.y = _start_y + _offset
	_interaction_prompt = Label.new()
	_interaction_prompt.text = "[F / △] Ascend" if arrived else "[F / △] Descend"
	_interaction_prompt.position = Vector2(-150, -35)
	_interaction_prompt.size = Vector2(300, 40)
	_interaction_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_interaction_prompt.add_theme_font_size_override("font_size", 28)
	_interaction_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_interaction_prompt.add_theme_constant_override("outline_size", 6)
	_interaction_prompt.z_index = 100
	_interaction_prompt.visible = false
	platform.add_child(_interaction_prompt)
	_restore_returning_player.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
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
		_interaction_prompt.text = "[F / △] Ascend" if arrived else "[F / △] Descend"
		if not (focus is LineEdit or focus is TextEdit):
			for body in get_tree().get_nodes_in_group("Player"):
				if body is CharacterBody2D and body.get("local_player") != false:
					if _is_on_platform(body):
						_interaction_prompt.visible = true
						if requested:
							body.set_meta(&"lift_interaction_frame", Engine.get_physics_frames())
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
	$Cables.queue_redraw()
	if _elapsed >= travel_time:
		arrived = descending
		descending = false
		ascending = false
		if arrived:
			descent_finished.emit()
			if not bottom_scene.is_empty():
				_enter_bottom_scene.call_deferred()
		elif not top_scene.is_empty():
			_enter_top_scene.call_deferred()


func _enter_top_scene() -> void:
	var tree := get_tree()
	var player := tree.get_first_node_in_group("LocalPlayer")
	if player == null:
		return
	tree.set_meta(&"lift_return_state", {
		"scene": top_scene,
		"lift_path": top_lift_path,
		"life": player.get("life"),
		"coin_power": player.get("coin_power"),
		"defence_power_timer": player.get("defence_power_timer"),
	})
	var loading_screen := get_node_or_null("/root/LoadingScreen")
	var error: Error
	if loading_screen != null:
		error = await loading_screen.change_scene_with_loading(top_scene)
	else:
		error = tree.change_scene_to_file(top_scene)
	if error != OK:
		tree.remove_meta(&"lift_return_state")
		push_error("Could not return from lift: %s (%s)" % [top_scene, error_string(error)])


func _restore_returning_player() -> void:
	var tree := get_tree()
	if not tree.has_meta(&"lift_return_state"):
		return
	var state: Dictionary = tree.get_meta(&"lift_return_state")
	var scene := tree.current_scene
	if scene == null or scene.scene_file_path != state.scene or scene.get_node_or_null(state.lift_path) != self:
		return
	var player := tree.get_first_node_in_group("LocalPlayer") as CharacterBody2D
	if player == null:
		return
	tree.remove_meta(&"lift_return_state")
	var deck := platform.get_node("CollisionShape2D") as CollisionShape2D
	var player_shape := player.get_node("CollisionShape2D") as CollisionShape2D
	var deck_top := deck.global_position.y + deck.shape.get_rect().position.y * deck.global_scale.y
	player.global_position = Vector2(deck.global_position.x,
		deck_top - player_shape.position.y - player_shape.shape.get_rect().end.y * player_shape.global_scale.y - 1.0)
	player.velocity = Vector2.ZERO
	player.set("life", int(state.life))
	player.set("coin_power", int(state.coin_power))
	player.set("defence_power_timer", float(state.defence_power_timer))
	player.emit_signal("life_changed", player.get("life"), player.get("max_life"))
	player.emit_signal("power_changed", player.get("coin_power"), player.get("max_coin_power"))
	player.reset_physics_interpolation()
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.reset_smoothing()


func _enter_bottom_scene() -> void:
	var tree := get_tree()
	var player := tree.get_first_node_in_group("LocalPlayer")
	if player == null:
		player = tree.get_first_node_in_group("Player")
	if player != null:
		tree.set_meta(&"cemetery_road_player_state", {
			"life": player.get("life"),
			"coin_power": player.get("coin_power"),
			"defence_power_timer": player.get("defence_power_timer"),
			"arrival_descent": true,
		})
	var loading_screen := get_node_or_null("/root/LoadingScreen")
	var error: Error
	if loading_screen != null:
		error = await loading_screen.change_scene_with_loading(bottom_scene)
	else:
		error = tree.change_scene_to_file(bottom_scene)
	if error != OK:
		tree.remove_meta(&"cemetery_road_player_state")
		push_error("Could not enter lift destination: %s (%s)" % [bottom_scene, error_string(error)])


func start_arrival_descent(player: CharacterBody2D) -> void:
	# The saved road lift stays parked for direct scene runs. A rider entering
	# from above instead finishes the journey on the same moving platform.
	_offset = 0.0
	platform.position.y = _start_y
	arrived = false
	var deck := platform.get_node("CollisionShape2D") as CollisionShape2D
	var player_shape := player.get_node("CollisionShape2D") as CollisionShape2D
	var deck_top := deck.global_position.y + deck.shape.get_rect().position.y * deck.global_scale.y
	player.global_position = Vector2(deck.global_position.x,
		deck_top - player_shape.position.y - player_shape.shape.get_rect().end.y * player_shape.global_scale.y - 1.0)
	player.velocity = Vector2.ZERO
	platform.reset_physics_interpolation()
	player.reset_physics_interpolation()
	$Cables.queue_redraw()
	start_descent()


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


func _connect_art_parts() -> void:
	var middle := floorf(texture.get_width() * 0.5)
	var left := $FixedSupports/LeftSupport as Node2D
	var right := $FixedSupports/RightSupport as Node2D
	_connect_part_draw(left, _draw_fixed_support.bind(left, Rect2(0, 0, middle, texture.get_height())))
	_connect_part_draw(right, _draw_fixed_support.bind(right, Rect2(middle, 0, texture.get_width() - middle, texture.get_height())))
	_connect_part_draw($Cables, _draw_cables)
	_connect_part_draw($StaticBody2D/PlatformArt, _draw_platform_art)
	_connect_part_draw($FixedForeground, _draw_fixed_foreground)


func _connect_part_draw(part: Node2D, callback: Callable) -> void:
	if not part.draw.is_connected(callback):
		part.draw.connect(callback)


func _refresh_art_parts() -> void:
	for part in [$FixedSupports/LeftSupport, $FixedSupports/RightSupport,
			$Cables, $StaticBody2D/PlatformArt, $FixedForeground]:
		part.queue_redraw()


func _draw_fixed_support(part: Node2D, source_rect: Rect2) -> void:
	if _frame_texture != null:
		part.draw_texture_rect_region(_frame_texture,
			Rect2(source_rect.position - texture.get_size() * 0.5, source_rect.size), source_rect)


func _draw_platform_art() -> void:
	if _deck_texture == null:
		return
	var art := $StaticBody2D/PlatformArt as Node2D
	var center := texture.get_size() * 0.5
	art.draw_texture(_deck_texture, -center)
	for bolt_x in [382.0, 766.0]:
		art.draw_texture_rect_region(texture,
			Rect2(Vector2(bolt_x, 750) - center, Vector2(56, 56)),
			Rect2(bolt_x, 750, 56, 56))


func _draw_fixed_foreground() -> void:
	if _foreground_texture != null:
		$FixedForeground.draw_texture(_foreground_texture, -texture.get_size() * 0.5)


func _draw_cables() -> void:
	if texture == null:
		return
	var center := texture.get_size() * 0.5
	var cables := $Cables as Node2D
	var deck_y := platform.position.y
	# Feed the links from fixed upper anchors down to the moving platform.
	for chain_x in [400.0, 776.0]:
		_draw_cable(cables, Vector2(chain_x, cable_anchor_y) - center, 778.0 + deck_y - cable_anchor_y,
			Rect2(chain_x, 950 + fmod(deck_y, 64.0), 25, 64))
	_draw_cable(cables, Vector2(592, cable_anchor_y) - center, 775.0 + deck_y - cable_anchor_y,
		Rect2(592, 340 + fmod(deck_y, 32.0), 18, 32))


func _draw_cable(cables: Node2D, anchor: Vector2, length: float, sample_rect: Rect2) -> void:
	var drawn := 0.0
	while drawn < length:
		var segment_height := minf(sample_rect.size.y, length - drawn)
		var source_rect := Rect2(sample_rect.position, Vector2(sample_rect.size.x, segment_height))
		cables.draw_texture_rect_region(texture,
			Rect2(anchor + Vector2(0, drawn), source_rect.size), source_rect)
		drawn += segment_height


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
	for y in range(275, source.get_height()):
		var left_vine := _vine_span(source, y, 250, 390)
		var right_vine := _vine_span(source, y, 810, 950)
		for x in range(354, 845):
			if (x >= left_vine.x and x <= left_vine.y) or (x >= right_vine.x and x <= right_vine.y):
				continue
			frame.set_pixel(x, y, Color.TRANSPARENT)
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
