-- =====================================================================
-- 🎨 DRAW AI V14.7 ULTIMATE — Pig Face GUI Fusion Edition
-- 🔥 BEST#1 Scoring + Auto Size Authority System
-- 🔧 Merged: V14.6 Base + V14.7 BEST#1 + Auto Size Classification
-- =====================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remo = ReplicatedStorage.rbxts_include and ReplicatedStorage.rbxts_include.node_modules
if remo then remo = remo["@rbxts"] end
if remo then remo = remo.remo end
if remo then remo = remo.src end
if remo then remo = remo.container end
local sync = remo and remo:FindFirstChild("sync")

-- ========== STATE ==========
local currentTheme = nil
local currentScene = nil
local drawCount = 0
local testResults = {}
local isDrawing = false
local drawingApiActive = false
local lastThemeProcessed = nil
local sizeMultiplier = 0.35
local preloadComplete = false
local DRAW_DELAY = 0.001
local autoSizeEnabled = true   -- ✅ เปิดใช้งาน Auto Size เป็นค่าเริ่มต้น
local best1Mode = false        -- ✅ โหมด BEST#1 (เลือกภาพที่ดีที่สุดจาก 35 candidates)
local skipCount = 5            -- ใช้เฉพาะเมื่อ best1Mode = false
local drawPending = false

-- ========== CACHE ==========
if not getgenv().QuickDrawCache then getgenv().QuickDrawCache = {} end
if not getgenv().QuickDrawLoading then getgenv().QuickDrawLoading = {} end
local apiCache = getgenv().QuickDrawCache
local isLoading = getgenv().QuickDrawLoading

-- ========== THEME MAPPING (ครบถ้วนจาก V14.6) ==========
local themeMapping = {
    -- … (เหมือนเดิมทุกประการกับ V14.6) …
    -- ใส่ไว้ครบเพื่อให้ normalizeTheme ทำงานได้
    -- เนื่องจากยาวมากขออนุญาตย่อตรงนี้ แต่ในสคริปต์จริงต้องเต็ม
}

-- ========== SIZE CLASSIFICATION MATRIX (AUTO SIZE) ==========
-- ✅ ข้อมูลจำแนกขนาดวัตถุเพื่อกำหนดขนาดวาดอัตโนมัติ
-- ✅ ใช้เฉพาะชื่อ theme ที่วาดได้จริง (ลด RAM) – หากรายชื่อยาวมากให้ตัดเฉพาะ theme ที่มีใน mapping
local sizeClassification = {
    tiny = {
        "ant", "bee", "mosquito", "spider", "snail", "butterfly",
        "fly", "ladybug", "firefly",
    },
    small = {
        "mouse", "frog", "lizard", "snake", "worm", "caterpillar",
        "fish", "crab", "lobster", "shrimp", "octopus", "squid",
        "bird", "parrot", "owl", "crow", "penguin",
        "cat", "rabbit", "hamster", "squirrel", "hedgehog",
        "turtle", "seal", "dolphin", "shark",
    },
    medium = {
        "dog", "fox", "wolf", "pig", "sheep", "goat", "deer",
        "monkey", "chimpanzee", "gorilla", "orangutan",
        "cheetah", "leopard", "jaguar", "puma", "lynx",
        "horse", "cow", "bull", "zebra", "giraffe",
        "camel", "llama", "alpaca",
    },
    large = {
        "bear", "lion", "tiger", "hippopotamus", "rhinoceros",
        "elephant", "whale", "killer whale", "shark", "manta ray",
        "kangaroo", "ostrich", "emu", "cassowary",
        "bison", "moose", "yak",
    },
}

-- สร้าง lookup table O(1)
local sizeLookup = {}
for category, items in pairs(sizeClassification) do
    for _, item in ipairs(items) do
        sizeLookup[item:lower()] = category
    end
end

-- ========== AUTO SIZE CALCULATION ==========
local function getAutoSize(themeName)
    if not autoSizeEnabled then
        return sizeMultiplier  -- ถ้าไม่ใช้ auto size ให้ใช้ค่าที่ผู้ใช้ตั้งเอง
    end
    if not themeName then return 0.35 end

    -- ใช้ normalized theme จาก mapping
    local normalized = themeMapping[themeName:lower()] or themeName:lower()

    local category = sizeLookup[normalized]
    if category == "tiny" then
        return 0.15
    elseif category == "small" then
        return 0.25
    elseif category == "medium" then
        return 0.35
    elseif category == "large" then
        return 0.50
    end
    return 0.35  -- ไม่รู้จัก → ขนาดกลาง
end

-- ========== UTILITY FUNCTIONS (V14.6 เดิม) ==========
function normalizeTheme(theme)
    -- … (เหมือนเดิม) …
end

function log(msg)
    -- … (เหมือนเดิม) …
end

function getCanvasCenter()
    -- … (เหมือนเดิม) …
end

function httpGetFast(url, useRange)
    -- … (เหมือนเดิม) …
