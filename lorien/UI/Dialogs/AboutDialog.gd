extends WindowDialog

# -------------------------------------------------------------------------------------------------
onready var _version_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/VBoxContainer/VersionLabel

# -------------------------------------------------------------------------------------------------
func _ready():
	_version_label.text = "DrawN'Gcode v%s" % Config.VERSION_STRING
	rect_size.y = $MarginContainer.rect_size.y + 5

# -------------------------------------------------------------------------------------------------
func _on_GithubLinkButton_pressed():
	# Originally https://github.com/mbrlabs/Lorien
	OS.shell_open("https://github.com/QueenChristina/draw-to-gcode")

# -------------------------------------------------------------------------------------------------
func _on_LicenseButton_pressed():
	OS.shell_open("https://github.com/mbrlabs/Lorien/blob/main/LICENSE")

# -------------------------------------------------------------------------------------------------
func _on_GodotButton_pressed():
#	godotengine.org/license
#	https://godotengine.org/
	OS.shell_open("godotengine.org/license")

# -------------------------------------------------------------------------------------------------
func _on_RemixIconsButton_pressed():
	OS.shell_open("https://remixicon.com/")

# -------------------------------------------------------------------------------------------------
func _on_KennyButton_pressed():
	OS.shell_open("https://www.kenney.nl/assets/platformer-art-deluxe")


func _on_LorienButton_pressed():
	OS.shell_open("https://github.com/mbrlabs/Lorien")


func _on_GDSerCommButton_pressed():
	OS.shell_open("https://github.com/NangiDev/GDSerCommPlugin")
