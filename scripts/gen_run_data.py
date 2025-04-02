#!/usr/bin/env python3

import argparse
import sqlite3


HEADER = 'e_field charge_filename light_filename charge_thresholds light_samples'

KV_TO_VPERCM = {
    '2x2': 500 / 26.2,
    'fsd': 500 / 23.4,
}

HV_EXPRESSION = {
    '2x2': '-s.Mean_Spellman_set_voltage_kV', # note negative sign!
    'fsd': 's.HV_kV',
}

DEFAULT_CHARGE_THRESHOLDS = 'high'
DEFAULT_LIGHT_SAMPLES = 256


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('-d', '--run-db', required=True)
    ap.add_argument('-o', '--output', required=True)
    ap.add_argument('-c', '--config', required=True,
                    choices=['2x2', 'fsd'])
    args = ap.parse_args()

    outf = open(args.output, 'w')
    outf.write(HEADER + '\n')

    conn = sqlite3.connect(args.run_db)

    hv_expr = HV_EXPRESSION[args.config]

    q = f'SELECT c.filename, l.filename, {hv_expr} \
          FROM (All_global_subruns a JOIN SC_beam_summary s \
                ON a.global_subrun = s.global_subrun) \
          JOIN CRS_summary c \
               ON c.run = a.crs_run AND c.subrun = a.crs_subrun \
          LEFT JOIN LRS_summary l \
               ON l.run = a.lrs_run AND l.subrun = a.lrs_subrun'

    for row in conn.execute(q):
        charge_filename, light_filename, kV = row
        if charge_filename.startswith('binary-'):
            charge_filename = charge_filename.replace('binary-', 'packet-', 1)
        e_field = -kV * KV_TO_VPERCM[args.config]
        charge_thresholds = DEFAULT_CHARGE_THRESHOLDS
        light_samples = DEFAULT_LIGHT_SAMPLES

        # Use something more distinct than "None", to prevent accidental
        # matching of a file that happens to have "None" in its path
        if light_filename is None:
            light_filename = 'THERE_IS_NO_LIGHT_ONLY_DARKNESS'

        l = f'{e_field:.3f} {charge_filename} {light_filename} {charge_thresholds} {light_samples}'
        outf.write(l + '\n')

    conn.close()
    outf.close()

if __name__ == '__main__':
    main()
