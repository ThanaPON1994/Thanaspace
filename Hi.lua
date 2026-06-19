-- =====================================================================
-- 🎨 DRAW AI V14.6 ULTIMATE — University Mode (Skip 1-35) + LV 1-25
-- 🔥 Fix: Expanded Skip Count (1-35), Massive Read Buffer for Perfect Draws
-- 🔥 New: LV 1-25 (เข้มงวดขึ้นตาม Level), Animal Auto Size 100%
-- =====================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
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
local autoSizeEnabled = false
local skipCount = 5 -- ค่าเริ่มต้น
local currentLV = 1 -- ✅ LV 1-25 (ค่าเริ่มต้น = 1)

-- ========== CACHE ==========
if not getgenv().QuickDrawCache then getgenv().QuickDrawCache = {} end
if not getgenv().QuickDrawLoading then getgenv().QuickDrawLoading = {} end
local apiCache = getgenv().QuickDrawCache
local isLoading = getgenv().QuickDrawLoading

-- ========== THEME MAPPING ==========
local themeMapping = {
    ["t-shirt"] = "t-shirt", ["t shirt"] = "t-shirt", ["t_shirt"] = "t-shirt", ["tshirt"] = "t-shirt",
    ["hot dog"] = "hot dog", ["hotdog"] = "hot dog", ["hot_dog"] = "hot dog",
    ["traffic light"] = "traffic light", ["traffic_light"] = "traffic light",
    ["palm tree"] = "palm tree", ["palm_tree"] = "palm tree", ["palmtree"] = "palm tree",
    ["house plant"] = "house plant", ["house_plant"] = "house plant", ["houseplant"] = "house plant",
    ["cell phone"] = "cell phone", ["cell_phone"] = "cell phone", ["cellphone"] = "cell phone",
    ["birthday cake"] = "birthday cake", ["birthday_cake"] = "birthday cake", ["birthdaycake"] = "birthday cake",
    ["flying saucer"] = "flying saucer", ["flying_saucer"] = "flying saucer", ["flyingsaucer"] = "flying saucer", ["ufo"] = "flying saucer",
    ["soccer ball"] = "soccer ball", ["soccer_ball"] = "soccer ball", ["soccerball"] = "soccer ball",
    ["tennis racquet"] = "tennis racquet", ["tennis_racquet"] = "tennis racquet", ["tennisracquet"] = "tennis racquet",
    ["baseball bat"] = "baseball bat", ["baseball_bat"] = "baseball bat", ["baseballbat"] = "baseball bat",
    ["aircraft carrier"] = "aircraft carrier", ["aircraft_carrier"] = "aircraft carrier", ["aircraftcarrier"] = "aircraft carrier",
    ["hot air balloon"] = "hot air balloon", ["hot_air_balloon"] = "hot air balloon", ["hotairballoon"] = "hot air balloon",
    ["paper clip"] = "paper clip", ["paper_clip"] = "paper clip", ["paperclip"] = "paper clip",
    ["paint can"] = "paint can", ["paint_can"] = "paint can", ["paintcan"] = "paint can",
    ["floor lamp"] = "floor lamp", ["floor_lamp"] = "floor lamp", ["floorlamp"] = "floor lamp",
    ["fire hydrant"] = "fire hydrant", ["fire_hydrant"] = "fire hydrant", ["firehydrant"] = "fire hydrant",
    ["fire truck"] = "firetruck", ["firetruck"] = "firetruck", ["fire_truck"] = "firetruck",
    ["wine bottle"] = "wine bottle", ["wine_bottle"] = "wine bottle", ["winebottle"] = "wine bottle",
    ["wine glass"] = "wine glass", ["wine_glass"] = "wine glass", ["wineglass"] = "wine glass",
    ["swing set"] = "swing set", ["swing_set"] = "swing set", ["swingset"] = "swing set",
    ["sleeping bag"] = "sleeping bag", ["sleeping_bag"] = "sleeping bag", ["sleepingbag"] = "sleeping bag",
    ["smiley face"] = "smiley face", ["smiley_face"] = "smiley face", ["smileyface"] = "smiley face", ["smile"] = "smiley face",
    ["speed boat"] = "speedboat", ["speedboat"] = "speedboat", ["speed_boat"] = "speedboat",
    ["power outlet"] = "power outlet", ["power_outlet"] = "power outlet", ["poweroutlet"] = "power outlet", ["outlet"] = "power outlet",
    ["remote control"] = "remote control", ["remote_control"] = "remote control", ["remotecontrol"] = "remote control", ["remote"] = "remote control",
    ["roller coaster"] = "roller coaster", ["roller_coaster"] = "roller coaster", ["rollercoaster"] = "roller coaster",
    ["school bus"] = "school bus", ["school_bus"] = "school bus", ["schoolbus"] = "school bus",
    ["see saw"] = "see saw", ["see_saw"] = "see saw", ["seesaw"] = "see saw",
    ["sea turtle"] = "sea turtle", ["sea_turtle"] = "sea turtle", ["seaturtle"] = "sea turtle",
    ["teddy bear"] = "teddy-bear", ["teddy_bear"] = "teddy-bear", ["teddybear"] = "teddy-bear", ["bear"] = "teddy-bear",
    ["washing machine"] = "washing machine", ["washing_machine"] = "washing machine", ["washingmachine"] = "washing machine",
    ["watermelon"] = "watermelon", ["water_melon"] = "watermelon",
    ["waterslide"] = "waterslide", ["water_slide"] = "waterslide",
    ["diving board"] = "diving board", ["diving_board"] = "diving board",
    ["light bulb"] = "light bulb", ["light_bulb"] = "light bulb", ["lightbulb"] = "light bulb",
    ["alarm clock"] = "alarm clock", ["alarm_clock"] = "alarm clock",
    ["ceiling fan"] = "ceiling fan", ["ceiling_fan"] = "ceiling fan",
    ["coffee cup"] = "coffee cup", ["coffee_cup"] = "coffee cup",
    ["cruise ship"] = "cruise ship", ["cruise_ship"] = "cruise ship",
    ["donut"] = "donut", ["doughnut"] = "donut",
    ["drums"] = "drums", ["drum"] = "drums",
    ["flip flops"] = "flip flops", ["flip_flops"] = "flip flops",
    ["frying pan"] = "frying pan", ["frying_pan"] = "frying pan",
    ["garden hose"] = "garden hose", ["garden_hose"] = "garden hose",
    ["golf club"] = "golf club", ["golf_club"] = "golf club",
    ["hockey puck"] = "hockey puck", ["hockey_puck"] = "hockey puck",
    ["hockey stick"] = "hockey stick", ["hockey_stick"] = "hockey stick",
    ["hot tub"] = "hot tub", ["hot_tub"] = "hot tub",
    ["ice cream"] = "ice cream", ["ice_cream"] = "ice cream",
    ["pickup truck"] = "pickup truck", ["pickup_truck"] = "pickup truck",
    ["picture frame"] = "picture frame", ["picture_frame"] = "picture frame",
    ["police car"] = "police car", ["police_car"] = "police car",
    ["stop sign"] = "stop sign", ["stop_sign"] = "stop sign", ["stopsign"] = "stop sign",
    ["string bean"] = "string bean", ["string_bean"] = "string bean", ["stringbean"] = "string bean",
    ["The Eiffel Tower"] = "The Eiffel Tower", ["the_eiffel_tower"] = "The Eiffel Tower", ["eiffel_tower"] = "The Eiffel Tower",
    ["The Great Wall of China"] = "The Great Wall of China", ["the_great_wall_of_china"] = "The Great Wall of China",
    ["The Mona Lisa"] = "The Mona Lisa", ["the_mona_lisa"] = "The Mona Lisa", ["mona_lisa"] = "The Mona Lisa",
    ["skateboard"] = "skateboard", ["spreadsheet"] = "spreadsheet", ["stereo"] = "stereo",
    ["stethoscope"] = "stethoscope", ["toothbrush"] = "toothbrush", ["toothpaste"] = "toothpaste",
    -- Single words
    ["ambulance"] = "ambulance", ["angel"] = "angel", ["ant"] = "ant", ["banana"] = "banana",
    ["barn"] = "barn", ["baseball"] = "baseball", ["basketball"] = "basketball", ["bathtub"] = "bathtub",
    ["beach"] = "beach", ["bear"] = "bear", ["beard"] = "beard", ["bed"] = "bed", ["bee"] = "bee",
    ["belt"] = "belt", ["bench"] = "bench", ["bicycle"] = "bicycle", ["binoculars"] = "binoculars",
    ["bluetooth"] = "bluetooth", ["bottlecap"] = "bottlecap", ["bowtie"] = "bowtie", ["bracelet"] = "bracelet",
    ["brain"] = "brain", ["bread"] = "bread", ["bridge"] = "bridge", ["broccoli"] = "broccoli",
    ["broom"] = "broom", ["bucket"] = "bucket", ["bulldozer"] = "bulldozer", ["bus"] = "bus",
    ["bush"] = "bush", ["butterfly"] = "butterfly", ["cactus"] = "cactus", ["cake"] = "cake",
    ["calculator"] = "calculator", ["calendar"] = "calendar", ["camel"] = "camel", ["camera"] = "camera",
    ["campfire"] = "campfire", ["candle"] = "candle", ["cannon"] = "cannon", ["canoe"] = "canoe",
    ["carrot"] = "carrot", ["castle"] = "castle", ["cat"] = "cat", ["chair"] = "chair",
    ["chandelier"] = "chandelier", ["church"] = "church", ["circle"] = "circle", ["clarinet"] = "clarinet",
    ["clock"] = "clock", ["cloud"] = "cloud", ["compass"] = "compass", ["computer"] = "computer",
    ["cookie"] = "cookie", ["cooler"] = "cooler", ["couch"] = "couch", ["cow"] = "cow",
    ["crab"] = "crab", ["crayon"] = "crayon", ["crocodile"] = "crocodile", ["crown"] = "crown",
    ["crow"] = "crow", ["cup"] = "cup", ["diamond"] = "diamond", ["dishwasher"] = "dishwasher",
    ["dog"] = "dog", ["dolphin"] = "dolphin", ["door"] = "door", ["dragon"] = "dragon",
    ["dresser"] = "dresser", ["drill"] = "drill", ["duck"] = "duck", ["dumbbell"] = "dumbbell",
    ["ear"] = "ear", ["elbow"] = "elbow", ["elephant"] = "elephant", ["envelope"] = "envelope",
    ["eraser"] = "eraser", ["eye"] = "eye", ["eyeglasses"] = "eyeglasses", ["face"] = "face",
    ["fan"] = "fan", ["feather"] = "feather", ["fence"] = "fence", ["finger"] = "finger",
    ["fireplace"] = "fireplace", ["fish"] = "fish", ["flamingo"] = "flamingo", ["flashlight"] = "flashlight",
    ["flower"] = "flower", ["foot"] = "foot", ["fork"] = "fork", ["frog"] = "frog",
    ["garden"] = "garden", ["giraffe"] = "giraffe", ["goatee"] = "goatee", ["grapes"] = "grapes",
    ["grass"] = "grass", ["guitar"] = "guitar", ["hamburger"] = "hamburger", ["hammer"] = "hammer",
    ["hand"] = "hand", ["harp"] = "harp", ["hat"] = "hat", ["headphones"] = "headphones",
    ["hedgehog"] = "hedgehog", ["helicopter"] = "helicopter", ["helmet"] = "helmet", ["hexagon"] = "hexagon",
    ["horse"] = "horse", ["hospital"] = "hospital", ["hourglass"] = "hourglass", ["house"] = "house",
    ["hurricane"] = "hurricane", ["jacket"] = "jacket", ["jail"] = "jail", ["kangaroo"] = "kangaroo",
    ["key"] = "key", ["keyboard"] = "keyboard", ["knee"] = "knee", ["knife"] = "knife",
    ["ladder"] = "ladder", ["lantern"] = "lantern", ["laptop"] = "laptop", ["leaf"] = "leaf",
    ["leg"] = "leg", ["lighter"] = "lighter", ["lighthouse"] = "lighthouse", ["lightning"] = "lightning",
    ["line"] = "line", ["lion"] = "lion", ["lipstick"] = "lipstick", ["lobster"] = "lobster",
    ["lollipop"] = "lollipop", ["mailbox"] = "mailbox", ["map"] = "map", ["marker"] = "marker",
    ["matches"] = "matches", ["megaphone"] = "megaphone", ["mermaid"] = "mermaid", ["microphone"] = "microphone",
    ["microwave"] = "microwave", ["monkey"] = "monkey", ["moon"] = "moon", ["mosquito"] = "mosquito",
    ["motorbike"] = "motorbike", ["mountain"] = "mountain", ["mouse"] = "mouse", ["moustache"] = "moustache",
    ["mouth"] = "mouth", ["mug"] = "mug", ["mushroom"] = "mushroom", ["nail"] = "nail",
    ["necklace"] = "necklace", ["nose"] = "nose", ["ocean"] = "ocean", ["octagon"] = "octagon",
    ["octopus"] = "octopus", ["onion"] = "onion", ["oven"] = "oven", ["owl"] = "owl",
    ["paintbrush"] = "paintbrush", ["panda"] = "panda", ["pants"] = "pants", ["parachute"] = "parachute",
    ["parrot"] = "parrot", ["passport"] = "passport", ["peanut"] = "peanut", ["pear"] = "pear",
    ["peas"] = "peas", ["pencil"] = "pencil", ["penguin"] = "penguin", ["piano"] = "piano",
    ["pig"] = "pig", ["pillow"] = "pillow", ["pineapple"] = "pineapple", ["pizza"] = "pizza",
    ["pond"] = "pond", ["pool"] = "pool", ["popsicle"] = "popsicle", ["postcard"] = "postcard",
    ["potato"] = "potato", ["purse"] = "purse", ["rabbit"] = "rabbit", ["radio"] = "radio",
    ["rain"] = "rain", ["rainbow"] = "rainbow", ["rake"] = "rake", ["rhinoceros"] = "rhinoceros",
    ["rifle"] = "rifle", ["river"] = "river", ["rollerskates"] = "rollerskates", ["sailboat"] = "sailboat",
    ["sandwich"] = "sandwich", ["saw"] = "saw", ["saxophone"] = "saxophone", ["scissors"] = "scissors",
    ["scorpion"] = "scorpion", ["screwdriver"] = "screwdriver", ["shark"] = "shark", ["sheep"] = "sheep",
    ["shoe"] = "shoe", ["shorts"] = "shorts", ["shovel"] = "shovel", ["sink"] = "sink",
    ["ski"] = "ski", ["skull"] = "skull", ["skyscraper"] = "skyscraper", ["snail"] = "snail",
    ["snake"] = "snake", ["snorkel"] = "snorkel", ["snowflake"] = "snowflake", ["snowman"] = "snowman",
    ["sock"] = "sock", ["spider"] = "spider", ["spoon"] = "spoon", ["square"] = "square",
    ["squiggle"] = "squiggle", ["squirrel"] = "squirrel", ["stairs"] = "stairs", ["star"] = "star",
    ["steak"] = "steak", ["stitches"] = "stitches", ["stove"] = "stove", ["strawberry"] = "strawberry",
    ["streetlight"] = "streetlight", ["submarine"] = "submarine", ["suitcase"] = "suitcase", ["sun"] = "sun",
    ["swan"] = "swan", ["sweater"] = "sweater", ["sword"] = "sword", ["syringe"] = "syringe",
    ["table"] = "table", ["teapot"] = "teapot", ["telephone"] = "telephone", ["television"] = "television",
    ["tent"] = "tent", ["tiger"] = "tiger", ["toaster"] = "toaster", ["toe"] = "toe",
    ["toilet"] = "toilet", ["tooth"] = "tooth", ["tornado"] = "tornado", ["tractor"] = "tractor",
    ["train"] = "train", ["tree"] = "tree", ["triangle"] = "triangle", ["trombone"] = "trombone",
    ["truck"] = "truck", ["trumpet"] = "trumpet", ["umbrella"] = "umbrella", ["underwear"] = "underwear",
    ["van"] = "van", ["vase"] = "vase", ["violin"] = "violin", ["whale"] = "whale",
    ["wheel"] = "wheel", ["windmill"] = "windmill", ["wristwatch"] = "wristwatch", ["yoga"] = "yoga",
    ["zebra"] = "zebra", ["zigzag"] = "zigzag",
}

