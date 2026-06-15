local Players = game:GetService("Players")
local VIM = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local lp = Players.LocalPlayer
local gui = lp:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera
local MORSE = {
	A = "●‒",
	B = "‒●●●",
	C = "‒●‒●",
	D = "‒●●",
	E = "●",
	F = "●●‒●",
	G = "‒‒●",
	H = "●●●●",
	I = "●●",
	J = "●‒‒‒",
	K = "‒●‒",
	L = "●‒●●",
	M = "‒‒",
	N = "‒●",
	O = "‒‒‒",
	P = "●‒‒●",
	Q = "‒‒●‒",
	R = "●‒●",
	S = "●●●",
	T = "‒",
	U = "●●‒",
	V = "●●●‒",
	W = "●‒‒",
	X = "‒●●‒",
	Y = "‒●‒‒",
	Z = "‒‒●●"
}
local MORSE_REV = {}
for k, v in pairs(MORSE) do
	MORSE_REV[v] = k
end
local DOT_DUR = 0.35
local DASH_DUR = 0.55
local SYM_GAP = 0.15
local LETTER_GAP = 0.7
local WORD_GAP = 1.0
local KEY_SPACE = Enum.KeyCode.Space
local KEY_D = Enum.KeyCode.D
local KEY_A = Enum.KeyCode.A
local isPlaying = false
local dashDir = true
local mode = "sender"
local watchTarget = nil
local function makeSound(parent, id, vol, pitch)
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = vol
	s.PlaybackSpeed = pitch
	s.RollOffMaxDistance = 0
	s.Parent = parent
	return s
end
local holder = Instance.new("Part")
holder.Anchored = true
holder.CanCollide = false
holder.Transparency = 1
holder.Name = "MorseSounds"
holder.Parent = workspace
local sClick = makeSound(holder, "rbxassetid://138567614125924", 0.6, 1.4)
local sTick = makeSound(holder, "rbxassetid://137872392480008", 0.4, 0.9)
local sTyping = makeSound(holder, "rbxassetid://127105730240202", 0.3, 1.0)
local sDecode = makeSound(holder, "rbxassetid://138567614125924", 0.45, 0.65)
local C = {
	bg = Color3.fromRGB(36, 36, 38),
	bar = Color3.fromRGB(44, 44, 46),
	input = Color3.fromRGB(28, 28, 30),
	stroke = Color3.fromRGB(68, 68, 72),
	text = Color3.fromRGB(205, 205, 208),
	dim = Color3.fromRGB(118, 118, 122),
	accent = Color3.fromRGB(155, 155, 160),
	green = Color3.fromRGB(110, 180, 110),
	yellow = Color3.fromRGB(185, 158, 80),
	red = Color3.fromRGB(178, 72, 72),
	btnPlay = Color3.fromRGB(58, 58, 62),
	btnStop = Color3.fromRGB(66, 44, 44),
	tabOn = Color3.fromRGB(60, 60, 64),
	tabOff = Color3.fromRGB(42, 42, 44),
}
local R = UDim.new(0, 3)
local function newCorner(parent)
	local c = Instance.new("UICorner", parent)
	c.CornerRadius = R
	return c
end
local function newStroke(parent, col, thick)
	local s = Instance.new("UIStroke", parent)
	s.Color = col or C.stroke
	s.Thickness = thick or 1
	return s
