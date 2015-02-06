local Class = require "hump.class"
local AStar = require "soccerManager.astar"
local SoccerManager = {}

SoccerManager.Tilemap = Class {
	init = function(self, image)
		self.tilesetBatch = love.graphics.newSpriteBatch(image, gameSettings.resolution.width / (gameSettings.tileSize * gameSettings.zoom) * gameSettings.resolution.height / (gameSettings.tileSize * gameSettings.zoom))

		self.quads = {}
		self.quads[0] = love.graphics.newQuad(0, 0, 8, 8, image:getWidth(), image:getHeight()) 	-- empty
		self.quads[1] = love.graphics.newQuad(16, 0, 16, 16, image:getWidth(), image:getHeight()) 	-- wood
		self.quads[2] = love.graphics.newQuad(32, 0, 16, 16, image:getWidth(), image:getHeight()) 	-- rope
		self.quads[3] = love.graphics.newQuad(0, 0, 8, 8, image:getWidth(), image:getHeight()) 	-- water
		self.quads[4] = love.graphics.newQuad(64, 0, 16, 16, image:getWidth(), image:getHeight()) 	-- rock
		end,

	updateTilesetBatch = function(self)
		self.tilesetBatch:clear()
		for x=1, gameSettings.resolution.width / (gameSettings.tileSize * gameSettings.zoom) do
			for y=1, gameSettings.resolution.height / (gameSettings.tileSize * gameSettings.zoom) do
				self.tilesetBatch:add(
					self.quads[self.map[y][x]],
					(x - 1) * (gameSettings.tileSize * gameSettings.zoom) + gameSettings.offset.x,
					(y - 1) * (gameSettings.tileSize * gameSettings.zoom) + gameSettings.offset.y,
					0, gameSettings.zoom
				)
			end
		end
	end,

	loadMap = function(self, map)
		self.map = map
		self:updateTilesetBatch()
	end,
	updateMap = function(self, pos, value)
		self.map[pos.y][pos.x] = value
		self:updateTilesetBatch()
	end,

	draw = function(self)
		love.graphics.draw(self.tilesetBatch)
	end,

	tile = function(self, x, y)
		return self.map[y][x]
	end,

	valid = function(self, pos)
		if (pos.y > 0 and pos.y <= #self.map) then
			if (pos.x > 0 and pos.x <= #self.map[1]) then
				return true
			end
		end
		do return false end
	end,

	blocked = function(self, pos)

		if (self:valid(pos)) then
			if (self.map[pos.y][pos.x] == 3) then return false end
			--if (self.map[pos.y][pos.x] == 4) then return true end
			do return false end
		end
		return true
	end
}

SoccerManager.Animation = Class {
	init = function(self, image, pos, steps, updateDelay)
		if (steps == nil) then steps = 1 end
		if (updateDelay == nil) then updateDelay = 0.1 end

		self.animationRunning = false

		self.pos = pos

		self.width = image:getWidth()
		self.height = image:getHeight()

		self.frames = {}
		self.currentFrameNumber = 1

		self.cyclesSinceLastUpdate = 0
		self.updateDelay = updateDelay

		self.frameWidth = self.width / steps
		self.frameHeight = self.height

		self:setFrames(image, steps)

		self.flip = 1
		self.flipWidth = 0
	end,
	setFlip = function(self, flip)
		if (flip) then
			self.flip = -1
			self.flipWidth = self.frameWidth
		else
			self.flip = 1
			self.flipWidth = 0
		end
	end,
	setFrames = function(self, image, steps)
		self.image = image
		for x=0, steps do
			self.frames[x+1] = love.graphics.newQuad((x*self.frameWidth), 0, self.frameWidth, self.frameHeight, self.width, self.height)
		end
	end,
	update = function(self, dt)
		if (not self.animationRunning) then return true end

		if (#self.frames == 1) then return true end
		self.cyclesSinceLastUpdate = self.cyclesSinceLastUpdate + dt
		if (self.cyclesSinceLastUpdate > self.updateDelay) then
			self.currentFrameNumber = self.currentFrameNumber + 1
			if (self.currentFrameNumber == #self.frames) then self.currentFrameNumber = 1 end
			self.cyclesSinceLastUpdate = 0
		end
	end,
	draw = function(self)
		love.graphics.draw(self.image, self.frames[self.currentFrameNumber], self.pos.x + gameSettings.offset.x, self.pos.y + gameSettings.offset.y, 0, self.flip * gameSettings.zoom, gameSettings.zoom, self.flipWidth)
	end,
	start = function(self)
		self.animationRunning = true
	end,
	stop = function(self)
		self.currentFrameNumber = 1
		self.cyclesSinceLastUpdate = 0
		self.animationRunning = false
	end,
	intersect = function(self, x, y)
		if (
			x>=self.pos.x and x<=self.pos.x+(self.frameWidth * gameSettings.zoom) and
			y>=self.pos.y and y<=self.pos.y+(self.frameHeight * gameSettings.zoom)
			) then
			return true
		end
	end,
	center = function(self)
		return {x=self.pos.x+((self.frameWidth * gameSettings.zoom) / 2), y=self.pos.y+((self.frameHeight * gameSettings.zoom) / 2)}
	end
}

SoccerManager.Entity = Class {
	init = function(self, image, tilePos, steps)
		self.tilePos = tilePos
		self.pixelOffset = {x=0, y=0}

		self.sprite = SoccerManager.Animation(
			image,
			self:pixelPos(),
			steps
		)
		self.job = nil
	end,
	pixelPos = function(self)
		return {
			x = ((self.tilePos.x - 1) * gameSettings.tileSize * gameSettings.zoom) + self.pixelOffset.x,
			y = ((self.tilePos.y - 1) * gameSettings.tileSize * gameSettings.zoom) + self.pixelOffset.y
		}
	end,
 	draw = function(self)
 		self.sprite.pos = self:pixelPos()
		self.sprite:draw()

	end,
	update = function(self, dt)
		self.sprite:update(dt)
		if (self.job) then
			local jobResult = self.job:update(dt)
			if (not jobResult) then self.job=nil end
		end
	end,
	giveJob = function(self, name, options)
		-- load a dynamic class based on "name" variable
		self.job = SoccerManager[name](self, options)
	end,
	giveJobIfReady = function(self, name, options)
		if (self.job == nil) then
			self:giveJob(name, options)
			return true
		end
		return false
	end
}

SoccerManager.ball = Class{
	__includes = SoccerManager.Entity,
	init = function(self, x, y, speed)
		local posBall = {x=x,y=y}
		self.normalImage = love.graphics.newImage("tileset/ball.png")
		SoccerManager.Entity.init(self, self.normalImage, posBall, 1)

		self.momentum = 0
	end,
	receiveKick = function(self, direction)
		if (self.momentum < 80) then
			self.direction = direction
			self.momentum = 100
		end
	end,
	update = function(self, dt)
		if (self.momentum > 0) then
			self.momentum = math.max(0, self.momentum - 1)

			local currentTilePos = self.tilePos
			local currentPixelOffset = self.pixelOffset

			local movementFactor    = (self.momentum / 100)
			local maxPixelOffset 	= gameSettings.tileSize * gameSettings.zoom
			local minPixelOffset 	= -1 * maxPixelOffset

			currentPixelOffset.x = currentPixelOffset.x+movementFactor*self.direction.x
			currentPixelOffset.y = currentPixelOffset.y+movementFactor*self.direction.y

			-- update beweging

			if (currentPixelOffset.x >= maxPixelOffset) then
				self.tilePos.x = self.tilePos.x + 1
				currentPixelOffset.x = 0
			end
			if (currentPixelOffset.x <= minPixelOffset) then
				self.tilePos.x = self.tilePos.x - 1
				currentPixelOffset.x = 0
			end
			if (currentPixelOffset.y >= maxPixelOffset) then
				self.tilePos.y = self.tilePos.y + 1
				currentPixelOffset.y = 0
			end
			if (currentPixelOffset.y <= minPixelOffset) then
				self.tilePos.y = self.tilePos.y - 1
				currentPixelOffset.y = 0
			end

			-- bounce

			local overTheLine = (maxPixelOffset / 2)

			if (self.tilePos.y > gameSettings.tilesVertical or
				(self.tilePos.y == gameSettings.tilesVertical and currentPixelOffset.y > overTheLine)
				) then
				self.tilePos.y = gameSettings.tilesVertical
				currentPixelOffset.y = 0
				self.direction.y = -1 * self.direction.y
				self:bounce()
			end
			if (self.tilePos.y < 1 or
				(self.tilePos.y == 1 and currentPixelOffset.y < -1 * overTheLine)
				) then
				self.tilePos.y = 1
				currentPixelOffset.y = 0
				self.direction.y = -1 * self.direction.y
				self:bounce()
			end
			if (self.tilePos.x > gameSettings.tilesHorizontal or
				(self.tilePos.x == gameSettings.tilesHorizontal and currentPixelOffset.x > overTheLine)
				) then
				self.tilePos.x = gameSettings.tilesHorizontal
				currentPixelOffset.x = 0
				self.direction.x = -1 * self.direction.x
				self:bounce()
			end
			if (self.tilePos.x < 1 or
				(self.tilePos.x == 1 and currentPixelOffset.x < -1 * overTheLine)
				) then
				self.tilePos.x = 1
				currentPixelOffset.x = 0
				self.direction.x = -1 * self.direction.x
				self:bounce()
			end

			self.pixelOffset = currentPixelOffset
		end,
		bounce = function(self)
			-- check de x en de y waarde van de bal
			-- local pos = self:tilePos()

		end
	end
}

SoccerManager.player = Class {
	__includes = SoccerManager.Entity,
	init = function(self, pos)
		self.normalImage = love.graphics.newImage("tileset/team1.png")
		SoccerManager.Entity.init(self, self.normalImage, pos, 4)
		self.sprite:setFlip(true)
	end,
	update = function(self, dt)
		SoccerManager.Entity.update(self, dt)
		if (self.job == nil) then
			-- ga kijken of de bal in de buurt is

			if (ball.tilePos.x == self.tilePos.x and
				-- bal in de buurt
				ball.tilePos.y == self.tilePos.y) then
				local randomX = math.floor(love.math.random()*10) - 5
				local randomY = math.floor(love.math.random()*10) - 5
				ball:receiveKick({x=randomX,y=randomY})
			else
				-- bal NIET in de buurt
				local deltaX = math.abs(ball.tilePos.x - self.tilePos.x)
				local deltaY = math.abs(ball.tilePos.y - self.tilePos.y)
				local lookAround = 6

				if 	((deltaX < lookAround) and (deltaY < lookAround)) then
				 	self:giveJob("walkToBall")
				end

				-- van elkaar af gaan staan
			end
		end
	end,
	arrive = function()
	end
}

SoccerManager.opponent = Class {
	__includes = SoccerManager.player,
	init = function(self, pos)
		SoccerManager.player.init(self, pos)
		self.normalImage = love.graphics.newImage("tileset/team2.png")
		SoccerManager.Entity.init(self, self.normalImage, pos, 4)
		self.sprite:setFlip(false)
	end
}

-- =================================================================================

SoccerManager.Job = Class {
	init = function(self, actor, options)
		self.actor = actor
		self.cyclesSinceLastUpdate = 0
		self.updateDelay = 0.1
		self.options = options
	end,
	update = function(self, dt)
		local jobResult = self:process(dt)
		if (not jobResult) then return false end
		return true
	end,
	process = function(self, dt)
		return false
	end
}

SoccerManager.walkToBall =  Class {
	__includes = SoccerManager.Job,
	init = function(self, actor, options)
		SoccerManager.Job.init(self, actor, options)
	end,
	process = function(self, dt)
		local path = AStar:findFromEntity(self.actor, {x=ball.tilePos.x, y=ball.tilePos.y})
		self.actor:giveJob("walkPath", {path=path})
		return true
	end
}

SoccerManager.walkPath = Class {
	__includes = SoccerManager.Job,
	init = function(self, actor, options)
		SoccerManager.Job.init(self, actor, options)
		-- local currentPos = self.actor.tilePos
		-- local goalTile = self.options.path[1]
		-- if (currentPos.x == goalTile.pos.x and currentPos.y == goalTile.pos.y) then table.remove(self.options.path, 1) end
		self.speed = 150
		if (self.options.speed) then self.speed = self.options.speed end
		self.actor.sprite:start()
	end,
	process = function(self, dt)
		local currentTilePos = self.actor.tilePos
		local currentPixelOffset = self.actor.pixelOffset
		local goalTilePos = self.options.path[1].pos

		if (currentTilePos.x == goalTilePos.x and currentTilePos.y == goalTilePos.y) then
			if (currentPixelOffset.x == 0 and currentPixelOffset.y==0) then
				table.remove(self.options.path,1)
				if (#self.options.path == 0) then
					self.actor.sprite:stop()
					print("aangekomen")
					return self.actor:arrive(goalTilePos)
				end
				return true
			end
		end

		local movement 			= self.speed * dt
		local maxPixelOffset 	= gameSettings.tileSize * gameSettings.zoom
		local minPixelOffset 	= -1 * maxPixelOffset

		-- naar links
		if currentTilePos.x > goalTilePos.x then
			currentPixelOffset.x = currentPixelOffset.x-movement
		end
		-- naar rechts
		if currentTilePos.x < goalTilePos.x then
			currentPixelOffset.x = currentPixelOffset.x+movement
		end
		-- omhoog
		if currentTilePos.y > goalTilePos.y then
			currentPixelOffset.y = currentPixelOffset.y-movement
		end
		-- omlaag
		if currentTilePos.y < goalTilePos.y then
			currentPixelOffset.y = currentPixelOffset.y+movement
		end

		currentPixelOffset.x = math.max(minPixelOffset, math.min(maxPixelOffset, currentPixelOffset.x))
		currentPixelOffset.y = math.max(minPixelOffset, math.min(maxPixelOffset, currentPixelOffset.y))

		if (currentPixelOffset.x >= maxPixelOffset) then
			self.actor.tilePos.x = self.actor.tilePos.x + 1
			currentPixelOffset.x = 0
		end
		if (currentPixelOffset.x <= minPixelOffset) then
			self.actor.tilePos.x = self.actor.tilePos.x - 1
			currentPixelOffset.x = 0
		end
		if (currentPixelOffset.y >= maxPixelOffset) then
			self.actor.tilePos.y = self.actor.tilePos.y + 1
			currentPixelOffset.y = 0
		end
		if (currentPixelOffset.y <= minPixelOffset) then
			self.actor.tilePos.y = self.actor.tilePos.y - 1
			currentPixelOffset.y = 0
		end

		self.actor.pixelOffset = currentPixelOffset
		return true
	end
}

SoccerManager.keeperWait = Class {
	__includes = SoccerManager.Job,
	init = function(self, actor, options)
		SoccerManager.Job.init(self, actor, options)
	end,
	process = function(self, dt)
		-- ik heb de bal niet en ik moet wachten.
		local actorPos = self.actor.tilePos
		local rand16Meters = actorPos.y - 1
		local randomGetal = math.random(1, 100)
		local goalPosY = 1
		if (rand16Meters < 8 ) then
			goalPosY = actorPos.y + 1
		elseif (rand16Meters > 14 ) then
			goalPosY = actorPos.y - 1
		else
			if (randomGetal <= 49) then
				goalPosY = actorPos.y + 1
			else
				goalPosY = actorPos.y - 1
			end
		end

		path = AStar:find({x=actorPos.x,y=actorPos.y}, {x=actorPos.x,y=goalPosY})
		self.actor:giveJob("WalkPath", {path=path,speed=75})
		return true
	end
}

SoccerManager.keeperBlock = Class {
	__includes = SoccerManager.Job,
	init = function(self, actor, options)
		SoccerManager.Job.init(self, actor, options)
	end,
	process = function(self, dt)
		-- ik heb de bal niet en ik moet wachten.
		local actorPos = self.actor.tilePos
		local randomGetal = math.random(1, 100)
		local goalPosX = 1
		local goalPosY = 1
		if (randomGetal <= 50) then
			goalPosX = actorPos.x
			goalPosY = actorPos.y - 1
		else
			goalPosX = actorPos.x
			goalPosY = actorPos.y + 1
		end
		path = AStar:find({x=actorPos.x,y=actorPos.y}, {x=goalPosX,y=goalPosY})
		self.actor:giveJob("WalkPath", {path=path,speed=100})
		return true
	end
}

SoccerManager.defenderPositionWalk = Class {
	__includes = SoccerManager.Job,
	init = function(self, actor, options)
		SoccerManager.Job.init(self, actor, options)
	end,
	process = function(self, dt)
		local actorPos = self.actor.tilePos
		local goalPosX = actorPos.x - 1
		local goalPosY = 1
		local randomPOSGetalY = math.random(1, 100)
		if (randomPOSGetalY <= 50) then
			goalPosY = actorPos.y - 1
		else
			goalPosY = actorPos.y + 1
		end

		path = AStar:find({x=actorPos.x,y=actorPos.y}, {x=goalPosX,y=goalPosY})
		self.actor:giveJob("WalkPath", {path=path,speed=100})
		self.actor.energy = self.actor.energy - 1
		print ("x", goalPosX)
		return true
	end
}

SoccerManager.passBall = Class {
	__includes = SoccerManager.Job,
	init = function(self, actor, options)
		SoccerManager.Job.init(self, actor, options)
	end,
	process = function(self, dt)
		-- ik paas de bal.
		if (opponent == true) then
		end

		if(ball.speed < 15) then
			return true
		else
			ball.speed = ball.speed - 10
		end
		return true
	end
}

return SoccerManager