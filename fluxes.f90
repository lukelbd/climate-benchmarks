module io
use netcdf
use global_variables
subroutine ncwrite
  implicit none
  !    ---- Create netcdf file and initialze variables ----
  ! Create file (also 'opens' it and turns on 'defmode'; no need to call those functions)
  ! The clobber mode says to overwrite any existing dataset (this is the default)
  ret = nf90_create(path='data.nc', cmode=nf90_clobber, ncid=file_id)
  ! Define dimensions
  ret = nf90_def_dim(file_id, 'x', imax, xdim_id)
  ret = nf90_def_dim(file_id, 'y', jmax, ydim_id)
  ret = nf90_def_dim(file_id, 'z', 2, zdim_id)
  ret = nf90_def_dim(file_id, 'time', nf90_unlimited, tdim_id)
  ! Dimension variables
  ret = nf90_def_var(file_id, 'x',  nf90_float, (/xdim_id/), x_id)
  ret = nf90_def_var(file_id, 'y',  nf90_float, (/ydim_id/), y_id)
  ret = nf90_def_var(file_id, 'z',  nf90_int,  (/zdim_id/), z_id)
  ret = nf90_def_var(file_id, 'time',  nf90_float, (/tdim_id/), t_id)
  ! Data variables
  s4d = (/xdim_id, ydim_id, zdim_id, tdim_id/) ! 2 levels
  ret = nf90_def_var(file_id, 'q',   nf90_float, s4d, q_id)
  ret = nf90_def_var(file_id, 'u',   nf90_float, s4d, u_id)
  ret = nf90_def_var(file_id, 'v',   nf90_float, s4d, v_id)
  ret = nf90_def_var(file_id, 'vor', nf90_float, s4d, vor_id)
  ! Global attributes
  ret = nf90_put_att(file_id, nf90_global, 'title', '2-layer QG model results')
  ! Dimension attributes
  ret = nf90_put_att(file_id, x_id, 'units', 'm')
  ret = nf90_put_att(file_id, y_id, 'units', 'm')
  ret = nf90_put_att(file_id, t_id, 'units', 'days')
  ret = nf90_put_att(file_id, z_id, 'units', 'z(1)=top z(2)=bottom')
  ! Variable attributes
  ret = nf90_put_att(file_id, q_id,   'units',     '1/s')
  ret = nf90_put_att(file_id, u_id,   'units',     'm/s')
  ret = nf90_put_att(file_id, v_id,   'units',     'm/s')
  ret = nf90_put_att(file_id, vor_id, 'units',     '1/s')
  ret = nf90_enddef(file_id)
  ! Write dimension variables (must come after define mode or they will be empty)
  ret = nf90_put_var(file_id, x_id, x_cart, start=(/1/), count=(/imax/))
  ret = nf90_put_var(file_id, y_id, y_cart, start=(/1/), count=(/jmax/))
  ret = nf90_put_var(file_id, z_id, (/1,2/), start=(/1/), count=(/2/))

  !    ---- Save data ----
  ! Note if you mess up the dimensionality of input arrays, error message will be mysterious:
  ! "There is no matching specific function for this generic function reference."
  ! Add current day to time variable
  ret = nf90_put_var(file_id, t_id, (/day/), start=(/t_io/), count=(/1/))
  ret = nf90_put_var(file_id, q_id, qfull1_cart, start=(/1,1,1,t_io/), count=(/imax,jmax,1,1/))

  !    ---- Increment save time ----
  t_io = t_io+1
end subroutine
end module

program main
  use netcdf
  !    ---- Initialize fields and other stuff ----
  call init ! (initial.f90)

end program


