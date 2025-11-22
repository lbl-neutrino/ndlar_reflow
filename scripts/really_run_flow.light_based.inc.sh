#!/usr/bin/env bash

# This file should be "sourced" after defining $workflow_blah variables
# (see run_flow.2x2.sh etc)

set -o errexit

true_outf=$(realpath "$1"); shift
lightf=$(realpath "$1"); shift
read -r -a chargefs <<< "$@"; shift $#

cd _install/ndlar_flow

outf=$true_outf.tmp
rm -f "$outf"

# Figure out what range of packets to cover from the charge files
get_range() {
    ../../scripts/get_charge_packet_range.py \
        --lightf "$lightf" \
        --first-chargef "$(realpath "${chargefs[0]}")" \
        --last-chargef "$(realpath "${chargefs[-1]}")"
}

# Enable compression
h5flow="h5flow -z lzf"

export HDF5_USE_FILE_LOCKING=FALSE


# Run light event building/reco
$h5flow -i "$(realpath "$lightf")" -o "$outf" -c \
    "$workflow_light_event_build" \
    "$workflow_light_event_reco"


if [[ -n "$chargefs" ]]; then
    read -r -a pkt_range <<< "$(get_range)"

    # Run charge event building
    for chargef in "${chargefs[@]}"; do
        extra_args=()
        if [[ "$chargef" == "${chargefs[0]}" ]]; then
            extra_args+=("--start_position" "${pkt_range[0]}")
        fi
        if [[ "$chargef" == "${chargefs[-1]}" ]]; then
            extra_args+=("--end_position" "${pkt_range[1]}")
        fi

        $h5flow -i "$chargef" -o "$outf" -c "$workflow_charge_event_build"
    done

    # Run charge reco...
    $h5flow -i "$outf" -o "$outf" -c \
        "$workflow_charge_event_reco" \
        "$workflow_comb_reco" \
        "$workflow_charge_hit_reco_prompt"

    # ...including final calib (optional)
    if [[ -n "$workflow_charge_hit_reco_final" ]]; then
        $h5flow -i "$outf" -o "$outf" -c "$workflow_charge_hit_reco_final"
    fi

    # Run charge/light matching
    $h5flow -i "$outf" -o "$outf" -c "$workflow_charge_light_match"
fi

mv "$outf" "$true_outf"
