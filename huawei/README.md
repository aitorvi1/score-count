# Score Count — Huawei

Aplicación de marcador de frontenis/frontón para **Huawei Lite Wearable**.

Está diseñada para llevar el marcador directamente desde el reloj durante un partido, con una interfaz grande y simple.

## Estado

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
  - al salir y volver a entrar se conserva la puntuación;
  - el marcador se guarda en almacenamiento privado de la aplicación.
- Icono personalizado.

## Dispositivo probado

Desarrollada y probada principalmente en:

- **Huawei Watch GT 5**
- Sistema: **HarmonyOS 6**
- Firmware probado: **HarmonyOS 6.0.0.32**
- Tipo de dispositivo del proyecto: `liteWearable`
- Pantalla circular
- Resolución de referencia: **466 × 466 px**

La compatibilidad con otros Huawei Lite Wearable no está garantizada y debe comprobarse en hardware real.

## Aplicación

- Nombre: `Score Count`
- Bundle name: `com.frontenisscore.app`

## Abrir el proyecto

Abre la carpeta **`score-count/huawei/`** como raíz del proyecto en DevEco Studio.

La firma se configura localmente en DevEco Studio y no se versiona en el repositorio.

## Estructura

```text
huawei/
├── README.md
├── app/             Código JS/HML/CSS de la aplicación Lite Wearable
├── entry/           Módulo, recursos y enlaces al código de app/
├── hvigor/          Configuración de construcción
├── lite-sample/     Ejemplo original conservado como referencia
├── build-profile.json5
├── hvigorfile.ts
└── oh-package.json5
```

Los enlaces relativos de `entry/` apuntan al código de `app/`, por lo que ambos directorios deben mantenerse dentro de esta misma raíz de proyecto.

## Notas de desarrollo

- Los artefactos de build y los HAP generados no se versionan.
- Las credenciales y material de firma permanecen fuera del repositorio.
- Los cambios de la versión Garmin no son una dependencia de esta implementación.
