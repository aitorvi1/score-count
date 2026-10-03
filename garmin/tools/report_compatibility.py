#!/usr/bin/env python3
"""Produce a versionable per-target report after all validation gates pass."""
import argparse
import collections
import csv
import json
from pathlib import Path

from verify_targets import ROOT, check


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / 'bin/compatibility118')
    parser.add_argument('--profiles', type=Path, default=Path.home() / '.Garmin/ConnectIQ/Devices')
    args = parser.parse_args()
    targets = check(args.profiles)
    results = json.loads((args.output / 'results.json').read_text())
    renders = json.loads((args.output / 'renders.json').read_text())
    reviews = json.loads((args.output / 'visual-reviews.json').read_text())
    export = json.loads((args.output / 'export.json').read_text())
    assert set(results) == {r['product_id'] for r in targets}
    assert len(renders) == 20 and set(reviews) == {r['product_id'] for r in renders.values()}
    assert all(review['passed'] for review in reviews.values())
    assert export['ok'] and export['targets_verified'] == 118
    columns = ['product_id', 'classification', 'policy', 'shape', 'width', 'height', 'icon_width', 'icon_height',
               'release_ok', 'release_warnings', 'release_errors', 'release_prg_bytes',
               'test_build_ok', 'test_build_warnings', 'test_build_errors', 'test_prg_bytes',
               'native_policy_logged', 'native_passed', 'native_failed', 'native_errors', 'launcher_exit_code',
               'watch_app_memory_bytes', 'max_prg_filespace_bytes']
    rows = []
    for target in targets:
        r = results[target['product_id']]
        release, tests, native = r['compile_release'], r['compile_tests'], r['native_tests']
        assert release['ok'] and tests['ok'] and native['ok']
        assert not release['warnings'] and not tests['warnings'] and not release['errors'] and not tests['errors']
        assert native['policy_logged'] and native['failed'] == native['errors'] == 0
        for compiled in [release, tests]:
            if target['max_prg_filespace_bytes'] is not None:
                assert compiled['program_bytes'] <= target['max_prg_filespace_bytes']
        rows.append(dict(target, release_ok=True, release_warnings=0, release_errors=0, release_prg_bytes=release['program_bytes'],
                         test_build_ok=True, test_build_warnings=0, test_build_errors=0, test_prg_bytes=tests['program_bytes'],
                         native_policy_logged=True, native_passed=native['passed'], native_failed=0, native_errors=0,
                         launcher_exit_code=native['returncode']))
    total = sum(row['native_passed'] for row in rows)
    assert total == 2513
    doc = ROOT / 'compatibility'
    with (doc / 'validation.csv').open('w', newline='') as file:
        writer = csv.DictWriter(file, fieldnames=columns, extrasaction='ignore', lineterminator='\n')
        writer.writeheader()
        writer.writerows(rows)
    visual = sorted(renders.values(), key=lambda r: (r['shape'], r['width'], r['height'], r['policy']))
    with (doc / 'visual-validation.csv').open('w', newline='') as file:
        writer = csv.DictWriter(file, fieldnames=['product_id', 'shape', 'width', 'height', 'policy', 'passed', 'checks'], lineterminator='\n')
        writer.writeheader()
        for r in visual:
            writer.writerow({key: (reviews[r['product_id']][key] if key in {'passed', 'checks'} else r[key]) for key in writer.fieldnames})
    lines = [
        '# Validación de los 118 targets Garmin', '',
        'SDK oficial Connect IQ 9.2.0.', '',
        'La lista procede exclusivamente de la segunda auditoría de navegación. Se conservan los hashes de sus cuatro artefactos en `audit-provenance.json`.', '',
        '**118 IDs únicos: 89 FULL_PHYSICAL y 29 TOUCH. 236 compilaciones correctas, 0 warnings y 0 errores. 2513 tests nativos PASS, 0 fallos y 0 errores.**', '',
        'Se comprueban lista exacta, exclusiones, selección exclusiva de delegate y suite, tamaños de launcher, UUID estable, minApiLevel 2.4.0 y versión 1.0.0. El código Monkey C no cambia respecto al commit base `68399591287cb6650887e26b83a04bd9241b90f6`.', '',
        '## Por producto', '',
        'Los bytes de PRG son tamaños de archivo; no equivalen al uso de RAM en ejecución. RAM y límite de PRG proceden de `compiler.json`. Los 46 perfiles que publican límite de archivo admiten ambos binarios; los otros 72 se registran con límite desconocido (`null` en targets.json). `monkeydo` puede devolver 1 pese a PASS: se exige el resumen nativo y la traza de política.', '',
        'Los resultados por producto, tamaños de PRG y límites oficiales se conservan en [validation.csv](validation.csv), como referencia para futuras regresiones.', '']
    lines += ['', '## Renderizado representativo', '',
              'Una captura de producción por cada combinación relevante de forma, resolución y política: 20 grupos. Se observa el estado 1–1 con tarjetas completas, números legibles y RESET centrado; sin clipping ni solapamientos. No se requieren overrides visuales. Las capturas y logs permanecen bajo `bin/compatibility118/`, ignorados por Git.', '',
              '| Forma | Resolución | Política | Representante | Resultado |', '| --- | --- | --- | --- | --- |']
    for r in visual:
        lines.append(f"| {r['shape']} | {r['width']}×{r['height']} | {r['policy']} | {r['product_id']} | PASS |")
    counts = collections.Counter((r['icon_width'], r['icon_height']) for r in targets)
    lines += ['', '## Launcher', '',
              'Un PNG compartido, base 40×40, ocho qualifiers oficiales de geometría y 29 excepciones. Se reutilizan 35, 60 y 70; se añaden XML mínimos para 30, 36, 40×33, 54, 56, 61 y 65. No se duplican imágenes ni se modifica el marcador.', '',
              '| Dimensiones | Productos |', '| --- | ---: |']
    lines += [f'| {w}×{h} | {count} |' for (w, h), count in sorted(counts.items())]
    lines += ['', '## Exportación Store', '',
              f"Exportación oficial correcta: `{Path(export['file']).name}`, {export['bytes']} bytes, SHA-256 `{export['sha256']}`. Los 118 product IDs corresponden exactamente a {export['hardware_variants_verified']} part numbers oficiales: se comprueban sus PRG y, mediante debug.xml, la política exclusiva de cada variante. 0 warnings y 0 errores. El archivo .iq no se versiona ni se publica.", '',
              '## Reproducir', '', 'Desde garmin/, con el simulador abierto y los 118 perfiles oficiales instalados. Configurar SDK, KEY, PROFILES y AUDIT con las rutas del entorno; la clave permanece fuera del repositorio:', '', '```sh',
              'python3 tools/verify_targets.py --profiles "$PROFILES" --audit "$AUDIT"',
              'python3 tools/validate_compatibility.py build --sdk "$SDK" --key "$KEY" --profiles "$PROFILES"',
              'python3 tools/render_compatibility.py --sdk "$SDK" --profiles "$PROFILES"',
              'python3 tools/validate_compatibility.py test --sdk "$SDK" --key "$KEY" --profiles "$PROFILES"',
              'python3 tools/build.py --sdk "$SDK" --key "$KEY" --export', '```', '',
              'Los builds se aíslan por dispositivo y se paralelizan; el simulador se utiliza en serie. El capturador X11 requiere Pillow, libX11 y libXtst. No ejecutar el capturador simultáneamente con las suites nativas.', '',
              '## Pendiente de hardware físico', '',
              'FULL_PHYSICAL clasifica disposición de botones, no garantiza entrega de releases del firmware. Validar UP/MENU, DOWN/música, START/hotkeys y BACK/LAP/LIGHT en los 89 targets; sin release no se sintetiza una acción. En los 29 TOUCH, comprobar botones/menús libres y entrega de tap/hold/RESET y swipes de salida. En los modelos con 128 KiB de RAM (lista en targets.json), comprobar consumo con historial lleno y scores largos. Los conteos de botones inferidos por familia en la auditoría necesitan confirmación física. Vibración, touch lock y persistencia real siguen pendientes. No se incluyen perfiles NEEDS_ADAPTATION o INCOMPATIBLE ni se certifica firmware físico mediante simulación.', '']
    (doc / 'VALIDATION.md').write_text('\n'.join(lines))
    print(f'Report complete: {len(rows)} targets, {total} passing tests, {len(visual)} visual groups.')


if __name__ == '__main__':
    main()
