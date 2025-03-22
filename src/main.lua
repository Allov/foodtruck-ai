-- Global managers
sceneManager = require('src.sceneManager')
gameManager = require('src.gameManager')

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

local Main = {}

function Main.load()
    -- Load all scenes
    local scenes = {
        mainMenu = require('src.scenes.mainMenu'),
        seedInput = require('src.scenes.seedInput'),
        chefSelect = require('src.scenes.chefSelect'),
        provinceMap = require('src.scenes.provinceMap'),
        encounter = require('src.scenes.encounter'),
        debugMenu = require('src.scenes.debugMenu'),
        encounterTester = require('src.scenes.encounterTester'),
        deckViewer = require('src.scenes.deckViewer'),
        game = require('src.scenes.game')
    }

    -- Add scenes to manager
    for name, scene in pairs(scenes) do
        sceneManager:add(name, scene)
    end
    
    -- Initialize game manager
    gameManager:init()
    
    -- Start with main menu
    sceneManager:switch('mainMenu')
end

function Main.update(dt)
    -- Update game manager first to handle global actions
    gameManager:update(dt)
    -- Then update current scene
    sceneManager:update(dt)
    
    -- Reset keyboard states
    love.keyboard.keysPressed = {}
    love.keyboard.keysReleased = {}
end

function Main.draw()
    sceneManager:draw()
end

function Main.keypressed(key)
    love.keyboard.keysPressed[key] = true
end

function Main.keyreleased(key)
    love.keyboard.keysReleased[key] = true
end

function Main.textinput(t)
    if sceneManager.current and sceneManager.current.inputtingSeed then
        -- Only allow alphanumeric characters and some basic punctuation
        if t:match("^[%w%s%-_%.]+$") then
            sceneManager.current.seedInput = sceneManager.current.seedInput .. t
        end
    end
end

-- Initialize keyboard state
love.keyboard.keysPressed = {}
love.keyboard.keysReleased = {}

function love.keyboard.wasPressed(key)
    return love.keyboard.keysPressed[key]
end

return Main
