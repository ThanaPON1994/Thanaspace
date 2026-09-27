-- =====================================================
-- FREEKICK AUTO + AUTO POWER + GREEN ZONE
-- AUTO POWER: กรอก 8-99.999 → power /100
-- AUTO GREEN: ยิงด้วย power + aim ไปที่กรอบเขียว
-- =====================================================

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst   = game:GetService("ReplicatedFirst")
local RunService        = game:GetService("RunService")
local LP = Players.LocalPlayer

local GOAL_CENTER = Vector3.new(188.1, 5.0, 0.0)
local GOAL_PLANE_X = 188.1

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
        if r then FreeKickRemote = r:FindFirstChild("Remotes"):FindFirstChild("FreeKickRemote") or FreeKickRemote end
        if not FreeKickRemote then FreeKickRemote = r:FindFirstChild("FreeKickRemote") end
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
local GREEN_COOLDOWN = 4

-- AUTO POWER
local AutoPower = {
    enabled = false,
    powerValue = 0.15,
    powerInput = "15",
    lastContactY = -0.55,
    lastContactX = -0.65,
    lastLeg = "Right",
    hasReference = false,
    lastFireTime = 0,
}

-- GREEN ZONE
local Green = {
    autoGreen = false,      -- ยิง auto ตอนถึงตา
    zoneOn = false,         -- แสดงกรอบ
    locked = false,         -- ล็อคกรอบ ลากไม่ได้
    x1 = 0, y1 = 0,         -- มุมที่ 1 (screen)
    x2 = 0, y2 = 0,         -- มุมที่ 2 (screen)
    drawing = false,
    dragStart = nil,
    lastFireTime = 0,
}

