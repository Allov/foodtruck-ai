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
            DEFAULT = {1, 1, 1, 1},
            SELECTED = {1, 0.9, 0.4, 1},
            LOCKED = {0.6, 0.6, 0.7, 1},
            DISABLED = {0.5, 0.5, 0.5, 0.7},
            HIGHLIGHTED = {0.4, 0.8, 1, 1},
            BORDER = {0.2, 0.2, 0.25, 1},
            HIGHLIGHT = {1, 0.6, 0, 1},
            ACCENT = {0.3, 0.5, 0.9, 1},
            TITLE = {0.1, 0.1, 0.15, 1},
            DESCRIPTION = {0.2, 0.2, 0.25, 1}
        },
        FONTS = {
            TITLE = love.graphics.newFont(14),
            DESCRIPTION = love.graphics.newFont(12),
            STATS = love.graphics.newFont(11)
        },
        ICONS = {
            -- For now, we'll use a simple text character as a lock icon
            -- Later you can replace this with actual icon images
            LOCK = "🔒"
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
    -- If card is locked, only allow changing to unlocked (DEFAULT) state
    if self.currentState == self.STATES.LOCKED and newState ~= self.STATES.DEFAULT then
        return
    end
    
    self.previousState = self.currentState
    self.currentState = newState
    print("[CardVisuals:setState] State changed from", self.previousState, "to", self.currentState)
    self:updateAnimationTargets()
end

function CardVisuals:updateAnimationTargets()
    local lift = self.animations.lift
    
    if self.currentState == self.STATES.LOCKED then
        lift.target = self.ANIMATION.LIFT.AMOUNT  -- Full lift amount for locked cards
    elseif self.currentState == self.STATES.SELECTED then
        lift.target = self.ANIMATION.LIFT.AMOUNT / 2  -- Half lift for selected cards
    else
        lift.target = 0  -- No lift for default state
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









