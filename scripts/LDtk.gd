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

	return json


#create new tilemap from tilemap_data.  Currently only works for Tile layers.
func new_tilemap(tilemap_data):
	if tilemap_data.__type == 'IntGrid' and get_layer_tileset_data(tilemap_data.layerDefUid) == null:
		print('intgrid null')
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
				var grid_coords = coordId_to_gridCoords(tile.d[0], tilemap_data.__cWid)
				tilemap.set_cellv(grid_coords, tile.d[1])
		'IntGrid', 'AutoLayer':
			for tile in tilemap_data.autoLayerTiles:
				var grid_coords = coordId_to_gridCoords(tile.d[1], tilemap_data.__cWid)
				tilemap.set_cellv(grid_coords, tile.d[2])

	return tilemap


#create new tileset from tileset_data.
func new_tileset(tileset_data):
	var tileset = TileSet.new()
	var texture_filepath = 'res://' + tileset_data.relPath
	var texture = load(texture_filepath)

	for tileId in tileset_data.opaqueTiles:
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
