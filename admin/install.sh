#!/usr/bin/env bash

set -o errexit

module load python/3.11

mkdir -p _install
cd _install

python -m venv ndlar_reflow.venv
source ndlar_reflow.venv/bin/activate
pip install --upgrade pip setuptools wheel

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

pip install adc64format
