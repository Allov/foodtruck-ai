-- Global managers
sceneManager = require('src.sceneManager')
gameManager = require('src.gameManager')

-- Global game state
gameState = {
    currentEncounter = nil,
    selectedChef = nil,
    mapSeed = nil,
    cash = 15,  -- Starting cash: enough for 1-3 basic cards
    progress = {
        level = 1,
        score = 0,
        encounters = {}
    }
}

local Main = {
    debugConsole = nil  -- Initialize as nil
}

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
        game = require('src.scenes.game'),
        marketEncounter = require('src.scenes.marketEncounter')
    }

    -- Add scenes to manager
    for name, scene in pairs(scenes) do
        sceneManager:add(name, scene)
    end
    
    -- Initialize game manager
    gameManager:init()
    
    -- Initialize debug tools
    Main:initializeTools()
    
    -- Start with main menu
    sceneManager:switch('mainMenu')
end

function Main.update(dt)
    -- Update game manager first to handle global actions
    gameManager:update(dt)
    -- Then update current scene
    sceneManager:update(dt)
    
    -- Update debug console
    if _DEBUG and Main.debugConsole then
        Main.debugConsole:update(dt)
    end
    
    -- Reset keyboard states
    love.keyboard.keysPressed = {}
    love.keyboard.keysReleased = {}
end

function Main.draw()
    sceneManager:draw()
    if _DEBUG and Main.debugConsole then
        Main.debugConsole:draw()
    end
end

function Main.keypressed(key)
    if _DEBUG and Main.debugConsole then
        if key == '`' then
            Main.debugConsole:toggle()
            return
        end
        if Main.debugConsole.visible then
            Main.debugConsole:handleInput(key)
            return
        end
    end
    love.keyboard.keysPressed[key] = true
end

function Main.keyreleased(key)
    love.keyboard.keysReleased[key] = true
end

function Main.textinput(t)
    if _DEBUG and Main.debugConsole and Main.debugConsole.visible then
        Main.debugConsole:textInput(t)
        return
    end
    
    if sceneManager.current and sceneManager.current.inputtingSeed then
        if t:match("^[%w%s%-_%.]+$") then
            sceneManager.current.seedInput = sceneManager.current.seedInput .. t
        end
    end
end

function Main:initializeTools()
    if _DEBUG then
        self.debugConsole = require('src.tools.debugConsole')
        self.debugConsole:init()
        
        -- Initialize content manager
        self.contentManager = require('src.tools.contentManager')
        self.contentManager:init()
    end
end

-- Initialize keyboard state
love.keyboard.keysPressed = {}
love.keyboard.keysReleased = {}

function love.keyboard.wasPressed(key)
    return love.keyboard.keysPressed[key]
end

return Main


