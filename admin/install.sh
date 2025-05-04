#!/usr/bin/env bash

set -o errexit

if [[ -z "$VIRTUAL_ENV" ]]; then
    echo "Please activate a virtual environment before running this installer"
    exit 1
fi

mkdir -p _install
cd _install

git clone -b main https://github.com/lbl-neutrino/h5flow.git
cd h5flow
pip install -e .
cd ..

git clone -b develop https://github.com/DUNE/ndlar_flow.git
cd ndlar_flow
pip install -e .
cd scripts/proto_nd_scripts
./get_proto_nd_input.sh
cd ../../..

git clone -b main https://github.com/larpix/adc64format.git
cd adc64format
pip install -e .
cd ..
