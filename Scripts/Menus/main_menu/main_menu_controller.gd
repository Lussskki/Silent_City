extends Node

signal start_requested
signal difficulty_preview_requested
signal character_requested
signal online_requested
signal settings_requested
signal exit_requested

var pages: Control = null
var home_page: Control = null

var home_start_button: Button = null
var home_map_button: Button = null
var home_choose_button: Button = null
var home_online_button: Button = null
var settings_button: Button = null
var exit_button: Button = null

var configured := false


func setup(nodes: Dictionary) -> void:
	if configured:
		return

	pages = nodes.get("pages") as Control
	home_page = nodes.get("home_page") as Control

	home_start_button = nodes.get("home_start_button") as Button
	home_map_button = nodes.get("home_map_button") as Button
	home_choose_button = nodes.get("home_choose_button") as Button
	home_online_button = nodes.get("home_online_button") as Button
	settings_button = nodes.get("settings_button") as Button
	exit_button = nodes.get("exit_button") as Button

	if home_start_button:
		home_start_button.pressed.connect(
			func(): start_requested.emit()
		)

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

	configured = true


func show_page(page: Control) -> void:
	if not pages or not page:
		return

	for child in pages.get_children():
		if child is Control:
			child.visible = child == page


func show_home() -> void:
	show_page(home_page)
