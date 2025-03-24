local TestRunner = require('tests.init')
local DeckManager = require('src.cards.deckManager')
local Card = require('src.cards.card')

TestRunner:addTest("DeckManager - Shuffle changes card order", function(t)
    -- Create a test deck with numbered cards
    local deck = {
        drawPile = {},
        discardPile = {}
    }
    
    -- Add 10 numbered cards
    for i = 1, 10 do
        table.insert(deck.drawPile, Card.new(i, "Card " .. i, "Test card " .. i))
    end
    
    -- Store original order
    local originalOrder = {}
    for i, card in ipairs(deck.drawPile) do
        originalOrder[i] = card.id
    end
    
    -- Shuffle multiple times to ensure order changes
    local orderChanged = false
    for _ = 1, 5 do
        DeckManager.shuffleDrawPile(deck)
        
        -- Check if order is different
        local allSame = true
        for i, card in ipairs(deck.drawPile) do
            if card.id ~= originalOrder[i] then
                allSame = false
                break
            end
        end
        
        if not allSame then
            orderChanged = true
            break
        end
    end
    
    t:assert(orderChanged, "Shuffle should change card order")
    t:assertEquals(#deck.drawPile, 10, "Should maintain same number of cards")
end)

TestRunner:addTest("DeckManager - Reset and shuffle combines piles", function(t)
    local deck = {
        drawPile = {},
        discardPile = {}
    }
    
    -- Add some cards to both piles
    for i = 1, 5 do
        table.insert(deck.drawPile, Card.new(i, "Draw Card " .. i, "Test card"))
    end
    for i = 6, 10 do
        table.insert(deck.discardPile, Card.new(i, "Discard Card " .. i, "Test card"))
    end
    
    DeckManager.resetAndShuffle(deck)
    
    t:assertEquals(#deck.drawPile, 10, "All cards should be in draw pile")
    t:assertEquals(#deck.discardPile, 0, "Discard pile should be empty")
end)

TestRunner:addTest("DeckManager - Cards maintain unique IDs after shuffle", function(t)
    local deck = {
        drawPile = {},
        discardPile = {}
    }
    
    -- Add cards with unique IDs
    local originalIds = {}
    for i = 1, 10 do
        local card = Card.new(i, "Card " .. i, "Test card")
        table.insert(deck.drawPile, card)
        originalIds[i] = true
    end
    
    DeckManager.shuffleDrawPile(deck)
    
    -- Verify all IDs still exist exactly once
    local foundIds = {}
    for _, card in ipairs(deck.drawPile) do
        t:assert(not foundIds[card.id], "Each card ID should appear only once")
        t:assert(originalIds[card.id], "All card IDs should be from original set")
        foundIds[card.id] = true
    end
    
    t:assertEquals(#deck.drawPile, 10, "Should maintain same number of cards")
end)

return TestRunner