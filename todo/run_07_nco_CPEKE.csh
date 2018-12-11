#!/bin/csh
#

set echo
set indir = /mdata3/yingli/ERA_Interim/daily_from_4xdaily/flux_all/
cd $indir
ncks -A vdzdy.19790101-20151231.zonal_mean.nc udzdx.19790101-20151231.zonal_mean.nc
ncap -O -v -s "CPEKE=-udzdx-vdzdy" udzdx.19790101-20151231.zonal_mean.nc CPEKE.19790101-20151231.zonal_mean.nc

end
