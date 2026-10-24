extends CanvasLayer

const AURA_SCALE := Vector2(2.65, 2.65)
const ORBIT_RADIUS := Vector2(118.0, 58.0)
const LOADER_VARIANT_COUNT := 4
const LOADER_VARIANTS := [
	{
		"texture": preload("res://Characters/Minotaurs/Minotaur_3/PNG/PNG Sequences/Idle/0_Minotaur_Idle_000.png"),
		"scale": Vector2(0.22, 0.22),
		"aura": Color(1.0, 0.55, 0.30, 0.76),
		"orbit_a": Color(1.0, 0.72, 0.34, 0.92),
		"orbit_b": Color(0.95, 0.38, 0.20, 0.78),
	},
	{
		"texture": preload("res://Characters/Active_Players/Stone_Golem/PNG/PNG Sequences/Idle/0_Golem_Idle_000.png"),
		"scale": Vector2(0.22, 0.22),
		"aura": Color(0.62, 1.0, 0.32, 0.74),
		"orbit_a": Color(0.72, 1.0, 0.38, 0.92),
		"orbit_b": Color(0.35, 0.78, 0.22, 0.76),
	},
	{
		"texture": preload("res://Characters/Active_Players/Ice_Golem/PNG/PNG Sequences/Idle/0_Golem_Idle_000.png"),
		"scale": Vector2(0.22, 0.22),
		"aura": Color(0.42, 0.92, 1.0, 0.78),
		"orbit_a": Color(0.55, 1.0, 1.0, 0.94),
		"orbit_b": Color(0.26, 0.65, 1.0, 0.78),
	},
	{
		"texture": preload("res://Characters/Skeleton_crusider/Skeleton_Crusader_1/PNG/PNG Sequences/Idle/0_Skeleton_Crusader_Idle_000.png"),
		"scale": Vector2(0.22, 0.22),
		"aura": Color(0.75, 0.58, 1.0, 0.76),
		"orbit_a": Color(0.86, 0.70, 1.0, 0.92),
		"orbit_b": Color(0.48, 0.36, 0.92, 0.78),
	},
]

@onready var overlay: Control = $Overlay
@onready var visual_root: Node2D = $Overlay/VisualRoot
@onready var aura: Sprite2D = $Overlay/VisualRoot/Aura
@onready var character: Sprite2D = $Overlay/VisualRoot/Character
@onready var orbit_a: Sprite2D = $Overlay/VisualRoot/OrbitA
@onready var orbit_b: Sprite2D = $Overlay/VisualRoot/OrbitB

var animation_time := 0.0
var last_variant_index := -1

func _ready() -> void:
	layer = 100
	overlay.visible = false
	_center_visual()
	overlay.resized.connect(_center_visual)
	get_tree().scene_changed.connect(_on_scene_changed)


func _process(delta: float) -> void:
	if not overlay.visible:
		return

	animation_time += delta
	var pulse := 1.0 + sin(animation_time * 2.4) * 0.055
	aura.rotation = animation_time * 0.85
	aura.scale = AURA_SCALE * pulse
	character.position.y = sin(animation_time * 2.1) * 7.0
	character.rotation = sin(animation_time * 1.35) * 0.025

	var orbit_angle := animation_time * 1.8
	orbit_a.position = Vector2(cos(orbit_angle) * ORBIT_RADIUS.x, sin(orbit_angle) * ORBIT_RADIUS.y)
	orbit_b.position = Vector2(cos(orbit_angle + PI) * ORBIT_RADIUS.x, sin(orbit_angle + PI) * ORBIT_RADIUS.y)
	orbit_a.rotation = -animation_time * 2.2
	orbit_b.rotation = animation_time * 2.5

	# Swap draw order while the particles pass behind and in front of the Wraith.
	orbit_a.z_index = 2 if sin(orbit_angle) > 0.0 else -1
	orbit_b.z_index = 2 if sin(orbit_angle + PI) > 0.0 else -1


func show_loading(_message := "", variant_index: int = -1) -> int:
	animation_time = 0.0
	var selected_variant := _select_variant(variant_index)
	_apply_variant(selected_variant)
	_center_visual()
	overlay.visible = true
	return selected_variant


func hide_loading() -> void:
	overlay.visible = false


func _select_variant(requested_index: int) -> int:
	if requested_index >= 0:
		return requested_index % LOADER_VARIANT_COUNT
	if last_variant_index < 0:
		return randi() % LOADER_VARIANT_COUNT
	# Pick any variant except the one shown immediately before it.
	return (last_variant_index + 1 + randi() % (LOADER_VARIANT_COUNT - 1)) % LOADER_VARIANT_COUNT


func _apply_variant(variant_index: int) -> void:
	var variant: Dictionary = LOADER_VARIANTS[variant_index]
	character.texture = variant["texture"] as Texture2D
	character.scale = variant["scale"]
	character.position = Vector2.ZERO
	character.rotation = 0.0
	aura.modulate = variant["aura"]
	orbit_a.modulate = variant["orbit_a"]
	orbit_b.modulate = variant["orbit_b"]
	last_variant_index = variant_index


func _center_visual() -> void:
	if visual_root:
		visual_root.position = overlay.size * 0.5


func _on_scene_changed() -> void:
	hide_loading()
