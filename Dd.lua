============================================================
-- 📦 OMNI-FABLE DELTA LOGGING SYSTEM + GUI (FULL SCRIPT)
-- สำหรับ Delta Codex (Android Compatible)
-- รวมทุกส่วน: Config, SecurityModule, DiscordWebhook, DeltaLogger,
-- DeltaForensics, RemoteEventHandler, ClientRemoteEvent,
-- DeltaGUIServer, DeltaGUIClient (Pig GUI + Log Viewer + Stats)
-- ============================================================

-- ==========================================
-- ส่วนที่ 1: SERVICES & INITIALIZATION
-- ==========================================
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Clipboard Service (อาจไม่มีในบางอุปกรณ์)
local ClipboardService = nil
pcall(function()
    ClipboardService = game:GetService("ClipboardService")
end)

-- ==========================================
-- ส่วนที่ 2: CONFIG
-- ==========================================
local Config = {}
Config.System = { 
    Name = "OMNI-FABLE Delta Logger", 
    Version = "3.0", 
    Enabled = true, 
    DebugMode = true 
}
Config.DataStore = { 
    Name = "DeltaLogs", 
    AutoSave = true, 
    SaveInterval = 60 
}
Config.Discord = { 
    Enabled = true, 
    WebhookURL = "https://webhook.site/0ccd4647-cbc3-4e2c-985d-6d1ab58ca8ea", 
    Username = "Roblox Security Bot", 
    AvatarURL = "" 
}
Config.Severity = {
    LOW  = { MaxDelta = 10, Action = "LOG_ONLY", Color = 16763904 },
    MEDIUM = { MaxDelta = 50, Action = "LOG_AND_WARN", Color = 16744192 },
    HIGH  = { MaxDelta = 100, Action = "LOG_WARN_BLOCK", Color = 16711680 },
}
Config.RateLimit = { 
    Enabled = true, 
    MaxRequestsPerSecond = 10, 
    CooldownTime = 0.3 
}
Config.MonitoredEvents = { 
    "BuyItemEvent", 
    "SellItemEvent", 
    "TransferMoneyEvent", 
    "UseItemEvent", 
    "AttackEvent", 
    "CraftEvent", 
    "TradeEvent" 
}

-- ==========================================
-- ส่วนที่ 3: SECURITY MODULE
-- ==========================================
local SecurityModule = {}

local function validateSchema(args, schema)
    if #args ~= #schema then 
        return false 
    end
    for i, expectedType in ipairs(schema) do
        if type(args[i]) ~= expectedType then 
            return false 
        end
    end
    return true
end

local function checkRateLimit(player, eventName)
    if not Config.RateLimit.Enabled then 
        return true 
    end
    local key = "RateLimit_" .. eventName .. "_" .. tostring(player.UserId)
    local lastFire = player:GetAttribute(key) or 0
    local currentTime = tick()
    if currentTime - lastFire < Config.RateLimit.CooldownTime then 
        return false 
    end
    player:SetAttribute(key, currentTime)
    return true
end

local function validateOwnership(player, instance)
    if not instance then 
        return false 
    end
    if instance:IsDescendantOf(player.Character) then 
        return true 
    end
    if instance:IsDescendantOf(player.Backpack) then 
        return true 
    end
    return false
end

function SecurityModule.Validate(player, eventName, args, schema, options)
    options = options or {}
    
    if not checkRateLimit(player, eventName) then
        if Config.System.DebugMode then 
            warn("Security: Rate limit exceeded for " .. player.Name) 
        end
        return false, "RATE_LIMIT_EXCEEDED"
    end
    
    if not validateSchema(args, schema) then
        if Config.System.DebugMode then 
            warn("Security: Invalid schema from " .. player.Name .. " for " .. eventName) 
        end
        return false, "INVALID_SCHEMA"
    end
    
    if options.requireOwnership then
        local instance = args[options.ownershipIndex or 1]
        if not validateOwnership(player, instance) then 
            return false, "INVALID_OWNERSHIP" 
        end
    end
    
    return true, "OK"
end

-- ==========================================
-- ส่วนที่ 4: DISCORD WEBHOOK
-- ==========================================
local DiscordWebhook = {}
local SEVERITY_COLORS = { 
    LOW = Config.Severity.LOW.Color, 
    MEDIUM = Config.Severity.MEDIUM.Color, 
    HIGH = Config.Severity.HIGH.Color 
}

function DiscordWebhook.SendAlert(player, eventName, delta, severity)
    if not Config.Discord.Enabled then 
        return 
    end
    
    local payload = {
        username = Config.Discord.Username,
        avatar_url = Config.Discord.AvatarURL,
        embeds = {{
            title = "🚨 **DELTA ALERT**",
            description = "ตรวจพบความผิดปกติใน RemoteEvent",
            color = SEVERITY_COLORS[severity] or 16763904,
            fields = {
                { 
                    name = "👤 ผู้เล่น", 
                    value = player.Name .. " (ID: " .. player.UserId .. ")", 
                    inline = true 
                },
                { 
                    name = "📌 Event", 
                    value = eventName, 
                    inline = true 
                },
                { 
                    name = "📊 ระดับความรุนแรง", 
                    value = severity, 
                    inline = true 
                },
                { 
                    name = "📝 Delta", 
                    value = "```json\n" .. HttpService:JSONEncode(delta) .. "\n```", 
                    inline = false 
                },
                { 
                    name = "⏰ เวลา", 
                    value = os.date("%Y-%m-%d %H:%M:%S"), 
                    inline = false 
                }
            },
            footer = { 
                text = "OMNI-FABLE Security System v" .. Config.System.Version 
            }
        }}
    }
    
    local success, error = pcall(function()
        HttpService:PostAsync(
            Config.Discord.WebhookURL, 
            HttpService:JSONEncode(payload), 
            { ["Content-Type"] = "application/json" }
        )
    end)
    
    if not success and Config.System.DebugMode then 
        warn("DiscordWebhook: ส่งแจ้งเตือนล้มเหลว - " .. tostring(error)) 
    end
end

-- ==========================================
-- ส่วนที่ 5: DELTA LOGGER
-- ==========================================
local DeltaLogger = {}

local function hashValue(value)
    if type(value) == "table" then 
        return HttpService:JSONEncode(value) 
    else 
        return tostring(value) 
    end
