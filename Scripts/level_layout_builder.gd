extends RefCounted

const TILE_SIZE := 128.0

const TILE_TOP_LEFT := preload("res://Sprites/Tiles/Tile (1).png")
const TILE_TOP := preload("res://Sprites/Tiles/Tile (2).png")
const TILE_TOP_RIGHT := preload("res://Sprites/Tiles/Tile (3).png")
const TILE_LEFT := preload("res://Sprites/Tiles/Tile (4).png")
const TILE_FILL := preload("res://Sprites/Tiles/Tile (5).png")
const TILE_RIGHT := preload("res://Sprites/Tiles/Tile (6).png")
const TILE_BOTTOM_LEFT := preload("res://Sprites/Tiles/Tile (12).png")
const TILE_BOTTOM := preload("res://Sprites/Tiles/Tile (9).png")
const TILE_BOTTOM_RIGHT := preload("res://Sprites/Tiles/Tile (13).png")
const TILE_FLOAT_LEFT := preload("res://Sprites/Tiles/Tile (14).png")
const TILE_FLOAT_MIDDLE := preload("res://Sprites/Tiles/Tile (15).png")
const TILE_FLOAT_RIGHT := preload("res://Sprites/Tiles/Tile (16).png")
const SPIKE := preload("res://Sprites/Tiles/Forbidden_Graveyard_2D_Platformer_Tileset_Platformer - Spike.png")
const BARREL := preload("res://Sprites/Tiles/Forbidden_Graveyard_2D_Platformer_Tileset_Platformer - Wooden Barrel.png")
const BOX := preload("res://Sprites/Tiles/Forbidden_Graveyard_2D_Platformer_Tileset_Platformer - Wooden Box.png")
const BRIDGE_LEFT := preload("res://Sprites/Tiles/Forbidden_Graveyard_2D_Platformer_Tileset_Platformer - Bridge Part 01.png")
const BRIDGE_RIGHT := preload("res://Sprites/Tiles/Forbidden_Graveyard_2D_Platformer_Tileset_Platformer - Bridge Part 02.png")
const LADDER := preload("res://Sprites/Tiles/Forbidden_Graveyard_2D_Platformer_Tileset_Platformer - Ladder.png")
const STONE := preload("res://Sprites/Tiles/Forbidden_Graveyard_2D_Platformer_Tileset_Platformer - Stone.png")

const CRATE := preload("res://Sprites/Objects/Crate.png")
const TOMBSTONE_A := preload("res://Sprites/Objects/TombStone (2).png")
const TOMBSTONE_B := preload("res://Sprites/Objects/TombStone (1).png")
const TREE := preload("res://Sprites/Objects/Tree.png")
const BUSH := preload("res://Sprites/Objects/Bush (1).png")
const BUSH_2 := preload("res://Sprites/Objects/Bush (2).png")
const DEAD_BUSH := preload("res://Sprites/Objects/DeadBush.png")
const SKELETON := preload("res://Sprites/Objects/Skeleton.png")
const SIGN := preload("res://Sprites/Objects/Sign.png")
const ARROW_SIGN := preload("res://Sprites/Objects/ArrowSign.png")

const CRYPT := preload("res://Sprites/Environment/Forbidden_Graveyard_2D_Platformer_Tileset_Environment - Crypt.png")
const COFFIN := preload("res://Sprites/Environment/Forbidden_Graveyard_2D_Platformer_Tileset_Environment - Coffin.png")
const FENCE_A := preload("res://Sprites/Environment/Forbidden_Graveyard_2D_Platformer_Tileset_Environment - Fence 01.png")
const FENCE_B := preload("res://Sprites/Environment/Forbidden_Graveyard_2D_Platformer_Tileset_Environment - Fence 02.png")
const LANTERN := preload("res://Sprites/Environment/Forbidden_Graveyard_2D_Platformer_Tileset_Environment - Lantern.png")
const ROCK := preload("res://Sprites/Environment/Forbidden_Graveyard_2D_Platformer_Tileset_Environment - Rock 01.png")
const SKULL := preload("res://Sprites/Environment/Forbidden_Graveyard_2D_Platformer_Tileset_Environment - Skull.png")
const TREE_ALT := preload("res://Sprites/Environment/Forbidden_Graveyard_2D_Platformer_Tileset_Environment - Tree 02.png")


static func rebuild(target: Node2D, difficulty: String, hazard_script: Script) -> void:
	_clear(target)
	match difficulty:
		"medium":
			_build_medium(target, hazard_script)
		"hard":
			_build_hard(target, hazard_script)
		_:
			_build_easy(target, hazard_script)


static func _clear(target: Node2D) -> void:
	for child in target.get_children():
		target.remove_child(child)
		child.free()


