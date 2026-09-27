-- =====================================================
-- FREEKICK AUTO — Full (PCT OFF/AUTO/8/10/13/15)
-- PCT OFF = all dynamic
-- PCT AUTO = lock contactY only
-- PCT 8/10/13/15 = lock power + contactY
-- =====================================================

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst   = game:GetService("ReplicatedFirst")
local LP = Players.LocalPlayer

local GOAL_CENTER = Vector3.new(188.1, 5.0, 0.0)

-- ★ PCT cycle — มี OFF
local PWR_CYCLE = {
    { label = "OFF",  value = nil, isOff = true },
    { label = "AUTO", value = nil },
    { label = "8%",   value = 0.08 },
    { label = "10%",  value = 0.10 },
    { label = "13%",  value = 0.13 },
    { label = "15%",  value = 0.15 },
}
local PCT_CONTACT_Y = -0.788

local CAP = {
    setclipboard      = type(setclipboard) == "function",
    toclipboard       = type(toclipboard) == "function",
    writefile         = type(writefile) == "function",
    makefolder        = type(makefolder) == "function",
    isfolder          = type(isfolder) == "function",
    hookmetamethod    = type(hookmetamethod) == "function",
    getnamecallmethod = type(getnamecallmethod) == "function",
}
local IS_TOUCH = UserInputService.TouchEnabled

local FreeKickRemote
do
    local fk = ReplicatedStorage:FindFirstChild("FootballFreekick")
    if fk then
        local r = fk:FindFirstChild("Remotes")
        if r then FreeKickRemote = r:FindFirstChild("FreeKickRemote") end
    end
end
if not FreeKickRemote then warn("[AUTO] no remote") return end

local WARMUP_TIME  = 1.0
local MAX_LOG      = 300
local MAX_COPY     = 20000
local MAX_LINE     = 4000
local MAX_DEPTH    = 4
local MAX_KEYS     = 40
local MAX_CELLS    = 400
local STR_CAP      = 80
local SAVE_DIR     = "spy_logs"
local FIRE_TIMEOUT = 10
local WAIT_TIMEOUT = 12
local COOLDOWN     = 5

local AutoState = {
    armed = false, learn = false,
    leg = "Right",
    aimYaw = 0.0, power = 0.55,
    contactX = -0.65, contactY = -0.55,
    precision = 0.50, contactDelay = 0.06,
    dynamicAim = true, autoSide = true, powerByDistance = true,
    pwrCycleIdx = 5,          -- ★ default = 13% (index 5)
    useOppPower = true, refMaxAge = 180, refMatchRange = 0.75,
    visualToBall = 2.0,
    lastFireTime = 0, lastParams = nil, shotState = "IDLE",
    fired = 0, accepted = 0, goals = 0, outs = 0, timeouts = 0,
}

local State = {
    ShotIndex = 0, CurrentShooter = nil, CurrentShooterName = "?",
    CurrentPayload = nil, KickData = nil, LastLabel = "-",
    MyShots = 0, TotalShots = 0, Goals = 0, Outs = 0,
    MatchId = nil, MatchPhase = "?", Round = 0, RoundLimit = nil,
    Shot = 0, ShotCount = nil, ScoreA = 0, ScoreB = 0,
    PlayerA = nil, PlayerB = nil, ShotOrder = {},
    SuddenDeath = false, SuddenDeathRound = 0, SuddenDeathRoundLimit = nil,
    OvertimeRound = 0, DecidingKick = false, Overtime = false,
    TimedOut = false, Deadline = nil, RegA = {}, RegB = {},
    ShooterUserId = nil, MyTurn = false,
    PresentationHolding = false, SkipStage = nil, SkipRequestedBy = nil,
    ReplayStarted = false, LastKickRootPos = nil,
    PlayerStats = {},
}

local LearnState = {
    buckets = {}, consecutiveMisses = 0, consecutiveGoals = 0,
}

local RefShots, PendingShots = {}, {}

do
    local seeds = {
        { d=22.636, p=0.684, uid=5245038569 },
        { d=20.341, p=0.553, uid=8889346895 },
        { d=18.765, p=0.545, uid=4684928145 },
        { d=22.100, p=0.550, uid=8889346895 },
        { d=22.471, p=0.550, uid=8889346895 },
        { d=22.122, p=0.550, uid=8889346895 },
    }
    for _, s in ipairs(seeds) do
        local b = math.floor(s.d * 2) / 2
        RefShots[b] = {
            power = s.p, mode = "InsideCurled",
            ballZ = 0, uid = s.uid, time = tick(),
        }
    end
end

local function learnKey()
    local kd = State.KickData
    if not kd or not kd.ballPosition or not kd.distanceMeters then
        return "unknown"
    end
    local bz = kd.ballPosition.Z
    local d = kd.distanceMeters
    local side = bz < -10 and "L" or (bz > 10 and "R" or "C")
    local dist = d < 20 and "N" or (d < 22 and "M" or "F")
    return side .. "|" .. dist
end

local function ensureBucket(key)
    if not LearnState.buckets[key] then
        LearnState.buckets[key] = {
            cY=AutoState.contactY, cX=AutoState.contactX,
            power=AutoState.power, yaw=AutoState.aimYaw,
            goals=0, misses=0, samples=0, weightDy=0, weightDz=0,
        }
    end
    return LearnState.buckets[key]
end

local allLogs, counters = {}, {}
local warmup, hookedCount = true, 0
local startTime, paused, filterText = tick(), false, ""

local function ts()
    local t = tick() - startTime
    return string.format("[%02d:%05.2f]", math.floor(t / 60), t % 60)
end

local function getPlayerName(uid)
    if not uid then return "?" end
    if uid == LP.UserId then return LP.Name .. " (me)" end
    local p = Players:GetPlayerByUserId(uid)
    return p and p.Name or ("uid:" .. tostring(uid))
end

local function refreshMyTurn()
    State.MyTurn = (State.MatchPhase == "Shoot"
        and State.ShooterUserId == LP.UserId)
end

local function regStr(arr)
    local s, n = "", 0
    for i = 1, 30 do
        local v = arr[i]
        if v == nil then break end
        n = i
        s = s .. (v and "✓" or "✗")
    end
    return n == 0 and "-" or s
end

