extends PanelContainer

const LAYER = preload("res://UI/Layers/Layer.tscn")

onready var _layer_box = $VBoxContainer2/LayersVBox
var layer_button_group : ButtonGroup
onready var curr_layer = $VBoxContainer2/LayersVBox/Layer

# Called when the node enters the scene tree for the first time.
func _ready():
	curr_layer.connect("switch_layers", self, "_on_switch_layers")
	layer_button_group = ButtonGroup.new()
	curr_layer.layer_button.group = layer_button_group
	curr_layer.layer_button.pressed = true

func _on_AddLayer_pressed():
	var layer = LAYER.instance()
	
	_layer_box.add_child(layer)
	_layer_box.move_child(layer, 0)
	layer.layer_button.group = layer_button_group
	
	var active_project: Project = ProjectManager.get_active_project()
	layer.text = "Layer " + str(active_project.layers.size())
	active_project.layers.append([active_project.layers.size()])
	layer.connect("switch_layers", self, "_on_switch_layers")

#	print("Current project layers: ")
#	print(active_project.layers)

func _on_DeleteLayer_pressed():
	var index_to_del = curr_layer.get_index()
	if _layer_box.get_child_count() > 1:
		var active_project: Project = ProjectManager.get_active_project()
		var curr_layer_index = _layer_box.get_child_count() - curr_layer.get_index() - 1
		active_project.layers.remove(curr_layer_index)
		_layer_box.remove_child(curr_layer)
		
		# Select existing layer intead
		var below_index = min(_layer_box.get_child_count() - 1, index_to_del)
		_layer_box.get_child(below_index).layer_button.pressed = true	
		curr_layer = _layer_box.get_child(below_index)
#
#		print("Current project layers: ")
#		print(active_project.layers)
	else:
		print("Must have at least 1 layer. Cannot delete.")

func _on_switch_layers(node):
	# Find which add layer pressed/on - NOTE: layer count is bottom-up, so inverted
	var curr_layer_index = _layer_box.get_child_count() - node.get_index() - 1
	print("Switch to layer " + str(curr_layer_index))
	
	curr_layer = node

# Shift current layer up and down
func _on_ShiftUp_pressed():
	var new_pos = max(0, curr_layer.get_index() - 1)
	_layer_box.move_child(curr_layer, new_pos)

	var active_project: Project = ProjectManager.get_active_project()
	var old_pos = _layer_box.get_child_count() - new_pos - 2
	var temp_layer_strokes = active_project.layers[old_pos].duplicate()
	active_project.layers.remove(old_pos)
	active_project.layers.insert(min(_layer_box.get_child_count() - 1, _layer_box.get_child_count() - new_pos - 1), temp_layer_strokes)
	
#	print("Moved to pos " + str(_layer_box.get_child_count() - new_pos - 1))
#	print("Current project layers: ")
#	print(active_project.layers)

func _on_ShiftDown_pressed():
	var new_pos = min(_layer_box.get_child_count() - 1, curr_layer.get_index() + 1)
	_layer_box.move_child(curr_layer, new_pos)
	
	var active_project: Project = ProjectManager.get_active_project()
	var old_pos = _layer_box.get_child_count() - new_pos 
	var temp_layer_strokes = active_project.layers[old_pos].duplicate()
	active_project.layers.remove(old_pos)
	active_project.layers.insert(max(0, _layer_box.get_child_count() - new_pos - 1), temp_layer_strokes)
	
#	print("Moved to pos " + str(_layer_box.get_child_count() - new_pos - 1))
#	print("Current project layers: ")
#	print(active_project.layers)
