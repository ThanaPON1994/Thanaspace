-- Blade Ball Hack Script for KRNL
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

-- สร้าง UI อย่างง่าย
local function CreateSimpleUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Parent = game:GetService("CoreGui")
    ScreenGui.Name = "BladeBallHackUI"
    
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0.3, 0, 0.4, 0)
    Frame.Position = UDim2.new(0.7, 0, 0.3, 0)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    Frame.BackgroundTransparency = 0.3
    Frame.Parent = ScreenGui
    
    -- ปุ่ม Auto Parry
    local AutoParryBtn = Instance.new("TextButton")
    AutoParryBtn.Name = "AutoParryBtn"
    AutoParryBtn.Size = UDim2.new(0.8, 0, 0.2, 0)
    AutoParryBtn.Position = UDim2.new(0.1, 0, 0.2, 0)
    AutoParryBtn.Text = "Auto Parry: OFF"
    AutoParryBtn.Parent = Frame
    
    AutoParryBtn.MouseButton1Click:Connect(function()
        _G.AutoParry = not _G.AutoParry
        AutoParryBtn.Text = "Auto Parry: " .. (_G.AutoParry and "ON" or "OFF")
    end)
    
    return ScreenGui
end

-- ค้นหา RemoteEvent
local ParryRemote = RS:FindFirstChild("ParryEvent") or RS:FindFirstChildOfClass("RemoteEvent")

if not ParryRemote then
    warn("⚠️ ไม่พบ RemoteEvent สำหรับ Parry!")
end

-- ฟังก์ชันหลัก
local function SafeParry()
    if ParryRemote then
        pcall(function()
            ParryRemote:FireServer()
            -- เพิ่ม delay สุ่มเพื่อป้องกันการตรวจจับ
            task.wait(math.random(80, 150)/1000)
        end)
    end
end

-- ตั้งค่า Keybind
UIS.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.F5 then
        _G.AutoParry = not _G.AutoParry
        print("Auto Parry:", _G.AutoParry and "ON" or "OFF")
    end
end)

-- สร้าง UI
local UI = CreateSimpleUI()

-- Loop หลัก
while task.wait(0.1) do
    if _G.AutoParry then
        SafeParry()
    end
end

print("Blade Ball Hack โหลดสำเร็จแล้ว!")
print("กด F5 เพื่อเปิด/ปิด Auto Parry")
