extends SceneTree

const OUTPUT_SCENE := "res://Scenes/OuterGraveyardMoonlit.tscn"
const HUD_SOURCE_SCENE := "res://Scenes/Online.tscn"
const LEVEL_WIDTH := 6656.0
const VIEW_HEIGHT := 900.0
const GROUND_TOP := 620.0
const TILE_SIZE := 128.0
const BRIDGE_BANK_OFFSET_Y := 22.0

const FIRST_TILESET := "res://Sprites/Graveyard/GraveyardTileset/png"
const SECOND_TILESET := "res://Sprites/Graveyard/GraveyardTileset_second/PNG"

const TILE_TOP_LEFT := FIRST_TILESET + "/Tiles/Tile (1).png"
const TILE_TOP := FIRST_TILESET + "/Tiles/Tile (2).png"
const TILE_TOP_RIGHT := FIRST_TILESET + "/Tiles/Tile (3).png"
const TILE_LEFT := FIRST_TILESET + "/Tiles/Tile (4).png"
const TILE_FILL := FIRST_TILESET + "/Tiles/Tile (5).png"
const TILE_RIGHT := FIRST_TILESET + "/Tiles/Tile (6).png"
const TILE_BOTTOM := FIRST_TILESET + "/Tiles/Tile (9).png"
const TILE_BOTTOM_LEFT := FIRST_TILESET + "/Tiles/Tile (12).png"
const TILE_BOTTOM_RIGHT := FIRST_TILESET + "/Tiles/Tile (13).png"

const ARROW_SIGN := FIRST_TILESET + "/Objects/ArrowSign.png"
const BUSH_A := FIRST_TILESET + "/Objects/Bush (1).png"
const BUSH_B := FIRST_TILESET + "/Objects/Bush (2).png"
const CRATE := FIRST_TILESET + "/Objects/Crate.png"
const DEAD_BUSH := FIRST_TILESET + "/Objects/DeadBush.png"
const BONES := FIRST_TILESET + "/Tiles/Bones (1).png"
const TOMBSTONE_A := FIRST_TILESET + "/Objects/TombStone (1).png"
const TOMBSTONE_B := FIRST_TILESET + "/Objects/TombStone (2).png"

const ENVIRONMENT := SECOND_TILESET + "/Environment"
const PLATFORMER := SECOND_TILESET + "/Platfromer"
const CRYPT := ENVIRONMENT + "/Forbidden_Graveyard_2D_Platformer_Tileset_Environment - Crypt.png"
const COFFIN := ENVIRONMENT + "/Forbidden_Graveyard_2D_Platformer_Tileset_Environment - Coffin.png"
const FENCE_A := ENVIRONMENT + "/Forbidden_Graveyard_2D_Platformer_Tileset_Environment - Fence 01.png"
const FENCE_B := ENVIRONMENT + "/Forbidden_Graveyard_2D_Platformer_Tileset_Environment - Fence 02.png"
const HEADSTONE_A := ENVIRONMENT + "/Forbidden_Graveyard_2D_Platformer_Tileset_Environment - Headstone 01.png"
const HEADSTONE_B := ENVIRONMENT + "/Forbidden_Graveyard_2D_Platformer_Tileset_Environment - Headstone 02.png"
const LANTERN := ENVIRONMENT + "/Forbidden_Graveyard_2D_Platformer_Tileset_Environment - Lantern.png"
const ROCK_A := ENVIRONMENT + "/Forbidden_Graveyard_2D_Platformer_Tileset_Environment - Rock 01.png"
const ROCK_B := ENVIRONMENT + "/Forbidden_Graveyard_2D_Platformer_Tileset_Environment - Rock 02.png"
const SIGNPOST := ENVIRONMENT + "/Forbidden_Graveyard_2D_Platformer_Tileset_Environment - Signpost 01.png"
const SKULL := ENVIRONMENT + "/Forbidden_Graveyard_2D_Platformer_Tileset_Environment - Skull.png"
const TREE_A := ENVIRONMENT + "/Forbidden_Graveyard_2D_Platformer_Tileset_Environment - Tree 01.png"
const TREE_B := ENVIRONMENT + "/Forbidden_Graveyard_2D_Platformer_Tileset_Environment - Tree 02.png"
const BARREL := PLATFORMER + "/Forbidden_Graveyard_2D_Platformer_Tileset_Platformer - Wooden Barrel.png"
const WOODEN_BOX := PLATFORMER + "/Forbidden_Graveyard_2D_Platformer_Tileset_Platformer - Wooden Box.png"
const BRIDGE_A := PLATFORMER + "/Forbidden_Graveyard_2D_Platformer_Tileset_Platformer - Bridge Part 01.png"
const BRIDGE_B := PLATFORMER + "/Forbidden_Graveyard_2D_Platformer_Tileset_Platformer - Bridge Part 02.png"

