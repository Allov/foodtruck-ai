local Scene = require('src.scenes.scene')
local EncounterTester = {}
EncounterTester.__index = EncounterTester

function EncounterTester.new()
    local self = setmetatable({}, EncounterTester)
    self:init()
    return self
end

function EncounterTester:init()
    self.encounters = {
        battle = {
            "food_critic",
            "rush_hour"
        },
        market = {
            "farmers_market",
            "specialty_shop",
            "supply_store"
        },
        negative = {
            "equipment_malfunction",
            "ingredient_shortage"
        },
        beneficial = {
            "food_festival",
            "master_workshop"
        },
        showdown = {
            "regional_champion",
            "master_chef"
        }
    }
    
    self.testState = {
        playerCash = 100,
        playerDeck = nil,
        currentEncounter = nil
    }
end

function EncounterTester:runTest(encounterType, encounterName)
    -- Setup test environment
    self:setupTestEnvironment()
    
    -- Load and run encounter
    local encounter = self:loadEncounter(encounterType, encounterName)
    if not encounter then
        return false, "Failed to load encounter"
    end
    
    -- Run the encounter
    local success, result = self:executeEncounter(encounter)
    
    -- Cleanup test environment
    self:cleanupTestEnvironment()
    
    return success, result
end

function EncounterTester:setupTestEnvironment()
    -- Create test deck
    self.testState.playerDeck = require('src.cards.deck').generateTestDeck()
end

return EncounterTester