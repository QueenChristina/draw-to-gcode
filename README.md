# DrawN'Gcode - 2D Drawing to GCode

## Based on Lorien, 2D Drawing Software Made By MBRLabs
Draw and convert multiple 2D images into layered g-code for printing, with multi-material support for bioprinting, chocolate printing, 3D printing, and more! The only multi-layered software that converts multiple unique images into layered g-code with support for co-axial printing (mutliple nozzles printing at once and/or separately).

## Try it Yourself
Download at [https://eggcat.itch.io/draw-n-gcode](https://eggcat.itch.io/draw-n-gcode).

## Features
Make drawings over multiple layers and with multiple materials, and convert it into GCode.
- Vector layers
- Set layer name
- Layer system with undo-redo capatibility
- Converts each layer into G-Code, stacked on top of each other
- Can set amount of times a layer is duplicated (stacked) in G-Code
- Onion skin feature to allow you to trace over past and future layers
- Custom settings for printing, such as guide for size of print-bed, set units, and set layer height
- Supports multiple nozzles moving synchronously, such as for use coaxial printing, or separately
- Multimaterial support: any axes (not just Z or A), add offset between axes, and custom ordering
- Custom saved settings for nozzles, pre-extrusion amount, and axes by printer
- Save unique custom settings for multiple different printers

Note: Sending G-code and commands directly to the printer from Draw N' Gcode is a work in progress, but theoretically working! You can help me test it by using "Connect to Printer", then generate G-code and send to the printer. Use buttons to move axes of the printer. It supports moving any axes (vertical or extruder) defined in printer settings -- making this more versatile than typical printer software that assumes single nozzle. 

## Roadmap
- Undo-redo with duplicate layer amount
- Undo-redo with layer name
- Save layer name
- Better default palette
- Better settings: custom onion skin settings (modulate color of above/below layers, opacity, number of layers visible), set color of printbed platform outline
- Fix printbed size magnitude (10x)
- Export GCode settings on export as extra dialog, not in settings
- Extrusion amount based on pressure sensitivity
- Fill polygons with lattice structure and option to trace outline
- Import images such as bitmap and svg types
- Support raster layer
- Convert vector to raster layer, and/or handle when lines overlap on the same layer
- Editable points, filled polygons, and lines (settings for width, color/material, etc.) in vector layers
- Grid snap and ruler
- Default brush/line width size to match real scale/width size (default of 2.5 mm width)
- Solutions for embedded printing eg., allow for lines that are not parallel to XY plane to be traced (such as along Z-axis)
- Equation layers (print equations, not just images)
- More error handling for opening projects of the incorrect version / failure to open projects on launch
- Support language localization for the new features
- Pan and Zoom tools (as tools, not shortcuts)
- Support for touch (export to App store)

<img src="https://github.com/QueenChristina/draw-to-gcode/blob/main/images/gcode-demo.jpg" align="center"/>
<img src="https://github.com/QueenChristina/draw-to-gcode/blob/main/images/layers-demo.jpg" align="center"/>

## Credits
* mbrlabs: https://github.com/mbrlabs/Lorien (MIT license)
* NangiDev: https://github.com/NangiDev/GDSerCommPlugin (MIT license)
* Godot: https://godotengine.org/license/ (MIT license)
* Godot Engine Logo Copyright (c) 2017 Andrea Calabró
This work is licensed under a Creative Commons Attribution 4.0 International License (CC-BY-4.0 International) https://creativecommons.org/licenses/by/4.0/. 

## About the original software
<img src="https://raw.githubusercontent.com/mbrlabs/Lorien/main/images/lorien.png" align="left"/>
<p>
    <a href="https://github.com/mbrlabs/Lorien/actions">
        <img src="https://github.com/mbrlabs/Lorien/workflows/build/badge.svg" alt="Build Passing" />
    </a>
    <a href="https://github.com/mbrlabs/Lorien/blob/main/LICENSE">
        <img src="https://img.shields.io/github/license/mbrlabs/Lorien.svg" alt="License" />
    </a>
</p>

Lorien is an **infinite canvas drawing/note-taking app that is focused on performance, small savefiles and simplicity**. It's not based on bitmap images like Krita, Gimp or Photoshop; it rather saves brush strokes as a collection of points and renders them at runtime (kind of like SVG). It's primarily designed to be used as a digital notebook and as brainstorming tool. While it can totally be used to make small sketches and diagrams, it is not meant to replace traditional art programs that operate on bitmap images. It is entirely written in the [Godot Game Engine](https://godotengine.org/). For an overview on how to use Lorien have a look [at the manual](docs/manuals/manual_v0.5.0.md). 

![Lorien demo](https://raw.githubusercontent.com/mbrlabs/Lorien/main/images/lorien_demo.png)

⚠ **This is very much a WIP and still a bit rough around the edges** ⚠. The savefile format *might* also change in the future. Contributions (be it bug reports, code, art or [translations](docs/i18n.md)) are very welcome.

## Features as of v0.6.0-dev:
- Infinite canvas
- Infinite undo/redo
- (Almost) Infinite zoom
- Infinite grid
- Distraction free mode (toggles the UI on/off)
- Extremely small savefiles ([File format specs](docs/file_format.md))
- Work on multiple documents simultaneously
- [Tools](docs/manuals/manual_v0.5.0.md): Freehand brush, eraser, line tool, rectangle tool, circle/ellipse tool, selection tool
- Move and delete selected brush strokes
- SVG export
- Rebindable keyboard shortcuts
- Built-in and custom color palettes
- Designed to be used with a drawing tablet (Wacom, etc.). It also supports pressure sensitivity
- A little Surprise Mechanic™ when pressing F12
- Runs on Windows, Linux & macOS
- Localizations: English, German, Italian, Korean, Russian, Spanish, Turkish, Brazilian Portuguese, Chinese

## Download
You can download the latest stable releases on [Github](https://github.com/mbrlabs/Lorien/releases). 

If you want to check out the bleeding edge main branch without building the project yourself you can also check out the [CI builds](https://github.com/mbrlabs/Lorien/actions). But make sure to backup your files and be prepared for bugs if you do that.

## More information
- [Contributing Guide](docs/contributing.md)
- [Localization](docs/i18n.md)
- [Changelog](docs/changelog.md)
- [Roadmap](docs/roadmap.md)

## Credits
- Brush stroke antialiasing: [godot-antialiased-line2d](https://github.com/godot-extended-libraries/godot-antialiased-line2d)
- Icons used for the UI: [Remix Icon](https://remixicon.com/)
- Blurred background image of demo screenshot: https://unsplash.com/photos/nO0V_T0g2fM
