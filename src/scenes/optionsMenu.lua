local BaseMenu = require('src.scenes.baseMenu')
local Settings = require('src.settings')
local MenuStyle = require('src.ui.menuStyle')

local OptionsMenu = {}
OptionsMenu.__index = OptionsMenu
setmetatable(OptionsMenu, BaseMenu)

function OptionsMenu.new()
    local self = BaseMenu.new()
    setmetatable(self, OptionsMenu)
    self:init()
    return self
end

function OptionsMenu:init()
    BaseMenu.init(self)
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
    self:setupClickables()
end

function OptionsMenu:getOptionText(option)
    if option.toggle then
        local status = option.value and "ON" or "OFF"
        return string.format("%s: %s", option.name, status)
    end
    return option.name
end

function OptionsMenu:onClick(index)
    local option = self.options[index]
    if option.toggle then
        option.toggle()
        option.value = Settings.crtEnabled
        self:setupClickables()  -- Refresh clickables to update toggle text
    elseif option.action then
        option.action()
    end
end

function OptionsMenu:draw()
    BaseMenu.draw(self)
    self:drawTitle("Options")
    MenuStyle.drawInstructions("Use ↑↓ or mouse to select, Enter or click to confirm, Esc to go back")
end

return OptionsMenu



