local room_data_set_json_type = require(script.Parent.room_data_set_json_type)

local RoomData = require(script.Parent.Parent.room.RoomData)
local AccessData = require(script.Parent.Parent.access.AccessData)
local RoomSelector = require(script.Parent.RoomSelector)

local Directions = require(script.Parent.Parent.Parent.gen_data.Directions)
local SimpleTileDirections = require(script.Parent.Parent.SimpleTileDirections)
local ComplexTileDirections = require(script.Parent.Parent.ComplexTileDirections)

local SimpleTileData = require(script.Parent.Parent.corridor_tile.uniform.SimpleTileData)
local ComplexTileData = require(script.Parent.Parent.corridor_tile.uniform.ComplexTileData)
local DeadEndTileRoomData = require(script.Parent.Parent.corridor_tile.uniform.DeadEndTileRoomData)

local MixedSimpleTileData = require(script.Parent.Parent.corridor_tile.mixed.MixedSimpleTileData)
local MixedComplexTileData = require(script.Parent.Parent.corridor_tile.mixed.MixedComplexTileData)

local RoomDataSet = {}
RoomDataSet.__index = RoomDataSet

export type RoomDataSet = typeof(RoomDataSet.new())

local DEFAULT_MODEL = Instance.new("Model")
DEFAULT_MODEL.Name = "DEFAULT"

local function readRoomSetJson(setData: room_data_set_json_type.roomDataSet)
	local roomList = {}

	for _, roomJson in ipairs(setData) do
		local accessDatas = {}
		for accessNum, accessJson in ipairs(roomJson.accesses) do
			accessDatas[accessNum] =
				AccessData.new(accessJson.type, accessJson.position, accessJson.direction)
		end

		-- We now have 4 versions of the same room so we have to divide the chance to spawn by 4
		local chanceToSpawn = roomJson.chance_to_spawn
		if roomJson.rotate_y ~= false then
			chanceToSpawn /= 4
		end

		local roomData = RoomData.new(roomJson.name, roomJson.size, accessDatas, chanceToSpawn)
		table.insert(roomList, roomData)

		-- print("Room: " .. roomJson.name)
		-- print("Rotated 0 times")
		-- print("Size: " .. tostring(roomJson.size))
		-- print("Access data: ")
		-- print(accessDatas)
		-- print("\n")

		if roomJson.rotate_y == false then
			continue
		end

		-- Handle the room rotation and create 3 other room for the 3 other directions
		local roomBaseSize = roomJson.size
		local rotationMatrix = CFrame.Angles(0, 0, 0)

		-- Iterate the 3 directions: WEST, SOUTH, EAST
		for rotationNum = 1, 3, 1 do
			rotationMatrix = rotationMatrix * CFrame.fromEulerAnglesYXZ(0, -math.pi / 2, 0)

			-- We shouldn't use CFrame
			local newRoomSize = rotationMatrix * roomBaseSize
			newRoomSize = Vector3.new(
				math.abs(math.round(newRoomSize.X)),
				math.abs(math.round(newRoomSize.Y)),
				math.abs(math.round(newRoomSize.Z))
			)
			local newRoomCenter = (newRoomSize + Vector3.new(1, 0, 1)) / 2

			-- Rotate the room accesses
			local newRoomAccessDataJson = table.clone(roomJson.accesses)

			--TODO do it without CFrame
			for i, accessData in ipairs(roomJson.accesses) do
				local accessDataPos = accessData.position + Vector3.new(0.5, 0, 0.5)
				local centerRelativePos = accessDataPos - newRoomCenter

				local centerRelativeRotatedPos = rotationMatrix * centerRelativePos
				local nonRelativePos = centerRelativeRotatedPos
					+ newRoomCenter
					- Vector3.new(0.5, 0, 0.5)

				local pos = Vector3.new(
					math.round(nonRelativePos.X),
					math.round(nonRelativePos.Y),
					math.round(nonRelativePos.Z)
				)
				newRoomAccessDataJson[i].position = pos

				-- Calculate the new direction
				local direction = rotationMatrix * accessData.direction
				direction = Vector3.new(
					math.round(direction.X),
					math.round(direction.Y),
					math.round(direction.Z)
				)
				newRoomAccessDataJson[i].direction = direction
			end

			local newRoomAccessData = {}
			for accessNum, accessJson in ipairs(newRoomAccessDataJson) do
				newRoomAccessData[accessNum] =
					AccessData.new(accessJson.type, accessJson.position, accessJson.direction)
			end

			-- print("Room: " .. roomJson.name)
			-- print("Rotated " .. tostring(rotationNum) .. " times")
			-- print("Size: " .. tostring(newRoomSize))
			-- print("Access data: ")
			-- print(newRoomAccessData)
			-- print("\n")

			local rotatedRoomData =
				RoomData.new(roomJson.name, newRoomSize, newRoomAccessData, chanceToSpawn)
			table.insert(roomList, rotatedRoomData)
		end
	end

	table.freeze(roomList)
	return roomList
end

