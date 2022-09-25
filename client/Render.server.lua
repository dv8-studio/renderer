local startAt = 1

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Stats = ReplicatedStorage:WaitForChild("RenderStats")
local AssignLine = ReplicatedStorage:WaitForChild("AssignLine")
local SendDataE = ReplicatedStorage:WaitForChild("SendData")

local Part1 = Stats.Parts["1"].Value
local Part2 = Stats.Parts["2"].Value
local CenterCFrame = Part1.CFrame:Lerp(Part2.CFrame, .5)
local Part1Rel = CenterCFrame:PointToObjectSpace(Part1.Position)
local Part2Rel = CenterCFrame:PointToObjectSpace(Part2.Position)

local Max = Vector3.new(math.max(Part1Rel.X, Part2Rel.X), math.max(Part1Rel.Y, Part2Rel.Y), math.max(Part1Rel.Z, Part2Rel.Z))
local Min = Vector3.new(math.min(Part1Rel.X, Part2Rel.X), math.min(Part1Rel.Y, Part2Rel.Y), math.min(Part1Rel.Z, Part2Rel.Z))

local Size = Vector3.new(Max.X - Min.X, Max.Y - Min.Y, Max.Z - Min.Z)
local Grid = Stats.Grid.Value
local XPlots = math.ceil((Size.X/2 - Grid/2) / Grid)
local YPlots = math.ceil((Size.Z/2 - Grid/2) / Grid)

local LPA = Stats.LinesPerAssign.Value
local PPS = Stats.PPS.Value

local HttpService = game:GetService("HttpService")
local SendData = function(Path, Data) return HttpService:PostAsync("http://" .. Stats.Host.Value .. "/" .. Path, HttpService:JSONEncode(Data)) end

local i = 1
local AllPlots = (XPlots*2+1) * (YPlots*2+1)
local PxGrid = Grid * PPS
for y = YPlots, -YPlots, -1 do
	for x = -XPlots, XPlots do
		if i < startAt then
			i = i + 1
			continue
		end

		print("Generating plot ", i, "/", AllPlots)
		local PlotCFrame = CenterCFrame * CFrame.new(x * Grid, 0, -y * Grid) * CFrame.new(0, Size.Y / 2, 0)
		local FirstRay = PlotCFrame * CFrame.new(-Grid/2, 0, -Grid/2) * CFrame.new(1/(PPS + 1), 0, 1/(PPS + 1))

		SendData("start", {
			plot = i,
			imageSize = { x = PxGrid, y = PxGrid },
			allPlots = AllPlots
		})

		local LC = {}
		for a = 0, PxGrid, LPA do LC[a] = {} end
		local LastLineAssigned = 0

		local AssignNew = function(Player)
			if LastLineAssigned < PxGrid then
				AssignLine:FireClient(Player, LastLineAssigned, math.min(LPA, PxGrid - LastLineAssigned), PlotCFrame, FirstRay, Size.Y)
				LastLineAssigned += LPA
			end
		end

		local SDEvent = SendDataE.OnServerEvent:Connect(function(Player, Line, Data)
			LC[Line] = Data
			AssignNew(Player)
		end)
		Players.PlayerAdded:Connect(function(Player) wait(5) AssignNew(Player) end)
		for _, Player in pairs(Players:GetPlayers()) do spawn(function() return AssignNew(Player) end) end

		repeat wait() until LastLineAssigned > 0

		local LinesDone = 0
		local LastUpdate = 0

		for A = 0, PxGrid - 1, LPA do
			while #LC[A] == 0 do wait() end
			if os.clock() - LastUpdate >= 10 then
				print("LINES ", LinesDone, "/", PxGrid)
				LastUpdate = os.clock()
			end
			LinesDone += LPA

			local TrySend = function() return pcall(function() SendData("data", LC[A]) end) end
			if not TrySend() then
				local success
				repeat wait(1) success = TrySend() until success
			end
		end

		SDEvent:Disconnect()
		SendData("end", {})

		i = i + 1
	end
end

print("DONE ALL")
