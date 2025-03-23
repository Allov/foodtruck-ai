local CardVisuals = {
    -- States
    STATES = {
        DEFAULT = "default",
        SELECTED = "selected",
        LOCKED = "locked",
        DISABLED = "disabled",
        HIGHLIGHTED = "highlighted"  -- New state for temporary highlights
    },

    -- Animation Constants
    ANIMATION = {
        LIFT = {
            AMOUNT = 20,
            SPEED = 8
        },
        HOVER = {
            AMOUNT = 3,
            SPEED = 2
        },
        SCORE = {
            DURATION = 1.0,
            RISE_HEIGHT = 40
        }
    },

    -- Style Constants (these will be used by Card's draw methods)
    STYLE = {
        DIMENSIONS = {
            WIDTH = 120,
            HEIGHT = 160,
            CORNER_RADIUS = 8,
            BORDER_WIDTH = 1,
            INNER_MARGIN = 10,
            TITLE_HEIGHT = 30,
            DESC_MARGIN_TOP = 45
        },
        COLORS = {
            -- Main card colors
            DEFAULT = {0.98, 0.98, 0.98, 1},    -- Almost white
            SELECTED = {1, 0.95, 0.8, 1},       -- Warm highlight
            LOCKED = {0.92, 0.92, 0.92, 1},     -- Light gray
            DISABLED = {0.85, 0.85, 0.85, 0.7}, -- Grayed out
            HIGHLIGHTED = {1, 0.9, 0.7, 1},     -- Highlighted state
            
            -- Text colors
            TITLE = {0.2, 0.2, 0.2, 1},         -- Dark gray for title
            DESCRIPTION = {0.3, 0.3, 0.3, 1},   -- Slightly lighter for description
            
            -- Borders and accents
            BORDER = {0.8, 0.8, 0.8, 1},        -- Light gray border
            ACCENT = {0.4, 0.5, 0.9},           -- Fixed: Added ACCENT color
            
            -- Special states
            HIGHLIGHT = {1, 0.85, 0.4, 1},      -- Golden highlight
            ERROR = {0.9, 0.3, 0.3, 1}          -- Error red
        },
        FONTS = {
            TITLE = love.graphics.newFont(14),
            DESCRIPTION = love.graphics.newFont(12),
            STATS = love.graphics.newFont(11)
        }
    }
}
CardVisuals.__index = CardVisuals

function CardVisuals.new()
    local self = setmetatable({}, CardVisuals)
    
    -- State
    self.currentState = self.STATES.DEFAULT
    self.previousState = nil
    
    -- Animation properties
    self.animations = {
        lift = {
            current = 0,
            target = 0
        },
        hover = {
            offset = 0
        },
        score = {
            active = false,
            timer = 0,
            value = 0
        }
    }
    
    return self
end

function CardVisuals:setState(newState)
    if self.STATES[newState] then
        self.previousState = self.currentState
        self.currentState = newState
        self:updateAnimationTargets()
    end
end

function CardVisuals:updateAnimationTargets()
    local lift = self.animations.lift
    
    if self.currentState == self.STATES.LOCKED then
        lift.target = self.ANIMATION.LIFT.AMOUNT
    elseif self.currentState == self.STATES.SELECTED then
        lift.target = self.ANIMATION.LIFT.AMOUNT / 2
    else
        lift.target = 0
    end
end

function CardVisuals:getVisualState()
    return {
        state = self.currentState,
        lift = self.animations.lift.current,
        hover = self.animations.hover.offset,
        scoring = self.animations.score.active,
        scoreValue = self.animations.score.value
    }
end

function CardVisuals:startScoreAnimation(value)
    self.animations.score.active = true
    self.animations.score.timer = 0
    self.animations.score.value = value
end

function CardVisuals:update(dt)
    -- Update lift animation
    local lift = self.animations.lift
    local liftDiff = lift.target - lift.current
    if math.abs(liftDiff) > 0.1 then
        lift.current = lift.current + (liftDiff * self.ANIMATION.LIFT.SPEED * dt)
    else
        lift.current = lift.target
    end
    
    -- Update hover animation
    local hover = self.animations.hover
    hover.offset = hover.offset + (self.ANIMATION.HOVER.SPEED * dt)
    if hover.offset > math.pi * 2 then
        hover.offset = 0
    end
    
    -- Update score animation
    local score = self.animations.score
    if score.active then
        score.timer = score.timer + dt
        if score.timer >= self.ANIMATION.SCORE.DURATION then
            score.active = false
            score.timer = 0
        end
    end
end

return CardVisuals


