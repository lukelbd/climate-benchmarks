#!/bin/csh
#

set echo
#foreach area (global NH SH)
set area = global 
#set outdir = /gs/project/ktg-565-aa/yingli/var_all/
set outdir = /mdata3/yingli/ERA_Interim/daily_from_4xdaily/flux_all/
#set outfile = gamma.19790101-20141231.${area}_mean
set outfile = gamma.19790101-20151231.zonal_mean

cat > code.ncl << eof

;************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;************************************
begin

  diri = "/mdata3/yingli/ERA_Interim/daily_from_4xdaily/flux_all/"
  fili = "theta.19790101-20151231.zonal_mean.nc" 
  f  = addfile (diri+fili, "r")
  theta = f->theta
  nlat = dimsizes(f->lat)
; =================================================================
  rad    = 4.*atan(1.)/180.
  clat = f->lat                  ; copy meta data , data&lat not copy meta data
  clat   = cos(rad*clat)                 
;  printVarSummary(clat)
; =================================================================

  latS = -90
  latN = 90
  x = dim_avg_wgt_n_Wrap(theta(:,:,{latS:latN},0),clat({latS:latN}),1,2)
  p = int2flt(f->lev)
  dxdp = center_finite_diff_n(x, log(p*100.), False, 0,1)
  printVarSummary(dxdp)
  dxdp = 1./dxdp
  printVarSummary(dxdp)

  fili = "t.19790101-20151231.zonal_mean.nc"
  f  = addfile (diri+fili, "r")
  t = f->t

  gama = t
  do j = 0, nlat-1
    gama(:,:,j,0) = -1.0 * theta(:,:,j,0) / t(:,:,j,0) *0.286 * dxdp(:,:) 
  end do
   
;*****************************************************************
; netCDF
;*****************************************************************
  fout    = "ncfile.nc"    ; output file name
  ncdf    = addfile(fout ,"c")     ; open output netCDF file

;================================================================
; create global attributes of the file (not required)
;================================================================
  fAtt               = True        ; assign file attributes
  fAtt@title         = "gamma"
  fAtt@source_file   = fili
  ;fAtt@Conventions   = "CF 1.0"   
  fAtt@creation_date = systemfunc ("date")        
  fileattdef( ncdf, fAtt )         ; copy file attributes    
                                ; recommended (generally) 
  filedimdef(ncdf,"time",-1,True)  ; make time UNLIMITED dimension 
  
  ncdf->gamma = gama
   
end

eof

ncl code.ncl
mv  ncfile.nc $outfile.nc
mv $outfile.nc $outdir



end
end