local _cells
local function fmtVal(v, depth)
    _cells = _cells + 1
    if _cells > MAX_CELLS then return "…" end
    depth = depth or 0
    local t = typeof(v)
    if t == "string" then
        if #v > STR_CAP then v = v:sub(1, STR_CAP) .. "…" end
        return '"' .. v .. '"'
    elseif t == "number" then
        if v == math.floor(v) and math.abs(v) < 1e15 then return tostring(v) end
        return ("%.3f"):format(v)
    elseif t == "boolean" then return v and "T" or "F"
    elseif t == "nil" then return "nil"
    elseif t == "Instance" then return v.Name
    elseif t == "Vector3" then return ("V3(%.1f,%.1f,%.1f)"):format(v.X, v.Y, v.Z)
    elseif t == "CFrame" then
        local p = v.Position
        return ("CF(%.1f,%.1f,%.1f)"):format(p.X, p.Y, p.Z)
    elseif t == "Color3" then
        return ("C3(%d,%d,%d)"):format(
            math.floor(v.R*255), math.floor(v.G*255), math.floor(v.B*255))
    elseif t == "EnumItem" then return tostring(v)
    elseif t == "table" then
        if depth >= MAX_DEPTH then return "{…}" end
        local kv, count = {}, 0
        local ok = pcall(function()
            for k, val in pairs(v) do
                count = count + 1
                if count > MAX_KEYS or _cells > MAX_CELLS then
                    kv[#kv+1] = "…" break
                end
                local kstr = type(k) == "string" and k
                    or (type(k) == "number" and ("["..k.."]") or tostring(k))
                local okv, res = pcall(fmtVal, val, depth + 1)
                kv[#kv+1] = kstr .. "=" .. (okv and res or "<err>")
            end
        end)
        if not ok then return "{<err>}" end
        return "{" .. table.concat(kv, ",") .. "}"
    else
        local ok, res = pcall(tostring, v)
        return ok and res or "<" .. t .. ">"
    end
end

local function fmtArgs(argsSnap)
    local parts, types = {}, {}
    for i = 1, argsSnap.n do
        _cells = 0
        local okv, res = pcall(fmtVal, argsSnap[i], 0)
        parts[i] = okv and res or "<err>"
        types[i] = typeof(argsSnap[i]):sub(1, 3)
    end
    return table.concat(parts, ", "), table.concat(types, ",")
end

local function clip(s)
    if #s > MAX_LINE then return s:sub(1, MAX_LINE) .. "…" end
    return s
end

local function clampNum(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function findRefPower(dist)
    if not AutoState.useOppPower then return nil end
    local now = tick()
    local bestRef, bestDiff = nil, 999
    for key, ref in pairs(RefShots) do
        local diff = math.abs(key - dist)
        if diff < bestDiff and diff <= AutoState.refMatchRange
            and (now - ref.time) <= AutoState.refMaxAge then
            bestRef, bestDiff = ref, diff
        end
    end
    if bestRef then return bestRef.power, bestRef, bestDiff end
    return nil
end

local function computeAimYaw()
    local kd = State.KickData
    if not kd or not kd.ballPosition then return AutoState.aimYaw end
    local b = kd.ballPosition
    return math.atan2(GOAL_CENTER.Z - b.Z, GOAL_CENTER.X - b.X)
end

local function computePower()
    local kd = State.KickData
    if not kd or not kd.distanceMeters then return AutoState.power end
    local d = kd.distanceMeters
    if d <= 21.5 then
        return clampNum(0.55 + (d - 19.8) * 0.005, 0.30, 0.95)
    end
    local base = 0.55 + (21.5 - 19.8) * 0.005
    return clampNum(base + (d - 21.5) * 0.100, 0.30, 0.95)
end

local function computeContactX()
    local cx = AutoState.contactX
    if not AutoState.autoSide then return cx end
    local kd = State.KickData
    if not kd or not kd.ballPosition then return cx end
    local bz = kd.ballPosition.Z
    if bz > 2 and cx > 0 then return -cx end
    if bz < -2 and cx < 0 then return -cx end
    return cx
end

-- ============ GUI ============
local gui = Instance.new("ScreenGui")
gui.Name = "FK_Auto"
gui.ResetOnSpawn = false
gui.DisplayOrder = 2147483647
gui.IgnoreGuiInset = true
gui.Parent = LP:WaitForChild("PlayerGui")

local uiScale = Instance.new("UIScale")
uiScale.Parent = gui

local function fitScale()
    local vp = workspace.CurrentCamera.ViewportSize
    local s = 1.0
    if vp.X < 500 then s = 0.48
    elseif vp.X < 800 then s = 0.58
    elseif vp.X < 1200 then s = 0.75 end
    uiScale.Scale = s
end
fitScale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    pcall(fitScale)
end)

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 560, 0, 760)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(120, 200, 255)
stroke.Thickness = 1.5
stroke.Transparency = 0.4
stroke.Parent = frame

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Color3.fromRGB(22, 26, 34)
titleBar.BorderSizePixel = 0
titleBar.Active = true
titleBar.Parent = frame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -160, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "FREEKICK AUTO"
title.TextColor3 = Color3.fromRGB(120, 200, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 34, 0, 30)
closeBtn.Position = UDim2.new(1, -40, 0, 3)
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 25, 35)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 120, 150)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 34, 0, 30)
minBtn.Position = UDim2.new(1, -78, 0, 3)
minBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
minBtn.BorderSizePixel = 0
minBtn.Text = "–"
minBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.Parent = titleBar
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

local minimized = false
local fullSize = frame.Size
local fullPos  = frame.Position
local hideRefs = {}

minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        frame.Size = UDim2.new(0, 560, 0, 36)
        for _, c in ipairs(hideRefs) do c.Visible = false end
    else
        frame.Size = fullSize
        frame.Position = fullPos
        for _, c in ipairs(hideRefs) do c.Visible = true end
    end
end)

local dragging, dragStart, startPos = false, nil, nil
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = frame.Position
    end
end)
titleBar.InputChanged:Connect(function(input)
    if dragging then
        local d = input.Position - dragStart
        local s = uiScale.Scale
        if s <= 0 then s = 1 end
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X / s,
            startPos.Y.Scale, startPos.Y.Offset + d.Y / s)
    end
end)
titleBar.InputEnded:Connect(function() dragging = false end)

local statsFrame = Instance.new("Frame")
statsFrame.Size = UDim2.new(1, -12, 0, 84)
statsFrame.Position = UDim2.new(0, 6, 0, 42)
statsFrame.BackgroundColor3 = Color3.fromRGB(16, 22, 30)
statsFrame.BorderSizePixel = 0
statsFrame.Parent = frame
Instance.new("UICorner", statsFrame).CornerRadius = UDim.new(0, 6)
table.insert(hideRefs, statsFrame)

local statsLbl = Instance.new("TextLabel")
statsLbl.Size = UDim2.new(1, -12, 1, 0)
statsLbl.Position = UDim2.new(0, 6, 0, 0)
statsLbl.BackgroundTransparency = 1
statsLbl.Text = "  ready"
statsLbl.TextColor3 = Color3.fromRGB(200, 220, 240)
statsLbl.Font = Enum.Font.Code
statsLbl.TextSize = 10
statsLbl.TextXAlignment = Enum.TextXAlignment.Left
statsLbl.TextYAlignment = Enum.TextYAlignment.Top
statsLbl.RichText = true
statsLbl.Parent = statsFrame

local autoPanel = Instance.new("Frame")
autoPanel.Size = UDim2.new(1, -12, 0, 70)
autoPanel.Position = UDim2.new(0, 6, 0, 132)
autoPanel.BackgroundColor3 = Color3.fromRGB(24, 18, 36)
autoPanel.BorderSizePixel = 0
autoPanel.Parent = frame
Instance.new("UICorner", autoPanel).CornerRadius = UDim.new(0, 6)
table.insert(hideRefs, autoPanel)

local autoStroke = Instance.new("UIStroke")
autoStroke.Color = Color3.fromRGB(180, 120, 255)
autoStroke.Thickness = 1
autoStroke.Transparency = 0.4
autoStroke.Parent = autoPanel

local autoTitle = Instance.new("TextLabel")
autoTitle.Size = UDim2.new(1, -12, 0, 16)
autoTitle.Position = UDim2.new(0, 6, 0, 2)
autoTitle.BackgroundTransparency = 1
autoTitle.Text = "  AUTO"
autoTitle.TextColor3 = Color3.fromRGB(220, 180, 255)
autoTitle.Font = Enum.Font.GothamBold
autoTitle.TextSize = 10
autoTitle.TextXAlignment = Enum.TextXAlignment.Left
autoTitle.Parent = autoPanel

local function mkAutoBtn(x, w, text, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w, 0, 32)
    b.Position = UDim2.new(0, x, 0, 22)
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.fromRGB(230, 230, 240)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 10
    b.Parent = autoPanel
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local armBtn   = mkAutoBtn(6,   100, "ARM: OFF",   Color3.fromRGB(60, 30, 40))
local learnBtn = mkAutoBtn(112, 100, "LEARN: OFF", Color3.fromRGB(40, 40, 60))
local tuneBtn  = mkAutoBtn(218, 100, "TUNE",       Color3.fromRGB(40, 60, 80))
local sideBtn  = mkAutoBtn(324, 100, "SIDE: ON",   Color3.fromRGB(30, 80, 50))
local pwrBtn   = mkAutoBtn(430, 100, "PCT:13%",    Color3.fromRGB(90, 60, 30))

local autoStatLbl = Instance.new("TextLabel")
autoStatLbl.Size = UDim2.new(1, -12, 0, 14)
autoStatLbl.Position = UDim2.new(0, 6, 0, 56)
autoStatLbl.BackgroundTransparency = 1
autoStatLbl.Text = "  ready"
autoStatLbl.TextColor3 = Color3.fromRGB(180, 200, 220)
autoStatLbl.Font = Enum.Font.Code
autoStatLbl.TextSize = 10
autoStatLbl.TextXAlignment = Enum.TextXAlignment.Left
autoStatLbl.Parent = autoPanel

local curFrame = Instance.new("Frame")
curFrame.Size = UDim2.new(1, -12, 0, 96)
curFrame.Position = UDim2.new(0, 6, 0, 208)
curFrame.BackgroundColor3 = Color3.fromRGB(22, 16, 32)
curFrame.BorderSizePixel = 0
curFrame.Parent = frame
Instance.new("UICorner", curFrame).CornerRadius = UDim.new(0, 6)
table.insert(hideRefs, curFrame)

local curStroke = Instance.new("UIStroke")
curStroke.Color = Color3.fromRGB(160, 120, 255)
curStroke.Thickness = 1
curStroke.Transparency = 0.4
curStroke.Parent = curFrame

local curLbl = Instance.new("TextLabel")
curLbl.Size = UDim2.new(1, -12, 1, 0)
curLbl.Position = UDim2.new(0, 6, 0, 0)
curLbl.BackgroundTransparency = 1
curLbl.Text = "  CURRENT: (waiting)"
curLbl.TextColor3 = Color3.fromRGB(220, 200, 255)
curLbl.Font = Enum.Font.Code
curLbl.TextSize = 10
curLbl.TextXAlignment = Enum.TextXAlignment.Left
curLbl.TextYAlignment = Enum.TextYAlignment.Top
curLbl.RichText = true
curLbl.Parent = curFrame

