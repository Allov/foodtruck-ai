local Deck = {}
Deck.__index = Deck

function Deck.new()
    local self = setmetatable({}, Deck)
    self.cards = {}      -- All cards in deck
    self.drawPile = {}   -- Cards available to draw
    self.discardPile = {} -- Cards that have been used
    return self
end

function Deck:addCard(card)
    table.insert(self.cards, card)
    table.insert(self.drawPile, card)
end

function Deck:draw()
    if #self.drawPile == 0 then
        -- Shuffle discard pile back into draw pile
        for _, card in ipairs(self.discardPile) do
            table.insert(self.drawPile, card)
        end
        self.discardPile = {}
        -- Shuffle the draw pile
        for i = #self.drawPile, 2, -1 do
            local j = math.random(i)
            self.drawPile[i], self.drawPile[j] = self.drawPile[j], self.drawPile[i]
        end
    end
    return table.remove(self.drawPile)
end

function Deck:discard(card)
    table.insert(self.discardPile, card)
end

return Deck


