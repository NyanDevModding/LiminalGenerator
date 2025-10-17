local IAccess = require(script.Parent.IAccess)
local IRoomStorable = require(script.Parent.Parent.Parent.gen_data.storage.IRoomStorable)

local function createAccessWrapper(
	wrappedRoom: IRoomStorable.IRoomStorable,
	access: IAccess.IAccess,
	x: number,
	y: number,
	z: number
)
	return {
		wrappedRoom = wrappedRoom,
		access = access,
		x = x,
		y = y,
		z = z,
		direction = access:getDirection(),
	}
end

export type AccessWrapper = typeof(createAccessWrapper())

return {
	createAccessWrapper = createAccessWrapper,
}
