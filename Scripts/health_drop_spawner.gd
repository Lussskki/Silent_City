extends CanvasLayer

@export var pickup_scene: PackedScene
@export var min_drop_interval := 90.0
@export var max_drop_interval := 90.0
@export var first_drop_delay := 35.0
@export var warning_duration := 2.5
@export var warning_text := "Health heart is coming!"
@export var drop_horizontal_range := 340.0
@export var drop_height := 460.0
@export var edge_padding := 40.0

const DEFAULT_PICKUP_SCENE := preload("res://Scenes/HealthPickup.tscn")

var rng := RandomNumberGenerator.new()
var drop_timer := 0.0
var warning_timer := 0.0
var warning_active := false
var warning_panel: Panel
var warning_label: Label
var next_drop_id := 1
var active_pickups := {}
var pending_drop_id := 0
var pending_drop_position := Vector2.INF


func _ready() -> void:
	rng.randomize()
	drop_timer = first_drop_delay
	_create_warning_label()
	_restore_pending_drop()


func _process(delta: float) -> void:
	if not _health_drops_enabled():
		warning_panel.visible = false
		return
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return

	if warning_active:
		warning_timer -= delta
		if warning_timer <= 0.0:
			warning_active = false
			warning_panel.visible = false
			_spawn_pending_health_box()
			_schedule_next_drop()
		return
	drop_timer -= delta
	if drop_timer <= 0.0:
		_prepare_new_drop_warning()


func _create_warning_label() -> void:
	warning_panel = Panel.new()
	warning_panel.visible = false
	warning_panel.anchor_left = 0.5
	warning_panel.anchor_right = 0.5
	warning_panel.offset_left = -190.0
	warning_panel.offset_top = 86.0
	warning_panel.offset_right = 190.0
	warning_panel.offset_bottom = 132.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.02, 0.02, 0.02, 0.78)
	panel_style.border_color = Color(1.0, 0.82, 0.18, 0.95)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4
	warning_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(warning_panel)

	warning_label = Label.new()
	warning_label.anchor_right = 1.0
	warning_label.anchor_bottom = 1.0
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	warning_label.add_theme_font_size_override("font_size", 24)
	warning_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.18))
	warning_panel.add_child(warning_label)


func _schedule_next_drop() -> void:
	drop_timer = rng.randf_range(min_drop_interval, max_drop_interval)


func _spawn_health_box() -> void:
	var drop_position := _random_level_drop_position()
	if drop_position == Vector2.INF:
		return

	var drop_id := next_drop_id
	next_drop_id += 1
	_set_pending_drop(drop_id, drop_position)
	_spawn_health_box_at(drop_id, drop_position)
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		rpc("_spawn_remote_health_box", drop_id, drop_position)


func _prepare_new_drop_warning() -> void:
	var drop_position := _random_level_drop_position()
	if drop_position == Vector2.INF:
		_schedule_next_drop()
		return

	var drop_id := next_drop_id
	next_drop_id += 1
	_set_pending_drop(drop_id, drop_position)
	_start_warning(warning_duration)


func _start_warning(duration: float) -> void:
	warning_active = true
	warning_timer = duration
	warning_label.text = warning_text
	warning_panel.visible = true
	if multiplayer.has_multiplayer_peer():
		rpc("_show_remote_warning", warning_text)


func _spawn_pending_health_box() -> void:
	if pending_drop_position == Vector2.INF:
		_spawn_health_box()
		return
	_spawn_health_box_at(pending_drop_id, pending_drop_position)
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		rpc("_spawn_remote_health_box", pending_drop_id, pending_drop_position)


func _set_pending_drop(drop_id: int, drop_position: Vector2) -> void:
	pending_drop_id = drop_id
	pending_drop_position = drop_position
	var settings := get_node_or_null("/root/GameSettings")
	if settings and settings.has_method("set_pending_health_drop"):
		settings.set_pending_health_drop(drop_id, drop_position)


func _restore_pending_drop() -> void:
	var settings := get_node_or_null("/root/GameSettings")
	if not settings or settings.get("pending_health_drop") != true:
		return

	pending_drop_id = int(settings.get("pending_health_drop_id"))
	pending_drop_position = settings.get("pending_health_drop_position")
	if pending_drop_id <= 0 or pending_drop_position == Vector2.INF:
		return

	next_drop_id = max(next_drop_id, pending_drop_id + 1)
	_start_warning(1.0)


func _spawn_health_box_at(drop_id: int, drop_position: Vector2) -> void:
	var scene := pickup_scene if pickup_scene else DEFAULT_PICKUP_SCENE
	var pickup := scene.instantiate() as Node2D
	pickup.global_position = Vector2(drop_position.x, drop_position.y - drop_height)
	pickup.set("target_y", drop_position.y)
	pickup.set("drop_id", drop_id)
	get_tree().current_scene.add_child(pickup)
	active_pickups[drop_id] = pickup


