local CardConstants = require('src.cards.cardConstants')

-- Base card class
local Card = {}
Card.__index = Card

-- Constants for card display
local CARD_WIDTH = 120
local CARD_HEIGHT = 180
local LIFT_AMOUNT = 20  -- Reduced from 30 for subtler effect
local ANIMATION_SPEED = 8

-- Score type constants
Card.SCORE_TYPES = {
    WHITE = "white",   -- Base score from ingredients
    RED = "red",      -- Multiplier from techniques
    PINK = "pink"     -- Additional multiplier from recipes
}

-- Score color constants
Card.SCORE_COLORS = {
    WHITE = {1, 1, 1, 1},           -- White
    RED = {1, 0.4, 0.4, 1},         -- Red
    PINK = {1, 0.7, 0.85, 1}        -- Pink
}

-- Animation constants (matching menu style)
local HOVER_SPEED = 2
local HOVER_AMOUNT = 3

-- Add to Card class constants at the top
Card.ANIMATION = {
    SCORE_DURATION = 0.5,    -- Duration of score animation in seconds
    SCORE_SCALE = 1.15,      -- Reduced from 1.2 for subtler scaling
    SCORE_FLOAT = 20,        -- Reduced from 30 for subtler float
    SHAKE = {
        AMOUNT = 0.02,       -- Maximum rotation in radians (about 1.15 degrees)
        FREQUENCY = 18       -- Shake frequency
    }
}

-- Add shadow constants at the top with other constants
local SHADOW = {
    OFFSET_X = 4,
    OFFSET_Y = 4,
    ALPHA = 0.3,    -- Shadow opacity
    BLUR = 2        -- Number of blur passes
}

function Card:drawShadow(x, y, width, height)
    -- Save current color
    local r, g, b, a = love.graphics.getColor()
    
    -- Draw shadow with multiple passes for soft edge
    love.graphics.setColor(0, 0, 0, SHADOW.ALPHA / SHADOW.BLUR)
    for i = 1, SHADOW.BLUR do
        love.graphics.rectangle(
            'fill', 
            x + SHADOW.OFFSET_X - i, 
            y + SHADOW.OFFSET_Y - i, 
            width + i * 2, 
            height + i * 2
        )
    end
    
    -- Restore color
    love.graphics.setColor(r, g, b, a)
end

function Card.new(id, name, description)
    local self = setmetatable({}, Card)
    self.id = id                -- Unique identifier
    self.name = name            -- Card name
    self.description = description  -- Card description
    self.cardType = "base"      -- "ingredient", "technique", or "recipe"
    
    -- Scoring properties
    self.whiteScore = CardConstants.DEFAULT_VALUES.INGREDIENT.BASIC
    self.redScore = CardConstants.DEFAULT_VALUES.TECHNIQUE.BASIC
    self.pinkScore = CardConstants.DEFAULT_VALUES.RECIPE.BASIC
    
    -- Animation and state properties
    self.currentOffset = 0      -- Current vertical offset
    self.targetOffset = 0       -- Target vertical offset
    self.isSelected = false     -- Currently highlighted/selected
    self.isLocked = false       -- Locked in for use
    self.hoverOffset = 0        -- New property for hover animation
    
    -- Animation properties
    self.isScoring = false
    self.scoreTimer = 0
    self.scoreValue = nil  -- Value to display during scoring
    
    return self
end

-- Factory methods for different card types
function Card.createIngredient(id, name, description, baseScore)
    local card = Card.new(id, name, description)
    card.cardType = "ingredient"
    card.whiteScore = baseScore or 1
    return card
end

function Card.createTechnique(id, name, description, multiplier)
    local card = Card.new(id, name, description)
    card.cardType = "technique"
    card.redScore = multiplier or 1.1
    return card
end

function Card.createRecipe(id, name, description, recipeMultiplier)
    local card = Card.new(id, name, description)
    card.cardType = "recipe"
    card.pinkScore = recipeMultiplier or 1.2
    return card
end

-- Helper methods for scoring
function Card:getScoreType()
    if self.cardType == "ingredient" then
        return Card.SCORE_TYPES.WHITE
    elseif self.cardType == "technique" then
        return Card.SCORE_TYPES.RED
    elseif self.cardType == "recipe" then
        return Card.SCORE_TYPES.PINK
    end
    return nil
end

function Card:getScoreValue()
    if self.cardType == "ingredient" then
        return self.whiteScore
    elseif self.cardType == "technique" then
        return self.redScore
    elseif self.cardType == "recipe" then
        return self.pinkScore
    end
    return 0
