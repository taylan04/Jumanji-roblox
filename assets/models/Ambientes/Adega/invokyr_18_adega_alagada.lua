--[[
INVOKYR - Script 18: Instalar a ADEGA ALAGADA (sala de desafio, 4 x 6 celulas)
==============================================================================
  1. Importe o AdegaAlagada.glb (Home > Import 3D). Ele ja fica selecionado no fim da importacao.
  2. Rode este script na BARRA DE COMANDOS (View > Command Bar), com o jogo PARADO.

O que faz (pode rodar de novo sem duplicar nada):
  - Monta a sala "AdegaAlagada" em ServerStorage > Invokyr_Salas (a peca que o gerador vai usar)
    e uma copia para testar, "Previa_AdegaAlagada", em Workspace > Invokyr > Mansao > Salas.
  - As 91 pecas sao conferidas uma a uma contra as medidas do Blender.
  - A sala ENTRA NO CHAO: a porta fica no nivel do corredor e o porao alagado 7 studs abaixo.
    (atributo Base = -8: o gerador do mapa nao pode por nada embaixo dela)
  - Uma porta so (lado sul), no padrao da casa, com o ConfigurarPortas.
  - Agua marrom na altura da cintura: dentro dela o jogador anda mais devagar e, com a camera
    debaixo d'agua, a tela fica marrom e embacada (LocalScript Invokyr_Agua).
  - Escura como o Banheiro (atributos Escuridao e Exposicao).
  - Gaveteiros velhos com 6 gavetas que abrem (dados) e o bau velho no balcao alto do fundo,
    onde o totem fica DEITADO. Ao balcao so se chega pelos caixotes e barris do canto leste.
  - Ponto de nascimento do jacare: Monstros > Monstro_Jacare.
  - Atualiza Invokyr_Moveis, Invokyr_Escuridao e ensina o Invokyr_Movimento a andar mais devagar
    na agua (a versao antiga dele vai para o backup).
  - Nada e apagado: a versao anterior e a importacao vao para ServerStorage > Invokyr_Backup.
]]

local CONFIG = {
	-- a previa fica 8 studs acima do chao do Workspace, senao o porao entra no Baseplate
	PREVIA = Vector3.new(400, 8.6, -220),
	PREVIA_PORTAS = { S = 100 },
	MOSTRAR_COLISOES = false,
	MOSTRAR_ESCONDERIJOS = false,
	-- true = o Script 09 tambem esconde totens na previa (bom para testar o totem deitado no bau)
	PREVIA_COM_ESCONDERIJOS = false,
}

-- ================================================================== guarda
local RunService = game:GetService("RunService")
if RunService:IsRunning() then
	error("[Invokyr] Pare o jogo (Stop) antes de rodar o Script 18. Em Play nada do que ele monta fica salvo.")
end
local Selection = game:GetService("Selection")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local V, CF, C3 = Vector3.new, CFrame.new, Color3.fromRGB