const MOONLIT_COTTAGE := "res://Sprites/Objects/moonlit_cottage.png"
const MOONLIT_LONGHOUSE := "res://Sprites/Objects/moonlit_longhouse.png"
const MOONLIT_MANOR := "res://Sprites/Objects/moonlit_manor.png"
const MANOR_STAIRS := "res://Resources/Levels/Stairs.png"

const PLAYER_SCRIPT := preload("res://Characters/Active_Players/Player/player.gd")
const ASH_FRAMES := preload("res://Resources/ash_golem_sprite_frames.tres")
const JUMP_SOUND := preload("res://Resources/character_voices/30_Jump_03.wav")
const RUN_SOUND := preload("res://Resources/character_voices/03_Step_grass_03.wav")
const ATTACK_SOUND := preload("res://Resources/character_voices/56_Attack_03.wav")
const HIT_SOUND := preload("res://Resources/character_voices/61_Hit_03.wav")
const LANDING_SOUND := preload("res://Resources/character_voices/45_Landing_01.wav")
const LEVEL_LAYER_SCRIPT := preload("res://Scripts/Environment/responsive_ground.gd")
const KILL_ZONE_SCRIPT := preload("res://Scripts/kill_zone.gd")
const SAGGING_BRIDGE_SCRIPT := preload("res://Scripts/sagging_bridge.gd")
const GRAVE_ENCOUNTER_SCRIPT := preload("res://Scripts/Enemies/grave_encounter.gd")
const WINDOW_LIGHT_SCRIPT := preload("res://Scripts/Environment/window_light.gd")
const WINDOW_DARKENER_SHADER := preload("res://Scripts/Environment/window_darkener.gdshader")
const PROXIMITY_LANTERN_SCRIPT := preload("res://Scripts/Environment/proximity_lantern.gd")
const CEMETERY_BACKGROUND_SCENE := preload("res://Scenes/Environment/CemeteryBackground.tscn")
const BRIDGE_WATERFALL_SCENE := preload("res://Scenes/Environment/BridgeWaterfall.tscn")


func _init() -> void:
	var root := Node2D.new()
	root.name = "OuterGraveyardMoonlit"
	root.set_meta("level_name", "Outer Graveyard")
	root.set_meta("layout_version", "Version 1 - Moonlit Procession")
	root.set_meta("campaign_next", "Forgotten Path")

	_add_background(root)
	_add_level_geometry(root)
	_add_decorations(root)
	_add_grave_encounters(root)
	_add_gameplay_markers(root)
	_add_fall_kill_zone(root)
	_add_player(root)
	_add_player_hud(root)
	_add_design_note(root)

	var packed := PackedScene.new()
	var pack_error := packed.pack(root)
	if pack_error != OK:
		push_error("Could not pack %s: %s" % [OUTPUT_SCENE, pack_error])
		root.free()
		quit(pack_error)
		return

	var save_error := ResourceSaver.save(packed, OUTPUT_SCENE)
	if save_error != OK:
		push_error("Could not save %s: %s" % [OUTPUT_SCENE, save_error])
		root.free()
		quit(save_error)
		return

	print("Created ", OUTPUT_SCENE)
	root.free()
	quit()


func _add_background(root: Node2D) -> void:
	var background_group := CEMETERY_BACKGROUND_SCENE.instantiate() as Node2D
	background_group.name = "CemeteryBackground"
	root.add_child(background_group)
	background_group.owner = root

	var darkness := CanvasModulate.new()
	darkness.name = "NeutralCharcoalNight"
	darkness.color = Color(0.58, 0.60, 0.63, 1.0)
	root.add_child(darkness)
	darkness.owner = root


