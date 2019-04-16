#!/usr/bin/env julia
# Snoop file for compilation
# Just calls the main function on a sample file
push!(LOAD_PATH, "../../")
using fluxes_netcdf
fluxes_netcdf.fluxes("./snoop.nc")
