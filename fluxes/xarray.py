#!/usr/bin/env python3
################################################################################
# Get fluxes with python
################################################################################
# First load file
# def import_global(name, custom_name=None):
#     custom_name = custom_name or name
#     f, pathname, desc = imp.find_module(name, sys.path[1:])
#     module = imp.load_module(custom_name, f, pathname, desc)
#     f.close()
#     return module
import os
import sys
import imp
import xarray as xr
filename = sys.argv[1]
nt = int(sys.argv[2]) # number of time chunks; 0 to disable chunking
if nt: # 1 chunk per level
    N = 100000 # max chunk size for lon/lat dimensions; want to chunk each 2D slice separately
    # N = 1000 # this made no difference
    chunks = {'time':nt, 'plev':N, 'lat':N, 'lon':N} # one chunk per horizontal slice, works pretty well
    data = xr.open_dataset(filename, chunks=chunks, decode_times=False)
else:
    data = xr.open_dataset(filename, decode_times=False)

# Next perform calculations
emf = ((data['u'] - data['u'].mean('lon')) * (data['v'] - data['v'].mean('lon'))).mean('lon')
ehf = ((data['t'] - data['t'].mean('lon')) * (data['v'] - data['v'].mean('lon'))).mean('lon')
emf.name = 'emf'
ehf.name = 'ehf'
emf.attrs = {'long_name':'eddy momentum flux', 'units':'m**2/s**2'}
ehf.attrs = {'long_name':'eddy heat flux', 'units':'K*m/s'}

# Save file
out = xr.Dataset({'emf':emf, 'ehf':ehf})
outname = f'out/xarray_{nt}.nc'
if os.path.exists(outname):
    os.remove(outname)
out.to_netcdf(outname, mode='w') # specify whether we did chunking
