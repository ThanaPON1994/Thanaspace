-- ATLAS v8.7 — linkIdMap Edition
-- 🐷 Pink Pig Edition (350 x 300) — 傳說中的龍女來了 Edition
-- 🆕 ใช้ linkIdMap 100% (ลบ scan ทั้งหมด)
-- 🆕 cap = 200 (ไม่ตัด link)
-- 🆕 Perplexity short answer
-- 🆕 UI junk filter
-- 🆕 cap ตามจริง 8-149 links/หน้า

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local NavigateArticle = Remotes:WaitForChild("NavigateArticle")

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

-- ==================== DIACRITICS ====================
local DIACRITIC_MAP = {
    ["\195\160"]="a",["\195\161"]="a",["\195\162"]="a",["\195\163"]="a",["\195\164"]="a",["\195\165"]="a",["\195\166"]="ae",["\195\167"]="c",
    ["\195\168"]="e",["\195\169"]="e",["\195\170"]="e",["\195\171"]="e",["\195\172"]="i",["\195\173"]="i",["\195\174"]="i",["\195\175"]="i",
    ["\195\177"]="n",["\195\178"]="o",["\195\179"]="o",["\195\180"]="o",["\195\181"]="o",["\195\182"]="oe",
    ["\195\185"]="u",["\195\186"]="u",["\195\187"]="u",["\195\188"]="u",
}

local function stripDiacritics(s)
    if not s or s == "" then return s end
    s = s:gsub("[\194-\199][\128-\191]", function(c)
        return DIACRITIC_MAP[c] or c
    end)
    return s
end

local function superNormalize(s)
    if not s then return "" end
    s = tostring(s):lower()
    s = s:gsub("&amp;", "&"):gsub("&#39;", "'"):gsub("&quot;", '\034'):gsub("&nbsp;", " ")
    s = s:gsub("\226\128\152", "'"):gsub("\226\128\153", "'")
    s = s:gsub("\226\128\156", '\034'):gsub("\226\128\157", '\034')
    s = s:gsub("\226\128\147", "-"):gsub("\226\128\148", "-")
    s = stripDiacritics(s)
    s = s:gsub("[^%w]", "")
    return s
end

local function isEnglish(text)
    if not text then return false end
    text = tostring(text):gsub("^%s+", ""):gsub("%s+$", "")
    if #text < 2 then return false end
    local letters = 0
    for i = 1, #text do
        local b = text:byte(i)
        if (b >= 65 and b <= 90) or (b >= 97 and b <= 122) then letters = letters + 1 end
    end
    if letters < 2 then return false end
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
    ["ui the free encyclopedia"]=true,
    ["the free encyclopedia"]=true,
    ["choose the language you want prioritized in translating the articles"]=true,
    ["choose the language you want prioritized in translating the articles!"]=true,
    ["article read"]=true,
    ["general knowledge"]=true,
    ["events"]=true, ["stats"]=true, ["ranked"]=true,
    ["race"]=true, ["drink"]=true, ["laptops"]=true,
    ["stickers"]=true, ["premium"]=true,
}

local JUNK_NAMES = {
    ["warner bros."]=true, ["warner bros"]=true, ["cbs"]=true,
    ["monterey, california"]=true, ["tucson, arizona"]=true,
    ["ellenburstyn"]=true, ["kriskristofferson"]=true,
    ["jodiefoster"]=true, ["harveykeitel"]=true, ["laura dern"]=true,
    ["doris day rock hudson"]=true, ["the exorcist"]=true,
    ["francis coppola"]=true, ["mean streets"]=true,
    ["palmed'or"]=true, ["best actress"]=true, ["supporting"]=true,
    ["original screenplay"]=true, ["originalscreenplay"]=true,
    ["televisionseries alice"]=true, ["soapopera"]=true,
    ["mel'sdiner"]=true, ["mott hoople"]=true,
}

