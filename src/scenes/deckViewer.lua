local Scene = require('src.scenes.scene')
local Card = require('src.cards.card')
local DeckViewer = setmetatable({}, Scene)
DeckViewer.__index = DeckViewer

-- Get card dimensions from Card class
local CARD_WIDTH, CARD_HEIGHT = Card.getDimensions()
local CARD_SPACING = 10
local CARDS_PER_ROW = 6
local SECTION_SPACING = 40
local SECTION_TITLE_HEIGHT = 30
local ANIMATION_DURATION = 0.3 -- seconds

function DeckViewer.new()
    local self = setmetatable({}, DeckViewer)
    -- Initialize cardTypes here instead of in init
    self.cardTypes = {
        "ingredient",
        "technique",
        "recipe"
    }
    -- Initialize other properties
    self.sectionPositions = {}
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
    return self
end

function DeckViewer:init()
    -- Remove cardTypes initialization from here since it's now in new()
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
    -- Initialize organized cards first
    self.organizedCards = {}
    for _, cardType in ipairs(self.cardTypes) do
        self.organizedCards[cardType] = {}
    end

    -- Get deck and organize cards if it exists
    self.deck = gameState.currentDeck
    if self.deck and self.deck.cards then
        for _, card in ipairs(self.deck.cards) do
            local cardType = card.cardType or "unknown"
            if not self.organizedCards[cardType] then
                self.organizedCards[cardType] = {}
            end
            table.insert(self.organizedCards[cardType], card)
        end
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
                
                -- Use card's draw method
                card:draw(x, y, i == self.state.selectedCategory)
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








