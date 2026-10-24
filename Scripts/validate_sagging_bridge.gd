extends SceneTree

const SCENE_PATH := "res://Scenes/OuterGraveyardMoonlit.tscn"
const BANK_SURFACE_Y := 620.0
const IDLE_CENTER_Y := -4.0
const IDLE_CENTER_ROTATION := 0.006


func _init() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		_fail("could not load level scene")
		return

	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene

	var player := scene.get_node("Player") as CharacterBody2D
	var bridge := scene.get_node("Level/ShortMoonlitBridge")
	var bridge_deck := bridge.get_node("BridgeDeck") as Node2D
	var bank_plank := bridge_deck.get_node("Plank_00") as AnimatableBody2D
	var center_plank := bridge_deck.get_node("Plank_03") as AnimatableBody2D
	var bank_shape := bank_plank.get_node("CollisionShape2D").shape as RectangleShape2D
	var bank_collision_top: float = (
		bridge.position.y
		+ bridge_deck.position.y
		+ bank_plank.position.y
		- bank_shape.size.y * 0.5
	)
	if not is_equal_approx(bank_collision_top, BANK_SURFACE_Y):
		_fail("bridge bank does not align with the green ground-tile surface")
		return
	if not is_equal_approx(center_plank.position.y, IDLE_CENTER_Y):
		_fail("unloaded bridge does not begin with a shallow center sag")
		return
	if not is_equal_approx(center_plank.rotation, IDLE_CENTER_ROTATION):
		_fail("unloaded bridge does not begin with a natural bend")
		return

	player.global_position = Vector2(4576, 535)
	player.velocity = Vector2.ZERO
	await create_timer(0.55).timeout

	if center_plank.position.y < IDLE_CENTER_Y + 24.0:
		var trigger := bridge.get_node("PlayerTrigger") as Area2D
		var animator := bridge.get_node("AnimationPlayer") as AnimationPlayer
		_fail(
			"center plank did not lower when the player entered the bridge "
			+ "(player_group=%s overlaps=%d lowered=%s animation=%s plank_y=%.1f player=%s)"
			% [
				player.is_in_group("Player"),
				trigger.get_overlapping_bodies().size(),
				bridge.get("is_lowered"),
				animator.current_animation,
				center_plank.position.y,
				player.global_position
			]
		)
		return
	if not bridge_deck.position.is_equal_approx(Vector2.ZERO):
		_fail("anchored bridge ends shifted away from the ground tiles")
		return

	var lowered_y := center_plank.position.y
	player.global_position = Vector2(4100, 520)
	player.velocity = Vector2.ZERO
	await create_timer(0.65).timeout

	if not is_equal_approx(center_plank.position.y, IDLE_CENTER_Y):
		_fail("bridge did not return to its shallow idle sag after the player left")
		return
	if not is_equal_approx(center_plank.rotation, IDLE_CENTER_ROTATION):
		_fail("bridge did not return to its idle bend after the player left")
		return
	if not bridge_deck.position.is_equal_approx(Vector2.ZERO):
		_fail("whole bridge deck did not lift back to its rest position")
		return

	print(
		"Sagging bridge validation passed: bank %.1f, center plank %.1f -> %.1f"
		% [bank_collision_top, lowered_y, center_plank.position.y]
	)
	scene.queue_free()
	await process_frame
	quit()


func _fail(message: String) -> void:
	push_error("Sagging bridge validation failed: %s" % message)
	quit(1)
