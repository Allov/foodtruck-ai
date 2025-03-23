local BaseCard = require('src.cards.baseCard')
local CardVisuals = require('src.cards.cardVisuals')
local CardScoring = require('src.cards.cardScoring')
local CardEffects = require('src.cards.cardEffects')

local Card = setmetatable({}, BaseCard)
Card.__index = Card

-- Static card dimensions - increased size
Card.WIDTH = 160  -- Increased from 120
Card.HEIGHT = 220 -- Increased from 160

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
    
    -- Draw base card elements
    self:drawCardBase(x, y, style, visualState)
    
    -- Draw card sections in order (from top to bottom)
    self:drawTitleSection(x, y, style, visualState)
    self:drawTypeSection(x, y, style, visualState)
    self:drawImageSection(x, y, style, visualState)
    self:drawDescriptionSection(x, y, style, visualState)
    self:drawStatsSection(x, y, style, visualState)
    self:drawFooterSection(x, y, style, visualState)
    
    -- Draw overlay effects (locked, scoring animation, etc.)
    self:drawOverlayEffects(x, y, style, visualState)
end

function Card:drawCardBase(x, y, style, visualState)
    local typeColors = self.visuals.TYPE_COLORS[self.cardType]
    
    -- Enhanced shadow
    local baseShadowOpacity = visualState.state == "disabled" and 0.2 or 0.3
    local shadowOffsetX = 4
    local shadowOffsetY = 6
    local shadowSpread = 4  -- How much larger the shadow is than the card
    
    -- Make shadow more prominent when card is lifted or hovering
    local liftAmount = visualState.lift + math.abs(math.sin(visualState.hover) * self.visuals.ANIMATION.HOVER.AMOUNT)
    shadowOffsetY = shadowOffsetY + (liftAmount * 0.5)
    baseShadowOpacity = baseShadowOpacity + (liftAmount / 100)
    
    -- Draw multiple shadows for a soft blur effect
    for i = 1, 3 do
        local spreadMultiplier = (i - 1) * shadowSpread
        local opacity = baseShadowOpacity / i  -- Fade out each layer
        
        love.graphics.setColor(0, 0, 0, opacity)
        love.graphics.rectangle(
            "fill",
            x + shadowOffsetX - spreadMultiplier/2,
            y + shadowOffsetY - spreadMultiplier/2,
            style.DIMENSIONS.WIDTH + spreadMultiplier,
            style.DIMENSIONS.HEIGHT + spreadMultiplier,
            style.DIMENSIONS.CORNER_RADIUS
        )
    end
    
    -- Draw card background
    local bgColor = typeColors.PRIMARY
    if visualState.state ~= "default" then
        bgColor = style.COLORS[visualState.state:upper()]
    end
    love.graphics.setColor(bgColor)
    love.graphics.rectangle(
        "fill",
        x,
        y,
        style.DIMENSIONS.WIDTH,
        style.DIMENSIONS.HEIGHT,
        style.DIMENSIONS.CORNER_RADIUS
    )
    
    -- Draw border
    local borderColor = typeColors.BORDER
    if visualState.state == "selected" then
        borderColor = style.COLORS.HIGHLIGHT
    elseif visualState.state == "highlighted" then
        borderColor = typeColors.ACCENT
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
end

function Card:drawTitleSection(x, y, style, visualState)
    local typeColors = self.visuals.TYPE_COLORS[self.cardType]
    
    -- Draw title background
    love.graphics.setColor(typeColors.TITLE_BG)
    love.graphics.rectangle(
        "fill",
        x + style.DIMENSIONS.BORDER_WIDTH,
        y + style.DIMENSIONS.BORDER_WIDTH,
        style.DIMENSIONS.WIDTH - style.DIMENSIONS.BORDER_WIDTH * 2,
        style.DIMENSIONS.TITLE_HEIGHT,
        style.DIMENSIONS.CORNER_RADIUS
    )
    
    -- Draw title text with better vertical centering
    local textAlpha = visualState.state == "disabled" and 0.5 or 1
    love.graphics.setFont(style.FONTS.TITLE)
    
    -- Calculate vertical centering
    local fontHeight = style.FONTS.TITLE:getHeight()
    local titleY = y + style.DIMENSIONS.BORDER_WIDTH + 
                  (style.DIMENSIONS.TITLE_HEIGHT - fontHeight) / 2
    
    -- Add text trimming if needed
    local titleWidth = style.DIMENSIONS.WIDTH - (style.DIMENSIONS.INNER_MARGIN * 2)
    local text = self.name
    while style.FONTS.TITLE:getWidth(text) > titleWidth and #text > 3 do
        text = text:sub(1, -2)
    end
    
    love.graphics.setColor(typeColors.TEXT[1], typeColors.TEXT[2], typeColors.TEXT[3], textAlpha)
    love.graphics.printf(
        text,
        x + style.DIMENSIONS.INNER_MARGIN,
        titleY,
        titleWidth,
        "center"
    )