end
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MorseGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = gui
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 420, 0, 252)
mainFrame.Position = UDim2.new(0.5, - 210, 0.5, - 126)
mainFrame.BackgroundColor3 = C.bg
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui
newCorner(mainFrame)
newStroke(mainFrame)
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 32)
titleBar.BackgroundColor3 = C.bar
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
newCorner(titleBar)
local tFix = Instance.new("Frame")
tFix.Size = UDim2.new(1, 0, 0.5, 0)
tFix.Position = UDim2.new(0, 0, 0.5, 0)
tFix.BackgroundColor3 = C.bar
tFix.BorderSizePixel = 0
tFix.Parent = titleBar
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, - 50, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "roblox morse code  -  by novi.w"
titleLabel.TextColor3 = C.dim
titleLabel.TextSize = 11
titleLabel.Font = Enum.Font.Gotham
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.RichText = false
titleLabel.Parent = titleBar
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 18)
closeBtn.Position = UDim2.new(1, - 30, 0, 7)
closeBtn.BackgroundColor3 = Color3.fromRGB(85, 50, 50)
closeBtn.Text = "x"
closeBtn.TextColor3 = Color3.fromRGB(190, 165, 165)
closeBtn.TextSize = 10
closeBtn.Font = Enum.Font.Gotham
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
newCorner(closeBtn)
local tabRow = Instance.new("Frame")
tabRow.Size = UDim2.new(1, - 18, 0, 24)
tabRow.Position = UDim2.new(0, 9, 0, 36)
tabRow.BackgroundTransparency = 1
tabRow.Parent = mainFrame
local tabSender = Instance.new("TextButton")
tabSender.Size = UDim2.new(0.5, - 2, 1, 0)
tabSender.Position = UDim2.new(0, 0, 0, 0)
tabSender.BackgroundColor3 = C.tabOn
tabSender.Text = "sender"
tabSender.TextColor3 = C.text
tabSender.TextSize = 11
tabSender.Font = Enum.Font.Gotham
tabSender.BorderSizePixel = 0
tabSender.Parent = tabRow
newCorner(tabSender)
newStroke(tabSender)
local tabTranslator = Instance.new("TextButton")
tabTranslator.Size = UDim2.new(0.5, - 2, 1, 0)
tabTranslator.Position = UDim2.new(0.5, 2, 0, 0)
tabTranslator.BackgroundColor3 = C.tabOff
tabTranslator.Text = "translator"
tabTranslator.TextColor3 = C.dim
tabTranslator.TextSize = 11
tabTranslator.Font = Enum.Font.Gotham
tabTranslator.BorderSizePixel = 0
tabTranslator.Parent = tabRow
newCorner(tabTranslator)
newStroke(tabTranslator)
local PANEL_TOP = 68
local PANEL_H = 252 - PANEL_TOP - 8
local senderPanel = Instance.new("Frame")
senderPanel.Size = UDim2.new(1, - 18, 0, PANEL_H)
senderPanel.Position = UDim2.new(0, 9, 0, PANEL_TOP)
senderPanel.BackgroundTransparency = 1
senderPanel.Parent = mainFrame
local inputBox = Instance.new("TextBox")
inputBox.Size = UDim2.new(1, 0, 0, 32)
inputBox.Position = UDim2.new(0, 0, 0, 0)
inputBox.BackgroundColor3 = C.input
inputBox.TextColor3 = C.text
inputBox.PlaceholderText = "type message, press enter..."
inputBox.PlaceholderColor3 = C.dim
inputBox.Text = ""
inputBox.TextSize = 13
inputBox.Font = Enum.Font.Gotham
inputBox.ClearTextOnFocus = false
inputBox.BorderSizePixel = 0
inputBox.Parent = senderPanel
newCorner(inputBox)
newStroke(inputBox)
local morseLabel = Instance.new("TextLabel")
morseLabel.Size = UDim2.new(1, 0, 0, 18)
morseLabel.Position = UDim2.new(0, 0, 0, 38)
morseLabel.BackgroundTransparency = 1
morseLabel.Text = "morse: —"
morseLabel.TextColor3 = C.accent
morseLabel.TextSize = 10
morseLabel.Font = Enum.Font.Code
morseLabel.TextXAlignment = Enum.TextXAlignment.Left
morseLabel.TextTruncate = Enum.TextTruncate.AtEnd
morseLabel.Parent = senderPanel
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 16)
statusLabel.Position = UDim2.new(0, 0, 0, 58)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "idle"
statusLabel.TextColor3 = C.dim
statusLabel.TextSize = 10
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = senderPanel
local playBtn = Instance.new("TextButton")
playBtn.Size = UDim2.new(0.48, 0, 0, 26)
playBtn.Position = UDim2.new(0, 0, 1, - 26)
playBtn.BackgroundColor3 = C.btnPlay
playBtn.Text = "play"
playBtn.TextColor3 = C.text
playBtn.TextSize = 11
playBtn.Font = Enum.Font.Gotham
playBtn.BorderSizePixel = 0
playBtn.Parent = senderPanel
newCorner(playBtn)
newStroke(playBtn)
local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(0.48, 0, 0, 26)
stopBtn.Position = UDim2.new(0.52, 0, 1, - 26)
stopBtn.BackgroundColor3 = C.btnStop
stopBtn.Text = "stop"
stopBtn.TextColor3 = Color3.fromRGB(195, 160, 160)
stopBtn.TextSize = 11
stopBtn.Font = Enum.Font.Gotham
stopBtn.BorderSizePixel = 0
stopBtn.Parent = senderPanel
newCorner(stopBtn)
newStroke(stopBtn, Color3.fromRGB(95, 58, 58))
local translatorPanel = Instance.new("Frame")
translatorPanel.Size = UDim2.new(1, - 18, 0, PANEL_H)
translatorPanel.Position = UDim2.new(0, 9, 0, PANEL_TOP)
translatorPanel.BackgroundTransparency = 1
translatorPanel.Visible = false
translatorPanel.Parent = mainFrame
local pickBtn = Instance.new("TextButton")
pickBtn.Size = UDim2.new(1, 0, 0, 28)
pickBtn.Position = UDim2.new(0, 0, 0, 0)
pickBtn.BackgroundColor3 = C.btnPlay
pickBtn.Text = "click a player to watch"
pickBtn.TextColor3 = C.dim
pickBtn.TextSize = 11
pickBtn.Font = Enum.Font.Gotham
pickBtn.BorderSizePixel = 0
pickBtn.Parent = translatorPanel
newCorner(pickBtn)
newStroke(pickBtn)
local watchingLabel = Instance.new("TextLabel")
watchingLabel.Size = UDim2.new(1, 0, 0, 16)
watchingLabel.Position = UDim2.new(0, 0, 0, 34)
watchingLabel.BackgroundTransparency = 1
watchingLabel.Text = "watching: none"
watchingLabel.TextColor3 = C.dim
watchingLabel.TextSize = 10
watchingLabel.Font = Enum.Font.Gotham
watchingLabel.TextXAlignment = Enum.TextXAlignment.Left
watchingLabel.Parent = translatorPanel
local rawMorseLabel = Instance.new("TextLabel")
rawMorseLabel.Size = UDim2.new(1, 0, 0, 16)
rawMorseLabel.Position = UDim2.new(0, 0, 0, 52)
rawMorseLabel.BackgroundTransparency = 1
rawMorseLabel.Text = "buffer: —"
rawMorseLabel.TextColor3 = C.accent
rawMorseLabel.TextSize = 10
rawMorseLabel.Font = Enum.Font.Code
rawMorseLabel.TextXAlignment = Enum.TextXAlignment.Left
rawMorseLabel.Parent = translatorPanel
local decodedBox = Instance.new("Frame")
decodedBox.Size = UDim2.new(1, 0, 0, 34)
decodedBox.Position = UDim2.new(0, 0, 0, 72)
decodedBox.BackgroundColor3 = C.input
decodedBox.BorderSizePixel = 0
decodedBox.Parent = translatorPanel
newCorner(decodedBox)
newStroke(decodedBox)
local decodedText = Instance.new("TextLabel")
decodedText.Size = UDim2.new(1, - 10, 1, 0)
decodedText.Position = UDim2.new(0, 6, 0, 0)
decodedText.BackgroundTransparency = 1
decodedText.Text = "—"
decodedText.TextColor3 = C.text
decodedText.TextSize = 14
decodedText.Font = Enum.Font.GothamBold
decodedText.TextXAlignment = Enum.TextXAlignment.Left
decodedText.TextTruncate = Enum.TextTruncate.AtEnd
decodedText.Parent = decodedBox
local acLabel = Instance.new("TextLabel")
acLabel.Size = UDim2.new(1, 0, 0, 14)
acLabel.Position = UDim2.new(0, 0, 0, 110)
acLabel.BackgroundTransparency = 1
acLabel.Text = "autocomplete: —"
acLabel.TextColor3 = C.dim
acLabel.TextSize = 10
acLabel.Font = Enum.Font.Gotham
acLabel.TextXAlignment = Enum.TextXAlignment.Left
acLabel.Parent = translatorPanel
local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(1, 0, 0, 24)
clearBtn.Position = UDim2.new(0, 0, 1, - 24)
clearBtn.BackgroundColor3 = C.btnStop
clearBtn.Text = "clear"
clearBtn.TextColor3 = Color3.fromRGB(195, 160, 160)
clearBtn.TextSize = 11
clearBtn.Font = Enum.Font.Gotham
clearBtn.BorderSizePixel = 0
clearBtn.Parent = translatorPanel
newCorner(clearBtn)
newStroke(clearBtn, Color3.fromRGB(95, 58, 58))
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 86, 0, 22)
toggleBtn.Position = UDim2.new(0, 0, 0, - 28)
toggleBtn.BackgroundColor3 = C.bar
toggleBtn.Text = "morse"
toggleBtn.TextColor3 = C.dim
toggleBtn.TextSize = 10
toggleBtn.Font = Enum.Font.Gotham
toggleBtn.BorderSizePixel = 0
toggleBtn.Visible = false
toggleBtn.Parent = mainFrame
newCorner(toggleBtn)
newStroke(toggleBtn)
local function customWait(t)
	local s = tick()
	while tick() - s < t do
		if not isPlaying then
			return
		end
		RunService.Heartbeat:Wait()
	end
