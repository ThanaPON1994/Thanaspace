-- ATLAS v9.6 — Groq 9-Keys + Compound + Rank1 + Copy Log
-- 🐷 Pink Pig Edition

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HS = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")
local Remotes = RS:WaitForChild("Remotes")
local Nav = Remotes:WaitForChild("NavigateArticle")

-- ==================== 🔑 9 KEYS ====================
local API_KEYS = getgenv().ATLAS_GROQ_KEYS or {
    "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",
    "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",
    "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",
    "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",
    "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",
    "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",
    "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",
    "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",
    "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",
}
local cKI, deadK, deadM, wMI = 1, {}, {}, nil

-- ==================== 🤖 MODELS ====================
local MODELS = {
    {id = "groq/compound",      label = "compound"},
    {id = "groq/compound-mini", label = "comp-mini"},
}
local cMI = 1
local URL = "https://api.groq.com/openai/v1/chat/completions"
local CFG = {max_cand = 40, temp = 0.2, max_tok = 500}
local AUTO = {max = 60, wait = 2.5, maxErr = 3}

-- ==================== 🎨 PALETTE ====================
local PM = Color3.fromRGB(255,180,200)
local PD = Color3.fromRGB(220,120,150)
local PX = Color3.fromRGB(200,100,130)
local PF = Color3.fromRGB(255,245,248)
local W  = Color3.fromRGB(255,255,255)
local G  = Color3.fromRGB(120,200,140)
local R  = Color3.fromRGB(230,110,130)
local O  = Color3.fromRGB(240,160,60)
local P  = Color3.fromRGB(130,90,220)
local GA = Color3.fromRGB(50,180,90)
local GR = Color3.fromRGB(220,60,80)
local BK = Color3.fromRGB(70,140,220)
local BL = Color3.fromRGB(100,180,220)
local GY = Color3.fromRGB(80,80,90)

-- ==================== HELPERS ====================
local function norm(t) if not t or t=="" then return t end; return tostring(t):gsub("_"," "):gsub("^%s+",""):gsub("%s+$","") end
local function clip(t)
    if setclipboard then pcall(setclipboard,t) return true end
    if toclipboard then pcall(toclipboard,t) return true end
    if writeclipboard then pcall(writeclipboard,t) return true end
    return false
end
local function gClip() if getclipboard then return getclipboard() end return nil end
local function gHTTP()
    if typeof(request)=="function" then return request end
    if typeof(http_request)=="function" then return http_request end
    if syn and syn.request then return syn.request end
    if http and http.request then return http.request end
    if fluxus and fluxus.request then return fluxus.request end
    return nil
end

local function isBlue(c)
    local r,g,b = c.R*255,c.G*255,c.B*255
    if math.abs(r-g)<10 and math.abs(g-b)<10 and math.abs(r-b)<10 then return false end
    if b<55 or b<r-15 or b<g-15 then return false end
    if b>100 and b>r+20 and b>g+15 then return true end
    if b>130 and b>r and b>g and r+g+b>300 then return true end
    if b>90 and b>=r and b>=g and (b-r)>=5 then return true end
    if b>110 and r>g-10 and b>g+10 then return true end
    return false
end

local function isEN(t)
    if not t then return false end
    t = tostring(t):gsub("^%s+",""):gsub("%s+$","")
    if #t<2 then return false end
    local L,D = 0,0
    for i=1,#t do local b=t:byte(i)
        if (b>=65 and b<=90) or (b>=97 and b<=122) then L=L+1
        elseif b>=48 and b<=57 then D=D+1 end
    end
    if L<2 or D==#t then return false end
    for i=1,#t do local b=t:byte(i) if b and b>=0xE0 and b<=0xEF then return false end end
    return true
end

local JUNK = {
    ["search wikibloxia"]=1,["wikirace! article translation pull"]=1,
    ["players"]=1,["shop"]=1,["style"]=1,["scores"]=1,["leave"]=1,["skip"]=1,
    ["host"]=1,["standard"]=1,["unlimited"]=1,["wikibloxia"]=1,
    ["time left"]=1,["wikirace!"]=1,["wikirace"]=1,
}
local function isJunk(t)
    if not t or t=="" then return false end
    local l = t:lower():gsub("^%s+",""):gsub("%s+$","")
    if JUNK[l] then return true end
    if l:find("^time left") or l:find("^search wiki") or l:find("^wikirace") or l:find("^wikibloxia") then return true end
    if l:match("^%d+%.?%s*$") then return true end
    return false
end

local function supN(s)
    if not s then return "" end
    s = tostring(s):lower():gsub("&amp;","&"):gsub("&#39;","'"):gsub("&quot;",'"')
    s = s:gsub("[^%w]","")
    return s
end

-- ==================== STATE ====================
local LOG = {}
local gCache, bwCache, linkMap = {}, {}, {}
local cArt, cArtId, tTitle = nil, nil, nil
local clickN, isProc, isAuto = 0, false, false
local vSet = {}

local function markV(n) if n and n~="" then vSet[n:lower()]=true end end
local function isV(n) if not n or n=="" then return false end return vSet[n:lower()]==true end

local function getURL()
    for _,o in ipairs(PG:GetDescendants()) do
        if o:IsA("TextLabel") or o:IsA("TextBox") then
            local t = o.Text or ""
            if t:find("wikibloxia%.org") then
                local m = t:match("wiki/([^%s%?%#]+)")
                if m then
                    m = m:gsub("%%(%x%x)", function(h) return string.char(tonumber(h,16)) end)
                    return norm(m)
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
gui.Parent = PG