end

function Card:drawTypeSection(x, y, style, visualState)
    local typeColors = self.visuals.TYPE_COLORS[self.cardType]
    
    -- Adjusted position after title
    local typeY = y + style.DIMENSIONS.TITLE_HEIGHT + style.SECTIONS.TYPE_MARGIN
    love.graphics.setFont(style.FONTS.STATS)
    love.graphics.setColor(typeColors.SECONDARY)
    love.graphics.printf(
        self.cardType:upper(),
        x + style.DIMENSIONS.INNER_MARGIN,
        typeY,
        style.DIMENSIONS.WIDTH - style.DIMENSIONS.INNER_MARGIN * 2,
        "left"
    )
end

function Card:drawImageSection(x, y, style, visualState)
    -- Adjusted position after type section
    local imageY = y + style.DIMENSIONS.TITLE_HEIGHT + 
                  style.SECTIONS.TYPE_MARGIN + style.FONTS.STATS:getHeight() + 5
    
    love.graphics.setColor(0.9, 0.9, 0.9, 0.1)
    love.graphics.rectangle(
        "fill",
        x + style.DIMENSIONS.INNER_MARGIN,
        imageY,
        style.DIMENSIONS.WIDTH - style.DIMENSIONS.INNER_MARGIN * 2,
        style.SECTIONS.IMAGE_HEIGHT
    )
end

function Card:drawDescriptionSection(x, y, style, visualState)
    local typeColors = self.visuals.TYPE_COLORS[self.cardType]
    local textAlpha = visualState.state == "disabled" and 0.5 or 1
    
    -- Calculate description position after image section
    local descY = y + style.DIMENSIONS.DESC_MARGIN_TOP + style.SECTIONS.IMAGE_HEIGHT
    
    love.graphics.setFont(style.FONTS.DESCRIPTION)
    love.graphics.setColor(typeColors.TEXT[1], typeColors.TEXT[2], typeColors.TEXT[3], textAlpha)
    
    -- Add padding and word wrap
    love.graphics.printf(
        self.description,
        x + style.DIMENSIONS.INNER_MARGIN,
        descY,
        style.DIMENSIONS.WIDTH - style.DIMENSIONS.INNER_MARGIN * 2,
        "left"
    )
end

function Card:drawStatsSection(x, y, style, visualState)
    -- Draw card stats (if any)
    -- This section can be expanded based on card type
end

function Card:drawFooterSection(x, y, style, visualState)
    local typeColors = self.visuals.TYPE_COLORS[self.cardType]
    local textAlpha = visualState.state == "disabled" and 0.5 or 1
    
    -- Draw scoring information at the bottom
    local scoreText = ""
    if self.cardType == "ingredient" then
        scoreText = string.format("+%d", self.scoring.whiteScore)
    elseif self.cardType == "technique" then
        scoreText = string.format("×%.1f", self.scoring.redScore)
    elseif self.cardType == "recipe" then
        scoreText = string.format("×%.1f", self.scoring.pinkScore)
    end
    
    -- Use the secondary color from the card type's color scheme
    love.graphics.setColor(typeColors.SECONDARY[1], 
                         typeColors.SECONDARY[2], 
                         typeColors.SECONDARY[3], 
                         textAlpha)
    
    -- Use larger score font
    love.graphics.setFont(style.FONTS.SCORE)
    love.graphics.printf(
        scoreText,
        x + style.DIMENSIONS.INNER_MARGIN,
        y + style.DIMENSIONS.HEIGHT - style.SECTIONS.FOOTER_HEIGHT + 
            (style.SECTIONS.FOOTER_HEIGHT - style.FONTS.SCORE:getHeight()) / 2,  -- Center vertically
        style.DIMENSIONS.WIDTH - style.DIMENSIONS.INNER_MARGIN * 2,
        "right"
    )
end

function Card:drawOverlayEffects(x, y, style, visualState)
    -- Draw locked state indicator
    if visualState.state == "locked" then
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.rectangle(
            "fill",
            x + style.DIMENSIONS.WIDTH - 24,
            y + 4,
            20,
            20
        )
    end
    
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
end

