local Directions = require(script.Parent.Parent.Parent.gen_data.Directions)
export type IAccess = {
	getAccessType: (self: IAccess) -> number,
	getRelativePosition: (self: IAccess) -> Vector3, -- in cells
	getDirection: (self: IAccess) -> Directions.Direction,
	getRelativeEntrancePos: (self: IAccess) -> Vector3,
}

return {}
