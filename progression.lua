-- Player Progression System
-- Per-mode level/XP/rank that contributes to overall player level

local Progression = {}

-- Font cache for performance
local FontCache = require("fontcache")
local function getFont(size)
    return FontCache.get(size)
end

-- Mode definitions with display names
local MODES = {
    fishing = {name = "Fishing", icon = "🎣"},
    forge = {name = "Blacksmith", icon = "⚒️"},
    wizardtower = {name = "Wizard", icon = "🔮"},
    alchemist = {name = "Alchemist", icon = "⚗️"},
    hunting = {name = "Hunter", icon = "🏹"},
    game = {name = "Gambler", icon = "🃏"},
    slots = {name = "Slots", icon = "🎰"},
    petsim = {name = "Pet Tamer", icon = "🐾"},
    wage = {name = "Barista", icon = "☕"},
    market = {name = "Merchant", icon = "💰"},
}

-- Rank/Title definitions based on level (per mode)
local MODE_RANKS = {
    {level = 1, title = "Novice", color = {0.6, 0.6, 0.6}},
    {level = 3, title = "Beginner", color = {0.5, 0.7, 0.5}},
    {level = 5, title = "Apprentice", color = {0.5, 0.8, 0.5}},
    {level = 8, title = "Journeyman", color = {0.3, 0.7, 0.9}},
    {level = 12, title = "Adept", color = {0.5, 0.5, 0.9}},
    {level = 16, title = "Expert", color = {0.8, 0.5, 0.8}},
    {level = 20, title = "Master", color = {0.9, 0.7, 0.2}},
    {level = 25, title = "Grandmaster", color = {1, 0.5, 0.2}},
    {level = 30, title = "Legend", color = {1, 0.3, 0.3}},
}

-- Overall player ranks based on combined level
local OVERALL_RANKS = {
    {level = 1, title = "Newcomer", color = {0.6, 0.6, 0.6}},
    {level = 10, title = "Tavern Regular", color = {0.5, 0.8, 0.5}},
    {level = 25, title = "Tavern Veteran", color = {0.3, 0.7, 0.9}},
    {level = 50, title = "Tavern Champion", color = {0.5, 0.5, 0.9}},
    {level = 75, title = "Tavern Hero", color = {0.8, 0.5, 0.8}},
    {level = 100, title = "Tavern Legend", color = {0.9, 0.7, 0.2}},
    {level = 150, title = "Tavern Master", color = {1, 0.5, 0.2}},
    {level = 200, title = "Tavern Lord", color = {1, 0.85, 0.2}},
    {level = 300, title = "Tavern Immortal", color = {0.9, 0.2, 0.9}},
}

-- XP required for each level (exponential curve)
function Progression.getXPForLevel(level)
    return math.floor(100 * (level ^ 1.4))
end

-- Get rank from a rank table based on level
local function getRankFromTable(rankTable, level)
    local currentRank = rankTable[1]
    for _, rank in ipairs(rankTable) do
        if level >= rank.level then
            currentRank = rank
        else
            break
        end
    end
    return currentRank
end

-- Get next rank from a rank table
local function getNextRankFromTable(rankTable, level)
    for _, rank in ipairs(rankTable) do
        if level < rank.level then
            return rank
        end
    end
    return nil
end

-- Get mode rank based on level
function Progression.getModeRank(level)
    return getRankFromTable(MODE_RANKS, level)
end

-- Get overall rank based on combined level
function Progression.getOverallRank(level)
    return getRankFromTable(OVERALL_RANKS, level)
end

-- Get next mode rank
function Progression.getNextModeRank(level)
    return getNextRankFromTable(MODE_RANKS, level)
end

-- Get next overall rank
function Progression.getNextOverallRank(level)
    return getNextRankFromTable(OVERALL_RANKS, level)
end

-- Initialize progression data in PlayerData
function Progression.init()
    if not PlayerData then return end
    if not PlayerData.progression then
        PlayerData.progression = {
            modes = {},
            totalXP = 0,
        }
    end
    -- Ensure modes table exists
    if not PlayerData.progression.modes then
        PlayerData.progression.modes = {}
    end
end

-- Initialize a specific mode's progression
function Progression.initMode(modeId)
    Progression.init()
    if not PlayerData.progression.modes[modeId] then
        PlayerData.progression.modes[modeId] = {
            level = 1,
            xp = 0,
            totalXP = 0,
        }
    end