end

local function computeDelta(sentValue, actualValue)
    -- Number comparison
    if type(sentValue) == "number" and type(actualValue) == "number" then 
        return sentValue - actualValue 
    end
    
    -- Table comparison
    if type(sentValue) == "table" and type(actualValue) == "table" then
        local delta = {}
        for key, value in pairs(sentValue) do
            if actualValue[key] ~= nil and actualValue[key] ~= value then
                delta[key] = { 
                    sent = value, 
                    actual = actualValue[key], 
                    difference = tostring(value) .. " != " .. tostring(actualValue[key]) 
                }
            end
        end
        if next(delta) then
            return delta
        end
        return nil
    end
    
    -- Value mismatch
    if sentValue ~= actualValue then 
        return { 
            sent = sentValue, 
            actual = actualValue, 
            difference = "MISMATCH" 
        } 
    end
    
    return nil
end

local function evaluateSeverity(delta)
    local maxDelta = 0
    for _, diff in pairs(delta) do
        if type(diff) == "number" and math.abs(diff) > maxDelta then 
            maxDelta = math.abs(diff)
        elseif type(diff) == "table" and diff.difference then 
            return "MEDIUM" 
        end
    end
    
    if maxDelta >= Config.Severity.HIGH.MaxDelta then 
        return "HIGH"
    elseif maxDelta >= Config.Severity.MEDIUM.MaxDelta then 
        return "MEDIUM"
    else 
        return "LOW" 
    end
end

function DeltaLogger.ProcessRemoteEvent(player, eventName, args, schema, actualDataGetter, options)
    options = options or {}
    
    -- Check if event is monitored
    if not table.find(Config.MonitoredEvents, eventName) then 
        return true, "OK" 
    end
    
    -- Validate security
    local isValid, result = SecurityModule.Validate(player, eventName, args, schema, options)
    if not isValid then 
        return false, result 
    end
    
    -- Get actual data from server
    local actualArgs = actualDataGetter(player)
    if not actualArgs then 
        return false, "NO_REFERENCE_DATA" 
    end
    
    -- Compute delta
    local delta = {}
    local hasDelta = false
    for i, arg in ipairs(args) do
        local actual = actualArgs[i]
        local diff = computeDelta(arg, actual)
        if diff then 
            delta[i] = diff
            hasDelta = true 
        end
    end
    
    -- Handle delta if found
    if hasDelta then
        local severity = evaluateSeverity(delta)
        local action = Config.Severity[severity].Action
        
        local logData = { 
            playerId = player.UserId, 
            playerName = player.Name, 
            eventName = eventName, 
            delta = delta, 
            rawArgs = args, 
            severity = severity, 
            action = action 
        }
        
        -- Send Discord alert
        if Config.Discord.Enabled then 
            DiscordWebhook.SendAlert(player, eventName, delta, severity) 
        end
        
        -- Debug output
        if Config.System.DebugMode then 
            print("DeltaLogger: พบ Delta จาก " .. player.Name, severity, HttpService:JSONEncode(delta)) 
        end
        
        -- Return based on severity
        if severity == "HIGH" then 
            return false, "DELTA_HIGH", delta
        elseif severity == "MEDIUM" then 
            warn("DeltaLogger: MEDIUM severity จาก " .. player.Name)
            return true, "DELTA_MEDIUM", delta
        else 
            return true, "DELTA_LOW", delta 
        end
    end
    
    return true, "OK"
end

-- ==========================================
-- ส่วนที่ 6: DELTA FORENSICS
-- ==========================================
local DeltaForensics = {}

local function sortTableByValue(tbl, limit)
    local sorted = {}
    for key, value in pairs(tbl) do 
        table.insert(sorted, {key = key, value = value}) 
    end
    table.sort(sorted, function(a, b) 
        return a.value > b.value 
    end)
    
    local result = {}
    for i = 1, math.min(limit or #sorted, #sorted) do 
        table.insert(result, sorted[i]) 
    end
    return result
end

function DeltaForensics.GetStatistics(logs)
    local stats = { 
        totalLogs = #logs, 
        severityCounts = { LOW = 0, MEDIUM = 0, HIGH = 0 }, 
        topPlayers = {}, 
        topEvents = {} 
    }
    
    for _, log in ipairs(logs) do
        if log.severity then 
            stats.severityCounts[log.severity] = (stats.severityCounts[log.severity] or 0) + 1 
        end
        if log.playerName then 
            stats.topPlayers[log.playerName] = (stats.topPlayers[log.playerName] or 0) + 1 
        end
        if log.eventName then 
            stats.topEvents[log.eventName] = (stats.topEvents[log.eventName] or 0) + 1 
        end
    end
    
    stats.topPlayers = sortTableByValue(stats.topPlayers, 5)
    stats.topEvents = sortTableByValue(stats.topEvents, 5)
    
    return stats
end

-- ==========================================
-- ส่วนที่ 7: GUI SYSTEM (ANDROID COMPATIBLE)
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "OmniFableDeltaGUI"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ========== COLOR THEME ==========
local colors = {
    background = Color3.fromRGB(25, 25, 35),
    surface = Color3.fromRGB(35, 35, 50),
    surfaceLight = Color3.fromRGB(50, 50, 70),
    accent = Color3.fromRGB(100, 150, 255),
    accentDark = Color3.fromRGB(70, 120, 220),
    text = Color3.fromRGB(255, 255, 255),
    textSecondary = Color3.fromRGB(180, 180, 200),
    success = Color3.fromRGB(50, 200, 100),
    warning = Color3.fromRGB(255, 200, 50),
    danger = Color3.fromRGB(255, 60, 60),
    pink = Color3.fromRGB(255, 150, 180),
    pinkDark = Color3.fromRGB(220, 100, 140),
    pinkLight = Color3.fromRGB(255, 200, 220),
    black = Color3.fromRGB(0, 0, 0)
}

-- ========== MAIN FRAME ==========
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 380, 0, 520)
mainFrame.Position = UDim2.new(0.5, -190, 0.5, -260)
mainFrame.BackgroundColor3 = colors.background
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = mainFrame

