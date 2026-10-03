# Validación de los 118 targets Garmin

SDK oficial Connect IQ 9.2.0.

La lista procede exclusivamente de la segunda auditoría de navegación. Se conservan los hashes de sus cuatro artefactos en `audit-provenance.json`.

**118 IDs únicos: 89 FULL_PHYSICAL y 29 TOUCH. 236 compilaciones correctas, 0 warnings y 0 errores. 2513 tests nativos PASS, 0 fallos y 0 errores.**

Se comprueban lista exacta, exclusiones, selección exclusiva de delegate y suite, tamaños de launcher, UUID estable, minApiLevel 2.4.0 y versión 1.0.0. El código Monkey C no cambia respecto al commit base `68399591287cb6650887e26b83a04bd9241b90f6`.

## Por producto

Los bytes de PRG son tamaños de archivo; no equivalen al uso de RAM en ejecución. RAM y límite de PRG proceden de `compiler.json`. Los 46 perfiles que publican límite de archivo admiten ambos binarios; los otros 72 se registran con límite desconocido (`null` en targets.json). `monkeydo` puede devolver 1 pese a PASS: se exige el resumen nativo y la traza de política.

Los resultados por producto, tamaños de PRG y límites oficiales se conservan en [validation.csv](validation.csv), como referencia para futuras regresiones.


## Renderizado representativo

Una captura de producción por cada combinación relevante de forma, resolución y política: 20 grupos. Se observa el estado 1–1 con tarjetas completas, números legibles y RESET centrado; sin clipping ni solapamientos. No se requieren overrides visuales. Las capturas y logs permanecen bajo `bin/compatibility118/`, ignorados por Git.

| Forma | Resolución | Política | Representante | Resultado |
| --- | --- | --- | --- | --- |
| rectangle | 240×240 | TOUCH | venusq | PASS |
| rectangle | 320×360 | TOUCH | venusq2 | PASS |
| rectangle | 448×486 | TOUCH | venux1 | PASS |
| round | 208×208 | FULL_PHYSICAL | fr55 | PASS |
| round | 218×218 | FULL_PHYSICAL | fenix5s | PASS |
| round | 218×218 | TOUCH | legacyherocaptainmarvel | PASS |
| round | 240×240 | FULL_PHYSICAL | d2charlie | PASS |
| round | 240×240 | TOUCH | approachs60 | PASS |
| round | 260×260 | FULL_PHYSICAL | fenix6 | PASS |
| round | 260×260 | TOUCH | approachs62 | PASS |
| round | 280×280 | FULL_PHYSICAL | descentmk2 | PASS |
| round | 360×360 | FULL_PHYSICAL | fr265s | PASS |
| round | 360×360 | TOUCH | venu2s | PASS |
| round | 390×390 | FULL_PHYSICAL | descentg2 | PASS |
| round | 390×390 | TOUCH | approachs50 | PASS |
| round | 416×416 | FULL_PHYSICAL | d2mach1 | PASS |
| round | 416×416 | TOUCH | d2airx10 | PASS |
| round | 454×454 | FULL_PHYSICAL | d2mach2 | PASS |
| round | 454×454 | TOUCH | approachs7047mm | PASS |
| round | 466×466 | FULL_PHYSICAL | fenix9pro51mm | PASS |

## Launcher

Un PNG compartido, base 40×40, ocho qualifiers oficiales de geometría y 29 excepciones. Se reutilizan 35, 60 y 70; se añaden XML mínimos para 30, 36, 40×33, 54, 56, 61 y 65. No se duplican imágenes ni se modifica el marcador.

| Dimensiones | Productos |
| --- | ---: |
| 30×30 | 3 |
| 35×35 | 5 |
| 36×36 | 4 |
| 40×33 | 1 |
| 40×40 | 54 |
| 54×54 | 8 |
| 56×56 | 2 |
| 60×60 | 22 |
| 61×61 | 1 |
| 65×65 | 12 |
| 70×70 | 6 |

## Exportación Store

Exportación oficial correcta: `ScoreCount-118.iq`, 2386952 bytes, SHA-256 `344ddf8e9c20346713ac5ecdeb9459c14740022cae18ac058b64cc6ad204e0cd`. Los 118 product IDs corresponden exactamente a 201 part numbers oficiales: se comprueban sus PRG y, mediante debug.xml, la política exclusiva de cada variante. 0 warnings y 0 errores. El archivo .iq no se versiona ni se publica.

## Reproducir

Desde garmin/, con el simulador abierto y los 118 perfiles oficiales instalados. Configurar SDK, KEY, PROFILES y AUDIT con las rutas del entorno; la clave permanece fuera del repositorio:

```sh
python3 tools/verify_targets.py --profiles "$PROFILES" --audit "$AUDIT"
python3 tools/validate_compatibility.py build --sdk "$SDK" --key "$KEY" --profiles "$PROFILES"
python3 tools/render_compatibility.py --sdk "$SDK" --profiles "$PROFILES"
python3 tools/validate_compatibility.py test --sdk "$SDK" --key "$KEY" --profiles "$PROFILES"
python3 tools/build.py --sdk "$SDK" --key "$KEY" --export
```

Los builds se aíslan por dispositivo y se paralelizan; el simulador se utiliza en serie. El capturador X11 requiere Pillow, libX11 y libXtst. No ejecutar el capturador simultáneamente con las suites nativas.

## Pendiente de hardware físico

FULL_PHYSICAL clasifica disposición de botones, no garantiza entrega de releases del firmware. Validar UP/MENU, DOWN/música, START/hotkeys y BACK/LAP/LIGHT en los 89 targets; sin release no se sintetiza una acción. En los 29 TOUCH, comprobar botones/menús libres y entrega de tap/hold/RESET y swipes de salida. En los modelos con 128 KiB de RAM (lista en targets.json), comprobar consumo con historial lleno y scores largos. Los conteos de botones inferidos por familia en la auditoría necesitan confirmación física. Vibración, touch lock y persistencia real siguen pendientes. No se incluyen perfiles NEEDS_ADAPTATION o INCOMPATIBLE ni se certifica firmware físico mediante simulación.
