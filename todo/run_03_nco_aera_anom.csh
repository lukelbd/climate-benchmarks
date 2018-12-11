#!/bin/csh
#

set echo
#foreach var (t w alpha)
set var = alpha
set indir = /gs/project/ktg-565-aa/yingli/var_all/
cd $indir

set infile1 = $var.19790101-20141231.zonal_mean
set infile2 = $var.19790101-20141231.global_mean
set outfile = $var.19790101-20141231.global_anom
ncdiff $infile1.nc $infile2.nc $outfile.nc

set infile1 = $var.19790101-20141231.zonal_mean
set infile2 = $var.19790101-20141231.NH_mean
set outfile = $var.19790101-20141231.NH_anom
ncdiff $infile1.nc $infile2.nc $outfile.nc

set infile1 = $var.19790101-20141231.zonal_mean
set infile2 = $var.19790101-20141231.SH_mean
set outfile = $var.19790101-20141231.SH_anom
ncdiff $infile1.nc $infile2.nc $outfile.nc


end
end
