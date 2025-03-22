-- Global scene manager
sceneManager = require('src.sceneManager')

-- Global game state
gameState = {
    currentEncounter = nil,
    selectedChef = nil,
    progress = {
        level = 1,
        score = 0,
        encounters = {}
    }
}

-- Keyboard handling
local keyPressed = {}

function love.load()
    -- Load all scenes
    local scenes = {
        mainMenu = require('src.scenes.mainMenu'),
        chefSelect = require('src.scenes.chefSelect'),
        provinceMap = require('src.scenes.provinceMap'),
        encounter = require('src.scenes.encounter')
    }

    -- Add scenes to manager
    for name, scene in pairs(scenes) do
        sceneManager:add(name, scene)
    end
    
    -- Start with main menu
    sceneManager:switch('mainMenu')
end

function love.update(dt)
    sceneManager:update(dt)
    
    -- Reset keyboard state
    keyPressed = {}
end

function love.draw()
    sceneManager:draw()
end

function love.keypressed(key)
    keyPressed[key] = true
end

-- Helper function for keyboard input
function love.keyboard.wasPressed(key)
    return keyPressed[key]
end


