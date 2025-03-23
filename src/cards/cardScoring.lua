local Constants = require('src.cards.cardConstants')

local CardScoring = {
    SCORE_TYPES = {
        WHITE = "white",
        RED = "red",
        PINK = "pink"
    }
}

function CardScoring.new()
    local self = {}
    self.whiteScore = Constants.DEFAULT_VALUES.INGREDIENT.BASIC
    self.redScore = Constants.DEFAULT_VALUES.TECHNIQUE.BASIC
    self.pinkScore = 1.5  -- Add RECIPE defaults to constants
    return self
end

function CardScoring:calculateScore(baseScore)
    if self.scoreType == self.SCORE_TYPES.WHITE then
        return baseScore + self.whiteScore
    elseif self.scoreType == self.SCORE_TYPES.RED then
        return baseScore * self.redScore
    elseif self.scoreType == self.SCORE_TYPES.PINK then
        return baseScore * self.pinkScore
    end
    return baseScore
end

return CardScoring
