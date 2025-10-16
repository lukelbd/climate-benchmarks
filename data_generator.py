#!/usr/bin/env python3
"""
Generate random geophysical datasets containing the variables 't' (temperature), 'u'
(zonal wind), and 'v' (meridional wind) with longitude, latitude, time, and optional
pressure level dimensions.
"""
import argparse
import os

import dask.array as da
import numpy as np

import xarray as xr

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument(
    'reso',
    type=int,
    help=(
        'The horizontal resolution, i.e. the latitude and longitude spacing of the '
        'resulting dataset grid.',
    ),
)
parser.add_argument(
    '-d', '--dir', type=str, default='<NLEV>lev', help='The output directory.'
)
parser.add_argument(
    '-l', '--nlev', type=int, default=60, help='The number of vertical levels.'
)
parser.add_argument(
    '-t', '--ntime', type=int, default=200, help='The number of time steps.'
)
args = parser.parse_args()

# Pull out arguments
reso = args.reso
nlev = args.nlev
ntime = args.ntime
directory = args.dir
if directory == '<NLEV>lev':
    directory = f'{nlev}lev'
if not os.path.isdir(directory):
    os.mkdir(directory)
print(f'Directory: {directory!r} Resolution: {reso}')

# Dimensions
dtype = np.float32
tstep = 2
if max(nlev, 1) == 1:
    plev = np.array([500.0], dtype=dtype)
else:
    plev = np.linspace(0, 1013.25, nlev + 1, dtype=dtype)
    plev = (plev[1:] + plev[:-1]) / 2
time = np.arange(1, ntime, dtype=dtype) / tstep  # in days
lat = np.arange(-90 + reso / 2, 90, reso, dtype=dtype)
lon = np.arange(-180 + reso / 2, 180, reso, dtype=dtype)

# Variables
shape = (time.size, plev.size, lat.size, lon.size)
params = ('u', 'v', 't')
params_attrs = {
    'u': {'long_name': 'zonal wind', 'units': 'm/s'},
    'v': {'long_name': 'meridional wind', 'units': 'm/s'},
    't': {'long_name': 'temperature', 'units': 'K'},
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
    'time': {
        'long_name': 'time',
        'calendar': '360_day',
        'units': 'days since 00-01-01 00:00:00',
        'axis': 'T',
    },
    'plev': {'long_name': 'pressure level', 'units': 'hPa', 'axis': 'Z'},
    'lat': {'long_name': 'latitude', 'units': 'degN', 'axis': 'Y'},
    'lon': {'long_name': 'longitude', 'units': 'degE', 'axis': 'X'},
}
for attrs in coords_attrs.values():
    attrs['standard_name'] = attrs['long_name']

# Variable data. Numpy is extremely slow at making tons of random variables, so need to
# use dask so generation is done in parallel and we don't get memory overload.
# NOTE: Random routines (including numpy ones) don't accept chunks.
# NOTE: For isentropic interpolation, with overlapping contours, NCL handles
# these fine but metpy method has many issues. Just make zonally uniform fields.
print('Making variables.')
N = 100000
chunks = (1, N, N, N)  # chunk in time dimension

# Temperature
base = da.zeros((time.size, 1, 1, lon.size), chunks=chunks)
offset = (
    (255 + 0.06 * plev)[:, None, None]  # max average of 255 + 60 = 315K
    - (60 * np.abs(lat) / 90)[:, None]
)  # average of 315 - 60 = 255K at pole

# Misc data. Smooth in longitude dimension? No, too complex for dask arrays.
random1 = da.random.normal(0, 1, (time.size, 1, 1, lon.size), chunks=chunks)
random1 = random1.cumsum(axis=0) + np.tile(0, (plev.size, lat.size, 1))
random2 = da.random.normal(0, 1, (time.size, 1, 1, lon.size), chunks=chunks)
random2 = random2.cumsum(axis=0) + np.tile(0, (plev.size, lat.size, 1))
random1 = random1.astype(dtype)  # remember 2/3 fall within +/-1stdev
random2 = random2.astype(dtype)  # remember 2/3 fall within +/-1stdev

# Write variables
# NOTE: NaN encoding causes issues with NCO, so use better fill value
print('Making dataset.')
params_values = {'t': offset + base, 'u': random1, 'v': random2}
params_map = {
    name: (coords, params_values[name], params_attrs[name]) for name in params
}
coords_map = {
    name: ((name,), coords_values[name], coords_attrs[name]) for name in coords
}
data = xr.Dataset(params_map, coords_map)
for param in data.variables.values():
    param.encoding.update({'_FillValue': None})  # disable default fill value

# Save
# formats = {3:'NETCDF3_CLASSIC', 4:'NETCDF4'}
formats = {3: 'NETCDF3_CLASSIC'}  # differences are minor and 'classic' is everywhere
for num, format in formats.items():
    out = f'{directory}/dataN{lat.size:04d}T{ntime}_{num}.nc'
    if os.path.exists(out):
        os.remove(out)
    print(f'Writing to {out}.')
    data[[*coords, *params]].to_netcdf(
        out, mode='w', format=format, unlimited_dims={'time': True}
    )
