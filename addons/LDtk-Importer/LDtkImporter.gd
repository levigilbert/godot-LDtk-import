tool
extends EditorImportPlugin


var LDtk = preload("LDtk.gd").new()


func get_importer_name():
	return "LDtk.import"


func get_visible_name():
	return "LDtk Importer"


func get_recognized_extensions():
	return ["ldtk"]


func get_save_extension():
	return "scn"


func get_preset_count():
	return 1


func get_preset_name(preset):
	return "Default"


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
		var layerInstances = get_level_layerInstances(level)
		for layerInstance in layerInstances:
			new_level.add_child(layerInstance)
			layerInstance.set_owner(map)

			for child in layerInstance.get_children():
				child.set_owner(map)
				for grandchild in child.get_children():
					grandchild.set_owner(map)

	var packed_scene = PackedScene.new()
	packed_scene.pack(map)

	return ResourceSaver.save("testmap.tscn", packed_scene)


#create layers in level
func get_level_layerInstances(level):
	var layers = []
	for layerInstance in level.layerInstances:
		match layerInstance.__type:
			'Entities':
				var new_node = Node2D.new()
				new_node.name = layerInstance.__identifier
				var entities = LDtk.get_layer_entities(layerInstance)
				for entity in entities:
					new_node.add_child(entity)

				layers.append(new_node)
			'Tiles', 'IntGrid', 'AutoLayer':
				var new_layer = LDtk.new_tilemap(layerInstance)
				if new_layer:
					layers.append(new_layer)

	return layers