local F = Instance.new("Frame")
F.Size = UDim2.new(0,350,0,360)
F.Position = UDim2.new(0,10,0,20)
F.BackgroundColor3 = PM
F.BorderSizePixel = 0
F.Active = true
F.Parent = gui
Instance.new("UICorner",F).CornerRadius = UDim.new(0,20)

local TB = Instance.new("Frame")
TB.Size = UDim2.new(1,0,0,28)
TB.BackgroundColor3 = PD
TB.BorderSizePixel = 0
TB.Active = true
TB.Parent = F
Instance.new("UICorner",TB).CornerRadius = UDim.new(0,20)

local TTL = Instance.new("TextLabel")
TTL.Size = UDim2.new(1,-80,1,0)
TTL.Position = UDim2.new(0,34,0,0)
TTL.BackgroundTransparency = 1
TTL.Text = "這位傳奇的龍衝浪女孩回來了。"
TTL.TextColor3 = W
TTL.Font = Enum.Font.SourceSansBold
TTL.TextSize = 12
TTL.TextXAlignment = Enum.TextXAlignment.Left
TTL.TextTruncate = Enum.TextTruncate.AtEnd
TTL.Parent = TB

local MB = Instance.new("TextButton")
MB.Size = UDim2.new(0,20,0,20)
MB.Position = UDim2.new(1,-46,0,4)
MB.BackgroundColor3 = PX
MB.Text = "-"
MB.TextColor3 = W
MB.Font = Enum.Font.SourceSansBold
MB.TextSize = 14
MB.BorderSizePixel = 0
MB.Parent = TB
Instance.new("UICorner",MB).CornerRadius = UDim.new(1,0)

local CB = Instance.new("TextButton")
CB.Size = UDim2.new(0,20,0,20)
CB.Position = UDim2.new(1,-24,0,4)
CB.BackgroundColor3 = R
CB.Text = "X"
CB.TextColor3 = W
CB.Font = Enum.Font.SourceSansBold
CB.TextSize = 12
CB.BorderSizePixel = 0
CB.Parent = TB
Instance.new("UICorner",CB).CornerRadius = UDim.new(1,0)

local drag, dS, sP = false, nil, nil
TB.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        drag = true; dS = i.Position; sP = F.Position
    end
end)
TB.InputChanged:Connect(function(i)
    if drag then
        local d = i.Position - dS
        F.Position = UDim2.new(sP.X.Scale, sP.X.Offset+d.X, sP.Y.Scale, sP.Y.Offset+d.Y)
    end
end)
TB.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end
end)

local CT = Instance.new("Frame")
CT.Size = UDim2.new(1,0,1,-28)
CT.Position = UDim2.new(0,0,0,28)
CT.BackgroundTransparency = 1
CT.Parent = F

-- Info
local iL = Instance.new("TextLabel")
iL.Size = UDim2.new(1,-120,0,18)
iL.Position = UDim2.new(0,6,0,4)
iL.BackgroundColor3 = PF
iL.BorderSizePixel = 0
iL.Text = "T: ?"
iL.TextColor3 = PX
iL.Font = Enum.Font.Code
iL.TextSize = 11
iL.TextXAlignment = Enum.TextXAlignment.Left
iL.TextTruncate = Enum.TextTruncate.AtEnd
iL.Parent = CT
Instance.new("UICorner",iL).CornerRadius = UDim.new(0,8)

local ctB = Instance.new("TextButton")
ctB.Size = UDim2.new(0,110,0,18)
ctB.Position = UDim2.new(1,-116,0,4)
ctB.BackgroundColor3 = PX
ctB.Text = "COPY TARGET"
ctB.TextColor3 = W
ctB.Font = Enum.Font.SourceSansBold
ctB.TextSize = 10
ctB.BorderSizePixel = 0
ctB.Parent = CT
Instance.new("UICorner",ctB).CornerRadius = UDim.new(0,8)

local cL = Instance.new("TextLabel")
cL.Size = UDim2.new(1,-12,0,18)
cL.Position = UDim2.new(0,6,0,24)
cL.BackgroundColor3 = PF
cL.BorderSizePixel = 0
cL.Text = "C: ?"
cL.TextColor3 = PD
cL.Font = Enum.Font.Code
cL.TextSize = 11
cL.TextXAlignment = Enum.TextXAlignment.Left
cL.TextTruncate = Enum.TextTruncate.AtEnd
cL.Parent = CT
Instance.new("UICorner",cL).CornerRadius = UDim.new(0,8)

local sL = Instance.new("TextLabel")
sL.Size = UDim2.new(1,-130,0,16)
sL.Position = UDim2.new(0,6,0,44)
sL.BackgroundTransparency = 1
sL.Text = "🐽 Ready."
sL.TextColor3 = PX
sL.Font = Enum.Font.SourceSans
sL.TextSize = 11
sL.TextXAlignment = Enum.TextXAlignment.Left
sL.TextTruncate = Enum.TextTruncate.AtEnd
sL.Parent = CT

local lgB = Instance.new("TextButton")
lgB.Size = UDim2.new(0,70,0,16)
lgB.Position = UDim2.new(1,-126,0,44)
lgB.BackgroundColor3 = BL
lgB.Text = "📋 LOG"
lgB.TextColor3 = W
lgB.Font = Enum.Font.SourceSansBold
lgB.TextSize = 10
lgB.BorderSizePixel = 0
lgB.Parent = CT
Instance.new("UICorner",lgB).CornerRadius = UDim.new(0,6)

