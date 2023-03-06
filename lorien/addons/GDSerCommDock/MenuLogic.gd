"""
GDSerCommDock by https://github.com/NangiDev/GDSerCommPlugin under MIT license.
"""

tool
extends Control

const SERCOMM = preload("res://addons/GDSerCommDock/bin/GDSerComm.gdns")
onready var PORT = SERCOMM.new()

#helper node
onready var com = $Com
#use it as node since script alone won't have the editor help

var port

onready var portButton = $"MarginContainer/HBoxContainer/VBoxContainer/PortHBoxContainer/PortOptionButton"
onready var baudButton = $"MarginContainer/HBoxContainer/VBoxContainer/PortHBoxContainer/BaudRateOptionButton"
onready var refreshButton = $"MarginContainer/HBoxContainer/VBoxContainer/PortHBoxContainer/RefreshButton"
onready var sendButton = $"MarginContainer/HBoxContainer/VBoxContainer/SendVBoxContainer/SendHBoxContainer/SendButton"
onready var sendLine = $"MarginContainer/HBoxContainer/VBoxContainer/SendVBoxContainer/LineEdit"
onready var endlineCheck = $"MarginContainer/HBoxContainer/VBoxContainer/SendVBoxContainer/SendHBoxContainer/EndlineCheckBox"
onready var readLabel = $"MarginContainer/HBoxContainer/VBoxContainer/SerialReadRichTextLabel"
# Printer specific
onready var gcodeTextEdit = $"MarginContainer/HBoxContainer/VBoxContainer2/TextEdit"


func _ready():
	#adding the port and baudrate options
	_on_RefreshButton_pressed()

#On refreash button pressed update PORT lists
func _on_RefreshButton_pressed():
	portButton.clear()
	portButton.add_item("Port")
	var no_ports = "NO DEVICES DETECTED"
	var l_ports = PORT.list_ports()
	var has_no_ports = true
	for i in range(len(l_ports)):
		if l_ports[i] != no_ports[i]:
			has_no_ports = false
	if has_no_ports:
		portButton.add_item(no_ports)
	else:
		for index in PORT.list_ports():
			portButton.add_item(str(index))
		
	baudButton.clear()
	baudButton.add_item("Baudrate")
	for index in com.baud_list: #first use of com helper
		baudButton.add_item(str(index))
	
#_physics_process may lag with lots of characters, but is the simplest way
#for best speed, you can use a thread
#do not use _process due to fps being too high
func _physics_process(delta):
	if PORT != null && PORT.get_available() > 0:
		for i in range(PORT.get_available()):
			readLabel.add_text(str(PORT.read()))

func send_text():
	#LineEdit does not recognize endline
	var text=sendLine.text.replace(("\\n"),com.endline)

	if endlineCheck.pressed: #if checkbox is active, add endline
		text+=com.endline

	PORT.write(text) #write function, please use only ascii
	sendLine.text=""

func _on_PortOptionButton_item_selected(ID):
	port = portButton.get_item_text(ID)

func _on_BaudRateOptionButton_item_selected(ID):
	set_physics_process(false)
	PORT.close()
	if port!=null and ID!=0:
		PORT.open(port,int(baudButton.get_item_text(ID)),1000,com.bytesz.SER_BYTESZ_8, com.parity.SER_PAR_NONE, com.stopbyte.SER_STOPB_ONE)
		PORT.flush()
	else:
		print("You must select a port first")
	set_physics_process(true)

func _on_LineEdit_gui_input(event):
	if event is InputEventKey and event.scancode==KEY_ENTER:
		if(sendLine.text!=""): #due to is_echo not working for some reason
			send_text()

func _on_SendButton_pressed():
	send_text()

func _on_ClearButton_pressed():
	readLabel.clear()

func _on_DisconnectButton_pressed():
	set_physics_process(false)
	PORT.flush()
	PORT.close()
	_on_RefreshButton_pressed()
	set_physics_process(true)

func _on_CheckBox_toggled(button_pressed):
	readLabel.scroll_following = button_pressed

# -------------------------------------------------------
# Printer specific code

func _on_GenerateGCode_pressed():
	var project: Project = ProjectManager.get_active_project()
	if project != null:
		var gcode := GCodeExporter.new()
		gcodeTextEdit.text = gcode.get_gcode(project.layers, project.layers_info, project.print_offset)
		
func _on_SendTextEdit_pressed():
	send(gcodeTextEdit.text)

func send(text):
	if endlineCheck.pressed: #if checkbox is active, add endline
		text+=com.endline
	PORT.write(text) #write function, please use only ascii

func _on_CopyText_pressed():
	OS.set_clipboard(gcodeTextEdit.text)
