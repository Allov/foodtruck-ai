local TestRunner = require('tests.init')
local BattleEncounter = require('src.scenes.battleEncounter')
local CombinationSystem = require('src.cards.combinationSystem')
local Chef = require('src.entities.chef')
local TestHelpers = require('tests.helpers')

TestRunner:addTest("BattleEncounter - Basic initialization", function(t)
    local battle = BattleEncounter.new()
    t:assertEquals(battle.state.currentPhase, BattleEncounter.PHASES.PREPARATION, "Should start in preparation phase")
    t:assertEquals(battle.state.roundNumber, 1, "Should start at round 1")
    t:assertEquals(battle.state.currentScore, 0, "Should start with 0 score")
    t:assertEquals(#battle.state.selectedCards, 0, "Should start with no selected cards")
end)

TestRunner:addTest("BattleEncounter - Food Critic Configuration", function(t)
    local battle = BattleEncounter.new()
    battle.state.battleType = "food_critic"
    battle:setupBattleParameters()

    t:assertEquals(battle.state.maxRounds, 3, "Food critic should have 3 rounds")
    t:assertEquals(battle.state.targetScore, 150, "Food critic should have correct target score")
    t:assertEquals(battle.state.maxSelectedCards, 5, "Should allow up to 5 cards")
    t:assertEquals(battle.state.enemy.name, "Food Critic", "Should have correct enemy name")
end)

TestRunner:addTest("BattleEncounter - Rush Hour Configuration", function(t)
    local battle = BattleEncounter.new()
    battle.state.battleType = "rush_hour"
    battle:setupBattleParameters()

    t:assertEquals(battle.state.maxRounds, 5, "Rush hour should have 5 rounds")
    t:assertEquals(battle.state.targetScore, 100, "Rush hour should have correct target score")
    t:assertEquals(battle.state.maxSelectedCards, 5, "Should allow up to 5 cards")
    t:assertEquals(battle.state.enemy.name, "Lunch Rush", "Should have correct enemy name")
end)

TestRunner:addTest("BattleEncounter - Battle Completion Conditions", function(t)
    local battle = BattleEncounter.new()
    battle.state.maxRounds = 3
    battle.state.targetScore = 100
    battle.state.totalScore = 0  -- Initialize totalScore

    -- Should not be complete at start
    t:assert(not battle:isBattleComplete(), "Battle should not be complete at start")

    -- Should complete when reaching max rounds
    battle.state.roundNumber = 4
    t:assert(battle:isBattleComplete(), "Battle should complete after max rounds")

    -- Should complete when reaching target score
    battle.state.roundNumber = 2
    battle.state.totalScore = 100
    t:assert(battle:isBattleComplete(), "Battle should complete when reaching target score")
end)

TestRunner:addTest("BattleEncounter - Rating Updates", function(t)
    local battle = BattleEncounter.new()
    battle.state.targetScore = 100

    -- Create a real Chef instance instead of a mock
    local chef = Chef.new({
        name = "Test Chef",
        rating = "B"
    })

    -- Set up the game state
    gameState = { selectedChef = chef }

    -- Test rating decrease on low score
    battle:updateRating(80)
    t:assertEquals(chef.rating, "C", "Rating should decrease on low score")

    -- Test rating increase on perfect score
    chef.rating = "B"
    battle:updateRating(200)  -- Need 200 to meet perfect dish criteria (2x target)
    t:assertEquals(chef.rating, "A", "Rating should increase on perfect score")

    -- Test game over condition
    chef.rating = "F"
    local gameOverCalled = false
    battle.gameOver = function(self)
        gameOverCalled = true
    end
    battle:updateRating(50)
    t:assert(gameOverCalled, "Game over should be called when rating is F")
end)

TestRunner:addTest("BattleEncounter - Multiple Ingredient Pair Combination", function(t)
    local battle = BattleEncounter.new()
    battle.state.selectedCards = {
        TestHelpers.createTestCard("Tomato", "ingredient", {
            tags = {"vegetable", "acidic"},
            scoreValue = 10
        }),
        TestHelpers.createTestCard("Onion", "ingredient", {
            tags = {"vegetable", "aromatic"},
            scoreValue = 10
        }),
        TestHelpers.createTestCard("Garlic", "ingredient", {
            tags = {"vegetable", "aromatic"},
            scoreValue = 10
        })
    }

    battle:scoreCards()
    t:assertEquals(battle.state.roundScore, 42, "Should apply 40% bonus for matching vegetables twice")
end)

TestRunner:addTest("BattleEncounter - No Combinations", function(t)
    local battle = BattleEncounter.new()
    battle.state.selectedCards = {
        TestHelpers.createTestCard("Random1", "ingredient", {
            tags = {"unique1"},
            scoreValue = 10
        }),
        TestHelpers.createTestCard("Random2", "ingredient", {
            tags = {"unique2"},
            scoreValue = 10
        })
    }

    battle:scoreCards()
    t:assertEquals(battle.state.roundScore, 20, "Should not apply any bonus when no combinations exist")
end)

TestRunner:addTest("CombinationSystem - Calculate Bonus Multiplier", function(t)
    -- Test single combination type
    local singleIngredientPair = {
        {
            type = CombinationSystem.TYPES.INGREDIENT_PAIR,
            bonus = CombinationSystem.BONUS_VALUES.INGREDIENT_PAIR
        }
    }
    t:assertEquals(
        CombinationSystem:calculateBonusMultiplier(singleIngredientPair),
        1.2,  -- Base 1.0 + 0.2 ingredient pair bonus
        "Single ingredient pair should give 20% bonus"
    )

    -- Test multiple of same type
    local multipleIngredientPairs = {
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
        CombinationSystem:calculateBonusMultiplier(multipleIngredientPairs),
        1.4,  -- Base 1.0 + (2 * 0.2) ingredient pair bonuses
        "Multiple ingredient pairs should stack bonuses"
    )

    -- Test empty combinations
    t:assertEquals(
        CombinationSystem:calculateBonusMultiplier({}),
        1.0,
        "Empty combinations should return base multiplier"
    )
end)

TestRunner:addTest("BattleEncounter - Score Calculation Order", function(t)
    local battle = BattleEncounter.new()

    -- Test case with all card types
    battle.state.selectedCards = {
        -- Ingredients (10 + 10 = 20 base)
        TestHelpers.createTestCard("Tomato", "ingredient", {
            scoreValue = 10
        }),
        TestHelpers.createTestCard("Onion", "ingredient", {
            scoreValue = 10
        }),
        -- Techniques (1.0 + 1.5 + 2.0 = 4.5 multiplier)
        TestHelpers.createTestCard("Slice", "technique", {
            scoreValue = 1.5
        }),
        TestHelpers.createTestCard("Dice", "technique", {
            scoreValue = 2.0
        }),
        -- Recipe (1.0 + 1.5 = 2.5 multiplier)
        TestHelpers.createTestCard("Soup", "recipe", {
            scoreValue = 1.5
        })
    }

    battle:scoreCards()
    -- 20 (ingredients) * 4.5 (techniques) * 2.5 (recipe) = 225
    t:assertEquals(battle.state.roundScore, 225, "Should calculate score in correct order")
end)

TestRunner:addTest("BattleEncounter - Score with Only Ingredients", function(t)
    local battle = BattleEncounter.new()

    battle.state.selectedCards = {
        TestHelpers.createTestCard("Tomato", "ingredient", {
            scoreValue = 10
        }),
        TestHelpers.createTestCard("Onion", "ingredient", {
            scoreValue = 15
        })
    }

    battle:scoreCards()
    t:assertEquals(battle.state.roundScore, 25, "Should sum ingredients correctly")
end)

TestRunner:addTest("BattleEncounter - Score with Techniques Only", function(t)
    local battle = BattleEncounter.new()

    battle.state.selectedCards = {
        TestHelpers.createTestCard("Tomato", "ingredient", {
            scoreValue = 10
        }),
        TestHelpers.createTestCard("Slice", "technique", {
            scoreValue = 1.5
        }),
        TestHelpers.createTestCard("Dice", "technique", {
            scoreValue = 2.0
        })
    }

    battle:scoreCards()
    -- 10 * (1.0 + 1.5 + 2.0) = 45
    t:assertEquals(battle.state.roundScore, 45, "Should apply technique multipliers correctly")
end)

TestRunner:addTest("BattleEncounter - Score with Recipe Only", function(t)
    local battle = BattleEncounter.new()

    battle.state.selectedCards = {
        TestHelpers.createTestCard("Tomato", "ingredient", {
            scoreValue = 10
        }),
        TestHelpers.createTestCard("Soup", "recipe", {
            scoreValue = 1.5
        })
    }

    battle:scoreCards()
    -- 10 * (1.0 + 1.5) = 25
    t:assertEquals(battle.state.roundScore, 25, "Should apply recipe multiplier correctly")
end)

TestRunner:addTest("BattleEncounter - Score with Combinations", function(t)
    local battle = BattleEncounter.new()

    battle.state.selectedCards = {
        TestHelpers.createTestCard("Tomato", "ingredient", {
            tags = {"vegetable"},
            scoreValue = 10
        }),
        TestHelpers.createTestCard("Carrot", "ingredient", {
            tags = {"vegetable"},
            scoreValue = 10
        }),
        TestHelpers.createTestCard("Slice", "technique", {
            scoreValue = 1.5
        })
    }

    battle:scoreCards()
    -- (20 * 2.5) * 1.2 = 60
    t:assertEquals(battle.state.roundScore, 60, "Should apply combinations after multipliers")
end)

return TestRunner








