-- ATLAS v9.3 — AUTO PLAY + Groq API + Auto Key/Model Rotation
-- 🐷 Pink Pig Edition

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local NavigateArticle = Remotes:WaitForChild("NavigateArticle")

-- ==================== 🔑 API KEYS ====================
local API_KEYS = {
    "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",
    "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",
    "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",
    "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",
}
local currentKeyIndex = 1
local deadKeys = {}
local deadModels = {}   -- 🆕 จำ model ที่ 404
local workingModelIdx = nil  -- 🆕 จำ model ที่ work

-- ==================== 🤖 MODELS (25 ตัว) ====================
local GROQ_MODELS = {
    -- ✅ work แน่นอน (10 ตัวแรก)
    {id = "llama-3.1-8b-instant",                          label = "1.8b"},
    {id = "llama-3.3-70b-versatile",                       label = "70b"},
    {id = "llama3-70b-8192",                               label = "L3-70b"},
    {id = "llama3-8b-8192",                                label = "L3-8b"},
    {id = "mixtral-8x7b-32768",                            label = "mixtral"},
    {id = "gemma2-9b-it",                                  label = "gemma2"},
    {id = "gemma-2-27b-it",                                label = "gemma27b"},
    {id = "mistral-saba-24b",                              label = "saba"},
    {id = "qwen-2.5-coder-32b",                            label = "qwen-coder"},
    {id = "qwen-qwq-32b",                                  label = "qwq"},
    -- ⚠️ อาจ 404 (ลองดู)
    {id = "meta-llama/llama-4-scout-17b-16e-instruct",     label = "L4-scout"},
    {id = "meta-llama/llama-4-maverick-17b-128e-instruct", label = "L4-mav"},
    {id = "meta-llama/llama-guard-4-12b",                  label = "guard4"},
    {id = "openai/gpt-oss-120b",                           label = "gpt-120b"},
    {id = "openai/gpt-oss-20b",                            label = "gpt-20b"},
    {id = "openai/gpt-oss-safeguard-20b",                  label = "oss-safe"},
    {id = "qwen/qwen3-32b",                                label = "qwen3"},
    {id = "qwen/qwen3.6-27b",                              label = "qwen3.6"},
    {id = "deepseek-r1-distill-llama-70b",                 label = "ds-r1-70b"},
    {id = "deepseek-r1-distill-qwen-32b",                  label = "ds-r1-32b"},
    {id = "moonshotai/kimi-k2-instruct-0905",              label = "kimi"},
    {id = "groq/compound",                                 label = "compound"},
    {id = "groq/compound-mini",                            label = "comp-mini"},
    {id = "llama-prompt-guard-2-22m",                      label = "guard-22m"},
    {id = "llama-prompt-guard-2-86m",                      label = "guard-86m"},
}
local currentModelIndex = 1
local GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"

local AI_CONFIG = { max_cand = 40, temperature = 0.2, max_tokens = 500 }
local AUTO_CONFIG = { maxLoops = 60, waitPerPage = 2.5, maxErrors = 3 }

-- ==================== 🎨 PALETTE ====================
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
local GREEN_AUTO  = Color3.fromRGB(50, 180, 90)
local RED_STOP    = Color3.fromRGB(220, 60, 80)
local BLUE_KEY    = Color3.fromRGB(70, 140, 220)
local GRAY_OFF    = Color3.fromRGB(200, 200, 210)
local GRAY_TEXT   = Color3.fromRGB(80, 80, 90)

-- ==================== HELPERS ====================
local function normalize(t)
    if not t or t == "" then return t end
    return tostring(t):gsub("_", " "):gsub("^%s+", ""):gsub("%s+$", "")
end

local function copyToClipboard(text)
    if setclipboard then pcall(setclipboard, text) return true end
    if toclipboard then pcall(toclipboard, text) return true end
    if writeclipboard then pcall(writeclipboard, text) return true end
    return false
end

local function getClipboard()
    if getclipboard then return getclipboard() end
    if syn and syn.get_clipboard then return syn.get_clipboard() end
    return nil
end

local function getHTTP()
    if typeof(request) == "function" then return request end
    if typeof(http_request) == "function" then return http_request end
    if syn and syn.request then return syn.request end
    if http and http.request then return http.request end
    if fluxus and fluxus.request then return fluxus.request end
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
    s = stripDiacritics(s)
    s = s:gsub("[^%w]", "")
    return s
end

