#!/usr/bin/env python3
# Take slice with xarray indexing
import xarray as xr
import os
import sys
filename = sys.argv[1]
nmax = int(sys.argv[2])

# Load data
data = xr.open_dataset(filename, decode_times=False)
out = data.isel(time=slice(None, nmax))

# Save data
outname = 'out/slice_xr.nc'
if os.path.exists(outname):
    os.remove(outname)
out.to_netcdf(outname, mode='w')
