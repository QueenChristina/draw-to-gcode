extends HBoxContainer
class_name NozzleRow

onready var axes_line_edit : LineEdit = $AxisLineEdit
onready var extruders_line_edit : LineEdit = $ExtruderLineEdit
onready var offset_x : SpinBox = $OffsetX
onready var offset_y : SpinBox = $OffsetY

var axes = []
var extruders = []
var offset = Vector2(0, 0)

signal deleted(node)
signal axes_changed(node, prev_axes, new_axes)
signal extruders_changed(node, prev_extruders, new_extruders)
signal offset_changed(node, new_offset)

# Initialize values
func init(axes_val, extruders_val, offset_val):
	axes = axes_val
	extruders = extruders_val
	offset = offset_val
	
	axes_line_edit.text = axes.join(",")
	extruders_line_edit.text = extruders.join(",")
	offset_x.value = offset.x
	offset_y.value = offset.y

func _on_DeleteButton_pressed():
	emit_signal("deleted", self)

func _on_AxisLineEdit_text_entered(new_text):
	var new_axes = make_list(new_text)
	emit_signal("axes_changed", self, axes, new_axes)
	axes = new_axes

func _on_ExtruderLineEdit_text_entered(new_text):
	var new_extruders = make_list(new_text)
	emit_signal("extruders_changed", self, axes, new_extruders)
	extruders = new_extruders

func _on_OffsetX_value_changed(value):
	offset.x = value
	emit_signal("offset_changed", self, offset)

func _on_OffsetY_value_changed(value):
	offset.y = value
	emit_signal("offset_changed", self, offset)
	
func make_list(text) -> Array:
	text.replace(" ", "")
	return text.split(",", false)
