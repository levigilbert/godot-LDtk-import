# godot-LDtk-import
- Godot version: 3.2.3
- LDtk version: 0.6.2

Basic GDscript for importing LDtk files into the Godot game engine.

- [Godot Website](https://godotengine.org/)
- [LDtk Website](https://deepnight.net/tools/ldtk-2d-level-editor/)
- [LDtk Docs](https://deepnight.net/docs/ldtk/)
- [LDtk JSON Format](https://github.com/deepnight/ldtk/blob/master/JSON_DOC.md)

## Updates:
### 1/4/2021:
- Updated for new version of LDtk.
- Changed import style: instead of making a new scene you can just open the ldtk file.
### 11/24/2020:
- removed import files.
### 11/22/2020:
- The Importer is now an addon/plugin.
- Added basic import options for Entities.
### 11/13/2020:
- Added basic functionality for autolayers and intgrid layers.

Can now create tilemaps from autolayers and intgrid layers with tilesets.  Intgrid layers without tilesets are ignored currently.
### 11/12/2020:
- Currently this script has very basic functionality.  Only Tile Layers are currently working.

## How to use:
1. Copy the addons folder to your godot project folder.
2. Enable LDtk Importer under Project Settings/Plugins.
3. Add a .ldtk map file and any spritesheets you're using to your project folder.

## Tips:
- IntGrid, Tiles, and AutoLayers are imported as TileMap Nodes.
- Currently Entities have very basic functionality, checkout the testmap.ldtk for examples.

## Options:
- Import_Collisions: If you want to import collision for the tiles (see import collisions below) or not
- Import_Custom_Entities: If you want to import your own Resources (see entities), this should be set to true. Keep in mind that this will remove the other node options (they will still be imported, but only as Node2D).
- Import_Metadata: If set, will import any fields set on the entities as metadata (using 'set_meta()'). They can be retrieved later using 'get_meta()' on the imported object.

## Importing Collisions:
- Create a layer called "Collisions", any tile in it will have a RectangleShape2D added to in a new layer.

### Entities:
You can set up how your entities are imported:
1. Create a new Entity
2. Add a String Field Type
3. Set the Field Identifier to: `NodeType`
4. Set the Default Value to the type of Node
5. Any fields added to the entity can be added as metadata if the option is set when importing (retrieve using the function 'get_meta()' on the object after importing)

Current node options are:
1. If not using Custom Entities:
- Position2D
- Area2D
- KinematicBody2D
- RigidBody2D
- StaticBody2D
2. If using Custom Entities:
- Position2D, Area2D, KinematicBody2D, RigidBody2D, and StaticBody2D will be imported as Node2D
- Path to Resource (eg: 'res://Player.tscn'), this will use 'load().instance()' to create your existing node

## Notes:
- The example is using the tileset that comes with LDtk: `Cavernas_by_Adam_Saltsman.png`
- The conversion functions: `coordId_to_gridCoords(), tileId_to_gridCoords(), tileId_to_pxCoords()` are from the LDtk documentation. 
