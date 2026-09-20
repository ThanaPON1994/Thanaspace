-- ATLAS v10.3 — AUTO v1.5 BRIDGE + CATEGORY v2 + delay 0.1 ⚡
-- 🐷 Pink Pig Edition (350 x 300)

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
local PURPLE_HIT  = Color3.fromRGB(180, 120, 220)
local GOLD_HIT    = Color3.fromRGB(255, 200, 100)

local AUTO_DELAY = 0.1  -- 🆕 ค่าคงที่เดียว ปรับง่าย

-- ==================== HELPERS ====================
local function normalize(t)
    if not t or t == "" then return t end
    return tostring(t):gsub("_", " "):gsub("^%s+", ""):gsub("%s+$", "")
end

local function copyToClipboard(text)
    if not text or text == "" then return false end
    if setclipboard then local ok = pcall(setclipboard, text); if ok then return true end end
    if syn and syn.set_clipboard then local ok = pcall(syn.set_clipboard, text); if ok then return true end end
    if toclipboard then local ok = pcall(toclipboard, text); if ok then return true end end
    if writeclipboard then local ok = pcall(writeclipboard, text); if ok then return true end end
    if Delta and Delta.Clipboard and Delta.Clipboard.set then
        local ok = pcall(function() Delta.Clipboard.set(text) end); if ok then return true end
    end
    if writefile then pcall(function() writefile("atlas_log.txt", text) end) end
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

-- ==================== COLOR CHECK ====================
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

local UI_JUNK = {
    ["search wikibloxia"]=true, ["wikirace! article translation pull"]=true,
    ["players"]=true, ["shop"]=true, ["style"]=true,
    ["scores"]=true, ["leave"]=true, ["skip"]=true,
    ["host"]=true, ["standard"]=true, ["unlimited"]=true,
    ["wikibloxia"]=true, ["time left"]=true,
    ["wikirace!"]=true, ["wikirace"]=true,
    ["ui the free encyclopedia"]=true, ["the free encyclopedia"]=true,
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
    if low == "article read" then return true end
    return false
end

-- ==================== STATE ====================
local allLogs = {}
local gameCache = {}
local blueWordCache = {}
local linkIdMap = {}
local currentArticle, currentArticleId = nil, nil
local startTitle, targetTitle = nil, nil
local currentPath = {}
local visitedSet = {}
local pathLog = {}
local pickCount = {}
local clickNum = 0
local lastPicks = {}
local isProcessing = false
local autoChainQueue, autoChainActive, chainHistory, chainCurrentRank = {}, false, {}, 0
local autoExploreActive, autoExploreBusy, autoRetryCount = false, false, 0
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
    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextBox") then
            local text = obj.Text or ""
            if text:find("wikibloxia%.org") then
                local m = text:match("wiki/([^%s%?%#]+)")
                if m then
                    m = m:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
                    return normalize(m)
                end
            end
        end
    end
    return nil
end

-- ==================== GUI ====================
local gui = Instance.new("ScreenGui")
gui.Name = "傳說中的龍女來了"
gui.ResetOnSpawn = false
gui.DisplayOrder = 9999
gui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 350, 0, 300)
frame.Position = UDim2.new(0, 10, 0, 20)
frame.BackgroundColor3 = PINK_MAIN
frame.BorderSizePixel = 0
frame.Active = true
frame.Visible = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 20)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 28)
titleBar.BackgroundColor3 = PINK_DARK
titleBar.BorderSizePixel = 0
titleBar.Active = true
titleBar.Parent = frame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 20)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -80, 1, 0)
title.Position = UDim2.new(0, 34, 0, 0)
title.BackgroundTransparency = 1
title.Text = "傳說中的龍女來了 ⚡ v10.3"
title.TextColor3 = WHITE
title.Font = Enum.Font.SourceSansBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 20, 0, 20)
minBtn.Position = UDim2.new(1, -46, 0, 4)
minBtn.BackgroundColor3 = PINK_DEEP
minBtn.Text = "-"; minBtn.TextColor3 = WHITE
minBtn.Font = Enum.Font.SourceSansBold; minBtn.TextSize = 14
minBtn.BorderSizePixel = 0; minBtn.Parent = titleBar
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(1, 0)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 20, 0, 20)
closeBtn.Position = UDim2.new(1, -24, 0, 4)
closeBtn.BackgroundColor3 = RED_ERR
closeBtn.Text = "X"; closeBtn.TextColor3 = WHITE
closeBtn.Font = Enum.Font.SourceSansBold; closeBtn.TextSize = 12
closeBtn.BorderSizePixel = 0; closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)

local dragging, dragStart, startPos = false, nil, nil
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = frame.Position
    end
end)
titleBar.InputChanged:Connect(function(input)
    if dragging then
        local d = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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
infoLbl.BackgroundColor3 = PINK_FIELD; infoLbl.BorderSizePixel = 0
infoLbl.Text = "T: ?"; infoLbl.TextColor3 = PINK_DEEP
infoLbl.Font = Enum.Font.Code; infoLbl.TextSize = 11
infoLbl.TextXAlignment = Enum.TextXAlignment.Left
infoLbl.TextTruncate = Enum.TextTruncate.AtEnd
infoLbl.Parent = content
Instance.new("UICorner", infoLbl).CornerRadius = UDim.new(0, 8)

local copyTargetBtn = Instance.new("TextButton")
copyTargetBtn.Size = UDim2.new(0, 110, 0, 18)
copyTargetBtn.Position = UDim2.new(1, -116, 0, 4)
copyTargetBtn.BackgroundColor3 = PINK_DEEP
copyTargetBtn.Text = "COPY TARGET"; copyTargetBtn.TextColor3 = WHITE
copyTargetBtn.Font = Enum.Font.SourceSansBold; copyTargetBtn.TextSize = 10
copyTargetBtn.BorderSizePixel = 0; copyTargetBtn.Parent = content
Instance.new("UICorner", copyTargetBtn).CornerRadius = UDim.new(0, 8)

local currentLbl = Instance.new("TextLabel")
currentLbl.Size = UDim2.new(1, -12, 0, 18)
currentLbl.Position = UDim2.new(0, 6, 0, 24)
currentLbl.BackgroundColor3 = PINK_FIELD; currentLbl.BorderSizePixel = 0
currentLbl.Text = "C: ?"; currentLbl.TextColor3 = PINK_DARK
currentLbl.Font = Enum.Font.Code; currentLbl.TextSize = 11
currentLbl.TextXAlignment = Enum.TextXAlignment.Left
currentLbl.TextTruncate = Enum.TextTruncate.AtEnd
currentLbl.Parent = content
Instance.new("UICorner", currentLbl).CornerRadius = UDim.new(0, 8)

local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1, -12, 0, 16)
statusLbl.Position = UDim2.new(0, 6, 0, 44)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "🐽 Ready."
statusLbl.TextColor3 = PINK_DEEP
statusLbl.Font = Enum.Font.SourceSans; statusLbl.TextSize = 11
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.TextTruncate = Enum.TextTruncate.AtEnd
statusLbl.Parent = content

