-- SERVICES
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

math.randomseed(tick())

-- PET TABLE (EXTENDED)
local petChances = {
    ["Common Egg"] = {"Dog", "Bunny", "Golden Lab"},
    ["Uncommon Egg"] = {"Cat", "Chicken", "Black Bunny", "Deer"},
    ["Rare Egg"] = {"Pig", "Monkey", "Rooster", "Spotted Deer"},
    ["Night Egg"] = {"Frog", "Hedgehog", "Mole", "Echo Frog", "Night Owl", "Raccoon"},
    ["Dinosaur Egg"] = {"Raptor", "Triceratops", "Stegosaurus", "T-Rex"},
    ["Primal Egg"] = {"Parasaurolophus", "Iguanodon", "Pachycephalosaurus"},
    ["Zen Egg"] = {"Shiba Inu", "Nihonzaru", "Tanuki", "Kitsune"},
    ["Paradise Egg"] = {"Ostrich", "Peacock", "Capybara", "Mimic Octopus"},
    ["Bug Egg"] = {"Dragonfly"},
}

local ESP_ENABLED = true
local AUTO_RANDOM = false -- Default to off

local divinePets = {
    ["Raccoon"] = true,
    ["Dragonfly"] = true,
    ["Mimic Octopus"] = true,
    ["Kitsune"] = true,
    ["T-Rex"] = true,
}

-- GUI SETUP
local mainGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
mainGui.Name = "Pet Randomizer by Jmcxz"

local frame = Instance.new("Frame", mainGui)
frame.Size = UDim2.new(0, 280, 0, 270)
frame.Position = UDim2.new(0, 40, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)

local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(255, 0, 130)
stroke.Thickness = 2

local title = Instance.new("TextLabel", frame)
title.Text = "Pet Randomizer by Jmcxz 🔥"
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 20

-- Title pulsing
RunService.RenderStepped:Connect(function()
    local t = tick()
    local pulse = 0.5 + 0.5 * math.sin(t * 2)
    title.TextColor3 = Color3.fromRGB(255, math.floor(100 + pulse * 155), 255)
end)

-- Frame Dragging
local dragging = false
local dragOffset
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragOffset = Vector2.new(mouse.X - frame.Position.X.Offset, mouse.Y - frame.Position.Y.Offset)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
RunService.RenderStepped:Connect(function()
    if dragging then
        frame.Position = UDim2.new(0, mouse.X - dragOffset.X, 0, mouse.Y - dragOffset.Y)
    end
end)

-- RARITY TAGS
local function getRarityInfo(petName)
    if divinePets[petName] then
        return "[Divine]", Color3.fromRGB(255, 215, 0)
    end
    return "[Normal]", Color3.fromRGB(255, 255, 255)
end

-- Clear ESP
local function clearESP(model)
    local part = model:FindFirstChildWhichIsA("BasePart")
    if not part then return end
    local old = part:FindFirstChild("PetESP")
    if old then old:Destroy() end
end

-- Show ESP
local function showPetESP(model, name)
    if not ESP_ENABLED then return end
    local part = model:FindFirstChildWhichIsA("BasePart")
    if not part then return end

    clearESP(model)

    local espGui = Instance.new("BillboardGui", part)
    espGui.Name = "PetESP"
    espGui.Size = UDim2.new(0, 200, 0, 60)
    espGui.StudsOffset = Vector3.new(0, 3, 0)
    espGui.AlwaysOnTop = true

    local petOnly = name:match("→ (.+)")
    local rarityTag, textColor = getRarityInfo(petOnly)

    local line1 = Instance.new("TextLabel", espGui)
    line1.Size = UDim2.new(1, 0, 0.5, 0)
    line1.Position = UDim2.new(0, 0, 0, 0)
    line1.BackgroundTransparency = 1
    line1.Font = Enum.Font.GothamBold
    line1.TextScaled = true
    line1.TextColor3 = textColor
    line1.Text = rarityTag .. " " .. name

    local line2 = Instance.new("TextLabel", espGui)
    line2.Size = UDim2.new(1, 0, 0.5, 0)
    line2.Position = UDim2.new(0, 0, 0.5, 0)
    line2.BackgroundTransparency = 1
    line2.Font = Enum.Font.Gotham
    line2.TextScaled = true
    line2.TextColor3 = Color3.new(0.8, 0.8, 0.8)

    for _, pet in ipairs(player.Character and player.Character:GetChildren() or {}) do
        if pet.Name == petOnly then
            local weight = pet:FindFirstChild("Weight")
            local age = pet:FindFirstChild("Age")
            if weight and age then
                line2.Text = "[" .. string.format("%.2f", weight.Value) .. " KG] [Age " .. age.Value .. "]"
            end
        end
    end

    if rarityTag == "[Divine]" then
        local glow = Instance.new("UIStroke", line1)
        glow.Color = textColor
        glow.Thickness = 2
        glow.Transparency = 0.2
    end
