local RoomData = require(script.Parent.RoomData)
local IAccessData = require(script.Parent.Parent.access.IAccessData)

local RoomDataBuilder = {}
RoomDataBuilder.__index = RoomDataBuilder

export type RoomDataBuilder = typeof(RoomDataBuilder.new())

function RoomDataBuilder.new(RoomDataName: string)
	return setmetatable({
		_RoomDataName = RoomDataName,
		_RoomDataAccesses = {},
	}, RoomDataBuilder)
end

function RoomDataBuilder.addAccess(self: RoomDataBuilder, access: IAccessData.IAccessData)
	table.insert(self._RoomDataAccesses, access)
end

function RoomDataBuilder.build(self: RoomDataBuilder)
	local result = RoomData.new(self._RoomDataName, self._RoomDataAccesses)
	self._RoomDataAccesses = nil
	return result
end

return RoomDataBuilder
