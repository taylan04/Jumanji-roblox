--[[
INVOKYR - Script 15: Instalar a GALERIA (sala de 2 andares, 3 x 5 celulas)
==================================================================
ANTES: importe o arquivo Galeria.glb no Studio (Avatar/Home > Import 3D).
DEPOIS: rode este script na BARRA DE COMANDOS (View > Command Bar), com o jogo PARADO.

O que faz (pode rodar quantas vezes quiser, nao duplica nada):
  - Acha o modelo importado e encaixa cada uma das 277 pecas no lugar exato
    (as posicoes foram lidas do proprio GLB, nao sao chute).
  - Monta tudo em Workspace > Invokyr > Mansao > Salas > Galeria, numa area de teste
    longe da mansao (CONFIG.ORIGEM). Quando o gerador existir, ele e quem posiciona a sala.
  - Cria as paredes invisiveis (colisao), a rampa da escada, as luzes, os esconderijos
    de totem e de dado e os pontos de encaixe das portas.
  - Deixa os MOVEIS QUE ABREM funcionando: armarios, guarda-roupas, gaveteiros, baus,
    relogio, gavetas da mesa e a porta debaixo da escada. E so chegar perto e apertar E.
  - Instala o script Invokyr_Moveis no ServerScriptService (cuida de abrir e fechar).
  - Nada e apagado: o que sai de uso vai para ServerStorage > Invokyr_Backup.
]]

local CONFIG = {
	ORIGEM = Vector3.new(400, 0.594, 0), -- centro do piso da sala (area de teste, longe da mansao)
	GIRO = 0,                            -- quartos de volta (0, 1, 2 ou 3)

	-- Cada vaga de porta: "fecho" (painel fechado) ou "porta" (folhas de porta fechadas).
	PORTAS = { N = "fecho", S = "porta", L = "fecho", O = "fecho" },

	-- false = os esconderijos existem mas o Script 09 ainda NAO sorteia totens aqui.
	-- Deixe false enquanto a sala nao estiver ligada a mansao (ninguem consegue chegar nela).
	ESCONDERIJOS_ATIVOS = false,

	MOSTRAR_COLISOES = false,     -- true = paredes invisiveis aparecem em vermelho
	MOSTRAR_ESCONDERIJOS = false, -- true = pontos de totem (verde) e de dado (azul) aparecem
	TRAVAR = true,
}

-- ================================================================== guarda
local RunService = game:GetService("RunService")
if RunService:IsRunning() then
	error("[Invokyr] Pare o jogo (Stop) antes de rodar o Script 15. Em Play nada do que ele monta fica salvo.")
end

local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

local V, CF, C3 = Vector3.new, CFrame.new, Color3.fromRGB

