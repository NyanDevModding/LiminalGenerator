local IAccessData = require(script.Parent.Parent.Parent.gen_setting.access.IAccessData)

export type IRoomStorable = {
	getPos: (self: IRoomStorable) -> Vector3,
	getAccessData: (self: IRoomStorable, accessNumero: number) -> IAccessData.IAccessData,
	getAccessNum: (self: IRoomStorable, relativeEntrancePos: Vector3) -> number,
	setAdjacent: (
		self: IRoomStorable,
		adjacent: IRoomStorable,
		accessNumero: number,
		accessData: IAccessData.IAccessData
	) -> (),
	changeAdjacent: (
		self: IRoomStorable,
		adjacent: IRoomStorable,
		newAdjacent: IRoomStorable
	) -> (),
	iterateAdjacents: (self: IRoomStorable) -> Vector3,
	isIncludingCell: (self: IRoomStorable, cellPos: Vector3) -> boolean,
	check: (self: IRoomStorable, errorLog: string) -> Vector3,
}

return {}
