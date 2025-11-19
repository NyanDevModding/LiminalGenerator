local AccessConnectStack = require(script.Parent.Parent.Parent.Parent.gen_data.AccessConnectStack)
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

local function roomifyCorridor(
	corridor: Corridor.Corridor,
	roomGrid: FlagGrid.FlagGrid,
	roomStorage: RoomStorage.RoomStorage,
	accessGrid: FlagGrid.FlagGrid,
	roomDataSet: RoomDataSet.RoomDataSet,
	seededRandom: SeededRandom.SeededRandom
)
	-- The corridor must be single-cell
	local roomified = corridor:roomify(roomDataSet, seededRandom)[1]

	for _, adjacent in corridor:iterateAdjacents() do
		adjacent:setAdjacentByNum(
			roomified,
			adjacent:getAccessNum(roomified:getPos() - adjacent:getPos())
		)
	end

	local roomifiedPos = roomified:getPos()
	roomGrid:set(roomifiedPos.X, roomifiedPos.Y, roomifiedPos.Z)
	roomStorage:addRoom(roomified)

	-- Place the accesses
	local access1, access2 =
		roomified:getAccessData(1):getRelativePosition(),
		roomified:getAccessData(2):getRelativePosition()
	accessGrid:set(
		roomifiedPos.X + access1.X,
		roomifiedPos.Y + access1.Y,
		roomifiedPos.Z + access1.Z
	)
	accessGrid:set(
		roomifiedPos.X + access2.X,
		roomifiedPos.Y + access2.Y,
		roomifiedPos.Z + access2.Z
	)

	return roomified
end

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