local hopBtn = Instance.new("TextButton")
hopBtn.Size = UDim2.new(0, 82, 0, 28); hopBtn.Position = UDim2.new(0, 6, 0, 64)
hopBtn.BackgroundColor3 = PINK_DEEP; hopBtn.Text = "小女孩"
hopBtn.TextColor3 = WHITE; hopBtn.Font = Enum.Font.SourceSansBold
hopBtn.TextSize = 13; hopBtn.BorderSizePixel = 0; hopBtn.Parent = content
Instance.new("UICorner", hopBtn).CornerRadius = UDim.new(0, 10)

local autoBtn = Instance.new("TextButton")
autoBtn.Size = UDim2.new(0, 90, 0, 28); autoBtn.Position = UDim2.new(0, 92, 0, 64)
autoBtn.BackgroundColor3 = ORANGE_WARN; autoBtn.Text = "AUTO ⚡ OFF"
autoBtn.TextColor3 = WHITE; autoBtn.Font = Enum.Font.SourceSansBold
autoBtn.TextSize = 11; autoBtn.BorderSizePixel = 0; autoBtn.Parent = content
Instance.new("UICorner", autoBtn).CornerRadius = UDim.new(0, 10)

local stopAutoBtn = Instance.new("TextButton")
stopAutoBtn.Size = UDim2.new(0, 82, 0, 28); stopAutoBtn.Position = UDim2.new(0, 186, 0, 64)
stopAutoBtn.BackgroundColor3 = RED_ERR; stopAutoBtn.Text = "STOP 🔴"
stopAutoBtn.TextColor3 = WHITE; stopAutoBtn.Font = Enum.Font.SourceSansBold
stopAutoBtn.TextSize = 11; stopAutoBtn.BorderSizePixel = 0; stopAutoBtn.Parent = content
Instance.new("UICorner", stopAutoBtn).CornerRadius = UDim.new(0, 10)

local copyLogBtn = Instance.new("TextButton")
copyLogBtn.Size = UDim2.new(0, 76, 0, 28); copyLogBtn.Position = UDim2.new(0, 272, 0, 64)
copyLogBtn.BackgroundColor3 = BLUE_LOG; copyLogBtn.Text = "📋 LOG"
copyLogBtn.TextColor3 = WHITE; copyLogBtn.Font = Enum.Font.SourceSansBold
copyLogBtn.TextSize = 12; copyLogBtn.BorderSizePixel = 0; copyLogBtn.Parent = content
Instance.new("UICorner", copyLogBtn).CornerRadius = UDim.new(0, 10)

local pasteLbl = Instance.new("TextLabel")
pasteLbl.Size = UDim2.new(1, -12, 0, 14); pasteLbl.Position = UDim2.new(0, 6, 0, 96)
pasteLbl.BackgroundTransparency = 1; pasteLbl.Text = "Paste Gemini JSON:"
pasteLbl.TextColor3 = PINK_DEEP; pasteLbl.Font = Enum.Font.SourceSans
pasteLbl.TextSize = 11; pasteLbl.TextXAlignment = Enum.TextXAlignment.Left
pasteLbl.Parent = content

local pasteBox = Instance.new("TextBox")
pasteBox.Size = UDim2.new(1, -12, 0, 44); pasteBox.Position = UDim2.new(0, 6, 0, 112)
pasteBox.BackgroundColor3 = PINK_FIELD; pasteBox.TextColor3 = PINK_DEEP
pasteBox.PlaceholderText = '{"path":[...]} / picks / พิมพ์ชื่อเพจตรงๆ'
pasteBox.Text = ""; pasteBox.Font = Enum.Font.Code; pasteBox.TextSize = 10
pasteBox.TextXAlignment = Enum.TextXAlignment.Left
pasteBox.TextYAlignment = Enum.TextYAlignment.Top
pasteBox.TextWrapped = true; pasteBox.MultiLine = true
pasteBox.ClearTextOnFocus = false; pasteBox.BorderSizePixel = 0
pasteBox.Parent = content
Instance.new("UICorner", pasteBox).CornerRadius = UDim.new(0, 10)

local pasteBtn = Instance.new("TextButton")
pasteBtn.Size = UDim2.new(0, 110, 0, 28); pasteBtn.Position = UDim2.new(0, 6, 0, 160)
pasteBtn.BackgroundColor3 = PINK_DARK; pasteBtn.Text = "777"
pasteBtn.TextColor3 = WHITE; pasteBtn.Font = Enum.Font.SourceSansBold
pasteBtn.TextSize = 12; pasteBtn.BorderSizePixel = 0; pasteBtn.Parent = content
Instance.new("UICorner", pasteBtn).CornerRadius = UDim.new(0, 10)

local clearJsonBtn = Instance.new("TextButton")
clearJsonBtn.Size = UDim2.new(0, 110, 0, 28); clearJsonBtn.Position = UDim2.new(0, 120, 0, 160)
clearJsonBtn.BackgroundColor3 = RED_ERR; clearJsonBtn.Text = "CLEAR"
clearJsonBtn.TextColor3 = WHITE; clearJsonBtn.Font = Enum.Font.SourceSansBold
clearJsonBtn.TextSize = 12; clearJsonBtn.BorderSizePixel = 0; clearJsonBtn.Parent = content
Instance.new("UICorner", clearJsonBtn).CornerRadius = UDim.new(0, 10)

