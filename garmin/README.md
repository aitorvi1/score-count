# Score Count para Garmin

Watch App de Connect IQ para llevar un marcador azul/rojo durante un partido.
Estado inicial `0–0`, sin negativos ni máximo deportivo. El marcador y los últimos
**25 estados** sobreviven a salir, cerrar y volver a abrir. RESET es deshacible.
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

## Controles

| Entrada | Acción |
| --- | --- |
| UP corto (<800 ms) | +1 azul |
| UP largo (≥800 ms) | −1 azul, mínimo 0 |
| DOWN corto (<800 ms) | +1 rojo |
| DOWN largo (≥800 ms) | −1 rojo, mínimo 0 |
| START/ENTER corto (<1500 ms) | UNDO |
| START/ENTER largo (≥1500 ms) | RESET a 0–0, deshacible |
| BACK/LAP | Comportamiento estándar Garmin; evento no consumido |
| LIGHT | Iluminación estándar Garmin; evento no consumido |
| MENU | Comportamiento estándar Garmin; evento no consumido |
| Toque en azul/rojo | +1 en esa zona |
| Pulsación larga en azul/rojo | −1 en esa zona, mínimo 0 |
| Pulsación larga en RESET | 0–0, deshacible |
| Toque corto en RESET | Sin cambio |

Los controles físicos se aplican tanto con touchscreen como sin él, cuando el
producto exponga esas teclas. La acción se ejecuta **al soltar** el botón: se mide
la duración con `System.getTimer()` entre `onKeyPressed()` y `onKeyReleased()`,
sin esperas ni temporizadores bloqueantes. Solo la liberación modifica el modelo;
`onKey()` consume las teclas asignadas sin ejecutar otra acción. Una pulsación
larga nunca suma ni deshace además al soltar. Se ignoran repeticiones de presión
y liberaciones sin presión previa; ENTER/START comparten el mismo registro.
La diferencia se calcula en 64 bits y corrige el desbordamiento del contador
de 32 bits. MENU sigue devolviendo `false`, incluso si Garmin lo genera durante
un UP largo: no se convierte en otra modificación del marcador.

Las zonas activas coinciden con las tarjetas y el rectángulo RESET. Los márgenes
y el espacio central no suman. No hay acciones asignadas a swipes ni a gestos
abstractos de navegación. Garmin determina la duración que produce `onHold`.
Solo se procesa una modificación por hold. Tras `onRelease`, los taps se ignoran
**200 ms** para proteger frente a duplicados; el siguiente toque posterior funciona
aunque no haya llegado un tap duplicado.

Cada cambio válido genera un pulso de 80 ms si la vibración está disponible y
habilitada. Restar en cero, UNDO sin historial y RESET en 0–0 no cambian el estado,
no crean historial ni vibran. **Forerunner 255, sin touchscreen, dispone de todas
las acciones** mediante pulsaciones cortas/largas. En Venu/vívoactive, que no
exponen UP/DOWN en estos perfiles, sumar/restar sigue disponible por táctil;
UNDO y RESET físicos usan la tecla ENTER/START que exponga Garmin.

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
source/ScoreCountDelegate.mc  InputDelegate, acciones compartidas y háptica
source/ScoreLayout.mc         Dimensiones y zonas de dibujo/entrada
source/TouchGesture.mc        Hold/release y protección de duplicados
resources*/                  Icono reutilizado de Huawei y strings ES/EN
tests/                       Tests nativos Run No Evil
tests.jungle                 Inclusión de tests en compilaciones de prueba
tools/build.py               Construcción por manifest y exportación
```

UP corto y tap azul llaman a `addBluePoint()`; DOWN corto y tap rojo a
`addRedPoint()`. UP/DOWN largo y hold táctil llaman a las mismas restas;
START largo y hold RESET llaman a `reset()`. START corto llama a `undo()`.
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

Repite con los demás modelos. Los 17 tests cubren botones cortos/largos, límites
de 800/1500 ms, repeticiones, ausencia de dobles eventos, teclas no asignadas,
presiones simultáneas y desbordamiento del temporizador; también UNDO múltiple, mínimo
cero, RESET deshacible, reinicio con historial, 25 estados, puntuaciones superiores
a 32 bits, fallos de almacenamiento, distintas resoluciones y hold/release/tap.
Usan almacén en memoria y contador háptico para no modificar el marcador real.
La persistencia real y los eventos del simulador se verifican adicionalmente
según [TESTING.md](TESTING.md).

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
6. Prueba botones cortos/largos, hold en equipos/RESET, BACK/LIGHT/MENU y reentrada con marcador e
   historial. Comprueba háptica real y legibilidad al sol.

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

- [InputDelegate](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/InputDelegate.html): onKeyPressed/onKeyReleased/onKey y onTap/onHold/onRelease.
- [System.getTimer](https://developer.garmin.com/connect-iq/api-docs/Toybox/System.html#getTimer-instance_function): duración en ms y desbordamiento periódico.
- [WatchUi](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi.html): KEY_* y requestUpdate.
- [Application.Storage](https://developer.garmin.com/connect-iq/api-docs/Toybox/Application/Storage.html): mínimo API 2.4.0.
- [Attention](https://developer.garmin.com/connect-iq/api-docs/Toybox/Attention.html): vibrate/VibeProfile con comprobación `has`.
- [DeviceSettings](https://developer.garmin.com/connect-iq/api-docs/Toybox/System/DeviceSettings.html): dimensiones y vibrateOn.
- [Graphics.Dc](https://developer.garmin.com/connect-iq/api-docs/Toybox/Graphics/Dc.html): dibujo y métricas de texto.
- Guías oficiales de manifest, firma, VS Code y publicación incluidas en SDK 9.2.0.
