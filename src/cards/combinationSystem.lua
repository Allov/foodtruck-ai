local MenuStyle = require('src.ui.menuStyle')
local Card = require('src.cards.card')

local CombinationSystem = {
    -- Combination types and their associated bonus values
    TYPES = {
        INGREDIENT_PAIR = "INGREDIENT_PAIR",  -- Applied once per matching ingredient group
        TECHNIQUE_BOOST = "TECHNIQUE_BOOST",
        RECIPE_MATCH = "RECIPE_MATCH"
    },

    -- Bonus values for each combination type
    -- Ingredient pairs give a single 20% bonus regardless of group size
    BONUS_VALUES = {
        INGREDIENT_PAIR = 0.2,  -- 20% bonus per matching ingredient group
        TECHNIQUE_BOOST = 0.3,  -- 30% bonus per technique-ingredient match
        RECIPE_MATCH = 0.5      -- 50% bonus per completed recipe
    }
}

-- Style definitions matching our existing visual language
CombinationSystem.STYLE = {
    COLORS = {
        COMBO = {1, 0.8, 0, 1},      -- Gold color matching MenuStyle
        BONUS = {0.4, 0.8, 1, 1},    -- Bright blue for bonuses
        TEXT = MenuStyle.COLORS.TEXT  -- Reuse menu text color
    },
    FONTS = {
        COMBO = MenuStyle.FONTS.MENU,
        BONUS = MenuStyle.FONTS.INSTRUCTIONS
    },
    ANIMATION = {
        SPEED = 3,
        AMOUNT = 8,
        PHASE_OFFSET = math.pi / 2
    }
}

-- Create a new combination result
local function newCombination(type, cards, bonus)
    return {
        type = type,
        cards = cards,
        bonus = bonus,
        visualState = {
            animTime = 0,
            highlight = 0
        }
    }
end

-- Check for ingredient pairs (like vegetables, proteins, etc.)
local function findIngredientPairs(ingredients)
    local pairCombos = {}
    local tagCounts = {}
    local processedTags = {}

    -- Count ingredients by tag
    for _, ingredient in ipairs(ingredients) do
        if ingredient.cardType == "ingredient" then  -- Verify it's an ingredient
            for _, tag in ipairs(ingredient.tags or {}) do
                tagCounts[tag] = (tagCounts[tag] or 0) + 1
            end
        end
    end

    -- Find matching groups (only process each tag once)
    for tag, count in pairs(tagCounts) do
        if count >= 2 and not processedTags[tag] then
            processedTags[tag] = true

            -- Get all cards with this tag
            local matchingCards = {}
            for _, ingredient in ipairs(ingredients) do
                if ingredient.cardType == "ingredient" and ingredient.tags then
                    for _, cardTag in ipairs(ingredient.tags) do
                        if cardTag == tag then
                            table.insert(matchingCards, ingredient)
                            break
                        end
                    end
                end
            end

            -- Create single combination for the group
            table.insert(pairCombos, {
                type = CombinationSystem.TYPES.INGREDIENT_PAIR,
                cards = matchingCards,
                bonus = CombinationSystem.BONUS_VALUES.INGREDIENT_PAIR,
                tag = tag
            })
        end
    end

    return pairCombos
end

-- Add this to the CombinationSystem table
CombinationSystem.findIngredientPairs = findIngredientPairs

-- Check for technique boosts (technique cards that enhance specific ingredients)
local function findTechniqueBoosts(ingredients, techniques)
    local boosts = {}

    for _, technique in ipairs(techniques) do
        for _, ingredient in ipairs(ingredients) do
            -- Check if technique tags complement ingredient tags
            local isMatch = false
            for _, techTag in ipairs(technique.tags or {}) do
                for _, ingTag in ipairs(ingredient.tags or {}) do
                    if (techTag == "heat" and ingTag == "protein") or
                       (techTag == "slice" and ingTag == "vegetable") or
                       (techTag == "slow_cook" and ingTag == "tough_meat") then
                        isMatch = true
                        break
                    end
                end
                if isMatch then break end
            end

            if isMatch then
                table.insert(boosts, newCombination(
                    CombinationSystem.TYPES.TECHNIQUE_BOOST,
                    {technique, ingredient},
                    0.3  -- 30% bonus
                ))
            end
        end
    end

    return boosts
