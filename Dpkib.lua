-- SPACE v2.2 — Multi-Source Color Detection (5 Sources)
-- 🐷 Pink Pig Edition

-- ==================== INIT ====================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end
if not LocalPlayer then warn("[SPACE] no LocalPlayer"); return end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 60)
if not PlayerGui then PlayerGui = LocalPlayer:FindFirstChild("PlayerGui") end
if not PlayerGui then PlayerGui = LocalPlayer:WaitForChild("PlayerGui") end
if not PlayerGui then warn("[SPACE] no PlayerGui"); return end

local Remotes
pcall(function() Remotes = ReplicatedStorage:WaitForChild("Remotes", 60) end)
if not Remotes then Remotes = ReplicatedStorage:FindFirstChild("Remotes") end
if not Remotes then warn("[SPACE] no Remotes"); return end

local NavigateArticle
pcall(function() NavigateArticle = Remotes:WaitForChild("NavigateArticle", 60) end)
if not NavigateArticle then NavigateArticle = Remotes:FindFirstChild("NavigateArticle") end
if not NavigateArticle then warn("[SPACE] no NavigateArticle"); return end

-- ==================== PALETTE ====================
local PINK_LIGHT  = Color3.fromRGB(255, 220, 230)
local PINK_MAIN   = Color3.fromRGB(255, 180, 200)
local PINK_DARK   = Color3.fromRGB(220, 120, 150)
local PINK_DEEP   = Color3.fromRGB(200, 100, 130)
local PINK_FIELD  = Color3.fromRGB(255, 245, 248)
local WHITE       = Color3.fromRGB(255, 255, 255)
local GREEN_OK    = Color3.fromRGB(120, 200, 140)
local RED_ERR     = Color3.fromRGB(230, 110, 130)
local ORANGE_WARN = Color3.fromRGB(240, 160, 60)
local GOLD        = Color3.fromRGB(255, 215, 0)
local BLUE_TEXT   = Color3.fromRGB(100, 150, 255)

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
        local ok = pcall(function() Delta.Clipboard.set(text) end)
        if ok then return true end
    end
    return false
end

local function getClipboard()
    if getclipboard then
        local ok, v = pcall(getclipboard)
        if ok and v then return v end
    end
    if syn and syn.get_clipboard then
        local ok, v = pcall(syn.get_clipboard)
        if ok and v then return v end
    end
    if Delta and Delta.Clipboard and Delta.Clipboard.get then
        local ok, v = pcall(function() return Delta.Clipboard.get() end)
        if ok then return v end
    end
    return nil
end

-- ==================== COLOR DETECTION ====================
local function getColorCategory(color)
    if not color then return nil end
    local r, g, b = color.R * 255, color.G * 255, color.B * 255
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local diff = max - min

    if diff < 20 then return nil end

    local hue
    if max == r then
        hue = ((g - b) / diff) % 6
    elseif max == g then
        hue = (b - r) / diff + 2
    else
        hue = (r - g) / diff + 4
    end
    hue = hue * 60
    if hue < 0 then hue = hue + 360 end

    if hue >= 180 and hue <= 260 and b > 80 then return "blue" end
    if hue >= 5 and hue <= 70 then
        if r > 80 and r > g and g >= b then return "orange" end
    end
    if (hue <= 20 or hue >= 340) and r > 120 then return "red" end

    return nil
end

-- ==================== CIRCLE DETECTION ====================
local function isCircle(obj)
    if not obj then return false end
    if not (obj:IsA("Frame") or obj:IsA("TextButton") or obj:IsA("ImageLabel") or obj:IsA("ImageButton")) then
        return false
    end

    local size = obj.AbsoluteSize
    if size.Y < 4 or size.Y > 40 then return false end
    if size.Y > 0 and math.abs(size.X / size.Y - 1) > 0.5 then return false end

    local corner = obj:FindFirstChildOfClass("UICorner")
    if corner then
        local radius = corner.CornerRadius
        if radius.Scale >= 0.2 then return true end
    end

    local aspectC = obj:FindFirstChildOfClass("UIAspectRatioConstraint")
    if aspectC and math.abs(aspectC.AspectRatio - 1) < 0.3 then
        if corner then return true end
    end

    if obj:IsA("ImageLabel") and size.Y > 0 then
        if math.abs(size.X / size.Y - 1) < 0.3 then return true end
    end

    return false
