#!/usr/bin/env julia
################################################################################
# Julia script for getting fluxes
# See fluxes_ncdatasets for more notes
################################################################################
module netcdf
  # Dependencies
  export fluxes  # makes it *publicly* available
  import NetCDF # netcdf
  nc = NetCDF   # syntastic 'import as' sugar not yet available

  # First the dummy function
  Base.@ccallable function julia_main(ARGS::Vector{String})::Cint # returns just 0 if success
    fluxes(ARGS[1])
    return 0
  end

  # The main function
  function fluxes(filename::String)
    # Dimensions and dimension attributes
    # dims = nc.dimnames(data["t"]) # list of anmes
    lat_units = nc.ncgetatt(filename, "lat", "units")
    plev_units = nc.ncgetatt(filename, "plev", "units")
    time_units = nc.ncgetatt(filename, "time", "units")
    lat_name = nc.ncgetatt(filename, "lat", "long_name")
    plev_name = nc.ncgetatt(filename, "plev", "long_name")
    time_name = nc.ncgetatt(filename, "time", "long_name")

    # Coordinates
    # NOTE: Appears coordinates cannot have 'miss' values
    # NOTE: Cannot add DateTime directly as NetCDF variable, has to be
    # encoded as decimal time units, and could not figure out how to load
    # file without encoding into DateTime
    u = nc.ncread(filename, "u")
    v = nc.ncread(filename, "v")
    t = nc.ncread(filename, "t")
    lon  = nc.ncread(filename, "lon")
    lat  = nc.ncread(filename, "lat")
    plev = nc.ncread(filename, "plev")
    time = nc.ncread(filename, "time")
    nc.ncclose(filename)
    nlon = length(lon)

    # Calculate
    emf = sum((u .- sum(u, dims=1)/nlon) .*
              (v .- sum(v, dims=1)/nlon), dims=1)/nlon
    ehf = sum((t .- sum(t, dims=1)/nlon) .*
              (v .- sum(v, dims=1)/nlon), dims=1)/nlon
    emf = emf[1,:,:,:] # sum does not reduce dims
    ehf = ehf[1,:,:,:]

    # Create new file, and save
    # dir = split(filename, "/")[1]
    #= outname = dir * "/fluxes_jl.nc" =#
    outname = "out/fluxes_jl.nc"
    if isfile(outname)
      rm(outname)
    end

    # Define coordinates
    # dims = ["lat", "plev", "time"]
    nc.nccreate(outname, "lat", "lat", length(lat)) # define dimension length for first time, otherwise get error when try to write to them
    nc.nccreate(outname, "plev", "plev", length(plev))
    nc.nccreate(outname, "time", "time", length(time))
    nc.nccreate(outname, "emf", "lat", "plev", "time")
    nc.nccreate(outname, "ehf", "lat", "plev", "time")
    # Write data
    nc.ncwrite(lat, outname, "lat")
    nc.ncwrite(plev, outname, "plev")
    nc.ncwrite(time, outname, "time")
    nc.ncwrite(emf, outname, "emf")
    nc.ncwrite(ehf, outname, "ehf")
    # Write attributes
    nc.ncputatt(outname, "lat", Dict("units" => lat_units, "long_name" => lat_name))
    nc.ncputatt(outname, "plev", Dict("units" => plev_units, "long_name" => plev_name))
    nc.ncputatt(outname, "time", Dict("units" => time_units, "long_name" => time_name))
    nc.ncputatt(outname, "emf", Dict("units" => "m**2/s**2", "long_name" => "eddy momentum flux"))
    nc.ncputatt(outname, "ehf", Dict("units" => "K*m/s", "long_name" => "eddy heat flux"))

  end
end
