local Scene = require('src.scenes.scene')
local ProvinceMap = {}
ProvinceMap.__index = ProvinceMap
setmetatable(ProvinceMap, Scene)

local EncounterRegistry = require('src.encounters.encounterRegistry')

function ProvinceMap.new()
    local self = Scene.new()  -- Create a new Scene instance as base
    setmetatable(self, ProvinceMap)
    
    -- Create a random generator with current time as seed
    self.randomGenerator = love.math.newRandomGenerator(os.time())
    
    -- Initialize all required properties
    self.encounterSymbols = {
        card_battle = "!",    -- Combat/Challenge
        beneficial = "+",     -- Beneficial event
        negative = "-",      -- Negative event
        market = "$",        -- Shop/Market
        lore = "?"          -- Story/Lore
    }
    
    self.encounterColors = {
        card_battle = {1, 0, 0, 1},      -- Red for battles
        beneficial = {0, 1, 0, 1},        -- Green for beneficial
        negative = {1, 0.5, 0, 1},        -- Orange for negative
        market = {0, 0.7, 1, 1},          -- Blue for market
        lore = {0.8, 0.3, 1, 1}          -- Purple for lore
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
    
    -- Initialize current level and selection
    self.currentLevel = 1
    self.selected = 1
    
    -- Store the original random state
    self.originalRandomState = love.math.getRandomState()
    
    self:init()  -- Call init right after creation
    return self
end

function ProvinceMap:init()
    -- Call parent init
    Scene.init(self)
    
    -- Initialize confirmation dialog
    self:initConfirmDialog()
    
    -- Generate the initial map
    self:generateMap()
end

function ProvinceMap:setSeed(seed)
    seed = seed or os.time()
    self.randomGenerator:setSeed(seed)
    self:generateMap()
end

function ProvinceMap:generateMap()
    -- Store current random state
    local oldState = love.math.getRandomState()
    
    -- Use our seeded random generator
    love.math.setRandomState(self.randomGenerator:getState())
    
    -- Create a 4-level tree structure
    self.nodes = {}
    
    -- First level (start) - Always a market
    local startY = 500
    self.nodes[1] = {
        {x = love.graphics.getWidth() / 2, y = startY, type = "market", connections = {}}
    }
    
    -- Second level (2-3 nodes)
    local level2Count = love.math.random(2, 3)
    local level2Y = 400
    self.nodes[2] = {}
    
    -- Calculate section width for even distribution
    local sectionWidth = love.graphics.getWidth() / (level2Count + 1)
    
    for i = 1, level2Count do
        local x = (i * sectionWidth) + love.math.random(-30, 30)
        x = math.max(100, math.min(love.graphics.getWidth() - 100, x))
        
        table.insert(self.nodes[2], {
            x = x,
            y = level2Y,
            type = self:randomEncounterType(),
            connections = {}
        })
    end
    
    -- Third level (3-4 nodes)
    local level3Count = love.math.random(3, 4)
    local level3Y = 300
    self.nodes[3] = {}
    
    sectionWidth = love.graphics.getWidth() / (level3Count + 1)
    
    for i = 1, level3Count do
        local x = (i * sectionWidth) + love.math.random(-30, 30)
        x = math.max(100, math.min(love.graphics.getWidth() - 100, x))
        
        table.insert(self.nodes[3], {
            x = x,
            y = level3Y,
            type = self:randomEncounterType(),
            connections = {}
        })
    end
    
    -- Fourth level (2 boss nodes)
    local level4Y = 200
    self.nodes[4] = {
        {x = love.graphics.getWidth() / 3, y = level4Y, type = "card_battle", connections = {}},
        {x = (love.graphics.getWidth() / 3) * 2, y = level4Y, type = "card_battle", connections = {}}
    }
    
    -- Connect nodes without crossing lines
    self:connectNodesWithoutCrossing()
    
    -- Restore the original random state
    love.math.setRandomState(oldState)
end

function ProvinceMap:connectNodesWithoutCrossing()
    -- Level 1 to 2: Connect start node to closest nodes
    local startNode = self.nodes[1][1]
    table.sort(self.nodes[2], function(a, b)
        return math.abs(a.x - startNode.x) < math.abs(b.x - startNode.x)
    end)
    
    startNode.connections = {1}
    if #self.nodes[2] > 1 then
        table.insert(startNode.connections, 2)
    end
    
    -- Level 2 to 3: Connect to nearest nodes without crossing
    for i, node in ipairs(self.nodes[2]) do
        node.connections = {}
        -- Find closest nodes in next level
        local possibleConnections = {}
        for j, nextNode in ipairs(self.nodes[3]) do
            table.insert(possibleConnections, {
                index = j,
                distance = math.abs(node.x - nextNode.x)
            })
        end
        
        -- Sort by distance
        table.sort(possibleConnections, function(a, b)
            return a.distance < b.distance
        end)
        
        -- Connect to closest 1-2 nodes
        table.insert(node.connections, possibleConnections[1].index)
        if love.math.random() > 0.5 and #possibleConnections > 1 then
            table.insert(node.connections, possibleConnections[2].index)
        end
    end
    
    -- Level 3 to 4: Connect to boss nodes
    for i, node in ipairs(self.nodes[3]) do
        node.connections = {}
        -- Connect to closest boss
        if node.x < love.graphics.getWidth() / 2 then
            table.insert(node.connections, 1)
        else
            table.insert(node.connections, 2)
        end
        
        -- 30% chance to connect to both bosses
        if love.math.random() > 0.7 then
            table.insert(node.connections, node.connections[1] == 1 and 2 or 1)
        end
    end
end

function ProvinceMap:randomEncounterType()
    local types = {"card_battle", "beneficial", "negative", "market", "lore"}
    return types[love.math.random(#types)]
end

function ProvinceMap:canSelectNode(level, index)
    -- Can't select completed nodes
    if self.completedNodes[level .. "," .. index] then
        return false
    end
    
    -- Can only select nodes in current level
    if level ~= self.currentLevel then
        return false
    end
    
    -- Check if there's a valid path to this node
    if level > 1 then
        local hasValidPath = false
        for prevLevelIdx, node in ipairs(self.nodes[level - 1]) do
            if self.completedNodes[(level-1) .. "," .. prevLevelIdx] then
                for _, conn in ipairs(node.connections) do
                    if conn == index then
                        hasValidPath = true
                        break
                    end
                end
            end
        end
        return hasValidPath
    end
    
    return true
end

function ProvinceMap:handleNodeSelection(selectedNode)
    if not self:canSelectNode(self.currentLevel, self.selected) then
        return
    end

    -- Store current state
    gameState.currentEncounter = selectedNode.type
    gameState.currentNodeLevel = self.currentLevel
    gameState.currentNodeIndex = self.selected
    gameState.previousScene = 'provinceMap'

    -- Get the appropriate scene for this encounter
    local EncounterRegistry = require('src.encounters.encounterRegistry')
    local SceneClass = EncounterRegistry:getSceneClass(selectedNode.type)
    
    -- Debug print to help identify issues
    print("Selected node type:", selectedNode.type)
    print("Scene class:", SceneClass and SceneClass.__name or "nil")

    if SceneClass then
        local sceneName = SceneClass.__name or selectedNode.type
        print("Switching to scene:", sceneName)
        sceneManager:switch(sceneName)
    else
        print("Warning: No scene class found for encounter type:", selectedNode.type)
        -- Fallback to generic encounter scene
        sceneManager:switch('encounter')
    end
end

function ProvinceMap:update(dt)
    -- Handle confirmation dialog first
    if self.showingConfirmDialog then
        self:updateConfirmDialog()
        return
    end

    -- Check for escape key
    if love.keyboard.wasPressed('escape') then
        self.showingConfirmDialog = true
        return
    end

    -- Check if keyboard input exists
    if not love.keyboard.wasPressed then
        love.keyboard.wasPressed = function(key)
            return love.keyboard.isDown(key)
        end
    end

    if love.keyboard.wasPressed('left') then
        repeat
            self.selected = self.selected - 1
            if self.selected < 1 then 
                self.selected = #self.nodes[self.currentLevel] 
            end
        until self:canSelectNode(self.currentLevel, self.selected)
    end
    
    if love.keyboard.wasPressed('right') then
        repeat
            self.selected = self.selected + 1
            if self.selected > #self.nodes[self.currentLevel] then 
                self.selected = 1 
            end
        until self:canSelectNode(self.currentLevel, self.selected)
    end
    
    if love.keyboard.wasPressed('return') then
        local selectedNode = self.nodes[self.currentLevel][self.selected]
        self:handleNodeSelection(selectedNode)
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
    -- Draw connections first
    for level, nodes in ipairs(self.nodes) do
        for i, node in ipairs(nodes) do
            for _, conn in ipairs(node.connections) do
                if self.nodes[level + 1] and self.nodes[level + 1][conn] then
                    local nextNode = self.nodes[level + 1][conn]
                    love.graphics.setColor(self.encounterColors[node.type])
                    love.graphics.setLineWidth(2)
                    love.graphics.line(node.x, node.y, nextNode.x, nextNode.y)
                end
            end
        end
    end
    
    -- Draw nodes
    for level, nodes in ipairs(self.nodes) do
        for i, node in ipairs(nodes) do
            local nodeKey = level .. "," .. i
            local scale = self.nodeScale[nodeKey] or 1
            
            -- Draw node background
            love.graphics.setColor(self.encounterColors[node.type])
            
            -- Draw completed nodes differently
            if self.completedNodes[nodeKey] then
                love.graphics.setColor(0.5, 0.5, 0.5, 1)  -- Gray out completed nodes
            end
            
            -- Fill all nodes except the selected one
            if not (level == self.currentLevel and i == self.selected) then
                love.graphics.circle('fill', node.x, node.y, self.BASE_NODE_SIZE * scale)
            end
            
            -- Draw node border
            if level == self.currentLevel and i == self.selected then
                love.graphics.setColor(1, 1, 1, 1)  -- White for selected node
                love.graphics.setLineWidth(4)  -- Thicker line for selected node
            else
                love.graphics.setLineWidth(1)  -- Normal line for other nodes
            end
            love.graphics.circle('line', node.x, node.y, self.BASE_NODE_SIZE * scale)
            
            -- Draw encounter symbol
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf(
                self.encounterSymbols[node.type] or "?",
                node.x - 20,
                node.y - 10,
                40,
                'center'
            )
            
            -- Draw event name under the node
            local eventName = self:getEventTypeName(node.type)
            love.graphics.printf(
                eventName,
                node.x - 50,  -- wider area for text
                node.y + self.BASE_NODE_SIZE + 5,  -- position below node
                100,  -- width of text area
                'center'
            )
        end
    end
    
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

    -- Draw confirmation dialog if active
    if self.showingConfirmDialog then
        self:drawConfirmDialog()
    end
end

function ProvinceMap:markNodeCompleted(level, index)
    self.completedNodes[level .. "," .. index] = true
    -- Move to next level
    self.currentLevel = level + 1
    self.selected = 1
    -- Show status message
    self:showStatus("Node completed!")
end

function ProvinceMap:showStatus(message)
    self.statusMessage = message
    self.statusTimer = self.STATUS_DURATION
end

-- Add method to get current seed
function ProvinceMap:getSeed()
    return self.randomGenerator:getSeed()
end

-- Add this helper function to get friendly names for event types
function ProvinceMap:getEventTypeName(type)
    local names = {
        card_battle = "Battle",
        beneficial = "Benefit",
        negative = "Challenge",
        market = "Market",
        lore = "Story"
    }
    return names[type] or "Unknown"
end

return ProvinceMap




















