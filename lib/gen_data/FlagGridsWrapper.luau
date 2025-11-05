local FlagGrid = require(script.Parent.FlagGrid)

-- implements IReadableGrid
local FlagGridsWrapper = {}
FlagGridsWrapper.__index = FlagGridsWrapper

type FlagGridsWrapper = typeof(FlagGridsWrapper.new())

function FlagGridsWrapper.new(grids: { FlagGrid.FlagGrid })
	local xSize, ySize, zSize = grids[1]:getXSize(), grids[1]:getYSize(), grids[1]:getZSize()
	for i = 2, #grids, 1 do
		if
			xSize ~= grids[i]:getXSize()
			or ySize ~= grids[i]:getYSize()
			or zSize ~= grids[i]:getZSize()
		then
			error(
				(
					"Error in a FlagGridsWrapper, expected all the flag grid to have the same size, "
					.. "got the first one at {%i, %i, %i} and the %i_th at {%i, %i, %i}"
				):format(
					xSize,
					ySize,
					zSize,
					i,
					grids[i]:getXSize(),
					grids[i]:getYSize(),
					grids[i]:getZSize()
				)
			)
		end
	end

	return setmetatable({
		_grids = grids,
	}, FlagGridsWrapper)
end

function FlagGridsWrapper.getXSize(self: FlagGridsWrapper)
	return self._grids[1]:getXSize()
end

function FlagGridsWrapper.getYSize(self: FlagGridsWrapper)
	return self._grids[1]:getYSize()
end

function FlagGridsWrapper.getZSize(self: FlagGridsWrapper)
	return self._grids[1]:getZSize()
end

function FlagGridsWrapper.get(self: FlagGridsWrapper, x: number, y: number, z: number)
	-- WTF IS THE MATTER WITH BUFFER LIB READING BITS FROM RIGHT TO LEFT AGFEYUZGFYEZ
	return buffer.readbits(self._storage[x][y], z - 1, 1)
end

function FlagGridsWrapper.volumeAnd(
	self: FlagGridsWrapper,
	x1: number,
	y1: number,
	z1: number,
	x2: number,
	y2: number,
	z2: number
)
	z1 -= 1
	z2 -= 1

	if x1 > x2 or y1 > y2 or z1 > z2 then
		error(
			(
				"Error while performing a volumeAnd: expected the first coordinates "
				.. "to be less then the second got: {%i, %i, %i} and {%i, %i, %i}"
			):format(x1, y1, z1, x2, y2, z2)
		)
	end

	for x = x1, x2, 1 do
		for y = y1, y2, 1 do
			for z = z1, z2, 1 do
				for _, grid in ipairs(self._grids) do
					if grid:get(x, y, z) == 1 then
						continue
					end

					return false
				end
			end
		end
	end

	return true
end

function FlagGridsWrapper.volumeOr(
	self: FlagGridsWrapper,
	x1: number,
	y1: number,
	z1: number,
	x2: number,
	y2: number,
	z2: number
)
	for _, grid in ipairs(self._grids) do
		if grid:volumeOr(x1, y1, z1, x2, y2, z2) then
			return true
		end
	end

	return false
end

function FlagGridsWrapper.getFirstSetInLine(
	self: FlagGridsWrapper,
	p1: Vector3,
	length: Vector3
): Vector3?
	local firstSetInLine = nil
	for _, grid in ipairs(self._grids) do
		local actualFirstSet = grid:getFirstSetInLine(p1, length)

		if
			firstSetInLine == nil
			or (actualFirstSet - p1).Magnitude < (firstSetInLine - p1).Magnitude
		then
			firstSetInLine = actualFirstSet
		end
	end

	return firstSetInLine
end

function FlagGridsWrapper.__tostring(self: FlagGridsWrapper)
	local str = ""
	for i, grid in ipairs(self._grids) do
		str ..= "grid#" .. tostring(i)
		str ..= tostring(grid) .. "\n"
	end
	return str
end

return FlagGridsWrapper
