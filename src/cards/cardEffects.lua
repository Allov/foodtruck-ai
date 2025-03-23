local CardEffects = {
    EFFECT_TYPES = {
        BOOST = "boost",
        COMBO = "combo",
        SPECIAL = "special"
    }
}
CardEffects.__index = CardEffects  -- Add this line to set up proper inheritance

function CardEffects.new()
    local self = setmetatable({}, CardEffects)  -- Use setmetatable to set up inheritance
    self.effects = {}
    return self
end

function CardEffects:addEffect(effectType, value, duration)
    table.insert(self.effects, {
        type = effectType,
        value = value,
        duration = duration
    })
end

function CardEffects:getEffects()
    return self.effects
end

function CardEffects:updateEffects()
    -- Remove expired effects
    for i = #self.effects, 1, -1 do
        local effect = self.effects[i]
        if effect.duration then
            effect.duration = effect.duration - 1
            if effect.duration <= 0 then
                table.remove(self.effects, i)
            end
        end
    end
end

return CardEffects
