local Scene = require('src.scenes.scene')
local Deck = require('src.cards.deck')
local ChefSelect = setmetatable({}, Scene)
ChefSelect.__index = ChefSelect

function ChefSelect.new()
    local self = setmetatable({}, ChefSelect)
    return self
end

function ChefSelect:generateStarterDeck(chef)
    local deck = Deck.new()
    
    -- Common cards every chef starts with
    local commonCards = {
        {name = "Basic Knife", cardType = "technique", description = "Simple cutting technique"},
        {name = "Salt", cardType = "ingredient", description = "Essential seasoning"},
        {name = "Oil", cardType = "ingredient", description = "Basic cooking oil"},
        {name = "Pan Fry", cardType = "technique", description = "Basic pan frying technique"}
    }
    
    -- Add common cards
    for _, card in ipairs(commonCards) do
        deck:addCard(card)
    end
    
    -- Specialty cards based on chef type
    if chef.name == "Chef Antonio" then
        -- Italian cuisine specialist
        deck:addCard({name = "Pasta", cardType = "ingredient", description = "Fresh pasta dough"})
        deck:addCard({name = "Tomato", cardType = "ingredient", description = "Ripe Italian tomatoes"})
        deck:addCard({name = "Basil", cardType = "ingredient", description = "Fresh aromatic basil"})
        deck:addCard({name = "Al Dente", cardType = "technique", description = "Perfect pasta cooking technique"})
        deck:addCard({name = "Basic Pasta", cardType = "recipe", description = "Simple pasta dish"})
    
    elseif chef.name == "Chef Mei" then
        -- Asian fusion specialist
        deck:addCard({name = "Rice", cardType = "ingredient", description = "Premium Asian rice"})
        deck:addCard({name = "Soy Sauce", cardType = "ingredient", description = "Traditional soy sauce"})
        deck:addCard({name = "Ginger", cardType = "ingredient", description = "Fresh ginger root"})
        deck:addCard({name = "Wok Technique", cardType = "technique", description = "Basic wok cooking"})
        deck:addCard({name = "Stir Fry", cardType = "recipe", description = "Classic stir fry dish"})
    
    elseif chef.name == "Chef Pierre" then
        -- French cuisine specialist
        deck:addCard({name = "Butter", cardType = "ingredient", description = "Premium French butter"})
        deck:addCard({name = "Cream", cardType = "ingredient", description = "Fresh heavy cream"})
        deck:addCard({name = "Herbs", cardType = "ingredient", description = "French herb blend"})
        deck:addCard({name = "Sauté", cardType = "technique", description = "Classic French sautéing"})
        deck:addCard({name = "Basic Sauce", cardType = "recipe", description = "Simple French sauce"})
    
    elseif chef.name == "Chef Sofia" then
        -- Street food specialist
        deck:addCard({name = "Flatbread", cardType = "ingredient", description = "Fresh flatbread"})
        deck:addCard({name = "Spice Mix", cardType = "ingredient", description = "Street food spice blend"})
        deck:addCard({name = "Onion", cardType = "ingredient", description = "Fresh crisp onion"})
        deck:addCard({name = "Quick Grill", cardType = "technique", description = "Fast grilling technique"})
        deck:addCard({name = "Street Wrap", cardType = "recipe", description = "Basic street wrap"})
    end
    
    return deck
end

function ChefSelect:loadChefs()
    -- Return a list of predefined chefs with their specialties
    return {
        {
            name = "Chef Antonio",
            specialty = "Italian Cuisine",
            description = "Master of pasta and traditional Italian dishes"
        },
        {
            name = "Chef Mei",
            specialty = "Asian Fusion",
            description = "Expert in combining Eastern and Western flavors"
        },
        {
            name = "Chef Pierre",
            specialty = "French Cuisine",
            description = "Classically trained in French cooking techniques"
        },
        {
            name = "Chef Sofia",
            specialty = "Street Food",
            description = "Specializes in creative street food innovations"
        }
    }
end

function ChefSelect:init()
    -- Initialize existing chef selection state
    self.chefs = self:loadChefs()
    self.selected = 1
    
    -- Initialize confirmation dialog
    self:initConfirmDialog()
end

function ChefSelect:update(dt)
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
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Select Your Chef", 0, 50, love.graphics.getWidth(), 'center')
    
    for i, chef in ipairs(self.chefs) do
        if i == self.selected then
            love.graphics.setColor(1, 1, 0, 1)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
        love.graphics.printf(
            chef.name .. "\n" .. chef.specialty,
            0, 150 + i * 60,
            love.graphics.getWidth(),
            'center'
        )
    end

    -- Draw confirmation dialog if active
    if self.showingConfirmDialog then
        self:drawConfirmDialog()
    end
end

return ChefSelect




