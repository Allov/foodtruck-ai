local Scene = require('src.scenes.scene')
local Deck = require('src.cards.deck')
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
        "Back to Main Menu"
    }
    self.selected = 1
end

function DebugMenu:update(dt)
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
            sceneManager:switch('mainMenu')
        end
    end
end

function DebugMenu:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Debug Menu", 0, 100, love.graphics.getWidth(), 'center')
    
    for i, option in ipairs(self.options) do
        if i == self.selected then
            love.graphics.setColor(1, 1, 0, 1)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
        love.graphics.printf(option, 0, 200 + i * 40, love.graphics.getWidth(), 'center')
    end
end

return DebugMenu