-- ================================================================== dados (gerados do Blender)
local PECAS = {
	["Abre_Armario_SL_PortaD__Latao"] = {V(13.363,4.25,23.705), V(2.274,5.86,0.35)},
	["Abre_Armario_SL_PortaD__Nogueira"] = {V(13.256,4.125,23.895), V(2.488,7.01,0.17)},
	["Abre_Armario_SL_PortaD__Talha"] = {V(13.256,4.125,23.845), V(1.928,6.45,0.03)},
	["Abre_Armario_SL_PortaE__Latao"] = {V(10.637,4.25,23.705), V(2.274,5.86,0.35)},
	["Abre_Armario_SL_PortaE__Nogueira"] = {V(10.744,4.125,23.895), V(2.488,7.01,0.17)},
	["Abre_Armario_SL_PortaE__Talha"] = {V(10.744,4.125,23.845), V(1.928,6.45,0.03)},
	["Abre_Armario_SO_PortaD__Latao"] = {V(-10.637,4.25,23.705), V(2.274,5.86,0.35)},
	["Abre_Armario_SO_PortaD__Nogueira"] = {V(-10.744,4.125,23.895), V(2.488,7.01,0.17)},
	["Abre_Armario_SO_PortaD__Talha"] = {V(-10.744,4.125,23.845), V(1.928,6.45,0.03)},
	["Abre_Armario_SO_PortaE__Latao"] = {V(-13.363,4.25,23.705), V(2.274,5.86,0.35)},
	["Abre_Armario_SO_PortaE__Nogueira"] = {V(-13.256,4.125,23.895), V(2.488,7.01,0.17)},
	["Abre_Armario_SO_PortaE__Talha"] = {V(-13.256,4.125,23.845), V(1.928,6.45,0.03)},
	["Abre_Bau_SL_Tampa__Ferro"] = {V(12.6,13.21,24.55), V(3.46,0.66,2.36)},
	["Abre_Bau_SL_Tampa__Latao"] = {V(12.6,12.855,23.365), V(0.44,0.45,0.07)},
	["Abre_Bau_SL_Tampa__Nogueira"] = {V(12.6,13.19,24.55), V(4.3,0.62,2.3)},
	["Abre_Bau_SO_Tampa__Ferro"] = {V(-12.6,13.21,24.55), V(3.46,0.66,2.36)},
	["Abre_Bau_SO_Tampa__Latao"] = {V(-12.6,12.855,23.365), V(0.44,0.45,0.07)},
	["Abre_Bau_SO_Tampa__Nogueira"] = {V(-12.6,13.19,24.55), V(4.3,0.62,2.3)},
	["Abre_Gaveteiro_L1_Gaveta1__Latao"] = {V(13.11,1.043,10.64), V(0.2,0.175,0.175)},
	["Abre_Gaveteiro_L1_Gaveta1__Nogueira"] = {V(14.19,1.043,10.64), V(1.9,1.127,2.12)},
	["Abre_Gaveteiro_L1_Gaveta1__Talha"] = {V(13.225,1.043,10.64), V(0.03,0.807,1.76)},
	["Abre_Gaveteiro_L1_Gaveta2__Latao"] = {V(13.11,2.29,10.64), V(0.2,0.175,0.175)},
	["Abre_Gaveteiro_L1_Gaveta2__Nogueira"] = {V(14.19,2.29,10.64), V(1.9,1.127,2.12)},
	["Abre_Gaveteiro_L1_Gaveta2__Talha"] = {V(13.225,2.29,10.64), V(0.03,0.807,1.76)},
	["Abre_Gaveteiro_L1_Gaveta3__Latao"] = {V(13.11,3.537,10.64), V(0.2,0.175,0.175)},
	["Abre_Gaveteiro_L1_Gaveta3__Nogueira"] = {V(14.19,3.537,10.64), V(1.9,1.127,2.12)},
	["Abre_Gaveteiro_L1_Gaveta3__Talha"] = {V(13.225,3.537,10.64), V(0.03,0.807,1.76)},
	["Abre_Gaveteiro_L1_Gaveta4__Latao"] = {V(13.11,1.043,8.36), V(0.2,0.175,0.175)},
	["Abre_Gaveteiro_L1_Gaveta4__Nogueira"] = {V(14.19,1.043,8.36), V(1.9,1.127,2.12)},
	["Abre_Gaveteiro_L1_Gaveta4__Talha"] = {V(13.225,1.043,8.36), V(0.03,0.807,1.76)},
	["Abre_Gaveteiro_L1_Gaveta5__Latao"] = {V(13.11,2.29,8.36), V(0.2,0.175,0.175)},
	["Abre_Gaveteiro_L1_Gaveta5__Nogueira"] = {V(14.19,2.29,8.36), V(1.9,1.127,2.12)},
	["Abre_Gaveteiro_L1_Gaveta5__Talha"] = {V(13.225,2.29,8.36), V(0.03,0.807,1.76)},
	["Abre_Gaveteiro_L1_Gaveta6__Latao"] = {V(13.11,3.537,8.36), V(0.2,0.175,0.175)},
	["Abre_Gaveteiro_L1_Gaveta6__Nogueira"] = {V(14.19,3.537,8.36), V(1.9,1.127,2.12)},
	["Abre_Gaveteiro_L1_Gaveta6__Talha"] = {V(13.225,3.537,8.36), V(0.03,0.807,1.76)},
	["Abre_Gaveteiro_L2_Gaveta1__Latao"] = {V(13.11,1.043,-8.36), V(0.2,0.175,0.175)},
	["Abre_Gaveteiro_L2_Gaveta1__Nogueira"] = {V(14.19,1.043,-8.36), V(1.9,1.127,2.12)},
	["Abre_Gaveteiro_L2_Gaveta1__Talha"] = {V(13.225,1.043,-8.36), V(0.03,0.807,1.76)},
	["Abre_Gaveteiro_L2_Gaveta2__Latao"] = {V(13.11,2.29,-8.36), V(0.2,0.175,0.175)},
	["Abre_Gaveteiro_L2_Gaveta2__Nogueira"] = {V(14.19,2.29,-8.36), V(1.9,1.127,2.12)},
	["Abre_Gaveteiro_L2_Gaveta2__Talha"] = {V(13.225,2.29,-8.36), V(0.03,0.807,1.76)},
	["Abre_Gaveteiro_L2_Gaveta3__Latao"] = {V(13.11,3.537,-8.36), V(0.2,0.175,0.175)},
	["Abre_Gaveteiro_L2_Gaveta3__Nogueira"] = {V(14.19,3.537,-8.36), V(1.9,1.127,2.12)},
	["Abre_Gaveteiro_L2_Gaveta3__Talha"] = {V(13.225,3.537,-8.36), V(0.03,0.807,1.76)},
	["Abre_Gaveteiro_L2_Gaveta4__Latao"] = {V(13.11,1.043,-10.64), V(0.2,0.175,0.175)},
	["Abre_Gaveteiro_L2_Gaveta4__Nogueira"] = {V(14.19,1.043,-10.64), V(1.9,1.127,2.12)},
	["Abre_Gaveteiro_L2_Gaveta4__Talha"] = {V(13.225,1.043,-10.64), V(0.03,0.807,1.76)},
	["Abre_Gaveteiro_L2_Gaveta5__Latao"] = {V(13.11,2.29,-10.64), V(0.2,0.175,0.175)},
	["Abre_Gaveteiro_L2_Gaveta5__Nogueira"] = {V(14.19,2.29,-10.64), V(1.9,1.127,2.12)},
	["Abre_Gaveteiro_L2_Gaveta5__Talha"] = {V(13.225,2.29,-10.64), V(0.03,0.807,1.76)},
	["Abre_Gaveteiro_L2_Gaveta6__Latao"] = {V(13.11,3.537,-10.64), V(0.2,0.175,0.175)},
	["Abre_Gaveteiro_L2_Gaveta6__Nogueira"] = {V(14.19,3.537,-10.64), V(1.9,1.127,2.12)},
	["Abre_Gaveteiro_L2_Gaveta6__Talha"] = {V(13.225,3.537,-10.64), V(0.03,0.807,1.76)},
	["Abre_Gaveteiro_O1_Gaveta1__Latao"] = {V(-13.11,1.043,8.36), V(0.2,0.175,0.175)},
	["Abre_Gaveteiro_O1_Gaveta1__Nogueira"] = {V(-14.19,1.043,8.36), V(1.9,1.127,2.12)},
	["Abre_Gaveteiro_O1_Gaveta1__Talha"] = {V(-13.225,1.043,8.36), V(0.03,0.807,1.76)},
	["Abre_Gaveteiro_O1_Gaveta2__Latao"] = {V(-13.11,2.29,8.36), V(0.2,0.175,0.175)},
	["Abre_Gaveteiro_O1_Gaveta2__Nogueira"] = {V(-14.19,2.29,8.36), V(1.9,1.127,2.12)},
	["Abre_Gaveteiro_O1_Gaveta2__Talha"] = {V(-13.225,2.29,8.36), V(0.03,0.807,1.76)},
	["Abre_Gaveteiro_O1_Gaveta3__Latao"] = {V(-13.11,3.537,8.36), V(0.2,0.175,0.175)},
	["Abre_Gaveteiro_O1_Gaveta3__Nogueira"] = {V(-14.19,3.537,8.36), V(1.9,1.127,2.12)},
	["Abre_Gaveteiro_O1_Gaveta3__Talha"] = {V(-13.225,3.537,8.36), V(0.03,0.807,1.76)},
	["Abre_Gaveteiro_O1_Gaveta4__Latao"] = {V(-13.11,1.043,10.64), V(0.2,0.175,0.175)},
	["Abre_Gaveteiro_O1_Gaveta4__Nogueira"] = {V(-14.19,1.043,10.64), V(1.9,1.127,2.12)},
	["Abre_Gaveteiro_O1_Gaveta4__Talha"] = {V(-13.225,1.043,10.64), V(0.03,0.807,1.76)},
	["Abre_Gaveteiro_O1_Gaveta5__Latao"] = {V(-13.11,2.29,10.64), V(0.2,0.175,0.175)},
	["Abre_Gaveteiro_O1_Gaveta5__Nogueira"] = {V(-14.19,2.29,10.64), V(1.9,1.127,2.12)},
	["Abre_Gaveteiro_O1_Gaveta5__Talha"] = {V(-13.225,2.29,10.64), V(0.03,0.807,1.76)},
	["Abre_Gaveteiro_O1_Gaveta6__Latao"] = {V(-13.11,3.537,10.64), V(0.2,0.175,0.175)},
	["Abre_Gaveteiro_O1_Gaveta6__Nogueira"] = {V(-14.19,3.537,10.64), V(1.9,1.127,2.12)},
	["Abre_Gaveteiro_O1_Gaveta6__Talha"] = {V(-13.225,3.537,10.64), V(0.03,0.807,1.76)},
	["Abre_Gaveteiro_O2_Gaveta1__Latao"] = {V(-13.11,1.043,-10.64), V(0.2,0.175,0.175)},
	["Abre_Gaveteiro_O2_Gaveta1__Nogueira"] = {V(-14.19,1.043,-10.64), V(1.9,1.127,2.12)},
	["Abre_Gaveteiro_O2_Gaveta1__Talha"] = {V(-13.225,1.043,-10.64), V(0.03,0.807,1.76)},
	["Abre_Gaveteiro_O2_Gaveta2__Latao"] = {V(-13.11,2.29,-10.64), V(0.2,0.175,0.175)},
	["Abre_Gaveteiro_O2_Gaveta2__Nogueira"] = {V(-14.19,2.29,-10.64), V(1.9,1.127,2.12)},
	["Abre_Gaveteiro_O2_Gaveta2__Talha"] = {V(-13.225,2.29,-10.64), V(0.03,0.807,1.76)},
	["Abre_Gaveteiro_O2_Gaveta3__Latao"] = {V(-13.11,3.537,-10.64), V(0.2,0.175,0.175)},
	["Abre_Gaveteiro_O2_Gaveta3__Nogueira"] = {V(-14.19,3.537,-10.64), V(1.9,1.127,2.12)},
	["Abre_Gaveteiro_O2_Gaveta3__Talha"] = {V(-13.225,3.537,-10.64), V(0.03,0.807,1.76)},
	["Abre_Gaveteiro_O2_Gaveta4__Latao"] = {V(-13.11,1.043,-8.36), V(0.2,0.175,0.175)},
	["Abre_Gaveteiro_O2_Gaveta4__Nogueira"] = {V(-14.19,1.043,-8.36), V(1.9,1.127,2.12)},
	["Abre_Gaveteiro_O2_Gaveta4__Talha"] = {V(-13.225,1.043,-8.36), V(0.03,0.807,1.76)},
	["Abre_Gaveteiro_O2_Gaveta5__Latao"] = {V(-13.11,2.29,-8.36), V(0.2,0.175,0.175)},
	["Abre_Gaveteiro_O2_Gaveta5__Nogueira"] = {V(-14.19,2.29,-8.36), V(1.9,1.127,2.12)},
	["Abre_Gaveteiro_O2_Gaveta5__Talha"] = {V(-13.225,2.29,-8.36), V(0.03,0.807,1.76)},
	["Abre_Gaveteiro_O2_Gaveta6__Latao"] = {V(-13.11,3.537,-8.36), V(0.2,0.175,0.175)},
	["Abre_Gaveteiro_O2_Gaveta6__Nogueira"] = {V(-14.19,3.537,-8.36), V(1.9,1.127,2.12)},
	["Abre_Gaveteiro_O2_Gaveta6__Talha"] = {V(-13.225,3.537,-8.36), V(0.03,0.807,1.76)},
	["Abre_GuardaRoupa_NL_PortaD__Latao"] = {V(10.787,15.45,-23.705), V(2.174,6.26,0.35)},
	["Abre_GuardaRoupa_NL_PortaD__Nogueira"] = {V(10.894,15.325,-23.895), V(2.388,7.41,0.17)},
	["Abre_GuardaRoupa_NL_PortaD__Talha"] = {V(10.894,15.325,-23.845), V(1.828,6.85,0.03)},
	["Abre_GuardaRoupa_NL_PortaE__Latao"] = {V(13.413,15.45,-23.705), V(2.174,6.26,0.35)},
	["Abre_GuardaRoupa_NL_PortaE__Nogueira"] = {V(13.306,15.325,-23.895), V(2.388,7.41,0.17)},
	["Abre_GuardaRoupa_NL_PortaE__Talha"] = {V(13.306,15.325,-23.845), V(1.828,6.85,0.03)},
	["Abre_GuardaRoupa_NO_PortaD__Latao"] = {V(-13.413,15.45,-23.705), V(2.174,6.26,0.35)},
	["Abre_GuardaRoupa_NO_PortaD__Nogueira"] = {V(-13.306,15.325,-23.895), V(2.388,7.41,0.17)},
	["Abre_GuardaRoupa_NO_PortaD__Talha"] = {V(-13.306,15.325,-23.845), V(1.828,6.85,0.03)},
	["Abre_GuardaRoupa_NO_PortaE__Latao"] = {V(-10.787,15.45,-23.705), V(2.174,6.26,0.35)},
	["Abre_GuardaRoupa_NO_PortaE__Nogueira"] = {V(-10.894,15.325,-23.895), V(2.388,7.41,0.17)},
	["Abre_GuardaRoupa_NO_PortaE__Talha"] = {V(-10.894,15.325,-23.845), V(1.828,6.85,0.03)},
	["Abre_Mesa_Expositora_Gaveta1__Latao"] = {V(-1.84,2.32,10.45), V(0.2,0.175,0.175)},
	["Abre_Mesa_Expositora_Gaveta1__Nogueira"] = {V(-1.02,2.325,10.45), V(1.44,0.75,2.8)},
	["Abre_Mesa_Expositora_Gaveta2__Latao"] = {V(-1.84,2.32,13.55), V(0.2,0.175,0.175)},
	["Abre_Mesa_Expositora_Gaveta2__Nogueira"] = {V(-1.02,2.325,13.55), V(1.44,0.75,2.8)},
	["Abre_Mesa_Expositora_Gaveta3__Latao"] = {V(1.84,2.32,10.45), V(0.2,0.175,0.175)},
	["Abre_Mesa_Expositora_Gaveta3__Nogueira"] = {V(1.02,2.325,10.45), V(1.44,0.75,2.8)},
	["Abre_Mesa_Expositora_Gaveta4__Latao"] = {V(1.84,2.32,13.55), V(0.2,0.175,0.175)},
	["Abre_Mesa_Expositora_Gaveta4__Nogueira"] = {V(1.02,2.325,13.55), V(1.44,0.75,2.8)},
	["Abre_Quartinho_Porta__Latao"] = {V(0.95,3,-20.77), V(0.232,0.221,0.24)},
	["Abre_Quartinho_Porta__Nogueira"] = {V(0,3.06,-20.56), V(2.66,6.04,0.12)},
	["Abre_Quartinho_Porta__Talha"] = {V(0,3.05,-20.635), V(2.1,5.3,0.03)},
	["Abre_Relogio_N_Porta__Latao"] = {V(12.3,3.775,-24.94), V(0.248,0.236,0.3)},
	["Abre_Relogio_N_Porta__Nogueira"] = {V(12.8,3.775,-25.18), V(1.6,3.55,0.12)},
	["Abre_Relogio_N_Porta__VidroMel"] = {V(12.8,4.3,-25.11), V(1.1,1.8,0.02)},
	["Arandelas__Chama"] = {V(0,13.01,0), V(29.14,10.54,29.74)},
	["Arandelas__Latao"] = {V(0,11.75,0), V(30.32,11.3,29.904)},
	["Arandelas__Marfim"] = {V(0,12.44,0), V(29.16,10.98,29.76)},
	["Armario_SL__Ebanizada"] = {V(12,4.45,24.96), V(6.12,8.9,2.96)},
	["Armario_SL__Nogueira"] = {V(12,4.9,25), V(5.96,8.9,2.88)},
	["Armario_SL__Talha"] = {V(12,8.69,23.799), V(2,0.42,0.018)},
	["Armario_SO__Ebanizada"] = {V(-12,4.45,24.96), V(6.12,8.9,2.96)},
	["Armario_SO__Nogueira"] = {V(-12,4.9,25), V(5.96,8.9,2.88)},
	["Armario_SO__Talha"] = {V(-12,8.69,23.799), V(2,0.42,0.018)},
	["Balaustrada_L__Ebanizada"] = {V(9.75,13.2,2.25), V(0.8,3,47.1)},
	["Balaustrada_L__Latao"] = {V(9.75,14.94,-3.325), V(0.48,0.48,35.606)},
	["Balaustrada_L__Nogueira"] = {V(9.75,12.775,2.29), V(0.64,3.55,47.02)},
	["Balaustrada_N__Ebanizada"] = {V(0,14.16,-20.75), V(18.8,0.06,0.48)},
	["Balaustrada_N__Nogueira"] = {V(0,12.725,-20.75), V(18.8,3.45,0.4)},
	["Balaustrada_O__Ebanizada"] = {V(-9.75,13.2,2.25), V(0.8,3,47.1)},
	["Balaustrada_O__Latao"] = {V(-9.75,14.94,-3.325), V(0.48,0.48,35.606)},
	["Balaustrada_O__Nogueira"] = {V(-9.75,12.775,2.29), V(0.64,3.55,47.02)},
	["Bancos__Couro"] = {V(0,1.485,12), V(12.6,0.27,4.8)},
	["Bancos__Latao"] = {V(-0.72,1.5,12), V(11.24,0.087,3.9)},
	["Bancos__Nogueira"] = {V(0,0.675,12), V(12.8,1.35,5)},
	["Bau_SL__Ebanizada"] = {V(12.6,11.94,24.55), V(4.36,1.88,2.28)},
	["Bau_SL__Ferro"] = {V(12.6,12.065,24.55), V(4.26,1.63,2.26)},
	["Bau_SL__Nogueira"] = {V(12.6,12.065,24.55), V(4.2,1.63,2.2)},
	["Bau_SO__Ebanizada"] = {V(-12.6,11.94,24.55), V(4.36,1.88,2.28)},
	["Bau_SO__Ferro"] = {V(-12.6,12.065,24.55), V(4.26,1.63,2.26)},
	["Bau_SO__Nogueira"] = {V(-12.6,12.065,24.55), V(4.2,1.63,2.2)},
	["Claraboia__Ebanizada"] = {V(0,23.9,4.5), V(9.8,0.2,22.8)},
	["Claraboia__Ferro"] = {V(0,26.675,4.5), V(8.94,0.25,21.94)},
	["Claraboia__Reboco"] = {V(0,25.4,4.5), V(9.6,2.8,22.6)},
	["Claraboia__Vidro"] = {V(0,26.85,4.5), V(8.8,0.1,21.8)},
	["Colunas__Ebanizada"] = {V(0,4.75,-3.325), V(21.36,9.5,36.71)},
	["Colunas__Nogueira"] = {V(0,4.78,-3.325), V(21.25,8.72,36.6)},
	["Console_N__Ebanizada"] = {V(0,12.51,-25.534), V(5.6,2.32,1.412)},
	["Console_N__Latao"] = {V(0,14.45,-25.64), V(5.4,0.9,0.571)},
	["Console_N__Marfim"] = {V(0,15.165,-25.64), V(4.981,0.53,0.181)},
	["Console_N__Nogueira"] = {V(0,12.5,-25.565), V(6.3,3,1.75)},
	["Console_N__Talha"] = {V(0,13.425,-24.819), V(5.36,0.49,0.018)},
	["Escadaria_Balaustres__Nogueira"] = {V(0,7.492,-10.785), V(6.53,13.412,18.933)},
	["Escadaria__Ebanizada"] = {V(0,7.35,-10.354), V(7.1,14.7,21.591)},
	["Escadaria__La_bordo"] = {V(0,5.543,-10.675), V(3.8,10.985,19.61)},
	["Escadaria__Latao"] = {V(0,7.96,-10.594), V(6.875,14.441,20.763)},
	["Escadaria__Nogueira"] = {V(0,7.238,-10.255), V(6.94,14.625,21.63)},
	["Escadaria__Reboco"] = {V(0,4.912,-11.082), V(6,11.106,19.549)},
	["Escadaria__Talha"] = {V(0,2.6,-12.965), V(6.6,4,15.151)},
	["Escadaria__VidroMel"] = {V(0,6.29,-0.5), V(7.14,1.08,0.819)},
	["Fecho_L__Damasco"] = {V(15.998,4.5,0), V(0.825,9,4.87)},
	["Fecho_L__Ebanizada"] = {V(15.32,1.905,0), V(0.44,3.81,4.87)},
	["Fecho_L__Nogueira"] = {V(15.275,2.15,0), V(0.41,3.62,4.87)},
	["Fecho_L__Talha"] = {V(15.348,2.16,0), V(0.035,2.42,4.49)},
	["Fecho_N__Damasco"] = {V(0,4.5,-26.997), V(4.87,9,0.825)},
	["Fecho_N__Ebanizada"] = {V(0,1.905,-26.32), V(4.87,3.81,0.44)},
	["Fecho_N__Nogueira"] = {V(0,2.15,-26.275), V(4.87,3.62,0.41)},
	["Fecho_N__Talha"] = {V(0,2.16,-26.348), V(4.49,2.42,0.035)},
	["Fecho_O__Damasco"] = {V(-15.998,4.5,0), V(0.825,9,4.87)},
	["Fecho_O__Ebanizada"] = {V(-15.32,1.905,0), V(0.44,3.81,4.87)},
	["Fecho_O__Nogueira"] = {V(-15.275,2.15,0), V(0.41,3.62,4.87)},
	["Fecho_O__Talha"] = {V(-15.348,2.16,0), V(0.035,2.42,4.49)},
	["Fecho_S__Damasco"] = {V(0,4.5,26.997), V(4.87,9,0.825)},
	["Fecho_S__Ebanizada"] = {V(0,1.905,26.32), V(4.87,3.81,0.44)},
	["Fecho_S__Nogueira"] = {V(0,2.15,26.275), V(4.87,3.62,0.41)},
	["Fecho_S__Talha"] = {V(0,2.16,26.348), V(4.49,2.42,0.035)},
	["Gaveteiro_L1__Ebanizada"] = {V(14.25,2.2,9.5), V(2.38,4.4,5.16)},
	["Gaveteiro_L1__Nogueira"] = {V(14.34,2.285,9.5), V(2.2,3.87,4.8)},
	["Gaveteiro_L2__Ebanizada"] = {V(14.25,2.2,-9.5), V(2.38,4.4,5.16)},
	["Gaveteiro_L2__Nogueira"] = {V(14.34,2.285,-9.5), V(2.2,3.87,4.8)},
	["Gaveteiro_O1__Ebanizada"] = {V(-14.25,2.2,9.5), V(2.38,4.4,5.16)},
	["Gaveteiro_O1__Nogueira"] = {V(-14.34,2.285,9.5), V(2.2,3.87,4.8)},
	["Gaveteiro_O2__Ebanizada"] = {V(-14.25,2.2,-9.5), V(2.38,4.4,5.16)},
	["Gaveteiro_O2__Nogueira"] = {V(-14.34,2.285,-9.5), V(2.2,3.87,4.8)},
	["GuardaRoupa_NL__Ebanizada"] = {V(12.1,15.65,-24.96), V(5.92,9.3,2.96)},
	["GuardaRoupa_NL__Nogueira"] = {V(12.1,16.142,-25), V(5.76,9.385,2.88)},
	["GuardaRoupa_NL__Talha"] = {V(12.1,20.09,-23.799), V(2,0.42,0.018)},
	["GuardaRoupa_NO__Ebanizada"] = {V(-12.1,15.65,-24.96), V(5.92,9.3,2.96)},
	["GuardaRoupa_NO__Nogueira"] = {V(-12.1,16.142,-25), V(5.76,9.385,2.88)},
	["GuardaRoupa_NO__Talha"] = {V(-12.1,20.09,-23.799), V(2,0.42,0.018)},
	["Janela_S__Bosque"] = {V(0,16.9,26.46), V(7.2,8.6,0.04)},
	["Janela_S__Calcario"] = {V(0,12.28,26.19), V(8.8,0.6,0.62)},
	["Janela_S__Ebanizada"] = {V(0,17.275,26.044), V(13.6,10.05,0.912)},
	["Janela_S__Ferro"] = {V(0,16.9,26.4), V(7.2,8.6,0.12)},
	["Janela_S__La_bordo"] = {V(0,16.6,25.95), V(12.502,10,0.42)},
	["Janela_S__Talha"] = {V(0,21.95,25.574), V(13,0.6,0.028)},
	["Lustre__Chama"] = {V(0,17.385,8.728), V(6.96,1.59,6.505)},
	["Lustre__Ferro"] = {V(0,20.075,8.5), V(0.16,6.15,0.139)},
	["Lustre__Latao"] = {V(0,15.95,8.5), V(7.28,2.3,7.256)},
	["Lustre__Marfim"] = {V(0,16.84,8.5), V(6.98,1.98,6.98)},
	["Mesa_Expositora__Couro"] = {V(-0.1,3.32,13.85), V(1.4,0.2,1.1)},
	["Mesa_Expositora__Ebanizada"] = {V(0,1.665,12), V(3.64,2.43,7.24)},
	["Mesa_Expositora__Latao"] = {V(0,3.91,12), V(3.32,1.62,6.92)},
	["Mesa_Expositora__Marfim"] = {V(0,3.57,11.6), V(0.8,0.7,0.8)},
	["Mesa_Expositora__Nogueira"] = {V(0,1.55,12), V(3.8,3.1,7.4)},
	["Mesa_Expositora__Papel"] = {V(-0.1,3.32,13.85), V(1.3,0.16,1.02)},
	["Mesa_Expositora__VidroMel"] = {V(0,4.615,12), V(3.12,0.03,6.72)},
	["Mezanino__Ebanizada"] = {V(0,10.385,2.6), V(20.6,1.53,47.8)},
	["Mezanino__Nogueira"] = {V(0,10.25,0), V(31,1.5,53)},
	["Mezanino__Reboco"] = {V(0,10.65,0), V(31,0.5,53)},
	["Mezanino__Talha"] = {V(0,9.97,2.556), V(18.976,0.7,46.088)},
	["Parede_L__Damasco"] = {V(16,12.2,0), V(1,24.4,53)},
	["Parede_L__Ebanizada"] = {V(15.15,12,0), V(0.7,24,53)},
	["Parede_L__Nogueira"] = {V(15.255,12.2,0), V(0.49,23.36,53)},
	["Parede_L__Talha"] = {V(15.415,2.135,0), V(0.05,2.43,52.2)},
	["Parede_N__Damasco"] = {V(0,12.2,-27), V(33,24.4,1)},
	["Parede_N__Ebanizada"] = {V(0,12,-26.15), V(31,24,0.7)},
	["Parede_N__Nogueira"] = {V(0,12.2,-26.255), V(31,23.36,0.49)},
	["Parede_N__Talha"] = {V(0,2.135,-26.415), V(30.2,2.43,0.05)},
	["Parede_O__Damasco"] = {V(-16,12.2,0), V(1,24.4,53)},
	["Parede_O__Ebanizada"] = {V(-15.15,12,0), V(0.7,24,53)},
	["Parede_O__Nogueira"] = {V(-15.255,12.2,0), V(0.49,23.36,53)},
	["Parede_O__Talha"] = {V(-15.415,2.135,0), V(0.05,2.43,52.2)},
	["Parede_S__Damasco"] = {V(0,12.2,27), V(33,24.4,1)},
	["Parede_S__Ebanizada"] = {V(0,12,26.15), V(31,24,0.7)},
	["Parede_S__Nogueira"] = {V(0,12.2,26.25), V(31,23.36,0.5)},
	["Parede_S__Talha"] = {V(0,6.035,26.314), V(30.2,10.23,0.308)},
	["Pedestais__Calcario"] = {V(0,8.25,-0.8), V(27.25,16.5,47.25)},
	["Pilastras__Ebanizada"] = {V(0,11.7,0), V(31,23.4,53)},
	["Pilastras__Nogueira"] = {V(0,11.81,0), V(31,22.38,53)},
	["Piso__Ebanizada"] = {V(0,-0.222,0), V(33,0.276,55)},
	["Piso__Nogueira"] = {V(0,-0.042,0), V(30.984,0.084,53)},
	["Porta_L_A__Ebanizada"] = {V(15.988,4.275,1.23), V(0.737,7.43,2)},
	["Porta_L_A__Latao"] = {V(16,4.25,0.44), V(0.947,0.16,0.26)},
	["Porta_L_A__Nogueira"] = {V(16.01,4.5,1.23), V(0.655,8.94,2.41)},
	["Porta_L_A__Talha"] = {V(16.017,4.275,1.23), V(0.735,7.25,1.82)},
	["Porta_L_B__Ebanizada"] = {V(15.988,4.275,-1.23), V(0.737,7.43,2)},
	["Porta_L_B__Latao"] = {V(16,4.25,-0.44), V(0.947,0.16,0.26)},
	["Porta_L_B__Nogueira"] = {V(16.01,4.5,-1.23), V(0.655,8.94,2.41)},
	["Porta_L_B__Talha"] = {V(16.017,4.275,-1.23), V(0.735,7.25,1.82)},
	["Porta_N_A__Ebanizada"] = {V(1.23,4.275,-26.988), V(2,7.43,0.737)},
	["Porta_N_A__Latao"] = {V(0.44,4.25,-27), V(0.26,0.16,0.947)},
	["Porta_N_A__Nogueira"] = {V(1.23,4.5,-27.01), V(2.41,8.94,0.655)},
	["Porta_N_A__Talha"] = {V(1.23,4.275,-27.017), V(1.82,7.25,0.735)},
	["Porta_N_B__Ebanizada"] = {V(-1.23,4.275,-26.988), V(2,7.43,0.737)},
	["Porta_N_B__Latao"] = {V(-0.44,4.25,-27), V(0.26,0.16,0.947)},
	["Porta_N_B__Nogueira"] = {V(-1.23,4.5,-27.01), V(2.41,8.94,0.655)},
	["Porta_N_B__Talha"] = {V(-1.23,4.275,-27.017), V(1.82,7.25,0.735)},
	["Porta_O_A__Ebanizada"] = {V(-15.988,4.275,-1.23), V(0.737,7.43,2)},
	["Porta_O_A__Latao"] = {V(-16,4.25,-0.44), V(0.947,0.16,0.26)},
	["Porta_O_A__Nogueira"] = {V(-16.01,4.5,-1.23), V(0.655,8.94,2.41)},
	["Porta_O_A__Talha"] = {V(-16.017,4.275,-1.23), V(0.735,7.25,1.82)},
	["Porta_O_B__Ebanizada"] = {V(-15.988,4.275,1.23), V(0.737,7.43,2)},
	["Porta_O_B__Latao"] = {V(-16,4.25,0.44), V(0.947,0.16,0.26)},
	["Porta_O_B__Nogueira"] = {V(-16.01,4.5,1.23), V(0.655,8.94,2.41)},
	["Porta_O_B__Talha"] = {V(-16.017,4.275,1.23), V(0.735,7.25,1.82)},
	["Porta_S_A__Ebanizada"] = {V(-1.23,4.275,26.988), V(2,7.43,0.737)},
	["Porta_S_A__Latao"] = {V(-0.44,4.25,27), V(0.26,0.16,0.947)},
	["Porta_S_A__Nogueira"] = {V(-1.23,4.5,27.01), V(2.41,8.94,0.655)},
	["Porta_S_A__Talha"] = {V(-1.23,4.275,27.017), V(1.82,7.25,0.735)},
	["Porta_S_B__Ebanizada"] = {V(1.23,4.275,26.988), V(2,7.43,0.737)},
	["Porta_S_B__Latao"] = {V(0.44,4.25,27), V(0.26,0.16,0.947)},
	["Porta_S_B__Nogueira"] = {V(1.23,4.5,27.01), V(2.41,8.94,0.655)},
	["Porta_S_B__Talha"] = {V(1.23,4.275,27.017), V(1.82,7.25,0.735)},
	["Quadros__Bosque"] = {V(0,12.8,0), V(30.76,14.8,52.76)},
	["Quadros__Ebanizada"] = {V(0,12.9,0), V(30.92,15.8,52.92)},
	["Quadros__Flores"] = {V(0,13.05,0), V(30.76,14.3,52.76)},
	["Quadros__Latao"] = {V(0,12.9,0), V(30.88,15.64,52.88)},
	["Quadros__Paisagem"] = {V(0,12.9,-1.653), V(30.76,15,49.455)},
	["Relogio_N__Ebanizada"] = {V(12.8,3.75,-25.66), V(2.34,7.5,1.52)},
	["Relogio_N__Latao"] = {V(12.8,5.15,-25.37), V(1.44,4.04,0.82)},
	["Relogio_N__Marfim"] = {V(12.8,6.45,-24.985), V(1.24,1.24,0.03)},
	["Relogio_N__Nogueira"] = {V(12.8,4.195,-25.71), V(2.14,7.589,1.42)},
	["Tapetes__La_bordo"] = {V(0,0.02,9.1), V(13.2,0.04,19)},
	["Teto__Nogueira"] = {V(0,23.575,0), V(31,0.85,53)},
	["Teto__Reboco"] = {V(0,24.2,0), V(33,0.4,55)},
}
local COLISOES = {
	{"COL_Parede_N_1", CF(9.468,12.5,-27,-1,0,0,0,1,0,0,0,-1), V(14.065,25,1)},
	{"COL_Parede_N_2", CF(-9.468,12.5,-27,-1,0,0,0,1,0,0,0,-1), V(14.065,25,1)},
	{"COL_Parede_N_3", CF(0,17,-27,-1,0,0,0,1,0,0,0,-1), V(4.87,16,1)},
	{"COL_Parede_S_1", CF(-9.468,12.5,27,1,0,0,0,1,0,0,0,1), V(14.065,25,1)},
	{"COL_Parede_S_2", CF(9.468,12.5,27,1,0,0,0,1,0,0,0,1), V(14.065,25,1)},
	{"COL_Parede_S_3", CF(0,17,27,1,0,0,0,1,0,0,0,1), V(4.87,16,1)},
	{"COL_Parede_L_1", CF(16,12.5,14.467,0,0,1,0,1,0,-1,0,0), V(24.065,25,1)},
	{"COL_Parede_L_2", CF(16,12.5,-14.467,0,0,1,0,1,0,-1,0,0), V(24.065,25,1)},
	{"COL_Parede_L_3", CF(16,17,0,0,0,1,0,1,0,-1,0,0), V(4.87,16,1)},
	{"COL_Parede_O_1", CF(-16,12.5,-14.467,0,0,-1,0,1,0,1,0,0), V(24.065,25,1)},
	{"COL_Parede_O_2", CF(-16,12.5,14.467,0,0,-1,0,1,0,1,0,0), V(24.065,25,1)},
	{"COL_Parede_O_3", CF(-16,17,0,0,0,-1,0,1,0,1,0,0), V(4.87,16,1)},
	{"COL_Piso", CF(0,-0.5,0,1,0,0,0,1,0,0,0,1), V(33,1,55)},
	{"COL_Teto", CF(0,24.5,0,1,0,0,0,1,0,0,0,1), V(33,1,55)},
	{"COL_Mezanino_O", CF(-12.5,10.7,0,1,0,0,0,1,0,0,0,1), V(6,0.6,53)},
	{"COL_Mezanino_L", CF(12.5,10.7,0,1,0,0,0,1,0,0,0,1), V(6,0.6,53)},
	{"COL_Mezanino_N", CF(0,10.7,-23.5,1,0,0,0,1,0,0,0,1), V(19,0.6,6)},
	{"COL_Coluna", CF(-9.9,4.75,14.25,1,0,0,0,1,0,0,0,1), V(1.3,9.5,1.3)},
	{"COL_Coluna", CF(-9.9,4.75,4.75,1,0,0,0,1,0,0,0,1), V(1.3,9.5,1.3)},
	{"COL_Coluna", CF(-9.9,4.75,-4.75,1,0,0,0,1,0,0,0,1), V(1.3,9.5,1.3)},
	{"COL_Coluna", CF(-9.9,4.75,-14.25,1,0,0,0,1,0,0,0,1), V(1.3,9.5,1.3)},
	{"COL_Coluna", CF(-9.9,4.75,-20.9,1,0,0,0,1,0,0,0,1), V(1.3,9.5,1.3)},
	{"COL_Coluna", CF(9.9,4.75,14.25,1,0,0,0,1,0,0,0,1), V(1.3,9.5,1.3)},
	{"COL_Coluna", CF(9.9,4.75,4.75,1,0,0,0,1,0,0,0,1), V(1.3,9.5,1.3)},
	{"COL_Coluna", CF(9.9,4.75,-4.75,1,0,0,0,1,0,0,0,1), V(1.3,9.5,1.3)},
	{"COL_Coluna", CF(9.9,4.75,-14.25,1,0,0,0,1,0,0,0,1), V(1.3,9.5,1.3)},
	{"COL_Coluna", CF(9.9,4.75,-20.9,1,0,0,0,1,0,0,0,1), V(1.3,9.5,1.3)},
	{"COL_Guarda_L", CF(9.7,13.5,2.8,1,0,0,0,1,0,0,0,1), V(0.5,5,47.4)},
	{"COL_Guarda_O", CF(-9.7,13.5,2.8,1,0,0,0,1,0,0,0,1), V(0.5,5,47.4)},
	{"COL_Guarda_N", CF(-6.4,13.5,-20.7,1,0,0,0,1,0,0,0,1), V(6.5,5,0.5)},
	{"COL_Guarda_N", CF(6.4,13.5,-20.7,1,0,0,0,1,0,0,0,1), V(6.5,5,0.5)},
	{"COL_Escada_Lado", CF(-3.2,7.5,-10.45,1,0,0,0,1,0,0,0,1), V(0.5,15,20.1)},
	{"COL_Escada_Lado", CF(3.2,7.5,-10.45,1,0,0,0,1,0,0,0,1), V(0.5,15,20.1)},
	{"COL_Escada_Rampa", CF(0,5.239,-9.505,1,0,0,0,0.871,-0.491,0,0.491,0.871), V(6,0.6,22.389)},
	{"COL_Escada_Topo", CF(0,10.7,-19.804,1,0,0,0,1,0,0,0,1), V(6,0.6,1.393)},
	{"COL_Quartinho_frente_E", CF(-2.175,5.2,-20.39,1,0,0,0,1,0,0,0,1), V(1.65,10.4,0.22)},
	{"COL_Quartinho_frente_D", CF(2.175,5.2,-20.39,1,0,0,0,1,0,0,0,1), V(1.65,10.4,0.22)},
	{"COL_Quartinho_frente_T", CF(0,8.25,-20.39,1,0,0,0,1,0,0,0,1), V(2.7,4.3,0.22)},
	{"COL_Armario_SO", CF(-12,4.38,25.09,1,0,0,0,1,0,0,0,1), V(5.8,8.76,2.7)},
	{"COL_Armario_SL", CF(12,4.38,25.09,1,0,0,0,1,0,0,0,1), V(5.8,8.76,2.7)},
	{"COL_Gaveteiro_L1", CF(14.25,2.2,9.5,0,0,1,0,1,0,-1,0,0), V(5.16,4.4,2.38)},
	{"COL_Gaveteiro_L2", CF(14.25,2.2,-9.5,0,0,1,0,1,0,-1,0,0), V(5.16,4.4,2.38)},
	{"COL_Gaveteiro_O1", CF(-14.25,2.2,9.5,0,0,-1,0,1,0,1,0,0), V(5.16,4.4,2.38)},
	{"COL_Gaveteiro_O2", CF(-14.25,2.2,-9.5,0,0,-1,0,1,0,1,0,0), V(5.16,4.4,2.38)},
	{"COL_Relogio_N", CF(12.8,4,-25.66,-1,0,0,0,1,0,0,0,-1), V(2.34,8,1.52)},
	{"COL_Pedestal", CF(-12.8,2,-23.6,1,0,0,0,1,0,0,0,1), V(1.7,5.5,1.7)},
	{"COL_Mesa_Expositora", CF(0,2.36,12,1,0,0,0,1,0,0,0,1), V(3.8,4.72,7.4)},
	{"COL_Banco", CF(-5.6,0.81,12,0,0,1,0,1,0,-1,0,0), V(5,1.62,1.6)},
	{"COL_Banco", CF(5.6,0.81,12,0,0,1,0,1,0,-1,0,0), V(5,1.62,1.6)},
	{"COL_Pedestal", CF(-5.6,2,22,1,0,0,0,1,0,0,0,1), V(1.7,5.5,1.7)},
	{"COL_Pedestal", CF(5.6,2,22,1,0,0,0,1,0,0,0,1), V(1.7,5.5,1.7)},
	{"COL_Pedestal", CF(-5.6,2,2.6,1,0,0,0,1,0,0,0,1), V(1.7,5.5,1.7)},
	{"COL_Pedestal", CF(5.6,2,2.6,1,0,0,0,1,0,0,0,1), V(1.7,5.5,1.7)},
	{"COL_GuardaRoupa_NO", CF(-12.1,15.58,-25.09,-1,0,0,0,1,0,0,0,-1), V(5.6,9.16,2.7)},
	{"COL_GuardaRoupa_NL", CF(12.1,15.58,-25.09,-1,0,0,0,1,0,0,0,-1), V(5.6,9.16,2.7)},
	{"COL_Bau_SO", CF(-12.6,12.25,24.55,1,0,0,0,1,0,0,0,1), V(4.4,2.5,2.4)},
	{"COL_Bau_SL", CF(12.6,12.25,24.55,1,0,0,0,1,0,0,0,1), V(4.4,2.5,2.4)},
	{"COL_Console_N", CF(0,12.5,-25.64,-1,0,0,0,1,0,0,0,-1), V(6.3,3,1.9)},
	{"COL_Pedestal", CF(12.8,13,0,1,0,0,0,1,0,0,0,1), V(1.7,5.5,1.7)},
	{"COL_Pedestal", CF(-12.8,13,0,1,0,0,0,1,0,0,0,1), V(1.7,5.5,1.7)},
	{"COL_Claraboia", CF(0,27.4,4.5,1,0,0,0,1,0,0,0,1), V(9.8,1,22.8)},
}
local LUZES = {
	{nome="Lampiao_escada_O", tipo="Point", pos=V(-3.15,6.3,-0.5), dir=nil, cor=C3(255,173,97), brilho=0.7, alcance=13, sombra=false, angulo=0},
	{nome="Lampiao_escada_L", tipo="Point", pos=V(3.15,6.3,-0.5), dir=nil, cor=C3(255,173,97), brilho=0.7, alcance=13, sombra=false, angulo=0},
	{nome="Arandela_terreo_L_S", tipo="Point", pos=V(14.3,7.75,14.25), dir=nil, cor=C3(255,158,76), brilho=0.6, alcance=12, sombra=false, angulo=0},
	{nome="Arandela_terreo_L_N", tipo="Point", pos=V(14.3,7.75,-14.25), dir=nil, cor=C3(255,158,76), brilho=0.6, alcance=12, sombra=false, angulo=0},
	{nome="Arandela_cima_L_S", tipo="Point", pos=V(14.3,17.95,4.75), dir=nil, cor=C3(255,158,76), brilho=0.6, alcance=12, sombra=false, angulo=0},
	{nome="Arandela_terreo_O_S", tipo="Point", pos=V(-14.3,7.75,14.25), dir=nil, cor=C3(255,158,76), brilho=0.6, alcance=12, sombra=false, angulo=0},
	{nome="Arandela_cima_O_S", tipo="Point", pos=V(-14.3,17.95,4.75), dir=nil, cor=C3(255,158,76), brilho=0.6, alcance=12, sombra=false, angulo=0},
	{nome="Arandela_cima_O_N", tipo="Point", pos=V(-14.3,17.95,-14.25), dir=nil, cor=C3(255,158,76), brilho=0.6, alcance=12, sombra=false, angulo=0},
	{nome="Luar_claraboia", tipo="Spot", pos=V(0,26.4,4.5), dir=V(0,-1,0), cor=C3(140,173,255), brilho=0.9, alcance=34, sombra=true, angulo=70},
	{nome="Luar_janela", tipo="Spot", pos=V(0,17.6,25.3), dir=V(0,-0.66,-0.75), cor=C3(128,163,255), brilho=0.8, alcance=36, sombra=true, angulo=60},
	{nome="Lustre", tipo="Point", pos=V(0,16.2,8.5), dir=nil, cor=C3(255,163,82), brilho=1.4, alcance=36, sombra=true, angulo=0},
	{nome="Preenchimento_norte", tipo="Point", pos=V(0,8,-23.5), dir=nil, cor=C3(255,178,115), brilho=0.35, alcance=10, sombra=false, angulo=0},
}
local PONTOS = {
	{"Totem_Armario_SO", V(-12,0.6,25.24), "totem", "Armario_SO"},
	{"Totem_Armario_SL", V(12,0.6,25.24), "totem", "Armario_SL"},
	{"Dado_Gaveteiro_L1_1", V(14.19,0.54,10.64), "dado", "Gaveteiro_L1"},
	{"Dado_Gaveteiro_L1_2", V(14.19,1.787,10.64), "dado", "Gaveteiro_L1"},
	{"Dado_Gaveteiro_L1_3", V(14.19,3.033,10.64), "dado", "Gaveteiro_L1"},
	{"Dado_Gaveteiro_L1_4", V(14.19,0.54,8.36), "dado", "Gaveteiro_L1"},
	{"Dado_Gaveteiro_L1_5", V(14.19,1.787,8.36), "dado", "Gaveteiro_L1"},
	{"Dado_Gaveteiro_L1_6", V(14.19,3.033,8.36), "dado", "Gaveteiro_L1"},
	{"Dado_Gaveteiro_L2_1", V(14.19,0.54,-8.36), "dado", "Gaveteiro_L2"},
	{"Dado_Gaveteiro_L2_2", V(14.19,1.787,-8.36), "dado", "Gaveteiro_L2"},
	{"Dado_Gaveteiro_L2_3", V(14.19,3.033,-8.36), "dado", "Gaveteiro_L2"},
	{"Dado_Gaveteiro_L2_4", V(14.19,0.54,-10.64), "dado", "Gaveteiro_L2"},
	{"Dado_Gaveteiro_L2_5", V(14.19,1.787,-10.64), "dado", "Gaveteiro_L2"},
	{"Dado_Gaveteiro_L2_6", V(14.19,3.033,-10.64), "dado", "Gaveteiro_L2"},
	{"Dado_Gaveteiro_O1_1", V(-14.19,0.54,8.36), "dado", "Gaveteiro_O1"},
	{"Dado_Gaveteiro_O1_2", V(-14.19,1.787,8.36), "dado", "Gaveteiro_O1"},
	{"Dado_Gaveteiro_O1_3", V(-14.19,3.033,8.36), "dado", "Gaveteiro_O1"},
	{"Dado_Gaveteiro_O1_4", V(-14.19,0.54,10.64), "dado", "Gaveteiro_O1"},
	{"Dado_Gaveteiro_O1_5", V(-14.19,1.787,10.64), "dado", "Gaveteiro_O1"},
	{"Dado_Gaveteiro_O1_6", V(-14.19,3.033,10.64), "dado", "Gaveteiro_O1"},
	{"Dado_Gaveteiro_O2_1", V(-14.19,0.54,-10.64), "dado", "Gaveteiro_O2"},
	{"Dado_Gaveteiro_O2_2", V(-14.19,1.787,-10.64), "dado", "Gaveteiro_O2"},
	{"Dado_Gaveteiro_O2_3", V(-14.19,3.033,-10.64), "dado", "Gaveteiro_O2"},
	{"Dado_Gaveteiro_O2_4", V(-14.19,0.54,-8.36), "dado", "Gaveteiro_O2"},
	{"Dado_Gaveteiro_O2_5", V(-14.19,1.787,-8.36), "dado", "Gaveteiro_O2"},
	{"Dado_Gaveteiro_O2_6", V(-14.19,3.033,-8.36), "dado", "Gaveteiro_O2"},
	{"Dado_Relogio_N", V(12.45,2,-25.77), "dado", "Relogio_N"},
	{"Dado_Mesa_Expositora_1", V(-1,2.01,10.45), "dado", "Mesa_Expositora"},
	{"Dado_Mesa_Expositora_2", V(-1,2.01,13.55), "dado", "Mesa_Expositora"},
	{"Dado_Mesa_Expositora_3", V(1,2.01,10.45), "dado", "Mesa_Expositora"},
	{"Dado_Mesa_Expositora_4", V(1,2.01,13.55), "dado", "Mesa_Expositora"},
	{"Totem_GuardaRoupa_NO", V(-12.1,11.6,-25.24), "totem", "GuardaRoupa_NO"},
	{"Totem_GuardaRoupa_NL", V(12.1,11.6,-25.24), "totem", "GuardaRoupa_NL"},
	{"Dado_Bau_SO", V(-12.6,11.3,24.55), "dado", "Bau_SO"},
	{"Dado_Bau_SL", V(12.6,11.3,24.55), "dado", "Bau_SL"},
	{"Totem_Console_N", V(0,14,-25.25), "totem", nil},
	{"Totem_Quartinho", V(0,0,-17.4), "totem", "Quartinho"},
	{"Totem_Canto_NO", V(-12.8,0,-20.6), "totem", nil},
	{"Encaixe_N", V(0,0,-27.5), "encaixe", nil},
	{"Encaixe_S", V(0,0,27.5), "encaixe", nil},
	{"Encaixe_L", V(16.5,0,0), "encaixe", nil},
	{"Encaixe_O", V(-16.5,0,0), "encaixe", nil},
}
local MOVEIS = {
	{id="Armario_SO", rotulo="Armario de colecao", interior={CF(-12,4.125,25.14,1,0,0,0,1,0,0,0,1), V(5,7.01,2.3)}, partes={
		{grupo="Abre_Armario_SO_PortaE", tipo="giro", pivo=V(-14.5,0,23.86), eixo=V(0,1,0), angulo=100},
		{grupo="Abre_Armario_SO_PortaD", tipo="giro", pivo=V(-9.5,0,23.86), eixo=V(0,1,0), angulo=-100},
	}},
	{id="Armario_SL", rotulo="Armario de colecao", interior={CF(12,4.125,25.14,1,0,0,0,1,0,0,0,1), V(5,7.01,2.3)}, partes={
		{grupo="Abre_Armario_SL_PortaE", tipo="giro", pivo=V(9.5,0,23.86), eixo=V(0,1,0), angulo=100},
		{grupo="Abre_Armario_SL_PortaD", tipo="giro", pivo=V(14.5,0,23.86), eixo=V(0,1,0), angulo=-100},
	}},
	{id="Gaveteiro_L1", rotulo="Gaveteiro", interior={CF(14.34,2.29,9.5,0,0,1,0,1,0,-1,0,0), V(4.4,3.74,1.9)}, partes={
		{grupo="Abre_Gaveteiro_L1_Gaveta1", tipo="gaveta", curso=V(-1.296,0,0), leva={V(14.19,1.043,10.64), V(1.92,1.027,1.7)}},
		{grupo="Abre_Gaveteiro_L1_Gaveta2", tipo="gaveta", curso=V(-1.296,0,0), leva={V(14.19,2.29,10.64), V(1.92,1.027,1.7)}},
		{grupo="Abre_Gaveteiro_L1_Gaveta3", tipo="gaveta", curso=V(-1.296,0,0), leva={V(14.19,3.537,10.64), V(1.92,1.027,1.7)}},
		{grupo="Abre_Gaveteiro_L1_Gaveta4", tipo="gaveta", curso=V(-1.296,0,0), leva={V(14.19,1.043,8.36), V(1.92,1.027,1.7)}},
		{grupo="Abre_Gaveteiro_L1_Gaveta5", tipo="gaveta", curso=V(-1.296,0,0), leva={V(14.19,2.29,8.36), V(1.92,1.027,1.7)}},
		{grupo="Abre_Gaveteiro_L1_Gaveta6", tipo="gaveta", curso=V(-1.296,0,0), leva={V(14.19,3.537,8.36), V(1.92,1.027,1.7)}},
	}},
	{id="Gaveteiro_L2", rotulo="Gaveteiro", interior={CF(14.34,2.29,-9.5,0,0,1,0,1,0,-1,0,0), V(4.4,3.74,1.9)}, partes={
		{grupo="Abre_Gaveteiro_L2_Gaveta1", tipo="gaveta", curso=V(-1.296,0,0), leva={V(14.19,1.043,-8.36), V(1.92,1.027,1.7)}},
		{grupo="Abre_Gaveteiro_L2_Gaveta2", tipo="gaveta", curso=V(-1.296,0,0), leva={V(14.19,2.29,-8.36), V(1.92,1.027,1.7)}},
		{grupo="Abre_Gaveteiro_L2_Gaveta3", tipo="gaveta", curso=V(-1.296,0,0), leva={V(14.19,3.537,-8.36), V(1.92,1.027,1.7)}},
		{grupo="Abre_Gaveteiro_L2_Gaveta4", tipo="gaveta", curso=V(-1.296,0,0), leva={V(14.19,1.043,-10.64), V(1.92,1.027,1.7)}},
		{grupo="Abre_Gaveteiro_L2_Gaveta5", tipo="gaveta", curso=V(-1.296,0,0), leva={V(14.19,2.29,-10.64), V(1.92,1.027,1.7)}},
		{grupo="Abre_Gaveteiro_L2_Gaveta6", tipo="gaveta", curso=V(-1.296,0,0), leva={V(14.19,3.537,-10.64), V(1.92,1.027,1.7)}},
	}},
	{id="Gaveteiro_O1", rotulo="Gaveteiro", interior={CF(-14.34,2.29,9.5,0,0,-1,0,1,0,1,0,0), V(4.4,3.74,1.9)}, partes={
		{grupo="Abre_Gaveteiro_O1_Gaveta1", tipo="gaveta", curso=V(1.296,0,0), leva={V(-14.19,1.043,8.36), V(1.92,1.027,1.7)}},
		{grupo="Abre_Gaveteiro_O1_Gaveta2", tipo="gaveta", curso=V(1.296,0,0), leva={V(-14.19,2.29,8.36), V(1.92,1.027,1.7)}},
		{grupo="Abre_Gaveteiro_O1_Gaveta3", tipo="gaveta", curso=V(1.296,0,0), leva={V(-14.19,3.537,8.36), V(1.92,1.027,1.7)}},
		{grupo="Abre_Gaveteiro_O1_Gaveta4", tipo="gaveta", curso=V(1.296,0,0), leva={V(-14.19,1.043,10.64), V(1.92,1.027,1.7)}},
		{grupo="Abre_Gaveteiro_O1_Gaveta5", tipo="gaveta", curso=V(1.296,0,0), leva={V(-14.19,2.29,10.64), V(1.92,1.027,1.7)}},
		{grupo="Abre_Gaveteiro_O1_Gaveta6", tipo="gaveta", curso=V(1.296,0,0), leva={V(-14.19,3.537,10.64), V(1.92,1.027,1.7)}},
	}},
	{id="Gaveteiro_O2", rotulo="Gaveteiro", interior={CF(-14.34,2.29,-9.5,0,0,-1,0,1,0,1,0,0), V(4.4,3.74,1.9)}, partes={
		{grupo="Abre_Gaveteiro_O2_Gaveta1", tipo="gaveta", curso=V(1.296,0,0), leva={V(-14.19,1.043,-10.64), V(1.92,1.027,1.7)}},
		{grupo="Abre_Gaveteiro_O2_Gaveta2", tipo="gaveta", curso=V(1.296,0,0), leva={V(-14.19,2.29,-10.64), V(1.92,1.027,1.7)}},
		{grupo="Abre_Gaveteiro_O2_Gaveta3", tipo="gaveta", curso=V(1.296,0,0), leva={V(-14.19,3.537,-10.64), V(1.92,1.027,1.7)}},
		{grupo="Abre_Gaveteiro_O2_Gaveta4", tipo="gaveta", curso=V(1.296,0,0), leva={V(-14.19,1.043,-8.36), V(1.92,1.027,1.7)}},
		{grupo="Abre_Gaveteiro_O2_Gaveta5", tipo="gaveta", curso=V(1.296,0,0), leva={V(-14.19,2.29,-8.36), V(1.92,1.027,1.7)}},
		{grupo="Abre_Gaveteiro_O2_Gaveta6", tipo="gaveta", curso=V(1.296,0,0), leva={V(-14.19,3.537,-8.36), V(1.92,1.027,1.7)}},
	}},
	{id="Relogio_N", rotulo="Relogio", interior={CF(12.8,3.7,-25.77,-1,0,0,0,1,0,0,0,-1), V(1.5,3.4,1)}, partes={
		{grupo="Abre_Relogio_N_Porta", tipo="giro", pivo=V(13.6,0,-25.12), eixo=V(0,1,0), angulo=100},
	}},
	{id="Mesa_Expositora", rotulo="Mesa expositora", interior={CF(0,2.35,12,1,0,0,0,1,0,0,0,1), V(3.4,0.8,7)}, partes={
		{grupo="Abre_Mesa_Expositora_Gaveta1", tipo="gaveta", curso=V(-1.15,0,0), leva={V(-0.95,2.3,10.45), V(2.6,0.5,1.3)}},
		{grupo="Abre_Mesa_Expositora_Gaveta2", tipo="gaveta", curso=V(-1.15,0,0), leva={V(-0.95,2.3,13.55), V(2.6,0.5,1.3)}},
		{grupo="Abre_Mesa_Expositora_Gaveta3", tipo="gaveta", curso=V(1.15,0,0), leva={V(0.95,2.3,10.45), V(2.6,0.5,1.3)}},
		{grupo="Abre_Mesa_Expositora_Gaveta4", tipo="gaveta", curso=V(1.15,0,0), leva={V(0.95,2.3,13.55), V(2.6,0.5,1.3)}},
	}},
	{id="GuardaRoupa_NO", rotulo="Guarda-roupa", interior={CF(-12.1,15.325,-25.14,-1,0,0,0,1,0,0,0,-1), V(4.8,7.41,2.3)}, partes={
		{grupo="Abre_GuardaRoupa_NO_PortaE", tipo="giro", pivo=V(-9.7,11,-23.86), eixo=V(0,1,0), angulo=100},
		{grupo="Abre_GuardaRoupa_NO_PortaD", tipo="giro", pivo=V(-14.5,11,-23.86), eixo=V(0,1,0), angulo=-100},
	}},
	{id="GuardaRoupa_NL", rotulo="Guarda-roupa", interior={CF(12.1,15.325,-25.14,-1,0,0,0,1,0,0,0,-1), V(4.8,7.41,2.3)}, partes={
		{grupo="Abre_GuardaRoupa_NL_PortaE", tipo="giro", pivo=V(14.5,11,-23.86), eixo=V(0,1,0), angulo=100},
		{grupo="Abre_GuardaRoupa_NL_PortaD", tipo="giro", pivo=V(9.7,11,-23.86), eixo=V(0,1,0), angulo=-100},
	}},
	{id="Bau_SO", rotulo="Bau", interior={CF(-12.6,12.09,24.55,1,0,0,0,1,0,0,0,1), V(3.8,1.48,1.8)}, partes={
		{grupo="Abre_Bau_SO_Tampa", tipo="giro", pivo=V(-12.6,12.88,25.65), eixo=V(1,0,0), angulo=95},
	}},
	{id="Bau_SL", rotulo="Bau", interior={CF(12.6,12.09,24.55,1,0,0,0,1,0,0,0,1), V(3.8,1.48,1.8)}, partes={
		{grupo="Abre_Bau_SL_Tampa", tipo="giro", pivo=V(12.6,12.88,25.65), eixo=V(1,0,0), angulo=95},
	}},
	{id="Quartinho", rotulo="Porta debaixo da escada", interior={CF(0,3,-16.6,1,0,0,0,1,0,0,0,1), V(5.6,6,7.4)}, partes={
		{grupo="Abre_Quartinho_Porta", tipo="giro", pivo=V(-1.33,0,-20.62), eixo=V(0,1,0), angulo=100, colide={V(0,3.06,-20.56), V(2.66,6.04,0.12)}},
	}},
}

