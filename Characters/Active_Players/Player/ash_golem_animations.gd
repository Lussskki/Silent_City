class_name AshGolemAnimations
extends RefCounted

# Polished rig frames use twice the original samples, retaining clip durations.
const FRAMES_PATH := "res://Resources/ash_golem_sprite_frames.tres"
const ANIMATIONS := {
	"Climbing": [8.0, true], "Dying": [24.0, false], "Falling Down": [24.0, true],
	"Hurt": [24.0, false], "Idle": [24.0, true], "Jump Looping": [24.0, true],
	"Kicking": [24.0, false], "Run Slashing": [24.0, false], "Running": [40.0, true],
	"Slashing": [24.0, false], "Slashing In Air": [24.0, false], "Sliding": [24.0, false],
	"Throwing": [24.0, false], "Throwing In Air": [24.0, false], "Walking": [60.0, true]
}

static func apply(player) -> bool:
	# Copy the animation list, but keep the loaded textures shared.
	# Deep-copying every PNG can stall the game when players spawn.
	var source_frames := ResourceLoader.load(FRAMES_PATH, "SpriteFrames") as SpriteFrames
	if source_frames == null:
		return false
	var frames: SpriteFrames = source_frames.duplicate(false)
	for animation_name in ANIMATIONS:
		if frames.has_animation(animation_name):
			var settings: Array = ANIMATIONS[animation_name]
			frames.set_animation_speed(animation_name, settings[0])
			frames.set_animation_loop(animation_name, settings[1])
	player.sprite.sprite_frames = frames
	player.sprite.play("Idle")
	return true
