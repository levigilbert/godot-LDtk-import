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
			"hint_string": "If true, will import entity fields as metadata."
		},
		{
			"name": "Import_YSort_Entities_Layer",
			"default_value": false
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
		map.add_child(new_level)
		new_level.set_owner(map)

		#add layers
		var layerInstances = get_level_layerInstances(level, options)
		for layerInstance in layerInstances:
			new_level.add_child(layerInstance)
			layerInstance.set_owner(map)

			for child in layerInstance.get_children():
				child.set_owner(map)
				
				if not options.Import_Custom_Entities:
					for grandchild in child.get_children():
						grandchild.set_owner(map)

	var packed_scene = PackedScene.new()
	packed_scene.pack(map)

	return ResourceSaver.save("%s.%s" % [save_path, get_save_extension()], packed_scene)


#create layers in level
func get_level_layerInstances(level, options):
	var layers = []
	var i = level.layerInstances.size()
	for layerInstance in level.layerInstances:
		match layerInstance.__type:
			'Entities':
				var new_node = null
				if options.Import_YSort_Entities_Layer and layerInstance.__identifier.begins_with("YSort"):
					new_node = YSort.new()
				else:
					new_node = Node2D.new()
				new_node.z_index = i
				new_node.name = layerInstance.__identifier
				var entities = LDtk.get_layer_entities(layerInstance, level, options)
				for entity in entities:
					new_node.add_child(entity)

				layers.push_front(new_node)
			'Tiles', 'IntGrid', 'AutoLayer':
				var new_layer = LDtk.new_tilemap(layerInstance, level)
				if new_layer:
					new_layer.z_index = i
					layers.push_front(new_layer)

		if layerInstance.__type == 'IntGrid':
			var collision_layer = LDtk.import_collisions(layerInstance, level, options)
			if collision_layer:
				collision_layer.z_index = i
				layers.push_front(collision_layer)

		i -= 1

	return layers
