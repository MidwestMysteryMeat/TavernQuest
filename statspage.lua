-- Stats page: read-only view over the persistent save data.
-- Every value here is derived from PlayerData at draw time; nothing is cached.

local StatsPage = {}
local UI = require("ui")

-- Stat categories with their icons
local CATEGORIES = {
    {id = "general", name = "General Stats", icon = "📊"},
    {id = "crafting", name = "Crafting", icon = "⚒"},
    {id = "achievements", name = "Achievements", icon = "🏆"},
}

local state = {
    selectedCategory = "general",
    scroll = 0,
}

-- UI Components
local categoryTabs
local scrollContainer
local backButton

--- Create the persistent stat tables on first use / after a save migration.
local function ensureStats()
    PlayerData.gameStats = PlayerData.gameStats or {}

    if not PlayerData.gameStats.general then
        PlayerData.gameStats.general = {
            firstPlayed = os.time(),
            lastPlayed = os.time(),
        }
    end
end

local function countKeys(t)
    local n = 0
    for _ in pairs(t or {}) do n = n + 1 end
    return n
end

--- Total properties the player owns across towns, land claims and settlements.
local function countProperties()
    local props = PlayerData.properties or {}
    return countKeys(props.townProperties) + countKeys(props.landClaims) + countKeys(props.settlements)
end

-- Get formatted stat value
local function formatStat(value, type)
    if type == "number" then
        if value >= 1000000 then
            return string.format("%.1fM", value / 1000000)
        elseif value >= 1000 then
            return string.format("%.1fK", value / 1000)
        else
            return tostring(math.floor(value))
        end
    elseif type == "currency" then
        return string.format("%d coins", value)
    elseif type == "percent" then
        return string.format("%.1f%%", value * 100)
    elseif type == "time" then
        local hours = math.floor(value / 3600)
        local mins = math.floor((value % 3600) / 60)
        if hours > 0 then
            return string.format("%dh %dm", hours, mins)
        else
            return string.format("%dm", mins)
        end
    elseif type == "date" then
        return os.date("%Y-%m-%d", value)
    else
        return tostring(value)
    end
end

-- Forward declaration for getAchievements (defined below getStats)
local getAchievements

