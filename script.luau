local Players = game:GetService("Players")
local VIM = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local lp = Players.LocalPlayer
local gui = lp:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local MORSE = {
	A="●‒", B="‒●●●", C="‒●‒●", D="‒●●",  E="●",
	F="●●‒●", G="‒‒●", H="●●●●", I="●●",  J="●‒‒‒",
	K="‒●‒", L="●‒●●", M="‒‒",  N="‒●",   O="‒‒‒",
	P="●‒‒●", Q="‒‒●‒", R="●‒●", S="●●●", T="‒",
	U="●●‒", V="●●●‒", W="●‒‒",  X="‒●●‒", Y="‒●‒‒", Z="‒‒●●"
}
local MORSE_REV = {}
for k,v in pairs(MORSE) do MORSE_REV[v]=k end

local DOT_DUR    = 0.35
local DASH_DUR   = 0.55
local SYM_GAP    = 0.15
local LETTER_GAP = 0.7
local WORD_GAP   = 1.0
local LETTER_TO  = 1.2
local WORD_TO    = 2.6

local KEY_SPACE = Enum.KeyCode.Space
local KEY_D     = Enum.KeyCode.D
local KEY_A     = Enum.KeyCode.A

local isPlaying   = false
local dashDir     = true
local mode        = "sender"
local watchTarget = nil
local minimized   = false

local function makeSound(id, vol, pitch)
	local s = Instance.new("Sound")
	s.SoundId = id; s.Volume = vol; s.PlaybackSpeed = pitch
	s.RollOffMaxDistance = 0
	s.Parent = workspace
	return s
end
local sClick  = makeSound("rbxassetid://138567614125924", 0.6, 1.4)
local sTick   = makeSound("rbxassetid://137872392480008", 0.4, 0.9)
local sTyping = makeSound("rbxassetid://127105730240202", 0.3, 1.0)
local sDecode = makeSound("rbxassetid://138567614125924", 0.45, 0.65)

local C = {
	bg      = Color3.fromRGB(30, 30, 30),
	bar     = Color3.fromRGB(40, 40, 40),
	input   = Color3.fromRGB(23, 23, 23),
	stroke  = Color3.fromRGB(60, 60, 60),
	text    = Color3.fromRGB(200, 200, 200),
	dim     = Color3.fromRGB(110, 110, 110),
	accent  = Color3.fromRGB(150, 150, 150),
	green   = Color3.fromRGB(120, 170, 120),
	yellow  = Color3.fromRGB(175, 155, 85),
	red     = Color3.fromRGB(165, 75, 75),
	btnNorm = Color3.fromRGB(50, 50, 50),
	btnStop = Color3.fromRGB(58, 38, 38),
	tabOn   = Color3.fromRGB(55, 55, 55),
	tabOff  = Color3.fromRGB(38, 38, 38),
	toggle  = Color3.fromRGB(45, 45, 45),
}

local function corner(parent, r)
	local c = Instance.new("UICorner", parent)
	c.CornerRadius = UDim.new(0, r or 4)
end
local function stroke(parent, col, thick)
	local s = Instance.new("UIStroke", parent)
	s.Color = col or C.stroke; s.Thickness = thick or 1
end
local function tween(obj, info, props)
	TweenService:Create(obj, info, props):Play()
end
local FAST = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local MED  = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MorseGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = gui

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 100, 0, 28)
toggleBtn.Position = UDim2.new(0, 12, 1, -48)
toggleBtn.BackgroundColor3 = C.toggle
toggleBtn.Text = "morse"
toggleBtn.TextColor3 = C.dim
toggleBtn.TextSize = 11
toggleBtn.Font = Enum.Font.Gotham
toggleBtn.BorderSizePixel = 0
toggleBtn.Visible = false
toggleBtn.ZIndex = 10
toggleBtn.Parent = screenGui
corner(toggleBtn, 4)
stroke(toggleBtn)

