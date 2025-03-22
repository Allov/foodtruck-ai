local DebugConsole = {
    visible = false,
    history = {},
    input = "",
    maxHistory = 50,
    cursorBlink = 0
}

function DebugConsole:init()
    self.commands = {
        help = function() self:showHelp() end,
        give_cash = function(amount) self:giveCash(amount) end,
        show_state = function() self:showGameState() end
    }
end

function DebugConsole:toggle()
    self.visible = not self.visible
    -- Enable/disable system text input when console is toggled
    love.keyboard.setTextInput(self.visible)
end

function DebugConsole:executeCommand(cmd)
    local parts = {}
    for part in cmd:gmatch("%S+") do
        table.insert(parts, part)
    end
    
    local command = parts[1]
    table.remove(parts, 1)
    
    if self.commands[command] then
        local success, result = pcall(self.commands[command], unpack(parts))
        if not success then
            self:log("Error: " .. tostring(result))
        else
            self:log("Executed: " .. command)
        end
    else
        self:log("Unknown command: " .. command)
    end
end

function DebugConsole:log(message)
    table.insert(self.history, tostring(message))
    if #self.history > self.maxHistory then
        table.remove(self.history, 1)
    end
end

function DebugConsole:handleInput(key)
    if not self.visible then return end
    
    if key == "return" and self.input ~= "" then
        self:executeCommand(self.input)
        self.input = ""
    elseif key == "backspace" then
        self.input = string.sub(self.input, 1, -2)
    end
end

function DebugConsole:textInput(text)
    if not self.visible then return end
    self.input = self.input .. text
end

function DebugConsole:update(dt)
    if not self.visible then return end
    self.cursorBlink = (self.cursorBlink + dt) % 1
end

function DebugConsole:draw()
    if not self.visible then return end
    
    -- Draw console background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight() * 0.3)
    
    -- Draw input box background
    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    love.graphics.rectangle(
        "fill", 
        10, 
        love.graphics.getHeight() * 0.3 - 30,
        love.graphics.getWidth() - 20,
        25
    )
    
    -- Draw command history
    love.graphics.setColor(1, 1, 1, 1)
    local y = love.graphics.getHeight() * 0.3 - 40
    for i = #self.history, math.max(1, #self.history - 10), -1 do
        love.graphics.print(self.history[i], 10, y - 20)
        y = y - 20
    end
    
    -- Draw input line with blinking cursor
    love.graphics.setColor(1, 1, 0, 1)
    local cursor = self.cursorBlink < 0.5 and "|" or ""
    love.graphics.print(
        "> " .. self.input .. cursor,
        15,
        love.graphics.getHeight() * 0.3 - 25
    )
end

function DebugConsole:showHelp()
    self:log("Available commands:")
    for cmd, _ in pairs(self.commands) do
        self:log("  " .. cmd)
    end
end

function DebugConsole:giveCash(amount)
    amount = tonumber(amount)
    if not amount then
        self:log("Error: Invalid amount")
        return
    end
    gameState.cash = gameState.cash + amount
    self:log("Added " .. amount .. " cash")
end

function DebugConsole:showGameState()
    self:log("Cash: " .. tostring(gameState.cash))
    self:log("Level: " .. tostring(gameState.progress.level))
    self:log("Score: " .. tostring(gameState.progress.score))
end

return DebugConsole



