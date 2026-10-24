@tool
extends Node2D

const ENVIRONMENT_DIR := "res://Sprites/Graveyard/GraveyardTileset_second/PNG/Environment"
const PLATFORM_DIR := "res://Sprites/Graveyard/GraveyardTileset_second/PNG/Platfromer"
const ASSET_PREFIX := "Forbidden_Graveyard_2D_Platformer_Tileset_Environment - "
const PLATFORM_PREFIX := "Forbidden_Graveyard_2D_Platformer_Tileset_Platformer - "
const GROUND_Y := 620.0

@export var preview_enabled := true
@export var layout_revision := 4:
	set(value):
		layout_revision = value
		if is_inside_tree():
			call_deferred("_rebuild_preview")


func _ready() -> void:
	if get_children().any(
		func(child: Node) -> bool: return child.owner != null
	):
		set_process(true)
		return
	_rebuild_preview()
	set_process(true)


func _process(delta: float) -> void:
	for child in get_children():
		if child.has_meta("fog_origin"):
			var origin := child.get_meta("fog_origin") as Vector2
			var phase := float(child.get_meta("fog_phase"))
			var speed := float(child.get_meta("fog_speed"))
			phase = fmod(phase + delta * speed, TAU)
			child.set_meta("fog_phase", phase)
			child.position = origin + Vector2(sin(phase) * 34.0, cos(phase * 0.55) * 3.0)


func get_preview_summary() -> Dictionary:
	return {
		"environment_assets": get_children().filter(
			func(child: Node) -> bool: return child.name.begins_with("EnvironmentPreview")
		).size(),
		"collectable_assets": 0,
		"route_sections": get_children().filter(
			func(child: Node) -> bool: return child.name.begins_with("RouteSection")
		).size(),
		"fog_bands": get_children().filter(
			func(child: Node) -> bool: return child.name.begins_with("FogBand")
		).size(),
		"light_glows": get_children().filter(
			func(child: Node) -> bool: return child.name.begins_with("AtmosphereGlow")
		).size(),
		"particle_emitters": get_children().filter(
			func(child: Node) -> bool: return child.name.begins_with("DriftingParticles")
		).size(),
		"background_ground_tiles": get_children().filter(
			func(child: Node) -> bool: return child.name.begins_with("BackgroundGround")
		).size(),
	}


func _rebuild_preview() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	if not preview_enabled:
		return

	_add_route_marker("VillageEdge", 650.0)
	_add_route_marker("FloodedRuins", 1900.0)
	_add_route_marker("WaterfallBridge", 3650.0)
	_add_route_marker("LiftApproach", 5000.0)
	_add_route_marker("CemeteryEntrance", 6100.0)

	_add_background_ground()
	_build_village_edge()
	_build_flooded_ruins()
	_build_waterfall_bridge()
	_build_lift_approach()
	_build_cemetery_entrance()
	_add_atmosphere()


func _add_background_ground() -> void:
	_add_background_ground_segment(4864.0, 3, "LiftApproach")
	_add_background_ground_segment(5760.0, 7, "Cemetery")


func _add_background_ground_segment(start_x: float, columns: int, section_name: String) -> void:
	for row in 2:
		for column in columns:
			var tile_name := "Ground 06.png"
			if row == 0:
				if column == 0:
					tile_name = "Ground 04.png"
				elif column == columns - 1:
					tile_name = "Ground 08.png"
				else:
					tile_name = "Ground 02.png"
			elif column == 0:
				tile_name = "Ground 09.png"
			elif column == columns - 1:
				tile_name = "Ground 13.png"
			var texture := load(PLATFORM_DIR.path_join(PLATFORM_PREFIX + tile_name)) as Texture2D
			if texture == null:
				continue
			var tile := Sprite2D.new()
			tile.name = "BackgroundGround_%s_%02d_%02d" % [section_name, row, column]
			tile.texture = texture
			tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tile.position = Vector2(
				start_x + float(column) * 128.0 + 64.0,
				GROUND_Y + float(row) * 128.0 + 64.0
			)
			tile.modulate = Color(0.64, 0.69, 0.71, 0.82)
			tile.z_index = -6
			tile.set_meta("decorative_background_only", true)
			add_child(tile)
			_register_editor_node(tile)


func _build_village_edge() -> void:
	_place("Tree 01.png", 250.0, 168.0, -4, Color(0.42, 0.49, 0.52, 0.48), true)
	_place("Fence 01.png", 430.0, 72.0, -2, Color(0.63, 0.69, 0.71, 0.82))
	_place("Bush 01.png", 575.0, 56.0, -1)
	_place("Lantern.png", 715.0, 88.0, 0)
	_place("Fence 02.png", 850.0, 76.0, -2)
	_place("Signpost 01.png", 1010.0, 70.0, 0)
	_place("Rock 01.png", 1130.0, 36.0, -1)
	_add_glow(Vector2(715.0, 562.0), 0.72)