local FRAME_W = 400
local FRAME_H = 256
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, FRAME_W, 0, FRAME_H)
mainFrame.Position = UDim2.new(0.5, -FRAME_W/2, 0.5, -FRAME_H/2)
mainFrame.BackgroundColor3 = C.bg
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui
corner(mainFrame, 5)
stroke(mainFrame)

local TITLE_H = 34
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, TITLE_H)
titleBar.BackgroundColor3 = C.bar
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
corner(titleBar, 5)
local tFix = Instance.new("Frame")
tFix.Size = UDim2.new(1, 0, 0.5, 0)
tFix.Position = UDim2.new(0, 0, 0.5, 0)
tFix.BackgroundColor3 = C.bar
tFix.BorderSizePixel = 0
tFix.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -80, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "roblox morse code  ·  novi.w"
titleLabel.TextColor3 = Color3.fromRGB(175, 175, 175)
titleLabel.TextSize = 11
titleLabel.Font = Enum.Font.Gotham
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 28, 0, 20)
minBtn.Position = UDim2.new(1, -62, 0.5, -10)
minBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
minBtn.Text = "—"
minBtn.TextColor3 = C.dim
minBtn.TextSize = 10
minBtn.Font = Enum.Font.Gotham
minBtn.BorderSizePixel = 0
minBtn.Parent = titleBar
corner(minBtn, 3)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 20)
closeBtn.Position = UDim2.new(1, -30, 0.5, -10)
closeBtn.BackgroundColor3 = Color3.fromRGB(68, 42, 42)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(180, 145, 145)
closeBtn.TextSize = 10
closeBtn.Font = Enum.Font.Gotham
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
corner(closeBtn, 3)

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 1, -TITLE_H)
contentFrame.Position = UDim2.new(0, 0, 0, TITLE_H)
contentFrame.BackgroundTransparency = 1
contentFrame.ClipsDescendants = true
contentFrame.Parent = mainFrame

local TAB_TOP = 8
local tabRow = Instance.new("Frame")
tabRow.Size = UDim2.new(1, -18, 0, 26)
tabRow.Position = UDim2.new(0, 9, 0, TAB_TOP)
tabRow.BackgroundTransparency = 1
tabRow.Parent = contentFrame

local tabSender = Instance.new("TextButton")
tabSender.Size = UDim2.new(0.5, -3, 1, 0)
tabSender.Position = UDim2.new(0, 0, 0, 0)
tabSender.BackgroundColor3 = C.tabOn
tabSender.Text = "sender"
tabSender.TextColor3 = Color3.fromRGB(210, 210, 210)
tabSender.TextSize = 12
tabSender.Font = Enum.Font.Gotham
tabSender.BorderSizePixel = 0
tabSender.Parent = tabRow
corner(tabSender, 4); stroke(tabSender)

local tabTranslator = Instance.new("TextButton")
tabTranslator.Size = UDim2.new(0.5, -3, 1, 0)
tabTranslator.Position = UDim2.new(0.5, 3, 0, 0)
tabTranslator.BackgroundColor3 = C.tabOff
tabTranslator.Text = "translator"
tabTranslator.TextColor3 = Color3.fromRGB(130, 130, 130)
tabTranslator.TextSize = 12
tabTranslator.Font = Enum.Font.Gotham
tabTranslator.BorderSizePixel = 0
tabTranslator.Parent = tabRow
corner(tabTranslator, 4); stroke(tabTranslator)

local PANEL_TOP = TAB_TOP + 26 + 6
local PANEL_H   = (FRAME_H - TITLE_H) - PANEL_TOP - 8

local senderPanel = Instance.new("Frame")
senderPanel.Size = UDim2.new(1, -18, 0, PANEL_H)
senderPanel.Position = UDim2.new(0, 9, 0, PANEL_TOP)
senderPanel.BackgroundTransparency = 1
senderPanel.Parent = contentFrame