-- ==================== BLUE DETECTION ====================
local function isBlue(color)
    local r, g, b = color.R * 255, color.G * 255, color.B * 255
    if math.abs(r - g) < 10 and math.abs(g - b) < 10 and math.abs(r - b) < 10 then return false end
    if b < 55 then return false end
    if b < r - 15 or b < g - 15 then return false end
    if b > 100 and b > r + 20 and b > g + 15 then return true end
    if b > 130 and b > r and b > g and r + g + b > 300 then return true end
    if b > 90 and b >= r and b >= g and (b - r) >= 5 then return true end
    if b > 110 and r > g - 10 and b > g + 10 then return true end
    if b > 90 and r > 60 and g < r - 15 and g < b - 15 then return true end
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

-- ==================== UI JUNK ====================
local UI_JUNK = {
    ["search wikibloxia"]=true, ["wikirace! article translation pull"]=true,
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
    if low:find("^time left") or low:find("^search wiki") or low:find("^wikirace") or low:find("^wikibloxia") then return true end
    if low:match("^%d+%.?%s*$") then return true end
    return false
end

-- ==================== STATE ====================
local gameCache, blueWordCache, linkIdMap = {}, {}, {}
local currentArticle, currentArticleId, startTitle, targetTitle = nil, nil, nil, nil
local clickNum, isProcessing, isAutoRunning = 0, false, false
local visitedSet = {}

local function markVisited(name) if name and name ~= "" then visitedSet[name:lower()] = true end end
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
gui.Name = "AtlasPig"
gui.ResetOnSpawn = false
gui.DisplayOrder = 9999
gui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 350, 0, 340)
frame.Position = UDim2.new(0, 10, 0, 20)
frame.BackgroundColor3 = PINK_MAIN
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui
local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(0, 20); fc.Parent = frame

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 28)
titleBar.BackgroundColor3 = PINK_DARK
titleBar.BorderSizePixel = 0
titleBar.Active = true
titleBar.Parent = frame
local tbc = Instance.new("UICorner"); tbc.CornerRadius = UDim.new(0, 20); tbc.Parent = titleBar

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
local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(1, 0); mc.Parent = minBtn

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
local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(1, 0); cc.Parent = closeBtn

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
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
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
local ilc = Instance.new("UICorner"); ilc.CornerRadius = UDim.new(0, 8); ilc.Parent = infoLbl

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
local ctc = Instance.new("UICorner"); ctc.CornerRadius = UDim.new(0, 8); ctc.Parent = copyTargetBtn

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
local clc = Instance.new("UICorner"); clc.CornerRadius = UDim.new(0, 8); clc.Parent = currentLbl

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
hopBtn.Size = UDim2.new(0, 100, 0, 30)
hopBtn.Position = UDim2.new(0, 6, 0, 64)
hopBtn.BackgroundColor3 = PINK_DEEP
hopBtn.Text = "小女孩"
hopBtn.TextColor3 = WHITE
hopBtn.Font = Enum.Font.SourceSansBold
hopBtn.TextSize = 13
hopBtn.BorderSizePixel = 0
hopBtn.Parent = content
local hc = Instance.new("UICorner"); hc.CornerRadius = UDim.new(0, 10); hc.Parent = hopBtn

local aiBtn = Instance.new("TextButton")
aiBtn.Size = UDim2.new(0, 100, 0, 30)
aiBtn.Position = UDim2.new(0, 112, 0, 64)
aiBtn.BackgroundColor3 = PURPLE_AI
aiBtn.Text = "🤖 AI"
aiBtn.TextColor3 = WHITE
aiBtn.Font = Enum.Font.SourceSansBold
aiBtn.TextSize = 13
aiBtn.BorderSizePixel = 0
aiBtn.Parent = content
local aic = Instance.new("UICorner"); aic.CornerRadius = UDim.new(0, 10); aic.Parent = aiBtn

local autoBtn = Instance.new("TextButton")
autoBtn.Size = UDim2.new(0, 126, 0, 30)
autoBtn.Position = UDim2.new(0, 218, 0, 64)
autoBtn.BackgroundColor3 = GREEN_AUTO
autoBtn.Text = "▶ AUTO"
autoBtn.TextColor3 = WHITE
autoBtn.Font = Enum.Font.SourceSansBold
autoBtn.TextSize = 13
autoBtn.BorderSizePixel = 0
autoBtn.Parent = content
local aoc = Instance.new("UICorner"); aoc.CornerRadius = UDim.new(0, 10); aoc.Parent = autoBtn

