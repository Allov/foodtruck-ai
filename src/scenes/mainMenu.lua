local BaseMenu = require('src.scenes.baseMenu')
local MenuStyle = require('src.ui.menuStyle')

local MainMenu = {}
MainMenu.__index = MainMenu
setmetatable(MainMenu, BaseMenu)

function MainMenu.new()
    local self = BaseMenu.new()
    setmetatable(self, MainMenu)
    self:init()
    return self
end

function MainMenu:init()
    BaseMenu.init(self)
    self.options = {
        "Start Food Truck Journey",
        "Options",
        "Exit"
    }
    self:setupClickables()
end

function MainMenu:onClick(index)
    if index == 1 then
        sceneManager:switch('seedInput')
    elseif index == 2 then
        sceneManager:switch('optionsMenu')
    elseif index == 3 then
        love.event.quit()
    end
end

function MainMenu:draw()
    BaseMenu.draw(self)
    self:drawTitle("Food Truck Journey")
    MenuStyle.drawInstructions("Use ↑↓ or mouse to select, Enter or click to confirm")
end

return MainMenu




