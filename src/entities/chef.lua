local Chef = {}
Chef.__index = Chef

-- Define rating constants
Chef.RATINGS = {'S', 'A', 'B', 'C', 'D', 'F'}  -- From best to worst

function Chef.new(data)
    local self = setmetatable({}, Chef)

    -- Initialize with default values, overridden by provided data
    self.name = data.name or "Unknown Chef"
    self.specialty = data.specialty or "None"
    self.description = data.description or ""
    self.rating = data.rating or "C"
    self.maxRating = data.maxRating or self.rating
    self.experience = data.experience or 0
    self.cash = data.cash or 0

    -- Track achievements and stats
    self.stats = {
        battlesWon = 0,
        battlesLost = 0,
        totalScore = 0,
        perfectDishes = 0
    }

    return self
end

function Chef:getRatingIndex(rating)
    for i, r in ipairs(self.RATINGS) do
        if r == rating then
            return i
        end
    end
    return 4  -- Default to 'C' rating (index 4) if not found
end

function Chef:updateRating(newRating)
    self.rating = newRating
    -- Update max rating if new rating is better (lower index)
    if self:getRatingIndex(newRating) < self:getRatingIndex(self.maxRating) then
        self.maxRating = newRating
    end
end

function Chef:addExperience(amount)
    self.experience = self.experience + amount
    -- Could implement level-up logic here
end

function Chef:recordBattleResult(won, score)
    if won then
        self.stats.battlesWon = self.stats.battlesWon + 1
    else
        self.stats.battlesLost = self.stats.battlesLost + 1
    end
    self.stats.totalScore = self.stats.totalScore + score
end

function Chef:isPerfectDish(score, targetScore)
    if score >= (targetScore * 2) then
        self.stats.perfectDishes = self.stats.perfectDishes + 1
        return true
    end
    return false
end

return Chef
