extends HBoxContainer

# Layer information. TODO: save information, for undo/redo too
export var text = "Layer 0" setget set_layer_text
var is_layer_visible = true

onready var layer_button = $Button

signal switch_layers(node)
signal layer_visibility_changed(node, is_layer_visible)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_layer_text(layer_text):
	text = layer_text
	layer_button.text = text


func _on_LayerButton_pressed():
	emit_signal("switch_layers", self)

func _on_Hide_pressed():
	var active_project: Project = ProjectManager.get_active_project()
	active_project.undo_redo.create_action("Toggle Layer Visibility")
	active_project.undo_redo.add_undo_method(self, "toggle_layer_visibility")
	active_project.undo_redo.add_do_method(self, "toggle_layer_visibility") # Re-add layer to the "top"/end of array, which is at this index
	active_project.undo_redo.commit_action()
	
func toggle_layer_visibility():
	is_layer_visible = !is_layer_visible
	emit_signal("layer_visibility_changed", self, is_layer_visible)
	
#	# TODO: change icon 
#	if is_layer_visible:
#		$Hide.text = "*"
#	else:
#		$Hide.text = "-"