end

-- ==================== STATUS COLOR (5 SOURCES) ====================
local function getStatusColor()
    local playerName = LocalPlayer.Name
    local playerCard = nil
    local playerNameLbl = nil

    -- หา PlayerName
    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Text == playerName then
            playerNameLbl = obj
            break
        end
    end

    if not playerNameLbl then 
        print("[COLOR] ❌ หา PlayerName ไม่เจอ")
        return "🔵" 
    end

    -- หา PlayerCard (ขึ้น 5 ระดับ)
    local parent = playerNameLbl.Parent
    for _ = 1, 5 do
        if parent and parent ~= PlayerGui and parent:IsA("GuiObject") then
            playerCard = parent
            parent = parent.Parent
        end
    end

    if not playerCard then 
        print("[COLOR] ❌ หา PlayerCard ไม่เจอ")
        return "🔵" 
    end

    -- หาวงกลม
    local circles = {}
    for _, obj in ipairs(playerCard:GetDescendants()) do
        if isCircle(obj) then
            local pos = obj.AbsolutePosition
            table.insert(circles, {obj = obj, x = pos and pos.X or 0})
        end
    end

    if #circles == 0 then 
        print("[COLOR] ❌ หาวงกลมไม่เจอ")
        return "🔵" 
    end

    table.sort(circles, function(a, b) return a.x < b.x end)

    print("[COLOR] PlayerCard = " .. playerCard.Name)
    print("[COLOR] Circles = " .. #circles)

    local hasOrange = false
    local hasRed = false

    -- 🆕 ตรวจจับ 5 แหล่ง
    for i = 1, math.min(3, #circles) do
        local obj = circles[i].obj
        
        print("[COLOR] Circle " .. i .. ":")
        
        -- 1. BackgroundColor3
        if obj.BackgroundColor3 then
            local cat = getColorCategory(obj.BackgroundColor3)
            print("  BG: " .. tostring(obj.BackgroundColor3) .. " → " .. tostring(cat))
            if cat == "orange" then hasOrange = true end
            if cat == "red" then hasRed = true end
        end
        
        -- 2. ImageColor3
        if obj:IsA("ImageLabel") and obj.ImageColor3 then
            local cat = getColorCategory(obj.ImageColor3)
            print("  Image: " .. tostring(obj.ImageColor3) .. " → " .. tostring(cat))
            if cat == "orange" then hasOrange = true end
            if cat == "red" then hasRed = true end
        end
        
        -- 3. UIStroke
        local stroke = obj:FindFirstChildOfClass("UIStroke")
        if stroke and stroke.Color then
            local cat = getColorCategory(stroke.Color)
            print("  Stroke: " .. tostring(stroke.Color) .. " → " .. tostring(cat))
            if cat == "orange" then hasOrange = true end
            if cat == "red" then hasRed = true end
        end
        
        -- 4. UIGradient
        local gradient = obj:FindFirstChildOfClass("UIGradient")
        if gradient then
            if gradient.Color and gradient.Color.Keypoints then
                for _, kp in ipairs(gradient.Color.Keypoints) do
                    local cat = getColorCategory(kp.Value)
                    if cat == "orange" then hasOrange = true end
                    if cat == "red" then hasRed = true end
                end
            end
        end
        
        -- 5. Frame/ImageLabel ข้างใน
        for _, child in ipairs(obj:GetChildren()) do
            if child:IsA("Frame") and child.BackgroundColor3 then
                local cat = getColorCategory(child.BackgroundColor3)
                if cat == "orange" then hasOrange = true end
                if cat == "red" then hasRed = true end
            end
            if child:IsA("ImageLabel") and child.ImageColor3 then
                local cat = getColorCategory(child.ImageColor3)
                if cat == "orange" then hasOrange = true end
                if cat == "red" then hasRed = true end
            end
        end
    end

    print("[COLOR] hasOrange = " .. tostring(hasOrange))
    print("[COLOR] hasRed = " .. tostring(hasRed))

    if hasRed then return "🔴"
    elseif hasOrange then return "🟠"
    else return "🔵" end
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

local function isEnglish(text)
    if not text then return false end
    text = tostring(text):gsub("^%s+", ""):gsub("%s+$", "")
    if #text < 1 then return false end
    local digits = 0
    for i = 1, #text do
        local b = text:byte(i)
        if b >= 48 and b <= 57 then digits = digits + 1 end
    end
    if digits == #text then return false end
    return true
end

local UI_JUNK = {
    ["players"]=true, ["shop"]=true, ["style"]=true,
    ["scores"]=true, ["leave"]=true, ["skip"]=true,
    ["host"]=true, ["standard"]=true, ["unlimited"]=true,
    ["time left"]=true, ["article read"]=true,
    ["wikibloxia"]=true, ["wikirace"]=true, ["wikirace!"]=true,
    ["search wikibloxia"]=true,
    ["wikirace! article translation pull"]=true,
    ["the free encyclopedia"]=true,
    ["ui the free encyclopedia"]=true,
    ["choose the language you want prioritized in translating the articles"]=true,
    ["general knowledge"]=true,
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
    if low == "general knowledge" then return true end
    if low:find("general knowledge", 1, true) and #low <= 20 then return true end
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
local hopArticle = nil

local currentCap = 250

local lastHopCandidates = nil
local lastHopPage = nil
local lastFallbackCandidates = nil
local lastFallbackPage = nil
local lastFallbackTarget = nil

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

-- ==================== GUI ====================
pcall(function()
    for _, g in ipairs(PlayerGui:GetChildren()) do
        if g.Name == "傳說中的龍女來了" then g:Destroy() end
    end
end)

local gui, frame, content, scroll, layout
local titleBar, minBtn, closeBtn, title
local infoLbl, copyTargetBtn, currentLbl, statusLbl
local hopBtn, pasteLbl, pasteBox, pasteBtn
local clearJsonBtn, copyLogBtn

local ok, err = pcall(function()
    gui = Instance.new("ScreenGui")
    gui.Name = "傳說中的龍女來了"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999999
    gui.IgnoreGuiInset = true
    gui.Enabled = true
    gui.Parent = PlayerGui

    frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 350, 0, 300)
    frame.Position = UDim2.new(0.5, -175, 0.5, -150)
    frame.BackgroundColor3 = PINK_MAIN
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Visible = true
    frame.Parent = gui
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 20)
    frameCorner.Parent = frame

    titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 28)
    titleBar.BackgroundColor3 = PINK_DARK
    titleBar.BorderSizePixel = 0
    titleBar.Active = true
    titleBar.Parent = frame
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 20)
    titleCorner.Parent = titleBar

    local pigIcon = Instance.new("TextLabel")
    pigIcon.Size = UDim2.new(0, 24, 0, 22)
    pigIcon.Position = UDim2.new(0, 4, 0, 3)
    pigIcon.BackgroundTransparency = 1
    pigIcon.Text = "🐽"
    pigIcon.TextColor3 = WHITE
    pigIcon.Font = Enum.Font.SourceSansBold
    pigIcon.TextSize = 14
    pigIcon.TextXAlignment = Enum.TextXAlignment.Center
    pigIcon.Parent = titleBar

    title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -110, 1, 0)
    title.Position = UDim2.new(0, 32, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "傳說中的龍女來了"
    title.TextColor3 = WHITE
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    minBtn = Instance.new("TextButton")
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

    closeBtn = Instance.new("TextButton")
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

    content = Instance.new("Frame")
    content.Size = UDim2.new(1, 0, 1, -28)
    content.Position = UDim2.new(0, 0, 0, 28)
    content.BackgroundTransparency = 1
    content.Visible = true
    content.Parent = frame

    infoLbl = Instance.new("TextLabel")
    infoLbl.Size = UDim2.new(1, -50, 0, 18)
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

    copyTargetBtn = Instance.new("TextButton")
    copyTargetBtn.Size = UDim2.new(0, 36, 0, 18)
    copyTargetBtn.Position = UDim2.new(1, -42, 0, 4)
    copyTargetBtn.BackgroundColor3 = PINK_DEEP
    copyTargetBtn.Text = "🐽"
    copyTargetBtn.TextColor3 = WHITE
    copyTargetBtn.Font = Enum.Font.SourceSansBold
    copyTargetBtn.TextSize = 14
    copyTargetBtn.BorderSizePixel = 0
    copyTargetBtn.Parent = content
    local ctC = Instance.new("UICorner")
    ctC.CornerRadius = UDim.new(0, 8)
    ctC.Parent = copyTargetBtn

    currentLbl = Instance.new("TextLabel")
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

    statusLbl = Instance.new("TextLabel")
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

    hopBtn = Instance.new("TextButton")
    hopBtn.Size = UDim2.new(1, -12, 0, 28)
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

    pasteLbl = Instance.new("TextLabel")
    pasteLbl.Size = UDim2.new(1, -12, 0, 14)
    pasteLbl.Position = UDim2.new(0, 6, 0, 96)
    pasteLbl.BackgroundTransparency = 1
    pasteLbl.Text = "Paste Gemini JSON:"
    pasteLbl.TextColor3 = PINK_DEEP
    pasteLbl.Font = Enum.Font.SourceSans
    pasteLbl.TextSize = 11
    pasteLbl.TextXAlignment = Enum.TextXAlignment.Left
    pasteLbl.Parent = content

    pasteBox = Instance.new("TextBox")
    pasteBox.Size = UDim2.new(1, -12, 0, 44)
    pasteBox.Position = UDim2.new(0, 6, 0, 112)
    pasteBox.BackgroundColor3 = PINK_FIELD
    pasteBox.TextColor3 = BLUE_TEXT
    pasteBox.PlaceholderText = 'วางข้อความจาก AI ที่นี่'
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

    pasteBtn = Instance.new("TextButton")
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

    clearJsonBtn = Instance.new("TextButton")
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

    copyLogBtn = Instance.new("TextButton")
    copyLogBtn.Size = UDim2.new(0, 110, 0, 28)
    copyLogBtn.Position = UDim2.new(1, -116, 0, 160)
    copyLogBtn.BackgroundColor3 = ORANGE_WARN
    copyLogBtn.Text = "111"
    copyLogBtn.TextColor3 = WHITE
    copyLogBtn.Font = Enum.Font.SourceSansBold
    copyLogBtn.TextSize = 11
    copyLogBtn.BorderSizePixel = 0
    copyLogBtn.Parent = content
    local clbC = Instance.new("UICorner")
    clbC.CornerRadius = UDim.new(0, 10)
    clbC.Parent = copyLogBtn

    scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -12, 1, -196)
    scroll.Position = UDim2.new(0, 6, 0, 194)
    scroll.BackgroundColor3 = PINK_FIELD
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.Parent = content
    pcall(function()
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    end)
    local scC = Instance.new("UICorner")
    scC.CornerRadius = UDim.new(0, 10)
    scC.Parent = scroll

    layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.Parent = scroll
