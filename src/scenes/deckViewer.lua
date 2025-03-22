local Scene = require('src.scenes.scene')
local DeckViewer = setmetatable({}, Scene)
DeckViewer.__index = DeckViewer

-- Constants for card display
local CARD_WIDTH = 120
local CARD_HEIGHT = 180
local CARD_SPACING = 10
local CARDS_PER_ROW = 6
local SECTION_SPACING = 40
local SECTION_TITLE_HEIGHT = 30
local ANIMATION_DURATION = 0.3 -- seconds

function DeckViewer.new()
    local self = setmetatable({}, Scene)
    return setmetatable(self, DeckViewer)
end

function DeckViewer:init()
    self.state = {
        scroll = 0,
        targetScroll = 0,
        maxScroll = 0,
        selectedCategory = 1,
        -- Animation state
        startScroll = 0,
        animationTime = 0,
        isAnimating = false
    }
    
    self.cardTypes = {
        "ingredient",
        "technique",
        "recipe"
    }
    
    -- Store section positions
    self.sectionPositions = {}
end

-- Quadratic easing function
function DeckViewer:easeInOutQuad(t)
    if t < 0.5 then
        return 2 * t * t
    else
        t = 2 * t - 1
        return -0.5 * (t * (t - 2) - 1)
    end
end

function DeckViewer:startScrollAnimation(targetScroll)
    self.state.startScroll = self.state.scroll
    self.state.targetScroll = targetScroll
    self.state.animationTime = 0
    self.state.isAnimating = true
end

function DeckViewer:enter()
    self.deck = gameState.currentDeck or {}
    
    -- Organize cards by type
    self.organizedCards = {}
    for _, cardType in ipairs(self.cardTypes) do
        self.organizedCards[cardType] = {}
    end
    
    for _, card in ipairs(self.deck.cards or {}) do
        local cardType = card.cardType or "unknown"
        self.organizedCards[cardType] = self.organizedCards[cardType] or {}
        table.insert(self.organizedCards[cardType], card)
    end
    
    -- Calculate section positions and max scroll
    self:calculateSectionPositions()
end

function DeckViewer:calculateSectionPositions()
    local currentY = 20
    self.sectionPositions = {}
    
    for i, cardType in ipairs(self.cardTypes) do
        local cards = self.organizedCards[cardType]
        if #cards > 0 then
            self.sectionPositions[i] = currentY
            
            -- Update currentY for next section
            local rows = math.ceil(#cards / CARDS_PER_ROW)
            currentY = currentY + SECTION_TITLE_HEIGHT
            currentY = currentY + (rows * (CARD_HEIGHT + CARD_SPACING))
            currentY = currentY + SECTION_SPACING
        end
    end
    
    self.state.maxScroll = math.max(0, currentY - love.graphics.getHeight())
end

function DeckViewer:update(dt)
    -- Handle category switching
    if love.keyboard.wasPressed('up') then
        local newCategory = self.state.selectedCategory - 1
        while newCategory >= 1 and #(self.organizedCards[self.cardTypes[newCategory]] or {}) == 0 do
            newCategory = newCategory - 1
        end
        if newCategory >= 1 then
            self.state.selectedCategory = newCategory
            self:startScrollAnimation(math.max(0, self.sectionPositions[newCategory]))
        end
    end
    
    if love.keyboard.wasPressed('down') then
        local newCategory = self.state.selectedCategory + 1
        while newCategory <= #self.cardTypes and #(self.organizedCards[self.cardTypes[newCategory]] or {}) == 0 do
            newCategory = newCategory + 1
        end
        if newCategory <= #self.cardTypes then
            self.state.selectedCategory = newCategory
            self:startScrollAnimation(math.max(0, self.sectionPositions[newCategory]))
        end
    end
    
    -- Update scroll animation
    if self.state.isAnimating then
        self.state.animationTime = self.state.animationTime + dt
        local progress = math.min(1, self.state.animationTime / ANIMATION_DURATION)
        local easedProgress = self:easeInOutQuad(progress)
        
        self.state.scroll = self.state.startScroll + 
            (self.state.targetScroll - self.state.startScroll) * easedProgress
        
        if progress >= 1 then
            self.state.isAnimating = false
            self.state.scroll = self.state.targetScroll
        end
    end
    
    -- If we came from game scene, allow both ESC and TAB to return
    if gameState.previousScene == 'game' then
        if love.keyboard.wasPressed('escape') or love.keyboard.wasPressed('tab') then
            sceneManager:switch('game')
            return
        end
    else
        -- Otherwise, just ESC to return to previous scene
        if love.keyboard.wasPressed('escape') then
            sceneManager:switch(gameState.previousScene or 'mainMenu')
            return
        end
    end
end

function DeckViewer:drawCard(card, x, y)
    -- Draw card background
    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    love.graphics.rectangle('fill', x, y, CARD_WIDTH, CARD_HEIGHT)
    
    -- Draw card border
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.rectangle('line', x, y, CARD_WIDTH, CARD_HEIGHT)
    
    -- Draw card content
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(
        card.name,
        x + 5,
        y + 10,
        CARD_WIDTH - 10,
        'center'
    )
    
    love.graphics.printf(
        card.description,
        x + 5,
        y + CARD_HEIGHT - 60,
        CARD_WIDTH - 10,
        'center'
    )
end

function DeckViewer:draw()
    love.graphics.push()
    love.graphics.translate(0, -self.state.scroll)
    
    local currentY = 20
    
    for i, cardType in ipairs(self.cardTypes) do
        local cards = self.organizedCards[cardType]
        if #cards > 0 then
            -- Draw section title with highlight if selected
            if i == self.state.selectedCategory then
                love.graphics.setColor(1, 1, 0, 1)
            else
                love.graphics.setColor(1, 1, 1, 1)
            end
            
            love.graphics.printf(
                string.upper(cardType) .. " (" .. #cards .. ")",
                0,
                currentY,
                love.graphics.getWidth(),
                'center'
            )
            currentY = currentY + 40
            
            -- Draw cards
            for j, card in ipairs(cards) do
                local row = math.floor((j-1) / CARDS_PER_ROW)
                local col = (j-1) % CARDS_PER_ROW
                
                local x = (love.graphics.getWidth() - (CARDS_PER_ROW * (CARD_WIDTH + CARD_SPACING))) / 2
                x = x + col * (CARD_WIDTH + CARD_SPACING)
                local y = currentY + row * (CARD_HEIGHT + CARD_SPACING)
                
                self:drawCard(card, x, y)
            end
            
            local rows = math.ceil(#cards / CARDS_PER_ROW)
            currentY = currentY + (rows * (CARD_HEIGHT + CARD_SPACING)) + SECTION_SPACING
        end
    end
    
    love.graphics.pop()
    
    -- Draw scroll indicators
    if self.state.maxScroll > 0 then
        love.graphics.setColor(1, 1, 1, 0.5)
        if self.state.scroll > 0 then
            love.graphics.printf("▲", 0, 10, love.graphics.getWidth(), 'center')
        end
        if self.state.scroll < self.state.maxScroll then
            love.graphics.printf("▼", 0, love.graphics.getHeight() - 30, love.graphics.getWidth(), 'center')
        end
    end
end

return DeckViewer