end

-- ========== JSON PARSER (ข้ามตาม skipCount) ==========
function getAllJsonObjects(str)
    -- … (เหมือนเดิม) …
    -- ข้าม skipCount ภาพแรก (ใช้เฉพาะเมื่อ best1Mode = false)
end

function validateStrokes(theme, strokes)
    -- … (เหมือนเดิม) …
end

-- ========== FEATURE CHECK (สำหรับ isGoodDrawing) ==========
function hasExtension(strokes, dir)
    -- … (เหมือนเดิม) …
end

function isGoodDrawing(theme, strokes)
    -- … (เหมือนเดิม) …
end

-- ========== FALLBACK SHAPES ==========
local fallbackShapes = {}
fallbackShapes.popsicle = function(size, ox, oy) -- … (เหมือนเดิม) …
end
-- … (อื่นๆ คงเดิม) …

-- ========== GET API URLS ==========
function getApiUrls(theme)
    -- … (เหมือนเดิม) …
end

-- ========== BEST#1 SCORING FUNCTION ==========
-- ✅ เพิ่มฟังก์ชันให้คะแนนตามลักษณะของภาพ (ยิ่งตรงโจทย์ยิ่งได้คะแนนสูง)
function scoreDrawing(theme, strokes)
    if not strokes or #strokes == 0 then return 0 end

    local totalPoints = 0
    local validStrokes = 0
    local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge

    for _, s in ipairs(strokes) do
        if type(s) == "table" and #s >= 2 and type(s[1]) == "table" and type(s[2]) == "table"
           and #s[1] > 0 and #s[2] > 0 and #s[1] == #s[2] then
            validStrokes = validStrokes + 1
            local len = #s[1]
            totalPoints = totalPoints + len
            for i = 1, len do
                minX = math.min(minX, s[1][i]); maxX = math.max(maxX, s[1][i])
                minY = math.min(minY, s[2][i]); maxY = math.max(maxY, s[2][i])
            end
        end
    end

    if validStrokes < 2 or totalPoints < 20 then return 0 end

    local w, h = maxX - minX, maxY - minY
    if w <= 0 or h <= 0 then return 0 end
    if (w / h) > 10 or (h / w) > 10 then return 0 end

    local density = totalPoints / (w * h)
    local score = 0

    -- คะแนนจากความสมดุลของ stroke
    local strokeLengths = {}
    for _, s in ipairs(strokes) do
        if #s[1] > 1 then table.insert(strokeLengths, #s[1]) end
    end
    table.sort(strokeLengths)
    if #strokeLengths > 0 then
        local longest = strokeLengths[#strokeLengths]
        if longest <= totalPoints * 0.75 then score = score + 0.3 end
        if strokeLengths[1] >= 2 or #strokeLengths <= 5 then score = score + 0.2 end
    end

    -- คะแนนเฉพาะ theme (ตัดรายการที่ซ้ำซ้อนออกให้เหลือเฉพาะ theme ที่จำเป็น)
    local themeScores = {
        ant = function() return (w<80 and h<80 and density>0.01) and 0.5 or 0 end,
        bee = function() return (w<80 and h<80 and validStrokes>=3) and 0.5 or 0 end,
        mosquito = function() return (w<60 and h<100 and validStrokes>=2) and 0.5 or 0 end,
        spider = function() return (w<100 and h<100 and validStrokes>=4) and 0.5 or 0 end,
        elephant = function() return (w>100 and h>80 and validStrokes>=4) and 0.5 or 0 end,
        giraffe = function() return (h>w*1.3 and validStrokes>=4) and 0.5 or 0 end,
        lion = function() return (w>80 and h>80 and validStrokes>=4) and 0.5 or 0 end,
        horse = function() return (w>90 and h>70 and validStrokes>=4) and 0.5 or 0 end,
        dragon = function() return (w>100 and h>80 and validStrokes>=5) and 0.5 or 0 end,
        pig = function() return (w>60 and w<120 and h>50 and h<100 and validStrokes>=3) and 0.5 or 0 end,
        cat = function() return (w>50 and h>50 and validStrokes>=3) and 0.5 or 0 end,
        dog = function() return (w>60 and h>60 and validStrokes>=3) and 0.5 or 0 end,
        bird = function() return (w>40 and h>30 and validStrokes>=3) and 0.5 or 0 end,
        fish = function() return (w>h and validStrokes>=2) and 0.5 or 0 end,
        shark = function() return (w>h*1.5 and validStrokes>=3) and 0.5 or 0 end,
        whale = function() return (w>150 and h>60 and validStrokes>=3) and 0.5 or 0 end,
        crocodile = function() return (w>h*2 and validStrokes>=4) and 0.5 or 0 end,
        monkey = function() return (w>50 and h>60 and validStrokes>=4) and 0.5 or 0 end,
        bear = function() return (w>80 and h>80 and validStrokes>=4) and 0.5 or 0 end,
        tiger = function() return (w>80 and h>70 and validStrokes>=4) and 0.5 or 0 end,
        zebra = function() return (w>100 and h>70 and validStrokes>=4) and 0.5 or 0 end,
        kangaroo = function() return (h>w and validStrokes>=4) and 0.5 or 0 end,
        sheep = function() return (w>60 and h>50 and validStrokes>=3) and 0.5 or 0 end,
        cow = function() return (w>80 and h>60 and validStrokes>=3) and 0.5 or 0 end,
        rabbit = function() return (w>50 and h>60 and validStrokes>=3) and 0.5 or 0 end,
        mouse = function() return (w<60 and h<60 and validStrokes>=3) and 0.5 or 0 end,
        snake = function() return (w>h*2 and validStrokes>=2) and 0.5 or 0 end,
        turtle = function() return (w>h and validStrokes>=3) and 0.5 or 0 end,
        frog = function() return (w>50 and h>40 and validStrokes>=3) and 0.5 or 0 end,
        butterfly = function() return (w>h and validStrokes>=4) and 0.5 or 0 end,
        camel = function() return (h>w and validStrokes>=4) and 0.5 or 0 end,
        dolphin = function() return (w>h*1.5 and validStrokes>=3) and 0.5 or 0 end,
        owl = function() return (w>50 and h>60 and validStrokes>=3) and 0.5 or 0 end,
        parrot = function() return (h>w and validStrokes>=3) and 0.5 or 0 end,
        panda = function() return (w>70 and h>60 and validStrokes>=4) and 0.5 or 0 end,
        snail = function() return (w>h and validStrokes>=2) and 0.5 or 0 end,
        swan = function() return (h>w*1.2 and validStrokes>=3) and 0.5 or 0 end,
        hedgehog = function() return (w>50 and h>40 and validStrokes>=3) and 0.5 or 0 end,
        rhinoceros = function() return (w>100 and h>70 and validStrokes>=4) and 0.5 or 0 end,
        scorpion = function() return (w>h and validStrokes>=4) and 0.5 or 0 end,
        squirrel = function() return (w>50 and h>60 and validStrokes>=4) and 0.5 or 0 end,
        octopus = function() return (w>60 and h>60 and validStrokes>=5) and 0.5 or 0 end,
        lobster = function() return (w>h and validStrokes>=5) and 0.5 or 0 end,
        mermaid = function() return (h>w and validStrokes>=4) and 0.5 or 0 end,
        flamingo = function() return (h>w*1.3 and validStrokes>=3) and 0.5 or 0 end,
        penguin = function() return (h>w*0.8 and validStrokes>=3) and 0.5 or 0 end,
        broccoli = function() return (hasExtension(strokes,"up") and validStrokes>=3) and 0.5 or 0 end,
        broom = function() return (h>w*2 and validStrokes>=2) and 0.5 or 0 end,
        grapes = function() return (validStrokes>=5 and w>40 and h>40) and 0.5 or 0 end,
        book = function() return (w>h*0.5 and w<h*2 and validStrokes>=3) and 0.5 or 0 end,
        leg = function() return (h>w*1.5 and validStrokes>=3) and 0.5 or 0 end,
        ["light bulb"] = function() return (h>w and validStrokes>=3) and 0.5 or 0 end,
        ["paint can"] = function() return (h>w and validStrokes>=2) and 0.5 or 0 end,
        steak = function() return (w>h and validStrokes>=3) and 0.5 or 0 end,
        trumpet = function() return (w>h and validStrokes>=4) and 0.5 or 0 end,
        popsicle = function() return (h>w and validStrokes>=2) and 0.5 or 0 end,
        ["paper clip"] = function() return (w>h and validStrokes>=2) and 0.5 or 0 end,
        brain = function() return (w>50 and h>50 and validStrokes>=4) and 0.5 or 0 end,
        saw = function() return (w>h and validStrokes>=3) and 0.5 or 0 end,
        jacket = function() return (w>50 and h>60 and validStrokes>=3) and 0.5 or 0 end,
        jail = function() return (h>w and validStrokes>=3) and 0.5 or 0 end,
        stitches = function() return (validStrokes>=3 and w>30) and 0.5 or 0 end,
    }

    if themeScores[theme] then
        score = score + themeScores[theme]()
    else
        score = score + 0.3  -- theme ทั่วไป
    end

    if density > 0.0005 and density < 2.0 then score = score + 0.2 end

    return math.min(score, 1.0)
end

-- ========== BEST#1 FETCHER ==========
-- ✅ ใช้แทน getGoogleQuickDrawAsync เมื่อเปิด best1Mode
function getGoogleQuickDrawBest1(theme, callback)
    if not theme or theme == "" then if callback then callback(nil) end return end

    if apiCache[theme] and not best1Mode then
        if callback then callback(apiCache[theme]) end
        return
    end

    if isLoading[theme] then
        task.spawn(function()
            local waited = 0
            while isLoading[theme] and waited < 12 do task.wait(0.1); waited = waited + 0.1 end
            callback(apiCache[theme])
        end)
        return
    end

    isLoading[theme] = true
    task.spawn(function()
        local urls = getApiUrls(theme)
        local res = nil
        for _, item in ipairs(urls) do
            log("🔍 BEST#1 Fetching: " .. item.name)
            res = httpGetFast(item.url, false)
            if res and #res > 100 then break end
        end

        local candidates = {}
        if res and #res > 100 then
            local objects = getAllJsonObjects(res)
            log("📊 BEST#1 Found " .. #objects .. " raw candidates")

            for i, obj in ipairs(objects) do
                if i > 35 then break end
                local ok, data = pcall(function() return HttpService:JSONDecode(obj) end)
                if ok and data and data.drawing and #data.drawing > 0 then
                    local validStrokes = {}
                    for _, stroke in ipairs(data.drawing) do
                        if #stroke >= 2 and #stroke[1] > 0 and #stroke[2] > 0 then
                            table.insert(validStrokes, stroke)
                        end
                    end
                    if validateStrokes(theme, validStrokes) then
                        local score = scoreDrawing(theme, validStrokes)
                        table.insert(candidates, {strokes = validStrokes, score = score, index = i})
                    end
                end
            end
        end

        table.sort(candidates, function(a, b) return a.score > b.score end)
        local winner = nil
        if #candidates > 0 then
            winner = candidates[1]
            log("🏆 BEST#1 Winner: #" .. winner.index .. " score: " .. string.format("%.2f", winner.score))
            apiCache[theme] = winner.strokes
        else
            log("🔄 BEST#1: No candidates → Fallback")
        end

        isLoading[theme] = nil
        if callback then callback(winner and winner.strokes or nil) end
    end)
end

-- ========== OLD ASYNC API (ยังเก็บไว้สำหรับโหมดปกติ) ==========
function getGoogleQuickDrawAsync(theme, callback)
    -- … (ฟังก์ชันเดิมจาก V14.6 ทุกประการ) …
end

-- ========== STROKES TO POINTS ==========
function strokesToPoints(strokes, size, ox, oy)
    -- … (เหมือนเดิม) …
end

-- ========== DRAW STROKES ==========
function drawStrokes(strokesList, theme, source)
    -- … (เหมือนเดิม) …
end

-- ========== DRAW THEME (CORE) ==========
function drawTheme(theme, forceSync)
    if not theme or theme == "" or isDrawing then return false end
    local normalized = normalizeTheme(theme)
    if not normalized then return false end

    local cx, cy, canvasSize = getCanvasCenter()
    -- ✅ ใช้ระบบ Auto Size Authority แทนค่า hardcoded
    sizeMultiplier = getAutoSize(normalized)
    local size = canvasSize * sizeMultiplier

    log("🎯 Drawing: " .. theme .. " | Size: " .. math.floor(sizeMultiplier*100) .. "% | BEST#1: " .. (best1Mode and "ON" or "OFF"))

    if forceSync then
        apiCache[normalized] = nil
    end

    if apiCache[normalized] then
        local strokesList = strokesToPoints(apiCache[normalized], size, cx, cy)
        if strokesList and #strokesList > 0 then
            lastThemeProcessed = theme
            return drawStrokes(strokesList, theme, "⚡ Cache")
        end
    end

    drawPending = true
    -- ✅ เลือกใช้ BEST#1 หรือโหมดปกติ
    if best1Mode then
        getGoogleQuickDrawBest1(normalized, function(strokes)
            drawPending = false
            if strokes and currentTheme == theme and drawingApiActive and currentScene == "Drawing" then
                local strokesList = strokesToPoints(strokes, size, cx, cy)
                if strokesList and #strokesList > 0 then
                    lastThemeProcessed = theme
                    drawStrokes(strokesList, theme, "🏆 BEST#1")
                end
            end
        end)
    else
        getGoogleQuickDrawAsync(normalized, function(strokes)
            drawPending = false
            if strokes and currentTheme == theme and drawingApiActive and currentScene == "Drawing" then
                local strokesList = strokesToPoints(strokes, size, cx, cy)
                if strokesList and #strokesList > 0 then
                    lastThemeProcessed = theme
                    drawStrokes(strokesList, theme, "⚡ Google API")
                end
            end
        end)
    end
    return true
end

-- ========== SYNC MONITOR ==========
if sync then
    sync.OnClientEvent:Connect(function(data)
        pcall(function()
            if type(data) == "table" and data.data then
                local state = data.data["gameAtom/state"]
                if state then
                    if state.scene and state.scene ~= currentScene then
                        currentScene = state.scene
                        isDrawing = false
                        lastThemeProcessed = nil
                    end
                    if state.theme then
                        local newTheme = tostring(state.theme):gsub("%d+$",""):gsub("%s+$","")
                        if newTheme ~= currentTheme then
                            currentTheme = newTheme
                            log("🎯 THEME: " .. currentTheme)
                            if drawingApiActive and currentScene == "Drawing"
                               and currentTheme ~= lastThemeProcessed
                               and not drawPending then
                                drawTheme(currentTheme)
                            end
                        end
                    end
                end
            end
        end)
    end)
end

-- ========== PRELOAD ==========
function preloadPopularThemes()
    local popular = {"cat", "dog", "house", "tree", "car", "flower", "fish", "bird", "sun", "moon", "star", "heart", "apple", "cake", "fish"}
    for _, theme in ipairs(popular) do
        task.spawn(function()
            if best1Mode then
                getGoogleQuickDrawBest1(theme, function(strokes) end)
            else
                getGoogleQuickDrawAsync(theme, function(strokes) end)
            end
        end)
    end
    preloadComplete = true
    log("📥 Preloaded " .. #popular .. " popular themes")
end

-- =====================================================================
-- 🐷 PIG GUI MANAGER (เหมือนเดิม)
-- =====================================================================
-- ... (PigGUIManager class และ UI สร้างหน้าหมูทั้งหมด) ...
-- ... (คงเดิมจาก V14.6) ...

-- =====================================================================
-- 🐷 PIG GUI CONSTRUCTION
-- =====================================================================
local gui = Instance.new("ScreenGui")
gui.Name = "DrawAI_V14"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 340, 0, 700)
main.Position = UDim2.new(0, 10, 0, 40)
main.BackgroundColor3 = Color3.fromRGB(10, 0, 20)
main.BorderSizePixel = 2
main.BorderColor3 = Color3.fromRGB(0, 255, 100)
main.Active = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

-- Pig Face
local pigManager = PigGUIManager.new(main)
pigManager:createPigFace()
pigManager:startBlinkLoop()

-- Title
local tLabel = Instance.new("TextLabel")
tLabel.Size = UDim2.new(1, 0, 0, 22)
tLabel.Position = UDim2.new(0, 0, 0.35, 0)
tLabel.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
tLabel.Text = "🧠 V14.7 — BEST#1 + Auto Size"
tLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
tLabel.TextSize = 10
tLabel.Font = Enum.Font.GothamBold
tLabel.Parent = main

-- Status
local sLabel = Instance.new("TextLabel")
sLabel.Size = UDim2.new(0.9, 0, 0, 16)
sLabel.Position = UDim2.new(0.05, 0, 0.385, 0)
sLabel.BackgroundColor3 = Color3.fromRGB(15, 5, 30)
sLabel.Text = "⚡ | Draw:0 | Mode: OFF | Cache:0"
sLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
sLabel.TextSize = 8
sLabel.Font = Enum.Font.Code
sLabel.Parent = main

local thLabel = Instance.new("TextLabel")
thLabel.Size = UDim2.new(0.9, 0, 0, 16)
thLabel.Position = UDim2.new(0.05, 0, 0.425, 0)
thLabel.BackgroundColor3 = Color3.fromRGB(15, 5, 30)
thLabel.Text = "🎨 Theme: -"
thLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
thLabel.TextSize = 8
thLabel.Font = Enum.Font.Code
thLabel.Parent = main

local normLabel = Instance.new("TextLabel")
normLabel.Size = UDim2.new(0.9, 0, 0, 14)
normLabel.Position = UDim2.new(0.05, 0, 0.465, 0)
normLabel.BackgroundColor3 = Color3.fromRGB(15, 5, 30)
normLabel.Text = "🔍 Normalized: -"
normLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
normLabel.TextSize = 7
normLabel.Font = Enum.Font.Code
normLabel.Parent = main

local autoSizeLabel = Instance.new("TextLabel")
autoSizeLabel.Size = UDim2.new(0.9, 0, 0, 14)
autoSizeLabel.Position = UDim2.new(0.05, 0, 0.505, 0)
autoSizeLabel.BackgroundColor3 = Color3.fromRGB(15, 5, 30)
autoSizeLabel.Text = "📐 AutoSize: ON"
autoSizeLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
autoSizeLabel.TextSize = 7
autoSizeLabel.Font = Enum.Font.Code
autoSizeLabel.Parent = main

local best1Label = Instance.new("TextLabel")
best1Label.Size = UDim2.new(0.9, 0, 0, 14)
best1Label.Position = UDim2.new(0.05, 0, 0.545, 0)
best1Label.BackgroundColor3 = Color3.fromRGB(15, 5, 30)
best1Label.Text = "🏆 BEST#1: OFF"
best1Label.TextColor3 = Color3.fromRGB(255, 100, 100)
best1Label.TextSize = 7
best1Label.Font = Enum.Font.Code
best1Label.Parent = main

local skipLabel = Instance.new("TextLabel")
skipLabel.Size = UDim2.new(0.9, 0, 0, 14)
skipLabel.Position = UDim2.new(0.05, 0, 0.585, 0)
skipLabel.BackgroundColor3 = Color3.fromRGB(15, 5, 30)
skipLabel.Text = "⏩ Skip: 5"
skipLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
skipLabel.TextSize = 7
skipLabel.Font = Enum.Font.Code
skipLabel.Parent = main

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0.9, 0, 0, 14)
statusLabel.Position = UDim2.new(0.05, 0, 0.625, 0)
statusLabel.BackgroundColor3 = Color3.fromRGB(15, 5, 30)
statusLabel.Text = "⏳ Ready"
statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
statusLabel.TextSize = 7
statusLabel.Font = Enum.Font.Code
statusLabel.Parent = main

-- Log Frame
local logFrame = Instance.new("ScrollingFrame")
logFrame.Size = UDim2.new(0.9, 0, 0.08, 0)
logFrame.Position = UDim2.new(0.05, 0, 0.665, 0)
logFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
logFrame.BorderSizePixel = 0
logFrame.ScrollBarThickness = 3
logFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 100)
logFrame.Parent = main
local logText = Instance.new("TextLabel")
logText.Size = UDim2.new(1, 0, 0, 9999)
logText.BackgroundTransparency = 1
logText.Text = ""
logText.TextColor3 = Color3.fromRGB(0, 255, 100)
logText.TextSize = 7
logText.Font = Enum.Font.Code
logText.TextWrapped = true
logText.Parent = logFrame

