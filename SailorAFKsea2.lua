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

-- Black Screen
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 120, 0, 35)
toggleBtn.Position = UDim2.new(0.5, -60, 0, 10)
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

-- Island List
local allIslands = {
	{ name = "Punch", pos = Vector3.new(-1578.628784, 2.682251, 1848.186890) },
	{ name = "Bizzare", pos = Vector3.new(-3074.686523, 7.518671, -667.695129) },
	{ name = "StarterSea2", pos = Vector3.new(-322.588348, -3.666585, -119.547699) },
}

-- Players Count, max 2 players only in server
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

-- Anti-Anchor
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

-- Rejoining Stuff
game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
	if child.Name == "ErrorPrompt" then
		while true do
			TeleportService:Teleport(game.PlaceId, player)
			task.wait(0.1)
		end
	end
end)

-- Additional, Idk if this works? // Removing Texture & Decal
task.spawn(function()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Texture") or obj:IsA("Decal") then obj:Destroy() end
	end
	workspace.DescendantAdded:Connect(function(obj)
		if obj:IsA("Texture") or obj:IsA("Decal") then obj:Destroy() end
	end)
end)

-- Remote Stuff
task.spawn(function()
	while true do
		if isAllowed() then
			AbilityRemote:FireServer(2)
			ReplicatedStorage.Remotes.AntiAFKHeartbeat:FireServer()
		end
		task.wait(0.1)
	end
end)

-- Check if all nearby NPCs within range are dead
local RANGE = 50
local function allNearbyDead()
	if not character then return true end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return true end
	for _, obj in ipairs(workspace.NPCs:GetChildren()) do
		local hum = obj:FindFirstChildWhichIsA("Humanoid")
		local root = obj:FindFirstChild("HumanoidRootPart")
		if hum and root and hum.Health > 0 then
			if (root.Position - hrp.Position).Magnitude <= RANGE then
				return false
			end
		end
	end
	return true
end

-- Wait until all nearby NPCs are dead then move on
local function waitForClear()
	while not allNearbyDead() do
		task.wait(0.3)
	end
end

-- TP Stuff
while true do
	for _, island in ipairs(allIslands) do
		if isAllowed() then
			-- 1. Wait for nearby NPCs to die first
			waitForClear()

			-- 2. Fire portal remote
			pcall(function() PortalRemote:FireServer(island.name) end)
			task.wait(0.5) -- Wait for server to register portal

			-- 3. Teleport to position
			if character and character.Parent then
				character:PivotTo(CFrame.new(island.pos))
			end
		end
	end
end
