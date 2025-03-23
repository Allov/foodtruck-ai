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
    if self.visuals then
        self.visuals:update(dt)  -- Make sure dt is passed here
    end
    if self.effects then
        self.effects:updateEffects(dt)  -- Also pass dt here if needed
    end
end

function Card:draw(x, y)
    local style = self.visuals.STYLE
    local visualState = self.visuals:getVisualState()
    
    -- Apply lift animation and hover effect
    local hoverOffset = math.sin(visualState.hover) * self.visuals.ANIMATION.HOVER.AMOUNT
    y = y - visualState.lift - hoverOffset
    
    -- Get current color based on state
    local bgColor = style.COLORS[visualState.state:upper()] or style.COLORS.DEFAULT


    
    -- Draw shadow (reduce shadow opacity for disabled state)
    local shadowOpacity = visualState.state == "disabled" and 0.05 or 0.1
    love.graphics.setColor(0, 0, 0, shadowOpacity)
    love.graphics.rectangle(
        "fill",
        x + 2,
        y + 2,
        style.DIMENSIONS.WIDTH,
        style.DIMENSIONS.HEIGHT,
        style.DIMENSIONS.CORNER_RADIUS
    )
    
    -- Draw card background with state-specific color
    love.graphics.setColor(bgColor)
    love.graphics.rectangle(
        "fill",
        x,
        y,
        style.DIMENSIONS.WIDTH,
        style.DIMENSIONS.HEIGHT,
        style.DIMENSIONS.CORNER_RADIUS
    )
    
    -- Draw border (highlight for selected/highlighted states)
    local borderColor = style.COLORS.BORDER
    if visualState.state == "selected" then
        borderColor = style.COLORS.HIGHLIGHT or {1, 1, 0, 1}
    elseif visualState.state == "highlighted" then
        borderColor = style.COLORS.ACCENT or {0.4, 0.5, 0.9, 1}
    end
    love.graphics.setColor(borderColor)
    love.graphics.rectangle(
        "line",
        x,
        y,
        style.DIMENSIONS.WIDTH,
        style.DIMENSIONS.HEIGHT,
        style.DIMENSIONS.CORNER_RADIUS
    )
    
    -- Draw title background
    local accentColor = style.COLORS.ACCENT or {0.4, 0.5, 0.9}
    local accentAlpha = visualState.state == "disabled" and 0.05 or 0.1
    love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], accentAlpha)
    love.graphics.rectangle(
        "fill",
        x + style.DIMENSIONS.BORDER_WIDTH,
        y + style.DIMENSIONS.BORDER_WIDTH,
        style.DIMENSIONS.WIDTH - style.DIMENSIONS.BORDER_WIDTH * 2,
        style.DIMENSIONS.TITLE_HEIGHT,
        style.DIMENSIONS.CORNER_RADIUS
    )
    
    -- Draw title with state-specific opacity
    local textAlpha = visualState.state == "disabled" and 0.5 or 1
    love.graphics.setFont(style.FONTS.TITLE)
    love.graphics.setColor(style.COLORS.TITLE[1], style.COLORS.TITLE[2], style.COLORS.TITLE[3], textAlpha)
    love.graphics.printf(
        self.name,
        x + style.DIMENSIONS.INNER_MARGIN,
        y + (style.DIMENSIONS.TITLE_HEIGHT - style.FONTS.TITLE:getHeight()) / 2,
        style.DIMENSIONS.WIDTH - style.DIMENSIONS.INNER_MARGIN * 2,
        "center"
    )
    
    -- Draw description with state-specific opacity
    love.graphics.setFont(style.FONTS.DESCRIPTION)
    love.graphics.setColor(style.COLORS.DESCRIPTION[1], style.COLORS.DESCRIPTION[2], style.COLORS.DESCRIPTION[3], textAlpha)
    love.graphics.printf(
        self.description,
        x + style.DIMENSIONS.INNER_MARGIN,
        y + style.DIMENSIONS.DESC_MARGIN_TOP,
        style.DIMENSIONS.WIDTH - style.DIMENSIONS.INNER_MARGIN * 2,
        "left"
    )
    
    -- Draw card type and stats with state-specific opacity
    love.graphics.setFont(style.FONTS.STATS)
    love.graphics.printf(
        self.cardType:upper(),
        x + style.DIMENSIONS.INNER_MARGIN,
        y + style.DIMENSIONS.HEIGHT - 30,
        style.DIMENSIONS.WIDTH - style.DIMENSIONS.INNER_MARGIN * 2,
        "left"
    )
    
    -- Draw score animation if active
    if visualState.scoring then
        love.graphics.setColor(style.COLORS.HIGHLIGHT)
        love.graphics.setFont(style.FONTS.TITLE)
        love.graphics.printf(
            "+" .. visualState.scoreValue,
            x,
            y - 20,
            style.DIMENSIONS.WIDTH,
            "center"
        )
    end

    -- Draw locked state indicator if needed
    if visualState.state == "locked" then
        love.graphics.setColor(1, 1, 1, 0.3)
        -- Temporary visual indicator for locked state
        love.graphics.rectangle(
            "fill",
            x + style.DIMENSIONS.WIDTH - 24,
            y + 4,
            20,
            20
        )
    end
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
        -- Don't change state if card is locked
        if self.visuals.currentState == self.visuals.STATES.LOCKED then
            return
        end
        self.visuals:setState(selected and self.visuals.STATES.SELECTED or self.visuals.STATES.DEFAULT)
    end
end

function Card:setLocked(locked)
    if self.visuals then
        self.visuals:setState(locked and self.visuals.STATES.LOCKED or self.visuals.STATES.DEFAULT)
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
