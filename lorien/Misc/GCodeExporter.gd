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

	# Order of axis printing per layer
	var nozzle_axes = ["Z", "A"]
	var axis_order = ["A,Z", "Z", "A"]
	var axis_extruder = {"Z" : "C", "A" : "B"}
	# TODO: scale these constants if converting between units
	var extruder_coeffs = {"C" : 2.5, "B" : 2.5}
	var extruder_nozzle_diam = {"C" : 0.25, "B" : 0.25}
	var extruder_syringe_diam = {"C" : 4.6, "B" : 4.6}
	var axis_offset = {"Z" : Vector2(0, 0), "A" : Vector2(33.75, 0)} # Per axis_order
	var last_axis = "Z" # The last axis/axes used
	
	# Add header
	var gcode_header = "F300"
	if gcode_header != "":
		file.store_string(gcode_header + "\n")
	
	# Start file with setting units to mm and set to relative coordinates
	if unit.to_lower() == "inch":
		# G92 X0.0 Y0.0\n # set current X,Y as origin(?)
		file.store_string("G20\n")
	else:
		file.store_string("G21\n")
	
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
					# Translate to new nozzle (axis) - untranslate back to origin, then translate to new nozzle; take negative as image coordinates is flipped of real coordinates
					var offset = -1 * (axis_offset.get(axis, Vector2(0, 0)) - axis_offset.get(last_axis, Vector2(0, 0)))
					if offset != Vector2(0, 0):
						file.store_string("G0 X%.2f Y%.2f ;Translate to nozzle of %s axis\n" % [offset.x, offset.y, axis])
					last_axis = axis
					# Set axis extruder(s).
					var list_axes = axis.split(",", false)
					var extruders = []
					for a in list_axes:
						extruders.append(axis_extruder[a])
					# Move axis to correct layer height. This line may be duplicate of below. TODO: remove one?
					file.store_string("(Move " + axis + " to layer " + str(layer_count) + ")\n")
					file.store_string("G90\nG0") # absolute
					for a in list_axes:
						file.store_string(" " + a + str(layer_count * layer_height))
					file.store_string("\nG91\n\n") # switch back to relative
					
					# Draw each stroke
					for stroke in strokes_by_axis[axis]:
						_gcode_polyline(file, stroke, extruders, extruder_coeffs, extruder_nozzle_diam, extruder_syringe_diam)
			# End layer
			
			# Move up a bit for each layer by size of layer, assuming relative coord, so not collide
			file.store_string("(Move all nozzles up a layer)\n")
			file.store_string("G0")
			for axis in nozzle_axes:
				file.store_string(" %s%.2f" % [axis, layer_height]) # Move to new layer height
			file.store_string("\n")
			
			layer_count += 1
	_gcode_end(file, nozzle_axes, layer_height)
	print("EXPORTED ", layer_count, " layers.")
	
	# Flush and close the file
#	file.flush()
	file.close()
	print("Exported %s in %d ms" % [path, (OS.get_ticks_msec() - start_time)])

# -------------------------------------------------------------------------------------------------
func _gcode_end(file: File, nozzle_axes: Array, layer_height: float) -> void:
	# Move all nozzles up slightly so out of the way
	file.store_string("(Move all nozzles up to end.)\n")
	file.store_string("G0")
	for axis in nozzle_axes:
		# TODO: better ending height
		file.store_string(" " + axis + str(min(3 * layer_height, 3))) 
	file.store_string("\n")

# -------------------------------------------------------------------------------------------------
func _gcode_polyline(file: File, stroke: BrushStroke, extruders : Array, extruder_coeffs : Dictionary, extruder_nozzle_diam : Dictionary, extruder_syringe_diam : Dictionary) -> void:
	# Stroke: Color, Size, [Points]
	var rel_offset = stroke.points[0] - curr_point_abs
	# Negate x to flip - from image coordinates to real coordinates
	file.store_string("G0 X%.3f Y%.3f\n" % [-1 * rel_offset.x / 10.0, rel_offset.y / 10.0])
	curr_point_abs = stroke.points[0]
	var idx := 0
	var point_count := stroke.points.size()
	for i in range(stroke.points.size()):
		if i != 0:
			var point = stroke.points[i]
			rel_offset = point - curr_point_abs
			curr_point_abs = point
			
			var extrusion_amts = []
			for extruder in extruders:
				var extrusion_amt = (extruder_coeffs.get(extruder, 1) * rel_offset.length() * pow(extruder_nozzle_diam.get(extruder, 0.25), 2)) / pow(extruder_syringe_diam.get(extruder, 4.6), 2)
				extrusion_amts.append(extruder + str(stepify(extrusion_amt,0.001)))
			var extrusions = PoolStringArray(extrusion_amts).join(" ")
			file.store_string("G1 X%.3f Y%.3f %s\n" % [-1 * rel_offset.x / 10.0, rel_offset.y / 10.0, extrusions])
			idx += 1
	file.store_string("\n")
