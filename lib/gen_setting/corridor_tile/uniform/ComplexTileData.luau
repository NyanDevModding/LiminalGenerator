local ComplexTileDirections = require(script.Parent.Parent.Parent.ComplexTileDirections)

local ComplexTileData = {}
ComplexTileData.__index = ComplexTileData

export type ComplexTileData = typeof(ComplexTileData.new())

function ComplexTileData.new(
	direction: ComplexTileDirections.Direction,
	accessType: number,
	thickness: number,
	model: Model
)
	return setmetatable({
		_direction = direction,
		_accessType = accessType,
		_thickness = thickness,
		_model = model,
	}, ComplexTileData)
end

function ComplexTileData.getDirection(self: ComplexTileData)
	return self._direction
end

function ComplexTileData.getAccessType(self: ComplexTileData)
	return self._accessType
end

function ComplexTileData.getEntranceRelativePos(self: ComplexTileData, accessNum: number)
	return self._direction[accessNum]
end

function ComplexTileData.getThickness(self: ComplexTileData)
	return self._thickness
end

function ComplexTileData.getModel(self: ComplexTileData)
	return self._model
end

return ComplexTileData
