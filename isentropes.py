#!/usr/bin/env python3
#------------------------------------------------------------------------------#
# Interpolate to isentropic levels
# NOTE: File cannot have any print statements! Need to capture output of
# time command
#------------------------------------------------------------------------------#
# Imports
# import cartopy.crs as ccrs
# import cartopy.feature as cfeature
# import matplotlib.pyplot as plt
import os
import sys
import numpy as np
import xarray as xr
import metpy.calc as mcalc
from metpy.units import units

# File, with optional decoding
if len(sys.argv)!=3:
    raise ValueError('Require two input args.')
filename = sys.argv[1]
dir = filename.split('/')[0]
nt = int(sys.argv[2]) # number of time chunks; 0 to disable chunking
if nt: # 1 chunk per level
    N = 100000 # max chunk size for lon/lat dimensions; want to chunk each 2D slice separately
    # N = 1000 # this made no difference
    chunks = {'time':nt, 'plev':N, 'lat':N, 'lon':N} # one chunk per horizontal slice, works pretty well
    data = xr.open_dataset(filename, chunks=chunks, decode_times=False)
else:
    data = xr.open_dataset(filename, decode_times=False)

# Interpoland
eps = 1
# thlev = np.array([*range(260, 360, 10), *range(360, 400, 20), *range(400, 800, 50), *range(800, 1600, 200)])
# thlev = np.array([*range(260, 360, 10), *range(360, 400, 20), *range(400, 800, 50)])
thlev = np.array([*range(300, 360, 10), *range(360, 400, 20)])
# Coordinates
times = data['time']
plev = data['plev']
lat = data['lat']
lon = data['lon']
# Variables
# u = data['u'][0]
u = data['u']
v = data['v']
t = data['t']
t = t*units.kelvin
thlev = thlev.astype('float32')*units.kelvin # assign units to input arg
plev = plev.values.astype('float32')*units.hectopascals

# Interpolation
# The returned 'p' are pressure along each isentrope
# NOTE: If temps out of bounds get error:
# raise ValueError('Input theta level out of data bounds')
# This should just be a warning, or optionally disabled!
t, u, v = t[0], u[0], v[0] # index first row, i.e. first timestep
p, t_th, u_th, v_th = mcalc.isentropic_interpolation(thlev, plev, t.values*units.kelvin, u.values, v.values, tmpk_out=True) # output isentropes in Kelvin
dims = ('thlev', 'lat', 'lon')
p = xr.Variable(dims, p.astype('float32'), {'long_name':'pressure', 'units':'hPa'})
t_th = xr.Variable(dims, t_th.astype('float32'), t.attrs)
u_th = xr.Variable(dims, u_th.astype('float32'), u.attrs)
v_th = xr.Variable(dims, v_th.astype('float32'), v.attrs)
# Make dataset, add variables and coordinates
# NOTE: Put coordinates in first, so they come first in ncdump
thlev = xr.Variable('thlev', thlev, {'long_name':'potential_temperature', 'units':'K'})
out = xr.Dataset({}, coords={'thlev':thlev, 'lat':lat, 'lon':lon})
for name,data in zip(('p','t','u','v'),(p,t_th,u_th,v_th)):
    out[name] = data
# out = xr.Dataset({'p':p, 't':t_th, 'u':u_th, 'v':v_th},
#                  {'thlev':thlev, 'lon':lon, 'lat':lat})

# Save file
outname = f'{dir}/isentropes_py{nt}.nc'
if os.path.exists(outname):
    os.remove(outname)
out.to_netcdf(outname, mode='w') # specify whether we did chunking

