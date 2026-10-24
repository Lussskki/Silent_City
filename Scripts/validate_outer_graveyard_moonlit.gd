extends SceneTree

const SCENE_PATH := "res://Scenes/OuterGraveyardMoonlit.tscn"


func _init() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	_assert(packed != null, "scene loads as PackedScene")
	var scene := packed.instantiate()

	_assert(scene.name == "OuterGraveyardMoonlit", "root name is correct")
	_assert(scene.get_node_or_null("OnlineManager") == null, "online manager is not present")
	_assert(scene.get_node_or_null("EnemySpawner") == null, "enemy spawner is not present")
	_assert(scene.get_node_or_null("PlayerHUD") != null, "player HUD is present")
	_assert(scene.get_node_or_null("PlayerHUD/PauseMenu") != null, "Escape pause menu is present")
	_assert(
		scene.get_node_or_null("PlayerHUD/PauseMenu/Box/MainMenuButton") != null,
		"pause menu includes the Main Menu exit button"
	)
	_assert(scene.get_node_or_null("Level/ContinuousGraveyardGround") != null, "continuous opening ground exists")
	_assert(scene.get_node_or_null("Level/ShortMoonlitBridge") != null, "short bridge exists")
	_assert(scene.get_node_or_null("Level/FinalGraveRow") != null, "final grave row exists")
	var bridge := scene.get_node("Level/ShortMoonlitBridge")
	var bridge_deck := bridge.get_node("BridgeDeck")
	var bridge_planks := bridge_deck.find_children("Plank_*", "AnimatableBody2D", false, false)
	_assert(bridge_planks.size() == 8, "bridge contains eight animated physics planks")
	for plank in bridge_planks:
		_assert(
			plank.get_node_or_null("CollisionShape2D") != null,
			"animated bridge plank has collision"
		)
	var bridge_animator := bridge.get_node("AnimationPlayer") as AnimationPlayer
	_assert(bridge_animator.has_animation(&"sag"), "bridge animator contains the sag animation")
	var sag_animation := bridge_animator.get_animation(&"sag")
	_assert(sag_animation.length == 0.42, "bridge sag animation uses the expected timing")
	_assert(sag_animation.get_track_count() == 17, "bridge animation controls the whole deck and every plank")

	_assert(
		scene.get_node_or_null("CemeteryBackground") != null,
		"single-moon layered cemetery background exists"
	)
	_assert(
		scene.get_node_or_null("Level/BridgeWaterfall") != null,
		"bridge-only waterfall scene exists"
	)
	_assert(
		scene.get_node_or_null("GraveEncounters/TutorialZombieGrave") != null,
		"tutorial zombie grave encounter exists"
	)
	_assert(scene.get_node("GraveEncounters").get_child_count() == 1, "only one enemy encounter exists")

	var house_names := ["TeachingCottage", "PressureLonghouse", "FinalManor"]
	for house_name in house_names:
		var house := scene.get_node_or_null("Decorations/BackLayer/" + house_name) as Node2D
		_assert(house != null, "pixel house %s exists" % house_name)
		var house_sprite := house.get_node_or_null("HouseSprite") as Sprite2D
		_assert(house_sprite != null, "pixel house %s has its base sprite" % house_name)
		_assert(house_sprite.texture != null, "pixel house %s has a texture" % house_name)
		_assert(house_sprite.material is ShaderMaterial, "pixel house %s has its dark-window material" % house_name)
		_assert(house_sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "pixel house %s uses nearest filtering" % house_name)
		_assert(house.z_index == -5, "pixel house %s stays behind gameplay decorations" % house_name)
		_assert(house.get_node_or_null("Windows") != null, "pixel house %s has reusable windows" % house_name)
		_assert(house.get_node_or_null("WindowLights") != null, "pixel house %s has a light container" % house_name)

	var all_windows := scene.get_node("Decorations/BackLayer").find_children(
		"Window*", "WindowLight", true, false
	)
	var enabled_window_count := 0
	for window in all_windows:
		if window.get("light_enabled"):
			enabled_window_count += 1
	_assert(all_windows.size() == 10, "all ten house windows are independently controllable")
	_assert(enabled_window_count == 1, "only one house window is illuminated")
	_assert(
		scene.get_node("Decorations/BackLayer/FinalManor/Windows/Window01").get("light_enabled"),
		"the tall manor's small upper window is illuminated"
	)
	var selected_window := scene.get_node(
		"Decorations/BackLayer/FinalManor/Windows/Window01"
	) as WindowLight
	var selected_sprite := selected_window.get_node("WindowSprite") as Sprite2D
	selected_window.turn_off()
	_assert(not selected_window.light_enabled and not selected_sprite.visible, "turn_off hides the window overlay")
	selected_window.turn_on()
	_assert(selected_window.light_enabled and selected_sprite.visible, "turn_on restores the window overlay")
	selected_window.toggle()
	_assert(not selected_window.light_enabled and not selected_sprite.visible, "toggle changes the light state")
	selected_window.toggle()

	var stairs := scene.get_node_or_null("Decorations/FrontLayer/ManorStairs") as Sprite2D
	_assert(stairs != null, "center manor staircase exists")
	_assert(stairs.texture != null, "center manor staircase has a texture")
	_assert(stairs.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "center manor staircase uses nearest filtering")
	_assert(
		scene.get_node_or_null("Level/ManorStairsRamp") == null,
		"perspective staircase does not block horizontal player movement"
	)

	var marker_names := [
		"PlayerSpawn", "EnemySlot01", "EnemySlot02", "EnemySlot03",
		"MemoryStoryTrigger", "Checkpoint", "ExitToForgottenPath"
	]
	for marker_name in marker_names:
		_assert(
			scene.get_node_or_null("GameplayMarkers/" + marker_name) != null,
			"marker %s exists" % marker_name
		)

	var missing_textures := 0
	var sprite_count := 0
	for node in scene.find_children("*", "Sprite2D", true, false):
		var sprite := node as Sprite2D
		sprite_count += 1
		if sprite.texture == null:
			missing_textures += 1
	_assert(sprite_count >= 123, "level contains the expected tiled visuals and houses")
	_assert(missing_textures == 0, "all Sprite2D nodes have textures")

	var decoration_collisions := scene.get_node("Decorations").find_children(
		"*", "CollisionObject2D", true, false
	)
	_assert(decoration_collisions.is_empty(), "decorations are non-collidable")

	var camera := scene.get_node("Player/Camera2D") as Camera2D
	_assert(camera.zoom.is_equal_approx(Vector2(1.35, 1.35)), "camera uses the slightly closer 1.35x view")
	_assert(camera.position.is_equal_approx(Vector2(2, -100)), "camera is biased upward for widescreen framing")
	_assert(camera.limit_left == 0, "camera left bound is zero")
	_assert(camera.limit_right == 6656, "camera right bound matches level width")
	_assert(camera.limit_bottom == 900, "camera bottom bound matches viewport")

	var approach_lantern := scene.get_node(
		"Decorations/BackLayer/AwakeningLantern"
	)
	_assert(approach_lantern != null, "first street lamp has proximity flicker behavior")
	_assert(
		approach_lantern.get("glow_path") == NodePath("../AwakeningLanternGlow"),
		"proximity lamp controls its existing warm glow"
	)
	var approach_glow := scene.get_node(
		"Decorations/BackLayer/AwakeningLanternGlow"
	) as Polygon2D
	approach_lantern.call("turn_off")
	_assert(not approach_glow.visible, "lamp OFF state hides the warm glow")
	approach_lantern.call("turn_on")
	_assert(approach_glow.visible, "lamp ON state restores the warm glow")

	var imported_png_count := _count_pngs("res://Sprites/Graveyard")
	_assert(imported_png_count == 105, "all 105 source PNGs are in Sprites/Graveyard")

	scene.free()
	print("Outer Graveyard validation passed: %d sprites, %d imported PNGs" % [
		sprite_count, imported_png_count
	])
	quit()


func _count_pngs(path: String) -> int:
	var count := 0
	var directory := DirAccess.open(path)
	_assert(directory != null, "asset directory opens: %s" % path)
	directory.list_dir_begin()
	var entry := directory.get_next()
	while entry != "":
		var child_path := path.path_join(entry)
		if directory.current_is_dir():
			count += _count_pngs(child_path)
		elif entry.get_extension().to_lower() == "png":
			count += 1
		entry = directory.get_next()
	directory.list_dir_end()
	return count


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("Validation failed: %s" % message)
	quit(1)
