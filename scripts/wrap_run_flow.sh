#!/usr/bin/env bash

set -o errexit
set -o pipefail

chargef=$ARCUBE_CHARGE_FILE
# split $ARCUBE_LIGHT_FILES into an array $lightfs
read -r -a lightfs <<< "$ARCUBE_LIGHT_FILES"

charge_relpath=$(echo "$chargef" | sed "s|^$ARCUBE_INDIR_BASE/||")
charge_reldir=$(dirname "$charge_relpath")
charge_ext=${charge_relpath##*.}
outf=$ARCUBE_OUTDIR_BASE/$charge_reldir/$(basename "$charge_relpath" ."$charge_ext").FLOW.hdf5
logf=$ARCUBE_LOGDIR_BASE/$charge_reldir/$(basename "$charge_relpath" ."$charge_ext").log

script=scripts/run_flow.$ARCUBE_REFLOW_VARIANT.sh
if [[ ! -e "$script" ]]; then
    echo "Unable to find $script" 2>&1
    exit 1
fi

mkdir -p "$(dirname "$outf")" "$(dirname "$logf")"

/usr/bin/time -f "%P %M %E" "$script" "$outf" "$chargef" "${lightfs[@]}" | tee -a "$logf"
