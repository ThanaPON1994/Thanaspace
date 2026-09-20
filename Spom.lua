-- ATLAS v9.8 — SIMPLE AUTO + PATH LOG ⚡
-- 🐷 Pink Pig Edition (350 x 300) — 傳說中的龍女來了
-- 🔙 กลับไปใช้วิธี v1 (สุ่ม) + soft bias ตรง target
-- 📋 มีปุ่ม LOG คัดลอกเส้นทาง

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
if not Remotes then warn("[ATLAS] no Remotes"); return end
local NavigateArticle = Remotes:WaitForChild("NavigateArticle", 30)
if not NavigateArticle then warn("[ATLAS] no NavigateArticle"); return end

-- ==================== 🐷 PALETTE ====================
local PINK_LIGHT  = Color3.fromRGB(255, 220, 230)
local PINK_MAIN   = Color3.fromRGB(255, 180, 200)
local PINK_DARK   = Color3.fromRGB(220, 120, 150)
local PINK_DEEP   = Color3.fromRGB(200, 100, 130)
local PINK_FIELD  = Color3.fromRGB(255, 245, 248)
local WHITE       = Color3.fromRGB(255, 255, 255)
local GREEN_OK    = Color3.fromRGB(120, 200, 140)
local RED_ERR     = Color3.fromRGB(230, 110, 130)
local ORANGE_WARN = Color3.fromRGB(240, 160, 60)
local BLUE_LOG    = Color3.fromRGB(100, 150, 210)

-- ==================== HELPERS ====================
local function normalize(t)
    if not t or t == "" then return t end
    return tostring(t):gsub("_", " "):gsub("^%s+", ""):gsub("%s+$", "")
end

local function copyToClipboard(text)
    if setclipboard then pcall(setclipboard, text) return true end
    if syn and syn.set_clipboard then pcall(syn.set_clipboard, text) return true end
    if toclipboard then pcall(toclipboard, text) return true end
    if writeclipboard then pcall(writeclipboard, text) return true end
    if Delta and Delta.Clipboard and Delta.Clipboard.set then
        pcall(function() Delta.Clipboard.set(text) end); return true
    end
    return false
end

local function getClipboard()
    if getclipboard then return getclipboard() end
    if syn and syn.get_clipboard then return syn.get_clipboard() end
    if Delta and Delta.Clipboard and Delta.Clipboard.get then
        local ok, v = pcall(function() return Delta.Clipboard.get() end)
        if ok then return v end
    end
    return nil
end

-- ==================== DIACRITICS ====================
local DIACRITIC_MAP = {
    ["\195\128"]="a",["\195\129"]="a",["\195\130"]="a",["\195\131"]="a",["\195\132"]="a",["\195\133"]="a",["\195\134"]="ae",["\195\135"]="c",
    ["\195\136"]="e",["\195\137"]="e",["\195\138"]="e",["\195\139"]="e",["\195\140"]="i",["\195\141"]="i",["\195\142"]="i",["\195\143"]="i",
    ["\195\144"]="d",["\195\145"]="n",["\195\146"]="o",["\195\147"]="o",["\195\148"]="o",["\195\149"]="o",["\195\150"]="oe",
    ["\195\153"]="u",["\195\154"]="u",["\195\155"]="u",["\195\156"]="u",["\195\157"]="y",["\195\159"]="ss",
    ["\195\160"]="a",["\195\161"]="a",["\195\162"]="a",["\195\163"]="a",["\195\164"]="a",["\195\165"]="a",["\195\166"]="ae",["\195\167"]="c",
    ["\195\168"]="e",["\195\169"]="e",["\195\170"]="e",["\195\171"]="e",["\195\172"]="i",["\195\173"]="i",["\195\174"]="i",["\195\175"]="i",
    ["\195\176"]="d",["\195\177"]="n",["\195\178"]="o",["\195\179"]="o",["\195\180"]="o",["\195\181"]="o",["\195\182"]="oe",
    ["\195\185"]="u",["\195\186"]="u",["\195\187"]="u",["\195\188"]="u",["\195\189"]="y",["\195\191"]="y",
    ["\196\128"]="a",["\196\129"]="a",["\196\130"]="a",["\196\131"]="a",["\196\132"]="a",["\196\133"]="a",["\196\134"]="c",["\196\135"]="c",
    ["\196\136"]="c",["\196\137"]="c",["\196\138"]="c",["\196\139"]="c",["\196\140"]="d",["\196\141"]="d",["\196\142"]="d",["\196\143"]="d",
    ["\196\144"]="d",["\196\145"]="d",["\196\146"]="e",["\196\147"]="e",["\196\148"]="e",["\196\149"]="e",["\196\150"]="e",["\196\151"]="e",
    ["\196\152"]="e",["\196\153"]="e",["\196\154"]="e",["\196\155"]="e",["\196\156"]="g",["\196\157"]="g",["\196\158"]="g",["\196\159"]="g",
    ["\196\160"]="g",["\196\161"]="g",["\196\162"]="g",["\196\163"]="g",["\196\164"]="h",["\196\165"]="h",["\196\166"]="h",["\196\167"]="h",
    ["\196\168"]="i",["\196\169"]="i",["\196\170"]="i",["\196\171"]="i",["\196\172"]="i",["\196\173"]="i",["\196\174"]="i",["\196\175"]="i",
    ["\196\176"]="i",["\196\177"]="i",["\196\178"]="ij",["\196\179"]="ij",["\196\180"]="j",["\196\181"]="j",["\196\182"]="k",["\196\183"]="k",
    ["\196\184"]="k",["\196\185"]="l",["\196\186"]="l",["\196\187"]="l",["\196\188"]="l",["\196\189"]="l",["\196\190"]="l",["\196\191"]="l",
    ["\197\128"]="l",["\197\129"]="l",["\197\130"]="l",["\197\131"]="n",["\197\132"]="n",["\197\133"]="n",["\197\134"]="n",["\197\135"]="n",
    ["\197\136"]="n",["\197\137"]="n",["\197\138"]="n",["\197\139"]="n",["\197\140"]="o",["\197\141"]="o",["\197\142"]="o",["\197\143"]="o",
    ["\197\144"]="o",["\197\145"]="o",["\197\146"]="oe",["\197\147"]="oe",["\197\148"]="r",["\197\149"]="r",["\197\150"]="r",["\197\151"]="r",
    ["\197\152"]="r",["\197\153"]="r",["\197\154"]="s",["\197\155"]="s",["\197\156"]="s",["\197\157"]="s",["\197\158"]="s",["\197\159"]="s",
    ["\197\160"]="s",["\197\161"]="s",["\197\162"]="t",["\197\163"]="t",["\197\164"]="t",["\197\165"]="t",["\197\166"]="t",["\197\167"]="t",
    ["\197\168"]="u",["\197\169"]="u",["\197\170"]="u",["\197\171"]="u",["\197\172"]="u",["\197\173"]="u",["\197\174"]="u",["\197\175"]="u",
    ["\197\176"]="u",["\197\177"]="u",["\197\178"]="u",["\197\179"]="u",["\197\180"]="w",["\197\181"]="w",["\197\182"]="y",["\197\183"]="y",
    ["\197\184"]="y",["\197\185"]="z",["\197\186"]="z",["\197\187"]="z",["\197\188"]="z",["\197\189"]="z",["\197\190"]="z",["\197\191"]="s",
    ["\198\160"]="o",["\198\161"]="o",["\198\175"]="u",["\198\176"]="u",
}

local function stripDiacritics(s)
    if not s or s == "" then return s end
    s = s:gsub("[\228-\233][\128-\191][\128-\191]", function(c) return DIACRITIC_MAP[c] or c end)
    s = s:gsub("[\194-\199][\128-\191]", function(c) return DIACRITIC_MAP[c] or c end)
    return s
end

local function superNormalize(s)
    if not s then return "" end
    s = tostring(s):lower()
    s = s:gsub("&amp;", "&"):gsub("&#39;", "'"):gsub("&quot;", '"'):gsub("&nbsp;", " ")
    s = s:gsub("\226\128\152", "'"):gsub("\226\128\153", "'")
    s = s:gsub("\226\128\156", '"'):gsub("\226\128\157", '"')
    s = s:gsub("\226\128\147", "-"):gsub("\226\128\148", "-")
    s = stripDiacritics(s)
    s = s:gsub("[^%w]", "")
    return s
