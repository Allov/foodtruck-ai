local Scene = require('src.scenes.scene')
local ProvinceMap = {}
ProvinceMap.__index = ProvinceMap
setmetatable(ProvinceMap, Scene)

local EncounterRegistry = require('src.encounters.encounterRegistry')

function ProvinceMap.new()
    local self = Scene.new()  -- Create a new Scene instance as base
    setmetatable(self, ProvinceMap)
    
    -- Create a random generator but DON'T generate map yet
    self.randomGenerator = love.math.newRandomGenerator()
    
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
        starting_market = "Starting Market",
        farmers_market = "Farmers Market",
        food_critic = "Food Critic Challenge",
        rush_hour = "Rush Hour Service",
        final_showdown = "Final Showdown",
        beneficial = "Food Festival",
        negative = "Road Trouble",
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
    
    -- Map configuration
    self.NUM_LEVELS = 15  -- Changed from 8 to match actual number of rows
    self.LEVEL_HEIGHT = 120  -- Vertical spacing between levels
    self.HORIZONTAL_PADDING = 100
    
    -- Camera/scroll properties
    self.camera = {
        x = 0,
        y = 0,
        targetY = 0,
        speed = 800,  -- Pixels per second
        padding = 100  -- Padding from top/bottom of screen
    }
    
    self:init()  -- Call init right after creation
    return self
end

function ProvinceMap:init()
    -- Call parent init
    Scene.init(self)
    
    -- Initialize confirmation dialog
    self:initConfirmDialog()
    
    -- Initialize camera peek offset
    self.peekOffset = 0
    self.PEEK_SPEED = 800 -- Pixels per second
    
    -- Generate the initial map
    self:generateMap()
end

function ProvinceMap:setSeed(seed)
    if not seed then
        print("Warning: Attempting to set nil seed")
        seed = os.time()
    end
    self.randomGenerator:setSeed(seed)
    self:generateMap()
end

function ProvinceMap:generateNodesPerRow()
    local nodesPerRow = {}
    
    -- First row: 2 nodes
    nodesPerRow[1] = 2
    
    -- Middle rows: alternate between 2 and 3 nodes
    for i = 2, self.NUM_LEVELS - 1 do
        -- Use the random generator to maintain consistency with seed
        nodesPerRow[i] = self.randomGenerator:random() < 0.6 and 3 or 2
    end
    
    -- Last row: always 1 node (final boss/encounter)
    nodesPerRow[self.NUM_LEVELS] = 1
    
    return nodesPerRow
end

function ProvinceMap:generateMap()
    -- Clear existing nodes
    self.nodes = {}
    
    -- Generate node distribution using same seed
    local nodesPerRow = self:generateNodesPerRow()
    
    -- Calculate total map height using class properties
    self.mapHeight = (self.NUM_LEVELS - 1) * self.LEVEL_HEIGHT + 200
    
    for row = 1, self.NUM_LEVELS do
        local rowNodes = {}
        
        for col = 1, nodesPerRow[row] do
            local node = {
                x = 0,  -- Will be set later
                y = self.mapHeight - ((row - 1) * self.LEVEL_HEIGHT + 100),
                completed = false,
                available = row == 1,
                connections = {},
            }
            
            -- Force battle encounters for row 2
            if row == 2 then
                node.type = "card_battle"
                node.encounterType = self.randomGenerator:random() < 0.5 and "food_critic" or "rush_hour"
            else
                -- Random encounter type for other rows
                node.type = self:getRandomEncounterType(row)
                node.encounterType = self:getSpecificEncounter(node.type)
            end
            
            table.insert(rowNodes, node)
        end
        
        -- Position nodes horizontally
        self:distributeNodesInRow(rowNodes)
        
        -- Add row to map
        self.nodes[row] = rowNodes
    end
    
    -- Create connections between rows
    self:createConnections()
end

function ProvinceMap:createConnections()
    -- Create connections between each level
    for level = 1, #self.nodes - 1 do
        self:connectLevels(level)
    end
