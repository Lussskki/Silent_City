extends Node2D

signal encounter_started(encounter: Node)
signal encounter_cleared(encounter: Node)

const ENEMY_SCENES := {
	"zombie": "res://Scenes/Enemies/ZombieVillager.tscn",
	"skeleton": "res://Scenes/Enemies/SkeletonWarrior.tscn",
}

const GRAVE_TEXTURES := [
	"res://Sprites/Graveyard/GraveyardTileset_second/PNG/Environment/Forbidden_Graveyard_2D_Platformer_Tileset_Environment - Headstone 01.png",
	"res://Sprites/Graveyard/GraveyardTileset_second/PNG/Environment/Forbidden_Graveyard_2D_Platformer_Tileset_Environment - Headstone 02.png",
	"res://Sprites/Graveyard/GraveyardTileset/png/Objects/TombStone (1).png",
	"res://Sprites/Graveyard/GraveyardTileset/png/Objects/TombStone (2).png",
]

@export var enemy_kinds := PackedStringArray(["zombie"])
@export var grave_offsets := PackedVector2Array([Vector2.ZERO])
@export var trigger_offset := Vector2(-250.0, -100.0)
@export var trigger_size := Vector2(520.0, 240.0)
@export_range(1, 4, 1) var max_concurrent := 1
@export var stagger_delay := 1.0
@export var tell_duration := 0.9

var triggered := false
var cleared := false
var next_enemy_index := 0
var active_enemy_count := 0
var spawn_delay := 0.0
var enemies: Array[Node] = []
var graves: Array[Sprite2D] = []


func _ready() -> void:
	_build_trigger()
	_build_graves_and_enemies()
	set_process(false)


func _process(delta: float) -> void:
	if not triggered or cleared:
		return
	spawn_delay = maxf(spawn_delay - delta, 0.0)
	if next_enemy_index < enemies.size() and active_enemy_count < max_concurrent and spawn_delay <= 0.0:
		_awaken_next_enemy()
	if next_enemy_index >= enemies.size() and active_enemy_count <= 0:
		cleared = true
		set_process(false)
		encounter_cleared.emit(self)


func activate() -> void:
	if triggered:
		return
	triggered = true
	spawn_delay = 0.1
	set_process(true)
	encounter_started.emit(self)


func get_encounter_summary() -> Dictionary:
	return {
		"enemy_kinds": Array(enemy_kinds),
		"grave_count": graves.size(),
		"enemy_count": enemies.size(),
		"max_concurrent": max_concurrent,
		"triggered": triggered,
		"cleared": cleared,
	}


func _build_trigger() -> void:
	var trigger := Area2D.new()
	trigger.name = "PlayerTrigger"
	trigger.position = trigger_offset
	trigger.collision_layer = 0
	trigger.collision_mask = 1
	add_child(trigger)
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = trigger_size
	collision.shape = shape
	trigger.add_child(collision)
	trigger.body_entered.connect(_on_trigger_body_entered)


func _build_graves_and_enemies() -> void:
	var count := mini(enemy_kinds.size(), grave_offsets.size())
	for index in count:
		var grave := _create_grave(index, grave_offsets[index])
		graves.append(grave)
		var kind := String(enemy_kinds[index])
		var scene_path := String(ENEMY_SCENES.get(kind, ENEMY_SCENES["zombie"]))
		var packed := load(scene_path) as PackedScene
		if packed == null:
			push_error("Missing story enemy scene: %s" % scene_path)
			continue
		var enemy := packed.instantiate()
		enemy.name = "%s_%02d" % [kind.capitalize().replace(" ", ""), index + 1]
		enemy.position = grave_offsets[index]
		add_child(enemy)
		if enemy.has_signal("defeated"):
			enemy.defeated.connect(_on_enemy_defeated)
		enemies.append(enemy)


func _create_grave(index: int, grave_offset: Vector2) -> Sprite2D:
	var texture := load(GRAVE_TEXTURES[index % GRAVE_TEXTURES.size()]) as Texture2D
	var grave := Sprite2D.new()
	grave.name = "Grave_%02d" % (index + 1)
	grave.texture = texture
	grave.position = grave_offset + Vector2(0.0, -texture.get_height() * 0.42)
	grave.scale = Vector2(0.84, 0.84)
	grave.z_index = 10
	add_child(grave)
	return grave


func _awaken_next_enemy() -> void:
	var index := next_enemy_index
	next_enemy_index += 1
	active_enemy_count += 1
	spawn_delay = stagger_delay
	_play_grave_tell(index)
	await get_tree().create_timer(tell_duration).timeout
	if index >= enemies.size():
		return
	var enemy := enemies[index]
	if is_instance_valid(enemy) and enemy.has_method("begin_emergence"):
		enemy.call("begin_emergence")


func _play_grave_tell(index: int) -> void:
	if index >= graves.size():
		return
	var grave := graves[index]
	var original_position := grave.position
	var shake := create_tween()
	for step in 6:
		var direction := -1.0 if step % 2 == 0 else 1.0
		shake.tween_property(grave, "position:x", original_position.x + direction * 4.0, tell_duration / 7.0)
	shake.tween_property(grave, "position", original_position, tell_duration / 7.0)

	var soil := Polygon2D.new()
	soil.name = "SoilTell_%02d" % (index + 1)
	soil.position = grave_offsets[index] + Vector2(0.0, -4.0)
	soil.polygon = PackedVector2Array([
		Vector2(-34.0, 0.0), Vector2(-18.0, -12.0), Vector2(0.0, -5.0),
		Vector2(18.0, -13.0), Vector2(36.0, 0.0), Vector2(0.0, 8.0),
	])
	soil.color = Color(0.30, 0.23, 0.17, 0.82)
	soil.z_index = 11
	add_child(soil)
	var puff := create_tween()
	puff.set_parallel(true)
	puff.tween_property(soil, "position:y", soil.position.y - 18.0, tell_duration)
	puff.tween_property(soil, "scale", Vector2(1.35, 0.72), tell_duration)
	puff.tween_property(soil, "modulate:a", 0.0, tell_duration)
	puff.chain().tween_callback(soil.queue_free)


func _on_trigger_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		activate()


func _on_enemy_defeated(_enemy: Node) -> void:
	active_enemy_count = maxi(active_enemy_count - 1, 0)
	if triggered:
		set_process(true)
