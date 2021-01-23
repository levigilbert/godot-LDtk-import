tool
extends Reference


var map_data setget _set_map_data


#setget mapdata from filepath.
func _set_map_data(filepath):
	if filepath is String:
		map_data = load_LDtk_file(filepath)


#get LDtk file as JSON.
func load_LDtk_file(filepath):
	var json_file = File.new()
	json_file.open(filepath, File.READ)
	var json = JSON.parse(json_file.get_as_text()).result
	json_file.close()

	json['base_dir'] = filepath.get_base_dir()

	return json


#get layer entities
func get_layer_entities(layer):
	if layer.__type != 'Entities':
		return

	var entities = []
	for entity in layer.entityInstances:
		var new_entity = new_entity(entity)
		entities.append(new_entity)

	return entities


#create new entity
func new_entity(entity_data):
	var new_entity
	if entity_data.fieldInstances:
		for field in entity_data.fieldInstances:
			if field.__identifier == 'NodeType' and field.__type == 'String':
				match field.__value:
					'Position2D':
						new_entity = Position2D.new()
					'Area2D':
						new_entity = Area2D.new()
					'KinematicBody2D':
						new_entity = KinematicBody2D.new()
					'RigidBody2D':
						new_entity = RigidBody2D.new()
					'StaticBody2D':
						new_entity = StaticBody2D.new()
	else:
		return

	match new_entity.get_class():
		'Area2D', 'KinematicBody2D', 'RigidBody2D', 'StaticBody2D':
			var col_shape = new_rectangle_collision_shape(get_entity_size(entity_data.__identifier))
			new_entity.add_child(col_shape)

	new_entity.name = entity_data.__identifier
	new_entity.position = Vector2(entity_data.px[0], entity_data.px[1])

	return new_entity


#create new RectangleShape2D
func new_rectangle_collision_shape(size):
	var col_shape = CollisionShape2D.new()
	col_shape.shape = RectangleShape2D.new()
	col_shape.shape.extents = size / 2
	col_shape.position = size / 2

	return col_shape


func get_entity_size(entity_identifier):
	for entity in map_data.defs.entities:
		if entity.identifier == entity_identifier:
			return Vector2(entity.width, entity.height)


#create new TileMap from tilemap_data.
func new_tilemap(tilemap_data):
	if tilemap_data.__type == 'IntGrid' and get_layer_tileset_data(tilemap_data.layerDefUid) == null:
		return

	var tilemap = TileMap.new()
	var tileset_data = get_layer_tileset_data(tilemap_data.layerDefUid)
	tilemap.tile_set = new_tileset(tileset_data)
	tilemap.name = tilemap_data.__identifier
	tilemap.position = Vector2(tilemap_data.__pxTotalOffsetX, tilemap_data.__pxTotalOffsetY)
	tilemap.cell_size = Vector2(tilemap_data.__gridSize, tilemap_data.__gridSize)
	tilemap.modulate = Color(1,1,1, tilemap_data.__opacity)

	match tilemap_data.__type:
		'Tiles':
			for tile in tilemap_data.gridTiles:
				var flip = int(tile["f"])
				var flipX = bool(flip & 1)
				var flipY = bool(flip & 2)
				var grid_coords = coordId_to_gridCoords(tile.d[0], tilemap_data.__cWid)
#				tilemap.set_cellv(grid_coords, tile.d[0], flipX, flipY)
				tilemap.set_cellv(grid_coords, tile.t, flipX, flipY)
		'IntGrid', 'AutoLayer':
			for tile in tilemap_data.autoLayerTiles:
				var flip = int(tile["f"])
				var flipX = bool(flip & 1)
				var flipY = bool(flip & 2)
				var grid_coords = coordId_to_gridCoords(tile.d[1], tilemap_data.__cWid)
				tilemap.set_cellv(grid_coords, tile.d[1], flipX, flipY)
				tilemap.set_cellv(grid_coords, tile.t, flipX, flipY)


	return tilemap


#create new tileset from tileset_data.
func new_tileset(tileset_data):
	var tileset = TileSet.new()
	var texture_filepath = map_data.base_dir + '/' + tileset_data.relPath
	var texture = load(texture_filepath)

	var texture_image = texture.get_data()

	var gridWidth = (tileset_data.pxWid - tileset_data.padding) / (tileset_data.tileGridSize + tileset_data.spacing)
	var gridHeight = (tileset_data.pxHei - tileset_data.padding) / (tileset_data.tileGridSize + tileset_data.spacing)
	var gridSize = gridWidth * gridHeight

	for tileId in range(0, gridSize):
		var tile_image = texture_image.get_rect(get_tile_region(tileId, tileset_data))
		if not tile_image.is_invisible():
			tileset.create_tile(tileId)
			tileset.tile_set_tile_mode(tileId, TileSet.SINGLE_TILE)
			tileset.tile_set_texture(tileId, texture)
			tileset.tile_set_region(tileId, get_tile_region(tileId, tileset_data))

	return tileset


#get layer tileset_data by layerDefUid.
func get_layer_tileset_data(layerDefUid):
	var tilesetId
	for layer in map_data.defs.layers:
		if layer.uid == layerDefUid:
			match layer.__type:
				'AutoLayer', 'IntGrid':
					tilesetId = layer.autoTilesetDefUid
				'Tiles':
					tilesetId = layer.tilesetDefUid

	for tileset_data in map_data.defs.tilesets:
		if tileset_data.uid == tilesetId:
			return tileset_data


#get tile region(Rect2) by tileId.
func get_tile_region(tileId, tileset_data):
	var padding = tileset_data.padding
	var spacing = tileset_data.spacing
	var atlasGridSize = tileset_data.tileGridSize
	var atlasGridWidth = tileset_data.pxWid / atlasGridSize
	var pixelTile = tileId_to_pxCoords(tileId, atlasGridSize, atlasGridWidth, padding, spacing)

	var rect = Rect2(pixelTile, Vector2(atlasGridSize, atlasGridSize))

	return rect


#converts coordId to grid coordinates.
func coordId_to_gridCoords(coordId, gridWidth):
	var gridY = floor(coordId / gridWidth)
	var gridX = coordId - gridY * gridWidth

	return Vector2(gridX, gridY)


#converts tileId to grid coordinates.
func tileId_to_gridCoords(tileId, atlasGridWidth):
	var gridTileX = tileId - atlasGridWidth * int(tileId / atlasGridWidth)
	var gridTileY = int(tileId / atlasGridWidth)

	return Vector2(gridTileX, gridTileY)


#converts tileId to pixel coordinates.
func tileId_to_pxCoords(tileId, atlasGridSize, atlasGridWidth, padding, spacing):
	var gridCoords = tileId_to_gridCoords(tileId, atlasGridWidth)
	var pixelTileX = padding + gridCoords.x * (atlasGridSize + spacing)
	var pixelTileY = padding + gridCoords.y * (atlasGridSize + spacing)

	return Vector2(pixelTileX, pixelTileY)
