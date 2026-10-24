extends SceneTree

const SCENE_PATH := "res://Scenes/OuterGraveyardMoonlit.tscn"
const EXPECTED_FRAMES := {
	"dying": 15,
	"falling_down": 6,
	"hurt": 12,
	"idle": 18,
	"idle_blinking": 18,
	"jump_loop": 6,
	"jump_start": 6,
	"kicking": 12,
	"run_slashing": 12,
	"run_throwing": 12,
	"running": 12,
	"slashing": 12,
	"slashing_in_air": 12,
	"sliding": 6,
	"throwing": 12,
	"throwing_in_air": 12,
	"walking": 24,
}


func _init() -> void:
	call_deferred(&"_run_validation")


func _run_validation() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	_assert(packed != null, "story scene loads")
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame

	var background := scene.get_node("CemeteryBackground")
	var background_summary: Dictionary = background.call("get_background_summary")
	_assert(int(background_summary["moon_instances"]) == 1, "exactly one moon background is active")
	_assert(int(background_summary["fog_layers"]) == 2, "two separate atmospheric fog layers exist")
	_assert(float(background_summary["sky_scroll_factor"]) == 0.0, "moon sky is screen-locked")
	_assert(float(background_summary["fog_scroll_factor"]) == 0.0, "fog does not parallax with the camera")
	_assert(float(background_summary["fog_drift_speed"]) == 0.0, "fog has no automatic sliding motion")
	_assert(int(background_summary["house_sprites"]) == 0, "houses and broken chimney are absent")

	var waterfall := scene.get_node("Level/BridgeWaterfall")
	var waterfall_summary: Dictionary = waterfall.call("get_waterfall_summary")
	_assert(int(waterfall_summary["frame_count"]) == 8, "waterfall uses all eight frames")
	_assert(is_equal_approx(float(waterfall_summary["fps"]), 8.0), "waterfall loops at 8 FPS")
	_assert(bool(waterfall_summary["loop"]), "waterfall animation loops")
	_assert(bool(waterfall_summary["positional_audio"]), "waterfall has local positional audio")
	_assert(bool(waterfall_summary["river_positional_audio"]), "river has local positional audio")
	_assert(float(waterfall_summary["waterfall_volume_db"]) <= -24.0, "waterfall ambience stays subtle")
	_assert(float(waterfall_summary["river_volume_db"]) <= -28.0, "river ambience stays subtle")
	_assert(
		waterfall.find_children("*", "CollisionObject2D", true, false).is_empty(),
		"waterfall decorations have no collision"
	)

	var asset_showcase := scene.get_node("Level/ExistingAssetShowcase")
	var asset_summary: Dictionary = asset_showcase.call("get_preview_summary")
	_assert(int(asset_summary["environment_assets"]) >= 29, "existing environment assets build the route background")
	_assert(int(asset_summary["collectable_assets"]) == 0, "collectibles are not used as background decoration")
	_assert(int(asset_summary["route_sections"]) == 5, "all five route background sections exist")
	_assert(int(asset_summary["fog_bands"]) == 5, "five subtle drifting fog bands exist")
	_assert(int(asset_summary["light_glows"]) == 5, "lanterns and fires have subtle glow")
	_assert(int(asset_summary["particle_emitters"]) == 3, "sparse drifting atmosphere exists")
	_assert(int(asset_summary["background_ground_tiles"]) == 20, "second-tileset ground fills the raised background")
	_assert(
		asset_showcase.find_children("*", "CollisionObject2D", true, false).is_empty(),
		"asset preview does not add gameplay collisions"
	)

	var encounters := scene.get_node("GraveEncounters")
	_assert(encounters.get_child_count() == 1, "only one grave encounter exists")
	var story_enemies: Array[Node] = []
	for candidate in encounters.find_children("*", "CharacterBody2D", true, false):
		if candidate.has_method("get_animation_library_summary"):
			story_enemies.append(candidate)
	_assert(story_enemies.size() == 1, "only one enemy exists in the entire story scene")

	var checked_kinds := {}
	for enemy in story_enemies:
		var kind := String(enemy.get("enemy_kind"))
		if checked_kinds.has(kind):
			continue
		checked_kinds[kind] = true
		var animation_summary: Dictionary = enemy.call("get_animation_library_summary")
		_assert(animation_summary.size() == 17, "%s has all 17 animation groups" % kind)
		for animation_name: String in EXPECTED_FRAMES:
			_assert(
				int(animation_summary.get(animation_name, -1)) == int(EXPECTED_FRAMES[animation_name]),
				"%s/%s frame count is correct" % [kind, animation_name]
			)
		_assert(
			int(enemy.call("get_runtime_loaded_frame_count")) == 18,
			"%s retains only its shared idle animation" % kind
		)
		var idle_texture := (enemy.get_node("AnimatedSprite2D") as AnimatedSprite2D).sprite_frames.get_frame_texture(&"idle", 0)
		_assert(idle_texture.get_width() <= 256, "%s animation imports are RAM-sized" % kind)
	_assert(checked_kinds.size() == 1, "only the single Zombie Villager is instantiated")

	root.size = Vector2i(1920, 1080)
	await process_frame
	var level := scene.get_node("Level")
	level.call("_refresh_coverage")
	var coverage_1080: Dictionary = level.call("get_coverage_summary")
	_assert(float(coverage_1080["surface_y"]) == 620.0, "walking surface remains fixed at y=620")
	_assert(int(coverage_1080["visual_rows"]) >= 5, "1080p has full soil coverage plus overscan")
	root.size = Vector2i(2560, 1440)
	await process_frame
	level.call("_refresh_coverage")
	var coverage_1440: Dictionary = level.call("get_coverage_summary")
	_assert(int(coverage_1440["visual_rows"]) >= 6, "1440p adds deeper complete soil rows")

	var tutorial := encounters.get_node("TutorialZombieGrave")
	var tutorial_enemy: Node = tutorial.get_child(2)
	var starting_life := int(tutorial_enemy.get("life"))
	tutorial.call("activate")
	await create_timer(1.05).timeout
	_assert(
		int(tutorial_enemy.call("get_runtime_loaded_frame_count")) == 18,
		"combat state changes do not load more textures"
	)
	_assert(
		int(tutorial_enemy.call("get_runtime_max_texture_width")) <= 256,
		"every warmed gameplay frame uses the RAM-sized import"
	)
	_assert(tutorial_enemy.visible, "grave tell reveals the emerging zombie")
	_assert(int(tutorial_enemy.get("state")) == 1, "zombie is in EMERGING state during the rise")
	tutorial_enemy.call("take_damage", 999)
	_assert(int(tutorial_enemy.get("life")) == starting_life, "emerging enemy cannot take combat damage")
	await create_timer(1.1).timeout
	_assert(int(tutorial_enemy.get("state")) in [2, 3, 4], "zombie becomes active after emergence")
	_assert(get_nodes_in_group("Enemy").size() == 1, "HUD enemy group registers the active encounter once")
	var hud := scene.get_node("PlayerHUD")
	_assert(int(hud.call("_update_enemy_count")) == 1, "HUD counter reports one active enemy")
	tutorial_enemy.call("take_damage", 999)
	await process_frame
	_assert(bool(tutorial_enemy.get("dead")), "lethal damage enters the one-shot death state")
	_assert(int(hud.call("_update_enemy_count")) == 0, "HUD counter removes dead enemy exactly once")
	await create_timer(2.1).timeout
	_assert(bool(tutorial.get("cleared")), "tutorial encounter clears without duplicate spawn")

	print(
		"Second prompt validation passed: one low-memory enemy, "
		+ "RAM-sized imports, one encounter, one moon, responsive ground, "
		+ "stationary moon atmosphere, no house layer, and 8-frame bridge waterfall"
	)
	scene.queue_free()
	await process_frame
	quit()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("Second prompt validation failed: %s" % message)
	quit(1)
