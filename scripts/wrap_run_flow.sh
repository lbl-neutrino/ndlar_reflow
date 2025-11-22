#!/usr/bin/env bash

set -o errexit
set -o pipefail

chargef=$ND_PRODUCTION_CHARGE_FILE
# split $ND_PRODUCTION_LIGHT_FILES into an array $lightfs
read -r -a lightfs <<< "$ND_PRODUCTION_LIGHT_FILES"

charge_relpath=$(echo "$chargef" | sed "s|^$ND_PRODUCTION_INDIR_BASE/||")
charge_reldir=$(dirname "$charge_relpath")
charge_ext=${charge_relpath##*.} # h5 or hdf5

outname=$(basename "$charge_relpath" ."$charge_ext")$ND_PRODUCTION_FILE_TAG

outf=$ND_PRODUCTION_OUTDIR_BASE/$charge_reldir/$outname.FLOW.hdf5
logf=$ND_PRODUCTION_LOGDIR_BASE/$charge_reldir/$outname.log

inner_script=scripts/really_run_flow.inc.sh
outer_script=scripts/run_flow.$ND_PRODUCTION_REFLOW_VARIANT.sh
if [[ ! -e "$outer_script" ]]; then
    echo "Unable to find $outer_script" 2>&1
    exit 1
fi

mkdir -p "$(dirname "$outf")" "$(dirname "$logf")"

/usr/bin/time -f "%P %M %E" "$outer_script" "$inner_script" \
    "$outf" "$chargef" "${lightfs[@]}" 2>&1 | tee -a "$logf"
