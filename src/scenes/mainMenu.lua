local Scene = require('src.scenes.scene')
local MainMenu = {}
MainMenu.__index = MainMenu
setmetatable(MainMenu, Scene)

-- Constants for styling
local COLORS = {
    TITLE = {1, 0.8, 0, 1},      -- Gold for title
    TEXT = {1, 1, 1, 1},         -- White for regular text
    SELECTED = {1, 0.8, 0, 1},   -- Gold for selected item
    UNSELECTED = {0.7, 0.7, 0.7, 1}, -- Slightly dimmed for unselected
    DEBUG = {0.5, 0.5, 0.5, 1},  -- Dimmed for debug option
    BACKGROUND = {0.1, 0.1, 0.2, 1}, -- Dark blue background
    VERSION = {0.6, 0.6, 0.6, 0.8}  -- New: Subtle gray for version info
}

local FONTS = {
    TITLE = love.graphics.newFont(48),
    MENU = love.graphics.newFont(24),
    INSTRUCTIONS = love.graphics.newFont(16),
    VERSION = love.graphics.newFont(12)  -- New: Small font for version info
}

-- Title animation constants
local FLOAT_SPEED = 1.5
local FLOAT_AMOUNT = 8
local SHIMMER_SPEED = 2

-- Constants for styling
local MENU_INDENT = 40  -- Space for selection indicator
local DOT_OFFSET = -20  -- Position of dot relative to text

function MainMenu.new()
    local self = Scene.new()
    setmetatable(self, MainMenu)
    self:init()
    return self
end

function MainMenu:init()
    Scene.init(self)
    self.options = {
        "Start Food Truck Journey",
        "Options",
        "Debug Menu",
        "Exit"
    }
    self.selected = 1
    
    -- Initialize animation variables
    self.titleOffset = 0
    self.titleAlpha = 1
    self.optionOffsets = {}
    for i = 1, #self.options do
        self.optionOffsets[i] = 0
    end
    -- Remove shader initialization since it's now global
end

function MainMenu:update(dt)
    if love.keyboard.wasPressed('escape') then
        love.event.quit()
        return
    end

    -- Update title floating animation
    self.titleOffset = math.sin(love.timer.getTime() * FLOAT_SPEED) * FLOAT_AMOUNT
    -- Update title shimmer
    self.titleAlpha = 1 - math.abs(math.sin(love.timer.getTime() * SHIMMER_SPEED) * 0.2)

    -- Animate selected option with reduced speed and amplitude
    for i = 1, #self.options do
        if i == self.selected then
            self.optionOffsets[i] = math.sin(love.timer.getTime() * 2) * 3  -- Reduced from 5 * 10 to 2 * 3
        else
            self.optionOffsets[i] = 0
        end
    end

    if love.keyboard.wasPressed('up') then
        self.selected = self.selected - 1
        if self.selected < 1 then self.selected = #self.options end
    end
    if love.keyboard.wasPressed('down') then
        self.selected = self.selected + 1
        if self.selected > #self.options then self.selected = 1 end
    end
    if love.keyboard.wasPressed('return') then
        if self.selected == 1 then
            sceneManager:switch('seedInput')
        elseif self.selected == 2 then
            sceneManager:switch('optionsMenu')
        elseif self.selected == 3 then
            sceneManager:switch('debugMenu')
        elseif self.selected == 4 then
            love.event.quit()
        end
    end
end

function MainMenu:draw()
    -- Draw background
    love.graphics.setColor(COLORS.BACKGROUND)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw title with floating animation and shimmer
    love.graphics.setFont(FONTS.TITLE)
    love.graphics.setColor(COLORS.TITLE[1], COLORS.TITLE[2], COLORS.TITLE[3], self.titleAlpha)
    love.graphics.printf(GAME_TITLE, 0, 100 + self.titleOffset, love.graphics.getWidth(), 'center')
    
    -- Draw menu options
    love.graphics.setFont(FONTS.MENU)
    for i, option in ipairs(self.options) do
        local y = 250 + (i - 1) * 50 + self.optionOffsets[i]
        
        -- Draw selection indicator to the left
        if i == self.selected then
            love.graphics.setColor(COLORS.SELECTED)
            love.graphics.printf("•", DOT_OFFSET, y, love.graphics.getWidth(), 'center')
        end

        -- Draw menu option text
        if i == 3 and not _DEBUG then -- Debug menu option
            love.graphics.setColor(COLORS.DEBUG)
        else
            love.graphics.setColor(i == self.selected and COLORS.SELECTED or COLORS.UNSELECTED)
        end
        love.graphics.printf(option, 0, y, love.graphics.getWidth(), 'center')
    end

    -- Draw instructions
    love.graphics.setFont(FONTS.INSTRUCTIONS)
    love.graphics.setColor(COLORS.TEXT[1], COLORS.TEXT[2], COLORS.TEXT[3], 0.7)
    love.graphics.printf(
        "Use ↑↓ to select, Enter to confirm",
        0,
        love.graphics.getHeight() - 100,
        love.graphics.getWidth(),
        'center'
    )

    -- Call base class draw to show prototype info
    Scene.draw(self)
end

return MainMenu







