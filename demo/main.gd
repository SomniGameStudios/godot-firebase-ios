extends Control

var auth_scene = preload("res://scenes/authentication.tscn")

func _on_auth_pressed() -> void:
	get_tree().change_scene_to_packed(auth_scene)
