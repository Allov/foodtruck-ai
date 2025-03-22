-- This is what we expect to see in sceneManager
local SceneManager = {
    scenes = {},
    current = nil
}

function SceneManager:init(scenes)
    -- Initialize each scene
    for name, sceneClass in pairs(scenes) do
        self.scenes[name] = sceneClass.new()
    end
end

function SceneManager:register(name, sceneClass)
    self.scenes[name] = sceneClass.new()
end

function SceneManager:switch(sceneName)
    if self.scenes[sceneName] then
        self.current = self.scenes[sceneName]
        if self.current.enter then
            self.current:enter()
        end
    end
end

function SceneManager:update(dt)
    if self.current then
        self.current:update(dt)
    end
end

function SceneManager:draw()
    if self.current then
        self.current:draw()
    end
end

-- Create a single instance
local instance = setmetatable({}, {__index = SceneManager})

return instance

