--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║  COMPLETE ARGUMENT DISCOVERY SUITE — Place 89231719412825       ║
    ║  All 8 Steps: Source Reader + Fuzzer + Sniffer + DB + Exploit    ║
    ║  + DRAGGABLE GUI + COPY LOG + EXPORT REPORT + PIG FACE          ║
    ╚══════════════════════════════════════════════════════════════════╝
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat task.wait() LocalPlayer = Players.LocalPlayer until LocalPlayer
end

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Leaderboard = ReplicatedStorage:WaitForChild("Leaderboard")

--------------------------------------------------------------------------------
-- SAFE INSTANCE CREATION
--------------------------------------------------------------------------------
local function safeCreate(className, properties)
    local success, obj = pcall(function()
        local o = Instance.new(className)
        for prop, value in pairs(properties) do
            pcall(function() o[prop] = value end)
        end
        return o
    end)
    if not success then return nil end
    return obj
end

--------------------------------------------------------------------------------
-- COLORS
--------------------------------------------------------------------------------
local COLORS = {
    BG_MAIN = Color3.fromRGB(8, 8, 20),
    BG_SECONDARY = Color3.fromRGB(16, 16, 35),
    BG_TERTIARY = Color3.fromRGB(26, 26, 50),
    ACCENT = Color3.fromRGB(0, 240, 180),
    ACCENT_DIM = Color3.fromRGB(0, 170, 130),
    ACCENT_DARK = Color3.fromRGB(0, 110, 80),
    RED = Color3.fromRGB(255, 55, 55),
    RED_DIM = Color3.fromRGB(180, 30, 30),
    ORANGE = Color3.fromRGB(255, 145, 35),
    YELLOW = Color3.fromRGB(255, 210, 50),
    GOLD = Color3.fromRGB(255, 195, 55),
    GREEN = Color3.fromRGB(55, 225, 95),
    GREEN_DIM = Color3.fromRGB(35, 155, 65),
    WHITE = Color3.fromRGB(255, 255, 255),
    GRAY = Color3.fromRGB(155, 155, 155),
    GRAY_DARK = Color3.fromRGB(85, 85, 105),
    PURPLE = Color3.fromRGB(155, 65, 255),
    PINK = Color3.fromRGB(255, 85, 175),
    CYAN = Color3.fromRGB(45, 205, 215),
    BLUE = Color3.fromRGB(55, 125, 235),
    TEAL = Color3.fromRGB(40, 180, 170),
    -- Pig face colors
    PIG_PINK = Color3.fromRGB(255, 180, 200),
    PIG_DARK = Color3.fromRGB(200, 130, 150),
    PIG_NOSE = Color3.fromRGB(255, 100, 130),
    PIG_NOSTRIL = Color3.fromRGB(120, 50, 70),
    PIG_BLUSH = Color3.fromRGB(255, 150, 180),
    PIG_EYE = Color3.fromRGB(40, 40, 40),
}

--------------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------------
local State = {
    isRunning = true,
    logs = {},
    
    -- Step 1-3: Source Reader
    sourceModules = {},
    sourceReadSuccess = 0,
    sourceReadFailed = 0,
    
    -- Step 4-5: Fuzzer
    fuzzTotalTests = 0,
    fuzzSuccessTests = 0,
    fuzzCurrentRemote = "None",
    fuzzResults = {},
    isFuzzing = false,
    
    -- Step 6: Passive Sniffer
    sniffedPackets = {},
    sniffCount = 0,
    argumentSignatures = {},
    
    -- Step 7: Signature Database
    signatureDB = {},
    
    -- Step 8: Exploit Tests
    exploitTests = 0,
    exploitSuccess = 0
}

local function addLog(message, color)
    color = color or COLORS.WHITE
    table.insert(State.logs, {
        text = message,
        color = color,
        time = os.date("%H:%M:%S")
    })
    if #State.logs > 500 then table.remove(State.logs, 1) end
end

--------------------------------------------------------------------------------
-- PIG FACE CREATION (FIXED)
--------------------------------------------------------------------------------
local function createPigFace(parent, size)
    -- Container
    local faceContainer = Instance.new("Frame")
    faceContainer.Size = UDim2.new(0, size, 0, size)
    faceContainer.Position = UDim2.new(0, 0, 0, 0)
    faceContainer.BackgroundColor3 = COLORS.PIG_PINK
    faceContainer.BackgroundTransparency = 0.4
    faceContainer.BorderSizePixel = 0
    faceContainer.ClipsDescendants = true
    faceContainer.Parent = parent

    local faceCorner = Instance.new("UICorner")
    faceCorner.CornerRadius = UDim.new(0, size * 0.12)
    faceCorner.Parent = faceContainer

    -- Ears (left and right)
    for i = 0, 1 do
        local ear = Instance.new("Frame")
        ear.Size = UDim2.new(0.25, 0, 0.3, 0)
        ear.Position = UDim2.new(0.02 + i * 0.73, 0, -0.1, 0)
        ear.BackgroundColor3 = COLORS.PIG_PINK
        ear.BackgroundTransparency = 0.4
        ear.BorderSizePixel = 0
        ear.Rotation = i == 0 and -15 or 15
        ear.Parent = faceContainer

        local earCorner = Instance.new("UICorner")
        earCorner.CornerRadius = UDim.new(1, 0)
        earCorner.Parent = ear

        local innerEar = Instance.new("Frame")
        innerEar.Size = UDim2.new(0.6, 0, 0.5, 0)
        innerEar.Position = UDim2.new(0.2, 0, 0.2, 0)
        innerEar.BackgroundColor3 = COLORS.PIG_DARK
        innerEar.BackgroundTransparency = 0.5
        innerEar.BorderSizePixel = 0
        innerEar.Rotation = i == 0 and 10 or -10
        innerEar.Parent = ear

        local innerCorner = Instance.new("UICorner")
        innerCorner.CornerRadius = UDim.new(1, 0)
        innerCorner.Parent = innerEar
    end

    -- Nose
    local nose = Instance.new("Frame")
    nose.Size = UDim2.new(0.25, 0, 0.2, 0)
    nose.Position = UDim2.new(0.375, 0, 0.45, 0)
    nose.BackgroundColor3 = COLORS.PIG_NOSE
    nose.BorderSizePixel = 0
    nose.Parent = faceContainer

    local noseCorner = Instance.new("UICorner")
    noseCorner.CornerRadius = UDim.new(0, size * 0.05)
    noseCorner.Parent = nose

    -- Nostrils
    for i = 0, 1 do
        local nostril = Instance.new("Frame")
        nostril.Size = UDim2.new(0.15, 0, 0.15, 0)
        nostril.Position = UDim2.new(0.2 + i * 0.45, 0, 0.3, 0)
        nostril.BackgroundColor3 = COLORS.PIG_NOSTRIL
        nostril.BorderSizePixel = 0
        nostril.Parent = nose

        local nCorner = Instance.new("UICorner")
        nCorner.CornerRadius = UDim.new(0, size * 0.03)
        nCorner.Parent = nostril
    end

    -- Eyes (with blink support)
    local eyeContainers = {}
    for i = 0, 1 do
        local eyeContainer = Instance.new("Frame")
        eyeContainer.Size = UDim2.new(0.2, 0, 0.2, 0)
        eyeContainer.Position = UDim2.new(0.22 + i * 0.56, 0, 0.25, 0)
        eyeContainer.BackgroundColor3 = COLORS.WHITE
        eyeContainer.BackgroundTransparency = 0.7
        eyeContainer.BorderSizePixel = 0
        eyeContainer.Parent = faceContainer

        local eyeCorner = Instance.new("UICorner")
        eyeCorner.CornerRadius = UDim.new(1, 0)
        eyeCorner.Parent = eyeContainer

        -- Pupil
        local pupil = Instance.new("Frame")
        pupil.Size = UDim2.new(0.5, 0, 0.5, 0)
        pupil.Position = UDim2.new(0.25, 0, 0.25, 0)
        pupil.BackgroundColor3 = COLORS.PIG_EYE
        pupil.BorderSizePixel = 0
        pupil.Parent = eyeContainer

        local pupilCorner = Instance.new("UICorner")
        pupilCorner.CornerRadius = UDim.new(1, 0)
        pupilCorner.Parent = pupil

        -- Eye shine
        local shine = Instance.new("Frame")
        shine.Size = UDim2.new(0.25, 0, 0.25, 0)
        shine.Position = UDim2.new(0.6, 0, 0.6, 0)
        shine.BackgroundColor3 = COLORS.WHITE
        shine.BackgroundTransparency = 0.3
        shine.BorderSizePixel = 0
        shine.Parent = eyeContainer

        local shineCorner = Instance.new("UICorner")
        shineCorner.CornerRadius = UDim.new(1, 0)
        shineCorner.Parent = shine

        table.insert(eyeContainers, eyeContainer)
    end

    -- Cheeks
    for i = 0, 1 do
        local cheek = Instance.new("Frame")
        cheek.Size = UDim2.new(0.15, 0, 0.1, 0)
        cheek.Position = UDim2.new(0.05 + i * 0.8, 0, 0.65, 0)
        cheek.BackgroundColor3 = COLORS.PIG_BLUSH
        cheek.BackgroundTransparency = 0.6
        cheek.BorderSizePixel = 0
        cheek.Parent = faceContainer

        local cheekCorner = Instance.new("UICorner")
        cheekCorner.CornerRadius = UDim.new(1, 0)
        cheekCorner.Parent = cheek
    end

    return faceContainer, eyeContainers
