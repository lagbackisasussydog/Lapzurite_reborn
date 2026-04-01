getgenv().lzr_dbg = false

local Player = game.Players.LocalPlayer
local Character, PrimaryPart

task.spawn(function()
	if Player.Neutral then
		game.ReplicatedStorage.Remotes.CommF_:InvokeServer("SetTeam", "Pirates")
	end
end)

local function UpdateCharacter(char)
	Character = char
	PrimaryPart = char:WaitForChild("HumanoidRootPart")
end

UpdateCharacter(Player.Character or Player.CharacterAdded:Wait())

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CollectionService = game:GetService("CollectionService")

local LocalSettings = {
	["FSpeed"] = 250,
	["BringDistance"] = 1000,
	["BringSpeed"] = 10000,
	["AttackDistance"] = 60,
	["Tool"] = "Melee",
	["CurrentPlace"] = "",
	["SubFarmMode"] = "",
	["KillMode"] = "Slow",
	["Modules"] = {
		["oneClick"] = false
	}
}

local States = {
	["CurrentTweeningProcess"] = nil,
	["Busy"] = false,
}

local FightingStyles = {
    ["Black Leg"] = {
        Type = "Tool",
        Calls = {
			{"BuyBlackLeg", true},
            {"BuyBlackLeg"}
        }
    },

    ["Electro"] = {
        Type = "Tool",
        Calls = {
			{"BuyElectro", true},
            {"BuyElectro"}
        }
    },

    ["Fishman Karate"] = {
        Type = "Tool",
        Calls = {
			{"BuyFishmanKarate", true},
            {"BuyFishmanKarate"}
        }
    },

    ["Dragon Claw"] = {
        Type = "Tool",
        Calls = {
            {"BlackbeardReward", "DragonClaw", "1"},
            {"BlackbeardReward", "DragonClaw", "2"}
        }
    },

    ["Superhuman"] = {
        Type = "Special",
        Calls = {
			{"BuySuperhuman", true},
            {"BuySuperhuman"}
        }
    },

    ["Death Step"] = {
        Type = "Tool",
        Calls = {
			{"BuyDeathStep", true},
            {"BuyDeathStep"}
        }
    },

    ["Electric Claw"] = {
        Type = "Tool",
        Calls = {
            {"BuyElectricClaw"}
        }
    },

    ["Sharkman Karate"] = {
        Type = "Tool",
        Calls = {
            {"BuySharkmanKarate"}
        }
    },

    ["Dragon Talon"] = {
        Type = "Tool",
        Calls = {
            {"BuyDragonTalon"}
        }
    },

    ["Godhuman"] = {
        Type = "Special",
        Calls = {
            {"BuyGodhuman"}
        }
    }
}

local Threads = {}
Threads._thread = {}

-- MODULES
function SendKey(Keycode, delay)
	VirtualInputManager:SendKeyEvent(true, Keycode, false, game)
	task.wait(delay)
	VirtualInputManager:SendKeyEvent(false, Keycode, false, game)
end

function Anchor()
	if PrimaryPart:FindFirstChild("BodyVelocity") then return end
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	bv.Velocity = Vector3.zero
	bv.Parent = PrimaryPart
	bv.Name = "f"
end

function Pause()
	for _, v in pairs(Character.PrimaryPart:GetChildren()) do
		if v.Name == "f" and v:IsA("BodyVelocity") then
			v:Destroy()
		end
	end
	
	local Track = States.CurrentTweeningProcess
	if Track and Track.PlaybackState == Enum.PlaybackState.Playing then
		Track:Pause()
		States.CurrentTweeningProcess = nil
	end
end

function AddFunction(name, func)
	Threads._thread[name] = {
		["Function"] = func,
		["Running"] = nil
	}
end

function StartThread(thread)
	local a = Threads._thread[thread]
	if a.Running then
		Pause()
		task.cancel(a.Running)
		a.Running = nil
	end
	
	Anchor()
	a.Running = task.spawn(a.Function)
end

function StartFunction(thread)
	local a = Threads._thread[thread]
	a.Running = task.spawn(a.Function)
end

function CloseThread(thread)
	local a = Threads._thread[thread]
	if a.Running then
		task.cancel(a.Running)
		a.Running = nil
		Pause()
	end
end

function ResetThread()
	for _, v in pairs(Threads._thread) do
		if v.Running then
			task.cancel(v.Running)
			v.Running = task.spawn(v.Function)
			Anchor()
		end
	end
end

function Buso()
	local CommF_ = ReplicatedStorage.Remotes.CommF_
	if Character:FindFirstChild("HasBuso") then return end
	CommF_:InvokeServer("Buso")
end

function Tween(Inst, Info, Prop)
	if not Inst or not Inst.Parent then return end
	
	local TweenSvc = game:GetService("TweenService")
	local Track = TweenSvc:Create(Inst, Info, Prop)
	States.CurrentTweeningProcess = Track

	if LocalSettings.FSpeed > 375 then
		Track:Play()

		while Track.PlaybackState == Enum.PlaybackState.Playing 
			or Track.PlaybackState == Enum.PlaybackState.Paused do
			
			task.wait(5)

			if Track.PlaybackState == Enum.PlaybackState.Playing then
				Track:Pause()
				task.wait(0.1) -- tiny break
				Track:Play()
			end

			if Track.PlaybackState == Enum.PlaybackState.Completed then
				break
			end
		end

		Track.Completed:Wait()
	else
		Track:Play()
		Track.Completed:Wait()
	end
end

function TweenNoDelay(Inst,Info, Prop)
	if not Inst or not Inst.Parent then return end
	local TweenSvc = game:GetService("TweenService")
	local Track = TweenSvc:Create(Inst, Info, Prop)
	Track:Play()
end

