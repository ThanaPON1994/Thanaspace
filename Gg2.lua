-- ATLAS v8.5 — Copy Hop + Copy Target + Paste Gemini + AI Local (Auto-Detect IP)
-- 🐷 Pink Pig Edition (350 x 300)
-- 🆕 Model Selector 3b/7b + 🤖 AI button
-- 🆕 Auto-Detect Ollama IP (common IPs + subnet scan)
-- 🆕 ปุ่ม 🔍 IP rescan
-- 🆕 Title Bar: 這位傳奇的龍衝浪女孩回來了。
-- 🆕 Manual only — ไม่มี auto-hop

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local NavigateArticle = Remotes:WaitForChild("NavigateArticle")

-- ==================== 🤖 AI CONFIG (Auto-Detect) ====================
local AI_CONFIG = {
    enabled     = true,
    port        = 11434,
    detectedIP  = nil,
    timeout     = 30,
    max_cand    = 40,
    temperature = 0.2,
    num_predict = 400,
}

local IP_CANDIDATES = {
    "127.0.0.1",
    "localhost",
    "192.168.1.1",
    "192.168.0.1",
    "192.168.1.100",
    "192.168.0.100",
    "192.168.1.101",
    "192.168.0.101",
    "10.0.0.1",
    "10.0.0.100",
    "172.16.0.1",
    "172.16.0.100",
}

local MODEL_OPTIONS = {
    {id = "qwen2.5:3b", label = "3b"},
    {id = "qwen2.5:7b", label = "7b"},
}
local selectedModel = "qwen2.5:3b"

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
local PURPLE_AI   = Color3.fromRGB(130, 90, 220)
local GRAY_OFF    = Color3.fromRGB(200, 200, 210)
local GRAY_TEXT   = Color3.fromRGB(80, 80, 90)

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
        pcall(function() Delta.Clipboard.set(text) end)
        return true
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

local function getHTTP()
    if typeof(request) == "function" then return request end
    if typeof(http_request) == "function" then return http_request end
    if syn and syn.request then return syn.request end
    if http and http.request then return http.request end
    if fluxus and fluxus.request then return fluxus.request end
    if krnl and krnl.request then return krnl.request end
    return nil
end

-- ==================== DIACRITICS MAP ====================
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
    ["\225\186\160"]="a",["\225\186\161"]="a",["\225\186\162"]="a",["\225\186\163"]="a",["\225\186\164"]="a",["\225\186\165"]="a",
    ["\225\186\166"]="a",["\225\186\167"]="a",["\225\186\168"]="a",["\225\186\169"]="a",["\225\186\170"]="a",["\225\186\171"]="a",
    ["\225\186\172"]="a",["\225\186\173"]="a",["\225\186\174"]="a",["\225\186\175"]="a",["\225\186\176"]="a",["\225\186\177"]="a",
    ["\225\186\178"]="a",["\225\186\179"]="a",["\225\186\180"]="a",["\225\186\181"]="a",["\225\186\182"]="a",["\225\186\183"]="a",
    ["\225\186\184"]="e",["\225\186\185"]="e",["\225\186\186"]="e",["\225\186\187"]="e",["\225\186\188"]="e",["\225\186\189"]="e",
    ["\225\186\190"]="e",["\225\186\191"]="e",["\225\187\128"]="e",["\225\187\129"]="e",["\225\187\130"]="e",["\225\187\131"]="e",
    ["\225\187\132"]="e",["\225\187\133"]="e",["\225\187\134"]="e",["\225\187\135"]="e",["\225\187\136"]="i",["\225\187\137"]="i",
    ["\225\187\138"]="i",["\225\187\139"]="i",["\225\187\140"]="o",["\225\187\141"]="o",["\225\187\142"]="o",["\225\187\143"]="o",
    ["\225\187\144"]="o",["\225\187\145"]="o",["\225\187\146"]="o",["\225\187\147"]="o",["\225\187\148"]="o",["\225\187\149"]="o",
    ["\225\187\150"]="o",["\225\187\151"]="o",["\225\187\152"]="o",["\225\187\153"]="o",["\225\187\154"]="o",["\225\187\155"]="o",
    ["\225\187\156"]="o",["\225\187\157"]="o",["\225\187\158"]="o",["\225\187\159"]="o",["\225\187\160"]="o",["\225\187\161"]="o",
    ["\225\187\162"]="o",["\225\187\163"]="o",["\225\187\164"]="u",["\225\187\165"]="u",["\225\187\166"]="u",["\225\187\167"]="u",
    ["\225\187\168"]="u",["\225\187\169"]="u",["\225\187\170"]="u",["\225\187\171"]="u",["\225\187\172"]="u",["\225\187\173"]="u",
    ["\225\187\174"]="u",["\225\187\175"]="u",["\225\187\176"]="u",["\225\187\177"]="u",["\225\187\178"]="y",["\225\187\179"]="y",
    ["\225\187\180"]="y",["\225\187\181"]="y",["\225\187\182"]="y",["\225\187\183"]="y",["\225\187\184"]="y",["\225\187\185"]="y",
}

