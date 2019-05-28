#!/usr/bin/env bash
################################################################################
# Get eddy fluxes
################################################################################
filename=$1
flags=${@:2}
[ -z "$filename" ] && echo "Error: Must provide filename." && exit 1
out=out/cdo.nc

# Calculate
flags="$flags -O -s" # quiet, and overwrite
cdo $flags -chname,u,EMF \
  -zonmean \
  -mul -sub -selvar,u $filename -enlarge,$filename -zonmean -selvar,u $filename \
       -sub -selvar,v $filename -enlarge,$filename -zonmean -selvar,v $filename \
  tmp1.nc
cdo $flags -chname,t,EHF \
  -zonmean \
  -mul -sub -selvar,t $filename -enlarge,$filename -zonmean -selvar,t $filename \
       -sub -selvar,v $filename -enlarge,$filename -zonmean -selvar,v $filename \
  tmp2.nc

# Cleanup
cdo $flags merge tmp1.nc tmp2.nc $out
rm tmp1.nc tmp2.nc
