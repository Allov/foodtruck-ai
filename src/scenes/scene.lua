local Scene = {}
Scene.__index = Scene

function Scene.new()
    local self = setmetatable({}, Scene)
    return self
end

function Scene:init()
    -- Base initialization if needed
end

function Scene:update(dt)
    -- Base update if needed
end

function Scene:draw()
    -- Base draw implementation
end

function Scene:initConfirmDialog()
    self.showingConfirmDialog = false
    self.confirmDialogOptions = {"Yes", "No"}
    self.confirmDialogSelected = 2  -- Default to "No"
    self.confirmDialogMessage = "Are you sure you want to exit?"
end

return Scene


