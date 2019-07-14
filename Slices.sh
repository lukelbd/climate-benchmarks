#!/usr/bin/env bash
################################################################################
# For *this task*, we get the the eddy heat flux and eddy momentum flux
# Use this to call successively call the different task1.x files, then time
# them, so we can compare their output. Consider automatically appending
# results to a markdown table or something
################################################################################
# Loop over datasets with different resolutions
# nmax=100
nmax=50
debug=false
source ./header.sh
cd slice
for data in ${datas[@]}; do
  # Header
  header $data

  # Python
  bench "XArray" python xarray.py $data $nmax

  # NCL
  export DYLD_LIBRARY_PATH="/opt/local/lib/libgcc"
  bench "NCL" ncl -Q -n "filename=\"${data}\"" "nmax=$nmax" ncl.ncl
  export DYLD_LIBRARY_PATH=""

  # NCO
  bench "NCO" ./nco.sh $data $nmax

  # CDO
  bench "CDO" ./cdo.sh $data $nmax
done
