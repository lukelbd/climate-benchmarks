#!/bin/csh
#

set echo

set indir = /mdata3/yingli/ERA_Interim/daily_from_4xdaily/flux_all/
set outdir1 = /mdata3/yingli/ERA_Interim/daily_from_4xdaily/flux_all/ 

set outfile1 = alpha.19790101-20151231.zonal_mean


cat > code.ncl << eof

;************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;************************************
begin

  diri = "$indir"
  fili = "t.19790101-20151231.zonal_mean.nc"

  f  = addfile (diri+fili, "r")
  t  = f->t
  printVarSummary(t)
  lev = f->lev
  nlev = dimsizes(f->lev)
  a = t
  do k = 0, nlev-1
    a(:,k,:,:) = 287.058 * t(:,k,:,:) /(lev(k)*100.)
  end do	

  a@units     = "kgm-3"

;*****************************************************************
; netCDF
;*****************************************************************
  fout    = "ncfile1.nc"    ; output file name
  ncdf    = addfile(fout ,"c")     ; open output netCDF file

;================================================================
; cireate global attributes of the file (not required)
;================================================================
  fAtt               = True        ; assign file attributes
  fAtt@title         = "wt"
  fAtt@source_file   = fili
  ;fAtt@Conventions   = "CF 1.0"   
  fAtt@creation_date = systemfunc ("date")        
  fileattdef( ncdf, fAtt )         ; copy file attributes    
                                ; recommended (generally) 
  filedimdef(ncdf,"time",-1,True)  ; make time UNLIMITED dimension 
  
  ncdf->alpha = a


;*****************************************************************

end

eof

ncl code.ncl
mv  ncfile1.nc $outdir1/$outfile1.nc


end
end

