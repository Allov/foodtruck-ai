local Settings = {
    initialized = false,
    crtEnabled = true,
    filepath = "settings.dat",
    baseResolution = {
        width = 1280,
        height = 720
    },
    debug = {
        logSaveLoad = true
    },
    debugConsole = nil  -- Add reference to debugConsole
}

function Settings:init(debugConsole)
    if self.initialized then
        return self
    end

    self.debugConsole = debugConsole

    if self.debug.logSaveLoad and self.debugConsole then
        self.debugConsole:info("[Settings] Initializing settings...")
    end

    -- Create save directory if it doesn't exist
    love.filesystem.createDirectory(love.filesystem.getSaveDirectory())

    -- Try to load existing settings
    local loaded = self:load()

    -- If load failed, save default settings
    if not loaded then
        if self.debug.logSaveLoad and self.debugConsole then
            self.debugConsole:info("[Settings] No settings found, saving defaults...")
        end
        self:save()
    end

    self.initialized = true
    return self
end

-- Add methods to the Settings table
function Settings.getScale()
    local currentWidth = love.graphics.getWidth()
    local currentHeight = love.graphics.getHeight()
    return {
        x = currentWidth / Settings.baseResolution.width,
        y = currentHeight / Settings.baseResolution.height
    }
end

function Settings.scalePosition(x, y)
    local scale = Settings.getScale()
    return x * scale.x, y * scale.y
end

function Settings.scaleDimensions(width, height)
    local scale = Settings.getScale()
    return width * scale.x, height * scale.y
end

function Settings:save()
    local data = "return " .. self:serialize(self)
    local encoded = love.data.encode("string", "base64", data)
    local success = love.filesystem.write(self.filepath, encoded)
    return success  -- Return whether the write was successful
end

function Settings:load()
    local success, content = pcall(love.filesystem.read, self.filepath)
    if success and content then
        local data = love.data.decode("string", "base64", content)
        local settings = load(data)()
        for k, v in pairs(settings) do
            if k ~= "save" and k ~= "load" and k ~= "serialize" then
                self[k] = v
            end
        end
        return true  -- Add return value for successful load
    end
    return false  -- Already returns false for failure case
end

function Settings:serialize(tbl)
    local result = "{"
    for k, v in pairs(tbl) do
        if type(k) == "string" and k ~= "filepath" and type(v) ~= "function" then
            result = result .. string.format("[%q]=", k)
            if type(v) == "table" then
                result = result .. self:serialize(v)
            elseif type(v) == "boolean" or type(v) == "number" then
                result = result .. tostring(v)
            else
                result = result .. string.format("%q", v)
            end
            result = result .. ","
        end
    end
    return result .. "}"
end

-- Return the module without initializing
return Settings