-- Shadow effect
local shadow = Instance.new("Frame")
shadow.Name = "Shadow"
shadow.Size = UDim2.new(1, 8, 1, 8)
shadow.Position = UDim2.new(0, -4, 0, -4)
shadow.BackgroundColor3 = colors.black
shadow.BackgroundTransparency = 0.5
shadow.ZIndex = -1
shadow.BorderSizePixel = 0
shadow.Parent = mainFrame
local shadowCorner = Instance.new("UICorner")
shadowCorner.CornerRadius = UDim.new(0, 16)
shadowCorner.Parent = shadow

-- ========== DRAG SYSTEM ==========
local guiDragging = false
local guiDragStart = nil
local guiFrameStart = nil

local dragHandle = Instance.new("Frame")
dragHandle.Name = "DragHandle"
dragHandle.Size = UDim2.new(1, 0, 0, 50)
dragHandle.Position = UDim2.new(0, 0, 0, 0)
dragHandle.BackgroundTransparency = 1
dragHandle.ZIndex = 10
dragHandle.Parent = mainFrame

dragHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
        guiDragging = true
        guiDragStart = input.Position
        guiFrameStart = mainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if guiDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                        input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - guiDragStart
        mainFrame.Position = UDim2.new(
            guiFrameStart.X.Scale, 
            guiFrameStart.X.Offset + delta.X, 
            guiFrameStart.Y.Scale, 
            guiFrameStart.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
        guiDragging = false
    end
end)

-- ========== HEADER ==========
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 50)
header.Position = UDim2.new(0, 0, 0, 0)
header.BackgroundColor3 = colors.surface
header.BorderSizePixel = 0
header.Parent = mainFrame
local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 16)
headerCorner.Parent = header

-- Fix bottom corners
local headerBottom = Instance.new("Frame")
headerBottom.Size = UDim2.new(1, 0, 0, 16)
headerBottom.Position = UDim2.new(0, 0, 1, -16)
headerBottom.BackgroundColor3 = colors.surface
headerBottom.BorderSizePixel = 0
headerBottom.Parent = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -50, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.Text = "🐷 OMNI-FABLE Delta Logger"
titleLabel.TextColor3 = colors.text
titleLabel.BackgroundTransparency = 1
titleLabel.TextSize = 16
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -40, 0, 9)
closeBtn.Text = "✕"
closeBtn.TextColor3 = colors.text
closeBtn.BackgroundColor3 = colors.danger
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.Parent = header
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 16)
closeCorner.Parent = closeBtn
closeBtn.MouseButton1Click:Connect(function() 
    screenGui:Destroy() 
end)

-- ========== TAB SYSTEM ==========
local tabContainer = Instance.new("Frame")
tabContainer.Name = "TabContainer"
tabContainer.Size = UDim2.new(1, 0, 0, 40)
tabContainer.Position = UDim2.new(0, 0, 0, 50)
tabContainer.BackgroundColor3 = colors.surface
tabContainer.BorderSizePixel = 0
tabContainer.Parent = mainFrame

local tabs = {}
local tabPages = {}
local tabButtons = {}

local tabData = {
    { name = "📋 Logs", icon = "📋" },
    { name = "📊 Stats", icon = "📊" },
    { name = "🐷 Pig", icon = "🐷" },
    { name = "⚙️ Config", icon = "⚙️" }
}

for i, data in ipairs(tabData) do
    local btn = Instance.new("TextButton")
    btn.Name = "Tab" .. i
    btn.Size = UDim2.new(0, 80, 1, -6)
    btn.Position = UDim2.new(0, 5 + (i-1) * 88, 0, 3)
    btn.Text = data.name
    btn.TextColor3 = colors.text
    btn.BackgroundColor3 = i == 1 and colors.accent or colors.surfaceLight
    btn.TextSize = 11
    btn.Font = Enum.Font.SourceSansBold
    btn.Parent = tabContainer
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn
    tabButtons[i] = btn
end

-- ========== CONTENT AREA ==========
local contentArea = Instance.new("Frame")
contentArea.Name = "ContentArea"
contentArea.Size = UDim2.new(1, -16, 1, -106)
contentArea.Position = UDim2.new(0, 8, 0, 98)
contentArea.BackgroundColor3 = colors.surface
contentArea.BorderSizePixel = 0
contentArea.Parent = mainFrame
local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, 12)
contentCorner.Parent = contentArea

-- ==========================================
-- PAGE 1: LOG VIEWER
-- ==========================================
local logPage = Instance.new("Frame")
logPage.Name = "LogPage"
logPage.Size = UDim2.new(1, 0, 1, 0)
logPage.BackgroundTransparency = 1
logPage.Visible = true
logPage.Parent = contentArea
tabPages[1] = logPage

local logScroll = Instance.new("ScrollingFrame")
logScroll.Name = "LogScroll"
logScroll.Size = UDim2.new(1, 0, 1, -40)
logScroll.Position = UDim2.new(0, 0, 0, 0)
logScroll.BackgroundTransparency = 1
logScroll.BorderSizePixel = 0
logScroll.ScrollBarThickness = 4
logScroll.ScrollBarImageColor3 = colors.accent
logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
logScroll.Parent = logPage

local logLayout = Instance.new("UIListLayout")
logLayout.Name = "LogLayout"
logLayout.SortOrder = Enum.SortOrder.LayoutOrder
logLayout.Padding = UDim.new(0, 4)
logLayout.Parent = logScroll

-- Clear button
local clearLogsBtn = Instance.new("TextButton")
clearLogsBtn.Name = "ClearLogsBtn"
clearLogsBtn.Size = UDim2.new(1, 0, 0, 32)
clearLogsBtn.Position = UDim2.new(0, 0, 1, -35)
clearLogsBtn.Text = "🗑️ Clear Logs"
clearLogsBtn.TextColor3 = colors.text
clearLogsBtn.BackgroundColor3 = colors.danger
clearLogsBtn.TextSize = 12
clearLogsBtn.Font = Enum.Font.SourceSansBold
clearLogsBtn.Parent = logPage
local clearCorner = Instance.new("UICorner")
clearCorner.CornerRadius = UDim.new(0, 8)
clearCorner.Parent = clearLogsBtn

-- ==========================================
-- PAGE 2: STATISTICS
-- ==========================================
local statsPage = Instance.new("Frame")
statsPage.Name = "StatsPage"
statsPage.Size = UDim2.new(1, 0, 1, 0)
statsPage.BackgroundTransparency = 1
statsPage.Visible = false
statsPage.Parent = contentArea
tabPages[2] = statsPage

