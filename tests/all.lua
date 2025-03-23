local TestRunner = require('tests.init')

-- Load all test suites
require('tests.settings_test')
require('tests.deck_factory_test')

-- Add new test suites here

return TestRunner