static func _build_easy(root: Node2D, hazard_script: Script) -> void:
	_add_platform(root, "StartPlatform", Rect2(96, 480, 768, 256))
	_add_platform(root, "LowBridge", Rect2(928, 410, 512, 128))
	_add_platform(root, "CryptRise", Rect2(1540, 350, 512, 256))
	_add_platform(root, "ShortStep", Rect2(2180, 470, 384, 128))
	_add_platform(root, "FinalGround", Rect2(2760, 420, 640, 256))
	_add_spike_pit(root, Vector2(1440, 706), 3, hazard_script)

	_add_sprite(root, "StartTree", TREE_ALT, Vector2(160, 280), Vector2(0.9, 0.9))
	_add_sprite(root, "StartFenceA", FENCE_A, Vector2(390, 454), Vector2(1.1, 1.1))
	_add_sprite(root, "StartSign", ARROW_SIGN, Vector2(710, 414))
	_add_sprite(root, "BridgeLantern", LANTERN, Vector2(1035, 310), Vector2(0.9, 0.9))
	_add_sprite(root, "BridgeBox", BOX, Vector2(1290, 348))
	_add_bridge_trim(root, Vector2(960, 370), 4)
	_add_sprite(root, "Crypt", CRYPT, Vector2(1690, 178), Vector2(0.82, 0.82))
	_add_sprite(root, "CryptBush", BUSH_2, Vector2(1950, 302), Vector2(0.85, 0.85))
	_add_sprite(root, "StepRock", ROCK, Vector2(2265, 426), Vector2(1.15, 1.15))
	_add_sprite(root, "FinalCoffin", COFFIN, Vector2(2900, 340), Vector2(0.9, 0.9))
	_add_sprite(root, "FinalTombstone", TOMBSTONE_A, Vector2(3170, 348), Vector2(1.8, 1.8))
	_add_sprite(root, "FinalTree", TREE, Vector2(3340, 300), Vector2(-1.05, 1.05))


static func _build_medium(root: Node2D, hazard_script: Script) -> void:
	_add_platform(root, "StartPlatform", Rect2(0, 500, 640, 256))
	_add_platform(root, "FirstJump", Rect2(760, 360, 384, 128))
	_add_platform(root, "BrokenBridge", Rect2(1260, 455, 256, 128))
	_add_platform(root, "CryptTower", Rect2(1660, 260, 512, 384))
	_add_platform(root, "DropFight", Rect2(2260, 620, 512, 128))
	_add_platform(root, "NarrowStep", Rect2(2860, 425, 256, 128))
	_add_platform(root, "ExitPlatform", Rect2(3240, 335, 512, 256))
	_add_spike_pit(root, Vector2(640, 708), 4, hazard_script)
	_add_spike_pit(root, Vector2(1518, 708), 3, hazard_script)
	_add_spike_pit(root, Vector2(2772, 708), 3, hazard_script)

	_add_sprite(root, "StartFence", FENCE_B, Vector2(130, 462), Vector2(1.2, 1.2))
	_add_sprite(root, "StartSkeleton", SKELETON, Vector2(350, 458), Vector2(1.15, 1.15))
	_add_sprite(root, "StartBarrel", BARREL, Vector2(535, 440), Vector2(0.95, 0.95))
	_add_sprite(root, "FirstLantern", LANTERN, Vector2(820, 260), Vector2(0.9, 0.9))
	_add_sprite(root, "FirstTombstone", TOMBSTONE_B, Vector2(1030, 305), Vector2(1.55, 1.55))
	_add_bridge_trim(root, Vector2(1288, 415), 2)
	_add_sprite(root, "TowerCrypt", CRYPT, Vector2(1818, 90), Vector2(0.86, 0.86))
	_add_sprite(root, "TowerBush", DEAD_BUSH, Vector2(2075, 223), Vector2(0.85, 0.85))
	_add_sprite(root, "DropCoffin", COFFIN, Vector2(2350, 542), Vector2(0.82, 0.82))
	_add_sprite(root, "DropSkull", SKULL, Vector2(2630, 592), Vector2(1.1, 1.1))
	_add_sprite(root, "StepCrate", CRATE, Vector2(2950, 365), Vector2(0.95, 0.95))
	_add_sprite(root, "ExitLantern", LANTERN, Vector2(3325, 230), Vector2(0.9, 0.9))
	_add_sprite(root, "ExitTree", TREE_ALT, Vector2(3655, 140), Vector2(-0.85, 0.85))