local VAOS = {   -- vaos de porta (centro e tamanho no espaco da sala)
	N = { V(0, 4.5, -27), V(4.87, 9, 1) },
	S = { V(0, 4.5, 27), V(4.87, 9, 1) },
	L = { V(16, 4.5, 0), V(1, 9, 4.87) },
	O = { V(-16, 4.5, 0), V(1, 9, 4.87) },
}

-- ================================================================== utilitarios
local avisos, linhas = {}, {}
local function info(...) table.insert(linhas, table.concat({ ... }, " ")) end
local function aviso(...) table.insert(avisos, table.concat({ ... }, " ")) end

local recording
pcall(function() recording = ChangeHistoryService:TryBeginRecording("Invokyr instalar Galeria") end)

local BASE = CFrame.new(CONFIG.ORIGEM) * CFrame.Angles(0, (CONFIG.GIRO % 4) * math.pi / 2, 0)

local function pasta(pai, nome, classe)
	local f = pai:FindFirstChild(nome)
	if not f then
		f = Instance.new(classe or "Folder"); f.Name = nome; f.Parent = pai
	end
	return f
end

local backup = pasta(ServerStorage, "Invokyr_Backup")
local raiz = workspace:FindFirstChild("Invokyr")
if not raiz then error("[Invokyr] Nao achei Workspace > Invokyr. Este place nao e o do jogo?") end
local salas = pasta(pasta(raiz, "Mansao"), "Salas")
local sala = pasta(salas, "Galeria", "Model")
local visual = pasta(sala, "Visual")
local guardadas = pasta(pasta(ServerStorage, "Invokyr_Salas"), "Galeria_Variantes")

