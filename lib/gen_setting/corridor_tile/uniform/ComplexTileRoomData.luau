local ComplexTileDirections = require(script.Parent.Parent.Parent.ComplexTileDirections)
local AccessData = require(script.Parent.Parent.Parent.access.AccessData)

-- Implements RoomData's interface
local ComplexTileRoomData = {}
ComplexTileRoomData.__index = ComplexTileRoomData

export type ComplexTileRoomData = typeof(ComplexTileRoomData.new())

function ComplexTileRoomData.new(
	direction: ComplexTileDirections.Direction,
	accessType: number,
	thickness: number,
	model: Model
)
	local accessDatas = {}
	for i, direction in ipairs(direction) do
		accessDatas[i] = AccessData.new(accessType, Vector3.zero, direction)
	end

	return setmetatable({
		_name = ("complex_uniform_tile_type#%i_directions{1:{%s},2:{%s},3:{%s},4:{%s}}"):format(
			accessType,
			tostring(direction[1]),
			tostring(direction[2]),
			tostring(direction[3]),
			tostring(direction[4])
		),
		_direction = direction,
		_accessType = accessType,
		_thickness = thickness,
		_model = model,
		_accessDatas = accessDatas,
	}, ComplexTileRoomData)
end

function ComplexTileRoomData.getName(self: ComplexTileRoomData)
	return self._name
end

function ComplexTileRoomData.isCorridorTile(self: ComplexTileRoomData)
	return true
end

function ComplexTileRoomData.getSize(self: ComplexTileRoomData)
	return Vector3.zero
end

function ComplexTileRoomData.getDirection(self: ComplexTileRoomData)
	return self._direction
end

function ComplexTileRoomData.getChanceToSpawn()
	return 1
end

function ComplexTileRoomData.getAccessType(self: ComplexTileRoomData)
	return self._accessType
end

function ComplexTileRoomData.getAccessData(self: ComplexTileRoomData, accessNum: number)
	return self._accessDatas[accessNum]
end

function ComplexTileRoomData.getAccessRelativePos(self: ComplexTileRoomData, accessNum: number)
	return Vector3.zero
end

function ComplexTileRoomData.getAccessRelativeEntrancePos(
	self: ComplexTileRoomData,
	accessNum: number
)
	return self._direction[accessNum]
end

function ComplexTileRoomData.getAccessNum(
	self: ComplexTileRoomData,
	relativeEntrancePos: Vector3
): number?
	for accessNum, accessEntrancePos in ipairs(self._direction) do
		if accessEntrancePos == relativeEntrancePos then
			return accessNum
		end
	end

	return nil
end

function ComplexTileRoomData.getAccessNumber(self: ComplexTileRoomData)
	return if self._direction == ComplexTileDirections.NORTH_WEST_SOUTH_EAST then 4 else 3
end

function ComplexTileRoomData.getThickness(self: ComplexTileRoomData)
	return self._thickness
end

function ComplexTileRoomData.getModel(self: ComplexTileRoomData)
	return self._model
end

function ComplexTileRoomData.iterateAccessDatas(self: ComplexTileRoomData)
	return ipairs(self._accessDatas)
end

return ComplexTileRoomData
