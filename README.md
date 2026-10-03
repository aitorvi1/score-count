# Score Count

Score Count es un marcador de frontenis/frontón para smartwatch con implementaciones independientes para **Huawei** y **Garmin**.

Cada plataforma vive en su propia carpeta y se puede abrir, compilar y mantener como proyecto separado.

## Plataformas

| Plataforma | Implementación | Estado |
| --- | --- | --- |
| [Huawei](huawei/) | Lite Wearable / HarmonyOS | Funcional y probada en Huawei Watch GT 5 |
| [Garmin](garmin/) | Connect IQ / Monkey C | 118 product IDs validados en SDK/simulador; hardware físico pendiente |

## Estructura del repositorio

```text
score-count/
├── README.md
├── huawei/     Aplicación Huawei, configuración DevEco/Hvigor y documentación
└── garmin/     Aplicación Garmin Connect IQ, tests, compatibilidad y documentación
```

No hay dependencias de runtime compartidas entre ambas implementaciones. Cada carpeta contiene su propia configuración de construcción, recursos y documentación.

## Funcionalidad

Las dos versiones están orientadas a llevar un marcador directamente desde el reloj durante un partido:

- dos puntuaciones, azul y roja;
- sumar y restar puntos;
- la puntuación nunca baja de cero;
- RESET;
- persistencia del marcador;
- feedback háptico cuando la plataforma lo permite.

Los controles concretos y las capacidades adicionales dependen de la plataforma.

## Huawei

La versión Huawei es la implementación original y está probada en un **Huawei Watch GT 5** con HarmonyOS 6.

Consulta [huawei/README.md](huawei/README.md) para la estructura del proyecto, dispositivo de referencia, controles y apertura en DevEco Studio.

## Garmin

La versión Garmin está escrita en **Monkey C** para Connect IQ. La compatibilidad actual declara **118 product IDs**: 89 con política `FULL_PHYSICAL` y 29 con política `TOUCH`.

La validación registrada incluye 236 compilaciones, 2.513 tests PASS y revisión visual representativa, sin presentar simulación como validación física.

Consulta:

- [garmin/README.md](garmin/README.md) — desarrollo, controles, compilación e instalación.
- [garmin/TESTING.md](garmin/TESTING.md) — validación funcional.
- [garmin/compatibility/VALIDATION.md](garmin/compatibility/VALIDATION.md) — compatibilidad y validación de los 118 targets.
