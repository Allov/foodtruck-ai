local TestRunner = require('tests.init')
local ProvinceMap = require('src.scenes.provinceMap')

TestRunner:addTest("ProvinceMap - Basic initialization", function(t)
    gameState = { mapSeed = 1 }  -- Simple seed for basic structure test
    local map = ProvinceMap.new()
    t:assertEquals(map.NUM_LEVELS, 15, "Should have correct number of levels")
    t:assertEquals(map.currentLevel, 1, "Should start at level 1")
    t:assertEquals(map.selected, 1, "Should start with first node selected")
end)

TestRunner:addTest("ProvinceMap - Node distribution", function(t)
    gameState = { mapSeed = 42 }  -- Seed chosen to demonstrate node distribution
    local map = ProvinceMap.new()

    -- First row should always have 2 nodes
    t:assertEquals(#map.nodes[1], 2, "First row should have 2 nodes")
    -- Last row should always have 1 node (final boss)
    t:assertEquals(#map.nodes[map.NUM_LEVELS], 1, "Last row should have 1 node")

    -- Middle rows should have 2-4 nodes
    for i = 2, map.NUM_LEVELS - 1 do
        local nodeCount = #map.nodes[i]
        t:assert(nodeCount >= 2 and nodeCount <= 4,
            string.format("Row %d should have 2-4 nodes, got %d", i, nodeCount))
    end
end)

TestRunner:addTest("ProvinceMap - First row encounters", function(t)
    gameState = { mapSeed = 123 }  -- Seed chosen to test encounter distribution
    local map = ProvinceMap.new()

    for _, node in ipairs(map.nodes[1]) do
        t:assert(node.available, "First row nodes should be available")
        t:assert(node.type == "market" or node.type == "beneficial",
            "First row should only have market or beneficial encounters")
    end
end)

TestRunner:addTest("ProvinceMap - Second row encounters", function(t)
    gameState = { mapSeed = 456 }  -- Different seed for battle encounter testing
    local map = ProvinceMap.new()

    for _, node in ipairs(map.nodes[2]) do
        t:assertEquals(node.type, "card_battle", "Second row should be card battles")
        t:assert(node.encounterType == "food_critic" or node.encounterType == "rush_hour",
            "Second row should have correct battle types")
    end
end)

TestRunner:addTest("ProvinceMap - Final node", function(t)
    gameState = { mapSeed = 789 }  -- Specific seed for final node test
    local map = ProvinceMap.new()

    local finalNode = map.nodes[map.NUM_LEVELS][1]
    t:assertEquals(finalNode.type, "card_battle", "Final node should be a battle")
    t:assertEquals(finalNode.encounterType, "final_showdown", "Final node should be final showdown")
end)

TestRunner:addTest("ProvinceMap - Node completion", function(t)
    local map = ProvinceMap.new()

    -- Complete a node
    map:markNodeCompleted(1, 1)

    -- Check if node is marked as completed
    t:assert(map.completedNodes["1,1"], "Node should be marked as completed")
    t:assertEquals(map.currentLevel, 2, "Should advance to next level")
    t:assertEquals(map.selected, 1, "Should reset selection to 1")
end)

TestRunner:addTest("ProvinceMap - Encounter distribution", function(t)
    gameState = { mapSeed = 101112 }  -- Seed chosen for good encounter distribution
    local map = ProvinceMap.new()

    local encounterCounts = {
        card_battle = 0,
        market = 0,
        beneficial = 0,
        negative = 0,
        lore = 0
    }

    for _, row in ipairs(map.nodes) do
        for _, node in ipairs(row) do
            encounterCounts[node.type] = encounterCounts[node.type] + 1
        end
    end

    for encounterType, count in pairs(encounterCounts) do
        t:assert(count > 0,
            string.format("Should have at least one %s encounter, got %d", encounterType, count))
    end
end)

TestRunner:addTest("ProvinceMap - Map generation consistency", function(t)
    gameState = { mapSeed = 12345 }  -- Fixed seed for consistency check
    local map = ProvinceMap.new()

    -- This is the expected hash for seed 12345
    -- You'll need to run this once and capture the actual hash
    local expectedHash = 323836616197308416  -- Replace with actual hash

    local actualHash = map:generateStructureHash()
    t:assertEquals(actualHash, expectedHash,
        string.format("Map structure has changed. Expected hash %d, got %d",
            expectedHash, actualHash))
end)

return TestRunner