local AutoState = {
    armed = false, learn = false,
    leg = "Right",
    aimYaw = 0.0, power = 0.55,
    contactX = -0.65, contactY = -0.55,
    precision = 0.50, contactDelay = 0.06,
    dynamicAim = true, autoSide = true, powerByDistance = true,
    pwrCycleIdx = 5,
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

local LearnState = { buckets = {}, consecutiveMisses = 0, consecutiveGoals = 0 }
local RefShots, PendingShots = {}, {}

do
    local seeds = {
        { d=22.636, p=0.684, uid=5245038569 },
        { d=20.341, p=0.553, uid=8889346895 },
        { d=18.765, p=0.545, uid=4684928145 },
        { d=22.100, p=0.550, uid=8889346895 },
        { d=22.471, p=0.550, uid=8889346895 },
        { d=22.122, p=0.550, uid=8889346895 },
        { d=20.207, p=0.550, uid=3516905894 },
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
        return ("%.5f"):format(v)
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
        return clampNum(0.55 + (d - 19.8) * 0.005, 0.30, 0.99999)
    end
    local base = 0.55 + (21.5 - 19.8) * 0.005
    return clampNum(base + (d - 21.5) * 0.100, 0.30, 0.99999)
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

-- ═══════ GREEN ZONE WORLD TARGET ═══════
local function getGreenTarget()
    -- คำนวณ world point จากกลางกรอบ green
    if not Green.zoneOn then return nil end
    if Green.x1 == Green.x2 and Green.y1 == Green.y2 then return nil end
    local cam = workspace.CurrentCamera
    if not cam then return nil end
    local vp = cam.ViewportSize
    local cx = (Green.x1 + Green.x2) / 2
    local cy = (Green.y1 + Green.y2) / 2
    -- คำนวณ world point บน plane X = GOAL_PLANE_X
    -- ใช้ ScreenPointToRay
    local ray = cam:ScreenPointToRay(cx, cy)
    local o, d = ray.Origin, ray.Direction
    if math.abs(d.X) < 1e-6 then return nil end
    local t = (GOAL_PLANE_X - o.X) / d.X
    if t < 0 then return nil end
    local hit = o + d * t
    return hit
end

local function getGreenAimYaw()
    local kd = State.KickData
    if not kd or not kd.ballPosition then return nil end
    local target = getGreenTarget()
    if not target then return nil end
    local b = kd.ballPosition
    local dx = target.X - b.X
    local dz = target.Z - b.Z
    return math.atan2(dz, dx)
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

-- ═══════ GREEN ZONE FRAME (draws on top) ═══════
local greenFrame = Instance.new("Frame")
greenFrame.Name = "GreenZone"
greenFrame.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
greenFrame.BackgroundTransparency = 0.7
greenFrame.BorderSizePixel = 2
greenFrame.BorderColor3 = Color3.fromRGB(0, 255, 100)
greenFrame.Visible = false
greenFrame.ZIndex = 5
greenFrame.Active = false
greenFrame.Parent = gui

local greenCorner = Instance.new("UICorner")
greenCorner.CornerRadius = UDim.new(0, 4)
greenCorner.Parent = greenFrame

local greenLabel = Instance.new("TextLabel")
greenLabel.Size = UDim2.new(1, 0, 0, 14)
greenLabel.Position = UDim2.new(0, 0, 1, 2)
greenLabel.BackgroundTransparency = 1
greenLabel.Text = "GREEN"
greenLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
greenLabel.Font = Enum.Font.GothamBold
greenLabel.TextSize = 10
greenLabel.ZIndex = 6
greenLabel.Parent = greenFrame

-- ═══════ GREEN TOUCH/DRAG OVERLAY (เฉพาะตอน unlock + zone on) ═══════
local greenCatcher = Instance.new("TextButton")
greenCatcher.Name = "GreenCatcher"
greenCatcher.Size = UDim2.new(1, 0, 1, 0)
greenCatcher.Position = UDim2.new(0, 0, 0, 0)
greenCatcher.BackgroundTransparency = 1
greenCatcher.Text = ""
greenCatcher.Visible = false
greenCatcher.ZIndex = 1
greenCatcher.AutoButtonColor = false
greenCatcher.Parent = gui

-- Draw mode logic
local function startDraw(x, y)
    Green.x1 = x; Green.y1 = y
    Green.x2 = x; Green.y2 = y
    Green.drawing = true
end

local function updateDraw(x, y)
    if not Green.drawing then return end
    Green.x2 = x; Green.y2 = y
    local minX = math.min(Green.x1, Green.x2)
    local minY = math.min(Green.y1, Green.y2)
    local maxX = math.max(Green.x1, Green.x2)
    local maxY = math.max(Green.y1, Green.y2)
    greenFrame.Position = UDim2.new(0, minX, 0, minY)
    greenFrame.Size = UDim2.new(0, math.max(maxX - minX, 4), 0, math.max(maxY - minY, 4))
end

local function finishDraw()
    Green.drawing = false
    if math.abs(Green.x1 - Green.x2) < 4 or math.abs(Green.y1 - Green.y2) < 4 then
        -- cancel ถ้าเล็กเกิน
        Green.x1 = 0; Green.y1 = 0; Green.x2 = 0; Green.y2 = 0
        greenFrame.Visible = false
    end
end

greenCatcher.InputBegan:Connect(function(input)
    if Green.locked then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        startDraw(input.Position.X, input.Position.Y)
        greenFrame.Visible = Green.zoneOn
        updateDraw(input.Position.X, input.Position.Y)
    end
end)

greenCatcher.InputChanged:Connect(function(input)
    if Green.drawing then
        updateDraw(input.Position.X, input.Position.Y)
    end
end)

greenCatcher.InputEnded:Connect(function(input)
    if Green.drawing then
        updateDraw(input.Position.X, input.Position.Y)
        finishDraw()
        addLog(("[GREEN] zone set [%d,%d → %d,%d]")
            :format(Green.x1, Green.y1, Green.x2, Green.y2), COL.GREEN)
    end
end)

-- ═══════ MAIN FRAME ═══════
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 560, 0, 880)
frame.Position = UDim2.new(0, 20, 0, 10)
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
titleBar.Size = UDim2.new(1, 0, 0, 34)
titleBar.BackgroundColor3 = Color3.fromRGB(22, 26, 34)
titleBar.BorderSizePixel = 0
titleBar.Active = true
titleBar.Parent = frame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -160, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "FREEKICK AUTO + GREEN"
title.TextColor3 = Color3.fromRGB(120, 200, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 11
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 32, 0, 28)
closeBtn.Position = UDim2.new(1, -38, 0, 3)
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
minBtn.Size = UDim2.new(0, 32, 0, 28)
minBtn.Position = UDim2.new(1, -74, 0, 3)
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
        frame.Size = UDim2.new(0, 560, 0, 34)
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

-- ═══════ AUTO POWER PANEL ═══════
local apPanel = Instance.new("Frame")
apPanel.Size = UDim2.new(1, -12, 0, 100)
apPanel.Position = UDim2.new(0, 6, 0, 40)
apPanel.BackgroundColor3 = Color3.fromRGB(20, 30, 24)
apPanel.BorderSizePixel = 0
apPanel.Parent = frame
Instance.new("UICorner", apPanel).CornerRadius = UDim.new(0, 6)
table.insert(hideRefs, apPanel)

local apStroke = Instance.new("UIStroke")
apStroke.Color = Color3.fromRGB(120, 255, 160)
apStroke.Thickness = 1.2
apStroke.Transparency = 0.3
apStroke.Parent = apPanel

local apTitle = Instance.new("TextLabel")
apTitle.Size = UDim2.new(1, -12, 0, 18)
apTitle.Position = UDim2.new(0, 8, 0, 2)
apTitle.BackgroundTransparency = 1
apTitle.Text = "  AUTO POWER  (8 - 99.999)"
apTitle.TextColor3 = Color3.fromRGB(160, 255, 200)
apTitle.Font = Enum.Font.GothamBold
apTitle.TextSize = 11
apTitle.TextXAlignment = Enum.TextXAlignment.Left
apTitle.Parent = apPanel

local apToggle = Instance.new("TextButton")
apToggle.Size = UDim2.new(0, 90, 0, 30)
apToggle.Position = UDim2.new(1, -100, 0, 24)
apToggle.BackgroundColor3 = Color3.fromRGB(60, 30, 40)
apToggle.BorderSizePixel = 0
apToggle.Text = "OFF"
apToggle.TextColor3 = Color3.fromRGB(230, 200, 200)
apToggle.Font = Enum.Font.GothamBold
apToggle.TextSize = 12
apToggle.Parent = apPanel
Instance.new("UICorner", apToggle).CornerRadius = UDim.new(0, 6)

local apPwrLbl = Instance.new("TextLabel")
apPwrLbl.Size = UDim2.new(0, 70, 0, 30)
apPwrLbl.Position = UDim2.new(0, 8, 0, 24)
apPwrLbl.BackgroundTransparency = 1
apPwrLbl.Text = "POWER:"
apPwrLbl.TextColor3 = Color3.fromRGB(200, 230, 210)
apPwrLbl.Font = Enum.Font.GothamBold
apPwrLbl.TextSize = 12
apPwrLbl.TextXAlignment = Enum.TextXAlignment.Left
apPwrLbl.Parent = apPanel

local apPwrBox = Instance.new("TextBox")
apPwrBox.Size = UDim2.new(0, 90, 0, 30)
apPwrBox.Position = UDim2.new(0, 80, 0, 24)
apPwrBox.BackgroundColor3 = Color3.fromRGB(8, 14, 10)
apPwrBox.BorderSizePixel = 0
apPwrBox.Text = "55"
apPwrBox.PlaceholderText = "8 - 99.999"
apPwrBox.TextColor3 = Color3.fromRGB(120, 255, 180)
apPwrBox.Font = Enum.Font.Code
apPwrBox.TextSize = 14
apPwrBox.ClearTextOnFocus = false
apPwrBox.Parent = apPanel
Instance.new("UICorner", apPwrBox).CornerRadius = UDim.new(0, 6)

local apPreview = Instance.new("TextLabel")
apPreview.Size = UDim2.new(0, 130, 0, 30)
apPreview.Position = UDim2.new(0, 176, 0, 24)
apPreview.BackgroundTransparency = 1
apPreview.Text = "= 0.55000"
apPreview.TextColor3 = Color3.fromRGB(180, 220, 200)
apPreview.Font = Enum.Font.Code
apPreview.TextSize = 12
apPreview.TextXAlignment = Enum.TextXAlignment.Left
apPreview.Parent = apPanel

local apStatus = Instance.new("TextLabel")
apStatus.Size = UDim2.new(1, -12, 0, 16)
apStatus.Position = UDim2.new(0, 8, 0, 60)
apStatus.BackgroundTransparency = 1
apStatus.Text = "  waiting contactY..."
apStatus.TextColor3 = Color3.fromRGB(150, 180, 160)
apStatus.Font = Enum.Font.Code
apStatus.TextSize = 10
apStatus.TextXAlignment = Enum.TextXAlignment.Left
apStatus.Parent = apPanel

-- ═══════ GREEN PANEL ═══════
local grPanel = Instance.new("Frame")
grPanel.Size = UDim2.new(1, -12, 0, 100)
grPanel.Position = UDim2.new(0, 6, 0, 148)
grPanel.BackgroundColor3 = Color3.fromRGB(16, 30, 20)
grPanel.BorderSizePixel = 0
grPanel.Parent = frame
Instance.new("UICorner", grPanel).CornerRadius = UDim.new(0, 6)
table.insert(hideRefs, grPanel)

local grStroke = Instance.new("UIStroke")
grStroke.Color = Color3.fromRGB(0, 255, 120)
grStroke.Thickness = 1.2
grStroke.Transparency = 0.3
grStroke.Parent = grPanel

local grTitle = Instance.new("TextLabel")
grTitle.Size = UDim2.new(1, -12, 0, 18)
grTitle.Position = UDim2.new(0, 8, 0, 2)
grTitle.BackgroundTransparency = 1
grTitle.Text = "  GREEN ZONE"
grTitle.TextColor3 = Color3.fromRGB(100, 255, 160)
grTitle.Font = Enum.Font.GothamBold
grTitle.TextSize = 11
grTitle.TextXAlignment = Enum.TextXAlignment.Left
grTitle.Parent = grPanel

local function mkGrBtn(x, w, text, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w, 0, 30)
    b.Position = UDim2.new(0, x, 0, 24)
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.fromRGB(230, 250, 240)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 10
    b.Parent = grPanel
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local grAutoBtn  = mkGrBtn(6,   130, "AUTO GREEN: OFF", Color3.fromRGB(60, 30, 40))
local grZoneBtn  = mkGrBtn(142, 130, "ZONE: OFF",       Color3.fromRGB(40, 40, 60))
local grLockBtn  = mkGrBtn(278, 130, "UNLOCK",          Color3.fromRGB(80, 60, 30))
local grClearBtn = mkGrBtn(414, 130, "CLEAR",           Color3.fromRGB(60, 30, 35))

local grStatus = Instance.new("TextLabel")
grStatus.Size = UDim2.new(1, -12, 0, 16)
grStatus.Position = UDim2.new(0, 8, 0, 60)
grStatus.BackgroundTransparency = 1
grStatus.Text = "  zone: (empty) | unlock → drag on screen"
grStatus.TextColor3 = Color3.fromRGB(160, 220, 180)
grStatus.Font = Enum.Font.Code
grStatus.TextSize = 10
grStatus.TextXAlignment = Enum.TextXAlignment.Left
grStatus.Parent = grPanel

-- ═══════ PCT PANEL ═══════
local pctPanel = Instance.new("Frame")
pctPanel.Size = UDim2.new(1, -12, 0, 90)
pctPanel.Position = UDim2.new(0, 6, 0, 256)
pctPanel.BackgroundColor3 = Color3.fromRGB(28, 20, 32)
pctPanel.BorderSizePixel = 0
pctPanel.Parent = frame
Instance.new("UICorner", pctPanel).CornerRadius = UDim.new(0, 6)
table.insert(hideRefs, pctPanel)

local pctStroke = Instance.new("UIStroke")
pctStroke.Color = Color3.fromRGB(220, 140, 255)
pctStroke.Thickness = 1.2
pctStroke.Transparency = 0.3
pctStroke.Parent = pctPanel

local pctOnLbl = Instance.new("TextLabel")
pctOnLbl.Size = UDim2.new(0, 100, 0, 18)
pctOnLbl.Position = UDim2.new(0, 8, 0, 4)
pctOnLbl.BackgroundTransparency = 1
pctOnLbl.Text = "PCT ON:"
pctOnLbl.TextColor3 = Color3.fromRGB(230, 180, 255)
pctOnLbl.Font = Enum.Font.GothamBold
pctOnLbl.TextSize = 11
pctOnLbl.TextXAlignment = Enum.TextXAlignment.Left
pctOnLbl.Parent = pctPanel

local pctOnBtn = Instance.new("TextButton")
pctOnBtn.Size = UDim2.new(0, 80, 0, 22)
pctOnBtn.Position = UDim2.new(0, 108, 0, 2)
pctOnBtn.BackgroundColor3 = Color3.fromRGB(80, 50, 100)
pctOnBtn.BorderSizePixel = 0
pctOnBtn.Text = "ON"
pctOnBtn.TextColor3 = Color3.fromRGB(230, 210, 240)
pctOnBtn.Font = Enum.Font.GothamBold
pctOnBtn.TextSize = 11
pctOnBtn.Parent = pctPanel
Instance.new("UICorner", pctOnBtn).CornerRadius = UDim.new(0, 5)

local pctValsLbl = Instance.new("TextLabel")
pctValsLbl.Size = UDim2.new(0, 120, 0, 18)
pctValsLbl.Position = UDim2.new(0, 8, 0, 32)
pctValsLbl.BackgroundTransparency = 1
pctValsLbl.Text = "ค่าพลัง (PCT):"
pctValsLbl.TextColor3 = Color3.fromRGB(200, 180, 220)
pctValsLbl.Font = Enum.Font.GothamMedium
pctValsLbl.TextSize = 10
pctValsLbl.TextXAlignment = Enum.TextXAlignment.Left
pctValsLbl.Parent = pctPanel

local pctBtnRow = Instance.new("Frame")
pctBtnRow.Size = UDim2.new(1, -12, 0, 32)
pctBtnRow.Position = UDim2.new(0, 6, 0, 54)
pctBtnRow.BackgroundTransparency = 1
pctBtnRow.Parent = pctPanel

local pctButtons = {}
local pctOptions = { 8, 10, 13, 15 }
for i, p in ipairs(pctOptions) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.24, -4, 1, 0)
    b.Position = UDim2.new((i-1) * 0.25, 0, 0, 0)
    b.BackgroundColor3 = Color3.fromRGB(60, 40, 60)
    b.BorderSizePixel = 0
    b.Text = p .. "%"
    b.TextColor3 = Color3.fromRGB(220, 200, 240)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.Parent = pctBtnRow
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    pctButtons[i] = b

    b.MouseButton1Click:Connect(function()
        AutoState.pwrCycleIdx = i + 1
        for j, pb in ipairs(pctButtons) do
            if j == i then
                pb.BackgroundColor3 = Color3.fromRGB(160, 80, 200)
                pb.TextColor3 = Color3.fromRGB(255, 240, 255)
            else
                pb.BackgroundColor3 = Color3.fromRGB(60, 40, 60)
                pb.TextColor3 = Color3.fromRGB(220, 200, 240)
            end
        end
        updateAutoStats()
        addLog(("[PCT] เลือก %d%%"):format(p), COL.WARN)
    end)
