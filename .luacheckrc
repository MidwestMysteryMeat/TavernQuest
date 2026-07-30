-- Static analysis config for Tavern Quest.
--
--   luacheck .          -- must exit 0; run it before every commit
--
-- The intent is a *meaningful* gate, not a wall of noise. Anything that can
-- crash at runtime (undefined globals, bad fields, dead branches, shadowing
-- that changes behaviour) fails the build. Purely cosmetic warnings are muted
-- below, each with a reason.

std = "lua51+love"
cache = true
codes = true

exclude_files = {
    "chatbot/**",   -- Python, not Lua
    "assets/**",
    ".luacheckrc",
}

-- Globals the game deliberately shares between modules. All of these are
-- established during boot, before any state module runs.
globals = {
    "GameState",        -- current top-level state + player handle (main.lua)
    "PlayerData",       -- active save slot contents (main.lua)
    "AudioSystem",      -- music/SFX playback (main.lua)
    "FPSCounter",       -- F3 overlay (main.lua)
    "RENDER_MODE",      -- "sprite" | "classic", toggled with F4 (renderer2d.lua)
    "savePlayerData",
    "loadPlayerData",
    "changeState",
    "calculateOfflinePassiveIncome",
}

-- The text-RPG dependency-injection table.
--
-- textrpg.lua installs a metatable on _G whose __index falls back to its `F`
-- table (see textrpg.lua, "setmetatable(_G, ...)"). Sibling rpg_* modules
-- therefore call injected functions as if they were bare globals. Static
-- analysis cannot see through that indirection, so the names actually used
-- this way are listed here.
--
-- This is legacy architecture and a known wart: it turns every typo into a
-- silent runtime nil lookup. Prefer passing `F` explicitly in new code, and
-- shrink this list rather than grow it.
read_globals = {
    "F",
    "log",
    "addJournalEvent",
    "calculateStats",
    "endCombat",
    "exitDungeon",
    "gainXP",
    "getStatModifier",
    "getTQInventory",
    "movePlayer",
    "onEnemyDefeated",
    "playerAttack",
    "useSkill",
}

-- Not enforced (yet). These are style debt, not defects:
ignore = {
    "211",  -- unused local: ~140 hits, mostly partially-wired systems
    "212",  -- unused argument: ~150 hits, mostly interface-conformance stubs
    "213",  -- unused loop variable, idiomatic in `for _, v in ipairs(...)`
    "542",  -- empty if branch, used as explicit "do nothing" markers
    "421",  -- shadowing a local: common in this codebase's long draw functions
}

-- The codebase predates any line-length rule and has ~1900 long lines,
-- almost all of them wide data tables. Reflowing them mechanically risks
-- corrupting string literals for no functional gain.
max_line_length = false

files["main.lua"] = {
    -- main.lua is where the shared globals above are defined.
    allow_defined_top = true,
}

files["conf.lua"] = {
    globals = { "love" },
}