local clB = Instance.new("TextButton")
clB.Size = UDim2.new(0,50,0,16)
clB.Position = UDim2.new(1,-52,0,44)
clB.BackgroundColor3 = R
clB.Text = "🗑️ CLR"
clB.TextColor3 = W
clB.Font = Enum.Font.SourceSansBold
clB.TextSize = 10
clB.BorderSizePixel = 0
clB.Parent = CT
Instance.new("UICorner",clB).CornerRadius = UDim.new(0,6)

-- Row 64
local HB = Instance.new("TextButton")
HB.Size = UDim2.new(0,100,0,30)
HB.Position = UDim2.new(0,6,0,64)
HB.BackgroundColor3 = PX
HB.Text = "小女孩"
HB.TextColor3 = W
HB.Font = Enum.Font.SourceSansBold
HB.TextSize = 13
HB.BorderSizePixel = 0
HB.Parent = CT
Instance.new("UICorner",HB).CornerRadius = UDim.new(0,10)

local AIB = Instance.new("TextButton")
AIB.Size = UDim2.new(0,100,0,30)
AIB.Position = UDim2.new(0,112,0,64)
AIB.BackgroundColor3 = P
AIB.Text = "🤖 AI"
AIB.TextColor3 = W
AIB.Font = Enum.Font.SourceSansBold
AIB.TextSize = 13
AIB.BorderSizePixel = 0
AIB.Parent = CT
Instance.new("UICorner",AIB).CornerRadius = UDim.new(0,10)

local AUB = Instance.new("TextButton")
AUB.Size = UDim2.new(0,126,0,30)
AUB.Position = UDim2.new(0,218,0,64)
AUB.BackgroundColor3 = GA
AUB.Text = "▶ AUTO"
AUB.TextColor3 = W
AUB.Font = Enum.Font.SourceSansBold
AUB.TextSize = 13
AUB.BorderSizePixel = 0
AUB.Parent = CT
Instance.new("UICorner",AUB).CornerRadius = UDim.new(0,10)

-- Model row
local mLab = Instance.new("TextLabel")
mLab.Size = UDim2.new(0,40,0,14)
mLab.Position = UDim2.new(0,6,0,98)
mLab.BackgroundTransparency = 1
mLab.Text = "Model:"
mLab.TextColor3 = P
mLab.Font = Enum.Font.SourceSansBold
mLab.TextSize = 10
mLab.TextXAlignment = Enum.TextXAlignment.Left
mLab.Parent = CT

local MPr = Instance.new("TextButton")
MPr.Size = UDim2.new(0,22,0,18)
MPr.Position = UDim2.new(0,46,0,96)
MPr.BackgroundColor3 = P
MPr.Text = "◀"
MPr.TextColor3 = W
MPr.Font = Enum.Font.SourceSansBold
MPr.TextSize = 11
MPr.BorderSizePixel = 0
MPr.Parent = CT
Instance.new("UICorner",MPr).CornerRadius = UDim.new(0,5)

local MDis = Instance.new("TextButton")
MDis.Size = UDim2.new(0,110,0,18)
MDis.Position = UDim2.new(0,70,0,96)
MDis.BackgroundColor3 = P
MDis.Text = MODELS[1].label
MDis.TextColor3 = W
MDis.Font = Enum.Font.SourceSansBold
MDis.TextSize = 10
MDis.BorderSizePixel = 0
MDis.Parent = CT
Instance.new("UICorner",MDis).CornerRadius = UDim.new(0,5)

local MNx = Instance.new("TextButton")
MNx.Size = UDim2.new(0,22,0,18)
MNx.Position = UDim2.new(0,182,0,96)
MNx.BackgroundColor3 = P
MNx.Text = "▶"
MNx.TextColor3 = W
MNx.Font = Enum.Font.SourceSansBold
MNx.TextSize = 11
MNx.BorderSizePixel = 0
MNx.Parent = CT
Instance.new("UICorner",MNx).CornerRadius = UDim.new(0,5)

local KB = Instance.new("TextButton")
KB.Size = UDim2.new(0,132,0,18)
KB.Position = UDim2.new(0,210,0,96)
KB.BackgroundColor3 = BK
KB.Text = "🔑 K1/9"
KB.TextColor3 = W
KB.Font = Enum.Font.Code
KB.TextSize = 10
KB.BorderSizePixel = 0
KB.Parent = CT
Instance.new("UICorner",KB).CornerRadius = UDim.new(0,5)

-- Paste
local plL = Instance.new("TextLabel")
plL.Size = UDim2.new(1,-12,0,14)
plL.Position = UDim2.new(0,6,0,118)
plL.BackgroundTransparency = 1
plL.Text = "Paste Gemini JSON:"
plL.TextColor3 = PX
plL.Font = Enum.Font.SourceSans
plL.TextSize = 11
plL.TextXAlignment = Enum.TextXAlignment.Left
plL.Parent = CT

