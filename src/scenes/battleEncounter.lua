local Encounter = require('src.scenes.encounter')
local BattleEncounter = {}
BattleEncounter.__index = BattleEncounter
BattleEncounter.__name = "battleEncounter"
setmetatable(BattleEncounter, Scene)

BattleEncounter.PHASES = {
    PREPARATION = "PREPARATION", -- Player selects cards
    COOKING = "COOKING",       -- Active cooking phase with timer
    JUDGING = "JUDGING",      -- Results evaluation
    RESULTS = "RESULTS"       -- Show round/battle results
}

function BattleEncounter.new()
    local self = setmetatable(Encounter.new(), BattleEncounter)
    self.instanceId = tostring(self):match('table: (.+)')
    
    self.state = {
        currentPhase = BattleEncounter.PHASES.PREPARATION,
        selectedCards = {},
        handCards = {},
        selectedCardIndex = 1,
        currentCookingIndex = 1,
        timeRemaining = 60,
        currentScore = 0,
        maxSelectedCards = 3,
        roundNumber = 1,
        maxRounds = 3
    }
    
    if self.init then
        self:init()
    end
    
    return self
end

function BattleEncounter:init()
    -- Any initialization specific to BattleEncounter
end

function BattleEncounter:enter()
    print("[BattleEncounter:enter] Entering instance", self.instanceId)
    -- Get battle configuration from gameState
    self.state.battleType = gameState.currentBattleType or "food_critic"
    self.state.difficulty = gameState.battleDifficulty or "normal"
    
    -- Setup initial hand from player's deck
    self:drawInitialHand()
    
    -- Set battle parameters based on type
    self:setupBattleParameters()
    
    print("[BattleEncounter:enter] After setup for instance", self.instanceId, "state:", self.state)
end

function BattleEncounter:setupBattleParameters()
    local battleConfigs = {
        food_critic = {
            rounds = 3,
            timePerRound = 60,
            maxCards = 3,
            targetScore = 100
        },
        rush_hour = {
            rounds = 5,
            timePerRound = 45,
            maxCards = 2,
            targetScore = 150
        }
        -- Add more battle types as needed
    }
    
    local config = battleConfigs[self.state.battleType] or battleConfigs.food_critic
    self.state.maxRounds = config.rounds
    self.state.timeRemaining = config.timePerRound
    self.state.maxSelectedCards = config.maxCards
    self.state.targetScore = config.targetScore
end

function BattleEncounter:endBattle(won)
    -- Store battle results
    gameState.battleResults = {
        won = won,
        score = self.state.currentScore,
        rounds = self.state.roundNumber
    }
    
    -- Mark node as completed if from province map
    if gameState.currentNodeLevel and gameState.currentNodeIndex then
        local provinceMap = sceneManager.scenes['provinceMap']
        provinceMap:markNodeCompleted(gameState.currentNodeLevel, gameState.currentNodeIndex)
    end
    
    -- Clear current encounter
    gameState.currentEncounter = nil
    
    -- Return to previous scene
    sceneManager:switch(gameState.previousScene or 'provinceMap')
end

function BattleEncounter:isBattleComplete()
    return self.state.roundNumber > self.state.maxRounds or
           self.state.currentScore >= self.state.targetScore
end

function BattleEncounter:update(dt)
    Encounter.update(self, dt)
    
    if self.state.showingConfirmDialog then
        return
    end

    -- Phase-specific updates
    if self.state.currentPhase == BattleEncounter.PHASES.PREPARATION then
        self:updatePreparationPhase()
    elseif self.state.currentPhase == BattleEncounter.PHASES.COOKING then
        self:updateCookingPhase(dt)
    elseif self.state.currentPhase == BattleEncounter.PHASES.JUDGING then
        self:updateJudgingPhase()
    elseif self.state.currentPhase == BattleEncounter.PHASES.RESULTS then
        self:updateResultsPhase()
    end
end

function BattleEncounter:updatePreparationPhase()
    -- Handle card selection
    if love.keyboard.wasPressed('left') then
        self:selectPreviousCard()
    elseif love.keyboard.wasPressed('right') then
        self:selectNextCard()
    elseif love.keyboard.wasPressed('space') then
        self:toggleCardSelection()
    elseif love.keyboard.wasPressed('return') and #self.state.selectedCards > 0 then
        self:transitionToPhase(BattleEncounter.PHASES.COOKING)
    end
end

