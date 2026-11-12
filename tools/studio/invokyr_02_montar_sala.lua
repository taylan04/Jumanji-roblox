--[[
INVOKYR - Script 02: Montar a Sala Principal v04 no Roblox Studio
==================================================================
Rode na BARRA DE COMANDOS (View > Command Bar) DEPOIS de importar os 3 arquivos GLB:
  SP04_Arquitetura.glb, SP04_Vegetacao.glb, SP04_Objetos.glb

O que faz (pode rodar quantas vezes quiser, nao duplica nada):
  - Encontra os 3 modelos importados, corrige escala e posicao automaticamente
    (usa as medidas reais exportadas do Blender, nao "chutes" pelo centro do modelo).
  - Organiza em Workspace > Invokyr > SalaPrincipal > Visual / Colisao / PontosDeLuz / Spawns
  - Malhas visuais NAO colidem; colisao fica em pecas invisiveis simples (piso, paredes,
    pilares, mesa, estantes, cadeiras, vasos, batentes e folhas das portas).
  - Cria 4 SpawnLocations livres ao redor da mesa, virados para ela.
  - Desativa (nao apaga) os outros SpawnLocations do Workspace.
  - Cria Attachments nas posicoes REAIS das lamparinas, lustre, janelas, vela e oculo
    (usados no proximo passo: iluminacao).
  - Imprime um relatorio no Output.
]]

local CONFIG = {
	ESCALA = 1.0,                         -- 1 unidade do Blender = 1 stud. Teste 1.15 se achar a sala apertada.
	ORIGEM = Vector3.new(0, 0.6, 0),      -- onde fica o centro do piso da sala
	MOSTRAR_COLISOES = false,             -- true = pecas de colisao ficam visiveis (vermelho) para conferir
	MOVER_SALA_ANTIGA_PARA_SERVERSTORAGE = true,  -- a sala antiga (UV_REPARADO) vai para ServerStorage, intacta
	TRANSPARENCIA_TEIAS = 0.55,
}

