--[[
INVOKYR - Script 16: Instalar o BANHEIRO (sala comum, 2 x 3 celulas)
==================================================================
Mesmo jeito do Salao da Bailarina:
  1. Importe o Banheiro.glb (Home > Import 3D). Ele ja fica selecionado no fim da importacao.
  2. Rode este script na BARRA DE COMANDOS (View > Command Bar), com o jogo PARADO.

O que faz (pode rodar de novo sem duplicar nada):
  - Monta a sala "Banheiro" em ServerStorage > Invokyr_Salas (a peca que o gerador vai usar)
    e uma copia para testar, "Previa_Banheiro", em Workspace > Invokyr > Mansao > Salas.
  - As 160 pecas sao conferidas uma a uma contra as medidas do Blender.
  - Portas no padrao da casa: Portas > N/S/L/O > A, B (com Eixo) e Fecho, e o ConfigurarPortas.
  - Colisao invisivel, luzes, esconderijos de totem e de dado, e os moveis que abrem:
    banheira (tampa), penteadeira (portas e gavetas), armarinho do espelho, caixa da descarga,
    cesto de roupa e armario de toalhas. E so chegar perto e apertar E.
  - O totem que cair na banheira fica DEITADO dentro dela.
  - Atualiza o script Invokyr_Moveis no ServerScriptService (continua servindo a Galeria).
  - Nada e apagado: a versao anterior e a importacao vao para ServerStorage > Invokyr_Backup.
]]

local CONFIG = {
	PREVIA = Vector3.new(400, 0.594, -120),  -- onde fica a copia de teste (longe da mansao e da Galeria)
	PREVIA_PORTAS = { L = 100 },             -- portas abertas na previa (as outras ficam com o painel)
	MOSTRAR_COLISOES = false,
	MOSTRAR_ESCONDERIJOS = false,
	-- true = o Script 09 tambem esconde totens na previa (bom para testar o totem deitado na banheira)
	PREVIA_COM_ESCONDERIJOS = false,
}

-- ================================================================== guarda
local RunService = game:GetService("RunService")
if RunService:IsRunning() then
	error("[Invokyr] Pare o jogo (Stop) antes de rodar o Script 16. Em Play nada do que ele monta fica salvo.")
end
local Selection = game:GetService("Selection")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local V, CF, C3 = Vector3.new, CFrame.new, Color3.fromRGB

