#!/bin/csh
#

set echo
set indir = /mdata3/yingli/ERA_Interim/daily_from_4xdaily/flux_all/
cd $indir
ncap -O -v -s "CPEKEwa=-wa" wa.19790101-20151231.zonal_mean.nc CPEKEwa.19790101-201451231.zonal_mean.nc

end
end
