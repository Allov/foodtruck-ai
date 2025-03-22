local Scene = require('src.scenes.scene')
local Encounter = setmetatable({}, Scene)
Encounter.__index = Encounter

function Encounter.new()
    local self = setmetatable({}, Encounter)
    return self
end

function Encounter:init()
    self.encounterTypes = {
        CARD_BATTLE = "card_battle",
        BENEFICIAL = "beneficial",
        NEGATIVE = "negative",
        MARKET = "market",
        LORE = "lore"
    }
    
    self.state = {
        type = nil,
        title = "",
        description = "",
        options = {},
        currentOption = 1
    }
end

function Encounter:enter()
    -- Use the encounter type from game state
    if gameState.currentEncounter then
        self.state.type = gameState.currentEncounter
        -- Generate encounter based on type
        if self.state.type == "card_battle" then
            self:setupCardBattle()
        elseif self.state.type == "beneficial" then
            self:setupBeneficial()
        elseif self.state.type == "negative" then
            self:setupNegative()
        elseif self.state.type == "market" then
            self:setupMarket()
        elseif self.state.type == "lore" then
            self:setupLore()
        end
    else
        -- Fallback to random encounter if no type specified
        self:generateEncounter()
    end
end

function Encounter:generateEncounter()
    -- Random number between 1 and 100
    local roll = love.math.random(100)
    
    if roll <= 30 then
        self:setupCardBattle()
    elseif roll <= 50 then
        self:setupBeneficial()
    elseif roll <= 65 then
        self:setupNegative()
    elseif roll <= 85 then
        self:setupMarket()
    else
        self:setupLore()
    end
end

function Encounter:setupCardBattle()
    self.state.type = self.encounterTypes.CARD_BATTLE
    -- Example setup
    self.state.title = "Food Critic Challenge"
    self.state.description = "A renowned food critic has arrived!"
    self.state.options = {
        "Accept the challenge",
        "Try to negotiate",
        "Decline politely"
    }
end

function Encounter:setupBeneficial()
    self.state.type = self.encounterTypes.BENEFICIAL
    -- Similar setup for beneficial events
end

function Encounter:setupNegative()
    self.state.type = self.encounterTypes.NEGATIVE
    -- Similar setup for negative events
end

function Encounter:setupMarket()
    self.state.type = self.encounterTypes.MARKET
    -- Similar setup for market events
end

function Encounter:setupLore()
    self.state.type = self.encounterTypes.LORE
    -- Similar setup for lore events
end

function Encounter:update(dt)
    if love.keyboard.wasPressed('up') then
        self.state.currentOption = self.state.currentOption - 1
        if self.state.currentOption < 1 then 
            self.state.currentOption = #self.state.options 
        end
    end
    
    if love.keyboard.wasPressed('down') then
        self.state.currentOption = self.state.currentOption + 1
        if self.state.currentOption > #self.state.options then 
            self.state.currentOption = 1 
        end
    end
    
    if love.keyboard.wasPressed('return') then
        self:resolveEncounter()
    end
    
    if love.keyboard.wasPressed('escape') then
        sceneManager:switch('provinceMap')
    end
end

function Encounter:draw()
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Draw encounter title
    love.graphics.printf(
        self.state.title,
        0,
        50,
        love.graphics.getWidth(),
        'center'
    )
    
    -- Draw description
    love.graphics.printf(
        self.state.description,
        50,
        120,
        love.graphics.getWidth() - 100,
        'center'
    )
    
    -- Draw options
    for i, option in ipairs(self.state.options) do
        if i == self.state.currentOption then
            love.graphics.setColor(1, 1, 0, 1)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
        
        love.graphics.printf(
            option,
            100,
            250 + (i * 40),
            love.graphics.getWidth() - 200,
            'left'
        )
    end
end

function Encounter:resolveEncounter()
    -- Get the province map scene
    local provinceMap = sceneManager.scenes['provinceMap']
    
    -- Mark the current node as completed
    provinceMap:markNodeCompleted(gameState.currentNodeLevel, gameState.currentNodeIndex)
    
    -- Clear the current encounter
    gameState.currentEncounter = nil
    
    -- Return to the map
    sceneManager:switch('provinceMap')
end

return Encounter


