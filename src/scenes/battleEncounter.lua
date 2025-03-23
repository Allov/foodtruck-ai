local Encounter = require('src.scenes.encounter')
local Card = require('src.cards.card')

local BattleEncounter = {}
BattleEncounter.__index = BattleEncounter
BattleEncounter.__name = "battleEncounter"
setmetatable(BattleEncounter, Scene)

BattleEncounter.PHASES = {
    PREPARATION = "PREPARATION",
    COOKING = "COOKING",
    JUDGING = "JUDGING",
    RESULTS = "RESULTS"
}

BattleEncounter.ACTIONS = {
    SELECT = "SELECT",
    DISCARD = "DISCARD",
    COOK = "COOK"
}

function BattleEncounter.new()
    local self = setmetatable(Encounter.new(), BattleEncounter)
    self.instanceId = tostring(self):match('table: (.+)')
    
    self.state = {
        currentPhase = BattleEncounter.PHASES.PREPARATION,
        currentAction = BattleEncounter.ACTIONS.SELECT,
        selectedCards = {},
        handCards = {},
        discardPile = {},
        selectedForDiscard = {},
        selectedCardIndex = 1,
        currentCookingIndex = 1,
        timeRemaining = 60,
        currentScore = 0,
        roundNumber = 1,
        maxRounds = 3,
        actionFeedback = nil,
        comboMultiplier = 1
    }
    -- Remove maxSelectedCards from here since it will be set by setupBattleParameters
    
    -- Call setupBattleParameters during initialization
    self:setupBattleParameters()
    
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
    
    -- Initialize enemy based on battle type
    self.state.enemy = {
        name = self.state.battleType == "food_critic" and "Food Critic" or "Lunch Rush",
        specialty = self.state.battleType == "food_critic" and "Fine Dining" or "Speed Service",
        targetScore = self.state.battleType == "food_critic" and 100 or 150,
        preferences = {
            -- Preferences affect scoring
            primary = self.state.battleType == "food_critic" and "quality" or "speed",
            bonus = self.state.battleType == "food_critic" and "presentation" or "efficiency"
        },
        satisfaction = 100  -- Starts at 100, changes based on performance
    }
    
    -- Use the current deck directly
    self.state.deck = gameState.currentDeck
    
    -- Draw initial hand
    self:drawInitialHand()
    
    -- Set battle parameters based on type
    self:setupBattleParameters()
    
    -- Initialize first card as selected
    if #self.state.handCards > 0 then
        self.state.selectedCardIndex = 1
        local firstCard = self.state.handCards[1]
        if firstCard then
            firstCard:setSelected(true)
        end
    end
end