function GetClosestEnemy()
	local closest = nil
	local shortest = math.huge
	
	for _, v in ipairs(workspace.Enemies:GetChildren()) do
		local hum = v:FindFirstChild("Humanoid")
		local root = v:FindFirstChild("HumanoidRootPart")
		
		if hum and root and hum.Health > 0 then
			local dist = (root.Position - PrimaryPart.Position).Magnitude
			
			if dist < shortest and dist < 1000 then
				shortest = dist
				closest = v
			end
		end
	end
	
	return closest
end

function GetNPC(name)
	for _, v in ipairs({ReplicatedStorage.NPCs, workspace.NPCs}) do
		for _, npc in pairs(v:GetChildren()) do
			if npc.Name == name or string.find(npc.Name, name) then
				return npc
			end
		end
	end
end

function strictCompare(s, pattern)
	if s == pattern then
		return true
	end
	return false
end

function CheckNotification(content)
	local Gui = Player.PlayerGui:FindFirstChild("Notifications")
	for _, tmp in pairs(Gui:GetChildren()) do
		if tmp and tmp:IsA("TextLabel") and string.find(tmp.Text, content) then
			return true
		end
	end
	return false
end

function GetEnemyByName(target)
    local closest = nil
    local shortest = math.huge
    
    for _, v in ipairs(workspace.Enemies:GetChildren()) do
        local hum = v:FindFirstChild("Humanoid")
        local root = v:FindFirstChild("HumanoidRootPart")
        
        if hum and root and hum.Health > 0 then
            local valid = false
            
            if type(target) == "table" then
                valid = table.find(target, v.Name)
            else
                valid = strictCompare(v.Name, target)
            end
            
            if valid then
                closest = v
            end
        end
    end
    
    return closest
end

function GetSeaBeast()
    for i,v in next, workspace.SeaBeasts:GetChildren() do
        if v.Name == "SeaBeast1" and Player:DistanceFromCharacter(v.HumanoidRootPart.Position) <= 2000 then
            if v:FindFirstChild("Health") and v.Health.Value > 0 then
                return v
            end
        end
    end
end

function GetTerrorshark()
	for i, v in pairs(workspace.Enemies:GetChildren()) do
		if v.Name == "Terrorshark" and Player:DistanceFromCharacter(v.HumanoidRootPart.Position) <= 2000 then
			return v
		end
	end
end

function Manipulate(v)
    local Distance = Player:DistanceFromCharacter(v.PrimaryPart.Position)
    if v:FindFirstChild("Humanoid") then
        v.Humanoid.WalkSpeed = Distance <= 50 and 0 or LocalSettings.BringSpeed
        v.Humanoid.JumpPower = 0
        v.Humanoid.AutoRotate = false
        v.HumanoidRootPart.CanCollide = false
        v.Head.CanCollide = false
    else
        return
    end
    for i,v in next, v:GetChildren() do
        if v.ClassName == "Shirt" or v.ClassName == "Pants" then
            v:Destroy()
        end
        if v:IsA("MeshPart") then
            v.Transparency = 1
            v.CanCollide = false
        end
        if v:IsA("Part") then
            v.CanCollide = false
        end
    end
    if v.Humanoid:FindFirstChild("Animator") then
        v.Humanoid.Animator:Destroy()
    end
    if Distance <= 50 and not v.HumanoidRootPart:FindFirstChild('Lock') then
        local Lock = Instance.new('BodyVelocity')
        Lock.Name = "Lock"
        Lock.Parent = v.HumanoidRootPart
        Lock.Velocity = Vector3.zero
        Lock.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    end
end

function SpamAllSkill()
    for i,v in next, Player.PlayerGui.Main.Skills:GetChildren() do
        if v:IsA("Frame") and v.Name ~= "Container" then
            for i1, v1 in next, v:GetChildren() do
                if v1:IsA("Frame") and v1.Name ~= "Template" and v1.Cooldown.AbsoluteSize.X <= 5 and v1.Title.TextColor3 == Color3.fromRGB(255,255,255) then
                    Character.Humanoid:EquipTool(v.Name)
                    task.wait()
                    SendKey(v1.Name,2)
                end
            end
        end
    end
end

function GetFruit()
	for _, v in pairs(workspace:GetChildren()) do
		if (v:IsA("Model") or v:IsA("Tool")) and string.find(v.Name, "Fruit") and v:FindFirstChild("Handle") then
			return v
		end
	end
end

function BringMob(target, pos)
	for _, v in ipairs(workspace.Enemies:GetChildren()) do
		local hum = v:FindFirstChild("Humanoid")
		local root = v:FindFirstChild("HumanoidRootPart")
		
		if hum and root and hum.Health > 0 and v.Name == target.Name then
			Manipulate(v)
			sethiddenproperty(Player, "SimulationRadius", math.huge)
			if (root.Position - target.PrimaryPart.Position).Magnitude <= LocalSettings.BringDistance then
				TweenNoDelay(root, TweenInfo.new(Player:DistanceFromCharacter(pos) / LocalSettings.BringSpeed), {CFrame = target:GetPivot()})
			else
				hum:MoveTo(root.Position)
			end
		end
	end
end

function AreEnemiesAlive(name)
	for _, v in ipairs(workspace.Enemies:GetChildren()) do
		local hum = v:FindFirstChild("Humanoid")

		if hum and hum.Health > 0 and string.find(v.Name, name) and Player:DistanceFromCharacter(v.PrimaryPart.Position) <= 20 then
			return true
		end
	end
	
	return false
end

function getTool()
	for _, v in pairs(Player.Backpack:GetChildren()) do
		if v:IsA("Tool") and v.ToolTip == LocalSettings.Tool then
			if Character:FindFirstChild(v.Name) then return end
			return v
		end
	end
end