-- ================================================================== 1. achar as pecas
local function ehDaGaleria(m)
	return m:FindFirstChild("Escadaria__Nogueira", true) ~= nil and m:FindFirstChild("Mezanino__Nogueira", true) ~= nil
end
local importado
for _, m in ipairs(workspace:GetChildren()) do
	if m:IsA("Model") and m ~= raiz and ehDaGaleria(m) then importado = m end
end

-- pecas ja instaladas antes (rodar de novo nao duplica)
local instaladas = {}
for _, lugar in ipairs({ visual, sala:FindFirstChild("Moveis"), guardadas }) do
	if lugar then
		for _, p in ipairs(lugar:GetDescendants()) do
			if p:IsA("MeshPart") then instaladas[p.Name] = p end
		end
	end
end

if importado then
	local antigas = 0
	for _ in pairs(instaladas) do antigas += 1 end
	if antigas > 0 then
		-- importou de novo: a versao anterior vai inteira para o Backup
		local bk = Instance.new("Folder")
		bk.Name = "Galeria_anterior_" .. os.date("%Y%m%d_%H%M%S")
		bk.Parent = backup
		for _, p in pairs(instaladas) do p.Parent = bk end
		info("Versao anterior das pecas guardada em ServerStorage > Invokyr_Backup > " .. bk.Name)
		instaladas = {}
	end
	for _, p in ipairs(importado:GetDescendants()) do
		if p:IsA("MeshPart") then
			p.Parent = visual
			instaladas[p.Name] = p
		end
	end
	importado.Name = "Galeria_importacao_vazia"
	importado.Parent = backup
	info("Modelo importado encontrado e desmontado.")
