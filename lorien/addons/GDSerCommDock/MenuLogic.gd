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
onready var axes_options = $"MarginContainer/HBoxContainer/VBoxContainer2/HBoxContainer/VBoxContainer/HBoxContainer/VAxis"
var move_amt = 0.01

func _ready():
	#adding the port and baudrate options
	_on_RefreshButton_pressed()
	move_amt = $"MarginContainer/HBoxContainer/VBoxContainer2/HBoxContainer/VBoxContainer2/MoveAmount".value

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
#			readLabel.add_text(str(PORT.read()))
			readLabel.append_bbcode("[color=#ffffff]" + str(PORT.read()) + "[/color]")

func send_text():
	if port != null and PORT != null:
		#LineEdit does not recognize endline
		var text=sendLine.text.replace(("\\n"),com.endline)

		if endlineCheck.pressed: #if checkbox is active, add endline
			text+=com.endline

		PORT.write(text) #write function, please use only ascii
		sendLine.text=""
		readLabel.append_bbcode("[color=#c4c4c4]Sent: " + text + "[/color]")
	else:
		readLabel.append_bbcode("[color=#ffffff]No port selected. Cannot send.[/color]")
		
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
	if port != null and PORT != null:
		if endlineCheck.pressed: #if checkbox is active, add endline
			text+=com.endline
		PORT.write(text) #write function, please use only ascii
		readLabel.append_bbcode("[color=#c4c4c4]Sent: " + text + "[/color]")
	else:
		print_debug("No active port selected. Port is null.")
		readLabel.append_bbcode("[color=#ffffff]No port selected. Cannot send.[/color]")

func _on_CopyText_pressed():
	OS.set_clipboard(gcodeTextEdit.text)

func _get_jog_speed():
	var printer_settings = Settings.get_value(Settings.PRINTER_SETTINGS, Config.DEFAULT_PRINTER_SETTINGS)
	var curr_printer =  Settings.get_value(Settings.CURR_PRINTER_NAME, Config.DEFAULT_CURR_PRINTER_NAME)
	var curr_printer_settings = printer_settings[curr_printer]

	return curr_printer_settings.jog_speed
	
func _get_axes():
	var printer_settings = Settings.get_value(Settings.PRINTER_SETTINGS, Config.DEFAULT_PRINTER_SETTINGS)
	var curr_printer =  Settings.get_value(Settings.CURR_PRINTER_NAME, Config.DEFAULT_CURR_PRINTER_NAME)
	var curr_printer_settings = printer_settings[curr_printer]

	return curr_printer_settings.axis_order
	
func _on_YPos_pressed():
	send("G0 Y%s %s" % [move_amt, _get_jog_speed()])

func _on_XNeg_pressed():
	send("G0 X-%s %s" % [move_amt, _get_jog_speed()])

func _on_XPos_pressed():
	send("G0 X%s %s" % [move_amt, _get_jog_speed()])

func _on_YNeg_pressed():
	send("G0 Y-%s %s" % [move_amt, _get_jog_speed()])

func _on_ZPos_pressed():
	send("G0 %s%s %s" % [axes_options.text, move_amt, _get_jog_speed()])

func _on_ZNeg_pressed():
	send("G0 %s-%s %s" % [axes_options.text, move_amt, _get_jog_speed()])

func _on_MoveAmount_value_changed(value):
	move_amt = value

func _on_SerialCommunication_about_to_show():
	set_axes()
	
func set_axes():
	axes_options.clear()
	for axis in _get_axes():
		axes_options.add_item(axis)
	if axes_options.get_item_count() <= 0:
		axes_options.add_item("Z")
	axes_options.select(0)
