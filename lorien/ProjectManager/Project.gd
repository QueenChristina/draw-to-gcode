class_name Project

var id: int # this is used at runtime only and will not be persisted; project ids are not garanteed to be the same between restarts
var undo_redo: UndoRedo

var dirty := false
var loaded := false

var filepath: String
var meta_data: Dictionary
var strokes: Array # Array<BrushStroke> # Current layer strokes [TODO: reference layers[curr_layer]

var curr_layer : int = 0 setget set_curr_layer # Current layer we are on, as index of layers
var layers : Array  = [[]] # Array<Array<BrushStroke>> # Array of strokes, 0 = bottom-most layer
var layers_info : Array = [{"dup_amount" : 1}] # Array<Dict{dup_amount: #, etc.}>
# -------------------------------------------------------------------------------------------------
func _init():
	undo_redo = UndoRedo.new()
	
	strokes = layers[0]

# -------------------------------------------------------------------------------------------------
func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if undo_redo != null:
			undo_redo.free()

# -------------------------------------------------------------------------------------------------
func clear() -> void:
	undo_redo.free()
	undo_redo = null
	meta_data.clear()
	strokes.clear()

# -------------------------------------------------------------------------------------------------
func add_stroke(stroke: BrushStroke, layer_index = curr_layer) -> void:
#	print("From ", layers)
	layers[layer_index].append(stroke)
	# TODO: fix all references to strokes not updating layers, and do not repeat
	if layer_index == curr_layer:
		strokes = layers[layer_index]
#	print("Changed to ", layers)
	dirty = true

# -------------------------------------------------------------------------------------------------
func remove_last_stroke(layer_index = curr_layer) -> void:
	if !layers[layer_index].empty():
		layers[layer_index].pop_back()
	if layer_index == curr_layer:
		strokes = layers[layer_index]
	
# -------------------------------------------------------------------------------------------------
func get_filename() -> String:
	if filepath.empty():
		return "Untitled"
	return filepath.get_file()

# -------------------------------------------------------------------------------------------------
func _to_string() -> String:
	return "%s: id: %d, loaded: %s, dirty: %s" % [filepath, id, loaded, dirty]

func set_curr_layer(layer_index):
	curr_layer = layer_index
	strokes = layers[curr_layer]
	
func add_layer(index, layer_strokes, dups_amount = 1):
	layers.insert(index, layer_strokes)
	layers_info.insert(index, {"dup_amount" : dups_amount})
	
func remove_layer(index):
	layers.remove(index)
	layers_info.remove(index)