end
local function pressKey(key, duration)
	if not isPlaying then
		return
	end
	VIM:SendKeyEvent(true, key, false, nil)
	customWait(duration)
	VIM:SendKeyEvent(false, key, false, nil)
end
local function setStatus(txt, col)
	statusLabel.Text = txt
	statusLabel.TextColor3 = col or C.dim
end
local function buildMorseDisplay(text)
	local parts = {}
	for i = 1, # text do
		local ch = text:sub(i, i):upper()
		if ch == " " then
			table.insert(parts, "/")
		elseif MORSE[ch] then
			table.insert(parts, MORSE[ch])
		end
	end
	return table.concat(parts, " ")
end
local function textToTokens(text)
	local result = {}
	for i = 1, # text do
		local ch = text:sub(i, i):upper()
		if ch == " " then
			table.insert(result, "WORD")
		elseif MORSE[ch] then
			table.insert(result, ch)
		end
	end
	return result
end
local function getSymbols(pattern)
	local syms = {}
	local j = 1
	while j <= # pattern do
		local b = pattern:byte(j)
		local len = 1
		if b >= 0xF0 then
			len = 4
		elseif b >= 0xE0 then
			len = 3
		elseif b >= 0xC0 then
			len = 2
		end
		table.insert(syms, pattern:sub(j, j + len - 1))
		j = j + len
	end
	return syms