end

-- Check for recipe matches (when ingredients and techniques match a recipe)
local function findRecipeMatches(ingredients, techniques, recipes)
    local matches = {}

    for _, recipe in ipairs(recipes) do
        local requiredTags = recipe.tags or {}
        local matchCount = 0
        local matchingCards = {recipe}

        -- Check if we have matching ingredients and techniques
        for _, tag in ipairs(requiredTags) do
            for _, card in ipairs(ingredients) do
                if card.tags and table.concat(card.tags, ","):find(tag) then
                    matchCount = matchCount + 1
                    table.insert(matchingCards, card)
                    break
                end
            end
            for _, card in ipairs(techniques) do
                if card.tags and table.concat(card.tags, ","):find(tag) then
                    matchCount = matchCount + 1
                    table.insert(matchingCards, card)
                    break
                end
            end
        end

        -- If we found all required elements, it's a match
        if matchCount >= #requiredTags then
            table.insert(matches, newCombination(
                CombinationSystem.TYPES.RECIPE_MATCH,
                matchingCards,
                0.5  -- 50% bonus
            ))
        end
    end

    return matches
end

function CombinationSystem:identifyCombinations(cards)
    local combinations = {}

    -- Filter to only ingredient cards
    local ingredients = {}
    for _, card in ipairs(cards) do
        if card.cardType == "ingredient" then
            table.insert(ingredients, card)
        end
    end

    -- Find ingredient pairs
    local ingredientPairs = findIngredientPairs(ingredients)
    for _, combo in ipairs(ingredientPairs) do
        table.insert(combinations, combo)
    end

    return combinations
end

-- Draw combination feedback using our existing style system
function CombinationSystem:drawCombination(combo, x, y)
    local style = self.STYLE

    -- Update animation state
    combo.visualState.animTime = combo.visualState.animTime + love.timer.getDelta()
    local bounce = math.sin(combo.visualState.animTime * style.ANIMATION.SPEED)
                  * style.ANIMATION.AMOUNT

    -- Draw using MenuStyle-compatible approach
    love.graphics.setFont(style.FONTS.COMBO)
    love.graphics.setColor(style.COLORS.COMBO)

    -- Draw combination name and bonus
    local text = string.format("%s (+%d%%)", combo.type, combo.bonus * 100)
    love.graphics.print(text, x, y + bounce)

    -- Draw involved cards
    local cardX = x + 150
    for i, card in ipairs(combo.cards) do
        if card.draw then  -- Only draw if card has draw method
            card:draw(cardX + (i-1) * (Card.WIDTH + 10), y)
        end
    end
end

-- Calculate total bonus multiplier from all combinations
function CombinationSystem:calculateBonusMultiplier(combinations)
    local totalBonus = 1.0

    for _, combo in ipairs(combinations) do
        if combo.type == self.TYPES.RECIPE_MATCH then
            totalBonus = totalBonus + self.BONUS_VALUES.RECIPE_MATCH
        elseif combo.type == self.TYPES.TECHNIQUE_BOOST then
            totalBonus = totalBonus + self.BONUS_VALUES.TECHNIQUE_BOOST
        elseif combo.type == self.TYPES.INGREDIENT_PAIR then
            totalBonus = totalBonus + self.BONUS_VALUES.INGREDIENT_PAIR
        end
    end

    return totalBonus
end

-- Get formatted description of combination bonuses
function CombinationSystem:getComboDescription(combo)
    local descriptions = {
        [self.TYPES.INGREDIENT_PAIR] = string.format("Ingredient Pair (+%d%%)", self.BONUS_VALUES.INGREDIENT_PAIR * 100),
        [self.TYPES.TECHNIQUE_BOOST] = string.format("Technique Boost (+%d%%)", self.BONUS_VALUES.TECHNIQUE_BOOST * 100),
        [self.TYPES.RECIPE_MATCH] = string.format("Recipe Match (+%d%%)", self.BONUS_VALUES.RECIPE_MATCH * 100)
    }
    return descriptions[combo.type] or ""
end

return CombinationSystem