function TweenToMobSpawn(target)
	local Spawn = workspace._WorldOrigin.EnemySpawns
	
	for _, v in ipairs(Spawn:GetChildren()) do
		if type(target) == "string" and string.find(v.Name, target) and Player:DistanceFromCharacter(v.Position) <= 1000 then
			Tween(PrimaryPart, TweenInfo.new(Player:DistanceFromCharacter(v.Position) / LocalSettings.FSpeed, Enum.EasingStyle.Linear), {CFrame = v.CFrame * CFrame.new(0,15,0)})
			break
		end
	end
end

function GetMobSpawn(target)
	local Spawn = workspace._WorldOrigin.EnemySpawns
	
	for _, v in ipairs(Spawn:GetChildren()) do
		if type(target) == "string" and string.find(v.Name, target) then
			return v
		end
	end
end

function FollowEnemy(enemy, pos)
	local hum = enemy:FindFirstChild("Humanoid")
	local root = enemy:FindFirstChild("HumanoidRootPart")
	
	if not hum or not root then return end
	
	if enemy.Parent and hum.Health > 0 then
		local targetCFrame = root.CFrame * CFrame.new(0, 20, 0)
		local Tool = getTool()

		Character.Humanoid:EquipTool(Tool)
		
		Tween(PrimaryPart, TweenInfo.new(Player:DistanceFromCharacter(root.Position) / LocalSettings.FSpeed, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetCFrame.Position)})
		BringMob(enemy, pos)
		
		task.wait(0.05)
	end
end

function GetCakeBoss()
	for _, x in ipairs({game.ReplicatedStorage, workspace.Enemies}) do
		for i, enemy in pairs(x:GetChildren()) do
			if enemy:IsA("Model") and (enemy.Name == "Cake Prince" or enemy.Name == "Dough King") then
				return enemy
			end
		end
	end
end

function HasFightingStyle(styleName)
    return (Player.Backpack:FindFirstChild(styleName) and Player.Backpack:FindFirstChild(styleName).Level.Value >= 400)
        or (Character:FindFirstChild(styleName) and Character:FindFirstChild(styleName).Level.Value >= 400)
end

function Sail(SeaLevel)
	
end

function HandleEvent(event)
	if event == "Shark" or event == "Piranha" then
	
	elseif event == "SeaBeast" then
		local Seabeast = GetSeaBeast()
		
		if Seabeast then
			local randX = math.random(-45, 45)
			local randZ = math.random(-45, 45)
		
			Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			task.wait(.5)
			Tween(PrimaryPart, TweenInfo.new(Player:DistanceFromCharacter(Seabeast:GetPivot().Position) / LocalSettings.FSpeed, Enum.EasingStyle.Linear), {CFrame = SeaBeast:GetPivot() * CFrame.new(randX,15,randZ)})
			SpamAllSkill()
		end
	elseif event == "Terrorshark" then
		local terrorshark = GetTerrorshark()
		
		if terrorshark then
			Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			task.wait(.5)
			FollowEnemy()
		end
	elseif event == "PrehistoricIsland" then
	
	elseif event == "MirageIsland" then
	
	end
end

local function HandleSeaProgression()
	local level = Player.Data.Level.Value

	-- Go to Second Sea
	if LocalSettings.CurrentPlace == "First-Seas" and level >= 700 then
		States.Busy = true

		local a = CFrame.new(1348.31799, 37.3803978, -1325.52441, 0.462068647, -4.20073683e-08, 0.886844158, -5.75951642e-09, 1, 5.03681044e-08, -0.886844158, -2.83813151e-08, 0.462068647)
		local args = {
			[1] = "DressrosaQuestProgress",
			[2] = "Detective"
		}
		local args2 = {	
			[1] = "TravelDressrosa"
		}
		
		ReplicatedStorage.Remotes.CommF_:InvokeServer(unpack(args))
		task.wait(1)
		
		local key = Player.Backpack:FindFirstChild("Key") or Character:FindFirstChild("Key")
		Character.Humanoid:EquipTool(key)
		Tween(PrimaryPart, TweenInfo.new(Player:DistanceFromCharacter(a.Position) / LocalSettings.FSpeed, Enum.EasingStyle.Linear), {CFrame = a})
		
		task.wait(5)
		
		local enemy
		repeat task.wait(1)
			enemy = GetEnemyByName("Ice Admiral")
			if not enemy then
				TweenToMobSpawn("Ice Admiral")
			end
		until enemy
		
		if enemy then
			repeat task.wait()
				FollowEnemy(enemy, PrimaryPart.Position - Vector3.new(0,15,0))
			until not AreEnemiesAlive(enemy.Name)
		else
			TweenToMobSpawn("Ice Admiral")
		end
		
		task.wait(1)
		ReplicatedStorage.Remotes.CommF_:InvokeServer(unpack(args))
		task.wait(1)
		ReplicatedStorage.Remotes.CommF_:InvokeServer(unpack(args2))
		
		States.Busy = false
	end

	-- Go to Third Sea
	if LocalSettings.CurrentPlace == "Second-Seas" and level >= 1500 then
		StartFunction("GoThirdSea")
	end
end

function GetQuest()
    local Level = Player.Data.Level
    local Name, NameQuest, Id = "", "", 0
    local LevelReq = 0
    if LocalSettings.CurrentPlace == "First-Seas" and Level.Value >= 700 then
        HandleSeaProgression()
    elseif LocalSettings.CurrentPlace == "Second-Seas" and Level.Value >= 1500 then
        HandleSeaProgression()
    else
        for i,v in next, require(game:GetService("ReplicatedStorage").Quests) do
            for ID, v1 in next, v do
                local LvReq = v1.LevelReq
                for i1,v2 in next, v1.Task do
                    if Level.Value >= LvReq and LvReq >= LevelReq and not table.find({"CitizenQuest", "BartiloQuest", "MarineQuest", "Trainees"}, i) and v1.Task[i1] >= 5 then
                        LevelReq = LvReq
                        LevelReq, Name, NameQuest, Id = LvReq, i1, i, ID
                    end
                end
            end
        end
    end
    return Name, NameQuest, Id
