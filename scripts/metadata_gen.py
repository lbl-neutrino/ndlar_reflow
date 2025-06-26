#!/usr/bin/env python3

import argparse
import json
from pathlib import Path
import sqlite3
import zlib

import h5py


PACKET_BASE = '/global/cfs/cdirs/dune/www/data/2x2/nearline/packet'
RAW_BASE = '/global/cfs/cdirs/dune/www/data/2x2/CRS'
FLOW_BASE = '/global/cfs/cdirs/dune/www/data/2x2/reflows/v11/flow'

RUNS_DB = '/pscratch/sd/m/mkramer/devel/BlobCraft2x2/mx2x2runs_v0.2.sqlite'

FLOW_VERSION = 'v1.5.0'
CAMPAIGN = 'run1'
CONFIG_FILE = 'run_flow.2x2.sh'

RUN_TO_LOCAL_SUBRUN  = 10000
RUN_TO_GLOBAL_SUBRUN = 10000000


def get_checksum(datapath: Path, chunksize=1_000_000_000) -> int:
    cksum = 1
    with open(datapath, 'rb') as f:
        while data := f.read(chunksize):
            cksum = zlib.adler32(data, cksum)
    return cksum & 0xffffffff


def packet2raw(packet_path: Path) -> Path:
    assert packet_path.name.startswith('packet')
    raw_filename = packet_path.name.replace('packet', 'binary', 1)
    return (Path(RAW_BASE)
            / packet_path.parent.relative_to(PACKET_BASE)
            / raw_filename)


def packet2flow(packet_path: Path) -> Path:
    flow_filename = Path(packet_path.stem).with_suffix('.FLOW.hdf5')
    return (Path(FLOW_BASE)
            / packet_path.parent.relative_to(PACKET_BASE)
            / flow_filename)


def format_parents(raw_file: Path, lrs_files: list[Path]):
    raw_filename_hdf5 = raw_file.with_suffix('.hdf5')
    parents = [{'did': f'neardet-2x2-lar-charge:{raw_filename_hdf5.name}'}]
    for lrs_file in lrs_files:
        parents.append({'did': f'neardet-2x2-lar-light:{lrs_file.name}'})
    return parents


def get_nevents(flow_file: Path):
    with h5py.File(flow_file) as f:
        return f['charge/events/data'].shape[0]


def get_local_subrun(conn: sqlite3.Connection, path: Path, table: str):
    q = f"SELECT run, subrun FROM {table} " + \
        f"WHERE filename = '{path.name}'"
    run, subrun = conn.execute(q).fetchone()
    return run*RUN_TO_LOCAL_SUBRUN + subrun


def get_global_subruns(conn: sqlite3.Connection, crs_local_subrun: int):
    q = "SELECT global_subrun from All_global_subruns " + \
        f"WHERE crs_run={crs_local_subrun // RUN_TO_LOCAL_SUBRUN} " + \
        f"AND crs_subrun={crs_local_subrun % RUN_TO_LOCAL_SUBRUN}"
    global_subruns = list(conn.execute(q).fetchone())
    global_run = global_subruns[0] // RUN_TO_GLOBAL_SUBRUN
    return global_run, global_subruns


def get_runs(raw_file: Path, lrs_files: list[Path]):
    conn = sqlite3.connect(RUNS_DB)

    crs_local_subrun = get_local_subrun(conn, raw_file, 'crs_summary')
    lrs_local_subruns = [get_local_subrun(conn, lrs_file, 'lrs_summary')
                         for lrs_file in lrs_files]

    global_run, global_subruns = get_global_subruns(conn, crs_local_subrun)

    return global_run, global_subruns, [crs_local_subrun], lrs_local_subruns


def metadata_gen(packet_file: Path, lrs_files: list[Path]):
    raw_file = packet2raw(packet_file)
    flow_file = packet2flow(packet_file)

    crs_json = json.load(open(raw_file.with_suffix('.h5.json')))
    # lrs_jsons = [json.load(open(lrs_file.with_suffix('.json')))
    #              for lrs_file in lrs_files]

    output = {}
    output['parents'] = format_parents(raw_file, lrs_files)
    output['name'] = packet_file.with_suffix('.FLOW.hdf5').name
    output['namespace'] = 'neardet-2x2-lar'
    output['creator'] = 'mkramer'
    output['size'] = flow_file.stat().st_size
    output['checksums'] = {'adler32': f'{get_checksum(flow_file):08x}'}

    meta = {}
    meta['core.data_tier'] = 'flow'
    meta['core.data_stream'] = crs_json['metadata']['core.data_stream']
    meta['core.start_time'] = crs_json['metadata']['core.start_time']
    meta['core.end_time'] = crs_json['metadata']['core.end_time']
    meta['core.file_format'] = 'hdf5'
    meta['core.file_type'] = 'detector'
    meta['core.application.family'] = 'ndlar_flow'
    meta['core.application.name'] = 'flow'
    meta['core.application.version'] = FLOW_VERSION
    meta['core.events'] = get_nevents(flow_file)
    meta['core.first_event_number'] = 0
    meta['core.last_event_number'] = meta['core.events'] - 1
    meta['core.file_content_status'] = 'good'
    meta['dune.dqc_quality'] = 'unknown'
    meta['dune.campaign'] = CAMPAIGN
    meta['dune.requestid'] = ''
    meta['dune.config_file'] = CONFIG_FILE
    meta['dune.workflow'] = 'ndlar_reflow'
    meta['dune.output_status'] = 'good'
    meta['retention.status'] = 'active'
    meta['retention.class'] = 'physics'

    runs, global_subruns, crs_subruns, lrs_subruns = get_runs(raw_file,
                                                              lrs_files)

    meta['core.runs'] = runs
    meta['core.runs_subruns'] = global_subruns
    meta['dune.ndlar_charge_subrun_numbers'] = crs_subruns
    meta['dune.ndlar_light_subrun_numbers'] = lrs_subruns

    output['metadata'] = meta

    print(json.dumps(output, indent=4))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('packet_files', type=Path)
    ap.add_argument('lrs_files', nargs='*', type=Path)
    args = ap.parse_args()

    metadata_gen(args.packet_files, args.lrs_files)


if __name__ == '__main__':
    main()
