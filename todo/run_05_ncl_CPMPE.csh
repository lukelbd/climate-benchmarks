#!/bin/csh
#

set echo

#foreach aera (global NH SH)

set outdir = "/mdata3/yingli/ERA_Interim/daily_from_4xdaily/flux_all/"
set outfile = "CPMPE.19790101-20151231.zonal_mean"

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
  diri = "$outdir"
  fili = "gamma.19790101-20151231.zonal_mean.nc"
  f = addfile (diri+fili, "r")
  gama = f->gamma
  printVarSummary(gama)

  fili = "vt.19790101-20151231.zonal_mean.nc"
  f = addfile (diri+fili, "r")
  vt = f->vt

  fili = "dtdy.19790101-20151231.zonal_mean.nc"
  f = addfile (diri+fili, "r")
  dtdy = f->dtdy

  fili = "wt.19790101-20151231.zonal_mean.nc"
  f = addfile (diri+fili, "r")
  wt = f->wt

  fili = "t.19790101-20151231.zonal_mean.nc"
  f = addfile (diri+fili, "r")
  t = f->t
  t = dim_rmvmean_n_Wrap(t,2)

;***********************************************************
; parameter
;***********************************************************
  kappa = 0.286 
  g   = 9.81          ; m/s
  cp  = 1004.         ; J kg-1 K-1
;***********************************************************

  p = int2flt(f->lev)
  pC = conform_dims(dimsizes(t),p,1)
  xC = t
  xC = pC^0.286 * gama * t 

  dxdp = center_finite_diff_n(xC, p*100., False, 0,1)
  dxdp = dxdp * pC^-0.286 

  CPMPE = vt
  CPMPE = -1. * cp * (gama * vt * dtdy + wt * dxdp) 
  CPMPE@long_name = "conversion from PM to PE"
  CPMPE@units = "m3/s3"

  printVarSummary(CPMPE)

;*****************************************************************
; netCDF
;*****************************************************************
  fout    = "ncfile.nc"    ; output file name
  ncdf    = addfile(fout ,"c")     ; open output netCDF file

;================================================================
; create global attributes of the file (not required)
;================================================================
  fAtt               = True        ; assign file attributes
  fAtt@title         = "conversion from PM to PE"
  fAtt@source_file   = fili
  ;fAtt@Conventions   = "CF 1.0"   
  fAtt@creation_date = systemfunc ("date")        
  fileattdef( ncdf, fAtt )         ; copy file attributes    
                                ; recommended (generally) 
  filedimdef(ncdf,"time",-1,True)  ; make time UNLIMITED dimension 
  
  ncdf->CPMPE = CPMPE

end
exit
  
eof

ncl plot.ncl
mv  ncfile.nc $outdir/$outfile.nc

end 
end
end