function BattleEncounter:setupBattleParameters()
    local battleConfigs = {
        food_critic = {
            rounds = 3,
            timePerRound = 60,
            maxCards = 5,  -- Updated to 5 cards
            targetScore = 100
        },
        rush_hour = {
            rounds = 5,
            timePerRound = 45,
            maxCards = 5,  -- Updated to 5 cards
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
    if self.state.currentAction == self.ACTIONS.SELECT then
        self:handleCardSelection()
    elseif self.state.currentAction == self.ACTIONS.DISCARD then
        self:handleCardDiscard()
    end
end

function BattleEncounter:handleCardSelection()
    if love.keyboard.wasPressed('left') then
        self:selectPreviousCard()
    elseif love.keyboard.wasPressed('right') then
        self:selectNextCard()
    elseif love.keyboard.wasPressed('space') then
        self:toggleCardSelection()
    elseif love.keyboard.wasPressed('return') and #self.state.selectedCards > 0 then
        self:transitionToPhase(self.PHASES.COOKING)
    end
    -- Discard action disabled
    --[[ elseif love.keyboard.wasPressed('d') then
        self:discardCurrentCard()
    ]]
end

function BattleEncounter:discardCurrentCard()
    if #self.state.handCards == 0 then return end
    
    local card = self.state.handCards[self.state.selectedCardIndex]
    if not card then return end
    
    print("[BattleEncounter] Before discard - Hand size:", #self.state.handCards)
    
    -- Remove current card and add to discard pile
    self:removeCardFromHand(self.state.selectedCardIndex)
    self.state.deck:discard(card)
    
    -- Draw and add new card
    self:drawAndAddNewCard(self.state.selectedCardIndex)
    
    -- Update selection
    self:adjustSelectionAfterDiscard()
    
    print("[BattleEncounter] After operations - Hand size:", #self.state.handCards)
end

function BattleEncounter:removeCardFromHand(index)
    table.remove(self.state.handCards, index)
end

function BattleEncounter:drawAndAddNewCard(index)
    local newCard = self.state.deck:draw()
    if newCard then
        table.insert(self.state.handCards, index, newCard)
    end
end

function BattleEncounter:adjustSelectionAfterDiscard()
    -- Ensure selected index is within bounds
    if self.state.selectedCardIndex > #self.state.handCards then
        self.state.selectedCardIndex = #self.state.handCards
    end
    
    -- Update visual selection state of cards
    for i, handCard in ipairs(self.state.handCards) do
        handCard:setSelected(i == self.state.selectedCardIndex)
    end
end

function BattleEncounter:handleCardDiscard()
    if love.keyboard.wasPressed('escape') then
        self.state.currentAction = self.ACTIONS.SELECT
    elseif love.keyboard.wasPressed('space') then
        self:discardAndDrawNew()
    end
end

function BattleEncounter:discardAndDrawNew()
    local card = self.state.handCards[self.state.selectedCardIndex]
    if not card then return end

    -- Remove from hand
    table.remove(self.state.handCards, self.state.selectedCardIndex)
    
    -- Add to deck's discard pile (not just the battle state discard pile)
    self.state.deck:discard(card)
    
    -- Draw a new card from the deck
    local newCard = self.state.deck:draw()
    if newCard then
        table.insert(self.state.handCards, self.state.selectedCardIndex, newCard)
    end
    
    -- Adjust selected card index if needed
    if self.state.selectedCardIndex > #self.state.handCards then
        self.state.selectedCardIndex = #self.state.handCards
    end
    
    -- Update card selection
    for i, handCard in ipairs(self.state.handCards) do
        handCard:setSelected(i == self.state.selectedCardIndex)
    end
    
    -- Return to selection mode
    self.state.currentAction = self.ACTIONS.SELECT
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
    for i, selectedCard in ipairs(self.state.selectedCards) do
        if selectedCard == card then
            isSelected = true
            -- Remove from selected cards
            table.remove(self.state.selectedCards, i)
            card:setLocked(false)
            break
        end
    end
    
    -- If not selected and we haven't reached max cards, add it
    if not isSelected and #self.state.selectedCards < self.state.maxSelectedCards then
        table.insert(self.state.selectedCards, card)
        card:setLocked(true)
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
    -- Calculate success based on enemy preferences
    local baseChance = 70
    local enemy = self.state.enemy
    
    -- Modify chance based on card type and enemy preferences
    if card.type == enemy.preferences.primary then
        baseChance = baseChance + 15
    elseif card.type == enemy.preferences.bonus then
        baseChance = baseChance + 10
    end
    
    -- Additional modifiers based on card quality and technique level
    if card.quality then
        baseChance = baseChance + (card.quality * 2)
    end
    
    -- Roll for success
    local roll = love.math.random(100)
    local success = roll <= baseChance
    
    -- Apply effects
    if success then
        local scoreGain = (card.quality or 10)
        -- Bonus points if matching preferences
        if card.type == enemy.preferences.primary then
            scoreGain = scoreGain * 1.5
        elseif card.type == enemy.preferences.bonus then
            scoreGain = scoreGain * 1.25
        end
        
        self.state.currentScore = self.state.currentScore + scoreGain
        -- Adjust satisfaction based on performance
        self.state.enemy.satisfaction = math.min(100, self.state.enemy.satisfaction + 5)
    else
        self.state.currentScore = self.state.currentScore - 5
        self.state.enemy.satisfaction = math.max(0, self.state.enemy.satisfaction - 10)
    end
    
    return success
end

function BattleEncounter:draw()
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
    -- Draw enemy stats at the top
    if self.state.enemy then
        love.graphics.setColor(1, 1, 1, 1)
        local enemyStatsY = 10
        local enemyNameY = enemyStatsY
        local enemyDetailsY = enemyNameY + 30
        local enemySatisfactionY = enemyDetailsY + 30
        
        -- Enemy name
        love.graphics.printf(
            self.state.enemy.name,
            0,
            enemyNameY,
            love.graphics.getWidth(),
            'center'
        )
        
        -- Enemy details
        love.graphics.printf(
            string.format("Specialty: %s | Prefers: %s, %s", 
                self.state.enemy.specialty,
                self.state.enemy.preferences.primary,
                self.state.enemy.preferences.bonus),
            0,
            enemyDetailsY,
            love.graphics.getWidth(),
            'center'
        )
        
        -- Satisfaction level
        love.graphics.printf(
            string.format("Satisfaction: %d%%", self.state.enemy.satisfaction),
            0,
            enemySatisfactionY,
            love.graphics.getWidth(),
            'center'
        )
    end

    -- Battle progress info
    local topY = self.state.enemy and 160 or 10  -- Adjust Y position based on whether enemy info is shown
    
    love.graphics.printf(
        "Round " .. self.state.roundNumber .. "/" .. self.state.maxRounds,
        0,
        topY,
        love.graphics.getWidth(),
        'center'
    )
    
    love.graphics.printf(
        "Score: " .. self.state.currentScore,
        0,
        topY + 30,
        love.graphics.getWidth(),
        'center'
    )
    
    love.graphics.printf(
        "Phase: " .. self.state.currentPhase,
        0,
        topY + 60,
        love.graphics.getWidth(),
        'center'
    )
    
    if self.state.currentPhase == BattleEncounter.PHASES.COOKING then
        love.graphics.printf(
            string.format("Time: %.1f", self.state.timeRemaining),
            0,
            topY + 90,
            love.graphics.getWidth(),
            'center'
        )
    end

    -- Card dimensions and layout constants
    local cardWidth, cardHeight = Card.getDimensions()
    local padding = 20
    local stackOffset = 2  -- How much each card in the stack is offset
    local pileSpacing = 20 -- Space between draw and discard piles
    
    -- Position both piles at the bottom right
    local pilesY = love.graphics.getHeight() - cardHeight - padding
    local drawPileX = love.graphics.getWidth() - (cardWidth * 2 + pileSpacing + padding)
    local discardPileX = love.graphics.getWidth() - (cardWidth + padding)
    
    -- Draw pile
    if #self.state.deck.drawPile > 0 then
        -- Draw stack of cards from bottom to top
        local numCardsToShow = math.min(5, #self.state.deck.drawPile)
        for i = numCardsToShow, 1, -1 do
            local cardX = drawPileX - (i * stackOffset)
            local cardY = pilesY - (i * stackOffset)
            
            love.graphics.setColor(1, 1, 1, 1)
            Card.new(0, "", ""):drawBack(cardX, cardY)
        end
    else
        -- Draw empty pile outline
        love.graphics.setColor(0.4, 0.4, 0.4, 0.5)
        love.graphics.rectangle('line', drawPileX, pilesY, cardWidth, cardHeight)
    end

    -- Draw pile count
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(
        "Draw: " .. #self.state.deck.drawPile,
        drawPileX,
        pilesY - 25,
        cardWidth,
        'center'
    )

    -- Discard pile
    if #self.state.deck.discardPile > 0 then
        local numCardsToShow = math.min(5, #self.state.deck.discardPile)
        for i = numCardsToShow, 1, -1 do
            local cardX = discardPileX - (i * stackOffset)
            local cardY = pilesY - (i * stackOffset)
            
            love.graphics.setColor(1, 1, 1, 1)
            Card.new(0, "", ""):drawBack(cardX, cardY)
        end
    else
        -- Draw empty pile outline
        love.graphics.setColor(0.4, 0.4, 0.4, 0.5)
        love.graphics.rectangle('line', discardPileX, pilesY, cardWidth, cardHeight)
    end

    -- Discard pile count
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(
        "Discard: " .. #self.state.deck.discardPile,
        discardPileX,
        pilesY - 25,
        cardWidth,
        'center'
    )
end

function BattleEncounter:drawInitialHand()
    -- Clear current hand
    self.state.handCards = {}
    self.state.selectedCardIndex = 1  -- Reset selection index
    
    -- Draw 8 cards from the current deck
    local cardsToDraw = 8
    for i = 1, cardsToDraw do
        local card = self.state.deck:draw()
        if card then
            table.insert(self.state.handCards, card)
            -- Select the first card
            if i == 1 then
                card:setSelected(true)
            end
        else
            break
        end
    end
end

function BattleEncounter:drawPreparationPhase()
    local cardWidth, cardHeight = Card.getDimensions()
    local padding = 20
    local baseY = love.graphics.getHeight() - cardHeight - padding
    
    -- Calculate available width for hand cards (leaving space for piles)
    local pilesWidth = (cardWidth * 2 + 20 + padding * 2) -- Two piles plus spacing and padding
    local availableWidth = love.graphics.getWidth() - pilesWidth - padding
    
    -- Calculate overlap amount based on number of cards
    local overlapAmount = math.min(
        cardWidth * 0.8,  -- Maximum overlap (80% of card width)
        (cardWidth * #self.state.handCards - availableWidth) / (#self.state.handCards - 1)
    )
    
    -- Start X position from the left with padding
    local startX = padding
    
    -- Calculate curve parameters
    local curveHeight = 30
    local middleIndex = math.ceil(#self.state.handCards / 2)
    
    -- First draw non-selected cards
    for i = #self.state.handCards, 1, -1 do
        if i ~= self.state.selectedCardIndex then
            local card = self.state.handCards[i]
            local x = startX + ((i-1) * (cardWidth - overlapAmount))
            
            -- Modified curve calculation
            local progress = (i - 1) / (#self.state.handCards - 1)
            local curveOffset = math.sin(progress * math.pi) * curveHeight
            local y = baseY - curveOffset
            
            local rotation = math.rad((i - middleIndex) * 2)
            
            if card.isLocked then
                love.graphics.setColor(0.2, 0.8, 0.2, 0.3)
                love.graphics.rectangle('fill', x, y, cardWidth, cardHeight)
            end
            
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.push()
            love.graphics.translate(x + cardWidth/2, y + cardHeight/2)
            love.graphics.rotate(rotation)
            love.graphics.translate(-cardWidth/2, -cardHeight/2)
            card:draw(0, 0)
            love.graphics.pop()
        end
    end
    
    -- Then draw selected card
    if self.state.selectedCardIndex > 0 and self.state.selectedCardIndex <= #self.state.handCards then
        local card = self.state.handCards[self.state.selectedCardIndex]
        local i = self.state.selectedCardIndex
        local x = startX + ((i-1) * (cardWidth - overlapAmount))
        
        local progress = (i - 1) / (#self.state.handCards - 1)
        local curveOffset = math.sin(progress * math.pi) * curveHeight
        local y = baseY - curveOffset - 20
        
        local rotation = math.rad((i - middleIndex) * 2)
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.push()
        love.graphics.translate(x + cardWidth/2, y + cardHeight/2)
        love.graphics.rotate(rotation)
        love.graphics.translate(-cardWidth/2, -cardHeight/2)
        card:draw(0, 0)
        love.graphics.pop()
    end
    
    -- Draw UI elements
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(
        string.format("Selected: %d/%d", #self.state.selectedCards, self.state.maxSelectedCards),
        0,
        baseY - 70,
        love.graphics.getWidth(),
        'center'
    )
    
    -- Draw instructions at the very bottom
    love.graphics.printf(
        "← → to move  |  SPACE to select  |  ENTER to confirm",
        0,
        love.graphics.getHeight() - 30,
        love.graphics.getWidth(),
        'center'
    )
end

function BattleEncounter:drawDiscardUI()
    -- Draw semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw discard mode instructions
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(
        "DISCARD MODE\nSpace: Select cards to discard\nEnter: Confirm\nEsc: Cancel",
        0,
        50,
        love.graphics.getWidth(),
        'center'
    )
    
    -- Highlight cards selected for discard
    for _, card in ipairs(self.state.selectedForDiscard) do
        -- Draw red outline or overlay on selected cards
        -- Implementation depends on your card drawing system
    end
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

function BattleEncounter:selectNextCard()
    if #self.state.handCards == 0 then return end
    
    -- Deselect current card
    local currentCard = self.state.handCards[self.state.selectedCardIndex]
    if currentCard then
        currentCard:setSelected(false)
    end
    
    -- Update index
    self.state.selectedCardIndex = self.state.selectedCardIndex + 1
    if self.state.selectedCardIndex > #self.state.handCards then
        self.state.selectedCardIndex = 1
    end
    
    -- Select new card
    local newCard = self.state.handCards[self.state.selectedCardIndex]
    if newCard then
        newCard:setSelected(true)
    end
end

function BattleEncounter:selectPreviousCard()
    if #self.state.handCards == 0 then return end
    
    -- Deselect current card
    local currentCard = self.state.handCards[self.state.selectedCardIndex]
    if currentCard then
        currentCard:setSelected(false)
    end
    
    -- Update index
    self.state.selectedCardIndex = self.state.selectedCardIndex - 1
    if self.state.selectedCardIndex < 1 then
        self.state.selectedCardIndex = #self.state.handCards
    end
    
    -- Select new card
    local newCard = self.state.handCards[self.state.selectedCardIndex]
    if newCard then
        newCard:setSelected(true)
    end
end

function BattleEncounter:transitionToPhase(newPhase)
    -- Validate phase
    if not self.PHASES[newPhase] then
        return
    end

    -- Handle cleanup of current phase
    if self.state.currentPhase == self.PHASES.PREPARATION then
        -- Reset any preparation phase specific states
        self.state.currentAction = self.ACTIONS.SELECT
        self.state.selectedForDiscard = {}
    elseif self.state.currentPhase == self.PHASES.COOKING then
        -- Reset cooking specific states
        self.state.currentCookingIndex = 1
    end

    -- Set up new phase
    if newPhase == self.PHASES.COOKING then
        -- Initialize cooking phase
        self.state.timeRemaining = 60
        self.state.currentCookingIndex = 1
    elseif newPhase == self.PHASES.JUDGING then
        -- Calculate final score for the round
        self:calculateRoundScore()
    end

    -- Update the phase
    self.state.currentPhase = newPhase
end

function BattleEncounter:calculateRoundScore()
    -- Basic score calculation
    local baseScore = 0
    for _, card in ipairs(self.state.selectedCards) do
        baseScore = baseScore + (card.value or 0)
    end
    
    -- Apply combo multiplier
    local finalScore = baseScore * self.state.comboMultiplier
    
    -- Update total score
    self.state.currentScore = self.state.currentScore + finalScore
    
    -- Reset combo multiplier for next round
    self.state.comboMultiplier = 1
end

return BattleEncounter  -- NOT return true/false













