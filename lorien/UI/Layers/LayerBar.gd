extends PanelContainer

const LAYER = preload("res://UI/Layers/Layer.tscn")

onready var _canvas = get_parent().get_node("InfiniteCanvas") # TODO: better way referene
onready var _layer_box = $VBoxContainer2/ScrollContainer/LayersVBox
var layer_button_group : ButtonGroup
onready var curr_layer = $VBoxContainer2/ScrollContainer/LayersVBox/Layer

signal layers_swap(layer1, layer2) # Indices of layer swap
signal add_layer(index)
signal delete_layer(index, selected_index)
signal set_active_layer(index)
signal undo_delete_layer(index, strokes)
signal layer_visibility_changed(index, is_visible)
signal copy_layer(from_index, to_index)
signal toggle_onion_skin(enabled)

# Called when the node enters the scene tree for the first time.
func _ready():
	curr_layer.connect("switch_layers", self, "_on_switch_layers")
	curr_layer.connect("layer_visibility_changed", self, "_on_layer_visibility_changed")
	curr_layer.connect("dups_amount_changed", self, "_on_dups_amount_changed")
	layer_button_group = ButtonGroup.new()
	curr_layer.layer_button.group = layer_button_group
	curr_layer.layer_button.pressed = true

func _on_AddLayer_pressed():
	var active_project: Project = ProjectManager.get_active_project()
	var index = min(active_project.layers.size(), _layer_box.get_child_count() - curr_layer.get_index())

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
	layer.text = "Layer " + str(active_project.layers.size())
	active_project.add_layer(index, [])
	layer.connect("switch_layers", self, "_on_switch_layers")
	layer.connect("layer_visibility_changed", self, "_on_layer_visibility_changed")
	layer.connect("dups_amount_changed", self, "_on_dups_amount_changed")
	
	# Communicate with canvas layer
	emit_signal("add_layer", index)
	
	# Select new layer
	select_layer(index) 

# Select new layer; index based on projects.layers array; inverse of children order
func select_layer(index):
	# Highlight correct layer
	_layer_box.get_child(_layer_box.get_child_count() - 1 - index).layer_button.pressed = true	
	curr_layer = _layer_box.get_child(_layer_box.get_child_count() - 1 - index)
	# Project data
	var active_project: Project = ProjectManager.get_active_project()
	active_project.curr_layer = index
	emit_signal("set_active_layer", index)

# Delete layer at index based on project.layers array; handles re-selection
func _on_delete_layer(index):
	if _layer_box.get_child_count() > 1:
		# Select current layer index (starting from bottom = 0) by default
		var selected_index = _layer_box.get_child_count() - 1 - curr_layer.get_index()
		
		var active_project: Project = ProjectManager.get_active_project()
		active_project.remove_layer(index)
		var layer = _layer_box.get_child(_layer_box.get_child_count() - 1 - index)
		_layer_box.remove_child(layer)
		var need_reselection = curr_layer == layer
		layer.queue_free()
		
		emit_signal("delete_layer", index)
		
		# Make sure to select top layer or lower now that we have one less layer
		selected_index = min(selected_index, _layer_box.get_child_count() - 1)
		
		# Select existing layer intead
		if need_reselection:
			var below_index = min(_layer_box.get_child_count() - 1, index)
			selected_index = below_index
		select_layer(selected_index)
	else:
		print("Must have at least 1 layer. Cannot delete.")

func _on_DeleteLayer_pressed():
	# Delete current layer
	var index = _layer_box.get_child_count() - 1 - curr_layer.get_index()
	
	var active_project: Project = ProjectManager.get_active_project()
	active_project.undo_redo.create_action("Delete Layer")
	# TODO: save layer information eg., visibility
	active_project.undo_redo.add_undo_method(self, "_on_add_layer", index)
	active_project.undo_redo.add_undo_method(self, "emit_signal", "undo_delete_layer", index, active_project.layers[index])
	active_project.undo_redo.add_undo_property(active_project, "layers", active_project.layers) # TODO: What this does?
	active_project.undo_redo.add_do_method(self, "_on_delete_layer", index)
	active_project.undo_redo.commit_action()

func _on_switch_layers(node):
	# Find which add layer pressed/on - NOTE: layer count is bottom-up, so inverted
	var curr_layer_index = _layer_box.get_child_count() - node.get_index() - 1