function BattleEncounter:updateCookingPhase(dt)
    -- Update timer
    self.state.timeRemaining = self.state.timeRemaining - dt
    
    -- Handle cooking actions
    if love.keyboard.wasPressed('space') then
        self:performCookingAction()
    end
    
    -- Check for phase end
    if self.state.timeRemaining <= 0 then
        self:transitionToPhase(BattleEncounter.PHASES.JUDGING)
    end
end

function BattleEncounter:updateJudgingPhase()
    -- Auto-transition after showing results
    if love.keyboard.wasPressed('return') then
        self:transitionToPhase(BattleEncounter.PHASES.RESULTS)
    end
end

function BattleEncounter:updateResultsPhase()
    if love.keyboard.wasPressed('return') then
        if self:isBattleComplete() then
            self:endBattle()
        else
            self:startNextRound()
        end
    end
end

function BattleEncounter:toggleCardSelection()
    local card = self.state.handCards[self.state.selectedCardIndex]
    if not card then return end
    
    -- Check if card is already selected
    local isSelected = false
    local selectedIndex = nil
    for i, selectedCard in ipairs(self.state.selectedCards) do
        if selectedCard == card then
            isSelected = true
            selectedIndex = i
            break
        end
    end
    
    -- Toggle selection
    if isSelected then
        table.remove(self.state.selectedCards, selectedIndex)
    else
        -- Only add if we haven't reached max cards
        if #self.state.selectedCards < self.state.maxSelectedCards then
            table.insert(self.state.selectedCards, card)
        end
    end
end

function BattleEncounter:performCookingAction()
    local currentCard = self.state.selectedCards[self.state.currentCookingIndex]
    if not currentCard then return end
    
    -- Apply card effects
    local success = self:applyCookingEffect(currentCard)
    
    -- Move to next card
    if success then
        self.state.currentCookingIndex = self.state.currentCookingIndex + 1
        if self.state.currentCookingIndex > #self.state.selectedCards then
            self.state.currentCookingIndex = 1
        end
    end
end

function BattleEncounter:applyCookingEffect(card)
    -- Calculate base success chance
    local baseChance = 70
    
    -- Modify chance based on card type and conditions
    if card.type == "ingredient" then
        baseChance = baseChance + 10
    elseif card.type == "technique" then
        baseChance = baseChance + (self.state.skillLevel or 0)
    end
    
    -- Roll for success
    local roll = love.math.random(100)
    local success = roll <= baseChance
    
    -- Apply effects
    if success then
        self.state.currentScore = self.state.currentScore + (card.quality or 10)
    else
        self.state.currentScore = self.state.currentScore - 5
    end
    
    return success
end

function BattleEncounter:draw()
    print("[BattleEncounter:draw] Drawing instance", self.instanceId, "state:", self.state)
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Draw phase-specific elements
    if self.state.currentPhase == BattleEncounter.PHASES.PREPARATION then
        self:drawPreparationPhase()
    elseif self.state.currentPhase == BattleEncounter.PHASES.COOKING then
        self:drawCookingPhase()
    elseif self.state.currentPhase == BattleEncounter.PHASES.JUDGING then
        self:drawJudgingPhase()
    elseif self.state.currentPhase == BattleEncounter.PHASES.RESULTS then
        self:drawResultsPhase()
    end
    
    -- Always draw common elements
    self:drawCommonElements()
end

function BattleEncounter:drawCommonElements()
    -- Draw round number
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(
        "Round " .. self.state.roundNumber .. "/" .. self.state.maxRounds,
        0,
        10,
        love.graphics.getWidth(),
        'center'
    )
    
    -- Draw current score
    love.graphics.printf(
        "Score: " .. self.state.currentScore,
        0,
        40,
        love.graphics.getWidth(),
        'center'
    )
    
    -- Draw current phase
    love.graphics.printf(
        "Phase: " .. self.state.currentPhase,
        0,
        70,
        love.graphics.getWidth(),
        'center'
    )
    
    -- If in cooking phase, draw timer
    if self.state.currentPhase == BattleEncounter.PHASES.COOKING then
        love.graphics.printf(
            string.format("Time: %.1f", self.state.timeRemaining),
            0,
            100,
            love.graphics.getWidth(),
            'center'
        )
    end
end

