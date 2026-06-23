local players = game:GetService("Players")
local vim = game:GetService("VirtualInputManager")
local run = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local ts = game:GetService("TweenService")
local lp = players.LocalPlayer
local gui = lp:WaitForChild("PlayerGui")
local cam = workspace.CurrentCamera

local morse = {
	A="●‒", B="‒●●●", C="‒●‒●", D="‒●●",  E="●",
	F="●●‒●", G="‒‒●", H="●●●●", I="●●",  J="●‒‒‒",
	K="‒●‒", L="●‒●●", M="‒‒",  N="‒●",   O="‒‒‒",
	P="●‒‒●", Q="‒‒●‒", R="●‒●", S="●●●", T="‒",
	U="●●‒", V="●●●‒", W="●‒‒",  X="‒●●‒", Y="‒●‒‒", Z="‒‒●●"
}
local morse_rev = {}
for k,v in pairs(morse) do morse_rev[v]=k end

local dot_dur    = 0.35
local dash_dur   = 0.55
local sym_gap    = 0.15
local letter_gap = 0.7
local word_gap   = 1.0
local letter_to  = 1.2
local word_to    = 2.6

local k_space = Enum.KeyCode.Space
local k_d     = Enum.KeyCode.D
local k_a     = Enum.KeyCode.A

local playing    = false
local dash_dir   = true
local cur_mode   = "sender"
local watch_tgt  = nil
local minimized  = false

local function make_sound(id, vol, pitch)
	local s = Instance.new("Sound")
	s.SoundId = id; s.Volume = vol; s.PlaybackSpeed = pitch
	s.RollOffMaxDistance = 0
	s.Parent = workspace
	return s
end
local snd_click  = make_sound("rbxassetid://138567614125924", 0.6, 1.4)
local snd_tick   = make_sound("rbxassetid://137872392480008", 0.4, 0.9)
local snd_typing = make_sound("rbxassetid://127105730240202", 0.3, 1.0)
local snd_decode = make_sound("rbxassetid://138567614125924", 0.45, 0.65)

local c = {
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
	btn     = Color3.fromRGB(50, 50, 50),
	btn_stop= Color3.fromRGB(58, 38, 38),
	tab_on  = Color3.fromRGB(55, 55, 55),
	tab_off = Color3.fromRGB(38, 38, 38),
	toggle  = Color3.fromRGB(45, 45, 45),
}

local function corner(p, r)
	local o = Instance.new("UICorner", p)
	o.CornerRadius = UDim.new(0, r or 4)
end
local function stroke(p, col, thick)
	local o = Instance.new("UIStroke", p)
	o.Color = col or c.stroke; o.Thickness = thick or 1
end
local function tw(obj, info, props)
	ts:Create(obj, info, props):Play()
end
local fast = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local med  = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local screen = Instance.new("ScreenGui")
screen.Name = "MorseGUI"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.IgnoreGuiInset = true
screen.Parent = gui

local toggle_btn = Instance.new("TextButton")
toggle_btn.Size = UDim2.new(0, 100, 0, 28)
toggle_btn.Position = UDim2.new(0, 12, 1, -48)
toggle_btn.BackgroundColor3 = c.toggle
toggle_btn.Text = "morse"
toggle_btn.TextColor3 = c.dim
toggle_btn.TextSize = 11
toggle_btn.Font = Enum.Font.Gotham
toggle_btn.BorderSizePixel = 0
toggle_btn.Visible = false
toggle_btn.ZIndex = 10
toggle_btn.Parent = screen
corner(toggle_btn, 4); stroke(toggle_btn)

local fw, fh = 400, 256
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, fw, 0, fh)
frame.Position = UDim2.new(0.5, -fw/2, 0.5, -fh/2)
frame.BackgroundColor3 = c.bg
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.ClipsDescendants = true
frame.Parent = screen
corner(frame, 5); stroke(frame)