--TODO debug adjacents system
local function handleIncrustation(
	corridor: Corridor.Corridor,
	genSettings: Settings.gen_settings,
	roomDataSet: RoomDataSet.RoomDataSet,
	seededRandom: SeededRandom.SeededRandom,
	roomGrid: FlagGrid.FlagGrid,
	roomStorage: RoomStorage.RoomStorage,
	corridorGrid: FlagGrid.FlagGrid,
	corridorStorage: CorridorStorage.CorridorStorage,
	accessConnectStack: AccessConnectStack.AccessConnectStack,
	debugMode: boolean
)
	local collision = corridor:getFirstCollision(corridorGrid)
	local previousCollision

	local previousRoom: Room.Room?

	local i = 0
	repeat
		i += 1
		local collisionCorridor = corridorStorage:getCorridorAt(collision)

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

		local accessGrid = accessConnectStack:getGrid()
		for _, access in room:iterateAccessDatas() do
			local entrancePos = room:getPos() + access:getRelativeEntrancePos()
			accessGrid:set(entrancePos.X, entrancePos.Y, entrancePos.Z)
		end

		-- Bind the rooms
		if previousRoom ~= nil then
			local roomToPreviousRelativePos = previousCollision - room:getPos()

			room:setAdjacentByNum(
				previousRoom,
				room:getRoomData():getAccessNum(roomToPreviousRelativePos)
			)

			-- Set adjacent at the access of direction: previousCollisionDirection
			previousRoom:setAdjacentByNum(
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

		local newCollisionCorridor1, newCollisionCorridor2
		-- The CollisionCorridor, unlike the corridor, divides when it doesn't
		-- merge with the corridor.
		-- The Corridor divides when it is not the first time iterating
		-- through this loop.
		if
			previousCollision == nil
			or (
				not isOtherVertex
				or (
					otherFirstCollisionNum ~= collisionCorridor:getVertexAmount()
					and otherFirstCollisionNum ~= 1 -- if the collision appared in the middle of the corridor
				)
			)
		then
			-- PreviousCollision can be nil or the previous collision corridor
			-- can be different from this one. In that situation, we still
			-- divide the collision corridor

			-- Divide the collisionCorridor
			newCollisionCorridor1, newCollisionCorridor2 = collisionCorridor:divide(
				accesses[getDirectionNum(otherDirection1)],
				accesses[getDirectionNum(otherDirection2)]
			)

			-- Remove the old corridor
			collisionCorridor:removeFromGrid(corridorGrid)
			corridorStorage:removeCorridor(collisionCorridor)

			-- Place the divided collision corridor
			if newCollisionCorridor1:isSingleCell() then
				roomifyCorridor(
					newCollisionCorridor1,
					roomGrid,
					roomStorage,
					accessGrid,
					roomDataSet,
					seededRandom
				)
				newCollisionCorridor1 = nil
			else
				newCollisionCorridor1:addOnGrid(corridorGrid)
				corridorStorage:addCorridor(newCollisionCorridor1)
				newCollisionCorridor1:connectToAdjacents()
			end

			if newCollisionCorridor2:isSingleCell() then
				roomifyCorridor(
					newCollisionCorridor2,
					roomGrid,
					roomStorage,
					accessGrid,
					roomDataSet,
					seededRandom
				)
				newCollisionCorridor2 = nil
			else
				newCollisionCorridor2:addOnGrid(corridorGrid)
				corridorStorage:addCorridor(newCollisionCorridor2)
				newCollisionCorridor2:connectToAdjacents()
			end
		else
			-- If the actual collision was just next to the previous one and
			-- the corridor is the same as the previous one, just move the
			-- vertex and change the adjacent.
			--  -> otherDirection1 or otherDirection2 because we know that one
			-- of them is nil and the other isn't

			local roomIsAtCorridorBeginning = collisionCorridor:getVertex(1) == collision

			collisionCorridor:removeFromGrid(corridorGrid)
			corridorStorage:removeCorridor(collisionCorridor)

			-- Find the room at the other extremity of the collisionCorridor
			local otherRoom
			for _, adjacent in collisionCorridor:iterateAdjacents() do
				if adjacent ~= previousRoom then
					otherRoom = adjacent
				end
			end

			if otherRoom == nil then
				error(
					"Error in the handleIncrustation while getting the room at the "
						.. "beginning of the collision corridor, expected it not to be nil"
				)
			end

			-- Check if the vertex that is going back do not intersect with its
			-- previous or next vertex
			local hasDuplicatedVertices

			if roomIsAtCorridorBeginning then
				hasDuplicatedVertices = (
					collisionCorridor:getVertex(1) - collisionCorridor:getVertex(2)
				).Magnitude == 1
			else
				hasDuplicatedVertices = (collisionCorridor:getVertex(
					collisionCorridor:getVertexAmount()
				) - collisionCorridor:getVertex(collisionCorridor:getVertexAmount() - 1)).Magnitude == 1
			end

			local accessNum

			if roomIsAtCorridorBeginning then
				accessNum = room:getAccessNum(otherDirection2)

				newCollisionCorridor1 = Corridor.newFromRooms(
					room,
					accessNum,
					otherRoom,
					otherRoom:getAccessNum(
						collisionCorridor:getVertex(collisionCorridor:getVertexAmount())
							- otherRoom:getPos()
					)
				)

				-- Fill the rest of the new corridor
				collisionCorridor:copyToCorridor(
					newCollisionCorridor1,
					1 + (if hasDuplicatedVertices then 2 else 1),
					collisionCorridor:getVertexAmount() - 1,
					if hasDuplicatedVertices then -1 else 0
				)
			else
				accessNum = room:getAccessNum(otherDirection1)

				newCollisionCorridor1 = Corridor.newFromRooms(
					otherRoom,
					otherRoom:getAccessNum(collisionCorridor:getVertex(1) - otherRoom:getPos()),
					room,
					accessNum
				)

				-- Fill the rest of the new corridor
				collisionCorridor:copyToCorridor(
					newCollisionCorridor1,
					2,
					collisionCorridor:getVertexAmount() - (if hasDuplicatedVertices then 2 else 1)
				)
			end

			-- Handle if it is a single-cell
			if newCollisionCorridor1:isSingleCell() then
				roomifyCorridor(
					newCollisionCorridor1,
					roomGrid,
					roomStorage,
					accessGrid,
					roomDataSet,
					seededRandom
				)

				newCollisionCorridor1 = nil
			else
				-- Place the shrinked collision corridor
				newCollisionCorridor1:addOnGrid(corridorGrid)
				corridorStorage:addCorridor(newCollisionCorridor1)
			end

			-- Set the adjacent of the new room
			room:setAdjacentByNum(newCollisionCorridor1, accessNum)
		end

		collisionCorridor = newCollisionCorridor1
		if debugMode then
			coroutine.yield(3, corridorStorage, collisionCorridor, newCollisionCorridor2)
		end

		-- Check if it is the first iteration as if it is not, this means that
		-- the first vertex of the corridor is itself in a collision, thus
		-- needing a particular treatment.
		local newCorridor1
		if previousCollision == nil then
			local newCorridor2

			local firstAccess: Access.Access = accesses[getDirectionNum(corridorDirection1)]
			local secondAccess = accesses[getDirectionNum(corridorDirection2)]

			-- Divide the corridors
			newCorridor1, newCorridor2 = corridor:divide(firstAccess, secondAccess)

			-- Add the new corridor that has no collision
			if newCorridor1:isSingleCell() then
				roomifyCorridor(
					newCorridor1,
					roomGrid,
					roomStorage,
					accessGrid,
					roomDataSet,
					seededRandom
				)
				newCorridor1 = nil
			else
				corridorStorage:addCorridor(newCorridor1)
				newCorridor1:addOnGrid(corridorGrid)
				newCorridor1:connectToAdjacents()
			end

			newCorridor1 = newCorridor2
			corridor = newCorridor1
		else
			-- If the actual collision was just next to the previous one, just
			-- move the vertex and change the adjacent.
			-- Find the room at the other extremity of the corridor
			local otherRoom
			for corridorAccessNum, adjacent in corridor:iterateAdjacents() do
				if corridorAccessNum == 2 then
					otherRoom = adjacent
				end
			end

			if otherRoom == nil then
				error(
					"Error in the handleIncrustation while getting the room at the "
						.. "beginning of the corridor, expected it not to be nil"
				)
			end

			-- Check if the vertex that is going back do not intersect with its
			-- previous or next vertex
			local hasDuplicatedVertices
			hasDuplicatedVertices = (corridor:getVertex(1) - corridor:getVertex(2)).Magnitude == 1

			newCorridor1 = Corridor.newFromRooms(
				room,
				room:getAccessNum(corridor:getVertexEndingDirection(1)),
				otherRoom,
				otherRoom:getAccessNum(
					corridor:getVertex(corridor:getVertexAmount()) - otherRoom:getPos()
				)
			)

			-- Fill the rest of the new corridor
			corridor:copyToCorridor(
				newCorridor1,
				1 + (if hasDuplicatedVertices then 2 else 1),
				corridor:getVertexAmount() - 1,
				if hasDuplicatedVertices then -1 else 0
			)

			if newCorridor1:isSingleCell() then
				roomifyCorridor(
					newCorridor1,
					roomGrid,
					roomStorage,
					accessGrid,
					roomDataSet,
					seededRandom
				)

				newCorridor1 = nil
			end

			corridor = newCorridor1
		end

		if debugMode then
			coroutine.yield(4, corridorStorage, corridor, newCorridor1)
		end

		previousRoom = room

		corridor = newCorridor1 or corridor

		if corridor == nil then
			return true
		end

		-- Recalculate next collision
		previousCollision = collision
		collision = corridor:getFirstCollision(corridorGrid)
	until collision == nil or (collision - previousCollision).Magnitude ~= 1

	if collision ~= nil then
		handleIncrustation(
			corridor,
			genSettings,
			roomDataSet,
			seededRandom,
			roomGrid,
			roomStorage,
			corridorGrid,
			corridorStorage,
			accessConnectStack,
			debugMode
		)
	end

	corridor:connectToAdjacents()

	-- Place the last half corridor
	corridor:addOnGrid(corridorGrid)
	corridorStorage:addCorridor(corridor)

	return true
end

return handleIncrustation
