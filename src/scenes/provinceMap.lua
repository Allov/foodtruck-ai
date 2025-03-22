local Scene = require('src.scenes.scene')
local ProvinceMap = setmetatable({}, Scene)
ProvinceMap.__index = ProvinceMap

function ProvinceMap.new()
    local self = setmetatable({}, ProvinceMap)
    return self
end

function ProvinceMap:init()
    -- Define encounter types icons/symbols for visualization
    self.encounterSymbols = {
        card_battle = "🗡️",  -- Combat/Challenge
        beneficial = "💝",    -- Beneficial event
        negative = "💀",      -- Negative event
        market = "🏪",       -- Shop/Market
        lore = "📚"          -- Story/Lore
    }
    
    -- Track completed nodes
    self.completedNodes = {}
    
    -- Add status message system
    self.statusMessage = nil
    self.statusTimer = 0
    self.STATUS_DURATION = 2 -- seconds
    
    -- Add animation properties
    self.nodeScale = {}
    self.PULSE_SPEED = 2
    self.BASE_NODE_SIZE = 20
    
    self:generateMap()
end

function ProvinceMap:generateMap()
    -- Create a 4-level tree structure
    self.nodes = {}
end

function ProvinceMap:showStatus(message)
    self.statusMessage = message
    self.statusTimer = self.STATUS_DURATION
end

function ProvinceMap:update(dt)
    if love.keyboard.wasPressed('left') then
    self.nodes[1] = {
        {x = 400, y = 500, type = "start", connections = {1, 2}}  -- Connect to indices 1 and 2 of level 2
    }
    
    -- Second level
    self.nodes[2] = {
    end
    
    if love.keyboard.wasPressed('right') then
    
    -- Third level
    self.nodes[3] = {
        {x = 200, y = 300, type = self:randomEncounterType(), connections = {1}},    -- Connect to index 1 of level 4
        {x = 400, y = 300, type = self:randomEncounterType(), connections = {1, 2}}, -- Connect to indices 1 and 2 of level 4
        {x = 600, y = 300, type = self:randomEncounterType(), connections = {2}}     -- Connect to index 2 of level 4
    end
    
    if love.keyboard.wasPressed('return') then
        local selectedNode = self.nodes[self.currentLevel][self.selected]
        {x = 300, y = 200, type = "card_battle", connections = {}},
            gameState.currentEncounter = selectedNode.type
            gameState.currentNodeLevel = self.currentLevel
            gameState.currentNodeIndex = self.selected
            sceneManager:switch('encounter')
        end
    end
    
    -- Update node animations
    for level, nodes in ipairs(self.nodes) do
        for i, _ in ipairs(nodes) do
            local nodeKey = level .. "," .. i
            self.nodeScale[nodeKey] = self.nodeScale[nodeKey] or 1
            
            if level == self.currentLevel and i == self.selected then
                -- Pulse selected node
                self.nodeScale[nodeKey] = 1 + math.sin(love.timer.getTime() * self.PULSE_SPEED) * 0.2
            else
                -- Reset scale of unselected nodes
                self.nodeScale[nodeKey] = 1
            end
        end
    end
    
    -- Update status message
    if self.statusTimer > 0 then
        self.statusTimer = self.statusTimer - dt
        if self.statusTimer <= 0 then
            self.statusMessage = nil
        end
    end
end

function ProvinceMap:draw()
    -- Existing draw code...
    
    -- Draw status message
    if self.statusMessage then
        love.graphics.setColor(1, 1, 1, math.min(self.statusTimer, 1))
        love.graphics.printf(
            self.statusMessage,
            0,
            love.graphics.getHeight() - 50,
            love.graphics.getWidth(),
            'center'
        )
    end
end