-- ================================================================== dados (gerados do Blender)
local CELULAS = {4, 6}
local PECAS = {
	["Abobadas__Tijolo"] = {V(0,8.85,0), V(42,9.7,64)},
	["Abre_Bau_Tampa__Ferrugem"] = {V(16.35,4.789,-29.5), V(4.7,0.803,3)},
	["Abre_Bau_Tampa__Latao"] = {V(16.35,4.225,-27.95), V(0.6,0.55,0.08)},
	["Abre_Bau_Tampa__MadeiraPodre"] = {V(16.35,4.765,-29.5), V(5.4,0.77,3)},
	["Abre_G1_Gaveta1__Ferrugem"] = {V(-17,0.955,30.05), V(2.011,0.211,0.18)},
	["Abre_G1_Gaveta1__MadeiraPodre"] = {V(-17,0.955,30.915), V(3.34,0.89,1.55)},
	["Abre_G1_Gaveta3__Ferrugem"] = {V(-17,2.94,30.05), V(2.011,0.211,0.18)},
	["Abre_G1_Gaveta3__MadeiraPodre"] = {V(-17,2.94,30.915), V(3.34,0.84,1.55)},
	["Abre_G2_Gaveta4__Ferrugem"] = {V(19.05,-2.755,5), V(0.18,0.211,1.911)},
	["Abre_G2_Gaveta4__MadeiraPodre"] = {V(19.915,-2.755,5), V(1.55,0.89,3.14)},
	["Abre_G2_Gaveta5__Ferrugem"] = {V(19.05,-1.725,5), V(0.18,0.211,1.911)},
	["Abre_G2_Gaveta5__MadeiraPodre"] = {V(19.915,-1.725,5), V(1.55,0.89,3.14)},
	["Abre_G3_Gaveta2__Ferrugem"] = {V(16.399,1.96,30.054), V(2.008,0.211,0.276)},
	["Abre_G3_Gaveta2__MadeiraPodre"] = {V(16.411,1.96,30.915), V(3.344,0.84,1.716)},
	["Abre_G3_Gaveta4__Ferrugem"] = {V(16.399,3.895,30.054), V(2.008,0.211,0.276)},
	["Abre_G3_Gaveta4__MadeiraPodre"] = {V(16.411,3.895,30.915), V(3.344,0.79,1.716)},
	["Adega_A__MadeiraPodre"] = {V(-20.24,-1.91,15), V(1.4,10.18,14.4)},
	["Adega_B__MadeiraPodre"] = {V(-18.691,-2.568,-8), V(2.811,9.263,13.4)},
	["Adega_C__MadeiraPodre"] = {V(-13.25,-1.91,-31.24), V(13.9,10.18,1.4)},
	["Agua__Agua"] = {V(0,-4.315,-3), V(42,0.03,58)},
	["Andaime__MadeiraPodre"] = {V(16,-2.8,-17.491), V(3.311,8.4,3.219)},
	["Arcadas__Calcario"] = {V(0,1.725,-3), V(22.76,5.65,59.1)},
	["Arcadas__Tijolo"] = {V(0,6.5,-3), V(22.6,15.2,58)},
	["Balcao__Calcario"] = {V(16.1,-2.5,-28.575), V(9.8,9,6.85)},
	["Balcao__Tijolo"] = {V(16.15,-2.8,-28.75), V(9.7,8.4,6.5)},
	["Barris__Ferrugem"] = {V(18,-4.4,16.6), V(4.284,3.718,12.462)},
	["Barris__Latao"] = {V(14.95,-5.4,16.6), V(0.6,0.24,0.24)},
	["Barris__MadeiraPodre"] = {V(18,-4.75,16.6), V(5.4,4.5,12.542)},
	["Bau__Ferrugem"] = {V(16.347,3.2,-29.5), V(5.776,2.4,3.08)},
	["Bau__Latao"] = {V(16.35,3.825,-27.94), V(0.44,0.35,0.1)},
	["Bau__MadeiraPodre"] = {V(16.35,3.2,-29.5), V(5.4,2.4,3)},
	["Boiando__Ferrugem"] = {V(-5.256,-4.65,-6.662), V(23.728,2.476,37.149)},
	["Boiando__MadeiraPodre"] = {V(-0.567,-4.65,-0.989), V(37.295,2.5,48.892)},
	["Boiando__VidroMel"] = {V(2.34,-4.261,6.011), V(19.167,0.334,10.652)},
	["Boiando__VidroVerde"] = {V(-1.998,-4.296,-6.087), V(33.759,0.497,37.539)},
	["Caixotes__Ferrugem"] = {V(17.5,-3.2,-12.6), V(2.88,5.956,2.837)},
	["Caixotes__MadeiraPodre"] = {V(16.805,-2.2,-15.043), V(4.474,9.6,17.311)},
	["Escada__Calcario"] = {V(-5.5,-2.475,20.166), V(6.863,9.05,11.732)},
	["Fecho_S__Damasco"] = {V(-5.5,4.5,32.497), V(4.87,9,0.825)},
	["Fecho_S__Ebanizada"] = {V(-5.5,1.905,31.82), V(4.87,3.81,0.44)},
	["Fecho_S__Nogueira"] = {V(-5.5,2.15,31.775), V(4.87,3.62,0.41)},
	["Fecho_S__Talha"] = {V(-5.5,2.16,31.847), V(4.49,2.42,0.035)},
	["Fios__Limo"] = {V(-0.525,6.531,-2.98), V(39.043,13.182,53.669)},
	["Garrafas_A__VidroMel"] = {V(-20.315,-1.1,14.965), V(1.05,6.604,13.289)},
	["Garrafas_A__VidroVerde"] = {V(-20.315,-1.1,14.965), V(1.05,6.604,13.289)},
	["Garrafas_B__VidroMel"] = {V(-18.649,-1.755,-8.035), V(1.891,5.583,12.289)},
	["Garrafas_B__VidroVerde"] = {V(-18.649,-1.755,-8.035), V(1.891,5.583,12.289)},
	["Garrafas_C__VidroMel"] = {V(-13.215,-1.1,-31.315), V(12.789,6.604,1.05)},
	["Garrafas_C__VidroVerde"] = {V(-13.215,-1.1,-31.315), V(12.789,6.604,1.05)},
	["Gaveteiro_G1__Ebanizada"] = {V(-17,2.915,31.835), V(3.4,2.81,0.03)},
	["Gaveteiro_G1__Ferrugem"] = {V(-17.54,3.895,29.838), V(0.209,0.211,0.184)},
	["Gaveteiro_G1__MadeiraPodre"] = {V(-15.672,2.184,29.565), V(6.495,4.752,4.79)},
	["Gaveteiro_G2__Ebanizada"] = {V(20.835,-5.38,5), V(0.03,2.08,3.2)},
	["Gaveteiro_G2__Ferrugem"] = {V(18.939,-4.313,5.25), V(0.402,1.266,0.71)},
	["Gaveteiro_G2__MadeiraPodre"] = {V(19.878,-4.005,4.923), V(2.164,5.99,3.795)},
	["Gaveteiro_G3__Ebanizada"] = {V(16.495,2.94,31.835), V(3.395,0.9,0.206)},
	["Gaveteiro_G3__Ferrugem"] = {V(16.124,1.947,29.961), V(0.761,2.196,0.368)},
	["Gaveteiro_G3__MadeiraPodre"] = {V(16.528,2.28,30.971), V(4.088,4.56,2.177)},
	["Grade__Calcario"] = {V(0,13.5,-3), V(3.4,0.2,3.4)},
	["Grade__Ebanizada"] = {V(0,13.79,-3), V(2.6,0.42,2.6)},
	["Grade__Ferrugem"] = {V(0,13.54,-3), V(2.7,0.16,2.7)},
	["Grades__Ferrugem"] = {V(0.045,1.241,0.425), V(41.61,3.939,51.59)},
	["Lanterna__Ferrugem"] = {V(-1.1,7.076,31.28), V(0.68,1.552,1.44)},
	["Lanterna__VidroMel"] = {V(-1.1,6.8,30.9), V(0.54,0.8,0.54)},
	["Limo__Limo"] = {V(0,-4.068,-2.99), V(42,5.864,58.02)},
	["Nervuras__Calcario"] = {V(0,8.85,-3), V(42,9.7,37.2)},
	["Parede_L__Calcario"] = {V(20.88,-5.275,0), V(0.24,3.45,64)},
	["Parede_L__Tijolo"] = {V(21.5,3.55,0), V(1,21.9,64)},
	["Parede_N__Calcario"] = {V(0,-5.275,-31.88), V(42,3.45,0.24)},
	["Parede_N__Tijolo"] = {V(0,3.55,-32.5), V(44,21.9,1)},
	["Parede_O__Calcario"] = {V(-20.88,-5.275,0), V(0.24,3.45,64)},
	["Parede_O__Tijolo"] = {V(-21.5,3.55,0), V(1,21.9,64)},
	["Parede_S__Calcario"] = {V(-5.5,4.975,31.775), V(6.67,9.95,0.45)},
	["Parede_S__Tijolo"] = {V(0,3.55,32.5), V(44,21.9,1)},
	["Patamar__Calcario"] = {V(0,-3.5,28.875), V(42,7,6.25)},
	["Pilares__Calcario"] = {V(0,-4.05,-3), V(23.3,5.9,38.3)},
	["Piso__PedraMolhada"] = {V(0,-7.2,-3), V(42,0.4,58)},
	["Porta_S_A__Ebanizada"] = {V(-6.73,4.275,32.488), V(2,7.43,0.737)},
	["Porta_S_A__Latao"] = {V(-5.94,4.25,32.5), V(0.26,0.16,0.947)},
	["Porta_S_A__Nogueira"] = {V(-6.73,4.5,32.51), V(2.41,8.94,0.655)},
	["Porta_S_A__Talha"] = {V(-6.73,4.275,32.518), V(1.82,7.25,0.735)},
	["Porta_S_B__Ebanizada"] = {V(-4.27,4.275,32.488), V(2,7.43,0.737)},
	["Porta_S_B__Latao"] = {V(-5.06,4.25,32.5), V(0.26,0.16,0.947)},
	["Porta_S_B__Nogueira"] = {V(-4.27,4.5,32.51), V(2.41,8.94,0.655)},
	["Porta_S_B__Talha"] = {V(-4.27,4.275,32.518), V(1.82,7.25,0.735)},
	["Tocha__Chama"] = {V(-20,2.47,0), V(0.32,0.34,0.32)},
	["Tocha__Ferrugem"] = {V(-20.688,1.618,0), V(0.625,0.735,0.5)},
	["Tocha__MadeiraPodre"] = {V(-20.141,1.644,0), V(0.574,1.328,0.36)},
	["Velas__Chama"] = {V(2.11,4.485,-0.07), V(36.56,1.77,62.36)},
	["Velas__Ferrugem"] = {V(2.1,3.35,-0.071), V(36.9,2.7,62.723)},
	["Velas__Marfim"] = {V(2.105,4.13,-0.065), V(36.61,1.86,62.41)},
}
local PORTAS = {
	S = {ponto=V(-5.5,0,33), fora=V(0,0,1)},
}
local DOBRADICAS = {
	["Porta_S_A"] = V(-7.955,0,32.51),
	["Porta_S_B"] = V(-3.045,0,32.51),
}
local COLISOES = {
	{"COL_Parede_N", CF(0,3.55,-32.5,-1,0,0,0,1,0,0,0,-1), V(44,22.1,1)},
	{"COL_Parede_S_1", CF(-14.968,3.55,32.5,1,0,0,0,1,0,0,0,1), V(14.065,22.1,1)},
	{"COL_Parede_S_2", CF(9.468,3.55,32.5,1,0,0,0,1,0,0,0,1), V(25.065,22.1,1)},
	{"COL_Parede_S_3", CF(-5.5,11.8,32.5,1,0,0,0,1,0,0,0,1), V(4.87,5.6,1)},
	{"COL_Parede_L", CF(21.5,3.55,0,0,0,1,0,1,0,-1,0,0), V(64,22.1,1)},
	{"COL_Parede_O", CF(-21.5,3.55,0,0,0,-1,0,1,0,1,0,0), V(64,22.1,1)},
	{"COL_Piso", CF(0,-7.5,-3,1,0,0,0,1,0,0,0,1), V(42,1,58)},
	{"COL_Teto", CF(0,14.6,0,1,0,0,0,1,0,0,0,1), V(44,1,66)},
	{"COL_Arcada_-1", CF(-10.5,8.3,-3,1,0,0,0,1,0,0,0,1), V(1.6,11.6,58)},
	{"COL_Arranque_-1_-15", CF(-10.5,0.5,15,1,0,0,0,1,0,0,0,1), V(1.8,4,3.4)},
	{"COL_Arranque_-1_-3", CF(-10.5,0.5,3,1,0,0,0,1,0,0,0,1), V(1.8,4,3.4)},
	{"COL_Arranque_-1_9", CF(-10.5,0.5,-9,1,0,0,0,1,0,0,0,1), V(1.8,4,3.4)},
	{"COL_Arranque_-1_21", CF(-10.5,0.5,-21,1,0,0,0,1,0,0,0,1), V(1.8,4,3.4)},
	{"COL_Arcada_1", CF(10.5,8.3,-3,1,0,0,0,1,0,0,0,1), V(1.6,11.6,58)},
	{"COL_Arranque_1_-15", CF(10.5,0.5,15,1,0,0,0,1,0,0,0,1), V(1.8,4,3.4)},
	{"COL_Arranque_1_-3", CF(10.5,0.5,3,1,0,0,0,1,0,0,0,1), V(1.8,4,3.4)},
	{"COL_Arranque_1_9", CF(10.5,0.5,-9,1,0,0,0,1,0,0,0,1), V(1.8,4,3.4)},
	{"COL_Arranque_1_21", CF(10.5,0.5,-21,1,0,0,0,1,0,0,0,1), V(1.8,4,3.4)},
	{"COL_Pilar_-1_-15", CF(-10.5,-4.05,15,1,0,0,0,1,0,0,0,1), V(2,5.9,2)},
	{"COL_Pilar_-1_-3", CF(-10.5,-4.05,3,1,0,0,0,1,0,0,0,1), V(2,5.9,2)},
	{"COL_Pilar_-1_9", CF(-10.5,-4.05,-9,1,0,0,0,1,0,0,0,1), V(2,5.9,2)},
	{"COL_Pilar_-1_21", CF(-10.5,-4.05,-21,1,0,0,0,1,0,0,0,1), V(2,5.9,2)},
	{"COL_Pilar_1_-15", CF(10.5,-4.05,15,1,0,0,0,1,0,0,0,1), V(2,5.9,2)},
	{"COL_Pilar_1_-3", CF(10.5,-4.05,3,1,0,0,0,1,0,0,0,1), V(2,5.9,2)},
	{"COL_Pilar_1_9", CF(10.5,-4.05,-9,1,0,0,0,1,0,0,0,1), V(2,5.9,2)},
	{"COL_Pilar_1_21", CF(10.5,-4.05,-21,1,0,0,0,1,0,0,0,1), V(2,5.9,2)},
	{"COL_Teto_Nave", CF(0,12,26,1,0,0,0,1,0,0,0,1), V(19.4,4.2,12)},
	{"COL_Teto_NaveL", CF(8.2,10,26,1,0,0,0,1,0,0,0,1), V(3,8,12)},
	{"COL_Teto_NaveO", CF(-8.2,10,26,1,0,0,0,1,0,0,0,1), V(3,8,12)},
	{"COL_Teto_Nave_-1", CF(-16.15,10.8,26,1,0,0,0,1,0,0,0,1), V(9.7,6.6,12)},
	{"COL_Teto_Canto_-1", CF(-20,10.05,26,1,0,0,0,1,0,0,0,1), V(2,8.1,12)},
	{"COL_Teto_Nave_1", CF(16.15,10.8,26,1,0,0,0,1,0,0,0,1), V(9.7,6.6,12)},
	{"COL_Teto_Canto_1", CF(20,10.05,26,1,0,0,0,1,0,0,0,1), V(2,8.1,12)},
	{"COL_Patamar", CF(0,-3.5,29,1,0,0,0,1,0,0,0,1), V(42,7,6)},
	{"COL_Degrau_1", CF(-5.5,-3.889,25.35,1,0,0,0,1,0,0,0,1), V(5.4,6.222,1.3)},
	{"COL_Degrau_2", CF(-5.5,-4.278,24.05,1,0,0,0,1,0,0,0,1), V(5.4,5.444,1.3)},
	{"COL_Degrau_3", CF(-5.5,-4.667,22.75,1,0,0,0,1,0,0,0,1), V(5.4,4.667,1.3)},
	{"COL_Degrau_4", CF(-5.5,-5.056,21.45,1,0,0,0,1,0,0,0,1), V(5.4,3.889,1.3)},
	{"COL_Degrau_5", CF(-5.5,-5.444,20.15,1,0,0,0,1,0,0,0,1), V(5.4,3.111,1.3)},
	{"COL_Degrau_6", CF(-5.5,-5.833,18.85,1,0,0,0,1,0,0,0,1), V(5.4,2.333,1.3)},
	{"COL_Degrau_7", CF(-5.5,-6.222,17.55,1,0,0,0,1,0,0,0,1), V(5.4,1.556,1.3)},
	{"COL_Degrau_8", CF(-5.5,-6.611,16.25,1,0,0,0,1,0,0,0,1), V(5.4,0.778,1.3)},
	{"COL_Degrau_9", CF(-5.5,-7,14.95,1,0,0,0,1,0,0,0,1), V(5.4,0,1.3)},
	{"COL_Parapeito_-8", CF(-8.5,-2.85,20.15,1,0,0,0,0.858,0.513,0,-0.513,0.858), V(0.6,1.4,13.634)},
	{"COL_Parapeito_-2", CF(-2.5,-2.85,20.15,1,0,0,0,0.858,0.513,0,-0.513,0.858), V(0.6,1.4,13.634)},
	{"COL_Grade_-20_-26", CF(-14.8,0.65,26.15,1,0,0,0,1,0,0,0,1), V(11.8,1.3,0.25)},
	{"COL_Grade_-2_-26", CF(0.95,0.65,26.15,1,0,0,0,1,0,0,0,1), V(6.1,1.3,0.25)},
	{"COL_Grade_8_-26", CF(14.6,0.65,26.15,1,0,0,0,1,0,0,0,1), V(12.2,1.3,0.25)},
	{"COL_Barril_0", CF(18,-4.75,21,1,0,0,0,1,0,0,0,1), V(5.4,4.5,3.6)},
	{"COL_Barril_1", CF(18,-4.75,16.6,1,0,0,0,1,0,0,0,1), V(5.4,4.5,3.6)},
	{"COL_Barril_2", CF(18,-4.75,12.2,1,0,0,0,1,0,0,0,1), V(5.4,4.5,3.6)},
	{"COL_Boiando_0", CF(-4.5,-4.65,-4,0.825,0,0.565,0,1,0,-0.565,0,0.825), V(3.4,2.3,2.3)},
	{"COL_Boiando_1", CF(2.5,-4.65,-19,-0.589,0,0.808,0,1,0,-0.808,0,-0.589), V(3.4,2.3,2.3)},
	{"COL_Boiando_2", CF(-15.5,-4.65,-23.5,0.454,0,0.891,0,1,0,-0.891,0,0.454), V(3.4,2.3,2.3)},
	{"COL_Boiando_3", CF(5,-4.65,10.5,-0.971,0,0.239,0,1,0,-0.239,0,-0.971), V(3.4,2.3,2.3)},
	{"COL_Adega_A", CF(-20.24,-1.9,15,0,0,-1,0,1,0,1,0,0), V(14.4,10.2,1.4)},
	{"COL_Adega_B", CF(-18.689,-2.566,-8,0,0.156,-0.988,0,0.988,0.156,1,0,0), V(13.4,9.2,1.4)},
	{"COL_Adega_C", CF(-13.25,-1.9,-31.24,-1,0,0,0,1,0,0,0,-1), V(13.9,10.2,1.4)},
	{"COL_Gaveteiro_G1", CF(-17,2.28,31.04,1,0,0,0,1,0,0,0,1), V(3.85,4.56,1.9)},
	{"COL_Gaveteiro_G3", CF(16.453,2.28,31.041,0.999,0,0.052,0,1,0,-0.052,0,0.999), V(3.85,4.56,1.9)},
	{"COL_Gaveteiro_G2", CF(20.04,-4.005,5,0,0,1,0,1,0,-1,0,0), V(3.65,5.99,1.9)},
	{"COL_P1", CF(17.5,-5,-8,0.996,0,0.09,0,1,0,-0.09,0,0.996), V(2.8,4,2.8)},
	{"COL_P2", CF(17.5,-3.2,-12.6,1,0,0,0,1,0,0,0,1), V(2.4,7.6,2.4)},
	{"COL_P3", CF(16,-2.8,-17.5,1,0,0,0,1,0,0,0,1), V(3.2,8.4,3.2)},
	{"COL_P4", CF(16.2,-2.2,-22,1,0,0,0,1,0,0,0,1), V(2.9,9.6,2.9)},
	{"COL_Balcao", CF(16.15,-2.5,-28.575,1,0,0,0,1,0,0,0,1), V(9.7,9,6.85)},
	{"COL_GradeBalcao_11", CF(12.95,2.6,-25.3,1,0,0,0,1,0,0,0,1), V(2.9,1.2,0.25)},
	{"COL_GradeBalcao_17", CF(19.35,2.6,-25.3,1,0,0,0,1,0,0,0,1), V(2.9,1.2,0.25)},
	{"COL_Bau", CF(16.35,3.2,-29.5,1,0,0,0,1,0,0,0,1), V(5.4,2.4,3)},
}
local LUZES = {
	{nome="Velas_do_bau", tipo="Point", pos=V(12.7,3.9,-30.4), dir=nil, cor=C3(255,158,82), brilho=0.6, alcance=13, sombra=true, angulo=0},
	{nome="Lanterna_entrada", tipo="Point", pos=V(-1.1,6.8,30.9), dir=nil, cor=C3(255,163,87), brilho=0.55, alcance=15, sombra=true, angulo=0},
	{nome="Vela_gaveteiro", tipo="Point", pos=V(-16.1,5.46,30.64), dir=nil, cor=C3(255,153,76), brilho=0.4, alcance=9, sombra=true, angulo=0},
	{nome="Tocha_oeste", tipo="Point", pos=V(-19.65,2.6,0), dir=nil, cor=C3(255,140,64), brilho=0.5, alcance=13, sombra=true, angulo=0},
	{nome="Luar_da_grade", tipo="Spot", pos=V(0,13.2,-3), dir=V(0,-1,-0.08), cor=C3(153,178,219), brilho=1, alcance=24, sombra=true, angulo=38},
	{nome="Reflexo_da_agua", tipo="Point", pos=V(0,-1.8,-4), dir=nil, cor=C3(140,153,97), brilho=0.12, alcance=26, sombra=false, angulo=0},
}
local PONTOS = {
	{nome="Dado_G1_1", pos=V(-17,0.57,30.915), tipo="dado", movel="G1"},
	{nome="Dado_G1_2", pos=V(-17,2.58,30.915), tipo="dado", movel="G1"},
	{nome="Dado_G3_1", pos=V(16.446,1.6,30.916), tipo="dado", movel="G3"},
	{nome="Dado_G3_2", pos=V(16.446,3.56,30.916), tipo="dado", movel="G3"},
	{nome="Dado_G2_1", pos=V(19.915,-3.14,5), tipo="dado", movel="G2"},
	{nome="Dado_G2_2", pos=V(19.915,-2.11,5), tipo="dado", movel="G2"},
	{nome="Totem_Bau", pos=V(16.35,2.22,-29.5), tipo="totem", movel="Bau", deitado=true, giro=90},
}
local AGUA = {nivel=-4.3, fundo=-7, cf=CF(0,-5.65,-3), tam=V(42,2.7,58)}
local MONSTROS = {
	{nome="Monstro_Jacare", pos=V(0,-7,-10), tipo="Jacare"},
}
local MOVEIS = {
	{id="G1", rotulo="Gaveteiro velho", interior={CF(-17,2.2,31.04,1,0,0,0,1,0,0,0,1), V(3.3,4,1.5)}, partes={
		{grupo="Abre_G1_Gaveta1", tipo="gaveta", curso=V(0,0,-1.224), leva={V(-17,0.955,30.915), V(3.1,0.85,1.4)}},
		{grupo="Abre_G1_Gaveta3", tipo="gaveta", curso=V(0,0,-1.224), leva={V(-17,2.94,30.915), V(3.1,0.8,1.4)}},
	}},
	{id="G3", rotulo="Gaveteiro velho", interior={CF(16.453,2.2,31.041,1,0,0,0,1,0,0,0,1), V(3.374,4,1.671)}, partes={
		{grupo="Abre_G3_Gaveta2", tipo="gaveta", curso=V(-0.064,0,-1.222), leva={V(16.446,1.96,30.916), V(3.169,0.8,1.56)}},
		{grupo="Abre_G3_Gaveta4", tipo="gaveta", curso=V(-0.064,0,-1.222), leva={V(16.446,3.895,30.916), V(3.169,0.75,1.56)}},
	}},
	{id="G2", rotulo="Gaveteiro velho", interior={CF(20.04,-4.085,5,1,0,0,0,1,0,0,0,1), V(1.5,5.33,3.1)}, partes={
		{grupo="Abre_G2_Gaveta4", tipo="gaveta", curso=V(-1.224,0,0), leva={V(19.915,-2.755,5), V(1.4,0.85,2.9)}},
		{grupo="Abre_G2_Gaveta5", tipo="gaveta", curso=V(-1.224,0,0), leva={V(19.915,-1.725,5), V(1.4,0.85,2.9)}},
	}},
	{id="Bau", rotulo="Bau velho", interior={CF(16.35,3.36,-29.5,1,0,0,0,1,0,0,0,1), V(4.9,2.2,2.5)}, partes={
		{grupo="Abre_Bau_Tampa", tipo="giro", pivo=V(16.35,4.4,-31), eixo=V(1,0,0), angulo=-78},
	}},
}

