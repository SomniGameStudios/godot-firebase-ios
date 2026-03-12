extends Control

var auth_scene = preload("res://scenes/authentication.tscn")
var firestore_scene = preload("res://scenes/firestore.tscn")
var remote_config_scene = preload("res://scenes/remote_config.tscn")

func _on_auth_pressed() -> void:
	get_tree().change_scene_to_packed(auth_scene)

func _on_firestore_pressed() -> void:
	get_tree().change_scene_to_packed(firestore_scene)

func _on_remote_config_pressed() -> void:
	get_tree().change_scene_to_packed(remote_config_scene)