func _add_level_geometry(root: Node2D) -> void:
	var level := Node2D.new()
	level.name = "Level"
	level.set_script(LEVEL_LAYER_SCRIPT)
	root.add_child(level)
	level.owner = root

	_add_platform(root, level, "ContinuousGraveyardGround", Rect2(0, GROUND_TOP, 4352, 256))
	var waterfall := BRIDGE_WATERFALL_SCENE.instantiate() as Node2D
	waterfall.name = "BridgeWaterfall"
	waterfall.position = Vector2(4608.0, 608.0)
	level.add_child(waterfall)
	waterfall.owner = root
	_add_bridge(root, level, Vector2(4352, GROUND_TOP), 8)
	_add_platform(root, level, "FinalGraveRow", Rect2(4864, GROUND_TOP, 1792, 256))


func _add_platform(root: Node2D, parent: Node2D, platform_name: String, rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.name = platform_name
	body.position = rect.position + rect.size * 0.5
	parent.add_child(body)
	body.owner = root

	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.add_child(collision)
	collision.owner = root

	var columns := int(round(rect.size.x / TILE_SIZE))
	var rows := int(round(rect.size.y / TILE_SIZE))
	for row in rows:
		for column in columns:
			var tile := Sprite2D.new()
			tile.name = "Tile_%02d_%02d" % [column, row]
			tile.texture = load(_platform_tile_path(column, row, columns, rows)) as Texture2D
			tile.position = rect.position + Vector2(
				TILE_SIZE * column + TILE_SIZE * 0.5,
				TILE_SIZE * row + TILE_SIZE * 0.5
			)
			tile.z_index = -1
			parent.add_child(tile)
			tile.owner = root


func _platform_tile_path(column: int, row: int, columns: int, rows: int) -> String:
	if row == 0:
		if column == 0:
			return TILE_TOP_LEFT
		if column == columns - 1:
			return TILE_TOP_RIGHT
		return TILE_TOP
	if column == 0:
		return TILE_LEFT
	if column == columns - 1:
		return TILE_RIGHT
	return TILE_FILL


func _add_bridge(root: Node2D, parent: Node2D, start: Vector2, piece_count: int) -> void:
	var width := 64.0 * piece_count
	var bridge := Node2D.new()
	bridge.name = "ShortMoonlitBridge"
	bridge.position = start + Vector2(0, BRIDGE_BANK_OFFSET_Y)
	bridge.set_script(SAGGING_BRIDGE_SCRIPT)
	parent.add_child(bridge)
	bridge.owner = root

	var deck := Node2D.new()
	deck.name = "BridgeDeck"
	bridge.add_child(deck)
	deck.owner = root

	var rest_positions: Array[Vector2] = []
	var sag_positions: Array[Vector2] = []
	var rest_rotations := [0.035, 0.028, 0.018, 0.006, -0.006, -0.018, -0.028, -0.035]
	var sag_rotations := [0.08, 0.065, 0.045, 0.018, -0.018, -0.045, -0.065, -0.08]
	var rest_depths := [2.0, 5.0, 9.0, 12.0, 12.0, 9.0, 5.0, 2.0]
	var sag_depths := [2.0, 12.0, 27.0, 38.0, 38.0, 27.0, 12.0, 2.0]

	for index in piece_count:
		var straight_position := Vector2(32.0 + index * 64.0, -16.0)
		var rest_position := straight_position + Vector2(0, rest_depths[index])
		var sag_position := straight_position + Vector2(0, sag_depths[index])
		rest_positions.append(rest_position)
		sag_positions.append(sag_position)

		var plank := AnimatableBody2D.new()
		plank.name = "Plank_%02d" % index
		plank.sync_to_physics = false
		plank.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		plank.position = rest_position
		plank.rotation = rest_rotations[index]
		deck.add_child(plank)
		plank.owner = root

		var collision := CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		var shape := RectangleShape2D.new()
		shape.size = Vector2(66.0, 16.0)
		collision.shape = shape
		plank.add_child(collision)
		collision.owner = root

		var bridge_piece := Sprite2D.new()
		bridge_piece.name = "BridgePiece"
		bridge_piece.texture = load(BRIDGE_A if index % 2 == 0 else BRIDGE_B) as Texture2D
		bridge_piece.scale = Vector2(1.1, 1.0)
		bridge_piece.z_index = 1
		plank.add_child(bridge_piece)
		bridge_piece.owner = root

	var trigger := Area2D.new()
	trigger.name = "PlayerTrigger"
	trigger.position = Vector2(width * 0.5, -10.0)
	trigger.collision_layer = 0
	trigger.collision_mask = 1
	bridge.add_child(trigger)
	trigger.owner = root

	var trigger_collision := CollisionShape2D.new()
	trigger_collision.name = "CollisionShape2D"
	var trigger_shape := RectangleShape2D.new()
	trigger_shape.size = Vector2(width - 24.0, 220.0)
	trigger_collision.shape = trigger_shape
	trigger.add_child(trigger_collision)
	trigger_collision.owner = root

	var animation_player := AnimationPlayer.new()
	animation_player.name = "AnimationPlayer"
	animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	bridge.add_child(animation_player)
	animation_player.owner = root

	var library := AnimationLibrary.new()
	var reset_animation := _create_bridge_animation(
		piece_count, rest_positions, rest_positions,
		PackedFloat32Array(rest_rotations), PackedFloat32Array(rest_rotations),
		0.0, 0.0
	)
	var sag_animation := _create_bridge_animation(
		piece_count, rest_positions, sag_positions,
		PackedFloat32Array(rest_rotations), PackedFloat32Array(sag_rotations),
		0.42, 0.0
	)
	library.add_animation(&"RESET", reset_animation)
	library.add_animation(&"sag", sag_animation)
	animation_player.add_animation_library(&"", library)


func _create_bridge_animation(
	piece_count: int,
	rest_positions: Array[Vector2],
	target_positions: Array[Vector2],
	rest_rotations: PackedFloat32Array,
	target_rotations: PackedFloat32Array,
	duration: float,
	deck_drop: float
) -> Animation:
	var animation := Animation.new()
	animation.length = duration
	var deck_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(deck_track, NodePath("BridgeDeck:position"))
	animation.track_set_interpolation_type(deck_track, Animation.INTERPOLATION_CUBIC)
	animation.track_insert_key(deck_track, 0.0, Vector2.ZERO)
	if duration > 0.0 and deck_drop > 0.0:
		animation.track_insert_key(
			deck_track,
			duration * 0.72,
			Vector2(0, deck_drop + 3.0),
			0.7
		)
		animation.track_insert_key(
			deck_track,
			duration,
			Vector2(0, deck_drop),
			0.55
		)
	for index in piece_count:
		var plank_path := "BridgeDeck/Plank_%02d" % index
		var position_track := animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(position_track, NodePath(plank_path + ":position"))
		animation.track_set_interpolation_type(position_track, Animation.INTERPOLATION_CUBIC)
		animation.track_insert_key(position_track, 0.0, rest_positions[index])
		if duration > 0.0:
			animation.track_insert_key(position_track, duration, target_positions[index], 0.55)

		var rotation_track := animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(rotation_track, NodePath(plank_path + ":rotation"))
		animation.track_set_interpolation_type(rotation_track, Animation.INTERPOLATION_CUBIC)
		animation.track_insert_key(rotation_track, 0.0, rest_rotations[index])
		if duration > 0.0:
			animation.track_insert_key(rotation_track, duration, target_rotations[index], 0.55)
	return animation


func _add_decorations(root: Node2D) -> void:
	var decorations := Node2D.new()
	decorations.name = "Decorations"
	root.add_child(decorations)
	decorations.owner = root

	var back := Node2D.new()
	back.name = "BackLayer"
	decorations.add_child(back)
	back.owner = root

	var front := Node2D.new()
	front.name = "FrontLayer"
	decorations.add_child(front)
	front.owner = root

	# Awakening ground: tombstones, bones, dead growth, and the first guiding lantern.
	_add_bottom_sprite(root, back, "AwakeningTree", TREE_A, 110, GROUND_TOP, Vector2(0.9, 0.9), -4)
	_add_bottom_sprite(root, front, "AwakeningTombstone", TOMBSTONE_A, 350, GROUND_TOP, Vector2(1.5, 1.5))
	_add_bottom_sprite(root, front, "AwakeningBones", BONES, 570, GROUND_TOP + 52, Vector2(0.85, 0.85))
	_add_bottom_sprite(root, front, "AwakeningDeadBush", DEAD_BUSH, 760, GROUND_TOP, Vector2(0.85, 0.85))
	_add_lantern(root, back, "AwakeningLantern", 940, GROUND_TOP)

	# Teaching stretch: a low-density road that clearly establishes the forward route.
	_add_bottom_sprite(root, back, "TeachingFenceA", FENCE_A, 1170, GROUND_TOP, Vector2(1.05, 1.05), -2)
	_add_bottom_sprite(root, back, "TeachingFenceB", FENCE_B, 1298, GROUND_TOP, Vector2(1.05, 1.05), -2)
	_add_bottom_sprite(root, front, "TeachingArrow", ARROW_SIGN, 1530, GROUND_TOP, Vector2(1.1, 1.1))
	_add_bottom_sprite(root, front, "TeachingRockA", ROCK_A, 1770, GROUND_TOP, Vector2(1.15, 1.15))
	_add_house_sprite(root, back, "TeachingCottage", MOONLIT_COTTAGE, 794, 0.23, 637.655)
	_add_bottom_sprite(root, front, "TeachingBush", BUSH_A, 1980, GROUND_TOP, Vector2(0.8, 0.8))
	_add_bottom_sprite(root, front, "TeachingCrate", CRATE, 2210, GROUND_TOP, Vector2(0.9, 0.9))

	# First pressure zone: two readable future encounter slots with recovery space.
	_add_lantern(root, back, "PressureLantern", 2490, GROUND_TOP)
	_add_bottom_sprite(root, front, "PressureHeadstoneA", HEADSTONE_A, 2640, GROUND_TOP, Vector2(0.9, 0.9))
	_add_bottom_sprite(root, front, "PressureFence", FENCE_B, 2880, GROUND_TOP, Vector2(1.0, 1.0), -2)
	_add_house_sprite(root, back, "PressureLonghouse", MOONLIT_LONGHOUSE, 1770, 0.21, 627.52)
	_add_bottom_sprite(root, front, "PressureBarrel", BARREL, 3100, GROUND_TOP, Vector2(0.95, 0.95))
	_add_bottom_sprite(root, front, "PressureHeadstoneB", HEADSTONE_B, 3340, GROUND_TOP, Vector2(0.9, 0.9))

	# Crypt landmark: the first memory/story trigger is framed by warm light.
	_add_bottom_sprite(root, back, "CryptTree", TREE_B, 3500, GROUND_TOP, Vector2(0.9, 0.9), -4)
	_add_bottom_sprite(root, back, "MemoryCrypt", CRYPT, 3840, GROUND_TOP, Vector2(0.88, 0.88), -2)
	_add_bottom_sprite(root, front, "CryptSkull", SKULL, 4080, GROUND_TOP + 48, Vector2(0.85, 0.85))
	_add_lantern(root, back, "CheckpointLantern", 4260, GROUND_TOP)

	# Short bridge: lanterns expose both landing edges before the player commits.
	_add_lantern(root, back, "BridgeEntryLantern", 4320, GROUND_TOP)
	_add_lantern(root, back, "BridgeExitLantern", 4900, GROUND_TOP)

	# Final grave row: denser silhouettes lead to the clearly marked exit.
	_add_bottom_sprite(root, front, "FinalCoffin", COFFIN, 5180, GROUND_TOP, Vector2(0.9, 0.9))
	_add_bottom_sprite(root, front, "FinalTombstoneA", TOMBSTONE_B, 5410, GROUND_TOP, Vector2(1.65, 1.65))
	_add_house_sprite(root, back, "FinalManor", MOONLIT_MANOR, 331, 0.22, 547.0)
	_add_manor_stairs(root, front)
	_add_bottom_sprite(root, front, "FinalRock", ROCK_B, 5600, GROUND_TOP, Vector2(1.1, 1.1))
	_add_bottom_sprite(root, front, "FinalWoodenBox", WOODEN_BOX, 5790, GROUND_TOP, Vector2(0.95, 0.95))
	_add_bottom_sprite(root, back, "FinalTree", TREE_A, 6020, GROUND_TOP, Vector2(-0.95, 0.95), -4)
	_add_bottom_sprite(root, front, "ExitSignpost", SIGNPOST, 6250, GROUND_TOP, Vector2(0.95, 0.95))
	_add_lantern(root, back, "ExitLantern", 6450, GROUND_TOP)


func _add_grave_encounters(root: Node2D) -> void:
	var encounters := Node2D.new()
	encounters.name = "GraveEncounters"
	root.add_child(encounters)
	encounters.owner = root

	_add_encounter(
		root,
		encounters,
		"TutorialZombieGrave",
		Vector2(2580.0, GROUND_TOP),
		PackedStringArray(["zombie"]),
		PackedVector2Array([Vector2.ZERO]),
		Vector2(-300.0, -110.0),
		Vector2(520.0, 250.0),
		1,
		1.0
	)


func _add_encounter(
	root: Node2D,
	parent: Node2D,
	encounter_name: String,
	position: Vector2,
	enemy_kinds: PackedStringArray,
	grave_offsets: PackedVector2Array,
	trigger_offset: Vector2,
	trigger_size: Vector2,
	max_concurrent: int,
	stagger_delay: float
) -> void:
	var encounter := Node2D.new()
	encounter.name = encounter_name
	encounter.position = position
	encounter.set_script(GRAVE_ENCOUNTER_SCRIPT)
	encounter.set("enemy_kinds", enemy_kinds)
	encounter.set("grave_offsets", grave_offsets)
	encounter.set("trigger_offset", trigger_offset)
	encounter.set("trigger_size", trigger_size)
	encounter.set("max_concurrent", max_concurrent)
	encounter.set("stagger_delay", stagger_delay)
	parent.add_child(encounter)
	encounter.owner = root


func _add_bottom_sprite(
	root: Node2D,
	parent: Node2D,
	sprite_name: String,
	path: String,
	x: float,
	bottom_y: float,
	scale_value: Vector2 = Vector2.ONE,
	z: int = 0
) -> void:
	var texture := load(path) as Texture2D
	var sprite := Sprite2D.new()
	sprite.name = sprite_name
	sprite.texture = texture
	sprite.scale = scale_value
	sprite.position = Vector2(x, bottom_y - texture.get_height() * absf(scale_value.y) * 0.5)
	sprite.z_index = z
	parent.add_child(sprite)
	sprite.owner = root


func _add_house_sprite(
	root: Node2D,
	parent: Node2D,
	sprite_name: String,
	path: String,
	x: float,
	scale_value: float,
	bottom_y: float = GROUND_TOP
) -> void:
	var texture := load(path) as Texture2D
	var house := Node2D.new()
	house.name = sprite_name
	house.scale = Vector2(scale_value, scale_value)
	house.position = Vector2(x, bottom_y - texture.get_height() * scale_value * 0.5)
	house.modulate = Color(0.78, 0.82, 0.92, 0.96)
	house.z_index = -5
	parent.add_child(house)
	house.owner = root

	var window_regions := _get_house_window_regions(path)
	var dark_material := ShaderMaterial.new()
	dark_material.shader = WINDOW_DARKENER_SHADER
	dark_material.resource_local_to_scene = true
	dark_material.set_shader_parameter("window_count", window_regions.size())
	var texture_size := Vector2(texture.get_width(), texture.get_height())
	for index in window_regions.size():
		var region := window_regions[index]
		var uv_rect := Vector4(
			region.position.x / texture_size.x,
			region.position.y / texture_size.y,
			region.size.x / texture_size.x,
			region.size.y / texture_size.y
		)
		dark_material.set_shader_parameter("window_rect_%d" % (index + 1), uv_rect)

	var house_sprite := Sprite2D.new()
	house_sprite.name = "HouseSprite"
	house_sprite.texture = texture
	house_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	house_sprite.material = dark_material
	house.add_child(house_sprite)
	house_sprite.owner = root

	var windows := Node2D.new()
	windows.name = "Windows"
	house.add_child(windows)
	windows.owner = root

	for index in window_regions.size():
		var enabled := path == MOONLIT_MANOR and index == 0
		var controller := Node2D.new()
		controller.name = "Window%02d" % (index + 1)
		controller.set_script(WINDOW_LIGHT_SCRIPT)
		controller.set("light_enabled", enabled)
		windows.add_child(controller)
		controller.owner = root

		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = window_regions[index]
		var overlay := Sprite2D.new()
		overlay.name = "WindowSprite"
		overlay.texture = atlas
		overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		overlay.position = window_regions[index].get_center() - texture_size * 0.5
		overlay.visible = enabled
		controller.add_child(overlay)
		overlay.owner = root

	var window_lights := Node2D.new()
	window_lights.name = "WindowLights"
	house.add_child(window_lights)
	window_lights.owner = root


func _get_house_window_regions(path: String) -> Array[Rect2]:
	match path:
		MOONLIT_COTTAGE:
			return [
				Rect2(750, 440, 140, 160),
				Rect2(400, 765, 120, 155),
			]
		MOONLIT_LONGHOUSE:
			return [
				Rect2(1125, 435, 125, 130),
				Rect2(395, 725, 120, 135),
				Rect2(700, 725, 120, 140),
			]
		MOONLIT_MANOR:
			return [
				Rect2(390, 140, 80, 105),
				Rect2(375, 295, 95, 150),
				Rect2(655, 405, 120, 150),
				Rect2(605, 835, 105, 150),
				Rect2(865, 835, 120, 160),
			]
	return []


func _add_manor_stairs(root: Node2D, front: Node2D) -> void:
	var stairs := Sprite2D.new()
	stairs.name = "ManorStairs"
	stairs.texture = load(MANOR_STAIRS) as Texture2D
	stairs.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stairs.position = Vector2(282.0, 556.0)
	stairs.scale = Vector2(0.15, 0.15)
	stairs.z_index = 2
	front.add_child(stairs)
	stairs.owner = root


func _add_lantern(root: Node2D, parent: Node2D, lantern_name: String, x: float, bottom_y: float) -> void:
	var glow := Polygon2D.new()
	glow.name = lantern_name + "Glow"
	glow.position = Vector2(x, bottom_y - 92.16)
	glow.polygon = PackedVector2Array([
		Vector2(-20, -46), Vector2(20, -46),
		Vector2(96, 92), Vector2(-96, 92)
	])
	glow.color = Color(1.0, 0.73, 0.24, 0.10)
	glow.z_index = -2
	parent.add_child(glow)
	glow.owner = root
	_add_bottom_sprite(root, parent, lantern_name, LANTERN, x, bottom_y, Vector2(0.72, 0.72), -1)
	if lantern_name == "AwakeningLantern":
		var lantern := parent.get_node(lantern_name) as Sprite2D
		lantern.set_script(PROXIMITY_LANTERN_SCRIPT)
		lantern.set("glow_path", NodePath("../" + lantern_name + "Glow"))


func _add_gameplay_markers(root: Node2D) -> void:
	var markers := Node2D.new()
	markers.name = "GameplayMarkers"
	root.add_child(markers)
	markers.owner = root

	_add_marker(root, markers, "PlayerSpawn", Vector2(280, GROUND_TOP - 80), "awakening spawn")
	_add_marker(root, markers, "SectionAwakeningEnd", Vector2(1024, GROUND_TOP - 40), "awakening to teaching")
	_add_marker(root, markers, "SectionTeachingEnd", Vector2(2432, GROUND_TOP - 40), "teaching to first pressure")
	_add_marker(root, markers, "SectionPressureEnd", Vector2(3456, GROUND_TOP - 40), "pressure to crypt landmark")
	_add_marker(root, markers, "EnemySlot01", Vector2(2720, GROUND_TOP - 42), "future skeleton encounter")
	_add_marker(root, markers, "EnemySlot02", Vector2(3260, GROUND_TOP - 42), "future skeleton encounter")
	_add_marker(root, markers, "MemoryStoryTrigger", Vector2(3840, GROUND_TOP - 80), "first memory reveal")
	_add_marker(root, markers, "Checkpoint", Vector2(4230, GROUND_TOP - 64), "safe checkpoint before bridge")
	_add_marker(root, markers, "EnemySlot03", Vector2(5570, GROUND_TOP - 42), "harder future skeleton encounter")
	_add_marker(root, markers, "ExitToForgottenPath", Vector2(6460, GROUND_TOP - 64), "level 2 transition")

	_add_trigger(root, markers, "MemoryTriggerArea", Vector2(3840, GROUND_TOP - 100), Vector2(260, 240), "story")
	_add_trigger(root, markers, "CheckpointArea", Vector2(4230, GROUND_TOP - 100), Vector2(180, 240), "checkpoint")
	_add_trigger(root, markers, "ExitArea", Vector2(6500, GROUND_TOP - 120), Vector2(180, 280), "exit")


func _add_marker(root: Node2D, parent: Node2D, marker_name: String, position: Vector2, purpose: String) -> void:
	var marker := Marker2D.new()
	marker.name = marker_name
	marker.position = position
	marker.set_meta("purpose", purpose)
	parent.add_child(marker)
	marker.owner = root


func _add_trigger(
	root: Node2D,
	parent: Node2D,
	trigger_name: String,
	position: Vector2,
	size: Vector2,
	trigger_type: String
) -> void:
	var area := Area2D.new()
	area.name = trigger_name
	area.position = position
	area.collision_layer = 0
	area.collision_mask = 1
	area.set_meta("trigger_type", trigger_type)
	parent.add_child(area)
	area.owner = root

	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	area.add_child(collision)
	collision.owner = root


func _add_fall_kill_zone(root: Node2D) -> void:
	var area := Area2D.new()
	area.name = "FallKillZone"
	area.position = Vector2(LEVEL_WIDTH * 0.5, 970)
	area.set_script(KILL_ZONE_SCRIPT)
	root.add_child(area)
	area.owner = root

	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(LEVEL_WIDTH + 512, 180)
	collision.shape = shape
	area.add_child(collision)
	collision.owner = root

	var timer := Timer.new()
	timer.name = "Timer"
	timer.wait_time = 0.15
	timer.one_shot = true
	area.add_child(timer)
	timer.owner = root


func _add_player(root: Node2D) -> void:
	var player := CharacterBody2D.new()
	player.name = "Player"
	player.z_index = 10
	player.position = Vector2(280, GROUND_TOP - 80)
	player.set_script(PLAYER_SCRIPT)
	player.set("jump_sound", JUMP_SOUND)
	player.set("run_sound", RUN_SOUND)
	player.set("attack_sound", ATTACK_SOUND)
	player.set("kick_sound", HIT_SOUND)
	player.set("hit_sound", HIT_SOUND)
	player.set("landing_sound", LANDING_SOUND)
	player.set("max_coin_power", 30)
	player.set("local_player", true)
	player.set("network_player_id", 1)
	player.set("dynamic_frames_root", "res://Characters/Active_Players/Ash_Golem/PNG Sequences")
	root.add_child(player)
	player.owner = root

	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	collision.position = Vector2(0, 25)
	var capsule := CapsuleShape2D.new()
	capsule.radius = 6.0
	capsule.height = 18.0
	collision.shape = capsule
	player.add_child(collision)
	collision.owner = root

	var sprite := AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	sprite.z_index = 10
	sprite.position = Vector2(-5, -9)
	sprite.scale = Vector2(0.22, 0.22)
	sprite.sprite_frames = ASH_FRAMES
	sprite.animation = &"Idle"
	player.add_child(sprite)
	sprite.owner = root

	var camera := Camera2D.new()
	camera.name = "Camera2D"
	# Bias the view upward so widescreen displays show the world instead of
	# spending almost half of the frame on the underground soil rows.
	camera.position = Vector2(2, -100)
	camera.zoom = Vector2(1.35, 1.35)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(LEVEL_WIDTH)
	camera.limit_bottom = int(VIEW_HEIGHT)
	player.add_child(camera)
	camera.owner = root


func _add_player_hud(root: Node2D) -> void:
	# Reuse the established in-game HUD so Escape, Return to Game, audio,
	# and Main Menu behave exactly like they do in the existing levels.
	var source_scene := load(HUD_SOURCE_SCENE) as PackedScene
	var source_root := source_scene.instantiate()
	var hud := source_root.get_node_or_null("PlayerHUD") as CanvasLayer
	if hud == null:
		push_error("PlayerHUD was not found in %s" % HUD_SOURCE_SCENE)
		source_root.free()
		return

	source_root.remove_child(hud)
	_set_scene_owner_recursive(hud, null)
	root.add_child(hud)
	_set_scene_owner_recursive(hud, root)
	source_root.free()


func _set_scene_owner_recursive(node: Node, scene_owner: Node = null) -> void:
	node.owner = scene_owner
	for child in node.get_children():
		_set_scene_owner_recursive(child, scene_owner)


func _add_design_note(root: Node2D) -> void:
	var note := Node.new()
	note.name = "DesignNotes"
	note.set_meta("route", "awakening > teaching > pressure > crypt memory > short bridge > final graves > exit")
	note.set_meta("collision_rule", "terrain and bridge collide; decorations do not")
	note.set_meta("readability_rule", "lanterns mark landmarks and both bridge landings")
	note.set_meta("enemy_policy", "grave tells, emergence, Easy chase/attack/recovery, death, and HUD counting")
	note.set_meta("background_policy", "one moon; layered hills, fog, grounded houses; no cemetery waterfall")
	note.set_meta("waterfall_policy", "one world-space assembly below and behind the bridge")
	note.set_meta("ground_policy", "surface remains at y=620; visual soil extends below the camera with two-row overscan")
	note.set_meta("online_scope", "story-only scene; online scenes and resources are unchanged")
	root.add_child(note)
	note.owner = root
