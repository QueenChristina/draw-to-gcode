class_name GCodeExporter
extends Reference

# TODOs
# - Stroke width / pressue data
var curr_point_abs = Vector2(0, 0) # Current point of nozzle in absolute coordinates, X, Y values only (image coordinates)

# -------------------------------------------------------------------------------------------------
const EDGE_MARGIN := 0.025

# -------------------------------------------------------------------------------------------------
func export_gcode(layers: Array, layers_info : Array, path: String) -> void:
	var start_time := OS.get_ticks_msec()
	
	# TODO: delete zero-length lines made by draw tool + fix line optimization
	# TODO: use new thread to save file so not freeze up software as it loads for 500+ layers + show spinner loader circle
	
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
	
	# Write gcode to file - TODO: stress test max length of string in memory!!! May limit file length
	file.store_string(get_gcode(layers, layers_info))
	# Flush and close the file
#	file.flush()
	file.close()
	print("Exported %s in %d ms" % [path, (OS.get_ticks_msec() - start_time)])
	
# -------------------------------------------------------------------------------------------------
# Returns gcode as a string
# NOTE: everything in relative right now. TODO: do it all in absolute instead.
# It's easier AND errors (due to rounding) won't compound so more accurate than relative.
# Just G92 the extruders to 0 at start!!!
func get_gcode(layers: Array, layers_info : Array) -> String:
	var gcode = ""
	curr_point_abs = Vector2(0, 0)
	
	# Initialize variables from settings
	var layer_count = 1	# Start printing one layer up ie., global origin 0, 0, 0 should be tip touching bed
	var layer_height = Settings.get_value(Settings.LAYER_HEIGHT, Config.DEFAULT_LAYER_HEIGHT)
	var unit = Settings.get_value(Settings.UNIT, Config.DEFAULT_UNIT)
	var gcode_header = ""
	var jog_speed = "F200"
	var print_speed = "F200"
	var nozzle_axes = ["Z", "A"] # Order of axis printing per layer
	var axis_order = ["A,Z", "Z", "A"]
	var axis_extruder = {"Z" : "B", "A" : "C"}
	var extruder_coeffs = {"C" : 1.5, "B" : 1.5}
	var extruder_nozzle_diam = {"C" :0.9798, "B" :  0.4} # Diameter of circle with equivalent area extruded from the nozzle
	var extruder_syringe_diam = {"C" : 4.6, "B" : 4.6} # Diameter of barrel
	var axis_offset = {"Z" : Vector2(0, 0), "A" : Vector2(33.75, 0)} # keys per axis_order
	var last_axis = "Z" # The last axis/axes used
	var pre_extrude_amt = {"B" : 0.2, "C" : 0.2} # Optional pre-extrude amounts to "pressurize" nozzle in mm syringe moves
	
	gcode += _gcode_start(layers, layers_info, axis_order, unit, jog_speed, print_speed, pre_extrude_amt, layer_count, layer_height, gcode_header)
	# Draw layers
	for i in range(layers.size()):
		for _j in range(layers_info[i].dup_amount): # Repeat this layer by dup_amount of times
			# Preprocessing - separate by axis in layer
			var strokes_by_axis = {} # For a single layer
			for stroke in layers[i]:
				if not strokes_by_axis.has(stroke.axis):
					strokes_by_axis[stroke.axis] = []
				strokes_by_axis[stroke.axis].append(stroke)
				
			# Move ALL nozzles to one layer heigher than draw layer so no collisions
			# TODO: best distance up to jog between strokes to avoid collision?
			gcode += _move_to_layer_gcode(nozzle_axes, layer_count + 1, layer_height, jog_speed)
			
			for axis in axis_order:
				# Draw each stroke in layer, of the same axis first
				if axis in strokes_by_axis:
					# Translate to new nozzle (axis) - untranslate back to origin, then translate to new nozzle; take negative as image coordinates is flipped of real coordinates
					var offset = -1 * (axis_offset.get(axis, Vector2(0, 0)) - axis_offset.get(last_axis, Vector2(0, 0)))
					if offset != Vector2(0, 0):
						gcode += "G0 X%.2f Y%.2f %s;Translate to nozzle of %s axis\n" % [offset.x, offset.y, print_speed, axis]
					last_axis = axis
					# Set axis extruder(s).
					var list_axes : PoolStringArray = axis.split(",", false)
					var extruders = []
					for a in list_axes:
						extruders.append(axis_extruder[a])

					# Draw each stroke
					gcode += "(Draw strokes for nozzle of axis " + axis + " )\n"
					for stroke in strokes_by_axis[axis]:
						gcode += _gcode_polyline(stroke, list_axes, extruders, extruder_coeffs, 
												extruder_nozzle_diam, extruder_syringe_diam, 
												print_speed, jog_speed, layer_count, layer_height)
						# Jog up a bit so not collide with strokes moving between them
						gcode += _move_to_layer_gcode(list_axes, layer_count + 1, layer_height, jog_speed)
			# End layer
			layer_count += 1
			
	gcode += _gcode_end(nozzle_axes, layer_height, axis_offset.get(last_axis, Vector2(0, 0)))
	return gcode

