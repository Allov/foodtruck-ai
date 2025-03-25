local Scene = require('src.scenes.scene')
local MenuStyle = require('src.ui.menuStyle')
local MouseHelper = require('src.ui.mouseHelper')

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
        "Exit"
    }
    self.selected = 1

    -- Initialize animation variables
    self.titleOffset = 0
    self.titleAlpha = 1

    -- Initialize mouse handling
    self.clickables = MouseHelper.newClickableCollection()
    self:setupClickables()
end

function MainMenu:onHover(index, isHovered)
    if isHovered then
        self.selected = index
    end
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

function MainMenu:setupClickables()
    self.clickables:clear()

    local font = MenuStyle.FONTS.MENU
    local padding = 20
    local verticalPadding = 10
    local verticalOffset = -15

    for i, option in ipairs(self.options) do
        local textWidth = font:getWidth(option)
        local textHeight = font:getHeight()
        local width = textWidth + padding * 2
        local height = textHeight + verticalPadding * 2

        local baseY = MenuStyle.LAYOUT.MENU_START_Y + (i - 1) * MenuStyle.LAYOUT.MENU_ITEM_HEIGHT
        local textY = baseY + (MenuStyle.LAYOUT.MENU_ITEM_HEIGHT - textHeight) / 2 + verticalOffset
        local y = textY - verticalPadding
        local x = (love.graphics.getWidth() - textWidth) / 2 - padding

        self.clickables:add(MouseHelper.newClickable(
            x, y, width, height,
            function(isHovered) self:onHover(i, isHovered) end,
            function() self:onClick(i) end
        ))
    end
end

function MainMenu:update(dt)
    -- Update animations
    self.titleOffset = math.sin(love.timer.getTime() * FLOAT_SPEED) * FLOAT_AMOUNT
    self.titleAlpha = 1 - math.abs(math.sin(love.timer.getTime() * SHIMMER_SPEED) * 0.2)

    -- Update mouse interaction
    local mx, my = love.mouse.getPosition()
    self.clickables:update(mx, my)

    -- Handle keyboard
    if love.keyboard.wasPressed('up') then
        self.selected = self.selected - 1
        if self.selected < 1 then self.selected = #self.options end
    end
    if love.keyboard.wasPressed('down') then
        self.selected = self.selected + 1
        if self.selected > #self.options then self.selected = 1 end
    end
    if love.keyboard.wasPressed('return') then
        self:selectCurrentOption()
    end
end

function MainMenu:mousepressed(x, y, button)
    if button == 1 then  -- Left click only
        self.clickables:click(x, y, button)
    end
end

function MainMenu:selectCurrentOption()
    if self.selected == 1 then
        sceneManager:switch('seedInput')
    elseif self.selected == 2 then
        sceneManager:switch('optionsMenu')
    elseif self.selected == 3 then
        love.event.quit()
    end
end

function MainMenu:draw()
    MenuStyle.drawBackground()

    -- Draw title
    love.graphics.setFont(MenuStyle.FONTS.TITLE)
    love.graphics.setColor(MenuStyle.COLORS.TITLE[1], MenuStyle.COLORS.TITLE[2],
        MenuStyle.COLORS.TITLE[3], self.titleAlpha)
    love.graphics.printf(GAME_TITLE, 0, MenuStyle.LAYOUT.TITLE_Y + self.titleOffset,
        love.graphics.getWidth(), 'center')

    -- Draw menu options
    for i, option in ipairs(self.options) do
        MenuStyle.drawMenuItem(option, i, i == self.selected, false)
    end

    -- Debug visualization
    self.clickables:debugDraw()

    -- Draw instructions
    MenuStyle.drawInstructions("Use ↑↓ or mouse to select, Enter or click to confirm")
end

return MainMenu