end

-- ═══════ ARM/LEARN/SIDE PANEL ═══════
local armPanel = Instance.new("Frame")
armPanel.Size = UDim2.new(1, -12, 0, 70)
armPanel.Position = UDim2.new(0, 6, 0, 354)
armPanel.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
armPanel.BorderSizePixel = 0
armPanel.Parent = frame
Instance.new("UICorner", armPanel).CornerRadius = UDim.new(0, 6)
table.insert(hideRefs, armPanel)

local armStroke = Instance.new("UIStroke")
armStroke.Color = Color3.fromRGB(120, 160, 220)
armStroke.Thickness = 1
armStroke.Transparency = 0.4
armStroke.Parent = armPanel

local armTitle = Instance.new("TextLabel")
armTitle.Size = UDim2.new(1, -12, 0, 16)
armTitle.Position = UDim2.new(0, 8, 0, 2)
armTitle.BackgroundTransparency = 1
armTitle.Text = "  AUTO (ARM + LEARN + SIDE)"
armTitle.TextColor3 = Color3.fromRGB(180, 200, 240)
armTitle.Font = Enum.Font.GothamBold
armTitle.TextSize = 10
armTitle.TextXAlignment = Enum.TextXAlignment.Left
armTitle.Parent = armPanel

local function mkAutoBtn(x, w, text, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w, 0, 32)
    b.Position = UDim2.new(0, x, 0, 22)
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.fromRGB(230, 230, 240)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.Parent = armPanel
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local armBtn   = mkAutoBtn(6,   130, "ARM: OFF",   Color3.fromRGB(60, 30, 40))
local learnBtn = mkAutoBtn(142, 130, "LEARN: OFF", Color3.fromRGB(40, 40, 60))
local tuneBtn  = mkAutoBtn(278, 130, "TUNE",       Color3.fromRGB(40, 60, 80))
local sideBtn  = mkAutoBtn(414, 130, "SIDE: ON",   Color3.fromRGB(30, 80, 50))

