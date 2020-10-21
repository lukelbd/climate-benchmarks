program main
  use netcdf
  implicit none
  integer :: idx, ret, ncid, uid, vid, tid, emfid, ehfid, &
    dlonid, dlatid, dplevid, dtimeid, &
    latid, lonid, plevid, timeid
  integer, dimension(3) :: idxs
  integer :: nlon, nlat, nplev, ntime
  real, allocatable, dimension(:) :: lon, lat, plev, time
  real, allocatable, dimension(:,:,:) :: ehf, emf
  real, allocatable, dimension(:,:,:) :: ubar, vbar, tbar
  real, allocatable, dimension(:,:,:,:) :: u, v, t
  character(len=80) :: dname, filename, outname
  character(len=80) :: lat_units, lat_name, plev_units, plev_name, time_units, time_name
  ! character(len=100) :: get_command_argument  ! return type of functions

  ! Read data
  ! NOTE: Unidata recommend wrapping in check, so exit happens if non-zero exit code is
  ! returned, but requires 2003 standard
  ! filename = trim(get_command_argument(1))
  ! idx = scan(filename, '/')
  ! outname = filename(:idx) // 'fortran.nc'
  call getarg(1, filename)
  outname = 'out/fortran.nc'
  ret = nf90_open(trim(filename), NF90_NOWRITE, ncid )

  ! Get ids
  ret = nf90_inq_varid(ncid, 'time', timeid )
  ret = nf90_inq_varid(ncid, 'plev', plevid )
  ret = nf90_inq_varid(ncid, 'lat',  latid)
  ret = nf90_inq_varid(ncid, 'lon',  lonid)
  ret = nf90_inq_varid(ncid, 'u',  uid)
  ret = nf90_inq_varid(ncid, 'v',  vid)
  ret = nf90_inq_varid(ncid, 't',  tid)

  ! Read dimension lengths
  ! NOTE: Have to allocate array storage sizes before writing to them, or hard-code
  ! sizes on declaration!
  ret = nf90_inq_dimid(ncid, 'lon',  dlonid)
  ret = nf90_inq_dimid(ncid, 'lat',  dlatid)
  ret = nf90_inq_dimid(ncid, 'plev', dplevid)
  ret = nf90_inq_dimid(ncid, 'time', dtimeid)
  ret = nf90_inquire_dimension(ncid, dlonid,  dname, nlon)
  ret = nf90_inquire_dimension(ncid, dlatid,  dname, nlat)
  ret = nf90_inquire_dimension(ncid, dplevid, dname, nplev)
  ret = nf90_inquire_dimension(ncid, dtimeid, dname, ntime)

  ! Allocate arrays
  allocate( lon(nlon) )
  allocate( lat(nlat) )
  allocate( plev(nplev) )
  allocate( time(ntime) )
  allocate( u(nlon, nlat, nplev, ntime) )
  allocate( v(nlon, nlat, nplev, ntime) )
  allocate( t(nlon, nlat, nplev, ntime) )

  ! Read data
  ret = nf90_get_var(ncid, lonid,  lon)
  ret = nf90_get_var(ncid, latid,  lat)
  ret = nf90_get_var(ncid, plevid, plev)
  ret = nf90_get_var(ncid, timeid, time)
  ret = nf90_get_var(ncid, uid, u)
  ret = nf90_get_var(ncid, vid, v)
  ret = nf90_get_var(ncid, tid, t)

  ! Read attributes
  ret = nf90_get_att(ncid, latid, 'units', lat_units)
  ret = nf90_get_att(ncid, latid, 'latg_name', lat_name)
  ret = nf90_get_att(ncid, plevid, 'units', plev_units)
  ret = nf90_get_att(ncid, plevid, 'long_name', plev_name)
  ret = nf90_get_att(ncid, timeid, 'units', time_units)
  ret = nf90_get_att(ncid, timeid, 'long_name', time_name)

  ! Close
  ret = nf90_close(ncid)

  ! Calculate data
  ! NOTE: spread function, unlike repmat, *inserts* a new singleton dimension then
  ! repeats data along that new dimension, much more useful
  ubar = sum(u, 1)/nlon
  vbar = sum(v, 1)/nlon
  tbar = sum(t, 1)/nlon
  emf = sum((u - spread(ubar, 1, nlon)) * (v - spread(vbar, 1, nlon)), 1)/nlon
  ehf = sum((t - spread(tbar, 1, nlon)) * (v - spread(vbar, 1, nlon)), 1)/nlon
  ! ubar = reshape(idxs, sum(u, 1)/nlon)
  ! vbar = reshape(idxs, sum(v, 1)/nlon)
  ! tbar = reshape(idxs, sum(t, 1)/nlon)

  ! Create the output file
  call system('rm ' // outname)
  ret = nf90_create(trim(outname), NF90_CLOBBER, ncid)

  ! Define dimensions
  ret = nf90_def_dim(ncid, 'lat', nlat, dlatid)
  ret = nf90_def_dim(ncid, 'plev', nplev, dplevid)
  ret = nf90_def_dim(ncid, 'time', NF90_UNLIMITED, dtimeid)

  ! Define variables
  idxs = (/dlatid, dplevid, dtimeid/)
  ret = nf90_def_var(ncid, 'lat', NF90_REAL, dlatid, latid)
  ret = nf90_def_var(ncid, 'plev', NF90_REAL, dplevid, plevid)
  ret = nf90_def_var(ncid, 'time', NF90_REAL, dtimeid, timeid)
  ret = nf90_def_var(ncid, 'emf', NF90_REAL, idxs, emfid)
  ret = nf90_def_var(ncid, 'ehf', NF90_REAL, idxs, ehfid)

  ! Add attributes
  ! WARNING: Must come before enddef command
  ret = nf90_put_att(ncid, latid, 'units', lat_units)
  ret = nf90_put_att(ncid, latid, 'long_name', lat_name)
  ret = nf90_put_att(ncid, plevid, 'units', plev_units)
  ret = nf90_put_att(ncid, plevid, 'long_name', plev_name)
  ret = nf90_put_att(ncid, timeid, 'units', time_units)
  ret = nf90_put_att(ncid, timeid, 'long_name', time_name)
  ret = nf90_put_att(ncid, emfid, 'units', 'm**2/s**2')
  ret = nf90_put_att(ncid, emfid, 'long_name', 'eddy momentum flux')
  ret = nf90_put_att(ncid, ehfid, 'units', 'K*m/s')
  ret = nf90_put_att(ncid, ehfid, 'long_name', 'eddy heat flux')
  ret = nf90_enddef(ncid)

  ! Write the coordinate variable data.
  ret = nf90_put_var(ncid, latid,  lat)
  ret = nf90_put_var(ncid, plevid, plev)
  ret = nf90_put_var(ncid, timeid, time)
  ret = nf90_put_var(ncid, emfid,  emf)
  ret = nf90_put_var(ncid, ehfid,  ehf)

  ! Close
  ret = nf90_close(ncid)

end program


