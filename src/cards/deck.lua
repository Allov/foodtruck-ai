local Deck = {}
Deck.__index = Deck

local DeckManager = require('src.cards.deckManager')

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
    local cards = DeckManager.drawCards(self, 1)
    return cards[1] -- Return single card or nil
end

function Deck:discard(card)
    DeckManager.discardCard(self, card)
end

function Deck:getCounts()
    return DeckManager.getCounts(self)
end

return Deck







