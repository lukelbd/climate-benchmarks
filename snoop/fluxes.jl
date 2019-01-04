#!/usr/bin/env julia
################################################################################
# File that calls main function in fluxes.jl so that
# SnoopCompile can do its thing, makes PackageCompiler work
# much better. Otherwise final result sucks.
# See: https://github.com/JuliaLang/PackageCompiler.jl
# Recipe: Simply run
#   using PackageCompiler
#   build_executable("fluxes.jl", snoopfile="fluxes_snoop.jl")
# The snoop file is ***critical***, otherwise no performance increases!
################################################################################
# Just call the main function on a sample file
push!(LOAD_PATH, "./")
using fluxes
fluxes.eddy_flux("snoop.nc")
