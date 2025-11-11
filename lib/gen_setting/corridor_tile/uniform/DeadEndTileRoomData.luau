local Directions = require(script.Parent.Parent.Parent.Parent.gen_data.Directions)
local AccessData = require(script.Parent.Parent.Parent.access.AccessData)

local DeadEndTileRoomData = {}
DeadEndTileRoomData.__index = DeadEndTileRoomData

export type DeadEndTileRoomData = typeof(DeadEndTileRoomData.new())

-- Same interface as DeadEndTileRoomData because it acts as a room too
function DeadEndTileRoomData.new(
	direction: Directions.Direction,
	accessType: number,
	thickness: number,
	model: Model
)
	return setmetatable({
		_name = ("dead_end_type#%i_direction#{%s}"):format(accessType, tostring(direction)),
		_direction = direction,
		_accessType = accessType,
		_thickness = thickness,
		_model = model,
		_accessData = AccessData.new(accessType, Vector3.zero, direction),
	}, DeadEndTileRoomData)
end

function DeadEndTileRoomData.getName(self: DeadEndTileRoomData)
	return self._name
end

function DeadEndTileRoomData.getSize(self: DeadEndTileRoomData)
	return Vector3.zero
end

function DeadEndTileRoomData.isCorridorTile(self: DeadEndTileRoomData)
	return true
end

function DeadEndTileRoomData.getEntranceRelativePos(self: DeadEndTileRoomData)
	return self._direction
end

function DeadEndTileRoomData.getThickness(self: DeadEndTileRoomData)
	return self._thickness
end

function DeadEndTileRoomData.getModel(self: DeadEndTileRoomData)
	return self._model
end

function DeadEndTileRoomData.getAccessType(self: DeadEndTileRoomData)
	return self._accessType
end

function DeadEndTileRoomData.getDirection(self: DeadEndTileRoomData)
	return self._direction
end

function DeadEndTileRoomData.getChanceToSpawn()
	return 1
end

function DeadEndTileRoomData.getAccessNum(
	self: DeadEndTileRoomData,
	relativeEntrancePos: Vector3
): number?
	if relativeEntrancePos == self._direction then
		return 1
	end

	return nil
end

function DeadEndTileRoomData.getAccessData(self: DeadEndTileRoomData)
	return self._accessData
end

function DeadEndTileRoomData.getAccessRelativeEntrancePos(self: DeadEndTileRoomData)
	return self._direction
end

function DeadEndTileRoomData.getAccessNumber()
	return 1
end

function DeadEndTileRoomData.iterateAccessDatas(self: DeadEndTileRoomData)
	return ipairs({ self._accessData })
end

return DeadEndTileRoomData