local function isUiJunk(text)
    if not text or text == "" then return false end
    local low = text:lower():gsub("^%s+",""):gsub("%s+$","")
    if UI_JUNK[low] then return true end
    if JUNK_NAMES[low] then return true end
    if low:find("^time left") then return true end
    if low:find("^search wiki") then return true end
    if low:find("^wikirace") then return true end
    if low:find("^wikibloxia") then return true end
    if low:match("^%d+%.?%s*$") then return true end
    if low:find("the free encyclopedia", 1, true) then return true end
    if low:find("choose the language", 1, true) then return true end
    if low:find("prioritized in translating", 1, true) then return true end
    if low == "article read" then return true end
    if low == "general knowledge" then return true end
    if low:match("^[a-z]+%s+%d+,%s+%d+$") then return true end
    if low:match("^[a-z]+%s+%d+$") then return true end
    if low:match("^%d+%s+[a-z]+%s+%d+$") then return true end
    if low:match("^%d%d%d%d$") then return true end
    if low:find("^televisionseries") then return true end
    if low:find("^soapopera") then return true end
    if low:find("^palmed") then return true end
    if low:find("^mel'sdiner") then return true end
    return false
end

-- ==================== STATE ====================
local allLogs = {}
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
local lastFallbackData = nil

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
            if text:find("wikibloxia.org/wiki/") then
                local match = text:match("wiki/([^%s%?%#]+)")
                if match then
                    match = match:gsub("%%(%x%x)", function(h)
                        return string.char(tonumber(h, 16))
                    end)
                    return normalize(match)
                end
            end
        end
    end
    return nil
end

-- ==================== 🐷 GUI ====================
local gui = Instance.new("ScreenGui")
gui.Name = "傳說中的龍女來了"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999
gui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 350, 0, 300)
frame.Position = UDim2.new(0, 10, 0, 20)
frame.BackgroundColor3 = PINK_MAIN
frame.BorderSizePixel = 0
frame.Active = true
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
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🐷 v8.7 linkIdMap"
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
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(1, 0)

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
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)

local dragging, dragStart, startPos = false, nil, nil
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
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
Instance.new("UICorner", infoLbl).CornerRadius = UDim.new(0, 8)

local copyTargetBtn = Instance.new("TextButton")
copyTargetBtn.Size = UDim2.new(0, 110, 0, 18)
copyTargetBtn.Position = UDim2.new(1, -116, 0, 4)
copyTargetBtn.BackgroundColor3 = PINK_DEEP
copyTargetBtn.Text = "🐽 Copy Target"
copyTargetBtn.TextColor3 = WHITE
copyTargetBtn.Font = Enum.Font.SourceSansBold
copyTargetBtn.TextSize = 10
copyTargetBtn.BorderSizePixel = 0
copyTargetBtn.Parent = content
Instance.new("UICorner", copyTargetBtn).CornerRadius = UDim.new(0, 8)

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
Instance.new("UICorner", currentLbl).CornerRadius = UDim.new(0, 8)

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

local hopBtn = Instance.new("TextButton")
hopBtn.Size = UDim2.new(1, -12, 0, 28)
hopBtn.Position = UDim2.new(0, 6, 0, 64)
hopBtn.BackgroundColor3 = PINK_DEEP
hopBtn.Text = "小女孩"
hopBtn.TextColor3 = WHITE
hopBtn.Font = Enum.Font.SourceSansBold
hopBtn.TextSize = 13
hopBtn.BorderSizePixel = 0
hopBtn.Parent = content
Instance.new("UICorner", hopBtn).CornerRadius = UDim.new(0, 10)

local pasteLbl = Instance.new("TextLabel")
pasteLbl.Size = UDim2.new(1, -12, 0, 14)
pasteLbl.Position = UDim2.new(0, 6, 0, 96)
pasteLbl.BackgroundTransparency = 1
pasteLbl.Text = "Paste Gemini/Perplexity:"
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
pasteBox.PlaceholderText = '{"pick":{"title":"..."}} หรือชื่อเพจ'
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
Instance.new("UICorner", pasteBox).CornerRadius = UDim.new(0, 10)

local pasteBtn = Instance.new("TextButton")
pasteBtn.Size = UDim2.new(0, 88, 0, 28)
pasteBtn.Position = UDim2.new(0, 6, 0, 160)
pasteBtn.BackgroundColor3 = PINK_DARK
pasteBtn.Text = "777"
pasteBtn.TextColor3 = WHITE
pasteBtn.Font = Enum.Font.SourceSansBold
pasteBtn.TextSize = 12
pasteBtn.BorderSizePixel = 0
pasteBtn.Parent = content
Instance.new("UICorner", pasteBtn).CornerRadius = UDim.new(0, 10)

