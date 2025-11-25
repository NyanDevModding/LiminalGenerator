local SimpleTileDirections = require(script.Parent.Parent.Parent.SimpleTileDirections)
local AccessData = require(script.Parent.Parent.Parent.access.AccessData)

local SimpleTileRoomData = {}
SimpleTileRoomData.__index = SimpleTileRoomData

export type SimpleTileRoomData = typeof(SimpleTileRoomData.new())

function SimpleTileRoomData.new(
	direction: SimpleTileDirections.Direction,
	accessType: number,
	thickness: number,
	model: Model
)
	local accessDatas = {}
	for i, compoundDirection in ipairs(direction) do
		accessDatas[i] = AccessData.new(accessType, Vector3.zero, compoundDirection)
	end

	return setmetatable({
		_name = ("simple_tile_type#%i_direction#{1:{%s}, 2:{%s}}"):format(
			accessType,
			tostring(direction[1]),
			tostring(direction[2])
		),
		_direction = direction,
		_accessType = accessType,
		_thickness = thickness,
		_model = model,
		_accessDatas = accessDatas,
	}, SimpleTileRoomData)
end

function SimpleTileRoomData.getName(self: SimpleTileRoomData)
	return self._name
end

function SimpleTileRoomData.getSize(self: SimpleTileRoomData)
	return Vector3.zero
end

function SimpleTileRoomData.isCorridorTile(self: SimpleTileRoomData)
	return true
end

function SimpleTileRoomData.getDirection(self: SimpleTileRoomData)
	return self._direction
end

function SimpleTileRoomData.getAccessType(self: SimpleTileRoomData)
	return self._accessType
end

function SimpleTileRoomData.getFirstEntranceRelativePos(self: SimpleTileRoomData)
	return self._direction[1]
end

function SimpleTileRoomData.getSecondEntranceRelativePos(self: SimpleTileRoomData)
	return self._direction[2]
end

function SimpleTileRoomData.getThickness(self: SimpleTileRoomData)
	return self._thickness
end

function SimpleTileRoomData.getModel(self: SimpleTileRoomData)
	return self._model
end

function SimpleTileRoomData.getChanceToSpawn()
	return 1
end

function SimpleTileRoomData.getAccessNum(
	self: SimpleTileRoomData,
	relativeEntrancePos: Vector3
): number?
	for i, direction in ipairs(self._direction) do
		if relativeEntrancePos == direction then
			return i
		end
	end

	return nil
end

function SimpleTileRoomData.getAccessData(self: SimpleTileRoomData, accessNum: number)
	return self._accessDatas[accessNum]
end

function SimpleTileRoomData.getAccessRelativeEntrancePos(
	self: SimpleTileRoomData,
	accessNum: number
)
	return self._direction[accessNum]
end

function SimpleTileRoomData.getAccessNumber(self: SimpleTileRoomData)
	return #self._direction
end

function SimpleTileRoomData.iterateAccessDatas(self: SimpleTileRoomData)
	return ipairs(self._accessDatas)
end

return SimpleTileRoomData
