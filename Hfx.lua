-- ATLAS v1.0 — LINKS-HERE BFS ⚡
-- 🐷 สร้างใหม่จาก 0 — ใช้ Wikipedia API โดยตรง

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
    if writefile then pcall(function() writefile("atlas_log.txt", text) end) end
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
local backlinksCache = {}   -- 🆕 cache ของ backlinks
local clickNum = 0
local lastPicks = {}
local isProcessing = false
local autoChainQueue, autoChainActive, chainHistory, chainCurrentRank = {}, false, {}, 0
local autoExploreActive, autoExploreBusy, autoRetryCount = false, false, 0
local lastPickAttemptTitle = nil

-- ==================== WIKIPEDIA API ====================
local function apiGet(params)
    local query = {}
    for k, v in pairs(params) do
        table.insert(query, k .. "=" .. tostring(v))
    end
    local url = API_URL .. "?" .. table.concat(query, "&") .. "&format=json"
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and res then
        local ok2, data = pcall(function() return HttpService:JSONDecode(res) end)
        if ok2 then return data end
    end
    return nil
end

-- 🆕 ดึง backlinks (หน้าที่ link ไปยัง title)
local function getBacklinks(title)
    if not title or title == "" then return {} end
    local key = title:lower()
    if backlinksCache[key] then return backlinksCache[key] end

    local data = apiGet({
        action = "query",
        list = "backlinks",
        bltitle = title,
        bllimit = 500,
        blnamespace = 0
    })

    local result = {}
    if data and data.query and data.query.backlinks then
        for _, bl in ipairs(data.query.backlinks) do
            if bl.title then
                table.insert(result, bl.title)
            end
        end
    end
    backlinksCache[key] = result
    return result
end

-- 🆕 ดึง links จากหน้า (ใช้ตรวจสอบว่าหน้ามี link ไป target ไหม)
local function getPageLinks(title)
    local data = apiGet({
        action = "query",
        prop = "links",
        titles = title,
        pllimit = 500,
        plnamespace = 0
    })
    local result = {}
    if data and data.query and data.query.pages then
        for _, page in pairs(data.query.pages) do
            if page.links then
                for _, link in ipairs(page.links) do
                    if link.title then
                        table.insert(result, link.title)
                    end
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
title.Text = "傳說中的龍女來了 ⚡ v1.0"
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
end

local function formatPathLog()
    local lines = {}
    table.insert(lines, "=== ATLAS v1.0 PATH LOG ===")
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

local function updateLabels()
    infoLbl.Text = "T: " .. (targetTitle or "?")
    local c = currentArticle or "?"
    if currentArticleId then c = c .. " [" .. currentArticleId .. "]" end
    currentLbl.Text = "C: " .. c
end

local function refreshURL()
    if currentArticle and currentArticleId then return false end
    local url = nil
    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextBox") then
            local text = obj.Text or ""
            if text:find("wikibloxia%.org") then
                local m = text:match("wiki/([^%s%?%#]+)")
                if m then
                    m = m:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
                    url = normalize(m)
                    break
                end
            end
        end
    end
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

    if not targetId then return false end

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

-- ==================== BFS ENGINE ====================
-- 🆕 ใช้ backlinks หา path แบบ 2-hop lookahead
local function findPathToTarget(pool, target)
    local tSup = superNormalize(target)
    if #tSup < 2 then return nil end

    -- 1. ดึง backlinks ของ target
    local backlinks = getBacklinks(target)
    local blSet = {}
    for _, bl in ipairs(backlinks) do
        blSet[bl:lower()] = true
    end

    -- 2. ตรวจ link ที่อยู่ใน backlinks โดยตรง (1-hop)
    for _, c in ipairs(pool) do
        if blSet[c:lower()] then
            addLine("[BFS] 🎯 " .. c .. " → " .. target .. " (1-hop)", PURPLE_HIT)
            return c, "1-HOP"
        end
    end

    -- 3. ตรวจ 2-hop: link ที่มี link ไปยัง backlinks
    local candidates2 = {}
    for _, c in ipairs(pool) do
        local cLow = c:lower()
        -- ข้าม link ที่ไม่เกี่ยว
        if not isUiJunk(c) and #c > 1 then
            local links = getPageLinks(c)
            for _, l in ipairs(links) do
                if blSet[l:lower()] then
                    table.insert(candidates2, {title=c, bridge=l, score=#backlinks})
                    break
                end
            end
        end
    end

    if #candidates2 > 0 then
        table.sort(candidates2, function(a, b) return a.score > b.score end)
        addLine("[BFS] 🌉 " .. candidates2[1].title .. " → " .. candidates2[1].bridge .. " → " .. target .. " (2-hop)", PURPLE_HIT)
        return candidates2[1].title, "2-HOP"
    end

    return nil
end

-- ==================== AUTO ====================
local function doAutoExploreStep()
    if not autoExploreActive or autoExploreBusy then return end
    autoExploreBusy = true

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

    -- 🆕 ลอง BFS ก่อน
    local pick, kind = findPathToTarget(pool, targetTitle)
    if not pick then
        -- fallback: สุ่มจาก pool
        pick = pool[math.random(1, #pool)]
        kind = "RANDOM"
    end

    if kind == "RANDOM" then
        addLine("[AUTO] 🎲 → " .. pick, ORANGE_WARN)
    end

    addPathLog(pick, kind)
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
    addLine("[AUTO] 🚀 v1.0 BFS + LINKS-HERE", GREEN_OK)
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
        addLine("[AUTO] ⚡ ON (v1.0)", GREEN_OK)
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
            backlinksCache = {}
            markVisited(startTitle)
            addPathLog(startTitle, "START")
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
addLine("⚡ v1.0 LINKS-HERE BFS", GREEN_OK)
addLine("ใช้ Wikipedia API — backlinks", PINK_DEEP)
addLine("1-hop / 2-hop lookahead", PINK_DARK)
statusLbl.Text = "🐽 Ready ⚡"
updateLabels()

print("[ATLAS v1.0 ⚡ LINKS-HERE BFS] Loaded ✓")
