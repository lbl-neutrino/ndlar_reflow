#!/usr/bin/env bash

# This file should be "sourced" after defining $workflow_blah variables
# (see run_flow.2x2.sh etc)

set -o errexit

true_outf=$(realpath "$1"); shift
chargef=$(realpath "$1"); shift
read -r -a lightfs <<< "$@"; shift $#

cd _install/ndlar_flow

outf=$true_outf.tmp
rm -f "$outf"

# Figure out what range of events to cover from the light files

get_range() {
    ../../scripts/get_light_event_range.py \
        --workflow "$workflow_light_event_build" \
        --chargef "$chargef" \
        --first-lightf "$(realpath "${lightfs[0]}")" \
        --last-lightf "$(realpath "${lightfs[-1]}")" \
        --tmpdir "$(dirname "$outf")"
}

# Enable compression
h5flow="h5flow -z lzf"

if [[ -n "$lightfs" ]]; then
    read -r -a evt_range <<< "$(get_range)"

    # Run light event building
    for lightf in "${lightfs[@]}"; do
       extra_args=()
       if [[ "$lightf" == "${lightfs[0]}" ]]; then
           extra_args+=("--start_position" "${evt_range[0]}")
       fi
       if [[ "$lightf" == "${lightfs[-1]}" ]]; then
           extra_args+=("--end_position" "${evt_range[1]}")
       fi

       $h5flow -i "$(realpath "$lightf")" -o "$outf" -c "$workflow_light_event_build" "${extra_args[@]}"
    done

    if [[ -n "$workflow_light_event_reco" ]]; then
        $h5flow -i "$outf" -o "$outf" -c "$workflow_light_event_reco"
    fi
fi

if [[ -n "$workflow_charge_hit_reco_final" ]]; then
    $h5flow -i "$chargef" -o "$outf" -c \
        "$workflow_charge_event_build" \
        "$workflow_charge_event_reco" \
        "$workflow_comb_reco" \
        "$workflow_charge_hit_reco_prompt" \
        "$workflow_charge_hit_reco_final"
else
    $h5flow -i "$chargef" -o "$outf" -c \
        "$workflow_charge_event_build" \
        "$workflow_charge_event_reco" \
        "$workflow_comb_reco" \
        "$workflow_charge_hit_reco_prompt"
fi


if [[ -n "$lightfs" ]]; then
    $h5flow -i "$outf" -o "$outf" -c "$workflow_charge_light_match"
fi

mv "$outf" "$true_outf"