function normalizeTheme(theme)
    if not theme then return nil end
    local t = tostring(theme):lower():gsub("%s+", " "):gsub("^%s+",""):gsub("%s+$",""):gsub("%d+$","")
    local mapped = themeMapping[t]
    if mapped then return mapped end
    return t
end

function log(msg)
    print("📝", msg)
    table.insert(testResults, 1, msg)
    if #testResults > 80 then table.remove(testResults) end
end

function getCanvasCenter()
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Name ~= "DrawAI_V14" then
            for _, obj in ipairs(gui:GetDescendants()) do
                if (obj:IsA("Frame") or obj:IsA("ImageLabel") or obj:IsA("CanvasGroup"))
                   and obj.AbsoluteSize.X > 150 and obj.AbsoluteSize.Y > 150 and obj.Visible then
                    local center = obj.AbsolutePosition + obj.AbsoluteSize / 2
                    return center.X, center.Y, math.min(obj.AbsoluteSize.X, obj.AbsoluteSize.Y)
                end
            end
        end
    end
    return 500, 400, 300
end

function httpGetFast(url, useRange)
    if request then
        local options = {
            Url = url,
            Method = "GET",
            Headers = useRange and {["Range"] = "bytes=0-51199"} or {}
        }
        local success, res = pcall(function() return request(options) end)
        if success and res and res.Body and #res.Body > 10 then
            return res.Body
        end
    end
    local success, res = pcall(function() return game:HttpGet(url, true) end)
    if success and res and #res > 10 then return res end
    return nil
end

