# godot-LDtk-import
- Godot version: 3.2.3
- LDtk version: 0.6.2

Basic GDscript for importing LDtk files into the Godot game engine.

- [Godot Website](https://godotengine.org/)
- [LDtk Website](https://deepnight.net/tools/ldtk-2d-level-editor/)
- [LDtk Docs](https://deepnight.net/docs/ldtk/)
- [LDtk JSON Format](https://github.com/deepnight/ldtk/blob/master/JSON_DOC.md)

## Updates:
### 11/24/2020:
- removed import files
### 11/22/2020:
- The Importer is now an addon/plugin.
- added basic import options for Entities.
### 11/13/2020:
- Added basic functionality for autolayers and intgrid layers.

Can now create tilemaps from autolayers and intgrid layers with tilesets.  Intgrid layers without tilesets are ignored currently.
### 11/12/2020:
- Currently this script has very basic functionality.  Only Tile Layers are currently working.

## How to use:
1. Copy the addons folder to your godot project folder.
2. Enable LDtk Importer under Project Settings/Plugins.
3. Add a .ldtk map file or use the example testmap.ldtk, the map will be imported as a .tscn file

## Tips:
- IntGrid, Tiles, and AutoLayers are imported as TileMap Nodes.
- Currently Entities have very basic functionality, checkout the testmap.ldtk for examples.

### Entities:
You can set up how your entities are imported:
1. Create a new Entity
2. Add a String Field Type
3. Set the Field Identifier to: `NodeType`
4. Set the Default Value to the type of Node

Current node options are:
- Position2D
- Area2D
- KinematicBody2D
- RigidBody2D
- StaticBody2D

## Notes:
- The example is using the tileset that comes with LDtk: `Cavernas_by_Adam_Saltsman.png`
- The conversion functions: `coordId_to_gridCoords(), tileId_to_gridCoords(), tileId_to_pxCoords()` are from the LDtk documentation. 
