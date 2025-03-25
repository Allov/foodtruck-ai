# Feature Removal Analysis

## Immediately Removable
1. CRT Shader Effect
   - Currently in Settings.lua as `crtEnabled`
   - Pure visual polish
   - No gameplay impact
   - Already toggleable

2. Market Complexity
   - Remove from ProvinceMap.getSpecificEncounter():
   - Simplify to single market type
   - Remove "specialty_shop" and "supply_store"
   - Keep only "farmers_market"

3. Multiple Battle Types
   - In ProvinceMap.getSpecificEncounter():
   - Remove "rush_hour"
   - Keep only "food_critic"
   - Simplify final showdown

4. Encounter Variety
   - From ProvinceMap.getRandomEncounterType():
   - Remove "lore" encounters
   - Remove "negative" encounters
   - Keep only: battles, markets, beneficial

## Simplify But Keep
1. Province Map
   - Reduce to linear progression
   - Simplify node connections
   - Keep basic navigation

2. Card System
   - Reduce card types
   - Simplify effects
   - Keep basic deck building

3. Chef System
   - Remove specialties
   - Keep basic stats
   - Minimal progression

## Must Keep (Core Loop)
1. Basic Map Navigation
   - Node selection
   - Progress tracking
   - Victory condition

2. Battle System
   - Both food_critic and rush_hour variants
   - Different strategic approaches:
     * Food Critic: Quality focus (3 rounds, high target)
     * Rush Hour: Speed focus (5 rounds, lower target)
   - Basic scoring
   - Win/loss states
   - Reward structure

3. Essential State Management
   - Game progress
   - Deck persistence
   - Basic settings

## Code Impact Examples
```lua
-- Remove from ProvinceMap
function ProvinceMap:getRandomEncounterType(row)
    -- Simplified version
    if row == self.NUM_LEVELS then
        return "card_battle"
    end
    return self.randomGenerator:random() < 0.5 and "market" or "card_battle"
end

-- Simplify encounter types
function ProvinceMap:getSpecificEncounter(encounterType)
    if encounterType == "card_battle" then
        return "food_critic"
    elseif encounterType == "market" then
        return "farmers_market"
    end
    return encounterType
end
```

## Impact Assessment
1. Code Reduction
   - Remove ~30% of ContentManager definitions
   - Simplify encounter logic
   - Remove special cases

2. Testing Reduction
   - Fewer edge cases
   - Simpler state management
   - Reduced content validation

3. UI Simplification
   - Remove non-essential feedback
   - Minimize tutorial needs
   - Focus on core interactions

## Migration Plan
1. Comment out removable features
2. Test core loop
3. Remove dead code
4. Update documentation
