local Corridor = require(script.Parent.Corridor)

local Directions = require(script.Parent.Parent.Parent.gen_data.Directions)
local FlagGrid = require(script.Parent.Parent.Parent.gen_data.FlagGrid)
local AccessData = require(script.Parent.Parent.Parent.gen_setting.access.AccessData)
local DeadEndTileRoomData =
	require(script.Parent.Parent.Parent.gen_setting.corridor_tile.uniform.DeadEndTileRoomData)
local Access = require(script.Parent.Parent.access.Access)
local RoomData = require(script.Parent.Parent.Parent.gen_setting.room.RoomData)
local Room = require(script.Parent.Parent.room.Room)

local TEST_ACCESS_1 = AccessData.new(1, Vector3.new(0, 0, 0), Directions.EAST)
local TEST_ACCESS_2 = AccessData.new(1, Vector3.new(0, 0, 0), Directions.WEST)
local TEST_ACCESS_3 = AccessData.new(1, Vector3.new(0, 0, 0), Directions.SOUTH)
local TEST_ACCESS_4 = AccessData.new(1, Vector3.new(0, 0, 0), Directions.NORTH)

local TEST_ROOM_1 = RoomData.new("test_1", Vector3.new(0, 0, 0), { TEST_ACCESS_1 })
local TEST_ROOM_2 = RoomData.new("test_2", Vector3.new(0, 0, 0), { TEST_ACCESS_2 })
local TEST_ROOM_3 = RoomData.new("test_3", Vector3.new(0, 0, 0), { TEST_ACCESS_1, TEST_ACCESS_2 })
local TEST_ROOM_4 = RoomData.new("test_4", Vector3.new(0, 0, 0), { TEST_ACCESS_3 })
local TEST_ROOM_5 = RoomData.new("test_5", Vector3.new(0, 0, 0), { TEST_ACCESS_4 })