local statsScroll = Instance.new("ScrollingFrame")
statsScroll.Name = "StatsScroll"
statsScroll.Size = UDim2.new(1, 0, 1, -40)
statsScroll.Position = UDim2.new(0, 0, 0, 0)
statsScroll.BackgroundTransparency = 1
statsScroll.BorderSizePixel = 0
statsScroll.ScrollBarThickness = 4
statsScroll.ScrollBarImageColor3 = colors.accent
statsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
statsScroll.Parent = statsPage

local statsLayout = Instance.new("UIListLayout")
statsLayout.Name = "StatsLayout"
statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
statsLayout.Padding = UDim.new(0, 6)
statsLayout.Parent = statsScroll

local refreshStatsBtn = Instance.new("TextButton")
refreshStatsBtn.Name = "RefreshStatsBtn"
refreshStatsBtn.Size = UDim2.new(1, 0, 0, 32)
refreshStatsBtn.Position = UDim2.new(0, 0, 1, -35)
refreshStatsBtn.Text = "🔄 Refresh Stats"
refreshStatsBtn.TextColor3 = colors.text
refreshStatsBtn.BackgroundColor3 = colors.accent
refreshStatsBtn.TextSize = 12
refreshStatsBtn.Font = Enum.Font.SourceSansBold
refreshStatsBtn.Parent = statsPage
local refreshCorner = Instance.new("UICorner")
refreshCorner.CornerRadius = UDim.new(0, 8)
refreshCorner.Parent = refreshStatsBtn

-- ==========================================
-- PAGE 3: PIG GUI
-- ==========================================
local pigPage = Instance.new("Frame")
pigPage.Name = "PigPage"
pigPage.Size = UDim2.new(1, 0, 1, 0)
pigPage.BackgroundTransparency = 1
pigPage.Visible = false
pigPage.Parent = contentArea
tabPages[3] = pigPage

-- Pig Face Frame
local pigFaceFrame = Instance.new("Frame")
pigFaceFrame.Name = "PigFace"
pigFaceFrame.Size = UDim2.new(0.85, 0, 0.35, 0)
pigFaceFrame.Position = UDim2.new(0.075, 0, 0.03, 0)
pigFaceFrame.BackgroundColor3 = colors.pink
pigFaceFrame.BackgroundTransparency = 0.1
pigFaceFrame.BorderSizePixel = 0
pigFaceFrame.Parent = pigPage
local pigFaceCorner = Instance.new("UICorner")
pigFaceCorner.CornerRadius = UDim.new(0, 25)
pigFaceCorner.Parent = pigFaceFrame

-- Pig Eyes
for i = 0, 1 do
    local eye = Instance.new("Frame")
    eye.Name = "Eye" .. i
    eye.Size = UDim2.new(0.08, 0, 0.18, 0)
    eye.Position = UDim2.new(0.18 + i * 0.68, 0, 0.2, 0)
    eye.BackgroundColor3 = Color3.fromRGB(180, 70, 90)
    eye.BorderSizePixel = 0
    eye.Parent = pigFaceFrame
    local eyeCorner = Instance.new("UICorner")
    eyeCorner.CornerRadius = UDim.new(0, 8)
    eyeCorner.Parent = eye
    
    -- Eye shine
    local eyeShine = Instance.new("Frame")
    eyeShine.Size = UDim2.new(0.3, 0, 0.3, 0)
    eyeShine.Position = UDim2.new(0.15, 0, 0.1, 0)
    eyeShine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    eyeShine.BackgroundTransparency = 0.5
    eyeShine.BorderSizePixel = 0
    eyeShine.Parent = eye
    local shineCorner = Instance.new("UICorner")
    shineCorner.CornerRadius = UDim.new(0, 4)
    shineCorner.Parent = eyeShine
end

-- Pig Nose
local pigNose = Instance.new("Frame")
pigNose.Name = "PigNose"
pigNose.Size = UDim2.new(0.3, 0, 0.3, 0)
pigNose.Position = UDim2.new(0.35, 0, 0.45, 0)
pigNose.BackgroundColor3 = colors.pinkDark
pigNose.BackgroundTransparency = 0.15
pigNose.BorderSizePixel = 0
pigNose.Parent = pigFaceFrame
local noseCorner = Instance.new("UICorner")
noseCorner.CornerRadius = UDim.new(0, 12)
noseCorner.Parent = pigNose

-- Nostrils
for i = 0, 1 do
    local nostril = Instance.new("Frame")
    nostril.Name = "Nostril" .. i
    nostril.Size = UDim2.new(0.12, 0, 0.22, 0)
    nostril.Position = UDim2.new(0.22 + i * 0.44, 0, 0.35, 0)
    nostril.BackgroundColor3 = Color3.fromRGB(200, 100, 120)
    nostril.BorderSizePixel = 0
    nostril.Parent = pigNose
    local nostrilCorner = Instance.new("UICorner")
    nostrilCorner.CornerRadius = UDim.new(0, 7)
    nostrilCorner.Parent = nostril
end

-- Pig Cheeks
for i = 0, 1 do
    local cheek = Instance.new("Frame")
    cheek.Name = "Cheek" .. i
    cheek.Size = UDim2.new(0.12, 0, 0.14, 0)
    cheek.Position = UDim2.new(0.03 + i * 0.85, 0, 0.65, 0)
    cheek.BackgroundColor3 = Color3.fromRGB(255, 130, 150)
    cheek.BackgroundTransparency = 0.35
    cheek.BorderSizePixel = 0
    cheek.Parent = pigFaceFrame
    local cheekCorner = Instance.new("UICorner")
    cheekCorner.CornerRadius = UDim.new(0, 10)
    cheekCorner.Parent = cheek
end

