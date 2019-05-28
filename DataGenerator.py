#!/usr/bin/env python3
# Generate random datasets with xarray and Dask, easiest way
# Then can test some very simple operations across several different methods
import os
import numpy as np
import dask.array as da
import xarray as xr
import datetime
import sys

# Check
try:
    dir = sys.argv[1]
    reso = float(sys.argv[2])
except ValueError:
    raise ValueError('Usage is ./DataGenerator <directory> <resolution>.')
if not os.path.isdir(dir):
    os.mkdir(dir)
print(f'Directory: {dir} Resolution: {reso}')

# Dimensions
print('Initial stuff.')
dtype = np.float32
step = 2
if dir=='1lev':
    ntime = 1000
    plev = np.array([500.0], dtype=dtype)
elif dir=='60lev':
    ntime = 200
    plev = np.linspace(0, 1013.25, 61, dtype=dtype)
    plev = (plev[1:] + plev[:-1])/2
else:
    raise ValueError('Unknown configuration for data generator "{dir}". Add to this script.')
time = np.arange(1/step, ntime, dtype=dtype)/step
lat = np.arange(-90 + reso/2, 90, reso, dtype=dtype)
lon = np.arange(-180 + reso/2, 180, reso, dtype=dtype)
# Variables
shape = (time.size, plev.size, lat.size, lon.size)
params = ('u', 'v', 't')
params_attrs = {
    'u': {'long_name':'zonal wind', 'units':'m/s'},
    'v': {'long_name':'meridional wind', 'units':'m/s'},
    't': {'long_name':'temperature', 'units':'K'}
    }
# Coordinates
coords = ('time', 'plev', 'lat', 'lon')
coords_values = {
    'time': time,
    'plev': plev,
    'lat': lat,
    'lon': lon,
    }
coords_attrs = {
    'time': {'long_name':'time', 'calendar':'360_day', 'units':'days since 00-01-01 00:00:00', 'axis':'T'},
    'plev': {'long_name':'pressure level', 'units':'hPa', 'axis':'Z'},
    'lat': {'long_name':'latitude',  'units':'degN', 'axis':'Y'},
    'lon': {'long_name':'longitude', 'units':'degE', 'axis':'X'},
    }
for attrs in coords_attrs.values():
    attrs['standard_name'] = attrs['long_name']

# Variable data
# Numpy is extremely slow at making tons of random variables, so need to
# use dask so generation is done in parallel and we don't get memory overload
# NOTE: Random routines (including numpy ones) don't accept chunks.
# NOTE: For isentropic interpolation, with overlapping contours, NCL handles
# these fine but metpy method has many issues. Just make zonally uniform fields.
print('Making variables.')
N = 100000
chunks = (1, N, N, N) # chunk in time dimension
# Temperature
base = da.zeros((time.size, 1, 1, lon.size), chunks=chunks) # empty array
offset = ((255 + 0.06*plev)[:,None,None] # max average of 255 + 60 = 315K
        - (60*np.abs(lat)/90)[:,None]) # average of 315 - 60 = 255K at pole
# Other
# Smooth in longitude dimension? No, too complex for dask arrays
# random[...,:lon.size//2] = random[...,:lon.size//2].cumsum(axis=3)
# random[...,lon.size//2:] = random[...,lon.size//2-1::-1]
random1 = da.random.normal(0, 1, (time.size, 1, 1, lon.size), chunks=chunks).astype(dtype) # remember 2/3 fall within +/-1stdev
random1 = random1.cumsum(axis=0) + np.tile(0, (plev.size, lat.size, 1))
random2 = da.random.normal(0, 1, (time.size, 1, 1, lon.size), chunks=chunks).astype(dtype) # remember 2/3 fall within +/-1stdev
random2 = random2.cumsum(axis=0) + np.tile(0, (plev.size, lat.size, 1))
# Write variables
# NOTE: NaN encoding causes issues with NCO, so use better fill value
print('Making dataset.')
params_values = {'t':offset + base, 'u':random1, 'v':random2}
params_map = {name: (coords, params_values[name], params_attrs[name]) for name in params}
coords_map = {name: ((name,), coords_values[name], coords_attrs[name]) for name in coords}
data = xr.Dataset(params_map, coords_map)
for param in data.variables.values():
    param.encoding.update({'_FillValue':None}) # disable default fill value

# Save
# Diabled follwoing instructions here: http://xarray.pydata.org/en/stable/io.html
# formats = {3:'NETCDF3_CLASSIC', 4:'NETCDF4'}
formats = {3:'NETCDF3_CLASSIC'} # differences are minor and 'classic' is everywhere, so just use this
for num,format in formats.items():
    out = f'{dir}/dataN{lat.size:04d}T{ntime}_{num}.nc'
    if os.path.exists(out):
        os.remove(out)
    print(f'Writing to {out}.')
    data[[*coords, *params]].to_netcdf(out, mode='w', format=format, unlimited_dims={'time':True})

