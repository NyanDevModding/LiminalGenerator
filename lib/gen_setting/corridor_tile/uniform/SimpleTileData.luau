local SimpleTileDirections = require(script.Parent.Parent.Parent.SimpleTileDirections)

local SimpleTileData = {}
SimpleTileData.__index = SimpleTileData

export type SimpleTileData = typeof(SimpleTileData.new())

function SimpleTileData.new(
	direction: SimpleTileDirections.Direction,
	accessType: number,
	thickness: number,
	model: Model
)
	return setmetatable({
		_direction = direction,
		_accessType = accessType,
		_thickness = thickness,
		_model = model,
	}, SimpleTileData)
end

function SimpleTileData.getDirection(self: SimpleTileData)
	return self._direction
end

function SimpleTileData.getAccessType(self: SimpleTileData)
	return self._accessType
end

function SimpleTileData.getFirstEntranceRelativePos(self: SimpleTileData)
	return self._direction[1]
end

function SimpleTileData.getSecondEntranceRelativePos(self: SimpleTileData)
	return self._direction[2]
end

function SimpleTileData.getThickness(self: SimpleTileData)
	return self._thickness
end

function SimpleTileData.getModel(self: SimpleTileData)
	return self._model
end

return SimpleTileData
