#!/usr/bin/env python3

import argparse
from collections import defaultdict
import json
import sqlite3


def get_crs2friends(conn: sqlite3.Connection, include_mx2: bool):
    crs2friends = {}

    mx2_cols, mx2_join, mx2_order = '', '', ''
    if include_mx2:
        mx2_cols = ', m.nersc_path'
        mx2_join = "LEFT JOIN Mx2_summary m ON (a.mx2_run = m.run AND a.mx2_subrun = m.subrun)"
        mx2_order = ', mx2_run, mx2_subrun'

    q = f"SELECT c.nersc_path, l.nersc_path {mx2_cols} from All_global_subruns a" + \
        f" JOIN CRS_summary c ON (a.crs_run = c.run AND a.crs_subrun = c.subrun)" + \
        f" LEFT JOIN LRS_summary l ON (a.lrs_run = l.run AND a.lrs_subrun = l.subrun)" + \
        f" {mx2_join}" + \
        f" ORDER BY crs_run, crs_subrun, lrs_run, lrs_subrun {mx2_order}"

    for row in conn.execute(q):
        crs_path, lrs_path = row[:2]
        if crs_path not in crs2friends:
            crs2friends[crs_path] = defaultdict(list)
        if lrs_path and lrs_path not in crs2friends[crs_path]['LIGHT']:
            crs2friends[crs_path]['LIGHT'].append(lrs_path)
        if include_mx2:
            mx2_path = row[2]
            if mx2_path and mx2_path not in crs2friends[crs_path]['MINERVA']:
                crs2friends[crs_path]['MINERVA'].append(mx2_path)

    return crs2friends


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('-d', '--db-file',
                    help='RunDB sqlite file',
                    required=True)
    ap.add_argument('-o', '--output',
                    help='Output json file',
                    required=True)
    ap.add_argument('-m', '--include-mx2', action='store_true')
    args = ap.parse_args()

    result = []

    conn = sqlite3.connect(args.db_file)
    crs2friends = get_crs2friends(conn, args.include_mx2)

    for crs_path, friends in crs2friends.items():
        lrs_paths = friends['LIGHT']
        spec = {
            'ARCUBE_CHARGE_FILE': crs_path,
            # hope there ain't no spaces in them paths
            'ARCUBE_LIGHT_FILES': ' '.join(lrs_paths) if lrs_paths else '',
        }
        if args.include_mx2:
            mx2_paths = friends['MINERVA']
            spec['ARCUBE_MINERVA_FILES'] = ' '.join(mx2_paths) if mx2_paths else ''
        result.append(spec)

    with open(args.output, 'w') as f:
        json.dump(result, f, indent=4)

    conn.close()


if __name__ == '__main__':
    main()
