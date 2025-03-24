local TestRunner = require('tests.init')
local BattleEncounter = require('src.scenes.battleEncounter')
local CombinationSystem = require('src.cards.combinationSystem')
local Chef = require('src.entities.chef')
local TestHelpers = require('tests.helpers')
-- First, we need to require the encounter configs
local encounterConfigs = require("src.encounters.encounterConfigs")

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

    -- Apply individual card scores first
    for _, card in ipairs(battle.state.selectedCards) do
        battle:applyCardScore(card)
    end

    battle:scoreCards()
    t:assertEquals(battle.state.roundScore, 42, "Should apply 40% bonus for matching vegetables twice")
end)

TestRunner:addTest("BattleEncounter - No Combinations", function(t)
    local battle = BattleEncounter.new()

    -- Reset running totals
    battle.state.runningTotals = {
        ingredients = 0,
        techniques = 0,
        recipes = 0
    }

    battle.state.selectedCards = {
        TestHelpers.createTestCard("Tomato", "ingredient", {
            tags = {"vegetable"},
            scoreValue = 10
        }),
        TestHelpers.createTestCard("Milk", "ingredient", {
            tags = {"dairy"},
            scoreValue = 10
        })
    }

    -- Apply individual card scores first
    for _, card in ipairs(battle.state.selectedCards) do
        battle:applyCardScore(card)
    end

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

    -- Apply individual card scores first
    for _, card in ipairs(battle.state.selectedCards) do
        battle:applyCardScore(card)
    end

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

    -- Apply individual card scores first
    for _, card in ipairs(battle.state.selectedCards) do
        battle:applyCardScore(card)
    end

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

    -- Apply individual card scores first
    for _, card in ipairs(battle.state.selectedCards) do
        battle:applyCardScore(card)
    end

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

    -- Apply individual card scores first
    for _, card in ipairs(battle.state.selectedCards) do
        battle:applyCardScore(card)
    end

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

    -- Apply individual card scores first
    for _, card in ipairs(battle.state.selectedCards) do
        battle:applyCardScore(card)
    end

    battle:scoreCards()
    -- (20 * 2.5) * 1.2 = 60
    t:assertEquals(battle.state.roundScore, 60, "Should apply combinations after multipliers")
end)

TestRunner:addTest("BattleEncounter - Complex Score Calculation", function(t)
    local battle = BattleEncounter.new()

    battle.state.selectedCards = {
        -- Ingredients (10 + 15 = 25 base)
        TestHelpers.createTestCard("Tomato", "ingredient", {
            tags = {"vegetable"},
            scoreValue = 10
        }),
        TestHelpers.createTestCard("Premium Mushroom", "ingredient", {
            tags = {"vegetable"},
            scoreValue = 15
        }),
        -- Techniques (1.0 + 1.5 + 2.0 = 4.5 multiplier)
        TestHelpers.createTestCard("Slice", "technique", {
            scoreValue = 1.5
        }),
        TestHelpers.createTestCard("Grill", "technique", {
            scoreValue = 2.0
        }),
        -- Recipe (1.0 + 1.5 = 2.5 multiplier)
        TestHelpers.createTestCard("Special Dish", "recipe", {
            scoreValue = 1.5
        })
    }

    -- Apply individual card scores first
    for _, card in ipairs(battle.state.selectedCards) do
        battle:applyCardScore(card)
    end

    battle:scoreCards()
    t:assertEquals(battle.state.roundScore, 337.5, "Should correctly apply single pair bonus with high technique multiplier")
end)

TestRunner:addTest("BattleEncounter - Four Ingredients With Single Pair And High Technique", function(t)
    local battle = BattleEncounter.new()

    battle.state.selectedCards = {
        -- Paired ingredients (vegetables)
        TestHelpers.createTestCard("Carrot", "ingredient", {
            tags = {"vegetable", "root"},
            scoreValue = 10
        }),
        TestHelpers.createTestCard("Celery", "ingredient", {
            tags = {"vegetable", "aromatic"},
            scoreValue = 10
        }),
        -- Non-paired ingredients
        TestHelpers.createTestCard("Chicken", "ingredient", {
            tags = {"protein", "meat"},
            scoreValue = 15
        }),
        TestHelpers.createTestCard("Milk", "ingredient", {
            tags = {"dairy", "liquid"},
            scoreValue = 5
        }),
        -- High-value technique
        TestHelpers.createTestCard("Master Chef Special", "technique", {
            scoreValue = 4.0
        })
    }

    -- Apply individual card scores first
    for _, card in ipairs(battle.state.selectedCards) do
        battle:applyCardScore(card)
    end

    battle:scoreCards()
    t:assertEquals(battle.state.roundScore, 240, "Should correctly apply single pair bonus with high technique multiplier")
end)

TestRunner:addTest("BattleEncounter - Basic Reward Calculation", function(t)
    local battle = BattleEncounter.new("food_critic")
    battle.config = encounterConfigs.food_critic

    -- Test C rating (exactly meeting target)
    battle.state.totalScore = battle.config.targetScore
    local reward = battle:calculateReward()
    t:assertEquals(reward, 8, "Should receive base (5) + C rating bonus (3)")
end)

TestRunner:addTest("BattleEncounter - Rating Based Rewards", function(t)
    local battle = BattleEncounter.new("food_critic")
    battle.config = encounterConfigs.food_critic

    local testCases = {
        { score = battle.config.targetScore * 2.0, expected = 15, rating = "S" },    -- base(5) + S(10)
        { score = battle.config.targetScore * 1.5, expected = 12, rating = "A" },    -- base(5) + A(7)
        { score = battle.config.targetScore * 1.2, expected = 10, rating = "B" },    -- base(5) + B(5)
        { score = battle.config.targetScore * 1.0, expected = 8,  rating = "C" },    -- base(5) + C(3)
        { score = battle.config.targetScore * 0.7, expected = 6,  rating = "D" },    -- base(5) + D(1)
        { score = battle.config.targetScore * 0.4, expected = 0,  rating = "F" }     -- No reward
    }

    for _, case in ipairs(testCases) do
        battle.state.totalScore = case.score
        local reward = battle:calculateReward()
        t:assertEquals(reward, case.expected,
            string.format("%s rating (%.1f%% of target) should give %d reward",
                case.rating, (case.score/battle.config.targetScore)*100, case.expected))
    end
end)

TestRunner:addTest("BattleEncounter - Rush Hour Reward Scaling", function(t)
    local battle = BattleEncounter.new("rush_hour")
    battle.config = encounterConfigs.rush_hour

    -- Test C rating (exactly meeting target)
    battle.state.targetScore = battle.config.targetScore
    battle.state.totalScore = battle.config.targetScore
    local reward = battle:calculateReward()
    t:assertEquals(reward, 9, "Rush hour should give base (7) + C rating bonus (2)")
end)

TestRunner:addTest("BattleEncounter - No Reward on Loss", function(t)
    local battle = BattleEncounter.new("food_critic")
    battle.config = encounterConfigs.food_critic

    -- Set up losing condition (F rating)
    battle.state.totalScore = battle.config.targetScore * 0.4
    local reward = battle:calculateReward()
    t:assertEquals(reward, 0, "Should receive no reward for F rating")
end)

return TestRunner


