func _build_flooded_ruins() -> void:
	_place("Tree 02.png", 1320.0, 162.0, -4, Color(0.38, 0.46, 0.50, 0.44))
	_place("Stone fence 01.png", 1450.0, 74.0, -2)
	_place("Rock 02.png", 1580.0, 42.0, -1)
	_place("Bone.png", 1690.0, 24.0, 0)
	_place("Bush 02.png", 1810.0, 55.0, -1)
	_place("Coffin.png", 1950.0, 82.0, -2, Color(0.68, 0.72, 0.72, 0.82), true)
	_place("Rock 03.png", 2080.0, 40.0, -1)
	_place("Skull.png", 2180.0, 28.0, 0)
	_place("Signpost 02.png", 2310.0, 68.0, 0)
	_place("Rock 04.png", 2425.0, 45.0, -1)
	_place("Stone fence 02.png", 2580.0, 76.0, -2)
	_place("Signpost 03.png", 2730.0, 66.0, 0)
	_place("Rock 05.png", 2850.0, 38.0, -1)
	_place("Rock 06.png", 2960.0, 44.0, -1)


func _build_waterfall_bridge() -> void:
	_place("Tree 01.png", 3180.0, 154.0, -4, Color(0.40, 0.48, 0.51, 0.46))
	_place("Bush 01.png", 3330.0, 50.0, -22)
	_place("Rock 04.png", 3440.0, 42.0, -1)
	_place("Lantern.png", 3570.0, 84.0, 0)
	_place("Signpost 04.png", 3790.0, 68.0, 0)
	_place("Rock 05.png", 3920.0, 45.0, -1)
	_place("Fire.png", 4070.0, 66.0, 0)
	_place("Bush 02.png", 4240.0, 52.0, -1, Color.WHITE, true)
	_place("Rock 06.png", 4400.0, 46.0, -1)
	_add_glow(Vector2(3570.0, 564.0), 0.68)
	_add_glow(Vector2(4070.0, 575.0), 0.95)


func _build_lift_approach() -> void:
	_place("Tree 02.png", 4600.0, 158.0, -4, Color(0.39, 0.47, 0.50, 0.45), true)
	_place("Stone fence 01.png", 4740.0, 76.0, -2)
	_place("Signpost 05.png", 4880.0, 72.0, 0)
	_place("Lantern.png", 5050.0, 90.0, 0)
	_place("Fence 01.png", 5200.0, 74.0, -2)
	_place("Fence 02.png", 5340.0, 76.0, -2)
	_place("Rock 02.png", 5470.0, 40.0, -1)
	_add_glow(Vector2(5050.0, 560.0), 0.76)


func _build_cemetery_entrance() -> void:
	_place("Tree 01.png", 5600.0, 176.0, -4, Color(0.40, 0.47, 0.50, 0.48))
	_place("Stone fence 02.png", 5700.0, 78.0, -2)
	_place("Headstone 01.png", 5800.0, 74.0, -1)
	_place("Headstone 02.png", 5900.0, 78.0, -1)
	_place("Crypt.png", 6090.0, 134.0, -2)
	_place("Headstone 03.png", 6250.0, 82.0, -1)
	_place("Coffin.png", 6360.0, 86.0, -2)
	_place("Signpost 06.png", 6460.0, 72.0, 0)
	_place("Fire.png", 6540.0, 68.0, 0)
	_place("Tree 02.png", 6630.0, 180.0, -4, Color(0.40, 0.47, 0.50, 0.48), true)
	_add_glow(Vector2(6540.0, 574.0), 0.95)


func _add_atmosphere() -> void:
	_add_fog_band(Vector2(1250.0, 520.0), Vector2(980.0, 48.0), 0.04, -3)
	_add_fog_band(Vector2(2280.0, 548.0), Vector2(1180.0, 58.0), 0.055, 1)
	_add_fog_band(Vector2(3820.0, 505.0), Vector2(1080.0, 52.0), 0.045, -3)
	_add_fog_band(Vector2(5200.0, 540.0), Vector2(980.0, 60.0), 0.06, 1)
	_add_fog_band(Vector2(6200.0, 495.0), Vector2(900.0, 54.0), 0.04, -3)
	_add_particles(Vector2(2080.0, 500.0), Vector2(520.0, 100.0), Color(0.58, 0.78, 0.82, 0.34))
	_add_particles(Vector2(3980.0, 480.0), Vector2(460.0, 120.0), Color(0.72, 0.82, 0.82, 0.30))
	_add_particles(Vector2(6100.0, 485.0), Vector2(500.0, 125.0), Color(0.68, 0.76, 0.78, 0.28))