local DADOS = {
	luzes = {
		{
			nome = "Lamparina_0",
			tipo = "lamparina",
			pos = {-4.45, 5.1, -13.8353},
			cor = {1.0, 0.47, 0.16},
			energia_blender = 800.0,
		},
		{
			nome = "Lamparina_1",
			tipo = "lamparina",
			pos = {4.45, 5.1, -13.8353},
			cor = {1.0, 0.47, 0.16},
			energia_blender = 800.0,
		},
		{
			nome = "Lamparina_2",
			tipo = "lamparina",
			pos = {13.8353, 5.1, -4.45},
			cor = {1.0, 0.47, 0.16},
			energia_blender = 800.0,
		},
		{
			nome = "Lamparina_3",
			tipo = "lamparina",
			pos = {13.8353, 5.1, 4.45},
			cor = {1.0, 0.47, 0.16},
			energia_blender = 800.0,
		},
		{
			nome = "Lamparina_4",
			tipo = "lamparina",
			pos = {4.45, 5.1, 13.8353},
			cor = {1.0, 0.47, 0.16},
			energia_blender = 800.0,
		},
		{
			nome = "Lamparina_5",
			tipo = "lamparina",
			pos = {-4.45, 5.1, 13.8353},
			cor = {1.0, 0.47, 0.16},
			energia_blender = 800.0,
		},
		{
			nome = "Lamparina_6",
			tipo = "lamparina",
			pos = {-13.8353, 5.1, 4.45},
			cor = {1.0, 0.47, 0.16},
			energia_blender = 800.0,
		},
		{
			nome = "Lamparina_7",
			tipo = "lamparina",
			pos = {-13.8353, 5.1, -4.45},
			cor = {1.0, 0.47, 0.16},
			energia_blender = 800.0,
		},
		{
			nome = "Luz_do_lustre",
			tipo = "lustre",
			pos = {0.0, 11.7, -0.0},
			cor = {1.0, 0.6, 0.27},
			energia_blender = 1800.0,
		},
		{
			nome = "Luar_da_janela_0",
			tipo = "janela",
			pos = {0.0, 20.0, -16.2853},
			cor = {0.58, 0.7, 1.0},
			energia_blender = 2000.0,
			dir = {-0.0, -0.6239, 0.7815},
		},
		{
			nome = "Luar_da_janela_1",
			tipo = "janela",
			pos = {11.5154, 20.0, -11.5154},
			cor = {0.58, 0.7, 1.0},
			energia_blender = 2000.0,
			dir = {-0.5526, -0.6239, 0.5526},
		},
		{
			nome = "Luar_da_janela_2",
			tipo = "janela",
			pos = {16.2853, 20.0, -0.0},
			cor = {0.58, 0.7, 1.0},
			energia_blender = 2000.0,
			dir = {-0.7815, -0.6239, 0.0},
		},
		{
			nome = "Luar_da_janela_3",
			tipo = "janela",
			pos = {11.5154, 20.0, 11.5154},
			cor = {0.58, 0.7, 1.0},
			energia_blender = 2000.0,
			dir = {-0.5526, -0.6239, -0.5526},
		},
		{
			nome = "Luar_da_janela_4",
			tipo = "janela",
			pos = {0.0, 20.0, 16.2853},
			cor = {0.58, 0.7, 1.0},
			energia_blender = 2000.0,
			dir = {-0.0, -0.6239, -0.7815},
		},
		{
			nome = "Luar_da_janela_5",
			tipo = "janela",
			pos = {-11.5154, 20.0, 11.5154},
			cor = {0.58, 0.7, 1.0},
			energia_blender = 2000.0,
			dir = {0.5526, -0.6239, -0.5526},
		},
		{
			nome = "Luar_da_janela_6",
			tipo = "janela",
			pos = {-16.2853, 20.0, 0.0},
			cor = {0.58, 0.7, 1.0},
			energia_blender = 2000.0,
			dir = {0.7815, -0.6239, 0.0},
		},
		{
			nome = "Luar_da_janela_7",
			tipo = "janela",
			pos = {-11.5154, 20.0, -11.5154},
			cor = {0.58, 0.7, 1.0},
			energia_blender = 2000.0,
			dir = {0.5526, -0.6239, 0.5526},
		},
		{
			nome = "Luz_fria_do_oculo",
			tipo = "oculo",
			pos = {0.0, 34.4, -0.0},
			cor = {0.42, 0.68, 1.0},
			energia_blender = 1500.0,
			dir = {0.0, -1.0, -0.0},
		},
		{
			nome = "Preenchimento_indireto",
			tipo = "preenchimento",
			pos = {0.0, 17.0, 5.0},
			cor = {0.73, 0.77, 0.84},
			energia_blender = 800.0,
			dir = {0.0, -0.9333, -0.359},
		},
		{
			nome = "Vela_da_mesa",
			tipo = "vela",
			pos = {-1.0261, 3.52, 2.8191},
			cor = {1.0, 0.55, 0.2},
			energia_blender = 90.0,
		},
	},
	portais = {
		{
			nome = "North",
			pos = {0.0, 0.0, -14.4853},
			fora = {0.0, 0.0, -1.0},
		},
		{
			nome = "East",
			pos = {14.4853, 0.0, -0.0},
			fora = {1.0, 0.0, -0.0},
		},
		{
			nome = "South",
			pos = {0.0, 0.0, 14.4853},
			fora = {0.0, 0.0, 1.0},
		},
		{
			nome = "West",
			pos = {-14.4853, 0.0, -0.0},
			fora = {-1.0, 0.0, -0.0},
		},
	},
	portas = {
		{
			nome = "DoorNorth_Left",
			portal = "North",
			lado = "Left",
			dobradica = {-2.455, 0.0, -16.0603},
			caixa = {
				nome = "COL_DoorNorth_Left",
				forma = "Block",
				pos = {-1.23, 4.5305, -16.1078},
				x = {1.0, 0.0, -0.0},
				y = {0.0, 1.0, -0.0},
				tam = {2.41, 8.941, 0.655},
			},
		},
		{
			nome = "DoorNorth_Right",
			portal = "North",
			lado = "Right",
			dobradica = {2.455, 0.0, -16.0603},
			caixa = {
				nome = "COL_DoorNorth_Right",
				forma = "Block",
				pos = {1.23, 4.5305, -16.1078},
				x = {1.0, 0.0, -0.0},
				y = {0.0, 1.0, -0.0},
				tam = {2.41, 8.941, 0.655},
			},
		},
		{
			nome = "DoorEast_Left",
			portal = "East",
			lado = "Left",
			dobradica = {16.0603, 0.0, -2.455},
			caixa = {
				nome = "COL_DoorEast_Left",
				forma = "Block",
				pos = {16.1078, 4.5305, -1.23},
				x = {1.0, 0.0, -0.0},
				y = {0.0, 1.0, -0.0},
				tam = {0.655, 8.941, 2.41},
			},
		},
		{
			nome = "DoorEast_Right",
			portal = "East",
			lado = "Right",
			dobradica = {16.0603, 0.0, 2.455},
			caixa = {
				nome = "COL_DoorEast_Right",
				forma = "Block",
				pos = {16.1078, 4.5305, 1.23},
				x = {1.0, 0.0, -0.0},
				y = {0.0, 1.0, -0.0},
				tam = {0.655, 8.941, 2.41},
			},
		},
		{
			nome = "DoorSouth_Left",
			portal = "South",
			lado = "Left",
			dobradica = {2.455, 0.0, 16.0603},
			caixa = {
				nome = "COL_DoorSouth_Left",
				forma = "Block",
				pos = {1.23, 4.5305, 16.1078},
				x = {1.0, 0.0, -0.0},
				y = {0.0, 1.0, -0.0},
				tam = {2.41, 8.941, 0.655},
			},
		},
		{
			nome = "DoorSouth_Right",
			portal = "South",
			lado = "Right",
			dobradica = {-2.455, 0.0, 16.0603},
			caixa = {
				nome = "COL_DoorSouth_Right",
				forma = "Block",
				pos = {-1.23, 4.5305, 16.1078},
				x = {1.0, 0.0, -0.0},
				y = {0.0, 1.0, -0.0},
				tam = {2.41, 8.941, 0.655},
			},
		},
		{
			nome = "DoorWest_Left",
			portal = "West",
			lado = "Left",
			dobradica = {-16.0603, 0.0, 2.455},
			caixa = {
				nome = "COL_DoorWest_Left",
				forma = "Block",
				pos = {-16.1078, 4.5305, 1.23},
				x = {1.0, 0.0, -0.0},
				y = {0.0, 1.0, -0.0},
				tam = {0.655, 8.941, 2.41},
			},
		},
		{
			nome = "DoorWest_Right",
			portal = "West",
			lado = "Right",
			dobradica = {-16.0603, 0.0, -2.455},
			caixa = {
				nome = "COL_DoorWest_Right",
				forma = "Block",
				pos = {-16.1078, 4.5305, -1.23},
				x = {1.0, 0.0, -0.0},
				y = {0.0, 1.0, -0.0},
				tam = {0.655, 8.941, 2.41},
			},
		},
	},
	colisoes = {
		{
			nome = "COL_Piso",
			forma = "Block",
			pos = {0.0, -1.0061, 0.0},
			x = {1.0, 0.0, 0.0},
			y = {0.0, 1.0, 0.0},
			tam = {33.57, 2.0, 33.57},
		},
		{
			nome = "COL_PortalNorth_Esq",
			forma = "Block",
			pos = {-4.2925, 6.9, -14.8153},
			x = {1.0, 0.0, -0.0},
			y = {0.0, 1.0, -0.0},
			tam = {3.715, 13.8, 2.34},
		},
		{
			nome = "COL_PortalNorth_Dir",
			forma = "Block",
			pos = {4.2925, 6.9, -14.8153},
			x = {1.0, 0.0, -0.0},
			y = {0.0, 1.0, -0.0},
			tam = {3.715, 13.8, 2.34},
		},
		{
			nome = "COL_PortalNorth_Topo",
			forma = "Block",
			pos = {0.0, 11.4005, -14.8153},
			x = {1.0, 0.0, -0.0},
			y = {0.0, 1.0, -0.0},
			tam = {4.87, 4.799, 2.34},
		},
		{
			nome = "COL_PortalEast_Esq",
			forma = "Block",
			pos = {14.8153, 6.9, -4.2925},
			x = {-0.0, 0.0, 1.0},
			y = {0.0, 1.0, -0.0},
			tam = {3.715, 13.8, 2.34},
		},
		{
			nome = "COL_PortalEast_Dir",
			forma = "Block",
			pos = {14.8153, 6.9, 4.2925},
			x = {-0.0, 0.0, 1.0},
			y = {0.0, 1.0, -0.0},
			tam = {3.715, 13.8, 2.34},
		},
		{
			nome = "COL_PortalEast_Topo",
			forma = "Block",
			pos = {14.8153, 11.4005, 0.0},
			x = {-0.0, 0.0, 1.0},
			y = {0.0, 1.0, -0.0},
			tam = {4.87, 4.799, 2.34},
		},
		{
			nome = "COL_PortalSouth_Esq",
			forma = "Block",
			pos = {4.2925, 6.9, 14.8153},
			x = {-1.0, 0.0, 0.0},
			y = {0.0, 1.0, -0.0},
			tam = {3.715, 13.8, 2.34},
		},
		{
			nome = "COL_PortalSouth_Dir",
			forma = "Block",
			pos = {-4.2925, 6.9, 14.8153},
			x = {-1.0, 0.0, 0.0},
			y = {0.0, 1.0, -0.0},
			tam = {3.715, 13.8, 2.34},
		},
		{
			nome = "COL_PortalSouth_Topo",
			forma = "Block",
			pos = {0.0, 11.4005, 14.8153},
			x = {-1.0, 0.0, 0.0},
			y = {0.0, 1.0, -0.0},
			tam = {4.87, 4.799, 2.34},
		},
		{
			nome = "COL_PortalWest_Esq",
			forma = "Block",
			pos = {-14.8153, 6.9, 4.2925},
			x = {-0.0, 0.0, -1.0},
			y = {0.0, 1.0, -0.0},
			tam = {3.715, 13.8, 2.34},
		},
		{
			nome = "COL_PortalWest_Dir",
			forma = "Block",
			pos = {-14.8153, 6.9, -4.2925},
			x = {-0.0, 0.0, -1.0},
			y = {0.0, 1.0, -0.0},
			tam = {3.715, 13.8, 2.34},
		},
		{
			nome = "COL_PortalWest_Topo",
			forma = "Block",
			pos = {-14.8153, 11.4005, 0.0},
			x = {-0.0, 0.0, -1.0},
			y = {0.0, 1.0, -0.0},
			tam = {4.87, 4.799, 2.34},
		},
		{
			nome = "COL_Pillar_01",
			forma = "Cylinder",
			pos = {-5.9932, 10.25, 5.9986},
			x = {0.0, 1.0, 0.0},
			y = {1.0, 0.0, 0.0},
			tam = {20.5, 1.92, 1.92},
		},
		{
			nome = "COL_Pillar_02",
			forma = "Cylinder",
			pos = {6.0068, 10.25, 5.9986},
			x = {0.0, 1.0, 0.0},
			y = {1.0, 0.0, 0.0},
			tam = {20.5, 1.92, 1.92},
		},
		{
			nome = "COL_Pillar_03",
			forma = "Cylinder",
			pos = {6.0068, 10.25, -6.0014},
			x = {0.0, 1.0, 0.0},
			y = {1.0, 0.0, 0.0},
			tam = {20.5, 1.92, 1.92},
		},
		{
			nome = "COL_Pillar_04",
			forma = "Cylinder",
			pos = {-5.9932, 10.25, -6.0014},
			x = {0.0, 1.0, 0.0},
			y = {1.0, 0.0, 0.0},
			tam = {20.5, 1.92, 1.92},
		},
		{
			nome = "COL_WallBay_01",
			forma = "Block",
			pos = {10.4831, 12.0, -10.4831},
			x = {0.7071, 0.0, -0.7071},
			y = {0.0, 1.0, -0.0},
			tam = {1.82, 24.0, 12.05},
		},
		{
			nome = "COL_WallBay_03",
			forma = "Block",
			pos = {10.4831, 12.0, 10.4831},
			x = {0.7071, 0.0, -0.7071},
			y = {0.0, 1.0, -0.0},
			tam = {12.05, 24.0, 1.82},
		},
		{
			nome = "COL_WallBay_05",
			forma = "Block",
			pos = {-10.4831, 12.0, 10.4831},
			x = {0.7071, 0.0, -0.7071},
			y = {0.0, 1.0, -0.0},
			tam = {1.82, 24.0, 12.05},
		},
		{
			nome = "COL_WallBay_07",
			forma = "Block",
			pos = {-10.4831, 12.0, -10.4831},
			x = {0.7071, 0.0, -0.7071},
			y = {0.0, 1.0, -0.0},
			tam = {12.05, 24.0, 1.82},
		},
		{
			nome = "COL_Bookshelf_1",
			forma = "Block",
			pos = {9.7158, 4.1904, -9.7158},
			x = {0.7071, 0.0, -0.7071},
			y = {0.0, 1.0, -0.0},
			tam = {0.93, 8.181, 4.36},
		},
		{
			nome = "COL_Bookshelf_3",
			forma = "Block",
			pos = {9.7158, 4.1904, 9.7158},
			x = {0.7071, 0.0, -0.7071},
			y = {0.0, 1.0, -0.0},
			tam = {4.36, 8.181, 0.93},
		},
		{
			nome = "COL_Bookshelf_5",
			forma = "Block",
			pos = {-9.7158, 4.1904, 9.7158},
			x = {0.7071, 0.0, -0.7071},
			y = {0.0, 1.0, -0.0},
			tam = {0.93, 8.181, 4.36},
		},
		{
			nome = "COL_Bookshelf_7",
			forma = "Block",
			pos = {-9.7158, 4.1904, -9.7158},
			x = {0.7071, 0.0, -0.7071},
			y = {0.0, 1.0, -0.0},
			tam = {4.36, 8.181, 0.93},
		},
		{
			nome = "COL_Mesa",
			forma = "Cylinder",
			pos = {0.0, 1.35, 0.0},
			x = {0.0, 1.0, 0.0},
			y = {1.0, 0.0, 0.0},
			tam = {2.7, 6.68, 6.68},
		},
		{
			nome = "COL_Props_101",
			forma = "Block",
			pos = {4.256, 1.7301, -2.4575},
			x = {0.8572, 0.0, -0.515},
			y = {0.0, 1.0, -0.0},
			tam = {1.535, 3.46, 1.506},
		},
		{
			nome = "COL_Props_102",
			forma = "Block",
			pos = {-1.25, 0.9817, -3.1319},
			x = {0.682, 0.0, -0.7314},
			y = {0.0, 1.0, -0.0},
			tam = {1.512, 1.933, 3.461},
		},
		{
			nome = "COL_Props_103",
			forma = "Block",
			pos = {-4.2554, 1.7301, 2.4583},
			x = {0.8192, 0.0, -0.5736},
			y = {0.0, 1.0, -0.0},
			tam = {1.538, 3.46, 1.51},
		},
		{
			nome = "COL_Props_104",
			forma = "Block",
			pos = {2.1412, 0.9817, 2.6371},
			x = {0.9816, 0.0, -0.1908},
			y = {0.0, 1.0, -0.0},
			tam = {1.507, 1.933, 3.458},
		},
		{
			nome = "COL_Props_105",
			forma = "Block",
			pos = {-3.4136, 1.0805, 4.6732},
			x = {0.5446, 0.0, -0.8387},
			y = {0.0, 1.0, -0.0},
			tam = {2.156, 2.141, 1.539},
		},
		{
			nome = "COL_Props_106",
			forma = "Block",
			pos = {3.8189, 0.9813, -5.4646},
			x = {0.8988, 0.0, -0.4384},
			y = {0.0, 1.0, -0.0},
			tam = {1.957, 1.943, 1.397},
		},
		{
			nome = "COL_Props_107",
			forma = "Block",
			pos = {7.0444, 0.9781, 4.8941},
			x = {0.8829, 0.0, -0.4695},
			y = {0.0, 1.0, -0.0},
			tam = {1.392, 1.936, 1.95},
		},
	},
	spawns = {
		{
			nome = "Spawn_1",
			pos = {-7.714, -0.006, -1.084},
			folga = 3.46,
		},
		{
			nome = "Spawn_2",
			pos = {0.272, -0.006, 7.785},
			folga = 2.95,
		},
		{
			nome = "Spawn_3",
			pos = {-0.272, -0.006, -7.785},
			folga = 2.73,
		},
		{
			nome = "Spawn_4",
			pos = {7.79, -0.006, 0.0},
			folga = 2.66,
		},
	},
	info = {
		piso_z = -0.0061,
		vao_porta = {4.87, 9.001},
		mesa = {
			raio = 3.34,
			topo = 2.7,
		},
	},
	arquivos = {
		Arquitetura = {
			prefixo = "ARQ",
			min = {-16.4353, -0.25, -16.4353},
			max = {16.4353, 34.7224, 16.4353},
			partes = 53.0,
			tris_renderizados = 423848.0,
			tris_unicos = 244112.0,
		},
		Vegetacao = {
			prefixo = "VEG",
			min = {-15.3049, -0.3121, -14.7323},
			max = {14.6743, 19.219, 14.7627},
			partes = 18.0,
			tris_renderizados = 212737.0,
			tris_unicos = 212737.0,
		},
		Objetos = {
			prefixo = "OBJ",
			min = {-14.8353, -0.2278, -14.8353},
			max = {14.8353, 34.62, 14.8353},
			partes = 21.0,
			tris_renderizados = 135030.0,
			tris_unicos = 135030.0,
		},
	},
	texturas = 34.0,
	gerado_em = "2026-11-09 02:03",
}

