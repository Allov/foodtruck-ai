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
    ACCENT = {1, 0.5, 0.5, 1}    -- Light red for accents
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

    if self.state.viewingPile then
        self:updatePileView()
        return
    end

    -- Phase-specific updates
    if self.state.currentPhase == BattleEncounter.PHASES.PREPARATION then
        self:updatePreparationPhase()
    elseif self.state.currentPhase == BattleEncounter.PHASES.JUDGING then
        self:updateJudgingPhase()
    elseif self.state.currentPhase == BattleEncounter.PHASES.RESULTS then
        self:updateResultsPhase()
    end

    -- Add pile viewing controls
    if love.keyboard.wasPressed('d') then
        self.state.viewingPile = 'draw'
        self.state.pileCardIndex = 1
    elseif love.keyboard.wasPressed('r') then
        self.state.viewingPile = 'discard'
        self.state.pileCardIndex = 1
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

function BattleEncounter:handleCardDiscard()
    if love.keyboard.wasPressed('escape') then
        -- Return to selection mode
        self.state.selectedForDiscard = {}
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
    if love.keyboard.wasPressed('return') then
        self:transitionToPhase(self.PHASES.RESULTS)
    end
end

function BattleEncounter:updateResultsPhase()
    if love.keyboard.wasPressed('return') then
        if self:isBattleComplete() then
            self:endBattle(self.state.currentScore >= self.state.targetScore)
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
    if self.state.viewingPile then
        self:drawPileView()
        return
    end
    
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
    -- Draw semi-transparent background overlay
    love.graphics.setColor(COLORS.PRIMARY[1], COLORS.PRIMARY[2], COLORS.PRIMARY[3], 0.1)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Constants for UI layout
    local TOP_MARGIN = 20
    local GAUGE_HEIGHT = 15
    local GAUGE_WIDTH = 200
    local STATS_HEIGHT = 120

    -- Draw enemy stats in top-left corner
    if self.state.enemy then
        local statsX = 20
        local statsY = TOP_MARGIN
        
        -- Enemy name
        love.graphics.setFont(FONTS.MEDIUM)
        love.graphics.setColor(COLORS.TEXT)
        love.graphics.print(self.state.enemy.name, statsX, statsY)
        
        -- Specialty and preferences in smaller font
        love.graphics.setFont(FONTS.SMALL)
        love.graphics.setColor(COLORS.ACCENT)
        love.graphics.print(
            string.format("Specialty: %s\nPrefers: %s, %s",
                self.state.enemy.specialty,
                self.state.enemy.preferences.primary,
                self.state.enemy.preferences.bonus
            ),
            statsX, statsY + 25
        )

        -- Satisfaction gauge
        local gaugeY = statsY + 65
        local satisfaction = self.state.enemy.satisfaction
        
        -- Gauge background
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle('fill', statsX, gaugeY, GAUGE_WIDTH, GAUGE_HEIGHT)
        
        -- Gauge fill
        local fillWidth = (satisfaction / 100) * GAUGE_WIDTH
        local r, g, b = 1, 0, 0
        if satisfaction >= 50 then
            r = 2 * (1 - satisfaction/100)
            g = 1
        else
            r = 1
            g = 2 * (satisfaction/100)
        end
        love.graphics.setColor(r, g, b, 1)
        love.graphics.rectangle('fill', statsX, gaugeY, fillWidth, GAUGE_HEIGHT)
        
        -- Gauge text
        love.graphics.setColor(COLORS.TEXT)
        love.graphics.printf(
            string.format("Satisfaction: %d%%", satisfaction),
            statsX, gaugeY - 20,
            GAUGE_WIDTH, 'left'
        )
    end

    -- Draw battle stats in top-right corner
    local statsX = love.graphics.getWidth() - 220
    local statsY = TOP_MARGIN
    local statSpacing = 25

    love.graphics.setFont(FONTS.MEDIUM)
    
    -- Round counter
    love.graphics.setColor(COLORS.TEXT)
    love.graphics.printf(
        string.format("Round %d/%d",
            self.state.roundNumber,
            self.state.maxRounds
        ),
        statsX, statsY,
        200, 'right'
    )
    
    -- Score with dynamic color
    local scoreColor = self.state.currentScore >= self.state.targetScore and COLORS.SUCCESS or COLORS.HIGHLIGHT
    love.graphics.setColor(scoreColor)
    love.graphics.printf(
        string.format("Score: %d/%d",
            self.state.currentScore,
            self.state.targetScore
        ),
        statsX, statsY + statSpacing,
        200, 'right'
    )
    
    -- Phase indicator
    love.graphics.setFont(FONTS.SMALL)
    love.graphics.setColor(COLORS.ACCENT)
    love.graphics.printf(
        self.state.currentPhase,
        statsX, statsY + statSpacing * 2,
        200, 'right'
    )
    
    -- Timer when in cooking phase
    if self.state.currentPhase == BattleEncounter.PHASES.COOKING then
        local timeColor = self.state.timeRemaining <= 10 and COLORS.FAILURE or COLORS.TEXT
        love.graphics.setColor(timeColor)
        love.graphics.printf(
            string.format("%.1fs", self.state.timeRemaining),
            statsX, statsY + statSpacing * 3,
            200, 'right'
        )
    end

    -- Draw deck/discard info at bottom right (rest of the function remains unchanged)
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
            Card.new(0, "", ""):drawBack(
                drawPileX - (i * stackOffset),
                pilesY - (i * stackOffset)
            )
        end
    end
    
    -- Discard pile visualization and count
    if #self.state.deck.discardPile > 0 then
        local numCardsToShow = math.min(5, #self.state.deck.discardPile)
        for i = numCardsToShow, 1, -1 do
            love.graphics.setColor(1, 1, 1, 0.8)
            Card.new(0, "", ""):drawBack(
                discardPileX - (i * stackOffset),
                pilesY - (i * stackOffset)
            )
        end
    end
    
    -- Draw counts
    love.graphics.setFont(FONTS.SMALL)
    love.graphics.setColor(COLORS.TEXT)
    love.graphics.printf(
        #self.state.deck.drawPile,
        drawPileX, pilesY - 25,
        cardWidth, 'center'
    )
    love.graphics.printf(
        #self.state.deck.discardPile,
        discardPileX, pilesY - 25,
        cardWidth, 'center'
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
        self.state.selectedForDiscard = {}
    end

    -- Set up new phase
    if newPhase == self.PHASES.JUDGING then
        -- Calculate final score for the round
        self:calculateRoundScore()
    end

    -- Update the phase
    self.state.currentPhase = newPhase
end

function BattleEncounter:calculateRoundScore()
    local baseScore = 0
    local combinations = self:identifyCombinations(self.state.selectedCards)
    
    -- Calculate base score from cards
    for _, card in ipairs(self.state.selectedCards) do
        baseScore = baseScore + (card.value or 0)
    end
    
    -- Apply combination bonuses
    for _, combo in ipairs(combinations) do
        baseScore = baseScore + combo.bonus
    end
    
    -- Apply enemy preference multipliers
    if self.state.enemy.preferences.primary == self.state.battleType then
        baseScore = baseScore * 1.5
    end
    
    -- Apply combo multiplier
    local finalScore = baseScore * self.state.comboMultiplier
    
    -- Update total score
    self.state.currentScore = self.state.currentScore + finalScore
    
    -- Discard all played cards
    for _, card in ipairs(self.state.selectedCards) do
        -- Remove from hand if it exists there
        for i = #self.state.handCards, 1, -1 do
            if self.state.handCards[i] == card then
                table.remove(self.state.handCards, i)
                break
            end
        end
        -- Add to discard pile
        self.state.deck:discard(card)
    end
    
    -- Clear selected cards
    self.state.selectedCards = {}
    
    -- Reset combo multiplier for next round
    self.state.comboMultiplier = 1
    
    return finalScore
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













