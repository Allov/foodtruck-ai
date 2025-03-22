-- Base card class
local Card = {}
Card.__index = Card

-- Constants for card display
local CARD_WIDTH = 120
local CARD_HEIGHT = 180

function Card.new(id, name, description)
    local self = setmetatable({}, Card)
    self.id = id                -- Unique identifier
    self.name = name            -- Card name
    self.description = description  -- Card description
    self.cardType = "base"      -- Base type, to be overridden by specific cards
    return self
end

function Card:draw(x, y, isSelected)
    -- Draw card background
    if isSelected then
        love.graphics.setColor(0.3, 0.3, 0.3, 1)
    else
        love.graphics.setColor(0.2, 0.2, 0.2, 1)
    end
    love.graphics.rectangle('fill', x, y, CARD_WIDTH, CARD_HEIGHT)
    
    -- Draw card border
    if isSelected then
        love.graphics.setColor(1, 1, 0, 1)  -- Yellow border for selected
        love.graphics.setLineWidth(3)
    else
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        love.graphics.setLineWidth(1)
    end
    love.graphics.rectangle('line', x, y, CARD_WIDTH, CARD_HEIGHT)
    
    -- Draw card content
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(
        self.name,
        x + 5,
        y + 10,
        CARD_WIDTH - 10,
        'center'
    )
    
    love.graphics.printf(
        self.description,
        x + 5,
        y + CARD_HEIGHT - 60,
        CARD_WIDTH - 10,
        'center'
    )
end

-- Getter for card dimensions
function Card.getDimensions()
    return CARD_WIDTH, CARD_HEIGHT
end

return Card
