# godot-LDtk-import
- Godot version: 3.2.3
- LDtk version: 0.5.2

Basic GDscript for importing LDtk files into the Godot game engine.

This project is just a starting point.  Please feel free to use parts for your own projects or to get you started with using LDtk with Godot.

## 11/13/2020:
-Added basic functionality for autolayers and intgrid layers.
## 11/12/2020:
- Currently this script has very basic functionality.  Only Tile Layers are currently working.

## To-do:
- Entities

## How to use:
Take a look at main.gd for an example.  Also LDtk.gd has lots of comments and is fairly readable.

1. Create a new gdscript.
2. Add the LDtk script: `onready var LDtk = load("res://scripts/LDtk.gd")`
3. Load map data: `LDtk.map_data = "filepath"`

Check out the [LDtk JSON documentation](https://github.com/deepnight/ldtk/blob/master/JSON_DOC.md).

Basic data structure is composed of Levels that have Layers(layerInstances).  In the example map(testmap.ldtk) there is a level called "level01" and it has a tile layer called "Ground".

To create a new tilemap for the "Ground" tile layer:
- `var tilemap_data = LDtk.map_data.levels[0].layerInstances[0]`
- `var new_tilemap = LDtk.new_tilemap(tilemap_data)`

## Tips:
- load map: `LDtk.map_data = "filepath"`
- levels(Array) are located at: `LDtk.map_data.levels`
- layers(Array) within each level are called: `layerInstances`

## Notes:
- The example is using the tileset that comes with LDtk: `Cavernas_by_Adam_Saltsman.png`
- The conversion functions: `coordId_to_gridCoords(), tileId_to_gridCoords(), tileId_to_pxCoords()` are from the LDtk documentation. 