local function readCorridorDataSet(setData: room_data_set_json_type.corridorTileSet)
	local uniformTileDict = {
		simple = {} :: { SimpleTileData.SimpleTileData },
		complex = {} :: { ComplexTileData.ComplexTileData },
		deadEnd = {} :: { DeadEndTileRoomData.DeadEndTileRoomData },
	}

	for typeNum, uniformTileSet in ipairs(setData.uniform_tiles) do
		-- Handle Simple uniform tiles data
		for direction, simpleTileData in pairs(uniformTileSet.simple_tiles) do
			table.insert(
				uniformTileDict.simple,
				SimpleTileData.new(
					direction,
					typeNum or 1,
					simpleTileData.thickness or 1,
					simpleTileData.model or DEFAULT_MODEL
				)
			)
		end

		-- Handle Complex uniform tiles data
		for direction, complexTileData in pairs(uniformTileSet.complex_tiles) do
			table.insert(
				uniformTileDict.complex,
				ComplexTileData.new(
					direction,
					typeNum or 1,
					complexTileData.thickness or 1,
					complexTileData.model or DEFAULT_MODEL
				)
			)
		end

		-- Handle Dead end tiles data
		-- dead ends are always uniform
		for direction, deadEndTileData in pairs(uniformTileSet.dead_ends) do
			table.insert(
				uniformTileDict.deadEnd,
				DeadEndTileRoomData.new(
					direction,
					typeNum or 1,
					deadEndTileData.thickness or 1,
					deadEndTileData.model or DEFAULT_MODEL
				)
			)
		end
	end

	local mixedTileDict = {
		simple = {},
		complex = {},
	}

	local mixedTiles = setData.mixed_tiles
	if mixedTiles == nil then
		mixedTiles = {}
	end

	-- Handle Simple mixed tiles data
	for direction, mixedSimpleTileData in pairs(mixedTiles.simple_tiles or {}) do
		table.insert(
			mixedTileDict.simple,
			MixedSimpleTileData.new(
				mixedSimpleTileData.first_access_type or 1,
				mixedSimpleTileData.second_access_type or 1,
				direction,
				mixedSimpleTileData.thickness or 1,
				mixedSimpleTileData.model or DEFAULT_MODEL
			)
		)
	end

	-- Handle Complex uniform tiles data
	for direction, mixedComplexTileData in pairs(mixedTiles.complex_tiles or {}) do
		table.insert(
			mixedTileDict.complex,
			MixedComplexTileData.new(
				mixedComplexTileData.access_types,
				direction,
				mixedComplexTileData.thickness or 1,
				mixedComplexTileData.model or DEFAULT_MODEL
			)
		)
	end

	return { uniform = uniformTileDict, mixed = mixedTileDict }
end

function RoomDataSet.new(setData: room_data_set_json_type.roomDataSetJson)
	return setmetatable({
		_version = (setData.data_set_name or "unknown") .. "@" .. tostring(
			setData.data_set_version or "unknown"
		),
		_roomList = readRoomSetJson(setData.rooms),
		_corridorData = readCorridorDataSet(setData.corridor_tiles),
	}, RoomDataSet)
end

function RoomDataSet.getVersion(self: RoomDataSet)
	return self._version
end

function RoomDataSet.getRoomDataList(self: RoomDataSet)
	return self._roomList
end

function RoomDataSet.iterateRoomDatas(self: RoomDataSet)
	return ipairs(self._roomList)
end

function RoomDataSet.startRoomSelection(self: RoomDataSet)
	return RoomSelector.new(table.clone(self._roomList))
end

function RoomDataSet.iterateUniformSimpleTiles(self: RoomDataSet)
	return ipairs(self._corridorData.uniform.simple)
end

function RoomDataSet.iterateUniformComplexTiles(self: RoomDataSet)
	return ipairs(self._corridorData.uniform.complex)
end

function RoomDataSet.iterateDeadEndTiles(self: RoomDataSet)
	return ipairs(self._corridorData.uniform.deadEnd)
end

function RoomDataSet.iterateMixedSimpleTiles(self: RoomDataSet)
	return ipairs(self._corridorData.mixed.simple)
end

function RoomDataSet.iterateMixedComplexTiles(self: RoomDataSet)
	return ipairs(self._corridorData.mixed.complex)
end

function RoomDataSet.getSimpleUniformTiles(
	self: RoomDataSet,
	accessType: number,
	direction: SimpleTileDirections.Direction
)
	local tiles = {}

	for _, tile in self:iterateUniformSimpleTiles() do
		if tile:getAccessType() == accessType and tile:getDirection() == direction then
			table.insert(tiles, tile)
		end
	end

	return tiles
end

function RoomDataSet.getComplexUniformTiles(
	self: RoomDataSet,
	accessType: number,
	direction: ComplexTileDirections.Direction
)
	local tiles = {}

	for _, tile in self:iterateUniformComplexTiles() do
		if tile:getAccessType() == accessType and tile:getDirection() == direction then
			table.insert(tiles, tile)
		end
	end

	return tiles
end

function RoomDataSet.getDeadEndTiles(
	self: RoomDataSet,
	accessType: number,
	direction: Directions.Direction
)
	local tiles = {}

	for _, tile in self:iterateDeadEndTiles() do
		if tile:getAccessType() == accessType and tile:getDirection() == direction then
			table.insert(tiles, tile)
		end
	end

	return tiles
end

function RoomDataSet.getSimpleMixedTiles(
	self: RoomDataSet,
	firstAccessType: number,
	secondAccessType: number,
	direction: SimpleTileDirections.Direction
)
	local tiles = {}

	for _, tile in self:iterateMixedSimpleTiles() do
		if
			tile:getFirstAccessType() == firstAccessType
			and tile:getSecondAccessType() == secondAccessType
			and tile:getDirection() == direction
		then
			table.insert(tiles, tile)
		end
	end

	return tiles
end

function RoomDataSet.getComplexMixedTiles(
	self: RoomDataSet,
	accessTypes: { number },
	direction: SimpleTileDirections.Direction
)
	local tiles = {}

	for _, tile in self:iterateMixedComplexTiles() do
		if tile:getDirection() ~= direction then
			continue
		end

		-- check the accesses
		local tileOk = true

		for accessNum, accessType in pairs(accessTypes) do
			if accessType ~= tile:getAccessType(accessNum) then
				tileOk = false
				break
			end
		end

		if tileOk then
			table.insert(tiles, tile)
		end
	end

	return tiles
end

return RoomDataSet
