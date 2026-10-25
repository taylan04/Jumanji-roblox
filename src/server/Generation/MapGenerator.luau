--!strict
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local MapGenerator = {}
local function part(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material): Part
    local block = Instance.new("Part")
    block.Name = name
    block.Size = size
    block.Position = position
    block.Anchored = true
    block.Color = color
    block.Material = material
    block.TopSurface = Enum.SurfaceType.Smooth
    block.BottomSurface = Enum.SurfaceType.Smooth
    block.Parent = parent
    return block
end
function MapGenerator.Generate(): ProximityPrompt
    local old = Workspace:FindFirstChild("GeneratedPrototype")
    if old then
        old:Destroy()
    end
    local model = Instance.new("Model")
    model.Name = "GeneratedPrototype"
    model.Parent = Workspace
    local stone = Color3.fromRGB(42, 43, 54)
    local wood = Color3.fromRGB(57, 43, 48)
    local brass = Color3.fromRGB(178, 124, 67)
    part(model, "Piso", Vector3.new(72, 2, 72), Vector3.new(0, 0, 0), stone, Enum.Material.Slate)
    part(model, "ParedeNorte", Vector3.new(72, 19, 2), Vector3.new(0, 10.5, -36), wood, Enum.Material.WoodPlanks)
    part(model, "ParedeSul", Vector3.new(72, 19, 2), Vector3.new(0, 10.5, 36), wood, Enum.Material.WoodPlanks)
    part(model, "ParedeLeste", Vector3.new(2, 19, 72), Vector3.new(36, 10.5, 0), wood, Enum.Material.WoodPlanks)
    part(model, "ParedeOeste", Vector3.new(2, 19, 72), Vector3.new(-36, 10.5, 0), wood, Enum.Material.WoodPlanks)
    part(model, "Pedestal", Vector3.new(7, 3, 7), Vector3.new(0, 2.5, 0), wood, Enum.Material.Wood)
    local board = part(model, "Tabuleiro", Vector3.new(8, 0.5, 8), Vector3.new(0, 4.25, 0), brass, Enum.Material.WoodPlanks)
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Lançar dado"
    prompt.ObjectText = "Tabuleiro misterioso"
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 11
    prompt.RequiresLineOfSight = false
    prompt.Parent = board
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "Entrada"
    spawn.Size = Vector3.new(7, 1, 7)
    spawn.Position = Vector3.new(0, 1.5, 25)
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Material = Enum.Material.Wood
    spawn.Color = Color3.fromRGB(85, 67, 64)
    spawn.Parent = model
    for _, x in {-23, 23} do
        for _, z in {-23, 23} do
            part(model, "Coluna", Vector3.new(2, 10, 2), Vector3.new(x, 6, z), wood, Enum.Material.Wood)
            local lamp = part(model, "Lanterna", Vector3.new(2.6, 1, 2.6), Vector3.new(x, 11.5, z), brass, Enum.Material.Neon)
            local light = Instance.new("PointLight")
            light.Name = "LuzQuente"
            light.Color = Color3.fromRGB(255, 193, 122)
            light.Brightness = 2
            light.Range = 29
            light.Shadows = true
            light.Parent = lamp
        end
    end
    Lighting.ClockTime = 1
    Lighting.Brightness = 1.5
    Lighting.Ambient = Color3.fromRGB(38, 36, 48)
    Lighting.OutdoorAmbient = Color3.fromRGB(46, 40, 47)
    print("[MapGenerator] Sala protótipo criada.")
    return prompt
end
return MapGenerator