end

-- Add XP to a specific mode and handle level ups
function Progression.addXP(amount, modeId)
    modeId = modeId or "game"  -- Default to game mode for backwards compatibility
    Progression.initMode(modeId)

    local modeData = PlayerData.progression.modes[modeId]
    modeData.xp = modeData.xp + amount
    modeData.totalXP = modeData.totalXP + amount
    PlayerData.progression.totalXP = (PlayerData.progression.totalXP or 0) + amount

    local leveledUp = false
    local levelsGained = 0

    -- Check for level ups in this mode
    while modeData.xp >= Progression.getXPForLevel(modeData.level) do
        modeData.xp = modeData.xp - Progression.getXPForLevel(modeData.level)
        modeData.level = modeData.level + 1
        leveledUp = true
        levelsGained = levelsGained + 1
    end

    -- Reset HUD fade when XP is gained (make it visible again)
    Progression.resetHUDFade()

    if savePlayerData then savePlayerData() end

    return leveledUp, levelsGained
end

-- Get a mode's level
function Progression.getModeLevel(modeId)
    Progression.initMode(modeId)
    return PlayerData.progression.modes[modeId].level
end

-- Get a mode's XP
function Progression.getModeXP(modeId)
    Progression.initMode(modeId)
    return PlayerData.progression.modes[modeId].xp
end

-- Get a mode's XP progress as percentage
function Progression.getModeXPProgress(modeId)
    Progression.initMode(modeId)
    local modeData = PlayerData.progression.modes[modeId]
    local required = Progression.getXPForLevel(modeData.level)
    return modeData.xp / required
end

-- Calculate overall player level (sum of all mode levels)
function Progression.getOverallLevel()
    Progression.init()
    local totalLevel = 0
    for modeId, modeData in pairs(PlayerData.progression.modes or {}) do
        totalLevel = totalLevel + (modeData.level or 1)
    end
    -- Minimum level 1 if no modes played yet
    return math.max(1, totalLevel)
end

-- Legacy function for backwards compatibility
function Progression.getLevel()
    return Progression.getOverallLevel()
end

-- Legacy function for backwards compatibility
function Progression.getXP()
    Progression.init()
    return PlayerData.progression.totalXP or 0
end

-- Get mode info
function Progression.getModeInfo(modeId)
    return MODES[modeId]
end

-- HUD state for fade functionality
local hudState = {
    lastActivityTime = 0,
    fadeDelay = 3,  -- Seconds before fading
    minAlpha = 0.3,  -- 70% less visible = 30% opacity
    currentAlpha = 1,
}

-- Reset the fade timer (call this when XP is gained or HUD is interacted with)
function Progression.resetHUDFade()
    hudState.lastActivityTime = love.timer.getTime()
    hudState.currentAlpha = 1
end

-- Update HUD fade (call from main update loop)
function Progression.updateHUD(dt, mx, my, hudX, hudY, panelW, panelH)
    local now = love.timer.getTime()
    local elapsed = now - hudState.lastActivityTime

    -- Check if mouse is hovering over HUD area
    local isHovered = mx >= hudX and mx <= hudX + panelW and my >= hudY and my <= hudY + panelH + 50

    if isHovered then
        hudState.currentAlpha = 1
        hudState.lastActivityTime = now
    elseif elapsed > hudState.fadeDelay then
        -- Fade to minimum alpha
        hudState.currentAlpha = math.max(hudState.minAlpha, hudState.currentAlpha - dt * 0.5)
    else
        hudState.currentAlpha = 1
    end
end

-- Get current HUD alpha
function Progression.getHUDAlpha()
    return hudState.currentAlpha
end