local clearJsonBtn = Instance.new("TextButton")
clearJsonBtn.Size = UDim2.new(0, 88, 0, 28)
clearJsonBtn.Position = UDim2.new(0, 98, 0, 160)
clearJsonBtn.BackgroundColor3 = RED_ERR
clearJsonBtn.Text = "CLEAR"
clearJsonBtn.TextColor3 = WHITE
clearJsonBtn.Font = Enum.Font.SourceSansBold
clearJsonBtn.TextSize = 12
clearJsonBtn.BorderSizePixel = 0
clearJsonBtn.Parent = content
Instance.new("UICorner", clearJsonBtn).CornerRadius = UDim.new(0, 10)

local copyLogBtn = Instance.new("TextButton")
copyLogBtn.Size = UDim2.new(0, 88, 0, 28)
copyLogBtn.Position = UDim2.new(0, 190, 0, 160)
copyLogBtn.BackgroundColor3 = GREEN_OK
copyLogBtn.Text = "📋 LOG v2"
copyLogBtn.TextColor3 = WHITE
copyLogBtn.Font = Enum.Font.SourceSansBold
copyLogBtn.TextSize = 11
copyLogBtn.BorderSizePixel = 0
copyLogBtn.Parent = content
Instance.new("UICorner", copyLogBtn).CornerRadius = UDim.new(0, 10)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -12, 1, -196)
scroll.Position = UDim2.new(0, 6, 0, 194)
scroll.BackgroundColor3 = PINK_FIELD
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = content
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 10)

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

-- ==================== 🆕 getFilteredCandidates (linkIdMap 100%) ====================
local function getFilteredCandidates()
    local filtered = {}
    local seen = {}

    -- ดึงจาก linkIdMap โดยตรง
    for title, id in pairs(linkIdMap) do
        local k = title:lower()
        if not seen[k]
            and isEnglish(title)
            and not isUiJunk(title)
            and not isVisited(title) then
            seen[k] = true
            table.insert(filtered, title)
        end
    end

    -- Sort alphabetically
    table.sort(filtered)

    -- 🆕 cap 200
    if #filtered > 200 then
        local capped = {}
        for i = 1, 200 do capped[i] = filtered[i] end
        filtered = capped
    end

    return filtered
end

-- ==================== UI HELPERS ====================
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

