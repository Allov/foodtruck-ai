-- Enable debugging
if arg[#arg] == "vsc_debug" then
    local lldebugger = require "lldebugger"
    lldebugger.start()
    local run = love.run
    function love.run(...)
        local f = lldebugger.call(run, false, ...)
        return function(...) return lldebugger.call(f, false, ...) end
    end
end

if arg[#arg] == "test" then
    -- Run all tests
    local testRunner = require('tests.all')
    local success = testRunner:runAll()
    love.event.quit(success and 0 or 1)
    return
end


local game = require('src.main')

function love.load()
    game.load()
end

function love.update(dt)
    game.update(dt)
end

function love.draw()
    game.draw()
end

function love.keypressed(key)
    game.keypressed(key)
end

function love.keyreleased(key)
    game.keyreleased(key)
end

function love.textinput(t)
    game.textinput(t)
end

function love.wheelmoved(x, y)
    game.wheelmoved(x, y)
end

-- Add quit callback
function love.quit()
    if game.debugConsole then
        game.debugConsole:cleanup()
    end
end



