extends Control

@onready var output_panel = $MarginContainer/VBoxContainer/OutputPanel
@onready var path = $MarginContainer/VBoxContainer/ScrollContainer/ButtonContainer/HBoxContainer/path
@onready var pair_container = $ManageDataPanel/VBoxContainer/ScrollContainer/key_value_pair_container


func _ready() -> void:
	FirebaseIOS.rtdb.write_task_completed.connect(print_output.bind("write_task_completed"))
	FirebaseIOS.rtdb.get_task_completed.connect(print_output.bind("get_task_completed"))
	FirebaseIOS.rtdb.update_task_completed.connect(print_output.bind("update_task_completed"))
	FirebaseIOS.rtdb.delete_task_completed.connect(print_output.bind("delete_task_completed"))
	FirebaseIOS.rtdb.db_value_changed.connect(print_listener_output.bind("db_value_changed"))


func _log(message: String) -> void:
	var time = Time.get_time_string_from_system()
	output_panel.text += "[%s] %s\n" % [time, message]


func get_dictionary_from_inputs() -> Dictionary:
	var data_dict := Dictionary()
	for pair in pair_container.get_children():
		if pair.name == "sample_pair":
			continue
		var key = pair.get_child(0).text
		var value = pair.get_child(1).text
		if pair.get_child(2).button_pressed:
			value = int(value)
		data_dict[key] = value
	return data_dict


func print_output(arg, context: String) -> void:
	_log(context + ": " + str(arg))


func print_listener_output(arg, arg2, context: String) -> void:
	_log(context + ": " + str(arg) + " -|- " + str(arg2))


func _on_clear_output_pressed() -> void:
	output_panel.text = ""


func _on_set_value_pressed() -> void:
	FirebaseIOS.rtdb.set_value(path.text, get_dictionary_from_inputs())


func _on_get_value_pressed() -> void:
	FirebaseIOS.rtdb.get_value(path.text)


func _on_update_value_pressed() -> void:
	FirebaseIOS.rtdb.update_value(path.text, get_dictionary_from_inputs())


func _on_delete_value_pressed() -> void:
	FirebaseIOS.rtdb.delete_value(path.text)


func _on_listen_to_path_pressed() -> void:
	FirebaseIOS.rtdb.listen_to_path(path.text)


func _on_stop_listening_pressed() -> void:
	FirebaseIOS.rtdb.stop_listening(path.text)


func _on_manage_data_pressed() -> void:
	$ManageDataPanel.show()


func _on_add_pair_pressed() -> void:
	var new_pair = $ManageDataPanel/VBoxContainer/ScrollContainer/key_value_pair_container/sample_pair.duplicate()
	new_pair.show()
	pair_container.add_child(new_pair)


func _on_close_pressed() -> void:
	$ManageDataPanel.hide()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_packed(load("res://main.tscn"))
