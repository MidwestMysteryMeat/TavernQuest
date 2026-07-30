-- Main menu: title screen, options overlay, and the bug-report dialog.
--
-- The menu owns no gameplay. Every entry either flips `GameState.current` to a
-- state registered in main.lua's `stateModules`, or opens an overlay that this
-- module draws on top of itself (Options, Knowledge Center, bug report).

local Menu = {}

local UI = require("ui")
local Options = require("options")
local UIAssets = require("uiassets")
local Theme = require("theme")

local colors = Theme.colors

-- Where "Report Bug" sends its payload.
local BUG_REPORT_EMAIL = "midwestmysterymeatstudios@gmail.com"
local BUG_REPORT_MAX_CHARS = 1000
local OFFLINE_EARNINGS_DISPLAY_TIME = 8 -- seconds the "welcome back" line stays up

-- Layout constants (main column is centred, secondary column hugs the right edge).
local MAIN_BUTTON_W, MAIN_BUTTON_H = 180, 45
local MAIN_START_Y, MAIN_SPACING = 510, 52
local SIDE_BUTTON_W, SIDE_BUTTON_H = 130, 38
local SIDE_START_Y, SIDE_SPACING = 200, 48

local buttons = {}
local backgroundImage = nil
local offlineEarningsTimer = 0

-- Bug report dialog state
local showBugReport = false
local bugReportText = ""
local bugReportStatus = ""
local bugReportStatusTimer = 0

local drawBugReportDialog
local submitBugReport

--- Switch to a top-level game state, initialising its module first.
local function enterState(name)
    local module = require(name)
    module.init()
    GameState.current = name
end

local function openBugReport()
    showBugReport = true
    bugReportText = ""
    bugReportStatus = ""
    bugReportStatusTimer = 0
end

local function closeBugReport()
    showBugReport = false
    bugReportText = ""
end

function Menu.init()
    UIAssets.init()

    backgroundImage = UIAssets.get("mainmenu_bg")
    if not backgroundImage and love.filesystem.getInfo("assets/mainmenu.png") then
        backgroundImage = love.graphics.newImage("assets/mainmenu.png")
    end

    Options.init()
    Menu.layout()
end

--- (Re)build the button list for the current window size.
-- Safe to call on every resize; buttons hold no state worth preserving.
function Menu.layout()
    local screenW, screenH = love.graphics.getDimensions()
    local centerX = screenW / 2 - MAIN_BUTTON_W / 2
    local sideX = screenW - SIDE_BUTTON_W - 30

    local function main(index, text, variant, onClick)
        return UI.Button.new({
            x = centerX,
            y = MAIN_START_Y + MAIN_SPACING * index,
            w = MAIN_BUTTON_W,
            h = MAIN_BUTTON_H,
            text = text,
            variant = variant,
            onClick = onClick,
        })
    end

    local function side(index, text, variant, onClick)
        return UI.Button.new({
            x = sideX,
            y = SIDE_START_Y + SIDE_SPACING * index,
            w = SIDE_BUTTON_W,
            h = SIDE_BUTTON_H,
            text = text,
            variant = variant,
            onClick = onClick,
        })
    end

    buttons = {
        main(0, "Tavern Quest", "primary", function() enterState("textrpg") end),
        main(1, "Quit", "danger", function()
            savePlayerData()
            love.event.quit()
        end),

        side(0, "Lore", "ghost", function() enterState("lore") end),
        side(1, "Options", "ghost", function() Options.openOptions() end),
        side(2, "Credits", "ghost", function() enterState("credits") end),

        UI.Button.new({
            x = 20,
            y = screenH - 70,
            w = 140,
            h = 40,
            text = "Report Bug",
            variant = "ghost",
            onClick = openBugReport,
        }),
    }
end

function Menu.update(dt)
    local muted = PlayerData.settings and PlayerData.settings.musicMuted
    if not muted and AudioSystem.currentTrack ~= "menu" then
        AudioSystem.playMenuMusic()
    end

    -- The "earned X while away" line is transient; retire it after a few seconds.
    if PlayerData.lastOfflineEarnings and PlayerData.lastOfflineEarnings > 0 then
        offlineEarningsTimer = offlineEarningsTimer + dt
        if offlineEarningsTimer >= OFFLINE_EARNINGS_DISPLAY_TIME then
            PlayerData.lastOfflineEarnings = nil
            offlineEarningsTimer = 0
        end
    else
        offlineEarningsTimer = 0
    end

    Options.update(dt)

    if bugReportStatusTimer > 0 then
        bugReportStatusTimer = bugReportStatusTimer - dt
        if bugReportStatusTimer <= 0 and bugReportStatus:find("opened") then
            closeBugReport()
        end
    end

    for _, btn in ipairs(buttons) do
        btn:update(dt)
    end
end