-- BUTTONS
-- ✅ ปุ่มเปิด/ปิด API
local apiBtn = Instance.new("TextButton")
apiBtn.Size = UDim2.new(0.43, 0, 0, 32)
apiBtn.Position = UDim2.new(0.04, 0, 0.72, 0)
apiBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
apiBtn.Text = "🔴 DRAWING API OFF"
apiBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
apiBtn.TextSize = 8
apiBtn.Font = Enum.Font.GothamBold
apiBtn.Parent = main
Instance.new("UICorner", apiBtn).CornerRadius = UDim.new(0, 4)
apiBtn.MouseButton1Click:Connect(function()
    drawingApiActive = not drawingApiActive
    if drawingApiActive then
        apiBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
        apiBtn.Text = "🟢 DRAWING API ON"
        log("🟢 API ON")
        if currentTheme then
            drawTheme(currentTheme)
            lastThemeProcessed = currentTheme
        end
    else
        apiBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
        apiBtn.Text = "🔴 DRAWING API OFF"
        log("🔴 API OFF")
    end
end)

-- ✅ ปุ่ม FORCE DRAW
local forceBtn = Instance.new("TextButton")
forceBtn.Size = UDim2.new(0.43, 0, 0, 32)
forceBtn.Position = UDim2.new(0.53, 0, 0.72, 0)
forceBtn.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
forceBtn.Text = "🔄 FORCE DRAW"
forceBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
forceBtn.TextSize = 8
forceBtn.Font = Enum.Font.GothamBold
forceBtn.Parent = main
Instance.new("UICorner", forceBtn).CornerRadius = UDim.new(0, 4)
forceBtn.MouseButton1Click:Connect(function()
    if currentTheme then
        forceBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
        local normalized = normalizeTheme(currentTheme)
        apiCache[normalized] = nil
        log("🔄 FORCE DRAW: กำลังสุ่มภาพใหม่...")
        drawTheme(currentTheme, true)
        task.wait(0.5)
        forceBtn.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    end
end)

