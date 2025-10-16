#!/usr/bin/env julia
# Snoop file for compilation
# Just calls the main function on a sample file
push!(LOAD_PATH, "./")
using netcdf
netcdf.fluxes("snoop/snoop.nc")
