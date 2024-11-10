#!/usr/bin/env bash

set -o errexit

# charge workflows
workflow_charge_event_build='yamls/proto_nd_flow/workflows/charge/charge_event_building.yaml'
workflow_charge_event_reco='yamls/proto_nd_flow/workflows/charge/charge_event_reconstruction.yaml'
workflow_comb_reco='yamls/proto_nd_flow/workflows/combined/combined_reconstruction.yaml'
workflow_charge_hit_reco_prompt='yamls/proto_nd_flow/workflows/charge/prompt_calibration.yaml'
# workflow_charge_hit_reco_final='yamls/proto_nd_flow/workflows/charge/final_calibration.yaml'

# light workflows
workflow_light_event_build='yamls/proto_nd_flow/workflows/light/light_event_building_mpd.yaml'
workflow_light_event_reco='yamls/proto_nd_flow/workflows/light/light_event_reconstruction.yaml'

# charge-light trigger matching
workflow_charge_light_match='yamls/proto_nd_flow/workflows/charge/charge_light_assoc.yaml'

outf=$1; shift
chargef=$1; shift
read -r -a lightfs <<< "$@"; shift $#

echo cd _install/ndlar-flow

# Run light event building
for lightf in "${lightfs[@]}"; do
    echo h5flow -i "$lightf" -o "$outf" -c "$workflow_light_event_build"
done

echo h5flow -i "$outf" -o "$outf" -c "$workflow_light_event_reco"

echo h5flow -i "$chargef" -o "$outf" -c \
    "$workflow_charge_event_build" \
    "$workflow_charge_event_reco" \
    "$workflow_comb_reco" \
    "$workflow_charge_hit_reco_prompt" \

echo h5flow -i "$outf" -o "$outf" -c "$workflow_charge_light_match"
