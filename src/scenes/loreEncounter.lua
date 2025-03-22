local Scene = require('src.scenes.scene')
local LoreEncounter = {}
LoreEncounter.__index = LoreEncounter
LoreEncounter.__name = "loreEncounter"
setmetatable(LoreEncounter, Scene)

function LoreEncounter.new()
    local self = Scene.new()
    setmetatable(self, LoreEncounter)
    return self
end

function LoreEncounter:init()
    self.state = {
        config = nil,
        resolved = false
    }
end

function LoreEncounter:enter()
    -- Get encounter configuration
    local EncounterRegistry = require('src.encounters.encounterRegistry')
    self.state.config = EncounterRegistry:getConfig(gameState.currentEncounter)
end

function LoreEncounter:update(dt)
    if love.keyboard.wasPressed('escape') or love.keyboard.wasPressed('return') then
        if gameState.currentNodeLevel and gameState.currentNodeIndex then
            local provinceMap = sceneManager.scenes['provinceMap']
            provinceMap:markNodeCompleted(gameState.currentNodeLevel, gameState.currentNodeIndex)
        end
        sceneManager:switch(gameState.previousScene or 'provinceMap')
    end
end

function LoreEncounter:draw()
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Draw encounter name and description
    love.graphics.printf(self.state.config.name, 0, 50, love.graphics.getWidth(), 'center')
    love.graphics.printf(self.state.config.description, 50, 100, love.graphics.getWidth() - 100, 'center')
    
    -- Draw prompt
    love.graphics.printf("Press ENTER to continue", 0, 300, love.graphics.getWidth(), 'center')
end

return LoreEncounter
