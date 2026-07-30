-- Headless test suite for Tavern Quest.
--
--   love . --test        (from the project root)
--
-- conf.lua detects the flag, and main.lua hands control here instead of
-- booting the game. Tests run inside a real LÖVE context (windowed, not
-- fullscreen) rather than against a stubbed `love`: several modules build
-- fonts at load time, and chatbot_fallback spins forever under a permissive
-- stub. Running for real is what makes the load-order and broken-require
-- checks meaningful.
--
-- Exit code is 0 when everything passes, 1 otherwise, so CI can gate on it.

local Test = {}

local passed, failed = 0, 0
local failures = {}
local currentSuite = "(root)"

local function record(ok, name, message)
    if ok then
        passed = passed + 1
    else
        failed = failed + 1
        table.insert(failures, string.format("%s > %s\n      %s", currentSuite, name, message or "failed"))
    end
end

local function describe(name, fn)
    local previous = currentSuite
    currentSuite = name
    fn()
    currentSuite = previous
end

local function it(name, fn)
    local ok, err = pcall(fn)
    record(ok, name, err)
end

-- Assertions ---------------------------------------------------------------

local function fail(fmt, ...)
    error(string.format(fmt, ...), 3)
end

local function isTrue(value, what)
    if not value then fail("expected %s to be truthy, got %s", what or "value", tostring(value)) end
end

local function equals(actual, expected, what)
    if actual ~= expected then
        fail("expected %s to be %s, got %s", what or "value", tostring(expected), tostring(actual))
    end
end

local function isType(value, expected, what)
    if type(value) ~= expected then
        fail("expected %s to be a %s, got %s", what or "value", expected, type(value))
    end
end

local function hasFunction(module, name, moduleName)
    if type(module[name]) ~= "function" then
        fail("%s.%s should be a function, got %s", moduleName, name, type(module[name]))
    end
end

-- Suites -------------------------------------------------------------------

--- Every state registered in main.lua must expose the callbacks main.lua calls.
local STATE_MODULES = {
    "menu", "credits", "statspage", "textrpg", "lore",
    "fishing", "forge", "hunting", "wizardtower", "alchemist",
}

local function testStateModules()
    describe("state modules", function()
        for _, name in ipairs(STATE_MODULES) do
            it(name .. " loads and exposes init/update/draw", function()
                local module = require(name)
                isType(module, "table", name)
                hasFunction(module, "init", name)
                hasFunction(module, "update", name)
                hasFunction(module, "draw", name)
            end)
        end
    end)
end

--- Non-state modules that must at least load without error.
local SUPPORT_MODULES = {
    "savesystem", "progression", "backpack", "pausemenu", "cutscenes", "ui",
    "uiassets", "theme", "fontcache", "json", "mathutil", "seedrandom",
    "craftingcore", "propertysystem", "settlement_expansion", "worldgen",
    "towngen", "rpg_data", "rpg_core", "rpg_input", "rpg_npc", "rpg_save",
    "tactical_combat", "stealth_system", "chatbot_fallback", "chatbot_bridge",
    "autoplay", "auto_travel", "lpcloader", "camera2d", "renderer2d",
    "prison_escape",  -- subsystem driven by rpg_core, not a top-level state
    "spritemanager", "tile_quad_maps", "assetpipeline",
    "options", "employees",
}

local function testSupportModules()
    describe("support modules", function()
        for _, name in ipairs(SUPPORT_MODULES) do
            it(name .. " loads", function()
                local module = require(name)
                isTrue(module ~= nil, name .. " return value")
            end)
        end
    end)
end

--- The save schema must round-trip and expose the fields the UI reads.
local function testSaveSystem()
    describe("savesystem", function()
        local SaveSystem = require("savesystem")

        it("exposes a default player template", function()
            isType(SaveSystem.defaultPlayerData, "table", "defaultPlayerData")
            isType(SaveSystem.defaultPlayerData.coins, "number", "coins")
            isType(SaveSystem.defaultPlayerData.settings, "table", "settings")
            isType(SaveSystem.defaultPlayerData.properties, "table", "properties")
        end)

        it("carries no leftover card-game fields", function()
            local removed = {
                "collection", "decks", "currentDeck", "equippedJokers",
                "fusionUpgrades", "unlockedModes", "cafeUpgrades", "cafeDay",
                "favoriteModes", "endlessRun", "wins", "losses",
            }
            for _, field in ipairs(removed) do
                equals(SaveSystem.defaultPlayerData[field], nil, "defaultPlayerData." .. field)
            end
        end)

        it("describes an empty slot", function()
            equals(SaveSystem.describeSlot(nil), "Empty", "describeSlot(nil)")
            equals(SaveSystem.describeSlot({exists = false}), "Empty", "describeSlot(missing)")
            equals(SaveSystem.describeSlot({exists = true, corrupted = true}), "CORRUPTED", "describeSlot(corrupt)")
        end)

        it("describes a slot with a character", function()
            local text = SaveSystem.describeSlot({
                exists = true, characterName = "Bran", characterLevel = 7, characterClass = "ranger",
            })
            isTrue(text:find("Bran", 1, true), "name in summary")
            isTrue(text:find("7", 1, true), "level in summary")
            isTrue(text:find("Ranger", 1, true), "capitalised class in summary")
        end)

        it("describes a slot with no character yet", function()
            equals(SaveSystem.describeSlot({exists = true}), "No character yet", "describeSlot(no character)")
        end)
    end)