static func _build_hard(root: Node2D, hazard_script: Script) -> void:
	_add_platform(root, "StartPlatform", Rect2(0, 520, 512, 256))
	_add_platform(root, "NeedleA", Rect2(665, 385, 256, 128))
	_add_platform(root, "NeedleB", Rect2(1065, 265, 256, 128))
	_add_platform(root, "NeedleC", Rect2(1485, 425, 256, 128))
	_add_platform(root, "CryptWall", Rect2(1865, 230, 384, 512))
	_add_platform(root, "LowRespite", Rect2(2410, 610, 256, 128))
	_add_platform(root, "KnifeBridgeA", Rect2(2815, 445, 256, 128))
	_add_platform(root, "KnifeBridgeB", Rect2(3110, 310, 256, 128))
	_add_platform(root, "FinalPlatform", Rect2(3460, 410, 384, 256))
	_add_spike_pit(root, Vector2(512, 728), 4, hazard_script)
	_add_spike_pit(root, Vector2(921, 728), 5, hazard_script)
	_add_spike_pit(root, Vector2(1321, 728), 4, hazard_script)
	_add_spike_pit(root, Vector2(2666, 728), 5, hazard_script)
	_add_spike_pit(root, Vector2(3350, 728), 2, hazard_script)

	_add_sprite(root, "StartDeadTree", TREE, Vector2(95, 390), Vector2(1.05, 1.05))
	_add_sprite(root, "StartFence", FENCE_A, Vector2(290, 488), Vector2(1.05, 1.05))
	_add_sprite(root, "NeedleALantern", LANTERN, Vector2(710, 285), Vector2(0.78, 0.78))
	_add_sprite(root, "NeedleARock", STONE, Vector2(850, 334), Vector2(0.95, 0.95))
	_add_sprite(root, "NeedleBBox", BOX, Vector2(1184, 206), Vector2(0.9, 0.9))
	_add_sprite(root, "NeedleCSkull", SKULL, Vector2(1565, 384), Vector2(0.9, 0.9))
	_add_sprite(root, "WallCrypt", CRYPT, Vector2(1985, 68), Vector2(0.82, 0.82))
	_add_sprite(root, "WallCoffin", COFFIN, Vector2(2185, 176), Vector2(0.72, 0.72))
	_add_sprite(root, "LowBarrel", BARREL, Vector2(2480, 552), Vector2(0.9, 0.9))
	_add_bridge_trim(root, Vector2(2835, 405), 2)
	_add_sprite(root, "BridgeSign", SIGN, Vector2(3195, 260), Vector2(0.9, 0.9))
	_add_sprite(root, "FinalTombstone", TOMBSTONE_A, Vector2(3515, 338), Vector2(1.65, 1.65))
	_add_sprite(root, "FinalFence", FENCE_B, Vector2(3735, 374), Vector2(1.2, 1.2))


static func _add_platform(root: Node2D, platform_name: String, rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.name = platform_name
	body.position = rect.position + rect.size * 0.5
	root.add_child(body)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.add_child(collision)

	var columns: int = max(1, int(round(rect.size.x / TILE_SIZE)))
	var rows: int = max(1, int(round(rect.size.y / TILE_SIZE)))
	for row in rows:
		for column in columns:
			var tile := Sprite2D.new()
			tile.name = "%s_Tile_%d_%d" % [platform_name, column, row]
			tile.texture = _platform_tile_texture(column, row, columns, rows)
			tile.position = Vector2(rect.position.x + TILE_SIZE * column + TILE_SIZE * 0.5, rect.position.y + TILE_SIZE * row + TILE_SIZE * 0.5)
			tile.z_index = -1
			root.add_child(tile)


static func _platform_tile_texture(column: int, row: int, columns: int, rows: int) -> Texture2D:
	if rows == 1:
		if column == 0:
			return TILE_FLOAT_LEFT
		if column == columns - 1:
			return TILE_FLOAT_RIGHT
		return TILE_FLOAT_MIDDLE
	if row == 0:
		if column == 0:
			return TILE_TOP_LEFT
		if column == columns - 1:
			return TILE_TOP_RIGHT
		return TILE_TOP
	if row == rows - 1:
		if column == 0:
			return TILE_BOTTOM_LEFT
		if column == columns - 1:
			return TILE_BOTTOM_RIGHT
		return TILE_BOTTOM
	if column == 0:
		return TILE_LEFT
	if column == columns - 1:
		return TILE_RIGHT
	return TILE_FILL


static func _add_spike_pit(root: Node2D, start_position: Vector2, count: int, hazard_script: Script) -> void:
	var hazard := Area2D.new()
	hazard.name = "SpikePitHazard"
	hazard.position = start_position + Vector2(TILE_SIZE * float(count) * 0.5, 32)
	if hazard_script:
		hazard.set_script(hazard_script)
	root.add_child(hazard)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(TILE_SIZE * count, 56)
	collision.shape = shape
	hazard.add_child(collision)

	for index in count:
		_add_sprite(root, "Spike_%d" % index, SPIKE, start_position + Vector2(TILE_SIZE * index + TILE_SIZE * 0.5, 0))


static func _add_bridge_trim(root: Node2D, start_position: Vector2, pairs: int) -> void:
	for index in pairs:
		_add_sprite(root, "BridgeLeft_%d" % index, BRIDGE_LEFT, start_position + Vector2(index * 128, 0), Vector2(1.0, 1.0), -2)
		_add_sprite(root, "BridgeRight_%d" % index, BRIDGE_RIGHT, start_position + Vector2(index * 128 + 64, 0), Vector2(1.0, 1.0), -2)


static func _add_sprite(root: Node2D, sprite_name: String, texture: Texture2D, position: Vector2, scale: Vector2 = Vector2.ONE, z_index: int = 0) -> void:
	var sprite := Sprite2D.new()
	sprite.name = sprite_name
	sprite.texture = texture
	sprite.position = position
	sprite.scale = scale
	sprite.z_index = z_index
	root.add_child(sprite)
