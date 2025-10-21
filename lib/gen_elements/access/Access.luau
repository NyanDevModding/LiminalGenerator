local IRoomStorable = require(script.Parent.Parent.Parent.gen_data.storage.IRoomStorable)
local IAccessData = require(script.Parent.Parent.Parent.gen_setting.access.IAccessData)

local function createAccess(
	wrappedRoom: IRoomStorable.IRoomStorable,
	access: IAccessData.IAccessData,
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

export type Access = typeof(createAccess())

return {
	createAccess = createAccess,
}
