local Directions = require(script.Parent.Parent.Parent.gen_data.Directions)

export type IAccessData = {
	getAccessType: (self: IAccessData) -> number,
	getRelativePosition: (self: IAccessData) -> Vector3, -- in cells
	getDirection: (self: IAccessData) -> Directions.Direction,
	getRelativeEntrancePos: (self: IAccessData) -> Vector3,
}

return {}
