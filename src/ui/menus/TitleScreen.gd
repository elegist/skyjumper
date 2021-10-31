extends Control

onready var animation_player = $AnimationPlayer

onready var main_menu = $MarginContainer/MainMenu
onready var settings_menu = $MarginContainer/SettingsMenu
onready var about_menu = $MarginContainer/AboutMenu

onready var start_button = $MarginContainer/MainMenu/ButtonStart

onready var back_button_about = $MarginContainer/AboutMenu/ButtonBack

#settings related
onready var resolution_options = $MarginContainer/SettingsMenu/Resolution/OptionsResolution
onready var fullscreen_checkbox = $MarginContainer/SettingsMenu/Fullscreen/CheckBoxFullscreen
onready var audio_slider = $MarginContainer/SettingsMenu/Audio/HSliderAudio

func _ready() -> void:
	start_button.grab_focus()

func _on_ButtonStart_pressed() -> void:
	SceneChanger.change_scene("res://src/levels/stage01/Stage01.tscn", "Fade")


func _on_ButtonSettings_pressed() -> void:
	main_menu.visible = false
	settings_menu.visible = true
	resolution_options.grab_focus()


func _on_ButtonAbout_pressed() -> void:
	main_menu.visible = false
	about_menu.visible = true
	back_button_about.grab_focus()


func _on_ButtonQuit_pressed() -> void:
	get_tree().quit()


func _on_ButtonBack_pressed() -> void:
	settings_menu.visible = false
	about_menu.visible = false
	main_menu.visible = true
	start_button.grab_focus()


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