end

-- Egg Logic
local function getNearbyEggs(radius)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return {} end
    local eggs = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and petChances[obj.Name] then
            local dist = (obj:GetModelCFrame().Position - root.Position).Magnitude
            if dist <= (radius or 60) then
                table.insert(eggs, obj)
            end
        end
    end
    return eggs
end

local function randomizeEggs()
    for _, egg in ipairs(getNearbyEggs()) do
        clearESP(egg)
        local pets = petChances[egg.Name]
        if pets then
            local pet = pets[math.random(1, #pets)]
            showPetESP(egg, egg.Name .. " → " .. pet)
        end
    end
end

-- RANDOM BUTTON
local nextRandomizeTime = 0

local randomBtn = Instance.new("TextButton", frame)
randomBtn.Size = UDim2.new(1, -20, 0, 40)
randomBtn.Position = UDim2.new(0, 10, 0, 40)
randomBtn.BackgroundColor3 = Color3.fromRGB(90, 0, 150)
randomBtn.TextColor3 = Color3.new(1, 1, 1)
randomBtn.Font = Enum.Font.GothamBold
randomBtn.TextSize = 18
randomBtn.Text = "🎲 Randomize Now"
Instance.new("UICorner", randomBtn).CornerRadius = UDim.new(0, 10)

randomBtn.MouseButton1Click:Connect(function()
    local now = tick()
    if now >= nextRandomizeTime then
        randomizeEggs()
        nextRandomizeTime = now + 1.5
    end
end)

-- TOGGLE ESP
local espBtn = Instance.new("TextButton", frame)
espBtn.Size = UDim2.new(1, -20, 0, 30)
espBtn.Position = UDim2.new(0, 10, 0, 90)
espBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
espBtn.TextColor3 = Color3.new(1, 1, 1)
espBtn.Font = Enum.Font.GothamBold
espBtn.TextSize = 16
espBtn.Text = "👁️ ESP: ON"
Instance.new("UICorner", espBtn).CornerRadius = UDim.new(0, 8)

espBtn.MouseButton1Click:Connect(function()
    ESP_ENABLED = not ESP_ENABLED
    espBtn.Text = ESP_ENABLED and "👁️ ESP: ON" or "👁️ ESP: OFF"
    for _, egg in ipairs(getNearbyEggs()) do
        clearESP(egg)
        if ESP_ENABLED then
            local pets = petChances[egg.Name]
            local pet = pets and pets[math.random(1, #pets)] or "?"
            showPetESP(egg, egg.Name .. " → " .. pet)
        end
    end
end)

-- Toggle Auto-Randomizer Button
local autoRandomBtn = Instance.new("TextButton", frame)
autoRandomBtn.Size = UDim2.new(1, -20, 0, 30)
autoRandomBtn.Position = UDim2.new(0, 10, 0, 130)
autoRandomBtn.BackgroundColor3 = Color3.fromRGB(80, 120, 60)
autoRandomBtn.TextColor3 = Color3.new(1, 1, 1)
autoRandomBtn.Font = Enum.Font.GothamBold
autoRandomBtn.TextSize = 15
autoRandomBtn.Text = "🔁 Auto Random: OFF"
Instance.new("UICorner", autoRandomBtn).CornerRadius = UDim.new(0, 8)

autoRandomBtn.MouseButton1Click:Connect(function()
    AUTO_RANDOM = not AUTO_RANDOM
    autoRandomBtn.Text = AUTO_RANDOM and "🔁 Auto Random: ON" or "🔁 Auto Random: OFF"
end)

local timerLabel = Instance.new("TextLabel", frame)
timerLabel.Size = UDim2.new(1, -20, 0, 25)
timerLabel.Position = UDim2.new(0, 10, 0, 170)
timerLabel.BackgroundTransparency = 1
timerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
timerLabel.Font = Enum.Font.GothamBold
timerLabel.TextSize = 14
timerLabel.Text = "⏳ Cooldown: Ready"

-- Countdown timer display (smooth and accurate)
local function updateTimerLabel()
    while true do
        local now = tick()
        local timeLeft = math.max(nextRandomizeTime - now, 0)
        if timeLeft > 0 then
            timerLabel.Text = string.format("⏳ Cooldown: %.1fs", timeLeft)
        else
            timerLabel.Text = "⏳ Cooldown: Ready"
        end
        task.wait(0.05)
    end
end
task.spawn(updateTimerLabel)

-- Auto-random every 1.5s, using timestamps
task.spawn(function()
    while true do
        if AUTO_RANDOM then
            local now = tick()
            if now >= nextRandomizeTime then
                randomizeEggs()
                nextRandomizeTime = now + 1.5
            end
        end
        task.wait(0.1)
    end
end)
