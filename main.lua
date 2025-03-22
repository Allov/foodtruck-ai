-- Global scene manager
sceneManager = require('src.sceneManager')

-- Global game state
gameState = {
    currentEncounter = nil,
    selectedChef = nil,
    mapSeed = nil,  -- Store the current map seed
    progress = {
        level = 1,
        score = 0,
        encounters = {}
    }
}

-- Keyboard handling
love.keyboard.keysPressed = {}
love.keyboard.keysReleased = {}

function love.keypressed(key)
    love.keyboard.keysPressed[key] = true
end

function love.keyreleased(key)
    love.keyboard.keysReleased[key] = true
end

function love.keyboard.wasPressed(key)
    return love.keyboard.keysPressed[key]
end

function love.load()
    -- Load all scenes
    local scenes = {
        mainMenu = require('src.scenes.mainMenu'),
        seedInput = require('src.scenes.seedInput'),
        chefSelect = require('src.scenes.chefSelect'),
        provinceMap = require('src.scenes.provinceMap'),
        encounter = require('src.scenes.encounter'),
        debugMenu = require('src.scenes.debugMenu'),
        encounterTester = require('src.scenes.encounterTester')
    }

    -- Add scenes to manager
    for name, scene in pairs(scenes) do
        sceneManager:add(name, scene)
    end
    
    -- Start with main menu
    sceneManager:switch('mainMenu')
end

-- Add textinput callback
function love.textinput(t)
    if sceneManager.current and sceneManager.current.inputtingSeed then
        -- Only allow alphanumeric characters and some basic punctuation
        if t:match("^[%w%s%-_%.]+$") then
            sceneManager.current.seedInput = sceneManager.current.seedInput .. t
        end
    end
end

function love.update(dt)
    sceneManager:update(dt)
    
    -- Reset keyboard states
    love.keyboard.keysPressed = {}
    love.keyboard.keysReleased = {}
end

function love.draw()
    sceneManager:draw()
end






