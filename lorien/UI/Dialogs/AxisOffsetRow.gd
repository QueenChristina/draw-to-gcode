extends VBoxContainer
class_name NozzleRow

onready var axes_line_edit : LineEdit = $HBox/AxisLineEdit
onready var extruders_line_edit : LineEdit = $HBox/ExtruderLineEdit
onready var offset_x : SpinBox = $HBox/OffsetX
onready var offset_y : SpinBox = $HBox/OffsetY
onready var diam_nozzle : SpinBox = $HBoxContainer/DiamNozzle
onready var diam_barrel : SpinBox = $HBoxContainer/DiamBarrel
onready var preextrusion : SpinBox = $HBoxContainer/Preextrusion
onready var e_row : HBoxContainer = $HBoxContainer
onready var e_coefficient : SpinBox = $HBoxContainer/Coeff

var axes = []
var extruders = []
var offset = Vector2(0, 0)

signal deleted(node)

# Initialize values
# axes_val - []
# extruders_val - []
# offset_val - Vector2
# diam - float
# p_val - float (preextrusion amount)
func init(axes_val, extruders_val, offset_val, e_coeff, diam_n_val, diam_b_val, p_val):
	axes = axes_val
	extruders = extruders_val
	offset = offset_val
	
	axes_line_edit.text = axes.join(",")
	extruders_line_edit.text = PoolStringArray(extruders).join(",")
	offset_x.value = offset.x
	offset_y.value = offset.y
	e_coefficient.value = e_coeff
	diam_nozzle.value = diam_n_val
	diam_barrel.value = diam_b_val
	preextrusion.value = p_val
	
	_set_extruder_editability(axes)
	
func _set_extruder_editability(axes):
	if axes.size() > 1:
		_toggle_extruder_row(false)
	else:
		_toggle_extruder_row(true)

func _on_DeleteButton_pressed():
	emit_signal("deleted", self)

func _on_AxisLineEdit_text_changed(new_text):
	var new_axes = make_list(new_text)
	axes = new_axes
	
	_set_extruder_editability(new_axes)

func _on_ExtruderLineEdit_text_changed(new_text):
	var new_extruders = make_list(new_text)
	extruders = new_extruders

func _on_OffsetX_value_changed(value):
	offset.x = value

func _on_OffsetY_value_changed(value):
	offset.y = value
	
func make_list(text) -> Array:
	text.replace(" ", "")
	return text.split(",", false)
	
# Do not make extruder values editable if specify multiple axes
func _toggle_extruder_row(enabled : bool):
	diam_barrel.editable = enabled
	diam_nozzle.editable = enabled
	preextrusion.editable = enabled
	extruders_line_edit.editable = enabled
	e_coefficient.editable = enabled
	
	if not enabled:
		extruders_line_edit.modulate.a = 0.5
		$HBox/Label4.modulate.a = 0.5
		e_row.modulate.a = 0.5
	else:
		extruders_line_edit.modulate.a = 1
		$HBox/Label4.modulate.a = 1
		e_row.modulate.a = 1
