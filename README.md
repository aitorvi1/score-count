# Score Count

Aplicación sencilla de marcador de frontenis/frontón para Huawei Watch.

Está diseñada para poder llevar el marcador directamente desde el reloj durante un partido, con una interfaz grande y simple para evitar tener que mirar el móvil.

## Estado del proyecto

Versión funcional probada en reloj físico.

### Funciones actuales

- Marcador para dos jugadores/equipos.
- Zona azul para el jugador/equipo izquierdo.
- Zona roja para el jugador/equipo derecho.
- Toque corto sobre una zona: suma `+1`.
- Pulsación larga sobre una zona: resta `-1`.
- La puntuación nunca baja de `0`.
- Vibración al modificar la puntuación.
- RESET protegido mediante pulsación larga.
- Persistencia del marcador:
  - si se sale de la aplicación y se vuelve a entrar, se conserva la puntuación;
  - el marcador se guarda en almacenamiento privado de la aplicación.
- Icono personalizado para la aplicación.

## Dispositivo probado

La aplicación se ha desarrollado y probado principalmente en:

- **Huawei Watch GT 5**
- Sistema: **HarmonyOS 6**
- Firmware probado: **HarmonyOS 6.0.0.32**
- Tipo de dispositivo del proyecto: `liteWearable`
- Pantalla circular
- Resolución de referencia: **466 × 466 px**

La compatibilidad con otros relojes Huawei Lite Wearable no está garantizada y debe probarse en hardware real.

## Aplicación

- Nombre: `Score Count`
- Bundle name:

```text
com.frontenisscore.app
```

## Versiones y estructura

La aplicación Huawei sigue en `app/` (JS, HML, CSS). `entry/` contiene el módulo,
los recursos y los enlaces a ese código. La raíz se abre en DevEco Studio con
la configuración Hvigor existente. `lite-sample/` conserva el ejemplo original.
La firma Huawei se configura localmente en DevEco Studio.

La Watch App para **Garmin Connect IQ**, escrita en **Monkey C**, está aislada en
[`garmin/`](garmin/). Añade controles físicos, un historial persistente de 25
estados para UNDO y una interfaz basada en las dimensiones reales del reloj.
RESET también se puede deshacer. El primer dispositivo de referencia es Fenix 7.

Consulta [`garmin/README.md`](garmin/README.md) para instalar el SDK oficial,
abrir el proyecto en VS Code, compilar, usar el simulador, instalar en el reloj y
exportar para Connect IQ Store. La validación se registra en
[`garmin/TESTING.md`](garmin/TESTING.md).

```text
app/          Aplicación Huawei
entry/        Módulo y recursos Huawei; enlaces a app/
hvigor/       Configuración de construcción Huawei
lite-sample/  Ejemplo original Huawei
garmin/       Aplicación Connect IQ, recursos, pruebas y documentación
```

No hay dependencias compartidas ni cambios en la lógica de la aplicación Huawei.
