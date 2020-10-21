#!/bin/bash
################################################################################
# Interpolate model level output to pressure levels. Turns out this is *much slower*
# than NCL interpolation. Compare performance of this script with NCL.
############################################################################
ncfile=$1
outfile=$2
flags="-s -O"
t=$(date +%s)
torig=$t

# Output coordinates into a separate file. NCL can't completely overwrite variable
# dimensions/name/etc. (would require delete which it can't do). Also can't use CDO
# delname because CDO cannot find variables that don't fit into its Cartesian model.
coordsfile=interp0.nc
ncks -O -v hyai,hybi $ncfile $coordsfile
ncks -O -x -v hyai,hybi $ncfile $ncfile

# Get the pressure suitable for interpolation with a quick python script. Should be fast
# since coordsfile is so teeny tiny
python > plevels.txt << EOF
import numpy as np
import netCDF4 as nc4
with nc4.Dataset("$coordsfile") as f:
  hyai = f['hyai'][:]
  hybi = f['hybi'][:]
psurf = 101325 # average surface pressure
phalf = hyai + hybi*psurf
pfull = (phalf[1:] + phalf[:-1])/2
print(",".join("%.f" % i for i in pfull.flat)) # just print output we want
# plevels = np.savetxt("plevels.txt", pfull, fmt="%.f", delimiter='', newline=',')
EOF
if [ ! -r plevels.txt ]; then
  echo "ERROR: Failed reading hybrid coordinates."
  exit 4
fi

# Get a nice grid of coefficients for this coordinate system. Was tricky to save the
# data as columns; anyway this generated a grid description Output "vct" stands for
# "vertical coordinate table". See: https://stackoverflow.com/q/15192847/4970632
python > vct.txt << EOF
import numpy as np
import netCDF4 as nc4
with nc4.Dataset("$coordsfile") as f:
  hyai = f['hyai'][:]
  hybi = f['hybi'][:]
# Print, or save into file
for i,(a,b) in enumerate(zip(hyai,hybi)):
  print("%02.f"%i, "%.10f"%a, "%.10f"%b)
# np.savetxt('vct.txt', np.column_stack((range(len(hyai)),hyai,hybi)), newline='\n', fmt='%.10f') # this was ugly
EOF

# Generate a z-axis description. This can be fed into "setzaxis", which changes
# dimensions and does a whole bunch of stuff that makes ml2pl function work properly.
python > zaxis.txt << EOF
import numpy as np
import netCDF4 as nc4
with nc4.Dataset("$coordsfile") as f:
  hyai = f['hyai'][:]
  hybi = f['hybi'][:]
# Print data and collect
print("zaxistype = hybrid")
print("size      = " + str(len(hyai)-1))
print("levels    = " + " ".join("%.f"%i for i in range(1,len(hyai)))) # e.g. 1 to 41-1=40
print("vctsize   = " + str(len(hyai)*2)) # number of stuff in table
print("vct       = " + " ".join("%.f"%i for i in hyai))
print("            " + " ".join("%.10f"%i for i in hybi))
# format is super weird but vct is just A vals in one row, B vals in other
EOF
echo "  * Time for pre-processing with NCO and python: $(($(date +%s) - t))s."

# Interpolate to approx half-pressure levels with CDO. Get the half-levels using a
# simple python script and the module netCDF4.
# * CDO will treat hyai and hybi as invisible. Can only handle
#   simple netcdf files with simple grids. Need to use ncks for this
# * You also cannot use "ncks -v hyai,hybi coords.nc. CDO enlarge,<infile> coords.nc"
#   because CDO will not read coords.nc at all.
# * Use "cat plevels.txt | sed 's/,/ /g' | wc -w" to get level count
# First change standard_name attribute so CDO will detect surface
# pressure. This is CF convention name.
# * First command is slow because need to make copy with setzaxis. obviously not
#   ideal workflow but still probably faster than any NCL approach.
# * Second command is fast because it's a 1-level variable.
echo "Interpolating coordinates..."
cdo -setzaxis,zaxis.txt $ncfile interp1.nc
ncap2 -O -s 'zs=slp; zs(:,:,:)=0' interp1.nc interp1.nc
ncatted -O -a standard_name,slp,o,c,"surface_air_pressure" \
   -a standard_name,t,o,c,"air_temperature" \
   -a standard_name,zs,o,c,"surface_geopotential" \
   -a long_name,zs,o,c,"surface geopotential" \
   -a units,zs,o,c,"m" interp1.nc
echo "  * Time for setting things up before interpolation: $(($(date +%s) - t))s."
t=$(date +%s)
EXTRAPOLATE=1 cdo $flags ml2pl,"$(cat plevels.txt)" interp1.nc interp2.nc
cdo $flags -delname,zs -genlevelbounds,ztop=101325,zbot=0 interp2.nc $outfile

# Message
echo "  * Time for interpolating to pressure coordinates with CDO: $(($(date +%s) - t))s."
echo "TOTAL TIME ELAPSED: $(($(date +%s) - torig))s."
