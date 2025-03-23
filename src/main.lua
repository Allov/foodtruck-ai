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
    debugConsole = nil,  -- Initialize as nil
    crtShader = nil,    -- Initialize shader reference
    canvas = nil        -- Initialize canvas reference
}

function Main:registerEncounters()
    local EncounterRegistry = require('src.encounters.encounterRegistry')
    local encounterConfigs = require('src.encounters.encounterConfigs')

    -- Register general encounter types
    EncounterRegistry:register("card_battle", 
        require('src.scenes.battleEncounter'), 
        encounterConfigs.food_critic)  -- Using food_critic as default config

    EncounterRegistry:register("market", 
        require('src.scenes.marketEncounter'), 
        encounterConfigs.farmers_market)  -- Using farmers_market as default config

    EncounterRegistry:register("negative", 
        require('src.scenes.negativeEncounter'), 
        encounterConfigs.equipment_malfunction)  -- Using equipment_malfunction as default config

    EncounterRegistry:register("beneficial", 
        require('src.scenes.beneficialEncounter'), 
        encounterConfigs.food_festival)  -- Using food_festival as default config

    EncounterRegistry:register("lore", 
        require('src.scenes.loreEncounter'), 
        {
            name = "Story Event",
            description = "A story unfolds...",
            type = "lore"
        })

    -- Register specific encounter variants (for detailed encounters)
    EncounterRegistry:register("food_critic", 
        require('src.scenes.battleEncounter'), 
        encounterConfigs.food_critic)
    EncounterRegistry:register("rush_hour", 
        require('src.scenes.battleEncounter'), 
        encounterConfigs.rush_hour)
    -- ... other specific encounters
end

function Main.load()
    -- Initialize global CRT shader
    Main.crtShader = love.graphics.newShader("src/shaders/scanline.glsl")
    
    -- Create global canvas for CRT effect
    Main.canvas = love.graphics.newCanvas()
    
    -- Load settings
    local Settings = require('src.settings')
    Settings:load()  -- Add this line to load saved settings
    
    -- Load all scenes
    local scenes = {
        mainMenu = require('src.scenes.mainMenu'),
        seedInput = require('src.scenes.seedInput'),
        chefSelect = require('src.scenes.chefSelect'),
        provinceMap = require('src.scenes.provinceMap'),
        encounter = require('src.scenes.encounter'),
        battleEncounter = require('src.scenes.battleEncounter'),
        marketEncounter = require('src.scenes.marketEncounter'),
        negativeEncounter = require('src.scenes.negativeEncounter'),
        beneficialEncounter = require('src.scenes.beneficialEncounter'),
        debugMenu = require('src.scenes.debugMenu'),
        encounterTester = require('src.scenes.encounterTester'),
        deckViewer = require('src.scenes.deckViewer'),
        game = require('src.scenes.game'),
        optionsMenu = require('src.scenes.optionsMenu')
    }

    -- Initialize scene manager with scenes
    sceneManager:init(scenes)
    
    -- Register all encounters
    Main:registerEncounters()
    
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
    local Settings = require('src.settings')
    
    if Settings.crtEnabled then
        -- Draw everything to the canvas
        love.graphics.setCanvas(Main.canvas)
        love.graphics.clear()
        
        -- Draw current scene
        sceneManager:draw()
        
        -- Draw debug console if in debug mode
        if _DEBUG and Main.debugConsole then
            Main.debugConsole:draw()
        end
        
        -- Reset canvas and apply CRT effect
        love.graphics.setCanvas()
        
        -- Update shader uniforms
        Main.crtShader:send("time", love.timer.getTime())
        Main.crtShader:send("screen_size", {love.graphics.getWidth(), love.graphics.getHeight()})
        
        -- Draw canvas with CRT shader
        love.graphics.setShader(Main.crtShader)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(Main.canvas, 0, 0)
        love.graphics.setShader()
    else
        -- Draw directly without CRT effect
        sceneManager:draw()
        
        if _DEBUG and Main.debugConsole then
            Main.debugConsole:draw()
        end
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

function love.load()
    -- Initialize global CRT shader
    Main.crtShader = love.graphics.newShader("src/shaders/scanline.glsl")
    
    -- Create global canvas for CRT effect
    Main.canvas = love.graphics.newCanvas()
    
    -- Load the game
    game.load()
end

return Main






