local Directions = require(script.Parent.Parent.Parent.Parent.gen_data.Directions)
local Corridor = require(script.Parent.Parent.Parent.Parent.gen_elements.corridor.Corridor)

local Settings = require(script.Parent.Parent.Parent.Parent.gen_setting.Settings)
local RoomDataSet =
	require(script.Parent.Parent.Parent.Parent.gen_setting.room_data_set.RoomDataSet)
local SeededRandom = require(script.Parent.Parent.Parent.SeededRandom)
local FlagGrid = require(script.Parent.Parent.Parent.Parent.gen_data.FlagGrid)
local CorridorStorage = require(script.Parent.Parent.Parent.Parent.gen_data.storage.CorridorStorage)
local RoomStorage = require(script.Parent.Parent.Parent.Parent.gen_data.storage.RoomStorage)
local Access = require(script.Parent.Parent.Parent.Parent.gen_elements.access.Access)
local Room = require(script.Parent.Parent.Parent.Parent.gen_elements.room.Room)

local function getIncrustationRoomSelection(
	isNorth: boolean,
	isWest: boolean,
	isSouth: boolean,
	isEast: boolean,
	roomDataSet: RoomDataSet.RoomDataSet
)
	local selection = roomDataSet:startRoomSelection():selectMaxSize(0, 0, 0)

	if isNorth and isWest and isSouth and isEast then
		selection:select(function(roomData): boolean
			return roomData:getAccessNumber() == 4 and roomData:getSize() == Vector3.new(0, 0, 0)
		end)

		return selection
	end

	-- Select with the access pos
	local accessPositions = {}

	if isNorth then
		table.insert(accessPositions, Directions.NORTH)
	end

	if isWest then
		table.insert(accessPositions, Directions.WEST)
	end

	if isSouth then
		table.insert(accessPositions, Directions.SOUTH)
	end

	if isEast then
		table.insert(accessPositions, Directions.EAST)
	end

	local accessAmount = (if isNorth then 1 else 0)
		+ (if isWest then 1 else 0)
		+ (if isSouth then 1 else 0)
		+ (if isEast then 1 else 0)

	selection:selectMaxSize(0, 0, 0):select(function(roomData): boolean
		if roomData:getAccessNumber() ~= accessAmount then
			return false
		end

		for _, accessPos in ipairs(accessPositions) do
			local ok = false
			for _, accessData in roomData:iterateAccessDatas() do
				if accessData:getRelativeEntrancePos() == accessPos then
					ok = true
					break
				end
			end

			if not ok then
				return false
			end
		end

		return true
	end)

	return selection
end

local function getDirectionNum(direction: Vector3)
	if direction.Z == 1 then
		return 1
	elseif direction.X == -1 then
		return 2
	elseif direction.Z == -1 then
		return 3
	elseif direction.X == 1 then
		return 4
	end

	return nil
end

