local TestRunner = require('tests.init')
local Settings = require('src.settings')

-- Test Settings module
TestRunner:addTest("Settings initialization", function(t)
    local settings = Settings:init()
    t:assert(settings.initialized, "Settings should be initialized")
    t:assert(settings.baseResolution.width == 1280, "Default resolution width should be 1280")
    t:assert(settings.baseResolution.height == 720, "Default resolution height should be 720")
end)

TestRunner:addTest("Settings save/load", function(t)
    local settings = Settings:init()
    settings.testValue = "test"
    
    -- Test save
    local saveSuccess = settings:save()
    t:assert(saveSuccess, "Settings should save successfully")
    
    -- Reset value
    settings.testValue = nil
    
    -- Test load
    local loadSuccess = settings:load()
    t:assert(loadSuccess, "Settings should load successfully")
    t:assert(settings.testValue == "test", "Loaded value should match saved value")
end)

TestRunner:addTest("Settings serialization", function(t)
    local settings = Settings:init()
    local serialized = settings:serialize({
        test = true,
        number = 42,
        string = "hello"
    })
    t:assert(type(serialized) == "string", "Serialized output should be string")
    t:assert(serialized:match("^{.*}$"), "Serialized output should be table syntax")
end)

return TestRunner