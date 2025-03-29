#!/usr/bin/env bash

# charge workflows
workflow_charge_event_build='yamls/proto_nd_flow/workflows/charge/charge_event_building_data.yaml'
workflow_charge_event_reco='yamls/proto_nd_flow/workflows/charge/charge_event_reconstruction_data.yaml'
workflow_comb_reco='yamls/proto_nd_flow/workflows/combined/combined_reconstruction_data.yaml'
workflow_charge_hit_reco_prompt='yamls/proto_nd_flow/workflows/charge/prompt_calibration_data.yaml'
workflow_charge_hit_reco_final='yamls/proto_nd_flow/workflows/charge/final_calibration_data.yaml'

# light workflows
workflow_light_event_build='yamls/proto_nd_flow/workflows/light/light_event_building_mpd.yaml'
workflow_light_event_reco='yamls/proto_nd_flow/workflows/light/light_event_reconstruction_data.yaml'

# charge-light trigger matching
workflow_charge_light_match='yamls/proto_nd_flow/workflows/charge/charge_light_assoc_data.yaml'

source "$(dirname "$0")/really_run_flow.inc.sh"