end

-- Blink loop for the pig face
local function startPigBlinkLoop(eyeContainers, runningFlag)
    task.spawn(function()
        while runningFlag() and State.isRunning do
            task.wait(math.random(3, 7))
            if not runningFlag() or not State.isRunning then break end

            -- Close eyes
            for _, eye in ipairs(eyeContainers) do
                if eye and eye.Parent then
                    local closeTween = TweenService:Create(eye, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {
                        Size = UDim2.new(0.2, 0, 0.04, 0)
                    })
                    closeTween:Play()
                    closeTween.Completed:Wait()
                    -- Open eyes
                    local openTween = TweenService:Create(eye, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {
                        Size = UDim2.new(0.2, 0, 0.2, 0)
                    })
                    openTween:Play()
                    openTween.Completed:Wait()
                end
            end
        end
    end)
end

--------------------------------------------------------------------------------
-- STEP 1-3: SOURCE CODE READER
--------------------------------------------------------------------------------
local SourceReader = {}

function SourceReader:ReadModuleSource(moduleScript)
    if not moduleScript or not moduleScript:IsA("ModuleScript") then
        return nil, "Not a ModuleScript"
    end
    
    local success, source = pcall(function()
        return moduleScript.Source
    end)
    
    if success and source and #source > 0 then
        State.sourceReadSuccess = State.sourceReadSuccess + 1
        
        addLog("[SOURCE] ✅ " .. moduleScript:GetFullName() .. " (" .. #source .. " bytes)", COLORS.GREEN)
        
        local signatures = self:ExtractSignatures(source)
        
        table.insert(State.sourceModules, {
            path = moduleScript:GetFullName(),
            name = moduleScript.Name,
            size = #source,
            source = source,
            signatures = signatures
        })
        
        return source, signatures
    else
        State.sourceReadFailed = State.sourceReadFailed + 1
        addLog("[SOURCE] ❌ " .. moduleScript:GetFullName() .. " - PROTECTED", COLORS.RED)
        return nil, "Protected or empty"
    end
end

function SourceReader:ExtractSignatures(source)
    local signatures = {}
    
    for remoteName, args in source:gmatch("([%w_]+):FireServer%(([^)]*)%)") do
        table.insert(signatures, { type = "RemoteEvent", name = remoteName, args = args })
    end
    for remoteName, args in source:gmatch("([%w_]+):InvokeServer%(([^)]*)%)") do
        table.insert(signatures, { type = "RemoteFunction", name = remoteName, args = args })
    end
    for bindableName, args in source:gmatch("([%w_]+):Fire%(([^)]*)%)") do
        table.insert(signatures, { type = "BindableEvent", name = bindableName, args = args })
    end
    for reqPath in source:gmatch("require%(([^)]+)%)") do
        table.insert(signatures, { type = "Require", path = reqPath })
    end
    
    return signatures
end

function SourceReader:ScanTargetModules()
    local targets = {
        "ReplicatedStorage.CodeValidator",
        "ReplicatedStorage.GeneralUtils",
        "ReplicatedStorage.KnownDigitsUtils",
        "ReplicatedStorage.Constants",
        "ReplicatedStorage.Utils.ClientPricing",
        "ReplicatedStorage.Utils.AdServiceHelper"
    }
    
    addLog("═══ STEP 1-3: Source Code Reader ═══", COLORS.TEAL)
    
    for _, path in ipairs(targets) do
        local parts = {}
        for part in path:gmatch("[^.]+") do table.insert(parts, part) end
        local current = game
        for _, part in ipairs(parts) do
            current = current:FindFirstChild(part)
            if not current then break end
        end
        
        if current and current:IsA("ModuleScript") then
            local source, signatures = self:ReadModuleSource(current)
            if source then
                addLog("[SOURCE] Signatures found: " .. #signatures, COLORS.CYAN)
                for _, sig in ipairs(signatures) do
                    addLog("  → " .. sig.type .. " " .. sig.name .. "(" .. sig.args .. ")", COLORS.GRAY)
                end
            end
        else
            addLog("[SOURCE] ⚠️ Not found: " .. path, COLORS.ORANGE)
        end
    end
    
    -- Also scan all ModuleScripts in ReplicatedStorage
    addLog("[SOURCE] Scanning ALL modules...", COLORS.TEAL)
    for _, mod in ipairs(ReplicatedStorage:GetDescendants()) do
        if mod:IsA("ModuleScript") then
            local alreadyScanned = false
            for _, scanned in ipairs(State.sourceModules) do
                if scanned.path == mod:GetFullName() then
                    alreadyScanned = true
                    break
                end
            end
            if not alreadyScanned then
                self:ReadModuleSource(mod)
            end
        end
    end
    
    addLog("[SOURCE] Complete: " .. State.sourceReadSuccess .. " read, " .. State.sourceReadFailed .. " protected", COLORS.TEAL)
end

function SourceReader:GetAllSignatures()
    local allSigs = {}
    for _, mod in ipairs(State.sourceModules) do
        for _, sig in ipairs(mod.signatures) do
            table.insert(allSigs, { source = mod.name, type = sig.type, name = sig.name, args = sig.args })
        end
    end
    return allSigs
end

--------------------------------------------------------------------------------
-- STEP 4-5: ARGUMENT FUZZER
--------------------------------------------------------------------------------
local ArgumentFuzzer = {
    typeMatrix = {
        "nil", "boolean", true, false,
        "number", 0, 1, -1, 999999, 3.14159,
        "string", "", "test", "000000", "player1", "666666",
        "table", {}, {test = 1}, {1, 2, 3},
        "Vector3", Vector3.new(0, 0, 0),
        "Instance", workspace
    }
}

function ArgumentFuzzer:FuzzRemoteEvent(remoteName, remoteInstance)
    State.isFuzzing = true
    State.fuzzCurrentRemote = remoteName
    
    addLog("═══ FUZZ: " .. remoteName .. " (RemoteEvent) ═══", COLORS.GOLD)
    
    local results = { remote = remoteName, type = "RemoteEvent", tests = {}, validSignatures = {}, timestamp = os.date("%H:%M:%S") }
    
    -- No args
    pcall(function() remoteInstance:FireServer() end)
    State.fuzzTotalTests = State.fuzzTotalTests + 1
    task.wait(0.1)
    
    -- Single argument fuzzing
    for _, testValue in ipairs(self.typeMatrix) do
        if typeof(testValue) ~= "string" then
            task.wait(0.15)
            local success, err = pcall(function() remoteInstance:FireServer(testValue) end)
            local argStr = typeof(testValue) .. ": " .. tostring(testValue):sub(1, 40)
            table.insert(results.tests, { args = "(" .. argStr .. ")", argType = typeof(testValue), success = success, error = err and tostring(err):sub(1, 150) or nil })
            State.fuzzTotalTests = State.fuzzTotalTests + 1
            if success then
                State.fuzzSuccessTests = State.fuzzSuccessTests + 1
                table.insert(results.validSignatures, "(" .. typeof(testValue) .. ")")
                addLog("  ✅ [" .. argStr .. "] — OK", COLORS.GREEN)
            else
                addLog("  ❌ [" .. argStr .. "] — " .. (err and tostring(err):sub(1, 70) or "?"), COLORS.RED)
            end
        end
    end
    
    -- Multi-argument patterns
    local patterns = {
        {"string", "string"}, {"string", "number"}, {"number", "number"},
        {"string", "boolean"}, {"number", "boolean"}, {"string", "string", "boolean"},
        {"string", "string", "string", "boolean"}, {"string", "boolean", "boolean", "boolean", "boolean", "boolean", "boolean"}
    }
    for _, pattern in ipairs(patterns) do
        local args = {}; local argDesc = {}
        for _, typeName in ipairs(pattern) do
            local val = self:GenerateValue(typeName)
            table.insert(args, val)
            table.insert(argDesc, typeName .. ":" .. tostring(val):sub(1, 20))
        end
        task.wait(0.15)
        local success, err = pcall(function() remoteInstance:FireServer(unpack(args)) end)
        local argStr = "(" .. table.concat(argDesc, ", ") .. ")"
        table.insert(results.tests, { args = argStr, pattern = table.concat(pattern, ", "), success = success, error = err and tostring(err):sub(1, 150) or nil })
        State.fuzzTotalTests = State.fuzzTotalTests + 1
        if success then
            State.fuzzSuccessTests = State.fuzzSuccessTests + 1
            table.insert(results.validSignatures, "(" .. table.concat(pattern, ", ") .. ")")
            addLog("  ✅ " .. argStr .. " — OK", COLORS.GREEN)
        else
            addLog("  ❌ " .. argStr .. " — " .. (err and tostring(err):sub(1, 60) or "?"), COLORS.RED)
        end
    end
    
    State.signatureDB[remoteName] = { type = "RemoteEvent", validSignatures = results.validSignatures, testCount = #results.tests, timestamp = os.date("%Y-%m-%d %H:%M:%S") }
    table.insert(State.fuzzResults, results)
    State.isFuzzing = false
    addLog("═══ " .. remoteName .. ": " .. #results.validSignatures .. " valid signatures ═══", COLORS.GOLD)
    return results
end

function ArgumentFuzzer:FuzzRemoteFunction(remoteName, remoteInstance)
    State.isFuzzing = true
    State.fuzzCurrentRemote = remoteName
    addLog("═══ FUZZ: " .. remoteName .. " (RemoteFunction) ═══", COLORS.GOLD)
    
    local results = { remote = remoteName, type = "RemoteFunction", tests = {}, validSignatures = {}, timestamp = os.date("%H:%M:%S") }
    local testPayloads = {
        {"()", {}}, {"(string)", {"test"}}, {"(number)", {123456}}, {"(code)", {"000000"}},
        {"(bool)", {true}}, {"(nil)", {nil}}, {"(str,num)", {"test", 123}}, {"(num,bool)", {123456, true}},
        {"(table)", {{key = "value"}}}, {"(Vector3)", {Vector3.new(0, 0, 0)}},
    }
    for _, testData in ipairs(testPayloads) do
        local label = testData[1]; local payload = testData[2]
        task.wait(0.2)
        local success, result = pcall(function() return remoteInstance:InvokeServer(unpack(payload)) end)
        State.fuzzTotalTests = State.fuzzTotalTests + 1
        if success then
            State.fuzzSuccessTests = State.fuzzSuccessTests + 1
            local resStr = typeof(result) .. ": " .. HttpService:JSONEncode(result):sub(1, 120)
            addLog("  ✅ " .. label .. " → " .. resStr, COLORS.GREEN)
            table.insert(results.validSignatures, label .. " → " .. typeof(result))
            table.insert(results.tests, { args = label, success = true, result = resStr })
        else
            addLog("  ❌ " .. label .. " → " .. tostring(result):sub(1, 80), COLORS.RED)
            table.insert(results.tests, { args = label, success = false, error = tostring(result):sub(1, 150) })
        end
    end
    
    State.signatureDB[remoteName] = { type = "RemoteFunction", validSignatures = results.validSignatures, testCount = #results.tests, timestamp = os.date("%Y-%m-%d %H:%M:%S") }
    table.insert(State.fuzzResults, results)
    State.isFuzzing = false
    addLog("═══ " .. remoteName .. ": " .. #results.validSignatures .. " valid ═══", COLORS.GOLD)
    return results
end

function ArgumentFuzzer:GenerateValue(typeName)
    local generators = {
        string = function() return "test_" .. tostring(math.random(1000)) end,
        number = function() return math.random(0, 999999) end,
        boolean = function() return math.random() > 0.5 end,
        table = function() return {test = math.random(100)} end,
        nil = function() return nil end
    }
    return (generators[typeName] or generators.string)()
end

function ArgumentFuzzer:FuzzAllRemotes()
    addLog("═══ STEP 4-5: Argument Fuzzer ═══", COLORS.GOLD)
    for _, remote in ipairs(Remotes:GetChildren()) do
        if remote:IsA("RemoteEvent") then self:FuzzRemoteEvent(remote.Name, remote); task.wait(0.3)
        elseif remote:IsA("RemoteFunction") then self:FuzzRemoteFunction(remote.Name, remote); task.wait(0.3) end
    end
    if Leaderboard then
        for _, remote in ipairs(Leaderboard:GetChildren()) do
            if remote:IsA("RemoteEvent") then self:FuzzRemoteEvent("Leaderboard." .. remote.Name, remote); task.wait(0.3)
            elseif remote:IsA("RemoteFunction") then self:FuzzRemoteFunction("Leaderboard." .. remote.Name, remote); task.wait(0.3) end
        end
    end
    addLog("✅ All remotes fuzzed!", COLORS.GREEN)
end

function ArgumentFuzzer:FuzzImportantOnly()
    addLog("═══ FUZZING IMPORTANT REMOTES ═══", COLORS.GOLD)
    local important = {
        "GuessResult", "RevealDigit", "RoundOver", "ResultDecided",
        "MakeGuess", "SubmitGuess", "SubmitCode", "ChooseCode",
        "SendNotification", "PromptCoinPurchase", "RequestRewardedCoinAd",
        "EquipItem", "GetTableCollection", "CameraFocus", "LocalCodeChosen"
    }
    for _, name in ipairs(important) do
        local remote = Remotes:FindFirstChild(name)
        if not remote and Leaderboard then remote = Leaderboard:FindFirstChild(name) end
        if remote then
            if remote:IsA("RemoteEvent") then self:FuzzRemoteEvent(name, remote)
            elseif remote:IsA("RemoteFunction") then self:FuzzRemoteFunction(name, remote) end
            task.wait(0.2)
        else
            addLog("  ⚠️ Not found: " .. name, COLORS.ORANGE)
        end
    end
end

--------------------------------------------------------------------------------
-- STEP 6: PASSIVE SNIFFER
--------------------------------------------------------------------------------
local PassiveSniffer = {}

function PassiveSniffer:MountAllSniffers()
    addLog("═══ STEP 6: Passive Sniffer ═══", COLORS.CYAN)
    for _, remote in ipairs(Remotes:GetChildren()) do
        if remote:IsA("RemoteEvent") then
            pcall(function()
                remote.OnClientEvent:Connect(function(...)
                    if not State.isRunning then return end
                    local args = {...}
                    State.sniffCount = State.sniffCount + 1
                    local argTypes = {}
                    for i, arg in ipairs(args) do table.insert(argTypes, typeof(arg) .. ":" .. tostring(arg):sub(1, 30)) end
                    table.insert(State.sniffedPackets, { remote = remote.Name, direction = "IN", args = argTypes, rawArgs = args, timestamp = tick() })
                    State.argumentSignatures[remote.Name] = { type = "RemoteEvent", argCount = #args, argTypes = argTypes, lastSeen = os.date("%H:%M:%S"), sample = args }
                end)
            end)
        elseif remote:IsA("RemoteFunction") then
            pcall(function()
                remote.OnClientInvoke:Connect(function(...)
                    if not State.isRunning then return end
                    local args = {...}
                    State.sniffCount = State.sniffCount + 1
                    local argTypes = {}
                    for i, arg in ipairs(args) do table.insert(argTypes, typeof(arg) .. ":" .. tostring(arg):sub(1, 30)) end
                    table.insert(State.sniffedPackets, { remote = remote.Name, direction = "INVOKE", args = argTypes, timestamp = tick() })
                    State.argumentSignatures[remote.Name] = { type = "RemoteFunction", argCount = #args, argTypes = argTypes, lastSeen = os.date("%H:%M:%S") }
                end)
            end)
        end
    end
    -- Hook FireServer for outgoing
    for _, remote in ipairs(Remotes:GetChildren()) do
        if remote:IsA("RemoteEvent") then
            pcall(function()
                local orig = remote.FireServer
                remote.FireServer = function(self, ...)
                    local args = {...}
                    local argTypes = {}
                    for i, arg in ipairs(args) do table.insert(argTypes, typeof(arg) .. ":" .. tostring(arg):sub(1, 30)) end
                    table.insert(State.sniffedPackets, { remote = remote.Name, direction = "OUT", args = argTypes, timestamp = tick() })
                    return orig(self, ...)
                end
            end)
        end
    end
    addLog("✅ Sniffers mounted on all remotes", COLORS.CYAN)
end

--------------------------------------------------------------------------------
-- STEP 7: SIGNATURE DATABASE BUILDER
--------------------------------------------------------------------------------
local SignatureDatabase = {}

function SignatureDatabase:Build()
    addLog("═══ STEP 7: Building Signature Database ═══", COLORS.PURPLE)
    local db = { generatedAt = os.date("!%Y-%m-%dT%H:%M:%SZ"), placeId = 89231719412825, sources = { sourceCode = #State.sourceModules, fuzzed = #State.fuzzResults, sniffed = State.sniffCount }, signatures = {} }
    local allRemoteNames = {}
    for _, mod in ipairs(State.sourceModules) do
        for _, sig in ipairs(mod.signatures) do
            if sig.type == "RemoteEvent" or sig.type == "RemoteFunction" then
                allRemoteNames[sig.name] = allRemoteNames[sig.name] or {}
                allRemoteNames[sig.name].sourceCode = sig.args
            end
        end
    end
    for remoteName, sigData in pairs(State.signatureDB) do
        allRemoteNames[remoteName] = allRemoteNames[remoteName] or {}
        allRemoteNames[remoteName].fuzzer = sigData.validSignatures
    end
    for remoteName, sigData in pairs(State.argumentSignatures) do
        allRemoteNames[remoteName] = allRemoteNames[remoteName] or {}
        allRemoteNames[remoteName].sniffer = { argCount = sigData.argCount, argTypes = sigData.argTypes, lastSeen = sigData.lastSeen }
    end
    for remoteName, sources in pairs(allRemoteNames) do
        local confidence = 0
        if sources.sourceCode then confidence = confidence + 0.4 end
        if sources.fuzzer then confidence = confidence + 0.3 end
        if sources.sniffer then confidence = confidence + 0.3 end
        table.insert(db.signatures, { remote = remoteName, confidence = math.floor(confidence * 100), sourceCode = sources.sourceCode, fuzzer = sources.fuzzer, sniffer = sources.sniffer, verified = confidence >= 0.6 })
    end
    table.sort(db.signatures, function(a, b) return a.confidence > b.confidence end)
    State.signatureDB = db
    addLog("✅ Database built: " .. #db.signatures .. " signatures", COLORS.PURPLE)
    for _, sig in ipairs(db.signatures) do
        if sig.verified then
            addLog("  🔒 " .. sig.remote .. " (" .. sig.confidence .. "% confidence)", COLORS.GREEN)
            if sig.sniffer then addLog("    → (" .. table.concat(sig.sniffer.argTypes or {}, ", ") .. ")", COLORS.GRAY) end
        end
    end
    return db
end

--------------------------------------------------------------------------------
-- STEP 8: EXPLOIT TESTER
--------------------------------------------------------------------------------
local ExploitTester = {}

function ExploitTester:TestWithSignature(remoteName, args)
    State.exploitTests = State.exploitTests + 1
    local remote = Remotes:FindFirstChild(remoteName)
    if not remote and Leaderboard then remote = Leaderboard:FindFirstChild(remoteName) end
    if not remote then addLog("[EXPLOIT] ❌ Remote not found: " .. remoteName, COLORS.RED); return false end
    addLog("[EXPLOIT] Testing: " .. remoteName .. " with " .. HttpService:JSONEncode(args):sub(1, 100), COLORS.PINK)
    local success = false
    if remote:IsA("RemoteEvent") then
        pcall(function() remote:FireServer(unpack(args)); success = true end)
    elseif remote:IsA("RemoteFunction") then
        local result
        pcall(function() result = remote:InvokeServer(unpack(args)); success = true end)
        if success and result then addLog("[EXPLOIT] ✅ Result: " .. typeof(result) .. " = " .. HttpService:JSONEncode(result):sub(1, 100), COLORS.GREEN) end
    end
    if success then State.exploitSuccess = State.exploitSuccess + 1; addLog("[EXPLOIT] ✅ Success!", COLORS.GREEN)
    else addLog("[EXPLOIT] ❌ Failed", COLORS.RED) end
    return success
end

function ExploitTester:RunAllVerifiedExploits()
    addLog("═══ STEP 8: Testing Verified Exploits ═══", COLORS.PINK)
    local db = State.signatureDB
    if not db or not db.signatures then addLog("[EXPLOIT] No signature database! Run Step 7 first.", COLORS.RED); return end
    for _, sig in ipairs(db.signatures) do
        if sig.verified and sig.sniffer then
            local testArgs = {}
            if sig.sniffer.argTypes then
                for _, typeStr in ipairs(sig.sniffer.argTypes) do
                    local typeName = typeStr:match("^(%w+):")
                    if typeName == "string" then table.insert(testArgs, "000000")
                    elseif typeName == "number" then table.insert(testArgs, 999999)
                    elseif typeName == "boolean" then table.insert(testArgs, true)
                    elseif typeName == "nil" then table.insert(testArgs, nil)
                    else table.insert(testArgs, "test") end
                end
            end
            if #testArgs > 0 then task.wait(0.3); self:TestWithSignature(sig.remote, testArgs) end
        end
    end
    addLog("✅ Exploit tests: " .. State.exploitTests .. " | Success: " .. State.exploitSuccess, COLORS.PINK)
end

--------------------------------------------------------------------------------
-- CREATE DRAGGABLE GUI (with Pig Face)
--------------------------------------------------------------------------------
local function createDiscoveryGUI()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then
        playerGui = safeCreate("ScreenGui", {Name = "PlayerGui", Parent = LocalPlayer})
    end
    if not playerGui then return nil end
    
    pcall(function()
        local old = playerGui:FindFirstChild("ArgumentDiscoveryGUI")
        if old then old:Destroy() end
    end)
    
    local screenGui = safeCreate("ScreenGui", { Name = "ArgumentDiscoveryGUI", ResetOnSpawn = false, Parent = playerGui })
    if not screenGui then return nil end
    
    -- ============================================================
    -- MAIN FRAME
    -- ============================================================
    local mainFrame = safeCreate("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, 430, 0, 520),
        Position = UDim2.new(0.5, -215, 0.04, 0),
        BackgroundColor3 = COLORS.BG_MAIN,
        BorderSizePixel = 0,
        Active = true,
        Parent = screenGui
    })
    safeCreate("UICorner", {CornerRadius = UDim.new(0, 16), Parent = mainFrame})
    safeCreate("UIStroke", {Color = COLORS.ACCENT, Thickness = 1.5, Transparency = 0.3, Parent = mainFrame})
    
    -- ============================================================
    -- HEADER (DRAG HANDLE)
    -- ============================================================
    local header = safeCreate("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = COLORS.BG_SECONDARY,
        BorderSizePixel = 0,
        Active = true,
        Parent = mainFrame
    })
    safeCreate("UICorner", {CornerRadius = UDim.new(0, 16), Parent = header})
    safeCreate("Frame", {
        Size = UDim2.new(1, 0, 0.5, 0),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = COLORS.BG_SECONDARY,
        BorderSizePixel = 0,
        Parent = header
    })
    
    -- Pig Face (replaces magnifying glass)
    local pigContainer, pigEyes = createPigFace(header, 30)
    pigContainer.Position = UDim2.new(0, 8, 0, 6)
    
    -- Title
    safeCreate("TextLabel", {
        Size = UDim2.new(0, 250, 1, 0),
        Position = UDim2.new(0, 45, 0, 0),
        Text = "Argument Discovery Suite",
        TextColor3 = COLORS.ACCENT,
        BackgroundTransparency = 1,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header
    })
    
    safeCreate("TextLabel", {
        Size = UDim2.new(0, 45, 0, 18),
        Position = UDim2.new(1, -90, 0, 12),
        Text = "v2.0",
        TextColor3 = COLORS.GRAY_DARK,
        BackgroundTransparency = 1,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        Parent = header
    })
    
    local closeBtn = safeCreate("TextButton", {
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -35, 0, 7),
        Text = "✖",
        TextColor3 = COLORS.RED,
        BackgroundColor3 = COLORS.BG_TERTIARY,
        BorderSizePixel = 0,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        Parent = header
    })
    safeCreate("UICorner", {CornerRadius = UDim.new(0, 8), Parent = closeBtn})
    closeBtn.MouseEnter:Connect(function()
        closeBtn.BackgroundColor3 = COLORS.RED; closeBtn.TextColor3 = COLORS.WHITE
    end)
    closeBtn.MouseLeave:Connect(function()
        closeBtn.BackgroundColor3 = COLORS.BG_TERTIARY; closeBtn.TextColor3 = COLORS.RED
    end)
    closeBtn.MouseButton1Click:Connect(function()
        State.isRunning = false
        screenGui:Destroy()
    end)
    
    -- ============================================================
    -- DRAG SYSTEM
    -- ============================================================
    local dragging = false
    local dragStart = nil
    local frameStart = nil
    
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            frameStart = mainFrame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                        input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local vp = workspace.CurrentCamera.ViewportSize
            local nx = math.clamp(frameStart.X.Offset + delta.X, -mainFrame.AbsoluteSize.X + 50, vp.X - 50)
            local ny = math.clamp(frameStart.Y.Offset + delta.Y, 0, vp.Y - 50)
            mainFrame.Position = UDim2.new(0, nx, 0, ny)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    -- ============================================================
    -- STATS PANEL
    -- ============================================================
    local statsPanel = safeCreate("Frame", {
        Size = UDim2.new(0.9, 0, 0, 50),
        Position = UDim2.new(0.05, 0, 0, 50),
        BackgroundColor3 = COLORS.BG_SECONDARY,
        BorderSizePixel = 0,
        Parent = mainFrame
    })
    safeCreate("UICorner", {CornerRadius = UDim.new(0, 10), Parent = statsPanel})
    
    local statsLabel = safeCreate("TextLabel", {
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        Text = "Sources: 0 | Fuzz: 0/0 | Sniff: 0 | DB: 0 sigs",
        TextColor3 = COLORS.WHITE,
        BackgroundTransparency = 1,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = statsPanel
    })
    
    -- ============================================================
    -- STATUS
    -- ============================================================
    local statusBar = safeCreate("Frame", {
        Size = UDim2.new(0.9, 0, 0, 26),
        Position = UDim2.new(0.05, 0, 0, 108),
        BackgroundColor3 = COLORS.BG_SECONDARY,
        BorderSizePixel = 0,
        Parent = mainFrame
    })
    safeCreate("UICorner", {CornerRadius = UDim.new(0, 8), Parent = statusBar})
    
    local statusDot = safeCreate("Frame", {
        Size = UDim2.new(0, 7, 0, 7),
        Position = UDim2.new(0, 7, 0.5, -3),
        BackgroundColor3 = COLORS.GREEN,
        BorderSizePixel = 0,
        Parent = statusBar
    })
    safeCreate("UICorner", {CornerRadius = UDim.new(1, 0), Parent = statusDot})
    
    local statusLabel = safeCreate("TextLabel", {
        Size = UDim2.new(1, -22, 1, 0),
        Position = UDim2.new(0, 20, 0, 0),
        Text = "🟢 Ready - Run ALL 8 STEPS",
        TextColor3 = COLORS.GREEN,
        BackgroundTransparency = 1,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = statusBar
    })
    
    -- ============================================================
    -- BUTTONS
    -- ============================================================
    local btnSection = safeCreate("Frame", {
        Size = UDim2.new(0.9, 0, 0, 260),
        Position = UDim2.new(0.05, 0, 0, 143),
        BackgroundTransparency = 1,
        Parent = mainFrame
    })
    
    local function createButton(name, text, position, color, callback)
        local btn = safeCreate("TextButton", {
            Name = name,
            Size = UDim2.new(0.47, 0, 0, 32),
            Position = position,
            Text = text,
            TextColor3 = COLORS.WHITE,
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            TextSize = 10,
            Font = Enum.Font.GothamBold,
            AutoButtonColor = false,
            Parent = btnSection
        })
        safeCreate("UICorner", {CornerRadius = UDim.new(0, 8), Parent = btn})
        btn.MouseEnter:Connect(function() pcall(function() btn.BackgroundColor3 = color:Lerp(COLORS.WHITE, 0.2) end) end)
        btn.MouseLeave:Connect(function() pcall(function() btn.BackgroundColor3 = color end) end)
        btn.MouseButton1Down:Connect(function() pcall(function() btn.BackgroundColor3 = color:Lerp(COLORS.WHITE, 0.35) end) end)
        btn.MouseButton1Up:Connect(function() pcall(function() btn.BackgroundColor3 = color:Lerp(COLORS.WHITE, 0.2) end) end)
        btn.MouseButton1Click:Connect(function() pcall(callback) end)
        return btn
    end
    
    -- Row 1: Steps 1-3
    createButton("Step1", "1️⃣ READ SOURCES",
        UDim2.new(0, 0, 0, 0), COLORS.TEAL,
        function()
            task.spawn(function()
                statusLabel.Text = "1️⃣ Reading sources..."
                statusLabel.TextColor3 = COLORS.TEAL
                statusDot.BackgroundColor3 = COLORS.TEAL
                SourceReader:ScanTargetModules()
                statusLabel.Text = "✅ Sources: " .. State.sourceReadSuccess
                statusLabel.TextColor3 = COLORS.GREEN
                statusDot.BackgroundColor3 = COLORS.GREEN
            end)
        end
    )
    
    createButton("Step4", "4️⃣ FUZZ IMPORTANT",
        UDim2.new(0.53, 0, 0, 0), COLORS.GOLD,
        function()
            task.spawn(function()
                statusLabel.Text = "4️⃣ Fuzzing..."
                statusLabel.TextColor3 = COLORS.GOLD
                statusDot.BackgroundColor3 = COLORS.GOLD
                ArgumentFuzzer:FuzzImportantOnly()
                statusLabel.Text = "✅ Fuzz: " .. State.fuzzTotalTests
                statusLabel.TextColor3 = COLORS.GREEN
                statusDot.BackgroundColor3 = COLORS.GREEN
            end)
        end
    )
    
    -- Row 2: Steps 4-5 Full
    createButton("Step4Full", "4️⃣-5️⃣ FUZZ ALL",
        UDim2.new(0, 0, 0, 38), COLORS.ORANGE,
        function()
            task.spawn(function()
                statusLabel.Text = "4️⃣-5️⃣ Fuzzing ALL..."
                statusLabel.TextColor3 = COLORS.ORANGE
                statusDot.BackgroundColor3 = COLORS.ORANGE
                ArgumentFuzzer:FuzzAllRemotes()
                statusLabel.Text = "✅ Fuzz done: " .. State.fuzzTotalTests
                statusLabel.TextColor3 = COLORS.GREEN
                statusDot.BackgroundColor3 = COLORS.GREEN
            end)
        end
    )
    
    createButton("Step6", "6️⃣ MOUNT SNIFFERS",
        UDim2.new(0.53, 0, 0, 38), COLORS.CYAN,
        function()
            PassiveSniffer:MountAllSniffers()
            statusLabel.Text = "6️⃣ Sniffers active: " .. State.sniffCount
            statusLabel.TextColor3 = COLORS.CYAN
            statusDot.BackgroundColor3 = COLORS.CYAN
        end
    )
    
    -- Row 3: Steps 7-8
    createButton("Step7", "7️⃣ BUILD DB",
        UDim2.new(0, 0, 0, 76), COLORS.PURPLE,
        function()
            local db = SignatureDatabase:Build()
            if db then
                local verified = 0
                for _, sig in ipairs(db.signatures) do if sig.verified then verified = verified + 1 end end
                statusLabel.Text = "7️⃣ DB: " .. #db.signatures .. " sigs (" .. verified .. " verified)"
                statusLabel.TextColor3 = COLORS.PURPLE
                statusDot.BackgroundColor3 = COLORS.PURPLE
            end
        end
    )
    
    createButton("Step8", "8️⃣ TEST EXPLOITS",
        UDim2.new(0.53, 0, 0, 76), COLORS.PINK,
        function()
            task.spawn(function()
                statusLabel.Text = "8️⃣ Testing..."
                statusLabel.TextColor3 = COLORS.PINK
                statusDot.BackgroundColor3 = COLORS.PINK
                ExploitTester:RunAllVerifiedExploits()
                statusLabel.Text = "8️⃣ Done: " .. State.exploitSuccess .. "/" .. State.exploitTests
                statusLabel.TextColor3 = COLORS.GREEN
                statusDot.BackgroundColor3 = COLORS.GREEN
            end)
        end
    )
    
    -- Row 4: ALL STEPS
    createButton("RunAll", "⚡ RUN ALL 8 STEPS",
        UDim2.new(0, 0, 0, 114), Color3.fromRGB(0, 200, 100),
        function()
            task.spawn(function()
                statusLabel.Text = "⚡ Running ALL steps..."
                statusLabel.TextColor3 = COLORS.GREEN
                statusDot.BackgroundColor3 = COLORS.GREEN
                
                SourceReader:ScanTargetModules()
                ArgumentFuzzer:FuzzImportantOnly()
                PassiveSniffer:MountAllSniffers()
                local db = SignatureDatabase:Build()
                ExploitTester:RunAllVerifiedExploits()
                
                local verified = 0
                if db and db.signatures then for _, sig in ipairs(db.signatures) do if sig.verified then verified = verified + 1 end end end
                statusLabel.Text = "✅ ALL DONE! " .. verified .. " verified sigs"
                statusLabel.TextColor3 = COLORS.GREEN
                statusDot.BackgroundColor3 = COLORS.GREEN
                addLog("✅ ALL 8 STEPS COMPLETE!", COLORS.GREEN)
            end)
        end
    )
    
    -- Row 5: Utilities
    createButton("CopyLog", "📋 COPY LOG",
        UDim2.new(0, 0, 0, 152), Color3.fromRGB(100, 100, 160),
        function()
            local text = "=== ARGUMENT DISCOVERY SUITE LOG ===\n"
            text = text .. "Place: 89231719412825 | " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n"
            text = text .. string.rep("=", 60) .. "\n"
            text = text .. "Sources: " .. State.sourceReadSuccess .. " | Fuzz: " .. State.fuzzSuccessTests .. "/" .. State.fuzzTotalTests .. "\n"
            text = text .. "Sniffed: " .. State.sniffCount .. " | DB: " .. (State.signatureDB.signatures and #State.signatureDB.signatures or 0) .. " sigs\n"
            text = text .. "Exploits: " .. State.exploitSuccess .. "/" .. State.exploitTests .. "\n\n"
            for _, log in ipairs(State.logs) do text = text .. "[" .. log.time .. "] " .. log.text .. "\n" end
            text = text .. "\n" .. string.rep("=", 60) .. "\nSIGNATURE DATABASE (JSON):\n" .. HttpService:JSONEncode(State.signatureDB)
            
            local copied = false
            pcall(function()
                if setclipboard then setclipboard(text); copied = true
                elseif syn and syn.write_clipboard then syn.write_clipboard(text); copied = true
                elseif writefile then writefile("discovery_log.txt", text); copied = true end
            end)
            
            if copied then
                statusLabel.Text = "📋 Copied to clipboard!"
                statusLabel.TextColor3 = COLORS.GREEN
                statusDot.BackgroundColor3 = COLORS.GREEN
            else
                print(text)
                statusLabel.Text = "📋 Printed to console (F9)"
                statusLabel.TextColor3 = COLORS.YELLOW
                statusDot.BackgroundColor3 = COLORS.YELLOW
            end
        end
    )
    
    createButton("Report", "📊 EXPORT JSON",
        UDim2.new(0.53, 0, 0, 152), COLORS.GOLD,
        function()
            local report = {
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                placeId = 89231719412825,
                summary = {
                    sourcesRead = State.sourceReadSuccess,
                    sourcesFailed = State.sourceReadFailed,
                    fuzzTotal = State.fuzzTotalTests,
                    fuzzSuccess = State.fuzzSuccessTests,
                    sniffedPackets = State.sniffCount,
                    dbSignatures = State.signatureDB.signatures and #State.signatureDB.signatures or 0,
                    exploitsRun = State.exploitTests,
                    exploitsSuccess = State.exploitSuccess
                },
                sourceModules = {},
                fuzzResults = {},
                sniffedPackets = {},
                signatureDB = State.signatureDB
            }
            for _, mod in ipairs(State.sourceModules) do table.insert(report.sourceModules, { path = mod.path, size = mod.size, signatures = mod.signatures }) end
            for _, result in ipairs(State.fuzzResults) do table.insert(report.fuzzResults, { remote = result.remote, type = result.type, validCount = #result.validSignatures, validSignatures = result.validSignatures }) end
            for _, packet in ipairs(State.sniffedPackets) do if #report.sniffedPackets < 50 then table.insert(report.sniffedPackets, { remote = packet.remote, direction = packet.direction, args = packet.args }) end end
            local json = HttpService:JSONEncode(report)
            print("[EXPORT]\n" .. json)
            pcall(function() if writefile then writefile("argument_discovery_report.json", json) end end)
            statusLabel.Text = "📊 Exported (F9 + file)"
            statusLabel.TextColor3 = COLORS.GOLD
            statusDot.BackgroundColor3 = COLORS.GOLD
            addLog("📊 Report exported", COLORS.GOLD)
        end
    )
    
    -- Row 6
    createButton("ClearLog", "🗑️ CLEAR ALL",
        UDim2.new(0, 0, 0, 190), Color3.fromRGB(120, 120, 140),
        function()
            State.logs = {}
            State.sourceModules = {}
            State.sourceReadSuccess = 0
            State.sourceReadFailed = 0
            State.fuzzTotalTests = 0
            State.fuzzSuccessTests = 0
            State.fuzzResults = {}
            State.sniffedPackets = {}
            State.sniffCount = 0
            State.argumentSignatures = {}
            State.signatureDB = {}
            State.exploitTests = 0
            State.exploitSuccess = 0
            ArgumentFuzzer.testResults = {}
            statusLabel.Text = "🗑️ All cleared"
            statusLabel.TextColor3 = COLORS.GRAY
            statusDot.BackgroundColor3 = COLORS.GRAY
            addLog("🗑️ All data cleared", COLORS.GRAY)
        end
    )
    
    createButton("CloseBtn", "✖ CLOSE",
        UDim2.new(0.53, 0, 0, 190), COLORS.RED_DIM,
        function()
            State.isRunning = false
            screenGui:Destroy()
        end
    )
    
    -- ============================================================
    -- LOG
    -- ============================================================
    safeCreate("TextLabel", {
        Size = UDim2.new(0.9, 0, 0, 16),
        Position = UDim2.new(0.05, 0, 0, 410),
        Text = "📜 DISCOVERY LOG",
        TextColor3 = COLORS.GRAY,
        BackgroundTransparency = 1,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = mainFrame
    })
    
    local logFrame = safeCreate("ScrollingFrame", {
        Size = UDim2.new(0.9, 0, 0, 90),
        Position = UDim2.new(0.05, 0, 0, 426),
        BackgroundColor3 = COLORS.BG_SECONDARY,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = COLORS.ACCENT,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = mainFrame
    })
    safeCreate("UICorner", {CornerRadius = UDim.new(0, 6), Parent = logFrame})
    safeCreate("UIListLayout", {Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder, Parent = logFrame})
    
    -- ============================================================
    -- START PIG BLINK LOOP
    -- ============================================================
    startPigBlinkLoop(pigEyes, function() return State.isRunning end)
    
    -- ============================================================
    -- RETURN GUI API
    -- ============================================================
    return {
        screenGui = screenGui,
        updateStats = function()
            local dbCount = State.signatureDB.signatures and #State.signatureDB.signatures or 0
            statsLabel.Text = string.format(
                "Sources: %d | Fuzz: %d/%d | Sniff: %d | DB: %d sigs | Exploit: %d/%d",
                State.sourceReadSuccess,
                State.fuzzSuccessTests, State.fuzzTotalTests,
                State.sniffCount,
                dbCount,
                State.exploitSuccess, State.exploitTests
            )
        end,
        updateStatus = function(text, color)
            statusLabel.Text = text
            if color then statusLabel.TextColor3 = color; statusDot.BackgroundColor3 = color end
        end,
        addLogEntry = function(text, color)
            color = color or COLORS.WHITE
            local entry = safeCreate("TextLabel", {
                Text = "[" .. os.date("%H:%M:%S") .. "] " .. text,
                TextColor3 = color,
                BackgroundTransparency = 1,
                TextSize = 9,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -8, 0, 13),
                Parent = logFrame
            })
            local labels = {}
            for _, c in ipairs(logFrame:GetChildren()) do if c:IsA("TextLabel") then table.insert(labels, c) end end
            while #labels > 70 do pcall(function() labels[1]:Destroy() end); table.remove(labels, 1) end
        end
    }
end

--------------------------------------------------------------------------------
-- CREATE GUI
--------------------------------------------------------------------------------
local gui = createDiscoveryGUI()

-- Override addLog
local originalAddLog = addLog
addLog = function(message, color)
    originalAddLog(message, color)
    if gui then
        gui.addLogEntry(message, color)
        gui.updateStats()
    end
end

if gui then
    addLog("🔬 Argument Discovery Suite v2.0 Ready", COLORS.ACCENT)
    addLog("8 Steps: Source → Fuzz → Sniff → DB → Exploit", COLORS.CYAN)
    gui.updateStatus("🟢 Ready - Click steps or RUN ALL", COLORS.GREEN)
end

--------------------------------------------------------------------------------
-- AUTO-MOUNT SNIFFERS
--------------------------------------------------------------------------------
task.spawn(function()
    task.wait(1)
    PassiveSniffer:MountAllSniffers()
    addLog("✅ Auto-mounted sniffers", COLORS.CYAN)
end)

--------------------------------------------------------------------------------
-- PERIODIC STATS UPDATE
--------------------------------------------------------------------------------
task.spawn(function()
    while State.isRunning do
        task.wait(0.5)
        if gui then gui.updateStats() end
    end
end)

--------------------------------------------------------------------------------
-- EXPORT
--------------------------------------------------------------------------------
_G.ArgumentDiscovery = {
    SourceReader = SourceReader,
    ArgumentFuzzer = ArgumentFuzzer,
    PassiveSniffer = PassiveSniffer,
    SignatureDatabase = SignatureDatabase,
    ExploitTester = ExploitTester,
    State = State,
    GUI = gui,
    RunAll = function()
        task.spawn(function()
            SourceReader:ScanTargetModules()
            ArgumentFuzzer:FuzzImportantOnly()
            PassiveSniffer:MountAllSniffers()
            SignatureDatabase:Build()
            ExploitTester:RunAllVerifiedExploits()
        end)
    end,
    RunStep1 = function() SourceReader:ScanTargetModules() end,
    RunStep4 = function() ArgumentFuzzer:FuzzImportantOnly() end,
    RunStep5 = function() ArgumentFuzzer:FuzzAllRemotes() end,
    RunStep6 = function() PassiveSniffer:MountAllSniffers() end,
    RunStep7 = function() return SignatureDatabase:Build() end,
    RunStep8 = function() ExploitTester:RunAllVerifiedExploits() end,
    GetDB = function() return State.signatureDB end,
    CopyLog = function()
        local text = "=== DISCOVERY LOG ===\n"
        for _, log in ipairs(State.logs) do text = text .. "[" .. log.time .. "] " .. log.text .. "\n" end
        text = text .. "\n=== SIGNATURE DB ===\n" .. HttpService:JSONEncode(State.signatureDB)
        pcall(function()
            if setclipboard then setclipboard(text)
            elseif syn and syn.write_clipboard then syn.write_clipboard(text)
            elseif writefile then writefile("discovery_log.txt", text) end
        end)
        return text
    end
}

print([[
╔══════════════════════════════════════╗
║ 🔬 ARGUMENT DISCOVERY SUITE v2.0    ║
║ ════════════════════════════════════ ║
║ 1️⃣  Source Code Reader              ║
║ 2️⃣  Source Code Reader (cont.)      ║
║ 3️⃣  Source Code Reader (cont.)      ║
║ 4️⃣  Argument Fuzzer (Important)     ║
║ 5️⃣  Argument Fuzzer (ALL)           ║
║ 6️⃣  Passive Sniffer                 ║
║ 7️⃣  Signature Database Builder      ║
║ 8️⃣  Exploit Tester                  ║
║ ════════════════════════════════════ ║
║ ✅ Draggable GUI with PIG FACE      ║
║ ✅ COPY LOG                          ║
║ ✅ EXPORT JSON                       ║
║ ✅ RUN ALL 8 STEPS                   ║
║ Place: 89231719412825                ║
╚══════════════════════════════════════╝
]])

print("Commands:")
print("  _G.ArgumentDiscovery.RunAll()          -- Run ALL 8 steps")
print("  _G.ArgumentDiscovery.RunStep1()        -- Read sources")
print("  _G.ArgumentDiscovery.RunStep4()        -- Fuzz important")
print("  _G.ArgumentDiscovery.RunStep5()        -- Fuzz ALL")
print("  _G.ArgumentDiscovery.RunStep7()        -- Build DB")
print("  _G.ArgumentDiscovery.RunStep8()        -- Test exploits")
print("  _G.ArgumentDiscovery.GetDB()           -- Get signature DB")
print("  _G.ArgumentDiscovery.CopyLog()         -- Copy everything")