-- ================================================================== dados (gerados do Blender)
local CELULAS = {2, 3}
local PECAS = {
	["Abre_Armarinho_Porta__Latao"] = {V(8.885,6.85,-10.1), V(0.31,4.3,2.9)},
	["Abre_Armarinho_Porta__Mercurio"] = {V(8.905,6.85,-10.1), V(0.03,3.86,2.46)},
	["Abre_ArmarioToalhas_PortaD__Latao"] = {V(7.22,4.225,8.021), V(0.32,6.21,1.641)},
	["Abre_ArmarioToalhas_PortaD__Nogueira"] = {V(7.42,4.225,8.394), V(0.12,7.21,2.388)},
	["Abre_ArmarioToalhas_PortaD__Talha"] = {V(7.345,4.225,8.394), V(0.03,6.69,1.868)},
	["Abre_ArmarioToalhas_PortaE__Latao"] = {V(7.22,4.225,11.179), V(0.32,6.21,1.641)},
	["Abre_ArmarioToalhas_PortaE__Nogueira"] = {V(7.42,4.225,10.806), V(0.12,7.21,2.388)},
	["Abre_ArmarioToalhas_PortaE__Talha"] = {V(7.345,4.225,10.806), V(0.03,6.69,1.868)},
	["Abre_Banheira_Tampa__Latao"] = {V(-4.552,3.17,-10.805), V(0.281,0.251,0.224)},
	["Abre_Banheira_Tampa__Nogueira"] = {V(-4.58,3.205,-13), V(7,0.29,4.166)},
	["Abre_Cesto_Tampa__Latao"] = {V(-8.2,2.81,5.4), V(0.252,0.26,0.252)},
	["Abre_Cesto_Tampa__Nogueira"] = {V(-8.2,2.55,5.4), V(2.12,0.26,2.12)},
	["Abre_Descarga_Tampa__Ebanizada"] = {V(-8.85,9.54,9), V(0.2,0.08,3.1)},
	["Abre_Descarga_Tampa__Nogueira"] = {V(-9.4,9.575,9), V(1.2,0.15,3)},
	["Abre_Penteadeira_D_Porta__Latao"] = {V(7.3,1.81,-10.791), V(0.32,1.62,1.617)},
	["Abre_Penteadeira_D_Porta__Nogueira"] = {V(7.5,1.81,-10.425), V(0.12,2.62,2.35)},
	["Abre_Penteadeira_D_Porta__Talha"] = {V(7.425,1.81,-10.425), V(0.03,2.1,1.83)},
	["Abre_Penteadeira_E_Porta__Latao"] = {V(7.3,1.81,-5.209), V(0.32,1.62,1.617)},
	["Abre_Penteadeira_E_Porta__Nogueira"] = {V(7.5,1.81,-5.575), V(0.12,2.62,2.35)},
	["Abre_Penteadeira_E_Porta__Talha"] = {V(7.425,1.81,-5.575), V(0.03,2.1,1.83)},
	["Abre_Penteadeira_G_Gaveta1__Latao"] = {V(7.31,2.51,-8), V(0.2,0.175,0.175)},
	["Abre_Penteadeira_G_Gaveta1__Nogueira"] = {V(8.54,2.51,-8), V(2.2,1.22,2.24)},
	["Abre_Penteadeira_G_Gaveta1__Talha"] = {V(7.425,2.51,-8), V(0.03,0.94,1.92)},
	["Abre_Penteadeira_G_Gaveta2__Latao"] = {V(7.31,1.125,-8), V(0.2,0.175,0.175)},
	["Abre_Penteadeira_G_Gaveta2__Nogueira"] = {V(8.54,1.125,-8), V(2.2,1.15,2.24)},
	["Abre_Penteadeira_G_Gaveta2__Talha"] = {V(7.425,1.125,-8), V(0.03,0.87,1.92)},
	["Arandelas__Latao"] = {V(9.475,7.2,-8), V(0.93,1.2,0.4)},
	["Arandelas__VidroMel"] = {V(9.19,7.78,-8), V(0.64,0.8,0.64)},
	["Armarinho__Ebanizada"] = {V(9.465,6.85,-10.1), V(0.75,4.2,2.8)},
	["Armarinho__Nogueira"] = {V(9.49,6.85,-10.1), V(0.9,4.5,3.1)},
	["Armarinho__VidroMel"] = {V(9.49,8.02,-10.05), V(0.36,0.92,2.142)},
	["ArmarioToalhas__Ebanizada"] = {V(8.565,4.525,9.6), V(2.75,9.05,5.5)},
	["ArmarioToalhas__Linho"] = {V(8.64,6.615,9.8), V(1.8,0.99,4)},
	["ArmarioToalhas__Nogueira"] = {V(8.49,4.95,9.6), V(2.9,9,5.8)},
	["ArmarioToalhas__Talha"] = {V(7.299,8.865,9.6), V(0.018,0.37,1.8)},
	["Banco__Chama"] = {V(-0.15,2.76,-10.5), V(0.14,0.34,0.14)},
	["Banco__Couro"] = {V(-0.75,1.98,-10.175), V(0.4,0.12,0.35)},
	["Banco__Latao"] = {V(-0.15,2,-10.5), V(0.4,0.4,0.38)},
	["Banco__Marfim"] = {V(-0.15,2.39,-10.5), V(0.161,0.38,0.161)},
	["Banco__Nogueira"] = {V(-0.4,0.9,-10.4), V(1.832,1.8,1.832)},
	["Banco__Porcelana"] = {V(-0.75,1.86,-10.2), V(0.815,0.12,0.815)},
	["Banheira__FerroPintado"] = {V(-5,1.675,-13), V(7.728,2.25,4.032)},
	["Banheira__Latao"] = {V(-5.28,5.607,-13.098), V(8.945,11.214,4.887)},
	["Banheira__Linho"] = {V(-7.452,6.96,-12.94), V(3.911,7.12,4.95)},
	["Banheira__Marfim"] = {V(-8.416,3.85,-13), V(0.24,0.12,1.248)},
	["Banheira__Porcelana"] = {V(-5,1.9,-13), V(7.84,2.3,4.122)},
	["Biombo__Linho"] = {V(-8.037,4.475,12.942), V(2.8,4.65,3.777)},
	["Biombo__Nogueira"] = {V(-8.071,3.975,12.971), V(3.117,7.45,4.106)},
	["Biombo__Talha"] = {V(-7.996,1.325,12.902), V(2.808,1.25,3.769)},
	["Canos__Ferro"] = {V(-9.79,12.41,0), V(0.42,0.42,24.16)},
	["Canos__Latao"] = {V(-3.895,6.245,-0.045), V(11.79,12.49,30.49)},
	["Carrinho__Ebanizada"] = {V(-2.6,0.125,14.1), V(3.6,0.25,2.38)},
	["Carrinho__Ferro"] = {V(-2.6,2.554,14.1), V(3.325,4.607,2.14)},
	["Carrinho__FerroPintado"] = {V(-2.6,2.39,14.1), V(3.3,2.58,2.1)},
	["Carrinho__Linho"] = {V(-2.4,1.18,14.1), V(1.8,0.679,0.679)},
	["Carrinho__Porcelana"] = {V(-3.451,2.13,14.1), V(0.939,1.9,0.84)},
	["Carrinho__VidroMel"] = {V(-2.7,2.93,14.6), V(2.44,0.9,0.518)},
	["Cesto__Latao"] = {V(-8.2,1.285,5.4), V(2.037,2.07,2.037)},
	["Cesto__Nogueira"] = {V(-8.2,1.207,5.4), V(1.998,2.414,1.998)},
	["Espelho__Latao"] = {V(9.8,7.225,-5.9), V(0.2,5.05,2.9)},
	["Espelho__Mercurio"] = {V(9.805,6.85,-5.9), V(0.03,3.86,2.46)},
	["Fecho_L__Damasco"] = {V(10.497,4.5,0), V(0.825,9,4.87)},
	["Fecho_L__Ebanizada"] = {V(9.82,1.905,0), V(0.44,3.81,4.87)},
	["Fecho_L__Nogueira"] = {V(9.775,2.15,0), V(0.41,3.62,4.87)},
	["Fecho_L__Talha"] = {V(9.847,2.16,0), V(0.035,2.42,4.49)},
	["Fecho_N__Damasco"] = {V(5.5,4.5,-15.997), V(4.87,9,0.825)},
	["Fecho_N__Ebanizada"] = {V(5.5,1.905,-15.32), V(4.87,3.81,0.44)},
	["Fecho_N__Nogueira"] = {V(5.5,2.15,-15.275), V(4.87,3.62,0.41)},
	["Fecho_N__Talha"] = {V(5.5,2.16,-15.347), V(4.49,2.42,0.035)},
	["Fecho_O__Damasco"] = {V(-10.497,4.5,0), V(0.825,9,4.87)},
	["Fecho_O__Ebanizada"] = {V(-9.82,1.905,0), V(0.44,3.81,4.87)},
	["Fecho_O__Nogueira"] = {V(-9.775,2.15,0), V(0.41,3.62,4.87)},
	["Fecho_O__Talha"] = {V(-9.847,2.16,0), V(0.035,2.42,4.49)},
	["Fecho_S__Damasco"] = {V(5.5,4.5,15.997), V(4.87,9,0.825)},
	["Fecho_S__Ebanizada"] = {V(5.5,1.905,15.32), V(4.87,3.81,0.44)},
	["Fecho_S__Nogueira"] = {V(5.5,2.15,15.275), V(4.87,3.62,0.41)},
	["Fecho_S__Talha"] = {V(5.5,2.16,15.347), V(4.49,2.42,0.035)},
	["Janela__Bosque"] = {V(-5,9.2,-15.465), V(5.6,5.2,0.03)},
	["Janela__Calcario"] = {V(-5,6.315,-15.225), V(7,0.33,0.55)},
	["Janela__Ebanizada"] = {V(-5,9.3,-15.35), V(6.6,6,0.3)},
	["Janela__Ferro"] = {V(-5,9.2,-15.415), V(5.6,5.2,0.07)},
	["Janela__Latao"] = {V(-5,12.22,-15.05), V(4.4,0.14,0.14)},
	["Janela__Linho"] = {V(-6.58,9.9,-15.05), V(2.58,4.6,0.54)},
	["Lampada__Ferro"] = {V(0,11.8,1.5), V(0.07,3,0.061)},
	["Lampada__Latao"] = {V(0,10.15,1.5), V(0.32,0.5,0.304)},
	["Lampada__VidroMel"] = {V(0,9.51,1.5), V(0.64,0.82,0.624)},
	["Parede_L__Azulejo"] = {V(9.97,2.71,0), V(0.06,4.58,31)},
	["Parede_L__Ebanizada"] = {V(9.725,7,0), V(0.55,14,31)},
	["Parede_L__Nogueira"] = {V(9.78,11.74,0), V(0.44,4.28,31)},
	["Parede_L__Reboco"] = {V(10.5,7.2,0), V(1,14.4,31)},
	["Parede_L__Talha"] = {V(9.969,10.35,0), V(0.038,0.8,3.6)},
	["Parede_N__Azulejo"] = {V(0,2.71,-15.47), V(20,4.58,0.06)},
	["Parede_N__Ebanizada"] = {V(0,7,-15.225), V(20,14,0.55)},
	["Parede_N__Nogueira"] = {V(0,11.74,-15.28), V(20,4.28,0.44)},
	["Parede_N__Reboco"] = {V(0,7.2,-16), V(22,14.4,1)},
	["Parede_N__Talha"] = {V(5.5,10.35,-15.469), V(3.6,0.8,0.038)},
	["Parede_O__Azulejo"] = {V(-9.97,2.71,0), V(0.06,4.58,31)},
	["Parede_O__Ebanizada"] = {V(-9.725,7,0), V(0.55,14,31)},
	["Parede_O__Nogueira"] = {V(-9.78,11.74,0), V(0.44,4.28,31)},
	["Parede_O__Reboco"] = {V(-10.5,7.2,0), V(1,14.4,31)},
	["Parede_O__Talha"] = {V(-9.969,10.35,0), V(0.038,0.8,3.6)},
	["Parede_S__Azulejo"] = {V(0,2.71,15.47), V(20,4.58,0.06)},
	["Parede_S__Ebanizada"] = {V(0,7,15.225), V(20,14,0.55)},
	["Parede_S__Nogueira"] = {V(0,11.74,15.28), V(20,4.28,0.44)},
	["Parede_S__Reboco"] = {V(0,7.2,16), V(22,14.4,1)},
	["Parede_S__Talha"] = {V(5.5,10.35,15.469), V(3.6,0.8,0.038)},
	["Penteadeira__Calcario"] = {V(8.59,3.65,-8), V(2.7,0.9,7.9)},
	["Penteadeira__Ebanizada"] = {V(8.665,0.175,-8), V(2.55,0.35,7.7)},
	["Penteadeira__Latao"] = {V(9.162,3.055,-8), V(1.317,2.831,5.004)},
	["Penteadeira__Marfim"] = {V(9.49,3.77,-8), V(0.271,0.1,5.171)},
	["Penteadeira__Nogueira"] = {V(8.69,1.775,-8), V(2.5,2.85,7.6)},
	["Penteadeira__Porcelana"] = {V(8.59,3.668,-8), V(2.032,0.495,6.232)},
	["Piso__Ebanizada"] = {V(0,-0.22,0), V(22,0.28,33)},
	["Piso__Ladrilho"] = {V(0,-0.04,0), V(20,0.08,31)},
	["Piso__Latao"] = {V(0,0.011,3.5), V(0.9,0.018,0.9)},
	["Porta_L_A__Ebanizada"] = {V(10.488,4.275,1.23), V(0.737,7.43,2)},
	["Porta_L_A__Latao"] = {V(10.5,4.25,0.44), V(0.947,0.16,0.26)},
	["Porta_L_A__Nogueira"] = {V(10.51,4.5,1.23), V(0.655,8.94,2.41)},
	["Porta_L_A__Talha"] = {V(10.517,4.275,1.23), V(0.735,7.25,1.82)},
	["Porta_L_B__Ebanizada"] = {V(10.488,4.275,-1.23), V(0.737,7.43,2)},
	["Porta_L_B__Latao"] = {V(10.5,4.25,-0.44), V(0.947,0.16,0.26)},
	["Porta_L_B__Nogueira"] = {V(10.51,4.5,-1.23), V(0.655,8.94,2.41)},
	["Porta_L_B__Talha"] = {V(10.517,4.275,-1.23), V(0.735,7.25,1.82)},
	["Porta_N_A__Ebanizada"] = {V(6.73,4.275,-15.988), V(2,7.43,0.737)},
	["Porta_N_A__Latao"] = {V(5.94,4.25,-16), V(0.26,0.16,0.947)},
	["Porta_N_A__Nogueira"] = {V(6.73,4.5,-16.01), V(2.41,8.94,0.655)},
	["Porta_N_A__Talha"] = {V(6.73,4.275,-16.017), V(1.82,7.25,0.735)},
	["Porta_N_B__Ebanizada"] = {V(4.27,4.275,-15.988), V(2,7.43,0.737)},
	["Porta_N_B__Latao"] = {V(5.06,4.25,-16), V(0.26,0.16,0.947)},
	["Porta_N_B__Nogueira"] = {V(4.27,4.5,-16.01), V(2.41,8.94,0.655)},
	["Porta_N_B__Talha"] = {V(4.27,4.275,-16.017), V(1.82,7.25,0.735)},
	["Porta_O_A__Ebanizada"] = {V(-10.488,4.275,-1.23), V(0.737,7.43,2)},
	["Porta_O_A__Latao"] = {V(-10.5,4.25,-0.44), V(0.947,0.16,0.26)},
	["Porta_O_A__Nogueira"] = {V(-10.51,4.5,-1.23), V(0.655,8.94,2.41)},
	["Porta_O_A__Talha"] = {V(-10.517,4.275,-1.23), V(0.735,7.25,1.82)},
	["Porta_O_B__Ebanizada"] = {V(-10.488,4.275,1.23), V(0.737,7.43,2)},
	["Porta_O_B__Latao"] = {V(-10.5,4.25,0.44), V(0.947,0.16,0.26)},
	["Porta_O_B__Nogueira"] = {V(-10.51,4.5,1.23), V(0.655,8.94,2.41)},
	["Porta_O_B__Talha"] = {V(-10.517,4.275,1.23), V(0.735,7.25,1.82)},
	["Porta_S_A__Ebanizada"] = {V(4.27,4.275,15.988), V(2,7.43,0.737)},
	["Porta_S_A__Latao"] = {V(5.06,4.25,16), V(0.26,0.16,0.947)},
	["Porta_S_A__Nogueira"] = {V(4.27,4.5,16.01), V(2.41,8.94,0.655)},
	["Porta_S_A__Talha"] = {V(4.27,4.275,16.017), V(1.82,7.25,0.735)},
	["Porta_S_B__Ebanizada"] = {V(6.73,4.275,15.988), V(2,7.43,0.737)},
	["Porta_S_B__Latao"] = {V(5.94,4.25,16), V(0.26,0.16,0.947)},
	["Porta_S_B__Nogueira"] = {V(6.73,4.5,16.01), V(2.41,8.94,0.655)},
	["Porta_S_B__Talha"] = {V(6.73,4.275,16.017), V(1.82,7.25,0.735)},
	["Radiador__Ferro"] = {V(-9.35,0.18,-6.8), V(0.28,0.36,4.28)},
	["Radiador__FerroPintado"] = {V(-9.35,1.875,-6.8), V(0.4,3.05,4.6)},
	["Radiador__Latao"] = {V(-9.645,0.65,-4.17), V(0.71,0.104,0.66)},
	["Radiador__Linho"] = {V(-9.34,2.91,-7.3), V(0.52,1.42,1.6)},
	["Teto__Nogueira"] = {V(0,13.55,0), V(20,0.9,31)},
	["Teto__Reboco"] = {V(0,14.2,0), V(22,0.4,33)},
	["Vaso__Ebanizada"] = {V(-8.894,8.85,9), V(0.012,0.9,2.3)},
	["Vaso__Ferro"] = {V(-9.55,7.75,9), V(0.9,0.9,2.32)},
	["Vaso__Latao"] = {V(-9.258,4.805,9.517), V(0.565,6.79,1.215)},
	["Vaso__Marfim"] = {V(-9,4.72,10.1), V(0.22,0.52,0.22)},
	["Vaso__Nogueira"] = {V(-8.735,5.61,9), V(2.53,7.78,2.8)},
	["Vaso__Porcelana"] = {V(-8.75,0.875,9), V(2.5,1.75,1.48)},
	["Vaso__Talha"] = {V(-8.874,8.85,9), V(0.028,0.9,2.3)},
}
local PORTAS = {
	N = {ponto=V(5.5,0,-16.5), fora=V(0,0,-1)},
	S = {ponto=V(5.5,0,16.5), fora=V(0,0,1)},
	L = {ponto=V(11,0,0), fora=V(1,0,0)},
	O = {ponto=V(-11,0,0), fora=V(-1,0,0)},
}
local DOBRADICAS = {
	["Porta_L_A"] = V(10.51,0,2.455),
	["Porta_L_B"] = V(10.51,0,-2.455),
	["Porta_N_A"] = V(7.955,0,-16.01),
	["Porta_N_B"] = V(3.045,0,-16.01),
	["Porta_O_A"] = V(-10.51,0,-2.455),
	["Porta_O_B"] = V(-10.51,0,2.455),
	["Porta_S_A"] = V(3.045,0,16.01),
	["Porta_S_B"] = V(7.955,0,16.01),
}
local COLISOES = {
	{"COL_Piso", CF(0,-0.5,0,1,0,0,0,1,0,0,0,1), V(22,1,33)},
	{"COL_Teto", CF(0,14.5,0,1,0,0,0,1,0,0,0,1), V(22,1,33)},
	{"COL_Parede_N_1", CF(9.467,7.5,-16,-1,0,0,0,1,0,0,0,-1), V(3.065,15,1)},
	{"COL_Parede_N_2", CF(-3.967,7.5,-16,-1,0,0,0,1,0,0,0,-1), V(14.065,15,1)},
	{"COL_Parede_N_3", CF(5.5,12,-16,-1,0,0,0,1,0,0,0,-1), V(4.87,6,1)},
	{"COL_Parede_S_1", CF(-3.968,7.5,16,1,0,0,0,1,0,0,0,1), V(14.065,15,1)},
	{"COL_Parede_S_2", CF(9.468,7.5,16,1,0,0,0,1,0,0,0,1), V(3.065,15,1)},
	{"COL_Parede_S_3", CF(5.5,12,16,1,0,0,0,1,0,0,0,1), V(4.87,6,1)},
	{"COL_Parede_L_1", CF(10.5,7.5,8.968,0,0,1,0,1,0,-1,0,0), V(13.065,15,1)},
	{"COL_Parede_L_2", CF(10.5,7.5,-8.968,0,0,1,0,1,0,-1,0,0), V(13.065,15,1)},
	{"COL_Parede_L_3", CF(10.5,12,0,0,0,1,0,1,0,-1,0,0), V(4.87,6,1)},
	{"COL_Parede_O_1", CF(-10.5,7.5,-8.968,0,0,-1,0,1,0,1,0,0), V(13.065,15,1)},
	{"COL_Parede_O_2", CF(-10.5,7.5,8.968,0,0,-1,0,1,0,1,0,0), V(13.065,15,1)},
	{"COL_Parede_O_3", CF(-10.5,12,0,0,0,-1,0,1,0,1,0,0), V(4.87,6,1)},
	{"COL_Banheira", CF(-4.608,1.675,-13,1,0,0,0,1,0,0,0,1), V(7.952,3.35,4.256)},
	{"COL_Penteadeira", CF(8.59,2.05,-8,0,0,1,0,1,0,-1,0,0), V(7.9,4.1,2.7)},
	{"COL_ArmarioToalhas", CF(8.59,4.725,9.6,0,0,1,0,1,0,-1,0,0), V(5.8,9.45,2.7)},
	{"COL_Vaso", CF(-8.8,0.95,9,0,0,-1,0,1,0,1,0,0), V(2,1.9,2.4)},
	{"COL_Cesto", CF(-8.2,1.35,5.4,1,0,0,0,1,0,0,0,1), V(2.1,2.7,2.1)},
	{"COL_Carrinho", CF(-2.6,2.1,14.1,1,0,0,0,1,0,0,0,1), V(3.4,4.2,2.3)},
	{"COL_Biombo_0", CF(-7.05,3.7,13.65,0.316,0,0.949,0,1,0,-0.949,0,0.316), V(2.846,7.4,0.3)},
	{"COL_Biombo_1", CF(-8.1,3.7,11.65,-0.918,0,0.398,0,1,0,-0.398,0,-0.918), V(3.27,7.4,0.3)},
	{"COL_Radiador", CF(-9.3,1.6,-6.8,0,0,-1,0,1,0,1,0,0), V(4.8,3.2,0.9)},
	{"COL_Banco", CF(-0.4,1,-10.4,1,0,0,0,1,0,0,0,1), V(1.9,2,1.9)},
}
local LUZES = {
	{nome="Luar_janela", tipo="Spot", pos=V(-5,10.5,-14.7), dir=V(0.15,-0.82,0.55), cor=C3(150,171,209), brilho=1.1, alcance=32, sombra=true, angulo=62},
	{nome="Arandela_espelhos", tipo="Point", pos=V(9.19,7.75,-8), dir=nil, cor=C3(255,181,122), brilho=0.75, alcance=13, sombra=true, angulo=0},
	{nome="Vela_banquinho", tipo="Point", pos=V(-0.15,2.85,-10.5), dir=nil, cor=C3(255,158,82), brilho=0.55, alcance=10, sombra=true, angulo=0},
	{nome="Lampada_central", tipo="Point", pos=V(0,9.4,1.5), dir=nil, cor=C3(255,191,128), brilho=1.25, alcance=24, sombra=true, angulo=0},
	{nome="Reflexo_no_azulejo", tipo="Point", pos=V(2,3,5), dir=nil, cor=C3(230,171,128), brilho=0.35, alcance=20, sombra=false, angulo=0},
	{nome="Reflexo_na_banheira", tipo="Point", pos=V(-5,6,-9), dir=nil, cor=C3(161,178,214), brilho=0.25, alcance=14, sombra=false, angulo=0},
}
local PONTOS = {
	{nome="Totem_Banheira", pos=V(-5,0.75,-13), tipo="totem", movel="Banheira", deitado=true, giro=90},
	{nome="Dado_Penteadeira_E", pos=V(8.39,0.5,-6.175), tipo="dado", movel="Penteadeira_E"},
	{nome="Dado_Penteadeira_D", pos=V(8.39,0.5,-9.825), tipo="dado", movel="Penteadeira_D"},
	{nome="Dado_Penteadeira_G1", pos=V(8.54,1.96,-8), tipo="dado", movel="Penteadeira_G"},
	{nome="Dado_Penteadeira_G2", pos=V(8.54,0.61,-8), tipo="dado", movel="Penteadeira_G"},
	{nome="Dado_Armarinho", pos=V(9.44,6.16,-10.4), tipo="dado", movel="Armarinho"},
	{nome="Totem_ArmarioToalhas", pos=V(8.74,0.6,9.6), tipo="totem", movel="ArmarioToalhas"},
	{nome="Dado_ArmarioToalhas", pos=V(8.64,7.1,8.7), tipo="dado", movel="ArmarioToalhas"},
	{nome="Dado_Descarga", pos=V(-9.45,8.32,9.3), tipo="dado", movel="Descarga"},
	{nome="Dado_Cesto", pos=V(-8.2,0.25,5.4), tipo="dado", movel="Cesto"},
	{nome="Totem_Carrinho", pos=V(-2.6,3.68,14.1), tipo="totem"},
	{nome="Totem_Atras_do_biombo", pos=V(-8.7,0,13.4), tipo="totem"},
	{nome="Dado_Radiador", pos=V(-9.35,3.42,-5.6), tipo="dado"},
}
local MOVEIS = {
	{id="Banheira", rotulo="Banheira", interior={CF(-5,1.9,-13,1,0,0,0,1,0,0,0,1), V(6.272,2.3,2.912)}, partes={
		{grupo="Abre_Banheira_Tampa", tipo="giro", pivo=V(-5,3.21,-15.083), eixo=V(1,0,0), angulo=-80},
	}},
	{id="Penteadeira_E", rotulo="Penteadeira", interior={CF(8.69,1.85,-5.575,0,0,1,0,1,0,-1,0,0), V(2.25,2.6,2.2)}, partes={
		{grupo="Abre_Penteadeira_E_Porta", tipo="giro", pivo=V(7.44,0,-4.4), eixo=V(0,1,0), angulo=100},
	}},
	{id="Penteadeira_D", rotulo="Penteadeira", interior={CF(8.69,1.85,-10.425,0,0,1,0,1,0,-1,0,0), V(2.25,2.6,2.2)}, partes={
		{grupo="Abre_Penteadeira_D_Porta", tipo="giro", pivo=V(7.44,0,-11.6), eixo=V(0,1,0), angulo=-100},
	}},
	{id="Penteadeira_G", rotulo="Gaveta da penteadeira", interior={CF(8.69,1.6,-8,0,0,1,0,1,0,-1,0,0), V(2.2,2.4,2.2)}, partes={
		{grupo="Abre_Penteadeira_G_Gaveta1", tipo="gaveta", curso=V(-1.512,0,0), leva={V(8.54,2.51,-8), V(2.04,1.12,2)}},
		{grupo="Abre_Penteadeira_G_Gaveta2", tipo="gaveta", curso=V(-1.512,0,0), leva={V(8.54,1.125,-8), V(2.04,1.05,2)}},
	}},
	{id="Armarinho", rotulo="Armarinho do espelho", interior={CF(9.44,6.85,-10.1,0,0,1,0,1,0,-1,0,0), V(2.7,4.1,0.7)}, partes={
		{grupo="Abre_Armarinho_Porta", tipo="giro", pivo=V(8.92,0,-11.55), eixo=V(0,1,0), angulo=-105},
	}},
	{id="ArmarioToalhas", rotulo="Armario de toalhas", interior={CF(8.64,3.3,9.6,0,0,1,0,1,0,-1,0,0), V(4.8,5.3,2.3)}, partes={
		{grupo="Abre_ArmarioToalhas_PortaE", tipo="giro", pivo=V(7.36,0,12), eixo=V(0,1,0), angulo=100},
		{grupo="Abre_ArmarioToalhas_PortaD", tipo="giro", pivo=V(7.36,0,7.2), eixo=V(0,1,0), angulo=-100},
	}},
	{id="Descarga", rotulo="Caixa da descarga", interior={CF(-9.45,8.85,9,0,0,-1,0,1,0,1,0,0), V(2.5,1.1,0.9)}, partes={
		{grupo="Abre_Descarga_Tampa", tipo="giro", pivo=V(-9.95,9.65,9), eixo=V(0,0,1), angulo=80},
	}},
	{id="Cesto", rotulo="Cesto de roupa", interior={CF(-8.2,1.3,5.4,1,0,0,0,1,0,0,0,1), V(1.6,2.1,1.6)}, partes={
		{grupo="Abre_Cesto_Tampa", tipo="giro", pivo=V(-9.26,2.47,5.4), eixo=V(0,0,1), angulo=95},
	}},
}

