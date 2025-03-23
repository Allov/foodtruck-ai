local Encounter = require('src.scenes.encounter')
local Card = require('src.cards.card')
local encounterConfigs = require('src.encounters.encounterConfigs')

local BattleEncounter = {}
BattleEncounter.__index = BattleEncounter
BattleEncounter.__name = "battleEncounter"
setmetatable(BattleEncounter, Scene)

local COLORS = {
    PRIMARY = {1, 0, 0, 1},      -- Red for battle theme
    TEXT = {1, 1, 1, 1},         -- White for regular text
    HIGHLIGHT = {1, 0.8, 0, 1},  -- Gold for important numbers
    SUCCESS = {0, 1, 0, 1},      -- Green for positive feedback
    FAILURE = {1, 0.3, 0.3, 1},  -- Red for negative feedback
    ACCENT = {1, 0.5, 0.5, 1},    -- Light red for accents
    DANGER = {1, 0, 0, 1}        -- Red for danger
}

local FONTS = {
    LARGE = love.graphics.newFont(24),
    MEDIUM = love.graphics.newFont(18),
    SMALL = love.graphics.newFont(14)
}

BattleEncounter.PHASES = {
    PREPARATION = "PREPARATION",  -- Select cards for your combination
    JUDGING = "JUDGING",         -- Calculate scores and effects
    RESULTS = "RESULTS"          -- Show round results and check win/loss
}

BattleEncounter.PHASE_TIMINGS = {
    JUDGING = 2.0,  -- Increased from 2.0 to 3.0 seconds
    CARD_SCORE_ANIMATION = 0.7,  -- Time per card animation (slightly longer than Card.ANIMATION.SCORE_DURATION)
    RESULTS = 0   -- Results phase duration
}

-- Remove ACTIONS as they're no longer needed
-- BattleEncounter.ACTIONS = { ... }

function BattleEncounter.new()
    local self = setmetatable(Encounter.new(), BattleEncounter)
    self.instanceId = tostring(self):match('table: (.+)')
    
    self.state = {
        currentPhase = BattleEncounter.PHASES.PREPARATION,
        selectedCards = {},
        handCards = {},
        discardPile = {},
        selectedCardIndex = 1,
        currentScore = 0,
        roundNumber = 1,
        maxRounds = 3,
        actionFeedback = nil,
        comboMultiplier = 1,
        viewingPile = nil,  -- 'draw' or 'discard' when viewing piles
        pileCardIndex = 1   -- Selected card index when viewing piles
    }
    
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
        specialty = self.state.battleType == "food_critic" and "Fine Dining" or "Speed Service"
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
            maxCards = 5,
            targetScore = 150
        },
        rush_hour = {
            rounds = 5,
            timePerRound = 60,
            maxCards = 5,
            targetScore = 100
        }
    }
    
    local config = battleConfigs[self.state.battleType] or battleConfigs.food_critic
    self.state.maxRounds = config.rounds
    self.state.timeRemaining = config.timePerRound
    self.state.maxSelectedCards = config.maxCards
    self.state.targetScore = config.targetScore
    
    -- Initialize enemy based on battle type
    self.state.enemy = {
        name = self.state.battleType == "food_critic" and "Food Critic" or "Lunch Rush",
        specialty = self.state.battleType == "food_critic" and "Fine Dining" or "Speed Service"
    }
end

function BattleEncounter:updateRating(finalScore)
    local chef = gameState.selectedChef
    local previousRating = chef.rating
    local targetScore = self.state.targetScore
    
    if finalScore < targetScore then
        -- Decrease rating
        local currentIndex = self:getRatingIndex(chef.rating)
        if currentIndex < #self.RATINGS then
            chef.rating = self.RATINGS[currentIndex + 1]
        end
    elseif finalScore >= (targetScore * 2) then
        -- Increase rating for doubling the target score
        local currentIndex = self:getRatingIndex(chef.rating)
        if currentIndex > 1 then
            chef.rating = self.RATINGS[currentIndex - 1]
        end
    end
    
    -- Store the rating change for UI feedback
    self.state.previousRating = previousRating
    self.state.ratingChanged = chef.rating ~= previousRating
    
    -- Check for game over condition
    if chef.rating == 'F' then
        self:gameOver()
    end
