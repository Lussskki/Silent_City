extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var player_trigger: Area2D = $PlayerTrigger
@onready var bridge_deck: Node2D = $BridgeDeck
@onready var walking_collision: CollisionPolygon2D = $BridgeDeck/WalkingSurface/CollisionPolygon2D

var is_lowered := false
var planks: Array[Node2D] = []


func _ready() -> void:
	animation_player.process_physics_priority = -2
	process_physics_priority = -1
	for child in bridge_deck.get_children():
		if child is AnimatableBody2D:
			planks.append(child)
	_update_walking_surface()
	player_trigger.body_entered.connect(_on_player_trigger_body_entered)
	player_trigger.body_exited.connect(_on_player_trigger_body_exited)
	call_deferred(&"_sync_bridge_state")


func _physics_process(_delta: float) -> void:
	_sync_bridge_state()
	_update_walking_surface()


func _update_walking_surface() -> void:
	if planks.is_empty():
		return
	# Follow the animated sag with a gentle curve instead of individual step edges.
	var surface := PackedVector2Array()
	surface.append(Vector2(-64.0, -22.0))
	var middle_y := ((planks[3].transform * Vector2(0.0, -8.0)).y + (planks[4].transform * Vector2(0.0, -8.0)).y) * 0.5
	for index in range(17):
		var x := float(index) * 32.0
		var sag_weight := (1.0 - cos(TAU * x / 512.0)) * 0.5
		surface.append(Vector2(x, lerpf(-22.0, middle_y, sag_weight)))
	surface.append(Vector2(576.0, -22.0))
	surface.append(Vector2(surface[-1].x, 64.0))
	surface.append(Vector2(surface[0].x, 64.0))
	if walking_collision.polygon != surface:
		walking_collision.polygon = surface


func _on_player_trigger_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	call_deferred(&"_sync_bridge_state")


func _on_player_trigger_body_exited(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	call_deferred(&"_sync_bridge_state")


func _sync_bridge_state() -> void:
	for body in player_trigger.get_overlapping_bodies():
		if body.is_in_group("Player") and _is_standing_on_deck(body):
			_set_lowered(true)
			return
	_set_lowered(false)


func _is_standing_on_deck(body: Node2D) -> bool:
	var character := body as CharacterBody2D
	if character == null or not character.is_on_floor():
		return false
	var deck_x := bridge_deck.to_local(character.global_position).x
	if deck_x <= 0.0 or deck_x >= 512.0:
		return false
	# The broad trigger includes both banks; only the actual deck should carry weight.
	var query := PhysicsRayQueryParameters2D.create(
		character.global_position,
		character.global_position + Vector2(0.0, 80.0),
		character.collision_mask,
		[character.get_rid()]
	)
	var floor_hit := get_world_2d().direct_space_state.intersect_ray(query)
	return floor_hit.get("collider") == walking_collision.get_parent()


func _set_lowered(lowered: bool) -> void:
	if lowered == is_lowered:
		return
	is_lowered = lowered
	if is_lowered:
		animation_player.play(&"sag")
	else:
		animation_player.play_backwards(&"sag")
