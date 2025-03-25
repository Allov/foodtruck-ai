local MouseHelper = {}

-- Represents a clickable area with position, size, and callback
function MouseHelper.newClickable(x, y, width, height, hoverCallback, clickCallback)
    return {
        x = x,
        y = y,
        width = width,
        height = height,
        hover = hoverCallback,
        click = clickCallback,
        isHovered = false
    }
end

-- Check if a point is inside a clickable area
function MouseHelper.isInside(clickable, px, py)
    return px >= clickable.x
        and px <= clickable.x + clickable.width
        and py >= clickable.y
        and py <= clickable.y + clickable.height
end

-- Create a collection of clickable areas
function MouseHelper.newClickableCollection()
    return {
        items = {},

        -- Add a new clickable area
        add = function(self, clickable)
            table.insert(self.items, clickable)
            return #self.items -- return index for reference
        end,

        -- Update hover states
        update = function(self, mx, my)
            for _, item in ipairs(self.items) do
                local wasHovered = item.isHovered
                item.isHovered = MouseHelper.isInside(item, mx, my)

                -- Call hover callback only when state changes
                if item.hover and wasHovered ~= item.isHovered then
                    item.hover(item.isHovered)
                end
            end
        end,

        -- Handle click
        click = function(self, mx, my, button)
            for _, item in ipairs(self.items) do
                if MouseHelper.isInside(item, mx, my) and item.click then
                    item.click(button)
                    return true -- click handled
                end
            end
            return false -- no click handled
        end,

        -- Debug draw all clickable areas
        debugDraw = function(self)
            if not _DEBUG then return end

            love.graphics.push('all')
            love.graphics.setLineWidth(2) -- Set outline width to 2px
            for _, item in ipairs(self.items) do
                if item.isHovered then
                    love.graphics.setColor(0, 1, 0, 0.8)
                    love.graphics.rectangle('line',
                        item.x, item.y,
                        item.width, item.height)
                end
            end
            love.graphics.pop()
        end,

        -- Clear all clickable areas
        clear = function(self)
            self.items = {}
        end
    }
end

return MouseHelper