end
local function playSymbol(sym)
	if not isPlaying then
		return
	end
	if sym == "●" then
		sClick:Play()
		setStatus("jumping", C.green)
		pressKey(KEY_SPACE, DOT_DUR)
	elseif sym == "‒" then
		sTick:Play()
		local key = dashDir and KEY_D or KEY_A
		dashDir = not dashDir
		setStatus("stepping", C.accent)
		pressKey(key, DASH_DUR)
	end
	customWait(SYM_GAP)
end
local function playText(text)
	isPlaying = true
	dashDir = true
	local tokens = textToTokens(text)
	for _, token in ipairs(tokens) do
		if not isPlaying then
			break
		end
		if token == "WORD" then
			setStatus("word gap...", C.yellow)
			customWait(WORD_GAP)
		else
			local pattern = MORSE[token]
			setStatus(token .. "  " .. pattern, C.text)
			local syms = getSymbols(pattern)
			for _, s in ipairs(syms) do
				if not isPlaying then
					break
				end
				playSymbol(s)
			end
			if isPlaying then
				setStatus("letter gap...", C.yellow)
				customWait(LETTER_GAP)
			end
		end
	end
	if isPlaying then
		setStatus("done", C.green)
	else
		setStatus("stopped", C.red)
	end
	isPlaying = false
