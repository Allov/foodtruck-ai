local SceneManager = {
    scenes = {},
    current = nil,
    transitioning = false
}

function SceneManager:add(name, scene)
    -- Create a new instance of the scene
    self.scenes[name] = scene.new()
    -- Initialize the scene
    self.scenes[name]:init()
end

function SceneManager:switch(name)
    if self.transitioning then return end
    if self.current then
        self.current:exit()
    end
    -- Check if the scene exists before switching
    if self.scenes[name] then
        self.current = self.scenes[name]
        print("Switching to scene:", name)
        self.current:enter()
    else
        error("Scene '" .. name .. "' not found")
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

function SceneManager:init()
    -- Add all scenes here
    self:add('market', require('src.scenes.marketEncounter'))
    -- Add other scenes...
end

return SceneManager

