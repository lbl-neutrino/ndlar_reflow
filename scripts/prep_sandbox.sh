#!/usr/bin/env bash

tag=$1; shift
if [[ -z "$tag" ]]; then
    echo "Specify a tag (e.g. v8)"
    exit 1
fi

stages=(flow spine pandora caf caf.flat)

mapfile -t files <<EOF
packet-0050017-2024_07_09_01_54_45_CDT
packet-0050017-2024_07_09_01_44_44_CDT
packet-0050017-2024_07_09_01_34_42_CDT
packet-0050017-2024_07_09_01_24_41_CDT
packet-0050017-2024_07_09_01_14_40_CDT
packet-0050017-2024_07_09_01_04_39_CDT
packet-0050017-2024_07_09_00_54_38_CDT
packet-0050017-2024_07_09_00_44_37_CDT
packet-0050017-2024_07_09_00_34_36_CDT
packet-0050017-2024_07_09_00_24_35_CDT
packet-0050017-2024_07_09_00_14_34_CDT
packet-0050017-2024_07_09_00_04_33_CDT
EOF

indir=/global/cfs/cdirs/dune/www/data/2x2/reflows
outdir=/global/cfs/cdirs/dune/www/data/2x2/sandbox
subdir=beam/july8_2024/nominal_hv

# set -x
for stage in "${stages[@]}"; do
    mkdir -p "$outdir/$tag/$stage"
    for f in "${files[@]}"; do
        ln -s $indir/$tag/$stage/$subdir/$f* "$outdir/$tag/$stage"
    done
done

# Get Mx2 data from sandbox v4
ln -s "$outdir/v4/mx2_data" "$outdir/$tag"