end

-- Example score calculation helper (might be moved to battle system)
function Card.calculateCombinedScore(cards)
    local totalWhite = 0
    local totalRed = 1  -- Start at 1 as it's a multiplier
    local totalPink = 1 -- Start at 1 as it's a multiplier
    
    for _, card in ipairs(cards) do
        if card.cardType == "ingredient" then
            totalWhite = totalWhite + card.whiteScore
        elseif card.cardType == "technique" then
            totalRed = totalRed + (card.redScore - 1) -- Subtract 1 to make multipliers additive
        elseif card.cardType == "recipe" then
            totalPink = totalPink + (card.pinkScore - 1) -- Subtract 1 to make multipliers additive
        end
    end
    
    -- Final calculation: base * technique * recipe
    return totalWhite * totalRed * totalPink
end

function Card:update(dt)
    -- Update hover animation when selected
    if self.isSelected and not self.isLocked then
        self.hoverOffset = math.sin(love.timer.getTime() * HOVER_SPEED) * HOVER_AMOUNT
    else
        self.hoverOffset = 0
    end

    -- Update score animation
    if self.isScoring then
        self.scoreTimer = self.scoreTimer + dt
        if self.scoreTimer >= Card.ANIMATION.SCORE_DURATION then
            self.isScoring = false
            self.scoreTimer = 0
            self.scoreValue = nil
        end
    end

    -- Update lift animation
    if self.currentOffset < self.targetOffset then
        self.currentOffset = math.min(self.currentOffset + ANIMATION_SPEED, self.targetOffset)
    elseif self.currentOffset > self.targetOffset then
        self.currentOffset = math.max(self.currentOffset - ANIMATION_SPEED, self.targetOffset)
    end
end

function Card:setSelected(selected)
    self.isSelected = selected
    self:updateTargetOffset()
end

function Card:setLocked(locked)
    self.isLocked = locked
    self:updateTargetOffset()
end

function Card:updateTargetOffset()
    if self.isLocked then
        self.targetOffset = LIFT_AMOUNT
    elseif self.isSelected then
        self.targetOffset = LIFT_AMOUNT / 2
    else
        self.targetOffset = 0
    end
end

function Card:showScoreAnimation(value)
    self.isScoring = true
    self.scoreTimer = 0
    self.scoreValue = value
end

function Card:draw(x, y)
    local actualY = y - self.currentOffset - self.hoverOffset
    
    -- Apply scoring animation if active
    if self.isScoring then
        local progress = self.scoreTimer / Card.ANIMATION.SCORE_DURATION
        
        -- Smooth easing function (cubic)
        local easeProgress = progress < 0.5 
            and 4 * progress * progress * progress
            or 1 - math.pow(-2 * progress + 2, 3) / 2
        
        -- Calculate scale with smoother falloff
        local scaleProgress = math.sin(progress * math.pi)
        local scale = 1 + (Card.ANIMATION.SCORE_SCALE - 1) * scaleProgress
        
        -- Calculate float with smooth easing
        local floatProgress = 1 - (progress * progress) -- Quadratic falloff
        local scoreFloat = Card.ANIMATION.SCORE_FLOAT * floatProgress
        
        -- Calculate shake rotation
        local shakeAmount = Card.ANIMATION.SHAKE.AMOUNT * (1 - progress) -- Fade out shake
        local shakeRotation = math.sin(progress * Card.ANIMATION.SHAKE.FREQUENCY) * shakeAmount
        
        -- Adjust position for scaling from center
        local scaleOffsetX = (CARD_WIDTH * scale - CARD_WIDTH) / 2
        local scaleOffsetY = (CARD_HEIGHT * scale - CARD_HEIGHT) / 2
        actualY = actualY - scoreFloat
        x = x - scaleOffsetX
        actualY = actualY - scaleOffsetY
        
        -- Draw with transformations
        love.graphics.push()
        love.graphics.translate(x + CARD_WIDTH/2, actualY + CARD_HEIGHT/2)
        love.graphics.rotate(shakeRotation)
        love.graphics.scale(scale, scale)
        love.graphics.translate(-CARD_WIDTH/2, -CARD_HEIGHT/2)
        
        -- Draw shadow first
        self:drawShadow(0, 0, CARD_WIDTH, CARD_HEIGHT)
        -- Draw card content
        self:drawCardContent(0, 0)
        
        -- Draw score value if present
        if self.scoreValue then
            -- Fade in quickly, hold, then fade out
            local alpha = progress < 0.2 and progress * 5 or
                         progress > 0.8 and (1 - progress) * 5 or
                         1
            
            love.graphics.setColor(1, 1, 0, alpha)
            love.graphics.setFont(love.graphics.newFont(24))
            love.graphics.printf(
                self.scoreValue,
                -20,  -- Extend left for better centering
                -35,  -- Float above card
                CARD_WIDTH + 40,  -- Extra width for larger numbers
                'center'
            )
        end
        
        love.graphics.pop()
    else
        -- Normal card drawing with shadow
        self:drawShadow(x, actualY, CARD_WIDTH, CARD_HEIGHT)
        self:drawCardContent(x, actualY)
    end
