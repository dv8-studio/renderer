-- Script used for resolving issues with unions and meshes colors

-- To get all unions into special workspace folder
local Workspace = game:GetService("Workspace")
local Folder = Instance.new("Folder", Workspace)
Folder.Name = "UnionFix"

-- Only fix unions without UsePartColor and MeshParts with textures
local shouldFix = function(v)
  -- only retrieves parts with certain color
  --if (v:IsA 'BasePart' or v:IsA'UnionOperation') and v.BrickColor == BrickColor.new("Hurricane grey") then return true end
  if v:IsA 'UnionOperation' and not v.UsePartColor then return true end
  if v:IsA 'MeshPart' and v.TextureID ~= "" then return true end
  return false
end
for _, v in ipairs(Workspace:GetDescendants()) do
  if shouldFix(v) then
    if not v:FindFirstChild("OriginalParent") then
      local originalParent = Instance.new("ObjectValue", v)
      originalParent.Name = "OriginalParent"
      originalParent.Value = v.Parent
    end
    v.Parent = Folder
  end
end

-- Restore fixed
local shouldFix = function(v)
  if v:IsA 'UnionOperation' and not v.UsePartColor then return true end
  if v:IsA 'MeshPart' and v.TextureID ~= "" then return true end
  return false
end
local Workspace = game:GetService("Workspace")
local UnionFix = Workspace:FindFirstChild("UnionFix")
if UnionFix then
  for _, v in ipairs(UnionFix:GetChildren()) do
    if not shouldFix(v) then
      local originalParent = v:FindFirstChild("OriginalParent")
      if originalParent and originalParent.Value then
        v.Parent = originalParent.Value
        originalParent:Destroy()
      end
    end
  end
end

-- To restore
local Workspace = game:GetService("Workspace")
local UnionFix = Workspace:FindFirstChild("UnionFix")
if UnionFix then
  for _, v in ipairs(UnionFix:GetChildren()) do
    local originalParent = v:FindFirstChild("OriginalParent")
    if originalParent and originalParent.Value then
      v.Parent = originalParent.Value
      originalParent:Destroy()
    end
  end
end