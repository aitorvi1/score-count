# Score Count para Garmin

Watch App de Connect IQ para llevar un marcador azul/rojo durante un partido.
Estado inicial `0–0`, sin negativos ni máximo deportivo. El marcador y los últimos
**25 estados** sobreviven a salir, cerrar y volver a abrir. En FULL_PHYSICAL,
RESET es deshacible mediante START/ENTER corto.
No registra una actividad deportiva ni utiliza GPS.

## Instalar herramientas y abrir VS Code

1. Instala Java 11 o posterior; se ha utilizado Java 17 para el desarrollo.
2. Descarga el [SDK Manager oficial](https://developer.garmin.com/connect-iq/sdk/).
   Sigue el asistente e inicia sesión en tu cuenta Garmin cuando lo solicite.
3. Instala y selecciona el SDK Connect IQ estable actual. Versión de desarrollo:
   **9.2.0**. En **Devices**, descarga los seis modelos de la tabla de
   compatibilidad con sus fuentes. El ZIP del SDK no incluye esos perfiles.
4. Instala VS Code y **Monkey C de Garmin** (`garmin.monkey-c`).
5. Abre **`score-count/garmin/`**, como proyecto independiente de la raíz Huawei.
6. Ejecuta **Monkey C: Verify Installation** desde la paleta de comandos.
7. Ejecuta **Monkey C: Generate Developer Key**. Guarda la clave fuera del
   repositorio y selecciona su ruta en **Monkey C: Developer Key Path**.
   Conserva la misma clave para actualizar la app en Store.

Garmin soporta Ubuntu para el SDK Linux. El simulador necesita sesión gráfica
y bibliotecas nativas; sigue los requisitos del SDK Manager para tu sistema.

## Simulador en VS Code

1. Ejecuta **Monkey C: Build Current Project** y elige **fenix7**.
2. Pulsa **F5** o **Run > Start Debugging**, configuración **Score Count — simulador**.
   Elige **fenix7** cuando se solicite el dispositivo.
3. Comprueba las zonas y RESET. Usa los botones de la carcasa simulada y pulsa
   dentro de las zonas para táctil; mantén el ratón pulsado para un hold.
4. Repite con **fr255** (sin touchscreen), **fenix7s** (240 px) y **epix2** (416 px AMOLED).
5. Detén la app con el control de parada del simulador y vuelve a ejecutarla con
   el mismo nombre de `.prg` y UUID para verificar persistencia. Borrar los datos
   de aplicación en el simulador sí reinicia el marcador.

## Compilar y ejecutar por terminal

Añade `bin` del SDK activo a `PATH`. En Linux:

```sh
export CONNECTIQ_SDK="$(cat "$HOME/.Garmin/ConnectIQ/current-sdk.cfg")"
export PATH="$CONNECTIQ_SDK/bin:$PATH"
```

En macOS el selector está en
`$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg`; en Windows,
`%APPDATA%\Garmin\ConnectIQ\current-sdk.cfg`. Puedes indicar directamente la
ruta del SDK al script de construcción con `--sdk`.

Alternativa para generar la clave: en una carpeta privada fuera del repositorio:

```sh
openssl genrsa -out developer_key.pem 4096
openssl pkcs8 -topk8 -inform PEM -outform DER \
  -in developer_key.pem -out developer_key.der -nocrypt
```

Desde `score-count/garmin/`, sustituyendo la ruta de la clave por la tuya:

```sh
mkdir -p bin
monkeyc -f monkey.jungle -d fenix7 -y /ruta/privada/developer_key.der \
  -o bin/ScoreCount-fenix7.prg -w
connectiq
```

Con el simulador abierto, en otra terminal:

```sh
monkeydo bin/ScoreCount-fenix7.prg fenix7
```

Segunda resolución:

```sh
monkeyc -f monkey.jungle -d epix2 -y /ruta/privada/developer_key.der \
  -o bin/ScoreCount-epix2.prg -w
monkeydo bin/ScoreCount-epix2.prg epix2
```

El script opcional usa Python 3 sin dependencias y obtiene los dispositivos del manifest:

```sh
python3 tools/build.py --sdk /ruta/al/sdk --key /ruta/privada/developer_key.der
python3 tools/build.py --sdk /ruta/al/sdk --key /ruta/privada/developer_key.der --device fenix7
```

## Controles y políticas de entrada

Jungle selecciona en compilación una única implementación de `ScoreCountDelegate`.
No hay comprobaciones de product IDs en runtime ni una política predeterminada
para futuros productos. Se usan `sourcePath` por dispositivo, según la
[configuración oficial de Jungle](https://developer.garmin.com/connect-iq/core-topics/build-configuration/).

| Producto | Política |
| --- | --- |
| fenix7, fenix7s, epix2, fr255 | `FULL_PHYSICAL` |
| venu2, vivoactive4 | `TOUCH` |

### FULL_PHYSICAL

Las acciones físicas se ejecutan **únicamente al soltar** el botón:

| Botón | Corto | Largo |
| --- | --- | --- |
| UP | <800 ms: +1 azul | ≥800 ms: −1 azul |
| DOWN | <800 ms: +1 rojo | ≥800 ms: −1 rojo |
| START / ENTER | <1500 ms: UNDO | ≥1500 ms: RESET directo a 0–0 |

`onKeyPressed()` registra el timer por botón; auto-repeat no reinicia el tiempo.
`onKeyReleased()` borra el registro antes de ejecutar una única acción. Releases
huérfanos o repetidos no hacen nada. UP/DOWN/START tienen registros independientes;
las acciones solapadas se aplican en orden de release. ENTER y START comparten
registro. La resta usa `Lang.Long` antes de calcular la diferencia y añade 2³²
si es negativa para cubrir el overflow firmado del contador.

`onKey()` consume UP/DOWN/ENTER/START y KEY_MENU sin puntuar. Los callbacks
`onPreviousPage`, `onNextPage` y `onSelect` solo se consumen mientras está activo
su botón. Sin un botón activo devuelven `false`, permitiendo táctil y swipes.
`onMenu()` consume MENU, incluido el generado por UP largo, sin abrir vistas,
puntuar ni borrar el timestamp UP. BACK/LAP/LIGHT quedan libres.

### TOUCH

No se usa ningún botón físico para el marcador. `onKey`, `onKeyPressed`,
`onKeyReleased`, `onMenu`, `onBack`, `onPreviousPage`, `onNextPage`,
`onPreviousMode`, `onNextMode` y `onSelect` devuelven `false`, incluso para
UP/DOWN/ENTER/START/MENU. Garmin conserva la gestión de esos eventos.
La app es completamente utilizable mediante touchscreen.

### Táctil común

| Zona | Tap | Hold |
| --- | --- | --- |
| Azul | +1 azul | −1 azul |
| Roja | +1 rojo | −1 rojo |
| RESET | RESET | Sin acción |

La zona inferior muestra únicamente `RESET`, centrado en una línea. Se recuperan
sus dimensiones originales, sin ampliar el ancho ni cambiar las tarjetas o los
números del marcador. No hay segunda línea ni etiqueta alternativa.
FR255 no tiene touchscreen y usa sus controles `FULL_PHYSICAL`.

Tap RESET pone directamente el marcador a 0–0. En `FULL_PHYSICAL` puede deshacerse
mediante START/ENTER corto, incluso después de cerrar y abrir. En `TOUCH` no hay
UNDO desde la interfaz: el historial se conserva internamente, pero ningún botón
o gesto lo utiliza. Restar en cero y RESET en 0–0 no generan escritura, historial
ni vibración; un RESET redundante conserva el historial previo. UNDO físico sin
historial tampoco escribe ni vibra.

Garmin determina cuándo envía `onHold`. Se aplica una modificación por hold de
equipo y se ignoran taps durante el hold y los **200 ms** posteriores al release
para evitar duplicados. Mantener RESET no ejecuta otra acción. Los márgenes no
puntúan. Cada cambio válido genera el pulso existente de 80 ms si la vibración
está disponible y habilitada. No hay temporizadores activos, esperas ni bucles
de espera en la app.

El firmware puede reservar hotkeys o interrumpir la entrega de eventos a Connect
IQ. La app no sintetiza acciones si falta el release. La devolución de `false`
en TOUCH no implementa menús Garmin: permite que firmware y simulador gestionen
la entrada según el perfil. Debe validarse en hardware.

## Compatibilidad declarada

| Producto | ID SDK | Pantalla | Táctil |
| --- | --- | --- | --- |
| Fenix 7 / variantes agrupadas por Garmin | `fenix7` | 260 × 260 MIP | Sí |
| Fenix 7S | `fenix7s` | 240 × 240 MIP | Sí |
| Epix (Gen 2) / variantes agrupadas por Garmin | `epix2` | 416 × 416 AMOLED | Sí |
| Forerunner 255 | `fr255` | 260 × 260 MIP | No |
| Venu 2 | `venu2` | 416 × 416 AMOLED | Sí |
| vívoactive 4 | `vivoactive4` | 260 × 260 MIP | Sí |

Los resultados por modelo están en [TESTING.md](TESTING.md). Una compilación o
simulación no equivale a una prueba física. La interfaz usa dimensiones reales,
proporciones y medición de fuentes nativas. Reduce la fuente según los dígitos y
puede dividir valores largos en líneas. El diseño muestra **solo números grandes
centrados** en dos tarjetas, azul a la izquierda y roja a la derecha, sobre fondo
negro, con RESET debajo. No hay título superior ni etiquetas AZUL/ROJO o BLUE/RED.
Las tarjetas aprovechan el espacio liberado y sus esquinas respetan la pantalla
circular. Solo un fallo real de almacenamiento muestra el aviso de error.
No hay fallback visual especial: todos los perfiles declarados tienen color.
No se declaran todavía relojes monocromos, rectangulares ni otras variantes de
estas familias; su posible identificación mínima deberá evaluarse al añadirlos.

Para ampliar: descarga el perfil oficial, añádelo al manifest, compila, ejecuta
tests y revisa controles, fuentes y límites de pantalla en su simulador.

## Arquitectura y almacenamiento

```text
manifest.xml                  UUID estable, Watch App, productos e idiomas
monkey.jungle                 Configuración del proyecto
source/ScoreCountApp.mc       Ciclo de vida y composición
source/ScoreModel.mc          Puntuaciones, historial, validación y ScoreStore
source/ScoreCountView.mc      Dibujo y selección de fuentes
source/ScoreCountCommonDelegate.mc  Táctil, actualización y háptica compartidos
policies/full-physical/       Delegate físico, timers y MENU
policies/touch/               Delegate con eventos físicos libres
source/ScoreLayout.mc         Dimensiones y zonas de dibujo/entrada
source/TouchGesture.mc        Hold/release y protección de duplicados
resources*/                  Icono reutilizado de Huawei y strings ES/EN
tests/common/                Modelo, almacenamiento y táctil para ambas políticas
tests/full-physical/         Regresiones físicas y comprobación de política
tests/touch/                 Passthrough y comprobación de política
tests.jungle                 Inclusión de tests en compilaciones de prueba
tools/build.py               Construcción por manifest y exportación
```

UP corto y tap azul llaman a `addBluePoint()`; DOWN corto y tap rojo a
`addRedPoint()`. Las pulsaciones largas físicas y los holds táctiles llaman a las mismas
restas de `ScoreModel`; START largo en FULL_PHYSICAL y tap RESET llaman a `reset()`.
Solo START/ENTER corto en FULL_PHYSICAL llama a `undo()`. Los eventos secundarios nunca modifican el modelo.
El modelo prepara el nuevo estado, lo guarda, publica el cambio y devuelve si
hubo modificación. La entrada solicita `WatchUi.requestUpdate()` y genera
háptica. Garmin programa el redibujado: `requestUpdate()` no es síncrono, por lo
que el pulso puede preceder al frame siguiente.

`Application.Storage` guarda un diccionario bajo `scoreCount.state.v1` con
`version`, `scoreBlue`, `scoreRed`, `history`. Guarda tras cada modificación y al
cerrar. Las puntuaciones son `Lang.Long` (64 bits), sin tope deportivo impuesto;
el entero nativo tiene rango finito. El historial ocupa hasta 25 pares. UNDO
consume historial; no hay REDO.

El arranque valida los tipos y descarta historiales inválidos, recuperando las
puntuaciones válidas. Si una lectura lanza excepción, la app bloquea modificaciones
y muestra error para evitar sobrescribir datos ilegibles; vuelve a abrirla tras
resolver el problema. Una escritura fallida conserva puntuaciones e historial,
no vibra, muestra `ERROR GUARDADO`/`SAVE ERROR` y permite reintentar. No se
solicitan permisos de red, sensores ni GPS: Storage y Attention no los necesitan.

## Pruebas nativas

Con el simulador abierto:

```sh
python3 tools/build.py --sdk /ruta/al/sdk --key /ruta/privada/developer_key.der --tests --device fenix7
monkeydo bin/ScoreCount-tests-fenix7.prg fenix7 -t
```

Equivalente sin Python:

```sh
monkeyc -f 'monkey.jungle;tests.jungle' -d fenix7 -t \
  -y /ruta/privada/developer_key.der -o bin/ScoreCount-tests-fenix7.prg -w
monkeydo bin/ScoreCount-tests-fenix7.prg fenix7 -t
```

Repite con los demás modelos. `tests.jungle` extiende las rutas de producción y
selecciona únicamente la suite de la política de cada perfil. Un test verifica
explícitamente `INPUT_POLICY`; TOUCH no ejecuta regresiones FULL_PHYSICAL.
Los tests cubren umbrales exactos, acciones solo al
soltar, repetición/duplicados, releases huérfanos, solapamientos, alias ENTER/START,
overflow del timer, MENU durante UP, navegación, táctil, persistencia, historial
de 25 estados y errores de almacenamiento. Usan almacén en memoria y contador
háptico. Los resultados y la validación de eventos están en [TESTING.md](TESTING.md).

## Instalar en Fenix 7 físico

1. Actualiza el reloj y verifica que sea el perfil **fenix7**. 7S/7X necesitan sus
   propios binarios; 7X aún no está declarado.
2. Ejecuta **Monkey C: Build for Device**, elige **fenix7** y genera `ScoreCount.prg`
   firmado con tu clave. Alternativa desde `garmin/`:

   ```sh
   monkeyc -f monkey.jungle -d fenix7 -r -y /ruta/privada/developer_key.der \
     -o bin/ScoreCount.prg -w
   ```

3. Conecta el reloj con un cable USB de datos. Selecciona transferencia o
   almacenamiento si lo solicita el reloj y acepta la conexión al ordenador.
4. Abre su almacenamiento y copia **el `.prg`** en **`GARMIN/APPS/ScoreCount.prg`**.
   Puede aparecer como unidad extraíble o MTP; usa el explorador compatible de
   tu sistema. El `.iq` es para Store, no para copiar al reloj.
5. Expulsa de forma segura, desconecta y abre **Score Count** desde las apps del
   reloj. Habilita el táctil si está desactivado para las aplicaciones.
6. Prueba UP/DOWN/START cortos y largos, tap RESET y holds en equipos,
   BACK/LAP/LIGHT y reentrada con marcador e historial. Comprueba que UP largo
   no abre vistas, RESET se puede deshacer y las hotkeys no impiden los releases.

Para actualizar, cierra la app y reemplaza el mismo `.prg` conservando nombre y
UUID. Desinstalar o borrar datos elimina la persistencia. No se promete migración
del almacén de una app de desarrollo a una instalación posterior de Store.

## Preparar Connect IQ Store

UUID estable, versión inicial `1.0.0`, launcher adaptado por el compilador al
perfil y strings ES/EN. No regeneres el UUID al actualizar esta app. Después de
validar en hardware los modelos que decidas mantener:

```sh
python3 tools/build.py --sdk /ruta/al/sdk --key /ruta/privada/developer_key.der --export
```

O **Monkey C: Export Project**. Equivalente con el SDK:

```sh
monkeyc -f monkey.jungle -e -r -y /ruta/privada/developer_key.der -o bin/ScoreCount.iq -w
```

El `.iq` incluye los productos del manifest y se carga desde
[Submit an App](https://apps.garmin.com/developer/submit). Prepara descripción,
categoría, contacto de soporte, capturas e icono de Store según el formulario
vigente. El launcher reutiliza el icono Huawei; su máster está en
`entry/src/main/resources/base/media/logo_master.png` para generar el de Store.
Revisa las [directrices oficiales](https://developer.garmin.com/connect-iq/app-review-guidelines/).
Solo se guardan marcador e historial en el reloj, sin servicios externos. La
revisión y publicación requieren tu cuenta Garmin y quedan fuera de esta implementación.

## APIs verificadas

- [BehaviorDelegate](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/BehaviorDelegate.html): onMenu y prioridad sobre los eventos básicos.
- [InputDelegate](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/InputDelegate.html): onKeyPressed/onKeyReleased (API 1.1.2), onKey y onTap/onHold/onRelease.
- [System.getTimer](https://developer.garmin.com/connect-iq/api-docs/Toybox/System.html#getTimer-instance_function): duración de botones físicos y guardia de duplicados táctiles.
- [WatchUi](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi.html): KEY_* y requestUpdate.
- [Application.Storage](https://developer.garmin.com/connect-iq/api-docs/Toybox/Application/Storage.html): mínimo API 2.4.0.
- [Attention](https://developer.garmin.com/connect-iq/api-docs/Toybox/Attention.html): vibrate/VibeProfile con comprobación `has`.
- [DeviceSettings](https://developer.garmin.com/connect-iq/api-docs/Toybox/System/DeviceSettings.html): dimensiones y vibrateOn.
- [Graphics.Dc](https://developer.garmin.com/connect-iq/api-docs/Toybox/Graphics/Dc.html): dibujo y métricas de texto.
- Guías oficiales de manifest, firma, VS Code y publicación incluidas en SDK 9.2.0.