local inputBox = Instance.new("TextBox")
inputBox.Size = UDim2.new(1, 0, 0, 34)
inputBox.BackgroundColor3 = C.input
inputBox.TextColor3 = Color3.fromRGB(215, 215, 215)
inputBox.PlaceholderText = "type message, press enter..."
inputBox.PlaceholderColor3 = Color3.fromRGB(90, 90, 90)
inputBox.Text = ""
inputBox.TextSize = 13
inputBox.Font = Enum.Font.Gotham
inputBox.ClearTextOnFocus = false
inputBox.BorderSizePixel = 0
inputBox.Parent = senderPanel
corner(inputBox, 4); stroke(inputBox)

local morseLabelBtn = Instance.new("TextButton")
morseLabelBtn.Size = UDim2.new(1, 0, 0, 20)
morseLabelBtn.Position = UDim2.new(0, 0, 0, 40)
morseLabelBtn.BackgroundTransparency = 1
morseLabelBtn.Text = "morse: —"
morseLabelBtn.TextColor3 = Color3.fromRGB(185, 185, 185)
morseLabelBtn.TextSize = 11
morseLabelBtn.Font = Enum.Font.Code
morseLabelBtn.TextXAlignment = Enum.TextXAlignment.Left
morseLabelBtn.TextTruncate = Enum.TextTruncate.AtEnd
morseLabelBtn.BorderSizePixel = 0
morseLabelBtn.AutoButtonColor = false
morseLabelBtn.Parent = senderPanel
local morseLabel = morseLabelBtn

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 16)
statusLabel.Position = UDim2.new(0, 0, 0, 62)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "idle"
statusLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = senderPanel

local playBtn = Instance.new("TextButton")
playBtn.Size = UDim2.new(0.48, 0, 0, 28)
playBtn.Position = UDim2.new(0, 0, 1, -28)
playBtn.BackgroundColor3 = C.btnNorm
playBtn.Text = "play"
playBtn.TextColor3 = Color3.fromRGB(210, 210, 210)
playBtn.TextSize = 12
playBtn.Font = Enum.Font.Gotham
playBtn.BorderSizePixel = 0
playBtn.Parent = senderPanel
corner(playBtn, 4); stroke(playBtn)

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(0.48, 0, 0, 28)
stopBtn.Position = UDim2.new(0.52, 0, 1, -28)
stopBtn.BackgroundColor3 = C.btnStop
stopBtn.Text = "stop"
stopBtn.TextColor3 = Color3.fromRGB(200, 155, 155)
stopBtn.TextSize = 12
stopBtn.Font = Enum.Font.Gotham
stopBtn.BorderSizePixel = 0
stopBtn.Parent = senderPanel
corner(stopBtn, 4); stroke(stopBtn, Color3.fromRGB(88, 52, 52))

local translatorPanel = Instance.new("Frame")
translatorPanel.Size = UDim2.new(1, -18, 0, PANEL_H)
translatorPanel.Position = UDim2.new(0, 9, 0, PANEL_TOP)
translatorPanel.BackgroundTransparency = 1
translatorPanel.Visible = false
translatorPanel.Parent = contentFrame

local pickBtn = Instance.new("TextButton")
pickBtn.Size = UDim2.new(1, 0, 0, 30)
pickBtn.BackgroundColor3 = C.btnNorm
pickBtn.Text = "click a player to watch"
pickBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
pickBtn.TextSize = 12
pickBtn.Font = Enum.Font.Gotham
pickBtn.BorderSizePixel = 0
pickBtn.Parent = translatorPanel
corner(pickBtn, 4); stroke(pickBtn)

local watchingLabel = Instance.new("TextLabel")
watchingLabel.Size = UDim2.new(1, 0, 0, 16)
watchingLabel.Position = UDim2.new(0, 0, 0, 36)
watchingLabel.BackgroundTransparency = 1
watchingLabel.Text = "watching: none"
watchingLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
watchingLabel.TextSize = 11
watchingLabel.Font = Enum.Font.Gotham
watchingLabel.TextXAlignment = Enum.TextXAlignment.Left
watchingLabel.Parent = translatorPanel

