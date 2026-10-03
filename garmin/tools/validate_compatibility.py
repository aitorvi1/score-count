#!/usr/bin/env python3
"""Build isolated official targets and run their native suites in one simulator.

Artifacts (including project snapshots, binaries and logs) stay under bin/.
Compilation can run concurrently; simulator test execution is always serial.
"""
import argparse
import concurrent.futures
import json
from pathlib import Path
import re
import shutil
import subprocess
import time

from verify_targets import ROOT, check


def write_results(path, results):
    temporary = path.with_suffix('.tmp')
    temporary.write_text(json.dumps(results, indent=2) + '\n')
    temporary.replace(path)


def run(command, cwd, timeout):
    start = time.monotonic()
    try:
        process = subprocess.run(command, cwd=cwd, stdout=subprocess.PIPE,
                                 stderr=subprocess.STDOUT, text=True, timeout=timeout)
        log, code = process.stdout, process.returncode
    except subprocess.TimeoutExpired as error:
        output = error.stdout or ''
        log = output.decode(errors='replace') if isinstance(output, bytes) else output
        log += '\nVALIDATION TIMEOUT\n'
        code = -1
    return log, code, round(time.monotonic() - start, 2)


def build(target, args):
    id = target['product_id']
    project = args.output / 'projects' / id
    project.mkdir(parents=True, exist_ok=True)
    # Keep full manifest and exact Jungle selection, with independent intermediates.
    for folder in ['source', 'policies', 'tests'] + [p.name for p in ROOT.glob('resources*') if p.is_dir()]:
        if (project / folder).exists():
            shutil.rmtree(project / folder)
        shutil.copytree(ROOT / folder, project / folder)
    for name in ['manifest.xml', 'monkey.jungle', 'tests.jungle']:
        shutil.copy2(ROOT / name, project / name)
    (project / 'bin').mkdir(exist_ok=True)
    row = dict(target)
    for mode in ['release', 'tests']:
        artifact = project / f'bin/ScoreCount-{mode}-{id}.prg'
        artifact.unlink(missing_ok=True)
        command = [str(args.sdk / 'bin/monkeyc'), '-f', 'monkey.jungle;tests.jungle' if mode == 'tests' else 'monkey.jungle',
                   '-y', str(args.key), '-w', '-d', id, '-o', str(artifact), '-t' if mode == 'tests' else '-r']
        log, code, seconds = run(command, project, 240)
        logpath = project / f'{mode}.log'
        logpath.write_text(log)
        warnings = [line for line in log.splitlines() if 'WARNING:' in line]
        errors = [line for line in log.splitlines() if 'ERROR:' in line]
        row['compile_' + mode] = dict(ok=code == 0 and not errors, returncode=code, seconds=seconds,
                                     warnings=warnings, errors=errors, program_bytes=artifact.stat().st_size if artifact.exists() else None,
                                     log=str(logpath.relative_to(args.output)))
    return row


def test(row, args):
    id = row['product_id']
    if not all(row.get('compile_' + mode, {}).get('ok') for mode in ['release', 'tests']):
        return dict(attempted=False, ok=False, reason='Release or tests compilation failed; target retained for investigation.')
    project = args.output / 'projects' / id
    log, code, seconds = run([str(args.sdk / 'bin/monkeydo'), str(project / f'bin/ScoreCount-tests-{id}.prg'), id, '-t'], ROOT, 65)
    logpath = project / 'native-tests.log'
    logpath.write_text(log)
    match = re.search(r'(PASSED|FAILED) \(passed=(\d+), failed=(\d+), errors=(\d+)\)', log)
    expected = 24 if row['policy'] == 'FULL_PHYSICAL' else 13
    policy_logged = f"Selected production policy: {row['policy']}" in log
    passed, failed, errors = [int(value) for value in match.groups()[1:]] if match else [None, None, None]
    return dict(attempted=True, ok=bool(match and match[1] == 'PASSED' and passed == expected and failed == 0 and errors == 0 and policy_logged),
                passed=passed, failed=failed, errors=errors, expected_tests=expected, policy_logged=policy_logged,
                returncode=code, seconds=seconds, log=str(logpath.relative_to(args.output)))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', choices=['build', 'test'])
    parser.add_argument('--sdk', type=Path, required=True)
    parser.add_argument('--key', type=Path, required=True)
    parser.add_argument('--profiles', type=Path, default=Path.home() / '.Garmin/ConnectIQ/Devices')
    parser.add_argument('--audit', type=Path)
    parser.add_argument('--output', type=Path, default=ROOT / 'bin/compatibility118')
    parser.add_argument('--jobs', type=int, default=4)
    parser.add_argument('--device', action='append', help='Explicit subset for an investigated rerun')
    args = parser.parse_args()
    args.sdk, args.key, args.output = args.sdk.resolve(), args.key.resolve(), args.output.resolve()
    if not args.output.is_relative_to(ROOT / 'bin'):
        parser.error('Validation artifacts must stay under garmin/bin/.')
    if not args.key.is_file():
        parser.error('Developer key path does not exist.')
    targets = check(args.profiles, args.audit)
    if args.device:
        assert set(args.device) <= {r['product_id'] for r in targets}
        targets = [r for r in targets if r['product_id'] in args.device]
    args.output.mkdir(parents=True, exist_ok=True)
    resultfile = args.output / 'results.json'
    results = json.loads(resultfile.read_text()) if resultfile.exists() else {}
    failures = []
    if args.mode == 'build':
        with concurrent.futures.ThreadPoolExecutor(max_workers=args.jobs) as pool:
            futures = [pool.submit(build, target, args) for target in targets]
            for index, future in enumerate(concurrent.futures.as_completed(futures), 1):
                row = future.result()
                results[row['product_id']] = row
                write_results(resultfile, results)
                ok = all(row['compile_' + mode]['ok'] for mode in ['release', 'tests'])
                if not ok:
                    failures.append(row['product_id'])
                warnings = sum(len(row['compile_' + mode]['warnings']) for mode in ['release', 'tests'])
                print(f"{index}/{len(targets)} {row['product_id']}: builds={'PASS' if ok else 'FAIL'} warnings={warnings}", flush=True)
    else:
        for index, target in enumerate(targets, 1):
            row = results[target['product_id']]
            assert row['policy'] == target['policy']
            row['native_tests'] = test(row, args)
            write_results(resultfile, results)
            if not row['native_tests']['ok']:
                failures.append(row['product_id'])
            print(f"{index}/{len(targets)} {row['product_id']} {row['policy']}: {row['native_tests']}", flush=True)
    print(f"Complete: {len(targets)} targets; failures={failures}", flush=True)
    raise SystemExit(1 if failures else 0)


if __name__ == '__main__':
    main()
