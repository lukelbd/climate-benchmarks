#!/bin/csh
#

set echo
#foreach aera ( global NH SH)
set outdir = "/mdata3/yingli/ERA_Interim/daily_from_4xdaily/flux_all/"
set outfile = "CPMKMwa.19790101-20151231.zonal_mean"

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
  fili = "w.19790101-20151231.zonal_mean.nc"
  f = addfile (diri+fili, "r")
  w = f->w
  printVarSummary(w)
  w = dim_rmvmean_n_Wrap(w,2)

  fili = "alpha.19790101-20151231.zonal_mean.nc"
  f = addfile (diri+fili, "r")
  a = f->alpha
  a = dim_rmvmean_n_Wrap(a,2)
  printVarSummary(a)

  cpmkm = w
  cpmkm = -1.* w * a

  cpmkm@long_name = "conversion from PM to KM"
  cpmkm@units = "m3/s3"

  printVarSummary(cpmkm)

;*****************************************************************
; netCDF
;*****************************************************************
  fout    = "ncfile.nc"    ; output file name
  ncdf    = addfile(fout ,"c")     ; open output netCDF file

;================================================================
; create global attributes of the file (not required)
;================================================================
  fAtt               = True        ; assign file attributes
  fAtt@title         = "conversion from PM to KM: -1.* w * alpha"
  fAtt@source_file   = fili
  ;fAtt@Conventions   = "CF 1.0"   
  fAtt@creation_date = systemfunc ("date")        
  fileattdef( ncdf, fAtt )         ; copy file attributes    
                                ; recommended (generally) 
  filedimdef(ncdf,"time",-1,True)  ; make time UNLIMITED dimension 
  
  ncdf->CPMKMwa = cpmkm

end
exit
  
eof

ncl plot.ncl
mv  ncfile.nc $outdir/$outfile.nc

end 
end
end