-- ================================================================== utilitarios
local avisos, linhas = {}, {}
local function info(...) table.insert(linhas, table.concat({ ... }, " ")) end
local function aviso(...) table.insert(avisos, table.concat({ ... }, " ")) end
local recording
pcall(function() recording = ChangeHistoryService:TryBeginRecording("Invokyr instalar Adega Alagada") end)

local function pasta(pai, nome, classe)
	local f = pai:FindFirstChild(nome)
	if not f then f = Instance.new(classe or "Folder"); f.Name = nome; f.Parent = pai end
	return f
end
local function novo(pai, nome, classe)
	local f = Instance.new(classe or "Folder"); f.Name = nome; f.Parent = pai
	return f
end
local function invisivel(pai, nome, cf, tam, solido)
	local p = Instance.new("Part")
	p.Name = nome; p.Size = tam; p.CFrame = cf
	p.Anchored = true; p.CanCollide = solido; p.CanQuery = solido; p.CanTouch = false; p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic; p.Color = C3(255, 60, 60)
	p.Transparency = (solido and CONFIG.MOSTRAR_COLISOES) and 0.6 or 1
	p.Parent = pai
	return p
end

local raiz = workspace:FindFirstChild("Invokyr")
if not raiz then error("[Invokyr] Nao achei Workspace > Invokyr. Este place nao e o do jogo?") end
local backup = pasta(ServerStorage, "Invokyr_Backup")
local biblioteca = pasta(ServerStorage, "Invokyr_Salas")
local salasMapa = pasta(pasta(raiz, "Mansao"), "Salas")

