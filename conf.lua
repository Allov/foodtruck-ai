-- Game configuration
GAME_TITLE = "Food Truck Journey"

function love.conf(t)
    t.title = GAME_TITLE     -- Game window title
    t.version = "11.4"       -- LÖVE version
    t.window.width = 1280    -- Window width
    t.window.height = 720    -- Window height
    
    -- For debugging
    t.console = true
end

-- Set global debug flag
_DEBUG = true