local btnRow = Instance.new("Frame")
btnRow.Size = UDim2.new(1, -12, 0, 40)
btnRow.Position = UDim2.new(0, 6, 0, 310)
btnRow.BackgroundTransparency = 1
btnRow.Parent = frame
table.insert(hideRefs, btnRow)

local function mkBtn(x, w, text, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w, 1, 0)
    b.Position = UDim2.new(0, x, 0, 0)
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.fromRGB(230, 230, 240)
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 11
    b.Parent = btnRow
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local pauseBtn = mkBtn(0,   130, "PAUSE",  Color3.fromRGB(80, 60, 20))
local clearBtn = mkBtn(138, 120, "CLEAR",  Color3.fromRGB(60, 30, 35))
local copyBtn  = mkBtn(266, 130, "COPY",   Color3.fromRGB(30, 60, 40))
local saveBtn  = mkBtn(404, 120, "SAVE",   Color3.fromRGB(30, 45, 70))

if not CAP.writefile then
    saveBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    saveBtn.TextColor3 = Color3.fromRGB(120, 120, 130)
end

local filterRow = Instance.new("Frame")
filterRow.Size = UDim2.new(1, -12, 0, 28)
filterRow.Position = UDim2.new(0, 6, 0, 356)
filterRow.BackgroundTransparency = 1
filterRow.Parent = frame
table.insert(hideRefs, filterRow)

local fl = Instance.new("TextLabel")
fl.Size = UDim2.new(0, 60, 1, 0)
fl.BackgroundTransparency = 1
fl.Text = "  Filter:"
fl.TextColor3 = Color3.fromRGB(160, 180, 200)
fl.Font = Enum.Font.GothamMedium
fl.TextSize = 11
fl.TextXAlignment = Enum.TextXAlignment.Left
fl.Parent = filterRow

local filterBox = Instance.new("TextBox")
filterBox.Size = UDim2.new(1, -70, 1, 0)
filterBox.Position = UDim2.new(0, 62, 0, 0)
filterBox.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
filterBox.BorderSizePixel = 0
filterBox.Text = ""
filterBox.PlaceholderText = "(empty = all)"
filterBox.TextColor3 = Color3.fromRGB(200, 200, 210)
filterBox.Font = Enum.Font.Code
filterBox.TextSize = 11
filterBox.ClearTextOnFocus = false
filterBox.Parent = filterRow
Instance.new("UICorner", filterBox).CornerRadius = UDim.new(0, 4)

local histTitle = Instance.new("TextLabel")
histTitle.Size = UDim2.new(1, -12, 0, 16)
histTitle.Position = UDim2.new(0, 6, 0, 390)
histTitle.BackgroundTransparency = 1
histTitle.Text = "  HISTORY"
histTitle.TextColor3 = Color3.fromRGB(140, 180, 220)
histTitle.Font = Enum.Font.GothamBold
histTitle.TextSize = 10
histTitle.TextXAlignment = Enum.TextXAlignment.Left
histTitle.Parent = frame
table.insert(hideRefs, histTitle)

local histScroll = Instance.new("ScrollingFrame")
histScroll.Size = UDim2.new(1, -12, 0, 120)
histScroll.Position = UDim2.new(0, 6, 0, 408)
histScroll.BackgroundColor3 = Color3.fromRGB(6, 10, 14)
histScroll.BorderSizePixel = 0
histScroll.ScrollBarThickness = 6
histScroll.ScrollBarImageColor3 = Color3.fromRGB(120, 220, 255)
histScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
histScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
histScroll.Parent = frame
Instance.new("UICorner", histScroll).CornerRadius = UDim.new(0, 6)
table.insert(hideRefs, histScroll)

local histPad = Instance.new("UIPadding")
histPad.PaddingTop = UDim.new(0, 3)
histPad.PaddingBottom = UDim.new(0, 3)
histPad.PaddingLeft = UDim.new(0, 5)
histPad.PaddingRight = UDim.new(0, 5)
histPad.Parent = histScroll

local histLayout = Instance.new("UIListLayout")
histLayout.Padding = UDim.new(0, 2)
histLayout.Parent = histScroll

local logTitle = Instance.new("TextLabel")
logTitle.Size = UDim2.new(1, -12, 0, 16)
logTitle.Position = UDim2.new(0, 6, 0, 534)
logTitle.BackgroundTransparency = 1
logTitle.Text = "  RAW LOG"
logTitle.TextColor3 = Color3.fromRGB(140, 180, 220)
logTitle.Font = Enum.Font.GothamBold
logTitle.TextSize = 10
logTitle.TextXAlignment = Enum.TextXAlignment.Left
logTitle.Parent = frame
table.insert(hideRefs, logTitle)

local logScroll = Instance.new("ScrollingFrame")
logScroll.Size = UDim2.new(1, -12, 1, -562)
logScroll.Position = UDim2.new(0, 6, 0, 552)
logScroll.BackgroundColor3 = Color3.fromRGB(6, 10, 14)
logScroll.BorderSizePixel = 0
logScroll.ScrollBarThickness = 6
logScroll.ScrollBarImageColor3 = Color3.fromRGB(120, 220, 255)
logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
logScroll.Parent = frame
Instance.new("UICorner", logScroll).CornerRadius = UDim.new(0, 6)
table.insert(hideRefs, logScroll)

local logPad = Instance.new("UIPadding")
logPad.PaddingTop = UDim.new(0, 3)
logPad.PaddingBottom = UDim.new(0, 3)
logPad.PaddingLeft = UDim.new(0, 5)
logPad.PaddingRight = UDim.new(0, 5)
logPad.Parent = logScroll

local logLayout = Instance.new("UIListLayout")
logLayout.Padding = UDim.new(0, 1)
logLayout.Parent = logScroll

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 56, 0, 56)
toggleBtn.Position = UDim2.new(1, -76, 0.5, -28)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = "FK"
toggleBtn.TextColor3 = Color3.fromRGB(120, 200, 255)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 14
toggleBtn.Parent = gui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 28)

local togStroke = Instance.new("UIStroke")
togStroke.Color = Color3.fromRGB(120, 200, 255)
togStroke.Thickness = 1.5
togStroke.Transparency = 0.4
togStroke.Parent = toggleBtn

toggleBtn.MouseButton1Click:Connect(function()
    frame.Visible = not frame.Visible
end)

local COL = {
    IN=Color3.fromRGB(120,240,160), OUT=Color3.fromRGB(120,180,255),
    ERR=Color3.fromRGB(255,100,100), WARN=Color3.fromRGB(255,200,100),
    MISC=Color3.fromRGB(180,180,200), HDR=Color3.fromRGB(120,200,255),
    GOAL=Color3.fromRGB(120,255,120), MISS=Color3.fromRGB(255,100,100),
    AUTO=Color3.fromRGB(255,180,100), LEARN=Color3.fromRGB(255,220,100),
    REF=Color3.fromRGB(255,140,220),
}

local function addLog(text, color)
    if paused then return end
    text = clip(text)
    table.insert(allLogs, text)
    if #allLogs > MAX_LOG then table.remove(allLogs, 1) end
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 12)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or COL.MISC
    l.Font = Enum.Font.Code
    l.TextSize = 9
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextTruncate = Enum.TextTruncate.AtEnd
    l.Parent = logScroll
    local ch = logScroll:GetChildren()
    if #ch > MAX_LOG + 20 then
        for _, c in ipairs(ch) do
            if c:IsA("TextLabel") then c:Destroy() break end
        end
    end
    task.defer(function()
        pcall(function()
            logScroll.CanvasPosition = Vector2.new(0, logScroll.AbsoluteCanvasSize.Y)
        end)
    end)
end

local function addHistory(shot, result, label, shooterName, shooterUid, extra)
    local isMine = (shooterUid == LP.UserId)
    local color = result:find("GOAL") and COL.GOAL or COL.MISS
    local tag = isMine and "[ME]" or "[OTHER]"
    local line = ("%s #%d %s — %s\n    %s\n    %s")
        :format(tag, shot, result, label or "-", shooterName or "?", extra or "")
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 44)
    lbl.BackgroundTransparency = 1
    lbl.Text = line
    lbl.TextColor3 = color
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 9
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextYAlignment = Enum.TextYAlignment.Top
    lbl.TextWrapped = true
    lbl.Parent = histScroll
    task.defer(function()
        pcall(function()
            histScroll.CanvasPosition = Vector2.new(0, 0)
        end)
    end)
end

