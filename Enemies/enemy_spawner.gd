extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_count := 5
@export var spawn_seed := 424242
@export var spawn_areas: Array[Rect2] = [
	Rect2(620, 360, 380, 1),
	Rect2(1080, 360, 420, 1),
	Rect2(1520, 360, 520, 1),
	Rect2(-1120, 500, 420, 1),
	Rect2(320, 860, 360, 1),
	Rect2(760, 1000, 520, 1),
	Rect2(-1120, -170, 360, 1)
]
@export var edge_padding := 45.0
@export var enemy_max_life := 140
@export var enemy_attack_damage := 12
@export var enemy_move_speed := 95.0
@export var enemy_attack_cooldown := 1.0
@export var enemy_character_name := ""

const CHARACTER_NAMES := [
	"Adventurer",
	"Female",
	"Soldier",
	"Zombie"
]

func _ready() -> void:
	if _is_online_match():
		queue_free()
		return
	_spawn_enemies()


func _is_online_match() -> bool:
	if multiplayer.has_multiplayer_peer():
		return true
	var settings := get_node_or_null("/root/GameSettings")
	return settings != null and settings.get("online_mode") == true


func _spawn_enemies() -> void:
	if not enemy_scene:
		return
	if spawn_areas.is_empty():
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = spawn_seed
	var area_indices := _shuffled_indices(spawn_areas.size(), rng)
	var character_indices := _shuffled_indices(CHARACTER_NAMES.size(), rng)
	var assignments := _build_area_assignments(max(spawn_count, 0), area_indices)
	var assigned_counts := {}
	for area_index in assignments:
		assigned_counts[area_index] = int(assigned_counts.get(area_index, 0)) + 1

	var used_counts := {}
	var amount: int = assignments.size()
	for index in amount:
		var area_index: int = assignments[index]
		var area: Rect2 = spawn_areas[area_index]
		var left_x := area.position.x + edge_padding
		var right_x := area.end.x - edge_padding
		if right_x <= left_x:
			left_x = area.position.x
			right_x = area.end.x

		var slot_index := int(used_counts.get(area_index, 0))
		var slot_count := int(assigned_counts.get(area_index, 1))
		used_counts[area_index] = slot_index + 1
		var spawn_x := _slot_x(left_x, right_x, slot_index, slot_count)
		var spawn_y := _ground_y_at_x(spawn_x, area.position.y)
		var enemy := enemy_scene.instantiate() as Node2D
		enemy.name = "Enemy_%d" % index
		enemy.position = Vector2(spawn_x, spawn_y)
		enemy.set("random_character", false)
		var selected_character := enemy_character_name.strip_edges()
		if selected_character.is_empty():
			selected_character = CHARACTER_NAMES[character_indices[index % character_indices.size()]]
		enemy.set("character_name", selected_character)
		enemy.set("max_life", enemy_max_life)
		enemy.set("attack_damage", enemy_attack_damage)
		enemy.set("move_speed", enemy_move_speed)
		enemy.set("patrol_min_x", left_x)
		enemy.set("patrol_max_x", right_x)
		enemy.set("attack_cooldown", enemy_attack_cooldown)
		add_child(enemy)


func _build_area_assignments(requested_amount: int, area_indices: Array[int]) -> Array[int]:
	var assignments: Array[int] = []
	var used_counts := {}
	while assignments.size() < requested_amount:
		var added := false
		for area_index in area_indices:
			var capacity := _area_capacity(spawn_areas[area_index])
			if int(used_counts.get(area_index, 0)) >= capacity:
				continue
			assignments.append(area_index)
			used_counts[area_index] = int(used_counts.get(area_index, 0)) + 1
			added = true
			if assignments.size() >= requested_amount:
				break
		if not added:
			break
	return assignments


func _area_capacity(area: Rect2) -> int:
	var usable_width: float = max(area.size.x - edge_padding * 2.0, area.size.x)
	return max(1, int(floor(usable_width / 75.0)))


func _slot_x(left_x: float, right_x: float, slot_index: int, slot_count: int) -> float:
	if slot_count <= 1:
		return (left_x + right_x) * 0.5
	var ratio := float(slot_index + 1) / float(slot_count + 1)
	return lerp(left_x, right_x, ratio)


func _ground_y_at_x(x: float, fallback_y: float) -> float:
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(Vector2(x, fallback_y - 90.0), Vector2(x, fallback_y + 260.0))
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return fallback_y
	return (hit["position"] as Vector2).y


func _shuffled_indices(size: int, rng: RandomNumberGenerator) -> Array[int]:
	var indices: Array[int] = []
	for index in size:
		indices.append(index)

	for index in range(indices.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var value := indices[index]
		indices[index] = indices[swap_index]
		indices[swap_index] = value

	return indices
