# INVOKYR — Coleção de totens

Cinco objetos 3D completos inspirados na referência: Fogo, Gelo, Teleporte, Raio e Diamante Raro. Cada um tem coroa, símbolo e cores próprios. Frente orientada para -Y no Blender; base em Z=0. As costas também foram modeladas.

## Qual arquivo usar

- `Invokyr_Totens.blend`: arquivo mestre editável com cinco coleções separadas, materiais e imagens incorporados. A coleção `STUDIO_preview_only` contém somente chão, câmera e iluminação da apresentação.
- `importar/`: um diretório por totem, com `.gltf`, `.bin` e texturas PNG. Mantenha esses arquivos juntos. Use o `.gltf` na importação do Studio.
- `renders/`: imagens renderizadas dos modelos reais.
- `scripts/`: construção e exportação reproduzíveis no Blender 5.2. Para reconstruir a versão final, execute `build.py`, `export_maps.py`, `refine.py` (uma única vez após a reconstrução), `render.py` e `validate.py`, nessa ordem. `package.py` cria a folha de apresentação e o ZIP com Python/Pillow.
- `geometry.json`: contagens por modelo e por malha.

Não é necessário juntar os arquivos Blender dos monstros e totens para montar o jogo. O Blender é o arquivo de autoria; o Roblox Studio reúne os modelos importados no mapa. Um único Blender pode conter vários objetos, e cada objeto pode ser exportado separadamente, como neste pacote.

## Importação no Roblox Studio

1. Extraia o ZIP inteiro.
2. No Studio, abra **File → Import** e selecione, por exemplo, `importar/01_Fogo/01_Fogo.gltf`.
3. Examine a prévia e eventuais avisos; importe as partes como um único Model. Não use configuração de avatar/R15: são objetos estáticos.
4. Confira o tamanho contra seu personagem e ajuste a escala do Model inteiro. As dimensões do Blender são de autoria; não presuma conversão automática de metros para studs.
5. Posicione o modelo no tabuleiro. Para peças fixas, configure Anchored nas MeshParts; para objetos coletáveis, a ligação ao personagem e as colisões dependem do sistema do seu jogo.
6. Repita para os outros totens. Você também pode usar a fila de importação.

O modelo tem várias MeshParts por material/lote. Isso preserva as formas detalhadas respeitando o limite documentado de 20.000 triângulos por malha individual. Esse limite não significa que os objetos precisam ser quadrados, nem é um limite de 20.000 para o modelo inteiro.

## Aparência e poderes

Os arquivos incluem geometria, UVs e imagens para cor, metalicidade, rugosidade e emissão. As imagens de metalicidade e rugosidade são valores uniformes por material; os detalhes esculpidos são geometria real, sem normal map. A aparência final depende da iluminação do seu mapa. O brilho não deve ser confundido com luz que ilumina o ambiente: configure iluminação/efeitos no Studio conforme necessário e confira a importação dos materiais emissivos.

Fogo, chão escorregadio, teleporte e raios são comportamentos que precisam ser programados no Roblox. Este pacote entrega os objetos visuais, sem scripts de poderes, partículas, áudio ou sistema de coleta. A raridade do diamante também deve ser definida na lógica de distribuição do jogo.

## Fontes oficiais consultadas em 6 de novembro de 2026

- Importador, formatos, hierarquia e fila: https://create.roblox.com/docs/studio/importer
- Geometria e limite por malha: https://create.roblox.com/docs/art/modeling/specifications
- Materiais e mapas PBR: https://create.roblox.com/docs/art/modeling/surface-appearance

Os arquivos são verificados no Blender e por reimportação glTF. A importação na sua conta do Roblox Studio não foi realizada nesta entrega.