-- Pig Ears
for i = 0, 1 do
    local ear = Instance.new("Frame")
    ear.Name = "Ear" .. i
    ear.Size = UDim2.new(0.2, 0, 0.3, 0)
    ear.Position = UDim2.new(-0.08 + i * 1.0, 0, -0.15, 0)
    ear.BackgroundColor3 = colors.pinkDark
    ear.BackgroundTransparency = 0.1
    ear.BorderSizePixel = 0
    ear.Rotation = i == 0 and -20 or 20
    ear.Parent = pigFaceFrame
    local earCorner = Instance.new("UICorner")
    earCorner.CornerRadius = UDim.new(0, 15)
    earCorner.Parent = ear
    
    local earInner = Instance.new("Frame")
    earInner.Size = UDim2.new(0.6, 0, 0.7, 0)
    earInner.Position = UDim2.new(0.2, 0, 0.15, 0)
    earInner.BackgroundColor3 = Color3.fromRGB(255, 180, 200)
    earInner.BackgroundTransparency = 0.2
    earInner.BorderSizePixel = 0
    earInner.Parent = ear
    local earInnerCorner = Instance.new("UICorner")
    earInnerCorner.CornerRadius = UDim.new(0, 10)
    earInnerCorner.Parent = earInner
end

-- Pig Buttons
local pigSendBtn = Instance.new("TextButton")
pigSendBtn.Name = "PigSendBtn"
pigSendBtn.Size = UDim2.new(0.4, 0, 0.08, 0)
pigSendBtn.Position = UDim2.new(0.06, 0, 0.52, 0)
pigSendBtn.Text = "📤 ส่ง Log"
pigSendBtn.TextColor3 = colors.text
pigSendBtn.BackgroundColor3 = colors.success
pigSendBtn.TextSize = 14
pigSendBtn.Font = Enum.Font.SourceSansBold
pigSendBtn.Parent = pigPage
local pigSendCorner = Instance.new("UICorner")
pigSendCorner.CornerRadius = UDim.new(0, 10)
pigSendCorner.Parent = pigSendBtn

local pigCopyBtn = Instance.new("TextButton")
pigCopyBtn.Name = "PigCopyBtn"
pigCopyBtn.Size = UDim2.new(0.4, 0, 0.08, 0)
pigCopyBtn.Position = UDim2.new(0.54, 0, 0.52, 0)
pigCopyBtn.Text = "📋 คัดลอก"
pigCopyBtn.TextColor3 = colors.text
pigCopyBtn.BackgroundColor3 = colors.accent
pigCopyBtn.TextSize = 14
pigCopyBtn.Font = Enum.Font.SourceSansBold
pigCopyBtn.Parent = pigPage
local pigCopyCorner = Instance.new("UICorner")
pigCopyCorner.CornerRadius = UDim.new(0, 10)
pigCopyCorner.Parent = pigCopyBtn

local pigLogDisplay = Instance.new("Frame")
pigLogDisplay.Name = "PigLogDisplay"
pigLogDisplay.Size = UDim2.new(0.88, 0, 0.22, 0)
pigLogDisplay.Position = UDim2.new(0.06, 0, 0.64, 0)
pigLogDisplay.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
pigLogDisplay.BackgroundTransparency = 0.3
pigLogDisplay.BorderSizePixel = 0
pigLogDisplay.Parent = pigPage
local pigLogCorner = Instance.new("UICorner")
pigLogCorner.CornerRadius = UDim.new(0, 8)
pigLogCorner.Parent = pigLogDisplay

local pigLogText = Instance.new("TextLabel")
pigLogText.Name = "PigLogText"
pigLogText.Size = UDim2.new(1, -16, 1, -16)
pigLogText.Position = UDim2.new(0, 8, 0, 8)
pigLogText.Text = "🐷 พร้อมใช้งาน!\nกดปุ่มเพื่อส่งหรือคัดลอก Log"
pigLogText.TextColor3 = Color3.fromRGB(200, 200, 200)
pigLogText.BackgroundTransparency = 1
pigLogText.TextSize = 11
pigLogText.Font = Enum.Font.SourceSans
pigLogText.TextXAlignment = Enum.TextXAlignment.Left
pigLogText.TextWrapped = true
pigLogText.Parent = pigLogDisplay

-- ==========================================
-- PAGE 4: CONFIG
-- ==========================================
local configPage = Instance.new("Frame")
configPage.Name = "ConfigPage"
configPage.Size = UDim2.new(1, 0, 1, 0)
configPage.BackgroundTransparency = 1
configPage.Visible = false
configPage.Parent = contentArea
tabPages[4] = configPage

local configScroll = Instance.new("ScrollingFrame")
configScroll.Name = "ConfigScroll"
configScroll.Size = UDim2.new(1, 0, 1, 0)
configScroll.BackgroundTransparency = 1
configScroll.BorderSizePixel = 0
configScroll.ScrollBarThickness = 4
configScroll.ScrollBarImageColor3 = colors.accent
configScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
configScroll.Parent = configPage

local configLayout = Instance.new("UIListLayout")
configLayout.Name = "ConfigLayout"
configLayout.SortOrder = Enum.SortOrder.LayoutOrder
configLayout.Padding = UDim.new(0, 6)
configLayout.Parent = configScroll

