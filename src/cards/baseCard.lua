local BaseCard = {
    -- Core properties
    CARD_WIDTH = 120,
    CARD_HEIGHT = 180,
    CARD_TYPES = {
        INGREDIENT = "ingredient",
        TECHNIQUE = "technique",
        RECIPE = "recipe",
        ACTION = "action"     -- Add action type
    }
}
BaseCard.__index = BaseCard

function BaseCard.getDimensions()
    return BaseCard.CARD_WIDTH, BaseCard.CARD_HEIGHT
end

function BaseCard.new(id, name, description)
    local self = setmetatable({}, BaseCard)
    self.id = id
    self.name = name
    self.description = description
    self.cardType = nil  -- Must be set by derived classes
    return self
end

function BaseCard:validate()
    local errors = {}
    
    if not self.id then table.insert(errors, "Missing card ID") end
    if not self.name then table.insert(errors, "Missing card name") end
    if not self.description then table.insert(errors, "Missing card description") end
    if not self.cardType then table.insert(errors, "Card type not set") end
    
    return #errors == 0, errors
end

function BaseCard:serialize()
    return {
        id = self.id,
        name = self.name,
        description = self.description,
        cardType = self.cardType
    }
end

return BaseCard
