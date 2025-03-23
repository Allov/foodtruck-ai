local TestHelpers = {}

-- Unified createTestCard function that handles all test cases
function TestHelpers.createTestCard(name, cardType, params)
    params = params or {}

    local card = {
        name = name,
        cardType = cardType,
        tags = params.tags or {},
        scoring = {
            getValue = function()
                return params.scoreValue or 0
            end
        },
        -- Optional animation method
        showScoreAnimation = params.showScoreAnimation or function(self, value) end
    }

    return card
end

return TestHelpers