local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

local avisos, linhas = {}, {}
local function info(...) local t = table.concat({...}, " "); table.insert(linhas, t); print("[Invokyr] " .. t) end
local function aviso(...) local t = table.concat({...}, " "); table.insert(avisos, t); warn("[Invokyr] " .. t) end

local recording
pcall(function() recording = ChangeHistoryService:TryBeginRecording("Invokyr montar sala") end)

local E, O = CONFIG.ESCALA, CONFIG.ORIGEM
local function V(t) return Vector3.new(t[1], t[2], t[3]) end
local function P(t) return O + V(t) * E end   -- dado do Blender -> mundo Roblox

-- ---------------------------------------------------------------- estrutura
local raiz = workspace:FindFirstChild("Invokyr") or Instance.new("Folder")
raiz.Name = "Invokyr"; raiz.Parent = workspace
local sala = raiz:FindFirstChild("SalaPrincipal") or Instance.new("Model")
sala.Name = "SalaPrincipal"; sala.Parent = raiz
local visual = sala:FindFirstChild("Visual") or Instance.new("Folder")
visual.Name = "Visual"; visual.Parent = sala
for _, nome in ipairs({"Colisao", "PontosDeLuz", "Spawns"}) do
	local f = sala:FindFirstChild(nome); if f then f:Destroy() end
