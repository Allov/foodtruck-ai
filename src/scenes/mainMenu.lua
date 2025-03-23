local Scene = require('src.scenes.scene')
local MenuStyle = require('src.ui.menuStyle')

local MainMenu = {}
MainMenu.__index = MainMenu
setmetatable(MainMenu, Scene)

-- Title animation constants
local FLOAT_SPEED = 1.5
local FLOAT_AMOUNT = 8
local SHIMMER_SPEED = 2

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
    MenuStyle.drawBackground()
    
    -- Draw animated title
    love.graphics.setFont(MenuStyle.FONTS.TITLE)
    love.graphics.setColor(MenuStyle.COLORS.TITLE[1], MenuStyle.COLORS.TITLE[2], 
        MenuStyle.COLORS.TITLE[3], self.titleAlpha)
    love.graphics.printf(GAME_TITLE, 0, MenuStyle.LAYOUT.TITLE_Y + self.titleOffset, 
        love.graphics.getWidth(), 'center')
    
    -- Draw menu options
    for i, option in ipairs(self.options) do
        local isDisabled = (i == 3 and not _DEBUG)
        MenuStyle.drawMenuItem(option, i, i == self.selected, isDisabled)
    end

    -- Draw instructions
    MenuStyle.drawInstructions("Use ↑↓ to select, Enter to confirm")
end

return MainMenu
