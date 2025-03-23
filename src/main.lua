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
    -- Initialize debug tools first, before any other operations
    if _DEBUG then
        -- Initialize debug console first
        Main.debugConsole = require('src.tools.debugConsole')
        Main.debugConsole:init()

        -- Initialize print override immediately after debug console
        local initializePrintOverride = require('src.tools.printOverride')
        initializePrintOverride(Main.debugConsole)

        -- Print launch arguments after logger is ready
        Main.debugConsole:info("Launch Arguments:")
        for i, v in ipairs(arg) do
            Main.debugConsole:info(string.format("arg[%d]: %s", i, tostring(v)))
        end
        Main.debugConsole:info("Total arguments: " .. #arg)
        Main.debugConsole:info("------------------------")
    end

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

    -- Initialize global CRT shader
    Main.crtShader = love.graphics.newShader("src/shaders/scanline.glsl")

    -- Create global canvas for CRT effect
    Main.canvas = love.graphics.newCanvas()

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
        -- Draw everything except global overlays to the canvas
        love.graphics.setCanvas(Main.canvas)
        love.graphics.clear()

        -- Draw current scene
        sceneManager:draw()

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

        -- Draw global overlays after post-processing
        Main:drawGlobalOverlays()

        -- Draw debug console last
        if _DEBUG and Main.debugConsole then
            Main.debugConsole:draw()
        end
    else
        -- Draw directly without CRT effect
        sceneManager:draw()
        Main:drawGlobalOverlays()

        if _DEBUG and Main.debugConsole then
            Main.debugConsole:draw()
        end
    end
end

function Main:drawGlobalOverlays()
    -- Draw prototype info
    local stats = {
        _DEBUG and "Debug Mode: Enabled" or "Debug Mode: Disabled",
        string.format("Memory: %.1f MB", collectgarbage("count") / 1024),
        string.format("FPS: %d", love.timer.getFPS()),
        string.format("Resolution: %dx%d", love.graphics.getWidth(), love.graphics.getHeight()),
        string.format("Version: %s (LÖVE %s)", "0.1.0-prototype", love.getVersion())
    }

    -- Save current graphics state
    local prevFont = love.graphics.getFont()
    local r, g, b, a = love.graphics.getColor()

    -- Draw stats
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.setColor(0.6, 0.6, 0.6, 0.8)

    local bottomMargin = 80
    for i, stat in ipairs(stats) do
        love.graphics.printf(
            stat,
            10,
            love.graphics.getHeight() - bottomMargin + ((#stats - i) * 15),
            love.graphics.getWidth() - 20,
            'left'
        )
    end

    -- Restore graphics state
    love.graphics.setFont(prevFont)
    love.graphics.setColor(r, g, b, a)
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
        -- Initialize debug console first
        self.debugConsole = require('src.tools.debugConsole')
        self.debugConsole:init()

        -- Initialize print override
        local initializePrintOverride = require('src.tools.printOverride')
        initializePrintOverride(self.debugConsole)

        -- Initialize content manager
        self.contentManager = require('src.tools.contentManager')
        self.contentManager:init()

        -- Get project stats
        local stats = self.contentManager:getProjectStats()

        -- Add startup logs
        self.debugConsole:info("===============================")
        self.debugConsole:info("=== Food Truck Journey ===")
        self.debugConsole:info("Version: " .. love.getVersion())
        self.debugConsole:info("Game Resolution: " .. love.graphics.getWidth() .. "x" .. love.graphics.getHeight())
        self.debugConsole:info("OS: " .. love.system.getOS())
        self.debugConsole:info("GPU: " .. love.graphics.getRendererInfo())
        self.debugConsole:info("Memory: " .. string.format("%.2f MB", collectgarbage("count") / 1024))
        self.debugConsole:info("===============================")
        self.debugConsole:info("Project Statistics:")
        self.debugConsole:info("Total Files: " .. stats.files)
        self.debugConsole:info("Lua Files: " .. stats.luaFiles)
        self.debugConsole:info("Lines of Code: " .. stats.lines)
        self.debugConsole:info("Asset Size: " .. stats.assetSizeMB .. " MB")
        self.debugConsole:info("Image Files: " .. stats.imageFiles)
        self.debugConsole:info("Audio Files: " .. stats.audioFiles)
        self.debugConsole:info("===============================")
        self.debugConsole:info("Debug tools initialized")
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

function Main.wheelmoved(x, y)
    if _DEBUG and Main.debugConsole and Main.debugConsole.visible then
        Main.debugConsole:wheelmoved(x, y)
        return
    end
end

return Main







