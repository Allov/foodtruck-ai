local Constants = require('src.cards.cardConstants')

local CardScoring = {}
CardScoring.__index = CardScoring  -- This is crucial! Add this line

CardScoring.SCORE_TYPES = {
    WHITE = "white",
    RED = "red",
    PINK = "pink"
}

function CardScoring.new()
    local self = setmetatable({}, CardScoring)
    self.whiteScore = Constants.DEFAULT_VALUES.INGREDIENT.BASIC
    self.redScore = Constants.DEFAULT_VALUES.TECHNIQUE.BASIC
    self.pinkScore = 1.5  -- Add RECIPE defaults to constants
    return self
end

function CardScoring:getValue()
    if self.scoreType == self.SCORE_TYPES.WHITE then
        return self.whiteScore
    elseif self.scoreType == self.SCORE_TYPES.RED then
        return self.redScore
    elseif self.scoreType == self.SCORE_TYPES.PINK then
        return self.pinkScore
    end
    return 0
end

return CardScoring
