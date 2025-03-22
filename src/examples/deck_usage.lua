local Card = require('src.cards.card')
local Deck = require('src.cards.deck')

-- Create a deck
local deck = Deck.new()

-- Add some cards
deck:addCard(Card.new(1, "Test Card 1", "This is a test card"))
deck:addCard(Card.new(2, "Test Card 2", "This is another test card"))

-- Shuffle the deck
deck:shuffle()

-- Draw a card
local drawnCard = deck:draw()
if drawnCard then
    print(drawnCard.name)
    deck:discard(drawnCard)
end

-- Check card counts
local counts = deck:getCounts()
print(string.format("Total: %d, Draw: %d, Discard: %d", 
    counts.total, counts.draw, counts.discard))