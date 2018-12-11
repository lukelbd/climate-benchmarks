#!/bin/csh
#

set echo
set outdir = "/mdata3/yingli/ERA_Interim/daily_from_4xdaily/flux_all/"
set outfile = "CKEKM.19790101-20151231.zonal_mean"

cat > plot.ncl << eof

;************************************
load "$NCARG_ROOT/lib/ncarg/nclex/gsun/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;************************************
begin

;*****************************************************************
; read file
;*****************************************************************

  diri = "/mdata3/yingli/ERA_Interim/daily_from_4xdaily/flux_all/"
  fili = "uv.19790101-20151231.zonal_mean.nc"
  f = addfile (diri+fili, "r")
  uv = f->uv

  fili = "dudy.cos.19790101-20151231.zonal_mean.nc"
  f = addfile (diri+fili, "r")
  dudy = f->dudy

  fili = "vv.19790101-20151231.zonal_mean.nc"
  f = addfile (diri+fili, "r")
  vv = f->vv

  fili = "dvdy.19790101-20151231.zonal_mean.nc"
  f = addfile (diri+fili, "r")
  dvdy = f->dvdy

  fili = "uw.19790101-20151231.zonal_mean.nc"
  f = addfile (diri+fili, "r")
  uw = f->uw

  fili = "dudp.19790101-20151231.zonal_mean.nc"
  f = addfile (diri+fili, "r")
  dudp = f->dudp

  fili = "vw.19790101-20151231.zonal_mean.nc"
  f = addfile (diri+fili, "r")
  vw = f->vw

  fili = "dvdp.19790101-20151231.zonal_mean.nc"
  f = addfile (diri+fili, "r")
  dvdp = f->dvdp

  fili = "v.19790101-20151231.zonal_mean.nc"
  f = addfile (diri+fili, "r")
  v = f->v

  fili = "uu.19790101-20151231.zonal_mean.nc"
  f = addfile (diri+fili, "r")
  uu = f->uu


  pi = 3.1415926535898
  radius = 6.371e+06
  clat = f->lat                  ; copy meta data , data&lat not copy meta data
  clat(0) = clat(1)
  clat(120) = clat(119)
  rad    = 4.*atan(1.)/180.
 ; f1 = 2*omega*sin(rad*clat)  ; coriolis parameter
;   print(tan(rad*clat))

  clat1 = conform(uv,clat,2)
  CKEKM = uv
  CKEKM = uv*dudy + vv*dvdy + uw*dudp + vw*dvdp - v*uu*tan(rad*clat1)/radius

  CKEKM@long_name = "conversion from KE to KM"
  CKEKM@units = "m3/s3"

  printVarSummary(CKEKM)

;*****************************************************************
; netCDF
;*****************************************************************
  fout    = "ncfile.nc"    ; output file name
  ncdf    = addfile(fout ,"c")     ; open output netCDF file

;================================================================
; create global attributes of the file (not required)
;================================================================
  fAtt               = True        ; assign file attributes
  fAtt@title         = "conversion from KE to KM"
  fAtt@source_file   = fili
  ;fAtt@Conventions   = "CF 1.0"   
  fAtt@creation_date = systemfunc ("date")        
  fileattdef( ncdf, fAtt )         ; copy file attributes    
                                ; recommended (generally) 
  filedimdef(ncdf,"time",-1,True)  ; make time UNLIMITED dimension 
  
  ncdf->CKEKM = CKEKM

end
exit
  
eof

ncl plot.ncl
mv  ncfile.nc $outdir/$outfile.nc

end 
end
end

