local IRoomStorable = require(script.Parent.Parent.Parent.gen_data.storage.IRoomStorable)
local IAccessData = require(script.Parent.Parent.Parent.gen_setting.access.IAccessData)

local function createAccess(
	room: IRoomStorable.IRoomStorable,
	access: IAccessData.IAccessData,
	-- The pos of the access
	x: number,
	y: number,
	z: number
)
	return {
		room = room,
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