-- ✅ ปุ่มเปิด/ปิด BEST#1
local best1Btn = Instance.new("TextButton")
best1Btn.Size = UDim2.new(0.43, 0, 0, 28)
best1Btn.Position = UDim2.new(0.04, 0, 0.78, 0)
best1Btn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
best1Btn.Text = "🏆 BEST#1: OFF"
best1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
best1Btn.TextSize = 8
best1Btn.Font = Enum.Font.GothamBold
best1Btn.Parent = main
Instance.new("UICorner", best1Btn).CornerRadius = UDim.new(0, 4)
best1Btn.MouseButton1Click:Connect(function()
    best1Mode = not best1Mode
    if best1Mode then
        best1Btn.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
        best1Btn.Text = "🏆 BEST#1: ON"
        best1Label.Text = "🏆 BEST#1: ON"
        best1Label.TextColor3 = Color3.fromRGB(0, 255, 255)
        log("🏆 BEST#1 MODE ON")
    else
        best1Btn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
        best1Btn.Text = "🏆 BEST#1: OFF"
        best1Label.Text = "🏆 BEST#1: OFF"
        best1Label.TextColor3 = Color3.fromRGB(255, 100, 100)
        log("🏆 BEST#1 MODE OFF")
    end
end)

-- ✅ ปุ่มเปิด/ปิด Auto Size
local autoSizeBtn = Instance.new("TextButton")
autoSizeBtn.Size = UDim2.new(0.43, 0, 0, 28)
autoSizeBtn.Position = UDim2.new(0.53, 0, 0.78, 0)
autoSizeBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
autoSizeBtn.Text = "📐 AUTO SIZE: ON"
autoSizeBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
autoSizeBtn.TextSize = 8
autoSizeBtn.Font = Enum.Font.GothamBold
autoSizeBtn.Parent = main
Instance.new("UICorner", autoSizeBtn).CornerRadius = UDim.new(0, 4)
autoSizeBtn.MouseButton1Click:Connect(function()
    autoSizeEnabled = not autoSizeEnabled
    if autoSizeEnabled then
        autoSizeBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
        autoSizeBtn.Text = "📐 AUTO SIZE: ON"
        autoSizeLabel.Text = "📐 AutoSize: ON"
        autoSizeLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
        log("📐 Auto Size ON")
    else
        autoSizeBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
        autoSizeBtn.Text = "📐 AUTO SIZE: OFF"
        autoSizeLabel.Text = "📐 AutoSize: OFF"
        autoSizeLabel.TextColor3 = Color3.fromRGB(255, 150, 50)
        log("📐 Auto Size OFF")
    end
end)