end

-- ==================== 🔵 BLUE ====================
local function isBlue(color)
    local r, g, b = color.R * 255, color.G * 255, color.B * 255
    if math.abs(r - g) < 10 and math.abs(g - b) < 10 and math.abs(r - b) < 10 then return false end
    if b < 55 then return false end
    if b < r - 15 or b < g - 15 then return false end
    if b > 100 and b > r + 20 and b > g + 15 then return true end
    if b > 130 and b > r and b > g then if r + g + b > 300 then return true end end
    if b > 90 and b >= r and b >= g and (b - r) >= 5 then return true end
    if b > 110 and r > g - 10 and b > g + 10 then return true end
    if b > 90 and r > 60 and g < r - 15 and g < b - 15 then return true end
    if b > 100 and g > 100 and b >= r + 20 and math.abs(g - b) < 60 then return true end
    if b > 80 and b > r + 30 and b > g + 30 then return true end
    return false
end

-- ==================== 🔴 RED (HUE) ====================
local function isRedColor(color)
    if not color then return false end
    local r, g, b = color.R * 255, color.G * 255, color.B * 255
    if r < 120 then return false end
    if r < g or r < b then return false end
    local delta = r - math.min(g, b)
    if delta < 40 then return false end
    local hueShift = (g - b) / delta
    if math.abs(hueShift) > 0.25 then return false end
    return true
end

local function isEnglish(text)
    if not text then return false end
    text = tostring(text):gsub("^%s+", ""):gsub("%s+$", "")
    if #text < 2 then return false end
    local letters, digits = 0, 0
    for i = 1, #text do
        local b = text:byte(i)
        if (b >= 65 and b <= 90) or (b >= 97 and b <= 122) then letters = letters + 1
        elseif b >= 48 and b <= 57 then digits = digits + 1 end
    end
    if letters < 2 then return false end
    if digits == #text then return false end
    for i = 1, #text do
        local b = text:byte(i)
        if b and b >= 0xE0 and b <= 0xEF then return false end
    end
    return true
end

-- ==================== UI JUNK ====================
local UI_JUNK = {
    ["search wikibloxia"]=true, ["wikirace! article translation pull"]=true,
    ["players"]=true, ["shop"]=true, ["style"]=true,
    ["scores"]=true, ["leave"]=true, ["skip"]=true,
    ["host"]=true, ["standard"]=true, ["unlimited"]=true,
    ["wikibloxia"]=true, ["time left"]=true,
    ["wikirace!"]=true, ["wikirace"]=true,
    ["ui the free encyclopedia"]=true, ["the free encyclopedia"]=true,
    ["choose the language you want prioritized in translating the articles"]=true,
    ["choose the language you want prioritized in translating the articles!"]=true,
    ["article read"]=true,
}

local function isUiJunk(text)
    if not text or text == "" then return false end
    local low = text:lower():gsub("^%s+",""):gsub("%s+$","")
    if UI_JUNK[low] then return true end
    if low:find("^time left") then return true end
    if low:find("^search wiki") then return true end
    if low:find("^wikirace") then return true end
    if low:find("^wikibloxia") then return true end
    if low:match("^%d+%.?%s*$") then return true end
    if low:find("the free encyclopedia", 1, true) then return true end
    if low:find("choose the language", 1, true) then return true end
    if low:find("prioritized in translating", 1, true) then return true end
    if low == "article read" then return true end
    return false
end

-- ==================== STATE ====================
local allLogs = {}
local gameCache = {}
local blueWordCache = {}
local linkIdMap = {}
local currentArticle = nil
local currentArticleId = nil
local startTitle = nil
local targetTitle = nil
local currentPath = {}
local visitedSet = {}
local pathLog = {}       -- 📋 {t=เวลา, page=ชื่อ, src=source}

local clickNum = 0
local lastPicks = {}
local isProcessing = false
local hopArticle = nil

local autoChainQueue = {}
local autoChainActive = false
local chainHistory = {}
local chainCurrentRank = 0

local autoExploreActive = false
local autoExploreBusy = false
local autoRetryCount = 0

local lastPickAttemptTitle = nil

local function markVisited(name)
    if not name or name == "" then return end
    visitedSet[name:lower()] = true
end

local function isVisited(name)
    if not name or name == "" then return false end
    return visitedSet[name:lower()] == true
end

local function getCurrentURL()
    local c = {}
    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextBox") then
            local text = obj.Text or ""
            if text:find("wikibloxia.org/wiki/") or text:find("wikibloxia%.org") then
                table.insert(c, text)
            end
        end
    end
    for _, text in ipairs(c) do
        local match = text:match("wiki/([^%s%?%#]+)")
        if match then
            match = match:gsub("%%(%x%x)", function(h)
                return string.char(tonumber(h, 16))
            end)
            return normalize(match)
        end
    end
    return nil
end

-- ==================== 🐷 GUI ====================
local gui = Instance.new("ScreenGui")
gui.Name = "傳說中的龍女來了"
gui.ResetOnSpawn = false
gui.DisplayOrder = 9999
gui.IgnoreGuiInset = false
gui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 350, 0, 300)
frame.Position = UDim2.new(0, 10, 0, 20)
frame.BackgroundColor3 = PINK_MAIN
frame.BorderSizePixel = 0
frame.Active = true
frame.Visible = true
frame.Parent = gui
local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 20)
frameCorner.Parent = frame

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 28)
titleBar.BackgroundColor3 = PINK_DARK
titleBar.BorderSizePixel = 0
titleBar.Active = true
titleBar.Parent = frame
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 20)
titleCorner.Parent = titleBar

local pigSnout = Instance.new("Frame")
pigSnout.Size = UDim2.new(0, 18, 0, 13)
pigSnout.Position = UDim2.new(0, 8, 0.5, -6)
pigSnout.BackgroundColor3 = PINK_LIGHT
pigSnout.BorderSizePixel = 0
pigSnout.Parent = titleBar
local snoutCorner = Instance.new("UICorner")
snoutCorner.CornerRadius = UDim.new(0, 5)
snoutCorner.Parent = pigSnout

for i = 0, 1 do
    local nostril = Instance.new("Frame")
    nostril.Size = UDim2.new(0, 4, 0, 5)
    nostril.Position = UDim2.new(0, 4 + i * 6, 0.5, -2)
    nostril.BackgroundColor3 = PINK_DEEP
    nostril.BorderSizePixel = 0
    nostril.Parent = pigSnout
    local nC = Instance.new("UICorner"); nC.CornerRadius = UDim.new(1, 0); nC.Parent = nostril
end
for i = 0, 1 do
    local eye = Instance.new("Frame")
    eye.Size = UDim2.new(0, 4, 0, 4)
    eye.Position = UDim2.new(0, 11 + i * 6, 0.2, 0)
    eye.BackgroundColor3 = PINK_DEEP
    eye.BorderSizePixel = 0
    eye.Parent = titleBar
    local eC = Instance.new("UICorner"); eC.CornerRadius = UDim.new(1, 0); eC.Parent = eye
end

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -80, 1, 0)
title.Position = UDim2.new(0, 34, 0, 0)
title.BackgroundTransparency = 1
title.Text = "傳說中的龍女來了 ⚡"
title.TextColor3 = WHITE
title.Font = Enum.Font.SourceSansBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 20, 0, 20)
minBtn.Position = UDim2.new(1, -46, 0, 4)
minBtn.BackgroundColor3 = PINK_DEEP
minBtn.Text = "-"
minBtn.TextColor3 = WHITE
minBtn.Font = Enum.Font.SourceSansBold
minBtn.TextSize = 14
minBtn.BorderSizePixel = 0
minBtn.Parent = titleBar
local mbC = Instance.new("UICorner"); mbC.CornerRadius = UDim.new(1, 0); mbC.Parent = minBtn

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 20, 0, 20)
closeBtn.Position = UDim2.new(1, -24, 0, 4)
closeBtn.BackgroundColor3 = RED_ERR
closeBtn.Text = "X"
closeBtn.TextColor3 = WHITE
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 12
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
local cbC = Instance.new("UICorner"); cbC.CornerRadius = UDim.new(1, 0); cbC.Parent = closeBtn

