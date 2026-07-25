extends Area2D

@export var gun_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if gun_texture:
		sprite.texture = gun_texture
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	if body.get("local_player") == false:
		return
	if body.has_method("grant_gun"):
		body.grant_gun()
	queue_free()
