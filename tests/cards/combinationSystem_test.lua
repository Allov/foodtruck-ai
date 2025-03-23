local TestRunner = require('tests.init')
local CombinationSystem = require('src.cards.combinationSystem')
local TestHelpers = require('tests.helpers')

TestRunner:addTest("CombinationSystem - findIngredientPairs Basic", function(t)
    local ingredients = {
        TestHelpers.createTestCard("Tomato", "ingredient", {
            tags = {"vegetable", "acidic"},
            scoreValue = 10
        }),
        TestHelpers.createTestCard("Carrot", "ingredient", {
            tags = {"vegetable", "root"},
            scoreValue = 10
        }),
        TestHelpers.createTestCard("Beef", "ingredient", {
            tags = {"protein", "meat"},
            scoreValue = 15
        })
    }

    local pairs = CombinationSystem.findIngredientPairs(ingredients)

    t:assertEquals(#pairs, 1, "Should find one pair combination")
    t:assertEquals(pairs[1].type, CombinationSystem.TYPES.INGREDIENT_PAIR, "Should be ingredient pair type")
    t:assertEquals(pairs[1].bonus, 0.2, "Should have 20% bonus")
    t:assertEquals(#pairs[1].cards, 2, "Should include both vegetable cards")
    t:assertEquals(pairs[1].tag, "vegetable", "Should match on vegetable tag")
end)

TestRunner:addTest("CombinationSystem - findIngredientPairs Multiple Tags", function(t)
    local ingredients = {
        TestHelpers.createTestCard("Beef", "ingredient", {
            tags = {"protein", "meat"},
            scoreValue = 15
        }),
        TestHelpers.createTestCard("Chicken", "ingredient", {
            tags = {"protein", "meat"},
            scoreValue = 12
        }),
        TestHelpers.createTestCard("Fish", "ingredient", {
            tags = {"protein", "seafood"},
            scoreValue = 13
        })
    }

    local pairs = CombinationSystem.findIngredientPairs(ingredients)

    t:assertEquals(#pairs, 2, "Should find two pair combinations")

    local proteinFound = false
    local meatFound = false

    for _, pair in ipairs(pairs) do
        if pair.tag == "protein" then
            proteinFound = true
            t:assertEquals(#pair.cards, 3, "Protein group should include all three cards")
        elseif pair.tag == "meat" then
            meatFound = true
            t:assertEquals(#pair.cards, 2, "Meat group should include two cards")
        end
    end

    t:assert(proteinFound, "Should find protein group")
    t:assert(meatFound, "Should find meat group")
end)

TestRunner:addTest("CombinationSystem - findIngredientPairs Edge Cases", function(t)
    -- Test empty input
    local emptyPairs = CombinationSystem.findIngredientPairs({})
    t:assertEquals(#emptyPairs, 0, "Empty input should return no pairs")

    -- Test single ingredient
    local singleIngredient = {
        TestHelpers.createTestCard("Tomato", "ingredient", {
            tags = {"vegetable"},
            scoreValue = 10
        })
    }
    local singlePairs = CombinationSystem.findIngredientPairs(singleIngredient)
    t:assertEquals(#singlePairs, 0, "Single ingredient should return no pairs")

    -- Test non-ingredient cards
    local nonIngredients = {
        TestHelpers.createTestCard("Chop", "technique", {
            tags = {"cut"},
            scoreValue = 1.5
        }),
        TestHelpers.createTestCard("Grill", "technique", {
            tags = {"heat"},
            scoreValue = 1.5
        })
    }
    local nonIngredientPairs = CombinationSystem.findIngredientPairs(nonIngredients)
    t:assertEquals(#nonIngredientPairs, 0, "Non-ingredients should return no pairs")
end)

return TestRunner


