local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Find properties
local RenderData = {
  GetParts = function ()
    local m = {}
    for _, v in ipairs(CollectionService:GetTagged("RenderPart")) do
      m[v.Name] = v
    end
    return m
  end
}

local RenderDataMod = ReplicatedStorage:FindFirstChild("RenderData")
if RenderDataMod then
  for i, v in pairs(require(RenderDataMod)) do RenderData[i] = v end
end

local RenderParts = RenderData.GetParts()
local RenderPartsTable = {}
for _, v in pairs(RenderParts) do table.insert(RenderPartsTable, v) end

-- Delete game scripts
local ScriptServices = RenderData.ScriptServices or {
  "Workspace", "Lighting", "ReplicatedFirst", "ServerScriptService", "StarterGui", "StarterPack", "StarterPlayer", "SoundService"
}
local scriptTypes = RenderData.ScriptTypes or { "Script", "LocalScript", "ModuleScript" }
local isAnyScript = function (v)
  for _, t in ipairs(scriptTypes) do
    if v:IsA(t) and v ~= RenderDataMod then return true end
  end
  return false
end

for _, Service in ipairs(ScriptServices) do
  local iService = game:GetService(Service)
  for _, v in ipairs(iService:GetDescendants()) do
    if isAnyScript(v) then v:Destroy() end
  end
end

-- Delete invisible parts
local MinInvisibleTransparency = RenderData.MinInvisibleTransparency or 0.9
for _, v in ipairs(Workspace:GetDescendants()) do
  if v:IsA 'BasePart' and v.Transparency > MinInvisibleTransparency and not table.find(RenderPartsTable, v) then v:Destroy() end
end

-- Use CollectionService to determine other elements which should be deleted
local othersDelete = RenderData.OthersDelete or {}
local othersPathDelete = RenderData.OthersPathDelete or {}
for _, Tag in ipairs(othersDelete) do
  for _, v in ipairs(CollectionService:GetTagged(Tag)) do v:Destroy() end
end
local RecursiveDelete
RecursiveDelete = function (Parent, Data)
  if not Parent then return end
  if not Data then return Parent:Destroy() end

  for i, v in pairs(Data) do RecursiveDelete(Parent:FindFirstChild(i), type(v) == "table" and v or nil) end
end
RecursiveDelete(Workspace, othersPathDelete)

-- Insert selected parts
local RenderFolder = Instance.new("Folder", Workspace)
RenderFolder.Name = "RenderFolder"

for _, RenderObject in pairs(CollectionService:GetTagged("RenderObject")) do RenderObject.Parent = RenderFolder end

-- Set the parts and other properties
local RenderStats = ReplicatedStorage:FindFirstChild("RenderStats")
if not RenderStats then
  RenderStats = Instance.new("Folder", ReplicatedStorage)
  RenderStats.Name = "RenderStats"
end

local Parts = RenderStats:FindFirstChild("Parts")
if not Parts then
  Parts = Instance.new("Folder", RenderStats)
  Parts.Name = "Parts"
end

for i, v in pairs(RenderParts) do
  local object = Parts:FindFirstChild(i) or Instance.new("ObjectValue", Parts)
  object.Name = i
  object.Value = v
end

if RenderData.OtherProperties then
  for i, v in pairs(RenderData.OtherProperties) do
    local object = RenderStats:FindFirstChild(i)
    if object then object.Value = v end
  end
end