end

function GetCFrameQuest()
	for _, x in ipairs({workspace.NPCs, ReplicatedStorage.NPCs}) do
		for i,v in next, x:GetChildren() do
			if v.Name == require(ReplicatedStorage.GuideModule).Data.LastClosestNPC then
				return v
			end
		end
	end
end

function GetQuestUnlocked()
    local TotalQuestUnlocked = {}
    local Name, NameQuest, Id = GetQuest()
    for i,v in next, require(ReplicatedStorage.Quests) do
        for ID, v1 in next, v do
            local LvReq = v1.LevelReq
            for i1,v2 in next, v1.Task do
                if i == NameQuest then
                    if LvReq <= Player.Data.Level.Value and v2 > 1 and v1.Name ~= "Town Raid" then
                        table.insert(TotalQuestUnlocked, v)
                    end
                end
            end
        end
    end
    return TotalQuestUnlocked
end

function GetLastQuest()
    local QuestData
    for i,v in next, require(ReplicatedStorage.GuideModule).Data do
        if i == "QuestData" then
            QuestData = v
            break
        end
    end
    if QuestData then
        for i,v in next, QuestData.Task do
            return i
        end
    else
        return false
    end
end

function CheckDoubleQuest()
    local Name, NameQuest, Id = GetQuest()
    if Player.PlayerGui.Main.Quest.Visible == false and GetLastQuest() and GetLastQuest() == Name and #GetQuestUnlocked() >= 2 then
        for i,v in next, require(ReplicatedStorage.Quests) do
            for ID, v1 in next, v do
                local LvReq = v1.LevelReq
                for i1,v2 in next, v1.Task do
                    if i1 ~= Name and i == NameQuest then
                        if LvReq <= Player.Data.Level.Value and v2 >= 5 and v1.Name ~= "Town Raid" then
                            return i1, i, ID
                        end
                    end
                end
            end
        end
    end
    return Name, NameQuest, Id
end

function tele(cframe)
	local lv = Player.Data.Level.Value
	local Name, NameQuest, Id = CheckDoubleQuest()
	
	if LocalSettings.CurrentPlace == "First-Seas" then
		if lv >= 375 and lv <= 450 then
			local args = {
				[1] = "requestEntrance",
				[2] = Vector3.new(61163.8515625, 11.680007934570312, 1819.7840576171875)
			}
			ReplicatedStorage.Remotes.CommF_:InvokeServer(unpack(args))
		elseif (lv >= 450 and lv <= 475) or Name == "God's Guard" then
			local args = {
				"requestEntrance",
				vector.create(-4607.8232421875, 874.3909912109375, -1667.5570068359375)
			}
			game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer(unpack(args))
		elseif (lv >= 475 and lv <= 525) or Name == "Shanda" then
			local args = {
				"requestEntrance",
				vector.create(-7894.6181640625, 5547.14208984375, -380.2909851074219)
			}
			game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer(unpack(args))
		end
	end
		
	if LocalSettings.CurrentPlace == "Second-Seas" then
		if lv >= 1250 and level <= 1350 then
			local args = {
				"requestEntrance",
				vector.create(923.2130126953125, 126.97599792480469, 32852.83203125)
			}
			CommF_:InvokeServer(unpack(args))
		end
	end
	
	Tween(PrimaryPart, TweenInfo.new(
		Player:DistanceFromCharacter(cframe.Position) / LocalSettings.FSpeed,
		Enum.EasingStyle.Linear
	), {CFrame = cframe})
end

function InvokeStyleCalls(styleData)
    for _, args in ipairs(styleData.Calls) do
        local ok, result = pcall(function()
			print(tostring(unpack(args)))
            return ReplicatedStorage.Remotes.CommF_:InvokeServer(unpack(args))
        end)

        task.wait(0.25)

        if ok then
            print("Tried:", unpack(args), "->", result)
        end
    end
end

function CheckFightingStyle(styleName)
    local styleData = FightingStyles[styleName]
    if not styleData then return false end

    if HasFightingStyle(styleName) then
        return true
    end

    InvokeStyleCalls(styleData)
    task.wait(1)

    if HasFightingStyle(styleName) then
        return true
    end

    return false
end

function CheckAllStyles()
    for styleName, _ in pairs(FightingStyles) do
        local success = CheckFightingStyle(styleName)

        if not success then
            print("Stopped at:", styleName)
            break
        end
    end
end

function IsRaiding(x)
    for i,v in next, workspace._WorldOrigin.Locations:GetChildren() do
        if v.Name == "Island 1" and Player:DistanceFromCharacter(x.Position, v.Position) <= 10000 then
            return true
        end
    end
    return false
end

