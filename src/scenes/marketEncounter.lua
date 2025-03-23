local Encounter = require('src.scenes.encounter')
local Card = require('src.cards.card')  -- Add this at the top with other requires
local PackFactory = require('src.cards.packFactory')
local MarketEncounter = {}
MarketEncounter.__index = MarketEncounter
MarketEncounter.__name = "marketEncounter"
setmetatable(MarketEncounter, Scene)

-- Card display constants
local CARD_WIDTH = 160
local CARD_HEIGHT = 200
local CARD_SPACING = 20
local CARDS_PER_ROW = 4
local START_Y = 100

local COLORS = {
    PRIMARY = {0, 0.7, 1, 1},    -- Blue for market theme
    TEXT = {1, 1, 1, 1},
    HIGHLIGHT = {1, 0.8, 0, 1},  -- Gold for prices
    ACCENT = {0.5, 0.8, 1, 1}    -- Light blue for accents
}

function MarketEncounter.new()
    local self = setmetatable({}, MarketEncounter)
    self.state = {
        availableCards = {},  -- Cards currently for sale
        selectedIndex = 1,    -- Currently selected card
        cash = 0,            -- Initialize with 0
        title = "Market",    -- Will be set based on market type
        showingDeck = false  -- New state for deck viewing
    }
    return self
end

function MarketEncounter:enter()
    -- Set cash from gameState
    self.state.cash = gameState.cash or 0
    self.state.selectedIndex = 1
    
    -- Set title based on market type
    local marketTitles = {
        farmers_market = "Farmers Market",
        specialty_shop = "Specialty Food Shop",
        supply_store = "Restaurant Supply Store"
    }
    self.state.title = marketTitles[gameState.currentMarketType] or "Market"
    
    -- Generate initial stock
    self:generateMarketStock()

    -- If no cards were generated, default to "Leave" option
    if #self.state.availableCards == 0 then
        self.state.selectedIndex = 1  -- Only the leave button will be available
    end
end

function MarketEncounter:generateMarketStock()
    print("Generating market stock for type:", gameState.currentMarketType)
    local cards = PackFactory.generatePack(gameState.currentMarketType)
    
    -- Convert card data to Card objects with proper state management
    self.state.availableCards = {}
    for _, cardData in ipairs(cards) do
        local card = Card.new(
            love.math.random(1000, 9999),
            cardData.name,
            cardData.description
        )
        card.cardType = cardData.cardType
        card.cost = cardData.cost
        table.insert(self.state.availableCards, card)
    end
    
    -- Add the Skip card
    local skipCard = Card.new(0, "Skip Market", "Leave this market without making a purchase")
    skipCard.cardType = "action"
    skipCard.cost = 0
    table.insert(self.state.availableCards, skipCard)
end