local function updateAutoStats()
    local rate = 0
    if AutoState.fired > 0 then
        rate = AutoState.goals / AutoState.fired * 100
    end
    local nB, nR = 0, 0
    for _ in pairs(LearnState.buckets) do nB = nB + 1 end
    for _ in pairs(RefShots) do nR = nR + 1 end
    local e = PWR_CYCLE[AutoState.pwrCycleIdx]
    autoStatLbl.Text = ("  fired %d | goal %d | %.0f%% | out %d | B:%d R:%d | PCT:%s")
        :format(AutoState.fired, AutoState.goals, rate, AutoState.outs,
                nB, nR, e.label)
end

local function updateStats()
    local acc = "0.0%"
    if State.MyShots > 0 then
        acc = ("%.1f%%"):format(State.Goals / State.MyShots * 100)
    end
    local topStr = ""
    do
        local list = {}
        for uid, s in pairs(State.PlayerStats) do
            table.insert(list, {uid=uid, shots=s.shots or 0, goals=s.goals or 0})
        end
        table.sort(list, function(a,b) return a.shots > b.shots end)
        for i = 1, math.min(3, #list) do
            local p = list[i]
            local n = getPlayerName(p.uid):gsub(" %(me%)", "")
            topStr = topStr .. ("  %s=%d/%d"):format(n:sub(1,10), p.goals, p.shots)
        end
    end
    local scoreStr = ("%d - %d"):format(State.ScoreA or 0, State.ScoreB or 0)
    if State.RoundLimit then
        scoreStr = scoreStr .. ("  R:%d/%d"):format(State.Round or 0, State.RoundLimit)
    end
    if State.SuddenDeath then
        scoreStr = scoreStr .. ("  SD:%d/%d")
            :format(State.SuddenDeathRound or 0, State.SuddenDeathRoundLimit or 0)
    end
    local turnStr
    if State.MyTurn then
        turnStr = "<font color='#78ff78'><b>YOUR TURN</b></font>"
    else
        local who = State.ShooterUserId and getPlayerName(State.ShooterUserId) or "?"
        turnStr = "<font color='#888'>wait</font> (" .. tostring(who):sub(1,14) .. ")"
    end
    if State.PresentationHolding then
        turnStr = turnStr .. "  <font color='#ffaa64'>HOLD</font>"
    end
    statsLbl.Text = ("  <b>MY:</b> %d  <b>GOAL:</b> <font color='#78ff78'>%d</font>  <b>OUT:</b> <font color='#ff6464'>%d</font>  <b>ACC:</b> %s  <b>SEEN:</b> %d\n  <b>SCORE:</b> %s  <b>PHASE:</b> %s  <b>SHOT:</b> %d/%s\n  <b>A:</b> %s  <b>B:</b> %s\n  <b>TURN:</b> %s\n  <b>TOP:</b>%s")
        :format(State.MyShots, State.Goals, State.Outs, acc, State.TotalShots,
                scoreStr, State.MatchPhase or "?", State.Shot or 0,
                tostring(State.ShotCount or "?"),
                regStr(State.RegA), regStr(State.RegB), turnStr, topStr)
end

local function updateCurrent()
    local tag = (State.CurrentShooter == LP.UserId) and "[ME]" or "[OTHER]"
    local L1 = ("  <b>%s SHOT — %s</b>"):format(tag, State.CurrentShooterName or "?")
    local L2 = "  (no payload)"
    if State.CurrentPayload then
        local p = State.CurrentPayload
        L2 = ("  leg=%s pwr=%s prec=%s"):format(
            tostring(p.leg), tostring(p.power), tostring(p.precision))
        if p.contactX ~= nil then
            L2 = L2 .. ("\n  cX=%s cY=%s cD=%s yaw=%s"):format(
                tostring(p.contactX), tostring(p.contactY),
                tostring(p.contactDelay), tostring(p.aimYaw))
        end
    end
    local L3 = "  (waiting kick)"
    if State.KickData then
        local k = State.KickData
        local key = learnKey()
        local b = LearnState.buckets[key]
        local e = PWR_CYCLE[AutoState.pwrCycleIdx]
        local lock = ""
        if not e.isOff then
            if e.value then
                lock = (" PCT=%s cY=%.3f"):format(e.label, PCT_CONTACT_Y)
            else
                lock = (" PCT=AUTO cY=%.3f"):format(PCT_CONTACT_Y)
            end
        end
        if b then
            L3 = ("  dist=%.2fm bkt=%s [cY=%.2f cX=%.2f pwr=%.2f %d/%d]%s")
                :format(k.distanceMeters or 0, key, b.cY, b.cX, b.power,
                        b.goals, b.goals + b.misses, lock)
        else
            L3 = ("  dist=%.2fm bkt=%s (no data)%s")
                :format(k.distanceMeters or 0, key, lock)
        end
    end
    curLbl.Text = L1 .. "\n" .. L2 .. "\n" .. L3
end

local function fireShot()
    if not FreeKickRemote then return end

    local key = learnKey()
    local b = LearnState.buckets[key]

    local useCY, useCX, usePower, useYawBase
    if b and AutoState.learn then
        useCY = b.cY; useCX = b.cX; usePower = b.power; useYawBase = b.yaw
    else
        useCY = AutoState.contactY; useCX = computeContactX()
        usePower = computePower(); useYawBase = AutoState.aimYaw
    end

    -- ★ PCT cycle
    local cycleEntry = PWR_CYCLE[AutoState.pwrCycleIdx]
    local pctOff = cycleEntry.isOff == true
    local pctActive = not pctOff
    local pctLocked = cycleEntry.value ~= nil

    if pctActive then
        useCY = PCT_CONTACT_Y           -- lock contactY
        if pctLocked then
            usePower = cycleEntry.value -- lock power
        end
    end

    -- ref override (ไม่ถ้า pctActive)
    local refUsed = false
    if not pctActive and AutoState.useOppPower and AutoState.learn then
        local kd = State.KickData
        if kd and kd.distanceMeters then
            local refPower, ref, diff = findRefPower(kd.distanceMeters)
            if refPower then
                usePower = refPower
                refUsed = true
                addLog(("[AUTO] USE REF dist=%.2fm pwr=%.3f (Δ%.2f)")
                    :format(kd.distanceMeters, refPower, diff), COL.REF)
            end
        end
    end

    local useYaw
    if AutoState.dynamicAim then useYaw = computeAimYaw() + useYawBase
    else useYaw = useYawBase end

    AutoState.lastParams = {
        leg = AutoState.leg, aimYaw = useYaw, power = usePower,
        contactX = useCX, contactY = useCY,
        precision = AutoState.precision, contactDelay = AutoState.contactDelay,
    }
    AutoState.lastFireTime = tick()
    AutoState.shotState = "FIRED"
    AutoState.fired = AutoState.fired + 1
    updateAutoStats()

    local dist = State.KickData and State.KickData.distanceMeters or 0
    local pctTag = ""
    if pctActive then
        pctTag = " [PCT:" .. cycleEntry.label .. "]"
    end
    addLog(("[AUTO] pwr=%.0f%% bkt=%s dist=%.2fm cY=%.2f cX=%.2f yaw=%.3f%s%s")
        :format(usePower * 100, key, dist, useCY, useCX, useYaw,
                refUsed and " [ref]" or "", pctTag), COL.AUTO)

    task.spawn(function()
        pcall(function() FreeKickRemote:FireServer("BeginShotVisual") end)
        task.wait(AutoState.visualToBall)
        pcall(function() FreeKickRemote:FireServer("PrepareBall") end)
        task.wait(0.15)
        pcall(function()
            FreeKickRemote:FireServer("Shoot", AutoState.lastParams)
        end)
        task.delay(FIRE_TIMEOUT, function()
            if AutoState.shotState == "FIRED" then
                AutoState.shotState = "IDLE"
                AutoState.timeouts = AutoState.timeouts + 1
                updateAutoStats()
                addLog("[AUTO] FIRED timeout → IDLE", COL.ERR)
            end
        end)
        task.delay(WAIT_TIMEOUT, function()
            if AutoState.shotState == "WAIT_RESULT" then
                AutoState.shotState = "IDLE"
                addLog("[AUTO] WAIT_RESULT timeout → IDLE", COL.ERR)
            end
        end)
    end)
end

local function applyLearn(outcome, payload)
    if not AutoState.learn then return end
    local key = learnKey()
    local b = ensureBucket(key)

    if outcome == "GOAL" then
        b.goals = b.goals + 1
        LearnState.consecutiveGoals = LearnState.consecutiveGoals + 1
        LearnState.consecutiveMisses = 0
        addLog(("[LEARN] %s GOAL %d/%d ✓"):format(key, b.goals, b.goals + b.misses), COL.GOAL)
        updateAutoStats()
        updateCurrent()
        return
    end

    b.misses = b.misses + 1
    b.samples = b.samples + 1
    LearnState.consecutiveGoals = 0
    LearnState.consecutiveMisses = LearnState.consecutiveMisses + 1

    local stepScale = 1.0 + math.min(LearnState.consecutiveMisses - 1, 4) * 0.6
    local prox = math.min(math.abs(b.weightDy) + math.abs(b.weightDz), 20) / 20
    stepScale = stepScale * (1.0 - prox * 0.4)

    if not payload or not payload.outPosition then
        b.cY = clampNum(b.cY + 0.03 * stepScale, -1, 1)
        updateAutoStats()
        updateCurrent()
        return
    end

    local op = payload.outPosition
    local dy = op.Y - GOAL_CENTER.Y
    local dz = op.Z - GOAL_CENTER.Z
    b.weightDy = b.weightDy * 0.6 + dy * 0.4
    b.weightDz = b.weightDz * 0.6 + dz * 0.4
    b.cY = clampNum(b.cY + dy * 0.008 * stepScale, -1, 1)
    b.cX = clampNum(b.cX - dz * 0.005 * stepScale, -1, 1)
    if math.abs(b.weightDz) > 5 then
        b.yaw = clampNum(b.yaw - b.weightDz * 0.003 * stepScale, -0.6, 0.6)
    end
    local kd = State.KickData
    if kd and kd.distanceMeters and kd.distanceMeters > 22 then
        b.power = clampNum(b.power + 0.005 * stepScale, 0.30, 0.95)
    end

    addLog(("[LEARN] %s miss#%d step=%.2f dy=%.1f dz=%.1f → cY=%.3f cX=%.3f yaw=%.3f pwr=%.3f")
        :format(key, b.samples, stepScale, dy, dz, b.cY, b.cX, b.yaw, b.power), COL.LEARN)
    updateAutoStats()
    updateCurrent()
end

-- TUNE PANEL
local tunePanel, tuneParams, tuneUpdate
do
    tunePanel = Instance.new("Frame")
    tunePanel.Size = UDim2.new(0, 340, 0, 470)
    tunePanel.Position = UDim2.new(0, 600, 0, 60)
    tunePanel.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
    tunePanel.BorderSizePixel = 0
    tunePanel.Visible = false
    tunePanel.ZIndex = 30
    tunePanel.Parent = gui
    Instance.new("UICorner", tunePanel).CornerRadius = UDim.new(0, 10)

    local tstroke = Instance.new("UIStroke")
    tstroke.Color = Color3.fromRGB(180, 120, 255)
    tstroke.Thickness = 1.5
    tstroke.Transparency = 0.3
    tstroke.Parent = tunePanel

    local tbar = Instance.new("Frame")
    tbar.Size = UDim2.new(1, 0, 0, 32)
    tbar.BackgroundColor3 = Color3.fromRGB(28, 22, 40)
    tbar.BorderSizePixel = 0
    tbar.Active = true
    tbar.ZIndex = 31
    tbar.Parent = tunePanel
    Instance.new("UICorner", tbar).CornerRadius = UDim.new(0, 10)

    local tlbl = Instance.new("TextLabel")
    tlbl.Size = UDim2.new(1, -60, 1, 0)
    tlbl.Position = UDim2.new(0, 10, 0, 0)
    tlbl.BackgroundTransparency = 1
    tlbl.Text = "TUNE PARAMS"
    tlbl.TextColor3 = Color3.fromRGB(220, 180, 255)
    tlbl.Font = Enum.Font.GothamBold
    tlbl.TextSize = 12
    tlbl.TextXAlignment = Enum.TextXAlignment.Left
    tlbl.ZIndex = 32
    tlbl.Parent = tbar

    local tclose = Instance.new("TextButton")
    tclose.Size = UDim2.new(0, 28, 0, 26)
    tclose.Position = UDim2.new(1, -34, 0, 3)
    tclose.BackgroundColor3 = Color3.fromRGB(60, 25, 35)
    tclose.BorderSizePixel = 0
    tclose.Text = "X"
    tclose.TextColor3 = Color3.fromRGB(255, 120, 150)
    tclose.Font = Enum.Font.GothamBold
    tclose.TextSize = 12
    tclose.ZIndex = 32
    tclose.Parent = tbar
    Instance.new("UICorner", tclose).CornerRadius = UDim.new(0, 6)
    tclose.MouseButton1Click:Connect(function() tunePanel.Visible = false end)

    local tdrag, tdS, tdP = false, nil, nil
    tbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            tdrag = true; tdS = input.Position; tdP = tunePanel.Position
        end
    end)
    tbar.InputChanged:Connect(function(input)
        if tdrag then
            local d = input.Position - tdS
            local s = uiScale.Scale
            if s <= 0 then s = 1 end
            tunePanel.Position = UDim2.new(
                tdP.X.Scale, tdP.X.Offset + d.X / s,
                tdP.Y.Scale, tdP.Y.Offset + d.Y / s)
        end
    end)
    tbar.InputEnded:Connect(function() tdrag = false end)

    tuneParams = {
        { name="power",        step=0.05, min=0,     max=1,    fmt="%.2f" },
        { name="contactY",     step=0.05, min=-1,    max=1,    fmt="%.2f" },
        { name="contactX",     step=0.05, min=-1,    max=1,    fmt="%.2f" },
        { name="precision",    step=0.05, min=0,     max=1,    fmt="%.2f" },
        { name="contactDelay", step=0.01, min=0,     max=1,    fmt="%.2f" },
        { name="aimYaw",       step=0.05, min=-3.14, max=3.14, fmt="%.2f" },
    }
    tuneUpdate = {}

    local rowY = 42
    for _, p in ipairs(tuneParams) do
        local r = Instance.new("Frame")
        r.Size = UDim2.new(1, -12, 0, 40)
        r.Position = UDim2.new(0, 6, 0, rowY)
        r.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
        r.BorderSizePixel = 0
        r.ZIndex = 31
        r.Parent = tunePanel
        Instance.new("UICorner", r).CornerRadius = UDim.new(0, 6)

        local nm = Instance.new("TextLabel")
        nm.Size = UDim2.new(0, 100, 1, 0)
        nm.Position = UDim2.new(0, 8, 0, 0)
        nm.BackgroundTransparency = 1
        nm.Text = p.name
        nm.TextColor3 = Color3.fromRGB(200, 220, 255)
        nm.Font = Enum.Font.GothamMedium
        nm.TextSize = 11
        nm.TextXAlignment = Enum.TextXAlignment.Left
        nm.ZIndex = 32
        nm.Parent = r

        local minus = Instance.new("TextButton")
        minus.Size = UDim2.new(0, 44, 0, 32)
        minus.Position = UDim2.new(0, 112, 0, 4)
        minus.BackgroundColor3 = Color3.fromRGB(50, 30, 40)
        minus.BorderSizePixel = 0
        minus.Text = "−"
        minus.TextColor3 = Color3.fromRGB(255, 180, 200)
        minus.Font = Enum.Font.GothamBold
        minus.TextSize = 18
        minus.ZIndex = 32
        minus.Parent = r
        Instance.new("UICorner", minus).CornerRadius = UDim.new(0, 6)

        local valBox = Instance.new("TextBox")
        valBox.Size = UDim2.new(0, 70, 0, 32)
        valBox.Position = UDim2.new(0, 160, 0, 4)
        valBox.BackgroundColor3 = Color3.fromRGB(8, 12, 18)
        valBox.BorderSizePixel = 0
        valBox.Text = string.format(p.fmt, AutoState[p.name])
        valBox.TextColor3 = Color3.fromRGB(120, 255, 200)
        valBox.Font = Enum.Font.Code
        valBox.TextSize = 12
        valBox.ClearTextOnFocus = false
        valBox.ZIndex = 32
        valBox.Parent = r
        Instance.new("UICorner", valBox).CornerRadius = UDim.new(0, 6)

        local plus = Instance.new("TextButton")
        plus.Size = UDim2.new(0, 44, 0, 32)
        plus.Position = UDim2.new(0, 234, 0, 4)
        plus.BackgroundColor3 = Color3.fromRGB(30, 50, 40)
        plus.BorderSizePixel = 0
        plus.Text = "+"
        plus.TextColor3 = Color3.fromRGB(180, 255, 200)
        plus.Font = Enum.Font.GothamBold
        plus.TextSize = 18
        plus.ZIndex = 32
        plus.Parent = r
        Instance.new("UICorner", plus).CornerRadius = UDim.new(0, 6)

        tuneUpdate[p.name] = function()
            valBox.Text = string.format(p.fmt, AutoState[p.name])
        end

        minus.MouseButton1Click:Connect(function()
            AutoState[p.name] = clampNum(AutoState[p.name] - p.step, p.min, p.max)
            tuneUpdate[p.name]()
        end)
        plus.MouseButton1Click:Connect(function()
            AutoState[p.name] = clampNum(AutoState[p.name] + p.step, p.min, p.max)
            tuneUpdate[p.name]()
        end)
        valBox.FocusLost:Connect(function()
            local n = tonumber(valBox.Text)
            if n then AutoState[p.name] = clampNum(n, p.min, p.max) end
            tuneUpdate[p.name]()
        end)

        rowY = rowY + 46
    end

    local presetLbl = Instance.new("TextLabel")
    presetLbl.Size = UDim2.new(1, -12, 0, 20)
    presetLbl.Position = UDim2.new(0, 6, 0, rowY + 4)
    presetLbl.BackgroundTransparency = 1
    presetLbl.Text = "  PRESETS"
    presetLbl.TextColor3 = Color3.fromRGB(180, 180, 200)
    presetLbl.Font = Enum.Font.GothamBold
    presetLbl.TextSize = 10
    presetLbl.TextXAlignment = Enum.TextXAlignment.Left
    presetLbl.ZIndex = 32
    presetLbl.Parent = tunePanel

    local function mkPreset(x, w, text, values)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, w, 0, 30)
        b.Position = UDim2.new(0, x, 0, rowY + 26)
        b.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
        b.BorderSizePixel = 0
        b.Text = text
        b.TextColor3 = Color3.fromRGB(220, 220, 255)
        b.Font = Enum.Font.GothamMedium
        b.TextSize = 10
        b.ZIndex = 32
        b.Parent = tunePanel
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        b.MouseButton1Click:Connect(function()
            for k, v in pairs(values) do AutoState[k] = v end
            for name, fn in pairs(tuneUpdate) do pcall(fn) end
        end)
        return b
    end

    mkPreset(6,   80, "S41",   {power=0.55, contactY=-0.55, contactX=-0.65,
        precision=0.50, contactDelay=0.06, aimYaw=0.00})
    mkPreset(92,  80, "LOW",   {power=0.55, contactY=-0.30, contactX=-0.65,
        precision=0.50, contactDelay=0.06, aimYaw=0.00})
    mkPreset(178, 80, "MID",   {power=0.58, contactY=-0.55, contactX=-0.60,
        precision=0.50, contactDelay=0.06, aimYaw=0.00})
    mkPreset(264, 70, "18.7m", {power=0.545, contactY=-0.55, contactX=-0.65,
        precision=0.50, contactDelay=0.06, aimYaw=0.00})
