function love.load()
    -- Initialize game state
end

function love.update(dt)
    -- Update game state
end

function love.draw()
    -- Set color to white
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Draw "Hello World" in the middle of the screen
    love.graphics.print(
        "Hello World!",
        love.graphics.getWidth() / 2,
        love.graphics.getHeight() / 2,
        0,
        2,
        2,
        50,
        15
    )
end