#!/usr/bin/env bash
#------------------------------------------------------------------------------#
# Gets a slice along latitudes with NCO hyperslab
#------------------------------------------------------------------------------#
# Entire thing just takes one line
# t1=$(((ni - 1)*ts/nsplit)) # e.g. nsplit=10, ts=200, goes
# t2=$((ni*ts/nsplit - 1)) # e.g. nsplit=10, ts=200, goes 1
filename=$1
nmax=$(($2-1)) # zero-based indexing, endpoint inclusive
flags=${@:3} # optionally pass flags; e.g. --no_tmp_fl for no tmp files; see http://nco.sourceforge.net/nco.html#Temporary-Output-Files
ncks -O -h --no-abc -d time,0,$nmax $filename out/slice_nco.nc
# ncks -O -h --no-abc -d lat,0,3 $filename out/slice_nco.nc