local autoStatLbl = Instance.new("TextLabel")
autoStatLbl.Size = UDim2.new(1, -12, 0, 14)
autoStatLbl.Position = UDim2.new(0, 8, 0, 56)
autoStatLbl.BackgroundTransparency = 1
autoStatLbl.Text = "  ready"
autoStatLbl.TextColor3 = Color3.fromRGB(180, 200, 220)
autoStatLbl.Font = Enum.Font.Code
autoStatLbl.TextSize = 10
autoStatLbl.TextXAlignment = Enum.TextXAlignment.Left
autoStatLbl.Parent = armPanel

-- ═══════ STATS ═══════
local statsFrame = Instance.new("Frame")
statsFrame.Size = UDim2.new(1, -12, 0, 84)
statsFrame.Position = UDim2.new(0, 6, 0, 430)
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

local curFrame = Instance.new("Frame")
curFrame.Size = UDim2.new(1, -12, 0, 90)
curFrame.Position = UDim2.new(0, 6, 0, 520)
curFrame.BackgroundColor3 = Color3.fromRGB(22, 16, 32)
curFrame.BorderSizePixel = 0
curFrame.Parent = frame
Instance.new("UICorner", curFrame).CornerRadius = UDim.new(0, 6)
table.insert(hideRefs, curFrame)

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
btnRow.Size = UDim2.new(1, -12, 0, 36)
btnRow.Position = UDim2.new(0, 6, 0, 616)
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

