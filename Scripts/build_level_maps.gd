extends SceneTree

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
const CRATE := preload("res://Sprites/Objects/Crate.png")
const TOMBSTONE_A := preload("res://Sprites/Objects/TombStone (2).png")
const TOMBSTONE_B := preload("res://Sprites/Objects/TombStone (1).png")
const TREE := preload("res://Sprites/Objects/Tree.png")
const BUSH := preload("res://Sprites/Objects/Bush (1).png")
const DEAD_BUSH := preload("res://Sprites/Objects/DeadBush.png")
const SKELETON := preload("res://Sprites/Objects/Skeleton.png")
const SIGN := preload("res://Sprites/Objects/Sign.png")
const HAZARD_SCRIPT := preload("res://Scripts/deadly_hazard.gd")


func _init() -> void:
	_save_medium_map()
	_save_hard_map()
	quit()


func _save_medium_map() -> void:
	var root := Node2D.new()
	root.name = "MediumMap"
	_add_platform(root, "StartPlatform", Rect2(0, 470, 640, 256))
	_add_platform(root, "ShotgunPlatform", Rect2(640, 330, 384, 128))
	_add_platform(root, "CenterPlatform", Rect2(1152, 430, 384, 128))
	_add_platform(root, "HighTower", Rect2(1664, 270, 512, 512))
	_add_platform(root, "StepPlatform", Rect2(2304, 410, 256, 128))
	_add_platform(root, "LowerFightPlatform", Rect2(2176, 650, 512, 128))
	_add_platform(root, "ExitPlatform", Rect2(2816, 500, 384, 256))
	_add_spike_pit(root, Vector2(896, 690), 5)
	_add_shotgun(root, Vector2(820, 270))
	_add_shotgun(root, Vector2(1870, 210))
	_add_sprite(root, "StartTree", TREE, Vector2(120, 340), Vector2(1.35, 1.35))
	_add_sprite(root, "StartSkeleton", SKELETON, Vector2(275, 430), Vector2(1.25, 1.25))
	_add_sprite(root, "StartSign", SIGN, Vector2(425, 414), Vector2(1.05, 1.05))
	_add_sprite(root, "StartCrate", CRATE, Vector2(535, 408))
	_add_sprite(root, "ShotgunTombstone", TOMBSTONE_A, Vector2(710, 261), Vector2(1.55, 1.55))
	_add_sprite(root, "ShotgunBush", BUSH, Vector2(920, 302), Vector2(0.75, 0.75))
	_add_sprite(root, "CenterCrate", CRATE, Vector2(1390, 366))
	_add_sprite(root, "CenterDeadBush", DEAD_BUSH, Vector2(1225, 389), Vector2(0.85, 0.85))
	_add_sprite(root, "TowerTombstone", TOMBSTONE_A, Vector2(1785, 194), Vector2(1.75, 1.75))
	_add_sprite(root, "TowerBush", BUSH, Vector2(1710, 240), Vector2(0.8, 0.8))
	_add_sprite(root, "TowerCrate", CRATE, Vector2(2095, 207))
	_add_sprite(root, "LowerCrate", CRATE, Vector2(2420, 587))
	_add_sprite(root, "LowerDeadBush", DEAD_BUSH, Vector2(2250, 609), Vector2(0.85, 0.85))
	_add_sprite(root, "ExitTombstone", TOMBSTONE_B, Vector2(2920, 440), Vector2(1.8, 1.8))
	_add_sprite(root, "ExitTree", TREE, Vector2(3050, 375), Vector2(-1.15, 1.15))
	_save_scene(root, "res://Scenes/MediumMap.tscn")


func _save_hard_map() -> void:
	var root := Node2D.new()
	root.name = "HardMap"
	_add_platform(root, "StartPlatform", Rect2(0, 500, 512, 256))
	_add_platform(root, "NeedlePlatformA", Rect2(640, 370, 256, 128))
	_add_platform(root, "NeedlePlatformB", Rect2(1030, 250, 256, 128))
	_add_platform(root, "SafeStep", Rect2(1420, 420, 256, 128))
	_add_platform(root, "HighTower", Rect2(1790, 230, 384, 512))
	_add_platform(root, "DropPlatform", Rect2(2300, 560, 256, 128))
	_add_platform(root, "TinyBridge", Rect2(2700, 410, 256, 128))
	_add_platform(root, "FinalPlatform", Rect2(3090, 285, 384, 384))
	_add_spike_pit(root, Vector2(512, 710), 3)
	_add_spike_pit(root, Vector2(900, 710), 4)
	_add_spike_pit(root, Vector2(1285, 710), 4)
	_add_spike_pit(root, Vector2(2560, 710), 4)
	_add_shotgun(root, Vector2(760, 310))
	_add_shotgun(root, Vector2(1915, 170))
	_add_sprite(root, "StartTree", TREE, Vector2(110, 370), Vector2(1.25, 1.25))
	_add_sprite(root, "StartSkeleton", SKELETON, Vector2(300, 460), Vector2(1.15, 1.15))
	_add_sprite(root, "StartCrate", CRATE, Vector2(430, 438), Vector2(0.95, 0.95))
	_add_sprite(root, "PlatformATombstone", TOMBSTONE_B, Vector2(700, 320), Vector2(1.6, 1.6))
	_add_sprite(root, "PlatformABush", BUSH, Vector2(825, 338), Vector2(0.65, 0.65))
	_add_sprite(root, "PlatformBCrate", CRATE, Vector2(1165, 188), Vector2(0.95, 0.95))
	_add_sprite(root, "SafeStepSign", SIGN, Vector2(1500, 364))
	_add_sprite(root, "TowerTombstone", TOMBSTONE_A, Vector2(1875, 154), Vector2(1.65, 1.65))
	_add_sprite(root, "TowerDeadBush", DEAD_BUSH, Vector2(2050, 186), Vector2(0.8, 0.8))
	_add_sprite(root, "TowerCrate", CRATE, Vector2(2115, 168), Vector2(0.95, 0.95))
	_add_sprite(root, "DropDeadBush", DEAD_BUSH, Vector2(2395, 519), Vector2(0.8, 0.8))
	_add_sprite(root, "TinyBridgeCrate", CRATE, Vector2(2790, 348), Vector2(0.95, 0.95))
	_add_sprite(root, "FinalTombstone", TOMBSTONE_A, Vector2(3200, 210), Vector2(1.8, 1.8))
	_add_sprite(root, "FinalTree", TREE, Vector2(3420, 158), Vector2(-1.15, 1.15))
	_save_scene(root, "res://Scenes/HardMap.tscn")