local dragging, dragStart, startPos = false, nil, nil
local function isClickOnButton(pos)
    if not pos then return false end
    local objs = PlayerGui:GetGuiObjectsAtPosition(pos.X, pos.Y)
    for _, o in ipairs(objs) do
        if o == minBtn or o == closeBtn then return true end
        if o:IsDescendantOf(minBtn) or o:IsDescendantOf(closeBtn) then return true end
    end
    return false
end

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        if isClickOnButton(input.Position) then return end
        dragging = true; dragStart = input.Position; startPos = frame.Position
    end
end)
titleBar.InputChanged:Connect(function(input)
    if dragging then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                   startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

local content = Instance.new("Frame")
content.Size = UDim2.new(1, 0, 1, -28)
content.Position = UDim2.new(0, 0, 0, 28)
content.BackgroundTransparency = 1
content.Parent = frame

local infoLbl = Instance.new("TextLabel")
infoLbl.Size = UDim2.new(1, -120, 0, 18)
infoLbl.Position = UDim2.new(0, 6, 0, 4)
infoLbl.BackgroundColor3 = PINK_FIELD
infoLbl.BorderSizePixel = 0
infoLbl.Text = "T: ?"
infoLbl.TextColor3 = PINK_DEEP
infoLbl.Font = Enum.Font.Code
infoLbl.TextSize = 11
infoLbl.TextXAlignment = Enum.TextXAlignment.Left
infoLbl.TextTruncate = Enum.TextTruncate.AtEnd
infoLbl.Parent = content
local ilC = Instance.new("UICorner"); ilC.CornerRadius = UDim.new(0, 8); ilC.Parent = infoLbl

local copyTargetBtn = Instance.new("TextButton")
copyTargetBtn.Size = UDim2.new(0, 110, 0, 18)
copyTargetBtn.Position = UDim2.new(1, -116, 0, 4)
copyTargetBtn.BackgroundColor3 = PINK_DEEP
copyTargetBtn.Text = "COPY TARGET"
copyTargetBtn.TextColor3 = WHITE
copyTargetBtn.Font = Enum.Font.SourceSansBold
copyTargetBtn.TextSize = 10
copyTargetBtn.BorderSizePixel = 0
copyTargetBtn.Parent = content
local ctC = Instance.new("UICorner"); ctC.CornerRadius = UDim.new(0, 8); ctC.Parent = copyTargetBtn

local currentLbl = Instance.new("TextLabel")
currentLbl.Size = UDim2.new(1, -12, 0, 18)
currentLbl.Position = UDim2.new(0, 6, 0, 24)
currentLbl.BackgroundColor3 = PINK_FIELD
currentLbl.BorderSizePixel = 0
currentLbl.Text = "C: ?"
currentLbl.TextColor3 = PINK_DARK
currentLbl.Font = Enum.Font.Code
currentLbl.TextSize = 11
currentLbl.TextXAlignment = Enum.TextXAlignment.Left
currentLbl.TextTruncate = Enum.TextTruncate.AtEnd
currentLbl.Parent = content
local clC = Instance.new("UICorner"); clC.CornerRadius = UDim.new(0, 8); clC.Parent = currentLbl

local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1, -12, 0, 16)
statusLbl.Position = UDim2.new(0, 6, 0, 44)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "🐽 Ready."
statusLbl.TextColor3 = PINK_DEEP
statusLbl.Font = Enum.Font.SourceSans
statusLbl.TextSize = 11
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.TextTruncate = Enum.TextTruncate.AtEnd
statusLbl.Parent = content

-- แถวปุ่ม: 小女孩 | AUTO | STOP | 📋 LOG
local hopBtn = Instance.new("TextButton")
hopBtn.Size = UDim2.new(0, 82, 0, 28)
hopBtn.Position = UDim2.new(0, 6, 0, 64)
hopBtn.BackgroundColor3 = PINK_DEEP
hopBtn.Text = "小女孩"
hopBtn.TextColor3 = WHITE
hopBtn.Font = Enum.Font.SourceSansBold
hopBtn.TextSize = 13
hopBtn.BorderSizePixel = 0
hopBtn.Parent = content
local hbC = Instance.new("UICorner"); hbC.CornerRadius = UDim.new(0, 10); hbC.Parent = hopBtn

local autoBtn = Instance.new("TextButton")
autoBtn.Size = UDim2.new(0, 90, 0, 28)
autoBtn.Position = UDim2.new(0, 92, 0, 64)
autoBtn.BackgroundColor3 = ORANGE_WARN
autoBtn.Text = "AUTO ⚡ OFF"
autoBtn.TextColor3 = WHITE
autoBtn.Font = Enum.Font.SourceSansBold
autoBtn.TextSize = 11
autoBtn.BorderSizePixel = 0
autoBtn.Parent = content
local abC = Instance.new("UICorner"); abC.CornerRadius = UDim.new(0, 10); abC.Parent = autoBtn

local stopAutoBtn = Instance.new("TextButton")
stopAutoBtn.Size = UDim2.new(0, 82, 0, 28)
stopAutoBtn.Position = UDim2.new(0, 186, 0, 64)
stopAutoBtn.BackgroundColor3 = RED_ERR
stopAutoBtn.Text = "STOP 🔴"
stopAutoBtn.TextColor3 = WHITE
stopAutoBtn.Font = Enum.Font.SourceSansBold
stopAutoBtn.TextSize = 11
stopAutoBtn.BorderSizePixel = 0
stopAutoBtn.Parent = content
local saC = Instance.new("UICorner"); saC.CornerRadius = UDim.new(0, 10); saC.Parent = stopAutoBtn

-- 📋 LOG
local copyLogBtn = Instance.new("TextButton")
copyLogBtn.Size = UDim2.new(0, 76, 0, 28)
copyLogBtn.Position = UDim2.new(0, 272, 0, 64)
copyLogBtn.BackgroundColor3 = BLUE_LOG
copyLogBtn.Text = "📋 LOG"
copyLogBtn.TextColor3 = WHITE
copyLogBtn.Font = Enum.Font.SourceSansBold
copyLogBtn.TextSize = 12
copyLogBtn.BorderSizePixel = 0
copyLogBtn.Parent = content
local clbC = Instance.new("UICorner"); clbC.CornerRadius = UDim.new(0, 10); clbC.Parent = copyLogBtn

local pasteLbl = Instance.new("TextLabel")
pasteLbl.Size = UDim2.new(1, -12, 0, 14)
pasteLbl.Position = UDim2.new(0, 6, 0, 96)
pasteLbl.BackgroundTransparency = 1
pasteLbl.Text = "Paste Gemini JSON:"
pasteLbl.TextColor3 = PINK_DEEP
pasteLbl.Font = Enum.Font.SourceSans
pasteLbl.TextSize = 11
pasteLbl.TextXAlignment = Enum.TextXAlignment.Left
pasteLbl.Parent = content

local pasteBox = Instance.new("TextBox")
pasteBox.Size = UDim2.new(1, -12, 0, 44)
pasteBox.Position = UDim2.new(0, 6, 0, 112)
pasteBox.BackgroundColor3 = PINK_FIELD
pasteBox.TextColor3 = PINK_DEEP
pasteBox.PlaceholderText = '{"path":[...]} / picks / พิมพ์ชื่อเพจตรงๆ'
pasteBox.Text = ""
pasteBox.Font = Enum.Font.Code
pasteBox.TextSize = 10
pasteBox.TextXAlignment = Enum.TextXAlignment.Left
pasteBox.TextYAlignment = Enum.TextYAlignment.Top
pasteBox.TextWrapped = true
pasteBox.MultiLine = true
pasteBox.ClearTextOnFocus = false
pasteBox.BorderSizePixel = 0
pasteBox.Parent = content
local pbC = Instance.new("UICorner"); pbC.CornerRadius = UDim.new(0, 10); pbC.Parent = pasteBox

