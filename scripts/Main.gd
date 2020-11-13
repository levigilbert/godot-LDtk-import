extends Node2D


onready var LDtk = load("res://scripts/LDtk.gd").new()


func _ready():
	#load LDtk map
	LDtk.map_data = "res://testmap.ldtk"

	#add levels as node2d
	for level in LDtk.map_data.levels:
		var new_level = Node2D.new()
		new_level.name = level.identifier
		add_child(new_level)
		
		#add layers
		var layerInstances = get_level_layerInstances(level)
		for layerInstance in layerInstances:
			new_level.add_child(layerInstance)


#create tilemaps from layers in level
func get_level_layerInstances(level):
	var layers = []
	for layerInstance in level.layerInstances:
		var new_layer = LDtk.new_tilemap(layerInstance)
		if new_layer:
			layers.append(new_layer)

	return layers