function GetRaidIsland()
    local select
    for i = 5, 1, -1 do
        for _,v in next, workspace._WorldOrigin.Locations:GetChildren() do
            if v.Name == "Island " .. tostring(i) and (v.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 3000 then
                select = v
                break
            end
        end
        if select then break end
    end
    return select
end

function instantKill(mob)
	local hum = mob:FindFirstChild("Humanoid")
	
	if hum and hum.Health > 0 then
		hum:ChangeState(Enum.HumanoidStateType.Dead)
		hum.Head:Destroy()
		sethiddenproperty(Player, "SimulationRadius", math.huge)
	end
end

function CheckItem(item)
	for i,v in next, Player.Backpack:GetChildren() do
        if v:IsA('Tool') and (tostring(v) == item or v.Name == item or string.find(v.Name, item)) then
            return v
        end
    end
    for i,v in next, Character:GetChildren() do
        if v:IsA('Tool') and (tostring(v) == item or v.Name == item or string.find(v.Name, item)) then
            return v
        end
    end
end

function CheckInventory(Name)
    for i,v in next, ReplicatedStorage.Remotes.CommF_:InvokeServer("getInventory") do
        if v.Name == Name then
            return v
        end
    end
end

function EquipItem(item)
	Character.Humanoid:EquipTool(item)
end

function getSaber()
	if CheckItem("Saber") then return end
        if workspace.Map.Jungle.Final.Part.CanCollide then
            if workspace.Map.Jungle.QuestPlates.Door.CanCollide then
                for i,v in next, workspace.Map.Jungle.QuestPlates:GetChildren() do
                    if v:FindFirstChild("Button") and v.Button:FindFirstChild("TouchInterest") then
                        firetouchinterest(v.Button, Player.Character.HumanoidRootPart, 0)
                        firetouchinterest(v.Button, Player.Character.HumanoidRootPart, 1)
                    end
                end
            else
                if workspace.Map.Desert.Burn.Part.CanCollide then
                    if not CheckItem("Torch") then
                        firetouchinterest(workspace.Map.Jungle.Torch, Player.Character.HumanoidRootPart, 0)
                        firetouchinterest(workspace.Map.Jungle.Torch, Player.Character.HumanoidRootPart, 1)
                    else
						local door = workspace.Map.Desert.Burn.Fire
						local Item = CheckItem("Torch")
                        EquipItem(Item)
                        Tween(PrimaryPart, TweenInfo.new(Player:DistanceFromCharacter(door:GetPivot().Position) / LocalSettings.FSpeed, Enum.EasingStyle.Linear), {CFrame = door:GetPivot()})
                    end
                else
                    local Progress = ReplicatedStorage.Remotes.CommF_:InvokeServer("ProQuestProgress", "RichSon")
                    if Progress ~= 0 and Progress ~= 1 then
                        if not CheckItem("Cup") then
							local Cup = workspace.Map.Desert.Cup
                            Tween(PrimaryPart, TweenInfo.new(Player:DistanceFromCharacter(Cup:GetPivot().Position) / LocalSettings.FSpeed, Enum.EasingStyle.Linear), {CFrame = Cup:GetPivot()})
                        else
							local Cup = CheckItem("Cup")
                            EquipItem(Cup)
                            ReplicatedStorage.Remotes.CommF_:InvokeServer("ProQuestProgress","FillCup", Player.Character:FindFirstChild("Cup"))
                            ReplicatedStorage.Remotes.CommF_:InvokeServer("ProQuestProgress","SickMan")
                        end
                    elseif Progress == 0 then
						local Mob = GetEnemyByName("Mob Leader")
                        if Mob then
                            pcall(function()
								repeat task.wait()
									FollowEnemy(Mob, PrimaryPart.Position - Vector3.new(0,15,0))
								until not AreEnemiesAlive(Mob.Name)
							end)
                        else
							TweenToMobSpawn("Mob Leader")
						end
                    elseif Progress == 1 then
                        if not CheckItem("Relic") then
                        ReplicatedStorage.Remotes.CommF_:InvokeServer("ProQuestProgress","RichSon")
                    else
						local Relic = CheckItem("Relic")
						local door = workspace.Map.Jungle.Final.Invis
                        EquipItem(Relic)
                        task.wait(0.1)
                        Tween(PrimaryPart, TweenInfo.new(Player:DistanceFromCharacter(door:GetPivot().Position) / LocalSettings.FSpeed, Enum.EasingStyle.Linear), {CFrame = door:GetPivot()})
                    end
                end
            end
        end
    else
        local v = GetEnemyByName("Saber Expert")
        if v then
            repeat wait()
                FollowEnemy(v, PrimaryPart.Position - Vector3.new(0,15,0))
            until not AreEnemiesAlive(v.Name)
        end
    end
end

function CheckUndervalueFruit()
	local max = math.huge
	local select = v.Name
	for _, v in pairs(ReplicatedStorage.Remotes.CommF_:InvokeServer("getInventory")) do
		if v.Type == "Blox Fruit" then
			if v.Value < 1000000 and v.Value <= max then
                max = v.Value
                select = v.Name
            end
		end
	end
	return select
end

function GetBartiloPlates()
    local Plates = workspace.Map.Dressrosa.BartiloPlates:GetChildren()
    local Select
    table.sort(Plates, function(i, v)
        return tonumber(i.Name:match("%d+$")) < tonumber(v.Name:match("%d+$"))
    end)
    for i,v in next, Plates do
        if v.BrickColor == BrickColor.new("Sand yellow") then
            Select = v
            break
        end
    end
    return Select
end

function bartiloQuest()
	local BartiloProgress = ReplicatedStorage.Remotes.CommF_:InvokeServer("BartiloQuestProgress", "Bartilo")
    States.Busy = true
	if BartiloProgress == 0 then
        if not Player.PlayerGui.Main.Quest.Visible or not string.find(Player.PlayerGui.Main.Quest.Container.QuestTitle.Title.Text,"Swan Pirate") then
            wait(1)
            ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", "BartiloQuest", 1)
            tele(GetNPC("Bartilo").CFrame)
        else
            local v = GetEnemyByName('Swan Pirate')
            if v then
                repeat task.wait()
                    FollowEnemy(v, PrimaryPart.Position - Vector3.new(0,15,0))
                until not AreEnemiesAlive(v) or BartiloProgress ~= 0
            else
                TweenToMobSpawn("Swan Pirate")
            end
        end
    elseif BartiloProgress == 1 then
        local v = GetEnemyByName('Jeremy')
        if v then
            repeat task.wait()
                FollowEnemy(v, PrimaryPart.Position - Vector3.new(0,15,0))
            until not AreEnemiesAlive(v) or BartiloProgress ~= 1
        end
    elseif BartiloProgress == 2 then
        repeat task.wait()
            if Player:DistanceFromCharacter(CFrame.new(-1835, 10, 1679)) <= 100 then
                local BartiloPlates = GetBartiloPlates()
                firetouchinterest(Character.PrimaryPart, BartiloPlates, 1)
                firetouchinterest(Character.PrimaryPart, BartiloPlates, 0)
                task.wait(0.1)
            else
                tele(CFrame.new(-1835, 10, 1679))
            end
        until BartiloProgress ~= 2
    end
	States.Busy = false
end

-- SPAWN
task.spawn(function()
	if game.PlaceId == 7449423635 then
		LocalSettings.CurrentPlace = "Third-Seas"
	elseif game.PlaceId == 4442272183 then
		LocalSettings.CurrentPlace = "Second-Seas"
	elseif game.PlaceId == 2753915549 then
		LocalSettings.CurrentPlace = "First-Seas"
	end
end)

task.spawn(function()
	if getconnections then
		for _, connection in pairs(getconnections(game.Players.LocalPlayer.Idled)) do
			if connection["Disable"] then
				connection["Disable"](connection)
			elseif connection["Disconnect"] then
				connection["Disconnect"](connection)
			end
		end
	else
		game.Players.LocalPlayer.Idled:Connect(function()
			Services.VirtualUser:CaptureController()
			Services.VirtualUser:ClickButton2(Vector2.new())
		end)
	end
end)

task.spawn(function()
	local remote, idremote
	for _, v in next, ({game.ReplicatedStorage.Util, game.ReplicatedStorage.Common, game.ReplicatedStorage.Remotes, game.ReplicatedStorage.Assets, game.ReplicatedStorage.FX}) do
		for _, n in next, v:GetChildren() do
			if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
				remote, idremote = n, n:GetAttribute("Id")				
			end
		end
		v.ChildAdded:Connect(function(n)
			if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
				remote, idremote = n, n:GetAttribute("Id")
			end
		end)
	end

	while task.wait(0.05) do
		local char = game.Players.LocalPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local parts = {}
		for _, x in ipairs({workspace.Enemies, workspace.Characters}) do
			for _, v in ipairs(x and x:GetChildren() or {}) do
				local hrp = v:FindFirstChild("HumanoidRootPart")
				local hum = v:FindFirstChild("Humanoid")
				if v ~= char and hrp and hum and hum.Health > 0 and (hrp.Position - root.Position).Magnitude <= LocalSettings.AttackDistance then
					for _, _v in ipairs(v:GetChildren()) do
						if _v:IsA("BasePart") and (hrp.Position - root.Position).Magnitude <= LocalSettings.AttackDistance then
							parts[#parts+1] = {v, _v}
						end
					end
				end
			end
		end
		local tool = char:FindFirstChildOfClass("Tool")
		if #parts > 0 and tool and (tool:GetAttribute("WeaponType") == "Melee" or tool:GetAttribute("WeaponType") == "Sword" or tool:GetAttribute("WeaponType") == "Demon Fruit") then
			pcall(function()
				require(game.ReplicatedStorage.Modules.Net):RemoteEvent("RegisterHit", true)
				game.ReplicatedStorage.Modules.Net["RE/RegisterAttack"]:FireServer()
				local head = parts[1][1]:FindFirstChild("Head")
				if not head then return end
				game.ReplicatedStorage.Modules.Net["RE/RegisterHit"]:FireServer(head, parts, {}, tostring(game.Players.LocalPlayer.UserId):sub(2, 4) .. tostring(coroutine.running()):sub(11, 15))
				cloneref(remote):FireServer(string.gsub("RE/RegisterHit", ".", function(c)
					return string.char(bit32.bxor(string.byte(c), math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1))
				end),
				bit32.bxor(idremote + 909090, game.ReplicatedStorage.Modules.Net.seed:InvokeServer() * 2), head, parts)
			end)
		end
	end
end)

Player.CharacterAdded:Connect(function(newChar)
	task.wait(.3)
	UpdateCharacter(newChar)
	Buso()
	ResetThread()
end)

AddFunction("autoChest", function()
	local Character = Player.Character or Player.CharacterAdded:Wait()
	local PrimaryPart = Character.PrimaryPart or Character:FindFirstChild("HumanoidRootPart")
	local last = nil
	local routeIndex = 1
	local map = workspace.Map
	while task.wait(.2) do
		local Chest = CollectionService:GetTagged("_ChestTagged")
		local closest = nil
		local shortestDist = math.huge
		
		local route = {}
		for _, v in ipairs(map:GetChildren()) do
			if v:IsA("Model") then
				table.insert(route, v)
			end
		end
		
		for i = 1, #Chest do
			local c = Chest[i]
			local dist = (c:GetPivot().Position - PrimaryPart.Position).Magnitude
		
			if c.Parent and c:FindFirstChild("TouchInterest") and not Chest[i]:GetAttribute("IsDisabled") then
				if dist < shortestDist then
					shortestDist = dist
					closest = c
				end
			end
		end
		
		if closest and closest ~= last then
			last = closest
			PrimaryPart.CFrame = closest:GetPivot() * CFrame.new(0,3,0)
		
			for _, part in ipairs(closest:GetDescendants()) do
				if part:IsA("BasePart") then
					firetouchinterest(PrimaryPart, part, 0)
					firetouchinterest(PrimaryPart, part, 1)
				end
			end
			task.wait(0.15)
		end
		
		if #route > 0 then
			local target = route[routeIndex]
			
			if target and target:IsA("Model") then
				Tween(PrimaryPart, TweenInfo.new(Player:DistanceFromCharacter(target:GetPivot().Position) / LocalSettings.FSpeed, Enum.EasingStyle.Linear), {CFrame = target:GetPivot()})
			end
			
			routeIndex += 1
			if routeIndex > #route then
				routeIndex = 1 -- loop route
			end
		end
	end
end)

AddFunction("autoBone", function()
	while task.wait() do
		local Character = Player.Character or Player.CharacterAdded:Wait()
		local PrimaryPart = Character.PrimaryPart or Character:FindFirstChild("HumanoidRootPart")
		local enemyList = {
			"Reborn Skeleton",
			"Living Zombie",
			"Demonic Soul",
			"Posessed Mummy",
		}
		
		local enemy = GetEnemyByName(enemyList)
		
		if enemy then
			pcall(function()
				repeat task.wait()
					FollowEnemy(enemy, PrimaryPart.Position - Vector3.new(0,15,0))
				until not AreEnemiesAlive(enemy.Name)
			end)
		else
			TweenToMobSpawn(enemyList[1])
		end
	end
end)

AddFunction("autoTryLuck", function()
	for i = 1, 10 do
		local args = {
			"Bones",
			"Buy",
			1,
			1
		}
		game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer(unpack(args))
		task.wait(.5)
	end
end)

AddFunction("autoKatakuri", function()
	while task.wait() do
		local Character = Player.Character or Player.CharacterAdded:Wait()
		local PrimaryPart = Character.PrimaryPart or Character:FindFirstChild("HumanoidRootPart")
		local enemyList = {
			"Cookie Crafter",
			"Cake Guard",
			"Baking Staff",
			"Head Baker",
		}
		
		game.ReplicatedStorage.Remotes.CommF_:InvokeServer("CakePrinceSpawner")
		local enemy = GetEnemyByName(enemyList)
		local boss = GetCakeBoss()
		
		if enemy or boss then
			pcall(function()
				repeat task.wait()
					FollowEnemy(enemy or boss, PrimaryPart.Position - Vector3.new(0,15,0))
				until not AreEnemiesAlive(enemy.Name or boss.Name)
			end)
		else
			TweenToMobSpawn(enemyList[1])
		end
	end
end)

AddFunction("rollFruit", function()
	local args = {
		"Cousin",
		"Buy",
		"DLCBoxData"
	}
	game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer(unpack(args))
end)

AddFunction("activateV4", function()
	while task.wait(1) do 
		if game.Players.LocalPlayer.Character:FindFirstChild("RaceEnergy") and game.Players.LocalPlayer.Character.RaceEnergy.Value >= 1 and not game.Players.LocalPlayer.Character.RaceTransformed.Value then
			game:GetService("ReplicatedStorage").Events.ActivateRaceV4:Fire()
		end
	end
end)

AddFunction("teleFruit", function()
	local fruit = GetFruit()
	
	if fruit then
		Character:PivotTo(fruit:GetPivot())
	end
end)

AddFunction("autoLevel", function()
	while task.wait() do
		local CFrameNPC = GetCFrameQuest()
		local Name, NameQuest, Id = CheckDoubleQuest()
		local NameMob = GetLastQuest()
		if not Player.PlayerGui.Main.Quest.Visible then
			local success, err = pcall(function()
				game.ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", NameQuest, Id)
				tele(CFrameNPC:GetPivot())
			end)
			
			if err then game.ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", NameQuest, Id) end
		else
			local Mob = GetEnemyByName(NameMob)
			if Mob then
				pcall(function()
					repeat task.wait()
						FollowEnemy(Mob, PrimaryPart.Position - Vector3.new(0,15,0))
					until not AreEnemiesAlive(NameMob)
				end)
			else
				local s, e = pcall(function()
					local spawn = GetMobSpawn(NameMob)
					tele(spawn.CFrame * CFrame.new(0,15,0))
				end)
				
				if e then 
					Character:BreakJoints()
				end
			end
		end
	end
end)

AddFunction("addStats", function()
	while task.wait(1) do
		local Point = Player.Data.Points.Value
		
		if Point > 0 then
			if Player.Data.Stats.Melee.Level.Value <= 2800 then
				ReplicatedStorage.Remotes.CommF_:InvokeServer("AddPoint", "Melee", 9999)
			elseif Player.Data.Stats.Defense.Level.Value <= 2800 then
				ReplicatedStorage.Remotes.CommF_:InvokeServer("AddPoint", "Defense", 9999)
			end
		end
	end
end)

AddFunction("autoStartRaid", function()
	if CheckNotification("loading map...") or GetRaidIsland() then return end
    if not CheckItem("Special Microchip") then
        if not CheckFruit() then
            ReplicatedStorage.Remotes.CommF_:InvokeServer("LoadFruit", CheckUndervalueFruit())
            wait(0.1)
        else
            ReplicatedStorage.Remotes.CommF_:InvokeServer("RaidsNpc", "Select", "Dark")
        end
    end
	
	local btn
	
	if LocalSettings.CurrentPlace == "Second-Seas" then
		btn = workspace.Map["CircleIsland"].RaidSummon.Button.Main.ClickDetector
	elseif LocalSettings.CurrentPlace == "Third-Seas" then
		btn = workspace.Map["Boat Castle"].RaidSummon2.Button.Main.ClickDetector
	end
	
	if CheckItem("Special Microchip") then
		fireclickdetector(btn)
	end
end)


AddFunction("autoSwitchFStyle", function()
	local tool = getTool()
	local money = Player.Data.Beli.Value
	local frag = Player.Data.Fragments.Value
	
	local MeleeList = {
		["Black Leg"] = {
			["Money"] = 150000,
			["Fragment"] = 0,
			["NPC"] = "Dark Step Teacher"
		},
		["Electro"] = {
			["Money"] = 500000,
			["Fragment"] = 0,
			["NPC"] = "Mad Scientist"
			
		},
		["Fishman Karate"] = {
			["Money"] = 750000,
			["Fragment"] = 0,
			["NPC"] = "Water Kung-fu Teacher"
		},
		["Dragon Claw"] = {
			["Money"] = 0,
			["Fragment"] = 1500,
			["NPC"] = "Sabi"
		},
	}
	
	local function GetMelee(npc, FStyle)
		if npc then
			pcall(function()
				repeat task.wait(1)
					Character:PivotTo(npc:GetPivot())
					InvokeStyleCalls(FightingStyles[FStyle])
				until Player.Backpack:FindFirstChild(FStyle) or Character:FindFirstChild(FStyle) 
			end)
		end
	end
	
	while task.wait(5) do
		for _, v in pairs(MeleeList) do
			local tool = getTool()
			
			if tool.Name == "Combat" and money >= 150000 then
				local npc = GetNPC(v["Black Leg"])
				GetMelee(npc)
			end
			
			if tool.Name == v and tool.Level.Value >= 400 and money >= v["Money"] then
				if frag <= v["Fragment"] and LocalSettings.CurrentPlace ~= "First-Seas" then
					StartFunction("autoStartRaid")
					repeat task.wait() until Player.PlayerGui.Main.TopHUDList.RaidTimer.Visible
					StartThread("completeRaid")
				else
					CloseThread("autoStartRaid")
					CloseThread("completeRaid")
					continue
				end
				
				local npc = GetNPC(v["NPC"])
				GetMelee(npc)
			end
		end
	end
end)

AddFunction("checkFruit", function()
	while task.wait(5) do
		local fruit = CheckItem("Fruit")
		
		if fruit and not CheckInventory(fruit:GetAttribute("OriginalName")) then
			ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", fruit:GetAttribute("OriginalName"), fruit)
		end
	end
end)

AddFunction("autoRollFruit", function()
	while task.wait(5) do
		local args = {
			"Cousin",
			"Buy",
			"DLCBoxData"
		}
		game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer(unpack(args))
	end
end)

AddFunction("activateV3", function()
	while task.wait(5) do
		game.ReplicatedStorage.Remotes.CommE:FireServer("ActivateAbility")
	end
end)

AddFunction("oneClick", function()
	StartFunction("autoSwitchFStyle")
	StartFunction("addStats")
	StartFunction("checkFruit")
	StartFunction("autoRollFruit")
	
	while task.wait(.5) do
		local fruit = GetFruit() or nil
		
		if fruit and not CheckInventory(fruit:GetAttribute("OriginalName")) then
			CloseThread("autoLevel")
			repeat task.wait(1)
				Character:PivotTo(fruit:GetPivot())
			until Player.Backpack:FindFirstChild(fruit.Name) or Character:FindFirstChild(fruit.Name)
			ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", fruit:GetAttribute("OriginalName"), fruit)
		end
	
		if Player.Data.Level.Value <= 2800 then
			if LocalSettings.CurrentPlace == "First-Seas" and Player.Data.Level.Value >= 200 and not (CheckItem("Saber") ~= nil or CheckInventory("Saber") ~= nil) then
				CloseThread("autoLevel")
				getSaber()
				repeat task.wait() until CheckItem("Saber")
			end
			
			if LocalSettings.CurrentPlace == "First-Seas" and Player.Data.Level.Value >= 700 then
				CloseThread("autoLevel")
				HandleSeaProgression()
				repeat task.wait() until States.Busy == false
			end

			if LocalSettings.CurrentPlace == "Second-Seas" then
				if (CheckNotification("We are breaching the factory in 30 seconds!") or GetEnemyByName("Core")) then
					local mob = GetEnemyByName("Core")
					CloseThread("autoLevel")
					repeat
						FollowEnemy(mob, PrimaryPart.Position)
					until not AreEnemiesAlive("Core")
				end
				
				if (CheckNotification("The power of darkness has been unleashed.") or GetEnemyByName("Darkbeard")) then
					local mob = GetEnemyByName("Darkbeard")
					CloseThread("autoLevel")
					repeat
						FollowEnemy(mob, PrimaryPart.Position - Vector3.new(0,15,0))
					until not AreEnemiesAlive("Darkbeard")
				end
				
				if Player.Data.Level.Value >= 850 then
					CloseThread("autoLevel")
					bartiloQuest()
					repeat task.wait() until not States.Busy
				end
			end
			
			StartThread("autoLevel")
		end
		
		break
	end
end)

AddFunction("completeRaid", function()
	while task.wait(1) do
		if Player.PlayerGui.Main.TopHUDList.RaidTimer.Visible then
            local Mob = GetClosestEnemy()
            if Mob then
				pcall(function()
					repeat
						if table.find({"Island 1", "Island 2", "Island 3", "Island 4", "Island 5"}, GetRaidIsland().Name) then
							if LocalSettings.KillMode == "Slow" then
								FollowEnemy(Mob, PrimaryPart.Position - Vector3.new(0,15,0))
							else
								Mob.Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
								Mob.Head:Destroy()
								sethiddenproperty(Player, "SimulationRadius", math.huge)
							end
						end
					until not AreEnemiesAlive(Mob.Name)
				end)
            else
				local targetCFrame = GetRaidIsland().CFrame * CFrame.new(0, 30, 0)
                Tween(PrimaryPart, TweenInfo.new(Player:DistanceFromCharacter(targetCFrame.Position) / LocalSettings.FSpeed, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
            end
        end
	end
end)

task.spawn(function()
	ReplicatedStorage.Remotes.ChangeSetting:FireServer("CameraShake", false)
	Buso()
end)