local PB = Instance.new("TextBox")
PB.Size = UDim2.new(1,-12,0,40)
PB.Position = UDim2.new(0,6,0,134)
PB.BackgroundColor3 = PF
PB.TextColor3 = PX
PB.PlaceholderText = '{"pick":{"title":"..."}}'
PB.Text = ""
PB.Font = Enum.Font.Code
PB.TextSize = 10
PB.TextXAlignment = Enum.TextXAlignment.Left
PB.TextYAlignment = Enum.TextYAlignment.Top
PB.TextWrapped = true
PB.MultiLine = true
PB.ClearTextOnFocus = false
PB.BorderSizePixel = 0
PB.Parent = CT
Instance.new("UICorner",PB).CornerRadius = UDim.new(0,10)

local pBtn = Instance.new("TextButton")
pBtn.Size = UDim2.new(0,110,0,28)
pBtn.Position = UDim2.new(0,6,0,178)
pBtn.BackgroundColor3 = PD
pBtn.Text = "777"
pBtn.TextColor3 = W
pBtn.Font = Enum.Font.SourceSansBold
pBtn.TextSize = 12
pBtn.BorderSizePixel = 0
pBtn.Parent = CT
Instance.new("UICorner",pBtn).CornerRadius = UDim.new(0,10)

local cjB = Instance.new("TextButton")
cjB.Size = UDim2.new(0,110,0,28)
cjB.Position = UDim2.new(0,120,0,178)
cjB.BackgroundColor3 = R
cjB.Text = "CLEAR"
cjB.TextColor3 = W
cjB.Font = Enum.Font.SourceSansBold
cjB.TextSize = 12
cjB.BorderSizePixel = 0
cjB.Parent = CT
Instance.new("UICorner",cjB).CornerRadius = UDim.new(0,10)

local gB = Instance.new("TextButton")
gB.Size = UDim2.new(0,114,0,28)
gB.Position = UDim2.new(0,234,0,178)
gB.BackgroundColor3 = G
gB.Text = "GO 🐽"
gB.TextColor3 = W
gB.Font = Enum.Font.SourceSansBold
gB.TextSize = 12
gB.BorderSizePixel = 0
gB.Parent = CT
Instance.new("UICorner",gB).CornerRadius = UDim.new(0,10)

local SC = Instance.new("ScrollingFrame")
SC.Size = UDim2.new(1,-12,1,-214)
SC.Position = UDim2.new(0,6,0,214)
SC.BackgroundColor3 = PF
SC.BorderSizePixel = 0
SC.ScrollBarThickness = 4
SC.AutomaticCanvasSize = Enum.AutomaticSize.Y
SC.CanvasSize = UDim2.new(0,0,0,0)
SC.Parent = CT
Instance.new("UICorner",SC).CornerRadius = UDim.new(0,10)
Instance.new("UIListLayout",SC).Padding = UDim.new(0,2)

local function addL(text, color)
    table.insert(LOG, text)
    if #LOG > 500 then table.remove(LOG, 1) end
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,-4,0,12)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or PX
    l.Font = Enum.Font.Code
    l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextTruncate = Enum.TextTruncate.AtEnd
    l.Parent = SC
    task.defer(function() pcall(function() SC.CanvasPosition = Vector2.new(0, SC.AbsoluteCanvasSize.Y) end) end)
end

local function updM()
    MDis.Text = MODELS[cMI].label
    KB.Text = "🔑 K" .. cKI .. "/" .. #API_KEYS
end

MPr.MouseButton1Click:Connect(function()
    cMI = cMI - 1
    if cMI < 1 then cMI = #MODELS end
    updM()
end)
MNx.MouseButton1Click:Connect(function()
    cMI = cMI + 1
    if cMI > #MODELS then cMI = 1 end
    updM()
end)
KB.MouseButton1Click:Connect(function()
    deadK, deadM, wMI = {}, {}, nil
    cKI = 1
    updM()
    addL("[RESET] all keys+models 🐽", G)
end)

-- ==================== SCAN BLUE ====================
local function scanBlue()
    local items, seen = {}, {}
    for _,o in ipairs(PG:GetDescendants()) do
        if not o:IsDescendantOf(gui) then
            if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
                local vis = true
                local p = o
                while p and p ~= PG do
                    if p:IsA("GuiObject") and not p.Visible then vis = false; break end
                    p = p.Parent
                end
                if vis then
                    local text = o.Text or ""
                    if text ~= "" then
                        local blue = isBlue(o.TextColor3)
                        if not blue and o.RichText then
                            for hex in text:gmatch('<font color="#(%x%x%x%x%x%x)"') do
                                local r = tonumber(hex:sub(1,2),16)
                                local g = tonumber(hex:sub(3,4),16)
                                local b = tonumber(hex:sub(5,6),16)
                                if isBlue(Color3.fromRGB(r,g,b)) then blue = true; break end
                            end
                        end
                        if blue then
                            local d = text:gsub("<[^>]+>",""):gsub("^%s+",""):gsub("%s+$","")
                            if #d > 0 and not isJunk(d) then
                                local k = d:lower()
                                if not seen[k] then
                                    seen[k] = true
                                    local pos = o.AbsolutePosition
                                    table.insert(items, {text=d, x=pos and pos.X or 0, y=pos and pos.Y or 0, w=o.AbsoluteSize and o.AbsoluteSize.X or 0})
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    table.sort(items, function(a,b)
        if math.abs(a.y-b.y) > 6 then return a.y < b.y end
        return a.x < b.x
    end)
    local merged, cur = {}, nil
    for _,it in ipairs(items) do
        if not cur then
            cur = {text=it.text, x=it.x, y=it.y, endX=it.x+it.w}
        else
            local same = math.abs(it.y - cur.y) <= 6
            local gap = it.x - cur.endX
            if same and gap < 25 and gap > -10 then
                local sp = true
                if cur.text:sub(-1) == " " or it.text:sub(1,1) == " " then sp = false end
                if gap <= 0.5 then sp = false end
                local lc = cur.text:sub(-1)
                if lc == "-" or lc == "'" or lc == "/" or lc == "." then sp = false end
                local fc = it.text:sub(1,1)
                if fc == "," or fc == "." or fc == ")" or fc == "!" or fc == "?" or fc == ":" or fc == ";" then sp = false end
                if sp then cur.text = cur.text .. " " .. it.text else cur.text = cur.text .. it.text end
                cur.endX = it.x + it.w
            else
                table.insert(merged, cur.text)
                cur = {text=it.text, x=it.x, y=it.y, endX=it.x+it.w}
            end
        end
    end
    if cur then table.insert(merged, cur.text) end
    local seen2, res = {}, {}
    for _,w in ipairs(merged) do
        w = w:gsub("^%s+",""):gsub("%s+$",""):gsub("%s+"," ")
        if isEN(w) and not isJunk(w) then
            local k = w:lower()
            if not seen2[k] then seen2[k] = true; table.insert(res, w) end
        end
    end
    return res