end
local watchConns = {}
local decodeBuffer = ""
local decodedOutput = ""
local letterTimerConn = nil
local LETTER_TO = 1.2
local WORD_TO = 2.6
local function getAutocomplete(buf)
	if # buf == 0 then
		return nil
	end
	local matches = {}
	for pattern, letter in pairs(MORSE_REV) do
		if # pattern >= # buf and pattern:sub(1, # buf) == buf then
			table.insert(matches, letter .. " (" .. pattern .. ")")
		end
	end
	if # matches == 1 then
		return matches[1]
	end
	if # matches > 1 then
		table.sort(matches)
		return table.concat(matches, "  ")
	end
	return nil
end
local function flushLetter()
	if # decodeBuffer == 0 then
		return
	end
	local letter = MORSE_REV[decodeBuffer]
	sDecode:Play()
	decodedOutput = decodedOutput .. (letter or "?")
	decodedText.Text = decodedOutput
	rawMorseLabel.Text = "buffer: " .. decodeBuffer .. "  ->  " .. (letter or "?")
	acLabel.Text = "autocomplete: —"
	decodeBuffer = ""
end
local function flushWord()
	flushLetter()
	if # decodedOutput > 0 and decodedOutput:sub(- 1) ~= " " then
		decodedOutput = decodedOutput .. " "
		decodedText.Text = decodedOutput
	end
end
local function startLetterTimer()
	if letterTimerConn then
		letterTimerConn:Disconnect()
	end
	local t0 = tick()
	letterTimerConn = RunService.Heartbeat:Connect(function()
		local elapsed = tick() - t0
		if elapsed >= WORD_TO then
			flushWord()
			letterTimerConn:Disconnect()
			letterTimerConn = nil
		elseif elapsed >= LETTER_TO then
			flushLetter()
			letterTimerConn:Disconnect()
			letterTimerConn = nil
		end
	end)
end
local function addSymbol(sym)
	decodeBuffer = decodeBuffer .. sym
	rawMorseLabel.Text = "buffer: " .. decodeBuffer
	local ac = getAutocomplete(decodeBuffer)
	acLabel.Text = "autocomplete: " .. (ac or "—")
	startLetterTimer()
end
local function stopWatching()
	for _, c in ipairs(watchConns) do
		c:Disconnect()
	end
	watchConns = {}
	if letterTimerConn then
		letterTimerConn:Disconnect()
		letterTimerConn = nil
	end
	watchTarget = nil
	decodeBuffer = ""
	watchingLabel.Text = "watching: none"
	watchingLabel.TextColor3 = C.dim
	pickBtn.Text = "click a player to watch"
	pickBtn.TextColor3 = C.dim
