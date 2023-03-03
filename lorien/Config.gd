class_name Config

const VERSION_MAJOR					:= 0
const VERSION_MINOR					:= 7
const VERSION_PATCH					:= 0
const VERSION_STATUS				:= "-dev"
const VERSION_STRING				:= "%d.%d.%d%s" % [VERSION_MAJOR, VERSION_MINOR, VERSION_PATCH, VERSION_STATUS]
const CONFIG_PATH 					:= "user://settings.cfg"
const PALETTES_PATH					:= "user://palettes.cfg"
const STATE_PATH					:= "user://state.cfg"
const MAX_PALETTE_SIZE 				:= 40
const MIN_PALETTE_SIZE 				:= 1
const MIN_WINDOW_SIZE				:= Vector2(320, 256)
const DEFAULT_CANVAS_COLOR 			:= Color("202124")
const DEFAULT_BRUSH_COLOR 			:= Color.white
const DEFAULT_BRUSH_AXIS			:= "Z"
const DEFAULT_BRUSH_SIZE			:= 12
const DEFAULT_PRESSURE_SENSITIVITY  := 1.5
const DEFAULT_AA_MODE				:= Types.AAMode.TEXTURE_FILL
const DEFAULT_SELECTION_COLOR 		:= Color("#2a967c")
const DEFAULT_FOREGROUND_FPS 		:= 144
const DEFAULT_BACKGROUND_FPS		:= 10
const DEFAULT_BRUSH_ROUNDING		:= Types.BrushRoundingType.ROUNDED
const DEFAULT_UI_SCALE_MODE 		:= Types.UIScale.AUTO
const DEFAULT_UI_SCALE  			:= 1.0
const DEFAULT_GRID_SIZE 			:= 10.0
const DEFAULT_PLATORM_SIZE			:= Vector2(200, 200)
const DEFAULT_UNIT					:= "mm"
const DEFAULT_LAYER_HEIGHT			:= 0.25
const DEFAULT_PRINTER_NAME			:= "default" # key to printer setting
# All settings for the bioprinter, by printer. TODO: add platform size to it

const DEFAULT_PRINTER_SETTINGS		:= {"default" : 
											{"nozzle_axes" : ["Z", "A"],		# vertical axes
											"axis_order" : ["A,Z", "Z", "A"], 	# print order
											"axis_extruder" : {"Z" : "B", "A" : "C"},
											"extruder_coeffs" : {"C" : 1.5, "B" : 1.5},
											"extruder_nozzle_diam" : {"C" :0.9798, "B" :  0.4},
											"extruder_syringe_diam" : {"C" : 4.6, "B" : 4.6},
											"axis_offset" : {"Z" : Vector2(0, 0), "A" : Vector2(33.75, 0)}, # Per axis_order as keys
											"pre_extrude_amt" : {"B" : 0.2, "C" : 0.2}
											}
										}
