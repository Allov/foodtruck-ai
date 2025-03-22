local Scene = require('src.scenes.scene')
local Encounter = setmetatable({}, Scene)
Encounter.__index = Encounter

function Encounter.new()
    local self = setmetatable({}, Encounter)
    return self
end

function Encounter:init()
    self.encounterTypes = {
        CARD_BATTLE = "card_battle",
        BENEFICIAL = "beneficial",
        NEGATIVE = "negative",
        MARKET = "market",
        LORE = "lore"
    }
    
    -- Define possible encounters for each type
    self.encounterPool = {
        card_battle = {
            {
                title = "Food Critic Challenge",
                description = "A renowned food critic has arrived! They're ready to test your culinary skills.",
                options = {"Accept the challenge", "Try to negotiate", "Decline politely"}
            },
            {
                title = "Rush Hour Service",
                description = "The lunch rush is hitting hard! Can you handle the pressure?",
                options = {"Speed up service", "Call for backup", "Limit menu options"}
            },
            {
                title = "Cooking Competition",
                description = "A local TV show is hosting a cooking competition!",
                options = {"Show off signature dish", "Try new recipe", "Focus on presentation"}
            },
            {
                title = "Health Inspector Visit",
                description = "A surprise inspection! Your cooking skills will be thoroughly tested.",
                options = {"Welcome inspection", "Request postponement", "Show documentation"}
            }
        },
        beneficial = {
            {
                title = "Local Food Festival",
                description = "A food festival is happening nearby! This could be a great opportunity.",
                options = {"Set up a stall", "Network with chefs", "Learn new recipes"}
            },
            {
                title = "Ingredient Giveaway",
                description = "A local supplier is giving away premium ingredients!",
                options = {"Take fresh produce", "Choose exotic spices", "Get premium meats"}
            },
            {
                title = "Master Chef Workshop",
                description = "A famous chef is offering free cooking lessons!",
                options = {"Learn techniques", "Get secret recipe", "Ask for advice"}
            }
        },
        negative = {
            {
                title = "Equipment Malfunction",
                description = "Your main cooking equipment is acting up. This could be trouble!",
                options = {"Try emergency repairs", "Call technician", "Use backup equipment"}
            },
            {
                title = "Bad Weather",
                description = "A storm is affecting customer turnout!",
                options = {"Offer delivery", "Run weather special", "Close early"}
            },
            {
                title = "Ingredient Shortage",
                description = "Your key ingredients didn't arrive today!",
                options = {"Find substitutes", "Change menu", "Visit local market"}
            }
        },
        market = {
            {
                title = "Farmers Market",
                description = "You've found a local farmers market with fresh ingredients!",
                options = {"Browse produce", "Check specialty items", "Meet suppliers"}
            },
            {
                title = "Restaurant Supply Sale",
                description = "A major supplier is having a clearance sale!",
                options = {"Buy equipment", "Stock up basics", "Look for deals"}
            },
            {
                title = "Specialty Food Shop",
                description = "You've discovered a hidden gem of rare ingredients!",
                options = {"Buy exotic items", "Learn about products", "Make connections"}
            }
        },
        lore = {
            {
                title = "Local Food Legend",
                description = "You've met an elderly chef who knows ancient cooking secrets!",
                options = {"Listen to stories", "Learn techniques", "Request recipes"}
            },
            {
                title = "Cultural Festival",
                description = "A celebration of traditional cooking is taking place!",
                options = {"Study methods", "Try local dishes", "Meet elders"}
            },
            {
                title = "Recipe Discovery",
                description = "You've found an old cookbook with forgotten recipes!",
                options = {"Study recipes", "Try modernizing", "Preserve tradition"}
            }
        }
    }
    
    self.state = {
        type = nil,
        title = "",
        description = "",
        options = {},
        currentOption = 1
    }

    -- Initialize confirmation dialog
    self:initConfirmDialog()
end

function Encounter:setupEncounter(encounterType)
    local encounters = self.encounterPool[encounterType]
    if encounters then
        local chosen = encounters[love.math.random(#encounters)]
        self.state.type = encounterType
        self.state.title = chosen.title
        self.state.description = chosen.description
        self.state.options = chosen.options
    end
end

function Encounter:enter()
    -- Use the encounter type from game state
    if gameState.currentEncounter then
        self:setupEncounter(gameState.currentEncounter)
    else
        -- Fallback to random encounter if no type specified
        self:generateEncounter()
    end
end

function Encounter:generateEncounter()
    -- Random number between 1 and 100
    local roll = love.math.random(100)
    
    if roll <= 30 then
        self:setupEncounter("card_battle")
    elseif roll <= 50 then
        self:setupEncounter("beneficial")
    elseif roll <= 65 then
        self:setupEncounter("negative")
    elseif roll <= 85 then
        self:setupEncounter("market")
    else
        self:setupEncounter("lore")
    end
end

function Encounter:update(dt)
    if self.showingConfirmDialog then
        self:updateConfirmDialog()
        return
    end

    if love.keyboard.wasPressed('escape') then
        self.showingConfirmDialog = true
        return
    end

    if love.keyboard.wasPressed('up') then
        self.state.currentOption = self.state.currentOption - 1
        if self.state.currentOption < 1 then 
            self.state.currentOption = #self.state.options 
        end
    end
    
    if love.keyboard.wasPressed('down') then
        self.state.currentOption = self.state.currentOption + 1
        if self.state.currentOption > #self.state.options then 
            self.state.currentOption = 1 
        end
    end
    
    if love.keyboard.wasPressed('return') then
        self:resolveEncounter()
    end
end

function Encounter:draw()
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Draw encounter title
    love.graphics.printf(
        self.state.title,
        0,
        50,
        love.graphics.getWidth(),
        'center'
    )
    
    -- Draw description
    love.graphics.printf(
        self.state.description,
        50,
        120,
        love.graphics.getWidth() - 100,
        'center'
    )
    
    -- Draw options
    for i, option in ipairs(self.state.options) do
        if i == self.state.currentOption then
            love.graphics.setColor(1, 1, 0, 1)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
        
        love.graphics.printf(
            option,
            100,
            250 + (i * 40),
            love.graphics.getWidth() - 200,
            'left'
        )
    end

    -- Draw confirmation dialog if active
    if self.showingConfirmDialog then
        self:drawConfirmDialog()
    end
end

function Encounter:resolveEncounter()
    -- Only try to mark node as completed if we came from the province map
    if gameState.currentNodeLevel and gameState.currentNodeIndex then
        -- Get the province map scene
        local provinceMap = sceneManager.scenes['provinceMap']
        
        -- Mark the current node as completed
        provinceMap:markNodeCompleted(gameState.currentNodeLevel, gameState.currentNodeIndex)
    end
    
    -- Clear the current encounter
    gameState.currentEncounter = nil
    
    -- Return to previous scene (either provinceMap or debugMenu)
    if gameState.previousScene then
        sceneManager:switch(gameState.previousScene)
    else
        sceneManager:switch('provinceMap')
    end
end

return Encounter







