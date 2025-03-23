local Settings = require('src.settings')

local DebugConsole = {
    visible = false,
    history = {},
    input = "",
    maxHistory = 50,
    cursorBlink = 0,
    scrollOffset = 0,
    maxVisibleLines = 20,
    isFullscreen = false,  -- New: tracks if console is fullscreen
    LOG_LEVELS = {
        DEBUG = {name = "DEBUG", color = {0.5, 0.5, 0.5, 1}},
        INFO = {name = "INFO", color = {0.8, 0.8, 1, 1}},      -- Softer blue-white
        WARN = {name = "WARN", color = {1, 0.9, 0.4, 1}},      -- Softer yellow
        ERROR = {name = "ERROR", color = {1, 0.4, 0.4, 1}},    -- Softer red
        SUCCESS = {name = "SUCCESS", color = {0.4, 1, 0.4, 1}} -- Softer green
    },
    lastMessage = "",
    lastMessageTime = 0,
    messageCount = 1,
    debounceTime = 0.1,
    LAYOUT = {
        PADDING = function()
            local scale = Settings.getScale()
            return 15 * scale.x
        end,
        MESSAGE_HEIGHT = function()
            local scale = Settings.getScale()
            return 24 * scale.y
        end,
        INPUT_HEIGHT = 30,      -- Input box height
        TIMESTAMP_WIDTH = 90,   -- Width for timestamp column
        LEVEL_WIDTH = 80,       -- Width for log level column
        TOP_MARGIN = 40,        -- Space for keybinds at top
        BOTTOM_MARGIN = 45,     -- Space at bottom
        SCROLLBAR_WIDTH = 8,    -- Width of scrollbar
        ROUNDED_CORNERS = 6     -- Increased rounded corners
    },
    STYLES = {
        BACKGROUND = {0.1, 0.1, 0.15, 0.95},    -- Slightly blue-tinted dark background
        INPUT_BG = {0.15, 0.15, 0.2, 1},        -- Slightly lighter input background
        INPUT_TEXT = {1, 0.95, 0.7, 1},         -- Warm white for input
        PROMPT = {0.4, 0.8, 1, 1},              -- Bright blue prompt
        SEPARATOR = {1, 1, 1, 0.1},             -- Subtle separator line
        SCROLLBAR = {1, 1, 1, 0.2},             -- Subtle scrollbar
        HELP_TEXT = {1, 1, 1, 0.4},              -- More visible help text
        TIMESTAMP = {0.6, 0.6, 0.7, 0.8}        -- New softer color for timestamps
    },
    scroll = {
        current = 0,
        target = 0,
        velocity = 0,
        -- Constants for smooth scrolling
        SPRING_STIFFNESS = 180.0,  -- How quickly it reaches the target
        SPRING_DAMPING = 12.0,     -- How quickly it stops oscillating
        SCROLL_SPEED = 5,          -- Lines per scroll
    }
}

function DebugConsole:init()
    self.commands = {
        help = function() self:showHelp() end,
        clear = function() self.history = {} end,  -- Added clear command
        give_cash = function(amount) self:giveCash(amount) end,
        show_state = function() self:showGameState() end
    }
    self:updateMaxVisibleLines()
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

function DebugConsole:formatTimestamp()
    return os.date("%H:%M:%S")
end

function DebugConsole:log(message, level)
    level = level or self.LOG_LEVELS.INFO
    local currentTime = love.timer.getTime()
    
    -- Check if this is a duplicate message within the debounce time
    if message == self.lastMessage and 
       (currentTime - self.lastMessageTime) < self.debounceTime then
        -- Update the last message to include the count
        self.messageCount = self.messageCount + 1
        self.history[#self.history].message = string.format("%s (x%d)", 
            message, self.messageCount)
        return
    end
    
    -- New message or outside debounce time
    local entry = {
        timestamp = self:formatTimestamp(),
        message = tostring(message),
        level = level
    }
    
    table.insert(self.history, entry)
    if #self.history > self.maxHistory then
        table.remove(self.history, 1)
    end
    
    -- Reset debounce tracking
    self.lastMessage = message
    self.lastMessageTime = currentTime
    self.messageCount = 1
end

-- Convenience methods for different log levels
function DebugConsole:debug(message)
    self:log(message, self.LOG_LEVELS.DEBUG)
end

function DebugConsole:info(message)
    self:log(message, self.LOG_LEVELS.INFO)