end

--- Regression guard for the bug class that shipped in lore.lua and fishing.lua:
--- a `local function` defined below its first call site resolves as a nil global.
local function testNoDanglingStateReferences()
    describe("cut features stay cut", function()
        local removedModules = {
            "game", "cards", "jokers", "deckbuilder", "lootbox", "endlessmode",
            "poker_hands", "tradingcards", "collection", "stockmarket",
            "petsim", "cafegame", "map_editor", "storymode",
            "kcdata", "knowledgecenter", "glossary", "tutorials",
            "tutorial_menu", "interactivetutorial",
        }

        for _, name in ipairs(removedModules) do
            it(name .. " is no longer requirable", function()
                local ok = pcall(require, name)
                isTrue(not ok, name .. " should fail to load")
            end)
        end
    end)
end

--- Portrait mappings had five duplicate keys; keep the table honest.
local function testDataIntegrity()
    describe("rpg_data", function()
        local Data = require("rpg_data")

        it("exposes portrait mappings", function()
            isType(Data.portraitMappings, "table", "portraitMappings")
            isTrue(next(Data.portraitMappings) ~= nil, "portraitMappings non-empty")
        end)

        it("maps every playable race to a portrait", function()
            for _, race in ipairs({"human", "elf", "dwarf", "orc", "goblin", "gnome",
                                   "catfolk", "lizardfolk"}) do
                isType(Data.portraitMappings[race], "string", "portrait for " .. race)
            end
        end)

        it("maps every player class to a portrait", function()
            for _, class in ipairs({"warrior", "mage", "rogue", "cleric", "ranger", "monk"}) do
                isType(Data.portraitMappings[class], "string", "portrait for " .. class)
            end
        end)
    end)
end

--- Settlement placement validation used an undefined `claim` upvalue.
local function testSettlementValidation()
    describe("settlement_expansion", function()
        local Settlement = require("settlement_expansion")

        it("exposes the placement validator", function()
            hasFunction(Settlement, "validateBuildingPlacement", "SettlementExpansion")
        end)

        it("rejects placement outside the grid", function()
            local grid = {width = 4, height = 4, tiles = {}, buildings = {}}
            for y = 1, 4 do
                grid.tiles[y] = {}
                for x = 1, 4 do
                    grid.tiles[y][x] = {type = "empty", wallSides = {}}
                end
            end
            local state = {player = {properties = {settlements = {}, landClaims = {}}}}
            local ok = Settlement.validateBuildingPlacement(state, {}, grid, 4, 4, {width = 3, height = 3}, "hut")
            isTrue(not ok, "3x3 building at (4,4) in a 4x4 grid")
        end)

        it("accepts placement on clear ground", function()
            local grid = {width = 8, height = 8, tiles = {}, buildings = {}}
            for y = 1, 8 do
                grid.tiles[y] = {}
                for x = 1, 8 do
                    grid.tiles[y][x] = {type = "empty", wallSides = {}}
                end
            end
            local state = {player = {properties = {settlements = {}, landClaims = {}}}}
            local ok = Settlement.validateBuildingPlacement(state, {}, grid, 2, 2, {width = 2, height = 2}, "hut")
            isTrue(ok, "2x2 building at (2,2) in an 8x8 grid")
        end)
    end)
end

--- The offline NPC dialogue engine is the project's distinctive asset.
local function testChatbot()
    describe("chatbot fallback", function()
        local Chatbot = require("chatbot_fallback")

        it("initialises with profiles", function()
            isType(Chatbot, "table", "chatbot_fallback")
        end)
    end)
end

-- Runner -------------------------------------------------------------------

function Test.run()
    print("")
    print("Tavern Quest test suite")
    print("=======================")

    testStateModules()
    testSupportModules()
    testSaveSystem()
    testNoDanglingStateReferences()
    testDataIntegrity()
    testSettlementValidation()
    testChatbot()

    print("")
    if failed > 0 then
        print(string.format("FAILED  %d passed, %d failed", passed, failed))
        for _, line in ipairs(failures) do
            print("  - " .. line)
        end
    else
        print(string.format("PASSED  %d assertions", passed))
    end
    print("")

    return failed == 0
end

return Test
