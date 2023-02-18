extends PanelContainer

const LAYER = preload("res://UI/Layers/Layer.tscn")

onready var _layer_box = $VBoxContainer2/LayersVBox
var layer_button_group : ButtonGroup
onready var curr_layer = $VBoxContainer2/LayersVBox/Layer

signal layers_swap(layer1, layer2) # Indices of layer swap
signal add_layer(index)
signal delete_layer(index)
signal set_active_layer(index)

# Called when the node enters the scene tree for the first time.
func _ready():
	curr_layer.connect("switch_layers", self, "_on_switch_layers")
	layer_button_group = ButtonGroup.new()
	curr_layer.layer_button.group = layer_button_group
	curr_layer.layer_button.pressed = true

func _on_AddLayer_pressed():
	var active_project: Project = ProjectManager.get_active_project()
	var index = active_project.layers.size()

	active_project.undo_redo.create_action("Add Layer")
	active_project.undo_redo.add_undo_method(self, "_on_delete_layer", index)
	active_project.undo_redo.add_do_method(self, "_on_add_layer", index) # Re-add layer to the "top"/end of array, which is at this index
	active_project.undo_redo.commit_action()

# Add layer at index based on project.layers array
func _on_add_layer(index):
	var layer = LAYER.instance()
	
	var child_index = _layer_box.get_child_count() - index
	_layer_box.add_child(layer)
	_layer_box.move_child(layer, child_index)
	layer.layer_button.group = layer_button_group
	
	var active_project: Project = ProjectManager.get_active_project()
	layer.text = "Layer " + str(index)
	active_project.layers.insert(index, [])
	layer.connect("switch_layers", self, "_on_switch_layers")
	
	# Communicate with canvas layer
	emit_signal("add_layer", index)

# Delete layer at index based on project.layers array; re-selection NOT handeled
func _on_delete_layer(index):
	if _layer_box.get_child_count() > 1:
		var active_project: Project = ProjectManager.get_active_project()
		active_project.layers.remove(index)
		_layer_box.remove_child(_layer_box.get_child(_layer_box.get_child_count() - 1 - index))
		
		emit_signal("delete_layer", index)
	else:
		print("Must have at least 1 layer. Cannot delete.")

func _undo_delete_layer(index):
	# (code taken from add_layer. TODO: refactor)
	var layer = LAYER.instance()
	
	var child_index = _layer_box.get_child_count() - index
	_layer_box.add_child(layer)
	_layer_box.move_child(layer, child_index)
	layer.layer_button.group = layer_button_group
	
	var active_project: Project = ProjectManager.get_active_project()
	layer.text = "Layer " + str(index)
	active_project.layers.insert(index, [])
	layer.connect("switch_layers", self, "_on_switch_layers")
	
	# Emit signal to re-add SAME layer as before
#	emit_signal("undo_delete_layer", index) # TODO

func _on_DeleteLayer_pressed():
	# Delete current layer
	var index = _layer_box.get_child_count() - 1 - curr_layer.get_index()
	
	# TODO: RE-ADD STROKES - IDEA: already built-in to re-add strokes in correct order
	# SO instead make unique functions: add_layer must add and delete_layer must delete the SAME LAYER --> safe as reference
	var active_project: Project = ProjectManager.get_active_project()
	active_project.undo_redo.create_action("Add Layer")
	active_project.undo_redo.add_undo_method(self, "_on_add_layer", index)
#	active_project.undo_redo.add_undo_method(self, "_undo_delete_layer", index)
	# TODO: Save deleted layer as reference?
	active_project.undo_redo.add_undo_property(active_project, "layers", active_project.layers)
	active_project.undo_redo.add_do_method(self, "_on_delete_layer", index)
	active_project.undo_redo.commit_action()
	
	if _layer_box.get_child_count() > 1:
		# Select existing layer intead
		var below_index = min(_layer_box.get_child_count() - 1, index)
		_layer_box.get_child(below_index).layer_button.pressed = true	
		curr_layer = _layer_box.get_child(below_index)

func _on_switch_layers(node):
	# Find which add layer pressed/on - NOTE: layer count is bottom-up, so inverted
	var curr_layer_index = _layer_box.get_child_count() - node.get_index() - 1
	print("Switch to layer " + str(curr_layer_index))
	
	var active_project: Project = ProjectManager.get_active_project()
	active_project.curr_layer = curr_layer_index
	active_project.strokes = active_project.layers[curr_layer_index]
	curr_layer = node
	
	emit_signal("set_active_layer", curr_layer_index)

# Shift current layer up and down
func _on_ShiftUp_pressed():
	var new_pos = max(0, curr_layer.get_index() - 1)
	_layer_box.move_child(curr_layer, new_pos)

	var active_project: Project = ProjectManager.get_active_project()
	var old_index = _layer_box.get_child_count() - new_pos - 2
	var temp_layer_strokes = active_project.layers[old_index].duplicate()
	active_project.layers.remove(old_index)
	var new_index = min(_layer_box.get_child_count() - 1, _layer_box.get_child_count() - new_pos - 1)
	active_project.layers.insert(new_index, temp_layer_strokes)
	
	emit_signal("layers_swap", old_index, new_index)

func _on_ShiftDown_pressed():
	var new_pos = min(_layer_box.get_child_count() - 1, curr_layer.get_index() + 1)
	_layer_box.move_child(curr_layer, new_pos)
	
	var active_project: Project = ProjectManager.get_active_project()
	var old_index = _layer_box.get_child_count() - new_pos 
	var temp_layer_strokes = active_project.layers[old_index].duplicate()
	active_project.layers.remove(old_index)
	var new_index = max(0, _layer_box.get_child_count() - new_pos - 1)
	active_project.layers.insert(new_index, temp_layer_strokes)
	
	emit_signal("layers_swap", old_index, new_index)
