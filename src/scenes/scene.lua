local Scene = {}
Scene.__index = Scene

function Scene.new()
    local self = setmetatable({}, Scene)
    return self
end

function Scene:init() end
function Scene:enter() end
function Scene:exit() end
function Scene:update(dt) end
function Scene:draw() end
function Scene:destroy() end

return Scene
