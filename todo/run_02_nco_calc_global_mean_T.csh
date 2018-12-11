#!/bin/csh
#

set echo
#foreach var (t  w alpha)
set var = alpha
set indir = /gs/project/ktg-565-aa/yingli/var_all/
cd $indir
#ncap -h -O -s "weights=cos(lat*3.1415/180)" t.$lev.19790101-20141231.nc t.$lev.19790101-20141231.nc
#ncwa -h -O -w weights -a lat,lon t.$lev.19790101-20141231.nc  t.$lev.19790101-20141231.${area}_mean.nc
#ncwa -h -O -w weights -a lat,lon -d latitude,-90.,0. t.$lev.19790101-20141231.nc  t.$lev.19790101-20141231.SH_mean.nc
#ncwa -h -O -w weights -a lat,lon -d latitude,0.,90. t.$lev.19790101-20141231.nc  t.$lev.19790101-20141231.NH_mean.nc

#ncap -h -O -s "weights=cos(lat*3.1415/180)" t.19790101-20141231.zonal_mean.nc t.19790101-20141231.zonal_mean.nc
#ncwa -h -O -w weights -a lat,lon t.19790101-20141231.zonal_mean.nc  t.19790101-20141231.${area}_mean.nc
#ncwa -h -O -w weights -a lat,lon -d latitude,-90.,0. t.19790101-20141231.zonal_mean.nc  t.19790101-20141231.SH_mean.nc
#ncwa -h -O -w weights -a lat,lon -d latitude,0.,90. t.19790101-20141231.zonal_mean.nc  t.19790101-20141231.NH_mean.nc

#set var = t
ncwa -w gw -a lat $var.19790101-20141231.zonal_mean.nc  $var.19790101-20141231.global_mean.nc
ncwa -w gw -a lat -d latitude,-90.,0. $var.19790101-20141231.zonal_mean.nc  $var.19790101-20141231.SH_mean.nc
ncwa -w gw -a lat -d latitude,0.,90. $var.19790101-20141231.zonal_mean.nc  $var.19790101-20141231.NH_mean.nc
 
end
end
