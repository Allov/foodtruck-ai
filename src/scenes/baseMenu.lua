local Scene = require('src.scenes.scene')
local MenuStyle = require('src.ui.menuStyle')
local MouseHelper = require('src.ui.mouseHelper')

local BaseMenu = {}
BaseMenu.__index = BaseMenu
setmetatable(BaseMenu, Scene)

-- Animation constants
BaseMenu.FLOAT_SPEED = 1.5
BaseMenu.FLOAT_AMOUNT = 8
BaseMenu.SHIMMER_SPEED = 2

function BaseMenu.new()
    local self = Scene.new()
    setmetatable(self, BaseMenu)
    self.options = {}  -- Initialize empty options table
    self:init()
    return self
end

function BaseMenu:init()
    Scene.init(self)
    self.selected = 1
    self.titleOffset = 0
    self.titleAlpha = 1
    self.clickables = MouseHelper.newClickableCollection()

    -- Add input handling properties
    self.inputting = false
    self.inputText = ""
    self.inputValidator = nil  -- Function to validate input characters
    self.onInputComplete = nil -- Function to handle input completion
    self.inputPrompt = ""      -- Text to show above input field
end

function BaseMenu:startInput(prompt, validator, onComplete)
    self.inputting = true
    self.inputText = ""
    self.inputPrompt = prompt or "Enter text:"
    self.inputValidator = validator
    self.onInputComplete = onComplete
end

function BaseMenu:stopInput()
    self.inputting = false
    self.inputText = ""
    self.inputValidator = nil
    self.onInputComplete = nil
end

function BaseMenu:handleTextInput(text)
    if not self.inputting then return end
    if self.inputValidator then
        if self.inputValidator(text) then
            self.inputText = self.inputText .. text
        end
    else
        self.inputText = self.inputText .. text
    end
end

-- Add a new method for child classes to call after setting options
function BaseMenu:initializeMenu()
    self:setupClickables()
end

function BaseMenu:onHover(index, isHovered)
    if isHovered then
        self.selected = index
    end
end

function BaseMenu:onClick(index)
    -- To be implemented by child classes
end

function BaseMenu:getOptionText(option)
    -- Can be overridden by child classes for custom text formatting
    return option.name or option
end

function BaseMenu:setupClickables()
    self.clickables:clear()

    local font = MenuStyle.FONTS.MENU
    local padding = 20
    local verticalPadding = 10
    local verticalOffset = -15

    for i, option in ipairs(self.options) do
        local displayText = self:getOptionText(option)
        local textWidth = font:getWidth(displayText)
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

function BaseMenu:mousepressed(x, y, button)
    if button == 1 then
        self.clickables:click(x, y, button)
    end
end

function BaseMenu:update(dt)
    -- Update animations
    self.titleOffset = math.sin(love.timer.getTime() * self.FLOAT_SPEED) * self.FLOAT_AMOUNT
    self.titleAlpha = 1 - math.abs(math.sin(love.timer.getTime() * self.SHIMMER_SPEED) * 0.2)

    if self.inputting then
        if love.keyboard.wasPressed('return') and #self.inputText > 0 then
            if self.onInputComplete then
                self.onInputComplete(self.inputText)
            end
        elseif love.keyboard.wasPressed('backspace') then
            self.inputText = self.inputText:sub(1, -2)
        elseif love.keyboard.wasPressed('escape') then
            self:stopInput()
        end
        return
    end

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
        self:onClick(self.selected)
    end
end

function BaseMenu:drawTitle(title)
    love.graphics.setFont(MenuStyle.FONTS.TITLE)
    love.graphics.setColor(MenuStyle.COLORS.TITLE[1], MenuStyle.COLORS.TITLE[2],
        MenuStyle.COLORS.TITLE[3], self.titleAlpha)
    love.graphics.printf(title, 0, MenuStyle.LAYOUT.TITLE_Y + self.titleOffset,
        love.graphics.getWidth(), 'center')
end

function BaseMenu:draw()
    MenuStyle.drawBackground()

    if self.inputting then
        -- Draw input interface
        love.graphics.setFont(MenuStyle.FONTS.MENU)
        love.graphics.setColor(MenuStyle.COLORS.TEXT)
        love.graphics.printf(self.inputPrompt, 0,
            MenuStyle.LAYOUT.MENU_START_Y,
            love.graphics.getWidth(), 'center')
        love.graphics.printf(self.inputText .. "_", 0,
            MenuStyle.LAYOUT.MENU_START_Y + MenuStyle.LAYOUT.MENU_ITEM_HEIGHT,
            love.graphics.getWidth(), 'center')
    else
        -- Draw menu options
        for i, option in ipairs(self.options) do
            local displayText = self:getOptionText(option)
            MenuStyle.drawMenuItem(displayText, i, i == self.selected, false)
        end
    end

    -- Debug visualization
    self.clickables:debugDraw()
end

function BaseMenu:textinput(t)
    if self.inputting then
        self:handleTextInput(t)
    end
end

return BaseMenu