local title_h = 34
local title_bar = Instance.new("Frame")
title_bar.Size = UDim2.new(1, 0, 0, title_h)
title_bar.BackgroundColor3 = c.bar
title_bar.BorderSizePixel = 0
title_bar.Parent = frame
corner(title_bar, 5)
local t_fix = Instance.new("Frame")
t_fix.Size = UDim2.new(1, 0, 0.5, 0)
t_fix.Position = UDim2.new(0, 0, 0.5, 0)
t_fix.BackgroundColor3 = c.bar
t_fix.BorderSizePixel = 0
t_fix.Parent = title_bar

local title_lbl = Instance.new("TextLabel")
title_lbl.Size = UDim2.new(1, -80, 1, 0)
title_lbl.Position = UDim2.new(0, 10, 0, 0)
title_lbl.BackgroundTransparency = 1
title_lbl.Text = "roblox morse code by novi.w"
title_lbl.TextColor3 = Color3.fromRGB(175, 175, 175)
title_lbl.TextSize = 11
title_lbl.Font = Enum.Font.Gotham
title_lbl.TextXAlignment = Enum.TextXAlignment.Left
title_lbl.Parent = title_bar

local min_btn = Instance.new("TextButton")
min_btn.Size = UDim2.new(0, 28, 0, 20)
min_btn.Position = UDim2.new(1, -62, 0.5, -10)
min_btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
min_btn.Text = "—"
min_btn.TextColor3 = c.dim
min_btn.TextSize = 10
min_btn.Font = Enum.Font.Gotham
min_btn.BorderSizePixel = 0
min_btn.Parent = title_bar
corner(min_btn, 3)

local close_btn = Instance.new("TextButton")
close_btn.Size = UDim2.new(0, 28, 0, 20)
close_btn.Position = UDim2.new(1, -30, 0.5, -10)
close_btn.BackgroundColor3 = Color3.fromRGB(68, 42, 42)
close_btn.Text = "X"
close_btn.TextColor3 = Color3.fromRGB(180, 145, 145)
close_btn.TextSize = 10
close_btn.Font = Enum.Font.Gotham
close_btn.BorderSizePixel = 0
close_btn.Parent = title_bar
corner(close_btn, 3)

local content = Instance.new("Frame")
content.Size = UDim2.new(1, 0, 1, -title_h)
content.Position = UDim2.new(0, 0, 0, title_h)
content.BackgroundTransparency = 1
content.ClipsDescendants = true
content.Parent = frame

local tab_top = 8
local tab_row = Instance.new("Frame")
tab_row.Size = UDim2.new(1, -18, 0, 26)
tab_row.Position = UDim2.new(0, 9, 0, tab_top)
tab_row.BackgroundTransparency = 1
tab_row.Parent = content

local tab_send = Instance.new("TextButton")
tab_send.Size = UDim2.new(0.5, -3, 1, 0)
tab_send.Position = UDim2.new(0, 0, 0, 0)
tab_send.BackgroundColor3 = c.tab_on
tab_send.Text = "sender"
tab_send.TextColor3 = Color3.fromRGB(210, 210, 210)
tab_send.TextSize = 12
tab_send.Font = Enum.Font.Gotham
tab_send.BorderSizePixel = 0
tab_send.Parent = tab_row
corner(tab_send, 4); stroke(tab_send)

local tab_trans = Instance.new("TextButton")
tab_trans.Size = UDim2.new(0.5, -3, 1, 0)
tab_trans.Position = UDim2.new(0.5, 3, 0, 0)
tab_trans.BackgroundColor3 = c.tab_off
tab_trans.Text = "translator"
tab_trans.TextColor3 = Color3.fromRGB(130, 130, 130)
tab_trans.TextSize = 12
tab_trans.Font = Enum.Font.Gotham
tab_trans.BorderSizePixel = 0
tab_trans.Parent = tab_row
corner(tab_trans, 4); stroke(tab_trans)

local panel_top = tab_top + 26 + 6
local panel_h   = (fh - title_h) - panel_top - 8

local send_panel = Instance.new("Frame")
send_panel.Size = UDim2.new(1, -18, 0, panel_h)
send_panel.Position = UDim2.new(0, 9, 0, panel_top)
send_panel.BackgroundTransparency = 1
send_panel.Parent = content