-- ================================================================== utilitarios
local avisos, linhas = {}, {}
local function info(...) table.insert(linhas, table.concat({ ... }, " ")) end
local function aviso(...) table.insert(avisos, table.concat({ ... }, " ")) end
local recording
pcall(function() recording = ChangeHistoryService:TryBeginRecording("Invokyr instalar Banheiro") end)

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
local function ehBanheiro(m)
	if not m:IsA("Model") or m:GetAttribute("PecaInvokyr") then return false end
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("MeshPart") and (chave(d.Name) == "banheiraferropintado" or string.gsub(chave(d.Parent.Name), "node$", "") == "banheiraferropintado") then return true end
	end
	return false
end
local importado
local sel = Selection:Get()
if #sel == 1 and ehBanheiro(sel[1]) then importado = sel[1] end
if not importado then
	for _, m in ipairs(workspace:GetChildren()) do
		if ehBanheiro(m) then importado = m end
	end
end
if not importado then
	error("[Invokyr] Nao achei o Banheiro importado. Importe o Banheiro.glb (Home > Import 3D) e rode de novo.")
end

local indice = {}
for _, p in ipairs(importado:GetDescendants()) do
	if p:IsA("MeshPart") then
		indice[chave(p.Name)] = p
		local pai = string.gsub(chave(p.Parent.Name), "node$", "")
		if pai ~= "" and not indice[pai] then indice[pai] = p end
	end
