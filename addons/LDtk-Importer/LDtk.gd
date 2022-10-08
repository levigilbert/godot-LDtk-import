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
func get_layer_entities(layer, options):
	if layer.__type != 'Entities':
		return

	var entities = []
	for entity in layer.entityInstances:
		var new_entity = new_entity(entity, options)
		if new_entity:
			entities.append(new_entity)

	return entities


#create new entity
func new_entity(entity_data, options):
	var new_entity
	var metadata = []

	var is_custom_entity = false
	for prpoerty in entity_data:
		if prpoerty == "fieldInstances":
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
						_:
							if not options.Import_Custom_Entities:
								return

							var resource = load(field.__value)
							if not resource:
								printerr("Could not load resource: ", field.__value)
								return
							new_entity = resource.instance()
							new_entity.position = Vector2(entity_data.px[0], entity_data.px[1])
							is_custom_entity = true
				elif options.Import_Metadata:
					metadata.append({'name': field.__identifier, 'value': field.__value})
		elif options.Import_Metadata:
				metadata.append({'name': prpoerty, 'value': entity_data[prpoerty]})

	if not new_entity:
		new_entity = Node2D.new()

	for data in metadata:
		if data['name'] in new_entity:
			new_entity[data['name']] = data['value']
		else:
			new_entity.set_meta(data['name'], data['value'])

	if is_custom_entity:
		return new_entity

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
	var tilemap = TileMap.new()
	var tileset_data = get_layer_tileset_data(tilemap_data.layerDefUid)
	if not tileset_data:
		return

	tilemap.tile_set = new_tileset(tileset_data)
	tilemap.name = tilemap_data.__identifier
	tilemap.position = Vector2(tilemap_data.__pxTotalOffsetX, tilemap_data.__pxTotalOffsetY)
	tilemap.cell_size = Vector2(tilemap_data.__gridSize, tilemap_data.__gridSize)
	tilemap.modulate = Color(1,1,1, tilemap_data.__opacity)
	tilemap.visible = tilemap_data.visible

	match tilemap_data.__type:
		'Tiles':
			for tile in tilemap_data.gridTiles:
				var flip = int(tile["f"])
				var flipX = bool(flip & 1)
				var flipY = bool(flip & 2)
				var grid_coords = coordId_to_gridCoords(tile.d[0], tilemap_data.__cWid)
				tilemap.set_cellv(grid_coords, tile.t, flipX, flipY)
		'IntGrid', 'AutoLayer':
			for tile in tilemap_data.autoLayerTiles:
				var flip = int(tile["f"])
				var flipX = bool(flip & 1)
				var flipY = bool(flip & 2)
				var grid_coords = pxCoords_to_gridCoords(tile.px, tilemap_data.__gridSize)
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

			for data in tileset_data.customData:
				if tileId == data.tileId:
					var jsonObj = parse_json(data.data)

					if "light_occluder_shape" in data.data:
						tileset.tile_set_light_occluder(tileId, get_tile_light_occluder_custom_shape(tileId, jsonObj.light_occluder_shape))
					elif "light_occluder" in jsonObj and jsonObj.light_occluder == true:
						tileset.tile_set_light_occluder(tileId, get_tile_light_occluder(tileId, tileset_data))

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
	var gridX = coordId - (gridY * gridWidth)

	return Vector2(gridX, gridY)


#converts pixels to grid coordinates.
func pxCoords_to_gridCoords(pixelValues, gridSize):
	var gridY = floor(pixelValues[1] / gridSize)
	var gridX = floor(pixelValues[0] / gridSize)

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

func import_collisions(tilemap_data, options):
#return if options has collision import off or layer name isn't "Collisions"
	var shouldImportCollisions = options.Import_Collisions and tilemap_data.__identifier == "Collisions"
	if not shouldImportCollisions:
		return

#return if IntGrid layer is empty
	if not tilemap_data.intGridCsv:
		return

	var layer = StaticBody2D.new()
	layer.name = 'CollisionsLayer'
	layer.position = Vector2(tilemap_data.__pxTotalOffsetX, tilemap_data.__pxTotalOffsetY)

	var grid_width = tilemap_data.__cWid
	var grid_size = tilemap_data.__gridSize

	var tile_size = Vector2(grid_size, grid_size)

	var creatingCollision = false
	var endCollision = false
	var starting_position = Vector2.ZERO
	var ending_position = Vector2.ZERO
	var tile_count = 0
	var gridCoords = Vector2.ZERO

	for i in range(0, tilemap_data.intGridCsv.size()):
		var tileValue = tilemap_data.intGridCsv[i]
		var hasTile = tileValue != 0

#if no tile and not creating a collision shape, pass
		if not hasTile and not creatingCollision:
			continue

		if hasTile:
			tile_count += 1

#if tile and not currently making collision shape, start one
		if hasTile and not creatingCollision:
			gridCoords = coordId_to_gridCoords(i, grid_width)
			gridCoords *= tile_size
			gridCoords += (tile_size / 2)
			starting_position = gridCoords
			creatingCollision = true

		if not hasTile and creatingCollision:
			endCollision = true
			ending_position.x -= tile_size.x

#if tile is last tile in row end collision shape
		if hasTile and (i % int(grid_width)) == (grid_width - 1):
			endCollision = true

#if ending collision shape, create shape
		if endCollision:
#get tile grid coords
			gridCoords = coordId_to_gridCoords(i, grid_width)
#get ending pixel position
			gridCoords *= tile_size
			gridCoords += (tile_size / 2)
			ending_position += gridCoords
			var col_shape = get_collision_shape(tile_size, starting_position, ending_position, tile_count)
			layer.add_child(col_shape)
			col_shape.set_owner(layer)
			creatingCollision = false
			endCollision = false
			tile_count = 0
			gridCoords = Vector2.ZERO
			starting_position = Vector2.ZERO
			ending_position = Vector2.ZERO

	return layer


func get_collision_shape(tile_size, start_position, end_position, tile_count):
	var col_shape = CollisionShape2D.new()
	col_shape.shape = RectangleShape2D.new()
	col_shape.shape.extents.x = tile_count * (tile_size.x / 2)
	col_shape.shape.extents.y = tile_size.y / 2
	col_shape.position.x = ((start_position.x + end_position.x) / 2)
	col_shape.position.y = ((start_position.y + end_position.y) / 2)

	return col_shape

# Returns a OccluderPolygon2D for the given tile
func get_tile_light_occluder(tileId, tileset_data):
	var region = get_tile_region(tileId, tileset_data)
	var polygon = OccluderPolygon2D.new()

	polygon.set_polygon(PoolVector2Array([
		Vector2(region.size.x, 0), # top right
		region.size,               # bottom right
		Vector2(0, region.size.y), # bottom left
		Vector2.ZERO               # top left
	]))

	return polygon

# Returns a OccluderPolygon2D for the given tile with a predefined custom shape.
func get_tile_light_occluder_custom_shape(tileId, pointArray):
	var polygon = OccluderPolygon2D.new()

	var list = PoolVector2Array()
	for a in pointArray:
		list.append(Vector2(a.x, a.y))

	polygon.set_polygon(list)

	return polygon
