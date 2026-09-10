@tool
extends Node2D

const LevelLayoutBuilder = preload("res://Scripts/level_layout_builder.gd")


func _ready() -> void:
	if Engine.is_editor_hint():
		_build_arena.call_deferred()
		return
	_build_arena()


func _build_arena() -> void:
	var level := get_node_or_null("Level") as Node2D
	if level:
		LevelLayoutBuilder.rebuild_squad(level)