local function stripDiacritics(s)
    if not s or s == "" then return s end
    s = s:gsub("[\228-\233][\128-\191][\128-\191]", function(c)
        return DIACRITIC_MAP[c] or c
    end)
    s = s:gsub("[\194-\199][\128-\191]", function(c)
        return DIACRITIC_MAP[c] or c
    end)
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

-- ==================== BLUE DETECTION ====================
local function isBlue(color)
    local r, g, b = color.R * 255, color.G * 255, color.B * 255
    if math.abs(r - g) < 10 and math.abs(g - b) < 10 and math.abs(r - b) < 10 then
        return false
    end
    if b < 55 then return false end
    if b < r - 15 or b < g - 15 then return false end
    if b > 100 and b > r + 20 and b > g + 15 then return true end
    if b > 130 and b > r and b > g then
        if r + g + b > 300 then return true end
    end
    if b > 90 and b >= r and b >= g and (b - r) >= 5 then return true end
    if b > 110 and r > g - 10 and b > g + 10 then return true end
    if b > 90 and r > 60 and g < r - 15 and g < b - 15 then return true end
    if b > 100 and g > 100 and b >= r + 20 and math.abs(g - b) < 60 then return true end
    if b > 80 and b > r + 30 and b > g + 30 then return true end
    return false
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

-- ==================== UI JUNK FILTER ====================
local UI_JUNK = {
    ["search wikibloxia"]=true,
    ["wikirace! article translation pull"]=true,
    ["players"]=true, ["shop"]=true, ["style"]=true,
    ["scores"]=true, ["leave"]=true, ["skip"]=true,
    ["host"]=true, ["standard"]=true, ["unlimited"]=true,
    ["wikibloxia"]=true, ["time left"]=true,
    ["wikirace!"]=true, ["wikirace"]=true,
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
local clickNum = 0
local lastPicks = {}
local isProcessing = false
local hopArticle = nil

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
gui.Name = "AtlasPig"
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
    local nC = Instance.new("UICorner")
    nC.CornerRadius = UDim.new(1, 0)
    nC.Parent = nostril
end

for i = 0, 1 do
    local eye = Instance.new("Frame")
    eye.Size = UDim2.new(0, 4, 0, 4)
    eye.Position = UDim2.new(0, 11 + i * 6, 0.2, 0)
    eye.BackgroundColor3 = PINK_DEEP
    eye.BorderSizePixel = 0
    eye.Parent = titleBar
    local eC = Instance.new("UICorner")
    eC.CornerRadius = UDim.new(1, 0)
    eC.Parent = eye
end

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -80, 1, 0)
title.Position = UDim2.new(0, 34, 0, 0)
title.BackgroundTransparency = 1
title.Text = "這位傳奇的龍衝浪女孩回來了。"
title.TextColor3 = WHITE
title.Font = Enum.Font.SourceSansBold
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextTruncate = Enum.TextTruncate.AtEnd
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
local mbC = Instance.new("UICorner")
mbC.CornerRadius = UDim.new(1, 0)
mbC.Parent = minBtn

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
local cbC = Instance.new("UICorner")
cbC.CornerRadius = UDim.new(1, 0)
cbC.Parent = closeBtn

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
local ilC = Instance.new("UICorner")
ilC.CornerRadius = UDim.new(0, 8)
ilC.Parent = infoLbl

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
local ctC = Instance.new("UICorner")
ctC.CornerRadius = UDim.new(0, 8)
ctC.Parent = copyTargetBtn

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
local clC = Instance.new("UICorner")
clC.CornerRadius = UDim.new(0, 8)
clC.Parent = currentLbl

local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1, -70, 0, 16)
statusLbl.Position = UDim2.new(0, 6, 0, 44)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "🐽 Ready."
statusLbl.TextColor3 = PINK_DEEP
statusLbl.Font = Enum.Font.SourceSans
statusLbl.TextSize = 11
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.TextTruncate = Enum.TextTruncate.AtEnd
statusLbl.Parent = content