local goBtn = Instance.new("TextButton")
goBtn.Size = UDim2.new(0, 114, 0, 28); goBtn.Position = UDim2.new(0, 234, 0, 160)
goBtn.BackgroundColor3 = GREEN_OK; goBtn.Text = "GO ⚡"
goBtn.TextColor3 = WHITE; goBtn.Font = Enum.Font.SourceSansBold
goBtn.TextSize = 12; goBtn.BorderSizePixel = 0; goBtn.Parent = content
Instance.new("UICorner", goBtn).CornerRadius = UDim.new(0, 10)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -12, 1, -196); scroll.Position = UDim2.new(0, 6, 0, 194)
scroll.BackgroundColor3 = PINK_FIELD; scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4; scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new(0, 0, 0, 0); scroll.Parent = content
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 10)
local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 2); layout.Parent = scroll

local function addLine(text, color)
    table.insert(allLogs, text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -4, 0, 12); l.BackgroundTransparency = 1
    l.Text = text; l.TextColor3 = color or PINK_DEEP
    l.Font = Enum.Font.Code; l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextTruncate = Enum.TextTruncate.AtEnd; l.Parent = scroll
    task.defer(function() pcall(function() scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y) end) end)
end

-- ==================== PATH LOG ====================
local function addPathLog(page, src)
    if not page or page == "" then return end
    table.insert(pathLog, {t=os.date("%H:%M:%S"), page=page, src=src or "?"})
    pickCount[page:lower()] = (pickCount[page:lower()] or 0) + 1
end

local logPopup = nil
local function showLogPopup(text)
    if logPopup then logPopup:Destroy() end
    logPopup = Instance.new("Frame")
    logPopup.Size = UDim2.new(0, 500, 0, 400)
    logPopup.Position = UDim2.new(0.5, -250, 0.5, -200)
    logPopup.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    logPopup.BorderSizePixel = 0; logPopup.ZIndex = 100; logPopup.Parent = gui
    Instance.new("UICorner", logPopup).CornerRadius = UDim.new(0, 12)
    local st = Instance.new("UIStroke", logPopup); st.Color = BLUE_LOG; st.Thickness = 2
    local ttl = Instance.new("TextLabel")
    ttl.Size = UDim2.new(1, -60, 0, 30); ttl.Position = UDim2.new(0, 10, 0, 0)
    ttl.BackgroundTransparency = 1
    ttl.Text = "📋 PATH LOG — Ctrl+A แล้ว Ctrl+C"
    ttl.TextColor3 = WHITE; ttl.Font = Enum.Font.SourceSansBold
    ttl.TextSize = 13; ttl.TextXAlignment = Enum.TextXAlignment.Left
    ttl.ZIndex = 101; ttl.Parent = logPopup
    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 30, 0, 26); close.Position = UDim2.new(1, -38, 0, 2)
    close.BackgroundColor3 = RED_ERR; close.Text = "X"
    close.TextColor3 = WHITE; close.Font = Enum.Font.SourceSansBold
    close.TextSize = 14; close.BorderSizePixel = 0; close.ZIndex = 101; close.Parent = logPopup
    Instance.new("UICorner", close).CornerRadius = UDim.new(0, 8)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -20, 1, -40); box.Position = UDim2.new(0, 10, 0, 34)
    box.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    box.TextColor3 = Color3.fromRGB(200, 220, 255)
    box.Font = Enum.Font.Code; box.TextSize = 11
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.TextYAlignment = Enum.TextYAlignment.Top
    box.TextWrapped = true; box.MultiLine = true
    box.ClearTextOnFocus = false; box.Text = text    box.BorderSizePixel = 0; box.ZIndex = 101; box.Parent = logPopup
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
    close.MouseButton1Click:Connect(function() logPopup:Destroy(); logPopup = nil end)
end