local input_box = Instance.new("TextBox")
input_box.Size = UDim2.new(1, 0, 0, 34)
input_box.BackgroundColor3 = c.input
input_box.TextColor3 = Color3.fromRGB(215, 215, 215)
input_box.PlaceholderText = "type message, press enter..."
input_box.PlaceholderColor3 = Color3.fromRGB(90, 90, 90)
input_box.Text = ""
input_box.TextSize = 13
input_box.Font = Enum.Font.Gotham
input_box.ClearTextOnFocus = false
input_box.BorderSizePixel = 0
input_box.Parent = send_panel
corner(input_box, 4); stroke(input_box)

local morse_btn = Instance.new("TextButton")
morse_btn.Size = UDim2.new(1, 0, 0, 20)
morse_btn.Position = UDim2.new(0, 0, 0, 40)
morse_btn.BackgroundTransparency = 1
morse_btn.Text = "morse: —"
morse_btn.TextColor3 = Color3.fromRGB(185, 185, 185)
morse_btn.TextSize = 11
morse_btn.Font = Enum.Font.Code
morse_btn.TextXAlignment = Enum.TextXAlignment.Left
morse_btn.TextTruncate = Enum.TextTruncate.AtEnd
morse_btn.BorderSizePixel = 0
morse_btn.AutoButtonColor = false
morse_btn.Parent = send_panel

local status_lbl = Instance.new("TextLabel")
status_lbl.Size = UDim2.new(1, 0, 0, 16)
status_lbl.Position = UDim2.new(0, 0, 0, 62)
status_lbl.BackgroundTransparency = 1
status_lbl.Text = "idle"
status_lbl.TextColor3 = Color3.fromRGB(140, 140, 140)
status_lbl.TextSize = 11
status_lbl.Font = Enum.Font.Gotham
status_lbl.TextXAlignment = Enum.TextXAlignment.Left
status_lbl.Parent = send_panel

local play_btn = Instance.new("TextButton")
play_btn.Size = UDim2.new(0.48, 0, 0, 28)
play_btn.Position = UDim2.new(0, 0, 1, -28)
play_btn.BackgroundColor3 = c.btn
play_btn.Text = "play"
play_btn.TextColor3 = Color3.fromRGB(210, 210, 210)
play_btn.TextSize = 12
play_btn.Font = Enum.Font.Gotham
play_btn.BorderSizePixel = 0
play_btn.Parent = send_panel
corner(play_btn, 4); stroke(play_btn)

local stop_btn = Instance.new("TextButton")
stop_btn.Size = UDim2.new(0.48, 0, 0, 28)
stop_btn.Position = UDim2.new(0.52, 0, 1, -28)
stop_btn.BackgroundColor3 = c.btn_stop
stop_btn.Text = "stop"
stop_btn.TextColor3 = Color3.fromRGB(200, 155, 155)
stop_btn.TextSize = 12
stop_btn.Font = Enum.Font.Gotham
stop_btn.BorderSizePixel = 0
stop_btn.Parent = send_panel
corner(stop_btn, 4); stroke(stop_btn, Color3.fromRGB(88, 52, 52))

local trans_panel = Instance.new("Frame")
trans_panel.Size = UDim2.new(1, -18, 0, panel_h)
trans_panel.Position = UDim2.new(0, 9, 0, panel_top)
trans_panel.BackgroundTransparency = 1
trans_panel.Visible = false
trans_panel.Parent = content

local pick_btn = Instance.new("TextButton")
pick_btn.Size = UDim2.new(1, 0, 0, 30)
pick_btn.BackgroundColor3 = c.btn
pick_btn.Text = "click a player to watch"
pick_btn.TextColor3 = Color3.fromRGB(150, 150, 150)
pick_btn.TextSize = 12
pick_btn.Font = Enum.Font.Gotham
pick_btn.BorderSizePixel = 0
pick_btn.Parent = trans_panel
corner(pick_btn, 4); stroke(pick_btn)

