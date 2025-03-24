local Scene = require('src.scenes.scene')
local DeckFactory = require('src.cards.deckFactory')
local MenuStyle = require('src.ui.menuStyle')
local Chef = require('src.entities.chef')

local ChefSelect = {}
ChefSelect.__index = ChefSelect
setmetatable(ChefSelect, Scene)

-- Animation constants
local FLOAT_SPEED = 1.5
local FLOAT_AMOUNT = 8
local SHIMMER_SPEED = 2

function ChefSelect.new()
    local self = Scene.new()  -- Create a new Scene instance as base
    setmetatable(self, ChefSelect)  -- Set ChefSelect as the metatable
    self:init()  -- Call init right after creation
    return self
end

function ChefSelect:loadChefs()
    -- Return a list of predefined chefs
    local chefData = {
        {
            name = "Chef Antonio",
            specialty = "Italian Cuisine",
            description = "Master of pasta and traditional Italian dishes",
            rating = "C"
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

    -- Convert raw data to Chef objects
    local chefs = {}
    for _, data in ipairs(chefData) do
        table.insert(chefs, Chef.new(data))
    end

    return chefs
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
    self.titleAlpha = 1
end

function ChefSelect:update(dt)
    -- Update title animations
    self.titleOffset = math.sin(love.timer.getTime() * FLOAT_SPEED) * FLOAT_AMOUNT
    self.titleAlpha = 1 - math.abs(math.sin(love.timer.getTime() * SHIMMER_SPEED) * 0.2)

    if love.keyboard.wasPressed('escape') then
        sceneManager:switch('mainMenu')
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
        gameState.currentDeck = self:generateStarterDeck(selectedChef)
        sceneManager:switch('provinceMap')
    end
end

function ChefSelect:draw()
    MenuStyle.drawBackground()

    -- Draw animated title
    love.graphics.setFont(MenuStyle.FONTS.TITLE)
    love.graphics.setColor(MenuStyle.COLORS.TITLE[1], MenuStyle.COLORS.TITLE[2],
        MenuStyle.COLORS.TITLE[3], self.titleAlpha)
    love.graphics.printf("Select Your Chef", 0, MenuStyle.LAYOUT.TITLE_Y + self.titleOffset,
        love.graphics.getWidth(), 'center')

    -- Draw chef options with increased spacing for two lines
    for i, chef in ipairs(self.chefs) do
        -- Calculate base Y position for this chef entry
        local baseY = MenuStyle.LAYOUT.MENU_START_Y + (i - 1) * (MenuStyle.LAYOUT.MENU_ITEM_HEIGHT * 2)

        -- Draw chef name
        MenuStyle.drawMenuItem(chef.name, i * 2 - 1, i == self.selected, false)

        -- Draw specialty closer to the name
        love.graphics.setFont(MenuStyle.FONTS.INSTRUCTIONS)
        love.graphics.setColor(MenuStyle.COLORS.UNSELECTED)
        love.graphics.printf(chef.specialty, 0, baseY + 35, love.graphics.getWidth(), 'center')
    end

    -- Draw instructions
    MenuStyle.drawInstructions("Use ↑↓ to select, Enter to confirm, Esc to return")
end

return ChefSelect
