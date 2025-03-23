local Scene = require('src.scenes.scene')
local SeedInput = {}
SeedInput.__index = SeedInput
setmetatable(SeedInput, Scene) -- Inherit from Scene

-- Consistent styling across menus
local COLORS = {
    TITLE = {1, 0.8, 0, 1},      -- Gold for title
    TEXT = {1, 1, 1, 1},         -- White for regular text
    SELECTED = {1, 0.8, 0, 1},   -- Gold for selected item
    UNSELECTED = {0.7, 0.7, 0.7, 1}, -- Slightly dimmed for unselected
    BACKGROUND = {0.1, 0.1, 0.2, 1} -- Dark blue background
}

local FONTS = {
    TITLE = love.graphics.newFont(48),
    MENU = love.graphics.newFont(24),
    INSTRUCTIONS = love.graphics.newFont(16)
}

-- Animation constants
local FLOAT_SPEED = 1.5
local FLOAT_AMOUNT = 8
local SHIMMER_SPEED = 2

-- Constants for styling
local MENU_INDENT = 40
local DOT_OFFSET = -20

function SeedInput.new()
    local self = setmetatable({}, SeedInput)
    self:init() -- Call init after creation
    return self
end

function SeedInput:init()
    Scene.init(self)
    self.options = {
        "Random Seed",
        "Enter Custom Seed"
    }
    self.selected = 1
    self.inputtingSeed = false
    self.seedInput = ""
    
    -- Initialize animation variables
    self.titleOffset = 0
    self.titleAlpha = 1
    self.optionOffsets = {}
    for i = 1, #self.options do
        self.optionOffsets[i] = 0
    end
    
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
    -- Update title animations
    self.titleOffset = math.sin(love.timer.getTime() * FLOAT_SPEED) * FLOAT_AMOUNT
    self.titleAlpha = 1 - math.abs(math.sin(love.timer.getTime() * SHIMMER_SPEED) * 0.2)

    -- Animate selected option
    for i = 1, #self.options do
        if i == self.selected then
            self.optionOffsets[i] = math.sin(love.timer.getTime() * 2) * 3
        else
            self.optionOffsets[i] = 0
        end
    end

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
    -- Draw background
    love.graphics.setColor(COLORS.BACKGROUND)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw title with floating animation and shimmer
    love.graphics.setFont(FONTS.TITLE)
    love.graphics.setColor(COLORS.TITLE[1], COLORS.TITLE[2], COLORS.TITLE[3], self.titleAlpha)
    love.graphics.printf("Choose Seed Type", 0, 100 + self.titleOffset, love.graphics.getWidth(), 'center')

    if self.inputtingSeed then
        -- Draw seed input interface
        love.graphics.setFont(FONTS.MENU)
        love.graphics.setColor(COLORS.TEXT)
        love.graphics.printf("Enter Seed:", 0, 200, love.graphics.getWidth(), 'center')
        love.graphics.printf(self.seedInput .. "_", 0, 250, love.graphics.getWidth(), 'center')
    else
        -- Draw menu options
        love.graphics.setFont(FONTS.MENU)
        for i, option in ipairs(self.options) do
            local y = 200 + i * 40 + self.optionOffsets[i]
            
            -- Draw selection indicator to the left
            if i == self.selected then
                love.graphics.setColor(COLORS.SELECTED)
                love.graphics.printf("•", DOT_OFFSET, y, love.graphics.getWidth(), 'center')
            end

            love.graphics.setColor(i == self.selected and COLORS.SELECTED or COLORS.UNSELECTED)
            love.graphics.printf(option, 0, y, love.graphics.getWidth(), 'center')
        end
    end

    -- Draw instructions
    love.graphics.setFont(FONTS.INSTRUCTIONS)
    love.graphics.setColor(COLORS.TEXT[1], COLORS.TEXT[2], COLORS.TEXT[3], 0.7)
    love.graphics.printf(
        "Use Up/Down to select, Enter to confirm, Escape to return",
        0,
        love.graphics.getHeight() - 50,
        love.graphics.getWidth(),
        'center'
    )
end

return SeedInput