end

function DebugConsole:warn(message)
    self:log(message, self.LOG_LEVELS.WARN)
end

function DebugConsole:error(message)
    self:log(message, self.LOG_LEVELS.ERROR)
end

function DebugConsole:success(message)
    self:log(message, self.LOG_LEVELS.SUCCESS)
end

function DebugConsole:handleInput(key)
    if not self.visible then return end
    
    if key == "return" and self.input ~= "" then
        self:executeCommand(self.input)
        self.input = ""
        -- Update scroll target instead of immediate scroll
        self.scroll.target = 0
    elseif key == "backspace" then
        self.input = string.sub(self.input, 1, -2)
    elseif key == "pageup" then
        -- Update scroll target smoothly
        self.scroll.target = math.min(
            self.scroll.target + self.scroll.SCROLL_SPEED,
            #self.history - self.maxVisibleLines
        )
    elseif key == "pagedown" then
        -- Update scroll target smoothly
        self.scroll.target = math.max(
            self.scroll.target - self.scroll.SCROLL_SPEED,
            0
        )
    elseif key == "f11" then  -- New: toggle fullscreen with F11
        self.isFullscreen = not self.isFullscreen
        -- Adjust maxVisibleLines based on screen size
        self:updateMaxVisibleLines()
    end
end

function DebugConsole:textInput(text)
    if not self.visible then return end
    self.input = self.input .. text
end

function DebugConsole:updateScroll(dt)
    -- Spring physics for smooth scrolling
    local displacement = self.scroll.target - self.scroll.current
    local spring = displacement * self.scroll.SPRING_STIFFNESS
    local damping = self.scroll.velocity * self.scroll.SPRING_DAMPING
    local force = spring - damping
    
    self.scroll.velocity = self.scroll.velocity + force * dt
    self.scroll.current = self.scroll.current + self.scroll.velocity * dt
    
    -- Update actual scroll offset (rounded for display)
    self.scrollOffset = math.floor(self.scroll.current + 0.5)
    
    -- Stop tiny oscillations
    if math.abs(self.scroll.velocity) < 0.01 and math.abs(displacement) < 0.01 then
        self.scroll.velocity = 0
        self.scroll.current = self.scroll.target
        self.scrollOffset = math.floor(self.scroll.current)
    end
end

function DebugConsole:update(dt)
    if not self.visible then return end
    
    -- Update cursor blink
    self.cursorBlink = (self.cursorBlink + dt) % 1
    
    -- Update scroll animation
    self:updateScroll(dt)
end

-- Separate wheel movement handler
function DebugConsole:wheelmoved(x, y)
    if not self.visible then return end
    
    -- Update scroll target based on wheel movement
    self.scroll.target = math.max(0, math.min(
        self.scroll.target - y * self.scroll.SCROLL_SPEED,
        #self.history - self.maxVisibleLines
    ))
end

function DebugConsole:drawKeybindHelp()
    local width = love.graphics.getWidth()
    local padding = self.LAYOUT.PADDING()  -- Call the function to get the value
    local helpText = {
        "F11: Toggle fullscreen",
        "PgUp/PgDn: Scroll",
        "`: Toggle console",
        "Enter: Execute command",
    }
    
    love.graphics.setColor(self.STYLES.HELP_TEXT)
    for i, text in ipairs(helpText) do
        love.graphics.printf(
            text,
            0,
            padding + (i-1) * 20,
            width - padding,
            'right'
        )
    end
end

