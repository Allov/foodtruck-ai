local BaseMenu = require('src.scenes.baseMenu')
local MenuStyle = require('src.ui.menuStyle')

local SeedInput = {}
SeedInput.__index = SeedInput
setmetatable(SeedInput, BaseMenu)

function SeedInput.stringToSeed(str)
    local seed = 0
    for i = 1, #str do
        seed = seed + string.byte(str, i) * (i * 256)
    end
    return seed
end

function SeedInput.new()
    local self = BaseMenu.new()
    setmetatable(self, SeedInput)
    self:init()
    return self
end

function SeedInput:init()
    BaseMenu.init(self)
    self.options = {
        "Random Seed",
        "Enter Custom Seed"
    }
    self:setupClickables()
end

function SeedInput:onClick(index)
    if index == 1 then
        gameState.mapSeed = os.time()
        sceneManager:switch('chefSelect')
    else
        self:startInput(
            "Enter Seed:",
            function(text) return text:match("^[%w%s%-_%.]+$") end,
            function(text)
                gameState.mapSeed = self.stringToSeed(text)
                sceneManager:switch('chefSelect')
            end
        )
    end
end

function SeedInput:draw()
    BaseMenu.draw(self)
    self:drawTitle("Choose Seed Type")

    local instructions = self.inputting and
        "Type seed and press Enter, Escape to cancel" or
        "Use ↑↓ or mouse to select, Enter or click to confirm"
    MenuStyle.drawInstructions(instructions)
end

return SeedInput