local logTitle = Instance.new("TextLabel")
logTitle.Size = UDim2.new(1, -12, 0, 16)
logTitle.Position = UDim2.new(0, 6, 0, 658)
logTitle.BackgroundTransparency = 1
logTitle.Text = "  RAW LOG"
logTitle.TextColor3 = Color3.fromRGB(140, 180, 220)
logTitle.Font = Enum.Font.GothamBold
logTitle.TextSize = 10
logTitle.TextXAlignment = Enum.TextXAlignment.Left
logTitle.Parent = frame
table.insert(hideRefs, logTitle)

local logScroll = Instance.new("ScrollingFrame")
logScroll.Size = UDim2.new(1, -12, 1, -684)
logScroll.Position = UDim2.new(0, 6, 0, 676)
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
toggleBtn.Size = UDim2.new(0, 52, 0, 52)
toggleBtn.Position = UDim2.new(1, -68, 0.5, -26)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = "FK"
toggleBtn.TextColor3 = Color3.fromRGB(120, 200, 255)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 13
toggleBtn.Parent = gui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 26)

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
    REF=Color3.fromRGB(255,140,220), AP=Color3.fromRGB(120,255,180),
    GREEN=Color3.fromRGB(0,255,120),
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

local function updateAutoStats()
    local rate = 0
    if AutoState.fired > 0 then
        rate = AutoState.goals / AutoState.fired * 100
    end
    local nB, nR = 0, 0
    for _ in pairs(LearnState.buckets) do nB = nB + 1 end
    for _ in pairs(RefShots) do nR = nR + 1 end
    local e = PWR_CYCLE[AutoState.pwrCycleIdx]
    autoStatLbl.Text = ("  fired %d | goal %d | %.0f%% | B:%d R:%d | PCT:%s | AP:%s | GR:%s")
        :format(AutoState.fired, AutoState.goals, rate,
                nB, nR, e.label,
                AutoPower.enabled and ("ON " .. AutoPower.powerInput) or "OFF",
                Green.autoGreen and "ON" or "OFF")
end