--- Rows to render for a category tab.
local function getStats(category)
    ensureStats()

    if category == "general" then
        return {
            {name = "Coins", value = PlayerData.coins or 0, type = "currency", color = {1, 0.9, 0.3}},
            {name = "Crystals", value = PlayerData.crystals or 0, type = "number", color = {0.6, 0.8, 1}},
            {name = "Properties Owned", value = countProperties(), type = "number"},
            {name = "Locations Discovered", value = countKeys(PlayerData.discoveredLocations), type = "number"},
            {name = "Races Unlocked", value = countKeys(PlayerData.unlockedRaces), type = "number"},
            {name = "Ascensions", value = PlayerData.ascensionCount or 0, type = "number", color = {0.8, 0.5, 0.9}},
            {name = "First Played", value = PlayerData.gameStats.general.firstPlayed, type = "date"},
            {name = "Last Played", value = PlayerData.gameStats.general.lastPlayed, type = "date"},
        }
    elseif category == "crafting" then
        local skills = PlayerData.craftingSkills or {}
        return {
            {name = "Items Crafted", value = #(PlayerData.craftedItems or {}), type = "number"},
            {name = "Forging XP", value = skills.forging or 0, type = "number", color = {0.9, 0.5, 0.3}},
            {name = "Wizardry XP", value = skills.wizardry or 0, type = "number", color = {0.5, 0.4, 0.9}},
            {name = "Alchemy XP", value = skills.alchemy or 0, type = "number", color = {0.3, 0.8, 0.5}},
        }
    elseif category == "achievements" then
        return getAchievements()
    end

    return {}
end

--- Achievement rows. `unlocked` is derived from live save data, never stored.
getAchievements = function()
    ensureStats()

    local skills = PlayerData.craftingSkills or {}
    local unlockedFlags = PlayerData.achievements or {}
    local properties = countProperties()

    return {
        {name = "Rich", desc = "Have 10,000 coins",
         unlocked = (PlayerData.coins or 0) >= 10000, icon = "💰"},
        {name = "Wealthy", desc = "Have 100,000 coins",
         unlocked = (PlayerData.coins or 0) >= 100000, icon = "💎"},
        {name = "Landowner", desc = "Own your first property",
         unlocked = properties >= 1, icon = "🏠"},
        {name = "Magnate", desc = "Own 10 properties",
         unlocked = properties >= 10, icon = "🏰"},
        {name = "Apprentice Smith", desc = "Reach 100 forging XP",
         unlocked = (skills.forging or 0) >= 100, icon = "⚒"},
        {name = "Arcane Scholar", desc = "Reach 100 wizardry XP",
         unlocked = (skills.wizardry or 0) >= 100, icon = "🔮"},
        {name = "Master Alchemist", desc = "Reach 100 alchemy XP",
         unlocked = (skills.alchemy or 0) >= 100, icon = "⚗"},
        {name = "Artisan", desc = "Craft 50 items",
         unlocked = #(PlayerData.craftedItems or {}) >= 50, icon = "🔨"},
        {name = "Cartographer", desc = "Discover 25 locations",
         unlocked = countKeys(PlayerData.discoveredLocations) >= 25, icon = "🗺"},
        {name = "Dragonslayer", desc = "Defeat a dragon",
         unlocked = unlockedFlags.defeat_dragon == true, icon = "🐉"},
        {name = "Ascendant", desc = "Ascend for the first time",
         unlocked = (PlayerData.ascensionCount or 0) >= 1, icon = "⭐"},
    }
end


function StatsPage.init()
    ensureStats()
    state.selectedCategory = "general"
    state.scroll = 0

    -- Update last played
    PlayerData.gameStats.general.lastPlayed = os.time()
    savePlayerData()

    -- Initialize UI components
    local screenW, screenH = love.graphics.getDimensions()

    -- Create category tabs
    local tabs = {}
    for _, cat in ipairs(CATEGORIES) do
        table.insert(tabs, {id = cat.id, label = cat.icon .. " " .. cat.name})
    end

    categoryTabs = UI.TabBar.new({
        x = 20,
        y = 80,
        w = 160,
        tabs = tabs,
        activeTab = state.selectedCategory,
        onChange = function(tabId)
            state.selectedCategory = tabId
            state.scroll = 0
        end
    })

    -- Create back button
    backButton = UI.Button.new({
        x = 20,
        y = screenH - 55,
        w = 100,
        h = 40,
        text = "Back",
        variant = "danger",
        onClick = function()
            local TextRPG = require("textrpg")
            TextRPG.init()
            GameState.current = "textrpg"
        end
    })
end

function StatsPage.update(dt)
    UI.anim.update(dt)
end

function StatsPage.draw()
    local screenW, screenH = love.graphics.getDimensions()
    local mx, my = love.mouse.getPosition()

    -- Background
    love.graphics.setColor(0.08, 0.08, 0.12)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Header
    love.graphics.setColor(0.12, 0.12, 0.18)
    love.graphics.rectangle("fill", 0, 0, screenW, 60)

    love.graphics.setColor(0.9, 0.7, 0.2)
    love.graphics.setFont(UI.fonts.get(28))
    love.graphics.print("STATISTICS", 20, 15)

    -- Draw category tabs
    categoryTabs.y = 80
    categoryTabs:draw(mx, my)

    -- Stats content area
    local contentX = 200
    local contentY = 80
    local contentW = screenW - contentX - 40
    local contentH = screenH - contentY - 70

    love.graphics.setColor(0.12, 0.12, 0.16)
    love.graphics.rectangle("fill", contentX, contentY, contentW, contentH, 10, 10)

    -- Get current category
    local currentCat = nil
    for _, cat in ipairs(CATEGORIES) do
        if cat.id == state.selectedCategory then
            currentCat = cat
            break
        end
    end

    if currentCat then
        -- Category title
        love.graphics.setColor(0.9, 0.7, 0.2)
        love.graphics.setFont(UI.fonts.get(22))
        love.graphics.print(currentCat.icon .. " " .. currentCat.name, contentX + 20, contentY + 15)

        -- Stats list
        local stats = getStats(state.selectedCategory)
        local statY = contentY + 60
        local statH = 45

        love.graphics.setScissor(contentX, contentY + 55, contentW, contentH - 65)

        if state.selectedCategory == "achievements" then
            -- Draw achievements grid
            local achW = 280
            local achH = 70
            local cols = math.floor((contentW - 40) / (achW + 15))
            if cols < 1 then cols = 1 end

            for i, ach in ipairs(stats) do
                local col = (i - 1) % cols
                local row = math.floor((i - 1) / cols)
                local achX = contentX + 20 + col * (achW + 15)
                local achY = statY + row * (achH + 10) - state.scroll

                if achY + achH >= contentY + 55 and achY <= contentY + contentH then
                    -- Background
                    if ach.unlocked then
                        love.graphics.setColor(0.2, 0.35, 0.25)
                    else
                        love.graphics.setColor(0.18, 0.18, 0.22)
                    end
                    love.graphics.rectangle("fill", achX, achY, achW, achH, 8, 8)

                    -- Border
                    if ach.unlocked then
                        love.graphics.setColor(0.3, 0.7, 0.4)
                    else
                        love.graphics.setColor(0.3, 0.3, 0.35)
                    end
                    love.graphics.rectangle("line", achX, achY, achW, achH, 8, 8)

                    -- Icon
                    love.graphics.setFont(UI.fonts.get(28))
                    love.graphics.setColor(1, 1, 1, ach.unlocked and 1 or 0.3)
                    love.graphics.print(ach.icon, achX + 12, achY + 18)

                    -- Name
                    love.graphics.setFont(UI.fonts.get(14))
                    love.graphics.setColor(1, 1, 1, ach.unlocked and 1 or 0.5)
                    love.graphics.print(ach.name, achX + 55, achY + 12)

                    -- Description
                    love.graphics.setFont(UI.fonts.get(11))
                    love.graphics.setColor(0.7, 0.7, 0.7, ach.unlocked and 1 or 0.4)
                    love.graphics.print(ach.desc, achX + 55, achY + 32)

                    -- Unlocked indicator
                    if ach.unlocked then
                        love.graphics.setColor(0.3, 0.8, 0.4)
                        love.graphics.setFont(UI.fonts.get(12))
                        love.graphics.print("✓", achX + achW - 25, achY + 25)
                    else
                        love.graphics.setColor(0.5, 0.5, 0.5)
                        love.graphics.setFont(UI.fonts.get(12))
                        love.graphics.print("🔒", achX + achW - 25, achY + 25)
                    end
                end
            end
        else
            -- Draw regular stats
            for i, stat in ipairs(stats) do
                local sy = statY + (i - 1) * statH - state.scroll

                if sy + statH >= contentY + 55 and sy <= contentY + contentH then
                    -- Alternating row background
                    if i % 2 == 0 then
                        love.graphics.setColor(0.1, 0.1, 0.14)
                        love.graphics.rectangle("fill", contentX + 15, sy, contentW - 30, statH - 5, 4, 4)
                    end

                    -- Stat name
                    love.graphics.setColor(0.8, 0.8, 0.85)
                    love.graphics.setFont(UI.fonts.get(15))
                    love.graphics.print(stat.name, contentX + 25, sy + 12)

                    -- Stat value
                    local valueStr = formatStat(stat.value, stat.type)
                    local valueColor = stat.color or {1, 1, 1}
                    love.graphics.setColor(valueColor)
                    love.graphics.setFont(UI.fonts.get(16))
                    love.graphics.printf(valueStr, contentX + 25, sy + 12, contentW - 60, "right")
                end
            end
        end

        love.graphics.setScissor()

        -- Scroll indicator
        local totalItems = #stats
        local visibleItems = math.floor((contentH - 65) / (state.selectedCategory == "achievements" and 80 or 45))
        if totalItems > visibleItems then
            local scrollBarH = math.max(30, (visibleItems / totalItems) * (contentH - 70))
            local maxScroll = (totalItems - visibleItems) * (state.selectedCategory == "achievements" and 80 or 45)
            local scrollBarY = contentY + 55 + (state.scroll / math.max(1, maxScroll)) * (contentH - 70 - scrollBarH)

            love.graphics.setColor(0.25, 0.25, 0.3)
            love.graphics.rectangle("fill", contentX + contentW - 15, contentY + 55, 8, contentH - 70, 4, 4)
            love.graphics.setColor(0.5, 0.6, 0.8)
            love.graphics.rectangle("fill", contentX + contentW - 15, scrollBarY, 8, scrollBarH, 4, 4)
        end
    end

    -- Back button
    backButton.y = screenH - 55
    backButton:draw()

    -- Achievement count
    local achievements = getAchievements()
    local unlockedCount = 0
    for _, ach in ipairs(achievements) do
        if ach.unlocked then unlockedCount = unlockedCount + 1 end
    end

    love.graphics.setColor(0.6, 0.6, 0.7)
    love.graphics.setFont(UI.fonts.get(12))
    love.graphics.printf(string.format("Achievements: %d/%d", unlockedCount, #achievements),
        screenW - 180, screenH - 40, 160, "right")
end

function StatsPage.mousepressed(x, y, button)
    if button ~= 1 then return end

    local screenW, screenH = love.graphics.getDimensions()

    -- Back button
    if backButton then
        if backButton:mousepressed(x, y, button) then return end
    end

    -- Category tabs
    if categoryTabs then
        categoryTabs:mousepressed(x, y, button)
    end
end

function StatsPage.mousereleased(x, y, button)
    if backButton then
        backButton:mousereleased(x, y, button)
    end
end

function StatsPage.wheelmoved(wx, wy)
    local stats = getStats(state.selectedCategory)
    local screenW, screenH = love.graphics.getDimensions()
    local contentH = screenH - 150

    local itemH = state.selectedCategory == "achievements" and 80 or 45
    local totalItems = #stats
    local visibleItems = math.floor(contentH / itemH)
    local maxScroll = math.max(0, (totalItems - visibleItems) * itemH)

    state.scroll = state.scroll - wy * 40
    state.scroll = math.max(0, math.min(state.scroll, maxScroll))
end

function StatsPage.keypressed(key)
    if key == "escape" then
        local TextRPG = require("textrpg")
        TextRPG.init()
        GameState.current = "textrpg"
    end
end

-- Helper function to update stats from other modules
function StatsPage.updateStat(category, stat, value, operation)
    ensureStats()

    if not PlayerData.gameStats[category] then return end
    if not PlayerData.gameStats[category][stat] then
        PlayerData.gameStats[category][stat] = 0
    end

    if operation == "add" then
        PlayerData.gameStats[category][stat] = PlayerData.gameStats[category][stat] + value
    elseif operation == "set" then
        PlayerData.gameStats[category][stat] = value
    elseif operation == "max" then
        PlayerData.gameStats[category][stat] = math.max(PlayerData.gameStats[category][stat], value)
    end

    savePlayerData()
end

return StatsPage
