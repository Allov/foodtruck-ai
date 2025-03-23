-- Simple test framework for LÖVE
local TestRunner = {
    tests = {},
    results = {
        passed = 0,
        failed = 0,
        total = 0
    }
}

function TestRunner:addTest(name, fn)
    table.insert(self.tests, {
        name = name,
        fn = fn
    })
end

function TestRunner:assert(condition, message)
    if not condition then
        error(message or "Assertion failed", 2)
    end
end

function TestRunner:assertEquals(received, expected, message)
    local errorMsg = message or "Values are not equal"
    if received ~= expected then
        errorMsg = string.format("%s\nExpected: %s\nReceived: %s",
            errorMsg,
            tostring(expected),
            tostring(received)
        )
        self:assert(false, errorMsg)
    end
end

function TestRunner:runAll()
    print("\n=== Running Tests ===\n")

    for _, test in ipairs(self.tests) do
        self.results.total = self.results.total + 1
        local success, error = pcall(function()
            test.fn(self)
        end)

        if success then
            print("✓ " .. test.name)
            self.results.passed = self.results.passed + 1
        else
            print("✗ " .. test.name)
            print("  Error: " .. error)
            self.results.failed = self.results.failed + 1
        end
    end

    local summary = string.format("\nResults: %d passed, %d failed, %d total",
        self.results.passed,
        self.results.failed,
        self.results.total
    )
    print(summary)

    return self.results.failed == 0
end

return TestRunner






