local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera


local Stats = ReplicatedStorage:WaitForChild("RenderStats")
local AssignLine = ReplicatedStorage:WaitForChild("AssignLine")
local SendData = ReplicatedStorage:WaitForChild("SendData")

local Terrain = Workspace.Terrain

local Grid = Stats.Grid.Value
local PPS = Stats.PPS.Value
local PxGrid = Grid * PPS

local RenderWater = Stats.RenderWater.Value
local SuperSample = Stats.SuperSampling.Value

local ShadowsCone = Stats.ShadowsCone.Value
local ShadowsConeAngle = Stats.ShadowsConeAngle.Value
local ShadowsTrans = Stats.ShadowsTrans.Value

local SunLen = Stats.ShadowsLen.Value

local Default = Vector3.new(0,0,0)

local Params = RaycastParams.new()
local function Raycasting(Origin,Direction)
	local Result = Workspace:Raycast(Origin, Direction, Params)

	if Result then return Result.Instance, Result.Position, Result.Normal, Result.Material end
	return nil, Origin + Direction, Default, Enum.Material.Air
end

local function GetColorFromMaterial(Material)
	if (not RenderWater) and Material == Enum.Material.Water then return Default end
	local Color
	pcall(function()
		if (Material ~= Enum.Material.Water) then Color = Terrain:GetMaterialColor(Material)
		else Color = Terrain.WaterColor
		end
	end)
	if Color then
		return Vector3.new(
			math.floor(Color.R * 255 + 0.5),
			math.floor(Color.G * 255 + 0.5),
			math.floor(Color.B * 255 + 0.5)
		)
	end
	return Default
end

local SunPosition
if (Stats.SunPosition.Value == "Static") then
	SunPosition = CFrame.new(0,0,0,-0.707106829,-0.54167515,-0.454519451,0,0.642787635,-0.766044438,0.707106709,-0.54167527,-0.45451954)
else
	SunPosition = CFrame.lookAt(Default,Lighting:GetSunDirection())
end

local function DoConeShadows(BaseColor,HitPos,NorA)
	local PercAdd = 1/(ShadowsCone+1)
	local ArcDel = 360/ShadowsCone

	local Perc = 0
	local Part = Raycasting(HitPos + NorA,SunPosition.LookVector * SunLen)

	if Part then Perc += PercAdd end

	for A = 1,ShadowsCone do
		Part = Raycasting(HitPos + NorA, (SunPosition * CFrame.Angles(0,0,math.rad(ArcDel * A)) * CFrame.Angles(math.rad(ShadowsConeAngle),0,0)).LookVector * SunLen)
		if Part then Perc += PercAdd end
	end

	return BaseColor:Lerp(Default, Perc*ShadowsTrans)
end

local function DoSoftShadows(BaseColor,HitPos,NorA)
	local Perc = 0

	local Part, Pos, Nor, Mat = Raycasting(HitPos + NorA, SunPosition.LookVector*SunLen)
	if (Part) then Perc += 0.2 end
	local Part, Pos, Nor, Mat = Raycasting(HitPos + NorA, SunPosition*CFrame.Angles(math.rad(5),0,0).LookVector*SunLen)
	if (Part) then Perc += 0.2 end
	local Part, Pos, Nor, Mat = Raycasting(HitPos + NorA, SunPosition*CFrame.Angles(math.rad(-5),0,0).LookVector*SunLen)
	if (Part) then Perc += 0.2 end
	local Part, Pos, Nor, Mat = Raycasting(HitPos + NorA, SunPosition.LookVector*SunLen)
	if (Part) then Perc += 0.2 end
	local Part, Pos, Nor, Mat = Raycasting(HitPos + NorA, SunPosition.LookVector*SunLen)
	if (Part) then Perc += 0.2 end

	return BaseColor:Lerp(Default,Perc*0.3)
end

