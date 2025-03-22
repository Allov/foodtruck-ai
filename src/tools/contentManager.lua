local ContentManager = {
    content = {
        cards = {},
        encounters = {},
        chefs = {}
    }
}

function ContentManager:init()
    self:loadContent()
end

function ContentManager:loadContent()
    -- Load card definitions
    self:loadCards()
    -- Load encounter definitions
    self:loadEncounters()
    -- Load chef definitions
    self:loadChefs()
end

function ContentManager:loadCards()
    -- TODO: Load from actual data files
    self.content.cards = {
        -- Example card definitions
        card_001 = {
            id = "card_001",
            name = "Tomato",
            description = "A fresh tomato",
            cardType = "ingredient",
            cost = 1
        },
        card_002 = {
            id = "card_002",
            name = "Dice",
            description = "Dice ingredients finely",
            cardType = "technique",
            cost = 2
        }
    }
end

function ContentManager:loadEncounters()
    -- TODO: Load from actual data files
    self.content.encounters = {
        -- Example encounter definitions
        food_critic = {
            type = "battle",
            name = "Food Critic Challenge",
            difficulty = 1
        },
        farmers_market = {
            type = "market",
            name = "Farmers Market",
            inventory_size = 6
        }
    }
end

function ContentManager:loadChefs()
    -- TODO: Load from actual data files
    self.content.chefs = {
        -- Example chef definitions
        chef_001 = {
            id = "chef_001",
            name = "Chef Bob",
            specialty = "Italian Cuisine",
            starting_deck = {"card_001", "card_002"}
        }
    }
end

function ContentManager:validateContent()
    local errors = {}
    
    -- Validate cards
    for id, card in pairs(self.content.cards) do
        local cardTester = require('src.tools.cardTester').new()
        local valid, cardErrors = cardTester:validateCard(card)
        if not valid then
            errors[id] = cardErrors
        end
    end
    
    -- Validate encounters
    -- Add encounter validation logic
    
    return #errors == 0, errors
end

function ContentManager:exportContent(path)
    -- Export content to JSON for external editing
    local json = require('lib.json')
    local file = io.open(path, "w")
    if file then
        file:write(json.encode(self.content))
        file:close()
        return true
    end
    return false
end

return ContentManager
