-- ATLAS v1.0 FIXED — LINKS-HERE BFS + Auto-Detect ⚡
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

local AUTO_DELAY = 0.1
local API_URL = "https://en.wikipedia.org/w/api.php"

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
    return false
end

local function getClipboard()
    if getclipboard then return getclipboard() end
    if syn and syn.get_clipboard then return syn.get_clipboard() end
    return nil
end

local function superNormalize(s)
    if not s then return "" end
    s = tostring(s):lower()
    s = s:gsub("&amp;", "&"):gsub("&#39;", "'"):gsub("&quot;", '"'):gsub("&nbsp;", " ")
    s = s:gsub("\226\128\152", "'"):gsub("\226\128\153", "'")
    s = s:gsub("\226\128\156", '"'):gsub("\226\128\157", '"')
    s = s:gsub("[^%w]", "")
    return s
end

local function isBlue(color)
    if not color then return false end
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
    return true
end

local UI_JUNK = {
    ["search wikibloxia"]=true, ["players"]=true, ["shop"]=true, ["style"]=true,
    ["scores"]=true, ["leave"]=true, ["skip"]=true, ["host"]=true,
    ["standard"]=true, ["unlimited"]=true, ["wikibloxia"]=true,
    ["time left"]=true, ["wikirace!"]=true, ["wikirace"]=true,
    ["the free encyclopedia"]=true, ["article read"]=true,
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
local backlinksCache = {}
local clickNum = 0
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

-- ==================== WIKIPEDIA API ====================
local function apiGet(params)
    local query = {}
    for k, v in pairs(params) do table.insert(query, k .. "=" .. tostring(v)) end
    local url = API_URL .. "?" .. table.concat(query, "&") .. "&format=json"
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and res and type(res) == "string" then
        local ok2, data = pcall(function() return HttpService:JSONDecode(res) end)
        if ok2 then return data end
    end
    return nil
end

local function getBacklinks(title)
    if not title or title == "" then return {} end
    local key = title:lower()
    if backlinksCache[key] then return backlinksCache[key] end
    local data = apiGet({action="query", list="backlinks", bltitle=title, bllimit=500, blnamespace=0})
    local result = {}
    if data and data.query and data.query.backlinks then
        for _, bl in ipairs(data.query.backlinks) do
            if bl.title then table.insert(result, bl.title) end
        end
    end
    backlinksCache[key] = result
    return result
end

local function getPageLinks(title)
    local data = apiGet({action="query", prop="links", titles=title, pllimit=500, plnamespace=0})
    local result = {}
    if data and data.query and data.query.pages then
        for _, page in pairs(data.query.pages) do
            if page.links then
                for _, link in ipairs(page.links) do
                    if link.title then table.insert(result, link.title) end
                end
            end
        end
    end
    return result
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
title.Text = "傳說中的龍女來了 ⚡ v1.0 Fix"
title.TextColor3 = WHITE
title.Font = Enum.Font.SourceSansBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 20, 0, 20); minBtn.Position = UDim2.new(1, -46, 0, 4)
minBtn.BackgroundColor3 = PINK_DEEP; minBtn.Text = "-"; minBtn.TextColor3 = WHITE
minBtn.Font = Enum.Font.SourceSansBold; minBtn.TextSize = 14
minBtn.BorderSizePixel = 0; minBtn.Parent = titleBar
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(1, 0)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 20, 0, 20); closeBtn.Position = UDim2.new(1, -24, 0, 4)
closeBtn.BackgroundColor3 = RED_ERR; closeBtn.Text = "X"; closeBtn.TextColor3 = WHITE
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
content.Size = UDim2.new(1, 0, 1, -28); content.Position = UDim2.new(0, 0, 0, 28)
content.BackgroundTransparency = 1; content.Parent = frame

local infoLbl = Instance.new("TextLabel")
infoLbl.Size = UDim2.new(1, -120, 0, 18); infoLbl.Position = UDim2.new(0, 6, 0, 4)
infoLbl.BackgroundColor3 = PINK_FIELD; infoLbl.BorderSizePixel = 0
infoLbl.Text = "T: ?"; infoLbl.TextColor3 = PINK_DEEP
infoLbl.Font = Enum.Font.Code; infoLbl.TextSize = 11
infoLbl.TextXAlignment = Enum.TextXAlignment.Left
infoLbl.TextTruncate = Enum.TextTruncate.AtEnd; infoLbl.Parent = content
Instance.new("UICorner", infoLbl).CornerRadius = UDim.new(0, 8)

