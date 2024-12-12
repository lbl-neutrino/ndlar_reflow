#!/usr/bin/env python3

import h5py

def chop_light(path_in: str, path_out: str):
    f_in = h5py.File(path_in)
    f_out = h5py.File(path_out, mode='w')

    c2l = f_in['/charge/events/ref/light/events/ref']
    l_evts = f_in['/light/events/data']

    # Get the indices of the first and last CL-matched light event
    c2l_l_evt_ids = c2l[:, 1]
    min_light_evt, max_light_evt = min(c2l_l_evt_ids), max(c2l_l_evt_ids)

    not2chop: list[str] = []
    data2chop: list[str] = []
    ref2chop: list[str] = []
    region2chop: list[str] = []

    def visit(name: str, thing):
        if not isinstance(thing, h5py.Dataset):
            return
        if not name.startswith('light'):
            # If it's not under /light, it doesn't need chopping
            not2chop.append(name)
        elif name.endswith('/data'):
            data2chop.append(name)
        elif name.endswith('/ref'):
            ref2chop.append(name)
        elif name.endswith('/ref_region'):
            region2chop.append(name)
        else:
            raise RuntimeError(f'WTF is {name}')

    f_in.visititems(visit)

    # Copy these ones as-is
    for name in not2chop:
        f_out.create_dataset(name, data=f_in[name])

    # These datasets should all have one entry per light event, so we already
    # know how to slice them
    for name in data2chop + region2chop:
        ds = f_in[name]
        assert ds.shape[0] == l_evts.shape[0]
        data = ds[min_light_evt:max_light_evt+1]
        f_out.create_dataset(name, data=data)

    # The ref datasets must be chopped according to whether the "source" (0th)
    # index refers to a chopped light event. Even the non-CL-matched light
    # events need to be considered here (e.g. event -> wvfm). We assume that
    # all the light datasets have the same shape[0] (= n_light_evt).
    for name in ref2chop:
        ref = f_in[name]
        ref_out = ref[(ref[:, 0] >= min_light_evt) & (ref[:, 0] <= max_light_evt)]
        f_out.create_dataset(name, data=ref_out)

    f_out.close()
