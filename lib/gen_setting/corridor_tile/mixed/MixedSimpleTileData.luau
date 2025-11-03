local SimpleTileDirections = require(script.Parent.Parent.Parent.SimpleTileDirections)

local MixedSimpleTileData = {}
MixedSimpleTileData.__index = MixedSimpleTileData

export type MixedSimpleTileData = typeof(MixedSimpleTileData.new())

function MixedSimpleTileData.new(
	firstAccessType: number,
	secondAccessType: number,
	direction: SimpleTileDirections.Direction,
	thickness: number,
	model: Model
)
	return setmetatable({
		_firstAccessType = firstAccessType,
		_secondAccessType = secondAccessType,
		_direction = direction,
		_thickness = thickness,
		_model = model,
	}, MixedSimpleTileData)
end

function MixedSimpleTileData.getDirection(self: MixedSimpleTileData)
	return self._direction
end

function MixedSimpleTileData.getFirstAccessType(self: MixedSimpleTileData)
	return self._firstAccessType
end

function MixedSimpleTileData.getSecondAccessType(self: MixedSimpleTileData)
	return self._secondAccessType
end

function MixedSimpleTileData.getFirstEntranceRelativePos(self: MixedSimpleTileData)
	return self._direction[1]
end

function MixedSimpleTileData.getSecondEntranceRelativePos(self: MixedSimpleTileData)
	return self._direction[2]
end

function MixedSimpleTileData.getThickness(self: MixedSimpleTileData)
	return self._thickness
end

function MixedSimpleTileData.getModel(self: MixedSimpleTileData)
	return self._model
end

return MixedSimpleTileData
