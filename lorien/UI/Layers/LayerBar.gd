extends PanelContainer

# -------------------------------------------------------------------------------------------------
const BRUSH_STROKE = preload("res://BrushStroke/BrushStroke.tscn")
const LAYER = preload("res://UI/Layers/Layer.tscn")

onready var _canvas = get_parent().get_node("InfiniteCanvas") # TODO: better way referene
onready var _layer_box = $VBoxContainer2/ScrollContainer/LayersVBox
onready var curr_layer = $VBoxContainer2/ScrollContainer/LayersVBox/Layer
onready var fake_viewport = $"Node2D/ViewportContainer/FakeScreenGrabber"
onready var fake_viewport_parent = $Node2D

var layer_button_group : ButtonGroup
var loading_thumbnail = false

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

# Make layers from the given project
func make_layers(project, clear_layers = true):
	# Clear layers from menu
	for layer in _layer_box.get_children():
		_layer_box.remove_child(layer)
		if clear_layers:
			layer.queue_free()
		
	# Generate layers to menu
	for i in range(project.layers.size()):
		_add_layer_to_menu(i, "Layer " + str(i), project.layers_info[i].dup_amount)
	select_layer(0)
	
func _on_AddLayer_pressed():
	var active_project: Project = ProjectManager.get_active_project()
	var index = min(active_project.layers.size(), _layer_box.get_child_count() - curr_layer.get_index())

	active_project.undo_redo.create_action("Add Layer")
	active_project.undo_redo.add_undo_method(self, "_on_delete_layer", index)
	active_project.undo_redo.add_do_method(self, "_on_add_layer", index) # Re-add layer to the "top"/end of array, which is at this index
	active_project.undo_redo.commit_action()

# Add layer to menu only
func _add_layer_to_menu(index, name, dup_amount = 1):
	var layer = LAYER.instance()
	
	var child_index = _layer_box.get_child_count() - index
	_layer_box.add_child(layer)
	_layer_box.move_child(layer, child_index)
	layer.layer_button.group = layer_button_group
	
	layer.text = name
	layer.dup_edit.value = dup_amount
	layer.connect("switch_layers", self, "_on_switch_layers")
	layer.connect("layer_visibility_changed", self, "_on_layer_visibility_changed")
	layer.connect("dups_amount_changed", self, "_on_dups_amount_changed")

# Add layer at index based on project.layers array; modifies project array too
func _on_add_layer(index):
	var active_project: Project = ProjectManager.get_active_project()
	_add_layer_to_menu(index, "Layer " + str(active_project.layers.size()))
	active_project.add_layer(index, [])
	
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
	
# ----------------------------------------------------------------------------
# Set layer thumbnails - NOTE: layer index in terms of project layers, not layer_box index
func _on_refresh_layer_thumbnail(viewport : Viewport, layer_strokes : Node2D, layer_index : int):
	# TODO: limit refresh rate -- only update once in a while, and not when drawing
	var index = _layer_box.get_child_count() - 1 - layer_index
	
	fake_viewport_parent.show()
	var cpy_layer_strokes = copy_layer(layer_strokes)
	fake_viewport.add_child(cpy_layer_strokes)
	fake_viewport.move_child(cpy_layer_strokes, 0)
	var dims = _get_min_max_dimension(cpy_layer_strokes.get_children())
	var top_left = dims[0]
	var bottom_right = dims[1]
	# Capture all strokes: min and max of strokes
	var size = bottom_right - top_left 
	# Offset all strokes so top_left starts at 0,0
	cpy_layer_strokes.position = -top_left
	# For now, thumbnail should be square (and not squished/scaled to square). TODO: set to aspect ratio of canvas instead
	var square_size = max(size.x, size.y)
	fake_viewport.size = Vector2(square_size, square_size)
	# Everything starts at topleft, but center instead
	cpy_layer_strokes.position += -size/2 + fake_viewport.size/2
	
	# Add offset so offscreen and not visible
	fake_viewport_parent.position = Vector2(get_viewport_rect().position.x + get_viewport_rect().size.x + 1000, get_viewport_rect().position.y + get_viewport_rect().size.y +1000)
	
	# Wait until the frame has finished before getting the texture.
	yield(VisualServer, "frame_post_draw")

	# Retrieve the captured image.
	if !loading_thumbnail: # Not sure if this does anything ... attempt to avoid overcapturing
		loading_thumbnail = true
		var img = fake_viewport.get_texture().get_data()
		# Flip it on the y-axis (because it's flipped). + Set to size 32x32
		if img != null: # Error that pops up when you call this function too much too quickly
			img.flip_y()
			var layer = _layer_box.get_child(index)
			img.resize(35, 35)
			# Create a texture for it.
			var tex = ImageTexture.new()
			tex.create_from_image(img)
			# Set the texture to the captured image node.
			layer.thumbnail = tex
		else:
			print_debug("Image returned was null...viewport might still be active?")
		
	fake_viewport_parent.hide()
	fake_viewport.remove_child(fake_viewport.get_child(0)) # Clear previous strokes
	cpy_layer_strokes.queue_free()
	loading_thumbnail = false
	
# Returns [TOP LEFT corner, BOTTOM RIGHT corner] with fractional empty margin
func _get_min_max_dimension(strokes, EDGE_MARGIN := 0.1):
	# Calculate total canvas dimensions
	var max_dim := BrushStroke.MIN_VECTOR2
	var min_dim := BrushStroke.MAX_VECTOR2
	if strokes.size() <= 0:
		max_dim = Vector2(100, 100)
		min_dim = Vector2(0, 0)
	for stroke in strokes:
		min_dim.x = min(min_dim.x, stroke.top_left_pos.x)
		min_dim.y = min(min_dim.y, stroke.top_left_pos.y)
		max_dim.x = max(max_dim.x, stroke.bottom_right_pos.x)
		max_dim.y = max(max_dim.y, stroke.bottom_right_pos.y)
	var size := max_dim - min_dim
	var margin_size := size * EDGE_MARGIN
	return [min_dim - margin_size, max_dim + margin_size]
	
# (COPIED FROM SELECTIONTOOL.gd + Infinite canvas) TODO: refactor into a Utils.gd
func copy_layer(layer_strokes):
	# Copy strokes
	var copy_strokes = Node2D.new()
	for stroke in layer_strokes.get_children():
		var dup := _duplicate_stroke(stroke, Vector2(0, 0))
		copy_strokes.add_child(dup)
	return copy_strokes
	
func _duplicate_stroke(stroke: BrushStroke, offset: Vector2) -> BrushStroke:	
	var dup: BrushStroke = BRUSH_STROKE.instance()
	dup.global_position = stroke.global_position
	dup.size = stroke.size
	dup.color = stroke.color
	dup.axis = stroke.axis
	dup.pressures = stroke.pressures.duplicate()
	for point in stroke.points:
		dup.points.append(point + offset)
	return dup