-- ========== GET API OBJECTS (ข้ามตามจำนวนที่ตั้งค่า + รองรับ Skip 35 + LV Buffer) ==========
function getAllJsonObjects(str)
    math.randomseed(tick() + os.time() + 9999)

    local objects = {}
    local depth = 0
    local inString = false
    local escape = false
    local startIdx = nil
    
    -- ✅ Buffer ขนาดตาม LV: LV1=1MB, LV25=5MB+
    local baseBuffer = 1048576 -- 1MB
    local lvMultiplier = 1 + (currentLV - 1) * 0.167 -- LV1=1.0, LV25=5.0
    local maxBytes = math.floor(baseBuffer * lvMultiplier)
    
    for i = 1, math.min(#str, maxBytes) do 
        local char = str:sub(i, i)
        if escape then
            escape = false
        elseif char == "\\" then
            escape = true
        elseif char == "\"" and not escape then
            inString = not inString
        elseif not inString then
            if char == "{" then
                if depth == 0 then startIdx = i end
                depth = depth + 1
            elseif char == "}" then
                depth = depth - 1
                if depth == 0 and startIdx then
                    table.insert(objects, str:sub(startIdx, i))
                    startIdx = nil
                end
            end
        end
    end
    
    -- ข้ามตามจำนวนที่ตั้งค่า (สูงสุด 35)
    if #objects > skipCount then
        for i = 1, skipCount do
            table.remove(objects, 1)
        end
        log("⏩ ข้าม " .. skipCount .. " ภาพแรกแล้ว (University Mode)")
    end
    
    log("📊 LV" .. currentLV .. " | Buffer: " .. math.floor(maxBytes/1048576*10)/10 .. "MB | พบ " .. #objects .. " objects")
    
    return objects
end

-- ========== ⚡ ULTIMATE 100% API FILTER (LV-Aware) ==========
function isGoodDrawing(theme, strokes)
    if not strokes or #strokes == 0 then return false end

    local totalPoints = 0
    local strokesCount = 0
    local minX, maxX, minY, maxY = 9e9, -9e9, 9e9, -9e9
    
    for _, s in ipairs(strokes) do
        if #s >= 2 and #s[1] > 0 then
            strokesCount = strokesCount + 1
            for i = 1, #s[1] do
                totalPoints = totalPoints + 1
                minX = math.min(minX, s[1][i])
                maxX = math.max(maxX, s[1][i])
                minY = math.min(minY, s[2][i])
                maxY = math.max(maxY, s[2][i])
            end
        end
    end

    -- ✅ เกณฑ์ขั้นต่ำตาม LV (เข้มงวดขึ้นเมื่อ LV สูง)
    local minStrokes = math.max(2, math.floor(currentLV / 5)) -- LV1=2, LV25=5
    local minPoints = 15 + (currentLV * 4) -- LV1=19, LV25=115
    local minStrokePoints = 3 + math.floor(currentLV / 3) -- LV1=3, LV25=11
    
    if strokesCount < minStrokes then 
        log("❌ LV" .. currentLV .. " | Strokes น้อยเกิน: " .. strokesCount .. "/" .. minStrokes)
        return false 
    end
    if totalPoints < minPoints then 
        log("❌ LV" .. currentLV .. " | Points น้อยเกิน: " .. totalPoints .. "/" .. minPoints)
        return false 
    end

    local w = maxX - minX
    local h = maxY - minY
    if w == 0 or h == 0 then return false end
    if (w / h) > 8 or (h / w) > 8 then return false end

    -- ✅ ตรวจสอบแต่ละ stroke มี points พอตาม LV
    for _, s in ipairs(strokes) do
        if #s >= 2 and #s[1] > 0 then
            if #s[1] < minStrokePoints then
                log("❌ LV" .. currentLV .. " | Stroke สั้นเกินไป: " .. #s[1] .. " points")
                return false
            end
        end
    end

    -- ✅ ตรวจสอบความสมบูรณ์ของรูปร่างตาม LV (สูง = เข้มงวดมาก)
    local shapeCompleteness = 0
    local cx, cy = (minX + maxX) / 2, (minY + maxY) / 2
    
    -- ตรวจสอบว่ามี stroke ในทุก quadrant หรือไม่
    local hasTL, hasTR, hasBL, hasBR = false, false, false, false
    for _, s in ipairs(strokes) do
        if #s >= 2 and #s[1] > 0 then
            for i = 1, #s[1] do
                local px, py = s[1][i], s[2][i]
                if px < cx and py < cy then hasTL = true end
                if px > cx and py < cy then hasTR = true end
                if px < cx and py > cy then hasBL = true end
                if px > cx and py > cy then hasBR = true end
            end
        end
    end
    
    local quadrantCoverage = 0
    if hasTL then quadrantCoverage = quadrantCoverage + 1 end
    if hasTR then quadrantCoverage = quadrantCoverage + 1 end
    if hasBL then quadrantCoverage = quadrantCoverage + 1 end
    if hasBR then quadrantCoverage = quadrantCoverage + 1 end
    
    -- ✅ LV สูงต้องมี stroke ครอบคลุมมากขึ้น
    local requiredQuadrants = math.min(4, 1 + math.floor(currentLV / 6)) -- LV1=1, LV25=5( capped ที่ 4)
    if quadrantCoverage < requiredQuadrants then
        log("❌ LV" .. currentLV .. " | ครอบคลุมน้อยเกิน: " .. quadrantCoverage .. "/" .. requiredQuadrants .. " quadrants")
        return false
    end

    -- 🔥 Specific Check (เพิ่มความเข้มงวดตาม LV)
    if theme == "saw" then
        local zigzagCount = 0
        for _, s in ipairs(strokes) do
            if #s[1] >= 3 then
                for i = 2, #s[1] - 1 do
                    local diff1 = s[2][i] - s[2][i-1]
                    local diff2 = s[2][i+1] - s[2][i]
                    if (diff1 > 0 and diff2 < 0) or (diff1 < 0 and diff2 > 0) then
                        zigzagCount = zigzagCount + 1
                    end
                end
            end
        end
        local requiredZigzag = 3 + math.floor(currentLV / 5) -- LV1=3, LV25=8
        if zigzagCount < requiredZigzag then return false end
    end

    if theme == "brain" then
        local curvePoints = 0
        for _, s in ipairs(strokes) do
            if #s[1] >= 5 then
                for i = 3, #s[1] - 2 do
                    local vx1 = s[1][i-1] - s[1][i-2]
                    local vy1 = s[2][i-1] - s[2][i-2]
                    local vx2 = s[1][i] - s[1][i-1]
                    local vy2 = s[2][i] - s[2][i-1]
                    local vx3 = s[1][i+1] - s[1][i]
                    local vy3 = s[2][i+1] - s[2][i]
                    local dot1 = vx1 * vx2 + vy1 * vy2
                    local dot2 = vx2 * vx3 + vy2 * vy3
                    if dot1 < -50 and dot2 < -50 then
                        curvePoints = curvePoints + 1
                    end
                end
            end
        end
        local requiredCurves = 2 + math.floor(currentLV / 8) -- LV1=2, LV25=5
        if curvePoints < requiredCurves then return false end
    end

    if theme == "drums" then
        local loops = 0
        for _, s in ipairs(strokes) do
            if #s[1] >= 5 then
                local firstX, firstY = s[1][1], s[2][1]
                local lastX, lastY = s[1][#s[1]], s[2][#s[2]]
                local dist = math.sqrt((firstX - lastX)^2 + (firstY - lastY)^2)
                if dist < 30 then loops = loops + 1 end
            end
        end
        local requiredLoops = 2 + math.floor(currentLV / 12) -- LV1=2, LV25=4
        if loops < requiredLoops then return false end
    end

    if theme == "jail" then
        local verticalLines = 0
        for _, s in ipairs(strokes) do
            if #s[1] >= 3 then
                local width = math.abs(s[1][1] - s[1][#s[1]])
                local height = math.abs(s[2][1] - s[2][#s[1]])
                if height > width * 1.5 then verticalLines = verticalLines + 1 end
            end
        end
        local requiredVertical = 2 + math.floor(currentLV / 12) -- LV1=2, LV25=4
        if verticalLines < requiredVertical then return false end
    end

    if theme == "jacket" then
        local hasArms = false
        local hasBody = false
        for _, s in ipairs(strokes) do
            if #s[1] >= 5 then
                local width = math.abs(s[1][1] - s[1][#s[1]])
                local height = math.abs(s[2][1] - s[2][#s[1]])
                if width > height then hasArms = true end
                if height > width then hasBody = true end
            end
        end
        if not hasArms or not hasBody then return false end
    end

    if theme == "stitches" then
        local facesDetected = 0
        for _, s in ipairs(strokes) do
            if #s[1] >= 5 then
                local firstX, firstY = s[1][1], s[2][1]
                local lastX, lastY = s[1][#s[1]], s[2][#s[2]]
                local dist = math.sqrt((firstX - lastX)^2 + (firstY - lastY)^2)
                if dist < 25 then facesDetected = facesDetected + 1 end
            end
        end
        if facesDetected > 1 then return false end
    end

    -- ✅ ตรวจสอบสัตว์ตาม LV (เข้มงวดขึ้น = ต้องมีส่วนประกอบครบ)
    local animalThemes = {
        elephant = {extensions = {"left", "right", "down"}, minSize = 80},
        flamingo = {extensions = {"down"}, minSize = 80},
        giraffe = {extensions = {"up"}, minSize = 80},
        lion = {extensions = {}, minSize = 80},
        horse = {extensions = {}, minSize = 80},
        dragon = {extensions = {}, minSize = 80},
        penguin = {extensions = {"down"}, minSize = 60},
        cat = {extensions = {"up"}, minSize = 50},
        dog = {extensions = {}, minSize = 50},
        monkey = {extensions = {}, minSize = 50},
    }
    
    local animalConfig = animalThemes[theme]
    if animalConfig then
        local animalWidth = maxX - minX
        local animalHeight = maxY - minY
        
        -- ✅ สัตว์ต้องมีขนาดใหญ่ตาม config
        if (animalWidth < animalConfig.minSize and animalHeight < animalConfig.minSize) then 
            log("❌ LV" .. currentLV .. " | สัตว์เล็กเกินไป: " .. animalWidth .. "x" .. animalHeight)
            return false 
        end
        
        -- ✅ LV สูง = ต้องมีส่วนขยายครบตามที่กำหนด
        if currentLV >= 10 then
            for _, dir in ipairs(animalConfig.extensions) do
                if not hasExtension(strokes, dir) then
                    log("❌ LV" .. currentLV .. " | สัตว์ขาดส่วนขยาย: " .. dir)
                    return false
                end
            end
        end
    end

    local complexThemeChecks = {
        elephant = function() return hasExtension(strokes, "left") end,
        flamingo = function() return hasExtension(strokes, "down") end,
        broccoli = function() return hasExtension(strokes, "up") and hasExtension(strokes, "down") end,
        broom = function() return hasExtension(strokes, "down") end,
    }

    -- ✅ LV สูง = ตรวจสอบ complex checks ทุกครั้ง
    if currentLV >= 15 and complexThemeChecks[theme] and not complexThemeChecks[theme]() then 
        log("❌ LV" .. currentLV .. " | Complex check ไม่ผ่าน: " .. theme)
        return false 
    end
    
    log("✅ LV" .. currentLV .. " | ผ่านการกรอง: " .. theme .. " | Strokes:" .. strokesCount .. " Points:" .. totalPoints .. " Q:" .. quadrantCoverage .. "/4")
    return true
end

function hasExtension(strokes, dir)
    local minX, maxX, minY, maxY = 9e9, -9e9, 9e9, -9e9
    for _, s in ipairs(strokes) do
        for _, x in ipairs(s[1]) do minX, maxX = math.min(minX, x), math.max(maxX, x) end
        for _, y in ipairs(s[2]) do minY, maxY = math.min(minY, y), math.max(maxY, y) end
    end
    local cx, cy = (minX + maxX) / 2, (minY + maxY) / 2
    local w, h = maxX - minX, maxY - minY
    for _, s in ipairs(strokes) do
        local sminX, smaxX, sminY, smaxY = 9e9, -9e9, 9e9, -9e9
        for _, x in ipairs(s[1]) do sminX, smaxX = math.min(sminX, x), math.max(smaxX, x) end
        for _, y in ipairs(s[2]) do sminY, smaxY = math.min(sminY, y), math.max(smaxY, y) end
        if dir == "down" and sminY > cy and (sminY - cy) > h * 0.25 then return true end
        if dir == "up" and smaxY < cy and (cy - smaxY) > h * 0.2 then return true end
        if dir == "left" and smaxX < cx and (cx - smaxX) > w * 0.2 then return true end
        if dir == "right" and sminX > cx and (sminX - cx) > w * 0.2 then return true end
    end
    return false
end

function validateStrokes(theme, strokes)
    if not strokes or #strokes == 0 then return false end
    local strokeCount = #strokes
    local totalPoints = 0
    local validStrokeCount = 0
    
    -- ✅ เกณฑ์ขั้นต่ำตาม LV
    local minStrokePoints = 2 + math.floor(currentLV / 5) -- LV1=2, LV25=7
    local minTotalPoints = 15 + (currentLV * 3) -- LV1=18, LV25=90
    local minValidStrokes = math.max(2, math.floor(currentLV / 6) + 1) -- LV1=2, LV25=5
    
    for _, s in ipairs(strokes) do
        if #s >= 2 and #s[1] > 0 and #s[2] > 0 then
            -- ✅ ตรวจสอบแต่ละ stroke มี points พอตาม LV
            if #s[1] >= minStrokePoints and #s[2] >= minStrokePoints then
                validStrokeCount = validStrokeCount + 1
                totalPoints = totalPoints + #s[1]
            end
        end
    end
    
    if validStrokeCount < minValidStrokes then 
        log("❌ Validate: Valid strokes น้อยเกิน " .. validStrokeCount .. "/" .. minValidStrokes)
        return false 
    end
    if totalPoints < minTotalPoints then 
        log("❌ Validate: Total points น้อยเกิน " .. totalPoints .. "/" .. minTotalPoints)
        return false 
    end
    
    return true
end

-- ========== FALLBACK SHAPES ==========
local fallbackShapes = {}

fallbackShapes.popsicle = function(size, ox, oy)
    local s = size or 180; local cx, cy = ox or 400, oy or 350
    local w, h = s * 0.5, s * 0.7; local stickW, stickH = s * 0.12, s * 0.4
    return {
        {{x = cx - w/2, y = cy - h/2}, {x = cx + w/2, y = cy - h/2}, {x = cx + w/2, y = cy + h/4}, {x = cx - w/2, y = cy + h/4}, {x = cx - w/2, y = cy - h/2}},
        {{x = cx - stickW/2, y = cy + h/4}, {x = cx + stickW/2, y = cy + h/4}, {x = cx + stickW/2, y = cy + h/4 + stickH}, {x = cx - stickW/2, y = cy + h/4 + stickH}, {x = cx - stickW/2, y = cy + h/4}},
    }
end

fallbackShapes.bird = function(size, ox, oy)
    local s = size or 180; local cx, cy = ox or 400, oy or 350
    return {
        {{x = cx - s*0.2, y = cy}, {x = cx - s*0.15, y = cy - s*0.25}, {x = cx + s*0.1, y = cy - s*0.3}, {x = cx + s*0.25, y = cy - s*0.1}, {x = cx + s*0.2, y = cy + s*0.15}, {x = cx, y = cy + s*0.2}, {x = cx - s*0.2, y = cy}},
        {{x = cx + s*0.2, y = cy - s*0.15}, {x = cx + s*0.3, y = cy - s*0.2}, {x = cx + s*0.35, y = cy - s*0.1}, {x = cx + s*0.3, y = cy}, {x = cx + s*0.2, y = cy - s*0.05}},
        {{x = cx + s*0.35, y = cy - s*0.1}, {x = cx + s*0.5, y = cy - s*0.05}, {x = cx + s*0.35, y = cy}},
        {{x = cx - s*0.1, y = cy - s*0.1}, {x = cx + s*0.05, y = cy - s*0.4}, {x = cx + s*0.2, y = cy - s*0.35}, {x = cx + s*0.15, y = cy - s*0.15}},
        {{x = cx - s*0.05, y = cy + s*0.2}, {x = cx - s*0.05, y = cy + s*0.35}},
        {{x = cx + s*0.1, y = cy + s*0.2}, {x = cx + s*0.1, y = cy + s*0.35}},
    }
end

fallbackShapes.steak = function(size, ox, oy)
    local s = size or 180; local cx, cy = ox or 400, oy or 350
    return {
        {{x = cx - s*0.3, y = cy}, {x = cx - s*0.25, y = cy - s*0.2}, {x = cx, y = cy - s*0.25}, {x = cx + s*0.25, y = cy - s*0.15}, {x = cx + s*0.3, y = cy + s*0.05}, {x = cx + s*0.2, y = cy + s*0.2}, {x = cx - s*0.1, y = cy + s*0.25}, {x = cx - s*0.3, y = cy + s*0.1}, {x = cx - s*0.3, y = cy}},
        {{x = cx - s*0.15, y = cy - s*0.1}, {x = cx + s*0.1, y = cy + s*0.05}},
        {{x = cx - s*0.05, y = cy - s*0.15}, {x = cx + s*0.15, y = cy + s*0.1}},
        {{x = cx + s*0.05, y = cy - s*0.2}, {x = cx + s*0.2, y = cy}},
    }
end

fallbackShapes.trumpet = function(size, ox, oy)
    local s = size or 180; local cx, cy = ox or 400, oy or 350
    return {
        {{x = cx - s*0.4, y = cy - s*0.15}, {x = cx - s*0.45, y = cy - s*0.25}, {x = cx - s*0.35, y = cy - s*0.3}, {x = cx - s*0.2, y = cy - s*0.1}, {x = cx - s*0.2, y = cy + s*0.1}, {x = cx - s*0.35, y = cy + s*0.25}, {x = cx - s*0.45, y = cy + s*0.2}, {x = cx - s*0.4, y = cy + s*0.1}},
        {{x = cx - s*0.1, y = cy - s*0.25}, {x = cx - s*0.05, y = cy - s*0.3}, {x = cx, y = cy - s*0.25}, {x = cx - s*0.05, y = cy - s*0.2}},
        {{x = cx + s*0.05, y = cy - s*0.25}, {x = cx + s*0.1, y = cy - s*0.3}, {x = cx + s*0.15, y = cy - s*0.25}, {x = cx + s*0.1, y = cy - s*0.2}},
        {{x = cx + s*0.2, y = cy - s*0.25}, {x = cx + s*0.25, y = cy - s*0.3}, {x = cx + s*0.3, y = cy - s*0.25}, {x = cx + s*0.25, y = cy - s*0.2}},
        {{x = cx - s*0.2, y = cy - s*0.05}, {x = cx + s*0.35, y = cy - s*0.05}, {x = cx + s*0.35, y = cy + s*0.05}, {x = cx - s*0.2, y = cy + s*0.05}},
        {{x = cx + s*0.35, y = cy - s*0.08}, {x = cx + s*0.42, y = cy - s*0.08}, {x = cx + s*0.42, y = cy + s*0.08}, {x = cx + s*0.35, y = cy + s*0.08}},
    }
end

fallbackShapes.grapes = function(size, ox, oy)
    local s = size or 180; local cx, cy = ox or 400, oy or 350
    local grapes = {}
    table.insert(grapes, {{x = cx, y = cy - s*0.4}, {x = cx + s*0.05, y = cy - s*0.35}})
    local positions = {{0, -0.2}, {-0.15, -0.1}, {0.15, -0.1}, {-0.1, 0.05}, {0.1, 0.05}, {0, 0.15}}
    for _, pos in ipairs(positions) do
        local gx, gy = cx + pos[1]*s, cy + pos[2]*s
        table.insert(grapes, {{x = gx - s*0.08, y = gy}, {x = gx - s*0.05, y = gy - s*0.08}, {x = gx + s*0.05, y = gy - s*0.08}, {x = gx + s*0.08, y = gy}, {x = gx + s*0.05, y = gy + s*0.08}, {x = gx - s*0.05, y = gy + s*0.08}, {x = gx - s*0.08, y = gy}})
    end
    return grapes
end

fallbackShapes["paint can"] = function(size, ox, oy)
    local s = size or 180; local cx, cy = ox or 400, oy or 350
    local w, h = s * 0.5, s * 0.6
    return {
        {{x = cx - w/2, y = cy - h/2}, {x = cx + w/2, y = cy - h/2}, {x = cx + w/2, y = cy + h/2}, {x = cx - w/2, y = cy + h/2}, {x = cx - w/2, y = cy - h/2}},
        {{x = cx - w/2, y = cy - h/2}, {x = cx - w/3, y = cy - h/2 - s*0.05}, {x = cx + w/3, y = cy - h/2 - s*0.05}, {x = cx + w/2, y = cy - h/2}},
        {{x = cx - w/3, y = cy - h/2 - s*0.05}, {x = cx - w/3, y = cy - h/2 - s*0.15}, {x = cx + w/3, y = cy - h/2 - s*0.15}, {x = cx + w/3, y = cy - h/2 - s*0.05}},
    }
end

fallbackShapes.book = function(size, ox, oy)
    local s = size or 180; local cx, cy = ox or 400, oy or 350
    return {
        {{x = cx - s*0.25, y = cy + s*0.2}, {x = cx - s*0.2, y = cy + s*0.25}, {x = cx + s*0.2, y = cy + s*0.25}, {x = cx + s*0.25, y = cy + s*0.2}},
        {{x = cx - s*0.25, y = cy + s*0.2}, {x = cx - s*0.3, y = cy - s*0.1}, {x = cx - s*0.05, y = cy - s*0.15}, {x = cx, y = cy + s*0.15}},
        {{x = cx + s*0.25, y = cy + s*0.2}, {x = cx + s*0.3, y = cy - s*0.1}, {x = cx + s*0.05, y = cy - s*0.15}, {x = cx, y = cy + s*0.15}},
        {{x = cx - s*0.2, y = cy}, {x = cx - s*0.02, y = cy + s*0.02}},
        {{x = cx - s*0.22, y = cy - s*0.05}, {x = cx - s*0.02, y = cy - s*0.03}},
        {{x = cx + s*0.02, y = cy + s*0.02}, {x = cx + s*0.2, y = cy}},
    }
end

fallbackShapes.leg = function(size, ox, oy)
    local s = size or 180; local cx, cy = ox or 400, oy or 350
    return {
        {{x = cx - s*0.15, y = cy - s*0.3}, {x = cx - s*0.1, y = cy}, {x = cx - s*0.08, y = cy + s*0.1}},
        {{x = cx + s*0.05, y = cy - s*0.3}, {x = cx + s*0.1, y = cy}, {x = cx + s*0.12, y = cy + s*0.1}},
        {{x = cx - s*0.08, y = cy + s*0.1}, {x = cx - s*0.05, y = cy + s*0.25}, {x = cx - s*0.02, y = cy + s*0.35}},
        {{x = cx + s*0.12, y = cy + s*0.1}, {x = cx + s*0.15, y = cy + s*0.25}, {x = cx + s*0.18, y = cy + s*0.35}},
        {{x = cx - s*0.02, y = cy + s*0.35}, {x = cx + s*0.05, y = cy + s*0.4}, {x = cx + s*0.2, y = cy + s*0.38}, {x = cx + s*0.22, y = cy + s*0.33}, {x = cx + s*0.18, y = cy + s*0.35}},
    }
end

fallbackShapes["light bulb"] = function(size, ox, oy)
    local s = size or 180; local cx, cy = ox or 400, oy or 350
    return {
        {{x = cx, y = cy - s*0.35}, {x = cx + s*0.15, y = cy - s*0.3}, {x = cx + s*0.2, y = cy - s*0.15}, {x = cx + s*0.15, y = cy}, {x = cx - s*0.15, y = cy}, {x = cx - s*0.2, y = cy - s*0.15}, {x = cx - s*0.15, y = cy - s*0.3}, {x = cx, y = cy - s*0.35}},
        {{x = cx - s*0.1, y = cy}, {x = cx + s*0.1, y = cy}, {x = cx + s*0.08, y = cy + s*0.1}, {x = cx - s*0.08, y = cy + s*0.1}, {x = cx - s*0.1, y = cy}},
        {{x = cx - s*0.03, y = cy + s*0.1}, {x = cx - s*0.03, y = cy + s*0.15}},
        {{x = cx + s*0.03, y = cy + s*0.1}, {x = cx + s*0.03, y = cy + s*0.15}},
    }
end

-- ========== GET API URLS ==========
function getApiUrls(theme)
    local urls = {}
    local base = "https://storage.googleapis.com/quickdraw_dataset/full/simplified/"
    local encoded = theme:gsub(" ", "%%20")
    table.insert(urls, {url = base .. encoded .. ".ndjson", name = theme .. " (%20)"})
    table.insert(urls, {url = base .. theme .. ".ndjson", name = theme})
    local noSpace = theme:gsub(" ", "")
    if noSpace ~= theme then table.insert(urls, {url = base .. noSpace .. ".ndjson", name = noSpace}) end
    local underscore = theme:gsub(" ", "_")
    if underscore ~= theme then table.insert(urls, {url = base .. underscore .. ".ndjson", name = underscore}) end
    return urls
end

-- ========== ASYNC API ==========
function getGoogleQuickDrawAsync(theme, callback)
    if not theme or theme == "" then if callback then callback(nil) end return end
    
    if apiCache[theme] then
        if callback then callback(apiCache[theme]) end
        return
    end
    
    if isLoading[theme] then
        task.spawn(function()
            local waited = 0
            while isLoading[theme] and waited < 8 do task.wait(0.1) waited = waited + 0.1 end
            callback(apiCache[theme])
        end)
        return
    end
    isLoading[theme] = true
    task.spawn(function()
        local urls = getApiUrls(theme)
        local res = nil
        for _, item in ipairs(urls) do
            log("🔍 Trying: " .. item.name)
            res = httpGetFast(item.url, true)
            if res and #res > 10 then break end
        end
        local finalStrokes = nil
        if res and #res > 10 then
            local objects = getAllJsonObjects(res)
            
            for i, obj in ipairs(objects) do
                local ok, data = pcall(function() return HttpService:JSONDecode(obj) end)
                if ok and data and data.drawing and #data.drawing > 0 then
                    local validStrokes = {}
                    for _, stroke in ipairs(data.drawing) do
                        if #stroke >= 2 and #stroke[1] > 0 and #stroke[2] > 0 then
                            table.insert(validStrokes, stroke)
                        end
                    end
                    if validateStrokes(theme, validStrokes) and isGoodDrawing(theme, validStrokes) then
                        finalStrokes = validStrokes
                        log("✅ " .. theme .. " | API ผ่านการกรอง 100%")
                        break
                    else
                        log("⚠️ " .. theme .. " | API ไม่ผ่านเกณฑ์ → ข้าม")
                    end
                end
            end
        end
        if not finalStrokes then
            log("🔄 " .. theme .. " | API ล้มเหลว → ใช้ Fallback")
            local cx, cy, canvasSize = getCanvasCenter()
            local size = canvasSize * sizeMultiplier
            if fallbackShapes[theme] then
                finalStrokes = fallbackShapes[theme](size, cx, cy)
            end
        end
        if finalStrokes and #finalStrokes > 0 then
            apiCache[theme] = finalStrokes
        end
        isLoading[theme] = nil
        if callback then callback(finalStrokes) end
    end)
end

-- ========== STROKES TO POINTS (Interpolation ตาม LV) ==========
function strokesToPoints(strokes, size, ox, oy)
    if not strokes or #strokes == 0 then return nil end
    size = size or 180; ox = ox or 400; oy = oy or 350
    
    -- ✅ Interpolation density ตาม LV (LV สูง = points หนาแน่นขึ้น)
    local interpolationSteps = math.max(1, math.floor(currentLV / 5)) -- LV1=1, LV25=5
    
    local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
    local hasPoints = false
    
    for _, stroke in ipairs(strokes) do
        if type(stroke) == "table" and #stroke > 0 then
            if stroke[1] and type(stroke[1]) == "table" and stroke[1].x then
                for _, p in ipairs(stroke) do 
                    if p.x and p.y then 
                        minX, maxX, minY, maxY = math.min(minX, p.x), math.max(maxX, p.x), math.min(minY, p.y), math.max(maxY, p.y)
                        hasPoints = true 
                    end 
                end
            elseif #stroke >= 2 and type(stroke[1]) == "table" then
                for _, x in ipairs(stroke[1]) do minX, maxX = math.min(minX, x), math.max(maxX, x); hasPoints = true end
                for _, y in ipairs(stroke[2]) do minY, maxY = math.min(minY, y), math.max(maxY, y) end
            end
        end
    end
    
    if not hasPoints then return nil end
    local w, h = maxX - minX, maxY - minY
    if w == 0 then w = 1 end; if h == 0 then h = 1 end
    local scale = math.min(size / w, size / h)
    local sx, sy = ox - (w * scale) / 2, oy - (h * scale) / 2
    
    -- ✅ Helper: Interpolate between two points
    local function interpolatePoints(x1, y1, x2, y2, steps)
        local points = {}
        for i = 0, steps do
            local t = i / steps
            table.insert(points, {
                x = x1 + (x2 - x1) * t,
                y = y1 + (y2 - y1) * t
            })
        end
        return points
    end
    
    local allStrokes = {}
    for _, stroke in ipairs(strokes) do
        local rawPoints = {}
        
        -- แปลง stroke เป็น raw points
        if type(stroke) == "table" and #stroke > 0 then
            if stroke[1] and type(stroke[1]) == "table" and stroke[1].x then
                for _, p in ipairs(stroke) do 
                    if p.x and p.y then 
                        table.insert(rawPoints, {x = p.x, y = p.y}) 
                    end 
                end
            elseif #stroke >= 2 and type(stroke[1]) == "table" then
                for i = 1, #stroke[1] do 
                    table.insert(rawPoints, {
                        x = sx + (stroke[1][i] - minX) * scale, 
                        y = sy + (stroke[2][i] - minY) * scale
                    }) 
                end
            end
        end
        
        -- ✅ Interpolate เพิ่ม points ตาม LV
        local finalPoints = {}
        if #rawPoints >= 2 and interpolationSteps > 1 then
            for i = 1, #rawPoints - 1 do
                local interpolated = interpolatePoints(
                    rawPoints[i].x, rawPoints[i].y,
                    rawPoints[i + 1].x, rawPoints[i + 1].y,
                    interpolationSteps
                )
                -- ใส่ทุก points ยกเว้น point สุดท้ายของแต่ละช่วง (จะได้ไม่ซ้ำ)
                for j = 1, #interpolated - 1 do
                    table.insert(finalPoints, interpolated[j])
                end
            end
            -- ใส่ point สุดท้าย
            table.insert(finalPoints, rawPoints[#rawPoints])
        else
            finalPoints = rawPoints
        end
        
        if #finalPoints > 0 then table.insert(allStrokes, finalPoints) end
    end
    
    log("📐 LV" .. currentLV .. " | Interpolation: " .. interpolationSteps .. "x | Strokes: " .. #allStrokes)
    return allStrokes
end

-- ========== DRAW STROKES ==========
function drawStrokes(strokesList, theme, source)
    if not strokesList or #strokesList == 0 or isDrawing then return false end
    isDrawing = true
    drawCount = drawCount + 1
    log("🎨 " .. theme .. " → " .. source .. " (" .. #strokesList .. " strokes)")
    
    task.spawn(function()
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        task.wait(0.01)

        for strokeIndex, points in ipairs(strokesList) do
            if #points == 0 then continue end
            VirtualInputManager:SendMouseButtonEvent(points[1].x, points[1].y, 0, true, game, 0)
            task.wait(0.005)
            for i = 2, #points do
                VirtualInputManager:SendMouseMoveEvent(points[i].x, points[i].y, game)
                if DRAW_DELAY > 0 then task.wait(DRAW_DELAY) end
            end
            VirtualInputManager:SendMouseButtonEvent(points[#points].x, points[#points].y, 0, false, game, 0)
            task.wait(0.005)
            VirtualInputManager:SendMouseMoveEvent(-100, -100, game)
            task.wait(0.003)
            if strokeIndex < #strokesList and #strokesList[strokeIndex + 1] and #strokesList[strokeIndex + 1] > 0 then
                local nextStart = strokesList[strokeIndex + 1][1]
                VirtualInputManager:SendMouseMoveEvent(nextStart.x, nextStart.y, game)
                task.wait(0.003)
            end
        end
        VirtualInputManager:SendMouseButtonEvent(-100, -100, 0, false, game, 0)
        isDrawing = false
        log("✅ " .. theme .. " done (" .. #strokesList .. " strokes)")
    end)
    return true
end

-- ========== DRAW THEME (สัตว์ Auto Size 100%) ==========
-- รายการสัตว์ทั้งหมด (345 รายการ)
local animalList = {
    "ant", "bear", "bee", "bird", "butterfly", "camel", "cat", "crab", 
    "crocodile", "crow", "dog", "dolphin", "dragon", "duck", "elephant",
    "fish", "flamingo", "frog", "giraffe", "hedgehog", "horse", "kangaroo",
    "lion", "lobster", "monkey", "mosquito", "mouse", "mermaid", "octopus",
    "owl", "panda", "parrot", "penguin", "pig", "rabbit", "rhinoceros",
    "scorpion", "shark", "sheep", "snail", "snake", "spider", "squirrel",
    "swan", "tiger", "whale", "zebra"
}

function isAnimal(theme)
    if not theme then return false end
    local t = tostring(theme):lower()
    for _, animal in ipairs(animalList) do
        if t == animal then return true end
    end
    return false
end

function drawTheme(theme, forceSync)
    if not theme or theme == "" or isDrawing then return false end
    local normalized = normalizeTheme(theme)
    if not normalized then return false end
    local cx, cy, canvasSize = getCanvasCenter()
    
    -- ✅ สัตว์ → sizeMultiplier 100% อัตโนมัติ
    if isAnimal(normalized) then
        sizeMultiplier = 1.0
        log("🐘 สัตว์ตรวจพบ: " .. normalized .. " → Size 100%")
    elseif autoSizeEnabled then
        local sizes = {elephant = 0.45, flamingo = 0.50, piano = 0.40, broom = 0.55, octopus = 0.45}
        sizeMultiplier = sizes[normalized] or 0.35
    end
    
    local size = canvasSize * sizeMultiplier
    log("🎯 Drawing: " .. theme .. " → API: " .. normalized .. " | Size: " .. math.floor(sizeMultiplier * 100) .. "%")
    
    if currentTheme ~= lastThemeProcessed or forceSync then
        apiCache[normalized] = nil
    end
    
    if apiCache[normalized] then
        local strokesList = strokesToPoints(apiCache[normalized], size, cx, cy)
        if strokesList and #strokesList > 0 then return drawStrokes(strokesList, theme, "⚡ Cache") end
    end
    
    getGoogleQuickDrawAsync(normalized, function(strokes)
        if strokes and currentTheme == theme and drawingApiActive and currentScene == "Drawing" then
            local strokesList = strokesToPoints(strokes, size, cx, cy)
            if strokesList and #strokesList > 0 then drawStrokes(strokesList, theme, "⚡ Google API") end
        end
    end)
    return false
end

-- ========== SYNC MONITOR ==========
if sync then
    sync.OnClientEvent:Connect(function(data)
        pcall(function()
            if type(data) == "table" and data.data then
                local state = data.data["gameAtom/state"]
                if state then
                    if state.scene and state.scene ~= currentScene then currentScene = state.scene; isDrawing = false; lastThemeProcessed = nil end
                    if state.theme then
                        local newTheme = tostring(state.theme):gsub("%d+$",""):gsub("%s+$","")
                        if newTheme ~= currentTheme then
                            currentTheme = newTheme
                            log("🎯 THEME: " .. currentTheme)
                            if drawingApiActive and currentScene == "Drawing" and currentTheme ~= lastThemeProcessed then
                                drawTheme(currentTheme)
                                lastThemeProcessed = currentTheme
                            end
                        end
                    end
                end
            end        end)
    end)
end

-- ========== GUI (เพิ่ม LV Controls + ปรับตำแหน่งปุ่ม) ==========
local gui = Instance.new("ScreenGui")
gui.Name = "DrawAI_V14"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 320, 0, 520) -- ปรับ GUI ให้สูงขึ้นเพื่อรองรับ LV
main.Position = UDim2.new(0, 10, 0, 60)
main.BackgroundColor3 = Color3.fromRGB(10, 0, 20)
main.BorderSizePixel = 2; main.BorderColor3 = Color3.fromRGB(0, 255, 100); main.Active = true; main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

local tLabel = Instance.new("TextLabel"); tLabel.Size = UDim2.new(1, 0, 0, 24); tLabel.BackgroundColor3 = Color3.fromRGB(0, 255, 100); tLabel.Text = "🧠 V14.6 — University Mode"; tLabel.TextColor3 = Color3.fromRGB(0, 0, 0); tLabel.TextSize = 10; tLabel.Font = Enum.Font.GothamBold; tLabel.Parent = main

local sLabel = Instance.new("TextLabel"); sLabel.Size = UDim2.new(0.9, 0, 0, 16); sLabel.Position = UDim2.new(0.05, 0, 0.07, 0); sLabel.BackgroundColor3 = Color3.fromRGB(15, 5, 30); sLabel.Text = "⚡ | Draw:0 | Mode: OFF | Cache:0 | LV:1"; sLabel.TextColor3 = Color3.fromRGB(0, 255, 100); sLabel.TextSize = 8; sLabel.Font = Enum.Font.Code; sLabel.Parent = main

local thLabel = Instance.new("TextLabel"); thLabel.Size = UDim2.new(0.9, 0, 0, 16); thLabel.Position = UDim2.new(0.05, 0, 0.11, 0); thLabel.BackgroundColor3 = Color3.fromRGB(15, 5, 30); thLabel.Text = "🎨 Theme: -"; thLabel.TextColor3 = Color3.fromRGB(255, 200, 0); thLabel.TextSize = 8; thLabel.Font = Enum.Font.Code; thLabel.Parent = main

local normLabel = Instance.new("TextLabel"); normLabel.Size = UDim2.new(0.9, 0, 0, 14); normLabel.Position = UDim2.new(0.05, 0, 0.15, 0); normLabel.BackgroundColor3 = Color3.fromRGB(15, 5, 30); normLabel.Text = "🔍 Normalized: -"; normLabel.TextColor3 = Color3.fromRGB(100, 200, 255); normLabel.TextSize = 7; normLabel.Font = Enum.Font.Code; normLabel.Parent = main

local autoSizeLabel = Instance.new("TextLabel"); autoSizeLabel.Size = UDim2.new(0.9, 0, 0, 14); autoSizeLabel.Position = UDim2.new(0.05, 0, 0.19, 0); autoSizeLabel.BackgroundColor3 = Color3.fromRGB(15, 5, 30); autoSizeLabel.Text = "📐 AutoSize: OFF"; autoSizeLabel.TextColor3 = Color3.fromRGB(255, 150, 50); autoSizeLabel.TextSize = 7; autoSizeLabel.Font = Enum.Font.Code; autoSizeLabel.Parent = main

local skipLabel = Instance.new("TextLabel"); skipLabel.Size = UDim2.new(0.9, 0, 0, 14); skipLabel.Position = UDim2.new(0.05, 0, 0.23, 0); skipLabel.BackgroundColor3 = Color3.fromRGB(15, 5, 30); skipLabel.Text = "⏩ Skip: 5"; skipLabel.TextColor3 = Color3.fromRGB(0, 255, 255); skipLabel.TextSize = 7; skipLabel.Font = Enum.Font.Code; skipLabel.Parent = main

-- ✅ LV Label
local lvLabel = Instance.new("TextLabel")
lvLabel.Size = UDim2.new(0.9, 0, 0, 14)
lvLabel.Position = UDim2.new(0.05, 0, 0.27, 0)
lvLabel.BackgroundColor3 = Color3.fromRGB(15, 5, 30)
lvLabel.Text = "⭐ LV: 1/25"
lvLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
lvLabel.TextSize = 7
lvLabel.Font = Enum.Font.Code
lvLabel.Parent = main

local statusLabel = Instance.new("TextLabel"); statusLabel.Size = UDim2.new(0.9, 0, 0, 14); statusLabel.Position = UDim2.new(0.05, 0, 0.31, 0); statusLabel.BackgroundColor3 = Color3.fromRGB(15, 5, 30); statusLabel.Text = "⏳ Ready"; statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100); statusLabel.TextSize = 7; statusLabel.Font = Enum.Font.Code; statusLabel.Parent = main

local logFrame = Instance.new("ScrollingFrame"); logFrame.Size = UDim2.new(0.9, 0, 0.12, 0); logFrame.Position = UDim2.new(0.05, 0, 0.36, 0); logFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0); logFrame.BorderSizePixel = 0; logFrame.ScrollBarThickness = 3; logFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 100); logFrame.Parent = main
local logText = Instance.new("TextLabel"); logText.Size = UDim2.new(1, 0, 0, 9999); logText.BackgroundTransparency = 1; logText.Text = ""; logText.TextColor3 = Color3.fromRGB(0, 255, 100); logText.TextSize = 7; logText.Font = Enum.Font.Code; logText.TextWrapped = true; logText.Parent = logFrame

-- BUTTONS
local apiBtn = Instance.new("TextButton"); apiBtn.Size = UDim2.new(0.43, 0, 0, 32); apiBtn.Position = UDim2.new(0.04, 0, 0.50, 0); apiBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 0); apiBtn.Text = "🔴 DRAWING API OFF"; apiBtn.TextColor3 = Color3.fromRGB(0, 0, 0); apiBtn.TextSize = 8; apiBtn.Font = Enum.Font.GothamBold; apiBtn.Parent = main; Instance.new("UICorner", apiBtn).CornerRadius = UDim.new(0, 4)
apiBtn.MouseButton1Click:Connect(function()
    drawingApiActive = not drawingApiActive
    if drawingApiActive then apiBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 100); apiBtn.Text = "🟢 DRAWING API ON"; log("🟢 API ON"); if currentTheme then drawTheme(currentTheme); lastThemeProcessed = currentTheme end else apiBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 0); apiBtn.Text = "🔴 DRAWING API OFF"; log("🔴 API OFF") end
end)

local forceBtn = Instance.new("TextButton"); forceBtn.Size = UDim2.new(0.43, 0, 0, 32); forceBtn.Position = UDim2.new(0.53, 0, 0.50, 0); forceBtn.BackgroundColor3 = Color3.fromRGB(100, 150, 255); forceBtn.Text = "🔄 FORCE DRAW"; forceBtn.TextColor3 = Color3.fromRGB(0, 0, 0); forceBtn.TextSize = 8; forceBtn.Font = Enum.Font.GothamBold; forceBtn.Parent = main; Instance.new("UICorner", forceBtn).CornerRadius = UDim.new(0, 4)
forceBtn.MouseButton1Click:Connect(function()
    if currentTheme then forceBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 0); local normalized = normalizeTheme(currentTheme); apiCache[normalized] = nil; log("🔄 FORCE DRAW: กำลังสุ่มภาพใหม่..."); drawTheme(currentTheme, true); task.wait(0.5); forceBtn.BackgroundColor3 = Color3.fromRGB(100, 150, 255) end
end)

-- ✅ LV Control Buttons (ย้ายมาอยู่หลัง forceBtn)
local lvDown = Instance.new("TextButton")
lvDown.Size = UDim2.new(0.12, 0, 0, 28)
lvDown.Position = UDim2.new(0.04, 0, 0.57, 0)
lvDown.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
lvDown.Text = "−"
lvDown.TextColor3 = Color3.fromRGB(255, 255, 255)
lvDown.TextSize = 16
lvDown.Font = Enum.Font.GothamBold
lvDown.Parent = main

local lvCountLabel = Instance.new("TextLabel")
lvCountLabel.Size = UDim2.new(0.14, 0, 0, 28)
lvCountLabel.Position = UDim2.new(0.17, 0, 0.57, 0)
lvCountLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
lvCountLabel.Text = "1"
lvCountLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
lvCountLabel.TextSize = 10
lvCountLabel.Font = Enum.Font.Code
lvCountLabel.Parent = main

local lvUp = Instance.new("TextButton")
lvUp.Size = UDim2.new(0.12, 0, 0, 28)
lvUp.Position = UDim2.new(0.32, 0, 0.57, 0)
lvUp.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
lvUp.Text = "+"
lvUp.TextColor3 = Color3.fromRGB(0, 0, 0)
lvUp.TextSize = 16
lvUp.Font = Enum.Font.GothamBold
lvUp.Parent = main

lvDown.MouseButton1Click:Connect(function()
    currentLV = math.max(1, currentLV - 1)
    lvCountLabel.Text = tostring(currentLV)
    lvLabel.Text = "⭐ LV: " .. currentLV .. "/25"
    log("⭐ LV ลดเหลือ: " .. currentLV)
end)

lvUp.MouseButton1Click:Connect(function()
    currentLV = math.min(25, currentLV + 1)
    lvCountLabel.Text = tostring(currentLV)
    lvLabel.Text = "⭐ LV: " .. currentLV .. "/25"
    log("⭐ LV เพิ่มเป็น: " .. currentLV)
end)

-- Size (เลื่อนลง)
local sizeDown = Instance.new("TextButton"); sizeDown.Size = UDim2.new(0.12, 0, 0, 28); sizeDown.Position = UDim2.new(0.04, 0, 0.63, 0); sizeDown.BackgroundColor3 = Color3.fromRGB(255, 100, 100); sizeDown.Text = "−"; sizeDown.TextColor3 = Color3.fromRGB(255, 255, 255); sizeDown.TextSize = 16; sizeDown.Font = Enum.Font.GothamBold; sizeDown.Parent = main
local sizeLabel = Instance.new("TextLabel"); sizeLabel.Size = UDim2.new(0.14, 0, 0, 28); sizeLabel.Position = UDim2.new(0.17, 0, 0.63, 0); sizeLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20); sizeLabel.Text = "35%"; sizeLabel.TextColor3 = Color3.fromRGB(0, 255, 100); sizeLabel.TextSize = 10; sizeLabel.Font = Enum.Font.Code; sizeLabel.Parent = main
local sizeUp = Instance.new("TextButton"); sizeUp.Size = UDim2.new(0.12, 0, 0, 28); sizeUp.Position = UDim2.new(0.32, 0, 0.63, 0); sizeUp.BackgroundColor3 = Color3.fromRGB(100, 255, 100); sizeUp.Text = "+"; sizeUp.TextColor3 = Color3.fromRGB(0, 0, 0); sizeUp.TextSize = 16; sizeUp.Font = Enum.Font.GothamBold; sizeUp.Parent = main
sizeDown.MouseButton1Click:Connect(function() sizeMultiplier = math.max(0.15, sizeMultiplier - 0.05); sizeLabel.Text = math.floor(sizeMultiplier * 100) .. "%" end)
sizeUp.MouseButton1Click:Connect(function() sizeMultiplier = math.min(1.00, sizeMultiplier + 0.05); sizeLabel.Text = math.floor(sizeMultiplier * 100) .. "%" end)

-- Skip Count Control (เลื่อนลง)
local skipDown = Instance.new("TextButton"); skipDown.Size = UDim2.new(0.12, 0, 0, 28); skipDown.Position = UDim2.new(0.47, 0, 0.63, 0); skipDown.BackgroundColor3 = Color3.fromRGB(255, 100, 100); skipDown.Text = "−"; skipDown.TextColor3 = Color3.fromRGB(255, 255, 255); skipDown.TextSize = 16; skipDown.Font = Enum.Font.GothamBold; skipDown.Parent = main
local skipCountLabel = Instance.new("TextLabel"); skipCountLabel.Size = UDim2.new(0.14, 0, 0, 28); skipCountLabel.Position = UDim2.new(0.60, 0, 0.63, 0); skipCountLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20); skipCountLabel.Text = "5"; skipCountLabel.TextColor3 = Color3.fromRGB(0, 255, 255); skipCountLabel.TextSize = 10; skipCountLabel.Font = Enum.Font.Code; skipCountLabel.Parent = main
local skipUp = Instance.new("TextButton"); skipUp.Size = UDim2.new(0.12, 0, 0, 28); skipUp.Position = UDim2.new(0.75, 0, 0.63, 0); skipUp.BackgroundColor3 = Color3.fromRGB(100, 255, 100); skipUp.Text = "+"; skipUp.TextColor3 = Color3.fromRGB(0, 0, 0); skipUp.TextSize = 16; skipUp.Font = Enum.Font.GothamBold; skipUp.Parent = main
skipDown.MouseButton1Click:Connect(function() skipCount = math.max(1, skipCount - 1); skipCountLabel.Text = tostring(skipCount); skipLabel.Text = "⏩ Skip: " .. skipCount; log("⏩ Skip Count set to: " .. skipCount) end)
skipUp.MouseButton1Click:Connect(function() skipCount = math.min(35, skipCount + 1); skipCountLabel.Text = tostring(skipCount); skipLabel.Text = "⏩ Skip: " .. skipCount; log("⏩ Skip Count set to: " .. skipCount) end)

-- Auto Size (เลื่อนลง)
local autoSizeBtn = Instance.new("TextButton"); autoSizeBtn.Size = UDim2.new(0.43, 0, 0, 28); autoSizeBtn.Position = UDim2.new(0.04, 0, 0.70, 0); autoSizeBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 50); autoSizeBtn.Text = "📐 AUTO SIZE OFF"; autoSizeBtn.TextColor3 = Color3.fromRGB(0, 0, 0); autoSizeBtn.TextSize = 8; autoSizeBtn.Font = Enum.Font.GothamBold; autoSizeBtn.Parent = main; Instance.new("UICorner", autoSizeBtn).CornerRadius = UDim.new(0, 4)
autoSizeBtn.MouseButton1Click:Connect(function()
    autoSizeEnabled = not autoSizeEnabled
    if autoSizeEnabled then autoSizeBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 255); autoSizeBtn.Text = "📐 AUTO SIZE ON"; autoSizeLabel.Text = "📐 AutoSize: ON"; log("📐 Auto Size ON") else autoSizeBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 50); autoSizeBtn.Text = "📐 AUTO SIZE OFF"; autoSizeLabel.Text = "📐 AutoSize: OFF"; log("📐 Auto Size OFF") end
end)

-- Speed (เลื่อนลง)
local speedBtn = Instance.new("TextButton"); speedBtn.Size = UDim2.new(0.43, 0, 0, 28); speedBtn.Position = UDim2.new(0.53, 0, 0.70, 0); speedBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0); speedBtn.Text = "🚀 FAST MODE"; speedBtn.TextColor3 = Color3.fromRGB(0, 0, 0); speedBtn.TextSize = 8; speedBtn.Font = Enum.Font.GothamBold; speedBtn.Parent = main; Instance.new("UICorner", speedBtn).CornerRadius = UDim.new(0, 4)
speedBtn.MouseButton1Click:Connect(function() DRAW_DELAY = DRAW_DELAY == 0 and 0.001 or 0; speedBtn.Text = DRAW_DELAY == 0 and "🚀 ZERO DELAY" or "⚡ FAST MODE"; log(DRAW_DELAY == 0 and "🚀 ZERO DELAY!" or "⚡ Fast mode") end)

-- Preload (เลื่อนลง)
local preloadBtn = Instance.new("TextButton"); preloadBtn.Size = UDim2.new(0.43, 0, 0, 28); preloadBtn.Position = UDim2.new(0.04, 0, 0.77, 0); preloadBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 255); preloadBtn.Text = "📥 PRELOAD"; preloadBtn.TextColor3 = Color3.fromRGB(0, 0, 0); preloadBtn.TextSize = 8; preloadBtn.Font = Enum.Font.GothamBold; preloadBtn.Parent = main; Instance.new("UICorner", preloadBtn).CornerRadius = UDim.new(0, 4)
preloadBtn.MouseButton1Click:Connect(function() preloadPopularThemes() end)

-- Clear (เลื่อนลง)
local clearBtn = Instance.new("TextButton"); clearBtn.Size = UDim2.new(0.43, 0, 0, 28); clearBtn.Position = UDim2.new(0.53, 0, 0.77, 0); clearBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80); clearBtn.Text = "🗑️ Clear Cache"; clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255); clearBtn.TextSize = 8; clearBtn.Font = Enum.Font.GothamBold; clearBtn.Parent = main; Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 4)
clearBtn.MouseButton1Click:Connect(function() getgenv().QuickDrawCache = {}; getgenv().QuickDrawLoading = {}; apiCache = getgenv().QuickDrawCache; isLoading = getgenv().QuickDrawLoading; log("🗑️ Cache cleared") end)

-- Close (เลื่อนลง)
local closeBtn = Instance.new("TextButton"); closeBtn.Size = UDim2.new(0.35, 0, 0, 24); closeBtn.Position = UDim2.new(0.33, 0, 0.92, 0); closeBtn.Text = "✕ Close"; closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255); closeBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0); closeBtn.TextSize = 10; closeBtn.Font = Enum.Font.GothamBold; closeBtn.Parent = main; Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
closeBtn.MouseButton1Click:Connect(function() gui:Destroy(); drawingApiActive = false end)