-- ==================== NAVIGATE ====================
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
                    local disp = text:gsub("<[^>]+>", ""):gsub("^%s+", ""):gsub("%s+$", "")
                    local dispSuper = superNormalize(disp)

                    local score = 0
                    if dispSuper == targetSuper then score = 100
                    elseif disp:lower() == title:lower() then score = 90
                    elseif #targetSuper >= 3 and dispSuper:find(targetSuper, 1, true) then score = 80
                    elseif #dispSuper >= 3 and targetSuper:find(dispSuper, 1, true) then score = 70
                    end

                    if score > 0 then
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

        addLine("[click-try] " .. f.disp, ORANGE_WARN)

        local ok = false
        pcall(function() if target.Activate then target:Activate(); ok = true end end)
        if not ok then
            pcall(function() if target.MouseButton1Click then target.MouseButton1Click:Fire(); ok = true end end)
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
            lastFallbackData = nil
            return true
        end

        addLine("[X] no id: " .. title, RED_ERR)

        local available = {}
        for k, _ in pairs(linkIdMap) do table.insert(available, k) end

        local fallbackList = {}
        for i = 1, math.min(10, #available) do
            table.insert(fallbackList, available[i])
        end

        lastFallbackData = {
            current   = currentArticle or "?",
            target    = targetTitle or title or "?",
            attempted = title,
            fallbacks = fallbackList,
            timestamp = os.date("%H:%M:%S"),
        }

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
            addLine("  🔍 ใกล้เคียง:", ORANGE_WARN)
            for i = 1, math.min(5, #available) do
                addLine("    • " .. available[i], PINK_DARK)
            end
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
    lastFallbackData = nil
    return true
end

-- ==================== EXTRACT ANSWER ====================
local function isAnswerCandidate(text)
    if not text or text == "" then return false end
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if #text < 2 or #text > 100 then return false end

    local hasLetter = false
    for i = 1, #text do
        local b = text:byte(i)
        if (b >= 65 and b <= 90) or (b >= 97 and b <= 122) then hasLetter = true; break end
        if b >= 0xE0 and b <= 0xEF then hasLetter = true; break end
    end
    if not hasLetter then return false end
    if text:match("^[%d%s%.%,%-]+$") then return false end
    if isUiJunk(text) then return false end
    return true
end

local function extractAnswerFromTail(text)
    if not text or text == "" then return nil end
    if text:find('{%s*"picks"') or text:find('{%s*"pick"') then return nil end

    local lines = {}
    for line in text:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    if #lines == 0 then return nil end

    -- PRIORITY 1: บรรทัดสุดท้ายที่ไม่ว่าง
    local lastNonEmpty = nil
    for i = #lines, 1, -1 do
        local clean = lines[i]:gsub("^%s+", ""):gsub("%s+$", "")
        if clean ~= "" then lastNonEmpty = clean; break end
    end

    if lastNonEmpty then
        local ans = lastNonEmpty
        ans = ans:gsub("%*%*", ""):gsub("`", "")
        ans = ans:gsub("^[%(%)%[%]]+", ""):gsub("[%(%)%[%]]+$", "")
        ans = ans:gsub('^\034', ""):gsub('\034$', "")
        ans = ans:gsub("^'", ""):gsub("'$", "")
        ans = ans:gsub("[%.%,%;:]+$", "")
        ans = ans:gsub("%[%d+%]", "")
        ans = ans:gsub("^%s+", ""):gsub("%s+$", "")

        local low = ans:lower()
        local isReasoning = false
        local reasoningPrefixes = {
            "approach","reasoning","step","why","reason",
            "explanation","note","caution","warning",
            "summary","strategy","path","think","thinking",
            "final","conclusion","answer","result","pick",
            "เหตุผล","ขั้นตอน","กลยุทธ์","หมายเหตุ","คำเตือน",
            "วิเคราะห์","พิจารณา","คำตอบ","สรุป","บทสรุป",
        }
        for _, pfx in ipairs(reasoningPrefixes) do
            if low:find("^" .. pfx) then isReasoning = true; break end
        end
        if ans:match("^[Ss]tep%s*%d") or ans:match("^%d+%.") or ans:match("^[%-%*•]") then
            isReasoning = true
        end

        if not isReasoning and #ans >= 2 and #ans <= 80
            and isAnswerCandidate(ans) and isEnglish(ans) then
            return ans
        end
    end

    -- PRIORITY 2: pattern "คำตอบ: X"
    local scanStart = math.max(1, #lines - 20)
    for i = #lines, scanStart, -1 do
        local clean = lines[i]:gsub("^%s+", ""):gsub("%s+$", "")
        if clean ~= "" then
            local ans = clean:match("^คำตอบ%s*:%s*(.+)$")
                or clean:match("^คำตอบที่เลือก%s*:%s*(.+)$")
                or clean:match("^คำตอบคือ%s*:%s*(.+)$")
                or clean:match("^เลือก%s*:%s*(.+)$")
                or clean:match("^เลือกคำ%s*:%s*(.+)$")
                or clean:match("^[Aa]nswer%s*:%s*(.+)$")
                or clean:match("^[Rr]esult%s*:%s*(.+)$")
                or clean:match("^[Pp]ick%s*:%s*(.+)$")
                or clean:match("^[Cc]hoice%s*:%s*(.+)$")
                or clean:match("^[Ss]elected%s*:%s*(.+)$")

            if ans then
                ans = ans:gsub("^%s+", ""):gsub("%s+$", "")
                ans = ans:gsub("%*%*", ""):gsub("`", "")
                ans = ans:gsub("^[%(%)%[%]]+", ""):gsub("[%(%)%[%]]+$", "")
                ans = ans:gsub('^\034', ""):gsub('\034$', "")
                ans = ans:gsub("^'", ""):gsub("'$", "")
                ans = ans:gsub("[%.%,%;:]+$", "")
                ans = ans:gsub("%[%d+%]", "")
                if isAnswerCandidate(ans) then return ans end
            end

            local hasPickLine = clean:match("^ฉันเลือกรายการ%s*%d+%s*จาก%s*%d+")
                or clean:match("^ฉันเลือก%s*%d+%s*จาก%s*%d+")
                or clean:match("^I%schose%s*item%s*%d+%s*of%s*%d+")
                or clean:match("^Selected%s*item%s*%d+%s*of%s*%d+")

            if hasPickLine and i < #lines then
                local nextLine = lines[i + 1]:gsub("^%s+", ""):gsub("%s+$", "")
                local ans2 = nextLine:match("^คำตอบ%s*:%s*(.+)$")
                    or nextLine:match("^[Aa]nswer%s*:%s*(.+)$")
                    or nextLine:match("^[Rr]esult%s*:%s*(.+)$")
                    or nextLine:match("^เลือก%s*:%s*(.+)$")
                if ans2 then
                    ans2 = ans2:gsub("^%s+", ""):gsub("%s+$", "")
                    ans2 = ans2:gsub("%*%*", ""):gsub("`", "")
                    ans2 = ans2:gsub("%[%d+%]", "")
                    if isAnswerCandidate(ans2) then return ans2 end
                end
            end
        end
    end

    return nil
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
            rank = tonumber(entry.rank or entry.Rank) or defaultRank or 99,
            title = tostring(t),
            why = entry.why or entry.reason or entry.Reason or entry.reasoning,
            confidence = entry.confidence or entry.Confidence or entry.score,
        })
    end

    if type(data.picks) == "table" then
        for i, p in ipairs(data.picks) do pushTitle(p, i) end
    end
    if data.pick ~= nil then pushTitle(data.pick, 1) end
    if #out == 0 and type(data.title) == "string" and data.title ~= "" then
        table.insert(out, {rank = 1, title = data.title})
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

    local tailAnswer = extractAnswerFromTail(text)
    if tailAnswer then
        return {
            picks = {{rank = 1, title = tailAnswer, _source = "tail"}},
            _raw = {tail = true}
        }
    end

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
                "approach","reasoning","why","reason","answer",
                "result","target","next","pick","choice","explanation",
                "notes","note","caution","warning","summary","step",
                "strategy","path","เหตุผล","คำตอบ","เป้าหมาย","หมายเหตุ",
            }
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
                for _, existing in ipairs(markdown_picks) do
                    if existing:lower() == cleanBold:lower() then found = true; break end
                end
                if not found then table.insert(markdown_picks, cleanBold) end
            end
        end
    end

    for line in text:gmatch("[^\r\n]+") do
        local clean = line
        clean = clean:gsub("%*%*([^*]+)%*%*", "%1")
        clean = clean:gsub("%*([^*]+)%*", "%1")
        clean = clean:gsub("^#+%s*", "")
        clean = clean:gsub("^%s+", ""):gsub("%s+$", "")

        if clean ~= "" then
            local target = clean:match("%-%>%s*(.+)$") or 
                           clean:match("→%s*(.+)$") or 
                           clean:match("⇒%s*(.+)$")

            if target then
                target = target:gsub("^%s+", ""):gsub("%s+$", "")
                target = target:gsub("^[%(%)%[%]]+", ""):gsub("[%(%)%[%]]+$", "")
                target = target:gsub("%s*[-–—%.%,]$", "")

                if #target >= 2 and isEnglish(target) then
                    local found = false
                    for _, existing in ipairs(markdown_picks) do
                        if existing:lower() == target:lower() then found = true; break end
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
        for i, t in ipairs(lines) do
            table.insert(picks, {rank = i, title = t})
        end
        return {picks = picks, _raw = {plain = true}}
    end

    return nil
