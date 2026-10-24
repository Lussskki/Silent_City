extends Node2D

const INTERACTION_RADIUS := 190.0
const PROMPT_TEXT := "[E]  Talk to the Forwarder"
const QUESTION_TEXT := "Choose your path."
const ESCAPE_CONSUMED_META := &"forwarder_escape_consumed"
const SIGNPOST_ICON := "res://Sprites/Graveyard/GraveyardTileset_second/PNG/Environment/Forbidden_Graveyard_2D_Platformer_Tileset_Environment - Signpost 01.png"
const SKULL_ICON := "res://Sprites/Graveyard/GraveyardTileset_second/PNG/Environment/Forbidden_Graveyard_2D_Platformer_Tileset_Environment - Skull.png"
const CRYPT_ICON := "res://Sprites/Graveyard/GraveyardTileset_second/PNG/Environment/Forbidden_Graveyard_2D_Platformer_Tileset_Environment - Crypt.png"

const CHOICES := [
	{
		"title": "ROUTES",
		"response": "Search both routes.",
		"icon": SIGNPOST_ICON,
	},
	{
		"title": "HIDDEN BOSSES",
		"response": "Seek the hidden trials.",
		"icon": SKULL_ICON,
	},
	{
		"title": "CEMETERY",
		"response": "Enter the cemetery.",
		"icon": CRYPT_ICON,
	},
]

var player: Node2D
var forwarders: Array[Node2D] = []
var nearby_forwarder: Node2D
var dialogue_open := false

var prompt_panel: PanelContainer
var dialogue_overlay: ColorRect
var dialogue_text: Label
var portrait: AnimatedSprite2D
var choice_buttons: Array[Button] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = get_node_or_null("../Player") as Node2D
	for node_name in ["DownRouteForwarder", "UpRouteForwarder"]:
		var forwarder := get_node_or_null(node_name) as Node2D
		if forwarder:
			forwarders.append(forwarder)
	_build_interface()


func _process(_delta: float) -> void:
	if dialogue_open:
		return
	if get_tree().paused:
		prompt_panel.visible = false
		return

	nearby_forwarder = _find_nearby_forwarder()
	prompt_panel.visible = nearby_forwarder != null


func _unhandled_input(event: InputEvent) -> void:
	if dialogue_open:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("menu_back"):
			get_viewport().set_input_as_handled()
			get_tree().set_meta(ESCAPE_CONSUMED_META, true)
			_close_dialogue()
		return

	if nearby_forwarder and event.is_action_pressed("special_power"):
		get_viewport().set_input_as_handled()
		_open_dialogue()


func _find_nearby_forwarder() -> Node2D:
	if not is_instance_valid(player):
		player = get_node_or_null("../Player") as Node2D
	if not player:
		return null

	var closest: Node2D
	var closest_distance := INTERACTION_RADIUS
	for forwarder in forwarders:
		if not is_instance_valid(forwarder):
			continue
		var distance := player.global_position.distance_to(forwarder.global_position)
		if distance <= closest_distance:
			closest = forwarder
			closest_distance = distance
	return closest


func _open_dialogue() -> void:
	dialogue_open = true
	prompt_panel.visible = false
	dialogue_text.text = QUESTION_TEXT
	_sync_portrait_to_nearby_forwarder()
	dialogue_overlay.visible = true
	get_tree().paused = true
	choice_buttons[0].grab_focus()


func _sync_portrait_to_nearby_forwarder() -> void:
	if not portrait or not nearby_forwarder is AnimatedSprite2D:
		return
	var source := nearby_forwarder as AnimatedSprite2D
	portrait.sprite_frames = source.sprite_frames
	portrait.animation = source.animation
	portrait.flip_h = source.flip_h
	portrait.frame = source.frame
	portrait.play(source.animation)


func _close_dialogue() -> void:
	dialogue_open = false
	dialogue_overlay.visible = false
	get_tree().paused = false
	nearby_forwarder = _find_nearby_forwarder()
	prompt_panel.visible = nearby_forwarder != null


func _select_choice(index: int) -> void:
	dialogue_text.text = CHOICES[index]["response"]
	choice_buttons[index].grab_focus()


