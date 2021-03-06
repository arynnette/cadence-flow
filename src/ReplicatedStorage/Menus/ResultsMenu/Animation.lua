local RunService = game:GetService("RunService")
local rs = RunService.RenderStepped
local hb = RunService.Heartbeat
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local rng = Random.new(tick())

local Animation = {}

function Animation.new(ui)
	local self = {}

	local UI = ui

	local FPSCAP = 1/60

	self.running = false

	-- >> SFX
	local sfx = {folder = UI.SFX}
	sfx.temp = sfx.folder.Temp
	sfx.list  = {
		scorerise = sfx.folder.Scorerise
	}

	function sfx:play(base)
		local sound = base:Clone()
		sound.PlayOnRemove = true
		sound.Parent = sfx.temp
		sound:Destroy()
	end

	-- >> BGM
	local bgm = {folder = UI.BGM}
	bgm.current = 0
	bgm.list = {
		[0] = bgm.folder['0'],
		[1] = bgm.folder['1'],
		[2] = bgm.folder['2'],
		[3] = bgm.folder['3'],
		[4] = bgm.folder['4'],
		[5] = bgm.folder['5']}

	function bgm:preload()
		if not bgm.list[0].IsLoaded then
			bgm.list[0].Loaded:Wait()
		end
	end

	bgm.thread = coroutine.wrap(function()
		bgm.list[0].Playing = true
		bgm.current = 0
		while (bgm.current < 5) and (self.running) do
			if (bgm.list[bgm.current].Playing == false)
			and (bgm.list[bgm.current+1].IsLoaded == true) then
				bgm.current += 1;
				bgm.list[bgm.current].Playing = true
			end
			hb:Wait()
		end
		print("Results BGM all finished.")
	end)

	-- >> Background elements
	local bg = {UI = UI.BG}

	-- (Tile)
	bg.tile = {ui = bg.UI.Tile}

	bg.tile.cover = bg.tile.ui.Cover
	bg.tile.pos0 = UDim2.new(0.5,0,0,0)
	bg.tile.pos1 = UDim2.new(0.5,0,-1,0)
	bg.tile.info_pos = TweenInfo.new(9, Enum.EasingStyle.Linear)
	bg.tile.tween_pos = TweenService:Create(bg.tile.ui, 
		bg.tile.info_pos, {Position = bg.tile.pos1})
	bg.tile.info_trans = TweenInfo.new(.7)
	bg.tile.tween_trans0 = TweenService:Create(bg.tile.cover, 
		bg.tile.info_trans, {BackgroundTransparency = 0})
	bg.tile.tween_trans1 = TweenService:Create(bg.tile.cover, 
		bg.tile.info_trans, {BackgroundTransparency = 1})
	bg.tile.delay_trans = 8

	bg.tile.thread_pos = coroutine.wrap(function()
		while self.running do
			bg.tile.ui.Position = bg.tile.pos0
			bg.tile.tween_pos:Play()
			bg.tile.tween_pos.Completed:Wait()
		end
	end)

	bg.tile.thread_trans = coroutine.wrap(function()
		while self.running do
			bg.tile.tween_trans0:Play() bg.tile.tween_trans0.Completed:Wait()
			for i=0,5 do
				local v = bg.tile.ui[tostring(i)]
				if bgm.current == i then
					v.Visible = true
				else v.Visible = false end
			end
			bg.tile.tween_trans1:Play() bg.tile.tween_trans1.Completed:Wait()
			wait(bg.tile.delay_trans)
		end
	end)

	-- (Spinner)
	bg.spinner = {ui = bg.UI.Spinner}
	bg.spinner.info = {
		TweenInfo.new(1, Enum.EasingStyle.Linear),
		TweenInfo.new(3, Enum.EasingStyle.Linear),
		TweenInfo.new(4, Enum.EasingStyle.Linear),
		TweenInfo.new(6, Enum.EasingStyle.Linear)
	}
	bg.spinner.tween = {
		TweenService:Create(bg.spinner.ui['1'], bg.spinner.info[1], {Rotation = 360}),
		TweenService:Create(bg.spinner.ui['2'], bg.spinner.info[2], {Rotation = 0}),
		TweenService:Create(bg.spinner.ui['3'], bg.spinner.info[3], {Rotation = 360}),
		TweenService:Create(bg.spinner.ui['4'], bg.spinner.info[4], {Rotation = 0})
	}

	bg.spinner.thread = {
		coroutine.wrap(function()
			local tween = bg.spinner.tween[1]
			while self.running do
				bg.spinner.ui['1'].Rotation = 0
				tween:Play() tween.Completed:Wait()
			end end),
		coroutine.wrap(function()
			local tween = bg.spinner.tween[2]
			while self.running do
				bg.spinner.ui['2'].Rotation = 360
				tween:Play() tween.Completed:Wait()
			end end),
		coroutine.wrap(function()
			local tween = bg.spinner.tween[3]
			while self.running do
				bg.spinner.ui['3'].Rotation = 0
				tween:Play() tween.Completed:Wait()
			end end),
		coroutine.wrap(function()
			local tween = bg.spinner.tween[4]
			while self.running do
				bg.spinner.ui['4'].Rotation = 360
				tween:Play() tween.Completed:Wait()
			end end),
	}

	-- (Runline)
	bg.runline = {ui = bg.UI.Runline}
	bg.runline.info = TweenInfo.new(3,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut)
	bg.runline.offset0 = Vector2.new(-1,0)
	bg.runline.offset1 = Vector2.new(1,0)
	bg.runline.delay = {2,.3,6}
	bg.runline.grad = {
		bg.runline.ui['1'].UIGradient,
		bg.runline.ui['2'].UIGradient,
		bg.runline.ui['3'].UIGradient
	}
	bg.runline.tween = {}
	for i=1,3 do
		bg.runline.tween[i] = TweenService:Create(bg.runline.grad[i], 
			bg.runline.info, {Offset = bg.runline.offset1})
	end

	function bg.runline.reset()
		for i=1,3 do
			bg.runline.grad[i].Offset = bg.runline.offset0
			bg.runline.tween[i]:Cancel()
		end
	end

	bg.runline.thread = coroutine.wrap(function()
		while self.running do
			bg.runline.reset()
			for i=1,3 do
				bg.runline.tween[i]:Play() bg.runline.tween[i].Completed:Wait()
			end
			wait(bg.runline.delay[1])
			bg.runline.reset()
			for i=1,3 do
				bg.runline.tween[i]:Play() wait(bg.runline.delay[2])
			end
			wait(bg.runline.delay[3])
		end
		bg.runline.reset()
	end)

	-- (Particles)
	bg.particles = {ui = bg.UI.Particles}
	bg.particles.base = bg.particles.ui.Base
	bg.particles.temp = bg.particles.ui.Temp

	function bg.particles.new()
		local particle = bg.particles.base:Clone()
		local size = rng:NextNumber(0.005,0.024)
		local pos0 = UDim2.new(rng:NextNumber(0,1),0,1,0)
		local pos1 = pos0 - UDim2.new(0,0,1,0)
		local trans = rng:NextNumber(0.7,0.95)
		local runtime = rng:NextNumber(10,20) 
		local tween0 = TweenService:Create(particle,
			TweenInfo.new(runtime*0.8),{ImageTransparency = trans})
		local tween1 = TweenService:Create(particle,
			TweenInfo.new(runtime*0.2),{ImageTransparency = 1})
		particle.Size = UDim2.new(size,0,size,0)
		particle.Position = pos0
		particle.Parent = bg.particles.temp
		particle.ImageTransparency = 1
		particle:TweenPosition(pos1,"Out","Linear",runtime)
		tween0:Play()
		coroutine.wrap(function()
			tween0.Completed:Wait()
			if particle.Parent then tween1:Play() end
		end)()
		Debris:AddItem(particle,runtime)
	end

	bg.particles.thread = coroutine.wrap(function()
		while self.running do
			for i=1,rng:NextInteger(1,6) do bg.particles.new() end
			local waittime = (rng:NextNumber(.05,.2))
			wait(waittime)
		end
		bg.particles.temp:ClearAllChildren()
	end)

	-- (Hoop)
	bg.hoop = {ui = bg.UI.Hoop}

	bg.hoop.size0 = UDim2.new(0.3,0,0.3,0)
	bg.hoop.size1 = UDim2.new(1.5,0,1.5,0)
	bg.hoop.runtime = 4
	bg.hoop.delay = 5
	bg.hoop.info_size = TweenInfo.new(bg.hoop.runtime, Enum.EasingStyle.Quart)
	bg.hoop.info_trans0 = TweenInfo.new(bg.hoop.runtime*.5, 
		Enum.EasingStyle.Quint, Enum.EasingDirection.In)
	bg.hoop.info_trans1 = TweenInfo.new(bg.hoop.runtime*.5, Enum.EasingStyle.Sine)
	bg.hoop.tween_size = TweenService:Create(bg.hoop.ui, 
		bg.hoop.info_size, {Size = bg.hoop.size1, Rotation = 180})
	bg.hoop.tween_trans0 = TweenService:Create(bg.hoop.ui, 
		bg.hoop.info_trans0, {ImageTransparency = .85})
	bg.hoop.tween_trans1 = TweenService:Create(bg.hoop.ui, 
		bg.hoop.info_trans1, {ImageTransparency = 1})

	bg.hoop.thread = coroutine.wrap(function()
		while self.running do
			bg.hoop.ui.Rotation = 0
			bg.hoop.ui.ImageTransparency = 1
			bg.hoop.ui.Size = bg.hoop.size0
			bg.hoop.tween_size:Play()
			bg.hoop.tween_trans0:Play()
			coroutine.wrap(function()
				bg.hoop.tween_trans0.Completed:Wait()
				bg.hoop.tween_trans1:Play()
			end)()
			wait(bg.hoop.runtime)
			bg.hoop.tween_size:Cancel()
			bg.hoop.tween_trans1:Cancel()
			wait(bg.hoop.delay)
		end
		bg.hoop.tween_size:Cancel()
		bg.hoop.tween_trans0:Cancel()
		bg.hoop.tween_trans1:Cancel()
	end)

	-- > Background Thread
	function bg.thread()
		bg.tile.thread_pos()
		bg.tile.thread_trans()
		bg.runline.thread()
		bg.particles.thread()
		bg.hoop.thread()
		for i,thread in pairs(bg.spinner.thread) do
			thread()
		end
	end

	-- >> Judgement
	local judgement = {UI = UI.Judgement}

	judgement.BG = judgement.UI.BG

	judgement.anim = {}
	judgement.anim.grad = judgement.BG.UIGradient
	judgement.anim.delay = 3
	judgement.anim.info_grad = TweenInfo.new(1.5,Enum.EasingStyle.Linear)
	judgement.anim.info_flash0 = TweenInfo.new(.1,Enum.EasingStyle.Linear)
	judgement.anim.info_flash1 = TweenInfo.new(1.5,Enum.EasingStyle.Linear)
	judgement.anim.offset0 = Vector2.new(-1,0)
	judgement.anim.offset1 = Vector2.new(1,0)
	judgement.anim.color0 = Color3.new(0,0,0)
	judgement.anim.color1 = Color3.new(0.25,0.25,0.25)
	judgement.anim.tween_grad = TweenService:Create(judgement.anim.grad,
		judgement.anim.info_grad,	{Offset = judgement.anim.offset1})
	judgement.anim.tween_flash0 = TweenService:Create(judgement.UI,
		judgement.anim.info_flash0,	{BackgroundColor3 = judgement.anim.color0})
	judgement.anim.tween_flash1 = TweenService:Create(judgement.UI,
		judgement.anim.info_flash1,	{BackgroundColor3 = judgement.anim.color0})

	judgement.anim.thread = coroutine.wrap(function()
		while self.running do
			judgement.UI.BackgroundColor3 = judgement.anim.color0
			judgement.anim.grad.Offset = judgement.anim.offset0
			judgement.anim.tween_grad:Play() judgement.anim.tween_grad.Completed:Wait()
			judgement.UI.BackgroundColor3 = judgement.anim.color1
			judgement.anim.tween_flash0:Play() judgement.anim.tween_flash0.Completed:Wait()
			judgement.UI.BackgroundColor3 = judgement.anim.color1
			judgement.anim.tween_flash1:Play() judgement.anim.tween_flash1.Completed:Wait()
			wait(judgement.anim.delay)
		end
		judgement.anim.tween_grad:Cancel()
		judgement.anim.tween_flash0:Cancel()
		judgement.anim.tween_flash1:Cancel()
	end)

	-- >> Statistics
	local statistics = {UI = UI.Statistics}

	statistics.BG = statistics.UI.BG

	statistics.anim = {}
	statistics.anim.grad = statistics.BG.UIGradient
	statistics.anim.delay = 3
	statistics.anim.info_grad = TweenInfo.new(1.5,Enum.EasingStyle.Linear)
	statistics.anim.info_flash0 = TweenInfo.new(.1,Enum.EasingStyle.Linear)
	statistics.anim.info_flash1 = TweenInfo.new(1.5,Enum.EasingStyle.Linear)
	statistics.anim.offset0 = Vector2.new(-1,0)
	statistics.anim.offset1 = Vector2.new(1,0)
	statistics.anim.color0 = Color3.new(0,0,0)
	statistics.anim.color1 = Color3.new(0.25,0.25,0.25)
	statistics.anim.tween_grad = TweenService:Create(statistics.anim.grad,
		statistics.anim.info_grad,	{Offset = statistics.anim.offset1})
	statistics.anim.tween_flash0 = TweenService:Create(statistics.UI,
		statistics.anim.info_flash0,	{BackgroundColor3 = statistics.anim.color0})
	statistics.anim.tween_flash1 = TweenService:Create(statistics.UI,
		statistics.anim.info_flash1,	{BackgroundColor3 = statistics.anim.color0})

	statistics.anim.thread = coroutine.wrap(function()
		while self.running do
			statistics.UI.BackgroundColor3 = statistics.anim.color0
			statistics.anim.grad.Offset = statistics.anim.offset0
			statistics.anim.tween_grad:Play() statistics.anim.tween_grad.Completed:Wait()
			statistics.UI.BackgroundColor3 = statistics.anim.color1
			statistics.anim.tween_flash0:Play() statistics.anim.tween_flash0.Completed:Wait()
			statistics.UI.BackgroundColor3 = statistics.anim.color1
			statistics.anim.tween_flash1:Play() statistics.anim.tween_flash1.Completed:Wait()
			wait(statistics.anim.delay)
		end
		statistics.anim.tween_grad:Cancel()
		statistics.anim.tween_flash0:Cancel()
		statistics.anim.tween_flash1:Cancel()
	end)

	-- >> Graph
	local graph = {UI = UI.Graph}

	graph.BG = graph.UI.BG

	graph.anim = {}
	graph.anim.grad = graph.BG.UIGradient
	graph.anim.info_grad = TweenInfo.new(8,Enum.EasingStyle.Linear)
	graph.anim.offset0 = Vector2.new(0,-1)
	graph.anim.offset1 = Vector2.new(0,1)
	graph.anim.tween_trans = TweenService:Create(graph.BG,
		graph.anim.info_grad,	{BackgroundTransparency = 0.8})
	graph.anim.tween_grad0 = TweenService:Create(graph.anim.grad,
		graph.anim.info_grad,	{Offset = graph.anim.offset0})
	graph.anim.tween_grad1 = TweenService:Create(graph.anim.grad,
		graph.anim.info_grad,	{Offset = graph.anim.offset1})

	graph.anim.thread = coroutine.wrap(function()
		graph.anim.grad.Offset = graph.anim.offset0
		while self.running do
			graph.BG.BackgroundTransparency = 1
			graph.anim.grad.Rotation = 90
			graph.anim.tween_trans:Play()
			graph.anim.tween_grad1:Play() graph.anim.tween_grad1.Completed:Wait()
			graph.anim.tween_trans:Cancel()
			graph.BG.BackgroundTransparency = 1
			graph.anim.grad.Rotation = -90
			graph.anim.tween_trans:Play()
			graph.anim.tween_grad0:Play() graph.anim.tween_grad0.Completed:Wait()
			graph.anim.tween_trans:Cancel()
		end
		graph.anim.tween_grad1:Cancel()
		graph.anim.tween_grad0:Cancel()
		graph.anim.tween_trans:Cancel()
	end)

	-- >> Profile
	local profile = {UI = UI.Profile}

	profile.BG = profile.UI.BG

	profile.anim = {}
	profile.anim.grad = profile.BG.UIGradient
	profile.anim.info_grad = TweenInfo.new(6,Enum.EasingStyle.Linear)
	profile.anim.offset0 = Vector2.new(0,-1)
	profile.anim.offset1 = Vector2.new(0,1)
	profile.anim.tween_trans = TweenService:Create(profile.BG,
		profile.anim.info_grad,	{BackgroundTransparency = 0.8})
	profile.anim.tween_grad0 = TweenService:Create(profile.anim.grad,
		profile.anim.info_grad,	{Offset = profile.anim.offset0})
	profile.anim.tween_grad1 = TweenService:Create(profile.anim.grad,
		profile.anim.info_grad,	{Offset = profile.anim.offset1})

	profile.anim.thread = coroutine.wrap(function()
		profile.anim.grad.Offset = profile.anim.offset0
		while self.running do
			profile.BG.BackgroundTransparency = 1
			profile.anim.grad.Rotation = 90
			profile.anim.tween_trans:Play()
			profile.anim.tween_grad1:Play() profile.anim.tween_grad1.Completed:Wait()
			profile.anim.tween_trans:Cancel()
			profile.BG.BackgroundTransparency = 1
			profile.anim.grad.Rotation = -90
			profile.anim.tween_trans:Play()
			profile.anim.tween_grad0:Play() profile.anim.tween_grad0.Completed:Wait()
			profile.anim.tween_trans:Cancel()
		end
		profile.anim.tween_grad1:Cancel()
		profile.anim.tween_grad0:Cancel()
		profile.anim.tween_trans:Cancel()
	end)

	-- >> Rank
	local rank = {UI = UI.Rank}

	rank.anim = {}
	rank.anim.temp = rank.UI.Temp
	rank.anim.base = rank.UI.Base
	rank.anim.runtime = 0.4
	rank.anim.size0 = UDim2.new(.05,0,.05,0)
	rank.anim.size1 = UDim2.new(0.3,0,0.3,0)
	rank.anim.info0 = TweenInfo.new(rank.anim.runtime*0.1)
	rank.anim.info1 = TweenInfo.new(rank.anim.runtime*0.9)
	rank.anim.poparea = {
		{[0]={x = 0.426, y = 0.063}, [1]={x = 0.918, y = 0.324}},
		{[0]={x = 0.021, y = 0.282}, [1]={x = 0.282, y = 0.748}},
		{[0]={x = 0.498, y = 0.748}, [1]={x = 0.978, y = 0.982}},
	}
	rank.anim.delay0 = 0.1
	rank.anim.delay1 = 2

	function rank.anim:pop(i)
		local popper = rank.anim.base:Clone()
		local poparea = rank.anim.poparea[i]
		local pos = {x = rng:NextNumber(poparea[0].x,poparea[1].x), 
			y = rng:NextNumber(poparea[0].y,poparea[1].y)}
		popper.Position = UDim2.new(pos.x,0,pos.y,0)
		popper.ImageTransparency = 1
		popper.Size = rank.anim.size0
		local tween0 = TweenService:Create(popper,rank.anim.info0,{ImageTransparency = 0})
		local tween1 = TweenService:Create(popper,rank.anim.info1,{ImageTransparency = 1})
		popper.Parent = rank.anim.temp
		popper.Visible = true
		popper:TweenSize(rank.anim.size1,"Out","Quad",rank.anim.runtime)
		tween0:Play()
		coroutine.wrap(function()
			tween0.Completed:Wait()
			if popper.Parent then tween1:Play() end
		end)()
		Debris:AddItem(popper,rank.anim.runtime)
	end

	rank.anim.thread = coroutine.wrap(function()
		while self.running do
			for i=1,3 do
				rank.anim:pop(i)
				wait(rank.anim.delay0)
			end
			wait(rank.anim.delay1)
		end
	end)

	-- >> RankLabel
	local ranklabel = {UI = UI.RankLabel}

	-- >> NextButton

	local nextbutton = {UI = UI.NextButton}

	nextbutton.BG = nextbutton.UI.BG

	nextbutton.anim = {}
	nextbutton.anim.grad = nextbutton.BG.UIGradient
	nextbutton.anim.info_grad = TweenInfo.new(1.2,Enum.EasingStyle.Linear)
	nextbutton.anim.offset0 = Vector2.new(-1,0)
	nextbutton.anim.offset1 = Vector2.new(1,0)
	nextbutton.anim.tween_grad = TweenService:Create(nextbutton.anim.grad,
		nextbutton.anim.info_grad,	{Offset = nextbutton.anim.offset1})

	nextbutton.anim.thread = coroutine.wrap(function()
		while self.running do
			nextbutton.anim.grad.Offset = nextbutton.anim.offset0
			nextbutton.anim.tween_grad:Play() nextbutton.anim.tween_grad.Completed:Wait()
		end
		nextbutton.anim.tween_grad:Cancel()
	end)

	-- >> Board
	local board = {UI = UI.Board}

	-- >> Linears
	local linears = {UI = UI.Linears}
	linears.info = TweenInfo.new(.3,Enum.EasingStyle.Quad)
	linears.rank = {ui = linears.UI.Rank}
	linears.rank.size1 = UDim2.new(0.6,0,0.25,0)
	linears.rank.size0 = UDim2.new(1.2,0,0.25,0)
	linears.rank.tween = TweenService:Create(linears.rank.ui,
		linears.info, {BackgroundTransparency = 1, Size = linears.rank.size1})
	linears.ranklabel = {ui = linears.UI.RankLabel}
	linears.ranklabel.size1 = UDim2.new(0.3,0,0.08,0)
	linears.ranklabel.size0 = UDim2.new(1,0,0.08,0)
	linears.ranklabel.tween = TweenService:Create(linears.ranklabel.ui,
		linears.info, {BackgroundTransparency = 1, Size = linears.ranklabel.size1})

	function rank:Show()
		linears.rank.ui.BackgroundTransparency = 0
		rank.UI.Visible = true
		linears.rank.tween:Play()
	end

	function ranklabel:Show()
		linears.ranklabel.ui.BackgroundTransparency = 0
		ranklabel.UI.Visible = true
		linears.ranklabel.tween:Play()
	end

	-- >> MapInfo
	local mapinfo = {UI = UI.MapInfo}

	-- >> Thumbnail
	local thumbnail = {UI = bg.UI.Thumbnail}
	thumbnail.info = TweenInfo.new(1,Enum.EasingStyle.Linear)
	thumbnail.tween = TweenService:Create(thumbnail.UI,
		thumbnail.info, {ImageTransparency = 0.25})

	-- >> Score
	local score = {UI = UI.Score}
	score.LU = score.UI.LayerUp
	score.grad = score

	function score:Write(val)
		score.UI.Text = val
		score.LU.Text = val
	end

	function score:Randomize()
		local randomscore = rng:NextInteger(100000,999999)
		score:Write(randomscore)
	end

	function score:Show(correctscore)
		local runtime = 0
		local timepassed = 0
		sfx:play(sfx.list.scorerise)
		while runtime < 1 do
			local dt = hb:Wait()
			if timepassed >= FPSCAP then
				score:Randomize()
				timepassed = 0
			end
			timepassed += dt
			runtime += dt
		end
		score:Write(correctscore)
	end

	-- >> Elements locators

	judgement.pos0 = UDim2.new(-0.495,0,0.375,0)
	judgement.pos1 = UDim2.new(0.005,0,0.425,0)
	statistics.pos0 = UDim2.new(1.495,0,0.375,0)
	statistics.pos1 = UDim2.new(0.995,0,0.425,0)
	graph.pos0 = UDim2.new(-0.495,0,0.5,0)
	graph.pos1 = UDim2.new(0.005,0,0.45,0)
	profile.pos0 = UDim2.new(1.495,0,0.5,0)
	profile.pos1 = UDim2.new(0.995,0,0.45,0)
	nextbutton.pos0 = UDim2.new(1.3,0,1,-10)
	nextbutton.pos1 = UDim2.new(1,-10,1,-10)
	board.pos0 = UDim2.new(-0.4,0,1,-10)
	board.pos1 = UDim2.new(0,10,1,-10)
	mapinfo.pos0 = UDim2.new(0.5,0,-0.12,0)
	mapinfo.pos1 = UDim2.new(0.5,0,0,0)

	function self:ResetElements()
		rank.UI.Visible = false
		ranklabel.UI.Visible = false
		linears.rank.ui.Size = linears.rank.size0
		linears.rank.ui.BackgroundTransparency = 1
		linears.ranklabel.ui.Size = linears.ranklabel.size0
		linears.ranklabel.ui.BackgroundTransparency = 1
		judgement.anim.grad.Offset = judgement.anim.offset0
		judgement.UI.BackgroundColor3 = judgement.anim.color0
		statistics.anim.grad.Offset = statistics.anim.offset0
		statistics.UI.BackgroundColor3 = statistics.anim.color0
		graph.anim.grad.Offset = graph.anim.offset0
		profile.anim.grad.Offset = profile.anim.offset0
		nextbutton.anim.grad.Offset = nextbutton.anim.offset0
	end
	function self:HideElements()
		thumbnail.UI.ImageTransparency = 1
		rank.UI.Visible = false
		judgement.UI.Position = judgement.pos0
		statistics.UI.Position = statistics.pos0
		graph.UI.Position = graph.pos0
		profile.UI.Position = profile.pos0
		nextbutton.UI.Position = nextbutton.pos0
		board.UI.Position = board.pos0
		mapinfo.UI.Position = mapinfo.pos0
		self:ResetElements()
	end
	function self:ShowElements()
		judgement.UI:TweenPosition(judgement.pos1,"Out","Quint",1,true)
		wait(.1)
		statistics.UI:TweenPosition(statistics.pos1,"Out","Quint",1,true)
		wait(.1)
		graph.UI:TweenPosition(graph.pos1,"Out","Quint",1,true)
		wait(.1)
		profile.UI:TweenPosition(profile.pos1,"Out","Quint",1,true)
		wait(.5)
		board.UI:TweenPosition(board.pos1,"Out","Quint",.4,true)
	end

	-- >>> MAIN MODULE

	self.PlayElements = coroutine.wrap(function()
		rank.anim.thread()
		nextbutton.anim.thread()
		judgement.anim.thread()
		graph.anim.thread()
		wait(.5)
		statistics.anim.thread()
		profile.anim.thread()
	end)

	function self:Start(_score)
		self.running = true
		self:HideElements()
		bg.thread()
		bgm:preload()
		wait(1)
		bgm.thread()
		mapinfo.UI:TweenPosition(mapinfo.pos1,"Out","Quint",.5,true)
		wait(.5)
		thumbnail.tween:Play()
		wait(.5)
		score:Show(_score)
		self:ShowElements()
		wait(1.5)
		ranklabel:Show()
		wait(1.5)
		rank:Show()
		self.PlayElements()
		nextbutton.UI:TweenPosition(nextbutton.pos1,"Out","Back",.5,true)
	end

	function self:Stop()
		self.running = false
	end

	return self
end

--==========================--

return Animation
