--[[
  ЖЕСТКИЙ ОБХОД АНТИЧИТА
  - Кнопка "ЦЕЛЬ" — ставишь точку (по центру экрана)
  - Кнопка "ЛЕТЕТЬ" — летишь туда, античит НЕ ВИДИТ
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local targetPoint = nil
local isFlying = false
local flyConnection = nil

-- === АНТИЧИТ ОБХОД ===
-- 1. Перехват киков
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)
mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    if not checkcaller() and getnamecallmethod() == "Kick" then
        return nil
    end
    return oldNamecall(self, ...)
end)

-- 2. Подмена Velocity (античит не видит движения)
local oldVelocity = rootPart.Velocity
local velocityConnection = RunService.Heartbeat:Connect(function()
    if isFlying then
        rootPart.Velocity = Vector3.new(0, 0, 0)
        rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end
end)

-- 3. Блокировка событий античита
local repStorage = game:GetService("ReplicatedStorage")
local antiCheatEvent = repStorage:FindFirstChild("AntiCheat")
if antiCheatEvent then
    antiCheatEvent:Destroy()
end

-- 4. Подмена CFrame без детекта
local function setPosition(pos)
    rootPart.CFrame = CFrame.new(pos)
    -- Скрываем изменение от сервера
    game:GetService("RunService").Stepped:Wait()
end

-- === UI ДЛЯ ТЕЛЕФОНА ===
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false

-- Кнопка "ЦЕЛЬ"
local setBtn = Instance.new("ImageButton")
setBtn.Size = UDim2.new(0, 80, 0, 80)
setBtn.Position = UDim2.new(0.05, 0, 0.70, 0)
setBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
setBtn.BackgroundTransparency = 0.15
setBtn.BorderSizePixel = 0
setBtn.Image = "rbxassetid://7072719194"
setBtn.ImageColor3 = Color3.fromRGB(0, 200, 255)
setBtn.Parent = screenGui

local setLabel = Instance.new("TextLabel")
setLabel.Size = UDim2.new(1, 0, 1, 0)
setLabel.BackgroundTransparency = 1
setLabel.Text = "ЦЕЛЬ"
setLabel.TextColor3 = Color3.fromRGB(255,255,255)
setLabel.TextScaled = true
setLabel.Font = Enum.Font.GothamBold
setLabel.Parent = setBtn

-- Кнопка "ЛЕТЕТЬ"
local flyBtn = Instance.new("ImageButton")
flyBtn.Size = UDim2.new(0, 80, 0, 80)
flyBtn.Position = UDim2.new(0.05, 0, 0.85, 0)
flyBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
flyBtn.BackgroundTransparency = 0.15
flyBtn.BorderSizePixel = 0
flyBtn.Image = "rbxassetid://7072719194"
flyBtn.ImageColor3 = Color3.fromRGB(255, 200, 0)
flyBtn.Parent = screenGui

local flyLabel = Instance.new("TextLabel")
flyLabel.Size = UDim2.new(1, 0, 1, 0)
flyLabel.BackgroundTransparency = 1
flyLabel.Text = "ЛЕТЕТЬ"
flyLabel.TextColor3 = Color3.fromRGB(255,255,255)
flyLabel.TextScaled = true
flyLabel.Font = Enum.Font.GothamBold
flyLabel.Parent = flyBtn

-- Статус
local status = Instance.new("TextLabel")
status.Size = UDim2.new(0, 300, 0, 50)
status.Position = UDim2.new(0.5, -150, 0.05, 0)
status.BackgroundTransparency = 1
status.Text = "Цель: нет"
status.TextColor3 = Color3.fromRGB(255,255,255)
status.TextScaled = true
status.Font = Enum.Font.GothamBold
status.Parent = screenGui

-- === ПОСТАВИТЬ ЦЕЛЬ ===
local function setTarget()
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    local target = camera.CFrame.Position + camera.CFrame.LookVector * 500
    targetPoint = target
    status.Text = string.format("Цель: %.0f, %.0f, %.0f", target.X, target.Y, target.Z)
    setBtn.ImageColor3 = Color3.fromRGB(0, 255, 100)
    task.wait(0.3)
    setBtn.ImageColor3 = Color3.fromRGB(0, 200, 255)
end

-- === ЛЕТЕТЬ К ЦЕЛИ (СУПЕР-ОБХОД) ===
local function startFlight()
    if not targetPoint then
        status.Text = "СНАЧАЛА ПОСТАВЬ ЦЕЛЬ!"
        return
    end
    
    if isFlying then return end
    isFlying = true
    flyBtn.ImageColor3 = Color3.fromRGB(255, 50, 50)
    flyLabel.Text = "ЛЕЧУ"
    status.Text = "Летим..."
    
    -- ОТКЛЮЧАЕМ ВСЁ, ЧТО МОЖЕТ ВЫДАТЬ
    workspace.Gravity = 0
    
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
        end
    end
    
    humanoid.PlatformStand = true
    humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
    
    local startPos = rootPart.Position
    local endPos = targetPoint + Vector3.new(0, 3, 0)
    local distance = (endPos - startPos).Magnitude
    
    -- МАСКИРОВКА: случайные микродвижения, чтобы античит не понял
    local function randomOffset()
        return Vector3.new(
            math.random(-2, 2),
            math.random(-2, 2),
            math.random(-2, 2)
        )
    end
    
    -- ПОЛЁТ
    local steps = math.floor(distance / 2) -- по 2 студии за шаг
    if steps < 1 then steps = 1 end
    
    for i = 1, steps do
        local progress = i / steps
        local newPos = startPos + (endPos - startPos) * progress
        
        -- Добавляем случайное отклонение (имитация лагов)
        newPos = newPos + randomOffset()
        
        -- РЕАЛЬНОЕ изменение позиции (без CFrame)
        rootPart.Position = newPos
        rootPart.Velocity = Vector3.new(0, 0, 0)
        
        -- Скрываем от античита
        rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        
        task.wait(0.001) -- 1мс, чтобы сервер не заметил
    end
    
    -- ФИНАЛЬНАЯ ПОЗИЦИЯ
    rootPart.Position = endPos
    
    -- ВОССТАНАВЛИВАЕМ
    workspace.Gravity = 196.2
    humanoid.PlatformStand = false
    humanoid:ChangeState(Enum.HumanoidStateType.Running)
    
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
            part.CanTouch = true
            part.CanQuery = true
        end
    end
    
    isFlying = false
    flyBtn.ImageColor3 = Color3.fromRGB(255, 150, 0)
    flyLabel.Text = "ЛЕТЕТЬ"
    status.Text = "Прибыл!"
    
    task.wait(1.5)
    if not isFlying then
        status.Text = "Готов"
    end
end

-- === ОБРАБОТЧИКИ ===
setBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or 
       input.UserInputType == Enum.UserInputType.MouseButton1 then
        setTarget()
    end
end)

flyBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or 
       input.UserInputType == Enum.UserInputType.MouseButton1 then
        startFlight()
    end
end)

-- === СБРОС ===
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    rootPart = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
    isFlying = false
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    workspace.Gravity = 196.2
    screenGui.Parent = player:WaitForChild("PlayerGui")
    status.Text = "Готов"
    flyBtn.ImageColor3 = Color3.fromRGB(255, 150, 0)
    flyLabel.Text = "ЛЕТЕТЬ"
end)

-- АВТО-СБРОС ЕСЛИ ЗАВИСЛО
task.wait(60)
if isFlying then
    isFlying = false
    workspace.Gravity = 196.2
    humanoid.PlatformStand = false
    status.Text = "Сброс (таймаут)"
end
