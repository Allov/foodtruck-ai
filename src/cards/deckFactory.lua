local Card = require('src.cards.card')
local Deck = require('src.cards.deck')
local CardConstants = require('src.cards.cardConstants')

local DeckFactory = {}

-- Common cards that every chef starts with
local commonCards = {
    -- Quality techniques (3)
    {id = 1, name = "Premium Knife", description = "High-quality chef's knife", cardType = "technique", value = CardConstants.DEFAULT_VALUES.TECHNIQUE.STANDARD},
    {id = 2, name = "Kitchen Basics", description = "Fundamental cooking skills", cardType = "technique", value = CardConstants.DEFAULT_VALUES.TECHNIQUE.STANDARD},
    {id = 3, name = "Heat Control", description = "Temperature management mastery", cardType = "technique", value = CardConstants.DEFAULT_VALUES.TECHNIQUE.STANDARD},

    -- Quality ingredients (3)
    {id = 4, name = "Extra Virgin Olive Oil", description = "High-quality cooking oil", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.QUALITY},
    {id = 5, name = "Fresh Herbs", description = "Assorted fresh herbs", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.QUALITY},
    {id = 6, name = "Sea Salt", description = "Premium sea salt flakes", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.QUALITY},

    -- Standard ingredients (4)
    {id = 7, name = "Fresh Garlic", description = "Essential flavor base", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.STANDARD},
    {id = 8, name = "Yellow Onion", description = "Versatile aromatic", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.STANDARD},
    {id = 9, name = "Black Pepper", description = "Freshly ground pepper", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.STANDARD},
    {id = 10, name = "Fresh Vegetables", description = "Seasonal vegetable mix", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.STANDARD},

    -- Basic ingredients and techniques (5)
    {id = 11, name = "Table Salt", description = "Basic seasoning", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.BASIC},
    {id = 12, name = "Vegetable Oil", description = "Basic cooking oil", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.BASIC},
    {id = 13, name = "Dice", description = "Basic cutting technique", cardType = "technique", value = CardConstants.DEFAULT_VALUES.TECHNIQUE.BASIC},
    {id = 14, name = "Pan Fry", description = "Basic cooking technique", cardType = "technique", value = CardConstants.DEFAULT_VALUES.TECHNIQUE.BASIC},
    {id = 15, name = "Basic Seasoning", description = "Simple seasoning technique", cardType = "technique", value = CardConstants.DEFAULT_VALUES.TECHNIQUE.BASIC}
}

