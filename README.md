cd ~/Documents/frontenis-score

cat > README.md <<'EOF'
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
