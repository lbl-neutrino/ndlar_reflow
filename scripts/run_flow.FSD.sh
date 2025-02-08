#!/usr/bin/env bash

set -o errexit

# charge workflows
workflow_charge_event_build='yamls/fsd_flow/workflows/charge/charge_event_building.yaml'
workflow_charge_event_reco='yamls/fsd_flow/workflows/charge/charge_event_reconstruction.yaml'
workflow_comb_reco='yamls/fsd_flow/workflows/combined/combined_reconstruction.yaml'
workflow_charge_hit_reco_prompt='yamls/fsd_flow/workflows/charge/prompt_calibration.yaml'
# workflow_charge_hit_reco_final='yamls/fsd_flow/workflows/charge/final_calibration.yaml'

# light workflows
workflow_light_event_build='yamls/fsd_flow/workflows/light/light_event_building_mpd.yaml'
workflow_light_event_reco='yamls/fsd_flow/workflows/light/light_event_reconstruction.yaml'

# charge-light trigger matching
workflow_charge_light_match='yamls/fsd_flow/workflows/charge/charge_light_assoc.yaml'

outf=$(realpath "$1"); shift
chargef=$(realpath "$1"); shift
read -r -a lightfs <<< "$@"; shift $#

cd _install/ndlar_flow

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

read -r -a evt_range <<< "$(get_range)"

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

    # $h5flow -i "$outf" -o "$outf" -c "$workflow_light_event_reco"
fi

$h5flow -i "$chargef" -o "$outf" -c \
    "$workflow_charge_event_build" \
    "$workflow_charge_event_reco" \
    "$workflow_comb_reco" \
    "$workflow_charge_hit_reco_prompt"

if [[ -n "$lightfs" ]]; then
    $h5flow -i "$outf" -o "$outf" -c "$workflow_charge_light_match"
fi
