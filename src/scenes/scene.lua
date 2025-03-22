local Scene = {}
Scene.__index = Scene

function Scene.new()
    local self = setmetatable({}, Scene)
    return self
end

-- Shared confirmation dialog state
function Scene:initConfirmDialog()
    self.showingConfirmDialog = false
    self.confirmDialogOptions = {"Yes", "No"}
    self.confirmDialogSelected = 2  -- Default to "No"
end

-- Shared confirmation dialog update logic
function Scene:updateConfirmDialog()
    if love.keyboard.wasPressed('left') or love.keyboard.wasPressed('right') then
        self.confirmDialogSelected = self.confirmDialogSelected == 1 and 2 or 1
    elseif love.keyboard.wasPressed('return') then
        self.showingConfirmDialog = false  -- Hide dialog regardless of choice
        if self.confirmDialogSelected == 1 then  -- Yes
            -- Reset game state
            gameState = {
                currentEncounter = nil,
                selectedChef = nil,
                mapSeed = nil,
                progress = {
                    level = 1,
                    score = 0,
                    encounters = {}
                }
            }
            sceneManager:switch('mainMenu')
        end
    end
end

-- Shared confirmation dialog drawing
function Scene:drawConfirmDialog()
    -- Draw semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw dialog box
    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    local boxWidth = 400
    local boxHeight = 150
    local boxX = (love.graphics.getWidth() - boxWidth) / 2
    local boxY = (love.graphics.getHeight() - boxHeight) / 2
    love.graphics.rectangle('fill', boxX, boxY, boxWidth, boxHeight)
    
    -- Draw text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(
        "End current game and return to main menu?",
        boxX,
        boxY + 30,
        boxWidth,
        'center'
    )
    
    -- Draw options with proper centering
    local buttonSpacing = 100  -- Space between buttons
    local totalButtonsWidth = buttonSpacing * (#self.confirmDialogOptions - 1)
    local startX = boxX + (boxWidth - totalButtonsWidth) / 2
    
    for i, option in ipairs(self.confirmDialogOptions) do
        if i == self.confirmDialogSelected then
            love.graphics.setColor(1, 1, 0, 1)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
        
        love.graphics.printf(
            option,
            startX + (i-1) * buttonSpacing - 50,
            boxY + 80,
            100,
            'center'
        )
    end
end

function Scene:init() end
function Scene:enter() end
function Scene:exit() end
function Scene:update(dt) end
function Scene:draw() end
function Scene:destroy() end

return Scene