function MarketEncounter:drawCard(cardData, x, y, isSelected)
    -- Create a temporary Card object for drawing
    local tempCard = Card.new(0, cardData.name, cardData.description)
    tempCard.cardType = cardData.cardType
    tempCard.cost = cardData.cost
    
    -- Use the Card class's draw method
    tempCard:draw(x, y, isSelected)
    
    -- Draw cost (since it's market-specific)
    love.graphics.setColor(1, 0.8, 0, 1)  -- Gold color for cost
    love.graphics.printf(
        "$" .. cardData.cost,
        x + 10,
        y + CARD_HEIGHT - 40,
        CARD_WIDTH - 20,
        'center'
    )
end

function MarketEncounter:handleOption(optionIndex)
    print("Handling option: " .. optionIndex)
    if optionIndex == 1 then  -- "Browse Goods"
        -- Set market type and enter browsing mode
        if not gameState.currentMarketType then
            gameState.currentMarketType = "farmers_market"
        end
        
        local marketTitles = {
            farmers_market = "Farmers Market",
            specialty_shop = "Specialty Food Shop",
            supply_store = "Restaurant Supply Store"
        }
        self.state.title = marketTitles[gameState.currentMarketType] or "Market"
        
        self.browsing = true
        self:generateMarketStock()
    elseif optionIndex == 2 then  -- "Chat/Gossip"
        -- Get the current market's gossips
        local marketTypes = {
            farmers_market = self.encounterPool.market[1],
            specialty_shop = self.encounterPool.market[2],
            supply_store = self.encounterPool.market[3]
        }
        
        local currentMarket = marketTypes[gameState.currentMarketType or "farmers_market"]
        local randomGossip = currentMarket.gossips[love.math.random(#currentMarket.gossips)]
        
        -- Update the encounter state to show the gossip
        self.state.description = randomGossip
        self.state.options = {"Continue Shopping", "Leave"}
        self.state.currentOption = 1
    else  -- "Leave"
        self:resolveEncounter()
    end
end

-- Add a method to handle the gossip continuation
function MarketEncounter:handleGossipContinue(optionIndex)
    if optionIndex == 1 then  -- "Continue Shopping"
        -- Reset to original market description and options
        local currentMarket = self.encounterPool.market[1]  -- Default to farmers market
        for _, market in ipairs(self.encounterPool.market) do
            if market.marketType == gameState.currentMarketType then
                currentMarket = market
                break
            end
        end
        
        self.state.description = currentMarket.description
        self.state.options = currentMarket.options
        self.state.currentOption = 1
    else  -- "Leave"
        self:resolveEncounter()
    end
end

function MarketEncounter:resolveEncounter()
    -- Only try to mark node as completed if we came from the province map
    if gameState.currentNodeLevel and gameState.currentNodeIndex then
        -- Get the province map scene
        local provinceMap = sceneManager.scenes['provinceMap']
        -- Mark the current node as completed
        provinceMap:markNodeCompleted(gameState.currentNodeLevel, gameState.currentNodeIndex)
    end
    
    -- Clear the current encounter
    gameState.currentEncounter = nil
    
    -- Return to previous scene
    sceneManager:switch(gameState.previousScene or 'provinceMap')
end

function MarketEncounter:update(dt)
    -- If showing deck, handle deck viewer controls
    if self.state.showingDeck then
        if love.keyboard.wasPressed('escape') or love.keyboard.wasPressed('tab') then
            self.state.showingDeck = false
            return
        end
        return
    end

    -- Add tab key to toggle deck view
    if love.keyboard.wasPressed('tab') then
        self.state.showingDeck = true
        -- Store current scene and switch to deck viewer
        gameState.previousScene = 'marketEncounter'
        sceneManager:switch('deckViewer')
        return
    end

    local numCards = #self.state.availableCards
    
    if love.keyboard.wasPressed('left') then
        self.state.selectedIndex = self.state.selectedIndex - 1
        if self.state.selectedIndex < 1 then 
            self.state.selectedIndex = numCards
        end
    end
    
    if love.keyboard.wasPressed('right') then
        self.state.selectedIndex = self.state.selectedIndex + 1
        if self.state.selectedIndex > numCards then
            self.state.selectedIndex = 1
        end
    end
    
    if love.keyboard.wasPressed('return') or love.keyboard.wasPressed('space') then
        self:tryPurchase(self.state.selectedIndex)
    end

    -- Allow escape to select the Skip card
    if love.keyboard.wasPressed('escape') then
        self.state.selectedIndex = #self.state.availableCards  -- Select Skip card
    end
end

function MarketEncounter:tryPurchase(index)
    local cardData = self.state.availableCards[index]
    if not cardData then return end  -- Safety check

    if cardData.name == "Skip Market" then
        -- Skip card is free and just resolves the encounter
        self:resolveEncounter()
        return
    end

    if self.state.cash >= cardData.cost then
        -- Create a proper Card object
        local card = Card.new(
            love.math.random(1000, 9999), -- Generate a random ID for now
            cardData.name,
            cardData.description
        )
        card.cardType = cardData.cardType
        card.cost = cardData.cost  -- Optional: preserve cost info
        
        -- Add to player's deck
        gameState.currentDeck:addCard(card)
        
        -- Deduct cost
        self.state.cash = self.state.cash - cardData.cost
        gameState.cash = self.state.cash
        
        -- Remove from available cards
        table.remove(self.state.availableCards, index)
        
        -- Adjust selection index if needed
        if self.state.selectedIndex > #self.state.availableCards then
            self.state.selectedIndex = #self.state.availableCards
        end
        
        -- Resolve the encounter after successful purchase
        self:resolveEncounter()
    end
end

function MarketEncounter:draw()
    -- Draw background overlay
    love.graphics.setColor(COLORS.PRIMARY[1], COLORS.PRIMARY[2], COLORS.PRIMARY[3], 0.1)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    local cardWidth, cardHeight = Card.getDimensions()
    local spacing = CARD_SPACING
    local cardsPerRow = CARDS_PER_ROW
    
    -- Calculate starting position to center the grid
    local totalWidth = (cardWidth + spacing) * cardsPerRow - spacing
    local startX = (love.graphics.getWidth() - totalWidth) / 2
    local startY = START_Y
    
    -- Draw title
    love.graphics.setColor(COLORS.TEXT)
    love.graphics.printf(self.state.title, 0, 30, love.graphics.getWidth(), 'center')
    
    -- Draw available cards in a grid
    for i, card in ipairs(self.state.availableCards) do
        -- Calculate row and column
        local row = math.floor((i-1) / cardsPerRow)
        local col = (i-1) % cardsPerRow
        
        -- Calculate position
        local x = startX + (col * (cardWidth + spacing))
        local y = startY + (row * (cardHeight + spacing))
        
        -- Update card selection state
        card:setSelected(i == self.state.selectedIndex)
        -- Remove the update call from here - it shouldn't be in draw
        
        -- Draw card
        card:draw(x, y)
        
        -- Draw price
        love.graphics.setColor(COLORS.HIGHLIGHT)
        love.graphics.printf(
            "Cost: " .. (card.cost or 0) .. " coins",
            x,
            y + cardHeight + 5,
            cardWidth,
            'center'
        )
    end
end

-- Add update method
function MarketEncounter:update(dt)
    -- Update all cards
    for _, card in ipairs(self.state.availableCards) do
        card:update(dt)
    end
end

return MarketEncounter


