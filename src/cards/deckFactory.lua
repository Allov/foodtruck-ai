local Card = require('src.cards.card')
local Deck = require('src.cards.deck')
local CardConstants = require('src.cards.cardConstants')

local DeckFactory = {}

-- Common cards that every chef starts with
local commonCards = {
    -- Quality ingredients (2)
    {id = 1, name = "Premium Knife", description = "High-quality chef's knife", cardType = "technique", value = CardConstants.DEFAULT_VALUES.TECHNIQUE.STANDARD},
    {id = 2, name = "Extra Virgin Olive Oil", description = "High-quality cooking oil", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.QUALITY},
    
    -- Standard ingredients (3)
    {id = 3, name = "Fresh Garlic", description = "Essential flavor base", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.STANDARD},
    {id = 4, name = "Yellow Onion", description = "Versatile aromatic", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.STANDARD},
    {id = 5, name = "Black Pepper", description = "Freshly ground pepper", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.STANDARD},
    
    -- Basic ingredients and techniques (4)
    {id = 6, name = "Table Salt", description = "Basic seasoning", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.BASIC},
    {id = 7, name = "Vegetable Oil", description = "Basic cooking oil", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.BASIC},
    {id = 8, name = "Dice", description = "Basic cutting technique", cardType = "technique", value = CardConstants.DEFAULT_VALUES.TECHNIQUE.BASIC},
    {id = 9, name = "Pan Fry", description = "Basic cooking technique", cardType = "technique", value = CardConstants.DEFAULT_VALUES.TECHNIQUE.BASIC}
}

-- Specialized cards for each chef
local chefCards = {
    ["Chef Antonio"] = {
        {id = 101, name = "Fresh Pasta", description = "Handmade pasta dough", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.QUALITY},
        {id = 102, name = "San Marzano Tomatoes", description = "Premium Italian tomatoes", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.QUALITY},
        {id = 103, name = "Al Dente", description = "Perfect pasta technique", cardType = "technique", value = CardConstants.DEFAULT_VALUES.TECHNIQUE.ADVANCED}
    },
    ["Chef Mei"] = {
        {id = 201, name = "Wok Hei", description = "Master wok technique", cardType = "technique", value = CardConstants.DEFAULT_VALUES.TECHNIQUE.ADVANCED},
        {id = 202, name = "Premium Soy Sauce", description = "Aged soy sauce", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.QUALITY},
        {id = 203, name = "Jasmine Rice", description = "Premium Asian rice", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.QUALITY}
    },
    ["Chef Pierre"] = {
        {id = 301, name = "French Butter", description = "Premium cultured butter", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.QUALITY},
        {id = 302, name = "Sauce Making", description = "Classic French technique", cardType = "technique", value = CardConstants.DEFAULT_VALUES.TECHNIQUE.ADVANCED},
        {id = 303, name = "Fine Herbs", description = "Premium herb blend", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.QUALITY}
    },
    ["Chef Sofia"] = {
        {id = 401, name = "Quick Prep", description = "Advanced prep technique", cardType = "technique", value = CardConstants.DEFAULT_VALUES.TECHNIQUE.ADVANCED},
        {id = 402, name = "Exotic Chilies", description = "Rare chili variety", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.QUALITY},
        {id = 403, name = "Charcoal Grilling", description = "Master grilling technique", cardType = "technique", value = CardConstants.DEFAULT_VALUES.TECHNIQUE.ADVANCED}
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
        card.value = cardData.value  -- Add the value property
        
        -- Set the appropriate score based on card type
        if card.cardType == "ingredient" then
            card.whiteScore = cardData.value
        elseif card.cardType == "technique" then
            card.redScore = cardData.value
        end
        
        deck:addCard(card)
    end
    
    -- Add chef-specific cards
    local specialCards = chefCards[chef.name]
    if specialCards then
        for _, cardData in ipairs(specialCards) do
            local card = Card.new(cardData.id, cardData.name, cardData.description)
            card.cardType = cardData.cardType
            card.value = cardData.value  -- Add the value property
            
            -- Set the appropriate score based on card type
            if card.cardType == "ingredient" then
                card.whiteScore = cardData.value
            elseif card.cardType == "technique" then
                card.redScore = cardData.value
            end
            
            deck:addCard(card)
        end
    end
    
    print("[DeckFactory] Created starter deck with " .. #deck.cards .. " cards")
    return deck
end

return DeckFactory




