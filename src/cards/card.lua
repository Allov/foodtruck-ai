-- Base card class
local Card = {}
Card.__index = Card

-- Constants for card display
local CARD_WIDTH = 120
local CARD_HEIGHT = 180
local LIFT_AMOUNT = 30
local ANIMATION_SPEED = 8

function Card.new(id, name, description)
    local self = setmetatable({}, Card)
    self.id = id                -- Unique identifier
    self.name = name            -- Card name
    self.description = description  -- Card description
    self.cardType = "base"      -- Base type, to be overridden by specific cards
    
    -- Animation and state properties
    self.currentOffset = 0      -- Current vertical offset
    self.targetOffset = 0       -- Target vertical offset
    self.isSelected = false     -- Currently highlighted/selected
    self.isLocked = false       -- Locked in for use
    
    return self
end

function Card:update(dt)
    -- Update animation
    if self.currentOffset < self.targetOffset then
        self.currentOffset = math.min(self.currentOffset + ANIMATION_SPEED, self.targetOffset)
    elseif self.currentOffset > self.targetOffset then
        self.currentOffset = math.max(self.currentOffset - ANIMATION_SPEED, self.targetOffset)
    end
end

function Card:setSelected(selected)
    self.isSelected = selected
    self:updateTargetOffset()
end

function Card:setLocked(locked)
    self.isLocked = locked
    self:updateTargetOffset()
end

function Card:updateTargetOffset()
    if self.isLocked then
        self.targetOffset = LIFT_AMOUNT
    elseif self.isSelected then
        self.targetOffset = LIFT_AMOUNT / 2
    else
        self.targetOffset = 0
    end
end

function Card:draw(x, y)
    local actualY = y - self.currentOffset
    
    -- Draw card background
    if self.isLocked then
        love.graphics.setColor(0.3, 0.8, 0.3, 1)
    elseif self.isSelected then
        love.graphics.setColor(0.3, 0.3, 0.8, 1)
    else
        love.graphics.setColor(0.2, 0.2, 0.2, 1)
    end
    love.graphics.rectangle('fill', x, actualY, CARD_WIDTH, CARD_HEIGHT)
    
    -- Draw card border
    if self.isLocked then
        love.graphics.setColor(0, 1, 0, 1)
        love.graphics.setLineWidth(3)
    elseif self.isSelected then
        love.graphics.setColor(1, 1, 0, 1)
        love.graphics.setLineWidth(3)
    else
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        love.graphics.setLineWidth(1)
    end
    love.graphics.rectangle('line', x, actualY, CARD_WIDTH, CARD_HEIGHT)
    
    -- Draw card content
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(
        self.name,
        x + 5,
        actualY + 10,
        CARD_WIDTH - 10,
        'center'
    )
    
    love.graphics.printf(
        self.description,
        x + 5,
        actualY + CARD_HEIGHT - 60,
        CARD_WIDTH - 10,
        'center'
    )
end

-- Getter for card dimensions
function Card.getDimensions()
    return CARD_WIDTH, CARD_HEIGHT
end

-- Add this function to draw card backs
function Card:drawBack(x, y)
    -- Draw card background
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.rectangle('fill', x, y, CARD_WIDTH, CARD_HEIGHT)
    
    -- Draw card border
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.rectangle('line', x, y, CARD_WIDTH, CARD_HEIGHT)
    
    -- Draw card back pattern
    love.graphics.setColor(0.4, 0.4, 0.4, 1)
    -- Diamond pattern
    local centerX = x + CARD_WIDTH / 2
    local centerY = y + CARD_HEIGHT / 2
    local diamondWidth = CARD_WIDTH * 0.6
    local diamondHeight = CARD_HEIGHT * 0.6
    
    -- Draw outer diamond
    love.graphics.polygon('line', 
        centerX, centerY - diamondHeight/2,
        centerX + diamondWidth/2, centerY,
        centerX, centerY + diamondHeight/2,
        centerX - diamondWidth/2, centerY
    )
    
    -- Draw inner diamond
    local innerScale = 0.6
    love.graphics.polygon('line', 
        centerX, centerY - (diamondHeight/2 * innerScale),
        centerX + (diamondWidth/2 * innerScale), centerY,
        centerX, centerY + (diamondHeight/2 * innerScale),
        centerX - (diamondWidth/2 * innerScale), centerY
    )
end

return Card
