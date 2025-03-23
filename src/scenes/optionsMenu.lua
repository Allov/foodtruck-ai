local Scene = require('src.scenes.scene')
local Settings = require('src.settings')
local MenuStyle = require('src.ui.menuStyle')

local OptionsMenu = {}
OptionsMenu.__index = OptionsMenu
setmetatable(OptionsMenu, Scene)

-- Title animation constants
local FLOAT_SPEED = 1.5
local FLOAT_AMOUNT = 8
local SHIMMER_SPEED = 2

function OptionsMenu.new()
    local self = setmetatable({}, OptionsMenu)
    self:init()
    return self
end

function OptionsMenu:init()
    self.options = {
        {
            name = "CRT Effect",
            value = Settings.crtEnabled,
            toggle = function()
                Settings.crtEnabled = not Settings.crtEnabled
                Settings:save()
            end
        },
        {
            name = "Back",
            action = function()
                sceneManager:switch('mainMenu')
            end
        }
    }
    self.selected = 1
    
    -- Initialize animation variables
    self.titleOffset = 0
    self.titleAlpha = 1
end

function OptionsMenu:update(dt)
    -- Update title animations
    self.titleOffset = math.sin(love.timer.getTime() * FLOAT_SPEED) * FLOAT_AMOUNT
    self.titleAlpha = 1 - math.abs(math.sin(love.timer.getTime() * SHIMMER_SPEED) * 0.2)

    if love.keyboard.wasPressed('up') then
        self.selected = self.selected - 1
        if self.selected < 1 then 
            self.selected = #self.options 
        end
    elseif love.keyboard.wasPressed('down') then
        self.selected = self.selected + 1
        if self.selected > #self.options then 
            self.selected = 1 
        end
    elseif love.keyboard.wasPressed('return') then
        local option = self.options[self.selected]
        if option.toggle then
            option.toggle()
            option.value = Settings.crtEnabled
        elseif option.action then
            option.action()
        end
    elseif love.keyboard.wasPressed('escape') then
        sceneManager:switch('mainMenu')
    end
end

function OptionsMenu:draw()
    MenuStyle.drawBackground()
    
    -- Draw animated title
    love.graphics.setFont(MenuStyle.FONTS.TITLE)
    love.graphics.setColor(MenuStyle.COLORS.TITLE[1], MenuStyle.COLORS.TITLE[2], 
        MenuStyle.COLORS.TITLE[3], self.titleAlpha)
    love.graphics.printf("Options", 0, MenuStyle.LAYOUT.TITLE_Y + self.titleOffset, 
        love.graphics.getWidth(), 'center')
    
    -- Draw menu options
    for i, option in ipairs(self.options) do
        local displayText = option.name
        if option.toggle then
            local status = option.value and "ON" or "OFF"
            displayText = string.format("%s: %s", option.name, status)
        end
        MenuStyle.drawMenuItem(displayText, i, i == self.selected, false)
    end

    -- Draw instructions
    MenuStyle.drawInstructions("Use ↑↓ to select, Enter to confirm, Esc to return")
end

return OptionsMenu

