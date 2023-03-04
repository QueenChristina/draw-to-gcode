extends Control

onready var nozzle_settings_row = preload("res://UI/Dialogs/AxisOffsetRow.tscn")
onready var _nozzle_rows : VBoxContainer = $VBoxContainer/ScrollContainer/AxesOffsets
onready var _p_speed : SpinBox = $VBoxContainer/Speed/Print
onready var _j_speed : SpinBox = $VBoxContainer/Speed/Jog

var printer_settings = {}
var curr_printer =  {}
var curr_printer_settings = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	_set_values()
	
func _set_values() -> void:
	printer_settings = Settings.get_value(Settings.PRINTER_SETTINGS, Config.DEFAULT_PRINTER_SETTINGS)
	curr_printer =  Settings.get_value(Settings.CURR_PRINTER_NAME, Config.DEFAULT_CURR_PRINTER_NAME)
	curr_printer_settings = printer_settings[curr_printer]

	print("SPEED", curr_printer_settings.print_speed, _to_speed_val(curr_printer_settings.print_speed))
	_p_speed.value = _to_speed_val(curr_printer_settings.print_speed)
	_j_speed.value = _to_speed_val(curr_printer_settings.jog_speed)

	var l_all_axes : Array = curr_printer_settings.nozzle_axes.duplicate()

	for axis in curr_printer_settings.axis_offset: # TODO: use axis order instead
		if not axis in l_all_axes:
			l_all_axes.append(axis)

	for axis in l_all_axes:
		var axis_row = nozzle_settings_row.instance()
		axis_row.connect("deleted", self, "_on_row_deleted")
#		axis_row.connect("axes_changed", self, "_on_axes_changed")
#		axis_row.connect("extruders_changed", self, "_on_extruders_changed")
#		axis_row.connect("offset_changed", self, "_on_offset_changed")
#		axis_row.connect("diam_nozzle_changed", self, "_on_diam_nozzle_changed")
#		axis_row.connect("diam_barrel_changed", self, "_on_diam_barrel_changed")
#		axis_row.connect("preextrusion_changed", self, "_on_preextrusion_changed")

		_nozzle_rows.add_child(axis_row)
		# Move to before the add row button
		_nozzle_rows.move_child(axis_row, max(0, _nozzle_rows.get_child_count() - 2))
		
		var l_axis = axis.split(",", false)
		var l_extr = []
		if l_axis.size() == 1:
			# Only going to populate extruder values if one axis specified
			l_extr.append(curr_printer_settings.axis_extruder.get(l_axis[0], "")) 
#		for a in l_axis:
#			l_extr.append(curr_printer_settings.axis_extruder.get(a, ""))
		var offset = curr_printer_settings.axis_offset.get(axis, Vector2(0, 0))
		var diam_n = 0
		var diam_b = 0
		var p_val = 0
		var e_coeff = 1
		if l_extr.size() > 0:
			e_coeff =  curr_printer_settings.extruder_coeffs.get(l_extr[0], 1)
			diam_n =  curr_printer_settings.extruder_nozzle_diam.get(l_extr[0], 0.25)
			diam_b =  curr_printer_settings.extruder_syringe_diam.get(l_extr[0], 4.6)
			p_val =  curr_printer_settings.pre_extrude_amt.get(l_extr[0], 0)
		axis_row.init(l_axis, l_extr, offset, e_coeff, diam_n, diam_b, p_val)

# Converts string F### to ####
func _to_speed_val(text : String) -> float:
	text = text.replace(" ", "")
	return float(text.substr(1))

# Add empty nozzle settings row
func _on_Add_Axis_pressed():
	var axis_row = nozzle_settings_row.instance()
	axis_row.connect("deleted", self, "_on_row_deleted")
	_nozzle_rows.add_child(axis_row)
	_nozzle_rows.move_child(axis_row, max(0, _nozzle_rows.get_child_count() - 2))
	
# ------------------------------------------------------------------------------
# Standarized way of using list as string
func list_to_string(list):
	Array(list).sort()
	var text = PoolStringArray(list).join(",")
	text = text.replace(" ", "")
	return text
	
# TODO: delete all modications of curr_printer on change -- does NOT work as default values
# when make new row not captured
#
## Remove axis key references
#func remove_axis(a_key):
#	# Delete from nozzle axes
#	if a_key in curr_printer_settings.nozzle_axes:
#		curr_printer_settings.nozzle_axes.erase(a_key)
#	# Delete from axis order
#	if a_key in curr_printer_settings.axis_order:
#		curr_printer_settings.axis_order.erase(a_key)
#	# TODO: handle if repeated reference / repeated row -- do not delete?
#	curr_printer_settings.axis_extruder.erase(a_key)
#	# TODO: delete other references?
	
