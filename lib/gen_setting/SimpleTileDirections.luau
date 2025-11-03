local Directions = require(script.Parent.Parent.gen_data.Directions)
export type Direction = {
	[number]: Directions.Direction,
}

return {
	-- simple directions
	NORTH_WEST = { Directions.NORTH, Directions.WEST },
	NORTH_SOUTH = { Directions.NORTH, Directions.SOUTH },
	NORTH_EAST = { Directions.NORTH, Directions.EAST },
	WEST_SOUTH = { Directions.WEST, Directions.SOUTH },
	WEST_EAST = { Directions.WEST, Directions.EAST },
	SOUTH_EAST = { Directions.EAST, Directions.EAST },
}
