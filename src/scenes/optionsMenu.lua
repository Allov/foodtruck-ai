local Scene = require('src.scenes.scene')
local Settings = require('src.settings')

local OptionsMenu = {}
OptionsMenu.__index = OptionsMenu
setmetatable(OptionsMenu, Scene)

local COLORS = {
    TEXT = {1, 1, 1, 1},
    SELECTED = {1, 0.8, 0, 1},
    TITLE = {0.4, 0.8, 1, 1}
}

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
end

function OptionsMenu:update(dt)
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
    love.graphics.setColor(COLORS.TITLE)
    love.graphics.printf("Options", 0, 100, love.graphics.getWidth(), 'center')
    
    for i, option in ipairs(self.options) do
        local y = 200 + (i - 1) * 40
        love.graphics.setColor(self.selected == i and COLORS.SELECTED or COLORS.TEXT)
        
        if option.toggle then
            local status = option.value and "ON" or "OFF"
            love.graphics.printf(
                string.format("%s: %s", option.name, status),
                0, y, love.graphics.getWidth(), 'center'
            )
        else
            love.graphics.printf(option.name, 0, y, love.graphics.getWidth(), 'center')
        end
    end
end

return OptionsMenu

