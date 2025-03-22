local Scene = require('src.scenes.scene')
local Encounter = setmetatable({}, Scene)
Encounter.__index = Encounter

function Encounter.new()
    local self = setmetatable({}, Encounter)
    -- Initialize base state
    self.state = {
        type = nil,
        title = "",
        description = "",
        options = {}
    }
    return self
end

-- Add other Encounter methods here

return Encounter