end

-- ---------------------------------------------------------------- achar os modelos importados
local function prefixoDe(model)
	local cont = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("MeshPart") then
			local p = string.match(d.Name, "^(%u%u%u)_")
			if p then cont[p] = (cont[p] or 0) + 1 end
		end
	end
	local melhor, n = nil, 0
	for p, c in pairs(cont) do if c > n then melhor, n = p, c end end
	return melhor
end

local porPrefixo = {}
for chave, arq in pairs(DADOS.arquivos) do porPrefixo[arq.prefixo] = chave end

local encontrados = {}
local function considerar(m)
	if not m:IsA("Model") then return end
	local p = prefixoDe(m)
	local chave = p and porPrefixo[p]
	if chave then
		if encontrados[chave] and encontrados[chave] ~= m then
			aviso("Mais de um modelo '" .. chave .. "' encontrado; usando o mais novo. O antigo foi para ServerStorage.")
			local bk = ServerStorage:FindFirstChild("Invokyr_Backup") or Instance.new("Folder")
			bk.Name = "Invokyr_Backup"; bk.Parent = ServerStorage
			encontrados[chave].Parent = bk
		end
		encontrados[chave] = m
	end
end
for _, m in ipairs(visual:GetChildren()) do considerar(m) end
for _, m in ipairs(workspace:GetChildren()) do if m ~= raiz then considerar(m) end end

