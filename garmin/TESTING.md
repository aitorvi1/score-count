# Validación Garmin

Realizada el **2 de octubre de 2026** con compilador y simulador oficiales
**Connect IQ SDK 9.2.0**, Java 17 y Ubuntu 22.04 en un contenedor con Xvfb.
Esta revisión de controles y diseño modifica únicamente archivos de `garmin/`.
Los archivos Huawei y el README principal conservan el estado de la implementación anterior.

## Procedencia de perfiles

SDK y documentación descargados directamente de `developer.garmin.com`.
La descarga directa de perfiles desde `api.gcs.garmin.com` se intentó de nuevo
tras el cambio de red solicitado, pero seguía bloqueada con HTTP 403.

Para completar la compilación y simulación se utilizaron los perfiles y fuentes
copiados de una instalación de SDK Manager, publicados por
[matco/connectiq-tester](https://github.com/matco/connectiq-tester/tree/5508cf707cbd7435f7f1e9226d2303f4349bfc3b),
con fecha **2026-08-31**. Se extrajeron los datos de la imagen pública
`ghcr.io/matco/connectiq-tester@sha256:64958e8fd2925d0c4986d72a9aa9d8e2101297a881354aab0118be2f1dc22105`.
Se usó el SDK oficial descargado para compilar y ejecutar; no se ejecutó el
runner de esa imagen ni se inventaron perfiles, fuentes o APIs. Es una copia
comunitaria de los recursos de Garmin, no una descarga directa autenticada.
Para pruebas locales y publicación, actualiza los perfiles con tu SDK Manager.
Ni SDK, perfiles, fuentes ni claves privadas se añaden al repositorio.

## Compilación y tests nativos

| Perfil | Resolución | Release | Tests Run No Evil |
| --- | --- | --- | --- |
| `fenix7` | 260 × 260 | Correcta | 17/17 PASS |
| `fenix7s` | 240 × 240 | Correcta | 17/17 PASS |
| `epix2` | 416 × 416 | Correcta | 17/17 PASS |
| `fr255` | 260 × 260, sin táctil | Correcta | 17/17 PASS |
| `venu2` | 416 × 416 | Correcta | 17/17 PASS |
| `vivoactive4` | 260 × 260 | Correcta | 17/17 PASS |

**Sin errores ni avisos** en las compilaciones finales de aplicación y tests.
Exportación `monkeyc -e -r` correcta: `ScoreCount.iq`, con seis perfiles y los
13 destinos de hardware que Garmin agrupa bajo ellos. Se firmó con una clave
temporal de pruebas externa al repositorio; genera y conserva tu propia clave
para el reloj y Store. Los `.prg` y `.iq` quedan en `bin/`, ignorados por Git.

Cada simulador ejecutó estos 17 escenarios sobre el código real:

1. UP/DOWN cortos, ENTER/START corto y UNDO consecutivo hasta vaciar el historial.
2. ESC/LAP/LIGHT/MENU devuelven `false` en presión, acción y liberación, sin cambiar el marcador.
3. Tap izquierdo/derecho, hold de ambos equipos y RESET largo; RESET corto no actúa.
4. Hold repetido, tap durante hold y tap duplicado tras release no suman;
   el siguiente tap real vuelve a funcionar.
5. `12–8 → RESET → reinicio → UNDO → 12–8`, con más UNDO tras otro reinicio.
6. 40 sumas, conservación de los últimos 25 estados y recuperación tras reinicio.
   Suma sobre `2147483647` sin desbordamiento de 32 bits.
7. Restar en cero, RESET en cero y UNDO vacío no escriben ni crean historial.
8. Fallos de escritura conservan puntuaciones/historial y no generan háptica;
   recuperación tras un nuevo intento válido.
9. Almacenamiento malformado y excepción de lectura sin sobrescribir datos ilegibles.
10. Zonas independientes en 240, 260, 390, 416 y una superficie 360 × 400.
11. UP/DOWN: 799 ms suma y 800 ms resta, con un único guardado/pulso por cambio.
12. ENTER a 1500 ms resetea; START a 1499 ms deshace; RESET físico persiste
    y se deshace también tras reiniciar desde `12–8`.
13. UP/DOWN/START largos en cero no escriben, vibran ni crean historial.
    Un segundo RESET en cero conserva el historial útil del primer RESET.
14. Tres pulsaciones largas consecutivas en cada equipo restan exactamente una vez.
15. `onKey` antes/después de release, MENU generado por UP largo, auto-repeat,
    release repetido y eventos sin presión previa no duplican ni inventan cambios.
16. Dos botones solapados mantienen duraciones independientes; ENTER/START
    comparten registro y no ejecutan RESET/UNDO dos veces.
17. Desbordamiento de `System.getTimer()` de positivo a negativo y paso por cero,
    con umbrales cortos/largos y RESET seguido de UNDO.

Los tests no convierten un dispositivo sin táctil en táctil: ejercitan los mismos
handlers de la app por código. Usan memoria para aislar la lógica y un contador
para confirmar cuándo se solicita feedback. La prueba interactiva siguiente
verifica adicionalmente eventos y almacenamiento reales del simulador.

En este SDK/Linux, `monkeydo ... -t` devolvió código 1 incluso con resultado
`PASSED (passed=17, failed=0, errors=0)`. Se comprobaron los resúmenes de Run No
Evil de los seis modelos, no solo el código de salida del wrapper.

## Interacción real en Fenix 7 y Forerunner 255

Se accionaron los botones del simulador y el ratón sobre la pantalla mediante
X11. Tras cada paso se capturó el marcador dibujado y se verificaron sus números
con OCR. No se llamaron directamente métodos del modelo para esta comprobación.

En ambos perfiles se comprobaron mediante botones reales del simulador:

| Secuencia | Estado verificado |
| --- | --- |
| START largo inicial | 0–0 |
| UP corto, DOWN corto, DOWN corto | 1–2 |
| START corto tres veces | 1–1, 1–0, 0–0 |
| Dos UP cortos y dos DOWN cortos | 2–2 |
| UP largo, DOWN largo, UP largo, DOWN largo | 1–2, 1–1, 0–1, 0–0 |
| UP/DOWN largos y RESET largo en cero | 0–0 |
| Doce UP cortos y ocho DOWN cortos | 12–8 |
| START largo dos veces | 0–0; no añade un segundo RESET |
| START corto | 12–8 |
| BACK, reabrir mismo `.prg` | 12–8 persistente |
| START corto después de reabrir | 12–7; historial persistente |

Los UP/DOWN largos se mantuvieron **1,05 s**, y START largo **1,7 s**.
La comprobación posterior a release confirma que no se añade una acción corta.
Forerunner 255 completa todas las funciones exclusivamente con botones.

En Fenix 7 se repitieron además tap azul/rojo, hold azul/rojo, holds en cero,
tap posterior a hold, RESET táctil corto sin efecto, RESET táctil largo,
UNDO del RESET táctil y swipe vertical sin sumas. Los holds táctiles de 1,2 s
solo restaron una vez. Los controles táctiles conservan su guardia de 200 ms.

Se inspeccionó además el orden real de eventos con una aplicación diagnóstica
temporal: DOWN/ENTER pueden enviar `onKey()` al presionar, y UP mantenido genera
`KEY_MENU` a aproximadamente 1 s antes de `onKeyReleased(KEY_UP)`. Por eso
`onKey()` no modifica puntuaciones. MENU se devuelve sin consumir y no altera
el registro del UP que después se libera. Esa aplicación no se incluye en el
repositorio ni comparte almacenamiento con Score Count.

BACK cerró la aplicación con normalidad en ambos perfiles. LIGHT no se intercepta;
se verifican sus tres handlers con tests. Estos perfiles de simulador no exponen
LIGHT como evento de la app: la iluminación y los menús/reservas de botones del
firmware deben comprobarse también en los relojes físicos.

## Revisión visual

Se dibujó la aplicación real en Fenix 7 (260 px) y Epix 2 (416 px) y se revisaron
la ausencia de título y etiquetas de equipo, números centrados, contraste,
tarjetas ampliadas y RESET dentro de la pantalla circular. También se revisó
la pantalla del simulador Forerunner 255, sin touchscreen. En Fenix 7S (240 px)
se revisó además una vista de
prueba con `9223372036854775807` y `999999`: el valor largo se divide en tres
líneas sin perder dígitos ni solaparse con RESET. Esa vista temporal usa el
mismo `ScoreCountView` y no forma parte del producto.

Capturas de la aplicación:

![Score Count en Fenix 7](docs/images/fenix7.png)
![Score Count en Epix 2](docs/images/epix2.png)

No se ha añadido fallback visual: todos los dispositivos del manifest tienen
color. El negro, las dos tarjetas y RESET se mantienen en todos ellos. El nombre
Score Count sigue siendo el nombre de la app en el launcher, sin dibujarse en
el marcador. El aviso de almacenamiento sigue apareciendo si hay un fallo real.

## Pendiente de hardware y publicación

- Sensación/intensidad de vibración, touchscreen real, bloqueo táctil del reloj,
  iluminación y salida/navegación sobre firmware del Fenix 7 físico.
- Legibilidad al sol en MIP, brillo/consumo AMOLED y uso durante un partido.
- Pruebas físicas de los demás productos antes de ofrecerlos como compatibilidad
  verificada en hardware. Actualmente se declaran como validados en simulador.
- Los 200 ms posteriores a un hold también ignoran un toque intencional demasiado rápido.
- Icono provisional reutilizado de Huawei; preparar ficha, imágenes, soporte,
  firma definitiva y revisión Garmin antes de publicar.

No quedan errores de compilación ni pruebas nativas fallidas pendientes.