end

function ProvinceMap:getRandomEncounterType(row)
    -- Define possible encounter types for each row
    local encounterPool
    if row == 1 then
        -- First row: always market
        return "market"
    elseif row == self.NUM_LEVELS then
        -- Final row: showdown (special battle)
        return "card_battle"  -- We can add a special "showdown" type later if needed
    elseif row == 2 then
        -- Second row: keep as battle encounters
        return "card_battle"
    else
        -- Other rows: mix of encounters
        encounterPool = {"card_battle", "market", "beneficial", "negative", "lore"}
        return encounterPool[self.randomGenerator:random(#encounterPool)]
    end
end

function ProvinceMap:getSpecificEncounter(encounterType)
    -- Return specific encounter based on type
    if encounterType == "card_battle" then
        if self.currentLevel == self.NUM_LEVELS then
            return "final_showdown"  -- New encounter type for final battle
        else
            return self.randomGenerator:random() < 0.5 and "food_critic" or "rush_hour"
        end
    elseif encounterType == "market" then
        if self.currentLevel == 1 then
            return "starting_market"  -- Special first market type
        else
            return "farmers_market"
        end
    end
    return encounterType
end

function ProvinceMap:connectLevels(level)
    local currentLevel = self.nodes[level]
    local nextLevel = self.nodes[level + 1]
    
    -- First pass: Ensure each node has at least one connection
    for i, node in ipairs(currentLevel) do
        -- Calculate the most natural target based on position
        local bestTargetIndex = math.floor(i * (#nextLevel / #currentLevel))
        bestTargetIndex = math.max(1, math.min(bestTargetIndex, #nextLevel))
        
        -- Add primary connection
        table.insert(node.connections, bestTargetIndex)
    end
    
    -- Second pass: Add additional connections where possible
    for i, node in ipairs(currentLevel) do
        if #node.connections < 2 then  -- If node doesn't have second connection yet
            local currentConn = node.connections[1]
            
            -- Try connecting to adjacent nodes
            local potentialTargets = {}
            if currentConn > 1 then
                table.insert(potentialTargets, currentConn - 1)
            end
            if currentConn < #nextLevel then
                table.insert(potentialTargets, currentConn + 1)
            end
            
            -- Try each potential target
            for _, targetIndex in ipairs(potentialTargets) do
                if self:canAddConnection(level, i, targetIndex) then
                    table.insert(node.connections, targetIndex)
                    break
                end
            end
        end
    end
    
    -- Sort connections for consistent rendering
    for _, node in ipairs(currentLevel) do
        table.sort(node.connections)
    end
end

function ProvinceMap:canAddConnection(level, fromIndex, toIndex)
    local currentLevel = self.nodes[level]
    
    -- Check if this connection would cross any existing ones
    for j, otherNode in ipairs(currentLevel) do
        if j ~= fromIndex then  -- Don't check against self
            for _, otherConn in ipairs(otherNode.connections) do
                if self:wouldConnectionsCross(fromIndex, toIndex, j, otherConn) then
                    return false
                end
            end
        end
    end
    
    -- Check if target already has too many incoming connections
    local incomingCount = self:countIncomingConnections(level + 1, toIndex)
    if incomingCount >= 2 then  -- Limit incoming connections to 2
        return false
    end
    
    return true
end

function ProvinceMap:wouldConnectionsCross(fromIndex1, toIndex1, fromIndex2, toIndex2)
    -- If the connections share a node, they don't cross
    if fromIndex1 == fromIndex2 or toIndex1 == toIndex2 then
        return false
    end
    
    -- Check if the connections cross
    return (fromIndex1 < fromIndex2 and toIndex1 > toIndex2) or
           (fromIndex1 > fromIndex2 and toIndex1 < toIndex2)
end

-- Helper function to check if a node already has a connection to a specific target
function ProvinceMap:hasConnection(node, targetIndex)
    for _, conn in ipairs(node.connections) do
        if conn == targetIndex then
            return true
        end
    end
    return false
end

-- Helper function to count incoming connections for a node
function ProvinceMap:countIncomingConnections(level, nodeIndex)
    if level <= 1 then return 0 end
    
    local count = 0
    local prevRow = self.nodes[level - 1]
    for _, node in ipairs(prevRow) do
        for _, conn in ipairs(node.connections) do
            if conn == nodeIndex then
                count = count + 1
            end
        end
    end
    return count
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
    -- Update camera position
    local screenH = love.graphics.getHeight()
    
    -- Handle page up/down for peeking
    if love.keyboard.isDown('pageup') then
        self.peekOffset = math.min(self.peekOffset + self.PEEK_SPEED * dt, self.mapHeight)
    elseif love.keyboard.isDown('pagedown') then
        self.peekOffset = math.max(self.peekOffset - self.PEEK_SPEED * dt, -self.mapHeight)
    end
    
    -- Calculate target camera Y based on current level plus peek offset
    local targetY = (self.NUM_LEVELS - self.currentLevel) * self.LEVEL_HEIGHT
    targetY = math.max(0, targetY - screenH/2)  -- Center current level
    targetY = math.min(targetY, self.mapHeight - screenH)  -- Clamp to map bounds
    targetY = targetY - self.peekOffset  -- Apply peek offset
    self.camera.targetY = targetY
    
    -- Smooth camera movement
    local dy = self.camera.targetY - self.camera.y
    if math.abs(dy) > 1 then
        self.camera.y = self.camera.y + dy * math.min(dt * 5, 1)
    end
    
    -- Handle node selection - only left/right movement
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

function ProvinceMap:drawMapInfo()
    -- Set up constants for info panel
    local padding = 10
    local lineHeight = 20
    local panelWidth = 200
    local panelHeight = 100
    local x = padding
    local y = padding
    
    -- Semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle('fill', x, y, panelWidth, panelHeight)
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.rectangle('line', x, y, panelWidth, panelHeight)
    
    -- Set font for info text
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Draw info text
    local textX = x + padding
    local textY = y + padding
    
    -- Display map seed
    love.graphics.print(string.format("Seed: %d", self:getSeed()), textX, textY)
    textY = textY + lineHeight
    
    -- Display chef name
    local chefName = gameState.selectedChef and gameState.selectedChef.name or "Unknown Chef"
    love.graphics.print(string.format("Chef: %s", chefName), textX, textY)
    textY = textY + lineHeight
    
    -- Display progress
    love.graphics.print(string.format("Level: %d/%d", self.currentLevel, self.NUM_LEVELS), textX, textY)
    textY = textY + lineHeight
    
    -- Count total nodes and completed nodes
    local totalNodes = 0
    local completedNodes = 0
    for level, nodes in ipairs(self.nodes) do
        totalNodes = totalNodes + #nodes
        for i, _ in ipairs(nodes) do
            if self.completedNodes[level .. "," .. i] then
                completedNodes = completedNodes + 1
            end
        end
    end
    love.graphics.print(string.format("Nodes: %d/%d", completedNodes, totalNodes), textX, textY)
end

function ProvinceMap:draw()
    love.graphics.push()
    love.graphics.translate(0, -self.camera.y)
    
    -- Draw connections and nodes
    self:drawConnections()
    
    for level, nodes in ipairs(self.nodes) do
        for i, node in ipairs(nodes) do
            if self:isNodeVisible(node) then
                self:drawNode(level, i, node)
            end
        end
    end
    
    love.graphics.pop()
    
    -- Draw UI elements that shouldn't scroll
    -- Add map info display
    self:drawMapInfo()
    
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

function ProvinceMap:drawConnections()
    love.graphics.setLineWidth(self.ROAD_WIDTH)
    
    -- Draw connection lines
    for level = 1, #self.nodes - 1 do
        local currentRow = self.nodes[level]
        local nextRow = self.nodes[level + 1]
        
        for i, node in ipairs(currentRow) do
            local startX = node.x
            local startY = node.y
            
            for _, connIdx in ipairs(node.connections) do
                local endX = nextRow[connIdx].x
                local endY = nextRow[connIdx].y
                
                -- Generate path points using bezier curve
                local points = {}
                local segments = 20
                for s = 0, segments do
                    local t = s / segments
                    -- Curved path using quadratic bezier
                    local controlX = (startX + endX) / 2
                    local controlY = startY + (endY - startY) * 0.5
                    
                    local px = math.pow(1-t, 2) * startX + 
                              2 * (1-t) * t * controlX + 
                              math.pow(t, 2) * endX
                    local py = math.pow(1-t, 2) * startY + 
                              2 * (1-t) * t * controlY + 
                              math.pow(t, 2) * endY
                    
                    table.insert(points, {x = px, y = py})
                end
                
                -- Draw path shadow
                love.graphics.setColor(0, 0, 0, 0.3)
                local linePoints = {}
                for _, point in ipairs(points) do
                    table.insert(linePoints, point.x)
                    table.insert(linePoints, point.y)
                end
                love.graphics.line(linePoints)
                
                -- Draw base road
                love.graphics.setColor(self.ROAD_COLOR)
                love.graphics.line(linePoints)
                
                -- Only animate if this connection leads to the selected node
                local isConnectedToSelected = (level == self.currentLevel - 1 and 
                                             connIdx == self.selected and
                                             self.completedNodes[level .. "," .. i])
                
                if isConnectedToSelected then
                    -- Draw animated dots
                    love.graphics.setColor(1, 1, 1, 0.8)
                    local dotSize = 2
                    local speed = 0.15
                    local numDots = 3  -- Number of dots per path
                    
                    -- Draw smoothly moving dots
                    for dot = 0, numDots - 1 do
                        local time = (love.timer.getTime() * speed + dot / numDots) % 1
                        -- Get exact position along curve using interpolation
                        local idx = 1 + time * (#points - 1)
                        local i1, i2 = math.floor(idx), math.ceil(idx)
                        local t = idx - i1
                        
                        if points[i1] and points[i2] then
                            local x = points[i1].x * (1 - t) + points[i2].x * t
                            local y = points[i1].y * (1 - t) + points[i2].y * t
                            love.graphics.circle('fill', x, y, dotSize)
                        end
                    end
                end
            end
        end
    end
    
    -- Reset graphics state
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

function ProvinceMap:drawNode(level, i, node)
    -- Convert node position to screen space for visibility checks
    local _, screenY = self:worldToScreen(node.x, node.y)
    
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
    local eventName = self.encounterNames[node.encounterType] or self.encounterNames[node.type] or "Unknown"
    
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

-- Helper function to check if table contains value
function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

function ProvinceMap:isNodeVisible(node)
    local screenH = love.graphics.getHeight()
    local nodeY = node.y
    -- Adjust visibility check to match new scroll direction
    return nodeY >= self.camera.y - 50 and nodeY <= self.camera.y + screenH + 50
end

function ProvinceMap:worldToScreen(x, y)
    -- Invert Y transformation
    return x, y - self.camera.y
end

function ProvinceMap:screenToWorld(x, y)
    -- Invert Y transformation
    return x, y + self.camera.y
end

function ProvinceMap:distributeNodesInRow(nodes)
    local screenWidth = love.graphics.getWidth()
    local margin = 100  -- Reduced from previous value
    local usableWidth = screenWidth - (margin * 2)
    local spacing = usableWidth / (math.max(3, #nodes + 1))  -- Ensure minimum spacing even with fewer nodes
    
    -- Position nodes evenly across the screen
    for i, node in ipairs(nodes) do
        node.x = margin + spacing * i  -- Adjusted spacing calculation
    end
    
    -- Center the nodes horizontally
    local totalWidth = spacing * (#nodes + 1)
    local offset = (screenWidth - totalWidth) / 2
    
    for _, node in ipairs(nodes) do
        node.x = node.x + offset
    end
end

return ProvinceMap






















