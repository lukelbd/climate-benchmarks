#!/usr/bin/env bash
################################################################################
# Get eddy fluxes, but with the expr variable
# This is a lot more like NCAP2! Should get better results! Perhaps this is
# how you should use CDO in the future.
################################################################################
filename=$1
flags=${@:2}
[ -z "$filename" ] && echo "Error: Must provide filename." && exit 1
out=out/fluxes_cdo.nc

# Calculate
# NOTE: When doing math and magnitudes of values change a lot, sometimes
# will need to increase precision because missing values are messed up
# or something; see: https://code.mpimet.mpg.de/projects/cdo/wiki/Cdo
flags="$flags -s -b F64 -O" # quiet, and overwrite
cdo $flags -expr,'
  ehf = zonmean((t - zonmean(t))*(v - zonmean(v)));
  emf = zonmean((u - zonmean(u))*(v - zonmean(v)));
  ' $filename $out

