#!/usr/bin/env julia
################################################################################
# This script follows the advice of answer here:
# https://stackoverflow.com/a/50627721/4970632
# It turns out speed hugely improves by putting stuff into ***pre-compiled***
# binaries (try running @time on function once, then again, in REPL, and
# speedup is like 2 orders of magnitude).
################################################################################
# Add current path
# Below says to insert this string at the end of LOAD_PATH, modifies in-place
# Second option from: https://stackoverflow.com/questions/37200025/how-to-import-custom-module-in-julia
# include("./ZonalStats.jl")
# NOTE: Using is recommended for interactive use only; using brings everything into scope!
# See: https://discourse.julialang.org/t/import-vs-using-v0-7/11753/3
push!(LOAD_PATH, "./")
using ZonalStats # same thing as using?

# Calculate
# NOTE: Differences between importing specified here:
# https://discourse.julialang.org/t/import-vs-using-v0-7/11753
# NOTE: First call to function inside modules are always really
# slow, so need to consider using interactive session!
ZonalStats.eddy_flux(ARGS[1]::String)