local function updateStats()
    local acc = "0.0%"
    if State.MyShots > 0 then
        acc = ("%.1f%%"):format(State.Goals / State.MyShots * 100)
    end
    local scoreStr = ("%d - %d"):format(State.ScoreA or 0, State.ScoreB or 0)
    if State.RoundLimit then
        scoreStr = scoreStr .. ("  R:%d/%d"):format(State.Round or 0, State.RoundLimit)
    end
    local turnStr
    if State.MyTurn then
        turnStr = "<font color='#78ff78'><b>YOUR TURN</b></font>"
    else
        local who = State.ShooterUserId and getPlayerName(State.ShooterUserId) or "?"
        turnStr = "<font color='#888'>wait</font> (" .. tostring(who):sub(1,14) .. ")"
    end
    statsLbl.Text = ("  <b>MY:</b> %d  <b>GOAL:</b> <font color='#78ff78'>%d</font>  <b>OUT:</b> <font color='#ff6464'>%d</font>  <b>ACC:</b> %s\n  <b>SCORE:</b> %s  <b>PHASE:</b> %s\n  <b>TURN:</b> %s")
        :format(State.MyShots, State.Goals, State.Outs, acc,
                scoreStr, State.MatchPhase or "?", turnStr)
end

local function updateCurrent()
    local tag = (State.CurrentShooter == LP.UserId) and "[ME]" or "[OTHER]"
    local L1 = ("  <b>%s SHOT — %s</b>"):format(tag, State.CurrentShooterName or "?")
    local L2 = "  (no payload)"
    if State.CurrentPayload then
        local p = State.CurrentPayload
        L2 = ("  leg=%s pwr=%s prec=%s"):format(
            tostring(p.leg), tostring(p.power), tostring(p.precision))
    end
    local L3 = "  (waiting kick)"
    if State.KickData then
        local k = State.KickData
        L3 = ("  dist=%.2fm angle=%.1f")
            :format(k.distanceMeters or 0, k.angleDegrees or 0)
    end
    curLbl.Text = L1 .. "\n" .. L2 .. "\n" .. L3
end

-- ═══════ FIRE: AUTO POWER ═══════
local function fireAutoPower()
    if not FreeKickRemote then return end
    if AutoPower.lastFireTime > 0
        and (tick() - AutoPower.lastFireTime) < 3 then
        return
    end
    AutoPower.lastFireTime = tick()

    local payload = {
        leg          = AutoPower.lastLeg,
        aimYaw       = AutoState.aimYaw,
        power        = AutoPower.powerValue,
        contactX     = AutoPower.lastContactX,
        contactY     = AutoPower.lastContactY,
        precision    = AutoState.precision,
        contactDelay = AutoState.contactDelay,
    }

    addLog(("[AP] ยิง power=%s → %.5f")
        :format(AutoPower.powerInput, AutoPower.powerValue), COL.AP)

    task.spawn(function()
        pcall(function() FreeKickRemote:FireServer("BeginShotVisual") end)
        task.wait(AutoState.visualToBall)
        pcall(function() FreeKickRemote:FireServer("PrepareBall") end)
        task.wait(0.15)
        pcall(function()
            FreeKickRemote:FireServer("Shoot", payload)
        end)
    end)
end

-- ═══════ FIRE: GREEN ═══════
local function fireGreen()
    if not FreeKickRemote then return end
    if Green.lastFireTime > 0 and (tick() - Green.lastFireTime) < GREEN_COOLDOWN then
        return
    end
    local yaw = getGreenAimYaw()
    if not yaw then
        addLog("[GREEN] no valid zone → skip", COL.WARN)
        return
    end
    Green.lastFireTime = tick()

    local payload = {
        leg          = AutoPower.lastLeg,
        aimYaw       = yaw,
        power        = AutoPower.powerValue,
        contactX     = AutoPower.lastContactX,
        contactY     = AutoPower.lastContactY,
        precision    = AutoState.precision,
        contactDelay = AutoState.contactDelay,
    }

    addLog(("[GREEN] ยิง power=%s → %.5f yaw=%.3f")
        :format(AutoPower.powerInput, AutoPower.powerValue, yaw), COL.GREEN)

    task.spawn(function()
        pcall(function() FreeKickRemote:FireServer("BeginShotVisual") end)
        task.wait(AutoState.visualToBall)
        pcall(function() FreeKickRemote:FireServer("PrepareBall") end)
        task.wait(0.15)
        pcall(function()
            FreeKickRemote:FireServer("Shoot", payload)
        end)
    end)
end