end

-- HOOK OUTGOING
if CAP.hookmetamethod and CAP.getnamecallmethod then
    local ok, err = pcall(function()
        local oldNC
        oldNC = hookmetamethod(game, "__namecall", function(self, ...)
            local result = oldNC(self, ...)
            if warmup then return result end
            local method = getnamecallmethod()
            local isFire = (method == "FireServer")
            local isInvoke = (method == "InvokeServer")
            if not (isFire or isInvoke) then return result end
            if filterText ~= "" and not self.Name:lower():find(filterText:lower(), 1, true) then
                return result
            end
            if typeof(self) == "Instance" then
                local argsSnap = table.pack(...)
                local remote = self
                local tag = isFire and "→" or "⇒"
                task.spawn(function()
                    pcall(function()
                        local argStr, typeStr = fmtArgs(argsSnap)
                        local short = remote:GetFullName()
                            :gsub("ReplicatedStorage%.", "")
                            :gsub("ReplicatedFirst%.", "")
                        counters[remote.Name] = (counters[remote.Name] or 0) + 1
                        addLog(("%s %s %s(%d:%s) x%d %s")
                            :format(ts(), tag, short, argsSnap.n, typeStr,
                                    counters[remote.Name], argStr), COL.OUT)

                        if remote == FreeKickRemote then
                            local action = argsSnap[1]
                            local payload = argsSnap[2]
                            if action == "Shoot" and type(payload) == "table" then
                                State.MyShots = State.MyShots + 1
                                State.ShotIndex = State.ShotIndex + 1
                                State.CurrentPayload = payload
                                State.CurrentShooter = LP.UserId
                                State.CurrentShooterName = LP.Name
                                State.MyTurn = false
                                State.PlayerStats[LP.UserId] =
                                    State.PlayerStats[LP.UserId] or {shots=0, goals=0, outs=0}
                                State.PlayerStats[LP.UserId].shots =
                                    State.PlayerStats[LP.UserId].shots + 1
                                updateStats()
                                updateCurrent()
                            elseif action == "MatchPresentationHold"
                                and type(payload) == "table" then
                                State.PresentationHolding = payload.holding == true
                                updateStats()
                            elseif action == "MatchPresentationSkip"
                                and type(payload) == "table" then
                                State.SkipStage = payload.stage
                                State.SkipRequestedBy = LP.UserId
                                updateStats()
                            elseif action == "MatchReplayStarted" then
                                State.ReplayStarted = true
                            elseif action == "CommitKickRoot"
                                and type(payload) == "table" then
                                State.LastKickRootPos = payload.position
                            elseif action == "MatchShotComplete" then
                                State.CurrentPayload = nil
                            end
                        end
                    end)
                end)
            end
            return result
        end)
    end)
    if not ok then warn("[AUTO] hookmm error: " .. tostring(err)) end
