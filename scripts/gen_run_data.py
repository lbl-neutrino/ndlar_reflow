#!/usr/bin/env python3

import argparse
import sqlite3


HEADER = 'e_field charge_filename light_filename charge_thresholds light_samples'

# In the FSD, at a cathode voltage of (-)23.4 kV, drift field is 500 V/cm
KV_TO_VPERCM_FSD = 500 / 23.4

DEFAULT_CHARGE_THRESHOLDS = 'high'
DEFAULT_LIGHT_SAMPLES = 256


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('-d', '--run-db', required=True)
    ap.add_argument('-o', '--output', required=True)
    args = ap.parse_args()

    outf = open(args.output, 'w')
    outf.write(HEADER + '\n')

    conn = sqlite3.connect(args.run_db)

    q = 'SELECT c.filename, l.filename, s.HV_kV \
         FROM (All_global_subruns a JOIN SC_beam_summary s \
               ON a.global_subrun = s.global_subrun) \
         JOIN CRS_summary c \
              ON c.run = a.crs_run AND c.subrun = a.crs_subrun \
         JOIN LRS_summary l \
              ON l.run = a.lrs_run AND l.subrun = a.lrs_subrun'

    for row in conn.execute(q):
        charge_filename, light_filename, kV = row
        if charge_filename.startswith('binary-'):
            charge_filename = charge_filename.replace('binary-', 'packet-', 1)
        e_field = -kV * KV_TO_VPERCM_FSD
        charge_thresholds = DEFAULT_CHARGE_THRESHOLDS
        light_samples = DEFAULT_LIGHT_SAMPLES

        l = f'{e_field} {charge_filename} {light_filename} {charge_thresholds} {light_samples}'
        outf.write(l + '\n')

    conn.close()
    outf.close()

if __name__ == '__main__':
    main()