local function drawBackground(screenW, screenH)
    if not backgroundImage then return end

    local imgW, imgH = backgroundImage:getDimensions()
    local scale = math.max(screenW / imgW, screenH / imgH)
    love.graphics.setColor(1, 1, 1, 0.85)
    love.graphics.draw(backgroundImage, (screenW - imgW * scale) / 2,
        (screenH - imgH * scale) / 2, 0, scale, scale)

    -- Darken so the title and buttons stay legible over busy art.
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)
end

local function printCentered(text, screenW, y)
    local width = love.graphics.getFont():getWidth(text)
    love.graphics.print(text, screenW / 2 - width / 2, y)
end

function Menu.draw()
    local screenW, screenH = love.graphics.getDimensions()

    UIAssets.clearTooltip()
    drawBackground(screenW, screenH)

    love.graphics.setColor(colors.accent)
    love.graphics.setFont(UI.fonts.get(48))
    printCentered("TAVERN TIMES", screenW, 100)

    love.graphics.setFont(UI.fonts.get(16))
    local coinSize = 22
    local coinTextW = love.graphics.getFont():getWidth(tostring(PlayerData.coins))
    UIAssets.drawCurrencyWithTooltip("coins", PlayerData.coins,
        screenW / 2 - (coinSize + 6 + coinTextW) / 2, 198, coinSize)

    if PlayerData.passiveIncome and PlayerData.passiveIncome > 0 then
        love.graphics.setColor(0.3, 0.9, 0.4)
        love.graphics.setFont(UI.fonts.get(12))
        printCentered(string.format("+$%.2f/s passive income", PlayerData.passiveIncome), screenW, 218)
    end

    if PlayerData.lastOfflineEarnings and PlayerData.lastOfflineEarnings > 0 then
        love.graphics.setColor(1, 0.9, 0.3)
        love.graphics.setFont(UI.fonts.get(14))
        printCentered(string.format("Welcome back! Earned $%d while away!",
            PlayerData.lastOfflineEarnings), screenW, 235)
    end

    for _, btn in ipairs(buttons) do
        btn:draw()
    end

    love.graphics.setColor(colors.subtitle)
    love.graphics.setFont(UI.fonts.get(14))
    love.graphics.print("Press ESC to quit", 20, screenH - 30)

    if Options.isOpen() then
        Options.draw()
    end
    if showBugReport then
        drawBugReportDialog(screenW, screenH)
    end

    -- Tooltips render last so they sit above every overlay.
    UIAssets.drawTooltip()
end

-- Geometry of the bug-report dialog, shared by its draw and hit-test paths.
local function bugReportLayout(screenW, screenH)
    local w, h = 500, 380
    local x, y = screenW / 2 - w / 2, screenH / 2 - h / 2
    local btnW, btnH = 120, 40
    local btnY = y + h - 60
    return {
        x = x, y = y, w = w, h = h,
        inputX = x + 25, inputY = y + 75, inputW = w - 50, inputH = 180,
        btnW = btnW, btnH = btnH, btnY = btnY,
        cancelX = x + w / 2 - btnW - 20,
        submitX = x + w / 2 + 20,
    }
end

local function hit(x, y, bx, by, bw, bh)
    return x >= bx and x <= bx + bw and y >= by and y <= by + bh
end

submitBugReport = function()
    if #bugReportText == 0 then
        bugReportStatus = "Please enter a description!"
        bugReportStatusTimer = 2
        return false
    end

    local playerId = PlayerData.playerUID or "UNKNOWN"
    local body = table.concat({
        "Player ID: " .. playerId,
        "",
        "Description:",
        bugReportText,
        "",
        "State: " .. (GameState.current or "menu"),
        "Coins: " .. (PlayerData.coins or 0),
    }, "\n")

    local function urlEncode(str)
        return (str:gsub("[^%w%-%.%_%~]", function(c)
            return string.format("%%%02X", string.byte(c))
        end))
    end

    love.system.openURL(string.format("mailto:%s?subject=%s&body=%s",
        BUG_REPORT_EMAIL, urlEncode("Bug Report - " .. playerId), urlEncode(body)))

    -- Keep a local copy in case the mail client never opens.
    love.filesystem.write("bug_report_" .. os.time() .. ".txt", table.concat({
        "Bug Report",
        "==========",
        "",
        "Player ID: " .. playerId,
        "Timestamp: " .. os.date("%Y-%m-%d %H:%M:%S"),
        "",
        "Description:",
        bugReportText,
        "",
    }, "\n"))

    bugReportStatus = "Email client opened! Report saved locally."
    bugReportStatusTimer = 3
    return true
end

