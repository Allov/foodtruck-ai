local Deck = {}
Deck.__index = Deck

function Deck.new()
    local self = setmetatable({}, Deck)
    self.cards = {}        -- All cards in the deck
    self.drawPile = {}     -- Cards available to draw
    self.discardPile = {}  -- Cards that have been used/discarded
    return self
end

-- Add a card to the deck
function Deck:addCard(card)
    table.insert(self.cards, card)
    table.insert(self.drawPile, card)
end

-- Shuffle the draw pile
function Deck:shuffle()
    local randomized = {}
    while #self.drawPile > 0 do
        local randomIndex = love.math.random(#self.drawPile)
        table.insert(randomized, self.drawPile[randomIndex])
        table.remove(self.drawPile, randomIndex)
    end
    self.drawPile = randomized
end

-- Draw a card from the deck
function Deck:draw()
    if #self.drawPile == 0 then
        -- If draw pile is empty, shuffle discard pile into draw pile
        self.drawPile = self.discardPile
        self.discardPile = {}
        self:shuffle()
    end
    
    if #self.drawPile > 0 then
        return table.remove(self.drawPile)
    end
    return nil
end

-- Discard a card
function Deck:discard(card)
    table.insert(self.discardPile, card)
end

-- Get counts of cards in different piles
function Deck:getCounts()
    return {
        total = #self.cards,
        draw = #self.drawPile,
        discard = #self.discardPile
    }
end

return Deck