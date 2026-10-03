# Validación Garmin: políticas de entrada y RESET táctil

Validación del 3 de octubre de 2026 en el entorno local del usuario.
Solo se modifican archivos de `garmin/`. No se modifica `manifest.xml`, UUID,
`minApiLevel="2.4.0"`, productos declarados, Huawei ni almacenamiento del modelo.
No se realiza commit, push, merge ni publicación.

## Comportamiento final

Jungle selecciona una única implementación de `ScoreCountDelegate` por producto.
En FULL_PHYSICAL, UP/DOWN cortos suman y largos restan; START/ENTER corto ejecuta
UNDO y largo RESET. Las acciones físicas se ejecutan únicamente al release.
MENU se consume sin abrir vistas; BACK/LAP/LIGHT quedan libres.

En TOUCH, todos los callbacks físicos implementados devuelven `false`: no
puntúan ni ejecutan UNDO. Tampoco existe gesto táctil para deshacer.

Ambas políticas comparten tap azul/rojo para sumar, hold azul/rojo para restar
y tap inferior para RESET. Mantener la zona RESET no ejecuta ninguna acción.
La interfaz muestra únicamente `RESET` en una línea centrada. No hay etiquetas
secundarias ni fallback de texto. Se recuperan los límites originales del botón:
ancho 40%, alto 15%, origen (30%, 73%); las tarjetas y números se conservan.

RESET en 0–0 no escribe, crea historial ni vibra. El modelo conserva historial
interno en ambas políticas. Solo FULL_PHYSICAL permite deshacer un RESET desde
la interfaz, mediante START/ENTER corto, incluso después de reiniciar la app.

## Entorno

SDK oficial **Connect IQ 9.2.0**:
`/home/aitor/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-9.2.0-2026-06-09-92a1605b2/`.
Perfiles oficiales locales: `/home/aitor/.Garmin/ConnectIQ/Devices/`.
La clave local se pasa mediante `-y`; no se lee ni muestra su contenido.

## Compilaciones y tests nativos

Release y tests usan la misma política de producción. `tests.jungle` añade los
12 tests comunes y únicamente la suite específica del dispositivo. Un test
verifica y registra explícitamente `INPUT_POLICY` sobre el delegate real.

| Dispositivo | Política | Release | Tests compilados | Tests nativos |
| --- | --- | --- | --- | --- |
| fenix7 | FULL_PHYSICAL | OK, 0 warnings | OK, 0 warnings | 24 passes, 0 fallos, 0 errores |
| fenix7s | FULL_PHYSICAL | OK, 0 warnings | OK, 0 warnings | 24 passes, 0 fallos, 0 errores |
| epix2 | FULL_PHYSICAL | OK, 0 warnings | OK, 0 warnings | 24 passes, 0 fallos, 0 errores |
| fr255 | FULL_PHYSICAL | OK, 0 warnings | OK, 0 warnings | 24 passes, 0 fallos, 0 errores |
| venu2 | TOUCH | OK, 0 warnings | OK, 0 warnings | 13 passes, 0 fallos, 0 errores |
| vivoactive4 | TOUCH | OK, 0 warnings | OK, 0 warnings | 13 passes, 0 fallos, 0 errores |

Total: **122 ejecuciones**, **0 fallos y 0 errores**. Hay 25 tests distintos:
12 comunes, 12 FULL_PHYSICAL y 1 TOUCH. Las excepciones simuladas de
almacenamiento son parte de tests que pasan. `monkeydo` devuelve código 1 pese
al resumen `PASSED`; se comprueban el resumen nativo y la traza de política.

Los tests comunes verifican tap/hold de equipos, duplicados, protección de 200 ms,
tap RESET, RESET repetido sin escrituras/historial/háptica, persistencia del estado
reseteado, fuentes de datos inválidas, fallos de escritura, historial limitado y
zonas independientes. Las pruebas directas de UNDO del modelo no exponen un
control para TOUCH ni ejecutan UNDO mediante su interfaz.