function Card:drawBack(x, y)
    local style = self.visuals.STYLE
    
    -- Enhanced shadow
    local baseShadowOpacity = 0.3
    local shadowOffsetX = 4
    local shadowOffsetY = 6
    local shadowSpread = 4
    
    for i = 1, 3 do
        local spreadMultiplier = (i - 1) * shadowSpread
        local opacity = baseShadowOpacity / i
        
        love.graphics.setColor(0, 0, 0, opacity)
        love.graphics.rectangle(
            "fill",
            x + shadowOffsetX - spreadMultiplier/2,
            y + shadowOffsetY - spreadMultiplier/2,
            style.DIMENSIONS.WIDTH + spreadMultiplier,
            style.DIMENSIONS.HEIGHT + spreadMultiplier,
            style.DIMENSIONS.CORNER_RADIUS
        )
    end
    
    -- Main background - More sophisticated dark blue-gray
    love.graphics.setColor(0.15, 0.17, 0.22, 1)
    love.graphics.rectangle(
        "fill",
        x,
        y,
        style.DIMENSIONS.WIDTH,
        style.DIMENSIONS.HEIGHT,
        style.DIMENSIONS.CORNER_RADIUS
    )
    
    -- Outer border - Sharp and distinct
    love.graphics.setColor(0.8, 0.85, 0.9, 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle(
        "line",
        x,
        y,
        style.DIMENSIONS.WIDTH,
        style.DIMENSIONS.HEIGHT,
        style.DIMENSIONS.CORNER_RADIUS
    )
    
    -- Inner border with gradient effect
    local margin = style.DIMENSIONS.INNER_MARGIN
    love.graphics.setColor(0.4, 0.45, 0.5, 0.6)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle(
        "line",
        x + margin,
        y + margin,
        style.DIMENSIONS.WIDTH - margin * 2,
        style.DIMENSIONS.HEIGHT - margin * 2,
        style.DIMENSIONS.CORNER_RADIUS - 2
    )
    
    -- Center pattern
    local centerX = x + style.DIMENSIONS.WIDTH / 2
    local centerY = y + style.DIMENSIONS.HEIGHT / 2
    local patternSize = 70  -- Slightly larger pattern
    
    -- Main diamond outline
    love.graphics.setColor(0.8, 0.85, 0.9, 0.8)
    love.graphics.setLineWidth(2)
    local points = {
        centerX, centerY - patternSize,
        centerX + patternSize, centerY,
        centerX, centerY + patternSize,
        centerX - patternSize, centerY
    }
    love.graphics.polygon("line", points)
    
    -- Inner diamond with fill
    local innerSize = patternSize * 0.7
    love.graphics.setColor(0.2, 0.22, 0.28, 0.6)
    local innerPoints = {
        centerX, centerY - innerSize,
        centerX + innerSize, centerY,
        centerX, centerY + innerSize,
        centerX - innerSize, centerY
    }
    love.graphics.polygon("fill", innerPoints)
    love.graphics.setColor(0.6, 0.65, 0.7, 0.4)
    love.graphics.polygon("line", innerPoints)
    
    -- Corner accents
    love.graphics.setColor(0.8, 0.85, 0.9, 0.9)
    local circleSize = 8
    local cornerDist = patternSize * 0.8
    
    -- Corner circles with inner detail
    local function drawCornerAccent(cx, cy)
        love.graphics.circle("fill", cx, cy, circleSize)
        love.graphics.setColor(0.15, 0.17, 0.22, 0.8)
        love.graphics.circle("fill", cx, cy, circleSize * 0.6)
        love.graphics.setColor(0.8, 0.85, 0.9, 0.9)
        love.graphics.circle("fill", cx, cy, circleSize * 0.2)
    end
    
    drawCornerAccent(centerX, centerY - cornerDist)
    drawCornerAccent(centerX + cornerDist, centerY)
    drawCornerAccent(centerX, centerY + cornerDist)
    drawCornerAccent(centerX - cornerDist, centerY)
    
    -- Center medallion
    love.graphics.setColor(0.8, 0.85, 0.9, 0.9)
    love.graphics.circle("fill", centerX, centerY, circleSize * 1.5)
    love.graphics.setColor(0.15, 0.17, 0.22, 0.8)
    love.graphics.circle("fill", centerX, centerY, circleSize * 0.9)
    love.graphics.setColor(0.8, 0.85, 0.9, 0.7)
    love.graphics.circle("fill", centerX, centerY, circleSize * 0.3)
    
    -- Subtle background pattern
    love.graphics.setColor(0.8, 0.85, 0.9, 0.04)
    local gridSize = 12
    for i = 0, style.DIMENSIONS.WIDTH, gridSize do
        love.graphics.line(
            x + i, 
            y, 
            x + i, 
            y + style.DIMENSIONS.HEIGHT
        )
    end
    for i = 0, style.DIMENSIONS.HEIGHT, gridSize do
        love.graphics.line(
            x, 
            y + i, 
            x + style.DIMENSIONS.WIDTH, 
            y + i
        )
    end
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
