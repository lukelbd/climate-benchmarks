#!/usr/bin/env julia
################################################################################
# File that calls main function in fluxes.jl so that
# SnoopCompile can do its thing, makes PackageCompiler work
# much better. Otherwise final result sucks.
# See: https://github.com/JuliaLang/PackageCompiler.jl
################################################################################
# Just call function on a sample file
push!(LOAD_PATH, "./")
using fluxes
fluxes.eddy_flux("./fluxes_snoop.nc")
