local MenuStyle = {
    COLORS = {
        TITLE = {1, 0.8, 0, 1},      -- Gold for title
        TEXT = {1, 1, 1, 1},         -- White for regular text
        SELECTED = {1, 0.8, 0, 1},   -- Gold for selected item
        UNSELECTED = {0.7, 0.7, 0.7, 1}, -- Slightly dimmed for unselected
        DEBUG = {0.5, 0.5, 0.5, 1},  -- Dimmed for debug options
        BACKGROUND = {0.1, 0.1, 0.2, 1}, -- Dark blue background
        INSTRUCTIONS = {1, 1, 1, 0.7} -- Semi-transparent white for instructions
    },

    FONTS = {
        TITLE = love.graphics.newFont(48),
        MENU = love.graphics.newFont(24),
        INSTRUCTIONS = love.graphics.newFont(16)
    },

    LAYOUT = {
        TITLE_Y = 100,
        MENU_START_Y = 250,
        MENU_ITEM_HEIGHT = 50,
        SELECTION_OFFSET = -20,
        INSTRUCTIONS_BOTTOM_MARGIN = 50
    },

    -- Animation constants for dots
    DOT_ANIMATION = {
        SPEED = 3,              -- Faster speed for more energy
        AMOUNT = 8,             -- Bigger bounce height
        PHASE_OFFSET = math.pi / 2,  -- Quarter phase difference for more playful timing
        SQUASH = 0.3,          -- Amount of squash and stretch (0 to 1)
        SQUASH_OFFSET = math.pi / 2  -- Offset for squash timing
    }
}

function MenuStyle.drawTitle(text)
    love.graphics.setFont(MenuStyle.FONTS.TITLE)
    love.graphics.setColor(MenuStyle.COLORS.TITLE)
    love.graphics.printf(text, 0, MenuStyle.LAYOUT.TITLE_Y, love.graphics.getWidth(), 'center')
end

function MenuStyle.drawMenuItem(text, index, isSelected, isDisabled)
    local y = MenuStyle.LAYOUT.MENU_START_Y + (index - 1) * MenuStyle.LAYOUT.MENU_ITEM_HEIGHT
    
    -- Calculate text dimensions
    local font = MenuStyle.FONTS.MENU
    local textWidth = font:getWidth(text)
    local screenWidth = love.graphics.getWidth()
    local textX = (screenWidth - textWidth) / 2
    
    -- Draw menu item text
    love.graphics.setFont(font)
    if isDisabled then
        love.graphics.setColor(MenuStyle.COLORS.DEBUG)
    else
        love.graphics.setColor(isSelected and MenuStyle.COLORS.SELECTED or MenuStyle.COLORS.UNSELECTED)
    end
    love.graphics.print(text, textX, y)
    
    -- Draw selection indicators on both sides with bounce animation
    if isSelected then
        love.graphics.setColor(MenuStyle.COLORS.SELECTED)
        local time = love.timer.getTime() * MenuStyle.DOT_ANIMATION.SPEED
        
        -- Left dot animation
        local leftBounce = math.sin(time) * MenuStyle.DOT_ANIMATION.AMOUNT
        local leftSquash = 1 + math.sin(time + MenuStyle.DOT_ANIMATION.SQUASH_OFFSET) * MenuStyle.DOT_ANIMATION.SQUASH
        
        love.graphics.push()
        love.graphics.translate(textX - font:getWidth("• "), y + leftBounce)
        love.graphics.scale(1/leftSquash, leftSquash)  -- Squash vertically, stretch horizontally
        love.graphics.print("•", 0, 0)
        love.graphics.pop()
        
        -- Right dot animation
        local rightBounce = math.sin(time + MenuStyle.DOT_ANIMATION.PHASE_OFFSET) * MenuStyle.DOT_ANIMATION.AMOUNT
        local rightSquash = 1 + math.sin(time + MenuStyle.DOT_ANIMATION.SQUASH_OFFSET + MenuStyle.DOT_ANIMATION.PHASE_OFFSET) * MenuStyle.DOT_ANIMATION.SQUASH
        
        love.graphics.push()
        love.graphics.translate(textX + textWidth + font:getWidth(" "), y + rightBounce)
        love.graphics.scale(1/rightSquash, rightSquash)  -- Squash vertically, stretch horizontally
        love.graphics.print("•", 0, 0)
        love.graphics.pop()
    end
end

function MenuStyle.drawInstructions(text)
    love.graphics.setFont(MenuStyle.FONTS.INSTRUCTIONS)
    love.graphics.setColor(MenuStyle.COLORS.INSTRUCTIONS)
    love.graphics.printf(
        text,
        0,
        love.graphics.getHeight() - MenuStyle.LAYOUT.INSTRUCTIONS_BOTTOM_MARGIN,
        love.graphics.getWidth(),
        'center'
    )
end

function MenuStyle.drawBackground()
    love.graphics.setColor(MenuStyle.COLORS.BACKGROUND)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
end

return MenuStyle