local modelLbl = Instance.new("TextLabel")
modelLbl.Size = UDim2.new(0, 40, 0, 14)
modelLbl.Position = UDim2.new(0, 6, 0, 98)
modelLbl.BackgroundTransparency = 1
modelLbl.Text = "Model:"
modelLbl.TextColor3 = PURPLE_AI
modelLbl.Font = Enum.Font.SourceSansBold
modelLbl.TextSize = 10
modelLbl.TextXAlignment = Enum.TextXAlignment.Left
modelLbl.Parent = content

local modelPrev = Instance.new("TextButton")
modelPrev.Size = UDim2.new(0, 22, 0, 18)
modelPrev.Position = UDim2.new(0, 46, 0, 96)
modelPrev.BackgroundColor3 = PURPLE_AI
modelPrev.Text = "◀"
modelPrev.TextColor3 = WHITE
modelPrev.Font = Enum.Font.SourceSansBold
modelPrev.TextSize = 11
modelPrev.BorderSizePixel = 0
modelPrev.Parent = content
local mp1 = Instance.new("UICorner"); mp1.CornerRadius = UDim.new(0, 5); mp1.Parent = modelPrev

local modelDisplay = Instance.new("TextButton")
modelDisplay.Size = UDim2.new(0, 110, 0, 18)
modelDisplay.Position = UDim2.new(0, 70, 0, 96)
modelDisplay.BackgroundColor3 = PURPLE_AI
modelDisplay.Text = GROQ_MODELS[1].label
modelDisplay.TextColor3 = WHITE
modelDisplay.Font = Enum.Font.SourceSansBold
modelDisplay.TextSize = 10
modelDisplay.BorderSizePixel = 0
modelDisplay.Parent = content
local md = Instance.new("UICorner"); md.CornerRadius = UDim.new(0, 5); md.Parent = modelDisplay

local modelNext = Instance.new("TextButton")
modelNext.Size = UDim2.new(0, 22, 0, 18)
modelNext.Position = UDim2.new(0, 182, 0, 96)
modelNext.BackgroundColor3 = PURPLE_AI
modelNext.Text = "▶"
modelNext.TextColor3 = WHITE
modelNext.Font = Enum.Font.SourceSansBold
modelNext.TextSize = 11
modelNext.BorderSizePixel = 0
modelNext.Parent = content
local mp2 = Instance.new("UICorner"); mp2.CornerRadius = UDim.new(0, 5); mp2.Parent = modelNext

local keyLbl = Instance.new("TextButton")
keyLbl.Size = UDim2.new(0, 132, 0, 18)
keyLbl.Position = UDim2.new(0, 210, 0, 96)
keyLbl.BackgroundColor3 = BLUE_KEY
keyLbl.Text = "🔑 K1/4"
keyLbl.TextColor3 = WHITE
keyLbl.Font = Enum.Font.Code
keyLbl.TextSize = 10
keyLbl.BorderSizePixel = 0
keyLbl.Parent = content
local klc = Instance.new("UICorner"); klc.CornerRadius = UDim.new(0, 5); klc.Parent = keyLbl

local pasteLbl = Instance.new("TextLabel")
pasteLbl.Size = UDim2.new(1, -12, 0, 14)
pasteLbl.Position = UDim2.new(0, 6, 0, 118)
pasteLbl.BackgroundTransparency = 1
pasteLbl.Text = "Paste Gemini JSON:"
pasteLbl.TextColor3 = PINK_DEEP
pasteLbl.Font = Enum.Font.SourceSans
pasteLbl.TextSize = 11
pasteLbl.TextXAlignment = Enum.TextXAlignment.Left
pasteLbl.Parent = content

local pasteBox = Instance.new("TextBox")
pasteBox.Size = UDim2.new(1, -12, 0, 40)
pasteBox.Position = UDim2.new(0, 6, 0, 134)
pasteBox.BackgroundColor3 = PINK_FIELD
pasteBox.TextColor3 = PINK_DEEP
pasteBox.PlaceholderText = '{"pick":{"title":"..."}}'
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
local pbc = Instance.new("UICorner"); pbc.CornerRadius = UDim.new(0, 10); pbc.Parent = pasteBox

