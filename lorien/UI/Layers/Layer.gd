extends HBoxContainer

export var text = "Layer 0" setget set_layer_text
onready var layer_button = $Button

signal switch_layers(node)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func set_layer_text(layer_text):
	text = layer_text
	layer_button.text = text


func _on_LayerButton_pressed():
	emit_signal("switch_layers", self)
