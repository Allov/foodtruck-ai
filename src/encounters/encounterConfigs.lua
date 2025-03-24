return {
    -- Battle encounters
    food_critic = {
        type = "card_battle",
        name = "Food Critic Challenge",
        description = "Impress a demanding food critic with your culinary skills.",
        rounds = 3,
        maxCards = 5,
        targetScore = 150,  -- Higher target score
        rewards = {
            base_money = 5,            -- Base money reward
            perfect_bonus = 3,         -- Additional money for perfect score
            above_target_multiplier = 0.05,  -- 5% of points above target as bonus money
            rating_bonus = {           -- Bonus based on final rating
                ["S"] = 10,
                ["A"] = 7,
                ["B"] = 5,
                ["C"] = 3,
                ["D"] = 1
            }
        }
    },
    rush_hour = {
        type = "card_battle",
        name = "Rush Hour Service",
        description = "Handle the pressure of a busy restaurant rush!",
        rounds = 5,
        maxCards = 5,
        targetScore = 100,  -- Lower target score
        rewards = {
            base_money = 7,            -- Base money reward
            perfect_bonus = 4,         -- Additional money for perfect score
            above_target_multiplier = 0.07,  -- 7% of points above target as bonus money
            rating_bonus = {           -- Bonus based on final rating
                ["S"] = 8,
                ["A"] = 6,
                ["B"] = 4,
                ["C"] = 2,
                ["D"] = 1
            }
        }
    },

    -- Market encounters
    farmers_market = {
        type = "market",
        name = "Farmers Market",
        description = "Fresh local ingredients at reasonable prices.",
        inventorySize = {min = 4, max = 6},
        cardPool = "farmers_market",
        bargainingEnabled = true
    },
    specialty_shop = {
        type = "market",
        name = "Specialty Food Shop",
        description = "Rare and exotic ingredients for distinguished chefs.",
        inventorySize = {min = 3, max = 5},
        cardPool = "specialty_shop",
        premiumCurrency = true
    },
    supply_store = {
        type = "market",
        name = "Restaurant Supply Store",
        description = "Professional grade equipment and bulk ingredients.",
        inventorySize = {min = 4, max = 8},
        cardPool = "supply_store",
        bulkDiscounts = true
    },

    -- Negative encounters
    equipment_malfunction = {
        type = "negative",
        name = "Equipment Malfunction",
        description = "One of your key pieces of equipment is acting up.",
        severity = 2,
        resolutionOptions = {"repair", "replace", "temporary_fix"}
    },
    ingredient_shortage = {
        type = "negative",
        name = "Ingredient Shortage",
        description = "Essential ingredients are hard to find.",
        severity = 1,
        resolutionOptions = {"alternative", "premium", "wait"}
    },

    -- Beneficial encounters
    food_festival = {
        type = "beneficial",
        name = "Food Festival",
        description = "Showcase your skills at a local food festival!",
        rewardTier = 2,
        duration = 3
    },
    master_workshop = {
        type = "beneficial",
        name = "Master Chef Workshop",
        description = "Learn new techniques from a visiting master chef.",
        rewardTier = 3,
        skillGain = true
    }
}
