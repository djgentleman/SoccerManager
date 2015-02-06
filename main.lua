local Gamestate = require "hump.gamestate"
local SoccerManager = require "SoccerManager.classes"
local AStar = require "SoccerManager.astar"
local LevelManager = require "SoccerManager.levelmanager"

opponents = {}
players = {}

levelManager = {}
decals = {}
match = {}
matchFinishedScreen = {}
matchGameStartScreen = {}

teamPlayer = {
	goals = 0,
	money = 100000
}

teamOpponent = {
	goals = 0
}

matchInformation = {
	time=0
}

gameSettings = {
	resolution={width=0,height=0},
	offset={x=0,y=0},
	tilesHorizontal=22,
	tilesVertical=19,
	tileSize=8,
	zoom=2
}

levelStartTime = 0

function love.load()
	for i=1, 99 do love.math.random() end

	love.graphics.setDefaultFilter("nearest", "nearest")
	love.window.setMode(gameSettings.resolution.width, gameSettings.resolution.height, {fullscreen=true})
	updateResolution()

	levelManager = LevelManager()
	Gamestate.registerEvents()
	Gamestate.switch(matchGameStartScreen)

end

function updateResolution()
	width, height = love.window.getDimensions()

	local desiredTileSize = 0
	if (width > height) then
		desiredTileSize = math.floor(height / gameSettings.tilesVertical)
	else
		desiredTileSize = math.floor(width / gameSettings.tilesHorizontal)
	end

	gameSettings.zoom=math.max(1, math.floor(desiredTileSize / gameSettings.tileSize * 10) / 10)

	gameSettings.resolution.width = math.ceil(gameSettings.tilesHorizontal * gameSettings.tileSize * gameSettings.zoom)
	gameSettings.resolution.height = math.ceil(gameSettings.tilesVertical * gameSettings.tileSize * gameSettings.zoom)

	gameSettings.offset.x = (width - gameSettings.resolution.width) / 2
	gameSettings.offset.y = (height - gameSettings.resolution.height) / 2

	if (gameSettings.resolution.width < 640) then
		mainFont = love.graphics.newFont("font/Sniglet-ExtraBold.otf", 15);
		storyFont = love.graphics.newFont("font/Sniglet-ExtraBold.otf", 40);
	else
		mainFont = love.graphics.newFont("font/Sniglet-ExtraBold.otf", 20);
		storyFont = love.graphics.newFont("font/Sniglet-ExtraBold.otf", 50);
	end

end

function matchFinishedScreen:draw()

	love.graphics.setColor(0,0,0)
	local text = {"Match Finished"}
		for t=1, #text do
			local lineW = storyFont:getWidth(text[t])
			love.graphics.print(text[t], (gameSettings.resolution.width/2)-(lineW/2) + gameSettings.offset.x, math.floor(0.1 * gameSettings.resolution.height) + t * 50 + gameSettings.offset.y)
		end
		love.graphics.reset()
	teamPlayer.money = teamPlayer.money + 10000
end

function matchGameStartScreen:enter()
	levelManager:loadMatch()
	love.graphics.setFont(storyFont)
end

function matchGameStartScreen:draw()
	tilemap:draw()

	love.graphics.setColor(0,0,0)
	local line = "Score " .. teamPlayer.goals .. " - " .. teamOpponent.goals .. "Touch to start the game!"
	local lineW = mainFont:getWidth(line)
	love.graphics.print(line, (gameSettings.resolution.width/2)-(lineW/2)+gameSettings.offset.x, 2 + gameSettings.offset.y)
	love.graphics.reset()

end

function matchGameStartScreen:mousepressed(x, y, button)
	Gamestate.switch(match)
end

function matchGameStartScreen:keypressed(key)
	if (key == "n") then
		Gamestate.switch(match)
	end
end

function match:enter()
	love.graphics.setFont(mainFont);
	levelStartTime = love.timer.getTime()
end

function match:draw()
	tilemap:draw()

	for x=1, #players do
		players[x]:draw()
	end

	for x=1, #opponents do
		opponents[x]:draw()
	end

	ball:draw()

	love.graphics.setColor(0,0,0)
	local line = "Score: " .. teamPlayer.goals .. " - " .. teamOpponent.goals .. "Time: " .. matchInformation.time
	local lineW = mainFont:getWidth(line)
	love.graphics.print(line, (gameSettings.resolution.width/2)-(lineW/2)+gameSettings.offset.x, 2 + gameSettings.offset.y)
	love.graphics.reset()

end

function match:keypressed(key)
	if (key == "n") then
		Gamestate.switch(matchFinishedScreen)
	end
end

function match:update(dt)

	for x=1, #opponents do
		opponents[x]:update(dt)
	end
	for x=1, #players do
		players[x]:update(dt)
	end
	ball:update(dt)

	matchInformation.time = math.floor((love.timer.getTime() - levelStartTime))
end
