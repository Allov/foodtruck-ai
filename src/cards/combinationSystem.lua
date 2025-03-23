local MenuStyle = require('src.ui.menuStyle')
local Card = require('src.cards.card')

local CombinationSystem = {}

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

-- Combination types based on our card system
CombinationSystem.TYPES = {
    INGREDIENT_PAIR = "INGREDIENT_PAIR",
    TECHNIQUE_BOOST = "TECHNIQUE_BOOST",
    RECIPE_MATCH = "RECIPE_MATCH"
}

-- Create a new combination result using our card system
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

function CombinationSystem:identifyCombinations(cards)
    local combinations = {}
    
    -- Use our existing card type system from BaseCard
    local ingredients = {}
    local techniques = {}
    local recipes = {}
    
    -- Group cards using our existing card types
    for _, card in ipairs(cards) do
        if card.cardType == Card.CARD_TYPES.INGREDIENT then
            table.insert(ingredients, card)
        elseif card.cardType == Card.CARD_TYPES.TECHNIQUE then
            table.insert(techniques, card)
        elseif card.cardType == Card.CARD_TYPES.RECIPE then
            table.insert(recipes, card)
        end
    end
    
    -- Check combinations using our existing card properties
    -- ... combination logic here ...
    
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
    
    -- Draw combination name and cards involved
    local text = string.format("%s (%dx)", combo.type, combo.bonus)
    love.graphics.print(text, x, y + bounce)
    
    -- Draw involved cards using our existing Card draw system
    local cardX = x + Card.WIDTH + 20
    for i, card in ipairs(combo.cards) do
        card:draw(cardX + (i-1) * (Card.WIDTH + 10), y)
    end
end

return CombinationSystem