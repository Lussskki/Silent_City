extends Area2D


@onready var prompt: Label = $Prompt


func _physics_process(_delta: float) -> void:
	prompt.visible = _nearby_player() != null


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or not event.is_action_pressed("lift_descend"):
		return
	var player := _nearby_player()
	if player == null:
		return
	var hud := get_tree().current_scene.get_node_or_null("PlayerHUD")
	if hud == null or not hud.has_method("open_save_place_menu"):
		return
	# The existing guard prevents shared controller bindings from also jumping
	# or activating a power during an interaction.
	player.set_meta(&"lift_interaction_frame", Engine.get_physics_frames())
	get_viewport().set_input_as_handled()
	hud.call("open_save_place_menu")


func _nearby_player() -> CharacterBody2D:
	for body in get_overlapping_bodies():
		if body is CharacterBody2D and body.is_in_group("Player"):
			if body.get("local_player") != false:
				return body
	return null