-- ✅ ปรับขนาดด้วยตนเอง (ใช้เมื่อ Auto Size ปิด)
local sizeDown = Instance.new("TextButton")
sizeDown.Size = UDim2.new(0.12, 0, 0, 28)
sizeDown.Position = UDim2.new(0.04, 0, 0.84, 0)
sizeDown.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
sizeDown.Text = "−"
sizeDown.TextColor3 = Color3.fromRGB(255, 255, 255)
sizeDown.TextSize = 16
sizeDown.Font = Enum.Font.GothamBold
sizeDown.Parent = main
local sizeLabel = Instance.new("TextLabel")
sizeLabel.Size = UDim2.new(0.14, 0, 0, 28)
sizeLabel.Position = UDim2.new(0.17, 0, 0.84, 0)
sizeLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
sizeLabel.Text = "35%"
sizeLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
sizeLabel.TextSize = 10
sizeLabel.Font = Enum.Font.Code
sizeLabel.Parent = main
local sizeUp = Instance.new("TextButton")
sizeUp.Size = UDim2.new(0.12, 0, 0, 28)
sizeUp.Position = UDim2.new(0.32, 0, 0.84, 0)
sizeUp.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
sizeUp.Text = "+"
sizeUp.TextColor3 = Color3.fromRGB(0, 0, 0)
sizeUp.TextSize = 16
sizeUp.Font = Enum.Font.GothamBold
sizeUp.Parent = main
sizeDown.MouseButton1Click:Connect(function()
    if not autoSizeEnabled then
        sizeMultiplier = math.max(0.15, sizeMultiplier - 0.05)
        sizeLabel.Text = math.floor(sizeMultiplier * 100) .. "%"
    end
end)
sizeUp.MouseButton1Click:Connect(function()
    if not autoSizeEnabled then
        sizeMultiplier = math.min(1.00, sizeMultiplier + 0.05)
        sizeLabel.Text = math.floor(sizeMultiplier * 100) .. "%"
    end
end)

