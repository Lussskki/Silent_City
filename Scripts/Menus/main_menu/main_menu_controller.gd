extends Node

const CONTROLLER_FOCUS_TINT := Color(0.72, 0.72, 0.72, 1.0)

signal start_requested
signal story_mode_requested
signal squad_requested
signal difficulty_preview_requested
signal character_requested
signal online_requested
signal settings_requested
signal exit_requested

var pages: Control = null
var home_page: Control = null

var home_start_button: Button = null
var mode_story_button: Button = null
var mode_squad_button: Button = null
var mode_back_button: Button = null
var home_map_button: Button = null
var home_choose_button: Button = null
var home_online_button: Button = null
var settings_button: Button = null
var exit_button: Button = null
var language_button: Button = null

var configured := false
var gamepad_focus_active := false


func setup(nodes: Dictionary) -> void:
	if configured:
		return

	pages = nodes.get("pages") as Control
	home_page = nodes.get("home_page") as Control

	home_start_button = nodes.get("home_start_button") as Button
	mode_story_button = nodes.get("mode_story_button") as Button
	mode_squad_button = nodes.get("mode_squad_button") as Button
	mode_back_button = nodes.get("mode_back_button") as Button
	home_map_button = nodes.get("home_map_button") as Button
	home_choose_button = nodes.get("home_choose_button") as Button
	home_online_button = nodes.get("home_online_button") as Button
	settings_button = nodes.get("settings_button") as Button
	exit_button = nodes.get("exit_button") as Button
	language_button = nodes.get("language_button") as Button

	if home_start_button:
		home_start_button.pressed.connect(
			func(): start_requested.emit()
		)

	if mode_story_button:
		mode_story_button.pressed.connect(func(): story_mode_requested.emit())

	if mode_squad_button:
		mode_squad_button.pressed.connect(func(): squad_requested.emit())

	if mode_back_button:
		mode_back_button.pressed.connect(show_home)

	if home_map_button:
		home_map_button.pressed.connect(
			func(): difficulty_preview_requested.emit()
		)

	if home_choose_button:
		home_choose_button.pressed.connect(
			func(): character_requested.emit()
		)

	if home_online_button:
		home_online_button.pressed.connect(
			func(): online_requested.emit()
		)

	if settings_button:
		settings_button.pressed.connect(
			func(): settings_requested.emit()
		)

	if exit_button:
		exit_button.pressed.connect(
			func(): exit_requested.emit()
		)

	gamepad_focus_active = not Input.get_connected_joypads().is_empty()
	if not Input.joy_connection_changed.is_connected(_on_joy_connection_changed):
		Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_setup_language_navigation()
	configured = true
	_prepare_page_focus.call_deferred(home_page)


func show_page(page: Control) -> void:
	if not pages or not page:
		return

	for child in pages.get_children():
		if child is Control:
			child.visible = child == page

	_prepare_page_focus.call_deferred(page)


func show_home() -> void:
	show_page(home_page)


func _input(event: InputEvent) -> void:
	if not configured:
		return
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		gamepad_focus_active = true
		var current_focus := get_viewport().gui_get_focus_owner() as Button
		if current_focus:
			current_focus.self_modulate = CONTROLLER_FOCUS_TINT

	if (
		event is InputEventJoypadButton
		and event.pressed
		and event.button_index == JOY_BUTTON_B
	):
		var circle_back_button := _visible_back_button()
		if circle_back_button:
			get_viewport().set_input_as_handled()
			circle_back_button.emit_signal(&"pressed")
		return

	if event.is_action_pressed("menu_confirm"):
		var focused := get_viewport().gui_get_focus_owner() as Button
		if focused and focused.is_visible_in_tree() and not focused.disabled:
			get_viewport().set_input_as_handled()
			focused.emit_signal(&"pressed")
		return

	if event.is_action_pressed("menu_back"):
		var back_button := _visible_back_button()
		if back_button:
			get_viewport().set_input_as_handled()
			back_button.emit_signal(&"pressed")
		return

	if _is_gamepad_navigation_event(event):
		var focused := get_viewport().gui_get_focus_owner()
		if not focused or not focused.is_visible_in_tree():
			_focus_first_visible_button()


func _prepare_page_focus(page: Control) -> void:
	if not is_instance_valid(page) or not page.is_visible_in_tree():
		return

	for node in page.find_children("*", "Button", true, false):
		var button := node as Button
		if not button:
			continue
		if not button.focus_entered.is_connected(_on_button_focus_entered.bind(button)):
			button.focus_entered.connect(_on_button_focus_entered.bind(button))
		if not button.focus_exited.is_connected(_on_button_focus_exited.bind(button)):
			button.focus_exited.connect(_on_button_focus_exited.bind(button))

	_connect_focus_tint(language_button)
	if gamepad_focus_active:
		_focus_first_button_in(page)


func _focus_first_visible_button() -> void:
	if not gamepad_focus_active:
		return
	for page in pages.get_children():
		if page is Control and page.is_visible_in_tree():
			if _focus_first_button_in(page):
				return


func _focus_first_button_in(root: Control) -> bool:
	for node in root.find_children("*", "Button", true, false):
		var button := node as Button
		if (
			button
			and button.is_visible_in_tree()
			and not button.disabled
			and button.focus_mode != Control.FOCUS_NONE
		):
			button.grab_focus()
			return true
	return false


func _visible_back_button() -> Button:
	var result: Button = null
	for node in pages.find_children("BackButton", "Button", true, false):
		var button := node as Button
		if button and button.is_visible_in_tree() and not button.disabled:
			result = button
	return result


func _is_gamepad_navigation_event(event: InputEvent) -> bool:
	if event is InputEventJoypadButton:
		return event.pressed
	if event is InputEventJoypadMotion:
		return abs(event.axis_value) >= 0.5 and event.axis in [0, 1]
	return false


func _on_button_focus_entered(button: Button) -> void:
	button.self_modulate = (
		CONTROLLER_FOCUS_TINT if gamepad_focus_active else Color.WHITE
	)


func _on_button_focus_exited(button: Button) -> void:
	button.self_modulate = Color.WHITE


func _connect_focus_tint(button: Button) -> void:
	if not button:
		return
	var entered := _on_button_focus_entered.bind(button)
	var exited := _on_button_focus_exited.bind(button)
	if not button.focus_entered.is_connected(entered):
		button.focus_entered.connect(entered)
	if not button.focus_exited.is_connected(exited):
		button.focus_exited.connect(exited)


func _setup_language_navigation() -> void:
	if not language_button or not home_start_button or not exit_button:
		return
	_connect_focus_tint(language_button)
	home_start_button.focus_neighbor_top = home_start_button.get_path_to(language_button)
	exit_button.focus_neighbor_bottom = exit_button.get_path_to(language_button)
	language_button.focus_neighbor_top = language_button.get_path_to(exit_button)
	language_button.focus_neighbor_bottom = language_button.get_path_to(home_start_button)


func _on_joy_connection_changed(_device: int, connected: bool) -> void:
	gamepad_focus_active = connected or not Input.get_connected_joypads().is_empty()
	if gamepad_focus_active:
		_focus_first_visible_button.call_deferred()
		return

	for button in _all_focus_buttons():
		button.self_modulate = Color.WHITE
	var focused := get_viewport().gui_get_focus_owner()
	if focused is Button and focused in _all_focus_buttons():
		focused.release_focus()


func _all_focus_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	if pages:
		for node in pages.find_children("*", "Button", true, false):
			var button := node as Button
			if button:
				buttons.append(button)
	if language_button:
		buttons.append(language_button)
	return buttons
