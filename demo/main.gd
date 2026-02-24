extends Control

var auth_scene = preload("res://scenes/authentication.tscn")
var firestore_scene = preload("res://scenes/firestore.tscn")

func _on_auth_pressed() -> void:
	get_tree().change_scene_to_packed(auth_scene)

func _on_firestore_pressed() -> void:
	get_tree().change_scene_to_packed(firestore_scene)