-- ================================================================== 1. achar a importacao
local function chave(s) return (string.gsub(string.lower(s), "[^a-z0-9]", "")) end
local function ehAdega(m)
	if not m:IsA("Model") or m:GetAttribute("PecaInvokyr") then return false end
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("MeshPart") and (chave(d.Name) == "baumadeirapodre" or string.gsub(chave(d.Parent.Name), "node$", "") == "baumadeirapodre") then return true end
	end
	return false
end
local importado
local sel = Selection:Get()
if #sel == 1 and ehAdega(sel[1]) then importado = sel[1] end
if not importado then
	for _, m in ipairs(workspace:GetChildren()) do
		if ehAdega(m) then importado = m end
	end
end
if not importado then
	error("[Invokyr] Nao achei a Adega importada. Importe o AdegaAlagada.glb (Home > Import 3D) e rode de novo.")
end

local indice = {}
for _, p in ipairs(importado:GetDescendants()) do
	if p:IsA("MeshPart") then
		indice[chave(p.Name)] = p
		local pai = string.gsub(chave(p.Parent.Name), "node$", "")
		if pai ~= "" and not indice[pai] then indice[pai] = p end
	end
end

-- referencia: o piso (meio da sala) e o bau (canto) dao posicao e direcao da importacao
local piso = indice[chave("Piso__PedraMolhada")]
local ref = indice[chave("Bau__MadeiraPodre")]
if not (piso and ref) then error("[Invokyr] A importacao nao tem o piso ou o bau. Importe todas as malhas, sem unir.") end
local ePiso, eBan = PECAS["Piso__PedraMolhada"], PECAS["Bau__MadeiraPodre"]
if math.abs(piso.Size.X - ePiso[2].X) > 0.3 or math.abs(piso.Size.Z - ePiso[2].Z) > 0.3 then
	error(("[Invokyr] O piso veio com %.2f x %.2f (esperado %.2f x %.2f). Importe com Scale Unit = Stud e Scale = 1.")
		:format(piso.Size.X, piso.Size.Z, ePiso[2].X, ePiso[2].Z))
