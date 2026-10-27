# Planta carnívora — estudo 3D para Jumanji-roblox

## Abrir
Abra `carnivorous_plant.blend` no Blender 5.2.3 LTS. A cena é `CarnivorousPlant_Presentation`.
Numpad 0 alterna a câmera; botão do meio orbita livremente. As coleções CP_ separam corpo, mandíbulas, dentes, língua, bulbo, raízes, membros, cipós, folhas, espinhos e estúdio.

A timeline contém uma volta de câmera em 240 quadros a 24 fps (10 segundos). Pressione Espaço para reproduzir. A criatura não muda de anatomia entre as vistas. Não foi renderizado um vídeo de 240 quadros.

## Entrega
- Projeto Blender com geometria real, materiais procedurais internos e referência empacotada.
- `renders/`: oito PNGs de 1200 × 800, calculados pelo Cycles.
- `eight_views.jpg`: comparação das oito vistas.
- `scripts/generate_carnivorous_plant.py`: gerador determinístico com funções por região anatômica.
- `scripts/validate_project.py`: reabertura e verificação de geometria, referência, animação e presença das oito imagens.
- `scripts/contact_sheet.py`: montagem das oito vistas; usa Pillow.
- `geometry.json` e `validation.json`: contagens e resultados da verificação.

## Geometria e materiais
A malha base da cena contém 337.935 vértices e 317.340 polígonos, em 2.350 objetos de malha, incluindo o piso. A espessura das folhas e das mandíbulas acrescenta geometria avaliada pelos modificadores. Há 92 dentes individuais, seis membros principais e seis cipós com lâminas curvas. São 11 materiais da criatura e um do piso. Não há dependência de texturas externas: cores, variações e bump são procedurais. A imagem de referência não é usada para simular o volume.

Mandíbula superior, mandíbula inferior e língua têm pivôs identificáveis. Esses pivôs são preparação estrutural; não representam um rig terminado. O fechamento da boca, skinning e deformações não foram implementados nem validados.

## Avaliação visual e limites
Esta entrega é uma interpretação procedural tridimensional da referência, não uma reprodução AAA fiel. Preserva a boca aberta com duas fileiras de dentes por mandíbula, o interior profundo, a língua, a coroa de folhas, o corpo vegetal baixo, membros enraizados, cipós com folhas serrilhadas e a cápsula posterior com sépalas e espinhos.

Ainda há diferenças importantes: distribuição mais regular de folhas e dentes, casca menos esculpida, transições entre peças aparentes, proporções dos membros e das mandíbulas diferentes e menos riqueza de microdetalhe e assimetria do que a ilustração. A qualidade visual solicitada na referência não foi integralmente alcançada. Para aproximá-la mais, a próxima etapa adequada é escultura dirigida das formas, integração das transições e pintura localizada de materiais. O modelo é editável para esse trabalho.

Durante a conferência foram corrigidos os materiais que inicialmente saíram brancos, a interseção do corpo com a cavidade oral, o cruzamento dos dedos os pivôs das mandíbulas e o perfil lateral raso da cabeça. Não se afirma que todas as interseções entre raízes e folhas foram eliminadas; várias sobreposições fazem parte da composição vegetal.

Não é um asset pronto para Roblox: não possui retopologia, UVs de produção, bake, colisão ou rig. Nenhum arquivo Luau, sistema do jogo ou projeto do Roblox Studio foi alterado. Não houve exportação para Roblox nem commit.

## Regerar
No PowerShell, dentro desta pasta:

```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --background --python '.\scripts\generate_carnivorous_plant.py' -- --render
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --background --python '.\scripts\validate_project.py'
python '.\scripts\contact_sheet.py'
```

O gerador cria uma nova cena, sem apagar objetos de outras cenas. Ao encontrar o arquivo de saída, preserva uma cópia `.previous.blend`. Para uma execução limpa e reproduzível, use o comando em um processo novo do Blender. As oito renderizações são substituídas ao regerar. O gerador foi executado no Blender 5.2.3 LTS; o Blender emitiu avisos de futura depreciação de `use_nodes` para a versão 6.0, sem impedir seu funcionamento em 5.2.3.

