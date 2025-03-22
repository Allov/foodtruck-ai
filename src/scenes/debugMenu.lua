local Scene = require('src.scenes.scene')
local Deck = require('src.cards.deck')
local ChefSelect = require('src.scenes.chefSelect')
local DebugMenu = setmetatable({}, Scene)
DebugMenu.__index = DebugMenu

function DebugMenu.new()
    local self = setmetatable({}, Scene)
    return setmetatable(self, DebugMenu)
end

function DebugMenu:init()
    self.options = {
        "Encounter Tester",
        "View Test Deck",
        "View Chef Decks",
        "Test Market",
        "Back to Main Menu"
    }
    self.selected = 1
    
    -- Initialize chef selection submenu
    self.chefSelect = ChefSelect.new()
    self.showingChefSelect = false
    self.chefs = self.chefSelect:loadChefs()
    self.selectedChef = 1
end

function DebugMenu:update(dt)
    if self.showingChefSelect then
        if love.keyboard.wasPressed('escape') then
            self.showingChefSelect = false
            return
        end

        if love.keyboard.wasPressed('up') then
            self.selectedChef = self.selectedChef - 1
            if self.selectedChef < 1 then self.selectedChef = #self.chefs end
        end
        if love.keyboard.wasPressed('down') then
            self.selectedChef = self.selectedChef + 1
            if self.selectedChef > #self.chefs then self.selectedChef = 1 end
        end
        if love.keyboard.wasPressed('return') then
            local chef = self.chefs[self.selectedChef]
            gameState.currentDeck = self.chefSelect:generateStarterDeck(chef)
            gameState.previousScene = 'debugMenu'
            sceneManager:switch('deckViewer')
        end
        return
    end

    if love.keyboard.wasPressed('escape') then
        sceneManager:switch('mainMenu')
        return
    end

    if love.keyboard.wasPressed('up') then
        self.selected = self.selected - 1
        if self.selected < 1 then self.selected = #self.options end
    end
    if love.keyboard.wasPressed('down') then
        self.selected = self.selected + 1
        if self.selected > #self.options then self.selected = 1 end
    end
    if love.keyboard.wasPressed('return') then
        if self.selected == 1 then
            sceneManager:switch('encounterTester')
        elseif self.selected == 2 then
            -- Generate and set a test deck
            gameState.currentDeck = Deck.generateTestDeck()
            gameState.previousScene = 'debugMenu'
            sceneManager:switch('deckViewer')
        elseif self.selected == 3 then
            -- Show chef selection submenu
            self.showingChefSelect = true
        elseif self.selected == 4 then
            -- Test market
            gameState.cash = 20  -- Give some test money
            gameState.previousScene = 'debugMenu'
            gameState.currentMarketType = 'farmers_market'  -- Default to farmers market
            sceneManager:switch('marketEncounter')
        elseif self.selected == 5 then
            sceneManager:switch('mainMenu')
        end
    end
end

function DebugMenu:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Debug Menu", 0, 100, love.graphics.getWidth(), 'center')
    
    if self.showingChefSelect then
        love.graphics.printf("Select Chef Deck to View", 0, 160, love.graphics.getWidth(), 'center')
        for i, chef in ipairs(self.chefs) do
            if i == self.selectedChef then
                love.graphics.setColor(1, 1, 0, 1)
            else
                love.graphics.setColor(1, 1, 1, 1)
            end
            love.graphics.printf(
                chef.name .. " - " .. chef.specialty,
                0, 200 + i * 40,
                love.graphics.getWidth(),
                'center'
            )
        end
    else
        for i, option in ipairs(self.options) do
            if i == self.selected then
                love.graphics.setColor(1, 1, 0, 1)
            else
                love.graphics.setColor(1, 1, 1, 1)
            end
            love.graphics.printf(option, 0, 200 + i * 40, love.graphics.getWidth(), 'center')
        end
    end
end

return DebugMenu


