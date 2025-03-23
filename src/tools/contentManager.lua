local ContentManager = {
    content = {
        cards = {},
        encounters = {},
        chefs = {}
    }
}

function ContentManager:init()
    self:loadContent()
end

function ContentManager:loadContent()
    -- Load card definitions
    self:loadCards()
    -- Load encounter definitions
    self:loadEncounters()
    -- Load chef definitions
    self:loadChefs()
end

function ContentManager:loadCards()
    -- TODO: Load from actual data files
    self.content.cards = {
        -- Example card definitions
        card_001 = {
            id = "card_001",
            name = "Tomato",
            description = "A fresh tomato",
            cardType = "ingredient",
            cost = 1
        },
        card_002 = {
            id = "card_002",
            name = "Dice",
            description = "Dice ingredients finely",
            cardType = "technique",
            cost = 2
        }
    }
end

function ContentManager:loadEncounters()
    -- TODO: Load from actual data files
    self.content.encounters = {
        -- Example encounter definitions
        food_critic = {
            type = "battle",
            name = "Food Critic Challenge",
            difficulty = 1
        },
        farmers_market = {
            type = "market",
            name = "Farmers Market",
            inventory_size = 6
        }
    }
end

function ContentManager:loadChefs()
    -- TODO: Load from actual data files
    self.content.chefs = {
        -- Example chef definitions
        chef_001 = {
            id = "chef_001",
            name = "Chef Bob",
            specialty = "Italian Cuisine",
            starting_deck = {"card_001", "card_002"}
        }
    }
end

function ContentManager:validateContent()
    local errors = {}
    
    -- Validate cards
    for id, card in pairs(self.content.cards) do
        local cardTester = require('src.tools.cardTester').new()
        local valid, cardErrors = cardTester:validateCard(card)
        if not valid then
            errors[id] = cardErrors
        end
    end
    
    -- Validate encounters
    -- Add encounter validation logic
    
    return #errors == 0, errors
end

function ContentManager:exportContent(path)
    -- Export content to JSON for external editing
    local json = require('lib.json')
    local file = io.open(path, "w")
    if file then
        file:write(json.encode(self.content))
        file:close()
        return true
    end
    return false
end

function ContentManager:getProjectStats()
    local stats = {
        files = 0,
        lines = 0,
        assetSize = 0,
        luaFiles = 0,
        imageFiles = 0,
        audioFiles = 0
    }
    
    local function isHidden(name)
        return name:sub(1, 1) == "." or name:match("/%.") -- Checks if name starts with . or contains /.
    end
    
    local function scanDirectory(dir)
        -- Skip hidden directories
        if isHidden(dir) then
            return
        end
        
        local items = love.filesystem.getDirectoryItems(dir)
        for _, item in ipairs(items) do
            -- Skip hidden files and folders
            if not isHidden(item) then
                local path = dir .. (dir ~= "" and "/" or "") .. item
                local info = love.filesystem.getInfo(path)
                
                if info.type == "file" then
                    stats.files = stats.files + 1
                    stats.assetSize = stats.assetSize + info.size
                    
                    -- Count lines in Lua files
                    if item:match("%.lua$") then
                        stats.luaFiles = stats.luaFiles + 1
                        local content = love.filesystem.read(path)
                        if content then
                            stats.lines = stats.lines + select(2, content:gsub("\n", "\n"))
                        end
                    elseif item:match("%.png$") or item:match("%.jpg$") then
                        stats.imageFiles = stats.imageFiles + 1
                    elseif item:match("%.wav$") or item:match("%.ogg$") or item:match("%.mp3$") then
                        stats.audioFiles = stats.audioFiles + 1
                    end
                elseif info.type == "directory" then
                    scanDirectory(path)
                end
            end
        end
    end
    
    scanDirectory("")
    
    -- Convert assetSize to MB
    stats.assetSizeMB = string.format("%.2f", stats.assetSize / (1024 * 1024))
    
    return stats
end

return ContentManager


