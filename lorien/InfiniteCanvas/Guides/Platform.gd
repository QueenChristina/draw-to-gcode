extends Node2D

# width, height of the printbed, for visual guideline purposes
export var rect_size = Vector2(300, 300) 
onready var line = $Line2D

# Called when the node enters the scene tree for the first time.
func _ready():
	line.points[0] = Vector2(-rect_size.x / 2 - line.width / 2, -rect_size.y / 2)
	line.points[1] =  Vector2(rect_size.x / 2, -rect_size.y / 2)
	line.points[2] =  Vector2(rect_size.x / 2, rect_size.y / 2)
	line.points[3] =  Vector2(-rect_size.x / 2, rect_size.y / 2)
	line.points[4] =  Vector2(-rect_size.x / 2, -rect_size.y / 2  - line.width / 2)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