La suite FULL_PHYSICAL conserva los umbrales 799/800 y 1499/1500 ms, release,
auto-repeat, releases huérfanos y duplicados, alias ENTER/START, solapamientos,
overflow, MENU durante UP largo, teclas libres, cero y fallos de escritura.
`physicalStartUndoesTouchResetAfterRestart` comprueba adicionalmente que tap
RESET resetea, un tap repetido no deshace y START corto recupera 1–1 después
de reconstruir el modelo.

La suite TOUCH exige que UP/DOWN/ENTER/START/MENU y ESC/LAP/LIGHT, los callbacks
básicos, páginas, modos, selección y BACK devuelvan `false`, sin cambios de
marcador, historial, escrituras o vibraciones. Los tests comunes comprueban que
los taps inferiores siempre ejecutan RESET, sin deshacer el historial.

Reproducción desde la raíz:

```sh
python3 garmin/tools/build.py --sdk /ruta/al/sdk --key /ruta/privada/developer_key.der
python3 garmin/tools/build.py --sdk /ruta/al/sdk --key /ruta/privada/developer_key.der --tests
/ruta/al/sdk/bin/monkeydo garmin/bin/ScoreCount-tests-fenix7.prg fenix7 -t
```

Repetir el último comando con cada producto actual.

## Validación visual e interacción del simulador

Se ejecutan los binarios release de producción de Fenix 7 (260 px), Fenix 7S
(240 px) y Venu 2 (416 px). Un controlador X11 externo genera taps en las zonas
reales del perfil oficial. No se instrumenta el código de estos binarios.

En los tres se inspeccionan capturas: aparece únicamente `RESET`, completo,
centrado y en una sola línea. No aparece ninguna etiqueta táctil de UNDO ni
indicación secundaria. Las strings base, española e inglesa contienen `Reset`;
se eliminan los recursos de la antigua interfaz dual tras revisar referencias.

En cada dispositivo se suma azul y rojo mediante taps, se observa 1–1 y se
pulsa RESET: el marcador pasa a 0–0. Otro tap RESET mantiene 0–0. En Fenix 7,
START corto después de esos taps devuelve 1–1 mediante UNDO físico.
Las escrituras y vibraciones del RESET redundante se verifican en tests nativos,
no se atribuyen a las capturas.

Las trazas instrumentadas de la validación física anterior siguen documentando
UP/DOWN/START cortos y largos, acción al release y UP largo sin abrir MENU.
Los handlers físicos no se han modificado en esta revisión. En la validación
anterior de Venu 2 también se observaron ENTER corto/largo sin puntuación,
MENU sin puntuación, swipe llegando a navegación y BACK cerrando la app.
Los flujos de la antigua zona inferior se sustituyen por las pruebas actuales.

Artefactos ignorados por Git bajo `garmin/bin/validation/`:

- `reset-only-release.log`, `reset-only-build-tests.log`: compilaciones actuales.
- `reset-only-tests-<dispositivo>.log`, `reset-only-test-results.json`: suites y políticas.
- `reset-only-<dispositivo>-ui.png`: vista final con RESET.
- `reset-only-<dispositivo>-seed.png`, `-reset.png`, `-repeat-reset.png`: 1–1 y RESET.
- `reset-only-fenix7-physical-undo.png`: UNDO mediante START corto.

## Limitaciones pendientes

No se ha probado hardware físico, vibración real, hotkeys ni entrega de releases
con firmware personal. La app no sintetiza una acción si falta el release.
El simulador no sustituye navegación y menús del firmware real. Persistencia e
historial en relojes físicos siguen pendientes. La guardia de 200 ms también
ignora un tap intencional muy rápido después de un hold; Garmin decide el umbral
del hold táctil. FR255 no tiene touchscreen: sus tests táctiles ejercitan los
handlers comunes, mientras que el uso real depende de FULL_PHYSICAL.

No se añaden dispositivos ni se adaptan Fenix 3, vivoactive 3, Instinct, Crossover
u otros perfiles pendientes.
