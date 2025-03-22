local EncounterRegistry = {
    encounters = {},
    typeToScene = {}
}

-- Register an encounter type and its associated scene
function EncounterRegistry:register(encounterType, sceneClass, config)
    self.encounters[encounterType] = {
        sceneClass = sceneClass,
        config = config or {}
    }
end

-- Get the appropriate scene class for an encounter type
function EncounterRegistry:getSceneClass(encounterType)
    local encounter = self.encounters[encounterType]
    return encounter and encounter.sceneClass
end

-- Get configuration for an encounter type
function EncounterRegistry:getConfig(encounterType)
    local encounter = self.encounters[encounterType]
    return encounter and encounter.config
end

return EncounterRegistry