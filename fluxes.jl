#!/usr/bin/env julia
################################################################################
# Julia script for getting fluxes
# Recommendation for building module this way copes from: https://stackoverflow.com/a/50627721/4970632
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
# More advanced notes:
#   * To re-install packages after you change underlying OS libraries
#     e.g. NetCDF, just use Pkg.build("name")
#   * For scoping inside for/do loops inside a function, see this
#     answer: https://github.com/JuliaLang/julia/pull/22659#issuecomment-312525833
#     Also see: https://discourse.julialang.org/t/repl-and-for-loops-scope-behavior-change/13514
#   * You can overwrite "global" variables without "global" keyword
#     when declared inside a function, but not in a script or the REPL!!!
#     Also see: https://github.com/JuliaLang/julia/issues/28789
# Running efficiently from shell:
#   * Main source of suggestions came from here:
#     https://stackoverflow.com/a/50996444/4970632
#   * Tried the pipeline approach but then can't wait for julia commands
#     See: https://stackoverflow.com/q/48510815/4970632
#   * Alternative was to build system image file but this also
#     seemed to fail: https://github.com/JuliaLang/julia/issues/28557
# For Julia REPL info see: https://en.wikibooks.org/wiki/Introducing_Julia/The_REPL#Help_and_searching_for_help
# Example random number generation (after 'using Random')
# a = rand(Float32, 5, 3)
# a = zeros(5, 3)
# rand!(a) # populates array
################################################################################
# __precompile__()
module fluxes
  # Dependencies
  export eddy_flux  # makes it *publicly* available
  import NCDatasets # netcdf
  import Statistics # basic stats
  nc = NCDatasets   # syntastic 'import as' sugar not yet available
  stat = Statistics

  # First the dummy function
  # To enable compiling, see: https://github.com/JuliaLang/PackageCompiler.jl
  # Recipe: Simply run build_executable("fluxes.jl", snoopfile="fluxes_snoop.jl")
  # The snoop file is ***critical***, otherwise no performance increases!
  Base.@ccallable function julia_main(ARGS::Vector{String})::Cint # returns just 0 if success
    eddy_flux(ARGS[1])
    return 0
  end

  # The main function
  function eddy_flux(filename::String)
    # A Dataset is a special mapping that returns NCDataset::Variable types,
    # iterates with "for (varname, variable) in data"; load data as in NetCDF4
    # which we extract into arrays loaded on memory with colon index
    # NOTE: For do block syntax see: https://alexander-barth.github.io/NCDatasets.jl/stable/#Variables-1
    # NOTE: Number type in NCDataset::Variables is Union{Missing, Float32}, a
    # mixed type (thought it was incompatible with Statitistics operations but was wrong).
    #   * See discussion here: https://github.com/JuliaLang/julia/issues/29693
    #   * To convert these, use nomissing(da, value) or nomissing(da).
    #   * See documentation here: https://alexander-barth.github.io/NCDatasets.jl/stable/#Utility-functions-1
    dir = split(filename, "/")[1]
    data = nc.Dataset(filename, "r")

    # Dimensions and dimension attributes
    dims = nc.dimnames(data["t"]) # list of anmes
    latt = Dict(data["lat"].attrib) # must convert to Dict before passing
    patt = Dict(data["plev"].attrib)
    tatt = Dict(data["time"].attrib)

    # Coordinates
    # NOTE: Appears coordinates cannot have 'miss' values
    # NOTE: Cannot add DateTime directly as NetCDF variable, has to be
    # encoded as decimal time units, and could not figure out how to load
    # file without encoding into DateTime
    lat  = nc.nomissing(data["lat"][:])
    plev = nc.nomissing(data["plev"][:])
    time = nc.timeencode(data["time"][:], tatt["units"], tatt["calendar"]) # this is seriously the best way to do it; can't avoid decoding in first place it seems
    t = data["t"][:] # row major means order switches to lon, lat, plev, time
    u = data["u"][:]
    v = data["v"][:]
    nc.close(data)

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
    emf = stat.mean((u .- stat.mean(u, dims=1)) .*
                     (v .- stat.mean(v, dims=1)), dims=1)
    ehf = stat.mean((t .- stat.mean(t, dims=1)) .*
                     (v .- stat.mean(v, dims=1)), dims=1)

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
    out = nc.Dataset(dir * "/fluxes_jl.nc", "c", format=:netcdf4)

    # Define coordinates
    nc.defVar(out, "lon",  Float32.([0]), ("lon",), attrib=["long_name" => "longitude"]) # note we apply Float32 as elementwise function there
    nc.defVar(out, "lat",  lat,  ("lat",),  attrib=latt)
    nc.defVar(out, "plev", plev, ("plev",), attrib=patt)
    nc.defVar(out, "time", time, ("time",), attrib=tatt)

    # Define variables
    nc.defVar(out, "emf", emf, dims, attrib=["long_name" => "eddy momentum flux", "units" => "m**2/s**2"])
    nc.defVar(out, "ehf", emf, dims, attrib=["long_name" => "eddy heat flux", "units" => "K*m/s"])
    nc.close(out)
  end
end
