local TestRunner = require('tests.init')
local DeckFactory = require('src.cards.deckFactory')
local CardConstants = require('src.cards.cardConstants')

TestRunner:addTest("DeckFactory - Empty deck for nil chef", function(t)
    local deck = DeckFactory.createStarterDeck(nil)
    t:assertEquals(#deck.cards, 0, "Should create empty deck when no chef provided")
end)

TestRunner:addTest("DeckFactory - Common cards for any chef", function(t)
    local chef = { name = "Chef Antonio" }
    local deck = DeckFactory.createStarterDeck(chef)

    -- Should have 15 common cards (from commonCards table)
    local commonCardCount = 0
    for _, card in ipairs(deck.cards) do
        if card.id <= 15 then
            commonCardCount = commonCardCount + 1
        end
    end
    t:assertEquals(commonCardCount, 15, "Should have 15 common cards")
end)

TestRunner:addTest("DeckFactory - Chef specific cards", function(t)
    local chef = { name = "Chef Antonio" }
    local deck = DeckFactory.createStarterDeck(chef)

    -- Should have 7 chef-specific cards (3 advanced techniques + 4 quality ingredients)
    local chefCardCount = 0
    for _, card in ipairs(deck.cards) do
        if card.id >= 101 and card.id <= 107 then
            chefCardCount = chefCardCount + 1
        end
    end
    t:assertEquals(chefCardCount, 7, "Should have 7 chef-specific cards")
end)

TestRunner:addTest("DeckFactory - Card types and values", function(t)
    local chef = { name = "Chef Mei" }
    local deck = DeckFactory.createStarterDeck(chef)

    -- Test a specific technique card
    local wokHeiFound = false
    for _, card in ipairs(deck.cards) do
        if card.id == 201 then
            wokHeiFound = true
            t:assertEquals(card.name, "Wok Hei", "Card name should match")
            t:assertEquals(card.cardType, "technique", "Card type should be technique")
            t:assertEquals(card.scoring:getValue(), CardConstants.DEFAULT_VALUES.TECHNIQUE.ADVANCED, "Should have correct value")
            break
        end
    end
    t:assert(wokHeiFound, "Should find Wok Hei technique card")
end)

TestRunner:addTest("DeckFactory - Total deck size", function(t)
    local chef = { name = "Chef Sofia" }
    local deck = DeckFactory.createStarterDeck(chef)

    -- Should have 22 total cards (15 common + 7 chef-specific)
    t:assertEquals(#deck.cards, 22, "Should have correct total number of cards")
end)

return TestRunner