for chave in pairs(DADOS.arquivos) do
	if not encontrados[chave] then
		aviso("NAO encontrei o modelo de " .. chave .. " (SP04_" .. chave .. ".glb). Importe-o e rode de novo.")
	end
end

-- ---------------------------------------------------------------- escala e posicao
local function caixa(model)
	local mn = Vector3.new(math.huge, math.huge, math.huge); local mx = -mn
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			local cf, s = d.CFrame, d.Size / 2
			for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
				local w = cf:PointToWorldSpace(Vector3.new(s.X * sx, s.Y * sy, s.Z * sz))
				mn = mn:Min(w); mx = mx:Max(w)
			end end end
		end
	end
	return mn, mx
end

for chave, m in pairs(encontrados) do
	local arq = DADOS.arquivos[chave]
	local emin, emax = V(arq.min), V(arq.max)
	local mn, mx = caixa(m)
	local atual, esperado = mx - mn, emax - emin
	local fator = (atual.X / esperado.X + atual.Y / esperado.Y + atual.Z / esperado.Z) / 3
	if math.abs(fator - 1) > 0.01 or math.abs(E - m:GetScale()) > 0.001 then
		m:ScaleTo(m:GetScale() / fator * E)
		mn, mx = caixa(m)
	end
	m:TranslateBy((O + emin * E) - mn)
	m.Name = "SP04_" .. chave
	m.Parent = visual
	if math.abs(fator - E) > 0.05 then info(chave .. ": escala de importacao corrigida (fator " .. string.format("%.3f", fator) .. ")") end
