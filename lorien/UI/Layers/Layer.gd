extends HBoxContainer
enum {VECTOR, RASTER, ADJUSTMENT, EQUATION}

# Layer information. TODO: save information, for undo/redo too
export var text = "Layer 0" setget set_layer_text
var is_layer_visible = true
var thumbnail = null setget set_thumbnail # Texture to set for button icon (thumbnail of layer)
var type = VECTOR

onready var layer_button = $Button
onready var dup_edit = $DuplicateAmountEdit
onready var name_edit = $"Button/NameEdit"

signal switch_layers(node)
signal layer_visibility_changed(node, is_layer_visible)
signal dups_amount_changed(node, value)

# Called when the node enters the scene tree for the first time.
func _ready():
	thumbnail = layer_button.icon

func set_layer_text(layer_text):
	if layer_text != "":
		text = layer_text
		layer_button.text = text

#release_focus()
func _input(event):
	# Mouse in viewport coordinates.
	if event is InputEventMouseButton:
		var position = get_local_mouse_position()
		if name_edit.visible and !_is_inside(position):
			set_layer_text(name_edit.text)
			name_edit.release_focus()
			name_edit.hide()
			name_edit.editable = false
		elif event.is_doubleclick() and _is_inside(position):
			# Was a double click - edit title
			name_edit.text = text
			name_edit.editable = true
			name_edit.show()
			name_edit.grab_focus()
			name_edit.caret_position = len(name_edit.text)

# Returns if clicked outside of self
func _is_inside(local_pos) -> bool:
	return local_pos.x > 0 and local_pos.x < self.rect_size.x and \
			local_pos.y > 0 and local_pos.y < self.rect_size.y

func _on_LayerButton_pressed():
	emit_signal("switch_layers", self)

func _on_Hide_pressed():
	var active_project: Project = ProjectManager.get_active_project()
	active_project.undo_redo.create_action("Toggle Layer Visibility")
	active_project.undo_redo.add_undo_method(self, "toggle_layer_visibility")
	active_project.undo_redo.add_do_method(self, "toggle_layer_visibility")
	active_project.undo_redo.commit_action()
	
func toggle_layer_visibility():
	is_layer_visible = !is_layer_visible
	emit_signal("layer_visibility_changed", self, is_layer_visible)

func _on_DuplicateAmountEdit_value_changed(value):
	# TODO: undo redo
	emit_signal("dups_amount_changed", self, value)

func set_thumbnail(tex : Texture):
	thumbnail = tex
	layer_button.icon = tex

func _on_NameEdit_text_entered(new_text):
	# TODO: fix undo/redo -- commented out as not working with layer deletion redo,
	# because LayerBar manages the layer, which gets deleted.
#	var active_project: Project = ProjectManager.get_active_project()
#	active_project.undo_redo.create_action("Set layer name")
#	active_project.undo_redo.add_undo_method(self, "set_layer_text", text)
#	active_project.undo_redo.add_do_method(self, "set_layer_text", new_text)
#	active_project.undo_redo.commit_action()
	set_layer_text(new_text)
	name_edit.hide()
	name_edit.editable = false
