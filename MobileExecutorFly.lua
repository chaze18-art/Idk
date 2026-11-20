local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Flight Settings
local FLY_SPEED = 55
local isFlying = false
local bodyGyro, bodyVelocity

-- Hijack & Error Spam Settings
local HIJACK_DURATION = 11
local TRIGGER_DELAY = 11
local ERROR_COUNT = 14 -- How many Windows errors cascade diagonally
local MULTIPLY_ON_OK = true -- Tapping "OK" spawns 2 more Windows errors!
local isHijacked = false
local takeoverScheduled = false
local isCorrupted = false

-- Create the Mobile UI Container
local controlsGui = Instance.new("ScreenGui")
controlsGui.Name = "MobileExecutorFlyUI"
controlsGui.ResetOnSpawn = false
controlsGui.Parent = player:WaitForChild("PlayerGui")

-- 1. "EXECUTOR" Button
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

-- 2. "FLY: OFF" Button
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

-- Function to turn on thick black fog
local function activateBlackFog()
	local existingAtmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if existingAtmosphere then
		existingAtmosphere:Destroy()
	end

	Lighting.FogColor = Color3.fromRGB(0, 0, 0)
	Lighting.FogStart = 0
	Lighting.FogEnd = 45
	Lighting.Brightness = 0.5
	Lighting.OutdoorAmbient = Color3.fromRGB(15, 15, 15)
end

-- Create a single classic Windows XP/98 Error Box
local function spawnSingleWindowsError(parentGui, xOffset, yOffset, zIndex, messageText)
	local window = Instance.new("Frame")
	window.Size = UDim2.new(0, 250, 0, 125)
	window.Position = UDim2.new(0.08, xOffset, 0.12, yOffset)
	window.BackgroundColor3 = Color3.fromRGB(212, 208, 200) -- Classic Windows gray
	window.BorderSizePixel = 2
	window.BorderColor3 = Color3.fromRGB(255, 255, 255)
	window.ZIndex = zIndex
	window.Parent = parentGui

	-- Dark bottom/right 3D border shadow
	local shadowStroke = Instance.new("UIStroke")
	shadowStroke.Color = Color3.fromRGB(64, 64, 64)
	shadowStroke.Thickness = 2
	shadowStroke.Parent = window

	-- Classic Blue Title Bar
	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, -4, 0, 24)
	titleBar.Position = UDim2.new(0, 2, 0, 2)
	titleBar.BackgroundColor3 = Color3.fromRGB(10, 36, 106)
	titleBar.BorderSizePixel = 0
	titleBar.ZIndex = zIndex + 1
	titleBar.Parent = window

	local titleText = Instance.new("TextLabel")
	titleText.Size = UDim2.new(1, -28, 1, 0)
	titleText.Position = UDim2.new(0, 6, 0, 0)
	titleText.BackgroundTransparency = 1
	titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleText.Font = Enum.Font.SourceSansBold
	titleText.TextSize = 14
	titleText.TextXAlignment = Enum.TextXAlignment.Left
	titleText.Text = "System Error"
	titleText.ZIndex = zIndex + 2
	titleText.Parent = titleBar

	-- Top-right [X] close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 18, 0, 18)
	closeBtn.Position = UDim2.new(1, -21, 0, 3)
	closeBtn.BackgroundColor3 = Color3.fromRGB(212, 208, 200)
	closeBtn.BorderSizePixel = 1
	closeBtn.BorderColor3 = Color3.fromRGB(64, 64, 64)
	closeBtn.Font = Enum.Font.SourceSansBold
	closeBtn.TextSize = 13
	closeBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
	closeBtn.Text = "X"
	closeBtn.ZIndex = zIndex + 2
	closeBtn.Parent = titleBar

	-- Red Circle Error Icon
	local errorIcon = Instance.new("TextLabel")
	errorIcon.Size = UDim2.new(0, 32, 0, 32)
	errorIcon.Position = UDim2.new(0, 14, 0, 38)
	errorIcon.BackgroundColor3 = Color3.fromRGB(215, 25, 25)
	errorIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
	errorIcon.Font = Enum.Font.GothamBold
	errorIcon.TextSize = 20
	errorIcon.Text = "X"
	errorIcon.ZIndex = zIndex + 1
	errorIcon.Parent = window

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(1, 0)
	iconCorner.Parent = errorIcon

	-- Error Message Text
	local msgLabel = Instance.new("TextLabel")
	msgLabel.Size = UDim2.new(1, -64, 0, 48)
	msgLabel.Position = UDim2.new(0, 56, 0, 32)
	msgLabel.BackgroundTransparency = 1
	msgLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
	msgLabel.Font = Enum.Font.SourceSans
	msgLabel.TextSize = 14
	msgLabel.TextWrapped = true
	msgLabel.TextXAlignment = Enum.TextXAlignment.Left
	msgLabel.Text = messageText
	msgLabel.ZIndex = zIndex + 1
	msgLabel.Parent = window

	-- Classic "OK" Button
	local okButton = Instance.new("TextButton")
	okButton.Size = UDim2.new(0, 72, 0, 24)
	okButton.Position = UDim2.new(0.5, -36, 1, -32)
	okButton.BackgroundColor3 = Color3.fromRGB(212, 208, 200)
	okButton.BorderSizePixel = 1
	okButton.BorderColor3 = Color3.fromRGB(64, 64, 64)
	okButton.Font = Enum.Font.SourceSansBold
	okButton.TextSize = 14
	okButton.TextColor3 = Color3.fromRGB(0, 0, 0)
	okButton.Text = "OK"
	okButton.ZIndex = zIndex + 1
	okButton.Parent = window

	local function onDismiss()
		window:Destroy()
		if MULTIPLY_ON_OK then
			-- Spawn 2 random popups when "OK" is tapped
			spawnSingleWindowsError(parentGui, math.random(0, 180), math.random(0, 150), zIndex + 5, messageText)
			spawnSingleWindowsError(parentGui, math.random(0, 180), math.random(0, 150), zIndex + 6, messageText)
		end
	end

	okButton.Activated:Connect(onDismiss)
	closeBtn.Activated:Connect(onDismiss)
