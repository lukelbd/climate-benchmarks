#!/usr/bin/env julia
# Compiles flux scripts into executables
# See: https://github.com/JuliaLang/PackageCompiler.jl
using PackageCompiler
build_executable("../../fluxes_ncdatasets.jl", snoopfile="fluxes_ncdatasets.jl", builddir="..")
build_executable("../../fluxes_netcdf.jl", snoopfile="fluxes_netcdf.jl", builddir="..")
