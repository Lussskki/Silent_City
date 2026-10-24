extends SceneTree

const MENU_SCENE := "res://Scenes/MainMenu.tscn"
const REMOVED_LEVEL_SCENES := [
	"res://Scenes/MediumMap.tscn",
	"res://Scenes/HardMap.tscn",
	"res://Scenes/MainMedium.tscn",
	"res://Scenes/MainHard.tscn",
]
const SQUAD_FRAME_RESOURCES := [
	"res://Resources/squad_crusader_sprite_frames.tres",
	"res://Resources/squad_wraith_sprite_frames.tres",
	"res://Resources/squad_minotaur_sprite_frames.tres",
	"res://Resources/squad_ranger_sprite_frames.tres",
]


func _init() -> void:
	var failed := false
	var packed := load(MENU_SCENE) as PackedScene
	failed = _check(packed != null, "main menu scene loads") or failed
	if packed == null:
		quit(1)
		return

	var menu := packed.instantiate()
	for script_path in [
		"res://Characters/Active_Players/Player/player.gd",
		"res://Scripts/online_manager.gd",
		"res://Scripts/online_manager_NO_WIFI.gd",
		"res://Scripts/Menus/difficulty/difficulty_menu.gd",
		"res://Scripts/Menus/choose_character/character_menu.gd",
	]:
		failed = _check(load(script_path) is Script, "%s parses" % script_path) or failed
	var cards := menu.get_node("Content/Root/Pages/ChooseLevel/MapCards")
	var card_names: Array[String] = []
	for card in cards.get_children():
		card_names.append(card.name)
	failed = _check(card_names == ["EasyButton"], "Difficulty contains only Easy") or failed
	failed = _check(
		not menu.get_node("Content/Root/Pages/ModeSelect/SquadButton").visible,
		"Start mode Squad button is hidden"
	) or failed
	failed = _check(
		not menu.get_node("Content/Root/Pages/Home/OnlineButton").visible,
		"home Online/Steam entry is hidden"
	) or failed
	failed = _check(
		not menu.get_node("Content/Root/Pages/ChooseCharacter/OnlineButton").visible,
		"character Online entry is hidden"
	) or failed

	for scene_path in REMOVED_LEVEL_SCENES:
		failed = _check(not FileAccess.file_exists(scene_path), "%s is deleted" % scene_path) or failed

	var startup_sources := (
		FileAccess.get_file_as_string("res://Characters/Active_Players/Player/player.gd")
		+ FileAccess.get_file_as_string("res://Scripts/online_manager.gd")
		+ FileAccess.get_file_as_string("res://Scripts/online_manager_NO_WIFI.gd")
	)
	for resource_path in SQUAD_FRAME_RESOURCES:
		failed = _check(
			startup_sources.find(resource_path.get_file()) == -1,
			"startup code does not import %s" % resource_path.get_file()
		) or failed
		failed = _check(
			not FileAccess.file_exists(resource_path),
			"squad SpriteFrame manifest is deleted: %s" % resource_path
		) or failed

	menu.free()
	if failed:
		quit(1)
		return
	print("Menu cleanup validation passed: Easy/story UI only; squad and online entries hidden")
	quit()


func _check(condition: bool, message: String) -> bool:
	if condition:
		return false
	push_error("Menu cleanup validation failed: %s" % message)
	return true