local pasteBtn = Instance.new("TextButton")
pasteBtn.Size = UDim2.new(0, 110, 0, 28)
pasteBtn.Position = UDim2.new(0, 6, 0, 178)
pasteBtn.BackgroundColor3 = PINK_DARK
pasteBtn.Text = "777"
pasteBtn.TextColor3 = WHITE
pasteBtn.Font = Enum.Font.SourceSansBold
pasteBtn.TextSize = 12
pasteBtn.BorderSizePixel = 0
pasteBtn.Parent = content
local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 10); pc.Parent = pasteBtn

local clearJsonBtn = Instance.new("TextButton")
clearJsonBtn.Size = UDim2.new(0, 110, 0, 28)
clearJsonBtn.Position = UDim2.new(0, 120, 0, 178)
clearJsonBtn.BackgroundColor3 = RED_ERR
clearJsonBtn.Text = "CLEAR"
clearJsonBtn.TextColor3 = WHITE
clearJsonBtn.Font = Enum.Font.SourceSansBold
clearJsonBtn.TextSize = 12
clearJsonBtn.BorderSizePixel = 0
clearJsonBtn.Parent = content
local cjc = Instance.new("UICorner"); cjc.CornerRadius = UDim.new(0, 10); cjc.Parent = clearJsonBtn

local goBtn = Instance.new("TextButton")
goBtn.Size = UDim2.new(0, 114, 0, 28)
goBtn.Position = UDim2.new(0, 234, 0, 178)
goBtn.BackgroundColor3 = GREEN_OK
goBtn.Text = "GO 🐽"
goBtn.TextColor3 = WHITE
goBtn.Font = Enum.Font.SourceSansBold
goBtn.TextSize = 12
goBtn.BorderSizePixel = 0
goBtn.Parent = content
local gc2 = Instance.new("UICorner"); gc2.CornerRadius = UDim.new(0, 10); gc2.Parent = goBtn

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -12, 1, -214)
scroll.Position = UDim2.new(0, 6, 0, 214)
scroll.BackgroundColor3 = PINK_FIELD
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = content
local scc = Instance.new("UICorner"); scc.CornerRadius = UDim.new(0, 10); scc.Parent = scroll

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 2)
layout.Parent = scroll

local function addLine(text, color)
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

local function updateModelDisplay()
    modelDisplay.Text = GROQ_MODELS[currentModelIndex].label
    keyLbl.Text = "🔑 K" .. currentKeyIndex .. "/" .. #API_KEYS
end

modelPrev.MouseButton1Click:Connect(function()
    currentModelIndex = currentModelIndex - 1
    if currentModelIndex < 1 then currentModelIndex = #GROQ_MODELS end
    updateModelDisplay()
    addLine("[model] " .. GROQ_MODELS[currentModelIndex].id, PURPLE_AI)
end)

modelNext.MouseButton1Click:Connect(function()
    currentModelIndex = currentModelIndex + 1
    if currentModelIndex > #GROQ_MODELS then currentModelIndex = 1 end
    updateModelDisplay()
    addLine("[model] " .. GROQ_MODELS[currentModelIndex].id, PURPLE_AI)
end)

modelDisplay.MouseButton1Click:Connect(function()
    addLine("[model] = " .. GROQ_MODELS[currentModelIndex].id, PURPLE_AI)
end)

keyLbl.MouseButton1Click:Connect(function()
    deadKeys = {}
    deadModels = {}
    workingModelIdx = nil
    currentKeyIndex = 1
    updateModelDisplay()
    addLine("[KEY+MODEL] reset all 🐽", GREEN_OK)
end)

-- ==================== SCAN BLUE ====================
local function scanBlue()
    local items, seen_texts = {}, {}
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
    local merged, cur = {}, nil
    for _, it in ipairs(items) do
        if not cur then
            cur = {text=it.text, x=it.x, y=it.y, endX=it.x+it.w}
        else
            local sameLine = math.abs(it.y - cur.y) <= 6
            local gap = it.x - cur.endX
            if sameLine and gap < 25 and gap > -10 then
                local addSpace = true
                if cur.text:sub(-1) == " " or it.text:sub(1,1) == " " then addSpace = false end
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
    local url = getCurrentURL()
    if url then
        if not currentArticle or currentArticle ~= url then
            currentArticle = url
            markVisited(url)
            updateLabels()
            return true
        end
    end
    return false
end

