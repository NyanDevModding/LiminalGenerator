local ComplexTileDirections = require(script.Parent.Parent.Parent.ComplexTileDirections)

local MixedComplexTileData = {}
MixedComplexTileData.__index = MixedComplexTileData

export type MixedComplexTileData = typeof(MixedComplexTileData.new())

function MixedComplexTileData.new(
	accessTypes: { number },
	direction: ComplexTileDirections.Direction,
	thickness: number,
	model: Model
)
	return setmetatable({
		_direction = direction,
		_accessTypes = accessTypes,
		_thickness = thickness,
		_model = model,
	}, MixedComplexTileData)
end

function MixedComplexTileData.getDirection(self: MixedComplexTileData)
	return self._direction
end

function MixedComplexTileData.getAccessType(self: MixedComplexTileData, accessNum: number)
	return self._accessTypes[accessNum]
end

function MixedComplexTileData.getEntranceRelativePos(self: MixedComplexTileData, accessNum: number)
	return self._direction[accessNum]
end

function MixedComplexTileData.getThickness(self: MixedComplexTileData)
	return self._thickness
end

function MixedComplexTileData.getModel(self: MixedComplexTileData)
	return self._model
end

return MixedComplexTileData