end

-- referencia: o piso (centro) e a banheira (fora do centro) dao posicao e direcao da importacao
local piso = indice[chave("Piso__Ladrilho")]
local banheira = indice[chave("Banheira__FerroPintado")]
if not (piso and banheira) then error("[Invokyr] A importacao nao tem o piso ou a banheira. Importe todas as malhas, sem unir.") end
local ePiso, eBan = PECAS["Piso__Ladrilho"], PECAS["Banheira__FerroPintado"]
if math.abs(piso.Size.X - ePiso[2].X) > 0.3 or math.abs(piso.Size.Z - ePiso[2].Z) > 0.3 then
	error(("[Invokyr] O piso veio com %.2f x %.2f (esperado %.2f x %.2f). Importe com Scale Unit = Stud e Scale = 1.")
		:format(piso.Size.X, piso.Size.Z, ePiso[2].X, ePiso[2].Z))
end
local esp = eBan[1] - ePiso[1]
local obs = banheira.Position - piso.Position
local giro = math.atan2(obs.X, obs.Z) - math.atan2(esp.X, esp.Z)
local origem = CFrame.new(piso.Position) * CFrame.Angles(0, giro, 0) * CFrame.new(-ePiso[1])

-- ================================================================== 2. montar a sala (na origem do mundo)
local sala = Instance.new("Model")
sala.Name = "Banheiro"
sala:SetAttribute("PecaInvokyr", true)
sala:SetAttribute("CelulasX", CELULAS[1])
sala:SetAttribute("CelulasZ", CELULAS[2])
sala:SetAttribute("Tipo", "Comum")
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
local BRILHA = { ["Lampada__VidroMel"] = C3(255, 196, 140), ["Arandelas__VidroMel"] = C3(255, 186, 128) }
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
	s.Color = l.cor; s.Brightness = l.brilho; s.Range = l.alcance; s.Shadows = l.sombra
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