local function getFilteredCandidates()
    if not currentArticle then return {} end
    local norm = normalize(currentArticle)
    local candidates, seen = {}, {}
    local function addSource(list)
        for _, c in ipairs(list) do
            if c and c ~= "" then
                local k = c:lower()
                if not seen[k] then seen[k] = true; table.insert(candidates, c) end
            end
        end
    end
    addSource(gameCache[norm] or {})
    local scan = scanBlue()
    addSource(scan)
    addSource(blueWordCache[norm] or {})
    if #scan > 0 then blueWordCache[norm] = scan end
    local filtered = {}
    for _, c in ipairs(candidates) do
        if isEnglish(c) and not isUiJunk(c) and not isVisited(c) then table.insert(filtered, c) end
    end
    if #filtered > 60 then
        local capped = {}
        for i = 1, 60 do capped[i] = filtered[i] end
        filtered = capped
    end
    return filtered
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
                        table.insert(found, {obj = obj, score = score})
                    end
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
        local ts = superNormalize(normTitle)
        if #ts >= 3 then
            for k, v in pairs(linkIdMap) do
                if superNormalize(k) == ts then targetId = v; matchType = "super"; break end
            end
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
        if tryClickVisibleLink(title) then markVisited(title); return true end
        return false
    end
    clickNum = clickNum + 1
    local tag = matchType ~= "exact" and (" [" .. matchType .. "]") or ""
    addLine("[GO] " .. title .. " (id=" .. targetId .. ")" .. tag, GREEN_OK)
    pcall(function() NavigateArticle:FireServer(currentArticleId, targetId, clickNum) end)
    markVisited(title)
    return true
end

-- ==================== PARSE PICKS ====================
local function normalizePicks(data)
    local out = {}
    if type(data) ~= "table" then return out end
    local function pushTitle(entry, defaultRank)
        if type(entry) == "string" then
            table.insert(out, {rank = defaultRank or 99, title = entry}); return
        end
        if type(entry) ~= "table" then return end
        local t = entry.title or entry.Title or entry.name or entry.next
        if not t or t == "" then return end
        table.insert(out, {rank = tonumber(entry.rank or entry.Rank) or defaultRank or 99, title = tostring(t)})
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
        if not seen[k] then seen[k] = true; table.insert(deduped, p) end
    end
    return deduped
end

local function parsePicksFromText(text)
    if not text or text == "" then return nil end
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
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
                if depth == 0 and lastOpen then table.insert(attempts, text:sub(lastOpen, i)); break end
            end
        end
        for _, c in ipairs(attempts) do
            local ok, data = pcall(function() return HttpService:JSONDecode(c) end)
            if ok and type(data) == "table" then
                if data.picks or data.pick or data.title then
                    local picks = normalizePicks(data)
                    if #picks > 0 then return {picks = picks, _raw = data} end
                end
            end
        end
    end
    local markdown_picks = {}
    for bold in text:gmatch("%*%*(.-)%*%*") do
        bold = bold:gsub("^%s+", ""):gsub("%s+$", "")
        if #bold >= 2 and #bold <= 80 then
            local hasThai = false
            for i = 1, #bold do
                local b = bold:byte(i)
                if b and b >= 0xE0 and b <= 0xEF then hasThai = true; break end
            end
            if not hasThai and isEnglish(bold) then
                local found = false
                for _, e in ipairs(markdown_picks) do
                    if e:lower() == bold:lower() then found = true; break end
                end
                if not found then table.insert(markdown_picks, bold) end
            end
        end
    end
    for line in text:gmatch("[^\r\n]+") do
        local clean = line:gsub("%*%*([^*]+)%*%*", "%1"):gsub("%*([^*]+)%*", "%1"):gsub("^#+%s*", ""):gsub("^%s+",""):gsub("%s+$","")
        if clean ~= "" then
            local target = clean:match("%-%>%s*(.+)$") or clean:match("→%s*(.+)$") or clean:match("⇒%s*(.+)$")
            if target then
                target = target:gsub("^%s+",""):gsub("%s+$",""):gsub("^[%(%)%[%]]+",""):gsub("[%(%)%[%]]+$",""):gsub("%s*[-–—%.%,]$","")
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
        for i, t in ipairs(markdown_picks) do table.insert(picks, {rank = i, title = t}) end
        return {picks = picks, _raw = {markdown = true}}
    end
    local lines = {}
    for line in text:gmatch("[^\r\n]+") do
        line = line:gsub("^%s+", ""):gsub("%s+$", "")
        if line ~= "" and not line:match("^%d+%.%s*$") then
            line = line:gsub("^%d+%.%s*", ""):gsub("^[-%*]%s*", "")
            if line ~= "" and isEnglish(line) then table.insert(lines, line) end
        end
    end
    if #lines == 1 then return {picks = {{rank = 1, title = lines[1]}}, _raw = {plain = true}} end
    if #lines >= 2 then
        local picks = {}
        for i, t in ipairs(lines) do table.insert(picks, {rank = i, title = t}) end
        return {picks = picks, _raw = {plain = true}}
    end
    return nil
