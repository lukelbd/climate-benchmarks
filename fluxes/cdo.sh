#!/usr/bin/env bash
# Get eddy fluxes using the -expr command
# NOTE: When magnitudes of values change a lot, sometimes need to increase precision or
# the missing values are messed up. See: https://code.mpimet.mpg.de/projects/cdo/wiki/Cdo
[ -z "$1" ] && echo "Error: Must provide filename." && exit 1
flags=(-s -b F64 -O "${@:2}")

cdo "${flags[@]}" -expr,'
  ehf = zonmean((t - zonmean(t))*(v - zonmean(v)));
  emf = zonmean((u - zonmean(u))*(v - zonmean(v)));
  ' "$1" out/cdo.nc
