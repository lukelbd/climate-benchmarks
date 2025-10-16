#!/usr/bin/env julia
# Compiles flux scripts into executables
# See: https://github.com/JuliaLang/PackageCompiler.jl
using PackageCompiler
build_executable("ncdatasets.jl", snoopfile="snoop/ncdatasets.jl", builddir="compiled")
build_executable("netcdf.jl", snoopfile="snoop/netcdf.jl", builddir="compiled")
