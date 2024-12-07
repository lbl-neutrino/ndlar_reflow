This README is a work in progress.

# ndlar_reflow

Scripts for bulk processing of DUNE ND-LAr data (2x2, FSD) using [ndlar_flow](https://github.com/DUNE/ndlar_flow.git).

# Installation

The scripts in this repository assume that you've already got a recent version of Python loaded in your environment, and that you've activated a virtual environment. For example, at NERSC, you could have done:

``` bash
module load python/3.11
python -m venv $SCRATCH/ndlar_reflow.venv
source $SCRATCH/ndlar_reflow.venv/bin/activate
```

Assuming you've done something like the above, you can proceed to clone the repository and run the install script (which installs ndlar_flow and its dependencies into the active virtual env):

``` bash
cd $SCRATCH
git clone https://github.com/lbl-neutrino/ndlar_reflow
cd ndlar_reflow
admin/install.sh
```

# Operation

The heavy lifting is done by `scripts/run_flow.2x2.sh` (or the `FSD` equivalent), which expects the following arguments in the following order:
- First, the path of the output HDF5 file that ndlar_flow will produce
- Second, the path of the charge input file (in HDF5 "packet" format)
- Third and onward, the paths of the light input files (in the DAQ's binary format)

For more convenient integration with workflow management systems (e.g. justIN), there is a wrapper script `scripts/wrap_run_flow.sh` that is controlled by environment variables (rather than command-line arguments) and automatically determines the path of the output file. It expects the following environment variables:
- `ARCUBE_REFLOW_VARIANT`: Either `2x2` or `FSD`; selects the appropriate inner script
- `ARCUBE_INDIR_BASE`: The "base directory" for the charge input files (e.g. `/global/cfs/cdirs/dune/www/data/2x2/CRS`). Any further subdirectory structure will be recreated in the output/log directories.
- `ARCUBE_OUTDIR_BASE`: The base directory where the output HDF5 file will be written (in the appropriate subdirectory, based on the path of the input charge file).
- `ARCUBE_LOGDIR_BASE`: The directory where the log file will be written (in the appropriate subdirectory).
- `ARCUBE_CHARGE_FILE`: The full path to the input charge file
- `ARCUBE_LIGHT_FILES`: A space-separated list of all the input light files

Within a given reflow campaign, these environment "variables" will be constants, except for the last two.

# Bulk processing

For a bulk reflow, the first step is to generate the JSON file that contains the list of (sets of) input files, where each "set" consists of one charge file and all of the light files that have any overlap with the charge file:

``` bash
run_db=/global/cfs/cdirs/dune/www/data/FSD/run_db/fsd_run_db.20241125.sqlite
scripts/gen_input_list.py -d $run_db -o inputs.json
```

The resulting `inputs.json` can then be used to prepare jobs for the system of your choice ([FireWorks example](https://github.com/lbl-neutrino/fireworks4dune/tree/develop/scripts/fwsub_reflow.py)). Each job should set up the environment (Python + venv), set the various `ARCUBE_` environment variables, cd into `ndlar_reflow`, and run `scripts/wrap_run_flow.sh` (without any arguments).
