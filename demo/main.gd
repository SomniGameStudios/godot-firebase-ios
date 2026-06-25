extends Control

var manual_scene := preload("res://scenes/manual_menu.tscn")
var auto_scene := preload("res://scenes/auto_test.tscn")

func _on_manual_pressed() -> void:
	get_tree().change_scene_to_packed(manual_scene)

func _on_automatic_pressed() -> void:
	get_tree().change_scene_to_packed(auto_scene)