function BattleEncounter:drawInitialHand()
    -- Initialize empty hand
    self.state.handCards = {}
    
    -- Get player's deck from gameState
    local playerDeck = gameState.playerDeck or {}
    
    -- Draw initial cards (for example, 5 cards)
    local handSize = 5
    for i = 1, handSize do
        -- If deck is empty, break
        if #playerDeck == 0 then break end
        
        -- Random card from deck
        local randomIndex = love.math.random(#playerDeck)
        local card = table.remove(playerDeck, randomIndex)
        table.insert(self.state.handCards, card)
    end
end

function BattleEncounter:drawPreparationPhase()
    -- Draw hand cards
    local cardWidth = 100
    local cardHeight = 150
    local spacing = 20
    local startX = (love.graphics.getWidth() - ((cardWidth + spacing) * #self.state.handCards)) / 2
    
    for i, card in ipairs(self.state.handCards) do
        local x = startX + ((i-1) * (cardWidth + spacing))
        local y = love.graphics.getHeight() - cardHeight - 50
        
        -- Check if card is selected
        local isSelected = (i == self.state.selectedCardIndex)
        local isInSelectedCards = false
        for _, selectedCard in ipairs(self.state.selectedCards) do
            if selectedCard == card then
                isInSelectedCards = true
                break
            end
        end
        
        -- Draw card background
        if isSelected then
            love.graphics.setColor(0.3, 0.3, 0.3, 1)
        else
            love.graphics.setColor(0.2, 0.2, 0.2, 1)
        end
        love.graphics.rectangle('fill', x, y, cardWidth, cardHeight)
        
        -- Draw card border
        if isSelected then
            love.graphics.setColor(1, 1, 0, 1)
        elseif isInSelectedCards then
            love.graphics.setColor(0, 1, 0, 1)
        else
            love.graphics.setColor(0.8, 0.8, 0.8, 1)
        end
        love.graphics.rectangle('line', x, y, cardWidth, cardHeight)
        
        -- Draw card content
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(card.name or "Card", x, y + 20, cardWidth, 'center')
    end
    
    -- Draw instructions
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(
        "Select cards with SPACE (max " .. self.state.maxSelectedCards .. ")\nPress ENTER when ready",
        0,
        love.graphics.getHeight() - 30,
        love.graphics.getWidth(),
        'center'
    )
end

function BattleEncounter:drawCookingPhase()
    -- Draw active cards
    local cardWidth = 100
    local cardHeight = 150
    local spacing = 20
    local startX = (love.graphics.getWidth() - ((cardWidth + spacing) * #self.state.selectedCards)) / 2
    
    for i, card in ipairs(self.state.selectedCards) do
        local x = startX + ((i-1) * (cardWidth + spacing))
        local y = love.graphics.getHeight() - cardHeight - 50
        
        -- Highlight current cooking card
        if i == self.state.currentCookingIndex then
            love.graphics.setColor(0.3, 0.8, 0.3, 1)
        else
            love.graphics.setColor(0.2, 0.2, 0.2, 1)
        end
        love.graphics.rectangle('fill', x, y, cardWidth, cardHeight)
        
        -- Draw card content
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(card.name or "Card", x, y + 20, cardWidth, 'center')
    end
    
    -- Draw instructions
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(
        "Press SPACE to cook!",
        0,
        love.graphics.getHeight() - 30,
        love.graphics.getWidth(),
        'center'
    )
end

function BattleEncounter:drawJudgingPhase()
    -- Draw results
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(
        "Round Complete!\nScore: " .. self.state.currentScore .. "\nPress ENTER to continue",
        0,
        love.graphics.getHeight() / 2 - 50,
        love.graphics.getWidth(),
        'center'
    )
end

function BattleEncounter:drawResultsPhase()
    -- Draw final results
    love.graphics.setColor(1, 1, 1, 1)
    local message
    if self:isBattleComplete() then
        message = "Battle Complete!\n"
        message = message .. (self.state.currentScore >= self.state.targetScore and "Victory!" or "Defeat!")
        message = message .. "\nFinal Score: " .. self.state.currentScore
    else
        message = "Round " .. self.state.roundNumber .. " Complete!\n"
        message = message .. "Current Score: " .. self.state.currentScore .. "\n"
        message = message .. "Target Score: " .. self.state.targetScore
    end
    
    love.graphics.printf(
        message .. "\nPress ENTER to continue",
        0,
        love.graphics.getHeight() / 2 - 50,
        love.graphics.getWidth(),
        'center'
    )
end

return BattleEncounter  -- NOT return true/false













