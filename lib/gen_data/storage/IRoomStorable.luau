local IAccessData = require(script.Parent.Parent.Parent.gen_setting.access.IAccessData)

export type IRoomStorable = {
	getPos: (self: IRoomStorable) -> Vector3,
	getAccessData: (self: IRoomStorable, accessNumero: number) -> IAccessData.IAccessData,
	getAccessNum: (self: IRoomStorable, relativeEntrancePos: Vector3) -> number,
	setAdjacent: (
		self: IRoomStorable,
		adjacent: IRoomStorable,
		accessData: IAccessData.IAccessData
	) -> (),
	setAdjacentByNum: (
		self: IRoomStorable,
		adjacent: IRoomStorable,
		accessNum: number
	) -> (),
	changeAdjacent: (
		self: IRoomStorable,
		adjacent: IRoomStorable,
		newAdjacent: IRoomStorable
	) -> (),
	iterateAdjacents: (self: IRoomStorable) -> ({}, number, nil) -> (number, IRoomStorable),
	isIncludingCell: (self: IRoomStorable, cellPos: Vector3) -> boolean,
	iterateAccessDatas: (
		self: IRoomStorable
	) -> ({}, number, nil) -> (number, IAccessData.IAccessData),
	check: (self: IRoomStorable, errorLog: string) -> Vector3,
}

return {}