local pasteBtn = Instance.new("TextButton")
pasteBtn.Size = UDim2.new(0, 110, 0, 28)
pasteBtn.Position = UDim2.new(0, 6, 0, 160)
pasteBtn.BackgroundColor3 = PINK_DARK
pasteBtn.Text = "777"
pasteBtn.TextColor3 = WHITE
pasteBtn.Font = Enum.Font.SourceSansBold
pasteBtn.TextSize = 12
pasteBtn.BorderSizePixel = 0
pasteBtn.Parent = content
local pC = Instance.new("UICorner"); pC.CornerRadius = UDim.new(0, 10); pC.Parent = pasteBtn

local clearJsonBtn = Instance.new("TextButton")
clearJsonBtn.Size = UDim2.new(0, 110, 0, 28)
clearJsonBtn.Position = UDim2.new(0, 120, 0, 160)
clearJsonBtn.BackgroundColor3 = RED_ERR
clearJsonBtn.Text = "CLEAR"
clearJsonBtn.TextColor3 = WHITE
clearJsonBtn.Font = Enum.Font.SourceSansBold
clearJsonBtn.TextSize = 12
clearJsonBtn.BorderSizePixel = 0
clearJsonBtn.Parent = content
local cjC = Instance.new("UICorner"); cjC.CornerRadius = UDim.new(0, 10); cjC.Parent = clearJsonBtn

local goBtn = Instance.new("TextButton")
goBtn.Size = UDim2.new(0, 114, 0, 28)
goBtn.Position = UDim2.new(0, 234, 0, 160)
goBtn.BackgroundColor3 = GREEN_OK
goBtn.Text = "GO ⚡"
goBtn.TextColor3 = WHITE
goBtn.Font = Enum.Font.SourceSansBold
goBtn.TextSize = 12
goBtn.BorderSizePixel = 0
goBtn.Parent = content
local gbC = Instance.new("UICorner"); gbC.CornerRadius = UDim.new(0, 10); gbC.Parent = goBtn

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -12, 1, -196)
scroll.Position = UDim2.new(0, 6, 0, 194)
scroll.BackgroundColor3 = PINK_FIELD
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = content
local scC = Instance.new("UICorner"); scC.CornerRadius = UDim.new(0, 10); scC.Parent = scroll

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 2)
layout.Parent = scroll

local function addLine(text, color)
    table.insert(allLogs, text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -4, 0, 12)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or PINK_DEEP
    l.Font = Enum.Font.Code
    l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextTruncate = Enum.TextTruncate.AtEnd
    l.Parent = scroll
    task.defer(function()
        pcall(function() scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y) end)
    end)
end

-- ==================== 📋 PATH LOG ====================
local function addPathLog(page, src)
    if not page or page == "" then return end
    table.insert(pathLog, {
        t = os.date("%H:%M:%S"),
        page = page,
        src = src or "?",
    })
end