drawBugReportDialog = function(screenW, screenH)
    local mx, my = love.mouse.getPosition()
    local L = bugReportLayout(screenW, screenH)

    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    love.graphics.setColor(0.12, 0.12, 0.18)
    love.graphics.rectangle("fill", L.x, L.y, L.w, L.h, 12, 12)
    love.graphics.setColor(0.3, 0.5, 0.7)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", L.x, L.y, L.w, L.h, 12, 12)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(0.4, 0.7, 0.9)
    love.graphics.setFont(UI.fonts.get(22))
    love.graphics.printf("Bug Report", L.x, L.y + 15, L.w, "center")

    love.graphics.setColor(0.6, 0.6, 0.7)
    love.graphics.setFont(UI.fonts.get(12))
    love.graphics.printf("Describe the issue you encountered", L.x, L.y + 45, L.w, "center")

    love.graphics.setColor(0.08, 0.08, 0.12)
    love.graphics.rectangle("fill", L.inputX, L.inputY, L.inputW, L.inputH, 8, 8)
    love.graphics.setColor(0.3, 0.4, 0.5)
    love.graphics.rectangle("line", L.inputX, L.inputY, L.inputW, L.inputH, 8, 8)

    love.graphics.setFont(UI.fonts.get(14))
    local displayText = bugReportText
    if #displayText == 0 then
        love.graphics.setColor(0.4, 0.4, 0.5)
        displayText = "Type your bug description here..."
    else
        love.graphics.setColor(1, 1, 1)
    end

    local _, wrapped = love.graphics.getFont():getWrap(displayText, L.inputW - 20)
    local lineY = L.inputY + 10
    for _, line in ipairs(wrapped) do
        if lineY >= L.inputY + L.inputH - 20 then break end
        love.graphics.print(line, L.inputX + 10, lineY)
        lineY = lineY + 18
    end

    if math.floor(love.timer.getTime() * 2) % 2 == 0 then
        love.graphics.setColor(1, 1, 1)
        local lastLineWidth, lineCount = 0, 0
        if #bugReportText > 0 then
            local _, actual = love.graphics.getFont():getWrap(bugReportText, L.inputW - 20)
            lineCount = #actual
            if lineCount > 0 then
                lastLineWidth = love.graphics.getFont():getWidth(actual[lineCount])
            end
        end
        love.graphics.rectangle("fill", L.inputX + 10 + lastLineWidth,
            L.inputY + 10 + math.max(0, lineCount - 1) * 18, 2, 16)
    end

    local idY = L.inputY + L.inputH + 20
    love.graphics.setColor(0.5, 0.5, 0.6)
    love.graphics.setFont(UI.fonts.get(11))
    love.graphics.print("Your ID: " .. (PlayerData.playerUID or "UNKNOWN"), L.inputX, idY)

    if bugReportStatusTimer > 0 then
        love.graphics.setColor(bugReportStatus:find("Please") and {0.9, 0.5, 0.3} or {0.3, 0.8, 0.4})
        love.graphics.setFont(UI.fonts.get(13))
        love.graphics.printf(bugReportStatus, L.x, idY + 25, L.w, "center")
    end

    love.graphics.setFont(UI.fonts.get(16))
    local cancelHover = hit(mx, my, L.cancelX, L.btnY, L.btnW, L.btnH)
    love.graphics.setColor(cancelHover and {0.5, 0.3, 0.3} or {0.4, 0.25, 0.25})
    love.graphics.rectangle("fill", L.cancelX, L.btnY, L.btnW, L.btnH, 8, 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Cancel", L.cancelX, L.btnY + 10, L.btnW, "center")

    local submitHover = hit(mx, my, L.submitX, L.btnY, L.btnW, L.btnH)
    love.graphics.setColor(submitHover and {0.3, 0.6, 0.4} or {0.25, 0.5, 0.35})
    love.graphics.rectangle("fill", L.submitX, L.btnY, L.btnW, L.btnH, 8, 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Submit", L.submitX, L.btnY + 10, L.btnW, "center")
end

function Menu.mousepressed(x, y, button)
    if button ~= 1 then return end

    if showBugReport then
        local L = bugReportLayout(love.graphics.getDimensions())
        if hit(x, y, L.cancelX, L.btnY, L.btnW, L.btnH) then
            closeBugReport()
        elseif hit(x, y, L.submitX, L.btnY, L.btnW, L.btnH) and submitBugReport() then
            bugReportStatusTimer = 3
        end
        return
    end

    if Options.isOpen() then
        Options.mousepressed(x, y, button)
        return
    end

    for _, btn in ipairs(buttons) do
        if btn:mousepressed(x, y, button) then return end
    end
end

function Menu.mousereleased(x, y, button)
    for _, btn in ipairs(buttons) do
        btn:mousereleased(x, y, button)
    end
end

function Menu.wheelmoved(x, y)
    if Options.isOpen() then
        Options.wheelmoved(x, y)
    end
end

--- Returns true when the menu consumed the key (blocks the global handler).
function Menu.keypressed(key)
    if not showBugReport then return false end

    if key == "escape" then
        closeBugReport()
    elseif key == "backspace" then
        bugReportText = bugReportText:sub(1, -2)
    elseif key == "return" or key == "kpenter" then
        bugReportText = bugReportText .. "\n"
    end
    return true
end

--- Returns true when the menu consumed the text input.
function Menu.textinput(text)
    if not showBugReport then return false end

    if #bugReportText < BUG_REPORT_MAX_CHARS then
        bugReportText = bugReportText .. text
    end
    return true
end

return Menu
