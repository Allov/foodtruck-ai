local BaseMenu = require('src.scenes.baseMenu')
local MenuStyle = require('src.ui.menuStyle')

local ChefSelect = {}
ChefSelect.__index = ChefSelect
setmetatable(ChefSelect, BaseMenu)

function ChefSelect.new()
    local self = BaseMenu.new()
    setmetatable(self, ChefSelect)
    self:init()
    return self
end

function ChefSelect:init()
    BaseMenu.init(self)
    self.chefs = self:loadChefs()
    self.options = self:createChefOptions()
    self:setupClickables()
end

function ChefSelect:loadChefs()
    return {
        {
            name = "Chef Antonio",
            specialty = "Italian Cuisine",
            description = "Specializes in pasta and traditional Italian dishes",
            starterCards = {"Basic Pasta", "Tomato Sauce", "Garlic Bread"},
            rating = "C"
        },
        {
            name = "Chef Ming",
            specialty = "Asian Fusion",
            description = "Masters the art of combining Asian flavors",
            starterCards = {"Stir Fry", "Steam Buns", "Rice Bowl"},
            rating = "C"
        },
        {
            name = "Chef Pierre",
            specialty = "French Cuisine",
            description = "Expert in classical French techniques",
            starterCards = {"Basic Sauce", "Fresh Bread", "Herb Mix"},
            rating = "C"
        }
    }
end

function ChefSelect:createChefOptions()
    local options = {}
    for i, chef in ipairs(self.chefs) do
        options[i] = {
            name = chef.name,
            description = chef.description,
            specialty = chef.specialty
        }
    end
    return options
end

function ChefSelect:getOptionText(option)
    return option.name .. " - " .. option.specialty
end

function ChefSelect:onClick(index)
    local selectedChefData = self.chefs[index]
    -- Create a proper Chef instance instead of using raw data
    local Chef = require('src.entities.chef')
    local chef = Chef.new({
        name = selectedChefData.name,
        specialty = selectedChefData.specialty,
        description = selectedChefData.description,
        rating = selectedChefData.rating
    })

    gameState.selectedChef = chef
    gameState.currentDeck = self:generateStarterDeck(selectedChefData)
    sceneManager:switch('provinceMap')
end

function ChefSelect:generateStarterDeck(chef)
    local DeckFactory = require('src.cards.deckFactory')
    return DeckFactory.createStarterDeck(chef)
end

function ChefSelect:drawChefInfo()
    if not (self.selected and self.selected > 0 and self.selected <= #self.options) then
        return
    end

    local chef = self.chefs[self.selected]

    -- Panel dimensions and position
    local padding = 20
    local lineHeight = 24
    local panelWidth = 500
    local panelHeight = 180 + padding * 2  -- Added padding to height
    local x = (love.graphics.getWidth() - panelWidth) / 2
    local y = MenuStyle.LAYOUT.DESCRIPTION_Y + 20  -- Changed from -20 to +20 to lower the panel

    -- Draw panel background with semi-transparent dark blue
    love.graphics.setColor(0.1, 0.15, 0.2, 0.9)
    love.graphics.rectangle('fill', x, y, panelWidth, panelHeight)

    -- Draw border with subtle glow
    love.graphics.setColor(1, 0.8, 0.2, 0.8)  -- Gold border
    love.graphics.setLineWidth(2)
    love.graphics.rectangle('line', x, y, panelWidth, panelHeight)

    -- Content positioning
    local textX = x + padding
    local textY = y + padding  -- Start text with padding from top

    -- Chef description
    love.graphics.setFont(MenuStyle.FONTS.DESCRIPTION)

    -- Chef specialty with styled header
    love.graphics.setColor(1, 0.8, 0.2, 1)  -- Gold for specialty
    love.graphics.print("Specialty: " .. chef.specialty, textX, textY)
    textY = textY + lineHeight

    -- Description with different color
    love.graphics.setColor(0.9, 0.9, 0.9, 1)  -- Soft white for description
    love.graphics.printf(chef.description, textX, textY, panelWidth - (padding * 2), 'left')
    textY = textY + lineHeight * 2

    -- Starter deck section
    love.graphics.setColor(1, 0.8, 0.2, 1)  -- Gold for header
    love.graphics.print("Starter Cards:", textX, textY)
    textY = textY + lineHeight

    -- Card list with different styling
    love.graphics.setColor(0.8, 0.8, 1, 1)  -- Light blue for cards
    for i, card in ipairs(chef.starterCards) do
        love.graphics.print("• " .. card, textX + padding, textY)
        textY = textY + lineHeight
    end
end

function ChefSelect:draw()
    BaseMenu.draw(self)
    self:drawTitle("Choose Your Chef")
    self:drawChefInfo()
    MenuStyle.drawInstructions(
        "Use ↑↓ or mouse to select, Enter or click to confirm"
    )
end

return ChefSelect







