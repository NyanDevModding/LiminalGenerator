export type IReadableGrid = {
	getXSize: (self: IReadableGrid) -> number,
	getYSize: (self: IReadableGrid) -> number,
	getZSize: (self: IReadableGrid) -> number,
	get: (self: IReadableGrid, x: number, y: number, z: number) -> number,
	volumeAnd: (
		self: IReadableGrid,
		x1: number,
		y1: number,
		z1: number,
		x2: number,
		y2: number,
		z2: number
	) -> boolean,
	volumeOr: (
		self: IReadableGrid,
		x1: number,
		y1: number,
		z1: number,
		x2: number,
		y2: number,
		z2: number
	) -> boolean,
	getFirstSetInLine: (self: IReadableGrid, p1: Vector3, length: Vector3) -> Vector3?,
}

return {}
