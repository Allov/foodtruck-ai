local Card = require('src.cards.card')

local PackFactory = {}

-- Common items available in all markets
local commonStock = {
    {id = 1001, name = "Salt", description = "Basic seasoning", cardType = "ingredient", cost = 2},
    {id = 1002, name = "Pepper", description = "Common spice", cardType = "ingredient", cost = 2},
    {id = 1003, name = "Cooking Oil", description = "All-purpose oil", cardType = "ingredient", cost = 3}
}

-- Market-specific items
local marketStock = {
    ["farmers_market"] = {
        {id = 2001, name = "Fresh Tomatoes", description = "Basic but versatile", cardType = "ingredient", cost = 3},
        {id = 2002, name = "Local Herbs", description = "Adds flavor to any dish", cardType = "ingredient", cost = 4},
        {id = 2003, name = "Fresh Fish", description = "Caught this morning", cardType = "ingredient", cost = 6},
        {id = 2004, name = "Seasonal Vegetables", description = "A mix of local produce", cardType = "ingredient", cost = 3},
        {id = 2005, name = "Farm Eggs", description = "Fresh from the coop", cardType = "ingredient", cost = 2},
        {id = 2006, name = "Wild Mushrooms", description = "Locally foraged", cardType = "ingredient", cost = 5}
    },
    ["specialty_shop"] = {
        -- Premium ingredients
        {id = 3001, name = "Truffle", description = "Rare delicacy", cardType = "ingredient", cost = 8},
        {id = 3002, name = "Saffron", description = "Precious spice", cardType = "ingredient", cost = 7},
        {id = 3003, name = "Aged Vinegar", description = "Artisanal product", cardType = "ingredient", cost = 5}
    },
    ["supply_store"] = {
        -- Tools and bulk items
        {id = 4001, name = "Sharp Knife", description = "Improved cutting speed", cardType = "technique", cost = 5},
        {id = 4002, name = "Steel Pan", description = "Better heat control", cardType = "technique", cost = 6},
        {id = 4003, name = "Stock Pot", description = "For soups and stocks", cardType = "technique", cost = 7}
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
            local card = Card.new(itemData.id, itemData.name, itemData.description)
            card.cardType = itemData.cardType
            card.cost = itemData.cost
            table.insert(pack, card)
        end
    end
    
    -- Fill remaining slots with market-specific items
    local marketItems = marketStock[marketType]
    while #pack < size and #marketItems > 0 do
        local index = love.math.random(#marketItems)
        local itemData = marketItems[index]
        
        local card = Card.new(itemData.id, itemData.name, itemData.description)
        card.cardType = itemData.cardType
        card.cost = itemData.cost
        table.insert(pack, card)
        
        -- Remove used item to avoid duplicates
        table.remove(marketItems, index)
    end
    
    -- Sort by cost
    table.sort(pack, function(a, b) return a.cost < b.cost end)
    
    return pack
end

return PackFactory