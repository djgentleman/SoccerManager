local Class = require "hump.class"
local Gamestate = require "hump.gamestate"
local SoccerManager = require "SoccerManager.classes"
local LevelManager = {}

LevelManager = Class {
	init = function(self)
		--????????????
		--type level in de toekomst kun je met verschillende type levels andere mappen laden.
		--bijvoorbeeld level waar veld onder sneeuw ligt of juist veel zand etc.
		self.typeLevel = 1
	end,

	loadMatch = function(self)

		local map = {}
		local l = self.typeLevel
		if (l == 1) then
			-- 22 breed
			-- 19 hoog
			map =
				{
					{ 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3},
					{ 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3},
					{ 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3},
					{ 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3},
					{ 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3},
					{ 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3 ,3},
					{ 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3},
					{ 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3},
					{ 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3},
					{ 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3},
					{ 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3},
					{ 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3},
					{ 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3},
					{ 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3},
					{ 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3},
					{ 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3},
					{ 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3},
					{ 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3},
					{ 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3}
					}
				players = {
					SoccerManager.player({x=1, y=11}, "goalkeeper", 10),
					SoccerManager.player({x=4, y=2}, "defender", 10),
					SoccerManager.player({x=3, y=7}, "goalkeeper", 10),
					SoccerManager.player({x=3, y=15}, "goalkeeper", 10),
					SoccerManager.player({x=4, y=18}, "goalkeeper", 10),
					SoccerManager.player({x=7, y=3}, "goalkeeper", 10),
					SoccerManager.player({x=6, y=8}, "goalkeeper", 10),
					SoccerManager.player({x=6, y=14}, "goalkeeper", 10),
					SoccerManager.player({x=7, y=17}, "goalkeeper", 10),
					SoccerManager.player({x=10, y=9}, "goalkeeper", 10),
					SoccerManager.player({x=10, y=13}, "goalkeeper", 10)
				}
				opponents = {
					SoccerManager.opponent({x=21,y=11}, "goalkeeper", 10),
					SoccerManager.opponent({x=18,y=2}, "defender", 10),
					SoccerManager.opponent({x=19,y=7}, "midfielder", 10),
					SoccerManager.opponent({x=19,y=15}, "midfielder", 10),
					SoccerManager.opponent({x=18,y=18}, "midfielder", 10),
					SoccerManager.opponent({x=15,y=3}, "midfielder", 10),
					SoccerManager.opponent({x=16,y=8}, "midfielder", 10),
					SoccerManager.opponent({x=16,y=14}, "midfielder", 10),
					SoccerManager.opponent({x=15,y=17}, "midfielder", 10),
					SoccerManager.opponent({x=12,y=9}, "attacker", 10),
					SoccerManager.opponent({x=12,y=13}, "attacker", 10)
				 }
				 ball = SoccerManager.ball(10,10,100)
		end

		tilemap = SoccerManager.Tilemap(love.graphics.newImage("tileset/tilemap.png"))

		tilemap:loadMap(map)
	end
}

return LevelManager