# godot-LDtk-import
- Godot version: 3.4.4
- LDtk version: 1.1.3

Basic GDscript for importing LDtk files into the Godot game engine.

- [Godot Website](https://godotengine.org/)
- [LDtk Website](https://deepnight.net/tools/ldtk-2d-level-editor/)
- [LDtk Docs](https://deepnight.net/docs/ldtk/)
- [LDtk JSON Format](https://github.com/deepnight/ldtk/blob/master/JSON_DOC.md)

## Updates:
### 7/17/2022
- New feature: Post Import Script (thanks to univeous)
- Fixed entities not saving CollisionShape2D's
### 7/4/2022
- Updated to Godot version 3.4.4
- Updated to LDtk version 1.1.3
- Fixed collision layer import.
- Rewrote some of the information below on how to use the importer.
### 5/29/2021
- Added option to import entities layer as YSort.
### 3/15/2021
- Added option to import custom entities.
- Added option to import metadata.
- Added option to import collisions.
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
4. Select your .ldtk file and open the Import menu to toggle importing collisions, custom entities, metadata, and YSort.

## Tips:
- IntGrid, Tiles, and AutoLayers are imported as TileMap Nodes.
- Currently Entities have very basic functionality, checkout the testmap.ldtk for examples.

## Import Menu Options:
- Import_Collisions: Import collisions from IntGrid layer (see import collisions below).
- Import_Custom_Entities: Import your own Resources (see entities). Keep in mind that this will remove the other node options (they will still be imported, but only as Node2D).
- Import_Metadata: Import any fields set on entities or levels. For entities, If they have an exported property with the same name, it will set the value of the property with the value on LDtk, if they don't (or the plugin can't find it), they will be imported as metadata (using 'set_meta()') and can be retrieved later using 'get_meta()' on the imported object. Level's fields will all be imported as metadata.
- Import_YSort_Entities_Layer: Any Entities Layer whose name begins with "YSort" will be imported as a YSort node, and all the entities will be set as children of this YSort node.
- Post_Import_Script: The selected script will have it's `post_import(scene)` method run. This
enables you to change the generated scene automatically upon each reimport.
The `post_import` method will receive the built scene and **must**
return the changed scene.

## Importing Collisions:
- Create an IntGrid layer called "Collisions", tiles on this layer will be made into CollisionShape2D and added to a StaticBody2D node.

### Entities:
You can set up how your entities are imported:
1. Create a new Entity
2. Add a String Field Type
3. Set the Field Identifier to: `NodeType`
4. Set the Default Value to the type of Node
5. Any fields added to the entity on LDtk can set properties on the object or be added as metadata if the option is set when importing (retrieve using the function 'get_meta()' on the object after importing).

Current node options are:
1. If not using Custom Entities:
    - Position2D
    - Area2D
    - KinematicBody2D
    - RigidBody2D
    - StaticBody2D
    
2. If using Custom Entities:
    - Set the Default Value to the resource path (eg: 'res://Player.tscn').

## Notes:
- The example is using the tileset that comes with LDtk: `Cavernas_by_Adam_Saltsman.png`
- The conversion functions: `coordId_to_gridCoords(), tileId_to_gridCoords(), tileId_to_pxCoords()` are from the LDtk documentation. 
