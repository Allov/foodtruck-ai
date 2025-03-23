local Card = require('src.cards.card')
local Deck = require('src.cards.deck')

local DeckFactory = {}

-- Common cards that every chef starts with
local commonCards = {
    {id = 1, name = "Basic Knife", description = "Simple cutting technique", cardType = "technique"},
    {id = 2, name = "Salt", description = "Essential seasoning", cardType = "ingredient"},
    {id = 3, name = "Oil", description = "Basic cooking oil", cardType = "ingredient"},
    {id = 4, name = "Pan Fry", description = "Basic pan frying technique", cardType = "technique"},
    -- Adding more common cards
    {id = 5, name = "Onion", description = "Basic aromatic vegetable", cardType = "ingredient"},
    {id = 6, name = "Garlic", description = "Essential flavor base", cardType = "ingredient"},
    {id = 7, name = "Black Pepper", description = "Basic spice", cardType = "ingredient"},
    {id = 8, name = "Boil", description = "Basic boiling technique", cardType = "technique"},
    {id = 9, name = "Chop", description = "Basic chopping technique", cardType = "technique"},
    {id = 10, name = "Steam", description = "Basic steaming technique", cardType = "technique"},
    {id = 11, name = "Water", description = "Basic cooking liquid", cardType = "ingredient"},
    {id = 12, name = "Mix", description = "Basic mixing technique", cardType = "technique"}
}

-- Specialized cards for each chef
local chefCards = {
    ["Chef Antonio"] = {
        {id = 101, name = "Pasta Base", description = "Fresh pasta dough", cardType = "ingredient"},
        {id = 102, name = "Tomato", description = "Fresh Italian tomatoes", cardType = "ingredient"},
        {id = 103, name = "Al Dente", description = "Perfect pasta cooking technique", cardType = "technique"}
    },
    ["Chef Mei"] = {
        {id = 201, name = "Wok", description = "High-heat stir frying", cardType = "technique"},
        {id = 202, name = "Soy Sauce", description = "Traditional Asian seasoning", cardType = "ingredient"},
        {id = 203, name = "Rice", description = "Premium Asian rice", cardType = "ingredient"}
    },
    ["Chef Pierre"] = {
        {id = 301, name = "Butter", description = "High-quality French butter", cardType = "ingredient"},
        {id = 302, name = "Deglaze", description = "Classic French pan sauce technique", cardType = "technique"},
        {id = 303, name = "Herbs de Provence", description = "Traditional French herb blend", cardType = "ingredient"}
    },
    ["Chef Sofia"] = {
        {id = 401, name = "Quick Prep", description = "Fast ingredient preparation", cardType = "technique"},
        {id = 402, name = "Chili", description = "Fresh hot chilies", cardType = "ingredient"},
        {id = 403, name = "Street Grill", description = "High-heat grilling technique", cardType = "technique"}
    }
}

function DeckFactory.createStarterDeck(chef)
    if not chef or not chef.name then
        return Deck.new()  -- Return empty deck if no chef provided
    end

    local deck = Deck.new()
    
    -- Add common cards
    for _, cardData in ipairs(commonCards) do
        local card = Card.new(cardData.id, cardData.name, cardData.description)
        card.cardType = cardData.cardType
        deck:addCard(card)
    end
    
    -- Add chef-specific cards
    local specialCards = chefCards[chef.name]
    if specialCards then
        for _, cardData in ipairs(specialCards) do
            local card = Card.new(cardData.id, cardData.name, cardData.description)
            card.cardType = cardData.cardType
            deck:addCard(card)
        end
    end
    
    print("[DeckFactory] Created starter deck with " .. #deck.cards .. " cards")
    return deck
end

return DeckFactory


