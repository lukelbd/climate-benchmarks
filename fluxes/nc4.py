#!/usr/bin/env python3
################################################################################
# Get fluxes with python
################################################################################
# First load file
import os
import sys
import netCDF4 as nc4
filename = sys.argv[1]
get_dict = lambda obj: {key:value for key,value in obj.__dict__.items() if key[:1]!='_'}
with nc4.Dataset(filename, 'r') as f:
    # Dimensions
    # TODO: Add attributes? Will not affect benchmark much though.
    time_var = f['time']
    plev_var = f['plev']
    lon_var  = f['lon']
    lat_var  = f['lat']
    time = time_var[:]
    plev = plev_var[:]
    lon = lon_var[:]
    lat = lat_var[:]
    # Data
    u_var = f['u']
    v_var = f['v']
    t_var = f['t']
    u = u_var[:]
    v = v_var[:]
    t = t_var[:]
    # Attributes
    time_att = get_dict(time_var)
    plev_att = get_dict(plev_var)
    lat_att = get_dict(lat_var)

# Next perform calculations
emf = ((u - u.mean(axis=-1, keepdims=True)) * (v - v.mean(axis=-1, keepdims=True))).mean(axis=-1)
ehf = ((t - t.mean(axis=-1, keepdims=True)) * (v - v.mean(axis=-1, keepdims=True))).mean(axis=-1)

# Save file
outname = 'out/netcdf4.nc'
if os.path.exists(outname):
    os.remove(outname)
with nc4.Dataset(outname, 'w') as f:
    # Make dimensions
    # NOTE: This is very similar syntax to low-level C and Fortran libs
    f.createDimension("time", None)
    f.createDimension("plev", plev.size)
    f.createDimension("lat",  lat.size)
    # Make new variables
    time_var = f.createVariable("time", "f8", ("time",))
    plev_var = f.createVariable("plev", "f8", ("plev",))
    lat_var  = f.createVariable("lat", "f8", ("lat",))
    ehf_var  = f.createVariable("ehf", "f8", ("time", "plev", "lat",))
    emf_var  = f.createVariable("emf", "f8", ("time", "plev", "lat",))
    # Add attributes
    # WARNING: Updating __dict__ silently fails for some reason!
    for var,dict_ in ((time_var,time_att), (plev_var,plev_att), (lat_var,lat_att)) :
        for key,value in dict_.items():
            setattr(var, key, value)
    for var,dict_ in ((emf_var, {'long_name':'eddy momentum flux', 'units':'m**2/s**2'}),
                      (ehf_var, {'long_name':'eddy heat flux', 'units':'K*m/s'})):
        for key,value in dict_.items():
            setattr(var, key, value)
    # Write to vars
    time_var[:] = time
    plev_var[:] = plev
    lat_var[:]  = lat
    ehf_var[:]  = ehf
    emf_var[:]  = emf
