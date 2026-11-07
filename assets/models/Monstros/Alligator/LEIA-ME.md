# ALLIGATOR — criatura 3D para Blender

Abra `alligator.blend` no Blender 5.2.3 LTS e selecione a cena `Alligator_Presentation`, caso necessário. Numpad 0 alterna a câmera; botão do meio orbita livremente; Espaço reproduz a rotação de 360 graus em 240 quadros (10 segundos).

## Modelo
Corpo baixo e musculoso, focinho achatado, mandíbula aberta com dentes individuais, palato e língua, olhos âmbar com pupilas verticais, quatro membros com dedos e garras, cauda longa curva e fileiras de placas ósseas. As escamas maiores e os escudos dorsais possuem geometria real; os materiais procedurais acrescentam variação e microtextura.

As partes estão organizadas nas coleções AG_Body, AG_Head, AG_UpperJaw, AG_LowerJaw, AG_Teeth, AG_Mouth, AG_Eyes, AG_Limbs, AG_Feet, AG_Tail e AG_DorsalArmor. A coleção AG_Studio contém piso, iluminação e câmera. Os pivôs das mandíbulas são preparação para edição; não constituem um rig completo.

## Arquivos
- `alligator.blend`: modelo, materiais, iluminação e câmera animada.
- `renders/01_front.png` a `08_front_right.png`: oito vistas do mesmo modelo.
- `renders/09_head_detail.png`: render aproximado da cabeça.
- `eight_views.jpg`: prancha das oito vistas.
- `geometry.json`: contagem de vértices, polígonos e triângulos antes/depois dos modificadores.
- `validation.json`: verificação de reabertura, coordenadas, índices, câmera, dentes e referência.
- `source/reference.png`: imagem fornecida, também empacotada no Blender.
- `scripts`: gerador, funções geométricas e renderização reproduzível.

## Escopo para o jogo
Esta é a matriz detalhada para aprovação visual no Blender. A anotação de aproximadamente 25.000 triângulos na referência é uma meta de versão otimizada; esta entrega tem cerca de 219.000 triângulos de base, com a contagem exata registrada no JSON. Ela ainda exige retopologia/otimização, UVs e bake, rig e testes de deformação antes de virar o asset de jogo. Nada foi importado no Roblox Studio e nenhum arquivo da planta anterior foi alterado.

A referência guiou anatomia, postura e paleta; não se certifica equivalência exata à ilustração. A escultura irregular da pele e as transições entre placas ainda podem receber direção artística adicional. As imagens entregues mostram o resultado real do arquivo 3D.

## Regerar
Execute no PowerShell, dentro desta pasta:

```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --background --python '.\scripts\generate_alligator.py' -- --preview
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --background --python '.\scripts\render_validate.py'
python '.\scripts\contact_sheet.py'
```

O gerador cria uma nova cena sem apagar objetos de outras cenas; utilize um processo novo do Blender para reprodução limpa. Ao substituir o arquivo de saída, preserva uma cópia `.previous.blend`. Os renders são atualizados. Os materiais são internos e não dependem de downloads de texturas.

