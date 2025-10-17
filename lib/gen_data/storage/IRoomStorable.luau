local IAccess = require(script.Parent.Parent.Parent.gen_elements.access.IAccess)

export type IRoomStorable = {
	getPos: (self: IRoomStorable) -> Vector3,
	getAccess: (self: IRoomStorable, accessNumero: number) -> IAccess.IAccess,
	setAdjacent: (
		self: IRoomStorable,
		adjacent: IRoomStorable,
		accessNumero: number,
		otherAccessNumero: number
	) -> Vector3,
	iterateAdjacents: (self: IRoomStorable) -> Vector3,
	isIncludingCell: (self: IRoomStorable, cellPos: Vector3) -> boolean,
	check: (self: IRoomStorable, errorLog: string) -> Vector3,
}

return {}