-- Draw the progression HUD (right-side positioned with fade support)
function Progression.drawHUD(x, y, currentMode)
    Progression.init()

    local panelH = 55
    local panelW = 180
    local alpha = hudState.currentAlpha

    -- Get overall level info
    local overallLevel = Progression.getOverallLevel()
    local overallRank = Progression.getOverallRank(overallLevel)

    -- Background panel for overall level
    love.graphics.setColor(0.1, 0.1, 0.15, 0.9 * alpha)
    love.graphics.rectangle("fill", x, y, panelW, panelH, 8, 8)
    love.graphics.setColor(0.3, 0.3, 0.4, alpha)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, panelW, panelH, 8, 8)
    love.graphics.setLineWidth(1)

    -- Overall Rank/Title with color
    love.graphics.setColor(overallRank.color[1], overallRank.color[2], overallRank.color[3], alpha)
    love.graphics.setFont(getFont(14))
    love.graphics.print(overallRank.title, x + 10, y + 5)

    -- Overall Level
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.setFont(getFont(12))
    love.graphics.print("Lv. " .. overallLevel, x + 130, y + 5)

    -- Next overall rank preview
    local nextOverallRank = Progression.getNextOverallRank(overallLevel)
    if nextOverallRank then
        love.graphics.setColor(0.5, 0.5, 0.6, alpha)
        love.graphics.setFont(getFont(9))
        love.graphics.print("Next: " .. nextOverallRank.title .. " (Lv." .. nextOverallRank.level .. ")", x + 10, y + 25)
    else
        love.graphics.setColor(1, 0.85, 0.2, alpha)
        love.graphics.setFont(getFont(9))
        love.graphics.print("MAX RANK!", x + 10, y + 25)
    end

    -- If we have a valid mode, show mode-specific progress below
    if currentMode and MODES[currentMode] then
        Progression.initMode(currentMode)
        local modeData = PlayerData.progression.modes[currentMode]
        local modeInfo = MODES[currentMode]
        local modeRank = Progression.getModeRank(modeData.level)
        local required = Progression.getXPForLevel(modeData.level)
        local progress = modeData.xp / required

        local modeY = y + panelH + 5

        -- Mode panel
        love.graphics.setColor(0.1, 0.1, 0.15, 0.9 * alpha)
        love.graphics.rectangle("fill", x, modeY, panelW, 45, 8, 8)
        love.graphics.setColor(0.4, 0.5, 0.6, alpha)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", x, modeY, panelW, 45, 8, 8)
        love.graphics.setLineWidth(1)

        -- Mode name and rank
        love.graphics.setColor(modeRank.color[1], modeRank.color[2], modeRank.color[3], alpha)
        love.graphics.setFont(getFont(11))
        love.graphics.print(modeInfo.name .. " " .. modeRank.title, x + 10, modeY + 5)

        -- Mode level
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.setFont(getFont(11))
        love.graphics.print("Lv." .. modeData.level, x + 140, modeY + 5)

        -- XP bar
        local barX = x + 10
        local barY = modeY + 24
        local barW = 160
        local barH = 10

        love.graphics.setColor(0.2, 0.2, 0.25, alpha)
        love.graphics.rectangle("fill", barX, barY, barW, barH, 3, 3)

        love.graphics.setColor(0.4, 0.7, 0.4, alpha)
        love.graphics.rectangle("fill", barX, barY, barW * progress, barH, 3, 3)

        love.graphics.setColor(0.4, 0.4, 0.5, alpha)
        love.graphics.rectangle("line", barX, barY, barW, barH, 3, 3)

        -- XP text
        love.graphics.setColor(0.8, 0.8, 0.8, alpha)
        love.graphics.setFont(getFont(8))
        local xpText = string.format("%d / %d", modeData.xp, required)
        love.graphics.printf(xpText, barX, barY + 1, barW, "center")
    end
end

-- Draw HUD on right side of screen with automatic positioning
function Progression.drawHUDRight(currentMode, padding)
    padding = padding or 10
    local screenW = love.graphics.getWidth()
    local panelW = 180
    local x = screenW - panelW - padding
    local y = padding

    -- Update fade based on mouse position
    local mx, my = love.mouse.getPosition()
    Progression.updateHUD(love.timer.getDelta(), mx, my, x, y, panelW, 110)

    Progression.drawHUD(x, y, currentMode)
end

-- XP rewards for different activities
Progression.XP_REWARDS = {
    -- Fishing
    catch_fish = 15,
    catch_rare = 50,

    -- Hunting
    hunt_success = 20,
    hunt_rare = 75,

    -- Tavern service
    serve_customer = 5,
    complete_shift = 30,

    -- Crafting
    craft_item = 20,
    craft_rare = 50,
    craft_legendary = 100,

    -- General
    daily_login = 50,
}

return Progression
