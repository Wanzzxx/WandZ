local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local Settings = settings()

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local AbilityRemote = ReplicatedStorage.AbilitySystem.Remotes.RequestAbility
local PortalRemote = ReplicatedStorage.Remotes.TeleportToPortal

Settings.Rendering.QualityLevel = 1

local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = player.PlayerGui

local blackScreen = Instance.new("Frame")
blackScreen.Size = UDim2.new(1, 0, 1, 0)
blackScreen.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
blackScreen.BorderSizePixel = 0
blackScreen.ZIndex = 10
blackScreen.Visible = true
blackScreen.Parent = screenGui

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 100, 0, 35)
toggleBtn.Position = UDim2.new(0.5, -50, 0, 10)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleBtn.TextColor3 = Color3.fromRGB(250, 250, 250)
toggleBtn.TextSize = 11
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Text = "Layar Ireng: Idup"
toggleBtn.BorderSizePixel = 0
toggleBtn.ZIndex = 11
toggleBtn.Parent = screenGui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)

toggleBtn.MouseButton1Click:Connect(function()
	blackScreen.Visible = not blackScreen.Visible
	toggleBtn.Text = blackScreen.Visible and "Layar Ireng: Idup" or "Layar Ireng: Ded"
end)

local islands = {
	{ name = "Lawless", pos = Vector3.new(54.656269, 6.627283, 1814.841064) },
	{ name = "Ninja", pos = Vector3.new(-1876.813843, 13.558611, -737.722473) },
	{ name = "Ninja", pos = Vector3.new(-2109.786865, 12.801344, -596.099854) },
	{ name = "Judgement", pos = Vector3.new(-1273.102905, 8.520060, -1191.468994) },
	{ name = "Judgement", pos = Vector3.new(-1421.924561, 21.431782, -1382.131836) },
	{ name = "Shinjuku", pos = Vector3.new(-21.131468, 9.205597, -1847.090454) },
	{ name = "Shinjuku", pos = Vector3.new(669.320557, 9.404799, -1693.271973) },
	{ name = "Slime", pos = Vector3.new(-1124.683838, 13.918226, 373.355255) },
	{ name = "Hollow", pos = Vector3.new(-568.870422, -1.921274, 1232.567139) },
}

local function isAllowed()
	return #Players:GetPlayers() <= 2
end

local function equipItem(char)
	local hum = char:WaitForChild("Humanoid")
	local backpack = player:WaitForChild("Backpack")
	task.wait(0.1)
	local item = backpack:FindFirstChild("Strongest In History")
	if item then hum:EquipTool(item) end
end

local function antiAnchor(char)
	local hrp = char:WaitForChild("HumanoidRootPart")
	hrp.Anchored = false
	hrp:GetPropertyChangedSignal("Anchored"):Connect(function()
		if hrp.Anchored then hrp.Anchored = false end
	end)
end

player.CharacterAdded:Connect(function(newChar)
	character = newChar
	equipItem(newChar)
	antiAnchor(newChar)
end)

equipItem(character)
antiAnchor(character)

game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
	if child.Name == "ErrorPrompt" then
		while true do
			TeleportService:Teleport(game.PlaceId, player)
			task.wait(0.1)
		end
	end
end)

task.spawn(function()
	while true do
		for _, obj in ipairs(workspace:GetChildren()) do
			if obj:IsA("Model") and obj:FindFirstChildWhichIsA("Humanoid") and obj ~= character then
				obj:Destroy()
			end
		end
		task.wait(1)
	end
end)

task.spawn(function()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Texture") or obj:IsA("Decal") then
			obj:Destroy()
		end
	end
	workspace.DescendantAdded:Connect(function(obj)
		if obj:IsA("Texture") or obj:IsA("Decal") then
			obj:Destroy()
		end
	end)
end)

task.spawn(function()
	while true do
		if isAllowed() then
			AbilityRemote:FireServer(2)
			ReplicatedStorage.Remotes.AntiAFKHeartbeat:FireServer()
		end
		task.wait(0.1)
	end
end)

while true do
	for _, island in ipairs(islands) do
		if isAllowed() then
			pcall(function() PortalRemote:FireServer(island.name) end)
			task.wait(0.3)
			if character and character.Parent then
				character:PivotTo(CFrame.new(island.pos))
			end
		end
		task.wait(0.8)
	end
end