end
local esp = eBan[1] - ePiso[1]
local obs = ref.Position - piso.Position
local giro = math.atan2(obs.X, obs.Z) - math.atan2(esp.X, esp.Z)
local origem = CFrame.new(piso.Position) * CFrame.Angles(0, giro, 0) * CFrame.new(-ePiso[1])

-- ================================================================== 2. montar a sala (na origem do mundo)
local sala = Instance.new("Model")
sala.Name = "AdegaAlagada"
sala:SetAttribute("PecaInvokyr", true)
sala:SetAttribute("CelulasX", CELULAS[1])
sala:SetAttribute("CelulasZ", CELULAS[2])
sala:SetAttribute("Tipo", "Desafio")
sala:SetAttribute("Escuridao", 1)   -- 0 = luz geral normal, 1 = so as luzes da sala (como no Blender)
sala:SetAttribute("Exposicao", -0.6)
sala:SetAttribute("Altura", 15)
sala:SetAttribute("Base", AGUA.fundo - 1)      -- a sala desce abaixo do nivel da porta
sala:SetAttribute("NivelAgua", AGUA.nivel)
sala:SetAttribute("AguaLentidao", 0.6)
local visual = novo(sala, "Visual")
local origemPart = invisivel(sala, "Origem", CFrame.identity, Vector3.one * 0.15, false)
sala.PrimaryPart = origemPart

local portas = novo(sala, "Portas")
local folhas = {}
for lado, d in pairs(PORTAS) do
	local f = novo(portas, lado)
	novo(f, "Fecho")
	for _, ab in ipairs({ "A", "B" }) do
		local leaf = novo(f, ab, "Model")
		local h = DOBRADICAS["Porta_" .. lado .. "_" .. ab]
		local eixo = invisivel(leaf, "Eixo", CFrame.lookAt(h, h + d.fora), Vector3.one * 0.1, false)
		leaf.PrimaryPart = eixo
		leaf:SetAttribute("Fechada", eixo.CFrame)
		folhas[lado .. ab] = leaf
	end
end
local moveis = novo(sala, "Moveis")
local grupos = {}
for _, m in ipairs(MOVEIS) do
	local mm = novo(moveis, "Movel_" .. m.id, "Model")
	mm:SetAttribute("Rotulo", m.rotulo)
	mm:SetAttribute("Relativo", true)
	mm:SetAttribute("InteriorCF", m.interior[1])
	mm:SetAttribute("InteriorTam", m.interior[2])
	for _, pa in ipairs(m.partes) do
		local g = novo(mm, pa.grupo, "Model")
		g:SetAttribute("Tipo", pa.tipo)
		g:SetAttribute("Movel", m.id)
		g:SetAttribute("Relativo", true)
		g:SetAttribute("Aberto", false)
		if pa.tipo == "giro" then
			g:SetAttribute("Pivo", pa.pivo); g:SetAttribute("Eixo", pa.eixo.Unit); g:SetAttribute("Angulo", pa.angulo)
		else
			g:SetAttribute("Curso", pa.curso); g:SetAttribute("LevaCF", CFrame.new(pa.leva[1])); g:SetAttribute("LevaTam", pa.leva[2])
		end
		grupos[pa.grupo] = { modelo = g, rotulo = m.rotulo }
	end
end

local faltam, desvio, pior = {}, 0, 0
local BRILHA = { ["Lanterna__VidroMel"] = C3(255, 170, 96) }
for nome, d in pairs(PECAS) do
	local src = indice[chave(nome)]
	if not src then
		table.insert(faltam, nome)
	else
		local p = src:Clone()
		p.Name = nome
		p.CFrame = origem:ToObjectSpace(src.CFrame)
		local erro = (p.Position - d[1]).Magnitude
		if erro > 0.05 then desvio += 1; pior = math.max(pior, erro) end
		p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
		local mat = string.match(nome, "__(.+)$")
		if mat == "Chama" or BRILHA[nome] then
			local sa = p:FindFirstChildOfClass("SurfaceAppearance")
			if sa then sa:Destroy() end   -- o Roblox nao faz textura brilhar; a peca vira Neon
			p.TextureID = ""; p.Material = Enum.Material.Neon; p.CastShadow = false
			p.Color = BRILHA[nome] or C3(255, 150, 60)
		end
		if nome == "Agua__Agua" then p.CastShadow = false end
		local lado, ab = string.match(nome, "^Porta_([NSLO])_([AB])__")
		local fecho = string.match(nome, "^Fecho_([NSLO])__")
		local grupo = string.match(nome, "^(Abre_.+)__")
		if lado then p.Parent = folhas[lado .. ab]
		elseif fecho then p.Parent = portas[fecho].Fecho
		elseif grupo and grupos[grupo] then p.CanQuery = true; p.Parent = grupos[grupo].modelo
		else p.Parent = visual end
	end
