local Card = require('src.cards.card')
local CardConstants = require('src.cards.cardConstants')

local PackFactory = {}

-- Common items available in all markets
local commonStock = {
    {id = 1001, name = "Table Salt", description = "Basic seasoning", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.BASIC, cost = 1},
    {id = 1002, name = "Ground Pepper", description = "Basic spice", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.BASIC, cost = 1},
    {id = 1003, name = "Vegetable Oil", description = "Basic cooking oil", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.BASIC, cost = 2}
}

-- Market-specific items
local marketStock = {
    ["farmers_market"] = {
        {id = 2001, name = "Heirloom Tomatoes", description = "Premium local variety", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.QUALITY, cost = 4},
        {id = 2002, name = "Fresh Herbs", description = "Just picked herbs", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.STANDARD, cost = 3},
        {id = 2003, name = "Wild-Caught Fish", description = "Today's catch", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.QUALITY, cost = 5},
        {id = 2004, name = "Seasonal Vegetables", description = "Peak season produce", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.STANDARD, cost = 3}
    },
    ["specialty_shop"] = {
        {id = 3001, name = "Black Truffle", description = "Rare delicacy", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.EXOTIC, cost = 8},
        {id = 3002, name = "Saffron", description = "Premium spice", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.PREMIUM, cost = 7},
        {id = 3003, name = "Aged Balsamic", description = "25-year aged vinegar", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.PREMIUM, cost = 6},
        {id = 3004, name = "Wagyu Beef", description = "A5 grade beef", cardType = "ingredient", value = CardConstants.DEFAULT_VALUES.INGREDIENT.EXOTIC, cost = 9}
    },
    ["culinary_school"] = {
        {id = 4001, name = "Sous Vide", description = "Precise temperature control", cardType = "technique", value = CardConstants.DEFAULT_VALUES.TECHNIQUE.ADVANCED, cost = 6},
        {id = 4002, name = "Molecular Gastronomy", description = "Scientific cooking approach", cardType = "technique", value = CardConstants.DEFAULT_VALUES.TECHNIQUE.EXPERT, cost = 8},
        {id = 4003, name = "Classical French", description = "Traditional techniques", cardType = "technique", value = CardConstants.DEFAULT_VALUES.TECHNIQUE.ADVANCED, cost = 5}
    }
}

function PackFactory.generatePack(marketType, size)
    if not marketType or not marketStock[marketType] then
        return {}
    end

    size = size or love.math.random(4, 6)
    local pack = {}
    
    -- Add some common items (25% chance for each)
    for _, itemData in ipairs(commonStock) do
        if love.math.random() < 0.25 and #pack < size then
            local card
            if itemData.cardType == "ingredient" then
                card = Card.createIngredient(itemData.id, itemData.name, itemData.description, itemData.value)
            elseif itemData.cardType == "technique" then
                card = Card.createTechnique(itemData.id, itemData.name, itemData.description, itemData.value)
            elseif itemData.cardType == "recipe" then
                card = Card.createRecipe(itemData.id, itemData.name, itemData.description, itemData.value)
            end
            
            if card then
                card.cost = itemData.cost
                table.insert(pack, card)
            end
        end
    end
    
    -- Fill remaining slots with market-specific items
    local marketItems = marketStock[marketType]
    while #pack < size and #marketItems > 0 do
        local index = love.math.random(#marketItems)
        local itemData = marketItems[index]
        
        local card
        if itemData.cardType == "ingredient" then
            card = Card.createIngredient(itemData.id, itemData.name, itemData.description, itemData.value)
        elseif itemData.cardType == "technique" then
            card = Card.createTechnique(itemData.id, itemData.name, itemData.description, itemData.value)
        elseif itemData.cardType == "recipe" then
            card = Card.createRecipe(itemData.id, itemData.name, itemData.description, itemData.value)
        end
        
        if card then
            card.cost = itemData.cost
            table.insert(pack, card)
        end
        
        -- Remove used item to avoid duplicates
        table.remove(marketItems, index)
    end
    
    -- Sort by cost
    table.sort(pack, function(a, b) return a.cost < b.cost end)
    
    return pack
end

return PackFactory
