local CardVisuals = {
    -- States
    STATES = {
        DEFAULT = "default",
        SELECTED = "selected",
        LOCKED = "locked",
        DISABLED = "disabled",
        HIGHLIGHTED = "highlighted"  -- New state for temporary highlights
    },

    -- Color schemes for different card types
    TYPE_COLORS = {
        ingredient = {
            PRIMARY = {0.95, 0.95, 0.95, 1},    -- Off-white
            SECONDARY = {0.4, 0.8, 0.4, 1},     -- Green
            ACCENT = {0.2, 0.6, 0.2, 1},        -- Dark green
            TITLE_BG = {0.3, 0.7, 0.3, 0.2},    -- Light green
            TEXT = {0.2, 0.3, 0.2, 1},          -- Dark green-grey
            BORDER = {0.3, 0.7, 0.3, 1}         -- Medium green
        },
        technique = {
            PRIMARY = {0.95, 0.95, 1, 1},       -- Light blue-white
            SECONDARY = {0.3, 0.5, 0.9, 1},     -- Blue
            ACCENT = {0.2, 0.3, 0.8, 1},        -- Dark blue
            TITLE_BG = {0.3, 0.5, 0.9, 0.2},    -- Light blue
            TEXT = {0.2, 0.2, 0.3, 1},          -- Dark blue-grey
            BORDER = {0.3, 0.5, 0.9, 1}         -- Medium blue
        },
        recipe = {
            PRIMARY = {1, 0.95, 0.95, 1},       -- Light pink-white
            SECONDARY = {0.9, 0.3, 0.5, 1},     -- Pink
            ACCENT = {0.8, 0.2, 0.3, 1},        -- Dark pink
            TITLE_BG = {0.9, 0.3, 0.5, 0.2},    -- Light pink
            TEXT = {0.3, 0.2, 0.2, 1},          -- Dark pink-grey
            BORDER = {0.9, 0.3, 0.5, 1}         -- Medium pink
        },
        action = {
            PRIMARY = {0.3, 0.3, 0.35, 1},    -- Dark slate
            SECONDARY = {0.4, 0.4, 0.45, 1},  -- Medium slate
            ACCENT = {0.5, 0.5, 0.55, 1},     -- Light slate
            TITLE_BG = {0.35, 0.35, 0.4, 0.2}, -- Semi-transparent slate
            TEXT = {0.8, 0.8, 0.85, 1},       -- Light grey
            BORDER = {0.45, 0.45, 0.5, 1}     -- Medium-light slate
        }
    },

    -- Common colors for states
    COLORS = {
        DEFAULT = {1, 1, 1, 1},
        SELECTED = {1, 0.9, 0.4, 1},
        LOCKED = {0.6, 0.6, 0.7, 1},
        DISABLED = {0.5, 0.5, 0.5, 0.7},
        HIGHLIGHTED = {0.4, 0.8, 1, 1},
        BORDER = {0.2, 0.2, 0.25, 1},
        HIGHLIGHT = {1, 0.6, 0, 1}
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
            WIDTH = 160,          -- Match new card width
            HEIGHT = 220,         -- Match new card height
            CORNER_RADIUS = 10,   -- Slightly increased for larger card
            BORDER_WIDTH = 2,     -- Slightly thicker border
            INNER_MARGIN = 12,    -- Increased margin
            TITLE_HEIGHT = 35,    -- Taller title section
            DESC_MARGIN_TOP = 90  -- Adjusted to accommodate image section
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
            TITLE = love.graphics.newFont(16),       -- Slightly larger
            DESCRIPTION = love.graphics.newFont(13),  -- Slightly larger
            STATS = love.graphics.newFont(12)        -- Slightly larger
        },
        SECTIONS = {
            IMAGE_HEIGHT = 60,    -- Define image section height
            TYPE_MARGIN = 8,      -- Margin after type section
            DESC_PADDING = 8,     -- Padding around description
            FOOTER_HEIGHT = 30    -- Height for footer section
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
    -- Don't change state if it's the same as current
    if self.currentState == newState then
        return
    end
    
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









