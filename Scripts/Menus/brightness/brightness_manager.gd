extends CanvasLayer

signal brightness_changed(percent: int)

const CONFIG_PATH := "user://brightness_settings.cfg"
const MIN_PERCENT := 25
const MAX_PERCENT := 100

var brightness_percent := 100
var dark_overlay: ColorRect
var light_overlay: ColorRect


func _ready() -> void:
	layer = 1000
	_build_overlays()
	_load_brightness()
	_apply_brightness()


func set_brightness(percent: int) -> void:
	brightness_percent = clampi(percent, MIN_PERCENT, MAX_PERCENT)
	_apply_brightness()
	_save_brightness()
	brightness_changed.emit(brightness_percent)


func get_brightness() -> int:
	return brightness_percent


func _build_overlays() -> void:
	dark_overlay = ColorRect.new()
	dark_overlay.name = "DarkOverlay"
	dark_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dark_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dark_overlay)

	light_overlay = ColorRect.new()
	light_overlay.name = "LightOverlay"
	light_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	light_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var additive_material := CanvasItemMaterial.new()
	additive_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	light_overlay.material = additive_material
	add_child(light_overlay)


func _apply_brightness() -> void:
	if not dark_overlay or not light_overlay:
		return

	var darkness := (100.0 - float(brightness_percent)) / 100.0
	dark_overlay.color = Color(0.0, 0.0, 0.0, darkness)
	light_overlay.color = Color(1.0, 1.0, 1.0, 0.0)


func _load_brightness() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return

	brightness_percent = clampi(
		int(config.get_value("display", "brightness_percent", 100)),
		MIN_PERCENT,
		MAX_PERCENT
	)


func _save_brightness() -> void:
	var config := ConfigFile.new()
	config.set_value("display", "brightness_percent", brightness_percent)
	config.save(CONFIG_PATH)
