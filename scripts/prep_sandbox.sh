#!/usr/bin/env bash

tag=$1; shift
if [[ -z "$tag" ]]; then
    echo "Specify a tag (e.g. v8)"
    exit 1
fi

mapfile -t files <<EOF
packet-0050017-2024_07_09_01_54_45_CDT.FLOW.hdf5
packet-0050017-2024_07_09_01_44_44_CDT.FLOW.hdf5
packet-0050017-2024_07_09_01_34_42_CDT.FLOW.hdf5
packet-0050017-2024_07_09_01_24_41_CDT.FLOW.hdf5
packet-0050017-2024_07_09_01_14_40_CDT.FLOW.hdf5
packet-0050017-2024_07_09_01_04_39_CDT.FLOW.hdf5
packet-0050017-2024_07_09_00_54_38_CDT.FLOW.hdf5
packet-0050017-2024_07_09_00_44_37_CDT.FLOW.hdf5
packet-0050017-2024_07_09_00_34_36_CDT.FLOW.hdf5
packet-0050017-2024_07_09_00_24_35_CDT.FLOW.hdf5
packet-0050017-2024_07_09_00_14_34_CDT.FLOW.hdf5
packet-0050017-2024_07_09_00_04_33_CDT.FLOW.hdf5
EOF

indir=/global/cfs/cdirs/dune/www/data/2x2/nearline/flowed_charge/REFLOW
outdir=/global/cfs/cdirs/dune/www/data/2x2/sandbox
subdir=beam/july8_2024/nominal_hv

mkdir -p "$outdir/$tag/flow"

for f in "${files[@]}"; do
    ln -s "$indir/$tag/$subdir/$f" "$outdir/$tag/flow"
done

# Get Mx2 data from sandbox v4
ln -s "$outdir/v4/mx2_data" "$outdir/$tag"
