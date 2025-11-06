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
	for _, grid in ipairs(self._grids) do
		if grid:get(x, y, z) == 1 then
			return 1
		end
	end

	return 0
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

local CELL_APPEARANCES = { "█", "▓", "▒", "░", "☻" }

function FlagGridsWrapper.__tostring(self: FlagGridsWrapper)
	local str = "Displaying a flagGrid wrapper: row=z column=x\n"

	local maxXNumberSize = math.floor(math.log(self:getXSize(), 10)) + 1

	local maxZNumberSize = math.floor(math.log(self:getZSize(), 10)) + 1
	local cellZIndent = string.rep(" ", maxZNumberSize)

	local xIndex = string.rep(" ", maxZNumberSize + 1)
	for x = 1, self:getXSize(), 1 do
		local numberSize = math.floor(math.log(x, 10)) + 1
		xIndex ..= tostring(x) .. string.rep(" ", maxXNumberSize - numberSize) .. " "
	end

	for y = 1, self:getYSize(), 1 do
		str ..= "layer:[y=" .. tostring(y) .. "]"
		for z = self:getZSize() - 1, 0, -1 do
			-- z Indent as all the numbers do not have the same amount of digit
			local zLength = maxZNumberSize - (math.floor(math.log(z + 1, 10)) + 1)
			local zIndent = string.rep(" ", zLength)

			str ..= "\n"
			str ..= tostring(z + 1) .. zIndent .. " "

			for x = 1, self:getXSize(), 1 do
				-- Different bit appearance for each grid
				local bitStr
				for i, grid in ipairs(self._grids) do
					if grid:get(x, y, z + 1) == 1 then
						bitStr = tostring(CELL_APPEARANCES[i])

						if bitStr == nil then
							bitStr = "◙"
						end
					end
				end

				if bitStr == nil then
					bitStr = "·"
				end

				str ..= bitStr .. cellZIndent
			end
		end
		str ..= "\n" .. xIndex
		str ..= "\n\n"
	end

	return str
end

return FlagGridsWrapper
