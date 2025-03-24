# Technical Debt Management Plan

## Deferred Systems Documentation

### 1. State Management Debt
Location: ProvinceMap.lua, ContentManager.lua
```lua
-- TODO: Replace with proper state machine
if encounterType == "card_battle" then
    return "food_critic"
end
```
Future Resolution:
- Implement proper state machine
- Add state validation
- Include state transitions
- Add proper error handling

### 2. Encounter System Simplification
Location: src/encounters/*.lua
Current Status:
- Removed multiple encounter types
- Simplified to food_critic and farmers_market
Future Expansion:
- Restore encounter variety
- Add proper type system
- Implement encounter factory
- Add validation layer

### 3. Debug System Limitations
Location: src/tools/debugConsole.lua
Current Compromises:
- Basic logging only
- Limited state inspection
- No performance metrics
Future Enhancements:
- Add comprehensive state inspection
- Implement performance monitoring
- Add replay system
- Include state snapshots

### 4. Save System Shortcuts
Current Implementation:
- Basic state serialization
- Limited validation
- No migration system
Future Requirements:
- Add proper schema validation
- Implement save migration
- Add corruption recovery
- Include backup system

## Code Markers

### Comment Tags
Use these tags to mark technical debt:
```lua
-- DEBT(state): Temporary state handling
-- DEBT(perf): Performance improvement needed
-- DEBT(valid): Add proper validation
-- DEBT(error): Improve error handling
-- DEBT(test): Add comprehensive tests
```

### Debug Flags
Add to Settings.lua:
```lua
Settings.DEBUG_FLAGS = {
    SHOW_DEBT_WARNINGS = false,    -- Show technical debt warnings
    LOG_STATE_CHANGES = false,     -- Log all state transitions
    VALIDATE_STATES = false,       -- Run extra state validation
    TRACK_PERFORMANCE = false      -- Log performance metrics
}
```

## Monitoring System

### Debug Console Commands
Add to debugConsole.lua:
```lua
-- Track technical debt in runtime
DebugConsole:addCommand("show_debt", function()
    -- List all DEBT comments in loaded files
    -- Show affected systems
    -- Display performance impacts
end)

-- Monitor deferred validations
DebugConsole:addCommand("check_debt", function()
    -- Run deferred validations
    -- Show potential issues
    -- Log recommendations
end)
```

## Recovery Strategies

### 1. State Management
Quick fixes:
- Add state logging
- Implement basic validation
- Add error recovery

### 2. Encounter System
Temporary solutions:
- Keep simplified encounters
- Add basic type checking
- Maintain encounter list

### 3. Save System
Immediate safeguards:
- Add checksum validation
- Implement basic backup
- Add corruption detection

## Documentation Requirements

### Code Comments
Required for deferred features:
```lua
-- DEBT(feature): [Feature name]
-- Current implementation: [Brief description]
-- Required changes: [List of needed improvements]
-- Dependencies: [Related systems]
-- Priority: [HIGH/MEDIUM/LOW]
```

### Debug Logging
Add to debugConsole.lua:
```lua
-- Log technical debt encounters
function DebugConsole:logDebtWarning(system, details)
    if Settings.DEBUG_FLAGS.SHOW_DEBT_WARNINGS then
        self:log(string.format("DEBT(%s): %s", system, details),
                self.LOG_LEVELS.WARN)
    end
end
```

## Repayment Schedule

### Phase 1 (Post-MVP)
- Implement proper state machine
- Add basic validation layer
- Improve error handling

### Phase 2 (First Update)
- Restore encounter variety
- Implement proper type system
- Add comprehensive testing

### Phase 3 (Major Update)
- Complete save system
- Add performance monitoring
- Implement replay system

## Emergency Fixes
Critical issues that need immediate attention:
1. Save corruption prevention
2. Basic state validation
3. Critical error handling

## Monitoring Checklist
Daily development checks:
1. Run debt detection commands
2. Review debug logs
3. Test critical paths
4. Update debt documentation