local watching_lbl = Instance.new("TextLabel")
watching_lbl.Size = UDim2.new(1, 0, 0, 16)
watching_lbl.Position = UDim2.new(0, 0, 0, 36)
watching_lbl.BackgroundTransparency = 1
watching_lbl.Text = "watching: none"
watching_lbl.TextColor3 = Color3.fromRGB(140, 140, 140)
watching_lbl.TextSize = 11
watching_lbl.Font = Enum.Font.Gotham
watching_lbl.TextXAlignment = Enum.TextXAlignment.Left
watching_lbl.Parent = trans_panel

local raw_morse_lbl = Instance.new("TextLabel")
raw_morse_lbl.Size = UDim2.new(1, 0, 0, 16)
raw_morse_lbl.Position = UDim2.new(0, 0, 0, 54)
raw_morse_lbl.BackgroundTransparency = 1
raw_morse_lbl.Text = "buffer: —"
raw_morse_lbl.TextColor3 = Color3.fromRGB(180, 180, 180)
raw_morse_lbl.TextSize = 11
raw_morse_lbl.Font = Enum.Font.Code
raw_morse_lbl.TextXAlignment = Enum.TextXAlignment.Left
raw_morse_lbl.Parent = trans_panel

local decoded_box = Instance.new("Frame")
decoded_box.Size = UDim2.new(1, 0, 0, 36)
decoded_box.Position = UDim2.new(0, 0, 0, 74)
decoded_box.BackgroundColor3 = c.input
decoded_box.BorderSizePixel = 0
decoded_box.Parent = trans_panel
corner(decoded_box, 4); stroke(decoded_box)

local decoded_txt = Instance.new("TextLabel")
decoded_txt.Size = UDim2.new(1, -10, 1, 0)
decoded_txt.Position = UDim2.new(0, 6, 0, 0)
decoded_txt.BackgroundTransparency = 1
decoded_txt.Text = "—"
decoded_txt.TextColor3 = Color3.fromRGB(215, 215, 215)
decoded_txt.TextSize = 14
decoded_txt.Font = Enum.Font.GothamBold
decoded_txt.TextXAlignment = Enum.TextXAlignment.Left
decoded_txt.TextTruncate = Enum.TextTruncate.AtEnd
decoded_txt.Parent = decoded_box

local ac_lbl = Instance.new("TextLabel")
ac_lbl.Size = UDim2.new(1, 0, 0, 14)
ac_lbl.Position = UDim2.new(0, 0, 0, 114)
ac_lbl.BackgroundTransparency = 1
ac_lbl.Text = "autocomplete: —"
ac_lbl.TextColor3 = Color3.fromRGB(130, 130, 130)
ac_lbl.TextSize = 11
ac_lbl.Font = Enum.Font.Gotham
ac_lbl.TextXAlignment = Enum.TextXAlignment.Left
ac_lbl.Parent = trans_panel

local clear_btn = Instance.new("TextButton")
clear_btn.Size = UDim2.new(1, 0, 0, 26)
clear_btn.Position = UDim2.new(0, 0, 1, -26)
clear_btn.BackgroundColor3 = c.btn_stop
clear_btn.Text = "clear"
clear_btn.TextColor3 = Color3.fromRGB(200, 155, 155)
clear_btn.TextSize = 12
clear_btn.Font = Enum.Font.Gotham
clear_btn.BorderSizePixel = 0
clear_btn.Parent = trans_panel
corner(clear_btn, 4); stroke(clear_btn, Color3.fromRGB(88, 52, 52))

do
	local dragging, drag_start, start_pos = false, nil, nil
	title_bar.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.Touch
		or inp.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging   = true
			drag_start = inp.Position
			start_pos  = frame.Position
		end
	end)
	title_bar.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.Touch
		or inp.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	uis.InputChanged:Connect(function(inp)
		if dragging and (inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseMovement) then
			local d = inp.Position - drag_start
			frame.Position = UDim2.new(start_pos.X.Scale, start_pos.X.Offset + d.X, start_pos.Y.Scale, start_pos.Y.Offset + d.Y)
		end
	end)
