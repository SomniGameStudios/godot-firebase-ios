class_name SafeAreaContainer extends MarginContainer

func _ready() -> void:
	apply_safe_area()
	get_tree().get_root().size_changed.connect(apply_safe_area)

func apply_safe_area() -> void:
	var top_margin = 0

	if OS.has_feature("mobile"):
		var safe_area = DisplayServer.get_display_safe_area()
		var window_position = DisplayServer.window_get_position()
		var relative_position = Vector2i(
			safe_area.position.x - window_position.x,
			safe_area.position.y - window_position.y
		)

		top_margin = max(0, relative_position.y)
	else:
		var inset_top = 40
		top_margin = inset_top

	add_theme_constant_override("margin_top", top_margin)
