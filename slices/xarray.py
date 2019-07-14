#!/usr/bin/env python3
#------------------------------------------------------------------------------#
# Gets a slice along latitudes with xarray slicing
#------------------------------------------------------------------------------#
import xarray as xr
import os
import sys
filename = sys.argv[1]
nmax = int(sys.argv[2]) # zero-based indexing, endpoint exclusive
# Get slice of all variables
data = xr.open_dataset(filename, decode_times=False)
out = data.isel(time=slice(None,nmax))
# out = data.isel(lat=slice(None,4))
# Save sliced data
outname = f'out/slice_xr.nc'
if os.path.exists(outname):
    os.remove(outname)
out.to_netcdf(outname, mode='w') # specify whether we did chunking