end

local function updLbl()
    iL.Text = "T: " .. (tTitle or "?")
    local c = cArt or "?"
    if cArtId then c = c .. " [" .. cArtId .. "]" end
    cL.Text = "C: " .. c
end

local function refresh()
    if cArt and cArtId then return false end
    local u = getURL()
    if u and (not cArt or cArt ~= u) then
        cArt = u
        markV(u)
        updLbl()
        return true
    end
    return false
end

local function getCands()
    if not cArt then return {} end
    local n = norm(cArt)
    local cands, seen = {}, {}
    local function addLst(l)
        for _,c in ipairs(l) do
            if c and c ~= "" then
                local k = c:lower()
                if not seen[k] then seen[k] = true; table.insert(cands, c) end
            end
        end
    end
    addLst(gCache[n] or {})
    local sc = scanBlue()
    addLst(sc)
    addLst(bwCache[n] or {})
    if #sc > 0 then bwCache[n] = sc end
    local f = {}
    for _,c in ipairs(cands) do
        if isEN(c) and not isJunk(c) and not isV(c) then table.insert(f, c) end
    end
    if #f > 60 then
        local cap = {}
        for i = 1, 60 do cap[i] = f[i] end
        f = cap
    end
    return f
end

-- ==================== NAVIGATE ====================
local function tryClick(t)
    if not t then return false end
    local tS = supN(t)
    if #tS < 2 then return false end
    local found = {}
    for _,o in ipairs(PG:GetDescendants()) do
        if not o:IsDescendantOf(gui) then
            if o:IsA("TextButton") or o:IsA("TextLabel") then
                local text = o.Text or ""
                if text ~= "" and not isJunk(text) then
                    local d = text:gsub("<[^>]+>",""):gsub("^%s+",""):gsub("%s+$","")
                    local dS = supN(d)
                    local sc = 0
                    if dS == tS then sc = 100
                    elseif d:lower() == t:lower() then sc = 90
                    elseif #tS >= 3 and dS:find(tS,1,true) then sc = 80
                    elseif #dS >= 3 and tS:find(dS,1,true) then sc = 70
                    end
                    if sc > 0 then
                        if isBlue(o.TextColor3) then sc = sc + 20 end
                        if o:IsA("TextButton") then sc = sc + 10 end
                        table.insert(found, {obj=o, score=sc})
                    end
                end
            end
        end
    end
    if #found == 0 then return false end
    table.sort(found, function(a,b) return a.score > b.score end)
    for i = 1, math.min(5, #found) do
        local t = found[i].obj
        if t:IsA("TextLabel") then
            local p = t.Parent
            while p and p ~= PG do
                if p:IsA("TextButton") then t = p; break end
                p = p.Parent
            end
        end
        local ok = false
        pcall(function() if t.Activate then t:Activate(); ok = true end end)
        if not ok then pcall(function() if t.MouseButton1Click then t.MouseButton1Click:Fire(); ok = true end end) end
        if not ok then
            pcall(function()
                if t.MouseButton1Down then t.MouseButton1Down:Fire() end
                if t.MouseButton1Up then t.MouseButton1Up:Fire() end
                ok = true
            end)
        end
        if ok then return true end
    end
    return false
end

local function navTo(title)
    if not title then return false end
    if not cArt or not cArtId then return false end
    if norm(title):lower() == norm(cArt):lower() then return false end
    local nt = norm(title)
    local tid, mt = nil, ""
    tid = linkMap[nt]
    if tid then mt = "exact" end
    if not tid then
        local lt = nt:lower()
        for k,v in pairs(linkMap) do
            if k:lower() == lt then tid = v; mt = "ci"; break end
        end
    end
    if not tid then
        local ts = supN(nt)
        if #ts >= 3 then
            for k,v in pairs(linkMap) do
                if supN(k) == ts then tid = v; mt = "sup"; break end
            end
        end
    end
    if not tid then
        local lt = nt:lower()
        if #lt >= 5 then
            for k,v in pairs(linkMap) do
                local lk = k:lower()
                if lk:find(lt,1,true) or lt:find(lk,1,true) then tid = v; mt = "sub"; break end
            end
        end
    end
    if not tid then
        if tryClick(title) then markV(title); return true end
        return false
    end
    clickN = clickN + 1
    local tag = mt ~= "exact" and (" [" .. mt .. "]") or ""
    addL("[GO] " .. title .. " (id=" .. tid .. ")" .. tag, G)
    pcall(function() Nav:FireServer(cArtId, tid, clickN) end)
    markV(title)
    return true
end

-- ==================== PARSE ====================
local function normPicks(data)
    local out = {}
    if type(data) ~= "table" then return out end
    local function push(e, dr)
        if type(e) == "string" then table.insert(out, {rank=dr or 99, title=e}); return end
        if type(e) ~= "table" then return end
        local t = e.title or e.Title or e.name
        if not t or t == "" then return end
        table.insert(out, {rank=tonumber(e.rank) or dr or 99, title=tostring(t)})
    end
    if type(data.picks) == "table" then
        for i,p in ipairs(data.picks) do push(p, i) end
    end
    if data.pick ~= nil then push(data.pick, 1) end
    if #out == 0 and type(data.title) == "string" then push({title=data.title}, 1) end
    table.sort(out, function(a,b) return (a.rank or 99) < (b.rank or 99) end)
    local seen, ded = {}, {}
    for _,p in ipairs(out) do
        local k = p.title:lower()
        if not seen[k] then seen[k] = true; table.insert(ded, p) end
    end
    return ded
end

local function parseJSON(text)
    if not text or text == "" then return nil end
    text = text:gsub("^%s+",""):gsub("%s+$",""):gsub("```%w*",""):gsub("```",""):gsub("^%s+",""):gsub("%s+$","")
    local first = text:find("{")
    if first then
        local att = {text}
        local dep, lo = 0, nil
        for i = first, #text do
            local c = text:sub(i,i)
            if c == "{" then
                dep = dep + 1
                if dep == 1 then lo = i end
            elseif c == "}" then
                dep = dep - 1
                if dep == 0 and lo then table.insert(att, text:sub(lo, i)); break end
            end
        end
        for _,c in ipairs(att) do
            local ok, d = pcall(function() return HS:JSONDecode(c) end)
            if ok and type(d) == "table" then
                if d.picks or d.pick or d.title then
                    local p = normPicks(d)
                    if #p > 0 then return {picks=p, _raw=d} end
                end
            end
        end
    end
    local mp = {}
    for b in text:gmatch("%*%*(.-)%*%*") do
        b = b:gsub("^%s+",""):gsub("%s+$","")
        if #b >= 2 and #b <= 80 and isEN(b) then
            local f = false
            for _,e in ipairs(mp) do if e:lower() == b:lower() then f = true; break end end
            if not f then table.insert(mp, b) end
        end
    end
    if #mp > 0 then
        local pk = {}
        for i,t in ipairs(mp) do table.insert(pk, {rank=i, title=t}) end
        return {picks=pk, _raw={markdown=true}}
    end
    local ls = {}
    for line in text:gmatch("[^\r\n]+") do
        line = line:gsub("^%s+",""):gsub("%s+$","")
        if line ~= "" and not line:match("^%d+%.%s*$") then
            line = line:gsub("^%d+%.%s*",""):gsub("^[-%*]%s*","")
            if line ~= "" and isEN(line) then table.insert(ls, line) end
        end
    end
    if #ls >= 1 then
        local pk = {}
        for i,t in ipairs(ls) do table.insert(pk, {rank=i, title=t}) end
        return {picks=pk, _raw={plain=true}}
    end
    return nil
end

-- ==================== DO-GO ====================
local function doGo()
    if not cArt then refresh() end
    if cArt then
        local n = norm(cArt)
        bwCache[n] = nil
        gCache[n] = nil
        scanBlue()
    end
    local text = PB.Text or ""
    if text == "" then addL("[X] paste box empty", R); return false end
    local data = parseJSON(text)
    if not data or not data.picks or #data.picks == 0 then
        addL("[X] parse failed", R); return false
    end
    addL("[ok] " .. #data.picks .. " picks", G)
    for i = 1, math.min(1, #data.picks) do
        local p = data.picks[i]
        local t = p.title or ""
        addL("  #" .. i .. ": " .. t, PX)
        if navTo(t) then return true end
    end
    return false
end

-- ==================== PROMPT ====================
local function buildPrompt(cands)
    local lines = {}
    for i = 1, math.min(CFG.max_cand, #cands) do
        table.insert(lines, i .. ". " .. cands[i])
    end
    return string.format([[# ROLE
You are a WikiRace pathfinder AI. Guide the player from CURRENT to TARGET by picking the SINGLE BEST next article.

# GAME CONTEXT
- WikiRace: start at CURRENT, reach TARGET by clicking blue links in Wikipedia
- Goal: reach TARGET in FEWEST clicks
- CURRENT: %s
- TARGET:  %s

# AVAILABLE LINKS
%s

# YOUR TASK
Pick the ONE BEST link that will bring the player CLOSEST to TARGET.

# STRATEGY
- Think: "Which link leads toward TARGET fastest?"
- Prefer broad/hub topics (countries, sciences, time periods)
- Avoid narrow/local topics unless directly related to TARGET
- Avoid CURRENT itself

# OUTPUT (STRICT JSON)
Return ONLY this JSON. No markdown, no explanation, no code fences.

{
  "picks": [
    {"rank": 1, "title": "EXACT name from list", "why": "short reason"}
  ]
}

# RULES
1. "title" MUST match an item in the list EXACTLY
2. Return EXACTLY 1 pick (rank 1 only)
3. Do NOT invent titles not in the list
4. Do NOT add text outside the JSON

Output JSON now:]], cArt or "?", tTitle or "?", table.concat(lines, "\n"))
end

-- ==================== CALL API ====================
local function callGroq(kIdx, model, prompt)
    local http = gHTTP()
    if not http then return nil, "no HTTP" end
    local key = API_KEYS[kIdx]
    if not key then return nil, "no key" end
    local body = HS:JSONEncode({
        model = model,
        messages = {
            {role = "system", content = "You are a JSON-only assistant. Return valid JSON."},
            {role = "user", content = prompt},
        },
        temperature = CFG.temp,
        max_tokens = CFG.max_tok,
        response_format = {type = "json_object"},
    })
    local ok, res = pcall(function()
        return http({
            Url = URL,
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
    local pOk, pd = pcall(function() return HS:JSONDecode(res.Body) end)
    if not pOk or not pd then return nil, "bad JSON" end
    if not pd.choices or not pd.choices[1] then return nil, "no choices" end
    local msg = pd.choices[1].message
    if not msg or not msg.content then return nil, "no content" end
    return msg.content, nil
end

-- ==================== ASK + ROTATION ====================
local function askGroq()
    if not cArt then refresh() end
    if not cArt then return nil, "no current" end
    if not tTitle then return nil, "no target" end
    local cands = getCands()
    if #cands == 0 then return nil, "no candidates" end
    local prompt = buildPrompt(cands)

    -- priority: [working] + [current onward, not dead]
    local mOrder = {}
    if wMI and not deadM[wMI] then table.insert(mOrder, wMI) end
    for mOff = 0, #MODELS - 1 do
        local mIdx = ((cMI - 1 + mOff) % #MODELS) + 1
        if not deadM[mIdx] and mIdx ~= wMI then table.insert(mOrder, mIdx) end
    end

    for kOff = 0, #API_KEYS - 1 do
        local kIdx = ((cKI - 1 + kOff) % #API_KEYS) + 1
        if not deadK[kIdx] then
            for _, mIdx in ipairs(mOrder) do
                local model = MODELS[mIdx].id
                local label = MODELS[mIdx].label
                addL("[AI] K" .. kIdx .. " × " .. label, P)

                local t0 = tick()
                local ans, err = callGroq(kIdx, model, prompt)
                local dt = tick() - t0

                if ans then
                    cKI = kIdx
                    cMI = mIdx
                    wMI = mIdx
                    updM()
                    addL("[AI] ✓ " .. string.format("%.1f", dt) .. "s", G)
                    return ans, nil
                else
                    if tostring(err):find("404") then
                        deadM[mIdx] = true
                        addL("[AI] ✗ " .. label .. " 404 💀", GY)
                    elseif tostring(err):find("401") or tostring(err):find("403") then
                        deadK[kIdx] = true
                        addL("[KEY] K" .. kIdx .. " ใช้ไม่ได้ 💀", R)
                        break
                    elseif tostring(err):find("429") then
                        addL("[AI] ✗ " .. label .. " 429", O)
                    else
                        addL("[AI] ✗ " .. tostring(err), O)
                    end
                end
                task.wait(0.1)
            end
        end
    end
    deadK, deadM, wMI = {}, {}, nil
    return nil, "all keys+models failed"
end

local function askAndGo()
    local ans, err = askGroq()
    if not ans then
        addL("[X] " .. tostring(err), R)
        sL.Text = "❌ " .. tostring(err)
        return false
    end
    PB.Text = ans
    return doGo()
end

-- ==================== AUTO ====================
local function runAuto()
    if isAuto then
        isAuto = false
        AUB.Text = "▶ AUTO"
        AUB.BackgroundColor3 = GA
        addL("[AUTO] ⏸ หยุด", GR)
        return
    end
    if not tTitle then
        addL("[AUTO] ❌ no target", R)
        return
    end
    isAuto = true
    AUB.Text = "⏸ STOP"
    AUB.BackgroundColor3 = GR

    task.spawn(function()
        local loopN, errN = 0, 0
        while isAuto and loopN < AUTO.max do
            loopN = loopN + 1
            refresh()
            if cArt and norm(cArt):lower() == norm(tTitle):lower() then
                addL("🎉 ถึง TARGET! (" .. loopN .. " ครั้ง)", G)
                sL.Text = "🎉 Target reached!"
                pcall(function()
                    local s = Instance.new("Sound")
                    s.SoundId = "rbxassetid://9114221327"
                    s.Volume = 0.5
                    s.Parent = game:GetService("SoundService")
                    s:Play()
                end)
                break
            end
            sL.Text = "▶ AUTO #" .. loopN .. "/" .. AUTO.max
            addL("[AUTO] #" .. loopN .. " C=" .. (cArt or "?") .. " T=" .. tTitle, P)

            local ok = askAndGo()
            if not ok then
                errN = errN + 1
                if errN >= AUTO.maxErr then
                    addL("[AUTO] error " .. AUTO.maxErr .. " ครั้งติด → หยุด", R)
                    break
                end
            else
                errN = 0
            end
            task.wait(AUTO.wait)
        end
        isAuto = false
        AUB.Text = "▶ AUTO"
        AUB.BackgroundColor3 = GA
        sL.Text = "🐽 Ready."
    end)
end

-- ==================== EVENTS ====================
local guiV = true
MB.MouseButton1Click:Connect(function()
    if CT.Visible then
        CT.Visible = false
        F.Size = UDim2.new(0,350,0,28)
        MB.Text = "+"
    else
        CT.Visible = true
        F.Size = UDim2.new(0,350,0,360)
        MB.Text = "-"
    end
end)
CB.MouseButton1Click:Connect(function() guiV = not guiV; F.Visible = guiV end)
UIS.InputBegan:Connect(function(i,g) if g then return end
    if i.KeyCode == Enum.KeyCode.RightShift then guiV = not guiV; F.Visible = guiV end
end)

ctB.MouseButton1Click:Connect(function()
    if not tTitle then return end
    local s = tostring(tTitle):gsub("\\","\\\\"):gsub('"','\\"')
    clip('{\n"picks": [\n{"rank": 1, "title": "' .. s .. '"}\n]\n}')
    addL("[target] copied", G)
end)

lgB.MouseButton1Click:Connect(function()
    if #LOG == 0 then addL("[LOG] empty", O); return end
    local txt = table.concat(LOG, "\n")
    local ok = clip(txt)
    addL("[LOG] copied " .. #LOG .. " lines (" .. #txt .. " chars)", ok and G or R)
    sL.Text = ok and "📋 Log copied!" or "❌ Copy failed"
end)

clB.MouseButton1Click:Connect(function()
    LOG = {}
    for _,c in ipairs(SC:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    addL("[LOG] cleared", G)
end)

HB.MouseButton1Click:Connect(function()
    if not cArt then refresh() end
    if not cArt then return end
    local cands = getCands()
    if #cands == 0 then addL("[X] no candidates", R); return end
    local ls = {"CURRENT: " .. cArt, "TARGET: " .. (tTitle or "?"), "", "CANDIDATES:"}
    for i,c in ipairs(cands) do table.insert(ls, i .. ". " .. c) end
    clip(table.concat(ls, "\n"))
    addL("[HOP] " .. #cands .. " cand copied", G)
end)

AIB.MouseButton1Click:Connect(function()
    if isProc or isAuto then return end
    isProc = true
    task.spawn(function() pcall(askAndGo); isProc = false end)
end)

AUB.MouseButton1Click:Connect(runAuto)

pBtn.MouseButton1Click:Connect(function()
    if isProc or isAuto then return end
    isProc = true
    local txt = gClip()
    if txt and #txt > 0 then
        PB.Text = txt
        task.wait(0.1)
        doGo()
    end
    isProc = false
end)

cjB.MouseButton1Click:Connect(function() PB.Text = "" end)

gB.MouseButton1Click:Connect(function()
    if isProc or isAuto then return end
    isProc = true
    doGo()
    isProc = false
end)

UIS.InputBegan:Connect(function(i,g) if g then return end
    if i.KeyCode == Enum.KeyCode.One and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
        if not isProc and not isAuto then
            isProc = true
            task.spawn(function() pcall(askAndGo); isProc = false end)
        end
    end
    if i.KeyCode == Enum.KeyCode.Two and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
        runAuto()
    end
end)

-- ==================== HOOKS ====================
local aU = Remotes:FindFirstChild("ArticleUpdated")
if aU then
    aU.OnClientEvent:Connect(function(p)
        if type(p) ~= "table" then return end
        local a = p.Article
        if type(a) ~= "table" or not a.Title then return end
        local t = norm(a.Title)
        markV(t)
        cArt = t
        if a.Id then cArtId = tostring(a.Id) end
        linkMap = {}
        if type(a.Links) == "table" then
            for _,v in pairs(a.Links) do
                if type(v) == "table" and v.Title and v.Id then
                    linkMap[norm(v.Title)] = tostring(v.Id)
                end
            end
        end
        local ls = {}
        if type(a.Links) == "table" then
            for _,v in pairs(a.Links) do
                if type(v) == "table" and v.Title then
                    local n = norm(v.Title)
                    if isEN(n) and not isJunk(n) then table.insert(ls, n) end
                end
            end
        end
        gCache[t] = ls
        updLbl()
        addL("[page] " .. t .. " (" .. #ls .. " links)", PD)
    end)
end

local rS = Remotes:FindFirstChild("RoundStarted")
if rS then
    rS.OnClientEvent:Connect(function(p)
        if type(p) ~= "table" then return end
        if p.StartArticle and p.StartArticle.Title then
            vSet = {}
            markV(norm(p.StartArticle.Title))
        end
        if p.TargetArticle and p.TargetArticle.Title then
            tTitle = norm(p.TargetArticle.Title)
        end
        clickN = 0
        updLbl()
    end)
end

local rSC = Remotes:FindFirstChild("RoundStateChanged")
if rSC then
    rSC.OnClientEvent:Connect(function(p)
        if type(p) ~= "table" then return end
        if p.StartTitle then markV(norm(p.StartTitle)) end
        if p.TargetTitle then tTitle = norm(p.TargetTitle) end
        updLbl()
    end)
end

-- ==================== INIT ====================
updM()
addL("🐷 v9.6 ready", G)
addL("9 keys | compound only | Rank1", PD)
addL("小女孩 | 🤖 | ▶ AUTO", PD)
sL.Text = "🐽 Ready."
updLbl()
print("[ATLAS v9.6 🐷 Groq 9-Keys] Loaded ✓")