local rawMorseLabel = Instance.new("TextLabel")
rawMorseLabel.Size = UDim2.new(1, 0, 0, 16)
rawMorseLabel.Position = UDim2.new(0, 0, 0, 54)
rawMorseLabel.BackgroundTransparency = 1
rawMorseLabel.Text = "buffer: —"
rawMorseLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
rawMorseLabel.TextSize = 11
rawMorseLabel.Font = Enum.Font.Code
rawMorseLabel.TextXAlignment = Enum.TextXAlignment.Left
rawMorseLabel.Parent = translatorPanel

local decodedBox = Instance.new("Frame")
decodedBox.Size = UDim2.new(1, 0, 0, 36)
decodedBox.Position = UDim2.new(0, 0, 0, 74)
decodedBox.BackgroundColor3 = C.input
decodedBox.BorderSizePixel = 0
decodedBox.Parent = translatorPanel
corner(decodedBox, 4); stroke(decodedBox)

local decodedText = Instance.new("TextLabel")
decodedText.Size = UDim2.new(1, -10, 1, 0)
decodedText.Position = UDim2.new(0, 6, 0, 0)
decodedText.BackgroundTransparency = 1
decodedText.Text = "—"
decodedText.TextColor3 = Color3.fromRGB(215, 215, 215)
decodedText.TextSize = 14
decodedText.Font = Enum.Font.GothamBold
decodedText.TextXAlignment = Enum.TextXAlignment.Left
decodedText.TextTruncate = Enum.TextTruncate.AtEnd
decodedText.Parent = decodedBox

local acLabel = Instance.new("TextLabel")
acLabel.Size = UDim2.new(1, 0, 0, 14)
acLabel.Position = UDim2.new(0, 0, 0, 114)
acLabel.BackgroundTransparency = 1
acLabel.Text = "autocomplete: —"
acLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
acLabel.TextSize = 11
acLabel.Font = Enum.Font.Gotham
acLabel.TextXAlignment = Enum.TextXAlignment.Left
acLabel.Parent = translatorPanel

local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(1, 0, 0, 26)
clearBtn.Position = UDim2.new(0, 0, 1, -26)
clearBtn.BackgroundColor3 = C.btnStop
clearBtn.Text = "clear"
clearBtn.TextColor3 = Color3.fromRGB(200, 155, 155)
clearBtn.TextSize = 12
clearBtn.Font = Enum.Font.Gotham
clearBtn.BorderSizePixel = 0
clearBtn.Parent = translatorPanel
corner(clearBtn, 4); stroke(clearBtn, Color3.fromRGB(88, 52, 52))

do
	local dragging, dragStart, startPos = false, nil, nil
	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging  = true
			dragStart = input.Position
			startPos  = mainFrame.Position
		end
	end)
	titleBar.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if dragging and (
			input.UserInputType == Enum.UserInputType.Touch or
			input.UserInputType == Enum.UserInputType.MouseMovement
		) then
			local delta = input.Position - dragStart
			mainFrame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

local function setMinimized(val)
	minimized = val
	if minimized then
		tween(mainFrame, MED, { Size = UDim2.new(0, FRAME_W, 0, TITLE_H) })
	else
		tween(mainFrame, MED, { Size = UDim2.new(0, FRAME_W, 0, FRAME_H) })
	end
end

minBtn.MouseButton1Click:Connect(function()
	setMinimized(not minimized)
end)

closeBtn.MouseButton1Click:Connect(function()
	tween(mainFrame, FAST, { BackgroundTransparency = 1 })
	tween(contentFrame, FAST, {})
	task.delay(0.2, function()
		mainFrame.Visible = false
		mainFrame.BackgroundTransparency = 0
		toggleBtn.Visible = true
	end)
end)

toggleBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = true
	mainFrame.Size = UDim2.new(0, FRAME_W, 0, TITLE_H)
	tween(mainFrame, MED, { Size = UDim2.new(0, FRAME_W, 0, FRAME_H) })
	minimized = false
	toggleBtn.Visible = false
end)

local function addHover(btn, normalColor, hoverColor)
	btn.MouseEnter:Connect(function()
		tween(btn, FAST, { BackgroundColor3 = hoverColor })
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, FAST, { BackgroundColor3 = normalColor })
	end)
end
addHover(playBtn,  C.btnNorm, Color3.fromRGB(65, 65, 65))
addHover(stopBtn,  C.btnStop, Color3.fromRGB(75, 48, 48))
addHover(clearBtn, C.btnStop, Color3.fromRGB(75, 48, 48))
addHover(pickBtn,  C.btnNorm, Color3.fromRGB(65, 65, 65))
addHover(minBtn,   Color3.fromRGB(50,50,50), Color3.fromRGB(70,70,70))
addHover(closeBtn, Color3.fromRGB(68,42,42), Color3.fromRGB(95,55,55))
addHover(toggleBtn, C.toggle, Color3.fromRGB(60,60,60))

local function customWait(t)
	local s = tick()
	while tick()-s < t do
		if not isPlaying then return end
		RunService.Heartbeat:Wait()
	end
end
local function pressKey(key, duration)
	if not isPlaying then return end
	VIM:SendKeyEvent(true, key, false, nil)
	customWait(duration)
	VIM:SendKeyEvent(false, key, false, nil)
end
local function setStatus(txt, col)
	statusLabel.Text = txt
	statusLabel.TextColor3 = col or Color3.fromRGB(140, 140, 140)
end
local function buildMorseDisplay(text)
	local parts = {}
	for i=1,#text do
		local ch = text:sub(i,i):upper()
		if ch==" " then table.insert(parts,"/")
		elseif MORSE[ch] then table.insert(parts, MORSE[ch]) end
	end
	return table.concat(parts," ")
end
local function textToTokens(text)
	local result = {}
	for i=1,#text do
		local ch = text:sub(i,i):upper()
		if ch==" " then table.insert(result,"WORD")
		elseif MORSE[ch] then table.insert(result, ch) end
	end
	return result
end
local function getSymbols(pattern)
	local syms, j = {}, 1
	while j <= #pattern do
		local b = pattern:byte(j)
		local len = 1
		if b >= 0xF0 then len=4 elseif b >= 0xE0 then len=3 elseif b >= 0xC0 then len=2 end
		table.insert(syms, pattern:sub(j, j+len-1))
		j = j+len
	end
	return syms
end
local function playSymbol(sym)
	if not isPlaying then return end
	if sym == "●" then
		sClick:Play(); setStatus("jumping", C.green); pressKey(KEY_SPACE, DOT_DUR)
	elseif sym == "‒" then
		sTick:Play()
		local key = dashDir and KEY_D or KEY_A; dashDir = not dashDir
		setStatus("stepping", C.accent); pressKey(key, DASH_DUR)
	end
	customWait(SYM_GAP)
end
local function playText(text)
	isPlaying = true; dashDir = true
	for _, token in ipairs(textToTokens(text)) do
		if not isPlaying then break end
		if token == "WORD" then
			setStatus("word gap...", C.yellow); customWait(WORD_GAP)
		else
			local pattern = MORSE[token]
			setStatus(token.."  "..pattern, C.text)
			for _, s in ipairs(getSymbols(pattern)) do
				if not isPlaying then break end
				playSymbol(s)
			end
			if isPlaying then setStatus("letter gap...", C.yellow); customWait(LETTER_GAP) end
		end
	end
	if isPlaying then setStatus("done", C.green) else setStatus("stopped", C.red) end
	isPlaying = false
end