end)

if not ok then
    warn("[SPACE] Error สร้าง GUI: " .. tostring(err))
    return
end

-- ==================== REAL-TIME UPDATE 0.1 วิ ====================
spawn(function()
    while task.wait(0.1) do
        pcall(function()
            local statusColor = getStatusColor()
            local c = currentArticle or "?"
            if currentArticleId then c = c .. " [" .. currentArticleId .. "]" end
            currentLbl.Text = "C: " .. c .. " " .. statusColor
            infoLbl.Text = "T: " .. (targetTitle or "?")
        end)
    end
end)

-- ==================== DRAG HANDLER ====================
local dragging, dragStart, startPos = false, nil, nil

local function isClickOnButton(pos)
    if not pos then return false end
    local objs = PlayerGui:GetGuiObjectsAtPosition(pos.X, pos.Y)
    for _, o in ipairs(objs) do
        if o == minBtn or o == closeBtn or o == copyTargetBtn then return true end
        if o:IsDescendantOf(minBtn) or o:IsDescendantOf(closeBtn) or o:IsDescendantOf(copyTargetBtn) then return true end
    end
    return false
end

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        if isClickOnButton(input.Position) then return end
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

titleBar.InputChanged:Connect(function(input)
    if dragging then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ==================== FUNCTIONS ====================
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
end

local function isBlue(color)
    return getColorCategory(color) == "blue"
end

local function scanBlue()
    local items = {}
    local seen_texts = {}
    local scanned = 0
    local MAX_SCAN = 100

    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if scanned >= MAX_SCAN then break end
        if not obj:IsDescendantOf(gui) then
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                scanned = scanned + 1
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
                        local colorCat = getColorCategory(obj.TextColor3)
                        local hasColor = (colorCat == "blue" or colorCat == "orange" or colorCat == "red")

                        if not hasColor and obj.RichText then
                            for hex in text:gmatch('<font color="#(%x%x%x%x%x%x)"') do
                                local r = tonumber(hex:sub(1,2),16)
                                local g = tonumber(hex:sub(3,4),16)
                                local b = tonumber(hex:sub(5,6),16)
                                local cat = getColorCategory(Color3.fromRGB(r,g,b))
                                if cat == "blue" or cat == "orange" or cat == "red" then
                                    hasColor = true; break
                                end
                            end
                        end

                        local circle = isCircle(obj)

                        if hasColor and circle then
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
    local statusColor = getStatusColor()
    infoLbl.Text = "T: " .. (targetTitle or "?")
    local c = currentArticle or "?"
    if currentArticleId then c = c .. " [" .. currentArticleId .. "]" end
    currentLbl.Text = "C: " .. c .. " " .. statusColor
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

    if #filtered > currentCap then
        local capped = {}
        for i = 1, currentCap do capped[i] = filtered[i] end
        filtered = capped
    end
    return filtered
end

local function findFuzzyMatch(pick, candidates)
    if not pick or pick == "" then return nil, nil end
    if not candidates or #candidates == 0 then return nil, nil end

    local pickNorm = normalize(pick)
    local pickLow = pickNorm:lower()
    local pickSuper = superNormalize(pick)

    for _, c in ipairs(candidates) do
        if c:lower() == pickLow then return c, "exact" end
    end

    if #pickSuper >= 2 then
        for _, c in ipairs(candidates) do
            if superNormalize(c) == pickSuper then return c, "super-fuzzy" end
        end
    end

    if #pickLow >= 3 then
        for _, c in ipairs(candidates) do
            local cLow = c:lower()
            if cLow:find(pickLow, 1, true) or pickLow:find(cLow, 1, true) then
                return c, "substring"
            end
        end
    end

    return nil, nil
end

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

    for i = 1, math.min(3, #found) do
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
        local noSpace = normTitle:gsub("%s+", ""):lower()
        for k, v in pairs(linkIdMap) do
            if k:gsub("%s+", ""):lower() == noSpace then
                targetId = v; matchType = "no-space"; break
            end
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
        addLine("[no-id] " .. title, RED_ERR)

        if tryClickVisibleLink(title) then
            addLine("[GO] " .. title .. " (clicked, no id)", GREEN_OK)
            markVisited(title)
            statusLbl.Text = "Clicked " .. title
            return true
        end

        addLine("[X] no id: " .. title, RED_ERR)

        local available = {}
        for k, _ in pairs(linkIdMap) do
            table.insert(available, k)
        end

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

        lastFallbackCandidates = {}
        lastFallbackPage = currentArticle
        lastFallbackTarget = targetTitle

        addLine("  เส้นทางใกล้เคียง:", RED_ERR)
        for i = 1, math.min(5, #available) do
            local candidate = available[i]
            addLine("    " .. i .. ". " .. candidate, RED_ERR)
            table.insert(lastFallbackCandidates, candidate)
        end
        addLine("  กด 111 เพื่อคัดลอก Fallback", RED_ERR)

        statusLbl.Text = "No ID"
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

    local lines = {}
    for line in text:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    for i = #lines, 1, -1 do
        local line = lines[i]
        local answer = line:match("^%s*คำตอบ%s*[:：=]%s*(.+)$")
                    or line:match("^%s*Answer%s*[:：=]%s*(.+)$")
                    or line:match("^%s*Respuesta%s*[:：=]%s*(.+)$")
                    or line:match("^%s*Elección%s*[:：=]%s*(.+)$")
                    or line:match("^%s*Antwort%s*[:：=]%s*(.+)$")
                    or line:match("^%s*Réponse%s*[:：=]%s*(.+)$")
                    or line:match("^%s*Risposta%s*[:：=]%s*(.+)$")
                    or line:match("^%s*Svar%s*[:：=]%s*(.+)$")
                    or line:match("^%s*Vastaus%s*[:：=]%s*(.+)$")
                    or line:match("^%s*答案%s*[:：=]%s*(.+)$")
                    or line:match("^%s*回答%s*[:：=]%s*(.+)$")
                    or line:match("^%s*答え%s*[:：=]%s*(.+)$")
                    or line:match("^%s*답변%s*[:：=]%s*(.+)$")
                    or line:match("^%s*대답%s*[:：=]%s*(.+)$")
                    or line:match("^%s*정답%s*[:：=]%s*(.+)$")
        if answer then
            answer = answer:gsub("^%s+", ""):gsub("%s+$", "")
            if #answer >= 1 then
                return {picks = {{rank = 1, title = answer}}, _raw = {plain = true}}
            end
        end
    end

    for i = #lines, 1, -1 do
        local line = lines[i]
        if line:match("ฉันเลือก") or line:match("I choose") or line:match("I select") then
            if lines[i + 1] then
                local answer = lines[i + 1]:match("^%s*คำตอบ%s*[:：=]%s*(.+)$")
                            or lines[i + 1]:match("^%s*Answer%s*[:：=]%s*(.+)$")
                if answer then
                    answer = answer:gsub("^%s+", ""):gsub("%s+$", "")
                    if #answer >= 1 then
                        return {picks = {{rank = 1, title = answer}}, _raw = {plain = true}}
                    end
                end
            end
        end
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

    return nil
end

local function doGo()
    if hopArticle and currentArticle and hopArticle ~= currentArticle then
        addLine("[!] หน้าเปลี่ยน!", ORANGE_WARN)
    end

    if not currentArticle then refreshURL() end

    if currentArticle then
        local norm = normalize(currentArticle)
        if lastHopCandidates and lastHopPage == currentArticle then
            addLine("[auto-scan] ข้าม (HOP list = " .. #lastHopCandidates .. ")", GREEN_OK)
        else
            blueWordCache[norm] = nil
            gameCache[norm] = nil
            local found = scanBlue()
            if #found > 0 then
                blueWordCache[norm] = found
                addLine("[auto-scan] " .. #found .. " words", GREEN_OK)
            else
                addLine("[auto-scan] 0 words", PINK_DEEP)
            end
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

    local currentCandidates
    if lastHopCandidates and lastHopPage == currentArticle then
        currentCandidates = lastHopCandidates
        addLine("[validate] ✅ HOP list = " .. #currentCandidates, GREEN_OK)
    else
        currentCandidates = getFilteredCandidates()
        addLine("[validate] ⚠️ fresh scan = " .. #currentCandidates, ORANGE_WARN)
    end

    local candidateSet = {}
    for _, c in ipairs(currentCandidates) do
        candidateSet[c:lower()] = true
    end

    local validPicks = {}
    for _, p in ipairs(data.picks) do
        local t = p.title or ""
        if t == "" then
            addLine("[skip] empty title", ORANGE_WARN)
        elseif not isEnglish(t) or isUiJunk(t) then
            addLine("[reject] UI junk: " .. t, RED_ERR)
        elseif candidateSet[t:lower()] then
            table.insert(validPicks, p)
        else
            local match, mtype = findFuzzyMatch(t, currentCandidates)
            if match then
                p.title = match
                table.insert(validPicks, p)
                addLine("[fix-" .. mtype .. "] " .. t .. " → " .. match, ORANGE_WARN)
            else
                addLine("[allow] " .. t .. " → ไม่อยู่ใน scan แต่อาจคลิกได้", ORANGE_WARN)
                table.insert(validPicks, p)
            end
        end
    end

    if #validPicks == 0 then
        addLine("[X] ไม่มี pick ที่ใช้ได้", RED_ERR)
        statusLbl.Text = "No valid picks"
        return
    end

    data.picks = validPicks
    lastPicks = data.picks
    local srcTag = ""
    if data._raw and data._raw.plain then srcTag = " (plain)"
    elseif data._raw and data._raw.markdown then srcTag = " (md)" end
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

-- ==================== BUTTONS ====================
local guiVisible = true

local function toggleMin()
    if not frame or not content or not minBtn then return end
    pcall(function()
        if content.Visible then
            content.Visible = false
            frame.Size = UDim2.new(0, 350, 0, 28)
            minBtn.Text = "+"
        else
            frame.Size = UDim2.new(0, 350, 0, 300)
            content.Visible = true
            minBtn.Text = "-"
        end
    end)
end

minBtn.MouseButton1Click:Connect(function() pcall(toggleMin) end)

local function toggleClose()
    if not frame then return end
    pcall(function()
        guiVisible = not guiVisible
        frame.Visible = guiVisible
    end)
end

closeBtn.MouseButton1Click:Connect(function() pcall(toggleClose) end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        pcall(function()
            guiVisible = not guiVisible
            frame.Visible = guiVisible
        end)
    end
end)

-- 🐽 Copy Target: JSON Format
copyTargetBtn.MouseButton1Click:Connect(function()
    if not targetTitle or targetTitle == "" then
        addLine("[X] no target", RED_ERR)
        statusLbl.Text = "No target yet"
        return
    end
    
    local safe = tostring(targetTitle):gsub("\\", "\\\\"):gsub('"', '\\"')
    local json = '{\n  "picks": [\n    {\n      "rank": 1,\n      "title": "' .. safe .. '"\n    }\n  ]\n}'
    
    local ok = copyToClipboard(json)
    addLine("[🐽] " .. targetTitle .. (ok and " copied (JSON)" or " FAIL"),
        ok and GREEN_OK or RED_ERR)
    statusLbl.Text = ok and "Target copied (JSON)" or "Copy failed"
end)

hopBtn.MouseButton1Click:Connect(function()
    if not currentArticle then refreshURL() end
    if not currentArticle then
        addLine("[X] no current", RED_ERR)
        return
    end

    local norm = normalize(currentArticle)
    local cacheCount = #(gameCache[norm] or {})

    local filtered = getFilteredCandidates()
    if #filtered == 0 then
        addLine("[X] no candidates", RED_ERR)
        return
    end

    local statusColor = getStatusColor()

    local lines = {
        "CURRENT: " .. currentArticle .. statusColor,
        "Target : " .. (targetTitle or "?"),
    }
    for i = 1, math.min(currentCap, #filtered) do
        table.insert(lines, i .. ". " .. filtered[i])
    end

    table.insert(lines, "")
    table.insert(lines, "---")
    table.insert(lines, "🚀 เลือก 1 คำตอบจากรายการด้านบน")
    table.insert(lines, "🚀 ห้ามพูดชื่อ Target ในคำตอบ (เพราะจะไม่ถึงGoal)")
    table.insert(lines, "🚀 ตอบแค่: คำตอบ: [ชื่อ]")

    local ok = copyToClipboard(table.concat(lines, "\n"))

    lastHopCandidates = filtered
    lastHopPage = currentArticle

    addLine("[hop-src] cache=" .. cacheCount .. " | total=" .. #filtered .. " | " .. statusColor, PINK_DARK)
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
    local txt = getClipboard()
    if txt and #txt > 0 then
        pasteBox.Text = txt
        pasteBox.TextColor3 = Color3.fromRGB(240, 160, 60)
        addLine("[paste] " .. #txt .. " chars", ORANGE_WARN)
        statusLbl.Text = "Pasted → GO"
        doGo()
    else
        addLine("[paste] empty", PINK_DEEP)
        statusLbl.Text = "Clipboard empty"
    end
end)

clearJsonBtn.MouseButton1Click:Connect(function()
    pasteBox.Text = ""
    pasteBox.TextColor3 = BLUE_TEXT
    lastHopCandidates = nil
    lastHopPage = nil
    addLine("[clear] json cleared", PINK_DEEP)
    statusLbl.Text = "Cleared"
end)

copyLogBtn.MouseButton1Click:Connect(function()
    if not lastFallbackCandidates or #lastFallbackCandidates == 0 then
        addLine("[X] ยังไม่มี Log No ID", ORANGE_WARN)
        statusLbl.Text = "No No-ID log yet"
        return
    end

    local page = lastFallbackPage or currentArticle or "?"
    local target = lastFallbackTarget or targetTitle or "?"
    local statusColor = getStatusColor()

    local lines = {
        "CURRENT: " .. page .. statusColor,
        "Target (ปลายทาง): " .. target,
        "❌ ไม่พบ ID ของคำที่เลือก (No ID Fallback)",
        "🔍 ทางเลือกที่ใกล้เคียงที่สุด (Fallback Candidates):",
    }
    for i, c in ipairs(lastFallbackCandidates) do
        table.insert(lines, i .. ". " .. c)
    end

    table.insert(lines, "")
    table.insert(lines, "--------------------------------------------------")
    table.insert(lines, "🚨 คำสั่งบังคับ:")
    table.insert(lines, "1. โปรดเลือก 1 คำตอบจาก Fallback Candidates ด้านบนนี้ เพื่อให้ไปถึงเป้าหมายได้เร็วที่สุด")
    table.insert(lines, "")
    table.insert(lines, "📋 รูปแบบการตอบกลับที่ต้องทำตาม")
    table.insert(lines, "ให้ตอบเป็นข้อความธรรมดา 1 บรรทัด")
    table.insert(lines, "")
    table.insert(lines, "บรรทัดที่ 1: คำตอบ: [ชื่อคำที่เลือก]")
    table.insert(lines, "คำตอบ: " .. (lastFallbackCandidates[1] or "ESPN"))

    local ok = copyToClipboard(table.concat(lines, "\n"))
    addLine("[111] " .. #lastFallbackCandidates .. " fallback " .. statusColor .. " " .. (ok and "copied" or "FAIL"),
        ok and GREEN_OK or RED_ERR)
    statusLbl.Text = ok and "Log No ID copied" or "Copy failed"
end)

-- ==================== HOOKS ====================
local articleUpdated = Remotes:FindFirstChild("ArticleUpdated")
if articleUpdated then
    articleUpdated.OnClientEvent:Connect(function(payload)
        if type(payload) ~= "table" then return end
        local art = payload.Article or payload
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

        if lastHopPage and lastHopPage ~= t then
            lastHopCandidates = nil
            lastHopPage = nil
        end
        if lastFallbackPage and lastFallbackPage ~= t then
            lastFallbackCandidates = nil
            lastFallbackPage = nil
            lastFallbackTarget = nil
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

addLine("🐷 SPACE v2.2 — 5 Sources Color", GREEN_OK)
addLine("小女孩 → Prompt | 777 → Fast", PINK_DEEP)
addLine("111 → Fallback | 🐽 → Target JSON", ORANGE_WARN)
statusLbl.Text = "🐽 Ready"
updateLabels()

print("[SPACE v2.2 🐷] Loaded ✓")
