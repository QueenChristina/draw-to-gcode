# DrawN'Gcode Manual v0.7.0
See below for a manual on the basic drawing software itself, Lorien. As of v0.7.0, DrawN'Gcode is based off of Lorien v0.6.0 and is not compatable in project files. As the project progresses, expect project file to change -- do NOT open old project files with new versions of the software.

Hover mouse over input lines for more details.

## New Drawing Features
- Layer system
    - Draw separate layers of the print in new layers as different images
    - Duplicate layers if you want to modify existing image
    - See above and below layers for reference with onion skin setting
    - Move layers up and down to change print location
    - See previews of each drawing layer in the layer thumbnail
    - Specify how many times to duplicate a layer (stacked) in final gcode print
    - Toggle visibility of layer, and change layer name
- Palette - multi-material support
    - Specify which (vertical) axis nozzle to print from by making new color in palette
    - Separate axes with commas if wanting to print from multiple nozzles simultaneously (eg., coaxially)
- Settings
    - Set layer height, printing offsets, units, pre-extrusion amounts, and nozzle information in "Bioprinting" tab.
    - The order in which you specify the nozzle information is the print order for a single layer
    - Make and save separate settings for different printers by selecting and/or adding new printer
- Reference Image
    - Add reference image for easy tracing and reference of images while drawing layers

## Printing Features
- Export to gcode with .gcode or .txt files
    - Layers are stacked, separated by layer height amount specified in settings
    - Each layer is drawn/printed in the order strokes are drawn 
    - Between each stroke and layer, nozzles will jog up a bit to avoid colliding with print
    - The x-axis is flipped(?)
- Connect to printer
    - Directly connect to printer -- send commands and project gcode to printer directly
    - Move and adjust axes of printer, based also on axes specified in printer settings

---

# Lorien Manual v0.6.0

Drawing tablets are supported and recommended, but you can also just use Keyboard+Mouse. 

## Basic Usage
- Draw with the left mouse button (<kbd>LMB</kbd>) or with your drawing tablet's pen
- Pan/drag across the canvas with the middle mouse button (i recommend to map a button on your pen to the middle mouse button for easy navigation)
- Zoom with the mouse wheel. You can also zoom while holding <kbd>CTRL</kbd> and the middle mouse button <kbd>MMB</kbd> while moving the mose up/down. This is especially useful when using a drawing tablet with a pen.
- You can open files by dragging them into the window or by opening it via the menu (Shortcut <kbd>CTRL</kbd> + <kbd>O</kbd>)

## Tools
Lorien provides you with different tools which you can find in the toolbar. If you want to enable a tool all you have to do is click on it or use the keyboard shortcut. If you hover over the icons you can also see a short description including the keyboard shortcut.

### Brush Tool
- The brush tool is selected by default. It allows you to freely draw on the canvas with your mouse or drawing tablet. 
- You can change the brush size with the adjuster in the toolbar
- The brush color can be changed by clicking on the colored button in the toolbar next to the brush size adjuster 
- It is pressure sensitve

### Rectangle Tool
- You can use the rectangle tool to create perfect (unfilled) rectagles
- Not pressure sensitive 

### Line Tool
- Allows you to draw perfect lines
- You can hold down <kbd>Shift</kbd> while using the line tool to snap the line in 15° increments 
- Not pressure sensitve

### Circle Tool
- Allows you to draw perfect ellipses and circles
- You can hold down <kbd>Shift</kbd> while using the circle tool to draw perfect circles. Otherwise it defaults to ellipses
- Not pressure sensitve

### Eraser Tool
- Allows you to erease brush strokes by drawing over it. Once the eraser intersects with a brush stroke, the whole brush stroke will be removed
- The brush size affects the area of effect

### Selection Tool
- With the Selection tool you can select a number of brush strokes by dragging across the screen with your <kbd>LMB</kbd> pressed. Brush strokes which are considered inside the selection recatangle will be added to the current selection. You can add more strokes to your current selection by holding down <kbd>Shift</kbd> while dragging.
- You can deselect your current selection by pressing <kbd>RMB</kbd> or <kbd>Esc</kbd>.
- To move the selected strokes simply drag them while holding down <kbd>LMB</kbd>. If you did not move your mouse while pressing <kbd>LMB</kbd>, everything will be deselected automatically.
- Press <kbd>Delete</kbd> to delete the current selection
- Press <kbd>CTRL</kbd> + <kbd>C</kbd> to copy the current selection
- Press <kbd>CTRL</kbd> + <kbd>V</kbd> to paste the copied brush strokes
- Press <kbd>CTRL</kbd> + <kbd>D</kbd> to duplicate the current selection

## Color Palettes
- Color palettes allow you to easily switch between different pre-defined colors. To open the pallete you have to click on the colored button in the toolbar next to the brush size adjsuter.
- You can add/edit/delete custom color palettes
- The default color palette can't be edited or deleted. If you want to customize it you can can make a copy of it and edit that instead.

## Keyboard shortcuts
- <kbd>Ctrl</kbd> + <kbd>S</kbd>: Saves the current file
- <kbd>Ctrl</kbd> + <kbd>N</kbd>: Open a new file
- <kbd>Ctrl</kbd> + <kbd>O</kbd>: Open a new empty tab
- <kbd>Ctrl</kbd> + <kbd>E</kbd>: Opens the SVG export dialog
- <kbd>Ctrl</kbd> + <kbd>Z</kbd>: Undo a brush stroke
- <kbd>Ctrl</kbd> + <kbd>Y</kbd>: Redo a brush stroke
- <kbd>Ctrl</kbd> + <kbd>C</kbd>: Copy selected brush strokes
- <kbd>Ctrl</kbd> + <kbd>V</kbd>: Paste copied brush strokes
- <kbd>Ctrl</kbd> + <kbd>D</kbd>: Duplicate selected brush strokes
- <kbd>SPACE</kbd>: Center the canvas based on current mouse position
- <kbd>B</kbd>: Brush tool
- <kbd>R</kbd>: Rectangle tool
- <kbd>E</kbd>: Eraser tool
- <kbd>L</kbd>: Line tool
- <kbd>C</kbd>: Circle tool
- <kbd>S</kbd>: Selection tool
- <kbd>Esc</kbd> or <kbd>RMB</kbd>: Deselect everything
- <kbd>Delete</kbd>: Deletes selected brush strokes
- <kbd>Tab</kbd>: enter/exit distraction free mode (no UI)
- <kbd>F12</kbd>: Spwans a playable character at the mouse position who can walk on the drawn lines (easteregg)
