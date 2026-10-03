#!/usr/bin/env python3
"""Read-only checks for the audited 118-target Jungle configuration."""
import argparse
import collections
import csv
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
NS = {'iq': 'http://www.garmin.com/xml/connectiq'}


def assignments(path):
    pairs = []
    for line in path.read_text().splitlines():
        line = line.split('#', 1)[0].strip()
        if line:
            key, value = line.split('=', 1)
            pairs.append((key.strip(), value.strip()))
    return pairs


def check(profiles, audit=None):
    targets = json.loads((ROOT / 'compatibility/targets.json').read_text())
    expected = (ROOT / 'compatibility/recommended-product-ids.txt').read_text().split()
    manifest = ET.parse(ROOT / 'manifest.xml')
    app = manifest.find('iq:application', NS)
    ids = [node.attrib['id'] for node in app.find('iq:products', NS)]
    assert len(ids) == len(set(ids)) == len(expected) == len(set(expected)) == 118
    assert ids == expected == [r['product_id'] for r in targets]
    assert app.attrib['id'] == '854c3e8cfc934e58a1f4202b2b30de16'
    assert app.attrib['minApiLevel'] == '2.4.0' and app.attrib['version'] == '1.0.0'
    assert collections.Counter(r['policy'] for r in targets) == {'FULL_PHYSICAL': 89, 'TOUCH': 29}
    assert not set(ids) & {'vivoactive3', 'vivoactive3d', 'vivoactive3m', 'vivoactive3mlte',
                           'vivoactive_hr', 'fenix3', 'fenix3_hr'}
    if audit:
        audited_ids = (audit / 'recommended-product-ids.txt').read_text().split()
        rows = {r['product_id']: r for r in json.loads((audit / 'compatibility.json').read_text())}
        with (audit / 'compatibility.csv').open(encoding='utf-8-sig') as f:
            csvrows = {r['product_id']: r for r in csv.DictReader(f)}
        report = (audit / 'report.md').read_text()
        assert ids == audited_ids and '118' in report
        assert set(ids) == {id for id, r in rows.items() if r['recommended']}
        for r in targets:
            id = r['product_id']
            assert rows[id]['classification'] == csvrows[id]['classification'] == r['classification']
            assert r['classification'] in {'FULL_PHYSICAL', 'SAFE_HYBRID'}
            assert r['policy'] == ('FULL_PHYSICAL' if r['classification'] == 'FULL_PHYSICAL' else 'TOUCH')
    production = assignments(ROOT / 'monkey.jungle')
    testing = assignments(ROOT / 'tests.jungle')
    for config in [production, testing]:
        selectors = [key.removesuffix('.sourcePath') for key, _ in config
                     if key.endswith('.sourcePath') and key != 'base.sourcePath']
        assert len(selectors) == len(set(selectors)) == 118 and set(selectors) == set(ids)
    for target in targets:
        id = target['product_id']
        compiler = json.loads((profiles / id / 'compiler.json').read_text())
        family = compiler['deviceFamily']
        assert family == target['device_family']
        policy = 'full-physical' if target['policy'] == 'FULL_PHYSICAL' else 'touch'
        for include_tests in [False, True]:
            # Resolve this project's explicit base/geometry/product expressions.
            # Self references preserve the previous expression; base references
            # resolve against the final base path (including common tests).
            paths = {'base.sourcePath': 'source', 'base.resourcePath': 'resources'}
            for key, value in production + (testing if include_tests else []):
                qualifier = key.rsplit('.', 1)[0]
                if key not in {'base.sourcePath', 'base.resourcePath'} and qualifier not in {family, id}:
                    continue
                if not key.endswith(('.sourcePath', '.resourcePath')):
                    continue
                field = key.rsplit('.', 1)[1]
                previous = paths.get(key, paths.get(f'{family}.{field}', paths[f'base.{field}']))
                paths[key] = value.replace('$(' + key + ')', previous)
            def expand(value):
                for _ in range(10):
                    result = re.sub(r'\$\(([^)]+)\)', lambda m: paths[m[1]], value)
                    if result == value:
                        return result.split(';')
                    value = result
                raise AssertionError('Cyclic Jungle path')
            source = expand(paths[f'{id}.sourcePath'])
            expected_source = ['source'] + (['tests/common'] if include_tests else []) + [f'policies/{policy}']
            if include_tests:
                expected_source += [f'tests/{policy}']
            assert source == expected_source, (id, source, expected_source)
            classes = [file for directory in source for file in (ROOT / directory).rglob('*.mc')
                       if re.search(r'\bclass\s+ScoreCountDelegate\s+extends\b', file.read_text())]
            assert classes == [ROOT / f'policies/{policy}/ScoreCountDelegate.mc'], (id, classes)
            icon = None
            resource_expr = paths.get(f'{id}.resourcePath', paths.get(f'{family}.resourcePath', paths['base.resourcePath']))
            for directory in expand(resource_expr):
                for file in (ROOT / directory).rglob('*.xml'):
                    bitmap = ET.parse(file).getroot().find(".//bitmap[@id='LauncherIcon']")
                    if bitmap is not None:
                        icon = (int(bitmap.attrib['scaleX']), int(bitmap.attrib['scaleY']))
            assert icon == (compiler['launcherIcon']['width'], compiler['launcherIcon']['height']), (id, icon)
        target['release_source_paths'] = ['source', f'policies/{policy}']
        target['test_source_paths'] = expected_source
    return targets


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--profiles', type=Path, default=Path.home() / '.Garmin/ConnectIQ/Devices')
    parser.add_argument('--audit', type=Path)
    args = parser.parse_args()
    rows = check(args.profiles, args.audit)
    print(f'PASS: {len(rows)} exact targets; 89 FULL_PHYSICAL, 29 TOUCH; unique delegates and matching suites in both modes; exact launcher dimensions; stable UUID/API/version.')


if __name__ == '__main__':
    main()