local function formatPathLog()
    local lines = {}
    table.insert(lines, "=== ATLAS v10.3 PATH LOG ===")
    table.insert(lines, "Start : " .. (startTitle or "?"))
    table.insert(lines, "Target: " .. (targetTitle or "?"))
    table.insert(lines, "Now   : " .. (currentArticle or "?"))
    table.insert(lines, "Hops  : " .. #pathLog)
    table.insert(lines, "")
    if #pathLog == 0 then
        table.insert(lines, "(ยังไม่มี hop)")
    else
        for i, e in ipairs(pathLog) do
            local line = string.format("%3d. [%s] %s", i, e.t, e.page)
            if e.src and e.src ~= "?" then line = line .. "  {" .. e.src .. "}" end
            table.insert(lines, line)
        end
    end
    table.insert(lines, "")
    table.insert(lines, "-- CANDIDATES ปัจจุบัน --")
    local okCand, cands = pcall(getAutoCandidates)
    if okCand and cands and #cands > 0 then
        for _, c in ipairs(cands) do table.insert(lines, "  • " .. c) end
    else
        table.insert(lines, "  (ยังไม่มี)")
    end
    return table.concat(lines, "\n")
end

local function copyPathLog()
    local text = formatPathLog()
    local ok = copyToClipboard(text)
    if ok then
        addLine("[COPY] ✓ " .. #pathLog .. " hops", GREEN_OK)
        statusLbl.Text = "📋 Copied " .. #pathLog .. " hops"
    else
        addLine("[COPY] ✗ copy ไม่ได้", ORANGE_WARN)
    end
    showLogPopup(text)
end

-- ==================== SCAN ====================
local function scanBlue()
    local items, seen_texts = {}, {}
    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if not obj:IsDescendantOf(gui) and (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then
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
    table.sort(items, function(a, b)
        if math.abs(a.y - b.y) > 6 then return a.y < b.y end
        return a.x < b.x
    end)
    local merged, cur = {}, nil
    for _, it in ipairs(items) do
        if not cur then
            cur = {text=it.text, x=it.x, y=it.y, endX=it.x+it.w}
        else
            local sameLine = math.abs(it.y - cur.y) <= 6
            local gap = it.x - cur.endX
            if sameLine and gap < 25 and gap > -10 then
                local addSpace = true
                if gap <= 0.5 then addSpace = false end
                local lastC = cur.text:sub(-1)
                if lastC == "-" or lastC == "'" or lastC == "/" or lastC == "." then addSpace = false end
                local firstC = it.text:sub(1, 1)
                if firstC == "," or firstC == "." or firstC == ")" or firstC == "!" or firstC == "?" or firstC == ":" or firstC == ";" then addSpace = false end
                if addSpace then cur.text = cur.text .. " " .. it.text else cur.text = cur.text .. it.text end
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

-- ==================== RED CIRCLE ====================
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
            if (isFrame or isImage) and isVisibleChain(obj) then
                local sizeX, sizeY = obj.AbsoluteSize.X, obj.AbsoluteSize.Y
                local sizeOk = sizeX >= 6 and sizeX <= 30 and sizeY >= 6 and sizeY <= 30
                local ratio = sizeX / math.max(sizeY, 1)
                local squareOk = ratio >= 0.85 and ratio <= 1.18
                if sizeOk and squareOk then
                    local isRealCircle = false
                    local corner = obj:FindFirstChildOfClass("UICorner")
                    if corner then
                        local cr = corner.CornerRadius
                        local minSide = math.min(sizeX, sizeY)
                        if cr.Scale >= 0.5 or cr.Offset >= minSide * 0.48 then isRealCircle = true end
                    end
                    if not isRealCircle then
                        local ar = obj:FindFirstChildOfClass("UIAspectRatioConstraint")
                        if ar and math.abs(ar.AspectRatio - 1) < 0.05 then isRealCircle = true end
                    end
                    if isRealCircle then
                        local red, reason = false, ""
                        if isFrame and obj.BackgroundTransparency < 0.3 and isRedColor(obj.BackgroundColor3) then red = true; reason = "bg" end
                        if not red and isImage and obj.ImageTransparency < 0.3 and isRedColor(obj.ImageColor3) then red = true; reason = "img" end
                        if not red then
                            local stroke = obj:FindFirstChildOfClass("UIStroke")
                            if stroke and stroke.Transparency < 0.3 and isRedColor(stroke.Color) then red = true; reason = "stroke" end
                        end
                        if red then
                            addLine("[🔴] " .. obj.Name .. " (" .. reason .. ")", RED_ERR)
                            return true
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
    if url and (not currentArticle or currentArticle ~= url) then
        currentArticle = url
        markVisited(url)
        if #currentPath == 0 then table.insert(currentPath, url)
        elseif currentPath[#currentPath] ~= url then table.insert(currentPath, url) end
        updateLabels()
        return true
    end
    return false
end

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
        if isEnglish(c) and not isUiJunk(c) then table.insert(filtered, c) end
    end
    if #filtered > 200 then local t = {}; for i=1,200 do t[i]=filtered[i] end; filtered = t end
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
        if isEnglish(c) and not isUiJunk(c) then table.insert(filtered, c) end
    end
    return filtered
end

local function tryClickVisibleLink(title)
    if not title then return false end
    local targetSuper = superNormalize(title)
    if #targetSuper < 2 then return false end
    local found = {}
    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if not obj:IsDescendantOf(gui) and (obj:IsA("TextButton") or obj:IsA("TextLabel")) then
            local text = obj.Text or ""
            if text ~= "" and not isUiJunk(text) then
                local disp = text:gsub("<[^>]+>",""):gsub("^%s+",""):gsub("%s+$","")
                local dispSuper = superNormalize(disp)
                local score = 0
                if dispSuper == targetSuper then score = 100
                elseif disp:lower() == title:lower() then score = 90
                elseif #targetSuper >= 3 and dispSuper:find(targetSuper, 1, true) then score = 80
                elseif #dispSuper >= 3 and targetSuper:find(dispSuper, 1, true) then score = 70 end
                if score > 0 then
                    if isBlue(obj.TextColor3) then score = score + 20 end
                    if obj:IsA("TextButton") then score = score + 10 end
                    table.insert(found, {obj=obj, score=score})
                end
            end
        end
    end
    if #found == 0 then return false end
    table.sort(found, function(a, b) return a.score > b.score end)
    for i = 1, math.min(5, #found) do
        local target = found[i].obj
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
        if ok then return true end
    end
    return false
end

local function navigateToTitle(title)
    if not title or not currentArticle or not currentArticleId then return false end
    if normalize(title):lower() == normalize(currentArticle):lower() then return false end

    local normTitle = normalize(title)
    local targetId, matchType = nil, ""

    targetId = linkIdMap[normTitle]
    if targetId then matchType = "exact" end
    if not targetId then
        local lowT = normTitle:lower()
        for k, v in pairs(linkIdMap) do if k:lower() == lowT then targetId = v; matchType = "ci"; break end end
    end
    if not targetId then
        local function agg(s) return tostring(s):lower():gsub("[%p%s]", "") end
        local ta = agg(normTitle)
        for k, v in pairs(linkIdMap) do if agg(k) == ta then targetId = v; matchType = "agg"; break end end
    end
    if not targetId then
        local tSup = superNormalize(normTitle)
        if #tSup >= 3 then
            for k, v in pairs(linkIdMap) do if superNormalize(k) == tSup then targetId = v; matchType = "super"; break end end
        end
    end
    if not targetId then
        local lowT = normTitle:lower()
        if #lowT >= 5 then
            for k, v in pairs(linkIdMap) do
                local lowK = k:lower()
                if lowK:find(lowT, 1, true) or lowT:find(lowK, 1, true) then targetId = v; matchType = "sub"; break end
            end
        end
    end

    if not targetId then
        if tryClickVisibleLink(title) then
            addLine("[GO] " .. title .. " (clicked)", GREEN_OK)
            markVisited(title)
            addPathLog(title, "GO:click")
            lastPickAttemptTitle = title
            return true
        end
        return false
    end

    clickNum = clickNum + 1
    local tag = matchType ~= "exact" and (" [" .. matchType .. "]") or ""
    addLine("[GO] " .. title .. " (id=" .. targetId .. ")" .. tag, GREEN_OK)
    addPathLog(title, "GO:" .. matchType)
    pcall(function() NavigateArticle:FireServer(currentArticleId, targetId, clickNum) end)
    markVisited(title)
    lastPickAttemptTitle = title
    statusLbl.Text = "→ " .. title
    return true
end

-- ==================== PARSE ====================
local function normalizePicks(data)
    local out = {}
    if type(data) ~= "table" then return out end
    local function pushTitle(entry, defaultRank)
        if type(entry) == "string" then table.insert(out, {rank=defaultRank or 99, title=entry}); return end
        if type(entry) ~= "table" then return end
        local t = entry.title or entry.Title or entry.name or entry.next
        if not t or t == "" then return end
        table.insert(out, {rank=tonumber(entry.rank or entry.Rank) or defaultRank or 99, title=tostring(t)})
    end
    if type(data.picks) == "table" then for i,p in ipairs(data.picks) do pushTitle(p,i) end end
    if type(data.path) == "table" then for i,p in ipairs(data.path) do pushTitle(p,i) end end
    if type(data.routes) == "table" then for i,p in ipairs(data.routes) do pushTitle(p,i) end end
    if type(data.steps) == "table" then for i,p in ipairs(data.steps) do pushTitle(p,i) end end
    if data.pick ~= nil then pushTitle(data.pick, 1) end
    if #out == 0 and type(data.title) == "string" and data.title ~= "" then
        table.insert(out, {rank=1, title=data.title})
    end
    table.sort(out, function(a,b) return (a.rank or 99) < (b.rank or 99) end)
    local seen, deduped = {}, {}
    for _, p in ipairs(out) do
        local k = p.title:lower()
        if not seen[k] then seen[k] = true; table.insert(deduped, p) end
    end
    return deduped
end

local function parsePicksFromText(text)
    if not text or text == "" then return nil end
    text = text:gsub("^%s+",""):gsub("%s+$",""):gsub("```%w*",""):gsub("```",""):gsub("^%s+",""):gsub("%s+$","")
    if text == "" then return nil end

    local first = text:find("{")
    if first then
        local depth, lastOpen = 0, nil
        for i = first, #text do
            local c = text:sub(i,i)
            if c == "{" then depth=depth+1; if depth==1 then lastOpen=i end
            elseif c == "}" then
                depth=depth-1
                if depth==0 and lastOpen then
                    local chunk = text:sub(lastOpen, i)
                    local ok, data = pcall(function() return HttpService:JSONDecode(chunk) end)
                    if ok and type(data) == "table" then
                        if data.picks or data.path or data.routes or data.steps or data.pick or data.title then
                            local p = normalizePicks(data)
                            if #p > 0 then return {picks=p, _raw=data} end
                        end
                    end
                    break
                end
            end
        end
    end

    local lines = {}
    for line in text:gmatch("[^\r\n]+") do
        line = line:gsub("^%s+",""):gsub("%s+$",""):gsub("^%d+%.%s*",""):gsub("^[-%*]%s*","")
        if line ~= "" and isEnglish(line) then table.insert(lines, line) end
    end
    if #lines == 1 then return {picks={{rank=1, title=lines[1]}}} end
    if #lines >= 2 then
        local p = {}
        for i, t in ipairs(lines) do table.insert(p, {rank=i, title=t}) end
        return {picks=p}
    end
    return nil
end

-- ==================== CHAIN ====================
local function fireNextChain()
    if not autoChainActive then return end
    local nextTitle = nil
    while #autoChainQueue > 0 do
        local c = table.remove(autoChainQueue, 1)
        local k = normalize(c):lower()
        if not chainHistory[k] then nextTitle = c; chainHistory[k] = true; break end
    end
    if not nextTitle then
        autoChainActive = false
        addLine("[CHAIN] ✓ DONE", GREEN_OK)
        statusLbl.Text = "🐽 DONE"
        return
    end
    addPathLog(nextTitle, "chain")
    addLine("[CHAIN] ⚡ → " .. nextTitle, GREEN_OK)
    if not navigateToTitle(nextTitle) then task.defer(fireNextChain) end
end

local function startInstantChain(picks)
    autoChainQueue, chainHistory, chainCurrentRank = {}, {}, 0
    if currentArticle then
        local nc = normalize(currentArticle):lower()
        for _, p in ipairs(picks) do
            if normalize(p.title or ""):lower() == nc then
                chainCurrentRank = tonumber(p.rank) or 0
                chainHistory[nc] = true
                break
            end
        end
    end
    for _, p in ipairs(picks) do
        local t = p.title or ""
        if t ~= "" then
            local r = tonumber(p.rank) or 999
            if r > chainCurrentRank then table.insert(autoChainQueue, t) end
        end
    end
    if #autoChainQueue == 0 then addLine("[CHAIN] ไม่มี rank ถัดไป", ORANGE_WARN); return end
    autoChainActive = true
    addLine("[CHAIN] เริ่ม " .. #autoChainQueue .. " หน้า", GREEN_OK)
    fireNextChain()
end

-- ============================================================
-- 🎯 SMART SCORING v1.5
-- ============================================================
local STOPWORDS = {
    ["the"]=true, ["a"]=true, ["an"]=true, ["of"]=true, ["in"]=true,
    ["on"]=true, ["at"]=true, ["to"]=true, ["for"]=true, ["and"]=true,
    ["or"]=true, ["is"]=true, ["are"]=true, ["was"]=true, ["were"]=true,
    ["by"]=true, ["with"]=true, ["from"]=true, ["as"]=true, ["that"]=true,
    ["this"]=true, ["it"]=true, ["be"]=true, ["has"]=true, ["have"]=true,
    ["had"]=true, ["but"]=true, ["not"]=true, ["also"]=true, ["which"]=true,
    ["new"]=true, ["list"]=true,
}

local TOPIC_HINTS = {
    -- 🐾 ANIMALS
    ["bat"] = {"mammal","animal","chiroptera","wing","nocturnal","insect","cave","flying"},
    ["cat"] = {"feline","mammal","animal","domestic","pet","felidae"},
    ["dog"] = {"canine","mammal","animal","domestic","pet","canidae"},
    ["monkey"] = {"primate","ape","mammal","animal","species","biology","forest"},
    ["bird"] = {"avian","animal","wing","feather","species","biology"},
    ["fish"] = {"animal","water","species","biology","aquatic","marine"},
    ["insect"] = {"animal","arthropod","species","biology","wing","antenna"},
    -- 🌱 PLANTS & FOOD
    ["potato"] = {"vegetable","tuber","solanum","plant","crop","food","starch","carb","solanaceae","irish"},
    ["tomato"] = {"vegetable","fruit","solanum","plant","crop","food"},
    ["wheat"] = {"grain","crop","plant","food","cereal","bread","flour"},
    ["rice"] = {"grain","crop","plant","food","cereal","asia","paddy"},
    ["corn"] = {"maize","grain","crop","plant","food","american"},
    ["vegetable"] = {"plant","food","crop","garden","nutrition","diet"},
    ["fruit"] = {"plant","food","tree","seed","nutrition","sweet"},
    ["bread"] = {"food","wheat","bake","flour","loaf","grain"},
    ["hamburger"] = {"hamburg","german","food","beef","bun","sandwich","cuisine"},
    ["pizza"] = {"italian","food","cheese","tomato","naples","cuisine"},
    -- 🏙️ CITIES
    ["berlin"] = {"germany","german","capital","city","europe"},
    ["paris"] = {"france","french","capital","city","europe"},
    ["london"] = {"england","english","capital","city","british"},
    ["tokyo"] = {"japan","japanese","capital","city","asia"},
    -- 🎮 GAMES
    ["silent hill"] = {"horror","survival","konami","playstation","game"},
    ["mario"] = {"nintendo","platformer","game","jump","plumber"},
    ["minecraft"] = {"sandbox","mojang","game","block","survival"},
    ["pokemon"] = {"nintendo","game","monster","trainer","pikachu"},
    -- 👤 PEOPLE
    ["einstein"] = {"physicist","physics","scientist","german","nobel","relativity"},
    ["napoleon"] = {"emperor","french","general","bonaparte","war","france"},
    ["mozart"] = {"composer","austrian","music","classical","opera"},
    ["tesla"] = {"inventor","serbian","engineer","physics","electricity"},
    ["newton"] = {"physicist","physics","mathematician","english","gravity"},
    ["darwin"] = {"naturalist","biologist","english","evolution","species"},
    -- 🔬 SCIENCE
    ["physics"] = {"science","energy","force","matter","quantum","particle"},
    ["math"] = {"mathematics","number","algebra","geometry","equation"},
    ["climate"] = {"weather","temperature","environment","atmosphere"},
    ["evolution"] = {"darwin","biology","species","natural","selection"},
    ["biology"] = {"science","life","organism","cell","species","evolution"},
}

local CATEGORIES = {
    animal = {"animal","mammal","species","biology","zoology","wildlife","genus","family","taxon","vertebrate"},
    plant = {"plant","flower","tree","botany","leaf","seed","crop","vegetable","fruit","herb"},
    food = {"food","cuisine","dish","cooking","crop","vegetable","fruit","grain","meal","recipe","bread"},
    city = {"city","capital","urban","population","metropolis","town","municipality"},
    country = {"country","nation","republic","government","sovereign","state","kingdom"},
    game = {"video game","playstation","nintendo","xbox","console","gameplay","arcade","sega"},
    person = {"born","biography","died","career","actor","singer","politician","author","scientist"},
    music = {"song","album","band","singer","composer","instrument","orchestra"},
    film = {"film","movie","actor","actress","director","cinema","screenplay"},
    science = {"science","physics","chemistry","biology","research","theory","experiment"},
    history = {"war","empire","ancient","century","civilization","king","battle"},
    language = {"language","grammar","dialect","linguistic","syntax","phonology"},
    religion = {"christianity","islam","buddhism","hinduism","god","church","religion"},
    sport = {"sport","football","soccer","team","player","championship","league"},
    art = {"painting","artist","museum","culture","renaissance","sculpture"},
}

local TOPIC_CATEGORY = {
    ["bat"]="animal", ["cat"]="animal", ["dog"]="animal", ["monkey"]="animal",
    ["bird"]="animal", ["fish"]="animal", ["insect"]="animal", ["mammal"]="animal",
    ["elephant"]="animal", ["whale"]="animal", ["dolphin"]="animal", ["tiger"]="animal",
    ["lion"]="animal", ["horse"]="animal", ["snake"]="animal", ["frog"]="animal",
    ["potato"]="food", ["tomato"]="food", ["wheat"]="food", ["rice"]="food",
    ["corn"]="food", ["vegetable"]="food", ["fruit"]="food", ["bread"]="food",
    ["hamburger"]="food", ["pizza"]="food", ["sushi"]="food", ["apple"]="food",
    ["banana"]="food", ["orange"]="food", ["cheese"]="food", ["meat"]="food",
    ["berlin"]="city", ["paris"]="city", ["london"]="city", ["tokyo"]="city",
    ["rome"]="city", ["moscow"]="city", ["hamburg"]="city", ["madrid"]="city",
    ["new york"]="city", ["beijing"]="city", ["delhi"]="city",
    ["silent hill"]="game", ["mario"]="game", ["zelda"]="game", ["pokemon"]="game",
    ["minecraft"]="game", ["halo"]="game", ["terraria"]="game", ["doom"]="game",
    ["einstein"]="person", ["napoleon"]="person", ["mozart"]="person",
    ["tesla"]="person", ["newton"]="person", ["darwin"]="person",
    ["shakespeare"]="person", ["lincoln"]="person", ["trump"]="person",
}

local TOPIC_COUNTRY = {
    ["hamburger"]="german", ["pizza"]="italian", ["sushi"]="japanese",
    ["ramen"]="japanese", ["taco"]="mexican", ["baguette"]="french",
    ["berlin"]="german", ["paris"]="french", ["tokyo"]="japanese",
    ["london"]="english", ["rome"]="italian", ["moscow"]="russian",
    ["hamburg"]="german", ["einstein"]="german", ["mozart"]="austrian",
}

local BRIDGE_WORDS = {
    "biology","organism","species","evolution","taxonomy","genus","family","mammal",
    "animal","plant","nature","ecology","cell","life",
    "nature","earth","world","environment","ecosystem",
    "science","research","university","theory","history",
    "agriculture","crop","food","diet","nutrition","farming","garden",
    "chemistry","molecule","compound","carbohydrate","protein","starch",
}

local TOPIC_MISMATCH = {
    animal = {"language","grammar","dialect","linguistic","university","philosophy","religion","music","film"},
    plant  = {"language","grammar","dialect","linguistic","university","philosophy","military","war"},
    food   = {"language","grammar","dialect","linguistic","university","military","war","philosophy","astronomy","mathematics"},
    game   = {"language","grammar","dialect","linguistic","university","philosophy","military"},
    city   = {"language","grammar","dialect","linguistic"},
}

local function getWords(t)
    local words = {}
    for w in tostring(t):gmatch("%a+") do
        if #w >= 4 and not STOPWORDS[w] then words[w] = true end
    end
    return words
end

local function findCategory(tLow)
    for key, cat in pairs(TOPIC_CATEGORY) do
        if tLow:find(key, 1, true) then return cat end
    end
    return nil
end

local function findCountry(tLow)
    for key, country in pairs(TOPIC_COUNTRY) do
        if tLow:find(key, 1, true) then return country end
    end
    return nil
end

local startContext = nil
local function computeStartContext()
    if not startTitle then return end
    local sLow = startTitle:lower()
    local sCat = findCategory(sLow)
    local sCountry = findCountry(sLow)
    startContext = {
        cat = sCat,
        country = sCountry,
        words = getWords(sLow),
        lower = sLow,
    }
end

local function matchesCategory(cLow, cat)
    if not cat or not CATEGORIES[cat] then return false end
    for _, w in ipairs(CATEGORIES[cat]) do
        if cLow:find(w, 1, true) then return true end
    end
    return false
end

local function mismatchesTarget(cLow, targetCat)
    if not targetCat or not TOPIC_MISMATCH[targetCat] then return false end
    for _, w in ipairs(TOPIC_MISMATCH[targetCat]) do
        if cLow:find(w, 1, true) then return true end
    end
    return false
end

local function isBridge(cLow)
    for _, w in ipairs(BRIDGE_WORDS) do
        if cLow == w then return true end
    end
    return false
end

-- ==================== SCORING v1.5 ====================
local function scoreV15(candidate, tLower, tSup, tWords, tCat, tCountry, sContext)
    if not candidate or candidate == "" then return -99999 end
    local cLow = tostring(candidate):lower()
    local cSup = superNormalize(candidate)

    if cLow:match("^%d+$") then return -99999 end
    if cLow:match("^%d+th century") then return -99999 end
    if cLow:match("^list of") then return -5000 end
    if cLow:match("^%d%d%d%d") and #candidate <= 8 then return -3000 end

    if #cSup >= 4 and #tSup >= 4 then
        if tSup:find(cSup, 1, true) then return 200000 end
        if cSup:find(tSup, 1, true) then return 150000 end
    end

    if tSup ~= "" and cSup == tSup then return 1000000 end

    local score = 0

    if tWords then
        for w in pairs(tWords) do
            if cLow:find(w, 1, true) then score = score + 800 end
        end
    end

    if tLower ~= "" then
        for key, hints in pairs(TOPIC_HINTS) do
            if tLower:find(key, 1, true) then
                for _, h in ipairs(hints) do
                    if cLow:find(h, 1, true) then score = score + 500 end
                end
            end
        end
    end

    if tCat and matchesCategory(cLow, tCat) then
        score = score + 300
    end

    if tCountry and cLow:find(tCountry, 1, true) then
        score = score + 400
    end

    if isBridge(cLow) then
        score = score + 2000
    end

    if sContext then
        if sContext.cat and matchesCategory(cLow, sContext.cat) then
            score = score + 150
        end
        for w in pairs(sContext.words) do
            if cLow:find(w, 1, true) then score = score + 100 end
        end
    end

    if mismatchesTarget(cLow, tCat) then
        score = score - 800
    end

    local len = #candidate
    if len <= 15 then score = score + 40
    elseif len <= 25 then score = score + 20
    elseif len <= 40 then score = score + 5
    elseif len > 80 then score = score - 40 end

    return score
end

local function loopPenalty(c)
    local cnt = pickCount[c:lower()] or 0
    if cnt == 0 then return 0 end
    if cnt == 1 then return -500 end
    if cnt == 2 then return -3000 end
    return -10000
end

local function smartPick(pool, tLower, tSup, tWords, tCat, tCountry, sContext)
    if #pool == 0 then return nil, "empty" end
    local scored = {}
    for _, c in ipairs(pool) do
        local s = scoreV15(c, tLower, tSup, tWords, tCat, tCountry, sContext)
        s = s + loopPenalty(c)
        table.insert(scored, {title=c, score=s})
    end
    table.sort(scored, function(a, b) return a.score > b.score end)

    if scored[1].score >= 100000 then
        return scored[1].title, "SUBSTRING"
    end
    if scored[1].score >= 2000 then
        return scored[1].title, "BRIDGE"
    end

    if math.random() < 0.85 then
        local topN = math.min(3, #scored)
        return scored[math.random(1, topN)].title, "top"
    else
        local total, weights = 0, {}
        for i, s in ipairs(scored) do
            local w = math.max(1, s.score + 100)
            weights[i] = w; total = total + w
        end
        local r = math.random() * total
        local acc = 0
        for i, w in ipairs(weights) do
            acc = acc + w
            if r <= acc then return scored[i].title, "explore" end
        end
        return scored[1].title, "top"
    end
end

-- ==================== AUTO LOOP ====================
local function doAutoExploreStep()
    if not autoExploreActive or autoExploreBusy then return end
    autoExploreBusy = true

    if hasRedCircleDot() then
        addLine("[AUTO] 🔴🔴🔴 RED — STOP!", RED_ERR)
        statusLbl.Text = "🔴 RED STOP"
        autoExploreActive, autoExploreBusy = false, false
        autoBtn.BackgroundColor3 = ORANGE_WARN
        autoBtn.Text = "AUTO ⚡ OFF"
        return
    end

    if not currentArticle then refreshURL() end
    if not currentArticle or not currentArticleId then
        autoRetryCount = autoRetryCount + 1
        autoExploreBusy = false
        task.defer(function()
            if autoExploreActive then task.wait(AUTO_DELAY); doAutoExploreStep() end
        end)
        return
    end
    autoRetryCount = 0

    local all = getAutoCandidates()
    if #all == 0 then
        autoExploreBusy = false
        task.defer(function()
            if autoExploreActive then task.wait(AUTO_DELAY); doAutoExploreStep() end
        end)
        return
    end

    local pool = {}
    for _, c in ipairs(all) do
        if not isVisited(c) then table.insert(pool, c) end
    end
    if #pool == 0 then pool = all end

    local tLower = (targetTitle or ""):lower()
    local tSup = superNormalize(targetTitle or "")
    local tWords = getWords(tLower)
    local tCat = findCategory(tLower)
    local tCountry = findCountry(tLower)

    if not startContext then computeStartContext() end

    local pick, kind = smartPick(pool, tLower, tSup, tWords, tCat, tCountry, startContext)
    if not pick then autoExploreBusy = false; return end

    addPathLog(pick, kind)
    local icon = kind == "SUBSTRING" and "💥" or kind == "BRIDGE" and "🌉" or kind == "top" and "🎯" or "🎲"
    local col = kind == "SUBSTRING" and PURPLE_HIT or kind == "BRIDGE" and GOLD_HIT or kind == "top" and PINK_DEEP or ORANGE_WARN
    addLine("[AUTO] " .. icon .. " → " .. pick .. " [" .. kind .. "]", col)

    local ok = navigateToTitle(pick)
    autoExploreBusy = false
    if not ok then
        task.defer(function()
            if autoExploreActive then task.wait(AUTO_DELAY); doAutoExploreStep() end
        end)
    end
end

local function startAutoExplore()
    if not autoExploreActive then return end
    addLine("[AUTO] 🚀 v1.5 BRIDGE + delay " .. AUTO_DELAY, GREEN_OK)
    statusLbl.Text = "🔵 AUTO running"
    autoRetryCount = 0
    task.defer(doAutoExploreStep)
end

local function doGo()
    if not currentArticle then refreshURL() end
    if currentArticle then
        local norm = normalize(currentArticle)
        blueWordCache[norm] = nil
        gameCache[norm] = nil
        local f = scanBlue()
        if #f > 0 then blueWordCache[norm] = f; addLine("[scan] " .. #f .. " words", GREEN_OK) end
    end
    local text = pasteBox.Text or ""
    if text == "" then addLine("[X] paste empty", RED_ERR); statusLbl.Text = "Paste JSON"; return end
    local data = parsePicksFromText(text)
    if not data or not data.picks or #data.picks == 0 then
        addLine("[X] parse failed", RED_ERR); statusLbl.Text = "Bad JSON"; return
    end
    lastPicks = data.picks
    addLine("[ok] " .. #data.picks .. " picks", GREEN_OK)
    for i = 1, math.min(10, #data.picks) do
        local p = data.picks[i]
        addLine("  #" .. i .. ": " .. (p.title or "?") .. (p.rank and " r"..p.rank or ""), PINK_DEEP)
    end
    startInstantChain(data.picks)
end

-- ==================== BUTTONS ====================
local guiVisible = true
local function toggleMin()
    if content.Visible then
        content.Visible = false; frame.Size = UDim2.new(0, 350, 0, 28); minBtn.Text = "+"
    else
        content.Visible = true; frame.Size = UDim2.new(0, 350, 0, 300); minBtn.Text = "-"
    end
end
minBtn.MouseButton1Click:Connect(toggleMin)
local function toggleClose()
    guiVisible = not guiVisible; frame.Visible = guiVisible
end
closeBtn.MouseButton1Click:Connect(toggleClose)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        guiVisible = not guiVisible; frame.Visible = guiVisible
    end
end)

copyTargetBtn.MouseButton1Click:Connect(function()
    if not targetTitle or targetTitle == "" then addLine("[X] no target", RED_ERR); return end
    local safe = tostring(targetTitle):gsub("\\", "\\\\"):gsub('"', '\\"')
    local ok = copyToClipboard('{"picks":[{"rank":1,"title":"' .. safe .. '"}]}')
    addLine("[target] " .. (ok and "copied" or "FAIL"), ok and GREEN_OK or RED_ERR)
end)

hopBtn.MouseButton1Click:Connect(function()
    if not currentArticle then refreshURL() end
    if not currentArticle then addLine("[X] no current", RED_ERR); return end
    local filtered = getFilteredCandidates()
    if #filtered == 0 then addLine("[X] no candidates", RED_ERR); return end
    local lines = {"CURRENT: " .. currentArticle, "TARGET: " .. (targetTitle or "?"), "", "CANDIDATES:"}
    for i, c in ipairs(filtered) do table.insert(lines, i .. ". " .. c) end
    local ok = copyToClipboard(table.concat(lines, "\n"))
    addLine("[HOP] " .. #filtered .. " cand " .. (ok and "copied" or "FAIL"), ok and GREEN_OK or RED_ERR)
end)

local function setAutoUI(on)
    if on then autoBtn.BackgroundColor3 = GREEN_OK; autoBtn.Text = "AUTO ⚡ ON"
    else autoBtn.BackgroundColor3 = ORANGE_WARN; autoBtn.Text = "AUTO ⚡ OFF" end
end

autoBtn.MouseButton1Click:Connect(function()
    autoExploreActive = not autoExploreActive
    setAutoUI(autoExploreActive)
    if autoExploreActive then
        addLine("[AUTO] ⚡ ON (v1.5)", GREEN_OK)
        if currentArticle then task.defer(startAutoExplore) end
    else addLine("[AUTO] OFF", PINK_DARK) end
end)

stopAutoBtn.MouseButton1Click:Connect(function()
    autoExploreActive, autoChainActive = false, false
    setAutoUI(false)
    addLine("[AUTO] ⛔ STOP", RED_ERR)
    statusLbl.Text = "🛑 Stopped"
end)

copyLogBtn.MouseButton1Click:Connect(copyPathLog)

pasteBtn.MouseButton1Click:Connect(function()
    if isProcessing then return end
    isProcessing = true
    local txt = getClipboard()
    if txt and #txt > 0 then
        pasteBox.Text = txt
        task.wait(AUTO_DELAY); doGo()
    else addLine("[paste] empty", PINK_DEEP) end
    task.wait(AUTO_DELAY); isProcessing = false
end)

clearJsonBtn.MouseButton1Click:Connect(function()
    pasteBox.Text = ""
    autoChainActive, autoChainQueue, chainHistory = false, {}, {}
    addLine("[clear]", PINK_DEEP); statusLbl.Text = "🐽 Cleared"
end)

goBtn.MouseButton1Click:Connect(function()
    if isProcessing then return end
    isProcessing = true; doGo(); task.wait(AUTO_DELAY); isProcessing = false
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
        addLine("[page] " .. t .. " (" .. #links .. " p)", PINK_DARK)

        if autoChainActive then task.defer(fireNextChain) end
        if autoExploreActive then task.defer(doAutoExploreStep) end
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
            pickCount = {}
            markVisited(startTitle)
            addPathLog(startTitle, "START")
            computeStartContext()
        end
        if p.TargetArticle and p.TargetArticle.Title then
            targetTitle = normalize(p.TargetArticle.Title)
        end
        clickNum = 0
        autoChainActive, autoChainQueue, chainHistory, chainCurrentRank = false, {}, {}, 0
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
addLine("⚡ v10.3 AUTO v1.5 BRIDGE", GREEN_OK)
addLine("delay = " .. AUTO_DELAY .. " ทุกจุด", PINK_DEEP)
addLine("substring + category + country", PINK_DARK)
statusLbl.Text = "🐽 Ready ⚡"
updateLabels()

print("[ATLAS v10.3 ⚡ AUTO v1.5 BRIDGE] Loaded ✓")
