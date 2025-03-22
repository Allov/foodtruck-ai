-- Base card class
local Card = {}
Card.__index = Card

function Card.new(id, name, description)
    local self = setmetatable({}, Card)
    self.id = id                -- Unique identifier
    self.name = name            -- Card name
    self.description = description  -- Card description
    self.cardType = "base"      -- Base type, to be overridden by specific cards
    return self
end

return Card