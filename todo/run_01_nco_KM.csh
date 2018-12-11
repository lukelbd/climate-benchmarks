#!/bin/csh
#

set echo
set indir = /mdata3/yingli/ERA_Interim/daily_from_4xdaily/flux_all/
cd $indir
ncks -A v.19790101-20151231.zonal_mean.nc u.19790101-20151231.zonal_mean.nc 
ncap -O -v -s "KM=0.5f*(u*u+v*v)" u.19790101-20151231.zonal_mean.nc KM.19790101-20151231.zonal_mean.nc
end
end
