tool
extends EditorImportPlugin


enum Presets { PRESET_DEFAULT, PRESET_COLLISIONS }
var LDtk = preload("LDtk.gd").new()


func get_importer_name():
	return "LDtk.import"


func get_visible_name():
	return "LDtk Scene"


func get_priority():
	return 1


func get_import_order():
	return 100


func get_resource_type():
	return "PackedScene"


func get_recognized_extensions():
	return ["ldtk"]


func get_save_extension():
	return "tscn"


func get_preset_count():
	return Presets.size()


func get_preset_name(preset):
	match preset:
		Presets.PRESET_DEFAULT:
			return "Default"
		Presets.PRESET_COLLISIONS:
			return "Import Collisions"


func get_import_options(preset):
	return [
		{
			"name": "Import_Collisions",
			"default_value": preset == Presets.PRESET_COLLISIONS
		},
		{
			"name": "Import_Custom_Entities",
			"default_value": true,
			"hint_string": "If true, will only use this project's scenes. If false, will import objects as simple scenes."
		},
		{
			"name": "Import_Metadata",
			"default_value": true,
			"hint_string": "If true, will import entity and level fields as metadata."
		},
		{
			"name": "Import_YSort_Entities_Layer",
			"default_value": false
		},
		{
			"name": "Post_Import_Script",
			"default_value": "",
			"property_hint": PROPERTY_HINT_FILE,
			"hint_string": "*.gd;GDScript"
		}
	]


func get_option_visibility(option, options):
	return true


func import(source_file, save_path, options, platform_v, r_gen_files):
#load LDtk map
	LDtk.map_data = source_file

	var map = Node2D.new()
	map.name = source_file.get_file().get_basename()

#add levels as Node2D
	for level in LDtk.map_data.levels:
		var new_level = Node2D.new()
		new_level.name = level.identifier
		new_level.position = Vector2(level.worldX, level.worldY)

#import level metadata
		if options.Import_Metadata:
			for property in level:
				if not property in ["layerInstances"]:
					if property == "fieldInstances":
						for field in level.fieldInstances:
							new_level.set_meta(field.__identifier, field.__value)
					else:
						new_level.set_meta(property, level[property])

		map.add_child(new_level)
		new_level.set_owner(map)

#add layers
		var layerInstances = get_level_layerInstances(level, options)
		for layerInstance in layerInstances:
			new_level.add_child(layerInstance)
			layerInstance.set_owner(map)

			var children = layerInstance.get_children()

			while children:
				for child in children:
					child.set_owner(map)
					if child.get_children():
						var grandchildren = child.get_children()
						children += grandchildren

					children.erase(child)

#Post imports script
	if not options.Post_Import_Script.empty():
		var script = load(options.Post_Import_Script)
		if not script or not script is GDScript:
			printerr("Post import script is not a GDScript.")
			return ERR_INVALID_PARAMETER

		script = script.new()
		if not script.has_method("post_import"):
			printerr("Post import script does not have a 'post_import' method.")
			return ERR_INVALID_PARAMETER

		map = script.post_import(map)

		if not map or not map is Node2D:
			printerr("Invalid scene returned from post import script.")
			return ERR_INVALID_DATA

	var packed_scene = PackedScene.new()
	packed_scene.pack(map)

	return ResourceSaver.save("%s.%s" % [save_path, get_save_extension()], packed_scene)


#create layers in level
func get_level_layerInstances(level, options):
	var layers = []
	var i = level.layerInstances.size()
	for layerInstance in level.layerInstances:
		var new_layer = null
		match layerInstance.__type:
			'Entities':
				if options.Import_YSort_Entities_Layer and layerInstance.__identifier.begins_with("YSort"):
					new_layer = YSort.new()
				else:
					new_layer = Node2D.new()
				var entities = LDtk.get_layer_entities(layerInstance, options)
				for entity in entities:
					new_layer.add_child(entity)
					entity.set_owner(new_layer)

			'Tiles', 'IntGrid', 'AutoLayer':
				new_layer = LDtk.new_tilemap(layerInstance)

#check for collision layer
		if layerInstance.__type == 'IntGrid':
			var collision_layer = LDtk.import_collisions(layerInstance, options)
			if collision_layer:
				layers.push_front(collision_layer)

#add new layer to layers array if not null
		if new_layer:
			new_layer.name = layerInstance.__identifier
			new_layer.position = Vector2(layerInstance.__pxTotalOffsetX, layerInstance.__pxTotalOffsetY)
			layers.push_front(new_layer)

		i -= 1

	return layers
