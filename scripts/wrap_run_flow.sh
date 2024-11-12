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

mkdir -p "$(dirname "$outf")" "$(dirname "$logf")"

scripts/run_flow.sh "$outf" "$chargef" "${lightfs[@]}" | tee -a "$logf"
