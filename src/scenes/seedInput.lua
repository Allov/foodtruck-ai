local Scene = require('src.scenes.scene')
local SeedInput = {}
SeedInput.__index = SeedInput
setmetatable(SeedInput, Scene) -- Inherit from Scene

function SeedInput.new()
    local self = setmetatable({}, SeedInput)
    self:init() -- Call init after creation
    return self
end

function SeedInput:init()
    self.seedInput = ""
    self.useRandomSeed = true
    self.options = {"Random Seed", "Enter Seed"}
    self.selected = 1
    self.inputtingSeed = false
    
    -- Initialize confirmation dialog
    self:initConfirmDialog()
    
    -- Convert string to numeric seed
    self.stringToSeed = function(str)
        local seed = 0
        for i = 1, #str do
            seed = seed + string.byte(str, i) * (31 ^ (i - 1))
        end
        return seed
    end
end

function SeedInput:update(dt)
    if self.showingConfirmDialog then
        self:updateConfirmDialog()
        return
    end

    if love.keyboard.wasPressed('escape') then
        if self.inputtingSeed then
            self.inputtingSeed = false
            self.seedInput = ""
        else
            self.showingConfirmDialog = true
        end
        return
    end

    if self.inputtingSeed then
        if love.keyboard.wasPressed('return') and #self.seedInput > 0 then
            gameState.mapSeed = self.stringToSeed(self.seedInput)
            sceneManager:switch('chefSelect')
        elseif love.keyboard.wasPressed('escape') then
            self.inputtingSeed = false
            self.seedInput = ""
        elseif love.keyboard.wasPressed('backspace') then
            self.seedInput = self.seedInput:sub(1, -2)
        end
    else
        if love.keyboard.wasPressed('up') or love.keyboard.wasPressed('down') then
            self.selected = self.selected == 1 and 2 or 1
        elseif love.keyboard.wasPressed('return') then
            if self.selected == 1 then
                -- Random seed
                gameState.mapSeed = os.time()
                sceneManager:switch('chefSelect')
            else
                -- Enter custom seed
                self.inputtingSeed = true
            end
        elseif love.keyboard.wasPressed('escape') then
            sceneManager:switch('mainMenu')
        end
    end
end

function SeedInput:draw()
    -- Draw regular scene content
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Choose Seed Type", 0, 100, love.graphics.getWidth(), 'center')
    
    if self.inputtingSeed then
        love.graphics.printf("Enter Seed Name:", 0, 200, love.graphics.getWidth(), 'center')
        
        -- Draw input box
        local boxWidth = love.graphics.getWidth() / 2
        local boxHeight = 40
        local boxX = love.graphics.getWidth() / 4
        local boxY = 250
        
        love.graphics.rectangle('line', boxX, boxY, boxWidth, boxHeight)
        love.graphics.printf(
            self.seedInput .. (love.timer.getTime() % 1 < 0.5 and "|" or ""),
            boxX, boxY + 10, boxWidth, 'center'
        )
        
        -- Instructions
        love.graphics.printf(
            "Press Enter to confirm or Escape to cancel",
            0, boxY + 60, love.graphics.getWidth(), 'center'
        )
    else
        for i, option in ipairs(self.options) do
            if i == self.selected then
                love.graphics.setColor(1, 1, 0, 1)
            else
                love.graphics.setColor(1, 1, 1, 1)
            end
            love.graphics.printf(option, 0, 200 + i * 40, love.graphics.getWidth(), 'center')
        end
        
        -- Instructions
        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.printf(
            "Use Up/Down to select, Enter to confirm, Escape to return",
            0, 350, love.graphics.getWidth(), 'center'
        )
    end

    -- Draw confirmation dialog if active
    if self.showingConfirmDialog then
        self:drawConfirmDialog()
    end
end

return SeedInput

