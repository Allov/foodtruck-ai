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
    
    self:generateMap()
end

function ProvinceMap:generateMap()
    -- Create a 4-level tree structure
    self.nodes = {}
    self.currentLevel = 1
    self.selected = 1
    
    -- First level (start)
    self.nodes[1] = {
        {x = 400, y = 500, type = "start", connections = {1, 2}}  -- Connect to indices 1 and 2 of level 2
    }
    
    -- Second level
    self.nodes[2] = {
        {x = 300, y = 400, type = self:randomEncounterType(), connections = {1, 2}},  -- Connect to indices 1 and 2 of level 3
        {x = 500, y = 400, type = self:randomEncounterType(), connections = {2, 3}}   -- Connect to indices 2 and 3 of level 3
    }
    
    -- Third level
    self.nodes[3] = {
        {x = 200, y = 300, type = self:randomEncounterType(), connections = {1}},    -- Connect to index 1 of level 4
        {x = 400, y = 300, type = self:randomEncounterType(), connections = {1, 2}}, -- Connect to indices 1 and 2 of level 4
        {x = 600, y = 300, type = self:randomEncounterType(), connections = {2}}     -- Connect to index 2 of level 4
    }
    
    -- Fourth level (boss/final)
    self.nodes[4] = {
        {x = 300, y = 200, type = "card_battle", connections = {}},
        {x = 500, y = 200, type = "card_battle", connections = {}}
    }
end

function ProvinceMap:randomEncounterType()
    local roll = love.math.random(100)
    if roll <= 30 then
        return "card_battle"
    elseif roll <= 50 then
        return "beneficial"
    elseif roll <= 65 then
        return "negative"
    elseif roll <= 85 then
        return "market"
    else
        return "lore"
    end
end

function ProvinceMap:update(dt)
    if love.keyboard.wasPressed('left') then
        self.selected = self.selected - 1
        if self.selected < 1 then 
            self.selected = #self.nodes[self.currentLevel] 
        end
    end
    
    if love.keyboard.wasPressed('right') then
        self.selected = self.selected + 1
        if self.selected > #self.nodes[self.currentLevel] then 
            self.selected = 1 
        end
    end
    
    if love.keyboard.wasPressed('return') then
        local selectedNode = self.nodes[self.currentLevel][self.selected]
        -- Only allow proceeding if current node hasn't been completed
        if not self.completedNodes[self.currentLevel .. "," .. self.selected] then
            gameState.currentEncounter = selectedNode.type
            gameState.currentNodeLevel = self.currentLevel
            gameState.currentNodeIndex = self.selected
            sceneManager:switch('encounter')
        end
    end
end

function ProvinceMap:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Choose Your Path", 0, 50, love.graphics.getWidth(), 'center')
    
    -- Draw connections first (behind nodes)
    for level, nodes in ipairs(self.nodes) do
        for i, node in ipairs(nodes) do
            for _, connectedIndex in ipairs(node.connections) do
                local nextLevel = level + 1
                if self.nodes[nextLevel] then
                    local targetNode = self.nodes[nextLevel][connectedIndex]
                    if targetNode then
                        -- Draw connections in different colors based on completion
                        if self.completedNodes[level .. "," .. i] then
                            love.graphics.setColor(0, 1, 0, 1) -- Green for completed
                        else
                            love.graphics.setColor(0.5, 0.5, 0.5, 1) -- Gray for incomplete
                        end
                        love.graphics.line(node.x, node.y, targetNode.x, targetNode.y)
                    end
                end
            end
        end
    end
    
    -- Draw nodes
    for level, nodes in ipairs(self.nodes) do
        for i, node in ipairs(nodes) do
            local nodeKey = level .. "," .. i
            local isCompleted = self.completedNodes[nodeKey]
            
            -- Determine node color
            if level == self.currentLevel then
                if i == self.selected then
                    love.graphics.setColor(1, 1, 0, 1) -- Yellow for selected
                elseif isCompleted then
                    love.graphics.setColor(0, 1, 0, 1) -- Green for completed
                else
                    love.graphics.setColor(0.7, 0.7, 0.7, 1) -- Gray for available
                end
            else
                if level < self.currentLevel then
                    love.graphics.setColor(0.3, 0.3, 0.3, 1) -- Dark gray for past nodes
                else
                    love.graphics.setColor(1, 1, 1, 1) -- White for future nodes
                end
            end
            
            -- Draw node circle
            love.graphics.circle('fill', node.x, node.y, 20)
            
            -- Draw encounter type symbol
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.printf(
                self.encounterSymbols[node.type] or "⭐",
                node.x - 20,
                node.y - 10,
                40,
                'center'
            )
        end
    end
    
    -- Draw encounter type legend
    self:drawLegend()
end

function ProvinceMap:drawLegend()
    love.graphics.setColor(1, 1, 1, 1)
    local legendY = 550
    local spacing = 100
    
    for type, symbol in pairs(self.encounterSymbols) do
        love.graphics.printf(
            symbol .. " " .. type:gsub("_", " "):gsub("^%l", string.upper),
            spacing * (#self.encounterSymbols - 4),
            legendY,
            spacing,
            'left'
        )
        spacing = spacing + 100
    end
end

-- Add method to mark nodes as completed
function ProvinceMap:markNodeCompleted(level, index)
    self.completedNodes[level .. "," .. index] = true
    -- Advance to next level if current node is completed
    if level == self.currentLevel then
        self.currentLevel = self.currentLevel + 1
        self.selected = 1
        
        -- Check if we've reached the end of the map
        if self.currentLevel > #self.nodes then
            -- Handle game completion here
            print("Map completed!")
            -- You might want to switch to a victory scene or handle it differently
        end
    end
end

return ProvinceMap



