tool
extends Node2D

# width, height of the printbed, for visual guideline purposes
export var rect_size = Vector2(300, 300) setget set_rect
onready var line = $Line2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
#	line.points[0] = Vector2(-rect_size.x / 2 - line.width / 2, -rect_size.y / 2)
#	line.points[1] =  Vector2(rect_size.x / 2, -rect_size.y / 2)
#	line.points[2] =  Vector2(rect_size.x / 2, rect_size.y / 2)
#	line.points[3] =  Vector2(-rect_size.x / 2, rect_size.y / 2)
#	line.points[4] =  Vector2(-rect_size.x / 2, -rect_size.y / 2  - line.width / 2)
	
func set_rect(rect_vector):
	rect_size = rect_vector
	line = get_node_or_null("Line2D")
	if line:
		line.points[0] = Vector2(-rect_size.x / 2 - line.width / 2, -rect_size.y / 2)
		line.points[1] =  Vector2(rect_size.x / 2, -rect_size.y / 2)
		line.points[2] =  Vector2(rect_size.x / 2, rect_size.y / 2)
		line.points[3] =  Vector2(-rect_size.x / 2, rect_size.y / 2)
		line.points[4] =  Vector2(-rect_size.x / 2, -rect_size.y / 2  - line.width / 2)