end

-- New helper method to avoid code duplication
function Card:drawCardContent(x, y)
    -- Draw card background
    if self.isLocked then
        love.graphics.setColor(0.3, 0.8, 0.3, 1)
    elseif self.isSelected then
        love.graphics.setColor(0.3, 0.3, 0.8, 1)
    else
        love.graphics.setColor(0.2, 0.2, 0.2, 1)
    end
    love.graphics.rectangle('fill', x, y, CARD_WIDTH, CARD_HEIGHT)
    
    -- Draw card border
    if self.isLocked then
        love.graphics.setColor(0, 1, 0, 1)
        love.graphics.setLineWidth(3)
    elseif self.isSelected then
        love.graphics.setColor(1, 1, 0, 1)
        love.graphics.setLineWidth(3)
    else
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        love.graphics.setLineWidth(1)
    end
    love.graphics.rectangle('line', x, y, CARD_WIDTH, CARD_HEIGHT)
    
    -- Draw card name
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(
        self.name,
        x + 5,
        y + 10,
        CARD_WIDTH - 10,
        'center'
    )
    
    -- Draw score based on card type
    local scoreY = y + CARD_HEIGHT - 90
    local fontSize = love.graphics.getFont():getHeight()
    
    if self.cardType == "ingredient" then
        love.graphics.setColor(unpack(Card.SCORE_COLORS.WHITE))
        love.graphics.printf(
            string.format("%d", self.whiteScore),
            x + 5,
            scoreY,
            CARD_WIDTH - 10,
            'center'
        )
    elseif self.cardType == "technique" then
        love.graphics.setColor(unpack(Card.SCORE_COLORS.RED))
        love.graphics.printf(
            string.format("×%.1f", self.redScore),
            x + 5,
            scoreY,
            CARD_WIDTH - 10,
            'center'
        )
    elseif self.cardType == "recipe" then
        love.graphics.setColor(unpack(Card.SCORE_COLORS.PINK))
        love.graphics.printf(
            string.format("×%.1f", self.pinkScore),
            x + 5,
            scoreY,
            CARD_WIDTH - 10,
            'center'
        )
    end
    
    -- Draw card description
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(
        self.description,
        x + 5,
        y + CARD_HEIGHT - 60,
        CARD_WIDTH - 10,
        'center'
    )
end

-- Getter for card dimensions
function Card.getDimensions()
    return CARD_WIDTH, CARD_HEIGHT
end

-- Add this function to draw card backs
function Card:drawBack(x, y)
    -- Draw shadow first
    self:drawShadow(x, y, CARD_WIDTH, CARD_HEIGHT)
    
    -- Draw card background
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.rectangle('fill', x, y, CARD_WIDTH, CARD_HEIGHT)
    
    -- Draw card border
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.rectangle('line', x, y, CARD_WIDTH, CARD_HEIGHT)
    
    -- Draw card back pattern
    love.graphics.setColor(0.4, 0.4, 0.4, 1)
    -- Diamond pattern
    local centerX = x + CARD_WIDTH / 2
    local centerY = y + CARD_HEIGHT / 2
    local diamondWidth = CARD_WIDTH * 0.6
    local diamondHeight = CARD_HEIGHT * 0.6
    
    -- Draw outer diamond
    love.graphics.polygon('line', 
        centerX, centerY - diamondHeight/2,
        centerX + diamondWidth/2, centerY,
        centerX, centerY + diamondHeight/2,
        centerX - diamondWidth/2, centerY
    )
    
    -- Draw inner diamond
    local innerScale = 0.6
    love.graphics.polygon('line', 
        centerX, centerY - (diamondHeight/2 * innerScale),
        centerX + (diamondWidth/2 * innerScale), centerY,
        centerX, centerY + (diamondHeight/2 * innerScale),
        centerX - (diamondWidth/2 * innerScale), centerY
    )
end

return Card
