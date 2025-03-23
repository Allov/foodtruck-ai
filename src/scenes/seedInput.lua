local Scene = require('src.scenes.scene')
local MenuStyle = require('src.ui.menuStyle')

local SeedInput = {}
SeedInput.__index = SeedInput
setmetatable(SeedInput, Scene)

-- Animation constants (these are specific to title animation)
local FLOAT_SPEED = 1.5
local FLOAT_AMOUNT = 8
local SHIMMER_SPEED = 2

function SeedInput.new()
    local self = Scene.new()
    setmetatable(self, SeedInput)
    self:init()
    return self
end

function SeedInput:init()
    Scene.init(self)
    self.options = {
        "Random Seed",
        "Enter Custom Seed"
    }
    self.selected = 1
    self.inputtingSeed = false
    self.seedInput = ""
    
    -- Initialize animation variables
    self.titleOffset = 0
    self.titleAlpha = 1
end

function SeedInput:update(dt)
    -- Update title animations
    self.titleOffset = math.sin(love.timer.getTime() * FLOAT_SPEED) * FLOAT_AMOUNT
    self.titleAlpha = 1 - math.abs(math.sin(love.timer.getTime() * SHIMMER_SPEED) * 0.2)

    if love.keyboard.wasPressed('escape') then
        if self.inputtingSeed then
            self.inputtingSeed = false
            self.seedInput = ""
        else
            sceneManager:switch('mainMenu')
        end
        return
    end

    if self.inputtingSeed then
        if love.keyboard.wasPressed('return') and #self.seedInput > 0 then
            gameState.mapSeed = self.stringToSeed(self.seedInput)
            sceneManager:switch('chefSelect')
        elseif love.keyboard.wasPressed('backspace') then
            self.seedInput = self.seedInput:sub(1, -2)
        end
    else
        if love.keyboard.wasPressed('up') or love.keyboard.wasPressed('down') then
            self.selected = self.selected == 1 and 2 or 1
        elseif love.keyboard.wasPressed('return') then
            if self.selected == 1 then
                -- Random seed
                gameState.mapSeed = os.time()
                sceneManager:switch('chefSelect')
            else
                -- Enter custom seed
                self.inputtingSeed = true
            end
        end
    end
end

function SeedInput:draw()
    MenuStyle.drawBackground()
    
    -- Draw animated title
    love.graphics.setFont(MenuStyle.FONTS.TITLE)
    love.graphics.setColor(MenuStyle.COLORS.TITLE[1], MenuStyle.COLORS.TITLE[2], 
        MenuStyle.COLORS.TITLE[3], self.titleAlpha)
    love.graphics.printf("Choose Seed Type", 0, 
        MenuStyle.LAYOUT.TITLE_Y + self.titleOffset, 
        love.graphics.getWidth(), 'center')

    if self.inputtingSeed then
        -- Draw seed input interface
        love.graphics.setFont(MenuStyle.FONTS.MENU)
        love.graphics.setColor(MenuStyle.COLORS.TEXT)
        love.graphics.printf("Enter Seed:", 0, 
            MenuStyle.LAYOUT.MENU_START_Y, 
            love.graphics.getWidth(), 'center')
        love.graphics.printf(self.seedInput .. "_", 0, 
            MenuStyle.LAYOUT.MENU_START_Y + MenuStyle.LAYOUT.MENU_ITEM_HEIGHT, 
            love.graphics.getWidth(), 'center')
    else
        -- Draw menu options
        for i, option in ipairs(self.options) do
            MenuStyle.drawMenuItem(option, i, i == self.selected)
        end
    end

    -- Draw instructions
    local instructions = self.inputtingSeed and 
        "Type seed and press Enter, Escape to cancel" or 
        "Use ↑↓ to select, Enter to confirm"
    MenuStyle.drawInstructions(instructions)
end

return SeedInput