end

-- Trigger the Diagonal Cascade of Windows Errors
local function triggerWindowsErrorCascade()
	local errorGui = Instance.new("ScreenGui")
	errorGui.Name = "WindowsErrorCascadeGui"
	errorGui.DisplayOrder = 8
	errorGui.ResetOnSpawn = false
	errorGui.Parent = player:WaitForChild("PlayerGui")

	local errorMessages = {
		"Fatal Exception 0x00000088: Memory could not be read.",
		"Executor.exe has stopped responding.",
		"FlyModule.dll is corrupted or missing.",
		"WARNING: Unauthorized override detected.",
		"System32\\controls.sys failed to load."
	}

	task.spawn(function()
		local stepX = 16
		local stepY = 14
		local curX = 0
		local curY = 0

		for i = 1, ERROR_COUNT do
			local msg = errorMessages[((i - 1) % #errorMessages) + 1]
			spawnSingleWindowsError(errorGui, curX, curY, i * 5, msg)

			curX = curX + stepX
			curY = curY + stepY

			if curY > 170 then
				curY = 0
				curX = (curX + 35) % 160
			end

			task.wait(0.09)
		end
	end)
end

-- Function to mess up & scramble the buttons after the hijacker leaves
local function corruptButtons()
	isCorrupted = true

	executorButton.Position = UDim2.new(0.15, 0, 0.72, 0)
	executorButton.Rotation = -14
	executorButton.BackgroundColor3 = Color3.fromRGB(140, 20, 20)
	executorButton.Text = "FL¥: ???"

	flyButton.Visible = true
	flyButton.Position = UDim2.new(0.68, 0, 0.22, 0)
	flyButton.Rotation = 19
	flyButton.BackgroundColor3 = Color3.fromRGB(90, 0, 130)
	flyButton.Text = "EX3CUT0R_ERR"

	local glitchedLabels = {
		"W4LK: ON",
		"FL¥: ERR",
		"EXE_NULL",
		"WHO_AM_I?",
		"FLY: 404",
		"SYST3M_L0ST"
	}

	task.spawn(function()
		while isCorrupted do
			task.wait(1.5)
			if not isHijacked then
				executorButton.Text = glitchedLabels[math.random(1, #glitchedLabels)]
				flyButton.Text = glitchedLabels[math.random(1, #glitchedLabels)]
			end
		end
	end)
end

-- Toggle Flight Function
local function toggleFly()
	if isHijacked then return end

	local character = player.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	if not rootPart or not humanoid then return end

	isFlying = not isFlying

	if isFlying then
		if not isCorrupted then
			flyButton.Text = "FLY: ON"
			flyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 90)
		else
			flyButton.Rotation = math.random(-25, 25)
			flyButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
		end

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
		if not isCorrupted then
			flyButton.Text = "FLY: OFF"
			flyButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
		else
			flyButton.Rotation = math.random(-25, 25)
			flyButton.BackgroundColor3 = Color3.fromRGB(90, 0, 130)
		end

		humanoid.PlatformStand = false
		if bodyGyro then bodyGyro:Destroy() end
		if bodyVelocity then bodyVelocity:Destroy() end
	end
end

-- Create the Fake Hijack UI
local function triggerFakeHijack()
	if isHijacked then return end
	isHijacked = true
	takeoverScheduled = false

	-- Stop flying when the takeover hits
	isFlying = false
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

	-- Countdown, auto-remove after 11s, then trigger fog + glitched buttons + Windows error cascade
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
		activateBlackFog()
		corruptButtons()
		triggerWindowsErrorCascade()
	end)

	-- Typewriter effect for the dialogue
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

-- "EXECUTOR" Button Click Handler
executorButton.Activated:Connect(function()
	if isHijacked then return end

	if isCorrupted then
		executorButton.Position = UDim2.new(math.random(10, 75) / 100, 0, math.random(15, 80) / 100, 0)
		toggleFly()
		return
	end

	flyButton.Visible = true

	if not takeoverScheduled then
		takeoverScheduled = true
		task.delay(TRIGGER_DELAY, function()
			triggerFakeHijack()
		end)
	end
end)

-- "FLY" Button Click Handler
flyButton.Activated:Connect(function()
	if isHijacked then return end

	if isCorrupted then
		flyButton.Position = UDim2.new(math.random(10, 75) / 100, 0, math.random(15, 80) / 100, 0)
		local character = player.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			rootPart.Velocity = Vector3.new(math.random(-40, 40), 75, math.random(-40, 40))
		end
		return
	end

	toggleFly()
end)

-- Steer flight using the mobile thumbstick and camera direction
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

			if isCorrupted then
				flyDirection = -flyDirection -- Reverse controls when corrupted
			end

			bodyVelocity.Velocity = flyDirection * FLY_SPEED
		else
			bodyVelocity.Velocity = Vector3.new(0, 0, 0)
		end

		bodyGyro.CFrame = camera.CFrame
	end
end)
