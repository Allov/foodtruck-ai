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
    
    -- Load encounter icons with error handling
    self.encounterIcons = {}
    local iconPaths = {
        card_battle = "assets/icons/competition.png",
        beneficial = "assets/icons/festival.png",
        negative = "assets/icons/warning.png",
        market = "assets/icons/market.png",
        lore = "assets/icons/story.png"
    }

    -- Try to load each icon, use fallback if file doesn't exist
    for type, path in pairs(iconPaths) do
        local success, result = pcall(function()
            return love.graphics.newImage(path)
        end)
        if not success then
            print("Warning: Could not load icon: " .. path)
            -- Create a fallback colored rectangle
            local canvas = love.graphics.newCanvas(32, 32)
            love.graphics.setCanvas(canvas)
            love.graphics.clear()
            -- Draw a simple shape as fallback
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.rectangle('fill', 8, 8, 16, 16)
            love.graphics.setCanvas()
            self.encounterIcons[type] = canvas
        else
            self.encounterIcons[type] = result
        end
    end
    
    -- Store icon dimensions for centering
    self.ICON_SIZE = 32  -- Assuming icons are 32x32 pixels
    
    self.encounterNames = {
        card_battle = "Food Competition",
        beneficial = "Food Festival",
        negative = "Road Trouble",
        market = "Local Market",
        lore = "Local Story"
    }
    
    self.encounterColors = {
        card_battle = {1, 0.4, 0, 1},      -- Orange for food competitions
        beneficial = {0.3, 0.8, 0.3, 1},    -- Green for festivals
        negative = {0.8, 0.2, 0.2, 1},      -- Red for troubles
        market = {0.2, 0.6, 1, 1},          -- Blue for markets
        lore = {0.8, 0.6, 1, 1}            -- Purple for stories
    }
    
    -- Road style - more subtle
    self.ROAD_WIDTH = 3  -- Reduced from 6
    self.ROAD_COLOR = {0.85, 0.85, 0.85, 0.5}  -- Added transparency
    self.ROAD_DASH = 8  -- Reduced from 10
    self.roadOffset = 0
    
    -- Node styling - smaller and sharper
    self.BASE_NODE_SIZE = 16  -- Reduced from 25
    self.NODE_PADDING = 6  -- Reduced from 10
    self.PULSE_SPEED = 2
    
    -- Track completed nodes
    self.completedNodes = {}
    self.nodeScale = {}
    
    -- Add status message system
    self.statusMessage = nil
    self.statusTimer = 0
    self.STATUS_DURATION = 2
    
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
    
    -- Ensure at least one battle in level 2
    local battlePlaced = false
    local battlePosition = love.math.random(1, level2Count)
    
    for i = 1, level2Count do
        local x = (i * sectionWidth) + love.math.random(-30, 30)
        x = math.max(100, math.min(love.graphics.getWidth() - 100, x))
        
        -- If this is our chosen battle position, or we haven't placed a battle yet and this is the last position
        local encounterType
        if i == battlePosition then
            encounterType = "card_battle"
            battlePlaced = true
        else
            encounterType = self:randomEncounterType(true) -- true means exclude card_battle
        end
        
        table.insert(self.nodes[2], {
            x = x,
            y = level2Y,
            type = encounterType,
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

function ProvinceMap:randomEncounterType(excludeBattle)
    local types
    if excludeBattle then
        types = {"beneficial", "negative", "market", "lore"}
    else
        types = {"card_battle", "beneficial", "negative", "market", "lore"}
    end
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

    -- Set market type if it's a market node
    if selectedNode.type == "market" then
        -- Randomly select a market type
        local marketTypes = {"farmers_market", "specialty_shop", "supply_store"}
        gameState.currentMarketType = marketTypes[love.math.random(#marketTypes)]
    end

    -- Get the appropriate scene for this encounter
    local EncounterRegistry = require('src.encounters.encounterRegistry')
    local SceneClass = EncounterRegistry:getSceneClass(selectedNode.type)
    
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
    -- Animate road dashes
    self.roadOffset = (self.roadOffset + dt * 0.2) % 1
    
    -- Handle node selection
    if love.keyboard.wasPressed('left') then
        local newSelected = self.selected - 1
        if newSelected < 1 then 
            newSelected = #self.nodes[self.currentLevel]
        end
        -- Only select if node is valid
        if self:canSelectNode(self.currentLevel, newSelected) then
            self.selected = newSelected
        end
    end
    
    if love.keyboard.wasPressed('right') then
        local newSelected = self.selected + 1
        if newSelected > #self.nodes[self.currentLevel] then
            newSelected = 1
        end
        -- Only select if node is valid
        if self:canSelectNode(self.currentLevel, newSelected) then
            self.selected = newSelected
        end
    end
    
    -- Handle node confirmation
    if love.keyboard.wasPressed('return') or love.keyboard.wasPressed('space') then
        local selectedNode = self.nodes[self.currentLevel][self.selected]
        if selectedNode and self:canSelectNode(self.currentLevel, self.selected) then
            self:handleNodeSelection(selectedNode)
        end
    end
    
    -- Update node animations
    for level, nodes in ipairs(self.nodes) do
        for i, _ in ipairs(nodes) do
            local nodeKey = level .. "," .. i
            if level == self.currentLevel and i == self.selected then
                self.nodeScale[nodeKey] = 1 + math.sin(love.timer.getTime() * self.PULSE_SPEED) * 0.1
            else
                self.nodeScale[nodeKey] = 1
            end
        end
    end
    
    -- Update status message
    if self.statusMessage then
        self.statusTimer = math.max(0, self.statusTimer - dt)
        if self.statusTimer <= 0 then
            self.statusMessage = nil
        end
    end
end

function ProvinceMap:draw()
    -- Draw animated road connections first
    self:drawRoads()
    
    -- Draw nodes
    for level, nodes in ipairs(self.nodes) do
        for i, node in ipairs(nodes) do
            self:drawNode(level, i, node)
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

function ProvinceMap:drawRoads()
    for level, nodes in ipairs(self.nodes) do
        for i, node in ipairs(nodes) do
            for _, conn in ipairs(node.connections) do
                if self.nodes[level + 1] and self.nodes[level + 1][conn] then
                    local nextNode = self.nodes[level + 1][conn]
                    self:drawRoadConnection(node, nextNode)
                end
            end
        end
    end
end

function ProvinceMap:drawRoadConnection(startNode, endNode)
    -- Draw main road - more subtle
    love.graphics.setColor(self.ROAD_COLOR)
    love.graphics.setLineWidth(self.ROAD_WIDTH)
    love.graphics.line(startNode.x, startNode.y, endNode.x, endNode.y)
    
    -- Draw animated dashed line - more subtle
    love.graphics.setColor(1, 1, 1, 0.3)  -- Reduced opacity
    love.graphics.setLineWidth(1)  -- Thinner line
    
    local dx = endNode.x - startNode.x
    local dy = endNode.y - startNode.y
    local dist = math.sqrt(dx * dx + dy * dy)
    local numDashes = math.floor(dist / (self.ROAD_DASH * 2))
    
    for i = 0, numDashes do
        local t = (i / numDashes + self.roadOffset) % 1
        local x1 = startNode.x + dx * t
        local y1 = startNode.y + dy * t
        local x2 = startNode.x + dx * math.min(t + 0.05, 1)  -- Shorter dashes
        local y2 = startNode.y + dy * math.min(t + 0.05, 1)
        love.graphics.line(x1, y1, x2, y2)
    end
end

function ProvinceMap:drawNode(level, i, node)
    local nodeKey = level .. "," .. i
    local scale = self.nodeScale[nodeKey] or 1
    local size = self.BASE_NODE_SIZE * scale
    
    -- Draw node background
    if self.completedNodes[nodeKey] then
        love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
    else
        local color = self.encounterColors[node.type]
        love.graphics.setColor(color[1], color[2], color[3], 0.9)
    end
    
    -- Draw node circle
    if level == self.currentLevel and i == self.selected then
        love.graphics.setLineWidth(2)
        love.graphics.circle('line', node.x, node.y, size + 3)
        love.graphics.setColor(1, 1, 1, 0.1)
        love.graphics.circle('fill', node.x, node.y, size)
    else
        love.graphics.circle('fill', node.x, node.y, size)
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.setLineWidth(1)
        love.graphics.circle('line', node.x, node.y, size)
    end
    
    -- Draw encounter icon
    love.graphics.setColor(1, 1, 1, 1)
    local icon = self.encounterIcons[node.type]
    if icon then
        local iconScale = scale * 0.75
        local iconX = node.x - (self.ICON_SIZE * iconScale) / 2
        local iconY = node.y - (self.ICON_SIZE * iconScale) / 2
        love.graphics.draw(icon, iconX, iconY, 0, iconScale, iconScale)
    end
    
    -- Draw event name with better visibility
    local eventName = self.encounterNames[node.type] or "Unknown"
    
    -- Draw text shadow/outline for better contrast
    love.graphics.setFont(love.graphics.newFont(12))  -- Slightly larger font
    love.graphics.setColor(0, 0, 0, 0.8)  -- Shadow color
    
    -- Draw text multiple times offset slightly for outline effect
    local offsets = {{-1,-1}, {-1,1}, {1,-1}, {1,1}}
    for _, offset in ipairs(offsets) do
        love.graphics.printf(
            eventName,
            node.x - 50 + offset[1],
            node.y + size + 5 + offset[2],
            100,
            'center'
        )
    end
    
    -- Draw main text
    love.graphics.setColor(1, 1, 1, 1)  -- Full opacity white
    love.graphics.printf(
        eventName,
        node.x - 50,
        node.y + size + 5,
        100,
        'center'
    )
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






