func _place(
	asset_name: String,
	x: float,
	target_height: float,
	z: int,
	tint: Color = Color.WHITE,
	flip: bool = false
) -> void:
	var texture := load(ENVIRONMENT_DIR.path_join(ASSET_PREFIX + asset_name)) as Texture2D
	if texture == null:
		return
	var sprite := Sprite2D.new()
	sprite.name = "EnvironmentPreview_%s_%d" % [asset_name.get_basename().replace(" ", ""), int(x)]
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = z
	sprite.modulate = tint
	sprite.flip_h = flip
	var texture_size := texture.get_size()
	var asset_scale := target_height / maxf(texture_size.y, 1.0)
	sprite.scale = Vector2(asset_scale, asset_scale)
	sprite.position = Vector2(x, GROUND_Y - texture_size.y * asset_scale * 0.5)
	sprite.set_meta("source_asset", asset_name)
	add_child(sprite)
	_register_editor_node(sprite)


func _add_route_marker(section_name: String, x: float) -> void:
	var marker := Marker2D.new()
	marker.name = "RouteSection_%s" % section_name
	marker.position = Vector2(x, GROUND_Y)
	marker.set_meta("section_name", section_name)
	add_child(marker)
	_register_editor_node(marker)


func _add_fog_band(center: Vector2, size: Vector2, drift_speed: float, z: int) -> void:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.42, 1.0])
	gradient.colors = PackedColorArray([
		Color(0.63, 0.76, 0.79, 0.085),
		Color(0.58, 0.72, 0.76, 0.04),
		Color(0.58, 0.72, 0.76, 0.0),
	])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 512
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	var fog := Sprite2D.new()
	fog.name = "FogBand_%d" % int(center.x)
	fog.texture = texture
	fog.position = center
	fog.scale = Vector2(size.x / 512.0, size.y / 128.0)
	fog.z_index = z
	fog.set_meta("fog_origin", center)
	fog.set_meta("fog_phase", center.x * 0.001)
	fog.set_meta("fog_speed", drift_speed)
	add_child(fog)
	_register_editor_node(fog)


func _add_glow(position_value: Vector2, energy: float) -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(1.0, 0.72, 0.34, 0.04), Color(1.0, 0.45, 0.12, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 128
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	var glow := Sprite2D.new()
	glow.name = "AtmosphereGlow_%d" % int(position_value.x)
	glow.position = position_value
	glow.texture = texture
	glow.scale = Vector2.ONE * lerpf(0.08, 0.11, energy)
	glow.z_index = -1
	var glow_material := CanvasItemMaterial.new()
	glow_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = glow_material
	add_child(glow)
	_register_editor_node(glow)


func _add_particles(position_value: Vector2, emission_box: Vector2, tint: Color) -> void:
	var particles := GPUParticles2D.new()
	particles.name = "DriftingParticles_%d" % int(position_value.x)
	particles.position = position_value
	particles.amount = 12
	particles.lifetime = 6.0
	particles.randomness = 0.7
	particles.visibility_rect = Rect2(-emission_box * 0.6, emission_box * 1.2)
	particles.z_index = 0
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(emission_box.x * 0.5, emission_box.y * 0.5, 1.0)
	material.direction = Vector3(0.8, -0.2, 0.0)
	material.spread = 35.0
	material.initial_velocity_min = 4.0
	material.initial_velocity_max = 10.0
	material.gravity = Vector3(0.0, -1.5, 0.0)
	material.scale_min = 0.8
	material.scale_max = 1.8
	material.color = tint
	particles.process_material = material
	var particle_gradient := Gradient.new()
	particle_gradient.colors = PackedColorArray([Color.WHITE, Color(1.0, 1.0, 1.0, 0.0)])
	var particle_texture := GradientTexture2D.new()
	particle_texture.gradient = particle_gradient
	particle_texture.width = 8
	particle_texture.height = 8
	particle_texture.fill = GradientTexture2D.FILL_RADIAL
	particle_texture.fill_from = Vector2(0.5, 0.5)
	particle_texture.fill_to = Vector2(1.0, 0.5)
	particles.texture = particle_texture
	add_child(particles)
	_register_editor_node(particles)


func _register_editor_node(node: Node) -> void:
	if not Engine.is_editor_hint():
		return
	var edited_root := get_tree().edited_scene_root
	if edited_root == null:
		return
	node.owner = edited_root
	node.set_meta("editable_background_asset", true)