-- 🆕 ปุ่ม 🔍 IP (rescan)
local rescanBtn = Instance.new("TextButton")
rescanBtn.Size = UDim2.new(0, 60, 0, 14)
rescanBtn.Position = UDim2.new(1, -66, 0, 45)
rescanBtn.BackgroundColor3 = ORANGE_WARN
rescanBtn.Text = "🔍 IP"
rescanBtn.TextColor3 = WHITE
rescanBtn.Font = Enum.Font.SourceSansBold
rescanBtn.TextSize = 10
rescanBtn.BorderSizePixel = 0
rescanBtn.Parent = content
local rsC = Instance.new("UICorner")
rsC.CornerRadius = UDim.new(0, 6)
rsC.Parent = rescanBtn

-- ==================== ROW: 小女孩 | 3b | 7b | 🤖 AI ====================
local hopBtn = Instance.new("TextButton")
hopBtn.Size = UDim2.new(0, 108, 0, 28)
hopBtn.Position = UDim2.new(0, 6, 0, 64)
hopBtn.BackgroundColor3 = PINK_DEEP
hopBtn.Text = "小女孩"
hopBtn.TextColor3 = WHITE
hopBtn.Font = Enum.Font.SourceSansBold
hopBtn.TextSize = 13
hopBtn.BorderSizePixel = 0
hopBtn.Parent = content
local hbC = Instance.new("UICorner")
hbC.CornerRadius = UDim.new(0, 10)
hbC.Parent = hopBtn

local modelBtns = {}

local function updateModelBtns()
    for _, m in ipairs(modelBtns) do
        if m.id == selectedModel then
            m.btn.BackgroundColor3 = PURPLE_AI
            m.btn.TextColor3 = WHITE
        else
            m.btn.BackgroundColor3 = GRAY_OFF
            m.btn.TextColor3 = GRAY_TEXT
        end
    end
end

for i, opt in ipairs(MODEL_OPTIONS) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 48, 0, 28)
    b.Position = UDim2.new(0, 118 + (i-1) * 52, 0, 64)
    b.BackgroundColor3 = GRAY_OFF
    b.Text = opt.label
    b.TextColor3 = GRAY_TEXT
    b.Font = Enum.Font.SourceSansBold
    b.TextSize = 13
    b.BorderSizePixel = 0
    b.Parent = content
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 10)
    c.Parent = b

    table.insert(modelBtns, {id = opt.id, btn = b})

    b.MouseButton1Click:Connect(function()
        selectedModel = opt.id
        updateModelBtns()
        addLine("[model] " .. opt.id, PURPLE_AI)
        statusLbl.Text = "Model: " .. opt.label
    end)
end

local aiBtn = Instance.new("TextButton")
aiBtn.Size = UDim2.new(0, 110, 0, 28)
aiBtn.Position = UDim2.new(0, 222, 0, 64)
aiBtn.BackgroundColor3 = PURPLE_AI
aiBtn.Text = "🤖 AI"
aiBtn.TextColor3 = WHITE
aiBtn.Font = Enum.Font.SourceSansBold
aiBtn.TextSize = 13
aiBtn.BorderSizePixel = 0
aiBtn.Parent = content
local aiC = Instance.new("UICorner")
aiC.CornerRadius = UDim.new(0, 10)
aiC.Parent = aiBtn

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
pasteBox.PlaceholderText = '{"pick":{"title":"..."}} หรือพิมพ์ชื่อเพจตรงๆ'
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
local pbC = Instance.new("UICorner")
pbC.CornerRadius = UDim.new(0, 10)
pbC.Parent = pasteBox

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
local pC = Instance.new("UICorner")
pC.CornerRadius = UDim.new(0, 10)
pC.Parent = pasteBtn

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
local cjC = Instance.new("UICorner")
cjC.CornerRadius = UDim.new(0, 10)
cjC.Parent = clearJsonBtn

local goBtn = Instance.new("TextButton")
goBtn.Size = UDim2.new(0, 114, 0, 28)
goBtn.Position = UDim2.new(0, 234, 0, 160)
goBtn.BackgroundColor3 = GREEN_OK
goBtn.Text = "GO 🐽"
goBtn.TextColor3 = WHITE
goBtn.Font = Enum.Font.SourceSansBold
goBtn.TextSize = 12
goBtn.BorderSizePixel = 0
goBtn.Parent = content
local gbC = Instance.new("UICorner")
gbC.CornerRadius = UDim.new(0, 10)
gbC.Parent = goBtn

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -12, 1, -196)
scroll.Position = UDim2.new(0, 6, 0, 194)
scroll.BackgroundColor3 = PINK_FIELD
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = content
local scC = Instance.new("UICorner")
scC.CornerRadius = UDim.new(0, 10)
scC.Parent = scroll

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
        pcall(function()
            scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y)
        end)
    end)
end

