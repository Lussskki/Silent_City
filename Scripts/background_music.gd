extends AudioStreamPlayer

func _ready() -> void:
	finished.connect(_on_finished)
	if not playing:
		play()


func _on_finished() -> void:
	play()
