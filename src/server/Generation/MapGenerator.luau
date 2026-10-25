--!strict

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Terrain = Workspace:FindFirstChildOfClass("Terrain")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("GameConfig"))

local MapGenerator = {}

type SceneResult = {
    prompt: ProximityPrompt,
    doors: { BasePart },
}

local ROOM = GameConfig.ROOM

local function createPart(
    parent: Instance,
    name: string,
    size: Vector3,
    cframe: CFrame,
    color: Color3,
    material: Enum.Material
): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Anchored = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Color = color
    part.Material = material
    part.Parent = parent
    return part
end

local function createCylinder(
    parent: Instance,
    name: string,
    size: Vector3,
    cframe: CFrame,
    color: Color3,
    material: Enum.Material
): Part
    local part = createPart(parent, name, size, cframe, color, material)
    part.Shape = Enum.PartType.Cylinder
    return part
end

local function createLantern(parent: Instance, position: Vector3)
    local base = createPart(
        parent,
        "LanternaBase",
        Vector3.new(1.2, 1.2, 1.2),
        CFrame.new(position),
        Color3.fromRGB(104, 69, 42),
        Enum.Material.Metal
    )

    local glow = createPart(
        parent,
        "LanternaLuz",
        Vector3.new(1.5, 1.5, 1.5),
        CFrame.new(position + Vector3.new(0, 1.1, 0)),
        Color3.fromRGB(255, 186, 95),
        Enum.Material.Neon
    )

    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 194, 125)
    light.Brightness = 2.8
    light.Range = 28
    light.Shadows = true
    light.Parent = glow

    return base, glow
end

local function createBookshelf(parent: Instance, name: string, cframe: CFrame)
    local shelf = Instance.new("Model")
    shelf.Name = name
    shelf.Parent = parent

    local wood = Color3.fromRGB(79, 55, 40)

    local back = createPart(shelf, "Back", Vector3.new(14, 18, 1), cframe, wood, Enum.Material.WoodPlanks)
    local _ = back

    createPart(shelf, "Left", Vector3.new(1, 18, 4), cframe * CFrame.new(-6.5, 0, 1.5), wood, Enum.Material.WoodPlanks)
    createPart(shelf, "Right", Vector3.new(1, 18, 4), cframe * CFrame.new(6.5, 0, 1.5), wood, Enum.Material.WoodPlanks)

    for i = -2, 2 do
        createPart(
            shelf,
            "Shelf" .. tostring(i),
            Vector3.new(13, 0.6, 4),
            cframe * CFrame.new(0, i * 3.2, 1.5),
            wood,
            Enum.Material.WoodPlanks
        )
    end

    local rng = Random.new()
    for row = -2, 2 do
        for col = -5, 5 do
            if rng:NextNumber() > 0.2 then
                local book = createPart(
                    shelf,
                    "Book",
                    Vector3.new(0.8, rng:NextNumber(1.8, 2.6), 2.2),
                    cframe * CFrame.new(col, row * 3.2 + 0.8, 1.6),
                    Color3.fromRGB(
                        rng:NextInteger(90, 160),
                        rng:NextInteger(60, 110),
                        rng:NextInteger(40, 80)
                    ),
                    Enum.Material.SmoothPlastic
                )
                book.Orientation += Vector3.new(0, rng:NextNumber(-8, 8), 0)
            end
        end
    end

    return shelf
end

local function createScatteredBook(parent: Instance, position: Vector3, rotationY: number)
    local book = createPart(
        parent,
        "LivroCaido",
        Vector3.new(1.8, 0.35, 2.4),
        CFrame.new(position) * CFrame.Angles(math.rad(90), math.rad(rotationY), 0),
        Color3.fromRGB(120, 84, 55),
        Enum.Material.Wood
    )
    return book
end

