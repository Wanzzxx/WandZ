local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local Settings = settings()

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local AbilityRemote = ReplicatedStorage.AbilitySystem.Remotes.RequestAbility
local PortalRemote = ReplicatedStorage.Remotes.TeleportToPortal

Settings.Rendering.QualityLevel = 1

-- Save File
local autoBossTP = true
pcall(function()
	local saved = readfile("autoBossTP.txt")
	autoBossTP = saved == "true"
end)

local function saveState()
	pcall(function() writefile("autoBossTP.txt", tostring(autoBossTP)) end)
end

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

-- Boss Toggle
local bossBtn = Instance.new("TextButton")
bossBtn.Size = UDim2.new(0, 120, 0, 35)
bossBtn.Position = UDim2.new(0.5, -60, 0, 55)
bossBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
bossBtn.TextSize = 11
bossBtn.Font = Enum.Font.GothamBold
bossBtn.Text = "Boss Farm Mode"
bossBtn.BorderSizePixel = 0
bossBtn.ZIndex = 11
bossBtn.Parent = screenGui
Instance.new("UICorner", bossBtn).CornerRadius = UDim.new(0, 6)

local function updateBossBtn()
	bossBtn.BackgroundColor3 = autoBossTP and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(180, 0, 0)
end

updateBossBtn()

bossBtn.MouseButton1Click:Connect(function()
	autoBossTP = not autoBossTP
	updateBossBtn()
	saveState()
end)

-- Island List
local allIslands = {
	{ name = "Lawless", pos = Vector3.new(54.656269, 6.627283, 1814.841064), boss = false },
	{ name = "Ninja", pos = Vector3.new(-1876.813843, 13.558611, -737.722473), boss = false },
	{ name = "Ninja", pos = Vector3.new(-2109.786865, 12.801344, -596.099854), boss = true }, -- Boss POS
	{ name = "Judgement", pos = Vector3.new(-1273.102905, 8.520060, -1191.468994), boss = false },
	{ name = "Shinjuku", pos = Vector3.new(-21.131468, 9.205597, -1847.090454), boss = false },
	{ name = "Shinjuku", pos = Vector3.new(669.320557, 9.404799, -1693.271973), boss = false },
	{ name = "SoulDominion", pos = Vector3.new(-1343.785156, 1604.373291, 1595.761963), boss = false },
	{ name = "Slime", pos = Vector3.new(-1124.683838, 13.918226, 373.355255), boss = false },
	{ name = "Hollow", pos = Vector3.new(-568.870422, -1.921274, 1232.567139), boss = true }, -- Boss POS
	{ name = "Sailor", pos = Vector3.new(249.287292, 7.593238, 926.742493), boss = true }, -- Boss POS
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
local RANGE = 20
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
		task.wait(0.1)
	end
end

-- Boss TP Stuff
while true do
	for _, island in ipairs(allIslands) do
		if island.boss and not autoBossTP then
			continue
		end
		if isAllowed() then
			pcall(function() PortalRemote:FireServer(island.name) end)
			task.wait(0.3) -- Quick wait after firing portal remote
			if character and character.Parent then
				character:PivotTo(CFrame.new(island.pos))
			end
			waitForClear() -- Wait until nearby NPCs are dead
		end
	end
end
