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
local AUTO_RANDOM = true
local LOCKED_EGGS = {} -- [eggName] = petName or nil

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
frame.Size = UDim2.new(0, 320, 0, 320)
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
            -- Lock logic
            local lockedPet = LOCKED_EGGS[egg.Name]
            local pet
            if lockedPet then
                pet = lockedPet
            else
                pet = pets[math.random(1, #pets)]
            end
            showPetESP(egg, egg.Name .. " → " .. pet)
        end
    end
end

-- RANDOM BUTTON
local countdown = 0
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
    if countdown <= 0 then
        randomizeEggs()
        countdown = 5
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
            local pet
            local lockedPet = LOCKED_EGGS[egg.Name]
            if lockedPet then
                pet = lockedPet
            else
                pet = pets and pets[math.random(1, #pets)] or "?"
            end
            showPetESP(egg, egg.Name .. " → " .. pet)
        end
    end
end)

-- Auto Randomizer Labels
local autoLabel = Instance.new("TextLabel", frame)
autoLabel.Size = UDim2.new(1, -20, 0, 25)
autoLabel.Position = UDim2.new(0, 10, 0, 130)
autoLabel.BackgroundTransparency = 1
autoLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
autoLabel.Font = Enum.Font.GothamBold
autoLabel.TextSize = 14
autoLabel.Text = "🔁 Auto Random: Every 5s"

local timerLabel = Instance.new("TextLabel", frame)
timerLabel.Size = UDim2.new(1, -20, 0, 25)
timerLabel.Position = UDim2.new(0, 10, 0, 160)
timerLabel.BackgroundTransparency = 1
timerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
timerLabel.Font = Enum.Font.GothamBold
timerLabel.TextSize = 14
timerLabel.Text = "⏳ Cooldown: Ready"

-- STOP/START AUTO RANDOM BUTTON
local stopBtn = Instance.new("TextButton", frame)
stopBtn.Size = UDim2.new(1, -20, 0, 30)
stopBtn.Position = UDim2.new(0, 10, 0, 190)
stopBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
stopBtn.TextColor3 = Color3.new(1, 1, 1)
stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 16
stopBtn.Text = "⏹️ Stop Auto Random"
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 8)

stopBtn.MouseButton1Click:Connect(function()
    AUTO_RANDOM = not AUTO_RANDOM
    stopBtn.Text = AUTO_RANDOM and "⏹️ Stop Auto Random" or "▶️ Start Auto Random"
    autoLabel.Text = AUTO_RANDOM and "🔁 Auto Random: Every 5s" or "🔁 Auto Random: OFF"
end)

-- LOCK EGG GUI
local lockFrame = Instance.new("Frame", frame)
lockFrame.Size = UDim2.new(1, -20, 0, 60)
lockFrame.Position = UDim2.new(0, 10, 0, 230)
lockFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
lockFrame.BorderSizePixel = 0
Instance.new("UICorner", lockFrame).CornerRadius = UDim.new(0, 6)

local lockTitle = Instance.new("TextLabel", lockFrame)
lockTitle.Size = UDim2.new(1, 0, 0, 18)
lockTitle.Position = UDim2.new(0, 0, 0, 0)
lockTitle.BackgroundTransparency = 1
lockTitle.TextColor3 = Color3.fromRGB(255, 200, 130)
lockTitle.Font = Enum.Font.GothamBold
lockTitle.TextSize = 13
lockTitle.Text = "🔒 Lock Egg (Choose Egg & Pet)"

local eggDropdown = Instance.new("TextButton", lockFrame)
eggDropdown.Size = UDim2.new(0.5, -5, 0, 22)
eggDropdown.Position = UDim2.new(0, 0, 0, 20)
eggDropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
eggDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
eggDropdown.Font = Enum.Font.Gotham
eggDropdown.TextSize = 13
eggDropdown.Text = "Egg"
Instance.new("UICorner", eggDropdown).CornerRadius = UDim.new(0, 4)

local petDropdown = Instance.new("TextButton", lockFrame)
petDropdown.Size = UDim2.new(0.5, -5, 0, 22)
petDropdown.Position = UDim2.new(0.5, 5, 0, 20)
petDropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
petDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
petDropdown.Font = Enum.Font.Gotham
petDropdown.TextSize = 13
petDropdown.Text = "Pet"
Instance.new("UICorner", petDropdown).CornerRadius = UDim.new(0, 4)

local lockBtn = Instance.new("TextButton", lockFrame)
lockBtn.Size = UDim2.new(1, 0, 0, 18)
lockBtn.Position = UDim2.new(0, 0, 1, -18)
lockBtn.BackgroundColor3 = Color3.fromRGB(90, 0, 150)
lockBtn.TextColor3 = Color3.new(1, 1, 1)
lockBtn.Font = Enum.Font.GothamBold
lockBtn.TextSize = 13
lockBtn.Text = "Lock"
Instance.new("UICorner", lockBtn).CornerRadius = UDim.new(0, 4)

-- Dropdown logic
local selectedEgg, selectedPet = nil, nil

local function showEggMenu()
    local menu = Instance.new("Frame", frame)
    menu.Size = UDim2.new(0, 100, 0, 18 * #petChances)
    menu.Position = UDim2.new(0, lockFrame.Position.X.Offset + eggDropdown.Position.X.Offset, 0, lockFrame.Position.Y.Offset + eggDropdown.Position.Y.Offset + 22)
    menu.BackgroundColor3 = Color3.fromRGB(30,30,40)
    menu.BorderSizePixel = 0
    for i, eggName in ipairs((function()
        local arr = {}
        for k in pairs(petChances) do table.insert(arr, k) end
        table.sort(arr)
        return arr
    end)()) do
        local btn = Instance.new("TextButton", menu)
        btn.Size = UDim2.new(1, 0, 0, 18)
        btn.Position = UDim2.new(0, 0, 0, (i-1)*18)
        btn.BackgroundColor3 = Color3.fromRGB(50,50,70)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 12
        btn.Text = eggName
        btn.MouseButton1Click:Connect(function()
            selectedEgg = eggName
            eggDropdown.Text = eggName
            selectedPet = nil
            petDropdown.Text = "Pet"
            menu:Destroy()
        end)
    end
    menu.ZIndex = 15
    eggDropdown.MouseLeave:Connect(function() menu:Destroy() end)
end

local function showPetMenu()
    if not selectedEgg then return end
    local pets = petChances[selectedEgg]
    if not pets then return end
    local menu = Instance.new("Frame", frame)
    menu.Size = UDim2.new(0, 100, 0, 18 * #pets)
    menu.Position = UDim2.new(0, lockFrame.Position.X.Offset + petDropdown.Position.X.Offset, 0, lockFrame.Position.Y.Offset + petDropdown.Position.Y.Offset + 22)
    menu.BackgroundColor3 = Color3.fromRGB(30,30,40)
    menu.BorderSizePixel = 0
    for i, petName in ipairs(pets) do
        local btn = Instance.new("TextButton", menu)
        btn.Size = UDim2.new(1, 0, 0, 18)
        btn.Position = UDim2.new(0, 0, 0, (i-1)*18)
        btn.BackgroundColor3 = Color3.fromRGB(50,50,70)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 12
        btn.Text = petName
        btn.MouseButton1Click:Connect(function()
            selectedPet = petName
            petDropdown.Text = petName
            menu:Destroy()
        end)
    end
    menu.ZIndex = 15
    petDropdown.MouseLeave:Connect(function() menu:Destroy() end)
end

eggDropdown.MouseButton1Click:Connect(showEggMenu)
petDropdown.MouseButton1Click:Connect(showPetMenu)

lockBtn.MouseButton1Click:Connect(function()
    if selectedEgg and selectedPet then
        LOCKED_EGGS[selectedEgg] = selectedPet
        lockBtn.Text = "Locked!"
        task.wait(1)
        lockBtn.Text = "Lock"
    elseif selectedEgg then
        LOCKED_EGGS[selectedEgg] = nil
        lockBtn.Text = "Unlocked!"
        task.wait(1)
        lockBtn.Text = "Lock"
    end
end)

-- Clear ESP every second
task.spawn(function()
    while true do
        for _, egg in ipairs(getNearbyEggs()) do
            clearESP(egg)
        end
        task.wait(1)
    end
end)

-- Countdown timer display
task.spawn(function()
    while true do
        if countdown > 0 then
            countdown -= 1
            timerLabel.Text = "⏳ Cooldown: " .. countdown .. "s"
        else
            timerLabel.Text = "⏳ Cooldown: Ready"
        end
        task.wait(1)
    end
end)

-- Auto-random every 5s
task.spawn(function()
    while true do
        if AUTO_RANDOM then
            randomizeEggs()
            countdown = 5
        end
        task.wait(5)
    end
end)