end
local function startWatching(player)
	stopWatching()
	watchTarget = player
	watchingLabel.Text = "watching: " .. player.Name
	watchingLabel.TextColor3 = C.green
	pickBtn.Text = "watching " .. player.Name .. "  (click to change)"
	pickBtn.TextColor3 = C.green
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid", 5)
	if not hum then
		return
	end
	local jumpConn = hum.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Jumping then
			sClick:Play()
			addSymbol("●")
		end
	end)
	local stepDebounce = false
	local prevState = nil
	local stepConn = hum.StateChanged:Connect(function(old, new)
		if new == Enum.HumanoidStateType.Running and prevState ~= Enum.HumanoidStateType.Running and not stepDebounce then
			if hum.MoveDirection.Magnitude > 0.1 then
				stepDebounce = true
				sTick:Play()
				addSymbol("‒")
				task.delay(0.45, function()
					stepDebounce = false
				end)
			end
		end
		prevState = new
	end)
	local diedConn = hum.Died:Connect(stopWatching)
	table.insert(watchConns, jumpConn)
	table.insert(watchConns, stepConn)
	table.insert(watchConns, diedConn)
end
local picking = false
pickBtn.MouseButton1Click:Connect(function()
	if watchTarget then
		stopWatching()
		return
	end
	if picking then
		picking = false
		pickBtn.Text = "click a player to watch"
		pickBtn.TextColor3 = C.dim
		return
	end
	picking = true
	pickBtn.Text = "click on a player..."
	pickBtn.TextColor3 = C.yellow
	local conn
	conn = UIS.InputBegan:Connect(function(input, gpe)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		if gpe then
			picking = false
			pickBtn.Text = "click a player to watch"
			pickBtn.TextColor3 = C.dim
			conn:Disconnect()
			return
		end
		local ray = camera:ScreenPointToRay(input.Position.X, input.Position.Y)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		if lp.Character then
			params.FilterDescendantsInstances = {
				lp.Character
			}
		end
		local result = workspace:Raycast(ray.Origin, ray.Direction * 500, params)
		if result then
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= lp and p.Character and result.Instance:IsDescendantOf(p.Character) then
					picking = false
					conn:Disconnect()
					startWatching(p)
					return
				end
			end
		end
		picking = false
		pickBtn.Text = "no player hit  —  try again"
		pickBtn.TextColor3 = C.red
		conn:Disconnect()
	end)
end)
clearBtn.MouseButton1Click:Connect(function()
	decodeBuffer = ""
	decodedOutput = ""
	decodedText.Text = "—"
	rawMorseLabel.Text = "buffer: —"
	acLabel.Text = "autocomplete: —"
end)
local function switchTab(to)
	mode = to
	if to == "sender" then
		senderPanel.Visible = true
		translatorPanel.Visible = false
		tabSender.BackgroundColor3 = C.tabOn
		tabSender.TextColor3 = C.text
		tabTranslator.BackgroundColor3 = C.tabOff
		tabTranslator.TextColor3 = C.dim
	else
		senderPanel.Visible = false
		translatorPanel.Visible = true
		tabSender.BackgroundColor3 = C.tabOff
		tabSender.TextColor3 = C.dim
		tabTranslator.BackgroundColor3 = C.tabOn
		tabTranslator.TextColor3 = C.text
		if isPlaying then
			isPlaying = false
		end
	end
end
tabSender.MouseButton1Click:Connect(function()
	switchTab("sender")
end)
tabTranslator.MouseButton1Click:Connect(function()
	switchTab("translator")
end)
inputBox:GetPropertyChangedSignal("Text"):Connect(function()
	sTyping:Play()
	local t = inputBox.Text
	morseLabel.Text = # t > 0 and ("morse: " .. buildMorseDisplay(t)) or "morse: —"
end)
inputBox.FocusLost:Connect(function(entered)
	if entered and not isPlaying and # inputBox.Text > 0 then
		coroutine.wrap(function()
			playText(inputBox.Text)
		end)()
	end
end)
playBtn.MouseButton1Click:Connect(function()
	if isPlaying or # inputBox.Text == 0 then
		return
	end
	coroutine.wrap(function()
		playText(inputBox.Text)
	end)()
end)
stopBtn.MouseButton1Click:Connect(function()
	isPlaying = false
end)
closeBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	toggleBtn.Visible = true
end)
toggleBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = true
	toggleBtn.Visible = false
end)