end

-- ==================== DO-GO ====================
local function doGo()
    if not currentArticle then refreshURL() end
    if currentArticle then
        local norm = normalize(currentArticle)
        blueWordCache[norm] = nil
        gameCache[norm] = nil
        scanBlue()
    end
    local text = pasteBox.Text or ""
    if text == "" then addLine("[X] paste box empty", RED_ERR); return false end
    local data = parsePicksFromText(text)
    if not data or not data.picks or #data.picks == 0 then
        addLine("[X] parse failed", RED_ERR); return false
    end
    addLine("[ok] " .. #data.picks .. " picks", GREEN_OK)
    for i = 1, math.min(3, #data.picks) do
        local p = data.picks[i]
        local t = p.title or ""
        addLine("  #" .. i .. ": " .. t, PINK_DEEP)
        if navigateToTitle(t) then return true end
    end
    return false
end

-- ==================== GROQ API ====================
local function buildPrompt(candidates)
    local candLines = {}
    for i = 1, math.min(AI_CONFIG.max_cand, #candidates) do
        table.insert(candLines, i .. ". " .. candidates[i])
    end
    return string.format([[You are a WikiRace pathfinder. Pick best next articles to reach TARGET.

CURRENT: %s
TARGET: %s

CANDIDATES:
%s

Rules:
- Pick top 3 candidates closest to TARGET
- Return ONLY valid JSON, no markdown
- Format: {"picks":[{"rank":1,"title":"Exact Name"},{"rank":2,"title":"Exact Name"}]}
- "title" MUST match CANDIDATES exactly]], currentArticle or "?", targetTitle or "?", table.concat(candLines, "\n"))
end

local function callGroq(keyIdx, model, prompt)
    local http = getHTTP()
    if not http then return nil, "no HTTP" end
    local key = API_KEYS[keyIdx]
    if not key then return nil, "no key" end

    local body = HttpService:JSONEncode({
        model = model,
        messages = {
            {role = "system", content = "You are a JSON-only assistant. Always return valid JSON."},
            {role = "user", content = prompt},
        },
        temperature = AI_CONFIG.temperature,
        max_tokens = AI_CONFIG.max_tokens,
        response_format = {type = "json_object"},
    })

    local ok, res = pcall(function()
        return http({
            Url = GROQ_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Authorization"] = "Bearer " .. key,
            },
            Body = body,
        })
    end)

    if not ok or not res then return nil, "HTTP fail" end
    if res.StatusCode == 401 then return nil, "401 invalid key" end
    if res.StatusCode == 403 then return nil, "403 forbidden" end
    if res.StatusCode == 404 then return nil, "404 model not found" end
    if res.StatusCode == 429 then return nil, "429 rate limit" end
    if res.StatusCode ~= 200 then return nil, "HTTP " .. tostring(res.StatusCode) end

    local parseOk, respData = pcall(function() return HttpService:JSONDecode(res.Body) end)
    if not parseOk or not respData then return nil, "bad JSON" end
    if not respData.choices or not respData.choices[1] then return nil, "no choices" end
    local msg = respData.choices[1].message
    if not msg or not msg.content then return nil, "no content" end
    return msg.content, nil
end

-- 🆕 Smart Key + Model Rotation with deadModels caching
local function askGroq()
    if not currentArticle then refreshURL() end
    if not currentArticle then return nil, "no current" end
    if not targetTitle then return nil, "no target" end

    local filtered = getFilteredCandidates()
    if #filtered == 0 then return nil, "no candidates" end
    local prompt = buildPrompt(filtered)

    -- สร้าง priority list: [workingModel] + [ตัวอื่นๆ ที่ยังไม่ dead]
    local modelOrder = {}
    if workingModelIdx and not deadModels[workingModelIdx] then
        table.insert(modelOrder, workingModelIdx)
    end
    -- เริ่มจาก currentModelIndex แล้วไล่
    for mOff = 0, #GROQ_MODELS - 1 do
        local mIdx = ((currentModelIndex - 1 + mOff) % #GROQ_MODELS) + 1
        if not deadModels[mIdx] and mIdx ~= workingModelIdx then
            table.insert(modelOrder, mIdx)
        end
    end

    -- ลอง (key × model) ตามลำดับ
    for kOff = 0, #API_KEYS - 1 do
        local kIdx = ((currentKeyIndex - 1 + kOff) % #API_KEYS) + 1
        if not deadKeys[kIdx] then
            for _, mIdx in ipairs(modelOrder) do
                local model = GROQ_MODELS[mIdx].id
                local label = GROQ_MODELS[mIdx].label
                addLine("[AI] K" .. kIdx .. " × " .. label, PURPLE_AI)

                local t0 = tick()
                local answer, err = callGroq(kIdx, model, prompt)
                local dt = tick() - t0

                if answer then
                    currentKeyIndex = kIdx
                    currentModelIndex = mIdx
                    workingModelIdx = mIdx
                    updateModelDisplay()
                    addLine("[AI] ✓ " .. string.format("%.1f", dt) .. "s", GREEN_OK)
                    return answer, nil
                else
                    -- 404 → model ไม่มี → mark dead เร็วๆ ไม่ log ยาว
                    if tostring(err):find("404") then
                        deadModels[mIdx] = true
                        addLine("[AI] ✗ " .. label .. " 404 💀", GRAY_TEXT)
                    -- 401/403 → key ตาย → mark + break
                    elseif tostring(err):find("401") or tostring(err):find("403") then
                        deadKeys[kIdx] = true
                        addLine("[KEY] K" .. kIdx .. " ใช้ไม่ได้ 💀", RED_ERR)
                        break
                    -- 429 → key หมดชั่วคราว → ลอง model ถัดไป
                    elseif tostring(err):find("429") then
                        addLine("[AI] ✗ " .. label .. " 429", ORANGE_WARN)
                    else
                        addLine("[AI] ✗ " .. tostring(err), ORANGE_WARN)
                    end
                end
                task.wait(0.1)
            end
        end
    end

    -- reset dead cache (เผื่อผ่านไปนาน)
    deadKeys = {}
    deadModels = {}
    workingModelIdx = nil
    return nil, "all keys+models failed"
end

local function askAndGo()
    local answer, err = askGroq()
    if not answer then
        addLine("[X] " .. tostring(err), RED_ERR)
        statusLbl.Text = "❌ " .. tostring(err)
        return false
    end
    pasteBox.Text = answer
    return doGo()
end

-- ==================== AUTO LOOP ====================
local function runAutoLoop()
    if isAutoRunning then
        isAutoRunning = false
        autoBtn.Text = "▶ AUTO"
        autoBtn.BackgroundColor3 = GREEN_AUTO
        addLine("[AUTO] ⏸ หยุด", RED_STOP)
        return
    end
    if not targetTitle then
        addLine("[AUTO] ❌ no target", RED_ERR)
        return
    end

    isAutoRunning = true
    autoBtn.Text = "⏸ STOP"
    autoBtn.BackgroundColor3 = RED_STOP

    task.spawn(function()
        local loopCount, errCount = 0, 0
        while isAutoRunning and loopCount < AUTO_CONFIG.maxLoops do
            loopCount = loopCount + 1
            refreshURL()

            if currentArticle and normalize(currentArticle):lower() == normalize(targetTitle):lower() then
                addLine("🎉 ถึง TARGET! (" .. loopCount .. " ครั้ง)", GREEN_OK)
                statusLbl.Text = "🎉 Target reached!"
                pcall(function()
                    local s = Instance.new("Sound")
                    s.SoundId = "rbxassetid://9114221327"
                    s.Volume = 0.5
                    s.Parent = game:GetService("SoundService")
                    s:Play()
                end)
                break
            end

            statusLbl.Text = "▶ AUTO #" .. loopCount .. "/" .. AUTO_CONFIG.maxLoops
            addLine("[AUTO] #" .. loopCount .. " C=" .. (currentArticle or "?") .. " T=" .. targetTitle, PURPLE_AI)

            local ok = askAndGo()
            if not ok then
                errCount = errCount + 1
                if errCount >= AUTO_CONFIG.maxErrors then
                    addLine("[AUTO] error " .. AUTO_CONFIG.maxErrors .. " ครั้งติด → หยุด", RED_ERR)
                    break
                end
            else
                errCount = 0
            end
            task.wait(AUTO_CONFIG.waitPerPage)
        end

        isAutoRunning = false
        autoBtn.Text = "▶ AUTO"
        autoBtn.BackgroundColor3 = GREEN_AUTO
        statusLbl.Text = "🐽 Ready."
    end)
end

-- ==================== EVENTS ====================
local guiVisible = true
minBtn.MouseButton1Click:Connect(function()
    if content.Visible then
        content.Visible = false
        frame.Size = UDim2.new(0, 350, 0, 28)
        minBtn.Text = "+"
    else
        content.Visible = true
        frame.Size = UDim2.new(0, 350, 0, 340)
        minBtn.Text = "-"
    end
end)
closeBtn.MouseButton1Click:Connect(function()
    guiVisible = not guiVisible
    frame.Visible = guiVisible
end)
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        guiVisible = not guiVisible
        frame.Visible = guiVisible
    end
end)

copyTargetBtn.MouseButton1Click:Connect(function()
    if not targetTitle then return end
    local safe = tostring(targetTitle):gsub("\\", "\\\\"):gsub('"', '\\"')
    local json = '{\n"picks": [\n{"rank": 1, "title": "' .. safe .. '"}\n]\n}'
    copyToClipboard(json)
    addLine("[target] copied", GREEN_OK)
end)

hopBtn.MouseButton1Click:Connect(function()
    if not currentArticle then refreshURL() end
    if not currentArticle then return end
    local filtered = getFilteredCandidates()
    if #filtered == 0 then addLine("[X] no candidates", RED_ERR); return end
    local lines = {"CURRENT: " .. currentArticle, "TARGET: " .. (targetTitle or "?"), "", "CANDIDATES:"}
    for i, c in ipairs(filtered) do table.insert(lines, i .. ". " .. c) end
    copyToClipboard(table.concat(lines, "\n"))
    addLine("[HOP] " .. #filtered .. " cand copied", GREEN_OK)
end)

aiBtn.MouseButton1Click:Connect(function()
    if isProcessing or isAutoRunning then return end
    isProcessing = true
    task.spawn(function()
        pcall(askAndGo)
        isProcessing = false
    end)
end)

autoBtn.MouseButton1Click:Connect(function()
    runAutoLoop()
end)

pasteBtn.MouseButton1Click:Connect(function()
    if isProcessing or isAutoRunning then return end
    isProcessing = true
    local txt = getClipboard()
    if txt and #txt > 0 then
        pasteBox.Text = txt
        task.wait(0.1)
        doGo()
    end
    isProcessing = false
end)

clearJsonBtn.MouseButton1Click:Connect(function()
    pasteBox.Text = ""
end)

goBtn.MouseButton1Click:Connect(function()
    if isProcessing or isAutoRunning then return end
    isProcessing = true
    doGo()
    isProcessing = false
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.One and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        if not isProcessing and not isAutoRunning then
            isProcessing = true
            task.spawn(function() pcall(askAndGo); isProcessing = false end)
        end
    end
    if input.KeyCode == Enum.KeyCode.Two and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        runAutoLoop()
    end
end)

-- ==================== HOOKS ====================
local articleUpdated = Remotes:FindFirstChild("ArticleUpdated")
if articleUpdated then
    articleUpdated.OnClientEvent:Connect(function(payload)
        if type(payload) ~= "table" then return end
        local art = payload.Article
        if type(art) ~= "table" or not art.Title then return end
        local t = normalize(art.Title)
        markVisited(t)
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
        addLine("[page] " .. t .. " (" .. #links .. " links)", PINK_DARK)
    end)
end

local roundStarted = Remotes:FindFirstChild("RoundStarted")
if roundStarted then
    roundStarted.OnClientEvent:Connect(function(p)
        if type(p) ~= "table" then return end
        if p.StartArticle and p.StartArticle.Title then
            startTitle = normalize(p.StartArticle.Title)
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
updateModelDisplay()

addLine("🐷 v9.3 ready", GREEN_OK)
addLine("小女孩 | 🤖 | ▶ AUTO", PINK_DEEP)
addLine("25 models × 4 keys auto-rotate", BLUE_KEY)
statusLbl.Text = "🐽 Ready."
updateLabels()

print("[ATLAS v9.3 🐷 Smart 25-Model Rotation] Loaded ✓")