local copyTargetBtn = Instance.new("TextButton")
copyTargetBtn.Size = UDim2.new(0, 110, 0, 18); copyTargetBtn.Position = UDim2.new(1, -116, 0, 4)
copyTargetBtn.BackgroundColor3 = PINK_DEEP; copyTargetBtn.Text = "COPY TARGET"
copyTargetBtn.TextColor3 = WHITE; copyTargetBtn.Font = Enum.Font.SourceSansBold
copyTargetBtn.TextSize = 10; copyTargetBtn.BorderSizePixel = 0; copyTargetBtn.Parent = content
Instance.new("UICorner", copyTargetBtn).CornerRadius = UDim.new(0, 8)

local currentLbl = Instance.new("TextLabel")
currentLbl.Size = UDim2.new(1, -12, 0, 18); currentLbl.Position = UDim2.new(0, 6, 0, 24)
currentLbl.BackgroundColor3 = PINK_FIELD; currentLbl.BorderSizePixel = 0
currentLbl.Text = "C: ?"; currentLbl.TextColor3 = PINK_DARK
currentLbl.Font = Enum.Font.Code; currentLbl.TextSize = 11
currentLbl.TextXAlignment = Enum.TextXAlignment.Left
currentLbl.TextTruncate = Enum.TextTruncate.AtEnd; currentLbl.Parent = content
Instance.new("UICorner", currentLbl).CornerRadius = UDim.new(0, 8)

local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1, -12, 0, 16); statusLbl.Position = UDim2.new(0, 6, 0, 44)
statusLbl.BackgroundTransparency = 1; statusLbl.Text = "🐽 Ready."
statusLbl.TextColor3 = PINK_DEEP; statusLbl.Font = Enum.Font.SourceSans
statusLbl.TextSize = 11; statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.TextTruncate = Enum.TextTruncate.AtEnd; statusLbl.Parent = content

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

-- 🆕 DETECT button (ปุ่มใหม่)
local detectBtn = Instance.new("TextButton")
detectBtn.Size = UDim2.new(1, -12, 0, 24); detectBtn.Position = UDim2.new(0, 6, 0, 96)
detectBtn.BackgroundColor3 = Color3.fromRGB(120, 180, 220)
detectBtn.Text = "🔍 DETECT (กดถ้า C: ยัง ?)"
detectBtn.TextColor3 = WHITE; detectBtn.Font = Enum.Font.SourceSansBold
detectBtn.TextSize = 12; detectBtn.BorderSizePixel = 0; detectBtn.Parent = content
Instance.new("UICorner", detectBtn).CornerRadius = UDim.new(0, 8)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -12, 1, -130); scroll.Position = UDim2.new(0, 6, 0, 128)
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

local function updateLabels()
    infoLbl.Text = "T: " .. (targetTitle or "?")
    local c = currentArticle or "?"
    if currentArticleId then c = c .. " [" .. currentArticleId .. "]" end
    currentLbl.Text = "C: " .. c
end

-- ==================== DETECT ====================
local function scanForURL()
    -- 🆕 สแกนทุก TextLabel/TextBox/RichText หา wikibloxia URL
    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextBox") or obj:IsA("TextButton") then
            local text = obj.Text or ""
            if text ~= "" and text:find("wikibloxia", 1, true) then
                local m = text:match("wiki/([^%s%?%#/]+)")
                if m and #m > 1 then
                    m = m:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
                    return normalize(m)
                end
            end
        end
    end
    return nil
end

local function detectNow()
    addLine("[DETECT] กำลังสแกน...", BLUE_LOG)
    local url = scanForURL()
    if url then
        currentArticle = url
        markVisited(url)
        updateLabels()
        addLine("[DETECT] ✓ เจอ: " .. url, GREEN_OK)
        statusLbl.Text = "🔍 " .. url
        return true
    else
        addLine("[DETECT] ✗ ไม่เจอ URL — ปุ่ม小女孩 หรือ pasted URL", ORANGE_WARN)
        statusLbl.Text = "🔍 ไม่เจอ"
        return false
    end
end

-- ==================== SCAN LINKS ====================
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
                    if blue then
                        local disp = text:gsub("<[^>]+>",""):gsub("^%s+",""):gsub("%s+$","")
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
                if cur.text:sub(-1) == " " or it.text:sub(1,1) == " " or gap <= 0.5 then
                    cur.text = cur.text .. it.text
                else
                    cur.text = cur.text .. " " .. it.text
                end
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

local function getCandidates()
    if not currentArticle then return scanBlue() end
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

