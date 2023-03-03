extends ScrollContainer

onready var _nozzle_rows : VBoxContainer = $AxesOffsets

# Called when the node enters the scene tree for the first time.
func _ready():
	_set_values()

func _set_values() -> void:
	# Fix TODO
	pass
#	var axes = Settings.get_value(Settings.AXES, Config.DEFAULT_AXES)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
