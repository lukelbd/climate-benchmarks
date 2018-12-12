#!/usr/bin/env julia
################################################################################
# Julia script for getting fluxes
# Beginner notes:
#   * Type '?' in REPL to get help info
#   * Type ';' to issue shell commands
#   * Use 'apropos("string")' to search for func names
#   * Use ']' for package management tools
#   * Use 'splat' operator <iterable>... inside a function to expand
#     like in *args.
#   * Also use keys() or values() to iterate over the mappable
#   * In julia, function names ending in '!' modify their arguments,
#     sort of like NCL commands vs. functions
# For Julia REPL info see: https://en.wikibooks.org/wiki/Introducing_Julia/The_REPL#Help_and_searching_for_help
# Example random number generation (after 'using Random')
# a = rand(Float32, 5, 3)
# a = zeros(5, 3)
# rand!(a) # populates array
# NOTE: To re-install packages after you change underlying OS libraries
# e.g. NetCDF, just use Pkg.build("name")
################################################################################
# First load modules and file
# NOTE: Julia has issues with year 0 (reads as year -1, then jumps from
# there to year 1), so we use Dates to increment by 1 year. Cool!
using NCDatasets # netcdf
using Statistics # basic stats
filename = ARGS[1]
dir = split(filename, "/")[1]

# Load contents of variables. Iterate: for (varname, variable) in data
# The dataset is a special mapping that returns NCDataset::Variable types,
# which we extract into arrays loaded on memory with colon index
# NOTE: For do block syntax see: https://alexander-barth.github.io/NCDatasets.jl/stable/#Variables-1
# NOTE: Number type in NCDataset::Variables is Union{Missing, Float32}, a
# mixed type (thought it was incompatible with Statitistics operations but was wrong).
#   * See discussion here: https://github.com/JuliaLang/julia/issues/29693
#   * To convert these, use nomissing(da, value) or nomissing(da).
#   * See documentation here: https://alexander-barth.github.io/NCDatasets.jl/stable/#Utility-functions-1
# Dataset(filename, "r") do data # do block vars are local so inappropriate here
# global t, u, v
data = Dataset(filename, "r")
# Dimensions and dimension attributes
dims = dimnames(data["t"]) # list of anmes
latt = Dict(data["lat"].attrib) # must convert to Dict before passing
patt = Dict(data["plev"].attrib)
tatt = Dict(data["time"].attrib)
# Coordinates
# NOTE: Appears coordinates cannot have 'miss' values
# NOTE: Cannot add DateTime directly as NetCDF variable, has to be
# encoded as decimal time units, and could not figure out how to load
# file without encoding into DateTime
lat  = nomissing(data["lat"][:])
plev = nomissing(data["plev"][:])
time = timeencode(data["time"][:], tatt["units"], tatt["calendar"]) # this is seriously the best way to do it; can't avoid decoding in first place it seems
t = data["t"][:] # row major means order switches to lon, lat, plev, time
u = data["u"][:]
v = data["v"][:]
close(data)
# end

# Calculate
# NOTE: Julia is column major which means everything gets permuted
# when loaded by NCDatasets
# NOTE: Array broadcasting is totally different in Julia, requires
# dotted operators or broadcast(+, a1, a2); see https://docs.julialang.org/en/latest/manual/arrays/#Broadcasting-1
# Also for more on vectorization see: https://docs.julialang.org/en/latest/manual/functions/#man-vectorized-1
# NOTE: Julia axis operations by default leave a singleton dimension
# This behavior is contested right now; see: https://github.com/JuliaLang/julia/issues/16606
# Also note the 'dims' keyword argument *must be specified*; don't have fluid
# differentiation between position args and kwargs like in python
emf = mean((u .- mean(u, dims=1)) .* (v .- mean(v, dims=1)), dims=1)
ehf = mean((t .- mean(t, dims=1)) .* (v .- mean(v, dims=1)), dims=1)

# Create new file, and save
# NOTE: The thing after the colon is a symbol; for more info see
# the stackoverflow post: https://stackoverflow.com/a/23482257/4970632
# NOTE: Use * for string concatenation;
# see: https://docs.julialang.org/en/v1/manual/strings/index.html
# NOTE: Use ncgen(filename) to get the code necessary to generate
# that same NetCDF file. Super handy!!!
# WARNING: Thought I found some undefined/unstable/strange behavior when we
# define variables and declare them to have their own dimension in the same
# breath; had mysterious failures below, can't reproduce anymore
Dataset(dir * "/fluxes_jl.nc", "c", format=:netcdf4) do out
  # Define coordinates
  defVar(out, "lon",  Float32.([0]), ("lon",), attrib=["long_name" => "longitude"]) # note we apply Float32 as elementwise function there
  defVar(out, "lat",  lat,  ("lat",),  attrib=latt)
  defVar(out, "plev", plev, ("plev",), attrib=patt)
  defVar(out, "time", time, ("time",), attrib=tatt)
  # Define variables
  defVar(out, "emf", emf, dims, attrib=["long_name" => "eddy momentum flux", "units" => "m**2/s**2"])
  defVar(out, "ehf", emf, dims, attrib=["long_name" => "eddy heat flux", "units" => "K*m/s"])
end

