extends "res://Scripts/level_layer.gd"

const TILE_SIZE := 128.0
const GROUND_ORIGIN_Y := 620.0
const BASE_VISUAL_ROWS := 2
const SEGMENTS := [

]

const FIRST_TILESET := "res://Sprites/Graveyard/GraveyardTileset/png"
const TILE_LEFT := FIRST_TILESET + "/Tiles/Tile (4).png"
const TILE_FILL := FIRST_TILESET + "/Tiles/Tile (5).png"
const TILE_RIGHT := FIRST_TILESET + "/Tiles/Tile (6).png"

var current_rows := BASE_VISUAL_ROWS
var last_viewport_size := Vector2i.ZERO
var last_camera_zoom := Vector2.ZERO
var coverage_check_time := 0.0
var underground: Node2D


func _ready() -> void:
	underground = Node2D.new()
	underground.name = "ResponsiveUnderground"
	underground.z_index = -1
	add_child(underground)
	get_viewport().size_changed.connect(_refresh_coverage)
	call_deferred(&"_refresh_coverage")


func _process(delta: float) -> void:
	coverage_check_time -= delta
	if coverage_check_time > 0.0:
		return
	coverage_check_time = 0.25
	var viewport_size := Vector2i(get_viewport_rect().size)
	var camera := get_viewport().get_camera_2d()
	var zoom := camera.zoom if camera else Vector2.ONE
	if viewport_size != last_viewport_size or not zoom.is_equal_approx(last_camera_zoom):
		_refresh_coverage()


func get_coverage_summary() -> Dictionary:
	return {
		"surface_y": GROUND_ORIGIN_Y,
		"tile_size": TILE_SIZE,
		"visual_rows": current_rows,
		"dynamic_tiles": underground.get_child_count() if underground else 0,
		"overscan_rows": 2,
	}


func _refresh_coverage() -> void:
	last_viewport_size = Vector2i(get_viewport_rect().size)
	var camera := get_viewport().get_camera_2d()
	last_camera_zoom = camera.zoom if camera else Vector2.ONE
	var canvas_inverse := get_viewport().get_canvas_transform().affine_inverse()
	var viewport_size := get_viewport_rect().size
	var visible_bottom_world := canvas_inverse * Vector2(viewport_size.x * 0.5, viewport_size.y)
	var required_bottom := visible_bottom_world.y + TILE_SIZE * 2.0
	var required_rows := maxi(
		int(ceil((required_bottom - GROUND_ORIGIN_Y) / TILE_SIZE)),
		BASE_VISUAL_ROWS
	)
	if required_rows <= current_rows:
		return
	for row in range(current_rows, required_rows):
		_add_visual_row(row)
	current_rows = required_rows


func _add_visual_row(row: int) -> void:
	for segment_index in SEGMENTS.size():
		var start_x: float = SEGMENTS[segment_index].x
		var width: float = SEGMENTS[segment_index].y
		var columns := int(round(width / TILE_SIZE))
		for column in columns:
			var tile := Sprite2D.new()
			tile.name = "Underground_%02d_%02d_%02d" % [segment_index, row, column]
			tile.texture = load(_tile_path(column, columns)) as Texture2D
			tile.position = Vector2(
				start_x + column * TILE_SIZE + TILE_SIZE * 0.5,
				GROUND_ORIGIN_Y + row * TILE_SIZE + TILE_SIZE * 0.5
			)
			tile.z_index = -1
			underground.add_child(tile)


func _tile_path(column: int, columns: int) -> String:
	if column == 0:
		return TILE_LEFT
	if column == columns - 1:
		return TILE_RIGHT
	return TILE_FILL