-- ==================== 🤖 AUTO-DETECT OLLAMA IP ====================
local function buildSubnetList()
    local list = {}
    for _, prefix in ipairs({"192.168.1.", "192.168.0.", "192.168.43.", "10.0.0."}) do
        for i = 2, 254 do
            table.insert(list, prefix .. i)
        end
    end
    return list
end

local function testOllamaIP(ip, httpFn)
    local url = "http://" .. ip .. ":" .. AI_CONFIG.port .. "/api/tags"
    local ok, res = pcall(function()
        return httpFn({
            Url = url,
            Method = "GET",
            Headers = {["Content-Type"] = "application/json"},
        })
    end)
    if ok and res and res.StatusCode == 200 then
        return true
    end
    return false
end

local function autoDetectOllama(onLog)
    local httpFn = getHTTP()
    if not httpFn then
        if onLog then onLog("[IP] no HTTP function", false) end
        return nil
    end

    if onLog then onLog("[IP] scanning common IPs...", nil) end
    for _, ip in ipairs(IP_CANDIDATES) do
        if testOllamaIP(ip, httpFn) then
            if onLog then onLog("[IP] ✅ found: " .. ip, true) end
            return ip
        end
    end

    if onLog then onLog("[IP] scanning subnet (20-40s)...", nil) end
    local subnets = buildSubnetList()

    local found = nil
    local batchSize = 20

    for i = 1, #subnets, batchSize do
        if found then break end
        for j = i, math.min(i + batchSize - 1, #subnets) do
            local ip = subnets[j]
            task.spawn(function()
                if not found and testOllamaIP(ip, httpFn) then
                    found = ip
                end
            end)
        end
        task.wait(1.5)
    end

    if found then
        if onLog then onLog("[IP] ✅ found in subnet: " .. found, true) end
        return found
    end

    if onLog then onLog("[IP] ❌ not found. ตั้ง OLLAMA_HOST=0.0.0.0", false) end
    return nil
end

local function getOllamaURL(onLog)
    if not AI_CONFIG.detectedIP then
        AI_CONFIG.detectedIP = autoDetectOllama(onLog)
    end
    if AI_CONFIG.detectedIP then
        return "http://" .. AI_CONFIG.detectedIP .. ":" .. AI_CONFIG.port .. "/api/generate"
    end
    return nil
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
                    if p:IsA("GuiObject") and not p.Visible then
                        vis = false; break
                    end
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

-- ==================== MERGE SOURCES ====================
local function getFilteredCandidates()
    if not currentArticle then return {} end
    local norm = normalize(currentArticle)

    local fromCache = gameCache[norm] or {}
    local fromScan = scanBlue()
    local fromOld = blueWordCache[norm] or {}

    local candidates = {}
    local seen = {}
    local function addSource(list)
        for _, c in ipairs(list) do
            if c and c ~= "" then
                local k = c:lower()
                if not seen[k] then
                    seen[k] = true
                    table.insert(candidates, c)
                end
            end
        end
    end
    addSource(fromCache)
    addSource(fromScan)
    addSource(fromOld)

    if #fromScan > 0 then
        blueWordCache[norm] = fromScan
    end

    local filtered = {}
    for _, c in ipairs(candidates) do
        if isEnglish(c) and not isUiJunk(c) and not isVisited(c) then
            table.insert(filtered, c)
        end
    end

    if #filtered > 60 then
        local capped = {}
        for i = 1, 60 do capped[i] = filtered[i] end
        filtered = capped
    end
    return filtered
end

-- ==================== FALLBACK CLICK ====================
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

        addLine("[click-try] " .. f.disp .. " (score=" .. f.score .. ")", ORANGE_WARN)

        local ok = false

        pcall(function()
            if target.Activate then target:Activate(); ok = true end
        end)

        if not ok then
            pcall(function()
                if target.MouseButton1Click then target.MouseButton1Click:Fire(); ok = true end
            end)
        end

        if not ok then
            pcall(function()
                if target.MouseButton1Down then target.MouseButton1Down:Fire() end
                if target.MouseButton1Up then target.MouseButton1Up:Fire() end
                ok = true
            end)
        end

        if ok then
            addLine("[click-ok] " .. f.disp, GREEN_OK)
            return true
        end
    end

    return false
end

-- ==================== NAVIGATE ====================
local function navigateToTitle(title)
    if not title then return false end
    if not currentArticle or not currentArticleId then
        addLine("[X] no current id", RED_ERR)
        return false
    end

    if normalize(title):lower() == normalize(currentArticle):lower() then
        addLine("[skip] " .. title .. " = หน้าปัจจุบัน", ORANGE_WARN)
        return false
    end

    local normTitle = normalize(title)
    local targetId = nil
    local matchType = ""

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
        addLine("[no-id] " .. title .. " → ลองคลิกตรง", ORANGE_WARN)

        if tryClickVisibleLink(title) then
            addLine("[GO] " .. title .. " (clicked, no id)", GREEN_OK)
            markVisited(title)
            statusLbl.Text = "Clicked " .. title
            return true
        end

        addLine("[X] no id: " .. title, RED_ERR)
        addLine("  ⚠️ หาปุ่มไม่เจอ", ORANGE_WARN)

        local available = {}
        for k, _ in pairs(linkIdMap) do table.insert(available, k) end

        local targetSuper = superNormalize(normTitle)
        local lowTitle = normTitle:lower()
        local firstWord = lowTitle:match("^(%a+)")

        table.sort(available, function(a, b)
            local function score(s)
                local sSuper = superNormalize(s)
                local sLow = s:lower()
                local sc = 0
                if sSuper == targetSuper then sc = sc + 10 end
                if #targetSuper >= 3 and sSuper:find(targetSuper, 1, true) then sc = sc + 6 end
                if firstWord and sLow:find(firstWord, 1, true) then sc = sc + 5 end
                if math.abs(#sSuper - #targetSuper) < 5 then sc = sc + 3 end
                if sSuper:sub(1,1) == targetSuper:sub(1,1) then sc = sc + 2 end
                return sc
            end
            return score(a) > score(b)
        end)

        if #available > 0 then
            addLine("  [มี " .. #available .. " ลิงก์]", ORANGE_WARN)
            addLine("  🔍 ใกล้เคียงที่สุด:", ORANGE_WARN)
            for i = 1, math.min(5, #available) do
                addLine("    • " .. available[i], PINK_DARK)
            end
        else
            addLine("  ⚠️ linkIdMap ว่าง!", RED_ERR)
        end
        statusLbl.Text = "No link to " .. title
        return false
    end

    clickNum = clickNum + 1
    local tag = matchType ~= "exact" and (" [" .. matchType .. "]") or ""
    addLine("[GO] " .. title .. " (id=" .. targetId .. ")" .. tag, GREEN_OK)
    pcall(function()
        NavigateArticle:FireServer(currentArticleId, targetId, clickNum)
    end)
    markVisited(title)
    statusLbl.Text = "Navigating to " .. title
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
            confidence   = entry.confidence or entry.Confidence
                           or entry.score or entry.Score,
            path_preview = entry.path_preview or entry.path or entry.Path,
        })
    end

    if type(data.picks) == "table" then
        for i, p in ipairs(data.picks) do pushTitle(p, i) end
    end
    if data.pick ~= nil then pushTitle(data.pick, 1) end
    if #out == 0 and type(data.title) == "string" and data.title ~= "" then
        table.insert(out, {rank = 1, title = data.title, why = data.reasoning or data.reason})
    end

    table.sort(out, function(a, b) return (a.rank or 99) < (b.rank or 99) end)

    local seen, deduped = {}, {}
    for _, p in ipairs(out) do
        local k = p.title:lower()
        if not seen[k] then
            seen[k] = true
            table.insert(deduped, p)
        end
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
                if data.picks or data.pick or data.title then
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
            local isLabel = false
            local labels = {
                "approach", "reasoning", "why", "reason", "answer",
                "result", "target", "next", "pick", "choice",
                "explanation", "notes", "note", "caution", "warning",
                "summary", "step", "steps", "strategy", "path",
                "เหตุผล", "คำตอบ", "เป้าหมาย", "หมายเหตุ", "คำเตือน",
                "กลยุทธ์", "ขั้นตอน", "สรุป",
            }
            for _, lbl in ipairs(labels) do
                if low == lbl then isLabel = true; break end
            end

            local hasThai = false
            for i = 1, #bold do
                local b = bold:byte(i)
                if b and b >= 0xE0 and b <= 0xEF then
                    hasThai = true; break
                end
            end

            local cleanBold = bold:gsub("^[%(%)%[%]]+", ""):gsub("[%(%)%[%]]+$", "")
            cleanBold = cleanBold:gsub("^%s+", ""):gsub("%s+$", "")

            if not isLabel and not hasThai and isEnglish(cleanBold) then
                local found = false
                for _, existing in ipairs(markdown_picks) do
                    if existing:lower() == cleanBold:lower() then
                        found = true; break
                    end
                end
                if not found then
                    table.insert(markdown_picks, cleanBold)
                end
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
            local target = nil
            target = clean:match("%-%>%s*(.+)$") or
                     clean:match("→%s*(.+)$") or
                     clean:match("⇒%s*(.+)$")

            if target then
                target = target:gsub("^%s+", ""):gsub("%s+$", "")
                target = target:gsub("^[%(%)%[%]]+", ""):gsub("[%(%)%[%]]+$", "")
                target = target:gsub("%s*[-–—%.%,]$", "")

                if #target >= 2 and isEnglish(target) then
                    local found = false
                    for _, existing in ipairs(markdown_picks) do
                        if existing:lower() == target:lower() then
                            found = true; break
                        end
                    end
                    if not found then
                        table.insert(markdown_picks, target)
                    end
                end
            end
        end
    end

    if #markdown_picks == 0 then
        for line in text:gmatch("[^\r\n]+") do
            local clean = line
            clean = clean:gsub("[\240\159][\128-\191][\128-\191][\128-\191]", "")
            clean = clean:gsub("%*%*([^*]+)%*%*", "%1")
            clean = clean:gsub("%*([^*]+)%*", "%1")
            clean = clean:gsub("^%s+", ""):gsub("%s+$", "")

            local target = clean:match("^[^:]+:%s*(.+)$")
            if target then
                target = target:gsub("^%s+", ""):gsub("%s+$", "")
                target = target:gsub("^[%(%)%[%]]+", ""):gsub("[%(%)%[%]]+$", "")

                if #target >= 2 and #target <= 60 and isEnglish(target) then
                    if not target:find("^%s*เหตุผล") and
                       not target:find("^%s*reason") and
                       not target:find("^%s*because") then
                        table.insert(markdown_picks, target)
                    end
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
        for i, t in ipairs(lines) do
            table.insert(picks, {rank = i, title = t})
        end
        return {picks = picks, _raw = {plain = true}}
    end

    if #text > 0 and #text < 200 and not text:find("\n") then
        local parts = {}
        for p in text:gmatch("[^,;]+") do
            p = p:gsub("^%s+", ""):gsub("%s+$", "")
            if p ~= "" and isEnglish(p) then
                table.insert(parts, p)
            end
        end
        if #parts >= 1 then
            local picks = {}
            for i, t in ipairs(parts) do
                table.insert(picks, {rank = i, title = t})
            end
            return {picks = picks, _raw = {plain = true}}
        end
    end

    return nil
end

-- ==================== DO-GO ====================
local function doGo()
    if hopArticle and currentArticle and hopArticle ~= currentArticle then
        addLine("[!] หน้าเปลี่ยน!", ORANGE_WARN)
        addLine("    HOP=" .. hopArticle, ORANGE_WARN)
        addLine("    now=" .. currentArticle, ORANGE_WARN)
    end

    if not currentArticle then refreshURL() end
    if currentArticle then
        local norm = normalize(currentArticle)
        blueWordCache[norm] = nil
        gameCache[norm] = nil

        local found = scanBlue()
        if #found > 0 then
            blueWordCache[norm] = found
            addLine("[auto-scan] " .. #found .. " words", GREEN_OK)
            statusLbl.Text = "Auto-scanned " .. #found
        else
            addLine("[auto-scan] 0 words", PINK_DEEP)
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
    local srcTag = ""
    if data._raw and data._raw.plain then srcTag = " (plain)"
    elseif data._raw and data._raw.markdown then srcTag = " (md)" end
    addLine("[ok] " .. #data.picks .. " picks" .. srcTag, GREEN_OK)

    local navigated = false
    for i = 1, math.min(3, #data.picks) do
        local p = data.picks[i]
        local t = p.title or ""
        local tag = ""
        if p.confidence then tag = " [" .. tostring(p.confidence):sub(1, 4) .. "]" end
        addLine("  #" .. i .. ": " .. t .. tag, PINK_DEEP)
        if p.why then
            local short = tostring(p.why)
            if #short > 90 then short = short:sub(1, 87) .. "..." end
            addLine("     " .. short, PINK_DARK)
        end
        if not navigated then
            if navigateToTitle(t) then
                navigated = true
                break
            else
                if i < math.min(3, #data.picks) then
                    addLine("     ↳ ลองตัวเลือกถัดไป...", ORANGE_WARN)
                end
            end
        end
    end

    if navigated then
        statusLbl.Text = "Clicked 🐽"
    else
        statusLbl.Text = "All picks invalid"
    end
end

-- ==================== 🤖 BUILD AI PROMPT ====================
local function buildAIPrompt(candidates)
    local candLines = {}
    for i = 1, math.min(AI_CONFIG.max_cand, #candidates) do
        table.insert(candLines, i .. ". " .. candidates[i])
    end
    local candText = table.concat(candLines, "\n")

    return string.format([[
You are a WikiRace pathfinder. Pick the BEST next articles to reach TARGET fastest.

CURRENT: %s
TARGET: %s

CANDIDATES:
%s

Rules:
- Pick top 3 candidates closest to TARGET.
- Return ONLY valid JSON. No markdown. No explanation.
- Format: {"picks":[{"rank":1,"title":"Exact Name","why":"reason"},{"rank":2,"title":"Exact Name","why":"reason"},{"rank":3,"title":"Exact Name","why":"reason"}]}
- "title" MUST be copied EXACTLY from the CANDIDATES list above.
]], currentArticle or "?", targetTitle or "?", candText)
end

-- ==================== 🤖 ASK LOCAL AI ====================
local function askLocalAI()
    if not AI_CONFIG.enabled then
        addLine("[AI] disabled", ORANGE_WARN)
        return false
    end

    if not currentArticle then refreshURL() end
    if not currentArticle then
        addLine("[X] no current article", RED_ERR)
        return false
    end

    if not targetTitle then
        addLine("[X] no target set", RED_ERR)
        return false
    end

    local http = getHTTP()
    if not http then
        addLine("[X] no HTTP function!", RED_ERR)
        addLine("  → executor ไม่รองรับ request()", ORANGE_WARN)
        statusLbl.Text = "No HTTP support"
        return false
    end

    -- Auto-detect URL
    local ollamaURL = getOllamaURL(function(msg, ok)
        addLine(msg, ok == true and GREEN_OK or (ok == false and RED_ERR or ORANGE_WARN))
    end)
    if not ollamaURL then
        addLine("[X] Ollama not found on network", RED_ERR)
        addLine("  → รัน: OLLAMA_HOST=0.0.0.0 ollama serve", ORANGE_WARN)
        statusLbl.Text = "Ollama not found"
        return false
    end

    local filtered = getFilteredCandidates()
    if #filtered == 0 then
        addLine("[X] no candidates", RED_ERR)
        return false
    end

    addLine("[AI] " .. #filtered .. " cand → " .. selectedModel, PURPLE_AI)
    statusLbl.Text = "🤖 " .. selectedModel .. " thinking..."

    local prompt = buildAIPrompt(filtered)
    local body = HttpService:JSONEncode({
        model  = selectedModel,
        prompt = prompt,
        stream = false,
        format = "json",
        options = {
            temperature = AI_CONFIG.temperature,
            num_predict = AI_CONFIG.num_predict,
        }
    })

    local t0 = tick()
    local ok, res = pcall(function()
        return http({
            Url     = ollamaURL,
            Method  = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body    = body,
        })
    end)
    local dt = tick() - t0

    if not ok or not res then
        addLine("[X] HTTP failed (" .. string.format("%.1f", dt) .. "s)", RED_ERR)
        addLine("  → เปิด Ollama: ollama serve", ORANGE_WARN)
        AI_CONFIG.detectedIP = nil
        statusLbl.Text = "Ollama offline"
        return false
    end

    if res.StatusCode ~= 200 then
        addLine("[X] HTTP " .. tostring(res.StatusCode), RED_ERR)
        statusLbl.Text = "HTTP " .. tostring(res.StatusCode)
        return false
    end

    local parseOk, respData = pcall(function()
        return HttpService:JSONDecode(res.Body)
    end)

    if not parseOk or not respData or not respData.response then
        addLine("[X] bad response from Ollama", RED_ERR)
        return false
    end

    local answer = respData.response
    addLine("[AI] ✓ " .. string.format("%.1f", dt) .. "s → " .. #answer .. " chars", GREEN_OK)

    pasteBox.Text = answer
    doGo()
    return true
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
    if input.UserInputType == Enum.UserInputType.Touch then
        toggleMin()
    end
end)

local function toggleClose()
    guiVisible = not guiVisible
    frame.Visible = guiVisible
    print("[ATLAS] " .. (guiVisible and "เปิด" or "ปิด") .. " GUI (RightShift เปิดกลับ)")
end

closeBtn.MouseButton1Click:Connect(toggleClose)
closeBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        toggleClose()
    end
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
        addLine("[X] no target", RED_ERR)
        statusLbl.Text = "No target yet"
        return
    end
    local safe = tostring(targetTitle):gsub("\\", "\\\\"):gsub('"', '\\"')
    local json = '{\n"picks": [\n{"Target": 1, "title": "' .. safe .. '"}\n]\n}'
    local ok = copyToClipboard(json)
    addLine("[target] " .. targetTitle .. (ok and " copied" or " FAIL"),
        ok and GREEN_OK or RED_ERR)
    statusLbl.Text = ok and "Target copied" or "Copy failed"
end)

rescanBtn.MouseButton1Click:Connect(function()
    AI_CONFIG.detectedIP = nil
    addLine("[IP] rescanning...", ORANGE_WARN)
    statusLbl.Text = "🔍 Scanning..."
    task.spawn(function()
        local url = getOllamaURL(function(msg, ok)
            addLine(msg, ok == true and GREEN_OK or (ok == false and RED_ERR or ORANGE_WARN))
        end)
        if url then
            statusLbl.Text = "IP: " .. tostring(AI_CONFIG.detectedIP)
        else
            statusLbl.Text = "❌ IP not found"
        end
    end)
end)

hopBtn.MouseButton1Click:Connect(function()
    if not currentArticle then refreshURL() end
    if not currentArticle then
        addLine("[X] no current", RED_ERR)
        return
    end

    local norm = normalize(currentArticle)
    local cacheCount = #(gameCache[norm] or {})
    local scanList = scanBlue()
    local scanCount = #scanList

    local filtered = getFilteredCandidates()
    if #filtered == 0 then
        addLine("[X] no candidates", RED_ERR)
        return
    end

    local lines = {
        "CURRENT: " .. currentArticle,
        "TARGET: " .. (targetTitle or "?"),
        "",
        "CANDIDATES:",
    }
    for i, c in ipairs(filtered) do
        table.insert(lines, i .. ". " .. c)
    end
    local ok = copyToClipboard(table.concat(lines, "\n"))

    addLine("[hop-src] cache=" .. cacheCount .. " scan=" .. scanCount, PINK_DARK)
    addLine("[HOP] " .. #filtered .. " cand " .. (ok and "copied" or "FAIL"),
        ok and GREEN_OK or RED_ERR)

    local sample = {}
    for i = 1, math.min(5, #filtered) do
        table.insert(sample, filtered[i])
    end
    addLine("  → " .. table.concat(sample, ", "), PINK_DARK)

    hopArticle = currentArticle
    statusLbl.Text = "Paste into Gemini"
end)

aiBtn.MouseButton1Click:Connect(function()
    if isProcessing then
        addLine("[skip] กำลังทำงานอยู่ 🐽", PINK_DEEP)
        return
    end
    isProcessing = true
    task.spawn(function()
        pcall(askLocalAI)
        isProcessing = false
    end)
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.One
        and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        if not isProcessing then
            isProcessing = true
            task.spawn(function()
                pcall(askLocalAI)
                isProcessing = false
            end)
        end
    end
end)

pasteBtn.MouseButton1Click:Connect(function()
    if isProcessing then
        addLine("[skip] กำลังทำงานอยู่ 🐽", PINK_DEEP)
        return
    end
    isProcessing = true

    local txt = getClipboard()
    if txt and #txt > 0 then
        pasteBox.Text = txt
        addLine("[paste] " .. #txt .. " chars", PINK_DARK)
        statusLbl.Text = "Pasted → GO"

        task.wait(0.1)
        doGo()
    else
        addLine("[paste] empty", PINK_DEEP)
        statusLbl.Text = "Clipboard empty"
    end

    task.wait(0.5)
    isProcessing = false
end)

clearJsonBtn.MouseButton1Click:Connect(function()
    pasteBox.Text = ""
    addLine("[clear] json cleared", PINK_DEEP)
    statusLbl.Text = "Cleared"
end)

goBtn.MouseButton1Click:Connect(function()
    if isProcessing then
        addLine("[skip] กำลังทำงานอยู่ 🐽", PINK_DEEP)
        return
    end
    isProcessing = true

    doGo()

    task.wait(0.5)
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
                    if isEnglish(n) and not isUiJunk(n) then table.insert(links, n) end
                end
            end
        end
        gameCache[t] = links

        updateLabels()
        local idCount = 0
        for _ in pairs(linkIdMap) do idCount = idCount + 1 end
        addLine("[page] " .. t .. " (" .. #links .. " payload, " .. idCount .. " id)", PINK_DARK)
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
            markVisited(startTitle)
        end
        if p.TargetArticle and p.TargetArticle.Title then
            targetTitle = normalize(p.TargetArticle.Title)
        end
        clickNum = 0
        updateLabels()
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
if gui and frame then
    gui.Enabled = true
    frame.Visible = true
end

updateModelBtns()

addLine("🐷 v8.5 ready", GREEN_OK)
addLine("小女孩 → Gemini → 777  (manual)", PINK_DEEP)
addLine("หรือกด 🤖 AI (auto-detect IP)", PURPLE_AI)
addLine("Ctrl+1 = 🤖 AI เร็ว", PINK_DARK)
statusLbl.Text = "🐽 Ready"
updateLabels()

print("[ATLAS v8.5 🐷 Auto-Detect IP] Loaded ✓")
