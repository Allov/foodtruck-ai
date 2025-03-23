local function initializePrintOverride(debugConsole)
    -- Store the original print function
    _G._originalPrint = print

    -- Override the global print function
    function print(...)
        -- Convert all arguments to strings and concatenate them
        local args = {...}
        local message = ""
        for i, v in ipairs(args) do
            message = message .. tostring(v)
            if i < #args then
                message = message .. "    "
            end
        end
        
        -- Call original print for console output if needed
        if _DEBUG then
            _G._originalPrint(...)
        end
        
        -- Log to debug console if it exists
        if debugConsole then
            debugConsole:debug(message)
        end
    end
end

return initializePrintOverride
