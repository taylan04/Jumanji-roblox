# Torre do Tabuleiro — versão 02
Data: 26/10/2026. Esta entrega é uma cena artística do Blender, não uma sala já importada no Roblox.

## Resultado
- Planta octogonal com aproximadamente 29 unidades entre paredes opostas.
- Cobertura radial real até 34,5 unidades, painéis de madeira, nervuras, quatro arcadas ogivais e óculo superior.
- Exatamente quatro pilares principais, com altura avaliada de 20,546 unidades.
- Bases, capitéis e ornamentos do pilar aprovado preservados. Apenas os trechos retos do fuste foram alongados, com anéis de transição e hera adicional.
- Quatro cópias da porta aprovada; oito folhas separadas com pivôs próprios.
- Mesa rústica central, tabuleiro original com quatro criaturas desenhadas em relevo, casas, peões e dois dados.
- Quatro estantes, livros nas laterais, oito lamparinas, lustre, gramas, raízes e folhas caídas.
- Luz fria nas janelas, luz quente nas lamparinas e névoa leve em coleção separada.
- As decorações se concentram nas diagonais e nos pilares, mantendo livres os caminhos cardeais.

O tabuleiro usa desenhos originais de cervo, aranha, serpente e coruja. Não utiliza imagens, modelos ou símbolos de Jumanji/Invokyr.

## Abrir no Blender
Abra assets/models/torre_tabuleiro_v02.blend. Não execute o gerador antigo gerar_torre_tabuleiro.py.
Cena ativa: T02 | Torre do Tabuleiro.
Numpad 0 mostra a câmera; F12 renderiza com a iluminação da cena.
Os PNGs entregues permitem avaliar sem esperar outro render.

Câmeras:
1. 01_Interior: vista vertical da arquitetura.
2. 02_Imersiva: vista mais próxima da altura do jogador.
3. 03_Tabuleiro: detalhes da mesa.
4. 04_Cobertura: teto e nervuras.

A coleção T02 | Névoa de prévia pode ser ocultada para examinar a geometria. O volume aparece em arame no viewport e não é um obstáculo físico para o jogo.
Material Preview pode usar uma iluminação diferente; o render é a referência para avaliar a atmosfera.

## Testar portas
Coleção 01 | Quatro portais aprovados.
Cada PortalNorth/East/South/West contém a cantaria e suas duas folhas.
Selecione DoorNorth_Left e use R, Z, Z, 88, Enter para girar em seu eixo local; na folha Right use -88.
Para as outras direções, também use o eixo LOCAL Z (pressionando Z duas vezes).
Ctrl+Z desfaz a mudança. Não salve sobre os modelos aprovados.

As portas abrem para fora da torre, para o espaço destinado às futuras regiões. Ainda não há corredores, totens ou programação de passagem ligados a este .blend.

## Organização e geração
Entrada: tools/blender/gerar_torre_medieval.py.
Módulos novos em tools/blender/torre:
- config.py: dimensões e densidade da névoa.
- assets.py: leitura e cópias dos modelos aprovados.
- architecture.py: paredes, janelas, piso, cobertura e arcadas.
- furniture.py: mesa, tabuleiro, livros e lamparinas.
- vegetation.py: raízes, heras, gramas e folhas.
- materials.py: materiais procedurais de estudo.
- geometry.py: malhas, perfis e UVs planares.
- preview.py: câmeras e luzes de avaliação.
- validate.py: verificações de pilares, portas, cobertura e contagem.

O gerador recusa substituir um arquivo existente. Para gerar outra versão na raiz do repositório:

~~~powershell
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --background --factory-startup --python-exit-code 1 --python tools\blender\gerar_torre_medieval.py -- --output assets\models\torre_tabuleiro_v03.blend --render
~~~

Use --draft para prévias menores; --views 1,2 seleciona as duas primeiras câmeras.
As fontes são assets/models/pilar_gotico.blend e assets/models/portal_estudo_v01.blend. São lidas e verificadas por hash; não são alteradas.

## Interface compacta
src/client/Controllers/UIController.luau substitui o painel de 320 x 124 pixels por avisos temporários, centralizados no topo e limitados à largura disponível.
- Turno: 5 a 6 segundos.
- Resultados: até 8 segundos.
- Avisos: 3 a 6 segundos.
- Desaparecimento suave de 0,35 segundo.
- Sem título fixo ou instrução de tecla E em telas móveis.
- Eventos e atributos de partida existentes foram mantidos.
- Timers antigos não apagam mensagens novas; conexões são desligadas ao reiniciar o controlador.

Backup: docs/backup/UIController_antes_torre02.luau.
No Studio, confirme o Script Sync e inicie um NOVO Play. Teste com dois clientes e emulação de celular; lance dados em sequência e confira o desaparecimento das mensagens.
Esta interface foi revisada em código, mas NÃO executada no Roblox Studio nesta entrega.

Referências de API consultadas:
https://create.roblox.com/docs/reference/engine/classes/CanvasGroup
https://create.roblox.com/docs/reference/engine/classes/ScreenGui

## Validação e limites
Blender 5.2.3 LTS realmente executado. A primeira execução revelou um problema com referências temporárias a materiais avaliados; a combinação passou a utilizar os materiais originais, e a geração concluiu.
O JSON ao lado do .blend registra:
- 4 pilares e 8 folhas;
- as quatro portas fechadas interceptam os raios de teste e, abertas, liberam os trajetos;
- 8 raios de cima atingem a cobertura;
- 52 objetos de malha, sem contar a névoa;
- 527.456 triângulos avaliados na cena inteira, contando as repetições.

A geometria foi consolidada em módulos, preservando as folhas como objetos independentes. Ainda é um modelo artístico de alta resolução: 527 mil triângulos não são um orçamento mobile aprovado.
Antes da publicação: preparar LODs, reduzir geometria de repetição, refazer/organizar UVs para atlas, assar materiais PBR, criar colisões simples e medir no Roblox. Os materiais procedurais e as luzes do Blender não são transferidos automaticamente com aparência idêntica.
Os shaders de prévia usam coordenadas de objeto; há peças herdadas sem UV de produção. Não considerar esta entrega pronta para exportação final.

Nenhuma textura externa foi baixada. Nenhum commit/push foi realizado. Lobby, grupos, totens, monstros e a mecânica definitiva de escolha das portas permanecem fora desta etapa.

Sugestão de commit após avaliação: feat: criar torre medieval do tabuleiro

