#!/usr/bin/env julia
# Compiles flux scripts into executables
# See: https://github.com/JuliaLang/PackageCompiler.jl
using PackageCompiler
build_executable("fluxes_ncdatasets", snoopfile="fluxes_ncdatasets.jl")
build_executable("fluxes_netcdf", snoopfile="fluxes_netcdf.jl")