-- ==================== NAVIGATE (2 modes) ====================
local function tryClickVisibleLink(title)
    -- 🆕 ถ้าไม่มี currentArticleId → คลิก UI ตรงๆ
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
                if dispSuper == targetSuper or disp:lower() == title:lower() then
                    table.insert(found, {obj=obj, score=100})
                elseif #targetSuper >= 3 and dispSuper:find(targetSuper, 1, true) then
                    table.insert(found, {obj=obj, score=70})
                end
            end
        end
    end
    if #found == 0 then return false end
    table.sort(found, function(a, b) return a.score > b.score end)
    for i = 1, math.min(3, #found) do
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
    if not title then return false end
    if normalize(title):lower() == normalize(currentArticle or ""):lower() then return false end

    -- Mode 1: ถ้ามี currentArticleId + linkIdMap → FireServer
    if currentArticleId and next(linkIdMap) then
        local normTitle = normalize(title)
        local targetId = linkIdMap[normTitle]
        if not targetId then
            local lowT = normTitle:lower()
            for k, v in pairs(linkIdMap) do if k:lower() == lowT then targetId = v; break end end
        end
        if not targetId then
            local tSup = superNormalize(normTitle)
            if #tSup >= 3 then
                for k, v in pairs(linkIdMap) do if superNormalize(k) == tSup then targetId = v; break end end
            end
        end
        if targetId then
            clickNum = clickNum + 1
            addLine("[GO] " .. title .. " (id)", GREEN_OK)
            pcall(function() NavigateArticle:FireServer(currentArticleId, targetId, clickNum) end)
            markVisited(title)
            statusLbl.Text = "→ " .. title
            return true
        end
    end

    -- Mode 2: คลิก UI
    if tryClickVisibleLink(title) then
        addLine("[GO] " .. title .. " (click)", GREEN_OK)
        markVisited(title)
        statusLbl.Text = "→ " .. title
        return true
    end

    return false
end

-- ==================== BFS ====================
local function findPathToTarget(pool, target)
    if not target or target == "" then return nil, nil end
    local tSup = superNormalize(target)
    if #tSup < 2 then return nil, nil end

    local backlinks = getBacklinks(target)
    if #backlinks == 0 then return nil, nil end

    local blSet = {}
    for _, bl in ipairs(backlinks) do blSet[bl:lower()] = true end

    -- 1-hop
    for _, c in ipairs(pool) do
        if blSet[c:lower()] then
            addLine("[BFS] 🎯 1-hop: " .. c .. " → " .. target, PURPLE_HIT)
            return c, "1-HOP"
        end
    end

    -- 2-hop
    local cand2 = {}
    for _, c in ipairs(pool) do
        if not isUiJunk(c) and #c > 1 then
            local links = getPageLinks(c)
            for _, l in ipairs(links) do
                if blSet[l:lower()] then
                    table.insert(cand2, {title=c, score=1})
                    break
                end
            end
        end
    end
    if #cand2 > 0 then
        addLine("[BFS] 🌉 2-hop: " .. cand2[1].title .. " → " .. target, PURPLE_HIT)
        return cand2[1].title, "2-HOP"
    end

    return nil, nil
end

-- ==================== AUTO ====================
local function doAutoExploreStep()
    if not autoExploreActive or autoExploreBusy then return end
    autoExploreBusy = true

    -- Detect current page
    if not currentArticle then
        local url = scanForURL()
        if url then currentArticle = url; markVisited(url); updateLabels() end
    end

    if not currentArticle then
        autoRetryCount = autoRetryCount + 1
        if autoRetryCount == 1 or autoRetryCount % 10 == 0 then
            addLine("[AUTO] ⏳ รอ detect... (" .. autoRetryCount .. ")", ORANGE_WARN)
        end
        autoExploreBusy = false
        task.defer(function()
            if autoExploreActive then task.wait(AUTO_DELAY); doAutoExploreStep() end
        end)
        return
    end
    autoRetryCount = 0

    local all = getCandidates()
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

    -- BFS
    local pick, kind = findPathToTarget(pool, targetTitle)
    if not pick then
        pick = pool[math.random(1, #pool)]
        kind = "RANDOM"
    end

    if kind == "RANDOM" then
        addLine("[AUTO] 🎲 → " .. pick, ORANGE_WARN)
    end

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
    addLine("[AUTO] 🚀 v1.0 Fix", GREEN_OK)
    statusLbl.Text = "🔵 AUTO running"
    autoRetryCount = 0
    task.defer(doAutoExploreStep)
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
local function toggleClose() guiVisible = not guiVisible; frame.Visible = guiVisible end
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
    copyToClipboard('{"picks":[{"rank":1,"title":"' .. safe .. '"}]}')
    addLine("[target] copied", GREEN_OK)
end)

detectBtn.MouseButton1Click:Connect(function() detectNow() end)

hopBtn.MouseButton1Click:Connect(function()
    detectNow()
    local filtered = getCandidates()
    if #filtered == 0 then addLine("[X] no candidates", RED_ERR); return end
    local lines = {"CURRENT: " .. (currentArticle or "?"), "TARGET: " .. (targetTitle or "?"), "", "CANDIDATES:"}
    for i, c in ipairs(filtered) do table.insert(lines, i .. ". " .. c) end
    local ok = copyToClipboard(table.concat(lines, "\n"))
    addLine("[HOP] " .. #filtered .. " cand " .. (ok and "✓" or "✗"), ok and GREEN_OK or RED_ERR)
end)

local function setAutoUI(on)
    if on then autoBtn.BackgroundColor3 = GREEN_OK; autoBtn.Text = "AUTO ⚡ ON"
    else autoBtn.BackgroundColor3 = ORANGE_WARN; autoBtn.Text = "AUTO ⚡ OFF" end
end

autoBtn.MouseButton1Click:Connect(function()
    autoExploreActive = not autoExploreActive
    setAutoUI(autoExploreActive)
    if autoExploreActive then
        addLine("[AUTO] ⚡ ON", GREEN_OK)
        -- auto-detect ถ้ายังไม่เจอ
        if not currentArticle then detectNow() end
        if currentArticle then task.defer(startAutoExplore) end
    else addLine("[AUTO] OFF", PINK_DARK) end
end)

stopAutoBtn.MouseButton1Click:Connect(function()
    autoExploreActive = false
    setAutoUI(false)
    addLine("[AUTO] ⛔ STOP", RED_ERR)
    statusLbl.Text = "🛑 Stopped"
end)

copyLogBtn.MouseButton1Click:Connect(function()
    local lines = {"=== ATLAS v1.0 Fix ==="}
    table.insert(lines, "Start: " .. (startTitle or "?"))
    table.insert(lines, "Target: " .. (targetTitle or "?"))
    table.insert(lines, "Now: " .. (currentArticle or "?"))
    table.insert(lines, "Hops: " .. #pathLog)
    local text = table.concat(lines, "\n")
    copyToClipboard(text)
    addLine("[LOG] copied", BLUE_LOG)
end)

-- ==================== HOOKS ====================
-- 🆕 ลองหลายชื่อ event
local function attachEvent(ev)
    if not ev then return end
    ev.OnClientEvent:Connect(function(payload)
        if type(payload) ~= "table" then return end
        local art = payload.Article or payload
        if type(art) ~= "table" or not art.Title then return end

        local t = normalize(art.Title)
        markVisited(t)
        if not currentArticle or currentArticle ~= t then
            table.insert(pathLog, {t=os.date("%H:%M:%S"), page=t})
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

        if autoExploreActive then task.defer(doAutoExploreStep) end
    end)
end

for _, name in ipairs({"ArticleUpdated","ArticleChanged","PageUpdated","NewArticle","ArticleLoad","PageChange","UpdateArticle"}) do
    local ev = Remotes:FindFirstChild(name)
    if ev then
        addLine("[event] ✓ " .. name, GREEN_OK)
        attachEvent(ev)
    end
end

local roundStarted = Remotes:FindFirstChild("RoundStarted")
if roundStarted then
    roundStarted.OnClientEvent:Connect(function(p)
        if type(p) ~= "table" then return end
        if p.StartArticle and p.StartArticle.Title then
            startTitle = normalize(p.StartArticle.Title)
            visitedSet = {}
            pathLog = {}
            backlinksCache = {}
            markVisited(startTitle)
        end
        if p.TargetArticle and p.TargetArticle.Title then
            targetTitle = normalize(p.TargetArticle.Title)
        end
        clickNum = 0
        updateLabels()
        if autoExploreActive then task.defer(startAutoExplore) end
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
addLine("⚡ v1.0 Fix — LINKS-HERE BFS", GREEN_OK)
addLine("auto-detect + 7 events", PINK_DEEP)

-- 🆕 รอโหลด UI แล้ว auto-detect
task.delay(1, function()
    if not currentArticle then detectNow() end
end)

statusLbl.Text = "🐽 Ready ⚡"
updateLabels()

print("[ATLAS v1.0 FIX ⚡] Loaded ✓")
