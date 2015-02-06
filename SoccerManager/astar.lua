local Class = require "hump.class"
local AStar = {}

AStar.node = Class {
	parent = nil,
	init = function(self, pos, parent)
		self.pos = pos
		self.parent = parent
	end,
	neighbors = function(self)
		map_w = #tilemap.map[1]
		map_h = #tilemap.map

		neighbors = {}
		if (self.pos.x + 1 <= map_w) then
			table.insert(neighbors, AStar.node(
				{x=self.pos.x+1, y=self.pos.y},
				self
			))
		end
		if (self.pos.x - 1 > 0) then
			table.insert(neighbors, AStar.node(
				{x=self.pos.x-1, y=self.pos.y},
				self
			))
		end
		if (self.pos.y + 1 <= map_h) then
			table.insert(neighbors, AStar.node(
				{x=self.pos.x, y=self.pos.y+1},
				self
			))
		end
		if (self.pos.y - 1 > 0) then
			table.insert(neighbors, AStar.node(
				{x=self.pos.x, y=self.pos.y-1},
				self
			))
		end
		return neighbors
	end,
	match = function(self, otherNode)
		if (self.pos.x == otherNode.pos.x and self.pos.y == otherNode.pos.y) then return true end
		return false
	end,
	blocked = function(self)
		if (tilemap:blocked({x=self.pos.x,y=self.pos.y})) then return true end
		return false
	end,
	water = function(self)
		if (tilemap:water({x=self.pos.x,y=self.pos.y})) then return true end
		return false
	end,
	distance = function(self, endPos)
		return math.sqrt(math.pow(self.pos.x - endPos.x, 2) + math.pow(self.pos.y - endPos.y, 2))
	end,
	__tostring = function(self)
		return "AStarNode: " .. self.pos.x .. ", " .. self.pos.y .. ", parent: " .. type(self.parent)
	end
}

function AStar:findFromEntity(entity, endPos)
	local currentTile = entity.tilePos
	local currentPixelPos = entity.sprite.pos
	if (currentPixelPos.x ~= currentTile.x * (gameSettings.tileSize * gameSettings.zoom) ) then
		-- x beweegt
		local leftPos = {x=currentTile.x-1, y=currentTile.y}
		local rightPos = {x=currentTile.x+1, y=currentTile.y}
		if (
			not tilemap:blocked(leftPos) and
			math.sqrt(math.pow(leftPos.x - endPos.x, 2) + math.pow(leftPos.y - endPos.y, 2)) < math.sqrt(math.pow(currentTile.x - endPos.x, 2) + math.pow(currentTile.y - endPos.y, 2))
		) then
			return AStar:find(leftPos, endPos)
		end
		if (
			not tilemap:blocked(rightPos) and
			math.sqrt(math.pow(rightPos.x - endPos.x, 2) + math.pow(rightPos.y - endPos.y, 2)) < math.sqrt(math.pow(currentTile.x - endPos.x, 2) + math.pow(currentTile.y - endPos.y, 2))
		) then
			return AStar:find(rightPos, endPos)
		end
		return AStar:find(currentTile, endPos)
	elseif (currentPixelPos.y ~= currentTile.y * (gameSettings.tileSize * gameSettings.zoom) ) then
		-- y beweegt
		local topPos = {x=currentTile.x, y=currentTile.y-1}
		local bottomPos = {x=currentTile.x, y=currentTile.y+1}
		if (
			not tilemap:blocked(topPos) and
			math.sqrt(math.pow(topPos.x - endPos.x, 2) + math.pow(topPos.y - endPos.y, 2)) < math.sqrt(math.pow(currentTile.x - endPos.x, 2) + math.pow(currentTile.y - endPos.y, 2))
		) then
			return AStar:find(topPos, endPos)
		end
		if (
			not tilemap:blocked(bottomPos) and
			math.sqrt(math.pow(bottomPos.x - endPos.x, 2) + math.pow(bottomPos.y - endPos.y, 2)) < math.sqrt(math.pow(currentTile.x - endPos.x, 2) + math.pow(currentTile.y - endPos.y, 2))
		) then
			return AStar:find(bottomPos, endPos)
		end
		return AStar:find(currentTile, endPos)
	end
	return AStar:find(currentTile, endPos)
end

function AStar:find(startPos, endPos, options)
	closedList = {}
	openList = {}
	table.insert(openList, AStar.node(startPos))
    --print("astar", startPos.x, startPos.y, endPos.x, endPos.y)

	local node = false
	local safety = 0
	while (#openList>0) do
		safety = safety + 1
		if (safety > 999) then
		--	print ("Astar took too long?!")
			break
		end

		local nodeIndex = false
		for n=1, #openList do
			if (nodeIndex  == false or (openList[n]:distance(endPos)<node:distance(endPos))) then
				node = openList[n]
				nodeIndex = n
			end
		end

		if (node.pos.x == endPos.x and node.pos.y == endPos.y) then
			break
		end

		table.insert(closedList, node)
		table.remove(openList, nodeIndex)

		neighbors = node:neighbors()

		for n=1, #neighbors do
			local blocked = true

			if options and options.onlyWater then
			--	print "unblock water"
				blocked = not neighbors[n]:water()
			else
				blocked = neighbors[n]:blocked()
			end
			if (blocked) then
				-- if blocked, then just skip
				table.insert(closedList, neighbors[n])
			else
				-- else, put on open list unless closed
				isClosed = false
				for c=1,#closedList do
					if (closedList[c]:match(neighbors[n])) then
						isClosed = true
						break
					end
				end

				isOpen = false
				for o=1,#openList do
					if (openList[o]:match(neighbors[n])) then
						isOpen = true
						break
					end
				end

				if (not isClosed and not isOpen) then
					table.insert(openList, neighbors[n])
				end
			end
		end
	end

	if (node.pos.x ~= endPos.x or node.pos.y ~= endPos.y) then
		return {AStar.node(startPos)}
	end

	path = {}
	while (node.parent) do
		table.insert(path, 1, node)
		node = node.parent
	end

	table.insert(path, 1, node)

	return path
end

return AStar