local Scene = require('src.scenes.scene')
local Deck = require('src.cards.deck')
local ChefSelect = require('src.scenes.chefSelect')
local MenuStyle = require('src.ui.menuStyle')

local DebugMenu = {}
DebugMenu.__index = DebugMenu
setmetatable(DebugMenu, Scene)

-- Title animation constants
local FLOAT_SPEED = 1.5
local FLOAT_AMOUNT = 8
local SHIMMER_SPEED = 2

function DebugMenu.new()
    local self = Scene.new()
    setmetatable(self, DebugMenu)
    self:init()
    return self
end

function DebugMenu:init()
    Scene.init(self)
    self.options = {
        "Encounter Tester",
        "View Test Deck",
        "View Chef Decks",
        "Test Market",
        "Back to Main Menu"
    }
    self.selected = 1
    
    -- Initialize animation variables
    self.titleOffset = 0
    self.titleAlpha = 1
    
    -- Initialize chef selection submenu
    self.chefSelect = ChefSelect.new()
    self.showingChefSelect = false
    self.chefs = self.chefSelect:loadChefs()
    self.selectedChef = 1
end

function DebugMenu:update(dt)
    -- Update title animations
    self.titleOffset = math.sin(love.timer.getTime() * FLOAT_SPEED) * FLOAT_AMOUNT
    self.titleAlpha = 1 - math.abs(math.sin(love.timer.getTime() * SHIMMER_SPEED) * 0.2)

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
            gameState.currentDeck = Deck.generateTestDeck()
            gameState.previousScene = 'debugMenu'
            sceneManager:switch('deckViewer')
        elseif self.selected == 3 then
            self.showingChefSelect = true
        elseif self.selected == 4 then
            gameState.cash = 20
            gameState.previousScene = 'debugMenu'
            gameState.currentMarketType = 'farmers_market'
            sceneManager:switch('marketEncounter')
        elseif self.selected == 5 then
            sceneManager:switch('mainMenu')
        end
    end
end

function DebugMenu:draw()
    MenuStyle.drawBackground()
    
    -- Draw animated title
    love.graphics.setFont(MenuStyle.FONTS.TITLE)
    love.graphics.setColor(MenuStyle.COLORS.TITLE[1], MenuStyle.COLORS.TITLE[2], 
        MenuStyle.COLORS.TITLE[3], self.titleAlpha)
    love.graphics.printf("Debug Menu", 0, MenuStyle.LAYOUT.TITLE_Y + self.titleOffset, 
        love.graphics.getWidth(), 'center')
    
    if self.showingChefSelect then
        love.graphics.setFont(MenuStyle.FONTS.MENU)
        love.graphics.printf("Select Chef Deck to View", 0, 160, love.graphics.getWidth(), 'center')
        
        for i, chef in ipairs(self.chefs) do
            local displayText = chef.name .. " - " .. chef.specialty
            MenuStyle.drawMenuItem(displayText, i, i == self.selectedChef, false)
        end
    else
        -- Draw menu options
        for i, option in ipairs(self.options) do
            MenuStyle.drawMenuItem(option, i, i == self.selected, false)
        end
    end

    -- Draw instructions
    local instructions = self.showingChefSelect and 
        "Use ↑↓ to select, Enter to confirm, Esc to return" or
        "Use ↑↓ to select, Enter to confirm, Esc to exit"
    MenuStyle.drawInstructions(instructions)
end

return DebugMenu