func _build_interface() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "ForwarderDialogueUI"
	canvas.layer = 90
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)

	prompt_panel = PanelContainer.new()
	prompt_panel.name = "TalkPrompt"
	prompt_panel.visible = false
	prompt_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	prompt_panel.anchor_left = 0.5
	prompt_panel.anchor_top = 1.0
	prompt_panel.anchor_right = 0.5
	prompt_panel.anchor_bottom = 1.0
	prompt_panel.offset_left = -170.0
	prompt_panel.offset_top = -92.0
	prompt_panel.offset_right = 170.0
	prompt_panel.offset_bottom = -36.0
	prompt_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.035, 0.055, 0.075, 0.94), Color(0.24, 0.58, 0.64, 1.0), 2))
	canvas.add_child(prompt_panel)

	var prompt_label := Label.new()
	prompt_label.text = PROMPT_TEXT
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 22)
	prompt_label.add_theme_color_override("font_color", Color(0.82, 0.95, 0.96, 1.0))
	prompt_panel.add_child(prompt_label)

	dialogue_overlay = ColorRect.new()
	dialogue_overlay.name = "DialogueOverlay"
	dialogue_overlay.visible = false
	dialogue_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	dialogue_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialogue_overlay.color = Color(0.008, 0.014, 0.024, 0.72)
	dialogue_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(dialogue_overlay)

	var card := PanelContainer.new()
	card.name = "DialogueCard"
	card.anchor_left = 0.5
	card.anchor_top = 0.5
	card.anchor_right = 0.5
	card.anchor_bottom = 0.5
	card.offset_left = -340.0
	card.offset_top = -190.0
	card.offset_right = 340.0
	card.offset_bottom = 190.0
	card.add_theme_stylebox_override("panel", _make_panel_style(Color(0.028, 0.043, 0.061, 0.98), Color(0.30, 0.66, 0.70, 1.0), 3))
	dialogue_overlay.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_bottom", 16)
	card.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)

	var title := Label.new()
	title.text = "THE FORWARDER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.47, 0.91, 0.90, 1.0))
	content.add_child(title)

	dialogue_text = Label.new()
	dialogue_text.text = QUESTION_TEXT
	dialogue_text.custom_minimum_size = Vector2(0, 32)
	dialogue_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_text.add_theme_font_size_override("font_size", 17)
	dialogue_text.add_theme_color_override("font_color", Color(0.85, 0.89, 0.91, 1.0))
	content.add_child(dialogue_text)

	var choices_row := HBoxContainer.new()
	choices_row.add_theme_constant_override("separation", 18)
	choices_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(choices_row)

	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(190.0, 235.0)
	portrait_frame.clip_contents = true
	portrait_frame.add_theme_stylebox_override("panel", _make_panel_style(Color(0.018, 0.029, 0.043, 0.92), Color(0.18, 0.38, 0.43, 1.0), 2))
	choices_row.add_child(portrait_frame)

	portrait = AnimatedSprite2D.new()
	portrait.name = "ForwarderPortrait"
	portrait.position = Vector2(95.0, 116.0)
	portrait.scale = Vector2(0.46, 0.46)
	portrait_frame.add_child(portrait)

	var button_column := VBoxContainer.new()
	button_column.add_theme_constant_override("separation", 8)
	button_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	choices_row.add_child(button_column)

	for index in CHOICES.size():
		var button := Button.new()
		button.name = "Choice%d" % (index + 1)
		button.text = CHOICES[index]["title"]
		button.icon = load(CHOICES[index]["icon"]) as Texture2D
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 58)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.custom_minimum_size = Vector2(0, 70)
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_font_size_override("font_size", 18)
		button.add_theme_constant_override("icon_separation", 18)
		button.add_theme_stylebox_override("normal", _make_panel_style(Color(0.045, 0.066, 0.082, 0.98), Color(0.16, 0.30, 0.34, 1.0), 1))
		button.add_theme_stylebox_override("hover", _make_panel_style(Color(0.075, 0.12, 0.14, 1.0), Color(0.30, 0.66, 0.70, 1.0), 2))
		button.add_theme_stylebox_override("pressed", _make_panel_style(Color(0.09, 0.15, 0.17, 1.0), Color(0.47, 0.91, 0.90, 1.0), 2))
		button.add_theme_stylebox_override("focus", _make_panel_style(Color(0.06, 0.095, 0.115, 1.0), Color(0.68, 0.94, 0.93, 1.0), 2))
		button.pressed.connect(_select_choice.bind(index))
		button_column.add_child(button)
		choice_buttons.append(button)

	var leave_hint := Label.new()
	leave_hint.text = "ESC  Back"
	leave_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	leave_hint.add_theme_font_size_override("font_size", 14)
	leave_hint.add_theme_color_override("font_color", Color(0.55, 0.64, 0.68, 1.0))
	content.add_child(leave_hint)


func _make_panel_style(background: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style