end

local function set_minimized(val)
	minimized = val
	if minimized then
		tw(frame, med, { Size = UDim2.new(0, fw, 0, title_h) })
	else
		tw(frame, med, { Size = UDim2.new(0, fw, 0, fh) })
	end
end

min_btn.MouseButton1Click:Connect(function()
	set_minimized(not minimized)
end)

close_btn.MouseButton1Click:Connect(function()
	tw(frame, fast, { BackgroundTransparency = 1 })
	task.delay(0.2, function()
		frame.Visible = false
		frame.BackgroundTransparency = 0
		toggle_btn.Visible = true
	end)
end)

toggle_btn.MouseButton1Click:Connect(function()
	frame.Visible = true
	frame.Size = UDim2.new(0, fw, 0, title_h)
	tw(frame, med, { Size = UDim2.new(0, fw, 0, fh) })
	minimized = false
	toggle_btn.Visible = false
end)

local function add_hover(btn, norm, hov)
	btn.MouseEnter:Connect(function() tw(btn, fast, { BackgroundColor3 = hov }) end)
	btn.MouseLeave:Connect(function() tw(btn, fast, { BackgroundColor3 = norm }) end)
end
add_hover(play_btn,   c.btn,      Color3.fromRGB(65,65,65))
add_hover(stop_btn,   c.btn_stop, Color3.fromRGB(75,48,48))
add_hover(clear_btn,  c.btn_stop, Color3.fromRGB(75,48,48))
add_hover(pick_btn,   c.btn,      Color3.fromRGB(65,65,65))
add_hover(min_btn,    Color3.fromRGB(50,50,50), Color3.fromRGB(70,70,70))
add_hover(close_btn,  Color3.fromRGB(68,42,42), Color3.fromRGB(95,55,55))
add_hover(toggle_btn, c.toggle,   Color3.fromRGB(60,60,60))

local function cwait(t)
	local s = tick()
	while tick()-s < t do
		if not playing then return end
		run.Heartbeat:Wait()
	end
end
local function press(key, dur)
	if not playing then return end
	vim:SendKeyEvent(true, key, false, nil)
	cwait(dur)
	vim:SendKeyEvent(false, key, false, nil)
end
local function set_status(txt, col)
	status_lbl.Text = txt
	status_lbl.TextColor3 = col or Color3.fromRGB(140,140,140)
end
local function build_display(text)
	local parts = {}
	for i=1,#text do
		local ch = text:sub(i,i):upper()
		if ch==" " then table.insert(parts,"/")
		elseif morse[ch] then table.insert(parts, morse[ch]) end
	end
	return table.concat(parts," ")
end
local function to_tokens(text)
	local out = {}
	for i=1,#text do
		local ch = text:sub(i,i):upper()
		if ch==" " then table.insert(out,"WORD")
		elseif morse[ch] then table.insert(out, ch) end
	end
	return out
end
local function get_syms(pat)
	local syms, j = {}, 1
	while j <= #pat do
		local b = pat:byte(j)
		local len = 1
		if b >= 0xF0 then len=4 elseif b >= 0xE0 then len=3 elseif b >= 0xC0 then len=2 end
		table.insert(syms, pat:sub(j, j+len-1))
		j = j+len
	end
	return syms
end
local function play_sym(sym)
	if not playing then return end
	if sym == "●" then
		snd_click:Play(); set_status("jumping", c.green); press(k_space, dot_dur)
	elseif sym == "‒" then
		snd_tick:Play()
		local key = dash_dir and k_d or k_a; dash_dir = not dash_dir
		set_status("stepping", c.accent); press(key, dash_dur)
	end
	cwait(sym_gap)