-- Config items
local configItems = {
    { label = "🐷 System Name", value = Config.System.Name },
    { label = "📌 Version", value = Config.System.Version },
    { label = "🐞 Debug Mode", value = tostring(Config.System.DebugMode) },
    { label = "📡 Discord Enabled", value = tostring(Config.Discord.Enabled) },
    { label = "🔗 Webhook URL", value = Config.Discord.WebhookURL },
    { label = "📊 LOW Threshold", value = "< " .. Config.Severity.LOW.MaxDelta },
    { label = "📊 MEDIUM Threshold", value = "< " .. Config.Severity.MEDIUM.MaxDelta },
    { label = "📊 HIGH Threshold", value = "≥ " .. Config.Severity.HIGH.MaxDelta },
    { label = "⏱️ Rate Limit", value = tostring(Config.RateLimit.Enabled) },
    { label = "📋 Events", value = #Config.MonitoredEvents .. " events" }
}

for _, item in ipairs(configItems) do
    local configEntry = Instance.new("Frame")
    configEntry.Size = UDim2.new(1, -8, 0, 36)
    configEntry.BackgroundColor3 = colors.surfaceLight
    configEntry.Parent = configScroll
    local entryCorner = Instance.new("UICorner")
    entryCorner.CornerRadius = UDim.new(0, 8)
    entryCorner.Parent = configEntry
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.45, 0, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.Text = item.label
    label.TextColor3 = colors.text
    label.BackgroundTransparency = 1
    label.TextSize = 12
    label.Font = Enum.Font.SourceSansBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = configEntry
    
    local value = Instance.new("TextLabel")
    value.Size = UDim2.new(0.5, 0, 1, 0)
    value.Position = UDim2.new(0.48, 0, 0, 0)
    value.Text = item.value
    value.TextColor3 = colors.textSecondary
    value.BackgroundTransparency = 1
    value.TextSize = 11
    value.Font = Enum.Font.SourceSans
    value.TextXAlignment = Enum.TextXAlignment.Right
    value.TextWrapped = true
    value.Parent = configEntry
end

configScroll.CanvasSize = UDim2.new(0, 0, 0, configLayout.AbsoluteContentSize.Y + 10)

-- ==========================================
-- TAB SWITCHING
-- ==========================================
local function switchTab(index)
    for i, btn in ipairs(tabButtons) do
        btn.BackgroundColor3 = i == index and colors.accent or colors.surfaceLight
    end
    for i, page in ipairs(tabPages) do
        page.Visible = (i == index)
    end
end

for i, btn in ipairs(tabButtons) do
    btn.MouseButton1Click:Connect(function()
        switchTab(i)
    end)
end

-- ==========================================
-- LOG FUNCTIONS
-- ==========================================
local lastLogData = nil
local logHistory = {}

local function addLogToViewer(logData)
    local entry = Instance.new("Frame")
    entry.Name = "LogEntry"
    entry.Size = UDim2.new(1, -8, 0, 65)
    entry.BackgroundColor3 = colors.surfaceLight
    entry.Parent = logScroll
    local entryCorner = Instance.new("UICorner")
    entryCorner.CornerRadius = UDim.new(0, 8)
    entryCorner.Parent = entry
    
    -- Severity indicator
    local severityBar = Instance.new("Frame")
    severityBar.Size = UDim2.new(0, 4, 1, 0)
    severityBar.Position = UDim2.new(0, 0, 0, 0)
    severityBar.BackgroundColor3 = logData.severity == "HIGH" and colors.danger or 
                                   logData.severity == "MEDIUM" and colors.warning or 
                                   colors.success
    severityBar.BorderSizePixel = 0
    severityBar.Parent = entry
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 2)
    barCorner.Parent = severityBar
    
    -- Time
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Size = UDim2.new(0, 120, 0, 16)
    timeLabel.Position = UDim2.new(0, 12, 0, 4)
    timeLabel.Text = os.date("%H:%M:%S", logData.timestamp or os.time())
    timeLabel.TextColor3 = colors.textSecondary
    timeLabel.BackgroundTransparency = 1
    timeLabel.TextSize = 10
    timeLabel.Font = Enum.Font.SourceSans
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeLabel.Parent = entry
    
    -- Event name
    local eventLabel = Instance.new("TextLabel")
    eventLabel.Size = UDim2.new(0, 160, 0, 16)
    eventLabel.Position = UDim2.new(0, 135, 0, 4)
    eventLabel.Text = logData.eventName or logData.event or "Unknown"
    eventLabel.TextColor3 = colors.text
    eventLabel.BackgroundTransparency = 1
    eventLabel.TextSize = 11
    eventLabel.Font = Enum.Font.SourceSansBold
    eventLabel.TextXAlignment = Enum.TextXAlignment.Left
    eventLabel.Parent = entry
    
    -- Severity badge
    local severityBadge = Instance.new("TextLabel")
    severityBadge.Size = UDim2.new(0, 55, 0, 16)
    severityBadge.Position = UDim2.new(1, -60, 0, 4)
    severityBadge.Text = logData.severity or "LOW"
    severityBadge.TextColor3 = colors.text
    severityBadge.BackgroundColor3 = logData.severity == "HIGH" and colors.danger or 
                                     logData.severity == "MEDIUM" and colors.warning or 
                                     colors.success
    severityBadge.BackgroundTransparency = 0.3
    severityBadge.TextSize = 10
    severityBadge.Font = Enum.Font.SourceSansBold
    severityBadge.Parent = entry
    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(0, 4)
    badgeCorner.Parent = severityBadge
    
    -- Player
    local playerLabel = Instance.new("TextLabel")
    playerLabel.Size = UDim2.new(1, -24, 0, 16)
    playerLabel.Position = UDim2.new(0, 12, 0, 22)
    playerLabel.Text = "👤 " .. (logData.playerName or logData.player or "Unknown")
    playerLabel.TextColor3 = colors.textSecondary
    playerLabel.BackgroundTransparency = 1
    playerLabel.TextSize = 10
    playerLabel.Font = Enum.Font.SourceSans
    playerLabel.TextXAlignment = Enum.TextXAlignment.Left
    playerLabel.Parent = entry
    
    -- Delta info
    local deltaLabel = Instance.new("TextLabel")
    deltaLabel.Size = UDim2.new(1, -24, 0, 20)
    deltaLabel.Position = UDim2.new(0, 12, 0, 40)
    deltaLabel.Text = "Δ: " .. HttpService:JSONEncode(logData.delta or {})
    deltaLabel.TextColor3 = colors.textSecondary
    deltaLabel.BackgroundTransparency = 1
    deltaLabel.TextSize = 9
    deltaLabel.Font = Enum.Font.SourceSansMono
    deltaLabel.TextXAlignment = Enum.TextXAlignment.Left
    deltaLabel.TextWrapped = true
    deltaLabel.Parent = entry
    
    logScroll.CanvasSize = UDim2.new(0, 0, 0, logLayout.AbsoluteContentSize.Y + 10)
end

local function clearLogs()
    for _, child in ipairs(logScroll:GetChildren()) do
        if child:IsA("Frame") and child.Name == "LogEntry" then
            child:Destroy()
        end
    end
    logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    logHistory = {}
    pigLogText.Text = "🐷 พร้อมใช้งาน!\nกดปุ่มเพื่อส่งหรือคัดลอก Log"
end

clearLogsBtn.MouseButton1Click:Connect(clearLogs)

