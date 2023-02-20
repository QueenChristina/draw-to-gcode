class_name GCodeExporter
extends Reference

# TODOs
# - Stroke width / pressue data
var curr_point_abs = Vector2(0, 0) # Current point of nozzle in absolute coordinates, X, Y values only

# -------------------------------------------------------------------------------------------------
const EDGE_MARGIN := 0.025

# -------------------------------------------------------------------------------------------------
func export_gcode(layers: Array, layers_info : Array, path: String) -> void:
	var start_time := OS.get_ticks_msec()
	
	# Open file
	var file := File.new()
	var err := file.open(path, File.WRITE)
	if err != OK:
		printerr("Failed to open file for writing")
		return
	
	# Calculate total canvas dimensions
	var max_dim := BrushStroke.MIN_VECTOR2
	var min_dim := BrushStroke.MAX_VECTOR2
	for layer in layers:
		for stroke in layer:
			min_dim.x = min(min_dim.x, stroke.top_left_pos.x)
			min_dim.y = min(min_dim.y, stroke.top_left_pos.y)
			max_dim.x = max(max_dim.x, stroke.bottom_right_pos.x)
			max_dim.y = max(max_dim.y, stroke.bottom_right_pos.y)
	var size := max_dim - min_dim
	var margin_size := size * EDGE_MARGIN
	size += margin_size*2.0
	var origin := min_dim - margin_size
	
	curr_point_abs = Vector2(0, 0)
	
	# Write gcode to file
	var layer_count = 0
	var layer_height = Settings.get_value(Settings.LAYER_HEIGHT, Config.DEFAULT_LAYER_HEIGHT)
	var unit = Settings.get_value(Settings.UNIT, Config.DEFAULT_UNIT)
	var first_axis = "Z" 
	if layers[0].size() > 0:
		first_axis = layers[0][0].axis
	# TODO: order of axis printing per layer
	var axis_order = ["Z", "A"]
		
	# Start file with setting units to mm and set current X,Y as origin
	if unit.to_lower() == "inch":
		file.store_string("G91\nG20\nG92 X0.0 Y0.0\nG90\n")
	else:
		file.store_string("G91\nG21\nG92 X0.0 Y0.0\nG90\n")
		
#	_gcode_start(file, origin, size, first_axis)
	for i in range(layers.size()):
		for _j in range(layers_info[i].dup_amount): # Repeat this layer by dup_amount of times
			
			# Preprocessing - separate by axis in layer
			var strokes_by_axis = {} # For a single layer
			for stroke in layers[i]:
				if not strokes_by_axis.has(stroke.axis):
					strokes_by_axis[stroke.axis] = []
				strokes_by_axis[stroke.axis].append(stroke)
			
			for axis in axis_order:
				# Draw each stroke in layer, of the same axis first
				if axis in strokes_by_axis:
					# TODO: Ensure nozzle in correct layer height + OFFSET X,Y depending on space between
					#  + possibly move nozzle up/down so not collide
					# Set axis. TODO: set extrusion rate
					file.store_string(axis + ";Set current extruder axis to " + axis + " \n")
					# This line may be duplicate for first_axis
					file.store_string("G90\nG0 " + axis + str(layer_count * layer_height) + "\nG91\n")
					
					# Draw each stroke
					for stroke in strokes_by_axis[axis]:
						_gcode_polyline(file, stroke)
			
			# End layer
			# Move up a bit for each layer by size of layer, assuming relative coord
			file.store_string("G0")
			
			for axis in axis_order:
#				file.store_string(" %s%.2f" % [axis, 0.25]) # Move to layer height
				file.store_string(" %s%.2f" % [axis, 3 * layer_height]) # Move above layer height so not get in the way
			file.store_string("\n")
			
			layer_count += 1
	_gcode_end(file, axis_order, layer_height)
	print("EXPORTED ", layer_count, " layers.")
	
	# Flush and close the file
#	file.flush()
	file.close()
	print("Exported %s in %d ms" % [path, (OS.get_ticks_msec() - start_time)])

# -------------------------------------------------------------------------------------------------
func _gcode_start(file: File, origin: Vector2, size: Vector2, first_axis : String) -> void:
	file.store_string("G90\nG0 " + first_axis + "0\nG91\n")

# -------------------------------------------------------------------------------------------------
func _gcode_end(file: File, axis_order: Array, layer_height: float) -> void:
	# Move all nozzles up slightly so out of the way
	for axis in axis_order:
		file.store_string("G0 " + axis + str(3 * layer_height) + "\n") 

# -------------------------------------------------------------------------------------------------
func _gcode_polyline(file: File, stroke: BrushStroke) -> void:
	# Stroke: Color, Size, [Points]
	var rel_offset = stroke.points[0] - curr_point_abs
	# Negate x to flip - from image coordinates to real coordinates
	file.store_string("G0 X%.2f Y%.2f\n" % [-1 * rel_offset.x / 10.0, rel_offset.y / 10.0])
	curr_point_abs = stroke.points[0]
	var idx := 0
	var point_count := stroke.points.size()
	for i in range(stroke.points.size()):
		if i != 0:
			var point = stroke.points[i]
			rel_offset = point - curr_point_abs
			curr_point_abs = point
			file.store_string("G1 X%.2f Y%.2f\n" % [-1 * rel_offset.x / 10.0, rel_offset.y / 10.0])
			idx += 1
	file.store_string("\n")