end
local function play_text(text)
	playing = true; dash_dir = true
	for _, token in ipairs(to_tokens(text)) do
		if not playing then break end
		if token == "WORD" then
			set_status("word gap...", c.yellow); cwait(word_gap)
		else
			local pat = morse[token]
			set_status(token.."  "..pat, c.text)
			for _, s in ipairs(get_syms(pat)) do
				if not playing then break end
				play_sym(s)
			end
			if playing then set_status("letter gap...", c.yellow); cwait(letter_gap) end
		end
	end
	if playing then set_status("done", c.green) else set_status("stopped", c.red) end
	playing = false
end

local watch_conns = {}
local decode_buf, decoded_out = "", ""
local letter_timer = nil

local function get_ac(buf)
	if #buf==0 then return nil end
	local matches = {}
	for pat, letter in pairs(morse_rev) do
		if #pat >= #buf and pat:sub(1,#buf)==buf then
			table.insert(matches, letter.." ("..pat..")")
		end
	end
	if #matches==1 then return matches[1] end
	if #matches>1 then table.sort(matches); return table.concat(matches,"  ") end
	return nil
end
local function flush_letter()
	if #decode_buf==0 then return end
	local letter = morse_rev[decode_buf]
	snd_decode:Play()
	decoded_out = decoded_out..(letter or "?")
	decoded_txt.Text = decoded_out
	raw_morse_lbl.Text = "buffer: "..decode_buf.."  ->  "..(letter or "?")
	ac_lbl.Text = "autocomplete: —"
	decode_buf = ""
end
local function flush_word()
	flush_letter()
	if #decoded_out>0 and decoded_out:sub(-1)~=" " then
		decoded_out = decoded_out.." "
		decoded_txt.Text = decoded_out
	end
end
local function start_letter_timer()
	if letter_timer then letter_timer:Disconnect() end
	local t0 = tick()
	letter_timer = run.Heartbeat:Connect(function()
		local e = tick()-t0
		if e >= word_to then
			flush_word(); letter_timer:Disconnect(); letter_timer=nil
		elseif e >= letter_to then
			flush_letter(); letter_timer:Disconnect(); letter_timer=nil
		end
	end)
end
local function add_sym(sym)
	decode_buf = decode_buf..sym
	raw_morse_lbl.Text = "buffer: "..decode_buf
	ac_lbl.Text = "autocomplete: "..(get_ac(decode_buf) or "—")
	start_letter_timer()
end
local function stop_watching()
	for _,conn in ipairs(watch_conns) do conn:Disconnect() end
	watch_conns = {}
	if letter_timer then letter_timer:Disconnect(); letter_timer=nil end
	watch_tgt = nil; decode_buf = ""
	watching_lbl.Text = "watching: none"; watching_lbl.TextColor3 = c.dim
	pick_btn.Text = "click a player to watch"; pick_btn.TextColor3 = c.dim
end
local function start_watching(player)
	stop_watching(); watch_tgt = player
	watching_lbl.Text = "watching: "..player.Name; watching_lbl.TextColor3 = c.green
	pick_btn.Text = "watching "..player.Name.."  (click to change)"; pick_btn.TextColor3 = c.green
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid", 5)
	if not hum then return end
	local jconn = hum.StateChanged:Connect(function(_, new)
		if new==Enum.HumanoidStateType.Jumping then snd_click:Play(); add_sym("●") end
	end)
	local step_db, prev_state = false, nil
	local sconn = hum.StateChanged:Connect(function(old, new)
		if new==Enum.HumanoidStateType.Running and prev_state~=Enum.HumanoidStateType.Running and not step_db then
			if hum.MoveDirection.Magnitude > 0.1 then
				step_db=true; snd_tick:Play(); add_sym("‒")
				task.delay(0.45, function() step_db=false end)
			end
		end
		prev_state=new
	end)
	local dconn = hum.Died:Connect(stop_watching)
	table.insert(watch_conns, jconn)
	table.insert(watch_conns, sconn)
	table.insert(watch_conns, dconn)
end

