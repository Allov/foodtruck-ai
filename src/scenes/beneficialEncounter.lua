local Scene = require('src.scenes.scene')
local BeneficialEncounter = {}
BeneficialEncounter.__index = BeneficialEncounter
BeneficialEncounter.__name = "beneficialEncounter"
setmetatable(BeneficialEncounter, Scene)

function BeneficialEncounter.new()
    local self = Scene.new()
    setmetatable(self, BeneficialEncounter)
    return self
end

function BeneficialEncounter:init()
    self.state = {
        config = nil,
        resolved = false
    }
end

function BeneficialEncounter:enter()
    -- Get encounter configuration
    local EncounterRegistry = require('src.encounters.encounterRegistry')
    self.state.config = EncounterRegistry:getConfig(gameState.currentEncounter)
end

function BeneficialEncounter:update(dt)
    if love.keyboard.wasPressed('escape') then
        sceneManager:switch(gameState.previousScene or 'provinceMap')
        return
    end

    if not self.state.resolved then
        if love.keyboard.wasPressed('return') then
            self:resolveEncounter()
        end
    else
        if love.keyboard.wasPressed('return') then
            sceneManager:switch(gameState.previousScene or 'provinceMap')
        end
    end
end

function BeneficialEncounter:draw()
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Draw encounter name and description
    love.graphics.printf(self.state.config.name, 0, 50, love.graphics.getWidth(), 'center')
    love.graphics.printf(self.state.config.description, 50, 100, love.graphics.getWidth() - 100, 'center')

    if not self.state.resolved then
        -- Draw prompt
        love.graphics.printf("Press ENTER to receive your reward!", 0, 300, love.graphics.getWidth(), 'center')
    else
        -- Draw resolution message
        love.graphics.printf("You received your reward!\nPress ENTER to continue", 0, 300, love.graphics.getWidth(), 'center')
    end
end

function BeneficialEncounter:resolveEncounter()
    -- Implement reward logic here based on rewardTier and other config properties
    self.state.resolved = true
end

return BeneficialEncounter
