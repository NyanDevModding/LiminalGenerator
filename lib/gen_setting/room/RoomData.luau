local IAccessData = require(script.Parent.Parent.access.IAccessData)

local RoomData = {}
RoomData.__index = RoomData

export type RoomData = typeof(RoomData.new())

function RoomData.new(
	RoomDataName: string,
	size: Vector3,
	accessesData: { [number]: IAccessData.IAccessData },
	chanceToSpawn: number
)
	return setmetatable({
		_RoomDataName = RoomDataName,
		_size = size,
		_accessAmount = #accessesData,
		_accessesData = accessesData,
		_chanceToSpawn = chanceToSpawn,
	}, RoomData)
end

function RoomData.getName(self: RoomData)
	return self._RoomDataName
end

function RoomData.getSize(self: RoomData)
	return self._size
end

function RoomData.getChanceToSpawn(self: RoomData)
	return self._chanceToSpawn
end

function RoomData.getAccessData(self: RoomData, accessNum: number)
	return self._accessesData[accessNum]
end

function RoomData.getAccessRelativeEntrancePos(self: RoomData, accessNum: number)
	return self._accessesData[accessNum]:getRelativeEntrancePos()
end

function RoomData.getAccessNumber(self: RoomData)
	return #self._accessesData
end

function RoomData.iterateAccessDatas(self: RoomData)
	return ipairs(self._accessesData)
end

return RoomData