end

-- ==================== DO-GO ====================
local function doGo()
    if hopArticle and currentArticle and hopArticle ~= currentArticle then
        addLine("[!] หน้าเปลี่ยน!", ORANGE_WARN)
    end

    if not currentArticle then refreshURL() end

    -- 🆕 นับ linkIdMap
    local idCount = 0
    for _ in pairs(linkIdMap) do idCount = idCount + 1 end
    addLine("[id-map] " .. idCount .. " links", PINK_DARK)

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
    elseif data._raw and data._raw.markdown then srcTag = " (md)"
    elseif data._raw and data._raw.tail then srcTag = " (tail)" end
    addLine("[ok] " .. #data.picks .. " picks" .. srcTag, GREEN_OK)

    local navigated = false
    for i = 1, math.min(3, #data.picks) do
        local p = data.picks[i]
        local t = p.title or ""
        addLine("  #" .. i .. ": " .. t, PINK_DEEP)
        if not navigated then
            if navigateToTitle(t) then
                navigated = true
                break
            end
        end
    end

    if navigated then
        statusLbl.Text = "Clicked 🐽"
    else
        statusLbl.Text = "All picks invalid"
    end
end

-- ==================== BUTTONS ====================
local guiVisible = true

local function toggleMin()
    guiVisible = false
    frame.Visible = false
end

minBtn.MouseButton1Click:Connect(toggleMin)

local function toggleClose()
    guiVisible = not guiVisible
    frame.Visible = guiVisible
end

closeBtn.MouseButton1Click:Connect(toggleClose)

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
        return
    end
    local safe = tostring(targetTitle):gsub("\\", "\\\\"):gsub('"', '\\"')
    local json = '{\n"picks": [\n{"Target": 1, "title": "' .. safe .. '"}\n]\n}'
    local ok = copyToClipboard(json)
    addLine("[target] " .. targetTitle, ok and GREEN_OK or RED_ERR)
end)

hopBtn.MouseButton1Click:Connect(function()
    if not currentArticle then refreshURL() end
    if not currentArticle then
        addLine("[X] no current", RED_ERR)
        return
    end

    local idCount = 0
    for _ in pairs(linkIdMap) do idCount = idCount + 1 end

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

    addLine("[linkIdMap] " .. idCount .. " | CAND=" .. #filtered, PINK_DARK)
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
        doGo()
    else
        addLine("[paste] empty", PINK_DEEP)
        statusLbl.Text = "Clipboard empty"
    end

    isProcessing = false
end)

clearJsonBtn.MouseButton1Click:Connect(function()
    pasteBox.Text = ""
    addLine("[clear] json cleared", PINK_DEEP)
end)

copyLogBtn.MouseButton1Click:Connect(function()
    local lines = {}
    table.insert(lines, "CURRENT:")
    table.insert(lines, currentArticle or "?")
    table.insert(lines, "")
    table.insert(lines, "Target:")
    table.insert(lines, targetTitle or "?")
    table.insert(lines, "")

    if lastFallbackData and #(lastFallbackData.fallbacks or {}) > 0 then
        table.insert(lines, "❌ ไม่พบ ID ของคำที่เลือก (No ID Fallback)")
        table.insert(lines, "🔍 ทางเลือกที่ใกล้เคียงที่สุดไปยัง " ..
            (lastFallbackData.target or "Target") .. ":")
        for i, c in ipairs(lastFallbackData.fallbacks) do
            table.insert(lines, i .. ". " .. c)
        end
    else
        table.insert(lines, "✅ ไม่มี Fallback — เจอ ID ทุกครั้ง")
    end

    local payload = table.concat(lines, "\n")
    local ok = copyToClipboard(payload)
    addLine("[log-v2] " .. (ok and "copied" or "FAIL"), ok and GREEN_OK or RED_ERR)
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
        lastFallbackData = nil

        -- 🆕 linkIdMap เก็บทุก link
        linkIdMap = {}
        if type(art.Links) == "table" then
            for _, v in pairs(art.Links) do
                if type(v) == "table" and v.Title and v.Id then
                    linkIdMap[normalize(v.Title)] = tostring(v.Id)
                end
            end
        end

        updateLabels()

        local idCount = 0
        for _ in pairs(linkIdMap) do idCount = idCount + 1 end
        addLine("[page] " .. t .. " (" .. idCount .. " links)", PINK_DARK)
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
gui.Enabled = true
frame.Visible = true

addLine("🐷 v8.7 linkIdMap", GREEN_OK)
addLine("小女孩 → Gemini/Perplexity → 777", PINK_DEEP)
addLine("cap 200 | no scan 🐽", PINK_DARK)
statusLbl.Text = "🐽 Ready"
updateLabels()

print("[ATLAS v8.7 🐷 linkIdMap Edition] Loaded ✓")
