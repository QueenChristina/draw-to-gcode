class_name GCodeExporter
extends Reference

# TODOs
# - Stroke width / pressue data

# -------------------------------------------------------------------------------------------------
const EDGE_MARGIN := 0.025

# -------------------------------------------------------------------------------------------------
func export_gcode(strokes: Array, path: String) -> void:
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
	for stroke in strokes:
		min_dim.x = min(min_dim.x, stroke.top_left_pos.x)
		min_dim.y = min(min_dim.y, stroke.top_left_pos.y)
		max_dim.x = max(max_dim.x, stroke.bottom_right_pos.x)
		max_dim.y = max(max_dim.y, stroke.bottom_right_pos.y)
	var size := max_dim - min_dim
	var margin_size := size * EDGE_MARGIN
	size += margin_size*2.0
	var origin := min_dim - margin_size
	
	# Write gcode to file
	_gcode_start(file, origin, size)
	for stroke in strokes:
		_gcode_polyline(file, stroke)
	_gcode_end(file)
	
	# Flush and close the file
#	file.flush()
	file.close()
	print("Exported %s in %d ms" % [path, (OS.get_ticks_msec() - start_time)])

# -------------------------------------------------------------------------------------------------
func _gcode_start(file: File, origin: Vector2, size: Vector2) -> void:
	file.store_string("G90\n")

# -------------------------------------------------------------------------------------------------
func _gcode_end(file: File) -> void:
	file.store_string("") 

# -------------------------------------------------------------------------------------------------
func _gcode_polyline(file: File, stroke: BrushStroke) -> void:
	# Stroke: Color, Size, [Points]
	file.store_string("G0 X%.1f Y%.1f\n" % [stroke.points[0].x / 10.0, stroke.points[0].y / 10.0])
	var idx := 0
	var point_count := stroke.points.size()
	for point in stroke.points:
		file.store_string("G1 X%.1f Y%.1f\n" % [point.x / 10.0, point.y / 10.0])
		idx += 1
	file.store_string("\n")
