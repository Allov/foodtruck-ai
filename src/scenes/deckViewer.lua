local Scene = require('src.scenes.scene')
local BaseCard = require('src.cards.baseCard')
local Card = require('src.cards.card')
local DeckViewer = setmetatable({}, Scene)
DeckViewer.__index = DeckViewer

-- Constants at the top of the file
local CARD_WIDTH, CARD_HEIGHT = BaseCard.CARD_WIDTH, BaseCard.CARD_HEIGHT
local CARD_SPACING = 10  -- Horizontal spacing between cards
local ROW_SPACING = 30   -- Vertical spacing between rows (new constant)
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
        "recipe",
        "action"      -- Add action type
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
    local currentY = 40  -- Initial spacing from top
    self.sectionPositions = {}
    
    for i, cardType in ipairs(self.cardTypes) do
        local cards = self.organizedCards[cardType]
        if #cards > 0 then
            self.sectionPositions[i] = currentY
            
            -- Update currentY for next section
            local rows = math.ceil(#cards / CARDS_PER_ROW)
            currentY = currentY + SECTION_TITLE_HEIGHT + 20  -- Padding after title
            -- Add ROW_SPACING to the calculation
            currentY = currentY + (rows * CARD_HEIGHT) + ((rows - 1) * ROW_SPACING)
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
            -- Negate the scroll value
            self:startScrollAnimation(-math.max(0, self.sectionPositions[newCategory]))
        end
    end
    
    if love.keyboard.wasPressed('down') then
        local newCategory = self.state.selectedCategory + 1
        while newCategory <= #self.cardTypes and #(self.organizedCards[self.cardTypes[newCategory]] or {}) == 0 do
            newCategory = newCategory + 1
        end
        if newCategory <= #self.cardTypes then
            self.state.selectedCategory = newCategory
            -- Negate the scroll value
            self:startScrollAnimation(-math.max(0, self.sectionPositions[newCategory]))
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
    local cardWidth, cardHeight = BaseCard.getDimensions()
    local spacing = 20
    local dt = love.timer.getDelta()  -- Get delta time for animations
    
    -- Draw categories
    for i, cardType in ipairs(self.cardTypes) do
        local cards = self.organizedCards[cardType]
        if #cards > 0 then  -- Only draw sections that have cards
            local startY = self.sectionPositions[i] + self.state.scroll
            
            -- Draw section title with better styling
            love.graphics.setColor(0.2, 0.2, 0.2, 1)  -- Dark background for title
            love.graphics.rectangle(
                "fill",
                30,
                startY,
                love.graphics.getWidth() - 60,
                SECTION_TITLE_HEIGHT,
                5  -- Rounded corners
            )
            
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setFont(love.graphics.newFont(18))  -- Larger font for section title
            love.graphics.printf(
                string.upper(cardType),
                50,
                startY + (SECTION_TITLE_HEIGHT - love.graphics.getFont():getHeight()) / 2,  -- Vertically centered
                love.graphics.getWidth() - 100,
                'left'
            )
            
            -- Draw cards starting below the title
            local cardsStartY = startY + SECTION_TITLE_HEIGHT + 20  -- Added padding after title
            local startX = 50
            
            -- Draw cards in reverse order for correct overlapping
            for j = #cards, 1, -1 do
                local card = cards[j]
                local x = startX + ((j-1) % CARDS_PER_ROW) * (CARD_WIDTH + CARD_SPACING)
                local row = math.floor((j-1) / CARDS_PER_ROW)
                -- Add ROW_SPACING to the y-position calculation
                local y = cardsStartY + (row * (CARD_HEIGHT + ROW_SPACING))
                
                if y + CARD_HEIGHT > 0 and y < love.graphics.getHeight() then
                    card:update(dt)
                    card:draw(x, y)
                end
            end
        end
    end
    
    -- Draw scroll indicators if needed
    if self.state.maxScroll > 0 then
        if self.state.scroll > -self.state.maxScroll then
            love.graphics.setColor(1, 1, 1, 0.5)
            love.graphics.printf("▼", 0, love.graphics.getHeight() - 30, love.graphics.getWidth(), 'center')
        end
        if self.state.scroll < 0 then
            love.graphics.setColor(1, 1, 1, 0.5)
            love.graphics.printf("▲", 0, 10, love.graphics.getWidth(), 'center')
        end
    end
end

function DeckViewer:getCardsByType(cardType)
    local cards = {}
    -- Assuming gameState.currentDeck.cards is your collection of cards
    for _, card in ipairs(gameState.currentDeck.cards) do
        if card.cardType == cardType then
            table.insert(cards, card)
        end
    end
    return cards
end

return DeckViewer



















