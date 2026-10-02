# Validación Garmin

Validación del 2 de octubre de 2026 en el entorno local del usuario.
Solo se modifican archivos de `garmin/`; Huawei conserva su implementación.

## Entorno y compilación

SDK oficial **Connect IQ 9.2.0**:
`/home/aitor/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-9.2.0-2026-06-09-92a1605b2/`.
Perfiles oficiales locales: `/home/aitor/.Garmin/ConnectIQ/Devices/`.
La clave local se entrega al compilador mediante `-y`; su contenido no se lee
ni se muestra. SDK, perfiles y clave no se incorporan al repositorio.

El UUID, los productos y `minApiLevel="2.4.0"` permanecen intactos.
`onKeyPressed()` y `onKeyReleased()` están disponibles desde API 1.1.2;
no requieren elevar el mínimo. No se añade Fenix 3 ni se cambia el diseño.

| Dispositivo | Compilación release | Compilación tests | Tests nativos |
| --- | --- | --- | --- |
| fenix7 | OK, 0 warnings | OK, 0 warnings | 19 passes, 0 fallos, 0 errores |
| fr255 | OK, 0 warnings | OK, 0 warnings | 19 passes, 0 fallos, 0 errores |
| fenix7s | OK, 0 warnings | OK, 0 warnings | 19 passes, 0 fallos, 0 errores |
| epix2 | OK, 0 warnings | OK, 0 warnings | 19 passes, 0 fallos, 0 errores |
| venu2 | OK, 0 warnings | OK, 0 warnings | 19 passes, 0 fallos, 0 errores |
| vivoactive4 | OK, 0 warnings | OK, 0 warnings | 19 passes, 0 fallos, 0 errores |

Total: **19 tests distintos × 6 perfiles = 114 ejecuciones**, todas PASS,
**0 fallos y 0 errores**. `monkeydo` devuelve código de proceso 1 en estas
ejecuciones pese a informar `PASSED (passed=19, failed=0, errors=0)`; se conserva
esta discrepancia del launcher y no se interpreta únicamente su exit code.
Los logs completos locales están en `bin/validation/tests-<dispositivo>.log`
(artefactos ignorados por Git).

La primera compilación mostró siete warnings en `ScoreCountDelegate.mc`:
“Cannot determine if container access/assignment is using container type”.
El registro `[null, null, null]` no tenía tipo explícito; se corrigió a
`Lang.Array<Lang.Long or Null>`. Las compilaciones posteriores no presentan
warnings. Los mensajes de lectura/escritura fallida durante los tests son
excepciones simuladas deliberadamente, verificadas por tests que pasan.

Desde la raíz del proyecto:

```sh
python3 garmin/tools/build.py --sdk /ruta/al/sdk --key /ruta/privada/developer_key.der
python3 garmin/tools/build.py --sdk /ruta/al/sdk --key /ruta/privada/developer_key.der --tests
/ruta/al/sdk/bin/monkeydo garmin/bin/ScoreCount-tests-fenix7.prg fenix7 -t
```

Repetir el último comando con cada dispositivo del manifest.

## Cobertura nativa

Los 19 tests Run No Evil se ejecutan sobre las fuentes de producción, con
`MemoryScoreStore` para contar escrituras y simular fallos y `RecordingDelegate`
para contar vibraciones. Los tiempos se inyectan en los mismos handlers que
llaman los callbacks Garmin; los umbrales no dependen de latencia del simulador.