return function(
	corridor: Corridor.Corridor,
	genSettings: Settings.gen_settings,
	roomDataSet: RoomDataSet.RoomDataSet,
	seededRandom: SeededRandom.SeededRandom,
	roomGrid: FlagGrid.FlagGrid,
	roomStorage: RoomStorage.RoomStorage,
	corridorGrid: FlagGrid.FlagGrid,
	corridorStorage: CorridorStorage.CorridorStorage,
	debugMode: boolean
)
	local collision = corridor:getFirstCollision(corridorGrid)
	local previousCollision

	local previousRoom: Room.Room?

	local i = 0
	repeat
		i += 1
		local collisionCorridor = corridorStorage:getCorridorAt(collision)

		--TODO debug and finish ts
		local isNorth = false
		local isWest = false
		local isSouth = false
		local isEast = false

		-- For the Corridor
		-- The vertex preceding the segment where the collision occurs
		local firstCorridorCollisionNum = corridor:getFirstVertexBefore(collision)

		-- If the collision occurs on a vertex
		local isCorridorVertex = corridor:getVertex(firstCorridorCollisionNum) == collision

		-- Get the relative position of the corridor cells around the collision.
		local corridorDirection1
		local corridorDirection2

		if isCorridorVertex then
			-- Handle if we are dealing with merged corridors at their
			-- starting point (if there was previous collisions)
			if previousCollision == nil then
				corridorDirection1 = corridor:getVertexStartingDirection(firstCorridorCollisionNum)
			else
				corridorDirection1 = nil
			end

			corridorDirection2 = corridor:getVertexEndingDirection(firstCorridorCollisionNum)
		else
			corridorDirection1 = corridor:getVertexStartingDirection(firstCorridorCollisionNum + 1)
			corridorDirection2 = -corridorDirection1
		end

		-- For the collision Corridor
		-- The vertex preceding the segment where the collision occurs
		local otherFirstCollisionNum = collisionCorridor:getFirstVertexBefore(collision)

		-- If the collision occurs on a vertex
		local isOtherVertex = collisionCorridor:getVertex(otherFirstCollisionNum) == collision

		-- Get the relative position of the collisionCorridor cells around the collision.
		local otherDirection1
		local otherDirection2

		if isOtherVertex then
			-- Handle if we are dealing with merged corridors at their
			-- starting point (if there was previous collisions)
			if previousCollision ~= nil then
				-- Check if the collision corridor is in the same sens as the corridor or not
				if otherFirstCollisionNum == 1 then
					-- can be nil as it is not used later, when we divide the corridors
					otherDirection1 = nil
					otherDirection2 =
						collisionCorridor:getVertexEndingDirection(otherFirstCollisionNum)
				elseif otherFirstCollisionNum == collisionCorridor:getVertexAmount() then
					otherDirection1 =
						collisionCorridor:getVertexStartingDirection(otherFirstCollisionNum)
					otherDirection2 = nil
				else
					otherDirection1 =
						collisionCorridor:getVertexStartingDirection(otherFirstCollisionNum)
					otherDirection2 =
						collisionCorridor:getVertexEndingDirection(otherFirstCollisionNum)
				end
			else
				otherDirection1 =
					collisionCorridor:getVertexStartingDirection(otherFirstCollisionNum)
				otherDirection2 = collisionCorridor:getVertexEndingDirection(otherFirstCollisionNum)
			end
		else
			otherDirection1 =
				collisionCorridor:getVertexStartingDirection(otherFirstCollisionNum + 1)
			otherDirection2 = -otherDirection1
		end

		-- Get the relativePos of the previousRoom
		local previousCollisionDirection: Vector3?
		if previousCollision ~= nil then
			previousCollisionDirection = previousCollision - collision
		end

		if debugMode then
			coroutine.yield(
				1,
				collision,
				corridorDirection1 or previousCollisionDirection,
				corridorDirection2,
				otherDirection1 or previousCollisionDirection,
				otherDirection2 or previousCollisionDirection
			)
		end

		-- Get the relative poisition of the other corridor cells around the collision
		isNorth = otherDirection1 == Directions.NORTH
			or otherDirection2 == Directions.NORTH
			or corridorDirection1 == Directions.NORTH
			or corridorDirection2 == Directions.NORTH
			or previousCollisionDirection == Directions.NORTH
		isWest = otherDirection1 == Directions.WEST
			or otherDirection2 == Directions.WEST
			or corridorDirection1 == Directions.WEST
			or corridorDirection2 == Directions.WEST
			or previousCollisionDirection == Directions.WEST
		isSouth = otherDirection1 == Directions.SOUTH
			or otherDirection2 == Directions.SOUTH
			or corridorDirection1 == Directions.SOUTH
			or corridorDirection2 == Directions.SOUTH
			or previousCollisionDirection == Directions.SOUTH
		isEast = otherDirection1 == Directions.EAST
			or otherDirection2 == Directions.EAST
			or corridorDirection1 == Directions.EAST
			or corridorDirection2 == Directions.EAST
			or previousCollisionDirection == Directions.EAST

		-- Create the room that fuses the corridors
		local roomData =
			getIncrustationRoomSelection(isNorth, isWest, isSouth, isEast, roomDataSet):getRandomRoom(
				seededRandom
			)

		if roomData == nil then
			return false
		end

		local room = Room.new(collision, roomData)

		-- Place the room
		roomStorage:addRoom(room)
		roomGrid:set(collision.X, collision.Y, collision.Z)

		-- Bind the rooms
		if previousRoom ~= nil then
			local roomToPreviousRelativePos = previousCollision - room:getPos()

			room:setAdjacent(
				previousRoom,
				room:getRoomData():getAccessNum(roomToPreviousRelativePos)
			)

			-- Set adjacent at the access of direction: previousCollisionDirection
			previousRoom:setAdjacent(
				room,
				previousRoom:getRoomData():getAccessNum(-roomToPreviousRelativePos)
			)
		end

		if debugMode then
			coroutine.yield(2, roomGrid)
		end

		-- Create a table with all the accesses
		local accesses = {}

		for _, accessData in roomData:iterateAccessDatas() do
			local accessPos = room:getPos() + accessData:getRelativePosition()

			accesses[getDirectionNum(accessData:getDirection())] =
				Access.createAccess(room, accessData, accessPos.X, accessPos.Y, accessPos.Z)
		end

		--FIXME ERROR WHEN COLLISION CORRIDOR ISNT IN THE SAME SENS AS CORRIDOR

		local newCollisionCorridor
		-- The CollisionCorridor, unlike the corridor, divides when it doesn't
		-- merge with the corridor.
		-- The Corridor divides when it is not the first time iterating
		-- through this loop.
		print(isOtherVertex)
		print(otherFirstCollisionNum)
		print(collisionCorridor:getVertexAmount())
		if
			previousCollision == nil
			or (
				not isOtherVertex
				or (
					otherFirstCollisionNum ~= collisionCorridor:getVertexAmount()
					and otherFirstCollisionNum ~= 1
				)
			)
		then
			-- PreviousCollision can be nil or the previous collision corridor
			-- can be different from this one. In that situation, we still
			-- divide the collision corridor

			-- Divide the collisionCorridor
			newCollisionCorridor = collisionCorridor:divide(
				accesses[getDirectionNum(otherDirection1)],
				accesses[getDirectionNum(otherDirection2)]
			)

			-- Set the adjacents as the half are both placed
			room:setAdjacent(
				collisionCorridor,
				room:getRoomData():getAccessNum(
					collisionCorridor:getVertex(collisionCorridor:getVertexAmount()) - collision
				)
			)
			room:setAdjacent(
				newCollisionCorridor,
				room:getRoomData():getAccessNum(newCollisionCorridor:getVertex(1) - collision)
			)

			-- Place the divided collision corridor
			newCollisionCorridor:addOnGrid(corridorGrid)
			corridorStorage:addCorridor(newCollisionCorridor)
		else
			-- If the actual collision was just next to the previous one and
			-- the corridor is the same as the previous one, just move the
			-- vertex and change the adjacent.
			--  -> otherDirection1 or otherDirection2 because we know that one
			-- of them is nil and the other isn't
			local accessData = accesses[getDirectionNum(otherDirection1 or otherDirection2)].access

			collisionCorridor:setAdjacent(room, 1, accessData)
			collisionCorridor:setVertex(
				-- either the last or first vertex
				otherFirstCollisionNum,
				room:getPos() + accessData:getRelativeEntrancePos()
			)

			local nextVertexNum = otherFirstCollisionNum
				+ if otherFirstCollisionNum == 1 then 1 else -1

			-- Check that it didn't move the vertex at the same pos as the next vertex
			if
				collisionCorridor:getVertex(otherFirstCollisionNum)
				== collisionCorridor:getVertex(nextVertexNum)
			then
				print(nextVertexNum)
				collisionCorridor:removeVertex(nextVertexNum)
			end
		end

		if debugMode then
			coroutine.yield(3, corridorStorage, collisionCorridor, newCollisionCorridor)
		end

		-- Check if it is the first iteration as if it is not, this means that
		-- the first vertex of the corridor is itself in a collision, thus
		-- needing a particular treatment.
		local newCorridor
		local accessData = accesses[getDirectionNum(corridorDirection2)].access
		if previousCollision == nil then
			-- Divide the corridors
			newCorridor = corridor:divide(
				accesses[getDirectionNum(corridorDirection1)],
				accesses[getDirectionNum(corridorDirection2)]
			)

			-- Set the corridor as adjacent as it is placed
			room:setAdjacent(
				corridor,
				room:getRoomData()
					:getAccessNum(corridor:getVertex(corridor:getVertexAmount()) - collision)
			)

			-- Place the divided corridor, the half that has no collision
			corridor:setAdjacent(room, 1, accessData)
			corridor:addOnGrid(corridorGrid)
			corridorStorage:addCorridor(corridor)
		else
			-- If the actual collision was just next to the previous one, just
			-- move the vertex and change the adjacent.

			corridor:setAdjacent(room, 1, accessData)
			corridor:setVertex(1, room:getPos() + accessData:getRelativeEntrancePos())

			-- Check that it didn't move the vertex at the same pos as the next vertex
			if corridor:getVertex(1) == corridor:getVertex(2) then
				corridor:removeVertex(2)
			end
		end

		if debugMode then
			coroutine.yield(4, corridorStorage, corridor, newCorridor)
		end

		previousRoom = room

		corridor = newCorridor or corridor

		-- Recalculate next collision
		previousCollision = collision
		collision = corridor:getFirstCollision(corridorGrid)
	until collision == nil or (collision - previousCollision).Magnitude ~= 1

	-- Set the last half as adjacent
	previousRoom:setAdjacent(
		corridor,
		previousRoom:getRoomData():getAccessNum(corridor:getVertex(1) - previousCollision)
	)

	-- Place the last half corridor
	corridor:addOnGrid(corridorGrid)
	corridorStorage:addCorridor(corridor)

	return true
end