#	print("Switch to layer " + str(curr_layer_index))
	
	var active_project: Project = ProjectManager.get_active_project()
	active_project.curr_layer = curr_layer_index
	active_project.strokes = active_project.layers[curr_layer_index]
	curr_layer = node
	
	emit_signal("set_active_layer", curr_layer_index)
	
func _on_layer_visibility_changed(node, is_layer_visible):
	emit_signal("layer_visibility_changed", _layer_box.get_child_count() - 1 - node.get_index(), is_layer_visible)

# Shift current layer up and down
func _on_ShiftUp_pressed():
	var active_project: Project = ProjectManager.get_active_project()
	active_project.undo_redo.create_action("Shift Up Layer")
	active_project.undo_redo.add_undo_method(self, "shift_down", curr_layer.get_index())
	active_project.undo_redo.add_do_method(self, "shift_up", curr_layer.get_index())
	active_project.undo_redo.commit_action()
	
func shift_up(layer_index):
	var new_pos = max(0, layer_index - 1)
	_layer_box.move_child(_layer_box.get_child(layer_index), new_pos)

	var active_project: Project = ProjectManager.get_active_project()
	var old_index = _layer_box.get_child_count() - new_pos - 2
	var temp_layer_strokes = active_project.layers[old_index].duplicate()
	var temp_layer_dups_amt = active_project.layers_info[old_index].dup_amount
	active_project.remove_layer(old_index)
	var new_index = min(_layer_box.get_child_count() - 1, _layer_box.get_child_count() - new_pos - 1)
	active_project.add_layer(new_index, temp_layer_strokes, temp_layer_dups_amt)
	
	emit_signal("layers_swap", old_index, new_index)
	active_project.curr_layer = new_index

func _on_ShiftDown_pressed():
	var active_project: Project = ProjectManager.get_active_project()
	active_project.undo_redo.create_action("Shift Up Layer")
	active_project.undo_redo.add_undo_method(self, "shift_up", curr_layer.get_index())
	active_project.undo_redo.add_do_method(self, "shift_down", curr_layer.get_index())
	active_project.undo_redo.commit_action()
	
func shift_down(layer_index):
	var new_pos = min(_layer_box.get_child_count() - 1, layer_index + 1)
	_layer_box.move_child(_layer_box.get_child(layer_index), new_pos)
	
	var active_project: Project = ProjectManager.get_active_project()
	var old_index = _layer_box.get_child_count() - new_pos 
	var temp_layer_strokes = active_project.layers[old_index].duplicate()
	var temp_layer_dups_amt = active_project.layers_info[old_index].dup_amount
	active_project.remove_layer(old_index)
	var new_index = max(0, _layer_box.get_child_count() - new_pos - 1)
	active_project.add_layer(new_index, temp_layer_strokes, temp_layer_dups_amt)
	
	emit_signal("layers_swap", old_index, new_index)
	active_project.curr_layer = new_index

func _on_Toolbar_layers_menu_toggle(visible):
	self.visible = visible

func _on_DuplicateLayer_pressed():
	var active_project: Project = ProjectManager.get_active_project()
	var index = min(active_project.layers.size(), _layer_box.get_child_count() - curr_layer.get_index())

	active_project.undo_redo.create_action("Duplicate Layer")
	active_project.undo_redo.add_undo_method(self, "_on_delete_layer", index)
	active_project.undo_redo.add_do_method(self, "_on_add_layer", index)
	active_project.undo_redo.add_do_method(self, "_on_copy_layer", _layer_box.get_child_count() - 1 - curr_layer.get_index(), index)
	active_project.undo_redo.commit_action()
	
# Copy layer information from_index to_index
func _on_copy_layer(from_index, to_index):
	# Assumes layer already exists; will OVERWRITE layer information
	emit_signal("copy_layer", from_index, to_index)
	
func _on_dups_amount_changed(node, value):
	var index = _layer_box.get_child_count() - 1 - node.get_index()
	var active_project: Project = ProjectManager.get_active_project()
	
	active_project.layers_info[index].dup_amount = value

func _on_OnionSkin_toggled(enabled):
	emit_signal("toggle_onion_skin", enabled)