-- ═══════ HOOK OUTGOING ═══════
if CAP.hookmetamethod and CAP.getnamecallmethod then
    local ok, err = pcall(function()
        local oldNC
        oldNC = hookmetamethod(game, "__namecall", function(self, ...)
            local result = oldNC(self, ...)
            if warmup then return result end
            local method = getnamecallmethod()
            local isFire = (method == "FireServer")
            if not isFire then return result end
            if typeof(self) == "Instance" then
                local argsSnap = table.pack(...)
                local remote = self
                task.spawn(function()
                    pcall(function()
                        local argStr, typeStr = fmtArgs(argsSnap)
                        local short = remote:GetFullName()
                            :gsub("ReplicatedStorage%.", "")
                            :gsub("ReplicatedFirst%.", "")
                        counters[remote.Name] = (counters[remote.Name] or 0) + 1
                        addLog(("%s → %s(%d:%s) x%d %s")
                            :format(ts(), short, argsSnap.n, typeStr,
                                    counters[remote.Name], argStr), COL.OUT)

                        if remote == FreeKickRemote then
                            local action = argsSnap[1]
                            local payload = argsSnap[2]
                            if action == "Shoot" and type(payload) == "table" then
                                State.MyShots = State.MyShots + 1
                                State.ShotIndex = State.ShotIndex + 1
                                State.CurrentPayload = payload
                                State.MyTurn = false
                                if payload.contactY ~= nil then
                                    AutoPower.lastContactY = tonumber(payload.contactY) or AutoPower.lastContactY
                                    AutoPower.hasReference = true
                                end
                                if payload.contactX ~= nil then
                                    AutoPower.lastContactX = tonumber(payload.contactX) or AutoPower.lastContactX
                                end
                                if payload.leg ~= nil then
                                    AutoPower.lastLeg = tostring(payload.leg)
                                end
                                apStatus.Text = ("  locked: cY=%.3f cX=%.3f leg=%s")
                                    :format(AutoPower.lastContactY,
                                            AutoPower.lastContactX,
                                            AutoPower.lastLeg)
                                updateStats()
                                updateCurrent()
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

-- ═══════ HOOK INCOMING ═══════
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

        task.spawn(function()
            pcall(function()
                local argStr, typeStr = fmtArgs(argsSnap)
                counters[remote.Name] = (counters[remote.Name] or 0) + 1
                local color = COL.IN
                if action == "GoalConfirmed" then color = COL.GOAL
                elseif action == "OutOfPlay" then color = COL.MISS end
                addLog(("%s ← %s(%d:%s) x%d %s")
                    :format(ts(), remote.Name, argsSnap.n, typeStr,
                            counters[remote.Name], argStr), color)

                if action == "MatchState" and type(payload) == "table" then
                    if payload.matchId then State.MatchId = payload.matchId end
                    if payload.scoreA then State.ScoreA = payload.scoreA end
                    if payload.scoreB then State.ScoreB = payload.scoreB end
                    if payload.regulationRoundLimit then
                        State.RoundLimit = payload.regulationRoundLimit end
                    if payload.round then State.Round = payload.round end
                    if payload.shooterUserId then
                        State.ShooterUserId = payload.shooterUserId end
                    if payload.state then State.MatchPhase = payload.state end
                    refreshMyTurn()
                    updateStats()

                elseif action == "KickReady" and type(payload) == "table" then
                    State.KickData = payload
                    if payload.shooterUserId then
                        State.ShooterUserId = payload.shooterUserId
                        State.MyTurn = (payload.shooterUserId == LP.UserId)
                    end
                    updateCurrent()
                    updateStats()

                elseif action == "GoalConfirmed" then
                    State.Goals = State.Goals + 1
                    State.MyTurn = false
                    updateStats()

                elseif action == "OutOfPlay" then
                    State.Outs = State.Outs + 1
                    State.MyTurn = false
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
end

for _, c in ipairs(containers) do pcall(hookContainer, c) end

-- ═══════ AUTO LOOPS ═══════
task.spawn(function()
    while true do
        task.wait(0.15)
        if not AutoPower.enabled then continue end
        if warmup then continue end
        if State.PresentationHolding then continue end
        if State.MatchPhase ~= "Shoot" then continue end
        if State.ShooterUserId ~= LP.UserId then continue end
        if (tick() - AutoPower.lastFireTime) < COOLDOWN then continue end
        task.wait(math.random() * 0.5 + 0.3)
        if not AutoPower.enabled then continue end
        if State.MatchPhase ~= "Shoot" then continue end
        fireAutoPower()
    end
end)

task.spawn(function()
    while true do
        task.wait(0.15)
        if not Green.autoGreen then continue end
        if not Green.zoneOn then continue end
        if warmup then continue end
        if State.PresentationHolding then continue end
        if State.MatchPhase ~= "Shoot" then continue end
        if State.ShooterUserId ~= LP.UserId then continue end
        if (tick() - Green.lastFireTime) < GREEN_COOLDOWN then continue end
        task.wait(math.random() * 0.4 + 0.3)
        if not Green.autoGreen then continue end
        if State.MatchPhase ~= "Shoot" then continue end
        fireGreen()
    end
end)

-- ═══════ BUTTON WIRING ═══════
apToggle.MouseButton1Click:Connect(function()
    AutoPower.enabled = not AutoPower.enabled
    if AutoPower.enabled then
        apToggle.Text = "ON"
        apToggle.BackgroundColor3 = Color3.fromRGB(30, 120, 70)
    else
        apToggle.Text = "OFF"
        apToggle.BackgroundColor3 = Color3.fromRGB(60, 30, 40)
    end
    updateAutoStats()
end)

apPwrBox.FocusLost:Connect(function()
    local n = tonumber(apPwrBox.Text)
    if n then
        n = clampNum(n, 8, 99.999)
        AutoPower.powerValue = n / 100
        AutoPower.powerInput = tostring(n)
        apPwrBox.Text = AutoPower.powerInput
        apPreview.Text = ("= %.5f"):format(AutoPower.powerValue)
    else
        apPwrBox.Text = AutoPower.powerInput
    end
end)

-- GREEN buttons
grAutoBtn.MouseButton1Click:Connect(function()
    Green.autoGreen = not Green.autoGreen
    if Green.autoGreen then
        grAutoBtn.Text = "AUTO GREEN: ON"
        grAutoBtn.BackgroundColor3 = Color3.fromRGB(30, 120, 70)
    else
        grAutoBtn.Text = "AUTO GREEN: OFF"
        grAutoBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 40)
    end
    updateAutoStats()
end)

grZoneBtn.MouseButton1Click:Connect(function()
    Green.zoneOn = not Green.zoneOn
    if Green.zoneOn then
        grZoneBtn.Text = "ZONE: ON"
        grZoneBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 60)
        greenFrame.Visible = (Green.x2 > Green.x1 or Green.y2 > Green.y1)
    else
        grZoneBtn.Text = "ZONE: OFF"
        grZoneBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
        greenFrame.Visible = false
    end
    updateGrStatus()
    updateAutoStats()
end)

local function updateGrStatus()
    if Green.x2 > Green.x1 or Green.y2 > Green.y1 then
        grStatus.Text = ("  zone: [%d,%d → %d,%d] | %s")
            :format(Green.x1, Green.y1, Green.x2, Green.y2,
                    Green.locked and "LOCKED" or "unlock → drag")
    else
        grStatus.Text = ("  zone: (empty) | %s")
            :format(Green.locked and "LOCKED" or "unlock → drag on screen")
    end
end

grLockBtn.MouseButton1Click:Connect(function()
    Green.locked = not Green.locked
    if Green.locked then
        grLockBtn.Text = "LOCKED"
        grLockBtn.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
        greenCatcher.Visible = false
    else
        grLockBtn.Text = "UNLOCK"
        grLockBtn.BackgroundColor3 = Color3.fromRGB(80, 60, 30)
        if Green.zoneOn then
            greenCatcher.Visible = true
        end
    end
    updateGrStatus()
end)

grClearBtn.MouseButton1Click:Connect(function()
    Green.x1 = 0; Green.y1 = 0; Green.x2 = 0; Green.y2 = 0
    greenFrame.Visible = false
    updateGrStatus()
end)

-- Zone on → enable catcher
local _grZoneOrig = grZoneBtn.MouseButton1Click
-- Override: แก้ catcher ตาม zoneOn + locked
task.spawn(function()
    while true do
        task.wait(0.5)
        if Green.zoneOn and not Green.locked then
            greenCatcher.Visible = true
        else
            greenCatcher.Visible = false
        end
        -- update frame visibility
        if Green.zoneOn then
            greenFrame.Visible = (Green.x2 > Green.x1 or Green.y2 > Green.y1)
        else
            greenFrame.Visible = false
        end
    end
end)

-- Other buttons
pctOnBtn.MouseButton1Click:Connect(function()
    if AutoState.pwrCycleIdx == 1 then
        AutoState.pwrCycleIdx = 5
        pctOnBtn.Text = "ON"
        pctOnBtn.BackgroundColor3 = Color3.fromRGB(80, 50, 100)
    else
        AutoState.pwrCycleIdx = 1
        pctOnBtn.Text = "OFF"
        pctOnBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    end
    updateAutoStats()
end)

armBtn.MouseButton1Click:Connect(function()
    AutoState.armed = not AutoState.armed
    if AutoState.armed then
        armBtn.Text = "ARM: ON"
        armBtn.BackgroundColor3 = Color3.fromRGB(30, 90, 50)
    else
        armBtn.Text = "ARM: OFF"
        armBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 40)
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

clearBtn.MouseButton1Click:Connect(function()
    for _, c in ipairs(logScroll:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    allLogs = {}; counters = {}
    State.MyShots = 0; State.TotalShots = 0; State.Goals = 0
    State.Outs = 0; State.ShotIndex = 0; State.PlayerStats = {}
    updateStats()
    updateAutoStats()
end)

copyBtn.MouseButton1Click:Connect(function()
    local lines = {
        "=== FK AUTO LOG ===",
        "MyShots=" .. State.MyShots .. " Goals=" .. State.Goals .. " Outs=" .. State.Outs,
        "AUTO POWER: " .. tostring(AutoPower.enabled) .. " input=" .. AutoPower.powerInput,
        "GREEN: auto=" .. tostring(Green.autoGreen) .. " zone=" .. tostring(Green.zoneOn) .. " locked=" .. tostring(Green.locked),
        "zone: [" .. Green.x1 .. "," .. Green.y1 .. " → " .. Green.x2 .. "," .. Green.y2 .. "]",
    }
    for _, l in ipairs(allLogs) do table.insert(lines, l) end
    local txt = table.concat(lines, "\n")
    if CAP.setclipboard then pcall(setclipboard, txt) end
    addLog("[COPY] " .. #txt .. " chars", COL.WARN)
end)

-- ═══════ BOOT ═══════
updateStats()
updateAutoStats()
updateGrStatus()
addLog(ts() .. " FREEKICK AUTO + GREEN", COL.HDR)
addLog(ts() .. " hooked: " .. hookedCount
    .. " | hookmm: " .. (CAP.hookmetamethod and "Y" or "N"), COL.MISC)

task.spawn(function()
    task.wait(WARMUP_TIME)
    warmup = false
    addLog(ts() .. " [warmup DONE]", COL.WARN)
end)

print("[FK AUTO] loaded — GREEN ready")
