#!/usr/bin/env bash

set -o errexit
set -o pipefail

lightf=$ND_PRODUCTION_LIGHT_FILE
# split $ND_PRODUCTION_CHARGE_FILES into an array $chargefs
read -r -a chargefs <<< "$ND_PRODUCTION_CHARGE_FILES"

light_relpath=$(echo "$lightf" | sed "s|^$ND_PRODUCTION_INDIR_BASE/||")
light_reldir=$(dirname "$light_relpath")

outname=$(basename "$light_relpath" .data)$ND_PRODUCTION_FILE_TAG

# HACK for Run 2:
if [[ "$ND_PRODUCTION_LIGHT_FILE" == *LRS_run2* ]]; then
    # In MetaCat/Rucio we renamed the files to avoid conflicts with FSD files.
    # But our input files at NERSC have the original filenames.
    # So we modify $outname to be consistent with MetaCat/Rucio.
    outname=$(echo "$outname" | sed 's/mpd_run_data/mpd_run_run2data/')
fi

outf=$ND_PRODUCTION_OUTDIR_BASE/$light_reldir/$outname.FLOW.hdf5
logf=$ND_PRODUCTION_LOGDIR_BASE/$light_reldir/$outname.log

inner_script=scripts/really_run_flow.light_based.inc.sh
outer_script=scripts/run_flow.$ND_PRODUCTION_REFLOW_VARIANT.sh
if [[ ! -e "$outer_script" ]]; then
    echo "Unable to find $outer_script" 2>&1
    exit 1
fi

mkdir -p "$(dirname "$outf")" "$(dirname "$logf")"

/usr/bin/time -f "%P %M %E" "$outer_script" "$inner_script" \
    "$outf" "$lightf" "${chargefs[@]}" 2>&1 | tee -a "$logf"