local picking = false
pick_btn.MouseButton1Click:Connect(function()
	if watch_tgt then stop_watching(); return end
	if picking then
		picking=false; pick_btn.Text="click a player to watch"; pick_btn.TextColor3=c.dim; return
	end
	picking=true; pick_btn.Text="click on a player..."; pick_btn.TextColor3=c.yellow
	local conn
	conn = uis.InputBegan:Connect(function(inp, gpe)
		if inp.UserInputType~=Enum.UserInputType.MouseButton1
		and inp.UserInputType~=Enum.UserInputType.Touch then return end
		if gpe then
			picking=false; pick_btn.Text="click a player to watch"; pick_btn.TextColor3=c.dim
			conn:Disconnect(); return
		end
		local ray = cam:ScreenPointToRay(inp.Position.X, inp.Position.Y)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		if lp.Character then params.FilterDescendantsInstances={lp.Character} end
		local result = workspace:Raycast(ray.Origin, ray.Direction*500, params)
		if result then
			for _, p in ipairs(players:GetPlayers()) do
				if p~=lp and p.Character and result.Instance:IsDescendantOf(p.Character) then
					picking=false; conn:Disconnect(); start_watching(p); return
				end
			end
		end
		picking=false; pick_btn.Text="no player hit - try again"; pick_btn.TextColor3=c.red
		conn:Disconnect()
	end)
end)

clear_btn.MouseButton1Click:Connect(function()
	decode_buf=""; decoded_out=""
	decoded_txt.Text="—"; raw_morse_lbl.Text="buffer: —"; ac_lbl.Text="autocomplete: —"
end)

local function switch_tab(to)
	cur_mode = to
	snd_click:Play()
	if to=="sender" then
		send_panel.Visible=true; trans_panel.Visible=false
		tw(tab_send, fast, {BackgroundColor3=c.tab_on}); tab_send.TextColor3=Color3.fromRGB(210,210,210)
		tw(tab_trans, fast, {BackgroundColor3=c.tab_off}); tab_trans.TextColor3=Color3.fromRGB(130,130,130)
	else
		send_panel.Visible=false; trans_panel.Visible=true
		tw(tab_send, fast, {BackgroundColor3=c.tab_off}); tab_send.TextColor3=Color3.fromRGB(130,130,130)
		tw(tab_trans, fast, {BackgroundColor3=c.tab_on}); tab_trans.TextColor3=Color3.fromRGB(210,210,210)
		if playing then playing=false end
	end
end
tab_send.MouseButton1Click:Connect(function() switch_tab("sender") end)
tab_trans.MouseButton1Click:Connect(function() switch_tab("translator") end)

input_box:GetPropertyChangedSignal("Text"):Connect(function()
	snd_typing:Play()
	local t = input_box.Text
	morse_btn.Text = #t>0 and ("morse: "..build_display(t)) or "morse: —"
end)

morse_btn.MouseButton1Click:Connect(function()
	local raw = input_box.Text
	if #raw == 0 then return end
	local display = build_display(raw)
	local ascii = ""
	local i = 1
	while i <= #display do
		local b = display:byte(i)
		if b >= 0xF0 then
			ascii = ascii.."?"; i = i+4
		elseif b >= 0xE0 then
			local seq = display:sub(i, i+2)
			if seq == "\226\128\146" then ascii = ascii.."-"
			elseif seq == "\226\151\143" then ascii = ascii.."."
			else ascii = ascii.."?" end
			i = i+3
		elseif b >= 0xC0 then
			ascii = ascii.."?"; i = i+2
		elseif b < 0x80 then
			ascii = ascii..display:sub(i,i); i = i+1
		else
			i = i+1
		end
	end
	setclipboard(ascii)
	snd_tick:Play()
	morse_btn.TextColor3 = c.green
	task.delay(0.6, function() morse_btn.TextColor3 = Color3.fromRGB(185,185,185) end)
end)

input_box.FocusLost:Connect(function(entered)
	if entered and not playing and #input_box.Text>0 then
		coroutine.wrap(function() play_text(input_box.Text) end)()
	end
end)
play_btn.MouseButton1Click:Connect(function()
	if playing or #input_box.Text==0 then return end
	coroutine.wrap(function() play_text(input_box.Text) end)()
end)
stop_btn.MouseButton1Click:Connect(function() playing=false end)
