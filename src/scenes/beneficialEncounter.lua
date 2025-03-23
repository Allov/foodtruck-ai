local Scene = require('src.scenes.scene')
local BeneficialEncounter = {}
BeneficialEncounter.__index = BeneficialEncounter
BeneficialEncounter.__name = "beneficialEncounter"
setmetatable(BeneficialEncounter, Scene)

local COLORS = {
    PRIMARY = {0, 1, 0, 1},      -- Green for beneficial theme
    TEXT = {1, 1, 1, 1},
    HIGHLIGHT = {0.8, 1, 0.8, 1},
    ACCENT = {0.5, 1, 0.5, 1}
}

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
    -- Draw background overlay
    love.graphics.setColor(COLORS.PRIMARY[1], COLORS.PRIMARY[2], COLORS.PRIMARY[3], 0.1)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw encounter name and description
    love.graphics.setColor(COLORS.TEXT)
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

