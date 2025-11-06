local FlagGrid = {}
FlagGrid.__index = FlagGrid

export type FlagGrid = typeof(FlagGrid.new())

local function _createGridStorage(xSize, ySize, zSize): { { buffer } }
	debug.profilebegin("Create Grid Sorage")

	local zByteSize = math.ceil(zSize / 8)
	local x = table.create(xSize, nil)
	for i = 1, xSize, 1 do
		x[i] = table.create(ySize)
		local y = x[i]

		for i = 1, ySize, 1 do
			y[i] = buffer.create(zByteSize)
		end
	end

	debug.profileend()

	return x
end

function FlagGrid.new(xSize: number, ySize: number, zSize: number)
	return setmetatable({
		_xSize = xSize,
		_ySize = ySize,
		_zSize = zSize,
		_zByteSize = math.ceil(zSize / 8),
		_storage = _createGridStorage(xSize, ySize, zSize),
	}, FlagGrid)
end

function FlagGrid.getXSize(self: FlagGrid)
	return self._xSize
end

function FlagGrid.getYSize(self: FlagGrid)
	return self._ySize
end

function FlagGrid.getZSize(self: FlagGrid)
	return self._zSize
end

function FlagGrid._getZByteSize(self: FlagGrid)
	return self._zSize
end

function FlagGrid.set(self: FlagGrid, x: number, y: number, z: number)
	buffer.writebits(self._storage[x][y], z - 1, 1, 1)
end

function FlagGrid.reset(self: FlagGrid, x: number, y: number, z: number)
	buffer.writebits(self._storage[x][y], z - 1, 1, 0)
end

function FlagGrid.get(self: FlagGrid, x: number, y: number, z: number)
	-- WTF IS THE MATTER WITH BUFFER LIB READING BITS FROM RIGHT TO LEFT AGFEYUZGFYEZ
	return buffer.readbits(self._storage[x][y], z - 1, 1)
end

function FlagGrid.volumeSet(
	self: FlagGrid,
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
				"Error while performing a volumeSet: expected the first coordinates "
				.. "to be less then the second got: {%i, %i, %i} and {%i, %i, %i}"
			):format(x1, y1, z1, x2, y2, z2)
		)
	end

	local deltaZ = z2 - z1
	local value = 2 ^ (deltaZ + 1) - 1
	for x = x1, x2, 1 do
		for y = y1, y2, 1 do
			buffer.writebits(self._storage[x][y], z1, deltaZ + 1, value)
		end
	end
end

function FlagGrid.volumeReset(
	self: FlagGrid,
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
				"Error while performing a volumeReset: expected the first coordinates "
				.. "to be less then the second got: {%i, %i, %i} and {%i, %i, %i}"
			):format(x1, y1, z1, x2, y2, z2)
		)
	end

	local deltaZ = z2 - z1
	for x = x1, x2, 1 do
		for y = y1, y2, 1 do
			buffer.writebits(self._storage[x][y], z1, 1 + deltaZ, 0)
		end
	end
end

function FlagGrid.volumeAnd(
	self: FlagGrid,
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

	local deltaZ = z2 - z1
	local value = 2 ^ (deltaZ + 1) - 1
	for x = x1, x2, 1 do
		for y = y1, y2, 1 do
			if buffer.readbits(self._storage[x][y], z1, 1 + deltaZ) ~= value then
				return false
			end
		end
	end

	return true
end

function FlagGrid.volumeOr(
	self: FlagGrid,
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
				"Error while performing a volumeOr: expected the first coordinates "
				.. "to be less then the second got: {%i, %i, %i} and {%i, %i, %i}"
			):format(x1, y1, z1, x2, y2, z2)
		)
	end

	local deltaZ = z2 - z1
	for x = x1, x2, 1 do
		for y = y1, y2, 1 do
			if buffer.readbits(self._storage[x][y], z1, deltaZ + 1) ~= 0 then
				return true
			end
		end
	end

	return false
end

function FlagGrid.getFirstSetInLine(self: FlagGrid, p1: Vector3, length: Vector3): Vector3?
	-- Check if the length vector is 0
	if length.Magnitude == 0 then
		error(
			"Error while getting the first set flag in a FlagGrid line: "
				.. "expected the length not to be 0"
		)
	end

	-- Check the length vector
	if
		not (
			(length.X ~= 0 and length.Y == 0 and length.Z == 0)
			or (length.X == 0 and length.Y ~= 0 and length.Z == 0)
			or (length.X == 0 and length.Y == 0 and length.Z ~= 0)
		)
	then
		error(
			(
				"Error while getting the first set flag in a FlagGrid line: "
				.. "expected the length to be in a single direction, got length: {%i, %i, %i}"
			):format(length.X, length.Y, length.Z)
		)
	end

	local unitVector = length.Unit

	for i = 0, length.Magnitude - 1, 1 do
		local pos = p1 + i * unitVector
		if self:get(pos.X, pos.Y, pos.Z) == 1 then
			return pos
		end
	end

	return nil
end

function FlagGrid.__tostring(self: FlagGrid)
	local str = "Displaying a flagGrid: row=z column=x\n"

	local maxXNumberSize = math.floor(math.log(self._xSize, 10)) + 1

	local maxZNumberSize = math.floor(math.log(self._zSize, 10)) + 1
	local cellZIndent = string.rep(" ", maxZNumberSize)

	local xIndex = string.rep(" ", maxZNumberSize + 1)
	for x = 1, self._xSize, 1 do
		local numberSize = math.floor(math.log(x, 10)) + 1
		xIndex ..= tostring(x) .. string.rep(" ", maxXNumberSize - numberSize) .. " "
	end

	for y = 1, self._ySize, 1 do
		str ..= "layer:[y=" .. tostring(y) .. "]"
		for z = self._zSize - 1, 0, -1 do
			-- z Indent as all the numbers do not have the same amount of digit
			local zLength = maxZNumberSize - (math.floor(math.log(z + 1, 10)) + 1)
			local zIndent = string.rep(" ", zLength)

			str ..= "\n"
			str ..= tostring(z + 1) .. zIndent .. " "

			for x = 1, self._xSize, 1 do
				local yBuffer = self._storage[x][y]

				local bit = buffer.readbits(yBuffer, z, 1)

				if bit == 0 then
					str ..= "○" .. cellZIndent
				else
					str ..= "◙" .. cellZIndent
				end
			end
		end
		str ..= "\n" .. xIndex
		str ..= "\n\n"
	end

	return str
end

return FlagGrid
