local CardVisuals = {
    -- Visual constants
    LIFT_AMOUNT = 20,
    ANIMATION_SPEED = 8,
    HOVER_SPEED = 2,
    HOVER_AMOUNT = 3,
    
    -- States
    STATES = {
        DEFAULT = "default",
        SELECTED = "selected",
        LOCKED = "locked",
        DISABLED = "disabled"
    }
}
CardVisuals.__index = CardVisuals  -- Add metatable

function CardVisuals.new()
    local self = setmetatable({}, CardVisuals)
    -- Animation properties
    self.currentOffset = 0
    self.targetOffset = 0
    self.isSelected = false
    self.isLocked = false
    self.hoverOffset = 0
    self.isScoring = false
    self.scoreTimer = 0
    self.scoreValue = 0
    return self
end

function CardVisuals:setState(state)
    if state == self.STATES.LOCKED then
        self.targetOffset = self.LIFT_AMOUNT
        self.isLocked = true
        self.isSelected = false
    elseif state == self.STATES.SELECTED then
        self.targetOffset = self.LIFT_AMOUNT / 2
        self.isLocked = false
        self.isSelected = true
    else
        self.targetOffset = 0
        self.isLocked = false
        self.isSelected = false
    end
end

function CardVisuals:updateHover(dt)
    self.hoverOffset = self.hoverOffset + (self.HOVER_SPEED * dt)
    if self.hoverOffset > math.pi * 2 then
        self.hoverOffset = 0
    end
end

function CardVisuals:updateLift(dt)
    local diff = self.targetOffset - self.currentOffset
    if math.abs(diff) > 0.1 then
        self.currentOffset = self.currentOffset + (diff * self.ANIMATION_SPEED * dt)
    else
        self.currentOffset = self.targetOffset
    end
end

function CardVisuals:updateScoring(dt)
    if self.isScoring then
        self.scoreTimer = self.scoreTimer + dt
        if self.scoreTimer >= 1 then
            self.isScoring = false
            self.scoreTimer = 0
        end
    end
end

function CardVisuals:update(dt)
    self:updateHover(dt)
    self:updateLift(dt)
    self:updateScoring(dt)
end

return CardVisuals