local function createGrassPatch(parent: Instance, position: Vector3, size: Vector3)
    local patch = createPart(
        parent,
        "Grama",
        size,
        CFrame.new(position),
        Color3.fromRGB(78, 101, 61),
        Enum.Material.Grass
    )
    return patch
end

local function createLeafPatch(parent: Instance, position: Vector3, size: Vector3)
    local patch = createPart(
        parent,
        "FolhasCaidas",
        size,
        CFrame.new(position),
        Color3.fromRGB(110, 82, 44),
        Enum.Material.LeafyGrass
    )
    return patch
end

local function createVines(parent: Instance, position: Vector3, height: number)
    local vine = createPart(
        parent,
        "Vinha",
        Vector3.new(0.5, height, 0.5),
        CFrame.new(position),
        Color3.fromRGB(68, 89, 53),
        Enum.Material.Grass
    )
    return vine
end

local function createDoor(parent: Instance, name: string, cframe: CFrame, openDirection: string): BasePart
    local door = createPart(
        parent,
        name,
        Vector3.new(ROOM.DOOR_WIDTH, ROOM.DOOR_HEIGHT, ROOM.DOOR_THICKNESS),
        cframe,
        Color3.fromRGB(67, 46, 34),
        Enum.Material.WoodPlanks
    )

    door:SetAttribute("ClosedCFrame", door.CFrame)
    door:SetAttribute("OpenDirection", openDirection)

    for i = -2, 2 do
        createPart(
            parent,
            name .. "_Beam_" .. tostring(i),
            Vector3.new(0.4, ROOM.DOOR_HEIGHT, 0.4),
            cframe * CFrame.new(i * 2.5, 0, 0.7),
            Color3.fromRGB(96, 66, 48),
            Enum.Material.Wood
        )
    end

    return door
end