local watchConns = {}
local decodeBuffer, decodedOutput = "", ""
local letterTimerConn = nil
local function getAutocomplete(buf)
	if #buf==0 then return nil end
	local matches = {}
	for pattern, letter in pairs(MORSE_REV) do
		if #pattern >= #buf and pattern:sub(1,#buf)==buf then
			table.insert(matches, letter.." ("..pattern..")")
		end
	end
	if #matches==1 then return matches[1] end
	if #matches>1 then table.sort(matches); return table.concat(matches,"  ") end
	return nil
end
local function flushLetter()
	if #decodeBuffer==0 then return end
	local letter = MORSE_REV[decodeBuffer]
	sDecode:Play()
	decodedOutput = decodedOutput..(letter or "?")
	decodedText.Text = decodedOutput
	rawMorseLabel.Text = "buffer: "..decodeBuffer.."  ->  "..(letter or "?")
	acLabel.Text = "autocomplete: —"
	decodeBuffer = ""
end
local function flushWord()
	flushLetter()
	if #decodedOutput>0 and decodedOutput:sub(-1)~=" " then
		decodedOutput = decodedOutput.." "
		decodedText.Text = decodedOutput
	end
end
local function startLetterTimer()
	if letterTimerConn then letterTimerConn:Disconnect() end
	local t0 = tick()
	letterTimerConn = RunService.Heartbeat:Connect(function()
		local elapsed = tick()-t0
		if elapsed >= WORD_TO then
			flushWord(); letterTimerConn:Disconnect(); letterTimerConn=nil
		elseif elapsed >= LETTER_TO then
			flushLetter(); letterTimerConn:Disconnect(); letterTimerConn=nil
		end
	end)
end
local function addSymbol(sym)
	decodeBuffer = decodeBuffer..sym
	rawMorseLabel.Text = "buffer: "..decodeBuffer
	acLabel.Text = "autocomplete: "..(getAutocomplete(decodeBuffer) or "—")
	startLetterTimer()
end
local function stopWatching()
	for _,c in ipairs(watchConns) do c:Disconnect() end
	watchConns = {}
	if letterTimerConn then letterTimerConn:Disconnect(); letterTimerConn=nil end
	watchTarget = nil; decodeBuffer = ""
	watchingLabel.Text = "watching: none"; watchingLabel.TextColor3 = C.dim
	pickBtn.Text = "click a player to watch"; pickBtn.TextColor3 = C.dim
end
local function startWatching(player)
	stopWatching(); watchTarget = player
	watchingLabel.Text = "watching: "..player.Name; watchingLabel.TextColor3 = C.green
	pickBtn.Text = "watching "..player.Name.."  (click to change)"; pickBtn.TextColor3 = C.green
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid", 5)
	if not hum then return end
	local jumpConn = hum.StateChanged:Connect(function(_, new)
		if new==Enum.HumanoidStateType.Jumping then sClick:Play(); addSymbol("●") end
	end)
	local stepDebounce, prevState = false, nil
	local stepConn = hum.StateChanged:Connect(function(old, new)
		if new==Enum.HumanoidStateType.Running and prevState~=Enum.HumanoidStateType.Running and not stepDebounce then
			if hum.MoveDirection.Magnitude > 0.1 then
				stepDebounce=true; sTick:Play(); addSymbol("‒")
				task.delay(0.45, function() stepDebounce=false end)
			end
		end
		prevState=new
	end)
	local diedConn = hum.Died:Connect(stopWatching)
	table.insert(watchConns, jumpConn)
	table.insert(watchConns, stepConn)
	table.insert(watchConns, diedConn)
end