end

-- ---------------------------------------------------------------- propriedades das malhas
local nMesh, nSA, nSemSA = 0, 0, {}
for _, d in ipairs(visual:GetDescendants()) do
	if d:IsA("BasePart") then
		nMesh += 1
		d.Anchored = true
		d.CanCollide = false
		d.CanTouch = false
		d.CanQuery = false
		d.Locked = true
		if d:IsA("MeshPart") then
			pcall(function() d.RenderFidelity = Enum.RenderFidelity.Automatic end)
			pcall(function() d.CollisionFidelity = Enum.CollisionFidelity.Box end)
		end
		local nome = d.Name
		if string.find(nome, "EMIS_Chama") then
			d.Material = Enum.Material.Neon
			d.Color = Color3.fromRGB(255, 147, 61)
			d.Transparency = 1           -- comeca apagada; o sistema de luz acende
			d.CastShadow = false
			CollectionService:AddTag(d, "Invokyr_Chama")
		elseif string.find(nome, "EMIS_Oculo") then
			d.Material = Enum.Material.Neon
			d.Color = Color3.fromRGB(120, 160, 230)
			d.Transparency = 0.35
			d.CastShadow = false
			CollectionService:AddTag(d, "Invokyr_Oculo")
		else
			local sa = d:FindFirstChildOfClass("SurfaceAppearance")
			if sa then nSA += 1 else table.insert(nSemSA, nome) end
			if string.find(nome, "Teia") then
				d.Transparency = CONFIG.TRANSPARENCIA_TEIAS; d.CastShadow = false
			end
			if string.sub(nome, 1, 4) == "VEG_" and string.find(nome, "Grama") then d.CastShadow = false end
		end
		if string.find(nome, "Door") then CollectionService:AddTag(d, "Invokyr_PortaVisual") end
	end