function MapGenerator.Generate(): SceneResult
    local old = Workspace:FindFirstChild("GeneratedPrototype")
    if old then
        old:Destroy()
    end

    local model = Instance.new("Model")
    model.Name = "GeneratedPrototype"
    model.Parent = Workspace

    local floorColor = Color3.fromRGB(63, 60, 55)
    local wallColor = Color3.fromRGB(67, 50, 39)
    local stoneColor = Color3.fromRGB(82, 78, 73)
    local warmLightColor = Color3.fromRGB(255, 196, 125)
    local pillarColor = Color3.fromRGB(74, 56, 44)

    local halfW = ROOM.WIDTH / 2
    local halfL = ROOM.LENGTH / 2
    local wallY = ROOM.WALL_HEIGHT / 2

    createPart(
        model,
        "Floor",
        Vector3.new(ROOM.WIDTH, ROOM.FLOOR_THICKNESS, ROOM.LENGTH),
        CFrame.new(0, 0, 0),
        floorColor,
        Enum.Material.Slate
    )

    createPart(
        model,
        "Ceiling",
        Vector3.new(ROOM.WIDTH, 2, ROOM.LENGTH),
        CFrame.new(0, ROOM.WALL_HEIGHT + 1, 0),
        wallColor,
        Enum.Material.WoodPlanks
    )

    createPart(
        model,
        "NorthWall",
        Vector3.new(ROOM.WIDTH, ROOM.WALL_HEIGHT, ROOM.WALL_THICKNESS),
        CFrame.new(0, wallY, -halfL),
        wallColor,
        Enum.Material.WoodPlanks
    )

    createPart(
        model,
        "SouthWall",
        Vector3.new(ROOM.WIDTH, ROOM.WALL_HEIGHT, ROOM.WALL_THICKNESS),
        CFrame.new(0, wallY, halfL),
        wallColor,
        Enum.Material.WoodPlanks
    )

    createPart(
        model,
        "EastWall",
        Vector3.new(ROOM.WALL_THICKNESS, ROOM.WALL_HEIGHT, ROOM.LENGTH),
        CFrame.new(halfW, wallY, 0),
        wallColor,
        Enum.Material.WoodPlanks
    )

    createPart(
        model,
        "WestWall",
        Vector3.new(ROOM.WALL_THICKNESS, ROOM.WALL_HEIGHT, ROOM.LENGTH),
        CFrame.new(-halfW, wallY, 0),
        wallColor,
        Enum.Material.WoodPlanks
    )

    local pillarOffset = 22
    local pillarY = ROOM.PILLAR_HEIGHT / 2 + 1

    local pillarPositions = {
        Vector3.new(-pillarOffset, pillarY, -pillarOffset),
        Vector3.new(pillarOffset, pillarY, -pillarOffset),
        Vector3.new(-pillarOffset, pillarY, pillarOffset),
        Vector3.new(pillarOffset, pillarY, pillarOffset),
    }

    for _, pos in ipairs(pillarPositions) do
        createPart(
            model,
            "Pillar",
            Vector3.new(ROOM.PILLAR_SIZE, ROOM.PILLAR_HEIGHT, ROOM.PILLAR_SIZE),
            CFrame.new(pos),
            pillarColor,
            Enum.Material.WoodPlanks
        )

        createPart(
            model,
            "PillarTop",
            Vector3.new(ROOM.PILLAR_SIZE + 1, 1.5, ROOM.PILLAR_SIZE + 1),
            CFrame.new(pos + Vector3.new(0, ROOM.PILLAR_HEIGHT / 2, 0)),
            Color3.fromRGB(92, 70, 54),
            Enum.Material.WoodPlanks
        )

        createLantern(model, pos + Vector3.new(0, ROOM.PILLAR_HEIGHT / 2 - 3, 0))
    end

    local tableBase = createCylinder(
        model,
        "MesaBase",
        Vector3.new(2.2, 4, 2.2),
        CFrame.new(0, 3, 0) * CFrame.Angles(0, 0, math.rad(90)),
        Color3.fromRGB(79, 55, 40),
        Enum.Material.Wood
    )

    local _ = tableBase

    local tableTop = createPart(
        model,
        "MesaTopo",
        Vector3.new(14, 1.2, 14),
        CFrame.new(0, 5.5, 0),
        Color3.fromRGB(97, 69, 48),
        Enum.Material.WoodPlanks
    )

    local board = createPart(
        model,
        "Tabuleiro",
        Vector3.new(9, 0.7, 9),
        CFrame.new(0, 6.45, 0),
        Color3.fromRGB(148, 116, 64),
        Enum.Material.WoodPlanks
    )

    createPart(
        model,
        "TabuleiroCentro",
        Vector3.new(5.6, 0.08, 5.6),
        board.CFrame * CFrame.new(0, 0.39, 0),
        Color3.fromRGB(66, 40, 29),
        Enum.Material.SmoothPlastic
    )

    for _, off in ipairs({
        Vector3.new(-2.1, 0.42, -2.1),
        Vector3.new(2.1, 0.42, -2.1),
        Vector3.new(-2.1, 0.42, 2.1),
        Vector3.new(2.1, 0.42, 2.1),
        Vector3.new(0, 0.42, 0),
    }) do
        createPart(
            model,
            "TabuleiroRune",
            Vector3.new(0.7, 0.08, 0.7),
            board.CFrame * CFrame.new(off),
            Color3.fromRGB(202, 164, 82),
            Enum.Material.Neon
        )
    end

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Lançar dado"
    prompt.ObjectText = "Tabuleiro misterioso"
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 11
    prompt.RequiresLineOfSight = false
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.Parent = board

    local doors = {}

    local northDoor = createDoor(
        model,
        "PortaNorte",
        CFrame.new(0, ROOM.DOOR_HEIGHT / 2 + 1, -halfL + 0.7),
        "X"
    )
    table.insert(doors, northDoor)

    local southDoor = createDoor(
        model,
        "PortaSul",
        CFrame.new(0, ROOM.DOOR_HEIGHT / 2 + 1, halfL - 0.7),
        "-X"
    )
    table.insert(doors, southDoor)

    local eastDoor = createDoor(
        model,
        "PortaLeste",
        CFrame.new(halfW - 0.7, ROOM.DOOR_HEIGHT / 2 + 1, 0) * CFrame.Angles(0, math.rad(90), 0),
        "-Z"
    )
    table.insert(doors, eastDoor)

    local westDoor = createDoor(
        model,
        "PortaOeste",
        CFrame.new(-halfW + 0.7, ROOM.DOOR_HEIGHT / 2 + 1, 0) * CFrame.Angles(0, math.rad(90), 0),
        "Z"
    )
    table.insert(doors, westDoor)

    createBookshelf(model, "BookshelfNorthWest", CFrame.new(-30, 10, -halfL + 2))
    createBookshelf(model, "BookshelfNorthEast", CFrame.new(30, 10, -halfL + 2))
    createBookshelf(model, "BookshelfSouthWest", CFrame.new(-30, 10, halfL - 2) * CFrame.Angles(0, math.rad(180), 0))
    createBookshelf(model, "BookshelfSouthEast", CFrame.new(30, 10, halfL - 2) * CFrame.Angles(0, math.rad(180), 0))

    createScatteredBook(model, Vector3.new(-10, 1.2, 8), 12)
    createScatteredBook(model, Vector3.new(12, 1.2, -9), -18)
    createScatteredBook(model, Vector3.new(-14, 1.2, -6), 33)
    createScatteredBook(model, Vector3.new(8, 1.2, 15), -41)
    createScatteredBook(model, Vector3.new(18, 1.2, 4), 19)

    createGrassPatch(model, Vector3.new(-26, 1.05, 19), Vector3.new(8, 0.15, 6))
    createGrassPatch(model, Vector3.new(24, 1.05, -18), Vector3.new(10, 0.15, 7))
    createGrassPatch(model, Vector3.new(0, 1.05, 28), Vector3.new(7, 0.15, 5))

    createLeafPatch(model, Vector3.new(-18, 1.03, -20), Vector3.new(9, 0.08, 6))
    createLeafPatch(model, Vector3.new(18, 1.03, 20), Vector3.new(8, 0.08, 6))
    createLeafPatch(model, Vector3.new(4, 1.03, -28), Vector3.new(10, 0.08, 5))

    createVines(model, Vector3.new(-halfW + 3, 8, -halfL + 4), 16)
    createVines(model, Vector3.new(halfW - 3, 10, halfL - 6), 20)
    createVines(model, Vector3.new(-4, 9, -halfL + 2), 18)
    createVines(model, Vector3.new(halfW - 2, 7, 6), 14)

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "Entrada"
    spawn.Size = Vector3.new(8, 1, 8)
    spawn.CFrame = CFrame.new(0, 1.5, 24)
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Material = Enum.Material.WoodPlanks
    spawn.Color = Color3.fromRGB(104, 82, 58)
    spawn.Parent = model

    if Terrain then
        Terrain.WaterWaveSize = 0.1
        Terrain.WaterWaveSpeed = 2
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 0.3
    end

    Lighting.ClockTime = 0.8
    Lighting.Brightness = 1.6
    Lighting.ExposureCompensation = -0.2
    Lighting.Ambient = Color3.fromRGB(40, 34, 36)
    Lighting.OutdoorAmbient = Color3.fromRGB(36, 31, 33)
    Lighting.ColorShift_Top = Color3.fromRGB(70, 54, 42)
    Lighting.ColorShift_Bottom = Color3.fromRGB(34, 32, 38)
    Lighting.FogColor = Color3.fromRGB(46, 39, 36)
    Lighting.FogStart = 8
    Lighting.FogEnd = 145

    print("[MapGenerator] Sala do tabuleiro gerada com sucesso.")

    return {
        prompt = prompt,
        doors = doors,
    }
end

return MapGenerator