-- ================================================================== 4. guardar, previa e limpeza
local carimbo = os.date("%Y%m%d_%H%M%S")
if backup:FindFirstChild("Banheiro_" .. carimbo) then carimbo ..= "_" .. math.random(100, 999) end
local antiga = biblioteca:FindFirstChild("Banheiro")
local previaAntiga = salasMapa:FindFirstChild("Previa_Banheiro") or workspace:FindFirstChild("Previa_Banheiro")
local historico
if antiga or previaAntiga then
	historico = novo(backup, "Banheiro_" .. carimbo)
	if antiga then antiga.Parent = historico end
	if previaAntiga then previaAntiga.Parent = historico end
end
sala.Parent = biblioteca

local previa = sala:Clone()
previa.Name = "Previa_Banheiro"
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

importado.Name = "Banheiro_importacao_" .. carimbo
importado.Parent = historico or novo(backup, "Banheiro_" .. carimbo)

-- ================================================================== relatorio
local nVis = 0
for _, p in ipairs(sala:GetDescendants()) do if p:IsA("MeshPart") then nVis += 1 end end
info(("Banheiro guardado em ServerStorage > Invokyr_Salas | pecas: %d de %d"):format(nVis, 160))
local nPartes = 0
for _ in pairs(grupos) do nPartes += 1 end
info(("Moveis que abrem: %d partes em %d moveis | esconderijos: %d de totem, %d de dado"):format(nPartes, #MOVEIS, nTotem, nDado))
info("Previa em Workspace > Invokyr > Mansao > Salas > Previa_Banheiro, em " .. tostring(CONFIG.PREVIA))
Selection:Set({ previa })
pcall(function()
	workspace.CurrentCamera.CFrame = previa:GetPivot() * CFrame.lookAt(V(5.5, 5.2, 14.5), V(-3, 4, -10))
end)
if recording then pcall(function() ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit) end) end
print("========== INVOKYR 16: BANHEIRO ==========")
for _, l in ipairs(linhas) do print("  " .. l) end
if #avisos == 0 then print("  Sem avisos.") else for _, a in ipairs(avisos) do warn("  AVISO: " .. a) end end
print("Para andar na sala: Test > setinha do Play > Play Here (a camera ja esta dentro da previa).")
