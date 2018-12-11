#!/bin/csh
#

set echo
#foreach aera ( global NH SH)
set outdir = "/mdata3/yingli/ERA_Interim/daily_from_4xdaily/flux_all/"
set outfile = "PM.19790101-20151231.zonal_mean"

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
  fili = "t.19790101-20151231.zonal_mean.nc"
  f = addfile (diri+fili, "r")
  x = f->t
  printVarSummary(x)
  
  x = dim_rmvmean_n_Wrap(x,2)

  fili = "gamma.19790101-20151231.zonal_mean.nc"
  f = addfile (diri+fili, "r")
  gama = f->gamma
  printVarSummary(gama)

;  plev = int2flt(x&lev)
;  plev = plev * 100.
;  printVarSummary(plev)
;  plev@units = "Pa"
  
;  ptop = min(plev)

;  psfc = 1018*100.
;  psfc@units = "Pa"

;  dp   = dpres_plevel(plev, psfc, ptop, 0)  
;  printVarSummary(dp)
;  print(dp)

;  dpC = conform_dims(dimsizes(x),dp,1)
;  gammaC = conform_dims(dimsizes(x),gama,(/0,1/))
;  xdp = x
;  xdp = x*x*gammaC*dpC

  g   = 9.81          ; m/s
  cp  = 1004.         ; J kg-1 K-1
;  pm = dim_sum_n_Wrap(xdp,1)
;  pm = 0.5*cp/g * pm
  pm = x
  pm = 0.5*cp*gama*x*x

  pm@long_name = "mean potential energy: 1/2*Cp*gamma*T*T"
  pm@units = "J/m2/hPa"

  printVarSummary(pm)

;*****************************************************************
; netCDF
;*****************************************************************
  fout    = "ncfile.nc"    ; output file name
  ncdf    = addfile(fout ,"c")     ; open output netCDF file

;================================================================
; create global attributes of the file (not required)
;================================================================
  fAtt               = True        ; assign file attributes
  fAtt@title         = "mean potential energy: 1/2*Cp*sum[(gamma*T*T)*dp/gravity]"
  fAtt@source_file   = fili
  ;fAtt@Conventions   = "CF 1.0"   
  fAtt@creation_date = systemfunc ("date")        
  fileattdef( ncdf, fAtt )         ; copy file attributes    
                                ; recommended (generally) 
  filedimdef(ncdf,"time",-1,True)  ; make time UNLIMITED dimension 
  
  ncdf->PM = pm

end
exit
  
eof

ncl plot.ncl
mv  ncfile.nc $outdir/$outfile.nc

end 
end
end