end
if #faltam > 0 then
	table.sort(faltam)
	aviso(#faltam .. " pecas nao vieram na importacao (ex.: " .. faltam[1] .. "). Importe todas as malhas, sem unir.")
end
if desvio > 0 then
	aviso(("%d pecas ficaram fora do lugar esperado (pior: %.2f studs). Mande print disso."):format(desvio, pior))
end

-- colisao das portas e encaixes (padrao da Bailarina)
local encaixes = novo(sala, "Encaixes")
local ancora = invisivel(encaixes, "AncoraEncaixes", CFrame.identity, Vector3.one * 0.1, false)
for lado, d in pairs(PORTAS) do
	local a = Instance.new("Attachment")
	a.Name = "Encaixe_" .. lado
	a.CFrame = CFrame.lookAt(d.ponto, d.ponto + d.fora)
	a.Parent = ancora
	local frame = CFrame.lookAt(d.ponto, d.ponto + d.fora)
	invisivel(portas[lado].Fecho, "BatenteColisao", frame * CFrame.new(0, 4.5, 0.5), V(4.87, 9, 0.8), true)
	for _, ab in ipairs({ "A", "B" }) do
		local leaf = folhas[lado .. ab]
		local cf = CFrame.lookAt(leaf.PrimaryPart.Position, leaf.PrimaryPart.Position + d.fora)
		invisivel(leaf, "FolhaColisao", cf * CFrame.new(ab == "A" and -1.225 or 1.225, 4.5, 0), V(2.41, 8.94, 0.655), true)
	end
end

-- colisao da sala
local col = novo(sala, "Colisao")
for _, c in ipairs(COLISOES) do invisivel(col, c[1], c[2], c[3], true) end

-- luzes (como no Salao da Bailarina: cada vela/lampada com a sua luz e sombra; reflexos sem sombra)
local luzes = novo(sala, "Luzes")
for _, l in ipairs(LUZES) do
	local a = invisivel(luzes, l.nome, CFrame.new(l.pos), Vector3.one * 0.1, false)
	local s
	if l.tipo == "Spot" then
		a.CFrame = CFrame.lookAt(l.pos, l.pos + l.dir)
		s = Instance.new("SpotLight"); s.Face = Enum.NormalId.Front; s.Angle = l.angulo
	else
		s = Instance.new("PointLight")
	end
	s.Color = l.cor; s.Brightness = l.brilho; s.Range = l.alcance; s.Shadows = l.sombra; s.Enabled = l.brilho > 0
	s.Parent = a
end

-- esconderijos
local esc = novo(sala, "Esconderijos")
local nTotem, nDado = 0, 0
for _, pt in ipairs(PONTOS) do
	local p = invisivel(esc, pt.nome, CFrame.new(pt.pos) * CFrame.Angles(0, math.rad(pt.giro or 0), 0),
		pt.tipo == "totem" and V(2.2, 0.1, 2.1) or V(1, 0.1, 1), false)
	p.Material = Enum.Material.Neon
	p.Color = pt.tipo == "totem" and C3(120, 255, 170) or C3(110, 170, 255)
	p.Transparency = CONFIG.MOSTRAR_ESCONDERIJOS and 0.4 or 1
	p:SetAttribute("TipoEsconderijo", pt.tipo)
	if pt.movel then p:SetAttribute("Movel", pt.movel) end
	if pt.deitado then p:SetAttribute("Deitado", true) end
	CollectionService:AddTag(p, pt.tipo == "totem" and "Invokyr_Esconderijo" or "Invokyr_EsconderijoDado")
	if pt.tipo == "totem" then nTotem += 1 else nDado += 1 end
end

-- agua (regiao para scripts e para o monstro) e ponto do jacare
local pastaAgua = novo(sala, "Agua")
local regiao = invisivel(pastaAgua, "RegiaoDaAgua", AGUA.cf, AGUA.tam, false)
regiao:SetAttribute("Nivel", AGUA.nivel)
local monstros = novo(sala, "Monstros")
for _, m in ipairs(MONSTROS) do
	local p = invisivel(monstros, m.nome, CFrame.new(m.pos), V(2, 0.2, 2), false)
	p:SetAttribute("Monstro", m.tipo)
end

-- moveis: puxador com o prompt, colisao que acompanha a peca
for nomeGrupo, gr in pairs(grupos) do
	local g = gr.modelo
	local qtd = 0
	for _, x in ipairs(g:GetChildren()) do if x:IsA("MeshPart") then qtd += 1 end end
	if qtd == 0 then aviso("Movel sem pecas: " .. nomeGrupo) end
	local cf = g:GetBoundingBox()
	local px = invisivel(g, "Puxador", cf, Vector3.one * 0.4, false)
	local pr = Instance.new("ProximityPrompt")
	pr.Name = "Abrir"; pr.ActionText = "Abrir"; pr.ObjectText = gr.rotulo
	pr.KeyboardKeyCode = Enum.KeyCode.E; pr.HoldDuration = 0; pr.MaxActivationDistance = 7
	pr.RequiresLineOfSight = false
	pr.Parent = px
	CollectionService:AddTag(g, "Invokyr_Abre")
end

-- configurador de portas (o mesmo do Salao da Bailarina)
local config = novo(sala, "ConfigurarPortas", "ModuleScript")
config.Source = [==[
-- require(sala.ConfigurarPortas)(sala, {N=100,S=0})
-- Um angulo (0 a 100) habilita a porta; um lado omitido recebe o painel.
return function(room,angles)
    local function show(parent,on)
        for _,p in ipairs(parent:GetDescendants()) do
            if p:IsA("MeshPart") then p.Transparency=on and 0 or 1
            elseif p:IsA("BasePart") and p.Name:match("Colisao$") then
                p.CanCollide=on
                p.CanQuery=on
            end
        end
    end
    for _,side in ipairs(room.Portas:GetChildren()) do
        local angle=angles[side.Name]
        local active=type(angle)=="number"
        show(side.Fecho,not active)
        for _,label in ipairs({"A","B"}) do
            local leaf=side[label]
            show(leaf,active)
            local turn=active and math.clamp(angle,0,100) or 0
            leaf:PivotTo(room:GetPivot()*leaf:GetAttribute("Fechada")*CFrame.Angles(0,math.rad(label=="A" and -turn or turn),0))
        end
    end
end
]==]
local configurar = require(config)
configurar(sala, {})

-- ================================================================== 3. script dos moveis
local FONTE = [==[
-- INVOKYR - Moveis que abrem (v2). Instalado pelos scripts de sala (Galeria, Banheiro...).
-- Nao edite aqui: rode de novo o instalador da sala que ele volta igual.
-- Cuida de todo Model com a tag Invokyr_Abre, em qualquer sala e em qualquer lugar do mapa.
-- Sala com o atributo PecaInvokyr guarda as medidas em relacao a ela (pode ser movida e girada).
-- Tambem: nao deixa pegar totem/dado de dentro de movel fechado, e deita o totem nos
-- esconderijos marcados com o atributo Deitado (ex.: dentro da banheira).
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local DURACAO = 0.45
local estado = {}

local params = OverlapParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
local mansao = workspace:FindFirstChild("Invokyr") and workspace.Invokyr:FindFirstChild("Mansao")
params.FilterDescendantsInstances = { mansao }

-- referencia de uma peca: a sala (se for peca de sala) ou o mundo
local function referencia(x)
	local a = x
	while a and a ~= workspace do
		if a:IsA("Model") and a:GetAttribute("PecaInvokyr") then return a:GetPivot() end
		a = a.Parent
	end
	return CFrame.identity
end

local function medidas(g, e)
	local R = g:GetAttribute("Relativo") and referencia(g) or CFrame.identity
	e.pivo = R * (g:GetAttribute("Pivo") or Vector3.zero)
	e.eixo = R:VectorToWorldSpace(g:GetAttribute("Eixo") or Vector3.yAxis)
	e.curso = R:VectorToWorldSpace(g:GetAttribute("Curso") or Vector3.zero)
	local cf = g:GetAttribute("LevaCF")
	e.levaCF = cf and (R * cf) or nil
	e.levaTam = g:GetAttribute("LevaTam")
end

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
		if p.Parent then p.CFrame = T * cf0 end
	end
end

local function alternar(g)
	local e = estado[g]
	if not e or e.ocupado then return end
	e.ocupado = true
	if not e.aberto then
		-- fechado: as pecas estao na posicao de repouso. Le tudo de novo (a sala pode ter mudado de lugar).
		e.base = {}
		for _, p in ipairs(g:GetDescendants()) do
			if p:IsA("BasePart") then e.base[p] = p.CFrame end
		end
		medidas(g, e)
	end
	local alvo = e.aberto and 0 or 1
	e.carregados = {}
	if e.tipo == "gaveta" and e.levaCF then
		local T = transformar(e, e.t)
		for _, p in ipairs(workspace:GetPartBoundsInBox(T * e.levaCF, e.levaTam, params)) do
			local modelo = p:FindFirstAncestorOfClass("Model")
			local ehPersonagem = modelo and modelo:FindFirstChildOfClass("Humanoid")
			if not e.base[p] and not ehPersonagem then e.carregados[p] = T:Inverse() * p.CFrame end
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
	e.tipo = g:GetAttribute("Tipo")
	e.angulo = g:GetAttribute("Angulo") or 0
	e.movel = g.Parent
	e.prompt = g:FindFirstChild("Abrir", true)
	medidas(g, e)
	estado[g] = e
	if e.prompt then
		e.prompt.ActionText = "Abrir"
		e.prompt.Triggered:Connect(function() task.spawn(alternar, g) end)
	end
end

for _, g in ipairs(CollectionService:GetTagged("Invokyr_Abre")) do preparar(g) end
CollectionService:GetInstanceAddedSignal("Invokyr_Abre"):Connect(preparar)
CollectionService:GetInstanceRemovedSignal("Invokyr_Abre"):Connect(function(g) estado[g] = nil end)

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

-- totem deitado: o Script 09 pousa o totem em pe; aqui ele e deitado ao longo do esconderijo
local function deitarTotens()
	local pasta = workspace:FindFirstChild("Invokyr") and workspace.Invokyr:FindFirstChild("Totens")
	local ativos = pasta and pasta:FindFirstChild("Ativos")
	if not ativos then return end
	local camas = {}
	for _, p in ipairs(CollectionService:GetTagged("Invokyr_Esconderijo")) do
		if p:IsA("BasePart") and p:GetAttribute("Deitado") and p:IsDescendantOf(workspace) then table.insert(camas, p) end
	end
	if #camas == 0 then return end
	for _, m in ipairs(ativos:GetChildren()) do
		if m:IsA("Model") and m:GetAttribute("Carregador") == nil then
			local cf, tam = m:GetBoundingBox()
			for _, cama in ipairs(camas) do
				local l = cama.CFrame:PointToObjectSpace(cf.Position)
				local emPe = math.abs(cf.UpVector:Dot(cama.CFrame.UpVector)) > 0.7
				if emPe and math.abs(l.X) < 1.5 and math.abs(l.Z) < 1.5 and l.Y > -0.6 and l.Y < tam.Y + 0.6 then
					-- a caixa do totem passa a ficar ao longo do Z do esconderijo, de barriga para cima
					local caixaRel = m:GetPivot():ToObjectSpace(cf)
					local alvo = cama.CFrame * CFrame.new(0, tam.Z / 2 + 0.06, 0) * CFrame.Angles(math.rad(90), 0, 0)
					m:PivotTo(alvo * caixaRel:Inverse())
					m:SetAttribute("DeitadoEm", cama.Name)
					break
				end
			end
		end
	end
end

while true do
	task.wait(0.25)
	deitarTotens()
	-- regioes trancadas: interior de movel com todas as portas fechadas, e gaveta fechada
	local trancadas = {}
	local portasDoMovel = {}
	for g, e in pairs(estado) do
		if g.Parent then
			if e.tipo == "giro" and e.movel then
				local s = portasDoMovel[e.movel] or { fechadas = true }
				if e.aberto or e.ocupado then s.fechadas = false end
				portasDoMovel[e.movel] = s
			elseif e.tipo == "gaveta" and not e.aberto and not e.ocupado then
				local cf, tam = g:GetAttribute("LevaCF"), g:GetAttribute("LevaTam")
				if cf and tam then
					local R = g:GetAttribute("Relativo") and referencia(g) or CFrame.identity
					table.insert(trancadas, { R * cf, tam })
				end
			end
		end
	end
	for m, s in pairs(portasDoMovel) do
		local cf, tam = m:GetAttribute("InteriorCF"), m:GetAttribute("InteriorTam")
		if s.fechadas and cf and tam then
			local R = m:GetAttribute("Relativo") and referencia(m) or CFrame.identity
			table.insert(trancadas, { R * cf, tam })
		end
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
if not sc then sc = Instance.new("Script"); sc.Name = "Invokyr_Moveis"; sc.Parent = ServerScriptService end
sc.Source = FONTE
sc.Disabled = false
local FONTE_ESC = [==[
-- INVOKYR - Escuridao das salas (LocalScript). Instalado pelos scripts de sala.
-- Nao edite aqui: rode de novo o instalador que ele volta igual.
-- Sala com o atributo Escuridao (0 a 1) apaga a luz geral do jogo enquanto o jogador esta dentro dela,
-- como no Blender: so as luzes da propria sala iluminam. Ao sair, tudo volta ao que o servidor mandou.
-- So mexe no computador de quem esta dentro; os outros jogadores nao sao afetados.
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local jogador = Players.LocalPlayer
local PROPS = { "Ambient", "OutdoorAmbient", "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "ExposureCompensation" }
local ESCURO = {
	Ambient = Color3.new(0, 0, 0),
	OutdoorAmbient = Color3.new(0, 0, 0),
	EnvironmentDiffuseScale = 0,
	EnvironmentSpecularScale = 0,
}
local expoSala = -0.7   -- quanto a camera "fecha" dentro da sala (atributo Exposicao da sala)

-- o que o servidor (ou outro script) quer: guardado sempre que muda sem ser por aqui
-- (os sinais podem chegar atrasados, entao compara com o ultimo valor escrito aqui)
local servidor, escrito = {}, {}
local function igual(a, b)
	if type(a) == "number" then return math.abs(a - b) < 0.001 end
	return math.abs(a.R - b.R) + math.abs(a.G - b.G) + math.abs(a.B - b.B) < 0.004
end
for _, k in ipairs(PROPS) do
	servidor[k] = Lighting[k]
	Lighting:GetPropertyChangedSignal(k):Connect(function()
		local meu = false
		for _, v in ipairs(escrito[k] or {}) do if igual(Lighting[k], v) then meu = true end end
		if not meu then servidor[k] = Lighting[k] end
	end)
end

local salas = {}
local function considerar(x)
	if x:IsA("Model") and x:GetAttribute("PecaInvokyr") then salas[x] = true end
end
for _, x in ipairs(workspace:GetDescendants()) do considerar(x) end
workspace.DescendantAdded:Connect(considerar)
workspace.DescendantRemoving:Connect(function(x) salas[x] = nil end)

local function escuridaoAqui(pos)
	for sala in pairs(salas) do
		local e = sala:GetAttribute("Escuridao")
		if e and e > 0 and sala.Parent then
			local l = sala:GetPivot():PointToObjectSpace(pos)
			local mx = (sala:GetAttribute("CelulasX") or 0) * 5.5
			local mz = (sala:GetAttribute("CelulasZ") or 0) * 5.5
			if math.abs(l.X) <= mx and math.abs(l.Z) <= mz and l.Y > (sala:GetAttribute("Base") or -3) and l.Y < (sala:GetAttribute("Altura") or 16) then
				expoSala = sala:GetAttribute("Exposicao") or -0.7
				return math.clamp(e, 0, 1)
			end
		end
	end
	return 0
end

local function mistura(a, b, t)
	if type(a) == "number" then return a + (b - a) * t end
	return a:Lerp(b, t)
end

local atual, ultimo = 0, -1
local dentroAntes = false
local relogio = 0
RunService.RenderStepped:Connect(function(dt)
	relogio += dt
	local alvo = 0
	local char = jogador.Character
	local raiz = char and char:FindFirstChild("HumanoidRootPart")
	if raiz then alvo = escuridaoAqui(raiz.Position) end
	if (alvo > 0) ~= dentroAntes then
		dentroAntes = alvo > 0
		print("[Invokyr] Escuridao: " .. (dentroAntes and ("entrou numa sala escura (" .. alvo .. ")") or "saiu da sala escura"))
	end
	-- entra em ~0,8 s e sai em ~0,8 s (o olho "acostuma")
	local passo = dt / 0.8
	if atual < alvo then atual = math.min(alvo, atual + passo) elseif atual > alvo then atual = math.max(alvo, atual - passo) end
	if atual == 0 and ultimo == 0 then return end
	if math.abs(atual - ultimo) < 0.002 and relogio < 0.5 then return end
	relogio = 0
	ultimo = atual
	for _, k in ipairs(PROPS) do
		local fim = ESCURO[k]
		if k == "ExposureCompensation" then fim = servidor[k] + expoSala end
		local v = mistura(servidor[k], fim, atual)
		local lista = escrito[k] or {}
		table.insert(lista, v)
		if #lista > 12 then table.remove(lista, 1) end
		escrito[k] = lista
		Lighting[k] = v
	end
end)
]==]
local sps = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
if sps then
	local ls = sps:FindFirstChild("Invokyr_Escuridao")
	if not ls then ls = Instance.new("LocalScript"); ls.Name = "Invokyr_Escuridao"; ls.Parent = sps end
	if ls:IsA("LocalScript") then ls.Source = FONTE_ESC; ls.Disabled = false end
end
local FONTE_AGUA = [==[
-- INVOKYR - Agua das salas (LocalScript). Instalado pelo script da Adega Alagada.
-- Nao edite aqui: rode de novo o instalador que ele volta igual.
-- Sala com o atributo NivelAgua (altura da agua medida a partir da origem da sala):
--   * com os pes dentro da agua o jogador anda mais devagar (atributo MultVelocidade, lido pelo Invokyr_Movimento);
--   * com a camera debaixo da agua a tela fica marrom e embacada.
-- Serve para qualquer sala: basta ela ter NivelAgua (e opcionalmente AguaLentidao, 0 a 1).
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local jogador = Players.LocalPlayer

local cor = Lighting:FindFirstChild("Invokyr_Submerso")
if not cor then
	cor = Instance.new("ColorCorrectionEffect")
	cor.Name = "Invokyr_Submerso"
	cor.Parent = Lighting
end
cor.TintColor = Color3.fromRGB(150, 112, 62); cor.Brightness = -0.18; cor.Contrast = 0.15; cor.Saturation = -0.35
cor.Enabled = false
local borrao = Lighting:FindFirstChild("Invokyr_SubmersoBorrao")
if not borrao then
	borrao = Instance.new("BlurEffect")
	borrao.Name = "Invokyr_SubmersoBorrao"
	borrao.Parent = Lighting
end
borrao.Size = 14; borrao.Enabled = false

local salas = {}
local function considerar(x)
	if x:IsA("Model") and x:GetAttribute("PecaInvokyr") then salas[x] = true end
end
for _, x in ipairs(workspace:GetDescendants()) do considerar(x) end
workspace.DescendantAdded:Connect(considerar)
workspace.DescendantRemoving:Connect(function(x) salas[x] = nil end)

-- devolve a sala com agua em que o ponto esta e a altura do ponto em relacao a agua (negativo = submerso)
local function agua(pos)
	for sala in pairs(salas) do
		local nivel = sala:GetAttribute("NivelAgua")
		if nivel and sala.Parent then
			local l = sala:GetPivot():PointToObjectSpace(pos)
			local mx = (sala:GetAttribute("CelulasX") or 0) * 5.5
			local mz = (sala:GetAttribute("CelulasZ") or 0) * 5.5
			if math.abs(l.X) <= mx and math.abs(l.Z) <= mz and l.Y > (sala:GetAttribute("Base") or -10) and l.Y < nivel + 6 then
				return sala, l.Y - nivel
			end
		end
	end
	return nil, 0
end

local mult = 1
RunService.RenderStepped:Connect(function()
	local alvo = 1
	local char = jogador.Character
	local raiz = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if raiz and hum then
		local pes = raiz.Position - Vector3.new(0, hum.HipHeight + raiz.Size.Y / 2, 0)
		local sala, h = agua(pes)
		if sala and h < -0.3 then alvo = sala:GetAttribute("AguaLentidao") or 0.6 end
	end
	if alvo ~= mult then
		mult = alvo
		jogador:SetAttribute("MultVelocidade", mult)
	end
	local cam = workspace.CurrentCamera
	local salaC, hc = agua(cam and cam.CFrame.Position or Vector3.zero)
	local debaixo = salaC ~= nil and hc < 0
	if cor.Enabled ~= debaixo then
		cor.Enabled = debaixo
		borrao.Enabled = debaixo
	end
end)
]==]
if sps then
	local la = sps:FindFirstChild("Invokyr_Agua")
	if not la then la = Instance.new("LocalScript"); la.Name = "Invokyr_Agua"; la.Parent = sps end
	if la:IsA("LocalScript") then la.Source = FONTE_AGUA; la.Disabled = false end
	-- Invokyr_Movimento: a velocidade passa a ser multiplicada pelo atributo MultVelocidade (agua)
	local mov = sps:FindFirstChild("Invokyr_Movimento")
	local LINHA = "hum.WalkSpeed = agachado and CFG.AGACHAR or (correndo and CFG.CORRER or CFG.ANDAR)"
	if mov and mov:IsA("LocalScript") then
		local src = mov.Source
		if string.find(src, "MultVelocidade", 1, true) then
			info("Invokyr_Movimento ja anda devagar na agua (nada mudou nele)")
		elseif string.find(src, LINHA, 1, true) then
			local copia = mov:Clone(); copia.Disabled = true
			copia.Name = "Invokyr_Movimento_antes_da_agua"; copia.Parent = backup
			local i, j = string.find(src, LINHA, 1, true)
			mov.Source = string.sub(src, 1, i - 1)
				.. "hum.WalkSpeed = (agachado and CFG.AGACHAR or (correndo and CFG.CORRER or CFG.ANDAR)) * (player:GetAttribute(\"MultVelocidade\") or 1)"
				.. string.sub(src, j + 1)
			info("Invokyr_Movimento: agora anda mais devagar na agua (copia antiga no Invokyr_Backup)")
		else
			aviso("Nao achei a linha da velocidade no Invokyr_Movimento; na agua o jogador vai andar na velocidade normal.")
		end
	else
		aviso("Nao achei o Invokyr_Movimento em StarterPlayerScripts; na agua o jogador vai andar na velocidade normal.")
	end
end

-- ================================================================== 4. guardar, previa e limpeza
local carimbo = os.date("%Y%m%d_%H%M%S")
if backup:FindFirstChild("AdegaAlagada_" .. carimbo) then carimbo ..= "_" .. math.random(100, 999) end
local antiga = biblioteca:FindFirstChild("AdegaAlagada")
local previaAntiga = salasMapa:FindFirstChild("Previa_AdegaAlagada") or workspace:FindFirstChild("Previa_AdegaAlagada")
local historico
if antiga or previaAntiga then
	historico = novo(backup, "AdegaAlagada_" .. carimbo)
	if antiga then antiga.Parent = historico end
	if previaAntiga then previaAntiga.Parent = historico end
end
sala.Parent = biblioteca

local previa = sala:Clone()
previa.Name = "Previa_AdegaAlagada"
if not CONFIG.PREVIA_COM_ESCONDERIJOS then
	for _, p in ipairs(previa.Esconderijos:GetChildren()) do
		CollectionService:RemoveTag(p, "Invokyr_Esconderijo")
		CollectionService:RemoveTag(p, "Invokyr_EsconderijoDado")
	end
end
previa:PivotTo(CFrame.new(CONFIG.PREVIA))
require(previa.ConfigurarPortas)(previa, CONFIG.PREVIA_PORTAS)
for lado in pairs(CONFIG.PREVIA_PORTAS) do
	local d = PORTAS[lado]
	if d then
		local patamar = invisivel(previa, "PatamarDeTeste_" .. lado, previa:GetPivot() * CFrame.lookAt(d.ponto, d.ponto + d.fora) * CFrame.new(0, -0.4, -6), V(11, 0.8, 12), true)
		patamar.Transparency = 0; patamar.Material = Enum.Material.Slate; patamar.Color = C3(48, 43, 44)
	end
end
-- a previa nao pode cair em cima de outra sala de teste
local cfP, tamP = previa:GetBoundingBox()
for _, outra in ipairs(salasMapa:GetChildren()) do
	if outra:IsA("Model") and outra ~= previa then
		local ok, cfO, tamO = pcall(function() return outra:GetBoundingBox() end)
		if ok and tamO.Magnitude > 0 then
			local d = cfP.Position - cfO.Position
			if math.abs(d.X) < (tamP.X + tamO.X) / 2 and math.abs(d.Z) < (tamP.Z + tamO.Z) / 2 and math.abs(d.Y) < (tamP.Y + tamO.Y) / 2 then
				aviso("A previa encosta em " .. outra.Name .. ". Mude CONFIG.PREVIA e rode de novo.")
			end
		end
	end
end
previa.Parent = salasMapa

importado.Name = "AdegaAlagada_importacao_" .. carimbo
importado.Parent = historico or novo(backup, "AdegaAlagada_" .. carimbo)

-- ================================================================== relatorio
local nVis = 0
for _, p in ipairs(sala:GetDescendants()) do if p:IsA("MeshPart") then nVis += 1 end end
info(("AdegaAlagada guardada em ServerStorage > Invokyr_Salas | pecas: %d de %d"):format(nVis, 91))
local nPartes = 0
for _ in pairs(grupos) do nPartes += 1 end
info(("Moveis que abrem: %d partes em %d moveis | esconderijos: %d de totem, %d de dado"):format(nPartes, #MOVEIS, nTotem, nDado))
info("Previa em Workspace > Invokyr > Mansao > Salas > Previa_AdegaAlagada, em " .. tostring(CONFIG.PREVIA))
Selection:Set({ previa })
pcall(function()
	workspace.CurrentCamera.CFrame = previa:GetPivot() * CFrame.lookAt(V(-3.5, 5.2, 29.5), V(4, -3.5, -12))
end)
if recording then pcall(function() ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit) end) end
print("========== INVOKYR 18: ADEGA ALAGADA ==========")
for _, l in ipairs(linhas) do print("  " .. l) end
if #avisos == 0 then print("  Sem avisos.") else for _, a in ipairs(avisos) do warn("  AVISO: " .. a) end end
print("Para andar na sala: Test > setinha do Play > Play Here (a camera ja esta dentro da previa).")
