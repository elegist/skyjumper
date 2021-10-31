extends Control

onready var resume_button = $MarginContainer/PauseMenu/ButtonResume
onready var resolution_options = $MarginContainer/SettingsMenu/Resolution/OptionsResolution

onready var settings_menu = $MarginContainer/SettingsMenu
onready var pause_menu = $MarginContainer/PauseMenu

onready var fullscreen_checkbox = $MarginContainer/SettingsMenu/Fullscreen/CheckBoxFullscreen

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		var pause_state = !get_tree().paused
		get_tree().paused = pause_state
		visible = pause_state
		if pause_state:
			pause_menu.visible = true
			settings_menu.visible = false
			resume_button.grab_focus()


func _on_ButtonResume_pressed() -> void:
	if get_tree().paused:
		get_tree().paused = false
		visible = false


func _on_ButtonRestart_pressed() -> void:
	assert(get_tree().reload_current_scene() == OK)
	get_tree().paused = false
	visible = false


func _on_ButtonSettings_pressed() -> void:
	pause_menu.visible = false
	settings_menu.visible = true
	resolution_options.grab_focus()

func _on_ButtonBack_pressed() -> void:
	pause_menu.visible = true
	settings_menu.visible = false
	resume_button.grab_focus()

func _on_ButtonMainMenu_pressed() -> void:
	SceneChanger.change_scene("res://src/levels/TitleScreenStage.tscn", "Fade")
	get_tree().paused = false


func _on_ButtonQuit_pressed() -> void:
	get_tree().quit()




func _on_CheckBoxFullscreen_toggled(button_pressed: bool) -> void:
	OS.window_fullscreen = !OS.window_fullscreen
	if button_pressed:
		fullscreen_checkbox.text = "On"
	else:
		fullscreen_checkbox.text = "Off"


func _on_OptionsResolution_item_selected(index: int) -> void:
	match index:
		0:
			OS.set_window_size(Vector2(1920, 1080))
		1:
			OS.set_window_size(Vector2(1280, 720))
		2:
			OS.set_window_size(Vector2(640, 360))
