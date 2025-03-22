local Deck = {}
Deck.__index = Deck

function Deck.new()
    local self = setmetatable({}, Deck)
    self.cards = {}  -- Initialize empty cards array
    return self
end

function Deck:addCard(card)
    table.insert(self.cards, card)
end

-- Other deck methods...

return Deck

