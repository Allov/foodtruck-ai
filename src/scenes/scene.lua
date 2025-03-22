local Scene = {}
Scene.__index = Scene

function Scene.new()
    local self = setmetatable({}, Scene)
    return self
end

function Scene:initConfirmDialog()
    self.showingConfirmDialog = false
    self.confirmDialogOptions = {"Yes", "No"}
    self.confirmDialogSelected = 2  -- Default to "No"
    self.confirmDialogMessage = "Are you sure you want to exit?"
end

function Scene:updateConfirmDialog()
    if love.keyboard.wasPressed('left') or love.keyboard.wasPressed('right') then
        self.confirmDialogSelected = self.confirmDialogSelected == 1 and 2 or 1
    elseif love.keyboard.wasPressed('return') then
        if self.confirmDialogSelected == 1 then
            -- "Yes" selected
            sceneManager:switch('mainMenu')
        else
            -- "No" selected
            self.showingConfirmDialog = false
        end
    elseif love.keyboard.wasPressed('escape') then
        self.showingConfirmDialog = false
    end
end

function Scene:drawConfirmDialog()
    -- Draw semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw dialog box
    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    local boxWidth = 300
    local boxHeight = 150
    local boxX = (love.graphics.getWidth() - boxWidth) / 2
    local boxY = (love.graphics.getHeight() - boxHeight) / 2
    love.graphics.rectangle('fill', boxX, boxY, boxWidth, boxHeight)
    
    -- Draw message
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(
        self.confirmDialogMessage,
        boxX,
        boxY + 30,
        boxWidth,
        'center'
    )
    
    -- Draw options
    for i, option in ipairs(self.confirmDialogOptions) do
        if i == self.confirmDialogSelected then
            love.graphics.setColor(1, 1, 0, 1)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
        
        love.graphics.printf(
            option,
            boxX + (i-1) * (boxWidth/2),
            boxY + 90,
            boxWidth/2,
            'center'
        )
    end
end

function Scene:init()
    -- Base initialization if needed
end

function Scene:enter()
    -- Base enter method
end

function Scene:update(dt)
    -- Base update method
end

function Scene:draw()
    -- Base draw method
end

return Scene


