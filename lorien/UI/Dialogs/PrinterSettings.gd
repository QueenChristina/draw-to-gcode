extends Control

onready var nozzle_settings_row = preload("res://UI/Dialogs/AxisOffsetRow.tscn")
onready var _nozzle_rows : VBoxContainer = $VBoxContainer/ScrollContainer/AxesOffsets
onready var _p_speed : SpinBox = $VBoxContainer/Speed/Print
onready var _j_speed : SpinBox = $VBoxContainer/Speed/Jog
onready var _name_line_edit : LineEdit = $"VBoxContainer/Name/PrinterNameLineEdit"
onready var _printer_option : OptionButton = $"VBoxContainer/SelectPrinter/PrinterOption"
onready var _del_printer : TextureButton = $VBoxContainer/SelectPrinter/DeletePrinter
# TODO: save project-specific print setttings as part of metadata
# AND have this in popup dialog before exporting GCode or other settings, NOT here
onready var _print_offset_z : SpinBox = $VBoxContainer/PrintOffset/HBoxContainer/Z

var printer_settings = {}
var curr_printer =  {}
var curr_printer_settings = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	_set_values()
	
# Initialize Settings based on saved or default values
func _set_values() -> void:
	printer_settings = Settings.get_value(Settings.PRINTER_SETTINGS, Config.DEFAULT_PRINTER_SETTINGS)
	curr_printer =  Settings.get_value(Settings.CURR_PRINTER_NAME, Config.DEFAULT_CURR_PRINTER_NAME)
	curr_printer_settings = printer_settings.get(curr_printer, Config.DEFAULT_PRINTER_SETTINGS["default"])

	_p_speed.value = _to_speed_val(curr_printer_settings.print_speed)
	_j_speed.value = _to_speed_val(curr_printer_settings.jog_speed)

	# Clear existing settings
	for nozzle in _nozzle_rows.get_children():
		# Do not clear the last "Add Axis (new nozzle)" button
		if nozzle.get_index() < _nozzle_rows.get_child_count() - 1:
			nozzle.queue_free()
	_printer_option.clear()

	# Populate printer selection
	_name_line_edit.text = curr_printer
	for printer in printer_settings.keys():
		_printer_option.add_item(printer)
		
	# Select the current printer
	for i in _printer_option.get_item_count():
		var text = _printer_option.get_item_text(i)
		if text == curr_printer:
			_printer_option.select(i)
			break
			
	# Edge case for errors?
	if _printer_option.text != curr_printer:
		_printer_option.add_item(curr_printer)
		_printer_option.select(_printer_option.get_item_count() - 1)
		print_debug("Improper printer settings -- Missing current printer key value: ", curr_printer)
	
	_printer_option.add_separator()
	_printer_option.add_item("Add new printer")
	
	# Populate nozzle settings
	var l_all_axes : Array = curr_printer_settings.nozzle_axes.duplicate()
	for axis in curr_printer_settings.axis_offset: # TODO: use axis order instead
		if not axis in l_all_axes:
			l_all_axes.append(axis)
	for axis in l_all_axes:
		var axis_row = nozzle_settings_row.instance()
		axis_row.connect("deleted", self, "_on_row_deleted")

		_nozzle_rows.add_child(axis_row)
		# Move to before the add row button
		_nozzle_rows.move_child(axis_row, max(0, _nozzle_rows.get_child_count() - 2))
		
		var l_axis = axis.split(",", false)
		var l_extr = []
		# Can only edit and add extruder values if one axis
		if l_axis.size() == 1:
			l_extr.append(curr_printer_settings.axis_extruder.get(l_axis[0], "")) 
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
# TODO: place in Utils instead. Copied func in GCodeExporter.gd and PrinterSettings.gd
# Standarized way of using list as string
func list_to_string(list : Array):
	list.sort()
	var text = PoolStringArray(list).join(",")
	text = text.replace(" ", "")
	return text
	
# Turn string of list into standarized string
func standarize(text):
	var arr = text.split(",", false)
	return list_to_string(arr)

# Set values when nozzle settings change
func _on_row_deleted(node):
	_nozzle_rows.remove_child(node)
	node.queue_free()

# Saves settings based on all nozzle rows
func save_settings():
	var new_curr_printer_settings = {"nozzle_axes" : [],		# vertical axes
									"axis_order" : [], 			# print order
									"axis_extruder" : {},
									"extruder_coeffs" : {},
									"extruder_nozzle_diam" : {},
									"extruder_syringe_diam" : {},
									"axis_offset" : {}, 		# Per axis_order as keys
									"pre_extrude_amt" : {},
									"print_speed" : "F200",
									"jog_speed" : "F200"
									}
	# Get settings from current rows
	for row in _nozzle_rows.get_children():
		if row.get_index() < _nozzle_rows.get_child_count() - 1:
			if row.axes.size() > 0:
				var a_key = list_to_string(Array(row.axes))
				if not a_key in new_curr_printer_settings["nozzle_axes"]:
					# TODO: custom axis_order, for multi-axis support too (eg., if not specified)
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

func _on_PrintOffsetZ_value_changed(value):
	var active_project = ProjectManager.get_active_project()
	active_project.print_offset.z = value

# Select new printer
func _on_PrinterOption_item_selected(index):
	# Keep old data
	save_settings()
	# Now switch to new printer
	_printer_option.select(index)
	if index == _printer_option.get_item_count() - 1:
		# Last item selected -- means add a new printer!!!
		var default_name = "New Printer"
		while printer_settings.has(default_name):
			default_name = "New " + default_name
		Settings.set_value(Settings.CURR_PRINTER_NAME, default_name)
		_del_printer.visible = true
	else:
		# Switch to new existing printer
		Settings.set_value(Settings.CURR_PRINTER_NAME, _printer_option.get_item_text(index))
	_set_values()
	
# Set current printer to have new name
func _on_PrinterNameLineEdit_text_changed(new_text):
	if new_text != "" and !printer_settings.has(new_text):
		printer_settings.erase(curr_printer)
		curr_printer = new_text
		Settings.set_value(Settings.CURR_PRINTER_NAME, new_text)
		save_settings()
		_printer_option.set_item_text(_printer_option.get_selected(), new_text)
	else:
		print_debug("Name taken. Cannot set to existing printer name -- names should be unique.")

# TODO: prompt confirmation dialog first instead, as action cannot be undone
func _on_DeletePrinter_pressed():
	# Must always have at least one printer
	if printer_settings.keys().size() > 1:
		printer_settings.erase(curr_printer)
		Settings.set_value(Settings.PRINTER_SETTINGS, printer_settings)
		# Select new printer
		var new_active_printer = printer_settings.keys()[0]
		Settings.set_value(Settings.CURR_PRINTER_NAME, new_active_printer)
		_set_values()
		# Just disable delete button if only one printer left
		if printer_settings.keys().size() <= 1:
			_del_printer.visible = false
	else:
		print_debug("Cannot delete remaining single printer.")
