local Directions = require(script.Parent.Parent.gen_data.Directions)
export type Direction = { [number]: Directions.Direction }

return {
	-- complex directions
	NORTH_WEST_EAST = { Directions.NORTH, Directions.WEST, Directions.EAST },
	WEST_SOUTH_NORTH = { Directions.WEST, Directions.SOUTH, Directions.NORTH },
	SOUTH_EAST_WEST = { Directions.SOUTH, Directions.EAST, Directions.WEST },
	EAST_NORTH_SOUTH = { Directions.EAST, Directions.NORTH, Directions.SOUTH },
	NORTH_WEST_SOUTH_EAST = { Directions.NORTH, Directions.WEST, Directions.SOUTH, Directions.EAST },
}
