local Scene = require('src.scenes.scene')
local NegativeEncounter = {}
NegativeEncounter.__index = NegativeEncounter
NegativeEncounter.__name = "negativeEncounter"
setmetatable(NegativeEncounter, Scene)

function NegativeEncounter.new()
    local self = Scene.new()
    setmetatable(self, NegativeEncounter)
    return self
end

function NegativeEncounter:init()
    self.state = {
        selectedOption = 1,
        config = nil,
        resolved = false
    }
end

function NegativeEncounter:enter()
    -- Get encounter configuration
    local EncounterRegistry = require('src.encounters.encounterRegistry')
    self.state.config = EncounterRegistry:getConfig(gameState.currentEncounter)
end

function NegativeEncounter:update(dt)
    if love.keyboard.wasPressed('escape') then
        sceneManager:switch(gameState.previousScene or 'provinceMap')
        return
    end

    if not self.state.resolved then
        if love.keyboard.wasPressed('up') then
            self.state.selectedOption = self.state.selectedOption - 1
            if self.state.selectedOption < 1 then 
                self.state.selectedOption = #self.state.config.resolutionOptions 
            end
        elseif love.keyboard.wasPressed('down') then
            self.state.selectedOption = self.state.selectedOption + 1
            if self.state.selectedOption > #self.state.config.resolutionOptions then 
                self.state.selectedOption = 1 
            end
        elseif love.keyboard.wasPressed('return') then
            self:resolveEncounter()
        end
    else
        if love.keyboard.wasPressed('return') then
            sceneManager:switch(gameState.previousScene or 'provinceMap')
        end
    end
end

function NegativeEncounter:draw()
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Draw encounter name and description
    love.graphics.printf(self.state.config.name, 0, 50, love.graphics.getWidth(), 'center')
    love.graphics.printf(self.state.config.description, 50, 100, love.graphics.getWidth() - 100, 'center')

    if not self.state.resolved then
        -- Draw resolution options
        local startY = 200
        for i, option in ipairs(self.state.config.resolutionOptions) do
            local text = i == self.state.selectedOption and "> " .. option or option
            love.graphics.printf(text, 100, startY + (i * 30), love.graphics.getWidth() - 200, 'center')
        end
    else
        -- Draw resolution message
        love.graphics.printf("Encounter resolved!\nPress ENTER to continue", 0, 300, love.graphics.getWidth(), 'center')
    end
end

function NegativeEncounter:resolveEncounter()
    -- Implement resolution logic here
    self.state.resolved = true
end

return NegativeEncounter