end

-- HOOK INCOMING
local function hookRemote(remote)
    if not (remote:IsA("RemoteEvent")
        or remote:IsA("UnreliableRemoteEvent")) then return end
    if remote:GetAttribute("_fkAutoHooked") then return end
    remote:SetAttribute("_fkAutoHooked", true)
    hookedCount = hookedCount + 1

    remote.OnClientEvent:Connect(function(...)
        local argsSnap = table.pack(...)
        local action  = argsSnap[1]
        local payload = argsSnap[2]

        if warmup then return end
        if filterText ~= "" and not remote.Name:lower():find(filterText:lower(), 1, true) then
            return
        end

        local short = remote:GetFullName()
            :gsub("ReplicatedStorage%.", "")
            :gsub("ReplicatedFirst%.", "")

        task.spawn(function()
            pcall(function()
                local argStr, typeStr = fmtArgs(argsSnap)
                counters[remote.Name] = (counters[remote.Name] or 0) + 1
                local color = COL.IN
                if action == "GoalConfirmed" then color = COL.GOAL
                elseif action == "OutOfPlay" then color = COL.MISS end
                addLog(("%s ← %s(%d:%s) x%d %s")
                    :format(ts(), short, argsSnap.n, typeStr,
                            counters[remote.Name], argStr), color)

                if action == "MatchState" and type(payload) == "table" then
                    if payload.matchId then State.MatchId = payload.matchId end
                    if payload.playerA then
                        State.PlayerA = payload.playerA
                        State.ScoreA = payload.playerA.score or State.ScoreA
                    end
                    if payload.playerB then
                        State.PlayerB = payload.playerB
                        State.ScoreB = payload.playerB.score or State.ScoreB
                    end
                    if payload.scoreA then State.ScoreA = payload.scoreA end
                    if payload.scoreB then State.ScoreB = payload.scoreB end
                    if payload.regulationRoundLimit then
                        State.RoundLimit = payload.regulationRoundLimit end
                    if payload.suddenDeath ~= nil then
                        State.SuddenDeath = payload.suddenDeath == true end
                    if payload.suddenDeathRound then
                        State.SuddenDeathRound = payload.suddenDeathRound end
                    if payload.suddenDeathRoundLimit then
                        State.SuddenDeathRoundLimit = payload.suddenDeathRoundLimit end
                    if payload.overtimeRound then
                        State.OvertimeRound = payload.overtimeRound end
                    if payload.decidingKick ~= nil then
                        State.DecidingKick = payload.decidingKick == true end
                    if payload.overtime ~= nil then
                        State.Overtime = payload.overtime == true end
                    if payload.timedOut ~= nil then
                        State.TimedOut = payload.timedOut == true end
                    if payload.deadline then State.Deadline = payload.deadline end
                    if payload.shotOrder then State.ShotOrder = payload.shotOrder end
                    if payload.round then State.Round = payload.round end
                    if payload.shot then State.Shot = payload.shot end
                    if payload.shotCount then State.ShotCount = payload.shotCount end
                    if payload.regulationResultsA then
                        State.RegA = payload.regulationResultsA end
                    if payload.regulationResultsB then
                        State.RegB = payload.regulationResultsB end
                    if payload.shooterUserId then
                        State.ShooterUserId = payload.shooterUserId end
                    if payload.state then State.MatchPhase = payload.state end
                    refreshMyTurn()
                    if payload.state == "Result" then
                        State.PresentationHolding = false
                        State.SkipStage = nil
                        State.ReplayStarted = false
                        if AutoState.shotState ~= "IDLE" then
                            AutoState.shotState = "IDLE"
                            updateAutoStats()
                        end
                    end
                    updateStats()

                elseif action == "KickReady" and type(payload) == "table" then
                    State.KickData = payload
                    if payload.shooterUserId then
                        State.ShooterUserId = payload.shooterUserId
                        State.CurrentShooter = payload.shooterUserId
                        State.CurrentShooterName = getPlayerName(payload.shooterUserId)
                        State.MyTurn = (payload.shooterUserId == LP.UserId)
                    end
                    if AutoState.shotState ~= "IDLE"
                        and (tick() - AutoState.lastFireTime) > 5 then
                        AutoState.shotState = "IDLE"
                        updateAutoStats()
                    end
                    updateCurrent()
                    updateStats()

                elseif action == "ShotVisualStarted" and type(payload) == "table" then
                    if payload.shooterUserId then
                        State.CurrentShooter = payload.shooterUserId
                        State.CurrentShooterName = getPlayerName(payload.shooterUserId)
                        updateCurrent()
                    end

                elseif action == "ShotAccepted" and type(payload) == "table" then
                    State.TotalShots = State.TotalShots + 1
                    local uid = payload.shooterUserId
                    State.CurrentShooter = uid
                    State.CurrentShooterName = getPlayerName(uid)
                    State.LastLabel = payload.label or payload.mode or "-"
                    if uid then
                        State.PlayerStats[uid] = State.PlayerStats[uid]
                            or {shots=0, goals=0, outs=0}
                        State.PlayerStats[uid].shots = State.PlayerStats[uid].shots + 1
                    end
                    if uid == LP.UserId then
                        State.MyTurn = false
                        if AutoState.shotState == "FIRED" then
                            AutoState.shotState = "WAIT_RESULT"
                            AutoState.accepted = AutoState.accepted + 1
                            updateAutoStats()
                        end
                    end
                    if payload.shotSequence then
                        PendingShots[payload.shotSequence] = {
                            shooterUserId = payload.shooterUserId,
                            power = payload.power,
                            precision = payload.precision,
                            mode = payload.mode,
                            kickData = State.KickData,
                            time = tick(),
                        }
                        for k, v in pairs(PendingShots) do
                            if (tick() - v.time) > 30 then PendingShots[k] = nil end
                        end
                    end
                    updateStats()
                    updateCurrent()

                elseif action == "GoalConfirmed" then
                    local uid = payload and payload.shooterUserId
                    local sname = getPlayerName(uid)
                    local gp = "?"
                    if payload and payload.goalPosition then
                        gp = tostring(payload.goalPosition)
                    end
                    State.Goals = State.Goals + 1
                    if uid then
                        State.PlayerStats[uid] = State.PlayerStats[uid]
                            or {shots=0, goals=0, outs=0}
                        State.PlayerStats[uid].goals = State.PlayerStats[uid].goals + 1
                    end
                    if uid == LP.UserId and AutoState.shotState ~= "IDLE" then
                        AutoState.goals = AutoState.goals + 1
                        AutoState.shotState = "IDLE"
                        updateAutoStats()
                        applyLearn("GOAL", payload)
                    end
                    local sq = payload and payload.shotSequence
                    if sq then
                        local ref = PendingShots[sq]
                        if ref and ref.shooterUserId ~= LP.UserId
                            and ref.kickData and ref.kickData.distanceMeters then
                            local d = ref.kickData.distanceMeters
                            local bucket = math.floor(d * 2) / 2
                            RefShots[bucket] = {
                                power = ref.power,
                                mode = ref.mode,
                                ballZ = ref.kickData.ballPosition
                                    and ref.kickData.ballPosition.Z or 0,
                                uid = ref.shooterUserId,
                                time = tick(),
                            }
                            addLog(("[REF] saved d=%.2fm pwr=%.3f uid=%d")
                                :format(d, ref.power, ref.shooterUserId), COL.REF)
                            updateAutoStats()
                        end
                        PendingShots[sq] = nil
                    end
                    addHistory(State.ShotIndex, "GOAL ✓", State.LastLabel,
                               sname, uid, "goalPos=" .. gp)
                    updateStats()

                elseif action == "OutOfPlay" then
                    local uid = payload and payload.shooterUserId
                    local sname = getPlayerName(uid)
                    local op, bd = "?", "?"
                    if payload then
                        if payload.outPosition then op = tostring(payload.outPosition) end
                        if payload.boundary then bd = tostring(payload.boundary) end
                    end
                    State.Outs = State.Outs + 1
                    if uid then
                        State.PlayerStats[uid] = State.PlayerStats[uid]
                            or {shots=0, goals=0, outs=0}
                        State.PlayerStats[uid].outs = State.PlayerStats[uid].outs + 1
                    end
                    if uid == LP.UserId and AutoState.shotState ~= "IDLE" then
                        AutoState.outs = AutoState.outs + 1
                        AutoState.shotState = "IDLE"
                        updateAutoStats()
                        applyLearn("MISS", payload)
                    end
                    if payload and payload.shotSequence then
                        PendingShots[payload.shotSequence] = nil
                    end
                    addHistory(State.ShotIndex, "OUT ✗", State.LastLabel,
                               sname, uid, "pos=" .. op .. " | " .. bd)
                    updateStats()

                elseif action == "MatchPresentationSkip" and type(payload) == "table" then
                    State.SkipStage = payload.stage
                    State.SkipRequestedBy = payload.requestedByUserId
                    updateStats()
                end
            end)
        end)
    end)
