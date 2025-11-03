local ComplexTileDirections = require(script.Parent.Parent.ComplexTileDirections)
local Directions = require(script.Parent.Parent.Parent.gen_data.Directions)
local SimpleTileDirections = require(script.Parent.Parent.SimpleTileDirections)

type simpleTile = {
	--! thickness is not yet supported
	thickness: number?,
	model: Model,
}

type complexTile = {
	--! thickness is not yet supported
	thickness: number?,
	model: Model,
}

type deadEnd = {
	--! thickness is not yet supported
	thickness: number?,
	model: Model,
}

export type uniformTypeTileSet = {
	simple_tiles: { [SimpleTileDirections.Direction]: simpleTile },
	complex_tiles: {
		[ComplexTileDirections.Direction]: complexTile,
	},
	dead_ends: {
		[Directions.Direction]: deadEnd,
	},
}

type mixedSimpleTile = {
	first_access_type: number,
	second_access_type: number,
	thickness: number?,
	model: Model,
}

type mixedComplexTile = {
	access_types: { number },
	thickness: number?,
	model: Model,
}

export type mixedTypeTileSet = {
	simple_tiles: { [SimpleTileDirections.Direction]: mixedSimpleTile },
	complex_tiles: {
		[ComplexTileDirections.Direction]: mixedComplexTile,
	},
}

export type corridorTileSet = {
	-- A corridor type corresponds to an access type accepted by all its
	-- accesses.
	uniform_tiles: {
		[number]: uniformTypeTileSet,
	},
	mixed_tiles: mixedTypeTileSet,
}

export type roomDataSet = {
	{
		name: string,
		size: Vector3,
		accesses: {
			[number]: {
				type: number?,
				direction: Directions.Direction,
				position: Vector3,
			},
		},
		chance_to_spawn: number?,
		model: Model?,
		rotate_y: boolean?,
	}
}

export type roomDataSetJson = {
	data_set_name: string,
	data_set_version: number,
	cell_size: number?,
	rooms: roomDataSet,
	corridor_tiles: corridorTileSet,
}

return {}
