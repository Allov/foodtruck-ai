local GameManager = {
    -- Track if we're in gameplay-related scenes
    gameplayScenes = {
        game = true,
        encounter = true,
        provinceMap = true
    }
}

function GameManager:init()
    self.sceneManager = require('src.sceneManager')
end

function GameManager:update(dt)
    -- Handle global keyboard shortcuts that should work across multiple scenes
    if self:isInGameplay() then
        -- Handle deck viewing
        if love.keyboard.wasPressed('tab') then
            self:viewDeck()
            return
        end
    end
end

function GameManager:isInGameplay()
    local currentScene = self.sceneManager.current
    if not currentScene then return false end
    
    -- Get scene name from current scene
    local currentSceneName = self:getCurrentSceneName()
    return self.gameplayScenes[currentSceneName] or false
end

function GameManager:viewDeck()
    -- Store the scene we're coming from
    gameState.previousScene = self:getCurrentSceneName()
    self.sceneManager:switch('deckViewer')
end

function GameManager:getCurrentSceneName()
    local currentScene = self.sceneManager.current
    if not currentScene then return nil end
    
    -- Find scene name by comparing scene instances
    for name, scene in pairs(self.sceneManager.scenes) do
        if scene == currentScene then
            return name
        end
    end
    return nil
end

return GameManager


