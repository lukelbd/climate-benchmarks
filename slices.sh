#!/usr/bin/env bash
# Take different time slices
nmax=50
debug=false
source ./header.sh
for data in ${datas[@]}; do
  # Header
  init $data

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
