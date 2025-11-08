local Corridor = require(script.Parent.Parent.Parent.gen_elements.corridor.Corridor)

local CorridorStorage = {}
CorridorStorage.__index = CorridorStorage

export type CorridorStorage = typeof(CorridorStorage.new())

function CorridorStorage.new()
	return setmetatable({
		_storage = {} :: { Corridor.Corridor },
	}, CorridorStorage)
end

function CorridorStorage.addCorridor(self: CorridorStorage, corridor: Corridor.Corridor)
	table.insert(self._storage, corridor)
end

function CorridorStorage.getCorridorAt(self: CorridorStorage, pos: Vector3): Corridor.Corridor?
	for _, corridor in ipairs(self._storage) do
		if corridor:isIncludingCell(pos) then
			return corridor
		end
	end

	return nil
end

function CorridorStorage.removeCorridor(self: CorridorStorage, corridor: Corridor.Corridor)
	for i, storedCorridor in ipairs(self._storage) do
		if storedCorridor == corridor then
			self._storage[i] = self._storage[#self._storage]
			break
		end
	end
end

function CorridorStorage.iterateCorridor(self: CorridorStorage)
	return ipairs(self._storage)
end

return CorridorStorage
