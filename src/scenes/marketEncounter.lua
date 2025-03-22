local Encounter = require('src.scenes.encounter')
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
    -- Generate 4-6 cards for sale
    local numCards = love.math.random(4, 6)
    self.state.availableCards = {}
    
    -- Different card pools based on market type
    local cardPools = {
        farmers_market = {
            {name = "Fresh Tomatoes", cardType = "ingredient", cost = 3, description = "Basic but versatile"},
            {name = "Local Herbs", cardType = "ingredient", cost = 4, description = "Adds flavor to any dish"},
            {name = "Fresh Fish", cardType = "ingredient", cost = 6, description = "Caught this morning"},
            {name = "Seasonal Vegetables", cardType = "ingredient", cost = 3, description = "A mix of local produce"},
            {name = "Farm Eggs", cardType = "ingredient", cost = 2, description = "Fresh from the coop"},
            {name = "Wild Mushrooms", cardType = "ingredient", cost = 5, description = "Locally foraged"}
        },
        specialty_shop = {
            {name = "Truffle Oil", cardType = "ingredient", cost = 8, description = "Luxurious finishing oil"},
            {name = "Saffron", cardType = "ingredient", cost = 10, description = "Precious spice"},
            {name = "Aged Vinegar", cardType = "ingredient", cost = 7, description = "Complex flavors"},
            {name = "Imported Cheese", cardType = "ingredient", cost = 9, description = "Artisanal selection"},
            {name = "Caviar", cardType = "ingredient", cost = 12, description = "Premium fish roe"},
            {name = "Wagyu Beef", cardType = "ingredient", cost = 15, description = "Highest grade marbling"}
        },
        supply_store = {
            {name = "Sharp Knife", cardType = "technique", cost = 5, description = "Improved cutting speed"},
            {name = "Steel Pan", cardType = "technique", cost = 6, description = "Better heat control"},
            {name = "Basic Spices", cardType = "ingredient", cost = 4, description = "Essential seasonings"},
            {name = "Cooking Oil", cardType = "ingredient", cost = 2, description = "All-purpose oil"},
            {name = "Stock Pot", cardType = "technique", cost = 7, description = "For soups and stocks"},
            {name = "Kitchen Scale", cardType = "technique", cost = 4, description = "Precise measurements"}
        }
    }
    
    -- Select cards based on market type
    local pool = cardPools[gameState.currentMarketType or "farmers_market"]
    
    -- Create a copy of the pool to modify
    local availablePool = {}
    for i, card in ipairs(pool) do
        table.insert(availablePool, card)
    end
    
    -- Select random unique cards
    for i = 1, numCards do
        if #availablePool > 0 then
            local index = love.math.random(#availablePool)
            table.insert(self.state.availableCards, availablePool[index])
            table.remove(availablePool, index)
        end
    end
    
    -- Sort cards by cost
    table.sort(self.state.availableCards, function(a, b) 
        return a.cost < b.cost 
    end)

    -- Add the Skip card at the end
    table.insert(self.state.availableCards, {
        name = "Skip Market",
        cardType = "action",
        cost = 0,
        description = "Leave this market without making a purchase"
    })
end

function MarketEncounter:drawCard(card, x, y, isSelected)
    -- Draw card background
    if isSelected then
        love.graphics.setColor(0.3, 0.3, 0.3, 1)
    else
        love.graphics.setColor(0.2, 0.2, 0.2, 1)
    end
    love.graphics.rectangle('fill', x, y, CARD_WIDTH, CARD_HEIGHT)
    
    -- Draw card border
    if isSelected then
        love.graphics.setColor(1, 1, 0, 1)  -- Yellow border for selected
        love.graphics.setLineWidth(3)
    else
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        love.graphics.setLineWidth(1)
    end
    love.graphics.rectangle('line', x, y, CARD_WIDTH, CARD_HEIGHT)
    
    -- Draw card content
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Card name
    love.graphics.printf(
        card.name,
        x + 10,
        y + 20,
        CARD_WIDTH - 20,
        'center'
    )
    
    -- Card type
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.printf(
        card.cardType,
        x + 10,
        y + 50,
        CARD_WIDTH - 20,
        'center'
    )
    
    -- Cost
    love.graphics.setColor(1, 0.8, 0, 1)  -- Gold color for cost
    love.graphics.printf(
        "$" .. card.cost,
        x + 10,
        y + 80,
        CARD_WIDTH - 20,
        'center'
    )
    
    -- Description
    love.graphics.setColor(0.9, 0.9, 0.9, 1)
    love.graphics.printf(
        card.description,
        x + 10,
        y + CARD_HEIGHT - 60,
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
    local card = self.state.availableCards[index]
    if not card then return end  -- Safety check

    if card.name == "Skip Market" then
        -- Skip card is free and just resolves the encounter
        self:resolveEncounter()
        return
    end

    if self.state.cash >= card.cost then
        -- Add to player's deck
        gameState.currentDeck:addCard(card)
        -- Deduct cost
        self.state.cash = self.state.cash - card.cost
        gameState.cash = self.state.cash
        -- Remove from available cards
        table.remove(self.state.availableCards, index)
        
        -- Adjust selection index if needed
        if self.state.selectedIndex > #self.state.availableCards then
            self.state.selectedIndex = #self.state.availableCards
        end
        
        -- Resolve the encounter after successful purchase
        self:resolveEncounter()
    else
        -- Optional: Add feedback for insufficient funds
        -- Could add a small message or visual indicator here
    end
end

function MarketEncounter:draw()
    -- Draw the market title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(self.state.title, 0, 20, love.graphics.getWidth(), 'center')
    
    -- Draw cash amount
    love.graphics.printf(
        "Cash: $" .. self.state.cash,
        0,
        50,
        love.graphics.getWidth(),
        'center'
    )

    -- Draw cards
    for i, card in ipairs(self.state.availableCards) do
        local row = math.floor((i-1) / CARDS_PER_ROW)
        local col = (i-1) % CARDS_PER_ROW
        
        local x = (love.graphics.getWidth() - (CARDS_PER_ROW * (CARD_WIDTH + CARD_SPACING))) / 2 
            + col * (CARD_WIDTH + CARD_SPACING)
        local y = START_Y + row * (CARD_HEIGHT + CARD_SPACING)
        
        -- Highlight selected card
        if i == self.state.selectedIndex then
            love.graphics.setColor(1, 1, 0, 1)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
        
        -- Draw card
        love.graphics.rectangle('line', x, y, CARD_WIDTH, CARD_HEIGHT)
        
        -- Draw card contents
        love.graphics.printf(
            card.name,
            x + 10,
            y + 20,
            CARD_WIDTH - 20,
            'center'
        )
        
        -- Draw cost
        love.graphics.printf(
            "$" .. (card.cost or 0),
            x + 10,
            y + CARD_HEIGHT - 40,
            CARD_WIDTH - 20,
            'center'
        )
    end

    -- Draw help text for deck viewing
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.printf(
        "Press TAB to view your deck",
        0,
        love.graphics.getHeight() - 30,
        love.graphics.getWidth(),
        'center'
    )
end

return MarketEncounter