end

local containers = { ReplicatedStorage, ReplicatedFirst, workspace,
    LP:WaitForChild("PlayerGui") }

for _, c in ipairs(containers) do
    pcall(function()
        for _, obj in ipairs(c:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("UnreliableRemoteEvent") then
                if obj:GetAttribute("_fkAutoHooked") then
                    obj:SetAttribute("_fkAutoHooked", nil)
                end
                if obj:GetAttribute("_fkGuiHooked") then
                    obj:SetAttribute("_fkGuiHooked", nil)
                end
            end
        end
    end)
end

local function hookContainer(c)
    for _, obj in ipairs(c:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("UnreliableRemoteEvent") then
            pcall(hookRemote, obj)
        end
    end
    c.DescendantAdded:Connect(function(obj)
        if obj:IsA("RemoteEvent") or obj:IsA("UnreliableRemoteEvent") then
            pcall(hookRemote, obj)
        end
    end)
end

for _, c in ipairs(containers) do pcall(hookContainer, c) end

task.spawn(function()
    while true do
        task.wait(0.15)
        if not AutoState.armed then continue end
        if warmup then continue end
        if State.PresentationHolding then continue end
        if State.MatchPhase ~= "Shoot" then continue end
        if State.ShooterUserId ~= LP.UserId then continue end
        if (tick() - AutoState.lastFireTime) < COOLDOWN then continue end
        if AutoState.shotState ~= "IDLE" then continue end
        task.wait(math.random() * 0.6 + 0.4)
        if not AutoState.armed then continue end
        if State.MatchPhase ~= "Shoot" then continue end
        if State.ShooterUserId ~= LP.UserId then continue end
        if (tick() - AutoState.lastFireTime) < COOLDOWN then continue end
        fireShot()
    end
end)

local function showCopyOverlay(txt)
    local ov = Instance.new("Frame")
    ov.Size = UDim2.new(0.92, 0, 0.72, 0)
    ov.Position = UDim2.new(0.04, 0, 0.14, 0)
    ov.BackgroundColor3 = Color3.fromRGB(10, 14, 20)
    ov.BorderSizePixel = 0
    ov.ZIndex = 50
    ov.Parent = gui
    Instance.new("UICorner", ov).CornerRadius = UDim.new(0, 8)

    local hint = Instance.new("TextLabel")
    hint.Size = UDim2.new(1, -16, 0, 24)
    hint.Position = UDim2.new(0, 8, 0, 6)
    hint.BackgroundTransparency = 1
    hint.Text = "Long-press → Copy"
    hint.TextColor3 = Color3.fromRGB(180, 200, 220)
    hint.Font = Enum.Font.GothamMedium
    hint.TextSize = 12
    hint.TextXAlignment = Enum.TextXAlignment.Left
    hint.ZIndex = 51
    hint.Parent = ov

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -16, 1, -74)
    box.Position = UDim2.new(0, 8, 0, 34)
    box.BackgroundColor3 = Color3.fromRGB(6, 10, 14)
    box.BorderSizePixel = 0
    box.TextColor3 = Color3.fromRGB(200, 220, 240)
    box.Font = Enum.Font.Code
    box.TextSize = 11
    box.Text = txt
    box.TextWrapped = true
    box.MultiLine = true
    box.ClearTextOnFocus = false
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.TextYAlignment = Enum.TextYAlignment.Top
    box.ZIndex = 51
    box.Parent = ov
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 100, 0, 32)
    close.Position = UDim2.new(0.5, -50, 1, -40)
    close.BackgroundColor3 = Color3.fromRGB(60, 30, 35)
    close.BorderSizePixel = 0
    close.Text = "CLOSE"
    close.TextColor3 = Color3.fromRGB(255, 150, 160)
    close.Font = Enum.Font.GothamBold
    close.TextSize = 12
    close.ZIndex = 51
    close.Parent = ov
    Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)
    close.MouseButton1Click:Connect(function() ov:Destroy() end)