# -------------------------------------------------------------------------------------------------
# Move axis to correct layer height.
func _move_to_layer_gcode(list_axes, layer_count, layer_height, jog_speed, v_offset = 0):
	var gcode = "(Move " + PoolStringArray(list_axes).join(", ") + " to layer " + str(layer_count) + ")\n"
	gcode += "G90\nG0" # absolute
	for a in list_axes:
		gcode += " " + a + str(layer_count * layer_height + v_offset)
	gcode += " %s\nG91\n\n" % [jog_speed] # switch back to relative
	return gcode

# -------------------------------------------------------------------------------------------------
func _gcode_start(layers, layer_info, axis_order, unit, jog_speed, print_speed, pre_extrude_amt, layer_count, layer_height, gcode_header = ""):
	# Add header
	var gcode = ""
	if gcode_header != "":
		gcode += gcode_header + "\n"
	# Start file with setting units to mm and set to relative coordinates
	if unit.to_lower() == "inch":
		gcode += "G20\n" # G92 X0.0 Y0.0\n # set current X,Y as origin(?)
	else:
		gcode += "G21\n"
	
	# Go to first layer and pre-extrude some amount at point of first stroke
	if layers[0].size() > 0 and layers[0][0].points.size() > 0:
		var l_first_axes = axis_order[0].split(",", false)
		gcode += _move_to_layer_gcode(l_first_axes, layer_count, layer_height, jog_speed)
		gcode += "(Move to first point of first stroke.)\n"
		var first_stroke_point = layers[0][0].points[0]
		gcode += "G0 X%.3f Y%.3f\n" % [-1 * first_stroke_point.x / 10.0, first_stroke_point.y / 10.0]
		curr_point_abs = first_stroke_point
		if pre_extrude_amt.size() > 0:
			gcode += "\n(Pre-extrude some amount to pressurize nozzles)\n"
			gcode += "G91\n"
			gcode += "G1"
			for e in pre_extrude_amt:
				gcode += " " + e + str(pre_extrude_amt[e])
			gcode +=  " " + print_speed + "\n\n"
	return gcode

# -------------------------------------------------------------------------------------------------
func _gcode_end(nozzle_axes: Array, layer_height: float, axis_offset : Vector2) -> String:
	# Move all nozzles up slightly so out of the way (assuming relative)
	var gcode = "(Move all nozzles up to end, and move back to starting X,Y.)\n"
	gcode += "G0"
	for axis in nozzle_axes:
		# TODO: better ending height
		gcode += " " + axis + str(min(20 * layer_height, 5))
	gcode += "\n"
	# Move back to origin X, Y
	var offset = axis_offset - Vector2(-curr_point_abs.x, curr_point_abs.y) / 10
	gcode += "G0 X%.3f Y%.3f\n" % [offset.x, offset.y]
	return gcode

# -------------------------------------------------------------------------------------------------
# Stroke: Color, Size, [Points]
func _gcode_polyline(stroke: BrushStroke, list_axes : Array, extruders : Array, 
					extruder_coeffs : Dictionary, extruder_nozzle_diam : Dictionary, 
					extruder_syringe_diam : Dictionary, print_speed : String, 
					jog_speed : String, layer_count : int, layer_height : float) -> String:
	var gcode = ""
	var rel_offset = stroke.points[0] - curr_point_abs
	# Move to first point. Negate x to flip - from image coordinates to real coordinates
	gcode += "G0 X%.3f Y%.3f %s\n" % [-1 * rel_offset.x / 10.0, rel_offset.y / 10.0, jog_speed]
	# Move drawing axes to draw layer height
	gcode += _move_to_layer_gcode(list_axes, layer_count, layer_height, jog_speed)
	curr_point_abs = stroke.points[0]
	
	# Draw each point in stroke
	for i in range(stroke.points.size()):
		if i != 0:
			var point = stroke.points[i]
			rel_offset = point - curr_point_abs
			curr_point_abs = point
			
			var extrusion_amts = []
			for extruder in extruders:
				var nozzle_diam = extruder_nozzle_diam.get(extruder, 0.25)
				var syringe_diam = extruder_syringe_diam.get(extruder, 4.6)
				var e_coeff = extruder_coeffs.get(extruder, 1)
				var length_line = rel_offset.length() / 10.0 # TODO: set the scale!!!!
				var extrusion_amt = (e_coeff * length_line * pow(nozzle_diam, 2)) / pow(syringe_diam, 2)
				extrusion_amts.append(extruder + str(stepify(extrusion_amt,0.001)))
			var extrusions = PoolStringArray(extrusion_amts).join(" ")
			gcode += "G1 X%.3f Y%.3f %s %s\n" % [-1 * rel_offset.x / 10.0, rel_offset.y / 10.0, extrusions, print_speed]
	gcode += "\n"
	return gcode