func request_health_pickup(drop_id: int, body: Node) -> void:
	if not body or not body.is_in_group("Player"):
		return
	if body.get("local_player") == false:
		return

	var player_peer_id := int(body.get("network_player_id"))
	if multiplayer.has_multiplayer_peer():
		if multiplayer.is_server():
			_consume_health_pickup(drop_id, player_peer_id)
		else:
			rpc_id(1, "_request_health_pickup", drop_id, player_peer_id)
		return

	if body.has_method("heal") and int(body.heal(35)) > 0:
		_remove_pickup(drop_id)


@rpc("authority", "reliable")
func _show_remote_warning(text: String) -> void:
	warning_label.text = text
	warning_panel.visible = true


@rpc("authority", "reliable")
func _spawn_remote_health_box(drop_id: int, drop_position: Vector2) -> void:
	warning_panel.visible = false
	_spawn_health_box_at(drop_id, drop_position)


@rpc("any_peer", "reliable")
func _request_health_pickup(drop_id: int, player_peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	_consume_health_pickup(drop_id, player_peer_id)


func _consume_health_pickup(drop_id: int, player_peer_id: int) -> void:
	if not active_pickups.has(drop_id):
		return

	if int(multiplayer.get_unique_id()) == player_peer_id:
		_heal_local_player()
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		rpc("_consume_remote_health_pickup", drop_id, player_peer_id)
	_remove_pickup(drop_id)


@rpc("authority", "reliable")
func _consume_remote_health_pickup(drop_id: int, player_peer_id: int) -> void:
	if int(multiplayer.get_unique_id()) == player_peer_id:
		_heal_local_player()
	_remove_pickup(drop_id)


func _heal_local_player() -> void:
	var player := get_tree().get_first_node_in_group("LocalPlayer")
	if not player:
		player = get_tree().get_first_node_in_group("Player")
	if player and player.has_method("heal"):
		player.heal(35)


func _remove_pickup(drop_id: int) -> void:
	var pickup := active_pickups.get(drop_id) as Node
	active_pickups.erase(drop_id)
	_clear_pending_drop(drop_id)
	if pickup and is_instance_valid(pickup):
		pickup.queue_free()


func _clear_pending_drop(drop_id := -1) -> void:
	if drop_id != -1 and pending_drop_id != drop_id:
		return
	var settings := get_node_or_null("/root/GameSettings")
	if settings and settings.has_method("clear_pending_health_drop"):
		settings.clear_pending_health_drop(pending_drop_id)
	pending_drop_id = 0
	pending_drop_position = Vector2.INF


func _random_level_drop_position() -> Vector2:
	var enemy_spawner := get_tree().current_scene.get_node_or_null("EnemySpawner")
	if enemy_spawner:
		var areas: Array = enemy_spawner.get("spawn_areas")
		if not areas.is_empty():
			for attempt in 12:
				var area: Rect2 = areas[rng.randi_range(0, areas.size() - 1)]
				var left_x := area.position.x + edge_padding
				var right_x := area.end.x - edge_padding
				if right_x <= left_x:
					left_x = area.position.x
					right_x = area.end.x
				var x := rng.randf_range(left_x, right_x)
				var hit := _find_ground_at_x(x, area.position.y)
				if hit != Vector2.INF:
					return hit

	var player := get_tree().get_first_node_in_group("LocalPlayer") as Node2D
	if not player:
		player = get_tree().get_first_node_in_group("Player") as Node2D
	if not player:
		return Vector2.INF
	return _find_drop_position(player.global_position)


func _find_drop_position(origin: Vector2) -> Vector2:
	for attempt in 10:
		var x := origin.x + rng.randf_range(-drop_horizontal_range, drop_horizontal_range)
		var hit := _find_ground_at_x(x, origin.y)
		if hit != Vector2.INF:
			return hit
	return Vector2.INF


func _find_ground_at_x(x: float, near_y: float) -> Vector2:
	var space_state: PhysicsDirectSpaceState2D = get_tree().current_scene.get_world_2d().direct_space_state
	var excluded_rids: Array[RID] = []
	for group_name in ["Player", "Enemy"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if node is CollisionObject2D:
				excluded_rids.append((node as CollisionObject2D).get_rid())

	var from := Vector2(x, near_y - 900.0)
	var to := Vector2(x, near_y + 900.0)
	var query := PhysicsRayQueryParameters2D.create(from, to)
	query.exclude = excluded_rids
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return Vector2.INF
	return Vector2(x, (hit["position"] as Vector2).y - 34.0)


func _health_drops_enabled() -> bool:
	var settings := get_node_or_null("/root/GameSettings")
	if settings and settings.has_method("is_online_match_over") and settings.is_online_match_over():
		return false
	return true
