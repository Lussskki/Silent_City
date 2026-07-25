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

const CHARACTER_NAMES := [
	"Adventurer",
	"Female",
	"Player",
	"Soldier",
	"Zombie"
]

func _ready() -> void:
	var settings := get_node_or_null("/root/GameSettings")
	if settings and settings.get("lan_mode") == true:
		return

	_spawn_enemies()


func _spawn_enemies() -> void:
	if not enemy_scene:
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = spawn_seed
	var area_indices := _shuffled_indices(spawn_areas.size(), rng)
	var character_indices := _shuffled_indices(CHARACTER_NAMES.size(), rng)

	var amount: int = min(spawn_count, spawn_areas.size(), CHARACTER_NAMES.size())
	for index in amount:
		var area: Rect2 = spawn_areas[area_indices[index]]
		var enemy := enemy_scene.instantiate() as Node2D
		enemy.name = "Enemy_%d" % index
		enemy.position = Vector2(
			rng.randf_range(area.position.x, area.end.x),
			rng.randf_range(area.position.y, area.end.y)
		)
		enemy.set("random_character", false)
		enemy.set("character_name", CHARACTER_NAMES[character_indices[index]])
		add_child(enemy)


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