return function()
	local testWrapped1, testWrapped2
	local firstAccess: Access.Access -- 2, 2, 8
	local secondAccess: Access.Access -- 10, 2, 2
	local corridor: Corridor.Corridor

	beforeEach(function()
		testWrapped1 = Room.new(Vector3.new(1, 2, 8), TEST_ROOM_1)
		testWrapped2 = Room.new(Vector3.new(11, 2, 2), TEST_ROOM_2)

		firstAccess = TEST_ACCESS_1:wrap(testWrapped1) -- 2, 2, 8
		secondAccess = TEST_ACCESS_2:wrap(testWrapped2) -- 10, 2, 2

		corridor = Corridor.new(firstAccess, secondAccess)
		corridor:addVertex(2) -- 2, 2, 2
		corridor:setVertex(
			2,
			Vector3.new(
				firstAccess.x + firstAccess.direction.X,
				firstAccess.y + firstAccess.direction.Y,
				secondAccess.z + secondAccess.direction.Z
			)
		)

		testWrapped1:setAdjacentByNum(corridor, 1)
		testWrapped2:setAdjacentByNum(corridor, 1)
	end)

	describe("Corridor", function()
		it("should return the pos of the first access for the position of the corridor", function()
			expect(corridor:getPos()).to.equal(
				Vector3.new(
					firstAccess.x + firstAccess.direction.X,
					firstAccess.y + firstAccess.direction.Y,
					firstAccess.z + firstAccess.direction.Z
				)
			)
		end)
		it("should return the length in cells of the corridor", function()
			expect(corridor:getLength()).to.equal(15)
		end)
		it("should create the access of one of its adjacents", function()
			local access1 = corridor:createAdjacentAccess(1)

			expect(access1.room).to.equal(testWrapped1)
			expect(access1.access).to.equal(TEST_ACCESS_1)
			expect(access1.x).to.equal(1)
			expect(access1.y).to.equal(2)
			expect(access1.z).to.equal(8)

			local access2 = corridor:createAdjacentAccess(2)

			expect(access2.room).to.equal(testWrapped2)
			expect(access2.access).to.equal(TEST_ACCESS_2)
			expect(access2.x).to.equal(11)
			expect(access2.y).to.equal(2)
			expect(access2.z).to.equal(2)
		end)
		it("should handle adjacents rooms", function()
			local testWrapped4 = Room.new(Vector3.new(1, 2, 8), TEST_ROOM_1)
			local testWrapped5 = Room.new(Vector3.new(1, 2, 8), TEST_ROOM_3)
			local testWrapped6 = Room.new(Vector3.new(11, 2, 2), TEST_ROOM_3)

			corridor:setAdjacentByNum(testWrapped4, 1)
			for i, adjacent in corridor:iterateAdjacents() do
				if i == 1 then
					expect(adjacent).to.equal(testWrapped4)
				end
			end

			corridor:setAdjacentByNum(testWrapped5, 1)
			for i, adjacent in corridor:iterateAdjacents() do
				if i == 1 then
					expect(adjacent).to.equal(testWrapped5)
				end
			end

			corridor:setAdjacentByNum(testWrapped6, 2)
			for i, adjacent in corridor:iterateAdjacents() do
				if i == 2 then
					expect(adjacent).to.equal(testWrapped6)
				end
			end

			local i = 0
			for _ in corridor:iterateAdjacents() do
				i += 1
			end
			expect(i).to.equal(2)
		end)
		it("should return its vertices", function()
			expect(corridor:getVertex(1)).to.be.ok()
			expect(corridor:getVertex(2)).to.be.ok()
			expect(corridor:getVertex(3)).to.be.ok()
		end)
		it("should return the amount of vertices it has", function()
			expect(corridor:getVertexAmount()).to.equal(3)
			corridor:addVertex(2)
			expect(corridor:getVertexAmount()).to.equal(4)
		end)
		it("should modify a vertex pos", function()
			corridor:addVertex(2)
			corridor:setVertex(
				2,
				Vector3.new(
					firstAccess.x + firstAccess.direction.X,
					firstAccess.y + firstAccess.direction.Y,
					secondAccess.z + firstAccess.direction.Z + 2
				)
			)

			expect(corridor:getVertex(2)).to.equal(
				Vector3.new(
					firstAccess.x + firstAccess.direction.X,
					firstAccess.y + firstAccess.direction.Y,
					secondAccess.z + firstAccess.direction.Z + 2
				)
			)
		end)
		it("should remove a vertex", function()
			corridor:addVertex(2)
			corridor:removeVertex(3)

			expect(corridor:getVertexAmount()).to.equal(3)
		end)
		it("should be able to invert a vertex", function()
			corridor:invert(2)

			expect(corridor:getVertex(2)).to.equal(
				Vector3.new(
					secondAccess.x + secondAccess.direction.X,
					secondAccess.y + secondAccess.direction.Y,
					firstAccess.z + firstAccess.direction.Z
				)
			)
		end)
		it("should iterate all the vertices", function()
			corridor:addVertex(2)

			local i = 0
			for _ in corridor:iterateVertices() do
				i += 1
			end

			expect(i).to.equal(4)
		end)
		it("should iterate all the middle vertices", function()
			corridor:addVertex(2)
			corridor:addVertex(2)

			local i = 0
			for _, v in corridor:iterateMiddleVertices() do
				i += 1
			end

			expect(i).to.equal(3)
		end)
		it("should return the first collision in the grid", function()
			local grid = FlagGrid.new(10, 2, 12)
			local collision1 = Vector3.new(7, 2, 2)
			local collision2 = Vector3.new(2, 2, 7)

			grid:set(collision1.X, collision1.Y, collision1.Z)
			expect(corridor:getFirstCollision(grid)).to.equal(collision1)
			grid:set(collision2.X, collision2.Y, collision2.Z)
			expect(corridor:getFirstCollision(grid)).to.equal(collision2)

			corridor:addVertex(3)
			corridor:setVertex(2, corridor:getVertex(2) + Vector3.new(0, 0, 4))
			local vx2, vx4 = corridor:getVertex(2), corridor:getVertex(4)
			corridor:setVertex(3, Vector3.new(vx4.X, vx2.Y, vx2.Z))

			local collision3 = Vector3.new(5, 2, 6)

			expect(corridor:getFirstCollision(grid)).to.equal(collision2)
			grid:reset(collision2.X, collision2.Y, collision2.Z)
			expect(corridor:getFirstCollision(grid)).to.equal(nil)

			grid:set(collision3.X, collision3.Y, collision3.Z)
			expect(corridor:getFirstCollision(grid)).to.equal(collision3)
		end)
		it("should return the first collision with another corridor", function()
			local firstCollision = Vector3.new(4, 2, 2)
			local secondCollision = Vector3.new(5, 2, 2)

			local otherRoom1 = Room.new(Vector3.new(4, 2, 4), TEST_ROOM_4)
			local otherRoom2 = Room.new(Vector3.new(6, 2, 4), TEST_ROOM_4)

			local otherCorridor = Corridor.new(
				Access.createAccess(otherRoom1, otherRoom1:getAccessData(1), 4, 2, 4),
				Access.createAccess(otherRoom2, otherRoom2:getAccessData(1), 6, 2, 4)
			)
			otherCorridor:addVertex(2)
			otherCorridor:setVertex(2, Vector3.new(4, 2, 2))

			otherCorridor:addVertex(3)
			otherCorridor:setVertex(3, Vector3.new(6, 2, 2))

			expect(corridor:getFirstCollisionWith(otherCorridor)).to.equal(firstCollision)

			-- Move the corridor
			local otherRoom3 = Room.new(Vector3.new(5, 2, 4), TEST_ROOM_4)

			local anotherCorridor = Corridor.new(
				Access.createAccess(otherRoom3, otherRoom3:getAccessData(1), 5, 2, 4),
				Access.createAccess(otherRoom2, otherRoom2:getAccessData(1), 6, 2, 4)
			)
			anotherCorridor:addVertex(2)
			anotherCorridor:setVertex(2, Vector3.new(5, 2, 2))

			anotherCorridor:addVertex(3)
			anotherCorridor:setVertex(3, Vector3.new(6, 2, 2))

			expect(corridor:getFirstCollisionWith(anotherCorridor)).to.equal(secondCollision)
		end)
		it("should return the first vertex before a position", function()
			expect(corridor:getFirstVertexBefore(Vector3.new(2, 2, 7))).to.equal(1)
			expect(corridor:getFirstVertexBefore(Vector3.new(2, 2, 8))).to.equal(1)
			expect(corridor:getFirstVertexBefore(Vector3.new(2, 2, 2))).to.equal(2)
			expect(corridor:getFirstVertexBefore(Vector3.new(8, 2, 2))).to.equal(2)
			expect(corridor:getFirstVertexBefore(Vector3.new(10, 2, 2))).to.equal(3)

			corridor:addVertex(3)
			corridor:setVertex(3, Vector3.new(5, 2, 2))
			expect(corridor:getFirstVertexBefore(Vector3.new(4, 2, 2))).to.equal(2)
			expect(corridor:getFirstVertexBefore(Vector3.new(5, 2, 2))).to.equal(3)
			expect(corridor:getFirstVertexBefore(Vector3.new(6, 2, 2))).to.equal(3)
			expect(corridor:getFirstVertexBefore(Vector3.new(10, 2, 2))).to.equal(4)
		end)
		it("should check if a cell is included in the corridor", function()
			local c1 = Vector3.new(7, 2, 2)
			local c2 = Vector3.new(2, 2, 7)
			local c3 = Vector3.new(5, 2, 6)

			expect(corridor:isIncludingCell(c1)).to.equal(true)
			expect(corridor:isIncludingCell(c2)).to.equal(true)
			expect(corridor:isIncludingCell(c3)).to.equal(false)

			corridor:addVertex(3)
			corridor:setVertex(2, corridor:getVertex(2) + Vector3.new(0, 0, 4))
			local vx2, vx4 = corridor:getVertex(2), corridor:getVertex(4)
			corridor:setVertex(3, Vector3.new(vx4.X, vx2.Y, vx2.Z))

			expect(corridor:isIncludingCell(c1)).to.equal(false)
			expect(corridor:isIncludingCell(c2)).to.equal(true)
			expect(corridor:isIncludingCell(c3)).to.equal(true)
		end)
		it("should be able to divide itself into two corridor", function()
			local testWrapped3 = Room.new(Vector3.new(6, 2, 2), TEST_ROOM_3)
			local newEndAccess = Access.createAccess(testWrapped3, TEST_ACCESS_2, 6, 2, 2)
			local newStartAccess = Access.createAccess(testWrapped3, TEST_ACCESS_1, 6, 2, 2)

			local firstCorridor, secondCorridor = corridor:divide(newEndAccess, newStartAccess)
			expect(firstCorridor:getVertex(1)).to.equal(Vector3.new(2, 2, 8))
			expect(firstCorridor:getVertex(2)).to.equal(Vector3.new(2, 2, 2))
			expect(firstCorridor:getVertex(3)).to.equal(Vector3.new(5, 2, 2))

			expect(secondCorridor:getVertex(1)).to.equal(Vector3.new(7, 2, 2))
			expect(secondCorridor:getVertex(2)).to.equal(Vector3.new(10, 2, 2))
		end)
		it("should return one of its accesses", function()
			expect(corridor:getAccessData(1):getDirection()).to.equal(-TEST_ACCESS_1:getDirection())
			expect(corridor:getAccessData(1):getAccessType()).to.equal(
				TEST_ACCESS_1:getAccessType()
			)
			expect(corridor:getAccessData(2):getDirection()).to.equal(-TEST_ACCESS_2:getDirection())
			expect(corridor:getAccessData(2):getAccessType()).to.equal(
				TEST_ACCESS_2:getAccessType()
			)
		end)
		it("should return the start direction of a vertex", function()
			expect(corridor:getVertexStartingDirection(2)).to.equal(Directions.NORTH)
		end)
		it("should return the end direction of a vertex", function()
			expect(corridor:getVertexEndingDirection(2)).to.equal(Directions.EAST)
		end)
		it("should make its vertex a deadEnd", function()
			local deadEndData =
				DeadEndTileRoomData.new(Directions.NORTH, 1, 1, Instance.new("Model"))

			local vertex = corridor:getVertex(2)
			local deadEndCorridor, deadEndRoom = corridor:makeDeadEnd(deadEndData, 2)

			expect(deadEndCorridor:getAccessData(2):getDirection()).to.equal(Directions.SOUTH)
			expect(deadEndCorridor:getVertexAmount()).to.equal(2)
			expect(deadEndCorridor:getVertex(2)).to.equal(
				deadEndRoom:getPos() + deadEndData:getDirection()
			)
			expect(deadEndRoom:getPos()).to.equal(vertex)
			expect(deadEndRoom:getRoomData()).to.equal(deadEndData)
			expect(deadEndRoom:getSize()).to.equal(Vector3.zero)
		end)
		describe("FlagGrid actions", function()
			it("should add itself onto a flagGrid", function()
				local grid = FlagGrid.new(10, 10, 10)
				corridor:addOnGrid(grid)

				expect(grid:volumeAnd(2, 2, 2, 2, 2, 8)).to.equal(true)
				expect(grid:volumeAnd(2, 2, 2, 10, 2, 2)).to.equal(true)
			end)
			it("should remove itself onto a flagGrid", function()
				local grid = FlagGrid.new(10, 10, 10)
				corridor:addOnGrid(grid)
				corridor:removeFromGrid(grid)

				expect(grid:volumeAnd(2, 2, 2, 2, 2, 8)).to.equal(false)
				expect(grid:volumeAnd(2, 2, 2, 10, 2, 2)).to.equal(false)
			end)
		end)
		it("should check if the corridor is ok", function()
			expect(corridor:isOk()).to.equal(true)

			corridor:addVertex(3)
			corridor:setVertex(3, Vector3.new(5, 2, 4))
			expect(corridor:isOk()).to.equal(false)

			corridor:setVertex(3, Vector3.new(5, 2, 2))
			expect(corridor:isOk()).to.equal(true)
		end)
	end)
end
