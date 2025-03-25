local BaseMenu = require('src.scenes.baseMenu')
local MenuStyle = require('src.ui.menuStyle')

local GameOver = {}
GameOver.__index = GameOver
setmetatable(GameOver, BaseMenu)

function GameOver.new()
    local self = BaseMenu.new()
    setmetatable(self, GameOver)
    self:init()
    return self
end

function GameOver:init()
    BaseMenu.init(self)
    self.options = {
        "Return to Title"
    }
    self:setupClickables()
    self.finalStats = {
        battlesWon = 0,
        totalScore = 0,
        lastBattle = nil
    }
end

function GameOver:enter()
    -- Initialize stats when entering the scene
    if gameState and gameState.selectedChef then
        self.finalStats = {
            battlesWon = gameState.selectedChef.stats.battlesWon,
            totalScore = gameState.selectedChef.stats.totalScore,
            lastBattle = gameState.battleResults
        }
    end
end

function GameOver:onClick(index)
    if index == 1 then
        gameState = {}  -- Reset game state
        sceneManager:switch('mainMenu')
    end
end

function GameOver:update(dt)
    BaseMenu.update(self, dt)
end

function GameOver:drawStats()
    -- Panel dimensions and position
    local padding = 20
    local lineHeight = 30  -- Increased for better readability
    local panelWidth = 500
    local panelHeight = 200 + padding * 2  -- Slightly taller
    local x = (love.graphics.getWidth() - panelWidth) / 2
    local y = 290  -- Fixed position below GAME OVER title

    -- Draw panel background
    love.graphics.setColor(0.1, 0.15, 0.2, 0.95)  -- More opaque background
    love.graphics.rectangle('fill', x, y, panelWidth, panelHeight)

    -- Draw border
    love.graphics.setColor(1, 0.8, 0.2, 1)  -- Fully opaque gold border
    love.graphics.setLineWidth(2)
    love.graphics.rectangle('line', x, y, panelWidth, panelHeight)

    -- Content positioning
    local textX = x + padding
    local textY = y + padding

    -- Draw stats with larger font
    love.graphics.setFont(MenuStyle.FONTS.MENU)  -- Larger font

    -- Basic stats with styled header
    love.graphics.setColor(1, 0.8, 0.2, 1)  -- Bright gold for headers
    love.graphics.print("Run Statistics", textX, textY)
    textY = textY + lineHeight

    -- Stats with different color
    love.graphics.setColor(1, 1, 1, 1)  -- Pure white for stats
    love.graphics.print(string.format("Battles Won: %d", self.finalStats.battlesWon), textX + padding, textY)
    textY = textY + lineHeight
    love.graphics.print(string.format("Total Score: %d", self.finalStats.totalScore), textX + padding, textY)
    textY = textY + lineHeight * 2

    -- Final battle section
    if self.finalStats.lastBattle then
        love.graphics.setColor(1, 0.8, 0.2, 1)  -- Bright gold for header
        love.graphics.print("Final Battle", textX, textY)
        textY = textY + lineHeight

        love.graphics.setColor(1, 1, 1, 1)  -- Pure white for details
        love.graphics.print(string.format("Score: %d", self.finalStats.lastBattle.score), textX + padding, textY)
        textY = textY + lineHeight
        love.graphics.print(string.format("Dish Rating: %s", self.finalStats.lastBattle.dishRating), textX + padding, textY)
    end
end

function GameOver:draw()
    BaseMenu.draw(self)
    self:drawTitle("Game Over")

    -- Draw stats panel
    self:drawStats()

    -- Draw instructions at the bottom
    MenuStyle.drawInstructions("Use ↑↓ or mouse to select, Enter or click to confirm")
end

return GameOver