-- ==========================================
-- STATS FUNCTIONS
-- ==========================================
local function updateStatsDisplay()
    -- Clear existing stats
    for _, child in ipairs(statsScroll:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    
    local stats = DeltaForensics.GetStatistics(logHistory)
    
    -- Total logs
    local totalCard = Instance.new("Frame")
    totalCard.Size = UDim2.new(1, -8, 0, 50)
    totalCard.BackgroundColor3 = colors.accent
    totalCard.BackgroundTransparency = 0.5
    totalCard.Parent = statsScroll
    local totalCardCorner = Instance.new("UICorner")
    totalCardCorner.CornerRadius = UDim.new(0, 10)
    totalCardCorner.Parent = totalCard
    
    local totalLabel = Instance.new("TextLabel")
    totalLabel.Size = UDim2.new(1, 0, 1, 0)
    totalLabel.Text = "📊 Total Logs: " .. stats.totalLogs
    totalLabel.TextColor3 = colors.text
    totalLabel.BackgroundTransparency = 1
    totalLabel.TextSize = 18
    totalLabel.Font = Enum.Font.SourceSansBold
    totalLabel.Parent = totalCard
    
    -- Severity breakdown
    local severityTitle = Instance.new("TextLabel")
    severityTitle.Size = UDim2.new(1, 0, 0, 25)
    severityTitle.Text = "Severity Breakdown:"
    severityTitle.TextColor3 = colors.text
    severityTitle.BackgroundTransparency = 1
    severityTitle.TextSize = 13
    severityTitle.Font = Enum.Font.SourceSansBold
    severityTitle.TextXAlignment = Enum.TextXAlignment.Left
    severityTitle.Parent = statsScroll
    
    for severity, count in pairs(stats.severityCounts) do
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -8, 0, 32)
        bar.BackgroundColor3 = colors.surfaceLight
        bar.Parent = statsScroll
        local barCorner = Instance.new("UICorner")
        barCorner.CornerRadius = UDim.new(0, 6)
        barCorner.Parent = bar
        
        local fill = Instance.new("Frame")
        local percentage = stats.totalLogs > 0 and (count / stats.totalLogs) or 0
        fill.Size = UDim2.new(percentage, 0, 1, 0)
        fill.BackgroundColor3 = severity == "HIGH" and colors.danger or 
                                severity == "MEDIUM" and colors.warning or 
                                colors.success
        fill.BackgroundTransparency = 0.4
        fill.BorderSizePixel = 0
        fill.Parent = bar
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 6)
        fillCorner.Parent = fill
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.Text = "  " .. severity .. ": " .. count .. " (" .. math.floor(percentage * 100) .. "%)"
        label.TextColor3 = colors.text
        label.BackgroundTransparency = 1
        label.TextSize = 12
        label.Font = Enum.Font.SourceSansBold
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = bar
    end
    
    -- Top players
    if #stats.topPlayers > 0 then
        local topPlayersTitle = Instance.new("TextLabel")
        topPlayersTitle.Size = UDim2.new(1, 0, 0, 25)
        topPlayersTitle.Text = "🏆 Top Players:"
        topPlayersTitle.TextColor3 = colors.text
        topPlayersTitle.BackgroundTransparency = 1
        topPlayersTitle.TextSize = 13
        topPlayersTitle.Font = Enum.Font.SourceSansBold
        topPlayersTitle.TextXAlignment = Enum.TextXAlignment.Left
        topPlayersTitle.Parent = statsScroll
        
        for _, p in ipairs(stats.topPlayers) do
            local pEntry = Instance.new("TextLabel")
            pEntry.Size = UDim2.new(1, -8, 0, 22)
            pEntry.Text = "  " .. p.key .. ": " .. p.value .. " logs"
            pEntry.TextColor3 = colors.textSecondary
            pEntry.BackgroundColor3 = colors.surfaceLight
            pEntry.TextSize = 11
            pEntry.Font = Enum.Font.SourceSans
            pEntry.TextXAlignment = Enum.TextXAlignment.Left
            pEntry.Parent = statsScroll
            local pCorner = Instance.new("UICorner")
            pCorner.CornerRadius = UDim.new(0, 4)
            pCorner.Parent = pEntry
        end
    end
    
    -- Top events
    if #stats.topEvents > 0 then
        local topEventsTitle = Instance.new("TextLabel")
        topEventsTitle.Size = UDim2.new(1, 0, 0, 25)
        topEventsTitle.Text = "📌 Top Events:"
        topEventsTitle.TextColor3 = colors.text
        topEventsTitle.BackgroundTransparency = 1
        topEventsTitle.TextSize = 13
        topEventsTitle.Font = Enum.Font.SourceSansBold
        topEventsTitle.TextXAlignment = Enum.TextXAlignment.Left
        topEventsTitle.Parent = statsScroll
        
        for _, e in ipairs(stats.topEvents) do
            local eEntry = Instance.new("TextLabel")
            eEntry.Size = UDim2.new(1, -8, 0, 22)
            eEntry.Text = "  " .. e.key .. ": " .. e.value .. " times"
            eEntry.TextColor3 = colors.textSecondary
            eEntry.BackgroundColor3 = colors.surfaceLight
            eEntry.TextSize = 11
            eEntry.Font = Enum.Font.SourceSans
            eEntry.TextXAlignment = Enum.TextXAlignment.Left
            eEntry.Parent = statsScroll
            local eCorner = Instance.new("UICorner")
            eCorner.CornerRadius = UDim.new(0, 4)
            eCorner.Parent = eEntry
        end
    end
    
    statsScroll.CanvasSize = UDim2.new(0, 0, 0, statsLayout.AbsoluteContentSize.Y + 20)
end

refreshStatsBtn.MouseButton1Click:Connect(updateStatsDisplay)

-- ==========================================
-- CORE LOGIC
-- ==========================================
local function copyToClipboard(text)
    if ClipboardService then
        pcall(function() 
            ClipboardService:SetClipboard(text) 
        end)
        pigLogText.Text = "✅ คัดลอกไปยังคลิปบอร์ดแล้ว!"
    else
        pigLogText.Text = "📋 ข้อความ:\n" .. text
    end
    print("📋 [DeltaLogger] Copied: " .. string.sub(text, 1, 100) .. "...")
end