# Set values when nozzle settings change
func _on_row_deleted(node):
#	var a_key = list_to_string(node.axes)
#	remove_axis(a_key)	
	_nozzle_rows.remove_child(node)
#
#func _on_axes_changed(node, prev_axes, new_axes):
#	var p_key = list_to_string(prev_axes)
#	var n_key = list_to_string(new_axes)
#	remove_axis(p_key)
#	# Add nozzle in nozzle axes
#	curr_printer_settings.nozzle_axes.append(n_key)
#	# Add to axis order. TODO: customize order
#	curr_printer_settings.axis_order.append(n_key)
#	# TODO: add other references/default values?
#	curr_printer_settings.axis_extruder[n_key] = list_to_string(node.extruders)
#
#func _on_extruders_changed(node, prev_extruders, new_extruders):
#	var p_key = list_to_string(prev_extruders)
#	var n_key = list_to_string(new_extruders)
#	var axis = list_to_string(node.axes)
#	# Update all keys
#	if not "," in axis:
#		curr_printer_settings.axis_extruder[axis] = n_key
##	curr_printer_settings.extruder_coeffs[n_key] = curr_printer_settings.extruder_coeffs[p_key]
##	curr_printer_settings.extruder_coeffs.erase(p_key)
#	curr_printer_settings.extruder_nozzle_diam[n_key] = node.diam_nozzle.value
#	curr_printer_settings.extruder_nozzle_diam.erase(p_key)
#	curr_printer_settings.extruder_syringe_diam[n_key] = node.diam_barrel.value
#	curr_printer_settings.extruder_syringe_diam.erase(p_key)
#	curr_printer_settings.pre_extrude_amt[n_key] = node.preextrusion.value
#	curr_printer_settings.pre_extrude_amt.erase(p_key)
#
#func _on_offset_changed(node, new_offset):
#	var a_key = list_to_string(node.axes)
#	curr_printer_settings.axis_offset[a_key] = new_offset
#
#func _on_diam_nozzle_changed(node, extruders, new_diam):
#	var e_key = list_to_string(extruders)
#	curr_printer_settings.extruder_nozzle_diam[e_key] = new_diam
#
#func _on_diam_barrel_changed(node, extruders, new_diam):
#	var e_key = list_to_string(extruders)
#	curr_printer_settings.extruder_syringe_diam[e_key] = new_diam
#
#func _on_preextrusion_changed(node, extruders, new_val):
#	var e_key = list_to_string(extruders)
#	curr_printer_settings.pre_extrude_amt[e_key] = new_val

# Saves settings based on all nozzle rows
func save_settings():
	var new_curr_printer_settings = {"nozzle_axes" : [],		# vertical axes
									"axis_order" : [], 	# print order
									"axis_extruder" : {},
									"extruder_coeffs" : {},
									"extruder_nozzle_diam" : {},
									"extruder_syringe_diam" : {},
									"axis_offset" : {}, # Per axis_order as keys
									"pre_extrude_amt" : {},
									"print_speed" : "F200",
									"jog_speed" : "F200"
									}
	# Get settings from curr rows
	for row in _nozzle_rows.get_children():
		if row.get_index() < _nozzle_rows.get_child_count() - 1:
			if row.axes.size() > 0:
				# Save settings
				var a_key = list_to_string(row.axes)
				print("Process ", a_key)
				if not a_key in new_curr_printer_settings["nozzle_axes"]:
					# TODO: custom axis_order, for multi-axis support too
					new_curr_printer_settings["axis_order"].append(a_key)
					new_curr_printer_settings["axis_offset"][a_key] = row.offset
					if not "," in a_key:
						new_curr_printer_settings["nozzle_axes"].append(a_key)
						var e_key = list_to_string(row.extruders)
						new_curr_printer_settings["axis_extruder"][a_key] = e_key
						new_curr_printer_settings["extruder_coeffs"][e_key] = row.e_coefficient.value
						new_curr_printer_settings["extruder_nozzle_diam"][e_key] = row.diam_nozzle.value
						new_curr_printer_settings["extruder_syringe_diam"][e_key] = row.diam_barrel.value
						new_curr_printer_settings["pre_extrude_amt"][e_key] = row.preextrusion.value
				else:
					print_debug("Multiple same axes in nozzle settings encountered -- did not save duplicate.")
	# Other printer settings
	new_curr_printer_settings.print_speed = "F" + str(_p_speed.value)
	new_curr_printer_settings.jog_speed = "F" + str(_j_speed.value)
	
	# Save
	printer_settings[curr_printer] = new_curr_printer_settings
	Settings.set_value(Settings.PRINTER_SETTINGS, printer_settings)
	curr_printer_settings = new_curr_printer_settings
