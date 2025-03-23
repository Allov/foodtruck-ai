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
    love.math.setRandomState(self.randomGenerator:getState())
    
    self.nodes = {}
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local LEVEL_HEIGHT = 100  -- Vertical spacing between levels
    local HORIZONTAL_PADDING = 100  -- Minimum distance from screen edges

    -- Constants
    local NUM_LEVELS = 4
    local START_Y = screenH - LEVEL_HEIGHT

    -- 1. Generate node positions level by level
    for level = 1, NUM_LEVELS do
        self.nodes[level] = {}
        local currentY = START_Y - (level - 1) * LEVEL_HEIGHT
        
        -- Determine number of nodes for this level
        local nodeCount
        if level == 1 or level == NUM_LEVELS then
            nodeCount = 2  -- First and last levels always have 2 nodes
        else
            nodeCount = love.math.random(3, 4)  -- Middle levels have 3-4 nodes
        end
        
        -- Calculate horizontal spacing
        local usableWidth = screenW - (2 * HORIZONTAL_PADDING)
        local spacing = usableWidth / (nodeCount + 1)
        
        -- Generate nodes for this level
        for i = 1, nodeCount do
            -- Calculate base position
            local baseX = HORIZONTAL_PADDING + (i * spacing)
            -- Add small random offset but ensure it stays within bounds
            local offsetX = love.math.random(-20, 20)
            local finalX = math.max(HORIZONTAL_PADDING, 
                                  math.min(baseX + offsetX, screenW - HORIZONTAL_PADDING))
            
            -- Determine node type
            local nodeType
            if level == 1 then
                nodeType = "market"  -- Starting nodes are markets
            elseif level == NUM_LEVELS then
                nodeType = "card_battle"  -- Final nodes are battles
            else
                nodeType = self:randomEncounterType()
            end
            
            -- Create node
            table.insert(self.nodes[level], {
                x = finalX,
                y = currentY,
                type = nodeType,
                connections = {}
            })
        end
    end
    
    -- 2. Create connections between levels
    for level = 1, NUM_LEVELS - 1 do
        self:connectLevels(level)
    end
    
    -- Restore the original random state
    love.math.setRandomState(oldState)
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
    self:drawConnections()
    
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
                    
                    table.insert(points, px)
                    table.insert(points, py)
                end
                
                -- Draw path shadow
                love.graphics.setColor(0, 0, 0, 0.3)
                love.graphics.line(points)
                
                -- Draw dashed line with animation
                love.graphics.setColor(self.ROAD_COLOR)
                local dashLength = self.ROAD_DASH
                local totalLength = 0
                
                -- Calculate total path length
                for j = 1, #points - 2, 2 do
                    local dx = points[j+2] - points[j]
                    local dy = points[j+3] - points[j+1]
                    totalLength = totalLength + math.sqrt(dx * dx + dy * dy)
                end
                
                -- Draw dashed line segments
                local currentLength = 0
                local isDash = true
                local lastX, lastY = points[1], points[2]
                
                -- Offset based on time (slowed down)
                local timeOffset = (love.timer.getTime() * 30) % (dashLength * 2)
                
                for j = 1, #points - 2, 2 do
                    local dx = points[j+2] - points[j]
                    local dy = points[j+3] - points[j+1]
                    local segLength = math.sqrt(dx * dx + dy * dy)
                    
                    -- Draw moving indicators (slowed down)
                    local numIndicators = math.floor(totalLength / 80) -- Increased spacing
                    for k = 1, numIndicators do
                        local offset = (love.timer.getTime() * 40 + (k * totalLength / numIndicators)) % totalLength
                        if offset >= currentLength and offset < currentLength + segLength then
                            local t = (offset - currentLength) / segLength
                            local ix = points[j] + dx * t
                            local iy = points[j+1] + dy * t
                            love.graphics.setColor(1, 1, 1, 0.9)
                            love.graphics.circle('fill', ix, iy, 3)
                        end
                    end
                    
                    -- Draw dashed segments with fixed length
                    local segmentStart = currentLength
                    while segmentStart < currentLength + segLength do
                        local dashStart = segmentStart + timeOffset
                        local dashEnd = math.min(dashStart + dashLength, currentLength + segLength)
                        
                        if isDash then
                            local t1 = (dashStart - currentLength) / segLength
                            local t2 = (dashEnd - currentLength) / segLength
                            
                            local x1 = points[j] + dx * t1
                            local y1 = points[j+1] + dy * t1
                            local x2 = points[j] + dx * t2
                            local y2 = points[j+1] + dy * t2
                            
                            love.graphics.line(x1, y1, x2, y2)
                        end
                        
                        segmentStart = segmentStart + dashLength
                        isDash = not isDash
                    end
                    
                    currentLength = currentLength + segLength
                end
            end
        end
    end
    
    -- Reset graphics state
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
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

-- Helper function to check if table contains value
function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

return ProvinceMap






