end

local faltam = {}
for nome in pairs(PECAS) do
	if not instaladas[nome] then table.insert(faltam, nome) end
end
if #faltam > 0 then
	table.sort(faltam)
	aviso(#faltam .. " pecas nao encontradas (ex.: " .. faltam[1] .. "). Importou o Galeria.glb?")
end
local sobrando = 0
for nome, p in pairs(instaladas) do
	if not PECAS[nome] then sobrando += 1 end
end
if sobrando > 0 then aviso(sobrando .. " pecas com nome desconhecido ficaram em Visual sem mexer.") end

-- ================================================================== 2. posicionar
local tamanhoErrado = 0
for nome, d in pairs(PECAS) do
	local p = instaladas[nome]
	if p then
		local esperado = d[2]
		local s = p.Size
		if math.abs(s.X - esperado.X) > 0.05 + esperado.X * 0.02 or math.abs(s.Y - esperado.Y) > 0.05 + esperado.Y * 0.02
			or math.abs(s.Z - esperado.Z) > 0.05 + esperado.Z * 0.02 then
			tamanhoErrado += 1
			if tamanhoErrado == 1 then
				aviso(("%s veio com tamanho %.2f x %.2f x %.2f (esperado %.2f x %.2f x %.2f). O importador mudou a escala?")
					:format(nome, s.X, s.Y, s.Z, esperado.X, esperado.Y, esperado.Z))
			end
		end
		p.CFrame = BASE * CFrame.new(d[1])
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Locked = CONFIG.TRAVAR
		p.Parent = visual
		local mat = string.match(nome, "__(.+)$")
		local brilha = (mat == "Chama") or (nome == "Claraboia__Vidro") or (nome == "Escadaria__VidroMel")
		if brilha then
			-- o Roblox nao faz textura brilhar: chama e vidro iluminado viram Neon
			local sa = p:FindFirstChildOfClass("SurfaceAppearance")
			if sa then sa.Parent = guardadas end
			p.TextureID = ""
			p.Material = Enum.Material.Neon
			p.CastShadow = false
			if mat == "Chama" then p.Color = C3(255, 150, 60)
			elseif mat == "VidroMel" then p.Color = C3(205, 140, 80); p.Transparency = 0.15
			else p.Color = C3(32, 44, 70) end
		end
	end
end
if tamanhoErrado > 1 then aviso(tamanhoErrado .. " pecas com tamanho diferente do esperado no total.") end

-- ================================================================== 3. portas e fechos
for lado, modo in pairs(CONFIG.PORTAS) do
	for nome, p in pairs(instaladas) do
		local ePorta = string.sub(nome, 1, 8) == "Porta_" .. lado .. "_"
		local eFecho = string.sub(nome, 1, 7) == "Fecho_" .. lado
		if ePorta then p.Parent = (modo == "porta") and visual or guardadas end
		if eFecho then p.Parent = (modo == "fecho") and visual or guardadas end
	end
end

-- ================================================================== 4. colisao
local velha = sala:FindFirstChild("Colisao")
if velha then velha:Destroy() end
local col = pasta(sala, "Colisao")
local function invisivel(nome, cf, tam, pai)
	local p = Instance.new("Part")
	p.Name = nome
	p.Size = tam
	p.CFrame = cf
	p.Anchored = true; p.CanCollide = true; p.CanQuery = true; p.CanTouch = false
	p.CastShadow = false; p.Locked = CONFIG.TRAVAR
	p.Material = Enum.Material.SmoothPlastic; p.Color = C3(255, 60, 60)
	p.Transparency = CONFIG.MOSTRAR_COLISOES and 0.6 or 1
	p.Parent = pai
	return p
end
for _, c in ipairs(COLISOES) do invisivel(c[1], BASE * c[2], c[3], col) end
for lado, v in pairs(VAOS) do invisivel("COL_Vao_" .. lado, BASE * CFrame.new(v[1]), v[2], col) end

-- ================================================================== 5. luzes
local velhaL = sala:FindFirstChild("Luzes")
if velhaL then velhaL:Destroy() end
local luzes = pasta(sala, "Luzes")
for _, l in ipairs(LUZES) do
	local a = Instance.new("Part")
	a.Name = l.nome; a.Size = Vector3.new(0.2, 0.2, 0.2)
	a.Anchored = true; a.CanCollide = false; a.CanQuery = false; a.CanTouch = false; a.CastShadow = false
	a.Transparency = 1; a.Locked = CONFIG.TRAVAR
	local pos = BASE * l.pos
	if l.tipo == "Spot" then
		a.CFrame = CFrame.lookAt(pos, pos + BASE:VectorToWorldSpace(l.dir))
		local s = Instance.new("SpotLight")
		s.Face = Enum.NormalId.Front; s.Angle = l.angulo
		s.Color = l.cor; s.Brightness = l.brilho; s.Range = l.alcance; s.Shadows = l.sombra
		s.Parent = a
	else
		a.CFrame = CFrame.new(pos)
		local s = Instance.new("PointLight")
		s.Color = l.cor; s.Brightness = l.brilho; s.Range = l.alcance; s.Shadows = l.sombra
		s.Parent = a
	end
	a.Parent = luzes
end

-- ================================================================== 6. esconderijos e encaixes
local velhaE = sala:FindFirstChild("Esconderijos")
if velhaE then velhaE:Destroy() end
local velhaX = sala:FindFirstChild("Encaixes")
if velhaX then velhaX:Destroy() end
local esc = pasta(sala, "Esconderijos")
local enc = pasta(sala, "Encaixes")
local ancora = Instance.new("Part")
ancora.Name = "AncoraEncaixes"; ancora.Size = Vector3.new(1, 1, 1); ancora.CFrame = BASE
ancora.Anchored = true; ancora.CanCollide = false; ancora.CanQuery = false; ancora.CanTouch = false
ancora.Transparency = 1; ancora.Locked = true; ancora.Parent = enc
local nTotem, nDado = 0, 0
for _, pt in ipairs(PONTOS) do
	local nome, pos, tipo, movel = pt[1], pt[2], pt[3], pt[4]
	if tipo == "encaixe" then
		local a = Instance.new("Attachment")
		a.Name = nome
		a.Position = pos
		local fora = Vector3.new(pos.X, 0, pos.Z).Unit
		a:SetAttribute("Fora", BASE:VectorToWorldSpace(fora))
		a:SetAttribute("Livre", true)
		a.Parent = ancora
	else
		local p = Instance.new("Part")
		p.Name = nome
		p.Size = (tipo == "totem") and Vector3.new(2.2, 0.1, 2.2) or Vector3.new(1, 0.1, 1)
		p.CFrame = BASE * CFrame.new(pos)
		p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
		p.Material = Enum.Material.Neon
		p.Color = (tipo == "totem") and C3(120, 255, 170) or C3(110, 170, 255)
		p.Transparency = CONFIG.MOSTRAR_ESCONDERIJOS and 0.4 or 1
		p.Locked = CONFIG.TRAVAR
		p:SetAttribute("TipoEsconderijo", tipo)
		if movel then p:SetAttribute("Movel", movel) end
		local tag = (tipo == "totem") and "Invokyr_Esconderijo" or "Invokyr_EsconderijoDado"
		if CONFIG.ESCONDERIJOS_ATIVOS then CollectionService:AddTag(p, tag) else p:SetAttribute("TagPendente", tag) end
		p.Parent = esc
		if tipo == "totem" then nTotem += 1 else nDado += 1 end
	end
end

-- ================================================================== 7. moveis que abrem
local moveis = pasta(sala, "Moveis")
local nPartes = 0
for _, m in ipairs(MOVEIS) do
	local mm = pasta(moveis, "Movel_" .. m.id, "Model")
	mm:SetAttribute("Rotulo", m.rotulo)
	mm:SetAttribute("InteriorCF", BASE * m.interior[1])
	mm:SetAttribute("InteriorTam", m.interior[2])
	for _, pa in ipairs(m.partes) do
		local g = pasta(mm, pa.grupo, "Model")
		-- tira o que o script criou da vez anterior (prompt e colisao que se movem)
		for _, x in ipairs(g:GetChildren()) do
			if x:IsA("Part") and (x.Name == "Puxador" or x.Name == "ColisaoMovel") then x:Destroy() end
		end
		local qtd = 0
		for nome, p in pairs(instaladas) do
			if string.sub(nome, 1, #pa.grupo + 2) == pa.grupo .. "__" then
				p.Parent = g
				p.CanQuery = true   -- a folha fechada bloqueia o clique em coisas atras dela
				qtd += 1
			end
		end
		if qtd == 0 then aviso("Movel " .. m.id .. ": nenhuma peca do grupo " .. pa.grupo) end
		g:SetAttribute("Tipo", pa.tipo)
		g:SetAttribute("Movel", m.id)
		g:SetAttribute("Aberto", false)
		if pa.tipo == "giro" then
			g:SetAttribute("Pivo", BASE * pa.pivo)
			g:SetAttribute("Eixo", BASE:VectorToWorldSpace(pa.eixo).Unit)
			g:SetAttribute("Angulo", pa.angulo)
		else
			g:SetAttribute("Curso", BASE:VectorToWorldSpace(pa.curso))
			g:SetAttribute("LevaCF", BASE * CFrame.new(pa.leva[1]))
			g:SetAttribute("LevaTam", pa.leva[2])
		end
		if pa.colide then
			invisivel("ColisaoMovel", BASE * CFrame.new(pa.colide[1]), pa.colide[2], g)
		end
		-- puxador invisivel com o prompt, no meio da peca
		local cf, tam = g:GetBoundingBox()
		local px = Instance.new("Part")
		px.Name = "Puxador"; px.Size = Vector3.new(0.4, 0.4, 0.4); px.CFrame = cf
		px.Anchored = true; px.CanCollide = false; px.CanQuery = false; px.CanTouch = false; px.CastShadow = false
		px.Transparency = 1; px.Locked = CONFIG.TRAVAR
		local pr = Instance.new("ProximityPrompt")
		pr.Name = "Abrir"
		pr.ActionText = "Abrir"
		pr.ObjectText = m.rotulo
		pr.KeyboardKeyCode = Enum.KeyCode.E
		pr.HoldDuration = 0
		pr.MaxActivationDistance = 7
		pr.RequiresLineOfSight = false
		pr.Parent = px
		px.Parent = g
		CollectionService:AddTag(g, "Invokyr_Abre")
		nPartes += 1
	end
end

-- ================================================================== 8. script que abre e fecha
local FONTE = [==[
-- INVOKYR - Moveis que abrem (instalado pelo Script 15. Nao edite aqui: rode o Script 15 de novo.)
-- Vale para qualquer sala: cuida de todo Model com a tag Invokyr_Abre.
-- Tambem impede pegar totem/dado que esta dentro de um movel fechado.
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local DURACAO = 0.45
local estado = {}

local params = OverlapParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
local mansao = workspace:FindFirstChild("Invokyr") and workspace.Invokyr:FindFirstChild("Mansao")
params.FilterDescendantsInstances = { mansao }

local function transformar(e, t)
	if e.tipo == "giro" then
		return CFrame.new(e.pivo) * CFrame.fromAxisAngle(e.eixo, math.rad(e.angulo) * t) * CFrame.new(-e.pivo)
	end
	return CFrame.new(e.curso * t)
end

local function aplicar(e, t)
	e.t = t
	local T = transformar(e, t)
	for p, cf0 in pairs(e.base) do
		if p.Parent then p.CFrame = T * cf0 end
	end
	for p, cf0 in pairs(e.carregados) do
		if p.Parent and p.Anchored then p.CFrame = T * cf0 end
	end
end

local function alternar(g)
	local e = estado[g]
	if not e or e.ocupado then return end
	e.ocupado = true
	local alvo = e.aberto and 0 or 1
	e.carregados = {}
	if e.tipo == "gaveta" and e.levaCF then
		-- o que esta dentro da gaveta (totem, dado) sai e volta junto com ela
		local T = transformar(e, e.t)
		for _, p in ipairs(workspace:GetPartBoundsInBox(T * e.levaCF, e.levaTam, params)) do
			if p.Anchored and not e.base[p] then e.carregados[p] = T:Inverse() * p.CFrame end
		end
	end
	local v = Instance.new("NumberValue")
	v.Value = e.t
	local con = v.Changed:Connect(function(x) aplicar(e, x) end)
	local tw = TweenService:Create(v, TweenInfo.new(DURACAO, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = alvo })
	tw:Play()
	tw.Completed:Wait()
	con:Disconnect()
	v:Destroy()
	aplicar(e, alvo)
	e.aberto = (alvo == 1)
	g:SetAttribute("Aberto", e.aberto)
	if e.prompt then e.prompt.ActionText = e.aberto and "Fechar" or "Abrir" end
	e.ocupado = false
end

local function preparar(g)
	if estado[g] or not g:IsDescendantOf(workspace) then return end
	local e = { aberto = false, t = 0, base = {}, carregados = {} }
	for _, p in ipairs(g:GetDescendants()) do
		if p:IsA("BasePart") then e.base[p] = p.CFrame end
	end
	e.tipo = g:GetAttribute("Tipo")
	e.pivo = g:GetAttribute("Pivo") or Vector3.zero
	e.eixo = g:GetAttribute("Eixo") or Vector3.yAxis
	e.angulo = g:GetAttribute("Angulo") or 0
	e.curso = g:GetAttribute("Curso") or Vector3.zero
	e.levaCF = g:GetAttribute("LevaCF")
	e.levaTam = g:GetAttribute("LevaTam")
	e.movel = g.Parent
	e.prompt = g:FindFirstChild("Abrir", true)
	estado[g] = e
	if e.prompt then
		e.prompt.ActionText = "Abrir"
		e.prompt.Triggered:Connect(function() task.spawn(alternar, g) end)
	end
end

for _, g in ipairs(CollectionService:GetTagged("Invokyr_Abre")) do preparar(g) end
CollectionService:GetInstanceAddedSignal("Invokyr_Abre"):Connect(preparar)

-- prompts de outros sistemas (totem, dado) que podem estar dentro de um movel
local deFora = {}
local function considerar(x)
	if x:IsA("ProximityPrompt") and x.Name ~= "Abrir" then deFora[x] = true end
end
for _, x in ipairs(workspace:GetDescendants()) do considerar(x) end
workspace.DescendantAdded:Connect(considerar)
workspace.DescendantRemoving:Connect(function(x) deFora[x] = nil end)

local function dentro(cf, tam, pos)
	local l = cf:PointToObjectSpace(pos)
	return math.abs(l.X) <= tam.X / 2 and math.abs(l.Y) <= tam.Y / 2 and math.abs(l.Z) <= tam.Z / 2
end

while true do
	task.wait(0.25)
	-- regioes trancadas: interior de movel com todas as portas fechadas, e gaveta fechada
	local trancadas = {}
	local portasDoMovel = {}
	for g, e in pairs(estado) do
		if e.tipo == "giro" and e.movel then
			local s = portasDoMovel[e.movel] or { fechadas = true }
			if e.aberto or e.ocupado then s.fechadas = false end
			portasDoMovel[e.movel] = s
		elseif e.tipo == "gaveta" and e.levaCF and not e.aberto and not e.ocupado then
			table.insert(trancadas, { e.levaCF, e.levaTam })
		end
	end
	for m, s in pairs(portasDoMovel) do
		local cf, tam = m:GetAttribute("InteriorCF"), m:GetAttribute("InteriorTam")
		if s.fechadas and cf and tam then table.insert(trancadas, { cf, tam }) end
	end
	for prompt in pairs(deFora) do
		local pai = prompt.Parent
		if pai and pai:IsA("BasePart") then
			local preso = false
			for _, r in ipairs(trancadas) do
				if dentro(r[1], r[2], pai.Position) then preso = true break end
			end
			if preso and prompt.Enabled then
				prompt.Enabled = false
				prompt:SetAttribute("TrancadoPorMovel", true)
			elseif not preso and prompt:GetAttribute("TrancadoPorMovel") then
				prompt.Enabled = true
				prompt:SetAttribute("TrancadoPorMovel", nil)
			end
		end
	end
end
]==]
local sc = ServerScriptService:FindFirstChild("Invokyr_Moveis")
if not sc then
	sc = Instance.new("Script"); sc.Name = "Invokyr_Moveis"; sc.Parent = ServerScriptService
end
sc.Source = FONTE
sc.Disabled = false

-- ================================================================== conferencia
sala.WorldPivot = BASE
local nVis = 0
for _, p in ipairs(sala:GetDescendants()) do
	if p:IsA("MeshPart") then nVis += 1 end
end
info(("Galeria em %s (giro %d) | pecas visuais: %d de %d"):format(tostring(CONFIG.ORIGEM), CONFIG.GIRO % 4, nVis, 277))
info(("Colisoes: %d | luzes: %d | moveis que abrem: %d partes"):format(#col:GetChildren(), #luzes:GetChildren(), nPartes))
info(("Esconderijos: %d de totem, %d de dado | %s"):format(nTotem, nDado,
	CONFIG.ESCONDERIJOS_ATIVOS and "ATIVOS (o Script 09 ja sorteia totens aqui)" or "desligados (ESCONDERIJOS_ATIVOS = false)"))
info("Portas: N=" .. CONFIG.PORTAS.N .. " S=" .. CONFIG.PORTAS.S .. " L=" .. CONFIG.PORTAS.L .. " O=" .. CONFIG.PORTAS.O)

pcall(function()
	workspace.CurrentCamera.CFrame = CFrame.lookAt((BASE * CFrame.new(0, 5, 24)).Position, (BASE * CFrame.new(0, 6, -10)).Position)
end)
if recording then pcall(function() ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit) end) end
print("========== INVOKYR 15: GALERIA ==========")
for _, l in ipairs(linhas) do print("  " .. l) end
if #avisos == 0 then print("  Sem avisos.") else for _, a in ipairs(avisos) do warn("  AVISO: " .. a) end end
print("Para andar na sala: deixe a camera dentro dela e use Test > Play Here (Jogar aqui).")