function DebugConsole:draw()
    if not self.visible then return end
    
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local scale = Settings.getScale()
    
    -- Get actual values from layout functions
    local padding = self.LAYOUT.PADDING()
    local messageHeight = self.LAYOUT.MESSAGE_HEIGHT()
    
    local consoleHeight = self.isFullscreen and height or (height * 0.3)
    
    -- Draw main background
    love.graphics.setColor(self.STYLES.BACKGROUND)
    love.graphics.rectangle("fill", 0, 0, width, consoleHeight)
    
    -- Draw separator line
    love.graphics.setColor(self.STYLES.SEPARATOR)
    love.graphics.rectangle(
        "fill", 
        padding, 
        consoleHeight - self.LAYOUT.BOTTOM_MARGIN,
        width - (padding * 2),
        1
    )
    
    -- Draw keybind help
    self:drawKeybindHelp()
    
    -- Draw input box background with rounded corners
    love.graphics.setColor(self.STYLES.INPUT_BG)
    love.graphics.rectangle(
        "fill", 
        padding, 
        consoleHeight - self.LAYOUT.BOTTOM_MARGIN + 5,
        width - (padding * 2),
        self.LAYOUT.INPUT_HEIGHT,
        self.LAYOUT.ROUNDED_CORNERS
    )
    
    -- Draw command history with scrolling
    local y = consoleHeight - self.LAYOUT.BOTTOM_MARGIN - messageHeight
    local startIndex = #self.history - self.scrollOffset
    local endIndex = math.max(1, startIndex - self.maxVisibleLines + 1)
    
    -- Draw scrollbar if needed
    if #self.history > self.maxVisibleLines then
        local scrollbarHeight = consoleHeight - self.LAYOUT.TOP_MARGIN - self.LAYOUT.BOTTOM_MARGIN
        local thumbHeight = (self.maxVisibleLines / #self.history) * scrollbarHeight
        local scrollProgress = 1 - (self.scrollOffset / (#self.history - self.maxVisibleLines))
        local thumbPosition = scrollProgress * (scrollbarHeight - thumbHeight)
        
        -- Scrollbar background
        love.graphics.setColor(self.STYLES.SCROLLBAR[1], self.STYLES.SCROLLBAR[2], 
                             self.STYLES.SCROLLBAR[3], self.STYLES.SCROLLBAR[4] * 0.5)
        love.graphics.rectangle(
            "fill", 
            width - padding - self.LAYOUT.SCROLLBAR_WIDTH,
            self.LAYOUT.TOP_MARGIN,
            self.LAYOUT.SCROLLBAR_WIDTH,
            scrollbarHeight
        )
        
        -- Scrollbar thumb
        love.graphics.setColor(self.STYLES.SCROLLBAR)
        love.graphics.rectangle(
            "fill",
            width - padding - self.LAYOUT.SCROLLBAR_WIDTH,
            self.LAYOUT.TOP_MARGIN + thumbPosition,
            self.LAYOUT.SCROLLBAR_WIDTH,
            thumbHeight
        )
    end
    
    -- Draw messages with proper column alignment
    for i = startIndex, endIndex, -1 do
        local entry = self.history[i]
        if entry then
            local x = padding
            
            -- Draw timestamp
            love.graphics.setColor(self.STYLES.TIMESTAMP)
            love.graphics.print("[" .. entry.timestamp .. "]", x, y)
            x = x + self.LAYOUT.TIMESTAMP_WIDTH
            
            -- Draw level indicator
            love.graphics.setColor(entry.level.color)
            love.graphics.print("[" .. entry.level.name .. "]", x, y)
            x = x + self.LAYOUT.LEVEL_WIDTH
            
            -- Draw message
            love.graphics.setColor(entry.level.color[1], entry.level.color[2], 
                                 entry.level.color[3], 1)
            love.graphics.print(entry.message, x, y)
            
            y = y - messageHeight
        end
    end
    
    -- Draw input line with blinking cursor
    love.graphics.setColor(self.STYLES.PROMPT)
    love.graphics.print(
        ">",
        padding + 5,
        consoleHeight - self.LAYOUT.BOTTOM_MARGIN + 12
    )
    
    love.graphics.setColor(self.STYLES.INPUT_TEXT)
    local cursor = self.cursorBlink < 0.5 and "│" or ""
    love.graphics.print(
        self.input .. cursor,
        padding + 25,
        consoleHeight - self.LAYOUT.BOTTOM_MARGIN + 12
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

function DebugConsole:updateMaxVisibleLines()
    local height = love.graphics.getHeight()
    local consoleHeight = self.isFullscreen and height or (height * 0.3)
    local availableHeight = consoleHeight - self.LAYOUT.TOP_MARGIN - self.LAYOUT.BOTTOM_MARGIN
    -- Call the MESSAGE_HEIGHT function to get the actual value
    self.maxVisibleLines = math.floor(availableHeight / self.LAYOUT.MESSAGE_HEIGHT())
end

-- Add mouse wheel support
function DebugConsole:wheelmoved(x, y)
    if not self.visible then return end
    
    -- Update scroll target based on wheel movement
    self.scroll.target = math.max(0, math.min(
        self.scroll.target - y * self.scroll.SCROLL_SPEED,
        #self.history - self.maxVisibleLines
    ))
end

return DebugConsole