local picking = false
pickBtn.MouseButton1Click:Connect(function()
	if watchTarget then stopWatching(); return end
	if picking then
		picking=false; pickBtn.Text="click a player to watch"; pickBtn.TextColor3=C.dim; return
	end
	picking=true; pickBtn.Text="click on a player..."; pickBtn.TextColor3=C.yellow
	local conn
	conn = UIS.InputBegan:Connect(function(input, gpe)
		if input.UserInputType~=Enum.UserInputType.MouseButton1
		and input.UserInputType~=Enum.UserInputType.Touch then return end
		if gpe then
			picking=false; pickBtn.Text="click a player to watch"; pickBtn.TextColor3=C.dim
			conn:Disconnect(); return
		end
		local ray = camera:ScreenPointToRay(input.Position.X, input.Position.Y)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		if lp.Character then params.FilterDescendantsInstances={lp.Character} end
		local result = workspace:Raycast(ray.Origin, ray.Direction*500, params)
		if result then
			for _, p in ipairs(Players:GetPlayers()) do
				if p~=lp and p.Character and result.Instance:IsDescendantOf(p.Character) then
					picking=false; conn:Disconnect(); startWatching(p); return
				end
			end
		end
		picking=false; pickBtn.Text="no player hit - try again"; pickBtn.TextColor3=C.red
		conn:Disconnect()
	end)
end)

clearBtn.MouseButton1Click:Connect(function()
	decodeBuffer=""; decodedOutput=""
	decodedText.Text="—"; rawMorseLabel.Text="buffer: —"; acLabel.Text="autocomplete: —"
end)

local function switchTab(to)
	mode = to
	sClick:Play()
	if to=="sender" then
		senderPanel.Visible=true; translatorPanel.Visible=false
		tween(tabSender, FAST, {BackgroundColor3=C.tabOn}); tabSender.TextColor3=Color3.fromRGB(210,210,210)
		tween(tabTranslator, FAST, {BackgroundColor3=C.tabOff}); tabTranslator.TextColor3=Color3.fromRGB(130,130,130)
	else
		senderPanel.Visible=false; translatorPanel.Visible=true
		tween(tabSender, FAST, {BackgroundColor3=C.tabOff}); tabSender.TextColor3=Color3.fromRGB(130,130,130)
		tween(tabTranslator, FAST, {BackgroundColor3=C.tabOn}); tabTranslator.TextColor3=Color3.fromRGB(210,210,210)
		if isPlaying then isPlaying=false end
	end
end
tabSender.MouseButton1Click:Connect(function() switchTab("sender") end)
tabTranslator.MouseButton1Click:Connect(function() switchTab("translator") end)

inputBox:GetPropertyChangedSignal("Text"):Connect(function()
	sTyping:Play()
	local t = inputBox.Text
	local display = #t>0 and ("morse: "..buildMorseDisplay(t)) or "morse: —"
	morseLabel.Text = display
end)

morseLabelBtn.MouseButton1Click:Connect(function()
	local raw = inputBox.Text
	if #raw == 0 then return end
	local display = buildMorseDisplay(raw)
	local ascii = ""
	local i = 1
	while i <= #display do
		local b = display:byte(i)
		if b >= 0xF0 then
			ascii = ascii .. "?"; i = i + 4
		elseif b >= 0xE0 then
			local seq = display:sub(i, i+2)
			if seq == "\226\128\146" then
				ascii = ascii .. "-"
			elseif seq == "\226\151\143" then
				ascii = ascii .. "."
			else
				ascii = ascii .. "?"
			end
			i = i + 3
		elseif b >= 0xC0 then
			ascii = ascii .. "?"; i = i + 2
		elseif b < 0x80 then
			ascii = ascii .. display:sub(i, i); i = i + 1
		else
			i = i + 1
		end
	end
	setclipboard(ascii)
	sTick:Play()
	morseLabelBtn.TextColor3 = C.green
	task.delay(0.6, function() morseLabelBtn.TextColor3 = Color3.fromRGB(185,185,185) end)
end)
inputBox.FocusLost:Connect(function(entered)
	if entered and not isPlaying and #inputBox.Text>0 then
		coroutine.wrap(function() playText(inputBox.Text) end)()
	end
end)
playBtn.MouseButton1Click:Connect(function()
	if isPlaying or #inputBox.Text==0 then return end
	coroutine.wrap(function() playText(inputBox.Text) end)()
end)
stopBtn.MouseButton1Click:Connect(function() isPlaying=false end)