| Test | Verificación |
| --- | --- |
| buttonsAndMultipleUndo | Pulsaciones completas cortas y UNDO múltiple |
| garminKeysAndNavigationStayUnassigned | BACK/LAP/LIGHT: key, press, release y navegación sin cambios |
| touchActionsAndProtectedReset | Tap/hold azul y rojo, hold RESET, tap RESET inerte y cero |
| holdCannotBecomeAnIncrement | Hold duplicado y tap espurio durante/después del hold |
| resetAndUndoSurviveRestart | RESET/UNDO y su historial sobreviven a reconstruir el modelo |
| historyIsBoundedWithoutLimitingScore | Hasta 25 estados, puntuación Long superior a 32 bits |
| zeroActionsDoNotWriteOrVibrate | Restas, RESET y UNDO en estado inicial sin escritura/historial |
| failedWritesPreserveScoreAndUndo | Escritura fallida no publica cambios ni vibra; recuperación |
| malformedStorageAndReadFailure | Validación del almacenamiento y protección de lectura fallida |
| layoutAdaptsAndKeepsSeparateTargets | Zonas separadas en las resoluciones existentes |
| physicalThresholds | UP/DOWN 799/800 ms y START 1499/1500 ms; exactamente un cambio |
| repeatsExtraKeysAndReleasesAreInert | Auto-repeat conserva inicio, onKey extra, release huérfano/repetido |
| overlappingKeysKeepIndependentTimes | UP/DOWN/START solapados, tiempos independientes y orden de release |
| enterStartAliasesShareOnePress | ENTER/START en press repetido y release, sin duplicados |
| signedTimerOverflowKeepsThresholds | Los seis límites cruzando 2147483647 → −2147483648 |
| menuAndSecondaryBehaviorsNeverScore | MENU con/sin UP, una resta al release; secundarios DOWN/START |
| physicalZeroActionsAndResetUndoPersist | Cero sin efectos, RESET redundante conserva UNDO, reinicios |
| failedPhysicalLongActionsPreserveState | Fallos al restar y resetear físicos sin cambios/háptica |
| timerWrapFromNegativeToPositive | Cruce −400 → 399/400 conserva límite 799/800 ms |

## Flujo real del simulador Fenix 7

Se ejecutó una **copia temporal instrumentada** de las mismas fuentes fuera del
repositorio, compilada con el perfil oficial `fenix7`. Un controlador X11 externo
accionó los botones de la carátula. Las trazas temporales no forman parte del
producto; las esperas del controlador no se introducen en la aplicación.

| Entrada simulada | Duración observada (aproximada) | Resultado |
| --- | --- | --- |
| UP corto | 230 ms | 0–0 → 1–0 al soltar |
| UP largo | 1298 ms | 1–0 → 0–0 al soltar, sin abrir vistas |
| DOWN corto | 249 ms | 0–0 → 0–1 al soltar |
| DOWN largo | 1203 ms | 0–1 → 0–0 al soltar |
| START corto | 230 ms | 1–1 → 1–0 mediante UNDO |
| START largo | 1802 ms | 1–0 → 0–0 mediante RESET |
| START corto después de RESET | 237 ms | 0–0 → 1–0 mediante UNDO |

UP largo produjo `onKeyPressed(UP) → onMenu() → onKeyReleased(UP)`.
`onMenu()` llegó con UP registrado y se consumió sin acciones ni vistas;
se observó exactamente un cambio de marcador, al release. Una captura tomada
mientras UP seguía presionado mostró el marcador 1–0 y ninguna vista adicional.
DOWN y START entregaron press y release; no generaron onKey adicional en esta
secuencia. Los eventos onKey extra se cubren mediante los tests nativos.

La traza de referencia de UP largo fue:

```text
onKeyPressed key=13 timer=1460457
onMenu UP=1460458
onKeyReleased key=13 timer=1461756
finish changed=true score=0-0
```

Los callbacks y el handler consultan el timer separadamente, por lo que la
traza de entrada puede diferir 1 ms del tiempo registrado. Los límites exactos
799/800 y 1499/1500 se validan en tests nativos, no mediante clicks cronometrados.

## Pendiente de hardware físico

- Fenix 7 y FR255: entrega de press/release con firmware y hotkeys personales,
  especialmente UP/MENU, música con DOWN largo y atajos de START. Connect IQ
  no garantiza interceptar acciones reservadas por el firmware. Si el firmware
  retira la app o no entrega release, la app no sintetiza una acción de marcador.
- BACK/LAP/LIGHT, salida/reentrada, persistencia real en `Application.Storage`
  y RESET seguido de UNDO tras reiniciar la aplicación en el reloj.
- Vibración real, touchscreen, bloqueo táctil y taps posteriores a un hold.
  La guardia existente de 200 ms también ignora un tap intencional muy rápido.
- Verificar físicamente los demás productos antes de declarar validación en
  hardware; compilación y tests no equivalen a validación de firmware real.

No se realiza commit, push, merge ni publicación como parte de esta validación.
