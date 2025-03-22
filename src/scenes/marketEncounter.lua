local Encounter = require('src.scenes.encounter')
local MarketEncounter = setmetatable({}, Encounter)
MarketEncounter.__index = MarketEncounter

-- Card display constants
local CARD_WIDTH = 160
local CARD_HEIGHT = 200
local CARD_SPACING = 20
local CARDS_PER_ROW = 4

function MarketEncounter.new()
    local self = setmetatable({}, MarketEncounter)
    self.state = {
        availableCards = {},  -- Cards currently for sale
        selectedIndex = 1,    -- Currently selected card
        cash = 0,            -- Initialize with 0
        title = "Market"     -- Will be set based on market type
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
    local numCards = #self.state.availableCards
    local totalOptions = numCards + 1  -- +1 for leave button
    
    if love.keyboard.wasPressed('left') then
        self.state.selectedIndex = self.state.selectedIndex - 1
        if self.state.selectedIndex < 1 then 
            self.state.selectedIndex = totalOptions
        end
    end
    
    if love.keyboard.wasPressed('right') then
        self.state.selectedIndex = self.state.selectedIndex + 1
        if self.state.selectedIndex > totalOptions then
            self.state.selectedIndex = 1
        end
    end
    
    if love.keyboard.wasPressed('return') then
        if self.state.selectedIndex > numCards then
            -- Selected "Leave" option
            gameState.cash = self.state.cash
            sceneManager:switch(gameState.previousScene or 'mainMenu')
        else
            -- Try to buy selected card
            self:tryPurchase(self.state.selectedIndex)
        end
    end
end

function MarketEncounter:tryPurchase(index)
    local card = self.state.availableCards[index]
    if self.state.cash >= card.cost then
        -- Add to player's deck
        gameState.currentDeck:addCard(card)
        -- Deduct cost
        self.state.cash = self.state.cash - card.cost
        gameState.cash = self.state.cash
        -- Remove from available cards
        table.remove(self.state.availableCards, index)
        -- Reset selection if needed
        if self.state.selectedIndex > #self.state.availableCards then
            self.state.selectedIndex = #self.state.availableCards + 1
        end
        
        -- Resolve the encounter after successful purchase
        self:resolveEncounter()
    end
end

function MarketEncounter:draw()
    -- Draw title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(
        self.state.title,
        0,
        30,
        love.graphics.getWidth(),
        'center'
    )
    
    -- Draw cash
    love.graphics.setColor(1, 0.8, 0, 1)
    love.graphics.printf(
        string.format("Cash: $%d", self.state.cash),
        -20,
        30,
        love.graphics.getWidth(),
        'right'
    )

    -- Calculate layout and draw cards
    local totalWidth = CARDS_PER_ROW * (CARD_WIDTH + CARD_SPACING) - CARD_SPACING
    local startX = (love.graphics.getWidth() - totalWidth) / 2
    local startY = 100

    for i, card in ipairs(self.state.availableCards) do
        local row = math.floor((i-1) / CARDS_PER_ROW)
        local col = (i-1) % CARDS_PER_ROW
        
        local x = startX + col * (CARD_WIDTH + CARD_SPACING)
        local y = startY + row * (CARD_HEIGHT + CARD_SPACING)
        
        self:drawCard(card, x, y, i == self.state.selectedIndex)
    end
    
    -- Draw "Leave" button
    local leaveY = startY + (math.ceil(#self.state.availableCards / CARDS_PER_ROW)) * (CARD_HEIGHT + CARD_SPACING) + 20
    
    if self.state.selectedIndex > #self.state.availableCards then
        love.graphics.setColor(1, 1, 0, 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    love.graphics.rectangle(
        'line',
        love.graphics.getWidth() / 2 - 100,
        leaveY,
        200,
        40
    )
    
    love.graphics.printf(
        "Leave Market",
        love.graphics.getWidth() / 2 - 100,
        leaveY + 10,
        200,
        'center'
    )
end

return MarketEncounter


