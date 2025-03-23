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

    local pairs = CombinationSystem:identifyCombinations(ingredients)

    t:assertEquals(#pairs, 1, "Should find one pair combination")
    t:assertEquals(pairs[1].type, CombinationSystem.TYPES.INGREDIENT_PAIR, "Should be ingredient pair type")
    t:assertEquals(pairs[1].bonus, 0.2, "Should have 20% bonus")
    t:assertEquals(#pairs[1].cards, 2, "Should include both vegetable cards")
end)

TestRunner:addTest("CombinationSystem - Multiple Tag Groups", function(t)
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

    local pairs = CombinationSystem:identifyCombinations(ingredients)
    t:assertEquals(#pairs, 2, "Should find two pair combinations")
end)

TestRunner:addTest("CombinationSystem - Calculate Bonus Multiplier", function(t)
    local combinations = {
        {
            type = CombinationSystem.TYPES.INGREDIENT_PAIR,
            bonus = CombinationSystem.BONUS_VALUES.INGREDIENT_PAIR
        },
        {
            type = CombinationSystem.TYPES.INGREDIENT_PAIR,
            bonus = CombinationSystem.BONUS_VALUES.INGREDIENT_PAIR
        }
    }

    t:assertEquals(
        CombinationSystem:calculateBonusMultiplier(combinations),
        1.4,  -- Base 1.0 + (2 * 0.2) ingredient pair bonuses
        "Multiple ingredient pairs should stack bonuses"
    )

    t:assertEquals(
        CombinationSystem:calculateBonusMultiplier({}),
        1.0,
        "Empty combinations should return base multiplier"
    )
end)

return TestRunner