local function formatPathLog()
    local lines = {}
    table.insert(lines, "=== ATLAS v9.8 PATH LOG ===")
    table.insert(lines, "Start : " .. (startTitle or "?"))
    table.insert(lines, "Target: " .. (targetTitle or "?"))
    table.insert(lines, "Hops  : " .. #pathLog)
    table.insert(lines, "")
    for i, e in ipairs(pathLog) do
        local line = string.format("%2d. [%s] %s", i, e.t, e.page)
        if e.src and e.src ~= "?" then line = line .. "  {" .. e.src .. "}" end
        table.insert(lines, line)
    end
    table.insert(lines, "")
    table.insert(lines, "-- CANDIDATES ปัจจุบัน --")
    for _, c in ipairs(getAutoCandidates()) do
        table.insert(lines, "  • " .. c)
    end
    return table.concat(lines, "\n")
end

local function copyPathLog()
    if #pathLog == 0 then
        addLine("[COPY] ยังไม่มี path", ORANGE_WARN)
        return
    end
    local ok = copyToClipboard(formatPathLog())
    addLine("[COPY] " .. #pathLog .. " hops → clipboard " .. (ok and "✓" or "✗"),
        ok and GREEN_OK or RED_ERR)
    statusLbl.Text = "📋 Copied " .. #pathLog .. " hops"
end

-- ==================== SCAN BLUE ====================
local function scanBlue()
    local items = {}
    local seen_texts = {}
    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if not obj:IsDescendantOf(gui) then
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                local vis = true
                local p = obj
                while p and p ~= PlayerGui do
                    if p:IsA("GuiObject") and not p.Visible then vis = false; break end
                    p = p.Parent
                end
                if vis then
                    local text = obj.Text or ""
                    if text ~= "" then
                        local blue = isBlue(obj.TextColor3)
                        if not blue and obj.RichText then
                            for hex in text:gmatch('<font color="#(%x%x%x%x%x%x)"') do
                                local r = tonumber(hex:sub(1,2),16)
                                local g = tonumber(hex:sub(3,4),16)
                                local b = tonumber(hex:sub(5,6),16)
                                if isBlue(Color3.fromRGB(r,g,b)) then blue = true; break end
                            end
                            if not blue then
                                for r,g,b in text:gmatch('<font color="rgb%((%d+),(%d+),(%d+)%)"') do
                                    if isBlue(Color3.fromRGB(tonumber(r),tonumber(g),tonumber(b))) then blue = true; break end
                                end
                            end
                            if text:find("<a ") then
                                for linkText in text:gmatch("<a [^>]*>([^<]+)</a>") do
                                    local disp = linkText:gsub("<[^>]+>",""):gsub("^%s+",""):gsub("%s+$","")
                                    if #disp > 0 and not isUiJunk(disp) and isEnglish(disp) then
                                        local key = disp:lower()
                                        if not seen_texts[key] then
                                            seen_texts[key] = true
                                            local pos = obj.AbsolutePosition
                                            table.insert(items, {text=disp, x=pos and pos.X or 0, y=pos and pos.Y or 0, w=obj.AbsoluteSize and obj.AbsoluteSize.X or 0})
                                        end
                                    end
                                end
                            end
                        end
                        if blue then
                            local disp = text:gsub("<[^>]+>",""):gsub("^%s+",""):gsub("%s+$","")
                            if #disp > 0 and not isUiJunk(disp) then
                                local key = disp:lower()
                                if not seen_texts[key] then
                                    seen_texts[key] = true
                                    local pos = obj.AbsolutePosition
                                    table.insert(items, {text=disp, x=pos and pos.X or 0, y=pos and pos.Y or 0, w=obj.AbsoluteSize and obj.AbsoluteSize.X or 0})
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    table.sort(items, function(a, b)
        if math.abs(a.y - b.y) > 6 then return a.y < b.y end
        return a.x < b.x
    end)
    local merged = {}
    local cur = nil
    for _, it in ipairs(items) do
        if not cur then
            cur = {text=it.text, x=it.x, y=it.y, endX=it.x+it.w}
        else
            local sameLine = math.abs(it.y - cur.y) <= 6
            local gap = it.x - cur.endX
            if sameLine and gap < 25 and gap > -10 then
                local addSpace = true
                if cur.text:sub(-1) == " " then addSpace = false end
                if it.text:sub(1, 1) == " " then addSpace = false end
                if gap <= 0.5 then addSpace = false end
                local lastC = cur.text:sub(-1)
                if lastC == "-" or lastC == "'" or lastC == "/" or lastC == "." then addSpace = false end
                local firstC = it.text:sub(1, 1)
                if firstC == "," or firstC == "." or firstC == ")" or firstC == "!" or firstC == "?" or firstC == ":" or firstC == ";" then addSpace = false end
                if addSpace then cur.text = cur.text .. " " .. it.text
                else cur.text = cur.text .. it.text end
                cur.endX = it.x + it.w
            else
                table.insert(merged, cur.text)
                cur = {text=it.text, x=it.x, y=it.y, endX=it.x+it.w}
            end
        end
    end
    if cur then table.insert(merged, cur.text) end
    local seen, result = {}, {}
    for _, w in ipairs(merged) do
        w = w:gsub("^%s+",""):gsub("%s+$",""):gsub("%s+"," ")
        if isEnglish(w) and not isUiJunk(w) then
            local k = w:lower()
            if not seen[k] then seen[k] = true; table.insert(result, w) end
        end
    end
    return result
end

-- ==================== 🔴 RED CIRCLE ====================
local function isVisibleChain(obj)
    local p = obj
    while p and p ~= PlayerGui do
        if p:IsA("GuiObject") and not p.Visible then return false end
        p = p.Parent
    end
    return true
end

local function hasRedCircleDot()
    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if not obj:IsDescendantOf(gui) then
            local isFrame = obj:IsA("Frame")
            local isImage = obj:IsA("ImageLabel")

            if isFrame or isImage then
                if isVisibleChain(obj) then
                    local sizeX = obj.AbsoluteSize.X
                    local sizeY = obj.AbsoluteSize.Y

                    local sizeOk = sizeX >= 6 and sizeX <= 30
                                and sizeY >= 6 and sizeY <= 30

                    local ratio = sizeX / math.max(sizeY, 1)
                    local squareOk = ratio >= 0.85 and ratio <= 1.18

                    if sizeOk and squareOk then
                        local isRealCircle = false
                        local corner = obj:FindFirstChildOfClass("UICorner")

                        if corner then
                            local cr = corner.CornerRadius
                            local minSide = math.min(sizeX, sizeY)
                            if cr.Scale >= 0.5 then
                                isRealCircle = true
                            elseif cr.Offset >= minSide * 0.48 then
                                isRealCircle = true
                            end
                        end

                        if not isRealCircle then
                            local ar = obj:FindFirstChildOfClass("UIAspectRatioConstraint")
                            if ar and math.abs(ar.AspectRatio - 1) < 0.05 then
                                isRealCircle = true
                            end
                        end

                        if isRealCircle then
                            local red, reason = false, ""

                            if not red and isFrame
                               and obj.BackgroundTransparency < 0.3
                               and isRedColor(obj.BackgroundColor3) then
                                red = true; reason = "bg"
                            end

                            if not red and isImage
                               and obj.ImageTransparency < 0.3
                               and isRedColor(obj.ImageColor3) then
                                red = true; reason = "img"
                            end

                            if not red then
                                local stroke = obj:FindFirstChildOfClass("UIStroke")
                                if stroke and stroke.Transparency < 0.3
                                   and isRedColor(stroke.Color) then
                                    red = true; reason = "stroke"
                                end
                            end

                            if red then
                                addLine("[🔴] " .. obj.Name
                                    .. " " .. math.floor(sizeX) .. "x" .. math.floor(sizeY)
                                    .. " @ " .. math.floor(obj.AbsolutePosition.X)
                                    .. "," .. math.floor(obj.AbsolutePosition.Y)
                                    .. " (" .. reason .. ")", RED_ERR)
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

local function updateLabels()
    infoLbl.Text = "T: " .. (targetTitle or "?")
    local c = currentArticle or "?"
    if currentArticleId then c = c .. " [" .. currentArticleId .. "]" end
    currentLbl.Text = "C: " .. c
end

local function refreshURL()
    if currentArticle and currentArticleId then return false end
    local url = getCurrentURL()
    if url then
        if not currentArticle or currentArticle ~= url then
            currentArticle = url
            markVisited(url)
            if #currentPath == 0 then table.insert(currentPath, url)
            elseif currentPath[#currentPath] ~= url then table.insert(currentPath, url) end
            updateLabels()
            return true
        end
    end
    return false
end

-- ==================== CANDIDATES ====================
local function getFilteredCandidates()
    if not currentArticle then return {} end
    local norm = normalize(currentArticle)
    local fromCache = gameCache[norm] or {}
    local fromScan = scanBlue()
    local fromOld = blueWordCache[norm] or {}
    local candidates, seen = {}, {}
    local function addSource(list)
        for _, c in ipairs(list) do
            if c and c ~= "" then
                local k = c:lower()
                if not seen[k] then seen[k] = true; table.insert(candidates, c) end
            end
        end
    end
    addSource(fromCache); addSource(fromScan); addSource(fromOld)
    if #fromScan > 0 then blueWordCache[norm] = fromScan end
    local filtered = {}
    for _, c in ipairs(candidates) do
        if isEnglish(c) and not isUiJunk(c) and not isVisited(c) then
            table.insert(filtered, c)
        end
    end
    if #filtered > 200 then
        local capped = {}
        for i = 1, 200 do capped[i] = filtered[i] end
        filtered = capped
    end
    return filtered
end

local function getAutoCandidates()
    if not currentArticle then return {} end
    local norm = normalize(currentArticle)
    local fromCache = gameCache[norm] or {}
    local fromScan = scanBlue()
    local candidates, seen = {}, {}
    local function addSource(list)
        for _, c in ipairs(list) do
            if c and c ~= "" then
                local k = c:lower()
                if not seen[k] then seen[k] = true; table.insert(candidates, c) end
            end
        end
    end
    addSource(fromCache); addSource(fromScan)
    local filtered = {}
    for _, c in ipairs(candidates) do
        if isEnglish(c) and not isUiJunk(c) then
            table.insert(filtered, c)
        end
    end
    return filtered
end

-- ==================== CLICK FALLBACK ====================
local function tryClickVisibleLink(title)
    if not title then return false end
    local targetSuper = superNormalize(title)
    if #targetSuper < 2 then return false end
    local found = {}
    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if not obj:IsDescendantOf(gui) then
            if obj:IsA("TextButton") or obj:IsA("TextLabel") then
                local text = obj.Text or ""
                if text ~= "" and not isUiJunk(text) then
                    local disp = text:gsub("<[^>]+>",""):gsub("^%s+",""):gsub("%s+$","")
                    local dispSuper = superNormalize(disp)
                    local score = 0
                    if dispSuper == targetSuper then score = 100
                    elseif disp:lower() == title:lower() then score = 90
                    elseif #targetSuper >= 3 and dispSuper:find(targetSuper, 1, true) then score = 80
                    elseif #dispSuper >= 3 and targetSuper:find(dispSuper, 1, true) then score = 70
                    end
                    if score > 0 then
                        if isBlue(obj.TextColor3) then score = score + 20 end
                        if obj:IsA("TextButton") then score = score + 10 end
                        table.insert(found, {obj = obj, score = score, disp = disp})
                    end
                end
            end
        end
    end
    if #found == 0 then return false end
    table.sort(found, function(a, b) return a.score > b.score end)
    for i = 1, math.min(5, #found) do
        local f = found[i]
        local target = f.obj
        if target:IsA("TextLabel") then
            local p = target.Parent
            while p and p ~= PlayerGui do
                if p:IsA("TextButton") then target = p; break end
                p = p.Parent
            end
        end
        local ok = false
        pcall(function() if target.Activate then target:Activate(); ok = true end end)
        if not ok then pcall(function() if target.MouseButton1Click then target.MouseButton1Click:Fire(); ok = true end end) end
        if not ok then
            pcall(function()
                if target.MouseButton1Down then target.MouseButton1Down:Fire() end
                if target.MouseButton1Up then target.MouseButton1Up:Fire() end
                ok = true
            end)
        end
        if ok then return true end
    end
    return false
end

-- ==================== NAVIGATE ====================
local function navigateToTitle(title)
    if not title then return false end
    if not currentArticle or not currentArticleId then return false end
    if normalize(title):lower() == normalize(currentArticle):lower() then return false end

    local normTitle = normalize(title)
    local targetId, matchType = nil, ""

    targetId = linkIdMap[normTitle]
    if targetId then matchType = "exact" end
    if not targetId then
        local lowT = normTitle:lower()
        for k, v in pairs(linkIdMap) do
            if k:lower() == lowT then targetId = v; matchType = "ci-exact"; break end
        end
    end
    if not targetId then
        local function agg(s) return tostring(s):lower():gsub("[%p%s]", "") end
        local targetAgg = agg(normTitle)
        for k, v in pairs(linkIdMap) do
            if agg(k) == targetAgg then targetId = v; matchType = "agg-fuzzy"; break end
        end
    end
    if not targetId then
        local targetSuper = superNormalize(normTitle)
        if #targetSuper >= 3 then
            for k, v in pairs(linkIdMap) do
                if superNormalize(k) == targetSuper then targetId = v; matchType = "super-fuzzy"; break end
            end
        end
    end
    if not targetId then
        local lowT = normTitle:lower()
        if #lowT >= 5 then
            for k, v in pairs(linkIdMap) do
                local lowK = k:lower()
                if lowK:find(lowT, 1, true) or lowT:find(lowK, 1, true) then targetId = v; matchType = "substring"; break end
            end
        end
    end
    if not targetId then
        local targetSuper = superNormalize(normTitle)
        if #targetSuper >= 5 then
            for k, v in pairs(linkIdMap) do
                local kSuper = superNormalize(k)
                if kSuper:find(targetSuper, 1, true) or targetSuper:find(kSuper, 1, true) then targetId = v; matchType = "super-substring"; break end
            end
        end
    end
    if not targetId then
        local lowT = normTitle:lower()
        local words = {}
        for w in lowT:gmatch("%a+") do
            if #w >= 4 then table.insert(words, w) end
        end
        if #words >= 2 then
            for k, v in pairs(linkIdMap) do
                local lowK = k:lower()
                local matchCount = 0
                for _, w in ipairs(words) do
                    if lowK:find(w, 1, true) then matchCount = matchCount + 1 end
                end
                if matchCount >= #words then targetId = v; matchType = "word-match"; break end
            end
        end
    end

    if not targetId then
        if tryClickVisibleLink(title) then
            addLine("[GO] " .. title .. " (clicked, no id)", GREEN_OK)
            markVisited(title)
            lastPickAttemptTitle = title
            return true
        end
        return false
    end

    clickNum = clickNum + 1
    local tag = matchType ~= "exact" and (" [" .. matchType .. "]") or ""
    addLine("[GO] " .. title .. " (id=" .. targetId .. ")" .. tag, GREEN_OK)
    pcall(function() NavigateArticle:FireServer(currentArticleId, targetId, clickNum) end)
    markVisited(title)
    lastPickAttemptTitle = title
    statusLbl.Text = "→ " .. title
    return true
end

-- ==================== PARSE PICKS ====================
local function normalizePicks(data)
    local out = {}
    if type(data) ~= "table" then return out end

    local function pushTitle(entry, defaultRank)
        if type(entry) == "string" then
            table.insert(out, {rank = defaultRank or 99, title = entry})
            return
        end
        if type(entry) ~= "table" then return end
        local t = entry.title or entry.Title or entry.name or entry.next
        if not t or t == "" then return end
        table.insert(out, {
            rank         = tonumber(entry.rank or entry.Rank) or defaultRank or 99,
            title        = tostring(t),
            why          = entry.why or entry.reason or entry.Reason
                           or entry.reasoning or entry.Reasoning
                           or entry.description or entry.Description,
        })
    end

    if type(data.picks) == "table" then
        for i, p in ipairs(data.picks) do pushTitle(p, i) end
    end
    if type(data.path) == "table" then
        for i, p in ipairs(data.path) do pushTitle(p, i) end
    end
    if type(data.routes) == "table" then
        for i, p in ipairs(data.routes) do pushTitle(p, i) end
    end
    if type(data.steps) == "table" then
        for i, p in ipairs(data.steps) do pushTitle(p, i) end
    end
    if data.pick ~= nil then pushTitle(data.pick, 1) end
    if #out == 0 and type(data.title) == "string" and data.title ~= "" then
        table.insert(out, {rank = 1, title = data.title, why = data.reasoning or data.reason})
    end

    table.sort(out, function(a, b) return (a.rank or 99) < (b.rank or 99) end)

    local seen, deduped = {}, {}
    for _, p in ipairs(out) do
        local k = p.title:lower()
        if not seen[k] then seen[k] = true; table.insert(deduped, p) end
    end
    return deduped
end

local function parsePicksFromText(text)
    if not text or text == "" then return nil end
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then return nil end
    text = text:gsub("```%w*", ""):gsub("```", "")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")

    local first = text:find("{")
    if first then
        local attempts = {text}
        local depth, lastOpen = 0, nil
        for i = first, #text do
            local c = text:sub(i, i)
            if c == "{" then
                depth = depth + 1
                if depth == 1 then lastOpen = i end
            elseif c == "}" then
                depth = depth - 1
                if depth == 0 and lastOpen then
                    table.insert(attempts, text:sub(lastOpen, i))
                    break
                end
            end
        end
        for _, c in ipairs(attempts) do
            local ok, data = pcall(function() return HttpService:JSONDecode(c) end)
            if ok and type(data) == "table" then
                if data.picks or data.path or data.routes or data.steps or data.pick or data.title then
                    local picks = normalizePicks(data)
                    if #picks > 0 then
                        return {picks = picks, _raw = data}
                    end
                end
            end
        end
    end

    local markdown_picks = {}
    for bold in text:gmatch("%*%*(.-)%*%*") do
        bold = bold:gsub("^%s+", ""):gsub("%s+$", "")
        if #bold >= 2 and #bold <= 80 then
            local low = bold:lower()
            local labels = {
                "approach","reasoning","why","reason","answer","result","target","next","pick","choice",
                "explanation","notes","note","caution","warning","summary","step","steps","strategy","path",
            }
            local isLabel = false
            for _, lbl in ipairs(labels) do
                if low == lbl then isLabel = true; break end
            end
            local hasThai = false
            for i = 1, #bold do
                local b = bold:byte(i)
                if b and b >= 0xE0 and b <= 0xEF then hasThai = true; break end
            end
            local cleanBold = bold:gsub("^[%(%)%[%]]+", ""):gsub("[%(%)%[%]]+$", "")
            cleanBold = cleanBold:gsub("^%s+", ""):gsub("%s+$", "")
            if not isLabel and not hasThai and isEnglish(cleanBold) then
                local found = false
                for _, e in ipairs(markdown_picks) do
                    if e:lower() == cleanBold:lower() then found = true; break end
                end
                if not found then table.insert(markdown_picks, cleanBold) end
            end
        end
    end

    for line in text:gmatch("[^\r\n]+") do
        local clean = line
        clean = clean:gsub("[\240\159][\128-\191][\128-\191][\128-\191]", "")
        clean = clean:gsub("[\226\152-\226\159][\128-\191]", "")
        clean = clean:gsub("[\226\156-\226\159][\128-\191]", "")
        clean = clean:gsub("%*%*([^*]+)%*%*", "%1")
        clean = clean:gsub("%*([^*]+)%*", "%1")
        clean = clean:gsub("^#+%s*", "")
        clean = clean:gsub("^%s+", ""):gsub("%s+$", "")
        if clean ~= "" then
            local target = clean:match("%-%>%s*(.+)$") or clean:match("→%s*(.+)$") or clean:match("⇒%s*(.+)$")
            if target then
                target = target:gsub("^%s+", ""):gsub("%s+$", "")
                target = target:gsub("^[%(%)%[%]]+", ""):gsub("[%(%)%[%]]+$", "")
                target = target:gsub("%s*[-–—%.%,]$", "")
                if #target >= 2 and isEnglish(target) then
                    local found = false
                    for _, e in ipairs(markdown_picks) do
                        if e:lower() == target:lower() then found = true; break end
                    end
                    if not found then table.insert(markdown_picks, target) end
                end
            end
        end
    end

    if #markdown_picks > 0 then
        local picks = {}
        for i, t in ipairs(markdown_picks) do
            table.insert(picks, {rank = i, title = t, _source = "markdown"})
        end
        return {picks = picks, _raw = {markdown = true}}
    end

    local lines = {}
    for line in text:gmatch("[^\r\n]+") do
        line = line:gsub("^%s+", ""):gsub("%s+$", "")
        if line ~= ""
            and not line:match("^[Cc][Uu][Rr][Rr][Ee][Nn][Tt]:")
            and not line:match("^[Tt][Aa][Rr][Gg][Ee][Tt]:")
            and not line:match("^[Cc][Aa][Nn][Dd][Ii][Dd][Aa][Tt][Ee][Ss]:")
            and not line:match("^%d+%.%s*$") then
            line = line:gsub("^%d+%.%s*", ""):gsub("^[-%*]%s*", "")
            if line ~= "" and isEnglish(line) then
                table.insert(lines, line)
            end
        end
    end
    if #lines == 1 then
        return {picks = {{rank = 1, title = lines[1]}}, _raw = {plain = true}}
    elseif #lines >= 2 then
        local picks = {}
        for i, t in ipairs(lines) do table.insert(picks, {rank = i, title = t}) end
        return {picks = picks, _raw = {plain = true}}
    end
    if #text > 0 and #text < 200 and not text:find("\n") then
        local parts = {}
        for p in text:gmatch("[^,;]+") do
            p = p:gsub("^%s+", ""):gsub("%s+$", "")
            if p ~= "" and isEnglish(p) then table.insert(parts, p) end
        end
        if #parts >= 1 then
            local picks = {}
            for i, t in ipairs(parts) do table.insert(picks, {rank = i, title = t}) end
            return {picks = picks, _raw = {plain = true}}
        end
    end
    return nil
end

-- ==================== ⚡ FORWARD-ONLY CHAIN ====================
local function fireNextChain()
    if not autoChainActive then return end

    local nextTitle = nil
    while #autoChainQueue > 0 do
        local candidate = table.remove(autoChainQueue, 1)
        local key = normalize(candidate):lower()
        if not chainHistory[key] then
            nextTitle = candidate
            chainHistory[key] = true
            break
        else
            addLine("[CHAIN] ⏭ skip ซ้ำ: " .. candidate, ORANGE_WARN)
        end
    end

    if not nextTitle then
        autoChainActive = false
        addLine("[CHAIN] ✓ ครบทุกหน้า ⚡", GREEN_OK)
        statusLbl.Text = "🐽 Chain DONE"
        return
    end

    addPathLog(nextTitle, "chain")
    addLine("[CHAIN] ⚡ → " .. nextTitle, GREEN_OK)
    if not navigateToTitle(nextTitle) then
        task.defer(fireNextChain)
    end
end

local function startInstantChain(picks)
    autoChainQueue = {}
    chainHistory = {}
    chainCurrentRank = 0

    if currentArticle then
        local normCur = normalize(currentArticle):lower()
        for _, p in ipairs(picks) do
            local pt = p.title or ""
            if normalize(pt):lower() == normCur then
                chainCurrentRank = tonumber(p.rank) or 0
                addLine("[CHAIN] 📍 rank ปัจจุบัน = " .. chainCurrentRank .. " (" .. pt .. ")", PINK_DARK)
                chainHistory[normCur] = true
                break
            end
        end
    end

    local skipped = 0
    for _, p in ipairs(picks) do
        local t = p.title or ""
        if t ~= "" then
            local r = tonumber(p.rank) or 999
            if r > chainCurrentRank then
                table.insert(autoChainQueue, t)
            else
                skipped = skipped + 1
            end
        end
    end

    if #autoChainQueue == 0 then
        addLine("[CHAIN] ไม่มี rank ถัดไปแล้ว", ORANGE_WARN)
        statusLbl.Text = "🐽 DONE"
        return
    end

    if skipped > 0 then
        addLine("[CHAIN] ⏭ ข้าม " .. skipped .. " rank ที่ผ่านมา", PINK_DARK)
    end

    autoChainActive = true
    addLine("[CHAIN] เริ่ม " .. #autoChainQueue .. " หน้า ⚡⚡⚡", GREEN_OK)
    fireNextChain()
end

-- ==================== 🔵🔴 AUTO (SIMPLE — v1 + soft bias) ====================
-- 🆕 ให้คะแนน 2 อย่างเท่านั้น:
--   • link ที่มีคำตรงกับ target → โบนัสเล็กน้อย
--   • link ที่ชื่อสั้น → โบนัสเล็กน้อย
-- แล้วเลือกแบบ weighted random (ไม่ใช่ hard sort)

local function simpleScore(candidate, target)
    local score = 1  -- base

    local cLow = tostring(candidate):lower()
    local tLow = tostring(target or ""):lower()

    -- 🎯 โบนัสถ้าตรงกับ target
    if tLow ~= "" then
        local tSup = superNormalize(target)
        local cSup = superNormalize(candidate)
        if cSup == tSup then
            score = score + 100   -- exact → น้ำหนักสูงมาก
        elseif #tSup >= 4 and cSup:find(tSup, 1, true) then
            score = score + 30
        else
            -- นับคำที่ตรง
            for w in tLow:gmatch("%a+") do
                if #w >= 4 and cLow:find(w, 1, true) then
                    score = score + 8
                end
            end
        end
    end

    -- 📏 ชื่อสั้นได้เปรียบ
    local len = #candidate
    if len <= 20 then score = score + 3
    elseif len <= 35 then score = score + 1 end

    return score
end

local function weightedRandomPick(pool, target)
    local total = 0
    local weights = {}
    for i, c in ipairs(pool) do
        local w = simpleScore(c, target)
        weights[i] = w
        total = total + w
    end
    if total <= 0 then
        return pool[math.random(1, #pool)]
    end
    local r = math.random() * total
    local acc = 0
    for i, w in ipairs(weights) do
        acc = acc + w
        if r <= acc then return pool[i] end
    end
    return pool[#pool]
end

local function doAutoExploreStep()
    if not autoExploreActive then return end
    if autoExploreBusy then return end
    autoExploreBusy = true

    -- 🔴 ตรวจแดงก่อน
    if hasRedCircleDot() then
        addLine("[AUTO] 🔴🔴🔴 RED CIRCLE — STOP!", RED_ERR)
        statusLbl.Text = "🔴 RED STOP"
        autoExploreActive = false
        autoExploreBusy = false
        autoBtn.BackgroundColor3 = ORANGE_WARN
        autoBtn.Text = "AUTO ⚡ OFF"
        return
    end

    if not currentArticle then refreshURL() end
    if not currentArticle or not currentArticleId then
        autoRetryCount = autoRetryCount + 1
        if autoRetryCount <= 5 then
            addLine("[AUTO] รอ page id... (" .. autoRetryCount .. "/5)", ORANGE_WARN)
        end
        autoExploreBusy = false
        task.defer(function()
            if autoExploreActive then
                task.wait(0.15)
                doAutoExploreStep()
            end
        end)
        return
    end
    autoRetryCount = 0

    local all = getAutoCandidates()
    if #all == 0 then
        addLine("[AUTO] ไม่มี link ฟ้า — รอ scan ใหม่", ORANGE_WARN)
        autoExploreBusy = false
        task.defer(function()
            if autoExploreActive then
                task.wait(0.3)
                doAutoExploreStep()
            end
        end)
        return
    end

    -- 🚫 ตัด visited (ถ้าหมด ใช้ all)
    local pool = {}
    for _, c in ipairs(all) do
        if not isVisited(c) then table.insert(pool, c) end
    end
    if #pool == 0 then pool = all end

    -- 🎯 ถ้าเจอ target ตรง → ยิงเลย
    if targetTitle then
        local tSup = superNormalize(targetTitle)
        for _, c in ipairs(pool) do
            if superNormalize(c) == tSup then
                addPathLog(c, "target")
                addLine("[AUTO] 🏆 TARGET! → " .. c, GREEN_OK)
                navigateToTitle(c)
                autoExploreBusy = false
                return
            end
        end
    end

    -- 🎲 weighted random (v1 แต่ให้น้ำหนักกับ target)
    local pick = weightedRandomPick(pool, targetTitle)
    addPathLog(pick, "auto")
    addLine("[AUTO] → " .. pick .. " (" .. #pool .. " cand)", GREEN_OK)

    local ok = navigateToTitle(pick)
    autoExploreBusy = false
    if not ok then
        task.defer(function()
            if autoExploreActive then
                task.wait(0.05)
                doAutoExploreStep()
            end
        end)
    end
end

local function startAutoExplore()
    if not autoExploreActive then return end
    addLine("[AUTO] 🚀 เริ่ม AUTO (v1 + soft target bias)", GREEN_OK)
    statusLbl.Text = "🔵 AUTO running"
    autoRetryCount = 0
    task.defer(doAutoExploreStep)
end

-- ==================== DO-GO ====================
local function doGo()
    if not currentArticle then refreshURL() end
    if currentArticle then
        local norm = normalize(currentArticle)
        blueWordCache[norm] = nil
        gameCache[norm] = nil
        local found = scanBlue()
        if #found > 0 then
            blueWordCache[norm] = found
            addLine("[scan] " .. #found .. " words", GREEN_OK)
        end
    end

    local text = pasteBox.Text or ""
    if text == "" then
        addLine("[X] paste box empty", RED_ERR)
        statusLbl.Text = "Paste JSON first"
        return
    end
    local data = parsePicksFromText(text)
    if not data or not data.picks or #data.picks == 0 then
        addLine("[X] parse failed", RED_ERR)
        statusLbl.Text = "Bad JSON/Text"
        return
    end

    lastPicks = data.picks
    addLine("[ok] " .. #data.picks .. " picks", GREEN_OK)

    for i = 1, math.min(10, #data.picks) do
        local p = data.picks[i]
        local tag = ""
        if p.rank then tag = tag .. " r" .. tostring(p.rank) end
        addLine("  #" .. i .. ": " .. (p.title or "?") .. tag, PINK_DEEP)
    end

    startInstantChain(data.picks)
end

-- ==================== BUTTONS ====================
local guiVisible = true

local function toggleMin()
    if content.Visible then
        content.Visible = false
        frame.Size = UDim2.new(0, 350, 0, 28)
        minBtn.Text = "+"
    else
        content.Visible = true
        frame.Size = UDim2.new(0, 350, 0, 300)
        minBtn.Text = "-"
    end
end
minBtn.MouseButton1Click:Connect(toggleMin)
minBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then toggleMin() end
end)

local function toggleClose()
    guiVisible = not guiVisible
    frame.Visible = guiVisible
end
closeBtn.MouseButton1Click:Connect(toggleClose)
closeBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then toggleClose() end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        guiVisible = not guiVisible
        frame.Visible = guiVisible
    end
end)

copyTargetBtn.MouseButton1Click:Connect(function()
    if not targetTitle or targetTitle == "" then
        addLine("[X] no target", RED_ERR); return
    end
    local safe = tostring(targetTitle):gsub("\\", "\\\\"):gsub('"', '\\"')
    local json = '{\n"picks": [\n{"Target": 1, "title": "' .. safe .. '"}\n]\n}'
    local ok = copyToClipboard(json)
    addLine("[target] " .. targetTitle .. (ok and " copied" or " FAIL"),
        ok and GREEN_OK or RED_ERR)
end)

hopBtn.MouseButton1Click:Connect(function()
    if not currentArticle then refreshURL() end
    if not currentArticle then addLine("[X] no current", RED_ERR); return end
    local filtered = getFilteredCandidates()
    if #filtered == 0 then addLine("[X] no candidates", RED_ERR); return end
    local lines = {
        "CURRENT: " .. currentArticle,
        "TARGET: " .. (targetTitle or "?"),
        "",
        "CANDIDATES:",
    }
    for i, c in ipairs(filtered) do table.insert(lines, i .. ". " .. c) end
    local ok = copyToClipboard(table.concat(lines, "\n"))
    addLine("[HOP] " .. #filtered .. " cand " .. (ok and "copied" or "FAIL"),
        ok and GREEN_OK or RED_ERR)
    hopArticle = currentArticle
end)

local function setAutoUI(on)
    if on then
        autoBtn.BackgroundColor3 = GREEN_OK
        autoBtn.Text = "AUTO ⚡ ON"
    else
        autoBtn.BackgroundColor3 = ORANGE_WARN
        autoBtn.Text = "AUTO ⚡ OFF"
    end
end

autoBtn.MouseButton1Click:Connect(function()
    autoExploreActive = not autoExploreActive
    setAutoUI(autoExploreActive)
    if autoExploreActive then
        addLine("[AUTO] ⚡ ON", GREEN_OK)
        if currentArticle then
            task.defer(startAutoExplore)
        end
    else
        addLine("[AUTO] OFF", PINK_DARK)
    end
end)

stopAutoBtn.MouseButton1Click:Connect(function()
    autoExploreActive = false
    autoChainActive = false
    setAutoUI(false)
    addLine("[AUTO] ⛔ STOP", RED_ERR)
    statusLbl.Text = "🛑 Stopped"
end)

-- 📋 LOG
copyLogBtn.MouseButton1Click:Connect(function()
    copyPathLog()
end)

pasteBtn.MouseButton1Click:Connect(function()
    if isProcessing then return end
    isProcessing = true
    local txt = getClipboard()
    if txt and #txt > 0 then
        pasteBox.Text = txt
        addLine("[paste] " .. #txt .. " chars", PINK_DARK)
        task.wait(0.05)
        doGo()
    else
        addLine("[paste] empty", PINK_DEEP)
    end
    task.wait(0.2)
    isProcessing = false
end)

clearJsonBtn.MouseButton1Click:Connect(function()
    pasteBox.Text = ""
    autoChainActive = false
    autoChainQueue = {}
    chainHistory = {}
    addLine("[clear] cleared", PINK_DEEP)
    statusLbl.Text = "🐽 Cleared"
end)

goBtn.MouseButton1Click:Connect(function()
    if isProcessing then return end
    isProcessing = true
    doGo()
    task.wait(0.2)
    isProcessing = false
end)

-- ==================== HOOKS ====================
local articleUpdated = Remotes:FindFirstChild("ArticleUpdated")
if articleUpdated then
    articleUpdated.OnClientEvent:Connect(function(payload)
        if type(payload) ~= "table" then return end
        local art = payload.Article
        if type(art) ~= "table" or not art.Title then return end

        local t = normalize(art.Title)
        local prev = currentArticle

        markVisited(t)
        addPathLog(t, "arrived")

        if prev and prev ~= t then
            table.insert(currentPath, t)
            if #currentPath > 20 then table.remove(currentPath, 1) end
        elseif not prev then
            table.insert(currentPath, t)
        end

        currentArticle = t
        if art.Id then currentArticleId = tostring(art.Id) end

        linkIdMap = {}
        if type(art.Links) == "table" then
            for _, v in pairs(art.Links) do
                if type(v) == "table" and v.Title and v.Id then
                    linkIdMap[normalize(v.Title)] = tostring(v.Id)
                end
            end
        end

        gameCache = {}
        local links = {}
        if type(art.Links) == "table" then
            for _, v in pairs(art.Links) do
                if type(v) == "table" and v.Title then
                    local n = normalize(v.Title)
                    if isEnglish(n) and not isUiJunk(n) then
                        table.insert(links, n)
                    end
                end
            end
        end
        gameCache[t] = links

        updateLabels()
        local idCount = 0
        for _ in pairs(linkIdMap) do idCount = idCount + 1 end
        addLine("[page] " .. t .. " (" .. #links .. " p, " .. idCount .. " id)", PINK_DARK)

        if autoChainActive then
            task.defer(fireNextChain)
        end
        if autoExploreActive then
            task.defer(doAutoExploreStep)
        end
    end)
end

local roundStarted = Remotes:FindFirstChild("RoundStarted")
if roundStarted then
    roundStarted.OnClientEvent:Connect(function(p)
        if type(p) ~= "table" then return end
        if p.StartArticle and p.StartArticle.Title then
            startTitle = normalize(p.StartArticle.Title)
            currentPath = {startTitle}
            visitedSet = {}
            pathLog = {}
            markVisited(startTitle)
            addPathLog(startTitle, "START")
        end
        if p.TargetArticle and p.TargetArticle.Title then
            targetTitle = normalize(p.TargetArticle.Title)
        end
        clickNum = 0
        autoChainActive = false
        autoChainQueue = {}
        chainHistory = {}
        chainCurrentRank = 0
        updateLabels()

        if autoExploreActive then
            addLine("[AUTO] 🎮 Round started!", GREEN_OK)
            task.defer(startAutoExplore)
        end
    end)
end

local roundStateChanged = Remotes:FindFirstChild("RoundStateChanged")
if roundStateChanged then
    roundStateChanged.OnClientEvent:Connect(function(p)
        if type(p) ~= "table" then return end
        if p.StartTitle then startTitle = normalize(p.StartTitle) end
        if p.TargetTitle then targetTitle = normalize(p.TargetTitle) end
        updateLabels()
    end)
end

-- ==================== INIT ====================
if gui and frame then gui.Enabled = true; frame.Visible = true end

addLine("⚡ v9.8 SIMPLE + LOG", GREEN_OK)
addLine("AUTO: สุ่มแบบ v1 + bias เป้า", PINK_DEEP)
addLine("📋 LOG: คัดลอกเส้นทาง", PINK_DARK)
statusLbl.Text = "🐽 Ready ⚡"
updateLabels()

print("[ATLAS v9.8 ⚡ SIMPLE + LOG] Loaded ✓")