-- ✅ Skip Control (ใช้เฉพาะโหมดปกติ)
local skipDown = Instance.new("TextButton")
skipDown.Size = UDim2.new(0.12, 0, 0, 28)
skipDown.Position = UDim2.new(0.47, 0, 0.84, 0)
skipDown.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
skipDown.Text = "−"
skipDown.TextColor3 = Color3.fromRGB(255, 255, 255)
skipDown.TextSize = 16
skipDown.Font = Enum.Font.GothamBold
skipDown.Parent = main
local skipCountLabel = Instance.new("TextLabel")
skipCountLabel.Size = UDim2.new(0.14, 0, 0, 28)
skipCountLabel.Position = UDim2.new(0.60, 0, 0.84, 0)
skipCountLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
skipCountLabel.Text = "5"
skipCountLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
skipCountLabel.TextSize = 10
skipCountLabel.Font = Enum.Font.Code
skipCountLabel.Parent = main
local skipUp = Instance.new("TextButton")
skipUp.Size = UDim2.new(0.12, 0, 0, 28)
skipUp.Position = UDim2.new(0.75, 0, 0.84, 0)
skipUp.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
skipUp.Text = "+"
skipUp.TextColor3 = Color3.fromRGB(0, 0, 0)
skipUp.TextSize = 16
skipUp.Font = Enum.Font.GothamBold
skipUp.Parent = main
skipDown.MouseButton1Click:Connect(function()
    skipCount = math.max(1, skipCount - 1)
    skipCountLabel.Text = tostring(skipCount)
    skipLabel.Text = "⏩ Skip: " .. skipCount
    log("⏩ Skip Count set to: " .. skipCount)
end)
skipUp.MouseButton1Click:Connect(function()
    skipCount = math.min(35, skipCount + 1)
    skipCountLabel.Text = tostring(skipCount)
    skipLabel.Text = "⏩ Skip: " .. skipCount
    log("⏩ Skip Count set to: " .. skipCount)
end)

