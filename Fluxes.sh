#!/usr/bin/env bash
################################################################################
# For *this task*, we get the the eddy heat flux and eddy momentum flux
# Use this to call successively call the different task1.x files, then time
# them, so we can compare their output. Consider automatically appending
# results to a markdown table or something
################################################################################
# Loop over datasets with different resolutions
debug=true
source ./header.sh
for data in ${datas[@]}; do
  # Header
  printhead $data

  # # Fortran method
  # # NOTE: Assumes fortran installed with MacPorts, port install netcdf and port install netcdf-fortran
  # gfortran -I/opt/local/include -L/opt/local/lib -lnetcdff -lnetcdf fortran.f90 -o fortran
  # bench "Fortran" fortran $data
  # rm fortran 2>/dev/null

  # Julia
  bench "Julia NCDatasets (compiled)" compiled/ncdatasets $data
  bench "Julia NetCDF (compiled)" compiled/netcdf $data
  # bench "Julia (naive)" julia -e 'push!(LOAD_PATH, "./"); using netcdf; netcdf.fluxes("'${name}'")' # will be ridiculously slow, don't bother

  # MATLAB
  # NOTE: nojvm very important, eliminates initial startup time
  # license="$(which matlab)"
  # license="${license%bin*}/licenses/license.dat"
  bench "MATLAB (no startup)" matlab -nojvm -nodisplay -r \
    "filename='${data}'; tic; matlab; toc; disp(' '); exit"

  # Python with NetCDF4
  bench "Python netCDF4" python nc4.py $data 0

  # Python with xarray method
  # WARNING: File name must differ from module name
  bench "XArray without dask" python xr.py $data 0

  # Python with xarray and Dask chunking by 2D slice
  if [ ${dir##*/} == 1lev ]; then
    bench "XArray 100 step chunks" python xr.py $data 100
    bench "XArray 10 step chunks" python xr.py $data 20
  elif [ ${dir##*/} == 60lev ]; then
    bench "XArray 20 step chunks" python xr.py $data 20
    bench "XArray 2 step chunks" python xr.py $data 2
  else
    echo "Error: Unknown chunk combos for sample data in dir \"$dir\"."
    exit 1
  fi

  # CDO method
  # NOTE: On mac just run with serial IO
  # NOTE: Serial IO turned out to be really small difference
  bench "CDO" ./cdo.sh $data

  # NCL method
  # NOTE: NCL needs special dyld library path but so does brew, screws up
  # Homebrew if we set it, so set it locally
  export DYLD_LIBRARY_PATH="/opt/local/lib/libgcc"
  bench "NCL" ncl -Q -n "filename=\"$data\"" "large=\"0\"" ncl.ncl
  export DYLD_LIBRARY_PATH=""

  # NCO method with NCAP
  # Add options for handling large files; see: http://nco.sourceforge.net/nco.html#Temporary-Output-Files
  # NOTE: Turned out no tmp file made pretty much zero difference
  # NOTE: We can 'open' or 'create' in RAM to prevent issues with overwrites
  # (2nd example). In this case we aren't writing to the same file so we don't
  # need to worry about those options. And makes no time diference.
  bench "NCO" ./nco.sh $data
  # bench "NCO + no tmp file" ./nco.sh $data --no_tmp_fl
  # bench "NCO + open in RAM" ./nco.sh $data --open_ram --no_tmp_fl
  # bench "NCO + create in RAM" ./nco.sh $data --create_ram --no_tmp_fl

done
