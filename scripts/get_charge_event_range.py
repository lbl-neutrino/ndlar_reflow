#!/usr/bin/env python3

import argparse
from pathlib import Path
from subprocess import DEVNULL, check_call
from tempfile import TemporaryDirectory

import h5py
import numpy as np


def get_limits(lf: h5py.File, first_cf: h5py.File, last_cf: h5py.File) \
        -> tuple[int, int]:
    """Based on the time range of the light file `lf`, returns --start_position
       for the charge file `first_cf` and --end_position for the charge file
       `last_cf`. `first_cf` and `last_cf` may be the same file. """
    pass


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--lightf', type=Path, required=True)
    ap.add_argument('--first-chargef', type=Path, required=True)
    ap.add_argument('--last-chargef', type=Path,
                    help='May be the same as --first-chargef')
    args = ap.parse_args()

    first_chargef_h5 = h5py.File(args.first_chargef)

    if args.last_chargef and args.last_chargef != args.first_chargef:
        last_chargef_h5 = h5py.File(args.last_chargef)
    else:
        last_chargef_h5 = first_chargef_h5

    lightf_h5 = h5py.File(args.lightf)

    start_pos, end_pos = get_limits(lightf_h5, first_chargef_h5, last_chargef_h5)

    print(start_pos, end_pos)


if __name__ == '__main__':
    main()