-- DRAG
local drag, ds, fs = false, nil, nil
main.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = true; ds = i.Position; fs = main.Position end
end)
UserInputService.InputChanged:Connect(function(i)
    if drag then local d = i.Position - ds; main.Position = UDim2.new(fs.X.Scale, fs.X.Offset + d.X, fs.Y.Scale, fs.Y.Offset + d.Y) end
end)
UserInputService.InputEnded:Connect(function() drag = false end)

-- UPDATE LOOP (เพิ่มแสดง LV)
task.spawn(function()
    while task.wait(0.2) do
        pcall(function()
            thLabel.Text = "🎨 Theme: " .. (currentTheme or "-")
            normLabel.Text = "🔍 Normalized: " .. (normalizeTheme(currentTheme) or "-")
            local cacheCount = 0; for _ in pairs(apiCache) do cacheCount = cacheCount + 1 end
            sLabel.Text = "⚡ | Draw:" .. drawCount .. " | Mode: " .. (drawingApiActive and "ON" or "OFF") .. " | Cache:" .. cacheCount .. " | LV:" .. currentLV
            local loadingCount = 0; for _ in pairs(isLoading) do loadingCount = loadingCount + 1 end
            if loadingCount > 0 then 
                statusLabel.Text = "⏳ Loading " .. loadingCount .. " theme(s)... LV" .. currentLV; statusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
            elseif preloadComplete then 
                statusLabel.Text = "✅ Ready LV" .. currentLV; statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            else 
                statusLabel.Text = "⏳ Ready | LV" .. currentLV .. " | Delay: " .. DRAW_DELAY .. "s"; statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100) 
            end
            local ls = ""; for i = math.max(1, #testResults - 6), #testResults do ls = ls .. testResults[i] .. "\n" end; logText.Text = ls; logFrame.CanvasSize = UDim2.new(0, 0, 0, logText.TextBounds.Y + 10)
        end)
    end
end)