end

function BattleEncounter:endBattle(won)
    -- Update rating based on final total score
    self:updateRating(self.state.totalScore)
    
    -- Store battle results
    gameState.battleResults = {
        won = won,
        score = self.state.totalScore,
        rounds = self.state.roundNumber,
        rating = gameState.selectedChef.rating,
        previousRating = self.state.previousRating,
        ratingChanged = self.state.ratingChanged
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
           self.state.totalScore >= self.state.targetScore
end

function BattleEncounter:update(dt)
    Encounter.update(self, dt)
    
    -- Update all cards in hand
    for _, card in ipairs(self.state.handCards) do
        card:update(dt)
    end
    
    if self.state.showingConfirmDialog then
        return
    end

    if self.state.viewingPile then
        self:updatePileView()
        return
    end

    -- Phase-specific updates
    if self.state.currentPhase == BattleEncounter.PHASES.PREPARATION then
        self:updatePreparationPhase()
    elseif self.state.currentPhase == BattleEncounter.PHASES.JUDGING then
        self:updateJudgingPhase(dt)
    elseif self.state.currentPhase == BattleEncounter.PHASES.RESULTS then
        self:updateResultsPhase(dt)
    end

    -- Add pile viewing controls
    if love.keyboard.wasPressed('d') then
        self.state.viewingPile = 'draw'
        self.state.pileCardIndex = 1
    elseif love.keyboard.wasPressed('r') then
        self.state.viewingPile = 'discard'
        self.state.pileCardIndex = 1
    end

    -- Animate the display total
    if self.state.currentPhase == self.PHASES.JUDGING and self.state.scoringState then
        local target = self.state.scoringState.displayTotal
        local current = self.state.scoringState.animatedTotal
        if current < target then
            -- Smooth animation with easing
            self.state.scoringState.animatedTotal = current + (target - current) * math.min(1, dt * 5)
        end
    end
end

function BattleEncounter:updatePreparationPhase()
    if love.keyboard.wasPressed('left') then
        self:selectPreviousCard()
    elseif love.keyboard.wasPressed('right') then
        self:selectNextCard()
    elseif love.keyboard.wasPressed('space') then
        self:toggleCardSelection()
    elseif love.keyboard.wasPressed('return') and #self.state.selectedCards > 0 then
        self:transitionToPhase(self.PHASES.JUDGING)
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
        self:transitionToPhase(self.PHASES.JUDGING)
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
    
    -- Reset card's internal states
    card:setSelected(false)
    card:setLocked(false)
    
    -- Remove from selected cards if it exists there
    for i = #self.state.selectedCards, 1, -1 do
        if self.state.selectedCards[i] == card then
            table.remove(self.state.selectedCards, i)
            break
        end
    end
    
    -- Remove current card and add to discard pile
    self:removeCardFromHand(self.state.selectedCardIndex)
    self.state.deck:discard(card)
    
    -- Draw and add new card
    self:drawAndAddNewCard(self.state.selectedCardIndex)
    
    -- Update selection
    self:adjustSelectionAfterDiscard()
end

function BattleEncounter:removeCardFromHand(index)
    table.remove(self.state.handCards, index)
end

function BattleEncounter:drawAndAddNewCard(index)
    local newCard = self.state.deck:draw()
    if newCard then
        -- Reset card states when drawing
        newCard:setSelected(false)
        newCard:setLocked(false)  -- Make sure the card is unlocked when drawn
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

-- Remove these functions as they're no longer used:
-- function BattleEncounter:handleCardDiscard()
-- function BattleEncounter:discardAndDrawNew()

function BattleEncounter:updateJudgingPhase(dt)
    self:updatePhaseTimer(dt)
    self:updateCardScoring(dt)
end

function BattleEncounter:updatePhaseTimer(dt)
    if self.state.phaseTimer then
        self.state.phaseTimer = self.state.phaseTimer - dt
        
        if self.state.phaseTimer <= 0 then
            self:transitionToPhase(self.PHASES.RESULTS)
        end
    end
end

function BattleEncounter:updateCardScoring(dt)
    local scoringState = self.state.scoringState
    
    -- If we've scored all cards, nothing to do
    if scoringState.currentCardIndex >= #self.state.selectedCards then
        return
    end

    scoringState.animationTimer = scoringState.animationTimer - dt
    
    -- Time to score next card
    if scoringState.animationTimer <= 0 then
        self:scoreNextCard()
    end
end

function BattleEncounter:scoreNextCard()
    local scoringState = self.state.scoringState
    scoringState.currentCardIndex = scoringState.currentCardIndex + 1
    
    -- Check if we still have cards to score
    if scoringState.currentCardIndex <= #self.state.selectedCards then
        local card = self.state.selectedCards[scoringState.currentCardIndex]
        local scoreValue = scoringState.cardScores[scoringState.currentCardIndex]

        print("[BattleEncounter:scoreNextCard] Scoring card", card.name, "with scoring value", card.scoring)
        
        self:applyCardScore(card)
        card:showScoreAnimation(scoreValue)
        scoringState.animationTimer = self.PHASE_TIMINGS.CARD_SCORE_ANIMATION
    end
end

function BattleEncounter:applyCardScore(card)
    local scoreValue = card.scoring:getValue()
    
    if card.cardType == "ingredient" then
        self.state.roundScore = (self.state.roundScore or 0) + scoreValue
    elseif card.cardType == "technique" or card.cardType == "recipe" then
        self.state.roundScore = (self.state.roundScore or 0) * scoreValue
    end
    
    self.state.currentScore = self.state.roundScore  -- Update current score for display
    self.state.scoringState.displayTotal = self.state.currentScore
end

function BattleEncounter:updateResultsPhase(dt)
    if self.state.phaseTimer then
        self.state.phaseTimer = self.state.phaseTimer - dt
        if self.state.phaseTimer <= 0 then
            self.state.phaseTimer = nil
            if self:isBattleComplete() then
                self:endBattle(self.state.totalScore >= self.state.targetScore)
            else
                self:startNextRound()
            end
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

-- Remove these functions as they're no longer used:
-- function BattleEncounter:performCookingAction()
-- function BattleEncounter:applyCookingEffect(card)

function BattleEncounter:draw()
    if self.state.viewingPile then
        self:drawPileView()
        return
    end
    
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Draw phase-specific elements
    if self.state.currentPhase == BattleEncounter.PHASES.PREPARATION then
        self:drawPreparationPhase()
    elseif self.state.currentPhase == BattleEncounter.PHASES.JUDGING then
        self:drawJudgingPhase()
    elseif self.state.currentPhase == BattleEncounter.PHASES.RESULTS then
        self:drawResultsPhase()
    end
    
    -- Always draw common elements
    self:drawCommonElements()
    -- Draw deck info (piles)
    self:drawDeckInfo()
end

function BattleEncounter:drawCommonElements()
    -- Draw base background
    self:drawBattleBackground()
    
    -- Draw top HUD elements
    self:drawTopHUD()
    
    -- Draw bottom HUD elements (hand and deck info)
    self:drawBottomHUD()
end

function BattleEncounter:drawBattleBackground()
    -- Draw semi-transparent background overlay
    love.graphics.setColor(COLORS.PRIMARY[1], COLORS.PRIMARY[2], COLORS.PRIMARY[3], 0.1)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
end

function BattleEncounter:drawTopHUD()
    local TOP_MARGIN = 20
    local LEFT_MARGIN = 20
    
    -- Draw enemy info (left side)
    self:drawEnemyInfo(LEFT_MARGIN, TOP_MARGIN)
    
    -- Draw battle stats (right side)
    self:drawBattleStats(TOP_MARGIN)
end

function BattleEncounter:drawEnemyInfo(x, y)
    love.graphics.setFont(FONTS.MEDIUM)
    love.graphics.setColor(COLORS.TEXT)
    
    -- Enemy name
    love.graphics.print(
        self.state.enemy.name,
        x,
        y
    )
    
    -- Enemy specialty
    love.graphics.setFont(FONTS.SMALL)
    love.graphics.print(
        "Specialty: " .. self.state.enemy.specialty,
        x,
        y + 30
    )
end

function BattleEncounter:drawBattleStats(y)
    local statsX = love.graphics.getWidth() - 220
    local statSpacing = 25
    
    love.graphics.setFont(FONTS.MEDIUM)
    
    -- Round counter
    love.graphics.setColor(COLORS.TEXT)
    love.graphics.printf(
        string.format("Round %d/%d",
            self.state.roundNumber,
            self.state.maxRounds
        ),
        statsX, y,
        200, 'right'
    )
    
    -- Score - now showing total score instead of current round score
    local totalScore = self.state.totalScore or 0
    local scoreColor = totalScore >= self.state.targetScore and COLORS.SUCCESS or COLORS.HIGHLIGHT
    love.graphics.setColor(scoreColor)
    love.graphics.printf(
        string.format("Score: %d/%d",
            totalScore,
            self.state.targetScore
        ),
        statsX, y + statSpacing,
        200, 'right'
    )
end

function BattleEncounter:drawBottomHUD()
    -- Draw the player's hand
    self:drawHand()
    
    -- Draw deck information
    self:drawDeckInfo()
end

-- Helper function to separate deck drawing logic
function BattleEncounter:drawDeckInfo()
    local cardWidth, cardHeight = Card.getDimensions()
    local padding = 20
    local stackOffset = 2
    local pileSpacing = 20
    
    local pilesY = love.graphics.getHeight() - cardHeight - padding
    local drawPileX = love.graphics.getWidth() - (cardWidth * 2 + pileSpacing + padding)
    local discardPileX = love.graphics.getWidth() - (cardWidth + padding)
    
    -- Draw pile visualization and count
    if #self.state.deck.drawPile > 0 then
        local numCardsToShow = math.min(5, #self.state.deck.drawPile)
        for i = numCardsToShow, 1, -1 do
            love.graphics.setColor(1, 1, 1, 1)
            local tempCard = Card.new(0, "", "")
            if tempCard then
                tempCard:drawBack(
                    drawPileX - (i * stackOffset),
                    pilesY - (i * stackOffset)
                )
            end
        end
    end
    
    -- Draw pile count
    love.graphics.setColor(COLORS.TEXT)
    love.graphics.printf(
        tostring(#self.state.deck.drawPile),
        drawPileX - cardWidth/2,
        pilesY + cardHeight + 5,
        cardWidth,
        'center'
    )
    
    -- Discard pile visualization and count
    if #self.state.deck.discardPile > 0 then
        local topCard = self.state.deck.discardPile[#self.state.deck.discardPile]
        if topCard then
            love.graphics.setColor(1, 1, 1, 1)
            topCard:drawBack(discardPileX, pilesY)
        end
    end
    
    -- Discard pile count
    love.graphics.setColor(COLORS.TEXT)
    love.graphics.printf(
        tostring(#self.state.deck.discardPile),
        discardPileX - cardWidth/2,
        pilesY + cardHeight + 5,
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

function BattleEncounter:drawHand()
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
end

function BattleEncounter:drawPreparationPhase()
    -- Draw preparation-specific UI elements only
    -- (hand is now drawn in drawCommonElements)
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

-- Remove these functions as they're no longer used:
-- function BattleEncounter:drawCookingPhase()
--     -- Draw active cards
--     local cardWidth = 100
--     local cardHeight = 150
--     local spacing = 20
--     local startX = (love.graphics.getWidth() - ((cardWidth + spacing) * #self.state.selectedCards)) / 2
--     
--     for i, card in ipairs(self.state.selectedCards) do
--         local x = startX + ((i-1) * (cardWidth + spacing))
--         local y = love.graphics.getHeight() - cardHeight - 50
--         
--         -- Highlight current cooking card
--         if i == self.state.currentCookingIndex then
--             love.graphics.setColor(0.3, 0.8, 0.3, 1)
--         else
--             love.graphics.setColor(0.2, 0.2, 0.2, 1)
--         end
--         love.graphics.rectangle('fill', x, y, cardWidth, cardHeight)
--         
--         -- Draw card content
--         love.graphics.setColor(1, 1, 1, 1)
--         love.graphics.printf(card.name or "Card", x, y + 20, cardWidth, 'center')
--     end
--     
--     -- Draw instructions
--     love.graphics.setColor(1, 1, 1, 1)
--     love.graphics.printf(
--         "Press SPACE to cook!",
--         0,
--         love.graphics.getHeight() - 30,
--         love.graphics.getWidth(),
--         'center'
--     )
-- end

function BattleEncounter:drawJudgingPhase()
    -- Get screen dimensions for centering
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Get card dimensions and spacing
    local cardWidth, cardHeight = Card.getDimensions()
    local cardSpacing = 20  -- Space between cards
    
    -- Calculate total width of all cards plus spacing
    local totalWidth = (#self.state.selectedCards * cardWidth) + ((#self.state.selectedCards - 1) * cardSpacing)
    
    -- Calculate starting X position to center the row
    local startX = (screenWidth - totalWidth) / 2
    -- Position cards higher up (at 1/3 of screen height instead of 1/2)
    local centerY = (screenHeight / 3) - (cardHeight / 2)
    
    -- Draw each selected card
    for i, card in ipairs(self.state.selectedCards) do
        local x = startX + ((i-1) * (cardWidth + cardSpacing))
        love.graphics.setColor(1, 1, 1, 1)
        card:draw(x, centerY)
    end

    -- Draw animated running total below the cards
    if self.state.scoringState and self.state.scoringState.displayTotal > 0 then
        love.graphics.setFont(FONTS.LARGE)
        love.graphics.setColor(COLORS.HIGHLIGHT)
        love.graphics.printf(
            tostring(math.ceil(self.state.scoringState.animatedTotal)),
            0,
            centerY + cardHeight + 40,
            screenWidth,
            'center'
        )
    end
end

function BattleEncounter:drawResultsPhase()
    love.graphics.setFont(FONTS.LARGE)
    local centerY = love.graphics.getHeight() / 2 - 40
    local lineHeight = 40
    
    if self:isBattleComplete() then
        -- Battle completion results
        local isVictory = self.state.currentScore >= self.state.targetScore
        love.graphics.setColor(isVictory and COLORS.SUCCESS or COLORS.FAILURE)
        love.graphics.printf(
            isVictory and "Victory!" or "Defeat!",
            0, centerY,
            love.graphics.getWidth(),
            'center'
        )
        
        -- Show rating change if any
        if self.state.ratingChanged then
            local ratingColor = self:getRatingIndex(gameState.selectedChef.rating) < 
                              self:getRatingIndex(self.state.previousRating) and COLORS.SUCCESS or COLORS.FAILURE
            love.graphics.setColor(ratingColor)
            love.graphics.printf(
                string.format("%s → %s", self.state.previousRating, gameState.selectedChef.rating),
                0, centerY + lineHeight,
                love.graphics.getWidth(),
                'center'
            )
        end
    else
        -- Just show "Next Round" message
        love.graphics.setColor(COLORS.PRIMARY)
        love.graphics.printf(
            "Next Round",
            0, centerY,
            love.graphics.getWidth(),
            'center'
        )
    end
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
    if not self.PHASES[newPhase] then return end

    if newPhase == self.PHASES.JUDGING then
        -- Initialize scoring state
        self.state.scoringState = {
            currentCardIndex = 0,  -- Index of card being scored (0 means not started)
            cardScores = {},       -- Will hold score display strings
            animationTimer = 0,    -- Timer for current card animation
            displayTotal = 0,    -- Add running total for display
            animatedTotal = 0,    -- Add animated total that will count up
            totalScore = 0         -- Running total as cards are scored
        }
        self.state.roundScore = 0  -- Initialize round score
        
        -- Prepare display strings for scoring animations
        self:prepareScoreDisplayStrings()
        
        -- Start phase timer
        -- self.state.phaseTimer = #self.state.selectedCards * self.PHASE_TIMINGS.CARD_SCORE_ANIMATION
        self.state.phaseTimer = (#self.state.selectedCards * self.PHASE_TIMINGS.CARD_SCORE_ANIMATION) + self.PHASE_TIMINGS.JUDGING
        
        -- Remove selected cards from hand but keep them in selectedCards
        self:removeCardsFromHand()
    elseif newPhase == self.PHASES.RESULTS then
        -- Add round score to total score
        self.state.totalScore = (self.state.totalScore or 0) + self.state.roundScore
        self.state.currentScore = self.state.totalScore  -- Update current score to total
        self:discardPlayedCards()
        self.state.phaseTimer = self.PHASE_TIMINGS.RESULTS
    end

    self.state.currentPhase = newPhase
end

function BattleEncounter:prepareScoreDisplayStrings()
    local scoringState = self.state.scoringState
    scoringState.cardScores = {}
    
    -- Just prepare the display strings for each card
    for i, card in ipairs(self.state.selectedCards) do
        if card.cardType == "ingredient" then
            scoringState.cardScores[i] = string.format("+%d", card.scoring.whiteScore)
        elseif card.cardType == "technique" then
            scoringState.cardScores[i] = string.format("×%.1f", card.scoring.redScore)
        elseif card.cardType == "recipe" then
            scoringState.cardScores[i] = string.format("×%.1f", card.scoring.pinkScore)
        end
    end
end

-- New function to remove cards from hand only
function BattleEncounter:removeCardsFromHand()
    for _, card in ipairs(self.state.selectedCards) do
        for i = #self.state.handCards, 1, -1 do
            if self.state.handCards[i] == card then
                table.remove(self.state.handCards, i)
                break
            end
        end
    end
end

-- Modified to only handle actual discarding
function BattleEncounter:discardPlayedCards()
    -- Add selected cards to discard pile
    for _, card in ipairs(self.state.selectedCards) do
        self.state.deck:discard(card)
    end
    
    -- Clear selected cards
    self.state.selectedCards = {}
end

function BattleEncounter:identifyCombinations(cards)
    local combinations = {}
    -- Add combination detection logic here
    -- Example: matching ingredients, complementary flavors, etc.
    return combinations
end

function BattleEncounter:startNextRound()
    -- Increment round number
    self.state.roundNumber = self.state.roundNumber + 1
    
    -- Reset round-specific state
    self.state.selectedCards = {}
    self.state.comboMultiplier = 1
    self.state.actionFeedback = nil
    self.state.currentScore = 0  -- Reset score at the start of each round
    self.state.roundScore = 0  -- Reset round score
    
    -- Get max hand size from battle parameters
    local config = encounterConfigs[self.state.battleType] or encounterConfigs.food_critic
    local maxHandSize = 8  -- Default hand size
    
    -- Draw cards until hand is full
    while #self.state.handCards < maxHandSize do
        local card = self.state.deck:draw()
        if card then
            table.insert(self.state.handCards, card)
        else
            -- If deck is empty, shuffle discard pile back in
            self.state.deck:shuffleDiscardIntoDeck()
            card = self.state.deck:draw()
            if card then
                table.insert(self.state.handCards, card)
            else
                -- If still no cards, break to prevent infinite loop
                break
            end
        end
    end
    
    -- Reset selection
    self.state.selectedCardIndex = 1
    for i, card in ipairs(self.state.handCards) do
        card:setSelected(i == 1)
    end
    
    -- Reset phase and time
    self.state.timeRemaining = config.timePerRound
    self:transitionToPhase(self.PHASES.PREPARATION)
end

-- Helper function to shuffle discard pile back into deck
function BattleEncounter:shuffleDiscardIntoDeck()
    -- Move all cards from discard pile to draw pile
    for _, card in ipairs(self.state.deck.discardPile) do
        table.insert(self.state.deck.drawPile, card)
    end
    
    -- Clear discard pile
    self.state.deck.discardPile = {}
    
    -- Shuffle draw pile
    for i = #self.state.deck.drawPile, 2, -1 do
        local j = math.random(i)
        self.state.deck.drawPile[i], self.state.deck.drawPile[j] = 
        self.state.deck.drawPile[j], self.state.deck.drawPile[i]
    end
end

function BattleEncounter:updatePileView()
    local pile = self.state.viewingPile == 'draw' and self.state.deck.drawPile or self.state.deck.discardPile
    local CARDS_PER_ROW = 5

    -- Initialize sorted display array if not exists or pile changed
    if not self.displayOrder or not self.lastViewingPile or self.lastViewingPile ~= self.state.viewingPile then
        self.displayOrder = {}
        for i = 1, #pile do
            self.displayOrder[i] = i
        end
        -- Sort by card names
        table.sort(self.displayOrder, function(a, b)
            return pile[a].name < pile[b].name
        end)
        self.lastViewingPile = self.state.viewingPile
    end

    if love.keyboard.wasPressed('escape') then
        self.state.viewingPile = nil
        self.displayOrder = nil  -- Clear display order when exiting
        self.lastViewingPile = nil
    elseif love.keyboard.wasPressed('tab') then
        -- Toggle between draw and discard piles
        self.state.viewingPile = self.state.viewingPile == 'draw' and 'discard' or 'draw'
        self.state.pileCardIndex = 1
        self.displayOrder = nil  -- Force new sort on pile switch
        self.lastViewingPile = nil
    else
        -- Grid-based navigation
        local currentRow = math.ceil(self.state.pileCardIndex / CARDS_PER_ROW)
        local currentCol = ((self.state.pileCardIndex - 1) % CARDS_PER_ROW) + 1
        local totalRows = math.ceil(#pile / CARDS_PER_ROW)

        if love.keyboard.wasPressed('left') then
            if currentCol > 1 then
                self.state.pileCardIndex = self.state.pileCardIndex - 1
            elseif currentRow > 1 then
                self.state.pileCardIndex = self.state.pileCardIndex - 1
            end
        elseif love.keyboard.wasPressed('right') then
            if self.state.pileCardIndex < #pile and currentCol < CARDS_PER_ROW then
                self.state.pileCardIndex = self.state.pileCardIndex + 1
            end
        elseif love.keyboard.wasPressed('up') then
            if currentRow > 1 then
                local newIndex = self.state.pileCardIndex - CARDS_PER_ROW
                if newIndex > 0 then
                    self.state.pileCardIndex = newIndex
                end
            end
        elseif love.keyboard.wasPressed('down') then
            local newIndex = self.state.pileCardIndex + CARDS_PER_ROW
            if newIndex <= #pile then
                self.state.pileCardIndex = newIndex
            end
        end
    end
end

function BattleEncounter:drawPileView()
    -- Get card dimensions and spacing
    local cardWidth, cardHeight = Card.getDimensions()
    local spacing = 20
    local CARDS_PER_ROW = 5
    local startX = 50
    local startY = 80

    -- Draw semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Draw pile title
    love.graphics.setColor(1, 1, 1, 1)
    local title = self.state.viewingPile == 'draw' and 'Draw Pile' or 'Discard Pile'
    love.graphics.printf(title, 0, 20, love.graphics.getWidth(), 'center')

    -- Get current pile
    local pile = self.state.viewingPile == 'draw' and self.state.deck.drawPile or self.state.deck.discardPile

    -- Draw cards in grid using displayOrder
    for displayIndex, i in ipairs(self.displayOrder or {}) do
        local card = pile[i]
        if card then
            local row = math.floor((displayIndex-1) / CARDS_PER_ROW)
            local col = (displayIndex-1) % CARDS_PER_ROW
            
            local x = startX + col * (cardWidth + spacing)
            local y = startY + row * (cardHeight + spacing)
            
            -- Highlight the currently selected card
            if displayIndex == self.state.pileCardIndex then
                love.graphics.setColor(1, 1, 0, 0.3)
                love.graphics.rectangle('fill', 
                    x - 5, y - 5, 
                    cardWidth + 10, cardHeight + 10
                )
            end
            
            love.graphics.setColor(1, 1, 1, 1)
            card:draw(x, y)
        end
    end

    -- Draw total card count
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(
        string.format("Total Cards: %d", #pile),
        0, love.graphics.getHeight() - 60,
        love.graphics.getWidth(),
        'center'
    )

    -- Draw controls help
    love.graphics.printf(
        "← → ↑ ↓ Navigate cards | Tab: Switch pile | Esc: Return to battle",
        0, love.graphics.getHeight() - 30,
        love.graphics.getWidth(),
        'center'
    )
end

return BattleEncounter  -- NOT return true/false