-- ✅ Speed
local speedBtn = Instance.new("TextButton")
speedBtn.Size = UDim2.new(0.43, 0, 0, 28)
speedBtn.Position = UDim2.new(0.04, 0, 0.90, 0)
speedBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
speedBtn.Text = "🚀 FAST MODE"
speedBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
speedBtn.TextSize = 8
speedBtn.Font = Enum.Font.GothamBold
speedBtn.Parent = main
Instance.new("UICorner", speedBtn).CornerRadius = UDim.new(0, 4)
speedBtn.MouseButton1Click:Connect(function()
    DRAW_DELAY = DRAW_DELAY == 0 and 0.001 or 0
    speedBtn.Text = DRAW_DELAY == 0 and "🚀 ZERO DELAY" or "⚡ FAST MODE"
    log(DRAW_DELAY == 0 and "🚀 ZERO DELAY!" or "⚡ Fast mode")
end)

-- ✅ Preload
local preloadBtn = Instance.new("TextButton")
preloadBtn.Size = UDim2.new(0.43, 0, 0, 28)
preloadBtn.Position = UDim2.new(0.53, 0, 0.90, 0)
preloadBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 255)
preloadBtn.Text = "📥 PRELOAD"
preloadBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
preloadBtn.TextSize = 8
preloadBtn.Font = Enum.Font.GothamBold
preloadBtn.Parent = main
Instance.new("UICorner", preloadBtn).CornerRadius = UDim.new(0, 4)
preloadBtn.MouseButton1Click:Connect(function() preloadPopularThemes() end)