-- ========== PRELOAD ==========
function preloadPopularThemes()
    if preloadComplete then return end
    local popular = {
        "cat","dog","house","tree","car","sun","fish","flower","apple",
        "bird","boat","cake","chair","circle","cloud","cup","face","fire",
        "heart","horse","leaf","moon","star","square","triangle","crown",
        "sheep","drums","donut","axe","lobster","popsicle","steak","trumpet",
        "grapes","paint can","book","leg","fork","bicycle","light bulb",
        "hot dog","t-shirt","palm tree","cell phone","birthday cake"
    }
    task.spawn(function()
        log("🔄 Preloading " .. #popular .. " themes...")
        local loaded = 0
        for _, theme in ipairs(popular) do
            local normalized = normalizeTheme(theme)
            if not apiCache[normalized] and not isLoading[normalized] then
                getGoogleQuickDrawAsync(normalized, function(strokes) if strokes then loaded = loaded + 1 end end)
            else
                loaded = loaded + 1
            end
            task.wait(0.2)
        end
        task.wait(5)
        preloadComplete = true
        log("✅ Preloaded: " .. loaded .. "/" .. #popular)
    end)
end

task.delay(1, function() preloadPopularThemes() end)
log("🚀 V14.6 ULTIMATE LOADED!")
log("🎯 LV 1-25 (เข้มงวดขึ้นตาม Level)")
log("🎯 Skip Count 1-35 | Animal Auto Size 100%")
log("🟢 Press DRAWING API ON to start")