end
info(("Malhas visuais: %d | com textura (SurfaceAppearance): %d"):format(nMesh, nSA))
if #nSemSA > 0 then
	aviso(#nSemSA .. " malhas SEM textura (ex.: " .. nSemSA[1] .. "). Se forem muitas, o importador nao trouxe as imagens.")
end

-- ---------------------------------------------------------------- colisoes
local col = Instance.new("Folder"); col.Name = "Colisao"; col.Parent = sala
local colPortas = Instance.new("Folder"); colPortas.Name = "Portas"; colPortas.Parent = col
local function peca(c, pai)
	local p = Instance.new("Part")
	p.Name = c.nome
	p.Shape = (c.forma == "Cylinder") and Enum.PartType.Cylinder or Enum.PartType.Block
	p.Size = V(c.tam) * E
	p.CFrame = CFrame.fromMatrix(P(c.pos), V(c.x).Unit, V(c.y).Unit)
	p.Anchored = true; p.CanCollide = true; p.CanTouch = false; p.CanQuery = true
	p.CastShadow = false; p.Locked = true
	p.Transparency = CONFIG.MOSTRAR_COLISOES and 0.6 or 1
	p.Color = Color3.fromRGB(255, 60, 60); p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = pai
	return p
end
for _, c in ipairs(DADOS.colisoes) do peca(c, col) end
for _, d in ipairs(DADOS.portas) do
	local p = peca(d.caixa, colPortas)
	p:SetAttribute("Portal", d.portal); p:SetAttribute("Lado", d.lado)
	p:SetAttribute("Dobradica", P(d.dobradica))
	CollectionService:AddTag(p, "Invokyr_PortaColisao")
end
info(("Colisoes: %d pecas + %d portas"):format(#DADOS.colisoes, #DADOS.portas))

-- ---------------------------------------------------------------- pontos de luz (posicoes reais do Blender)
local luzes = Instance.new("Folder"); luzes.Name = "PontosDeLuz"; luzes.Parent = sala
local ancora = Instance.new("Part")
ancora.Name = "AncoraLuzes"; ancora.Anchored = true; ancora.CanCollide = false; ancora.CanQuery = false
ancora.CanTouch = false; ancora.Transparency = 1; ancora.Size = Vector3.new(1, 1, 1); ancora.CFrame = CFrame.new(O)
ancora.Locked = true; ancora.Parent = luzes
for _, l in ipairs(DADOS.luzes) do
	local a = Instance.new("Attachment")
	a.Name = l.nome
	a.Position = P(l.pos) - O
	a:SetAttribute("Tipo", l.tipo)
	a:SetAttribute("Cor", Color3.new(l.cor[1], l.cor[2], l.cor[3]))
	if l.dir then a:SetAttribute("Direcao", V(l.dir)) end
	a.Parent = ancora
end
for _, pt in ipairs(DADOS.portais) do
	local a = Instance.new("Attachment")
	a.Name = "Portal" .. pt.nome; a.Position = P(pt.pos) - O
	a:SetAttribute("Tipo", "portal"); a:SetAttribute("Fora", V(pt.fora))
	a.Parent = ancora
end
info(("Pontos de luz/portais: %d"):format(#DADOS.luzes + #DADOS.portais))

-- ---------------------------------------------------------------- spawns
local spawns = Instance.new("Folder"); spawns.Name = "Spawns"; spawns.Parent = sala
local desativados = 0
for _, s in ipairs(workspace:GetDescendants()) do
	if s:IsA("SpawnLocation") and not s:IsDescendantOf(sala) and s.Enabled then
		s.Enabled = false; s:SetAttribute("DesativadoPorInvokyr", true); desativados += 1
	end
end
local centro = O
for _, s in ipairs(DADOS.spawns) do
	local pos = P(s.pos)
	local sp = Instance.new("SpawnLocation")
	sp.Name = s.nome
	sp.Size = Vector3.new(3, 1, 3)
	sp.CFrame = CFrame.lookAt(pos - Vector3.new(0, 0.45, 0), Vector3.new(centro.X, pos.Y - 0.45, centro.Z))
	sp.Anchored = true; sp.CanCollide = false; sp.CanTouch = true; sp.CanQuery = false
	sp.Transparency = 1; sp.Neutral = true; sp.Duration = 0; sp.Enabled = true
	sp.CastShadow = false; sp.Locked = true
	local dec = sp:FindFirstChildOfClass("Decal"); if dec then dec:Destroy() end
	sp.Parent = spawns
end
info(("Spawns criados: %d | outros SpawnLocations desativados: %d"):format(#DADOS.spawns, desativados))

-- ---------------------------------------------------------------- sala antiga
if CONFIG.MOVER_SALA_ANTIGA_PARA_SERVERSTORAGE then
	for _, m in ipairs(workspace:GetChildren()) do
		if m:IsA("Model") and m ~= raiz and (string.find(m.Name, "UV_REPARADO") or string.find(m.Name, "SalaPrincipal")) then
			local bk = ServerStorage:FindFirstChild("Invokyr_Backup") or Instance.new("Folder")
			bk.Name = "Invokyr_Backup"; bk.Parent = ServerStorage
			m.Parent = bk
			info("Sala antiga '" .. m.Name .. "' movida (intacta) para ServerStorage > Invokyr_Backup")
		end
	end
end

-- ---------------------------------------------------------------- conferencia
local mn, mx = caixa(visual)
info(("Tamanho final da sala: %.1f x %.1f x %.1f studs"):format(mx.X - mn.X, mx.Y - mn.Y, mx.Z - mn.Z))
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = {col}
for _, s in ipairs(spawns:GetChildren()) do
	local r = workspace:Raycast(s.Position + Vector3.new(0, 4, 0), Vector3.new(0, -10, 0), params)
	if not r or r.Instance.Name ~= "COL_Piso" then
		aviso(s.Name .. ": o chao abaixo dele nao e o piso (" .. (r and r.Instance.Name or "nada") .. ")")
	end
end
pcall(function()
	workspace.CurrentCamera.CFrame = CFrame.lookAt(O + Vector3.new(0, 7, 13) * E, O + Vector3.new(0, 3, 0) * E)
end)

if recording then pcall(function() ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit) end) end
print("========== INVOKYR: RELATORIO ==========")
for _, l in ipairs(linhas) do print("  " .. l) end
if #avisos == 0 then print("  Sem avisos.") else for _, a in ipairs(avisos) do warn("  AVISO: " .. a) end end
print("Agora: clique em Play e teste andar, as portas fechadas e o spawn.")
