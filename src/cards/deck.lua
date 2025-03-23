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
    -- If draw pile is empty, reshuffle discard pile
    if #self.drawPile == 0 then
        print("[Deck:draw] Draw pile empty, reshuffling", #self.discardPile, "cards")
        -- Shuffle discard pile back into draw pile
        for _, card in ipairs(self.discardPile) do
            -- Reset card states before adding back to draw pile
            card:setLocked(false)
            card:setSelected(false)
            table.insert(self.drawPile, card)
        end
        self.discardPile = {}
        
        -- Shuffle the draw pile
        for i = #self.drawPile, 2, -1 do
            local j = math.random(i)
            self.drawPile[i], self.drawPile[j] = self.drawPile[j], self.drawPile[i]
        end
    end
    
    -- Draw and return top card
    local card = table.remove(self.drawPile)
    if card then
        -- Reset card states when drawing
        card:setLocked(false)
        card:setSelected(false)
    end
    print("[Deck:draw] Drawing card", card and card.name, "Cards left:", #self.drawPile)
    return card
end

function Deck:discard(card)
    if not card then
        print("[Deck:discard] Warning: Attempting to discard nil card")
        return
    end
    print("[Deck:discard] Discarding card", card.name, "Current discard pile:", #self.discardPile)
    table.insert(self.discardPile, card)
end

return Deck






