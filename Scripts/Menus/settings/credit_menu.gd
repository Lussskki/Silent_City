extends Node

const BACK_BUTTON_SIZE := Vector2(260.0, 40.0)
const BACK_PNG := "res://Resources/Buttons/menu_button_start.png"

var credits_page: VBoxContainer = null
var settings_page: VBoxContainer = null
var credits_header: Label = null
var credits_text: RichTextLabel = null
var back_button: Button = null

var show_page_callback
var translate_callback
var apply_button_sprite_callback

var configured := false


func setup(
	pages: Control,
	settings_page_node: VBoxContainer,
	services: Dictionary
) -> void:
	if configured:
		return
	if not pages:
		return

	settings_page = settings_page_node

	show_page_callback = services.get("show_page")
	translate_callback = services.get("translate")
	apply_button_sprite_callback = services.get("apply_button_sprite")

	credits_page = pages.get_node_or_null("Credits") as VBoxContainer
	if not credits_page:
		return

	credits_header = credits_page.get_node_or_null("Header") as Label
	credits_text = credits_page.get_node_or_null(
		"CreditsScroll/CreditsText"
	) as RichTextLabel
	back_button = credits_page.get_node_or_null("BackButton") as Button

	if back_button:
		_apply_button_sprite(
			back_button,
			BACK_PNG,
			BACK_BUTTON_SIZE
		)
		back_button.pressed.connect(_back_to_settings)

	if credits_text:
		credits_text.meta_clicked.connect(_open_credits_link)

	refresh_language()
	configured = true


func open() -> void:
	if not configured:
		return

	refresh_language()
	_show_page(credits_page)


func refresh_language() -> void:
	if credits_header:
		credits_header.text = _t("credits")
	if credits_text:
		credits_text.text = _t("credits_text")
	if back_button:
		back_button.text = _t("back")


func _open_credits_link(meta: Variant) -> void:
	var url := String(meta)

	if url.begins_with("https://"):
		OS.shell_open(url)


func _back_to_settings() -> void:
	_show_page(settings_page)


func _apply_button_sprite(
	button: Button,
	texture_path: String,
	size: Vector2
) -> void:
	if (
		apply_button_sprite_callback is Callable
		and apply_button_sprite_callback.is_valid()
	):
		apply_button_sprite_callback.call(button, texture_path, size)


func _show_page(page: Control) -> void:
	if (
		show_page_callback is Callable
		and show_page_callback.is_valid()
	):
		show_page_callback.call(page)


func _t(key: String) -> String:
	if (
		translate_callback is Callable
		and translate_callback.is_valid()
	):
		return String(translate_callback.call(key))

	return key