-- Specialized cards for each chef
local chefCards = {
    ["Chef Antonio"] = {
        -- Advanced Techniques (3)
        {id = 101, name = "Al Dente", description = "Perfect pasta technique", cardType = "technique", value = CardConstants.DEFAULT_VALUES.TECHNIQUE.ADVANCED},
        {id = 102, name = "Sauce Master", description = "Italian sauce expertise", cardType = "technique", value = CardConstants.DEFAULT_VALUES.TECHNIQUE.ADVANCED},
        {id = 103, name = "Hand-Made Pasta", description = "Traditional pasta making", cardType = "technique", value = CardConstants.DEFAULT_VALUES.TECHNIQUE.ADVANCED},

        -- Quality Ingredients (4)
        {id = 104, name = "Fresh Pasta", description = "Handmade pasta dough", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.QUALITY},
        {id = 105, name = "San Marzano Tomatoes", description = "Premium Italian tomatoes", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.QUALITY},
        {id = 106, name = "Parmigiano-Reggiano", description = "Aged Italian cheese", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.QUALITY},
        {id = 107, name = "Italian Herbs", description = "Classic herb blend", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.QUALITY}
    },

    ["Chef Mei"] = {
        -- Advanced Techniques (3)
        {id = 201, name = "Wok Hei", description = "Master wok technique", cardType = "technique", value = CardConstants.DEFAULT_VALUES.TECHNIQUE.ADVANCED},
        {id = 202, name = "Quick Fire", description = "High heat mastery", cardType = "technique", value = CardConstants.DEFAULT_VALUES.TECHNIQUE.ADVANCED},
        {id = 203, name = "Knife Artistry", description = "Precise cutting skills", cardType = "technique", value = CardConstants.DEFAULT_VALUES.TECHNIQUE.ADVANCED},

        -- Quality Ingredients (4)
        {id = 204, name = "Premium Soy Sauce", description = "Aged soy sauce", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.QUALITY},
        {id = 205, name = "Jasmine Rice", description = "Premium Asian rice", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.QUALITY},
        {id = 206, name = "Shaoxing Wine", description = "Chinese cooking wine", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.QUALITY},
        {id = 207, name = "Fresh Ginger", description = "Premium ginger root", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.QUALITY}
    },

    ["Chef Pierre"] = {
        -- Advanced Techniques (3)
        {id = 301, name = "Sauce Making", description = "Classic French technique", cardType = "technique", value = CardConstants.DEFAULT_VALUES.TECHNIQUE.ADVANCED},
        {id = 302, name = "Mise en Place", description = "Perfect preparation", cardType = "technique", value = CardConstants.DEFAULT_VALUES.TECHNIQUE.ADVANCED},
        {id = 303, name = "French Method", description = "Traditional techniques", cardType = "technique", value = CardConstants.DEFAULT_VALUES.TECHNIQUE.ADVANCED},

        -- Quality Ingredients (4)
        {id = 304, name = "French Butter", description = "Premium cultured butter", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.QUALITY},
        {id = 305, name = "Fine Herbs", description = "Premium herb blend", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.QUALITY},
        {id = 306, name = "Shallots", description = "French shallots", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.QUALITY},
        {id = 307, name = "White Wine", description = "Cooking wine", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.QUALITY}
    },

    ["Chef Sofia"] = {
        -- Advanced Techniques (3)
        {id = 401, name = "Quick Prep", description = "Advanced prep technique", cardType = "technique", value = CardConstants.DEFAULT_VALUES.TECHNIQUE.ADVANCED},
        {id = 402, name = "Charcoal Grilling", description = "Master grilling technique", cardType = "technique", value = CardConstants.DEFAULT_VALUES.TECHNIQUE.ADVANCED},
        {id = 403, name = "Street Smart", description = "Efficient cooking method", cardType = "technique", value = CardConstants.DEFAULT_VALUES.TECHNIQUE.ADVANCED},

        -- Quality Ingredients (4)
        {id = 404, name = "Exotic Chilies", description = "Rare chili variety", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.QUALITY},
        {id = 405, name = "Fresh Lime", description = "Zesty citrus", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.QUALITY},
        {id = 406, name = "Street Spices", description = "Special spice blend", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.QUALITY},
        {id = 407, name = "Fresh Cilantro", description = "Aromatic herbs", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.QUALITY}
    }
}

local function createCardFromData(cardData)
    if cardData.cardType == "ingredient" then
        return Card.createIngredient(cardData.id, cardData.name, cardData.description, cardData.value)
    elseif cardData.cardType == "technique" then
        return Card.createTechnique(cardData.id, cardData.name, cardData.description, cardData.value)
    elseif cardData.cardType == "recipe" then
        return Card.createRecipe(cardData.id, cardData.name, cardData.description, cardData.value)
    end
    return nil
end

function DeckFactory.createStarterDeck(chef)
    if not chef or not chef.name then
        return Deck.new()  -- Return empty deck if no chef provided
    end

    local deck = Deck.new()

    -- Add common cards
    for _, cardData in ipairs(commonCards) do
        local card = createCardFromData(cardData)
        if card then
            deck:addCard(card)
        end
    end

    -- Add chef-specific cards
    local specialCards = chefCards[chef.name]
    if specialCards then
        for _, cardData in ipairs(specialCards) do
            local card = createCardFromData(cardData)
            if card then
                deck:addCard(card)
            end
        end
    end

    return deck
end

return DeckFactory




