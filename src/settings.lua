local Settings = {
    crtEnabled = true,
    filepath = "settings.dat"
}

function Settings:save()
    local data = "return " .. self:serialize(self)
    local encoded = love.data.encode("string", "base64", data)
    love.filesystem.write(self.filepath, encoded)
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
    end
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

return Settings