local function sendLog()
    local testDeltas = {
        { amount = 9999, expected = 100 },
        { amount = 50, expected = 30 },
        { amount = 5, expected = 2 }
    }
    local severities = {"HIGH", "MEDIUM", "LOW"}
    local events = {"BuyItemEvent", "SellItemEvent", "TransferMoneyEvent"}
    
    local randomIndex = math.random(1, 3)
    local testDelta = testDeltas[randomIndex]
    local severity = severities[randomIndex]
    local eventName = events[math.random(1, #events)]
    
    local logEntry = {
        player = player.Name,
        playerName = player.Name,
        playerId = player.UserId,
        event = eventName,
        eventName = eventName,
        delta = testDelta,
        severity = severity,
        timestamp = os.time(),
        time = os.date("%Y-%m-%d %H:%M:%S"),
        rawArgs = {"Item", testDelta.amount},
        action = Config.Severity[severity].Action
    }
    
    lastLogData = logEntry
    table.insert(logHistory, logEntry)
    
    -- Send to Discord webhook
    DiscordWebhook.SendAlert(player, eventName, testDelta, severity)
    
    -- Update pig display
    pigLogText.Text = "✅ ส่ง Log แล้ว!\n👤 " .. player.Name .. 
                      "\n📌 " .. eventName .. 
                      "\n📊 " .. severity .. 
                      "\n💰 Amount: " .. testDelta.amount .. 
                      " (Expected: " .. testDelta.expected .. ")"
    
    -- Add to log viewer
    addLogToViewer(logEntry)
    
    -- Update stats
    updateStatsDisplay()
    
    print("🐷 [DeltaLogger] Log sent - Event: " .. eventName .. " | Severity: " .. severity)
end

local function copyLastLog()
    if lastLogData then
        copyToClipboard(HttpService:JSONEncode(lastLogData))
    else
        pigLogText.Text = "⚠️ ยังไม่มี Log ให้คัดลอก"
    end
end

-- ==========================================
-- BUTTON CONNECTIONS
-- ==========================================
pigSendBtn.MouseButton1Click:Connect(sendLog)
pigCopyBtn.MouseButton1Click:Connect(copyLastLog)

-- ==========================================
-- KEYBOARD SHORTCUTS
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.G then
        sendLog()
    elseif input.KeyCode == Enum.KeyCode.C and lastLogData then
        copyLastLog()
    elseif input.KeyCode == Enum.KeyCode.L then
        switchTab(1) -- Logs tab
    elseif input.KeyCode == Enum.KeyCode.S then
        switchTab(2) -- Stats tab
    elseif input.KeyCode == Enum.KeyCode.P then
        switchTab(3) -- Pig tab
    end
end)

-- ==========================================
-- MOBILE FLOATING BUTTON (Android Quick Access)
-- ==========================================
local floatingBtn = Instance.new("TextButton")
floatingBtn.Name = "FloatingBtn"
floatingBtn.Size = UDim2.new(0, 50, 0, 50)
floatingBtn.Position = UDim2.new(1, -65, 1, -120)
floatingBtn.Text = "🐷"
floatingBtn.TextColor3 = colors.text
floatingBtn.BackgroundColor3 = colors.pink
floatingBtn.TextSize = 24
floatingBtn.Font = Enum.Font.SourceSansBold
floatingBtn.ZIndex = 100
floatingBtn.Parent = screenGui
local floatCorner = Instance.new("UICorner")
floatCorner.CornerRadius = UDim.new(1, 0)
floatCorner.Parent = floatingBtn

local floatShadow = Instance.new("Frame")
floatShadow.Size = UDim2.new(1, 4, 1, 4)
floatShadow.Position = UDim2.new(0, -2, 0, 2)
floatShadow.BackgroundColor3 = colors.black
floatShadow.BackgroundTransparency = 0.6
floatShadow.ZIndex = 99
floatShadow.BorderSizePixel = 0
floatShadow.Parent = floatingBtn
local floatShadowCorner = Instance.new("UICorner")
floatShadowCorner.CornerRadius = UDim.new(1, 0)
floatShadowCorner.Parent = floatShadow

local guiVisible = true
floatingBtn.MouseButton1Click:Connect(function()
    guiVisible = not guiVisible
    mainFrame.Visible = guiVisible
    floatingBtn.Text = guiVisible and "🐷" or "👁️"
end)

-- ==========================================
-- INITIALIZATION
-- ==========================================
-- Send initial log and update displays
sendLog()
switchTab(1)

-- ==========================================
-- FOOTER STATUS BAR
-- ==========================================
local statusBar = Instance.new("Frame")
statusBar.Name = "StatusBar"
statusBar.Size = UDim2.new(1, 0, 0, 16)
statusBar.Position = UDim2.new(0, 0, 1, -16)
statusBar.BackgroundColor3 = colors.surface
statusBar.BorderSizePixel = 0
statusBar.Parent = mainFrame

local statusText = Instance.new("TextLabel")
statusText.Name = "StatusText"
statusText.Size = UDim2.new(1, -16, 1, 0)
statusText.Position = UDim2.new(0, 8, 0, 0)
statusText.Text = "✅ Ready | " .. Config.System.Name .. " v" .. Config.System.Version
statusText.TextColor3 = colors.textSecondary
statusText.BackgroundTransparency = 1
statusText.TextSize = 9
statusText.Font = Enum.Font.SourceSans
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Parent = statusBar

-- ==========================================
-- PRINT LOADED MESSAGE
-- ==========================================
print([[
╔══════════════════════════════════════════════╗
║  🐷 OMNI-FABLE DELTA LOGGER v]] .. Config.System.Version .. [[          ║
║  📱 Android Compatible | Delta Codex Ready  ║
║                                              ║
║  📋 Tab 1: Log Viewer                       ║
║  📊 Tab 2: Statistics                       ║
║  🐷 Tab 3: Pig GUI (Send/Copy)              ║
║  ⚙️ Tab 4: Configuration                    ║
║                                              ║
║  ⌨️  Shortcuts:                              ║
║  G = Send Log                               ║
║  C = Copy Log                               ║
║  L = Logs Tab                               ║
║  S = Stats Tab                              ║
║  P = Pig Tab                                ║
║                                              ║
║  🐷 Floating button for quick access        ║
╚══════════════════════════════════════════════╝
]])

return {
    Config = Config,
    SecurityModule = SecurityModule,
    DiscordWebhook = DiscordWebhook,
    DeltaLogger = DeltaLogger,
    DeltaForensics = DeltaForensics
}
