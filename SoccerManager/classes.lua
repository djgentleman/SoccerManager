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
	init = function(self, image, pos, steps, typeOpponent, energy, updateDelay)
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
		love.graphics.draw(self.image, self.frames[self.currentFrameNumber], self.pos.x + gameSettings.offset.x, self.pos.y + gameSettings.offset.y, 0, gameSettings.zoom, gameSettings.zoom)
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
	init = function(self, image, pos, steps, typeOpponent, energy)
		self.sprite = SoccerManager.Animation(
			image,
			{x=(pos.x-1)*gameSettings.tileSize*gameSettings.zoom, y=(pos.y-1)*gameSettings.tileSize*gameSettings.zoom},
			steps,
			typeOpponent,
			energy
		)
		self.job = nil
		self.tilePosCache = self:tilePos()
	end,
	tilePos = function(self)
		local tile_x = math.floor(self.sprite.pos.x * 1000 / (gameSettings.tileSize * gameSettings.zoom * 1000)) + 1
		local tile_y = math.floor(self.sprite.pos.y * 1000 / (gameSettings.tileSize * gameSettings.zoom * 1000)) + 1
		
		return {x = tile_x, y=tile_y}
	end,
	recalculateSpritePosition = function(self)
		self.sprite.pos = {
			x=(self.tilePosCache.x-1)*(gameSettings.tileSize*gameSettings.zoom),
			y=(self.tilePosCache.y-1)*(gameSettings.tileSize*gameSettings.zoom)
		}
	end,
 	draw = function(self)
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
	end
}

SoccerManager.player = Class {
	__includes = SoccerManager.Entity,
	init = function(self, pos, typePlayer)
		self.normalImage = love.graphics.newImage("tileset/team1.png")
		
		SoccerManager.Entity.init(self, self.normalImage, pos, 4)
	end,
	giveJob = function(self, name, options)
		-- load a dynamic class based on "name" variable
		options.speed = self.speed
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
	--print ("wat is x ", x, "en y ", y)
		local posBall = {x=x,y=y}
		self.normalImage = love.graphics.newImage("tileset/ball.png")
		SoccerManager.Entity.init(self, self.normalImage, posBall, 4)
	end
}

SoccerManager.opponent = Class {
	__includes = SoccerManager.Entity,
	init = function(self, pos, typeOpponent, energy)
		self.normalImage = love.graphics.newImage("tileset/team2.png")
		self.typeOpponent = typeOpponent
		self.energy = energy
		SoccerManager.Entity.init(self, self.normalImage, pos, 4, typeOpponent, energy)
	end,
	
	update = function(self, dt)
		SoccerManager.Entity.update(self, dt)
		
	-- collision with ball
	local opponentCenter = self.sprite:center()
		
		if (self.job == nil) then
			if (self.typeOpponent == "goalkeeper") then
				local randomGetal = math.random(1, 100)
				if (randomGetal < 100) then
					-- keeper blijft op doellijn staan
					self:giveJob("keeperWait")
				else
					local deltaX = self.sprite.pos.x - ball.x
					local deltaY = self.sprite.pos.y - ball.y
					if (deltaX > 1) then
						self:giveJob("keeperBlock")
					else
						self:giveJob("keeperWait")
					end
				end
			
			elseif (self.typeOpponent == "defender") then
				if (self.job == nil) then
				
					local randomGetal = math.random(1, 100)
					if (randomGetal <=70) then
						print("pass energy low",self.energy)
						if (self.energy <= 2) then
							-- ik ben moe en wil paas geven
							ball.speed = 50
							self:giveJob("passBall")

							
						else
							self:giveJob("defenderPositionWalk")

						end
						
						-- geef ik een paas

					elseif (randomGetal >70 and randomGetal <=90) then
						-- speel ik terug naar de keeper
					else
						-- paas recht naar voren zo hard ik kan
						ball.speed = 60
						self:giveJob("passBall", {opponent=true})
					end
				end
			elseif (self.typeOpponent == "midfielder") then
				
			
			elseif (self.typeOpponent == "attacker") then
			
				local randomGoal = math.random(1, 100)
				if (randomGoal < 2) then
					teamPlayer.goals = teamPlayer.goals + 1
				end
			end
		end
	end,
	
	arrive = function(self, x, y)
		--loop en ik kom aan op mijn positie en wat ga ik dan doen?
	end
}

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

SoccerManager.WalkPath = Class {
	__includes = SoccerManager.Job,
	init = function(self, actor, options)
		SoccerManager.Job.init(self, actor, options)
		local currentPos = self.actor.sprite.pos
		--if (#self.options.path > 1) then table.remove(self.options.path, 1) end

		local goalTile = self.options.path[1]
		if (currentPos.x == goalTile.pos.x and currentPos.y == goalTile.pos.y) then table.remove(self.options.path, 1) end

		self.speed = 150
		if (self.options.speed) then self.speed = self.options.speed end
		self.actor.sprite:start()
	end,
	process = function(self, dt)
		local currentPos = self.actor.sprite.pos
		local goalTile = self.options.path[1]

		local goalPos = {
			x=(goalTile.pos.x-1)*gameSettings.tileSize*gameSettings.zoom,
			y=(goalTile.pos.y-1)*gameSettings.tileSize*gameSettings.zoom
		}

		if currentPos.x==goalPos.x and currentPos.y==goalPos.y then
			table.remove(self.options.path,1)
			self.actor.tilePosCache = self.actor:tilePos()
			if (#self.options.path == 0) then
				self.actor.sprite:stop()
				return self.actor:arrive(goalTile.pos.x,goalTile.pos.y)
			end
			return true
		end

		local movement = self.speed * dt

		if currentPos.x > goalPos.x then
			currentPos.x = math.max(currentPos.x-movement, goalPos.x)
		end
		if currentPos.x < goalPos.x then
			currentPos.x = math.min(currentPos.x+movement, goalPos.x)
		end
		if currentPos.y > goalPos.y then
			currentPos.y = math.max(currentPos.y-movement, goalPos.y)
		end
		if currentPos.y < goalPos.y then
			currentPos.y = math.min(currentPos.y+movement, goalPos.y)
		end

		self.actor.sprite.pos = currentPos
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
		local actorPos = self.actor:tilePos()
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
		local actorPos = self.actor:tilePos()
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
		local actorPos = self.actor:tilePos()
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