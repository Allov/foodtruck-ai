local TestRunner = require('tests.init')

-- Load all test suites
require('tests.settings_test')
require('tests.deck_factory_test')
require('tests.cards.deckManager_test')
require('tests.scenes.provinceMap_test')
require('tests.scenes.battleEncounter_test')
require('tests.cards.combinationSystem_test')

return TestRunner



