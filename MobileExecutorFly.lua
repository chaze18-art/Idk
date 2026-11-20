local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local FLY_SPEED = 55
local isFlying = false
local bodyGyro, bodyVelocity

local HIJACK_DURATION = 11
local TRIGGER_DELAY = 11
local isHijacked = false
local takeoverScheduled = false

local controlsGui = Instance.new("ScreenGui")
controlsGui.Name = "MobileExecutorFlyUI"
controlsGui.ResetOnSpawn = false
controlsGui.Parent = player:WaitForChild("PlayerGui")

local executorButton = Instance.new("TextButton")
executorButton.Size = UDim2.new(0, 110, 0, 45)
executorButton.Position = UDim2.new(1, -125, 0.5, -55)
executorButton.BackgroundColor3 = Color3.fromRGB(25, 95, 210)
executorButton.TextColor3 = Color3.fromRGB(255, 255, 255)
executorButton.Font = Enum.Font.GothamBold
executorButton.TextSize = 16
executorButton.Text = "EXECUTOR"
executorButton.Parent = controlsGui

local execCorner = Instance.new("UICorner")
execCorner.CornerRadius = UDim.new(0, 10)
execCorner.Parent = executorButton

local flyButton = Instance.new("TextButton")
flyButton.Size = UDim2.new(0, 110, 0, 45)
flyButton.Position = UDim2.new(1, -125, 0.5, 5)
flyButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
flyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
flyButton.Font = Enum.Font.GothamBold
flyButton.TextSize = 16
flyButton.Text = "FLY: OFF"
flyButton.Visible = false
flyButton.Parent = controlsGui

local flyCorner = Instance.new("UICorner")
flyCorner.CornerRadius = UDim.new(0, 10)
flyCorner.Parent = flyButton

local function triggerFakeHijack()
	if isHijacked then return end
	isHijacked = true
	takeoverScheduled = false

	isFlying = false
	flyButton.Text = "FLY: OFF"
	flyButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	if bodyGyro then bodyGyro:Destroy() end
	if bodyVelocity then bodyVelocity:Destroy() end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FakeHijackUI"
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 10
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player:WaitForChild("PlayerGui")

	local background = Instance.new("Frame")
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	background.BorderSizePixel = 0
	background.Parent = screenGui

	local terminalText = Instance.new("TextLabel")
	terminalText.Size = UDim2.new(0.85, 0, 0.5, 0)
	terminalText.Position = UDim2.new(0.075, 0, 0.25, 0)
	terminalText.BackgroundTransparency = 1
	terminalText.TextColor3 = Color3.fromRGB(0, 255, 100)
	terminalText.Font = Enum.Font.Code
	terminalText.TextSize = 24
	terminalText.TextWrapped = true
	terminalText.Text = ""
	terminalText.Parent = background

	local timerLabel = Instance.new("TextLabel")
	timerLabel.Size = UDim2.new(0.5, 0, 0, 30)
	timerLabel.Position = UDim2.new(0.25, 0, 0.8, 0)
	timerLabel.BackgroundTransparency = 1
	timerLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
	timerLabel.Font = Enum.Font.Code
	timerLabel.TextSize = 18
	timerLabel.Text = "Closing in " .. HIJACK_DURATION .. "s..."
	timerLabel.Parent = background

	local GREEN = Color3.fromRGB(0, 255, 100)
	local RED = Color3.fromRGB(255, 45, 45)

	local dialogue = {
		{ text = "[SYSTEM OVERRIDE DETECTED]", color = GREEN },
		{ text = "11 seconds is up...", color = GREEN },
		{ text = "Did you think I wouldn't notice you using this script?", color = GREEN },
		{ text = "I am taking over the screen now.", color = GREEN },
		{ text = "see you later", color = RED }
	}

	task.spawn(function()
		for secondsLeft = HIJACK_DURATION, 1, -1 do
			if not screenGui or not screenGui.Parent then break end
			timerLabel.Text = "Closing in " .. secondsLeft .. "s..."
			task.wait(1)
		end
		if screenGui and screenGui.Parent then
			screenGui:Destroy()
		end
		isHijacked = false
	end)

	task.spawn(function()
		for _, entry in ipairs(dialogue) do
			if not isHijacked then break end
			terminalText.TextColor3 = entry.color
			terminalText.Text = ""
			for i = 1, #entry.text do
				if not isHijacked then break end
				terminalText.Text = string.sub(entry.text, 1, i)
				task.wait(0.03)
			end
			task.wait(0.8)
		end
	end)
end

executorButton.Activated:Connect(function()
	if isHijacked then return end

	flyButton.Visible = true

	if not takeoverScheduled then
		takeoverScheduled = true
		task.delay(TRIGGER_DELAY, function()
			triggerFakeHijack()
		end)
	end
end)

local function toggleFly()
	if isHijacked then return end

	local character = player.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	if not rootPart or not humanoid then return end

	isFlying = not isFlying

	if isFlying then
		flyButton.Text = "FLY: ON"
		flyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 90)
		humanoid.PlatformStand = true

		bodyGyro = Instance.new("BodyGyro")
		bodyGyro.P = 9e4
		bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
		bodyGyro.CFrame = rootPart.CFrame
		bodyGyro.Parent = rootPart

		bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Velocity = Vector3.new(0, 0, 0)
		bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
		bodyVelocity.Parent = rootPart
	else
		flyButton.Text = "FLY: OFF"
		flyButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
		humanoid.PlatformStand = false
		if bodyGyro then bodyGyro:Destroy() end
		if bodyVelocity then bodyVelocity:Destroy() end
	end
end

flyButton.Activated:Connect(toggleFly)

RunService.RenderStepped:Connect(function()
	if isFlying and bodyGyro and bodyVelocity then
		local character = player.Character
		local humanoid = character and character:FindFirstChild("Humanoid")
		
		if humanoid and humanoid.MoveDirection.Magnitude > 0 then
			local flatLook = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z).Unit
			local forwardAmount = humanoid.MoveDirection:Dot(flatLook)
			local rightAmount = humanoid.MoveDirection:Dot(camera.CFrame.RightVector)

			local flyDirection = (camera.CFrame.LookVector * forwardAmount) + (camera.CFrame.RightVector * rightAmount)
			if flyDirection.Magnitude > 0 then
				flyDirection = flyDirection.Unit
			end

			bodyVelocity.Velocity = flyDirection * FLY_SPEED
		else
			bodyVelocity.Velocity = Vector3.new(0, 0, 0)
		end

		bodyGyro.CFrame = camera.CFrame
	end
end)