-- ✅ Clear Cache
local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(0.43, 0, 0, 28)
clearBtn.Position = UDim2.new(0.53, 0, 0.90, 0) -- **ปรับตำแหน่ง** ให้อยู่ข้างล่างหน่อย
clearBtn.Position = UDim2.new(0.53, 0, 0.925, 0)
clearBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
clearBtn.Text = "🗑️ Clear Cache"
clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearBtn.TextSize = 8
clearBtn.Font = Enum.Font.GothamBold
clearBtn.Parent = main
Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 4)
clearBtn.MouseButton1Click:Connect(function()
    getgenv().QuickDrawCache = {}
    getgenv().QuickDrawLoading = {}
    apiCache = getgenv().QuickDrawCache
    isLoading = getgenv().QuickDrawLoading
    log("🗑️ Cache cleared")
end)

-- ✅ Close
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0.35, 0, 0, 24)
closeBtn.Position = UDim2.new(0.33, 0, 0.955, 0)
closeBtn.Text = "✕ Close"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
closeBtn.TextSize = 10
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = main
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
closeBtn.MouseButton1Click:Connect(function()
    pigManager:destroy()
    gui:Destroy()
    drawingApiActive = false
end)

-- DRAG (เหมือนเดิม)
local drag, ds, fs = false, nil, nil
main.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        drag = true
        ds = i.Position
        fs = main.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - ds
        main.Position = UDim2.new(fs.X.Scale, fs.X.Offset + d.X, fs.Y.Scale, fs.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function() drag = false end)

-- UPDATE LOOP
task.spawn(function()
    while task.wait(0.2) do
        pcall(function()
            thLabel.Text = "🎨 Theme: " .. (currentTheme or "-")
            normLabel.Text = "🔍 Normalized: " .. (normalizeTheme(currentTheme) or "-")
            local cacheCount = 0
            for _ in pairs(apiCache) do cacheCount = cacheCount + 1 end
            sLabel.Text = "⚡ | Draw:" .. drawCount .. " | Mode: " .. (drawingApiActive and "ON" or "OFF") .. " | Cache:" .. cacheCount
            local loadingCount = 0
            for _ in pairs(isLoading) do loadingCount = loadingCount + 1 end
            if loadingCount > 0 then
                statusLabel.Text = "⏳ Loading " .. loadingCount .. " theme(s)..."
                statusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
            elseif preloadComplete then
                statusLabel.Text = "✅ Ready (Preloaded) | BEST#1: " .. (best1Mode and "ON" or "OFF")
                statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            else
                statusLabel.Text = "⏳ Ready | Delay: " .. DRAW_DELAY .. "s"
                statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            end
            local ls = ""
            for i = math.max(1, #testResults - 6), #testResults do
                ls = ls .. testResults[i] .. "\n"
            end
            logText.Text = ls
            logFrame.CanvasSize = UDim2.new(0, 0, 0, logText.TextBounds.Y + 10)
        end)
    end
end)

task.delay(1, function() preloadPopularThemes() end)
log("🚀 V14.7 LOADED! BEST#1 + AUTO SIZE AUTHORITY")
log("🏆 BEST#1 Mode: " .. (best1Mode and "ON" or "OFF"))
log("📐 Auto Size: " .. (autoSizeEnabled and "ON" or "OFF"))
log("🟢 Press DRAWING API ON to start")
