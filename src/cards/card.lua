local BaseCard = require('src.cards.baseCard')
local CardVisuals = require('src.cards.cardVisuals')
local CardScoring = require('src.cards.cardScoring')
local CardEffects = require('src.cards.cardEffects')

local Card = setmetatable({}, BaseCard)
Card.__index = Card

-- Static card dimensions
Card.WIDTH = 120
Card.HEIGHT = 160

function Card.getDimensions()
    return Card.WIDTH, Card.HEIGHT
end

function Card.new(id, name, description)
    local self = BaseCard.new(id, name, description)
    setmetatable(self, Card)
    
    -- Initialize components
    self.visuals = CardVisuals.new()
    self.scoring = CardScoring.new()
    self.effects = CardEffects.new()
    
    return self
end

function Card:update(dt)
    if self.visuals and self.visuals.update then
        self.visuals:update(dt)
    end
    if self.effects and self.effects.updateEffects then
        self.effects:updateEffects()
    end
end

function Card:draw(x, y)
    -- Basic card drawing
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", x, y, self.WIDTH, self.HEIGHT)
    
    -- Draw card content
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.printf(self.name, x, y + 10, self.WIDTH, "center")
    love.graphics.printf(self.description, x + 5, y + 40, self.WIDTH - 10, "left")
end

function Card:drawBack(x, y)
    -- Draw card back
    love.graphics.setColor(0.2, 0.2, 0.8, 1) -- Blue background for card back
    love.graphics.rectangle("fill", x, y, self.WIDTH, self.HEIGHT)
    
    -- Draw decorative pattern
    love.graphics.setColor(0.3, 0.3, 0.9, 1)
    love.graphics.rectangle("line", x + 5, y + 5, self.WIDTH - 10, self.HEIGHT - 10)
    
    -- Draw logo or pattern in the center
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("★", x, y + (self.HEIGHT/2) - 20, self.WIDTH, "center")
end

function Card:setSelected(selected)
    if self.visuals then
        self.visuals.isSelected = selected
        self.visuals.targetOffset = selected and self.visuals.LIFT_AMOUNT or 0
    end
end

function Card:setLocked(locked)
    if self.visuals then
        self.visuals.isLocked = locked
    end
end

function Card:showScoreAnimation(value)
    if self.visuals then
        self.visuals.isScoring = true
        self.visuals.scoreTimer = 0
        self.visuals.scoreValue = value
    end
end

function Card:serialize()
    local baseData = BaseCard.serialize(self)
    return {
        base = baseData,
        scoring = {
            whiteScore = self.scoring.whiteScore,
            redScore = self.scoring.redScore,
            pinkScore = self.scoring.pinkScore
        },
        effects = self.effects:getEffects()
    }
end

-- Factory methods
function Card.createIngredient(id, name, description, baseScore)
    local card = Card.new(id, name, description)
    card.cardType = Card.CARD_TYPES.INGREDIENT
    card.scoring.whiteScore = baseScore
    return card
end

function Card.createTechnique(id, name, description, multiplier)
    local card = Card.new(id, name, description)
    card.cardType = Card.CARD_TYPES.TECHNIQUE
    card.scoring.redScore = multiplier
    return card
end

function Card.createRecipe(id, name, description, recipeMultiplier)
    local card = Card.new(id, name, description)
    card.cardType = Card.CARD_TYPES.RECIPE
    card.scoring.pinkScore = recipeMultiplier
    return card
end

return Card
