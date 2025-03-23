local Scene = require('src.scenes.scene')
local DeckFactory = require('src.cards.deckFactory')

local ChefSelect = {}
ChefSelect.__index = ChefSelect
setmetatable(ChefSelect, Scene)

-- Consistent styling across menus
local COLORS = {
    TITLE = {1, 0.8, 0, 1},      -- Gold for title
    TEXT = {1, 1, 1, 1},         -- White for regular text
    SELECTED = {1, 0.8, 0, 1},   -- Gold for selected item
    UNSELECTED = {0.7, 0.7, 0.7, 1}, -- Slightly dimmed for unselected
    BACKGROUND = {0.1, 0.1, 0.2, 1} -- Dark blue background
}

local FONTS = {
    TITLE = love.graphics.newFont(48),
    MENU = love.graphics.newFont(24),
    INSTRUCTIONS = love.graphics.newFont(16)
}

-- Animation constants
local FLOAT_SPEED = 1.5
local FLOAT_AMOUNT = 8
local SHIMMER_SPEED = 2

-- Constants for styling
local MENU_INDENT = 40
local DOT_OFFSET = -20

function ChefSelect.new()
    local self = Scene.new()  -- Create a new Scene instance as base
    setmetatable(self, ChefSelect)  -- Set ChefSelect as the metatable
    self:init()  -- Call init right after creation
    return self
end

function ChefSelect:loadChefs()
    -- Return a list of predefined chefs with their specialties
    return {
        {
            name = "Chef Antonio",
            specialty = "Italian Cuisine",
            description = "Master of pasta and traditional Italian dishes",
            rating = "C"  -- Add default rating
        },
        {
            name = "Chef Mei",
            specialty = "Asian Fusion",
            description = "Expert in combining Eastern and Western flavors",
            rating = "C"
        },
        {
            name = "Chef Pierre",
            specialty = "French Cuisine",
            description = "Classically trained in French cooking techniques",
            rating = "C"
        },
        {
            name = "Chef Sofia",
            specialty = "Street Food",
            description = "Specializes in creative street food innovations",
            rating = "C"
        }
    }
end

function ChefSelect:generateStarterDeck(chef)
    return DeckFactory.createStarterDeck(chef)
end

function ChefSelect:init()
    Scene.init(self)
    self.selected = 1
    self.chefs = self:loadChefs()
    
    -- Initialize animation variables
    self.titleOffset = 0
    self.chefOffsets = {}
    for i = 1, #self.chefs do
        self.chefOffsets[i] = 0
    end
end

function ChefSelect:update(dt)
    -- Update title animations
    self.titleOffset = math.sin(love.timer.getTime() * FLOAT_SPEED) * FLOAT_AMOUNT
    self.titleAlpha = 1 - math.abs(math.sin(love.timer.getTime() * SHIMMER_SPEED) * 0.2)

    -- Animate selected option
    for i = 1, #self.chefs do
        if i == self.selected then
            self.chefOffsets[i] = math.sin(love.timer.getTime() * 2) * 3
        else
            self.chefOffsets[i] = 0
        end
    end

    if self.showingConfirmDialog then
        self:updateConfirmDialog()
        return
    end

    if love.keyboard.wasPressed('escape') then
        self.showingConfirmDialog = true
        return
    end

    if love.keyboard.wasPressed('up') then
        self.selected = self.selected - 1
        if self.selected < 1 then self.selected = #self.chefs end
    end
    if love.keyboard.wasPressed('down') then
        self.selected = self.selected + 1
        if self.selected > #self.chefs then self.selected = 1 end
    end
    if love.keyboard.wasPressed('return') then
        local selectedChef = self.chefs[self.selected]
        gameState.selectedChef = selectedChef
        -- Generate and assign starter deck
        gameState.currentDeck = self:generateStarterDeck(selectedChef)
        local provinceMap = sceneManager.scenes['provinceMap']
        provinceMap:setSeed(gameState.mapSeed)
        sceneManager:switch('provinceMap')
    end
end

function ChefSelect:draw()
    -- Draw background
    love.graphics.setColor(COLORS.BACKGROUND)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw title with floating animation and shimmer
    love.graphics.setFont(FONTS.TITLE)
    love.graphics.setColor(COLORS.TITLE[1], COLORS.TITLE[2], COLORS.TITLE[3], self.titleAlpha)
    love.graphics.printf("Select Your Chef", 0, 100 + self.titleOffset, love.graphics.getWidth(), 'center')

    -- Draw chef options
    love.graphics.setFont(FONTS.MENU)
    for i, chef in ipairs(self.chefs) do
        local y = 200 + i * 60 + self.chefOffsets[i]
        
        -- Draw selection indicator to the left
        if i == self.selected then
            love.graphics.setColor(COLORS.SELECTED)
            love.graphics.printf("•", DOT_OFFSET, y, love.graphics.getWidth(), 'center')
        end
        
        love.graphics.setColor(i == self.selected and COLORS.SELECTED or COLORS.UNSELECTED)
        love.graphics.printf(
            chef.name .. "\n" .. chef.specialty,
            0, y,
            love.graphics.getWidth(),
            'center'
        )
    end

    -- Draw instructions
    love.graphics.setFont(FONTS.INSTRUCTIONS)
    love.graphics.setColor(COLORS.TEXT[1], COLORS.TEXT[2], COLORS.TEXT[3], 0.7)
    love.graphics.printf(
        "Use Up/Down to select, Enter to confirm, Escape to return",
        0,
        love.graphics.getHeight() - 50,
        love.graphics.getWidth(),
        'center'
    )
end

return ChefSelect








