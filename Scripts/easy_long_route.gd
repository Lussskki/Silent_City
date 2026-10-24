extends Node2D

@onready var scare_panel: ColorRect = $JumpscareOverlay/ScarePanel
@onready var scare_face: TextureRect = $JumpscareOverlay/ScareFace
@onready var scare_title: Label = $JumpscareOverlay/ScareTitle


func _on_jumpscare_gate_body_entered(body: Node2D) -> void:
	if body.name != "Player" or scare_panel.visible:
		return
	scare_panel.visible = true
	scare_face.visible = true
	scare_title.visible = true
	get_tree().create_timer(1.4).timeout.connect(_hide_scare_overlay)


func _hide_scare_overlay() -> void:
	scare_panel.visible = false
	scare_face.visible = false
	scare_title.visible = false