end

clearBtn.MouseButton1Click:Connect(function()
    for _, c in ipairs(logScroll:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    for _, c in ipairs(histScroll:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    allLogs = {}; counters = {}
    State.MyShots = 0; State.TotalShots = 0; State.Goals = 0
    State.Outs = 0; State.ShotIndex = 0; State.PlayerStats = {}
    LearnState.buckets = {}
    LearnState.consecutiveMisses = 0
    LearnState.consecutiveGoals = 0
    PendingShots = {}
    updateStats()
    updateAutoStats()
    curLbl.Text = "  CURRENT: (waiting)"
end)

pauseBtn.MouseButton1Click:Connect(function()
    paused = not paused
    if paused then
        pauseBtn.Text = "RESUME"
        pauseBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
    else
        pauseBtn.Text = "PAUSE"
        pauseBtn.BackgroundColor3 = Color3.fromRGB(80, 60, 20)
    end
end)

armBtn.MouseButton1Click:Connect(function()
    AutoState.armed = not AutoState.armed
    if AutoState.armed then
        armBtn.Text = "ARM: ON"
        armBtn.BackgroundColor3 = Color3.fromRGB(30, 90, 50)
        addLog("[AUTO] ARMED", COL.AUTO)
    else
        armBtn.Text = "ARM: OFF"
        armBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 40)
        addLog("[AUTO] disarmed", COL.WARN)
    end
end)

learnBtn.MouseButton1Click:Connect(function()
    AutoState.learn = not AutoState.learn
    if AutoState.learn then
        learnBtn.Text = "LEARN: ON"
        learnBtn.BackgroundColor3 = Color3.fromRGB(30, 70, 90)
    else
        learnBtn.Text = "LEARN: OFF"
        learnBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    end
end)

tuneBtn.MouseButton1Click:Connect(function()
    tunePanel.Visible = not tunePanel.Visible
end)

sideBtn.MouseButton1Click:Connect(function()
    AutoState.autoSide = not AutoState.autoSide
    if AutoState.autoSide then
        sideBtn.Text = "SIDE: ON"
        sideBtn.BackgroundColor3 = Color3.fromRGB(30, 80, 50)
    else
        sideBtn.Text = "SIDE: OFF"
        sideBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 40)
    end
end)

-- ★ ปุ่ม PCT — วน 6 สถานะ OFF/AUTO/8/10/13/15
local function refreshPwrBtn()
    local e = PWR_CYCLE[AutoState.pwrCycleIdx]
    if e.isOff then
        pwrBtn.Text = "PCT:OFF"
        pwrBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    elseif e.value then
        pwrBtn.Text = "PCT:" .. e.label
        pwrBtn.BackgroundColor3 = Color3.fromRGB(90, 60, 30)
    else
        pwrBtn.Text = "PCT:AUTO"
        pwrBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 40)
    end
end
refreshPwrBtn()

pwrBtn.MouseButton1Click:Connect(function()
    AutoState.pwrCycleIdx = AutoState.pwrCycleIdx + 1
    if AutoState.pwrCycleIdx > #PWR_CYCLE then
        AutoState.pwrCycleIdx = 1
    end
    refreshPwrBtn()
    updateAutoStats()
    local e = PWR_CYCLE[AutoState.pwrCycleIdx]
    if e.isOff then
        addLog("[AUTO] PCT = OFF (all dynamic)", COL.WARN)
    elseif e.value then
        addLog(("[AUTO] PCT = %s (pwr=%.2f cY=%.3f)")
            :format(e.label, e.value, PCT_CONTACT_Y), COL.WARN)
    else
        addLog(("[AUTO] PCT = AUTO (cY=%.3f pwr=dynamic)")
            :format(PCT_CONTACT_Y), COL.WARN)
    end
end)

local function buildCopy()
    local lines = {}
    table.insert(lines, "=== FK AUTO LOG ===")
    table.insert(lines, "Place: " .. tostring(game.PlaceId))
    table.insert(lines, "Job: " .. tostring(game.JobId))
    table.insert(lines, "MyShots=" .. State.MyShots
        .. " SeenShots=" .. State.TotalShots
        .. " Goals=" .. State.Goals .. " Outs=" .. State.Outs)
    table.insert(lines, "Score: " .. State.ScoreA .. "-" .. State.ScoreB)
    table.insert(lines, "AUTO fired=" .. AutoState.fired
        .. " accepted=" .. AutoState.accepted
        .. " goals=" .. AutoState.goals
        .. " outs=" .. AutoState.outs
        .. " timeout=" .. AutoState.timeouts
        .. " pct=" .. PWR_CYCLE[AutoState.pwrCycleIdx].label)
    table.insert(lines, ("Params: pwr=%.2f cY=%.2f cX=%.2f prec=%.2f delay=%.2f yaw=%.2f")
        :format(AutoState.power, AutoState.contactY, AutoState.contactX,
                AutoState.precision, AutoState.contactDelay, AutoState.aimYaw))
    table.insert(lines, "--- LEARN BUCKETS ---")
    for key, b in pairs(LearnState.buckets) do
        table.insert(lines, ("  %s: cY=%.3f cX=%.3f pwr=%.3f yaw=%.3f — %d/%d")
            :format(key, b.cY, b.cX, b.power, b.yaw, b.goals, b.goals + b.misses))
    end
    table.insert(lines, "--- REF SHOTS ---")
    for bucket, ref in pairs(RefShots) do
        table.insert(lines, ("  %.2fm: pwr=%.3f mode=%s uid=%d")
            :format(bucket, ref.power, tostring(ref.mode), ref.uid))
    end
    table.insert(lines, "--- HISTORY ---")
    for _, c in ipairs(histScroll:GetChildren()) do
        if c:IsA("TextLabel") then table.insert(lines, c.Text) end
    end
    table.insert(lines, "--- RAW LOG ---")
    for _, l in ipairs(allLogs) do table.insert(lines, l) end
    local txt = table.concat(lines, "\n")
    if #txt > MAX_COPY then txt = txt:sub(#txt - MAX_COPY + 1) end
    return txt
end

copyBtn.MouseButton1Click:Connect(function()
    local txt = buildCopy()
    if CAP.setclipboard then
        local ok = pcall(setclipboard, txt)
        if ok then addLog("[COPY] " .. #txt .. " chars", COL.WARN) return end
    end
    if CAP.toclipboard then
        local ok = pcall(toclipboard, txt)
        if ok then addLog("[COPY] " .. #txt .. " chars", COL.WARN) return end
    end
    showCopyOverlay(txt)
    addLog("[COPY] manual overlay", COL.WARN)
end)

saveBtn.MouseButton1Click:Connect(function()
    if not CAP.writefile then
        addLog("[SAVE] not supported", COL.ERR)
        return
    end
    if CAP.makefolder and CAP.isfolder then
        local ok, exists = pcall(isfolder, SAVE_DIR)
        if ok and not exists then pcall(makefolder, SAVE_DIR) end
    end
    local txt = buildCopy()
    local fname = SAVE_DIR .. "/fk_" .. math.floor(tick()) .. ".txt"
    local ok = pcall(writefile, fname, txt)
    addLog("[SAVE] " .. (ok and fname or "fail"), ok and COL.IN or COL.ERR)
end)

filterBox:GetPropertyChangedSignal("Text"):Connect(function()
    filterText = filterBox.Text
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        frame.Visible = not frame.Visible
    end
end)

updateStats()
updateAutoStats()
addLog(ts() .. " FREEKICK AUTO — full", COL.HDR)
addLog(ts() .. " Place: " .. tostring(game.PlaceId), COL.HDR)
addLog(ts() .. " hooked: " .. hookedCount
    .. " | hookmm: " .. (CAP.hookmetamethod and "Y" or "N")
    .. " | touch: " .. (IS_TOUCH and "Y" or "N"), COL.MISC)
addLog(ts() .. " PCT cycle: OFF/AUTO/8%/10%/13%/15% (default 13%)", COL.REF)
addLog(ts() .. (" PCT_CONTACT_Y = %.3f"):format(PCT_CONTACT_Y), COL.REF)
addLog(ts() .. " seeds: 22.6/22.5/22.4/22.1/20.3/18.7m", COL.REF)

task.spawn(function()
    task.wait(WARMUP_TIME)
    warmup = false
    addLog(ts() .. " [warmup DONE]", COL.WARN)
end)

print("[FK AUTO] loaded — PCT OFF/AUTO/8/10/13/15")