AssignLine.OnClientEvent:Connect(function(Line, Lines, PlotCenter, FirstStud, RayLen)
	print("Line", Line + 1)

	Camera.CameraType = Enum.CameraType.Scriptable
	local OldCF = Camera.CFrame
	Camera.CFrame = PlotCenter * CFrame.Angles(-math.pi/2, 0, 0)
	if (OldCF.Position - Camera.CFrame.Position).Magnitude > 100 then wait(2) end

	local Data = {}
	for B = Line, Line + Lines - 1 do
		for A = 0, PxGrid - 1 do
			local BaseColor = Default
			local BaseColor1,BaseColor2,BaseColor3,BaseColor4 = Default,Default,Default,Default

			local Start = (FirstStud * CFrame.new(B / PPS, 0, A / PPS)).Position

			local Part,Pos,Nor,Mat = Raycasting(Start+Vector3.new(0.01, 0, 0.01), Vector3.new(0,-RayLen,0))
			local SunNor = (SunPosition.LookVector-Nor).Magnitude*0.4

			local Empty = not Part

			if not SuperSample or Empty then
				if (Part == Terrain) then
					BaseColor1 = GetColorFromMaterial(Mat):Lerp(Default,math.clamp(SunNor,0,0.8))
				elseif ((Part) and (Part.Transparency < 1)) then
					local Col = Part.Color
					BaseColor1 = Vector3.new(
						Col.R * 255,
						Col.G * 255,
						Col.B * 255
					):Lerp(Default,math.clamp(SunNor,0,0.8))
				end
				if ((BaseColor1 ~= Default) and (Part)) then
					BaseColor1 = DoConeShadows(BaseColor1,Pos,Nor)
				end
				BaseColor = BaseColor1
			else -- SUPER SAMPLING X4

				local Part,Pos,Nor,Mat = Raycasting(Start+Vector3.new(-1/PPS/4,0,-1/PPS/4)+Vector3.new(0.01,0,0.01), Vector3.new(0,-RayLen,0))

				if (not Part) then
					Empty = true
				end

				if (Part == Terrain) then
					BaseColor1 = GetColorFromMaterial(Mat):Lerp(Default,math.clamp(SunNor,0,0.8))
				elseif ((Part) and (Part.Transparency < 1)) then
					local Col = Part.Color
					BaseColor1 = Vector3.new(
						Col.R * 255,
						Col.G * 255,
						Col.B * 255
					):Lerp(Default,math.clamp(SunNor,0,0.8))
				end
				if ((BaseColor1 ~= Default) and (Part)) then
					BaseColor1 = DoConeShadows(BaseColor1,Pos,Nor)
				end

				local Part,Pos,Nor,Mat = Raycasting(Start+Vector3.new(1/PPS/4,0,-1/PPS/4)+Vector3.new(0.01,0,0.01), Vector3.new(0,-RayLen,0))

				if (not Part) then
					Empty = true
				end

				if (Part == Terrain) then
					BaseColor2 = GetColorFromMaterial(Mat):Lerp(Default,math.clamp(SunNor,0,0.8))
				elseif ((Part) and (Part.Transparency < 1)) then
					local Col = Part.Color
					BaseColor2 = Vector3.new(
						Col.R * 255,
						Col.G * 255,
						Col.B * 255
					):Lerp(Default,math.clamp(SunNor,0,0.8))
				end
				if ((BaseColor2 ~= Default) and (Part)) then
					BaseColor2 = DoConeShadows(BaseColor2,Pos,Nor)
				end

				local Part,Pos,Nor,Mat = Raycasting(Start+Vector3.new(-1/PPS/4,0,1/PPS/4)+Vector3.new(0.01,0,0.01), Vector3.new(0,-RayLen,0))

				if (not Part) then
					Empty = true
				end

				if (Part == Terrain) then
					BaseColor3 = GetColorFromMaterial(Mat):Lerp(Default,math.clamp(SunNor,0,0.8))
				elseif ((Part) and (Part.Transparency < 1)) then
					local Col = Part.Color
					BaseColor3 = Vector3.new(
						Col.R * 255,
						Col.G * 255,
						Col.B * 255
					):Lerp(Default,math.clamp(SunNor,0,0.8))
				end
				if ((BaseColor3 ~= Default) and (Part)) then
					BaseColor3 = DoConeShadows(BaseColor3,Pos,Nor)
				end

				local Part,Pos,Nor,Mat = Raycasting(Start+Vector3.new(1/PPS/4,0,1/PPS/4)+Vector3.new(0.01,0,0.01), Vector3.new(0,-RayLen,0))

				if (not Part) then
					Empty = true
				end

				if (Part == Terrain) then
					BaseColor4 = GetColorFromMaterial(Mat):Lerp(Default,math.clamp(SunNor,0,0.8))
				elseif ((Part) and (Part.Transparency < 1)) then
					local Col = Part.Color
					BaseColor4 = Vector3.new(
						Col.R * 255,
						Col.G * 255,
						Col.B * 255
					):Lerp(Default,math.clamp(SunNor,0,0.8))
				end
				if ((BaseColor4 ~= Default) and (Part)) then
					BaseColor4 = DoConeShadows(BaseColor4,Pos,Nor)
				end

				--^^^^^^^^^^^^^^^^^--
				-- AVERAGE COLOURS FOR PIXELS
				BaseColor = (BaseColor1+BaseColor2+BaseColor3+BaseColor4)*0.25
			end
			table.insert(Data,{
				math.floor(BaseColor.X + 0.5),
				math.floor(BaseColor.Y + 0.5),
				math.floor(BaseColor.Z + 0.5),
				Empty and 0 or 255
			})
		end
		RunService.Heartbeat:Wait()
	end
	SendData:FireServer(Line, Data)
end)