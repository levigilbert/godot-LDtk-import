extends "res://addons/gut/test.gd"


class TestLoadMapData:
	extends "res://addons/gut/test.gd"

	var LDtk = load("res://addons/LDtk-Importer/LDtk.gd").new()


	func test_load_map_data():
		LDtk.map_data = 'res://testmap.ldtk'
		assert_eq(LDtk.map_data.__header__.fileType, "LDtk Project JSON")
		var loaded_data = LDtk.load_LDtk_file('res://testmap.ldtk')
		assert_eq(loaded_data.__header__.fileType, "LDtk Project JSON")


class TestConversions:
	extends "res://addons/gut/test.gd"

	var LDtk = load("res://addons/LDtk-Importer/LDtk.gd").new()


	func test_coordId_to_gridCoords():
		var coordId = 16
		var gridWidth = 8
		var gridCoords = LDtk.coordId_to_gridCoords(coordId, gridWidth)
		assert_eq(gridCoords, Vector2(0, 2))

		coordId = 32
		gridCoords = LDtk.coordId_to_gridCoords(coordId, gridWidth)
		assert_eq(gridCoords, Vector2(0, 4))


	func test_tileId_to_gridCoords():
		var tileId = 16
		var gridWidth = 8
		var gridCoords = LDtk.tileId_to_gridCoords(tileId, gridWidth)
		assert_eq(gridCoords, Vector2(0, 2))

		tileId = 32
		gridCoords = LDtk.tileId_to_gridCoords(tileId, gridWidth)
		assert_eq(gridCoords, Vector2(0, 4))


	func test_tileId_to_pxCoords():
		var tileId = 16
		var atlasGridWidth = 8
		var atlasGridSize = 8
		var padding = 0
		var spacing = 0
		var pxCoords = LDtk.tileId_to_pxCoords(tileId, atlasGridSize, atlasGridWidth, padding, spacing)
		assert_eq(pxCoords, Vector2(0, 16))

		padding = 2
		spacing = 2
		pxCoords = LDtk.tileId_to_pxCoords(tileId, atlasGridSize, atlasGridWidth, padding, spacing)
		assert_eq(pxCoords, Vector2(2, 22))

		tileId = 18
		pxCoords = LDtk.tileId_to_pxCoords(tileId, atlasGridSize, atlasGridWidth, padding, spacing)
		assert_eq(pxCoords, Vector2(22, 22))


class TestTileSet:
	extends "res://addons/gut/test.gd"

	var LDtk = load("res://addons/LDtk-Importer/LDtk.gd").new()


	func test_get_tile_region():
		var tileId = 16
		var tileset_data = {
			'padding' : 0,
			'spacing' : 0,
			'tileGridSize' : 8,
			'pxWid' : 256
		}
		var tile_region = LDtk.get_tile_region(tileId, tileset_data)
		#rect properties
		var x = 128
		var y = 0
		var width = 8
		var height = 8
		assert_eq(tile_region, Rect2(x,y,width,height))


	func test_new_tileset():
		LDtk.map_data = 'res://testmap.ldtk'
		var tileset_data = LDtk.map_data.defs.tilesets[0]
		var tileset = LDtk.new_tileset(tileset_data)

		var tile_count = 205
		var tilset_tile_array = tileset.get_tiles_ids()
		assert_eq(tilset_tile_array.size(), tile_count)


class TestLayerTypes:
	extends "res://addons/gut/test.gd"

	var LDtk = load("res://addons/LDtk-Importer/LDtk.gd").new()

	func test_tiles_layer():
		LDtk.map_data = 'res://testmap.ldtk'
		var tilemap_data = LDtk.map_data.levels[0].layerInstances[0]
		var tilemap = LDtk.new_tilemap(tilemap_data)
		assert_eq(tilemap.name, 'Ground')
		assert_eq(tilemap.cell_size, Vector2(8,8))

		tilemap.free()


	func test_autolayer_layer():
		LDtk.map_data = 'res://testmap.ldtk'
		var tilemap_data = LDtk.map_data.levels[0].layerInstances[1]
		var tilemap = LDtk.new_tilemap(tilemap_data)
		assert_eq(tilemap.name, 'AutoLayer')
		assert_eq(tilemap.cell_size, Vector2(8,8))

		tilemap.free()


	func test_intgrid_layer_without_tileset():
		LDtk.map_data = 'res://testmap.ldtk'
		var tilemap_data = LDtk.map_data.levels[0].layerInstances[2]
		var tilemap = LDtk.new_tilemap(tilemap_data)
		assert_false(tilemap)


	func test_intgrid_layer_with_tileset():
		LDtk.map_data = 'res://testmap.ldtk'
		var tilemap_data = LDtk.map_data.levels[0].layerInstances[3]
		var tilemap = LDtk.new_tilemap(tilemap_data)
		assert_eq(tilemap.name, 'IntGridTiles')
		assert_eq(tilemap.cell_size, Vector2(8,8))

		tilemap.free()
