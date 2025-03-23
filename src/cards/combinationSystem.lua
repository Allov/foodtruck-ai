local MenuStyle = require('src.ui.menuStyle')
local Card = require('src.cards.card')

local CombinationSystem = {
    -- Only keeping ingredient pair type
    TYPES = {
        INGREDIENT_PAIR = "INGREDIENT_PAIR"  -- Applied once per matching ingredient group
    },

    -- Only keeping ingredient pair bonus
    BONUS_VALUES = {
        INGREDIENT_PAIR = 0.2  -- 20% bonus per matching ingredient group
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
            table.insert(pairCombos, newCombination(
                CombinationSystem.TYPES.INGREDIENT_PAIR,
                matchingCards,
                CombinationSystem.BONUS_VALUES.INGREDIENT_PAIR
            ))
        end
    end

    return pairCombos
end

-- Add this to the CombinationSystem table
CombinationSystem.findIngredientPairs = findIngredientPairs

function CombinationSystem:identifyCombinations(cards)
    -- Now only checks for ingredient pairs
    return self.findIngredientPairs(cards)
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
        if combo.type == self.TYPES.INGREDIENT_PAIR then
            totalBonus = totalBonus + self.BONUS_VALUES.INGREDIENT_PAIR
        end
    end

    return totalBonus
end

-- Get formatted description of combination bonuses
function CombinationSystem:getComboDescription(combo)
    if combo.type == self.TYPES.INGREDIENT_PAIR then
        return string.format("Ingredient Pair (+%d%%)", self.BONUS_VALUES.INGREDIENT_PAIR * 100)
    end
    return ""
end

return CombinationSystem

