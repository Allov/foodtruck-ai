local Deck = {}
Deck.__index = Deck

function Deck.new()
    local self = setmetatable({}, Deck)
    self.cards = {}        -- All cards in the deck
    self.drawPile = {}     -- Cards available to draw
    self.discardPile = {}  -- Cards that have been used/discarded
    return self
end

-- Add a card to the deck
function Deck:addCard(card)
    table.insert(self.cards, card)
    table.insert(self.drawPile, card)
end

-- Shuffle the draw pile
function Deck:shuffle()
    local randomized = {}
    while #self.drawPile > 0 do
        local randomIndex = love.math.random(#self.drawPile)
        table.insert(randomized, self.drawPile[randomIndex])
        table.remove(self.drawPile, randomIndex)
    end
    self.drawPile = randomized
end

-- Draw a card from the deck
function Deck:draw()
    if #self.drawPile == 0 then
        -- If draw pile is empty, shuffle discard pile into draw pile
        self.drawPile = self.discardPile
        self.discardPile = {}
        self:shuffle()
    end
    
    if #self.drawPile > 0 then
        return table.remove(self.drawPile)
    end
    return nil
end

-- Discard a card
function Deck:discard(card)
    table.insert(self.discardPile, card)
end

-- Get counts of cards in different piles
function Deck:getCounts()
    return {
        total = #self.cards,
        draw = #self.drawPile,
        discard = #self.discardPile
    }
end

-- Add this function to generate a test deck
function Deck.generateTestDeck()
    local deck = Deck.new()
    
    local cardTypes = {"ingredient", "technique", "recipe"}
    local ingredients = {"Tomato", "Onion", "Garlic", "Beef", "Chicken", "Rice", "Potato"}
    local techniques = {"Dice", "Slice", "Grill", "Fry", "Boil", "Bake", "Sauté"}
    local recipes = {"Burger", "Stir Fry", "Soup", "Curry", "Pasta", "Salad"}
    
    -- Add 15 ingredient cards
    for i = 1, 15 do
        local name = ingredients[love.math.random(#ingredients)]
        deck:addCard({
            id = love.math.random(1000),
            name = name,
            description = "A fresh " .. string.lower(name),
            cardType = "ingredient"
        })
    end
    
    -- Add 10 technique cards
    for i = 1, 10 do
        local name = techniques[love.math.random(#techniques)]
        deck:addCard({
            id = love.math.random(1000),
            name = name,
            description = name .. " your ingredients",
            cardType = "technique"
        })
    end
    
    -- Add 5 recipe cards
    for i = 1, 5 do
        local name = recipes[love.math.random(#recipes)]
        deck:addCard({
            id = love.math.random(1000),
            name = name,
            description = "Create a delicious " .. string.lower(name),
            cardType = "recipe"
        })
    end
    
    return deck
end

return Deck