func _add_platform(root: Node2D, platform_name: String, rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.name = platform_name
	body.position = rect.position + rect.size * 0.5
	root.add_child(body)
	body.owner = root

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.add_child(collision)
	collision.owner = root

	var columns: int = max(1, int(round(rect.size.x / TILE_SIZE)))
	var rows: int = max(1, int(round(rect.size.y / TILE_SIZE)))
	for row in rows:
		for column in columns:
			var tile := Sprite2D.new()
			tile.name = "Tile_%d_%d" % [column, row]
			tile.texture = _platform_tile_texture(column, row, columns, rows)
			tile.position = Vector2(rect.position.x + TILE_SIZE * column + TILE_SIZE * 0.5, rect.position.y + TILE_SIZE * row + TILE_SIZE * 0.5)
			tile.z_index = -1
			root.add_child(tile)
			tile.owner = root


func _platform_tile_texture(column: int, row: int, columns: int, rows: int) -> Texture2D:
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


func _add_spike_pit(root: Node2D, start_position: Vector2, count: int) -> void:
	var hazard := Area2D.new()
	hazard.name = "SpikePitHazard"
	hazard.position = start_position + Vector2(TILE_SIZE * float(count) * 0.5, 32)
	hazard.set_script(HAZARD_SCRIPT)
	root.add_child(hazard)
	hazard.owner = root

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(TILE_SIZE * count, 56)
	collision.shape = shape
	hazard.add_child(collision)
	collision.owner = root

	for index in count:
		_add_sprite(root, "Spike_%d" % index, SPIKE, start_position + Vector2(TILE_SIZE * index + TILE_SIZE * 0.5, 0))


func _add_shotgun(root: Node2D, position: Vector2) -> void:
	var pickup := Node2D.new()
	pickup.name = "ShotgunPickup"
	pickup.position = position
	root.add_child(pickup)
	pickup.owner = root

	_add_polygon(root, pickup, "Glow", Color(1, 0.62, 0.08, 0.28), PackedVector2Array([-72, -24, 72, -24, 80, 20, -64, 28]))
	_add_polygon(root, pickup, "Stock", Color(0.78, 0.36, 0.08), PackedVector2Array([-66, -14, -30, -14, -42, 14, -74, 20]))
	_add_polygon(root, pickup, "Body", Color(0.15, 0.16, 0.17), PackedVector2Array([-34, -16, 36, -14, 44, 4, -20, 14]))
	var barrel := Line2D.new()
	barrel.name = "Barrel"
	barrel.points = PackedVector2Array([-42, -7, 56, -7])
	barrel.default_color = Color(0.05, 0.05, 0.06)
	barrel.width = 9.0
	pickup.add_child(barrel)
	barrel.owner = root
	_add_polygon(root, pickup, "Grip", Color(0.55, 0.23, 0.06), PackedVector2Array([-5, 6, 16, 6, 4, 35, -12, 31]))


func _add_polygon(root: Node2D, parent: Node, polygon_name: String, color: Color, points: PackedVector2Array) -> void:
	var polygon := Polygon2D.new()
	polygon.name = polygon_name
	polygon.color = color
	polygon.polygon = points
	parent.add_child(polygon)
	polygon.owner = root


func _add_sprite(root: Node2D, sprite_name: String, texture: Texture2D, position: Vector2, scale: Vector2 = Vector2.ONE) -> void:
	var sprite := Sprite2D.new()
	sprite.name = sprite_name
	sprite.texture = texture
	sprite.position = position
	sprite.scale = scale
	if "Tree" in sprite_name or "Bush" in sprite_name:
		sprite.z_index = 30
	root.add_child(sprite)
	sprite.owner = root


func _save_scene(root: Node2D, path: String) -> void:
	var scene := PackedScene.new()
	var error := scene.pack(root)
	if error != OK:
		push_error("Could not pack %s: %s" % [path, error])
		return
	error = ResourceSaver.save(scene, path)
	if error != OK:
		push_error("Could not save %s: %s" % [path, error])
