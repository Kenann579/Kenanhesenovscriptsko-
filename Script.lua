local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("WheelClickerGui") then
    playerGui.WheelClickerGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WheelClickerGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local wheelButton = Instance.new("TextButton")
wheelButton.Name = "MouseWheelBtn"
wheelButton.Size = UDim2.new(0, 65, 0, 65)
wheelButton.Position = UDim2.new(0.5, 10, 0.4, 0)
wheelButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
wheelButton.BackgroundTransparency = 0.2
wheelButton.Text = "WHEEL"
wheelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
wheelButton.Font = Enum.Font.GothamBold
wheelButton.TextSize = 12
wheelButton.Active = true
wheelButton.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = wheelButton

local stroke = Instance.new("UIStroke")
stroke.Thickness = 2
stroke.Color = Color3.fromRGB(255, 170, 0)
stroke.Parent = wheelButton

-- Draggable Logic
local dragging, dragStart, startPos = false, nil, nil
local hasMoved = false

wheelButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        hasMoved = false
        dragStart = input.Position
        startPos = wheelButton.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then 
                dragging = false 
            end
        end)
    end
end)

wheelButton.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        if delta.Magnitude > 5 then
            hasMoved = true 
        end
        wheelButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Tap-to-Ping Mode Logic
local waitingForPing = false

wheelButton.MouseButton1Click:Connect(function()
    if hasMoved then return end
    
    waitingForPing = not waitingForPing
    
    if waitingForPing then
        wheelButton.Text = "TAP MAP"
        wheelButton.BackgroundColor3 = Color3.fromRGB(200, 80, 0)
    else
        wheelButton.Text = "WHEEL"
        wheelButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    end
end)

-- Corrected Touch-to-Ping Listener
UserInputService.InputBegan:Connect(function(input)
    if not waitingForPing then return end
    
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        local px, py = input.Position.X, input.Position.Y
        
        -- Ignore if tapping the button itself
        local absPos = wheelButton.AbsolutePosition
        local absSize = wheelButton.AbsoluteSize
        if px >= absPos.X and px <= absPos.X + absSize.X and py >= absPos.Y and py <= absPos.Y + absSize.Y then
            return 
        end
        
        -- Adjust for mobile top-bar / core GUI inset offset
        local inset = GuiService:GetGuiInset()
        local correctedX = px
        local correctedY = py - inset.Y
        
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(correctedX, correctedY, 2, true, game, 0)
            task.wait(0.03)
            VirtualInputManager:SendMouseButtonEvent(correctedX, correctedY, 2, false, game, 0)
        end)
        
        -- Reset state
        waitingForPing = false
        wheelButton.Text = "WHEEL"
        wheelButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    end
end)
