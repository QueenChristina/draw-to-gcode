extends HBoxContainer

# -------------------------------------------------------------------------------------------------
signal modified_binding(bindings_data)

# -------------------------------------------------------------------------------------------------
var _bindings_data := {}
var _preloaded_image := preload("res://Assets/Icons/delete.png")

# -------------------------------------------------------------------------------------------------
# Keybindings data: {"action": "str", "readable_name": "str", "events": [...]}
func set_keybindings_data(bindings_data: Dictionary) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free() # TODO: check this doesn't break anything

	_bindings_data = bindings_data
	for event in bindings_data["events"]:
		if event is InputEventKey:
			var remove_button = Button.new()
			remove_button.text = OS.get_scancode_string(event.get_scancode_with_modifiers())
			remove_button.icon = _preloaded_image
	
			remove_button.add_constant_override("hseparation", 6)
	
			remove_button.connect("pressed", self, "_remove_pressed", [event])
			add_child(remove_button)

# -------------------------------------------------------------------------------------------------
func _remove_pressed(event: InputEvent) -> void:
	_bindings_data["events"].erase(event)
	emit_signal("modified_binding", _bindings_data)
