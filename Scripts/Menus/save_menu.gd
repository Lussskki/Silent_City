extends Node

signal load_requested(scene_path: String)

const BUTTON_SIZE := Vector2(520.0, 58.0)
const SMALL_BUTTON_SIZE := Vector2(320.0, 46.0)
const BUTTON_PNG := "res://Resources/Buttons/menu_button_how_to_play.png"
const BACK_PNG := "res://Resources/Buttons/menu_button_exit.png"

var pages: Control
var play_page: VBoxContainer
var save_page: VBoxContainer
var load_button: Button
var slot_buttons: Array[Button] = []
var back_button: Button
var settings: Node
var show_page_callback
var translate_callback
var language_callback
var set_save_header_callback
var apply_button_sprite_callback


func setup(pages_node: Control, play_page_node: VBoxContainer, services: Dictionary) -> void:
	pages = pages_node
	play_page = play_page_node
	settings = services.get("settings") as Node
	show_page_callback = services.get("show_page")
	translate_callback = services.get("translate")
	language_callback = services.get("language")
	set_save_header_callback = services.get("set_save_header")
	apply_button_sprite_callback = services.get("apply_button_sprite")
	_create_play_button()
	if settings:
		if settings.has_signal("save_slots_changed"):
			settings.save_slots_changed.connect(refresh)


func open() -> void:
	_ensure_page()
	refresh()
	_set_save_header(true)
	_show_page(save_page)


func refresh() -> void:
	if load_button:
		load_button.text = _t("load_game")
		load_button.disabled = settings == null or not bool(settings.call("has_any_save"))
	if save_page == null:
		return
	back_button.text = _t("back")
	var summaries: Array = settings.call("get_save_slot_summaries") if settings else []
	for index in range(slot_buttons.size()):
		var button := slot_buttons[index]
		if index >= summaries.size():
			button.visible = false
			continue
		button.visible = true
		var summary: Dictionary = summaries[index]
		var slot := int(summary.get("slot", index))
		var is_empty := bool(summary.get("empty", true))
		button.disabled = is_empty
		if is_empty:
			button.text = (_t("slot") % slot) + " — " + _t("empty")
			continue
		button.text = (_t("slot") % slot) + " — %s" % [
			_save_slot_age(String(summary.get("saved_at_text", "")))
		]


func _create_play_button() -> void:
	load_button = play_page.get_node_or_null("LoadGameButton") as Button
	if load_button == null:
		load_button = Button.new()
		load_button.name = "LoadGameButton"
		load_button.custom_minimum_size = SMALL_BUTTON_SIZE
		load_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		play_page.add_child(load_button)
		var back := play_page.get_node_or_null("BackButton")
		if back:
			play_page.move_child(load_button, back.get_index())
	_apply_button_sprite(load_button, BUTTON_PNG, SMALL_BUTTON_SIZE)
	load_button.pressed.connect(open)
	refresh()


func _ensure_page() -> void:
	if save_page:
		return
	save_page = VBoxContainer.new()
	save_page.name = "SaveGames"
	save_page.alignment = BoxContainer.ALIGNMENT_CENTER
	save_page.add_theme_constant_override("separation", 12)
	save_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	save_page.visible = false
	pages.add_child(save_page)

	for slot in range(1, 4):
		var button := Button.new()
		button.name = "Slot%dButton" % slot
		button.custom_minimum_size = BUTTON_SIZE
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.pressed.connect(_load_slot.bind(slot))
		save_page.add_child(button)
		slot_buttons.append(button)
		_apply_button_sprite(button, BUTTON_PNG, BUTTON_SIZE)

	back_button = Button.new()
	back_button.name = "BackButton"
	back_button.custom_minimum_size = SMALL_BUTTON_SIZE
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.pressed.connect(_back_to_play)
	save_page.add_child(back_button)
	_apply_button_sprite(back_button, BACK_PNG, SMALL_BUTTON_SIZE)


func _load_slot(slot: int) -> void:
	if settings == null:
		return
	var scene_path := String(settings.call("request_load_slot", slot))
	if not scene_path.is_empty():
		load_requested.emit(scene_path)


func _back_to_play() -> void:
	_set_save_header(false)
	_show_page(play_page)


func _set_save_header(enabled: bool) -> void:
	if set_save_header_callback is Callable and set_save_header_callback.is_valid():
		set_save_header_callback.call(enabled)


func _apply_button_sprite(button: Button, texture_path: String, size: Vector2) -> void:
	if apply_button_sprite_callback is Callable and apply_button_sprite_callback.is_valid():
		apply_button_sprite_callback.call(button, texture_path, size)


func _show_page(page: Control) -> void:
	if show_page_callback is Callable and show_page_callback.is_valid():
		show_page_callback.call(page)


func _t(key: String) -> String:
	if translate_callback is Callable and translate_callback.is_valid():
		return String(translate_callback.call(key))
	return key


func _save_slot_age(saved_at: String) -> String:
	var timestamp := saved_at.replace("T", " ")
	var saved_date := timestamp.left(10)
	var saved_time := timestamp.substr(11, 5) if timestamp.length() >= 16 else ""
	var time_suffix := " • " + saved_time if not saved_time.is_empty() else ""
	var today := Time.get_date_string_from_system(false)
	var georgian := _language() == "geo"
	if saved_date == today:
		return ("დღეს" if georgian else "Today") + time_suffix
	var saved_midnight := Time.get_unix_time_from_datetime_string(saved_date + "T00:00:00")
	var today_midnight := Time.get_unix_time_from_datetime_string(today + "T00:00:00")
	var days_ago := int(round((today_midnight - saved_midnight) / 86400.0))
	if days_ago == 1:
		return ("გუშინ" if georgian else "Yesterday") + time_suffix
	if days_ago > 1:
		return ("%d დღის წინ%s" if georgian else "%d days ago%s") % [days_ago, time_suffix]
	return ("შენახულია" if georgian else "Saved") + time_suffix


func _language() -> String:
	if language_callback is Callable and language_callback.is_valid():
		return String(language_callback.call())
	return "eng"
